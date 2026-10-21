package com.stellar.erp.common;

import java.time.OffsetDateTime;
import java.util.UUID;

/**
 * E32 {@code workflow.process.completed}（00-common 09 §3、08-workflow 02 §6.2 PRC-WF-011-01）。
 * 項目はエンベロープ（eventId・tenantId・companyId）と payload（processInstanceId・businessType・businessId・
 * businessNo・finalResult・completedAt）の定義どおり。承認者は E32 に含まれない。
 *
 * @param finalResult {@code APPROVED}／{@code REJECTED}／{@code TERMINATED}（WITHDRAWN 等その他は購読側で 4002／60101）
 */
public record WorkflowProcessCompleted(UUID eventId, long tenantId, long companyId, String processInstanceId,
                                       String businessType, long businessId, String businessNo, String finalResult,
                                       OffsetDateTime completedAt) {

    public static final String EVENT_TYPE = "workflow.process.completed";
    public static final String APPROVED = "APPROVED", REJECTED = "REJECTED", TERMINATED = "TERMINATED";
}
