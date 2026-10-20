package com.stellar.erp.db;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.List;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;

import com.stellar.erp.support.DbIntegrationTest;

/**
 * CI 守护：public schema 中所有含 tenant_id 列的表必须 ENABLE + FORCE ROW LEVEL SECURITY 且至少有一条策略。
 * 新增业务表忘记套用 RLS 模板时本测试失败。
 */
@DbIntegrationTest
class RlsCoverageTest {

    @Autowired
    JdbcTemplate jdbc;

    @Test
    void everyTenantTableHasForcedRlsAndPolicy() {
        List<String> violations = jdbc.queryForList("""
                SELECT c.relname || ' (enabled=' || c.relrowsecurity || ', forced=' || c.relforcerowsecurity
                       || ', policies=' || (SELECT count(*) FROM pg_policy p WHERE p.polrelid = c.oid) || ')'
                FROM pg_class c
                JOIN pg_namespace n ON n.oid = c.relnamespace
                WHERE n.nspname = 'public'
                  AND c.relkind IN ('r', 'p')
                  AND EXISTS (SELECT 1 FROM pg_attribute a
                              WHERE a.attrelid = c.oid AND a.attname = 'tenant_id' AND NOT a.attisdropped)
                  AND (NOT c.relrowsecurity OR NOT c.relforcerowsecurity
                       OR NOT EXISTS (SELECT 1 FROM pg_policy p WHERE p.polrelid = c.oid))
                ORDER BY 1
                """, String.class);
        assertThat(violations).as("以下含 tenant_id 的表未完整启用 RLS").isEmpty();
    }

    @Test
    void sysUserIsCoveredByTheCheck() {
        Integer n = jdbc.queryForObject("""
                SELECT count(*) FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
                WHERE n.nspname = 'public' AND c.relname = 'sys_user'
                  AND c.relrowsecurity AND c.relforcerowsecurity
                """, Integer.class);
        assertThat(n).isEqualTo(1);
    }

    @Test
    void appRoleIsNotOwnerNorBypassRls() {
        var row = jdbc.queryForMap("""
                SELECT current_user AS usr, r.rolsuper, r.rolbypassrls,
                       (SELECT pg_get_userbyid(c.relowner) FROM pg_class c WHERE c.relname = 'sys_user') AS owner
                FROM pg_roles r WHERE r.rolname = current_user
                """);
        assertThat(row.get("usr")).isEqualTo("erp_app");
        assertThat(row.get("rolsuper")).isEqualTo(false);
        assertThat(row.get("rolbypassrls")).isEqualTo(false);
        assertThat(row.get("owner")).isNotEqualTo("erp_app");
    }
}
