package com.stellar.erp.production;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.List;

import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.baomidou.mybatisplus.core.toolkit.IdWorker;
import com.stellar.erp.common.BizException;
import com.stellar.erp.common.LoginContext;
import com.stellar.erp.common.PageResult;
import com.stellar.erp.production.SalesOrderLineLookup.SalesOrderLine;
import com.stellar.erp.production.internal.DocumentNumbers;
import com.stellar.erp.production.internal.ProductionRepository;
import com.stellar.erp.production.internal.ProductionRepository.ApprovalInsert;

/**
 * 超产申请保存（90-db-design §3.19.1、G2-18 第 6 項）的最小切片。
 *
 * <p>{@code request_qty} 为 NULL 或 ≤ 0 时，在任何查询 / INSERT 之前返回 60103 / MSG-PRD-103（HTTP 422）。
 * DB 侧 {@code NOT NULL}（23502）/ {@code ck_prd_opa_qty}（23514）仅作兜底，若仍触发也转换为 60103，不会变成 500。</p>
 *
 * <p>未实装（后续任务）：Flowable 起動（申請保存→20）、承認時の allowed_qty 増分更新とロック順、API 路径。</p>
 */
@Service
public class OverproductionApprovalService {

    /** sys_sequence キー：设计书未定义，暂用此值（待 DB/业务确认）。 */
    static final String SEQ_KEY = "PRD_OVERPRODUCTION_APPROVAL";
    static final String PREFIX = "OPA";
    static final short STATUS_DRAFT = 10;
    static final short STATUS_PENDING = 20;
    static final short STATUS_APPROVED = 30;
    static final short STATUS_REJECTED = 40;
    static final short STATUS_CANCELLED = 90;
    static final short WO_RELEASED = 30;
    static final String MAX_RATE_KEY = "prd.overproduction_max_rate";
    /** 08/94 §2.2 業務類型・§2.3 流程定義（{@code OPA_STANDARD}、承認対象 {@code APR-OPA}）。 */
    public static final String BUSINESS_TYPE = "OVERPRODUCTION_APPROVAL";
    public static final String PROCESS_KEY = "prd_overproduction_approval";

    private final ProductionRepository repo;
    private final SalesOrderLineLookup salesOrderLines;

    public OverproductionApprovalService(ProductionRepository repo, SalesOrderLineLookup salesOrderLines) {
        this.repo = repo;
        this.salesOrderLines = salesOrderLines;
    }

    @Transactional
    public OverproductionRequested request(OverproductionRequestCommand cmd) {
        if (cmd == null || cmd.requestQty() == null || cmd.requestQty().signum() <= 0) {
            throw invalidQty();
        }
        LoginContext.LoginUser login = LoginContext.require();
        long company = login.companyId();
        if (cmd.salesOrderLineId() == null) {
            throw new BizException(1001, "MSG-COM-040", "受注行必须指定。");
        }

        // 申请时的快照仅供参考，上限在审批和报完工时先锁受注行再重读（此处不加锁）。
        SalesOrderLine line = salesOrderLines.find(company, cmd.salesOrderLineId())
                .orElseThrow(() -> new BizException(ProductionErrorCode.NOT_FOUND, "受注行不存在"));
        checkTargetWorkOrder(company, line, cmd.workOrderId());
        if (line.allowedQty() == null) {
            // 業務データ未準備（受注未確定で allowed_qty 未スナップショット）→ 422 / 60101 / MSG-PRD-106（lead 2026-10-21 決定）。
            // 5000 は prd.overproduction_max_rate 欠落のみ。
            throw allowedUnavailable();
        }
        if (line.allowedQty().signum() < 0) {
            // 負値も NULL と同じく業務データ未準備 → 422 / 60101 / MSG-PRD-106（lead 2026-10-21 決定。60103 にはしない）
            throw allowedUnavailable();
        }

        checkLimit(company, line.id(), cmd.requestQty());

        String no = DocumentNumbers.next(repo, company, SEQ_KEY, PREFIX, LocalDate.now());
        long id = IdWorker.getId();
        try {
            repo.insertApproval(new ApprovalInsert(id, company, login.userId(), no, line.salesOrderId(), line.id(),
                    cmd.workOrderId(), line.materialId(), cmd.requestQty(), line.allowedQty(), STATUS_DRAFT,
                    OffsetDateTime.now(), cmd.remark()));
        } catch (DataIntegrityViolationException e) {
            if (isRequestQtyViolation(e)) {
                throw invalidQty();
            }
            throw e;
        }
        return new OverproductionRequested(id, no, STATUS_DRAFT, cmd.requestQty(), line.allowedQty());
    }

    /** 工单級の対象工单チェック（登録・草稿編集で共通）。NULL＝受注行級は何もしない。 */
    private void checkTargetWorkOrder(long company, SalesOrderLine line, Long workOrderId) {
        if (workOrderId == null) {
            return;
        }
        ProductionRepository.WorkOrderRef wo = repo.findWorkOrder(company, workOrderId)
                .orElseThrow(OverproductionApprovalService::woMismatch);
        checkWorkOrderBelongs(wo, line.id(), line.materialId());
        // 工单級：下达済（≥30）かつ allowed_qty スナップショット済みでなければ申請不可（Lead 2026-10-21 決定）
        ProductionRepository.WorkOrderLimitState st = repo.findWorkOrderLimitState(company, wo.id())
                .orElseThrow(OverproductionApprovalService::woMismatch);
        if (st.orderStatus() < WO_RELEASED) {
            // 工单未下达は状態不符 → 60101 / MSG-PRD-101（lead 2026-10-21 決定）
            throw invalidApproval("工单が未下达のため工单級の超産申請はできません。");
        }
        if (st.allowedQty() == null) {
            throw allowedUnavailable();
        }
    }

    /**
     * 草稿修正（状態 10 のみ）。申請行を FOR UPDATE → 状態（10 以外は 60101、他操作と同じ）→ version（不一致 4003）→
     * 数量・工单を登録と同じ規則で検証し、request_qty・work_order_id・remark のみ更新する（#39h、AC-PRD-18）。
     * current_allowed_qty／受注行・工单の allowed_qty は変更しない。
     */
    @Transactional
    public OverproductionApprovalView update(long approvalId, OverproductionUpdateCommand cmd) {
        LoginContext.LoginUser login = LoginContext.require();
        long company = login.companyId();
        ProductionRepository.ApprovalRow a = repo.findApproval(company, approvalId, true)
                .orElseThrow(OverproductionApprovalService::notFound);
        checkStatus(a, STATUS_DRAFT);
        checkVersion(a, cmd == null ? null : cmd.version());
        if (cmd.requestQty() == null || cmd.requestQty().signum() <= 0) {
            throw invalidQty();
        }
        SalesOrderLine line = salesOrderLines.find(company, a.salesOrderLineId())
                .orElseThrow(() -> allowedUnavailable());
        checkTargetWorkOrder(company, line, cmd.workOrderId());
        checkLimit(company, line.id(), cmd.requestQty());
        int n;
        try {
            n = repo.updateDraftApproval(company, a.id(), a.version(), login.userId(), cmd.workOrderId(),
                    cmd.requestQty(), cmd.remark());
        } catch (DataIntegrityViolationException e) {
            if (isRequestQtyViolation(e)) {
                throw invalidQty();
            }
            throw e;
        }
        if (n != 1) {
            throw versionConflict();
        }
        return get(approvalId);
    }

    /** 超产申请用 受注行ピッカー（当前会社、受注番号・品目コード／品名の部分一致、ページング）。 */
    @Transactional(readOnly = true)
    public PageResult<SalesOrderLineOption> searchSalesOrderLines(String salesOrderNo, String material,
                                                                   int pageNum, int pageSize) {
        long company = LoginContext.require().companyId();
        if (pageNum < 1 || pageSize < 1 || pageSize > 200) {
            throw new BizException(1001, "MSG-COM-040", "pageNum / pageSize 不正");
        }
        String no = blankToNull(salesOrderNo);
        String mat = blankToNull(material);
        long total = repo.countSalesOrderLineOptions(company, no, mat);
        List<SalesOrderLineOption> rows = repo.listSalesOrderLineOptions(company, no, mat, pageSize,
                (long) (pageNum - 1) * pageSize);
        return PageResult.of(rows, total, pageNum, pageSize);
    }

    /** 前後空白を除き、空なら NULL（絞込なし）。LIKE のワイルドカードはエスケープしない。 */
    private static String blankToNull(String v) {
        return v == null || v.isBlank() ? null : v.strip();
    }

    /** 承認 → 30。受注行 → 工单 → 申請行の順にロックし、受注行（と工单級なら工单）の allowed_qty を +delta。 */
    @Transactional
    public OverproductionApproved approve(long approvalId, Integer version) {
        LoginContext.LoginUser login = LoginContext.require();
        long company = login.companyId();
        ProductionRepository.ApprovalRow peek = repo.findApproval(company, approvalId, false)
                .orElseThrow(() -> new BizException(ProductionErrorCode.NOT_FOUND, "超产申请不存在"));
        SalesOrderLine line = salesOrderLines.lockForUpdate(company, peek.salesOrderLineId())
                .orElseThrow(() -> allowedUnavailable());
        if (peek.workOrderId() != null) {
            ProductionRepository.WorkOrderRef wo = repo.lockWorkOrderRef(company, peek.workOrderId())
                    .orElseThrow(OverproductionApprovalService::woMismatch);
            checkWorkOrderBelongs(wo, line.id(), line.materialId());
        }
        ProductionRepository.ApprovalRow a = repo.findApproval(company, approvalId, true)
                .orElseThrow(() -> new BizException(ProductionErrorCode.NOT_FOUND, "超产申请不存在"));
        checkStatus(a, STATUS_PENDING);
        checkVersion(a, version);
        if (a.requestedBy() == login.userId()) {
            throw new BizException(ProductionErrorCode.WO_SELF_APPROVAL, ProductionErrorCode.MSG_WO_SELF_APPROVAL,
                    "申請者と承認者が同一のため承認できません。");
        }
        // 受注行（工单級なら工单も）の allowed_qty が NULL／負値 → 業務データ未準備 422 / 60101 / MSG-PRD-106（lead 2026-10-21 決定）
        if (line.allowedQty() == null || line.allowedQty().signum() < 0) {
            throw allowedUnavailable();
        }
        if (a.workOrderId() != null) {
            BigDecimal woAllowed = repo.findWorkOrderLimitState(company, a.workOrderId())
                    .map(ProductionRepository.WorkOrderLimitState::allowedQty).orElse(null);
            if (woAllowed == null) {
                throw allowedUnavailable();
            }
        }
        BigDecimal lineAllowed = repo.addSalesOrderLineAllowedQty(company, line.id(), a.requestQty(), login.userId())
                .orElseThrow(() -> allowedUnavailable());
        if (a.workOrderId() != null
                && repo.addWorkOrderAllowedQty(company, a.workOrderId(), a.requestQty(), login.userId()) != 1) {
            throw allowedUnavailable();
        }
        if (repo.markOverproductionApproved(company, a.id(), a.version(), login.userId(), lineAllowed) != 1) {
            // WHERE は approval_status = 20 AND version = :version。0 行＝同時更新 → 409 / 4003
            throw versionConflict();
        }
        return new OverproductionApproved(a.id(), a.approvalNo(), STATUS_APPROVED, a.requestQty(), lineAllowed,
                a.workOrderId(), a.version() + 1);
    }

    /** 提出 10→20。 */
    @Transactional
    public OverproductionApprovalView submit(long approvalId, Integer version) {
        return transition(approvalId, version, List.of(STATUS_DRAFT), STATUS_PENDING, null);
    }

    /** 却下 20→40（allowed_qty は変更しない）。 */
    @Transactional
    public OverproductionApprovalView reject(long approvalId, Integer version, String reason) {
        return transition(approvalId, version, List.of(STATUS_PENDING), STATUS_REJECTED, reason);
    }

    /** 取消 10/20→90（allowed_qty は変更しない）。 */
    @Transactional
    public OverproductionApprovalView cancel(long approvalId, Integer version) {
        return transition(approvalId, version, List.of(STATUS_DRAFT, STATUS_PENDING), STATUS_CANCELLED, null);
    }

    @Transactional(readOnly = true)
    public OverproductionApprovalView get(long approvalId) {
        long company = LoginContext.require().companyId();
        return repo.findApprovalView(company, approvalId).map(OverproductionApprovalView::of)
                .orElseThrow(OverproductionApprovalService::notFound);
    }

    @Transactional(readOnly = true)
    public PageResult<OverproductionApprovalView> list(Long salesOrderLineId, Long workOrderId, Short status,
                                                       int pageNum, int pageSize) {
        long company = LoginContext.require().companyId();
        if (pageNum < 1 || pageSize < 1 || pageSize > 200) {
            throw new BizException(1001, "MSG-COM-040", "pageNum / pageSize 不正");
        }
        long total = repo.countApprovals(company, salesOrderLineId, workOrderId, status);
        List<OverproductionApprovalView> rows = repo.listApprovals(company, salesOrderLineId, workOrderId, status,
                pageSize, (long) (pageNum - 1) * pageSize).stream().map(OverproductionApprovalView::of).toList();
        return PageResult.of(rows, total, pageNum, pageSize);
    }

    private OverproductionApprovalView transition(long approvalId, Integer version, List<Short> from, short to,
                                                  String reason) {
        LoginContext.LoginUser login = LoginContext.require();
        long company = login.companyId();
        ProductionRepository.ApprovalRow a = repo.findApproval(company, approvalId, true)
                .orElseThrow(OverproductionApprovalService::notFound);
        if (!from.contains(a.approvalStatus())) {
            checkStatus(a, (short) -1);
        }
        checkVersion(a, version);
        if (repo.transitionOverproduction(company, a.id(), a.version(), login.userId(), from, to, reason) != 1) {
            throw versionConflict();
        }
        return get(approvalId);
    }

    /** 想定外の状態（10・30・40・90 を含む）への操作はすべて 60101（91 §3.14）。 */
    private static void checkStatus(ProductionRepository.ApprovalRow a, short expected) {
        if (a.approvalStatus() != expected) {
            throw invalidApproval("超产申请当前状态不允许此操作，请刷新后重试");
        }
    }

    private static void checkVersion(ProductionRepository.ApprovalRow a, Integer version) {
        if (version == null || version != a.version()) {
            throw versionConflict();
        }
    }

    private static BizException versionConflict() {
        return new BizException(ProductionErrorCode.VERSION_CONFLICT, ProductionErrorCode.MSG_VERSION_CONFLICT,
                "数据已被其他用户更新，请重新获取最新信息后再操作。");
    }

    private static BizException invalidApproval(String msg) {
        return new BizException(ProductionErrorCode.OPA_INVALID, ProductionErrorCode.MSG_OPA_INVALID, msg);
    }

    /** allowed_qty 为 NULL／负值／未快照，或销售订单行已不存在 → 422 / 60101 / MSG-PRD-106（lead 2026-10-21 决定）。 */
    private static BizException allowedUnavailable() {
        return new BizException(ProductionErrorCode.OPA_INVALID, ProductionErrorCode.MSG_OPA_ALLOWED_UNAVAILABLE,
                "超产允许数量不可用或对应的销售订单行已不存在，无法执行此操作");
    }

    private static BizException notFound() {
        return new BizException(ProductionErrorCode.NOT_FOUND, "超产申请不存在");
    }

    private void checkLimit(long company, long lineId, BigDecimal requestQty) {
        BigDecimal rate = repo.findCompanyDecimalParam(company, MAX_RATE_KEY);
        if (rate == null) {
            throw new BizException(ProductionErrorCode.CONFIG_MISSING,
                    "未设置超产申请上限率（sys_param " + MAX_RATE_KEY + "）");
        }
        ProductionRepository.OverproductionLimitBasis basis = repo.findOverproductionLimitBasis(company, lineId)
                .orElseThrow(() -> new BizException(ProductionErrorCode.NOT_FOUND, "受注行不存在"));
        if (basis.decimalPlaces() == null || basis.baseQty() == null) {
            throw new BizException(ProductionErrorCode.CONFIG_MISSING, "受注行基本单位未登记（mdm_uom）");
        }
        if (requestQty.stripTrailingZeros().scale() > basis.decimalPlaces()
                || requestQty.compareTo(basis.baseQty().multiply(rate)) > 0) {
            throw invalidQty();
        }
    }

    private static void checkWorkOrderBelongs(ProductionRepository.WorkOrderRef wo, long lineId, long materialId) {
        if (wo.salesOrderLineId() == null || wo.salesOrderLineId() != lineId || wo.materialId() != materialId) {
            throw woMismatch();
        }
    }

    private static BizException woMismatch() {
        return new BizException(ProductionErrorCode.WO_MATERIAL_MISMATCH, ProductionErrorCode.MSG_WO_MATERIAL_MISMATCH,
                "工单与销售订单行不一致（不属于该受注行或公司）。");
    }

    private static BizException invalidQty() {
        return new BizException(ProductionErrorCode.OPA_INVALID_REQUEST_QTY,
                ProductionErrorCode.MSG_OPA_INVALID_REQUEST_QTY,
                "超産申請数量が不正です。0 より大きく、上限（受注行基本数量 × 上限率）以内、基本単位の小数桁数以内で指定してください。");
    }

    /**
     * 只把以下两种映射为 60103：23502 且列为 {@code "request_qty"}；23514 且约束为 {@code "ck_prd_opa_request_qty"}
     * （V202610210704 拆分后）。{@code ck_prd_opa_allowed_qty} 等其他约束错误原样抛出，不转换为 60103。
     */
    static boolean isRequestQtyViolation(Throwable e) {
        for (Throwable t = e; t != null; t = t.getCause()) {
            if (t instanceof java.sql.SQLException sql) {
                String state = sql.getSQLState();
                String msg = String.valueOf(sql.getMessage());
                if ("23502".equals(state) && msg.contains("\"request_qty\"")) {
                    return true;
                }
                if ("23514".equals(state) && msg.contains("\"ck_prd_opa_request_qty\"")) {
                    return true;
                }
            }
        }
        return false;
    }
}
