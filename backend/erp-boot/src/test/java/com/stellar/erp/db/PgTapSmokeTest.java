package com.stellar.erp.db;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.List;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.testcontainers.postgresql.PostgreSQLContainer;

import com.stellar.erp.support.DbIntegrationTest;
import com.stellar.erp.support.OwnerJdbc;

/**
 * pgTAP 冒烟测试。pgtap 扩展只在测试中创建（生产迁移不包含）。
 * 编写 pgTAP 用例时：以 owner 连接执行 plan/断言/finish，所有行以 "ok" 开头即通过。
 */
@DbIntegrationTest
class PgTapSmokeTest {

    @Autowired
    PostgreSQLContainer pg;

    @Test
    void pgTapAssertionsPass() {
        JdbcTemplate owner = OwnerJdbc.of(pg);
        owner.execute("CREATE EXTENSION IF NOT EXISTS pgtap");
        // 同一连接（会话）内顺序执行：plan → 断言 → finish
        List<String> tap = new java.util.ArrayList<>();
        tap.add(owner.queryForObject("SELECT plan(3)", String.class));
        tap.add(owner.queryForObject("SELECT has_table('public'::name, 'sys_user'::name, 'sys_user 存在')", String.class));
        tap.add(owner.queryForObject("SELECT policies_are('public'::name, 'sys_user'::name, ARRAY['tenant_isolation']::name[], 'sys_user 仅有租户隔离策略')", String.class));
        tap.add(owner.queryForObject("SELECT has_role('erp_app'::name, '应用角色 erp_app 存在')", String.class));
        tap.addAll(owner.queryForList("SELECT * FROM finish()", String.class));
        assertThat(tap).isNotEmpty();
        assertThat(tap.stream().filter(l -> l.startsWith("not ok"))).as("pgTAP 输出: %s", tap).isEmpty();
        assertThat(tap.stream().filter(l -> l.startsWith("ok"))).hasSize(3);
    }
}
