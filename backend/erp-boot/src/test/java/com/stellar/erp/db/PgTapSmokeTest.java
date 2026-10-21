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
 * 涉及 RLS 的断言必须先 {@code SET ROLE erp_app}（owner/超级用户绕过 RLS）；同一连接内执行，结束后 RESET ROLE。
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
        owner.update("INSERT INTO sys_user (id, tenant_id, company_id, user_code, username, real_name, password_hash) VALUES (9101, 301, 1, 'tap_a', 'tap_a', 'tap_a', 'x'), (9102, 302, 1, 'tap_b', 'tap_b', 'tap_b', 'x') ON CONFLICT DO NOTHING");
        tap.add(owner.queryForObject("SELECT plan(6)", String.class));
        tap.add(owner.queryForObject("SELECT has_table('public'::name, 'sys_user'::name, 'sys_user 存在')", String.class));
        tap.add(owner.queryForObject("SELECT policies_are('public'::name, 'sys_user'::name, ARRAY['tenant_isolation']::name[], 'sys_user 仅有租户隔离策略')", String.class));
        tap.add(owner.queryForObject("SELECT has_role('erp_app'::name, '应用角色 erp_app 存在')", String.class));
        // RLS 断言：切换为应用角色（受 RLS 约束），并在事务级设置租户
        owner.execute("BEGIN");
        owner.execute("SET LOCAL ROLE erp_app");
        owner.queryForObject("SELECT set_config('app.tenant_id', '301', true)", String.class);
        tap.add(owner.queryForObject("SELECT is(current_user::text, 'erp_app', 'RLS 断言以 erp_app 执行')", String.class));
        tap.add(owner.queryForObject("SELECT results_eq('SELECT username::text FROM sys_user WHERE id IN (9101, 9102)', ARRAY['tap_a'], '租户 301 只看到自己的行')", String.class));
        tap.add(owner.queryForObject("SELECT throws_ok('INSERT INTO sys_user (id, tenant_id, company_id, user_code, username, real_name, password_hash) VALUES (9103, 302, 1, ''tap_c'', ''tap_c'', ''tap_c'', ''x'')', '42501', NULL, 'WITH CHECK 拒绝写入其他租户')", String.class));
        owner.execute("ROLLBACK");
        tap.addAll(owner.queryForList("SELECT * FROM finish()", String.class));
        owner.update("DELETE FROM sys_user WHERE id IN (9101, 9102)");
        assertThat(tap).isNotEmpty();
        assertThat(tap.stream().filter(l -> l.startsWith("not ok"))).as("pgTAP 输出: %s", tap).isEmpty();
        assertThat(tap.stream().filter(l -> l.startsWith("ok"))).hasSize(6);
    }
}
