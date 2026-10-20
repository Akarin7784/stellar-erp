package com.stellar.erp.production;

import java.time.LocalDate;
import java.time.OffsetDateTime;

import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.baomidou.mybatisplus.core.toolkit.IdWorker;
import com.stellar.erp.common.BizException;
import com.stellar.erp.common.LoginContext;
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

        SalesOrderLine line = salesOrderLines.find(company, cmd.salesOrderLineId())
                .orElseThrow(() -> new BizException(ProductionErrorCode.NOT_FOUND, "受注行不存在"));
        if (cmd.workOrderId() != null) {
            ProductionRepository.WorkOrderRef wo = repo.findWorkOrder(company, cmd.workOrderId())
                    .orElseThrow(() -> new BizException(ProductionErrorCode.NOT_FOUND, "工单不存在"));
            if (wo.materialId() != line.materialId()) {
                throw new BizException(ProductionErrorCode.WO_MATERIAL_MISMATCH,
                        ProductionErrorCode.MSG_WO_MATERIAL_MISMATCH, "工单品目与销售订单行品目不一致。");
            }
        }
        if (line.allowedQty() == null) {
            throw new BizException(ProductionErrorCode.CONFIG_MISSING, "受注行 allowed_qty 尚未快照");
        }
        if (line.allowedQty().signum() < 0) {
            // current_allowed_qty 是受注行快照，负值属于数据不整合，不是申请数量错误 → 5000（不是 60103）
            throw new BizException(ProductionErrorCode.CONFIG_MISSING, "受注行 allowed_qty 为负值，数据不整合");
        }

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

    private static BizException invalidQty() {
        return new BizException(ProductionErrorCode.OPA_INVALID_REQUEST_QTY,
                ProductionErrorCode.MSG_OPA_INVALID_REQUEST_QTY,
                "超産申請数量が不正です。申請超産数量は 0 より大きい値を指定してください。");
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
