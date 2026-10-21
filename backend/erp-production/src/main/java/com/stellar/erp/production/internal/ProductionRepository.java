package com.stellar.erp.production.internal;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;

import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

/** 生产模块的 SQL（应用数据源 erp_app，RLS 按 app.tenant_id 生效；公司条件显式带上）。 */
@Repository
public class ProductionRepository {

    /** 公司既定参数键（01-system 90 §3.15）。 */
    static final String COMPANY_RATE_KEY = "prd.completion_over_rate";

    private final JdbcClient jdbc;

    public ProductionRepository(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    /** 制造品物料 + 分类上的完工超收容差。 */
    public record MaterialRow(long id, String materialCode, String materialName, String spec,
                              BigDecimal materialRate, BigDecimal categoryRate) {
    }

    public Optional<MaterialRow> findMaterial(long companyId, long materialId) {
        return jdbc.sql("""
                        SELECT m.id, m.material_code, m.material_name, m.spec,
                               m.completion_over_rate AS material_rate,
                               c.completion_over_rate AS category_rate
                          FROM mdm_material m
                          LEFT JOIN mdm_material_category c
                                 ON c.id = m.category_id AND c.company_id = m.company_id AND c.deleted = FALSE
                         WHERE m.id = :id AND m.company_id = :company AND m.deleted = FALSE
                        """)
                .param("id", materialId)
                .param("company", companyId)
                .query((rs, i) -> new MaterialRow(rs.getLong("id"), rs.getString("material_code"),
                        rs.getString("material_name"), rs.getString("spec"),
                        rs.getBigDecimal("material_rate"), rs.getBigDecimal("category_rate")))
                .optional();
    }

    /**
     * 品目計画（{@code prd_material_planning}，物料 × 工厂）の {@code material_type}。行がなければ空。
     * 10:采购品 20:制造品 30:委外品 40:虚拟件 50:外注部品。
     */
    public Optional<Short> findPlanningMaterialType(long companyId, long materialId, long factoryId) {
        return jdbc.sql("""
                        SELECT material_type FROM prd_material_planning
                         WHERE company_id = :company AND material_id = :material AND factory_id = :factory
                           AND deleted = FALSE
                        """)
                .param("company", companyId).param("material", materialId).param("factory", factoryId)
                .query(Short.class).optional();
    }

    /** 有効倉庫（当前公司、未删除、status=1）。 */
    public boolean warehouseExists(long companyId, long warehouseId) {
        return jdbc.sql("""
                        SELECT count(*) FROM mdm_warehouse
                         WHERE id = :id AND company_id = :company AND deleted = FALSE AND status = 1
                        """)
                .param("id", warehouseId).param("company", companyId)
                .query(Long.class).single() > 0;
    }

    public boolean departmentExists(long companyId, long departmentId) {
        return jdbc.sql("SELECT count(*) FROM sys_department WHERE id = :id AND company_id = :company AND deleted = FALSE")
                .param("id", departmentId).param("company", companyId)
                .query(Long.class).single() > 0;
    }

    public boolean factoryExists(long companyId, long factoryId) {
        return jdbc.sql("SELECT count(*) FROM mdm_factory WHERE id = :id AND company_id = :company AND deleted = FALSE")
                .param("id", factoryId).param("company", companyId)
                .query(Long.class).single() > 0;
    }

    /**
     * 当前公司的 {@code prd.completion_over_rate}。只取当前公司的行，不回退到 {@code company_id = 0}
     * （Lead 2026-10-21 决定）。缺失或无法解析为数值时返回 NULL（调用方报 5000）。
     *
     * <p>{@code deleted = FALSE} 必须保留：唯一索引 {@code uk_sys_param_key (tenant_id, company_id, param_key) WHERE deleted = FALSE}
     * （sys/V202610210103__sys_t1_core_tables.sql:166）保证同一租户（RLS）+ 公司 + 键下未删除的行至多一行，
     * 因此本查询最多返回一行，不需要 ORDER BY / LIMIT。</p>
     */
    public BigDecimal findCompanyOverRate(long companyId) {
        return findCompanyDecimalParam(companyId, COMPANY_RATE_KEY);
    }

    /** 当前公司的数值型 sys_param（同 {@link #findCompanyOverRate} 口径：只取当前公司、不回退 company_id = 0；缺失/不可解析 → NULL）。 */
    public BigDecimal findCompanyDecimalParam(long companyId, String paramKey) {
        List<String> values = jdbc.sql("""
                        SELECT param_value
                          FROM sys_param
                         WHERE param_key = :key
                           AND company_id = :company
                           AND status = 1
                           AND deleted = FALSE
                        """)
                .param("key", paramKey)
                .param("company", companyId)
                .query(String.class).list();
        if (values.isEmpty() || values.get(0) == null || values.get(0).isBlank()) {
            return null;
        }
        try {
            return new BigDecimal(values.get(0).trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }

    /**
     * 当日连番（{@code sys_sequence}，日次リセット、同一事务内采番，00-common 08 §2）。
     * 返回自增后的值。
     */
    public long nextSequence(long companyId, String sequenceKey, LocalDate date, long newId) {
        return jdbc.sql("""
                        INSERT INTO sys_sequence (id, company_id, sequence_key, sequence_date, current_value, step)
                        VALUES (:id, :company, :key, :date, 1, 1)
                        ON CONFLICT (tenant_id, company_id, sequence_key, sequence_date)
                        DO UPDATE SET current_value = sys_sequence.current_value + sys_sequence.step,
                                      version = sys_sequence.version + 1,
                                      updated_at = now()
                        RETURNING current_value
                        """)
                .param("id", newId).param("company", companyId).param("key", sequenceKey).param("date", date)
                .query(Long.class).single();
    }

    /** 插入工单（只写本切片涉及的列；其余列用 DDL 默认值，standard_cost 不写＝NULL）。 */
    public record WorkOrderInsert(long id, long companyId, long userId, String workOrderNo, short workOrderType,
                                  MaterialRow material, String uomCode, long factoryId, Long departmentId,
                                  Long warehouseId, BigDecimal orderQty, BigDecimal allowedQty,
                                  LocalDate plannedStartDate, LocalDate plannedEndDate, short orderStatus,
                                  short priorityNo, Long salesOrderId, Long salesOrderLineId, String salesOrderNo,
                                  short sourceType, boolean backflush, BigDecimal overReceiptRate, String remark) {
    }

    public void insertWorkOrder(WorkOrderInsert w) {
        jdbc.sql("""
                        INSERT INTO prd_work_order (
                            id, company_id, created_by, updated_by, remark,
                            work_order_no, work_order_type, material_id, material_code, material_name, material_spec,
                            uom_code, factory_id, department_id, warehouse_id, order_qty, allowed_qty,
                            planned_start_date, planned_end_date, order_status, priority_no,
                            sales_order_id, sales_order_line_id, sales_order_no, source_type, is_backflush,
                            over_receipt_rate)
                        VALUES (
                            :id, :company, :user, :user, :remark,
                            :no, :type, :materialId, :materialCode, :materialName, :materialSpec,
                            :uom, :factory, :department, :warehouse, :orderQty, :allowedQty,
                            :start, :end, :status, :priority,
                            :soId, :soLineId, :soNo, :sourceType, :backflush,
                            :rate)
                        """)
                .param("id", w.id()).param("company", w.companyId()).param("user", w.userId())
                .param("remark", w.remark())
                .param("no", w.workOrderNo()).param("type", w.workOrderType())
                .param("materialId", w.material().id()).param("materialCode", w.material().materialCode())
                .param("materialName", w.material().materialName()).param("materialSpec", w.material().spec())
                .param("uom", w.uomCode()).param("factory", w.factoryId())
                .param("department", w.departmentId()).param("warehouse", w.warehouseId())
                .param("orderQty", w.orderQty()).param("allowedQty", w.allowedQty())
                .param("start", w.plannedStartDate()).param("end", w.plannedEndDate())
                .param("status", w.orderStatus()).param("priority", w.priorityNo())
                .param("soId", w.salesOrderId()).param("soLineId", w.salesOrderLineId())
                .param("soNo", w.salesOrderNo()).param("sourceType", w.sourceType())
                .param("backflush", w.backflush()).param("rate", w.overReceiptRate())
                .update();
    }

    /** 下达用：工单行（FOR UPDATE 后读取）。 */
    public record WorkOrderForRelease(long id, String workOrderNo, long materialId, Long salesOrderLineId,
                                      short orderStatus, boolean hold, int version, long factoryId,
                                      LocalDate plannedStartDate, BigDecimal orderQty) {
    }

    /** BOM 展開で作る材料行（CALC-WO-01/02 計算済み）。 */
    public record MaterialLineInsert(long id, long companyId, long userId, long workOrderId, int lineNo, long bomLineId,
                                     Integer operationSeq, long materialId, String materialCode, String materialName,
                                     String uomCode, BigDecimal requiredQty, BigDecimal lossRate, BigDecimal lossQty,
                                     BigDecimal totalRequiredQty, boolean keyPart, String substituteGroup,
                                     String bomUomCode, BigDecimal bomQty) {
    }

    /** 物料の基本単位（当前公司、未删除）。 */
    public Optional<String> findBaseUom(long companyId, long materialId) {
        return jdbc.sql("SELECT base_uom_code FROM mdm_material WHERE id = :id AND company_id = :c AND deleted = FALSE")
                .param("id", materialId).param("c", companyId).query(String.class).optional();
    }

    /** 単位整合の再チェック用：材料行と物料基本単位（物料が見つからない行は baseUom=NULL）。 */
    public record MaterialLineUom(long id, int lineNo, long materialId, String uomCode, String bomUomCode,
                                  String baseUom) {
    }

    public List<MaterialLineUom> listMaterialLineUoms(long companyId, long workOrderId) {
        return jdbc.sql("""
                        SELECT l.id, l.line_no, l.material_id, l.uom_code, l.bom_uom_code, m.base_uom_code
                          FROM prd_work_order_material l
                          LEFT JOIN mdm_material m ON m.id = l.material_id AND m.company_id = l.company_id AND m.deleted = FALSE
                         WHERE l.company_id = :c AND l.work_order_id = :wo
                         ORDER BY l.line_no, l.id
                        """)
                .param("c", companyId).param("wo", workOrderId)
                .query((rs, i) -> new MaterialLineUom(rs.getLong(1), rs.getInt(2), rs.getLong(3), rs.getString(4),
                        rs.getString(5), rs.getString(6)))
                .list();
    }

    public Optional<LocalDate> findPlannedStartDate(long companyId, long workOrderId) {
        return jdbc.sql("SELECT planned_start_date FROM prd_work_order WHERE id = :id AND company_id = :c")
                .param("id", workOrderId).param("c", companyId).query(LocalDate.class).optional();
    }

    public void insertMaterialLine(MaterialLineInsert m) {
        jdbc.sql("""
                        INSERT INTO prd_work_order_material (id, company_id, created_by, updated_by, work_order_id, line_no,
                            bom_line_id, operation_seq, material_id, material_code, material_name, uom_code, required_qty,
                            loss_rate, loss_qty, total_required_qty, remaining_qty, is_key_part, substitute_group,
                            bom_uom_code, bom_qty)
                        VALUES (:id, :company, :user, :user, :wo, :lineNo, :bomLine, :opSeq, :material, :code, :name, :uom,
                            :req, :lossRate, :lossQty, :total, :total, :key, :sub, :bomUom, :bomQty)
                        """)
                .param("id", m.id()).param("company", m.companyId()).param("user", m.userId())
                .param("wo", m.workOrderId()).param("lineNo", m.lineNo()).param("bomLine", m.bomLineId())
                .param("opSeq", m.operationSeq()).param("material", m.materialId()).param("code", m.materialCode())
                .param("name", m.materialName()).param("uom", m.uomCode()).param("req", m.requiredQty())
                .param("lossRate", m.lossRate()).param("lossQty", m.lossQty()).param("total", m.totalRequiredQty())
                .param("key", m.keyPart()).param("sub", m.substituteGroup())
                .param("bomUom", m.bomUomCode()).param("bomQty", m.bomQty())
                .update();
    }


    /** 不加锁读取工单的受注行 ID（用于决定是否需要先锁受注行）。 */
    public Optional<WorkOrderForRelease> findWorkOrderForRelease(long companyId, long workOrderId) {
        return selectForRelease(companyId, workOrderId, "");
    }

    /** {@code FOR UPDATE} 锁工单（lock_timeout 3 秒，91 §3.2「工单行ロック（FOR UPDATE、3 秒待ち）」）。 */
    public Optional<WorkOrderForRelease> lockWorkOrderForRelease(long companyId, long workOrderId) {
        jdbc.sql("SELECT set_config('lock_timeout', '3s', true)").query(String.class).single();
        return selectForRelease(companyId, workOrderId, " FOR UPDATE");
    }

    private Optional<WorkOrderForRelease> selectForRelease(long companyId, long workOrderId, String lock) {
        return jdbc.sql("""
                        SELECT id, work_order_no, material_id, sales_order_line_id, order_status, is_hold, version,
                               factory_id, planned_start_date, order_qty
                          FROM prd_work_order WHERE id = :id AND company_id = :company
                        """ + lock)
                .param("id", workOrderId).param("company", companyId)
                .query((rs, i) -> new WorkOrderForRelease(rs.getLong("id"), rs.getString("work_order_no"),
                        rs.getLong("material_id"), (Long) rs.getObject("sales_order_line_id", Long.class),
                        rs.getShort("order_status"), rs.getBoolean("is_hold"), rs.getInt("version"),
                        rs.getLong("factory_id"), rs.getObject("planned_start_date", LocalDate.class),
                        rs.getBigDecimal("order_qty")))
                .optional();
    }

    /**
     * 下达日の期間に有効な発行済み標準原価（02-work-order §6.4 第 4 項）：
     * {@code status = 40} かつ {@code period_from ≤ 期間 ≤ COALESCE(period_to, ∞)}。期間は月初日。
     * 発行済み版の期間重複は ex_fin_standard_cost_period（EXCLUDE）で禁止されているため最大 1 行。
     */
    public Optional<BigDecimal> findEffectiveStandardCost(long companyId, long materialId, LocalDate periodMonth) {
        return jdbc.sql("""
                        SELECT total_unit_cost FROM fin_standard_cost
                         WHERE company_id = :company AND material_id = :material AND status = 40
                           AND period_from <= :month AND (period_to IS NULL OR period_to >= :month)
                        """)
                .param("company", companyId).param("material", materialId).param("month", periodMonth)
                .query(BigDecimal.class).optional();
    }

    /**
     * 25→30。standard_cost はここで一度だけスナップショット（NULL 可）。
     * 乐观锁：WHERE 同时带 company / status / version（00-common：UPDATE 必须带 version 与 company 条件），
     * 0 行时由调用方映射为 4003。
     */
    public int markReleased(long companyId, long workOrderId, int version, long userId, BigDecimal standardCost,
                            BigDecimal allowedQty, boolean copyAllowedQty) {
        return jdbc.sql("""
                        UPDATE prd_work_order
                           SET order_status = 30, released_by = :user, released_at = now(),
                               standard_cost = :cost,
                               allowed_qty = CASE WHEN :copy THEN :allowed ELSE allowed_qty END,
                               version = version + 1, updated_by = :user, updated_at = now()
                         WHERE id = :id AND company_id = :company AND order_status = 25
                           AND version = :version
                        """)
                .param("user", userId).param("cost", standardCost)
                .param("copy", copyAllowedQty).param("allowed", allowedQty)
                .param("id", workOrderId).param("company", companyId).param("version", version)
                .update();
    }

    /** 提出・承認用：工单行（FOR UPDATE）。 */
    public record WorkOrderForApproval(long id, short orderStatus, int version, long createdBy) {
    }

    public Optional<WorkOrderForApproval> lockWorkOrderForApproval(long companyId, long workOrderId) {
        jdbc.sql("SELECT set_config('lock_timeout', '3s', true)").query(String.class).single();
        return jdbc.sql("""
                        SELECT id, order_status, version, created_by FROM prd_work_order
                         WHERE id = :id AND company_id = :company FOR UPDATE
                        """)
                .param("id", workOrderId).param("company", companyId)
                .query((rs, i) -> new WorkOrderForApproval(rs.getLong("id"), rs.getShort("order_status"),
                        rs.getInt("version"), rs.getLong("created_by")))
                .optional();
    }

    public long countWorkOrderOperations(long companyId, long workOrderId) {
        return jdbc.sql("SELECT count(*) FROM prd_work_order_operation WHERE company_id = :company AND work_order_id = :id")
                .param("company", companyId).param("id", workOrderId).query(Long.class).single();
    }

    public long countWorkOrderMaterials(long companyId, long workOrderId) {
        return jdbc.sql("SELECT count(*) FROM prd_work_order_material WHERE company_id = :company AND work_order_id = :id")
                .param("company", companyId).param("id", workOrderId).query(Long.class).single();
    }

    /** 10→20（T-01）。 */
    public int markSubmitted(long companyId, long workOrderId, int version, long userId) {
        return jdbc.sql("""
                        UPDATE prd_work_order
                           SET order_status = 20, submitted_at = now(),
                               version = version + 1, updated_by = :user, updated_at = now()
                         WHERE id = :id AND company_id = :company AND order_status = 10 AND version = :version
                        """)
                .param("version", version).param("user", userId).param("id", workOrderId).param("company", companyId).update();
    }

    /** 20→25（T-02）。 */
    public int markApproved(long companyId, long workOrderId, int version, long userId) {
        return jdbc.sql("""
                        UPDATE prd_work_order
                           SET order_status = 25, approved_by = :user, approved_at = now(),
                               version = version + 1, updated_by = :user, updated_at = now()
                         WHERE id = :id AND company_id = :company AND order_status = 20 AND version = :version
                        """)
                .param("version", version).param("user", userId).param("id", workOrderId).param("company", companyId).update();
    }

    /** 工单（超产申请校验用）。 */
    public record WorkOrderRef(long id, long materialId, Long salesOrderLineId) {
    }

    public Optional<WorkOrderRef> findWorkOrder(long companyId, long workOrderId) {
        return jdbc.sql("""
                        SELECT id, material_id, sales_order_line_id
                          FROM prd_work_order WHERE id = :id AND company_id = :company
                        """)
                .param("id", workOrderId).param("company", companyId)
                .query((rs, i) -> new WorkOrderRef(rs.getLong("id"), rs.getLong("material_id"),
                        (Long) rs.getObject("sales_order_line_id", Long.class)))
                .optional();
    }

    public record ApprovalInsert(long id, long companyId, long userId, String approvalNo, long salesOrderId,
                                 long salesOrderLineId, Long workOrderId, long materialId, BigDecimal requestQty,
                                 BigDecimal currentAllowedQty, short approvalStatus, OffsetDateTime requestedAt,
                                 String remark) {
    }

    public void insertApproval(ApprovalInsert a) {
        jdbc.sql("""
                        INSERT INTO prd_overproduction_approval (
                            id, company_id, created_by, updated_by, remark,
                            approval_no, sales_order_id, sales_order_line_id, work_order_id, material_id,
                            request_qty, current_allowed_qty, approval_status, requested_by, requested_at)
                        VALUES (
                            :id, :company, :user, :user, :remark,
                            :no, :soId, :soLineId, :woId, :materialId,
                            :requestQty, :currentAllowed, :status, :user, :requestedAt)
                        """)
                .param("id", a.id()).param("company", a.companyId()).param("user", a.userId())
                .param("remark", a.remark()).param("no", a.approvalNo())
                .param("soId", a.salesOrderId()).param("soLineId", a.salesOrderLineId())
                .param("woId", a.workOrderId()).param("materialId", a.materialId())
                .param("requestQty", a.requestQty()).param("currentAllowed", a.currentAllowedQty())
                .param("status", a.approvalStatus()).param("requestedAt", a.requestedAt())
                .update();
    }

    // ------------------------------------------------------------------ 超产申请 / 承認（90 §3.19.1、G2-18 6.）

    /**
     * 超产申请上限的基准：受注行 {@code base_qty}（基本单位）与基本单位 {@code mdm_uom.decimal_places}。
     * 单位未登记时 {@code decimalPlaces} 为 NULL（调用方报 5000）。
     */
    public record OverproductionLimitBasis(BigDecimal baseQty, Integer decimalPlaces) {
    }

    public Optional<OverproductionLimitBasis> findOverproductionLimitBasis(long companyId, long salesOrderLineId) {
        return jdbc.sql("""
                        SELECT l.base_qty, u.decimal_places
                          FROM sal_sales_order_line l
                          LEFT JOIN mdm_uom u
                            ON u.company_id = l.company_id AND u.uom_code = l.base_uom_code AND u.deleted = FALSE
                         WHERE l.id = :id AND l.company_id = :company
                        """)
                .param("id", salesOrderLineId).param("company", companyId)
                .query((rs, i) -> new OverproductionLimitBasis(rs.getBigDecimal(1), (Integer) rs.getObject(2, Integer.class)))
                .optional();
    }

    /** 超产承認用：申请行（{@code lock = true} 时 FOR UPDATE）。 */
    public record ApprovalRow(long id, String approvalNo, long salesOrderLineId, Long workOrderId, BigDecimal requestQty,
                              short approvalStatus, int version) {
    }

    public Optional<ApprovalRow> findApproval(long companyId, long approvalId, boolean lock) {
        return jdbc.sql("""
                        SELECT id, approval_no, sales_order_line_id, work_order_id, request_qty, approval_status, version
                          FROM prd_overproduction_approval
                         WHERE id = :id AND company_id = :company
                        """ + (lock ? " FOR UPDATE" : ""))
                .param("id", approvalId).param("company", companyId)
                .query((rs, i) -> new ApprovalRow(rs.getLong(1), rs.getString(2), rs.getLong(3),
                        (Long) rs.getObject(4, Long.class), rs.getBigDecimal(5), rs.getShort(6), rs.getInt(7)))
                .optional();
    }

    /** 工单 FOR UPDATE（受注行の後に取る：00-common 04 §11.1）。 */
    public Optional<WorkOrderRef> lockWorkOrderRef(long companyId, long workOrderId) {
        return jdbc.sql("""
                        SELECT id, material_id, sales_order_line_id
                          FROM prd_work_order WHERE id = :id AND company_id = :company FOR UPDATE
                        """)
                .param("id", workOrderId).param("company", companyId)
                .query((rs, i) -> new WorkOrderRef(rs.getLong("id"), rs.getLong("material_id"),
                        (Long) rs.getObject("sales_order_line_id", Long.class)))
                .optional();
    }

    /** 受注行 {@code allowed_qty += delta}。返回更新后的值；0 行时为空。 */
    public Optional<BigDecimal> addSalesOrderLineAllowedQty(long companyId, long salesOrderLineId, BigDecimal delta,
                                                            long userId) {
        return jdbc.sql("""
                        UPDATE sal_sales_order_line
                           SET allowed_qty = allowed_qty + :delta, version = version + 1,
                               updated_by = :user, updated_at = now()
                         WHERE id = :id AND company_id = :company AND allowed_qty IS NOT NULL
                        RETURNING allowed_qty
                        """)
                .param("delta", delta).param("user", userId).param("id", salesOrderLineId).param("company", companyId)
                .query(BigDecimal.class).optional();
    }

    /** 工单 {@code allowed_qty += delta}（option B）。返回更新行数。 */
    public int addWorkOrderAllowedQty(long companyId, long workOrderId, BigDecimal delta, long userId) {
        return jdbc.sql("""
                        UPDATE prd_work_order
                           SET allowed_qty = allowed_qty + :delta, version = version + 1,
                               updated_by = :user, updated_at = now()
                         WHERE id = :id AND company_id = :company AND allowed_qty IS NOT NULL
                        """)
                .param("delta", delta).param("user", userId).param("id", workOrderId).param("company", companyId)
                .update();
    }

    /** 申请 → 30（承認済）。{@code approved_allowed_qty} は承認後の受注行上限スナップショット。 */
    public int markOverproductionApproved(long companyId, long approvalId, int version, long userId,
                                          BigDecimal approvedAllowedQty) {
        return jdbc.sql("""
                        UPDATE prd_overproduction_approval
                           SET approval_status = 30, approved_by = :user, approved_at = now(),
                               approved_allowed_qty = :approved,
                               version = version + 1, updated_by = :user, updated_at = now()
                         WHERE id = :id AND company_id = :company AND approval_status IN (10, 20) AND version = :version
                        """)
                .param("user", userId).param("approved", approvedAllowedQty).param("id", approvalId)
                .param("company", companyId).param("version", version)
                .update();
    }
}
