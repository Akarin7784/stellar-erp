-- inv → mdm 跨域 FK 27 条改为三列 (tenant_id, company_id, x_id) → mdm_x (tenant_id, company_id, id)。
-- 04 §6.2 项 2a：被引用表有 company_id 时三列为标准形（DB 层拒绝引用同租户其他公司的主数据）。
-- 27 条全部在普通表上（分区表 inv_stock_txn 无指向 mdm 的 FK）；子表 company_id 均 NOT NULL，约束名不变，NO ACTION。
-- 被引用表 mdm_material / mdm_factory 已有 uk_*_tenant_company_id；mdm_warehouse / mdm_customer / mdm_supplier 本迁移新增。

-- 前置检查：已有数据中子表 company_id 与被引用行 company_id 不一致时中止（需人工处理，不自动修正）
DO $$
DECLARE r record; n bigint; bad text := '';
BEGIN
  FOR r IN SELECT * FROM (VALUES
    ('fk_inv_age_snapshot_material', 'inv_age_snapshot', 'material_id', 'mdm_material'),
    ('fk_inv_age_snapshot_wh', 'inv_age_snapshot', 'warehouse_id', 'mdm_warehouse'),
    ('fk_inv_batch_material', 'inv_batch', 'material_id', 'mdm_material'),
    ('fk_inv_batch_supplier', 'inv_batch', 'supplier_id', 'mdm_supplier'),
    ('fk_inv_cost_adjustment_line_material', 'inv_cost_adjustment_line', 'material_id', 'mdm_material'),
    ('fk_inv_cost_adjustment_line_wh', 'inv_cost_adjustment_line', 'warehouse_id', 'mdm_warehouse'),
    ('fk_inv_cost_layer_material', 'inv_cost_layer', 'material_id', 'mdm_material'),
    ('fk_inv_cost_layer_wh', 'inv_cost_layer', 'warehouse_id', 'mdm_warehouse'),
    ('fk_inv_event_wait_wh', 'inv_event_wait', 'warehouse_id', 'mdm_warehouse'),
    ('fk_inv_replenishment_material', 'inv_replenishment', 'material_id', 'mdm_material'),
    ('fk_inv_replenishment_wh', 'inv_replenishment', 'warehouse_id', 'mdm_warehouse'),
    ('fk_inv_reservation_line_material', 'inv_reservation_line', 'material_id', 'mdm_material'),
    ('fk_inv_reservation_line_wh', 'inv_reservation_line', 'warehouse_id', 'mdm_warehouse'),
    ('fk_inv_scan_log_wh', 'inv_scan_log', 'warehouse_id', 'mdm_warehouse'),
    ('fk_inv_serial_customer', 'inv_serial', 'customer_id', 'mdm_customer'),
    ('fk_inv_serial_material', 'inv_serial', 'material_id', 'mdm_material'),
    ('fk_inv_serial_txn_wh', 'inv_serial_txn', 'warehouse_id', 'mdm_warehouse'),
    ('fk_inv_stock_summary_material', 'inv_stock_summary', 'material_id', 'mdm_material'),
    ('fk_inv_stock_summary_wh', 'inv_stock_summary', 'warehouse_id', 'mdm_warehouse'),
    ('fk_inv_stocktake_line_material', 'inv_stocktake_line', 'material_id', 'mdm_material'),
    ('fk_inv_stocktake_plan_wh', 'inv_stocktake_plan', 'warehouse_id', 'mdm_warehouse'),
    ('fk_inv_stocktake_wh', 'inv_stocktake', 'warehouse_id', 'mdm_warehouse'),
    ('fk_inv_transfer_from_factory', 'inv_transfer', 'from_factory_id', 'mdm_factory'),
    ('fk_inv_transfer_from_wh', 'inv_transfer', 'from_warehouse_id', 'mdm_warehouse'),
    ('fk_inv_transfer_line_material', 'inv_transfer_line', 'material_id', 'mdm_material'),
    ('fk_inv_transfer_to_factory', 'inv_transfer', 'to_factory_id', 'mdm_factory'),
    ('fk_inv_transfer_to_wh', 'inv_transfer', 'to_warehouse_id', 'mdm_warehouse')
  ) v(con, child, col, parent) LOOP
    EXECUTE format('SELECT count(*) FROM %I c JOIN %I p ON p.tenant_id = c.tenant_id AND p.id = c.%I WHERE p.company_id <> c.company_id',
                   r.child, r.parent, r.col) INTO n;
    IF n > 0 THEN bad := bad || format('%s: %s 行; ', r.con, n); END IF;
  END LOOP;
  IF bad <> '' THEN RAISE EXCEPTION 'inv → mdm 跨公司引用数据存在，无法改为三列 FK：%', bad; END IF;
END $$;

ALTER TABLE mdm_warehouse ADD CONSTRAINT uk_mdm_warehouse_tenant_company_id UNIQUE (tenant_id, company_id, id);
COMMENT ON CONSTRAINT uk_mdm_warehouse_tenant_company_id ON mdm_warehouse IS 'FK 参照先専用（三列 FK、04 §6.2 項 2a）。業務一意キーではない';
ALTER TABLE mdm_customer ADD CONSTRAINT uk_mdm_customer_tenant_company_id UNIQUE (tenant_id, company_id, id);
COMMENT ON CONSTRAINT uk_mdm_customer_tenant_company_id ON mdm_customer IS 'FK 参照先専用（三列 FK、04 §6.2 項 2a）。業務一意キーではない';
ALTER TABLE mdm_supplier ADD CONSTRAINT uk_mdm_supplier_tenant_company_id UNIQUE (tenant_id, company_id, id);
COMMENT ON CONSTRAINT uk_mdm_supplier_tenant_company_id ON mdm_supplier IS 'FK 参照先専用（三列 FK、04 §6.2 項 2a）。業務一意キーではない';

ALTER TABLE inv_age_snapshot DROP CONSTRAINT fk_inv_age_snapshot_material;
ALTER TABLE inv_age_snapshot ADD CONSTRAINT fk_inv_age_snapshot_material FOREIGN KEY (tenant_id, company_id, material_id) REFERENCES mdm_material (tenant_id, company_id, id);
ALTER TABLE inv_age_snapshot DROP CONSTRAINT fk_inv_age_snapshot_wh;
ALTER TABLE inv_age_snapshot ADD CONSTRAINT fk_inv_age_snapshot_wh FOREIGN KEY (tenant_id, company_id, warehouse_id) REFERENCES mdm_warehouse (tenant_id, company_id, id);
ALTER TABLE inv_batch DROP CONSTRAINT fk_inv_batch_material;
ALTER TABLE inv_batch ADD CONSTRAINT fk_inv_batch_material FOREIGN KEY (tenant_id, company_id, material_id) REFERENCES mdm_material (tenant_id, company_id, id);
ALTER TABLE inv_batch DROP CONSTRAINT fk_inv_batch_supplier;
ALTER TABLE inv_batch ADD CONSTRAINT fk_inv_batch_supplier FOREIGN KEY (tenant_id, company_id, supplier_id) REFERENCES mdm_supplier (tenant_id, company_id, id);
ALTER TABLE inv_cost_adjustment_line DROP CONSTRAINT fk_inv_cost_adjustment_line_material;
ALTER TABLE inv_cost_adjustment_line ADD CONSTRAINT fk_inv_cost_adjustment_line_material FOREIGN KEY (tenant_id, company_id, material_id) REFERENCES mdm_material (tenant_id, company_id, id);
ALTER TABLE inv_cost_adjustment_line DROP CONSTRAINT fk_inv_cost_adjustment_line_wh;
ALTER TABLE inv_cost_adjustment_line ADD CONSTRAINT fk_inv_cost_adjustment_line_wh FOREIGN KEY (tenant_id, company_id, warehouse_id) REFERENCES mdm_warehouse (tenant_id, company_id, id);
ALTER TABLE inv_cost_layer DROP CONSTRAINT fk_inv_cost_layer_material;
ALTER TABLE inv_cost_layer ADD CONSTRAINT fk_inv_cost_layer_material FOREIGN KEY (tenant_id, company_id, material_id) REFERENCES mdm_material (tenant_id, company_id, id);
ALTER TABLE inv_cost_layer DROP CONSTRAINT fk_inv_cost_layer_wh;
ALTER TABLE inv_cost_layer ADD CONSTRAINT fk_inv_cost_layer_wh FOREIGN KEY (tenant_id, company_id, warehouse_id) REFERENCES mdm_warehouse (tenant_id, company_id, id);
ALTER TABLE inv_event_wait DROP CONSTRAINT fk_inv_event_wait_wh;
ALTER TABLE inv_event_wait ADD CONSTRAINT fk_inv_event_wait_wh FOREIGN KEY (tenant_id, company_id, warehouse_id) REFERENCES mdm_warehouse (tenant_id, company_id, id);
ALTER TABLE inv_replenishment DROP CONSTRAINT fk_inv_replenishment_material;
ALTER TABLE inv_replenishment ADD CONSTRAINT fk_inv_replenishment_material FOREIGN KEY (tenant_id, company_id, material_id) REFERENCES mdm_material (tenant_id, company_id, id);
ALTER TABLE inv_replenishment DROP CONSTRAINT fk_inv_replenishment_wh;
ALTER TABLE inv_replenishment ADD CONSTRAINT fk_inv_replenishment_wh FOREIGN KEY (tenant_id, company_id, warehouse_id) REFERENCES mdm_warehouse (tenant_id, company_id, id);
ALTER TABLE inv_reservation_line DROP CONSTRAINT fk_inv_reservation_line_material;
ALTER TABLE inv_reservation_line ADD CONSTRAINT fk_inv_reservation_line_material FOREIGN KEY (tenant_id, company_id, material_id) REFERENCES mdm_material (tenant_id, company_id, id);
ALTER TABLE inv_reservation_line DROP CONSTRAINT fk_inv_reservation_line_wh;
ALTER TABLE inv_reservation_line ADD CONSTRAINT fk_inv_reservation_line_wh FOREIGN KEY (tenant_id, company_id, warehouse_id) REFERENCES mdm_warehouse (tenant_id, company_id, id);
ALTER TABLE inv_scan_log DROP CONSTRAINT fk_inv_scan_log_wh;
ALTER TABLE inv_scan_log ADD CONSTRAINT fk_inv_scan_log_wh FOREIGN KEY (tenant_id, company_id, warehouse_id) REFERENCES mdm_warehouse (tenant_id, company_id, id);
ALTER TABLE inv_serial DROP CONSTRAINT fk_inv_serial_customer;
ALTER TABLE inv_serial ADD CONSTRAINT fk_inv_serial_customer FOREIGN KEY (tenant_id, company_id, customer_id) REFERENCES mdm_customer (tenant_id, company_id, id);
ALTER TABLE inv_serial DROP CONSTRAINT fk_inv_serial_material;
ALTER TABLE inv_serial ADD CONSTRAINT fk_inv_serial_material FOREIGN KEY (tenant_id, company_id, material_id) REFERENCES mdm_material (tenant_id, company_id, id);
ALTER TABLE inv_serial_txn DROP CONSTRAINT fk_inv_serial_txn_wh;
ALTER TABLE inv_serial_txn ADD CONSTRAINT fk_inv_serial_txn_wh FOREIGN KEY (tenant_id, company_id, warehouse_id) REFERENCES mdm_warehouse (tenant_id, company_id, id);
ALTER TABLE inv_stock_summary DROP CONSTRAINT fk_inv_stock_summary_material;
ALTER TABLE inv_stock_summary ADD CONSTRAINT fk_inv_stock_summary_material FOREIGN KEY (tenant_id, company_id, material_id) REFERENCES mdm_material (tenant_id, company_id, id);
ALTER TABLE inv_stock_summary DROP CONSTRAINT fk_inv_stock_summary_wh;
ALTER TABLE inv_stock_summary ADD CONSTRAINT fk_inv_stock_summary_wh FOREIGN KEY (tenant_id, company_id, warehouse_id) REFERENCES mdm_warehouse (tenant_id, company_id, id);
ALTER TABLE inv_stocktake_line DROP CONSTRAINT fk_inv_stocktake_line_material;
ALTER TABLE inv_stocktake_line ADD CONSTRAINT fk_inv_stocktake_line_material FOREIGN KEY (tenant_id, company_id, material_id) REFERENCES mdm_material (tenant_id, company_id, id);
ALTER TABLE inv_stocktake_plan DROP CONSTRAINT fk_inv_stocktake_plan_wh;
ALTER TABLE inv_stocktake_plan ADD CONSTRAINT fk_inv_stocktake_plan_wh FOREIGN KEY (tenant_id, company_id, warehouse_id) REFERENCES mdm_warehouse (tenant_id, company_id, id);
ALTER TABLE inv_stocktake DROP CONSTRAINT fk_inv_stocktake_wh;
ALTER TABLE inv_stocktake ADD CONSTRAINT fk_inv_stocktake_wh FOREIGN KEY (tenant_id, company_id, warehouse_id) REFERENCES mdm_warehouse (tenant_id, company_id, id);
ALTER TABLE inv_transfer DROP CONSTRAINT fk_inv_transfer_from_factory;
ALTER TABLE inv_transfer ADD CONSTRAINT fk_inv_transfer_from_factory FOREIGN KEY (tenant_id, company_id, from_factory_id) REFERENCES mdm_factory (tenant_id, company_id, id);
ALTER TABLE inv_transfer DROP CONSTRAINT fk_inv_transfer_from_wh;
ALTER TABLE inv_transfer ADD CONSTRAINT fk_inv_transfer_from_wh FOREIGN KEY (tenant_id, company_id, from_warehouse_id) REFERENCES mdm_warehouse (tenant_id, company_id, id);
ALTER TABLE inv_transfer_line DROP CONSTRAINT fk_inv_transfer_line_material;
ALTER TABLE inv_transfer_line ADD CONSTRAINT fk_inv_transfer_line_material FOREIGN KEY (tenant_id, company_id, material_id) REFERENCES mdm_material (tenant_id, company_id, id);
ALTER TABLE inv_transfer DROP CONSTRAINT fk_inv_transfer_to_factory;
ALTER TABLE inv_transfer ADD CONSTRAINT fk_inv_transfer_to_factory FOREIGN KEY (tenant_id, company_id, to_factory_id) REFERENCES mdm_factory (tenant_id, company_id, id);
ALTER TABLE inv_transfer DROP CONSTRAINT fk_inv_transfer_to_wh;
ALTER TABLE inv_transfer ADD CONSTRAINT fk_inv_transfer_to_wh FOREIGN KEY (tenant_id, company_id, to_warehouse_id) REFERENCES mdm_warehouse (tenant_id, company_id, id);

-- 附带（蓝色大肥鱼 2026-10-21 指示）：sys_login_log.session_id 的含义改为 token 摘要，列类型 VARCHAR(100) 不变
COMMENT ON COLUMN sys_login_log.session_id IS 'トークンの SHA-256 16 進完全値（64 桁、成功時）。平文トークンは保存しない。Redis 上のセッションとの対応付け用で、認証情報として使用不可';
