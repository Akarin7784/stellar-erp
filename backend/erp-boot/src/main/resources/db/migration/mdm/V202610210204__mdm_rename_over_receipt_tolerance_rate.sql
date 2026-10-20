-- 过入荷容差列改名：over_receipt_tolerance_pct → over_receipt_tolerance_rate（与 04-purchase receiving_tolerance_rate 口径一致，比率 0.05=5%）
-- 已合并迁移（V202610210201/0203/0202）不改，避免 Flyway checksum 失败。
-- 列级权限按 attnum 绑定，RENAME 后 erp_app 在 mdm_material 上的列级 UPDATE 自动随列保留，无需重新授权（pgTAP 校验）。

-- 1) 先确认现有值都按比率存（0〜1）；有越界值直接失败，不做静默修正
DO $$
DECLARE v_bad bigint;
BEGIN
    SELECT (SELECT count(*) FROM mdm_material          WHERE over_receipt_tolerance_pct NOT BETWEEN 0 AND 1)
         + (SELECT count(*) FROM mdm_material_category WHERE over_receipt_tolerance_pct NOT BETWEEN 0 AND 1)
         + (SELECT count(*) FROM mdm_supplier          WHERE over_receipt_tolerance_pct NOT BETWEEN 0 AND 1)
      INTO v_bad;
    IF v_bad > 0 THEN
        RAISE EXCEPTION 'over_receipt_tolerance_pct 存在 % 行不在 0〜1（疑似按百分数存），请先修正数据', v_bad;
    END IF;
END $$;

-- 2) 改名
ALTER TABLE mdm_material          RENAME COLUMN over_receipt_tolerance_pct TO over_receipt_tolerance_rate;
ALTER TABLE mdm_material_category RENAME COLUMN over_receipt_tolerance_pct TO over_receipt_tolerance_rate;
ALTER TABLE mdm_supplier          RENAME COLUMN over_receipt_tolerance_pct TO over_receipt_tolerance_rate;

-- 3) 以后只允许比率：NULL=继承下一级，0=明确 0%
ALTER TABLE mdm_material          ADD CONSTRAINT ck_mdm_material_over_receipt_tolerance_rate
    CHECK (over_receipt_tolerance_rate IS NULL OR over_receipt_tolerance_rate BETWEEN 0 AND 1);
ALTER TABLE mdm_material_category ADD CONSTRAINT ck_mdm_material_category_over_receipt_tolerance_rate
    CHECK (over_receipt_tolerance_rate IS NULL OR over_receipt_tolerance_rate BETWEEN 0 AND 1);
ALTER TABLE mdm_supplier          ADD CONSTRAINT ck_mdm_supplier_over_receipt_tolerance_rate
    CHECK (over_receipt_tolerance_rate IS NULL OR over_receipt_tolerance_rate BETWEEN 0 AND 1);
