package com.stellar.erp.db;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.List;
import java.util.Set;

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

    /** public 中允许不带 tenant_id 的非业务表（显式白名单）。Flowable 表在 schema flowable，不在 public。 */
    static final List<String> NON_TENANT_WHITELIST = List.of("flyway_schema_history");

    @Test
    void everyPublicTableHasTenantIdUnlessWhitelisted() {
        List<String> missing = jdbc.queryForList("""
                SELECT c.relname FROM pg_class c
                JOIN pg_namespace n ON n.oid = c.relnamespace
                WHERE n.nspname = 'public'
                  AND c.relkind IN ('r', 'p')
                  AND NOT c.relispartition
                  AND c.relname <> ALL (?::text[])
                  AND NOT EXISTS (SELECT 1 FROM pg_attribute a
                                  WHERE a.attrelid = c.oid AND a.attname = 'tenant_id' AND NOT a.attisdropped)
                ORDER BY 1
                """, String.class, (Object) NON_TENANT_WHITELIST.toArray(String[]::new));
        assertThat(missing).as("public 中以下表缺少 tenant_id 且不在白名单 %s", NON_TENANT_WHITELIST).isEmpty();
    }

    @Test
    void everyPolicyOnTenantTablesHasUsingAndWithCheck() {
        List<String> violations = jdbc.queryForList("""
                SELECT c.relname || '.' || p.polname FROM pg_policy p
                JOIN pg_class c ON c.oid = p.polrelid
                JOIN pg_namespace n ON n.oid = c.relnamespace
                WHERE n.nspname = 'public'
                  AND (p.polqual IS NULL OR p.polwithcheck IS NULL)
                ORDER BY 1
                """, String.class);
        assertThat(violations).as("以下策略缺少 USING 或 WITH CHECK").isEmpty();
    }

    /** 一意インデックス先頭列規則の例外（親 id 先頭の明細表）。04-common-db-spec.md §6.1 例外一覧と同期。 */
    static final Set<String> UNIQUE_INDEX_EXCEPTIONS = Set.of(
            "uk_mdm_material_factory",
            "uk_mdm_substitute",
            "uk_mdm_warehouse_zone_code",
            "uk_mdm_price_line_no",
            "uk_mdm_quotation_line_no",
            "uk_mdm_payment_term_line",
            "uk_mdm_evaluation",
            "uk_mdm_eval_item",
            "uk_mdm_change_line_no",
            // 06-production 90-db-design.md §8「一意索引の先頭列ルールと例外」（親 ID 先頭、company_id 打头）
            "uk_prd_bom_line_bom_line",
            "uk_prd_bom_substitute_line_pri",
            "uk_prd_routing_operation_routing_seq",
            "uk_prd_routing_operation_alt_pri",
            "uk_prd_work_center_calendar_date",
            "uk_prd_mps_line_mps_line",
            "uk_prd_work_order_material_wo_line",
            "uk_prd_work_order_operation_wo_seq",
            "uk_prd_work_order_change_wo_no",
            "uk_prd_material_issue_line_issue_line",
            "uk_prd_work_report_labor_report_line",
            "uk_prd_work_report_defect_report_line",
            "uk_prd_completion_receipt_line_rcpt_line",
            "uk_prd_outsourcing_order_line_order_line",
            "uk_prd_outsourcing_issue_line_issue_line",
            "uk_prd_outsourcing_receipt_line_rcpt_line"
    );

    /** 业务 schema 中所有非主键唯一索引的第一列必须是 tenant_id（唯一约束检查不经过 RLS）。 */
    @Test
    void everyUniqueIndexStartsWithTenantId() {
        List<String> violations = jdbc.queryForList("""
                SELECT n.nspname || '.' || ic.relname || ' ON ' || tc.relname
                       || ' (first=' || coalesce(a.attname, '<expr>') || ')'
                FROM pg_index i
                JOIN pg_class ic ON ic.oid = i.indexrelid
                JOIN pg_class tc ON tc.oid = i.indrelid
                JOIN pg_namespace n ON n.oid = tc.relnamespace
                LEFT JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = i.indkey[0]
                WHERE i.indisunique AND NOT i.indisprimary
                  AND n.nspname NOT IN ('flowable', 'pg_catalog', 'information_schema', 'pg_toast')
                  AND n.nspname NOT LIKE 'pg_temp%'
                  AND tc.relname <> 'flyway_schema_history'
                  AND NOT tc.relispartition
                  AND ic.relname <> ALL (?::text[])
                  AND (a.attname IS DISTINCT FROM 'tenant_id')
                ORDER BY 1
                """, String.class, (Object) UNIQUE_INDEX_EXCEPTIONS.toArray(String[]::new));
        assertThat(violations).as("以下唯一索引第一列不是 tenant_id，且不在例外 %s", UNIQUE_INDEX_EXCEPTIONS).isEmpty();
    }

    @Test
    void appRoleCannotCreateInBusinessOrFlowableSchema() {
        var row = jdbc.queryForMap("""
                SELECT has_schema_privilege('erp_app', 'public', 'CREATE') AS pub,
                       has_schema_privilege('erp_app', 'flowable', 'CREATE') AS flw,
                       has_schema_privilege('erp_app', 'flowable', 'USAGE') AS flw_usage
                """);
        assertThat(row.get("pub")).isEqualTo(false);
        assertThat(row.get("flw")).isEqualTo(false);
        assertThat(row.get("flw_usage")).isEqualTo(true);
    }

    /** erp_app 自建对象的 owner 是自己，RLS 对 owner 无效（FORCE 也挡不住 DROP/ALTER），因此不允许存在。 */
    @Test
    void noRelationIsOwnedByAppRole() {
        List<String> owned = jdbc.queryForList("""
                SELECT n.nspname || '.' || c.relname FROM pg_class c
                JOIN pg_namespace n ON n.oid = c.relnamespace
                WHERE c.relowner = (SELECT oid FROM pg_roles WHERE rolname = 'erp_app')
                ORDER BY 1
                """, String.class);
        assertThat(owned).as("以下对象的 owner 是 erp_app").isEmpty();
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
