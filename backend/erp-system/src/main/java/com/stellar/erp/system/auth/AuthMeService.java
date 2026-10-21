package com.stellar.erp.system.auth;

import java.util.List;
import java.util.TreeSet;

import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.stellar.erp.common.BizException;
import com.stellar.erp.common.LoginContext;
import com.stellar.erp.system.UserPermissionService;

/**
 * {@code GET /api/system/auth/me}（01/91 #4）：ログインユーザ・ロール・権限コード（コードで重複排除、94 §2.10）。
 * ロール・権限は session の会社（{@code sys_user_role.company_id}）のもののみ。
 *
 * <p>sys_user は現状 V1 baseline の列（username / nickname）のみ。01/90 の正式列（user_code・real_name・
 * department 等）は sys_user 正式迁移後に追加する。dataScopes は対象外。</p>
 *
 * <p>menus：session の会社で付与された（有効なロール経由の）メニュー（ボタン menu_type=3 を除く）と、
 * その祖先ディレクトリ（menu_type=1）。ID は Long（Jackson で文字列化）。</p>
 */
@Service
public class AuthMeService {

    public record UserInfo(long id, String username, String nickname) {
    }

    public record RoleInfo(String roleCode, String roleName) {
    }

    public record MenuInfo(Long id, Long parentId, int menuType, String menuCode, String routePath, int sortNo) {
    }

    public record Me(UserInfo userInfo, long companyId, List<RoleInfo> roles, List<String> permissions,
                     List<MenuInfo> menus) {
    }

    private final JdbcClient jdbc;
    private final UserPermissionService permissions;

    public AuthMeService(JdbcClient jdbc, UserPermissionService permissions) {
        this.jdbc = jdbc;
        this.permissions = permissions;
    }

    @Transactional(readOnly = true)
    public Me me() {
        LoginContext.LoginUser login = LoginContext.require();
        UserInfo user = jdbc.sql("SELECT id, username, nickname FROM sys_user WHERE id = :id AND deleted = FALSE")
                .param("id", login.userId())
                .query((rs, i) -> new UserInfo(rs.getLong(1), rs.getString(2), rs.getString(3)))
                .optional()
                .orElseThrow(() -> new BizException(2001, "MSG-COM-020", "登录已过期，请重新登录。"));
        List<RoleInfo> roles = jdbc.sql("""
                        SELECT DISTINCT r.role_code, r.role_name
                          FROM sys_user_role ur
                          JOIN sys_role r
                            ON r.id = ur.role_id AND r.tenant_id = ur.tenant_id AND r.deleted = FALSE AND r.status = 1
                         WHERE ur.user_id = :user AND ur.company_id = :company AND ur.status = 1
                           AND (ur.valid_from IS NULL OR ur.valid_from <= CURRENT_DATE)
                           AND (ur.valid_to IS NULL OR ur.valid_to >= CURRENT_DATE)
                         ORDER BY r.role_code
                        """)
                .param("user", login.userId()).param("company", login.companyId())
                .query((rs, i) -> new RoleInfo(rs.getString(1), rs.getString(2))).list();
        List<String> codes = List.copyOf(new TreeSet<>(permissions.permissionCodes(login.userId(), login.companyId())));
        List<MenuInfo> menus = jdbc.sql("""
                        WITH RECURSIVE granted AS (
                            SELECT DISTINCT m.id, m.parent_id
                              FROM sys_user_role ur
                              JOIN sys_role r
                                ON r.id = ur.role_id AND r.tenant_id = ur.tenant_id AND r.deleted = FALSE AND r.status = 1
                              JOIN sys_role_permission rp ON rp.role_id = r.id AND rp.tenant_id = r.tenant_id
                              JOIN sys_menu m
                                ON m.id = rp.menu_id AND m.tenant_id = rp.tenant_id
                               AND m.deleted = FALSE AND m.status = 1 AND m.menu_type <> 3
                             WHERE ur.user_id = :user AND ur.company_id = :company AND ur.status = 1
                               AND (ur.valid_from IS NULL OR ur.valid_from <= CURRENT_DATE)
                               AND (ur.valid_to IS NULL OR ur.valid_to >= CURRENT_DATE)
                        ), tree AS (
                            SELECT id, parent_id FROM granted
                            UNION
                            SELECT p.id, p.parent_id
                              FROM tree t
                              JOIN sys_menu p ON p.id = t.parent_id AND p.deleted = FALSE AND p.menu_type = 1
                        )
                        SELECT m.id, m.parent_id, m.menu_type, m.menu_code, m.route_path, m.sort_no
                          FROM sys_menu m
                         WHERE m.id IN (SELECT id FROM tree)
                         ORDER BY m.sort_no, m.id
                        """)
                .param("user", login.userId()).param("company", login.companyId())
                .query((rs, i) -> new MenuInfo(rs.getLong(1), rs.getLong(2), rs.getInt(3), rs.getString(4),
                        rs.getString(5), rs.getInt(6)))
                .list();
        return new Me(user, login.companyId(), roles, codes, menus);
    }
}
