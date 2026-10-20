package com.stellar.erp;

import java.util.Arrays;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.config.BeanDefinition;
import org.springframework.beans.factory.config.BeanFactoryPostProcessor;
import org.springframework.beans.factory.config.ConfigurableListableBeanFactory;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.util.ClassUtils;

/**
 * 保证 Flyway 迁移先于所有 Flowable 引擎（process/app/cmmn/dmn/idm/eventRegistry 等）初始化执行。
 * Flowable 会在 public schema 自动建表，若先于 Flyway 执行，Flyway 会因 "non-empty schema" 拒绝迁移。
 */
@Configuration(proxyBeanMethods = false)
class FlywayFirstConfig {

    private static final Logger log = LoggerFactory.getLogger(FlywayFirstConfig.class);

    static final String FLYWAY_INITIALIZER = "flywayInitializer";

    /** 已知的 Flowable Spring Boot 引擎 Bean 名称。 */
    static final List<String> KNOWN_ENGINE_BEANS = List.of(
            "processEngine", "appEngine", "cmmnEngine", "dmnEngine", "idmEngine",
            "eventRegistryEngine", "formEngine", "contentEngine");

    private static final String FLOWABLE_ENGINE_TYPE = "org.flowable.common.engine.api.Engine";

    @Bean
    static BeanFactoryPostProcessor flowableDependsOnFlyway() {
        return FlywayFirstConfig::applyDependsOn;
    }

    static void applyDependsOn(ConfigurableListableBeanFactory bf) {
        if (!bf.containsBeanDefinition(FLYWAY_INITIALIZER)) {
            log.warn("未找到 Bean '{}'，无法保证 Flyway 先于 Flowable 引擎执行（Flyway 是否被禁用或未引入 spring-boot-starter-flyway？）",
                    FLYWAY_INITIALIZER);
            return;
        }
        Set<String> engines = new LinkedHashSet<>();
        for (String name : KNOWN_ENGINE_BEANS) {
            if (bf.containsBeanDefinition(name)) {
                engines.add(name);
            }
        }
        ClassLoader cl = bf.getBeanClassLoader();
        if (ClassUtils.isPresent(FLOWABLE_ENGINE_TYPE, cl)) {
            Class<?> engineType = ClassUtils.resolveClassName(FLOWABLE_ENGINE_TYPE, cl);
            for (String name : bf.getBeanNamesForType(engineType, true, false)) {
                String raw = name.startsWith("&") ? name.substring(1) : name;
                if (bf.containsBeanDefinition(raw)) {
                    engines.add(raw);
                }
            }
        }
        if (!engines.contains("processEngine")) {
            log.warn("未找到 Bean 'processEngine'，Flowable 流程引擎可能未启用或 Bean 名称已变化");
        }
        if (engines.isEmpty()) {
            log.warn("未检测到任何 Flowable 引擎 Bean，未设置对 '{}' 的依赖", FLYWAY_INITIALIZER);
            return;
        }
        for (String name : engines) {
            BeanDefinition def = bf.getBeanDefinition(name);
            Set<String> deps = new LinkedHashSet<>();
            if (def.getDependsOn() != null) {
                deps.addAll(Arrays.asList(def.getDependsOn()));
            }
            deps.add(FLYWAY_INITIALIZER);
            def.setDependsOn(deps.toArray(String[]::new));
        }
        log.info("Flowable 引擎 {} 已设置依赖 '{}'", engines, FLYWAY_INITIALIZER);
    }
}
