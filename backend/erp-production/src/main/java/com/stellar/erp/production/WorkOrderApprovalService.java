package com.stellar.erp.production;

import java.time.Clock;
import java.time.LocalDate;

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
 *   <li>状態不正 → 422 / 4002 / MSG-COM-034（§6.3 第 1 項、CHK-PRD-002-11）。</li>
 *   <li>{@code version} 不一致 → 409 / 4003 / MSG-COM-033（91 §10「状態操作は version 必須」）。</li>
 *   <li>提出：材料明細 0 行可（CHK-PRD-002-09、AC-PRD-13）。</li>
 *   <li>承認：工序明細 1 行以上（CHK-PRD-002-08、60021 / MSG-PRD-021）、材料明細は不要。</li>
 *   <li>承認：起案者（created_by）≠ 承認者（CHK-PRD-002-12、60005 / MSG-PRD-005）。</li>
 * </ul>
 *
 * <p>WF（08）連携：業務類型 {@code WORK_ORDER}、流程 key {@code prd_work_order_release}（一級・生产主管）。
 * E32 受信は {@link ProductionWorkflowCallback} が承認→{@link #approve}（20→25）、却下・強制終了→
 * {@link #returnToDraft}（20→10、95・90 は使わない）を呼ぶ（06/02 §規則 5、06/91 §3.11 備考、蓝色大肥鱼 2026-10-21 決定）。
 * 却下理由は WF 履歴のみ（工单表に列なし）。</p>
 *
 * <p>未実装：WF 提交（プロセス起動・{@code wf_business_process} 登録）、監査ログ、Idempotency-Key。</p>
 */
@Service
public class WorkOrderApprovalService {

    static final short DRAFT = 10, PENDING = 20, APPROVED = 25;
    /** 08/94 §2.2 業務類型・§2.3 流程定義（{@code WO_STANDARD}）。 */
    public static final String BUSINESS_TYPE = "WORK_ORDER";
    public static final String PROCESS_KEY = "prd_work_order_release";

    private final ProductionRepository repo;
    private final WorkOrderQueryService query;

    private final WorkOrderMaterials materials;
    private Clock clock = Clock.system(java.time.ZoneId.of("Asia/Shanghai"));

    @org.springframework.beans.factory.annotation.Autowired
    WorkOrderApprovalService(ProductionRepository repo, WorkOrderQueryService query, WorkOrderMaterials materials) {
        this.repo = repo;
        this.query = query;
        this.materials = materials;
    }

    WorkOrderApprovalService(ProductionRepository repo, WorkOrderQueryService query, WorkOrderMaterials materials,
                             Clock clock) {
        this(repo, query, materials);
        this.clock = clock;
    }

    @Transactional
    public WorkOrderDetail submit(long workOrderId, WorkOrderStateCommand cmd) {
        LoginContext.LoginUser login = LoginContext.require();
        long company = login.companyId();
        WorkOrderForApproval wo = lockAndCheck(company, workOrderId, DRAFT, cmd);
        // CHK-PRD-002-10：提出時は全材料行の単位整合を確認（基準日＝planned_start_date、なければ Asia/Shanghai 当日）
        LocalDate baseDate = repo.findPlannedStartDate(company, wo.id()).orElse(LocalDate.now(clock));
        materials.checkAll(company, wo.id(), baseDate);
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

    /**
     * 却下・強制終了（WF E32 REJECTED／TERMINATED）：20→10。状態不正 4002、version 不一致 4003。
     * 再編集・再提出可（AC-PRD-20）。
     */
    @Transactional
    public WorkOrderDetail returnToDraft(long workOrderId, WorkOrderStateCommand cmd) {
        LoginContext.LoginUser login = LoginContext.require();
        long company = login.companyId();
        WorkOrderForApproval wo = lockAndCheck(company, workOrderId, PENDING, cmd);
        if (repo.markReturnedToDraft(company, wo.id(), wo.version(), login.userId()) != 1) {
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
