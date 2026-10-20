-- G2-18 测试桩表（仅测试用，不是迁移）。
-- T2（sal_sales_order / sal_sales_order_line）的迁移还没合入，这里只建 db/draft/g2_18_completion.sql 用到的列，
-- RLS 与正式表同一写法（ENABLE + FORCE，按 app.tenant_id）。
-- prd_work_order / prd_overproduction_approval 已由 prd/V202610210702 正式建表（PR #13），不再建桩。
-- 表由 owner 创建，erp_app 通过 V202610200101 的 ALTER DEFAULT PRIVILEGES 自动获得 DML 权限。
-- T2 合入后删除本文件，pgTAP 直接用正式表。
CREATE TABLE sal_sales_order (
    id          bigint PRIMARY KEY,
    tenant_id   bigint NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id  bigint NOT NULL,
    order_no    varchar(32) NOT NULL
);
CREATE TABLE sal_sales_order_line (
    id                bigint PRIMARY KEY,
    tenant_id         bigint NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    sales_order_id    bigint NOT NULL REFERENCES sal_sales_order(id),
    line_no           integer NOT NULL,
    material_id       bigint NOT NULL,
    base_qty          numeric(18,4) NOT NULL,
    shipped_base_qty  numeric(18,4) NOT NULL DEFAULT 0,
    over_receipt_rate numeric(5,4),
    allowed_qty       numeric(18,4),
    completed_qty     numeric(18,4) NOT NULL DEFAULT 0,
    line_status       smallint NOT NULL DEFAULT 20,
    version           integer NOT NULL DEFAULT 0,
    updated_at        timestamptz NOT NULL DEFAULT now(),
    updated_by        bigint NOT NULL DEFAULT 0,
    CONSTRAINT ck_sal_sales_order_line_completed CHECK (completed_qty >= 0 AND (allowed_qty IS NULL OR completed_qty <= allowed_qty))
);
DO $$
DECLARE t text;
BEGIN
    FOREACH t IN ARRAY ARRAY['sal_sales_order','sal_sales_order_line'] LOOP
        EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
        EXECUTE format('ALTER TABLE %I FORCE ROW LEVEL SECURITY', t);
        EXECUTE format($p$CREATE POLICY tenant_isolation ON %I
            USING (tenant_id = current_setting('app.tenant_id')::bigint)
            WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint)$p$, t);
    END LOOP;
END $$;
