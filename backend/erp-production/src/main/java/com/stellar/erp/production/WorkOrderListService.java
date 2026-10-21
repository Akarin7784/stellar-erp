package com.stellar.erp.production;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;

import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.stellar.erp.common.BizException;
import com.stellar.erp.common.LoginContext;
import com.stellar.erp.common.PageResult;
import com.stellar.erp.common.TenantContext;
import com.stellar.erp.system.FactoryDataScope;

/**
 * 工单一覧 GET /api/production/work-orders（06/91 §3.15、AC-PRD-22）。
 *
 * <p>租户・会社はログインコンテキスト（{@code tenant_id}＋{@code company_id} を明示条件、RLS 併用）。
 * 工单号は前方一致、品目（コード・名称）・受注番号は部分一致で、いずれも {@code prd_work_order} のスナップショット列を
 * 照合し他表は結合しない。入力の {@code %}・{@code _}・{@code \} はエスケープし {@code LIKE … ESCAPE '\'}。</p>
 */
@Service
public class WorkOrderListService {

    public static final int DATA_SCOPE_DENIED = 3002;
    public static final String MSG_DATA_SCOPE_DENIED = "MSG-COM-031";
    static final String RESOURCE = "production:work-order";

    /** sort 許可キー → 列（SQL 断片はこの固定表からのみ組み立てる）。 */
    static final Map<String, String> SORT_COLUMNS = Map.of(
            "workOrderNo", "w.work_order_no", "plannedStartDate", "w.planned_start_date",
            "plannedEndDate", "w.planned_end_date", "priorityNo", "w.priority_no",
            "orderStatus", "w.order_status", "createdAt", "w.created_at");
    static final String DEFAULT_ORDER = "w.planned_end_date ASC, w.priority_no ASC, w.work_order_no ASC, w.id ASC";

    private final JdbcClient jdbc;
    private final FactoryDataScope scope;

    public WorkOrderListService(JdbcClient jdbc, FactoryDataScope scope) {
        this.jdbc = jdbc;
        this.scope = scope;
    }

    @Transactional(readOnly = true)
    public PageResult<WorkOrderListDto> list(WorkOrderListQuery q) {
        LoginContext.LoginUser login = LoginContext.require();
        long tenant = TenantContext.currentTenantId();
        long company = login.companyId();
        Optional<Set<Long>> factories = scope.allowedFactories(login.userId(), company, "production", RESOURCE);
        if (q.factoryId() != null && factories.isPresent() && !factories.get().contains(q.factoryId())) {
            throw new BizException(DATA_SCOPE_DENIED, MSG_DATA_SCOPE_DENIED, "您没有查看该数据的权限。");
        }

        StringBuilder where = new StringBuilder("w.tenant_id = :tenant AND w.company_id = :company");
        Map<String, Object> p = new java.util.HashMap<>();
        p.put("tenant", tenant);
        p.put("company", company);
        if (q.factoryId() == null && factories.isPresent()) {
            if (factories.get().isEmpty()) {
                return PageResult.of(List.of(), 0, q.pageNum(), q.pageSize());
            }
            where.append(" AND w.factory_id IN (:scopeFactories)");
            p.put("scopeFactories", List.copyOf(factories.get()));
        }
        if (q.workOrderNo() != null) {
            where.append(" AND w.work_order_no LIKE :woNo || '%' ESCAPE '\\'");
            p.put("woNo", escapeLike(q.workOrderNo()));
        }
        if (q.material() != null) {
            where.append(" AND (w.material_code ILIKE '%' || :mat || '%' ESCAPE '\\'"
                    + " OR w.material_name ILIKE '%' || :mat || '%' ESCAPE '\\')");
            p.put("mat", escapeLike(q.material()));
        }
        if (q.salesOrderNo() != null) {
            where.append(" AND w.sales_order_no ILIKE '%' || :soNo || '%' ESCAPE '\\'");
            p.put("soNo", escapeLike(q.salesOrderNo()));
        }
        eq(where, p, "w.work_order_type", "woType", q.workOrderType());
        if (q.status() != null && !q.status().isEmpty()) {
            where.append(" AND w.order_status IN (:status)");
            p.put("status", q.status());
        }
        range(where, p, "w.planned_start_date", "psFrom", q.plannedStartDateFrom(), "psTo", q.plannedStartDateTo());
        range(where, p, "w.planned_end_date", "peFrom", q.plannedEndDateFrom(), "peTo", q.plannedEndDateTo());
        eq(where, p, "w.factory_id", "factory", q.factoryId());
        eq(where, p, "w.department_id", "dept", q.departmentId());
        eq(where, p, "w.customer_id", "customer", q.customerId());
        eq(where, p, "w.priority_no", "priority", q.priorityNo());
        eq(where, p, "w.source_type", "sourceType", q.sourceType());
        eq(where, p, "w.is_hold", "hold", q.isHold());

        Long total = jdbc.sql("SELECT count(*) FROM prd_work_order w WHERE " + where).params(p)
                .query(Long.class).single();
        if (total == 0) {
            return PageResult.of(List.of(), 0, q.pageNum(), q.pageSize());
        }
        p.put("limit", q.pageSize());
        p.put("offset", (long) (q.pageNum() - 1) * q.pageSize());
        List<WorkOrderListDto> rows = jdbc.sql("""
                        SELECT w.id, w.work_order_no, w.work_order_type, w.material_id, w.material_code, w.material_name,
                               w.material_spec, w.uom_code, w.order_qty, w.completed_qty, w.reported_good_qty,
                               w.progress_rate, w.planned_start_date, w.planned_end_date, w.order_status, w.priority_no,
                               w.source_type, w.is_hold, w.factory_id, f.factory_code, f.factory_name,
                               w.department_id, d.department_name, w.sales_order_id, w.sales_order_no,
                               w.customer_id, c.customer_name, w.version
                          FROM prd_work_order w
                          LEFT JOIN mdm_factory f
                            ON f.tenant_id = w.tenant_id AND f.company_id = w.company_id AND f.id = w.factory_id
                          LEFT JOIN sys_department d
                            ON d.tenant_id = w.tenant_id AND d.company_id = w.company_id AND d.id = w.department_id
                          LEFT JOIN mdm_customer c
                            ON c.tenant_id = w.tenant_id AND c.company_id = w.company_id AND c.id = w.customer_id
                         WHERE %s
                         ORDER BY %s
                         LIMIT :limit OFFSET :offset
                        """.formatted(where, orderBy(q.sort())))
                .params(p)
                .query((rs, i) -> new WorkOrderListDto(rs.getLong("id"), rs.getString("work_order_no"),
                        rs.getShort("work_order_type"), rs.getLong("material_id"), rs.getString("material_code"),
                        rs.getString("material_name"), rs.getString("material_spec"), rs.getString("uom_code"),
                        plain(rs.getBigDecimal("order_qty")), plain(rs.getBigDecimal("completed_qty")),
                        plain(rs.getBigDecimal("reported_good_qty")), plain(rs.getBigDecimal("progress_rate")),
                        rs.getObject("planned_start_date", LocalDate.class),
                        rs.getObject("planned_end_date", LocalDate.class), rs.getShort("order_status"),
                        rs.getShort("priority_no"), rs.getShort("source_type"), rs.getBoolean("is_hold"),
                        rs.getLong("factory_id"), rs.getString("factory_code"), rs.getString("factory_name"),
                        rs.getObject("department_id", Long.class), rs.getString("department_name"),
                        rs.getObject("sales_order_id", Long.class), rs.getString("sales_order_no"),
                        rs.getObject("customer_id", Long.class), rs.getString("customer_name"), rs.getInt("version")))
                .list();
        return PageResult.of(rows, total, q.pageNum(), q.pageSize());
    }

    /** {@code \}・{@code %}・{@code _} を {@code \} でエスケープ（ワイルドカード付与前）。 */
    public static String escapeLike(String s) {
        return s.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_");
    }

    static String orderBy(List<WorkOrderListQuery.Sort> sort) {
        if (sort == null || sort.isEmpty()) {
            return DEFAULT_ORDER;
        }
        List<String> parts = new ArrayList<>();
        for (WorkOrderListQuery.Sort s : sort) {
            String col = SORT_COLUMNS.get(s.key());
            if (col == null) {
                throw new IllegalArgumentException("sort key not allowed: " + s.key());
            }
            parts.add(col + (s.desc() ? " DESC" : " ASC"));
        }
        parts.add("w.id ASC");
        return String.join(", ", parts);
    }

    private static void eq(StringBuilder where, Map<String, Object> p, String col, String name, Object v) {
        if (v != null) {
            where.append(" AND ").append(col).append(" = :").append(name);
            p.put(name, v);
        }
    }

    private static void range(StringBuilder where, Map<String, Object> p, String col, String fromName, LocalDate from,
                              String toName, LocalDate to) {
        if (from != null) {
            where.append(" AND ").append(col).append(" >= :").append(fromName);
            p.put(fromName, from);
        }
        if (to != null) {
            where.append(" AND ").append(col).append(" <= :").append(toName);
            p.put(toName, to);
        }
    }

    private static String plain(BigDecimal v) {
        return v == null ? null : v.stripTrailingZeros().toPlainString();
    }
}
