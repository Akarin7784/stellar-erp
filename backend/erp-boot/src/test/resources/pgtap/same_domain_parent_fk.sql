-- pgTAP：同域父子表复合外键（sys/V202610211401）。public 下非 mdm 同域外键必须为 (tenant_id, company_id, x_id) → (tenant_id, company_id, id)，跨公司引用被拒。
BEGIN;
SELECT plan(8);

-- 同域判定：public 下表名前缀（split_part(_,1)）相同；排除 Flowable 引擎表（act_/flw_）。
-- 合规形态：(tenant_id, company_id, x_id) → (tenant_id, company_id, id)；
-- 例外（蓝色大肥鱼已定）：mdm 域内部外键保持 0707 的 (tenant_id, x_id) → (tenant_id, id)。新域（inv/wf …）自动纳入。
CREATE TEMP TABLE t_sdfk ON COMMIT DROP AS
SELECT k.conname, c.relname AS child, split_part(c.relname, '_', 1) AS dom,
       (SELECT array_agg(a.attname ORDER BY x.n) FROM unnest(k.conkey) WITH ORDINALITY x(att, n)
          JOIN pg_attribute a ON a.attrelid = k.conrelid AND a.attnum = x.att) AS cols,
       (SELECT array_agg(a.attname ORDER BY x.n) FROM unnest(k.confkey) WITH ORDINALITY x(att, n)
          JOIN pg_attribute a ON a.attrelid = k.confrelid AND a.attnum = x.att) AS refcols
FROM pg_constraint k JOIN pg_class c ON c.oid = k.conrelid JOIN pg_class p ON p.oid = k.confrelid
JOIN pg_namespace n ON n.oid = c.relnamespace JOIN pg_namespace pn ON pn.oid = p.relnamespace
WHERE k.contype = 'f' AND n.nspname = 'public' AND pn.nspname = 'public'
  AND c.relname !~ '^(act|flw)_' AND split_part(c.relname, '_', 1) = split_part(p.relname, '_', 1);

SELECT ok((SELECT count(*) FROM t_sdfk WHERE dom <> 'mdm') > 0, '非 mdm 同域外键数（动态得出）> 0，防止空集通过');
SELECT is((SELECT count(*)::int FROM t_sdfk
            WHERE dom <> 'mdm'
              AND NOT (array_length(cols, 1) = 3 AND cols[1] = 'tenant_id' AND cols[2] = 'company_id'
                       AND refcols = ARRAY['tenant_id', 'company_id', 'id']::name[])),
          0, '非 mdm 同域外键中，单列或不含 company_id 的为 0（应为 (tenant_id, company_id, x_id) → (tenant_id, company_id, id)）');
SELECT is((SELECT count(*)::int FROM t_sdfk
            WHERE dom = 'mdm'
              AND NOT (array_length(cols, 1) = 2 AND cols[1] = 'tenant_id' AND refcols = ARRAY['tenant_id', 'id']::name[])),
          0, 'mdm 域内部外键全部为 (tenant_id, x_id) → (tenant_id, id)（已定例外）');
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
                 '23503', 'insert or update on table "prd_mrp_demand" violates foreign key constraint "fk_prd_mrp_demand_run"',
                 '公司 2 的明细引用公司 1 的 prd_mrp_run.id → 23503 fk_prd_mrp_demand_run');
SELECT lives_ok($$INSERT INTO prd_mrp_demand (id, company_id, mrp_run_id, material_id, material_code, material_name, factory_id, bucket_date, demand_type)
                  VALUES (8030102, 1, 8030001, 1, 'M', 'm', 8030001, DATE '2026-10-21', 10)$$,
                '同租户同公司引用可写入');
RESET ROLE;

SELECT * FROM finish();
ROLLBACK;
