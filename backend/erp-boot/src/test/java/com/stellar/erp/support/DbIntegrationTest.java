package com.stellar.erp.support;

import java.lang.annotation.Documented;
import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

import org.junit.jupiter.api.Tag;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.ActiveProfiles;

/**
 * 数据库集成测试约定：标注后启动完整 Spring 上下文，连接 Testcontainers PostgreSQL（postgres:18.6），
 * 并打上 JUnit 标签 {@code integration}。CI（./mvnw verify）默认运行全部测试，包括本标签。
 * 本地仅跑单元测试：./mvnw test -DexcludedGroups=integration
 */
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Tag("integration")
// erp.auth.trust-preset-context：既存 MockMvc 测试直接设置 LoginContext；仅 test profile 允许为 true（TrustPresetContextPolicy）。
@SpringBootTest(properties = "erp.auth.trust-preset-context=true")
@ActiveProfiles("test")
@Import({PostgresContainerConfig.class, RedisContainerConfig.class})
public @interface DbIntegrationTest {
}
