package com.stellar.erp.production;

import java.math.BigDecimal;
import java.util.List;

/** 工单登録结果（WorkOrderDetailDto 的最小子集）。{@code warnings[]} は 91 §3.1：有効 BOM なし → 60020 / MSG-PRD-020。 */
public record WorkOrderCreated(long id, String workOrderNo, short orderStatus, String materialCode,
                               String materialName, BigDecimal orderQty, BigDecimal overReceiptRate,
                               BigDecimal allowedQty, BigDecimal standardCost, int version,
                               List<WorkOrderReleased.Warning> warnings) {
}
