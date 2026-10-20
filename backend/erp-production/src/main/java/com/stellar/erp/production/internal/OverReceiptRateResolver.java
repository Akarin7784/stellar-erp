package com.stellar.erp.production.internal;

import java.math.BigDecimal;
import java.util.function.Supplier;

import com.stellar.erp.common.BizException;
import com.stellar.erp.production.ProductionErrorCode;

/**
 * 完工超收容差チェーン（06-production 90-db-design §3.19 G2-18 第 3 項、00-common 08 §容差、02-mdm 90 §容差）：
 * 受注行 → 物料 → 物料分類 → 会社既定 {@code sys_param.prd.completion_over_rate}。
 *
 * <p>NULL＝次段継承、0＝明示 0%（下位へ進まない）。NULL 継承は受注行・物料・分類の 3 段のみ。
 * 会社既定が取れない場合は既定値で補わず 5000（設定不備）。結果は工单 {@code over_receipt_rate}（NOT NULL）にスナップショットする。</p>
 */
public final class OverReceiptRateResolver {

    private OverReceiptRateResolver() {
    }

    public static BigDecimal resolve(BigDecimal salesOrderLineRate, BigDecimal materialRate, BigDecimal categoryRate,
                                     Supplier<BigDecimal> companyDefault) {
        if (salesOrderLineRate != null) {
            return salesOrderLineRate;
        }
        if (materialRate != null) {
            return materialRate;
        }
        if (categoryRate != null) {
            return categoryRate;
        }
        BigDecimal company = companyDefault.get();
        if (company == null) {
            throw new BizException(ProductionErrorCode.CONFIG_MISSING,
                    "未设置公司默认完工超收容差（sys_param prd.completion_over_rate）");
        }
        return company;
    }
}
