-- prd → mdm 跨域 FK 29 条改为三列 (tenant_id, company_id, x_id) → mdm_x (tenant_id, company_id, id)。
-- 04 §6.2 项 2a：被引用表有 company_id 时三列为标准形（DB 层拒绝引用同租户其他公司的主数据）。
-- 29 条全部在普通表上（prd 无分区表）；子表 company_id 均 NOT NULL，约束名不变，NO ACTION。
-- 被引用表 mdm_material / mdm_factory / mdm_warehouse / mdm_supplier 的 uk_*_tenant_company_id 均已存在（warehouse/supplier 由 inv/V202610211410 新增），本迁移不新增 UNIQUE。

-- 前置检查：已有数据中子表 company_id 与被引用行 company_id 不一致时中止（需人工处理，不自动修正）
DO $$
DECLARE r record; n bigint; bad text := '';
BEGIN
  FOR r IN SELECT * FROM (VALUES
    ('fk_prd_bom_factory', 'prd_bom', 'factory_id', 'mdm_factory'),
    ('fk_prd_bom_line_component', 'prd_bom_line', 'component_material_id', 'mdm_material'),
    ('fk_prd_bom_material', 'prd_bom', 'material_id', 'mdm_material'),
    ('fk_prd_bom_substitute_material', 'prd_bom_substitute', 'substitute_material_id', 'mdm_material'),
    ('fk_prd_completion_receipt_line_material', 'prd_completion_receipt_line', 'material_id', 'mdm_material'),
    ('fk_prd_completion_receipt_wh', 'prd_completion_receipt', 'warehouse_id', 'mdm_warehouse'),
    ('fk_prd_demand_forecast_material', 'prd_demand_forecast', 'material_id', 'mdm_material'),
    ('fk_prd_inspection_material', 'prd_inspection', 'material_id', 'mdm_material'),
    ('fk_prd_material_issue_wh', 'prd_material_issue', 'warehouse_id', 'mdm_warehouse'),
    ('fk_prd_material_planning_factory', 'prd_material_planning', 'factory_id', 'mdm_factory'),
    ('fk_prd_material_planning_material', 'prd_material_planning', 'material_id', 'mdm_material'),
    ('fk_prd_mps_factory', 'prd_mps', 'factory_id', 'mdm_factory'),
    ('fk_prd_mps_line_material', 'prd_mps_line', 'material_id', 'mdm_material'),
    ('fk_prd_mrp_run_factory', 'prd_mrp_run', 'factory_id', 'mdm_factory'),
    ('fk_prd_outsourcing_issue_line_material', 'prd_outsourcing_issue_line', 'material_id', 'mdm_material'),
    ('fk_prd_outsourcing_issue_wh', 'prd_outsourcing_issue', 'warehouse_id', 'mdm_warehouse'),
    ('fk_prd_outsourcing_order_factory', 'prd_outsourcing_order', 'factory_id', 'mdm_factory'),
    ('fk_prd_outsourcing_order_line_material', 'prd_outsourcing_order_line', 'material_id', 'mdm_material'),
    ('fk_prd_outsourcing_order_supplier', 'prd_outsourcing_order', 'supplier_id', 'mdm_supplier'),
    ('fk_prd_outsourcing_receipt_line_material', 'prd_outsourcing_receipt_line', 'material_id', 'mdm_material'),
    ('fk_prd_outsourcing_receipt_wh', 'prd_outsourcing_receipt', 'warehouse_id', 'mdm_warehouse'),
    ('fk_prd_outsourcing_settlement_line_material', 'prd_outsourcing_settlement_line', 'material_id', 'mdm_material'),
    ('fk_prd_outsourcing_settlement_supplier', 'prd_outsourcing_settlement', 'supplier_id', 'mdm_supplier'),
    ('fk_prd_routing_factory', 'prd_routing', 'factory_id', 'mdm_factory'),
    ('fk_prd_routing_material', 'prd_routing', 'material_id', 'mdm_material'),
    ('fk_prd_work_center_factory', 'prd_work_center', 'factory_id', 'mdm_factory'),
    ('fk_prd_work_order_factory', 'prd_work_order', 'factory_id', 'mdm_factory'),
    ('fk_prd_work_order_material', 'prd_work_order', 'material_id', 'mdm_material'),
    ('fk_prd_work_order_material_material', 'prd_work_order_material', 'material_id', 'mdm_material')
  ) v(con, child, col, parent) LOOP
    EXECUTE format('SELECT count(*) FROM %I c JOIN %I p ON p.tenant_id = c.tenant_id AND p.id = c.%I WHERE p.company_id <> c.company_id',
                   r.child, r.parent, r.col) INTO n;
    IF n > 0 THEN bad := bad || format('%s: %s 行; ', r.con, n); END IF;
  END LOOP;
  IF bad <> '' THEN RAISE EXCEPTION 'prd → mdm 跨公司引用数据存在，无法改为三列 FK：%', bad; END IF;
END $$;

ALTER TABLE prd_bom DROP CONSTRAINT fk_prd_bom_factory;
ALTER TABLE prd_bom ADD CONSTRAINT fk_prd_bom_factory FOREIGN KEY (tenant_id, company_id, factory_id) REFERENCES mdm_factory (tenant_id, company_id, id);
ALTER TABLE prd_bom_line DROP CONSTRAINT fk_prd_bom_line_component;
ALTER TABLE prd_bom_line ADD CONSTRAINT fk_prd_bom_line_component FOREIGN KEY (tenant_id, company_id, component_material_id) REFERENCES mdm_material (tenant_id, company_id, id);
ALTER TABLE prd_bom DROP CONSTRAINT fk_prd_bom_material;
ALTER TABLE prd_bom ADD CONSTRAINT fk_prd_bom_material FOREIGN KEY (tenant_id, company_id, material_id) REFERENCES mdm_material (tenant_id, company_id, id);
ALTER TABLE prd_bom_substitute DROP CONSTRAINT fk_prd_bom_substitute_material;
ALTER TABLE prd_bom_substitute ADD CONSTRAINT fk_prd_bom_substitute_material FOREIGN KEY (tenant_id, company_id, substitute_material_id) REFERENCES mdm_material (tenant_id, company_id, id);
ALTER TABLE prd_completion_receipt_line DROP CONSTRAINT fk_prd_completion_receipt_line_material;
ALTER TABLE prd_completion_receipt_line ADD CONSTRAINT fk_prd_completion_receipt_line_material FOREIGN KEY (tenant_id, company_id, material_id) REFERENCES mdm_material (tenant_id, company_id, id);
ALTER TABLE prd_completion_receipt DROP CONSTRAINT fk_prd_completion_receipt_wh;
ALTER TABLE prd_completion_receipt ADD CONSTRAINT fk_prd_completion_receipt_wh FOREIGN KEY (tenant_id, company_id, warehouse_id) REFERENCES mdm_warehouse (tenant_id, company_id, id);
ALTER TABLE prd_demand_forecast DROP CONSTRAINT fk_prd_demand_forecast_material;
ALTER TABLE prd_demand_forecast ADD CONSTRAINT fk_prd_demand_forecast_material FOREIGN KEY (tenant_id, company_id, material_id) REFERENCES mdm_material (tenant_id, company_id, id);
ALTER TABLE prd_inspection DROP CONSTRAINT fk_prd_inspection_material;
ALTER TABLE prd_inspection ADD CONSTRAINT fk_prd_inspection_material FOREIGN KEY (tenant_id, company_id, material_id) REFERENCES mdm_material (tenant_id, company_id, id);
ALTER TABLE prd_material_issue DROP CONSTRAINT fk_prd_material_issue_wh;
ALTER TABLE prd_material_issue ADD CONSTRAINT fk_prd_material_issue_wh FOREIGN KEY (tenant_id, company_id, warehouse_id) REFERENCES mdm_warehouse (tenant_id, company_id, id);
ALTER TABLE prd_material_planning DROP CONSTRAINT fk_prd_material_planning_factory;
ALTER TABLE prd_material_planning ADD CONSTRAINT fk_prd_material_planning_factory FOREIGN KEY (tenant_id, company_id, factory_id) REFERENCES mdm_factory (tenant_id, company_id, id);
ALTER TABLE prd_material_planning DROP CONSTRAINT fk_prd_material_planning_material;
ALTER TABLE prd_material_planning ADD CONSTRAINT fk_prd_material_planning_material FOREIGN KEY (tenant_id, company_id, material_id) REFERENCES mdm_material (tenant_id, company_id, id);
ALTER TABLE prd_mps DROP CONSTRAINT fk_prd_mps_factory;
ALTER TABLE prd_mps ADD CONSTRAINT fk_prd_mps_factory FOREIGN KEY (tenant_id, company_id, factory_id) REFERENCES mdm_factory (tenant_id, company_id, id);
ALTER TABLE prd_mps_line DROP CONSTRAINT fk_prd_mps_line_material;
ALTER TABLE prd_mps_line ADD CONSTRAINT fk_prd_mps_line_material FOREIGN KEY (tenant_id, company_id, material_id) REFERENCES mdm_material (tenant_id, company_id, id);
ALTER TABLE prd_mrp_run DROP CONSTRAINT fk_prd_mrp_run_factory;
ALTER TABLE prd_mrp_run ADD CONSTRAINT fk_prd_mrp_run_factory FOREIGN KEY (tenant_id, company_id, factory_id) REFERENCES mdm_factory (tenant_id, company_id, id);
ALTER TABLE prd_outsourcing_issue_line DROP CONSTRAINT fk_prd_outsourcing_issue_line_material;
ALTER TABLE prd_outsourcing_issue_line ADD CONSTRAINT fk_prd_outsourcing_issue_line_material FOREIGN KEY (tenant_id, company_id, material_id) REFERENCES mdm_material (tenant_id, company_id, id);
ALTER TABLE prd_outsourcing_issue DROP CONSTRAINT fk_prd_outsourcing_issue_wh;
ALTER TABLE prd_outsourcing_issue ADD CONSTRAINT fk_prd_outsourcing_issue_wh FOREIGN KEY (tenant_id, company_id, warehouse_id) REFERENCES mdm_warehouse (tenant_id, company_id, id);
ALTER TABLE prd_outsourcing_order DROP CONSTRAINT fk_prd_outsourcing_order_factory;
ALTER TABLE prd_outsourcing_order ADD CONSTRAINT fk_prd_outsourcing_order_factory FOREIGN KEY (tenant_id, company_id, factory_id) REFERENCES mdm_factory (tenant_id, company_id, id);
ALTER TABLE prd_outsourcing_order_line DROP CONSTRAINT fk_prd_outsourcing_order_line_material;
ALTER TABLE prd_outsourcing_order_line ADD CONSTRAINT fk_prd_outsourcing_order_line_material FOREIGN KEY (tenant_id, company_id, material_id) REFERENCES mdm_material (tenant_id, company_id, id);
ALTER TABLE prd_outsourcing_order DROP CONSTRAINT fk_prd_outsourcing_order_supplier;
ALTER TABLE prd_outsourcing_order ADD CONSTRAINT fk_prd_outsourcing_order_supplier FOREIGN KEY (tenant_id, company_id, supplier_id) REFERENCES mdm_supplier (tenant_id, company_id, id);
ALTER TABLE prd_outsourcing_receipt_line DROP CONSTRAINT fk_prd_outsourcing_receipt_line_material;
ALTER TABLE prd_outsourcing_receipt_line ADD CONSTRAINT fk_prd_outsourcing_receipt_line_material FOREIGN KEY (tenant_id, company_id, material_id) REFERENCES mdm_material (tenant_id, company_id, id);
ALTER TABLE prd_outsourcing_receipt DROP CONSTRAINT fk_prd_outsourcing_receipt_wh;
ALTER TABLE prd_outsourcing_receipt ADD CONSTRAINT fk_prd_outsourcing_receipt_wh FOREIGN KEY (tenant_id, company_id, warehouse_id) REFERENCES mdm_warehouse (tenant_id, company_id, id);
ALTER TABLE prd_outsourcing_settlement_line DROP CONSTRAINT fk_prd_outsourcing_settlement_line_material;
ALTER TABLE prd_outsourcing_settlement_line ADD CONSTRAINT fk_prd_outsourcing_settlement_line_material FOREIGN KEY (tenant_id, company_id, material_id) REFERENCES mdm_material (tenant_id, company_id, id);
ALTER TABLE prd_outsourcing_settlement DROP CONSTRAINT fk_prd_outsourcing_settlement_supplier;
ALTER TABLE prd_outsourcing_settlement ADD CONSTRAINT fk_prd_outsourcing_settlement_supplier FOREIGN KEY (tenant_id, company_id, supplier_id) REFERENCES mdm_supplier (tenant_id, company_id, id);
ALTER TABLE prd_routing DROP CONSTRAINT fk_prd_routing_factory;
ALTER TABLE prd_routing ADD CONSTRAINT fk_prd_routing_factory FOREIGN KEY (tenant_id, company_id, factory_id) REFERENCES mdm_factory (tenant_id, company_id, id);
ALTER TABLE prd_routing DROP CONSTRAINT fk_prd_routing_material;
ALTER TABLE prd_routing ADD CONSTRAINT fk_prd_routing_material FOREIGN KEY (tenant_id, company_id, material_id) REFERENCES mdm_material (tenant_id, company_id, id);
ALTER TABLE prd_work_center DROP CONSTRAINT fk_prd_work_center_factory;
ALTER TABLE prd_work_center ADD CONSTRAINT fk_prd_work_center_factory FOREIGN KEY (tenant_id, company_id, factory_id) REFERENCES mdm_factory (tenant_id, company_id, id);
ALTER TABLE prd_work_order DROP CONSTRAINT fk_prd_work_order_factory;
ALTER TABLE prd_work_order ADD CONSTRAINT fk_prd_work_order_factory FOREIGN KEY (tenant_id, company_id, factory_id) REFERENCES mdm_factory (tenant_id, company_id, id);
ALTER TABLE prd_work_order DROP CONSTRAINT fk_prd_work_order_material;
ALTER TABLE prd_work_order ADD CONSTRAINT fk_prd_work_order_material FOREIGN KEY (tenant_id, company_id, material_id) REFERENCES mdm_material (tenant_id, company_id, id);
ALTER TABLE prd_work_order_material DROP CONSTRAINT fk_prd_work_order_material_material;
ALTER TABLE prd_work_order_material ADD CONSTRAINT fk_prd_work_order_material_material FOREIGN KEY (tenant_id, company_id, material_id) REFERENCES mdm_material (tenant_id, company_id, id);

-- 三列 FK 子表侧索引：FK 列须有以 (tenant_id, company_id, x_id) 打头的 btree 索引（被引用行 DELETE/UPDATE 时的检查、按主数据检索）。
-- 29 条中 20 条已有覆盖索引（含 uk_/复合 idx_），以下 9 条缺失，本迁移补齐。
CREATE INDEX idx_prd_bom_factory ON prd_bom (tenant_id, company_id, factory_id);
CREATE INDEX idx_prd_completion_receipt_wh ON prd_completion_receipt (tenant_id, company_id, warehouse_id);
CREATE INDEX idx_prd_material_issue_wh ON prd_material_issue (tenant_id, company_id, warehouse_id);
CREATE INDEX idx_prd_material_planning_factory ON prd_material_planning (tenant_id, company_id, factory_id);
CREATE INDEX idx_prd_outsourcing_issue_wh ON prd_outsourcing_issue (tenant_id, company_id, warehouse_id);
CREATE INDEX idx_prd_outsourcing_order_factory ON prd_outsourcing_order (tenant_id, company_id, factory_id);
CREATE INDEX idx_prd_outsourcing_receipt_wh ON prd_outsourcing_receipt (tenant_id, company_id, warehouse_id);
CREATE INDEX idx_prd_outsourcing_settlement_line_material ON prd_outsourcing_settlement_line (tenant_id, company_id, material_id);
CREATE INDEX idx_prd_routing_factory ON prd_routing (tenant_id, company_id, factory_id);
