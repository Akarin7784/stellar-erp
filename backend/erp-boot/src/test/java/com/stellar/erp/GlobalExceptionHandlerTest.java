package com.stellar.erp;

import com.stellar.erp.common.BizException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class GlobalExceptionHandlerTest {

    @RestController
    static class ThrowingController {
        @GetMapping("/biz/{code}")
        String biz(@PathVariable int code) {
            throw new BizException(code, "msg-" + code);
        }

        @GetMapping("/okres")
        com.stellar.erp.common.Result<String> okres() {
            return com.stellar.erp.common.Result.ok("x");
        }

        @GetMapping("/msg")
        String msg() {
            throw new BizException(60040, "MSG-PRD-040", "完工数量超过允许上限");
        }

        record Body(int qty) {}

        @PostMapping("/echo")
        String echo(@RequestBody Body body) {
            return "ok";
        }

        @GetMapping("/ck/{name}")
        String ck(@PathVariable String name) {
            throw new org.springframework.dao.DataIntegrityViolationException("x", new java.sql.SQLException(
                    "ERROR: new row for relation \"sal_sales_order_line\" violates check constraint \"" + name + "\"",
                    "23514"));
        }

        /** 用真实服务抛出的 60103（不手写 BizException），验证经 ControllerAdvice 后的 HTTP 映射。 */
        @GetMapping("/opa/{qty}")
        String opa(@PathVariable String qty) {
            new com.stellar.erp.production.OverproductionApprovalService(null, null)
                    .request(new com.stellar.erp.production.OverproductionRequestCommand(1L, null, new java.math.BigDecimal(qty), null));
            return "unreachable";
        }

        @GetMapping("/boom")
        String boom() {
            throw new IllegalStateException("secret detail");
        }
    }

    private final MockMvc mvc = MockMvcBuilders.standaloneSetup(new ThrowingController())
            .setControllerAdvice(new GlobalExceptionHandler())
            .build();

    @ParameterizedTest
    @CsvSource({
            "4002, 422",   // 状态不整合（409 仅限 4003）
            "4003, 409",   // 乐观锁冲突
            "4005, 422",   // 重复处理/处理中（409 仅限 4003）
            "60001, 422",  // 领域业务规则（PRD）
            "50001, 422",  // 领域业务规则（INV）
            "4001, 404",
            "1001, 400",
            "3001, 403",
            "5000, 500",
            "400, 400"     // 旧写法：直接用 HTTP 数字作业务码
    })
    void bizExceptionMapsToSpecStatusAndKeepsCode(int code, int httpStatus) throws Exception {
        mvc.perform(get("/biz/" + code))
                .andExpect(status().is(httpStatus))
                .andExpect(jsonPath("$.code").value(code))
                .andExpect(jsonPath("$.message").value("msg-" + code))
                .andExpect(jsonPath("$.msgId").doesNotExist());
    }

    @Test
    void msgIdIsReturnedWhenPresent() throws Exception {
        mvc.perform(get("/msg"))
                .andExpect(status().isUnprocessableContent())
                .andExpect(jsonPath("$.code").value(60040))
                .andExpect(jsonPath("$.msgId").value("MSG-PRD-040"));
    }

    @Test
    void malformedBodyIs400NotServerError() throws Exception {
        mvc.perform(post("/echo").contentType(MediaType.APPLICATION_JSON).content("{not json"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(1001));
    }

    @Test
    void wrongMethodIs405() throws Exception {
        mvc.perform(post("/boom"))
                .andExpect(status().isMethodNotAllowed())
                .andExpect(jsonPath("$.code").value(1001));
    }

    @Test
    void unknownExceptionIs500WithoutLeakingDetail() throws Exception {
        mvc.perform(get("/boom"))
                .andExpect(status().isInternalServerError())
                .andExpect(jsonPath("$.code").value(5000))
                .andExpect(jsonPath("$.message").value("服务器内部错误"));
    }

    @Test
    void defaultBizExceptionCodeIs1001() {
        assertThat(new BizException("x").getCode()).isEqualTo(1001);
    }

    @Test
    void unmappedCodeFallsBackTo500() {
        assertThat(GlobalExceptionHandler.httpStatusOf(123).value()).isEqualTo(500);
    }

    @org.junit.jupiter.api.Test
    void onlyCode2001IsHttp401OtherAuthCodesAre200() {
        assertThat(GlobalExceptionHandler.httpStatusOf(2001).value()).isEqualTo(401);
        for (int code : new int[] {2002, 2003, 2004, 2005}) {
            assertThat(GlobalExceptionHandler.httpStatusOf(code).value()).isEqualTo(200);
        }
        assertThat(GlobalExceptionHandler.httpStatusOf(3001).value()).isEqualTo(403);
        // 登录 API 以外：账号停用码为业务错误 422，4003 为 409（登录 API 自身全部 HTTP 200）
        assertThat(GlobalExceptionHandler.httpStatusOf(com.stellar.erp.system.auth.LoginService.ACCOUNT_DISABLED).value())
                .isEqualTo(422);
        assertThat(GlobalExceptionHandler.httpStatusOf(4003).value()).isEqualTo(409);
    }

    @Test
    void completedQtyCheckViolationMapsTo60040() throws Exception {
        mvc.perform(get("/ck/ck_sal_sol_completed_qty"))
                .andExpect(status().isUnprocessableContent())
                .andExpect(jsonPath("$.code").value(60040))
                .andExpect(jsonPath("$.msgId").value("MSG-PRD-040"));
    }

    @Test
    void otherCheckViolationStays5000() throws Exception {
        mvc.perform(get("/ck/ck_sal_sales_order_line_qty"))
                .andExpect(status().isInternalServerError())
                .andExpect(jsonPath("$.code").value(5000));
    }

    @ParameterizedTest
    @org.junit.jupiter.params.provider.ValueSource(strings = {"0", "-1", "-0.0001"})
    void overproductionInvalidRequestQtyIs422WithCodeAndMsgId(String qty) throws Exception {
        mvc.perform(get("/opa/" + qty))
                .andExpect(status().isUnprocessableContent())
                .andExpect(jsonPath("$.code").value(60103))
                .andExpect(jsonPath("$.msgId").value("MSG-PRD-103"));
    }

    /** 响应体只有 03 §5 的 4 个键（无 success 等派生字段）：成功与失败两种。 */
    @Test
    void responseBodyHasExactlyFourKeys() throws Exception {
        for (String path : new String[] {"/okres", "/msg"}) {
            String json = mvc.perform(get(path)).andReturn().getResponse().getContentAsString();
            java.util.Map<String, Object> body = new tools.jackson.databind.ObjectMapper().readValue(json, new tools.jackson.core.type.TypeReference<java.util.Map<String, Object>>() { });
            assertThat(body.keySet()).as(path).containsExactlyInAnyOrder("code", "message", "data", "msgId");
        }
    }
}
