-- mdm 域内部 FK 32 条改为三列 (tenant_id, company_id, x_id) → 被引用表 (tenant_id, company_id, id)。
-- 04 §6.2 项 2a：被引用表有 company_id 时三列为标准形（DB 层拒绝同租户跨公司的父子／主数据引用）。
-- 32 条全部在普通表上（mdm 无分区表）；子表 company_id 均 NOT NULL，约束名不变，NO ACTION。
-- 被引用表 mdm_material / mdm_customer / mdm_supplier / mdm_warehouse / mdm_factory 的 uk_*_tenant_company_id 已存在；
-- 其余 11 张被引用表本迁移新增 uk_<table>_tenant_company_id UNIQUE (tenant_id, company_id, id)。

-- 前置检查：已有数据中子表 company_id 与被引用行 company_id 不一致时中止（需人工处理，不自动修正）
DO $$
DECLARE r record; n bigint; bad text := '';
BEGIN
  FOR r IN SELECT * FROM (VALUES
    ('fk_mdm_admission_supplier', 'mdm_supplier_admission', 'supplier_id', 'mdm_supplier'),
    ('fk_mdm_bank_account_bank', 'mdm_partner_bank_account', 'bank_id', 'mdm_bank'),
    ('fk_mdm_barcode_material', 'mdm_material_barcode', 'material_id', 'mdm_material'),
    ('fk_mdm_change_line_request', 'mdm_change_request_line', 'request_id', 'mdm_change_request'),
    ('fk_mdm_credit_limit_customer', 'mdm_credit_limit', 'customer_id', 'mdm_customer'),
    ('fk_mdm_credit_limit_rule', 'mdm_credit_limit', 'check_rule_id', 'mdm_credit_check_rule'),
    ('fk_mdm_customer_address_customer', 'mdm_customer_address', 'customer_id', 'mdm_customer'),
    ('fk_mdm_customer_contact_customer', 'mdm_customer_contact', 'customer_id', 'mdm_customer'),
    ('fk_mdm_dq_issue_rule', 'mdm_data_quality_issue', 'rule_id', 'mdm_data_quality_rule'),
    ('fk_mdm_eval_item_evaluation', 'mdm_supplier_eval_item', 'evaluation_id', 'mdm_supplier_evaluation'),
    ('fk_mdm_evaluation_supplier', 'mdm_supplier_evaluation', 'supplier_id', 'mdm_supplier'),
    ('fk_mdm_material_category', 'mdm_material', 'category_id', 'mdm_material_category'),
    ('fk_mdm_material_category_parent', 'mdm_material_category', 'parent_id', 'mdm_material_category'),
    ('fk_mdm_material_factory_material', 'mdm_material_factory', 'material_id', 'mdm_material'),
    ('fk_mdm_payment_term_line_term', 'mdm_payment_term_line', 'payment_term_id', 'mdm_payment_term'),
    ('fk_mdm_price_line_list', 'mdm_price_list_line', 'price_list_id', 'mdm_price_list'),
    ('fk_mdm_purchase_price_material', 'mdm_purchase_price', 'material_id', 'mdm_material'),
    ('fk_mdm_purchase_price_supplier', 'mdm_purchase_price', 'supplier_id', 'mdm_supplier'),
    ('fk_mdm_quotation_line_material', 'mdm_supplier_quotation_line', 'material_id', 'mdm_material'),
    ('fk_mdm_quotation_line_quotation', 'mdm_supplier_quotation_line', 'quotation_id', 'mdm_supplier_quotation'),
    ('fk_mdm_quotation_supplier', 'mdm_supplier_quotation', 'supplier_id', 'mdm_supplier'),
    ('fk_mdm_substitute_material', 'mdm_material_substitute', 'material_id', 'mdm_material'),
    ('fk_mdm_substitute_target', 'mdm_material_substitute', 'substitute_material_id', 'mdm_material'),
    ('fk_mdm_supplier_address_supplier', 'mdm_supplier_address', 'supplier_id', 'mdm_supplier'),
    ('fk_mdm_supplier_contact_supplier', 'mdm_supplier_contact', 'supplier_id', 'mdm_supplier'),
    ('fk_mdm_supplier_material_supplier', 'mdm_supplier_material', 'supplier_id', 'mdm_supplier'),
    ('fk_mdm_supplier_qualification_supplier', 'mdm_supplier_qualification', 'supplier_id', 'mdm_supplier'),
    ('fk_mdm_tax_rate_code', 'mdm_tax_rate', 'tax_code_id', 'mdm_tax_code'),
    ('fk_mdm_warehouse_bin_warehouse', 'mdm_warehouse_bin', 'warehouse_id', 'mdm_warehouse'),
    ('fk_mdm_warehouse_bin_zone', 'mdm_warehouse_bin', 'zone_id', 'mdm_warehouse_zone'),
    ('fk_mdm_warehouse_factory', 'mdm_warehouse', 'factory_id', 'mdm_factory'),
    ('fk_mdm_warehouse_zone_warehouse', 'mdm_warehouse_zone', 'warehouse_id', 'mdm_warehouse')
  ) v(con, child, col, parent) LOOP
    EXECUTE format('SELECT count(*) FROM %I c JOIN %I p ON p.tenant_id = c.tenant_id AND p.id = c.%I WHERE p.company_id <> c.company_id',
                   r.child, r.parent, r.col) INTO n;
    IF n > 0 THEN bad := bad || format('%s: %s 行; ', r.con, n); END IF;
  END LOOP;
  IF bad <> '' THEN RAISE EXCEPTION 'mdm 域内部跨公司引用数据存在，无法改为三列 FK：%', bad; END IF;
END $$;

-- 被引用表侧 UNIQUE (tenant_id, company_id, id)：11 张
ALTER TABLE mdm_bank ADD CONSTRAINT uk_mdm_bank_tenant_company_id UNIQUE (tenant_id, company_id, id);
COMMENT ON CONSTRAINT uk_mdm_bank_tenant_company_id ON mdm_bank IS 'FK 参照先専用（三列 FK、04 §6.2 項 2a）。業務一意キーではない';
ALTER TABLE mdm_change_request ADD CONSTRAINT uk_mdm_change_request_tenant_company_id UNIQUE (tenant_id, company_id, id);
COMMENT ON CONSTRAINT uk_mdm_change_request_tenant_company_id ON mdm_change_request IS 'FK 参照先専用（三列 FK、04 §6.2 項 2a）。業務一意キーではない';
ALTER TABLE mdm_credit_check_rule ADD CONSTRAINT uk_mdm_credit_check_rule_tenant_company_id UNIQUE (tenant_id, company_id, id);
COMMENT ON CONSTRAINT uk_mdm_credit_check_rule_tenant_company_id ON mdm_credit_check_rule IS 'FK 参照先専用（三列 FK、04 §6.2 項 2a）。業務一意キーではない';
ALTER TABLE mdm_data_quality_rule ADD CONSTRAINT uk_mdm_data_quality_rule_tenant_company_id UNIQUE (tenant_id, company_id, id);
COMMENT ON CONSTRAINT uk_mdm_data_quality_rule_tenant_company_id ON mdm_data_quality_rule IS 'FK 参照先専用（三列 FK、04 §6.2 項 2a）。業務一意キーではない';
ALTER TABLE mdm_material_category ADD CONSTRAINT uk_mdm_material_category_tenant_company_id UNIQUE (tenant_id, company_id, id);
COMMENT ON CONSTRAINT uk_mdm_material_category_tenant_company_id ON mdm_material_category IS 'FK 参照先専用（三列 FK、04 §6.2 項 2a）。業務一意キーではない';
ALTER TABLE mdm_payment_term ADD CONSTRAINT uk_mdm_payment_term_tenant_company_id UNIQUE (tenant_id, company_id, id);
COMMENT ON CONSTRAINT uk_mdm_payment_term_tenant_company_id ON mdm_payment_term IS 'FK 参照先専用（三列 FK、04 §6.2 項 2a）。業務一意キーではない';
ALTER TABLE mdm_price_list ADD CONSTRAINT uk_mdm_price_list_tenant_company_id UNIQUE (tenant_id, company_id, id);
COMMENT ON CONSTRAINT uk_mdm_price_list_tenant_company_id ON mdm_price_list IS 'FK 参照先専用（三列 FK、04 §6.2 項 2a）。業務一意キーではない';
ALTER TABLE mdm_supplier_evaluation ADD CONSTRAINT uk_mdm_supplier_evaluation_tenant_company_id UNIQUE (tenant_id, company_id, id);
COMMENT ON CONSTRAINT uk_mdm_supplier_evaluation_tenant_company_id ON mdm_supplier_evaluation IS 'FK 参照先専用（三列 FK、04 §6.2 項 2a）。業務一意キーではない';
ALTER TABLE mdm_supplier_quotation ADD CONSTRAINT uk_mdm_supplier_quotation_tenant_company_id UNIQUE (tenant_id, company_id, id);
COMMENT ON CONSTRAINT uk_mdm_supplier_quotation_tenant_company_id ON mdm_supplier_quotation IS 'FK 参照先専用（三列 FK、04 §6.2 項 2a）。業務一意キーではない';
ALTER TABLE mdm_tax_code ADD CONSTRAINT uk_mdm_tax_code_tenant_company_id UNIQUE (tenant_id, company_id, id);
COMMENT ON CONSTRAINT uk_mdm_tax_code_tenant_company_id ON mdm_tax_code IS 'FK 参照先専用（三列 FK、04 §6.2 項 2a）。業務一意キーではない';
ALTER TABLE mdm_warehouse_zone ADD CONSTRAINT uk_mdm_warehouse_zone_tenant_company_id UNIQUE (tenant_id, company_id, id);
COMMENT ON CONSTRAINT uk_mdm_warehouse_zone_tenant_company_id ON mdm_warehouse_zone IS 'FK 参照先専用（三列 FK、04 §6.2 項 2a）。業務一意キーではない';

ALTER TABLE mdm_supplier_admission DROP CONSTRAINT fk_mdm_admission_supplier;
ALTER TABLE mdm_supplier_admission ADD CONSTRAINT fk_mdm_admission_supplier FOREIGN KEY (tenant_id, company_id, supplier_id) REFERENCES mdm_supplier (tenant_id, company_id, id);
ALTER TABLE mdm_partner_bank_account DROP CONSTRAINT fk_mdm_bank_account_bank;
ALTER TABLE mdm_partner_bank_account ADD CONSTRAINT fk_mdm_bank_account_bank FOREIGN KEY (tenant_id, company_id, bank_id) REFERENCES mdm_bank (tenant_id, company_id, id);
ALTER TABLE mdm_material_barcode DROP CONSTRAINT fk_mdm_barcode_material;
ALTER TABLE mdm_material_barcode ADD CONSTRAINT fk_mdm_barcode_material FOREIGN KEY (tenant_id, company_id, material_id) REFERENCES mdm_material (tenant_id, company_id, id);
ALTER TABLE mdm_change_request_line DROP CONSTRAINT fk_mdm_change_line_request;
ALTER TABLE mdm_change_request_line ADD CONSTRAINT fk_mdm_change_line_request FOREIGN KEY (tenant_id, company_id, request_id) REFERENCES mdm_change_request (tenant_id, company_id, id);
ALTER TABLE mdm_credit_limit DROP CONSTRAINT fk_mdm_credit_limit_customer;
ALTER TABLE mdm_credit_limit ADD CONSTRAINT fk_mdm_credit_limit_customer FOREIGN KEY (tenant_id, company_id, customer_id) REFERENCES mdm_customer (tenant_id, company_id, id);
ALTER TABLE mdm_credit_limit DROP CONSTRAINT fk_mdm_credit_limit_rule;
ALTER TABLE mdm_credit_limit ADD CONSTRAINT fk_mdm_credit_limit_rule FOREIGN KEY (tenant_id, company_id, check_rule_id) REFERENCES mdm_credit_check_rule (tenant_id, company_id, id);
ALTER TABLE mdm_customer_address DROP CONSTRAINT fk_mdm_customer_address_customer;
ALTER TABLE mdm_customer_address ADD CONSTRAINT fk_mdm_customer_address_customer FOREIGN KEY (tenant_id, company_id, customer_id) REFERENCES mdm_customer (tenant_id, company_id, id);
ALTER TABLE mdm_customer_contact DROP CONSTRAINT fk_mdm_customer_contact_customer;
ALTER TABLE mdm_customer_contact ADD CONSTRAINT fk_mdm_customer_contact_customer FOREIGN KEY (tenant_id, company_id, customer_id) REFERENCES mdm_customer (tenant_id, company_id, id);
ALTER TABLE mdm_data_quality_issue DROP CONSTRAINT fk_mdm_dq_issue_rule;
ALTER TABLE mdm_data_quality_issue ADD CONSTRAINT fk_mdm_dq_issue_rule FOREIGN KEY (tenant_id, company_id, rule_id) REFERENCES mdm_data_quality_rule (tenant_id, company_id, id);
ALTER TABLE mdm_supplier_eval_item DROP CONSTRAINT fk_mdm_eval_item_evaluation;
ALTER TABLE mdm_supplier_eval_item ADD CONSTRAINT fk_mdm_eval_item_evaluation FOREIGN KEY (tenant_id, company_id, evaluation_id) REFERENCES mdm_supplier_evaluation (tenant_id, company_id, id);
ALTER TABLE mdm_supplier_evaluation DROP CONSTRAINT fk_mdm_evaluation_supplier;
ALTER TABLE mdm_supplier_evaluation ADD CONSTRAINT fk_mdm_evaluation_supplier FOREIGN KEY (tenant_id, company_id, supplier_id) REFERENCES mdm_supplier (tenant_id, company_id, id);
ALTER TABLE mdm_material DROP CONSTRAINT fk_mdm_material_category;
ALTER TABLE mdm_material ADD CONSTRAINT fk_mdm_material_category FOREIGN KEY (tenant_id, company_id, category_id) REFERENCES mdm_material_category (tenant_id, company_id, id);
ALTER TABLE mdm_material_category DROP CONSTRAINT fk_mdm_material_category_parent;
ALTER TABLE mdm_material_category ADD CONSTRAINT fk_mdm_material_category_parent FOREIGN KEY (tenant_id, company_id, parent_id) REFERENCES mdm_material_category (tenant_id, company_id, id);
ALTER TABLE mdm_material_factory DROP CONSTRAINT fk_mdm_material_factory_material;
ALTER TABLE mdm_material_factory ADD CONSTRAINT fk_mdm_material_factory_material FOREIGN KEY (tenant_id, company_id, material_id) REFERENCES mdm_material (tenant_id, company_id, id);
ALTER TABLE mdm_payment_term_line DROP CONSTRAINT fk_mdm_payment_term_line_term;
ALTER TABLE mdm_payment_term_line ADD CONSTRAINT fk_mdm_payment_term_line_term FOREIGN KEY (tenant_id, company_id, payment_term_id) REFERENCES mdm_payment_term (tenant_id, company_id, id);
ALTER TABLE mdm_price_list_line DROP CONSTRAINT fk_mdm_price_line_list;
ALTER TABLE mdm_price_list_line ADD CONSTRAINT fk_mdm_price_line_list FOREIGN KEY (tenant_id, company_id, price_list_id) REFERENCES mdm_price_list (tenant_id, company_id, id);
ALTER TABLE mdm_purchase_price DROP CONSTRAINT fk_mdm_purchase_price_material;
ALTER TABLE mdm_purchase_price ADD CONSTRAINT fk_mdm_purchase_price_material FOREIGN KEY (tenant_id, company_id, material_id) REFERENCES mdm_material (tenant_id, company_id, id);
ALTER TABLE mdm_purchase_price DROP CONSTRAINT fk_mdm_purchase_price_supplier;
ALTER TABLE mdm_purchase_price ADD CONSTRAINT fk_mdm_purchase_price_supplier FOREIGN KEY (tenant_id, company_id, supplier_id) REFERENCES mdm_supplier (tenant_id, company_id, id);
ALTER TABLE mdm_supplier_quotation_line DROP CONSTRAINT fk_mdm_quotation_line_material;
ALTER TABLE mdm_supplier_quotation_line ADD CONSTRAINT fk_mdm_quotation_line_material FOREIGN KEY (tenant_id, company_id, material_id) REFERENCES mdm_material (tenant_id, company_id, id);
ALTER TABLE mdm_supplier_quotation_line DROP CONSTRAINT fk_mdm_quotation_line_quotation;
ALTER TABLE mdm_supplier_quotation_line ADD CONSTRAINT fk_mdm_quotation_line_quotation FOREIGN KEY (tenant_id, company_id, quotation_id) REFERENCES mdm_supplier_quotation (tenant_id, company_id, id);
ALTER TABLE mdm_supplier_quotation DROP CONSTRAINT fk_mdm_quotation_supplier;
ALTER TABLE mdm_supplier_quotation ADD CONSTRAINT fk_mdm_quotation_supplier FOREIGN KEY (tenant_id, company_id, supplier_id) REFERENCES mdm_supplier (tenant_id, company_id, id);
ALTER TABLE mdm_material_substitute DROP CONSTRAINT fk_mdm_substitute_material;
ALTER TABLE mdm_material_substitute ADD CONSTRAINT fk_mdm_substitute_material FOREIGN KEY (tenant_id, company_id, material_id) REFERENCES mdm_material (tenant_id, company_id, id);
ALTER TABLE mdm_material_substitute DROP CONSTRAINT fk_mdm_substitute_target;
ALTER TABLE mdm_material_substitute ADD CONSTRAINT fk_mdm_substitute_target FOREIGN KEY (tenant_id, company_id, substitute_material_id) REFERENCES mdm_material (tenant_id, company_id, id);
ALTER TABLE mdm_supplier_address DROP CONSTRAINT fk_mdm_supplier_address_supplier;
ALTER TABLE mdm_supplier_address ADD CONSTRAINT fk_mdm_supplier_address_supplier FOREIGN KEY (tenant_id, company_id, supplier_id) REFERENCES mdm_supplier (tenant_id, company_id, id);
ALTER TABLE mdm_supplier_contact DROP CONSTRAINT fk_mdm_supplier_contact_supplier;
ALTER TABLE mdm_supplier_contact ADD CONSTRAINT fk_mdm_supplier_contact_supplier FOREIGN KEY (tenant_id, company_id, supplier_id) REFERENCES mdm_supplier (tenant_id, company_id, id);
ALTER TABLE mdm_supplier_material DROP CONSTRAINT fk_mdm_supplier_material_supplier;
ALTER TABLE mdm_supplier_material ADD CONSTRAINT fk_mdm_supplier_material_supplier FOREIGN KEY (tenant_id, company_id, supplier_id) REFERENCES mdm_supplier (tenant_id, company_id, id);
ALTER TABLE mdm_supplier_qualification DROP CONSTRAINT fk_mdm_supplier_qualification_supplier;
ALTER TABLE mdm_supplier_qualification ADD CONSTRAINT fk_mdm_supplier_qualification_supplier FOREIGN KEY (tenant_id, company_id, supplier_id) REFERENCES mdm_supplier (tenant_id, company_id, id);
ALTER TABLE mdm_tax_rate DROP CONSTRAINT fk_mdm_tax_rate_code;
ALTER TABLE mdm_tax_rate ADD CONSTRAINT fk_mdm_tax_rate_code FOREIGN KEY (tenant_id, company_id, tax_code_id) REFERENCES mdm_tax_code (tenant_id, company_id, id);
ALTER TABLE mdm_warehouse_bin DROP CONSTRAINT fk_mdm_warehouse_bin_warehouse;
ALTER TABLE mdm_warehouse_bin ADD CONSTRAINT fk_mdm_warehouse_bin_warehouse FOREIGN KEY (tenant_id, company_id, warehouse_id) REFERENCES mdm_warehouse (tenant_id, company_id, id);
ALTER TABLE mdm_warehouse_bin DROP CONSTRAINT fk_mdm_warehouse_bin_zone;
ALTER TABLE mdm_warehouse_bin ADD CONSTRAINT fk_mdm_warehouse_bin_zone FOREIGN KEY (tenant_id, company_id, zone_id) REFERENCES mdm_warehouse_zone (tenant_id, company_id, id);
ALTER TABLE mdm_warehouse DROP CONSTRAINT fk_mdm_warehouse_factory;
ALTER TABLE mdm_warehouse ADD CONSTRAINT fk_mdm_warehouse_factory FOREIGN KEY (tenant_id, company_id, factory_id) REFERENCES mdm_factory (tenant_id, company_id, id);
ALTER TABLE mdm_warehouse_zone DROP CONSTRAINT fk_mdm_warehouse_zone_warehouse;
ALTER TABLE mdm_warehouse_zone ADD CONSTRAINT fk_mdm_warehouse_zone_warehouse FOREIGN KEY (tenant_id, company_id, warehouse_id) REFERENCES mdm_warehouse (tenant_id, company_id, id);

-- 三列 FK 子表侧索引：32 条中 25 条已有以 (tenant_id, company_id, x_id) 打头的 btree 索引（含 uk_），以下 7 条缺失，本迁移补齐。
CREATE INDEX idx_mdm_admission_supplier ON mdm_supplier_admission (tenant_id, company_id, supplier_id);
CREATE INDEX idx_mdm_bank_account_bank ON mdm_partner_bank_account (tenant_id, company_id, bank_id);
CREATE INDEX idx_mdm_credit_limit_rule ON mdm_credit_limit (tenant_id, company_id, check_rule_id);
CREATE INDEX idx_mdm_dq_issue_rule ON mdm_data_quality_issue (tenant_id, company_id, rule_id);
CREATE INDEX idx_mdm_quotation_line_material ON mdm_supplier_quotation_line (tenant_id, company_id, material_id);
CREATE INDEX idx_mdm_warehouse_bin_zone ON mdm_warehouse_bin (tenant_id, company_id, zone_id);
CREATE INDEX idx_mdm_warehouse_factory ON mdm_warehouse (tenant_id, company_id, factory_id);
