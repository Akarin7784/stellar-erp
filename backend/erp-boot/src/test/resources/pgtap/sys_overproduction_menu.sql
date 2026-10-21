-- pgTAP：超产审批菜单/权限增量（sys/V202610211406、V202610211407；01-system/94 G-11、付录 A #397〜#401）
-- owner 连接执行（superuser，绕过 RLS），最后 ROLLBACK。
BEGIN;
SELECT plan(21);

CREATE TEMP TABLE t_codes(code text) ON COMMIT DROP;
INSERT INTO t_codes VALUES ('production:overproduction-approval:view'), ('production:overproduction-approval:create'),
  ('production:overproduction-approval:submit'), ('production:overproduction-approval:approve'), ('production:overproduction-approval:cancel');

-- 0. 迁移回填后的租户 0（模板）
SELECT is((SELECT count(*)::int FROM sys_menu WHERE tenant_id = 0 AND deleted = FALSE), 594, '租户 0：sys_menu 594 行');
SELECT is((SELECT count(*)::int FROM sys_menu WHERE tenant_id = 0 AND permission_code IS NOT NULL), 584, '租户 0：有 permission_code 584 行');
SELECT is((SELECT count(DISTINCT permission_code)::int FROM sys_menu WHERE tenant_id = 0), 518, '租户 0：不同权限码 518 个');
SELECT results_eq($$SELECT menu_code::text, menu_type::int, route_path::text, sort_no::int, is_visible, company_id::bigint,
                           (SELECT p.menu_code::text FROM sys_menu p WHERE p.tenant_id = 0 AND p.id = m.parent_id)
                      FROM sys_menu m WHERE tenant_id = 0 AND menu_code = 'SCR-PRD-034'$$,
                  $$VALUES ('SCR-PRD-034', 2, 'production/overproduction-approvals', 340, TRUE, 0::bigint, 'DIR-PRD')$$,
                  'SCR-PRD-034：菜单、路径、sort 340、显示、company_id 0、父 DIR-PRD');
SELECT results_eq($$SELECT permission_code::text, sort_no::int FROM sys_menu m
                     WHERE tenant_id = 0 AND menu_type = 3
                       AND parent_id = (SELECT id FROM sys_menu WHERE tenant_id = 0 AND menu_code = 'SCR-PRD-034') ORDER BY sort_no$$,
                  $$VALUES ('production:overproduction-approval:approve', 1), ('production:overproduction-approval:cancel', 2),
                           ('production:overproduction-approval:create', 3), ('production:overproduction-approval:submit', 4)$$,
                  'SCR-PRD-034 下 4 个按钮（approve/cancel/create/submit）');
SELECT is((SELECT id FROM sys_menu WHERE tenant_id = 0 AND menu_code = 'SCR-PRD-034'), sys_seed_id('sys_menu:0:SCR-PRD-034'), 'ID = sys_seed_id');
SELECT is((SELECT count(*)::int FROM sys_menu_seed_rows()), 594, 'sys_menu_seed_rows() = 594 行');

-- 1. 一次性回填函数已由 V202610211407 删除
SELECT hasnt_function('public', 'sys_apply_overproduction_menu', ARRAY[]::name[], 'sys_apply_overproduction_menu() 已删除（V202610211407）');

-- 2. 迁移后的现有状态：所有现有 SYSTEM_ADMIN 都持有 5 个新码（状态检查，代替调用已删除的回填函数）
SELECT is((SELECT count(*)::int FROM sys_role r WHERE r.role_code = 'SYSTEM_ADMIN' AND r.deleted = FALSE
            AND (SELECT count(*) FROM sys_role_permission rp WHERE rp.tenant_id = r.tenant_id AND rp.role_id = r.id
                  AND rp.permission_code IN (SELECT code FROM t_codes)) <> 5), 0,
          '回填后：现有 SYSTEM_ADMIN 无一缺少 5 个新码');
SELECT is((SELECT count(DISTINCT tenant_id)::int FROM sys_menu WHERE menu_code = 'DIR-PRD' AND deleted = FALSE),
          (SELECT count(DISTINCT tenant_id)::int FROM sys_menu WHERE menu_code = 'SCR-PRD-034' AND deleted = FALSE),
          '回填后：有付录 A 菜单的租户都有 SCR-PRD-034');

-- 3. 迁移后新建租户 9301 / 公司 930101：sys_init_tenant 得到 594 菜单、584 授权
INSERT INTO sys_tenant (id, tenant_id, tenant_code, tenant_name, max_user_count, status) VALUES (9301, 9301, 'TAP9301', 'tap 9301', 0, 1);
INSERT INTO sys_company (id, tenant_id, company_id, company_code, company_name, deleted) VALUES (930101, 9301, 930101, 'A', 'A', FALSE);
SET ROLE erp_tenant_provisioner;
SELECT lives_ok($$SELECT sys_init_tenant(9301)$$, 'sys_init_tenant(9301) 成功');
RESET ROLE;
SELECT results_eq($$SELECT (SELECT count(*)::int FROM sys_menu WHERE tenant_id = 9301),
                           (SELECT count(*)::int FROM sys_role_permission WHERE tenant_id = 9301 AND company_id = 930101)$$,
                  $$VALUES (594, 584)$$, '新租户：菜单 594 / 公司 A 授权 584');
SELECT set_eq($$SELECT permission_code::text FROM sys_role_permission WHERE tenant_id = 9301 AND company_id = 930101
                 AND permission_code LIKE 'production:overproduction-approval:%'$$,
              $$SELECT code FROM t_codes$$, '新租户公司 A 的 SYSTEM_ADMIN 含 5 个新码');

-- 撤销一条旧授权与一条新码授权后重跑：行数不变、撤销保持
DELETE FROM sys_role_permission WHERE tenant_id = 9301 AND company_id = 930101
   AND permission_code IN ('system:company:create', 'production:overproduction-approval:cancel');
CREATE TEMP VIEW v_cnt AS SELECT (SELECT count(*) FROM sys_menu) AS menus, (SELECT count(*) FROM sys_role_permission) AS grants,
                                 (SELECT count(*) FROM sys_role) AS roles;
CREATE TEMP TABLE t_before AS SELECT * FROM v_cnt;
SET ROLE erp_tenant_provisioner;
SELECT lives_ok($$SELECT sys_init_tenant(9301)$$, 'sys_init_tenant(9301) 重跑成功');
RESET ROLE;
SELECT results_eq($$SELECT * FROM v_cnt$$, $$SELECT * FROM t_before$$, '重跑：sys_menu / sys_role_permission / sys_role 行数不变');
SELECT is((SELECT count(*)::int FROM sys_role_permission WHERE tenant_id = 9301 AND company_id = 930101), 582, '撤销保持：授权 582');
SELECT ok(NOT EXISTS (SELECT 1 FROM sys_role_permission WHERE tenant_id = 9301 AND company_id = 930101
                       AND permission_code IN ('system:company:create', 'production:overproduction-approval:cancel')),
          '撤销的旧码与新码均未被补回');

-- 4. 迁移后新建公司：sys_init_company 授予全部有 permission_code 的菜单（584）
INSERT INTO sys_company (id, tenant_id, company_id, company_code, company_name, deleted) VALUES (930102, 9301, 930102, 'B', 'B', FALSE);
SET ROLE erp_app;
SELECT set_config('app.tenant_id', '9301', true);
SELECT lives_ok($$SELECT sys_init_company(9301, 930102)$$, 'erp_app：新公司 sys_init_company 成功');
RESET ROLE;
SELECT is((SELECT count(*)::int FROM sys_role_permission WHERE tenant_id = 9301 AND company_id = 930102),
          (SELECT count(*)::int FROM sys_menu WHERE tenant_id = 9301 AND deleted = FALSE AND permission_code IS NOT NULL),
          '新公司授权数 = 带 permission_code 的 sys_menu 行数');
SELECT is((SELECT count(*)::int FROM sys_role_permission WHERE tenant_id = 9301 AND company_id = 930102), 584, '新公司授权 584 行');
SELECT is((SELECT count(*)::int FROM sys_role_permission WHERE tenant_id = 9301 AND company_id = 930102
            AND permission_code IN (SELECT code FROM t_codes)), 5, '新公司含 5 个超产码');

SELECT * FROM finish();
ROLLBACK;
