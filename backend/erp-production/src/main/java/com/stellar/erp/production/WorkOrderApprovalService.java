package com.stellar.erp.production;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.stellar.erp.common.BizException;
import com.stellar.erp.common.LoginContext;
import com.stellar.erp.production.internal.ProductionRepository;
import com.stellar.erp.production.internal.ProductionRepository.WorkOrderForApproval;

/**
 * 工单の承認提出（T-01 10→20、API 91 #28）と承認（T-02 20→25、{@code POST /{id}/approve}。将来の WF E32 受信と同じ
 * {@link #approve}）。Flowable 連携前の単純な状態遷移（Lead 2026-10-21 決定）。
 *
 * <ul>
 *   <li>状態不正 → 409 / 4002 / MSG-COM-034（§6.3 第 1 項、CHK-PRD-002-11）。</li>
 *   <li>{@code version} 不一致 → 409 / 4003 / MSG-COM-033（91 §10「状態操作は version 必須」）。</li>
 *   <li>提出：材料明細 0 行可（CHK-PRD-002-09、AC-PRD-13）。</li>
 *   <li>承認：工序明細 1 行以上（CHK-PRD-002-08、60021 / MSG-PRD-021）、材料明細は不要。</li>
 *   <li>承認：起案者（created_by）≠ 承認者（CHK-PRD-002-12、60005 / MSG-PRD-005）。</li>
 * </ul>
 *
 * <p>未実装：WF 提交（businessType=PRODUCTION_WORK_ORDER）・E31/E32 受信、差戻し（20→10）・却下（20→95）、
 * 監査ログ、Idempotency-Key。</p>
 */
@Service
public class WorkOrderApprovalService {

    static final short DRAFT = 10, PENDING = 20, APPROVED = 25;

    private final ProductionRepository repo;
    private final WorkOrderQueryService query;

    public WorkOrderApprovalService(ProductionRepository repo, WorkOrderQueryService query) {
        this.repo = repo;
        this.query = query;
    }

    @Transactional
    public WorkOrderDetail submit(long workOrderId, WorkOrderStateCommand cmd) {
        LoginContext.LoginUser login = LoginContext.require();
        long company = login.companyId();
        WorkOrderForApproval wo = lockAndCheck(company, workOrderId, DRAFT, cmd);
        // 材料行 0 件でも提出可（Lead 2026-10-21 最終決定、AC-PRD-12）。BOM 展開は下达時に行う。
        if (repo.markSubmitted(company, wo.id(), wo.version(), login.userId()) != 1) {
            throw versionConflict();
        }
        return query.get(workOrderId);
    }

    @Transactional
    public WorkOrderDetail approve(long workOrderId, WorkOrderStateCommand cmd) {
        LoginContext.LoginUser login = LoginContext.require();
        long company = login.companyId();
        WorkOrderForApproval wo = lockAndCheck(company, workOrderId, PENDING, cmd);
        if (wo.createdBy() == login.userId()) {
            throw new BizException(ProductionErrorCode.WO_SELF_APPROVAL, ProductionErrorCode.MSG_WO_SELF_APPROVAL,
                    "起案者と承認者が同一のため承認できません。");
        }
        // 承認は工序明細 1 行以上が必要、材料明細は不要（0 行可、下达時に BOM 展開。Lead 2026-10-21 決定）
        if (repo.countWorkOrderOperations(company, wo.id()) == 0) {
            throw new BizException(ProductionErrorCode.ROUTING_NOT_FOUND, ProductionErrorCode.MSG_ROUTING_NOT_FOUND,
                    "有効な工艺路线がありません。工艺路线を登録してください。");
        }
        if (repo.markApproved(company, wo.id(), wo.version(), login.userId()) != 1) {
            throw versionConflict();
        }
        return query.get(workOrderId);
    }

    private WorkOrderForApproval lockAndCheck(long company, long workOrderId, short expected, WorkOrderStateCommand cmd) {
        WorkOrderForApproval wo = repo.lockWorkOrderForApproval(company, workOrderId)
                .orElseThrow(() -> new BizException(ProductionErrorCode.NOT_FOUND, "工单不存在"));
        if (wo.orderStatus() != expected) {
            throw stateConflict();
        }
        if (cmd == null || cmd.version() == null || cmd.version() != wo.version()) {
            throw versionConflict();
        }
        return wo;
    }

    /** 楽観ロック：UPDATE … AND version = :version が 0 行 → 4003。 */
    private static BizException versionConflict() {
        return new BizException(ProductionErrorCode.VERSION_CONFLICT, ProductionErrorCode.MSG_VERSION_CONFLICT,
                "数据已被其他用户更新，请重新获取最新信息后再操作。");
    }

    private static BizException stateConflict() {
        return new BizException(ProductionErrorCode.STATE_CONFLICT, ProductionErrorCode.MSG_STATE_CONFLICT,
                "该记录当前状态不允许此操作。");
    }
}
