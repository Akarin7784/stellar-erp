package com.stellar.erp.support;

import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.context.annotation.Bean;
import org.testcontainers.postgresql.PostgreSQLContainer;
import org.testcontainers.utility.DockerImageName;

/** 与 docker-compose.yml 保持一致的 PostgreSQL 版本。 */
@TestConfiguration(proxyBeanMethods = false)
public class PostgresContainerConfig {

    public static final String POSTGRES_IMAGE = "postgres:18.6";

    @Bean
    @ServiceConnection
    PostgreSQLContainer postgresContainer() {
        return new PostgreSQLContainer(DockerImageName.parse(POSTGRES_IMAGE));
    }
}
