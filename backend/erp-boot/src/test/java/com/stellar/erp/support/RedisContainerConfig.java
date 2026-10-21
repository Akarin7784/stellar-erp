package com.stellar.erp.support;

import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.context.annotation.Bean;
import org.testcontainers.containers.GenericContainer;
import org.testcontainers.utility.DockerImageName;

/** 测试用 Redis（与 docker-compose.yml 相同镜像），供 Sa-Token Redis DAO 使用。 */
@TestConfiguration(proxyBeanMethods = false)
public class RedisContainerConfig {

    public static final String IMAGE = "redis:8.8.3";

    @Bean
    @ServiceConnection(name = "redis")
    GenericContainer<?> redisContainer() {
        return new GenericContainer<>(DockerImageName.parse(IMAGE)).withExposedPorts(6379);
    }
}
