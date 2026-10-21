-- sal 域三列外键 (tenant_id, company_id, x_id) 子表侧补前导索引 6 条（04 §6.2 项 2a，v1.25）。
-- 规则：每条三列 FK 的子表须有以 (tenant_id, company_id, x_id) 依次打头的 btree 索引；部分索引仅当谓词为「x_id IS NOT NULL」时计入
-- （WHERE deleted = false 等谓词的部分唯一索引不覆盖软删除行，父表 DELETE/UPDATE 的 RI 检查用不上，故仍补普通索引）。
-- 清单由目录查询（pgTAP composite_fk.sql 同一条件）在空库全量迁移后得出；Flyway 事务内普通 CREATE INDEX，与 #84/#90/#101 一致。

CREATE INDEX idx_sal_delivery_serial_dn ON sal_delivery_serial (tenant_id, company_id, delivery_note_id);
CREATE INDEX idx_sal_invoice_application ON sal_invoice (tenant_id, company_id, application_id);
CREATE INDEX idx_sal_pick_detail_dn ON sal_pick_detail (tenant_id, company_id, delivery_note_id);
CREATE INDEX idx_sal_return_inspection_r ON sal_return_inspection (tenant_id, company_id, return_id);
CREATE INDEX idx_sal_sales_order_quotation ON sal_sales_order (tenant_id, company_id, quotation_id);
CREATE INDEX idx_sal_sales_return_so ON sal_sales_return (tenant_id, company_id, sales_order_id);
