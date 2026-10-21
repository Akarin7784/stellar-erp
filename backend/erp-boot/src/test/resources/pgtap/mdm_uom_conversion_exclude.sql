-- pgTAP：mdm/V202610211402。mdm_uom_conversion 期间 EXCLUDE（deleted = FALSE AND status = 1）；prd_work_order_material.bom_uom_code / bom_qty。
BEGIN;
SELECT plan(15);

SELECT ok(EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ex_mdm_uom_conversion_period' AND contype = 'x'
                   AND conrelid = 'mdm_uom_conversion'::regclass),
          'mdm_uom_conversion 有 EXCLUDE 约束 ex_mdm_uom_conversion_period');
SELECT ok(upper_inf(daterange(DATE '2026-01-01', NULL, '[]')), 'daterange 上界为 NULL 即无穷大');

SELECT col_type_is('prd_work_order_material', 'bom_uom_code', 'character varying(16)', 'bom_uom_code VARCHAR(16)');
SELECT col_is_null('prd_work_order_material', 'bom_uom_code', 'bom_uom_code 可为空');
SELECT col_type_is('prd_work_order_material', 'bom_qty', 'numeric(18,4)', 'bom_qty NUMERIC(18,4)');
SELECT col_is_null('prd_work_order_material', 'bom_qty', 'bom_qty 可为空');
SELECT is((SELECT format_type(atttypid, atttypmod) FROM pg_attribute
            WHERE attrelid = 'prd_work_order_material'::regclass AND attname = 'bom_qty'),
          (SELECT format_type(atttypid, atttypmod) FROM pg_attribute
            WHERE attrelid = 'prd_work_order_material'::regclass AND attname = 'required_qty'),
          'bom_qty 与 required_qty 类型一致');

SET ROLE erp_app;
SELECT set_config('app.tenant_id', '804', true);
INSERT INTO mdm_uom_conversion (id, company_id, conversion_group, from_uom_code, to_uom_code, conversion_rate, valid_from, valid_to)
VALUES (8040001, 1, 'G1', 'BOX', 'PCE', 10, DATE '2026-01-01', DATE '2026-06-30');

SELECT throws_ok($$INSERT INTO mdm_uom_conversion (id, company_id, conversion_group, from_uom_code, to_uom_code, conversion_rate, valid_from, valid_to)
                   VALUES (8040002, 1, 'G1', 'BOX', 'PCE', 12, DATE '2026-06-30', DATE '2026-12-31')$$,
                 '23P01', NULL, '区间重叠（端点 06-30 两端均含）→ 23P01');
SELECT lives_ok($$INSERT INTO mdm_uom_conversion (id, company_id, conversion_group, from_uom_code, to_uom_code, conversion_rate, valid_from, valid_to)
                  VALUES (8040003, 1, 'G1', 'BOX', 'PCE', 12, DATE '2026-07-01', NULL)$$,
                '不重叠可写入（valid_to NULL 一直有效）');
SELECT throws_ok($$INSERT INTO mdm_uom_conversion (id, company_id, conversion_group, from_uom_code, to_uom_code, conversion_rate, valid_from, valid_to)
                   VALUES (8040004, 1, 'G1', 'BOX', 'PCE', 13, DATE '2030-01-01', DATE '2030-12-31')$$,
                 '23P01', NULL, '与 valid_to NULL 的无限区间重叠 → 23P01');
SELECT lives_ok($$INSERT INTO mdm_uom_conversion (id, company_id, conversion_group, from_uom_code, to_uom_code, conversion_rate, valid_from, valid_to, deleted)
                  VALUES (8040005, 1, 'G1', 'BOX', 'PCE', 13, DATE '2026-03-01', DATE '2026-03-31', TRUE)$$,
                'deleted = TRUE 的行不参与检查');
SELECT lives_ok($$INSERT INTO mdm_uom_conversion (id, company_id, conversion_group, from_uom_code, to_uom_code, conversion_rate, valid_from, valid_to)
                  VALUES (8040006, 2, 'G1', 'BOX', 'PCE', 10, DATE '2026-01-01', NULL)$$,
                '不同公司的同区间可写入');
SELECT lives_ok($$UPDATE mdm_uom_conversion SET deleted = TRUE WHERE id = 8040003;
                  INSERT INTO mdm_uom_conversion (id, company_id, conversion_group, from_uom_code, to_uom_code, conversion_rate, valid_from, valid_to)
                  VALUES (8040007, 1, 'G1', 'BOX', 'PCE', 14, DATE '2026-07-01', NULL)$$,
                '旧行逻辑删除后同区间可重新写入');
SELECT lives_ok($$INSERT INTO mdm_uom_conversion (id, company_id, conversion_group, from_uom_code, to_uom_code, conversion_rate, valid_from, valid_to, status)
                  VALUES (8040008, 1, 'G1', 'BOX', 'PCE', 15, DATE '2026-02-01', DATE '2026-02-28', 0)$$,
                '停用行（status = 0）不参与检查');
SELECT throws_ok($$UPDATE mdm_uom_conversion SET status = 1 WHERE id = 8040008$$,
                 '23P01', NULL, '停用行重新启用且与现有区间重叠 → 23P01');
RESET ROLE;

SELECT * FROM finish();
ROLLBACK;
