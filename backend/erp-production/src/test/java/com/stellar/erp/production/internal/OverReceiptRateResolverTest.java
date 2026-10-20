package com.stellar.erp.production.internal;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.math.BigDecimal;
import java.util.concurrent.atomic.AtomicBoolean;

import org.junit.jupiter.api.Test;

import com.stellar.erp.common.BizException;

/** 容差チェーン：受注行 → 物料 → 分類 → 会社。NULL＝継承、0＝明示（02-mdm 95 / 06-production 95）。 */
class OverReceiptRateResolverTest {

    static final BigDecimal COMPANY = new BigDecimal("0.0500");

    @Test
    void salesOrderLineWins() {
        assertThat(OverReceiptRateResolver.resolve(new BigDecimal("0.0100"), new BigDecimal("0.0300"),
                new BigDecimal("0.0200"), () -> COMPANY)).isEqualByComparingTo("0.01");
    }

    @Test
    void materialWhenLineNull() {
        assertThat(OverReceiptRateResolver.resolve(null, new BigDecimal("0.0300"), new BigDecimal("0.0200"),
                () -> COMPANY)).isEqualByComparingTo("0.03");
    }

    @Test
    void explicitZeroOnMaterialDoesNotInherit() {
        AtomicBoolean companyRead = new AtomicBoolean();
        BigDecimal rate = OverReceiptRateResolver.resolve(null, BigDecimal.ZERO, new BigDecimal("0.0200"), () -> {
            companyRead.set(true);
            return COMPANY;
        });
        assertThat(rate).isEqualByComparingTo("0");
        assertThat(companyRead).isFalse();
    }

    @Test
    void explicitZeroOnLineDoesNotInherit() {
        assertThat(OverReceiptRateResolver.resolve(BigDecimal.ZERO, new BigDecimal("0.0300"), null, () -> COMPANY))
                .isEqualByComparingTo("0");
    }

    @Test
    void categoryWhenLineAndMaterialNull() {
        assertThat(OverReceiptRateResolver.resolve(null, null, new BigDecimal("0.0200"), () -> COMPANY))
                .isEqualByComparingTo("0.02");
    }

    @Test
    void companyDefaultWhenAllNull() {
        assertThat(OverReceiptRateResolver.resolve(null, null, null, () -> COMPANY)).isEqualByComparingTo("0.05");
    }

    @Test
    void missingCompanyDefaultIs5000NotSilentDefault() {
        assertThatThrownBy(() -> OverReceiptRateResolver.resolve(null, null, null, () -> null))
                .isInstanceOf(BizException.class)
                .extracting(e -> ((BizException) e).getCode()).isEqualTo(5000);
    }
}
