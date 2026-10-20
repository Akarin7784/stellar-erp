-- pgTAP：fin_period（fin/V202610210706）结构 / RLS / 权限 / 约束 / 与 fin_publish_standard_cost 关账校验联动
BEGIN;
SELECT plan(14);

SELECT has_table('fin_period');
SELECT ok((SELECT relrowsecurity AND relforcerowsecurity FROM pg_class WHERE relname = 'fin_period'), 'ENABLE + FORCE RLS');
SELECT ok(EXISTS (SELECT 1 FROM pg_policy p JOIN pg_class c ON c.oid = p.polrelid
                   WHERE c.relname = 'fin_period' AND p.polqual IS NOT NULL AND p.polwithcheck IS NOT NULL), '策略含 USING / WITH CHECK');
SELECT is((SELECT column_default FROM information_schema.columns WHERE table_name = 'fin_period' AND column_name = 'tenant_id'),
          '(current_setting(''app.tenant_id''::text))::bigint', 'tenant_id DEFAULT current_setting');
SELECT ok((SELECT is_nullable = 'NO' AND column_default IS NULL FROM information_schema.columns
            WHERE table_name = 'fin_period' AND column_name = 'company_id'), 'company_id NOT NULL 无 DEFAULT');
SELECT ok(EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'uk_fin_period_code'
                   AND indexdef LIKE '%(tenant_id, company_id, period_code)%'), 'uk_fin_period_code 以 tenant_id 打头');
SELECT ok(has_table_privilege('erp_app', 'fin_period', 'SELECT,INSERT,UPDATE,DELETE'), 'erp_app 有 DML');
SELECT ok(has_table_privilege('erp_cost_publisher', 'fin_period', 'SELECT'), 'erp_cost_publisher 可 SELECT（关账校验）');

-- 租户 702 的期间（owner 写入）
INSERT INTO fin_period (id, tenant_id, company_id, fiscal_year, period_code, period_no, start_date, end_date, status)
VALUES (7020001, 702, 1, 2026, '2026-01', 1, DATE '2026-01-01', DATE '2026-01-31', 'OPEN');

SET ROLE erp_app;
SELECT set_config('app.tenant_id', '701', true);
INSERT INTO fin_period (id, company_id, fiscal_year, period_code, period_no, start_date, end_date, status)
VALUES (7010001, 1, 2026, '2026-01', 1, DATE '2026-01-01', DATE '2026-01-31', 'CLOSED');
SELECT is((SELECT count(*)::int FROM fin_period), 1, '租户 701 只看到自己的期间（同 period_code 不同租户可共存）');
SELECT throws_ok($$INSERT INTO fin_period (id, company_id, fiscal_year, period_code, period_no, start_date, end_date)
                   VALUES (7010002, 1, 2026, '2026-01', 1, DATE '2026-01-01', DATE '2026-01-31')$$,
                 '23505', NULL, 'uk_fin_period_code：同租户同公司同期间重复被拒');
SELECT throws_ok($$UPDATE fin_period SET status = 'DONE' WHERE id = 7010001$$, '23514', NULL, 'ck_fin_period_status 拒绝非法状态');
SELECT throws_ok($$INSERT INTO fin_period (id, tenant_id, company_id, fiscal_year, period_code, period_no, start_date, end_date)
                   VALUES (7010003, 702, 1, 2026, '2026-02', 2, DATE '2026-02-01', DATE '2026-02-28')$$,
                 '42501', NULL, 'WITH CHECK 拒绝写入其他租户');
RESET ROLE;

-- 关账期间联动：期间 2026-01 已 CLOSED → 2026-01 起的版本发布被拒 70134
INSERT INTO mdm_material_category (id, tenant_id, company_id, category_code, category_name, category_path, category_level, is_leaf, status)
VALUES (7010001, 701, 1, '9FPD', 'pgTAP fp', '/9FPD/', 1, TRUE, 1);
INSERT INTO mdm_material (id, tenant_id, company_id, material_code, material_name, material_type, category_id, spec, base_uom_code, valuation_method, status)
VALUES (7010001, 701, 1, '9FPD000001', 'fp mat', 10, 7010001, 'spec', 'PCE', 20, 1);
INSERT INTO fin_standard_cost (id, tenant_id, company_id, material_id, material_code, cost_version, period_from, cost_method, material_unit_cost, total_unit_cost)
VALUES (7010101, 701, 1, 7010001, '9FPD000001', '2026A', DATE '2026-01-01', 2, 1, 1),
       (7010102, 701, 1, 7010001, '9FPD000001', '2026B', DATE '2026-02-01', 2, 2, 2);
SET ROLE erp_app;
SELECT set_config('app.tenant_id', '701', true);
SELECT throws_ok($$SELECT fin_publish_standard_cost(7010101, 0)$$, 'P0001', '70134', '开始期间落在 CLOSED 期间 → 70134');
SELECT lives_ok($$SELECT fin_publish_standard_cost(7010102, 0)$$, '开始期间无关账期间 → 发布成功');
RESET ROLE;

SELECT * FROM finish();
ROLLBACK;
