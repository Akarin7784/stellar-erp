-- pgTAP：sys_user 正式化（sys/V202610211408；01-system/90-db-design.md §3.6）+ 登录前查询函数 sys_auth_find_login_user。
-- owner 连接执行（superuser，绕过 RLS），最后 ROLLBACK。
BEGIN;
SELECT plan(103);

-- 1. 列存在与类型（90 §3.6 :333-364）
SELECT columns_are('public', 'sys_user', ARRAY[
    'id', 'tenant_id', 'company_id', 'version', 'deleted', 'remark', 'ext_data',
    'created_at', 'created_by', 'updated_at', 'updated_by',
    'user_code', 'username', 'password_hash', 'real_name', 'nickname', 'gender', 'birth_date', 'mobile', 'email',
    'avatar_attachment_id', 'employee_type', 'department_id', 'position_id', 'factory_id', 'manager_user_id',
    'hire_date', 'leave_date', 'status', 'account_status', 'lock_until', 'login_fail_count',
    'password_updated_at', 'password_expire_at', 'password_reset_required', 'last_login_at', 'last_login_ip',
    'is_builtin', 'sort_no']::name[], 'sys_user 列集合 = 共通 M + §3.6（基线 password 已改名）');
SELECT hasnt_column('public', 'sys_user', 'password', '基线 password 列已不存在');
SELECT col_type_is('public', 'sys_user', 'company_id', 'bigint', 'company_id BIGINT');
SELECT col_type_is('public', 'sys_user', 'user_code', 'character varying(16)', 'user_code VARCHAR(16)');
SELECT col_type_is('public', 'sys_user', 'username', 'character varying(64)', 'username VARCHAR(64)');
SELECT col_type_is('public', 'sys_user', 'password_hash', 'character varying(100)', 'password_hash VARCHAR(100)');
SELECT col_type_is('public', 'sys_user', 'real_name', 'character varying(50)', 'real_name VARCHAR(50)');
SELECT col_type_is('public', 'sys_user', 'nickname', 'character varying(50)', 'nickname VARCHAR(50)');
SELECT col_type_is('public', 'sys_user', 'mobile', 'character varying(20)', 'mobile VARCHAR(20)');
SELECT col_type_is('public', 'sys_user', 'email', 'character varying(100)', 'email VARCHAR(100)');
SELECT col_type_is('public', 'sys_user', 'account_status', 'smallint', 'account_status SMALLINT');
SELECT col_type_is('public', 'sys_user', 'lock_until', 'timestamp with time zone', 'lock_until TIMESTAMPTZ');
SELECT col_type_is('public', 'sys_user', 'login_fail_count', 'smallint', 'login_fail_count SMALLINT');
SELECT col_type_is('public', 'sys_user', 'password_reset_required', 'boolean', 'password_reset_required BOOLEAN');
SELECT col_type_is('public', 'sys_user', 'last_login_ip', 'character varying(45)', 'last_login_ip VARCHAR(45)');
SELECT col_type_is('public', 'sys_user', 'ext_data', 'jsonb', 'ext_data JSONB');

-- 2. NOT NULL / NULL
SELECT col_not_null('public', 'sys_user', c, 'NOT NULL: ' || c) FROM unnest(ARRAY[
    'tenant_id', 'company_id', 'version', 'created_by', 'updated_by', 'user_code', 'username', 'password_hash', 'real_name',
    'gender', 'employee_type', 'status', 'account_status', 'login_fail_count', 'password_reset_required', 'is_builtin', 'sort_no']::name[]) c;
SELECT col_is_null('public', 'sys_user', c, 'NULL 允许: ' || c) FROM unnest(ARRAY[
    'nickname', 'lock_until', 'department_id', 'last_login_at', 'password_expire_at']::name[]) c;

-- 3. 默认值
SELECT col_hasnt_default('public', 'sys_user', 'company_id', 'company_id 无默认值（04 §6.1 第 2 条）');
SELECT col_default_is('public', 'sys_user', 'tenant_id', $$(current_setting('app.tenant_id'::text))::bigint$$, 'tenant_id 默认取 app.tenant_id（非 0）');
SELECT col_default_is('public', 'sys_user', 'account_status', '1', 'account_status 默认 1');
SELECT col_default_is('public', 'sys_user', 'login_fail_count', '0', 'login_fail_count 默认 0');
SELECT col_default_is('public', 'sys_user', 'password_reset_required', 'true', 'password_reset_required 默认 TRUE');
SELECT col_default_is('public', 'sys_user', 'gender', '0', 'gender 默认 0');
SELECT col_default_is('public', 'sys_user', 'employee_type', '1', 'employee_type 默认 1');
SELECT col_default_is('public', 'sys_user', 'is_builtin', 'false', 'is_builtin 默认 FALSE');
SELECT col_default_is('public', 'sys_user', 'version', '0', 'version 默认 0');

-- 4. 索引（90 §3.6 :367-373）
SELECT is((SELECT indexdef FROM pg_indexes WHERE indexname = 'uk_sys_user_username'),
          'CREATE UNIQUE INDEX uk_sys_user_username ON public.sys_user USING btree (tenant_id, username) WHERE (deleted = false)',
          'uk_sys_user_username = (tenant_id, username) WHERE deleted=FALSE（租户级）');
SELECT hasnt_index('public', 'sys_user', 'uk_sys_user_tenant_username', '旧名 uk_sys_user_tenant_username 已改名');
SELECT is((SELECT indexdef FROM pg_indexes WHERE indexname = 'uk_sys_user_code'),
          'CREATE UNIQUE INDEX uk_sys_user_code ON public.sys_user USING btree (tenant_id, company_id, user_code) WHERE (deleted = false)',
          'uk_sys_user_code = (tenant_id, company_id, user_code) WHERE deleted=FALSE');
SELECT is((SELECT indexdef FROM pg_indexes WHERE indexname = 'idx_sys_user_dept_status'),
          'CREATE INDEX idx_sys_user_dept_status ON public.sys_user USING btree (tenant_id, company_id, department_id, status)', 'idx_sys_user_dept_status');
SELECT is((SELECT indexdef FROM pg_indexes WHERE indexname = 'idx_sys_user_name_trgm'),
          'CREATE INDEX idx_sys_user_name_trgm ON public.sys_user USING gin (real_name gin_trgm_ops)', 'idx_sys_user_name_trgm（GIN）');
SELECT is((SELECT indexdef FROM pg_indexes WHERE indexname = 'idx_sys_user_mobile'),
          'CREATE INDEX idx_sys_user_mobile ON public.sys_user USING btree (tenant_id, company_id, mobile)', 'idx_sys_user_mobile');
SELECT col_is_unique('public', 'sys_user', ARRAY['tenant_id', 'id']::name[], 'UNIQUE (tenant_id, id)（复合 FK 被引用）');

-- 5. 数据行为（owner 准备，显式 tenant_id）
INSERT INTO sys_tenant (id, tenant_id, tenant_code, tenant_name, status, expire_date) VALUES
       (9401, 9401, 'TAPA', 'tap A', 1, NULL), (9402, 9402, 'TAPB', 'tap B', 1, current_date),
       (9403, 9403, 'TAPDEL', 'tap deleted', 1, NULL), (9405, 9405, 'TAPOFF', 'tap disabled', 0, NULL),
       (9406, 9406, 'TAPEXP', 'tap expired', 1, current_date - 1);
UPDATE sys_tenant SET deleted = TRUE WHERE id = 9403;
INSERT INTO sys_user (id, tenant_id, company_id, user_code, username, real_name, password_hash)
VALUES (94011, 9401, 940101, 'E000001', 'alice', '张三', '$2a$10$hashA'),
       (94021, 9402, 940201, 'E000001', 'bob',   '李四', '$2a$10$hashB'),
       (94031, 9403, 940301, 'E000001', 'alice', '王五', '$2a$10$hashC'),
       (94012, 9401, 940101, 'E000002', 'gone',  '赵六', '$2a$10$hashD'),
       (94051, 9405, 940501, 'E000001', 'alice', '孙七', '$2a$10$hashE'),
       (94061, 9406, 940601, 'E000001', 'alice', '周八', '$2a$10$hashF');
UPDATE sys_user SET deleted = TRUE WHERE id = 94012;

SELECT is((SELECT row(account_status, login_fail_count, password_reset_required, lock_until IS NULL)::text FROM sys_user WHERE id = 94011),
          '(1,0,t,t)', '新行默认：account_status=1 / login_fail_count=0 / 须改密 / 未锁定');
SELECT throws_ok($$INSERT INTO sys_user (id, tenant_id, company_id, user_code, username, real_name, password_hash) VALUES (94013, 9401, 940102, 'E000009', 'alice', 'x', 'h')$$,
                 '23505', NULL, '同租户 username 重复（跨公司也不行）→ 23505');
SELECT lives_ok($$INSERT INTO sys_user (id, tenant_id, company_id, user_code, username, real_name, password_hash) VALUES (94022, 9402, 940201, 'E000002', 'alice', 'x', 'h')$$,
                '其他租户可用相同 username');
SELECT throws_ok($$INSERT INTO sys_user (id, tenant_id, company_id, user_code, username, real_name, password_hash) VALUES (94014, 9401, 940101, 'E000001', 'carol', 'x', 'h')$$,
                 '23505', NULL, '同租户同公司 user_code 重复 → 23505');
SELECT lives_ok($$INSERT INTO sys_user (id, tenant_id, company_id, user_code, username, real_name, password_hash) VALUES (94015, 9401, 940101, 'E000002', 'gone', 'x', 'h')$$,
                '已逻辑删除的 username / user_code 可复用（部分唯一）');
UPDATE sys_user SET deleted = TRUE WHERE id = 94015;  -- 复用行也删掉，供第 7 组“已删除用户”断言
SELECT throws_ok($$INSERT INTO sys_user (id, tenant_id, user_code, username, real_name, password_hash) VALUES (94016, 9401, 'E000016', 'u16', 'x', 'h')$$,
                 '23502', NULL, '缺 company_id → 23502');
SELECT throws_ok($$INSERT INTO sys_user (id, tenant_id, company_id, username, real_name, password_hash) VALUES (94017, 9401, 940101, 'u17', 'x', 'h')$$,
                 '23502', NULL, '缺 user_code → 23502');
SELECT throws_ok($$INSERT INTO sys_user (id, tenant_id, company_id, user_code, username, password_hash) VALUES (94018, 9401, 940101, 'E000018', 'u18', 'h')$$,
                 '23502', NULL, '缺 real_name → 23502');
SELECT throws_ok($$UPDATE sys_user SET account_status = 5 WHERE id = 94011$$, '23514', NULL, 'ck_sys_user_account_status：5 → 23514');
SELECT throws_ok($$UPDATE sys_user SET status = 3 WHERE id = 94011$$, '23514', NULL, 'ck_sys_user_status：3 → 23514');
SELECT throws_ok($$UPDATE sys_user SET login_fail_count = -1 WHERE id = 94011$$, '23514', NULL, 'ck_sys_user_login_fail_count：-1 → 23514');

-- 6. sys_auth_find_login_user：定义属性与权限
SELECT ok((SELECT prosecdef FROM pg_proc WHERE oid = 'public.sys_auth_find_login_user(varchar, varchar)'::regprocedure), '函数为 SECURITY DEFINER');
SELECT ok((SELECT proconfig @> ARRAY['search_path=pg_catalog, public'] FROM pg_proc WHERE oid = 'public.sys_auth_find_login_user(varchar, varchar)'::regprocedure),
          '函数固定 search_path=pg_catalog, public');
SELECT ok(NOT has_function_privilege('public', 'public.sys_auth_find_login_user(varchar, varchar)', 'EXECUTE'), 'PUBLIC 无 EXECUTE');
SELECT ok(has_function_privilege('erp_app', 'public.sys_auth_find_login_user(varchar, varchar)', 'EXECUTE'), 'erp_app 有 EXECUTE');
SELECT is((SELECT count(*)::int FROM aclexplode((SELECT proacl FROM pg_proc WHERE oid = 'public.sys_auth_find_login_user(varchar, varchar)'::regprocedure)) a
            WHERE a.privilege_type = 'EXECUTE' AND a.grantee <> (SELECT proowner FROM pg_proc WHERE oid = 'public.sys_auth_find_login_user(varchar, varchar)'::regprocedure)),
          1, 'EXECUTE 只授予 erp_app（owner 除外）');

-- 7. 以 erp_app、无租户上下文调用
SET ROLE erp_app;
SELECT results_eq($$SELECT tenant_id, user_id, company_id, password_hash::text, account_status::int, login_fail_count::int, version FROM sys_auth_find_login_user('TAPA', 'alice')$$,
                  $$VALUES (9401::bigint, 94011::bigint, 940101::bigint, '$2a$10$hashA', 1, 0, 0)$$,
                  'TAPA/alice：返回租户 9401 的 alice（无 app.tenant_id 也可查）');
SELECT is_empty($$SELECT * FROM sys_auth_find_login_user('TAPA', 'bob')$$, '其他租户的 username（bob@TAPB）在 TAPA 下查不到');
SELECT is_empty($$SELECT * FROM sys_auth_find_login_user('NOPE', 'alice')$$, '未知租户 → 0 行');
SELECT is_empty($$SELECT * FROM sys_auth_find_login_user('TAPA', 'nobody')$$, '未知用户 → 0 行（与未知租户不可区分）');
SELECT is_empty($$SELECT * FROM sys_auth_find_login_user('TAPA', 'gone')$$, '已删除用户 → 0 行');
SELECT is_empty($$SELECT * FROM sys_auth_find_login_user('TAPDEL', 'alice')$$, '已删除租户 → 0 行');
SELECT is_empty($$SELECT * FROM sys_auth_find_login_user('TAPOFF', 'alice')$$, '无效租户（status=0）→ 0 行');
SELECT is_empty($$SELECT * FROM sys_auth_find_login_user('TAPEXP', 'alice')$$, '过期租户（expire_date < 今天）→ 0 行');
SELECT is((SELECT count(*)::int FROM sys_auth_find_login_user('TAPB', 'bob')), 1, 'expire_date = 今天仍有效');
SELECT is_empty($$SELECT * FROM sys_auth_find_login_user(NULL, 'alice')$$, 'tenant_code NULL → 0 行');
SELECT throws_ok($$SELECT count(*) FROM sys_user$$, '42704', NULL, 'erp_app 无租户上下文直接查 sys_user 仍报错（RLS 未被放开）');
RESET ROLE;

-- 8. uk_sys_tenant_code 全体唯一（#74：04 §6.1 第 4 条 (c)）
SELECT is((SELECT indexdef FROM pg_indexes WHERE indexname = 'uk_sys_tenant_code'),
          'CREATE UNIQUE INDEX uk_sys_tenant_code ON public.sys_tenant USING btree (tenant_code) WHERE (deleted = false)',
          'uk_sys_tenant_code = (tenant_code) WHERE deleted=FALSE');
SELECT throws_ok($$INSERT INTO sys_tenant (id, tenant_id, tenant_code, tenant_name) VALUES (9404, 9404, 'TAPA', 'dup code')$$,
                 '23505', NULL, '不同租户 tenant_code 重复 → 23505');
SELECT lives_ok($$INSERT INTO sys_tenant (id, tenant_id, tenant_code, tenant_name) VALUES (9407, 9407, 'TAPDEL', 're-use')$$,
                '已删除租户的 tenant_code 可复用');
SELECT ok((SELECT proretset FROM pg_proc WHERE oid = 'public.sys_auth_find_login_user(varchar, varchar)'::regprocedure)
          AND NOT EXISTS (SELECT 1 FROM unnest((SELECT proargnames FROM pg_proc WHERE oid = 'public.sys_auth_find_login_user(varchar, varchar)'::regprocedure)) n
                          WHERE n IN ('real_name', 'nickname', 'mobile', 'email', 'username')),
          '返回列不含姓名/联系方式');

-- 9. tenant_code 大写（#75 决定）
SELECT throws_ok($$INSERT INTO sys_tenant (id, tenant_id, tenant_code, tenant_name) VALUES (9408, 9408, 'lower', 'x')$$,
                 '23514', NULL, '小写 tenant_code → ck_sys_tenant_code_upper 23514');
SELECT is((SELECT count(*)::int FROM sys_tenant WHERE tenant_code <> upper(tenant_code)), 0, '现有 tenant_code 均为大写');
SET ROLE erp_app;
SELECT is((SELECT user_id FROM sys_auth_find_login_user('tapa', 'alice')), 94011::bigint, '小写企业代码输入也能查到（upper 匹配）');
SELECT is_empty($$SELECT * FROM sys_auth_find_login_user('TAPA', 'ALICE')$$, 'username 区分大小写：ALICE ≠ alice');
RESET ROLE;

-- 10. gender CHECK
SELECT throws_ok($$UPDATE sys_user SET gender = 3 WHERE id = 94011$$, '23514', NULL, 'ck_sys_user_gender：3 → 23514');
SELECT lives_ok($$UPDATE sys_user SET gender = 2 WHERE id = 94011$$, 'gender=2 可');
SELECT is_empty($$SELECT conname FROM pg_constraint WHERE conrelid = 'public.sys_user'::regclass AND contype = 'c' AND pg_get_constraintdef(oid) LIKE '%employee_type%'$$, 'employee_type 无 CHECK（#75 决定）');

-- 11. 外键（可空、同租户 2 列）
INSERT INTO sys_department (id, tenant_id, company_id, department_code, department_name) VALUES (94101, 9401, 940101, 'D001', 'd'), (94201, 9402, 940201, 'D001', 'd');
INSERT INTO sys_position (id, tenant_id, company_id, position_code, position_name) VALUES (94102, 9401, 940101, 'P1', 'p'), (94202, 9402, 940201, 'P1', 'p');
INSERT INTO mdm_factory (id, tenant_id, company_id, factory_code, factory_name) VALUES (94103, 9401, 940101, 'F1', 'f'), (94203, 9402, 940201, 'F1', 'f');
SELECT is((SELECT pg_get_constraintdef(oid) FROM pg_constraint WHERE conname = 'fk_sys_user_department'),
          'FOREIGN KEY (tenant_id, department_id) REFERENCES sys_department(tenant_id, id)', 'fk_sys_user_department 2 列');
SELECT is((SELECT pg_get_constraintdef(oid) FROM pg_constraint WHERE conname = 'fk_sys_user_position'),
          'FOREIGN KEY (tenant_id, position_id) REFERENCES sys_position(tenant_id, id)', 'fk_sys_user_position 2 列');
SELECT is((SELECT pg_get_constraintdef(oid) FROM pg_constraint WHERE conname = 'fk_sys_user_factory'),
          'FOREIGN KEY (tenant_id, factory_id) REFERENCES mdm_factory(tenant_id, id)', 'fk_sys_user_factory 2 列');
SELECT is((SELECT pg_get_constraintdef(oid) FROM pg_constraint WHERE conname = 'fk_sys_user_manager'),
          'FOREIGN KEY (tenant_id, manager_user_id) REFERENCES sys_user(tenant_id, id)', 'fk_sys_user_manager 自引用 2 列');
SELECT lives_ok($$UPDATE sys_user SET department_id = 94101, position_id = 94102, factory_id = 94103, manager_user_id = 94011 WHERE id = 94011$$,
                '同租户引用部门/岗位/工厂/上级 → 可');
SELECT throws_ok($$UPDATE sys_user SET department_id = 94201 WHERE id = 94011$$, '23503', NULL, '引用其他租户的部门 → 23503');
SELECT throws_ok($$UPDATE sys_user SET position_id = 94202 WHERE id = 94011$$, '23503', NULL, '引用其他租户的岗位 → 23503');
SELECT throws_ok($$UPDATE sys_user SET factory_id = 94203 WHERE id = 94011$$, '23503', NULL, '引用其他租户的工厂 → 23503');
SELECT throws_ok($$UPDATE sys_user SET manager_user_id = 94021 WHERE id = 94011$$, '23503', NULL, '上级为其他租户用户 → 23503');
SELECT throws_ok($$UPDATE sys_user SET department_id = 0 WHERE id = 94011$$, '23503', NULL, '0 不再作为“未设置”（应为 NULL）→ 23503');
SELECT lives_ok($$UPDATE sys_user SET department_id = NULL, position_id = NULL, factory_id = NULL, manager_user_id = NULL WHERE id = 94011$$,
                '四个外键列均可为 NULL');

SELECT * FROM finish();
ROLLBACK;
