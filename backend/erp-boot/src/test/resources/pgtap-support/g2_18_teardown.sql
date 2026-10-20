-- 清理 G2-18 草稿函数与测试数据（G218ConcurrencyTest 提交后的数据用；pgTAP 文件靠 ROLLBACK，不需要）。
DROP VIEW IF EXISTS v_g2_18_line_completion_recon;
DO $$
DECLARE f regprocedure;
BEGIN
    FOR f IN SELECT p.oid::regprocedure FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
              WHERE n.nspname = 'public' AND p.proname LIKE 'g2\_18\_%' LOOP
        EXECUTE 'DROP FUNCTION ' || f;
    END LOOP;
END $$;
-- prd_ / sal_ 都是正式表，只删测试数据，不 DROP（先删引用方）。
DELETE FROM prd_overproduction_approval WHERE id BETWEEN 992000 AND 992099;
DELETE FROM prd_work_order WHERE id BETWEEN 992100 AND 992199;
DELETE FROM sal_sales_order_line WHERE id BETWEEN 992000 AND 992099;
DELETE FROM sal_sales_order WHERE id BETWEEN 992000 AND 992099;
DELETE FROM mdm_customer WHERE id BETWEEN 992000 AND 992099;
DELETE FROM sys_audit_log WHERE tenant_id = 101 AND resource_code = 'sales-order-line';
DELETE FROM sys_param WHERE id BETWEEN 992000 AND 992099;
DELETE FROM mdm_factory WHERE id BETWEEN 992000 AND 992099;
DELETE FROM mdm_material WHERE id BETWEEN 992000 AND 992099;
DELETE FROM mdm_uom WHERE id BETWEEN 992000 AND 992099;
DELETE FROM mdm_material_category WHERE id BETWEEN 992000 AND 992099;
