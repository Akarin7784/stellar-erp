-- sal → mdm/sys 跨域 FK 14 条改为三列 (tenant_id, company_id, x_id) → 被引用表 (tenant_id, company_id, id)。
-- 04 §6.2 项 2a：被引用表有 company_id 时三列为标准形（DB 层拒绝引用同租户其他公司的主数据）。
-- 14 条全部在普通表上（sal 无分区表）；子表 company_id 均 NOT NULL，约束名不变，NO ACTION。
-- 被引用表 mdm_customer / mdm_material / mdm_warehouse / sys_department 的 uk_*_tenant_company_id 均已存在，本迁移不新增 UNIQUE。

-- 前置检查：已有数据中子表 company_id 与被引用行 company_id 不一致时中止（需人工处理，不自动修正）
DO $$
DECLARE r record; n bigint; bad text := '';
BEGIN
  FOR r IN SELECT * FROM (VALUES
    ('fk_sal_credit_log_customer', 'sal_credit_check_log', 'customer_id', 'mdm_customer'),
    ('fk_sal_credit_occ_customer', 'sal_credit_ledger_snapshot', 'customer_id', 'mdm_customer'),
    ('fk_sal_delivery_note_wh', 'sal_delivery_note', 'warehouse_id', 'mdm_warehouse'),
    ('fk_sal_forecast_dept', 'sal_sales_forecast', 'department_id', 'sys_department'),
    ('fk_sal_inquiry_customer', 'sal_inquiry', 'customer_id', 'mdm_customer'),
    ('fk_sal_inquiry_line_material', 'sal_inquiry_line', 'material_id', 'mdm_material'),
    ('fk_sal_invoice_customer', 'sal_invoice', 'customer_id', 'mdm_customer'),
    ('fk_sal_iva_customer', 'sal_invoice_application', 'customer_id', 'mdm_customer'),
    ('fk_sal_quotation_customer', 'sal_quotation', 'customer_id', 'mdm_customer'),
    ('fk_sal_sales_order_customer', 'sal_sales_order', 'customer_id', 'mdm_customer'),
    ('fk_sal_sales_order_line_m', 'sal_sales_order_line', 'material_id', 'mdm_material'),
    ('fk_sal_special_price_cust', 'sal_special_price', 'customer_id', 'mdm_customer'),
    ('fk_sal_special_price_mat', 'sal_special_price', 'material_id', 'mdm_material'),
    ('fk_sal_statement_customer', 'sal_statement', 'customer_id', 'mdm_customer')
  ) v(con, child, col, parent) LOOP
    EXECUTE format('SELECT count(*) FROM %I c JOIN %I p ON p.tenant_id = c.tenant_id AND p.id = c.%I WHERE p.company_id <> c.company_id',
                   r.child, r.parent, r.col) INTO n;
    IF n > 0 THEN bad := bad || format('%s: %s 行; ', r.con, n); END IF;
  END LOOP;
  IF bad <> '' THEN RAISE EXCEPTION 'sal → mdm/sys 跨公司引用数据存在，无法改为三列 FK：%', bad; END IF;
END $$;

ALTER TABLE sal_credit_check_log DROP CONSTRAINT fk_sal_credit_log_customer;
ALTER TABLE sal_credit_check_log ADD CONSTRAINT fk_sal_credit_log_customer FOREIGN KEY (tenant_id, company_id, customer_id) REFERENCES mdm_customer (tenant_id, company_id, id);
ALTER TABLE sal_credit_ledger_snapshot DROP CONSTRAINT fk_sal_credit_occ_customer;
ALTER TABLE sal_credit_ledger_snapshot ADD CONSTRAINT fk_sal_credit_occ_customer FOREIGN KEY (tenant_id, company_id, customer_id) REFERENCES mdm_customer (tenant_id, company_id, id);
ALTER TABLE sal_delivery_note DROP CONSTRAINT fk_sal_delivery_note_wh;
ALTER TABLE sal_delivery_note ADD CONSTRAINT fk_sal_delivery_note_wh FOREIGN KEY (tenant_id, company_id, warehouse_id) REFERENCES mdm_warehouse (tenant_id, company_id, id);
ALTER TABLE sal_sales_forecast DROP CONSTRAINT fk_sal_forecast_dept;
ALTER TABLE sal_sales_forecast ADD CONSTRAINT fk_sal_forecast_dept FOREIGN KEY (tenant_id, company_id, department_id) REFERENCES sys_department (tenant_id, company_id, id);
ALTER TABLE sal_inquiry DROP CONSTRAINT fk_sal_inquiry_customer;
ALTER TABLE sal_inquiry ADD CONSTRAINT fk_sal_inquiry_customer FOREIGN KEY (tenant_id, company_id, customer_id) REFERENCES mdm_customer (tenant_id, company_id, id);
ALTER TABLE sal_inquiry_line DROP CONSTRAINT fk_sal_inquiry_line_material;
ALTER TABLE sal_inquiry_line ADD CONSTRAINT fk_sal_inquiry_line_material FOREIGN KEY (tenant_id, company_id, material_id) REFERENCES mdm_material (tenant_id, company_id, id);
ALTER TABLE sal_invoice DROP CONSTRAINT fk_sal_invoice_customer;
ALTER TABLE sal_invoice ADD CONSTRAINT fk_sal_invoice_customer FOREIGN KEY (tenant_id, company_id, customer_id) REFERENCES mdm_customer (tenant_id, company_id, id);
ALTER TABLE sal_invoice_application DROP CONSTRAINT fk_sal_iva_customer;
ALTER TABLE sal_invoice_application ADD CONSTRAINT fk_sal_iva_customer FOREIGN KEY (tenant_id, company_id, customer_id) REFERENCES mdm_customer (tenant_id, company_id, id);
ALTER TABLE sal_quotation DROP CONSTRAINT fk_sal_quotation_customer;
ALTER TABLE sal_quotation ADD CONSTRAINT fk_sal_quotation_customer FOREIGN KEY (tenant_id, company_id, customer_id) REFERENCES mdm_customer (tenant_id, company_id, id);
ALTER TABLE sal_sales_order DROP CONSTRAINT fk_sal_sales_order_customer;
ALTER TABLE sal_sales_order ADD CONSTRAINT fk_sal_sales_order_customer FOREIGN KEY (tenant_id, company_id, customer_id) REFERENCES mdm_customer (tenant_id, company_id, id);
ALTER TABLE sal_sales_order_line DROP CONSTRAINT fk_sal_sales_order_line_m;
ALTER TABLE sal_sales_order_line ADD CONSTRAINT fk_sal_sales_order_line_m FOREIGN KEY (tenant_id, company_id, material_id) REFERENCES mdm_material (tenant_id, company_id, id);
ALTER TABLE sal_special_price DROP CONSTRAINT fk_sal_special_price_cust;
ALTER TABLE sal_special_price ADD CONSTRAINT fk_sal_special_price_cust FOREIGN KEY (tenant_id, company_id, customer_id) REFERENCES mdm_customer (tenant_id, company_id, id);
ALTER TABLE sal_special_price DROP CONSTRAINT fk_sal_special_price_mat;
ALTER TABLE sal_special_price ADD CONSTRAINT fk_sal_special_price_mat FOREIGN KEY (tenant_id, company_id, material_id) REFERENCES mdm_material (tenant_id, company_id, id);
ALTER TABLE sal_statement DROP CONSTRAINT fk_sal_statement_customer;
ALTER TABLE sal_statement ADD CONSTRAINT fk_sal_statement_customer FOREIGN KEY (tenant_id, company_id, customer_id) REFERENCES mdm_customer (tenant_id, company_id, id);

-- 三列 FK 子表侧索引：14 条中 11 条已有以 (tenant_id, company_id, x_id) 打头的 btree 索引（含 uk_），以下 3 条缺失，本迁移补齐。
CREATE INDEX idx_sal_delivery_note_wh ON sal_delivery_note (tenant_id, company_id, warehouse_id);
CREATE INDEX idx_sal_forecast_dept ON sal_sales_forecast (tenant_id, company_id, department_id);
CREATE INDEX idx_sal_special_price_mat ON sal_special_price (tenant_id, company_id, material_id);
