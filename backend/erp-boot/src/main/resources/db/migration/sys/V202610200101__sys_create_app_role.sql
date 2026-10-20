-- 应用运行账号 erp_app：非 owner、非超级用户、无 BYPASSRLS。
-- 本脚本只创建 NOLOGIN 角色；LOGIN 与密码由 db/callback/afterMigrate.sql 依据占位符 erp_app_password 设置（为空则不启用登录）。
-- Flyway 以 owner 账号执行，所有表归 owner 所有，因此 FORCE ROW LEVEL SECURITY 对 erp_app 生效。
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'erp_app') THEN
        CREATE ROLE erp_app NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS NOREPLICATION INHERIT;
    END IF;
END
$$;

GRANT USAGE ON SCHEMA public TO erp_app;
-- Flowable 由应用数据源（erp_app）在 public 自动建表，需要 CREATE；迁出到独立 schema 见 issue #7
GRANT CREATE ON SCHEMA public TO erp_app;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO erp_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO erp_app;
-- 之后由 owner（Flyway）创建的表/序列自动授权
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO erp_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO erp_app;
