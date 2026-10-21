package com.stellar.erp;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import org.junit.jupiter.api.Test;
import org.springframework.boot.SpringApplication;
import org.springframework.mock.env.MockEnvironment;

class RequiredEnvironmentCheckTest {

    @Test
    void prodWithoutEnvFailsFast() {
        MockEnvironment env = new MockEnvironment();
        env.setActiveProfiles("prod");
        assertThatThrownBy(() -> RequiredEnvironmentCheck.verify(env))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("DB_URL")
                .hasMessageContaining("DB_USER")
                .hasMessageContaining("DB_PASSWORD")
                .hasMessageContaining("DB_APP_USER")
                .hasMessageContaining("DB_APP_PASSWORD");
    }

    @Test
    void prodWithoutAppCredentialsFails() {
        MockEnvironment env = new MockEnvironment()
                .withProperty("DB_URL", "jdbc:postgresql://db:5432/x")
                .withProperty("DB_USER", "u")
                .withProperty("DB_PASSWORD", "p");
        env.setActiveProfiles("prod");
        assertThatThrownBy(() -> RequiredEnvironmentCheck.verify(env))
                .hasMessageContaining("DB_APP_USER")
                .hasMessageContaining("DB_APP_PASSWORD")
                .hasMessageNotContaining("DB_URL");
    }

    @Test
    void appPasswordWithSingleQuoteFailsInAnyProfile() {
        MockEnvironment env = new MockEnvironment()
                .withProperty(RequiredEnvironmentCheck.APP_PASSWORD_PLACEHOLDER, "ab'c");
        env.setActiveProfiles("dev");
        assertThatThrownBy(() -> RequiredEnvironmentCheck.verify(env))
                .hasMessageContaining("单引号");
    }

    @Test
    void prodWithBlankPasswordFails() {
        MockEnvironment env = new MockEnvironment()
                .withProperty("DB_URL", "jdbc:postgresql://db:5432/x")
                .withProperty("DB_USER", "u")
                .withProperty("DB_PASSWORD", " ");
        env.setActiveProfiles("prod");
        assertThatThrownBy(() -> RequiredEnvironmentCheck.verify(env))
                .hasMessageContaining("DB_PASSWORD");
    }

    @Test
    void prodWithEnvPasses() {
        MockEnvironment env = new MockEnvironment()
                .withProperty("DB_URL", "jdbc:postgresql://db:5432/x")
                .withProperty("DB_USER", "u")
                .withProperty("DB_PASSWORD", "p")
                .withProperty("DB_APP_USER", "erp_app")
                .withProperty("DB_APP_PASSWORD", "ap")
                .withProperty("REDIS_HOST", "redis");
        env.setActiveProfiles("prod");
        assertThatCode(() -> RequiredEnvironmentCheck.verify(env)).doesNotThrowAnyException();
    }

    @Test
    void devDoesNotRequireEnv() {
        MockEnvironment env = new MockEnvironment();
        env.setActiveProfiles("dev");
        assertThatCode(() -> RequiredEnvironmentCheck.verify(env)).doesNotThrowAnyException();
    }

    /** 端到端：以 prod 启动真实 SpringApplication（无环境变量）应在创建 Bean 前失败。 */
    @Test
    void prodApplicationStartupFailsFast() {
        SpringApplication app = new SpringApplication(ErpApplication.class);
        app.setAdditionalProfiles("prod");
        assertThatThrownBy(() -> app.run("--spring.main.web-application-type=none"))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("DB_PASSWORD");
    }
}
