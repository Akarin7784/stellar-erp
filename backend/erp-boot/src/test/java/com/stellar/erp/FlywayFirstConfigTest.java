package com.stellar.erp;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.beans.factory.support.DefaultListableBeanFactory;
import org.springframework.beans.factory.support.RootBeanDefinition;
import org.springframework.boot.test.system.CapturedOutput;
import org.springframework.boot.test.system.OutputCaptureExtension;

/**
 * FlywayFirstConfig 的单元测试（不启动容器）：
 * 验证所有 Flowable 引擎 Bean 依赖 flywayInitializer，且 Bean 缺失时输出 WARN 而不是静默返回。
 * 端到端启动顺序由 db.FlywayMigrationTest 覆盖。
 */
@ExtendWith(OutputCaptureExtension.class)
class FlywayFirstConfigTest {

    private static DefaultListableBeanFactory factory(String... names) {
        DefaultListableBeanFactory bf = new DefaultListableBeanFactory();
        for (String n : names) {
            bf.registerBeanDefinition(n, new RootBeanDefinition(Object.class));
        }
        return bf;
    }

    @Test
    void allKnownEnginesDependOnFlyway() {
        DefaultListableBeanFactory bf = factory("flywayInitializer", "processEngine", "appEngine", "cmmnEngine");
        bf.getBeanDefinition("cmmnEngine").setDependsOn("existingDep");

        FlywayFirstConfig.applyDependsOn(bf);

        assertThat(bf.getBeanDefinition("processEngine").getDependsOn()).containsExactly("flywayInitializer");
        assertThat(bf.getBeanDefinition("appEngine").getDependsOn()).containsExactly("flywayInitializer");
        assertThat(bf.getBeanDefinition("cmmnEngine").getDependsOn()).containsExactly("existingDep", "flywayInitializer");
    }

    @Test
    void appliedTwiceDoesNotDuplicate() {
        DefaultListableBeanFactory bf = factory("flywayInitializer", "processEngine");
        FlywayFirstConfig.applyDependsOn(bf);
        FlywayFirstConfig.applyDependsOn(bf);
        assertThat(bf.getBeanDefinition("processEngine").getDependsOn()).containsExactly("flywayInitializer");
    }

    @Test
    void warnsWhenFlywayInitializerMissing(CapturedOutput output) {
        DefaultListableBeanFactory bf = factory("processEngine");
        FlywayFirstConfig.applyDependsOn(bf);
        assertThat(bf.getBeanDefinition("processEngine").getDependsOn()).isNull();
        assertThat(output).contains("WARN").contains("flywayInitializer");
    }

    @Test
    void warnsWhenProcessEngineMissing(CapturedOutput output) {
        DefaultListableBeanFactory bf = factory("flywayInitializer", "appEngine");
        FlywayFirstConfig.applyDependsOn(bf);
        assertThat(bf.getBeanDefinition("appEngine").getDependsOn()).containsExactly("flywayInitializer");
        assertThat(output).contains("WARN").contains("processEngine");
    }

    @Test
    void warnsWhenNoEngineFound(CapturedOutput output) {
        FlywayFirstConfig.applyDependsOn(factory("flywayInitializer"));
        assertThat(output).contains("未检测到任何 Flowable 引擎 Bean");
    }
}
