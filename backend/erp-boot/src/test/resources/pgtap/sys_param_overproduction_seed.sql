-- pgTAP：sys_param 种子 prd.overproduction_max_rate（sys/V202610211403）
-- owner 连接执行（superuser，绕过 RLS，须显式写 tenant_id），最后 ROLLBACK。
BEGIN;
SELECT plan(16);

-- 0. 迁移本身：种租户 0 的 company_id = 0 行
SELECT is((SELECT param_value FROM sys_param WHERE tenant_id = 0 AND company_id = 0 AND param_key = 'prd.overproduction_max_rate' AND deleted = FALSE),
          '1.0000', '种租户 0 已有 overproduction_max_rate = 1.0000');

-- 准备：租户 9101（init 场景）、9102（回填场景）
INSERT INTO sys_tenant (id, tenant_id, tenant_code, tenant_name, max_user_count, status) VALUES
  (9101, 9101, 'TAP9101', 'tap 9101', 0, 1), (9102, 9102, 'TAP9102', 'tap 9102', 0, 1);
INSERT INTO sys_company (id, tenant_id, company_id, company_code, company_name, deleted) VALUES
  (910101, 9101, 910101, 'A', 'A', FALSE),
  (910102, 9101, 910102, 'B', 'B', FALSE),
  (910103, 9101, 910103, 'C', 'C', TRUE),
  (910201, 9102, 910201, 'D', 'D', FALSE),
  (910202, 9102, 910202, 'E', 'E', FALSE),
  (910203, 9102, 910203, 'F', 'F', TRUE);
-- 自定义值（不得被覆盖）
INSERT INTO sys_param (id, tenant_id, company_id, param_key, param_name, param_group, param_value, value_type) VALUES
  (9910001, 9101, 910101, 'prd.overproduction_max_rate', 'x', 'prd', '1.5000', 3),
  (9910002, 9102, 910202, 'prd.completion_over_rate',   'x', 'prd', '0.0700', 3);

-- 1. sys_init_tenant（以 erp_tenant_provisioner 调用）
SET ROLE erp_tenant_provisioner;
SELECT lives_ok($$SELECT sys_init_tenant(9101)$$, 'sys_init_tenant(9101) 成功');
SELECT lives_ok($$SELECT sys_init_tenant(9101)$$, 'sys_init_tenant 重复执行不报错');
RESET ROLE;

SELECT results_eq($$SELECT param_key::text, param_value::numeric FROM sys_param WHERE tenant_id = 9101 AND company_id = 0 AND deleted = FALSE ORDER BY 1$$,
  $$VALUES ('prd.completion_over_rate', 0.05::numeric), ('prd.overproduction_max_rate', 1.0000::numeric)$$,
  'init：company_id=0 两个参数都在');
SELECT is((SELECT param_value FROM sys_param WHERE tenant_id = 9101 AND company_id = 910102 AND param_key = 'prd.overproduction_max_rate'),
  '1.0000', 'init：公司 B overproduction_max_rate = 1.0000（4 位小数）');
SELECT is((SELECT param_value FROM sys_param WHERE tenant_id = 9101 AND company_id = 910102 AND param_key = 'prd.completion_over_rate'),
  '0.05', 'init：公司 B completion_over_rate = 0.05');
SELECT is((SELECT param_value FROM sys_param WHERE tenant_id = 9101 AND company_id = 910101 AND param_key = 'prd.overproduction_max_rate'),
  '1.5000', 'init：公司 A 自定义值不被覆盖');
SELECT is((SELECT count(*)::int FROM sys_param WHERE tenant_id = 9101 AND company_id = 910103), 0, 'init：逻辑删除的公司 C 不补');
SELECT is((SELECT count(*)::int FROM sys_param WHERE tenant_id = 9101), 6, 'init：重复执行后租户 9101 共 6 行（无重复）');
SELECT is((SELECT value_type::int || '|' || value_range || '|' || default_value FROM sys_param WHERE tenant_id = 9101 AND company_id = 910102 AND param_key = 'prd.overproduction_max_rate'),
  '3|0.0000-9.9999|1.0000', 'init：value_type=3 小数、值域、默认值');

-- 2. 回填：重新执行迁移两次（幂等）
--!include db/migration/sys/V202610211403__sys_param_overproduction_seed.sql
--!include db/migration/sys/V202610211403__sys_param_overproduction_seed.sql
SELECT is((SELECT param_value FROM sys_param WHERE tenant_id = 9102 AND company_id = 910201 AND param_key = 'prd.overproduction_max_rate'),
  '1.0000', '回填：公司 D overproduction_max_rate = 1.0000');
SELECT is((SELECT param_value FROM sys_param WHERE tenant_id = 9102 AND company_id = 910201 AND param_key = 'prd.completion_over_rate'),
  '0.05', '回填：公司 D 缺 completion_over_rate 补 0.05');
SELECT is((SELECT param_value FROM sys_param WHERE tenant_id = 9102 AND company_id = 910202 AND param_key = 'prd.completion_over_rate'),
  '0.0700', '回填：公司 E 自定义 completion_over_rate 不被覆盖');
SELECT is((SELECT count(*)::int FROM sys_param WHERE tenant_id = 9102 AND company_id = 910203), 0, '回填：逻辑删除的公司 F 不补');
SELECT is((SELECT count(*)::int FROM sys_param WHERE tenant_id = 9102), 4, '回填：执行两次后租户 9102 共 4 行（幂等）');
SELECT is((SELECT param_value FROM sys_param WHERE tenant_id = 9101 AND company_id = 910101 AND param_key = 'prd.overproduction_max_rate'),
  '1.5000', '回填：公司 A 自定义值仍为 1.5000');

SELECT * FROM finish();
ROLLBACK;
