-- pgTAP：菜单/权限/SYSTEM_ADMIN 种子（sys/V202610211405；01-system/94 §2.10、付录 A）
-- owner 连接执行（superuser，绕过 RLS，须显式写 tenant_id），最后 ROLLBACK。
BEGIN;
SELECT plan(33);

-- 0. 迁移回填：种租户 0 已有付录 A 的全部菜单
SELECT is((SELECT count(*)::int FROM sys_menu WHERE tenant_id = 0 AND deleted = FALSE), 589, '回填：租户 0 的 sys_menu = 589 行');

-- 准备：租户 9201（A、B 公司，C 已删除）、9202（D 公司）
INSERT INTO sys_tenant (id, tenant_id, tenant_code, tenant_name, max_user_count, status) VALUES
  (9201, 9201, 'TAP9201', 'tap 9201', 0, 1), (9202, 9202, 'TAP9202', 'tap 9202', 0, 1);
INSERT INTO sys_company (id, tenant_id, company_id, company_code, company_name, deleted) VALUES
  (920101, 9201, 920101, 'A', 'A', FALSE),
  (920102, 9201, 920102, 'B', 'B', FALSE),
  (920103, 9201, 920103, 'C', 'C', TRUE),
  (920201, 9202, 920201, 'D', 'D', FALSE);

-- 1. sys_init_tenant（以 erp_tenant_provisioner 调用）
SET ROLE erp_tenant_provisioner;
SELECT lives_ok($$SELECT sys_init_tenant(9201)$$, 'sys_init_tenant(9201) 成功');
RESET ROLE;

SELECT is((SELECT count(*)::int FROM sys_menu WHERE tenant_id = 9201), 589, '菜单 589 行');
SELECT is((SELECT count(*)::int FROM sys_menu WHERE tenant_id = 9201 AND company_id <> 0), 0, '菜单全部 company_id = 0');
SELECT is((SELECT count(*)::int FROM sys_menu WHERE tenant_id = 9201 AND permission_code IS NOT NULL), 579, '有 permission_code 的菜单 579 行');
SELECT is((SELECT count(DISTINCT permission_code)::int FROM sys_menu WHERE tenant_id = 9201), 513, '不同权限码 513 个');
SELECT results_eq($$SELECT menu_type::int, count(*)::int FROM sys_menu WHERE tenant_id = 9201 GROUP BY 1 ORDER BY 1$$,
                  $$VALUES (1, 10), (2, 339), (3, 240)$$, '目录 10 / 菜单 339 / 按钮 240');
SELECT is((SELECT count(*)::int FROM sys_menu WHERE tenant_id = 9201 AND menu_type = 2 AND is_visible), 174, '显示菜单 174 行');
SELECT is((SELECT count(*)::int FROM sys_menu c WHERE c.tenant_id = 9201 AND c.parent_id <> 0
            AND NOT EXISTS (SELECT 1 FROM sys_menu p WHERE p.tenant_id = 9201 AND p.id = c.parent_id)), 0, 'parent_id 全部解决到同租户菜单');
SELECT is((SELECT p.menu_code::text FROM sys_menu c JOIN sys_menu p ON p.tenant_id = c.tenant_id AND p.id = c.parent_id
            WHERE c.tenant_id = 9201 AND c.menu_code = 'SCR-SYS-004'), 'DIR-SYS', 'SCR-SYS-004 的父菜单 = DIR-SYS');
SELECT is((SELECT route_path::text FROM sys_menu WHERE tenant_id = 9201 AND menu_code = 'SCR-SYS-004'), 'system/users', 'route_path 不带开头的 /');
SELECT ok(EXISTS (SELECT 1 FROM sys_menu WHERE tenant_id = 9201 AND permission_code = 'system:company:create'), '菜单含 system:company:create');

SELECT is((SELECT count(*)::int FROM sys_role WHERE tenant_id = 9201 AND role_code = 'SYSTEM_ADMIN' AND deleted = FALSE), 2,
          '每个未删除公司一个 SYSTEM_ADMIN（A、B）');
SELECT is((SELECT count(*)::int FROM sys_role WHERE tenant_id = 9201 AND company_id = 920103), 0, '已删除公司 C 不建角色');
SELECT results_eq($$SELECT role_name::text, role_type::int, data_scope_type::int, requires_approval FROM sys_role
                     WHERE tenant_id = 9201 AND company_id = 920101 AND role_code = 'SYSTEM_ADMIN'$$,
                  $$VALUES ('系统管理员', 1, 1, TRUE)$$, 'SYSTEM_ADMIN 属性（内置、全社、需审批）');
SELECT is((SELECT count(*)::int FROM sys_role_permission WHERE tenant_id = 9201 AND company_id = 920101), 579, '公司 A 授权 579 条');
SELECT ok(EXISTS (SELECT 1 FROM sys_role_permission WHERE tenant_id = 9201 AND company_id = 920101 AND permission_code = 'system:company:create'),
          '公司 A 已授予 system:company:create');
SELECT is((SELECT count(*)::int FROM sys_param WHERE tenant_id = 9201 AND company_id = 920102 AND deleted = FALSE), 2, '公司 B 的 sys_param 默认 2 行');

-- 2. 撤销一条授权 + 改一个菜单名后重跑：行数不变、撤销保持、已有值不覆盖
DELETE FROM sys_role_permission WHERE tenant_id = 9201 AND company_id = 920101 AND permission_code = 'system:company:create';
UPDATE sys_menu SET menu_name = '自定义' WHERE tenant_id = 9201 AND menu_code = 'SCR-SYS-004';
SET ROLE erp_tenant_provisioner;
SELECT lives_ok($$SELECT sys_init_tenant(9201)$$, 'sys_init_tenant 重跑不报错');
RESET ROLE;
SELECT is((SELECT count(*)::int FROM sys_menu WHERE tenant_id = 9201), 589, '重跑后菜单仍 589 行');
SELECT is((SELECT menu_name::text FROM sys_menu WHERE tenant_id = 9201 AND menu_code = 'SCR-SYS-004'), '自定义', '重跑不覆盖已有菜单');
SELECT is((SELECT count(*)::int FROM sys_role_permission WHERE tenant_id = 9201 AND company_id = 920101), 578, '重跑后公司 A 授权仍 578 条（撤销保持）');
SELECT ok(NOT EXISTS (SELECT 1 FROM sys_role_permission WHERE tenant_id = 9201 AND company_id = 920101 AND permission_code = 'system:company:create'),
          '撤销的 system:company:create 未被补回');
SELECT is((SELECT count(*)::int FROM sys_role WHERE tenant_id = 9201 AND role_code = 'SYSTEM_ADMIN'), 2, '重跑后 SYSTEM_ADMIN 仍 2 个');

-- 3. 以 erp_app 调用 sys_init_company（租户 9202 尚未初始化菜单；先用 provisioner 种菜单）
SET ROLE erp_tenant_provisioner;
SELECT sys_init_tenant(9202);
RESET ROLE;
DELETE FROM sys_role_permission WHERE tenant_id = 9202;
DELETE FROM sys_role WHERE tenant_id = 9202;
SET ROLE erp_app;
SELECT set_config('app.tenant_id', '9202', true);
SELECT throws_like($$SELECT sys_init_company(9201, 920101)$$, '%不一致%', 'erp_app：p_tenant_id 与 app.tenant_id 不一致 → 报错');
SELECT throws_like($$SELECT sys_init_company(9202, 920101)$$, '%不存在%', 'erp_app：传入别的租户的公司 → 报错');
RESET ROLE;
INSERT INTO sys_company (id, tenant_id, company_id, company_code, company_name, deleted) VALUES (920202, 9202, 920202, 'E', 'E', TRUE);
SET ROLE erp_app;
SELECT set_config('app.tenant_id', '9202', true);
SELECT throws_like($$SELECT sys_init_company(9202, 920202)$$, '%不存在%', 'erp_app：传入已删除的公司 → 报错');
SELECT lives_ok($$SELECT sys_init_company(9202, 920201)$$, 'erp_app：本租户公司调用成功');
SELECT lives_ok($$SELECT sys_init_company(9202, 920201)$$, 'erp_app：重复调用成功');
RESET ROLE;
SELECT results_eq($$SELECT (SELECT count(*)::int FROM sys_role WHERE tenant_id = 9202 AND role_code = 'SYSTEM_ADMIN'),
                           (SELECT count(*)::int FROM sys_role_permission WHERE tenant_id = 9202),
                           (SELECT count(*)::int FROM sys_role WHERE tenant_id = 9201)$$,
                  $$VALUES (1, 579, 2)$$, 'erp_app 两次调用后：角色 1、授权 579，未写别的租户');

-- 4. 索引与函数属性
SELECT ok(EXISTS (SELECT 1 FROM pg_index i JOIN pg_class c ON c.oid = i.indexrelid
                   WHERE c.relname = 'idx_sys_menu_permission' AND NOT i.indisunique)
          AND NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = 'uk_sys_menu_permission'),
          'idx_sys_menu_permission 为非唯一索引，uk_sys_menu_permission 已删除');
SELECT is((SELECT pg_get_constraintdef(oid) FROM pg_constraint WHERE conname = 'fk_sys_role_permission_menu'),
          'FOREIGN KEY (tenant_id, menu_id) REFERENCES sys_menu(tenant_id, id)', 'fk_sys_role_permission_menu 为 (tenant_id, menu_id) 2 列');
SELECT ok((SELECT p.prosecdef AND p.proconfig @> ARRAY['search_path=pg_catalog, public']
             AND NOT has_function_privilege('public', p.oid, 'EXECUTE')
             AND has_function_privilege('erp_app', p.oid, 'EXECUTE')
             AND has_function_privilege('erp_tenant_provisioner', p.oid, 'EXECUTE')
             FROM pg_proc p WHERE p.oid = 'public.sys_init_company(bigint, bigint)'::regprocedure),
          'sys_init_company：SECURITY DEFINER、search_path 固定、PUBLIC 无 EXECUTE、erp_app/provisioner 有');

SELECT * FROM finish();
ROLLBACK;
