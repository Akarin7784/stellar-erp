package com.stellar.erp.production;

import java.math.BigDecimal;
import java.time.LocalDate;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.baomidou.mybatisplus.core.toolkit.IdWorker;
import com.stellar.erp.common.BizException;
import com.stellar.erp.common.LoginContext;
import com.stellar.erp.production.SalesOrderLineLookup.SalesOrderLine;
import com.stellar.erp.production.internal.DocumentNumbers;
import com.stellar.erp.production.internal.OverReceiptRateResolver;
import com.stellar.erp.production.internal.ProductionRepository;
import com.stellar.erp.production.internal.ProductionRepository.MaterialRow;
import com.stellar.erp.production.internal.ProductionRepository.WorkOrderInsert;

/**
 * 工单登録（PRC-PRD-002-01，02-work-order §6.2）的最小切片：
 * 入力チェック → 公司取自登录上下文 → 容差チェーン解決 → 采番 → INSERT（order_status=10、standard_cost=NULL）。
 *
 * <p>未实装（后续任务）：BOM/工艺解決（MSG-PRD-020/021）与材料・工序展開、子工单、权限/数据范围、审计日志、
 * Idempotency-Key。</p>
 */
@Service
public class WorkOrderService {

    /** sys_sequence キー（02-work-order §6.2 / 90 §採番）。 */
    static final String SEQ_KEY = "PRD_WORK_ORDER";
    static final String PREFIX = "WO";
    static final short STATUS_DRAFT = 10;
    /** source_type 20:手工 / 30:受注（90 §3.19）。 */
    static final short SOURCE_MANUAL = 20;
    static final short SOURCE_SALES_ORDER = 30;

    private final ProductionRepository repo;
    private final SalesOrderLineLookup salesOrderLines;

    public WorkOrderService(ProductionRepository repo, SalesOrderLineLookup salesOrderLines) {
        this.repo = repo;
        this.salesOrderLines = salesOrderLines;
    }

    @Transactional
    public WorkOrderCreated create(WorkOrderCreateCommand cmd) {
        LoginContext.LoginUser login = LoginContext.require();
        long company = login.companyId();

        if (cmd.orderQty() == null || cmd.orderQty().signum() <= 0) {
            throw new BizException(1001, "MSG-COM-047", "数量必须大于 0。");
        }
        if (cmd.plannedStartDate().isAfter(cmd.plannedEndDate())) {
            throw new BizException(1001, "MSG-COM-045", "「计划着手日」不能大于「计划完成日」。");
        }

        MaterialRow material = repo.findMaterial(company, cmd.materialId())
                .orElseThrow(() -> new BizException(ProductionErrorCode.NOT_FOUND, "物料不存在"));
        if (!repo.factoryExists(company, cmd.factoryId())) {
            throw new BizException(ProductionErrorCode.NOT_FOUND, "工厂不存在");
        }

        SalesOrderLine line = null;
        if (cmd.salesOrderLineId() != null) {
            line = salesOrderLines.find(company, cmd.salesOrderLineId())
                    .orElseThrow(() -> new BizException(ProductionErrorCode.NOT_FOUND, "受注行不存在"));
            if (line.materialId() != material.id()) {
                throw new BizException(ProductionErrorCode.WO_MATERIAL_MISMATCH,
                        ProductionErrorCode.MSG_WO_MATERIAL_MISMATCH, "工单品目与销售订单行品目不一致。");
            }
        }

        BigDecimal rate = OverReceiptRateResolver.resolve(
                line != null ? line.completionOverRate() : null,
                material.materialRate(),
                material.categoryRate(),
                () -> repo.findCompanyOverRate(company));

        String no = DocumentNumbers.next(repo, company, SEQ_KEY, PREFIX, LocalDate.now());
        long id = IdWorker.getId();
        short status = STATUS_DRAFT;
        BigDecimal allowedQty = line != null ? line.allowedQty() : null;
        repo.insertWorkOrder(new WorkOrderInsert(
                id, company, login.userId(), no,
                cmd.workOrderType() != null ? cmd.workOrderType() : 10,
                material, cmd.uomCode(), cmd.factoryId(), cmd.departmentId(), cmd.warehouseId(),
                cmd.orderQty(), allowedQty, cmd.plannedStartDate(), cmd.plannedEndDate(), status,
                cmd.priorityNo() != null ? cmd.priorityNo() : 5,
                line != null ? line.salesOrderId() : null,
                line != null ? line.id() : null,
                line != null ? line.salesOrderNo() : null,
                line != null ? SOURCE_SALES_ORDER : SOURCE_MANUAL,
                Boolean.TRUE.equals(cmd.isBackflush()),
                rate, cmd.remark()));

        return new WorkOrderCreated(id, no, status, material.materialCode(), material.materialName(),
                cmd.orderQty(), rate, allowedQty, null, 0);
    }
}
