-- mdm 域三列外键 (tenant_id, company_id, x_id) 子表侧补前导索引 7 条（04 §6.2 项 2a，v1.25）。
-- 规则：每条三列 FK 的子表须有以 (tenant_id, company_id, x_id) 依次打头的 btree 索引；部分索引仅当谓词为「x_id IS NOT NULL」时计入
-- （WHERE deleted = false 等谓词的部分唯一索引不覆盖软删除行，父表 DELETE/UPDATE 的 RI 检查用不上，故仍补普通索引）。
-- 清单由目录查询（pgTAP composite_fk.sql 同一条件）在空库全量迁移后得出；Flyway 事务内普通 CREATE INDEX，与 #84/#90/#101 一致。

CREATE INDEX idx_mdm_material_factory_material ON mdm_material_factory (tenant_id, company_id, material_id);
CREATE INDEX idx_mdm_substitute_material ON mdm_material_substitute (tenant_id, company_id, material_id);
CREATE INDEX idx_mdm_payment_term_line_term ON mdm_payment_term_line (tenant_id, company_id, payment_term_id);
CREATE INDEX idx_mdm_price_line_list ON mdm_price_list_line (tenant_id, company_id, price_list_id);
CREATE INDEX idx_mdm_evaluation_supplier ON mdm_supplier_evaluation (tenant_id, company_id, supplier_id);
CREATE INDEX idx_mdm_quotation_line_quotation ON mdm_supplier_quotation_line (tenant_id, company_id, quotation_id);
CREATE INDEX idx_mdm_warehouse_zone_warehouse ON mdm_warehouse_zone (tenant_id, company_id, warehouse_id);
