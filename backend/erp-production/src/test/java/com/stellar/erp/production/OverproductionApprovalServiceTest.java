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
                new SQLException("violates check constraint \"ck_prd_opa_qty\"", "23514")))).isTrue();
        assertThat(OverproductionApprovalService.isRequestQtyViolation(new DataIntegrityViolationException("x",
                new SQLException("null value in column \"material_id\"", "23502")))).isFalse();
    }
}
