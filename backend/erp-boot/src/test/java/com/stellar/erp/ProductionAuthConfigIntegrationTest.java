package com.stellar.erp;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;

import com.stellar.erp.common.LoginContext;
import com.stellar.erp.common.LoginContext.LoginUser;
import com.stellar.erp.common.TenantContext;
import com.stellar.erp.support.PostgresContainerConfig;
import com.stellar.erp.support.RedisContainerConfig;

/**
 * 生产配置（不激活 test profile、不设置 erp.auth.trust-preset-context，即默认 false）下，
 * 预先设置的 LoginContext 不会被信任：无 token 一律 401 / 2001 / MSG-COM-020。
 */
@Tag("integration")
@SpringBootTest
@Import({PostgresContainerConfig.class, RedisContainerConfig.class})
class ProductionAuthConfigIntegrationTest {

    @Autowired WebApplicationContext wac;
    @Autowired TrustPresetContextPolicy policy;

    @AfterEach
    void clear() {
        LoginContext.clear();
        TenantContext.clear();
    }

    @Test
    void switchIsOffByDefault() {
        assertThat(policy.enabled()).isFalse();
    }

    @Test
    void presetContextWithoutTokenIs401() throws Exception {
        TenantContext.set(312L);
        LoginContext.set(new LoginUser(7401L, 81L));
        AuthInterceptorIntegrationTest.is401(
                MockMvcBuilders.webAppContextSetup(wac).build().perform(get("/api/system/departments/options")));
        AuthInterceptorIntegrationTest.is401(
                MockMvcBuilders.webAppContextSetup(wac).build().perform(get("/api/system/auth/me")));
    }
}
