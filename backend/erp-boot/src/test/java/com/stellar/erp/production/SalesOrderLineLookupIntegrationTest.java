package com.stellar.erp.production;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.math.BigDecimal;
import java.util.Map;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.function.Supplier;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.transaction.support.TransactionTemplate;
import org.testcontainers.postgresql.PostgreSQLContainer;

import com.stellar.erp.common.BizException;
import com.stellar.erp.common.LoginContext;
import com.stellar.erp.common.LoginContext.LoginUser;
import com.stellar.erp.common.TenantContext;
import com.stellar.erp.support.DbIntegrationTest;
import com.stellar.erp.support.OwnerJdbc;

/**
 * 受注行端口的正式实现（sal/V202610210705 正式表，erp_app + RLS）。
 * 覆盖：租户 / 公司过滤、FOR UPDATE 实际加锁、allowed_qty 未快照 → 5000（下达 / 超产申请）、
 * MTO 下达经真实受注行快照 allowed_qty、ck_sal_sol_completed_qty（23514）→ 60040。
 */
@DbIntegrationTest
class SalesOrderLineLookupIntegrationTest {

    static final long TENANT = 305L, COMPANY = 51L, OTHER_COMPANY = 52L, OTHER_TENANT = 306L, USER = 7201L;
    static final long MAT = 995011, LINE = 995041, LINE_NULL = 995042, LINE_OTHER_CO = 995043, LINE_OTHER_TENANT = 995044;
    static final long WO = 995101, WO_NULL = 995102;

    @Autowired PostgreSQLContainer pg;
    @Autowired SalesOrderLineLookup lookup;
    @Autowired WorkOrderReleaseService releases;
    @Autowired OverproductionApprovalService approvals;
    @Autowired JdbcClient jdbc;
    @Autowired TransactionTemplate tx;

    JdbcTemplate owner;

    @BeforeEach
    void seed() {
        owner = OwnerJdbc.of(pg);
        cleanup();
        owner.execute("""
            INSERT INTO mdm_material_category (id, tenant_id, company_id, category_code, category_name, category_path, category_level, is_leaf)
              VALUES (995001, 305, 51, 'L1', 'L', '/L1/', 1, TRUE),
                     (995002, 306, 51, 'L1', 'L T306', '/L1/', 1, TRUE);   -- 复合 FK (tenant_id, x_id)：租户 306 要有自己的主数据
            INSERT INTO mdm_material (id, tenant_id, company_id, material_code, material_name, material_type, category_id, spec, base_uom_code, valuation_method, status)
              VALUES (995011, 305, 51, '9950000011', 'L 成品', 10, 995001, 's', 'PCE', 20, 1),
                     (995012, 306, 51, '9950000012', 'L 成品 T306', 10, 995002, 's', 'PCE', 20, 1);
            INSERT INTO mdm_factory (id, tenant_id, company_id, factory_code, factory_name) VALUES (995021, 305, 51, 'F51', '工厂51');
            INSERT INTO mdm_customer (id, tenant_id, company_id, customer_code, customer_name, customer_type, tax_no, owner_user_id, payment_term_code, settlement_method_code) VALUES
              (995031, 305, 51, 'C995031', 'L 客户', 10, '91320000000000000X', 1, 'NET30', 'TT'),
              (995032, 305, 52, 'C995032', 'L 客户 52', 10, '91320000000000000X', 1, 'NET30', 'TT'),
              (995033, 306, 51, 'C995033', 'L 客户 T306', 10, '91320000000000000X', 1, 'NET30', 'TT');
            INSERT INTO sal_sales_order (id, tenant_id, company_id, sales_order_no, order_date, customer_id, customer_code, customer_name,
                                         delivery_address, sales_department_id, owner_user_id, payment_term_code, delivery_date, warehouse_id, order_status) VALUES
              (995031, 305, 51, 'SO-L-51',   DATE '2026-10-01', 995031, 'C995031', 'L', 'addr', 1, 1, 'NET30', DATE '2026-11-30', 1, 25),
              (995032, 305, 52, 'SO-L-52',   DATE '2026-10-01', 995032, 'C995032', 'L', 'addr', 1, 1, 'NET30', DATE '2026-11-30', 1, 25),
              (995033, 306, 51, 'SO-L-T306', DATE '2026-10-01', 995033, 'C995033', 'L', 'addr', 1, 1, 'NET30', DATE '2026-11-30', 1, 25);
            INSERT INTO sal_sales_order_line (id, tenant_id, company_id, sales_order_id, line_no, material_id, material_code, material_name,
                                              ordered_qty, uom_code, base_uom_code, base_qty, unit_price, tax_code, tax_rate, delivery_date, warehouse_id,
                                              completion_over_rate, allowed_qty, completed_qty) VALUES
              (995041, 305, 51, 995031, 10, 995011, '9950000011', 'L', 100, 'PCE', 'PCE', 100, 1, 'VAT13-OUT', 13, DATE '2026-11-30', 1, 0.05, 105, 0),
              (995042, 305, 51, 995031, 20, 995011, '9950000011', 'L', 100, 'PCE', 'PCE', 100, 1, 'VAT13-OUT', 13, DATE '2026-11-30', 1, NULL, NULL, 0),
              (995043, 305, 52, 995032, 10, 995011, '9950000011', 'L', 100, 'PCE', 'PCE', 100, 1, 'VAT13-OUT', 13, DATE '2026-11-30', 1, 0.05, 105, 0),
              (995044, 306, 51, 995033, 10, 995012, '9950000012', 'L', 100, 'PCE', 'PCE', 100, 1, 'VAT13-OUT', 13, DATE '2026-11-30', 1, 0.05, 105, 0);
            """);
        insertMtoWorkOrder(WO, LINE);
        insertMtoWorkOrder(WO_NULL, LINE_NULL);
    }

    void insertMtoWorkOrder(long id, long lineId) {
        owner.update("""
            INSERT INTO prd_work_order (id, tenant_id, company_id, work_order_no, material_id, material_code, material_name,
                uom_code, factory_id, order_qty, planned_start_date, planned_end_date, order_status, is_hold, over_receipt_rate,
                sales_order_id, sales_order_line_id, sales_order_no, source_type)
            VALUES (?, 305, 51, ?, 995011, '9950000011', 'L 成品', 'PCE', 995021, 100, DATE '2026-11-01', DATE '2026-11-30', 25, FALSE, 0.05,
                995031, ?, 'SO-L-51', 30)
            """, id, "WO-L-" + id, lineId);
    }

    @AfterEach
    void tearDown() {
        cleanup();
        LoginContext.clear();
        TenantContext.clear();
    }

    void cleanup() {
        owner.execute("""
            DELETE FROM prd_overproduction_approval WHERE tenant_id IN (305, 306);
            DELETE FROM prd_work_order_material WHERE tenant_id IN (305, 306);
            DELETE FROM prd_work_order WHERE tenant_id IN (305, 306);
            DELETE FROM sys_sequence WHERE tenant_id IN (305, 306);
            DELETE FROM sal_sales_order_line WHERE tenant_id IN (305, 306);
            DELETE FROM sal_sales_order WHERE tenant_id IN (305, 306);
            DELETE FROM mdm_customer WHERE tenant_id IN (305, 306);
            DELETE FROM mdm_factory WHERE tenant_id IN (305, 306);
            DELETE FROM mdm_material WHERE tenant_id IN (305, 306);
            DELETE FROM mdm_material_category WHERE tenant_id IN (305, 306);
            """);
    }

    <T> T asUser(long company, Supplier<T> body) {
        return TenantContext.callAs(TENANT, () -> LoginContext.callAs(new LoginUser(USER, company), body));
    }

    <T> T asUser(Supplier<T> body) {
        return asUser(COMPANY, body);
    }

    java.util.Optional<SalesOrderLineLookup.SalesOrderLine> read(long company, long lineId, boolean lock) {
        return asUser(company, () -> tx.execute(s -> lock ? lookup.lockForUpdate(company, lineId) : lookup.find(company, lineId)));
    }

    Map<String, Object> wo(long id) {
        return owner.queryForMap("SELECT * FROM prd_work_order WHERE id = ?", id);
    }

    @Test
    void findReadsRealLineFilteredByTenantAndCompany() {
        var line = read(COMPANY, LINE, false).orElseThrow();
        assertThat(line.salesOrderId()).isEqualTo(995031);
        assertThat(line.salesOrderNo()).isEqualTo("SO-L-51");
        assertThat(line.materialId()).isEqualTo(MAT);
        assertThat(line.completionOverRate()).isEqualByComparingTo("0.05");
        assertThat(line.allowedQty()).isEqualByComparingTo("105");

        assertThat(read(COMPANY, LINE_OTHER_CO, false)).isEmpty();
        assertThat(read(COMPANY, LINE_OTHER_TENANT, false)).isEmpty();
        assertThat(read(COMPANY, LINE_OTHER_CO, true)).isEmpty();
        assertThat(read(OTHER_COMPANY, LINE_OTHER_CO, false)).isPresent();
    }

    @Test
    void lockForUpdateHoldsRowLockUntilCommit() throws Exception {
        CountDownLatch locked = new CountDownLatch(1);
        CountDownLatch release = new CountDownLatch(1);
        CompletableFuture<Void> holder = CompletableFuture.runAsync(() -> asUser(() -> tx.execute(s -> {
            lookup.lockForUpdate(COMPANY, LINE).orElseThrow();
            locked.countDown();
            try {
                release.await(20, TimeUnit.SECONDS);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
            return null;
        })));
        assertThat(locked.await(10, TimeUnit.SECONDS)).isTrue();
        try {
            // 另一事务对同一受注行 FOR UPDATE：被阻塞，3 秒 lock_timeout 后报错
            assertThatThrownBy(() -> read(COMPANY, LINE, true))
                    .hasStackTraceContaining("lock timeout");
        } finally {
            release.countDown();
            holder.get(20, TimeUnit.SECONDS);
        }
        // 释放后可以正常加锁
        assertThat(read(COMPANY, LINE, true)).isPresent();
    }

    @Test
    void mtoReleaseSnapshotsAllowedQtyFromRealLine() {
        // 材料明細ありの工单（0 行だと下达時に BOM 展開が必要になるため、本テストの関心外）
        owner.update("""
            INSERT INTO prd_work_order_material (id, tenant_id, company_id, work_order_id, line_no, material_id,
                material_code, material_name, uom_code, required_qty, total_required_qty)
            VALUES (995201, 305, 51, ?, 10, 995011, '9950000011', 'L 成品', 'PCE', 1, 1)
            """, WO);
        WorkOrderReleased r = asUser(() -> releases.release(WO, new WorkOrderReleaseCommand(0)));
        assertThat(r.orderStatus()).isEqualTo((short) 30);
        Map<String, Object> w = wo(WO);
        assertThat(w.get("order_status")).isEqualTo(30);
        assertThat((BigDecimal) w.get("allowed_qty")).isEqualByComparingTo("105");
        assertThat(w.get("version")).isEqualTo(1);
    }

    @Test
    void mtoReleaseWithUnsnapshottedLineIs5000AndUnchanged() {
        assertThatThrownBy(() -> asUser(() -> releases.release(WO_NULL, new WorkOrderReleaseCommand(0))))
                .isInstanceOfSatisfying(BizException.class, e -> assertThat(e.getCode()).isEqualTo(5000));
        Map<String, Object> w = wo(WO_NULL);
        assertThat(w.get("order_status")).isEqualTo(25);
        assertThat(w.get("allowed_qty")).isNull();
    }

    @Test
    void overproductionRequestOnUnsnapshottedLineIs5000() {
        assertThatThrownBy(() -> asUser(() -> approvals.request(
                new OverproductionRequestCommand(LINE_NULL, null, new BigDecimal("5"), null))))
                .isInstanceOfSatisfying(BizException.class, e -> assertThat(e.getCode()).isEqualTo(5000));
        assertThat(owner.queryForObject("SELECT count(*) FROM prd_overproduction_approval WHERE tenant_id = 305",
                Integer.class)).isZero();
    }

    @Test
    void completedQtyCheckViolationTranslatesTo60040() {
        Throwable thrown = org.assertj.core.api.Assertions.catchThrowable(() -> asUser(() -> tx.execute(s -> jdbc.sql(
                "UPDATE sal_sales_order_line SET completed_qty = 106 WHERE id = :id AND company_id = :company")
                .param("id", LINE).param("company", COMPANY).update())));
        assertThat(thrown).isInstanceOf(DataIntegrityViolationException.class);
        assertThat(ProductionDbErrors.translate(thrown)).hasValueSatisfying(e -> {
            assertThat(e.getCode()).isEqualTo(60040);
            assertThat(e.getMsgId()).isEqualTo("MSG-PRD-040");
        });
    }
}
