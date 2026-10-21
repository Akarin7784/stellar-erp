-- prd 域三列外键 (tenant_id, company_id, x_id) 子表侧补前导索引 11 条（04 §6.2 项 2a，v1.25）。
-- 规则：每条三列 FK 的子表须有以 (tenant_id, company_id, x_id) 依次打头的 btree 索引；部分索引仅当谓词为「x_id IS NOT NULL」时计入
-- （WHERE deleted = false 等谓词的部分唯一索引不覆盖软删除行，父表 DELETE/UPDATE 的 RI 检查用不上，故仍补普通索引）。
-- 清单由目录查询（pgTAP composite_fk.sql 同一条件）在空库全量迁移后得出；Flyway 事务内普通 CREATE INDEX，与 #84/#90/#101 一致。

CREATE INDEX idx_prd_bom_substitute_line ON prd_bom_substitute (tenant_id, company_id, bom_line_id);
CREATE INDEX idx_prd_inspection_standard ON prd_inspection (tenant_id, company_id, standard_id);
CREATE INDEX idx_prd_material_planning_material ON prd_material_planning (tenant_id, company_id, material_id);
CREATE INDEX idx_prd_ncr_defect_code ON prd_ncr (tenant_id, company_id, defect_code_id);
CREATE INDEX idx_prd_ncr_inspection ON prd_ncr (tenant_id, company_id, inspection_id);
CREATE INDEX idx_prd_routing_operation_routing ON prd_routing_operation (tenant_id, company_id, routing_id);
CREATE INDEX idx_prd_routing_operation_alt_op ON prd_routing_operation_alt (tenant_id, company_id, routing_operation_id);
CREATE INDEX idx_prd_routing_operation_alt_wc ON prd_routing_operation_alt (tenant_id, company_id, alt_work_center_id);
CREATE INDEX idx_prd_work_center_calendar_wc ON prd_work_center_calendar (tenant_id, company_id, work_center_id);
CREATE INDEX idx_prd_work_order_bom ON prd_work_order (tenant_id, company_id, bom_id);
CREATE INDEX idx_prd_work_order_routing ON prd_work_order (tenant_id, company_id, routing_id);
