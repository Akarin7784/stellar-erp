-- T1 系统域最小集：公司 / 租户 / 系统参数 / 采番 + sys_init_tenant
-- 来源：docs/design/01-system/90-db-design.md §3.1 / §3.3 / §3.15 / §3.17
-- 唯一索引以 tenant_id 打头（docs/design/00-common/04-common-db-spec.md §6.1）
-- sys_user 已由 V1__baseline + sys/V202610200102 建好，本脚本不重建

CREATE TABLE sys_company (
    id              BIGINT       NOT NULL,
    tenant_id       BIGINT       NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id      BIGINT       NOT NULL,
    version         INT          NOT NULL DEFAULT 0,
    deleted         BOOLEAN      NOT NULL DEFAULT FALSE,
    remark          VARCHAR(500) NULL,
    ext_data        JSONB        NULL,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_by      BIGINT       NOT NULL DEFAULT 0,
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_by      BIGINT       NOT NULL DEFAULT 0,
    company_code            VARCHAR(32)   NOT NULL,        -- 公司代码
    company_name            VARCHAR(200)  NOT NULL,        -- 公司名称（中文全称）
    company_name_en         VARCHAR(200),                  -- 公司英文名称
    short_name              VARCHAR(100),                  -- 公司简称
    unified_social_credit_code VARCHAR(18),               -- 统一社会信用代码（GB 32100-2015，18 位）
    tax_no                  VARCHAR(30),                   -- 纳税人识别号
    tax_payer_type          SMALLINT      NOT NULL DEFAULT 1, -- 纳税人类型：1 一般纳税人 / 2 小规模纳税人
    legal_representative    VARCHAR(50),                   -- 法定代表人
    province_code           VARCHAR(6),                    -- 省级行政区划代码（GB/T 2260，例 320000）
    city_code               VARCHAR(6),                    -- 市级行政区划代码（例 320400）
    address                 VARCHAR(300),                  -- 注册地址
    postal_code             VARCHAR(10),                   -- 邮政编码
    phone                   VARCHAR(30),                   -- 联系电话
    email                   VARCHAR(100),                  -- 邮箱
    invoice_title           VARCHAR(200),                  -- 发票抬头
    bank_account_name       VARCHAR(200),                  -- 开户名称（发票/收付款用）
    fiscal_year_start_month SMALLINT      NOT NULL DEFAULT 1, -- 会计年度起始月（中国=1）
    base_currency_code      VARCHAR(3)    NOT NULL DEFAULT 'CNY', -- 记账本位币（ISO 4217）
    logo_attachment_id      BIGINT,                        -- 公司 LOGO 附件 ID（sys_attachment.id）
    status                  SMALLINT      NOT NULL DEFAULT 1, -- 状态：1 有效 / 0 无效
    sort_no                 INT           NOT NULL DEFAULT 0, -- 表示顺
    CONSTRAINT pk_sys_company PRIMARY KEY (id)
);

CREATE UNIQUE INDEX uk_sys_company_code ON sys_company (tenant_id, company_code) WHERE deleted = FALSE;
CREATE UNIQUE INDEX uk_sys_company_credit ON sys_company (tenant_id, unified_social_credit_code)
    WHERE deleted = FALSE AND unified_social_credit_code IS NOT NULL;


ALTER TABLE sys_company ENABLE ROW LEVEL SECURITY;
ALTER TABLE sys_company FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sys_company
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);

COMMENT ON TABLE sys_company IS '公司（会计主体）';
COMMENT ON COLUMN sys_company.company_code IS '公司代码';
COMMENT ON COLUMN sys_company.company_name IS '公司名称（中文全称）';
COMMENT ON COLUMN sys_company.company_name_en IS '公司英文名称';
COMMENT ON COLUMN sys_company.short_name IS '公司简称';
COMMENT ON COLUMN sys_company.unified_social_credit_code IS '统一社会信用代码（GB 32100-2015，18 位）';
COMMENT ON COLUMN sys_company.tax_no IS '纳税人识别号';
COMMENT ON COLUMN sys_company.tax_payer_type IS '纳税人类型：1 一般纳税人 / 2 小规模纳税人';
COMMENT ON COLUMN sys_company.legal_representative IS '法定代表人';
COMMENT ON COLUMN sys_company.province_code IS '省级行政区划代码（GB/T 2260，例 320000）';
COMMENT ON COLUMN sys_company.city_code IS '市级行政区划代码（例 320400）';
COMMENT ON COLUMN sys_company.address IS '注册地址';
COMMENT ON COLUMN sys_company.postal_code IS '邮政编码';
COMMENT ON COLUMN sys_company.phone IS '联系电话';
COMMENT ON COLUMN sys_company.email IS '邮箱';
COMMENT ON COLUMN sys_company.invoice_title IS '发票抬头';
COMMENT ON COLUMN sys_company.bank_account_name IS '开户名称（发票/收付款用）';
COMMENT ON COLUMN sys_company.fiscal_year_start_month IS '会计年度起始月（中国=1）';
COMMENT ON COLUMN sys_company.base_currency_code IS '记账本位币（ISO 4217）';
COMMENT ON COLUMN sys_company.logo_attachment_id IS '公司 LOGO 附件 ID（sys_attachment.id）';
COMMENT ON COLUMN sys_company.status IS '状态：1 有效 / 0 无效';
COMMENT ON COLUMN sys_company.sort_no IS '表示顺';
COMMENT ON COLUMN sys_company.id IS '雪花 ID（主键）';
COMMENT ON COLUMN sys_company.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN sys_company.company_id IS '公司 ID';
COMMENT ON COLUMN sys_company.created_at IS '创建时间';
COMMENT ON COLUMN sys_company.created_by IS '创建人';
COMMENT ON COLUMN sys_company.updated_at IS '更新时间';
COMMENT ON COLUMN sys_company.updated_by IS '更新人';
COMMENT ON COLUMN sys_company.version IS '乐观锁版本';
COMMENT ON COLUMN sys_company.deleted IS '逻辑删除';
COMMENT ON COLUMN sys_company.remark IS '备注';
COMMENT ON COLUMN sys_company.ext_data IS '扩展字段';

CREATE TABLE sys_tenant (
    id              BIGINT       NOT NULL,
    tenant_id       BIGINT       NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    version         INT          NOT NULL DEFAULT 0,
    deleted         BOOLEAN      NOT NULL DEFAULT FALSE,
    remark          VARCHAR(500) NULL,
    ext_data        JSONB        NULL,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_by      BIGINT       NOT NULL DEFAULT 0,
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_by      BIGINT       NOT NULL DEFAULT 0,
    tenant_code         VARCHAR(32)   NOT NULL,           -- 租户代码
    tenant_name         VARCHAR(200)  NOT NULL,           -- 租户名称
    contact_name        VARCHAR(50),                      -- 联系人
    contact_phone       VARCHAR(30),                      -- 联系电话
    max_user_count      INT           NOT NULL DEFAULT 0, -- 最大用户数（0=無制限）
    expire_date         DATE,                             -- 契約満了日
    status              SMALLINT      NOT NULL DEFAULT 1, -- 状态：1 有效 / 0 无效
    CONSTRAINT pk_sys_tenant PRIMARY KEY (id)
);

CREATE UNIQUE INDEX uk_sys_tenant_code ON sys_tenant (tenant_id, tenant_code) WHERE deleted = FALSE;


ALTER TABLE sys_tenant ENABLE ROW LEVEL SECURITY;
ALTER TABLE sys_tenant FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sys_tenant
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);

COMMENT ON TABLE sys_tenant IS '租户（多租户契约单位）';
COMMENT ON COLUMN sys_tenant.tenant_code IS '租户代码';
COMMENT ON COLUMN sys_tenant.tenant_name IS '租户名称';
COMMENT ON COLUMN sys_tenant.contact_name IS '联系人';
COMMENT ON COLUMN sys_tenant.contact_phone IS '联系电话';
COMMENT ON COLUMN sys_tenant.max_user_count IS '最大用户数（0=無制限）';
COMMENT ON COLUMN sys_tenant.expire_date IS '契約満了日';
COMMENT ON COLUMN sys_tenant.status IS '状态：1 有效 / 0 无效';
COMMENT ON COLUMN sys_tenant.id IS '雪花 ID（主键）';
COMMENT ON COLUMN sys_tenant.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN sys_tenant.created_at IS '创建时间';
COMMENT ON COLUMN sys_tenant.created_by IS '创建人';
COMMENT ON COLUMN sys_tenant.updated_at IS '更新时间';
COMMENT ON COLUMN sys_tenant.updated_by IS '更新人';
COMMENT ON COLUMN sys_tenant.version IS '乐观锁版本';
COMMENT ON COLUMN sys_tenant.deleted IS '逻辑删除';
COMMENT ON COLUMN sys_tenant.remark IS '备注';
COMMENT ON COLUMN sys_tenant.ext_data IS '扩展字段';

CREATE TABLE sys_param (
    id              BIGINT       NOT NULL,
    tenant_id       BIGINT       NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id      BIGINT       NOT NULL,
    version         INT          NOT NULL DEFAULT 0,
    deleted         BOOLEAN      NOT NULL DEFAULT FALSE,
    remark          VARCHAR(500) NULL,
    ext_data        JSONB        NULL,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_by      BIGINT       NOT NULL DEFAULT 0,
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_by      BIGINT       NOT NULL DEFAULT 0,
    param_key           VARCHAR(100)  NOT NULL,           -- 参数键（一意、group.key 形式）
    param_name          VARCHAR(100)  NOT NULL,           -- 参数名称
    param_group         VARCHAR(64)   NOT NULL,           -- 分组（auth/file/notify/workflow/report/…）
    param_value         TEXT,                             -- 参数值（加密対象は AES-256 暗号文）
    default_value       TEXT,                             -- 默认值
    value_type          SMALLINT      NOT NULL DEFAULT 1, -- 类型：1 字符串 / 2 整数 / 3 小数 / 4 布尔 / 5 JSON / 6 日期
    value_range         VARCHAR(500),                     -- 值域（例 1-100、a,b,c、正则）
    is_encrypted        BOOLEAN       NOT NULL DEFAULT FALSE, -- 是否加密保存
    is_danger           BOOLEAN       NOT NULL DEFAULT FALSE, -- 高危参数（変更時复核必須）
    is_readonly         BOOLEAN       NOT NULL DEFAULT FALSE, -- 只读（システム固定）
    effective_scope     SMALLINT      NOT NULL DEFAULT 1, -- 有効範囲：1 全社 / 2 工厂 / 3 用户
    sort_no             INT           NOT NULL DEFAULT 0, -- 表示顺
    description         VARCHAR(500),                     -- 说明
    status              SMALLINT      NOT NULL DEFAULT 1, -- 状态：1 有效 / 0 无效
    CONSTRAINT pk_sys_param PRIMARY KEY (id)
);

-- 会社既定参数：唯一键含 company_id；租户级默认使用 company_id = 0
CREATE UNIQUE INDEX uk_sys_param_key ON sys_param (tenant_id, company_id, param_key) WHERE deleted = FALSE;
CREATE INDEX idx_sys_param_group ON sys_param (tenant_id, company_id, param_group, sort_no);


ALTER TABLE sys_param ENABLE ROW LEVEL SECURITY;
ALTER TABLE sys_param FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sys_param
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);

COMMENT ON TABLE sys_param IS '系统参数';
COMMENT ON COLUMN sys_param.param_key IS '参数键（一意、group.key 形式）';
COMMENT ON COLUMN sys_param.param_name IS '参数名称';
COMMENT ON COLUMN sys_param.param_group IS '分组（auth/file/notify/workflow/report/…）';
COMMENT ON COLUMN sys_param.param_value IS '参数值（加密対象は AES-256 暗号文）';
COMMENT ON COLUMN sys_param.default_value IS '默认值';
COMMENT ON COLUMN sys_param.value_type IS '类型：1 字符串 / 2 整数 / 3 小数 / 4 布尔 / 5 JSON / 6 日期';
COMMENT ON COLUMN sys_param.value_range IS '值域（例 1-100、a,b,c、正则）';
COMMENT ON COLUMN sys_param.is_encrypted IS '是否加密保存';
COMMENT ON COLUMN sys_param.is_danger IS '高危参数（変更時复核必須）';
COMMENT ON COLUMN sys_param.is_readonly IS '只读（システム固定）';
COMMENT ON COLUMN sys_param.effective_scope IS '有効範囲：1 全社 / 2 工厂 / 3 用户';
COMMENT ON COLUMN sys_param.sort_no IS '表示顺';
COMMENT ON COLUMN sys_param.description IS '说明';
COMMENT ON COLUMN sys_param.status IS '状态：1 有效 / 0 无效';
COMMENT ON COLUMN sys_param.id IS '雪花 ID（主键）';
COMMENT ON COLUMN sys_param.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN sys_param.company_id IS '公司 ID';
COMMENT ON COLUMN sys_param.created_at IS '创建时间';
COMMENT ON COLUMN sys_param.created_by IS '创建人';
COMMENT ON COLUMN sys_param.updated_at IS '更新时间';
COMMENT ON COLUMN sys_param.updated_by IS '更新人';
COMMENT ON COLUMN sys_param.version IS '乐观锁版本';
COMMENT ON COLUMN sys_param.deleted IS '逻辑删除';
COMMENT ON COLUMN sys_param.remark IS '备注';
COMMENT ON COLUMN sys_param.ext_data IS '扩展字段';

CREATE TABLE sys_sequence (
    id             BIGINT       NOT NULL,
    tenant_id      BIGINT       NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id     BIGINT       NOT NULL,   -- 公司 ID（会社別採番）
    sequence_key   VARCHAR(64)  NOT NULL,   -- 採番キー（sys_number_rule.rule_code）
    sequence_date  DATE         NOT NULL,   -- 期間開始日（日次=当日、月次=月初、年次=年初、無=1970-01-01）
    current_value  BIGINT       NOT NULL DEFAULT 0, -- 現在値
    step           INT          NOT NULL DEFAULT 1, -- 増分
    version        INT          NOT NULL DEFAULT 0,
    created_at     TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_by     BIGINT       NOT NULL DEFAULT 0,
    updated_at     TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_by     BIGINT       NOT NULL DEFAULT 0,
    CONSTRAINT pk_sys_sequence PRIMARY KEY (id),
    CONSTRAINT uk_sys_sequence_key_date UNIQUE (tenant_id, company_id, sequence_key, sequence_date)
);

ALTER TABLE sys_sequence ENABLE ROW LEVEL SECURITY;
ALTER TABLE sys_sequence FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sys_sequence
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);

COMMENT ON TABLE sys_sequence IS '采番连番';
COMMENT ON COLUMN sys_sequence.company_id IS '公司 ID（会社別採番）';
COMMENT ON COLUMN sys_sequence.sequence_key IS '採番キー（sys_number_rule.rule_code）';
COMMENT ON COLUMN sys_sequence.sequence_date IS '期間開始日（日次=当日、月次=月初、年次=年初、無=1970-01-01）';
COMMENT ON COLUMN sys_sequence.current_value IS '現在値';
COMMENT ON COLUMN sys_sequence.step IS '増分';
COMMENT ON COLUMN sys_sequence.id IS '雪花 ID（主键）';
COMMENT ON COLUMN sys_sequence.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN sys_sequence.created_at IS '创建时间';
COMMENT ON COLUMN sys_sequence.created_by IS '创建人';
COMMENT ON COLUMN sys_sequence.updated_at IS '更新时间';
COMMENT ON COLUMN sys_sequence.updated_by IS '更新人';
COMMENT ON COLUMN sys_sequence.version IS '乐观锁版本';


-- ---------------------------------------------------------------------------
-- 租户开户角色 + sys_init_tenant（01-system/90 §3.15）
-- SECURITY DEFINER、固定 search_path、先 set_config 目标租户
-- REVOKE EXECUTE FROM PUBLIC；不授予 erp_app；仅 erp_tenant_provisioner
-- ---------------------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'erp_tenant_provisioner') THEN
        CREATE ROLE erp_tenant_provisioner NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE
            NOBYPASSRLS NOREPLICATION INHERIT;
    END IF;
END
$$;

GRANT USAGE ON SCHEMA public TO erp_tenant_provisioner;

CREATE OR REPLACE FUNCTION public.sys_init_tenant(p_tenant_id BIGINT)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
    IF p_tenant_id IS NULL THEN
        RAISE EXCEPTION 'sys_init_tenant: tenant_id is required';
    END IF;
    PERFORM set_config('app.tenant_id', p_tenant_id::text, true);

    INSERT INTO sys_param (
        id, tenant_id, company_id,
        param_key, param_name, param_group, param_value, default_value,
        value_type, value_range, is_encrypted, is_danger, is_readonly,
        effective_scope, sort_no, description, status,
        version, deleted, created_at, created_by, updated_at, updated_by
    ) VALUES (
        (p_tenant_id * 1000 + 1), p_tenant_id, 0,
        'prd.completion_over_rate', '完工超收容差（公司默认）', 'prd',
        '0.05', '0.05',
        3, '0.0000-1.0000', FALSE, FALSE, FALSE,
        1, 10,
        '完工超收容差的公司默认（比率，0.05=5%）。受注行>物料>分类>本参数。',
        1,
        0, FALSE, now(), 0, now(), 0
    )
    ON CONFLICT (tenant_id, company_id, param_key) WHERE deleted = FALSE
    DO NOTHING;
END;
$$;

COMMENT ON FUNCTION public.sys_init_tenant(BIGINT) IS
    '租户创建时投入默认 sys_param（含 prd.completion_over_rate=0.05）；SECURITY DEFINER';

REVOKE ALL ON FUNCTION public.sys_init_tenant(BIGINT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.sys_init_tenant(BIGINT) TO erp_tenant_provisioner;

-- 种租户 0（系统默认租户）+ 显式投入默认参数（owner 执行，须写明 tenant_id）
INSERT INTO sys_tenant (
    id, tenant_id, tenant_code, tenant_name, max_user_count, status,
    version, deleted, created_at, created_by, updated_at, updated_by
) VALUES (
    0, 0, 'SYSTEM', '系统默认租户', 0, 1,
    0, FALSE, now(), 0, now(), 0
) ON CONFLICT (id) DO NOTHING;

INSERT INTO sys_param (
    id, tenant_id, company_id,
    param_key, param_name, param_group, param_value, default_value,
    value_type, value_range, is_encrypted, is_danger, is_readonly,
    effective_scope, sort_no, description, status,
    version, deleted, created_at, created_by, updated_at, updated_by
) VALUES (
    1, 0, 0,
    'prd.completion_over_rate', '完工超收容差（公司默认）', 'prd',
    '0.05', '0.05',
    3, '0.0000-1.0000', FALSE, FALSE, FALSE,
    1, 10,
    '完工超收容差的公司默认（比率，0.05=5%）。受注行>物料>分类>本参数。',
    1,
    0, FALSE, now(), 0, now(), 0
) ON CONFLICT (tenant_id, company_id, param_key) WHERE deleted = FALSE
DO NOTHING;
