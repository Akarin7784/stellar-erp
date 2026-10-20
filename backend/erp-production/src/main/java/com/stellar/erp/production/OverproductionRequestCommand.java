package com.stellar.erp.production;

import java.math.BigDecimal;

/**
 * 超产申请（prd_overproduction_approval，90-db-design §3.19.1）。
 *
 * <p>{@code requestQty} 是申请增分 delta（基本单位，> 0），不是总量。不做 Bean Validation：
 * NULL / ≤ 0 由服务层统一返回 60103 / MSG-PRD-103（HTTP 422），而不是 400。</p>
 *
 * @param workOrderId 对象工单（任意；NULL = 受注行整体）
 */
public record OverproductionRequestCommand(Long salesOrderLineId, Long workOrderId, BigDecimal requestQty,
                                           String remark) {
}
