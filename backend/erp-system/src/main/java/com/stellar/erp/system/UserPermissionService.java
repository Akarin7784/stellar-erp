package com.stellar.erp.system;

import java.util.Set;

import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 当前用户的权限码（01-system：sys_user_role → sys_role → sys_role_permission.permission_code）。
 *
 * <p>租户由 RLS（事务内 {@code app.tenant_id}）限定。只计入有效的角色分配（status = 1、在 valid_from〜valid_to 内）
 * 与有效未删除的角色（status = 1、deleted = FALSE）。按公司过滤 {@code sys_user_role.company_id}。</p>
 */
@Service
public class UserPermissionService {

    private final JdbcClient jdbc;

    public UserPermissionService(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Transactional(readOnly = true)
    public Set<String> permissionCodes(long userId, long companyId) {
        return Set.copyOf(jdbc.sql("""
                        SELECT DISTINCT rp.permission_code
                          FROM sys_user_role ur
                          JOIN sys_role r
                            ON r.id = ur.role_id AND r.tenant_id = ur.tenant_id AND r.deleted = FALSE AND r.status = 1
                          JOIN sys_role_permission rp
                            ON rp.role_id = r.id AND rp.tenant_id = r.tenant_id
                         WHERE ur.user_id = :user
                           AND ur.company_id = :company
                           AND ur.status = 1
                           AND (ur.valid_from IS NULL OR ur.valid_from <= CURRENT_DATE)
                           AND (ur.valid_to IS NULL OR ur.valid_to >= CURRENT_DATE)
                        """)
                .param("user", userId).param("company", companyId)
                .query(String.class).list());
    }
}
