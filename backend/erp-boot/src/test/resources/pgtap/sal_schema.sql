-- pgTAP：03-sales 建表（sal/V202610210705）结构 / RLS / erp_app 权限 / 关键约束 / G2-18 列
-- 约定：准备数据用 owner（暂停 FK 触发器，免建 mdm_customer 等前置数据），断言前 SET ROLE erp_app；以 ROLLBACK 结束。
BEGIN;
SELECT plan(23);

SELECT is((SELECT count(*)::int FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE n.nspname = 'public' AND c.relkind = 'r' AND c.relname LIKE 'sal\_%'),
          29, 'sal_ 表共 29 张（§2）');
SELECT is((SELECT count(*)::int FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE n.nspname = 'public' AND c.relkind = 'r' AND c.relname LIKE 'sal\_%'
              AND c.relrowsecurity AND c.relforcerowsecurity
              AND EXISTS (SELECT 1 FROM pg_policy p WHERE p.polrelid = c.oid AND p.polqual IS NOT NULL AND p.polwithcheck IS NOT NULL)),
          29, '全部 sal_ 表 ENABLE + FORCE RLS 且策略含 USING / WITH CHECK');
SELECT is((SELECT count(*)::int FROM information_schema.columns
            WHERE table_schema = 'public' AND table_name LIKE 'sal\_%' AND column_name = 'tenant_id'
              AND column_default = '(current_setting(''app.tenant_id''::text))::bigint'),
          29, '全部 sal_ 表 tenant_id DEFAULT current_setting(app.tenant_id)（无 DEFAULT 0）');
SELECT is((SELECT count(*)::int FROM information_schema.columns
            WHERE table_schema = 'public' AND table_name LIKE 'sal\_%' AND column_name = 'company_id'
              AND is_nullable = 'NO' AND column_default IS NULL),
          29, '全部 sal_ 表（含明细）有 company_id NOT NULL 且无 DEFAULT');
SELECT is((SELECT count(*)::int FROM pg_index i JOIN pg_class ic ON ic.oid = i.indexrelid JOIN pg_class tc ON tc.oid = i.indrelid
            JOIN pg_attribute a0 ON a0.attrelid = i.indrelid AND a0.attnum = i.indkey[0]
            LEFT JOIN pg_attribute a1 ON a1.attrelid = i.indrelid AND a1.attnum = i.indkey[1]
            WHERE i.indisunique AND NOT i.indisprimary AND tc.relname LIKE 'sal\_%'
              AND (a0.attname <> 'tenant_id' OR a1.attname IS DISTINCT FROM 'company_id')),
          0, '全部 sal_ 唯一索引以 tenant_id 打头（明细/版表为 tenant_id, company_id, 父 ID …）');
SELECT ok(EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'uk_sal_sales_order_line_no'
                   AND indexdef LIKE '%(tenant_id, company_id, sales_order_id, line_no)%'), 'uk_sal_sales_order_line_no = (tenant_id, company_id, sales_order_id, line_no)');
SELECT is((SELECT count(*)::int FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE n.nspname = 'public' AND c.relkind = 'r' AND c.relname LIKE 'sal\_%'
              AND has_table_privilege('erp_app', c.oid, 'SELECT,INSERT,UPDATE,DELETE')),
          29, 'erp_app 对全部 sal_ 表有 SELECT/INSERT/UPDATE/DELETE');
SELECT is((SELECT count(*)::int FROM pg_class c WHERE c.relname LIKE 'sal\_%' AND c.relkind = 'r'
              AND pg_get_userbyid(c.relowner) = 'erp_app'),
          0, 'sal_ 表的 owner 不是 erp_app');

-- G2-18 受注行列（名称 / 类型与 g2_18 草稿一致）
SELECT col_type_is('sal_sales_order_line', 'completion_over_rate', 'numeric(5,4)', 'completion_over_rate NUMERIC(5,4)');
SELECT col_type_is('sal_sales_order_line', 'allowed_qty', 'numeric(18,4)', 'allowed_qty NUMERIC(18,4)');
SELECT col_type_is('sal_sales_order_line', 'completed_qty', 'numeric(18,4)', 'completed_qty NUMERIC(18,4)');
SELECT ok(EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'uk_sal_sales_order_no'
                    AND indexdef LIKE '%(tenant_id, company_id, sales_order_no)%'),
          'uk_sal_sales_order_no 以 (tenant_id, company_id) 打头');

SELECT ok(EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'uk_sal_sales_order_source'
                   AND indexdef LIKE '%(tenant_id, company_id, source_type, source_id) WHERE (source_id IS NOT NULL)%'),
          'uk_sal_sales_order_source = (tenant_id, company_id, source_type, source_id) WHERE source_id IS NOT NULL');

-- 准备：两个租户各一张受注 + 行（owner，暂停 FK 触发器）
SET LOCAL session_replication_role = replica;
INSERT INTO sal_sales_order (id, tenant_id, company_id, sales_order_no, order_date, customer_id, customer_code, customer_name,
                             delivery_address, sales_department_id, owner_user_id, payment_term_code, delivery_date, warehouse_id)
VALUES (3010001, 301, 1, 'SO2610210001', DATE '2026-10-21', 1, 'C001', 'cust', 'addr', 1, 1, 'NET30', DATE '2026-11-30', 1),
       (3020001, 302, 1, 'SO2610210001', DATE '2026-10-21', 1, 'C001', 'cust', 'addr', 1, 1, 'NET30', DATE '2026-11-30', 1);
INSERT INTO sal_sales_order_line (id, tenant_id, company_id, sales_order_id, line_no, material_id, material_code, material_name, ordered_qty,
                                  uom_code, base_uom_code, base_qty, unit_price, tax_code, tax_rate, delivery_date, warehouse_id)
VALUES (3010011, 301, 1, 3010001, 10, 1, 'M001', 'mat', 10, 'PCE', 'PCE', 10, 1, 'VAT13-OUT', 13, DATE '2026-11-30', 1);
SET LOCAL session_replication_role = origin;

SET ROLE erp_app;
SELECT set_config('app.tenant_id', '301', true);
SELECT is((SELECT count(*)::int FROM sal_sales_order), 1, '租户 301 只看到自己的受注');
SELECT is((SELECT count(*)::int FROM sal_sales_order WHERE id = 3020001), 0, '看不到租户 302 的受注');
SELECT throws_ok($$UPDATE sal_sales_order SET tenant_id = 302 WHERE id = 3010001$$, '42501', NULL,
                 'WITH CHECK 拒绝改成其他租户');
SELECT throws_ok($$UPDATE sal_sales_order SET order_status = 11 WHERE id = 3010001$$, '23514', NULL,
                 'ck_sal_sales_order_status 拒绝非法状态');
SELECT throws_ok($$UPDATE sal_sales_order_line SET ordered_qty = 0 WHERE id = 3010011$$, '23514', NULL,
                 'ck_sal_sales_order_line_qty 拒绝 ordered_qty = 0');
SELECT throws_ok($$UPDATE sal_sales_order_line SET completed_qty = -1 WHERE id = 3010011$$, '23514', NULL,
                 'ck_sal_sales_order_line_qty 拒绝 completed_qty < 0');
SELECT throws_ok($$UPDATE sal_sales_order_line SET allowed_qty = 5, completed_qty = 6 WHERE id = 3010011$$, '23514',
                 'new row for relation "sal_sales_order_line" violates check constraint "ck_sal_sol_completed_qty"',
                 'ck_sal_sol_completed_qty 拒绝 completed_qty > allowed_qty（约束名正确）');
SELECT throws_ok($$UPDATE sal_sales_order_line SET allowed_qty = -1 WHERE id = 3010011$$, '23514', NULL,
                 'ck_sal_sales_order_line_qty 拒绝 allowed_qty < 0');
SELECT throws_ok($$INSERT INTO sal_sales_order_line (id, company_id, sales_order_id, line_no, material_id, material_code, material_name, ordered_qty,
                     uom_code, base_uom_code, base_qty, unit_price, tax_code, tax_rate, delivery_date, warehouse_id)
                   VALUES (3010012, 1, 3010001, 20, 999999999, 'M9', 'x', 1, 'PCE', 'PCE', 1, 1, 'VAT13-OUT', 13, DATE '2026-11-30', 1)$$,
                 '23503', NULL, 'fk_sal_sales_order_line_m：物料必须存在（mdm_material）');
SELECT throws_ok($$INSERT INTO sal_sales_order (id, company_id, sales_order_no, order_date, customer_id, customer_code, customer_name,
                     delivery_address, sales_department_id, owner_user_id, payment_term_code, delivery_date, warehouse_id)
                   VALUES (3010002, 1, 'SO2610210001', DATE '2026-10-21', 1, 'C001', 'cust', 'addr', 1, 1, 'NET30', DATE '2026-11-30', 1)$$,
                 '23505', NULL, 'uk_sal_sales_order_no：同租户同公司受注号重复被拒（唯一检查先于 FK）');
RESET ROLE;

SELECT * FROM finish();
ROLLBACK;
