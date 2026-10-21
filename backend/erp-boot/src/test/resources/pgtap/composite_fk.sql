-- pgTAP：复合外键（sys/V202610210707、inv/V202610211409・V202610211410、prd/V202610211411）。指向有 company_id 的 sys_/mdm_ 表的 FK 须为三列 (tenant_id, company_id, x)（2 列须登记：已定例外或待改存量），跨租户引用被拒。
BEGIN;
SELECT plan(13);

SELECT is((SELECT count(*)::int FROM pg_constraint k JOIN pg_class r ON r.oid = k.confrelid
            WHERE k.contype = 'f' AND array_length(k.conkey, 1) = 1 AND r.relname ~ '^(sys|mdm)_'),
          0, '指向 sys_/mdm_ 的单列外键为 0');
-- 断言 2（收紧）：被引用表有 company_id 时只允许三列 (tenant_id, company_id, x) → (tenant_id, company_id, id)；
-- 被引用表无 company_id 时为 (tenant_id, x) → (tenant_id, id)。被引用侧末列必须是 id。
-- 2 列 (tenant_id, x) → (tenant_id, id) 登记表：〔A〕已定例外 1 条、〔B〕待改为三列（存量，按域分批）47 条（inv 27 条已由 inv/V202610211410、prd 29 条已由 prd/V202610211411 改为三列）。新增 FK 不得默认走 2 列。
CREATE TEMP TABLE t_cfk_2col_exception (conname name PRIMARY KEY) ON COMMIT DROP;
INSERT INTO t_cfk_2col_exception VALUES
        -- 〔A〕已定例外 1 条（04 §6.2 2a 命名例外）
        -- 指向 sys_menu（company_id=0 的租户级表）1 条
        ('fk_sys_role_permission_menu'),
        -- 〔B〕待改为三列（存量，按域分批）47 条：sal 14／fin 1／mdm 32（inv 27 条已于 inv/V202610211410、prd 29 条已于 prd/V202610211411 改为三列）
        -- mdm 域内部 32 条
        ('fk_mdm_admission_supplier'),
        ('fk_mdm_bank_account_bank'),
        ('fk_mdm_barcode_material'),
        ('fk_mdm_change_line_request'),
        ('fk_mdm_credit_limit_customer'),
        ('fk_mdm_credit_limit_rule'),
        ('fk_mdm_customer_address_customer'),
        ('fk_mdm_customer_contact_customer'),
        ('fk_mdm_dq_issue_rule'),
        ('fk_mdm_eval_item_evaluation'),
        ('fk_mdm_evaluation_supplier'),
        ('fk_mdm_material_category'),
        ('fk_mdm_material_category_parent'),
        ('fk_mdm_material_factory_material'),
        ('fk_mdm_payment_term_line_term'),
        ('fk_mdm_price_line_list'),
        ('fk_mdm_purchase_price_material'),
        ('fk_mdm_purchase_price_supplier'),
        ('fk_mdm_quotation_line_material'),
        ('fk_mdm_quotation_line_quotation'),
        ('fk_mdm_quotation_supplier'),
        ('fk_mdm_substitute_material'),
        ('fk_mdm_substitute_target'),
        ('fk_mdm_supplier_address_supplier'),
        ('fk_mdm_supplier_contact_supplier'),
        ('fk_mdm_supplier_material_supplier'),
        ('fk_mdm_supplier_qualification_supplier'),
        ('fk_mdm_tax_rate_code'),
        ('fk_mdm_warehouse_bin_warehouse'),
        ('fk_mdm_warehouse_bin_zone'),
        ('fk_mdm_warehouse_factory'),
        ('fk_mdm_warehouse_zone_warehouse'),
        -- fin 1 条
        ('fk_fin_standard_cost_material'),
        -- sal 14 条
        ('fk_sal_credit_log_customer'),
        ('fk_sal_credit_occ_customer'),
        ('fk_sal_delivery_note_wh'),
        ('fk_sal_forecast_dept'),
        ('fk_sal_inquiry_customer'),
        ('fk_sal_inquiry_line_material'),
        ('fk_sal_invoice_customer'),
        ('fk_sal_iva_customer'),
        ('fk_sal_quotation_customer'),
        ('fk_sal_sales_order_customer'),
        ('fk_sal_sales_order_line_m'),
        ('fk_sal_special_price_cust'),
        ('fk_sal_special_price_mat'),
        ('fk_sal_statement_customer');
CREATE TEMP TABLE t_cfk ON COMMIT DROP AS
SELECT k.conname, r.relname AS parent,
       EXISTS (SELECT 1 FROM pg_attribute x WHERE x.attrelid = r.oid AND x.attname = 'company_id' AND NOT x.attisdropped) AS parent_has_co,
       (SELECT array_agg(a.attname ORDER BY o.n) FROM unnest(k.conkey) WITH ORDINALITY o(att, n)
          JOIN pg_attribute a ON a.attrelid = k.conrelid AND a.attnum = o.att) AS cols,
       (SELECT array_agg(a.attname ORDER BY o.n) FROM unnest(k.confkey) WITH ORDINALITY o(att, n)
          JOIN pg_attribute a ON a.attrelid = k.confrelid AND a.attnum = o.att) AS refcols
FROM pg_constraint k JOIN pg_class r ON r.oid = k.confrelid
WHERE k.contype = 'f' AND r.relname ~ '^(sys|mdm)_';
SELECT is((SELECT count(*)::int FROM t_cfk
            WHERE NOT CASE
              WHEN parent_has_co AND conname NOT IN (SELECT conname FROM t_cfk_2col_exception)
                THEN array_length(cols, 1) = 3 AND cols[1] = 'tenant_id' AND cols[2] = 'company_id'
                     AND refcols = ARRAY['tenant_id', 'company_id', 'id']::name[]
              ELSE array_length(cols, 1) = 2 AND cols[1] = 'tenant_id' AND refcols = ARRAY['tenant_id', 'id']::name[]
            END),
          0, '指向 sys_/mdm_ 的外键：被引用表有 company_id → (tenant_id, company_id, x) → (tenant_id, company_id, id)（登记表〔A〕已定例外／〔B〕待改为三列存量为 (tenant_id, x) → (tenant_id, id)）；无 company_id → (tenant_id, x) → (tenant_id, id)');
SELECT is((SELECT count(*)::int FROM t_cfk_2col_exception e
            WHERE NOT EXISTS (SELECT 1 FROM t_cfk f WHERE f.conname = e.conname AND f.parent_has_co)),
          0, '2 列登记表（〔A〕+〔B〕）全部真实存在且被引用表有 company_id（防止例外表陈旧）');
SELECT ok(EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'uk_mdm_material_tenant_id' AND contype = 'u'),
          'mdm_material 有 uk_mdm_material_tenant_id UNIQUE (tenant_id, id)');
SELECT is((SELECT count(*)::int FROM t_cfk WHERE conname ~ '^fk_inv_'
            AND NOT (cols[1:2] = ARRAY['tenant_id', 'company_id']::name[] AND refcols = ARRAY['tenant_id', 'company_id', 'id']::name[])),
          0, 'inv → mdm FK 28 条全部为 04 §6.2 2a 标准三列形（inv/V202610211409・V202610211410），登记表无 fk_inv_*');
SELECT is((SELECT count(*)::int FROM t_cfk WHERE conname ~ '^fk_prd_'
            AND NOT (cols[1:2] = ARRAY['tenant_id', 'company_id']::name[] AND refcols = ARRAY['tenant_id', 'company_id', 'id']::name[])),
          0, 'prd → mdm FK 29 条全部为 04 §6.2 2a 标准三列形（prd/V202610211411），登记表无 fk_prd_*');
SELECT is((SELECT pg_get_constraintdef(oid) FROM pg_constraint WHERE conname = 'fk_inv_stock_balance_material'),
          'FOREIGN KEY (tenant_id, company_id, material_id) REFERENCES mdm_material(tenant_id, company_id, id)',
          'fk_inv_stock_balance_material 为 04 §6.2 2a 标准三列形 = (tenant_id, company_id, material_id) → mdm_material(tenant_id, company_id, id)');

SELECT is((SELECT count(*)::int FROM pg_index i JOIN pg_class tc ON tc.oid = i.indrelid
            LEFT JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = i.indkey[0]
            JOIN pg_class ic ON ic.oid = i.indexrelid JOIN pg_am am ON am.oid = ic.relam
            JOIN pg_namespace n ON n.oid = tc.relnamespace
            WHERE n.nspname = 'public' AND tc.relname ~ '^(sys|mdm|sal|fin|prd|inv)_' AND am.amname = 'btree' AND NOT i.indisprimary AND NOT i.indisunique
              AND a.attname IS DISTINCT FROM 'tenant_id'),
          0, 'sys/mdm/sal/fin/prd/inv 全部普通 btree 索引以 tenant_id 打头（GIN 除外）');
-- 唯一键：有 company_id 的表以 (tenant_id, company_id) 打头，无 company_id 的表以 tenant_id 打头（int 域暂不覆盖）
-- 豁免：复合 FK 被引用的 UNIQUE (tenant_id, id)；下列（表名, 索引名）租户级唯一键（已定），只放行列出的组合
SELECT is((SELECT count(*)::int FROM pg_index i
            JOIN pg_class tc ON tc.oid = i.indrelid JOIN pg_class ic ON ic.oid = i.indexrelid
            JOIN pg_namespace n ON n.oid = tc.relnamespace
            LEFT JOIN pg_attribute a0 ON a0.attrelid = tc.oid AND a0.attnum = i.indkey[0]
            LEFT JOIN pg_attribute a1 ON a1.attrelid = tc.oid AND a1.attnum = i.indkey[1]
            WHERE n.nspname = 'public' AND tc.relname ~ '^(sys|mdm|sal|fin|prd|inv)_'
              AND i.indisunique AND NOT i.indisprimary
              AND (tc.relname, ic.relname) NOT IN (
                    ('sys_company', 'uk_sys_company_code'), ('sys_company', 'uk_sys_company_credit'),
                    ('sys_menu', 'uk_sys_menu_code'),
                    ('sys_dict_type', 'uk_sys_dict_type_code'), ('sys_outbox_event', 'uk_sys_outbox_event_id'),
                    ('sys_idempotency', 'uk_sys_idempotency_key'), ('mdm_exchange_rate', 'uk_mdm_exchange_rate'),
                    ('sys_user', 'uk_sys_user_username'),
                    ('sys_tenant', 'uk_sys_tenant_code'))  -- 04 §6.1 第 4 条 (c) 全体一意（tenant_id 不打头）
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
