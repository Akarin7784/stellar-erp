-- 07 财务：fin_standard_cost（标准成本版本管理）与发布函数 fin_publish_standard_cost
-- 来源：docs/design/07-finance/90-db-design.md §6.12；权限设计 docs/design/02-mdm/90-db-design.md §4.1.2；
--       RLS 模板 docs/design/00-common/10-rls-and-db-roles.md
-- 前提：fin/V202610210701 已建 btree_gist 扩展（EXCLUDE 对 BIGINT 使用 =）。

CREATE TABLE fin_standard_cost (
    id                    BIGINT        NOT NULL,
    tenant_id             BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id            BIGINT        NOT NULL,
    material_id           BIGINT        NOT NULL,               -- mdm_material.id（产品/半成品）
    material_code         VARCHAR(64)   NOT NULL,               -- 快照
    cost_version          VARCHAR(16)   NOT NULL,               -- 版本（例 2026A）
    period_from           DATE          NOT NULL,               -- 适用开始期间（存月初日；画面/API 为 YYYY-MM）
    period_to             DATE,                                 -- 适用结束期间（月初日；NULL=无期限；后续版发布时自动截止）
    cost_method           SMALLINT      NOT NULL,               -- 1 品种法/2 分批法
    bom_id                BIGINT,
    routing_id            BIGINT,
    base_qty              NUMERIC(18,4) NOT NULL DEFAULT 1,
    std_labor_hours       NUMERIC(18,4) NOT NULL DEFAULT 0,
    std_labor_rate        NUMERIC(18,6) NOT NULL DEFAULT 0,
    std_overhead_rate     NUMERIC(18,6) NOT NULL DEFAULT 0,
    material_unit_cost    NUMERIC(18,6) NOT NULL DEFAULT 0,
    labor_unit_cost       NUMERIC(18,6) NOT NULL DEFAULT 0,
    overhead_unit_cost    NUMERIC(18,6) NOT NULL DEFAULT 0,
    outsourcing_unit_cost NUMERIC(18,6) NOT NULL DEFAULT 0,
    total_unit_cost       NUMERIC(18,6) NOT NULL,               -- 4 要素合计
    status                SMALLINT      NOT NULL DEFAULT 10,    -- 10 草稿/40 已发布/90 失效
    published_at          TIMESTAMPTZ,
    published_by          BIGINT,
    version               INT           NOT NULL DEFAULT 0,
    remark                VARCHAR(500),
    ext_data              JSONB,
    created_at            TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by            BIGINT        NOT NULL DEFAULT 0,
    updated_at            TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by            BIGINT        NOT NULL DEFAULT 0,
    CONSTRAINT pk_fin_standard_cost PRIMARY KEY (id),
    CONSTRAINT uk_fin_standard_cost_version UNIQUE (tenant_id, company_id, material_id, cost_version),
    CONSTRAINT fk_fin_standard_cost_material FOREIGN KEY (material_id) REFERENCES mdm_material (id),
    CONSTRAINT ck_fin_standard_cost_status CHECK (status IN (10,40,90)),
    CONSTRAINT ck_fin_standard_cost_method CHECK (cost_method IN (1,2)),
    CONSTRAINT ck_fin_standard_cost_period CHECK (EXTRACT(day FROM period_from) = 1
        AND (period_to IS NULL OR (EXTRACT(day FROM period_to) = 1 AND period_to >= period_from))),
    CONSTRAINT ck_fin_standard_cost_nonneg CHECK (material_unit_cost >= 0 AND labor_unit_cost >= 0 AND overhead_unit_cost >= 0 AND outsourcing_unit_cost >= 0 AND base_qty > 0),
    CONSTRAINT ck_fin_standard_cost_total CHECK (total_unit_cost = material_unit_cost + labor_unit_cost + overhead_unit_cost + outsourcing_unit_cost),
    -- 已发布版本的适用期间不得重叠（period_to NULL = 无上限）
    CONSTRAINT ex_fin_standard_cost_period EXCLUDE USING gist (
        tenant_id WITH =, company_id WITH =, material_id WITH =,
        daterange(period_from, (period_to + interval '1 month')::date, '[)') WITH &&
    ) WHERE (status = 40)
);
CREATE UNIQUE INDEX uk_fin_standard_cost_period ON fin_standard_cost (tenant_id, company_id, material_id, period_from) WHERE status = 40;
CREATE INDEX idx_fin_standard_cost_lookup ON fin_standard_cost (company_id, material_id, status, period_from DESC);

ALTER TABLE fin_standard_cost ENABLE ROW LEVEL SECURITY;
ALTER TABLE fin_standard_cost FORCE ROW LEVEL SECURITY;
CREATE POLICY rls_fin_standard_cost ON fin_standard_cost
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);

COMMENT ON TABLE fin_standard_cost IS '标准成本（物料×版本×适用期间，材料/人工/制造费用/委外）。唯一的正；mdm_material/prd_work_order 的 standard_cost 是快照';
COMMENT ON COLUMN fin_standard_cost.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN fin_standard_cost.period_from IS '适用开始期间（月初日，CHECK 日=1）';
COMMENT ON COLUMN fin_standard_cost.period_to IS '适用结束期间（月初日，NULL=无期限，后续版发布时自动截止）';
COMMENT ON COLUMN fin_standard_cost.status IS '10 草稿/40 已发布/90 失效';

-- 02-mdm V202610210202 预留的授权（已合迁移不改，在此启用）
GRANT SELECT ON fin_standard_cost TO erp_cost_publisher;
GRANT UPDATE (period_to, status, published_at, published_by, version, updated_at, updated_by)
    ON fin_standard_cost TO erp_cost_publisher;

-- 发布：§6.12 步骤 1~4。业务错误以 MESSAGE=错误码、ERRCODE P0001 抛出（应用层翻译为 HTTP + MSG-xxx）。
--   70134 MSG-FIN-134 发布期间不正（含 EXCLUDE 23P01 兜底）/ 70135 MSG-FIN-135 版本不是草稿
CREATE OR REPLACE FUNCTION public.fin_publish_standard_cost(p_id BIGINT, p_published_by BIGINT DEFAULT 0)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_tenant   BIGINT;
    v_new      fin_standard_cost%ROWTYPE;
    v_cur      fin_standard_cost%ROWTYPE;
    v_closed   BOOLEAN := FALSE;
    v_month    DATE;
BEGIN
    -- 租户：取调用方会话的 app.tenant_id 并在本事务内显式设定（FORCE RLS 对 owner 也生效）
    v_tenant := NULLIF(current_setting('app.tenant_id', true), '')::bigint;
    IF v_tenant IS NULL OR v_tenant = 0 THEN
        RAISE EXCEPTION '5000' USING ERRCODE = 'P0001', DETAIL = 'tenant context invalid (app.tenant_id)';
    END IF;
    PERFORM set_config('app.tenant_id', v_tenant::text, true);

    -- 取目标版（不加锁，仅为拿 company/material 去锁物料行）
    SELECT * INTO v_new FROM fin_standard_cost WHERE id = p_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION '4001' USING ERRCODE = 'P0001', DETAIL = 'fin_standard_cost not found: ' || p_id;
    END IF;

    -- 1. 先锁物料行，串行化同一物料的发布（不挡外键 FOR KEY SHARE）
    PERFORM 1 FROM mdm_material
     WHERE tenant_id = v_tenant AND company_id = v_new.company_id AND id = v_new.material_id
     FOR NO KEY UPDATE;

    -- 锁后重新取目标版与当前有效版
    SELECT * INTO v_new FROM fin_standard_cost WHERE id = p_id FOR UPDATE;
    IF v_new.status <> 10 THEN
        RAISE EXCEPTION '70135' USING ERRCODE = 'P0001', DETAIL = 'standard cost version is not draft';
    END IF;

    SELECT * INTO v_cur FROM fin_standard_cost
     WHERE tenant_id = v_tenant AND company_id = v_new.company_id
       AND material_id = v_new.material_id AND status = 40
     ORDER BY period_from DESC
     LIMIT 1
     FOR UPDATE;

    -- 2. 期间校验
    IF v_cur.id IS NOT NULL AND v_new.period_from <= v_cur.period_from THEN
        RAISE EXCEPTION '70134' USING ERRCODE = 'P0001', DETAIL = 'period_from must be later than current version';
    END IF;
    -- 已关账期间：fin_period 尚未建表时跳过（后续建 fin_period 的迁移须 GRANT SELECT 给 erp_cost_publisher）
    IF to_regclass('public.fin_period') IS NOT NULL THEN
        EXECUTE 'SELECT EXISTS (SELECT 1 FROM fin_period WHERE tenant_id = $1 AND company_id = $2
                   AND start_date <= $3 AND end_date >= $3 AND status IN (''CLOSED'',''YEAR_CLOSED''))'
           INTO v_closed USING v_tenant, v_new.company_id, v_new.period_from;
        IF v_closed THEN
            RAISE EXCEPTION '70134' USING ERRCODE = 'P0001', DETAIL = 'period_from falls in closed period';
        END IF;
    END IF;

    -- 3. 先截止旧版，再发布新版（EXCLUDE 非 DEFERRABLE）
    BEGIN
        IF v_cur.id IS NOT NULL THEN
            UPDATE fin_standard_cost
               SET period_to = (v_new.period_from - interval '1 month')::date,
                   version = version + 1, updated_at = now(), updated_by = COALESCE(p_published_by, 0)
             WHERE id = v_cur.id;
        END IF;
        UPDATE fin_standard_cost
           SET status = 40, published_at = now(), published_by = p_published_by,
               version = version + 1, updated_at = now(), updated_by = COALESCE(p_published_by, 0)
         WHERE id = p_id;
    EXCEPTION
        WHEN exclusion_violation THEN
            RAISE EXCEPTION '70134' USING ERRCODE = 'P0001', DETAIL = SQLERRM;
    END;

    -- 4. 快照写入 mdm_material.standard_cost（触发器仅放行 current_user = erp_cost_publisher）。
    --    仅当新版生效期间覆盖当月时写入；未来月生效的版本由期间开账（BAT-FIN-001）刷新。
    --    「当月」：fin_period 建表前一律取发布当天所在月（current_date 的月初）；
    --    建 fin_period 后改按 OPEN 期间判断（另开 PR）。新版 period_to 此时必为 NULL。
    v_month := date_trunc('month', current_date)::date;
    IF v_new.period_from <= v_month AND (v_new.period_to IS NULL OR v_new.period_to >= v_month) THEN
        UPDATE mdm_material
           SET standard_cost = v_new.total_unit_cost
         WHERE tenant_id = v_tenant AND company_id = v_new.company_id AND id = v_new.material_id;
    END IF;
END;
$$;

ALTER FUNCTION public.fin_publish_standard_cost(BIGINT, BIGINT) OWNER TO erp_cost_publisher;
REVOKE ALL ON FUNCTION public.fin_publish_standard_cost(BIGINT, BIGINT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.fin_publish_standard_cost(BIGINT, BIGINT) TO erp_app;
COMMENT ON FUNCTION public.fin_publish_standard_cost(BIGINT, BIGINT) IS
    '标准成本发布（07-finance §6.12）：锁物料行→截止上一版→发布→写 mdm_material.standard_cost 快照';

-- erp_app：去掉表级 UPDATE（含 DEFAULT PRIVILEGES 带来的授权），按列授回草稿可编辑列（不含 id/tenant_id/created_*/published_*）
REVOKE UPDATE ON fin_standard_cost FROM erp_app;
GRANT UPDATE (
        company_id, material_id, material_code, cost_version, period_from, period_to, cost_method,
        bom_id, routing_id, base_qty, std_labor_hours, std_labor_rate, std_overhead_rate,
        material_unit_cost, labor_unit_cost, overhead_unit_cost, outsourcing_unit_cost, total_unit_cost,
        status, version, remark, ext_data, updated_at, updated_by
) ON fin_standard_cost TO erp_app;

-- 发布保护：非 erp_cost_publisher 不得以 status=40 INSERT/UPDATE，也不得修改已发布行（只认 current_user）
CREATE OR REPLACE FUNCTION public.trg_fin_standard_cost_protect_publish()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF current_user IS DISTINCT FROM 'erp_cost_publisher'
       AND (NEW.status = 40 OR (TG_OP = 'UPDATE' AND OLD.status = 40)) THEN
        RAISE EXCEPTION '70135' USING ERRCODE = 'P0001',
            DETAIL = 'fin_standard_cost 的发布/已发布行仅允许经 fin_publish_standard_cost 修改';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_fin_standard_cost_protect_publish
    BEFORE INSERT OR UPDATE ON fin_standard_cost
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_fin_standard_cost_protect_publish();

COMMENT ON FUNCTION public.trg_fin_standard_cost_protect_publish() IS
    '禁止非 erp_cost_publisher 发布（status=40）或修改已发布的 fin_standard_cost';
