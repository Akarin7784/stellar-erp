package com.stellar.erp.system.company;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.NullAndEmptySource;
import org.junit.jupiter.params.provider.ValueSource;

/** GB 32100-2015 校验位（CHK-SYS-014-01）。 */
class UnifiedSocialCreditCodeTest {

    @ParameterizedTest
    @ValueSource(strings = {"91350100M000100Y43", "91110000600037341L", "91320400MA1XXXXX0D", "91320400MA1XXXXX1G"})
    void validCodesPass(String code) {
        assertThat(UnifiedSocialCreditCode.isValid(code)).isTrue();
    }

    @ParameterizedTest
    @NullAndEmptySource
    @ValueSource(strings = {
            "91350100M000100Y44",   // 校验位違い
            "91320400MA1XXXXX0A",   // 校验位違い
            "91350100M000100Y4",    // 17 桁
            "91350100M000100Y430",  // 19 桁
            "91350100m000100Y43",   // 小文字
            "91350100I000100Y43",   // 使用不可文字 I
            "91350100O000100Y43",   // 使用不可文字 O
            "9135010SM000100Y43",   // 使用不可文字 S
            "91350100M000100YZ3",   // 使用不可文字 Z
            "91350100M000100Y4V",   // 校验位に V（不可）
            "９1350100M000100Y43"   // 全角
    })
    void invalidCodesFail(String code) {
        assertThat(UnifiedSocialCreditCode.isValid(code)).isFalse();
    }

    @Test
    void checkCharMatchesFormulaForAllSeventeenDigitPrefixesOfSample() {
        // 第 18 桁だけを 31 通り変えると、正しいのはちょうど 1 文字
        String prefix = "91350100M000100Y4";
        long ok = UnifiedSocialCreditCode.CHARSET.chars().filter(c -> UnifiedSocialCreditCode.isValid(prefix + (char) c)).count();
        assertThat(ok).isEqualTo(1);
    }
}
