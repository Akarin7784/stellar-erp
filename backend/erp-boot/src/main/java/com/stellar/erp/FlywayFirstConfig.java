package com.stellar.erp;

import java.util.Arrays;
import java.util.LinkedHashSet;
import java.util.Set;

import org.springframework.beans.factory.config.BeanDefinition;
import org.springframework.beans.factory.config.BeanFactoryPostProcessor;
import org.springframework.beans.factory.config.ConfigurableListableBeanFactory;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * 保证 Flyway 迁移先于 Flowable 引擎初始化执行。
 * Flowable 会在 public schema 自动建表，若先于 Flyway 执行，Flyway 会因 "non-empty schema" 拒绝迁移。
 */
@Configuration(proxyBeanMethods = false)
class FlywayFirstConfig {

    private static final String FLYWAY_INITIALIZER = "flywayInitializer";
    private static final String PROCESS_ENGINE = "processEngine";

    @Bean
    static BeanFactoryPostProcessor flowableDependsOnFlyway() {
        return (ConfigurableListableBeanFactory bf) -> {
            if (!bf.containsBeanDefinition(FLYWAY_INITIALIZER) || !bf.containsBeanDefinition(PROCESS_ENGINE)) {
                return;
            }
            BeanDefinition engine = bf.getBeanDefinition(PROCESS_ENGINE);
            Set<String> deps = new LinkedHashSet<>();
            if (engine.getDependsOn() != null) {
                deps.addAll(Arrays.asList(engine.getDependsOn()));
            }
            deps.add(FLYWAY_INITIALIZER);
            engine.setDependsOn(deps.toArray(String[]::new));
        };
    }
}
