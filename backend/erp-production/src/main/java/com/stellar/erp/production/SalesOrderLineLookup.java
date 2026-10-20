package com.stellar.erp.production;

import java.math.BigDecimal;
import java.util.Optional;

/**
 * 受注行读取端口（SAL 域提供实现）。
 *
 * <p>实现：{@code internal.JdbcSalesOrderLineLookup}，读 sal/V202610210705 的正式表，
 * 按租户 + 公司过滤。</p>
 */
public interface SalesOrderLineLookup {

    /**
     * 按当前租户 + 公司查找受注行。
     *
     * @return 不存在（或不属于该公司）时为空
     */
    Optional<SalesOrderLine> find(long companyId, long salesOrderLineId);

    /**
     * 同 {@link #find}，但对受注行加 {@code FOR UPDATE}（00-common 04 §11.1：跨表先锁受注行，再锁工单）。
     * 必须在调用方事务内调用。
     */
    Optional<SalesOrderLine> lockForUpdate(long companyId, long salesOrderLineId);

    /**
     * 受注行快照。
     *
     * @param completionOverRate 受注行 {@code sal_sales_order_line.completion_over_rate}（完工超收容差，NULL = 继承下一级）
     * @param allowedQty         受注确定时快照的完工上限（基本单位），可空
     */
    record SalesOrderLine(long id, long salesOrderId, String salesOrderNo, long materialId,
                          BigDecimal completionOverRate, BigDecimal allowedQty) {
    }
}
