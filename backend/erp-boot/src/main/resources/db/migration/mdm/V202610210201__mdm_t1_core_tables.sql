-- T1 最小主数据（docs/design/02-mdm/95-acceptance-criteria.md 対象表）
-- 来源：docs/design/02-mdm/90-db-design.md；RLS 模板见 00-common/10-rls-and-db-roles.md

CREATE TABLE mdm_uom (
    id BIGINT NOT NULL, tenant_id BIGINT NOT NULL DEFAULT current_setting('app.tenant_id')::bigint, company_id BIGINT NOT NULL,
    uom_code VARCHAR(16) NOT NULL,                     -- 单位代码（UN/ECE Rec20）
    uom_name VARCHAR(32) NOT NULL, uom_name_en VARCHAR(64) NULL,
    conversion_group VARCHAR(16) NOT NULL,             -- 换算组（uom.csv の 11 群：PCS/SET/BOX/PK/ROL/MASS/LEN/AREA/VOL/TIME/ENERGY）
    is_base_uom BOOLEAN NOT NULL DEFAULT FALSE,        -- 基本单位
    decimal_places SMALLINT NOT NULL DEFAULT 0,        -- 小数位（0-4）
    rounding_mode VARCHAR(16) NOT NULL DEFAULT 'HALF_UP',
    sort_no INT NOT NULL DEFAULT 0, status SMALLINT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), created_by BIGINT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_by BIGINT NOT NULL DEFAULT 0,
    version INT NOT NULL DEFAULT 0, deleted BOOLEAN NOT NULL DEFAULT FALSE, remark VARCHAR(500) NULL,
    CONSTRAINT pk_mdm_uom PRIMARY KEY (id)
);
CREATE UNIQUE INDEX uk_mdm_uom_code ON mdm_uom (tenant_id, company_id, uom_code) WHERE deleted = FALSE;
CREATE UNIQUE INDEX uk_mdm_uom_base ON mdm_uom (tenant_id, company_id, conversion_group) WHERE is_base_uom = TRUE AND deleted = FALSE;

ALTER TABLE mdm_uom ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm_uom FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON mdm_uom
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);

CREATE TABLE mdm_material_category (
    id              BIGINT       NOT NULL,
    tenant_id       BIGINT       NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id      BIGINT       NOT NULL,
    category_code   VARCHAR(4)   NOT NULL,             -- 分类编码（4位：大类2+中类2）
    category_name   VARCHAR(100) NOT NULL,             -- 分类名称
    parent_id       BIGINT       NULL,                 -- 父分类ID（根为NULL）
    category_path   VARCHAR(500) NOT NULL,             -- 分类路径（/10/1001/）
    category_level  SMALLINT     NOT NULL,             -- 层级（1起）
    material_type   SMALLINT     NULL,                 -- 默认物料类型
    default_uom_code VARCHAR(16) NULL,                 -- 默认基本单位
    over_receipt_tolerance_pct NUMERIC(5,4) NULL,      -- 過入荷容差（比率 0.05=5%。分類既定。品目>分類>仕入先>会社の優先順、05 §2.4）
    completion_over_rate NUMERIC(5,4) NULL,            -- 完工超収容差（比率 0.05=5%。受注行>物料>分類>会社の優先順）
    attribute_template JSONB     NULL,                 -- 分类属性模板（扩展字段定义）
    is_leaf         BOOLEAN      NOT NULL DEFAULT FALSE, -- 是否末级
    sort_no         INT          NOT NULL DEFAULT 0,   -- 显示顺序
    status          SMALLINT     NOT NULL DEFAULT 1,   -- 1有效/0停止
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_by      BIGINT       NOT NULL DEFAULT 0,
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_by      BIGINT       NOT NULL DEFAULT 0,
    version         INT          NOT NULL DEFAULT 0,
    deleted         BOOLEAN      NOT NULL DEFAULT FALSE,
    remark          VARCHAR(500) NULL,
    ext_data        JSONB        NULL,
    CONSTRAINT pk_mdm_material_category PRIMARY KEY (id),
    CONSTRAINT fk_mdm_material_category_parent FOREIGN KEY (parent_id) REFERENCES mdm_material_category (id)
);
CREATE UNIQUE INDEX uk_mdm_material_category_code ON mdm_material_category (tenant_id, company_id, category_code) WHERE deleted = FALSE;
CREATE INDEX idx_mdm_material_category_parent ON mdm_material_category (company_id, parent_id);
CREATE INDEX gin_mdm_material_category_name ON mdm_material_category USING gin (category_name gin_trgm_ops);

ALTER TABLE mdm_material_category ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm_material_category FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON mdm_material_category
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);

CREATE TABLE mdm_material (
    id                    BIGINT       NOT NULL,
    tenant_id             BIGINT       NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id            BIGINT       NOT NULL,
    material_code         VARCHAR(10)  NOT NULL,       -- 物料编码（分类4+流水6）
    material_name         VARCHAR(200) NOT NULL,       -- 物料名称
    material_short_name   VARCHAR(100) NULL,           -- 简称
    material_type         SMALLINT     NOT NULL,       -- 类型 10成品/20半成品/30原材料/40外购件/50包装/60低值易耗品/70委外/80服务
    category_id           BIGINT       NOT NULL,       -- 物料分类ID
    spec                  VARCHAR(200) NOT NULL,       -- 规格型号
    material_grade        VARCHAR(100) NULL,           -- 材质牌号
    drawing_no            VARCHAR(64)  NULL,           -- 图号
    standard_code         VARCHAR(100) NULL,           -- 执行标准
    brand                 VARCHAR(100) NULL,           -- 品牌
    product_series        VARCHAR(64)  NULL,           -- 产品系列
    unit_weight           NUMERIC(18,6) NULL,          -- 单位重量KGM
    gross_weight          NUMERIC(18,6) NULL,          -- 毛重KGM
    volume                NUMERIC(18,6) NULL,          -- 体积MTQ
    origin_country_code   VARCHAR(2)   NULL,           -- 原产国ISO3166
    base_uom_code         VARCHAR(16)  NOT NULL,       -- 基本单位
    is_key_material       BOOLEAN      NOT NULL DEFAULT FALSE, -- 关键件
    is_customer_supplied  BOOLEAN      NOT NULL DEFAULT FALSE, -- 客供品
    is_consumable         BOOLEAN      NOT NULL DEFAULT FALSE, -- 消耗品
    -- 采购视图
    purchase_uom_code     VARCHAR(16)  NULL,           -- 采购单位
    purchase_conversion_rate NUMERIC(18,8) NULL,       -- 采购换算率
    purchase_lead_time_days  INT       NULL,           -- 采购提前期（日）
    min_order_qty         NUMERIC(18,4) NULL,          -- 最小订购量
    order_multiple        NUMERIC(18,4) NULL,          -- 订购倍数
    default_supplier_id   BIGINT       NULL,           -- 默认供应商
    supplier_material_no  VARCHAR(64)  NULL,           -- 供应商物料号
    purchase_tax_code     VARCHAR(32)  NULL,           -- 采购税码
    over_receipt_tolerance_pct NUMERIC(5,4) NULL,      -- 過入荷容差（比率 0.05=5%）
    buyer_id              BIGINT       NULL,           -- 采购担当
    is_purchase_stopped   BOOLEAN      NOT NULL DEFAULT FALSE, -- 采购停止
    -- 销售视图
    sales_uom_code        VARCHAR(16)  NULL,           -- 销售单位
    sales_conversion_rate NUMERIC(18,8) NULL,          -- 销售换算率
    sales_tax_code        VARCHAR(32)  NULL,           -- 销售税码
    sales_price_group_code VARCHAR(32) NULL,           -- 销售价格组
    min_sales_qty         NUMERIC(18,4) NULL,          -- 最小销售量
    sales_lead_time_days  INT          NULL,           -- 可销售天数
    return_limit_days     INT          NULL,           -- 退货期限（日）
    is_sales_stopped      BOOLEAN      NOT NULL DEFAULT FALSE, -- 销售停止
    ship_over_rate        NUMERIC(5,4) NULL,           -- 出荷超過容差（比率。受注行>物料>会社既定 0）
    -- 库存视图
    default_warehouse_id  BIGINT       NULL,           -- 默认仓库
    default_bin_id        BIGINT       NULL,           -- 默认库位
    is_batch_managed      BOOLEAN      NOT NULL DEFAULT FALSE, -- 批次管理
    batch_rule_code       VARCHAR(32)  NULL,           -- 批次规则码
    is_serial_managed     BOOLEAN      NOT NULL DEFAULT FALSE, -- 序列号管理
    serial_rule_code      VARCHAR(32)  NULL,           -- 序列号规则码
    shelf_life_days       INT          NULL,           -- 保质期（日）
    expiry_warning_days   INT          NULL,           -- 失效预警（日）
    safety_stock_qty      NUMERIC(18,4) NULL,          -- 安全库存
    reorder_point_qty     NUMERIC(18,4) NULL,          -- 再订货点
    max_stock_qty         NUMERIC(18,4) NULL,          -- 最大库存
    abc_class             VARCHAR(1)   NULL,           -- ABC分类
    cycle_count_cycle     VARCHAR(16)  NULL,           -- 盘点周期
    storage_condition     VARCHAR(32)  NULL,           -- 保管条件
    is_negative_stock_allowed BOOLEAN NOT NULL DEFAULT FALSE, -- 允许负库存
    is_hazardous          BOOLEAN      NOT NULL DEFAULT FALSE, -- 危险品
    -- 生产视图
    is_manufactured       BOOLEAN      NOT NULL DEFAULT FALSE, -- 制造品
    is_outsourced         BOOLEAN      NOT NULL DEFAULT FALSE, -- 委外品
    bom_required_flag     BOOLEAN      NOT NULL DEFAULT FALSE, -- 需要BOM
    default_bom_code      VARCHAR(64)  NULL,           -- 默认BOM（PRD）
    default_routing_code  VARCHAR(64)  NULL,           -- 默认工艺路线（PRD）
    is_backflush          BOOLEAN      NOT NULL DEFAULT FALSE, -- 倒冲
    backflush_warehouse_id BIGINT      NULL,           -- 倒冲仓库
    default_work_center_id BIGINT      NULL,           -- 默认工作中心
    yield_rate            NUMERIC(7,4) NULL,           -- 良品率%
    mrp_type              SMALLINT     NULL,           -- 10MTS/20MTO
    planning_policy       SMALLINT     NULL,           -- 10MRP/20ROP/30手动
    manufacturing_lead_time_days INT    NULL,          -- 制造提前期（日）
    completion_over_rate  NUMERIC(5,4) NULL,           -- 完工超収容差（比率 0.05=5%。受注行>物料>分類>会社既定）
    -- 财务视图
    inventory_account_code VARCHAR(32) NULL,           -- 存货科目
    revenue_account_code  VARCHAR(32)  NULL,           -- 收入科目
    cogs_account_code     VARCHAR(32)  NULL,           -- 销售成本科目
    cost_category         SMALLINT     NULL,           -- 成本分类
    cost_method           SMALLINT     NOT NULL DEFAULT 1, -- 成本核算方法 1品种法/2分批法（FIN直接参照）
    valuation_method      SMALLINT     NOT NULL,       -- 10移动平均/20标准成本（R1：MTS 自制品 20、MTO 产品・外购料 10。既定値なし）
    standard_cost         NUMERIC(18,6) NULL,          -- 标准成本（スナップショット。fin_publish_standard_cost（所有者 erp_cost_publisher）のみ更新可、他はトリガーで拒否。正は fin_standard_cost）
    standard_price        NUMERIC(18,6) NULL,          -- 标准销售价（参考）
    tax_classification_code VARCHAR(32) NULL,          -- 税收分类编码
    -- 质量视图
    inspection_stage      SMALLINT     NOT NULL DEFAULT 0, -- 00免检/10IQC/20IPQC/30FQC/40全工程
    inspection_standard_id BIGINT      NULL,           -- 检验标准（PRD）
    certificate_required  BOOLEAN      NOT NULL DEFAULT FALSE, -- 材质证明
    quality_grade         VARCHAR(8)   NULL,           -- 质量等级
    -- 状态
    status                SMALLINT     NOT NULL DEFAULT 0, -- 1有效/0使用停止
    approval_status       SMALLINT     NOT NULL DEFAULT 10, -- 10草稿/20审批中/25批准/95驳回/90废止
    submitted_at          TIMESTAMPTZ  NULL,
    approved_at           TIMESTAMPTZ  NULL,
    approved_by           BIGINT       NULL,
    effective_at          TIMESTAMPTZ  NULL,
    deactivate_reason     VARCHAR(500) NULL,
    -- 共通列セットA
    created_at            TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_by            BIGINT       NOT NULL DEFAULT 0,
    updated_at            TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_by            BIGINT       NOT NULL DEFAULT 0,
    version               INT          NOT NULL DEFAULT 0,
    deleted               BOOLEAN      NOT NULL DEFAULT FALSE,
    remark                VARCHAR(500) NULL,
    ext_data              JSONB        NULL,
    CONSTRAINT pk_mdm_material PRIMARY KEY (id),
    CONSTRAINT fk_mdm_material_category FOREIGN KEY (category_id) REFERENCES mdm_material_category (id),
    CONSTRAINT ck_mdm_material_stage CHECK (inspection_stage IN (0,10,20,30,40)),
    CONSTRAINT ck_mdm_material_cost_method CHECK (cost_method IN (1,2)),
    CONSTRAINT ck_mdm_material_valuation_method CHECK (valuation_method IN (10,20)),
    CONSTRAINT ck_mdm_material_completion_over_rate CHECK (completion_over_rate IS NULL OR completion_over_rate >= 0),
    CONSTRAINT ck_mdm_material_ship_over_rate CHECK (ship_over_rate IS NULL OR ship_over_rate >= 0),
    CONSTRAINT ck_mdm_material_status CHECK (status IN (0,1))
);
CREATE UNIQUE INDEX uk_mdm_material_company_code ON mdm_material (tenant_id, company_id, material_code) WHERE deleted = FALSE;
CREATE INDEX idx_mdm_material_category ON mdm_material (company_id, category_id);
CREATE INDEX idx_mdm_material_type_status ON mdm_material (company_id, material_type, status);
CREATE INDEX idx_mdm_material_batch ON mdm_material (company_id, is_batch_managed, status);
CREATE INDEX gin_mdm_material_name ON mdm_material USING gin (material_name gin_trgm_ops);
CREATE INDEX gin_mdm_material_spec ON mdm_material USING gin (spec gin_trgm_ops);
CREATE INDEX gin_mdm_material_ext ON mdm_material USING gin (ext_data jsonb_path_ops);

ALTER TABLE mdm_material ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm_material FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON mdm_material
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);

CREATE TABLE mdm_factory (
    id BIGINT NOT NULL, tenant_id BIGINT NOT NULL DEFAULT current_setting('app.tenant_id')::bigint, company_id BIGINT NOT NULL,
    factory_code VARCHAR(8) NOT NULL,                  -- 工厂编码（CZ01/WX01）
    factory_name VARCHAR(100) NOT NULL,                -- 工厂名称
    address VARCHAR(200) NULL,                         -- 地址
    manager_user_id BIGINT NULL,                       -- 负责人
    plant_type SMALLINT NULL,                          -- 10总装/20零部件/30其他
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), created_by BIGINT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_by BIGINT NOT NULL DEFAULT 0,
    version INT NOT NULL DEFAULT 0, deleted BOOLEAN NOT NULL DEFAULT FALSE, remark VARCHAR(500) NULL,
    CONSTRAINT pk_mdm_factory PRIMARY KEY (id)
);
CREATE UNIQUE INDEX uk_mdm_factory_code ON mdm_factory (tenant_id, company_id, factory_code) WHERE deleted = FALSE;

ALTER TABLE mdm_factory ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm_factory FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON mdm_factory
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);

CREATE TABLE mdm_warehouse (
    id BIGINT NOT NULL, tenant_id BIGINT NOT NULL DEFAULT current_setting('app.tenant_id')::bigint, company_id BIGINT NOT NULL,
    warehouse_code VARCHAR(8) NOT NULL,                -- 仓库编码（WH+2位）
    warehouse_name VARCHAR(100) NOT NULL,              -- 仓库名称
    warehouse_type SMALLINT NOT NULL,                  -- 10原料/20半成品/30成品/40待检/50不合格/60寄售/70在途/80委外
    factory_id BIGINT NOT NULL,                        -- 工厂ID
    address VARCHAR(200) NULL, manager_user_id BIGINT NULL, phone VARCHAR(32) NULL,
    is_physical BOOLEAN NOT NULL DEFAULT TRUE,         -- 物理仓库
    is_consignment BOOLEAN NOT NULL DEFAULT FALSE,     -- 寄售
    allow_negative_stock BOOLEAN NOT NULL DEFAULT FALSE,
    storage_condition VARCHAR(32) NULL,                -- 保管条件
    default_receiving_bin_id BIGINT NULL,              -- 默认入库库位
    default_issue_bin_id BIGINT NULL,                  -- 默认出库库位
    area_m2 NUMERIC(18,2) NULL,                        -- 面积
    status SMALLINT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), created_by BIGINT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_by BIGINT NOT NULL DEFAULT 0,
    version INT NOT NULL DEFAULT 0, deleted BOOLEAN NOT NULL DEFAULT FALSE, remark VARCHAR(500) NULL,
    CONSTRAINT pk_mdm_warehouse PRIMARY KEY (id),
    CONSTRAINT fk_mdm_warehouse_factory FOREIGN KEY (factory_id) REFERENCES mdm_factory (id),
    CONSTRAINT ck_mdm_warehouse_type CHECK (warehouse_type IN (10,20,30,40,50,60,70,80))
);
CREATE UNIQUE INDEX uk_mdm_warehouse_code ON mdm_warehouse (tenant_id, company_id, warehouse_code) WHERE deleted = FALSE;

ALTER TABLE mdm_warehouse ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm_warehouse FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON mdm_warehouse
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);

CREATE TABLE mdm_customer (
    id                    BIGINT       NOT NULL,
    tenant_id             BIGINT       NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id            BIGINT       NOT NULL,
    customer_code         VARCHAR(8)   NOT NULL,       -- 客户编码（C+6位）
    customer_name         VARCHAR(200) NOT NULL,       -- 客户名称
    short_name            VARCHAR(100) NULL,           -- 简称
    customer_type         SMALLINT     NOT NULL,       -- 10企业/20经销商/30个人/40出口
    customer_grade        VARCHAR(1)   NULL,           -- 客户等级 A/B/C/D
    industry_code         VARCHAR(16)  NULL,           -- 行业代码（GB/T 4754）
    tax_no                VARCHAR(18)  NOT NULL,       -- 统一社会信用代码（18位）
    legal_rep             VARCHAR(64)  NULL,           -- 法定代表人
    registered_address    VARCHAR(200) NULL,           -- 注册地址
    office_address        VARCHAR(200) NULL,           -- 办公地址
    phone                 VARCHAR(32)  NULL,           -- 代表电话
    website               VARCHAR(200) NULL,           -- 网站
    sales_department_id   BIGINT       NULL,           -- 所辖部门
    owner_user_id         BIGINT       NOT NULL,       -- 销售担当
    price_list_id         BIGINT       NULL,           -- 默认价格表
    price_group_code      VARCHAR(32)  NULL,           -- 价格组
    tax_code              VARCHAR(32)  NULL,           -- 默认税码（销项）
    payment_term_code     VARCHAR(32)  NOT NULL,       -- 付款条件
    settlement_method_code VARCHAR(32) NOT NULL,       -- 结算方式
    currency_code         VARCHAR(3)   NOT NULL DEFAULT 'CNY', -- 交易币种
    credit_limit_id       BIGINT       NULL,           -- 信用额度ID
    credit_status         SMALLINT     NOT NULL DEFAULT 10, -- 10正常/20超限/30冻结/40关闭
    ar_account_code       VARCHAR(32)  NULL,           -- 应收账款科目
    delivery_address      VARCHAR(200) NULL,           -- 默认收货地址
    return_limit_days     INT          NULL,           -- 退货期限（日）
    invoice_type          SMALLINT     NULL,           -- 10专票/20普票/30数电专票/40数电普票/50红字发票
    invoice_title         VARCHAR(200) NULL,           -- 发票抬头
    invoice_tax_no        VARCHAR(18)  NULL,           -- 发票税号
    invoice_address_phone VARCHAR(200) NULL,           -- 发票地址电话
    invoice_bank_name     VARCHAR(100) NULL,           -- 发票开户行
    invoice_bank_account  VARCHAR(64)  NULL,           -- 发票账号（加密推奨）
    status                SMALLINT     NOT NULL DEFAULT 0, -- 1有效/0停止
    approval_status       SMALLINT     NOT NULL DEFAULT 10, -- 10/20/25/90/95
    submitted_at          TIMESTAMPTZ  NULL,
    approved_at           TIMESTAMPTZ  NULL,
    approved_by           BIGINT       NULL,
    -- 共通列セットA
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), created_by BIGINT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_by BIGINT NOT NULL DEFAULT 0,
    version INT NOT NULL DEFAULT 0, deleted BOOLEAN NOT NULL DEFAULT FALSE,
    remark VARCHAR(500) NULL, ext_data JSONB NULL,
    CONSTRAINT pk_mdm_customer PRIMARY KEY (id),
    CONSTRAINT ck_mdm_customer_type CHECK (customer_type IN (10,20,30,40)),
    CONSTRAINT ck_mdm_customer_status CHECK (status IN (0,1))
);
CREATE UNIQUE INDEX uk_mdm_customer_code ON mdm_customer (tenant_id, company_id, customer_code) WHERE deleted = FALSE;
CREATE UNIQUE INDEX uk_mdm_customer_tax_no ON mdm_customer (tenant_id, company_id, tax_no) WHERE deleted = FALSE;
CREATE INDEX idx_mdm_customer_owner ON mdm_customer (company_id, owner_user_id, status);
CREATE INDEX idx_mdm_customer_credit ON mdm_customer (company_id, credit_status);
CREATE INDEX gin_mdm_customer_name ON mdm_customer USING gin (customer_name gin_trgm_ops);

ALTER TABLE mdm_customer ENABLE ROW LEVEL SECURITY;
ALTER TABLE mdm_customer FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON mdm_customer
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);

COMMENT ON TABLE mdm_uom IS '计量单位';
COMMENT ON COLUMN mdm_uom.uom_code IS '单位代码（UN/ECE Rec20）';
COMMENT ON COLUMN mdm_uom.conversion_group IS '换算组（uom.csv の 11 群：PCS/SET/BOX/PK/ROL/MASS/LEN/AREA/VOL/TIME/ENERGY）';
COMMENT ON COLUMN mdm_uom.is_base_uom IS '基本单位';
COMMENT ON COLUMN mdm_uom.decimal_places IS '小数位（0-4）';
COMMENT ON COLUMN mdm_uom.id IS '雪花 ID（主键）';
COMMENT ON COLUMN mdm_uom.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN mdm_uom.company_id IS '公司 ID';
COMMENT ON COLUMN mdm_uom.created_at IS '创建时间';
COMMENT ON COLUMN mdm_uom.created_by IS '创建人';
COMMENT ON COLUMN mdm_uom.updated_at IS '更新时间';
COMMENT ON COLUMN mdm_uom.updated_by IS '更新人';
COMMENT ON COLUMN mdm_uom.version IS '乐观锁版本';
COMMENT ON COLUMN mdm_uom.deleted IS '逻辑删除';
COMMENT ON COLUMN mdm_uom.remark IS '备注';
COMMENT ON TABLE mdm_material_category IS '物料分类';
COMMENT ON COLUMN mdm_material_category.category_code IS '分类编码（4位：大类2+中类2）';
COMMENT ON COLUMN mdm_material_category.category_name IS '分类名称';
COMMENT ON COLUMN mdm_material_category.parent_id IS '父分类ID（根为NULL）';
COMMENT ON COLUMN mdm_material_category.category_path IS '分类路径（/10/1001/）';
COMMENT ON COLUMN mdm_material_category.category_level IS '层级（1起）';
COMMENT ON COLUMN mdm_material_category.material_type IS '默认物料类型';
COMMENT ON COLUMN mdm_material_category.default_uom_code IS '默认基本单位';
COMMENT ON COLUMN mdm_material_category.over_receipt_tolerance_pct IS '過入荷容差（比率 0.05=5%。分類既定。品目>分類>仕入先>会社の優先順、05 §2.4）';
COMMENT ON COLUMN mdm_material_category.completion_over_rate IS '完工超収容差（比率 0.05=5%。受注行>物料>分類>会社の優先順）';
COMMENT ON COLUMN mdm_material_category.attribute_template IS '分类属性模板（扩展字段定义）';
COMMENT ON COLUMN mdm_material_category.is_leaf IS '是否末级';
COMMENT ON COLUMN mdm_material_category.sort_no IS '显示顺序';
COMMENT ON COLUMN mdm_material_category.status IS '1有效/0停止';
COMMENT ON COLUMN mdm_material_category.id IS '雪花 ID（主键）';
COMMENT ON COLUMN mdm_material_category.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN mdm_material_category.company_id IS '公司 ID';
COMMENT ON COLUMN mdm_material_category.created_at IS '创建时间';
COMMENT ON COLUMN mdm_material_category.created_by IS '创建人';
COMMENT ON COLUMN mdm_material_category.updated_at IS '更新时间';
COMMENT ON COLUMN mdm_material_category.updated_by IS '更新人';
COMMENT ON COLUMN mdm_material_category.version IS '乐观锁版本';
COMMENT ON COLUMN mdm_material_category.deleted IS '逻辑删除';
COMMENT ON COLUMN mdm_material_category.remark IS '备注';
COMMENT ON COLUMN mdm_material_category.ext_data IS '扩展字段';
COMMENT ON TABLE mdm_material IS '物料主数据';
COMMENT ON COLUMN mdm_material.material_code IS '物料编码（分类4+流水6）';
COMMENT ON COLUMN mdm_material.material_name IS '物料名称';
COMMENT ON COLUMN mdm_material.material_short_name IS '简称';
COMMENT ON COLUMN mdm_material.material_type IS '类型 10成品/20半成品/30原材料/40外购件/50包装/60低值易耗品/70委外/80服务';
COMMENT ON COLUMN mdm_material.category_id IS '物料分类ID';
COMMENT ON COLUMN mdm_material.spec IS '规格型号';
COMMENT ON COLUMN mdm_material.material_grade IS '材质牌号';
COMMENT ON COLUMN mdm_material.drawing_no IS '图号';
COMMENT ON COLUMN mdm_material.standard_code IS '执行标准';
COMMENT ON COLUMN mdm_material.brand IS '品牌';
COMMENT ON COLUMN mdm_material.product_series IS '产品系列';
COMMENT ON COLUMN mdm_material.unit_weight IS '单位重量KGM';
COMMENT ON COLUMN mdm_material.gross_weight IS '毛重KGM';
COMMENT ON COLUMN mdm_material.volume IS '体积MTQ';
COMMENT ON COLUMN mdm_material.origin_country_code IS '原产国ISO3166';
COMMENT ON COLUMN mdm_material.base_uom_code IS '基本单位';
COMMENT ON COLUMN mdm_material.is_key_material IS '关键件';
COMMENT ON COLUMN mdm_material.is_customer_supplied IS '客供品';
COMMENT ON COLUMN mdm_material.is_consumable IS '消耗品';
COMMENT ON COLUMN mdm_material.purchase_uom_code IS '采购单位';
COMMENT ON COLUMN mdm_material.purchase_conversion_rate IS '采购换算率';
COMMENT ON COLUMN mdm_material.purchase_lead_time_days IS '采购提前期（日）';
COMMENT ON COLUMN mdm_material.min_order_qty IS '最小订购量';
COMMENT ON COLUMN mdm_material.order_multiple IS '订购倍数';
COMMENT ON COLUMN mdm_material.default_supplier_id IS '默认供应商';
COMMENT ON COLUMN mdm_material.supplier_material_no IS '供应商物料号';
COMMENT ON COLUMN mdm_material.purchase_tax_code IS '采购税码';
COMMENT ON COLUMN mdm_material.over_receipt_tolerance_pct IS '過入荷容差（比率 0.05=5%）';
COMMENT ON COLUMN mdm_material.buyer_id IS '采购担当';
COMMENT ON COLUMN mdm_material.is_purchase_stopped IS '采购停止';
COMMENT ON COLUMN mdm_material.sales_uom_code IS '销售单位';
COMMENT ON COLUMN mdm_material.sales_conversion_rate IS '销售换算率';
COMMENT ON COLUMN mdm_material.sales_tax_code IS '销售税码';
COMMENT ON COLUMN mdm_material.sales_price_group_code IS '销售价格组';
COMMENT ON COLUMN mdm_material.min_sales_qty IS '最小销售量';
COMMENT ON COLUMN mdm_material.sales_lead_time_days IS '可销售天数';
COMMENT ON COLUMN mdm_material.return_limit_days IS '退货期限（日）';
COMMENT ON COLUMN mdm_material.is_sales_stopped IS '销售停止';
COMMENT ON COLUMN mdm_material.ship_over_rate IS '出荷超過容差（比率。受注行>物料>会社既定 0）';
COMMENT ON COLUMN mdm_material.default_warehouse_id IS '默认仓库';
COMMENT ON COLUMN mdm_material.default_bin_id IS '默认库位';
COMMENT ON COLUMN mdm_material.is_batch_managed IS '批次管理';
COMMENT ON COLUMN mdm_material.batch_rule_code IS '批次规则码';
COMMENT ON COLUMN mdm_material.is_serial_managed IS '序列号管理';
COMMENT ON COLUMN mdm_material.serial_rule_code IS '序列号规则码';
COMMENT ON COLUMN mdm_material.shelf_life_days IS '保质期（日）';
COMMENT ON COLUMN mdm_material.expiry_warning_days IS '失效预警（日）';
COMMENT ON COLUMN mdm_material.safety_stock_qty IS '安全库存';
COMMENT ON COLUMN mdm_material.reorder_point_qty IS '再订货点';
COMMENT ON COLUMN mdm_material.max_stock_qty IS '最大库存';
COMMENT ON COLUMN mdm_material.abc_class IS 'ABC分类';
COMMENT ON COLUMN mdm_material.cycle_count_cycle IS '盘点周期';
COMMENT ON COLUMN mdm_material.storage_condition IS '保管条件';
COMMENT ON COLUMN mdm_material.is_negative_stock_allowed IS '允许负库存';
COMMENT ON COLUMN mdm_material.is_hazardous IS '危险品';
COMMENT ON COLUMN mdm_material.is_manufactured IS '制造品';
COMMENT ON COLUMN mdm_material.is_outsourced IS '委外品';
COMMENT ON COLUMN mdm_material.bom_required_flag IS '需要BOM';
COMMENT ON COLUMN mdm_material.default_bom_code IS '默认BOM（PRD）';
COMMENT ON COLUMN mdm_material.default_routing_code IS '默认工艺路线（PRD）';
COMMENT ON COLUMN mdm_material.is_backflush IS '倒冲';
COMMENT ON COLUMN mdm_material.backflush_warehouse_id IS '倒冲仓库';
COMMENT ON COLUMN mdm_material.default_work_center_id IS '默认工作中心';
COMMENT ON COLUMN mdm_material.yield_rate IS '良品率%';
COMMENT ON COLUMN mdm_material.mrp_type IS '10MTS/20MTO';
COMMENT ON COLUMN mdm_material.planning_policy IS '10MRP/20ROP/30手动';
COMMENT ON COLUMN mdm_material.manufacturing_lead_time_days IS '制造提前期（日）';
COMMENT ON COLUMN mdm_material.completion_over_rate IS '完工超収容差（比率 0.05=5%。受注行>物料>分類>会社既定）';
COMMENT ON COLUMN mdm_material.inventory_account_code IS '存货科目';
COMMENT ON COLUMN mdm_material.revenue_account_code IS '收入科目';
COMMENT ON COLUMN mdm_material.cogs_account_code IS '销售成本科目';
COMMENT ON COLUMN mdm_material.cost_category IS '成本分类';
COMMENT ON COLUMN mdm_material.cost_method IS '成本核算方法 1品种法/2分批法（FIN直接参照）';
COMMENT ON COLUMN mdm_material.valuation_method IS '10移动平均/20标准成本（R1：MTS 自制品 20、MTO 产品・外购料 10。既定値なし）';
COMMENT ON COLUMN mdm_material.standard_cost IS '标准成本（スナップショット。fin_publish_standard_cost（所有者 erp_cost_publisher）のみ更新可、他はトリガーで拒否。正は fin_standard_cost）';
COMMENT ON COLUMN mdm_material.standard_price IS '标准销售价（参考）';
COMMENT ON COLUMN mdm_material.tax_classification_code IS '税收分类编码';
COMMENT ON COLUMN mdm_material.inspection_stage IS '00免检/10IQC/20IPQC/30FQC/40全工程';
COMMENT ON COLUMN mdm_material.inspection_standard_id IS '检验标准（PRD）';
COMMENT ON COLUMN mdm_material.certificate_required IS '材质证明';
COMMENT ON COLUMN mdm_material.quality_grade IS '质量等级';
COMMENT ON COLUMN mdm_material.status IS '1有效/0使用停止';
COMMENT ON COLUMN mdm_material.approval_status IS '10草稿/20审批中/25批准/95驳回/90废止';
COMMENT ON COLUMN mdm_material.id IS '雪花 ID（主键）';
COMMENT ON COLUMN mdm_material.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN mdm_material.company_id IS '公司 ID';
COMMENT ON COLUMN mdm_material.created_at IS '创建时间';
COMMENT ON COLUMN mdm_material.created_by IS '创建人';
COMMENT ON COLUMN mdm_material.updated_at IS '更新时间';
COMMENT ON COLUMN mdm_material.updated_by IS '更新人';
COMMENT ON COLUMN mdm_material.version IS '乐观锁版本';
COMMENT ON COLUMN mdm_material.deleted IS '逻辑删除';
COMMENT ON COLUMN mdm_material.remark IS '备注';
COMMENT ON COLUMN mdm_material.ext_data IS '扩展字段';
COMMENT ON TABLE mdm_factory IS '工厂';
COMMENT ON COLUMN mdm_factory.factory_code IS '工厂编码（CZ01/WX01）';
COMMENT ON COLUMN mdm_factory.factory_name IS '工厂名称';
COMMENT ON COLUMN mdm_factory.address IS '地址';
COMMENT ON COLUMN mdm_factory.manager_user_id IS '负责人';
COMMENT ON COLUMN mdm_factory.plant_type IS '10总装/20零部件/30其他';
COMMENT ON COLUMN mdm_factory.id IS '雪花 ID（主键）';
COMMENT ON COLUMN mdm_factory.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN mdm_factory.company_id IS '公司 ID';
COMMENT ON COLUMN mdm_factory.created_at IS '创建时间';
COMMENT ON COLUMN mdm_factory.created_by IS '创建人';
COMMENT ON COLUMN mdm_factory.updated_at IS '更新时间';
COMMENT ON COLUMN mdm_factory.updated_by IS '更新人';
COMMENT ON COLUMN mdm_factory.version IS '乐观锁版本';
COMMENT ON COLUMN mdm_factory.deleted IS '逻辑删除';
COMMENT ON COLUMN mdm_factory.remark IS '备注';
COMMENT ON TABLE mdm_warehouse IS '仓库';
COMMENT ON COLUMN mdm_warehouse.warehouse_code IS '仓库编码（WH+2位）';
COMMENT ON COLUMN mdm_warehouse.warehouse_name IS '仓库名称';
COMMENT ON COLUMN mdm_warehouse.warehouse_type IS '10原料/20半成品/30成品/40待检/50不合格/60寄售/70在途/80委外';
COMMENT ON COLUMN mdm_warehouse.factory_id IS '工厂ID';
COMMENT ON COLUMN mdm_warehouse.is_physical IS '物理仓库';
COMMENT ON COLUMN mdm_warehouse.is_consignment IS '寄售';
COMMENT ON COLUMN mdm_warehouse.storage_condition IS '保管条件';
COMMENT ON COLUMN mdm_warehouse.default_receiving_bin_id IS '默认入库库位';
COMMENT ON COLUMN mdm_warehouse.default_issue_bin_id IS '默认出库库位';
COMMENT ON COLUMN mdm_warehouse.area_m2 IS '面积';
COMMENT ON COLUMN mdm_warehouse.id IS '雪花 ID（主键）';
COMMENT ON COLUMN mdm_warehouse.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN mdm_warehouse.company_id IS '公司 ID';
COMMENT ON COLUMN mdm_warehouse.created_at IS '创建时间';
COMMENT ON COLUMN mdm_warehouse.created_by IS '创建人';
COMMENT ON COLUMN mdm_warehouse.updated_at IS '更新时间';
COMMENT ON COLUMN mdm_warehouse.updated_by IS '更新人';
COMMENT ON COLUMN mdm_warehouse.version IS '乐观锁版本';
COMMENT ON COLUMN mdm_warehouse.deleted IS '逻辑删除';
COMMENT ON COLUMN mdm_warehouse.remark IS '备注';
COMMENT ON TABLE mdm_customer IS '客户';
COMMENT ON COLUMN mdm_customer.customer_code IS '客户编码（C+6位）';
COMMENT ON COLUMN mdm_customer.customer_name IS '客户名称';
COMMENT ON COLUMN mdm_customer.short_name IS '简称';
COMMENT ON COLUMN mdm_customer.customer_type IS '10企业/20经销商/30个人/40出口';
COMMENT ON COLUMN mdm_customer.customer_grade IS '客户等级 A/B/C/D';
COMMENT ON COLUMN mdm_customer.industry_code IS '行业代码（GB/T 4754）';
COMMENT ON COLUMN mdm_customer.tax_no IS '统一社会信用代码（18位）';
COMMENT ON COLUMN mdm_customer.legal_rep IS '法定代表人';
COMMENT ON COLUMN mdm_customer.registered_address IS '注册地址';
COMMENT ON COLUMN mdm_customer.office_address IS '办公地址';
COMMENT ON COLUMN mdm_customer.phone IS '代表电话';
COMMENT ON COLUMN mdm_customer.website IS '网站';
COMMENT ON COLUMN mdm_customer.sales_department_id IS '所辖部门';
COMMENT ON COLUMN mdm_customer.owner_user_id IS '销售担当';
COMMENT ON COLUMN mdm_customer.price_list_id IS '默认价格表';
COMMENT ON COLUMN mdm_customer.price_group_code IS '价格组';
COMMENT ON COLUMN mdm_customer.tax_code IS '默认税码（销项）';
COMMENT ON COLUMN mdm_customer.payment_term_code IS '付款条件';
COMMENT ON COLUMN mdm_customer.settlement_method_code IS '结算方式';
COMMENT ON COLUMN mdm_customer.currency_code IS '交易币种';
COMMENT ON COLUMN mdm_customer.credit_limit_id IS '信用额度ID';
COMMENT ON COLUMN mdm_customer.credit_status IS '10正常/20超限/30冻结/40关闭';
COMMENT ON COLUMN mdm_customer.ar_account_code IS '应收账款科目';
COMMENT ON COLUMN mdm_customer.delivery_address IS '默认收货地址';
COMMENT ON COLUMN mdm_customer.return_limit_days IS '退货期限（日）';
COMMENT ON COLUMN mdm_customer.invoice_type IS '10专票/20普票/30数电专票/40数电普票/50红字发票';
COMMENT ON COLUMN mdm_customer.invoice_title IS '发票抬头';
COMMENT ON COLUMN mdm_customer.invoice_tax_no IS '发票税号';
COMMENT ON COLUMN mdm_customer.invoice_address_phone IS '发票地址电话';
COMMENT ON COLUMN mdm_customer.invoice_bank_name IS '发票开户行';
COMMENT ON COLUMN mdm_customer.invoice_bank_account IS '发票账号（加密推奨）';
COMMENT ON COLUMN mdm_customer.status IS '1有效/0停止';
COMMENT ON COLUMN mdm_customer.approval_status IS '10/20/25/90/95';
COMMENT ON COLUMN mdm_customer.id IS '雪花 ID（主键）';
COMMENT ON COLUMN mdm_customer.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN mdm_customer.company_id IS '公司 ID';
COMMENT ON COLUMN mdm_customer.created_at IS '创建时间';
COMMENT ON COLUMN mdm_customer.created_by IS '创建人';
COMMENT ON COLUMN mdm_customer.updated_at IS '更新时间';
COMMENT ON COLUMN mdm_customer.updated_by IS '更新人';
COMMENT ON COLUMN mdm_customer.version IS '乐观锁版本';
COMMENT ON COLUMN mdm_customer.deleted IS '逻辑删除';
COMMENT ON COLUMN mdm_customer.remark IS '备注';
COMMENT ON COLUMN mdm_customer.ext_data IS '扩展字段';