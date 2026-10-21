-- sys_param 种子：prd.overproduction_max_rate（超产申请单次上限率，默认 1.0000）
-- 依据：01-system/90 業務パラメータ表（#48，蓝色大肥鱼 2026-10-21 决定）；sys_param 为公司级，
--       唯一键 uk_sys_param_key (tenant_id, company_id, param_key) WHERE deleted = FALSE（sys/V202610210103:166）。
-- 合并顺序：须在 #50（mdm/V202610211402）之后合并。
-- 不改已发布迁移（V202610210103 的 checksum 保持不变），本文件以 CREATE OR REPLACE 重新定义 sys_init_tenant。
--
-- RLS：sys_param 为 FORCE RLS。Flyway 以 owner 执行，beforeMigrate 回调已要求执行账号为 superuser 或 BYPASSRLS；
--       本文件回填跨租户写入，再自检一次，避免在受 RLS 约束的账号下静默只补到部分租户（或因 app.tenant_id 未设置报错）。
-- ID：仓库内无 DB 端雪花发号器。sys_init_tenant 沿用 (tenant_id * 1000 + n) 规则（n=1 已被 completion_over_rate 占用，
--       本参数用 n=2）；公司行使用由 (tenant_id, company_id, param_key) 派生的确定性正 BIGINT（重复执行得到同一 ID）。

DO $$
DECLARE
    v_super  boolean;
    v_bypass boolean;
BEGIN
    SELECT rolsuper, rolbypassrls INTO v_super, v_bypass FROM pg_roles WHERE rolname = current_user;
    IF NOT (v_super OR v_bypass) THEN
        RAISE EXCEPTION 'V202610211403: 执行账号 % 需为 superuser 或 BYPASSRLS（sys_param 为 FORCE RLS，回填跨租户）', current_user;
    END IF;
END
$$;

-- 确定性 ID：hashtextextended 的 63 位正数部分；仅供本迁移与 sys_init_tenant 的种子行使用
CREATE OR REPLACE FUNCTION public.sys_param_seed_id(p_tenant_id BIGINT, p_company_id BIGINT, p_param_key TEXT)
RETURNS BIGINT
LANGUAGE sql
IMMUTABLE
SET search_path = pg_catalog
AS $$
    SELECT (hashtextextended(p_tenant_id::text || ':' || p_company_id::text || ':' || p_param_key, 0)
            & 9223372036854775807)::bigint
$$;

COMMENT ON FUNCTION public.sys_param_seed_id(BIGINT, BIGINT, TEXT) IS
    'sys_param 种子行的确定性 ID（tenant_id, company_id, param_key 派生的正 BIGINT）';
REVOKE ALL ON FUNCTION public.sys_param_seed_id(BIGINT, BIGINT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.sys_param_seed_id(BIGINT, BIGINT, TEXT) TO erp_tenant_provisioner;

-- ---------------------------------------------------------------------------
-- sys_init_tenant：保留 V202610210103 的全部逻辑（参数校验、set_config、company_id = 0 的 completion_over_rate 行），
-- 追加：
--   (1) company_id = 0 的 prd.overproduction_max_rate 行（ID tenant_id*1000+2）；
--   (2) 调用时该租户已存在的每个未逻辑删除公司（sys_company.id）各一行 completion_over_rate / overproduction_max_rate。
-- 后端只按当前公司读取、不回退 company_id = 0（ProductionRepository.findCompanyOverRate），因此 (2) 是实际生效的行。
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.sys_init_tenant(p_tenant_id BIGINT)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
    IF p_tenant_id IS NULL THEN
        RAISE EXCEPTION 'sys_init_tenant: tenant_id is required';
    END IF;
    PERFORM set_config('app.tenant_id', p_tenant_id::text, true);

    INSERT INTO sys_param (
        id, tenant_id, company_id,
        param_key, param_name, param_group, param_value, default_value,
        value_type, value_range, is_encrypted, is_danger, is_readonly,
        effective_scope, sort_no, description, status,
        version, deleted, created_at, created_by, updated_at, updated_by
    ) VALUES (
        (p_tenant_id * 1000 + 1), p_tenant_id, 0,
        'prd.completion_over_rate', '完工超收容差（公司默认）', 'prd',
        '0.05', '0.05',
        3, '0.0000-1.0000', FALSE, FALSE, FALSE,
        1, 10,
        '完工超收容差的公司默认（比率，0.05=5%）。受注行>物料>分类>本参数。',
        1,
        0, FALSE, now(), 0, now(), 0
    ), (
        (p_tenant_id * 1000 + 2), p_tenant_id, 0,
        'prd.overproduction_max_rate', '超产申请上限率（公司默认）', 'prd',
        '1.0000', '1.0000',
        3, '0.0000-9.9999', FALSE, FALSE, FALSE,
        1, 20,
        '超产申请单次上限率（比率，NUMERIC(5,4)，1.0000=受注行基本数量的 100%）。单次 request_qty ≤ 受注行基本数量 × 本参数；不设累计上限。',
        1,
        0, FALSE, now(), 0, now(), 0
    )
    ON CONFLICT (tenant_id, company_id, param_key) WHERE deleted = FALSE
    DO NOTHING;

    INSERT INTO sys_param (
        id, tenant_id, company_id,
        param_key, param_name, param_group, param_value, default_value,
        value_type, value_range, is_encrypted, is_danger, is_readonly,
        effective_scope, sort_no, description, status,
        version, deleted, created_at, created_by, updated_at, updated_by
    )
    SELECT sys_param_seed_id(p_tenant_id, c.id, d.param_key), p_tenant_id, c.id,
           d.param_key, d.param_name, 'prd', d.v, d.v,
           3, d.value_range, FALSE, FALSE, FALSE,
           1, d.sort_no, d.description, 1,
           0, FALSE, now(), 0, now(), 0
      FROM sys_company c
     CROSS JOIN (VALUES
        ('prd.completion_over_rate', '完工超收容差（公司默认）', '0.05', '0.0000-1.0000', 10,
         '完工超收容差的公司默认（比率，0.05=5%）。受注行>物料>分类>本参数。'),
        ('prd.overproduction_max_rate', '超产申请上限率（公司默认）', '1.0000', '0.0000-9.9999', 20,
         '超产申请单次上限率（比率，NUMERIC(5,4)，1.0000=受注行基本数量的 100%）。单次 request_qty ≤ 受注行基本数量 × 本参数；不设累计上限。')
     ) AS d(param_key, param_name, v, value_range, sort_no, description)
     WHERE c.tenant_id = p_tenant_id
       AND c.deleted = FALSE
    ON CONFLICT (tenant_id, company_id, param_key) WHERE deleted = FALSE
    DO NOTHING;
END;
$$;

COMMENT ON FUNCTION public.sys_init_tenant(BIGINT) IS
    '租户创建时投入默认 sys_param（prd.completion_over_rate=0.05、prd.overproduction_max_rate=1.0000；company_id=0 及已存在的各公司）；SECURITY DEFINER';

REVOKE ALL ON FUNCTION public.sys_init_tenant(BIGINT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.sys_init_tenant(BIGINT) TO erp_tenant_provisioner;

-- ---------------------------------------------------------------------------
-- 回填：现有每个未逻辑删除的公司补 overproduction_max_rate = 1.0000；缺 completion_over_rate 的补原种子默认 0.05。
-- 幂等：ON CONFLICT … DO NOTHING，已有（含自定义值）的行不覆盖。执行账号 superuser/BYPASSRLS，跨租户一次写入，tenant_id 显式取自 sys_company。
-- 种租户 0 的 company_id = 0 行（原 V202610210103 显式投入的 completion_over_rate）同样补上 overproduction_max_rate。
-- ---------------------------------------------------------------------------
INSERT INTO sys_param (
    id, tenant_id, company_id,
    param_key, param_name, param_group, param_value, default_value,
    value_type, value_range, is_encrypted, is_danger, is_readonly,
    effective_scope, sort_no, description, status,
    version, deleted, created_at, created_by, updated_at, updated_by
) VALUES (
    2, 0, 0,
    'prd.overproduction_max_rate', '超产申请上限率（公司默认）', 'prd',
    '1.0000', '1.0000',
    3, '0.0000-9.9999', FALSE, FALSE, FALSE,
    1, 20,
    '超产申请单次上限率（比率，NUMERIC(5,4)，1.0000=受注行基本数量的 100%）。单次 request_qty ≤ 受注行基本数量 × 本参数；不设累计上限。',
    1,
    0, FALSE, now(), 0, now(), 0
) ON CONFLICT (tenant_id, company_id, param_key) WHERE deleted = FALSE
DO NOTHING;

INSERT INTO sys_param (
    id, tenant_id, company_id,
    param_key, param_name, param_group, param_value, default_value,
    value_type, value_range, is_encrypted, is_danger, is_readonly,
    effective_scope, sort_no, description, status,
    version, deleted, created_at, created_by, updated_at, updated_by
)
SELECT sys_param_seed_id(c.tenant_id, c.id, d.param_key), c.tenant_id, c.id,
       d.param_key, d.param_name, 'prd', d.v, d.v,
       3, d.value_range, FALSE, FALSE, FALSE,
       1, d.sort_no, d.description, 1,
       0, FALSE, now(), 0, now(), 0
  FROM sys_company c
 CROSS JOIN (VALUES
    ('prd.completion_over_rate', '完工超收容差（公司默认）', '0.05', '0.0000-1.0000', 10,
     '完工超收容差的公司默认（比率，0.05=5%）。受注行>物料>分类>本参数。'),
    ('prd.overproduction_max_rate', '超产申请上限率（公司默认）', '1.0000', '0.0000-9.9999', 20,
     '超产申请单次上限率（比率，NUMERIC(5,4)，1.0000=受注行基本数量的 100%）。单次 request_qty ≤ 受注行基本数量 × 本参数；不设累计上限。')
 ) AS d(param_key, param_name, v, value_range, sort_no, description)
 WHERE c.deleted = FALSE
ON CONFLICT (tenant_id, company_id, param_key) WHERE deleted = FALSE
DO NOTHING;
