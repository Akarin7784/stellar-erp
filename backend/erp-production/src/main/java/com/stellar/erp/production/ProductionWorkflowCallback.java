package com.stellar.erp.production;

import java.util.Map;
import java.util.OptionalLong;

import org.springframework.stereotype.Service;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.TransactionDefinition;
import org.springframework.transaction.support.TransactionTemplate;

import com.stellar.erp.common.BizException;
import com.stellar.erp.common.LoginContext;
import com.stellar.erp.common.TenantContext;
import com.stellar.erp.common.WorkflowProcessCompleted;
import com.stellar.erp.production.internal.ProductionRepository;

/**
 * E32 {@code workflow.process.completed} の PRD 購読側（00-common 09 §9.1・§10.1、08-workflow 02 §6.2、
 * 06/91 §3.11 備考・§3.14、AC-PRD-20／21）。
 *
 * <p>{@code sys_event_consume_log.consume_status}：1=成功／0=失敗（V202610210104）。失敗理由は
 * {@code error_message}。一意キー {@code (tenant_id, event_id, consumer_name)} で1行のみ。</p>
 *
 * <ul>
 *   <li>{@code approverUserId} 必須（欠落 → 1001）。提出者本人なら 60005。</li>
 *   <li>成功時に初めて status=1 を書く（新規 INSERT、または失敗行の 0→1 UPDATE＋error_message クリア）。</li>
 *   <li>業務検証失敗：REQUIRES_NEW で status=0 を<strong>先にコミット</strong>してから業務 TX をロールバックする
 *   （同一 TX だと失敗記録も消える）。同一 eventId 再送は業務を再実行し、直っていなければ再び 0 のまま。</li>
 *   <li>超産 REJECTED：{@code comment} → {@code reject_reason}（空／空白は NULL）。</li>
 * </ul>
 */
@Service
public class ProductionWorkflowCallback {

    static final String CONSUMER = "production.ProductionWorkflowCallback";
    public static final int MISSING_APPROVER = 1001;
    public static final String MSG_MISSING_APPROVER = "MSG-COM-040";

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
    private final TransactionTemplate txNew;

    public ProductionWorkflowCallback(ProductionRepository repo, WorkOrderApprovalService workOrders,
                                      OverproductionApprovalService overproduction, PlatformTransactionManager tm) {
        this.repo = repo;
        this.workOrders = workOrders;
        this.overproduction = overproduction;
        this.tx = new TransactionTemplate(tm);
        this.txNew = new TransactionTemplate(tm);
        this.txNew.setPropagationBehavior(TransactionDefinition.PROPAGATION_REQUIRES_NEW);
    }

    public Outcome onProcessCompleted(WorkflowProcessCompleted e) {
        if (e.approverUserId() == null) {
            throw new BizException(MISSING_APPROVER, MSG_MISSING_APPROVER, "请输入必填项「approverUserId」。");
        }
        OptionalLong prevTenant = TenantContext.current();
        LoginContext.LoginUser prevLogin = LoginContext.current().orElse(null);
        TenantContext.set(e.tenantId());
        LoginContext.set(new LoginContext.LoginUser(e.approverUserId(), e.companyId()));
        try {
            return tx.execute(s -> {
                Short prior = repo.findConsumeStatus(e.tenantId(), e.eventId(), CONSUMER);
                if (prior != null && prior == ProductionRepository.CONSUME_OK) {
                    return Outcome.DUPLICATE_EVENT;
                }
                try {
                    Outcome out = switch (e.businessType()) {
                        case WorkOrderApprovalService.BUSINESS_TYPE -> workOrder(e);
                        case OverproductionApprovalService.BUSINESS_TYPE -> overproduction(e);
                        default -> throw new IllegalArgumentException("unsupported businessType: " + e.businessType());
                    };
                    // 成功後に初めて status=1。失敗行の再送は INSERT せず 0→1 UPDATE（error_message クリア）
                    if (prior != null && prior == ProductionRepository.CONSUME_FAILED) {
                        repo.reclaimFailedEvent(e.tenantId(), e.eventId(), CONSUMER);
                    } else if (prior == null) {
                        repo.tryClaimEvent(e.tenantId(), e.eventId(), WorkflowProcessCompleted.EVENT_TYPE, CONSUMER);
                    }
                    return out;
                } catch (BizException ex) {
                    String err = ex.getMessage() == null ? String.valueOf(ex.getCode()) : ex.getMessage();
                    if (err.length() > 1000) {
                        err = err.substring(0, 1000);
                    }
                    String finalErr = err;
                    // 失敗ログを独立 TX で先にコミットしてから、業務 TX をロールバックする
                    txNew.executeWithoutResult(st -> repo.markEventFailed(e.tenantId(), e.eventId(),
                            WorkflowProcessCompleted.EVENT_TYPE, CONSUMER, finalErr));
                    throw ex;
                }
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
        WorkOrderStateCommand cmd = new WorkOrderStateCommand(wo.version(), e.comment());
        if (target == WorkOrderApprovalService.APPROVED) {
            workOrders.approve(wo.id(), cmd);
        } else {
            workOrders.returnToDraft(wo.id(), cmd);
        }
        return Outcome.APPLIED;
    }

    private Outcome overproduction(WorkflowProcessCompleted e) {
        Short target = OPA_TARGET.get(e.finalResult());
        // ロックして並行時に ALREADY_APPLIED を正しく返す（未ロックだと後着が 60101 になる）
        var a = repo.findApproval(e.companyId(), e.businessId(), true)
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
            case WorkflowProcessCompleted.REJECTED -> overproduction.reject(a.id(), a.version(), blankToNull(e.comment()));
            default -> overproduction.cancel(a.id(), a.version());
        }
        return Outcome.APPLIED;
    }

    private static String blankToNull(String s) {
        return s == null || s.isBlank() ? null : s.strip();
    }
}
