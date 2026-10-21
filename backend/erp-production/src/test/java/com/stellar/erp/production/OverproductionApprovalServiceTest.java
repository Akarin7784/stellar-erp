package com.stellar.erp.production;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.lang.reflect.Proxy;
import java.math.BigDecimal;
import java.sql.SQLException;
import java.util.concurrent.atomic.AtomicInteger;

import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.NullSource;
import org.junit.jupiter.params.provider.ValueSource;
import org.junit.jupiter.api.Test;
import org.springframework.dao.DataIntegrityViolationException;

import com.stellar.erp.common.BizException;

/** request_qty 校验在任何 DB 访问之前（不依赖登录上下文、不调用端口/仓库）。 */
class OverproductionApprovalServiceTest {

    @ParameterizedTest
    @NullSource
    @ValueSource(strings = {"0", "0.0000", "-1", "-0.0001"})
    void invalidRequestQtyIs60103BeforeAnyAccess(BigDecimal qty) {
        AtomicInteger lookups = new AtomicInteger();
        SalesOrderLineLookup lookup = (SalesOrderLineLookup) Proxy.newProxyInstance(
                getClass().getClassLoader(), new Class<?>[] {SalesOrderLineLookup.class}, (p, m, a) -> {
                    lookups.incrementAndGet();
                    throw new AssertionError("should not be called");
                });
        // repo = null：若服务在校验前访问仓库会 NPE，测试即失败
        OverproductionApprovalService service = new OverproductionApprovalService(null, lookup);

        assertThatThrownBy(() -> service.request(new OverproductionRequestCommand(1L, null, qty, null)))
                .isInstanceOfSatisfying(BizException.class, e -> {
                    assertThat(e.getCode()).isEqualTo(60103);
                    assertThat(e.getMsgId()).isEqualTo("MSG-PRD-103");
                });
        assertThat(lookups).hasValue(0);
    }

    @Test
    void nullCommandIs60103() {
        OverproductionApprovalService service = new OverproductionApprovalService(null, null);
        assertThatThrownBy(() -> service.request(null))
                .isInstanceOfSatisfying(BizException.class, e -> assertThat(e.getCode()).isEqualTo(60103));
    }

    @Test
    void recognisesNotNullAndCheckViolationsOnRequestQty() {
        assertThat(OverproductionApprovalService.isRequestQtyViolation(new DataIntegrityViolationException("x",
                new SQLException("null value in column \"request_qty\" violates not-null constraint", "23502"))))
                .isTrue();
        assertThat(OverproductionApprovalService.isRequestQtyViolation(new DataIntegrityViolationException("x",
                new SQLException("new row for relation \"prd_overproduction_approval\" violates check constraint \"ck_prd_opa_request_qty\"", "23514")))).isTrue();
        assertThat(OverproductionApprovalService.isRequestQtyViolation(new DataIntegrityViolationException("x",
                new SQLException("null value in column \"material_id\"", "23502")))).isFalse();
    }

    @org.junit.jupiter.params.ParameterizedTest
    @org.junit.jupiter.params.provider.CsvSource(delimiter = '|', value = {
            "23514|violates check constraint \"ck_prd_opa_allowed_qty\"",
            "23514|violates check constraint \"ck_prd_opa_qty\"",
            "23514|violates check constraint \"ck_prd_opa_status\"",
            "23514|violates check constraint \"ck_prd_opa_request_qty_x\"",
            "23505|duplicate key value violates unique constraint \"uk_prd_overproduction_approval_no\"",
            "23502|null value in column \"current_allowed_qty\""
    })
    void otherConstraintViolationsAreNot60103(String state, String message) {
        assertThat(OverproductionApprovalService.isRequestQtyViolation(
                new DataIntegrityViolationException("x", new SQLException(message, state)))).isFalse();
    }

    // ---------------------------------------------------------------- DB 兜底经 request() 转换（插入阶段）

    static final long CO = 1, USER = 9, LINE = 500, SO = 400, MAT = 300;

    private OverproductionApprovalService mockedService(com.stellar.erp.production.internal.ProductionRepository repo) {
        SalesOrderLineLookup lookup = org.mockito.Mockito.mock(SalesOrderLineLookup.class);
        org.mockito.Mockito.when(lookup.find(CO, LINE)).thenReturn(java.util.Optional.of(
                new SalesOrderLineLookup.SalesOrderLine(LINE, SO, "SO1", MAT, null, new BigDecimal("105"))));
        org.mockito.Mockito.when(repo.nextSequence(org.mockito.ArgumentMatchers.eq(CO), org.mockito.ArgumentMatchers.anyString(),
                org.mockito.ArgumentMatchers.any(), org.mockito.ArgumentMatchers.anyLong())).thenReturn(1L);
        return new OverproductionApprovalService(repo, lookup);
    }

    @Test
    void dbRequestQtyCheckViolationDuringRequestIsConvertedTo60103() {
        var repo = org.mockito.Mockito.mock(com.stellar.erp.production.internal.ProductionRepository.class);
        org.mockito.Mockito.doThrow(new DataIntegrityViolationException("x", new SQLException(
                "new row for relation \"prd_overproduction_approval\" violates check constraint \"ck_prd_opa_request_qty\"", "23514")))
                .when(repo).insertApproval(org.mockito.ArgumentMatchers.any());
        OverproductionApprovalService service = mockedService(repo);
        com.stellar.erp.common.LoginContext.set(new com.stellar.erp.common.LoginContext.LoginUser(USER, CO));
        try {
            assertThatThrownBy(() -> service.request(new OverproductionRequestCommand(LINE, null, new BigDecimal("3"), null)))
                    .isInstanceOfSatisfying(BizException.class, e -> {
                        assertThat(e.getCode()).isEqualTo(60103);
                        assertThat(e.getMsgId()).isEqualTo("MSG-PRD-103");
                    });
        } finally {
            com.stellar.erp.common.LoginContext.clear();
        }
    }

    @Test
    void otherDbViolationDuringRequestIsRethrownUnchanged() {
        var repo = org.mockito.Mockito.mock(com.stellar.erp.production.internal.ProductionRepository.class);
        DataIntegrityViolationException original = new DataIntegrityViolationException("x", new SQLException(
                "violates check constraint \"ck_prd_opa_allowed_qty\"", "23514"));
        org.mockito.Mockito.doThrow(original).when(repo).insertApproval(org.mockito.ArgumentMatchers.any());
        OverproductionApprovalService service = mockedService(repo);
        com.stellar.erp.common.LoginContext.set(new com.stellar.erp.common.LoginContext.LoginUser(USER, CO));
        try {
            assertThatThrownBy(() -> service.request(new OverproductionRequestCommand(LINE, null, new BigDecimal("3"), null)))
                    .isSameAs(original);
        } finally {
            com.stellar.erp.common.LoginContext.clear();
        }
    }

    @Test
    void invalidQtyIsCheckedBeforeMissingSalesOrderLineAndLogin() {
        // 受注行未指定 + 未登录 + 数量 0：60103 优先（不是 1001 / 未登录错误）
        OverproductionApprovalService service = new OverproductionApprovalService(null, null);
        assertThatThrownBy(() -> service.request(new OverproductionRequestCommand(null, null, BigDecimal.ZERO, null)))
                .isInstanceOfSatisfying(BizException.class, e -> assertThat(e.getCode()).isEqualTo(60103));
    }
}
