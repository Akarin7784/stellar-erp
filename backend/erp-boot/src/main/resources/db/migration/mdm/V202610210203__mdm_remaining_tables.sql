-- 02-mdm 补全：#55 最小集之外的主数据表（docs/design/02-mdm/90-db-design.md）
-- 已建（跳过）：mdm_customer, mdm_factory, mdm_material, mdm_material_category, mdm_uom, mdm_warehouse
-- 规则：tenant_id DEFAULT current_setting；company_id NOT NULL 无 DEFAULT 1；
--       唯一键以 tenant_id 打头（§6.1 例外登记见 RlsCoverageTest / 04-common-db-spec）；FORCE RLS
-- 不建 fin_standard_cost / fin_publish_standard_cost；不叫分期（v1 全量补表）

-- mdm_material_factory
CREATE TABLE mdm_material_factory (
    id                  BIGINT       NOT NULL,
    tenant_id           BIGINT       NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT       NOT NULL,
    material_id         BIGINT       NOT NULL,        -- 物料ID
    factory_id          BIGINT       NOT NULL,        -- 工厂ID
    default_warehouse_id BIGINT      NULL,            -- 工厂默认仓库
    default_bin_id      BIGINT       NULL,            -- 工厂默认库位
    safety_stock_qty    NUMERIC(18,4) NULL,           -- 工厂安全库存
    reorder_point_qty   NUMERIC(18,4) NULL,           -- 工厂再订货点
    max_stock_qty       NUMERIC(18,4) NULL,           -- 工厂最大库存
    purchase_lead_time_days INT      NULL,            -- 工厂采购提前期
    manufacturing_lead_time_days INT NULL,            -- 工厂制造提前期
    mrp_type            SMALLINT     NULL,            -- 工厂MRP类型
    planning_policy     SMALLINT     NULL,            -- 工厂补充方式
    lot_size_rule       SMALLINT     NULL,            -- 10Lot-for-Lot/20固定/30期间
    is_active           BOOLEAN      NOT NULL DEFAULT TRUE, -- 展开有效
    created_at          TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_by          BIGINT       NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_by          BIGINT       NOT NULL DEFAULT 0,
    version             INT          NOT NULL DEFAULT 0,
    deleted             BOOLEAN      NOT NULL DEFAULT FALSE,
    remark              VARCHAR(500) NULL,
    ext_data            JSONB        NULL,
    CONSTRAINT pk_mdm_material_factory PRIMARY KEY (id),
    CONSTRAINT fk_mdm_material_factory_material FOREIGN KEY (material_id) REFERENCES mdm_material (id)
);

ALTER TABLE mdm_material_factory ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm_material_factory FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON mdm_material_factory
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_mdm_material_factory ON mdm_material_factory (material_id, factory_id) WHERE deleted = FALSE;
CREATE INDEX idx_mdm_material_factory_factory ON mdm_material_factory (factory_id);
COMMENT ON COLUMN mdm_material_factory.material_id IS '物料ID';
COMMENT ON COLUMN mdm_material_factory.factory_id IS '工厂ID';
COMMENT ON COLUMN mdm_material_factory.default_warehouse_id IS '工厂默认仓库';
COMMENT ON COLUMN mdm_material_factory.default_bin_id IS '工厂默认库位';
COMMENT ON COLUMN mdm_material_factory.safety_stock_qty IS '工厂安全库存';
COMMENT ON COLUMN mdm_material_factory.reorder_point_qty IS '工厂再订货点';
COMMENT ON COLUMN mdm_material_factory.max_stock_qty IS '工厂最大库存';
COMMENT ON COLUMN mdm_material_factory.purchase_lead_time_days IS '工厂采购提前期';
COMMENT ON COLUMN mdm_material_factory.manufacturing_lead_time_days IS '工厂制造提前期';
COMMENT ON COLUMN mdm_material_factory.mrp_type IS '工厂MRP类型';
COMMENT ON COLUMN mdm_material_factory.planning_policy IS '工厂补充方式';
COMMENT ON COLUMN mdm_material_factory.lot_size_rule IS '10Lot-for-Lot/20固定/30期间';
COMMENT ON COLUMN mdm_material_factory.is_active IS '展开有效';
COMMENT ON COLUMN mdm_material_factory.id IS '雪花 ID（主键）';
COMMENT ON COLUMN mdm_material_factory.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN mdm_material_factory.company_id IS '公司 ID';
COMMENT ON COLUMN mdm_material_factory.created_at IS '创建时间';
COMMENT ON COLUMN mdm_material_factory.created_by IS '创建人';
COMMENT ON COLUMN mdm_material_factory.updated_at IS '更新时间';
COMMENT ON COLUMN mdm_material_factory.updated_by IS '更新人';
COMMENT ON COLUMN mdm_material_factory.version IS '乐观锁版本';
COMMENT ON COLUMN mdm_material_factory.deleted IS '逻辑删除';
COMMENT ON COLUMN mdm_material_factory.remark IS '备注';
COMMENT ON COLUMN mdm_material_factory.ext_data IS '扩展字段';

-- mdm_material_his
CREATE TABLE mdm_material_his (
    id               BIGINT       NOT NULL,
    tenant_id        BIGINT       NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id       BIGINT       NOT NULL,
    material_id      BIGINT       NOT NULL,          -- 物料ID
    operation_type   VARCHAR(16)  NOT NULL,          -- CREATE/UPDATE/APPROVE/DEACTIVATE/REACTIVATE
    change_request_id BIGINT      NULL,              -- 变更申请ID
    before_data      JSONB        NULL,              -- 变更前（CREATE时为NULL）
    after_data       JSONB        NULL,              -- 变更后
    change_reason    VARCHAR(1000) NULL,             -- 变更理由
    created_at       TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_by       BIGINT       NOT NULL DEFAULT 0,
    CONSTRAINT pk_mdm_material_his PRIMARY KEY (id)
);

ALTER TABLE mdm_material_his ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm_material_his FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON mdm_material_his
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE INDEX idx_mdm_material_his_material ON mdm_material_his (material_id, created_at DESC);
CREATE INDEX idx_mdm_material_his_request ON mdm_material_his (change_request_id);
COMMENT ON COLUMN mdm_material_his.material_id IS '物料ID';
COMMENT ON COLUMN mdm_material_his.operation_type IS 'CREATE/UPDATE/APPROVE/DEACTIVATE/REACTIVATE';
COMMENT ON COLUMN mdm_material_his.change_request_id IS '变更申请ID';
COMMENT ON COLUMN mdm_material_his.before_data IS '变更前（CREATE时为NULL）';
COMMENT ON COLUMN mdm_material_his.after_data IS '变更后';
COMMENT ON COLUMN mdm_material_his.change_reason IS '变更理由';
COMMENT ON COLUMN mdm_material_his.id IS '雪花 ID（主键）';
COMMENT ON COLUMN mdm_material_his.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN mdm_material_his.company_id IS '公司 ID';
COMMENT ON COLUMN mdm_material_his.created_at IS '创建时间';
COMMENT ON COLUMN mdm_material_his.created_by IS '创建人';

-- mdm_material_substitute
CREATE TABLE mdm_material_substitute (
    id                   BIGINT      NOT NULL,
    tenant_id            BIGINT      NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id           BIGINT      NOT NULL,
    material_id          BIGINT      NOT NULL,       -- 替代源物料
    substitute_material_id BIGINT    NOT NULL,       -- 替代目标物料
    substitute_type      SMALLINT    NOT NULL,       -- 10完全/20条件/30单向/40紧急
    is_bidirectional     BOOLEAN     NOT NULL DEFAULT FALSE, -- 双向
    priority             INT         NOT NULL DEFAULT 100,   -- 优先级（小优先）
    conversion_ratio     NUMERIC(18,8) NOT NULL DEFAULT 1,   -- 替代换算比
    valid_from           DATE        NOT NULL,       -- 有效开始
    valid_to             DATE        NULL,           -- 有效结束
    customer_approval_no VARCHAR(64) NULL,           -- 客户承认编号
    ecn_no               VARCHAR(64) NULL,           -- 设计变更号
    approval_status      SMALLINT    NOT NULL DEFAULT 10, -- 审批状态
    status               SMALLINT    NOT NULL DEFAULT 1,  -- 1有效/0停止
    reason               VARCHAR(500) NOT NULL,      -- 替代理由
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by           BIGINT      NOT NULL DEFAULT 0,
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_by           BIGINT      NOT NULL DEFAULT 0,
    version              INT         NOT NULL DEFAULT 0,
    deleted              BOOLEAN     NOT NULL DEFAULT FALSE,
    remark               VARCHAR(500) NULL,
    ext_data             JSONB       NULL,
    CONSTRAINT pk_mdm_material_substitute PRIMARY KEY (id),
    CONSTRAINT fk_mdm_substitute_material FOREIGN KEY (material_id) REFERENCES mdm_material (id),
    CONSTRAINT fk_mdm_substitute_target FOREIGN KEY (substitute_material_id) REFERENCES mdm_material (id),
    CONSTRAINT ck_mdm_substitute_diff CHECK (material_id <> substitute_material_id),
    CONSTRAINT ck_mdm_substitute_type CHECK (substitute_type IN (10,20,30,40)),
    CONSTRAINT ck_mdm_substitute_ratio CHECK (conversion_ratio > 0)
);

ALTER TABLE mdm_material_substitute ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm_material_substitute FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON mdm_material_substitute
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_mdm_substitute ON mdm_material_substitute (material_id, substitute_material_id, valid_from) WHERE deleted = FALSE;
CREATE INDEX idx_mdm_substitute_target ON mdm_material_substitute (substitute_material_id, status);
COMMENT ON COLUMN mdm_material_substitute.material_id IS '替代源物料';
COMMENT ON COLUMN mdm_material_substitute.substitute_material_id IS '替代目标物料';
COMMENT ON COLUMN mdm_material_substitute.substitute_type IS '10完全/20条件/30单向/40紧急';
COMMENT ON COLUMN mdm_material_substitute.is_bidirectional IS '双向';
COMMENT ON COLUMN mdm_material_substitute.priority IS '优先级（小优先）';
COMMENT ON COLUMN mdm_material_substitute.conversion_ratio IS '替代换算比';
COMMENT ON COLUMN mdm_material_substitute.valid_from IS '有效开始';
COMMENT ON COLUMN mdm_material_substitute.valid_to IS '有效结束';
COMMENT ON COLUMN mdm_material_substitute.customer_approval_no IS '客户承认编号';
COMMENT ON COLUMN mdm_material_substitute.ecn_no IS '设计变更号';
COMMENT ON COLUMN mdm_material_substitute.approval_status IS '审批状态';
COMMENT ON COLUMN mdm_material_substitute.status IS '1有效/0停止';
COMMENT ON COLUMN mdm_material_substitute.reason IS '替代理由';
COMMENT ON COLUMN mdm_material_substitute.id IS '雪花 ID（主键）';
COMMENT ON COLUMN mdm_material_substitute.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN mdm_material_substitute.company_id IS '公司 ID';
COMMENT ON COLUMN mdm_material_substitute.created_at IS '创建时间';
COMMENT ON COLUMN mdm_material_substitute.created_by IS '创建人';
COMMENT ON COLUMN mdm_material_substitute.updated_at IS '更新时间';
COMMENT ON COLUMN mdm_material_substitute.updated_by IS '更新人';
COMMENT ON COLUMN mdm_material_substitute.version IS '乐观锁版本';
COMMENT ON COLUMN mdm_material_substitute.deleted IS '逻辑删除';
COMMENT ON COLUMN mdm_material_substitute.remark IS '备注';
COMMENT ON COLUMN mdm_material_substitute.ext_data IS '扩展字段';

-- mdm_material_barcode
CREATE TABLE mdm_material_barcode (
    id              BIGINT       NOT NULL,
    tenant_id       BIGINT       NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id      BIGINT       NOT NULL,
    material_id     BIGINT       NOT NULL,          -- 物料ID
    barcode_rule_code VARCHAR(32) NOT NULL,         -- 条码规则
    barcode_value   VARCHAR(128) NOT NULL,          -- 条码内容
    barcode_type    SMALLINT     NOT NULL,          -- 10Code128/20GS1-128/30QR
    batch_no        VARCHAR(64)  NULL,              -- 批次号（批次条码）
    label_qty       NUMERIC(18,4) NULL,             -- 包装数量
    print_count     INT          NOT NULL DEFAULT 0,-- 打印次数
    printed_at      TIMESTAMPTZ  NULL,              -- 最后打印时间
    is_active       BOOLEAN      NOT NULL DEFAULT TRUE, -- 有效
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_by      BIGINT       NOT NULL DEFAULT 0,
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_by      BIGINT       NOT NULL DEFAULT 0,
    version         INT          NOT NULL DEFAULT 0,
    deleted         BOOLEAN      NOT NULL DEFAULT FALSE,
    CONSTRAINT pk_mdm_material_barcode PRIMARY KEY (id),
    CONSTRAINT fk_mdm_barcode_material FOREIGN KEY (material_id) REFERENCES mdm_material (id)
);

ALTER TABLE mdm_material_barcode ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm_material_barcode FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON mdm_material_barcode
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_mdm_material_barcode_value ON mdm_material_barcode (tenant_id, company_id, barcode_value) WHERE deleted = FALSE;
CREATE INDEX idx_mdm_material_barcode_material ON mdm_material_barcode (material_id, is_active);
COMMENT ON COLUMN mdm_material_barcode.material_id IS '物料ID';
COMMENT ON COLUMN mdm_material_barcode.barcode_rule_code IS '条码规则';
COMMENT ON COLUMN mdm_material_barcode.barcode_value IS '条码内容';
COMMENT ON COLUMN mdm_material_barcode.barcode_type IS '10Code128/20GS1-128/30QR';
COMMENT ON COLUMN mdm_material_barcode.batch_no IS '批次号（批次条码）';
COMMENT ON COLUMN mdm_material_barcode.label_qty IS '包装数量';
COMMENT ON COLUMN mdm_material_barcode.print_count IS '打印次数';
COMMENT ON COLUMN mdm_material_barcode.printed_at IS '最后打印时间';
COMMENT ON COLUMN mdm_material_barcode.is_active IS '有效';
COMMENT ON COLUMN mdm_material_barcode.id IS '雪花 ID（主键）';
COMMENT ON COLUMN mdm_material_barcode.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN mdm_material_barcode.company_id IS '公司 ID';
COMMENT ON COLUMN mdm_material_barcode.created_at IS '创建时间';
COMMENT ON COLUMN mdm_material_barcode.created_by IS '创建人';
COMMENT ON COLUMN mdm_material_barcode.updated_at IS '更新时间';
COMMENT ON COLUMN mdm_material_barcode.updated_by IS '更新人';
COMMENT ON COLUMN mdm_material_barcode.version IS '乐观锁版本';
COMMENT ON COLUMN mdm_material_barcode.deleted IS '逻辑删除';

-- mdm_code_rule
CREATE TABLE mdm_code_rule (
    id              BIGINT       NOT NULL,
    tenant_id       BIGINT       NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id      BIGINT       NOT NULL,
    object_type     VARCHAR(32)  NOT NULL,          -- MATERIAL/CUSTOMER/SUPPLIER/WAREHOUSE/BIN...
    rule_code       VARCHAR(32)  NOT NULL,          -- 规则编码
    rule_name       VARCHAR(100) NOT NULL,          -- 规则名称
    code_pattern    VARCHAR(200) NOT NULL,          -- 编码模板（例 {categoryCode}{serial:6}）
    prefix          VARCHAR(16)  NULL,              -- 前缀（C/S/WH）
    serial_length   SMALLINT     NOT NULL,          -- 流水位数
    sequence_key_template VARCHAR(100) NOT NULL,    -- 序列键模板
    reset_cycle     VARCHAR(16)  NOT NULL DEFAULT 'NONE', -- NONE/DAILY/MONTHLY
    allow_manual    BOOLEAN      NOT NULL DEFAULT FALSE,  -- 允许手工指定
    status          SMALLINT     NOT NULL DEFAULT 1,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_by      BIGINT       NOT NULL DEFAULT 0,
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_by      BIGINT       NOT NULL DEFAULT 0,
    version         INT          NOT NULL DEFAULT 0,
    deleted         BOOLEAN      NOT NULL DEFAULT FALSE,
    remark          VARCHAR(500) NULL,
    CONSTRAINT pk_mdm_code_rule PRIMARY KEY (id)
);

ALTER TABLE mdm_code_rule ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm_code_rule FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON mdm_code_rule
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_mdm_code_rule_object ON mdm_code_rule (tenant_id, company_id, object_type, rule_code) WHERE deleted = FALSE;
COMMENT ON COLUMN mdm_code_rule.object_type IS 'MATERIAL/CUSTOMER/SUPPLIER/WAREHOUSE/BIN...';
COMMENT ON COLUMN mdm_code_rule.rule_code IS '规则编码';
COMMENT ON COLUMN mdm_code_rule.rule_name IS '规则名称';
COMMENT ON COLUMN mdm_code_rule.code_pattern IS '编码模板（例 {categoryCode}{serial:6}）';
COMMENT ON COLUMN mdm_code_rule.prefix IS '前缀（C/S/WH）';
COMMENT ON COLUMN mdm_code_rule.serial_length IS '流水位数';
COMMENT ON COLUMN mdm_code_rule.sequence_key_template IS '序列键模板';
COMMENT ON COLUMN mdm_code_rule.reset_cycle IS 'NONE/DAILY/MONTHLY';
COMMENT ON COLUMN mdm_code_rule.allow_manual IS '允许手工指定';
COMMENT ON COLUMN mdm_code_rule.id IS '雪花 ID（主键）';
COMMENT ON COLUMN mdm_code_rule.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN mdm_code_rule.company_id IS '公司 ID';
COMMENT ON COLUMN mdm_code_rule.created_at IS '创建时间';
COMMENT ON COLUMN mdm_code_rule.created_by IS '创建人';
COMMENT ON COLUMN mdm_code_rule.updated_at IS '更新时间';
COMMENT ON COLUMN mdm_code_rule.updated_by IS '更新人';
COMMENT ON COLUMN mdm_code_rule.version IS '乐观锁版本';
COMMENT ON COLUMN mdm_code_rule.deleted IS '逻辑删除';
COMMENT ON COLUMN mdm_code_rule.remark IS '备注';

-- mdm_ext_field
CREATE TABLE mdm_ext_field (
    id              BIGINT       NOT NULL,
    tenant_id       BIGINT       NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id      BIGINT       NOT NULL,
    object_type     VARCHAR(32)  NOT NULL,          -- MATERIAL/CUSTOMER/SUPPLIER...
    field_code      VARCHAR(64)  NOT NULL,          -- 字段代码（JSON key）
    field_name      VARCHAR(100) NOT NULL,          -- 字段名称
    data_type       VARCHAR(16)  NOT NULL,          -- STRING/NUMBER/DATE/BOOLEAN/ENUM
    is_required     BOOLEAN      NOT NULL DEFAULT FALSE,
    enum_options    JSONB        NULL,              -- 选择项（ENUM）
    validation_expression VARCHAR(500) NULL,        -- 校验正则/表达式
    display_order   INT          NOT NULL DEFAULT 0,
    status          SMALLINT     NOT NULL DEFAULT 1,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_by      BIGINT       NOT NULL DEFAULT 0,
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_by      BIGINT       NOT NULL DEFAULT 0,
    version         INT          NOT NULL DEFAULT 0,
    deleted         BOOLEAN      NOT NULL DEFAULT FALSE,
    remark          VARCHAR(500) NULL,
    CONSTRAINT pk_mdm_ext_field PRIMARY KEY (id)
);

ALTER TABLE mdm_ext_field ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm_ext_field FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON mdm_ext_field
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_mdm_ext_field ON mdm_ext_field (tenant_id, company_id, object_type, field_code) WHERE deleted = FALSE;

COMMENT ON COLUMN mdm_ext_field.object_type IS 'MATERIAL/CUSTOMER/SUPPLIER...';
COMMENT ON COLUMN mdm_ext_field.field_code IS '字段代码（JSON key）';
COMMENT ON COLUMN mdm_ext_field.field_name IS '字段名称';
COMMENT ON COLUMN mdm_ext_field.data_type IS 'STRING/NUMBER/DATE/BOOLEAN/ENUM';
COMMENT ON COLUMN mdm_ext_field.enum_options IS '选择项（ENUM）';
COMMENT ON COLUMN mdm_ext_field.validation_expression IS '校验正则/表达式';
COMMENT ON COLUMN mdm_ext_field.id IS '雪花 ID（主键）';
COMMENT ON COLUMN mdm_ext_field.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN mdm_ext_field.company_id IS '公司 ID';
COMMENT ON COLUMN mdm_ext_field.created_at IS '创建时间';
COMMENT ON COLUMN mdm_ext_field.created_by IS '创建人';
COMMENT ON COLUMN mdm_ext_field.updated_at IS '更新时间';
COMMENT ON COLUMN mdm_ext_field.updated_by IS '更新人';
COMMENT ON COLUMN mdm_ext_field.version IS '乐观锁版本';
COMMENT ON COLUMN mdm_ext_field.deleted IS '逻辑删除';
COMMENT ON COLUMN mdm_ext_field.remark IS '备注';

-- mdm_customer_contact
CREATE TABLE mdm_customer_contact (
    id BIGINT NOT NULL, tenant_id BIGINT NOT NULL DEFAULT current_setting('app.tenant_id')::bigint, company_id BIGINT NOT NULL,
    customer_id BIGINT NOT NULL,                       -- 客户ID
    contact_name VARCHAR(64) NOT NULL,                 -- 姓名
    contact_position VARCHAR(64) NULL,                 -- 职位
    contact_phone VARCHAR(32) NULL,                    -- 电话
    contact_email VARCHAR(128) NULL,                   -- 邮箱
    contact_wechat VARCHAR(64) NULL,                   -- 微信/其他
    is_default_contact BOOLEAN NOT NULL DEFAULT FALSE, -- 默认联系人
    status SMALLINT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), created_by BIGINT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_by BIGINT NOT NULL DEFAULT 0,
    version INT NOT NULL DEFAULT 0, deleted BOOLEAN NOT NULL DEFAULT FALSE, remark VARCHAR(500) NULL,
    CONSTRAINT pk_mdm_customer_contact PRIMARY KEY (id),
    CONSTRAINT fk_mdm_customer_contact_customer FOREIGN KEY (customer_id) REFERENCES mdm_customer (id)
);

ALTER TABLE mdm_customer_contact ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm_customer_contact FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON mdm_customer_contact
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE INDEX idx_mdm_customer_contact_customer ON mdm_customer_contact (customer_id, deleted);
COMMENT ON COLUMN mdm_customer_contact.customer_id IS '客户ID';
COMMENT ON COLUMN mdm_customer_contact.contact_name IS '姓名';
COMMENT ON COLUMN mdm_customer_contact.contact_position IS '职位';
COMMENT ON COLUMN mdm_customer_contact.contact_phone IS '电话';
COMMENT ON COLUMN mdm_customer_contact.contact_email IS '邮箱';
COMMENT ON COLUMN mdm_customer_contact.contact_wechat IS '微信/其他';
COMMENT ON COLUMN mdm_customer_contact.is_default_contact IS '默认联系人';
COMMENT ON COLUMN mdm_customer_contact.id IS '雪花 ID（主键）';
COMMENT ON COLUMN mdm_customer_contact.created_at IS '创建时间';
COMMENT ON COLUMN mdm_customer_contact.updated_at IS '更新时间';
COMMENT ON COLUMN mdm_customer_contact.version IS '乐观锁版本';

-- mdm_customer_address
CREATE TABLE mdm_customer_address (
    id BIGINT NOT NULL, tenant_id BIGINT NOT NULL DEFAULT current_setting('app.tenant_id')::bigint, company_id BIGINT NOT NULL,
    customer_id BIGINT NOT NULL,                       -- 客户ID
    address_name VARCHAR(100) NOT NULL,                -- 地址名称
    receiver_name VARCHAR(64) NOT NULL,                -- 收货人
    receiver_phone VARCHAR(32) NOT NULL,               -- 收货电话
    address_detail VARCHAR(200) NOT NULL,              -- 详细地址
    region_code VARCHAR(12) NULL,                      -- 行政区划（GB/T 2260）
    delivery_window VARCHAR(64) NULL,                  -- 收货时间窗
    is_default_address BOOLEAN NOT NULL DEFAULT FALSE, -- 默认地址
    status SMALLINT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), created_by BIGINT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_by BIGINT NOT NULL DEFAULT 0,
    version INT NOT NULL DEFAULT 0, deleted BOOLEAN NOT NULL DEFAULT FALSE, remark VARCHAR(500) NULL,
    CONSTRAINT pk_mdm_customer_address PRIMARY KEY (id),
    CONSTRAINT fk_mdm_customer_address_customer FOREIGN KEY (customer_id) REFERENCES mdm_customer (id)
);

ALTER TABLE mdm_customer_address ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm_customer_address FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON mdm_customer_address
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE INDEX idx_mdm_customer_address_customer ON mdm_customer_address (customer_id, deleted);
COMMENT ON COLUMN mdm_customer_address.customer_id IS '客户ID';
COMMENT ON COLUMN mdm_customer_address.address_name IS '地址名称';
COMMENT ON COLUMN mdm_customer_address.receiver_name IS '收货人';
COMMENT ON COLUMN mdm_customer_address.receiver_phone IS '收货电话';
COMMENT ON COLUMN mdm_customer_address.address_detail IS '详细地址';
COMMENT ON COLUMN mdm_customer_address.region_code IS '行政区划（GB/T 2260）';
COMMENT ON COLUMN mdm_customer_address.delivery_window IS '收货时间窗';
COMMENT ON COLUMN mdm_customer_address.is_default_address IS '默认地址';
COMMENT ON COLUMN mdm_customer_address.id IS '雪花 ID（主键）';
COMMENT ON COLUMN mdm_customer_address.created_at IS '创建时间';
COMMENT ON COLUMN mdm_customer_address.updated_at IS '更新时间';
COMMENT ON COLUMN mdm_customer_address.version IS '乐观锁版本';

-- mdm_customer_his
CREATE TABLE mdm_customer_his (
    id BIGINT NOT NULL, tenant_id BIGINT NOT NULL DEFAULT current_setting('app.tenant_id')::bigint, company_id BIGINT NOT NULL,
    customer_id BIGINT NOT NULL,                       -- 客户ID
    operation_type VARCHAR(16) NOT NULL,               -- CREATE/UPDATE/APPROVE/DEACTIVATE
    change_request_id BIGINT NULL,                     -- 变更申请ID
    before_data JSONB NULL, after_data JSONB NULL,     -- 变更前后
    change_reason VARCHAR(1000) NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), created_by BIGINT NOT NULL DEFAULT 0,
    CONSTRAINT pk_mdm_customer_his PRIMARY KEY (id)
);

ALTER TABLE mdm_customer_his ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm_customer_his FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON mdm_customer_his
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE INDEX idx_mdm_customer_his_customer ON mdm_customer_his (customer_id, created_at DESC);
COMMENT ON COLUMN mdm_customer_his.customer_id IS '客户ID';
COMMENT ON COLUMN mdm_customer_his.operation_type IS 'CREATE/UPDATE/APPROVE/DEACTIVATE';
COMMENT ON COLUMN mdm_customer_his.change_request_id IS '变更申请ID';
COMMENT ON COLUMN mdm_customer_his.before_data IS '变更前后';
COMMENT ON COLUMN mdm_customer_his.id IS '雪花 ID（主键）';
COMMENT ON COLUMN mdm_customer_his.created_at IS '创建时间';

-- mdm_supplier
CREATE TABLE mdm_supplier (
    id BIGINT NOT NULL, tenant_id BIGINT NOT NULL DEFAULT current_setting('app.tenant_id')::bigint, company_id BIGINT NOT NULL,
    supplier_code VARCHAR(8) NOT NULL,                 -- 供应商编码（S+6位）
    supplier_name VARCHAR(200) NOT NULL,               -- 供应商名称
    short_name VARCHAR(100) NULL,                      -- 简称
    supplier_type SMALLINT NOT NULL,                   -- 10制造商/20经销商/30外注/40服务
    supplier_grade VARCHAR(1) NULL,                    -- 分级 A/B/C/D
    tax_no VARCHAR(18) NOT NULL,                       -- 统一社会信用代码
    legal_rep VARCHAR(64) NULL,                        -- 法定代表人
    registered_address VARCHAR(200) NULL,              -- 注册地址
    office_address VARCHAR(200) NULL,                  -- 办公地址
    contact_phone VARCHAR(32) NULL,                    -- 代表电话
    buyer_id BIGINT NOT NULL,                          -- 采购担当
    default_lead_time_days INT NULL,                   -- 标准采购提前期
    over_receipt_tolerance_pct NUMERIC(5,4) NULL,      -- 過入荷容差（比率 0.05=5%。仕入先既定。品目>分類>仕入先>会社の優先順、05 §2.4）
    currency_code VARCHAR(3) NOT NULL DEFAULT 'CNY',   -- 交易币种
    admission_status SMALLINT NOT NULL DEFAULT 10,     -- 10潜在/20审查中/30合格/40不合格/50暂停/60淘汰
    admitted_at TIMESTAMPTZ NULL, admitted_by BIGINT NULL,
    payment_term_code VARCHAR(32) NOT NULL,            -- 付款条件
    settlement_method_code VARCHAR(32) NOT NULL,       -- 结算方式
    tax_code VARCHAR(32) NULL,                         -- 默认税码（进项）
    ap_account_code VARCHAR(32) NULL,                  -- 应付账款科目
    advance_payment_allowed BOOLEAN NOT NULL DEFAULT FALSE, -- 允许预付款
    vmi_flag BOOLEAN NOT NULL DEFAULT FALSE,           -- VMI对象
    status SMALLINT NOT NULL DEFAULT 0,                -- 1有效/0停止
    approval_status SMALLINT NOT NULL DEFAULT 10,
    submitted_at TIMESTAMPTZ NULL, approved_at TIMESTAMPTZ NULL, approved_by BIGINT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), created_by BIGINT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_by BIGINT NOT NULL DEFAULT 0,
    version INT NOT NULL DEFAULT 0, deleted BOOLEAN NOT NULL DEFAULT FALSE,
    remark VARCHAR(500) NULL, ext_data JSONB NULL,
    CONSTRAINT pk_mdm_supplier PRIMARY KEY (id),
    CONSTRAINT ck_mdm_supplier_type CHECK (supplier_type IN (10,20,30,40)),
    CONSTRAINT ck_mdm_supplier_admission CHECK (admission_status IN (10,20,30,40,50,60))
);

ALTER TABLE mdm_supplier ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm_supplier FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON mdm_supplier
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE INDEX idx_mdm_supplier_admission ON mdm_supplier (admission_status, supplier_grade);
CREATE UNIQUE INDEX uk_mdm_supplier_code ON mdm_supplier (tenant_id, company_id, supplier_code) WHERE deleted = FALSE;
CREATE UNIQUE INDEX uk_mdm_supplier_tax_no ON mdm_supplier (tenant_id, company_id, tax_no) WHERE deleted = FALSE;

CREATE INDEX idx_mdm_supplier_buyer ON mdm_supplier (buyer_id);
CREATE INDEX gin_mdm_supplier_name ON mdm_supplier USING gin (supplier_name gin_trgm_ops);
COMMENT ON COLUMN mdm_supplier.supplier_code IS '供应商编码（S+6位）';
COMMENT ON COLUMN mdm_supplier.supplier_name IS '供应商名称';
COMMENT ON COLUMN mdm_supplier.short_name IS '简称';
COMMENT ON COLUMN mdm_supplier.supplier_type IS '10制造商/20经销商/30外注/40服务';
COMMENT ON COLUMN mdm_supplier.supplier_grade IS '分级 A/B/C/D';
COMMENT ON COLUMN mdm_supplier.tax_no IS '统一社会信用代码';
COMMENT ON COLUMN mdm_supplier.legal_rep IS '法定代表人';
COMMENT ON COLUMN mdm_supplier.registered_address IS '注册地址';
COMMENT ON COLUMN mdm_supplier.office_address IS '办公地址';
COMMENT ON COLUMN mdm_supplier.contact_phone IS '代表电话';
COMMENT ON COLUMN mdm_supplier.buyer_id IS '采购担当';
COMMENT ON COLUMN mdm_supplier.default_lead_time_days IS '标准采购提前期';
COMMENT ON COLUMN mdm_supplier.over_receipt_tolerance_pct IS '過入荷容差（比率 0.05=5%。仕入先既定。品目>分類>仕入先>会社の優先順、05 §2.4）';
COMMENT ON COLUMN mdm_supplier.currency_code IS '交易币种';
COMMENT ON COLUMN mdm_supplier.admission_status IS '10潜在/20审查中/30合格/40不合格/50暂停/60淘汰';
COMMENT ON COLUMN mdm_supplier.payment_term_code IS '付款条件';
COMMENT ON COLUMN mdm_supplier.settlement_method_code IS '结算方式';
COMMENT ON COLUMN mdm_supplier.tax_code IS '默认税码（进项）';
COMMENT ON COLUMN mdm_supplier.ap_account_code IS '应付账款科目';
COMMENT ON COLUMN mdm_supplier.advance_payment_allowed IS '允许预付款';
COMMENT ON COLUMN mdm_supplier.vmi_flag IS 'VMI对象';
COMMENT ON COLUMN mdm_supplier.status IS '1有效/0停止';
COMMENT ON COLUMN mdm_supplier.id IS '雪花 ID（主键）';
COMMENT ON COLUMN mdm_supplier.created_at IS '创建时间';
COMMENT ON COLUMN mdm_supplier.updated_at IS '更新时间';
COMMENT ON COLUMN mdm_supplier.version IS '乐观锁版本';
COMMENT ON COLUMN mdm_supplier.remark IS '备注';

-- mdm_supplier_contact
CREATE TABLE mdm_supplier_contact (
    id BIGINT NOT NULL, tenant_id BIGINT NOT NULL DEFAULT current_setting('app.tenant_id')::bigint, company_id BIGINT NOT NULL,
    supplier_id BIGINT NOT NULL, contact_name VARCHAR(64) NOT NULL,
    contact_position VARCHAR(64) NULL, contact_phone VARCHAR(32) NULL,
    contact_email VARCHAR(128) NULL, is_default_contact BOOLEAN NOT NULL DEFAULT FALSE,
    status SMALLINT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), created_by BIGINT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_by BIGINT NOT NULL DEFAULT 0,
    version INT NOT NULL DEFAULT 0, deleted BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT pk_mdm_supplier_contact PRIMARY KEY (id),
    CONSTRAINT fk_mdm_supplier_contact_supplier FOREIGN KEY (supplier_id) REFERENCES mdm_supplier (id)
);

ALTER TABLE mdm_supplier_contact ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm_supplier_contact FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON mdm_supplier_contact
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE INDEX idx_mdm_supplier_contact_supplier ON mdm_supplier_contact (supplier_id, deleted);
COMMENT ON COLUMN mdm_supplier_contact.id IS '雪花 ID（主键）';
COMMENT ON COLUMN mdm_supplier_contact.created_at IS '创建时间';
COMMENT ON COLUMN mdm_supplier_contact.updated_at IS '更新时间';
COMMENT ON COLUMN mdm_supplier_contact.version IS '乐观锁版本';

-- mdm_supplier_address
CREATE TABLE mdm_supplier_address (
    id BIGINT NOT NULL, tenant_id BIGINT NOT NULL DEFAULT current_setting('app.tenant_id')::bigint, company_id BIGINT NOT NULL,
    supplier_id BIGINT NOT NULL, address_type SMALLINT NOT NULL DEFAULT 10, -- 10送货/20开票/30注册
    address_name VARCHAR(100) NOT NULL, address_detail VARCHAR(200) NOT NULL,
    contact_name VARCHAR(64) NULL, contact_phone VARCHAR(32) NULL,
    is_default_address BOOLEAN NOT NULL DEFAULT FALSE, status SMALLINT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), created_by BIGINT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_by BIGINT NOT NULL DEFAULT 0,
    version INT NOT NULL DEFAULT 0, deleted BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT pk_mdm_supplier_address PRIMARY KEY (id),
    CONSTRAINT fk_mdm_supplier_address_supplier FOREIGN KEY (supplier_id) REFERENCES mdm_supplier (id)
);

ALTER TABLE mdm_supplier_address ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm_supplier_address FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON mdm_supplier_address
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE INDEX idx_mdm_supplier_address_supplier ON mdm_supplier_address (supplier_id, deleted);
COMMENT ON COLUMN mdm_supplier_address.supplier_id IS '10送货/20开票/30注册';
COMMENT ON COLUMN mdm_supplier_address.id IS '雪花 ID（主键）';
COMMENT ON COLUMN mdm_supplier_address.created_at IS '创建时间';
COMMENT ON COLUMN mdm_supplier_address.updated_at IS '更新时间';
COMMENT ON COLUMN mdm_supplier_address.version IS '乐观锁版本';

-- mdm_supplier_qualification
CREATE TABLE mdm_supplier_qualification (
    id BIGINT NOT NULL, tenant_id BIGINT NOT NULL DEFAULT current_setting('app.tenant_id')::bigint, company_id BIGINT NOT NULL,
    supplier_id BIGINT NOT NULL, qualification_type VARCHAR(32) NOT NULL, -- BUSINESS_LICENSE/ISO9001/ISO14001/CCC/EXPROOF/OTHER
    qualification_no VARCHAR(64) NOT NULL, issuer VARCHAR(100) NULL,
    valid_from DATE NOT NULL, valid_to DATE NULL,      -- 有效期
    attachment_id BIGINT NULL,                          -- 附件（SYS）
    status SMALLINT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), created_by BIGINT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_by BIGINT NOT NULL DEFAULT 0,
    version INT NOT NULL DEFAULT 0, deleted BOOLEAN NOT NULL DEFAULT FALSE, remark VARCHAR(500) NULL,
    CONSTRAINT pk_mdm_supplier_qualification PRIMARY KEY (id),
    CONSTRAINT fk_mdm_supplier_qualification_supplier FOREIGN KEY (supplier_id) REFERENCES mdm_supplier (id)
);

ALTER TABLE mdm_supplier_qualification ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm_supplier_qualification FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON mdm_supplier_qualification
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE INDEX idx_mdm_supplier_qual_supplier ON mdm_supplier_qualification (supplier_id, valid_to);
CREATE INDEX idx_mdm_supplier_qual_expiry ON mdm_supplier_qualification (valid_to) WHERE deleted = FALSE;
COMMENT ON COLUMN mdm_supplier_qualification.supplier_id IS 'BUSINESS_LICENSE/ISO9001/ISO14001/CCC/EXPROOF/OTHER';
COMMENT ON COLUMN mdm_supplier_qualification.valid_from IS '有效期';
COMMENT ON COLUMN mdm_supplier_qualification.attachment_id IS '附件（SYS）';
COMMENT ON COLUMN mdm_supplier_qualification.id IS '雪花 ID（主键）';
COMMENT ON COLUMN mdm_supplier_qualification.created_at IS '创建时间';
COMMENT ON COLUMN mdm_supplier_qualification.updated_at IS '更新时间';
COMMENT ON COLUMN mdm_supplier_qualification.version IS '乐观锁版本';

-- mdm_supplier_material
CREATE TABLE mdm_supplier_material (
    id BIGINT NOT NULL, tenant_id BIGINT NOT NULL DEFAULT current_setting('app.tenant_id')::bigint, company_id BIGINT NOT NULL,
    supplier_id BIGINT NOT NULL, material_id BIGINT NULL,       -- 物料ID（或分类）
    category_code VARCHAR(4) NULL,                              -- 物料分类（物料为空时使用）
    priority INT NOT NULL DEFAULT 100,                          -- 优先级
    is_preferred BOOLEAN NOT NULL DEFAULT FALSE,                -- 推荐供应商
    moq NUMERIC(18,4) NULL,                                     -- 最小発注量（供給範囲単位。未設定時は mdm_material.min_order_qty）
    purchase_lead_time_days INT NULL,                           -- 購買提前期（供給範囲単位。未設定時は mdm_supplier.default_lead_time_days）
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), created_by BIGINT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_by BIGINT NOT NULL DEFAULT 0,
    version INT NOT NULL DEFAULT 0, deleted BOOLEAN NOT NULL DEFAULT FALSE, remark VARCHAR(500) NULL,
    CONSTRAINT pk_mdm_supplier_material PRIMARY KEY (id),
    CONSTRAINT fk_mdm_supplier_material_supplier FOREIGN KEY (supplier_id) REFERENCES mdm_supplier (id),
    CONSTRAINT ck_mdm_supplier_material_target CHECK (material_id IS NOT NULL OR category_code IS NOT NULL)
);

ALTER TABLE mdm_supplier_material ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm_supplier_material FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON mdm_supplier_material
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE INDEX idx_mdm_supplier_material_material ON mdm_supplier_material (material_id, is_active);
CREATE INDEX idx_mdm_supplier_material_supplier ON mdm_supplier_material (supplier_id, is_active);
COMMENT ON COLUMN mdm_supplier_material.supplier_id IS '物料ID（或分类）';
COMMENT ON COLUMN mdm_supplier_material.category_code IS '物料分类（物料为空时使用）';
COMMENT ON COLUMN mdm_supplier_material.priority IS '优先级';
COMMENT ON COLUMN mdm_supplier_material.is_preferred IS '推荐供应商';
COMMENT ON COLUMN mdm_supplier_material.moq IS '最小発注量（供給範囲単位。未設定時は mdm_material.min_order_qty）';
COMMENT ON COLUMN mdm_supplier_material.purchase_lead_time_days IS '購買提前期（供給範囲単位。未設定時は mdm_supplier.default_lead_time_days）';
COMMENT ON COLUMN mdm_supplier_material.id IS '雪花 ID（主键）';
COMMENT ON COLUMN mdm_supplier_material.created_at IS '创建时间';
COMMENT ON COLUMN mdm_supplier_material.updated_at IS '更新时间';
COMMENT ON COLUMN mdm_supplier_material.version IS '乐观锁版本';

-- mdm_supplier_his
CREATE TABLE mdm_supplier_his (
    id BIGINT NOT NULL, tenant_id BIGINT NOT NULL DEFAULT current_setting('app.tenant_id')::bigint, company_id BIGINT NOT NULL,
    supplier_id BIGINT NOT NULL, operation_type VARCHAR(16) NOT NULL,
    change_request_id BIGINT NULL, before_data JSONB NULL, after_data JSONB NULL,
    change_reason VARCHAR(1000) NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), created_by BIGINT NOT NULL DEFAULT 0,
    CONSTRAINT pk_mdm_supplier_his PRIMARY KEY (id)
);

ALTER TABLE mdm_supplier_his ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm_supplier_his FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON mdm_supplier_his
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE INDEX idx_mdm_supplier_his_supplier ON mdm_supplier_his (supplier_id, created_at DESC);
COMMENT ON COLUMN mdm_supplier_his.id IS '雪花 ID（主键）';
COMMENT ON COLUMN mdm_supplier_his.created_at IS '创建时间';

-- mdm_bank
CREATE TABLE mdm_bank (
    id BIGINT NOT NULL, tenant_id BIGINT NOT NULL DEFAULT current_setting('app.tenant_id')::bigint, company_id BIGINT NOT NULL,
    bank_code VARCHAR(16) NOT NULL,                    -- 银行行别代码（CNAPS 先頭 3 桁と同値。例 102=中国工商银行）
    bank_name VARCHAR(100) NOT NULL, bank_short_name VARCHAR(64) NULL,
    bank_category SMALLINT NULL,                       -- 銀行類別（10政策性/20国有大型/30股份制/40城商/50农商/60外资。CNAPS 行別コードとは別軸）
    status SMALLINT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), created_by BIGINT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_by BIGINT NOT NULL DEFAULT 0,
    version INT NOT NULL DEFAULT 0, deleted BOOLEAN NOT NULL DEFAULT FALSE, remark VARCHAR(500) NULL,
    CONSTRAINT pk_mdm_bank PRIMARY KEY (id)
);

ALTER TABLE mdm_bank ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm_bank FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON mdm_bank
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_mdm_bank_code ON mdm_bank (tenant_id, company_id, bank_code) WHERE deleted = FALSE;
CREATE INDEX idx_mdm_bank_name ON mdm_bank (bank_name);
COMMENT ON COLUMN mdm_bank.bank_code IS '银行行别代码（CNAPS 先頭 3 桁と同値。例 102=中国工商银行）';
COMMENT ON COLUMN mdm_bank.bank_category IS '銀行類別（10政策性/20国有大型/30股份制/40城商/50农商/60外资。CNAPS 行別コードとは別軸）';
COMMENT ON COLUMN mdm_bank.id IS '雪花 ID（主键）';
COMMENT ON COLUMN mdm_bank.created_at IS '创建时间';
COMMENT ON COLUMN mdm_bank.updated_at IS '更新时间';
COMMENT ON COLUMN mdm_bank.version IS '乐观锁版本';

-- mdm_partner_bank_account
CREATE TABLE mdm_partner_bank_account (
    id BIGINT NOT NULL, tenant_id BIGINT NOT NULL DEFAULT current_setting('app.tenant_id')::bigint, company_id BIGINT NOT NULL,
    owner_type VARCHAR(16) NOT NULL,                   -- CUSTOMER/SUPPLIER
    owner_id BIGINT NOT NULL,                          -- 客户/供应商ID
    bank_id BIGINT NOT NULL,                           -- 银行ID
    bank_branch_name VARCHAR(100) NOT NULL,            -- 支行名称
    cnaps_code VARCHAR(12) NOT NULL,                   -- 联行号（CNAPS 12位）
    account_type SMALLINT NOT NULL DEFAULT 10,         -- 10基本/20一般/30专用/40临时
    account_no VARCHAR(64) NOT NULL,                   -- 账号（暗号化推奨）
    account_name VARCHAR(100) NOT NULL,                -- 账户名
    currency_code VARCHAR(3) NOT NULL DEFAULT 'CNY',   -- 账户币种
    is_default_account BOOLEAN NOT NULL DEFAULT FALSE, -- 默认账户
    is_verified BOOLEAN NOT NULL DEFAULT FALSE,        -- 已验证
    verified_at TIMESTAMPTZ NULL, verify_method VARCHAR(32) NULL,
    change_reason VARCHAR(200) NULL,
    status SMALLINT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), created_by BIGINT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_by BIGINT NOT NULL DEFAULT 0,
    version INT NOT NULL DEFAULT 0, deleted BOOLEAN NOT NULL DEFAULT FALSE, remark VARCHAR(500) NULL,
    CONSTRAINT pk_mdm_partner_bank_account PRIMARY KEY (id),
    CONSTRAINT fk_mdm_bank_account_bank FOREIGN KEY (bank_id) REFERENCES mdm_bank (id),
    CONSTRAINT ck_mdm_bank_account_type CHECK (account_type IN (10,20,30,40))
);

ALTER TABLE mdm_partner_bank_account ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm_partner_bank_account FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON mdm_partner_bank_account
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE INDEX idx_mdm_bank_account_owner ON mdm_partner_bank_account (owner_type, owner_id, deleted);
CREATE UNIQUE INDEX uk_mdm_bank_account_owner_no ON mdm_partner_bank_account (tenant_id, company_id, owner_type, owner_id, account_no) WHERE deleted = FALSE;
COMMENT ON COLUMN mdm_partner_bank_account.owner_type IS 'CUSTOMER/SUPPLIER';
COMMENT ON COLUMN mdm_partner_bank_account.owner_id IS '客户/供应商ID';
COMMENT ON COLUMN mdm_partner_bank_account.bank_id IS '银行ID';
COMMENT ON COLUMN mdm_partner_bank_account.bank_branch_name IS '支行名称';
COMMENT ON COLUMN mdm_partner_bank_account.cnaps_code IS '联行号（CNAPS 12位）';
COMMENT ON COLUMN mdm_partner_bank_account.account_type IS '10基本/20一般/30专用/40临时';
COMMENT ON COLUMN mdm_partner_bank_account.account_no IS '账号（暗号化推奨）';
COMMENT ON COLUMN mdm_partner_bank_account.account_name IS '账户名';
COMMENT ON COLUMN mdm_partner_bank_account.currency_code IS '账户币种';
COMMENT ON COLUMN mdm_partner_bank_account.is_default_account IS '默认账户';
COMMENT ON COLUMN mdm_partner_bank_account.is_verified IS '已验证';
COMMENT ON COLUMN mdm_partner_bank_account.id IS '雪花 ID（主键）';
COMMENT ON COLUMN mdm_partner_bank_account.created_at IS '创建时间';
COMMENT ON COLUMN mdm_partner_bank_account.updated_at IS '更新时间';
COMMENT ON COLUMN mdm_partner_bank_account.version IS '乐观锁版本';

-- mdm_partner_bank_account_his
CREATE TABLE mdm_partner_bank_account_his (
    id BIGINT NOT NULL, tenant_id BIGINT NOT NULL DEFAULT current_setting('app.tenant_id')::bigint, company_id BIGINT NOT NULL,
    account_id BIGINT NOT NULL,                        -- 原账户ID
    owner_type VARCHAR(16) NOT NULL, owner_id BIGINT NOT NULL,
    before_data JSONB NULL, after_data JSONB NULL,     -- 变更前后（账号下4桁のみ保持）
    change_request_id BIGINT NULL, reason VARCHAR(500) NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), created_by BIGINT NOT NULL DEFAULT 0,
    CONSTRAINT pk_mdm_partner_bank_account_his PRIMARY KEY (id)
);

ALTER TABLE mdm_partner_bank_account_his ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm_partner_bank_account_his FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON mdm_partner_bank_account_his
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE INDEX idx_mdm_bank_account_his_account ON mdm_partner_bank_account_his (account_id, created_at DESC);

COMMENT ON COLUMN mdm_partner_bank_account_his.account_id IS '原账户ID';
COMMENT ON COLUMN mdm_partner_bank_account_his.before_data IS '变更前后（账号下4桁のみ保持）';
COMMENT ON COLUMN mdm_partner_bank_account_his.id IS '雪花 ID（主键）';
COMMENT ON COLUMN mdm_partner_bank_account_his.created_at IS '创建时间';

-- mdm_warehouse_zone
CREATE TABLE mdm_warehouse_zone (
    id BIGINT NOT NULL, tenant_id BIGINT NOT NULL DEFAULT current_setting('app.tenant_id')::bigint, company_id BIGINT NOT NULL,
    warehouse_id BIGINT NOT NULL, zone_code VARCHAR(8) NOT NULL, zone_name VARCHAR(100) NOT NULL,
    zone_type SMALLINT NOT NULL DEFAULT 10,            -- 10保管/20拣货/30入库/40出库/50待检/60冻结/70不合格/80退货
    floor_no SMALLINT NULL, area_m2 NUMERIC(18,2) NULL,
    is_picking_zone BOOLEAN NOT NULL DEFAULT FALSE, status SMALLINT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), created_by BIGINT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_by BIGINT NOT NULL DEFAULT 0,
    version INT NOT NULL DEFAULT 0, deleted BOOLEAN NOT NULL DEFAULT FALSE, remark VARCHAR(500) NULL,
    CONSTRAINT pk_mdm_warehouse_zone PRIMARY KEY (id),
    CONSTRAINT fk_mdm_warehouse_zone_warehouse FOREIGN KEY (warehouse_id) REFERENCES mdm_warehouse (id)
);

ALTER TABLE mdm_warehouse_zone ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm_warehouse_zone FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON mdm_warehouse_zone
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_mdm_warehouse_zone_code ON mdm_warehouse_zone (warehouse_id, zone_code) WHERE deleted = FALSE;
COMMENT ON COLUMN mdm_warehouse_zone.zone_type IS '10保管/20拣货/30入库/40出库/50待检/60冻结/70不合格/80退货';
COMMENT ON COLUMN mdm_warehouse_zone.id IS '雪花 ID（主键）';
COMMENT ON COLUMN mdm_warehouse_zone.created_at IS '创建时间';
COMMENT ON COLUMN mdm_warehouse_zone.updated_at IS '更新时间';
COMMENT ON COLUMN mdm_warehouse_zone.version IS '乐观锁版本';

-- mdm_warehouse_bin
CREATE TABLE mdm_warehouse_bin (
    id BIGINT NOT NULL, tenant_id BIGINT NOT NULL DEFAULT current_setting('app.tenant_id')::bigint, company_id BIGINT NOT NULL,
    warehouse_id BIGINT NOT NULL, zone_id BIGINT NOT NULL,
    bin_code VARCHAR(64) NOT NULL,                     -- 库位编码（WH01-A-01-02-03）
    bin_name VARCHAR(100) NULL,
    shelf_code VARCHAR(8) NOT NULL, level_no SMALLINT NOT NULL, position_no SMALLINT NOT NULL,
    bin_type SMALLINT NOT NULL DEFAULT 10,             -- 10保管/20拣货/30入库/40出库/50待检/60冻结/70不合格
    max_weight_kg NUMERIC(18,4) NULL, max_volume_mtq NUMERIC(18,6) NULL,
    length_mm INT NULL, width_mm INT NULL, height_mm INT NULL,
    abc_class VARCHAR(1) NULL,                         -- ABC分类
    is_mixed_material_allowed BOOLEAN NOT NULL DEFAULT FALSE,
    is_mixed_batch_allowed BOOLEAN NOT NULL DEFAULT FALSE,
    storage_condition VARCHAR(32) NULL,
    bin_barcode VARCHAR(100) NULL,                     -- 库位条码
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), created_by BIGINT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_by BIGINT NOT NULL DEFAULT 0,
    version INT NOT NULL DEFAULT 0, deleted BOOLEAN NOT NULL DEFAULT FALSE, remark VARCHAR(500) NULL,
    CONSTRAINT pk_mdm_warehouse_bin PRIMARY KEY (id),
    CONSTRAINT fk_mdm_warehouse_bin_warehouse FOREIGN KEY (warehouse_id) REFERENCES mdm_warehouse (id),
    CONSTRAINT fk_mdm_warehouse_bin_zone FOREIGN KEY (zone_id) REFERENCES mdm_warehouse_zone (id)
);

ALTER TABLE mdm_warehouse_bin ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm_warehouse_bin FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON mdm_warehouse_bin
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_mdm_warehouse_bin_code ON mdm_warehouse_bin (tenant_id, company_id, bin_code) WHERE deleted = FALSE;
CREATE INDEX idx_mdm_warehouse_bin_warehouse ON mdm_warehouse_bin (warehouse_id, zone_id, is_active);
CREATE UNIQUE INDEX uk_mdm_warehouse_bin_barcode ON mdm_warehouse_bin (tenant_id, company_id, bin_barcode) WHERE deleted = FALSE AND bin_barcode IS NOT NULL;

COMMENT ON COLUMN mdm_warehouse_bin.bin_code IS '库位编码（WH01-A-01-02-03）';
COMMENT ON COLUMN mdm_warehouse_bin.bin_type IS '10保管/20拣货/30入库/40出库/50待检/60冻结/70不合格';
COMMENT ON COLUMN mdm_warehouse_bin.abc_class IS 'ABC分类';
COMMENT ON COLUMN mdm_warehouse_bin.bin_barcode IS '库位条码';
COMMENT ON COLUMN mdm_warehouse_bin.id IS '雪花 ID（主键）';
COMMENT ON COLUMN mdm_warehouse_bin.created_at IS '创建时间';
COMMENT ON COLUMN mdm_warehouse_bin.updated_at IS '更新时间';
COMMENT ON COLUMN mdm_warehouse_bin.version IS '乐观锁版本';

-- mdm_uom_conversion
CREATE TABLE mdm_uom_conversion (
    id BIGINT NOT NULL, tenant_id BIGINT NOT NULL DEFAULT current_setting('app.tenant_id')::bigint, company_id BIGINT NOT NULL,
    conversion_group VARCHAR(16) NOT NULL, from_uom_code VARCHAR(16) NOT NULL, to_uom_code VARCHAR(16) NOT NULL,
    conversion_rate NUMERIC(18,8) NOT NULL,            -- 1 from = n to
    valid_from DATE NOT NULL, valid_to DATE NULL, status SMALLINT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), created_by BIGINT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_by BIGINT NOT NULL DEFAULT 0,
    version INT NOT NULL DEFAULT 0, deleted BOOLEAN NOT NULL DEFAULT FALSE, remark VARCHAR(500) NULL,
    CONSTRAINT pk_mdm_uom_conversion PRIMARY KEY (id),
    CONSTRAINT ck_mdm_uom_conversion_rate CHECK (conversion_rate > 0)
);

ALTER TABLE mdm_uom_conversion ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm_uom_conversion FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON mdm_uom_conversion
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE INDEX idx_mdm_uom_conversion_group ON mdm_uom_conversion (conversion_group, valid_from DESC);
COMMENT ON COLUMN mdm_uom_conversion.conversion_rate IS '1 from = n to';
COMMENT ON COLUMN mdm_uom_conversion.id IS '雪花 ID（主键）';
COMMENT ON COLUMN mdm_uom_conversion.created_at IS '创建时间';
COMMENT ON COLUMN mdm_uom_conversion.updated_at IS '更新时间';
COMMENT ON COLUMN mdm_uom_conversion.version IS '乐观锁版本';

-- mdm_currency
CREATE TABLE mdm_currency (
    id BIGINT NOT NULL, tenant_id BIGINT NOT NULL DEFAULT current_setting('app.tenant_id')::bigint, company_id BIGINT NOT NULL,
    currency_code VARCHAR(3) NOT NULL,                 -- ISO 4217
    currency_name VARCHAR(64) NOT NULL, symbol VARCHAR(8) NULL,
    decimal_places SMALLINT NOT NULL DEFAULT 2, is_base_currency BOOLEAN NOT NULL DEFAULT FALSE,
    rounding_mode VARCHAR(16) NOT NULL DEFAULT 'HALF_UP', status SMALLINT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), created_by BIGINT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_by BIGINT NOT NULL DEFAULT 0,
    version INT NOT NULL DEFAULT 0, deleted BOOLEAN NOT NULL DEFAULT FALSE, remark VARCHAR(500) NULL,
    CONSTRAINT pk_mdm_currency PRIMARY KEY (id)
);

ALTER TABLE mdm_currency ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm_currency FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON mdm_currency
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_mdm_currency_code ON mdm_currency (tenant_id, company_id, currency_code) WHERE deleted = FALSE;
CREATE UNIQUE INDEX uk_mdm_currency_base ON mdm_currency (tenant_id, company_id) WHERE is_base_currency = TRUE AND deleted = FALSE;
COMMENT ON COLUMN mdm_currency.currency_code IS 'ISO 4217';
COMMENT ON COLUMN mdm_currency.id IS '雪花 ID（主键）';
COMMENT ON COLUMN mdm_currency.created_at IS '创建时间';
COMMENT ON COLUMN mdm_currency.updated_at IS '更新时间';
COMMENT ON COLUMN mdm_currency.version IS '乐观锁版本';

-- mdm_exchange_rate
CREATE TABLE mdm_exchange_rate (
    id BIGINT NOT NULL, tenant_id BIGINT NOT NULL DEFAULT current_setting('app.tenant_id')::bigint, company_id BIGINT NOT NULL,
    from_currency_code VARCHAR(3) NOT NULL, to_currency_code VARCHAR(3) NOT NULL,
    rate_type VARCHAR(8) NOT NULL DEFAULT 'SPOT',       -- SPOT/PERIOD/AVG
    effective_date DATE NOT NULL, exchange_rate NUMERIC(18,8) NOT NULL,
    source VARCHAR(64) NULL,                           -- 来源
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), created_by BIGINT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_by BIGINT NOT NULL DEFAULT 0,
    version INT NOT NULL DEFAULT 0, deleted BOOLEAN NOT NULL DEFAULT FALSE, remark VARCHAR(500) NULL,
    CONSTRAINT pk_mdm_exchange_rate PRIMARY KEY (id),
    CONSTRAINT ck_mdm_exchange_rate_positive CHECK (exchange_rate > 0),
    CONSTRAINT ck_mdm_exchange_rate_type CHECK (rate_type IN ('SPOT','PERIOD','AVG'))
);

ALTER TABLE mdm_exchange_rate ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm_exchange_rate FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON mdm_exchange_rate
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_mdm_exchange_rate ON mdm_exchange_rate (tenant_id, from_currency_code, to_currency_code, rate_type, effective_date) WHERE deleted = FALSE;
CREATE INDEX idx_mdm_exchange_rate_pair_date ON mdm_exchange_rate (from_currency_code, to_currency_code, rate_type, effective_date DESC);
COMMENT ON COLUMN mdm_exchange_rate.rate_type IS 'SPOT/PERIOD/AVG';
COMMENT ON COLUMN mdm_exchange_rate.source IS '来源';
COMMENT ON COLUMN mdm_exchange_rate.id IS '雪花 ID（主键）';
COMMENT ON COLUMN mdm_exchange_rate.created_at IS '创建时间';
COMMENT ON COLUMN mdm_exchange_rate.updated_at IS '更新时间';
COMMENT ON COLUMN mdm_exchange_rate.version IS '乐观锁版本';

-- mdm_tax_code
CREATE TABLE mdm_tax_code (
    id BIGINT NOT NULL, tenant_id BIGINT NOT NULL DEFAULT current_setting('app.tenant_id')::bigint, company_id BIGINT NOT NULL,
    tax_code VARCHAR(32) NOT NULL,                     -- 具体税码（VAT13-OUT/VAT13-IN...）
    tax_name VARCHAR(100) NOT NULL,
    tax_rate_code VARCHAR(16) NOT NULL,                -- 06基础税率码（VAT13...）
    tax_type SMALLINT NOT NULL,                        -- 10销项/11进项/20附加/30关税/40所得税/50其他
    tax_rate NUMERIC(7,4) NOT NULL,                    -- 税率%
    is_tax_included BOOLEAN NOT NULL DEFAULT FALSE,    -- 含税标志（既定 FALSE＝税抜。税込単価は換算して保持：BR-TAX-06）
    tax_classification_code VARCHAR(32) NULL,          -- 税收分类编码
    valid_from DATE NOT NULL, valid_to DATE NULL, legal_basis VARCHAR(200) NULL,
    status SMALLINT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), created_by BIGINT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_by BIGINT NOT NULL DEFAULT 0,
    version INT NOT NULL DEFAULT 0, deleted BOOLEAN NOT NULL DEFAULT FALSE, remark VARCHAR(500) NULL,
    CONSTRAINT pk_mdm_tax_code PRIMARY KEY (id),
    CONSTRAINT ck_mdm_tax_code_type CHECK (tax_type IN (10,11,20,30,40,50))
);

ALTER TABLE mdm_tax_code ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm_tax_code FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON mdm_tax_code
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_mdm_tax_code ON mdm_tax_code (tenant_id, company_id, tax_code, valid_from) WHERE deleted = FALSE;
CREATE INDEX idx_mdm_tax_code_type ON mdm_tax_code (tax_type, status);
COMMENT ON COLUMN mdm_tax_code.tax_code IS '具体税码（VAT13-OUT/VAT13-IN...）';
COMMENT ON COLUMN mdm_tax_code.tax_rate_code IS '06基础税率码（VAT13...）';
COMMENT ON COLUMN mdm_tax_code.tax_type IS '10销项/11进项/20附加/30关税/40所得税/50其他';
COMMENT ON COLUMN mdm_tax_code.tax_rate IS '税率%';
COMMENT ON COLUMN mdm_tax_code.is_tax_included IS '含税标志（既定 FALSE＝税抜。税込単価は換算して保持：BR-TAX-06）';
COMMENT ON COLUMN mdm_tax_code.tax_classification_code IS '税收分类编码';
COMMENT ON COLUMN mdm_tax_code.id IS '雪花 ID（主键）';
COMMENT ON COLUMN mdm_tax_code.created_at IS '创建时间';
COMMENT ON COLUMN mdm_tax_code.updated_at IS '更新时间';
COMMENT ON COLUMN mdm_tax_code.version IS '乐观锁版本';

-- mdm_tax_rate
CREATE TABLE mdm_tax_rate (
    id BIGINT NOT NULL, tenant_id BIGINT NOT NULL DEFAULT current_setting('app.tenant_id')::bigint, company_id BIGINT NOT NULL,
    tax_code_id BIGINT NOT NULL, tax_rate NUMERIC(7,4) NOT NULL,
    effective_from DATE NOT NULL, effective_to DATE NULL, legal_basis VARCHAR(200) NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), created_by BIGINT NOT NULL DEFAULT 0,
    CONSTRAINT pk_mdm_tax_rate PRIMARY KEY (id),
    CONSTRAINT fk_mdm_tax_rate_code FOREIGN KEY (tax_code_id) REFERENCES mdm_tax_code (id)
);

ALTER TABLE mdm_tax_rate ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm_tax_rate FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON mdm_tax_rate
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE INDEX idx_mdm_tax_rate_code ON mdm_tax_rate (tax_code_id, effective_from DESC);
COMMENT ON COLUMN mdm_tax_rate.id IS '雪花 ID（主键）';
COMMENT ON COLUMN mdm_tax_rate.created_at IS '创建时间';

-- mdm_tax_classification
CREATE TABLE mdm_tax_classification (
    id BIGINT NOT NULL, tenant_id BIGINT NOT NULL DEFAULT current_setting('app.tenant_id')::bigint, company_id BIGINT NOT NULL,
    classification_code VARCHAR(32) NOT NULL,          -- 商品和服务税收分类编码
    classification_name VARCHAR(200) NOT NULL,
    goods_service_type SMALLINT NULL,                  -- 10货物/20服务/30无形资产/40不动产
    tax_rate_hint NUMERIC(7,4) NULL,                   -- 参考税率
    status SMALLINT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), created_by BIGINT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_by BIGINT NOT NULL DEFAULT 0,
    version INT NOT NULL DEFAULT 0, deleted BOOLEAN NOT NULL DEFAULT FALSE, remark VARCHAR(500) NULL,
    CONSTRAINT pk_mdm_tax_classification PRIMARY KEY (id)
);

ALTER TABLE mdm_tax_classification ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm_tax_classification FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON mdm_tax_classification
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_mdm_tax_classification ON mdm_tax_classification (tenant_id, company_id, classification_code) WHERE deleted = FALSE;

COMMENT ON COLUMN mdm_tax_classification.classification_code IS '商品和服务税收分类编码';
COMMENT ON COLUMN mdm_tax_classification.goods_service_type IS '10货物/20服务/30无形资产/40不动产';
COMMENT ON COLUMN mdm_tax_classification.tax_rate_hint IS '参考税率';
COMMENT ON COLUMN mdm_tax_classification.id IS '雪花 ID（主键）';
COMMENT ON COLUMN mdm_tax_classification.created_at IS '创建时间';
COMMENT ON COLUMN mdm_tax_classification.updated_at IS '更新时间';
COMMENT ON COLUMN mdm_tax_classification.version IS '乐观锁版本';

-- mdm_price_list
CREATE TABLE mdm_price_list (
    id BIGINT NOT NULL, tenant_id BIGINT NOT NULL DEFAULT current_setting('app.tenant_id')::bigint, company_id BIGINT NOT NULL,
    price_list_code VARCHAR(32) NOT NULL, price_list_name VARCHAR(100) NOT NULL,
    scope_type SMALLINT NOT NULL DEFAULT 40,           -- 10全社/20客户分类/30区域/40客户
    currency_code VARCHAR(3) NOT NULL DEFAULT 'CNY',
    is_tax_included BOOLEAN NOT NULL DEFAULT FALSE,    -- 含税标志
    price_type SMALLINT NOT NULL DEFAULT 10,           -- 10标准/20客户协议/30促销
    valid_from DATE NOT NULL, valid_to DATE NULL,
    status SMALLINT NOT NULL DEFAULT 10,               -- 10草稿/20审批中/25批准/30有效/90终止
    activated_at TIMESTAMPTZ NULL, activated_by BIGINT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), created_by BIGINT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_by BIGINT NOT NULL DEFAULT 0,
    version INT NOT NULL DEFAULT 0, deleted BOOLEAN NOT NULL DEFAULT FALSE, remark VARCHAR(500) NULL, ext_data JSONB NULL,
    CONSTRAINT pk_mdm_price_list PRIMARY KEY (id)
);

ALTER TABLE mdm_price_list ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm_price_list FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON mdm_price_list
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_mdm_price_list_code ON mdm_price_list (tenant_id, company_id, price_list_code) WHERE deleted = FALSE;
CREATE INDEX idx_mdm_price_list_status_date ON mdm_price_list (status, valid_from, valid_to);
COMMENT ON COLUMN mdm_price_list.scope_type IS '10全社/20客户分类/30区域/40客户';
COMMENT ON COLUMN mdm_price_list.is_tax_included IS '含税标志';
COMMENT ON COLUMN mdm_price_list.price_type IS '10标准/20客户协议/30促销';
COMMENT ON COLUMN mdm_price_list.status IS '10草稿/20审批中/25批准/30有效/90终止';
COMMENT ON COLUMN mdm_price_list.id IS '雪花 ID（主键）';
COMMENT ON COLUMN mdm_price_list.created_at IS '创建时间';
COMMENT ON COLUMN mdm_price_list.updated_at IS '更新时间';
COMMENT ON COLUMN mdm_price_list.version IS '乐观锁版本';

-- mdm_price_list_line
CREATE TABLE mdm_price_list_line (
    id BIGINT NOT NULL, tenant_id BIGINT NOT NULL DEFAULT current_setting('app.tenant_id')::bigint, company_id BIGINT NOT NULL,
    price_list_id BIGINT NOT NULL, line_no INT NOT NULL,
    scope_type SMALLINT NOT NULL,                      -- 10客户+物料/20客户分类+物料/30物料/40全社标准
    customer_id BIGINT NULL, customer_category_code VARCHAR(32) NULL,
    material_id BIGINT NULL, material_category_id BIGINT NULL,
    min_qty NUMERIC(18,4) NOT NULL DEFAULT 1, max_qty NUMERIC(18,4) NULL,
    unit_price NUMERIC(18,6) NOT NULL,
    currency_code VARCHAR(3) NOT NULL DEFAULT 'CNY',
    tax_code VARCHAR(32) NOT NULL,
    is_tax_included BOOLEAN NOT NULL DEFAULT FALSE,
    discount_rate NUMERIC(7,4) NULL,                   -- 行折扣率%
    priority INT NOT NULL DEFAULT 100,                 -- 优先级（小优先）
    valid_from DATE NOT NULL, valid_to DATE NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), created_by BIGINT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_by BIGINT NOT NULL DEFAULT 0,
    version INT NOT NULL DEFAULT 0, deleted BOOLEAN NOT NULL DEFAULT FALSE, remark VARCHAR(500) NULL,
    CONSTRAINT pk_mdm_price_list_line PRIMARY KEY (id),
    CONSTRAINT fk_mdm_price_line_list FOREIGN KEY (price_list_id) REFERENCES mdm_price_list (id),
    CONSTRAINT ck_mdm_price_line_qty CHECK (min_qty >= 0 AND (max_qty IS NULL OR max_qty > min_qty)),
    CONSTRAINT ck_mdm_price_line_scope CHECK (
        (scope_type = 10 AND customer_id IS NOT NULL AND material_id IS NOT NULL) OR
        (scope_type = 20 AND customer_category_code IS NOT NULL AND material_id IS NOT NULL) OR
        (scope_type = 30 AND material_id IS NOT NULL) OR (scope_type = 40))
);

ALTER TABLE mdm_price_list_line ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm_price_list_line FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON mdm_price_list_line
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_mdm_price_line_no ON mdm_price_list_line (price_list_id, line_no) WHERE deleted = FALSE;
CREATE INDEX idx_mdm_price_line_lookup ON mdm_price_list_line (scope_type, customer_id, material_id, min_qty, valid_from);
CREATE INDEX idx_mdm_price_line_material ON mdm_price_list_line (material_id, valid_from DESC);
COMMENT ON COLUMN mdm_price_list_line.scope_type IS '10客户+物料/20客户分类+物料/30物料/40全社标准';
COMMENT ON COLUMN mdm_price_list_line.discount_rate IS '行折扣率%';
COMMENT ON COLUMN mdm_price_list_line.priority IS '优先级（小优先）';
COMMENT ON COLUMN mdm_price_list_line.id IS '雪花 ID（主键）';
COMMENT ON COLUMN mdm_price_list_line.created_at IS '创建时间';
COMMENT ON COLUMN mdm_price_list_line.updated_at IS '更新时间';
COMMENT ON COLUMN mdm_price_list_line.version IS '乐观锁版本';

-- mdm_price_discount
CREATE TABLE mdm_price_discount (
    id BIGINT NOT NULL, tenant_id BIGINT NOT NULL DEFAULT current_setting('app.tenant_id')::bigint, company_id BIGINT NOT NULL,
    discount_code VARCHAR(32) NOT NULL, discount_name VARCHAR(100) NOT NULL,
    apply_scope SMALLINT NOT NULL,                     -- 10客户/20客户分类/30物料/40全社
    customer_id BIGINT NULL, customer_category_code VARCHAR(32) NULL, material_id BIGINT NULL,
    condition_type SMALLINT NOT NULL,                  -- 10金额/20数量/30等级
    min_amount NUMERIC(18,2) NULL, min_qty NUMERIC(18,4) NULL,
    discount_type SMALLINT NOT NULL,                   -- 10率/20额
    discount_value NUMERIC(18,6) NOT NULL,
    priority INT NOT NULL DEFAULT 100,
    valid_from DATE NOT NULL, valid_to DATE NULL, status SMALLINT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), created_by BIGINT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_by BIGINT NOT NULL DEFAULT 0,
    version INT NOT NULL DEFAULT 0, deleted BOOLEAN NOT NULL DEFAULT FALSE, remark VARCHAR(500) NULL,
    CONSTRAINT pk_mdm_price_discount PRIMARY KEY (id)
);

ALTER TABLE mdm_price_discount ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm_price_discount FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON mdm_price_discount
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_mdm_price_discount_code ON mdm_price_discount (tenant_id, company_id, discount_code) WHERE deleted = FALSE;
COMMENT ON COLUMN mdm_price_discount.apply_scope IS '10客户/20客户分类/30物料/40全社';
COMMENT ON COLUMN mdm_price_discount.condition_type IS '10金额/20数量/30等级';
COMMENT ON COLUMN mdm_price_discount.discount_type IS '10率/20额';
COMMENT ON COLUMN mdm_price_discount.id IS '雪花 ID（主键）';
COMMENT ON COLUMN mdm_price_discount.created_at IS '创建时间';
COMMENT ON COLUMN mdm_price_discount.updated_at IS '更新时间';
COMMENT ON COLUMN mdm_price_discount.version IS '乐观锁版本';

-- mdm_purchase_price
CREATE TABLE mdm_purchase_price (
    id BIGINT NOT NULL, tenant_id BIGINT NOT NULL DEFAULT current_setting('app.tenant_id')::bigint, company_id BIGINT NOT NULL,
    supplier_id BIGINT NOT NULL, material_id BIGINT NOT NULL,
    scope_type SMALLINT NOT NULL DEFAULT 10,           -- 10供应商+物料/20供应商分类+物料/30物料标准
    supplier_category VARCHAR(32) NULL,
    min_qty NUMERIC(18,4) NOT NULL DEFAULT 1, max_qty NUMERIC(18,4) NULL,
    unit_price NUMERIC(18,6) NOT NULL, currency_code VARCHAR(3) NOT NULL DEFAULT 'CNY',
    price_includes_tax BOOLEAN NOT NULL DEFAULT TRUE, tax_code VARCHAR(32) NOT NULL,
    moq NUMERIC(18,4) NULL, lead_time_days INT NULL,
    valid_from DATE NOT NULL, valid_to DATE NULL, status SMALLINT NOT NULL DEFAULT 10,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), created_by BIGINT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_by BIGINT NOT NULL DEFAULT 0,
    version INT NOT NULL DEFAULT 0, deleted BOOLEAN NOT NULL DEFAULT FALSE, remark VARCHAR(500) NULL,
    CONSTRAINT pk_mdm_purchase_price PRIMARY KEY (id),
    CONSTRAINT fk_mdm_purchase_price_supplier FOREIGN KEY (supplier_id) REFERENCES mdm_supplier (id),
    CONSTRAINT fk_mdm_purchase_price_material FOREIGN KEY (material_id) REFERENCES mdm_material (id)
);

ALTER TABLE mdm_purchase_price ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm_purchase_price FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON mdm_purchase_price
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE INDEX idx_mdm_purchase_price_lookup ON mdm_purchase_price (supplier_id, material_id, min_qty, valid_from);
CREATE INDEX idx_mdm_purchase_price_material ON mdm_purchase_price (material_id, status);
COMMENT ON COLUMN mdm_purchase_price.scope_type IS '10供应商+物料/20供应商分类+物料/30物料标准';
COMMENT ON COLUMN mdm_purchase_price.id IS '雪花 ID（主键）';
COMMENT ON COLUMN mdm_purchase_price.created_at IS '创建时间';
COMMENT ON COLUMN mdm_purchase_price.updated_at IS '更新时间';
COMMENT ON COLUMN mdm_purchase_price.version IS '乐观锁版本';

-- mdm_supplier_quotation
CREATE TABLE mdm_supplier_quotation (
    id BIGINT NOT NULL, tenant_id BIGINT NOT NULL DEFAULT current_setting('app.tenant_id')::bigint, company_id BIGINT NOT NULL,
    quotation_no VARCHAR(32) NOT NULL, supplier_id BIGINT NOT NULL, rfq_no VARCHAR(32) NULL,
    quotation_date DATE NOT NULL, valid_from DATE NOT NULL, valid_to DATE NOT NULL,
    currency_code VARCHAR(3) NOT NULL DEFAULT 'CNY', payment_term_code VARCHAR(32) NULL,
    delivery_terms VARCHAR(100) NULL, total_amount NUMERIC(18,2) NULL,
    status SMALLINT NOT NULL DEFAULT 10,               -- 10登记/20比价中/30采用/90无效
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), created_by BIGINT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_by BIGINT NOT NULL DEFAULT 0,
    version INT NOT NULL DEFAULT 0, deleted BOOLEAN NOT NULL DEFAULT FALSE, remark VARCHAR(500) NULL,
    CONSTRAINT pk_mdm_supplier_quotation PRIMARY KEY (id),
    CONSTRAINT fk_mdm_quotation_supplier FOREIGN KEY (supplier_id) REFERENCES mdm_supplier (id)
);

ALTER TABLE mdm_supplier_quotation ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm_supplier_quotation FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON mdm_supplier_quotation
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_mdm_quotation_no ON mdm_supplier_quotation (tenant_id, company_id, quotation_no) WHERE deleted = FALSE;
CREATE INDEX idx_mdm_quotation_supplier ON mdm_supplier_quotation (supplier_id, quotation_date DESC);
COMMENT ON COLUMN mdm_supplier_quotation.status IS '10登记/20比价中/30采用/90无效';
COMMENT ON COLUMN mdm_supplier_quotation.id IS '雪花 ID（主键）';
COMMENT ON COLUMN mdm_supplier_quotation.created_at IS '创建时间';
COMMENT ON COLUMN mdm_supplier_quotation.updated_at IS '更新时间';
COMMENT ON COLUMN mdm_supplier_quotation.version IS '乐观锁版本';

-- mdm_supplier_quotation_line
CREATE TABLE mdm_supplier_quotation_line (
    id BIGINT NOT NULL, tenant_id BIGINT NOT NULL DEFAULT current_setting('app.tenant_id')::bigint, company_id BIGINT NOT NULL,
    quotation_id BIGINT NOT NULL, line_no INT NOT NULL, material_id BIGINT NOT NULL,
    quantity NUMERIC(18,4) NULL, uom_code VARCHAR(16) NULL,
    unit_price NUMERIC(18,6) NOT NULL, currency_code VARCHAR(3) NOT NULL DEFAULT 'CNY',
    tax_code VARCHAR(32) NULL, moq NUMERIC(18,4) NULL, lead_time_days INT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), created_by BIGINT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_by BIGINT NOT NULL DEFAULT 0,
    version INT NOT NULL DEFAULT 0, deleted BOOLEAN NOT NULL DEFAULT FALSE, remark VARCHAR(500) NULL,
    CONSTRAINT pk_mdm_supplier_quotation_line PRIMARY KEY (id),
    CONSTRAINT fk_mdm_quotation_line_quotation FOREIGN KEY (quotation_id) REFERENCES mdm_supplier_quotation (id),
    CONSTRAINT fk_mdm_quotation_line_material FOREIGN KEY (material_id) REFERENCES mdm_material (id)
);

ALTER TABLE mdm_supplier_quotation_line ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm_supplier_quotation_line FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON mdm_supplier_quotation_line
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_mdm_quotation_line_no ON mdm_supplier_quotation_line (quotation_id, line_no) WHERE deleted = FALSE;
COMMENT ON COLUMN mdm_supplier_quotation_line.id IS '雪花 ID（主键）';
COMMENT ON COLUMN mdm_supplier_quotation_line.created_at IS '创建时间';
COMMENT ON COLUMN mdm_supplier_quotation_line.updated_at IS '更新时间';
COMMENT ON COLUMN mdm_supplier_quotation_line.version IS '乐观锁版本';

-- mdm_settlement_method
CREATE TABLE mdm_settlement_method (
    id BIGINT NOT NULL, tenant_id BIGINT NOT NULL DEFAULT current_setting('app.tenant_id')::bigint, company_id BIGINT NOT NULL,
    settlement_method_code VARCHAR(32) NOT NULL,       -- 06 §8.1（BANK_TRANSFER...）
    settlement_method_name VARCHAR(100) NOT NULL,
    settlement_type SMALLINT NOT NULL,                 -- 10现金/20转账/30票据/40信用证/50其他
    description VARCHAR(200) NULL, is_default BOOLEAN NOT NULL DEFAULT FALSE,
    status SMALLINT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), created_by BIGINT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_by BIGINT NOT NULL DEFAULT 0,
    version INT NOT NULL DEFAULT 0, deleted BOOLEAN NOT NULL DEFAULT FALSE, remark VARCHAR(500) NULL,
    CONSTRAINT pk_mdm_settlement_method PRIMARY KEY (id)
);

ALTER TABLE mdm_settlement_method ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm_settlement_method FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON mdm_settlement_method
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_mdm_settlement_code ON mdm_settlement_method (tenant_id, company_id, settlement_method_code) WHERE deleted = FALSE;
COMMENT ON COLUMN mdm_settlement_method.settlement_method_code IS '06 §8.1（BANK_TRANSFER...）';
COMMENT ON COLUMN mdm_settlement_method.settlement_type IS '10现金/20转账/30票据/40信用证/50其他';
COMMENT ON COLUMN mdm_settlement_method.id IS '雪花 ID（主键）';
COMMENT ON COLUMN mdm_settlement_method.created_at IS '创建时间';
COMMENT ON COLUMN mdm_settlement_method.updated_at IS '更新时间';
COMMENT ON COLUMN mdm_settlement_method.version IS '乐观锁版本';

-- mdm_payment_term
CREATE TABLE mdm_payment_term (
    id BIGINT NOT NULL, tenant_id BIGINT NOT NULL DEFAULT current_setting('app.tenant_id')::bigint, company_id BIGINT NOT NULL,
    payment_term_code VARCHAR(32) NOT NULL,            -- 06 §8.2（NET30...）
    payment_term_name VARCHAR(100) NOT NULL,
    settlement_basis SMALLINT NOT NULL DEFAULT 40,     -- 10发票日/20验收日/30发货日/40月末/50订单日
    net_days INT NOT NULL DEFAULT 30,
    payment_day_type SMALLINT NOT NULL DEFAULT 20,     -- 10月末/20次月末/30再次月末/40固定日/50即时
    fixed_payment_day SMALLINT NULL,
    installment_count SMALLINT NOT NULL DEFAULT 1,
    valid_from DATE NOT NULL, valid_to DATE NULL, status SMALLINT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), created_by BIGINT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_by BIGINT NOT NULL DEFAULT 0,
    version INT NOT NULL DEFAULT 0, deleted BOOLEAN NOT NULL DEFAULT FALSE, remark VARCHAR(500) NULL,
    CONSTRAINT pk_mdm_payment_term PRIMARY KEY (id)
);

ALTER TABLE mdm_payment_term ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm_payment_term FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON mdm_payment_term
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_mdm_payment_term_code ON mdm_payment_term (tenant_id, company_id, payment_term_code) WHERE deleted = FALSE;
COMMENT ON COLUMN mdm_payment_term.payment_term_code IS '06 §8.2（NET30...）';
COMMENT ON COLUMN mdm_payment_term.settlement_basis IS '10发票日/20验收日/30发货日/40月末/50订单日';
COMMENT ON COLUMN mdm_payment_term.payment_day_type IS '10月末/20次月末/30再次月末/40固定日/50即时';
COMMENT ON COLUMN mdm_payment_term.id IS '雪花 ID（主键）';
COMMENT ON COLUMN mdm_payment_term.created_at IS '创建时间';
COMMENT ON COLUMN mdm_payment_term.updated_at IS '更新时间';
COMMENT ON COLUMN mdm_payment_term.version IS '乐观锁版本';

-- mdm_payment_term_line
CREATE TABLE mdm_payment_term_line (
    id BIGINT NOT NULL, tenant_id BIGINT NOT NULL DEFAULT current_setting('app.tenant_id')::bigint, company_id BIGINT NOT NULL,
    payment_term_id BIGINT NOT NULL, seq_no SMALLINT NOT NULL,
    installment_ratio NUMERIC(7,4) NOT NULL,           -- 分期比率%（合计100）
    due_type SMALLINT NOT NULL,                        -- 10固定日/20相对日
    trigger_event SMALLINT NOT NULL,                   -- 10订单/20验收/30发货/40发票
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), created_by BIGINT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_by BIGINT NOT NULL DEFAULT 0,
    version INT NOT NULL DEFAULT 0, deleted BOOLEAN NOT NULL DEFAULT FALSE, remark VARCHAR(500) NULL,
    CONSTRAINT pk_mdm_payment_term_line PRIMARY KEY (id),
    CONSTRAINT fk_mdm_payment_term_line_term FOREIGN KEY (payment_term_id) REFERENCES mdm_payment_term (id)
);

ALTER TABLE mdm_payment_term_line ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm_payment_term_line FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON mdm_payment_term_line
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_mdm_payment_term_line ON mdm_payment_term_line (payment_term_id, seq_no) WHERE deleted = FALSE;
COMMENT ON COLUMN mdm_payment_term_line.installment_ratio IS '分期比率%（合计100）';
COMMENT ON COLUMN mdm_payment_term_line.due_type IS '10固定日/20相对日';
COMMENT ON COLUMN mdm_payment_term_line.trigger_event IS '10订单/20验收/30发货/40发票';
COMMENT ON COLUMN mdm_payment_term_line.id IS '雪花 ID（主键）';
COMMENT ON COLUMN mdm_payment_term_line.created_at IS '创建时间';
COMMENT ON COLUMN mdm_payment_term_line.updated_at IS '更新时间';
COMMENT ON COLUMN mdm_payment_term_line.version IS '乐观锁版本';

-- mdm_credit_check_rule
CREATE TABLE mdm_credit_check_rule (
    id BIGINT NOT NULL, tenant_id BIGINT NOT NULL DEFAULT current_setting('app.tenant_id')::bigint, company_id BIGINT NOT NULL,
    rule_code VARCHAR(32) NOT NULL, rule_name VARCHAR(100) NOT NULL,
    check_timing JSONB NOT NULL,                       -- [10,30] 检查时点
    exposure_scope JSONB NOT NULL,                     -- [10,20,30] 占用范围
    include_open_orders BOOLEAN NOT NULL DEFAULT TRUE,
    over_limit_ratio NUMERIC(7,4) NOT NULL DEFAULT 0,
    overflow_action SMALLINT NOT NULL DEFAULT 30,      -- 10阻断/20警告/30审批
    status SMALLINT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), created_by BIGINT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_by BIGINT NOT NULL DEFAULT 0,
    version INT NOT NULL DEFAULT 0, deleted BOOLEAN NOT NULL DEFAULT FALSE, remark VARCHAR(500) NULL,
    CONSTRAINT pk_mdm_credit_check_rule PRIMARY KEY (id)
);

ALTER TABLE mdm_credit_check_rule ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm_credit_check_rule FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON mdm_credit_check_rule
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_mdm_credit_check_rule ON mdm_credit_check_rule (tenant_id, company_id, rule_code) WHERE deleted = FALSE;
COMMENT ON COLUMN mdm_credit_check_rule.check_timing IS '[10,30] 检查时点';
COMMENT ON COLUMN mdm_credit_check_rule.exposure_scope IS '[10,20,30] 占用范围';
COMMENT ON COLUMN mdm_credit_check_rule.overflow_action IS '10阻断/20警告/30审批';
COMMENT ON COLUMN mdm_credit_check_rule.id IS '雪花 ID（主键）';
COMMENT ON COLUMN mdm_credit_check_rule.created_at IS '创建时间';
COMMENT ON COLUMN mdm_credit_check_rule.updated_at IS '更新时间';
COMMENT ON COLUMN mdm_credit_check_rule.version IS '乐观锁版本';

-- mdm_credit_limit
CREATE TABLE mdm_credit_limit (
    id BIGINT NOT NULL, tenant_id BIGINT NOT NULL DEFAULT current_setting('app.tenant_id')::bigint, company_id BIGINT NOT NULL,
    customer_id BIGINT NOT NULL,                       -- 客户ID（1客户1有效记录）
    currency_code VARCHAR(3) NOT NULL DEFAULT 'CNY',
    credit_limit_amount NUMERIC(18,2) NOT NULL DEFAULT 0,     -- 信用额度
    single_order_limit_amount NUMERIC(18,2) NULL,             -- 单笔上限（0/空=无限）
    over_limit_ratio NUMERIC(7,4) NOT NULL DEFAULT 0,         -- 超限容许率%
    check_rule_id BIGINT NOT NULL,                     -- 检查规则
    credit_status SMALLINT NOT NULL DEFAULT 10,        -- 10正常/20超限/30冻结/40关闭
    valid_from DATE NOT NULL, valid_to DATE NULL,
    credit_remark VARCHAR(500) NULL, last_review_date DATE NULL,
    approval_status SMALLINT NOT NULL DEFAULT 10,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), created_by BIGINT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_by BIGINT NOT NULL DEFAULT 0,
    version INT NOT NULL DEFAULT 0, deleted BOOLEAN NOT NULL DEFAULT FALSE, remark VARCHAR(500) NULL,
    CONSTRAINT pk_mdm_credit_limit PRIMARY KEY (id),
    CONSTRAINT fk_mdm_credit_limit_customer FOREIGN KEY (customer_id) REFERENCES mdm_customer (id),
    CONSTRAINT fk_mdm_credit_limit_rule FOREIGN KEY (check_rule_id) REFERENCES mdm_credit_check_rule (id)
);

ALTER TABLE mdm_credit_limit ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm_credit_limit FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON mdm_credit_limit
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE INDEX idx_mdm_credit_limit_customer ON mdm_credit_limit (customer_id, valid_from DESC);
CREATE INDEX idx_mdm_credit_limit_status ON mdm_credit_limit (credit_status);
COMMENT ON COLUMN mdm_credit_limit.customer_id IS '客户ID（1客户1有效记录）';
COMMENT ON COLUMN mdm_credit_limit.credit_limit_amount IS '信用额度';
COMMENT ON COLUMN mdm_credit_limit.single_order_limit_amount IS '单笔上限（0/空=无限）';
COMMENT ON COLUMN mdm_credit_limit.over_limit_ratio IS '超限容许率%';
COMMENT ON COLUMN mdm_credit_limit.check_rule_id IS '检查规则';
COMMENT ON COLUMN mdm_credit_limit.credit_status IS '10正常/20超限/30冻结/40关闭';
COMMENT ON COLUMN mdm_credit_limit.id IS '雪花 ID（主键）';
COMMENT ON COLUMN mdm_credit_limit.created_at IS '创建时间';
COMMENT ON COLUMN mdm_credit_limit.updated_at IS '更新时间';
COMMENT ON COLUMN mdm_credit_limit.version IS '乐观锁版本';

-- mdm_credit_limit_his
CREATE TABLE mdm_credit_limit_his (
    id BIGINT NOT NULL, tenant_id BIGINT NOT NULL DEFAULT current_setting('app.tenant_id')::bigint, company_id BIGINT NOT NULL,
    credit_limit_id BIGINT NOT NULL, customer_id BIGINT NOT NULL,
    before_data JSONB NULL, after_data JSONB NULL, change_request_id BIGINT NULL,
    change_reason VARCHAR(1000) NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), created_by BIGINT NOT NULL DEFAULT 0,
    CONSTRAINT pk_mdm_credit_limit_his PRIMARY KEY (id)
);

ALTER TABLE mdm_credit_limit_his ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm_credit_limit_his FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON mdm_credit_limit_his
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE INDEX idx_mdm_credit_limit_his_customer ON mdm_credit_limit_his (customer_id, created_at DESC);
COMMENT ON COLUMN mdm_credit_limit_his.id IS '雪花 ID（主键）';
COMMENT ON COLUMN mdm_credit_limit_his.created_at IS '创建时间';

-- mdm_supplier_admission
CREATE TABLE mdm_supplier_admission (
    id BIGINT NOT NULL, tenant_id BIGINT NOT NULL DEFAULT current_setting('app.tenant_id')::bigint, company_id BIGINT NOT NULL,
    admission_no VARCHAR(32) NOT NULL, supplier_id BIGINT NOT NULL,
    apply_date DATE NOT NULL, apply_type SMALLINT NOT NULL DEFAULT 10, -- 10新规/20再准入/30范围扩大
    reviewer_id BIGINT NULL, review_result SMALLINT NULL, -- 10通过/20驳回
    review_comment VARCHAR(500) NULL, approved_by BIGINT NULL, approved_at TIMESTAMPTZ NULL,
    status SMALLINT NOT NULL DEFAULT 10,               -- 10申请/20审查中/30通过/40驳回
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), created_by BIGINT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_by BIGINT NOT NULL DEFAULT 0,
    version INT NOT NULL DEFAULT 0, deleted BOOLEAN NOT NULL DEFAULT FALSE, remark VARCHAR(500) NULL,
    CONSTRAINT pk_mdm_supplier_admission PRIMARY KEY (id),
    CONSTRAINT fk_mdm_admission_supplier FOREIGN KEY (supplier_id) REFERENCES mdm_supplier (id)
);

ALTER TABLE mdm_supplier_admission ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm_supplier_admission FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON mdm_supplier_admission
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_mdm_admission_no ON mdm_supplier_admission (tenant_id, company_id, admission_no) WHERE deleted = FALSE;
COMMENT ON COLUMN mdm_supplier_admission.apply_date IS '10新规/20再准入/30范围扩大';
COMMENT ON COLUMN mdm_supplier_admission.reviewer_id IS '10通过/20驳回';
COMMENT ON COLUMN mdm_supplier_admission.status IS '10申请/20审查中/30通过/40驳回';
COMMENT ON COLUMN mdm_supplier_admission.id IS '雪花 ID（主键）';
COMMENT ON COLUMN mdm_supplier_admission.created_at IS '创建时间';
COMMENT ON COLUMN mdm_supplier_admission.updated_at IS '更新时间';
COMMENT ON COLUMN mdm_supplier_admission.version IS '乐观锁版本';

-- mdm_supplier_evaluation
CREATE TABLE mdm_supplier_evaluation (
    id BIGINT NOT NULL, tenant_id BIGINT NOT NULL DEFAULT current_setting('app.tenant_id')::bigint, company_id BIGINT NOT NULL,
    supplier_id BIGINT NOT NULL, evaluation_period VARCHAR(7) NOT NULL, -- YYYY-MM
    quality_score NUMERIC(5,2) NULL, delivery_score NUMERIC(5,2) NULL,
    price_score NUMERIC(5,2) NULL, service_score NUMERIC(5,2) NULL, technology_score NUMERIC(5,2) NULL,
    total_score NUMERIC(5,2) NULL, supplier_grade VARCHAR(1) NULL,
    eval_source SMALLINT NOT NULL DEFAULT 10,          -- 10自动/20手动/30混在
    eval_status SMALLINT NOT NULL DEFAULT 10,          -- 10计算/20待确认/30确定
    evaluator_comment VARCHAR(500) NULL,
    calculated_at TIMESTAMPTZ NULL, confirmed_at TIMESTAMPTZ NULL, confirmed_by BIGINT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), created_by BIGINT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_by BIGINT NOT NULL DEFAULT 0,
    version INT NOT NULL DEFAULT 0, deleted BOOLEAN NOT NULL DEFAULT FALSE, remark VARCHAR(500) NULL,
    CONSTRAINT pk_mdm_supplier_evaluation PRIMARY KEY (id),
    CONSTRAINT fk_mdm_evaluation_supplier FOREIGN KEY (supplier_id) REFERENCES mdm_supplier (id)
);

ALTER TABLE mdm_supplier_evaluation ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm_supplier_evaluation FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON mdm_supplier_evaluation
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_mdm_evaluation ON mdm_supplier_evaluation (supplier_id, evaluation_period) WHERE deleted = FALSE;

CREATE INDEX idx_mdm_evaluation_period ON mdm_supplier_evaluation (evaluation_period, total_score DESC);
COMMENT ON COLUMN mdm_supplier_evaluation.supplier_id IS 'YYYY-MM';
COMMENT ON COLUMN mdm_supplier_evaluation.eval_source IS '10自动/20手动/30混在';
COMMENT ON COLUMN mdm_supplier_evaluation.eval_status IS '10计算/20待确认/30确定';
COMMENT ON COLUMN mdm_supplier_evaluation.id IS '雪花 ID（主键）';
COMMENT ON COLUMN mdm_supplier_evaluation.created_at IS '创建时间';
COMMENT ON COLUMN mdm_supplier_evaluation.updated_at IS '更新时间';
COMMENT ON COLUMN mdm_supplier_evaluation.version IS '乐观锁版本';

-- mdm_supplier_eval_item
CREATE TABLE mdm_supplier_eval_item (
    id BIGINT NOT NULL, tenant_id BIGINT NOT NULL DEFAULT current_setting('app.tenant_id')::bigint, company_id BIGINT NOT NULL,
    evaluation_id BIGINT NOT NULL, dimension_code VARCHAR(32) NOT NULL, -- QUALITY/DELIVERY/PRICE/SERVICE/TECH
    score NUMERIC(5,2) NOT NULL, weight NUMERIC(7,4) NOT NULL,
    data_source SMALLINT NOT NULL DEFAULT 10,          -- 10系统/20手动
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), created_by BIGINT NOT NULL DEFAULT 0,
    CONSTRAINT pk_mdm_supplier_eval_item PRIMARY KEY (id),
    CONSTRAINT fk_mdm_eval_item_evaluation FOREIGN KEY (evaluation_id) REFERENCES mdm_supplier_evaluation (id)
);

ALTER TABLE mdm_supplier_eval_item ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm_supplier_eval_item FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON mdm_supplier_eval_item
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_mdm_eval_item ON mdm_supplier_eval_item (evaluation_id, dimension_code);
COMMENT ON COLUMN mdm_supplier_eval_item.evaluation_id IS 'QUALITY/DELIVERY/PRICE/SERVICE/TECH';
COMMENT ON COLUMN mdm_supplier_eval_item.data_source IS '10系统/20手动';
COMMENT ON COLUMN mdm_supplier_eval_item.id IS '雪花 ID（主键）';
COMMENT ON COLUMN mdm_supplier_eval_item.created_at IS '创建时间';

-- mdm_barcode_rule
CREATE TABLE mdm_barcode_rule (
    id BIGINT NOT NULL, tenant_id BIGINT NOT NULL DEFAULT current_setting('app.tenant_id')::bigint, company_id BIGINT NOT NULL,
    rule_code VARCHAR(32) NOT NULL, rule_name VARCHAR(100) NOT NULL,
    target_type SMALLINT NOT NULL,                     -- 10物料/20批次/30库位/40包装箱/50序列号
    barcode_type SMALLINT NOT NULL DEFAULT 10,         -- 10Code128/20GS1-128/30QR
    content_pattern VARCHAR(200) NOT NULL,             -- 内容模板
    check_digit_type SMALLINT NOT NULL DEFAULT 10,     -- 10Mod103/20GS1/30无
    label_template_id BIGINT NULL, printer_type SMALLINT NULL,
    is_default BOOLEAN NOT NULL DEFAULT FALSE, status SMALLINT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), created_by BIGINT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_by BIGINT NOT NULL DEFAULT 0,
    version INT NOT NULL DEFAULT 0, deleted BOOLEAN NOT NULL DEFAULT FALSE, remark VARCHAR(500) NULL,
    CONSTRAINT pk_mdm_barcode_rule PRIMARY KEY (id)
);

ALTER TABLE mdm_barcode_rule ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm_barcode_rule FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON mdm_barcode_rule
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_mdm_barcode_rule ON mdm_barcode_rule (tenant_id, company_id, rule_code) WHERE deleted = FALSE;
COMMENT ON COLUMN mdm_barcode_rule.target_type IS '10物料/20批次/30库位/40包装箱/50序列号';
COMMENT ON COLUMN mdm_barcode_rule.barcode_type IS '10Code128/20GS1-128/30QR';
COMMENT ON COLUMN mdm_barcode_rule.content_pattern IS '内容模板';
COMMENT ON COLUMN mdm_barcode_rule.check_digit_type IS '10Mod103/20GS1/30无';
COMMENT ON COLUMN mdm_barcode_rule.id IS '雪花 ID（主键）';
COMMENT ON COLUMN mdm_barcode_rule.created_at IS '创建时间';
COMMENT ON COLUMN mdm_barcode_rule.updated_at IS '更新时间';
COMMENT ON COLUMN mdm_barcode_rule.version IS '乐观锁版本';

-- mdm_change_request
CREATE TABLE mdm_change_request (
    id BIGINT NOT NULL, tenant_id BIGINT NOT NULL DEFAULT current_setting('app.tenant_id')::bigint, company_id BIGINT NOT NULL,
    request_no VARCHAR(32) NOT NULL,                   -- CR2610200001
    object_type VARCHAR(32) NOT NULL,                  -- MATERIAL/CUSTOMER/SUPPLIER/PRICE/CREDIT...
    object_id BIGINT NOT NULL, object_code VARCHAR(64) NULL,
    change_type SMALLINT NOT NULL DEFAULT 10,          -- 10一般/20关键
    reason VARCHAR(500) NOT NULL, base_version INT NOT NULL,
    status SMALLINT NOT NULL DEFAULT 10,               -- 10草稿/20审批中/25批准/30反映/90取消/95驳回
    applicant_id BIGINT NOT NULL, submitted_at TIMESTAMPTZ NULL,
    approved_by BIGINT NULL, approved_at TIMESTAMPTZ NULL, approval_comment VARCHAR(500) NULL,
    applied_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), created_by BIGINT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_by BIGINT NOT NULL DEFAULT 0,
    version INT NOT NULL DEFAULT 0, deleted BOOLEAN NOT NULL DEFAULT FALSE, remark VARCHAR(500) NULL,
    CONSTRAINT pk_mdm_change_request PRIMARY KEY (id)
);

ALTER TABLE mdm_change_request ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm_change_request FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON mdm_change_request
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_mdm_change_request_no ON mdm_change_request (tenant_id, company_id, request_no) WHERE deleted = FALSE;
CREATE INDEX idx_mdm_change_request_object ON mdm_change_request (object_type, object_id, status);
CREATE INDEX idx_mdm_change_request_status ON mdm_change_request (status, submitted_at);
COMMENT ON COLUMN mdm_change_request.request_no IS 'CR2610200001';
COMMENT ON COLUMN mdm_change_request.object_type IS 'MATERIAL/CUSTOMER/SUPPLIER/PRICE/CREDIT...';
COMMENT ON COLUMN mdm_change_request.change_type IS '10一般/20关键';
COMMENT ON COLUMN mdm_change_request.status IS '10草稿/20审批中/25批准/30反映/90取消/95驳回';
COMMENT ON COLUMN mdm_change_request.id IS '雪花 ID（主键）';
COMMENT ON COLUMN mdm_change_request.created_at IS '创建时间';
COMMENT ON COLUMN mdm_change_request.updated_at IS '更新时间';
COMMENT ON COLUMN mdm_change_request.version IS '乐观锁版本';

-- mdm_change_request_line
CREATE TABLE mdm_change_request_line (
    id BIGINT NOT NULL, tenant_id BIGINT NOT NULL DEFAULT current_setting('app.tenant_id')::bigint, company_id BIGINT NOT NULL,
    request_id BIGINT NOT NULL, line_no INT NOT NULL,
    field_name VARCHAR(64) NOT NULL,                   -- 字段物理名
    field_label VARCHAR(100) NULL, before_value VARCHAR(1000) NULL, after_value VARCHAR(1000) NULL,
    before_data JSONB NULL, after_data JSONB NULL,     -- 复杂值（JSON）
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), created_by BIGINT NOT NULL DEFAULT 0,
    CONSTRAINT pk_mdm_change_request_line PRIMARY KEY (id),
    CONSTRAINT fk_mdm_change_line_request FOREIGN KEY (request_id) REFERENCES mdm_change_request (id)
);

ALTER TABLE mdm_change_request_line ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm_change_request_line FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON mdm_change_request_line
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_mdm_change_line_no ON mdm_change_request_line (request_id, line_no);
COMMENT ON COLUMN mdm_change_request_line.field_name IS '字段物理名';
COMMENT ON COLUMN mdm_change_request_line.before_data IS '复杂值（JSON）';
COMMENT ON COLUMN mdm_change_request_line.id IS '雪花 ID（主键）';
COMMENT ON COLUMN mdm_change_request_line.created_at IS '创建时间';

-- mdm_data_quality_rule
CREATE TABLE mdm_data_quality_rule (
    id BIGINT NOT NULL, tenant_id BIGINT NOT NULL DEFAULT current_setting('app.tenant_id')::bigint, company_id BIGINT NOT NULL,
    rule_code VARCHAR(32) NOT NULL, rule_name VARCHAR(100) NOT NULL,
    object_type VARCHAR(32) NOT NULL, check_type SMALLINT NOT NULL, -- 10必须/20格式/30唯一/40参照/50业务
    severity SMALLINT NOT NULL DEFAULT 20,             -- 10E/20W/30I
    condition_expression TEXT NOT NULL,                -- SQL 条件/表达式
    message_template VARCHAR(500) NOT NULL, is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), created_by BIGINT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_by BIGINT NOT NULL DEFAULT 0,
    version INT NOT NULL DEFAULT 0, deleted BOOLEAN NOT NULL DEFAULT FALSE, remark VARCHAR(500) NULL,
    CONSTRAINT pk_mdm_data_quality_rule PRIMARY KEY (id)
);

ALTER TABLE mdm_data_quality_rule ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm_data_quality_rule FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON mdm_data_quality_rule
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_mdm_data_quality_rule ON mdm_data_quality_rule (tenant_id, company_id, rule_code) WHERE deleted = FALSE;
COMMENT ON COLUMN mdm_data_quality_rule.object_type IS '10必须/20格式/30唯一/40参照/50业务';
COMMENT ON COLUMN mdm_data_quality_rule.severity IS '10E/20W/30I';
COMMENT ON COLUMN mdm_data_quality_rule.condition_expression IS 'SQL 条件/表达式';
COMMENT ON COLUMN mdm_data_quality_rule.id IS '雪花 ID（主键）';
COMMENT ON COLUMN mdm_data_quality_rule.created_at IS '创建时间';
COMMENT ON COLUMN mdm_data_quality_rule.updated_at IS '更新时间';
COMMENT ON COLUMN mdm_data_quality_rule.version IS '乐观锁版本';

-- mdm_data_quality_issue
CREATE TABLE mdm_data_quality_issue (
    id BIGINT NOT NULL, tenant_id BIGINT NOT NULL DEFAULT current_setting('app.tenant_id')::bigint, company_id BIGINT NOT NULL,
    object_type VARCHAR(32) NOT NULL, object_id BIGINT NOT NULL, object_code VARCHAR(64) NULL,
    rule_id BIGINT NOT NULL, severity SMALLINT NOT NULL, issue_message VARCHAR(500) NOT NULL,
    assignee_id BIGINT NULL, status SMALLINT NOT NULL DEFAULT 10, -- 10起票/20修正中/30修正済/40关闭/50无视
    detected_at TIMESTAMPTZ NOT NULL DEFAULT now(), resolved_at TIMESTAMPTZ NULL,
    resolve_comment VARCHAR(500) NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), created_by BIGINT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_by BIGINT NOT NULL DEFAULT 0,
    version INT NOT NULL DEFAULT 0, deleted BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT pk_mdm_data_quality_issue PRIMARY KEY (id),
    CONSTRAINT fk_mdm_dq_issue_rule FOREIGN KEY (rule_id) REFERENCES mdm_data_quality_rule (id)
);

ALTER TABLE mdm_data_quality_issue ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm_data_quality_issue FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON mdm_data_quality_issue
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE INDEX idx_mdm_dq_issue_object ON mdm_data_quality_issue (object_type, object_id, status);
CREATE INDEX idx_mdm_dq_issue_status ON mdm_data_quality_issue (status, severity, detected_at DESC);
COMMENT ON COLUMN mdm_data_quality_issue.assignee_id IS '10起票/20修正中/30修正済/40关闭/50无视';
COMMENT ON COLUMN mdm_data_quality_issue.id IS '雪花 ID（主键）';
COMMENT ON COLUMN mdm_data_quality_issue.created_at IS '创建时间';
COMMENT ON COLUMN mdm_data_quality_issue.updated_at IS '更新时间';
COMMENT ON COLUMN mdm_data_quality_issue.version IS '乐观锁版本';

-- mdm_data_scope_policy
CREATE TABLE mdm_data_scope_policy (
    id BIGINT NOT NULL, tenant_id BIGINT NOT NULL DEFAULT current_setting('app.tenant_id')::bigint, company_id BIGINT NOT NULL,
    object_type VARCHAR(32) NOT NULL,                  -- MATERIAL/CUSTOMER/SUPPLIER...
    scope_key_column VARCHAR(64) NOT NULL,             -- 权限键列（factory_id/owner_user_id/sales_department_id）
    scope_type VARCHAR(16) NOT NULL,                   -- FACTORY/DEPARTMENT/OWNER/CUSTOM
    description VARCHAR(200) NULL, is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), created_by BIGINT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_by BIGINT NOT NULL DEFAULT 0,
    version INT NOT NULL DEFAULT 0, deleted BOOLEAN NOT NULL DEFAULT FALSE, remark VARCHAR(500) NULL,
    CONSTRAINT pk_mdm_data_scope_policy PRIMARY KEY (id)
);

ALTER TABLE mdm_data_scope_policy ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm_data_scope_policy FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON mdm_data_scope_policy
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_mdm_data_scope_policy ON mdm_data_scope_policy (tenant_id, company_id, object_type, scope_key_column) WHERE deleted = FALSE;
COMMENT ON COLUMN mdm_data_scope_policy.object_type IS 'MATERIAL/CUSTOMER/SUPPLIER...';
COMMENT ON COLUMN mdm_data_scope_policy.scope_key_column IS '权限键列（factory_id/owner_user_id/sales_department_id）';
COMMENT ON COLUMN mdm_data_scope_policy.scope_type IS 'FACTORY/DEPARTMENT/OWNER/CUSTOM';
COMMENT ON COLUMN mdm_data_scope_policy.id IS '雪花 ID（主键）';
COMMENT ON COLUMN mdm_data_scope_policy.created_at IS '创建时间';
COMMENT ON COLUMN mdm_data_scope_policy.updated_at IS '更新时间';
COMMENT ON COLUMN mdm_data_scope_policy.version IS '乐观锁版本';

