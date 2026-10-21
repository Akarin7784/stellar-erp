package com.stellar.erp.production;

import java.math.BigDecimal;
import java.time.OffsetDateTime;

import com.stellar.erp.production.internal.ProductionRepository.ApprovalView;

/** 超产申请の詳細／一覧行（ID は全局 Jackson 設定で文字列）。 */
public record OverproductionApprovalView(long id, String approvalNo, long salesOrderId, long salesOrderLineId,
                                         Long workOrderId, long materialId, BigDecimal requestQty,
                                         BigDecimal currentAllowedQty, BigDecimal approvedAllowedQty,
                                         short approvalStatus, long requestedBy, OffsetDateTime requestedAt,
                                         Long approvedBy, OffsetDateTime approvedAt, String rejectReason,
                                         String remark, int version) {

    static OverproductionApprovalView of(ApprovalView v) {
        return new OverproductionApprovalView(v.id(), v.approvalNo(), v.salesOrderId(), v.salesOrderLineId(),
                v.workOrderId(), v.materialId(), v.requestQty(), v.currentAllowedQty(), v.approvedAllowedQty(),
                v.approvalStatus(), v.requestedBy(), v.requestedAt(), v.approvedBy(), v.approvedAt(),
                v.rejectReason(), v.remark(), v.version());
    }
}
