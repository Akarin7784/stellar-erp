-- inv 域三列外键 (tenant_id, company_id, x_id) 子表侧补前导索引 17 条（04 §6.2 项 2a，v1.25）。
-- 规则：每条三列 FK 的子表须有以 (tenant_id, company_id, x_id) 依次打头的 btree 索引；部分索引仅当谓词为「x_id IS NOT NULL」时计入
-- （WHERE deleted = false 等谓词的部分唯一索引不覆盖软删除行，父表 DELETE/UPDATE 的 RI 检查用不上，故仍补普通索引）。
-- 清单由目录查询（pgTAP composite_fk.sql 同一条件）在空库全量迁移后得出；Flyway 事务内普通 CREATE INDEX，与 #84/#90/#101 一致。

CREATE INDEX idx_inv_age_snapshot_material ON inv_age_snapshot (tenant_id, company_id, material_id);
CREATE INDEX idx_inv_age_snapshot_wh ON inv_age_snapshot (tenant_id, company_id, warehouse_id);
CREATE INDEX idx_inv_batch_supplier ON inv_batch (tenant_id, company_id, supplier_id);
CREATE INDEX idx_inv_cost_adjustment_line_wh ON inv_cost_adjustment_line (tenant_id, company_id, warehouse_id);
CREATE INDEX idx_inv_cost_layer_material ON inv_cost_layer (tenant_id, company_id, material_id);
CREATE INDEX idx_inv_event_wait_wh ON inv_event_wait (tenant_id, company_id, warehouse_id);
CREATE INDEX idx_inv_replenishment_material ON inv_replenishment (tenant_id, company_id, material_id);
CREATE INDEX idx_inv_replenishment_wh ON inv_replenishment (tenant_id, company_id, warehouse_id);
CREATE INDEX idx_inv_reservation_line_wh ON inv_reservation_line (tenant_id, company_id, warehouse_id);
CREATE INDEX idx_inv_scan_log_wh ON inv_scan_log (tenant_id, company_id, warehouse_id);
CREATE INDEX idx_inv_serial_txn_wh ON inv_serial_txn (tenant_id, company_id, warehouse_id);
CREATE INDEX idx_inv_stock_summary_material ON inv_stock_summary (tenant_id, company_id, material_id);
CREATE INDEX idx_inv_stock_summary_wh ON inv_stock_summary (tenant_id, company_id, warehouse_id);
CREATE INDEX idx_inv_stocktake_plan ON inv_stocktake (tenant_id, company_id, plan_id);
CREATE INDEX idx_inv_stocktake_line_material ON inv_stocktake_line (tenant_id, company_id, material_id);
CREATE INDEX idx_inv_transfer_from_factory ON inv_transfer (tenant_id, company_id, from_factory_id);
CREATE INDEX idx_inv_transfer_to_factory ON inv_transfer (tenant_id, company_id, to_factory_id);
