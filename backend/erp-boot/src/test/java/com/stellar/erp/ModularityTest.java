package com.stellar.erp;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.springframework.modulith.core.ApplicationModules;

/**
 * 模块结构校验：CI 中强制模块边界，防止跨模块访问 internal 包。
 */
class ModularityTest {

    @Test
    void verifiesModuleStructure() {
        ApplicationModules modules = ApplicationModules.of(ErpApplication.class);
        modules.verify();
        assertThat(modules.stream().count()).isGreaterThanOrEqualTo(3);
    }
}
