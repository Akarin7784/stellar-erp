-- pgTAP：06-production 建表（V202610210702）结构 / RLS / erp_app 权限 / standard_cost NULL 无默认
-- 约定：准备数据用 owner，断言前 SET ROLE erp_app；以 ROLLBACK 结束。
BEGIN;
SELECT plan(38);

-- 结构
SELECT is((SELECT count(*)::int FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE n.nspname = 'public' AND c.relkind = 'r' AND c.relname LIKE 'prd\_%'),
          48, 'prd_ 表共 48 张（§2 的 47 张 + §3.19.1 prd_overproduction_approval）');
SELECT is((SELECT count(*)::int FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE n.nspname = 'public' AND c.relkind = 'r' AND c.relname LIKE 'prd\_%'
              AND c.relrowsecurity AND c.relforcerowsecurity
              AND EXISTS (SELECT 1 FROM pg_policy p WHERE p.polrelid = c.oid AND p.polqual IS NOT NULL AND p.polwithcheck IS NOT NULL)),
          48, '全部 prd_ 表 ENABLE + FORCE RLS 且策略含 USING / WITH CHECK');
SELECT is((SELECT count(*)::int FROM information_schema.columns
            WHERE table_schema = 'public' AND table_name LIKE 'prd\_%' AND column_name = 'company_id'
              AND is_nullable = 'NO' AND column_default IS NULL),
          48, '全部 prd_ 表有 company_id NOT NULL 且无 DEFAULT');
SELECT is((SELECT count(*)::int FROM information_schema.columns
            WHERE table_schema = 'public' AND table_name LIKE 'prd\_%' AND column_name = 'tenant_id'
              AND column_default = '(current_setting(''app.tenant_id''::text))::bigint'),
          48, '全部 prd_ 表 tenant_id DEFAULT current_setting(app.tenant_id)');
SELECT is((SELECT count(*)::int FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE n.nspname = 'public' AND c.relkind = 'r' AND c.relname LIKE 'prd\_%'
              AND has_table_privilege('erp_app', c.oid, 'SELECT,INSERT,UPDATE,DELETE')),
          48, 'erp_app 对全部 prd_ 表有 SELECT/INSERT/UPDATE/DELETE');
SELECT is((SELECT count(*)::int FROM pg_class c WHERE c.relname LIKE 'prd\_%' AND c.relkind = 'r'
              AND pg_get_userbyid(c.relowner) = 'erp_app'),
          0, 'prd_ 表的 owner 不是 erp_app');

-- prd_work_order.standard_cost（PR #9）
SELECT col_type_is('prd_work_order', 'standard_cost', 'numeric(18,6)', 'standard_cost 为 NUMERIC(18,6)');
SELECT col_is_null('prd_work_order', 'standard_cost', 'standard_cost 允许 NULL');
SELECT col_hasnt_default('prd_work_order', 'standard_cost', 'standard_cost 无 DEFAULT');
SELECT col_default_is('prd_work_order', 'cost_variance', '0', 'cost_variance DEFAULT 0（NULL 判定靠 standard_cost IS NULL）');

-- 2026-10-21 决定：over_receipt_rate NOT NULL 无默认（创建时快照）；order_status 默认 10；current_date 改名 current_due_date（#15）
SELECT col_not_null('prd_work_order', 'over_receipt_rate', 'over_receipt_rate NOT NULL（创建时快照）');
SELECT col_hasnt_default('prd_work_order', 'over_receipt_rate', 'over_receipt_rate 无 DEFAULT');
SELECT col_default_is('prd_work_order', 'order_status', '10', 'order_status DEFAULT 10');
SELECT has_column('prd_mrp_action', 'current_due_date', 'prd_mrp_action 有 current_due_date');
SELECT hasnt_column('prd_mrp_action', 'current_date', 'prd_mrp_action 无保留字列 current_date');

-- G2-18 草稿 / 测试桩使用的工单列
SELECT ok((SELECT count(*) FROM information_schema.columns
            WHERE table_schema = 'public' AND table_name = 'prd_work_order'
              AND column_name IN ('id','tenant_id','company_id','sales_order_line_id','material_id','order_status','is_hold',
                                  'order_qty','completed_qty','allowed_qty','over_receipt_rate','version','updated_at','updated_by')) = 14,
          'prd_work_order 含 G2-18 使用的 14 列');
SELECT has_table('prd_overproduction_approval', 'prd_overproduction_approval 存在');

-- 唯一索引首列：(tenant_id, company_id)（sys/V202610210708 起不再有父 ID 打头的例外）
SELECT is((SELECT count(*)::int FROM pg_index i
            JOIN pg_class tc ON tc.oid = i.indrelid
            LEFT JOIN pg_attribute a ON a.attrelid = tc.oid AND a.attnum = i.indkey[0]
            WHERE tc.relname LIKE 'prd\_%' AND i.indisunique AND NOT i.indisprimary
              AND a.attname IS DISTINCT FROM 'tenant_id'),
          0, 'prd_ 唯一索引首列均为 tenant_id');
SELECT is((SELECT count(*)::int FROM pg_index i
            JOIN pg_class tc ON tc.oid = i.indrelid
            LEFT JOIN pg_attribute a ON a.attrelid = tc.oid AND a.attnum = i.indkey[1]
            WHERE tc.relname LIKE 'prd\_%' AND i.indisunique AND NOT i.indisprimary
              AND a.attname IS DISTINCT FROM 'company_id'),
          0, 'prd_ 唯一索引第二列均为 company_id（无父 ID 打头例外）');

-- prd → mdm 跨域 FK 29 条三列化（prd/V202610211411，04 §6.2 项 2a）
SELECT is((SELECT count(*)::int FROM pg_constraint k JOIN pg_class c ON c.oid = k.conrelid JOIN pg_class p ON p.oid = k.confrelid
            WHERE k.contype = 'f' AND c.relname ~ '^prd_' AND p.relname ~ '^mdm_'), 29, 'prd → mdm 跨域 FK 29 条');
SELECT is((SELECT count(*)::int FROM pg_constraint k JOIN pg_class c ON c.oid = k.conrelid JOIN pg_class p ON p.oid = k.confrelid
            WHERE k.contype = 'f' AND c.relname ~ '^prd_' AND p.relname ~ '^mdm_'
              AND (pg_get_constraintdef(k.oid) !~ '^FOREIGN KEY \(tenant_id, company_id, \w+\) REFERENCES mdm_\w+\(tenant_id, company_id, id\)$'
                   OR k.confdeltype <> 'a' OR k.confupdtype <> 'a')),
          0, 'prd → mdm FK 29 条全部三列 (tenant_id, company_id, x_id) → (tenant_id, company_id, id)，NO ACTION');
SELECT is((SELECT count(*)::int FROM pg_constraint k JOIN pg_class c ON c.oid = k.conrelid JOIN pg_class p ON p.oid = k.confrelid
            WHERE k.contype = 'f' AND c.relname ~ '^prd_' AND p.relname ~ '^mdm_'
              AND NOT EXISTS (SELECT 1 FROM pg_index i JOIN pg_class ic ON ic.oid = i.indexrelid JOIN pg_am am ON am.oid = ic.relam
                               WHERE i.indrelid = k.conrelid AND am.amname = 'btree' AND i.indnatts >= 3
                                 AND i.indkey[0] = k.conkey[1] AND i.indkey[1] = k.conkey[2] AND i.indkey[2] = k.conkey[3])),
          0, 'prd → mdm FK 29 条的子表均有以 (tenant_id, company_id, x_id) 打头的 btree 索引');

INSERT INTO mdm_factory (id, tenant_id, company_id, factory_code, factory_name)
VALUES (6030001, 603, 1, '9PRD1', 'prd f c1'), (6030002, 603, 2, '9PRD2', 'prd f c2');
INSERT INTO mdm_material_category (id, tenant_id, company_id, category_code, category_name, category_path, category_level, is_leaf, status)
VALUES (6030001, 603, 1, '9PRD', 'prd', '/9PRD/', 1, TRUE, 1), (6030002, 603, 2, '9PRD', 'prd', '/9PRD/', 1, TRUE, 1);
INSERT INTO mdm_material (id, tenant_id, company_id, material_code, material_name, material_type, category_id, spec, base_uom_code, valuation_method, status)
VALUES (6030001, 603, 1, '9PRD000001', 'prd m c1', 10, 6030001, 's', 'PCE', 10, 1),
       (6030002, 603, 2, '9PRD000002', 'prd m c2', 10, 6030002, 's', 'PCE', 10, 1);
INSERT INTO mdm_supplier (id, tenant_id, company_id, supplier_code, supplier_name, supplier_type, tax_no, buyer_id, payment_term_code, settlement_method_code)
VALUES (6030001, 603, 1, '9PRDS1', 's c1', 10, 'T1', 1, 'P', 'S'), (6030002, 603, 2, '9PRDS2', 's c2', 10, 'T2', 1, 'P', 'S');
SET ROLE erp_app;
SELECT set_config('app.tenant_id', '603', true);
SELECT throws_ok($$INSERT INTO prd_work_center (id, company_id, work_center_code, work_center_name, factory_id) VALUES (6030001, 1, 'WC1', 'wc', 6030002)$$,
                 '23503', NULL, 'fk_prd_work_center_factory：公司 1 引用同租户公司 2 的工厂 → 23503');
SELECT lives_ok($$INSERT INTO prd_work_center (id, company_id, work_center_code, work_center_name, factory_id) VALUES (6030002, 1, 'WC2', 'wc', 6030001)$$,
                'fk_prd_work_center_factory：同公司工厂可写入');
SELECT throws_ok($$INSERT INTO prd_demand_forecast (id, company_id, forecast_no, material_id, material_code, factory_id, bucket_date, forecast_qty)
                   VALUES (6030001, 1, 'FC1', 6030002, '9PRD000002', 6030001, DATE '2026-11-01', 1)$$,
                 '23503', NULL, 'fk_prd_demand_forecast_material：公司 1 引用同租户公司 2 的物料 → 23503');
SELECT lives_ok($$INSERT INTO prd_demand_forecast (id, company_id, forecast_no, material_id, material_code, factory_id, bucket_date, forecast_qty)
                  VALUES (6030002, 1, 'FC2', 6030001, '9PRD000001', 6030001, DATE '2026-11-01', 1)$$,
                'fk_prd_demand_forecast_material：同公司物料可写入');
SELECT throws_ok($$INSERT INTO prd_outsourcing_settlement (id, company_id, settlement_no, supplier_id, supplier_code, supplier_name, factory_id, period_code, settlement_date)
                   VALUES (6030001, 1, 'OS1', 6030002, '9PRDS2', 's c2', 6030001, '2026-10', DATE '2026-10-21')$$,
                 '23503', NULL, 'fk_prd_outsourcing_settlement_supplier：公司 1 引用同租户公司 2 的供应商 → 23503');
SELECT lives_ok($$INSERT INTO prd_outsourcing_settlement (id, company_id, settlement_no, supplier_id, supplier_code, supplier_name, factory_id, period_code, settlement_date)
                  VALUES (6030002, 1, 'OS2', 6030001, '9PRDS1', 's c1', 6030001, '2026-10', DATE '2026-10-21')$$,
                'fk_prd_outsourcing_settlement_supplier：同公司供应商可写入');
RESET ROLE;

-- RLS 行为（prd_defect_code，无跨表 FK）
SET ROLE erp_app;
SELECT set_config('app.tenant_id', '601', true);
INSERT INTO prd_defect_code (id, company_id, defect_code, defect_name) VALUES (6010001, 1, '101', '短路');
SELECT is((SELECT tenant_id FROM prd_defect_code WHERE id = 6010001), 601::bigint, 'tenant_id 取自 app.tenant_id');
SELECT set_config('app.tenant_id', '602', true);
SELECT is((SELECT count(*)::int FROM prd_defect_code WHERE id = 6010001), 0, '其他租户看不到');
SELECT throws_ok($$INSERT INTO prd_defect_code (id, tenant_id, company_id, defect_code, defect_name)
                   VALUES (6010002, 601, 1, '102', 'x')$$,
                 '42501', NULL, 'WITH CHECK 拒绝写入其他租户');
INSERT INTO prd_defect_code (id, company_id, defect_code, defect_name) VALUES (6010003, 1, '101', '短路');
SELECT is((SELECT count(*)::int FROM prd_defect_code WHERE defect_code = '101'), 1, '不同租户可用相同业务键（uk 含 tenant_id）');
SELECT throws_ok($$INSERT INTO prd_defect_code (id, defect_code, defect_name) VALUES (6010004, '103', 'x')$$,
                 '23502', NULL, 'company_id 无默认值，缺省时拒绝');

-- ck_prd_opa_qty 拆分（V202610210704）
SELECT ok(EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'prd_overproduction_approval'::regclass
                    AND conname = 'ck_prd_opa_request_qty' AND contype = 'c')
          AND EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'prd_overproduction_approval'::regclass
                    AND conname = 'ck_prd_opa_allowed_qty' AND contype = 'c')
          AND NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'prd_overproduction_approval'::regclass
                    AND conname = 'ck_prd_opa_qty'),
          'prd_overproduction_approval：有 ck_prd_opa_request_qty / ck_prd_opa_allowed_qty，无 ck_prd_opa_qty');
SELECT throws_ok($$INSERT INTO prd_overproduction_approval (id, company_id, approval_no, sales_order_id, sales_order_line_id,
                     material_id, request_qty, current_allowed_qty, requested_by, requested_at)
                   VALUES (6020001, 1, 'OPA2610210001', 1, 1, 1, 0, 100, 1, now())$$,
                 '23514', 'new row for relation "prd_overproduction_approval" violates check constraint "ck_prd_opa_request_qty"',
                 'request_qty = 0 → 23514 ck_prd_opa_request_qty');
SELECT throws_ok($$INSERT INTO prd_overproduction_approval (id, company_id, approval_no, sales_order_id, sales_order_line_id,
                     material_id, request_qty, current_allowed_qty, requested_by, requested_at)
                   VALUES (6020002, 1, 'OPA2610210002', 1, 1, 1, 5, -1, 1, now())$$,
                 '23514', 'new row for relation "prd_overproduction_approval" violates check constraint "ck_prd_opa_allowed_qty"',
                 'current_allowed_qty < 0 → 23514 ck_prd_opa_allowed_qty');
SELECT lives_ok($$INSERT INTO prd_overproduction_approval (id, company_id, approval_no, sales_order_id, sales_order_line_id,
                     material_id, request_qty, current_allowed_qty, requested_by, requested_at)
                   VALUES (6020003, 1, 'OPA2610210003', 1, 1, 1, 5, 0, 1, now())$$,
                'request_qty > 0 且 current_allowed_qty = 0 可写入');
RESET ROLE;

SELECT is((SELECT pg_get_constraintdef(oid) FROM pg_constraint WHERE conname = 'ck_prd_work_order_status'),
          'CHECK ((order_status = ANY (ARRAY[10, 20, 25, 30, 35, 40, 90])))',
          'ck_prd_work_order_status 不含 95（prd/V202610211420）');

SELECT * FROM finish();
ROLLBACK;
