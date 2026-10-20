package com.stellar.erp.support;

import java.nio.file.Path;

import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.test.context.DynamicPropertyRegistrar;
import org.testcontainers.images.builder.ImageFromDockerfile;
import org.testcontainers.postgresql.PostgreSQLContainer;
import org.testcontainers.utility.DockerImageName;

/**
 * 测试用 PostgreSQL：基于 postgres:18.6（与 docker-compose.yml 一致）并安装 pgTAP。
 *
 * <p>不使用 {@code @ServiceConnection}：它会让应用数据源以容器超级用户连接，而超级用户绕过 RLS。
 * 这里显式区分两个账号，与生产一致：
 * <ul>
 *   <li>Flyway：容器 owner（超级用户）执行迁移；</li>
 *   <li>应用数据源：{@value #APP_USER}（非 owner、NOBYPASSRLS），密码经 Flyway 占位符在 afterMigrate 回调中设置。</li>
 * </ul>
 */
@TestConfiguration(proxyBeanMethods = false)
public class PostgresContainerConfig {

    public static final String BASE_IMAGE = "postgres:18.6";
    public static final String APP_USER = "erp_app";
    public static final String APP_PASSWORD = "erp_app_test_password";

    @Bean
    PostgreSQLContainer postgresContainer() {
        ImageFromDockerfile image = new ImageFromDockerfile("stellar-erp/postgres-pgtap", false)
                .withDockerfile(Path.of("src/test/docker/postgres-pgtap/Dockerfile"));
        PostgreSQLContainer container = new PostgreSQLContainer(
                DockerImageName.parse(image.get()).asCompatibleSubstituteFor("postgres"));
        container.start();
        return container;
    }

    @Bean
    DynamicPropertyRegistrar postgresProperties(PostgreSQLContainer pg) {
        return registry -> {
            registry.add("spring.datasource.url", pg::getJdbcUrl);
            registry.add("spring.datasource.username", () -> APP_USER);
            registry.add("spring.datasource.password", () -> APP_PASSWORD);
            registry.add("spring.flyway.url", pg::getJdbcUrl);
            registry.add("spring.flyway.user", pg::getUsername);
            registry.add("spring.flyway.password", pg::getPassword);
            registry.add("spring.flyway.placeholders.erp_app_password", () -> APP_PASSWORD);
        };
    }
}
