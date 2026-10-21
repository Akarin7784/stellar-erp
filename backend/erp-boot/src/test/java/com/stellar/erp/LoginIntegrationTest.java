package com.stellar.erp;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
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

    static void isBadCredentials(ResultActions r) throws Exception {
        r.andExpect(status().isOk())
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

    @Test
    void validationFailuresAreHttp200With1001() throws Exception {
        String longCode = "A".repeat(33);
        for (String body : new String[] {
                "{\"username\":\"u7501\",\"password\":\"x\"}",                        // tenantCode 欠落
                "{\"tenantCode\":\"" + longCode + "\",\"username\":\"u7501\",\"password\":\"x\"}", // 33 字
                "{\"tenantCode\":\"LOGINT\",\"password\":\"x\"}",                      // username 欠落
                "{\"tenantCode\":\"LOGINT\",\"username\":\"" + "u".repeat(65) + "\",\"password\":\"x\"}",
                "{\"tenantCode\":\"LOGINT\",\"username\":\"u7501\"}",                   // password 欠落
                "{\"tenantCode\":\"LOGINT\",\"username\":\"u7501\",\"password\":\"" + "p".repeat(65) + "\"}"}) {
            mvc.perform(post("/api/system/auth/login").contentType(MediaType.APPLICATION_JSON).content(body))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.code").value(1001))
                    .andExpect(jsonPath("$.data").doesNotExist());
        }
        assertThat(owner.queryForObject("SELECT login_fail_count FROM sys_user WHERE id = ?", Integer.class, USER)).isZero();
    }
}
