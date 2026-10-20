package com.stellar.erp.production;

import java.time.OffsetDateTime;
import java.util.List;

import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.stellar.erp.common.BizException;
import com.stellar.erp.common.LoginContext;

/** 工单詳細（GET /api/production/work-orders/{id}）。tenant は RLS、company は明示条件。 */
@Service
public class WorkOrderQueryService {

    private final JdbcClient jdbc;

    public WorkOrderQueryService(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Transactional(readOnly = true)
    public WorkOrderDetail get(long id) {
        long company = LoginContext.require().companyId();
        List<WorkOrderDetail.Material> materials = jdbc.sql("""
                        SELECT line_no, material_id, material_code, material_name, total_required_qty, uom_code
                          FROM prd_work_order_material WHERE company_id = :c AND work_order_id = :id ORDER BY line_no
                        """).param("c", company).param("id", id)
                .query((rs, i) -> new WorkOrderDetail.Material(rs.getInt(1), rs.getLong(2), rs.getString(3),
                        rs.getString(4), rs.getBigDecimal(5), rs.getString(6)))
                .list();
        List<WorkOrderDetail.Operation> operations = jdbc.sql("""
                        SELECT operation_seq, operation_name, work_center_code, planned_start_date, planned_end_date
                          FROM prd_work_order_operation WHERE company_id = :c AND work_order_id = :id ORDER BY operation_seq
                        """).param("c", company).param("id", id)
                .query((rs, i) -> new WorkOrderDetail.Operation(rs.getInt(1), rs.getString(2), rs.getString(3),
                        rs.getObject(4, java.time.LocalDate.class), rs.getObject(5, java.time.LocalDate.class)))
                .list();
        return jdbc.sql("SELECT * FROM prd_work_order WHERE id = :id AND company_id = :c")
                .param("id", id).param("c", company)
                .query((rs, i) -> {
                    short status = rs.getShort("order_status");
                    return new WorkOrderDetail(rs.getLong("id"), rs.getString("work_order_no"),
                            rs.getShort("work_order_type"), status, WorkOrderDetail.statusName(status),
                            rs.getLong("material_id"), rs.getString("material_code"), rs.getString("material_name"),
                            rs.getString("material_spec"), rs.getString("uom_code"),
                            rs.getLong("factory_id"), rs.getObject("department_id", Long.class),
                            rs.getObject("warehouse_id", Long.class),
                            rs.getBigDecimal("order_qty"), rs.getBigDecimal("allowed_qty"), rs.getBigDecimal("completed_qty"),
                            rs.getObject("planned_start_date", java.time.LocalDate.class),
                            rs.getObject("planned_end_date", java.time.LocalDate.class), rs.getShort("priority_no"),
                            rs.getObject("sales_order_id", Long.class), rs.getObject("sales_order_line_id", Long.class),
                            rs.getString("sales_order_no"), rs.getShort("source_type"), rs.getBoolean("is_hold"),
                            rs.getBigDecimal("over_receipt_rate"), rs.getBigDecimal("standard_cost"),
                            rs.getObject("submitted_at", OffsetDateTime.class), rs.getObject("approved_by", Long.class),
                            rs.getObject("approved_at", OffsetDateTime.class), rs.getObject("released_by", Long.class),
                            rs.getObject("released_at", OffsetDateTime.class), rs.getString("remark"),
                            rs.getInt("version"), materials, operations);
                })
                .optional()
                .orElseThrow(() -> new BizException(ProductionErrorCode.NOT_FOUND, "工单不存在"));
    }
}
