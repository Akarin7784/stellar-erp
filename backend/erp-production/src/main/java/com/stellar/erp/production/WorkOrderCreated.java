package com.stellar.erp.production;

import java.math.BigDecimal;

/** 工单登録结果（WorkOrderDetailDto 的最小子集）。 */
public record WorkOrderCreated(long id, String workOrderNo, short orderStatus, String materialCode,
                               String materialName, BigDecimal orderQty, BigDecimal overReceiptRate,
                               BigDecimal allowedQty, BigDecimal standardCost, int version) {
}
