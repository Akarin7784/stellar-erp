-- 清理 G2-18 桩表与草稿函数（G218ConcurrencyTest 提交后的数据用；pgTAP 文件靠 ROLLBACK，不需要）。
DROP VIEW IF EXISTS v_g2_18_line_completion_recon;
DO $$
DECLARE f regprocedure;
BEGIN
    FOR f IN SELECT p.oid::regprocedure FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
              WHERE n.nspname = 'public' AND p.proname LIKE 'g2\_18\_%' LOOP
        EXECUTE 'DROP FUNCTION ' || f;
    END LOOP;
END $$;
DROP TABLE IF EXISTS prd_overproduction_approval, prd_work_order, sal_sales_order_line, sal_sales_order;
DELETE FROM sys_audit_log WHERE tenant_id = 101 AND resource_code = 'sales-order-line';
DELETE FROM sys_param WHERE id BETWEEN 992000 AND 992099;
DELETE FROM mdm_material WHERE id BETWEEN 992000 AND 992099;
DELETE FROM mdm_uom WHERE id BETWEEN 992000 AND 992099;
DELETE FROM mdm_material_category WHERE id BETWEEN 992000 AND 992099;
