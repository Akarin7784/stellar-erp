package com.stellar.erp.db;

import static org.assertj.core.api.Assertions.assertThat;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.Callable;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.testcontainers.postgresql.PostgreSQLContainer;

import com.stellar.erp.support.DbIntegrationTest;
import com.stellar.erp.support.OwnerJdbc;
import com.stellar.erp.support.PostgresContainerConfig;

/**
 * G2-18 并发用例。pgTAP 单会话无法模拟并发，这里用多条 erp_app 连接（NOBYPASSRLS）+ CountDownLatch 同时起跑。
 * 被测对象：db/draft/g2_18_completion.sql；prd_ 用正式表（PR #13），受注表用 sal/V202610210705 的正式表。
 * 并发需要已提交的数据，所以 owner 在每个用例前提交建表与数据，用例后用 g2_18_teardown.sql 清掉。
 * 不变量：0 <= completed_qty <= allowed_qty；受注行与工单合计对账差异为 0；不出现死锁（40P01）。
 */
@DbIntegrationTest
class G218ConcurrencyTest {

    static final int THREADS = 8;

    @Autowired PostgreSQLContainer pg;

    JdbcTemplate owner;
    ExecutorService pool;

    @BeforeEach
    void setUp() throws Exception {
        owner = OwnerJdbc.of(pg);
        owner.execute(PgTapSuiteTest.read("pgtap-support/g2_18_teardown.sql"));   // 防止上次残留
        owner.execute(PgTapSuiteTest.read("db/draft/g2_18_completion.sql"));
        owner.execute("""
            INSERT INTO mdm_material_category (id, tenant_id, company_id, category_code, category_name, category_path, category_level, is_leaf)
              VALUES (992001, 101, 1, '9C1', 'g218 conc', '/9C1/', 1, TRUE);
            INSERT INTO mdm_uom (id, tenant_id, company_id, uom_code, uom_name, conversion_group, is_base_uom, decimal_places)
              VALUES (992001, 101, 1, 'PCE', '个', 'CNT', TRUE, 0);
            INSERT INTO mdm_material (id, tenant_id, company_id, material_code, material_name, material_type, category_id, spec, base_uom_code, valuation_method, status)
              VALUES (992001, 101, 1, '99C2180001', 'conc', 10, 992001, 's', 'PCE', 20, 1);
            INSERT INTO sys_param (id, tenant_id, company_id, param_key, param_name, param_group, param_value, value_type)
              VALUES (992001, 101, 1, 'prd.completion_over_rate', 'rate', 'PRD', '0.05', 3);
            INSERT INTO mdm_factory (id, tenant_id, company_id, factory_code, factory_name) VALUES (992001, 101, 1, '9C1', 'g218 conc');
            INSERT INTO mdm_customer (id, tenant_id, company_id, customer_code, customer_name, customer_type, tax_no, owner_user_id, payment_term_code, settlement_method_code)
              VALUES (992001, 101, 1, 'C992001', 'g218 conc', 10, '91320000000000000X', 1, 'NET30', 'TT');
            INSERT INTO sal_sales_order (id, tenant_id, company_id, sales_order_no, order_date, customer_id, customer_code, customer_name,
                                         delivery_address, sales_department_id, owner_user_id, payment_term_code, delivery_date, warehouse_id, order_status)
              VALUES (992001, 101, 1, 'SO-CONC', DATE '2026-10-01', 992001, 'C992001', 'g218 conc', 'addr', 1, 1, 'NET30', DATE '2026-10-31', 1, 30);
            INSERT INTO sal_sales_order_line (id, tenant_id, company_id, sales_order_id, line_no, material_id, material_code, material_name, ordered_qty,
                                              uom_code, base_uom_code, base_qty, unit_price, tax_code, tax_rate, delivery_date, warehouse_id,
                                              completion_over_rate, allowed_qty, completed_qty)
              VALUES (992011, 101, 1, 992001, 1, 992001, '99C2180001', 'conc', 100, 'PCE', 'PCE', 100, 1, 'VAT13-OUT', 13, DATE '2026-10-31', 1, 0.05, 105, 100);
            """);
        StringBuilder wo = new StringBuilder();
        for (int i = 1; i <= THREADS; i++) {
            wo.append(String.format(
                "INSERT INTO prd_work_order (id, tenant_id, company_id, sales_order_line_id, material_id, order_status, order_qty, completed_qty, allowed_qty, over_receipt_rate,"
                + " work_order_no, material_code, material_name, uom_code, factory_id, planned_start_date, planned_end_date)"
                + " VALUES (%d, 101, 1, 992011, 992001, 35, 100, %d, 105, 0.05, 'WO-CONC-%d', '99C2180001', 'conc', 'PCE', 992001, DATE '2026-10-01', DATE '2026-10-31');",
                992100 + i, i == 1 ? 100 : 0, i));
        }
        owner.execute(wo.toString());
        pool = Executors.newFixedThreadPool(THREADS);
    }

    @AfterEach
    void tearDown() throws Exception {
        pool.shutdownNow();
        owner.execute(PgTapSuiteTest.read("pgtap-support/g2_18_teardown.sql"));
    }

    /** 8 张工单各报完工 1，剩余额度只有 5：恰好 5 个成功，其余 60100；受注行停在 105，无死锁。 */
    @Test
    void parallelCompletionsDoNotOverIssue() throws Exception {
        List<String> results = race(i -> "SELECT g2_18_report_completion(" + (992100 + i) + ", 1, 9)");
        assertThat(results).filteredOn("OK"::equals).hasSize(5);
        assertThat(results).filteredOn(r -> !"OK".equals(r)).allMatch(r -> r.equals("60100"), "失败的都应是 60100：" + results);
        assertThat(results).noneMatch(r -> r.contains("40P01"));
        assertInvariants(105);
    }

    /** 报完工、冲销、受注改量、整行超产审批混跑：都是先锁受注行再按 id 升序锁工单，不死锁，不变量成立。 */
    @Test
    void mixedOperationsNoDeadlock() throws Exception {
        owner.execute("""
            INSERT INTO prd_overproduction_approval (id, tenant_id, company_id, approval_no, sales_order_line_id, work_order_id, material_id, request_qty, approval_status,
                                                      sales_order_id, current_allowed_qty, requested_by, requested_at)
              VALUES (992001, 101, 1, 'OA-CONC', 992011, NULL, 992001, 3, 20, 992001, 105, 9, now())""");
        List<String> results = race(i -> switch (i) {
            case 1 -> "SELECT g2_18_reverse_completion(992101, 2, 9)";
            case 2 -> "SELECT g2_18_approve_overproduction(992001, 9, 992001)";
            case 3 -> "SELECT g2_18_check_line_qty_change(992011, 101)";
            default -> "SELECT g2_18_report_completion(" + (992100 + i) + ", 1, 9)";
        });
        assertThat(results).as("无死锁：%s", results).noneMatch(r -> r.contains("40P01"));
        assertThat(results.get(0)).isEqualTo("OK");   // 冲销
        assertThat(results.get(1)).isEqualTo("OK");   // 审批 +3 → 108
        assertThat(results.get(2)).isEqualTo("OK");   // 改量只校验
        assertThat(results.subList(3, THREADS)).allMatch(r -> r.equals("OK") || r.equals("60040") || r.equals("60100"));
        Long allowed = owner.queryForObject("SELECT allowed_qty::bigint FROM sal_sales_order_line WHERE id = 992011", Long.class);
        assertThat(allowed).isEqualTo(108L);
        assertInvariants(null);
    }

    private void assertInvariants(Integer expectedLineCompleted) {
        var row = owner.queryForMap("""
            SELECT l.completed_qty AS done, l.allowed_qty AS allowed,
                   (SELECT sum(completed_qty) FROM prd_work_order WHERE sales_order_line_id = l.id) AS wo_sum
              FROM sal_sales_order_line l WHERE l.id = 992011""");
        var done = (java.math.BigDecimal) row.get("done");
        assertThat(done.signum()).isGreaterThanOrEqualTo(0);
        assertThat(done).isLessThanOrEqualTo((java.math.BigDecimal) row.get("allowed"));
        assertThat(done).isEqualByComparingTo((java.math.BigDecimal) row.get("wo_sum"));
        if (expectedLineCompleted != null) {
            assertThat(done).isEqualByComparingTo(String.valueOf(expectedLineCompleted));
        }
    }

    /** 每个线程一条 erp_app 连接、一个事务；返回 "OK" 或错误码（P0001 的 MESSAGE / 其他 SQLSTATE）。 */
    private List<String> race(java.util.function.IntFunction<String> sqlFor) throws Exception {
        CountDownLatch ready = new CountDownLatch(THREADS);
        CountDownLatch start = new CountDownLatch(1);
        List<Future<String>> fs = new ArrayList<>();
        for (int i = 1; i <= THREADS; i++) {
            String sql = sqlFor.apply(i);
            Callable<String> task = () -> {
                try (Connection c = DriverManager.getConnection(pg.getJdbcUrl(),
                        PostgresContainerConfig.APP_USER, PostgresContainerConfig.APP_PASSWORD);
                     Statement st = c.createStatement()) {
                    c.setAutoCommit(false);
                    st.execute("SET lock_timeout = '20s'");
                    st.execute("SELECT set_config('app.tenant_id', '101', true), set_config('app.company_id', '1', true)");
                    ready.countDown();
                    start.await(10, TimeUnit.SECONDS);
                    try {
                        st.execute(sql);
                        c.commit();
                        return "OK";
                    } catch (SQLException e) {
                        c.rollback();
                        return "P0001".equals(e.getSQLState()) ? ((org.postgresql.util.PSQLException) e).getServerErrorMessage().getMessage() : e.getSQLState() + " " + e.getMessage();
                    }
                }
            };
            fs.add(pool.submit(task));
        }
        ready.await(30, TimeUnit.SECONDS);
        start.countDown();
        List<String> out = new ArrayList<>();
        for (Future<String> f : fs) {
            out.add(f.get(60, TimeUnit.SECONDS));
        }
        return out;
    }
}
