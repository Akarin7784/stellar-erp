-- pgTAP：复合外键（sys/V202610210707）。指向 sys_/mdm_ 的 FK 必须为 (tenant_id, x_id)，跨租户引用被拒。
BEGIN;
SELECT plan(9);

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
            JOIN pg_class ic ON ic.oid = i.indexrelid JOIN pg_am am ON am.oid = ic.relam
            JOIN pg_namespace n ON n.oid = tc.relnamespace
            WHERE n.nspname = 'public' AND tc.relname ~ '^(sys|mdm|sal|fin|prd)_' AND am.amname = 'btree' AND NOT i.indisprimary AND NOT i.indisunique
              AND a.attname IS DISTINCT FROM 'tenant_id'),
          0, 'sys/mdm/sal/fin/prd 全部普通 btree 索引以 tenant_id 打头（GIN 除外）');
-- 唯一键：有 company_id 的表以 (tenant_id, company_id) 打头，无 company_id 的表以 tenant_id 打头（int 域暂不覆盖）
-- 豁免：复合 FK 被引用的 UNIQUE (tenant_id, id)；下列（表名, 索引名）租户级唯一键（已定），只放行列出的组合
SELECT is((SELECT count(*)::int FROM pg_index i
            JOIN pg_class tc ON tc.oid = i.indrelid JOIN pg_class ic ON ic.oid = i.indexrelid
            JOIN pg_namespace n ON n.oid = tc.relnamespace
            LEFT JOIN pg_attribute a0 ON a0.attrelid = tc.oid AND a0.attnum = i.indkey[0]
            LEFT JOIN pg_attribute a1 ON a1.attrelid = tc.oid AND a1.attnum = i.indkey[1]
            WHERE n.nspname = 'public' AND tc.relname ~ '^(sys|mdm|sal|fin|prd)_'
              AND i.indisunique AND NOT i.indisprimary
              AND (tc.relname, ic.relname) NOT IN (
                    ('sys_company', 'uk_sys_company_code'), ('sys_company', 'uk_sys_company_credit'),
                    ('sys_menu', 'uk_sys_menu_code'), ('sys_menu', 'uk_sys_menu_permission'),
                    ('sys_dict_type', 'uk_sys_dict_type_code'), ('sys_outbox_event', 'uk_sys_outbox_event_id'),
                    ('sys_idempotency', 'uk_sys_idempotency_key'), ('mdm_exchange_rate', 'uk_mdm_exchange_rate'))
              AND NOT (i.indnatts = 2 AND a0.attname = 'tenant_id' AND a1.attname = 'id')
              AND (a0.attname IS DISTINCT FROM 'tenant_id'
                   OR (EXISTS (SELECT 1 FROM pg_attribute c WHERE c.attrelid = tc.oid AND c.attname = 'company_id' AND NOT c.attisdropped)
                       AND a1.attname IS DISTINCT FROM 'company_id'))),
          0, '唯一键以 (tenant_id, company_id) 打头（无 company_id 的表以 tenant_id 打头）');
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
