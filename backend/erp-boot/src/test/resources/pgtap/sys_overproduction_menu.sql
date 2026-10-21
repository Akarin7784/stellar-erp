-- pgTAP：超产审批菜单/权限增量（sys/V202610211406；01-system/94 G-11、付录 A #397〜#401）
-- owner 连接执行（superuser，绕过 RLS），最后 ROLLBACK。
BEGIN;
SELECT plan(19);

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

-- 1. 模拟迁移前的现有公司：租户 9301 / 公司 930101 按 V1405 状态（无 5 行菜单与授权），且撤销过一条旧授权
INSERT INTO sys_tenant (id, tenant_id, tenant_code, tenant_name, max_user_count, status) VALUES (9301, 9301, 'TAP9301', 'tap 9301', 0, 1);
INSERT INTO sys_company (id, tenant_id, company_id, company_code, company_name, deleted) VALUES (930101, 9301, 930101, 'A', 'A', FALSE);
SET ROLE erp_tenant_provisioner;
SELECT sys_init_tenant(9301);
RESET ROLE;
DELETE FROM sys_role_permission WHERE tenant_id = 9301
   AND menu_id IN (SELECT id FROM sys_menu WHERE tenant_id = 9301 AND permission_code IN (SELECT code FROM t_codes));
DELETE FROM sys_menu WHERE tenant_id = 9301 AND menu_code = 'SCR-PRD-034' OR (tenant_id = 9301 AND permission_code IN (SELECT code FROM t_codes));
DELETE FROM sys_role_permission WHERE tenant_id = 9301 AND company_id = 930101 AND permission_code = 'system:company:create';
SELECT results_eq($$SELECT (SELECT count(*)::int FROM sys_menu WHERE tenant_id = 9301),
                           (SELECT count(*)::int FROM sys_role_permission WHERE tenant_id = 9301 AND company_id = 930101)$$,
                  $$VALUES (589, 578)$$, '准备：迁移前状态 菜单 589 / 授权 578（撤销 1 条）');

-- 2. 增量回填
SELECT lives_ok($$SELECT sys_apply_overproduction_menu()$$, 'sys_apply_overproduction_menu() 成功');
SELECT is((SELECT count(*)::int FROM sys_menu WHERE tenant_id = 9301), 594, '现有租户补入 5 行菜单 → 594');
SELECT set_eq($$SELECT rp.permission_code::text FROM sys_role_permission rp JOIN sys_role r ON r.id = rp.role_id
                 WHERE rp.tenant_id = 9301 AND rp.company_id = 930101 AND r.role_code = 'SYSTEM_ADMIN'
                   AND rp.permission_code LIKE 'production:overproduction-approval:%'$$,
              $$SELECT code FROM t_codes$$, '现有公司 SYSTEM_ADMIN 得到 5 个新码');
SELECT is((SELECT count(*)::int FROM sys_role_permission WHERE tenant_id = 9301 AND company_id = 930101), 583, '现有公司授权 578 + 5 = 583');
SELECT ok(NOT EXISTS (SELECT 1 FROM sys_role_permission WHERE tenant_id = 9301 AND company_id = 930101 AND permission_code = 'system:company:create'),
          '撤销过的 system:company:create 未被补回');
SELECT is((SELECT count(*)::int FROM sys_role_permission rp WHERE rp.tenant_id = 9301 AND rp.menu_id <> ALL (
             SELECT id FROM sys_menu WHERE tenant_id = 9301 AND permission_code IN (SELECT code FROM t_codes)) ), 578, '旧授权 578 条不变');

-- 3. 重跑冪等
CREATE TEMP VIEW v_cnt AS SELECT (SELECT count(*) FROM sys_menu) AS menus, (SELECT count(*) FROM sys_role_permission) AS grants,
                                 (SELECT count(*) FROM sys_role) AS roles;
CREATE TEMP TABLE t_before AS SELECT * FROM v_cnt;
SELECT sys_apply_overproduction_menu();
SELECT results_eq($$SELECT * FROM v_cnt$$, $$SELECT * FROM t_before$$, '重跑：sys_menu / sys_role_permission / sys_role 行数不变');

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
