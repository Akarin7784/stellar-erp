-- pgTAP：复合外键（sys/V202610210707）。指向 sys_/mdm_ 的 FK 必须为 (tenant_id, x_id)，跨租户引用被拒。
BEGIN;
SELECT plan(8);

SELECT is((SELECT count(*)::int FROM pg_constraint k JOIN pg_class r ON r.oid = k.confrelid
            WHERE k.contype = 'f' AND array_length(k.conkey, 1) = 1 AND r.relname ~ '^(sys|mdm)_'),
          0, '指向 sys_/mdm_ 的单列外键为 0');
SELECT is((SELECT count(*)::int FROM pg_constraint k JOIN pg_class r ON r.oid = k.confrelid
            JOIN pg_attribute a ON a.attrelid = k.conrelid AND a.attnum = k.conkey[1]
            JOIN pg_attribute b ON b.attrelid = k.confrelid AND b.attnum = k.confkey[1]
            WHERE k.contype = 'f' AND r.relname ~ '^(sys|mdm)_'
              AND NOT (array_length(k.conkey, 1) = 2 AND a.attname = 'tenant_id' AND b.attname = 'tenant_id')),
          0, '指向 sys_/mdm_ 的外键全部以 (tenant_id, …) → (tenant_id, id)');
SELECT ok(EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'uk_mdm_material_tenant_id' AND contype = 'u'),
          'mdm_material 有 uk_mdm_material_tenant_id UNIQUE (tenant_id, id)');

SELECT is((SELECT count(*)::int FROM pg_index i JOIN pg_class tc ON tc.oid = i.indrelid
            LEFT JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = i.indkey[0]
            WHERE tc.relname LIKE 'prd\_%' AND NOT i.indisprimary AND NOT i.indisunique AND a.attname IS DISTINCT FROM 'tenant_id'),
          0, 'prd_ 全部普通索引以 tenant_id 打头');
SELECT ok(EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_prd_bom_effective'
                   AND indexdef LIKE '%(tenant_id, company_id, effective_status, valid_from, valid_to)%'),
          'idx_prd_bom_effective = (tenant_id, company_id, effective_status, valid_from, valid_to)');

-- 准备（owner）：租户 801 / 802 各一个物料
INSERT INTO mdm_material_category (id, tenant_id, company_id, category_code, category_name, category_path, category_level, is_leaf, status)
VALUES (8010001, 801, 1, '9CFK', 'cfk', '/9CFK/', 1, TRUE, 1),
       (8020001, 802, 1, '9CFK', 'cfk', '/9CFK/', 1, TRUE, 1);
INSERT INTO mdm_material (id, tenant_id, company_id, material_code, material_name, material_type, category_id, spec, base_uom_code, valuation_method, status)
VALUES (8010001, 801, 1, '9CFK000001', 'cfk 801', 10, 8010001, 's', 'PCE', 20, 1),
       (8020001, 802, 1, '9CFK000001', 'cfk 802', 10, 8020001, 's', 'PCE', 20, 1);

SET ROLE erp_app;
SELECT set_config('app.tenant_id', '801', true);
SELECT throws_ok($$INSERT INTO fin_standard_cost (id, company_id, material_id, material_code, cost_version, period_from, cost_method, material_unit_cost, total_unit_cost)
                   VALUES (8010101, 1, 8020001, '9CFK000001', '2026A', DATE '2026-01-01', 2, 1, 1)$$,
                 '23503', NULL, '租户 801 的行引用租户 802 的 mdm_material.id → 23503');
SELECT throws_ok($$INSERT INTO mdm_material (id, company_id, material_code, material_name, material_type, category_id, spec, base_uom_code, valuation_method, status)
                   VALUES (8010002, 1, '9CFK000002', 'x', 10, 8020001, 's', 'PCE', 20, 1)$$,
                 '23503', NULL, 'mdm 内部：租户 801 物料引用租户 802 分类 → 23503');
SELECT lives_ok($$INSERT INTO fin_standard_cost (id, company_id, material_id, material_code, cost_version, period_from, cost_method, material_unit_cost, total_unit_cost)
                  VALUES (8010102, 1, 8010001, '9CFK000001', '2026A', DATE '2026-01-01', 2, 1, 1)$$,
                '同租户引用可写入');
RESET ROLE;

SELECT * FROM finish();
ROLLBACK;
