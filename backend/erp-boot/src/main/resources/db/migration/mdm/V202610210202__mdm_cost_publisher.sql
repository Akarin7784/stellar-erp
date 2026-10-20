-- T1：标准成本快照列保护（docs/design/02-mdm/90-db-design.md §4.1.2）
-- - 角色 erp_cost_publisher（NOLOGIN）
-- - 列级 UPDATE(standard_cost) + SELECT(id/tenant_id/company_id)
-- - 触发器仅允许 current_user = 'erp_cost_publisher' 修改 standard_cost
-- - erp_app：REVOKE 表级 UPDATE 后逐列 GRANT（不含 standard_cost）
-- - 不建 fin_standard_cost / fin_publish_standard_cost（留给 07-finance）
-- - 对未来 fin_standard_cost 的 SELECT 待 07-finance 建表后再 GRANT（此处注释预留）

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'erp_cost_publisher') THEN
        CREATE ROLE erp_cost_publisher NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE
            NOBYPASSRLS NOREPLICATION INHERIT;
    END IF;
END
$$;

GRANT USAGE ON SCHEMA public TO erp_cost_publisher;

-- 列级权限（WHERE / RLS 需要可读 id、tenant_id、company_id；standard_cost 便于发布后回读）
GRANT SELECT (id, tenant_id, company_id, standard_cost) ON mdm_material TO erp_cost_publisher;
GRANT UPDATE (standard_cost) ON mdm_material TO erp_cost_publisher;
-- GRANT SELECT ON fin_standard_cost TO erp_cost_publisher;  -- 07-finance 建表后启用

CREATE OR REPLACE FUNCTION public.trg_mdm_material_protect_standard_cost()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.standard_cost IS DISTINCT FROM OLD.standard_cost
       AND current_user IS DISTINCT FROM 'erp_cost_publisher' THEN
        RAISE EXCEPTION 'mdm_material.standard_cost 仅允许 erp_cost_publisher 更新'
            USING ERRCODE = '42501';
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_mdm_material_protect_standard_cost ON mdm_material;
CREATE TRIGGER trg_mdm_material_protect_standard_cost
    BEFORE UPDATE ON mdm_material
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_mdm_material_protect_standard_cost();

COMMENT ON FUNCTION public.trg_mdm_material_protect_standard_cost() IS
    '禁止非 erp_cost_publisher 修改 mdm_material.standard_cost';

-- erp_app：去掉表级 UPDATE（含 ALTER DEFAULT PRIVILEGES 带来的授权），再逐列授回（不含 standard_cost）
REVOKE UPDATE ON mdm_material FROM erp_app;
GRANT UPDATE (
        id,
        tenant_id,
        company_id,
        material_code,
        material_name,
        material_short_name,
        material_type,
        category_id,
        spec,
        material_grade,
        drawing_no,
        standard_code,
        brand,
        product_series,
        unit_weight,
        gross_weight,
        volume,
        origin_country_code,
        base_uom_code,
        is_key_material,
        is_customer_supplied,
        is_consumable,
        purchase_uom_code,
        purchase_conversion_rate,
        purchase_lead_time_days,
        min_order_qty,
        order_multiple,
        default_supplier_id,
        supplier_material_no,
        purchase_tax_code,
        over_receipt_tolerance_pct,
        buyer_id,
        is_purchase_stopped,
        sales_uom_code,
        sales_conversion_rate,
        sales_tax_code,
        sales_price_group_code,
        min_sales_qty,
        sales_lead_time_days,
        return_limit_days,
        is_sales_stopped,
        ship_over_rate,
        default_warehouse_id,
        default_bin_id,
        is_batch_managed,
        batch_rule_code,
        is_serial_managed,
        serial_rule_code,
        shelf_life_days,
        expiry_warning_days,
        safety_stock_qty,
        reorder_point_qty,
        max_stock_qty,
        abc_class,
        cycle_count_cycle,
        storage_condition,
        is_negative_stock_allowed,
        is_hazardous,
        is_manufactured,
        is_outsourced,
        bom_required_flag,
        default_bom_code,
        default_routing_code,
        is_backflush,
        backflush_warehouse_id,
        default_work_center_id,
        yield_rate,
        mrp_type,
        planning_policy,
        manufacturing_lead_time_days,
        completion_over_rate,
        inventory_account_code,
        revenue_account_code,
        cogs_account_code,
        cost_category,
        cost_method,
        valuation_method,
        standard_price,
        tax_classification_code,
        inspection_stage,
        inspection_standard_id,
        certificate_required,
        quality_grade,
        status,
        approval_status,
        submitted_at,
        approved_at,
        approved_by,
        effective_at,
        deactivate_reason,
        created_at,
        created_by,
        updated_at,
        updated_by,
        version,
        deleted,
        remark,
        ext_data
) ON mdm_material TO erp_app;

-- 本表不再依赖「表级 UPDATE」的 DEFAULT PRIVILEGES；新建同名表时仍会走默认授权，
-- 但 mdm_material 已显式 REVOKE + 列级 GRANT，后续迁移勿再 GRANT UPDATE ON mdm_material TO erp_app。
