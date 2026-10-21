package com.stellar.erp.system;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.Map;

import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.SingleConnectionDataSource;
import org.springframework.test.json.JsonCompareMode;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;
import org.testcontainers.postgresql.PostgreSQLContainer;

import com.jayway.jsonpath.JsonPath;
import com.stellar.erp.common.LoginContext;
import com.stellar.erp.common.LoginContext.LoginUser;
import com.stellar.erp.common.TenantContext;
import com.stellar.erp.support.CompanyInitInjector;
import com.stellar.erp.support.DbIntegrationTest;
import com.stellar.erp.support.OwnerJdbc;
import com.stellar.erp.support.PermissionGrants;

/** POST /api/system/companies（01-system 91 #47a / 03 PRC-SYS-014-03）。 */
@DbIntegrationTest
class CompanyApiIntegrationTest {

    static final long TENANT = 314L, CO = 91L, USER = 7601L, NOPERM = 7602L;
    static final String URL = "/api/system/companies";
    /** GB 32100-2015 校验位が正しい 18 桁（CHK-SYS-014-01）。 */
    static final String USCC_A = "91320400MA1XXXXX0D", USCC_B = "91320400MA1XXXXX1G";

    @Autowired PostgreSQLContainer pg;
    @Autowired WebApplicationContext wac;

    static JdbcTemplate owner;
    MockMvc mvc;

    @BeforeEach
    void setUp() {
        if (owner == null) {
            owner = OwnerJdbc.of(pg);
        }
        cleanup();
        mvc = MockMvcBuilders.webAppContextSetup(wac).build();
        PermissionGrants.grant(owner, TENANT, CO, USER, 998700, "system:company:create");
        PermissionGrants.grant(owner, TENANT, CO, NOPERM, 998800, "system:company:view");
    }

    @AfterEach
    void tearDown() {
        CompanyInitInjector.reset();
        cleanup();
        LoginContext.clear();
        TenantContext.clear();
    }

    void cleanup() {
        owner.execute("""
                DELETE FROM sys_user_role WHERE tenant_id = %1$d;
                DELETE FROM sys_role_permission WHERE tenant_id = %1$d;
                DELETE FROM sys_role WHERE tenant_id = %1$d;
                DELETE FROM sys_menu WHERE tenant_id = %1$d AND module_code = 'test';
                DELETE FROM sys_param WHERE tenant_id = %1$d;
                DELETE FROM sys_company WHERE tenant_id = %1$d;
                DELETE FROM sys_audit_log WHERE tenant_id = %1$d;
                DELETE FROM sys_user WHERE tenant_id = %1$d;
                """.formatted(TENANT));
    }

    @AfterAll
    static void close() {
        if (owner != null) {
            ((SingleConnectionDataSource) owner.getDataSource()).destroy();
            owner = null;
        }
    }

    ResultActions create(long user, String body) throws Exception {
        TenantContext.set(TENANT);
        LoginContext.set(new LoginUser(user, CO));
        return mvc.perform(post(URL).contentType(MediaType.APPLICATION_JSON).content(body));
    }

    static String body(String code, String uscc) {
        return "{\"companyCode\":\"" + code + "\",\"companyName\":\"测试公司 " + code + "\",\"unifiedSocialCreditCode\":\""
                + uscc + "\"}";
    }

    long companies() {
        return owner.queryForObject("SELECT count(*) FROM sys_company WHERE tenant_id = ?", Long.class, TENANT);
    }

    @Test
    void createsCompanyWithParamsAndSystemAdminInOneTransaction() throws Exception {
        String json = create(USER, body("NEWCO1", USCC_A))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.id").isString())
                .andExpect(jsonPath("$.data.companyCode").value("NEWCO1"))
                .andReturn().getResponse().getContentAsString();
        Map<String, Object> top = JsonPath.read(json, "$");
        assertThat(top.keySet()).containsExactlyInAnyOrder("code", "message", "data", "msgId");
        long id = Long.parseLong(JsonPath.read(json, "$.data.id"));
        Map<String, Object> row = owner.queryForMap(
                "SELECT company_id, tax_payer_type, fiscal_year_start_month, base_currency_code FROM sys_company WHERE id = ?", id);
        assertThat(((Number) row.get("company_id")).longValue()).isEqualTo(id);
        assertThat(((Number) row.get("tax_payer_type")).intValue()).isEqualTo(1);
        assertThat(((Number) row.get("fiscal_year_start_month")).intValue()).isEqualTo(1);
        assertThat(row.get("base_currency_code")).isEqualTo("CNY");
        assertThat(owner.queryForList("SELECT param_key || '=' || param_value FROM sys_param WHERE tenant_id = ? AND company_id = ? ORDER BY 1",
                String.class, TENANT, id))
                .containsExactly("prd.completion_over_rate=0.05", "prd.overproduction_max_rate=1.0000");
        Long role = owner.queryForObject("SELECT id FROM sys_role WHERE tenant_id = ? AND company_id = ? AND role_code = 'SYSTEM_ADMIN'",
                Long.class, TENANT, id);
        int menusWithCode = owner.queryForObject(
                "SELECT count(*) FROM sys_menu WHERE tenant_id = ? AND deleted = FALSE AND permission_code IS NOT NULL", Integer.class, TENANT);
        assertThat(menusWithCode).isPositive();
        assertThat(owner.queryForObject("SELECT count(*) FROM sys_role_permission WHERE role_id = ?", Integer.class, role))
                .isEqualTo(menusWithCode);
    }

    static final String DUP = "{\"code\":10035,\"message\":\"公司代码「%s」或统一社会信用代码已存在，请使用其他代码。\",\"data\":null,\"msgId\":\"MSG-SYS-093\"}";

    @Test
    void duplicateCompanyCodeIs422And10035() throws Exception {
        create(USER, body("DUPCO", USCC_A)).andExpect(status().isCreated());
        create(USER, body("DUPCO", USCC_B))
                .andExpect(status().isUnprocessableContent())
                .andExpect(content().json(DUP.formatted("DUPCO"), JsonCompareMode.STRICT));
        assertThat(companies()).isEqualTo(1);
    }

    @Test
    void duplicateCreditCodeIs422And10035() throws Exception {
        create(USER, body("CO1", USCC_A)).andExpect(status().isCreated());
        create(USER, body("CO2", USCC_A))
                .andExpect(status().isUnprocessableContent())
                .andExpect(content().json(DUP.formatted("CO2"), JsonCompareMode.STRICT));
        assertThat(companies()).isEqualTo(1);
    }

    @Test
    void otherUniqueViolationIsNot10035() {
        org.springframework.dao.DataIntegrityViolationException other = new org.springframework.dao.DataIntegrityViolationException(
                "x", new java.sql.SQLException("ERROR: duplicate key value violates unique constraint \"uk_sys_param_key\"", "23505"));
        assertThat(com.stellar.erp.system.company.CompanyService.isCompanyDuplicate(other)).isFalse();
        org.springframework.dao.DataIntegrityViolationException mine = new org.springframework.dao.DataIntegrityViolationException(
                "x", new java.sql.SQLException("ERROR: duplicate key value violates unique constraint \"uk_sys_company_credit\"", "23505"));
        assertThat(com.stellar.erp.system.company.CompanyService.isCompanyDuplicate(mine)).isTrue();
    }

    @Test
    void withoutCreatePermissionIs403() throws Exception {
        create(NOPERM, body("NOPERM", USCC_A))
                .andExpect(status().isForbidden())
                .andExpect(content().json("{\"code\":3001,\"message\":\"您没有执行该操作的权限，请联系管理员。\",\"data\":null,\"msgId\":\"MSG-COM-030\"}",
                        JsonCompareMode.STRICT));
        assertThat(companies()).isZero();
    }

    @Test
    void companyIdAndTenantIdInBodyAreIgnored() throws Exception {
        String json = create(USER, "{\"companyId\":\"12345\",\"tenantId\":\"999\",\"id\":\"777\",\"companyCode\":\"IGN\","
                + "\"companyName\":\"忽略\",\"unifiedSocialCreditCode\":\"" + USCC_A + "\"}")
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        long id = Long.parseLong(JsonPath.read(json, "$.data.id"));
        assertThat(id).isNotIn(12345L, 777L);
        Map<String, Object> row = owner.queryForMap("SELECT tenant_id, company_id FROM sys_company WHERE id = ?", id);
        assertThat(((Number) row.get("tenant_id")).longValue()).isEqualTo(TENANT);
        assertThat(((Number) row.get("company_id")).longValue()).isEqualTo(id);
    }

    @Test
    void initFailureRollsBackCompany() throws Exception {
        // 同一 TX 内で app.tenant_id を別値にし、sys_init_company の租户一致チェックで RAISE させる
        CompanyInitInjector.action = (jdbc, id) ->
                jdbc.sql("SELECT set_config('app.tenant_id', '999999', true)").query((rs, i) -> 1).list();
        create(USER, body("ROLLBK", USCC_A)).andExpect(status().isInternalServerError())
                .andExpect(jsonPath("$.code").value(5000));
        assertThat(companies()).isZero();
        assertThat(owner.queryForObject("SELECT count(*) FROM sys_param WHERE tenant_id = ?", Integer.class, TENANT)).isZero();
        assertThat(owner.queryForObject("SELECT count(*) FROM sys_role WHERE tenant_id = ? AND role_code = 'SYSTEM_ADMIN'",
                Integer.class, TENANT)).isZero();
    }

    @Test
    void validationIs400With1001FieldErrors() throws Exception {
        create(USER, "{\"companyCode\":\"BAD-CODE\",\"unifiedSocialCreditCode\":\"123\",\"fiscalYearStartMonth\":13}")
                .andExpect(status().isBadRequest())
                .andExpect(content().json("""
                        {"code":1001,"message":"「公司代码」只能输入半角英数字。","msgId":"MSG-COM-087","data":{"fieldErrors":[
                          {"field":"companyCode","message":"「公司代码」只能输入半角英数字。"},
                          {"field":"companyName","message":"请输入必填项「公司名称」。"},
                          {"field":"unifiedSocialCreditCode","message":"「统一社会信用代码」的格式不正确。"},
                          {"field":"fiscalYearStartMonth","message":"「会计年度起始月」必须在 1 到 12 之间。"}]}}
                        """, JsonCompareMode.STRICT));
        assertThat(companies()).isZero();
    }

    // ------------------------------------------------------------------ CHK-SYS-014-01/04/05/06（03:180-183）

    static String one(String field, String message, String msgId) {
        return "{\"code\":1001,\"message\":\"" + message + "\",\"msgId\":\"" + msgId + "\",\"data\":{\"fieldErrors\":["
                + "{\"field\":\"" + field + "\",\"message\":\"" + message + "\"}]}}";
    }

    String withField(String extra) {
        return "{\"companyCode\":\"VC1\",\"companyName\":\"校验\",\"unifiedSocialCreditCode\":\"" + USCC_A + "\"" + extra + "}";
    }

    @org.junit.jupiter.params.ParameterizedTest
    @org.junit.jupiter.params.provider.ValueSource(strings = {"91350100M000100Y43", "91110000600037341L"})
    void validCheckDigitIsAccepted(String uscc) throws Exception {
        create(USER, body("OK" + uscc.substring(15), uscc)).andExpect(status().isCreated());
        assertThat(companies()).isEqualTo(1);
    }

    @org.junit.jupiter.params.ParameterizedTest
    @org.junit.jupiter.params.provider.ValueSource(strings = {
            "91350100M000100Y44",  // 校验位違い
            "91320400MA1XXXXX0A",  // 校验位違い
            "91350100M000100Y4",   // 17 桁
            "91350100m000100Y43",  // 小文字
            "91350100I000100Y43"   // 使用不可文字
    })
    void invalidUsccIs088(String uscc) throws Exception {
        create(USER, body("NG1", uscc))
                .andExpect(status().isBadRequest())
                .andExpect(content().json(one("unifiedSocialCreditCode", "「统一社会信用代码」的格式不正确。", "MSG-COM-088"),
                        JsonCompareMode.STRICT));
        assertThat(companies()).isZero();
    }

    @Test
    void usccOver18Is041() throws Exception {
        create(USER, body("NG2", "91350100M000100Y430"))
                .andExpect(status().isBadRequest())
                .andExpect(content().json(one("unifiedSocialCreditCode", "「统一社会信用代码」不能超过 18 个字符。", "MSG-COM-041"),
                        JsonCompareMode.STRICT));
    }

    @Test
    void usccMissingIs040() throws Exception {
        create(USER, "{\"companyCode\":\"NG3\",\"companyName\":\"n\"}")
                .andExpect(status().isBadRequest())
                .andExpect(content().json(one("unifiedSocialCreditCode", "请输入必填项「统一社会信用代码」。", "MSG-COM-040"),
                        JsonCompareMode.STRICT));
    }

    @org.junit.jupiter.params.ParameterizedTest
    @org.junit.jupiter.params.provider.ValueSource(ints = {0, 3})
    void taxPayerTypeOutOfRangeIs049(int v) throws Exception {
        create(USER, withField(",\"taxPayerType\":" + v))
                .andExpect(status().isBadRequest())
                .andExpect(content().json(one("taxPayerType", "所选数据不存在或已失效，请重新选择。", "MSG-COM-049"),
                        JsonCompareMode.STRICT));
    }

    @org.junit.jupiter.params.ParameterizedTest
    @org.junit.jupiter.params.provider.ValueSource(ints = {0, 13})
    void fiscalYearStartMonthOutOfRangeIs089(int v) throws Exception {
        create(USER, withField(",\"fiscalYearStartMonth\":" + v))
                .andExpect(status().isBadRequest())
                .andExpect(content().json(one("fiscalYearStartMonth", "「会计年度起始月」必须在 1 到 12 之间。", "MSG-COM-089"),
                        JsonCompareMode.STRICT));
    }

    @org.junit.jupiter.params.ParameterizedTest
    @org.junit.jupiter.params.provider.ValueSource(strings = {"cny", "CN", "CNYY", "C1Y"})
    void baseCurrencyCodeInvalidIs088(String v) throws Exception {
        create(USER, withField(",\"baseCurrencyCode\":\"" + v + "\""))
                .andExpect(status().isBadRequest())
                .andExpect(content().json(one("baseCurrencyCode", "「记账本位币」的格式不正确。", "MSG-COM-088"),
                        JsonCompareMode.STRICT));
    }

    @Test
    void boundaryValuesAreAccepted() throws Exception {
        create(USER, "{\"companyCode\":\"BND\",\"companyName\":\"b\",\"unifiedSocialCreditCode\":\"" + USCC_A
                + "\",\"taxPayerType\":2,\"fiscalYearStartMonth\":12,\"baseCurrencyCode\":\"USD\"}")
                .andExpect(status().isCreated());
    }

    // ------------------------------------------------------------------ 監査ログ（PRC-SYS-014-03 手順 4）

    @Test
    void creationWritesAuditLogInSameTransaction() throws Exception {
        owner.update("""
                INSERT INTO sys_user (id, tenant_id, company_id, user_code, username, real_name, nickname, password_hash)
                VALUES (?, ?, ?, 'E007601', 'admin7601', '管理员', '管理员', 'x')
                """, USER, TENANT, CO);
        String json = create(USER, body("AUD1", USCC_A)).andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        long id = Long.parseLong(JsonPath.read(json, "$.data.id"));
        Map<String, Object> a = owner.queryForMap("""
                SELECT tenant_id, company_id, user_id, username, operation_type, module_code, resource_code, resource_id,
                       resource_no, result, after_data::text AS after
                  FROM sys_audit_log WHERE tenant_id = ? AND resource_code = 'company' AND resource_id = ?
                """, TENANT, String.valueOf(id));
        assertThat(((Number) a.get("tenant_id")).longValue()).isEqualTo(TENANT);
        assertThat(((Number) a.get("company_id")).longValue()).isEqualTo(CO);
        assertThat(((Number) a.get("user_id")).longValue()).isEqualTo(USER);
        assertThat(a.get("username")).isEqualTo("admin7601");
        assertThat(a.get("operation_type")).isEqualTo("CREATE");
        assertThat(a.get("module_code")).isEqualTo("system");
        assertThat(a.get("resource_no")).isEqualTo("AUD1");
        assertThat(((Number) a.get("result")).intValue()).isEqualTo(1);
        Map<String, Object> after = JsonPath.read((String) a.get("after"), "$");
        assertThat(after).containsEntry("companyCode", "AUD1").containsEntry("unifiedSocialCreditCode", USCC_A)
                .containsEntry("taxPayerType", 1).containsEntry("fiscalYearStartMonth", 1)
                .containsEntry("baseCurrencyCode", "CNY");
        assertThat(owner.queryForObject("SELECT count(*) FROM sys_audit_log WHERE tenant_id = ?", Integer.class, TENANT))
                .isEqualTo(1);
    }

    @Test
    void failedCreationWritesNoAuditLog() throws Exception {
        create(USER, body("DUPA", USCC_A)).andExpect(status().isCreated());
        create(USER, body("DUPA", USCC_B)).andExpect(status().isUnprocessableContent());
        CompanyInitInjector.action = (jdbc, id) ->
                jdbc.sql("SELECT set_config('app.tenant_id', '999999', true)").query((rs, i) -> 1).list();
        create(USER, body("RBK2", "91350100M000100Y43")).andExpect(status().isInternalServerError());
        assertThat(owner.queryForObject("SELECT count(*) FROM sys_audit_log WHERE tenant_id = ?", Integer.class, TENANT))
                .isEqualTo(1);
    }
}
