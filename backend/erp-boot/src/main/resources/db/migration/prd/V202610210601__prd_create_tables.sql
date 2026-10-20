-- 06-production 全量建表（docs/design/06-production/90-db-design.md §3，47 表 + §3.19.1 prd_overproduction_approval）
-- 由设计书 DDL 机械转换：仅展开「共通カラム（§1.2）」并追加 RLS / 注释，不新增设计书之外的业务列。
-- 规则：tenant_id DEFAULT current_setting('app.tenant_id')::bigint；company_id NOT NULL 无 DEFAULT；
--       uk_ 以 (tenant_id, company_id, …) 打头，例外（父 ID 明细表，以 company_id 打头）见设计书 §8 末尾 / RlsCoverageTest；
--       ENABLE + FORCE RLS；erp_app 的 DML 权限由 V202610200101 的 ALTER DEFAULT PRIVILEGES 自动授予（无列级特殊授权）。
-- 共通列分配（§1.2）：主数据=全部共通列含 deleted；单据/明细=不含 deleted；履历=id/tenant_id/company_id/created_*；
--       prd_capacity_load（集计）=不含 version/deleted。明细表按 §1.2 表格冗余持有 company_id（索引首列，不可省略）。
-- 跨域引用（sal_/inv_/fin_/sys_ 等）设计书只在注释中给出，未声明 FK 约束，本迁移不追加（相关表尚未迁移）。
-- 锁序（§5.2 / 04 §11.1）：跨表先受注行 FOR UPDATE 再工单；同表按 id 升序。
-- prd_work_order.standard_cost：NUMERIC(18,6) NULL、无 DEFAULT（PR #9）。

-- prd_bom
CREATE TABLE prd_bom (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    deleted             BOOLEAN       NOT NULL DEFAULT FALSE,
    remark              VARCHAR(500),
    ext_data            JSONB,
    bom_no              VARCHAR(32)   NOT NULL,                  -- BOM 编码 BOM-{父物料编码}-V{2位版本}（08 2.2）
    material_id         BIGINT        NOT NULL,                  -- 父项（产品）物料 ID → mdm_material.id
    material_code       VARCHAR(64)   NOT NULL,                  -- 父项物料编码（スナップショット）
    material_name       VARCHAR(200)  NOT NULL,                  -- 父项物料名称（スナップショット）
    material_spec       VARCHAR(200),                            -- 父项规格（スナップショット）
    factory_id          BIGINT        NOT NULL,                  -- 工厂 ID → mdm_factory.id
    version_no          SMALLINT      NOT NULL,                  -- 版本号（01〜99、`sys_sequence` キー BOM_VERSION で採番）
    base_qty            NUMERIC(18,4) NOT NULL DEFAULT 1,        -- 基准数量（BOM 用量の基準。YE3 は 1 PCE）
    base_uom_code       VARCHAR(16)   NOT NULL,                  -- 基准单位（PCE）
    bom_status          SMALLINT      NOT NULL DEFAULT 10,       -- 10:草稿 25:承認済 30:有効 90:廃止
    valid_from          DATE          NOT NULL,                  -- 生效开始日
    valid_to            DATE,                                    -- 生效終了日（NULL=無期限）
    is_default          BOOLEAN       NOT NULL DEFAULT FALSE,    -- 既定版本フラグ
    eco_no              VARCHAR(32),                             -- 设计变更（ECN）编号
    low_level_code      SMALLINT      NOT NULL DEFAULT 1,        -- 父项低层码（BAT-PRD-002 で計算・保持）
    approved_by         BIGINT,                                  -- 承認者 → sys_user.id
    approved_at         TIMESTAMPTZ,                             -- 承認日時
    effective_status    SMALLINT      NOT NULL DEFAULT 0,        -- 有効判定キャッシュ 0:期間外 1:有効（バッチで更新）
    CONSTRAINT pk_prd_bom PRIMARY KEY (id),
    CONSTRAINT fk_prd_bom_material FOREIGN KEY (material_id) REFERENCES mdm_material (id),
    CONSTRAINT fk_prd_bom_factory FOREIGN KEY (factory_id) REFERENCES mdm_factory (id),
    CONSTRAINT ck_prd_bom_status CHECK (bom_status IN (10,25,30,90)),
    CONSTRAINT ck_prd_bom_valid CHECK (valid_to IS NULL OR valid_to >= valid_from),
    CONSTRAINT ck_prd_bom_base_qty CHECK (base_qty > 0)
);
ALTER TABLE prd_bom ENABLE ROW LEVEL SECURITY;
ALTER TABLE prd_bom FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON prd_bom
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_prd_bom_bom_no ON prd_bom (tenant_id, company_id, bom_no) WHERE deleted = FALSE;
CREATE UNIQUE INDEX uk_prd_bom_material_version ON prd_bom (tenant_id, company_id, material_id, factory_id, version_no) WHERE deleted = FALSE;
CREATE INDEX idx_prd_bom_material_status ON prd_bom (company_id, material_id, bom_status, valid_from DESC);
CREATE INDEX idx_prd_bom_effective ON prd_bom (company_id, effective_status, valid_from, valid_to);
-- 既定版本は 1 件のみ（部分一意）
CREATE UNIQUE INDEX uk_prd_bom_default ON prd_bom (tenant_id, company_id, material_id, factory_id) WHERE is_default = TRUE AND deleted = FALSE;
COMMENT ON COLUMN prd_bom.id IS '雪花 ID（主键）';
COMMENT ON COLUMN prd_bom.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN prd_bom.company_id IS '公司 ID（无默认值）';
COMMENT ON COLUMN prd_bom.created_at IS '创建时间';
COMMENT ON COLUMN prd_bom.created_by IS '创建人';
COMMENT ON COLUMN prd_bom.updated_at IS '更新时间';
COMMENT ON COLUMN prd_bom.updated_by IS '更新人';
COMMENT ON COLUMN prd_bom.version IS '乐观锁版本';
COMMENT ON COLUMN prd_bom.deleted IS '逻辑删除';
COMMENT ON COLUMN prd_bom.remark IS '备注';
COMMENT ON COLUMN prd_bom.ext_data IS '扩展字段';
COMMENT ON COLUMN prd_bom.bom_no IS 'BOM 编码 BOM-{父物料编码}-V{2位版本}（08 2.2）';
COMMENT ON COLUMN prd_bom.material_id IS '父项（产品）物料 ID → mdm_material.id';
COMMENT ON COLUMN prd_bom.material_code IS '父项物料编码（スナップショット）';
COMMENT ON COLUMN prd_bom.material_name IS '父项物料名称（スナップショット）';
COMMENT ON COLUMN prd_bom.material_spec IS '父项规格（スナップショット）';
COMMENT ON COLUMN prd_bom.factory_id IS '工厂 ID → mdm_factory.id';
COMMENT ON COLUMN prd_bom.version_no IS '版本号（01〜99、`sys_sequence` キー BOM_VERSION で採番）';
COMMENT ON COLUMN prd_bom.base_qty IS '基准数量（BOM 用量の基準。YE3 は 1 PCE）';
COMMENT ON COLUMN prd_bom.base_uom_code IS '基准单位（PCE）';
COMMENT ON COLUMN prd_bom.bom_status IS '10:草稿 25:承認済 30:有効 90:廃止';
COMMENT ON COLUMN prd_bom.valid_from IS '生效开始日';
COMMENT ON COLUMN prd_bom.valid_to IS '生效終了日（NULL=無期限）';
COMMENT ON COLUMN prd_bom.is_default IS '既定版本フラグ';
COMMENT ON COLUMN prd_bom.eco_no IS '设计变更（ECN）编号';
COMMENT ON COLUMN prd_bom.low_level_code IS '父项低层码（BAT-PRD-002 で計算・保持）';
COMMENT ON COLUMN prd_bom.approved_by IS '承認者 → sys_user.id';
COMMENT ON COLUMN prd_bom.approved_at IS '承認日時';
COMMENT ON COLUMN prd_bom.effective_status IS '有効判定キャッシュ 0:期間外 1:有効（バッチで更新）';

-- prd_bom_line
CREATE TABLE prd_bom_line (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    deleted             BOOLEAN       NOT NULL DEFAULT FALSE,
    remark              VARCHAR(500),
    ext_data            JSONB,
    bom_id              BIGINT        NOT NULL,                  -- BOM ID → prd_bom.id
    line_no             INT           NOT NULL,                  -- 行番号（10 刻み）
    component_material_id BIGINT      NOT NULL,                  -- 子件物料 ID → mdm_material.id
    component_code      VARCHAR(64)   NOT NULL,                  -- 子件物料编码（スナップショット）
    component_name      VARCHAR(200)  NOT NULL,                  -- 子件物料名称（スナップショット）
    component_spec      VARCHAR(200),                            -- 子件规格（スナップショット）
    uom_code            VARCHAR(16)   NOT NULL,                  -- 使用単位（基本単位）
    component_qty       NUMERIC(18,4) NOT NULL,                  -- 純使用量（base_qty あたり。bom-demo §4 の qty_net）
    loss_rate           NUMERIC(7,4)  NOT NULL DEFAULT 0,        -- 工程损耗率（比率。0.3000 = 30%。gross = net ÷ (1 − loss_rate)）
    required_qty        NUMERIC(18,4) NOT NULL,                  -- 展開用所要量（gross）= component_qty ÷ (1 − loss_rate)（4 桁四捨五入）
    component_type      SMALLINT      NOT NULL DEFAULT 10,       -- 10:标准件 20:替代候補 30:虚拟件（展开用） 40:委外件
    level_no            SMALLINT      NOT NULL DEFAULT 1,        -- 本 BOM 内の相対階層
    operation_seq       INT,                                     -- 投入工序 SEQ（NULL=最初の工序）
    feeding_type        SMALLINT      NOT NULL DEFAULT 10,       -- 10:先行払出 20:倒冲（後方払出）
    is_key_part         BOOLEAN       NOT NULL DEFAULT FALSE,    -- 关键件（品質追跡対象）
    substitute_group    VARCHAR(32),                             -- 替代组（同一组内で代替可能）
    position_no         VARCHAR(32),                             -- 装配位置（定子/转子/机座等）
    effective_status    SMALLINT      NOT NULL DEFAULT 1,        -- 0:期間外 1:有効（親に同期）
    CONSTRAINT pk_prd_bom_line PRIMARY KEY (id),
    CONSTRAINT fk_prd_bom_line_bom FOREIGN KEY (bom_id) REFERENCES prd_bom (id) ON DELETE RESTRICT,
    CONSTRAINT fk_prd_bom_line_component FOREIGN KEY (component_material_id) REFERENCES mdm_material (id),
    CONSTRAINT ck_prd_bom_line_qty CHECK (component_qty > 0 AND required_qty > 0),
    CONSTRAINT ck_prd_bom_line_loss CHECK (loss_rate >= 0 AND loss_rate < 1),
    CONSTRAINT ck_prd_bom_line_level CHECK (level_no >= 1)
);
ALTER TABLE prd_bom_line ENABLE ROW LEVEL SECURITY;
ALTER TABLE prd_bom_line FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON prd_bom_line
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_prd_bom_line_bom_line ON prd_bom_line (company_id, bom_id, line_no);
CREATE INDEX idx_prd_bom_line_component ON prd_bom_line (company_id, component_material_id);
CREATE INDEX idx_prd_bom_line_substitute ON prd_bom_line (company_id, substitute_group) WHERE substitute_group IS NOT NULL;
COMMENT ON COLUMN prd_bom_line.id IS '雪花 ID（主键）';
COMMENT ON COLUMN prd_bom_line.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN prd_bom_line.company_id IS '公司 ID（无默认值）';
COMMENT ON COLUMN prd_bom_line.created_at IS '创建时间';
COMMENT ON COLUMN prd_bom_line.created_by IS '创建人';
COMMENT ON COLUMN prd_bom_line.updated_at IS '更新时间';
COMMENT ON COLUMN prd_bom_line.updated_by IS '更新人';
COMMENT ON COLUMN prd_bom_line.version IS '乐观锁版本';
COMMENT ON COLUMN prd_bom_line.deleted IS '逻辑删除';
COMMENT ON COLUMN prd_bom_line.remark IS '备注';
COMMENT ON COLUMN prd_bom_line.ext_data IS '扩展字段';
COMMENT ON COLUMN prd_bom_line.bom_id IS 'BOM ID → prd_bom.id';
COMMENT ON COLUMN prd_bom_line.line_no IS '行番号（10 刻み）';
COMMENT ON COLUMN prd_bom_line.component_material_id IS '子件物料 ID → mdm_material.id';
COMMENT ON COLUMN prd_bom_line.component_code IS '子件物料编码（スナップショット）';
COMMENT ON COLUMN prd_bom_line.component_name IS '子件物料名称（スナップショット）';
COMMENT ON COLUMN prd_bom_line.component_spec IS '子件规格（スナップショット）';
COMMENT ON COLUMN prd_bom_line.uom_code IS '使用単位（基本単位）';
COMMENT ON COLUMN prd_bom_line.component_qty IS '純使用量（base_qty あたり。bom-demo §4 の qty_net）';
COMMENT ON COLUMN prd_bom_line.loss_rate IS '工程损耗率（比率。0.3000 = 30%。gross = net ÷ (1 − loss_rate)）';
COMMENT ON COLUMN prd_bom_line.required_qty IS '展開用所要量（gross）= component_qty ÷ (1 − loss_rate)（4 桁四捨五入）';
COMMENT ON COLUMN prd_bom_line.component_type IS '10:标准件 20:替代候補 30:虚拟件（展开用） 40:委外件';
COMMENT ON COLUMN prd_bom_line.level_no IS '本 BOM 内の相対階層';
COMMENT ON COLUMN prd_bom_line.operation_seq IS '投入工序 SEQ（NULL=最初の工序）';
COMMENT ON COLUMN prd_bom_line.feeding_type IS '10:先行払出 20:倒冲（後方払出）';
COMMENT ON COLUMN prd_bom_line.is_key_part IS '关键件（品質追跡対象）';
COMMENT ON COLUMN prd_bom_line.substitute_group IS '替代组（同一组内で代替可能）';
COMMENT ON COLUMN prd_bom_line.position_no IS '装配位置（定子/转子/机座等）';
COMMENT ON COLUMN prd_bom_line.effective_status IS '0:期間外 1:有効（親に同期）';

-- prd_bom_substitute
CREATE TABLE prd_bom_substitute (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    deleted             BOOLEAN       NOT NULL DEFAULT FALSE,
    remark              VARCHAR(500),
    ext_data            JSONB,
    bom_line_id         BIGINT        NOT NULL,                  -- 主料行 ID → prd_bom_line.id
    line_no             INT           NOT NULL,                  -- 行番号
    substitute_material_id BIGINT     NOT NULL,                  -- 替代料 ID → mdm_material.id
    substitute_code     VARCHAR(64)   NOT NULL,                  -- 替代料编码（スナップショット）
    substitute_name     VARCHAR(200)  NOT NULL,                  -- 替代料名称（スナップショット）
    substitute_qty      NUMERIC(18,4) NOT NULL,                  -- 替代投入量（主料 1 単位に対する必要量）
    substitute_uom_code VARCHAR(16)   NOT NULL,                  -- 替代料单位
    priority_no         SMALLINT      NOT NULL DEFAULT 1,        -- 优先順（1 が最優先）
    ratio               NUMERIC(7,4)  NOT NULL DEFAULT 1,        -- 替代比率（1.0000 = 全量替代可、0.3000 = 30% まで）
    loss_rate           NUMERIC(7,4)  NOT NULL DEFAULT 0,        -- 替代料损耗率
    unit_cost_diff      NUMERIC(18,6),                           -- 标准成本差异（替代料単価 − 主料単価）
    valid_from          DATE,                                    -- 替代有効開始日
    valid_to            DATE,                                    -- 替代有効終了日
    substitute_reason   VARCHAR(200),                            -- 替代理由（缺料/成本/工艺）
    approval_status     SMALLINT      NOT NULL DEFAULT 10,       -- 10:未承認 25:承認済
    CONSTRAINT pk_prd_bom_substitute PRIMARY KEY (id),
    CONSTRAINT fk_prd_bom_substitute_line FOREIGN KEY (bom_line_id) REFERENCES prd_bom_line (id) ON DELETE RESTRICT,
    CONSTRAINT fk_prd_bom_substitute_material FOREIGN KEY (substitute_material_id) REFERENCES mdm_material (id),
    CONSTRAINT ck_prd_bom_substitute_qty CHECK (substitute_qty > 0 AND ratio > 0 AND ratio <= 1)
);
ALTER TABLE prd_bom_substitute ENABLE ROW LEVEL SECURITY;
ALTER TABLE prd_bom_substitute FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON prd_bom_substitute
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_prd_bom_substitute_line_pri ON prd_bom_substitute (company_id, bom_line_id, priority_no) WHERE deleted = FALSE;
CREATE INDEX idx_prd_bom_substitute_material ON prd_bom_substitute (company_id, substitute_material_id, valid_from, valid_to);
COMMENT ON COLUMN prd_bom_substitute.id IS '雪花 ID（主键）';
COMMENT ON COLUMN prd_bom_substitute.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN prd_bom_substitute.company_id IS '公司 ID（无默认值）';
COMMENT ON COLUMN prd_bom_substitute.created_at IS '创建时间';
COMMENT ON COLUMN prd_bom_substitute.created_by IS '创建人';
COMMENT ON COLUMN prd_bom_substitute.updated_at IS '更新时间';
COMMENT ON COLUMN prd_bom_substitute.updated_by IS '更新人';
COMMENT ON COLUMN prd_bom_substitute.version IS '乐观锁版本';
COMMENT ON COLUMN prd_bom_substitute.deleted IS '逻辑删除';
COMMENT ON COLUMN prd_bom_substitute.remark IS '备注';
COMMENT ON COLUMN prd_bom_substitute.ext_data IS '扩展字段';
COMMENT ON COLUMN prd_bom_substitute.bom_line_id IS '主料行 ID → prd_bom_line.id';
COMMENT ON COLUMN prd_bom_substitute.line_no IS '行番号';
COMMENT ON COLUMN prd_bom_substitute.substitute_material_id IS '替代料 ID → mdm_material.id';
COMMENT ON COLUMN prd_bom_substitute.substitute_code IS '替代料编码（スナップショット）';
COMMENT ON COLUMN prd_bom_substitute.substitute_name IS '替代料名称（スナップショット）';
COMMENT ON COLUMN prd_bom_substitute.substitute_qty IS '替代投入量（主料 1 単位に対する必要量）';
COMMENT ON COLUMN prd_bom_substitute.substitute_uom_code IS '替代料单位';
COMMENT ON COLUMN prd_bom_substitute.priority_no IS '优先順（1 が最優先）';
COMMENT ON COLUMN prd_bom_substitute.ratio IS '替代比率（1.0000 = 全量替代可、0.3000 = 30% まで）';
COMMENT ON COLUMN prd_bom_substitute.loss_rate IS '替代料损耗率';
COMMENT ON COLUMN prd_bom_substitute.unit_cost_diff IS '标准成本差异（替代料単価 − 主料単価）';
COMMENT ON COLUMN prd_bom_substitute.valid_from IS '替代有効開始日';
COMMENT ON COLUMN prd_bom_substitute.valid_to IS '替代有効終了日';
COMMENT ON COLUMN prd_bom_substitute.substitute_reason IS '替代理由（缺料/成本/工艺）';
COMMENT ON COLUMN prd_bom_substitute.approval_status IS '10:未承認 25:承認済';

-- prd_routing
CREATE TABLE prd_routing (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    deleted             BOOLEAN       NOT NULL DEFAULT FALSE,
    remark              VARCHAR(500),
    ext_data            JSONB,
    routing_no          VARCHAR(40)   NOT NULL,                  -- 工艺路线编码 RT-{物料编码}-V{2位版本}
    material_id         BIGINT        NOT NULL,                  -- 对象物料 ID → mdm_material.id
    material_code       VARCHAR(64)   NOT NULL,                  -- 物料编码（スナップショット）
    material_name       VARCHAR(200)  NOT NULL,                  -- 物料名称（スナップショット）
    factory_id          BIGINT        NOT NULL,                  -- 工厂 ID → mdm_factory.id
    version_no          SMALLINT      NOT NULL,                  -- 版本号
    routing_status      SMALLINT      NOT NULL DEFAULT 10,       -- 10:草稿 25:承認済 30:有効 90:廃止
    valid_from          DATE          NOT NULL,                  -- 生效开始日
    valid_to            DATE,                                    -- 生效終了日
    is_default          BOOLEAN       NOT NULL DEFAULT FALSE,    -- 既定版本
    total_setup_hours   NUMERIC(12,2) NOT NULL DEFAULT 0,        -- 全工序准备工数合計（h）
    total_run_hours     NUMERIC(12,2) NOT NULL DEFAULT 0,        -- 全工序单件工数合計（h/件）
    eco_no              VARCHAR(32),                             -- 设计变更编号
    approved_by         BIGINT,                                  -- 承認者
    approved_at         TIMESTAMPTZ,                             -- 承認日時
    effective_status    SMALLINT      NOT NULL DEFAULT 0,        -- 0:期間外 1:有効
    CONSTRAINT pk_prd_routing PRIMARY KEY (id),
    CONSTRAINT fk_prd_routing_material FOREIGN KEY (material_id) REFERENCES mdm_material (id),
    CONSTRAINT fk_prd_routing_factory FOREIGN KEY (factory_id) REFERENCES mdm_factory (id),
    CONSTRAINT ck_prd_routing_status CHECK (routing_status IN (10,25,30,90)),
    CONSTRAINT ck_prd_routing_valid CHECK (valid_to IS NULL OR valid_to >= valid_from)
);
ALTER TABLE prd_routing ENABLE ROW LEVEL SECURITY;
ALTER TABLE prd_routing FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON prd_routing
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_prd_routing_no ON prd_routing (tenant_id, company_id, routing_no) WHERE deleted = FALSE;
CREATE UNIQUE INDEX uk_prd_routing_material_version ON prd_routing (tenant_id, company_id, material_id, factory_id, version_no) WHERE deleted = FALSE;
CREATE INDEX idx_prd_routing_material_status ON prd_routing (company_id, material_id, routing_status, valid_from DESC);
CREATE UNIQUE INDEX uk_prd_routing_default ON prd_routing (tenant_id, company_id, material_id, factory_id) WHERE is_default = TRUE AND deleted = FALSE;
COMMENT ON COLUMN prd_routing.id IS '雪花 ID（主键）';
COMMENT ON COLUMN prd_routing.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN prd_routing.company_id IS '公司 ID（无默认值）';
COMMENT ON COLUMN prd_routing.created_at IS '创建时间';
COMMENT ON COLUMN prd_routing.created_by IS '创建人';
COMMENT ON COLUMN prd_routing.updated_at IS '更新时间';
COMMENT ON COLUMN prd_routing.updated_by IS '更新人';
COMMENT ON COLUMN prd_routing.version IS '乐观锁版本';
COMMENT ON COLUMN prd_routing.deleted IS '逻辑删除';
COMMENT ON COLUMN prd_routing.remark IS '备注';
COMMENT ON COLUMN prd_routing.ext_data IS '扩展字段';
COMMENT ON COLUMN prd_routing.routing_no IS '工艺路线编码 RT-{物料编码}-V{2位版本}';
COMMENT ON COLUMN prd_routing.material_id IS '对象物料 ID → mdm_material.id';
COMMENT ON COLUMN prd_routing.material_code IS '物料编码（スナップショット）';
COMMENT ON COLUMN prd_routing.material_name IS '物料名称（スナップショット）';
COMMENT ON COLUMN prd_routing.factory_id IS '工厂 ID → mdm_factory.id';
COMMENT ON COLUMN prd_routing.version_no IS '版本号';
COMMENT ON COLUMN prd_routing.routing_status IS '10:草稿 25:承認済 30:有効 90:廃止';
COMMENT ON COLUMN prd_routing.valid_from IS '生效开始日';
COMMENT ON COLUMN prd_routing.valid_to IS '生效終了日';
COMMENT ON COLUMN prd_routing.is_default IS '既定版本';
COMMENT ON COLUMN prd_routing.total_setup_hours IS '全工序准备工数合計（h）';
COMMENT ON COLUMN prd_routing.total_run_hours IS '全工序单件工数合計（h/件）';
COMMENT ON COLUMN prd_routing.eco_no IS '设计变更编号';
COMMENT ON COLUMN prd_routing.approved_by IS '承認者';
COMMENT ON COLUMN prd_routing.approved_at IS '承認日時';
COMMENT ON COLUMN prd_routing.effective_status IS '0:期間外 1:有効';

-- prd_work_center
CREATE TABLE prd_work_center (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    deleted             BOOLEAN       NOT NULL DEFAULT FALSE,
    remark              VARCHAR(500),
    ext_data            JSONB,
    work_center_code    VARCHAR(32)   NOT NULL,                  -- 工作中心编码 WC001（08 2.2）
    work_center_name    VARCHAR(100)  NOT NULL,                  -- 工作中心名称（冲片中心 等）
    factory_id          BIGINT        NOT NULL,                  -- 工厂 ID → mdm_factory.id
    department_id       BIGINT,                                  -- 所属部门 ID → sys_department.id
    work_center_type    SMALLINT      NOT NULL DEFAULT 10,       -- 10:設備 20:班組 30:手工作業 40:外注
    capacity_per_day    NUMERIC(18,4) NOT NULL DEFAULT 8,        -- 日能力（capacity_uom 単位）
    capacity_uom        VARCHAR(16)   NOT NULL DEFAULT 'H',      -- 能力単位 H:工時 PCE:台
    shift_pattern       VARCHAR(32)   NOT NULL DEFAULT 'TWO',    -- 班次模式 TWO:二班 THREE:三班 ONE:一班
    calendar_id         BIGINT,                                  -- 工作日历 ID → prd_work_center_calendar の暦グループ
    equipment_count     SMALLINT      NOT NULL DEFAULT 1,        -- 设备台数
    standard_worker_count SMALLINT    NOT NULL DEFAULT 0,        -- 标准人员数
    labor_rate_per_hour NUMERIC(18,6) NOT NULL DEFAULT 0,        -- 人工费率（元/h、J13 用）
    overhead_rate_per_hour NUMERIC(18,6) NOT NULL DEFAULT 0,     -- 制造费用分配率（元/h、J14/J15 用）
    machine_rate_per_hour  NUMERIC(18,6) NOT NULL DEFAULT 0,     -- 设备费率（元/h、参考）
    cost_center_code    VARCHAR(32),                             -- 成本中心编码（FIN 連携）
    is_bottleneck       BOOLEAN       NOT NULL DEFAULT FALSE,    -- 瓶颈工序フラグ
    status              SMALLINT      NOT NULL DEFAULT 1,        -- 1:有効 0:使用停止
    valid_from          DATE,                                    -- 有効開始日
    valid_to            DATE,                                    -- 有効終了日
    CONSTRAINT pk_prd_work_center PRIMARY KEY (id),
    CONSTRAINT fk_prd_work_center_factory FOREIGN KEY (factory_id) REFERENCES mdm_factory (id),
    CONSTRAINT ck_prd_work_center_type CHECK (work_center_type IN (10,20,30,40)),
    CONSTRAINT ck_prd_work_center_capacity CHECK (capacity_per_day >= 0),
    CONSTRAINT ck_prd_work_center_rate CHECK (labor_rate_per_hour >= 0 AND overhead_rate_per_hour >= 0)
);
ALTER TABLE prd_work_center ENABLE ROW LEVEL SECURITY;
ALTER TABLE prd_work_center FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON prd_work_center
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_prd_work_center_code ON prd_work_center (tenant_id, company_id, work_center_code) WHERE deleted = FALSE;
CREATE INDEX idx_prd_work_center_factory ON prd_work_center (company_id, factory_id, status);
COMMENT ON COLUMN prd_work_center.id IS '雪花 ID（主键）';
COMMENT ON COLUMN prd_work_center.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN prd_work_center.company_id IS '公司 ID（无默认值）';
COMMENT ON COLUMN prd_work_center.created_at IS '创建时间';
COMMENT ON COLUMN prd_work_center.created_by IS '创建人';
COMMENT ON COLUMN prd_work_center.updated_at IS '更新时间';
COMMENT ON COLUMN prd_work_center.updated_by IS '更新人';
COMMENT ON COLUMN prd_work_center.version IS '乐观锁版本';
COMMENT ON COLUMN prd_work_center.deleted IS '逻辑删除';
COMMENT ON COLUMN prd_work_center.remark IS '备注';
COMMENT ON COLUMN prd_work_center.ext_data IS '扩展字段';
COMMENT ON COLUMN prd_work_center.work_center_code IS '工作中心编码 WC001（08 2.2）';
COMMENT ON COLUMN prd_work_center.work_center_name IS '工作中心名称（冲片中心 等）';
COMMENT ON COLUMN prd_work_center.factory_id IS '工厂 ID → mdm_factory.id';
COMMENT ON COLUMN prd_work_center.department_id IS '所属部门 ID → sys_department.id';
COMMENT ON COLUMN prd_work_center.work_center_type IS '10:設備 20:班組 30:手工作業 40:外注';
COMMENT ON COLUMN prd_work_center.capacity_per_day IS '日能力（capacity_uom 単位）';
COMMENT ON COLUMN prd_work_center.capacity_uom IS '能力単位 H:工時 PCE:台';
COMMENT ON COLUMN prd_work_center.shift_pattern IS '班次模式 TWO:二班 THREE:三班 ONE:一班';
COMMENT ON COLUMN prd_work_center.calendar_id IS '工作日历 ID → prd_work_center_calendar の暦グループ';
COMMENT ON COLUMN prd_work_center.equipment_count IS '设备台数';
COMMENT ON COLUMN prd_work_center.standard_worker_count IS '标准人员数';
COMMENT ON COLUMN prd_work_center.labor_rate_per_hour IS '人工费率（元/h、J13 用）';
COMMENT ON COLUMN prd_work_center.overhead_rate_per_hour IS '制造费用分配率（元/h、J14/J15 用）';
COMMENT ON COLUMN prd_work_center.machine_rate_per_hour IS '设备费率（元/h、参考）';
COMMENT ON COLUMN prd_work_center.cost_center_code IS '成本中心编码（FIN 連携）';
COMMENT ON COLUMN prd_work_center.is_bottleneck IS '瓶颈工序フラグ';
COMMENT ON COLUMN prd_work_center.status IS '1:有効 0:使用停止';
COMMENT ON COLUMN prd_work_center.valid_from IS '有効開始日';
COMMENT ON COLUMN prd_work_center.valid_to IS '有効終了日';

-- prd_routing_operation
CREATE TABLE prd_routing_operation (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    deleted             BOOLEAN       NOT NULL DEFAULT FALSE,
    remark              VARCHAR(500),
    ext_data            JSONB,
    routing_id          BIGINT        NOT NULL,                  -- 工艺路线 ID → prd_routing.id
    operation_seq       INT           NOT NULL,                  -- 工序序号（10,20,30…）
    operation_code      VARCHAR(32)   NOT NULL,                  -- 工序编码（OP10 等、社内标准）
    operation_name      VARCHAR(100)  NOT NULL,                  -- 工序名称（下料/冲片、绕线 等）
    operation_desc      VARCHAR(500),                            -- 作业内容
    work_center_id      BIGINT        NOT NULL,                  -- 工作中心 ID → prd_work_center.id
    work_center_code    VARCHAR(32)   NOT NULL,                  -- 工作中心编码（スナップショット）
    equipment_id        BIGINT,                                  -- 既定设备 ID → prd_equipment.id
    setup_time          NUMERIC(12,2) NOT NULL DEFAULT 0,        -- 准备工数（h/批次）
    run_time_per_unit   NUMERIC(12,4) NOT NULL DEFAULT 0,        -- 单件工数（h/件）
    labor_time_per_unit NUMERIC(12,4) NOT NULL DEFAULT 0,        -- 单件人工工数（h/件、standard_workers 含む）
    machine_time_per_unit NUMERIC(12,4) NOT NULL DEFAULT 0,      -- 单件设备工数（h/件）
    standard_workers    SMALLINT      NOT NULL DEFAULT 1,        -- 标准作业人数
    queue_time          NUMERIC(12,2) NOT NULL DEFAULT 0,        -- 待ち時間（h）
    move_time           NUMERIC(12,2) NOT NULL DEFAULT 0,        -- 移動時間（h）
    is_inspection_point BOOLEAN       NOT NULL DEFAULT FALSE,    -- 检验点フラグ（IPQC 起票）
    inspection_standard_id BIGINT,                               -- 检验标准 ID → prd_inspection_standard.id（NULL=品目共通）
    is_backflush        BOOLEAN       NOT NULL DEFAULT FALSE,    -- 当工序完了で材料倒冲
    work_instruction    TEXT,                                    -- 作业指导书（要点）
    CONSTRAINT pk_prd_routing_operation PRIMARY KEY (id),
    CONSTRAINT fk_prd_routing_operation_routing FOREIGN KEY (routing_id) REFERENCES prd_routing (id) ON DELETE RESTRICT,
    CONSTRAINT fk_prd_routing_operation_wc FOREIGN KEY (work_center_id) REFERENCES prd_work_center (id),
    CONSTRAINT ck_prd_routing_operation_seq CHECK (operation_seq > 0),
    CONSTRAINT ck_prd_routing_operation_time CHECK (setup_time >= 0 AND run_time_per_unit >= 0)
);
ALTER TABLE prd_routing_operation ENABLE ROW LEVEL SECURITY;
ALTER TABLE prd_routing_operation FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON prd_routing_operation
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_prd_routing_operation_routing_seq ON prd_routing_operation (company_id, routing_id, operation_seq) WHERE deleted = FALSE;
CREATE INDEX idx_prd_routing_operation_wc ON prd_routing_operation (company_id, work_center_id);
CREATE INDEX idx_prd_routing_operation_inspection ON prd_routing_operation (company_id, is_inspection_point) WHERE is_inspection_point = TRUE;
COMMENT ON COLUMN prd_routing_operation.id IS '雪花 ID（主键）';
COMMENT ON COLUMN prd_routing_operation.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN prd_routing_operation.company_id IS '公司 ID（无默认值）';
COMMENT ON COLUMN prd_routing_operation.created_at IS '创建时间';
COMMENT ON COLUMN prd_routing_operation.created_by IS '创建人';
COMMENT ON COLUMN prd_routing_operation.updated_at IS '更新时间';
COMMENT ON COLUMN prd_routing_operation.updated_by IS '更新人';
COMMENT ON COLUMN prd_routing_operation.version IS '乐观锁版本';
COMMENT ON COLUMN prd_routing_operation.deleted IS '逻辑删除';
COMMENT ON COLUMN prd_routing_operation.remark IS '备注';
COMMENT ON COLUMN prd_routing_operation.ext_data IS '扩展字段';
COMMENT ON COLUMN prd_routing_operation.routing_id IS '工艺路线 ID → prd_routing.id';
COMMENT ON COLUMN prd_routing_operation.operation_seq IS '工序序号（10,20,30…）';
COMMENT ON COLUMN prd_routing_operation.operation_code IS '工序编码（OP10 等、社内标准）';
COMMENT ON COLUMN prd_routing_operation.operation_name IS '工序名称（下料/冲片、绕线 等）';
COMMENT ON COLUMN prd_routing_operation.operation_desc IS '作业内容';
COMMENT ON COLUMN prd_routing_operation.work_center_id IS '工作中心 ID → prd_work_center.id';
COMMENT ON COLUMN prd_routing_operation.work_center_code IS '工作中心编码（スナップショット）';
COMMENT ON COLUMN prd_routing_operation.equipment_id IS '既定设备 ID → prd_equipment.id';
COMMENT ON COLUMN prd_routing_operation.setup_time IS '准备工数（h/批次）';
COMMENT ON COLUMN prd_routing_operation.run_time_per_unit IS '单件工数（h/件）';
COMMENT ON COLUMN prd_routing_operation.labor_time_per_unit IS '单件人工工数（h/件、standard_workers 含む）';
COMMENT ON COLUMN prd_routing_operation.machine_time_per_unit IS '单件设备工数（h/件）';
COMMENT ON COLUMN prd_routing_operation.standard_workers IS '标准作业人数';
COMMENT ON COLUMN prd_routing_operation.queue_time IS '待ち時間（h）';
COMMENT ON COLUMN prd_routing_operation.move_time IS '移動時間（h）';
COMMENT ON COLUMN prd_routing_operation.is_inspection_point IS '检验点フラグ（IPQC 起票）';
COMMENT ON COLUMN prd_routing_operation.inspection_standard_id IS '检验标准 ID → prd_inspection_standard.id（NULL=品目共通）';
COMMENT ON COLUMN prd_routing_operation.is_backflush IS '当工序完了で材料倒冲';
COMMENT ON COLUMN prd_routing_operation.work_instruction IS '作业指导书（要点）';

-- prd_routing_operation_alt
CREATE TABLE prd_routing_operation_alt (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    deleted             BOOLEAN       NOT NULL DEFAULT FALSE,
    remark              VARCHAR(500),
    ext_data            JSONB,
    routing_operation_id BIGINT       NOT NULL,                  -- 工序 ID → prd_routing_operation.id
    alt_work_center_id  BIGINT        NOT NULL,                  -- 替代工作中心 ID → prd_work_center.id
    alt_equipment_id    BIGINT,                                  -- 替代设备 ID → prd_equipment.id
    priority_no         SMALLINT      NOT NULL DEFAULT 1,        -- 优先順
    efficiency_rate     NUMERIC(7,4)  NOT NULL DEFAULT 1,        -- 能率係数（1.2000 = 1.2 倍工時）
    alt_reason          VARCHAR(200),                            -- 替代理由（能力不足/故障/外注）
    CONSTRAINT pk_prd_routing_operation_alt PRIMARY KEY (id),
    CONSTRAINT fk_prd_routing_operation_alt_op FOREIGN KEY (routing_operation_id) REFERENCES prd_routing_operation (id) ON DELETE RESTRICT,
    CONSTRAINT fk_prd_routing_operation_alt_wc FOREIGN KEY (alt_work_center_id) REFERENCES prd_work_center (id),
    CONSTRAINT ck_prd_routing_operation_alt_eff CHECK (efficiency_rate >= 0.5)
);
ALTER TABLE prd_routing_operation_alt ENABLE ROW LEVEL SECURITY;
ALTER TABLE prd_routing_operation_alt FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON prd_routing_operation_alt
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_prd_routing_operation_alt_pri ON prd_routing_operation_alt (company_id, routing_operation_id, priority_no) WHERE deleted = FALSE;
COMMENT ON COLUMN prd_routing_operation_alt.id IS '雪花 ID（主键）';
COMMENT ON COLUMN prd_routing_operation_alt.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN prd_routing_operation_alt.company_id IS '公司 ID（无默认值）';
COMMENT ON COLUMN prd_routing_operation_alt.created_at IS '创建时间';
COMMENT ON COLUMN prd_routing_operation_alt.created_by IS '创建人';
COMMENT ON COLUMN prd_routing_operation_alt.updated_at IS '更新时间';
COMMENT ON COLUMN prd_routing_operation_alt.updated_by IS '更新人';
COMMENT ON COLUMN prd_routing_operation_alt.version IS '乐观锁版本';
COMMENT ON COLUMN prd_routing_operation_alt.deleted IS '逻辑删除';
COMMENT ON COLUMN prd_routing_operation_alt.remark IS '备注';
COMMENT ON COLUMN prd_routing_operation_alt.ext_data IS '扩展字段';
COMMENT ON COLUMN prd_routing_operation_alt.routing_operation_id IS '工序 ID → prd_routing_operation.id';
COMMENT ON COLUMN prd_routing_operation_alt.alt_work_center_id IS '替代工作中心 ID → prd_work_center.id';
COMMENT ON COLUMN prd_routing_operation_alt.alt_equipment_id IS '替代设备 ID → prd_equipment.id';
COMMENT ON COLUMN prd_routing_operation_alt.priority_no IS '优先順';
COMMENT ON COLUMN prd_routing_operation_alt.efficiency_rate IS '能率係数（1.2000 = 1.2 倍工時）';
COMMENT ON COLUMN prd_routing_operation_alt.alt_reason IS '替代理由（能力不足/故障/外注）';

-- prd_work_center_calendar
CREATE TABLE prd_work_center_calendar (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    deleted             BOOLEAN       NOT NULL DEFAULT FALSE,
    remark              VARCHAR(500),
    ext_data            JSONB,
    work_center_id      BIGINT        NOT NULL,                  -- 工作中心 ID → prd_work_center.id
    calendar_date       DATE          NOT NULL,                  -- 日付
    day_type            SMALLINT      NOT NULL DEFAULT 10,       -- 10:工作日 20:休息日 30:法定节假日 40:临时调整
    shift_code          VARCHAR(32)   NOT NULL DEFAULT 'ALL',    -- 班次 A/B/C/ALL
    working_hours       NUMERIC(12,2) NOT NULL DEFAULT 8,        -- 稼働時間（h）
    overtime_hours      NUMERIC(12,2) NOT NULL DEFAULT 0,        -- 残業時間（h）
    available_capacity  NUMERIC(18,4) NOT NULL DEFAULT 0,        -- 実効能力（capacity_uom 単位）
    calendar_reason     VARCHAR(200),                            -- 休日/調整理由（春节 等）
    CONSTRAINT pk_prd_work_center_calendar PRIMARY KEY (id),
    CONSTRAINT fk_prd_work_center_calendar_wc FOREIGN KEY (work_center_id) REFERENCES prd_work_center (id) ON DELETE RESTRICT,
    CONSTRAINT ck_prd_work_center_calendar_day CHECK (day_type IN (10,20,30,40)),
    CONSTRAINT ck_prd_work_center_calendar_hours CHECK (working_hours >= 0 AND overtime_hours >= 0)
);
ALTER TABLE prd_work_center_calendar ENABLE ROW LEVEL SECURITY;
ALTER TABLE prd_work_center_calendar FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON prd_work_center_calendar
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_prd_work_center_calendar_date ON prd_work_center_calendar (company_id, work_center_id, calendar_date, shift_code) WHERE deleted = FALSE;
CREATE INDEX idx_prd_work_center_calendar_date ON prd_work_center_calendar (company_id, calendar_date, day_type);
COMMENT ON COLUMN prd_work_center_calendar.id IS '雪花 ID（主键）';
COMMENT ON COLUMN prd_work_center_calendar.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN prd_work_center_calendar.company_id IS '公司 ID（无默认值）';
COMMENT ON COLUMN prd_work_center_calendar.created_at IS '创建时间';
COMMENT ON COLUMN prd_work_center_calendar.created_by IS '创建人';
COMMENT ON COLUMN prd_work_center_calendar.updated_at IS '更新时间';
COMMENT ON COLUMN prd_work_center_calendar.updated_by IS '更新人';
COMMENT ON COLUMN prd_work_center_calendar.version IS '乐观锁版本';
COMMENT ON COLUMN prd_work_center_calendar.deleted IS '逻辑删除';
COMMENT ON COLUMN prd_work_center_calendar.remark IS '备注';
COMMENT ON COLUMN prd_work_center_calendar.ext_data IS '扩展字段';
COMMENT ON COLUMN prd_work_center_calendar.work_center_id IS '工作中心 ID → prd_work_center.id';
COMMENT ON COLUMN prd_work_center_calendar.calendar_date IS '日付';
COMMENT ON COLUMN prd_work_center_calendar.day_type IS '10:工作日 20:休息日 30:法定节假日 40:临时调整';
COMMENT ON COLUMN prd_work_center_calendar.shift_code IS '班次 A/B/C/ALL';
COMMENT ON COLUMN prd_work_center_calendar.working_hours IS '稼働時間（h）';
COMMENT ON COLUMN prd_work_center_calendar.overtime_hours IS '残業時間（h）';
COMMENT ON COLUMN prd_work_center_calendar.available_capacity IS '実効能力（capacity_uom 単位）';
COMMENT ON COLUMN prd_work_center_calendar.calendar_reason IS '休日/調整理由（春节 等）';

-- prd_equipment
CREATE TABLE prd_equipment (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    deleted             BOOLEAN       NOT NULL DEFAULT FALSE,
    remark              VARCHAR(500),
    ext_data            JSONB,
    equipment_code      VARCHAR(32)   NOT NULL,                  -- 设备编号（EQ-001 等）
    equipment_name      VARCHAR(100)  NOT NULL,                  -- 设备名称
    work_center_id      BIGINT,                                  -- 所属工作中心 ID → prd_work_center.id
    equipment_type      SMALLINT      NOT NULL DEFAULT 10,       -- 10:加工設備 20:検査設備 30:搬送 40:その他
    model_spec          VARCHAR(200),                            -- 型号/规格
    manufacturer        VARCHAR(200),                            -- 制造厂家
    serial_no           VARCHAR(64),                             -- 出厂编号
    purchase_date       DATE,                                    -- 购入日
    acquisition_cost    NUMERIC(18,2),                           -- 取得原价（元）
    rated_capacity      NUMERIC(18,4),                           -- 额定能力（capacity_uom 単位/日）
    capacity_uom        VARCHAR(16),                             -- 能力単位
    equipment_status    SMALLINT      NOT NULL DEFAULT 10,       -- 10:待機 20:稼動 30:故障 40:修理中 90:廃棄
    location            VARCHAR(100),                            -- 设置场所
    responsible_user_id BIGINT,                                  -- 设备责任人 → sys_user.id
    maintenance_cycle_days INT,                                  -- 点检周期（日）
    last_maintenance_date DATE,                                  -- 前回点検日
    next_maintenance_date DATE,                                  -- 次回点検予定日
    CONSTRAINT pk_prd_equipment PRIMARY KEY (id),
    CONSTRAINT fk_prd_equipment_wc FOREIGN KEY (work_center_id) REFERENCES prd_work_center (id),
    CONSTRAINT ck_prd_equipment_status CHECK (equipment_status IN (10,20,30,40,90))
);
ALTER TABLE prd_equipment ENABLE ROW LEVEL SECURITY;
ALTER TABLE prd_equipment FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON prd_equipment
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_prd_equipment_code ON prd_equipment (tenant_id, company_id, equipment_code) WHERE deleted = FALSE;
CREATE INDEX idx_prd_equipment_wc ON prd_equipment (company_id, work_center_id, equipment_status);
CREATE INDEX idx_prd_equipment_next_maintenance ON prd_equipment (company_id, next_maintenance_date) WHERE equipment_status <> 90;
COMMENT ON COLUMN prd_equipment.id IS '雪花 ID（主键）';
COMMENT ON COLUMN prd_equipment.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN prd_equipment.company_id IS '公司 ID（无默认值）';
COMMENT ON COLUMN prd_equipment.created_at IS '创建时间';
COMMENT ON COLUMN prd_equipment.created_by IS '创建人';
COMMENT ON COLUMN prd_equipment.updated_at IS '更新时间';
COMMENT ON COLUMN prd_equipment.updated_by IS '更新人';
COMMENT ON COLUMN prd_equipment.version IS '乐观锁版本';
COMMENT ON COLUMN prd_equipment.deleted IS '逻辑删除';
COMMENT ON COLUMN prd_equipment.remark IS '备注';
COMMENT ON COLUMN prd_equipment.ext_data IS '扩展字段';
COMMENT ON COLUMN prd_equipment.equipment_code IS '设备编号（EQ-001 等）';
COMMENT ON COLUMN prd_equipment.equipment_name IS '设备名称';
COMMENT ON COLUMN prd_equipment.work_center_id IS '所属工作中心 ID → prd_work_center.id';
COMMENT ON COLUMN prd_equipment.equipment_type IS '10:加工設備 20:検査設備 30:搬送 40:その他';
COMMENT ON COLUMN prd_equipment.model_spec IS '型号/规格';
COMMENT ON COLUMN prd_equipment.manufacturer IS '制造厂家';
COMMENT ON COLUMN prd_equipment.serial_no IS '出厂编号';
COMMENT ON COLUMN prd_equipment.purchase_date IS '购入日';
COMMENT ON COLUMN prd_equipment.acquisition_cost IS '取得原价（元）';
COMMENT ON COLUMN prd_equipment.rated_capacity IS '额定能力（capacity_uom 単位/日）';
COMMENT ON COLUMN prd_equipment.capacity_uom IS '能力単位';
COMMENT ON COLUMN prd_equipment.equipment_status IS '10:待機 20:稼動 30:故障 40:修理中 90:廃棄';
COMMENT ON COLUMN prd_equipment.location IS '设置场所';
COMMENT ON COLUMN prd_equipment.responsible_user_id IS '设备责任人 → sys_user.id';
COMMENT ON COLUMN prd_equipment.maintenance_cycle_days IS '点检周期（日）';
COMMENT ON COLUMN prd_equipment.last_maintenance_date IS '前回点検日';
COMMENT ON COLUMN prd_equipment.next_maintenance_date IS '次回点検予定日';

-- prd_equipment_maintenance
CREATE TABLE prd_equipment_maintenance (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    deleted             BOOLEAN       NOT NULL DEFAULT FALSE,
    remark              VARCHAR(500),
    ext_data            JSONB,
    maintenance_no      VARCHAR(32)   NOT NULL,                  -- 点检/维修单号（MT-{YYMMDD}-{4桁}）
    equipment_id        BIGINT        NOT NULL,                  -- 设备 ID → prd_equipment.id
    maintenance_type    SMALLINT      NOT NULL DEFAULT 10,       -- 10:点検 20:保养 30:维修 40:故障対応
    maintenance_date    DATE          NOT NULL,                  -- 実施日
    maintenance_status  SMALLINT      NOT NULL DEFAULT 10,       -- 10:予定 20:実施中 40:完了 90:取消
    fault_desc          VARCHAR(1000),                           -- 故障現象
    cause_desc          VARCHAR(1000),                           -- 原因
    measure_desc        VARCHAR(1000),                           -- 処置内容
    downtime_hours      NUMERIC(12,2) NOT NULL DEFAULT 0,        -- 停止時間（h）
    maintenance_cost    NUMERIC(18,2) NOT NULL DEFAULT 0,        -- 维修费用（元）
    operator_user_id    BIGINT,                                  -- 実施者 → sys_user.id
    next_maintenance_date DATE,                                  -- 次回予定日
    CONSTRAINT pk_prd_equipment_maintenance PRIMARY KEY (id),
    CONSTRAINT fk_prd_equipment_maintenance_eq FOREIGN KEY (equipment_id) REFERENCES prd_equipment (id),
    CONSTRAINT ck_prd_equipment_maintenance_type CHECK (maintenance_type IN (10,20,30,40))
);
ALTER TABLE prd_equipment_maintenance ENABLE ROW LEVEL SECURITY;
ALTER TABLE prd_equipment_maintenance FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON prd_equipment_maintenance
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_prd_equipment_maintenance_no ON prd_equipment_maintenance (tenant_id, company_id, maintenance_no) WHERE deleted = FALSE;
CREATE INDEX idx_prd_equipment_maintenance_eq_date ON prd_equipment_maintenance (company_id, equipment_id, maintenance_date DESC);
COMMENT ON COLUMN prd_equipment_maintenance.id IS '雪花 ID（主键）';
COMMENT ON COLUMN prd_equipment_maintenance.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN prd_equipment_maintenance.company_id IS '公司 ID（无默认值）';
COMMENT ON COLUMN prd_equipment_maintenance.created_at IS '创建时间';
COMMENT ON COLUMN prd_equipment_maintenance.created_by IS '创建人';
COMMENT ON COLUMN prd_equipment_maintenance.updated_at IS '更新时间';
COMMENT ON COLUMN prd_equipment_maintenance.updated_by IS '更新人';
COMMENT ON COLUMN prd_equipment_maintenance.version IS '乐观锁版本';
COMMENT ON COLUMN prd_equipment_maintenance.deleted IS '逻辑删除';
COMMENT ON COLUMN prd_equipment_maintenance.remark IS '备注';
COMMENT ON COLUMN prd_equipment_maintenance.ext_data IS '扩展字段';
COMMENT ON COLUMN prd_equipment_maintenance.maintenance_no IS '点检/维修单号（MT-{YYMMDD}-{4桁}）';
COMMENT ON COLUMN prd_equipment_maintenance.equipment_id IS '设备 ID → prd_equipment.id';
COMMENT ON COLUMN prd_equipment_maintenance.maintenance_type IS '10:点検 20:保养 30:维修 40:故障対応';
COMMENT ON COLUMN prd_equipment_maintenance.maintenance_date IS '実施日';
COMMENT ON COLUMN prd_equipment_maintenance.maintenance_status IS '10:予定 20:実施中 40:完了 90:取消';
COMMENT ON COLUMN prd_equipment_maintenance.fault_desc IS '故障現象';
COMMENT ON COLUMN prd_equipment_maintenance.cause_desc IS '原因';
COMMENT ON COLUMN prd_equipment_maintenance.measure_desc IS '処置内容';
COMMENT ON COLUMN prd_equipment_maintenance.downtime_hours IS '停止時間（h）';
COMMENT ON COLUMN prd_equipment_maintenance.maintenance_cost IS '维修费用（元）';
COMMENT ON COLUMN prd_equipment_maintenance.operator_user_id IS '実施者 → sys_user.id';
COMMENT ON COLUMN prd_equipment_maintenance.next_maintenance_date IS '次回予定日';

-- prd_material_planning
CREATE TABLE prd_material_planning (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    deleted             BOOLEAN       NOT NULL DEFAULT FALSE,
    remark              VARCHAR(500),
    ext_data            JSONB,
    material_id         BIGINT        NOT NULL,                  -- 物料 ID → mdm_material.id
    material_code       VARCHAR(64)   NOT NULL,                  -- 物料编码（スナップショット）
    material_name       VARCHAR(200)  NOT NULL,                  -- 物料名称（スナップショット）
    factory_id          BIGINT        NOT NULL,                  -- 工厂 ID → mdm_factory.id
    material_type       SMALLINT      NOT NULL,                  -- 10:采购品 20:制造品 30:委外品 40:虚拟件 50:外注部品
    low_level_code      SMALLINT      NOT NULL DEFAULT 0,        -- 低层码（0=最終製品。BAT-PRD-002 で計算）
    lead_time_days      SMALLINT      NOT NULL DEFAULT 0,        -- 采购提前期（日、material_type=10）
    production_lead_time_days SMALLINT NOT NULL DEFAULT 0,       -- 制造提前期（日、20/30）。工艺工时から算出可
    setup_days          SMALLINT      NOT NULL DEFAULT 0,        -- 准备日数（段取り・検査待ち）
    safety_stock_qty    NUMERIC(18,4) NOT NULL DEFAULT 0,        -- 安全库存量
    safety_stock_days   SMALLINT      NOT NULL DEFAULT 0,        -- 安全库存日数（需要日数換算）
    reorder_point_qty   NUMERIC(18,4) NOT NULL DEFAULT 0,        -- 再订货点（発注点）
    lot_sizing_rule     SMALLINT      NOT NULL DEFAULT 10,       -- 10:L4L 20:FOQ 30:最小-最大 40:周期発注 50:倍数切上
    lot_size            NUMERIC(18,4) NOT NULL DEFAULT 0,        -- 固定批量（FOQ 用）
    min_order_qty       NUMERIC(18,4) NOT NULL DEFAULT 0,        -- 最小起订量
    max_order_qty       NUMERIC(18,4),                           -- 最大订单量
    order_multiple      NUMERIC(18,4) NOT NULL DEFAULT 0,        -- 発注倍数（0=倍数制約なし）
    fixed_lead_time_days SMALLINT     NOT NULL DEFAULT 0,        -- 固定提前期（日）
    yield_rate          NUMERIC(7,4)  NOT NULL DEFAULT 1,        -- 良品率（0.9500 = 95%。必要投入量 = 净需求 ÷ 良品率）
    scrap_rate          NUMERIC(7,4)  NOT NULL DEFAULT 0,        -- 预定报废率（参考、BOM 损耗率と別管理）
    default_warehouse_id BIGINT,                                 -- 默认入库仓库 → mdm_warehouse.id
    default_work_center_id BIGINT,                               -- 默认工作中心 → prd_work_center.id
    mrp_planner_user_id BIGINT,                                  -- MRP 计划员 → sys_user.id
    is_mrp_planned      BOOLEAN       NOT NULL DEFAULT TRUE,     -- MRP 対象フラグ
    is_forecast_planned BOOLEAN       NOT NULL DEFAULT FALSE,    -- 预测展开対象（MTS 成品）
    planning_horizon_days SMALLINT    NOT NULL DEFAULT 90,       -- 品目別计划展望期（日）
    valid_from          DATE,                                    -- 参数有効開始日
    valid_to            DATE,                                    -- 参数有効終了日
    last_calculated_at  TIMESTAMPTZ,                             -- 低层码最終計算日時
    CONSTRAINT pk_prd_material_planning PRIMARY KEY (id),
    CONSTRAINT fk_prd_material_planning_material FOREIGN KEY (material_id) REFERENCES mdm_material (id),
    CONSTRAINT fk_prd_material_planning_factory FOREIGN KEY (factory_id) REFERENCES mdm_factory (id),
    CONSTRAINT ck_prd_material_planning_type CHECK (material_type IN (10,20,30,40,50)),
    CONSTRAINT ck_prd_material_planning_lot CHECK (lot_sizing_rule IN (10,20,30,40,50)),
    CONSTRAINT ck_prd_material_planning_llc CHECK (low_level_code >= 0),
    CONSTRAINT ck_prd_material_planning_yield CHECK (yield_rate > 0 AND yield_rate <= 1)
);
ALTER TABLE prd_material_planning ENABLE ROW LEVEL SECURITY;
ALTER TABLE prd_material_planning FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON prd_material_planning
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_prd_material_planning_mat_factory ON prd_material_planning (tenant_id, company_id, material_id, factory_id) WHERE deleted = FALSE;
CREATE INDEX idx_prd_material_planning_llc ON prd_material_planning (company_id, low_level_code, material_type);
CREATE INDEX idx_prd_material_planning_planner ON prd_material_planning (company_id, mrp_planner_user_id);
COMMENT ON COLUMN prd_material_planning.id IS '雪花 ID（主键）';
COMMENT ON COLUMN prd_material_planning.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN prd_material_planning.company_id IS '公司 ID（无默认值）';
COMMENT ON COLUMN prd_material_planning.created_at IS '创建时间';
COMMENT ON COLUMN prd_material_planning.created_by IS '创建人';
COMMENT ON COLUMN prd_material_planning.updated_at IS '更新时间';
COMMENT ON COLUMN prd_material_planning.updated_by IS '更新人';
COMMENT ON COLUMN prd_material_planning.version IS '乐观锁版本';
COMMENT ON COLUMN prd_material_planning.deleted IS '逻辑删除';
COMMENT ON COLUMN prd_material_planning.remark IS '备注';
COMMENT ON COLUMN prd_material_planning.ext_data IS '扩展字段';
COMMENT ON COLUMN prd_material_planning.material_id IS '物料 ID → mdm_material.id';
COMMENT ON COLUMN prd_material_planning.material_code IS '物料编码（スナップショット）';
COMMENT ON COLUMN prd_material_planning.material_name IS '物料名称（スナップショット）';
COMMENT ON COLUMN prd_material_planning.factory_id IS '工厂 ID → mdm_factory.id';
COMMENT ON COLUMN prd_material_planning.material_type IS '10:采购品 20:制造品 30:委外品 40:虚拟件 50:外注部品';
COMMENT ON COLUMN prd_material_planning.low_level_code IS '低层码（0=最終製品。BAT-PRD-002 で計算）';
COMMENT ON COLUMN prd_material_planning.lead_time_days IS '采购提前期（日、material_type=10）';
COMMENT ON COLUMN prd_material_planning.production_lead_time_days IS '制造提前期（日、20/30）。工艺工时から算出可';
COMMENT ON COLUMN prd_material_planning.setup_days IS '准备日数（段取り・検査待ち）';
COMMENT ON COLUMN prd_material_planning.safety_stock_qty IS '安全库存量';
COMMENT ON COLUMN prd_material_planning.safety_stock_days IS '安全库存日数（需要日数換算）';
COMMENT ON COLUMN prd_material_planning.reorder_point_qty IS '再订货点（発注点）';
COMMENT ON COLUMN prd_material_planning.lot_sizing_rule IS '10:L4L 20:FOQ 30:最小-最大 40:周期発注 50:倍数切上';
COMMENT ON COLUMN prd_material_planning.lot_size IS '固定批量（FOQ 用）';
COMMENT ON COLUMN prd_material_planning.min_order_qty IS '最小起订量';
COMMENT ON COLUMN prd_material_planning.max_order_qty IS '最大订单量';
COMMENT ON COLUMN prd_material_planning.order_multiple IS '発注倍数（0=倍数制約なし）';
COMMENT ON COLUMN prd_material_planning.fixed_lead_time_days IS '固定提前期（日）';
COMMENT ON COLUMN prd_material_planning.yield_rate IS '良品率（0.9500 = 95%。必要投入量 = 净需求 ÷ 良品率）';
COMMENT ON COLUMN prd_material_planning.scrap_rate IS '预定报废率（参考、BOM 损耗率と別管理）';
COMMENT ON COLUMN prd_material_planning.default_warehouse_id IS '默认入库仓库 → mdm_warehouse.id';
COMMENT ON COLUMN prd_material_planning.default_work_center_id IS '默认工作中心 → prd_work_center.id';
COMMENT ON COLUMN prd_material_planning.mrp_planner_user_id IS 'MRP 计划员 → sys_user.id';
COMMENT ON COLUMN prd_material_planning.is_mrp_planned IS 'MRP 対象フラグ';
COMMENT ON COLUMN prd_material_planning.is_forecast_planned IS '预测展开対象（MTS 成品）';
COMMENT ON COLUMN prd_material_planning.planning_horizon_days IS '品目別计划展望期（日）';
COMMENT ON COLUMN prd_material_planning.valid_from IS '参数有効開始日';
COMMENT ON COLUMN prd_material_planning.valid_to IS '参数有効終了日';
COMMENT ON COLUMN prd_material_planning.last_calculated_at IS '低层码最終計算日時';

-- prd_demand_forecast
CREATE TABLE prd_demand_forecast (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    remark              VARCHAR(500),
    ext_data            JSONB,
    forecast_no         VARCHAR(32)   NOT NULL,                  -- 预测编号 FC{YYMMDD}{4桁}
    version_no          SMALLINT      NOT NULL DEFAULT 1,        -- 版本号
    material_id         BIGINT        NOT NULL,                  -- 品目 ID → mdm_material.id
    material_code       VARCHAR(64)   NOT NULL,                  -- 品目编码
    factory_id          BIGINT        NOT NULL,                  -- 工厂 ID
    bucket_date         DATE          NOT NULL,                  -- 需求日（バケット開始日）
    bucket_type         SMALLINT      NOT NULL DEFAULT 10,       -- 10:日 20:週 30:月
    forecast_qty        NUMERIC(18,4) NOT NULL,                  -- 预测数量
    forecast_type       SMALLINT      NOT NULL DEFAULT 10,       -- 10:销售预测 20:生产计划 30:安全库存补充
    confidence_rate     NUMERIC(7,4)  NOT NULL DEFAULT 1,        -- 置信度（MRP 重み付け用、第一版）
    source_type         SMALLINT      NOT NULL DEFAULT 10,       -- 10:手工 20:销售预测取込 30:Excel 取込
    forecast_status     SMALLINT      NOT NULL DEFAULT 10,       -- 10:草稿 20:承認待ち 30:確定 90:取消
    approved_by         BIGINT,                                  -- 承認者
    approved_at         TIMESTAMPTZ,                             -- 承認日時
    CONSTRAINT pk_prd_demand_forecast PRIMARY KEY (id),
    CONSTRAINT fk_prd_demand_forecast_material FOREIGN KEY (material_id) REFERENCES mdm_material (id),
    CONSTRAINT ck_prd_demand_forecast_qty CHECK (forecast_qty >= 0)
);
ALTER TABLE prd_demand_forecast ENABLE ROW LEVEL SECURITY;
ALTER TABLE prd_demand_forecast FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON prd_demand_forecast
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_prd_demand_forecast_no ON prd_demand_forecast (tenant_id, company_id, forecast_no);
CREATE INDEX idx_prd_demand_forecast_mat_date ON prd_demand_forecast (company_id, material_id, bucket_date, forecast_status);
CREATE INDEX idx_prd_demand_forecast_run ON prd_demand_forecast (company_id, forecast_status, bucket_type);
COMMENT ON COLUMN prd_demand_forecast.id IS '雪花 ID（主键）';
COMMENT ON COLUMN prd_demand_forecast.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN prd_demand_forecast.company_id IS '公司 ID（无默认值）';
COMMENT ON COLUMN prd_demand_forecast.created_at IS '创建时间';
COMMENT ON COLUMN prd_demand_forecast.created_by IS '创建人';
COMMENT ON COLUMN prd_demand_forecast.updated_at IS '更新时间';
COMMENT ON COLUMN prd_demand_forecast.updated_by IS '更新人';
COMMENT ON COLUMN prd_demand_forecast.version IS '乐观锁版本';
COMMENT ON COLUMN prd_demand_forecast.remark IS '备注';
COMMENT ON COLUMN prd_demand_forecast.ext_data IS '扩展字段';
COMMENT ON COLUMN prd_demand_forecast.forecast_no IS '预测编号 FC{YYMMDD}{4桁}';
COMMENT ON COLUMN prd_demand_forecast.version_no IS '版本号';
COMMENT ON COLUMN prd_demand_forecast.material_id IS '品目 ID → mdm_material.id';
COMMENT ON COLUMN prd_demand_forecast.material_code IS '品目编码';
COMMENT ON COLUMN prd_demand_forecast.factory_id IS '工厂 ID';
COMMENT ON COLUMN prd_demand_forecast.bucket_date IS '需求日（バケット開始日）';
COMMENT ON COLUMN prd_demand_forecast.bucket_type IS '10:日 20:週 30:月';
COMMENT ON COLUMN prd_demand_forecast.forecast_qty IS '预测数量';
COMMENT ON COLUMN prd_demand_forecast.forecast_type IS '10:销售预测 20:生产计划 30:安全库存补充';
COMMENT ON COLUMN prd_demand_forecast.confidence_rate IS '置信度（MRP 重み付け用、第一版）';
COMMENT ON COLUMN prd_demand_forecast.source_type IS '10:手工 20:销售预测取込 30:Excel 取込';
COMMENT ON COLUMN prd_demand_forecast.forecast_status IS '10:草稿 20:承認待ち 30:確定 90:取消';
COMMENT ON COLUMN prd_demand_forecast.approved_by IS '承認者';
COMMENT ON COLUMN prd_demand_forecast.approved_at IS '承認日時';

-- prd_mps
CREATE TABLE prd_mps (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    remark              VARCHAR(500),
    ext_data            JSONB,
    mps_no              VARCHAR(32)   NOT NULL,                  -- MPS 编号 MPS{YYMM}{3桁}
    factory_id          BIGINT        NOT NULL,                  -- 工厂 ID
    period_code         VARCHAR(7)    NOT NULL,                  -- 期间 YYYY-MM
    mps_type            SMALLINT      NOT NULL DEFAULT 10,       -- 10:月度 20:周次
    version_no          SMALLINT      NOT NULL DEFAULT 1,        -- 版本号
    mps_status          SMALLINT      NOT NULL DEFAULT 10,       -- 10:草稿 20:承認待ち 30:確定 40:完了 90:取消
    approved_by         BIGINT,                                  -- 承認者
    approved_at         TIMESTAMPTZ,                             -- 承認日時
    published_at        TIMESTAMPTZ,                             -- 確定日時（MRP 参照可）
    CONSTRAINT pk_prd_mps PRIMARY KEY (id),
    CONSTRAINT fk_prd_mps_factory FOREIGN KEY (factory_id) REFERENCES mdm_factory (id),
    CONSTRAINT ck_prd_mps_status CHECK (mps_status IN (10,20,30,40,90))
);
ALTER TABLE prd_mps ENABLE ROW LEVEL SECURITY;
ALTER TABLE prd_mps FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON prd_mps
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_prd_mps_no ON prd_mps (tenant_id, company_id, mps_no);
CREATE UNIQUE INDEX uk_prd_mps_factory_period_ver ON prd_mps (tenant_id, company_id, factory_id, period_code, version_no);
COMMENT ON COLUMN prd_mps.id IS '雪花 ID（主键）';
COMMENT ON COLUMN prd_mps.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN prd_mps.company_id IS '公司 ID（无默认值）';
COMMENT ON COLUMN prd_mps.created_at IS '创建时间';
COMMENT ON COLUMN prd_mps.created_by IS '创建人';
COMMENT ON COLUMN prd_mps.updated_at IS '更新时间';
COMMENT ON COLUMN prd_mps.updated_by IS '更新人';
COMMENT ON COLUMN prd_mps.version IS '乐观锁版本';
COMMENT ON COLUMN prd_mps.remark IS '备注';
COMMENT ON COLUMN prd_mps.ext_data IS '扩展字段';
COMMENT ON COLUMN prd_mps.mps_no IS 'MPS 编号 MPS{YYMM}{3桁}';
COMMENT ON COLUMN prd_mps.factory_id IS '工厂 ID';
COMMENT ON COLUMN prd_mps.period_code IS '期间 YYYY-MM';
COMMENT ON COLUMN prd_mps.mps_type IS '10:月度 20:周次';
COMMENT ON COLUMN prd_mps.version_no IS '版本号';
COMMENT ON COLUMN prd_mps.mps_status IS '10:草稿 20:承認待ち 30:確定 40:完了 90:取消';
COMMENT ON COLUMN prd_mps.approved_by IS '承認者';
COMMENT ON COLUMN prd_mps.approved_at IS '承認日時';
COMMENT ON COLUMN prd_mps.published_at IS '確定日時（MRP 参照可）';

-- prd_mps_line
CREATE TABLE prd_mps_line (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    remark              VARCHAR(500),
    ext_data            JSONB,
    mps_id              BIGINT        NOT NULL,                  -- MPS ID → prd_mps.id
    line_no             INT           NOT NULL,                  -- 行番号
    material_id         BIGINT        NOT NULL,                  -- 品目 ID → mdm_material.id
    material_code       VARCHAR(64)   NOT NULL,                  -- 品目编码
    material_name       VARCHAR(200)  NOT NULL,                  -- 品目名称
    plan_date           DATE          NOT NULL,                  -- 计划日（週次的には週開始日）
    planned_qty         NUMERIC(18,4) NOT NULL DEFAULT 0,        -- 计划生产数量
    forecast_qty        NUMERIC(18,4) NOT NULL DEFAULT 0,        -- 其中：预测数量
    sales_order_qty     NUMERIC(18,4) NOT NULL DEFAULT 0,        -- 其中：受注数量（MTO）
    confirmed_qty       NUMERIC(18,4) NOT NULL DEFAULT 0,        -- 已确认数量（下达済工单集計）
    CONSTRAINT pk_prd_mps_line PRIMARY KEY (id),
    CONSTRAINT fk_prd_mps_line_mps FOREIGN KEY (mps_id) REFERENCES prd_mps (id) ON DELETE RESTRICT,
    CONSTRAINT fk_prd_mps_line_material FOREIGN KEY (material_id) REFERENCES mdm_material (id),
    CONSTRAINT ck_prd_mps_line_qty CHECK (planned_qty >= 0)
);
ALTER TABLE prd_mps_line ENABLE ROW LEVEL SECURITY;
ALTER TABLE prd_mps_line FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON prd_mps_line
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_prd_mps_line_mps_line ON prd_mps_line (company_id, mps_id, line_no);
CREATE INDEX idx_prd_mps_line_material_date ON prd_mps_line (company_id, material_id, plan_date);
COMMENT ON COLUMN prd_mps_line.id IS '雪花 ID（主键）';
COMMENT ON COLUMN prd_mps_line.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN prd_mps_line.company_id IS '公司 ID（无默认值）';
COMMENT ON COLUMN prd_mps_line.created_at IS '创建时间';
COMMENT ON COLUMN prd_mps_line.created_by IS '创建人';
COMMENT ON COLUMN prd_mps_line.updated_at IS '更新时间';
COMMENT ON COLUMN prd_mps_line.updated_by IS '更新人';
COMMENT ON COLUMN prd_mps_line.version IS '乐观锁版本';
COMMENT ON COLUMN prd_mps_line.remark IS '备注';
COMMENT ON COLUMN prd_mps_line.ext_data IS '扩展字段';
COMMENT ON COLUMN prd_mps_line.mps_id IS 'MPS ID → prd_mps.id';
COMMENT ON COLUMN prd_mps_line.line_no IS '行番号';
COMMENT ON COLUMN prd_mps_line.material_id IS '品目 ID → mdm_material.id';
COMMENT ON COLUMN prd_mps_line.material_code IS '品目编码';
COMMENT ON COLUMN prd_mps_line.material_name IS '品目名称';
COMMENT ON COLUMN prd_mps_line.plan_date IS '计划日（週次的には週開始日）';
COMMENT ON COLUMN prd_mps_line.planned_qty IS '计划生产数量';
COMMENT ON COLUMN prd_mps_line.forecast_qty IS '其中：预测数量';
COMMENT ON COLUMN prd_mps_line.sales_order_qty IS '其中：受注数量（MTO）';
COMMENT ON COLUMN prd_mps_line.confirmed_qty IS '已确认数量（下达済工单集計）';

-- prd_mrp_run
CREATE TABLE prd_mrp_run (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    mrp_run_no          VARCHAR(32)   NOT NULL,                  -- 运行编号 MRP{YYMMDD}{3桁}
    factory_id          BIGINT        NOT NULL,                  -- 对象工厂 ID
    run_type            SMALLINT      NOT NULL DEFAULT 10,       -- 10:全量 20:净变更 30:单品目 40:模拟
    run_date            DATE          NOT NULL,                  -- 运行基准日
    planning_horizon_days SMALLINT    NOT NULL DEFAULT 90,       -- 计划展望期（日）
    bucket_type         SMALLINT      NOT NULL DEFAULT 10,       -- 10:日 20:週
    include_forecast    BOOLEAN       NOT NULL DEFAULT TRUE,     -- 预测を需要源に含める
    include_safety_stock BOOLEAN      NOT NULL DEFAULT TRUE,     -- 安全库存を考慮
    include_sales_order BOOLEAN       NOT NULL DEFAULT TRUE,     -- 受注を需要源に含める
    run_status          SMALLINT      NOT NULL DEFAULT 10,       -- 10:実行中 40:完了 90:失敗 95:取消
    started_at          TIMESTAMPTZ,                             -- 開始日時
    finished_at         TIMESTAMPTZ,                             -- 終了日時
    run_by              BIGINT,                                  -- 実行者 → sys_user.id
    total_item_count    INT           NOT NULL DEFAULT 0,        -- 处理品目数
    demand_count        INT           NOT NULL DEFAULT 0,        -- 需求数
    plan_order_count    INT           NOT NULL DEFAULT 0,        -- 计划订单数
    action_count        INT           NOT NULL DEFAULT 0,        -- 动作消息数
    error_count         INT           NOT NULL DEFAULT 0,        -- エラー件数
    param_snapshot      JSONB,                                   -- 実行時パラメータ（再現用）
    log_message         TEXT,                                    -- 実行ログ（异常时）
    CONSTRAINT pk_prd_mrp_run PRIMARY KEY (id),
    CONSTRAINT fk_prd_mrp_run_factory FOREIGN KEY (factory_id) REFERENCES mdm_factory (id),
    CONSTRAINT ck_prd_mrp_run_status CHECK (run_status IN (10,40,90,95))
);
ALTER TABLE prd_mrp_run ENABLE ROW LEVEL SECURITY;
ALTER TABLE prd_mrp_run FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON prd_mrp_run
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_prd_mrp_run_no ON prd_mrp_run (tenant_id, company_id, mrp_run_no);
CREATE INDEX idx_prd_mrp_run_date ON prd_mrp_run (company_id, factory_id, run_date DESC, run_status);
COMMENT ON COLUMN prd_mrp_run.id IS '雪花 ID（主键）';
COMMENT ON COLUMN prd_mrp_run.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN prd_mrp_run.company_id IS '公司 ID（无默认值）';
COMMENT ON COLUMN prd_mrp_run.created_at IS '创建时间';
COMMENT ON COLUMN prd_mrp_run.created_by IS '创建人';
COMMENT ON COLUMN prd_mrp_run.mrp_run_no IS '运行编号 MRP{YYMMDD}{3桁}';
COMMENT ON COLUMN prd_mrp_run.factory_id IS '对象工厂 ID';
COMMENT ON COLUMN prd_mrp_run.run_type IS '10:全量 20:净变更 30:单品目 40:模拟';
COMMENT ON COLUMN prd_mrp_run.run_date IS '运行基准日';
COMMENT ON COLUMN prd_mrp_run.planning_horizon_days IS '计划展望期（日）';
COMMENT ON COLUMN prd_mrp_run.bucket_type IS '10:日 20:週';
COMMENT ON COLUMN prd_mrp_run.include_forecast IS '预测を需要源に含める';
COMMENT ON COLUMN prd_mrp_run.include_safety_stock IS '安全库存を考慮';
COMMENT ON COLUMN prd_mrp_run.include_sales_order IS '受注を需要源に含める';
COMMENT ON COLUMN prd_mrp_run.run_status IS '10:実行中 40:完了 90:失敗 95:取消';
COMMENT ON COLUMN prd_mrp_run.started_at IS '開始日時';
COMMENT ON COLUMN prd_mrp_run.finished_at IS '終了日時';
COMMENT ON COLUMN prd_mrp_run.run_by IS '実行者 → sys_user.id';
COMMENT ON COLUMN prd_mrp_run.total_item_count IS '处理品目数';
COMMENT ON COLUMN prd_mrp_run.demand_count IS '需求数';
COMMENT ON COLUMN prd_mrp_run.plan_order_count IS '计划订单数';
COMMENT ON COLUMN prd_mrp_run.action_count IS '动作消息数';
COMMENT ON COLUMN prd_mrp_run.error_count IS 'エラー件数';
COMMENT ON COLUMN prd_mrp_run.param_snapshot IS '実行時パラメータ（再現用）';
COMMENT ON COLUMN prd_mrp_run.log_message IS '実行ログ（异常时）';

-- prd_mrp_demand
CREATE TABLE prd_mrp_demand (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    mrp_run_id          BIGINT        NOT NULL,                  -- 运行 ID → prd_mrp_run.id
    material_id         BIGINT        NOT NULL,                  -- 品目 ID → mdm_material.id
    material_code       VARCHAR(64)   NOT NULL,                  -- 品目编码
    material_name       VARCHAR(200)  NOT NULL,                  -- 品目名称
    factory_id          BIGINT        NOT NULL,                  -- 工厂 ID
    bucket_date         DATE          NOT NULL,                  -- バケット日
    demand_type         SMALLINT      NOT NULL,                  -- 10:受注 20:预测 30:安全库存 40:工单子件 50:计划订单子件 60:委外子件 70:服务部品
    source_type         SMALLINT,                                -- 10:销售订单 20:预测 30:工单 40:计划订单 50:委外订单
    source_id           BIGINT,                                  -- 来源 ID
    source_no           VARCHAR(64),                             -- 来源单号
    low_level_code      SMALLINT      NOT NULL DEFAULT 0,        -- 低层码（展开順）
    bom_level           SMALLINT      NOT NULL DEFAULT 0,        -- BOM 展开层级
    gross_qty           NUMERIC(18,4) NOT NULL DEFAULT 0,        -- 毛需求
    on_hand_qty         NUMERIC(18,4) NOT NULL DEFAULT 0,        -- 现有库存（バケット開始時点）
    scheduled_receipt_qty NUMERIC(18,4) NOT NULL DEFAULT 0,      -- 入荷预定（PO/工单/委外）
    reserved_qty        NUMERIC(18,4) NOT NULL DEFAULT 0,        -- 引当済数量
    safety_stock_qty    NUMERIC(18,4) NOT NULL DEFAULT 0,        -- 安全库存
    net_qty             NUMERIC(18,4) NOT NULL DEFAULT 0,        -- 净需求（0 以上）
    projected_on_hand_qty NUMERIC(18,4) NOT NULL DEFAULT 0,      -- 预计库存（期末）
    shortage_flag       BOOLEAN       NOT NULL DEFAULT FALSE,    -- 欠品フラグ（预计库存 < 0）
    CONSTRAINT pk_prd_mrp_demand PRIMARY KEY (id),
    CONSTRAINT fk_prd_mrp_demand_run FOREIGN KEY (mrp_run_id) REFERENCES prd_mrp_run (id) ON DELETE RESTRICT,
    CONSTRAINT ck_prd_mrp_demand_type CHECK (demand_type IN (10,20,30,40,50,60,70))
);
ALTER TABLE prd_mrp_demand ENABLE ROW LEVEL SECURITY;
ALTER TABLE prd_mrp_demand FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON prd_mrp_demand
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE INDEX idx_prd_mrp_demand_run_mat ON prd_mrp_demand (company_id, mrp_run_id, material_id, bucket_date);
CREATE INDEX idx_prd_mrp_demand_run_type ON prd_mrp_demand (company_id, mrp_run_id, demand_type);
CREATE INDEX idx_prd_mrp_demand_run_shortage ON prd_mrp_demand (company_id, mrp_run_id, shortage_flag) WHERE shortage_flag = TRUE;
COMMENT ON COLUMN prd_mrp_demand.id IS '雪花 ID（主键）';
COMMENT ON COLUMN prd_mrp_demand.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN prd_mrp_demand.company_id IS '公司 ID（无默认值）';
COMMENT ON COLUMN prd_mrp_demand.created_at IS '创建时间';
COMMENT ON COLUMN prd_mrp_demand.created_by IS '创建人';
COMMENT ON COLUMN prd_mrp_demand.mrp_run_id IS '运行 ID → prd_mrp_run.id';
COMMENT ON COLUMN prd_mrp_demand.material_id IS '品目 ID → mdm_material.id';
COMMENT ON COLUMN prd_mrp_demand.material_code IS '品目编码';
COMMENT ON COLUMN prd_mrp_demand.material_name IS '品目名称';
COMMENT ON COLUMN prd_mrp_demand.factory_id IS '工厂 ID';
COMMENT ON COLUMN prd_mrp_demand.bucket_date IS 'バケット日';
COMMENT ON COLUMN prd_mrp_demand.demand_type IS '10:受注 20:预测 30:安全库存 40:工单子件 50:计划订单子件 60:委外子件 70:服务部品';
COMMENT ON COLUMN prd_mrp_demand.source_type IS '10:销售订单 20:预测 30:工单 40:计划订单 50:委外订单';
COMMENT ON COLUMN prd_mrp_demand.source_id IS '来源 ID';
COMMENT ON COLUMN prd_mrp_demand.source_no IS '来源单号';
COMMENT ON COLUMN prd_mrp_demand.low_level_code IS '低层码（展开順）';
COMMENT ON COLUMN prd_mrp_demand.bom_level IS 'BOM 展开层级';
COMMENT ON COLUMN prd_mrp_demand.gross_qty IS '毛需求';
COMMENT ON COLUMN prd_mrp_demand.on_hand_qty IS '现有库存（バケット開始時点）';
COMMENT ON COLUMN prd_mrp_demand.scheduled_receipt_qty IS '入荷预定（PO/工单/委外）';
COMMENT ON COLUMN prd_mrp_demand.reserved_qty IS '引当済数量';
COMMENT ON COLUMN prd_mrp_demand.safety_stock_qty IS '安全库存';
COMMENT ON COLUMN prd_mrp_demand.net_qty IS '净需求（0 以上）';
COMMENT ON COLUMN prd_mrp_demand.projected_on_hand_qty IS '预计库存（期末）';
COMMENT ON COLUMN prd_mrp_demand.shortage_flag IS '欠品フラグ（预计库存 < 0）';

-- prd_mrp_plan_order
CREATE TABLE prd_mrp_plan_order (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    remark              VARCHAR(500),
    ext_data            JSONB,
    mrp_run_id          BIGINT        NOT NULL,                  -- 运行 ID → prd_mrp_run.id
    plan_order_no       VARCHAR(40)   NOT NULL,                  -- 计划订单号 PO{YYMMDD}{6桁}（MRP 内仮番）
    material_id         BIGINT        NOT NULL,                  -- 品目 ID → mdm_material.id
    material_code       VARCHAR(64)   NOT NULL,                  -- 品目编码
    material_name       VARCHAR(200)  NOT NULL,                  -- 品目名称
    factory_id          BIGINT        NOT NULL,                  -- 工厂 ID
    order_type          SMALLINT      NOT NULL,                  -- 10:采购 20:制造 30:委外
    bom_level           SMALLINT      NOT NULL DEFAULT 0,        -- BOM 层级
    bucket_date         DATE          NOT NULL,                  -- 需求バケット日
    due_date            DATE          NOT NULL,                  -- 需求日（現品必要日）
    start_date          DATE          NOT NULL,                  -- 着手日/発注日（提前期逆算）
    order_qty           NUMERIC(18,4) NOT NULL,                  -- 订单数量（批量规则適用後）
    net_qty             NUMERIC(18,4) NOT NULL,                  -- 元の净需求
    lot_sizing_rule     SMALLINT      NOT NULL DEFAULT 10,       -- 适用批量规则（実行時スナップショット）
    safety_stock_qty    NUMERIC(18,4) NOT NULL DEFAULT 0,        -- 考虑安全库存
    lead_time_days      SMALLINT      NOT NULL DEFAULT 0,        -- 适用提前期（日）
    plan_status         SMALLINT      NOT NULL DEFAULT 10,       -- 10:提案 20:確認済 25:承認済 30:展開済 40:完了 90:取消
    parent_plan_order_id BIGINT,                                 -- 親计划订单 ID（多阶展开系譜）
    source_demand_id    BIGINT,                                  -- 源泉需求 ID → prd_mrp_demand.id
    confirmed_by        BIGINT,                                  -- 確認者 → sys_user.id
    confirmed_at        TIMESTAMPTZ,                             -- 確認日時
    converted_doc_type  SMALLINT,                                -- 10:工单 20:请购 30:委外订单
    converted_doc_id    BIGINT,                                  -- 転送先 ID
    converted_doc_no    VARCHAR(64),                             -- 転送先单号
    CONSTRAINT pk_prd_mrp_plan_order PRIMARY KEY (id),
    CONSTRAINT fk_prd_mrp_plan_order_run FOREIGN KEY (mrp_run_id) REFERENCES prd_mrp_run (id) ON DELETE RESTRICT,
    CONSTRAINT ck_prd_mrp_plan_order_type CHECK (order_type IN (10,20,30)),
    CONSTRAINT ck_prd_mrp_plan_order_qty CHECK (order_qty > 0),
    CONSTRAINT ck_prd_mrp_plan_order_date CHECK (start_date <= due_date)
);
ALTER TABLE prd_mrp_plan_order ENABLE ROW LEVEL SECURITY;
ALTER TABLE prd_mrp_plan_order FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON prd_mrp_plan_order
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_prd_mrp_plan_order_no ON prd_mrp_plan_order (tenant_id, company_id, plan_order_no);
CREATE INDEX idx_prd_mrp_plan_order_run_mat ON prd_mrp_plan_order (company_id, mrp_run_id, material_id, due_date);
CREATE INDEX idx_prd_mrp_plan_order_status ON prd_mrp_plan_order (company_id, plan_status, start_date);
CREATE INDEX idx_prd_mrp_plan_order_converted ON prd_mrp_plan_order (company_id, converted_doc_type, converted_doc_id);
COMMENT ON COLUMN prd_mrp_plan_order.id IS '雪花 ID（主键）';
COMMENT ON COLUMN prd_mrp_plan_order.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN prd_mrp_plan_order.company_id IS '公司 ID（无默认值）';
COMMENT ON COLUMN prd_mrp_plan_order.created_at IS '创建时间';
COMMENT ON COLUMN prd_mrp_plan_order.created_by IS '创建人';
COMMENT ON COLUMN prd_mrp_plan_order.updated_at IS '更新时间';
COMMENT ON COLUMN prd_mrp_plan_order.updated_by IS '更新人';
COMMENT ON COLUMN prd_mrp_plan_order.version IS '乐观锁版本';
COMMENT ON COLUMN prd_mrp_plan_order.remark IS '备注';
COMMENT ON COLUMN prd_mrp_plan_order.ext_data IS '扩展字段';
COMMENT ON COLUMN prd_mrp_plan_order.mrp_run_id IS '运行 ID → prd_mrp_run.id';
COMMENT ON COLUMN prd_mrp_plan_order.plan_order_no IS '计划订单号 PO{YYMMDD}{6桁}（MRP 内仮番）';
COMMENT ON COLUMN prd_mrp_plan_order.material_id IS '品目 ID → mdm_material.id';
COMMENT ON COLUMN prd_mrp_plan_order.material_code IS '品目编码';
COMMENT ON COLUMN prd_mrp_plan_order.material_name IS '品目名称';
COMMENT ON COLUMN prd_mrp_plan_order.factory_id IS '工厂 ID';
COMMENT ON COLUMN prd_mrp_plan_order.order_type IS '10:采购 20:制造 30:委外';
COMMENT ON COLUMN prd_mrp_plan_order.bom_level IS 'BOM 层级';
COMMENT ON COLUMN prd_mrp_plan_order.bucket_date IS '需求バケット日';
COMMENT ON COLUMN prd_mrp_plan_order.due_date IS '需求日（現品必要日）';
COMMENT ON COLUMN prd_mrp_plan_order.start_date IS '着手日/発注日（提前期逆算）';
COMMENT ON COLUMN prd_mrp_plan_order.order_qty IS '订单数量（批量规则適用後）';
COMMENT ON COLUMN prd_mrp_plan_order.net_qty IS '元の净需求';
COMMENT ON COLUMN prd_mrp_plan_order.lot_sizing_rule IS '适用批量规则（実行時スナップショット）';
COMMENT ON COLUMN prd_mrp_plan_order.safety_stock_qty IS '考虑安全库存';
COMMENT ON COLUMN prd_mrp_plan_order.lead_time_days IS '适用提前期（日）';
COMMENT ON COLUMN prd_mrp_plan_order.plan_status IS '10:提案 20:確認済 25:承認済 30:展開済 40:完了 90:取消';
COMMENT ON COLUMN prd_mrp_plan_order.parent_plan_order_id IS '親计划订单 ID（多阶展开系譜）';
COMMENT ON COLUMN prd_mrp_plan_order.source_demand_id IS '源泉需求 ID → prd_mrp_demand.id';
COMMENT ON COLUMN prd_mrp_plan_order.confirmed_by IS '確認者 → sys_user.id';
COMMENT ON COLUMN prd_mrp_plan_order.confirmed_at IS '確認日時';
COMMENT ON COLUMN prd_mrp_plan_order.converted_doc_type IS '10:工单 20:请购 30:委外订单';
COMMENT ON COLUMN prd_mrp_plan_order.converted_doc_id IS '転送先 ID';
COMMENT ON COLUMN prd_mrp_plan_order.converted_doc_no IS '転送先单号';

-- prd_mrp_action
CREATE TABLE prd_mrp_action (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    mrp_run_id          BIGINT        NOT NULL,                  -- 运行 ID → prd_mrp_run.id
    action_type         SMALLINT      NOT NULL,                  -- 10:発注 20:製造 30:取消 40:延期 50:提前 60:增量 70:减量 80:安全库存不足
    material_id         BIGINT        NOT NULL,                  -- 品目 ID → mdm_material.id
    material_code       VARCHAR(64)   NOT NULL,                  -- 品目编码
    material_name       VARCHAR(200)  NOT NULL,                  -- 品目名称
    factory_id          BIGINT        NOT NULL,                  -- 工厂 ID
    plan_order_id       BIGINT,                                  -- 由来计划订单 ID → prd_mrp_plan_order.id
    ref_doc_type        SMALLINT,                                -- 参照先種別 10:采购订单 20:工单 30:委外订单 40:请购 50:计划订单
    ref_doc_id          BIGINT,                                  -- 参照先 ID
    ref_doc_no          VARCHAR(64),                             -- 参照先单号
    "current_date"      DATE,  -- 保留字，设计书列名原样加引号（待设计书改名）                                    -- 现日期（延期/提前の対象）
    suggested_date      DATE,                                    -- 建议日期
    current_qty         NUMERIC(18,4),                           -- 现数量
    suggested_qty       NUMERIC(18,4),                           -- 建议数量
    action_message      VARCHAR(500)  NOT NULL,                  -- 表示用メッセージ（例：発注日を 2026-11-05 に前倒し）
    action_status       SMALLINT      NOT NULL DEFAULT 10,       -- 10:未処理 20:確認済 30:無視 40:実施済
    processed_by        BIGINT,                                  -- 処理者 → sys_user.id
    processed_at        TIMESTAMPTZ,                             -- 処理日時
    CONSTRAINT pk_prd_mrp_action PRIMARY KEY (id),
    CONSTRAINT fk_prd_mrp_action_run FOREIGN KEY (mrp_run_id) REFERENCES prd_mrp_run (id) ON DELETE RESTRICT,
    CONSTRAINT ck_prd_mrp_action_type CHECK (action_type IN (10,20,30,40,50,60,70,80))
);
ALTER TABLE prd_mrp_action ENABLE ROW LEVEL SECURITY;
ALTER TABLE prd_mrp_action FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON prd_mrp_action
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE INDEX idx_prd_mrp_action_run_type ON prd_mrp_action (company_id, mrp_run_id, action_type, action_status);
CREATE INDEX idx_prd_mrp_action_ref ON prd_mrp_action (company_id, ref_doc_type, ref_doc_id);
CREATE INDEX idx_prd_mrp_action_material ON prd_mrp_action (company_id, material_id, action_status);
COMMENT ON COLUMN prd_mrp_action.id IS '雪花 ID（主键）';
COMMENT ON COLUMN prd_mrp_action.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN prd_mrp_action.company_id IS '公司 ID（无默认值）';
COMMENT ON COLUMN prd_mrp_action.created_at IS '创建时间';
COMMENT ON COLUMN prd_mrp_action.created_by IS '创建人';
COMMENT ON COLUMN prd_mrp_action.mrp_run_id IS '运行 ID → prd_mrp_run.id';
COMMENT ON COLUMN prd_mrp_action.action_type IS '10:発注 20:製造 30:取消 40:延期 50:提前 60:增量 70:减量 80:安全库存不足';
COMMENT ON COLUMN prd_mrp_action.material_id IS '品目 ID → mdm_material.id';
COMMENT ON COLUMN prd_mrp_action.material_code IS '品目编码';
COMMENT ON COLUMN prd_mrp_action.material_name IS '品目名称';
COMMENT ON COLUMN prd_mrp_action.factory_id IS '工厂 ID';
COMMENT ON COLUMN prd_mrp_action.plan_order_id IS '由来计划订单 ID → prd_mrp_plan_order.id';
COMMENT ON COLUMN prd_mrp_action.ref_doc_type IS '参照先種別 10:采购订单 20:工单 30:委外订单 40:请购 50:计划订单';
COMMENT ON COLUMN prd_mrp_action.ref_doc_id IS '参照先 ID';
COMMENT ON COLUMN prd_mrp_action.ref_doc_no IS '参照先单号';
COMMENT ON COLUMN prd_mrp_action.suggested_date IS '建议日期';
COMMENT ON COLUMN prd_mrp_action.current_qty IS '现数量';
COMMENT ON COLUMN prd_mrp_action.suggested_qty IS '建议数量';
COMMENT ON COLUMN prd_mrp_action.action_message IS '表示用メッセージ（例：発注日を 2026-11-05 に前倒し）';
COMMENT ON COLUMN prd_mrp_action.action_status IS '10:未処理 20:確認済 30:無視 40:実施済';
COMMENT ON COLUMN prd_mrp_action.processed_by IS '処理者 → sys_user.id';
COMMENT ON COLUMN prd_mrp_action.processed_at IS '処理日時';

-- prd_work_order
CREATE TABLE prd_work_order (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    remark              VARCHAR(500),
    ext_data            JSONB,
    work_order_no       VARCHAR(32)   NOT NULL,                  -- 工单号 WO{YYMMDD}{4桁}（08 2.1）
    work_order_type     SMALLINT      NOT NULL DEFAULT 10,       -- 10:量产 20:试制 30:返工 40:拆分/合并生成
    material_id         BIGINT        NOT NULL,                  -- 制造品物料 ID → mdm_material.id
    material_code       VARCHAR(64)   NOT NULL,                  -- 制造品物料编码（スナップショット）
    material_name       VARCHAR(200)  NOT NULL,                  -- 制造品物料名称（スナップショット）
    material_spec       VARCHAR(200),                            -- 制造品规格（スナップショット）
    uom_code            VARCHAR(16)   NOT NULL,                  -- 单位（PCE）
    factory_id          BIGINT        NOT NULL,                  -- 工厂 ID → mdm_factory.id
    department_id       BIGINT,                                  -- 制造部门 ID → sys_department.id
    warehouse_id        BIGINT,                                  -- 完工入库仓库 ID → mdm_warehouse.id
    order_qty           NUMERIC(18,4) NOT NULL,                  -- 注文数量（物料基本単位）
    completed_qty       NUMERIC(18,4) NOT NULL DEFAULT 0,        -- 完工入库良品累計（物料基本単位）
    allowed_qty         NUMERIC(18,4),                           -- 許容完工上限（基本単位。MTO は受注行からスナップショット）
    reported_good_qty   NUMERIC(18,4) NOT NULL DEFAULT 0,        -- 報工良品累計
    reported_defect_qty NUMERIC(18,4) NOT NULL DEFAULT 0,        -- 報工不良累計
    scrapped_qty        NUMERIC(18,4) NOT NULL DEFAULT 0,        -- 報工报废累計
    progress_rate       NUMERIC(7,4)  NOT NULL DEFAULT 0,        -- 進捗率（表示用）
    planned_start_date  DATE          NOT NULL,                  -- 计划着手日
    planned_end_date    DATE          NOT NULL,                  -- 计划完成日（納期）
    actual_start_date   DATE,                                    -- 実績着手日（初回報工日）
    actual_end_date     DATE,                                    -- 実績完成日（最終完工入库日）
    order_status        SMALLINT      NOT NULL DEFAULT 10,       -- 10:草稿 20:承認待ち 25:承認済 30:下达済 35:製造中 40:完工（closed_at で結案・終端） 90:取消 95:却下
    material_issue_status SMALLINT    NOT NULL DEFAULT 0,        -- 材料引当/領料状態 0:未 10:一部 20:完了
    report_status       SMALLINT      NOT NULL DEFAULT 0,        -- 報工状態 0:未 10:一部 20:完了
    completion_status   SMALLINT      NOT NULL DEFAULT 0,        -- 入庫状態 0:未 10:一部 20:完了
    inspection_status   SMALLINT      NOT NULL DEFAULT 10,       -- 10:起票 20:検査中 30:判定確定 90:取消
    priority_no         SMALLINT      NOT NULL DEFAULT 5,        -- 优先度 1(最高)〜9(最低)
    sales_order_id      BIGINT,                                  -- 受注 ID → sal_sales_order.id（MTO）
    sales_order_line_id BIGINT,                                  -- 受注明細 ID → sal_sales_order_line.id（MTO。G2-18 / backend #47）
    sales_order_no      VARCHAR(32),                             -- 受注番号（スナップショット）
    customer_id         BIGINT,                                  -- 顧客 ID → mdm_customer.id
    bom_id              BIGINT,                                  -- 適用 BOM ID → prd_bom.id（展開時スナップショット）
    bom_no              VARCHAR(32),                             -- 適用 BOM 编号
    routing_id          BIGINT,                                  -- 適用工艺路线 ID → prd_routing.id
    routing_no          VARCHAR(40),                             -- 適用工艺路线编号
    source_type         SMALLINT      NOT NULL DEFAULT 20,       -- 10:MRP计划订单 20:手工 30:受注 40:拆分 50:合并 60:返工NCR 70:MPS
    source_id           BIGINT,                                  -- 来源 ID
    source_no           VARCHAR(64),                             -- 来源单号
    parent_work_order_id BIGINT,                                 -- 親工单 ID（多阶製造）
    root_work_order_id  BIGINT,                                  -- 最上位工单 ID（追溯用）
    is_backflush        BOOLEAN       NOT NULL DEFAULT FALSE,    -- 倒冲工单フラグ
    over_receipt_rate   NUMERIC(5,4)  NOT NULL DEFAULT 0.05,     -- 完工超収容差スナップショット（比率 NUMERIC(5,4)。チェーン：受注行>物料>分類>会社 sys_param key prd.completion_over_rate）
    over_report_rate    NUMERIC(5,4)  NOT NULL DEFAULT 0.05,     -- 超報工容差（比率 NUMERIC(5,4)）
    is_hold             BOOLEAN       NOT NULL DEFAULT FALSE,    -- 保留フラグ（工程異常・品質問題）
    hold_reason         VARCHAR(500),                            -- 保留理由
    standard_cost       NUMERIC(18,6),                           -- 標準単位原価スナップショット（既定値なし・NULL 可）。下达時に fin_standard_cost の発行済み版（status=40、当該期間）の total_unit_cost を複写。版なしは NULL（PR #8 決定 2（蓝色大肥鱼 2026-10-21））
    actual_material_cost NUMERIC(18,2) NOT NULL DEFAULT 0,       -- 実績材料費（E22/E36 と E18 の累計）
    actual_labor_cost   NUMERIC(18,2) NOT NULL DEFAULT 0,        -- 実績人工費（E23 累計）
    actual_overhead_cost NUMERIC(18,2) NOT NULL DEFAULT 0,       -- 配賦製造費用（月結で確定）
    actual_total_cost   NUMERIC(18,2) NOT NULL DEFAULT 0,        -- 実績完工原価合計
    cost_variance       NUMERIC(18,2) NOT NULL DEFAULT 0,        -- 原価差異（実際 − 標準×数量）。standard_cost IS NULL（標準原価未設定）時は 0 のままだが「差異 0」ではない。判定は必ず standard_cost IS NULL で行う
    cost_status         SMALLINT      NOT NULL DEFAULT 0,        -- 原価状態 0:未帰集 10:暫定 20:確定（FIN 月結）
    submitted_at        TIMESTAMPTZ,                             -- 承認提出日時
    approved_by         BIGINT,                                  -- 承認者 → sys_user.id
    approved_at         TIMESTAMPTZ,                             -- 承認日時
    released_by         BIGINT,                                  -- 下达者
    released_at         TIMESTAMPTZ,                             -- 下达日時（E21 発行）
    closed_by           BIGINT,                                  -- 結案者
    closed_at           TIMESTAMPTZ,                             -- 結案日時
    close_reason        VARCHAR(500),                            -- 結案理由
    cancel_reason       VARCHAR(500),                            -- 取消理由
    wip_cost            NUMERIC(18,2) NOT NULL DEFAULT 0,        -- 在制品残高（月末結転用）
    CONSTRAINT pk_prd_work_order PRIMARY KEY (id),
    CONSTRAINT fk_prd_work_order_material FOREIGN KEY (material_id) REFERENCES mdm_material (id),
    CONSTRAINT fk_prd_work_order_factory FOREIGN KEY (factory_id) REFERENCES mdm_factory (id),
    CONSTRAINT fk_prd_work_order_bom FOREIGN KEY (bom_id) REFERENCES prd_bom (id),
    CONSTRAINT fk_prd_work_order_routing FOREIGN KEY (routing_id) REFERENCES prd_routing (id),
    CONSTRAINT ck_prd_work_order_status CHECK (order_status IN (10,20,25,30,35,40,90,95)),
    CONSTRAINT ck_prd_work_order_qty CHECK (order_qty > 0 AND completed_qty >= 0 AND scrapped_qty >= 0),
    CONSTRAINT ck_prd_work_order_date CHECK (planned_end_date >= planned_start_date),
    CONSTRAINT ck_prd_work_order_rate CHECK (over_receipt_rate >= 0 AND over_report_rate >= 0)
);
ALTER TABLE prd_work_order ENABLE ROW LEVEL SECURITY;
ALTER TABLE prd_work_order FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON prd_work_order
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_prd_work_order_no ON prd_work_order (tenant_id, company_id, work_order_no);
CREATE INDEX idx_prd_work_order_status_date ON prd_work_order (tenant_id, company_id, factory_id, order_status, planned_end_date);
CREATE INDEX idx_prd_work_order_material ON prd_work_order (tenant_id, company_id, material_id, order_status);
CREATE INDEX idx_prd_work_order_sales ON prd_work_order (tenant_id, company_id, sales_order_id) WHERE sales_order_id IS NOT NULL;
CREATE INDEX idx_prd_work_order_so_line ON prd_work_order (tenant_id, company_id, sales_order_line_id) WHERE sales_order_line_id IS NOT NULL;
CREATE INDEX idx_prd_work_order_parent ON prd_work_order (tenant_id, company_id, parent_work_order_id) WHERE parent_work_order_id IS NOT NULL;
CREATE INDEX idx_prd_work_order_source ON prd_work_order (tenant_id, company_id, source_type, source_id);
COMMENT ON COLUMN prd_work_order.id IS '雪花 ID（主键）';
COMMENT ON COLUMN prd_work_order.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN prd_work_order.company_id IS '公司 ID（无默认值）';
COMMENT ON COLUMN prd_work_order.created_at IS '创建时间';
COMMENT ON COLUMN prd_work_order.created_by IS '创建人';
COMMENT ON COLUMN prd_work_order.updated_at IS '更新时间';
COMMENT ON COLUMN prd_work_order.updated_by IS '更新人';
COMMENT ON COLUMN prd_work_order.version IS '乐观锁版本';
COMMENT ON COLUMN prd_work_order.remark IS '备注';
COMMENT ON COLUMN prd_work_order.ext_data IS '扩展字段';
COMMENT ON COLUMN prd_work_order.work_order_no IS '工单号 WO{YYMMDD}{4桁}（08 2.1）';
COMMENT ON COLUMN prd_work_order.work_order_type IS '10:量产 20:试制 30:返工 40:拆分/合并生成';
COMMENT ON COLUMN prd_work_order.material_id IS '制造品物料 ID → mdm_material.id';
COMMENT ON COLUMN prd_work_order.material_code IS '制造品物料编码（スナップショット）';
COMMENT ON COLUMN prd_work_order.material_name IS '制造品物料名称（スナップショット）';
COMMENT ON COLUMN prd_work_order.material_spec IS '制造品规格（スナップショット）';
COMMENT ON COLUMN prd_work_order.uom_code IS '单位（PCE）';
COMMENT ON COLUMN prd_work_order.factory_id IS '工厂 ID → mdm_factory.id';
COMMENT ON COLUMN prd_work_order.department_id IS '制造部门 ID → sys_department.id';
COMMENT ON COLUMN prd_work_order.warehouse_id IS '完工入库仓库 ID → mdm_warehouse.id';
COMMENT ON COLUMN prd_work_order.order_qty IS '注文数量（物料基本単位）';
COMMENT ON COLUMN prd_work_order.completed_qty IS '完工入库良品累計（物料基本単位）';
COMMENT ON COLUMN prd_work_order.allowed_qty IS '許容完工上限（基本単位。MTO は受注行からスナップショット）';
COMMENT ON COLUMN prd_work_order.reported_good_qty IS '報工良品累計';
COMMENT ON COLUMN prd_work_order.reported_defect_qty IS '報工不良累計';
COMMENT ON COLUMN prd_work_order.scrapped_qty IS '報工报废累計';
COMMENT ON COLUMN prd_work_order.progress_rate IS '進捗率（表示用）';
COMMENT ON COLUMN prd_work_order.planned_start_date IS '计划着手日';
COMMENT ON COLUMN prd_work_order.planned_end_date IS '计划完成日（納期）';
COMMENT ON COLUMN prd_work_order.actual_start_date IS '実績着手日（初回報工日）';
COMMENT ON COLUMN prd_work_order.actual_end_date IS '実績完成日（最終完工入库日）';
COMMENT ON COLUMN prd_work_order.order_status IS '10:草稿 20:承認待ち 25:承認済 30:下达済 35:製造中 40:完工（closed_at で結案・終端） 90:取消 95:却下';
COMMENT ON COLUMN prd_work_order.material_issue_status IS '材料引当/領料状態 0:未 10:一部 20:完了';
COMMENT ON COLUMN prd_work_order.report_status IS '報工状態 0:未 10:一部 20:完了';
COMMENT ON COLUMN prd_work_order.completion_status IS '入庫状態 0:未 10:一部 20:完了';
COMMENT ON COLUMN prd_work_order.inspection_status IS '10:起票 20:検査中 30:判定確定 90:取消';
COMMENT ON COLUMN prd_work_order.priority_no IS '优先度 1(最高)〜9(最低)';
COMMENT ON COLUMN prd_work_order.sales_order_id IS '受注 ID → sal_sales_order.id（MTO）';
COMMENT ON COLUMN prd_work_order.sales_order_line_id IS '受注明細 ID → sal_sales_order_line.id（MTO。G2-18 / backend #47）';
COMMENT ON COLUMN prd_work_order.sales_order_no IS '受注番号（スナップショット）';
COMMENT ON COLUMN prd_work_order.customer_id IS '顧客 ID → mdm_customer.id';
COMMENT ON COLUMN prd_work_order.bom_id IS '適用 BOM ID → prd_bom.id（展開時スナップショット）';
COMMENT ON COLUMN prd_work_order.bom_no IS '適用 BOM 编号';
COMMENT ON COLUMN prd_work_order.routing_id IS '適用工艺路线 ID → prd_routing.id';
COMMENT ON COLUMN prd_work_order.routing_no IS '適用工艺路线编号';
COMMENT ON COLUMN prd_work_order.source_type IS '10:MRP计划订单 20:手工 30:受注 40:拆分 50:合并 60:返工NCR 70:MPS';
COMMENT ON COLUMN prd_work_order.source_id IS '来源 ID';
COMMENT ON COLUMN prd_work_order.source_no IS '来源单号';
COMMENT ON COLUMN prd_work_order.parent_work_order_id IS '親工单 ID（多阶製造）';
COMMENT ON COLUMN prd_work_order.root_work_order_id IS '最上位工单 ID（追溯用）';
COMMENT ON COLUMN prd_work_order.is_backflush IS '倒冲工单フラグ';
COMMENT ON COLUMN prd_work_order.over_receipt_rate IS '完工超収容差スナップショット（比率 NUMERIC(5,4)。チェーン：受注行>物料>分類>会社 sys_param key prd.completion_over_rate）';
COMMENT ON COLUMN prd_work_order.over_report_rate IS '超報工容差（比率 NUMERIC(5,4)）';
COMMENT ON COLUMN prd_work_order.is_hold IS '保留フラグ（工程異常・品質問題）';
COMMENT ON COLUMN prd_work_order.hold_reason IS '保留理由';
COMMENT ON COLUMN prd_work_order.standard_cost IS '標準単位原価スナップショット（既定値なし・NULL 可）。下达時に fin_standard_cost の発行済み版（status=40、当該期間）の total_unit_cost を複写。版なしは NULL（PR #8 決定 2（蓝色大肥鱼 2026-10-21））';
COMMENT ON COLUMN prd_work_order.actual_material_cost IS '実績材料費（E22/E36 と E18 の累計）';
COMMENT ON COLUMN prd_work_order.actual_labor_cost IS '実績人工費（E23 累計）';
COMMENT ON COLUMN prd_work_order.actual_overhead_cost IS '配賦製造費用（月結で確定）';
COMMENT ON COLUMN prd_work_order.actual_total_cost IS '実績完工原価合計';
COMMENT ON COLUMN prd_work_order.cost_variance IS '原価差異（実際 − 標準×数量）。standard_cost IS NULL（標準原価未設定）時は 0 のままだが「差異 0」ではない。判定は必ず standard_cost IS NULL で行う';
COMMENT ON COLUMN prd_work_order.cost_status IS '原価状態 0:未帰集 10:暫定 20:確定（FIN 月結）';
COMMENT ON COLUMN prd_work_order.submitted_at IS '承認提出日時';
COMMENT ON COLUMN prd_work_order.approved_by IS '承認者 → sys_user.id';
COMMENT ON COLUMN prd_work_order.approved_at IS '承認日時';
COMMENT ON COLUMN prd_work_order.released_by IS '下达者';
COMMENT ON COLUMN prd_work_order.released_at IS '下达日時（E21 発行）';
COMMENT ON COLUMN prd_work_order.closed_by IS '結案者';
COMMENT ON COLUMN prd_work_order.closed_at IS '結案日時';
COMMENT ON COLUMN prd_work_order.close_reason IS '結案理由';
COMMENT ON COLUMN prd_work_order.cancel_reason IS '取消理由';
COMMENT ON COLUMN prd_work_order.wip_cost IS '在制品残高（月末結転用）';

-- prd_overproduction_approval
CREATE TABLE prd_overproduction_approval (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    remark              VARCHAR(500),
    ext_data            JSONB,
    approval_no         VARCHAR(32)   NOT NULL,                  -- 超産承認番号 OPA{YYMMDD}{4桁}
    sales_order_id      BIGINT        NOT NULL,                  -- 受注 ID → sal_sales_order.id
    sales_order_line_id BIGINT        NOT NULL,                  -- 受注明細 ID → sal_sales_order_line.id
    work_order_id       BIGINT,                                  -- 対象工单（任意。NULL＝受注行全体）
    material_id         BIGINT        NOT NULL,                  -- 品目（受注行と一致必須）
    request_qty         NUMERIC(18,4) NOT NULL,                  -- 申請超産増分 delta（基本単位、> 0）。総量ではない
    current_allowed_qty NUMERIC(18,4) NOT NULL,                  -- 申請時点の受注行 allowed_qty（基本単位、スナップショット）
    approved_allowed_qty NUMERIC(18,4),                          -- 承認後の受注行新上限（= 承認時点の受注行 allowed_qty + request_qty。スナップショット、参照のみ）
    approval_status     SMALLINT      NOT NULL DEFAULT 10,       -- 10:草稿 20:承認待ち 30:承認済 40:却下 90:取消
    process_instance_id VARCHAR(64),                             -- Flowable process instance id
    requested_by        BIGINT        NOT NULL,                  -- 申請者 → sys_user.id
    requested_at        TIMESTAMPTZ   NOT NULL,                  -- 申請日時
    approved_by         BIGINT,                                  -- 承認者
    approved_at         TIMESTAMPTZ,                             -- 承認／却下日時
    reject_reason       VARCHAR(500),                            -- 却下理由
    CONSTRAINT pk_prd_overproduction_approval PRIMARY KEY (id),
    CONSTRAINT ck_prd_opa_status CHECK (approval_status IN (10,20,30,40,90)),
    CONSTRAINT ck_prd_opa_qty CHECK (request_qty > 0 AND current_allowed_qty >= 0)
);
ALTER TABLE prd_overproduction_approval ENABLE ROW LEVEL SECURITY;
ALTER TABLE prd_overproduction_approval FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON prd_overproduction_approval
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_prd_overproduction_approval_no
    ON prd_overproduction_approval (tenant_id, company_id, approval_no);
CREATE INDEX idx_prd_opa_so_line
    ON prd_overproduction_approval (tenant_id, company_id, sales_order_line_id, approval_status);
CREATE INDEX idx_prd_opa_wo
    ON prd_overproduction_approval (tenant_id, company_id, work_order_id)
    WHERE work_order_id IS NOT NULL;
COMMENT ON COLUMN prd_overproduction_approval.id IS '雪花 ID（主键）';
COMMENT ON COLUMN prd_overproduction_approval.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN prd_overproduction_approval.company_id IS '公司 ID（无默认值）';
COMMENT ON COLUMN prd_overproduction_approval.created_at IS '创建时间';
COMMENT ON COLUMN prd_overproduction_approval.created_by IS '创建人';
COMMENT ON COLUMN prd_overproduction_approval.updated_at IS '更新时间';
COMMENT ON COLUMN prd_overproduction_approval.updated_by IS '更新人';
COMMENT ON COLUMN prd_overproduction_approval.version IS '乐观锁版本';
COMMENT ON COLUMN prd_overproduction_approval.remark IS '备注';
COMMENT ON COLUMN prd_overproduction_approval.ext_data IS '扩展字段';
COMMENT ON COLUMN prd_overproduction_approval.approval_no IS '超産承認番号 OPA{YYMMDD}{4桁}';
COMMENT ON COLUMN prd_overproduction_approval.sales_order_id IS '受注 ID → sal_sales_order.id';
COMMENT ON COLUMN prd_overproduction_approval.sales_order_line_id IS '受注明細 ID → sal_sales_order_line.id';
COMMENT ON COLUMN prd_overproduction_approval.work_order_id IS '対象工单（任意。NULL＝受注行全体）';
COMMENT ON COLUMN prd_overproduction_approval.material_id IS '品目（受注行と一致必須）';
COMMENT ON COLUMN prd_overproduction_approval.request_qty IS '申請超産増分 delta（基本単位、> 0）。総量ではない';
COMMENT ON COLUMN prd_overproduction_approval.current_allowed_qty IS '申請時点の受注行 allowed_qty（基本単位、スナップショット）';
COMMENT ON COLUMN prd_overproduction_approval.approved_allowed_qty IS '承認後の受注行新上限（= 承認時点の受注行 allowed_qty + request_qty。スナップショット、参照のみ）';
COMMENT ON COLUMN prd_overproduction_approval.approval_status IS '10:草稿 20:承認待ち 30:承認済 40:却下 90:取消';
COMMENT ON COLUMN prd_overproduction_approval.process_instance_id IS 'Flowable process instance id';
COMMENT ON COLUMN prd_overproduction_approval.requested_by IS '申請者 → sys_user.id';
COMMENT ON COLUMN prd_overproduction_approval.requested_at IS '申請日時';
COMMENT ON COLUMN prd_overproduction_approval.approved_by IS '承認者';
COMMENT ON COLUMN prd_overproduction_approval.approved_at IS '承認／却下日時';
COMMENT ON COLUMN prd_overproduction_approval.reject_reason IS '却下理由';

-- prd_work_order_material
CREATE TABLE prd_work_order_material (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    remark              VARCHAR(500),
    ext_data            JSONB,
    work_order_id       BIGINT        NOT NULL,                  -- 工单 ID → prd_work_order.id
    line_no             INT           NOT NULL,                  -- 行番号（10 刻み）
    bom_line_id         BIGINT,                                  -- 由来 BOM 行 ID → prd_bom_line.id（变更追跡用）
    operation_seq       INT,                                     -- 投入工序 SEQ（倒冲の対象工序）
    feeding_type        SMALLINT      NOT NULL DEFAULT 10,       -- 10:先行払出 20:倒冲
    material_id         BIGINT        NOT NULL,                  -- 材料物料 ID → mdm_material.id
    material_code       VARCHAR(64)   NOT NULL,                  -- 材料编码（スナップショット）
    material_name       VARCHAR(200)  NOT NULL,                  -- 材料名称（スナップショット）
    material_spec       VARCHAR(200),                            -- 材料规格（スナップショット）
    uom_code            VARCHAR(16)   NOT NULL,                  -- 单位
    required_qty        NUMERIC(18,4) NOT NULL,                  -- 純必要量（BOM.component_qty × order_qty ÷ base_qty）
    loss_rate           NUMERIC(7,4)  NOT NULL DEFAULT 0,        -- 適用损耗率（BOM スナップショット）
    loss_qty            NUMERIC(18,4) NOT NULL DEFAULT 0,        -- 损耗量 = required_qty ÷ (1 − loss_rate) − required_qty
    total_required_qty  NUMERIC(18,4) NOT NULL,                  -- 総必要量（gross）= required_qty + loss_qty
    reserved_qty        NUMERIC(18,4) NOT NULL DEFAULT 0,        -- 引当済数量（E09 受信）
    shortage_qty        NUMERIC(18,4) NOT NULL DEFAULT 0,        -- 引当不足数量
    issued_qty          NUMERIC(18,4) NOT NULL DEFAULT 0,        -- 領料済累計
    returned_qty        NUMERIC(18,4) NOT NULL DEFAULT 0,        -- 退料済累計
    consumed_qty        NUMERIC(18,4) NOT NULL DEFAULT 0,        -- 実投入量（issued − returned）
    remaining_qty       NUMERIC(18,4) NOT NULL DEFAULT 0,        -- 未領数量
    warehouse_id        BIGINT,                                  -- 出庫倉庫 → mdm_warehouse.id
    issue_status        SMALLINT      NOT NULL DEFAULT 0,        -- 0:未 10:一部 20:完了
    is_key_part         BOOLEAN       NOT NULL DEFAULT FALSE,    -- 关键件（追溯対象）
    substitute_group    VARCHAR(32),                             -- 替代组
    used_substitute_material_id BIGINT,                          -- 実際使用した替代料 ID
    standard_unit_cost  NUMERIC(18,6) NOT NULL DEFAULT 0,        -- 標準単価（展開時点）
    actual_unit_cost    NUMERIC(18,6) NOT NULL DEFAULT 0,        -- 実績平均単価（E18 受信）
    actual_amount       NUMERIC(18,2) NOT NULL DEFAULT 0,        -- 実績材料費（領料原価累計）
    CONSTRAINT pk_prd_work_order_material PRIMARY KEY (id),
    CONSTRAINT fk_prd_work_order_material_wo FOREIGN KEY (work_order_id) REFERENCES prd_work_order (id) ON DELETE RESTRICT,
    CONSTRAINT fk_prd_work_order_material_material FOREIGN KEY (material_id) REFERENCES mdm_material (id),
    CONSTRAINT ck_prd_work_order_material_qty CHECK (required_qty > 0 AND total_required_qty >= required_qty AND remaining_qty >= 0),
    CONSTRAINT ck_prd_work_order_material_status CHECK (issue_status IN (0,10,20))
);
ALTER TABLE prd_work_order_material ENABLE ROW LEVEL SECURITY;
ALTER TABLE prd_work_order_material FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON prd_work_order_material
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_prd_work_order_material_wo_line ON prd_work_order_material (company_id, work_order_id, line_no);
CREATE INDEX idx_prd_work_order_material_material ON prd_work_order_material (company_id, material_id, issue_status);
CREATE INDEX idx_prd_work_order_material_unissued ON prd_work_order_material (company_id, work_order_id, remaining_qty) WHERE remaining_qty > 0;
COMMENT ON COLUMN prd_work_order_material.id IS '雪花 ID（主键）';
COMMENT ON COLUMN prd_work_order_material.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN prd_work_order_material.company_id IS '公司 ID（无默认值）';
COMMENT ON COLUMN prd_work_order_material.created_at IS '创建时间';
COMMENT ON COLUMN prd_work_order_material.created_by IS '创建人';
COMMENT ON COLUMN prd_work_order_material.updated_at IS '更新时间';
COMMENT ON COLUMN prd_work_order_material.updated_by IS '更新人';
COMMENT ON COLUMN prd_work_order_material.version IS '乐观锁版本';
COMMENT ON COLUMN prd_work_order_material.remark IS '备注';
COMMENT ON COLUMN prd_work_order_material.ext_data IS '扩展字段';
COMMENT ON COLUMN prd_work_order_material.work_order_id IS '工单 ID → prd_work_order.id';
COMMENT ON COLUMN prd_work_order_material.line_no IS '行番号（10 刻み）';
COMMENT ON COLUMN prd_work_order_material.bom_line_id IS '由来 BOM 行 ID → prd_bom_line.id（变更追跡用）';
COMMENT ON COLUMN prd_work_order_material.operation_seq IS '投入工序 SEQ（倒冲の対象工序）';
COMMENT ON COLUMN prd_work_order_material.feeding_type IS '10:先行払出 20:倒冲';
COMMENT ON COLUMN prd_work_order_material.material_id IS '材料物料 ID → mdm_material.id';
COMMENT ON COLUMN prd_work_order_material.material_code IS '材料编码（スナップショット）';
COMMENT ON COLUMN prd_work_order_material.material_name IS '材料名称（スナップショット）';
COMMENT ON COLUMN prd_work_order_material.material_spec IS '材料规格（スナップショット）';
COMMENT ON COLUMN prd_work_order_material.uom_code IS '单位';
COMMENT ON COLUMN prd_work_order_material.required_qty IS '純必要量（BOM.component_qty × order_qty ÷ base_qty）';
COMMENT ON COLUMN prd_work_order_material.loss_rate IS '適用损耗率（BOM スナップショット）';
COMMENT ON COLUMN prd_work_order_material.loss_qty IS '损耗量 = required_qty ÷ (1 − loss_rate) − required_qty';
COMMENT ON COLUMN prd_work_order_material.total_required_qty IS '総必要量（gross）= required_qty + loss_qty';
COMMENT ON COLUMN prd_work_order_material.reserved_qty IS '引当済数量（E09 受信）';
COMMENT ON COLUMN prd_work_order_material.shortage_qty IS '引当不足数量';
COMMENT ON COLUMN prd_work_order_material.issued_qty IS '領料済累計';
COMMENT ON COLUMN prd_work_order_material.returned_qty IS '退料済累計';
COMMENT ON COLUMN prd_work_order_material.consumed_qty IS '実投入量（issued − returned）';
COMMENT ON COLUMN prd_work_order_material.remaining_qty IS '未領数量';
COMMENT ON COLUMN prd_work_order_material.warehouse_id IS '出庫倉庫 → mdm_warehouse.id';
COMMENT ON COLUMN prd_work_order_material.issue_status IS '0:未 10:一部 20:完了';
COMMENT ON COLUMN prd_work_order_material.is_key_part IS '关键件（追溯対象）';
COMMENT ON COLUMN prd_work_order_material.substitute_group IS '替代组';
COMMENT ON COLUMN prd_work_order_material.used_substitute_material_id IS '実際使用した替代料 ID';
COMMENT ON COLUMN prd_work_order_material.standard_unit_cost IS '標準単価（展開時点）';
COMMENT ON COLUMN prd_work_order_material.actual_unit_cost IS '実績平均単価（E18 受信）';
COMMENT ON COLUMN prd_work_order_material.actual_amount IS '実績材料費（領料原価累計）';

-- prd_work_order_operation
CREATE TABLE prd_work_order_operation (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    remark              VARCHAR(500),
    ext_data            JSONB,
    work_order_id       BIGINT        NOT NULL,                  -- 工单 ID → prd_work_order.id
    operation_seq       INT           NOT NULL,                  -- 工序序号（10,20,…）
    operation_code      VARCHAR(32)   NOT NULL,                  -- 工序编码
    operation_name      VARCHAR(100)  NOT NULL,                  -- 工序名称
    work_center_id      BIGINT        NOT NULL,                  -- 工作中心 ID → prd_work_center.id
    work_center_code    VARCHAR(32)   NOT NULL,                  -- 工作中心编码（スナップショット）
    work_center_name    VARCHAR(100)  NOT NULL,                  -- 工作中心名称（スナップショット）
    equipment_id        BIGINT,                                  -- 使用设备 ID → prd_equipment.id
    setup_time          NUMERIC(12,2) NOT NULL DEFAULT 0,        -- 準備工数（h/批次、スナップショット）
    run_time_per_unit   NUMERIC(12,4) NOT NULL DEFAULT 0,        -- 单件工数（h/件）
    standard_workers    SMALLINT      NOT NULL DEFAULT 1,        -- 标准作业人数
    planned_qty         NUMERIC(18,4) NOT NULL,                  -- 计划良品数量（= order_qty）
    input_qty           NUMERIC(18,4) NOT NULL DEFAULT 0,        -- 投入数量累計
    reported_good_qty   NUMERIC(18,4) NOT NULL DEFAULT 0,        -- 良品累計
    reported_defect_qty NUMERIC(18,4) NOT NULL DEFAULT 0,        -- 不良累計（返工可能）
    scrapped_qty        NUMERIC(18,4) NOT NULL DEFAULT 0,        -- 报废累計
    rework_qty          NUMERIC(18,4) NOT NULL DEFAULT 0,        -- 返工受入累計
    planned_start_date  DATE          NOT NULL,                  -- 计划着手日
    planned_end_date    DATE          NOT NULL,                  -- 计划完了日
    actual_start_date   DATE,                                    -- 実績着手日
    actual_end_date     DATE,                                    -- 実績完了日
    planned_setup_hours NUMERIC(12,2) NOT NULL DEFAULT 0,        -- 予定準備工数
    planned_run_hours   NUMERIC(12,2) NOT NULL DEFAULT 0,        -- 予定加工工数（run_time × planned_qty）
    actual_setup_hours  NUMERIC(12,2) NOT NULL DEFAULT 0,        -- 実績準備工数
    actual_labor_hours  NUMERIC(12,2) NOT NULL DEFAULT 0,        -- 実績人工工数
    actual_machine_hours NUMERIC(12,2) NOT NULL DEFAULT 0,       -- 実績設備工数
    operation_status    SMALLINT      NOT NULL DEFAULT 0,        -- 0:未着手 10:着手中 20:完了 30:保留
    is_inspection_point BOOLEAN       NOT NULL DEFAULT FALSE,    -- 检验点フラグ
    inspection_status   SMALLINT      NOT NULL DEFAULT 10,       -- 10:起票 20:検査中 30:判定確定 90:取消
    inspection_id       BIGINT,                                  -- 検査单 ID → prd_inspection.id
    is_backflush        BOOLEAN       NOT NULL DEFAULT FALSE,    -- 当工序完了で材料倒冲
    CONSTRAINT pk_prd_work_order_operation PRIMARY KEY (id),
    CONSTRAINT fk_prd_work_order_operation_wo FOREIGN KEY (work_order_id) REFERENCES prd_work_order (id) ON DELETE RESTRICT,
    CONSTRAINT fk_prd_work_order_operation_wc FOREIGN KEY (work_center_id) REFERENCES prd_work_center (id),
    CONSTRAINT ck_prd_work_order_operation_qty CHECK (planned_qty > 0 AND reported_good_qty >= 0 AND scrapped_qty >= 0),
    CONSTRAINT ck_prd_work_order_operation_status CHECK (operation_status IN (0,10,20,30))
);
ALTER TABLE prd_work_order_operation ENABLE ROW LEVEL SECURITY;
ALTER TABLE prd_work_order_operation FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON prd_work_order_operation
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_prd_work_order_operation_wo_seq ON prd_work_order_operation (company_id, work_order_id, operation_seq);
CREATE INDEX idx_prd_work_order_operation_wc_date ON prd_work_order_operation (company_id, work_center_id, planned_start_date, operation_status);
CREATE INDEX idx_prd_work_order_operation_inspection ON prd_work_order_operation (company_id, inspection_status) WHERE inspection_status IN (10,30);
COMMENT ON COLUMN prd_work_order_operation.id IS '雪花 ID（主键）';
COMMENT ON COLUMN prd_work_order_operation.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN prd_work_order_operation.company_id IS '公司 ID（无默认值）';
COMMENT ON COLUMN prd_work_order_operation.created_at IS '创建时间';
COMMENT ON COLUMN prd_work_order_operation.created_by IS '创建人';
COMMENT ON COLUMN prd_work_order_operation.updated_at IS '更新时间';
COMMENT ON COLUMN prd_work_order_operation.updated_by IS '更新人';
COMMENT ON COLUMN prd_work_order_operation.version IS '乐观锁版本';
COMMENT ON COLUMN prd_work_order_operation.remark IS '备注';
COMMENT ON COLUMN prd_work_order_operation.ext_data IS '扩展字段';
COMMENT ON COLUMN prd_work_order_operation.work_order_id IS '工单 ID → prd_work_order.id';
COMMENT ON COLUMN prd_work_order_operation.operation_seq IS '工序序号（10,20,…）';
COMMENT ON COLUMN prd_work_order_operation.operation_code IS '工序编码';
COMMENT ON COLUMN prd_work_order_operation.operation_name IS '工序名称';
COMMENT ON COLUMN prd_work_order_operation.work_center_id IS '工作中心 ID → prd_work_center.id';
COMMENT ON COLUMN prd_work_order_operation.work_center_code IS '工作中心编码（スナップショット）';
COMMENT ON COLUMN prd_work_order_operation.work_center_name IS '工作中心名称（スナップショット）';
COMMENT ON COLUMN prd_work_order_operation.equipment_id IS '使用设备 ID → prd_equipment.id';
COMMENT ON COLUMN prd_work_order_operation.setup_time IS '準備工数（h/批次、スナップショット）';
COMMENT ON COLUMN prd_work_order_operation.run_time_per_unit IS '单件工数（h/件）';
COMMENT ON COLUMN prd_work_order_operation.standard_workers IS '标准作业人数';
COMMENT ON COLUMN prd_work_order_operation.planned_qty IS '计划良品数量（= order_qty）';
COMMENT ON COLUMN prd_work_order_operation.input_qty IS '投入数量累計';
COMMENT ON COLUMN prd_work_order_operation.reported_good_qty IS '良品累計';
COMMENT ON COLUMN prd_work_order_operation.reported_defect_qty IS '不良累計（返工可能）';
COMMENT ON COLUMN prd_work_order_operation.scrapped_qty IS '报废累計';
COMMENT ON COLUMN prd_work_order_operation.rework_qty IS '返工受入累計';
COMMENT ON COLUMN prd_work_order_operation.planned_start_date IS '计划着手日';
COMMENT ON COLUMN prd_work_order_operation.planned_end_date IS '计划完了日';
COMMENT ON COLUMN prd_work_order_operation.actual_start_date IS '実績着手日';
COMMENT ON COLUMN prd_work_order_operation.actual_end_date IS '実績完了日';
COMMENT ON COLUMN prd_work_order_operation.planned_setup_hours IS '予定準備工数';
COMMENT ON COLUMN prd_work_order_operation.planned_run_hours IS '予定加工工数（run_time × planned_qty）';
COMMENT ON COLUMN prd_work_order_operation.actual_setup_hours IS '実績準備工数';
COMMENT ON COLUMN prd_work_order_operation.actual_labor_hours IS '実績人工工数';
COMMENT ON COLUMN prd_work_order_operation.actual_machine_hours IS '実績設備工数';
COMMENT ON COLUMN prd_work_order_operation.operation_status IS '0:未着手 10:着手中 20:完了 30:保留';
COMMENT ON COLUMN prd_work_order_operation.is_inspection_point IS '检验点フラグ';
COMMENT ON COLUMN prd_work_order_operation.inspection_status IS '10:起票 20:検査中 30:判定確定 90:取消';
COMMENT ON COLUMN prd_work_order_operation.inspection_id IS '検査单 ID → prd_inspection.id';
COMMENT ON COLUMN prd_work_order_operation.is_backflush IS '当工序完了で材料倒冲';

-- prd_work_order_change
CREATE TABLE prd_work_order_change (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    work_order_id       BIGINT        NOT NULL,                  -- 工单 ID → prd_work_order.id
    change_no           INT           NOT NULL,                  -- 变更序号（工单内連番）
    change_type         SMALLINT      NOT NULL,                  -- 10:数量 20:日程 30:BOM 40:工艺 50:保留 60:取消 70:拆分合并
    change_reason       VARCHAR(1000) NOT NULL,                  -- 变更理由（必須）
    before_data         JSONB         NOT NULL,                  -- 変更前
    after_data          JSONB         NOT NULL,                  -- 変更後
    change_status       SMALLINT      NOT NULL DEFAULT 10,       -- 10:申請中 25:承認済 95:却下
    applicant_id        BIGINT,                                  -- 申請者 → sys_user.id
    approved_by         BIGINT,                                  -- 承認者
    approved_at         TIMESTAMPTZ,                             -- 承認日時
    CONSTRAINT pk_prd_work_order_change PRIMARY KEY (id),
    CONSTRAINT fk_prd_work_order_change_wo FOREIGN KEY (work_order_id) REFERENCES prd_work_order (id) ON DELETE RESTRICT,
    CONSTRAINT ck_prd_work_order_change_type CHECK (change_type IN (10,20,30,40,50,60,70))
);
ALTER TABLE prd_work_order_change ENABLE ROW LEVEL SECURITY;
ALTER TABLE prd_work_order_change FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON prd_work_order_change
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_prd_work_order_change_wo_no ON prd_work_order_change (company_id, work_order_id, change_no);
CREATE INDEX idx_prd_work_order_change_date ON prd_work_order_change (company_id, created_at DESC);
COMMENT ON COLUMN prd_work_order_change.id IS '雪花 ID（主键）';
COMMENT ON COLUMN prd_work_order_change.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN prd_work_order_change.company_id IS '公司 ID（无默认值）';
COMMENT ON COLUMN prd_work_order_change.created_at IS '创建时间';
COMMENT ON COLUMN prd_work_order_change.created_by IS '创建人';
COMMENT ON COLUMN prd_work_order_change.work_order_id IS '工单 ID → prd_work_order.id';
COMMENT ON COLUMN prd_work_order_change.change_no IS '变更序号（工单内連番）';
COMMENT ON COLUMN prd_work_order_change.change_type IS '10:数量 20:日程 30:BOM 40:工艺 50:保留 60:取消 70:拆分合并';
COMMENT ON COLUMN prd_work_order_change.change_reason IS '变更理由（必須）';
COMMENT ON COLUMN prd_work_order_change.before_data IS '変更前';
COMMENT ON COLUMN prd_work_order_change.after_data IS '変更後';
COMMENT ON COLUMN prd_work_order_change.change_status IS '10:申請中 25:承認済 95:却下';
COMMENT ON COLUMN prd_work_order_change.applicant_id IS '申請者 → sys_user.id';
COMMENT ON COLUMN prd_work_order_change.approved_by IS '承認者';
COMMENT ON COLUMN prd_work_order_change.approved_at IS '承認日時';

-- prd_work_order_relation
CREATE TABLE prd_work_order_relation (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    relation_type       SMALLINT      NOT NULL,                  -- 10:拆分 20:合并 30:返工起票
    source_work_order_id BIGINT       NOT NULL,                  -- 元工单 ID → prd_work_order.id
    target_work_order_id BIGINT       NOT NULL,                  -- 新工单 ID → prd_work_order.id
    relation_qty        NUMERIC(18,4) NOT NULL,                  -- 移管数量
    relation_reason     VARCHAR(500),                            -- 理由
    relation_status     SMALLINT      NOT NULL DEFAULT 10,       -- 10:申請中 25:承認済 90:取消
    approved_by         BIGINT,                                  -- 承認者
    approved_at         TIMESTAMPTZ,                             -- 承認日時
    CONSTRAINT pk_prd_work_order_relation PRIMARY KEY (id),
    CONSTRAINT fk_prd_work_order_relation_src FOREIGN KEY (source_work_order_id) REFERENCES prd_work_order (id) ON DELETE RESTRICT,
    CONSTRAINT fk_prd_work_order_relation_tgt FOREIGN KEY (target_work_order_id) REFERENCES prd_work_order (id) ON DELETE RESTRICT,
    CONSTRAINT ck_prd_work_order_relation_type CHECK (relation_type IN (10,20,30)),
    CONSTRAINT ck_prd_work_order_relation_qty CHECK (relation_qty > 0)
);
ALTER TABLE prd_work_order_relation ENABLE ROW LEVEL SECURITY;
ALTER TABLE prd_work_order_relation FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON prd_work_order_relation
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE INDEX idx_prd_work_order_relation_src ON prd_work_order_relation (company_id, source_work_order_id);
CREATE INDEX idx_prd_work_order_relation_tgt ON prd_work_order_relation (company_id, target_work_order_id);
COMMENT ON COLUMN prd_work_order_relation.id IS '雪花 ID（主键）';
COMMENT ON COLUMN prd_work_order_relation.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN prd_work_order_relation.company_id IS '公司 ID（无默认值）';
COMMENT ON COLUMN prd_work_order_relation.created_at IS '创建时间';
COMMENT ON COLUMN prd_work_order_relation.created_by IS '创建人';
COMMENT ON COLUMN prd_work_order_relation.relation_type IS '10:拆分 20:合并 30:返工起票';
COMMENT ON COLUMN prd_work_order_relation.source_work_order_id IS '元工单 ID → prd_work_order.id';
COMMENT ON COLUMN prd_work_order_relation.target_work_order_id IS '新工单 ID → prd_work_order.id';
COMMENT ON COLUMN prd_work_order_relation.relation_qty IS '移管数量';
COMMENT ON COLUMN prd_work_order_relation.relation_reason IS '理由';
COMMENT ON COLUMN prd_work_order_relation.relation_status IS '10:申請中 25:承認済 90:取消';
COMMENT ON COLUMN prd_work_order_relation.approved_by IS '承認者';
COMMENT ON COLUMN prd_work_order_relation.approved_at IS '承認日時';

-- prd_material_issue
CREATE TABLE prd_material_issue (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    remark              VARCHAR(500),
    ext_data            JSONB,
    request_no          VARCHAR(32)   NOT NULL,                  -- PRD 要求番号（域内番号）REQ{YYMMDD}{4桁}。伝票番号ではない
    issue_type          SMALLINT      NOT NULL DEFAULT 10,       -- 10:领料要求 20:补料要求 30:退料要求 40:倒冲 50:报废补料
    work_order_id       BIGINT        NOT NULL,                  -- 工单 ID → prd_work_order.id
    work_order_no       VARCHAR(32)   NOT NULL,                  -- 工单号（スナップショット）
    issue_date          DATE          NOT NULL,                  -- 領料/退料要求日
    warehouse_id        BIGINT        NOT NULL,                  -- 出庫/入庫倉庫 ID → mdm_warehouse.id
    issue_status        SMALLINT      NOT NULL DEFAULT 10,       -- 10:起票 30:要求確定（E22/E36 発行済） 40:INV 処理完了 90:取消
    source_type         SMALLINT      NOT NULL DEFAULT 10,       -- 10:手工 20:倒冲自動 30:PDA 40:MES
    total_qty           NUMERIC(18,4) NOT NULL DEFAULT 0,        -- 合計数量
    total_amount        NUMERIC(18,2) NOT NULL DEFAULT 0,        -- 合計金額（原価参考）
    stock_doc_id        BIGINT,                                  -- INV 採番の在庫伝票 ID → inv_stock_txn.id（E18 受信で設定）
    stock_doc_no        VARCHAR(32),                             -- INV 採番の伝票番号（MII/MIR）。**PRD は採番しない**
    stock_doc_status    SMALLINT      NOT NULL DEFAULT 0,        -- INV 側状態 0:未採番 10:起票 30:確定 40:完了 90:取消
    issued_by           BIGINT,                                  -- 要求者 → sys_user.id
    issued_at           TIMESTAMPTZ,                             -- 要求確定日時（E22/E36 発行）
    approval_required   BOOLEAN       NOT NULL DEFAULT FALSE,    -- 超領等の承認要否
    approved_by         BIGINT,                                  -- 承認者
    approved_at         TIMESTAMPTZ,                             -- 承認日時
    cancel_reason       VARCHAR(500),                            -- 取消理由
    CONSTRAINT pk_prd_material_issue PRIMARY KEY (id),
    CONSTRAINT fk_prd_material_issue_wo FOREIGN KEY (work_order_id) REFERENCES prd_work_order (id),
    CONSTRAINT fk_prd_material_issue_wh FOREIGN KEY (warehouse_id) REFERENCES mdm_warehouse (id),
    CONSTRAINT ck_prd_material_issue_type CHECK (issue_type IN (10,20,30,40,50)),
    CONSTRAINT ck_prd_material_issue_status CHECK (issue_status IN (10,30,40,90)),
    CONSTRAINT ck_prd_material_issue_qty CHECK (total_qty >= 0)
);
ALTER TABLE prd_material_issue ENABLE ROW LEVEL SECURITY;
ALTER TABLE prd_material_issue FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON prd_material_issue
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_prd_material_issue_req ON prd_material_issue (tenant_id, company_id, request_no);
CREATE INDEX idx_prd_material_issue_doc ON prd_material_issue (company_id, stock_doc_no);
CREATE INDEX idx_prd_material_issue_wo ON prd_material_issue (company_id, work_order_id, issue_type, issue_status);
CREATE INDEX idx_prd_material_issue_date ON prd_material_issue (company_id, issue_date, issue_status);

-- 设计书矛盾：列 issue_no 不存在（v1.1 起 INV 单一采番），暂不创建：CREATE UNIQUE INDEX uk_prd_material_issue_no ON prd_material_issue (tenant_id, company_id, issue_no);
COMMENT ON COLUMN prd_material_issue.id IS '雪花 ID（主键）';
COMMENT ON COLUMN prd_material_issue.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN prd_material_issue.company_id IS '公司 ID（无默认值）';
COMMENT ON COLUMN prd_material_issue.created_at IS '创建时间';
COMMENT ON COLUMN prd_material_issue.created_by IS '创建人';
COMMENT ON COLUMN prd_material_issue.updated_at IS '更新时间';
COMMENT ON COLUMN prd_material_issue.updated_by IS '更新人';
COMMENT ON COLUMN prd_material_issue.version IS '乐观锁版本';
COMMENT ON COLUMN prd_material_issue.remark IS '备注';
COMMENT ON COLUMN prd_material_issue.ext_data IS '扩展字段';
COMMENT ON COLUMN prd_material_issue.request_no IS 'PRD 要求番号（域内番号）REQ{YYMMDD}{4桁}。伝票番号ではない';
COMMENT ON COLUMN prd_material_issue.issue_type IS '10:领料要求 20:补料要求 30:退料要求 40:倒冲 50:报废补料';
COMMENT ON COLUMN prd_material_issue.work_order_id IS '工单 ID → prd_work_order.id';
COMMENT ON COLUMN prd_material_issue.work_order_no IS '工单号（スナップショット）';
COMMENT ON COLUMN prd_material_issue.issue_date IS '領料/退料要求日';
COMMENT ON COLUMN prd_material_issue.warehouse_id IS '出庫/入庫倉庫 ID → mdm_warehouse.id';
COMMENT ON COLUMN prd_material_issue.issue_status IS '10:起票 30:要求確定（E22/E36 発行済） 40:INV 処理完了 90:取消';
COMMENT ON COLUMN prd_material_issue.source_type IS '10:手工 20:倒冲自動 30:PDA 40:MES';
COMMENT ON COLUMN prd_material_issue.total_qty IS '合計数量';
COMMENT ON COLUMN prd_material_issue.total_amount IS '合計金額（原価参考）';
COMMENT ON COLUMN prd_material_issue.stock_doc_id IS 'INV 採番の在庫伝票 ID → inv_stock_txn.id（E18 受信で設定）';
COMMENT ON COLUMN prd_material_issue.stock_doc_no IS 'INV 採番の伝票番号（MII/MIR）。**PRD は採番しない**';
COMMENT ON COLUMN prd_material_issue.stock_doc_status IS 'INV 側状態 0:未採番 10:起票 30:確定 40:完了 90:取消';
COMMENT ON COLUMN prd_material_issue.issued_by IS '要求者 → sys_user.id';
COMMENT ON COLUMN prd_material_issue.issued_at IS '要求確定日時（E22/E36 発行）';
COMMENT ON COLUMN prd_material_issue.approval_required IS '超領等の承認要否';
COMMENT ON COLUMN prd_material_issue.approved_by IS '承認者';
COMMENT ON COLUMN prd_material_issue.approved_at IS '承認日時';
COMMENT ON COLUMN prd_material_issue.cancel_reason IS '取消理由';

-- prd_material_issue_line
CREATE TABLE prd_material_issue_line (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    remark              VARCHAR(500),
    ext_data            JSONB,
    issue_id            BIGINT        NOT NULL,                  -- 领料单 ID → prd_material_issue.id
    line_no             INT           NOT NULL,                  -- 行番号
    work_order_material_id BIGINT     NOT NULL,                  -- 工单用料行 ID → prd_work_order_material.id
    material_id         BIGINT        NOT NULL,                  -- 物料 ID → mdm_material.id
    material_code       VARCHAR(64)   NOT NULL,                  -- 物料编码（スナップショット）
    material_name       VARCHAR(200)  NOT NULL,                  -- 物料名称（スナップショット）
    material_spec       VARCHAR(200),                            -- 规格（スナップショット）
    uom_code            VARCHAR(16)   NOT NULL,                  -- 单位
    issue_qty           NUMERIC(18,4) NOT NULL DEFAULT 0,        -- 領料数量（退料時は 0）
    return_qty          NUMERIC(18,4) NOT NULL DEFAULT 0,        -- 退料数量（領料時は 0）
    applied_qty         NUMERIC(18,4) NOT NULL DEFAULT 0,        -- 適用数量（領料=+、退料=−として工单用料へ反映）
    batch_no            VARCHAR(64),                             -- 批次号（INV 批次管理対象）
    warehouse_id        BIGINT        NOT NULL,                  -- 倉庫 ID → mdm_warehouse.id
    location_id         BIGINT,                                  -- 庫位 ID → mdm_warehouse_bin.id
    unit_cost           NUMERIC(18,6) NOT NULL DEFAULT 0,        -- 単価（参照原価、INV が権威）
    amount              NUMERIC(18,2) NOT NULL DEFAULT 0,        -- 金額（issue_qty × unit_cost、2 桁）
    is_substitute       BOOLEAN       NOT NULL DEFAULT FALSE,    -- 替代料使用フラグ
    substitute_for_material_id BIGINT,                           -- 替代対象の主料 ID
    issue_reason        SMALLINT      NOT NULL DEFAULT 10,       -- 10:標準 20:補料 30:不良追加 40:试验 50:その他
    stock_doc_line_id   BIGINT,                                  -- INV 採番の在庫伝票行 ID（E18 受信で設定）
    CONSTRAINT pk_prd_material_issue_line PRIMARY KEY (id),
    CONSTRAINT fk_prd_material_issue_line_issue FOREIGN KEY (issue_id) REFERENCES prd_material_issue (id) ON DELETE RESTRICT,
    CONSTRAINT fk_prd_material_issue_line_wom FOREIGN KEY (work_order_material_id) REFERENCES prd_work_order_material (id),
    CONSTRAINT ck_prd_material_issue_line_qty CHECK (issue_qty >= 0 AND return_qty >= 0 AND NOT (issue_qty > 0 AND return_qty > 0)),
    CONSTRAINT ck_prd_material_issue_line_amount CHECK (amount >= 0)
);
ALTER TABLE prd_material_issue_line ENABLE ROW LEVEL SECURITY;
ALTER TABLE prd_material_issue_line FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON prd_material_issue_line
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_prd_material_issue_line_issue_line ON prd_material_issue_line (company_id, issue_id, line_no);
CREATE INDEX idx_prd_material_issue_line_wom ON prd_material_issue_line (company_id, work_order_material_id);
CREATE INDEX idx_prd_material_issue_line_material ON prd_material_issue_line (company_id, material_id, batch_no);
COMMENT ON COLUMN prd_material_issue_line.id IS '雪花 ID（主键）';
COMMENT ON COLUMN prd_material_issue_line.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN prd_material_issue_line.company_id IS '公司 ID（无默认值）';
COMMENT ON COLUMN prd_material_issue_line.created_at IS '创建时间';
COMMENT ON COLUMN prd_material_issue_line.created_by IS '创建人';
COMMENT ON COLUMN prd_material_issue_line.updated_at IS '更新时间';
COMMENT ON COLUMN prd_material_issue_line.updated_by IS '更新人';
COMMENT ON COLUMN prd_material_issue_line.version IS '乐观锁版本';
COMMENT ON COLUMN prd_material_issue_line.remark IS '备注';
COMMENT ON COLUMN prd_material_issue_line.ext_data IS '扩展字段';
COMMENT ON COLUMN prd_material_issue_line.issue_id IS '领料单 ID → prd_material_issue.id';
COMMENT ON COLUMN prd_material_issue_line.line_no IS '行番号';
COMMENT ON COLUMN prd_material_issue_line.work_order_material_id IS '工单用料行 ID → prd_work_order_material.id';
COMMENT ON COLUMN prd_material_issue_line.material_id IS '物料 ID → mdm_material.id';
COMMENT ON COLUMN prd_material_issue_line.material_code IS '物料编码（スナップショット）';
COMMENT ON COLUMN prd_material_issue_line.material_name IS '物料名称（スナップショット）';
COMMENT ON COLUMN prd_material_issue_line.material_spec IS '规格（スナップショット）';
COMMENT ON COLUMN prd_material_issue_line.uom_code IS '单位';
COMMENT ON COLUMN prd_material_issue_line.issue_qty IS '領料数量（退料時は 0）';
COMMENT ON COLUMN prd_material_issue_line.return_qty IS '退料数量（領料時は 0）';
COMMENT ON COLUMN prd_material_issue_line.applied_qty IS '適用数量（領料=+、退料=−として工单用料へ反映）';
COMMENT ON COLUMN prd_material_issue_line.batch_no IS '批次号（INV 批次管理対象）';
COMMENT ON COLUMN prd_material_issue_line.warehouse_id IS '倉庫 ID → mdm_warehouse.id';
COMMENT ON COLUMN prd_material_issue_line.location_id IS '庫位 ID → mdm_warehouse_bin.id';
COMMENT ON COLUMN prd_material_issue_line.unit_cost IS '単価（参照原価、INV が権威）';
COMMENT ON COLUMN prd_material_issue_line.amount IS '金額（issue_qty × unit_cost、2 桁）';
COMMENT ON COLUMN prd_material_issue_line.is_substitute IS '替代料使用フラグ';
COMMENT ON COLUMN prd_material_issue_line.substitute_for_material_id IS '替代対象の主料 ID';
COMMENT ON COLUMN prd_material_issue_line.issue_reason IS '10:標準 20:補料 30:不良追加 40:试验 50:その他';
COMMENT ON COLUMN prd_material_issue_line.stock_doc_line_id IS 'INV 採番の在庫伝票行 ID（E18 受信で設定）';

-- prd_work_report
CREATE TABLE prd_work_report (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    remark              VARCHAR(500),
    ext_data            JSONB,
    report_no           VARCHAR(32)   NOT NULL,                  -- 报工单号 WR{YYMMDD}{4桁}（域内拡張採番）
    work_order_id       BIGINT        NOT NULL,                  -- 工单 ID → prd_work_order.id
    work_order_no       VARCHAR(32)   NOT NULL,                  -- 工单号（スナップショット）
    work_order_operation_id BIGINT    NOT NULL,                  -- 工单工序 ID → prd_work_order_operation.id
    operation_seq       INT           NOT NULL,                  -- 工序序号（スナップショット）
    operation_name      VARCHAR(100)  NOT NULL,                  -- 工序名称（スナップショット）
    report_type         SMALLINT      NOT NULL DEFAULT 10,       -- 10:正常 20:返工 30:返修 40:试制 50:再作業
    report_date         DATE          NOT NULL,                  -- 報工日
    shift_code          VARCHAR(16),                             -- 班次 A/B/C
    input_qty           NUMERIC(18,4) NOT NULL DEFAULT 0,        -- 投入数量
    reported_good_qty   NUMERIC(18,4) NOT NULL DEFAULT 0,        -- 良品数量
    defect_qty          NUMERIC(18,4) NOT NULL DEFAULT 0,        -- 不良数量（返工可能）
    scrap_qty           NUMERIC(18,4) NOT NULL DEFAULT 0,        -- 报废数量
    rework_qty          NUMERIC(18,4) NOT NULL DEFAULT 0,        -- 返工受入数量
    setup_hours         NUMERIC(12,2) NOT NULL DEFAULT 0,        -- 準備工数（h）
    labor_hours         NUMERIC(12,2) NOT NULL DEFAULT 0,        -- 人工工数（h）
    machine_hours       NUMERIC(12,2) NOT NULL DEFAULT 0,        -- 設備工数（h）
    total_work_hours    NUMERIC(12,2) NOT NULL DEFAULT 0,        -- 合計工数（h）
    labor_amount        NUMERIC(18,2) NOT NULL DEFAULT 0,        -- 人工費（labor_hours × 賃率）
    overhead_amount     NUMERIC(18,2) NOT NULL DEFAULT 0,        -- 製造費用配賦額（machine/labor × 配賦率）
    report_status       SMALLINT      NOT NULL DEFAULT 10,       -- 10:草稿 20:承認待ち 40:確定済（E23 発行） 90:取消
    report_user_id      BIGINT,                                  -- 報工者 → sys_user.id
    department_id       BIGINT,                                  -- 部門 ID → sys_department.id
    approved_by         BIGINT,                                  -- 承認者
    approved_at         TIMESTAMPTZ,                             -- 承認日時
    confirmed_at        TIMESTAMPTZ,                             -- 確定日時（E23 発行）
    backflush_flag      BOOLEAN       NOT NULL DEFAULT FALSE,    -- 倒冲実施フラグ
    linked_issue_id     BIGINT,                                  -- 倒冲で生成した领料单 ID → prd_material_issue.id
    cancel_reason       VARCHAR(500),                            -- 取消理由
    CONSTRAINT pk_prd_work_report PRIMARY KEY (id),
    CONSTRAINT fk_prd_work_report_wo FOREIGN KEY (work_order_id) REFERENCES prd_work_order (id),
    CONSTRAINT fk_prd_work_report_op FOREIGN KEY (work_order_operation_id) REFERENCES prd_work_order_operation (id),
    CONSTRAINT ck_prd_work_report_status CHECK (report_status IN (10,20,40,90)),
    CONSTRAINT ck_prd_work_report_qty CHECK (reported_good_qty >= 0 AND defect_qty >= 0 AND scrap_qty >= 0 AND total_work_hours >= 0),
    CONSTRAINT ck_prd_work_report_input CHECK (input_qty >= reported_good_qty + defect_qty + scrap_qty - 0.0001)
);
ALTER TABLE prd_work_report ENABLE ROW LEVEL SECURITY;
ALTER TABLE prd_work_report FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON prd_work_report
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_prd_work_report_no ON prd_work_report (tenant_id, company_id, report_no);
CREATE INDEX idx_prd_work_report_wo ON prd_work_report (company_id, work_order_id, operation_seq, report_status);
CREATE INDEX idx_prd_work_report_date ON prd_work_report (company_id, report_date, report_status);
CREATE INDEX idx_prd_work_report_op ON prd_work_report (company_id, work_order_operation_id);
COMMENT ON COLUMN prd_work_report.id IS '雪花 ID（主键）';
COMMENT ON COLUMN prd_work_report.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN prd_work_report.company_id IS '公司 ID（无默认值）';
COMMENT ON COLUMN prd_work_report.created_at IS '创建时间';
COMMENT ON COLUMN prd_work_report.created_by IS '创建人';
COMMENT ON COLUMN prd_work_report.updated_at IS '更新时间';
COMMENT ON COLUMN prd_work_report.updated_by IS '更新人';
COMMENT ON COLUMN prd_work_report.version IS '乐观锁版本';
COMMENT ON COLUMN prd_work_report.remark IS '备注';
COMMENT ON COLUMN prd_work_report.ext_data IS '扩展字段';
COMMENT ON COLUMN prd_work_report.report_no IS '报工单号 WR{YYMMDD}{4桁}（域内拡張採番）';
COMMENT ON COLUMN prd_work_report.work_order_id IS '工单 ID → prd_work_order.id';
COMMENT ON COLUMN prd_work_report.work_order_no IS '工单号（スナップショット）';
COMMENT ON COLUMN prd_work_report.work_order_operation_id IS '工单工序 ID → prd_work_order_operation.id';
COMMENT ON COLUMN prd_work_report.operation_seq IS '工序序号（スナップショット）';
COMMENT ON COLUMN prd_work_report.operation_name IS '工序名称（スナップショット）';
COMMENT ON COLUMN prd_work_report.report_type IS '10:正常 20:返工 30:返修 40:试制 50:再作業';
COMMENT ON COLUMN prd_work_report.report_date IS '報工日';
COMMENT ON COLUMN prd_work_report.shift_code IS '班次 A/B/C';
COMMENT ON COLUMN prd_work_report.input_qty IS '投入数量';
COMMENT ON COLUMN prd_work_report.reported_good_qty IS '良品数量';
COMMENT ON COLUMN prd_work_report.defect_qty IS '不良数量（返工可能）';
COMMENT ON COLUMN prd_work_report.scrap_qty IS '报废数量';
COMMENT ON COLUMN prd_work_report.rework_qty IS '返工受入数量';
COMMENT ON COLUMN prd_work_report.setup_hours IS '準備工数（h）';
COMMENT ON COLUMN prd_work_report.labor_hours IS '人工工数（h）';
COMMENT ON COLUMN prd_work_report.machine_hours IS '設備工数（h）';
COMMENT ON COLUMN prd_work_report.total_work_hours IS '合計工数（h）';
COMMENT ON COLUMN prd_work_report.labor_amount IS '人工費（labor_hours × 賃率）';
COMMENT ON COLUMN prd_work_report.overhead_amount IS '製造費用配賦額（machine/labor × 配賦率）';
COMMENT ON COLUMN prd_work_report.report_status IS '10:草稿 20:承認待ち 40:確定済（E23 発行） 90:取消';
COMMENT ON COLUMN prd_work_report.report_user_id IS '報工者 → sys_user.id';
COMMENT ON COLUMN prd_work_report.department_id IS '部門 ID → sys_department.id';
COMMENT ON COLUMN prd_work_report.approved_by IS '承認者';
COMMENT ON COLUMN prd_work_report.approved_at IS '承認日時';
COMMENT ON COLUMN prd_work_report.confirmed_at IS '確定日時（E23 発行）';
COMMENT ON COLUMN prd_work_report.backflush_flag IS '倒冲実施フラグ';
COMMENT ON COLUMN prd_work_report.linked_issue_id IS '倒冲で生成した领料单 ID → prd_material_issue.id';
COMMENT ON COLUMN prd_work_report.cancel_reason IS '取消理由';

-- prd_work_report_labor
CREATE TABLE prd_work_report_labor (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    remark              VARCHAR(500),
    ext_data            JSONB,
    report_id           BIGINT        NOT NULL,                  -- 报工单 ID → prd_work_report.id
    line_no             INT           NOT NULL,                  -- 行番号
    labor_type          SMALLINT      NOT NULL DEFAULT 10,       -- 10:直接人工 20:間接人工 30:設備工数
    employee_id         BIGINT,                                  -- 作業者 → sys_user.id（labor_type=10/20）
    employee_name       VARCHAR(100),                            -- 作業者名（スナップショット）
    equipment_id        BIGINT,                                  -- 設備 ID → prd_equipment.id（labor_type=30）
    work_center_id      BIGINT,                                  -- 工作中心 ID（スナップショット）
    labor_hours         NUMERIC(12,2) NOT NULL,                  -- 工数（h）
    hourly_rate         NUMERIC(18,6) NOT NULL DEFAULT 0,        -- 賃率（元/h、記録時点）
    labor_amount        NUMERIC(18,2) NOT NULL DEFAULT 0,        -- 金額（元）
    is_overtime         BOOLEAN       NOT NULL DEFAULT FALSE,    -- 残業フラグ
    shift_code          VARCHAR(16),                             -- 班次
    start_at            TIMESTAMPTZ,                             -- 作業開始
    end_at              TIMESTAMPTZ,                             -- 作業終了
    CONSTRAINT pk_prd_work_report_labor PRIMARY KEY (id),
    CONSTRAINT fk_prd_work_report_labor_report FOREIGN KEY (report_id) REFERENCES prd_work_report (id) ON DELETE RESTRICT,
    CONSTRAINT ck_prd_work_report_labor_type CHECK (labor_type IN (10,20,30)),
    CONSTRAINT ck_prd_work_report_labor_hours CHECK (labor_hours > 0 AND labor_amount >= 0)
);
ALTER TABLE prd_work_report_labor ENABLE ROW LEVEL SECURITY;
ALTER TABLE prd_work_report_labor FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON prd_work_report_labor
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_prd_work_report_labor_report_line ON prd_work_report_labor (company_id, report_id, line_no);
CREATE INDEX idx_prd_work_report_labor_employee ON prd_work_report_labor (company_id, employee_id, start_at DESC);
COMMENT ON COLUMN prd_work_report_labor.id IS '雪花 ID（主键）';
COMMENT ON COLUMN prd_work_report_labor.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN prd_work_report_labor.company_id IS '公司 ID（无默认值）';
COMMENT ON COLUMN prd_work_report_labor.created_at IS '创建时间';
COMMENT ON COLUMN prd_work_report_labor.created_by IS '创建人';
COMMENT ON COLUMN prd_work_report_labor.updated_at IS '更新时间';
COMMENT ON COLUMN prd_work_report_labor.updated_by IS '更新人';
COMMENT ON COLUMN prd_work_report_labor.version IS '乐观锁版本';
COMMENT ON COLUMN prd_work_report_labor.remark IS '备注';
COMMENT ON COLUMN prd_work_report_labor.ext_data IS '扩展字段';
COMMENT ON COLUMN prd_work_report_labor.report_id IS '报工单 ID → prd_work_report.id';
COMMENT ON COLUMN prd_work_report_labor.line_no IS '行番号';
COMMENT ON COLUMN prd_work_report_labor.labor_type IS '10:直接人工 20:間接人工 30:設備工数';
COMMENT ON COLUMN prd_work_report_labor.employee_id IS '作業者 → sys_user.id（labor_type=10/20）';
COMMENT ON COLUMN prd_work_report_labor.employee_name IS '作業者名（スナップショット）';
COMMENT ON COLUMN prd_work_report_labor.equipment_id IS '設備 ID → prd_equipment.id（labor_type=30）';
COMMENT ON COLUMN prd_work_report_labor.work_center_id IS '工作中心 ID（スナップショット）';
COMMENT ON COLUMN prd_work_report_labor.labor_hours IS '工数（h）';
COMMENT ON COLUMN prd_work_report_labor.hourly_rate IS '賃率（元/h、記録時点）';
COMMENT ON COLUMN prd_work_report_labor.labor_amount IS '金額（元）';
COMMENT ON COLUMN prd_work_report_labor.is_overtime IS '残業フラグ';
COMMENT ON COLUMN prd_work_report_labor.shift_code IS '班次';
COMMENT ON COLUMN prd_work_report_labor.start_at IS '作業開始';
COMMENT ON COLUMN prd_work_report_labor.end_at IS '作業終了';

-- prd_defect_code
CREATE TABLE prd_defect_code (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    deleted             BOOLEAN       NOT NULL DEFAULT FALSE,
    remark              VARCHAR(500),
    ext_data            JSONB,
    defect_code         VARCHAR(32)   NOT NULL,                  -- 缺陷代码（3 桁、例 101）
    defect_name         VARCHAR(200)  NOT NULL,                  -- 缺陷名称（例：定子铁心片间短路）
    defect_group        SMALLINT      NOT NULL DEFAULT 10,       -- 10:材料 20:加工 30:組立 40:電気性能 50:外観 60:包装
    defect_type         SMALLINT      NOT NULL DEFAULT 10,       -- 10:不良（返工可能） 20:报废（返工不可）
    default_disposition SMALLINT      NOT NULL DEFAULT 10,       -- 既定処置 10:返工 20:特采 30:报废 40:返品 50:分选
    responsibility_type SMALLINT,                                -- 既定責任区分 10:供方 20:自工序 30:前工序 40:设计 50:设备 60:材料
    description         VARCHAR(500),                            -- 現象説明・判定基準
    is_active           BOOLEAN       NOT NULL DEFAULT TRUE,     -- 有効フラグ
    CONSTRAINT pk_prd_defect_code PRIMARY KEY (id),
    CONSTRAINT ck_prd_defect_code_group CHECK (defect_group IN (10,20,30,40,50,60)),
    CONSTRAINT ck_prd_defect_code_type CHECK (defect_type IN (10,20))
);
ALTER TABLE prd_defect_code ENABLE ROW LEVEL SECURITY;
ALTER TABLE prd_defect_code FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON prd_defect_code
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_prd_defect_code ON prd_defect_code (tenant_id, company_id, defect_code) WHERE deleted = FALSE;
CREATE INDEX idx_prd_defect_code_group ON prd_defect_code (company_id, defect_group, is_active);
COMMENT ON COLUMN prd_defect_code.id IS '雪花 ID（主键）';
COMMENT ON COLUMN prd_defect_code.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN prd_defect_code.company_id IS '公司 ID（无默认值）';
COMMENT ON COLUMN prd_defect_code.created_at IS '创建时间';
COMMENT ON COLUMN prd_defect_code.created_by IS '创建人';
COMMENT ON COLUMN prd_defect_code.updated_at IS '更新时间';
COMMENT ON COLUMN prd_defect_code.updated_by IS '更新人';
COMMENT ON COLUMN prd_defect_code.version IS '乐观锁版本';
COMMENT ON COLUMN prd_defect_code.deleted IS '逻辑删除';
COMMENT ON COLUMN prd_defect_code.remark IS '备注';
COMMENT ON COLUMN prd_defect_code.ext_data IS '扩展字段';
COMMENT ON COLUMN prd_defect_code.defect_code IS '缺陷代码（3 桁、例 101）';
COMMENT ON COLUMN prd_defect_code.defect_name IS '缺陷名称（例：定子铁心片间短路）';
COMMENT ON COLUMN prd_defect_code.defect_group IS '10:材料 20:加工 30:組立 40:電気性能 50:外観 60:包装';
COMMENT ON COLUMN prd_defect_code.defect_type IS '10:不良（返工可能） 20:报废（返工不可）';
COMMENT ON COLUMN prd_defect_code.default_disposition IS '既定処置 10:返工 20:特采 30:报废 40:返品 50:分选';
COMMENT ON COLUMN prd_defect_code.responsibility_type IS '既定責任区分 10:供方 20:自工序 30:前工序 40:设计 50:设备 60:材料';
COMMENT ON COLUMN prd_defect_code.description IS '現象説明・判定基準';
COMMENT ON COLUMN prd_defect_code.is_active IS '有効フラグ';

-- prd_work_report_defect
CREATE TABLE prd_work_report_defect (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    remark              VARCHAR(500),
    ext_data            JSONB,
    report_id           BIGINT        NOT NULL,                  -- 报工单 ID → prd_work_report.id
    line_no             INT           NOT NULL,                  -- 行番号
    defect_code_id      BIGINT        NOT NULL,                  -- 缺陷代码 ID → prd_defect_code.id
    defect_code         VARCHAR(32)   NOT NULL,                  -- 缺陷代码（スナップショット）
    defect_name         VARCHAR(200)  NOT NULL,                  -- 缺陷名称（スナップショット）
    defect_qty          NUMERIC(18,4) NOT NULL,                  -- 数量
    defect_type         SMALLINT      NOT NULL DEFAULT 10,       -- 10:不良（返工可能） 20:报废
    disposition         SMALLINT      NOT NULL DEFAULT 10,       -- 10:返工 20:特采 30:报废 40:返品 50:分选 60:待定
    responsible_operation_seq INT,                               -- 责任工序 SEQ（原因工程）
    cause_type          SMALLINT,                                -- 10:人 20:机 30:料 40:法 50:环 60:测
    ncr_id              BIGINT,                                  -- NCR ID → prd_ncr.id
    rework_work_order_id BIGINT,                                 -- 返工工单 ID → prd_work_order.id
    CONSTRAINT pk_prd_work_report_defect PRIMARY KEY (id),
    CONSTRAINT fk_prd_work_report_defect_report FOREIGN KEY (report_id) REFERENCES prd_work_report (id) ON DELETE RESTRICT,
    CONSTRAINT fk_prd_work_report_defect_code FOREIGN KEY (defect_code_id) REFERENCES prd_defect_code (id),
    CONSTRAINT ck_prd_work_report_defect_qty CHECK (defect_qty > 0),
    CONSTRAINT ck_prd_work_report_defect_type CHECK (defect_type IN (10,20)),
    CONSTRAINT ck_prd_work_report_defect_disp CHECK (disposition IN (10,20,30,40,50,60))
);
ALTER TABLE prd_work_report_defect ENABLE ROW LEVEL SECURITY;
ALTER TABLE prd_work_report_defect FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON prd_work_report_defect
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_prd_work_report_defect_report_line ON prd_work_report_defect (company_id, report_id, line_no);
CREATE INDEX idx_prd_work_report_defect_code ON prd_work_report_defect (company_id, defect_code_id, created_at DESC);
COMMENT ON COLUMN prd_work_report_defect.id IS '雪花 ID（主键）';
COMMENT ON COLUMN prd_work_report_defect.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN prd_work_report_defect.company_id IS '公司 ID（无默认值）';
COMMENT ON COLUMN prd_work_report_defect.created_at IS '创建时间';
COMMENT ON COLUMN prd_work_report_defect.created_by IS '创建人';
COMMENT ON COLUMN prd_work_report_defect.updated_at IS '更新时间';
COMMENT ON COLUMN prd_work_report_defect.updated_by IS '更新人';
COMMENT ON COLUMN prd_work_report_defect.version IS '乐观锁版本';
COMMENT ON COLUMN prd_work_report_defect.remark IS '备注';
COMMENT ON COLUMN prd_work_report_defect.ext_data IS '扩展字段';
COMMENT ON COLUMN prd_work_report_defect.report_id IS '报工单 ID → prd_work_report.id';
COMMENT ON COLUMN prd_work_report_defect.line_no IS '行番号';
COMMENT ON COLUMN prd_work_report_defect.defect_code_id IS '缺陷代码 ID → prd_defect_code.id';
COMMENT ON COLUMN prd_work_report_defect.defect_code IS '缺陷代码（スナップショット）';
COMMENT ON COLUMN prd_work_report_defect.defect_name IS '缺陷名称（スナップショット）';
COMMENT ON COLUMN prd_work_report_defect.defect_qty IS '数量';
COMMENT ON COLUMN prd_work_report_defect.defect_type IS '10:不良（返工可能） 20:报废';
COMMENT ON COLUMN prd_work_report_defect.disposition IS '10:返工 20:特采 30:报废 40:返品 50:分选 60:待定';
COMMENT ON COLUMN prd_work_report_defect.responsible_operation_seq IS '责任工序 SEQ（原因工程）';
COMMENT ON COLUMN prd_work_report_defect.cause_type IS '10:人 20:机 30:料 40:法 50:环 60:测';
COMMENT ON COLUMN prd_work_report_defect.ncr_id IS 'NCR ID → prd_ncr.id';
COMMENT ON COLUMN prd_work_report_defect.rework_work_order_id IS '返工工单 ID → prd_work_order.id';

-- prd_completion_receipt
CREATE TABLE prd_completion_receipt (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    remark              VARCHAR(500),
    ext_data            JSONB,
    request_no          VARCHAR(32)   NOT NULL,                  -- PRD 要求番号 REQ{YYMMDD}{4桁}。FGI 伝票番号は INV が採番
    work_order_id       BIGINT        NOT NULL,                  -- 工单 ID → prd_work_order.id
    work_order_no       VARCHAR(32)   NOT NULL,                  -- 工单号（スナップショット）
    receipt_type        SMALLINT      NOT NULL DEFAULT 10,       -- 10:成品 20:半成品 30:返工品
    receipt_date        DATE          NOT NULL,                  -- 入庫要求日
    warehouse_id        BIGINT        NOT NULL,                  -- 入庫倉庫 ID → mdm_warehouse.id
    receipt_status      SMALLINT      NOT NULL DEFAULT 10,       -- 10:起票 30:要求確定（E24 発行済） 40:INV 処理完了 90:取消
    total_qty           NUMERIC(18,4) NOT NULL DEFAULT 0,        -- 合計入庫数量
    total_amount        NUMERIC(18,2) NOT NULL DEFAULT 0,        -- 合計金額（暫定完工原価）
    batch_no            VARCHAR(64),                             -- 製品批次号（INV 採番）
    stock_doc_id        BIGINT,                                  -- INV 採番の在庫伝票 ID（FGI）
    stock_doc_no        VARCHAR(32),                             -- INV 伝票番号（FGI）。**PRD は採番しない**
    stock_doc_status    SMALLINT      NOT NULL DEFAULT 0,        -- INV 側状態
    inspection_id       BIGINT,                                  -- FQC 検査単 ID → prd_inspection.id（入庫後・E15 で状態変換）
    is_last_receipt     BOOLEAN       NOT NULL DEFAULT FALSE,    -- 最終入庫フラグ（工单 40 判定）
    cost_status         SMALLINT      NOT NULL DEFAULT 0,        -- 原価状態 0:暫定 20:確定
    confirmed_at        TIMESTAMPTZ,                             -- 要求確定日時（E24 発行）
    cancel_reason       VARCHAR(500),                            -- 取消理由
    CONSTRAINT pk_prd_completion_receipt PRIMARY KEY (id),
    CONSTRAINT fk_prd_completion_receipt_wo FOREIGN KEY (work_order_id) REFERENCES prd_work_order (id),
    CONSTRAINT fk_prd_completion_receipt_wh FOREIGN KEY (warehouse_id) REFERENCES mdm_warehouse (id),
    CONSTRAINT ck_prd_completion_receipt_status CHECK (receipt_status IN (10,30,40,90)),
    CONSTRAINT ck_prd_completion_receipt_qty CHECK (total_qty >= 0)
);
ALTER TABLE prd_completion_receipt ENABLE ROW LEVEL SECURITY;
ALTER TABLE prd_completion_receipt FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON prd_completion_receipt
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_prd_completion_receipt_req ON prd_completion_receipt (tenant_id, company_id, request_no);
CREATE INDEX idx_prd_completion_receipt_doc ON prd_completion_receipt (company_id, stock_doc_no);
CREATE INDEX idx_prd_completion_receipt_wo ON prd_completion_receipt (company_id, work_order_id, receipt_status);
CREATE INDEX idx_prd_completion_receipt_date ON prd_completion_receipt (company_id, receipt_date, receipt_status);

-- 设计书矛盾：列 receipt_no 不存在（v1.1 起 INV 单一采番），暂不创建：CREATE UNIQUE INDEX uk_prd_completion_receipt_no ON prd_completion_receipt (tenant_id, company_id, receipt_no);
COMMENT ON COLUMN prd_completion_receipt.id IS '雪花 ID（主键）';
COMMENT ON COLUMN prd_completion_receipt.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN prd_completion_receipt.company_id IS '公司 ID（无默认值）';
COMMENT ON COLUMN prd_completion_receipt.created_at IS '创建时间';
COMMENT ON COLUMN prd_completion_receipt.created_by IS '创建人';
COMMENT ON COLUMN prd_completion_receipt.updated_at IS '更新时间';
COMMENT ON COLUMN prd_completion_receipt.updated_by IS '更新人';
COMMENT ON COLUMN prd_completion_receipt.version IS '乐观锁版本';
COMMENT ON COLUMN prd_completion_receipt.remark IS '备注';
COMMENT ON COLUMN prd_completion_receipt.ext_data IS '扩展字段';
COMMENT ON COLUMN prd_completion_receipt.request_no IS 'PRD 要求番号 REQ{YYMMDD}{4桁}。FGI 伝票番号は INV が採番';
COMMENT ON COLUMN prd_completion_receipt.work_order_id IS '工单 ID → prd_work_order.id';
COMMENT ON COLUMN prd_completion_receipt.work_order_no IS '工单号（スナップショット）';
COMMENT ON COLUMN prd_completion_receipt.receipt_type IS '10:成品 20:半成品 30:返工品';
COMMENT ON COLUMN prd_completion_receipt.receipt_date IS '入庫要求日';
COMMENT ON COLUMN prd_completion_receipt.warehouse_id IS '入庫倉庫 ID → mdm_warehouse.id';
COMMENT ON COLUMN prd_completion_receipt.receipt_status IS '10:起票 30:要求確定（E24 発行済） 40:INV 処理完了 90:取消';
COMMENT ON COLUMN prd_completion_receipt.total_qty IS '合計入庫数量';
COMMENT ON COLUMN prd_completion_receipt.total_amount IS '合計金額（暫定完工原価）';
COMMENT ON COLUMN prd_completion_receipt.batch_no IS '製品批次号（INV 採番）';
COMMENT ON COLUMN prd_completion_receipt.stock_doc_id IS 'INV 採番の在庫伝票 ID（FGI）';
COMMENT ON COLUMN prd_completion_receipt.stock_doc_no IS 'INV 伝票番号（FGI）。**PRD は採番しない**';
COMMENT ON COLUMN prd_completion_receipt.stock_doc_status IS 'INV 側状態';
COMMENT ON COLUMN prd_completion_receipt.inspection_id IS 'FQC 検査単 ID → prd_inspection.id（入庫後・E15 で状態変換）';
COMMENT ON COLUMN prd_completion_receipt.is_last_receipt IS '最終入庫フラグ（工单 40 判定）';
COMMENT ON COLUMN prd_completion_receipt.cost_status IS '原価状態 0:暫定 20:確定';
COMMENT ON COLUMN prd_completion_receipt.confirmed_at IS '要求確定日時（E24 発行）';
COMMENT ON COLUMN prd_completion_receipt.cancel_reason IS '取消理由';

-- prd_completion_receipt_line
CREATE TABLE prd_completion_receipt_line (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    remark              VARCHAR(500),
    ext_data            JSONB,
    receipt_id          BIGINT        NOT NULL,                  -- 入库单 ID → prd_completion_receipt.id
    line_no             INT           NOT NULL,                  -- 行番号
    material_id         BIGINT        NOT NULL,                  -- 入庫品目 ID → mdm_material.id
    material_code       VARCHAR(64)   NOT NULL,                  -- 品目编码（スナップショット）
    material_name       VARCHAR(200)  NOT NULL,                  -- 品目名称（スナップショット）
    material_spec       VARCHAR(200),                            -- 规格（スナップショット）
    uom_code            VARCHAR(16)   NOT NULL,                  -- 单位
    receipt_qty         NUMERIC(18,4) NOT NULL,                  -- 入庫数量
    batch_no            VARCHAR(64),                             -- 批次号
    warehouse_id        BIGINT        NOT NULL,                  -- 倉庫 ID
    location_id         BIGINT,                                  -- 庫位 ID
    unit_cost           NUMERIC(18,6) NOT NULL DEFAULT 0,        -- 暫定単位原価（材料費+人工費+製造費用）
    amount              NUMERIC(18,2) NOT NULL DEFAULT 0,        -- 金額（receipt_qty × unit_cost）
    quality_status      SMALLINT      NOT NULL DEFAULT 10,       -- 10:待検 20:合格 30:特采 40:不合格
    production_date     DATE,                                    -- 製造日
    expiry_date         DATE,                                    -- 有効期限（該当品のみ）
    wip_cost            NUMERIC(18,2) NOT NULL DEFAULT 0,        -- 当該数量に配賦した在制品原価
    stock_doc_line_id   BIGINT,                                  -- INV 採番の在庫伝票行 ID（E18 受信で設定）
    CONSTRAINT pk_prd_completion_receipt_line PRIMARY KEY (id),
    CONSTRAINT fk_prd_completion_receipt_line_rcpt FOREIGN KEY (receipt_id) REFERENCES prd_completion_receipt (id) ON DELETE RESTRICT,
    CONSTRAINT fk_prd_completion_receipt_line_material FOREIGN KEY (material_id) REFERENCES mdm_material (id),
    CONSTRAINT ck_prd_completion_receipt_line_qty CHECK (receipt_qty > 0),
    CONSTRAINT ck_prd_completion_receipt_line_quality CHECK (quality_status IN (10,20,30,40))
);
ALTER TABLE prd_completion_receipt_line ENABLE ROW LEVEL SECURITY;
ALTER TABLE prd_completion_receipt_line FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON prd_completion_receipt_line
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_prd_completion_receipt_line_rcpt_line ON prd_completion_receipt_line (company_id, receipt_id, line_no);
CREATE INDEX idx_prd_completion_receipt_line_material ON prd_completion_receipt_line (company_id, material_id, batch_no);
COMMENT ON COLUMN prd_completion_receipt_line.id IS '雪花 ID（主键）';
COMMENT ON COLUMN prd_completion_receipt_line.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN prd_completion_receipt_line.company_id IS '公司 ID（无默认值）';
COMMENT ON COLUMN prd_completion_receipt_line.created_at IS '创建时间';
COMMENT ON COLUMN prd_completion_receipt_line.created_by IS '创建人';
COMMENT ON COLUMN prd_completion_receipt_line.updated_at IS '更新时间';
COMMENT ON COLUMN prd_completion_receipt_line.updated_by IS '更新人';
COMMENT ON COLUMN prd_completion_receipt_line.version IS '乐观锁版本';
COMMENT ON COLUMN prd_completion_receipt_line.remark IS '备注';
COMMENT ON COLUMN prd_completion_receipt_line.ext_data IS '扩展字段';
COMMENT ON COLUMN prd_completion_receipt_line.receipt_id IS '入库单 ID → prd_completion_receipt.id';
COMMENT ON COLUMN prd_completion_receipt_line.line_no IS '行番号';
COMMENT ON COLUMN prd_completion_receipt_line.material_id IS '入庫品目 ID → mdm_material.id';
COMMENT ON COLUMN prd_completion_receipt_line.material_code IS '品目编码（スナップショット）';
COMMENT ON COLUMN prd_completion_receipt_line.material_name IS '品目名称（スナップショット）';
COMMENT ON COLUMN prd_completion_receipt_line.material_spec IS '规格（スナップショット）';
COMMENT ON COLUMN prd_completion_receipt_line.uom_code IS '单位';
COMMENT ON COLUMN prd_completion_receipt_line.receipt_qty IS '入庫数量';
COMMENT ON COLUMN prd_completion_receipt_line.batch_no IS '批次号';
COMMENT ON COLUMN prd_completion_receipt_line.warehouse_id IS '倉庫 ID';
COMMENT ON COLUMN prd_completion_receipt_line.location_id IS '庫位 ID';
COMMENT ON COLUMN prd_completion_receipt_line.unit_cost IS '暫定単位原価（材料費+人工費+製造費用）';
COMMENT ON COLUMN prd_completion_receipt_line.amount IS '金額（receipt_qty × unit_cost）';
COMMENT ON COLUMN prd_completion_receipt_line.quality_status IS '10:待検 20:合格 30:特采 40:不合格';
COMMENT ON COLUMN prd_completion_receipt_line.production_date IS '製造日';
COMMENT ON COLUMN prd_completion_receipt_line.expiry_date IS '有効期限（該当品のみ）';
COMMENT ON COLUMN prd_completion_receipt_line.wip_cost IS '当該数量に配賦した在制品原価';
COMMENT ON COLUMN prd_completion_receipt_line.stock_doc_line_id IS 'INV 採番の在庫伝票行 ID（E18 受信で設定）';

-- prd_outsourcing_order
CREATE TABLE prd_outsourcing_order (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    remark              VARCHAR(500),
    ext_data            JSONB,
    outsourcing_no      VARCHAR(32)   NOT NULL,                  -- 委外订单号 OS{YYMMDD}{4桁}
    supplier_id         BIGINT        NOT NULL,                  -- 仕入先 ID → mdm_supplier.id
    supplier_code       VARCHAR(32)   NOT NULL,                  -- 仕入先编码（スナップショット）
    supplier_name       VARCHAR(200)  NOT NULL,                  -- 仕入先名称（スナップショット）
    factory_id          BIGINT        NOT NULL,                  -- 工厂 ID → mdm_factory.id
    outsourcing_type    SMALLINT      NOT NULL DEFAULT 10,       -- 10:工序委外 20:部品加工 30:整体委外
    order_date          DATE          NOT NULL,                  -- 下单日
    planned_delivery_date DATE        NOT NULL,                  -- 契約納期
    actual_delivery_date DATE,                                   -- 実際入荷日（最終）
    currency_code       VARCHAR(3)    NOT NULL DEFAULT 'CNY',    -- 通貨
    tax_rate            NUMERIC(7,4)  NOT NULL DEFAULT 13,       -- 税率（%）13.0000
    total_qty           NUMERIC(18,4) NOT NULL DEFAULT 0,        -- 合計委外数量
    issued_qty          NUMERIC(18,4) NOT NULL DEFAULT 0,        -- 発料済数量（累計）
    received_qty        NUMERIC(18,4) NOT NULL DEFAULT 0,        -- 受入済数量（累計）
    processing_amount   NUMERIC(18,2) NOT NULL DEFAULT 0,        -- 加工費（税抜）合計
    tax_amount          NUMERIC(18,2) NOT NULL DEFAULT 0,        -- 税額
    total_amount        NUMERIC(18,2) NOT NULL DEFAULT 0,        -- 税込合計
    os_status           SMALLINT      NOT NULL DEFAULT 10,       -- 10:草稿 20:承認待ち 25:承認済 30:発注済 35:一部受入 40:完了 90:取消 95:却下
    source_type         SMALLINT,                                -- 10:工单 20:MRP计划订单 30:手工 40:采购申请
    source_id           BIGINT,                                  -- 来源 ID
    source_no           VARCHAR(64),                             -- 来源单号
    contract_no         VARCHAR(64),                             -- 加工合同号
    buyer_user_id       BIGINT,                                  -- 采购担当 → sys_user.id
    department_id       BIGINT,                                  -- 部門 ID
    settlement_status   SMALLINT      NOT NULL DEFAULT 0,        -- 结算状態 0:未 10:一部 20:完了
    submitted_at        TIMESTAMPTZ,                             -- 提出日時
    approved_by         BIGINT,                                  -- 承認者
    approved_at         TIMESTAMPTZ,                             -- 承認日時
    cancel_reason       VARCHAR(500),                            -- 取消理由
    CONSTRAINT pk_prd_outsourcing_order PRIMARY KEY (id),
    CONSTRAINT fk_prd_outsourcing_order_supplier FOREIGN KEY (supplier_id) REFERENCES mdm_supplier (id),
    CONSTRAINT fk_prd_outsourcing_order_factory FOREIGN KEY (factory_id) REFERENCES mdm_factory (id),
    CONSTRAINT ck_prd_outsourcing_order_status CHECK (os_status IN (10,20,25,30,35,40,90,95)),
    CONSTRAINT ck_prd_outsourcing_order_qty CHECK (total_qty > 0 AND received_qty >= 0),
    CONSTRAINT ck_prd_outsourcing_order_amount CHECK (processing_amount >= 0 AND tax_amount >= 0)
);
ALTER TABLE prd_outsourcing_order ENABLE ROW LEVEL SECURITY;
ALTER TABLE prd_outsourcing_order FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON prd_outsourcing_order
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_prd_outsourcing_order_no ON prd_outsourcing_order (tenant_id, company_id, outsourcing_no);
CREATE INDEX idx_prd_outsourcing_order_supplier ON prd_outsourcing_order (company_id, supplier_id, os_status, planned_delivery_date);
CREATE INDEX idx_prd_outsourcing_order_status ON prd_outsourcing_order (company_id, os_status, planned_delivery_date);
COMMENT ON COLUMN prd_outsourcing_order.id IS '雪花 ID（主键）';
COMMENT ON COLUMN prd_outsourcing_order.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN prd_outsourcing_order.company_id IS '公司 ID（无默认值）';
COMMENT ON COLUMN prd_outsourcing_order.created_at IS '创建时间';
COMMENT ON COLUMN prd_outsourcing_order.created_by IS '创建人';
COMMENT ON COLUMN prd_outsourcing_order.updated_at IS '更新时间';
COMMENT ON COLUMN prd_outsourcing_order.updated_by IS '更新人';
COMMENT ON COLUMN prd_outsourcing_order.version IS '乐观锁版本';
COMMENT ON COLUMN prd_outsourcing_order.remark IS '备注';
COMMENT ON COLUMN prd_outsourcing_order.ext_data IS '扩展字段';
COMMENT ON COLUMN prd_outsourcing_order.outsourcing_no IS '委外订单号 OS{YYMMDD}{4桁}';
COMMENT ON COLUMN prd_outsourcing_order.supplier_id IS '仕入先 ID → mdm_supplier.id';
COMMENT ON COLUMN prd_outsourcing_order.supplier_code IS '仕入先编码（スナップショット）';
COMMENT ON COLUMN prd_outsourcing_order.supplier_name IS '仕入先名称（スナップショット）';
COMMENT ON COLUMN prd_outsourcing_order.factory_id IS '工厂 ID → mdm_factory.id';
COMMENT ON COLUMN prd_outsourcing_order.outsourcing_type IS '10:工序委外 20:部品加工 30:整体委外';
COMMENT ON COLUMN prd_outsourcing_order.order_date IS '下单日';
COMMENT ON COLUMN prd_outsourcing_order.planned_delivery_date IS '契約納期';
COMMENT ON COLUMN prd_outsourcing_order.actual_delivery_date IS '実際入荷日（最終）';
COMMENT ON COLUMN prd_outsourcing_order.currency_code IS '通貨';
COMMENT ON COLUMN prd_outsourcing_order.tax_rate IS '税率（%）13.0000';
COMMENT ON COLUMN prd_outsourcing_order.total_qty IS '合計委外数量';
COMMENT ON COLUMN prd_outsourcing_order.issued_qty IS '発料済数量（累計）';
COMMENT ON COLUMN prd_outsourcing_order.received_qty IS '受入済数量（累計）';
COMMENT ON COLUMN prd_outsourcing_order.processing_amount IS '加工費（税抜）合計';
COMMENT ON COLUMN prd_outsourcing_order.tax_amount IS '税額';
COMMENT ON COLUMN prd_outsourcing_order.total_amount IS '税込合計';
COMMENT ON COLUMN prd_outsourcing_order.os_status IS '10:草稿 20:承認待ち 25:承認済 30:発注済 35:一部受入 40:完了 90:取消 95:却下';
COMMENT ON COLUMN prd_outsourcing_order.source_type IS '10:工单 20:MRP计划订单 30:手工 40:采购申请';
COMMENT ON COLUMN prd_outsourcing_order.source_id IS '来源 ID';
COMMENT ON COLUMN prd_outsourcing_order.source_no IS '来源单号';
COMMENT ON COLUMN prd_outsourcing_order.contract_no IS '加工合同号';
COMMENT ON COLUMN prd_outsourcing_order.buyer_user_id IS '采购担当 → sys_user.id';
COMMENT ON COLUMN prd_outsourcing_order.department_id IS '部門 ID';
COMMENT ON COLUMN prd_outsourcing_order.settlement_status IS '结算状態 0:未 10:一部 20:完了';
COMMENT ON COLUMN prd_outsourcing_order.submitted_at IS '提出日時';
COMMENT ON COLUMN prd_outsourcing_order.approved_by IS '承認者';
COMMENT ON COLUMN prd_outsourcing_order.approved_at IS '承認日時';
COMMENT ON COLUMN prd_outsourcing_order.cancel_reason IS '取消理由';

-- prd_outsourcing_order_line
CREATE TABLE prd_outsourcing_order_line (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    remark              VARCHAR(500),
    ext_data            JSONB,
    outsourcing_order_id BIGINT       NOT NULL,                  -- 委外订单 ID → prd_outsourcing_order.id
    line_no             INT           NOT NULL,                  -- 行番号
    material_id         BIGINT        NOT NULL,                  -- 委外品目（被加工品）ID → mdm_material.id
    material_code       VARCHAR(64)   NOT NULL,                  -- 品目编码（スナップショット）
    material_name       VARCHAR(200)  NOT NULL,                  -- 品目名称（スナップショット）
    material_spec       VARCHAR(200),                            -- 规格（スナップショット）
    uom_code            VARCHAR(16)   NOT NULL,                  -- 单位
    order_qty           NUMERIC(18,4) NOT NULL,                  -- 委外数量
    issued_qty          NUMERIC(18,4) NOT NULL DEFAULT 0,        -- 発料済数量
    received_qty        NUMERIC(18,4) NOT NULL DEFAULT 0,        -- 受入済数量
    defect_qty          NUMERIC(18,4) NOT NULL DEFAULT 0,        -- 不合格返品数量
    processing_unit_price NUMERIC(18,6) NOT NULL DEFAULT 0,      -- 加工単価（税抜、元/単位）
    processing_amount   NUMERIC(18,2) NOT NULL DEFAULT 0,        -- 加工費（税抜）= order_qty × price
    planned_delivery_date DATE        NOT NULL,                  -- 明細納期
    supply_material_flag BOOLEAN      NOT NULL DEFAULT TRUE,     -- 支給材料有無（TRUE=支給）
    source_work_order_id BIGINT,                                 -- 由来工单 ID → prd_work_order.id
    CONSTRAINT pk_prd_outsourcing_order_line PRIMARY KEY (id),
    CONSTRAINT fk_prd_outsourcing_order_line_order FOREIGN KEY (outsourcing_order_id) REFERENCES prd_outsourcing_order (id) ON DELETE RESTRICT,
    CONSTRAINT fk_prd_outsourcing_order_line_material FOREIGN KEY (material_id) REFERENCES mdm_material (id),
    CONSTRAINT ck_prd_outsourcing_order_line_qty CHECK (order_qty > 0 AND received_qty >= 0),
    CONSTRAINT ck_prd_outsourcing_order_line_price CHECK (processing_unit_price >= 0)
);
ALTER TABLE prd_outsourcing_order_line ENABLE ROW LEVEL SECURITY;
ALTER TABLE prd_outsourcing_order_line FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON prd_outsourcing_order_line
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_prd_outsourcing_order_line_order_line ON prd_outsourcing_order_line (company_id, outsourcing_order_id, line_no);
CREATE INDEX idx_prd_outsourcing_order_line_material ON prd_outsourcing_order_line (company_id, material_id);
COMMENT ON COLUMN prd_outsourcing_order_line.id IS '雪花 ID（主键）';
COMMENT ON COLUMN prd_outsourcing_order_line.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN prd_outsourcing_order_line.company_id IS '公司 ID（无默认值）';
COMMENT ON COLUMN prd_outsourcing_order_line.created_at IS '创建时间';
COMMENT ON COLUMN prd_outsourcing_order_line.created_by IS '创建人';
COMMENT ON COLUMN prd_outsourcing_order_line.updated_at IS '更新时间';
COMMENT ON COLUMN prd_outsourcing_order_line.updated_by IS '更新人';
COMMENT ON COLUMN prd_outsourcing_order_line.version IS '乐观锁版本';
COMMENT ON COLUMN prd_outsourcing_order_line.remark IS '备注';
COMMENT ON COLUMN prd_outsourcing_order_line.ext_data IS '扩展字段';
COMMENT ON COLUMN prd_outsourcing_order_line.outsourcing_order_id IS '委外订单 ID → prd_outsourcing_order.id';
COMMENT ON COLUMN prd_outsourcing_order_line.line_no IS '行番号';
COMMENT ON COLUMN prd_outsourcing_order_line.material_id IS '委外品目（被加工品）ID → mdm_material.id';
COMMENT ON COLUMN prd_outsourcing_order_line.material_code IS '品目编码（スナップショット）';
COMMENT ON COLUMN prd_outsourcing_order_line.material_name IS '品目名称（スナップショット）';
COMMENT ON COLUMN prd_outsourcing_order_line.material_spec IS '规格（スナップショット）';
COMMENT ON COLUMN prd_outsourcing_order_line.uom_code IS '单位';
COMMENT ON COLUMN prd_outsourcing_order_line.order_qty IS '委外数量';
COMMENT ON COLUMN prd_outsourcing_order_line.issued_qty IS '発料済数量';
COMMENT ON COLUMN prd_outsourcing_order_line.received_qty IS '受入済数量';
COMMENT ON COLUMN prd_outsourcing_order_line.defect_qty IS '不合格返品数量';
COMMENT ON COLUMN prd_outsourcing_order_line.processing_unit_price IS '加工単価（税抜、元/単位）';
COMMENT ON COLUMN prd_outsourcing_order_line.processing_amount IS '加工費（税抜）= order_qty × price';
COMMENT ON COLUMN prd_outsourcing_order_line.planned_delivery_date IS '明細納期';
COMMENT ON COLUMN prd_outsourcing_order_line.supply_material_flag IS '支給材料有無（TRUE=支給）';
COMMENT ON COLUMN prd_outsourcing_order_line.source_work_order_id IS '由来工单 ID → prd_work_order.id';

-- prd_outsourcing_issue
CREATE TABLE prd_outsourcing_issue (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    remark              VARCHAR(500),
    ext_data            JSONB,
    request_no          VARCHAR(32)   NOT NULL,                  -- PRD 要求番号 REQ{YYMMDD}{4桁}。OSI 伝票番号は INV が採番
    outsourcing_order_id BIGINT       NOT NULL,                  -- 委外订单 ID → prd_outsourcing_order.id
    outsourcing_no      VARCHAR(32)   NOT NULL,                  -- 委外订单号（スナップショット）
    supplier_id         BIGINT        NOT NULL,                  -- 仕入先 ID
    issue_date          DATE          NOT NULL,                  -- 発料要求日
    warehouse_id        BIGINT        NOT NULL,                  -- 出庫倉庫 ID
    issue_status        SMALLINT      NOT NULL DEFAULT 10,       -- 10:起票 30:要求確定（E25 発行済） 40:INV 処理完了 90:取消
    total_qty           NUMERIC(18,4) NOT NULL DEFAULT 0,        -- 合計発料数量
    total_amount        NUMERIC(18,2) NOT NULL DEFAULT 0,        -- 合計金額（材料原価参考）
    stock_doc_id        BIGINT,                                  -- INV 採番の在庫伝票 ID（OSI）
    stock_doc_no        VARCHAR(32),                             -- INV 伝票番号（OSI）。**PRD は採番しない**
    stock_doc_status    SMALLINT      NOT NULL DEFAULT 0,        -- INV 側状態
    issued_by           BIGINT,                                  -- 要求者 → sys_user.id
    issued_at           TIMESTAMPTZ,                             -- 要求確定日時（E25 発行）
    cancel_reason       VARCHAR(500),                            -- 取消理由
    CONSTRAINT pk_prd_outsourcing_issue PRIMARY KEY (id),
    CONSTRAINT fk_prd_outsourcing_issue_order FOREIGN KEY (outsourcing_order_id) REFERENCES prd_outsourcing_order (id),
    CONSTRAINT fk_prd_outsourcing_issue_wh FOREIGN KEY (warehouse_id) REFERENCES mdm_warehouse (id),
    CONSTRAINT ck_prd_outsourcing_issue_status CHECK (issue_status IN (10,30,40,90)),
    CONSTRAINT ck_prd_outsourcing_issue_qty CHECK (total_qty >= 0)
);
ALTER TABLE prd_outsourcing_issue ENABLE ROW LEVEL SECURITY;
ALTER TABLE prd_outsourcing_issue FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON prd_outsourcing_issue
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_prd_outsourcing_issue_req ON prd_outsourcing_issue (tenant_id, company_id, request_no);
CREATE INDEX idx_prd_outsourcing_issue_doc ON prd_outsourcing_issue (company_id, stock_doc_no);
CREATE INDEX idx_prd_outsourcing_issue_order ON prd_outsourcing_issue (company_id, outsourcing_order_id, issue_status);

-- 设计书矛盾：列 issue_no 不存在（v1.1 起 INV 单一采番），暂不创建：CREATE UNIQUE INDEX uk_prd_outsourcing_issue_no ON prd_outsourcing_issue (tenant_id, company_id, issue_no);
COMMENT ON COLUMN prd_outsourcing_issue.id IS '雪花 ID（主键）';
COMMENT ON COLUMN prd_outsourcing_issue.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN prd_outsourcing_issue.company_id IS '公司 ID（无默认值）';
COMMENT ON COLUMN prd_outsourcing_issue.created_at IS '创建时间';
COMMENT ON COLUMN prd_outsourcing_issue.created_by IS '创建人';
COMMENT ON COLUMN prd_outsourcing_issue.updated_at IS '更新时间';
COMMENT ON COLUMN prd_outsourcing_issue.updated_by IS '更新人';
COMMENT ON COLUMN prd_outsourcing_issue.version IS '乐观锁版本';
COMMENT ON COLUMN prd_outsourcing_issue.remark IS '备注';
COMMENT ON COLUMN prd_outsourcing_issue.ext_data IS '扩展字段';
COMMENT ON COLUMN prd_outsourcing_issue.request_no IS 'PRD 要求番号 REQ{YYMMDD}{4桁}。OSI 伝票番号は INV が採番';
COMMENT ON COLUMN prd_outsourcing_issue.outsourcing_order_id IS '委外订单 ID → prd_outsourcing_order.id';
COMMENT ON COLUMN prd_outsourcing_issue.outsourcing_no IS '委外订单号（スナップショット）';
COMMENT ON COLUMN prd_outsourcing_issue.supplier_id IS '仕入先 ID';
COMMENT ON COLUMN prd_outsourcing_issue.issue_date IS '発料要求日';
COMMENT ON COLUMN prd_outsourcing_issue.warehouse_id IS '出庫倉庫 ID';
COMMENT ON COLUMN prd_outsourcing_issue.issue_status IS '10:起票 30:要求確定（E25 発行済） 40:INV 処理完了 90:取消';
COMMENT ON COLUMN prd_outsourcing_issue.total_qty IS '合計発料数量';
COMMENT ON COLUMN prd_outsourcing_issue.total_amount IS '合計金額（材料原価参考）';
COMMENT ON COLUMN prd_outsourcing_issue.stock_doc_id IS 'INV 採番の在庫伝票 ID（OSI）';
COMMENT ON COLUMN prd_outsourcing_issue.stock_doc_no IS 'INV 伝票番号（OSI）。**PRD は採番しない**';
COMMENT ON COLUMN prd_outsourcing_issue.stock_doc_status IS 'INV 側状態';
COMMENT ON COLUMN prd_outsourcing_issue.issued_by IS '要求者 → sys_user.id';
COMMENT ON COLUMN prd_outsourcing_issue.issued_at IS '要求確定日時（E25 発行）';
COMMENT ON COLUMN prd_outsourcing_issue.cancel_reason IS '取消理由';

-- prd_outsourcing_issue_line
CREATE TABLE prd_outsourcing_issue_line (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    remark              VARCHAR(500),
    ext_data            JSONB,
    issue_id            BIGINT        NOT NULL,                  -- 发料单 ID → prd_outsourcing_issue.id
    line_no             INT           NOT NULL,                  -- 行番号
    outsourcing_order_line_id BIGINT,                            -- 委外订单明细 ID → prd_outsourcing_order_line.id
    material_id         BIGINT        NOT NULL,                  -- 支給材料 ID → mdm_material.id
    material_code       VARCHAR(64)   NOT NULL,                  -- 物料编码（スナップショット）
    material_name       VARCHAR(200)  NOT NULL,                  -- 物料名称（スナップショット）
    uom_code            VARCHAR(16)   NOT NULL,                  -- 单位
    issue_qty           NUMERIC(18,4) NOT NULL,                  -- 発料数量
    return_qty          NUMERIC(18,4) NOT NULL DEFAULT 0,        -- 受入時の余料返却数量（後日）
    batch_no            VARCHAR(64),                             -- 批次号
    warehouse_id        BIGINT        NOT NULL,                  -- 倉庫 ID
    location_id         BIGINT,                                  -- 庫位 ID
    unit_cost           NUMERIC(18,6) NOT NULL DEFAULT 0,        -- 平均単価（発料時点）
    amount              NUMERIC(18,2) NOT NULL DEFAULT 0,        -- 金額
    stock_doc_line_id   BIGINT,                                  -- INV 採番の在庫伝票行 ID（E18 受信で設定）
    CONSTRAINT pk_prd_outsourcing_issue_line PRIMARY KEY (id),
    CONSTRAINT fk_prd_outsourcing_issue_line_issue FOREIGN KEY (issue_id) REFERENCES prd_outsourcing_issue (id) ON DELETE RESTRICT,
    CONSTRAINT fk_prd_outsourcing_issue_line_material FOREIGN KEY (material_id) REFERENCES mdm_material (id),
    CONSTRAINT ck_prd_outsourcing_issue_line_qty CHECK (issue_qty > 0),
    CONSTRAINT ck_prd_outsourcing_issue_line_amt CHECK (amount >= 0)
);
ALTER TABLE prd_outsourcing_issue_line ENABLE ROW LEVEL SECURITY;
ALTER TABLE prd_outsourcing_issue_line FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON prd_outsourcing_issue_line
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_prd_outsourcing_issue_line_issue_line ON prd_outsourcing_issue_line (company_id, issue_id, line_no);
CREATE INDEX idx_prd_outsourcing_issue_line_material ON prd_outsourcing_issue_line (company_id, material_id, batch_no);
COMMENT ON COLUMN prd_outsourcing_issue_line.id IS '雪花 ID（主键）';
COMMENT ON COLUMN prd_outsourcing_issue_line.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN prd_outsourcing_issue_line.company_id IS '公司 ID（无默认值）';
COMMENT ON COLUMN prd_outsourcing_issue_line.created_at IS '创建时间';
COMMENT ON COLUMN prd_outsourcing_issue_line.created_by IS '创建人';
COMMENT ON COLUMN prd_outsourcing_issue_line.updated_at IS '更新时间';
COMMENT ON COLUMN prd_outsourcing_issue_line.updated_by IS '更新人';
COMMENT ON COLUMN prd_outsourcing_issue_line.version IS '乐观锁版本';
COMMENT ON COLUMN prd_outsourcing_issue_line.remark IS '备注';
COMMENT ON COLUMN prd_outsourcing_issue_line.ext_data IS '扩展字段';
COMMENT ON COLUMN prd_outsourcing_issue_line.issue_id IS '发料单 ID → prd_outsourcing_issue.id';
COMMENT ON COLUMN prd_outsourcing_issue_line.line_no IS '行番号';
COMMENT ON COLUMN prd_outsourcing_issue_line.outsourcing_order_line_id IS '委外订单明细 ID → prd_outsourcing_order_line.id';
COMMENT ON COLUMN prd_outsourcing_issue_line.material_id IS '支給材料 ID → mdm_material.id';
COMMENT ON COLUMN prd_outsourcing_issue_line.material_code IS '物料编码（スナップショット）';
COMMENT ON COLUMN prd_outsourcing_issue_line.material_name IS '物料名称（スナップショット）';
COMMENT ON COLUMN prd_outsourcing_issue_line.uom_code IS '单位';
COMMENT ON COLUMN prd_outsourcing_issue_line.issue_qty IS '発料数量';
COMMENT ON COLUMN prd_outsourcing_issue_line.return_qty IS '受入時の余料返却数量（後日）';
COMMENT ON COLUMN prd_outsourcing_issue_line.batch_no IS '批次号';
COMMENT ON COLUMN prd_outsourcing_issue_line.warehouse_id IS '倉庫 ID';
COMMENT ON COLUMN prd_outsourcing_issue_line.location_id IS '庫位 ID';
COMMENT ON COLUMN prd_outsourcing_issue_line.unit_cost IS '平均単価（発料時点）';
COMMENT ON COLUMN prd_outsourcing_issue_line.amount IS '金額';
COMMENT ON COLUMN prd_outsourcing_issue_line.stock_doc_line_id IS 'INV 採番の在庫伝票行 ID（E18 受信で設定）';

-- prd_outsourcing_receipt
CREATE TABLE prd_outsourcing_receipt (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    remark              VARCHAR(500),
    ext_data            JSONB,
    request_no          VARCHAR(32)   NOT NULL,                  -- PRD 要求番号 REQ{YYMMDD}{4桁}。OSR 伝票番号は INV が採番
    outsourcing_order_id BIGINT       NOT NULL,                  -- 委外订单 ID → prd_outsourcing_order.id
    outsourcing_no      VARCHAR(32)   NOT NULL,                  -- 委外订单号（スナップショット）
    supplier_id         BIGINT        NOT NULL,                  -- 仕入先 ID
    receipt_date        DATE          NOT NULL,                  -- 受入要求日
    warehouse_id        BIGINT        NOT NULL,                  -- 入庫倉庫 ID
    receipt_status      SMALLINT      NOT NULL DEFAULT 10,       -- 10:起票 30:要求確定（E26 発行済） 40:INV 処理完了 90:取消
    total_qty           NUMERIC(18,4) NOT NULL DEFAULT 0,        -- 合計受入数量
    total_material_cost NUMERIC(18,2) NOT NULL DEFAULT 0,        -- 材料費合計（発料原価）
    total_processing_amount NUMERIC(18,2) NOT NULL DEFAULT 0,    -- 加工費合計（税抜）
    total_amount        NUMERIC(18,2) NOT NULL DEFAULT 0,        -- 合計金額（材料費＋加工費）
    stock_doc_id        BIGINT,                                  -- INV 採番の在庫伝票 ID（OSR）
    stock_doc_no        VARCHAR(32),                             -- INV 伝票番号（OSR）。**PRD は採番しない**
    stock_doc_status    SMALLINT      NOT NULL DEFAULT 0,        -- INV 側状態
    inspection_id       BIGINT,                                  -- IQC 検査単 ID → prd_inspection.id
    received_by         BIGINT,                                  -- 要求者 → sys_user.id
    confirmed_at        TIMESTAMPTZ,                             -- 要求確定日時（E26 発行）
    cancel_reason       VARCHAR(500),                            -- 取消理由
    CONSTRAINT pk_prd_outsourcing_receipt PRIMARY KEY (id),
    CONSTRAINT fk_prd_outsourcing_receipt_order FOREIGN KEY (outsourcing_order_id) REFERENCES prd_outsourcing_order (id),
    CONSTRAINT fk_prd_outsourcing_receipt_wh FOREIGN KEY (warehouse_id) REFERENCES mdm_warehouse (id),
    CONSTRAINT ck_prd_outsourcing_receipt_status CHECK (receipt_status IN (10,30,40,90)),
    CONSTRAINT ck_prd_outsourcing_receipt_qty CHECK (total_qty >= 0)
);
ALTER TABLE prd_outsourcing_receipt ENABLE ROW LEVEL SECURITY;
ALTER TABLE prd_outsourcing_receipt FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON prd_outsourcing_receipt
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_prd_outsourcing_receipt_req ON prd_outsourcing_receipt (tenant_id, company_id, request_no);
CREATE INDEX idx_prd_outsourcing_receipt_doc ON prd_outsourcing_receipt (company_id, stock_doc_no);
CREATE INDEX idx_prd_outsourcing_receipt_order ON prd_outsourcing_receipt (company_id, outsourcing_order_id, receipt_status);

-- 设计书矛盾：列 receipt_no 不存在（v1.1 起 INV 单一采番），暂不创建：CREATE UNIQUE INDEX uk_prd_outsourcing_receipt_no ON prd_outsourcing_receipt (tenant_id, company_id, receipt_no);
COMMENT ON COLUMN prd_outsourcing_receipt.id IS '雪花 ID（主键）';
COMMENT ON COLUMN prd_outsourcing_receipt.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN prd_outsourcing_receipt.company_id IS '公司 ID（无默认值）';
COMMENT ON COLUMN prd_outsourcing_receipt.created_at IS '创建时间';
COMMENT ON COLUMN prd_outsourcing_receipt.created_by IS '创建人';
COMMENT ON COLUMN prd_outsourcing_receipt.updated_at IS '更新时间';
COMMENT ON COLUMN prd_outsourcing_receipt.updated_by IS '更新人';
COMMENT ON COLUMN prd_outsourcing_receipt.version IS '乐观锁版本';
COMMENT ON COLUMN prd_outsourcing_receipt.remark IS '备注';
COMMENT ON COLUMN prd_outsourcing_receipt.ext_data IS '扩展字段';
COMMENT ON COLUMN prd_outsourcing_receipt.request_no IS 'PRD 要求番号 REQ{YYMMDD}{4桁}。OSR 伝票番号は INV が採番';
COMMENT ON COLUMN prd_outsourcing_receipt.outsourcing_order_id IS '委外订单 ID → prd_outsourcing_order.id';
COMMENT ON COLUMN prd_outsourcing_receipt.outsourcing_no IS '委外订单号（スナップショット）';
COMMENT ON COLUMN prd_outsourcing_receipt.supplier_id IS '仕入先 ID';
COMMENT ON COLUMN prd_outsourcing_receipt.receipt_date IS '受入要求日';
COMMENT ON COLUMN prd_outsourcing_receipt.warehouse_id IS '入庫倉庫 ID';
COMMENT ON COLUMN prd_outsourcing_receipt.receipt_status IS '10:起票 30:要求確定（E26 発行済） 40:INV 処理完了 90:取消';
COMMENT ON COLUMN prd_outsourcing_receipt.total_qty IS '合計受入数量';
COMMENT ON COLUMN prd_outsourcing_receipt.total_material_cost IS '材料費合計（発料原価）';
COMMENT ON COLUMN prd_outsourcing_receipt.total_processing_amount IS '加工費合計（税抜）';
COMMENT ON COLUMN prd_outsourcing_receipt.total_amount IS '合計金額（材料費＋加工費）';
COMMENT ON COLUMN prd_outsourcing_receipt.stock_doc_id IS 'INV 採番の在庫伝票 ID（OSR）';
COMMENT ON COLUMN prd_outsourcing_receipt.stock_doc_no IS 'INV 伝票番号（OSR）。**PRD は採番しない**';
COMMENT ON COLUMN prd_outsourcing_receipt.stock_doc_status IS 'INV 側状態';
COMMENT ON COLUMN prd_outsourcing_receipt.inspection_id IS 'IQC 検査単 ID → prd_inspection.id';
COMMENT ON COLUMN prd_outsourcing_receipt.received_by IS '要求者 → sys_user.id';
COMMENT ON COLUMN prd_outsourcing_receipt.confirmed_at IS '要求確定日時（E26 発行）';
COMMENT ON COLUMN prd_outsourcing_receipt.cancel_reason IS '取消理由';

-- prd_outsourcing_receipt_line
CREATE TABLE prd_outsourcing_receipt_line (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    remark              VARCHAR(500),
    ext_data            JSONB,
    receipt_id          BIGINT        NOT NULL,                  -- 收货单 ID → prd_outsourcing_receipt.id
    line_no             INT           NOT NULL,                  -- 行番号
    outsourcing_order_line_id BIGINT,                            -- 委外订单明细 ID → prd_outsourcing_order_line.id
    material_id         BIGINT        NOT NULL,                  -- 受入品目 ID → mdm_material.id
    material_code       VARCHAR(64)   NOT NULL,                  -- 品目编码（スナップショット）
    material_name       VARCHAR(200)  NOT NULL,                  -- 品目名称（スナップショット）
    uom_code            VARCHAR(16)   NOT NULL,                  -- 单位
    receipt_qty         NUMERIC(18,4) NOT NULL,                  -- 受入数量
    defect_qty          NUMERIC(18,4) NOT NULL DEFAULT 0,        -- 不合格数量（返品/再加工）
    batch_no            VARCHAR(64),                             -- 批次号
    warehouse_id        BIGINT        NOT NULL,                  -- 倉庫 ID
    location_id         BIGINT,                                  -- 庫位 ID
    unit_material_cost  NUMERIC(18,6) NOT NULL DEFAULT 0,        -- 単位材料費（発料原価ベース）
    processing_unit_price NUMERIC(18,6) NOT NULL DEFAULT 0,      -- 加工単価
    unit_cost           NUMERIC(18,6) NOT NULL DEFAULT 0,        -- 単位原価（材料費＋加工費）
    amount              NUMERIC(18,2) NOT NULL DEFAULT 0,        -- 金額（receipt_qty × unit_cost）
    quality_status      SMALLINT      NOT NULL DEFAULT 10,       -- 10:待検 20:合格 30:特采 40:不合格
    CONSTRAINT pk_prd_outsourcing_receipt_line PRIMARY KEY (id),
    CONSTRAINT fk_prd_outsourcing_receipt_line_rcpt FOREIGN KEY (receipt_id) REFERENCES prd_outsourcing_receipt (id) ON DELETE RESTRICT,
    CONSTRAINT fk_prd_outsourcing_receipt_line_material FOREIGN KEY (material_id) REFERENCES mdm_material (id),
    CONSTRAINT ck_prd_outsourcing_receipt_line_qty CHECK (receipt_qty > 0),
    CONSTRAINT ck_prd_outsourcing_receipt_line_cost CHECK (unit_material_cost >= 0 AND processing_unit_price >= 0)
);
ALTER TABLE prd_outsourcing_receipt_line ENABLE ROW LEVEL SECURITY;
ALTER TABLE prd_outsourcing_receipt_line FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON prd_outsourcing_receipt_line
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_prd_outsourcing_receipt_line_rcpt_line ON prd_outsourcing_receipt_line (company_id, receipt_id, line_no);
CREATE INDEX idx_prd_outsourcing_receipt_line_material ON prd_outsourcing_receipt_line (company_id, material_id, batch_no);
COMMENT ON COLUMN prd_outsourcing_receipt_line.id IS '雪花 ID（主键）';
COMMENT ON COLUMN prd_outsourcing_receipt_line.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN prd_outsourcing_receipt_line.company_id IS '公司 ID（无默认值）';
COMMENT ON COLUMN prd_outsourcing_receipt_line.created_at IS '创建时间';
COMMENT ON COLUMN prd_outsourcing_receipt_line.created_by IS '创建人';
COMMENT ON COLUMN prd_outsourcing_receipt_line.updated_at IS '更新时间';
COMMENT ON COLUMN prd_outsourcing_receipt_line.updated_by IS '更新人';
COMMENT ON COLUMN prd_outsourcing_receipt_line.version IS '乐观锁版本';
COMMENT ON COLUMN prd_outsourcing_receipt_line.remark IS '备注';
COMMENT ON COLUMN prd_outsourcing_receipt_line.ext_data IS '扩展字段';
COMMENT ON COLUMN prd_outsourcing_receipt_line.receipt_id IS '收货单 ID → prd_outsourcing_receipt.id';
COMMENT ON COLUMN prd_outsourcing_receipt_line.line_no IS '行番号';
COMMENT ON COLUMN prd_outsourcing_receipt_line.outsourcing_order_line_id IS '委外订单明细 ID → prd_outsourcing_order_line.id';
COMMENT ON COLUMN prd_outsourcing_receipt_line.material_id IS '受入品目 ID → mdm_material.id';
COMMENT ON COLUMN prd_outsourcing_receipt_line.material_code IS '品目编码（スナップショット）';
COMMENT ON COLUMN prd_outsourcing_receipt_line.material_name IS '品目名称（スナップショット）';
COMMENT ON COLUMN prd_outsourcing_receipt_line.uom_code IS '单位';
COMMENT ON COLUMN prd_outsourcing_receipt_line.receipt_qty IS '受入数量';
COMMENT ON COLUMN prd_outsourcing_receipt_line.defect_qty IS '不合格数量（返品/再加工）';
COMMENT ON COLUMN prd_outsourcing_receipt_line.batch_no IS '批次号';
COMMENT ON COLUMN prd_outsourcing_receipt_line.warehouse_id IS '倉庫 ID';
COMMENT ON COLUMN prd_outsourcing_receipt_line.location_id IS '庫位 ID';
COMMENT ON COLUMN prd_outsourcing_receipt_line.unit_material_cost IS '単位材料費（発料原価ベース）';
COMMENT ON COLUMN prd_outsourcing_receipt_line.processing_unit_price IS '加工単価';
COMMENT ON COLUMN prd_outsourcing_receipt_line.unit_cost IS '単位原価（材料費＋加工費）';
COMMENT ON COLUMN prd_outsourcing_receipt_line.amount IS '金額（receipt_qty × unit_cost）';
COMMENT ON COLUMN prd_outsourcing_receipt_line.quality_status IS '10:待検 20:合格 30:特采 40:不合格';

-- prd_outsourcing_settlement
CREATE TABLE prd_outsourcing_settlement (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    remark              VARCHAR(500),
    ext_data            JSONB,
    settlement_no       VARCHAR(32)   NOT NULL,                  -- 结算单号 OSS{YYMMDD}{4桁}
    supplier_id         BIGINT        NOT NULL,                  -- 仕入先 ID → mdm_supplier.id
    supplier_code       VARCHAR(32)   NOT NULL,                  -- 仕入先编码（スナップショット）
    supplier_name       VARCHAR(200)  NOT NULL,                  -- 仕入先名称（スナップショット）
    factory_id          BIGINT        NOT NULL,                  -- 工厂 ID
    period_code         VARCHAR(7)    NOT NULL,                  -- 结算期间 YYYY-MM
    settlement_type     SMALLINT      NOT NULL DEFAULT 10,       -- 10:月度一括 20:受入単位 30:単発
    settlement_date     DATE          NOT NULL,                  -- 结算日
    total_qty           NUMERIC(18,4) NOT NULL DEFAULT 0,        -- 合計受入数量
    total_processing_amount NUMERIC(18,2) NOT NULL DEFAULT 0,    -- 加工費合計（税抜）
    deduction_amount    NUMERIC(18,2) NOT NULL DEFAULT 0,        -- 扣款合計（品質・遅延）
    net_amount          NUMERIC(18,2) NOT NULL DEFAULT 0,        -- 正味加工費（税抜）
    tax_rate            NUMERIC(7,4)  NOT NULL DEFAULT 13,       -- 税率（%）
    tax_amount          NUMERIC(18,2) NOT NULL DEFAULT 0,        -- 税額
    total_amount        NUMERIC(18,2) NOT NULL DEFAULT 0,        -- 税込合計
    settlement_status   SMALLINT      NOT NULL DEFAULT 10,       -- 10:草稿 20:確認待ち 25:承認済 40:完了 90:取消
    ap_bill_id          BIGINT,                                  -- FIN 应付单 ID → fin_ap_bill.id
    ap_bill_no          VARCHAR(32),                             -- 应付单号（スナップショット）
    invoice_no          VARCHAR(64),                             -- 加工費発票番号
    invoice_date        DATE,                                    -- 発票日
    submitted_at        TIMESTAMPTZ,                             -- 提出日時
    approved_by         BIGINT,                                  -- 承認者
    approved_at         TIMESTAMPTZ,                             -- 承認日時
    cancel_reason       VARCHAR(500),                            -- 取消理由
    CONSTRAINT pk_prd_outsourcing_settlement PRIMARY KEY (id),
    CONSTRAINT fk_prd_outsourcing_settlement_supplier FOREIGN KEY (supplier_id) REFERENCES mdm_supplier (id),
    CONSTRAINT ck_prd_outsourcing_settlement_status CHECK (settlement_status IN (10,20,25,40,90)),
    CONSTRAINT ck_prd_outsourcing_settlement_amt CHECK (total_processing_amount >= 0 AND net_amount >= 0 AND deduction_amount >= 0)
);
ALTER TABLE prd_outsourcing_settlement ENABLE ROW LEVEL SECURITY;
ALTER TABLE prd_outsourcing_settlement FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON prd_outsourcing_settlement
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_prd_outsourcing_settlement_no ON prd_outsourcing_settlement (tenant_id, company_id, settlement_no);
CREATE INDEX idx_prd_outsourcing_settlement_supplier ON prd_outsourcing_settlement (company_id, supplier_id, period_code, settlement_status);
COMMENT ON COLUMN prd_outsourcing_settlement.id IS '雪花 ID（主键）';
COMMENT ON COLUMN prd_outsourcing_settlement.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN prd_outsourcing_settlement.company_id IS '公司 ID（无默认值）';
COMMENT ON COLUMN prd_outsourcing_settlement.created_at IS '创建时间';
COMMENT ON COLUMN prd_outsourcing_settlement.created_by IS '创建人';
COMMENT ON COLUMN prd_outsourcing_settlement.updated_at IS '更新时间';
COMMENT ON COLUMN prd_outsourcing_settlement.updated_by IS '更新人';
COMMENT ON COLUMN prd_outsourcing_settlement.version IS '乐观锁版本';
COMMENT ON COLUMN prd_outsourcing_settlement.remark IS '备注';
COMMENT ON COLUMN prd_outsourcing_settlement.ext_data IS '扩展字段';
COMMENT ON COLUMN prd_outsourcing_settlement.settlement_no IS '结算单号 OSS{YYMMDD}{4桁}';
COMMENT ON COLUMN prd_outsourcing_settlement.supplier_id IS '仕入先 ID → mdm_supplier.id';
COMMENT ON COLUMN prd_outsourcing_settlement.supplier_code IS '仕入先编码（スナップショット）';
COMMENT ON COLUMN prd_outsourcing_settlement.supplier_name IS '仕入先名称（スナップショット）';
COMMENT ON COLUMN prd_outsourcing_settlement.factory_id IS '工厂 ID';
COMMENT ON COLUMN prd_outsourcing_settlement.period_code IS '结算期间 YYYY-MM';
COMMENT ON COLUMN prd_outsourcing_settlement.settlement_type IS '10:月度一括 20:受入単位 30:単発';
COMMENT ON COLUMN prd_outsourcing_settlement.settlement_date IS '结算日';
COMMENT ON COLUMN prd_outsourcing_settlement.total_qty IS '合計受入数量';
COMMENT ON COLUMN prd_outsourcing_settlement.total_processing_amount IS '加工費合計（税抜）';
COMMENT ON COLUMN prd_outsourcing_settlement.deduction_amount IS '扣款合計（品質・遅延）';
COMMENT ON COLUMN prd_outsourcing_settlement.net_amount IS '正味加工費（税抜）';
COMMENT ON COLUMN prd_outsourcing_settlement.tax_rate IS '税率（%）';
COMMENT ON COLUMN prd_outsourcing_settlement.tax_amount IS '税額';
COMMENT ON COLUMN prd_outsourcing_settlement.total_amount IS '税込合計';
COMMENT ON COLUMN prd_outsourcing_settlement.settlement_status IS '10:草稿 20:確認待ち 25:承認済 40:完了 90:取消';
COMMENT ON COLUMN prd_outsourcing_settlement.ap_bill_id IS 'FIN 应付单 ID → fin_ap_bill.id';
COMMENT ON COLUMN prd_outsourcing_settlement.ap_bill_no IS '应付单号（スナップショット）';
COMMENT ON COLUMN prd_outsourcing_settlement.invoice_no IS '加工費発票番号';
COMMENT ON COLUMN prd_outsourcing_settlement.invoice_date IS '発票日';
COMMENT ON COLUMN prd_outsourcing_settlement.submitted_at IS '提出日時';
COMMENT ON COLUMN prd_outsourcing_settlement.approved_by IS '承認者';
COMMENT ON COLUMN prd_outsourcing_settlement.approved_at IS '承認日時';
COMMENT ON COLUMN prd_outsourcing_settlement.cancel_reason IS '取消理由';

-- prd_outsourcing_settlement_line
CREATE TABLE prd_outsourcing_settlement_line (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    remark              VARCHAR(500),
    ext_data            JSONB,
    settlement_id       BIGINT        NOT NULL,                  -- 结算单 ID → prd_outsourcing_settlement.id
    line_no             INT           NOT NULL,                  -- 行番号
    outsourcing_receipt_id BIGINT,                               -- 委外收货单 ID → prd_outsourcing_receipt.id
    outsourcing_receipt_no VARCHAR(32),                          -- 收货单号（スナップショット）
    outsourcing_order_id BIGINT,                                 -- 委外订单 ID
    outsourcing_no      VARCHAR(32),                             -- 委外订单号（スナップショット）
    material_id         BIGINT        NOT NULL,                  -- 品目 ID
    material_code       VARCHAR(64)   NOT NULL,                  -- 品目编码（スナップショット）
    material_name       VARCHAR(200)  NOT NULL,                  -- 品目名称（スナップショット）
    receipt_qty         NUMERIC(18,4) NOT NULL,                  -- 结算対象受入数量
    processing_unit_price NUMERIC(18,6) NOT NULL DEFAULT 0,      -- 加工単価
    processing_amount   NUMERIC(18,2) NOT NULL DEFAULT 0,        -- 加工費（税抜）
    deduction_amount    NUMERIC(18,2) NOT NULL DEFAULT 0,        -- 扣款額
    deduction_reason    VARCHAR(500),                            -- 扣款理由（不良/遅延/返品）
    net_amount          NUMERIC(18,2) NOT NULL DEFAULT 0,        -- 正味金額（税抜）
    CONSTRAINT pk_prd_outsourcing_settlement_line PRIMARY KEY (id),
    CONSTRAINT fk_prd_outsourcing_settlement_line_settle FOREIGN KEY (settlement_id) REFERENCES prd_outsourcing_settlement (id) ON DELETE RESTRICT,
    CONSTRAINT fk_prd_outsourcing_settlement_line_material FOREIGN KEY (material_id) REFERENCES mdm_material (id),
    CONSTRAINT ck_prd_outsourcing_settlement_line_qty CHECK (receipt_qty > 0),
    CONSTRAINT ck_prd_outsourcing_settlement_line_amt CHECK (processing_amount >= 0 AND deduction_amount >= 0 AND net_amount >= 0)
);
ALTER TABLE prd_outsourcing_settlement_line ENABLE ROW LEVEL SECURITY;
ALTER TABLE prd_outsourcing_settlement_line FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON prd_outsourcing_settlement_line
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_prd_outsourcing_settlement_line_settle_line ON prd_outsourcing_settlement_line (tenant_id, company_id, settlement_id, line_no);
CREATE INDEX idx_prd_outsourcing_settlement_line_rcpt ON prd_outsourcing_settlement_line (company_id, outsourcing_receipt_id);
COMMENT ON COLUMN prd_outsourcing_settlement_line.id IS '雪花 ID（主键）';
COMMENT ON COLUMN prd_outsourcing_settlement_line.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN prd_outsourcing_settlement_line.company_id IS '公司 ID（无默认值）';
COMMENT ON COLUMN prd_outsourcing_settlement_line.created_at IS '创建时间';
COMMENT ON COLUMN prd_outsourcing_settlement_line.created_by IS '创建人';
COMMENT ON COLUMN prd_outsourcing_settlement_line.updated_at IS '更新时间';
COMMENT ON COLUMN prd_outsourcing_settlement_line.updated_by IS '更新人';
COMMENT ON COLUMN prd_outsourcing_settlement_line.version IS '乐观锁版本';
COMMENT ON COLUMN prd_outsourcing_settlement_line.remark IS '备注';
COMMENT ON COLUMN prd_outsourcing_settlement_line.ext_data IS '扩展字段';
COMMENT ON COLUMN prd_outsourcing_settlement_line.settlement_id IS '结算单 ID → prd_outsourcing_settlement.id';
COMMENT ON COLUMN prd_outsourcing_settlement_line.line_no IS '行番号';
COMMENT ON COLUMN prd_outsourcing_settlement_line.outsourcing_receipt_id IS '委外收货单 ID → prd_outsourcing_receipt.id';
COMMENT ON COLUMN prd_outsourcing_settlement_line.outsourcing_receipt_no IS '收货单号（スナップショット）';
COMMENT ON COLUMN prd_outsourcing_settlement_line.outsourcing_order_id IS '委外订单 ID';
COMMENT ON COLUMN prd_outsourcing_settlement_line.outsourcing_no IS '委外订单号（スナップショット）';
COMMENT ON COLUMN prd_outsourcing_settlement_line.material_id IS '品目 ID';
COMMENT ON COLUMN prd_outsourcing_settlement_line.material_code IS '品目编码（スナップショット）';
COMMENT ON COLUMN prd_outsourcing_settlement_line.material_name IS '品目名称（スナップショット）';
COMMENT ON COLUMN prd_outsourcing_settlement_line.receipt_qty IS '结算対象受入数量';
COMMENT ON COLUMN prd_outsourcing_settlement_line.processing_unit_price IS '加工単価';
COMMENT ON COLUMN prd_outsourcing_settlement_line.processing_amount IS '加工費（税抜）';
COMMENT ON COLUMN prd_outsourcing_settlement_line.deduction_amount IS '扣款額';
COMMENT ON COLUMN prd_outsourcing_settlement_line.deduction_reason IS '扣款理由（不良/遅延/返品）';
COMMENT ON COLUMN prd_outsourcing_settlement_line.net_amount IS '正味金額（税抜）';

-- prd_inspection_standard
CREATE TABLE prd_inspection_standard (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    deleted             BOOLEAN       NOT NULL DEFAULT FALSE,
    remark              VARCHAR(500),
    ext_data            JSONB,
    standard_no         VARCHAR(40)   NOT NULL,                  -- 检验标准编号 QS{種別2桁}{4桁}
    standard_name       VARCHAR(200)  NOT NULL,                  -- 标准名称（例：来料检验标准-硅钢片）
    inspection_type     SMALLINT      NOT NULL,                  -- 10:IQC 20:IPQC 30:FQC 40:OQC
    material_id         BIGINT,                                  -- 适用品目 ID → mdm_material.id（NULL=品目共通）
    material_code       VARCHAR(64),                             -- 品目编码（スナップショット、NULL 可）
    material_name       VARCHAR(200),                            -- 品目名称（NULL 可）
    operation_seq       INT,                                     -- 适用工序 SEQ（IPQC 用、NULL=工程共通）
    customer_id         BIGINT,                                  -- 适用顾客 ID → mdm_customer.id（NULL=一般）
    customer_name       VARCHAR(200),                            -- 顾客名称（スナップショット）
    version_no          SMALLINT      NOT NULL DEFAULT 1,        -- 版本号
    standard_status     SMALLINT      NOT NULL DEFAULT 10,       -- 10:草稿 25:承認済 30:有効 90:廃止
    valid_from          DATE          NOT NULL,                  -- 生效开始日
    valid_to            DATE,                                    -- 生效終了日
    sampling_type       SMALLINT      NOT NULL DEFAULT 20,       -- 10:全数検査 20:抽样検査 30:免检
    sampling_plan_code  VARCHAR(32),                             -- 抽样方案代码（GB/T 2828.1-2012 の検査水準/方案番号）
    inspection_level    VARCHAR(16)   NOT NULL DEFAULT 'II',     -- 一般检验水平（GB/T 2828.1 一般検査水準 II）
    aql_value           NUMERIC(7,4)  NOT NULL DEFAULT 2.5,      -- 接收质量限 AQL（%）
    sample_size         INT,                                     -- 样本数（sampling_plan_code 未使用時の固定値）
    judge_rule          SMALLINT      NOT NULL DEFAULT 10,       -- 10:全項目合格 20:关键项全合格+一般项 Ac/Re 22:关键项全合格
    standard_basis      VARCHAR(500),                            -- 判定依据（GB/T 1032-2023 等の標準・社内規格）
    approved_by         BIGINT,                                  -- 承認者 → sys_user.id
    approved_at         TIMESTAMPTZ,                             -- 承認日時
    CONSTRAINT pk_prd_inspection_standard PRIMARY KEY (id),
    CONSTRAINT ck_prd_inspection_standard_type CHECK (inspection_type IN (10,20,30,40)),
    CONSTRAINT ck_prd_inspection_standard_status CHECK (standard_status IN (10,25,30,90)),
    CONSTRAINT ck_prd_inspection_standard_sampling CHECK (sampling_type IN (10,20,30)),
    CONSTRAINT ck_prd_inspection_standard_valid CHECK (valid_to IS NULL OR valid_to >= valid_from)
);
ALTER TABLE prd_inspection_standard ENABLE ROW LEVEL SECURITY;
ALTER TABLE prd_inspection_standard FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON prd_inspection_standard
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_prd_inspection_standard_no ON prd_inspection_standard (tenant_id, company_id, standard_no) WHERE deleted = FALSE;
CREATE INDEX idx_prd_inspection_standard_apply ON prd_inspection_standard (company_id, inspection_type, material_id, operation_seq, customer_id, standard_status);
CREATE INDEX idx_prd_inspection_standard_valid ON prd_inspection_standard (company_id, inspection_type, valid_from, valid_to);
COMMENT ON COLUMN prd_inspection_standard.id IS '雪花 ID（主键）';
COMMENT ON COLUMN prd_inspection_standard.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN prd_inspection_standard.company_id IS '公司 ID（无默认值）';
COMMENT ON COLUMN prd_inspection_standard.created_at IS '创建时间';
COMMENT ON COLUMN prd_inspection_standard.created_by IS '创建人';
COMMENT ON COLUMN prd_inspection_standard.updated_at IS '更新时间';
COMMENT ON COLUMN prd_inspection_standard.updated_by IS '更新人';
COMMENT ON COLUMN prd_inspection_standard.version IS '乐观锁版本';
COMMENT ON COLUMN prd_inspection_standard.deleted IS '逻辑删除';
COMMENT ON COLUMN prd_inspection_standard.remark IS '备注';
COMMENT ON COLUMN prd_inspection_standard.ext_data IS '扩展字段';
COMMENT ON COLUMN prd_inspection_standard.standard_no IS '检验标准编号 QS{種別2桁}{4桁}';
COMMENT ON COLUMN prd_inspection_standard.standard_name IS '标准名称（例：来料检验标准-硅钢片）';
COMMENT ON COLUMN prd_inspection_standard.inspection_type IS '10:IQC 20:IPQC 30:FQC 40:OQC';
COMMENT ON COLUMN prd_inspection_standard.material_id IS '适用品目 ID → mdm_material.id（NULL=品目共通）';
COMMENT ON COLUMN prd_inspection_standard.material_code IS '品目编码（スナップショット、NULL 可）';
COMMENT ON COLUMN prd_inspection_standard.material_name IS '品目名称（NULL 可）';
COMMENT ON COLUMN prd_inspection_standard.operation_seq IS '适用工序 SEQ（IPQC 用、NULL=工程共通）';
COMMENT ON COLUMN prd_inspection_standard.customer_id IS '适用顾客 ID → mdm_customer.id（NULL=一般）';
COMMENT ON COLUMN prd_inspection_standard.customer_name IS '顾客名称（スナップショット）';
COMMENT ON COLUMN prd_inspection_standard.version_no IS '版本号';
COMMENT ON COLUMN prd_inspection_standard.standard_status IS '10:草稿 25:承認済 30:有効 90:廃止';
COMMENT ON COLUMN prd_inspection_standard.valid_from IS '生效开始日';
COMMENT ON COLUMN prd_inspection_standard.valid_to IS '生效終了日';
COMMENT ON COLUMN prd_inspection_standard.sampling_type IS '10:全数検査 20:抽样検査 30:免检';
COMMENT ON COLUMN prd_inspection_standard.sampling_plan_code IS '抽样方案代码（GB/T 2828.1-2012 の検査水準/方案番号）';
COMMENT ON COLUMN prd_inspection_standard.inspection_level IS '一般检验水平（GB/T 2828.1 一般検査水準 II）';
COMMENT ON COLUMN prd_inspection_standard.aql_value IS '接收质量限 AQL（%）';
COMMENT ON COLUMN prd_inspection_standard.sample_size IS '样本数（sampling_plan_code 未使用時の固定値）';
COMMENT ON COLUMN prd_inspection_standard.judge_rule IS '10:全項目合格 20:关键项全合格+一般项 Ac/Re 22:关键项全合格';
COMMENT ON COLUMN prd_inspection_standard.standard_basis IS '判定依据（GB/T 1032-2023 等の標準・社内規格）';
COMMENT ON COLUMN prd_inspection_standard.approved_by IS '承認者 → sys_user.id';
COMMENT ON COLUMN prd_inspection_standard.approved_at IS '承認日時';

-- prd_inspection_standard_item
CREATE TABLE prd_inspection_standard_item (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    deleted             BOOLEAN       NOT NULL DEFAULT FALSE,
    remark              VARCHAR(500),
    ext_data            JSONB,
    standard_id         BIGINT        NOT NULL,                  -- 检验标准 ID → prd_inspection_standard.id
    item_seq            INT           NOT NULL,                  -- 项目序号（10 刻み）
    inspection_item_code VARCHAR(32)  NOT NULL,                  -- 检验项目代码（IR/RS/HV/NO/OC 等の社内コード）
    inspection_item_name VARCHAR(200) NOT NULL,                  -- 检验项目名称（绝缘电阻/耐电压/空载电流 等）
    item_type           SMALLINT      NOT NULL DEFAULT 10,       -- 10:计量 20:计数 30:外观 40:性能 50:材料 60:标识
    inspection_method   VARCHAR(200)  NOT NULL,                  -- 检验方法（測定器・目視・試験台）
    specification       VARCHAR(200),                            -- 规格值（表示用、例：≥100 MΩ）
    lower_limit         NUMERIC(18,6),                           -- 下限值
    upper_limit         NUMERIC(18,6),                           -- 上限值
    target_value        NUMERIC(18,6),                           -- 目标值/中心值
    unit_code           VARCHAR(16),                             -- 单位（MΩ/V/A/mm/—）
    is_critical         BOOLEAN       NOT NULL DEFAULT FALSE,    -- 关键项（不合格即拒收）
    sample_size         INT,                                     -- 项目別样本数（NULL=标准ヘッダに従う）
    judge_rule          SMALLINT      NOT NULL DEFAULT 10,       -- 10:上下限内 20:下限以上 30:上限以下 40:合否 50:記録のみ
    instrument_code     VARCHAR(32),                             -- 使用計測器/設備コード → prd_equipment.equipment_code
    inspection_basis    VARCHAR(200),                            -- 试验方法依据（標準番号）
    CONSTRAINT pk_prd_inspection_standard_item PRIMARY KEY (id),
    CONSTRAINT fk_prd_inspection_standard_item_std FOREIGN KEY (standard_id) REFERENCES prd_inspection_standard (id) ON DELETE RESTRICT,
    CONSTRAINT ck_prd_inspection_standard_item_type CHECK (item_type IN (10,20,30,40,50,60)),
    CONSTRAINT ck_prd_inspection_standard_item_limit CHECK (upper_limit IS NULL OR lower_limit IS NULL OR upper_limit >= lower_limit)
);
ALTER TABLE prd_inspection_standard_item ENABLE ROW LEVEL SECURITY;
ALTER TABLE prd_inspection_standard_item FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON prd_inspection_standard_item
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_prd_inspection_standard_item_std_seq ON prd_inspection_standard_item (tenant_id, company_id, standard_id, item_seq);
CREATE INDEX idx_prd_inspection_standard_item_code ON prd_inspection_standard_item (company_id, inspection_item_code);
COMMENT ON COLUMN prd_inspection_standard_item.id IS '雪花 ID（主键）';
COMMENT ON COLUMN prd_inspection_standard_item.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN prd_inspection_standard_item.company_id IS '公司 ID（无默认值）';
COMMENT ON COLUMN prd_inspection_standard_item.created_at IS '创建时间';
COMMENT ON COLUMN prd_inspection_standard_item.created_by IS '创建人';
COMMENT ON COLUMN prd_inspection_standard_item.updated_at IS '更新时间';
COMMENT ON COLUMN prd_inspection_standard_item.updated_by IS '更新人';
COMMENT ON COLUMN prd_inspection_standard_item.version IS '乐观锁版本';
COMMENT ON COLUMN prd_inspection_standard_item.deleted IS '逻辑删除';
COMMENT ON COLUMN prd_inspection_standard_item.remark IS '备注';
COMMENT ON COLUMN prd_inspection_standard_item.ext_data IS '扩展字段';
COMMENT ON COLUMN prd_inspection_standard_item.standard_id IS '检验标准 ID → prd_inspection_standard.id';
COMMENT ON COLUMN prd_inspection_standard_item.item_seq IS '项目序号（10 刻み）';
COMMENT ON COLUMN prd_inspection_standard_item.inspection_item_code IS '检验项目代码（IR/RS/HV/NO/OC 等の社内コード）';
COMMENT ON COLUMN prd_inspection_standard_item.inspection_item_name IS '检验项目名称（绝缘电阻/耐电压/空载电流 等）';
COMMENT ON COLUMN prd_inspection_standard_item.item_type IS '10:计量 20:计数 30:外观 40:性能 50:材料 60:标识';
COMMENT ON COLUMN prd_inspection_standard_item.inspection_method IS '检验方法（測定器・目視・試験台）';
COMMENT ON COLUMN prd_inspection_standard_item.specification IS '规格值（表示用、例：≥100 MΩ）';
COMMENT ON COLUMN prd_inspection_standard_item.lower_limit IS '下限值';
COMMENT ON COLUMN prd_inspection_standard_item.upper_limit IS '上限值';
COMMENT ON COLUMN prd_inspection_standard_item.target_value IS '目标值/中心值';
COMMENT ON COLUMN prd_inspection_standard_item.unit_code IS '单位（MΩ/V/A/mm/—）';
COMMENT ON COLUMN prd_inspection_standard_item.is_critical IS '关键项（不合格即拒收）';
COMMENT ON COLUMN prd_inspection_standard_item.sample_size IS '项目別样本数（NULL=标准ヘッダに従う）';
COMMENT ON COLUMN prd_inspection_standard_item.judge_rule IS '10:上下限内 20:下限以上 30:上限以下 40:合否 50:記録のみ';
COMMENT ON COLUMN prd_inspection_standard_item.instrument_code IS '使用計測器/設備コード → prd_equipment.equipment_code';
COMMENT ON COLUMN prd_inspection_standard_item.inspection_basis IS '试验方法依据（標準番号）';

-- prd_inspection
CREATE TABLE prd_inspection (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    remark              VARCHAR(500),
    ext_data            JSONB,
    inspection_no       VARCHAR(32)   NOT NULL,                  -- 检验单号 IQC/PQC/FQC/OQC{YYMMDD}{4桁}
    inspection_type     SMALLINT      NOT NULL,                  -- 10:IQC 20:IPQC 30:FQC 40:OQC
    inspection_status   SMALLINT      NOT NULL DEFAULT 10,       -- 10:起票 20:検査中 30:判定確定 90:取消
    source_type         SMALLINT      NOT NULL,                  -- 10:采购收货 20:工单工序 30:工单完工 40:出荷指示 50:委外收货 60:手工
    source_id           BIGINT,                                  -- 来源 ID（receipt_id / work_order_operation_id 等）
    source_no           VARCHAR(64),                             -- 来源单号（スナップショット）
    material_id         BIGINT        NOT NULL,                  -- 検査対象品目 ID → mdm_material.id
    material_code       VARCHAR(64)   NOT NULL,                  -- 品目编码（スナップショット）
    material_name       VARCHAR(200)  NOT NULL,                  -- 品目名称（スナップショット）
    material_spec       VARCHAR(200),                            -- 规格（スナップショット）
    uom_code            VARCHAR(16)   NOT NULL,                  -- 单位
    lot_no              VARCHAR(64),                             -- 批次/ロット番号
    work_order_id       BIGINT,                                  -- 工单 ID → prd_work_order.id（IPQC/FQC）
    work_order_operation_id BIGINT,                              -- 工单工序 ID → prd_work_order_operation.id（IPQC）
    purchase_receipt_id BIGINT,                                  -- 采购收货单 ID → pur_receipt.id（IQC）
    outsourcing_receipt_id BIGINT,                               -- 委外收货单 ID → prd_outsourcing_receipt.id
    supplier_id         BIGINT,                                  -- 仕入先 ID → mdm_supplier.id（IQC/委外）
    customer_id         BIGINT,                                  -- 顧客 ID → mdm_customer.id（OQC/顾客指定標準）
    standard_id         BIGINT,                                  -- 適用检验标准 ID → prd_inspection_standard.id
    inspection_qty      NUMERIC(18,4) NOT NULL DEFAULT 0,        -- 検査対象数量（ロット数量）
    sample_qty          NUMERIC(18,4) NOT NULL DEFAULT 0,        -- 抜取数量（全数時は inspection_qty と同値）
    defect_qty          NUMERIC(18,4) NOT NULL DEFAULT 0,        -- 不良数量
    critical_defect_qty NUMERIC(18,4) NOT NULL DEFAULT 0,        -- 关键项不良数量
    result              SMALLINT      NOT NULL DEFAULT 10,       -- resultCode: 10:未検査 20:合格 30:特採 40:不合格 50:廃棄（09 E15 と一致）
    inspector_id        BIGINT,                                  -- 検査員 → sys_user.id
    inspected_at        TIMESTAMPTZ,                             -- 検査実施日時
    judged_by           BIGINT,                                  -- 判定者 → sys_user.id
    judged_at           TIMESTAMPTZ,                             -- 判定日時（E15 発行）
    ncr_id              BIGINT,                                  -- NCR ID → prd_ncr.id（不合格時）
    factory_id          BIGINT        NOT NULL,                  -- 工厂 ID
    e15_published_at    TIMESTAMPTZ,                             -- E15 発行日時（再送制御用）
    cancel_reason       VARCHAR(500),                            -- 取消理由
    CONSTRAINT pk_prd_inspection PRIMARY KEY (id),
    CONSTRAINT fk_prd_inspection_material FOREIGN KEY (material_id) REFERENCES mdm_material (id),
    CONSTRAINT fk_prd_inspection_standard FOREIGN KEY (standard_id) REFERENCES prd_inspection_standard (id),
    CONSTRAINT fk_prd_inspection_wo FOREIGN KEY (work_order_id) REFERENCES prd_work_order (id),
    CONSTRAINT ck_prd_inspection_type CHECK (inspection_type IN (10,20,30,40)),
    CONSTRAINT ck_prd_inspection_status CHECK (inspection_status IN (10,20,30,90)),
    CONSTRAINT ck_prd_inspection_result CHECK (result IN (0,10,20,30,40,50)),
    CONSTRAINT ck_prd_inspection_qty CHECK (inspection_qty >= 0 AND sample_qty >= 0 AND defect_qty >= 0)
);
ALTER TABLE prd_inspection ENABLE ROW LEVEL SECURITY;
ALTER TABLE prd_inspection FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON prd_inspection
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_prd_inspection_no ON prd_inspection (tenant_id, company_id, inspection_no);
CREATE INDEX idx_prd_inspection_source ON prd_inspection (company_id, source_type, source_id);
CREATE INDEX idx_prd_inspection_status ON prd_inspection (company_id, inspection_type, inspection_status, judged_at);
CREATE INDEX idx_prd_inspection_wo ON prd_inspection (company_id, work_order_id) WHERE work_order_id IS NOT NULL;
CREATE INDEX idx_prd_inspection_lot ON prd_inspection (company_id, material_id, lot_no);
COMMENT ON COLUMN prd_inspection.id IS '雪花 ID（主键）';
COMMENT ON COLUMN prd_inspection.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN prd_inspection.company_id IS '公司 ID（无默认值）';
COMMENT ON COLUMN prd_inspection.created_at IS '创建时间';
COMMENT ON COLUMN prd_inspection.created_by IS '创建人';
COMMENT ON COLUMN prd_inspection.updated_at IS '更新时间';
COMMENT ON COLUMN prd_inspection.updated_by IS '更新人';
COMMENT ON COLUMN prd_inspection.version IS '乐观锁版本';
COMMENT ON COLUMN prd_inspection.remark IS '备注';
COMMENT ON COLUMN prd_inspection.ext_data IS '扩展字段';
COMMENT ON COLUMN prd_inspection.inspection_no IS '检验单号 IQC/PQC/FQC/OQC{YYMMDD}{4桁}';
COMMENT ON COLUMN prd_inspection.inspection_type IS '10:IQC 20:IPQC 30:FQC 40:OQC';
COMMENT ON COLUMN prd_inspection.inspection_status IS '10:起票 20:検査中 30:判定確定 90:取消';
COMMENT ON COLUMN prd_inspection.source_type IS '10:采购收货 20:工单工序 30:工单完工 40:出荷指示 50:委外收货 60:手工';
COMMENT ON COLUMN prd_inspection.source_id IS '来源 ID（receipt_id / work_order_operation_id 等）';
COMMENT ON COLUMN prd_inspection.source_no IS '来源单号（スナップショット）';
COMMENT ON COLUMN prd_inspection.material_id IS '検査対象品目 ID → mdm_material.id';
COMMENT ON COLUMN prd_inspection.material_code IS '品目编码（スナップショット）';
COMMENT ON COLUMN prd_inspection.material_name IS '品目名称（スナップショット）';
COMMENT ON COLUMN prd_inspection.material_spec IS '规格（スナップショット）';
COMMENT ON COLUMN prd_inspection.uom_code IS '单位';
COMMENT ON COLUMN prd_inspection.lot_no IS '批次/ロット番号';
COMMENT ON COLUMN prd_inspection.work_order_id IS '工单 ID → prd_work_order.id（IPQC/FQC）';
COMMENT ON COLUMN prd_inspection.work_order_operation_id IS '工单工序 ID → prd_work_order_operation.id（IPQC）';
COMMENT ON COLUMN prd_inspection.purchase_receipt_id IS '采购收货单 ID → pur_receipt.id（IQC）';
COMMENT ON COLUMN prd_inspection.outsourcing_receipt_id IS '委外收货单 ID → prd_outsourcing_receipt.id';
COMMENT ON COLUMN prd_inspection.supplier_id IS '仕入先 ID → mdm_supplier.id（IQC/委外）';
COMMENT ON COLUMN prd_inspection.customer_id IS '顧客 ID → mdm_customer.id（OQC/顾客指定標準）';
COMMENT ON COLUMN prd_inspection.standard_id IS '適用检验标准 ID → prd_inspection_standard.id';
COMMENT ON COLUMN prd_inspection.inspection_qty IS '検査対象数量（ロット数量）';
COMMENT ON COLUMN prd_inspection.sample_qty IS '抜取数量（全数時は inspection_qty と同値）';
COMMENT ON COLUMN prd_inspection.defect_qty IS '不良数量';
COMMENT ON COLUMN prd_inspection.critical_defect_qty IS '关键项不良数量';
COMMENT ON COLUMN prd_inspection.result IS 'resultCode: 10:未検査 20:合格 30:特採 40:不合格 50:廃棄（09 E15 と一致）';
COMMENT ON COLUMN prd_inspection.inspector_id IS '検査員 → sys_user.id';
COMMENT ON COLUMN prd_inspection.inspected_at IS '検査実施日時';
COMMENT ON COLUMN prd_inspection.judged_by IS '判定者 → sys_user.id';
COMMENT ON COLUMN prd_inspection.judged_at IS '判定日時（E15 発行）';
COMMENT ON COLUMN prd_inspection.ncr_id IS 'NCR ID → prd_ncr.id（不合格時）';
COMMENT ON COLUMN prd_inspection.factory_id IS '工厂 ID';
COMMENT ON COLUMN prd_inspection.e15_published_at IS 'E15 発行日時（再送制御用）';
COMMENT ON COLUMN prd_inspection.cancel_reason IS '取消理由';

-- prd_inspection_line
CREATE TABLE prd_inspection_line (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    remark              VARCHAR(500),
    ext_data            JSONB,
    inspection_id       BIGINT        NOT NULL,                  -- 检验单 ID → prd_inspection.id
    item_seq            INT           NOT NULL,                  -- 项目序号（标准項目からスナップショット）
    inspection_item_code VARCHAR(32)  NOT NULL,                  -- 检验项目代码
    inspection_item_name VARCHAR(200) NOT NULL,                  -- 检验项目名称
    item_type           SMALLINT      NOT NULL DEFAULT 10,       -- 10:计量 20:计数 30:外观 40:性能 50:材料 60:标识
    inspection_method   VARCHAR(200),                            -- 检验方法（スナップショット）
    specification       VARCHAR(200),                            -- 规格值（スナップショット）
    lower_limit         NUMERIC(18,6),                           -- 下限（スナップショット）
    upper_limit         NUMERIC(18,6),                           -- 上限（スナップショット）
    measured_value      NUMERIC(18,6),                           -- 実測値
    measured_text       VARCHAR(500),                            -- 定性結果（良/不良、試験結果等）
    unit_code           VARCHAR(16),                             -- 单位
    sample_qty          NUMERIC(18,4) NOT NULL DEFAULT 0,        -- 項目別抜取数
    defect_qty          NUMERIC(18,4) NOT NULL DEFAULT 0,        -- 項目別不良数
    judge               SMALLINT      NOT NULL DEFAULT 0,        -- 0:未判定 10:合格 20:不合格
    is_critical         BOOLEAN       NOT NULL DEFAULT FALSE,    -- 关键项（スナップショット）
    instrument_code     VARCHAR(32),                             -- 使用計測器コード
    inspection_basis    VARCHAR(200),                            -- 试验方法依据（標準番号）
    inspected_by        BIGINT,                                  -- 検査員 → sys_user.id
    inspected_at        TIMESTAMPTZ,                             -- 検査日時
    CONSTRAINT pk_prd_inspection_line PRIMARY KEY (id),
    CONSTRAINT fk_prd_inspection_line_inspection FOREIGN KEY (inspection_id) REFERENCES prd_inspection (id) ON DELETE RESTRICT,
    CONSTRAINT ck_prd_inspection_line_judge CHECK (judge IN (0,10,20)),
    CONSTRAINT ck_prd_inspection_line_qty CHECK (sample_qty >= 0 AND defect_qty >= 0)
);
ALTER TABLE prd_inspection_line ENABLE ROW LEVEL SECURITY;
ALTER TABLE prd_inspection_line FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON prd_inspection_line
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_prd_inspection_line_inspection_seq ON prd_inspection_line (tenant_id, company_id, inspection_id, item_seq);
CREATE INDEX idx_prd_inspection_line_item ON prd_inspection_line (company_id, inspection_item_code, judge);
COMMENT ON COLUMN prd_inspection_line.id IS '雪花 ID（主键）';
COMMENT ON COLUMN prd_inspection_line.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN prd_inspection_line.company_id IS '公司 ID（无默认值）';
COMMENT ON COLUMN prd_inspection_line.created_at IS '创建时间';
COMMENT ON COLUMN prd_inspection_line.created_by IS '创建人';
COMMENT ON COLUMN prd_inspection_line.updated_at IS '更新时间';
COMMENT ON COLUMN prd_inspection_line.updated_by IS '更新人';
COMMENT ON COLUMN prd_inspection_line.version IS '乐观锁版本';
COMMENT ON COLUMN prd_inspection_line.remark IS '备注';
COMMENT ON COLUMN prd_inspection_line.ext_data IS '扩展字段';
COMMENT ON COLUMN prd_inspection_line.inspection_id IS '检验单 ID → prd_inspection.id';
COMMENT ON COLUMN prd_inspection_line.item_seq IS '项目序号（标准項目からスナップショット）';
COMMENT ON COLUMN prd_inspection_line.inspection_item_code IS '检验项目代码';
COMMENT ON COLUMN prd_inspection_line.inspection_item_name IS '检验项目名称';
COMMENT ON COLUMN prd_inspection_line.item_type IS '10:计量 20:计数 30:外观 40:性能 50:材料 60:标识';
COMMENT ON COLUMN prd_inspection_line.inspection_method IS '检验方法（スナップショット）';
COMMENT ON COLUMN prd_inspection_line.specification IS '规格值（スナップショット）';
COMMENT ON COLUMN prd_inspection_line.lower_limit IS '下限（スナップショット）';
COMMENT ON COLUMN prd_inspection_line.upper_limit IS '上限（スナップショット）';
COMMENT ON COLUMN prd_inspection_line.measured_value IS '実測値';
COMMENT ON COLUMN prd_inspection_line.measured_text IS '定性結果（良/不良、試験結果等）';
COMMENT ON COLUMN prd_inspection_line.unit_code IS '单位';
COMMENT ON COLUMN prd_inspection_line.sample_qty IS '項目別抜取数';
COMMENT ON COLUMN prd_inspection_line.defect_qty IS '項目別不良数';
COMMENT ON COLUMN prd_inspection_line.judge IS '0:未判定 10:合格 20:不合格';
COMMENT ON COLUMN prd_inspection_line.is_critical IS '关键项（スナップショット）';
COMMENT ON COLUMN prd_inspection_line.instrument_code IS '使用計測器コード';
COMMENT ON COLUMN prd_inspection_line.inspection_basis IS '试验方法依据（標準番号）';
COMMENT ON COLUMN prd_inspection_line.inspected_by IS '検査員 → sys_user.id';
COMMENT ON COLUMN prd_inspection_line.inspected_at IS '検査日時';

-- prd_ncr
CREATE TABLE prd_ncr (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    remark              VARCHAR(500),
    ext_data            JSONB,
    ncr_no              VARCHAR(32)   NOT NULL,                  -- NCR 编号 NCR{YYMMDD}{4桁}
    ncr_date            DATE          NOT NULL,                  -- 起票日
    source_type         SMALLINT      NOT NULL,                  -- 10:IQC 20:IPQC 30:FQC 40:OQC 50:客诉 60:委外受入
    source_id           BIGINT,                                  -- 来源 ID（检验单 ID 等）
    source_no           VARCHAR(64),                             -- 来源单号
    inspection_id       BIGINT,                                  -- 检验单 ID → prd_inspection.id
    work_order_id       BIGINT,                                  -- 工单 ID → prd_work_order.id
    work_order_operation_id BIGINT,                              -- 工单工序 ID
    operation_seq       INT,                                     -- 発生工序 SEQ
    material_id         BIGINT        NOT NULL,                  -- 対象品目 ID → mdm_material.id
    material_code       VARCHAR(64)   NOT NULL,                  -- 品目编码（スナップショット）
    material_name       VARCHAR(200)  NOT NULL,                  -- 品目名称（スナップショット）
    material_spec       VARCHAR(200),                            -- 规格（スナップショット）
    uom_code            VARCHAR(16)   NOT NULL,                  -- 单位
    lot_no              VARCHAR(64),                             -- 批次号
    supplier_id         BIGINT,                                  -- 仕入先 ID（IQC/委外）
    customer_id         BIGINT,                                  -- 顧客 ID（客诉/OQC）
    defect_code_id      BIGINT        NOT NULL,                  -- 主缺陷代码 ID → prd_defect_code.id
    defect_qty          NUMERIC(18,4) NOT NULL,                  -- 不合格数量
    defect_desc         VARCHAR(1000),                           -- 不良内容（現象・測定値）
    disposition_type    SMALLINT      NOT NULL,                  -- 10:返工 20:特采 30:报废 40:返品 50:分选 60:让步接收
    disposition_qty     NUMERIC(18,4) NOT NULL,                  -- 処置対象数量
    responsibility_type SMALLINT,                                -- 10:供方 20:自工序 30:前工序 40:设计 50:设备 60:材料
    cause_type          SMALLINT,                                -- 10:人 20:机 30:料 40:法 50:环 60:测
    root_cause          TEXT,                                    -- 根本原因
    corrective_action   TEXT,                                    -- 纠正措施
    preventive_action   TEXT,                                    -- 预防措施
    ncr_status          SMALLINT      NOT NULL DEFAULT 10,       -- 10:起票 20:承認待ち 25:承認済 30:処置中 40:完了 90:取消 95:却下
    approved_by         BIGINT,                                  -- 承認者 → sys_user.id
    approved_at         TIMESTAMPTZ,                             -- 承認日時
    closed_by           BIGINT,                                  -- 完了者
    closed_at           TIMESTAMPTZ,                             -- 完了日時
    cost_amount         NUMERIC(18,2) NOT NULL DEFAULT 0,        -- 品質コスト（返工費+廃棄損失+返品費）
    factory_id          BIGINT        NOT NULL,                  -- 工厂 ID
    CONSTRAINT pk_prd_ncr PRIMARY KEY (id),
    CONSTRAINT fk_prd_ncr_inspection FOREIGN KEY (inspection_id) REFERENCES prd_inspection (id),
    CONSTRAINT fk_prd_ncr_work_order FOREIGN KEY (work_order_id) REFERENCES prd_work_order (id),
    CONSTRAINT fk_prd_ncr_defect_code FOREIGN KEY (defect_code_id) REFERENCES prd_defect_code (id),
    CONSTRAINT ck_prd_ncr_status CHECK (ncr_status IN (10,20,25,30,40,90,95)),
    CONSTRAINT ck_prd_ncr_disposition CHECK (disposition_type IN (10,20,30,40,50,60)),
    CONSTRAINT ck_prd_ncr_qty CHECK (defect_qty > 0 AND disposition_qty > 0 AND disposition_qty <= defect_qty)
);
ALTER TABLE prd_ncr ENABLE ROW LEVEL SECURITY;
ALTER TABLE prd_ncr FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON prd_ncr
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_prd_ncr_no ON prd_ncr (tenant_id, company_id, ncr_no);
CREATE INDEX idx_prd_ncr_status ON prd_ncr (company_id, ncr_status, ncr_date);
CREATE INDEX idx_prd_ncr_material ON prd_ncr (company_id, material_id, lot_no);
CREATE INDEX idx_prd_ncr_wo ON prd_ncr (company_id, work_order_id) WHERE work_order_id IS NOT NULL;
COMMENT ON COLUMN prd_ncr.id IS '雪花 ID（主键）';
COMMENT ON COLUMN prd_ncr.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN prd_ncr.company_id IS '公司 ID（无默认值）';
COMMENT ON COLUMN prd_ncr.created_at IS '创建时间';
COMMENT ON COLUMN prd_ncr.created_by IS '创建人';
COMMENT ON COLUMN prd_ncr.updated_at IS '更新时间';
COMMENT ON COLUMN prd_ncr.updated_by IS '更新人';
COMMENT ON COLUMN prd_ncr.version IS '乐观锁版本';
COMMENT ON COLUMN prd_ncr.remark IS '备注';
COMMENT ON COLUMN prd_ncr.ext_data IS '扩展字段';
COMMENT ON COLUMN prd_ncr.ncr_no IS 'NCR 编号 NCR{YYMMDD}{4桁}';
COMMENT ON COLUMN prd_ncr.ncr_date IS '起票日';
COMMENT ON COLUMN prd_ncr.source_type IS '10:IQC 20:IPQC 30:FQC 40:OQC 50:客诉 60:委外受入';
COMMENT ON COLUMN prd_ncr.source_id IS '来源 ID（检验单 ID 等）';
COMMENT ON COLUMN prd_ncr.source_no IS '来源单号';
COMMENT ON COLUMN prd_ncr.inspection_id IS '检验单 ID → prd_inspection.id';
COMMENT ON COLUMN prd_ncr.work_order_id IS '工单 ID → prd_work_order.id';
COMMENT ON COLUMN prd_ncr.work_order_operation_id IS '工单工序 ID';
COMMENT ON COLUMN prd_ncr.operation_seq IS '発生工序 SEQ';
COMMENT ON COLUMN prd_ncr.material_id IS '対象品目 ID → mdm_material.id';
COMMENT ON COLUMN prd_ncr.material_code IS '品目编码（スナップショット）';
COMMENT ON COLUMN prd_ncr.material_name IS '品目名称（スナップショット）';
COMMENT ON COLUMN prd_ncr.material_spec IS '规格（スナップショット）';
COMMENT ON COLUMN prd_ncr.uom_code IS '单位';
COMMENT ON COLUMN prd_ncr.lot_no IS '批次号';
COMMENT ON COLUMN prd_ncr.supplier_id IS '仕入先 ID（IQC/委外）';
COMMENT ON COLUMN prd_ncr.customer_id IS '顧客 ID（客诉/OQC）';
COMMENT ON COLUMN prd_ncr.defect_code_id IS '主缺陷代码 ID → prd_defect_code.id';
COMMENT ON COLUMN prd_ncr.defect_qty IS '不合格数量';
COMMENT ON COLUMN prd_ncr.defect_desc IS '不良内容（現象・測定値）';
COMMENT ON COLUMN prd_ncr.disposition_type IS '10:返工 20:特采 30:报废 40:返品 50:分选 60:让步接收';
COMMENT ON COLUMN prd_ncr.disposition_qty IS '処置対象数量';
COMMENT ON COLUMN prd_ncr.responsibility_type IS '10:供方 20:自工序 30:前工序 40:设计 50:设备 60:材料';
COMMENT ON COLUMN prd_ncr.cause_type IS '10:人 20:机 30:料 40:法 50:环 60:测';
COMMENT ON COLUMN prd_ncr.root_cause IS '根本原因';
COMMENT ON COLUMN prd_ncr.corrective_action IS '纠正措施';
COMMENT ON COLUMN prd_ncr.preventive_action IS '预防措施';
COMMENT ON COLUMN prd_ncr.ncr_status IS '10:起票 20:承認待ち 25:承認済 30:処置中 40:完了 90:取消 95:却下';
COMMENT ON COLUMN prd_ncr.approved_by IS '承認者 → sys_user.id';
COMMENT ON COLUMN prd_ncr.approved_at IS '承認日時';
COMMENT ON COLUMN prd_ncr.closed_by IS '完了者';
COMMENT ON COLUMN prd_ncr.closed_at IS '完了日時';
COMMENT ON COLUMN prd_ncr.cost_amount IS '品質コスト（返工費+廃棄損失+返品費）';
COMMENT ON COLUMN prd_ncr.factory_id IS '工厂 ID';

-- prd_ncr_action
CREATE TABLE prd_ncr_action (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    remark              VARCHAR(500),
    ext_data            JSONB,
    ncr_id              BIGINT        NOT NULL,                  -- NCR ID → prd_ncr.id
    action_seq          INT           NOT NULL,                  -- 処置序号
    action_type         SMALLINT      NOT NULL,                  -- 10:返工 20:特采 30:报废 40:返品 50:再検査 60:分选
    action_qty          NUMERIC(18,4) NOT NULL,                  -- 処置数量
    rework_work_order_id BIGINT,                                 -- 返工工单 ID → prd_work_order.id
    re_inspection_id    BIGINT,                                  -- 再検査单 ID → prd_inspection.id
    return_id           BIGINT,                                  -- 採購退货单 ID → pur_return.id
    scrap_stock_txn_id  BIGINT,                                  -- 报废出庫の在庫取引 ID → inv_stock_txn.id
    action_status       SMALLINT      NOT NULL DEFAULT 10,       -- 10:未実施 20:実施中 40:完了 90:取消
    planned_date        DATE,                                    -- 予定日
    executed_at         TIMESTAMPTZ,                             -- 実施日時
    executed_by         BIGINT,                                  -- 実施者 → sys_user.id
    result_desc         VARCHAR(500),                            -- 実施結果
    cost_amount         NUMERIC(18,2) NOT NULL DEFAULT 0,        -- 処置コスト（返工費/廃棄損失/返品送料）
    CONSTRAINT pk_prd_ncr_action PRIMARY KEY (id),
    CONSTRAINT fk_prd_ncr_action_ncr FOREIGN KEY (ncr_id) REFERENCES prd_ncr (id) ON DELETE RESTRICT,
    CONSTRAINT ck_prd_ncr_action_type CHECK (action_type IN (10,20,30,40,50,60)),
    CONSTRAINT ck_prd_ncr_action_qty CHECK (action_qty > 0)
);
ALTER TABLE prd_ncr_action ENABLE ROW LEVEL SECURITY;
ALTER TABLE prd_ncr_action FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON prd_ncr_action
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_prd_ncr_action_ncr_seq ON prd_ncr_action (tenant_id, company_id, ncr_id, action_seq);
CREATE INDEX idx_prd_ncr_action_status ON prd_ncr_action (company_id, action_status, planned_date);
COMMENT ON COLUMN prd_ncr_action.id IS '雪花 ID（主键）';
COMMENT ON COLUMN prd_ncr_action.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN prd_ncr_action.company_id IS '公司 ID（无默认值）';
COMMENT ON COLUMN prd_ncr_action.created_at IS '创建时间';
COMMENT ON COLUMN prd_ncr_action.created_by IS '创建人';
COMMENT ON COLUMN prd_ncr_action.updated_at IS '更新时间';
COMMENT ON COLUMN prd_ncr_action.updated_by IS '更新人';
COMMENT ON COLUMN prd_ncr_action.version IS '乐观锁版本';
COMMENT ON COLUMN prd_ncr_action.remark IS '备注';
COMMENT ON COLUMN prd_ncr_action.ext_data IS '扩展字段';
COMMENT ON COLUMN prd_ncr_action.ncr_id IS 'NCR ID → prd_ncr.id';
COMMENT ON COLUMN prd_ncr_action.action_seq IS '処置序号';
COMMENT ON COLUMN prd_ncr_action.action_type IS '10:返工 20:特采 30:报废 40:返品 50:再検査 60:分选';
COMMENT ON COLUMN prd_ncr_action.action_qty IS '処置数量';
COMMENT ON COLUMN prd_ncr_action.rework_work_order_id IS '返工工单 ID → prd_work_order.id';
COMMENT ON COLUMN prd_ncr_action.re_inspection_id IS '再検査单 ID → prd_inspection.id';
COMMENT ON COLUMN prd_ncr_action.return_id IS '採購退货单 ID → pur_return.id';
COMMENT ON COLUMN prd_ncr_action.scrap_stock_txn_id IS '报废出庫の在庫取引 ID → inv_stock_txn.id';
COMMENT ON COLUMN prd_ncr_action.action_status IS '10:未実施 20:実施中 40:完了 90:取消';
COMMENT ON COLUMN prd_ncr_action.planned_date IS '予定日';
COMMENT ON COLUMN prd_ncr_action.executed_at IS '実施日時';
COMMENT ON COLUMN prd_ncr_action.executed_by IS '実施者 → sys_user.id';
COMMENT ON COLUMN prd_ncr_action.result_desc IS '実施結果';
COMMENT ON COLUMN prd_ncr_action.cost_amount IS '処置コスト（返工費/廃棄損失/返品送料）';

-- prd_wo_lot
CREATE TABLE prd_wo_lot (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    work_order_id       BIGINT        NOT NULL,                  -- 工单 ID → prd_work_order.id
    work_order_no       VARCHAR(32)   NOT NULL,                  -- 工单号（スナップショット）
    trace_type          SMALLINT      NOT NULL,                  -- 10:投入（材料消費） 20:産出（製品完成）
    product_lot_no      VARCHAR(64),                             -- 産出批次号（trace_type=20 または製品側）
    input_material_id   BIGINT,                                  -- 投入材料 ID → mdm_material.id
    input_material_code VARCHAR(64),                             -- 投入材料编码（スナップショット）
    input_lot_no        VARCHAR(64),                             -- 投入批次号
    input_qty           NUMERIC(18,4) NOT NULL DEFAULT 0,        -- 投入数量
    uom_code            VARCHAR(16),                             -- 单位
    operation_seq       INT,                                     -- 消費工序 SEQ
    work_center_id      BIGINT,                                  -- 工作中心 ID
    equipment_id        BIGINT,                                  -- 設備 ID
    report_id           BIGINT,                                  -- 報工单 ID → prd_work_report.id（産出時）
    inspection_id       BIGINT,                                  -- 検査单 ID → prd_inspection.id
    consumed_at         TIMESTAMPTZ,                             -- 消費/産出日時
    operator_id         BIGINT,                                  -- 作業者 → sys_user.id
    parent_wo_lot_id    BIGINT,                                  -- 親リンク ID（多階追溯）
    lot_status          SMALLINT      NOT NULL DEFAULT 10,       -- 10:有効 20:引当済 30:出荷済 90:取消
    source_type         SMALLINT,                                -- 10:采购受入 20:生産 30:委外受入 40:返品
    source_id           BIGINT,                                  -- 来源 ID
    CONSTRAINT pk_prd_wo_lot PRIMARY KEY (id),
    CONSTRAINT ck_prd_wo_lot_type CHECK (trace_type IN (10,20)),
    CONSTRAINT ck_prd_wo_lot_qty CHECK (input_qty >= 0)
);
ALTER TABLE prd_wo_lot ENABLE ROW LEVEL SECURITY;
ALTER TABLE prd_wo_lot FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON prd_wo_lot
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE INDEX idx_prd_wo_lot_wo ON prd_wo_lot (company_id, work_order_id, operation_seq);
CREATE INDEX idx_prd_wo_lot_product ON prd_wo_lot (company_id, product_lot_no, trace_type);
CREATE INDEX idx_prd_wo_lot_input ON prd_wo_lot (company_id, input_material_id, input_lot_no);
CREATE INDEX idx_prd_wo_lot_consumed ON prd_wo_lot (company_id, consumed_at);
COMMENT ON COLUMN prd_wo_lot.id IS '雪花 ID（主键）';
COMMENT ON COLUMN prd_wo_lot.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN prd_wo_lot.company_id IS '公司 ID（无默认值）';
COMMENT ON COLUMN prd_wo_lot.created_at IS '创建时间';
COMMENT ON COLUMN prd_wo_lot.created_by IS '创建人';
COMMENT ON COLUMN prd_wo_lot.work_order_id IS '工单 ID → prd_work_order.id';
COMMENT ON COLUMN prd_wo_lot.work_order_no IS '工单号（スナップショット）';
COMMENT ON COLUMN prd_wo_lot.trace_type IS '10:投入（材料消費） 20:産出（製品完成）';
COMMENT ON COLUMN prd_wo_lot.product_lot_no IS '産出批次号（trace_type=20 または製品側）';
COMMENT ON COLUMN prd_wo_lot.input_material_id IS '投入材料 ID → mdm_material.id';
COMMENT ON COLUMN prd_wo_lot.input_material_code IS '投入材料编码（スナップショット）';
COMMENT ON COLUMN prd_wo_lot.input_lot_no IS '投入批次号';
COMMENT ON COLUMN prd_wo_lot.input_qty IS '投入数量';
COMMENT ON COLUMN prd_wo_lot.uom_code IS '单位';
COMMENT ON COLUMN prd_wo_lot.operation_seq IS '消費工序 SEQ';
COMMENT ON COLUMN prd_wo_lot.work_center_id IS '工作中心 ID';
COMMENT ON COLUMN prd_wo_lot.equipment_id IS '設備 ID';
COMMENT ON COLUMN prd_wo_lot.report_id IS '報工单 ID → prd_work_report.id（産出時）';
COMMENT ON COLUMN prd_wo_lot.inspection_id IS '検査单 ID → prd_inspection.id';
COMMENT ON COLUMN prd_wo_lot.consumed_at IS '消費/産出日時';
COMMENT ON COLUMN prd_wo_lot.operator_id IS '作業者 → sys_user.id';
COMMENT ON COLUMN prd_wo_lot.parent_wo_lot_id IS '親リンク ID（多階追溯）';
COMMENT ON COLUMN prd_wo_lot.lot_status IS '10:有効 20:引当済 30:出荷済 90:取消';
COMMENT ON COLUMN prd_wo_lot.source_type IS '10:采购受入 20:生産 30:委外受入 40:返品';
COMMENT ON COLUMN prd_wo_lot.source_id IS '来源 ID';

-- prd_capacity_load
CREATE TABLE prd_capacity_load (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    work_center_id      BIGINT        NOT NULL,                  -- 工作中心 ID → prd_work_center.id
    load_date           DATE          NOT NULL,                  -- 負荷日
    load_type           SMALLINT      NOT NULL DEFAULT 10,       -- 10:計画負荷 20:実績負荷
    factory_id          BIGINT        NOT NULL,                  -- 工厂 ID
    required_hours      NUMERIC(12,2) NOT NULL DEFAULT 0,        -- 必要工数（h）
    available_hours     NUMERIC(12,2) NOT NULL DEFAULT 0,        -- 能力工数（h）
    load_rate           NUMERIC(7,4)  NOT NULL DEFAULT 0,        -- 負荷率（required ÷ available）
    work_order_count    INT           NOT NULL DEFAULT 0,        -- 対象工单数
    operation_count     INT           NOT NULL DEFAULT 0,        -- 対象工序数
    snapshot_date       DATE          NOT NULL,                  -- スナップショット日（BAT 実行日）
    CONSTRAINT pk_prd_capacity_load PRIMARY KEY (id),
    CONSTRAINT fk_prd_capacity_load_wc FOREIGN KEY (work_center_id) REFERENCES prd_work_center (id),
    CONSTRAINT ck_prd_capacity_load_type CHECK (load_type IN (10,20)),
    CONSTRAINT ck_prd_capacity_load_rate CHECK (load_rate >= 0)
);
ALTER TABLE prd_capacity_load ENABLE ROW LEVEL SECURITY;
ALTER TABLE prd_capacity_load FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON prd_capacity_load
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_prd_capacity_load_wc_date_snap ON prd_capacity_load (tenant_id, company_id, work_center_id, load_date, load_type, snapshot_date);
CREATE INDEX idx_prd_capacity_load_date ON prd_capacity_load (company_id, load_date, load_type, load_rate DESC);
COMMENT ON COLUMN prd_capacity_load.id IS '雪花 ID（主键）';
COMMENT ON COLUMN prd_capacity_load.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN prd_capacity_load.company_id IS '公司 ID（无默认值）';
COMMENT ON COLUMN prd_capacity_load.created_at IS '创建时间';
COMMENT ON COLUMN prd_capacity_load.created_by IS '创建人';
COMMENT ON COLUMN prd_capacity_load.updated_at IS '更新时间';
COMMENT ON COLUMN prd_capacity_load.updated_by IS '更新人';
COMMENT ON COLUMN prd_capacity_load.work_center_id IS '工作中心 ID → prd_work_center.id';
COMMENT ON COLUMN prd_capacity_load.load_date IS '負荷日';
COMMENT ON COLUMN prd_capacity_load.load_type IS '10:計画負荷 20:実績負荷';
COMMENT ON COLUMN prd_capacity_load.factory_id IS '工厂 ID';
COMMENT ON COLUMN prd_capacity_load.required_hours IS '必要工数（h）';
COMMENT ON COLUMN prd_capacity_load.available_hours IS '能力工数（h）';
COMMENT ON COLUMN prd_capacity_load.load_rate IS '負荷率（required ÷ available）';
COMMENT ON COLUMN prd_capacity_load.work_order_count IS '対象工单数';
COMMENT ON COLUMN prd_capacity_load.operation_count IS '対象工序数';
COMMENT ON COLUMN prd_capacity_load.snapshot_date IS 'スナップショット日（BAT 実行日）';
