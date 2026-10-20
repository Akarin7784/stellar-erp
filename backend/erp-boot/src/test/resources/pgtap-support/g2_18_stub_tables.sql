-- G2-18 测试桩表（仅测试用，不是迁移）。
-- T2（sal_sales_order / sal_sales_order_line）、T3（prd_work_order）、#58（prd_overproduction_approval）
-- 的迁移还没合入，这里只建 db/draft/g2_18_completion.sql 用到的列，RLS 与正式表同一写法（ENABLE + FORCE，按 app.tenant_id）。
-- 表由 owner 创建，erp_app 通过 V202610200101 的 ALTER DEFAULT PRIVILEGES 自动获得 DML 权限。
-- T2/T3 合入后删除本文件，pgTAP 直接用正式表。
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
CREATE TABLE prd_work_order (
    id                  bigint PRIMARY KEY,
    tenant_id           bigint NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          bigint NOT NULL,
    sales_order_line_id bigint REFERENCES sal_sales_order_line(id),
    material_id         bigint NOT NULL,
    order_status        smallint NOT NULL DEFAULT 30,
    is_hold             boolean NOT NULL DEFAULT false,
    order_qty           numeric(18,4) NOT NULL,
    completed_qty       numeric(18,4) NOT NULL DEFAULT 0,
    allowed_qty         numeric(18,4),
    over_receipt_rate   numeric(5,4),
    version             integer NOT NULL DEFAULT 0,
    updated_at          timestamptz NOT NULL DEFAULT now(),
    updated_by          bigint NOT NULL DEFAULT 0,
    CONSTRAINT ck_prd_work_order_completed CHECK (completed_qty >= 0)
);
CREATE TABLE prd_overproduction_approval (
    id                   bigint PRIMARY KEY,
    tenant_id            bigint NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id           bigint NOT NULL,
    approval_no          varchar(32) NOT NULL,
    sales_order_line_id  bigint NOT NULL REFERENCES sal_sales_order_line(id),
    work_order_id        bigint REFERENCES prd_work_order(id),
    material_id          bigint NOT NULL,
    request_qty          numeric(18,4),
    approved_allowed_qty numeric(18,4),
    approval_status      smallint NOT NULL DEFAULT 10,
    approved_by          bigint,
    approved_at          timestamptz,
    version              integer NOT NULL DEFAULT 0,
    updated_at           timestamptz NOT NULL DEFAULT now(),
    updated_by           bigint NOT NULL DEFAULT 0,
    CONSTRAINT ck_prd_overproduction_approval_qty CHECK (request_qty > 0)   -- 90-db-design.md:1085
);
DO $$
DECLARE t text;
BEGIN
    FOREACH t IN ARRAY ARRAY['sal_sales_order','sal_sales_order_line','prd_work_order','prd_overproduction_approval'] LOOP
        EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
        EXECUTE format('ALTER TABLE %I FORCE ROW LEVEL SECURITY', t);
        EXECUTE format($p$CREATE POLICY tenant_isolation ON %I
            USING (tenant_id = current_setting('app.tenant_id')::bigint)
            WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint)$p$, t);
    END LOOP;
END $$;
