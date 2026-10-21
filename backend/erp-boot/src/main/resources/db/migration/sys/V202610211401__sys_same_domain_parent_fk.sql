-- 同域父子表外键改为复合外键 (tenant_id, company_id, x_id) → 父表 (tenant_id, company_id, id)（蓝色大肥鱼 2026-10-21 指派）
-- 范围：main（871dc93）public 下全部同域单列外键，共 74 处（prd 46 / sal 28）；子表、父表均有 company_id NOT NULL。
-- 保留原约束名与 ON DELETE 行为（RESTRICT / NO ACTION），ON UPDATE NO ACTION、MATCH SIMPLE、不可延迟。
-- 被引用父表 34 张各加 UNIQUE (tenant_id, company_id, id)（uk_<table>_tenant_company_id）。表内无数据，直接建（不用 NOT VALID）。
-- 不含：mdm 域内部外键（0707 已为 (tenant_id, x_id)，是否升级到 company 级待定）；flowable 引擎表（wf schema）。

-- 1. 被引用父表加 UNIQUE (tenant_id, company_id, id)
ALTER TABLE prd_bom ADD CONSTRAINT uk_prd_bom_tenant_company_id UNIQUE (tenant_id, company_id, id);
ALTER TABLE prd_bom_line ADD CONSTRAINT uk_prd_bom_line_tenant_company_id UNIQUE (tenant_id, company_id, id);
ALTER TABLE prd_completion_receipt ADD CONSTRAINT uk_prd_completion_receipt_tenant_company_id UNIQUE (tenant_id, company_id, id);
ALTER TABLE prd_defect_code ADD CONSTRAINT uk_prd_defect_code_tenant_company_id UNIQUE (tenant_id, company_id, id);
ALTER TABLE prd_equipment ADD CONSTRAINT uk_prd_equipment_tenant_company_id UNIQUE (tenant_id, company_id, id);
ALTER TABLE prd_inspection ADD CONSTRAINT uk_prd_inspection_tenant_company_id UNIQUE (tenant_id, company_id, id);
ALTER TABLE prd_inspection_standard ADD CONSTRAINT uk_prd_inspection_standard_tenant_company_id UNIQUE (tenant_id, company_id, id);
ALTER TABLE prd_material_issue ADD CONSTRAINT uk_prd_material_issue_tenant_company_id UNIQUE (tenant_id, company_id, id);
ALTER TABLE prd_mps ADD CONSTRAINT uk_prd_mps_tenant_company_id UNIQUE (tenant_id, company_id, id);
ALTER TABLE prd_mrp_run ADD CONSTRAINT uk_prd_mrp_run_tenant_company_id UNIQUE (tenant_id, company_id, id);
ALTER TABLE prd_ncr ADD CONSTRAINT uk_prd_ncr_tenant_company_id UNIQUE (tenant_id, company_id, id);
ALTER TABLE prd_outsourcing_issue ADD CONSTRAINT uk_prd_outsourcing_issue_tenant_company_id UNIQUE (tenant_id, company_id, id);
ALTER TABLE prd_outsourcing_order ADD CONSTRAINT uk_prd_outsourcing_order_tenant_company_id UNIQUE (tenant_id, company_id, id);
ALTER TABLE prd_outsourcing_receipt ADD CONSTRAINT uk_prd_outsourcing_receipt_tenant_company_id UNIQUE (tenant_id, company_id, id);
ALTER TABLE prd_outsourcing_settlement ADD CONSTRAINT uk_prd_outsourcing_settlement_tenant_company_id UNIQUE (tenant_id, company_id, id);
ALTER TABLE prd_routing ADD CONSTRAINT uk_prd_routing_tenant_company_id UNIQUE (tenant_id, company_id, id);
ALTER TABLE prd_routing_operation ADD CONSTRAINT uk_prd_routing_operation_tenant_company_id UNIQUE (tenant_id, company_id, id);
ALTER TABLE prd_work_center ADD CONSTRAINT uk_prd_work_center_tenant_company_id UNIQUE (tenant_id, company_id, id);
ALTER TABLE prd_work_order ADD CONSTRAINT uk_prd_work_order_tenant_company_id UNIQUE (tenant_id, company_id, id);
ALTER TABLE prd_work_order_material ADD CONSTRAINT uk_prd_work_order_material_tenant_company_id UNIQUE (tenant_id, company_id, id);
ALTER TABLE prd_work_order_operation ADD CONSTRAINT uk_prd_work_order_operation_tenant_company_id UNIQUE (tenant_id, company_id, id);
ALTER TABLE prd_work_report ADD CONSTRAINT uk_prd_work_report_tenant_company_id UNIQUE (tenant_id, company_id, id);
ALTER TABLE sal_delivery_note ADD CONSTRAINT uk_sal_delivery_note_tenant_company_id UNIQUE (tenant_id, company_id, id);
ALTER TABLE sal_delivery_note_line ADD CONSTRAINT uk_sal_delivery_note_line_tenant_company_id UNIQUE (tenant_id, company_id, id);
ALTER TABLE sal_inquiry ADD CONSTRAINT uk_sal_inquiry_tenant_company_id UNIQUE (tenant_id, company_id, id);
ALTER TABLE sal_invoice ADD CONSTRAINT uk_sal_invoice_tenant_company_id UNIQUE (tenant_id, company_id, id);
ALTER TABLE sal_invoice_application ADD CONSTRAINT uk_sal_invoice_application_tenant_company_id UNIQUE (tenant_id, company_id, id);
ALTER TABLE sal_quotation ADD CONSTRAINT uk_sal_quotation_tenant_company_id UNIQUE (tenant_id, company_id, id);
ALTER TABLE sal_sales_forecast ADD CONSTRAINT uk_sal_sales_forecast_tenant_company_id UNIQUE (tenant_id, company_id, id);
ALTER TABLE sal_sales_order ADD CONSTRAINT uk_sal_sales_order_tenant_company_id UNIQUE (tenant_id, company_id, id);
ALTER TABLE sal_sales_order_line ADD CONSTRAINT uk_sal_sales_order_line_tenant_company_id UNIQUE (tenant_id, company_id, id);
ALTER TABLE sal_sales_return ADD CONSTRAINT uk_sal_sales_return_tenant_company_id UNIQUE (tenant_id, company_id, id);
ALTER TABLE sal_sales_return_line ADD CONSTRAINT uk_sal_sales_return_line_tenant_company_id UNIQUE (tenant_id, company_id, id);
ALTER TABLE sal_statement ADD CONSTRAINT uk_sal_statement_tenant_company_id UNIQUE (tenant_id, company_id, id);

-- 2. 同域单列 FK → 复合 FK
ALTER TABLE prd_bom_line DROP CONSTRAINT fk_prd_bom_line_bom,
    ADD CONSTRAINT fk_prd_bom_line_bom FOREIGN KEY (tenant_id, company_id, bom_id) REFERENCES prd_bom (tenant_id, company_id, id) ON DELETE RESTRICT;
ALTER TABLE prd_bom_substitute DROP CONSTRAINT fk_prd_bom_substitute_line,
    ADD CONSTRAINT fk_prd_bom_substitute_line FOREIGN KEY (tenant_id, company_id, bom_line_id) REFERENCES prd_bom_line (tenant_id, company_id, id) ON DELETE RESTRICT;
ALTER TABLE prd_capacity_load DROP CONSTRAINT fk_prd_capacity_load_wc,
    ADD CONSTRAINT fk_prd_capacity_load_wc FOREIGN KEY (tenant_id, company_id, work_center_id) REFERENCES prd_work_center (tenant_id, company_id, id);
ALTER TABLE prd_completion_receipt DROP CONSTRAINT fk_prd_completion_receipt_wo,
    ADD CONSTRAINT fk_prd_completion_receipt_wo FOREIGN KEY (tenant_id, company_id, work_order_id) REFERENCES prd_work_order (tenant_id, company_id, id);
ALTER TABLE prd_completion_receipt_line DROP CONSTRAINT fk_prd_completion_receipt_line_rcpt,
    ADD CONSTRAINT fk_prd_completion_receipt_line_rcpt FOREIGN KEY (tenant_id, company_id, receipt_id) REFERENCES prd_completion_receipt (tenant_id, company_id, id) ON DELETE RESTRICT;
ALTER TABLE prd_equipment DROP CONSTRAINT fk_prd_equipment_wc,
    ADD CONSTRAINT fk_prd_equipment_wc FOREIGN KEY (tenant_id, company_id, work_center_id) REFERENCES prd_work_center (tenant_id, company_id, id);
ALTER TABLE prd_equipment_maintenance DROP CONSTRAINT fk_prd_equipment_maintenance_eq,
    ADD CONSTRAINT fk_prd_equipment_maintenance_eq FOREIGN KEY (tenant_id, company_id, equipment_id) REFERENCES prd_equipment (tenant_id, company_id, id);
ALTER TABLE prd_inspection DROP CONSTRAINT fk_prd_inspection_standard,
    ADD CONSTRAINT fk_prd_inspection_standard FOREIGN KEY (tenant_id, company_id, standard_id) REFERENCES prd_inspection_standard (tenant_id, company_id, id);
ALTER TABLE prd_inspection DROP CONSTRAINT fk_prd_inspection_wo,
    ADD CONSTRAINT fk_prd_inspection_wo FOREIGN KEY (tenant_id, company_id, work_order_id) REFERENCES prd_work_order (tenant_id, company_id, id);
ALTER TABLE prd_inspection_line DROP CONSTRAINT fk_prd_inspection_line_inspection,
    ADD CONSTRAINT fk_prd_inspection_line_inspection FOREIGN KEY (tenant_id, company_id, inspection_id) REFERENCES prd_inspection (tenant_id, company_id, id) ON DELETE RESTRICT;
ALTER TABLE prd_inspection_standard_item DROP CONSTRAINT fk_prd_inspection_standard_item_std,
    ADD CONSTRAINT fk_prd_inspection_standard_item_std FOREIGN KEY (tenant_id, company_id, standard_id) REFERENCES prd_inspection_standard (tenant_id, company_id, id) ON DELETE RESTRICT;
ALTER TABLE prd_material_issue DROP CONSTRAINT fk_prd_material_issue_wo,
    ADD CONSTRAINT fk_prd_material_issue_wo FOREIGN KEY (tenant_id, company_id, work_order_id) REFERENCES prd_work_order (tenant_id, company_id, id);
ALTER TABLE prd_material_issue_line DROP CONSTRAINT fk_prd_material_issue_line_issue,
    ADD CONSTRAINT fk_prd_material_issue_line_issue FOREIGN KEY (tenant_id, company_id, issue_id) REFERENCES prd_material_issue (tenant_id, company_id, id) ON DELETE RESTRICT;
ALTER TABLE prd_material_issue_line DROP CONSTRAINT fk_prd_material_issue_line_wom,
    ADD CONSTRAINT fk_prd_material_issue_line_wom FOREIGN KEY (tenant_id, company_id, work_order_material_id) REFERENCES prd_work_order_material (tenant_id, company_id, id);
ALTER TABLE prd_mps_line DROP CONSTRAINT fk_prd_mps_line_mps,
    ADD CONSTRAINT fk_prd_mps_line_mps FOREIGN KEY (tenant_id, company_id, mps_id) REFERENCES prd_mps (tenant_id, company_id, id) ON DELETE RESTRICT;
ALTER TABLE prd_mrp_action DROP CONSTRAINT fk_prd_mrp_action_run,
    ADD CONSTRAINT fk_prd_mrp_action_run FOREIGN KEY (tenant_id, company_id, mrp_run_id) REFERENCES prd_mrp_run (tenant_id, company_id, id) ON DELETE RESTRICT;
ALTER TABLE prd_mrp_demand DROP CONSTRAINT fk_prd_mrp_demand_run,
    ADD CONSTRAINT fk_prd_mrp_demand_run FOREIGN KEY (tenant_id, company_id, mrp_run_id) REFERENCES prd_mrp_run (tenant_id, company_id, id) ON DELETE RESTRICT;
ALTER TABLE prd_mrp_plan_order DROP CONSTRAINT fk_prd_mrp_plan_order_run,
    ADD CONSTRAINT fk_prd_mrp_plan_order_run FOREIGN KEY (tenant_id, company_id, mrp_run_id) REFERENCES prd_mrp_run (tenant_id, company_id, id) ON DELETE RESTRICT;
ALTER TABLE prd_ncr DROP CONSTRAINT fk_prd_ncr_defect_code,
    ADD CONSTRAINT fk_prd_ncr_defect_code FOREIGN KEY (tenant_id, company_id, defect_code_id) REFERENCES prd_defect_code (tenant_id, company_id, id);
ALTER TABLE prd_ncr DROP CONSTRAINT fk_prd_ncr_inspection,
    ADD CONSTRAINT fk_prd_ncr_inspection FOREIGN KEY (tenant_id, company_id, inspection_id) REFERENCES prd_inspection (tenant_id, company_id, id);
ALTER TABLE prd_ncr DROP CONSTRAINT fk_prd_ncr_work_order,
    ADD CONSTRAINT fk_prd_ncr_work_order FOREIGN KEY (tenant_id, company_id, work_order_id) REFERENCES prd_work_order (tenant_id, company_id, id);
ALTER TABLE prd_ncr_action DROP CONSTRAINT fk_prd_ncr_action_ncr,
    ADD CONSTRAINT fk_prd_ncr_action_ncr FOREIGN KEY (tenant_id, company_id, ncr_id) REFERENCES prd_ncr (tenant_id, company_id, id) ON DELETE RESTRICT;
ALTER TABLE prd_outsourcing_issue DROP CONSTRAINT fk_prd_outsourcing_issue_order,
    ADD CONSTRAINT fk_prd_outsourcing_issue_order FOREIGN KEY (tenant_id, company_id, outsourcing_order_id) REFERENCES prd_outsourcing_order (tenant_id, company_id, id);
ALTER TABLE prd_outsourcing_issue_line DROP CONSTRAINT fk_prd_outsourcing_issue_line_issue,
    ADD CONSTRAINT fk_prd_outsourcing_issue_line_issue FOREIGN KEY (tenant_id, company_id, issue_id) REFERENCES prd_outsourcing_issue (tenant_id, company_id, id) ON DELETE RESTRICT;
ALTER TABLE prd_outsourcing_order_line DROP CONSTRAINT fk_prd_outsourcing_order_line_order,
    ADD CONSTRAINT fk_prd_outsourcing_order_line_order FOREIGN KEY (tenant_id, company_id, outsourcing_order_id) REFERENCES prd_outsourcing_order (tenant_id, company_id, id) ON DELETE RESTRICT;
ALTER TABLE prd_outsourcing_receipt DROP CONSTRAINT fk_prd_outsourcing_receipt_order,
    ADD CONSTRAINT fk_prd_outsourcing_receipt_order FOREIGN KEY (tenant_id, company_id, outsourcing_order_id) REFERENCES prd_outsourcing_order (tenant_id, company_id, id);
ALTER TABLE prd_outsourcing_receipt_line DROP CONSTRAINT fk_prd_outsourcing_receipt_line_rcpt,
    ADD CONSTRAINT fk_prd_outsourcing_receipt_line_rcpt FOREIGN KEY (tenant_id, company_id, receipt_id) REFERENCES prd_outsourcing_receipt (tenant_id, company_id, id) ON DELETE RESTRICT;
ALTER TABLE prd_outsourcing_settlement_line DROP CONSTRAINT fk_prd_outsourcing_settlement_line_settle,
    ADD CONSTRAINT fk_prd_outsourcing_settlement_line_settle FOREIGN KEY (tenant_id, company_id, settlement_id) REFERENCES prd_outsourcing_settlement (tenant_id, company_id, id) ON DELETE RESTRICT;
ALTER TABLE prd_routing_operation DROP CONSTRAINT fk_prd_routing_operation_routing,
    ADD CONSTRAINT fk_prd_routing_operation_routing FOREIGN KEY (tenant_id, company_id, routing_id) REFERENCES prd_routing (tenant_id, company_id, id) ON DELETE RESTRICT;
ALTER TABLE prd_routing_operation DROP CONSTRAINT fk_prd_routing_operation_wc,
    ADD CONSTRAINT fk_prd_routing_operation_wc FOREIGN KEY (tenant_id, company_id, work_center_id) REFERENCES prd_work_center (tenant_id, company_id, id);
ALTER TABLE prd_routing_operation_alt DROP CONSTRAINT fk_prd_routing_operation_alt_op,
    ADD CONSTRAINT fk_prd_routing_operation_alt_op FOREIGN KEY (tenant_id, company_id, routing_operation_id) REFERENCES prd_routing_operation (tenant_id, company_id, id) ON DELETE RESTRICT;
ALTER TABLE prd_routing_operation_alt DROP CONSTRAINT fk_prd_routing_operation_alt_wc,
    ADD CONSTRAINT fk_prd_routing_operation_alt_wc FOREIGN KEY (tenant_id, company_id, alt_work_center_id) REFERENCES prd_work_center (tenant_id, company_id, id);
ALTER TABLE prd_work_center_calendar DROP CONSTRAINT fk_prd_work_center_calendar_wc,
    ADD CONSTRAINT fk_prd_work_center_calendar_wc FOREIGN KEY (tenant_id, company_id, work_center_id) REFERENCES prd_work_center (tenant_id, company_id, id) ON DELETE RESTRICT;
ALTER TABLE prd_work_order DROP CONSTRAINT fk_prd_work_order_bom,
    ADD CONSTRAINT fk_prd_work_order_bom FOREIGN KEY (tenant_id, company_id, bom_id) REFERENCES prd_bom (tenant_id, company_id, id);
ALTER TABLE prd_work_order DROP CONSTRAINT fk_prd_work_order_routing,
    ADD CONSTRAINT fk_prd_work_order_routing FOREIGN KEY (tenant_id, company_id, routing_id) REFERENCES prd_routing (tenant_id, company_id, id);
ALTER TABLE prd_work_order_change DROP CONSTRAINT fk_prd_work_order_change_wo,
    ADD CONSTRAINT fk_prd_work_order_change_wo FOREIGN KEY (tenant_id, company_id, work_order_id) REFERENCES prd_work_order (tenant_id, company_id, id) ON DELETE RESTRICT;
ALTER TABLE prd_work_order_material DROP CONSTRAINT fk_prd_work_order_material_wo,
    ADD CONSTRAINT fk_prd_work_order_material_wo FOREIGN KEY (tenant_id, company_id, work_order_id) REFERENCES prd_work_order (tenant_id, company_id, id) ON DELETE RESTRICT;
ALTER TABLE prd_work_order_operation DROP CONSTRAINT fk_prd_work_order_operation_wc,
    ADD CONSTRAINT fk_prd_work_order_operation_wc FOREIGN KEY (tenant_id, company_id, work_center_id) REFERENCES prd_work_center (tenant_id, company_id, id);
ALTER TABLE prd_work_order_operation DROP CONSTRAINT fk_prd_work_order_operation_wo,
    ADD CONSTRAINT fk_prd_work_order_operation_wo FOREIGN KEY (tenant_id, company_id, work_order_id) REFERENCES prd_work_order (tenant_id, company_id, id) ON DELETE RESTRICT;
ALTER TABLE prd_work_order_relation DROP CONSTRAINT fk_prd_work_order_relation_src,
    ADD CONSTRAINT fk_prd_work_order_relation_src FOREIGN KEY (tenant_id, company_id, source_work_order_id) REFERENCES prd_work_order (tenant_id, company_id, id) ON DELETE RESTRICT;
ALTER TABLE prd_work_order_relation DROP CONSTRAINT fk_prd_work_order_relation_tgt,
    ADD CONSTRAINT fk_prd_work_order_relation_tgt FOREIGN KEY (tenant_id, company_id, target_work_order_id) REFERENCES prd_work_order (tenant_id, company_id, id) ON DELETE RESTRICT;
ALTER TABLE prd_work_report DROP CONSTRAINT fk_prd_work_report_op,
    ADD CONSTRAINT fk_prd_work_report_op FOREIGN KEY (tenant_id, company_id, work_order_operation_id) REFERENCES prd_work_order_operation (tenant_id, company_id, id);
ALTER TABLE prd_work_report DROP CONSTRAINT fk_prd_work_report_wo,
    ADD CONSTRAINT fk_prd_work_report_wo FOREIGN KEY (tenant_id, company_id, work_order_id) REFERENCES prd_work_order (tenant_id, company_id, id);
ALTER TABLE prd_work_report_defect DROP CONSTRAINT fk_prd_work_report_defect_code,
    ADD CONSTRAINT fk_prd_work_report_defect_code FOREIGN KEY (tenant_id, company_id, defect_code_id) REFERENCES prd_defect_code (tenant_id, company_id, id);
ALTER TABLE prd_work_report_defect DROP CONSTRAINT fk_prd_work_report_defect_report,
    ADD CONSTRAINT fk_prd_work_report_defect_report FOREIGN KEY (tenant_id, company_id, report_id) REFERENCES prd_work_report (tenant_id, company_id, id) ON DELETE RESTRICT;
ALTER TABLE prd_work_report_labor DROP CONSTRAINT fk_prd_work_report_labor_report,
    ADD CONSTRAINT fk_prd_work_report_labor_report FOREIGN KEY (tenant_id, company_id, report_id) REFERENCES prd_work_report (tenant_id, company_id, id) ON DELETE RESTRICT;
ALTER TABLE sal_delivery_note DROP CONSTRAINT fk_sal_delivery_note_order,
    ADD CONSTRAINT fk_sal_delivery_note_order FOREIGN KEY (tenant_id, company_id, sales_order_id) REFERENCES sal_sales_order (tenant_id, company_id, id);
ALTER TABLE sal_delivery_note_line DROP CONSTRAINT fk_sal_dn_line_note,
    ADD CONSTRAINT fk_sal_dn_line_note FOREIGN KEY (tenant_id, company_id, delivery_note_id) REFERENCES sal_delivery_note (tenant_id, company_id, id);
ALTER TABLE sal_delivery_note_line DROP CONSTRAINT fk_sal_dn_line_so_line,
    ADD CONSTRAINT fk_sal_dn_line_so_line FOREIGN KEY (tenant_id, company_id, sales_order_line_id) REFERENCES sal_sales_order_line (tenant_id, company_id, id);
ALTER TABLE sal_delivery_serial DROP CONSTRAINT fk_sal_delivery_serial_dn,
    ADD CONSTRAINT fk_sal_delivery_serial_dn FOREIGN KEY (tenant_id, company_id, delivery_note_id) REFERENCES sal_delivery_note (tenant_id, company_id, id);
ALTER TABLE sal_delivery_serial DROP CONSTRAINT fk_sal_delivery_serial_line,
    ADD CONSTRAINT fk_sal_delivery_serial_line FOREIGN KEY (tenant_id, company_id, delivery_note_line_id) REFERENCES sal_delivery_note_line (tenant_id, company_id, id);
ALTER TABLE sal_inquiry_line DROP CONSTRAINT fk_sal_inquiry_line_inquiry,
    ADD CONSTRAINT fk_sal_inquiry_line_inquiry FOREIGN KEY (tenant_id, company_id, inquiry_id) REFERENCES sal_inquiry (tenant_id, company_id, id);
ALTER TABLE sal_invoice DROP CONSTRAINT fk_sal_invoice_application,
    ADD CONSTRAINT fk_sal_invoice_application FOREIGN KEY (tenant_id, company_id, application_id) REFERENCES sal_invoice_application (tenant_id, company_id, id);
ALTER TABLE sal_invoice_application_line DROP CONSTRAINT fk_sal_iva_line_app,
    ADD CONSTRAINT fk_sal_iva_line_app FOREIGN KEY (tenant_id, company_id, application_id) REFERENCES sal_invoice_application (tenant_id, company_id, id);
ALTER TABLE sal_invoice_application_line DROP CONSTRAINT fk_sal_iva_line_dn,
    ADD CONSTRAINT fk_sal_iva_line_dn FOREIGN KEY (tenant_id, company_id, delivery_id) REFERENCES sal_delivery_note (tenant_id, company_id, id);
ALTER TABLE sal_invoice_line DROP CONSTRAINT fk_sal_invoice_line_inv,
    ADD CONSTRAINT fk_sal_invoice_line_inv FOREIGN KEY (tenant_id, company_id, invoice_id) REFERENCES sal_invoice (tenant_id, company_id, id);
ALTER TABLE sal_invoice_relation DROP CONSTRAINT fk_sal_invoice_relation_inv,
    ADD CONSTRAINT fk_sal_invoice_relation_inv FOREIGN KEY (tenant_id, company_id, invoice_id) REFERENCES sal_invoice (tenant_id, company_id, id);
ALTER TABLE sal_pick_detail DROP CONSTRAINT fk_sal_pick_detail_dn,
    ADD CONSTRAINT fk_sal_pick_detail_dn FOREIGN KEY (tenant_id, company_id, delivery_note_id) REFERENCES sal_delivery_note (tenant_id, company_id, id);
ALTER TABLE sal_pick_detail DROP CONSTRAINT fk_sal_pick_detail_dn_line,
    ADD CONSTRAINT fk_sal_pick_detail_dn_line FOREIGN KEY (tenant_id, company_id, delivery_note_line_id) REFERENCES sal_delivery_note_line (tenant_id, company_id, id);
ALTER TABLE sal_quotation DROP CONSTRAINT fk_sal_quotation_inquiry,
    ADD CONSTRAINT fk_sal_quotation_inquiry FOREIGN KEY (tenant_id, company_id, inquiry_id) REFERENCES sal_inquiry (tenant_id, company_id, id);
ALTER TABLE sal_quotation_line DROP CONSTRAINT fk_sal_quotation_line_q,
    ADD CONSTRAINT fk_sal_quotation_line_q FOREIGN KEY (tenant_id, company_id, quotation_id) REFERENCES sal_quotation (tenant_id, company_id, id);
ALTER TABLE sal_quotation_version DROP CONSTRAINT fk_sal_quotation_version_q,
    ADD CONSTRAINT fk_sal_quotation_version_q FOREIGN KEY (tenant_id, company_id, quotation_id) REFERENCES sal_quotation (tenant_id, company_id, id);
ALTER TABLE sal_return_inspection DROP CONSTRAINT fk_sal_return_inspection_l,
    ADD CONSTRAINT fk_sal_return_inspection_l FOREIGN KEY (tenant_id, company_id, return_line_id) REFERENCES sal_sales_return_line (tenant_id, company_id, id);
ALTER TABLE sal_return_inspection DROP CONSTRAINT fk_sal_return_inspection_r,
    ADD CONSTRAINT fk_sal_return_inspection_r FOREIGN KEY (tenant_id, company_id, return_id) REFERENCES sal_sales_return (tenant_id, company_id, id);
ALTER TABLE sal_sales_forecast_line DROP CONSTRAINT fk_sal_forecast_line_f,
    ADD CONSTRAINT fk_sal_forecast_line_f FOREIGN KEY (tenant_id, company_id, forecast_id) REFERENCES sal_sales_forecast (tenant_id, company_id, id);
ALTER TABLE sal_sales_order DROP CONSTRAINT fk_sal_sales_order_quotation,
    ADD CONSTRAINT fk_sal_sales_order_quotation FOREIGN KEY (tenant_id, company_id, quotation_id) REFERENCES sal_quotation (tenant_id, company_id, id);
ALTER TABLE sal_sales_order_line DROP CONSTRAINT fk_sal_sales_order_line_o,
    ADD CONSTRAINT fk_sal_sales_order_line_o FOREIGN KEY (tenant_id, company_id, sales_order_id) REFERENCES sal_sales_order (tenant_id, company_id, id);
ALTER TABLE sal_sales_order_line_version DROP CONSTRAINT fk_sal_sales_order_line_version_v,
    ADD CONSTRAINT fk_sal_sales_order_line_version_v FOREIGN KEY (tenant_id, company_id, sales_order_id) REFERENCES sal_sales_order (tenant_id, company_id, id);
ALTER TABLE sal_sales_order_version DROP CONSTRAINT fk_sal_sales_order_version_o,
    ADD CONSTRAINT fk_sal_sales_order_version_o FOREIGN KEY (tenant_id, company_id, sales_order_id) REFERENCES sal_sales_order (tenant_id, company_id, id);
ALTER TABLE sal_sales_return DROP CONSTRAINT fk_sal_sales_return_dn,
    ADD CONSTRAINT fk_sal_sales_return_dn FOREIGN KEY (tenant_id, company_id, original_delivery_id) REFERENCES sal_delivery_note (tenant_id, company_id, id);
ALTER TABLE sal_sales_return DROP CONSTRAINT fk_sal_sales_return_so,
    ADD CONSTRAINT fk_sal_sales_return_so FOREIGN KEY (tenant_id, company_id, sales_order_id) REFERENCES sal_sales_order (tenant_id, company_id, id);
ALTER TABLE sal_sales_return_line DROP CONSTRAINT fk_sal_return_line_dn_line,
    ADD CONSTRAINT fk_sal_return_line_dn_line FOREIGN KEY (tenant_id, company_id, original_delivery_line_id) REFERENCES sal_delivery_note_line (tenant_id, company_id, id);
ALTER TABLE sal_sales_return_line DROP CONSTRAINT fk_sal_return_line_return,
    ADD CONSTRAINT fk_sal_return_line_return FOREIGN KEY (tenant_id, company_id, return_id) REFERENCES sal_sales_return (tenant_id, company_id, id);
ALTER TABLE sal_statement_line DROP CONSTRAINT fk_sal_statement_line_s,
    ADD CONSTRAINT fk_sal_statement_line_s FOREIGN KEY (tenant_id, company_id, statement_id) REFERENCES sal_statement (tenant_id, company_id, id);
