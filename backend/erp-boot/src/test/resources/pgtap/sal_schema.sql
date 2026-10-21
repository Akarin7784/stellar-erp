-- pgTAP：03-sales 建表（sal/V202610210705）结构 / RLS / erp_app 权限 / 关键约束 / G2-18 列
-- 约定：准备数据用 owner（暂停 FK 触发器，免建 mdm_customer 等前置数据），断言前 SET ROLE erp_app；以 ROLLBACK 结束。
BEGIN;
SELECT plan(31);

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

-- sal → mdm/sys 跨域 FK 14 条三列化（sal/V202610211412，04 §6.2 项 2a）
SELECT is((SELECT count(*)::int FROM pg_constraint k JOIN pg_class c ON c.oid = k.conrelid JOIN pg_class p ON p.oid = k.confrelid
            WHERE k.contype = 'f' AND c.relname ~ '^sal_' AND p.relname ~ '^(mdm|sys)_'), 14, 'sal → mdm/sys 跨域 FK 14 条');
SELECT is((SELECT count(*)::int FROM pg_constraint k JOIN pg_class c ON c.oid = k.conrelid JOIN pg_class p ON p.oid = k.confrelid
            WHERE k.contype = 'f' AND c.relname ~ '^sal_' AND p.relname ~ '^(mdm|sys)_'
              AND (pg_get_constraintdef(k.oid) !~ '^FOREIGN KEY \(tenant_id, company_id, \w+\) REFERENCES (mdm|sys)_\w+\(tenant_id, company_id, id\)$'
                   OR k.confdeltype <> 'a' OR k.confupdtype <> 'a')),
          0, 'sal → mdm/sys FK 14 条全部三列 (tenant_id, company_id, x_id) → (tenant_id, company_id, id)，NO ACTION');
SELECT is((SELECT count(*)::int FROM pg_constraint k JOIN pg_class c ON c.oid = k.conrelid JOIN pg_class p ON p.oid = k.confrelid
            WHERE k.contype = 'f' AND c.relname ~ '^sal_' AND p.relname ~ '^(mdm|sys)_'
              AND NOT EXISTS (SELECT 1 FROM pg_index i JOIN pg_class ic ON ic.oid = i.indexrelid JOIN pg_am am ON am.oid = ic.relam
                               WHERE i.indrelid = k.conrelid AND am.amname = 'btree' AND i.indnatts >= 3
                                 AND i.indkey[0] = k.conkey[1] AND i.indkey[1] = k.conkey[2] AND i.indkey[2] = k.conkey[3])),
          0, 'sal → mdm/sys FK 14 条的子表均有以 (tenant_id, company_id, x_id) 打头的 btree 索引');

INSERT INTO mdm_customer (id, tenant_id, company_id, customer_code, customer_name, customer_type, tax_no, owner_user_id, payment_term_code, settlement_method_code)
VALUES (3030001, 303, 1, '9SALC1', 'c c1', 10, 'T1', 1, 'P', 'S'), (3030002, 303, 2, '9SALC2', 'c c2', 10, 'T2', 1, 'P', 'S');
INSERT INTO mdm_material_category (id, tenant_id, company_id, category_code, category_name, category_path, category_level, is_leaf, status)
VALUES (3030001, 303, 1, '9SAL', 'sal', '/9SAL/', 1, TRUE, 1), (3030002, 303, 2, '9SAL', 'sal', '/9SAL/', 1, TRUE, 1);
INSERT INTO mdm_material (id, tenant_id, company_id, material_code, material_name, material_type, category_id, spec, base_uom_code, valuation_method, status)
VALUES (3030001, 303, 1, '9SAL000001', 'sal m c1', 10, 3030001, 's', 'PCE', 10, 1),
       (3030002, 303, 2, '9SAL000002', 'sal m c2', 10, 3030002, 's', 'PCE', 10, 1);
INSERT INTO sys_department (id, tenant_id, company_id, department_code, department_name)
VALUES (3030001, 303, 1, '9SALD1', 'd c1'), (3030002, 303, 2, '9SALD2', 'd c2');
SET ROLE erp_app;
SELECT set_config('app.tenant_id', '303', true);
SELECT throws_ok($$INSERT INTO sal_special_price (id, company_id, special_price_no, customer_id, customer_code, customer_name, material_id, material_code, material_name,
                     special_unit_price, tax_code, valid_from, valid_to, reason_type, reason)
                   VALUES (3030001, 1, 'SP1', 3030002, '9SALC2', 'c c2', 3030001, '9SAL000001', 'm', 1, 'VAT13-OUT', DATE '2026-10-01', DATE '2026-12-31', 'X', 'r')$$,
                 '23503', NULL, 'fk_sal_special_price_cust：公司 1 引用同租户公司 2 的客户 → 23503');
SELECT throws_ok($$INSERT INTO sal_special_price (id, company_id, special_price_no, customer_id, customer_code, customer_name, material_id, material_code, material_name,
                     special_unit_price, tax_code, valid_from, valid_to, reason_type, reason)
                   VALUES (3030002, 1, 'SP2', 3030001, '9SALC1', 'c c1', 3030002, '9SAL000002', 'm', 1, 'VAT13-OUT', DATE '2026-10-01', DATE '2026-12-31', 'X', 'r')$$,
                 '23503', NULL, 'fk_sal_special_price_mat：公司 1 引用同租户公司 2 的物料 → 23503');
SELECT lives_ok($$INSERT INTO sal_special_price (id, company_id, special_price_no, customer_id, customer_code, customer_name, material_id, material_code, material_name,
                    special_unit_price, tax_code, valid_from, valid_to, reason_type, reason)
                  VALUES (3030003, 1, 'SP3', 3030001, '9SALC1', 'c c1', 3030001, '9SAL000001', 'm', 1, 'VAT13-OUT', DATE '2026-10-01', DATE '2026-12-31', 'X', 'r')$$,
                'fk_sal_special_price_*：同公司客户・物料可写入');
SELECT throws_ok($$INSERT INTO sal_sales_forecast (id, company_id, forecast_no, period_code, department_id) VALUES (3030001, 1, 'SF1', '2026-11', 3030002)$$,
                 '23503', NULL, 'fk_sal_forecast_dept：公司 1 引用同租户公司 2 的部门 → 23503');
SELECT lives_ok($$INSERT INTO sal_sales_forecast (id, company_id, forecast_no, period_code, department_id) VALUES (3030002, 1, 'SF2', '2026-11', 3030001)$$,
                'fk_sal_forecast_dept：同公司部门可写入');
RESET ROLE;

SELECT * FROM finish();
ROLLBACK;
