package com.stellar.erp.production;

import java.time.LocalDate;

/**
 * 工单一覧の行（06/91 §3.15 {@code WorkOrderListDto}）。数量は文字列、ID は JacksonConfig で文字列化。
 * 状態名称は返さない（前端辞書）。品目はスナップショット列。原価項目・欠品フラグは返さない。
 */
public record WorkOrderListDto(long id, String workOrderNo, short workOrderType,
                               long materialId, String materialCode, String materialName, String materialSpec,
                               String uomCode, String orderQty, String completedQty, String reportedGoodQty,
                               String progressRate, LocalDate plannedStartDate, LocalDate plannedEndDate,
                               short orderStatus, short priorityNo, short sourceType, boolean isHold,
                               long factoryId, String factoryCode, String factoryName,
                               Long departmentId, String departmentName,
                               Long salesOrderId, String salesOrderNo, Long customerId, String customerName,
                               int version) {
}
