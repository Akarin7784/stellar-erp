package com.stellar.erp;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.test.json.JsonCompareMode;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.SingleConnectionDataSource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;
import org.testcontainers.postgresql.PostgreSQLContainer;

import com.jayway.jsonpath.JsonPath;
import com.stellar.erp.common.LoginContext;
import com.stellar.erp.common.TenantContext;
import com.stellar.erp.support.DbIntegrationTest;
import com.stellar.erp.support.LoginConflictInjector;
import com.stellar.erp.support.OwnerJdbc;
import com.stellar.erp.support.PermissionGrants;

import cn.dev33.satoken.secure.BCrypt;

/** POST /api/system/auth/login（01-auth-login PRC-SYS-001-02、BR-04・BR-13・BR-14）。 */
@DbIntegrationTest
class LoginIntegrationTest {

    static final long TENANT = 313L, CO = 83L, USER = 7501L, TENANT_ROW = 9313L;
    static final String CODE = "LOGINT", PW = "Passw0rd!";

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
        cn.dev33.satoken.SaManager.setSaTokenDao(wac.getBean(cn.dev33.satoken.dao.SaTokenDao.class));
        mvc = MockMvcBuilders.webAppContextSetup(wac).build();
        owner.update("INSERT INTO sys_tenant (id, tenant_id, tenant_code, tenant_name) VALUES (?, ?, ?, 'login test')",
                TENANT_ROW, TENANT, CODE);
        owner.update("""
                INSERT INTO sys_user (id, tenant_id, company_id, user_code, username, real_name, nickname, password_hash)
                VALUES (?, ?, ?, 'E007501', 'u7501', '登录用户', 'nick', ?)
                """, USER, TENANT, CO, BCrypt.hashpw(PW, BCrypt.gensalt(10)));
        PermissionGrants.grant(owner, TENANT, CO, USER, 998600, "test:login:view");
    }

    @AfterEach
    void tearDown() {
        LoginConflictInjector.reset();
        cleanup();
        LoginContext.clear();
        TenantContext.clear();
    }

    void cleanup() {
        PermissionGrants.cleanup(owner, TENANT);
        owner.update("DELETE FROM sys_login_log WHERE tenant_id = ?", TENANT);
        owner.update("DELETE FROM sys_user WHERE tenant_id = ?", TENANT);
        owner.update("DELETE FROM sys_tenant WHERE id = ?", TENANT_ROW);
    }

    @AfterAll
    static void close() {
        if (owner != null) {
            ((SingleConnectionDataSource) owner.getDataSource()).destroy();
            owner = null;
        }
    }

    ResultActions login(String tenantCode, String username, String password) throws Exception {
        String body = "{\"tenantCode\":\"%s\",\"username\":\"%s\",\"password\":\"%s\"}"
                .formatted(tenantCode, username, password);
        return mvc.perform(post("/api/system/auth/login").contentType(MediaType.APPLICATION_JSON).content(body));
    }

    /** 2002 の応答 body 全体（既存 Result は isSuccess() により "success" も出力される）（列挙防止：どの原因でも完全一致）。 */
    static final String BAD_CREDENTIALS_BODY =
            "{\"code\":2002,\"message\":\"企业代码、用户名或密码错误。\",\"data\":null,\"msgId\":\"MSG-COM-021\",\"success\":false}";

    static void isBadCredentials(ResultActions r) throws Exception {
        r.andExpect(status().isOk())
                .andExpect(content().json(BAD_CREDENTIALS_BODY, JsonCompareMode.STRICT))
                .andExpect(jsonPath("$.code").value(2002))
                .andExpect(jsonPath("$.msgId").value("MSG-COM-021"))
                .andExpect(jsonPath("$.message").value("企业代码、用户名或密码错误。"));
    }

    @Test
    void lowercaseTenantCodeLogsInAndTokenWorks() throws Exception {
        String json = login("loginT".toLowerCase(), "u7501", PW)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.tokenName").value("Authorization"))
                .andExpect(jsonPath("$.data.expiresIn").value(86400))
                .andExpect(jsonPath("$.data.passwordResetRequired").value(true)) // 迁移既定 TRUE
                .andExpect(jsonPath("$.data.userInfo.id").value(String.valueOf(USER)))
                .andExpect(jsonPath("$.data.permissions[0]").value("test:login:view"))
                .andReturn().getResponse().getContentAsString();
        String token = JsonPath.read(json, "$.data.token");
        // sys_login_log.session_id はトークンではなく SHA-256 16 進全体（64 字）
        String sid = owner.queryForObject("SELECT session_id FROM sys_login_log WHERE tenant_id = ? AND login_result = 1",
                String.class, TENANT);
        assertThat(sid).isNotEqualTo(token).doesNotContain(token).matches("[0-9a-f]{64}");
        assertThat(sid).isEqualTo(java.util.HexFormat.of().formatHex(java.security.MessageDigest.getInstance("SHA-256")
                .digest(token.getBytes(java.nio.charset.StandardCharsets.UTF_8))));
        mvc.perform(get("/api/system/auth/me").header("Authorization", token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.companyId").value(String.valueOf(CO)));
        assertThat(owner.queryForObject("SELECT login_fail_count FROM sys_user WHERE id = ?", Integer.class, USER)).isZero();
        assertThat(owner.queryForObject("SELECT last_login_at IS NOT NULL FROM sys_user WHERE id = ?", Boolean.class, USER)).isTrue();
        assertThat(owner.queryForObject("SELECT count(*) FROM sys_login_log WHERE tenant_id = ? AND login_result = 1",
                Integer.class, TENANT)).isEqualTo(1);
    }

    @Test
    void unknownTenantUnknownUserWrongPasswordAndUsernameCaseAreTheSameError() throws Exception {
        isBadCredentials(login("NOSUCH", "u7501", PW));
        isBadCredentials(login(CODE, "nobody", PW));
        isBadCredentials(login(CODE, "U7501", PW)); // username は大文字小文字を区別
        isBadCredentials(login(CODE, "u7501", "wrong"));
        owner.update("UPDATE sys_tenant SET status = 0 WHERE id = ?", TENANT_ROW);
        isBadCredentials(login(CODE, "u7501", PW));
        // 租户期限切れ（expire_date < current_date）も同一の 2002（01-auth-login 前提条件 5・BR-14）
        owner.update("UPDATE sys_tenant SET status = 1, expire_date = current_date - 1 WHERE id = ?", TENANT_ROW);
        isBadCredentials(login(CODE, "u7501", PW));
    }

    @Test
    void fiveFailuresLockAndCorrectPasswordIsThenRejected() throws Exception {
        for (int i = 0; i < 5; i++) {
            isBadCredentials(login(CODE, "u7501", "wrong"));
        }
        assertThat(owner.queryForObject("SELECT account_status FROM sys_user WHERE id = ?", Integer.class, USER)).isEqualTo(2);
        login(CODE, "u7501", PW)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(2003))
                .andExpect(jsonPath("$.msgId").value("MSG-COM-023"))
                .andExpect(jsonPath("$.message").value("账号已被锁定，请于 30 分钟后重试或联系管理员。"));
    }

    @Test
    void expiredLockIsReleasedOnLogin() throws Exception {
        owner.update("UPDATE sys_user SET account_status = 2, login_fail_count = 5, lock_until = now() - interval '1 minute' WHERE id = ?", USER);
        login(CODE, "u7501", PW).andExpect(status().isOk());
        assertThat(owner.queryForObject("SELECT account_status FROM sys_user WHERE id = ?", Integer.class, USER)).isEqualTo(1);
    }

    @Test
    void disabledAccountIsHttp200WithAccountDisabledCode() throws Exception {
        owner.update("UPDATE sys_user SET account_status = 3 WHERE id = ?", USER);
        assertThat(com.stellar.erp.system.auth.LoginService.ACCOUNT_DISABLED).isBetween(10000, 19999).isNotEqualTo(10001);
        login(CODE, "u7501", PW)
                .andExpect(status().isOk()) // ログイン API に限り HTTP 200
                .andExpect(jsonPath("$.code").value(com.stellar.erp.system.auth.LoginService.ACCOUNT_DISABLED))
                .andExpect(jsonPath("$.msgId").value("MSG-SYS-001"));
    }

    @Test
    void passwordResetRequiredFalseWhenCleared() throws Exception {
        owner.update("UPDATE sys_user SET password_reset_required = FALSE WHERE id = ?", USER);
        login(CODE, "u7501", PW).andExpect(jsonPath("$.data.passwordResetRequired").value(false));
    }

    @Test
    void userWithoutRolesLogsInWithEmptyMenus() throws Exception {
        PermissionGrants.cleanup(owner, TENANT);
        login(CODE, "u7501", PW)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.roles.length()").value(0))
                .andExpect(jsonPath("$.data.permissions.length()").value(0))
                .andExpect(jsonPath("$.data.menus.length()").value(0));
    }

    /** 別接続（owner、autocommit）で version を進め、ログイン側の WHERE version 更新を 0 件にする。 */
    void injectConflicts(int times, String extraSet) {
        int[] left = {times};
        LoginConflictInjector.action = id -> {
            if (left[0]-- > 0) {
                owner.update("UPDATE sys_user SET version = version + 1" + extraSet + " WHERE id = ?", id);
            }
        };
    }

    int version() {
        return owner.queryForObject("SELECT version FROM sys_user WHERE id = ?", Integer.class, USER);
    }

    @Test
    void oneVersionConflictIsRetriedAndLoginSucceeds() throws Exception {
        int v0 = version();
        injectConflicts(1, "");
        login(CODE, "u7501", PW).andExpect(status().isOk()).andExpect(jsonPath("$.code").value(0));
        assertThat(version()).isEqualTo(v0 + 2); // 競合更新 +1、再試行の更新 +1
    }

    @Test
    void retryRereadsFailCountBeforeIncrementing() throws Exception {
        injectConflicts(1, ", login_fail_count = 2");
        isBadCredentials(login(CODE, "u7501", "wrong"));
        assertThat(owner.queryForObject("SELECT login_fail_count FROM sys_user WHERE id = ?", Integer.class, USER))
                .isEqualTo(3);
    }

    @Test
    void secondVersionConflictIs4003() throws Exception {
        injectConflicts(2, "");
        login(CODE, "u7501", PW)
                .andExpect(status().isOk()) // ログイン API は 4003 も HTTP 200（改密等の他 API は 409）
                .andExpect(jsonPath("$.code").value(4003))
                .andExpect(jsonPath("$.msgId").value("MSG-COM-033"))
                .andExpect(jsonPath("$.data").doesNotExist());
        assertThat(owner.queryForObject("SELECT count(*) FROM sys_login_log WHERE tenant_id = ? AND fail_reason = 'MSG-COM-033'",
                Integer.class, TENANT)).isEqualTo(1);
    }

    /** 1001 の body 全体：message/msgId は最初の違反、fieldErrors に全違反（[field, message] の組）。 */
    void expectInvalid(String body, String msgId, String[]... errors) throws Exception {
        StringBuilder fe = new StringBuilder();
        for (String[] e : errors) {
            if (fe.length() > 0) fe.append(',');
            fe.append("{\"field\":\"").append(e[0]).append("\",\"message\":\"").append(e[1]).append("\"}");
        }
        String expected = "{\"code\":1001,\"message\":\"%s\",\"data\":{\"fieldErrors\":[%s]},\"msgId\":%s,\"success\":false}"
                .formatted(errors[0][1], fe, msgId == null ? "null" : "\"" + msgId + "\"");
        mvc.perform(post("/api/system/auth/login").contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isOk())
                .andExpect(content().json(expected, JsonCompareMode.STRICT));
    }

    static String[] fe(String field, String message) {
        return new String[] {field, message};
    }

    static final String REQ_T = "请输入必填项「企业代码」。", REQ_U = "请输入必填项「账号」。", REQ_P = "请输入必填项「密码」。";
    static final String FMT_T = "「企业代码」只能为半角英数。";

    static String body(String tenantCode, String username, String password) {
        java.util.List<String> parts = new java.util.ArrayList<>();
        if (tenantCode != null) parts.add("\"tenantCode\":\"" + tenantCode + "\"");
        if (username != null) parts.add("\"username\":\"" + username + "\"");
        if (password != null) parts.add("\"password\":\"" + password + "\"");
        return "{" + String.join(",", parts) + "}";
    }

    @Test
    void validationFailuresAreHttp200With1001() throws Exception {
        expectInvalid(body(null, "u7501", "x"), "MSG-COM-040", fe("tenantCode", REQ_T));
        expectInvalid(body("A".repeat(33), "u7501", "x"), "MSG-COM-041", fe("tenantCode", "「企业代码」不能超过 32 个字符。"));
        expectInvalid(body("LOG-INT", "u7501", "x"), null, fe("tenantCode", FMT_T));
        expectInvalid(body("ＬＯＧＩＮＴ", "u7501", "x"), null, fe("tenantCode", FMT_T));
        expectInvalid(body(CODE, null, "x"), "MSG-COM-040", fe("username", REQ_U));
        expectInvalid(body(CODE, "u".repeat(65), "x"), "MSG-COM-041", fe("username", "「账号」不能超过 64 个字符。"));
        expectInvalid(body(CODE, "u7501", null), "MSG-COM-040", fe("password", REQ_P));
        expectInvalid(body(CODE, "u7501", "p".repeat(65)), "MSG-COM-041", fe("password", "「密码」不能超过 64 个字符。"));
        assertThat(owner.queryForObject("SELECT login_fail_count FROM sys_user WHERE id = ?", Integer.class, USER)).isZero();
    }

    @Test
    void multipleInvalidFieldsAreAllReturnedInFormOrder() throws Exception {
        expectInvalid("{}", "MSG-COM-040", fe("tenantCode", REQ_T), fe("username", REQ_U), fe("password", REQ_P));
        expectInvalid(body(CODE, null, null), "MSG-COM-040", fe("username", REQ_U), fe("password", REQ_P));
        expectInvalid(body("bad-code", "u".repeat(65), null), null,
                fe("tenantCode", FMT_T), fe("username", "「账号」不能超过 64 个字符。"), fe("password", REQ_P));
    }
}
