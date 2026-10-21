package com.stellar.erp.production;

import java.math.BigDecimal;

/**
 * 超产承認结果。
 *
 * @param approvedAllowedQty 承認後の受注行 allowed_qty（基本単位）
 * @param workOrderId        工单級なら対象工单（その allowed_qty も +requestQty 済み）、受注行級なら NULL
 */
public record OverproductionApproved(long id, String approvalNo, short approvalStatus, BigDecimal requestQty,
                                     BigDecimal approvedAllowedQty, Long workOrderId, int version) {
}
