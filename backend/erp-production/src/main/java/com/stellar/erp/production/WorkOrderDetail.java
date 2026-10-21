package com.stellar.erp.production;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.List;

/**
 * 工单詳細（WorkOrderDetailDto、02-work-order §7 レスポンス例 + SCR-PRD-009 ヘッダ項目）。
 * {@code standardCost} NULL＝標準原価未設定（差異分析対象外）。
 */
public record WorkOrderDetail(
        long id, String workOrderNo, short workOrderType, short orderStatus, String statusName,
        long materialId, String materialCode, String materialName, String materialSpec, String uomCode,
        long factoryId, Long departmentId, Long warehouseId,
        BigDecimal orderQty, BigDecimal allowedQty, BigDecimal completedQty,
        LocalDate plannedStartDate, LocalDate plannedEndDate, short priorityNo,
        Long salesOrderId, Long salesOrderLineId, String salesOrderNo, short sourceType,
        boolean isHold, BigDecimal overReceiptRate, BigDecimal standardCost,
        OffsetDateTime submittedAt, Long approvedBy, OffsetDateTime approvedAt,
        Long releasedBy, OffsetDateTime releasedAt, String remark, int version,
        List<Material> materials, List<Operation> operations) {

    public record Material(int lineNo, long materialId, String materialCode, String materialName,
                           BigDecimal totalRequiredQty, String uomCode) {
    }

    public record Operation(int operationSeq, String operationName, String workCenterCode,
                            LocalDate plannedStartDate, LocalDate plannedEndDate) {
    }

    /** order_status の表示名（90-db-design prd_work_order.order_status 注釈）。 */
    public static String statusName(short status) {
        return switch (status) {
            case 10 -> "草稿";
            case 20 -> "承認待ち";
            case 25 -> "承認済";
            case 30 -> "下达済";
            case 35 -> "製造中";
            case 40 -> "完工";
            case 90 -> "取消";
            default -> null;
        };
    }
}
