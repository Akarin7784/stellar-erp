package com.stellar.erp.db;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.List;
import java.util.Map;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;

import com.stellar.erp.support.DbIntegrationTest;

/**
 * Flyway 迁移集成校验：任一迁移脚本错误都会导致上下文启动失败或本测试断言失败。
 */
@DbIntegrationTest
class FlywayMigrationTest {

    @Autowired
    JdbcTemplate jdbc;

    @Test
    void allMigrationsAppliedSuccessfully() {
        List<Map<String, Object>> rows = jdbc.queryForList(
                "SELECT version, script, success FROM flyway_schema_history WHERE version IS NOT NULL ORDER BY installed_rank");
        assertThat(rows).as("flyway_schema_history 至少包含一条版本迁移").isNotEmpty();
        assertThat(rows).allSatisfy(r -> assertThat(r.get("success")).as("迁移 %s", r.get("script")).isEqualTo(Boolean.TRUE));
    }

    @Test
    void sysUserTableExists() {
        Integer count = jdbc.queryForObject(
                "SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'sys_user'",
                Integer.class);
        assertThat(count).isEqualTo(1);
    }
}
