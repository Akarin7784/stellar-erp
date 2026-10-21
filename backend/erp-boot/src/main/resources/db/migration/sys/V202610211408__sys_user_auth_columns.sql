-- sys_user 正式化：V1__baseline 的基线字段 → 01-system/90-db-design.md §3.6 正式定义；
-- uk_sys_tenant_code 全体唯一化；新增登录前查询函数 sys_auth_find_login_user（docs #74 ebb4f3c，蓝色大肥鱼 2026-10-21 #71 决定）。
-- 来源：
--   01-system/90-db-design.md:333-364（列定义）、:367-373（索引）、:375（制约）、:880（登录更新规格）
--   00-common/04-common-db-spec.md:181-190（§6.1 第 4 条 (b)：uk_sys_user_username 改名、tenant_id 默认值、pgTAP 例外登録）
--   00-common/01-common-item-definitions.md:28-36（共通カラム M）
--   01-system/01-auth-login.md:35、:65-86、:253-258（账号状态、登录处理）
-- 现有行：company_id 取该租户唯一的有效公司（不唯一则中止迁移）；user_code=username（超 16 字符则中止）；
--         real_name=coalesce(nickname, username)；password 列改名为 password_hash（保留哈希）；
--         基线 status=0（停用）→ account_status=3（停用），status 保持原值（新语义：0 离职）。
--         password_reset_required 默认 TRUE（现有账号下次登录须改密）。

-- 1. 共通カラム M 补齐
ALTER TABLE sys_user
    ADD COLUMN company_id  BIGINT,
    ADD COLUMN version     INT          NOT NULL DEFAULT 0,
    ADD COLUMN remark      VARCHAR(500),
    ADD COLUMN ext_data    JSONB,
    ADD COLUMN created_by  BIGINT       NOT NULL DEFAULT 0,
    ADD COLUMN updated_by  BIGINT       NOT NULL DEFAULT 0;

-- tenant_id 默认值：已由 sys/V202610200102 改为 current_setting('app.tenant_id')（04 §6.1 第 4 条 (b) 要求的“修正”），此处再次显式设定以固化
ALTER TABLE sys_user ALTER COLUMN tenant_id SET DEFAULT current_setting('app.tenant_id')::bigint;

-- 2. 业务列
ALTER TABLE sys_user RENAME COLUMN password TO password_hash;
ALTER TABLE sys_user ALTER COLUMN password_hash TYPE VARCHAR(100);
ALTER TABLE sys_user ALTER COLUMN nickname TYPE VARCHAR(50);

ALTER TABLE sys_user
    ADD COLUMN user_code               VARCHAR(16),
    ADD COLUMN real_name               VARCHAR(50),
    ADD COLUMN gender                  SMALLINT     NOT NULL DEFAULT 0,
    ADD COLUMN birth_date              DATE,
    ADD COLUMN mobile                  VARCHAR(20),
    ADD COLUMN email                   VARCHAR(100),
    ADD COLUMN avatar_attachment_id    BIGINT,
    ADD COLUMN employee_type           SMALLINT     NOT NULL DEFAULT 1,
    ADD COLUMN department_id           BIGINT,
    ADD COLUMN position_id             BIGINT,
    ADD COLUMN factory_id              BIGINT,
    ADD COLUMN manager_user_id         BIGINT,
    ADD COLUMN hire_date               DATE,
    ADD COLUMN leave_date              DATE,
    ADD COLUMN account_status          SMALLINT     NOT NULL DEFAULT 1,
    ADD COLUMN lock_until              TIMESTAMPTZ,
    ADD COLUMN login_fail_count        SMALLINT     NOT NULL DEFAULT 0,
    ADD COLUMN password_updated_at     TIMESTAMPTZ,
    ADD COLUMN password_expire_at      TIMESTAMPTZ,
    ADD COLUMN password_reset_required BOOLEAN      NOT NULL DEFAULT TRUE,
    ADD COLUMN last_login_at           TIMESTAMPTZ,
    ADD COLUMN last_login_ip           VARCHAR(45),
    ADD COLUMN is_builtin              BOOLEAN      NOT NULL DEFAULT FALSE,
    ADD COLUMN sort_no                 INT          NOT NULL DEFAULT 0;

-- 3. 现有行回填（owner 带 BYPASSRLS 执行；不满足条件即中止，不猜）
DO $$
DECLARE
    v_bad TEXT;
BEGIN
    SELECT string_agg(DISTINCT u.tenant_id::text, ',') INTO v_bad
      FROM sys_user u
     WHERE (SELECT count(*) FROM sys_company c WHERE c.tenant_id = u.tenant_id AND c.deleted = FALSE) <> 1;
    IF v_bad IS NOT NULL THEN
        RAISE EXCEPTION 'sys_user 回填中止：租户 % 的有效公司数不为 1，无法确定现有用户的 company_id', v_bad;
    END IF;
    SELECT string_agg(u.id::text, ',') INTO v_bad FROM sys_user u WHERE length(u.username) > 16;
    IF v_bad IS NOT NULL THEN
        RAISE EXCEPTION 'sys_user 回填中止：用户 % 的 username 超过 16 字符，不能作为 user_code', v_bad;
    END IF;

    UPDATE sys_user u
       SET company_id = (SELECT c.id FROM sys_company c WHERE c.tenant_id = u.tenant_id AND c.deleted = FALSE),
           user_code  = u.username,
           real_name  = left(coalesce(nullif(u.nickname, ''), u.username), 50),
           account_status = CASE WHEN u.status = 0 THEN 3 ELSE 1 END;
END
$$;

ALTER TABLE sys_user
    ALTER COLUMN company_id SET NOT NULL,
    ALTER COLUMN user_code  SET NOT NULL,
    ALTER COLUMN real_name  SET NOT NULL;

-- 4. CHECK（04 §6：列挙値・符号。取值见 90 §3.6 列注释、01-auth-login.md:65-86）
ALTER TABLE sys_user
    ADD CONSTRAINT ck_sys_user_status           CHECK (status IN (0, 1, 2)),
    ADD CONSTRAINT ck_sys_user_account_status   CHECK (account_status IN (1, 2, 3, 4)),
    ADD CONSTRAINT ck_sys_user_login_fail_count CHECK (login_fail_count >= 0);

-- 5. 索引（90 §3.6 :367-373）
ALTER INDEX uk_sys_user_tenant_username RENAME TO uk_sys_user_username;
CREATE UNIQUE INDEX uk_sys_user_code ON sys_user (tenant_id, company_id, user_code) WHERE deleted = FALSE;
CREATE INDEX idx_sys_user_dept_status ON sys_user (tenant_id, company_id, department_id, status);
CREATE INDEX idx_sys_user_name_trgm ON sys_user USING gin (real_name gin_trgm_ops);
CREATE INDEX idx_sys_user_mobile ON sys_user (tenant_id, company_id, mobile);
-- 复合外键被引用用（04 §6.2 项 2；04-purchase/90 等以 (tenant_id, x_id) → sys_user (tenant_id, id) 引用）
ALTER TABLE sys_user ADD CONSTRAINT uk_sys_user_tenant_id UNIQUE (tenant_id, id);

-- 6. 注释
COMMENT ON TABLE sys_user IS '用户（登录账号＋员工属性）';
COMMENT ON COLUMN sys_user.id IS '雪花 ID（主键）';
COMMENT ON COLUMN sys_user.tenant_id IS '租户 ID（RLS 隔离键）；默认取 current_setting(''app.tenant_id'')，未设置租户上下文时插入失败';
COMMENT ON COLUMN sys_user.company_id IS '公司 ID（sys_company.id，无默认值）';
COMMENT ON COLUMN sys_user.version IS '乐观锁版本';
COMMENT ON COLUMN sys_user.deleted IS '逻辑删除';
COMMENT ON COLUMN sys_user.remark IS '备注';
COMMENT ON COLUMN sys_user.ext_data IS '扩展字段';
COMMENT ON COLUMN sys_user.created_at IS '创建时间';
COMMENT ON COLUMN sys_user.created_by IS '创建人';
COMMENT ON COLUMN sys_user.updated_at IS '更新时间';
COMMENT ON COLUMN sys_user.updated_by IS '更新人';
COMMENT ON COLUMN sys_user.user_code IS '工号（用户账号，E+6 位，08 2.2）';
COMMENT ON COLUMN sys_user.username IS '登录账号（默认=工号，不可变更）；租户级唯一';
COMMENT ON COLUMN sys_user.password_hash IS 'BCrypt 哈希（cost≥10，禁止明文）';
COMMENT ON COLUMN sys_user.real_name IS '姓名';
COMMENT ON COLUMN sys_user.nickname IS '昵称';
COMMENT ON COLUMN sys_user.gender IS '性别：0 未填 / 1 男 / 2 女';
COMMENT ON COLUMN sys_user.birth_date IS '出生日期（任意，脱敏对象）';
COMMENT ON COLUMN sys_user.mobile IS '手机号（显示时脱敏）';
COMMENT ON COLUMN sys_user.email IS '邮箱';
COMMENT ON COLUMN sys_user.avatar_attachment_id IS '头像附件 ID';
COMMENT ON COLUMN sys_user.employee_type IS '用工类型：1 正式 / 2 试用 / 3 外包 / 4 实习';
COMMENT ON COLUMN sys_user.department_id IS '所属部门（sys_department.id）';
COMMENT ON COLUMN sys_user.position_id IS '主岗位（sys_position.id）';
COMMENT ON COLUMN sys_user.factory_id IS '所属工厂（mdm_factory.id，作为默认值使用）';
COMMENT ON COLUMN sys_user.manager_user_id IS '直属上级（sys_user.id，审批升级对象）';
COMMENT ON COLUMN sys_user.hire_date IS '入职日期';
COMMENT ON COLUMN sys_user.leave_date IS '离职日期';
COMMENT ON COLUMN sys_user.status IS '在职状态：1 在职 / 0 离职 / 2 待入职';
COMMENT ON COLUMN sys_user.account_status IS '账号状态：1 正常 / 2 锁定 / 3 停用 / 4 密码过期';
COMMENT ON COLUMN sys_user.lock_until IS '锁定解除时间（NULL=无期限）';
COMMENT ON COLUMN sys_user.login_fail_count IS '连续登录失败次数';
COMMENT ON COLUMN sys_user.password_updated_at IS '密码最后更新时间';
COMMENT ON COLUMN sys_user.password_expire_at IS '密码有效期（90 天）';
COMMENT ON COLUMN sys_user.password_reset_required IS '下次登录必须改密（初次/管理员重置）';
COMMENT ON COLUMN sys_user.last_login_at IS '最后登录时间';
COMMENT ON COLUMN sys_user.last_login_ip IS '最后登录 IP';
COMMENT ON COLUMN sys_user.is_builtin IS '内置账号（管理员初始化，不可删除）';
COMMENT ON COLUMN sys_user.sort_no IS '显示顺序';

-- 7. uk_sys_tenant_code 改为全体唯一 (tenant_code) WHERE deleted=FALSE（#74：04 §6.1 第 4 条 (c) 具名例外、01/90 §3.3）
DO $$
DECLARE v_dup TEXT;
BEGIN
    SELECT string_agg(tenant_code, ',') INTO v_dup FROM (
        SELECT tenant_code FROM sys_tenant WHERE deleted = FALSE GROUP BY tenant_code HAVING count(*) > 1) d;
    IF v_dup IS NOT NULL THEN
        RAISE EXCEPTION 'uk_sys_tenant_code 全体唯一化中止：未删除租户中 tenant_code 重复：%（请先人工处理）', v_dup;
    END IF;
END
$$;
DROP INDEX uk_sys_tenant_code;
CREATE UNIQUE INDEX uk_sys_tenant_code ON sys_tenant (tenant_code) WHERE deleted = FALSE;

-- 8. 登录前查询：sys_auth_find_login_user(p_tenant_code, p_username)（#74：01-auth-login PRC-SYS-001-02 手顺 2、01/90 §3.3）
--    登录时尚无 app.tenant_id，erp_app 受 FORCE RLS 约束无法查 sys_user；本函数以 owner（BYPASSRLS）执行，
--    函数内显式按 tenant_id 过滤。租户须 status=1、未删除、未过期（expire_date IS NULL OR >= current_date）。
--    租户不存在/无效/过期、用户不存在/已删除：一律 0 行（不可区分）。只返回认证所需最少字段（不含姓名、联系方式）。
--    tenant_code、username 精确匹配（不做大小写折叠）。
CREATE FUNCTION public.sys_auth_find_login_user(p_tenant_code VARCHAR, p_username VARCHAR)
RETURNS TABLE (
    tenant_id               BIGINT,
    user_id                 BIGINT,
    company_id              BIGINT,
    password_hash           VARCHAR,
    status                  SMALLINT,
    account_status          SMALLINT,
    lock_until              TIMESTAMPTZ,
    login_fail_count        SMALLINT,
    password_reset_required BOOLEAN,
    password_expire_at      TIMESTAMPTZ,
    version                 INT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
    SELECT u.tenant_id, u.id, u.company_id, u.password_hash, u.status, u.account_status,
           u.lock_until, u.login_fail_count, u.password_reset_required, u.password_expire_at, u.version
      FROM public.sys_tenant t
      JOIN public.sys_user u ON u.tenant_id = t.tenant_id
     WHERE t.tenant_code = p_tenant_code
       AND t.deleted = FALSE
       AND t.status = 1
       AND (t.expire_date IS NULL OR t.expire_date >= current_date)
       AND u.username = p_username
       AND u.deleted = FALSE
$$;
COMMENT ON FUNCTION public.sys_auth_find_login_user(VARCHAR, VARCHAR) IS
    '登录前按 (tenant_code, username) 取认证所需最少字段；SECURITY DEFINER，显式按 tenant_id 过滤；租户无效/过期/不存在与用户不存在均返回 0 行';
REVOKE ALL ON FUNCTION public.sys_auth_find_login_user(VARCHAR, VARCHAR) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.sys_auth_find_login_user(VARCHAR, VARCHAR) TO erp_app;
