package com.stellar.erp.common;

import java.time.OffsetDateTime;
import java.util.UUID;

/**
 * E32 {@code workflow.process.completed}（00-common 09 §3、08-workflow 02 §6.2 PRC-WF-011-01）。
 * エンベロープ（eventId・tenantId・companyId）＋ payload（processInstanceId・businessType・businessId・
 * businessNo・finalResult・completedAt）。購読側が自己承認検査と監査に使うため {@code approverUserId} を必須とし、
 * 却下理由用に {@code comment} を任意で持つ（08/02 E31 の comment に相当。E32 公式例に無いが業務側が要する）。
 *
 * @param approverUserId 最終承認者／却下者（必須。欠落は購読側が拒否）。TERMINATED も操作者を入れる
 * @param comment 却下理由等（空／null 可。超産 REJECTED 時に {@code reject_reason} へ書く）
 * @param finalResult {@code APPROVED}／{@code REJECTED}／{@code TERMINATED}
 */
public record WorkflowProcessCompleted(UUID eventId, long tenantId, long companyId, String processInstanceId,
                                       String businessType, long businessId, String businessNo, String finalResult,
                                       OffsetDateTime completedAt, Long approverUserId, String comment) {

    public static final String EVENT_TYPE = "workflow.process.completed";
    public static final String APPROVED = "APPROVED", REJECTED = "REJECTED", TERMINATED = "TERMINATED";
}
