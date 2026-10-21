package com.stellar.erp.system.company;

/**
 * 统一社会信用代码（GB 32100-2015）の形式・校验位チェック（01-system 03 CHK-SYS-014-01）。
 *
 * <p>18 桁。各桁は {@code 0-9A-HJ-NPQRTUWXY}（I・O・S・V・Z を除く 31 文字、英大文字のみ）。
 * 第 18 桁は前 17 桁の加重和（重み 3^(i) mod 31：1,3,9,27,19,26,16,17,20,29,25,13,8,24,10,30,28）から
 * {@code (31 - sum % 31) % 31} を同じ文字集合で表した校验字符。</p>
 */
public final class UnifiedSocialCreditCode {

    static final String CHARSET = "0123456789ABCDEFGHJKLMNPQRTUWXY";
    static final int[] WEIGHTS = {1, 3, 9, 27, 19, 26, 16, 17, 20, 29, 25, 13, 8, 24, 10, 30, 28};

    private UnifiedSocialCreditCode() {
    }

    /** 18 桁・文字集合・校验位がすべて正しいとき true。null は false。 */
    public static boolean isValid(String code) {
        if (code == null || code.length() != 18) {
            return false;
        }
        int sum = 0;
        for (int i = 0; i < 17; i++) {
            int v = CHARSET.indexOf(code.charAt(i));
            if (v < 0) {
                return false;
            }
            sum += v * WEIGHTS[i];
        }
        int last = CHARSET.indexOf(code.charAt(17));
        return last >= 0 && last == (31 - sum % 31) % 31;
    }
}
