-- Flyway 回调：每次 migrate 后执行（不计入版本、无 checksum）。
-- 占位符 erp_app_password 非空时为 erp_app 启用 LOGIN 并设置密码；为空则保持 NOLOGIN。
-- 注意：密码不得包含单引号。
DO $$
BEGIN
    IF '${erp_app_password}' <> '' THEN
        EXECUTE format('ALTER ROLE erp_app LOGIN PASSWORD %L', '${erp_app_password}');
    END IF;
END
$$;
