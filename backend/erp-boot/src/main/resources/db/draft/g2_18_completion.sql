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
--      - 容许率优先级：受注行指定 > 物料设定 > 公司默认 0.05；
--      - 工单 over_receipt_rate 只校验单张工单，不参与受注行累计上限；
--      - CHECK (completed_qty >= 0 AND completed_qty <= allowed_qty)；
--      - 超产审批通过后同一事务调高 allowed_qty 并写审计；
--      - 冲销（完工退回/报废冲销）走同一加锁路径扣减；
--      - 受注改量：新 allowed_qty < completed_qty 时拒绝；不用乐观锁（version 只 +1 不校验，G2-06）。
--   D2 加锁顺序（群内 蓝色大肥鱼 2026-10-20 最终裁定）：
--      先锁受注行，再锁工单；同类多行按 id 升序。完工/冲销/返工入库/受注变更/超产审批统一。
--   D3 错误码：00-common/03-common-api-spec.md 6 章 4002 状态不整合（MSG-COM-034）、1003 値域外、5000 系统错误（公司默认容许率缺失）；
--      PRD 60056 为占位（工单物料与受注行物料不一致），HTTP 422；
--      SAL 30022 为占位（受注改量低于已完工/已发货、超产调高值不合法），HTTP 422；
--      06-production/91-api-design.md 60040 超過入庫（MSG-PRD-040）。
--   D5 蓝色大肥鱼 2026-10-20 追加裁定：
--      - 上限按基本单位计算：allowed_qty / completed_qty 以基本单位存储，基数取 base_qty；
--      - 完工容许率优先级：受注行 > 物料 > 物料分类 > 公司；容许率一律存 rate NUMERIC(5,4)，不做 /100 换算；
--      - 公司默认取 01-system 公司参数表（表名未定），不硬编码 0.05；
--      - 超产审批单独建表（审批单号、申请数量、批准 allowed_qty、审批人、审批时间），走 Flowable 审批；
--      - 软删除统一 deleted BOOLEAN。
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
LANGUAGE plpgsql SECURITY INVOKER AS $$
DECLARE
    v_tenant text := current_setting('app.tenant_id', true);
BEGIN
    IF v_tenant IS NULL OR v_tenant = '' OR v_tenant::bigint = 0 THEN
        RAISE EXCEPTION 'tenant context missing (app.tenant_id)'
            USING ERRCODE = '42501';
    END IF;
    RETURN v_tenant::bigint;
END $$;

-- 业务错误统一出口：MESSAGE 为错误码，应用层翻译为 HTTP + MSG-xxx，不抛 500
CREATE OR REPLACE FUNCTION g2_18_raise(p_code int, p_detail text) RETURNS void
LANGUAGE plpgsql SECURITY INVOKER AS $$
BEGIN
    RAISE EXCEPTION '%', p_code USING ERRCODE = 'P0001', DETAIL = p_detail;
END $$;

-- ---------------------------------------------------------------------
-- 1. 容许率解析（受注行确认时调用一次，结果快照到受注行）
--    受注行指定 > 物料设定 > 公司默认 0.05
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION g2_18_resolve_over_receipt_rate(
    p_line_rate   numeric,   -- 受注行上明确指定的值（rate NUMERIC(5,4)，0.0500 = 5%），NULL 表示未指定
    p_material_id bigint
) RETURNS numeric
LANGUAGE plpgsql STABLE SECURITY INVOKER AS $$
DECLARE
    v_rate numeric;
BEGIN
    PERFORM g2_18_assert_tenant();
    -- (1) 受注行
    IF p_line_rate IS NOT NULL THEN
        RETURN p_line_rate;
    END IF;
    -- (2) 物料  (3) 物料分类：均为 rate，不做 /100 换算
    -- TODO(待T2/T3定稿) 物料/分类上「完工超入库容许率」列名未定（现有 over_receipt_tolerance_pct 为采购超收 %，
    --                   是否复用、改名或新增 NUMERIC(5,4) 列由 MDM 定），下面的列名 completion_over_rate 为占位
    SELECT COALESCE(m.completion_over_rate, c.completion_over_rate)
      INTO v_rate
      FROM mdm_material m
      JOIN mdm_material_category c ON c.id = m.category_id AND c.deleted = FALSE
     WHERE m.id = p_material_id AND m.deleted = FALSE;
    IF v_rate IS NOT NULL THEN
        RETURN v_rate;
    END IF;
    -- (4) 公司默认：01-system 公司参数表
    -- TODO(待T2/T3定稿) 公司参数表名/参数键未定（01-system），不硬编码 0.05；取不到时报错而不是默认
    -- 由 DB 组在 sys_param 迁移中预置 0.05；缺失属配置/系统错误，报 5000
    -- SELECT ... INTO v_rate FROM <sys_company_param?> WHERE company_id = ? AND param_key = ?;
    IF v_rate IS NULL THEN
        PERFORM g2_18_raise(5000, 'company default completion over-receipt rate not configured');
    END IF;
    RETURN v_rate;
END $$;

-- ---------------------------------------------------------------------
-- 内部：按 D2 顺序加锁。先受注行，再该行全部工单（id 升序）
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION g2_18_lock_line_and_work_orders(p_sales_order_line_id bigint)
RETURNS void
LANGUAGE plpgsql SECURITY INVOKER AS $$
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
LANGUAGE plpgsql SECURITY INVOKER AS $$
DECLARE
    v_line_id       bigint;
    v_line_id_chk   bigint;
    v_line_done     numeric;
    v_line_allowed  numeric;
    v_line_status   smallint;
    v_line_material bigint;
    v_wo            record;
BEGIN
    PERFORM g2_18_assert_tenant();
    IF p_qty IS NULL OR p_qty <= 0 THEN
        PERFORM g2_18_raise(1003, 'qty must be > 0');   -- 入参值域错误，HTTP 400
    END IF;

    -- 先无锁读出受注行 ID，用于确定加锁对象（不能先锁工单）
    SELECT w.sales_order_line_id INTO v_line_id          -- TODO(待T2/T3定稿) T3 新增列
      FROM prd_work_order w WHERE w.id = p_work_order_id;
    IF NOT FOUND THEN
        PERFORM g2_18_raise(4001, 'work_order not found: ' || p_work_order_id);
    END IF;

    -- (1) 锁受注行（MTS 工单无受注行，跳过）
    IF v_line_id IS NOT NULL THEN
        SELECT l.completed_qty, l.allowed_qty, l.line_status, l.material_id   -- TODO(待T2/T3定稿) completed_qty/allowed_qty 为 T2 新增列
          INTO v_line_done, v_line_allowed, v_line_status, v_line_material
          FROM sal_sales_order_line l
         WHERE l.id = v_line_id
           FOR UPDATE;
        IF v_line_status = 90 THEN      -- 90 取消
            PERFORM g2_18_raise(4002, 'sales_order_line cancelled');
        END IF;
    END IF;

    -- (2) 锁工单
    SELECT w.id, w.material_id, w.order_status, w.is_hold, w.order_qty, w.completed_qty,
           w.over_receipt_rate, w.sales_order_line_id AS line_id   -- TODO(待T2/T3定稿)
      INTO v_wo
      FROM prd_work_order w
     WHERE w.id = p_work_order_id
       FOR UPDATE;

    -- 加锁前读到的受注行可能已被改绑：不一致则视为状态冲突，由调用方重试
    v_line_id_chk := v_wo.line_id;
    IF v_line_id_chk IS DISTINCT FROM v_line_id THEN
        PERFORM g2_18_raise(4002, 'work_order.sales_order_line_id changed concurrently');
    END IF;

    -- 工单物料必须与受注行物料一致：业务规则拒绝（HTTP 422），非并发冲突
    IF v_line_id IS NOT NULL AND v_wo.material_id IS DISTINCT FROM v_line_material THEN
        PERFORM g2_18_raise(60056, format('work_order material %s <> sales_order_line material %s',
            v_wo.material_id, v_line_material));   -- TODO(待PRD定编号/MSG编号) 60056 为占位（MSG-PRD-056 未使用）
    END IF;

    -- 状态：30 下达済 / 35 製造中 才能报完工
    IF v_wo.order_status NOT IN (30, 35) THEN
        PERFORM g2_18_raise(4002, 'work_order status ' || v_wo.order_status);
    END IF;
    IF v_wo.is_hold THEN
        PERFORM g2_18_raise(60047, 'work_order on hold');
    END IF;

    -- 单张工单上限：工单自己的 over_receipt_rate，只作用于本工单
    IF v_wo.completed_qty + p_qty > v_wo.order_qty * (1 + v_wo.over_receipt_rate) THEN
        PERFORM g2_18_raise(60040, format('work_order %s: %s + %s > %s',
            v_wo.id, v_wo.completed_qty, p_qty, v_wo.order_qty * (1 + v_wo.over_receipt_rate)));
    END IF;

    -- 受注行累计上限：0 ≤ completed_qty + qty ≤ allowed_qty
    -- 工单与完工报告均为基本单位，无需换算
    -- TODO(待T2/T3定稿) 舍入规则未定，参照 测试与评审 提案：按基本单位精度向下取整，并在受注行确认时快照
    IF v_line_id IS NOT NULL THEN
        IF v_line_done + p_qty < 0 OR v_line_done + p_qty > v_line_allowed THEN
            PERFORM g2_18_raise(60040, format('sales_order_line %s: %s + %s > allowed %s',
                v_line_id, v_line_done, p_qty, v_line_allowed));
        END IF;
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
LANGUAGE plpgsql SECURITY INVOKER AS $$
DECLARE
    v_line_id      bigint;
    v_line_done    numeric;
    v_wo           record;
BEGIN
    PERFORM g2_18_assert_tenant();
    IF p_qty IS NULL OR p_qty <= 0 THEN
        PERFORM g2_18_raise(1003, 'reverse qty must be > 0');   -- 入参值域错误，HTTP 400
    END IF;

    SELECT w.sales_order_line_id INTO v_line_id          -- TODO(待T2/T3定稿)
      FROM prd_work_order w WHERE w.id = p_work_order_id;
    IF NOT FOUND THEN
        PERFORM g2_18_raise(4001, 'work_order not found: ' || p_work_order_id);
    END IF;

    IF v_line_id IS NOT NULL THEN
        SELECT l.completed_qty INTO v_line_done          -- TODO(待T2/T3定稿)
          FROM sal_sales_order_line l WHERE l.id = v_line_id FOR UPDATE;
    END IF;

    SELECT w.completed_qty, w.sales_order_line_id AS line_id   -- TODO(待T2/T3定稿)
      INTO v_wo
      FROM prd_work_order w WHERE w.id = p_work_order_id FOR UPDATE;
    IF v_wo.line_id IS DISTINCT FROM v_line_id THEN
        PERFORM g2_18_raise(4002, 'work_order.sales_order_line_id changed concurrently');
    END IF;

    IF v_wo.completed_qty - p_qty < 0 THEN
        -- 业务规则拒绝（HTTP 422），非并发冲突
        PERFORM g2_18_raise(60032, format('work_order completed_qty %s < reverse %s', v_wo.completed_qty, p_qty));
    END IF;
    IF v_line_id IS NOT NULL AND v_line_done - p_qty < 0 THEN
        PERFORM g2_18_raise(60032, format('sales_order_line completed_qty %s < reverse %s', v_line_done, p_qty));
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
    p_new_allowed_qty     numeric,
    p_approval_no         varchar,   -- 超产审批单号
    p_approver_id         bigint,
    p_audit_id            bigint     -- sys_audit_log.id：雪花 ID 由应用生成（04-common-db-spec §5）
) RETURNS void
LANGUAGE plpgsql SECURITY INVOKER AS $$
DECLARE
    v_old     numeric;
    v_company bigint;
BEGIN
    PERFORM g2_18_assert_tenant();
    PERFORM g2_18_lock_line_and_work_orders(p_sales_order_line_id);

    SELECT l.allowed_qty, h.company_id                    -- TODO(待T2/T3定稿) allowed_qty
      INTO v_old, v_company
      FROM sal_sales_order_line l
      JOIN sal_sales_order h ON h.id = l.sales_order_id
     WHERE l.id = p_sales_order_line_id;

    IF p_new_allowed_qty IS NULL OR p_new_allowed_qty <= v_old THEN
        -- 业务规则拒绝（HTTP 422），非并发冲突
        PERFORM g2_18_raise(30022, format('new allowed_qty %s must be > current %s', p_new_allowed_qty, v_old));   -- TODO(待SAL定编号/MSG编号)
    END IF;

    UPDATE sal_sales_order_line
       SET allowed_qty = p_new_allowed_qty,                -- TODO(待T2/T3定稿)
           version = version + 1, updated_at = now(), updated_by = p_approver_id
     WHERE id = p_sales_order_line_id;

    -- TODO(待T2/T3定稿) 超产审批单独建表（审批单号、申请数量、批准 allowed_qty、审批人、审批时间），
    --                   经 Flowable 审批通过后由回调在同一事务调用本函数；表名/列名未定，届时在此 INSERT 审批记录
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
        jsonb_build_object('allowed_qty', p_new_allowed_qty, 'approval_no', p_approval_no),
        1, now(), p_approver_id
    );
END $$;

-- ---------------------------------------------------------------------
-- 5. 受注改量校验：新的 allowed_qty < completed_qty 时拒绝。锁序同 4
--    只做加锁+校验并返回新 allowed_qty；同一事务内由调用方更新受注行数量。
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION g2_18_check_line_qty_change(
    p_sales_order_line_id bigint,
    p_new_base_qty        numeric    -- 改后基本单位数量（base_qty）
) RETURNS numeric
LANGUAGE plpgsql SECURITY INVOKER AS $$
DECLARE
    v_done     numeric;
    v_shipped  numeric;
    v_rate     numeric;
    v_new_allowed numeric;
BEGIN
    PERFORM g2_18_assert_tenant();
    PERFORM g2_18_lock_line_and_work_orders(p_sales_order_line_id);

    SELECT l.completed_qty, l.shipped_base_qty, l.over_receipt_rate   -- TODO(待T2/T3定稿) completed_qty/over_receipt_rate
      INTO v_done, v_shipped, v_rate
      FROM sal_sales_order_line l WHERE l.id = p_sales_order_line_id;

    -- 已定：按基本单位，基数为 base_qty
    -- TODO(待T2/T3定稿) 舍入规则未定，参照 测试与评审 提案：按基本单位精度向下取整，受注行确认时快照
    v_new_allowed := p_new_base_qty * (1 + v_rate);

    IF v_new_allowed < v_done THEN
        -- 业务规则拒绝 → HTTP 422，不是并发冲突（不用 4002/409）
        -- 30022 为 SAL 领域占位码（03-sales 已用 30001-30021/30050/30090）
        PERFORM g2_18_raise(30022, format('new allowed_qty %s < completed_qty %s; 先完工退回或走受注变更审批', v_new_allowed, v_done));   -- TODO(待SAL定编号/MSG编号)
    END IF;
    -- 与 base_qty 比较统一用基本单位已发货数 shipped_base_qty  -- TODO(待T2/T3定稿) T2 新增列
    IF p_new_base_qty < v_shipped THEN
        PERFORM g2_18_raise(30022, format('new base_qty %s < shipped_base_qty %s', p_new_base_qty, v_shipped));   -- TODO(待SAL定编号/MSG编号) HTTP 422
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
