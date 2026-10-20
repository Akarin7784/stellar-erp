-- sys_user 启用 RLS（模板见 docs/design/00-common/10-rls-and-db-roles.md）
-- tenant_id 不再静默默认 0：默认取当前事务的 app.tenant_id，未设置时报错（有意为之）
ALTER TABLE sys_user ALTER COLUMN tenant_id DROP DEFAULT;
ALTER TABLE sys_user ALTER COLUMN tenant_id SET DEFAULT current_setting('app.tenant_id')::bigint;
COMMENT ON COLUMN sys_user.tenant_id IS '租户 ID；默认取 current_setting(''app.tenant_id'')，未设置租户上下文时插入失败；RLS 隔离键';

ALTER TABLE sys_user ENABLE ROW LEVEL SECURITY;
ALTER TABLE sys_user FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation ON sys_user
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
