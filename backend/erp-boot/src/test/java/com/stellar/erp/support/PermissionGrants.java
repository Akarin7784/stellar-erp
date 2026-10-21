package com.stellar.erp.support;

import org.springframework.jdbc.core.JdbcTemplate;

/**
 * テスト用の権限付与（owner 接続、RLS バイパス）：sys_menu（ボタン）→ sys_role → sys_role_permission → sys_user_role。
 * 本番の権限コードはシード迁移で入るが、未投入のコードもあるためテストは明示的に付与する。
 * ID は {@code base} から連番で振る（呼び出し側でテナントごとに重ならない値を渡す）。
 */
public final class PermissionGrants {

    private PermissionGrants() {
    }

    /** 1 ロールを作って {@code codes} を付与し、ユーザに割り当てる。 */
    /** 工单 API の全権限（view/create/submit/release/approve）。 */
    public static final String[] WORK_ORDER_ALL = {"production:work-order:view", "production:work-order:create",
            "production:work-order:submit", "production:work-order:release", "production:work-order:approve"};

    public static void grant(JdbcTemplate owner, long tenant, long company, long user, long base, String... codes) {
        owner.update("""
                INSERT INTO sys_role (id, tenant_id, company_id, role_code, role_name) VALUES (?, ?, ?, ?, 'test role')
                """, base, tenant, company, "TEST_" + base);
        for (int i = 0; i < codes.length; i++) {
            long menu = base + 1 + i;
            owner.update("""
                    INSERT INTO sys_menu (id, tenant_id, company_id, menu_code, menu_name, menu_type, module_code, permission_code)
                    VALUES (?, ?, ?, ?, ?, 3, 'test', ?)
                    """, menu, tenant, company, "TEST-" + menu, codes[i], codes[i]);
            owner.update("""
                    INSERT INTO sys_role_permission (id, tenant_id, company_id, role_id, menu_id, permission_code)
                    VALUES (?, ?, ?, ?, ?, ?)
                    """, menu + 500, tenant, company, base, menu, codes[i]);
        }
        owner.update("""
                INSERT INTO sys_user_role (id, tenant_id, company_id, user_id, role_id) VALUES (?, ?, ?, ?, ?)
                """, base + 999, tenant, company, user, base);
    }

    public static void cleanup(JdbcTemplate owner, long tenant) {
        owner.execute("""
                DELETE FROM sys_user_role WHERE tenant_id = %1$d;
                DELETE FROM sys_role_permission WHERE tenant_id = %1$d;
                DELETE FROM sys_menu WHERE tenant_id = %1$d AND module_code = 'test';
                DELETE FROM sys_role WHERE tenant_id = %1$d AND role_code LIKE 'TEST\\_%%';
                """.formatted(tenant));
    }
}
