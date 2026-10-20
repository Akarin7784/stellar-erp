package com.stellar.erp;

import com.stellar.erp.common.BizException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class GlobalExceptionHandlerTest {

    @RestController
    static class ThrowingController {
        @GetMapping("/biz/{code}")
        String biz(@PathVariable int code) {
            throw new BizException(code, "msg-" + code);
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
            "4002, 409",   // 状态不整合
            "4003, 409",   // 乐观锁冲突
            "60001, 422",  // 领域业务规则（PRD）
            "50001, 422",  // 领域业务规则（INV）
            "4001, 404",
            "1001, 400",
            "3001, 403",
            "400, 400"     // 旧写法：BizException(String) 默认码
    })
    void bizExceptionMapsToSpecStatusAndKeepsCode(int code, int httpStatus) throws Exception {
        mvc.perform(get("/biz/" + code))
                .andExpect(status().is(httpStatus))
                .andExpect(jsonPath("$.code").value(code))
                .andExpect(jsonPath("$.message").value("msg-" + code));
    }

    @Test
    void unknownExceptionIs500WithoutLeakingDetail() throws Exception {
        mvc.perform(get("/boom"))
                .andExpect(status().isInternalServerError())
                .andExpect(jsonPath("$.code").value(500))
                .andExpect(jsonPath("$.message").value("服务器内部错误"));
    }

    @Test
    void unmappedCodeFallsBackTo500() {
        assertThat(GlobalExceptionHandler.httpStatusOf(123).value()).isEqualTo(500);
    }
}
