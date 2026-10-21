-- pgTAP：同域父子表复合外键（sys/V202610211401）。prd_/sal_ 同域外键必须为 (tenant_id, company_id, x_id) → (tenant_id, company_id, id)，跨公司引用被拒。
BEGIN;
SELECT plan(7);

SELECT is((SELECT count(*)::int FROM pg_constraint k JOIN pg_class c ON c.oid = k.conrelid JOIN pg_class p ON p.oid = k.confrelid
            JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE k.contype = 'f' AND n.nspname = 'public' AND c.relname ~ '^(prd|sal)_'
              AND split_part(c.relname, '_', 1) = split_part(p.relname, '_', 1)
              AND array_length(k.conkey, 1) = 1),
          0, 'prd_/sal_ 同域单列外键为 0');
SELECT is((SELECT count(*)::int FROM pg_constraint k JOIN pg_class c ON c.oid = k.conrelid JOIN pg_class p ON p.oid = k.confrelid
            JOIN pg_namespace n ON n.oid = c.relnamespace
            JOIN pg_attribute a0 ON a0.attrelid = k.conrelid AND a0.attnum = k.conkey[1]
            JOIN pg_attribute a1 ON a1.attrelid = k.conrelid AND a1.attnum = k.conkey[2]
            JOIN pg_attribute b0 ON b0.attrelid = k.confrelid AND b0.attnum = k.confkey[1]
            JOIN pg_attribute b1 ON b1.attrelid = k.confrelid AND b1.attnum = k.confkey[2]
            JOIN pg_attribute b2 ON b2.attrelid = k.confrelid AND b2.attnum = k.confkey[3]
            WHERE k.contype = 'f' AND n.nspname = 'public' AND c.relname ~ '^(prd|sal)_'
              AND split_part(c.relname, '_', 1) = split_part(p.relname, '_', 1)
              AND array_length(k.conkey, 1) = 3
              AND a0.attname = 'tenant_id' AND a1.attname = 'company_id'
              AND b0.attname = 'tenant_id' AND b1.attname = 'company_id' AND b2.attname = 'id'),
          74, 'prd_/sal_ 同域外键 74 处全部为 (tenant_id, company_id, x_id) → (tenant_id, company_id, id)');
SELECT is((SELECT pg_get_constraintdef(oid) FROM pg_constraint WHERE conname = 'fk_prd_bom_line_bom'),
          'FOREIGN KEY (tenant_id, company_id, bom_id) REFERENCES prd_bom(tenant_id, company_id, id) ON DELETE RESTRICT',
          'fk_prd_bom_line_bom 保留约束名与 ON DELETE RESTRICT');
SELECT is((SELECT pg_get_constraintdef(oid) FROM pg_constraint WHERE conname = 'fk_sal_sales_order_line_o'),
          'FOREIGN KEY (tenant_id, company_id, sales_order_id) REFERENCES sal_sales_order(tenant_id, company_id, id)',
          'fk_sal_sales_order_line_o 保留约束名与 NO ACTION');
SELECT ok(EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'uk_prd_bom_tenant_company_id' AND contype = 'u'
                   AND pg_get_constraintdef(oid) = 'UNIQUE (tenant_id, company_id, id)'),
          'prd_bom 有 uk_prd_bom_tenant_company_id UNIQUE (tenant_id, company_id, id)');

-- 准备（owner）：租户 803 的工厂 + 公司 1 的 MRP 运行
INSERT INTO mdm_factory (id, tenant_id, company_id, factory_code, factory_name)
VALUES (8030001, 803, 1, '9SDF', 'sdfk 803');
INSERT INTO prd_mrp_run (id, tenant_id, company_id, mrp_run_no, factory_id, run_date)
VALUES (8030001, 803, 1, '9SDFK0001', 8030001, DATE '2026-10-21');

SET ROLE erp_app;
SELECT set_config('app.tenant_id', '803', true);
SELECT throws_ok($$INSERT INTO prd_mrp_demand (id, company_id, mrp_run_id, material_id, material_code, material_name, factory_id, bucket_date, demand_type)
                   VALUES (8030101, 2, 8030001, 1, 'M', 'm', 8030001, DATE '2026-10-21', 10)$$,
                 '23503', NULL, '公司 2 的明细引用公司 1 的 prd_mrp_run.id → 23503');
SELECT lives_ok($$INSERT INTO prd_mrp_demand (id, company_id, mrp_run_id, material_id, material_code, material_name, factory_id, bucket_date, demand_type)
                  VALUES (8030102, 1, 8030001, 1, 'M', 'm', 8030001, DATE '2026-10-21', 10)$$,
                '同租户同公司引用可写入');
RESET ROLE;

SELECT * FROM finish();
ROLLBACK;
