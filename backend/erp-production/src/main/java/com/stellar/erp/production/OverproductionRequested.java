package com.stellar.erp.production;

import java.math.BigDecimal;

/** 超产申请保存结果。 */
public record OverproductionRequested(long id, String approvalNo, short approvalStatus, BigDecimal requestQty,
                                      BigDecimal currentAllowedQty) {
}
