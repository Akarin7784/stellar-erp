package com.stellar.erp;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.SingleConnectionDataSource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;
import org.testcontainers.postgresql.PostgreSQLContainer;

import com.stellar.erp.common.LoginContext;
import com.stellar.erp.common.LoginContext.LoginUser;
import com.stellar.erp.common.TenantContext;
import com.stellar.erp.support.DbIntegrationTest;
import com.stellar.erp.support.OwnerJdbc;
import com.stellar.erp.support.PermissionGrants;
import com.stellar.erp.system.AuthSessions;

import cn.dev33.satoken.context.mock.SaTokenContextMockUtil;

/** 認証（401 / 2001 / MSG-COM-020）と {@code @RequirePermission}（403 / 3001 / MSG-COM-030）。 */
@DbIntegrationTest
class AuthInterceptorIntegrationTest {

    static final long TENANT = 312L, CO = 81L, CO2 = 82L, USER = 7401L;

    @Autowired PostgreSQLContainer pg;
    @Autowired WebApplicationContext wac;
    @Autowired org.springframework.data.redis.core.StringRedisTemplate redis;

    static JdbcTemplate sharedOwner;
    JdbcTemplate owner;
    MockMvc mvc;

    @BeforeEach
    void setUp() {
        if (sharedOwner == null) {
            sharedOwner = OwnerJdbc.of(pg);
        }
        owner = sharedOwner;
        PermissionGrants.cleanup(owner, TENANT);
        mvc = MockMvcBuilders.webAppContextSetup(wac).build();
    }

    @AfterEach
    void tearDown() {
        PermissionGrants.cleanup(owner, TENANT);
        owner.update("DELETE FROM sys_user WHERE tenant_id = ?", TENANT);
        LoginContext.clear();
        TenantContext.clear();
    }

    @AfterAll
    static void closeOwner() {
        if (sharedOwner != null) {
            ((SingleConnectionDataSource) sharedOwner.getDataSource()).destroy();
            sharedOwner = null;
        }
    }

    ResultActions getAs(long company, String path) throws Exception {
        TenantContext.set(TENANT);
        LoginContext.set(new LoginUser(USER, company));
        return mvc.perform(get(path));
    }

    static void is401(ResultActions r) throws Exception {
        r.andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value(2001))
                .andExpect(jsonPath("$.msgId").value("MSG-COM-020"));
    }

    static void is403(ResultActions r) throws Exception {
        r.andExpect(status().isForbidden())
                .andExpect(jsonPath("$.code").value(3001))
                .andExpect(jsonPath("$.msgId").value("MSG-COM-030"));
    }

    @Test
    void unauthenticatedDeptOptionsIs401() throws Exception {
        is401(mvc.perform(get("/api/system/departments/options")));
    }

    @Test
    void unauthenticatedProbeIs401BeforePermissionCheck() throws Exception {
        is401(mvc.perform(get("/api/test/permission-probe/method")));
    }

    @Test
    void healthCheckNeedsNoLogin() throws Exception {
        mvc.perform(get("/api/v1/system/ping")).andExpect(status().isOk());
    }

    @Test
    void loginOnlyEndpointNeedsNoPermission() throws Exception {
        getAs(CO, "/api/system/departments/options").andExpect(status().isOk());
    }

    @Test
    void missingPermissionIs403() throws Exception {
        PermissionGrants.grant(owner, TENANT, CO, USER, 998100, "test:probe:other");
        is403(getAs(CO, "/api/test/permission-probe/method"));
    }

    @Test
    void grantedPermissionPasses() throws Exception {
        PermissionGrants.grant(owner, TENANT, CO, USER, 998100, "test:probe:view");
        getAs(CO, "/api/test/permission-probe/method").andExpect(status().isOk()).andExpect(jsonPath("$.data").value("ok"));
    }

    @Test
    void methodAnnotationOverridesClassAnnotation() throws Exception {
        PermissionGrants.grant(owner, TENANT, CO, USER, 998100, "test:probe:class");
        is403(getAs(CO, "/api/test/permission-probe/method"));
        getAs(CO, "/api/test/permission-probe/class").andExpect(status().isOk());
    }

    @Test
    void grantInOtherCompanyDoesNotCount() throws Exception {
        PermissionGrants.grant(owner, TENANT, CO2, USER, 998100, "test:probe:view");
        is403(getAs(CO, "/api/test/permission-probe/method"));
    }

    @Test
    void revokedOrExpiredOrDisabledRoleDoesNotCount() throws Exception {
        PermissionGrants.grant(owner, TENANT, CO, USER, 998100, "test:probe:view");
        owner.update("UPDATE sys_user_role SET status = 0 WHERE id = 999099");
        is403(getAs(CO, "/api/test/permission-probe/method"));
        owner.update("UPDATE sys_user_role SET status = 1, valid_to = CURRENT_DATE - 1 WHERE id = 999099");
        is403(getAs(CO, "/api/test/permission-probe/method"));
        owner.update("UPDATE sys_user_role SET valid_to = NULL WHERE id = 999099");
        owner.update("UPDATE sys_role SET status = 0 WHERE id = 998100");
        is403(getAs(CO, "/api/test/permission-probe/method"));
        owner.update("UPDATE sys_role SET status = 1 WHERE id = 998100");
        getAs(CO, "/api/test/permission-probe/method").andExpect(status().isOk());
    }

    // ------------------------------------------------------------------ Sa-Token セッション経由

    /** ログイン成立時と同じ {@link AuthSessions#open} でトークンを発行（Sa-Token の mock コンテキスト内）。 */
    static String token(long user, long tenant, long company) {
        String[] t = new String[1];
        SaTokenContextMockUtil.setMockContext(() -> t[0] = AuthSessions.open(user, tenant, company));
        return t[0];
    }

    ResultActions withToken(String token, org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder req)
            throws Exception {
        LoginContext.clear();
        TenantContext.clear();
        return mvc.perform(req.header("Authorization", token));
    }

    @Test
    void tokenSessionSuppliesTenantAndCompany() throws Exception {
        PermissionGrants.grant(owner, TENANT, CO, USER, 998100, "test:probe:view");
        withToken(token(USER, TENANT, CO), get("/api/test/permission-probe/method")).andExpect(status().isOk());
        // 業務 API：session の tenant → app.tenant_id（RLS）、company → LoginContext
        withToken(token(USER, TENANT, CO), get("/api/system/departments/options")).andExpect(status().isOk());
        // リクエスト後にスレッドへ残らない
        org.assertj.core.api.Assertions.assertThat(LoginContext.current()).isEmpty();
        org.assertj.core.api.Assertions.assertThat(TenantContext.current()).isEmpty();
    }

    @Test
    void tokenIsStoredInRedisAndRemovedOnLogout() throws Exception {
        String t = token(USER, TENANT, CO);
        String key = "Authorization:login:token:" + t;
        org.assertj.core.api.Assertions.assertThat(redis.hasKey(key)).isTrue();
        withToken(t, post("/api/system/auth/logout")).andExpect(status().isOk());
        org.assertj.core.api.Assertions.assertThat(redis.hasKey(key)).isFalse();
    }

    @Test
    void codeInCompanyAButNotBIs403InB() throws Exception {
        PermissionGrants.grant(owner, TENANT, CO, USER, 998100, "test:probe:view");
        withToken(token(USER, TENANT, CO), get("/api/test/permission-probe/method")).andExpect(status().isOk());
        is403(withToken(token(USER, TENANT, CO2), get("/api/test/permission-probe/method")));
    }

    @Test
    void invalidTokenIs401() throws Exception {
        is401(withToken("not-a-token", get("/api/system/departments/options")));
    }

    @Test
    void logoutIsPublicIdempotentAndInvalidatesOnlyThatToken() throws Exception {
        mvc.perform(post("/api/system/auth/logout")).andExpect(status().isOk()).andExpect(jsonPath("$.code").value(0));
        withToken("not-a-token", post("/api/system/auth/logout")).andExpect(status().isOk());
        String t1 = token(USER, TENANT, CO);
        String t2 = token(USER, TENANT, CO);
        withToken(t1, post("/api/system/auth/logout")).andExpect(status().isOk());
        withToken(t1, post("/api/system/auth/logout")).andExpect(status().isOk());   // 2 回目も 200
        is401(withToken(t1, get("/api/system/departments/options")));
        withToken(t2, get("/api/system/departments/options")).andExpect(status().isOk());   // 他端末は維持（BR-07）
    }

    @Test
    void meReturnsUserRolesAndDedupedPermissionsOfSessionCompany() throws Exception {
        owner.update("INSERT INTO sys_user (id, tenant_id, username, nickname, password) VALUES (?, ?, 'u7401', '用户', 'x')",
                USER, TENANT);
        PermissionGrants.grant(owner, TENANT, CO, USER, 998100, "test:a", "test:b");
        PermissionGrants.grant(owner, TENANT, CO, USER, 998200, "test:b");          // 重複コード
        PermissionGrants.grant(owner, TENANT, CO2, USER, 998300, "test:other-co");  // 他社は含まない
        withToken(token(USER, TENANT, CO), get("/api/system/auth/me"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.userInfo.id").value(String.valueOf(USER)))
                .andExpect(jsonPath("$.data.userInfo.username").value("u7401"))
                .andExpect(jsonPath("$.data.companyId").value(String.valueOf(CO)))
                .andExpect(jsonPath("$.data.roles.length()").value(2))
                .andExpect(jsonPath("$.data.permissions.length()").value(2))
                .andExpect(jsonPath("$.data.permissions[0]").value("test:a"))
                .andExpect(jsonPath("$.data.permissions[1]").value("test:b"));
        is401(withToken("not-a-token", get("/api/system/auth/me")));
    }
}
