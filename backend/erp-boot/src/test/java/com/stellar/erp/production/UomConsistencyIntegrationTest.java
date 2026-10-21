package com.stellar.erp.production;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Map;
import java.util.function.Supplier;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.transaction.support.TransactionTemplate;
import org.springframework.web.context.WebApplicationContext;
import org.testcontainers.postgresql.PostgreSQLContainer;

import com.stellar.erp.common.BizException;
import com.stellar.erp.common.LoginContext;
import com.stellar.erp.common.LoginContext.LoginUser;
import com.stellar.erp.common.TenantContext;
import com.stellar.erp.production.internal.UomConverter;
import com.stellar.erp.support.DbIntegrationTest;
import com.stellar.erp.support.OwnerJdbc;

/** CHK-PRD-002-10 / 60022：単位整合と基本単位換算（登録・下达・提出、erp_app + RLS）。 */
@DbIntegrationTest
class UomConsistencyIntegrationTest {

    static final long TENANT = 309L, CO = 91L, CO2 = 92L, USER = 7901L;
    static final long MAT = 999011, COMP_KG = 999012, COMP_PCE = 999013, FACTORY = 999021, WH = 999061;
    static final LocalDate D = LocalDate.of(2026, 11, 2);

    @Autowired PostgreSQLContainer pg;
    @Autowired UomConverter uoms;
    @Autowired WorkOrderService workOrders;
    @Autowired WorkOrderReleaseService releases;
    @Autowired WorkOrderApprovalService approvals;
    @Autowired TransactionTemplate tx;
    @Autowired WebApplicationContext wac;

    JdbcTemplate owner;

    @BeforeEach
    void seed() {
        owner = OwnerJdbc.of(pg);
        cleanup();
        owner.execute("""
            INSERT INTO mdm_uom (id, tenant_id, company_id, uom_code, uom_name, conversion_group, decimal_places) VALUES
              (999071, 309, 91, 'PCE', '个', 'PCS', 0),
              (999072, 309, 91, 'KGM', '千克', 'MASS', 3),
              (999073, 309, 91, 'GRM', '克', 'MASS', 0),
              (999074, 309, 91, 'TNE', '吨', 'MASS', 6),
              (999075, 309, 92, 'GRM', '克', 'MASS', 0),
              (999076, 309, 92, 'KGM', '千克', 'MASS', 3);
            INSERT INTO mdm_material_category (id, tenant_id, company_id, category_code, category_name, category_path, category_level, is_leaf)
              VALUES (999001, 309, 91, 'U1', 'U', '/U1/', 1, TRUE);
            INSERT INTO mdm_material (id, tenant_id, company_id, material_code, material_name, material_type, category_id, spec, base_uom_code, valuation_method, status) VALUES
              (999011, 309, 91, '9990000011', 'U 成品', 10, 999001, 's', 'PCE', 20, 1),
              (999012, 309, 91, '9990000012', 'U 原料 kg', 30, 999001, 's', 'KGM', 20, 1),
              (999013, 309, 91, '9990000013', 'U 部品', 30, 999001, 's', 'PCE', 20, 1);
            INSERT INTO mdm_factory (id, tenant_id, company_id, factory_code, factory_name) VALUES (999021, 309, 91, 'F91', '工厂91');
            INSERT INTO mdm_warehouse (id, tenant_id, company_id, warehouse_code, warehouse_name, warehouse_type, factory_id, status)
              VALUES (999061, 309, 91, 'W91', '成品仓', 30, 999021, 1);
            INSERT INTO prd_material_planning (id, tenant_id, company_id, material_id, material_code, material_name, factory_id, material_type)
              VALUES (999031, 309, 91, 999011, '9990000011', 'U 成品', 999021, 20);
            INSERT INTO sys_param (id, tenant_id, company_id, param_key, param_name, param_group, param_value, value_type)
              VALUES (999041, 309, 91, 'prd.completion_over_rate', '完工超收容差', 'prd', '0.0500', 3);
            """);
    }

    @AfterEach
    void tearDown() {
        cleanup();
        LoginContext.clear();
        TenantContext.clear();
    }

    void cleanup() {
        owner.execute("""
            DELETE FROM prd_work_order_material WHERE tenant_id = 309;
            DELETE FROM prd_work_order WHERE tenant_id = 309;
            DELETE FROM prd_bom_line WHERE tenant_id = 309;
            DELETE FROM prd_bom WHERE tenant_id = 309;
            DELETE FROM prd_material_planning WHERE tenant_id = 309;
            DELETE FROM sys_param WHERE tenant_id = 309;
            DELETE FROM sys_sequence WHERE tenant_id = 309;
            DELETE FROM mdm_uom_conversion WHERE tenant_id = 309;
            DELETE FROM mdm_warehouse WHERE tenant_id = 309;
            DELETE FROM mdm_factory WHERE tenant_id = 309;
            DELETE FROM mdm_material WHERE tenant_id = 309;
            DELETE FROM mdm_material_category WHERE tenant_id = 309;
            DELETE FROM mdm_uom WHERE tenant_id = 309;
            """);
    }

    <T> T as(Supplier<T> body) {
        return TenantContext.callAs(TENANT, () -> LoginContext.callAs(new LoginUser(USER, CO), body));
    }

    <T> T inTx(Supplier<T> body) {
        return TenantContext.callAs(TENANT, () -> tx.execute(s -> body.get()));
    }

    void rate(long id, long company, String from, String to, String rate, String validFrom, String validTo, int status,
              boolean deleted) {
        owner.update("""
            INSERT INTO mdm_uom_conversion (id, tenant_id, company_id, conversion_group, from_uom_code, to_uom_code,
                conversion_rate, valid_from, valid_to, status, deleted)
            VALUES (?, 309, ?, 'MASS', ?, ?, CAST(? AS NUMERIC), CAST(? AS DATE), CAST(? AS DATE), ?, ?)
            """, id, company, from, to, rate, validFrom, validTo, status, deleted);
    }

    BigDecimal toKg(String from, String qty, LocalDate d) {
        return inTx(() -> uoms.toBase(CO, from, "KGM", new BigDecimal(qty), d));
    }

    static void is60022(Runnable r) {
        assertThatThrownBy(r::run).isInstanceOfSatisfying(BizException.class, e -> {
            assertThat(e.getCode()).isEqualTo(60022);
            assertThat(e.getMsgId()).isEqualTo("MSG-PRD-022");
        });
    }

    // ---- 換算ルール ----

    @Test
    void identicalUnitNeedsNoRate() {
        assertThat(toKg("KGM", "1.23456", D)).isEqualByComparingTo("1.23456");
    }

    @Test
    void sameGroupConvertsWithCeilingToBaseDecimalPlaces() {
        rate(999101, CO, "GRM", "KGM", "0.001", "2026-01-01", null, 1, false);
        assertThat(toKg("GRM", "1234.5", D)).isEqualByComparingTo("1.235");     // 1.2345 → CEILING 3 桁
        assertThat(toKg("GRM", "1000", D)).isEqualByComparingTo("1.000");
    }

    @Test
    void reverseDirectionRowDivides() {
        rate(999102, CO, "KGM", "GRM", "1000", "2026-01-01", null, 1, false);   // 1 KGM = 1000 GRM
        assertThat(toKg("GRM", "1500", D)).isEqualByComparingTo("1.500");
    }

    @Test
    void noRateOrOtherGroupOrUnknownUnitIs60022() {
        is60022(() -> toKg("GRM", "1", D));                                      // 換算率なし
        is60022(() -> inTx(() -> uoms.toBase(CO, "PCE", "KGM", BigDecimal.ONE, D)));   // 別グループ
        is60022(() -> inTx(() -> uoms.toBase(CO, "LBR", "KGM", BigDecimal.ONE, D)));   // 未登録単位
        rate(999103, CO2, "GRM", "KGM", "0.001", "2026-01-01", null, 1, false);  // 他社の換算率は使わない
        is60022(() -> toKg("GRM", "1", D));
    }

    @Test
    void multipleEffectiveRatesIs60022() {
        rate(999104, CO, "GRM", "KGM", "0.001", "2026-01-01", null, 1, false);
        rate(999105, CO, "KGM", "GRM", "1000", "2026-01-01", null, 1, false);    // 正逆両方向が同時に有効
        is60022(() -> toKg("GRM", "1", D));
    }

    @Test
    void inactiveAndDeletedRatesAreIgnored() {
        rate(999106, CO, "GRM", "KGM", "0.001", "2026-01-01", null, 0, false);   // status=0
        rate(999107, CO, "KGM", "GRM", "1000", "2026-01-01", null, 1, true);     // deleted
        is60022(() -> toKg("GRM", "1", D));
        rate(999108, CO, "GRM", "KGM", "0.002", "2026-01-01", null, 1, false);   // 有効はこれ 1 件のみ
        assertThat(toKg("GRM", "1000", D)).isEqualByComparingTo("2.000");
    }

    @Test
    void validToIsInclusiveAndValidFromApplies() {
        rate(999109, CO, "GRM", "KGM", "0.001", "2026-10-01", "2026-11-02", 1, false);
        assertThat(toKg("GRM", "1000", LocalDate.of(2026, 11, 2))).isEqualByComparingTo("1.000");   // valid_to 当日
        is60022(() -> toKg("GRM", "1000", LocalDate.of(2026, 11, 3)));                            // 翌日は失効
        is60022(() -> toKg("GRM", "1000", LocalDate.of(2026, 9, 30)));                            // valid_from 前
    }

    // ---- 登録・下达・提出 ----

    void bom(long id, String lineUom, String componentQty, long component) {
        owner.update("""
            INSERT INTO prd_bom (id, tenant_id, company_id, bom_no, material_id, material_code, material_name, factory_id,
                version_no, base_uom_code, valid_from, is_default, bom_status)
            VALUES (?, 309, 91, ?, 999011, '9990000011', 'U 成品', 999021, 1, 'PCE', DATE '2026-01-01', TRUE, 30)
            """, id, "BOM-" + id);
        owner.update("""
            INSERT INTO prd_bom_line (id, tenant_id, company_id, bom_id, line_no, component_material_id, component_code,
                component_name, uom_code, component_qty, required_qty)
            VALUES (?, 309, 91, ?, 10, ?, 'C', 'C', ?, CAST(? AS NUMERIC), CAST(? AS NUMERIC))
            """, id + 1, id, component, lineUom, componentQty, componentQty);
    }

    WorkOrderCreateCommand cmd() {
        return new WorkOrderCreateCommand(null, FACTORY, MAT, new BigDecimal("3"), "PCE", D, D.plusDays(7), null, null,
                WH, null, null, null);
    }

    long woCount() {
        return owner.queryForObject("SELECT count(*) FROM prd_work_order WHERE tenant_id = 309", Long.class);
    }

    long lineCount() {
        return owner.queryForObject("SELECT count(*) FROM prd_work_order_material WHERE tenant_id = 309", Long.class);
    }

    @Test
    void createExpandsBomIntoBaseUnitAndKeepsBomOriginals() {
        rate(999110, CO, "GRM", "KGM", "0.001", "2026-01-01", null, 1, false);
        bom(999201, "GRM", "411.5", COMP_KG);                 // 3 × 411.5 g = 1234.5 g → 1.235 kg
        WorkOrderCreated c = as(() -> workOrders.create(cmd()));
        assertThat(c.warnings()).isEmpty();
        Map<String, Object> m = owner.queryForMap("SELECT * FROM prd_work_order_material WHERE work_order_id = ?", c.id());
        assertThat(m.get("uom_code")).isEqualTo("KGM");
        assertThat((BigDecimal) m.get("required_qty")).isEqualByComparingTo("1.235");
        assertThat((BigDecimal) m.get("total_required_qty")).isEqualByComparingTo("1.235");
        assertThat(m.get("bom_uom_code")).isEqualTo("GRM");
        assertThat((BigDecimal) m.get("bom_qty")).isEqualByComparingTo("1234.5");
    }

    @Test
    void createWithIdenticalUnitStoresBomOriginalsToo() {
        bom(999202, "PCE", "2", COMP_PCE);
        WorkOrderCreated c = as(() -> workOrders.create(cmd()));
        Map<String, Object> m = owner.queryForMap("SELECT * FROM prd_work_order_material WHERE work_order_id = ?", c.id());
        assertThat(m.get("uom_code")).isEqualTo("PCE");
        assertThat((BigDecimal) m.get("required_qty")).isEqualByComparingTo("6");
        assertThat(m.get("bom_uom_code")).isEqualTo("PCE");
    }

    @Test
    void createWithUnconvertibleBomUnitIs60022AndRollsBack() {
        bom(999203, "GRM", "1", COMP_KG);                    // GRM→KGM の換算率なし
        is60022(() -> as(() -> workOrders.create(cmd())));
        assertThat(woCount()).isZero();
        assertThat(lineCount()).isZero();
    }

    @Test
    void createWithoutBomStillOnlyWarns60020() {
        WorkOrderCreated c = as(() -> workOrders.create(cmd()));
        assertThat(c.warnings()).singleElement().satisfies(w -> assertThat(w.code()).isEqualTo(60020));
        assertThat(lineCount()).isZero();
    }

    long insertWo(long id, int status) {
        owner.update("""
            INSERT INTO prd_work_order (id, tenant_id, company_id, work_order_no, material_id, material_code, material_name,
                uom_code, factory_id, warehouse_id, order_qty, planned_start_date, planned_end_date, order_status,
                over_receipt_rate, created_by)
            VALUES (?, 309, 91, ?, 999011, '9990000011', 'U 成品', 'PCE', 999021, 999061, 3, DATE '2026-11-02',
                DATE '2026-11-09', ?, 0.05, 7999)
            """, id, "WO-U-" + id, status);
        return id;
    }

    @Test
    void releaseExpansionFailureIs60022AndStatusUnchanged() {
        long wo = insertWo(999301, 25);
        bom(999204, "GRM", "1", COMP_KG);
        is60022(() -> as(() -> releases.release(wo, new WorkOrderReleaseCommand(0))));
        Map<String, Object> w = owner.queryForMap("SELECT order_status, version FROM prd_work_order WHERE id = ?", wo);
        assertThat(w.get("order_status")).isEqualTo(25);
        assertThat(w.get("version")).isEqualTo(0);
        assertThat(lineCount()).isZero();
    }

    @Test
    void releaseRechecksExistingBomLineAndRollsBack() {
        long wo = insertWo(999302, 25);
        owner.update("""
            INSERT INTO prd_work_order_material (id, tenant_id, company_id, work_order_id, line_no, bom_line_id, material_id,
                material_code, material_name, uom_code, required_qty, total_required_qty, remaining_qty, bom_uom_code, bom_qty)
            VALUES (999401, 309, 91, ?, 10, NULL, 999012, '9990000012', 'U 原料 kg', 'KGM', 1, 1, 1, 'GRM', 1000)
            """, wo);                                         // 換算率が失効した BOM 由来行
        is60022(() -> as(() -> releases.release(wo, new WorkOrderReleaseCommand(0))));
        assertThat(owner.queryForObject("SELECT order_status FROM prd_work_order WHERE id = ?", Integer.class, wo))
                .isEqualTo(25);
        rate(999111, CO, "GRM", "KGM", "0.001", "2026-01-01", null, 1, false);
        as(() -> releases.release(wo, new WorkOrderReleaseCommand(0)));
        assertThat(owner.queryForObject("SELECT order_status FROM prd_work_order WHERE id = ?", Integer.class, wo))
                .isEqualTo(30);
        assertThat(owner.queryForObject("SELECT required_qty FROM prd_work_order_material WHERE id = 999401",
                BigDecimal.class)).isEqualByComparingTo("1");   // 既存数量は書き換えない
    }

    @Test
    void submitChecksAllLinesAndApiMapsTo422() throws Exception {
        long wo = insertWo(999303, 10);
        owner.update("""
            INSERT INTO prd_work_order_material (id, tenant_id, company_id, work_order_id, line_no, material_id,
                material_code, material_name, uom_code, required_qty, total_required_qty, remaining_qty)
            VALUES (999402, 309, 91, ?, 10, 999012, '9990000012', 'U 原料 kg', 'GRM', 5, 5, 5)
            """, wo);                                         // 手工行が基本単位（KGM）以外
        MockMvc mvc = MockMvcBuilders.webAppContextSetup(wac).build();
        TenantContext.set(TENANT);
        LoginContext.set(new LoginUser(USER, CO));
        mvc.perform(post("/api/production/work-orders/" + wo + "/submit").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"version\": 0}"))
                .andExpect(status().isUnprocessableContent())
                .andExpect(jsonPath("$.code").value(60022))
                .andExpect(jsonPath("$.msgId").value("MSG-PRD-022"));
        assertThat(owner.queryForObject("SELECT order_status FROM prd_work_order WHERE id = ?", Integer.class, wo))
                .isEqualTo(10);

        owner.update("UPDATE prd_work_order_material SET uom_code = 'KGM' WHERE id = 999402");
        mvc.perform(post("/api/production/work-orders/" + wo + "/submit").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"version\": 0}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.orderStatus").value(20));
    }
}
