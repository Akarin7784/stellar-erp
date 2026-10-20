-- pgTAP：过入荷容差列改名为 _rate、比率 CHECK、erp_app 列级 UPDATE 随列保留
BEGIN;
SELECT plan(10);
SELECT has_column('mdm_material', 'over_receipt_tolerance_rate', 'mdm_material 有 _rate 列');
SELECT has_column('mdm_material_category', 'over_receipt_tolerance_rate', 'mdm_material_category 有 _rate 列');
SELECT has_column('mdm_supplier', 'over_receipt_tolerance_rate', 'mdm_supplier 有 _rate 列');
SELECT hasnt_column('mdm_material', 'over_receipt_tolerance_pct', 'mdm_material 旧 _pct 列已不存在');
SELECT hasnt_column('mdm_material_category', 'over_receipt_tolerance_pct', 'mdm_material_category 旧列已不存在');
SELECT hasnt_column('mdm_supplier', 'over_receipt_tolerance_pct', 'mdm_supplier 旧列已不存在');
SELECT col_type_is('mdm_material', 'over_receipt_tolerance_rate', 'numeric(5,4)', '类型仍为 NUMERIC(5,4)');
SELECT ok(has_column_privilege('erp_app', 'mdm_material', 'over_receipt_tolerance_rate', 'UPDATE'),
          'erp_app 在改名后的列上仍有 UPDATE');
SELECT ok(NOT has_column_privilege('erp_app', 'mdm_material', 'standard_cost', 'UPDATE'),
          'erp_app 仍不能 UPDATE standard_cost');
SELECT col_has_check('mdm_supplier', 'over_receipt_tolerance_rate', 'mdm_supplier 有比率 CHECK');
SELECT * FROM finish();
ROLLBACK;
