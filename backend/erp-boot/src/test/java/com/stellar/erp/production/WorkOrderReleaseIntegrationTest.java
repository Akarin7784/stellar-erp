package com.stellar.erp.production;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.Callable;
import java.util.concurrent.CyclicBarrier;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.function.Supplier;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;
import org.testcontainers.postgresql.PostgreSQLContainer;

import com.stellar.erp.common.BizException;
import com.stellar.erp.common.LoginContext;
import com.stellar.erp.common.LoginContext.LoginUser;
import com.stellar.erp.common.TenantContext;
import com.stellar.erp.support.DbIntegrationTest;
import com.stellar.erp.support.OwnerJdbc;

/**
 * 任务 D：工单下达 25→30 + standard_cost 快照（真实 fin_standard_cost / fin_publish_standard_cost，erp_app + RLS）。
 * 发布版只能经 fin_publish_standard_cost 产生（触发器禁止直接写 status=40），测试也走这条路。
 */
@DbIntegrationTest
class WorkOrderReleaseIntegrationTest {

    static final long TENANT = 304L, COMPANY = 41L, USER = 7101L;
    static final long MAT = 994011, FACTORY = 994021, WO = 994101;

    @Autowired PostgreSQLContainer pg;
    @Autowired WorkOrderReleaseService releases;
    @Autowired WebApplicationContext wac;

    JdbcTemplate owner;
    final LocalDate month = LocalDate.now(ZoneId.of("Asia/Shanghai")).withDayOfMonth(1);

    @BeforeEach
    void seed() {
        owner = OwnerJdbc.of(pg);
        cleanup();
        owner.execute("""
            INSERT INTO mdm_material_category (id, tenant_id, company_id, category_code, category_name, category_path, category_level, is_leaf)
              VALUES (994001, 304, 41, 'D1', 'D', '/D1/', 1, TRUE);
            INSERT INTO mdm_material (id, tenant_id, company_id, material_code, material_name, material_type, category_id, spec, base_uom_code, valuation_method, status)
              VALUES (994011, 304, 41, '9940000011', 'D 成品', 10, 994001, 's', 'PCE', 20, 1),
                     (994012, 304, 41, '9940000012', 'D 部品', 30, 994001, 's', 'PCE', 20, 1);
            INSERT INTO mdm_factory (id, tenant_id, company_id, factory_code, factory_name) VALUES (994021, 304, 41, 'F41', '工厂41');
            """);
        insertWorkOrder(WO, 25, false);
        owner.update("""
            INSERT INTO prd_bom (id, tenant_id, company_id, bom_no, material_id, material_code, material_name, factory_id,
                version_no, base_uom_code, valid_from, is_default, bom_status)
            VALUES (994301, 304, 41, 'BOM-D', 994011, '9940000011', 'D 成品', 994021, 1, 'PCE', DATE '2026-01-01', TRUE, 30)
            """);
        owner.update("""
            INSERT INTO prd_bom_line (id, tenant_id, company_id, bom_id, line_no, component_material_id, component_code,
                component_name, uom_code, component_qty, loss_rate, required_qty)
            VALUES (994311, 304, 41, 994301, 10, 994012, '9940000012', 'D 部品', 'PCE', 3, 0.005, 3.0151)
            """);
    }

    void insertWorkOrder(long id, int status, boolean hold) {
        owner.update("""
            INSERT INTO prd_work_order (id, tenant_id, company_id, work_order_no, material_id, material_code, material_name,
                uom_code, factory_id, order_qty, planned_start_date, planned_end_date, order_status, is_hold, over_receipt_rate)
            VALUES (?, 304, 41, ?, 994011, '9940000011', 'D 成品', 'PCE', 994021, 10, DATE '2026-11-01', DATE '2026-11-30', ?, ?, 0.05)
            """, id, "WO-D-" + id, status, hold);
    }

    /** 草稿 → 经 fin_publish_standard_cost 发布（与生产路径相同）。 */
    void publish(long id, LocalDate periodFrom, String total) {
        owner.execute(String.format("""
            INSERT INTO fin_standard_cost (id, tenant_id, company_id, material_id, material_code, cost_version, period_from,
                cost_method, material_unit_cost, labor_unit_cost, overhead_unit_cost, outsourcing_unit_cost, total_unit_cost, status)
            VALUES (%d, 304, 41, 994011, '9940000011', 'V%d', DATE '%s', 1, %s, 0, 0, 0, %s, 10);
            SELECT set_config('app.tenant_id', '304', false);
            SELECT fin_publish_standard_cost(%d, 0);
            SELECT set_config('app.tenant_id', '', false);
            """, id, id, periodFrom, total, total, id));
    }

    @AfterEach
    void tearDown() {
        cleanup();
        LoginContext.clear();
        TenantContext.clear();
    }

    void cleanup() {
        owner.execute("""
            DELETE FROM prd_work_order_material WHERE tenant_id = 304;
            DELETE FROM prd_work_order WHERE tenant_id = 304;
            DELETE FROM prd_bom_line WHERE tenant_id = 304;
            DELETE FROM prd_bom WHERE tenant_id = 304;
            DELETE FROM fin_standard_cost WHERE tenant_id = 304;
            DELETE FROM mdm_factory WHERE tenant_id = 304;
            DELETE FROM mdm_material WHERE tenant_id = 304;
            DELETE FROM mdm_material_category WHERE tenant_id = 304;
            """);
    }

    <T> T asUser(Supplier<T> body) {
        return TenantContext.callAs(TENANT, () -> LoginContext.callAs(new LoginUser(USER, COMPANY), body));
    }

    Map<String, Object> row(long id) {
        return owner.queryForMap("SELECT * FROM prd_work_order WHERE id = ?", id);
    }

    @Test
    void releaseSnapshotsPublishedStandardCostOfCurrentMonth() {
        publish(994201, month, "778.200000");
        WorkOrderReleased r = asUser(() -> releases.release(WO, new WorkOrderReleaseCommand(0)));

        Map<String, Object> w = row(WO);
        assertThat(w.get("order_status")).isEqualTo(30);
        assertThat((BigDecimal) w.get("standard_cost")).isEqualByComparingTo("778.2");
        assertThat(w.get("released_by")).isEqualTo(USER);
        assertThat(w.get("released_at")).isNotNull();
        assertThat(w.get("version")).isEqualTo(1);
        assertThat(r.warnings()).isEmpty();
    }

    @Test
    void draftOrFutureVersionDoesNotCountAndWarns() {
        publish(994202, month.plusMonths(1), "800");   // 下月起的发布版：不覆盖本月
        owner.execute("""
            INSERT INTO fin_standard_cost (id, tenant_id, company_id, material_id, material_code, cost_version, period_from,
                cost_method, material_unit_cost, labor_unit_cost, overhead_unit_cost, outsourcing_unit_cost, total_unit_cost, status)
            VALUES (994203, 304, 41, 994011, '9940000011', 'DRAFT', DATE '%s', 1, 1, 0, 0, 0, 1, 10);
            """.formatted(month));                        // 本月的草稿：不算

        WorkOrderReleased r = asUser(() -> releases.release(WO, new WorkOrderReleaseCommand(0)));

        Map<String, Object> w = row(WO);
        assertThat(w.get("order_status")).isEqualTo(30);
        assertThat(w.get("standard_cost")).isNull();
        assertThat(r.warnings()).singleElement().satisfies(x -> assertThat(x.msgId()).isEqualTo("MSG-FIN-117"));
    }

    @Test
    void notApprovedIs4002AndUnchanged() {
        insertWorkOrder(994102, 10, false);
        assertThatThrownBy(() -> asUser(() -> releases.release(994102, new WorkOrderReleaseCommand(0))))
                .isInstanceOfSatisfying(BizException.class, e -> assertThat(e.getCode()).isEqualTo(4002));
        assertThat(row(994102).get("order_status")).isEqualTo(10);
    }

    @Test
    void otherCompanyCannotRelease() {
        assertThatThrownBy(() -> TenantContext.callAs(TENANT, () -> LoginContext.callAs(new LoginUser(USER, 42L),
                () -> releases.release(WO, new WorkOrderReleaseCommand(0)))))
                .isInstanceOfSatisfying(BizException.class, e -> assertThat(e.getCode()).isEqualTo(4001));
        assertThat(row(WO).get("order_status")).isEqualTo(25);
    }

    @Test
    void apiReturns200WithWarningsAndConflictIs409() throws Exception {
        MockMvc mvc = MockMvcBuilders.webAppContextSetup(wac).build();
        TenantContext.set(TENANT);
        LoginContext.set(new LoginUser(USER, COMPANY));
        mvc.perform(post("/api/production/work-orders/" + WO + "/release")
                        .contentType(MediaType.APPLICATION_JSON).content("{\"version\": 0}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.orderStatus").value(30))
                .andExpect(jsonPath("$.data.standardCost").doesNotExist())
                .andExpect(jsonPath("$.data.warnings[0].code").value(70117))
                .andExpect(jsonPath("$.data.warnings[0].msgId").value("MSG-FIN-117"));
        mvc.perform(post("/api/production/work-orders/" + WO + "/release")
                        .contentType(MediaType.APPLICATION_JSON).content("{\"version\": 1}"))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value(4002))
                .andExpect(jsonPath("$.msgId").value("MSG-COM-034"));
    }

    @Test
    void concurrentReleaseOnlyOneWinsAndVersionIncrementsOnce() throws Exception {
        publish(994204, month, "100");
        int before = ((Number) row(WO).get("version")).intValue();
        CyclicBarrier barrier = new CyclicBarrier(2);
        Callable<WorkOrderReleased> task = () -> {
            barrier.await(10, TimeUnit.SECONDS);
            return asUser(() -> releases.release(WO, new WorkOrderReleaseCommand(before)));
        };
        ExecutorService pool = Executors.newFixedThreadPool(2);
        List<Future<WorkOrderReleased>> futures;
        try {
            futures = List.of(pool.submit(task), pool.submit(task));
            pool.shutdown();
            assertThat(pool.awaitTermination(30, TimeUnit.SECONDS)).isTrue();
        } finally {
            pool.shutdownNow();
        }

        int ok = 0;
        List<Integer> failures = new ArrayList<>();
        for (Future<WorkOrderReleased> f : futures) {
            try {
                f.get();
                ok++;
            } catch (ExecutionException e) {
                assertThat(e.getCause()).isInstanceOf(BizException.class);
                failures.add(((BizException) e.getCause()).getCode());
            }
        }
        assertThat(ok).isEqualTo(1);
        assertThat(failures).singleElement().satisfies(c -> assertThat(c).isEqualTo(4002));

        Map<String, Object> w = row(WO);
        assertThat(w.get("order_status")).isEqualTo(30);
        assertThat(((Number) w.get("version")).intValue()).isEqualTo(before + 1);
        assertThat(lineCount(WO)).isEqualTo(1);   // 後続は行ロック後に状態 30 を見て 4002。BOM 展開は 1 回だけ
    }

    @Test
    void releaseDateInNextMonthPicksThatMonthsVersion() {
        publish(994206, month, "700");
        publish(994207, month.plusMonths(1), "800");
        LocalDate next = month.plusMonths(1).plusDays(9);
        WorkOrderReleased r = asUser(() -> releases.release(WO, new WorkOrderReleaseCommand(0, next)));
        assertThat(r.releaseDate()).isEqualTo(next);
        assertThat((BigDecimal) row(WO).get("standard_cost")).isEqualByComparingTo("800");
    }

    @Test
    void apiPastReleaseDateIs422AndNothingChanges() throws Exception {
        MockMvc mvc = MockMvcBuilders.webAppContextSetup(wac).build();
        TenantContext.set(TENANT);
        LoginContext.set(new LoginUser(USER, COMPANY));
        LocalDate yesterday = LocalDate.now(ZoneId.of("Asia/Shanghai")).minusDays(1);
        mvc.perform(post("/api/production/work-orders/" + WO + "/release").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"version\": 0, \"releaseDate\": \"" + yesterday + "\"}"))
                .andExpect(status().isUnprocessableContent())
                .andExpect(jsonPath("$.code").value(60104))
                .andExpect(jsonPath("$.msgId").value("MSG-PRD-104"));
        assertThat(row(WO).get("order_status")).isEqualTo(25);
    }

    @Test
    void noEffectiveBomIs60020AndStateUnchanged() {
        // 計画開始日 2026-11-01 時点で有効な BOM がない（承認前・期間外のみ）
        owner.update("UPDATE prd_bom SET bom_status = 10 WHERE id = 994301");
        owner.update("""
            INSERT INTO prd_bom (id, tenant_id, company_id, bom_no, material_id, material_code, material_name, factory_id,
                version_no, base_uom_code, valid_from, is_default, bom_status)
            VALUES (994302, 304, 41, 'BOM-D2', 994011, '9940000011', 'D 成品', 994021, 2, 'PCE', DATE '2026-12-01', FALSE, 30)
            """);
        assertThatThrownBy(() -> asUser(() -> releases.release(WO, new WorkOrderReleaseCommand(0))))
                .isInstanceOfSatisfying(BizException.class, e -> {
                    assertThat(e.getCode()).isEqualTo(60020);
                    assertThat(e.getMsgId()).isEqualTo("MSG-PRD-020");
                });
        Map<String, Object> w = row(WO);
        assertThat(w.get("order_status")).isEqualTo(25);
        assertThat(w.get("version")).isEqualTo(0);
        assertThat(w.get("released_at")).isNull();
        assertThat(lineCount(WO)).isZero();
    }

    long lineCount(long wo) {
        return owner.queryForObject("SELECT count(*) FROM prd_work_order_material WHERE work_order_id = ?", Long.class, wo);
    }

    @Test
    void zeroLinesExpandsEffectiveBomInSameTransaction() {
        asUser(() -> releases.release(WO, new WorkOrderReleaseCommand(0)));
        Map<String, Object> m = owner.queryForMap("SELECT * FROM prd_work_order_material WHERE work_order_id = ?", WO);
        // order_qty 10 × 3 ÷ base 1 = 30.0000、÷ (1 − 0.005) = 30.1508（切上）
        assertThat((BigDecimal) m.get("required_qty")).isEqualByComparingTo("30.0000");
        assertThat((BigDecimal) m.get("total_required_qty")).isEqualByComparingTo("30.1508");
        assertThat((BigDecimal) m.get("remaining_qty")).isEqualByComparingTo("30.1508");
        assertThat(m.get("bom_line_id")).isEqualTo(994311L);
        assertThat(m.get("material_id")).isEqualTo(994012L);
        assertThat(row(WO).get("order_status")).isEqualTo(30);
    }

    @Test
    void existingLinesAreNotOverwrittenEvenWithoutBom() {
        owner.update("UPDATE prd_bom SET bom_status = 10 WHERE id = 994301");   // 有効 BOM なし
        owner.update("""
            INSERT INTO prd_work_order_material (id, tenant_id, company_id, work_order_id, line_no, material_id,
                material_code, material_name, uom_code, required_qty, total_required_qty, remaining_qty)
            VALUES (994401, 304, 41, ?, 10, 994012, '9940000012', 'D 部品', 'PCE', 7, 7, 7)
            """, WO);
        asUser(() -> releases.release(WO, new WorkOrderReleaseCommand(0)));
        assertThat(lineCount(WO)).isEqualTo(1);
        assertThat(owner.queryForObject("SELECT total_required_qty FROM prd_work_order_material WHERE id = 994401",
                BigDecimal.class)).isEqualByComparingTo("7");
        assertThat(row(WO).get("order_status")).isEqualTo(30);
    }
}
