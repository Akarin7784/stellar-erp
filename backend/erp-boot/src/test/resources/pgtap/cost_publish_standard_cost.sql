-- pgTAP：AC1-9 标准成本发布保护（mdm_material.standard_cost）。
-- 已定方案（蓝色大肥鱼 2026-10-20 定稿）：
--   * NOLOGIN 角色 erp_cost_publisher；触发器只放行 current_user = 'erp_cost_publisher'；
--   * 不使用 app.cost_publish 标记；
--   * erp_app 对 mdm_material 无表级 UPDATE，按列授权且不含 standard_cost。
-- T1（#55）已合：角色 / 触发器 / 列权限可实跑。
-- 07-finance 未合：fin_publish_standard_cost / fin_standard_cost 相关用例继续 skip。
BEGIN;
SELECT plan(10);

-- C1 正例：fin_publish_standard_cost（07-finance）
SELECT skip('07-finance fin_publish_standard_cost 未合入', 1);

-- 准备：owner 写测试物料（超户绕过 FORCE RLS；显式 tenant_id）
INSERT INTO mdm_material_category (
    id, tenant_id, company_id, category_code, category_name, category_path, category_level, is_leaf, status
) VALUES (
    990001, 101, 1, '9TAP', 'pgTAP cost', '/9TAP/', 1, TRUE, 1
);
INSERT INTO mdm_material (
    id, tenant_id, company_id, material_code, material_name, material_type, category_id,
    spec, base_uom_code, valuation_method, standard_cost, status
) VALUES (
    990001, 101, 1, '99TAP00001', 'tap cost mat', 10, 990001,
    'spec', 'PCE', 20, 10.000000, 1
);

SET ROLE erp_app;
SELECT set_config('app.tenant_id', '101', true);

-- C2 erp_app 直接改 standard_cost → 42501（列权限或触发器）
SELECT throws_ok(
    $$UPDATE mdm_material SET standard_cost = 99.000000 WHERE id = 990001$$,
    '42501',
    NULL,
    'C2 erp_app 直接 UPDATE standard_cost 被拒'
);

-- C3 先 set_config('app.cost_publish','on') 再 UPDATE → 仍 42501
SELECT set_config('app.cost_publish', 'on', true);
SELECT throws_ok(
    $$UPDATE mdm_material SET standard_cost = 88.000000 WHERE id = 990001$$,
    '42501',
    NULL,
    'C3 set_config app.cost_publish 不能绕过'
);

-- C4 / C5 / C6 权限目录
SELECT ok(NOT has_table_privilege('erp_app', 'mdm_material', 'UPDATE'),
          'C4 erp_app 无表级 UPDATE');
SELECT ok(NOT has_column_privilege('erp_app', 'mdm_material', 'standard_cost', 'UPDATE'),
          'C5 erp_app 无 standard_cost 列 UPDATE');
SELECT ok(has_column_privilege('erp_app', 'mdm_material', 'material_name', 'UPDATE'),
          'C6 erp_app 可 UPDATE material_name');

RESET ROLE;

-- C7 角色 NOLOGIN（fin_publish owner/prosecdef/search_path 等 07-finance）
SELECT ok(
    EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'erp_cost_publisher' AND NOT rolcanlogin),
    'C7 erp_cost_publisher 存在且 NOLOGIN'
);

-- C8 / C9 发布角色列权限
SELECT ok(has_column_privilege('erp_cost_publisher', 'mdm_material', 'standard_cost', 'UPDATE'),
          'C8 erp_cost_publisher 可 UPDATE standard_cost');
SELECT ok(
    has_column_privilege('erp_cost_publisher', 'mdm_material', 'id', 'SELECT')
    AND has_column_privilege('erp_cost_publisher', 'mdm_material', 'tenant_id', 'SELECT')
    AND has_column_privilege('erp_cost_publisher', 'mdm_material', 'company_id', 'SELECT'),
    'C9 erp_cost_publisher SELECT id/tenant_id/company_id'
);

-- C10 fin_standard_cost SELECT（07-finance）
SELECT skip('07-finance fin_standard_cost 未合入', 1);

SELECT * FROM finish();
ROLLBACK;
