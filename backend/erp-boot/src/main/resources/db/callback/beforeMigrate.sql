-- Flyway 回调：每次 migrate 前执行（不计入版本、无 checksum），保护所有迁移（含已合并的 V202610210204）。
-- 业务表为 owner 所有且 FORCE ROW LEVEL SECURITY，owner 本身也受 RLS 约束；
-- 迁移里的数据校验/回填（如 0204 的容差值范围检查）若被 RLS 过滤会形同虚设，故要求执行账号为 superuser 或 BYPASSRLS。
-- 见 docs/design/00-common/10-rls-and-db-roles.md。
DO $$
DECLARE
    v_super  boolean;
    v_bypass boolean;
BEGIN
    SELECT rolsuper, rolbypassrls INTO v_super, v_bypass
      FROM pg_roles WHERE rolname = current_user;
    IF NOT (v_super OR v_bypass) THEN
        RAISE EXCEPTION 'Flyway 执行账号 % 既不是 superuser 也没有 BYPASSRLS：FORCE RLS 下迁移中的数据校验会被租户策略过滤。请用带 BYPASSRLS 的 owner 账号执行（ALTER ROLE % BYPASSRLS）', current_user, current_user;
    END IF;
END
$$;
