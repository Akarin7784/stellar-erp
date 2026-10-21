package com.stellar.erp.production;

import java.util.Map;
import java.util.OptionalLong;

import org.springframework.stereotype.Service;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

import com.stellar.erp.common.BizException;
import com.stellar.erp.common.LoginContext;
import com.stellar.erp.common.TenantContext;
import com.stellar.erp.common.WorkflowProcessCompleted;
import com.stellar.erp.production.internal.ProductionRepository;

/**
 * E32 {@code workflow.process.completed} の PRD 購読側（00-common 09 §9.1・§10.1、08-workflow 02 §6.2、
 * 06/91 §3.11 備考・§3.14、AC-PRD-20／21）。業務ステータスの更新責任は業務域（08/02 BR-14）。
 *
 * <table>
 *   <tr><th>businessType</th><th>APPROVED</th><th>REJECTED</th><th>TERMINATED</th><th>状態不正</th></tr>
 *   <tr><td>{@code WORK_ORDER}</td><td>20→25</td><td>20→10</td><td>20→10</td><td>4002</td></tr>
 *   <tr><td>{@code OVERPRODUCTION_APPROVAL}</td><td>20→30（allowed_qty +request_qty）</td><td>20→40</td><td>20→90</td><td>60101</td></tr>
 * </table>
 *
 * <ul>
 *   <li>租户・会社はイベントのエンベロープ（tenantId・companyId）から取り、1 トランザクションで処理する。</li>
 *   <li>冪等：{@code sys_event_consume_log (tenant_id, event_id, consumer_name)} で重複排除（09 §10.1）。さらに
 *   業務側の現在状態を確認し、既に遷移先なら更新しない（08/02 §6.2）。失敗時は消費記録ごとロールバック。</li>
 *   <li>状態遷移は API と同一のサービスメソッド（{@link WorkOrderApprovalService#approve}、
 *   {@link OverproductionApprovalService#approve} 等）を現在の version で呼ぶ（06/91 §3.11 呼出元）。</li>
 *   <li>E32 に承認者が無いため、操作者は system（userId 0）とする（待定：E31 の approverId を使うか）。</li>
 * </ul>
 */
@Service
public class ProductionWorkflowCallback {

    static final String CONSUMER = "production.ProductionWorkflowCallback";
    static final long SYSTEM_USER = 0L;

    public enum Outcome { APPLIED, ALREADY_APPLIED, DUPLICATE_EVENT }

    private static final Map<String, Short> WO_TARGET = Map.of(
            WorkflowProcessCompleted.APPROVED, (short) 25,
            WorkflowProcessCompleted.REJECTED, (short) 10,
            WorkflowProcessCompleted.TERMINATED, (short) 10);
    private static final Map<String, Short> OPA_TARGET = Map.of(
            WorkflowProcessCompleted.APPROVED, OverproductionApprovalService.STATUS_APPROVED,
            WorkflowProcessCompleted.REJECTED, OverproductionApprovalService.STATUS_REJECTED,
            WorkflowProcessCompleted.TERMINATED, OverproductionApprovalService.STATUS_CANCELLED);

    private final ProductionRepository repo;
    private final WorkOrderApprovalService workOrders;
    private final OverproductionApprovalService overproduction;
    private final TransactionTemplate tx;

    public ProductionWorkflowCallback(ProductionRepository repo, WorkOrderApprovalService workOrders,
                                      OverproductionApprovalService overproduction, PlatformTransactionManager tm) {
        this.repo = repo;
        this.workOrders = workOrders;
        this.overproduction = overproduction;
        this.tx = new TransactionTemplate(tm);
    }

    public Outcome onProcessCompleted(WorkflowProcessCompleted e) {
        OptionalLong prevTenant = TenantContext.current();
        LoginContext.LoginUser prevLogin = LoginContext.current().orElse(null);
        TenantContext.set(e.tenantId());
        LoginContext.set(new LoginContext.LoginUser(SYSTEM_USER, e.companyId()));
        try {
            return tx.execute(s -> {
                if (!repo.markEventConsumed(e.tenantId(), e.eventId(), WorkflowProcessCompleted.EVENT_TYPE, CONSUMER)) {
                    return Outcome.DUPLICATE_EVENT;
                }
                return switch (e.businessType()) {
                    case WorkOrderApprovalService.BUSINESS_TYPE -> workOrder(e);
                    case OverproductionApprovalService.BUSINESS_TYPE -> overproduction(e);
                    default -> throw new IllegalArgumentException("unsupported businessType: " + e.businessType());
                };
            });
        } finally {
            if (prevTenant.isPresent()) {
                TenantContext.set(prevTenant.getAsLong());
            } else {
                TenantContext.clear();
            }
            if (prevLogin == null) {
                LoginContext.clear();
            } else {
                LoginContext.set(prevLogin);
            }
        }
    }

    private Outcome workOrder(WorkflowProcessCompleted e) {
        Short target = WO_TARGET.get(e.finalResult());
        var wo = repo.lockWorkOrderForApproval(e.companyId(), e.businessId())
                .orElseThrow(() -> new BizException(ProductionErrorCode.NOT_FOUND, "工单不存在"));
        if (target != null && wo.orderStatus() == target) {
            return Outcome.ALREADY_APPLIED;
        }
        if (target == null || wo.orderStatus() != WorkOrderApprovalService.PENDING) {
            throw new BizException(ProductionErrorCode.STATE_CONFLICT, ProductionErrorCode.MSG_STATE_CONFLICT,
                    "该记录当前状态不允许此操作。");
        }
        WorkOrderStateCommand cmd = new WorkOrderStateCommand(wo.version(), null);
        if (target == WorkOrderApprovalService.APPROVED) {
            workOrders.approve(wo.id(), cmd);
        } else {
            workOrders.returnToDraft(wo.id(), cmd);
        }
        return Outcome.APPLIED;
    }

    private Outcome overproduction(WorkflowProcessCompleted e) {
        Short target = OPA_TARGET.get(e.finalResult());
        // ロック順（受注行→工单→申請）を崩さないよう、ここでは読むだけ。各サービスメソッドがロック後に再検査する
        var a = repo.findApproval(e.companyId(), e.businessId(), false)
                .orElseThrow(() -> new BizException(ProductionErrorCode.NOT_FOUND, "超产申请不存在"));
        if (target != null && a.approvalStatus() == target) {
            return Outcome.ALREADY_APPLIED;
        }
        if (target == null || a.approvalStatus() != OverproductionApprovalService.STATUS_PENDING) {
            throw new BizException(ProductionErrorCode.OPA_INVALID, ProductionErrorCode.MSG_OPA_INVALID,
                    "超产申请当前状态不允许此操作，请刷新后重试");
        }
        switch (e.finalResult()) {
            case WorkflowProcessCompleted.APPROVED -> overproduction.approve(a.id(), a.version());
            case WorkflowProcessCompleted.REJECTED -> overproduction.reject(a.id(), a.version(), null);
            default -> overproduction.cancel(a.id(), a.version());
        }
        return Outcome.APPLIED;
    }
}
