package com.stellar.erp.production;

import java.math.BigDecimal;
import java.time.OffsetDateTime;

import com.stellar.erp.production.internal.ProductionRepository.ApprovalView;

/**
 * 超产申请の詳細／一覧行（ID は全局 Jackson 設定で文字列）。
 *
 * <p>表示用の {@code salesOrderNo}・{@code workOrderNo}・{@code materialCode}・{@code materialName}・{@code requestedByName}
 * は同一租户・同一会社の三列 JOIN で取得（ID 項目はそのまま残す）。参照先が無い場合は null。</p>
 */
public record OverproductionApprovalView(long id, String approvalNo, long salesOrderId, String salesOrderNo,
                                         long salesOrderLineId, Long workOrderId, String workOrderNo, long materialId,
                                         String materialCode, String materialName, BigDecimal requestQty,
                                         BigDecimal currentAllowedQty, BigDecimal approvedAllowedQty,
                                         short approvalStatus, long requestedBy, String requestedByName,
                                         OffsetDateTime requestedAt,
                                         Long approvedBy, OffsetDateTime approvedAt, String rejectReason,
                                         String remark, int version) {

    static OverproductionApprovalView of(ApprovalView v) {
        return new OverproductionApprovalView(v.id(), v.approvalNo(), v.salesOrderId(), v.salesOrderNo(),
                v.salesOrderLineId(), v.workOrderId(), v.workOrderNo(), v.materialId(), v.materialCode(),
                v.materialName(), v.requestQty(), v.currentAllowedQty(), v.approvedAllowedQty(),
                v.approvalStatus(), v.requestedBy(), v.requestedByName(), v.requestedAt(), v.approvedBy(), v.approvedAt(),
                v.rejectReason(), v.remark(), v.version());
    }
}
