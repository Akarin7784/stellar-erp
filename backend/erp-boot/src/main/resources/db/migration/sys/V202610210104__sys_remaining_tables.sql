-- 01-system 补全：#55 最小集之外的系统表（docs/design/01-system/90-db-design.md）
-- 已建（跳过）：sys_company, sys_param, sys_sequence, sys_tenant, sys_user
-- 规则：tenant_id DEFAULT current_setting；company_id NOT NULL 无 DEFAULT 1；
--       唯一键以 tenant_id 打头（04-common-db-spec §6.1 例外除外）；FORCE RLS
-- #55 种租户 0 INSERT 在超户下执行未先 set_config；sys_init_tenant 已对后续租户 set_config
-- （不改已发布迁移 checksum）。本文件不建销售/生产/财务表。

-- sys_factory_setting
CREATE TABLE sys_factory_setting (
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
    factory_id          BIGINT        NOT NULL,           -- 工厂 ID（mdm_factory.id、MDM 主データ参照）
    is_enabled          BOOLEAN       NOT NULL DEFAULT TRUE,  -- システム利用可否（组织設置）
    is_default          BOOLEAN       NOT NULL DEFAULT FALSE, -- 是否默认工厂（会社内 1 件）
    manager_user_id     BIGINT,                           -- 工厂负责人（sys_user.id、組織責任者）
    sort_no             INT           NOT NULL DEFAULT 0, -- 表示顺
    description         VARCHAR(500), -- 说明
    CONSTRAINT pk_sys_factory_setting PRIMARY KEY (id)
);

ALTER TABLE sys_factory_setting ENABLE ROW LEVEL SECURITY;
ALTER TABLE sys_factory_setting FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sys_factory_setting
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_sys_factory_setting ON sys_factory_setting (tenant_id, factory_id) WHERE deleted = FALSE;
CREATE INDEX idx_sys_factory_setting_default ON sys_factory_setting (company_id, is_default) WHERE is_default AND deleted = FALSE;
COMMENT ON TABLE sys_factory_setting IS '工厂组织设置（工厂主数据は mdm_factory が管理）';
COMMENT ON COLUMN sys_factory_setting.factory_id IS '工厂 ID（mdm_factory.id、MDM 主データ参照）';
COMMENT ON COLUMN sys_factory_setting.is_enabled IS 'システム利用可否（组织設置）';
COMMENT ON COLUMN sys_factory_setting.is_default IS '是否默认工厂（会社内 1 件）';
COMMENT ON COLUMN sys_factory_setting.manager_user_id IS '工厂负责人（sys_user.id、組織責任者）';
COMMENT ON COLUMN sys_factory_setting.sort_no IS '表示顺';
COMMENT ON COLUMN sys_factory_setting.description IS '说明';
COMMENT ON COLUMN sys_factory_setting.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN sys_factory_setting.company_id IS '公司 ID';
COMMENT ON COLUMN sys_factory_setting.created_at IS '创建时间';
COMMENT ON COLUMN sys_factory_setting.created_by IS '创建人';
COMMENT ON COLUMN sys_factory_setting.updated_at IS '更新时间';
COMMENT ON COLUMN sys_factory_setting.updated_by IS '更新人';
COMMENT ON COLUMN sys_factory_setting.version IS '乐观锁版本';
COMMENT ON COLUMN sys_factory_setting.deleted IS '逻辑删除';
COMMENT ON COLUMN sys_factory_setting.remark IS '备注';
COMMENT ON COLUMN sys_factory_setting.ext_data IS '扩展字段';

-- sys_department
CREATE TABLE sys_department (
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
    department_code     VARCHAR(16)   NOT NULL,           -- 部门代码（D+3 桁、规则见 08 2.2）
    department_name     VARCHAR(200)  NOT NULL,           -- 部门名称
    parent_id           BIGINT        NOT NULL DEFAULT 0, -- 父部门 ID（0=ルート）
    department_path     VARCHAR(500)  NOT NULL DEFAULT '/', -- 素材化パス（例 /1/12/35/）
    department_level    SMALLINT      NOT NULL DEFAULT 1, -- 階層（1 起算）
    factory_id          BIGINT,                           -- 所属工厂（mdm_factory.id、MDM 主データ参照）
    manager_user_id     BIGINT,                           -- 部门负责人（sys_user.id）
    cost_center_code    VARCHAR(32),                      -- 成本中心代码（財務連携用）
    is_leaf             BOOLEAN       NOT NULL DEFAULT TRUE, -- 是否末级（子追加時に更新）
    status              SMALLINT      NOT NULL DEFAULT 1, -- 状态：1 有效 / 0 无效
    sort_no             INT           NOT NULL DEFAULT 0, -- 同级表示顺
    valid_from          DATE,                             -- 有効開始日（組織改編用）
    valid_to            DATE, -- 有効終了日
    CONSTRAINT pk_sys_department PRIMARY KEY (id)
);

ALTER TABLE sys_department ENABLE ROW LEVEL SECURITY;
ALTER TABLE sys_department FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sys_department
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_sys_department_company_code ON sys_department (tenant_id, company_id, department_code) WHERE deleted = FALSE;
CREATE INDEX idx_sys_department_parent ON sys_department (parent_id, sort_no);
CREATE INDEX idx_sys_department_path ON sys_department (department_path);
COMMENT ON TABLE sys_department IS '部门（组织ツリー）';
COMMENT ON COLUMN sys_department.department_code IS '部门代码（D+3 桁、规则见 08 2.2）';
COMMENT ON COLUMN sys_department.department_name IS '部门名称';
COMMENT ON COLUMN sys_department.parent_id IS '父部门 ID（0=ルート）';
COMMENT ON COLUMN sys_department.department_path IS '素材化パス（例 /1/12/35/）';
COMMENT ON COLUMN sys_department.department_level IS '階層（1 起算）';
COMMENT ON COLUMN sys_department.factory_id IS '所属工厂（mdm_factory.id、MDM 主データ参照）';
COMMENT ON COLUMN sys_department.manager_user_id IS '部门负责人（sys_user.id）';
COMMENT ON COLUMN sys_department.cost_center_code IS '成本中心代码（財務連携用）';
COMMENT ON COLUMN sys_department.is_leaf IS '是否末级（子追加時に更新）';
COMMENT ON COLUMN sys_department.status IS '状态：1 有效 / 0 无效';
COMMENT ON COLUMN sys_department.sort_no IS '同级表示顺';
COMMENT ON COLUMN sys_department.valid_from IS '有効開始日（組織改編用）';
COMMENT ON COLUMN sys_department.valid_to IS '有効終了日';
COMMENT ON COLUMN sys_department.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN sys_department.company_id IS '公司 ID';
COMMENT ON COLUMN sys_department.created_at IS '创建时间';
COMMENT ON COLUMN sys_department.created_by IS '创建人';
COMMENT ON COLUMN sys_department.updated_at IS '更新时间';
COMMENT ON COLUMN sys_department.updated_by IS '更新人';
COMMENT ON COLUMN sys_department.version IS '乐观锁版本';
COMMENT ON COLUMN sys_department.deleted IS '逻辑删除';
COMMENT ON COLUMN sys_department.remark IS '备注';
COMMENT ON COLUMN sys_department.ext_data IS '扩展字段';

-- sys_position
CREATE TABLE sys_position (
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
    position_code       VARCHAR(32)   NOT NULL,           -- 岗位代码
    position_name       VARCHAR(100)  NOT NULL,           -- 岗位名称
    position_category   SMALLINT      NOT NULL DEFAULT 2, -- 分类：1 管理 / 2 专业 / 3 操作
    position_level      SMALLINT      NOT NULL DEFAULT 1, -- 职级（1〜20）
    department_id       BIGINT,                           -- 所属部门（sys_department.id）
    is_manager          BOOLEAN       NOT NULL DEFAULT FALSE, -- 是否管理岗（审批者判定用）
    status              SMALLINT      NOT NULL DEFAULT 1, -- 状态：1 有效 / 0 无效
    sort_no             INT           NOT NULL DEFAULT 0, -- 表示顺
    CONSTRAINT pk_sys_position PRIMARY KEY (id)
);

ALTER TABLE sys_position ENABLE ROW LEVEL SECURITY;
ALTER TABLE sys_position FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sys_position
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_sys_position_company_code ON sys_position (tenant_id, company_id, position_code) WHERE deleted = FALSE;
CREATE INDEX idx_sys_position_department ON sys_position (department_id, status);
COMMENT ON TABLE sys_position IS '岗位（職位）';
COMMENT ON COLUMN sys_position.position_code IS '岗位代码';
COMMENT ON COLUMN sys_position.position_name IS '岗位名称';
COMMENT ON COLUMN sys_position.position_category IS '分类：1 管理 / 2 专业 / 3 操作';
COMMENT ON COLUMN sys_position.position_level IS '职级（1〜20）';
COMMENT ON COLUMN sys_position.department_id IS '所属部门（sys_department.id）';
COMMENT ON COLUMN sys_position.is_manager IS '是否管理岗（审批者判定用）';
COMMENT ON COLUMN sys_position.status IS '状态：1 有效 / 0 无效';
COMMENT ON COLUMN sys_position.sort_no IS '表示顺';
COMMENT ON COLUMN sys_position.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN sys_position.company_id IS '公司 ID';
COMMENT ON COLUMN sys_position.created_at IS '创建时间';
COMMENT ON COLUMN sys_position.created_by IS '创建人';
COMMENT ON COLUMN sys_position.updated_at IS '更新时间';
COMMENT ON COLUMN sys_position.updated_by IS '更新人';
COMMENT ON COLUMN sys_position.version IS '乐观锁版本';
COMMENT ON COLUMN sys_position.deleted IS '逻辑删除';
COMMENT ON COLUMN sys_position.remark IS '备注';
COMMENT ON COLUMN sys_position.ext_data IS '扩展字段';

-- sys_role
CREATE TABLE sys_role (
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
    role_code           VARCHAR(64)   NOT NULL,           -- 角色代码（例 SYSTEM_ADMIN、SALES_MANAGER）
    role_name           VARCHAR(100)  NOT NULL,           -- 角色名称
    role_type           SMALLINT      NOT NULL DEFAULT 2, -- 类型：1 内置系统 / 2 业务 / 3 只读
    data_scope_type     SMALLINT      NOT NULL DEFAULT 2, -- 数据范围：1 全社 / 2 本部门及子部门 / 3 本部门 / 4 本人 / 5 自定义 / 6 工場 / 7 倉庫
    description         VARCHAR(500),                     -- 说明
    is_default          BOOLEAN       NOT NULL DEFAULT FALSE, -- 新規ユーザの既定ロール
    requires_approval   BOOLEAN       NOT NULL DEFAULT TRUE,  -- 付与時承認要否（高権限ロール）
    status              SMALLINT      NOT NULL DEFAULT 1, -- 状态：1 有效 / 0 无效
    sort_no             INT           NOT NULL DEFAULT 0, -- 表示顺
    CONSTRAINT pk_sys_role PRIMARY KEY (id)
);

ALTER TABLE sys_role ENABLE ROW LEVEL SECURITY;
ALTER TABLE sys_role FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sys_role
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_sys_role_code ON sys_role (tenant_id, role_code) WHERE deleted = FALSE;
CREATE INDEX idx_sys_role_status ON sys_role (status, sort_no);
COMMENT ON TABLE sys_role IS '角色（権限集合）';
COMMENT ON COLUMN sys_role.role_code IS '角色代码（例 SYSTEM_ADMIN、SALES_MANAGER）';
COMMENT ON COLUMN sys_role.role_name IS '角色名称';
COMMENT ON COLUMN sys_role.role_type IS '类型：1 内置系统 / 2 业务 / 3 只读';
COMMENT ON COLUMN sys_role.data_scope_type IS '数据范围：1 全社 / 2 本部门及子部门 / 3 本部门 / 4 本人 / 5 自定义 / 6 工場 / 7 倉庫';
COMMENT ON COLUMN sys_role.description IS '说明';
COMMENT ON COLUMN sys_role.is_default IS '新規ユーザの既定ロール';
COMMENT ON COLUMN sys_role.requires_approval IS '付与時承認要否（高権限ロール）';
COMMENT ON COLUMN sys_role.status IS '状态：1 有效 / 0 无效';
COMMENT ON COLUMN sys_role.sort_no IS '表示顺';
COMMENT ON COLUMN sys_role.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN sys_role.company_id IS '公司 ID';
COMMENT ON COLUMN sys_role.created_at IS '创建时间';
COMMENT ON COLUMN sys_role.created_by IS '创建人';
COMMENT ON COLUMN sys_role.updated_at IS '更新时间';
COMMENT ON COLUMN sys_role.updated_by IS '更新人';
COMMENT ON COLUMN sys_role.version IS '乐观锁版本';
COMMENT ON COLUMN sys_role.deleted IS '逻辑删除';
COMMENT ON COLUMN sys_role.remark IS '备注';
COMMENT ON COLUMN sys_role.ext_data IS '扩展字段';

-- sys_user_role
CREATE TABLE sys_user_role (
    id              BIGINT       NOT NULL,
    tenant_id       BIGINT       NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id      BIGINT       NOT NULL,
    version         INT          NOT NULL DEFAULT 0,
    remark          VARCHAR(500) NULL,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_by      BIGINT       NOT NULL DEFAULT 0,
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_by      BIGINT       NOT NULL DEFAULT 0,
    user_id             BIGINT        NOT NULL,           -- ユーザ ID（sys_user.id）
    role_id             BIGINT        NOT NULL,           -- ロール ID（sys_role.id）
    grant_type          SMALLINT      NOT NULL DEFAULT 1, -- 付与種別：1 直接付与 / 2 岗位連動 / 3 代理 / 4 临时
    valid_from          DATE,                             -- 有効開始日
    valid_to            DATE,                             -- 有効終了日（NULL=無期限）
    granted_by          BIGINT        NOT NULL DEFAULT 0, -- 付与者
    granted_at          TIMESTAMPTZ   NOT NULL DEFAULT now(), -- 付与日時
    reason              VARCHAR(500),                     -- 付与理由（高権限ロールは必須）
    status              SMALLINT      NOT NULL DEFAULT 1, -- 状态：1 有效 / 0 解除
    CONSTRAINT pk_sys_user_role PRIMARY KEY (id)
);

ALTER TABLE sys_user_role ENABLE ROW LEVEL SECURITY;
ALTER TABLE sys_user_role FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sys_user_role
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_sys_user_role ON sys_user_role (tenant_id, user_id, role_id, grant_type);
CREATE INDEX idx_sys_user_role_role ON sys_user_role (role_id, status);
COMMENT ON TABLE sys_user_role IS '用户角色（付与履歴付き）';
COMMENT ON COLUMN sys_user_role.user_id IS 'ユーザ ID（sys_user.id）';
COMMENT ON COLUMN sys_user_role.role_id IS 'ロール ID（sys_role.id）';
COMMENT ON COLUMN sys_user_role.grant_type IS '付与種別：1 直接付与 / 2 岗位連動 / 3 代理 / 4 临时';
COMMENT ON COLUMN sys_user_role.valid_from IS '有効開始日';
COMMENT ON COLUMN sys_user_role.valid_to IS '有効終了日（NULL=無期限）';
COMMENT ON COLUMN sys_user_role.granted_by IS '付与者';
COMMENT ON COLUMN sys_user_role.granted_at IS '付与日時';
COMMENT ON COLUMN sys_user_role.reason IS '付与理由（高権限ロールは必須）';
COMMENT ON COLUMN sys_user_role.status IS '状态：1 有效 / 0 解除';
COMMENT ON COLUMN sys_user_role.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN sys_user_role.company_id IS '公司 ID';
COMMENT ON COLUMN sys_user_role.created_at IS '创建时间';
COMMENT ON COLUMN sys_user_role.created_by IS '创建人';
COMMENT ON COLUMN sys_user_role.updated_at IS '更新时间';
COMMENT ON COLUMN sys_user_role.updated_by IS '更新人';
COMMENT ON COLUMN sys_user_role.version IS '乐观锁版本';
COMMENT ON COLUMN sys_user_role.remark IS '备注';

-- sys_role_permission
CREATE TABLE sys_role_permission (
    id              BIGINT       NOT NULL,
    tenant_id       BIGINT       NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id      BIGINT       NOT NULL,
    version         INT          NOT NULL DEFAULT 0,
    remark          VARCHAR(500) NULL,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_by      BIGINT       NOT NULL DEFAULT 0,
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_by      BIGINT       NOT NULL DEFAULT 0,
    role_id             BIGINT        NOT NULL,           -- ロール ID
    menu_id             BIGINT        NOT NULL,           -- メニュー/ボタン ID（sys_menu.id）
    permission_code     VARCHAR(100)  NOT NULL,           -- 権限コード（sys_menu.permission_code のスナップショット）
    granted_by          BIGINT        NOT NULL DEFAULT 0, -- 付与者
    granted_at          TIMESTAMPTZ   NOT NULL DEFAULT now(), -- 付与日時
    CONSTRAINT pk_sys_role_permission PRIMARY KEY (id)
);

ALTER TABLE sys_role_permission ENABLE ROW LEVEL SECURITY;
ALTER TABLE sys_role_permission FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sys_role_permission
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_sys_role_permission ON sys_role_permission (tenant_id, role_id, menu_id);
CREATE INDEX idx_sys_role_permission_code ON sys_role_permission (permission_code);
COMMENT ON TABLE sys_role_permission IS '角色权限（ロール×メニュー/ボタン）';
COMMENT ON COLUMN sys_role_permission.role_id IS 'ロール ID';
COMMENT ON COLUMN sys_role_permission.menu_id IS 'メニュー/ボタン ID（sys_menu.id）';
COMMENT ON COLUMN sys_role_permission.permission_code IS '権限コード（sys_menu.permission_code のスナップショット）';
COMMENT ON COLUMN sys_role_permission.granted_by IS '付与者';
COMMENT ON COLUMN sys_role_permission.granted_at IS '付与日時';
COMMENT ON COLUMN sys_role_permission.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN sys_role_permission.company_id IS '公司 ID';
COMMENT ON COLUMN sys_role_permission.created_at IS '创建时间';
COMMENT ON COLUMN sys_role_permission.created_by IS '创建人';
COMMENT ON COLUMN sys_role_permission.updated_at IS '更新时间';
COMMENT ON COLUMN sys_role_permission.updated_by IS '更新人';
COMMENT ON COLUMN sys_role_permission.version IS '乐观锁版本';
COMMENT ON COLUMN sys_role_permission.remark IS '备注';

-- sys_role_data_scope
CREATE TABLE sys_role_data_scope (
    id              BIGINT       NOT NULL,
    tenant_id       BIGINT       NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id      BIGINT       NOT NULL,
    version         INT          NOT NULL DEFAULT 0,
    remark          VARCHAR(500) NULL,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_by      BIGINT       NOT NULL DEFAULT 0,
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_by      BIGINT       NOT NULL DEFAULT 0,
    role_id             BIGINT        NOT NULL,           -- ロール ID
    resource_code       VARCHAR(100)  NOT NULL,           -- リソース（例 sales:order、'*'=全リソース）
    scope_type          SMALLINT      NOT NULL,           -- 数据范围：1 全社 / 2 本部门及子部门 / 3 本部门 / 4 本人 / 5 自定义 / 6 工場 / 7 倉庫
    factory_ids         JSONB,                            -- 工場 ID 配列（scope_type=6 時必須。例 ["1","2"]、mdm_factory.id）
    warehouse_ids       JSONB,                            -- 倉庫 ID 配列（scope_type=7 時必須。mdm_warehouse.id）
    custom_rule         JSONB,                            -- 自定义规则（scope_type=5 時。例 {"departmentIds":[...],"userIds":[...],"factoryIds":[...],"warehouseIds":[...]}）
    module_code         VARCHAR(32)   NOT NULL DEFAULT '*', -- モジュール名（system/sales/…、'*'=全域）
    description         VARCHAR(500), -- 说明
    CONSTRAINT pk_sys_role_data_scope PRIMARY KEY (id)
);

ALTER TABLE sys_role_data_scope ENABLE ROW LEVEL SECURITY;
ALTER TABLE sys_role_data_scope FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sys_role_data_scope
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_sys_role_data_scope ON sys_role_data_scope (tenant_id, role_id, module_code, resource_code);
CREATE INDEX idx_sys_role_data_scope_factory ON sys_role_data_scope USING gin (factory_ids jsonb_path_ops);
CREATE INDEX idx_sys_role_data_scope_warehouse ON sys_role_data_scope USING gin (warehouse_ids jsonb_path_ops);
COMMENT ON TABLE sys_role_data_scope IS '角色数据范围（リソース単位の上書き。工場/倉庫次元を含む）';
COMMENT ON COLUMN sys_role_data_scope.role_id IS 'ロール ID';
COMMENT ON COLUMN sys_role_data_scope.resource_code IS 'リソース（例 sales:order、''*''=全リソース）';
COMMENT ON COLUMN sys_role_data_scope.scope_type IS '数据范围：1 全社 / 2 本部门及子部门 / 3 本部门 / 4 本人 / 5 自定义 / 6 工場 / 7 倉庫';
COMMENT ON COLUMN sys_role_data_scope.factory_ids IS '工場 ID 配列（scope_type=6 時必須。例 ["1","2"]、mdm_factory.id）';
COMMENT ON COLUMN sys_role_data_scope.warehouse_ids IS '倉庫 ID 配列（scope_type=7 時必須。mdm_warehouse.id）';
COMMENT ON COLUMN sys_role_data_scope.custom_rule IS '自定义规则（scope_type=5 時。例 {"departmentIds":[...],"userIds":[...],"factoryIds":[...],"warehouseIds":[...]}）';
COMMENT ON COLUMN sys_role_data_scope.module_code IS 'モジュール名（system/sales/…、''*''=全域）';
COMMENT ON COLUMN sys_role_data_scope.description IS '说明';
COMMENT ON COLUMN sys_role_data_scope.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN sys_role_data_scope.company_id IS '公司 ID';
COMMENT ON COLUMN sys_role_data_scope.created_at IS '创建时间';
COMMENT ON COLUMN sys_role_data_scope.created_by IS '创建人';
COMMENT ON COLUMN sys_role_data_scope.updated_at IS '更新时间';
COMMENT ON COLUMN sys_role_data_scope.updated_by IS '更新人';
COMMENT ON COLUMN sys_role_data_scope.version IS '乐观锁版本';
COMMENT ON COLUMN sys_role_data_scope.remark IS '备注';

-- sys_user_data_scope
CREATE TABLE sys_user_data_scope (
    id              BIGINT       NOT NULL,
    tenant_id       BIGINT       NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id      BIGINT       NOT NULL,
    version         INT          NOT NULL DEFAULT 0,
    remark          VARCHAR(500) NULL,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_by      BIGINT       NOT NULL DEFAULT 0,
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_by      BIGINT       NOT NULL DEFAULT 0,
    user_id             BIGINT        NOT NULL,           -- ユーザ ID
    resource_code       VARCHAR(100)  NOT NULL,           -- リソース（'*'=全リソース）
    scope_type          SMALLINT      NOT NULL,           -- データ範囲（3.10 と同一値域 1〜7）
    factory_ids         JSONB,                            -- 工場 ID 配列（scope_type=6 時必須）
    warehouse_ids       JSONB,                            -- 倉庫 ID 配列（scope_type=7 時必須）
    custom_rule         JSONB,                            -- 自定义规则（factoryIds/warehouseIds を含む）
    valid_from          DATE,                             -- 有効開始日
    valid_to            DATE,                             -- 有効終了日
    reason              VARCHAR(500)  NOT NULL,           -- 上書き理由（必須）
    granted_by          BIGINT        NOT NULL DEFAULT 0, -- 付与者
    CONSTRAINT pk_sys_user_data_scope PRIMARY KEY (id)
);

ALTER TABLE sys_user_data_scope ENABLE ROW LEVEL SECURITY;
ALTER TABLE sys_user_data_scope FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sys_user_data_scope
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_sys_user_data_scope ON sys_user_data_scope (tenant_id, user_id, resource_code);
CREATE INDEX idx_sys_user_data_scope_user ON sys_user_data_scope (user_id, valid_to);
COMMENT ON TABLE sys_user_data_scope IS '用户数据范围（個別上書き。工場/倉庫次元を含む）';
COMMENT ON COLUMN sys_user_data_scope.user_id IS 'ユーザ ID';
COMMENT ON COLUMN sys_user_data_scope.resource_code IS 'リソース（''*''=全リソース）';
COMMENT ON COLUMN sys_user_data_scope.scope_type IS 'データ範囲（3.10 と同一値域 1〜7）';
COMMENT ON COLUMN sys_user_data_scope.factory_ids IS '工場 ID 配列（scope_type=6 時必須）';
COMMENT ON COLUMN sys_user_data_scope.warehouse_ids IS '倉庫 ID 配列（scope_type=7 時必須）';
COMMENT ON COLUMN sys_user_data_scope.custom_rule IS '自定义规则（factoryIds/warehouseIds を含む）';
COMMENT ON COLUMN sys_user_data_scope.valid_from IS '有効開始日';
COMMENT ON COLUMN sys_user_data_scope.valid_to IS '有効終了日';
COMMENT ON COLUMN sys_user_data_scope.reason IS '上書き理由（必須）';
COMMENT ON COLUMN sys_user_data_scope.granted_by IS '付与者';
COMMENT ON COLUMN sys_user_data_scope.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN sys_user_data_scope.company_id IS '公司 ID';
COMMENT ON COLUMN sys_user_data_scope.created_at IS '创建时间';
COMMENT ON COLUMN sys_user_data_scope.created_by IS '创建人';
COMMENT ON COLUMN sys_user_data_scope.updated_at IS '更新时间';
COMMENT ON COLUMN sys_user_data_scope.updated_by IS '更新人';
COMMENT ON COLUMN sys_user_data_scope.version IS '乐观锁版本';
COMMENT ON COLUMN sys_user_data_scope.remark IS '备注';

-- sys_menu
CREATE TABLE sys_menu (
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
    menu_code           VARCHAR(64)   NOT NULL,           -- 菜单代码（一意）
    menu_name           VARCHAR(100)  NOT NULL,           -- 菜单名称
    menu_type           SMALLINT      NOT NULL,           -- 类型：1 目录 / 2 菜单 / 3 按钮 / 4 外链
    parent_id           BIGINT        NOT NULL DEFAULT 0, -- 父菜单 ID（0=ルート）
    module_code         VARCHAR(32)   NOT NULL,           -- 模块名（system/sales/mdm/…）
    route_path          VARCHAR(300),                     -- 前端路由路径（例 /system/users）
    component_path      VARCHAR(300),                     -- コンポーネントパス（例 system/user/index）
    permission_code     VARCHAR(100),                     -- 权限代码（例 system:user:view）
    icon                VARCHAR(64),                      -- アイコン
    is_external         BOOLEAN       NOT NULL DEFAULT FALSE, -- 外部リンク
    external_url        VARCHAR(500),                     -- 外部 URL
    is_visible          BOOLEAN       NOT NULL DEFAULT TRUE,  -- メニュー表示
    is_cache            BOOLEAN       NOT NULL DEFAULT FALSE, -- keep-alive
    is_affix           BOOLEAN       NOT NULL DEFAULT FALSE, -- 固定タブ
    sort_no             INT           NOT NULL DEFAULT 0, -- 表示顺
    status              SMALLINT      NOT NULL DEFAULT 1, -- 状态：1 有效 / 0 无效
    description         VARCHAR(500), -- 说明
    CONSTRAINT pk_sys_menu PRIMARY KEY (id)
);

ALTER TABLE sys_menu ENABLE ROW LEVEL SECURITY;
ALTER TABLE sys_menu FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sys_menu
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_sys_menu_code ON sys_menu (tenant_id, menu_code) WHERE deleted = FALSE;
CREATE UNIQUE INDEX uk_sys_menu_permission ON sys_menu (tenant_id, permission_code) WHERE deleted = FALSE AND permission_code IS NOT NULL;
CREATE INDEX idx_sys_menu_parent ON sys_menu (parent_id, sort_no);
CREATE INDEX idx_sys_menu_module ON sys_menu (module_code, menu_type);
COMMENT ON TABLE sys_menu IS '菜单/权限（メニューツリー＋ボタン権限）';
COMMENT ON COLUMN sys_menu.menu_code IS '菜单代码（一意）';
COMMENT ON COLUMN sys_menu.menu_name IS '菜单名称';
COMMENT ON COLUMN sys_menu.menu_type IS '类型：1 目录 / 2 菜单 / 3 按钮 / 4 外链';
COMMENT ON COLUMN sys_menu.parent_id IS '父菜单 ID（0=ルート）';
COMMENT ON COLUMN sys_menu.module_code IS '模块名（system/sales/mdm/…）';
COMMENT ON COLUMN sys_menu.route_path IS '前端路由路径（例 /system/users）';
COMMENT ON COLUMN sys_menu.component_path IS 'コンポーネントパス（例 system/user/index）';
COMMENT ON COLUMN sys_menu.permission_code IS '权限代码（例 system:user:view）';
COMMENT ON COLUMN sys_menu.icon IS 'アイコン';
COMMENT ON COLUMN sys_menu.is_external IS '外部リンク';
COMMENT ON COLUMN sys_menu.external_url IS '外部 URL';
COMMENT ON COLUMN sys_menu.is_visible IS 'メニュー表示';
COMMENT ON COLUMN sys_menu.is_cache IS 'keep-alive';
COMMENT ON COLUMN sys_menu.is_affix IS '固定タブ';
COMMENT ON COLUMN sys_menu.sort_no IS '表示顺';
COMMENT ON COLUMN sys_menu.status IS '状态：1 有效 / 0 无效';
COMMENT ON COLUMN sys_menu.description IS '说明';
COMMENT ON COLUMN sys_menu.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN sys_menu.company_id IS '公司 ID';
COMMENT ON COLUMN sys_menu.created_at IS '创建时间';
COMMENT ON COLUMN sys_menu.created_by IS '创建人';
COMMENT ON COLUMN sys_menu.updated_at IS '更新时间';
COMMENT ON COLUMN sys_menu.updated_by IS '更新人';
COMMENT ON COLUMN sys_menu.version IS '乐观锁版本';
COMMENT ON COLUMN sys_menu.deleted IS '逻辑删除';
COMMENT ON COLUMN sys_menu.remark IS '备注';
COMMENT ON COLUMN sys_menu.ext_data IS '扩展字段';

-- sys_dict_type
CREATE TABLE sys_dict_type (
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
    dict_code           VARCHAR(64)   NOT NULL,           -- 字典代码（例 CUSTOMER_GRADE）
    dict_name           VARCHAR(100)  NOT NULL,           -- 字典名称
    module_code         VARCHAR(32)   NOT NULL,           -- 所辖模块（system/mdm/sales/…）
    is_system           BOOLEAN       NOT NULL DEFAULT FALSE, -- 系统内置（削除不可）
    is_tree             BOOLEAN       NOT NULL DEFAULT FALSE, -- ツリー辞書（項目に parent_id を許可）
    status              SMALLINT      NOT NULL DEFAULT 1, -- 状态：1 有效 / 0 无效
    description         VARCHAR(500), -- 说明
    CONSTRAINT pk_sys_dict_type PRIMARY KEY (id)
);

ALTER TABLE sys_dict_type ENABLE ROW LEVEL SECURITY;
ALTER TABLE sys_dict_type FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sys_dict_type
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_sys_dict_type_code ON sys_dict_type (tenant_id, dict_code) WHERE deleted = FALSE;
CREATE INDEX idx_sys_dict_type_module ON sys_dict_type (module_code, status);
COMMENT ON TABLE sys_dict_type IS '数据字典类型';
COMMENT ON COLUMN sys_dict_type.dict_code IS '字典代码（例 CUSTOMER_GRADE）';
COMMENT ON COLUMN sys_dict_type.dict_name IS '字典名称';
COMMENT ON COLUMN sys_dict_type.module_code IS '所辖模块（system/mdm/sales/…）';
COMMENT ON COLUMN sys_dict_type.is_system IS '系统内置（削除不可）';
COMMENT ON COLUMN sys_dict_type.is_tree IS 'ツリー辞書（項目に parent_id を許可）';
COMMENT ON COLUMN sys_dict_type.status IS '状态：1 有效 / 0 无效';
COMMENT ON COLUMN sys_dict_type.description IS '说明';
COMMENT ON COLUMN sys_dict_type.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN sys_dict_type.company_id IS '公司 ID';
COMMENT ON COLUMN sys_dict_type.created_at IS '创建时间';
COMMENT ON COLUMN sys_dict_type.created_by IS '创建人';
COMMENT ON COLUMN sys_dict_type.updated_at IS '更新时间';
COMMENT ON COLUMN sys_dict_type.updated_by IS '更新人';
COMMENT ON COLUMN sys_dict_type.version IS '乐观锁版本';
COMMENT ON COLUMN sys_dict_type.deleted IS '逻辑删除';
COMMENT ON COLUMN sys_dict_type.remark IS '备注';
COMMENT ON COLUMN sys_dict_type.ext_data IS '扩展字段';

-- sys_dict_item
CREATE TABLE sys_dict_item (
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
    dict_type_id        BIGINT        NOT NULL,           -- 字典类型 ID（sys_dict_type.id）
    item_code           VARCHAR(64)   NOT NULL,           -- 项目代码（一意、大文字推奨）
    item_name           VARCHAR(200)  NOT NULL,           -- 项目名称（表示名）
    item_value          VARCHAR(200),                     -- 项目值（省略時は item_code と同値）
    parent_id           BIGINT        NOT NULL DEFAULT 0, -- 親項目（ツリー辞書用）
    sort_no             INT           NOT NULL DEFAULT 0, -- 表示顺
    tag_type            VARCHAR(32),                      -- 表示色（Element Plus: success/warning/danger/info）
    is_default          BOOLEAN       NOT NULL DEFAULT FALSE, -- 既定値
    status              SMALLINT      NOT NULL DEFAULT 1, -- 状态：1 有效 / 0 无效
    description         VARCHAR(500), -- 说明
    CONSTRAINT pk_sys_dict_item PRIMARY KEY (id)
);

ALTER TABLE sys_dict_item ENABLE ROW LEVEL SECURITY;
ALTER TABLE sys_dict_item FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sys_dict_item
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_sys_dict_item ON sys_dict_item (tenant_id, dict_type_id, item_code) WHERE deleted = FALSE;
CREATE INDEX idx_sys_dict_item_type ON sys_dict_item (dict_type_id, status, sort_no);
COMMENT ON TABLE sys_dict_item IS '数据字典项目';
COMMENT ON COLUMN sys_dict_item.dict_type_id IS '字典类型 ID（sys_dict_type.id）';
COMMENT ON COLUMN sys_dict_item.item_code IS '项目代码（一意、大文字推奨）';
COMMENT ON COLUMN sys_dict_item.item_name IS '项目名称（表示名）';
COMMENT ON COLUMN sys_dict_item.item_value IS '项目值（省略時は item_code と同値）';
COMMENT ON COLUMN sys_dict_item.parent_id IS '親項目（ツリー辞書用）';
COMMENT ON COLUMN sys_dict_item.sort_no IS '表示顺';
COMMENT ON COLUMN sys_dict_item.tag_type IS '表示色（Element Plus: success/warning/danger/info）';
COMMENT ON COLUMN sys_dict_item.is_default IS '既定値';
COMMENT ON COLUMN sys_dict_item.status IS '状态：1 有效 / 0 无效';
COMMENT ON COLUMN sys_dict_item.description IS '说明';
COMMENT ON COLUMN sys_dict_item.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN sys_dict_item.company_id IS '公司 ID';
COMMENT ON COLUMN sys_dict_item.created_at IS '创建时间';
COMMENT ON COLUMN sys_dict_item.created_by IS '创建人';
COMMENT ON COLUMN sys_dict_item.updated_at IS '更新时间';
COMMENT ON COLUMN sys_dict_item.updated_by IS '更新人';
COMMENT ON COLUMN sys_dict_item.version IS '乐观锁版本';
COMMENT ON COLUMN sys_dict_item.deleted IS '逻辑删除';
COMMENT ON COLUMN sys_dict_item.remark IS '备注';
COMMENT ON COLUMN sys_dict_item.ext_data IS '扩展字段';

-- sys_number_rule
CREATE TABLE sys_number_rule (
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
    rule_code           VARCHAR(64)   NOT NULL,           -- 规则代码（例 SALES_ORDER、PURCHASE_ORDER）
    rule_name           VARCHAR(100)  NOT NULL,           -- 规则名称
    module_code         VARCHAR(32)   NOT NULL,           -- モジュール名
    biz_type            VARCHAR(64),                      -- 業務類型（任意）
    prefix              VARCHAR(10)   NOT NULL,           -- プレフィックス（例 SO、PO、C）
    date_format         VARCHAR(16)   NOT NULL DEFAULT 'yyMMdd', -- 日付部分形式（Java DateTimeFormatter 記法）
    seq_length          SMALLINT      NOT NULL DEFAULT 4, -- 連番桁数（1〜10）
    reset_cycle         SMALLINT      NOT NULL DEFAULT 1, -- リセット周期：1 日次 / 2 月次 / 3 年次 / 4 無
    start_value         BIGINT        NOT NULL DEFAULT 1, -- 連番初期値
    separator           VARCHAR(2)    NOT NULL DEFAULT '', -- 区切り文字（保存値には付けない、表示時のみ）
    example_value       VARCHAR(64),                      -- プレビュー例（保存時に自動生成）
    effective_from      DATE          NOT NULL,           -- 適用開始日
    is_locked           BOOLEAN       NOT NULL DEFAULT FALSE, -- 使用中ロック（承認済伝票あり=変更不可）
    status              SMALLINT      NOT NULL DEFAULT 1, -- 状态：1 有效 / 0 无效
    description         VARCHAR(500), -- 说明
    CONSTRAINT pk_sys_number_rule PRIMARY KEY (id)
);

ALTER TABLE sys_number_rule ENABLE ROW LEVEL SECURITY;
ALTER TABLE sys_number_rule FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sys_number_rule
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_sys_number_rule_code ON sys_number_rule (tenant_id, rule_code) WHERE deleted = FALSE;
CREATE INDEX idx_sys_number_rule_status ON sys_number_rule (status, module_code);
COMMENT ON TABLE sys_number_rule IS '编号规则（採番ルール）';
COMMENT ON COLUMN sys_number_rule.rule_code IS '规则代码（例 SALES_ORDER、PURCHASE_ORDER）';
COMMENT ON COLUMN sys_number_rule.rule_name IS '规则名称';
COMMENT ON COLUMN sys_number_rule.module_code IS 'モジュール名';
COMMENT ON COLUMN sys_number_rule.biz_type IS '業務類型（任意）';
COMMENT ON COLUMN sys_number_rule.prefix IS 'プレフィックス（例 SO、PO、C）';
COMMENT ON COLUMN sys_number_rule.date_format IS '日付部分形式（Java DateTimeFormatter 記法）';
COMMENT ON COLUMN sys_number_rule.seq_length IS '連番桁数（1〜10）';
COMMENT ON COLUMN sys_number_rule.reset_cycle IS 'リセット周期：1 日次 / 2 月次 / 3 年次 / 4 無';
COMMENT ON COLUMN sys_number_rule.start_value IS '連番初期値';
COMMENT ON COLUMN sys_number_rule.separator IS '区切り文字（保存値には付けない、表示時のみ）';
COMMENT ON COLUMN sys_number_rule.example_value IS 'プレビュー例（保存時に自動生成）';
COMMENT ON COLUMN sys_number_rule.effective_from IS '適用開始日';
COMMENT ON COLUMN sys_number_rule.is_locked IS '使用中ロック（承認済伝票あり=変更不可）';
COMMENT ON COLUMN sys_number_rule.status IS '状态：1 有效 / 0 无效';
COMMENT ON COLUMN sys_number_rule.description IS '说明';
COMMENT ON COLUMN sys_number_rule.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN sys_number_rule.company_id IS '公司 ID';
COMMENT ON COLUMN sys_number_rule.created_at IS '创建时间';
COMMENT ON COLUMN sys_number_rule.created_by IS '创建人';
COMMENT ON COLUMN sys_number_rule.updated_at IS '更新时间';
COMMENT ON COLUMN sys_number_rule.updated_by IS '更新人';
COMMENT ON COLUMN sys_number_rule.version IS '乐观锁版本';
COMMENT ON COLUMN sys_number_rule.deleted IS '逻辑删除';
COMMENT ON COLUMN sys_number_rule.remark IS '备注';
COMMENT ON COLUMN sys_number_rule.ext_data IS '扩展字段';

-- sys_audit_log
CREATE TABLE sys_audit_log (
    id              BIGINT       NOT NULL,
    tenant_id       BIGINT       NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id      BIGINT       NOT NULL,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_by      BIGINT       NOT NULL DEFAULT 0,
    trace_id            VARCHAR(64),                      -- リクエスト追跡 ID（X-Request-Id）
    user_id             BIGINT        NOT NULL DEFAULT 0, -- 操作者（未ログイン=0）
    username            VARCHAR(64),                      -- 操作者アカウント（スナップショット）
    operation_type      VARCHAR(32)   NOT NULL,           -- 操作種別：LOGIN/LOGOUT/CREATE/UPDATE/DELETE/SUBMIT/APPROVE/REJECT/EXPORT/IMPORT/PRINT/POST/REVERSE/CLOSE
    module_code         VARCHAR(32)   NOT NULL,           -- 模块名
    resource_code       VARCHAR(64)   NOT NULL,           -- リソース名（例 user、sales-order）
    resource_id         VARCHAR(64),                      -- 対象 ID
    resource_no         VARCHAR(64),                      -- 対象業務番号（例 SO2610200001）
    before_data         JSONB,                            -- 変更前（マスタ・重要項目のみ。パスワード等は含めない）
    after_data          JSONB,                            -- 変更後
    ip_address          VARCHAR(45),                      -- IPv4/IPv6
    user_agent          VARCHAR(500),                     -- UA
    result              SMALLINT      NOT NULL DEFAULT 1, -- 1 成功 / 0 失敗
    error_message       VARCHAR(1000),                    -- 失敗理由
    duration_ms         INT,                              -- 処理時間（ミリ秒）
    occurred_at         TIMESTAMPTZ   NOT NULL DEFAULT now(), -- 発生日時
    CONSTRAINT pk_sys_audit_log PRIMARY KEY (id)
);

ALTER TABLE sys_audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE sys_audit_log FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sys_audit_log
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE INDEX idx_sys_audit_log_time ON sys_audit_log (occurred_at DESC);
CREATE INDEX idx_sys_audit_log_user ON sys_audit_log (user_id, occurred_at DESC);
CREATE INDEX idx_sys_audit_log_resource ON sys_audit_log (module_code, resource_code, resource_id);
CREATE INDEX idx_sys_audit_log_type ON sys_audit_log (operation_type, result, occurred_at DESC);
COMMENT ON TABLE sys_audit_log IS '操作审计日志（追記専用）';
COMMENT ON COLUMN sys_audit_log.trace_id IS 'リクエスト追跡 ID（X-Request-Id）';
COMMENT ON COLUMN sys_audit_log.user_id IS '操作者（未ログイン=0）';
COMMENT ON COLUMN sys_audit_log.username IS '操作者アカウント（スナップショット）';
COMMENT ON COLUMN sys_audit_log.operation_type IS '操作種別：LOGIN/LOGOUT/CREATE/UPDATE/DELETE/SUBMIT/APPROVE/REJECT/EXPORT/IMPORT/PRINT/POST/REVERSE/CLOSE';
COMMENT ON COLUMN sys_audit_log.module_code IS '模块名';
COMMENT ON COLUMN sys_audit_log.resource_code IS 'リソース名（例 user、sales-order）';
COMMENT ON COLUMN sys_audit_log.resource_id IS '対象 ID';
COMMENT ON COLUMN sys_audit_log.resource_no IS '対象業務番号（例 SO2610200001）';
COMMENT ON COLUMN sys_audit_log.before_data IS '変更前（マスタ・重要項目のみ。パスワード等は含めない）';
COMMENT ON COLUMN sys_audit_log.after_data IS '変更後';
COMMENT ON COLUMN sys_audit_log.ip_address IS 'IPv4/IPv6';
COMMENT ON COLUMN sys_audit_log.user_agent IS 'UA';
COMMENT ON COLUMN sys_audit_log.result IS '1 成功 / 0 失敗';
COMMENT ON COLUMN sys_audit_log.error_message IS '失敗理由';
COMMENT ON COLUMN sys_audit_log.duration_ms IS '処理時間（ミリ秒）';
COMMENT ON COLUMN sys_audit_log.occurred_at IS '発生日時';
COMMENT ON COLUMN sys_audit_log.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN sys_audit_log.company_id IS '公司 ID';
COMMENT ON COLUMN sys_audit_log.created_at IS '创建时间';
COMMENT ON COLUMN sys_audit_log.created_by IS '创建人';

-- sys_login_log
CREATE TABLE sys_login_log (
    id              BIGINT       NOT NULL,
    tenant_id       BIGINT       NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id      BIGINT       NOT NULL,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_by      BIGINT       NOT NULL DEFAULT 0,
    user_id             BIGINT,                           -- ユーザ ID（不存在ユーザは NULL）
    username            VARCHAR(64)   NOT NULL,           -- ログイン試行アカウント
    login_type          SMALLINT      NOT NULL DEFAULT 1, -- 認証種別：1 密码 / 2 验证码 / 3 SSO / 4 刷新
    login_result        SMALLINT      NOT NULL,           -- 1 成功 / 0 失敗
    fail_reason         VARCHAR(200),                     -- 失敗理由（MSG-COM-021/022/023 等）
    ip_address          VARCHAR(45),                      -- IP
    location            VARCHAR(100),                     -- 地域（IP から推定、任意）
    user_agent          VARCHAR(500),                     -- UA
    device_type         SMALLINT,                         -- 端末：1 PC / 2 移动 / 3 API
    session_id          VARCHAR(100),                     -- Sa-Token セッション ID（成功時）
    occurred_at         TIMESTAMPTZ   NOT NULL DEFAULT now(), -- 発生日時
    CONSTRAINT pk_sys_login_log PRIMARY KEY (id)
);

ALTER TABLE sys_login_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE sys_login_log FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sys_login_log
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE INDEX idx_sys_login_log_user_time ON sys_login_log (username, occurred_at DESC);
CREATE INDEX idx_sys_login_log_result ON sys_login_log (login_result, occurred_at DESC);
CREATE INDEX idx_sys_login_log_ip ON sys_login_log (ip_address, occurred_at DESC);
COMMENT ON TABLE sys_login_log IS '登录日志（認証履歴）';
COMMENT ON COLUMN sys_login_log.user_id IS 'ユーザ ID（不存在ユーザは NULL）';
COMMENT ON COLUMN sys_login_log.username IS 'ログイン試行アカウント';
COMMENT ON COLUMN sys_login_log.login_type IS '認証種別：1 密码 / 2 验证码 / 3 SSO / 4 刷新';
COMMENT ON COLUMN sys_login_log.login_result IS '1 成功 / 0 失敗';
COMMENT ON COLUMN sys_login_log.fail_reason IS '失敗理由（MSG-COM-021/022/023 等）';
COMMENT ON COLUMN sys_login_log.ip_address IS 'IP';
COMMENT ON COLUMN sys_login_log.location IS '地域（IP から推定、任意）';
COMMENT ON COLUMN sys_login_log.user_agent IS 'UA';
COMMENT ON COLUMN sys_login_log.device_type IS '端末：1 PC / 2 移动 / 3 API';
COMMENT ON COLUMN sys_login_log.session_id IS 'Sa-Token セッション ID（成功時）';
COMMENT ON COLUMN sys_login_log.occurred_at IS '発生日時';
COMMENT ON COLUMN sys_login_log.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN sys_login_log.company_id IS '公司 ID';
COMMENT ON COLUMN sys_login_log.created_at IS '创建时间';
COMMENT ON COLUMN sys_login_log.created_by IS '创建人';

-- sys_user_password_history
CREATE TABLE sys_user_password_history (
    id              BIGINT       NOT NULL,
    tenant_id       BIGINT       NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_by      BIGINT       NOT NULL DEFAULT 0,
    user_id             BIGINT        NOT NULL,           -- ユーザ ID
    password_hash       VARCHAR(100)  NOT NULL,           -- BCrypt ハッシュ
    change_type         SMALLINT      NOT NULL,           -- 変更種別：1 初期設定 / 2 本人変更 / 3 管理者リセット / 4 強制失効
    changed_by          BIGINT        NOT NULL DEFAULT 0, -- 変更者（本人=user_id、管理者=管理者 ID）
    CONSTRAINT pk_sys_user_password_history PRIMARY KEY (id)
);

ALTER TABLE sys_user_password_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE sys_user_password_history FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sys_user_password_history
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE INDEX idx_sys_user_password_history_user ON sys_user_password_history (user_id, created_at DESC);
COMMENT ON TABLE sys_user_password_history IS '密码历史（再利用禁止判定）';
COMMENT ON COLUMN sys_user_password_history.user_id IS 'ユーザ ID';
COMMENT ON COLUMN sys_user_password_history.password_hash IS 'BCrypt ハッシュ';
COMMENT ON COLUMN sys_user_password_history.change_type IS '変更種別：1 初期設定 / 2 本人変更 / 3 管理者リセット / 4 強制失効';
COMMENT ON COLUMN sys_user_password_history.changed_by IS '変更者（本人=user_id、管理者=管理者 ID）';
COMMENT ON COLUMN sys_user_password_history.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN sys_user_password_history.created_at IS '创建时间';
COMMENT ON COLUMN sys_user_password_history.created_by IS '创建人';

-- sys_attachment
CREATE TABLE sys_attachment (
    id              BIGINT       NOT NULL,
    tenant_id       BIGINT       NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id      BIGINT       NOT NULL,
    version         INT          NOT NULL DEFAULT 0,
    deleted         BOOLEAN      NOT NULL DEFAULT FALSE,
    remark          VARCHAR(500) NULL,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_by      BIGINT       NOT NULL DEFAULT 0,
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_by      BIGINT       NOT NULL DEFAULT 0,

    attachment_no       VARCHAR(32)   NOT NULL,           -- 附件编号（ATT+yyMMdd+連番）
    original_name       VARCHAR(255)  NOT NULL,           -- 元ファイル名
    file_name           VARCHAR(255)  NOT NULL,           -- 保存ファイル名（UUID.ext）
    file_ext            VARCHAR(16)   NOT NULL,           -- 拡張子（小文字）
    mime_type           VARCHAR(100),                     -- MIME 类型
    file_size           BIGINT        NOT NULL,           -- サイズ（byte）
    storage_type        SMALLINT      NOT NULL DEFAULT 1, -- 保存类型：1 本地 / 2 S3/MinIO
    storage_path        VARCHAR(500)  NOT NULL,           -- 保存パス／オブジェクトキー
    sha256              CHAR(64)      NOT NULL,           -- SHA-256（完全性検査）
    upload_user_id      BIGINT        NOT NULL,           -- アップロード者
    virus_scan_status   SMALLINT      NOT NULL DEFAULT 0, -- スキャン：0 未実施 / 1 合格 / 2 不合格 / 3 失敗
    download_count      INT           NOT NULL DEFAULT 0, -- ダウンロード回数
    expire_at           TIMESTAMPTZ,                      -- 一時ファイルの有効期限（業務添付は NULL）
    status              SMALLINT      NOT NULL DEFAULT 1, -- 状态：1 有效 / 0 削除
    CONSTRAINT pk_sys_attachment PRIMARY KEY (id)
);

ALTER TABLE sys_attachment ENABLE ROW LEVEL SECURITY;
ALTER TABLE sys_attachment FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sys_attachment
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_sys_attachment_no ON sys_attachment (tenant_id, attachment_no) WHERE deleted = FALSE;
CREATE INDEX idx_sys_attachment_sha ON sys_attachment (sha256);
CREATE INDEX idx_sys_attachment_user ON sys_attachment (upload_user_id, created_at DESC);
CREATE INDEX idx_sys_attachment_expire ON sys_attachment (expire_at) WHERE expire_at IS NOT NULL;
COMMENT ON TABLE sys_attachment IS '附件（ファイルメタ情報）';
COMMENT ON COLUMN sys_attachment.attachment_no IS '附件编号（ATT+yyMMdd+連番）';
COMMENT ON COLUMN sys_attachment.original_name IS '元ファイル名';
COMMENT ON COLUMN sys_attachment.file_name IS '保存ファイル名（UUID.ext）';
COMMENT ON COLUMN sys_attachment.file_ext IS '拡張子（小文字）';
COMMENT ON COLUMN sys_attachment.mime_type IS 'MIME 类型';
COMMENT ON COLUMN sys_attachment.file_size IS 'サイズ（byte）';
COMMENT ON COLUMN sys_attachment.storage_type IS '保存类型：1 本地 / 2 S3/MinIO';
COMMENT ON COLUMN sys_attachment.storage_path IS '保存パス／オブジェクトキー';
COMMENT ON COLUMN sys_attachment.sha256 IS 'SHA-256（完全性検査）';
COMMENT ON COLUMN sys_attachment.upload_user_id IS 'アップロード者';
COMMENT ON COLUMN sys_attachment.virus_scan_status IS 'スキャン：0 未実施 / 1 合格 / 2 不合格 / 3 失敗';
COMMENT ON COLUMN sys_attachment.download_count IS 'ダウンロード回数';
COMMENT ON COLUMN sys_attachment.expire_at IS '一時ファイルの有効期限（業務添付は NULL）';
COMMENT ON COLUMN sys_attachment.status IS '状态：1 有效 / 0 削除';
COMMENT ON COLUMN sys_attachment.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN sys_attachment.company_id IS '公司 ID';
COMMENT ON COLUMN sys_attachment.created_at IS '创建时间';
COMMENT ON COLUMN sys_attachment.created_by IS '创建人';
COMMENT ON COLUMN sys_attachment.updated_at IS '更新时间';
COMMENT ON COLUMN sys_attachment.updated_by IS '更新人';
COMMENT ON COLUMN sys_attachment.version IS '乐观锁版本';
COMMENT ON COLUMN sys_attachment.deleted IS '逻辑删除';
COMMENT ON COLUMN sys_attachment.remark IS '备注';

-- sys_attachment_biz
CREATE TABLE sys_attachment_biz (
    id              BIGINT       NOT NULL,
    tenant_id       BIGINT       NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id      BIGINT       NOT NULL,
    version         INT          NOT NULL DEFAULT 0,
    remark          VARCHAR(500) NULL,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_by      BIGINT       NOT NULL DEFAULT 0,
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_by      BIGINT       NOT NULL DEFAULT 0,
    attachment_id       BIGINT        NOT NULL,           -- 附件 ID
    biz_type            VARCHAR(64)   NOT NULL,           -- 業務種別（例 SALES_ORDER、PURCHASE_ORDER、WORKFLOW_TASK）
    biz_id              BIGINT        NOT NULL,           -- 業務 ID
    file_category       VARCHAR(32),                      -- 文件分类（例 CONTRACT、DRAWING、INVOICE、OTHER）
    sort_no             INT           NOT NULL DEFAULT 0, -- 表示顺
    is_primary          BOOLEAN       NOT NULL DEFAULT FALSE, -- 主附件（帳票・一覧に表示）
    CONSTRAINT pk_sys_attachment_biz PRIMARY KEY (id)
);

ALTER TABLE sys_attachment_biz ENABLE ROW LEVEL SECURITY;
ALTER TABLE sys_attachment_biz FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sys_attachment_biz
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_sys_attachment_biz ON sys_attachment_biz (tenant_id, attachment_id, biz_type, biz_id);
CREATE INDEX idx_sys_attachment_biz ON sys_attachment_biz (biz_type, biz_id, sort_no);
COMMENT ON TABLE sys_attachment_biz IS '附件业务关联（業務×附件）';
COMMENT ON COLUMN sys_attachment_biz.attachment_id IS '附件 ID';
COMMENT ON COLUMN sys_attachment_biz.biz_type IS '業務種別（例 SALES_ORDER、PURCHASE_ORDER、WORKFLOW_TASK）';
COMMENT ON COLUMN sys_attachment_biz.biz_id IS '業務 ID';
COMMENT ON COLUMN sys_attachment_biz.file_category IS '文件分类（例 CONTRACT、DRAWING、INVOICE、OTHER）';
COMMENT ON COLUMN sys_attachment_biz.sort_no IS '表示顺';
COMMENT ON COLUMN sys_attachment_biz.is_primary IS '主附件（帳票・一覧に表示）';
COMMENT ON COLUMN sys_attachment_biz.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN sys_attachment_biz.company_id IS '公司 ID';
COMMENT ON COLUMN sys_attachment_biz.created_at IS '创建时间';
COMMENT ON COLUMN sys_attachment_biz.created_by IS '创建人';
COMMENT ON COLUMN sys_attachment_biz.updated_at IS '更新时间';
COMMENT ON COLUMN sys_attachment_biz.updated_by IS '更新人';
COMMENT ON COLUMN sys_attachment_biz.version IS '乐观锁版本';
COMMENT ON COLUMN sys_attachment_biz.remark IS '备注';

-- sys_notification
CREATE TABLE sys_notification (
    id              BIGINT       NOT NULL,
    tenant_id       BIGINT       NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id      BIGINT       NOT NULL,
    version         INT          NOT NULL DEFAULT 0,
    remark          VARCHAR(500) NULL,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_by      BIGINT       NOT NULL DEFAULT 0,
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_by      BIGINT       NOT NULL DEFAULT 0,
    notification_no     VARCHAR(32)   NOT NULL,           -- 通知编号（NTF+yyMMdd+連番）
    notification_type   SMALLINT      NOT NULL DEFAULT 1, -- 类型：1 系统通知 / 2 业务提醒 / 3 审批通知 / 4 告警
    biz_scene           VARCHAR(64),                      -- 業務シーン（例 WORKFLOW_TASK_CREATED、BATCH_FAILED）
    biz_type            VARCHAR(64),                      -- 関連業務種別
    biz_id              BIGINT,                           -- 関連業務 ID
    template_code       VARCHAR(64),                      -- 使用テンプレート（sys_notification_template.template_code）
    title               VARCHAR(200)  NOT NULL,           -- タイトル
    content             TEXT          NOT NULL,           -- 本文（プレースホルダ置換済み）
    related_url         VARCHAR(500),                     -- 関連画面 URL（フロントルート）
    priority            SMALLINT      NOT NULL DEFAULT 2, -- 優先度：1 高 / 2 中 / 3 低
    sender_id           BIGINT        NOT NULL DEFAULT 0, -- 送信者（0=システム）
    send_status         SMALLINT      NOT NULL DEFAULT 0, -- 送信：0 待送 / 1 送信中 / 2 成功 / 3 一部失敗 / 4 失敗
    expire_at           TIMESTAMPTZ, -- 表示期限（NULL=無期限）
    CONSTRAINT pk_sys_notification PRIMARY KEY (id)
);

ALTER TABLE sys_notification ENABLE ROW LEVEL SECURITY;
ALTER TABLE sys_notification FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sys_notification
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_sys_notification_no ON sys_notification (tenant_id, notification_no);
CREATE INDEX idx_sys_notification_scene ON sys_notification (biz_scene, created_at DESC);
CREATE INDEX idx_sys_notification_status ON sys_notification (send_status, created_at);
CREATE INDEX idx_sys_notification_expire ON sys_notification (expire_at) WHERE expire_at IS NOT NULL;
COMMENT ON TABLE sys_notification IS '站内通知（通知本体）';
COMMENT ON COLUMN sys_notification.notification_no IS '通知编号（NTF+yyMMdd+連番）';
COMMENT ON COLUMN sys_notification.notification_type IS '类型：1 系统通知 / 2 业务提醒 / 3 审批通知 / 4 告警';
COMMENT ON COLUMN sys_notification.biz_scene IS '業務シーン（例 WORKFLOW_TASK_CREATED、BATCH_FAILED）';
COMMENT ON COLUMN sys_notification.biz_type IS '関連業務種別';
COMMENT ON COLUMN sys_notification.biz_id IS '関連業務 ID';
COMMENT ON COLUMN sys_notification.template_code IS '使用テンプレート（sys_notification_template.template_code）';
COMMENT ON COLUMN sys_notification.title IS 'タイトル';
COMMENT ON COLUMN sys_notification.content IS '本文（プレースホルダ置換済み）';
COMMENT ON COLUMN sys_notification.related_url IS '関連画面 URL（フロントルート）';
COMMENT ON COLUMN sys_notification.priority IS '優先度：1 高 / 2 中 / 3 低';
COMMENT ON COLUMN sys_notification.sender_id IS '送信者（0=システム）';
COMMENT ON COLUMN sys_notification.send_status IS '送信：0 待送 / 1 送信中 / 2 成功 / 3 一部失敗 / 4 失敗';
COMMENT ON COLUMN sys_notification.expire_at IS '表示期限（NULL=無期限）';
COMMENT ON COLUMN sys_notification.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN sys_notification.company_id IS '公司 ID';
COMMENT ON COLUMN sys_notification.created_at IS '创建时间';
COMMENT ON COLUMN sys_notification.created_by IS '创建人';
COMMENT ON COLUMN sys_notification.updated_at IS '更新时间';
COMMENT ON COLUMN sys_notification.updated_by IS '更新人';
COMMENT ON COLUMN sys_notification.version IS '乐观锁版本';
COMMENT ON COLUMN sys_notification.remark IS '备注';

-- sys_notification_receiver
CREATE TABLE sys_notification_receiver (
    id              BIGINT       NOT NULL,
    tenant_id       BIGINT       NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id      BIGINT       NOT NULL,
    version         INT          NOT NULL DEFAULT 0,
    remark          VARCHAR(500) NULL,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_by      BIGINT       NOT NULL DEFAULT 0,
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_by      BIGINT       NOT NULL DEFAULT 0,
    notification_id     BIGINT        NOT NULL,           -- 通知 ID
    receiver_user_id    BIGINT        NOT NULL,           -- 受信者ユーザ ID
    receiver_type       SMALLINT      NOT NULL DEFAULT 1, -- 受信種別：1 主送 / 2 抄送
    read_flag           BOOLEAN       NOT NULL DEFAULT FALSE, -- 既読
    read_at             TIMESTAMPTZ,                      -- 既読日時
    status              SMALLINT      NOT NULL DEFAULT 0, -- 状态：0 未読 / 1 既読 / 2 削除（ユーザ非表示）
    CONSTRAINT pk_sys_notification_receiver PRIMARY KEY (id)
);

ALTER TABLE sys_notification_receiver ENABLE ROW LEVEL SECURITY;
ALTER TABLE sys_notification_receiver FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sys_notification_receiver
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_sys_notification_receiver ON sys_notification_receiver (tenant_id, notification_id, receiver_user_id);
CREATE INDEX idx_sys_notification_receiver_inbox ON sys_notification_receiver (receiver_user_id, status, created_at DESC);
COMMENT ON TABLE sys_notification_receiver IS '通知受信者（既読管理）';
COMMENT ON COLUMN sys_notification_receiver.notification_id IS '通知 ID';
COMMENT ON COLUMN sys_notification_receiver.receiver_user_id IS '受信者ユーザ ID';
COMMENT ON COLUMN sys_notification_receiver.receiver_type IS '受信種別：1 主送 / 2 抄送';
COMMENT ON COLUMN sys_notification_receiver.read_flag IS '既読';
COMMENT ON COLUMN sys_notification_receiver.read_at IS '既読日時';
COMMENT ON COLUMN sys_notification_receiver.status IS '状态：0 未読 / 1 既読 / 2 削除（ユーザ非表示）';
COMMENT ON COLUMN sys_notification_receiver.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN sys_notification_receiver.company_id IS '公司 ID';
COMMENT ON COLUMN sys_notification_receiver.created_at IS '创建时间';
COMMENT ON COLUMN sys_notification_receiver.created_by IS '创建人';
COMMENT ON COLUMN sys_notification_receiver.updated_at IS '更新时间';
COMMENT ON COLUMN sys_notification_receiver.updated_by IS '更新人';
COMMENT ON COLUMN sys_notification_receiver.version IS '乐观锁版本';
COMMENT ON COLUMN sys_notification_receiver.remark IS '备注';

-- sys_notification_template
CREATE TABLE sys_notification_template (
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
    template_code       VARCHAR(64)   NOT NULL,           -- 模板代码（一意、例 WF_TASK_CREATED）
    template_name       VARCHAR(100)  NOT NULL,           -- 模板名称
    channel_type        SMALLINT      NOT NULL DEFAULT 1, -- 渠道：1 站内 / 2 邮件 / 3 短信 / 4 企业微信 / 5 钉钉
    biz_scene           VARCHAR(64),                      -- 対応シーン
    title_template      VARCHAR(300)  NOT NULL,           -- 标题模板
    content_template    TEXT          NOT NULL,           -- 本文模板（{0}、{1}…）
    variables_schema    JSONB,                            -- 変数定義（例 [{"code":"taskName","name":"任务名","type":"string"}]）
    version_no          INT           NOT NULL DEFAULT 1, -- 版数
    is_system           BOOLEAN       NOT NULL DEFAULT FALSE, -- 系统内置（削除不可）
    effective_from      DATE,                             -- 適用開始日
    effective_to        DATE,                             -- 適用終了日
    status              SMALLINT      NOT NULL DEFAULT 1, -- 状态：1 有效 / 0 无效
    description         VARCHAR(500), -- 说明
    CONSTRAINT pk_sys_notification_template PRIMARY KEY (id)
);

ALTER TABLE sys_notification_template ENABLE ROW LEVEL SECURITY;
ALTER TABLE sys_notification_template FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sys_notification_template
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_sys_notification_template ON sys_notification_template (tenant_id, template_code, channel_type, version_no) WHERE deleted = FALSE;
CREATE INDEX idx_sys_notification_template_scene ON sys_notification_template (biz_scene, channel_type, status);
COMMENT ON TABLE sys_notification_template IS '通知模板（站内/邮件/短信/企微）';
COMMENT ON COLUMN sys_notification_template.template_code IS '模板代码（一意、例 WF_TASK_CREATED）';
COMMENT ON COLUMN sys_notification_template.template_name IS '模板名称';
COMMENT ON COLUMN sys_notification_template.channel_type IS '渠道：1 站内 / 2 邮件 / 3 短信 / 4 企业微信 / 5 钉钉';
COMMENT ON COLUMN sys_notification_template.biz_scene IS '対応シーン';
COMMENT ON COLUMN sys_notification_template.title_template IS '标题模板';
COMMENT ON COLUMN sys_notification_template.content_template IS '本文模板（{0}、{1}…）';
COMMENT ON COLUMN sys_notification_template.variables_schema IS '変数定義（例 [{"code":"taskName","name":"任务名","type":"string"}]）';
COMMENT ON COLUMN sys_notification_template.version_no IS '版数';
COMMENT ON COLUMN sys_notification_template.is_system IS '系统内置（削除不可）';
COMMENT ON COLUMN sys_notification_template.effective_from IS '適用開始日';
COMMENT ON COLUMN sys_notification_template.effective_to IS '適用終了日';
COMMENT ON COLUMN sys_notification_template.status IS '状态：1 有效 / 0 无效';
COMMENT ON COLUMN sys_notification_template.description IS '说明';
COMMENT ON COLUMN sys_notification_template.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN sys_notification_template.company_id IS '公司 ID';
COMMENT ON COLUMN sys_notification_template.created_at IS '创建时间';
COMMENT ON COLUMN sys_notification_template.created_by IS '创建人';
COMMENT ON COLUMN sys_notification_template.updated_at IS '更新时间';
COMMENT ON COLUMN sys_notification_template.updated_by IS '更新人';
COMMENT ON COLUMN sys_notification_template.version IS '乐观锁版本';
COMMENT ON COLUMN sys_notification_template.deleted IS '逻辑删除';
COMMENT ON COLUMN sys_notification_template.remark IS '备注';
COMMENT ON COLUMN sys_notification_template.ext_data IS '扩展字段';

-- sys_notification_send_log
CREATE TABLE sys_notification_send_log (
    id              BIGINT       NOT NULL,
    tenant_id       BIGINT       NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_by      BIGINT       NOT NULL DEFAULT 0,
    notification_id     BIGINT        NOT NULL,           -- 通知 ID
    channel_type        SMALLINT      NOT NULL,           -- 渠道：1 站内 / 2 邮件 / 3 短信 / 4 企业微信 / 5 钉钉
    receiver_user_id    BIGINT,                           -- 受信者ユーザ ID
    receiver_address    VARCHAR(200),                     -- 送信先（メール/電話、マスキング保存）
    send_status         SMALLINT      NOT NULL DEFAULT 0, -- 0 待送 / 1 送信中 / 2 成功 / 3 失敗
    retry_count         SMALLINT      NOT NULL DEFAULT 0, -- 再送回数
    error_message       VARCHAR(1000),                    -- 失敗理由
    provider_msg_id     VARCHAR(100),                     -- サービス事業者メッセージ ID
    sent_at             TIMESTAMPTZ,                      -- 送信日時
    cost_ms             INT,                              -- 処理時間
    next_retry_at       TIMESTAMPTZ, -- 次回再送日時
    CONSTRAINT pk_sys_notification_send_log PRIMARY KEY (id)
);

ALTER TABLE sys_notification_send_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE sys_notification_send_log FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sys_notification_send_log
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE INDEX idx_sys_notification_send_log_retry ON sys_notification_send_log (send_status, next_retry_at) WHERE send_status IN (0,3);
CREATE INDEX idx_sys_notification_send_log_user ON sys_notification_send_log (receiver_user_id, created_at DESC);
COMMENT ON TABLE sys_notification_send_log IS '通知发送日志（外部渠道）';
COMMENT ON COLUMN sys_notification_send_log.notification_id IS '通知 ID';
COMMENT ON COLUMN sys_notification_send_log.channel_type IS '渠道：1 站内 / 2 邮件 / 3 短信 / 4 企业微信 / 5 钉钉';
COMMENT ON COLUMN sys_notification_send_log.receiver_user_id IS '受信者ユーザ ID';
COMMENT ON COLUMN sys_notification_send_log.receiver_address IS '送信先（メール/電話、マスキング保存）';
COMMENT ON COLUMN sys_notification_send_log.send_status IS '0 待送 / 1 送信中 / 2 成功 / 3 失敗';
COMMENT ON COLUMN sys_notification_send_log.retry_count IS '再送回数';
COMMENT ON COLUMN sys_notification_send_log.error_message IS '失敗理由';
COMMENT ON COLUMN sys_notification_send_log.provider_msg_id IS 'サービス事業者メッセージ ID';
COMMENT ON COLUMN sys_notification_send_log.sent_at IS '送信日時';
COMMENT ON COLUMN sys_notification_send_log.cost_ms IS '処理時間';
COMMENT ON COLUMN sys_notification_send_log.next_retry_at IS '次回再送日時';
COMMENT ON COLUMN sys_notification_send_log.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN sys_notification_send_log.created_at IS '创建时间';
COMMENT ON COLUMN sys_notification_send_log.created_by IS '创建人';

-- sys_import_export_job
CREATE TABLE sys_import_export_job (
    id              BIGINT       NOT NULL,
    tenant_id       BIGINT       NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id      BIGINT       NOT NULL,
    version         INT          NOT NULL DEFAULT 0,
    remark          VARCHAR(500) NULL,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_by      BIGINT       NOT NULL DEFAULT 0,
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_by      BIGINT       NOT NULL DEFAULT 0,
    job_no              VARCHAR(32)   NOT NULL,           -- 任务编号（JOB+yyMMdd+連番）
    job_type            SMALLINT      NOT NULL,           -- 类型：1 导入 / 2 导出 / 3 帳票 / 4 批量処理
    job_name            VARCHAR(200)  NOT NULL,           -- 任务名称（例 用户导入）
    module_code         VARCHAR(32)   NOT NULL,           -- 模块名
    biz_type            VARCHAR(64),                      -- 業務種別（import-template.biz_type）
    template_id         BIGINT,                           -- 导入テンプレート ID
    request_params      JSONB,                            -- 検索条件・対象 ID 等のリクエスト
    source_file_id      BIGINT,                           -- 入力ファイル（附件 ID）
    result_file_id      BIGINT,                           -- 結果ファイル（附件 ID）
    total_count         BIGINT        NOT NULL DEFAULT 0, -- 総件数
    success_count       BIGINT        NOT NULL DEFAULT 0, -- 成功件数
    fail_count          BIGINT        NOT NULL DEFAULT 0, -- 失敗件数
    progress            SMALLINT      NOT NULL DEFAULT 0, -- 進捗（0〜100）
    job_status          SMALLINT      NOT NULL DEFAULT 0, -- 0 待機 / 1 実行中 / 2 成功 / 3 失敗 / 4 取消 / 5 一部成功
    error_message       VARCHAR(1000),                    -- 失敗理由
    started_at          TIMESTAMPTZ,                      -- 開始日時
    finished_at         TIMESTAMPTZ,                      -- 終了日時
    expire_at           TIMESTAMPTZ,                      -- 結果ファイル有効期限（完了+7 日）
    trace_id            VARCHAR(64), -- 追跡 ID
    CONSTRAINT pk_sys_import_export_job PRIMARY KEY (id)
);

ALTER TABLE sys_import_export_job ENABLE ROW LEVEL SECURITY;
ALTER TABLE sys_import_export_job FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sys_import_export_job
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_sys_import_export_job_no ON sys_import_export_job (tenant_id, job_no);
CREATE INDEX idx_sys_import_export_job_user ON sys_import_export_job (created_by, created_at DESC);
CREATE INDEX idx_sys_import_export_job_status ON sys_import_export_job (job_status, created_at);
CREATE INDEX idx_sys_import_export_job_expire ON sys_import_export_job (expire_at) WHERE expire_at IS NOT NULL;
COMMENT ON TABLE sys_import_export_job IS '导入导出任务（非同期ジョブ）';
COMMENT ON COLUMN sys_import_export_job.job_no IS '任务编号（JOB+yyMMdd+連番）';
COMMENT ON COLUMN sys_import_export_job.job_type IS '类型：1 导入 / 2 导出 / 3 帳票 / 4 批量処理';
COMMENT ON COLUMN sys_import_export_job.job_name IS '任务名称（例 用户导入）';
COMMENT ON COLUMN sys_import_export_job.module_code IS '模块名';
COMMENT ON COLUMN sys_import_export_job.biz_type IS '業務種別（import-template.biz_type）';
COMMENT ON COLUMN sys_import_export_job.template_id IS '导入テンプレート ID';
COMMENT ON COLUMN sys_import_export_job.request_params IS '検索条件・対象 ID 等のリクエスト';
COMMENT ON COLUMN sys_import_export_job.source_file_id IS '入力ファイル（附件 ID）';
COMMENT ON COLUMN sys_import_export_job.result_file_id IS '結果ファイル（附件 ID）';
COMMENT ON COLUMN sys_import_export_job.total_count IS '総件数';
COMMENT ON COLUMN sys_import_export_job.success_count IS '成功件数';
COMMENT ON COLUMN sys_import_export_job.fail_count IS '失敗件数';
COMMENT ON COLUMN sys_import_export_job.progress IS '進捗（0〜100）';
COMMENT ON COLUMN sys_import_export_job.job_status IS '0 待機 / 1 実行中 / 2 成功 / 3 失敗 / 4 取消 / 5 一部成功';
COMMENT ON COLUMN sys_import_export_job.error_message IS '失敗理由';
COMMENT ON COLUMN sys_import_export_job.started_at IS '開始日時';
COMMENT ON COLUMN sys_import_export_job.finished_at IS '終了日時';
COMMENT ON COLUMN sys_import_export_job.expire_at IS '結果ファイル有効期限（完了+7 日）';
COMMENT ON COLUMN sys_import_export_job.trace_id IS '追跡 ID';
COMMENT ON COLUMN sys_import_export_job.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN sys_import_export_job.company_id IS '公司 ID';
COMMENT ON COLUMN sys_import_export_job.created_at IS '创建时间';
COMMENT ON COLUMN sys_import_export_job.created_by IS '创建人';
COMMENT ON COLUMN sys_import_export_job.updated_at IS '更新时间';
COMMENT ON COLUMN sys_import_export_job.updated_by IS '更新人';
COMMENT ON COLUMN sys_import_export_job.version IS '乐观锁版本';
COMMENT ON COLUMN sys_import_export_job.remark IS '备注';

-- sys_import_export_error
CREATE TABLE sys_import_export_error (
    id              BIGINT       NOT NULL,
    tenant_id       BIGINT       NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_by      BIGINT       NOT NULL DEFAULT 0,
    job_id              BIGINT        NOT NULL,           -- ジョブ ID
    row_no              INT           NOT NULL,           -- 行番号（Excel 行、1 起算）
    error_type          SMALLINT      NOT NULL,           -- 1 必須 / 2 型・桁 / 3 コード不存在 / 4 業務 / 5 DB 制約
    column_name         VARCHAR(64),                      -- 列名（項目エラーの場合）
    error_value         VARCHAR(500),                     -- 入力値（マスキング済み）
    message             VARCHAR(500)  NOT NULL,           -- エラー内容（MSG-xxx 本文）
    raw_row             JSONB,                            -- 取込行の原本（項目→値）
    message_id          VARCHAR(32), -- メッセージ ID
    CONSTRAINT pk_sys_import_export_error PRIMARY KEY (id)
);

ALTER TABLE sys_import_export_error ENABLE ROW LEVEL SECURITY;
ALTER TABLE sys_import_export_error FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sys_import_export_error
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE INDEX idx_sys_import_export_error_job ON sys_import_export_error (job_id, row_no);
COMMENT ON TABLE sys_import_export_error IS '导入错误行（行単位エラー）';
COMMENT ON COLUMN sys_import_export_error.job_id IS 'ジョブ ID';
COMMENT ON COLUMN sys_import_export_error.row_no IS '行番号（Excel 行、1 起算）';
COMMENT ON COLUMN sys_import_export_error.error_type IS '1 必須 / 2 型・桁 / 3 コード不存在 / 4 業務 / 5 DB 制約';
COMMENT ON COLUMN sys_import_export_error.column_name IS '列名（項目エラーの場合）';
COMMENT ON COLUMN sys_import_export_error.error_value IS '入力値（マスキング済み）';
COMMENT ON COLUMN sys_import_export_error.message IS 'エラー内容（MSG-xxx 本文）';
COMMENT ON COLUMN sys_import_export_error.raw_row IS '取込行の原本（項目→値）';
COMMENT ON COLUMN sys_import_export_error.message_id IS 'メッセージ ID';
COMMENT ON COLUMN sys_import_export_error.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN sys_import_export_error.created_at IS '创建时间';
COMMENT ON COLUMN sys_import_export_error.created_by IS '创建人';

-- sys_import_template
CREATE TABLE sys_import_template (
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
    template_code       VARCHAR(64)   NOT NULL,           -- 模板代码（一意、例 USER_IMPORT）
    template_name       VARCHAR(200)  NOT NULL,           -- 模板名称
    module_code         VARCHAR(32)   NOT NULL,           -- 模块名
    biz_type            VARCHAR(64)   NOT NULL,           -- 業務種別（取込データの種類）
    file_name           VARCHAR(255)  NOT NULL,           -- 配布ファイル名
    storage_path        VARCHAR(500)  NOT NULL,           -- テンプレート保存パス
    column_schema       JSONB         NOT NULL,           -- 列定義（[{"column":"user_code","name":"用户账号","type":"string","required":true,"maxLength":16,"dictCode":null}]）
    version_no          INT           NOT NULL DEFAULT 1, -- 版数
    download_count      INT           NOT NULL DEFAULT 0, -- ダウンロード回数
    status              SMALLINT      NOT NULL DEFAULT 1, -- 状态：1 有效 / 0 无效
    description         VARCHAR(500), -- 说明
    CONSTRAINT pk_sys_import_template PRIMARY KEY (id)
);

ALTER TABLE sys_import_template ENABLE ROW LEVEL SECURITY;
ALTER TABLE sys_import_template FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sys_import_template
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_sys_import_template_code ON sys_import_template (tenant_id, template_code, version_no) WHERE deleted = FALSE;
CREATE INDEX idx_sys_import_template_biz ON sys_import_template (module_code, biz_type, status);
COMMENT ON TABLE sys_import_template IS '导入模板（Excel テンプレート定義）';
COMMENT ON COLUMN sys_import_template.template_code IS '模板代码（一意、例 USER_IMPORT）';
COMMENT ON COLUMN sys_import_template.template_name IS '模板名称';
COMMENT ON COLUMN sys_import_template.module_code IS '模块名';
COMMENT ON COLUMN sys_import_template.biz_type IS '業務種別（取込データの種類）';
COMMENT ON COLUMN sys_import_template.file_name IS '配布ファイル名';
COMMENT ON COLUMN sys_import_template.storage_path IS 'テンプレート保存パス';
COMMENT ON COLUMN sys_import_template.column_schema IS '列定義（[{"column":"user_code","name":"用户账号","type":"string","required":true,"maxLength":16,"dictCode":null}]）';
COMMENT ON COLUMN sys_import_template.version_no IS '版数';
COMMENT ON COLUMN sys_import_template.download_count IS 'ダウンロード回数';
COMMENT ON COLUMN sys_import_template.status IS '状态：1 有效 / 0 无效';
COMMENT ON COLUMN sys_import_template.description IS '说明';
COMMENT ON COLUMN sys_import_template.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN sys_import_template.company_id IS '公司 ID';
COMMENT ON COLUMN sys_import_template.created_at IS '创建时间';
COMMENT ON COLUMN sys_import_template.created_by IS '创建人';
COMMENT ON COLUMN sys_import_template.updated_at IS '更新时间';
COMMENT ON COLUMN sys_import_template.updated_by IS '更新人';
COMMENT ON COLUMN sys_import_template.version IS '乐观锁版本';
COMMENT ON COLUMN sys_import_template.deleted IS '逻辑删除';
COMMENT ON COLUMN sys_import_template.remark IS '备注';
COMMENT ON COLUMN sys_import_template.ext_data IS '扩展字段';

-- sys_print_template
CREATE TABLE sys_print_template (
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
    template_code       VARCHAR(64)   NOT NULL,           -- 模板代码（一意）
    template_name       VARCHAR(200)  NOT NULL,           -- 模板名称
    report_id           VARCHAR(32)   NOT NULL,           -- 帳票 ID（例 PRT-SAL-001）
    biz_type            VARCHAR(64)   NOT NULL,           -- 業務種別
    module_code         VARCHAR(32)   NOT NULL,           -- 模块名
    engine_type         SMALLINT      NOT NULL DEFAULT 1, -- エンジン：1 HTML / 2 JasperReports
    content             TEXT          NOT NULL,           -- テンプレート内容（HTML/JSON）
    page_size           VARCHAR(16)   NOT NULL DEFAULT 'A4', -- 用紙（A4/A5/LABEL）
    orientation         SMALLINT      NOT NULL DEFAULT 1, -- 1 縦 / 2 横
    version_no          INT           NOT NULL DEFAULT 1, -- 版数
    is_default          BOOLEAN       NOT NULL DEFAULT FALSE, -- 業務種別の既定テンプレート
    effective_from      DATE,                             -- 適用開始日
    effective_to        DATE,                             -- 適用終了日
    status              SMALLINT      NOT NULL DEFAULT 1, -- 状态：1 有效 / 0 无效
    description         VARCHAR(500), -- 说明
    CONSTRAINT pk_sys_print_template PRIMARY KEY (id)
);

ALTER TABLE sys_print_template ENABLE ROW LEVEL SECURITY;
ALTER TABLE sys_print_template FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sys_print_template
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_sys_print_template ON sys_print_template (tenant_id, template_code, version_no) WHERE deleted = FALSE;
CREATE INDEX idx_sys_print_template_report ON sys_print_template (report_id, is_default, status);
COMMENT ON TABLE sys_print_template IS '打印模板（帳票レイアウト）';
COMMENT ON COLUMN sys_print_template.template_code IS '模板代码（一意）';
COMMENT ON COLUMN sys_print_template.template_name IS '模板名称';
COMMENT ON COLUMN sys_print_template.report_id IS '帳票 ID（例 PRT-SAL-001）';
COMMENT ON COLUMN sys_print_template.biz_type IS '業務種別';
COMMENT ON COLUMN sys_print_template.module_code IS '模块名';
COMMENT ON COLUMN sys_print_template.engine_type IS 'エンジン：1 HTML / 2 JasperReports';
COMMENT ON COLUMN sys_print_template.content IS 'テンプレート内容（HTML/JSON）';
COMMENT ON COLUMN sys_print_template.page_size IS '用紙（A4/A5/LABEL）';
COMMENT ON COLUMN sys_print_template.orientation IS '1 縦 / 2 横';
COMMENT ON COLUMN sys_print_template.version_no IS '版数';
COMMENT ON COLUMN sys_print_template.is_default IS '業務種別の既定テンプレート';
COMMENT ON COLUMN sys_print_template.effective_from IS '適用開始日';
COMMENT ON COLUMN sys_print_template.effective_to IS '適用終了日';
COMMENT ON COLUMN sys_print_template.status IS '状态：1 有效 / 0 无效';
COMMENT ON COLUMN sys_print_template.description IS '说明';
COMMENT ON COLUMN sys_print_template.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN sys_print_template.company_id IS '公司 ID';
COMMENT ON COLUMN sys_print_template.created_at IS '创建时间';
COMMENT ON COLUMN sys_print_template.created_by IS '创建人';
COMMENT ON COLUMN sys_print_template.updated_at IS '更新时间';
COMMENT ON COLUMN sys_print_template.updated_by IS '更新人';
COMMENT ON COLUMN sys_print_template.version IS '乐观锁版本';
COMMENT ON COLUMN sys_print_template.deleted IS '逻辑删除';
COMMENT ON COLUMN sys_print_template.remark IS '备注';
COMMENT ON COLUMN sys_print_template.ext_data IS '扩展字段';

-- sys_print_log
CREATE TABLE sys_print_log (
    id              BIGINT       NOT NULL,
    tenant_id       BIGINT       NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id      BIGINT       NOT NULL,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_by      BIGINT       NOT NULL DEFAULT 0,
    print_no            VARCHAR(32)   NOT NULL,           -- 出力番号（PRN+yyMMdd+連番）
    report_id           VARCHAR(32)   NOT NULL,           -- 帳票 ID
    biz_type            VARCHAR(64),                      -- 業務種別
    biz_id              BIGINT,                           -- 業務 ID
    template_id         BIGINT,                           -- 使用テンプレート ID
    output_type         SMALLINT      NOT NULL DEFAULT 1, -- 出力形式：1 PDF / 2 Excel / 3 プレビュー
    print_count         INT           NOT NULL DEFAULT 1, -- 部数
    result              SMALLINT      NOT NULL DEFAULT 1, -- 1 成功 / 0 失敗
    error_message       VARCHAR(1000),                    -- 失敗理由
    printer_user_id     BIGINT        NOT NULL,           -- 出力者
    trace_id            VARCHAR(64),                      -- 追跡 ID
    occurred_at         TIMESTAMPTZ   NOT NULL DEFAULT now(), -- 出力日時
    CONSTRAINT pk_sys_print_log PRIMARY KEY (id)
);

ALTER TABLE sys_print_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE sys_print_log FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sys_print_log
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE INDEX idx_sys_print_log_biz ON sys_print_log (biz_type, biz_id, occurred_at DESC);
CREATE INDEX idx_sys_print_log_user ON sys_print_log (printer_user_id, occurred_at DESC);
COMMENT ON TABLE sys_print_log IS '打印日志（帳票出力履歴）';
COMMENT ON COLUMN sys_print_log.print_no IS '出力番号（PRN+yyMMdd+連番）';
COMMENT ON COLUMN sys_print_log.report_id IS '帳票 ID';
COMMENT ON COLUMN sys_print_log.biz_type IS '業務種別';
COMMENT ON COLUMN sys_print_log.biz_id IS '業務 ID';
COMMENT ON COLUMN sys_print_log.template_id IS '使用テンプレート ID';
COMMENT ON COLUMN sys_print_log.output_type IS '出力形式：1 PDF / 2 Excel / 3 プレビュー';
COMMENT ON COLUMN sys_print_log.print_count IS '部数';
COMMENT ON COLUMN sys_print_log.result IS '1 成功 / 0 失敗';
COMMENT ON COLUMN sys_print_log.error_message IS '失敗理由';
COMMENT ON COLUMN sys_print_log.printer_user_id IS '出力者';
COMMENT ON COLUMN sys_print_log.trace_id IS '追跡 ID';
COMMENT ON COLUMN sys_print_log.occurred_at IS '出力日時';
COMMENT ON COLUMN sys_print_log.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN sys_print_log.company_id IS '公司 ID';
COMMENT ON COLUMN sys_print_log.created_at IS '创建时间';
COMMENT ON COLUMN sys_print_log.created_by IS '创建人';

-- sys_scheduled_job
CREATE TABLE sys_scheduled_job (
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
    job_code            VARCHAR(64)   NOT NULL,           -- ジョブコード（例 BAT-SYS-001）
    job_name            VARCHAR(200)  NOT NULL,           -- ジョブ名
    job_group           VARCHAR(64)   NOT NULL,           -- グループ（system/sales/mdm/…）
    handler_bean        VARCHAR(200)  NOT NULL,           -- 実行ハンドラ（Bean 名 or クラス名）
    schedule_type       SMALLINT      NOT NULL DEFAULT 1, -- 起動方式：1 Cron / 2 固定間隔 / 3 手動のみ
    cron_expression     VARCHAR(100),                     -- Cron（6 桁、秒 分 時 日 月 週）
    fixed_interval_ms   INT,                              -- 固定間隔（schedule_type=2）
    allow_concurrent    BOOLEAN       NOT NULL DEFAULT FALSE, -- 並行実行許可
    timeout_seconds     INT           NOT NULL DEFAULT 300,   -- タイムアウト（秒）
    retry_count         SMALLINT      NOT NULL DEFAULT 0, -- 失敗時リトライ回数
    retry_interval_sec  INT           NOT NULL DEFAULT 60, -- リトライ間隔（秒）
    param_json          JSONB,                            -- ジョブパラメータ
    status              SMALLINT      NOT NULL DEFAULT 1, -- 状态：1 有效 / 0 停止
    last_run_at         TIMESTAMPTZ,                      -- 最終実行日時
    last_result         SMALLINT,                         -- 最終結果：1 成功 / 0 失敗 / 2 スキップ
    next_run_at         TIMESTAMPTZ,                      -- 次回実行予定
    description         VARCHAR(500), -- 说明
    CONSTRAINT pk_sys_scheduled_job PRIMARY KEY (id)
);

ALTER TABLE sys_scheduled_job ENABLE ROW LEVEL SECURITY;
ALTER TABLE sys_scheduled_job FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sys_scheduled_job
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_sys_scheduled_job_code ON sys_scheduled_job (tenant_id, job_code) WHERE deleted = FALSE;
CREATE INDEX idx_sys_scheduled_job_status ON sys_scheduled_job (status, next_run_at);
COMMENT ON TABLE sys_scheduled_job IS '定时任务定义';
COMMENT ON COLUMN sys_scheduled_job.job_code IS 'ジョブコード（例 BAT-SYS-001）';
COMMENT ON COLUMN sys_scheduled_job.job_name IS 'ジョブ名';
COMMENT ON COLUMN sys_scheduled_job.job_group IS 'グループ（system/sales/mdm/…）';
COMMENT ON COLUMN sys_scheduled_job.handler_bean IS '実行ハンドラ（Bean 名 or クラス名）';
COMMENT ON COLUMN sys_scheduled_job.schedule_type IS '起動方式：1 Cron / 2 固定間隔 / 3 手動のみ';
COMMENT ON COLUMN sys_scheduled_job.cron_expression IS 'Cron（6 桁、秒 分 時 日 月 週）';
COMMENT ON COLUMN sys_scheduled_job.fixed_interval_ms IS '固定間隔（schedule_type=2）';
COMMENT ON COLUMN sys_scheduled_job.allow_concurrent IS '並行実行許可';
COMMENT ON COLUMN sys_scheduled_job.timeout_seconds IS 'タイムアウト（秒）';
COMMENT ON COLUMN sys_scheduled_job.retry_count IS '失敗時リトライ回数';
COMMENT ON COLUMN sys_scheduled_job.retry_interval_sec IS 'リトライ間隔（秒）';
COMMENT ON COLUMN sys_scheduled_job.param_json IS 'ジョブパラメータ';
COMMENT ON COLUMN sys_scheduled_job.status IS '状态：1 有效 / 0 停止';
COMMENT ON COLUMN sys_scheduled_job.last_run_at IS '最終実行日時';
COMMENT ON COLUMN sys_scheduled_job.last_result IS '最終結果：1 成功 / 0 失敗 / 2 スキップ';
COMMENT ON COLUMN sys_scheduled_job.next_run_at IS '次回実行予定';
COMMENT ON COLUMN sys_scheduled_job.description IS '说明';
COMMENT ON COLUMN sys_scheduled_job.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN sys_scheduled_job.company_id IS '公司 ID';
COMMENT ON COLUMN sys_scheduled_job.created_at IS '创建时间';
COMMENT ON COLUMN sys_scheduled_job.created_by IS '创建人';
COMMENT ON COLUMN sys_scheduled_job.updated_at IS '更新时间';
COMMENT ON COLUMN sys_scheduled_job.updated_by IS '更新人';
COMMENT ON COLUMN sys_scheduled_job.version IS '乐观锁版本';
COMMENT ON COLUMN sys_scheduled_job.deleted IS '逻辑删除';
COMMENT ON COLUMN sys_scheduled_job.remark IS '备注';
COMMENT ON COLUMN sys_scheduled_job.ext_data IS '扩展字段';

-- sys_scheduled_job_log
CREATE TABLE sys_scheduled_job_log (
    id              BIGINT       NOT NULL,
    tenant_id       BIGINT       NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_by      BIGINT       NOT NULL DEFAULT 0,
    job_id              BIGINT        NOT NULL,           -- ジョブ ID（sys_scheduled_job.id）
    job_code            VARCHAR(64)   NOT NULL,           -- ジョブコード（スナップショット）
    trigger_type        SMALLINT      NOT NULL DEFAULT 1, -- 1 自動 / 2 手動 / 3 補償実行
    start_at            TIMESTAMPTZ   NOT NULL,           -- 開始日時
    end_at              TIMESTAMPTZ,                      -- 終了日時
    duration_ms         INT,                              -- 処理時間
    execute_result      SMALLINT      NOT NULL DEFAULT 1, -- 1 成功 / 0 失敗 / 2 スキップ（多重起動等）
    processed_count     BIGINT        NOT NULL DEFAULT 0, -- 処理件数
    error_message       VARCHAR(2000),                    -- 失敗理由
    execute_node        VARCHAR(64),                      -- 実行ノード（マルチインスタンス時）
    trace_id            VARCHAR(64), -- 追跡 ID
    CONSTRAINT pk_sys_scheduled_job_log PRIMARY KEY (id)
);

ALTER TABLE sys_scheduled_job_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE sys_scheduled_job_log FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sys_scheduled_job_log
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE INDEX idx_sys_scheduled_job_log_job ON sys_scheduled_job_log (job_id, start_at DESC);
CREATE INDEX idx_sys_scheduled_job_log_result ON sys_scheduled_job_log (execute_result, start_at DESC);
CREATE INDEX idx_sys_scheduled_job_log_running ON sys_scheduled_job_log (job_id, end_at) WHERE end_at IS NULL;
COMMENT ON TABLE sys_scheduled_job_log IS '定时任务日志（実行履歴）';
COMMENT ON COLUMN sys_scheduled_job_log.job_id IS 'ジョブ ID（sys_scheduled_job.id）';
COMMENT ON COLUMN sys_scheduled_job_log.job_code IS 'ジョブコード（スナップショット）';
COMMENT ON COLUMN sys_scheduled_job_log.trigger_type IS '1 自動 / 2 手動 / 3 補償実行';
COMMENT ON COLUMN sys_scheduled_job_log.start_at IS '開始日時';
COMMENT ON COLUMN sys_scheduled_job_log.end_at IS '終了日時';
COMMENT ON COLUMN sys_scheduled_job_log.duration_ms IS '処理時間';
COMMENT ON COLUMN sys_scheduled_job_log.execute_result IS '1 成功 / 0 失敗 / 2 スキップ（多重起動等）';
COMMENT ON COLUMN sys_scheduled_job_log.processed_count IS '処理件数';
COMMENT ON COLUMN sys_scheduled_job_log.error_message IS '失敗理由';
COMMENT ON COLUMN sys_scheduled_job_log.execute_node IS '実行ノード（マルチインスタンス時）';
COMMENT ON COLUMN sys_scheduled_job_log.trace_id IS '追跡 ID';
COMMENT ON COLUMN sys_scheduled_job_log.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN sys_scheduled_job_log.created_at IS '创建时间';
COMMENT ON COLUMN sys_scheduled_job_log.created_by IS '创建人';

-- sys_outbox_event
CREATE TABLE sys_outbox_event (
    id              BIGINT       NOT NULL,
    tenant_id       BIGINT       NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id      BIGINT       NOT NULL,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_by      BIGINT       NOT NULL DEFAULT 0,
    event_id            UUID          NOT NULL,           -- イベント ID（冪等キー）
    event_type          VARCHAR(100)  NOT NULL,           -- イベント名（{domain}.{entity}.{action}）
    event_version       INT           NOT NULL DEFAULT 1, -- イベントバージョン（後方互換管理）
    aggregate_type      VARCHAR(64),                      -- 集約種別
    aggregate_id        VARCHAR(64),                      -- 集約 ID
    payload             JSONB         NOT NULL,           -- イベントペイロード（エンベロープ含む：source/aggregateVersion は payload 内）
    status              SMALLINT      NOT NULL DEFAULT 0, -- 0 NEW / 1 PUBLISHED / 2 FAILED / 9 DEAD_LETTER
    retry_count         INT           NOT NULL DEFAULT 0, -- 再送回数
    next_retry_at       TIMESTAMPTZ,                      -- 次回再送日時
    last_error          VARCHAR(1000),                    -- 最終エラー
    occurred_at         TIMESTAMPTZ   NOT NULL,           -- 事実発生日時
    published_at        TIMESTAMPTZ, -- 配信日時
    CONSTRAINT pk_sys_outbox_event PRIMARY KEY (id)
);

ALTER TABLE sys_outbox_event ENABLE ROW LEVEL SECURITY;
ALTER TABLE sys_outbox_event FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sys_outbox_event
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_sys_outbox_event_id ON sys_outbox_event (tenant_id, event_id);
CREATE INDEX idx_sys_outbox_event_pending ON sys_outbox_event (status, next_retry_at);
CREATE INDEX idx_sys_outbox_event_type ON sys_outbox_event (event_type, occurred_at DESC);
COMMENT ON TABLE sys_outbox_event IS 'Outbox 事件（ドメインイベント配信。DDL 正本）';
COMMENT ON COLUMN sys_outbox_event.event_id IS 'イベント ID（冪等キー）';
COMMENT ON COLUMN sys_outbox_event.event_type IS 'イベント名（{domain}.{entity}.{action}）';
COMMENT ON COLUMN sys_outbox_event.event_version IS 'イベントバージョン（後方互換管理）';
COMMENT ON COLUMN sys_outbox_event.aggregate_type IS '集約種別';
COMMENT ON COLUMN sys_outbox_event.aggregate_id IS '集約 ID';
COMMENT ON COLUMN sys_outbox_event.payload IS 'イベントペイロード（エンベロープ含む：source/aggregateVersion は payload 内）';
COMMENT ON COLUMN sys_outbox_event.status IS '0 NEW / 1 PUBLISHED / 2 FAILED / 9 DEAD_LETTER';
COMMENT ON COLUMN sys_outbox_event.retry_count IS '再送回数';
COMMENT ON COLUMN sys_outbox_event.next_retry_at IS '次回再送日時';
COMMENT ON COLUMN sys_outbox_event.last_error IS '最終エラー';
COMMENT ON COLUMN sys_outbox_event.occurred_at IS '事実発生日時';
COMMENT ON COLUMN sys_outbox_event.published_at IS '配信日時';
COMMENT ON COLUMN sys_outbox_event.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN sys_outbox_event.company_id IS '公司 ID';
COMMENT ON COLUMN sys_outbox_event.created_at IS '创建时间';
COMMENT ON COLUMN sys_outbox_event.created_by IS '创建人';

-- sys_event_consume_log
CREATE TABLE sys_event_consume_log (
    id              BIGINT       NOT NULL,
    tenant_id       BIGINT       NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_by      BIGINT       NOT NULL DEFAULT 0,
    event_id            UUID          NOT NULL,           -- イベント ID
    event_type          VARCHAR(100)  NOT NULL,           -- イベント名
    consumer_name       VARCHAR(100)  NOT NULL,           -- 購読者（モジュール+リスナー名）
    consume_status      SMALLINT      NOT NULL DEFAULT 1, -- 1 成功 / 0 失敗
    retry_count         SMALLINT      NOT NULL DEFAULT 0, -- 再試行回数
    error_message       VARCHAR(1000),                    -- 失敗理由
    consumed_at         TIMESTAMPTZ   NOT NULL DEFAULT now(), -- 消費日時
    CONSTRAINT pk_sys_event_consume_log PRIMARY KEY (id)
);

ALTER TABLE sys_event_consume_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE sys_event_consume_log FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sys_event_consume_log
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_sys_event_consume_log ON sys_event_consume_log (tenant_id, event_id, consumer_name);
CREATE INDEX idx_sys_event_consume_log_type ON sys_event_consume_log (event_type, consumed_at DESC);
COMMENT ON TABLE sys_event_consume_log IS '事件消费日志（冪等重複排除）';
COMMENT ON COLUMN sys_event_consume_log.event_id IS 'イベント ID';
COMMENT ON COLUMN sys_event_consume_log.event_type IS 'イベント名';
COMMENT ON COLUMN sys_event_consume_log.consumer_name IS '購読者（モジュール+リスナー名）';
COMMENT ON COLUMN sys_event_consume_log.consume_status IS '1 成功 / 0 失敗';
COMMENT ON COLUMN sys_event_consume_log.retry_count IS '再試行回数';
COMMENT ON COLUMN sys_event_consume_log.error_message IS '失敗理由';
COMMENT ON COLUMN sys_event_consume_log.consumed_at IS '消費日時';
COMMENT ON COLUMN sys_event_consume_log.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN sys_event_consume_log.created_at IS '创建时间';
COMMENT ON COLUMN sys_event_consume_log.created_by IS '创建人';

-- sys_idempotency
CREATE TABLE sys_idempotency (
    id              BIGINT       NOT NULL,
    tenant_id       BIGINT       NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id      BIGINT       NOT NULL,
    version         INT          NOT NULL DEFAULT 0,
    remark          VARCHAR(500) NULL,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_by      BIGINT       NOT NULL DEFAULT 0,
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_by      BIGINT       NOT NULL DEFAULT 0,
    idempotency_key     VARCHAR(64)   NOT NULL,           -- クライアント生成キー（UUID）
    user_id             BIGINT        NOT NULL DEFAULT 0, -- 送信者
    request_path        VARCHAR(300)  NOT NULL,           -- リクエストパス
    request_hash        VARCHAR(64)   NOT NULL,           -- リクエストボディのハッシュ
    response_code       INT,                              -- 初回の業務コード
    response_body       TEXT,                             -- 初回のレスポンス JSON
    process_status      SMALLINT      NOT NULL DEFAULT 0, -- 0 処理中 / 1 完了
    expires_at          TIMESTAMPTZ   NOT NULL, -- 有効期限（作成+24 時間）
    CONSTRAINT pk_sys_idempotency PRIMARY KEY (id)
);

ALTER TABLE sys_idempotency ENABLE ROW LEVEL SECURITY;
ALTER TABLE sys_idempotency FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sys_idempotency
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_sys_idempotency_key ON sys_idempotency (tenant_id, idempotency_key);
CREATE INDEX idx_sys_idempotency_expire ON sys_idempotency (expires_at);
COMMENT ON TABLE sys_idempotency IS '幂等键（Idempotency-Key 管理）';
COMMENT ON COLUMN sys_idempotency.idempotency_key IS 'クライアント生成キー（UUID）';
COMMENT ON COLUMN sys_idempotency.user_id IS '送信者';
COMMENT ON COLUMN sys_idempotency.request_path IS 'リクエストパス';
COMMENT ON COLUMN sys_idempotency.request_hash IS 'リクエストボディのハッシュ';
COMMENT ON COLUMN sys_idempotency.response_code IS '初回の業務コード';
COMMENT ON COLUMN sys_idempotency.response_body IS '初回のレスポンス JSON';
COMMENT ON COLUMN sys_idempotency.process_status IS '0 処理中 / 1 完了';
COMMENT ON COLUMN sys_idempotency.expires_at IS '有効期限（作成+24 時間）';
COMMENT ON COLUMN sys_idempotency.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN sys_idempotency.company_id IS '公司 ID';
COMMENT ON COLUMN sys_idempotency.created_at IS '创建时间';
COMMENT ON COLUMN sys_idempotency.created_by IS '创建人';
COMMENT ON COLUMN sys_idempotency.updated_at IS '更新时间';
COMMENT ON COLUMN sys_idempotency.updated_by IS '更新人';
COMMENT ON COLUMN sys_idempotency.version IS '乐观锁版本';
COMMENT ON COLUMN sys_idempotency.remark IS '备注';

-- sys_user_preference
CREATE TABLE sys_user_preference (
    id              BIGINT       NOT NULL,
    tenant_id       BIGINT       NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id      BIGINT       NOT NULL,
    version         INT          NOT NULL DEFAULT 0,
    remark          VARCHAR(500) NULL,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_by      BIGINT       NOT NULL DEFAULT 0,
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_by      BIGINT       NOT NULL DEFAULT 0,
    user_id             BIGINT        NOT NULL,           -- ユーザ ID
    preference_type     SMALLINT      NOT NULL,           -- 类型：1 一覧列 / 2 検索条件 / 3 テーマ / 4 通知設定 / 5 ショートカット
    resource_key        VARCHAR(200)  NOT NULL,           -- 対象リソース（例 SCR-SAL-003）
    preference_value    JSONB         NOT NULL, -- 設定値
    CONSTRAINT pk_sys_user_preference PRIMARY KEY (id)
);

ALTER TABLE sys_user_preference ENABLE ROW LEVEL SECURITY;
ALTER TABLE sys_user_preference FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sys_user_preference
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_sys_user_preference ON sys_user_preference (tenant_id, user_id, preference_type, resource_key);
COMMENT ON TABLE sys_user_preference IS '用户画面设置（列構成・検索条件等）';
COMMENT ON COLUMN sys_user_preference.user_id IS 'ユーザ ID';
COMMENT ON COLUMN sys_user_preference.preference_type IS '类型：1 一覧列 / 2 検索条件 / 3 テーマ / 4 通知設定 / 5 ショートカット';
COMMENT ON COLUMN sys_user_preference.resource_key IS '対象リソース（例 SCR-SAL-003）';
COMMENT ON COLUMN sys_user_preference.preference_value IS '設定値';
COMMENT ON COLUMN sys_user_preference.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN sys_user_preference.company_id IS '公司 ID';
COMMENT ON COLUMN sys_user_preference.created_at IS '创建时间';
COMMENT ON COLUMN sys_user_preference.created_by IS '创建人';
COMMENT ON COLUMN sys_user_preference.updated_at IS '更新时间';
COMMENT ON COLUMN sys_user_preference.updated_by IS '更新人';
COMMENT ON COLUMN sys_user_preference.version IS '乐观锁版本';
COMMENT ON COLUMN sys_user_preference.remark IS '备注';

-- sys_data_maintenance_log
CREATE TABLE sys_data_maintenance_log (
    id              BIGINT       NOT NULL,
    tenant_id       BIGINT       NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_by      BIGINT       NOT NULL DEFAULT 0,
    maintenance_type    SMALLINT      NOT NULL,           -- 1 初期化 / 2 キャッシュ再構築 / 3 整合性検査 / 4 アーカイブ / 5 データ修正
    target              VARCHAR(200)  NOT NULL,           -- 対象（テーブル/モジュール/キャッシュ名）
    execute_mode        SMALLINT      NOT NULL DEFAULT 1, -- 1 ドライラン / 2 実行
    execute_result      SMALLINT      NOT NULL DEFAULT 1, -- 1 成功 / 0 失敗 / 2 一部成功
    affected_count      BIGINT        NOT NULL DEFAULT 0, -- 影響件数
    backup_path         VARCHAR(500),                     -- 実行前バックアップパス
    detail              JSONB,                            -- 実行結果明細
    operator_id         BIGINT        NOT NULL,           -- 実行依頼者
    approved_by         BIGINT,                           -- 承認者
    start_at            TIMESTAMPTZ   NOT NULL,           -- 開始日時
    end_at              TIMESTAMPTZ,                      -- 終了日時
    trace_id            VARCHAR(64), -- 追跡 ID
    CONSTRAINT pk_sys_data_maintenance_log PRIMARY KEY (id)
);

ALTER TABLE sys_data_maintenance_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE sys_data_maintenance_log FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sys_data_maintenance_log
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE INDEX idx_sys_data_maintenance_log_type ON sys_data_maintenance_log (maintenance_type, start_at DESC);
CREATE INDEX idx_sys_data_maintenance_log_operator ON sys_data_maintenance_log (operator_id, start_at DESC);
COMMENT ON TABLE sys_data_maintenance_log IS '数据维护历史（初期化・维护実行履歴）';
COMMENT ON COLUMN sys_data_maintenance_log.maintenance_type IS '1 初期化 / 2 キャッシュ再構築 / 3 整合性検査 / 4 アーカイブ / 5 データ修正';
COMMENT ON COLUMN sys_data_maintenance_log.target IS '対象（テーブル/モジュール/キャッシュ名）';
COMMENT ON COLUMN sys_data_maintenance_log.execute_mode IS '1 ドライラン / 2 実行';
COMMENT ON COLUMN sys_data_maintenance_log.execute_result IS '1 成功 / 0 失敗 / 2 一部成功';
COMMENT ON COLUMN sys_data_maintenance_log.affected_count IS '影響件数';
COMMENT ON COLUMN sys_data_maintenance_log.backup_path IS '実行前バックアップパス';
COMMENT ON COLUMN sys_data_maintenance_log.detail IS '実行結果明細';
COMMENT ON COLUMN sys_data_maintenance_log.operator_id IS '実行依頼者';
COMMENT ON COLUMN sys_data_maintenance_log.approved_by IS '承認者';
COMMENT ON COLUMN sys_data_maintenance_log.start_at IS '開始日時';
COMMENT ON COLUMN sys_data_maintenance_log.end_at IS '終了日時';
COMMENT ON COLUMN sys_data_maintenance_log.trace_id IS '追跡 ID';
COMMENT ON COLUMN sys_data_maintenance_log.tenant_id IS '租户 ID（RLS 隔离键）';
COMMENT ON COLUMN sys_data_maintenance_log.created_at IS '创建时间';
COMMENT ON COLUMN sys_data_maintenance_log.created_by IS '创建人';

