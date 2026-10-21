-- pgTAP：05 库存域（inv/V202610211404）。结构（24 表 / RLS / 分区 / FK）、关键 CHECK、表头触发器、inv_stock_txn_key 防重（90-db-design.md:458-489）、跨公司隔离。
BEGIN;
SELECT plan(62);

-- ===== 结构 =====
SELECT is((SELECT count(*)::int FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE n.nspname = 'public' AND c.relname ~ '^inv_' AND c.relkind IN ('r','p') AND NOT c.relispartition),
          24, 'inv 域 24 表（不含分区子表）');
SELECT is((SELECT count(*)::int FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE n.nspname = 'public' AND c.relname ~ '^inv_' AND c.relkind IN ('r','p')
              AND (NOT c.relrowsecurity OR NOT c.relforcerowsecurity
                   OR NOT EXISTS (SELECT 1 FROM pg_policy p WHERE p.polrelid = c.oid AND p.polname = 'tenant_isolation'))),
          0, 'inv 全表（含分区子表）ENABLE + FORCE RLS 且有 tenant_isolation');
SELECT is((SELECT count(*)::int FROM information_schema.columns
            WHERE table_schema = 'public' AND table_name ~ '^inv_' AND column_name = 'tenant_id'
              AND column_default IS DISTINCT FROM '(current_setting(''app.tenant_id''::text))::bigint'),
          0, 'inv 全表 tenant_id DEFAULT current_setting(app.tenant_id)');
SELECT is((SELECT count(*)::int FROM information_schema.columns
            WHERE table_schema = 'public' AND table_name ~ '^inv_' AND column_name = 'company_id'
              AND (is_nullable = 'YES' OR column_default IS NOT NULL)),
          0, 'inv 全表 company_id NOT NULL 且无 DEFAULT');
SELECT is((SELECT count(*)::int FROM information_schema.columns
            WHERE table_schema = 'public' AND table_name ~ '^inv_' AND column_name = 'uom_code'
              AND character_maximum_length <> 16),
          0, 'inv 的 uom_code 全部 VARCHAR(16)');
SELECT is((SELECT relkind::text FROM pg_class WHERE relname = 'inv_stock_txn'), 'p', 'inv_stock_txn 是分区表');
SELECT is((SELECT count(*)::int FROM pg_inherits WHERE inhparent = 'inv_stock_txn'::regclass), 25,
          'inv_stock_txn 分区 2026-01〜2027-12（24 个）+ default');
SELECT is((SELECT pg_get_constraintdef(oid) FROM pg_constraint WHERE conname = 'pk_inv_stock_txn'),
          'PRIMARY KEY (id, txn_date)', '主键含分区键 txn_date');
SELECT ok((SELECT indexdef FROM pg_indexes WHERE indexname = 'uk_inv_stock_txn_no') LIKE '%(tenant_id, company_id, txn_no, txn_date)%',
          'uk_inv_stock_txn_no 含分区键 txn_date');
SELECT ok(NOT has_table_privilege('erp_app', 'inv_stock_txn_y2026m10', 'SELECT')
          AND NOT has_table_privilege('erp_app', 'inv_stock_txn_default', 'INSERT'),
          'erp_app 不能直接访问分区子表');
SELECT ok(has_table_privilege('erp_app', 'inv_stock_txn', 'INSERT') AND has_table_privilege('erp_app', 'inv_stock_txn_key', 'DELETE'),
          'erp_app 对父表/台账有 DML（ALTER DEFAULT PRIVILEGES）');
-- 月分区函数
SELECT lives_ok($$SELECT public.inv_create_stock_txn_partition(DATE '2028-03-17')$$, 'inv_create_stock_txn_partition 新建 2028-03 分区');
SELECT ok((SELECT relrowsecurity AND relforcerowsecurity FROM pg_class WHERE relname = 'inv_stock_txn_y2028m03'),
          '新分区 ENABLE + FORCE RLS');
SELECT ok(EXISTS (SELECT 1 FROM pg_policy WHERE polrelid = 'inv_stock_txn_y2028m03'::regclass AND polname = 'tenant_isolation'),
          '新分区有 tenant_isolation 策略');
SELECT ok(NOT has_table_privilege('erp_app', 'inv_stock_txn_y2028m03', 'SELECT')
          AND NOT has_table_privilege('erp_app', 'inv_stock_txn_y2028m03', 'INSERT'), '新分区 erp_app 无权限');
SELECT lives_ok($$SELECT public.inv_create_stock_txn_partition(DATE '2028-03-01')$$, '重复调用不报错（幂等）');
SELECT is((SELECT count(*)::int FROM pg_inherits WHERE inhparent = 'inv_stock_txn'::regclass), 26, '重复调用不多建分区');
SELECT ok(has_function_privilege('erp_partition_maintainer', 'public.inv_create_stock_txn_partition(date)', 'EXECUTE'),
          'erp_partition_maintainer 有 inv_create_stock_txn_partition 的 EXECUTE');
SELECT ok(NOT EXISTS (SELECT 1 FROM pg_proc p, aclexplode(COALESCE(p.proacl, acldefault('f', p.proowner))) a
                      WHERE p.oid = 'public.inv_create_stock_txn_partition(date)'::regprocedure
                        AND a.grantee = 0 AND a.privilege_type = 'EXECUTE'),
          'PUBLIC 没有 inv_create_stock_txn_partition 的 EXECUTE');
SELECT ok(NOT has_function_privilege('erp_app', 'public.inv_create_stock_txn_partition(date)', 'EXECUTE')
          AND (SELECT prosecdef FROM pg_proc WHERE proname = 'inv_create_stock_txn_partition'),
          '函数为 SECURITY DEFINER，erp_app 无 EXECUTE');
SELECT is((SELECT count(*)::int FROM pg_constraint WHERE contype = 'f' AND confrelid = 'inv_stock_txn'::regclass), 0,
          '没有 FK 引用分区表 inv_stock_txn');
SELECT is((SELECT count(*)::int FROM pg_constraint k JOIN pg_class c ON c.oid = k.conrelid JOIN pg_class p ON p.oid = k.confrelid
            WHERE k.contype = 'f' AND c.relname ~ '^inv_' AND p.relname ~ '^mdm_'), 28, 'inv → mdm 跨域 FK 28 条（§6.3 #7〜11 + inv_stock_balance.material_id）');
SELECT is((SELECT count(*)::int FROM pg_constraint k JOIN pg_class c ON c.oid = k.conrelid JOIN pg_class p ON p.oid = k.confrelid
            WHERE k.contype = 'f' AND c.relname ~ '^inv_' AND p.relname ~ '^mdm_'
              AND pg_get_constraintdef(k.oid) !~ '^FOREIGN KEY \(tenant_id, \w+\) REFERENCES mdm_\w+\(tenant_id, id\)$'),
          0, 'inv → mdm FK 全部 (tenant_id, x_id) → (tenant_id, id)，无 ON DELETE');
SELECT is((SELECT count(*)::int FROM pg_constraint WHERE contype = 'u' AND conname ~ '^uk_inv_\w+_tenant_company_id$'), 6,
          '同域被引用父表 6 张有 uk_<表>_tenant_company_id');
SELECT is((SELECT count(*)::int FROM pg_constraint WHERE contype = 'u' AND conname ~ '^uk_inv_\w+_tenant_id$'), 0,
          'inv 无 uk_<表>_tenant_id（§3.4：本域 0 件）');

-- ===== 准备（owner）：租户 804 公司 1 的 mdm 数据 =====
INSERT INTO mdm_factory (id, tenant_id, company_id, factory_code, factory_name) VALUES (8040001, 804, 1, '9INV', 'inv 804');
INSERT INTO mdm_warehouse (id, tenant_id, company_id, warehouse_code, warehouse_name, warehouse_type, factory_id)
VALUES (8040001, 804, 1, '9INV1', 'inv wh 804', 10, 8040001);
INSERT INTO mdm_material_category (id, tenant_id, company_id, category_code, category_name, category_path, category_level, is_leaf, status)
VALUES (8040001, 804, 1, '9INV', 'inv', '/9INV/', 1, TRUE, 1);
INSERT INTO mdm_material (id, tenant_id, company_id, material_code, material_name, material_type, category_id, spec, base_uom_code, valuation_method, status)
VALUES (8040001, 804, 1, '9INV000001', 'inv m', 10, 8040001, 's', 'PCE', 10, 1);
-- 租户 805 的一行（RLS 可见性用）
INSERT INTO inv_stock_txn_key (id, tenant_id, company_id, key_type, key_value, txn_id, txn_date)
VALUES (8050001, 805, 1, 'TXN_NO', 'GRI2610150001', 1, DATE '2026-10-15');

SET ROLE erp_app;
SELECT set_config('app.tenant_id', '804', true);

-- ===== 关键 CHECK =====
SELECT throws_ok($$INSERT INTO inv_stock_balance (id, company_id, warehouse_id, material_id, stock_status, qty_on_hand, qty_reserved)
                   VALUES (1, 1, 8040001, 8040001, 20, 5, 6)$$, '23514', NULL, 'ck_inv_stock_balance_qty：引当 > 現存 → 23514');
SELECT throws_ok($$INSERT INTO inv_stock_balance (id, company_id, warehouse_id, material_id, stock_status) VALUES (2, 1, 8040001, 8040001, 25)$$,
                 '23514', NULL, 'ck_inv_stock_balance_status：状態 25 → 23514');
SELECT throws_ok($$INSERT INTO inv_stock_txn (id, company_id, txn_no, txn_type, txn_date, factory_id, warehouse_id, source_type, accounting_period)
                   VALUES (10, 1, 'X1', 'XX', DATE '2026-10-15', 8040001, 8040001, 'MANUAL', '2026-10')$$,
                 '23514', NULL, 'ck_inv_stock_txn_type：19 種以外 → 23514');
SELECT throws_ok($$INSERT INTO inv_stock_txn (id, company_id, txn_no, txn_type, txn_date, factory_id, warehouse_id, source_type, accounting_period, reason_type)
                   VALUES (11, 1, 'X2', 'PI', DATE '2026-10-15', 8040001, 8040001, 'PURCHASE_RECEIPT', '2026-10', 10)$$,
                 '23514', NULL, 'ck_inv_stock_txn_reason：PI に reason_type → 23514');
SELECT throws_ok($$INSERT INTO inv_stock_txn (id, company_id, txn_no, txn_type, txn_date, factory_id, warehouse_id, source_type, accounting_period)
                   VALUES (14, 1, 'X5', 'AOI', DATE '2026-10-15', 8040001, 8040001, 'MANUAL', '2026-10')$$,
                 '23514', NULL, 'ck_inv_stock_txn_reason：AOI で reason_type 未入力 → 23514');
SELECT throws_ok($$INSERT INTO inv_stock_txn (id, company_id, txn_no, txn_type, txn_date, factory_id, warehouse_id, source_type, accounting_period)
                   VALUES (17, 1, 'X8', 'AOO', DATE '2026-10-15', 8040001, 8040001, 'MANUAL', '2026-10')$$,
                 '23514', NULL, 'ck_inv_stock_txn_reason：AOO で reason_type 未入力 → 23514');
SELECT throws_ok($$INSERT INTO inv_stock_txn (id, company_id, txn_no, txn_type, txn_date, factory_id, warehouse_id, source_type, accounting_period, reason_type)
                   VALUES (15, 1, 'X6', 'SC_OUT', DATE '2026-10-15', 8040001, 8040001, 'MANUAL', '2026-10', 60)$$,
                 '23514', NULL, 'ck_inv_stock_txn_reason：SC_OUT で reason_type=60 → 23514（02 §2.6.7 は 10〜50）');
SELECT lives_ok($$INSERT INTO inv_stock_txn (id, company_id, txn_no, txn_type, txn_date, factory_id, warehouse_id, source_type, accounting_period, reason_type)
                  VALUES (16, 1, 'X7', 'SC_OUT', DATE '2026-10-15', 8040001, 8040001, 'MANUAL', '2026-10', 50)$$,
                'SC_OUT で reason_type=50 は可');
SELECT lives_ok($$INSERT INTO inv_batch_genealogy (id, company_id, parent_batch_id, child_batch_id, source_txn_id, qty_consumed)
                  VALUES (40, 1, 1, 2, 100, 1)$$, '系谱 source_txn_line_id=NULL 首次写入');
SELECT throws_ok($$INSERT INTO inv_batch_genealogy (id, company_id, parent_batch_id, child_batch_id, source_txn_id, qty_consumed)
                   VALUES (41, 1, 1, 2, 100, 1)$$,
                 '23505', NULL, 'uk_inv_batch_genealogy_key NULLS NOT DISTINCT：source_txn_line_id=NULL 重复 → 23505');
SELECT throws_ok($$INSERT INTO inv_stock_txn (id, company_id, txn_no, txn_type, txn_date, factory_id, warehouse_id, source_type, accounting_period, is_reversal)
                   VALUES (12, 1, 'X3', 'PI', DATE '2026-10-15', 8040001, 8040001, 'PURCHASE_RECEIPT', '2026-10', TRUE)$$,
                 '23514', NULL, 'ck_inv_stock_txn_reversal：沖销元なし → 23514');
SELECT throws_ok($$INSERT INTO inv_stock_txn (id, company_id, txn_no, txn_type, txn_date, factory_id, warehouse_id, source_type, accounting_period)
                   VALUES (13, 1, 'X4', 'PI', DATE '2019-12-31', 8040001, 8040001, 'PURCHASE_RECEIPT', '2019-12')$$,
                 '23514', NULL, 'ck_inv_stock_txn_date：2020-01-01 より前 → 23514');
SELECT throws_ok($$INSERT INTO inv_transfer (id, company_id, transfer_no, transfer_type, transfer_date, from_factory_id, from_warehouse_id,
                     to_factory_id, to_warehouse_id, reason, applicant_id)
                   VALUES (20, 1, 'TR1', 10, DATE '2026-10-15', 8040001, 8040001, 8040001, 8040002, 'r', 1)$$,
                 '23514', NULL, 'ck_inv_transfer_wh：同倉移庫で倉庫相違 → 23514');
SELECT throws_ok($$INSERT INTO inv_stock_summary (id, company_id, period_code, warehouse_id, material_id, uom_code, opening_qty, in_qty, out_qty, closing_qty)
                   VALUES (30, 1, '2026-10', 8040001, 8040001, 'PCE', 10, 5, 3, 13)$$,
                 '23514', NULL, 'ck_inv_stock_summary_balance：期末 ≠ 期初+入−出 → 23514');

-- ===== 分区路由 + 表头触发器 =====
SELECT lives_ok($$INSERT INTO inv_stock_txn (id, company_id, txn_no, txn_type, txn_date, factory_id, warehouse_id, source_type, source_id, accounting_period)
                  VALUES (100, 1, 'GRI2610150001', 'PI', DATE '2026-10-15', 8040001, 8040001, 'PURCHASE_RECEIPT', 9001, '2026-10'),
                         (101, 1, 'GRI2610150001', 'PI', DATE '2026-11-02', 8040001, 8040001, 'PURCHASE_RECEIPT', 9001, '2026-11'),
                         (102, 1, 'SDO3001010001', 'SI', DATE '2030-01-01', 8040001, 8040001, 'SALES_DELIVERY', 9002, '2030-01');
                  INSERT INTO inv_stock_txn (id, company_id, txn_no, txn_type, txn_date, factory_id, warehouse_id, source_type, source_id, accounting_period, is_reversal, reversal_of_txn_id)
                  VALUES (103, 1, 'GRI2610150002', 'PI', DATE '2026-10-16', 8040001, 8040001, 'PURCHASE_RECEIPT', 9001, '2026-10', TRUE, 100)$$,
                '同一 txn_no 不同 txn_date 可进入不同分区（uk_inv_stock_txn_no 只保证分区内）');
SELECT is((SELECT tableoid::regclass::text FROM inv_stock_txn WHERE id = 100), 'inv_stock_txn_y2026m10', '2026-10-15 → inv_stock_txn_y2026m10');
SELECT is((SELECT tableoid::regclass::text FROM inv_stock_txn WHERE id = 102), 'inv_stock_txn_default', '2030-01-01 → inv_stock_txn_default');
SELECT throws_ok($$INSERT INTO inv_stock_txn_line (id, company_id, txn_id, line_no, material_id, material_code, material_name, uom_code, qty, direction, stock_status, inspection_flag, txn_type, valuation_method)
                   VALUES (200, 1, 100, 10, 8040001, '9INV000001', 'inv m', 'PCE', 1, 1, 20, TRUE, 'PI', 10)$$,
                 '23514', NULL, 'ck_inv_stock_txn_line_insp_inbound：入庫・検査要で状態 20 → 23514');
SELECT lives_ok($$INSERT INTO inv_stock_txn_line (id, company_id, txn_id, line_no, material_id, material_code, material_name, uom_code, qty, direction, stock_status, inspection_flag, txn_type, valuation_method)
                  VALUES (201, 1, 100, 10, 8040001, '9INV000001', 'inv m', 'PCE', 1, 1, 10, TRUE, 'PI', 10)$$, '表头存在・PI・direction=+1 可写入');
SELECT throws_ok($$INSERT INTO inv_stock_txn_line (id, company_id, txn_id, line_no, material_id, material_code, material_name, uom_code, qty, direction, stock_status, inspection_flag, txn_type, valuation_method)
                   VALUES (202, 1, 999, 10, 8040001, '9INV000001', 'inv m', 'PCE', 1, 1, 20, FALSE, 'PI', 10)$$,
                 '23503', NULL, '表头不存在 → 23503（trg_inv_stock_txn_line_head）');
SELECT throws_ok($$INSERT INTO inv_stock_txn_line (id, company_id, txn_id, line_no, material_id, material_code, material_name, uom_code, qty, direction, stock_status, inspection_flag, txn_type, valuation_method)
                   VALUES (203, 2, 100, 10, 8040001, '9INV000001', 'inv m', 'PCE', 1, 1, 20, FALSE, 'PI', 10)$$,
                 '23503', NULL, '公司 2 的明细挂公司 1 的表头 → 23503');
SELECT throws_ok($$INSERT INTO inv_stock_txn_line (id, company_id, txn_id, line_no, material_id, material_code, material_name, uom_code, qty, direction, stock_status, inspection_flag, txn_type, valuation_method)
                   VALUES (204, 1, 100, 20, 8040001, '9INV000001', 'inv m', 'PCE', 1, 1, 20, FALSE, 'SI', 10)$$,
                 '23514', NULL, 'txn_type 与表头不一致 → 23514');
SELECT throws_ok($$INSERT INTO inv_stock_txn_line (id, company_id, txn_id, line_no, material_id, material_code, material_name, uom_code, qty, direction, stock_status, inspection_flag, txn_type, valuation_method)
                   VALUES (205, 1, 100, 30, 8040001, '9INV000001', 'inv m', 'PCE', 1, -1, 20, FALSE, 'PI', 10)$$,
                 '23514', NULL, 'PI 的 direction=-1 → 23514');
SELECT lives_ok($$INSERT INTO inv_stock_txn_line (id, company_id, txn_id, line_no, material_id, material_code, material_name, uom_code, qty, direction, stock_status, inspection_flag, txn_type, valuation_method)
                  VALUES (206, 1, 103, 10, 8040001, '9INV000001', 'inv m', 'PCE', 1, -1, 20, FALSE, 'PI', 10)$$, '沖销 PI（is_reversal）的 direction=-1 可写入');

-- ===== inv_stock_txn_key 防重（90-db-design.md:458-489） =====
SELECT lives_ok($$INSERT INTO inv_stock_txn_key (id, company_id, key_type, key_value, txn_id, txn_date) VALUES
                  (300, 1, 'TXN_NO', 'GRI2610150001', 100, DATE '2026-10-15'),
                  (301, 1, 'SOURCE_POSTED', 'PURCHASE_RECEIPT|9001|PI', 100, DATE '2026-10-15'),
                  (302, 1, 'REVERSAL', '100', 103, DATE '2026-10-16'),
                  (303, 1, 'PAIR', 'p-1|ST_OUT', 100, DATE '2026-10-15')$$, '四种 key 首次登记成功');
SELECT throws_ok($$INSERT INTO inv_stock_txn_key (id, company_id, key_type, key_value, txn_id, txn_date) VALUES (310, 1, 'TXN_NO', 'GRI2610150001', 101, DATE '2026-11-02')$$,
                 '23505', NULL, 'TXN_NO：跨分区同号 → 23505');
SELECT throws_ok($$INSERT INTO inv_stock_txn_key (id, company_id, key_type, key_value, txn_id, txn_date) VALUES (311, 1, 'SOURCE_POSTED', 'PURCHASE_RECEIPT|9001|PI', 101, DATE '2026-11-02')$$,
                 '23505', NULL, 'SOURCE_POSTED：同来源同种别二次过账 → 23505');
SELECT throws_ok($$INSERT INTO inv_stock_txn_key (id, company_id, key_type, key_value, txn_id, txn_date) VALUES (312, 1, 'REVERSAL', '100', 104, DATE '2026-10-17')$$,
                 '23505', NULL, 'REVERSAL：同一事务二次沖销 → 23505');
SELECT throws_ok($$INSERT INTO inv_stock_txn_key (id, company_id, key_type, key_value, txn_id, txn_date) VALUES (313, 1, 'PAIR', 'p-1|ST_OUT', 105, DATE '2026-10-15')$$,
                 '23505', NULL, 'PAIR：同 pair_key×txn_type 二次 → 23505');
SELECT lives_ok($$DELETE FROM inv_stock_txn_key WHERE company_id = 1 AND key_type = 'SOURCE_POSTED' AND key_value = 'PURCHASE_RECEIPT|9001|PI';
                  INSERT INTO inv_stock_txn_key (id, company_id, key_type, key_value, txn_id, txn_date) VALUES (314, 1, 'SOURCE_POSTED', 'PURCHASE_RECEIPT|9001|PI', 101, DATE '2026-11-02')$$,
                '沖销时删除 SOURCE_POSTED 后可再过账');
SELECT lives_ok($$INSERT INTO inv_stock_txn_key (id, company_id, key_type, key_value, txn_id, txn_date) VALUES (315, 2, 'TXN_NO', 'GRI2610150001', 500, DATE '2026-10-15')$$,
                '其他公司同号可登记（键以 tenant_id, company_id 打头）');
SELECT throws_ok($$INSERT INTO inv_stock_txn_key (id, company_id, key_type, key_value, txn_id, txn_date) VALUES (316, 1, 'OTHER', 'x', 1, DATE '2026-10-15')$$,
                 '23514', NULL, 'ck_inv_stock_txn_key_type：未定义 key_type → 23514');

-- ===== 跨公司 / 跨租户隔离 =====
SELECT lives_ok($$INSERT INTO inv_stocktake_plan (id, company_id, plan_no, plan_name, warehouse_id, scope_json, planned_start_date, planned_end_date)
                    VALUES (400, 1, 'PL1', 'p', 8040001, '{}', DATE '2026-10-01', DATE '2026-10-31');
                  INSERT INTO inv_stocktake (id, company_id, stocktake_no, plan_id, warehouse_id, take_date, snapshot_at)
                    VALUES (401, 1, 'CNT1', 400, 8040001, DATE '2026-10-15', now())$$, '同公司 plan → stocktake 可写入');
SELECT throws_ok($$INSERT INTO inv_stocktake (id, company_id, stocktake_no, plan_id, warehouse_id, take_date, snapshot_at)
                   VALUES (402, 2, 'CNT2', 400, 8040001, DATE '2026-10-15', now())$$,
                 '23503', NULL, '公司 2 的盘点单引用公司 1 的计划 → 23503（fk_inv_stocktake_plan）');
SELECT throws_ok($$INSERT INTO inv_stocktake_line (id, company_id, stocktake_id, line_no, material_id, material_code, material_name, stock_status, uom_code, book_qty)
                   VALUES (403, 2, 401, 10, 8040001, '9INV000001', 'inv m', 20, 'PCE', 0)$$,
                 '23503', NULL, '公司 2 的盘点明细引用公司 1 的盘点单 → 23503');
SELECT is((SELECT count(*)::int FROM inv_stock_txn_key WHERE tenant_id = 805), 0, 'RLS：租户 804 看不到租户 805 的行');
SELECT throws_ok($$INSERT INTO inv_stock_txn_key (id, tenant_id, company_id, key_type, key_value, txn_id, txn_date) VALUES (317, 805, 1, 'TXN_NO', 'Z', 1, DATE '2026-10-15')$$,
                 '42501', NULL, 'RLS WITH CHECK：写入其他租户 → 42501');
RESET ROLE;

SELECT * FROM finish();
ROLLBACK;
