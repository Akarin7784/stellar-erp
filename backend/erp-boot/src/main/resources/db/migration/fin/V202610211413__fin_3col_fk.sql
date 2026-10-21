-- fin → mdm 跨域 FK 1 条改为三列 (tenant_id, company_id, material_id) → mdm_material (tenant_id, company_id, id)。
-- 04 §6.2 项 2a：被引用表有 company_id 时三列为标准形（DB 层拒绝引用同租户其他公司的主数据）。
-- fin_standard_cost 为普通表（非分区）；company_id NOT NULL，约束名不变，NO ACTION。
-- 被引用表 mdm_material 的 uk_mdm_material_tenant_company_id 已存在，本迁移不新增 UNIQUE。

-- 前置检查：已有数据中子表 company_id 与被引用行 company_id 不一致时中止（需人工处理，不自动修正）
DO $$
DECLARE r record; n bigint; bad text := '';
BEGIN
  FOR r IN SELECT * FROM (VALUES
    ('fk_fin_standard_cost_material', 'fin_standard_cost', 'material_id', 'mdm_material')
  ) v(con, child, col, parent) LOOP
    EXECUTE format('SELECT count(*) FROM %I c JOIN %I p ON p.tenant_id = c.tenant_id AND p.id = c.%I WHERE p.company_id <> c.company_id',
                   r.child, r.parent, r.col) INTO n;
    IF n > 0 THEN bad := bad || format('%s: %s 行; ', r.con, n); END IF;
  END LOOP;
  IF bad <> '' THEN RAISE EXCEPTION 'fin → mdm 跨公司引用数据存在，无法改为三列 FK：%', bad; END IF;
END $$;

ALTER TABLE fin_standard_cost DROP CONSTRAINT fk_fin_standard_cost_material;
ALTER TABLE fin_standard_cost ADD CONSTRAINT fk_fin_standard_cost_material FOREIGN KEY (tenant_id, company_id, material_id) REFERENCES mdm_material (tenant_id, company_id, id);

-- 三列 FK 子表侧索引：已有 uk_fin_standard_cost_version (tenant_id, company_id, material_id, cost_version)、
-- idx_fin_standard_cost_lookup (tenant_id, company_id, material_id, …) 以 (tenant_id, company_id, material_id) 打头，不新增索引。
