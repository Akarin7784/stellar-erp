-- =====================================================================
-- G2-18 受注行累计完工上限：存储过程草稿（DRAFT，不执行）
-- ---------------------------------------------------------------------
-- 本文件位于 db/draft/，不在 Flyway locations（classpath:db/migration）内，
-- 永远不会被 Flyway 执行。不建任何业务表，表结构迁移归 DB 组。
--
-- 依赖的决定：
--   D1 docs/design/30-review/R3-对抗性评审-第2轮-异常路径.md G2-18（2026-10-20 已批准）
--      - 报完工在同一事务内 FOR UPDATE 受注行，校验并更新受注行冗余 completed_qty；
--      - allowed_qty = 受注数量 × (1 + over_receipt_rate)，rate 为受注行确认时快照；
--      - 容许率优先级：受注行指定 > 物料设定 > 物料分类 > 公司参数 sys_param（见 D5，不硬编码）；
--      - 工单 over_receipt_rate 只校验单张工单，不参与受注行累计上限；
--      - CHECK (completed_qty >= 0 AND completed_qty <= allowed_qty)；
--      - 超产审批通过后同一事务调高 allowed_qty 并写审计；
--      - 冲销（完工退回/报废冲销）走同一加锁路径扣减；
--      - 受注改量：新 allowed_qty < completed_qty 时拒绝；不用乐观锁（version 只 +1 不校验，G2-06）。
--   D2 加锁顺序（群内 蓝色大肥鱼 2026-10-20 最终裁定）：
--      先锁受注行，再锁工单；同类多行按 id 升序。完工/冲销/返工入库/受注变更/超产审批统一。
--   D3 错误码（#56 群内定稿 2026-10-21，HTTP 422 域内码；业务拒绝不用 4002）：
--      60056 / MSG-PRD-056  工单物料 ≠ 受注行物料；
--      60100 / MSG-PRD-100  MTO 未批超产（超过 allowed_qty 且超产审批未通过）；
--      60040 / MSG-PRD-040  硬超 allowed_qty（MTS，或审批额度用尽后仍超；含单张工单上限）；
--      60102 / MSG-PRD-102  报工冲销数量 > 已完工量；
--      30022 / MSG-SAL-056  受注改量低于已完工/已发货；
--      60101 / MSG-PRD-101  超产审批已驳回/取消后仍超；
--      60103 / MSG-PRD-103  超产审批调高值不合法；
--      5000 缺租户 / 缺 prd.completion_over_rate / 缺 UOM 精度；4002 仅真状态冲突（HTTP 409）。
--   D5 蓝色大肥鱼 2026-10-20 追加裁定：
--      - 上限按基本单位计算：allowed_qty / completed_qty 以基本单位存储，基数取 base_qty；
--      - 完工容许率优先级：受注行 > 物料 > 物料分类 > 公司；容许率一律存 rate NUMERIC(5,4)，不做 /100 换算；
--      - 公司默认取 01-system 公司参数表（表名未定），不硬编码 0.05；
--      - 超产审批单独建表（审批单号、申请数量、批准 allowed_qty、审批人、审批时间），走 Flowable 审批；
--      - 软删除统一 deleted BOOLEAN；
--      - 舍入：allowed_qty 按物料基本单位精度（mdm_uom.decimal_places）向下取整，
--        受注行确认时快照，受注改量、超产审批通过时按同一规则重算。
--   D6 错误码分工：4002 只用于真正的状态冲突（单据状态不允许、并发改绑），HTTP 409；
--      业务规则拒绝用领域码（HTTP 422），入参值域错误用 1003（HTTP 400）。
--   D4 RLS：依赖 #43（app.tenant_id，set_config(...,true)，erp_app NOBYPASSRLS）。
--      全部 SECURITY INVOKER，不自行写 tenant_id（由列默认值 current_setting 取得），
--      没有租户上下文或租户为 0 时直接报错。
--
-- 等待的表：
--   T2 sal_sales_order_line 增加 completed_qty / allowed_qty / over_receipt_rate + CHECK
--   T3 prd_work_order 增加 sales_order_line_id BIGINT（MTO 必填）
--   未定稿列均以 -- TODO(待T2/T3定稿) 标出。
-- =====================================================================

-- ---------------------------------------------------------------------
-- 0. 租户上下文守卫：无上下文 / 租户 0 直接报错
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION g2_18_assert_tenant() RETURNS bigint
LANGUAGE plpgsql SECURITY INVOKER
SET search_path = public, pg_temp AS $$
DECLARE
    v_tenant text := current_setting('app.tenant_id', true);
    v_id     bigint;
BEGIN
    -- 缺租户 / 非数值 / 0 → 5000（设定不备），不用 42501
    IF v_tenant IS NULL OR v_tenant = '' THEN
        PERFORM g2_18_raise(5000, 'tenant context missing (app.tenant_id)');
    END IF;
    BEGIN
        v_id := v_tenant::bigint;
    EXCEPTION WHEN invalid_text_representation OR numeric_value_out_of_range THEN
        PERFORM g2_18_raise(5000, 'tenant context invalid (app.tenant_id)');
    END;
    IF v_id = 0 THEN
        PERFORM g2_18_raise(5000, 'tenant context is 0 (app.tenant_id)');
    END IF;
    RETURN v_id;
END $$;

-- 业务错误统一出口：MESSAGE 为错误码，应用层翻译为 HTTP + MSG-xxx，不抛 500
CREATE OR REPLACE FUNCTION g2_18_raise(p_code int, p_detail text) RETURNS void
LANGUAGE plpgsql SECURITY INVOKER
SET search_path = public, pg_temp AS $$
BEGIN
    RAISE EXCEPTION '%', p_code USING ERRCODE = 'P0001', DETAIL = p_detail;
END $$;

-- 公司上下文：取 current_setting('app.company_id', true)，缺失/空 → 5000（设定不备）
-- 注意：RLS 只按 tenant_id；company_id 仅作业务过滤条件
CREATE OR REPLACE FUNCTION g2_18_assert_company() RETURNS bigint
LANGUAGE plpgsql SECURITY INVOKER
SET search_path = public, pg_temp AS $$
DECLARE
    v_company text := current_setting('app.company_id', true);
BEGIN
    IF v_company IS NULL OR v_company = '' THEN
        PERFORM g2_18_raise(5000, 'company context missing (app.company_id)');
    END IF;
    BEGIN
        RETURN v_company::bigint;
    EXCEPTION WHEN invalid_text_representation OR numeric_value_out_of_range THEN
        PERFORM g2_18_raise(5000, 'company context invalid (app.company_id)');
    END;
END $$;

-- ---------------------------------------------------------------------
-- 1. 容许率解析（受注行确认时调用一次，结果快照到受注行）
--    受注行指定 > 物料设定 > 物料分类 > 公司参数 sys_param（缺失 → 5000）
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION g2_18_resolve_over_receipt_rate(
    p_line_rate   numeric,   -- 受注行上明确指定的值（rate NUMERIC(5,4)，0.0500 = 5%），NULL 表示未指定
    p_material_id bigint
) RETURNS numeric
LANGUAGE plpgsql STABLE SECURITY INVOKER
SET search_path = public, pg_temp AS $$
DECLARE
    v_rate numeric;
BEGIN
    PERFORM g2_18_assert_tenant();
    -- (1) 受注行
    IF p_line_rate IS NOT NULL THEN
        RETURN p_line_rate;
    END IF;
    -- (2) 物料  (3) 物料分类：均为 rate，不做 /100 换算
    -- TODO(待T2/T3定稿) 物料/分类上「完工超入库容许率」列名未定（现有 over_receipt_tolerance_rate 为采购超收容许率，
    --                   是否复用、改名或新增 NUMERIC(5,4) 列由 MDM 定），下面的列名 completion_over_rate 为占位
    SELECT COALESCE(m.completion_over_rate, c.completion_over_rate)
      INTO v_rate
      FROM mdm_material m
      LEFT JOIN mdm_material_category c ON c.id = m.category_id AND c.deleted = FALSE
     WHERE m.id = p_material_id AND m.deleted = FALSE;
    IF v_rate IS NOT NULL THEN
        RETURN v_rate;
    END IF;
    -- (4) 公司默认：01-system 公司参数表
    -- 公司默认取 01-system sys_param（value_type 3 小数），不硬编码 0.05；取不到时报错而不是默认
    -- 由 DB 组在 sys_param 迁移中预置 0.05；缺失属配置/系统错误，报 5000
    SELECT p.param_value::numeric INTO v_rate
      FROM sys_param p
     WHERE p.param_key = 'prd.completion_over_rate'   -- TODO(待T2/T3定稿) sys_param 参数键名未定，此为占位
       AND p.company_id = g2_18_assert_company()   -- 当前公司上下文，不取物料的 company_id
       AND p.status = 1
       AND p.deleted = FALSE;
    IF v_rate IS NULL THEN
        PERFORM g2_18_raise(5000, 'company default completion over-receipt rate not configured');
    END IF;
    RETURN v_rate;
END $$;

-- ---------------------------------------------------------------------
-- 1b. allowed_qty 计算（已定）：按物料基本单位精度向下取整
--     例：PCE（decimal_places = 0）7 × 1.05 = 7.35 → 7
--     精度来源 mdm_uom.decimal_places（02-mdm/90-db-design.md:925），经 mdm_material.base_uom_code 关联
--     受注行确认、受注改量、超产审批三处统一调用
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION g2_18_calc_allowed_qty(
    p_qty         numeric,   -- 基本单位数量（base_qty 或审批批准值）
    p_rate        numeric,   -- 容许率 rate；超产审批传 0
    p_material_id bigint
) RETURNS numeric
LANGUAGE plpgsql STABLE SECURITY INVOKER
SET search_path = public, pg_temp AS $$
DECLARE
    v_scale smallint;
BEGIN
    SELECT u.decimal_places INTO v_scale
      FROM mdm_material m
      JOIN mdm_uom u ON u.uom_code = m.base_uom_code
                    AND u.company_id = m.company_id
                    AND u.deleted = FALSE
     WHERE m.id = p_material_id AND m.deleted = FALSE;
    IF v_scale IS NULL THEN
        PERFORM g2_18_raise(5000, 'base uom precision not found for material ' || p_material_id);
    END IF;
    -- 数量均 ≥ 0，trunc 即向下取整
    RETURN trunc(p_qty * (1 + p_rate), v_scale);
END $$;

-- ---------------------------------------------------------------------
-- 1c. 受注行确认时快照 over_receipt_rate 与 allowed_qty。锁序：受注行 → 工单(id 升序)
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION g2_18_snapshot_on_line_confirm(
    p_sales_order_line_id bigint,
    p_line_rate           numeric,   -- 受注行上明确指定的容许率，NULL 表示未指定
    p_operator_id         bigint
) RETURNS numeric
LANGUAGE plpgsql SECURITY INVOKER
SET search_path = public, pg_temp AS $$
DECLARE
    v_base_qty numeric;
    v_material bigint;
    v_rate     numeric;
    v_allowed  numeric;
    v_company  bigint;
BEGIN
    PERFORM g2_18_assert_tenant();
    v_company := g2_18_assert_company();
    PERFORM g2_18_lock_line_and_work_orders(p_sales_order_line_id);
    SELECT l.base_qty, l.material_id INTO v_base_qty, v_material
      FROM sal_sales_order_line l
      JOIN sal_sales_order h ON h.id = l.sales_order_id
     WHERE l.id = p_sales_order_line_id AND h.company_id = v_company;
    IF NOT FOUND THEN
        PERFORM g2_18_raise(4001, 'sales_order_line not found in company: ' || p_sales_order_line_id);
    END IF;
    v_rate    := g2_18_resolve_over_receipt_rate(p_line_rate, v_material);
    v_allowed := g2_18_calc_allowed_qty(v_base_qty, v_rate, v_material);
    UPDATE sal_sales_order_line
       SET over_receipt_rate = v_rate,      -- TODO(待T2/T3定稿) T2 新增列
           allowed_qty       = v_allowed,   -- TODO(待T2/T3定稿) T2 新增列
           version = version + 1, updated_at = now(), updated_by = p_operator_id
     WHERE id = p_sales_order_line_id;
    RETURN v_allowed;
END $$;

-- ---------------------------------------------------------------------
-- 内部：按 D2 顺序加锁。先受注行，再该行全部工单（id 升序）
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION g2_18_lock_line_and_work_orders(p_sales_order_line_id bigint)
RETURNS void
LANGUAGE plpgsql SECURITY INVOKER
SET search_path = public, pg_temp AS $$
BEGIN
    PERFORM 1 FROM sal_sales_order_line l
     WHERE l.id = p_sales_order_line_id
       FOR UPDATE;
    IF NOT FOUND THEN
        PERFORM g2_18_raise(4001, 'sales_order_line not found: ' || p_sales_order_line_id);
    END IF;

    PERFORM 1 FROM prd_work_order w
     WHERE w.sales_order_line_id = p_sales_order_line_id   -- TODO(待T2/T3定稿) T3 新增列
     ORDER BY w.id
       FOR UPDATE;
END $$;

-- ---------------------------------------------------------------------
-- 2. 报完工：qty > 0
--    锁序：受注行 → 工单（单张）
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION g2_18_report_completion(
    p_work_order_id bigint,
    p_qty           numeric,
    p_operator_id   bigint
) RETURNS void
LANGUAGE plpgsql SECURITY INVOKER
SET search_path = public, pg_temp AS $$
DECLARE
    v_line_id       bigint;
    v_line_id_chk   bigint;
    v_line_done     numeric;
    v_line_allowed  numeric;
    v_line_status   smallint;
    v_line_material bigint;
    v_wo            record;
    v_company       bigint;
    v_wo_allowed    numeric;
    v_appr_ok       boolean;
    v_appr_pending  boolean;
BEGIN
    PERFORM g2_18_assert_tenant();
    v_company := g2_18_assert_company();
    IF p_qty IS NULL OR p_qty <= 0 THEN
        PERFORM g2_18_raise(1003, 'qty must be > 0');   -- 入参值域错误，HTTP 400
    END IF;

    -- 先无锁读出受注行 ID，用于确定加锁对象（不能先锁工单）；按当前公司过滤
    SELECT w.sales_order_line_id INTO v_line_id          -- TODO(待T2/T3定稿) T3 新增列
      FROM prd_work_order w WHERE w.id = p_work_order_id AND w.company_id = v_company;
    IF NOT FOUND THEN
        PERFORM g2_18_raise(4001, 'work_order not found: ' || p_work_order_id);
    END IF;

    -- (1) 锁受注行（MTS 工单无受注行，跳过）；公司取受注头
    IF v_line_id IS NOT NULL THEN
        SELECT l.completed_qty, l.allowed_qty, l.line_status, l.material_id   -- TODO(待T2/T3定稿) completed_qty/allowed_qty 为 T2 新增列
          INTO v_line_done, v_line_allowed, v_line_status, v_line_material
          FROM sal_sales_order_line l
          JOIN sal_sales_order h ON h.id = l.sales_order_id
         WHERE l.id = v_line_id
           AND h.company_id = v_company
           FOR UPDATE OF l;
        IF NOT FOUND THEN
            PERFORM g2_18_raise(4001, 'sales_order_line not found in company: ' || v_line_id);
        END IF;
        IF v_line_status = 90 THEN      -- 90 取消
            PERFORM g2_18_raise(4002, 'sales_order_line cancelled');
        END IF;
    END IF;

    -- (2) 锁工单
    SELECT w.id, w.material_id, w.order_status, w.is_hold, w.order_qty, w.completed_qty,
           w.allowed_qty, w.over_receipt_rate, w.sales_order_line_id AS line_id   -- TODO(待T2/T3定稿)
      INTO v_wo
      FROM prd_work_order w
     WHERE w.id = p_work_order_id
       AND w.company_id = v_company
       FOR UPDATE;
    IF NOT FOUND THEN
        PERFORM g2_18_raise(4001, 'work_order not found: ' || p_work_order_id);
    END IF;

    -- 加锁前读到的受注行可能已被改绑：不一致则视为状态冲突，由调用方重试
    v_line_id_chk := v_wo.line_id;
    IF v_line_id_chk IS DISTINCT FROM v_line_id THEN
        PERFORM g2_18_raise(4002, 'work_order.sales_order_line_id changed concurrently');
    END IF;

    -- 工单物料必须与受注行物料一致：业务规则拒绝（HTTP 422），非并发冲突
    IF v_line_id IS NOT NULL AND v_wo.material_id IS DISTINCT FROM v_line_material THEN
        PERFORM g2_18_raise(60056, format('work_order material %s <> sales_order_line material %s',
            v_wo.material_id, v_line_material));   -- MSG-PRD-056 / HTTP 422
    END IF;

    -- 状态：30 下达済 / 35 製造中 才能报完工
    IF v_wo.order_status NOT IN (30, 35) THEN
        PERFORM g2_18_raise(4002, 'work_order status ' || v_wo.order_status);
    END IF;
    IF v_wo.is_hold THEN
        PERFORM g2_18_raise(60047, 'work_order on hold');
    END IF;

    -- (3) 受注行累计上限（先于工单上限，AC-PRD-07：60100 优先于 60040）
    --     allowed_qty 已在受注行确认/改量/超产审批时按基本单位精度向下取整快照，此处直接比较
    IF v_line_id IS NOT NULL AND v_line_done + p_qty > v_line_allowed THEN
        -- #58 prd_overproduction_approval（90-db-design §3.19.1），对象=本受注行（整行或本工单）：
        --   30 承認済 → allowed_qty 已调高仍超 = 额度用尽 → 60040 / MSG-PRD-040
        --   无记录 或 10/20 草稿・承認待ち → 60100 / MSG-PRD-100
        --   仅有 40 却下 / 90 取消 → 60101 / MSG-PRD-101（95-acceptance-criteria:50、90:1097）
        SELECT bool_or(a.approval_status = 30),
               bool_or(a.approval_status IN (10, 20))
          INTO v_appr_ok, v_appr_pending
          FROM prd_overproduction_approval a
         WHERE a.company_id = v_company
           AND a.sales_order_line_id = v_line_id
           AND (a.work_order_id IS NULL OR a.work_order_id = p_work_order_id);
        IF v_appr_ok THEN
            PERFORM g2_18_raise(60040, format(
                'sales_order_line %s: %s + %s > allowed %s (approved quota used)',
                v_line_id, v_line_done, p_qty, v_line_allowed));   -- MSG-PRD-040 / HTTP 422
        ELSIF v_appr_pending IS NULL OR v_appr_pending THEN
            PERFORM g2_18_raise(60100, format(
                'sales_order_line %s: over-production approval required (%s + %s > allowed %s)',
                v_line_id, v_line_done, p_qty, v_line_allowed));   -- MSG-PRD-100 / HTTP 422
        ELSE
            PERFORM g2_18_raise(60101, format(
                'sales_order_line %s: over-production approval rejected/cancelled (%s + %s > allowed %s)',
                v_line_id, v_line_done, p_qty, v_line_allowed));   -- MSG-PRD-101 / HTTP 422
        END IF;
    END IF;

    -- (4) 单张工单上限：工单 allowed_qty（MTO 为受注行快照/超产审批后值）；
    --     未快照（MTS）时按同一规则算：floor(order_qty × (1+rate))，rate NULL 走容许率链，不跳过
    v_wo_allowed := v_wo.allowed_qty;
    IF v_wo_allowed IS NULL THEN
        v_wo_allowed := g2_18_calc_allowed_qty(
            v_wo.order_qty,
            g2_18_resolve_over_receipt_rate(v_wo.over_receipt_rate, v_wo.material_id),
            v_wo.material_id);
    END IF;
    IF v_wo.completed_qty + p_qty > v_wo_allowed THEN
        PERFORM g2_18_raise(60040, format('work_order %s: %s + %s > allowed %s',
            v_wo.id, v_wo.completed_qty, p_qty, v_wo_allowed));   -- MSG-PRD-040 / HTTP 422（MTS 或审批后仍超）
    END IF;

    IF v_line_id IS NOT NULL THEN
        UPDATE sal_sales_order_line
           SET completed_qty = completed_qty + p_qty,           -- TODO(待T2/T3定稿)
               version       = version + 1,                     -- 只 +1，不校验旧值（G2-06）
               updated_at    = now(),
               updated_by    = p_operator_id
         WHERE id = v_line_id;
    END IF;

    UPDATE prd_work_order
       SET completed_qty = completed_qty + p_qty,
           version       = version + 1,
           updated_at    = now(),
           updated_by    = p_operator_id
     WHERE id = p_work_order_id;
END $$;

-- ---------------------------------------------------------------------
-- 3. 冲销：完工退回 / 报废冲销，扣减 completed_qty。锁序同上
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION g2_18_reverse_completion(
    p_work_order_id bigint,
    p_qty           numeric,     -- 正数，表示要扣减的数量
    p_operator_id   bigint
) RETURNS void
LANGUAGE plpgsql SECURITY INVOKER
SET search_path = public, pg_temp AS $$
DECLARE
    v_line_id      bigint;
    v_line_done    numeric;
    v_wo           record;
    v_company      bigint;
BEGIN
    PERFORM g2_18_assert_tenant();
    v_company := g2_18_assert_company();
    IF p_qty IS NULL OR p_qty <= 0 THEN
        PERFORM g2_18_raise(1003, 'reverse qty must be > 0');   -- 入参值域错误，HTTP 400
    END IF;

    SELECT w.sales_order_line_id INTO v_line_id          -- TODO(待T2/T3定稿)
      FROM prd_work_order w WHERE w.id = p_work_order_id AND w.company_id = v_company;
    IF NOT FOUND THEN
        PERFORM g2_18_raise(4001, 'work_order not found: ' || p_work_order_id);
    END IF;

    IF v_line_id IS NOT NULL THEN
        SELECT l.completed_qty INTO v_line_done          -- TODO(待T2/T3定稿)
          FROM sal_sales_order_line l
          JOIN sal_sales_order h ON h.id = l.sales_order_id
         WHERE l.id = v_line_id
           AND h.company_id = v_company
           FOR UPDATE OF l;
        IF NOT FOUND THEN
            PERFORM g2_18_raise(4001, 'sales_order_line not found in company: ' || v_line_id);
        END IF;
    END IF;

    SELECT w.completed_qty, w.sales_order_line_id AS line_id   -- TODO(待T2/T3定稿)
      INTO v_wo
      FROM prd_work_order w WHERE w.id = p_work_order_id AND w.company_id = v_company FOR UPDATE;
    IF v_wo.line_id IS DISTINCT FROM v_line_id THEN
        PERFORM g2_18_raise(4002, 'work_order.sales_order_line_id changed concurrently');
    END IF;

    IF v_wo.completed_qty - p_qty < 0 THEN
        -- 业务规则拒绝（HTTP 422），非并发冲突；#56 定稿 60102 / MSG-PRD-102
        PERFORM g2_18_raise(60102, format('work_order completed_qty %s < reverse %s', v_wo.completed_qty, p_qty));
    END IF;
    IF v_line_id IS NOT NULL AND v_line_done - p_qty < 0 THEN
        PERFORM g2_18_raise(60102, format('sales_order_line completed_qty %s < reverse %s', v_line_done, p_qty));   -- MSG-PRD-102 / HTTP 422
    END IF;

    IF v_line_id IS NOT NULL THEN
        UPDATE sal_sales_order_line
           SET completed_qty = completed_qty - p_qty,           -- TODO(待T2/T3定稿)
               version = version + 1, updated_at = now(), updated_by = p_operator_id
         WHERE id = v_line_id;
    END IF;
    UPDATE prd_work_order
       SET completed_qty = completed_qty - p_qty,
           version = version + 1, updated_at = now(), updated_by = p_operator_id
     WHERE id = p_work_order_id;
END $$;

-- ---------------------------------------------------------------------
-- 4. 超产审批通过：调高 allowed_qty 并写审计。锁序：受注行 → 全部工单(id 升序)
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION g2_18_raise_allowed_qty(
    p_sales_order_line_id bigint,
    p_work_order_id       bigint,    -- 审批对象工单；NULL = 受注行全体（prd_overproduction_approval.work_order_id）
    p_delta_qty           numeric,   -- 已批超产增量 = prd_overproduction_approval.request_qty（基本单位）
    p_approval_no         varchar,   -- 超产审批单号
    p_approver_id         bigint,
    p_audit_id            bigint     -- sys_audit_log.id：雪花 ID 由应用生成（04-common-db-spec §5）
) RETURNS void
LANGUAGE plpgsql SECURITY INVOKER
SET search_path = public, pg_temp AS $$
DECLARE
    v_old     numeric;
    v_company bigint;
    v_material bigint;
    v_new     numeric;
    v_delta   numeric;
    v_rows    bigint;
BEGIN
    PERFORM g2_18_assert_tenant();
    v_company := g2_18_assert_company();
    PERFORM g2_18_lock_line_and_work_orders(p_sales_order_line_id);

    SELECT l.allowed_qty, l.material_id     -- TODO(待T2/T3定稿) allowed_qty
      INTO v_old, v_material
      FROM sal_sales_order_line l
      JOIN sal_sales_order h ON h.id = l.sales_order_id
     WHERE l.id = p_sales_order_line_id
       AND h.company_id = v_company;
    IF NOT FOUND THEN
        PERFORM g2_18_raise(4001, 'sales_order_line not found in company: ' || p_sales_order_line_id);
    END IF;

    -- 受注行未快照 allowed_qty：数据/设定不备 → 5000
    IF v_old IS NULL THEN
        PERFORM g2_18_raise(5000, 'sales_order_line allowed_qty not snapshotted: ' || p_sales_order_line_id);
    END IF;
    -- 超产增量不合法（NULL 或 ≤ 0）：60103 / MSG-PRD-103（HTTP 422，蓝色大肥鱼 2026-10-21 定稿）
    IF p_delta_qty IS NULL OR p_delta_qty <= 0 THEN
        PERFORM g2_18_raise(60103, format('over-production delta %s must be > 0', p_delta_qty));   -- MSG-PRD-103 / HTTP 422
    END IF;
    -- 增量按基本单位精度向下取整（rate 传 0）；取整后为 0 同样不合法
    v_delta := g2_18_calc_allowed_qty(p_delta_qty, 0, v_material);
    IF v_delta <= 0 THEN
        PERFORM g2_18_raise(60103, format('over-production delta %s truncates to %s', p_delta_qty, v_delta));   -- MSG-PRD-103 / HTTP 422
    END IF;
    v_new := v_old + v_delta;

    -- 工单级审批：先校验工单属于该受注行且属当前公司，否则业务拒绝 60056（整事务回滚，受注行不改）
    IF p_work_order_id IS NOT NULL THEN
        PERFORM 1 FROM prd_work_order w
         WHERE w.id = p_work_order_id
           AND w.sales_order_line_id = p_sales_order_line_id
           AND w.company_id = v_company;
        IF NOT FOUND THEN
            PERFORM g2_18_raise(60056, format('work_order %s does not belong to sales_order_line %s',
                p_work_order_id, p_sales_order_line_id));   -- MSG-PRD-056 / HTTP 422
        END IF;
    END IF;

    -- 受注行：工单级、行级审批都 += delta
    UPDATE sal_sales_order_line
       SET allowed_qty = v_new,                   -- TODO(待T2/T3定稿)
           version = version + 1, updated_at = now(), updated_by = p_approver_id
     WHERE id = p_sales_order_line_id;

    -- 工单：仅工单级审批（work_order_id NOT NULL）时该工单 += delta；行级审批（NULL）工单不变
    -- 行锁已由 g2_18_lock_line_and_work_orders 按 id 升序取得
    IF p_work_order_id IS NOT NULL THEN
        UPDATE prd_work_order w
           SET allowed_qty = w.allowed_qty + v_delta,
               version = version + 1, updated_at = now(), updated_by = p_approver_id
         WHERE w.id = p_work_order_id
           AND w.sales_order_line_id = p_sales_order_line_id
           AND w.company_id = v_company;
        GET DIAGNOSTICS v_rows = ROW_COUNT;
        IF v_rows = 0 THEN
            PERFORM g2_18_raise(5000, 'work_order not updated: ' || p_work_order_id);
        END IF;
    END IF;

    -- 审计：审批单号、原值、新值、审批人、时间
    -- TODO(待T2/T3定稿) sys_audit_log 的 module_code/resource_code 取值待定
    -- tenant_id 不显式写入，由列默认值 current_setting('app.tenant_id') 取得（#43）
    INSERT INTO sys_audit_log (
        id, company_id, user_id, operation_type, module_code, resource_code,
        resource_id, resource_no, before_data, after_data, result, occurred_at,
        created_by
    ) VALUES (
        p_audit_id, v_company, p_approver_id, 'APPROVE', 'SAL', 'sales-order-line',
        p_sales_order_line_id::text, p_approval_no,
        jsonb_build_object('allowed_qty', v_old),
        jsonb_build_object('allowed_qty', v_new, 'delta_qty', v_delta, 'work_order_id', p_work_order_id, 'approval_no', p_approval_no),
        1, now(), p_approver_id
    );
END $$;

-- ---------------------------------------------------------------------
-- 4b. 超产审批通过（Flowable 回调，同一事务）：20 → 30，并调用 g2_18_raise_allowed_qty
--     锁序：受注行 → 工单(id 升序) → 审批单（审批单不属于跨表锁序规定对象，最后锁）
--     驳回(40)/取消(90) 不改 allowed_qty，由应用层直接更新状态
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION g2_18_approve_overproduction(
    p_approval_id bigint,
    p_approver_id bigint,
    p_audit_id    bigint
) RETURNS numeric
LANGUAGE plpgsql SECURITY INVOKER
SET search_path = public, pg_temp AS $$
DECLARE
    v_company bigint;
    v_line_id bigint;
    v_a       record;
    v_new     numeric;
BEGIN
    PERFORM g2_18_assert_tenant();
    v_company := g2_18_assert_company();

    -- 先无锁读出受注行 ID（不能先锁审批单/工单）
    SELECT a.sales_order_line_id INTO v_line_id
      FROM prd_overproduction_approval a
     WHERE a.id = p_approval_id AND a.company_id = v_company;
    IF NOT FOUND THEN
        PERFORM g2_18_raise(4001, 'overproduction approval not found: ' || p_approval_id);
    END IF;

    PERFORM g2_18_lock_line_and_work_orders(v_line_id);

    SELECT a.approval_no, a.sales_order_line_id, a.work_order_id, a.material_id,
           a.request_qty, a.approval_status
      INTO v_a
      FROM prd_overproduction_approval a
     WHERE a.id = p_approval_id
       FOR UPDATE;
    IF v_a.sales_order_line_id IS DISTINCT FROM v_line_id THEN
        PERFORM g2_18_raise(4002, 'approval sales_order_line_id changed concurrently');
    END IF;
    IF v_a.approval_status <> 20 THEN       -- 只有承認待ち可通过：真状态冲突 → 4002 / HTTP 409
        PERFORM g2_18_raise(4002, 'approval status ' || v_a.approval_status);
    END IF;

    -- request_qty 口径（蓝色大肥鱼 2026-10-21 定稿）：申请的超产增量（基本单位），不是审批后合计。
    -- approved_allowed_qty：审批通过后受注行的新 allowed_qty（只读快照）
    PERFORM g2_18_raise_allowed_qty(v_line_id, v_a.work_order_id, v_a.request_qty,
                                    v_a.approval_no, p_approver_id, p_audit_id);

    SELECT l.allowed_qty INTO v_new FROM sal_sales_order_line l WHERE l.id = v_line_id;  -- TODO(待T2/T3定稿)

    UPDATE prd_overproduction_approval
       SET approval_status      = 30,
           approved_allowed_qty = v_new,
           approved_by          = p_approver_id,
           approved_at          = now(),
           version = version + 1, updated_at = now(), updated_by = p_approver_id
     WHERE id = p_approval_id;
    RETURN v_new;
END $$;

-- ---------------------------------------------------------------------
-- 5. 受注改量校验：新的 allowed_qty < completed_qty 时拒绝。锁序同 4
--    只做加锁+校验并返回新 allowed_qty；同一事务内由调用方更新受注行数量。
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION g2_18_check_line_qty_change(
    p_sales_order_line_id bigint,
    p_new_base_qty        numeric    -- 改后基本单位数量（base_qty）
) RETURNS numeric
LANGUAGE plpgsql SECURITY INVOKER
SET search_path = public, pg_temp AS $$
DECLARE
    v_done     numeric;
    v_shipped  numeric;
    v_rate     numeric;
    v_new_allowed numeric;
    v_material bigint;
    v_company  bigint;
    v_approved_delta numeric;
BEGIN
    PERFORM g2_18_assert_tenant();
    v_company := g2_18_assert_company();
    PERFORM g2_18_lock_line_and_work_orders(p_sales_order_line_id);

    SELECT l.completed_qty, l.shipped_base_qty, l.over_receipt_rate, l.material_id   -- TODO(待T2/T3定稿) completed_qty/over_receipt_rate
      INTO v_done, v_shipped, v_rate, v_material
      FROM sal_sales_order_line l
      JOIN sal_sales_order h ON h.id = l.sales_order_id
     WHERE l.id = p_sales_order_line_id AND h.company_id = v_company;
    IF NOT FOUND THEN
        PERFORM g2_18_raise(4001, 'sales_order_line not found in company: ' || p_sales_order_line_id);
    END IF;

    -- 已定：按基本单位，基数为 base_qty
    -- 同一规则重算：基本单位精度向下取整；调用方在同一事务把返回值写回 allowed_qty
    -- 按快照 rate 重算，再加回该受注行全部已批（30）超产增量（行级 + 工单级都已计入受注行）
    -- 工单 allowed_qty 不在此重算，工单级已批增量保持不变
    v_new_allowed := g2_18_calc_allowed_qty(p_new_base_qty, v_rate, v_material);
    SELECT COALESCE(SUM(g2_18_calc_allowed_qty(a.request_qty, 0, v_material)), 0) INTO v_approved_delta
      FROM prd_overproduction_approval a
     WHERE a.company_id = v_company
       AND a.sales_order_line_id = p_sales_order_line_id
       AND a.approval_status = 30;
    v_new_allowed := v_new_allowed + v_approved_delta;

    IF v_new_allowed < v_done THEN
        -- 业务规则拒绝 → HTTP 422，不是并发冲突（不用 4002/409）
        -- 30022 / MSG-SAL-056：受注改量导致新 allowed_qty < completed_qty（覆盖已完工）
        PERFORM g2_18_raise(30022, format('new allowed_qty %s < completed_qty %s; 先完工退回或走受注变更审批', v_new_allowed, v_done));
    END IF;
    -- 与 base_qty 比较统一用基本单位已发货数 shipped_base_qty  -- TODO(待T2/T3定稿) T2 新增列
    IF p_new_base_qty < v_shipped THEN
        PERFORM g2_18_raise(30022, format('new base_qty %s < shipped_base_qty %s', p_new_base_qty, v_shipped));   -- MSG-SAL-056 / HTTP 422
    END IF;
    RETURN v_new_allowed;
END $$;

-- ---------------------------------------------------------------------
-- 6. 对账视图：受注行 completed_qty vs 其工单 completed_qty 合计
--    security_invoker 需 PostgreSQL 15+，使 RLS 按调用者生效
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW v_g2_18_line_completion_recon
WITH (security_invoker = true) AS
SELECT l.id                                   AS sales_order_line_id,
       l.sales_order_id,
       l.line_no,
       l.completed_qty                        AS line_completed_qty,   -- TODO(待T2/T3定稿)
       l.allowed_qty,                                                  -- TODO(待T2/T3定稿)
       COALESCE(SUM(w.completed_qty), 0)      AS wo_completed_qty_sum,
       l.completed_qty - COALESCE(SUM(w.completed_qty), 0) AS diff_qty,
       COUNT(w.id)                            AS work_order_count
  FROM sal_sales_order_line l
  LEFT JOIN prd_work_order w
         ON w.sales_order_line_id = l.id                               -- TODO(待T2/T3定稿)
        AND w.order_status <> 90                                       -- 取消工单不计
 GROUP BY l.id, l.sales_order_id, l.line_no, l.completed_qty, l.allowed_qty;
