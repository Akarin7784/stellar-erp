-- 07 财务：fin_period 会计期间（docs/design/07-finance/90-db-design.md §4.3），DDL 照设计书 + RLS
-- 规则：tenant_id DEFAULT current_setting('app.tenant_id')::bigint（禁 DEFAULT 0）；company_id NOT NULL 无 DEFAULT；
--       uk 以 (tenant_id, company_id) 打头；ENABLE + FORCE RLS；erp_app DML 由 V202610200101 DEFAULT PRIVILEGES 授予。
CREATE TABLE fin_period (
    id             BIGINT       NOT NULL,
    tenant_id      BIGINT       NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id     BIGINT       NOT NULL,
    fiscal_year    SMALLINT     NOT NULL,                 -- 2026
    period_code    VARCHAR(7)   NOT NULL,                 -- 2026-10
    period_no      SMALLINT     NOT NULL,                 -- 1～12
    start_date     DATE         NOT NULL,
    end_date       DATE         NOT NULL,
    status         VARCHAR(16)  NOT NULL DEFAULT 'FUTURE',-- FUTURE/OPEN/CLOSED/YEAR_CLOSED
    close_date     DATE,                                  -- 予定/実績結帳日
    closed_at      TIMESTAMPTZ,
    closed_by      BIGINT,
    reopen_reason  VARCHAR(500),
    version        INT          NOT NULL DEFAULT 0,
    created_at     TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_by     BIGINT       NOT NULL DEFAULT 0,
    updated_at     TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_by     BIGINT       NOT NULL DEFAULT 0,
    CONSTRAINT pk_fin_period PRIMARY KEY (id),
    CONSTRAINT uk_fin_period_code UNIQUE (tenant_id, company_id, period_code),
    CONSTRAINT ck_fin_period_status CHECK (status IN ('FUTURE','OPEN','CLOSED','YEAR_CLOSED'))
);
CREATE INDEX idx_fin_period_status ON fin_period (fiscal_year, status);
ALTER TABLE fin_period ENABLE ROW LEVEL SECURITY;
ALTER TABLE fin_period FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON fin_period
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
COMMENT ON TABLE fin_period IS '会计期间（期间状态机）';
COMMENT ON COLUMN fin_period.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN fin_period.company_id IS '公司 ID（无默认值）';
COMMENT ON COLUMN fin_period.status IS 'FUTURE/OPEN/CLOSED/YEAR_CLOSED';

-- fin_publish_standard_cost（owner erp_cost_publisher，V202610210703）的已关账期间校验需要读本表（#14 约定）
GRANT SELECT ON fin_period TO erp_cost_publisher;
