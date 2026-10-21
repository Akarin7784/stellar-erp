package com.stellar.erp.production;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.math.BigDecimal;
import java.util.Map;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.json.JsonCompareMode;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;
import org.testcontainers.postgresql.PostgreSQLContainer;

import com.jayway.jsonpath.JsonPath;
import com.stellar.erp.common.LoginContext;
import com.stellar.erp.common.LoginContext.LoginUser;
import com.stellar.erp.common.TenantContext;
import com.stellar.erp.support.DbIntegrationTest;
import com.stellar.erp.support.OwnerJdbc;
import com.stellar.erp.support.PermissionGrants;

/**
 * 超产申请 / 承認 API（{@code /api/production/overproduction-approvals}）の実エンドポイント結合テスト（erp_app + RLS、MockMvc）。
 * 受注行 base_qty 100・allowed_qty 105、基本単位 PCE（decimal_places 0）、{@code prd.overproduction_max_rate} 0.5 → 1 件上限 50。
 */
@DbIntegrationTest
class OverproductionApprovalApiIntegrationTest {

    static final long TENANT = 311L, CO = 71L, CO2 = 72L, USER = 7311L, APPROVER = 7312L;
    static final long LINE = 997041, LINE2 = 997042, LINE_CO2 = 997043, WO = 997101, WO_LINE2 = 997102, WO_CO2 = 997103;
    static final String BASE = "/api/production/overproduction-approvals";
    static final String[] ALL_CODES = {"production:overproduction-approval:view", "production:overproduction-approval:create",
            "production:overproduction-approval:submit", "production:overproduction-approval:approve",
            "production:overproduction-approval:cancel"};

    @Autowired PostgreSQLContainer pg;
    @Autowired WebApplicationContext wac;
    @Autowired OverproductionApprovalService approvals;

    /** owner 接続はクラスで 1 本だけ（テストごとに開くと接続がリークし、CI で too many clients になる）。 */
    static JdbcTemplate sharedOwner;
    JdbcTemplate owner;
    MockMvc mvc;

    @BeforeEach
    void seed() {
        if (sharedOwner == null) {
            sharedOwner = OwnerJdbc.of(pg);
        }
        owner = sharedOwner;
        mvc = MockMvcBuilders.webAppContextSetup(wac).build();
        cleanup();
        owner.execute("""
            INSERT INTO mdm_material_category (id, tenant_id, company_id, category_code, category_name, category_path, category_level, is_leaf)
              VALUES (997001, 311, 71, 'O1', 'O', '/O1/', 1, TRUE), (997002, 311, 72, 'O1', 'O 72', '/O1/', 1, TRUE);
            INSERT INTO mdm_material (id, tenant_id, company_id, material_code, material_name, material_type, category_id, spec, base_uom_code, valuation_method, status)
              VALUES (997011, 311, 71, '9970000011', 'O 成品', 10, 997001, 's', 'PCE', 20, 1),
                     (997012, 311, 72, '9970000012', 'O 成品 72', 10, 997002, 's', 'PCE', 20, 1);
            INSERT INTO mdm_factory (id, tenant_id, company_id, factory_code, factory_name) VALUES
              (997021, 311, 71, 'F71', '工厂71'), (997022, 311, 72, 'F72', '工厂72');
            INSERT INTO mdm_uom (id, tenant_id, company_id, uom_code, uom_name, conversion_group, decimal_places) VALUES
              (997071, 311, 71, 'PCE', '个', 'PCS', 0), (997072, 311, 72, 'PCE', '个', 'PCS', 0);
            INSERT INTO mdm_customer (id, tenant_id, company_id, customer_code, customer_name, customer_type, tax_no, owner_user_id, payment_term_code, settlement_method_code) VALUES
              (997031, 311, 71, 'C997031', 'O 客户', 10, '91320000000000000X', 1, 'NET30', 'TT'),
              (997032, 311, 72, 'C997032', 'O 客户 72', 10, '91320000000000000X', 1, 'NET30', 'TT');
            INSERT INTO sal_sales_order (id, tenant_id, company_id, sales_order_no, order_date, customer_id, customer_code, customer_name,
                                         delivery_address, sales_department_id, owner_user_id, payment_term_code, delivery_date, warehouse_id, order_status) VALUES
              (997031, 311, 71, 'SO-O-71', DATE '2026-10-01', 997031, 'C997031', 'O', 'addr', 1, 1, 'NET30', DATE '2026-11-30', 1, 25),
              (997032, 311, 72, 'SO-O-72', DATE '2026-10-01', 997032, 'C997032', 'O', 'addr', 1, 1, 'NET30', DATE '2026-11-30', 1, 25);
            INSERT INTO sal_sales_order_line (id, tenant_id, company_id, sales_order_id, line_no, material_id, material_code, material_name,
                                              ordered_qty, uom_code, base_uom_code, base_qty, unit_price, tax_code, tax_rate, delivery_date, warehouse_id,
                                              completion_over_rate, allowed_qty, completed_qty) VALUES
              (997041, 311, 71, 997031, 10, 997011, '9970000011', 'O', 100, 'PCE', 'PCE', 100, 1, 'VAT13-OUT', 13, DATE '2026-11-30', 1, 0.05, 105, 0),
              (997042, 311, 71, 997031, 20, 997011, '9970000011', 'O', 100, 'PCE', 'PCE', 100, 1, 'VAT13-OUT', 13, DATE '2026-11-30', 1, 0.05, 105, 0),
              (997043, 311, 72, 997032, 10, 997012, '9970000012', 'O', 100, 'PCE', 'PCE', 100, 1, 'VAT13-OUT', 13, DATE '2026-11-30', 1, 0.05, 105, 0);
            INSERT INTO sys_param (id, tenant_id, company_id, param_key, param_name, param_group, param_value, value_type) VALUES
              (997091, 311, 71, 'prd.overproduction_max_rate', '超产申请上限率', 'prd', '0.5000', 3),
              (997092, 311, 72, 'prd.overproduction_max_rate', '超产申请上限率', 'prd', '9.0000', 3);
            INSERT INTO sys_user (id, tenant_id, company_id, user_code, username, real_name, nickname, password_hash) VALUES
              (7311, 311, 71, 'E007311', 'u7311', '申请人甲', '甲', 'x');
            """);
        // 91 #39a〜39g の権限コード（シードに依存せず明示付与）
        PermissionGrants.grant(owner, TENANT, CO, USER, 997500, ALL_CODES);
        PermissionGrants.grant(owner, TENANT, CO, APPROVER, 997600, ALL_CODES);
        PermissionGrants.grant(owner, TENANT, CO2, USER, 997700, ALL_CODES);
        PermissionGrants.grant(owner, TENANT, CO2, APPROVER, 997800, ALL_CODES);
        insertWorkOrder(WO, 71, 997011, 997021, 997031, LINE);
        insertWorkOrder(WO_LINE2, 71, 997011, 997021, 997031, LINE2);
        insertWorkOrder(WO_CO2, 72, 997012, 997022, 997032, LINE_CO2);
    }

    void insertWorkOrder(long id, long company, long material, long factory, long so, long line) {
        owner.update("""
            INSERT INTO prd_work_order (id, tenant_id, company_id, work_order_no, material_id, material_code, material_name,
                uom_code, factory_id, order_qty, allowed_qty, planned_start_date, planned_end_date, order_status, is_hold, over_receipt_rate,
                sales_order_id, sales_order_line_id, sales_order_no, source_type)
            VALUES (?, 311, ?, ?, ?, 'M', 'O 成品', 'PCE', ?, 100, 105, DATE '2026-11-01', DATE '2026-11-30', 30, FALSE, 0.05,
                ?, ?, 'SO-O', 30)
            """, id, company, "WO-O-" + id, material, factory, so, line);
    }

    @org.junit.jupiter.api.AfterAll
    static void closeOwner() {
        if (sharedOwner != null) {
            ((org.springframework.jdbc.datasource.SingleConnectionDataSource) sharedOwner.getDataSource()).destroy();
            sharedOwner = null;
        }
    }

    @AfterEach
    void tearDown() {
        cleanup();
        LoginContext.clear();
        TenantContext.clear();
    }

    void cleanup() {
        owner.execute("""
            DELETE FROM prd_overproduction_approval WHERE tenant_id = 311;
            DELETE FROM sys_user WHERE tenant_id = 311;
            DELETE FROM sys_user_role WHERE tenant_id = 311;
            DELETE FROM sys_role_permission WHERE tenant_id = 311;
            DELETE FROM sys_menu WHERE tenant_id = 311 AND module_code = 'test';
            DELETE FROM sys_role WHERE tenant_id = 311;
            DELETE FROM prd_work_order WHERE tenant_id = 311;
            DELETE FROM sys_sequence WHERE tenant_id = 311;
            DELETE FROM sys_param WHERE tenant_id = 311;
            DELETE FROM sal_sales_order_line WHERE tenant_id = 311;
            DELETE FROM sal_sales_order WHERE tenant_id = 311;
            DELETE FROM mdm_customer WHERE tenant_id = 311;
            DELETE FROM mdm_factory WHERE tenant_id = 311;
            DELETE FROM mdm_uom WHERE tenant_id = 311;
            DELETE FROM mdm_material WHERE tenant_id = 311;
            DELETE FROM mdm_material_category WHERE tenant_id = 311;
            """);
    }

    ResultActions postAs(long user, long company, String path, String json) throws Exception {
        TenantContext.set(TENANT);
        LoginContext.set(new LoginUser(user, company));
        return mvc.perform(post(path).contentType(MediaType.APPLICATION_JSON).content(json));
    }

    ResultActions create(long company, String json) throws Exception {
        return postAs(USER, company, BASE, json);
    }

    String body(long line, Long wo, String qty) {
        return "{\"salesOrderLineId\": \"" + line + "\"" + (wo == null ? "" : ", \"workOrderId\": \"" + wo + "\"")
                + ", \"requestQty\": " + qty + "}";
    }

    long approvalCount() {
        return owner.queryForObject("SELECT count(*) FROM prd_overproduction_approval WHERE tenant_id = 311", Long.class);
    }

    BigDecimal lineAllowed(long id) {
        return owner.queryForObject("SELECT allowed_qty FROM sal_sales_order_line WHERE id = ?", BigDecimal.class, id);
    }

    BigDecimal woAllowed(long id) {
        return owner.queryForObject("SELECT allowed_qty FROM prd_work_order WHERE id = ?", BigDecimal.class, id);
    }

    String createdId(MvcResult r) throws Exception {
        return JsonPath.read(r.getResponse().getContentAsString(), "$.data.id");
    }

    @Test
    void createWithinLimitIs201AndIdsAreStrings() throws Exception {
        MvcResult r = create(CO, body(LINE, WO, "50"))   // 上限 = 100 × 0.5 = 50（ちょうど上限は可）
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.id").isString())
                .andExpect(jsonPath("$.data.approvalNo").value(org.hamcrest.Matchers.matchesPattern("OPA\\d{6}0001")))
                .andExpect(jsonPath("$.data.approvalStatus").value(10))
                .andReturn();
        Map<String, Object> row = owner.queryForMap("SELECT * FROM prd_overproduction_approval WHERE id = ?",
                Long.parseLong(createdId(r)));
        assertThat(row.get("company_id")).isEqualTo(CO);
        assertThat(row.get("work_order_id")).isEqualTo(WO);
        assertThat((BigDecimal) row.get("request_qty")).isEqualByComparingTo("50");
        assertThat((BigDecimal) row.get("current_allowed_qty")).isEqualByComparingTo("105");
        assertThat(row.get("requested_by")).isEqualTo(USER);
    }

    @Test
    void noCumulativeCap() throws Exception {
        create(CO, body(LINE, null, "50")).andExpect(status().isCreated());
        create(CO, body(LINE, null, "50")).andExpect(status().isCreated());
        assertThat(approvalCount()).isEqualTo(2);
    }

    @ParameterizedTest
    @ValueSource(strings = {"51", "50.0001"})
    void overLimitIs422With60103(String qty) throws Exception {
        create(CO, body(LINE, null, qty))
                .andExpect(status().isUnprocessableContent())
                .andExpect(jsonPath("$.code").value(60103))
                .andExpect(jsonPath("$.msgId").value("MSG-PRD-103"));
        assertThat(approvalCount()).isZero();
    }

    @Test
    void scaleFinerThanBaseUnitIs60103() throws Exception {
        create(CO, body(LINE, null, "1.5"))
                .andExpect(status().isUnprocessableContent())
                .andExpect(jsonPath("$.code").value(60103))
                .andExpect(jsonPath("$.msgId").value("MSG-PRD-103"));
        // 末尾 0 は桁数に数えない（1.000 = 1）
        create(CO, body(LINE, null, "1.000")).andExpect(status().isCreated());
        assertThat(approvalCount()).isEqualTo(1);
    }

    @ParameterizedTest
    @ValueSource(strings = {"0", "-1", "null"})
    void zeroNegativeOrNullIs60103(String qty) throws Exception {
        create(CO, body(LINE, null, qty))
                .andExpect(status().isUnprocessableContent())
                .andExpect(jsonPath("$.code").value(60103))
                .andExpect(jsonPath("$.msgId").value("MSG-PRD-103"));
        assertThat(approvalCount()).isZero();
    }

    @Test
    void lineAllowedQtyNullIs422With60101() throws Exception {
        owner.update("UPDATE sal_sales_order_line SET allowed_qty = NULL WHERE id = ?", LINE);
        create(CO, body(LINE, null, "1"))
                .andExpect(status().isUnprocessableContent())
                .andExpect(content().json("{\"code\":60101,\"message\":\"受注行の allowed_qty が未確定のため超産申請はできません。\","
                        + "\"data\":null,\"msgId\":\"MSG-PRD-101\"}", JsonCompareMode.STRICT));
        assertThat(approvalCount()).isZero();
    }

    @Test
    void approveWhenLineAllowedQtyNullIs422With60101AndNothingChanged() throws Exception {
        String id = pendingApproval(null, "10");
        owner.update("UPDATE sal_sales_order_line SET allowed_qty = NULL WHERE id = ?", LINE);
        postAs(APPROVER, CO, BASE + "/" + id + "/approve", "{\"version\": 1}")
                .andExpect(status().isUnprocessableContent())
                .andExpect(content().json("{\"code\":60101,\"message\":\"受注行の allowed_qty が未確定または不正のため承認できません。\","
                        + "\"data\":null,\"msgId\":\"MSG-PRD-101\"}", JsonCompareMode.STRICT));
        assertThat(statusOf(id)).isEqualTo(20);
        assertThat(lineAllowed(LINE)).isNull();
    }

    @Test
    void missingParamIs5000() throws Exception {
        owner.update("DELETE FROM sys_param WHERE id = 997091");
        create(CO, body(LINE, null, "1"))
                .andExpect(status().isInternalServerError())
                .andExpect(jsonPath("$.code").value(5000));
        assertThat(approvalCount()).isZero();
    }

    @Test
    void otherCompanyLineIsNotFoundAndBodyCompanyIdIsIgnored() throws Exception {
        // 会社 71 のユーザーが会社 72 の受注行を指定 → 不存在（4001）
        create(CO, body(LINE_CO2, null, "1")).andExpect(status().isNotFound()).andExpect(jsonPath("$.code").value(4001));
        // 会社 72 のユーザーは会社 71 の受注行を見られない
        create(CO2, body(LINE, null, "1")).andExpect(status().isNotFound());
        // body の companyId は無視、LoginContext の会社で保存
        MvcResult r = create(CO, "{\"companyId\": \"72\", \"salesOrderLineId\": \"" + LINE + "\", \"requestQty\": 1}")
                .andExpect(status().isCreated()).andReturn();
        assertThat(owner.queryForObject("SELECT company_id FROM prd_overproduction_approval WHERE id = ?", Long.class,
                Long.parseLong(createdId(r)))).isEqualTo(CO);
        // 他社の申請は承認できない
        postAs(APPROVER, CO2, BASE + "/" + createdId(r) + "/cancel", "{\"version\": 0}")
                .andExpect(status().isNotFound());
        assertThat(lineAllowed(LINE)).isEqualByComparingTo("105");
    }

    @Test
    void workOrderOfOtherLineOrCompanyIs60056() throws Exception {
        create(CO, body(LINE, WO_LINE2, "1"))
                .andExpect(status().isUnprocessableContent()).andExpect(jsonPath("$.code").value(60056));
        create(CO, body(LINE, WO_CO2, "1"))
                .andExpect(status().isUnprocessableContent()).andExpect(jsonPath("$.code").value(60056));
        assertThat(approvalCount()).isZero();
    }

    String newApproval(Long wo, String qty) throws Exception {
        return createdId(create(CO, body(LINE, wo, qty)).andExpect(status().isCreated()).andReturn());
    }

    ResultActions act(long user, String id, String op, int version) throws Exception {
        return postAs(user, CO, BASE + "/" + id + "/" + op, "{\"version\": " + version + "}");
    }

    /** 新規（10）→ 提出（20、version 1）。 */
    String pendingApproval(Long wo, String qty) throws Exception {
        String id = newApproval(wo, qty);
        act(USER, id, "submit", 0).andExpect(status().isOk()).andExpect(jsonPath("$.data.approvalStatus").value(20))
                .andExpect(jsonPath("$.data.version").value(1));
        return id;
    }

    int statusOf(String id) {
        return owner.queryForObject("SELECT approval_status FROM prd_overproduction_approval WHERE id = ?", Integer.class,
                Long.parseLong(id));
    }

    ResultActions getAs(long company, String path, String... params) throws Exception {
        TenantContext.set(TENANT);
        LoginContext.set(new LoginUser(USER, company));
        var req = org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get(path);
        for (int i = 0; i < params.length; i += 2) {
            req.param(params[i], params[i + 1]);
        }
        return mvc.perform(req);
    }

    @Test
    void workOrderNotReleasedOrAllowedNullIs60101OnCreate() throws Exception {
        owner.update("UPDATE prd_work_order SET order_status = 25 WHERE id = ?", WO);
        create(CO, body(LINE, WO, "1")).andExpect(status().isUnprocessableContent())
                .andExpect(jsonPath("$.code").value(60101)).andExpect(jsonPath("$.msgId").value("MSG-PRD-101"));
        owner.update("UPDATE prd_work_order SET order_status = 30, allowed_qty = NULL WHERE id = ?", WO);
        create(CO, body(LINE, WO, "1")).andExpect(status().isUnprocessableContent())
                .andExpect(jsonPath("$.code").value(60101));
        assertThat(approvalCount()).isZero();
    }

    @Test
    void approveWorkOrderLevelRaisesLineAndWorkOrderAllowedQty() throws Exception {
        String id = pendingApproval(WO, "10");
        act(APPROVER, id, "approve", 1)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.id").value(id))
                .andExpect(jsonPath("$.data.approvalStatus").value(30))
                .andExpect(jsonPath("$.data.workOrderId").value(String.valueOf(WO)));
        assertThat(lineAllowed(LINE)).isEqualByComparingTo("115");
        assertThat(woAllowed(WO)).isEqualByComparingTo("115");
        assertThat(woAllowed(WO_LINE2)).isEqualByComparingTo("105");
        Map<String, Object> row = owner.queryForMap("SELECT * FROM prd_overproduction_approval WHERE id = ?", Long.parseLong(id));
        assertThat(row.get("approval_status")).isEqualTo(30);
        assertThat((BigDecimal) row.get("approved_allowed_qty")).isEqualByComparingTo("115");
        assertThat(row.get("approved_by")).isEqualTo(APPROVER);
        // 承認済への再承認は 60101、allowed_qty は再加算されない
        act(APPROVER, id, "approve", 2)
                .andExpect(status().isUnprocessableContent()).andExpect(jsonPath("$.code").value(60101));
        assertThat(lineAllowed(LINE)).isEqualByComparingTo("115");
        assertThat(woAllowed(WO)).isEqualByComparingTo("115");
    }

    @Test
    void approveLineLevelRaisesOnlyLine() throws Exception {
        String id = pendingApproval(null, "7");
        act(APPROVER, id, "approve", 1).andExpect(status().isOk());
        assertThat(lineAllowed(LINE)).isEqualByComparingTo("112");
        assertThat(woAllowed(WO)).isEqualByComparingTo("105");
    }

    @Test
    void approveDraftIs60101() throws Exception {
        String id = newApproval(WO, "10");
        act(APPROVER, id, "approve", 0).andExpect(status().isUnprocessableContent()).andExpect(jsonPath("$.code").value(60101));
        assertThat(lineAllowed(LINE)).isEqualByComparingTo("105");
        assertThat(statusOf(id)).isEqualTo(10);
    }

    @ParameterizedTest
    @ValueSource(ints = {30, 40, 90})
    void approvingApprovedRejectedOrCancelledIs60101(int st) throws Exception {
        String id = pendingApproval(WO, "10");
        owner.update("UPDATE prd_overproduction_approval SET approval_status = ? WHERE id = ?", st, Long.parseLong(id));
        act(APPROVER, id, "approve", 1)
                .andExpect(status().isUnprocessableContent())
                .andExpect(jsonPath("$.code").value(60101))
                .andExpect(jsonPath("$.msgId").value("MSG-PRD-101"));
        assertThat(lineAllowed(LINE)).isEqualByComparingTo("105");
        assertThat(woAllowed(WO)).isEqualByComparingTo("105");
    }

    @Test
    void selfApprovalIs60005() throws Exception {
        String id = pendingApproval(WO, "10");
        act(USER, id, "approve", 1)
                .andExpect(status().isUnprocessableContent())
                .andExpect(jsonPath("$.code").value(60005))
                .andExpect(jsonPath("$.msgId").value("MSG-PRD-005"));
        assertThat(lineAllowed(LINE)).isEqualByComparingTo("105");
        assertThat(woAllowed(WO)).isEqualByComparingTo("105");
        assertThat(statusOf(id)).isEqualTo(20);
    }

    @Test
    void staleVersionIs4003AndAllowedQtyUnchanged() throws Exception {
        String id = pendingApproval(WO, "10");   // version 1
        act(APPROVER, id, "approve", 0)
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value(4003))
                .andExpect(jsonPath("$.msgId").value("MSG-COM-033"));
        assertThat(lineAllowed(LINE)).isEqualByComparingTo("105");
        assertThat(woAllowed(WO)).isEqualByComparingTo("105");
        assertThat(statusOf(id)).isEqualTo(20);
    }

    /** 同一受注行の 2 件を別スレッド・別トランザクションで同時承認：両方成功し、受注行は増分の合計（ロストアップデートなし）。 */
    @Test
    void concurrentApprovalsOnSameLineBothApplied() throws Exception {
        long a = Long.parseLong(pendingApproval(WO, "10"));
        long b = Long.parseLong(pendingApproval(null, "7"));
        LoginContext.clear();
        TenantContext.clear();
        java.util.concurrent.CyclicBarrier barrier = new java.util.concurrent.CyclicBarrier(2);
        java.util.concurrent.ExecutorService pool = java.util.concurrent.Executors.newFixedThreadPool(2);
        try {
            java.util.List<java.util.concurrent.Future<OverproductionApproved>> fs = java.util.stream.Stream.of(a, b)
                    .map(id -> pool.submit(() -> {
                        barrier.await(10, java.util.concurrent.TimeUnit.SECONDS);
                        return TenantContext.callAs(TENANT, () -> LoginContext.callAs(new LoginUser(APPROVER, CO),
                                () -> approvals.approve(id, 1)));
                    })).toList();
            for (var f : fs) {
                assertThat(f.get(30, java.util.concurrent.TimeUnit.SECONDS).approvalStatus()).isEqualTo((short) 30);
            }
        } finally {
            pool.shutdownNow();
        }
        assertThat(lineAllowed(LINE)).isEqualByComparingTo("122");   // 105 + 10 + 7
        assertThat(woAllowed(WO)).isEqualByComparingTo("115");       // 工单級の 10 のみ
        assertThat(owner.queryForObject("""
                SELECT count(*) FROM prd_overproduction_approval WHERE tenant_id = 311 AND approval_status = 30""",
                Long.class)).isEqualTo(2);
    }

    @Test
    void submitOnlyFromDraft() throws Exception {
        String id = pendingApproval(WO, "10");
        act(USER, id, "submit", 1).andExpect(status().isUnprocessableContent()).andExpect(jsonPath("$.code").value(60101));
    }

    @Test
    void rejectFromPendingKeepsAllowedQty() throws Exception {
        String id = pendingApproval(WO, "10");
        postAs(APPROVER, CO, BASE + "/" + id + "/reject", "{\"version\": 1, \"rejectReason\": \"数量过多\"}")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.approvalStatus").value(40))
                .andExpect(jsonPath("$.data.rejectReason").value("数量过多"))
                .andExpect(jsonPath("$.data.approvedBy").value(String.valueOf(APPROVER)));
        assertThat(lineAllowed(LINE)).isEqualByComparingTo("105");
        assertThat(woAllowed(WO)).isEqualByComparingTo("105");
        postAs(APPROVER, CO, BASE + "/" + id + "/reject", "{\"version\": 2, \"rejectReason\": \"再却下\"}").andExpect(status().isUnprocessableContent()).andExpect(jsonPath("$.code").value(60101));
        act(USER, id, "cancel", 2).andExpect(status().isUnprocessableContent()).andExpect(jsonPath("$.code").value(60101));
        String draft = newApproval(null, "1");
        postAs(APPROVER, CO, BASE + "/" + draft + "/reject", "{\"version\": 0, \"rejectReason\": \"草稿却下\"}").andExpect(status().isUnprocessableContent()).andExpect(jsonPath("$.code").value(60101));
    }

    @Test
    void cancelFromDraftOrPendingAndNotAfterApproval() throws Exception {
        String draft = newApproval(null, "1");
        act(USER, draft, "cancel", 0).andExpect(status().isOk()).andExpect(jsonPath("$.data.approvalStatus").value(90));
        String pending = pendingApproval(null, "1");
        act(USER, pending, "cancel", 1).andExpect(status().isOk()).andExpect(jsonPath("$.data.approvalStatus").value(90));
        String approved = pendingApproval(WO, "10");
        act(APPROVER, approved, "approve", 1).andExpect(status().isOk());
        act(USER, approved, "cancel", 2).andExpect(status().isUnprocessableContent()).andExpect(jsonPath("$.code").value(60101));
        assertThat(lineAllowed(LINE)).isEqualByComparingTo("115");
        assertThat(statusOf(approved)).isEqualTo(30);
        act(USER, draft, "submit", 1).andExpect(status().isUnprocessableContent()).andExpect(jsonPath("$.code").value(60101));
    }

    @Test
    void getDetailAndListAreCompanyScoped() throws Exception {
        String a = newApproval(WO, "10");
        String b = pendingApproval(null, "3");
        getAs(CO, BASE + "/" + a)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.id").value(a))
                .andExpect(jsonPath("$.data.salesOrderLineId").value(String.valueOf(LINE)))
                .andExpect(jsonPath("$.data.workOrderId").value(String.valueOf(WO)))
                .andExpect(jsonPath("$.data.approvalStatus").value(10))
                .andExpect(jsonPath("$.data.requestedBy").value(String.valueOf(USER)))
                .andExpect(jsonPath("$.data.salesOrderId").value("997031"))
                .andExpect(jsonPath("$.data.salesOrderNo").value("SO-O-71"))
                .andExpect(jsonPath("$.data.workOrderNo").value("WO-O-" + WO))
                .andExpect(jsonPath("$.data.materialId").value("997011"))
                .andExpect(jsonPath("$.data.materialCode").value("9970000011"))
                .andExpect(jsonPath("$.data.materialName").value("O 成品"))
                .andExpect(jsonPath("$.data.requestedByName").value("申请人甲"));
        getAs(CO, BASE, "approvalStatus", "20")
                .andExpect(jsonPath("$.data.list[0].salesOrderNo").value("SO-O-71"))
                .andExpect(jsonPath("$.data.list[0].workOrderId").doesNotExist())
                .andExpect(jsonPath("$.data.list[0].workOrderNo").doesNotExist())
                .andExpect(jsonPath("$.data.list[0].materialCode").value("9970000011"))
                .andExpect(jsonPath("$.data.list[0].requestedByName").value("申请人甲"));
        getAs(CO, BASE, "salesOrderLineId", String.valueOf(LINE))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(2))
                .andExpect(jsonPath("$.data.list.length()").value(2));
        getAs(CO, BASE, "approvalStatus", "20")
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].id").value(b));
        getAs(CO, BASE, "workOrderId", String.valueOf(WO))
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].id").value(a));
        getAs(CO2, BASE + "/" + a).andExpect(status().isNotFound()).andExpect(jsonPath("$.code").value(4001));
        getAs(CO2, BASE).andExpect(status().isOk()).andExpect(jsonPath("$.data.total").value(0));
    }

    // ------------------------------------------------------------------ 403（権限コードなし、エンドポイントごと）

    static final long NOPERM = 7399L;

    ResultActions asNoPerm(org.springframework.test.web.servlet.RequestBuilder req) throws Exception {
        TenantContext.set(TENANT);
        LoginContext.set(new LoginUser(NOPERM, CO));
        return mvc.perform(req);
    }

    static void is403(ResultActions r) throws Exception {
        r.andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value(3001))
                .andExpect(jsonPath("$.msgId").value("MSG-COM-030"));
    }

    /** view 以外の全コードを持つユーザ：一覧は 403。 */
    @Test
    void listWithoutViewIs403() throws Exception {
        PermissionGrants.grant(owner, TENANT, CO, NOPERM, 997900, ALL_CODES[1], ALL_CODES[2], ALL_CODES[3], ALL_CODES[4]);
        is403(asNoPerm(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get(BASE)));
    }

    @Test
    void detailWithoutViewIs403() throws Exception {
        String id = newApproval(null, "1");
        PermissionGrants.grant(owner, TENANT, CO, NOPERM, 997900, ALL_CODES[1], ALL_CODES[2], ALL_CODES[3], ALL_CODES[4]);
        is403(asNoPerm(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get(BASE + "/" + id)));
    }

    @Test
    void createWithoutCreateIs403() throws Exception {
        PermissionGrants.grant(owner, TENANT, CO, NOPERM, 997900, ALL_CODES[0], ALL_CODES[2], ALL_CODES[3], ALL_CODES[4]);
        is403(asNoPerm(post(BASE).contentType(MediaType.APPLICATION_JSON).content(body(LINE, null, "1"))));
        assertThat(approvalCount()).isZero();
    }

    @Test
    void submitWithoutSubmitIs403() throws Exception {
        String id = newApproval(null, "1");
        PermissionGrants.grant(owner, TENANT, CO, NOPERM, 997900, ALL_CODES[0], ALL_CODES[1], ALL_CODES[3], ALL_CODES[4]);
        is403(asNoPerm(post(BASE + "/" + id + "/submit").contentType(MediaType.APPLICATION_JSON).content("{\"version\": 0}")));
        assertThat(statusOf(id)).isEqualTo(10);
    }

    @Test
    void approveWithoutApproveIs403() throws Exception {
        String id = pendingApproval(WO, "10");
        PermissionGrants.grant(owner, TENANT, CO, NOPERM, 997900, ALL_CODES[0], ALL_CODES[1], ALL_CODES[2], ALL_CODES[4]);
        is403(asNoPerm(post(BASE + "/" + id + "/approve").contentType(MediaType.APPLICATION_JSON).content("{\"version\": 1}")));
        assertThat(statusOf(id)).isEqualTo(20);
        assertThat(lineAllowed(LINE)).isEqualByComparingTo("105");
    }

    @Test
    void rejectWithoutApproveIs403() throws Exception {
        String id = pendingApproval(WO, "10");
        PermissionGrants.grant(owner, TENANT, CO, NOPERM, 997900, ALL_CODES[0], ALL_CODES[1], ALL_CODES[2], ALL_CODES[4]);
        is403(asNoPerm(post(BASE + "/" + id + "/reject").contentType(MediaType.APPLICATION_JSON).content("{\"version\": 1}")));
        assertThat(statusOf(id)).isEqualTo(20);
    }

    @Test
    void cancelWithoutCancelIs403() throws Exception {
        String id = newApproval(null, "1");
        PermissionGrants.grant(owner, TENANT, CO, NOPERM, 997900, ALL_CODES[0], ALL_CODES[1], ALL_CODES[2], ALL_CODES[3]);
        is403(asNoPerm(post(BASE + "/" + id + "/cancel").contentType(MediaType.APPLICATION_JSON).content("{\"version\": 0}")));
        assertThat(statusOf(id)).isEqualTo(10);
    }

    // ------------------------------------------------------------------ 驳回理由の検証（91:589、AC-PRD-17）

    ResultActions reject(String id, String reasonJson) throws Exception {
        return postAs(APPROVER, CO, BASE + "/" + id + "/reject",
                "{\"version\": 1" + (reasonJson == null ? "" : ", \"rejectReason\": " + reasonJson) + "}");
    }

    static String required() {
        return "{\"code\":1001,\"message\":\"请输入必填项「驳回理由」。\",\"msgId\":\"MSG-COM-040\",\"data\":{\"fieldErrors\":["
                + "{\"field\":\"rejectReason\",\"message\":\"请输入必填项「驳回理由」。\"}]}}";
    }

    @ParameterizedTest
    @ValueSource(strings = {"MISSING", "\"\"", "\"   \"", "\"\\t\\n \""})
    void blankRejectReasonIs400With040(String reasonJson) throws Exception {
        String id = pendingApproval(WO, "10");
        reject(id, "MISSING".equals(reasonJson) ? null : reasonJson)
                .andExpect(status().isBadRequest())
                .andExpect(content().json(required(), JsonCompareMode.STRICT));
        assertThat(statusOf(id)).isEqualTo(20);
    }

    @Test
    void rejectReasonOver500Is400With041() throws Exception {
        String id = pendingApproval(WO, "10");
        reject(id, "\"" + "理".repeat(501) + "\"")
                .andExpect(status().isBadRequest())
                .andExpect(content().json("{\"code\":1001,\"message\":\"「驳回理由」不能超过 500 个字符。\",\"msgId\":\"MSG-COM-041\","
                        + "\"data\":{\"fieldErrors\":[{\"field\":\"rejectReason\",\"message\":\"「驳回理由」不能超过 500 个字符。\"}]}}",
                        JsonCompareMode.STRICT));
        assertThat(statusOf(id)).isEqualTo(20);
    }

    @Test
    void rejectReasonExactly500Succeeds() throws Exception {
        String id = pendingApproval(WO, "10");
        String reason = "理".repeat(500);
        reject(id, "\"" + reason + "\"")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.approvalStatus").value(40))
                .andExpect(jsonPath("$.data.rejectReason").value(reason));
        assertThat(owner.queryForObject("SELECT reject_reason FROM prd_overproduction_approval WHERE id = ?", String.class,
                Long.parseLong(id))).isEqualTo(reason);
    }

    // ------------------------------------------------------------------ 草稿修正 PUT /{id}（#39h、AC-PRD-18）

    ResultActions putAs(long user, String id, String json) throws Exception {
        TenantContext.set(TENANT);
        LoginContext.set(new LoginUser(user, CO));
        return mvc.perform(put(BASE + "/" + id).contentType(MediaType.APPLICATION_JSON).content(json));
    }

    BigDecimal snapshotOf(String id) {
        return owner.queryForObject("SELECT current_allowed_qty FROM prd_overproduction_approval WHERE id = ?",
                BigDecimal.class, Long.parseLong(id));
    }

    @Test
    void editDraftUpdatesQtyWorkOrderAndRemarkAndKeepsAllowedQty() throws Exception {
        String id = newApproval(null, "5");
        // salesOrderLineId は修正不可（body にあっても無視）
        putAs(USER, id, "{\"version\": 0, \"workOrderId\": \"" + WO + "\", \"requestQty\": 12, \"remark\": \"追加\", "
                + "\"salesOrderLineId\": \"" + LINE2 + "\"}")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.approvalStatus").value(10))
                .andExpect(jsonPath("$.data.version").value(1))
                .andExpect(jsonPath("$.data.workOrderId").value(String.valueOf(WO)))
                .andExpect(jsonPath("$.data.workOrderNo").value("WO-O-" + WO))
                .andExpect(jsonPath("$.data.requestQty").value(12))
                .andExpect(jsonPath("$.data.salesOrderLineId").value(String.valueOf(LINE)))
                .andExpect(jsonPath("$.data.remark").value("追加"));
        Map<String, Object> row = owner.queryForMap("SELECT * FROM prd_overproduction_approval WHERE id = ?", Long.parseLong(id));
        assertThat((BigDecimal) row.get("request_qty")).isEqualByComparingTo("12");
        assertThat(row.get("work_order_id")).isEqualTo(WO);
        assertThat(row.get("sales_order_line_id")).isEqualTo(LINE);
        assertThat(row.get("remark")).isEqualTo("追加");
        assertThat(((Number) row.get("approval_status")).intValue()).isEqualTo(10);
        assertThat(snapshotOf(id)).isEqualByComparingTo("105");
        assertThat(lineAllowed(LINE)).isEqualByComparingTo("105");
        assertThat(woAllowed(WO)).isEqualByComparingTo("105");
        // 工单級 → 受注行級へ戻す
        putAs(USER, id, "{\"version\": 1, \"workOrderId\": null, \"requestQty\": 3}")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.workOrderId").doesNotExist())
                .andExpect(jsonPath("$.data.version").value(2));
    }

    @Test
    void editRemarkOver500Is400With041AndExactly500Succeeds() throws Exception {
        String id = newApproval(null, "5");
        putAs(USER, id, "{\"version\": 0, \"requestQty\": 6, \"remark\": \"" + "备".repeat(501) + "\"}")
                .andExpect(status().isBadRequest())
                .andExpect(content().json("{\"code\":1001,\"message\":\"「备注」不能超过 500 个字符。\",\"msgId\":\"MSG-COM-041\","
                        + "\"data\":{\"fieldErrors\":[{\"field\":\"remark\",\"message\":\"「备注」不能超过 500 个字符。\"}]}}",
                        JsonCompareMode.STRICT));
        assertThat(owner.queryForObject("SELECT version FROM prd_overproduction_approval WHERE id = ?", Integer.class,
                Long.parseLong(id))).isZero();
        String ok = "备".repeat(500);
        putAs(USER, id, "{\"version\": 0, \"requestQty\": 6, \"remark\": \"" + ok + "\"}")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.remark").value(ok))
                .andExpect(jsonPath("$.data.version").value(1));
    }

    @Test
    void editWithoutVersionIs400With040() throws Exception {
        String id = newApproval(null, "5");
        String required = "{\"code\":1001,\"message\":\"请输入必填项「version」。\",\"msgId\":\"MSG-COM-040\","
                + "\"data\":{\"fieldErrors\":[{\"field\":\"version\",\"message\":\"请输入必填项「version」。\"}]}}";
        putAs(USER, id, "{\"requestQty\": 6}")
                .andExpect(status().isBadRequest())
                .andExpect(content().json(required, JsonCompareMode.STRICT));
        putAs(USER, id, "{\"version\": null, \"requestQty\": 6}")
                .andExpect(status().isBadRequest())
                .andExpect(content().json(required, JsonCompareMode.STRICT));
        Map<String, Object> row = owner.queryForMap("SELECT request_qty, version FROM prd_overproduction_approval WHERE id = ?",
                Long.parseLong(id));
        assertThat((BigDecimal) row.get("request_qty")).isEqualByComparingTo("5");
        assertThat(((Number) row.get("version")).intValue()).isZero();
    }

    @Test
    void editStaleVersionIs409With4003() throws Exception {
        String id = newApproval(null, "5");
        putAs(USER, id, "{\"version\": 7, \"requestQty\": 6}")
                .andExpect(status().isConflict())
                .andExpect(content().json("{\"code\":4003,\"message\":\"数据已被其他用户更新，请重新获取最新信息后再操作。\",\"data\":null,\"msgId\":\"MSG-COM-033\"}",
                        JsonCompareMode.STRICT));
        assertThat(owner.queryForObject("SELECT request_qty FROM prd_overproduction_approval WHERE id = ?", BigDecimal.class,
                Long.parseLong(id))).isEqualByComparingTo("5");
    }

    @ParameterizedTest
    @ValueSource(ints = {20, 30, 40, 90})
    void editNonDraftIs422With60101(int st) throws Exception {
        String id = newApproval(null, "5");
        owner.update("UPDATE prd_overproduction_approval SET approval_status = ? WHERE id = ?", st, Long.parseLong(id));
        putAs(USER, id, "{\"version\": 0, \"requestQty\": 6}")
                .andExpect(status().isUnprocessableContent())
                .andExpect(content().json("{\"code\":60101,\"message\":\"超産承認が無効です（現在の状態ではこの操作はできません）。\",\"data\":null,\"msgId\":\"MSG-PRD-101\"}",
                        JsonCompareMode.STRICT));
        assertThat(statusOf(id)).isEqualTo(st);
        assertThat(owner.queryForObject("SELECT request_qty FROM prd_overproduction_approval WHERE id = ?", BigDecimal.class,
                Long.parseLong(id))).isEqualByComparingTo("5");
        assertThat(lineAllowed(LINE)).isEqualByComparingTo("105");
    }

    @ParameterizedTest
    @ValueSource(strings = {"0", "-1", "51", "1.5", "null"})
    void editInvalidQtyIs60103(String qty) throws Exception {
        String id = newApproval(null, "5");
        putAs(USER, id, "{\"version\": 0, \"requestQty\": " + qty + "}")
                .andExpect(status().isUnprocessableContent()).andExpect(jsonPath("$.code").value(60103));
    }

    @Test
    void editToOtherLineOrCompanyWorkOrderIs60056() throws Exception {
        String id = newApproval(null, "5");
        putAs(USER, id, "{\"version\": 0, \"workOrderId\": \"" + WO_LINE2 + "\", \"requestQty\": 5}")
                .andExpect(status().isUnprocessableContent()).andExpect(jsonPath("$.code").value(60056));
        putAs(USER, id, "{\"version\": 0, \"workOrderId\": \"" + WO_CO2 + "\", \"requestQty\": 5}")
                .andExpect(status().isUnprocessableContent()).andExpect(jsonPath("$.code").value(60056));
    }

    @Test
    void editOtherCompanyIs404() throws Exception {
        String id = newApproval(null, "5");
        TenantContext.set(TENANT);
        LoginContext.set(new LoginUser(USER, CO2));
        mvc.perform(put(BASE + "/" + id).contentType(MediaType.APPLICATION_JSON).content("{\"version\": 0, \"requestQty\": 6}"))
                .andExpect(status().isNotFound()).andExpect(jsonPath("$.code").value(4001));
    }

    @Test
    void editWithoutCreateIs403() throws Exception {
        String id = newApproval(null, "5");
        PermissionGrants.grant(owner, TENANT, CO, NOPERM, 997900, ALL_CODES[0], ALL_CODES[2], ALL_CODES[3], ALL_CODES[4]);
        is403(asNoPerm(put(BASE + "/" + id).contentType(MediaType.APPLICATION_JSON).content("{\"version\": 0, \"requestQty\": 6}")));
    }

    // ------------------------------------------------------------------ 受注行ピッカー GET /sales-order-lines

    @Test
    void salesOrderLinePickerIsCompanyScopedPagedAndFiltered() throws Exception {
        String lines = BASE + "/sales-order-lines";
        getAs(CO, lines)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(2))
                .andExpect(jsonPath("$.data.list[0].salesOrderLineId").value(String.valueOf(LINE)))
                .andExpect(jsonPath("$.data.list[0].salesOrderId").value("997031"))
                .andExpect(jsonPath("$.data.list[0].salesOrderNo").value("SO-O-71"))
                .andExpect(jsonPath("$.data.list[0].lineNo").value(10))
                .andExpect(jsonPath("$.data.list[0].materialId").value("997011"))
                .andExpect(jsonPath("$.data.list[0].materialCode").value("9970000011"))
                .andExpect(jsonPath("$.data.list[0].baseUomCode").value("PCE"))
                .andExpect(jsonPath("$.data.list[0].baseQty").value(100))
                .andExpect(jsonPath("$.data.list[0].allowedQty").value(105))
                .andExpect(jsonPath("$.data.list[0].completedQty").value(0))
                .andExpect(jsonPath("$.data.list[0].length()").value(11))
                .andExpect(jsonPath("$.data.list[1].salesOrderLineId").value(String.valueOf(LINE2)));
        getAs(CO, lines, "pageNum", "2", "pageSize", "1")
                .andExpect(jsonPath("$.data.total").value(2))
                .andExpect(jsonPath("$.data.list.length()").value(1))
                .andExpect(jsonPath("$.data.list[0].salesOrderLineId").value(String.valueOf(LINE2)));
        getAs(CO, lines, "salesOrderNo", "o-71").andExpect(jsonPath("$.data.total").value(2));
        getAs(CO, lines, "salesOrderNo", "O-72").andExpect(jsonPath("$.data.total").value(0));
        getAs(CO, lines, "material", "0000011").andExpect(jsonPath("$.data.total").value(2));
        getAs(CO, lines, "material", "不存在").andExpect(jsonPath("$.data.total").value(0));
        getAs(CO2, lines).andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].salesOrderLineId").value(String.valueOf(LINE_CO2)));
        // allowed_qty 未スナップショット・完了明細・草稿受注は対象外
        owner.update("UPDATE sal_sales_order_line SET allowed_qty = NULL WHERE id = ?", LINE2);
        getAs(CO, lines).andExpect(jsonPath("$.data.total").value(1));
        owner.update("UPDATE sal_sales_order_line SET line_status = 40 WHERE id = ?", LINE);
        getAs(CO, lines).andExpect(jsonPath("$.data.total").value(0));
    }

    @Test
    void salesOrderLinePickerSizeOver200Is400With1001FieldErrors() throws Exception {
        getAs(CO, BASE + "/sales-order-lines", "pageSize", "201")
                .andExpect(status().isBadRequest())
                .andExpect(content().json("{\"code\":1001,\"message\":\"「pageSize」不能大于「200」。\",\"msgId\":\"MSG-COM-045\","
                        + "\"data\":{\"fieldErrors\":[{\"field\":\"pageSize\",\"message\":\"「pageSize」不能大于「200」。\"}]}}",
                        JsonCompareMode.STRICT));
        getAs(CO, BASE + "/sales-order-lines", "pageSize", "200").andExpect(status().isOk())
                .andExpect(jsonPath("$.data.pageSize").value(200));
    }

    @Test
    void salesOrderLinePickerWithoutCreateIs403() throws Exception {
        PermissionGrants.grant(owner, TENANT, CO, NOPERM, 997900, ALL_CODES[0], ALL_CODES[2], ALL_CODES[3], ALL_CODES[4]);
        is403(asNoPerm(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get(BASE + "/sales-order-lines")));
    }

    @ParameterizedTest
    @ValueSource(strings = {"/sales-order-lines", ""})
    void pagingUsesPageNumPageSizeWith044And045(String path) throws Exception {
        getAs(CO, BASE + path, "pageNum", "0", "pageSize", "0")
                .andExpect(status().isBadRequest())
                .andExpect(content().json("{\"code\":1001,\"message\":\"「pageNum」必须大于 0。\",\"msgId\":\"MSG-COM-044\","
                        + "\"data\":{\"fieldErrors\":[{\"field\":\"pageNum\",\"message\":\"「pageNum」必须大于 0。\"},"
                        + "{\"field\":\"pageSize\",\"message\":\"「pageSize」必须大于 0。\"}]}}", JsonCompareMode.STRICT));
        getAs(CO, BASE + path, "pageSize", "201")
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.msgId").value("MSG-COM-045"))
                .andExpect(jsonPath("$.data.fieldErrors[0].field").value("pageSize"));
        getAs(CO, BASE + path, "pageNum", "1", "pageSize", "200").andExpect(status().isOk())
                .andExpect(jsonPath("$.data.pageNum").value(1))
                .andExpect(jsonPath("$.data.pageSize").value(200));
        // 旧パラメータ page/size は無視（既定 1/20）
        getAs(CO, BASE + path, "page", "2", "size", "1").andExpect(status().isOk())
                .andExpect(jsonPath("$.data.pageNum").value(1))
                .andExpect(jsonPath("$.data.pageSize").value(20));
    }
}
