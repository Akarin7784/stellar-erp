package com.stellar.erp.production.internal;

import static org.assertj.core.api.Assertions.assertThat;

import java.math.BigDecimal;
import java.util.List;

import org.junit.jupiter.api.Test;

import com.stellar.erp.production.internal.UomConverter.Rate;

/** CALC-WO-10 の換算率選択：0 件・複数件は不可（60022）、逆方向は正方向 0 件のときのみ。 */
class UomConverterTest {

    static Rate f(String r) {
        return new Rate(new BigDecimal(r), true);
    }

    static Rate b(String r) {
        return new Rate(new BigDecimal(r), false);
    }

    @Test
    void noRateIsEmpty() {
        assertThat(UomConverter.pick(List.of())).isEmpty();
    }

    @Test
    void multipleForwardIsEmpty() {
        assertThat(UomConverter.pick(List.of(f("1"), f("2")))).isEmpty();
    }

    @Test
    void multipleReverseOnlyIsEmpty() {
        assertThat(UomConverter.pick(List.of(b("1"), b("2")))).isEmpty();
    }

    @Test
    void singleForwardWinsEvenWithReverse() {
        assertThat(UomConverter.pick(List.of(b("1000"), f("0.001")))).contains(f("0.001"));
    }

    @Test
    void singleReverseUsedWhenNoForward() {
        assertThat(UomConverter.pick(List.of(b("1000")))).contains(b("1000"));
    }
}
