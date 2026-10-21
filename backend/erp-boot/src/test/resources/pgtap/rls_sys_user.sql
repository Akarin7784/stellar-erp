-- pgTAP：RLS 基础（sys_user）。由 db.PgTapSuiteTest 以 owner 连接在【全新会话】中整体执行，最后 ROLLBACK。
-- 约定：准备数据用 owner（RESET ROLE），断言前一律 SET ROLE erp_app。
-- 注意：第 1 组（未设置 app.tenant_id）必须在本会话首次 set_config 之前执行，
--       因为一旦设置过，自定义 GUC 在会话内会退化为空串而不再是“未定义”。
BEGIN;
SELECT plan(23);

-- 准备：两个租户的数据（owner 绕过 RLS，必须显式写 tenant_id）
INSERT INTO sys_user (id, tenant_id, company_id, user_code, username, real_name, password_hash) VALUES (98001, 101, 1, 'tap_alice', 'tap_alice', 'tap_alice', 'x'), (98002, 202, 1, 'tap_bob', 'tap_bob', 'tap_bob', 'x');

SET ROLE erp_app;
SELECT is(current_user::text, 'erp_app', '断言以 erp_app 身份执行');

-- 1. 未设置 app.tenant_id（新会话）
SELECT throws_ok($$SELECT count(*) FROM sys_user$$, '42704', NULL, '未设置租户：读报错');
SELECT throws_ok($$INSERT INTO sys_user (id, company_id, user_code, username, real_name, password_hash) VALUES (98010, 1, 'tap_x', 'tap_x', 'tap_x', 'x')$$, '42704', NULL, '未设置租户：写报错（默认值取 current_setting）');

-- 2. 空串
SELECT set_config('app.tenant_id', '', true);
SELECT throws_ok($$SELECT count(*) FROM sys_user$$, '22P02', NULL, '空串租户：读报错');
SELECT throws_ok($$INSERT INTO sys_user (id, company_id, user_code, username, real_name, password_hash) VALUES (98011, 1, 'tap_y', 'tap_y', 'tap_y', 'x')$$, '22P02', NULL, '空串租户：写报错');

-- 3. 租户 A 只看到自己的行
SELECT set_config('app.tenant_id', '101', true);
SELECT results_eq($$SELECT username::text FROM sys_user WHERE username LIKE 'tap_%' ORDER BY 1$$, ARRAY['tap_alice'], 'A 只看到 A 的行');
SELECT is_empty($$SELECT 1 FROM sys_user WHERE id = 98002$$, 'A 按主键也查不到 B 的行');
UPDATE sys_user SET nickname = 'hacked' WHERE id = 98002;
DELETE FROM sys_user WHERE id = 98002;

-- 4. WITH CHECK
SELECT throws_ok($$INSERT INTO sys_user (id, tenant_id, company_id, user_code, username, real_name, password_hash) VALUES (98012, 202, 1, 'tap_m', 'tap_m', 'tap_m', 'x')$$, '42501', NULL, 'WITH CHECK 拒绝 INSERT 到其他租户');
SELECT throws_ok($$UPDATE sys_user SET tenant_id = 202 WHERE id = 98001$$, '42501', NULL, 'WITH CHECK 拒绝把本租户行改为其他租户');

-- 5. 默认值取 current_setting
SELECT lives_ok($$INSERT INTO sys_user (id, company_id, user_code, username, real_name, password_hash) VALUES (98013, 1, 'tap_carol', 'tap_carol', 'tap_carol', 'x')$$, '不写 tenant_id 可插入');
SELECT is((SELECT tenant_id FROM sys_user WHERE id = 98013), 101::bigint, 'tenant_id 默认取 app.tenant_id');

-- 6. B 视角（同时验证上面 A 的 UPDATE/DELETE 对 B 的行无效）
SELECT set_config('app.tenant_id', '202', true);
SELECT is((SELECT nickname FROM sys_user WHERE id = 98002), NULL, 'A 的 UPDATE 未改到 B 的行');
SELECT results_eq($$SELECT username::text FROM sys_user WHERE username LIKE 'tap_%' ORDER BY 1$$, ARRAY['tap_bob'], 'B 只看到 B 的行（A 的 DELETE 未删掉 B 的行）');

-- 7. 角色属性
SELECT isnt_superuser('erp_app', 'erp_app 非超级用户');
SELECT ok(NOT (SELECT rolbypassrls FROM pg_roles WHERE rolname = 'erp_app'), 'erp_app 无 BYPASSRLS');
SELECT isnt((SELECT pg_get_userbyid(relowner)::text FROM pg_class WHERE oid = 'public.sys_user'::regclass), 'erp_app', 'erp_app 不是 sys_user 的 owner');
-- #46（Closes #7）：Flowable 表由 Flyway 预建在 schema flowable，public 下不得有 erp_app 拥有的表
SELECT is_empty($$SELECT c.relname FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
                 WHERE n.nspname = 'public' AND c.relkind IN ('r','p') AND pg_get_userbyid(c.relowner) = 'erp_app' ORDER BY 1$$, 'public 下没有 erp_app 拥有的对象');
-- #43：已删除 GRANT CREATE，erp_app 在 public 无 CREATE
SELECT ok(NOT has_schema_privilege('erp_app', 'public', 'CREATE'), 'erp_app 在 public 无 CREATE 权限');

-- 8. 目录级检查（以 owner 查目录，避免受权限影响）
RESET ROLE;
SELECT is_empty($$SELECT c.relname FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
                 JOIN pg_attribute a ON a.attrelid = c.oid AND a.attname = 'tenant_id' AND NOT a.attisdropped
                 WHERE n.nspname = 'public' AND c.relkind IN ('r','p') AND NOT (c.relrowsecurity AND c.relforcerowsecurity)$$,
                'public 中所有含 tenant_id 的表均 ENABLE + FORCE RLS');
SELECT is_empty($$SELECT c.relname || '.' || p.polname FROM pg_policy p JOIN pg_class c ON c.oid = p.polrelid
                 JOIN pg_namespace n ON n.oid = c.relnamespace
                 WHERE n.nspname = 'public' AND p.polcmd IN ('*','a','w') AND p.polwithcheck IS NULL$$,
                'public 中所有 ALL/INSERT/UPDATE 策略都有 WITH CHECK');
SELECT is_empty($$SELECT c.relname FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
                 JOIN pg_attribute a ON a.attrelid = c.oid AND a.attname = 'tenant_id' AND NOT a.attisdropped
                 WHERE n.nspname = 'public' AND c.relkind IN ('r','p') AND NOT EXISTS (SELECT 1 FROM pg_policy p WHERE p.polrelid = c.oid)$$,
                'public 中所有含 tenant_id 的表至少有一条策略');
-- 与 RlsCoverageTest.NON_TENANT_WHITELIST 一致：仅 flyway_schema_history
SELECT is_empty($$SELECT c.relname FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
                 WHERE n.nspname = 'public' AND c.relkind IN ('r','p')
                   AND c.relname NOT IN ('flyway_schema_history')
                   AND NOT EXISTS (SELECT 1 FROM pg_attribute a WHERE a.attrelid = c.oid AND a.attname = 'tenant_id' AND NOT a.attisdropped)$$,
                'public 中除白名单外所有表都有 tenant_id（白名单仅 flyway_schema_history）');
SELECT col_not_null('public', 'sys_user', 'tenant_id', 'sys_user.tenant_id NOT NULL');

SELECT * FROM finish();
ROLLBACK;
