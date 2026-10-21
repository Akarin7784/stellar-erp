-- 1. mdm_uom_conversion：同一 (租户, 公司, 换算组, from, to) 的有效期间不得重叠（未删除且启用 status = 1 的行；status SMALLINT DEFAULT 1，1有效/0停止，同 mdm 惯例）。
--    daterange(valid_from, valid_to, '[]')：两端均含；valid_to IS NULL 时上界为无穷大（一直有效）。
--    前提：fin/V202610210701 已建 btree_gist。命名沿用 ex_fin_standard_cost_period。不另建唯一键，不改 idx_mdm_uom_conversion_group。
ALTER TABLE mdm_uom_conversion ADD CONSTRAINT ex_mdm_uom_conversion_period EXCLUDE USING gist (
    tenant_id WITH =, company_id WITH =, conversion_group WITH =,
    from_uom_code WITH =, to_uom_code WITH =,
    daterange(valid_from, valid_to, '[]') WITH &&
) WHERE (deleted = FALSE AND status = 1);

-- 2. prd_work_order_material：所有物料行的 uom_code / required_qty 一律存基本单位（无例外）；
--    BOM 明细的原单位 / 原数量放 bom_uom_code / bom_qty，仅追溯用。精度与 required_qty（NUMERIC(18,4)）一致；手工行为 NULL。
ALTER TABLE prd_work_order_material
    ADD COLUMN bom_uom_code VARCHAR(16) NULL,
    ADD COLUMN bom_qty NUMERIC(18,4) NULL;
COMMENT ON COLUMN prd_work_order_material.bom_uom_code IS 'BOM 原单位，仅追溯用；计算以 uom_code（基本单位）为准；手工行为 NULL';
COMMENT ON COLUMN prd_work_order_material.bom_qty IS 'BOM 原数量（bom_uom_code 下），仅追溯用；计算以 required_qty（基本单位）为准；手工行为 NULL';
