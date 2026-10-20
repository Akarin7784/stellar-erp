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
        List<String> values = jdbc.sql("""
                        SELECT param_value
                          FROM sys_param
                         WHERE param_key = :key
                           AND company_id = :company
                           AND status = 1
                           AND deleted = FALSE
                        """)
                .param("key", COMPANY_RATE_KEY)
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
}
