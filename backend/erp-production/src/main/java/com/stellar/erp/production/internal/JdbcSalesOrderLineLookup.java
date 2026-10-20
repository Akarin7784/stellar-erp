package com.stellar.erp.production.internal;

import java.util.Optional;

import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

import com.stellar.erp.common.TenantContext;
import com.stellar.erp.production.SalesOrderLineLookup;

/**
 * 受注行读取（sal/V202610210705 的正式表 {@code sal_sales_order_line} / {@code sal_sales_order}）。
 *
 * <p>RLS 按 {@code app.tenant_id} 生效，这里仍显式带 {@code tenant_id}（来自 {@link TenantContext}）与
 * {@code company_id}（来自调用方的 LoginContext），不属于当前租户 / 公司的行一律视为不存在。</p>
 *
 * <p>{@link #lockForUpdate} 只锁受注行（{@code FOR UPDATE OF l}），不锁受注头；调用方随后再锁工单
 * （00-common 04 §11.1：受注行 → 工单）。{@code lock_timeout} 与工单锁一致为 3 秒。</p>
 */
@Repository
class JdbcSalesOrderLineLookup implements SalesOrderLineLookup {

    private static final String SELECT = """
            SELECT l.id, l.sales_order_id, h.sales_order_no, l.material_id,
                   l.completion_over_rate, l.allowed_qty
              FROM sal_sales_order_line l
              JOIN sal_sales_order h
                ON h.id = l.sales_order_id AND h.tenant_id = l.tenant_id AND h.company_id = l.company_id
             WHERE l.id = :id AND l.tenant_id = :tenant AND l.company_id = :company
            """;

    private final JdbcClient jdbc;

    JdbcSalesOrderLineLookup(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public Optional<SalesOrderLine> find(long companyId, long salesOrderLineId) {
        return select(companyId, salesOrderLineId, "");
    }

    @Override
    public Optional<SalesOrderLine> lockForUpdate(long companyId, long salesOrderLineId) {
        jdbc.sql("SELECT set_config('lock_timeout', '3s', true)").query(String.class).single();
        return select(companyId, salesOrderLineId, " FOR UPDATE OF l");
    }

    private Optional<SalesOrderLine> select(long companyId, long salesOrderLineId, String lock) {
        return jdbc.sql(SELECT + lock)
                .param("id", salesOrderLineId)
                .param("tenant", TenantContext.currentTenantId())
                .param("company", companyId)
                .query((rs, i) -> new SalesOrderLine(rs.getLong("id"), rs.getLong("sales_order_id"),
                        rs.getString("sales_order_no"), rs.getLong("material_id"),
                        rs.getBigDecimal("completion_over_rate"), rs.getBigDecimal("allowed_qty")))
                .optional();
    }
}
