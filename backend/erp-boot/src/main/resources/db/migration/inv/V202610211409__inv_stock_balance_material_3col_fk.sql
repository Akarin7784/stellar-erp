-- inv_stock_balance.material_id 硬 FK 改为三列 (tenant_id, company_id, material_id) → mdm_material (tenant_id, company_id, id)。
-- 理由：库存余额为公司单位，禁止引用同租户其他公司的物料（DB 层拒绝跨公司）。按 04 §6.2 项 2a，被引用表有 company_id 时三列为标准形（非例外）。
-- inv_stock_balance 非分区表（分区表仅 inv_stock_txn），且 company_id NOT NULL。约束名保持 fk_inv_stock_balance_material，NO ACTION。
ALTER TABLE mdm_material ADD CONSTRAINT uk_mdm_material_tenant_company_id UNIQUE (tenant_id, company_id, id);
COMMENT ON CONSTRAINT uk_mdm_material_tenant_company_id ON mdm_material IS 'FK 参照先専用（fk_inv_stock_balance_material 三列）。業務一意キーではない';

ALTER TABLE inv_stock_balance DROP CONSTRAINT fk_inv_stock_balance_material;
ALTER TABLE inv_stock_balance ADD CONSTRAINT fk_inv_stock_balance_material
    FOREIGN KEY (tenant_id, company_id, material_id) REFERENCES mdm_material (tenant_id, company_id, id);
