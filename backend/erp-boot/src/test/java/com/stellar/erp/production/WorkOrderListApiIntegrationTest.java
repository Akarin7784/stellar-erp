package com.stellar.erp.production;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.List;

import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.SingleConnectionDataSource;
import org.springframework.test.json.JsonCompareMode;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders;
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
 * 工单一覧 GET /api/production/work-orders（06/91 §3.15、06/95 AC-PRD-22）。erp_app + RLS、MockMvc。
 *
 * <p>会社 81：W1〜W4、会社 82：W5（他社）。既定順（計画完成日→優先度→工单号）は W3, W2, W1, W4。</p>
 */
@DbIntegrationTest
class WorkOrderListApiIntegrationTest {

    static final long TENANT = 316L, CO = 81L, CO2 = 82L, USER = 7801L, NOPERM = 7802L, SCOPED = 7803L;
    static final long F1 = 989021, F2 = 989022, F3 = 989023, DEPT = 989041, CUST = 989031;
    static final long W1 = 989101, W2 = 989102, W3 = 989103, W4 = 989104, W5 = 989105;
    static final String URL = "/api/production/work-orders";

    @Autowired PostgreSQLContainer pg;
    @Autowired WebApplicationContext wac;

    static JdbcTemplate owner;
    MockMvc mvc;

    @BeforeEach
    void seed() {
        if (owner == null) {
            owner = OwnerJdbc.of(pg);
        }
        mvc = MockMvcBuilders.webAppContextSetup(wac).build();
        cleanup();
        owner.execute("""
            INSERT INTO mdm_material_category (id, tenant_id, company_id, category_code, category_name, category_path, category_level, is_leaf)
              VALUES (989001, 316, 81, 'L1', 'L', '/L1/', 1, TRUE), (989002, 316, 82, 'L1', 'L', '/L1/', 1, TRUE);
            INSERT INTO mdm_material (id, tenant_id, company_id, material_code, material_name, material_type, category_id, spec, base_uom_code, valuation_method, status)
              VALUES (989011, 316, 81, '9890000011', 'L 成品', 10, 989001, 's', 'PCE', 20, 1),
                     (989012, 316, 82, '9890000012', 'L 成品', 10, 989002, 's', 'PCE', 20, 1);
            INSERT INTO mdm_factory (id, tenant_id, company_id, factory_code, factory_name) VALUES
              (989021, 316, 81, 'F81A', '一厂'), (989022, 316, 81, 'F81B', '二厂'), (989023, 316, 82, 'F82', '他社厂');
            INSERT INTO sys_department (id, tenant_id, company_id, department_code, department_name)
              VALUES (989041, 316, 81, 'D030', '生产部');
            INSERT INTO mdm_customer (id, tenant_id, company_id, customer_code, customer_name, customer_type, tax_no, owner_user_id, payment_term_code, settlement_method_code)
              VALUES (989031, 316, 81, 'C989031', '甲客户', 10, '91320000000000000X', 1, 'NET30', 'TT');
            """);
        // id, company, no, type, matCode, matName, factory, dept, start, end, status, prio, soNo, customer, source, hold
        wo(W1, CO, "WO2610010001", 10, "M-A01", "螺丝", F1, DEPT, "2026-11-01", "2026-11-10", 10, 5, "SO-2610-001", CUST, 30, false);
        wo(W2, CO, "WO2610010002", 20, "M-B02", "含%特殊_字\\符", F1, null, "2026-10-25", "2026-11-05", 20, 3, null, null, 20, true);
        wo(W3, CO, "WO2611010001", 10, "M-A03", "轴承", F2, null, "2026-10-20", "2026-11-05", 30, 1, "SO-2611-009", CUST, 10, false);
        wo(W4, CO, "WO2612010001", 30, "X-900", "外壳", F2, null, "2026-11-20", "2026-12-01", 90, 9, null, null, 60, false);
        wo(W5, CO2, "WO2610010009", 10, "M-A01", "螺丝", F3, null, "2026-11-01", "2026-11-10", 10, 5, "SO-2610-001", null, 30, false);
        PermissionGrants.grant(owner, TENANT, CO, USER, 989500, "production:work-order:view");
        PermissionGrants.grant(owner, TENANT, CO2, USER, 989600, "production:work-order:view");
        PermissionGrants.grant(owner, TENANT, CO, NOPERM, 989700, "production:work-order:create");
        PermissionGrants.grant(owner, TENANT, CO, SCOPED, 989800, "production:work-order:view");
        // SCOPED：ロールのリソース別データ範囲＝工場（一厂のみ）
        owner.update("""
            INSERT INTO sys_role_data_scope (id, tenant_id, company_id, role_id, resource_code, scope_type, factory_ids, module_code)
            VALUES (989890, 316, 81, 989800, 'production:work-order', 6, '["989021"]'::jsonb, 'production')
            """);
    }

    void wo(long id, long company, String no, int type, String matCode, String matName, long factory, Long dept,
            String start, String end, int status, int prio, String soNo, Long customer, int source, boolean hold) {
        owner.update("""
            INSERT INTO prd_work_order (id, tenant_id, company_id, work_order_no, work_order_type, material_id, material_code,
                material_name, material_spec, uom_code, factory_id, department_id, order_qty, completed_qty, reported_good_qty,
                progress_rate, planned_start_date, planned_end_date, order_status, priority_no, sales_order_no, customer_id,
                source_type, is_hold, over_receipt_rate)
            VALUES (?, 316, ?, ?, ?, ?, ?, ?, 'spec', 'PCE', ?, ?, 100.5, 10, 12, 0.1200, ?::date, ?::date, ?, ?, ?, ?, ?, ?, 0.05)
            """, id, company, no, type, company == CO ? 989011L : 989012L, matCode, matName, factory, dept,
                start, end, status, prio, soNo, customer, source, hold);
    }

    @AfterEach
    void tearDown() {
        cleanup();
        LoginContext.clear();
        TenantContext.clear();
    }

    @AfterAll
    static void close() {
        if (owner != null) {
            ((SingleConnectionDataSource) owner.getDataSource()).destroy();
            owner = null;
        }
    }

    void cleanup() {
        owner.execute("""
            DELETE FROM prd_work_order WHERE tenant_id = 316;
            DELETE FROM sys_role_data_scope WHERE tenant_id = 316;
            DELETE FROM sys_user_data_scope WHERE tenant_id = 316;
            DELETE FROM sys_user_role WHERE tenant_id = 316;
            DELETE FROM sys_role_permission WHERE tenant_id = 316;
            DELETE FROM sys_menu WHERE tenant_id = 316 AND module_code = 'test';
            DELETE FROM sys_role WHERE tenant_id = 316;
            DELETE FROM mdm_customer WHERE tenant_id = 316;
            DELETE FROM sys_department WHERE tenant_id = 316;
            DELETE FROM mdm_factory WHERE tenant_id = 316;
            DELETE FROM mdm_material WHERE tenant_id = 316;
            DELETE FROM mdm_material_category WHERE tenant_id = 316;
            """);
    }

    ResultActions get(long user, long company, String... params) throws Exception {
        TenantContext.set(TENANT);
        LoginContext.set(new LoginUser(user, company));
        var req = MockMvcRequestBuilders.get(URL);
        for (int i = 0; i < params.length; i += 2) {
            req.param(params[i], params[i + 1]);
        }
        return mvc.perform(req);
    }

    ResultActions get(String... params) throws Exception {
        return get(USER, CO, params);
    }

    /** 200 で返った行の id（文字列）を順に。 */
    List<String> ids(String... params) throws Exception {
        String json = get(params).andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        List<String> ids = JsonPath.read(json, "$.data.list[*].id");
        assertThat(((Number) JsonPath.read(json, "$.data.total")).intValue()).isEqualTo(ids.size());
        return ids;
    }

    static List<String> s(long... ids) {
        return java.util.Arrays.stream(ids).mapToObj(String::valueOf).toList();
    }

    static String error(String field, String message, String msgId) {
        return "{\"code\":1001,\"message\":\"" + message + "\",\"msgId\":\"" + msgId + "\",\"data\":{\"fieldErrors\":["
                + "{\"field\":\"" + field + "\",\"message\":\"" + message + "\"}]}}";
    }

    // ------------------------------------------------------------------ 既定（条件なし）

    @Test
    void noFilterReturnsCurrentCompanyInDefaultOrderAsPageResult() throws Exception {
        get().andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.total").value(4))
                .andExpect(jsonPath("$.data.pageNum").value(1))
                .andExpect(jsonPath("$.data.pageSize").value(20))
                .andExpect(jsonPath("$.data.pages").value(1))
                .andExpect(jsonPath("$.data.list[*].id").value(org.hamcrest.Matchers.contains(
                        s(W3, W2, W1, W4).toArray())));
        // 行項目（91 §3.15）：28 項目、数量は文字列、状態は値のみ、欠品フラグ・原価なし
        get().andExpect(jsonPath("$.data.list[2].length()").value(28))
                .andExpect(jsonPath("$.data.list[2].workOrderNo").value("WO2610010001"))
                .andExpect(jsonPath("$.data.list[2].workOrderType").value(10))
                .andExpect(jsonPath("$.data.list[2].materialId").value("989011"))
                .andExpect(jsonPath("$.data.list[2].materialCode").value("M-A01"))
                .andExpect(jsonPath("$.data.list[2].materialName").value("螺丝"))
                .andExpect(jsonPath("$.data.list[2].materialSpec").value("spec"))
                .andExpect(jsonPath("$.data.list[2].uomCode").value("PCE"))
                .andExpect(jsonPath("$.data.list[2].orderQty").value("100.5"))
                .andExpect(jsonPath("$.data.list[2].completedQty").value("10"))
                .andExpect(jsonPath("$.data.list[2].reportedGoodQty").value("12"))
                .andExpect(jsonPath("$.data.list[2].progressRate").value("0.12"))
                .andExpect(jsonPath("$.data.list[2].plannedStartDate").value("2026-11-01"))
                .andExpect(jsonPath("$.data.list[2].plannedEndDate").value("2026-11-10"))
                .andExpect(jsonPath("$.data.list[2].orderStatus").value(10))
                .andExpect(jsonPath("$.data.list[2].priorityNo").value(5))
                .andExpect(jsonPath("$.data.list[2].sourceType").value(30))
                .andExpect(jsonPath("$.data.list[2].isHold").value(false))
                .andExpect(jsonPath("$.data.list[2].factoryId").value(String.valueOf(F1)))
                .andExpect(jsonPath("$.data.list[2].factoryCode").value("F81A"))
                .andExpect(jsonPath("$.data.list[2].factoryName").value("一厂"))
                .andExpect(jsonPath("$.data.list[2].departmentId").value(String.valueOf(DEPT)))
                .andExpect(jsonPath("$.data.list[2].departmentName").value("生产部"))
                .andExpect(jsonPath("$.data.list[2].salesOrderNo").value("SO-2610-001"))
                .andExpect(jsonPath("$.data.list[2].customerId").value(String.valueOf(CUST)))
                .andExpect(jsonPath("$.data.list[2].customerName").value("甲客户"))
                .andExpect(jsonPath("$.data.list[2].version").value(0))
                .andExpect(jsonPath("$.data.list[1].departmentId").doesNotExist())
                .andExpect(jsonPath("$.data.list[2].orderStatusName").doesNotExist())
                .andExpect(jsonPath("$.data.list[2].standardCost").doesNotExist());
    }

    @Test
    void crossCompanyIsolation() throws Exception {
        assertThat(ids()).doesNotContain(String.valueOf(W5));
        TenantContext.set(TENANT);
        assertThat(JsonPath.<List<String>>read(get(USER, CO2).andExpect(status().isOk()).andReturn().getResponse()
                .getContentAsString(), "$.data.list[*].id")).containsExactly(String.valueOf(W5));
        // 他社の工場・受注番号を指定しても自社の行のみ（0 件）
        assertThat(ids("factoryId", String.valueOf(F3))).isEmpty();
        assertThat(ids("workOrderNo", "WO2610010009")).isEmpty();
    }

    // ------------------------------------------------------------------ 各検索条件

    @Test
    void eachFilter() throws Exception {
        assertThat(ids("workOrderNo", "WO2610")).containsExactly(s(W2, W1).toArray(String[]::new));
        assertThat(ids("workOrderNo", "2610")).isEmpty();                 // 前方一致（部分一致ではない）
        assertThat(ids("material", "m-a")).containsExactly(s(W3, W1).toArray(String[]::new));  // コード
        assertThat(ids("material", "轴")).containsExactly(String.valueOf(W3));                  // 名称
        assertThat(ids("workOrderType", "20")).containsExactly(String.valueOf(W2));
        assertThat(ids("status", "10,20")).containsExactly(s(W2, W1).toArray(String[]::new));
        assertThat(ids("status", "10", "status", "90")).containsExactly(s(W1, W4).toArray(String[]::new));
        assertThat(ids("plannedStartDateFrom", "2026-10-25", "plannedStartDateTo", "2026-11-01"))
                .containsExactly(s(W2, W1).toArray(String[]::new));                             // 両端含む
        assertThat(ids("plannedEndDateFrom", "2026-11-06", "plannedEndDateTo", "2026-12-01"))
                .containsExactly(s(W1, W4).toArray(String[]::new));
        assertThat(ids("plannedEndDateTo", "2026-11-05")).containsExactly(s(W3, W2).toArray(String[]::new));
        assertThat(ids("factoryId", String.valueOf(F2))).containsExactly(s(W3, W4).toArray(String[]::new));
        assertThat(ids("departmentId", String.valueOf(DEPT))).containsExactly(String.valueOf(W1));
        assertThat(ids("salesOrderNo", "2611")).containsExactly(String.valueOf(W3));
        assertThat(ids("salesOrderNo", "so-26")).containsExactly(s(W3, W1).toArray(String[]::new));
        assertThat(ids("customerId", String.valueOf(CUST))).containsExactly(s(W3, W1).toArray(String[]::new));
        assertThat(ids("priorityNo", "9")).containsExactly(String.valueOf(W4));
        assertThat(ids("sourceType", "60")).containsExactly(String.valueOf(W4));
        assertThat(ids("isHold", "true")).containsExactly(String.valueOf(W2));
        assertThat(ids("isHold", "false")).containsExactly(s(W3, W1, W4).toArray(String[]::new));
        // AND 結合・空値は絞り込まない
        assertThat(ids("material", "M-A", "status", "30")).containsExactly(String.valueOf(W3));
        assertThat(ids("workOrderNo", "", "material", "  ", "status", "")).hasSize(4);
    }

    // ------------------------------------------------------------------ LIKE エスケープ（AC-PRD-22）

    @Test
    void likeWildcardsInInputAreLiterals() throws Exception {
        assertThat(ids("workOrderNo", "WO2610%")).isEmpty();
        assertThat(ids("workOrderNo", "WO2610_1")).isEmpty();
        assertThat(ids("material", "%")).containsExactly(String.valueOf(W2));
        assertThat(ids("material", "_")).containsExactly(String.valueOf(W2));
        assertThat(ids("material", "\\")).containsExactly(String.valueOf(W2));
        assertThat(ids("material", "%特殊_")).containsExactly(String.valueOf(W2));
        assertThat(ids("salesOrderNo", "%")).isEmpty();
        assertThat(ids("salesOrderNo", "_")).isEmpty();
    }

    // ------------------------------------------------------------------ ソート

    @Test
    void sortByAllowedKeys() throws Exception {
        assertThat(ids("sort", "workOrderNo,desc")).containsExactly(s(W4, W3, W2, W1).toArray(String[]::new));
        assertThat(ids("sort", "priorityNo")).containsExactly(s(W3, W2, W1, W4).toArray(String[]::new));
        assertThat(ids("sort", "orderStatus,desc")).containsExactly(s(W4, W3, W2, W1).toArray(String[]::new));
        assertThat(ids("sort", "plannedStartDate,asc")).containsExactly(s(W3, W2, W1, W4).toArray(String[]::new));
        assertThat(ids("sort", "plannedEndDate,desc,workOrderNo,desc"))
                .containsExactly(s(W4, W1, W3, W2).toArray(String[]::new));
        assertThat(ids("sort", "plannedEndDate,asc", "sort", "priorityNo,desc"))
                .containsExactly(s(W2, W3, W1, W4).toArray(String[]::new));
        assertThat(ids("sort", "createdAt,desc")).hasSize(4);
    }

    @ParameterizedTest
    @CsvSource(delimiter = '|', value = {"material_code", "factoryName", "id", "workOrderNo,sideways", "planned_end_date;DROP"})
    void sortOutsideAllowedKeysIs400(String sort) throws Exception {
        get("sort", sort).andExpect(status().isBadRequest())
                .andExpect(content().json(error("sort", "所选数据不存在或已失效，请重新选择。", "MSG-COM-049"),
                        JsonCompareMode.STRICT));
    }

    // ------------------------------------------------------------------ 値域・形式

    @ParameterizedTest
    @CsvSource(delimiter = '|', value = {"status|95", "status|10,abc", "status|0", "workOrderType|50", "sourceType|80"})
    void invalidCodesAre400(String field, String value) throws Exception {
        get(field, value).andExpect(status().isBadRequest())
                .andExpect(content().json(error(field, "所选数据不存在或已失效，请重新选择。", "MSG-COM-049"),
                        JsonCompareMode.STRICT));
    }

    @Test
    void otherFormatErrorsAre400() throws Exception {
        get("priorityNo", "10").andExpect(status().isBadRequest())
                .andExpect(content().json(error("priorityNo", "「priorityNo」必须在 1 到 9 之间。", "MSG-COM-089"),
                        JsonCompareMode.STRICT));
        get("plannedEndDateFrom", "2026/11/01").andExpect(status().isBadRequest())
                .andExpect(content().json(error("plannedEndDateFrom", "「plannedEndDateFrom」的日期格式不正确。", "MSG-COM-043"),
                        JsonCompareMode.STRICT));
        get("factoryId", "abc").andExpect(status().isBadRequest())
                .andExpect(content().json(error("factoryId", "「factoryId」的格式不正确。", "MSG-COM-088"),
                        JsonCompareMode.STRICT));
        get("isHold", "yes").andExpect(status().isBadRequest())
                .andExpect(content().json(error("isHold", "「isHold」的格式不正确。", "MSG-COM-088"),
                        JsonCompareMode.STRICT));
    }

    @ParameterizedTest
    @CsvSource(delimiter = '|', value = {"plannedEndDate", "plannedStartDate"})
    void dateFromAfterToIs046(String prefix) throws Exception {
        get(prefix + "From", "2026-11-11", prefix + "To", "2026-11-10").andExpect(status().isBadRequest())
                .andExpect(content().json(error(prefix + "From", "开始日期不能晚于结束日期。", "MSG-COM-046"),
                        JsonCompareMode.STRICT));
        get(prefix + "From", "2026-11-10", prefix + "To", "2026-11-10").andExpect(status().isOk());
    }

    // ------------------------------------------------------------------ ページング

    @Test
    void pagingLimits() throws Exception {
        get("pageSize", "201").andExpect(status().isBadRequest())
                .andExpect(content().json(error("pageSize", "「pageSize」不能大于「200」。", "MSG-COM-045"),
                        JsonCompareMode.STRICT));
        get("pageNum", "0").andExpect(status().isBadRequest())
                .andExpect(content().json(error("pageNum", "「pageNum」必须大于 0。", "MSG-COM-044"),
                        JsonCompareMode.STRICT));
        get("pageSize", "0").andExpect(status().isBadRequest())
                .andExpect(content().json(error("pageSize", "「pageSize」必须大于 0。", "MSG-COM-044"),
                        JsonCompareMode.STRICT));
        get("pageNum", "x").andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.msgId").value("MSG-COM-088"));
        get("pageSize", "200").andExpect(status().isOk()).andExpect(jsonPath("$.data.pageSize").value(200));
        get("pageNum", "2", "pageSize", "3").andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(4))
                .andExpect(jsonPath("$.data.pageNum").value(2))
                .andExpect(jsonPath("$.data.pageSize").value(3))
                .andExpect(jsonPath("$.data.pages").value(2))
                .andExpect(jsonPath("$.data.list[*].id").value(org.hamcrest.Matchers.contains(String.valueOf(W4))));
        get("pageNum", "3", "pageSize", "3").andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(4))
                .andExpect(jsonPath("$.data.list.length()").value(0));
    }

    // ------------------------------------------------------------------ 権限・データ範囲

    @Test
    void withoutViewPermissionIs403With3001() throws Exception {
        get(NOPERM, CO).andExpect(status().isForbidden())
                .andExpect(jsonPath("$.code").value(3001))
                .andExpect(jsonPath("$.msgId").value("MSG-COM-030"));
        // 他社でのみ付与：会社 82 の view は会社 81 では無効
        PermissionGrants.grant(owner, TENANT, CO2, NOPERM, 989900, "production:work-order:view");
        get(NOPERM, CO).andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value(3001));
    }

    @Test
    void factoryDataScope() throws Exception {
        // 範囲指定なし → 範囲内工場（一厂）の行のみ
        String json = get(SCOPED, CO).andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        assertThat(JsonPath.<List<String>>read(json, "$.data.list[*].id")).containsExactly(s(W2, W1).toArray(String[]::new));
        assertThat(((Number) JsonPath.read(json, "$.data.total")).intValue()).isEqualTo(2);
        // 範囲外工場の指定 → 403 / 3002
        get(SCOPED, CO, "factoryId", String.valueOf(F2)).andExpect(status().isForbidden())
                .andExpect(content().json("{\"code\":3002,\"message\":\"您没有查看该数据的权限。\",\"msgId\":\"MSG-COM-031\"}"));
        get(SCOPED, CO, "factoryId", String.valueOf(F1)).andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(2));
        // 範囲外条件の検証より入力検証が先（400）
        get(SCOPED, CO, "factoryId", String.valueOf(F2), "pageSize", "201").andExpect(status().isBadRequest());
        // ユーザ個別が工場型ならロールより優先（ロールは見ない）：二厂のみ
        owner.update("""
            INSERT INTO sys_user_data_scope (id, tenant_id, company_id, user_id, resource_code, scope_type, factory_ids, reason)
            VALUES (989891, 316, 81, ?, 'production:work-order', 6, '["989022"]'::jsonb, 'test')
            """, SCOPED);
        get(SCOPED, CO, "factoryId", String.valueOf(F2)).andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(2));
        get(SCOPED, CO, "factoryId", String.valueOf(F1)).andExpect(status().isForbidden())
                .andExpect(jsonPath("$.code").value(3002));
        // ロール側が全社（1）でもユーザ個別の工場で制限
        owner.update("UPDATE sys_role_data_scope SET scope_type = 1, factory_ids = NULL WHERE id = 989890");
        get(SCOPED, CO).andExpect(jsonPath("$.data.total").value(2));
        get(SCOPED, CO, "factoryId", String.valueOf(F1)).andExpect(status().isForbidden());
    }

    @Test
    void nonFactoryUserScopeFallsBackToRoleFactoryScope() throws Exception {
        // ユーザ個別が工場型でない（全社 1）→ 工場次元はロール（一厂のみ）にフォールバック、全開にしない
        owner.update("""
            INSERT INTO sys_user_data_scope (id, tenant_id, company_id, user_id, resource_code, scope_type, reason)
            VALUES (989892, 316, 81, ?, 'production:work-order', 1, 'test')
            """, SCOPED);
        String json = get(SCOPED, CO).andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        assertThat(JsonPath.<List<String>>read(json, "$.data.list[*].id")).containsExactly(s(W2, W1).toArray(String[]::new));
        get(SCOPED, CO, "factoryId", String.valueOf(F2)).andExpect(status().isForbidden())
                .andExpect(jsonPath("$.code").value(3002));
        // 自定义（5）でも factoryIds なしなら工場型ではない → 同じくロールにフォールバック
        owner.update("UPDATE sys_user_data_scope SET scope_type = 5, custom_rule = '{\"deptIds\":[989041]}'::jsonb WHERE id = 989892");
        get(SCOPED, CO).andExpect(jsonPath("$.data.total").value(2));
        get(SCOPED, CO, "factoryId", String.valueOf(F2)).andExpect(status().isForbidden());
    }

    @Test
    void nonFactoryUserScopeFallsBackToUnionOfRoles() throws Exception {
        owner.update("""
            INSERT INTO sys_user_data_scope (id, tenant_id, company_id, user_id, resource_code, scope_type, reason)
            VALUES (989893, 316, 81, ?, '*', 4, 'test')
            """, SCOPED);
        // 2 つ目のロール（二厂）→ 一厂 ∪ 二厂
        PermissionGrants.grant(owner, TENANT, CO, SCOPED, 989950, "production:work-order:view");
        owner.update("""
            INSERT INTO sys_role_data_scope (id, tenant_id, company_id, role_id, resource_code, scope_type, factory_ids, module_code)
            VALUES (989991, 316, 81, 989950, 'production:work-order', 6, '["989022"]'::jsonb, 'production')
            """);
        get(SCOPED, CO).andExpect(jsonPath("$.data.total").value(4));
        get(SCOPED, CO, "factoryId", String.valueOf(F2)).andExpect(status().isOk());
        // いずれかのロールが工場無制限（ロール既定 全社 1）なら無制限
        owner.update("DELETE FROM sys_role_data_scope WHERE id = 989991");
        owner.update("UPDATE sys_role SET data_scope_type = 1 WHERE id = 989950");
        get(SCOPED, CO).andExpect(jsonPath("$.data.total").value(4));
        // 無制限ロールが外れると一厂のみに戻る
        owner.update("UPDATE sys_role SET data_scope_type = 6 WHERE id = 989950");
        get(SCOPED, CO).andExpect(jsonPath("$.data.total").value(2));
    }

    @Test
    void factoryScopeIsUnionAcrossRolesAndCustomRule() throws Exception {
        // 2 つ目のロール：自定义（custom_rule.factoryIds＝二厂）→ 一厂 ∪ 二厂
        PermissionGrants.grant(owner, TENANT, CO, SCOPED, 989950, "production:work-order:view");
        owner.update("""
            INSERT INTO sys_role_data_scope (id, tenant_id, company_id, role_id, resource_code, scope_type, custom_rule, module_code)
            VALUES (989990, 316, 81, 989950, '*', 5, '{"factoryIds":[989022]}'::jsonb, '*')
            """);
        get(SCOPED, CO).andExpect(jsonPath("$.data.total").value(4));
        get(SCOPED, CO, "factoryId", String.valueOf(F2)).andExpect(status().isOk());
        // ロール既定が全社（1）のロールが加わると無制限
        owner.update("UPDATE sys_role_data_scope SET scope_type = 6, factory_ids = '[]'::jsonb, custom_rule = NULL WHERE id = 989990");
        get(SCOPED, CO).andExpect(jsonPath("$.data.total").value(2));
        owner.update("DELETE FROM sys_role_data_scope WHERE id = 989990");
        owner.update("UPDATE sys_role SET data_scope_type = 1 WHERE id = 989950");
        get(SCOPED, CO).andExpect(jsonPath("$.data.total").value(4));
    }

    // ------------------------------------------------------------------ GET /api/mdm/factories（CALC-02a で絞る）

    List<String> factoryCodes(long user, String... params) throws Exception {
        TenantContext.set(TENANT);
        LoginContext.set(new LoginUser(user, CO));
        var req = MockMvcRequestBuilders.get("/api/mdm/factories");
        for (int i = 0; i < params.length; i += 2) {
            req.param(params[i], params[i + 1]);
        }
        String json = mvc.perform(req).andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        return JsonPath.read(json, "$.data[*].factoryCode");
    }

    @Test
    void factoryLookupIsFilteredByFactoryDataScope() throws Exception {
        // 工場無制限ロール → 当前公司の全工場（他社工場は出ない）
        assertThat(factoryCodes(USER, "resource", "production:work-order")).containsExactly("F81A", "F81B");
        // resource 指定なし → 絞らない（当前公司の全工場）
        assertThat(factoryCodes(SCOPED)).containsExactly("F81A", "F81B");
        // ロールが工場（一厂）に限定 → 一厂のみ
        assertThat(factoryCodes(SCOPED, "resource", "production:work-order")).containsExactly("F81A");
        // ユーザ個別が工場型でない → ロールへフォールバック（全開にしない）
        owner.update("""
            INSERT INTO sys_user_data_scope (id, tenant_id, company_id, user_id, resource_code, scope_type, reason)
            VALUES (989894, 316, 81, ?, 'production:work-order', 1, 'test')
            """, SCOPED);
        assertThat(factoryCodes(SCOPED, "resource", "production:work-order")).containsExactly("F81A");
        // ユーザ個別が工場型 → 優先（ロールは見ない）：二厂のみ
        owner.update("UPDATE sys_user_data_scope SET scope_type = 6, factory_ids = '[\"989022\"]'::jsonb WHERE id = 989894");
        assertThat(factoryCodes(SCOPED, "resource", "production:work-order")).containsExactly("F81B");
        // ユーザ個別の工場範囲が空 → 空
        owner.update("UPDATE sys_user_data_scope SET factory_ids = '[]'::jsonb WHERE id = 989894");
        assertThat(factoryCodes(SCOPED, "resource", "production:work-order")).isEmpty();
        assertThat(factoryCodes(SCOPED)).containsExactly("F81A", "F81B");
    }

    @Test
    void factoryLookupRejectsMalformedResource() throws Exception {
        TenantContext.set(TENANT);
        LoginContext.set(new LoginUser(SCOPED, CO));
        mvc.perform(MockMvcRequestBuilders.get("/api/mdm/factories").param("resource", "work-order"))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.code").value(1001));
    }

    @Test
    void factoryLookupUnionsRolesAndIsEmptyWithoutRoles() throws Exception {
        // 2 つ目のロール（二厂）→ 和集合
        PermissionGrants.grant(owner, TENANT, CO, SCOPED, 989950, "production:work-order:view");
        owner.update("""
            INSERT INTO sys_role_data_scope (id, tenant_id, company_id, role_id, resource_code, scope_type, factory_ids, module_code)
            VALUES (989992, 316, 81, 989950, 'production:work-order', 6, '["989022"]'::jsonb, 'production')
            """);
        assertThat(factoryCodes(SCOPED, "resource", "production:work-order")).containsExactly("F81A", "F81B");
        // 有効ロールなし → 空（単一工場の自動選択も起きない）。resource なしなら全工場
        assertThat(factoryCodes(7809L, "resource", "production:work-order")).isEmpty();
        assertThat(factoryCodes(7809L)).containsExactly("F81A", "F81B");
    }
}
