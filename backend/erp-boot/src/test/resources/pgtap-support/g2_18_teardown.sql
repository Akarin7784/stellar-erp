-- 清理 G2-18 桩表、草稿函数与测试数据（G218ConcurrencyTest 提交后的数据用；pgTAP 文件靠 ROLLBACK，不需要）。
DROP VIEW IF EXISTS v_g2_18_line_completion_recon;
DO $$
DECLARE f regprocedure;
BEGIN
    FOR f IN SELECT p.oid::regprocedure FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
              WHERE n.nspname = 'public' AND p.proname LIKE 'g2\_18\_%' LOOP
        EXECUTE 'DROP FUNCTION ' || f;
    END LOOP;
END $$;
-- prd_ 是正式表（PR #13），只删测试数据，不 DROP；sal_ 仍是桩表。
DELETE FROM prd_overproduction_approval WHERE id BETWEEN 992000 AND 992099;
DELETE FROM prd_work_order WHERE id BETWEEN 992100 AND 992199;
DROP TABLE IF EXISTS sal_sales_order_line, sal_sales_order;
DELETE FROM sys_audit_log WHERE tenant_id = 101 AND resource_code = 'sales-order-line';
DELETE FROM sys_param WHERE id BETWEEN 992000 AND 992099;
DELETE FROM mdm_factory WHERE id BETWEEN 992000 AND 992099;
DELETE FROM mdm_material WHERE id BETWEEN 992000 AND 992099;
DELETE FROM mdm_uom WHERE id BETWEEN 992000 AND 992099;
DELETE FROM mdm_material_category WHERE id BETWEEN 992000 AND 992099;
