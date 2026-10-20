-- pgTAP：06-production 建表（V202610210601）结构 / RLS / erp_app 权限 / standard_cost NULL 无默认
-- 约定：准备数据用 owner，断言前 SET ROLE erp_app；以 ROLLBACK 结束。
BEGIN;
SELECT plan(24);

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

-- 2026-10-21 决定：over_receipt_rate 可 NULL 无默认（NULL＝继承）；order_status 默认 10；action_date 改名
SELECT col_is_null('prd_work_order', 'over_receipt_rate', 'over_receipt_rate 允许 NULL（NULL＝继承）');
SELECT col_hasnt_default('prd_work_order', 'over_receipt_rate', 'over_receipt_rate 无 DEFAULT');
SELECT col_default_is('prd_work_order', 'order_status', '10', 'order_status DEFAULT 10');
SELECT has_column('prd_mrp_action', 'action_date', 'prd_mrp_action 有 action_date');
SELECT hasnt_column('prd_mrp_action', 'current_date', 'prd_mrp_action 无保留字列 current_date');

-- G2-18 草稿 / 测试桩使用的工单列
SELECT ok((SELECT count(*) FROM information_schema.columns
            WHERE table_schema = 'public' AND table_name = 'prd_work_order'
              AND column_name IN ('id','tenant_id','company_id','sales_order_line_id','material_id','order_status','is_hold',
                                  'order_qty','completed_qty','allowed_qty','over_receipt_rate','version','updated_at','updated_by')) = 14,
          'prd_work_order 含 G2-18 使用的 14 列');
SELECT has_table('prd_overproduction_approval', 'prd_overproduction_approval 存在');

-- 唯一索引首列：tenant_id，或设计书 §8 列出的父 ID 明细例外（company_id 打头）
SELECT is((SELECT count(*)::int FROM pg_index i
            JOIN pg_class ic ON ic.oid = i.indexrelid JOIN pg_class tc ON tc.oid = i.indrelid
            JOIN pg_attribute a ON a.attrelid = tc.oid AND a.attnum = i.indkey[0]
            WHERE tc.relname LIKE 'prd\_%' AND i.indisunique AND NOT i.indisprimary
              AND a.attname NOT IN ('tenant_id', 'company_id')),
          0, 'prd_ 唯一索引首列均为 tenant_id 或 company_id（例外）');
SELECT is((SELECT count(*)::int FROM pg_index i
            JOIN pg_class ic ON ic.oid = i.indexrelid JOIN pg_class tc ON tc.oid = i.indrelid
            JOIN pg_attribute a ON a.attrelid = tc.oid AND a.attnum = i.indkey[0]
            WHERE tc.relname LIKE 'prd\_%' AND i.indisunique AND NOT i.indisprimary AND a.attname = 'company_id'),
          16, '以 company_id 打头的 prd_ 唯一索引恰为设计书 §8 的 16 个例外');

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
RESET ROLE;

SELECT * FROM finish();
ROLLBACK;
