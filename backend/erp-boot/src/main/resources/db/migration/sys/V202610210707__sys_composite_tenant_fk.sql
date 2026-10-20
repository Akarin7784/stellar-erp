-- 跨表外键改为复合外键 (tenant_id, x_id) → (tenant_id, id)（蓝色大肥鱼 2026-10-21 决定）
-- 范围：main（4c2a206）上全部指向 sys_* / mdm_* 的单列外键，共 76 处（mdm 32 / prd 29 / sal 14 / fin 1）；
--       原约束均为 ON UPDATE/DELETE NO ACTION、MATCH SIMPLE、不可延迟，重建保持一致、保留原约束名。
-- 被引用表 17 张各加 UNIQUE (tenant_id, id)（uk_<table>_tenant_id）。表内无数据，直接建（不用 NOT VALID）。
-- 同时：全部普通 btree 索引改为 tenant_id 打头（GIN 除外）；uk_sal_credit_occ_source / uk_sal_receivable_snapshot_fin 改为 (tenant_id, company_id, …) 打头。

-- 1. 被引用表加 UNIQUE (tenant_id, id)
ALTER TABLE mdm_bank ADD CONSTRAINT uk_mdm_bank_tenant_id UNIQUE (tenant_id, id);
ALTER TABLE mdm_change_request ADD CONSTRAINT uk_mdm_change_request_tenant_id UNIQUE (tenant_id, id);
ALTER TABLE mdm_credit_check_rule ADD CONSTRAINT uk_mdm_credit_check_rule_tenant_id UNIQUE (tenant_id, id);
ALTER TABLE mdm_customer ADD CONSTRAINT uk_mdm_customer_tenant_id UNIQUE (tenant_id, id);
ALTER TABLE mdm_data_quality_rule ADD CONSTRAINT uk_mdm_data_quality_rule_tenant_id UNIQUE (tenant_id, id);
ALTER TABLE mdm_factory ADD CONSTRAINT uk_mdm_factory_tenant_id UNIQUE (tenant_id, id);
ALTER TABLE mdm_material ADD CONSTRAINT uk_mdm_material_tenant_id UNIQUE (tenant_id, id);
ALTER TABLE mdm_material_category ADD CONSTRAINT uk_mdm_material_category_tenant_id UNIQUE (tenant_id, id);
ALTER TABLE mdm_payment_term ADD CONSTRAINT uk_mdm_payment_term_tenant_id UNIQUE (tenant_id, id);
ALTER TABLE mdm_price_list ADD CONSTRAINT uk_mdm_price_list_tenant_id UNIQUE (tenant_id, id);
ALTER TABLE mdm_supplier ADD CONSTRAINT uk_mdm_supplier_tenant_id UNIQUE (tenant_id, id);
ALTER TABLE mdm_supplier_evaluation ADD CONSTRAINT uk_mdm_supplier_evaluation_tenant_id UNIQUE (tenant_id, id);
ALTER TABLE mdm_supplier_quotation ADD CONSTRAINT uk_mdm_supplier_quotation_tenant_id UNIQUE (tenant_id, id);
ALTER TABLE mdm_tax_code ADD CONSTRAINT uk_mdm_tax_code_tenant_id UNIQUE (tenant_id, id);
ALTER TABLE mdm_warehouse ADD CONSTRAINT uk_mdm_warehouse_tenant_id UNIQUE (tenant_id, id);
ALTER TABLE mdm_warehouse_zone ADD CONSTRAINT uk_mdm_warehouse_zone_tenant_id UNIQUE (tenant_id, id);
ALTER TABLE sys_department ADD CONSTRAINT uk_sys_department_tenant_id UNIQUE (tenant_id, id);

-- 2. 单列 FK → 复合 FK
ALTER TABLE fin_standard_cost DROP CONSTRAINT fk_fin_standard_cost_material,
    ADD CONSTRAINT fk_fin_standard_cost_material FOREIGN KEY (tenant_id, material_id) REFERENCES mdm_material (tenant_id, id);
ALTER TABLE mdm_change_request_line DROP CONSTRAINT fk_mdm_change_line_request,
    ADD CONSTRAINT fk_mdm_change_line_request FOREIGN KEY (tenant_id, request_id) REFERENCES mdm_change_request (tenant_id, id);
ALTER TABLE mdm_credit_limit DROP CONSTRAINT fk_mdm_credit_limit_customer,
    ADD CONSTRAINT fk_mdm_credit_limit_customer FOREIGN KEY (tenant_id, customer_id) REFERENCES mdm_customer (tenant_id, id);
ALTER TABLE mdm_credit_limit DROP CONSTRAINT fk_mdm_credit_limit_rule,
    ADD CONSTRAINT fk_mdm_credit_limit_rule FOREIGN KEY (tenant_id, check_rule_id) REFERENCES mdm_credit_check_rule (tenant_id, id);
ALTER TABLE mdm_customer_address DROP CONSTRAINT fk_mdm_customer_address_customer,
    ADD CONSTRAINT fk_mdm_customer_address_customer FOREIGN KEY (tenant_id, customer_id) REFERENCES mdm_customer (tenant_id, id);
ALTER TABLE mdm_customer_contact DROP CONSTRAINT fk_mdm_customer_contact_customer,
    ADD CONSTRAINT fk_mdm_customer_contact_customer FOREIGN KEY (tenant_id, customer_id) REFERENCES mdm_customer (tenant_id, id);
ALTER TABLE mdm_data_quality_issue DROP CONSTRAINT fk_mdm_dq_issue_rule,
    ADD CONSTRAINT fk_mdm_dq_issue_rule FOREIGN KEY (tenant_id, rule_id) REFERENCES mdm_data_quality_rule (tenant_id, id);
ALTER TABLE mdm_material DROP CONSTRAINT fk_mdm_material_category,
    ADD CONSTRAINT fk_mdm_material_category FOREIGN KEY (tenant_id, category_id) REFERENCES mdm_material_category (tenant_id, id);
ALTER TABLE mdm_material_barcode DROP CONSTRAINT fk_mdm_barcode_material,
    ADD CONSTRAINT fk_mdm_barcode_material FOREIGN KEY (tenant_id, material_id) REFERENCES mdm_material (tenant_id, id);
ALTER TABLE mdm_material_category DROP CONSTRAINT fk_mdm_material_category_parent,
    ADD CONSTRAINT fk_mdm_material_category_parent FOREIGN KEY (tenant_id, parent_id) REFERENCES mdm_material_category (tenant_id, id);
ALTER TABLE mdm_material_factory DROP CONSTRAINT fk_mdm_material_factory_material,
    ADD CONSTRAINT fk_mdm_material_factory_material FOREIGN KEY (tenant_id, material_id) REFERENCES mdm_material (tenant_id, id);
ALTER TABLE mdm_material_substitute DROP CONSTRAINT fk_mdm_substitute_material,
    ADD CONSTRAINT fk_mdm_substitute_material FOREIGN KEY (tenant_id, material_id) REFERENCES mdm_material (tenant_id, id);
ALTER TABLE mdm_material_substitute DROP CONSTRAINT fk_mdm_substitute_target,
    ADD CONSTRAINT fk_mdm_substitute_target FOREIGN KEY (tenant_id, substitute_material_id) REFERENCES mdm_material (tenant_id, id);
ALTER TABLE mdm_partner_bank_account DROP CONSTRAINT fk_mdm_bank_account_bank,
    ADD CONSTRAINT fk_mdm_bank_account_bank FOREIGN KEY (tenant_id, bank_id) REFERENCES mdm_bank (tenant_id, id);
ALTER TABLE mdm_payment_term_line DROP CONSTRAINT fk_mdm_payment_term_line_term,
    ADD CONSTRAINT fk_mdm_payment_term_line_term FOREIGN KEY (tenant_id, payment_term_id) REFERENCES mdm_payment_term (tenant_id, id);
ALTER TABLE mdm_price_list_line DROP CONSTRAINT fk_mdm_price_line_list,
    ADD CONSTRAINT fk_mdm_price_line_list FOREIGN KEY (tenant_id, price_list_id) REFERENCES mdm_price_list (tenant_id, id);
ALTER TABLE mdm_purchase_price DROP CONSTRAINT fk_mdm_purchase_price_material,
    ADD CONSTRAINT fk_mdm_purchase_price_material FOREIGN KEY (tenant_id, material_id) REFERENCES mdm_material (tenant_id, id);
ALTER TABLE mdm_purchase_price DROP CONSTRAINT fk_mdm_purchase_price_supplier,
    ADD CONSTRAINT fk_mdm_purchase_price_supplier FOREIGN KEY (tenant_id, supplier_id) REFERENCES mdm_supplier (tenant_id, id);
ALTER TABLE mdm_supplier_address DROP CONSTRAINT fk_mdm_supplier_address_supplier,
    ADD CONSTRAINT fk_mdm_supplier_address_supplier FOREIGN KEY (tenant_id, supplier_id) REFERENCES mdm_supplier (tenant_id, id);
ALTER TABLE mdm_supplier_admission DROP CONSTRAINT fk_mdm_admission_supplier,
    ADD CONSTRAINT fk_mdm_admission_supplier FOREIGN KEY (tenant_id, supplier_id) REFERENCES mdm_supplier (tenant_id, id);
ALTER TABLE mdm_supplier_contact DROP CONSTRAINT fk_mdm_supplier_contact_supplier,
    ADD CONSTRAINT fk_mdm_supplier_contact_supplier FOREIGN KEY (tenant_id, supplier_id) REFERENCES mdm_supplier (tenant_id, id);
ALTER TABLE mdm_supplier_eval_item DROP CONSTRAINT fk_mdm_eval_item_evaluation,
    ADD CONSTRAINT fk_mdm_eval_item_evaluation FOREIGN KEY (tenant_id, evaluation_id) REFERENCES mdm_supplier_evaluation (tenant_id, id);
ALTER TABLE mdm_supplier_evaluation DROP CONSTRAINT fk_mdm_evaluation_supplier,
    ADD CONSTRAINT fk_mdm_evaluation_supplier FOREIGN KEY (tenant_id, supplier_id) REFERENCES mdm_supplier (tenant_id, id);
ALTER TABLE mdm_supplier_material DROP CONSTRAINT fk_mdm_supplier_material_supplier,
    ADD CONSTRAINT fk_mdm_supplier_material_supplier FOREIGN KEY (tenant_id, supplier_id) REFERENCES mdm_supplier (tenant_id, id);
ALTER TABLE mdm_supplier_qualification DROP CONSTRAINT fk_mdm_supplier_qualification_supplier,
    ADD CONSTRAINT fk_mdm_supplier_qualification_supplier FOREIGN KEY (tenant_id, supplier_id) REFERENCES mdm_supplier (tenant_id, id);
ALTER TABLE mdm_supplier_quotation DROP CONSTRAINT fk_mdm_quotation_supplier,
    ADD CONSTRAINT fk_mdm_quotation_supplier FOREIGN KEY (tenant_id, supplier_id) REFERENCES mdm_supplier (tenant_id, id);
ALTER TABLE mdm_supplier_quotation_line DROP CONSTRAINT fk_mdm_quotation_line_material,
    ADD CONSTRAINT fk_mdm_quotation_line_material FOREIGN KEY (tenant_id, material_id) REFERENCES mdm_material (tenant_id, id);
ALTER TABLE mdm_supplier_quotation_line DROP CONSTRAINT fk_mdm_quotation_line_quotation,
    ADD CONSTRAINT fk_mdm_quotation_line_quotation FOREIGN KEY (tenant_id, quotation_id) REFERENCES mdm_supplier_quotation (tenant_id, id);
ALTER TABLE mdm_tax_rate DROP CONSTRAINT fk_mdm_tax_rate_code,
    ADD CONSTRAINT fk_mdm_tax_rate_code FOREIGN KEY (tenant_id, tax_code_id) REFERENCES mdm_tax_code (tenant_id, id);
ALTER TABLE mdm_warehouse DROP CONSTRAINT fk_mdm_warehouse_factory,
    ADD CONSTRAINT fk_mdm_warehouse_factory FOREIGN KEY (tenant_id, factory_id) REFERENCES mdm_factory (tenant_id, id);
ALTER TABLE mdm_warehouse_bin DROP CONSTRAINT fk_mdm_warehouse_bin_warehouse,
    ADD CONSTRAINT fk_mdm_warehouse_bin_warehouse FOREIGN KEY (tenant_id, warehouse_id) REFERENCES mdm_warehouse (tenant_id, id);
ALTER TABLE mdm_warehouse_bin DROP CONSTRAINT fk_mdm_warehouse_bin_zone,
    ADD CONSTRAINT fk_mdm_warehouse_bin_zone FOREIGN KEY (tenant_id, zone_id) REFERENCES mdm_warehouse_zone (tenant_id, id);
ALTER TABLE mdm_warehouse_zone DROP CONSTRAINT fk_mdm_warehouse_zone_warehouse,
    ADD CONSTRAINT fk_mdm_warehouse_zone_warehouse FOREIGN KEY (tenant_id, warehouse_id) REFERENCES mdm_warehouse (tenant_id, id);
ALTER TABLE prd_bom DROP CONSTRAINT fk_prd_bom_factory,
    ADD CONSTRAINT fk_prd_bom_factory FOREIGN KEY (tenant_id, factory_id) REFERENCES mdm_factory (tenant_id, id);
ALTER TABLE prd_bom DROP CONSTRAINT fk_prd_bom_material,
    ADD CONSTRAINT fk_prd_bom_material FOREIGN KEY (tenant_id, material_id) REFERENCES mdm_material (tenant_id, id);
ALTER TABLE prd_bom_line DROP CONSTRAINT fk_prd_bom_line_component,
    ADD CONSTRAINT fk_prd_bom_line_component FOREIGN KEY (tenant_id, component_material_id) REFERENCES mdm_material (tenant_id, id);
ALTER TABLE prd_bom_substitute DROP CONSTRAINT fk_prd_bom_substitute_material,
    ADD CONSTRAINT fk_prd_bom_substitute_material FOREIGN KEY (tenant_id, substitute_material_id) REFERENCES mdm_material (tenant_id, id);
ALTER TABLE prd_completion_receipt DROP CONSTRAINT fk_prd_completion_receipt_wh,
    ADD CONSTRAINT fk_prd_completion_receipt_wh FOREIGN KEY (tenant_id, warehouse_id) REFERENCES mdm_warehouse (tenant_id, id);
ALTER TABLE prd_completion_receipt_line DROP CONSTRAINT fk_prd_completion_receipt_line_material,
    ADD CONSTRAINT fk_prd_completion_receipt_line_material FOREIGN KEY (tenant_id, material_id) REFERENCES mdm_material (tenant_id, id);
ALTER TABLE prd_demand_forecast DROP CONSTRAINT fk_prd_demand_forecast_material,
    ADD CONSTRAINT fk_prd_demand_forecast_material FOREIGN KEY (tenant_id, material_id) REFERENCES mdm_material (tenant_id, id);
ALTER TABLE prd_inspection DROP CONSTRAINT fk_prd_inspection_material,
    ADD CONSTRAINT fk_prd_inspection_material FOREIGN KEY (tenant_id, material_id) REFERENCES mdm_material (tenant_id, id);
ALTER TABLE prd_material_issue DROP CONSTRAINT fk_prd_material_issue_wh,
    ADD CONSTRAINT fk_prd_material_issue_wh FOREIGN KEY (tenant_id, warehouse_id) REFERENCES mdm_warehouse (tenant_id, id);
ALTER TABLE prd_material_planning DROP CONSTRAINT fk_prd_material_planning_factory,
    ADD CONSTRAINT fk_prd_material_planning_factory FOREIGN KEY (tenant_id, factory_id) REFERENCES mdm_factory (tenant_id, id);
ALTER TABLE prd_material_planning DROP CONSTRAINT fk_prd_material_planning_material,
    ADD CONSTRAINT fk_prd_material_planning_material FOREIGN KEY (tenant_id, material_id) REFERENCES mdm_material (tenant_id, id);
ALTER TABLE prd_mps DROP CONSTRAINT fk_prd_mps_factory,
    ADD CONSTRAINT fk_prd_mps_factory FOREIGN KEY (tenant_id, factory_id) REFERENCES mdm_factory (tenant_id, id);
ALTER TABLE prd_mps_line DROP CONSTRAINT fk_prd_mps_line_material,
    ADD CONSTRAINT fk_prd_mps_line_material FOREIGN KEY (tenant_id, material_id) REFERENCES mdm_material (tenant_id, id);
ALTER TABLE prd_mrp_run DROP CONSTRAINT fk_prd_mrp_run_factory,
    ADD CONSTRAINT fk_prd_mrp_run_factory FOREIGN KEY (tenant_id, factory_id) REFERENCES mdm_factory (tenant_id, id);
ALTER TABLE prd_outsourcing_issue DROP CONSTRAINT fk_prd_outsourcing_issue_wh,
    ADD CONSTRAINT fk_prd_outsourcing_issue_wh FOREIGN KEY (tenant_id, warehouse_id) REFERENCES mdm_warehouse (tenant_id, id);
ALTER TABLE prd_outsourcing_issue_line DROP CONSTRAINT fk_prd_outsourcing_issue_line_material,
    ADD CONSTRAINT fk_prd_outsourcing_issue_line_material FOREIGN KEY (tenant_id, material_id) REFERENCES mdm_material (tenant_id, id);
ALTER TABLE prd_outsourcing_order DROP CONSTRAINT fk_prd_outsourcing_order_factory,
    ADD CONSTRAINT fk_prd_outsourcing_order_factory FOREIGN KEY (tenant_id, factory_id) REFERENCES mdm_factory (tenant_id, id);
ALTER TABLE prd_outsourcing_order DROP CONSTRAINT fk_prd_outsourcing_order_supplier,
    ADD CONSTRAINT fk_prd_outsourcing_order_supplier FOREIGN KEY (tenant_id, supplier_id) REFERENCES mdm_supplier (tenant_id, id);
ALTER TABLE prd_outsourcing_order_line DROP CONSTRAINT fk_prd_outsourcing_order_line_material,
    ADD CONSTRAINT fk_prd_outsourcing_order_line_material FOREIGN KEY (tenant_id, material_id) REFERENCES mdm_material (tenant_id, id);
ALTER TABLE prd_outsourcing_receipt DROP CONSTRAINT fk_prd_outsourcing_receipt_wh,
    ADD CONSTRAINT fk_prd_outsourcing_receipt_wh FOREIGN KEY (tenant_id, warehouse_id) REFERENCES mdm_warehouse (tenant_id, id);
ALTER TABLE prd_outsourcing_receipt_line DROP CONSTRAINT fk_prd_outsourcing_receipt_line_material,
    ADD CONSTRAINT fk_prd_outsourcing_receipt_line_material FOREIGN KEY (tenant_id, material_id) REFERENCES mdm_material (tenant_id, id);
ALTER TABLE prd_outsourcing_settlement DROP CONSTRAINT fk_prd_outsourcing_settlement_supplier,
    ADD CONSTRAINT fk_prd_outsourcing_settlement_supplier FOREIGN KEY (tenant_id, supplier_id) REFERENCES mdm_supplier (tenant_id, id);
ALTER TABLE prd_outsourcing_settlement_line DROP CONSTRAINT fk_prd_outsourcing_settlement_line_material,
    ADD CONSTRAINT fk_prd_outsourcing_settlement_line_material FOREIGN KEY (tenant_id, material_id) REFERENCES mdm_material (tenant_id, id);
ALTER TABLE prd_routing DROP CONSTRAINT fk_prd_routing_factory,
    ADD CONSTRAINT fk_prd_routing_factory FOREIGN KEY (tenant_id, factory_id) REFERENCES mdm_factory (tenant_id, id);
ALTER TABLE prd_routing DROP CONSTRAINT fk_prd_routing_material,
    ADD CONSTRAINT fk_prd_routing_material FOREIGN KEY (tenant_id, material_id) REFERENCES mdm_material (tenant_id, id);
ALTER TABLE prd_work_center DROP CONSTRAINT fk_prd_work_center_factory,
    ADD CONSTRAINT fk_prd_work_center_factory FOREIGN KEY (tenant_id, factory_id) REFERENCES mdm_factory (tenant_id, id);
ALTER TABLE prd_work_order DROP CONSTRAINT fk_prd_work_order_factory,
    ADD CONSTRAINT fk_prd_work_order_factory FOREIGN KEY (tenant_id, factory_id) REFERENCES mdm_factory (tenant_id, id);
ALTER TABLE prd_work_order DROP CONSTRAINT fk_prd_work_order_material,
    ADD CONSTRAINT fk_prd_work_order_material FOREIGN KEY (tenant_id, material_id) REFERENCES mdm_material (tenant_id, id);
ALTER TABLE prd_work_order_material DROP CONSTRAINT fk_prd_work_order_material_material,
    ADD CONSTRAINT fk_prd_work_order_material_material FOREIGN KEY (tenant_id, material_id) REFERENCES mdm_material (tenant_id, id);
ALTER TABLE sal_credit_check_log DROP CONSTRAINT fk_sal_credit_log_customer,
    ADD CONSTRAINT fk_sal_credit_log_customer FOREIGN KEY (tenant_id, customer_id) REFERENCES mdm_customer (tenant_id, id);
ALTER TABLE sal_credit_ledger_snapshot DROP CONSTRAINT fk_sal_credit_occ_customer,
    ADD CONSTRAINT fk_sal_credit_occ_customer FOREIGN KEY (tenant_id, customer_id) REFERENCES mdm_customer (tenant_id, id);
ALTER TABLE sal_delivery_note DROP CONSTRAINT fk_sal_delivery_note_wh,
    ADD CONSTRAINT fk_sal_delivery_note_wh FOREIGN KEY (tenant_id, warehouse_id) REFERENCES mdm_warehouse (tenant_id, id);
ALTER TABLE sal_inquiry DROP CONSTRAINT fk_sal_inquiry_customer,
    ADD CONSTRAINT fk_sal_inquiry_customer FOREIGN KEY (tenant_id, customer_id) REFERENCES mdm_customer (tenant_id, id);
ALTER TABLE sal_inquiry_line DROP CONSTRAINT fk_sal_inquiry_line_material,
    ADD CONSTRAINT fk_sal_inquiry_line_material FOREIGN KEY (tenant_id, material_id) REFERENCES mdm_material (tenant_id, id);
ALTER TABLE sal_invoice DROP CONSTRAINT fk_sal_invoice_customer,
    ADD CONSTRAINT fk_sal_invoice_customer FOREIGN KEY (tenant_id, customer_id) REFERENCES mdm_customer (tenant_id, id);
ALTER TABLE sal_invoice_application DROP CONSTRAINT fk_sal_iva_customer,
    ADD CONSTRAINT fk_sal_iva_customer FOREIGN KEY (tenant_id, customer_id) REFERENCES mdm_customer (tenant_id, id);
ALTER TABLE sal_quotation DROP CONSTRAINT fk_sal_quotation_customer,
    ADD CONSTRAINT fk_sal_quotation_customer FOREIGN KEY (tenant_id, customer_id) REFERENCES mdm_customer (tenant_id, id);
ALTER TABLE sal_sales_forecast DROP CONSTRAINT fk_sal_forecast_dept,
    ADD CONSTRAINT fk_sal_forecast_dept FOREIGN KEY (tenant_id, department_id) REFERENCES sys_department (tenant_id, id);
ALTER TABLE sal_sales_order DROP CONSTRAINT fk_sal_sales_order_customer,
    ADD CONSTRAINT fk_sal_sales_order_customer FOREIGN KEY (tenant_id, customer_id) REFERENCES mdm_customer (tenant_id, id);
ALTER TABLE sal_sales_order_line DROP CONSTRAINT fk_sal_sales_order_line_m,
    ADD CONSTRAINT fk_sal_sales_order_line_m FOREIGN KEY (tenant_id, material_id) REFERENCES mdm_material (tenant_id, id);
ALTER TABLE sal_special_price DROP CONSTRAINT fk_sal_special_price_cust,
    ADD CONSTRAINT fk_sal_special_price_cust FOREIGN KEY (tenant_id, customer_id) REFERENCES mdm_customer (tenant_id, id);
ALTER TABLE sal_special_price DROP CONSTRAINT fk_sal_special_price_mat,
    ADD CONSTRAINT fk_sal_special_price_mat FOREIGN KEY (tenant_id, material_id) REFERENCES mdm_material (tenant_id, id);
ALTER TABLE sal_statement DROP CONSTRAINT fk_sal_statement_customer,
    ADD CONSTRAINT fk_sal_statement_customer FOREIGN KEY (tenant_id, customer_id) REFERENCES mdm_customer (tenant_id, id);

-- 3. sal 唯一键补 company_id（原索引无 WHERE 条件）
DROP INDEX uk_sal_credit_occ_source;
CREATE UNIQUE INDEX uk_sal_credit_occ_source ON sal_credit_ledger_snapshot (tenant_id, company_id, source_type, source_id, release_seq);
DROP INDEX uk_sal_receivable_snapshot_fin;
CREATE UNIQUE INDEX uk_sal_receivable_snapshot_fin ON sal_receivable_snapshot (tenant_id, company_id, receivable_id);

-- 4. prd 域普通索引改为 (tenant_id, company_id, …) 打头（原列顺序在后，索引名不变；78 个，原均以 company_id 打头）
DROP INDEX idx_prd_bom_effective;
CREATE INDEX idx_prd_bom_effective ON public.prd_bom USING btree (tenant_id, company_id, effective_status, valid_from, valid_to);
DROP INDEX idx_prd_bom_material_status;
CREATE INDEX idx_prd_bom_material_status ON public.prd_bom USING btree (tenant_id, company_id, material_id, bom_status, valid_from DESC);
DROP INDEX idx_prd_bom_line_component;
CREATE INDEX idx_prd_bom_line_component ON public.prd_bom_line USING btree (tenant_id, company_id, component_material_id);
DROP INDEX idx_prd_bom_line_substitute;
CREATE INDEX idx_prd_bom_line_substitute ON public.prd_bom_line USING btree (tenant_id, company_id, substitute_group) WHERE (substitute_group IS NOT NULL);
DROP INDEX idx_prd_bom_substitute_material;
CREATE INDEX idx_prd_bom_substitute_material ON public.prd_bom_substitute USING btree (tenant_id, company_id, substitute_material_id, valid_from, valid_to);
DROP INDEX idx_prd_capacity_load_date;
CREATE INDEX idx_prd_capacity_load_date ON public.prd_capacity_load USING btree (tenant_id, company_id, load_date, load_type, load_rate DESC);
DROP INDEX idx_prd_completion_receipt_date;
CREATE INDEX idx_prd_completion_receipt_date ON public.prd_completion_receipt USING btree (tenant_id, company_id, receipt_date, receipt_status);
DROP INDEX idx_prd_completion_receipt_doc;
CREATE INDEX idx_prd_completion_receipt_doc ON public.prd_completion_receipt USING btree (tenant_id, company_id, stock_doc_no);
DROP INDEX idx_prd_completion_receipt_wo;
CREATE INDEX idx_prd_completion_receipt_wo ON public.prd_completion_receipt USING btree (tenant_id, company_id, work_order_id, receipt_status);
DROP INDEX idx_prd_completion_receipt_line_material;
CREATE INDEX idx_prd_completion_receipt_line_material ON public.prd_completion_receipt_line USING btree (tenant_id, company_id, material_id, batch_no);
DROP INDEX idx_prd_defect_code_group;
CREATE INDEX idx_prd_defect_code_group ON public.prd_defect_code USING btree (tenant_id, company_id, defect_group, is_active);
DROP INDEX idx_prd_demand_forecast_mat_date;
CREATE INDEX idx_prd_demand_forecast_mat_date ON public.prd_demand_forecast USING btree (tenant_id, company_id, material_id, bucket_date, forecast_status);
DROP INDEX idx_prd_demand_forecast_run;
CREATE INDEX idx_prd_demand_forecast_run ON public.prd_demand_forecast USING btree (tenant_id, company_id, forecast_status, bucket_type);
DROP INDEX idx_prd_equipment_next_maintenance;
CREATE INDEX idx_prd_equipment_next_maintenance ON public.prd_equipment USING btree (tenant_id, company_id, next_maintenance_date) WHERE (equipment_status <> 90);
DROP INDEX idx_prd_equipment_wc;
CREATE INDEX idx_prd_equipment_wc ON public.prd_equipment USING btree (tenant_id, company_id, work_center_id, equipment_status);
DROP INDEX idx_prd_equipment_maintenance_eq_date;
CREATE INDEX idx_prd_equipment_maintenance_eq_date ON public.prd_equipment_maintenance USING btree (tenant_id, company_id, equipment_id, maintenance_date DESC);
DROP INDEX idx_prd_inspection_lot;
CREATE INDEX idx_prd_inspection_lot ON public.prd_inspection USING btree (tenant_id, company_id, material_id, lot_no);
DROP INDEX idx_prd_inspection_source;
CREATE INDEX idx_prd_inspection_source ON public.prd_inspection USING btree (tenant_id, company_id, source_type, source_id);
DROP INDEX idx_prd_inspection_status;
CREATE INDEX idx_prd_inspection_status ON public.prd_inspection USING btree (tenant_id, company_id, inspection_type, inspection_status, judged_at);
DROP INDEX idx_prd_inspection_wo;
CREATE INDEX idx_prd_inspection_wo ON public.prd_inspection USING btree (tenant_id, company_id, work_order_id) WHERE (work_order_id IS NOT NULL);
DROP INDEX idx_prd_inspection_line_item;
CREATE INDEX idx_prd_inspection_line_item ON public.prd_inspection_line USING btree (tenant_id, company_id, inspection_item_code, judge);
DROP INDEX idx_prd_inspection_standard_apply;
CREATE INDEX idx_prd_inspection_standard_apply ON public.prd_inspection_standard USING btree (tenant_id, company_id, inspection_type, material_id, operation_seq, customer_id, standard_status);
DROP INDEX idx_prd_inspection_standard_valid;
CREATE INDEX idx_prd_inspection_standard_valid ON public.prd_inspection_standard USING btree (tenant_id, company_id, inspection_type, valid_from, valid_to);
DROP INDEX idx_prd_inspection_standard_item_code;
CREATE INDEX idx_prd_inspection_standard_item_code ON public.prd_inspection_standard_item USING btree (tenant_id, company_id, inspection_item_code);
DROP INDEX idx_prd_material_issue_date;
CREATE INDEX idx_prd_material_issue_date ON public.prd_material_issue USING btree (tenant_id, company_id, issue_date, issue_status);
DROP INDEX idx_prd_material_issue_doc;
CREATE INDEX idx_prd_material_issue_doc ON public.prd_material_issue USING btree (tenant_id, company_id, stock_doc_no);
DROP INDEX idx_prd_material_issue_wo;
CREATE INDEX idx_prd_material_issue_wo ON public.prd_material_issue USING btree (tenant_id, company_id, work_order_id, issue_type, issue_status);
DROP INDEX idx_prd_material_issue_line_material;
CREATE INDEX idx_prd_material_issue_line_material ON public.prd_material_issue_line USING btree (tenant_id, company_id, material_id, batch_no);
DROP INDEX idx_prd_material_issue_line_wom;
CREATE INDEX idx_prd_material_issue_line_wom ON public.prd_material_issue_line USING btree (tenant_id, company_id, work_order_material_id);
DROP INDEX idx_prd_material_planning_llc;
CREATE INDEX idx_prd_material_planning_llc ON public.prd_material_planning USING btree (tenant_id, company_id, low_level_code, material_type);
DROP INDEX idx_prd_material_planning_planner;
CREATE INDEX idx_prd_material_planning_planner ON public.prd_material_planning USING btree (tenant_id, company_id, mrp_planner_user_id);
DROP INDEX idx_prd_mps_line_material_date;
CREATE INDEX idx_prd_mps_line_material_date ON public.prd_mps_line USING btree (tenant_id, company_id, material_id, plan_date);
DROP INDEX idx_prd_mrp_action_material;
CREATE INDEX idx_prd_mrp_action_material ON public.prd_mrp_action USING btree (tenant_id, company_id, material_id, action_status);
DROP INDEX idx_prd_mrp_action_ref;
CREATE INDEX idx_prd_mrp_action_ref ON public.prd_mrp_action USING btree (tenant_id, company_id, ref_doc_type, ref_doc_id);
DROP INDEX idx_prd_mrp_action_run_type;
CREATE INDEX idx_prd_mrp_action_run_type ON public.prd_mrp_action USING btree (tenant_id, company_id, mrp_run_id, action_type, action_status);
DROP INDEX idx_prd_mrp_demand_run_mat;
CREATE INDEX idx_prd_mrp_demand_run_mat ON public.prd_mrp_demand USING btree (tenant_id, company_id, mrp_run_id, material_id, bucket_date);
DROP INDEX idx_prd_mrp_demand_run_shortage;
CREATE INDEX idx_prd_mrp_demand_run_shortage ON public.prd_mrp_demand USING btree (tenant_id, company_id, mrp_run_id, shortage_flag) WHERE (shortage_flag = true);
DROP INDEX idx_prd_mrp_demand_run_type;
CREATE INDEX idx_prd_mrp_demand_run_type ON public.prd_mrp_demand USING btree (tenant_id, company_id, mrp_run_id, demand_type);
DROP INDEX idx_prd_mrp_plan_order_converted;
CREATE INDEX idx_prd_mrp_plan_order_converted ON public.prd_mrp_plan_order USING btree (tenant_id, company_id, converted_doc_type, converted_doc_id);
DROP INDEX idx_prd_mrp_plan_order_run_mat;
CREATE INDEX idx_prd_mrp_plan_order_run_mat ON public.prd_mrp_plan_order USING btree (tenant_id, company_id, mrp_run_id, material_id, due_date);
DROP INDEX idx_prd_mrp_plan_order_status;
CREATE INDEX idx_prd_mrp_plan_order_status ON public.prd_mrp_plan_order USING btree (tenant_id, company_id, plan_status, start_date);
DROP INDEX idx_prd_mrp_run_date;
CREATE INDEX idx_prd_mrp_run_date ON public.prd_mrp_run USING btree (tenant_id, company_id, factory_id, run_date DESC, run_status);
DROP INDEX idx_prd_ncr_material;
CREATE INDEX idx_prd_ncr_material ON public.prd_ncr USING btree (tenant_id, company_id, material_id, lot_no);
DROP INDEX idx_prd_ncr_status;
CREATE INDEX idx_prd_ncr_status ON public.prd_ncr USING btree (tenant_id, company_id, ncr_status, ncr_date);
DROP INDEX idx_prd_ncr_wo;
CREATE INDEX idx_prd_ncr_wo ON public.prd_ncr USING btree (tenant_id, company_id, work_order_id) WHERE (work_order_id IS NOT NULL);
DROP INDEX idx_prd_ncr_action_status;
CREATE INDEX idx_prd_ncr_action_status ON public.prd_ncr_action USING btree (tenant_id, company_id, action_status, planned_date);
DROP INDEX idx_prd_outsourcing_issue_doc;
CREATE INDEX idx_prd_outsourcing_issue_doc ON public.prd_outsourcing_issue USING btree (tenant_id, company_id, stock_doc_no);
DROP INDEX idx_prd_outsourcing_issue_order;
CREATE INDEX idx_prd_outsourcing_issue_order ON public.prd_outsourcing_issue USING btree (tenant_id, company_id, outsourcing_order_id, issue_status);
DROP INDEX idx_prd_outsourcing_issue_line_material;
CREATE INDEX idx_prd_outsourcing_issue_line_material ON public.prd_outsourcing_issue_line USING btree (tenant_id, company_id, material_id, batch_no);
DROP INDEX idx_prd_outsourcing_order_status;
CREATE INDEX idx_prd_outsourcing_order_status ON public.prd_outsourcing_order USING btree (tenant_id, company_id, os_status, planned_delivery_date);
DROP INDEX idx_prd_outsourcing_order_supplier;
CREATE INDEX idx_prd_outsourcing_order_supplier ON public.prd_outsourcing_order USING btree (tenant_id, company_id, supplier_id, os_status, planned_delivery_date);
DROP INDEX idx_prd_outsourcing_order_line_material;
CREATE INDEX idx_prd_outsourcing_order_line_material ON public.prd_outsourcing_order_line USING btree (tenant_id, company_id, material_id);
DROP INDEX idx_prd_outsourcing_receipt_doc;
CREATE INDEX idx_prd_outsourcing_receipt_doc ON public.prd_outsourcing_receipt USING btree (tenant_id, company_id, stock_doc_no);
DROP INDEX idx_prd_outsourcing_receipt_order;
CREATE INDEX idx_prd_outsourcing_receipt_order ON public.prd_outsourcing_receipt USING btree (tenant_id, company_id, outsourcing_order_id, receipt_status);
DROP INDEX idx_prd_outsourcing_receipt_line_material;
CREATE INDEX idx_prd_outsourcing_receipt_line_material ON public.prd_outsourcing_receipt_line USING btree (tenant_id, company_id, material_id, batch_no);
DROP INDEX idx_prd_outsourcing_settlement_supplier;
CREATE INDEX idx_prd_outsourcing_settlement_supplier ON public.prd_outsourcing_settlement USING btree (tenant_id, company_id, supplier_id, period_code, settlement_status);
DROP INDEX idx_prd_outsourcing_settlement_line_rcpt;
CREATE INDEX idx_prd_outsourcing_settlement_line_rcpt ON public.prd_outsourcing_settlement_line USING btree (tenant_id, company_id, outsourcing_receipt_id);
DROP INDEX idx_prd_routing_material_status;
CREATE INDEX idx_prd_routing_material_status ON public.prd_routing USING btree (tenant_id, company_id, material_id, routing_status, valid_from DESC);
DROP INDEX idx_prd_routing_operation_inspection;
CREATE INDEX idx_prd_routing_operation_inspection ON public.prd_routing_operation USING btree (tenant_id, company_id, is_inspection_point) WHERE (is_inspection_point = true);
DROP INDEX idx_prd_routing_operation_wc;
CREATE INDEX idx_prd_routing_operation_wc ON public.prd_routing_operation USING btree (tenant_id, company_id, work_center_id);
DROP INDEX idx_prd_wo_lot_consumed;
CREATE INDEX idx_prd_wo_lot_consumed ON public.prd_wo_lot USING btree (tenant_id, company_id, consumed_at);
DROP INDEX idx_prd_wo_lot_input;
CREATE INDEX idx_prd_wo_lot_input ON public.prd_wo_lot USING btree (tenant_id, company_id, input_material_id, input_lot_no);
DROP INDEX idx_prd_wo_lot_product;
CREATE INDEX idx_prd_wo_lot_product ON public.prd_wo_lot USING btree (tenant_id, company_id, product_lot_no, trace_type);
DROP INDEX idx_prd_wo_lot_wo;
CREATE INDEX idx_prd_wo_lot_wo ON public.prd_wo_lot USING btree (tenant_id, company_id, work_order_id, operation_seq);
DROP INDEX idx_prd_work_center_factory;
CREATE INDEX idx_prd_work_center_factory ON public.prd_work_center USING btree (tenant_id, company_id, factory_id, status);
DROP INDEX idx_prd_work_center_calendar_date;
CREATE INDEX idx_prd_work_center_calendar_date ON public.prd_work_center_calendar USING btree (tenant_id, company_id, calendar_date, day_type);
DROP INDEX idx_prd_work_order_change_date;
CREATE INDEX idx_prd_work_order_change_date ON public.prd_work_order_change USING btree (tenant_id, company_id, created_at DESC);
DROP INDEX idx_prd_work_order_material_material;
CREATE INDEX idx_prd_work_order_material_material ON public.prd_work_order_material USING btree (tenant_id, company_id, material_id, issue_status);
DROP INDEX idx_prd_work_order_material_unissued;
CREATE INDEX idx_prd_work_order_material_unissued ON public.prd_work_order_material USING btree (tenant_id, company_id, work_order_id, remaining_qty) WHERE (remaining_qty > (0)::numeric);
DROP INDEX idx_prd_work_order_operation_inspection;
CREATE INDEX idx_prd_work_order_operation_inspection ON public.prd_work_order_operation USING btree (tenant_id, company_id, inspection_status) WHERE (inspection_status = ANY (ARRAY[10, 30]));
DROP INDEX idx_prd_work_order_operation_wc_date;
CREATE INDEX idx_prd_work_order_operation_wc_date ON public.prd_work_order_operation USING btree (tenant_id, company_id, work_center_id, planned_start_date, operation_status);
DROP INDEX idx_prd_work_order_relation_src;
CREATE INDEX idx_prd_work_order_relation_src ON public.prd_work_order_relation USING btree (tenant_id, company_id, source_work_order_id);
DROP INDEX idx_prd_work_order_relation_tgt;
CREATE INDEX idx_prd_work_order_relation_tgt ON public.prd_work_order_relation USING btree (tenant_id, company_id, target_work_order_id);
DROP INDEX idx_prd_work_report_date;
CREATE INDEX idx_prd_work_report_date ON public.prd_work_report USING btree (tenant_id, company_id, report_date, report_status);
DROP INDEX idx_prd_work_report_op;
CREATE INDEX idx_prd_work_report_op ON public.prd_work_report USING btree (tenant_id, company_id, work_order_operation_id);
DROP INDEX idx_prd_work_report_wo;
CREATE INDEX idx_prd_work_report_wo ON public.prd_work_report USING btree (tenant_id, company_id, work_order_id, operation_seq, report_status);
DROP INDEX idx_prd_work_report_defect_code;
CREATE INDEX idx_prd_work_report_defect_code ON public.prd_work_report_defect USING btree (tenant_id, company_id, defect_code_id, created_at DESC);
DROP INDEX idx_prd_work_report_labor_employee;
CREATE INDEX idx_prd_work_report_labor_employee ON public.prd_work_report_labor USING btree (tenant_id, company_id, employee_id, start_at DESC);

-- 5. sys/mdm/sal/fin 普通 btree 索引改为 tenant_id 打头（147 个；有 company_id 的表为 (tenant_id, company_id, 原列…)，无 company_id 的表为 (tenant_id, 原列…)；索引名、WHERE 不变）
-- GIN 索引（8 个）未改：GIN 加 bigint 列需 btree_gin 扩展，待定。
DROP INDEX idx_fin_standard_cost_lookup;
CREATE INDEX idx_fin_standard_cost_lookup ON public.fin_standard_cost USING btree (tenant_id, company_id, material_id, status, period_from DESC);
DROP INDEX idx_mdm_bank_name;
CREATE INDEX idx_mdm_bank_name ON public.mdm_bank USING btree (tenant_id, company_id, bank_name);
DROP INDEX idx_mdm_change_request_object;
CREATE INDEX idx_mdm_change_request_object ON public.mdm_change_request USING btree (tenant_id, company_id, object_type, object_id, status);
DROP INDEX idx_mdm_change_request_status;
CREATE INDEX idx_mdm_change_request_status ON public.mdm_change_request USING btree (tenant_id, company_id, status, submitted_at);
DROP INDEX idx_mdm_credit_limit_customer;
CREATE INDEX idx_mdm_credit_limit_customer ON public.mdm_credit_limit USING btree (tenant_id, company_id, customer_id, valid_from DESC);
DROP INDEX idx_mdm_credit_limit_status;
CREATE INDEX idx_mdm_credit_limit_status ON public.mdm_credit_limit USING btree (tenant_id, company_id, credit_status);
DROP INDEX idx_mdm_credit_limit_his_customer;
CREATE INDEX idx_mdm_credit_limit_his_customer ON public.mdm_credit_limit_his USING btree (tenant_id, company_id, customer_id, created_at DESC);
DROP INDEX idx_mdm_customer_credit;
CREATE INDEX idx_mdm_customer_credit ON public.mdm_customer USING btree (tenant_id, company_id, credit_status);
DROP INDEX idx_mdm_customer_owner;
CREATE INDEX idx_mdm_customer_owner ON public.mdm_customer USING btree (tenant_id, company_id, owner_user_id, status);
DROP INDEX idx_mdm_customer_address_customer;
CREATE INDEX idx_mdm_customer_address_customer ON public.mdm_customer_address USING btree (tenant_id, company_id, customer_id, deleted);
DROP INDEX idx_mdm_customer_contact_customer;
CREATE INDEX idx_mdm_customer_contact_customer ON public.mdm_customer_contact USING btree (tenant_id, company_id, customer_id, deleted);
DROP INDEX idx_mdm_customer_his_customer;
CREATE INDEX idx_mdm_customer_his_customer ON public.mdm_customer_his USING btree (tenant_id, company_id, customer_id, created_at DESC);
DROP INDEX idx_mdm_dq_issue_object;
CREATE INDEX idx_mdm_dq_issue_object ON public.mdm_data_quality_issue USING btree (tenant_id, company_id, object_type, object_id, status);
DROP INDEX idx_mdm_dq_issue_status;
CREATE INDEX idx_mdm_dq_issue_status ON public.mdm_data_quality_issue USING btree (tenant_id, company_id, status, severity, detected_at DESC);
DROP INDEX idx_mdm_exchange_rate_pair_date;
CREATE INDEX idx_mdm_exchange_rate_pair_date ON public.mdm_exchange_rate USING btree (tenant_id, company_id, from_currency_code, to_currency_code, rate_type, effective_date DESC);
DROP INDEX idx_mdm_material_batch;
CREATE INDEX idx_mdm_material_batch ON public.mdm_material USING btree (tenant_id, company_id, is_batch_managed, status);
DROP INDEX idx_mdm_material_category;
CREATE INDEX idx_mdm_material_category ON public.mdm_material USING btree (tenant_id, company_id, category_id);
DROP INDEX idx_mdm_material_type_status;
CREATE INDEX idx_mdm_material_type_status ON public.mdm_material USING btree (tenant_id, company_id, material_type, status);
DROP INDEX idx_mdm_material_barcode_material;
CREATE INDEX idx_mdm_material_barcode_material ON public.mdm_material_barcode USING btree (tenant_id, company_id, material_id, is_active);
DROP INDEX idx_mdm_material_category_parent;
CREATE INDEX idx_mdm_material_category_parent ON public.mdm_material_category USING btree (tenant_id, company_id, parent_id);
DROP INDEX idx_mdm_material_factory_factory;
CREATE INDEX idx_mdm_material_factory_factory ON public.mdm_material_factory USING btree (tenant_id, company_id, factory_id);
DROP INDEX idx_mdm_material_his_material;
CREATE INDEX idx_mdm_material_his_material ON public.mdm_material_his USING btree (tenant_id, company_id, material_id, created_at DESC);
DROP INDEX idx_mdm_material_his_request;
CREATE INDEX idx_mdm_material_his_request ON public.mdm_material_his USING btree (tenant_id, company_id, change_request_id);
DROP INDEX idx_mdm_substitute_target;
CREATE INDEX idx_mdm_substitute_target ON public.mdm_material_substitute USING btree (tenant_id, company_id, substitute_material_id, status);
DROP INDEX idx_mdm_bank_account_owner;
CREATE INDEX idx_mdm_bank_account_owner ON public.mdm_partner_bank_account USING btree (tenant_id, company_id, owner_type, owner_id, deleted);
DROP INDEX idx_mdm_bank_account_his_account;
CREATE INDEX idx_mdm_bank_account_his_account ON public.mdm_partner_bank_account_his USING btree (tenant_id, company_id, account_id, created_at DESC);
DROP INDEX idx_mdm_price_list_status_date;
CREATE INDEX idx_mdm_price_list_status_date ON public.mdm_price_list USING btree (tenant_id, company_id, status, valid_from, valid_to);
DROP INDEX idx_mdm_price_line_lookup;
CREATE INDEX idx_mdm_price_line_lookup ON public.mdm_price_list_line USING btree (tenant_id, company_id, scope_type, customer_id, material_id, min_qty, valid_from);
DROP INDEX idx_mdm_price_line_material;
CREATE INDEX idx_mdm_price_line_material ON public.mdm_price_list_line USING btree (tenant_id, company_id, material_id, valid_from DESC);
DROP INDEX idx_mdm_purchase_price_lookup;
CREATE INDEX idx_mdm_purchase_price_lookup ON public.mdm_purchase_price USING btree (tenant_id, company_id, supplier_id, material_id, min_qty, valid_from);
DROP INDEX idx_mdm_purchase_price_material;
CREATE INDEX idx_mdm_purchase_price_material ON public.mdm_purchase_price USING btree (tenant_id, company_id, material_id, status);
DROP INDEX idx_mdm_supplier_admission;
CREATE INDEX idx_mdm_supplier_admission ON public.mdm_supplier USING btree (tenant_id, company_id, admission_status, supplier_grade);
DROP INDEX idx_mdm_supplier_buyer;
CREATE INDEX idx_mdm_supplier_buyer ON public.mdm_supplier USING btree (tenant_id, company_id, buyer_id);
DROP INDEX idx_mdm_supplier_address_supplier;
CREATE INDEX idx_mdm_supplier_address_supplier ON public.mdm_supplier_address USING btree (tenant_id, company_id, supplier_id, deleted);
DROP INDEX idx_mdm_supplier_contact_supplier;
CREATE INDEX idx_mdm_supplier_contact_supplier ON public.mdm_supplier_contact USING btree (tenant_id, company_id, supplier_id, deleted);
DROP INDEX idx_mdm_evaluation_period;
CREATE INDEX idx_mdm_evaluation_period ON public.mdm_supplier_evaluation USING btree (tenant_id, company_id, evaluation_period, total_score DESC);
DROP INDEX idx_mdm_supplier_his_supplier;
CREATE INDEX idx_mdm_supplier_his_supplier ON public.mdm_supplier_his USING btree (tenant_id, company_id, supplier_id, created_at DESC);
DROP INDEX idx_mdm_supplier_material_material;
CREATE INDEX idx_mdm_supplier_material_material ON public.mdm_supplier_material USING btree (tenant_id, company_id, material_id, is_active);
DROP INDEX idx_mdm_supplier_material_supplier;
CREATE INDEX idx_mdm_supplier_material_supplier ON public.mdm_supplier_material USING btree (tenant_id, company_id, supplier_id, is_active);
DROP INDEX idx_mdm_supplier_qual_expiry;
CREATE INDEX idx_mdm_supplier_qual_expiry ON public.mdm_supplier_qualification USING btree (tenant_id, company_id, valid_to) WHERE (deleted = false);
DROP INDEX idx_mdm_supplier_qual_supplier;
CREATE INDEX idx_mdm_supplier_qual_supplier ON public.mdm_supplier_qualification USING btree (tenant_id, company_id, supplier_id, valid_to);
DROP INDEX idx_mdm_quotation_supplier;
CREATE INDEX idx_mdm_quotation_supplier ON public.mdm_supplier_quotation USING btree (tenant_id, company_id, supplier_id, quotation_date DESC);
DROP INDEX idx_mdm_tax_code_type;
CREATE INDEX idx_mdm_tax_code_type ON public.mdm_tax_code USING btree (tenant_id, company_id, tax_type, status);
DROP INDEX idx_mdm_tax_rate_code;
CREATE INDEX idx_mdm_tax_rate_code ON public.mdm_tax_rate USING btree (tenant_id, company_id, tax_code_id, effective_from DESC);
DROP INDEX idx_mdm_uom_conversion_group;
CREATE INDEX idx_mdm_uom_conversion_group ON public.mdm_uom_conversion USING btree (tenant_id, company_id, conversion_group, valid_from DESC);
DROP INDEX idx_mdm_warehouse_bin_warehouse;
CREATE INDEX idx_mdm_warehouse_bin_warehouse ON public.mdm_warehouse_bin USING btree (tenant_id, company_id, warehouse_id, zone_id, is_active);
DROP INDEX idx_sal_credit_log_customer;
CREATE INDEX idx_sal_credit_log_customer ON public.sal_credit_check_log USING btree (tenant_id, company_id, customer_id, checked_at DESC);
DROP INDEX idx_sal_credit_log_order;
CREATE INDEX idx_sal_credit_log_order ON public.sal_credit_check_log USING btree (tenant_id, company_id, sales_order_id, check_type);
DROP INDEX idx_sal_credit_occ_customer;
CREATE INDEX idx_sal_credit_occ_customer ON public.sal_credit_ledger_snapshot USING btree (tenant_id, company_id, customer_id, status);
DROP INDEX idx_sal_credit_occ_source_lookup;
CREATE INDEX idx_sal_credit_occ_source_lookup ON public.sal_credit_ledger_snapshot USING btree (tenant_id, company_id, source_type, source_id);
DROP INDEX idx_sal_delivery_note_customer;
CREATE INDEX idx_sal_delivery_note_customer ON public.sal_delivery_note USING btree (tenant_id, company_id, customer_id, delivery_date DESC);
DROP INDEX idx_sal_delivery_note_order;
CREATE INDEX idx_sal_delivery_note_order ON public.sal_delivery_note USING btree (tenant_id, company_id, sales_order_id);
DROP INDEX idx_sal_delivery_note_status_date;
CREATE INDEX idx_sal_delivery_note_status_date ON public.sal_delivery_note USING btree (tenant_id, company_id, delivery_status, delivery_date DESC);
DROP INDEX idx_sal_dn_line_material;
CREATE INDEX idx_sal_dn_line_material ON public.sal_delivery_note_line USING btree (tenant_id, company_id, material_id);
DROP INDEX idx_sal_dn_line_order_line;
CREATE INDEX idx_sal_dn_line_order_line ON public.sal_delivery_note_line USING btree (tenant_id, company_id, sales_order_line_id);
DROP INDEX idx_sal_delivery_serial_no;
CREATE INDEX idx_sal_delivery_serial_no ON public.sal_delivery_serial USING btree (tenant_id, company_id, material_id, serial_no);
DROP INDEX idx_sal_inquiry_customer;
CREATE INDEX idx_sal_inquiry_customer ON public.sal_inquiry USING btree (tenant_id, company_id, customer_id, inquiry_date DESC);
DROP INDEX idx_sal_inquiry_date;
CREATE INDEX idx_sal_inquiry_date ON public.sal_inquiry USING btree (tenant_id, company_id, inquiry_date DESC);
DROP INDEX idx_sal_inquiry_owner_status;
CREATE INDEX idx_sal_inquiry_owner_status ON public.sal_inquiry USING btree (tenant_id, company_id, owner_user_id, inquiry_status);
DROP INDEX idx_sal_inquiry_line_material;
CREATE INDEX idx_sal_inquiry_line_material ON public.sal_inquiry_line USING btree (tenant_id, company_id, material_id);
DROP INDEX idx_sal_invoice_customer;
CREATE INDEX idx_sal_invoice_customer ON public.sal_invoice USING btree (tenant_id, company_id, customer_id, issued_at DESC);
DROP INDEX idx_sal_invoice_issued;
CREATE INDEX idx_sal_invoice_issued ON public.sal_invoice USING btree (tenant_id, company_id, issued_at DESC, invoice_status);
DROP INDEX idx_sal_invoice_original;
CREATE INDEX idx_sal_invoice_original ON public.sal_invoice USING btree (tenant_id, company_id, original_invoice_id);
DROP INDEX idx_sal_iva_customer_period;
CREATE INDEX idx_sal_iva_customer_period ON public.sal_invoice_application USING btree (tenant_id, company_id, customer_id, period_from DESC);
DROP INDEX idx_sal_iva_status;
CREATE INDEX idx_sal_iva_status ON public.sal_invoice_application USING btree (tenant_id, company_id, application_status, period_from DESC);
DROP INDEX idx_sal_iva_line_dn;
CREATE INDEX idx_sal_iva_line_dn ON public.sal_invoice_application_line USING btree (tenant_id, company_id, delivery_id);
DROP INDEX idx_sal_invoice_line_material;
CREATE INDEX idx_sal_invoice_line_material ON public.sal_invoice_line USING btree (tenant_id, company_id, material_id);
DROP INDEX idx_sal_invoice_relation_inv;
CREATE INDEX idx_sal_invoice_relation_inv ON public.sal_invoice_relation USING btree (tenant_id, company_id, invoice_id, relate_type);
DROP INDEX idx_sal_invoice_relation_target;
CREATE INDEX idx_sal_invoice_relation_target ON public.sal_invoice_relation USING btree (tenant_id, company_id, relate_type, relate_id);
DROP INDEX idx_sal_pick_detail_batch;
CREATE INDEX idx_sal_pick_detail_batch ON public.sal_pick_detail USING btree (tenant_id, company_id, material_id, batch_no);
DROP INDEX idx_sal_pick_detail_line;
CREATE INDEX idx_sal_pick_detail_line ON public.sal_pick_detail USING btree (tenant_id, company_id, delivery_note_line_id, pick_seq);
DROP INDEX idx_sal_quotation_customer;
CREATE INDEX idx_sal_quotation_customer ON public.sal_quotation USING btree (tenant_id, company_id, customer_id, issue_date DESC);
DROP INDEX idx_sal_quotation_inquiry;
CREATE INDEX idx_sal_quotation_inquiry ON public.sal_quotation USING btree (tenant_id, company_id, inquiry_id);
DROP INDEX idx_sal_quotation_owner;
CREATE INDEX idx_sal_quotation_owner ON public.sal_quotation USING btree (tenant_id, company_id, owner_user_id, quotation_status);
DROP INDEX idx_sal_quotation_status_valid;
CREATE INDEX idx_sal_quotation_status_valid ON public.sal_quotation USING btree (tenant_id, company_id, quotation_status, valid_to);
DROP INDEX idx_sal_quotation_line_material;
CREATE INDEX idx_sal_quotation_line_material ON public.sal_quotation_line USING btree (tenant_id, company_id, material_id);
DROP INDEX idx_sal_receivable_snapshot_cust;
CREATE INDEX idx_sal_receivable_snapshot_cust ON public.sal_receivable_snapshot USING btree (tenant_id, company_id, customer_id, due_date);
DROP INDEX idx_sal_receivable_snapshot_open;
CREATE INDEX idx_sal_receivable_snapshot_open ON public.sal_receivable_snapshot USING btree (tenant_id, company_id, customer_id, receivable_status);
DROP INDEX idx_sal_return_inspection_line;
CREATE INDEX idx_sal_return_inspection_line ON public.sal_return_inspection USING btree (tenant_id, company_id, return_line_id, inspection_seq DESC);
DROP INDEX idx_sal_forecast_period;
CREATE INDEX idx_sal_forecast_period ON public.sal_sales_forecast USING btree (tenant_id, company_id, period_code, department_id, forecast_status);
DROP INDEX idx_sal_forecast_line_material;
CREATE INDEX idx_sal_forecast_line_material ON public.sal_sales_forecast_line USING btree (tenant_id, company_id, material_id);
DROP INDEX idx_sal_sales_order_customer;
CREATE INDEX idx_sal_sales_order_customer ON public.sal_sales_order USING btree (tenant_id, company_id, customer_id, order_date DESC);
DROP INDEX idx_sal_sales_order_delivery;
CREATE INDEX idx_sal_sales_order_delivery ON public.sal_sales_order USING btree (tenant_id, company_id, delivery_date, order_status);
DROP INDEX idx_sal_sales_order_owner;
CREATE INDEX idx_sal_sales_order_owner ON public.sal_sales_order USING btree (tenant_id, company_id, owner_user_id, order_status);
DROP INDEX idx_sal_sales_order_status_date;
CREATE INDEX idx_sal_sales_order_status_date ON public.sal_sales_order USING btree (tenant_id, company_id, order_status, order_date DESC);
DROP INDEX idx_sal_sales_order_line_material;
CREATE INDEX idx_sal_sales_order_line_material ON public.sal_sales_order_line USING btree (tenant_id, company_id, material_id, delivery_date);
DROP INDEX idx_sal_sales_order_line_open;
CREATE INDEX idx_sal_sales_order_line_open ON public.sal_sales_order_line USING btree (tenant_id, company_id, sales_order_id) WHERE (line_status = ANY (ARRAY[10, 30, 35]));
DROP INDEX idx_sal_sales_order_line_status;
CREATE INDEX idx_sal_sales_order_line_status ON public.sal_sales_order_line USING btree (tenant_id, company_id, line_status, delivery_date);
DROP INDEX idx_sal_so_line_version;
CREATE INDEX idx_sal_so_line_version ON public.sal_sales_order_line_version USING btree (tenant_id, company_id, sales_order_id, version_no, line_no);
DROP INDEX idx_sal_sales_order_version_status;
CREATE INDEX idx_sal_sales_order_version_status ON public.sal_sales_order_version USING btree (tenant_id, company_id, change_status, requested_at DESC);
DROP INDEX idx_sal_sales_return_customer;
CREATE INDEX idx_sal_sales_return_customer ON public.sal_sales_return USING btree (tenant_id, company_id, customer_id, return_date DESC);
DROP INDEX idx_sal_sales_return_deadline;
CREATE INDEX idx_sal_sales_return_deadline ON public.sal_sales_return USING btree (tenant_id, company_id, return_status, return_deadline_date);
DROP INDEX idx_sal_sales_return_delivery;
CREATE INDEX idx_sal_sales_return_delivery ON public.sal_sales_return USING btree (tenant_id, company_id, original_delivery_id);
DROP INDEX idx_sal_return_line_dn_line;
CREATE INDEX idx_sal_return_line_dn_line ON public.sal_sales_return_line USING btree (tenant_id, company_id, original_delivery_line_id);
DROP INDEX idx_sal_special_price_lookup;
CREATE INDEX idx_sal_special_price_lookup ON public.sal_special_price USING btree (tenant_id, company_id, customer_id, material_id, status, valid_to);
DROP INDEX idx_sal_statement_status;
CREATE INDEX idx_sal_statement_status ON public.sal_statement USING btree (tenant_id, company_id, statement_status, period_code DESC);
DROP INDEX idx_sal_statement_line_date;
CREATE INDEX idx_sal_statement_line_date ON public.sal_statement_line USING btree (tenant_id, company_id, statement_id, transaction_date);
DROP INDEX idx_sys_attachment_expire;
CREATE INDEX idx_sys_attachment_expire ON public.sys_attachment USING btree (tenant_id, company_id, expire_at) WHERE (expire_at IS NOT NULL);
DROP INDEX idx_sys_attachment_sha;
CREATE INDEX idx_sys_attachment_sha ON public.sys_attachment USING btree (tenant_id, company_id, sha256);
DROP INDEX idx_sys_attachment_user;
CREATE INDEX idx_sys_attachment_user ON public.sys_attachment USING btree (tenant_id, company_id, upload_user_id, created_at DESC);
DROP INDEX idx_sys_attachment_biz;
CREATE INDEX idx_sys_attachment_biz ON public.sys_attachment_biz USING btree (tenant_id, company_id, biz_type, biz_id, sort_no);
DROP INDEX idx_sys_audit_log_resource;
CREATE INDEX idx_sys_audit_log_resource ON public.sys_audit_log USING btree (tenant_id, company_id, module_code, resource_code, resource_id);
DROP INDEX idx_sys_audit_log_time;
CREATE INDEX idx_sys_audit_log_time ON public.sys_audit_log USING btree (tenant_id, company_id, occurred_at DESC);
DROP INDEX idx_sys_audit_log_type;
CREATE INDEX idx_sys_audit_log_type ON public.sys_audit_log USING btree (tenant_id, company_id, operation_type, result, occurred_at DESC);
DROP INDEX idx_sys_audit_log_user;
CREATE INDEX idx_sys_audit_log_user ON public.sys_audit_log USING btree (tenant_id, company_id, user_id, occurred_at DESC);
DROP INDEX idx_sys_data_maintenance_log_operator;
CREATE INDEX idx_sys_data_maintenance_log_operator ON public.sys_data_maintenance_log USING btree (tenant_id, operator_id, start_at DESC);
DROP INDEX idx_sys_data_maintenance_log_type;
CREATE INDEX idx_sys_data_maintenance_log_type ON public.sys_data_maintenance_log USING btree (tenant_id, maintenance_type, start_at DESC);
DROP INDEX idx_sys_department_parent;
CREATE INDEX idx_sys_department_parent ON public.sys_department USING btree (tenant_id, company_id, parent_id, sort_no);
DROP INDEX idx_sys_department_path;
CREATE INDEX idx_sys_department_path ON public.sys_department USING btree (tenant_id, company_id, department_path);
DROP INDEX idx_sys_dict_item_type;
CREATE INDEX idx_sys_dict_item_type ON public.sys_dict_item USING btree (tenant_id, company_id, dict_type_id, status, sort_no);
DROP INDEX idx_sys_dict_type_module;
CREATE INDEX idx_sys_dict_type_module ON public.sys_dict_type USING btree (tenant_id, company_id, module_code, status);
DROP INDEX idx_sys_event_consume_log_type;
CREATE INDEX idx_sys_event_consume_log_type ON public.sys_event_consume_log USING btree (tenant_id, event_type, consumed_at DESC);
DROP INDEX idx_sys_factory_setting_default;
CREATE INDEX idx_sys_factory_setting_default ON public.sys_factory_setting USING btree (tenant_id, company_id, is_default) WHERE (is_default AND (deleted = false));
DROP INDEX idx_sys_idempotency_expire;
CREATE INDEX idx_sys_idempotency_expire ON public.sys_idempotency USING btree (tenant_id, company_id, expires_at);
DROP INDEX idx_sys_import_export_error_job;
CREATE INDEX idx_sys_import_export_error_job ON public.sys_import_export_error USING btree (tenant_id, job_id, row_no);
DROP INDEX idx_sys_import_export_job_expire;
CREATE INDEX idx_sys_import_export_job_expire ON public.sys_import_export_job USING btree (tenant_id, company_id, expire_at) WHERE (expire_at IS NOT NULL);
DROP INDEX idx_sys_import_export_job_status;
CREATE INDEX idx_sys_import_export_job_status ON public.sys_import_export_job USING btree (tenant_id, company_id, job_status, created_at);
DROP INDEX idx_sys_import_export_job_user;
CREATE INDEX idx_sys_import_export_job_user ON public.sys_import_export_job USING btree (tenant_id, company_id, created_by, created_at DESC);
DROP INDEX idx_sys_import_template_biz;
CREATE INDEX idx_sys_import_template_biz ON public.sys_import_template USING btree (tenant_id, company_id, module_code, biz_type, status);
DROP INDEX idx_sys_login_log_ip;
CREATE INDEX idx_sys_login_log_ip ON public.sys_login_log USING btree (tenant_id, company_id, ip_address, occurred_at DESC);
DROP INDEX idx_sys_login_log_result;
CREATE INDEX idx_sys_login_log_result ON public.sys_login_log USING btree (tenant_id, company_id, login_result, occurred_at DESC);
DROP INDEX idx_sys_login_log_user_time;
CREATE INDEX idx_sys_login_log_user_time ON public.sys_login_log USING btree (tenant_id, company_id, username, occurred_at DESC);
DROP INDEX idx_sys_menu_module;
CREATE INDEX idx_sys_menu_module ON public.sys_menu USING btree (tenant_id, company_id, module_code, menu_type);
DROP INDEX idx_sys_menu_parent;
CREATE INDEX idx_sys_menu_parent ON public.sys_menu USING btree (tenant_id, company_id, parent_id, sort_no);
DROP INDEX idx_sys_notification_expire;
CREATE INDEX idx_sys_notification_expire ON public.sys_notification USING btree (tenant_id, company_id, expire_at) WHERE (expire_at IS NOT NULL);
DROP INDEX idx_sys_notification_scene;
CREATE INDEX idx_sys_notification_scene ON public.sys_notification USING btree (tenant_id, company_id, biz_scene, created_at DESC);
DROP INDEX idx_sys_notification_status;
CREATE INDEX idx_sys_notification_status ON public.sys_notification USING btree (tenant_id, company_id, send_status, created_at);
DROP INDEX idx_sys_notification_receiver_inbox;
CREATE INDEX idx_sys_notification_receiver_inbox ON public.sys_notification_receiver USING btree (tenant_id, company_id, receiver_user_id, status, created_at DESC);
DROP INDEX idx_sys_notification_send_log_retry;
CREATE INDEX idx_sys_notification_send_log_retry ON public.sys_notification_send_log USING btree (tenant_id, send_status, next_retry_at) WHERE (send_status = ANY (ARRAY[0, 3]));
DROP INDEX idx_sys_notification_send_log_user;
CREATE INDEX idx_sys_notification_send_log_user ON public.sys_notification_send_log USING btree (tenant_id, receiver_user_id, created_at DESC);
DROP INDEX idx_sys_notification_template_scene;
CREATE INDEX idx_sys_notification_template_scene ON public.sys_notification_template USING btree (tenant_id, company_id, biz_scene, channel_type, status);
DROP INDEX idx_sys_number_rule_status;
CREATE INDEX idx_sys_number_rule_status ON public.sys_number_rule USING btree (tenant_id, company_id, status, module_code);
DROP INDEX idx_sys_outbox_event_pending;
CREATE INDEX idx_sys_outbox_event_pending ON public.sys_outbox_event USING btree (tenant_id, company_id, status, next_retry_at);
DROP INDEX idx_sys_outbox_event_type;
CREATE INDEX idx_sys_outbox_event_type ON public.sys_outbox_event USING btree (tenant_id, company_id, event_type, occurred_at DESC);
DROP INDEX idx_sys_position_department;
CREATE INDEX idx_sys_position_department ON public.sys_position USING btree (tenant_id, company_id, department_id, status);
DROP INDEX idx_sys_print_log_biz;
CREATE INDEX idx_sys_print_log_biz ON public.sys_print_log USING btree (tenant_id, company_id, biz_type, biz_id, occurred_at DESC);
DROP INDEX idx_sys_print_log_user;
CREATE INDEX idx_sys_print_log_user ON public.sys_print_log USING btree (tenant_id, company_id, printer_user_id, occurred_at DESC);
DROP INDEX idx_sys_print_template_report;
CREATE INDEX idx_sys_print_template_report ON public.sys_print_template USING btree (tenant_id, company_id, report_id, is_default, status);
DROP INDEX idx_sys_role_status;
CREATE INDEX idx_sys_role_status ON public.sys_role USING btree (tenant_id, company_id, status, sort_no);
DROP INDEX idx_sys_role_permission_code;
CREATE INDEX idx_sys_role_permission_code ON public.sys_role_permission USING btree (tenant_id, company_id, permission_code);
DROP INDEX idx_sys_scheduled_job_status;
CREATE INDEX idx_sys_scheduled_job_status ON public.sys_scheduled_job USING btree (tenant_id, company_id, status, next_run_at);
DROP INDEX idx_sys_scheduled_job_log_job;
CREATE INDEX idx_sys_scheduled_job_log_job ON public.sys_scheduled_job_log USING btree (tenant_id, job_id, start_at DESC);
DROP INDEX idx_sys_scheduled_job_log_result;
CREATE INDEX idx_sys_scheduled_job_log_result ON public.sys_scheduled_job_log USING btree (tenant_id, execute_result, start_at DESC);
DROP INDEX idx_sys_scheduled_job_log_running;
CREATE INDEX idx_sys_scheduled_job_log_running ON public.sys_scheduled_job_log USING btree (tenant_id, job_id, end_at) WHERE (end_at IS NULL);
DROP INDEX idx_sys_user_data_scope_user;
CREATE INDEX idx_sys_user_data_scope_user ON public.sys_user_data_scope USING btree (tenant_id, company_id, user_id, valid_to);
DROP INDEX idx_sys_user_password_history_user;
CREATE INDEX idx_sys_user_password_history_user ON public.sys_user_password_history USING btree (tenant_id, user_id, created_at DESC);
DROP INDEX idx_sys_user_role_role;
CREATE INDEX idx_sys_user_role_role ON public.sys_user_role USING btree (tenant_id, company_id, role_id, status);
