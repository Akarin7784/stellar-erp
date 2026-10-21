-- 05 库存域全量建表（docs/design/05-inventory/90-db-design.md v1.9 §4，main 19dbdf6 / PR #47），24 表。
-- 表 DDL 由设计书 §4 原样转写（列、CHECK、索引、COMMENT 不增删）；按 §3.4 每表追加 ENABLE + FORCE RLS 与 tenant_isolation 策略。
-- 规则：tenant_id DEFAULT current_setting('app.tenant_id')::bigint；company_id NOT NULL 无 DEFAULT；
--       uk_/idx_ 以 (tenant_id, company_id, …) 打头；erp_app 的 DML 权限由 sys/V202610200101 的 ALTER DEFAULT PRIVILEGES 自动授予（不写 GRANT）。
-- FK（§6.3）：同域父子 6 条 (tenant_id, company_id, x_id) → 父 uk_<表>_tenant_company_id（写在 CREATE TABLE 内，设计书原文）；
--       指向 mdm 的跨域 FK (tenant_id, x_id) → mdm_x (tenant_id, id)，在文件末尾统一 ALTER TABLE 追加（§6.3 #7〜11）；
--       inv_stock_txn 为月次分区表，不被任何 FK 引用（04 §8.1），表头↔明细由触发器 trg_inv_stock_txn_line_head 校验。
-- 分区（§4.2.2 / §9）：inv_stock_txn_y2026m01〜y2027m12 + inv_stock_txn_default。分区子表同样 ENABLE + FORCE RLS + 策略
--       （RlsCoverageTest 覆盖 relkind='r' 的子表），并 REVOKE erp_app 的直接访问（§3.4）。月分区统一由 inv_create_stock_txn_partition(date) 建（幂等，同步 RLS/策略/REVOKE），月次作业也调用它。
-- 依赖：mdm/V202610210201〜0203、sys/V202610210707（uk_mdm_*_tenant_id）、sys/V202610211401、sys/V202610211403。

-- inv_stock_balance（90-db-design.md:209）
CREATE TABLE inv_stock_balance (
    id              BIGINT        NOT NULL,
    tenant_id       BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id      BIGINT        NOT NULL,
    warehouse_id    BIGINT        NOT NULL,
    location_id     BIGINT        NOT NULL DEFAULT 0,      -- 0 = 库位未管理
    material_id     BIGINT        NOT NULL,
    batch_id        BIGINT        NOT NULL DEFAULT 0,      -- 0 = 非批次管理
    batch_no        VARCHAR(64)   NOT NULL DEFAULT '',     -- ロック順序・照会用の冗長列
    stock_status    SMALLINT      NOT NULL,
    qty_on_hand     NUMERIC(18,4) NOT NULL DEFAULT 0,
    qty_reserved    NUMERIC(18,4) NOT NULL DEFAULT 0,
    amount_on_hand  NUMERIC(18,2) NOT NULL DEFAULT 0,
    avg_unit_cost   NUMERIC(18,6) NOT NULL DEFAULT 0,
    last_txn_date   DATE,
    last_txn_id     BIGINT,
    version         INT           NOT NULL DEFAULT 0,
    remark          VARCHAR(500),
    ext_data        JSONB,
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by      BIGINT        NOT NULL DEFAULT 0,
    updated_at      TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by      BIGINT        NOT NULL DEFAULT 0,
    CONSTRAINT pk_inv_stock_balance PRIMARY KEY (id),
    CONSTRAINT ck_inv_stock_balance_status CHECK (stock_status IN (10,20,30,40,50)),
    CONSTRAINT ck_inv_stock_balance_qty CHECK (qty_on_hand >= 0 AND qty_reserved >= 0 AND qty_reserved <= qty_on_hand),
    CONSTRAINT ck_inv_stock_balance_amount CHECK (amount_on_hand >= 0),
    CONSTRAINT ck_inv_stock_balance_avg CHECK (avg_unit_cost >= 0)
);
ALTER TABLE inv_stock_balance ENABLE ROW LEVEL SECURITY;
ALTER TABLE inv_stock_balance FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON inv_stock_balance
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);

CREATE UNIQUE INDEX uk_inv_stock_balance_key
    ON inv_stock_balance (tenant_id, company_id, warehouse_id, material_id, batch_id, stock_status, location_id);
CREATE INDEX idx_inv_stock_balance_material_wh
    ON inv_stock_balance (tenant_id, company_id, material_id, warehouse_id, stock_status);
CREATE INDEX idx_inv_stock_balance_wh_material
    ON inv_stock_balance (tenant_id, company_id, warehouse_id, material_id);
CREATE INDEX idx_inv_stock_balance_batch
    ON inv_stock_balance (tenant_id, company_id, batch_id) WHERE batch_id <> 0;
CREATE INDEX idx_inv_stock_balance_status
    ON inv_stock_balance (tenant_id, company_id, stock_status) WHERE qty_on_hand > 0;

COMMENT ON TABLE inv_stock_balance IS '库存余额（倉庫×物料×批次×状態×庫位）';
COMMENT ON COLUMN inv_stock_balance.qty_reserved IS '引当済数量（可用量 = status=20 の qty_on_hand - qty_reserved）';
COMMENT ON COLUMN inv_stock_balance.stock_status IS '在庫状態：10待検 / 20可用 / 30冻结 / 40不合格 / 50報廃待処理';
COMMENT ON COLUMN inv_stock_balance.avg_unit_cost IS '同一(倉庫,物料,批次)の全状態行で共有する移動平均単価（6桁）';

-- inv_stock_txn（90-db-design.md:319）
CREATE TABLE inv_stock_txn (
    id                BIGINT        NOT NULL,
    tenant_id         BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id      BIGINT        NOT NULL,
    txn_no            VARCHAR(32)   NOT NULL,          -- GRI/SDO/MII/MIR/FGI/OSI/OSR/TR/CNT/AOI/AOO/ST
    txn_type          VARCHAR(16)   NOT NULL,
    txn_date          DATE          NOT NULL,
    factory_id        BIGINT        NOT NULL,
    warehouse_id      BIGINT        NOT NULL,
    source_type       VARCHAR(32)   NOT NULL,
    source_id         BIGINT,
    source_no         VARCHAR(32),
    partner_type      SMALLINT      NOT NULL DEFAULT 0, -- 0:なし 1:仕入先 2:顧客 3:部門/工場 4:その他
    partner_id        BIGINT,
    partner_name      VARCHAR(200),
    biz_module        VARCHAR(16),                      -- PUR/SAL/PRD/INV
    reference_txn_no  VARCHAR(32),                      -- 対になる事務（TR_OUT⇔TR_IN 等）
    pair_key          VARCHAR(64),                      -- ST_IN/ST_OUT 等の対をグループ化（UUID）
    is_reversal       BOOLEAN       NOT NULL DEFAULT FALSE,
    reversal_of_txn_id BIGINT,                          -- 沖销元の事務 ID
    reversed_txn_id   BIGINT,                           -- この事務を沖销した事務 ID（元に保持）
    reverse_reason    VARCHAR(500),
    reversed_at       TIMESTAMPTZ,
    reversed_by       BIGINT,
    txn_status        SMALLINT      NOT NULL DEFAULT 10, -- 10草稿/20承認待ち/25承認済/30已過账/90已沖销
    posted_at         TIMESTAMPTZ,
    posted_by         BIGINT,
    currency_code     VARCHAR(3)    NOT NULL DEFAULT 'CNY',
    accounting_period VARCHAR(7)    NOT NULL,
    source_event_at   TIMESTAMPTZ,                      -- 遅延イベントの原本業務日時（BR-16）
    reason_type       SMALLINT,                         -- AOI/AOO/SC_OUT の原因区分（02 §2.6.6/2.6.7、API reasonType）
    work_order_id     BIGINT,                           -- MII/MIR/FGI/OSI/OSR：工单 ID → prd_work_order.id（软引用、分批法の原価対象）
    sales_order_line_id BIGINT,                         -- MTO：工单の受注明細スナップショット → sal_sales_order_line.id（软引用）
    total_qty         NUMERIC(18,4) NOT NULL DEFAULT 0,
    total_amount      NUMERIC(18,2) NOT NULL DEFAULT 0,
    version           INT           NOT NULL DEFAULT 0,
    remark            VARCHAR(500),
    ext_data          JSONB,
    created_at        TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by        BIGINT        NOT NULL DEFAULT 0,
    updated_at        TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by        BIGINT        NOT NULL DEFAULT 0,
    CONSTRAINT pk_inv_stock_txn PRIMARY KEY (id, txn_date),   -- パーティションキーを含む（04 §8.1）
    CONSTRAINT ck_inv_stock_txn_source CHECK (source_type IN
        ('PURCHASE_RECEIPT','OUTSOURCING_ORDER','PRODUCTION_COMPLETION','INSPECTION','SALES_DELIVERY',
         'WORK_ORDER','TRANSFER','STOCKTAKE','SALES_RETURN','PURCHASE_RETURN','MANUAL')),
    CONSTRAINT ck_inv_stock_txn_partner CHECK (partner_type IN (0,1,2,3,4)),
    CONSTRAINT ck_inv_stock_txn_reason CHECK (
        -- CK-05（90-db-design.md:441「AOI/AOO/SC_OUT のみ必須」）：三者必填；SC_OUT 为 10〜50（02 §2.6.7），AOI/AOO 为 10〜60（02 §2.6.6/2.6.7）
        (txn_type IN ('AOI','AOO') AND reason_type IS NOT NULL AND reason_type IN (10,20,30,40,50,60)) OR
        (txn_type = 'SC_OUT' AND reason_type IS NOT NULL AND reason_type IN (10,20,30,40,50)) OR
        (txn_type NOT IN ('AOI','AOO','SC_OUT') AND reason_type IS NULL)),
    CONSTRAINT ck_inv_stock_txn_amount CHECK (total_qty >= 0 AND total_amount >= 0),
    CONSTRAINT ck_inv_stock_txn_type CHECK (txn_type IN
        ('PI','SI','MII','MIR','FGI','OSI','OSR','TR_OUT','TR_IN','ADJ_IN','ADJ_OUT',
         'SC_IN','SC_OUT','AOI','AOO','RT_IN','PR_OUT','ST_IN','ST_OUT')),
    CONSTRAINT ck_inv_stock_txn_status CHECK (txn_status IN (10,20,25,30,90)),
    CONSTRAINT ck_inv_stock_txn_date CHECK (txn_date >= DATE '2020-01-01'),
    CONSTRAINT ck_inv_stock_txn_period CHECK (accounting_period ~ '^[0-9]{4}-[0-9]{2}$'),
    CONSTRAINT ck_inv_stock_txn_reversal CHECK (is_reversal = FALSE OR reversal_of_txn_id IS NOT NULL)
) PARTITION BY RANGE (txn_date);
ALTER TABLE inv_stock_txn ENABLE ROW LEVEL SECURITY;
ALTER TABLE inv_stock_txn FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON inv_stock_txn
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
-- 月分区建表函数（蓝色大肥鱼 2026-10-21 决定，#55）。幂等：已存在则只补 RLS/策略/REVOKE。
-- SECURITY DEFINER + 固定 search_path（同 sys/V202610211403 写法）；REVOKE PUBLIC，不授予 erp_app（只有 owner/迁移账号可执行）。
-- 注：若 DEFAULT 分区里已有该月数据，CREATE ... PARTITION OF 会失败（需先搬迁），应在月份到来前预建（§4.2.2 3 か月先）。
CREATE FUNCTION public.inv_create_stock_txn_partition(p_month DATE)
RETURNS regclass
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
    v_from DATE := date_trunc('month', p_month)::date;
    v_to   DATE := (date_trunc('month', p_month) + INTERVAL '1 month')::date;
    v_name TEXT := format('inv_stock_txn_y%sm%s', to_char(p_month, 'YYYY'), to_char(p_month, 'MM'));
    v_rel  regclass;
BEGIN
    IF p_month IS NULL THEN
        RAISE EXCEPTION 'p_month 不能为空' USING ERRCODE = '22004';
    END IF;
    v_rel := to_regclass('public.' || v_name);
    IF v_rel IS NULL THEN
        EXECUTE format('CREATE TABLE public.%I PARTITION OF public.inv_stock_txn FOR VALUES FROM (%L) TO (%L)', v_name, v_from, v_to);
        v_rel := to_regclass('public.' || v_name);
    END IF;
    EXECUTE format('ALTER TABLE %s ENABLE ROW LEVEL SECURITY', v_rel);
    EXECUTE format('ALTER TABLE %s FORCE ROW LEVEL SECURITY', v_rel);
    IF NOT EXISTS (SELECT 1 FROM pg_policy WHERE polrelid = v_rel AND polname = 'tenant_isolation') THEN
        EXECUTE format('CREATE POLICY tenant_isolation ON %s USING (tenant_id = current_setting(''app.tenant_id'')::bigint) WITH CHECK (tenant_id = current_setting(''app.tenant_id'')::bigint)', v_rel);
    END IF;
    EXECUTE format('REVOKE ALL ON %s FROM erp_app', v_rel);
    RETURN v_rel;
END $$;
REVOKE ALL ON FUNCTION public.inv_create_stock_txn_partition(DATE) FROM PUBLIC;
COMMENT ON FUNCTION public.inv_create_stock_txn_partition(DATE) IS
    '建 inv_stock_txn 月分区 inv_stock_txn_yYYYYmMM（幂等），同步 ENABLE+FORCE RLS、tenant_isolation 策略、REVOKE erp_app；SECURITY DEFINER，不授予 erp_app';
SELECT public.inv_create_stock_txn_partition(DATE '2026-01-01');
SELECT public.inv_create_stock_txn_partition(DATE '2026-02-01');
SELECT public.inv_create_stock_txn_partition(DATE '2026-03-01');
SELECT public.inv_create_stock_txn_partition(DATE '2026-04-01');
SELECT public.inv_create_stock_txn_partition(DATE '2026-05-01');
SELECT public.inv_create_stock_txn_partition(DATE '2026-06-01');
SELECT public.inv_create_stock_txn_partition(DATE '2026-07-01');
SELECT public.inv_create_stock_txn_partition(DATE '2026-08-01');
SELECT public.inv_create_stock_txn_partition(DATE '2026-09-01');
SELECT public.inv_create_stock_txn_partition(DATE '2026-10-01');
SELECT public.inv_create_stock_txn_partition(DATE '2026-11-01');
SELECT public.inv_create_stock_txn_partition(DATE '2026-12-01');
SELECT public.inv_create_stock_txn_partition(DATE '2027-01-01');
SELECT public.inv_create_stock_txn_partition(DATE '2027-02-01');
SELECT public.inv_create_stock_txn_partition(DATE '2027-03-01');
SELECT public.inv_create_stock_txn_partition(DATE '2027-04-01');
SELECT public.inv_create_stock_txn_partition(DATE '2027-05-01');
SELECT public.inv_create_stock_txn_partition(DATE '2027-06-01');
SELECT public.inv_create_stock_txn_partition(DATE '2027-07-01');
SELECT public.inv_create_stock_txn_partition(DATE '2027-08-01');
SELECT public.inv_create_stock_txn_partition(DATE '2027-09-01');
SELECT public.inv_create_stock_txn_partition(DATE '2027-10-01');
SELECT public.inv_create_stock_txn_partition(DATE '2027-11-01');
SELECT public.inv_create_stock_txn_partition(DATE '2027-12-01');
CREATE TABLE inv_stock_txn_default PARTITION OF inv_stock_txn DEFAULT;
ALTER TABLE inv_stock_txn_default ENABLE ROW LEVEL SECURITY;
ALTER TABLE inv_stock_txn_default FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON inv_stock_txn_default
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
REVOKE ALL ON inv_stock_txn_default FROM erp_app;
-- 月次パーティション：inv_stock_txn_yYYYYmMM（例 inv_stock_txn_y2026m10）。初回迁移で 2026-01〜2027-12 と DEFAULT パーティションを作成し、
-- 以降は月次ジョブ（sys_scheduled_job）が 3 か月先まで事前作成する（第 10 章 #7）。

-- パーティション表の一意索引はパーティションキーを含む必要があるため、全社一意は 4.2.6 の inv_stock_txn_key で保証する（第 10 章 #7 決定済）。
CREATE UNIQUE INDEX uk_inv_stock_txn_no ON inv_stock_txn (tenant_id, company_id, txn_no, txn_date);
CREATE INDEX idx_inv_stock_txn_date_type ON inv_stock_txn (tenant_id, company_id, txn_date DESC, txn_type);
CREATE INDEX idx_inv_stock_txn_source ON inv_stock_txn (tenant_id, company_id, source_type, source_no);
CREATE INDEX idx_inv_stock_txn_status ON inv_stock_txn (tenant_id, company_id, txn_status) WHERE txn_status IN (10,20,25);
CREATE INDEX idx_inv_stock_txn_pair ON inv_stock_txn (tenant_id, company_id, pair_key) WHERE pair_key IS NOT NULL;
CREATE INDEX idx_inv_stock_txn_wo ON inv_stock_txn (tenant_id, company_id, work_order_id) WHERE work_order_id IS NOT NULL;

COMMENT ON TABLE inv_stock_txn IS '库存事务（在庫取引）ヘッダ。txn_type は 09 §7.1 の 19 種のみ';
COMMENT ON COLUMN inv_stock_txn.txn_no IS '業務伝票番号。GRI/SDO/MII/MIR/FGI/OSI/OSR/TR/CNT/AOI/AOO は 08 §2.1 の採番、ST は来源番号または内部番号';
COMMENT ON COLUMN inv_stock_txn.accounting_period IS 'txn_date から導出した会計期間（YYYY-MM）。inv_period の OPEN 判定に使用';

-- inv_stock_txn_key（90-db-design.md:463）
CREATE TABLE inv_stock_txn_key (
    id          BIGINT       NOT NULL,
    tenant_id   BIGINT       NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id  BIGINT       NOT NULL,
    key_type    VARCHAR(16)  NOT NULL,       -- TXN_NO / SOURCE_POSTED / REVERSAL / PAIR
    key_value   VARCHAR(200) NOT NULL,       -- TXN_NO: txn_no／SOURCE_POSTED: source_type|source_id|txn_type／REVERSAL: reversal_of_txn_id／PAIR: pair_key|txn_type
    txn_id      BIGINT       NOT NULL,       -- inv_stock_txn.id（软引用、04 §8.1）
    txn_date    DATE         NOT NULL,       -- パーティション特定用
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_by  BIGINT       NOT NULL DEFAULT 0,
    CONSTRAINT pk_inv_stock_txn_key PRIMARY KEY (id),
    CONSTRAINT ck_inv_stock_txn_key_type CHECK (key_type IN ('TXN_NO','SOURCE_POSTED','REVERSAL','PAIR'))
);
ALTER TABLE inv_stock_txn_key ENABLE ROW LEVEL SECURITY;
ALTER TABLE inv_stock_txn_key FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON inv_stock_txn_key
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_inv_stock_txn_key ON inv_stock_txn_key (tenant_id, company_id, key_type, key_value);
CREATE INDEX idx_inv_stock_txn_key_txn ON inv_stock_txn_key (tenant_id, company_id, txn_id);
COMMENT ON TABLE inv_stock_txn_key IS '在庫事務の全期間一意キー台帳（パーティション表 inv_stock_txn の代替一意制約）';

-- inv_stock_txn_line（90-db-design.md:505）
CREATE TABLE inv_stock_txn_line (
    id              BIGINT        NOT NULL,
    tenant_id       BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id      BIGINT        NOT NULL,
    txn_id          BIGINT        NOT NULL,
    line_no         INT           NOT NULL,
    material_id     BIGINT        NOT NULL,
    material_code   VARCHAR(10)   NOT NULL,
    material_name   VARCHAR(200)  NOT NULL,
    spec            VARCHAR(200),
    uom_code        VARCHAR(16)   NOT NULL,
    qty             NUMERIC(18,4) NOT NULL,
    direction       SMALLINT      NOT NULL,                -- +1:IN / -1:OUT
    batch_id        BIGINT        NOT NULL DEFAULT 0,
    batch_no        VARCHAR(64)   NOT NULL DEFAULT '',
    stock_status    SMALLINT      NOT NULL,
    inspection_flag BOOLEAN       NOT NULL,                -- inbound: PI/OSR stage in {10,40}; FGI in {30,40}; else false
    txn_type        VARCHAR(16)   NOT NULL,                -- redundant with header; trigger enforces match (04 sec 8.1)
    location_id     BIGINT        NOT NULL DEFAULT 0,
    unit_cost       NUMERIC(18,6),
    amount          NUMERIC(18,2),
    valuation_method SMALLINT     NOT NULL,                -- mdm_material.valuation_method のスナップショット：10移動平均/20標準原価
    std_unit_cost   NUMERIC(18,6),                         -- valuation_method=20：fin_standard_cost.total_unit_cost（txn_date の有効版）
    variance_amount NUMERIC(18,2) NOT NULL DEFAULT 0,      -- valuation_method=20 の入庫：実際原価 − 標準原価（FIN 差異へ、在庫金額に含めない）
    purchase_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
    freight_amount  NUMERIC(18,2) NOT NULL DEFAULT 0,
    duty_amount     NUMERIC(18,2) NOT NULL DEFAULT 0,
    other_amount    NUMERIC(18,2) NOT NULL DEFAULT 0,
    before_qty      NUMERIC(18,4),
    before_amount   NUMERIC(18,2),
    after_qty       NUMERIC(18,4),
    after_amount    NUMERIC(18,2),
    after_avg_cost  NUMERIC(18,6),
    cost_layer_id   BIGINT,
    serial_id       BIGINT,
    serial_no       VARCHAR(64),
    source_line_id  BIGINT,
    source_line_no  INT,
    remark          VARCHAR(500),
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by      BIGINT        NOT NULL DEFAULT 0,
    CONSTRAINT pk_inv_stock_txn_line PRIMARY KEY (id),
    -- txn_id は FK なし（inv_stock_txn はパーティション表、04 §8.1）。トリガー trg_inv_stock_txn_line_head で表頭の存在・txn_type 一致を検証
    CONSTRAINT ck_inv_stock_txn_line_type CHECK (txn_type IN
        ('PI','SI','MII','MIR','FGI','OSI','OSR','TR_OUT','TR_IN','ADJ_IN','ADJ_OUT',
         'SC_IN','SC_OUT','AOI','AOO','RT_IN','PR_OUT','ST_IN','ST_OUT')),
    -- direction は txn_type の基本方向（IN：PI/MIR/FGI/OSR/TR_IN/ADJ_IN/SC_IN/AOI/RT_IN/ST_IN、OUT：その他）×（表頭 is_reversal なら −1）。
    -- 沖销は同一 txn_type・方向反転（00-overview §冲销）のため CHECK では表現できず、上記トリガーで検証する。
    CONSTRAINT ck_inv_stock_txn_line_valuation CHECK (valuation_method IN (10,20)),
    CONSTRAINT ck_inv_stock_txn_line_std CHECK (valuation_method = 10 OR std_unit_cost IS NOT NULL OR unit_cost IS NULL),
    CONSTRAINT ck_inv_stock_txn_line_qty CHECK (qty > 0),
    CONSTRAINT ck_inv_stock_txn_line_direction CHECK (direction IN (1, -1)),
    CONSTRAINT ck_inv_stock_txn_line_status CHECK (stock_status IN (10,20,30,40,50)),
    CONSTRAINT ck_inv_stock_txn_line_amount CHECK (amount IS NULL OR amount >= 0),
    CONSTRAINT ck_inv_stock_txn_line_insp_inbound CHECK (
        direction <> 1 OR inspection_flag = FALSE OR stock_status = 10
    )
);
ALTER TABLE inv_stock_txn_line ENABLE ROW LEVEL SECURITY;
ALTER TABLE inv_stock_txn_line FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON inv_stock_txn_line
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);

CREATE UNIQUE INDEX uk_inv_stock_txn_line_no ON inv_stock_txn_line (tenant_id, company_id, txn_id, line_no);
CREATE INDEX idx_inv_stock_txn_line_material_date
    ON inv_stock_txn_line (tenant_id, company_id, material_id, batch_id, txn_id);
CREATE INDEX idx_inv_stock_txn_line_batch
    ON inv_stock_txn_line (tenant_id, company_id, batch_id) WHERE batch_id <> 0;
CREATE INDEX idx_inv_stock_txn_line_serial
    ON inv_stock_txn_line (tenant_id, company_id, serial_no) WHERE serial_no IS NOT NULL;
CREATE INDEX idx_inv_stock_txn_line_source
    ON inv_stock_txn_line (tenant_id, company_id, source_line_id) WHERE source_line_id IS NOT NULL;

COMMENT ON TABLE inv_stock_txn_line IS '库存事务明细（在庫取引明細）。追記専用';
COMMENT ON COLUMN inv_stock_txn_line.direction IS '+1=入庫(IN) / -1=出庫(OUT)。残高変動 = direction × qty';
COMMENT ON COLUMN inv_stock_txn_line.amount IS '行金額（2桁）。入庫=原価構成合計、出庫=移動平均×数量。草稿時は NULL';
COMMENT ON COLUMN inv_stock_txn_line.after_avg_cost IS '過账後の移動平均単価（監査・原価追跡用）';

-- 表头存在（同 tenant/company）・txn_type 一致・direction 符号（§3.3、§4.3.1 注释、§9 トリガー）
CREATE FUNCTION public.inv_stock_txn_line_head_check()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public, pg_temp
AS $$
DECLARE
    h_type     VARCHAR(16);
    h_reversal BOOLEAN;
    expected   SMALLINT;
BEGIN
    SELECT h.txn_type, h.is_reversal INTO h_type, h_reversal
      FROM inv_stock_txn h
     WHERE h.tenant_id = NEW.tenant_id AND h.company_id = NEW.company_id AND h.id = NEW.txn_id
     LIMIT 1;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'inv_stock_txn_line.txn_id=% 在同租户同公司下没有表头 inv_stock_txn', NEW.txn_id
            USING ERRCODE = '23503', CONSTRAINT = 'trg_inv_stock_txn_line_head';
    END IF;
    IF NEW.txn_type <> h_type THEN
        RAISE EXCEPTION 'inv_stock_txn_line.txn_type=% 与表头 txn_type=% 不一致', NEW.txn_type, h_type
            USING ERRCODE = '23514', CONSTRAINT = 'trg_inv_stock_txn_line_head';
    END IF;
    expected := CASE WHEN NEW.txn_type IN ('PI','MIR','FGI','OSR','TR_IN','ADJ_IN','SC_IN','AOI','RT_IN','ST_IN') THEN 1 ELSE -1 END;
    IF h_reversal THEN expected := -expected; END IF;
    IF NEW.direction <> expected THEN
        RAISE EXCEPTION 'inv_stock_txn_line.direction=% 与 txn_type=%（is_reversal=%）不符，应为 %', NEW.direction, NEW.txn_type, h_reversal, expected
            USING ERRCODE = '23514', CONSTRAINT = 'trg_inv_stock_txn_line_head';
    END IF;
    RETURN NEW;
END $$;
CREATE TRIGGER trg_inv_stock_txn_line_head
    BEFORE INSERT OR UPDATE OF tenant_id, company_id, txn_id, txn_type, direction ON inv_stock_txn_line
    FOR EACH ROW EXECUTE FUNCTION public.inv_stock_txn_line_head_check();
COMMENT ON FUNCTION public.inv_stock_txn_line_head_check() IS 'trg_inv_stock_txn_line_head：表头存在・txn_type 一致・direction = 基本方向 ×（is_reversal ? -1 : 1）';

-- inv_transfer（90-db-design.md:630）
CREATE TABLE inv_transfer (
    id               BIGINT        NOT NULL,
    tenant_id        BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id      BIGINT        NOT NULL,
    transfer_no      VARCHAR(32)   NOT NULL,
    transfer_type    SMALLINT      NOT NULL DEFAULT 20,   -- 10同倉移庫/20跨倉調撥/30跨工場(P2)
    transfer_date    DATE          NOT NULL,
    from_factory_id  BIGINT        NOT NULL,
    from_warehouse_id BIGINT       NOT NULL,
    from_location_id BIGINT        NOT NULL DEFAULT 0,
    to_factory_id    BIGINT        NOT NULL,
    to_warehouse_id  BIGINT        NOT NULL,
    to_location_id   BIGINT        NOT NULL DEFAULT 0,
    transfer_status  SMALLINT      NOT NULL DEFAULT 10,   -- 10/20/25/30/35/40/90
    reason           VARCHAR(200)  NOT NULL,
    applicant_id     BIGINT        NOT NULL,
    approval_status  SMALLINT      NOT NULL DEFAULT 0,    -- 0不要/10待ち/20承認/30却下
    shipped_at       TIMESTAMPTZ,
    received_at      TIMESTAMPTZ,
    total_qty        NUMERIC(18,4) NOT NULL DEFAULT 0,
    in_transit_qty   NUMERIC(18,4) NOT NULL DEFAULT 0,
    version          INT           NOT NULL DEFAULT 0,
    remark           VARCHAR(500),
    ext_data         JSONB,
    created_at       TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by       BIGINT        NOT NULL DEFAULT 0,
    updated_at       TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by       BIGINT        NOT NULL DEFAULT 0,
    CONSTRAINT pk_inv_transfer PRIMARY KEY (id),
    CONSTRAINT uk_inv_transfer_tenant_company_id UNIQUE (tenant_id, company_id, id),  -- 同域複合 FK の被参照キー（業務一意キーではない、#43）
    CONSTRAINT ck_inv_transfer_type CHECK (transfer_type IN (10,20,30)),
    CONSTRAINT ck_inv_transfer_status CHECK (transfer_status IN (10,20,25,30,35,40,90)),
    CONSTRAINT ck_inv_transfer_qty CHECK (total_qty >= 0 AND in_transit_qty >= 0),
    CONSTRAINT ck_inv_transfer_approval CHECK (approval_status IN (0,10,20,30)),
    CONSTRAINT ck_inv_transfer_wh CHECK (
        (transfer_type = 10 AND from_warehouse_id = to_warehouse_id)
        OR (transfer_type IN (20,30) AND from_warehouse_id <> to_warehouse_id))
);
ALTER TABLE inv_transfer ENABLE ROW LEVEL SECURITY;
ALTER TABLE inv_transfer FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON inv_transfer
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_inv_transfer_no ON inv_transfer (tenant_id, company_id, transfer_no);
CREATE INDEX idx_inv_transfer_status ON inv_transfer (tenant_id, company_id, transfer_status, transfer_date DESC);
CREATE INDEX idx_inv_transfer_from_wh ON inv_transfer (tenant_id, company_id, from_warehouse_id, transfer_date DESC);
CREATE INDEX idx_inv_transfer_to_wh ON inv_transfer (tenant_id, company_id, to_warehouse_id, transfer_date DESC);
CREATE INDEX idx_inv_transfer_intransit ON inv_transfer (tenant_id, company_id, transfer_date)
    WHERE transfer_status IN (30, 35);
COMMENT ON TABLE inv_transfer IS '库存调拨单（同倉移庫・跨倉調撥・在途管理）';
COMMENT ON COLUMN inv_transfer.in_transit_qty IS '出庫済・未受入の数量（= Σ line.qty - received_qty）';

-- inv_transfer_line（90-db-design.md:692）
CREATE TABLE inv_transfer_line (
    id              BIGINT        NOT NULL,
    tenant_id       BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id      BIGINT        NOT NULL,
    transfer_id     BIGINT        NOT NULL,
    line_no         INT           NOT NULL,
    material_id     BIGINT        NOT NULL,
    material_code   VARCHAR(10)   NOT NULL,
    material_name   VARCHAR(200)  NOT NULL,
    spec            VARCHAR(200),
    uom_code        VARCHAR(16)   NOT NULL,
    qty             NUMERIC(18,4) NOT NULL,
    shipped_qty     NUMERIC(18,4) NOT NULL DEFAULT 0,
    received_qty    NUMERIC(18,4) NOT NULL DEFAULT 0,
    returned_qty    NUMERIC(18,4) NOT NULL DEFAULT 0,
    in_transit_qty  NUMERIC(18,4) NOT NULL DEFAULT 0,
    batch_id        BIGINT        NOT NULL DEFAULT 0,
    batch_no        VARCHAR(64)   NOT NULL DEFAULT '',
    stock_status    SMALLINT      NOT NULL DEFAULT 10,
    unit_cost       NUMERIC(18,6),
    amount          NUMERIC(18,2),
    remark          VARCHAR(200),
    version         INT           NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by      BIGINT        NOT NULL DEFAULT 0,
    updated_at      TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by      BIGINT        NOT NULL DEFAULT 0,
    CONSTRAINT pk_inv_transfer_line PRIMARY KEY (id),
    CONSTRAINT fk_inv_transfer_line_head FOREIGN KEY (tenant_id, company_id, transfer_id) REFERENCES inv_transfer (tenant_id, company_id, id),
    CONSTRAINT ck_inv_transfer_line_qty CHECK (qty > 0 AND shipped_qty >= 0 AND received_qty >= 0
        AND received_qty + returned_qty <= shipped_qty AND in_transit_qty >= 0)
);
ALTER TABLE inv_transfer_line ENABLE ROW LEVEL SECURITY;
ALTER TABLE inv_transfer_line FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON inv_transfer_line
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_inv_transfer_line_no ON inv_transfer_line (tenant_id, company_id, transfer_id, line_no);
CREATE INDEX idx_inv_transfer_line_material ON inv_transfer_line (tenant_id, company_id, material_id);
COMMENT ON TABLE inv_transfer_line IS '库存调拨单明细。金額保存則 ΣTR_OUT.amount = ΣTR_IN.amount（04 §7）';

-- inv_stocktake_plan（90-db-design.md:742）
CREATE TABLE inv_stocktake_plan (
    id                 BIGINT        NOT NULL,
    tenant_id          BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id      BIGINT        NOT NULL,
    plan_no            VARCHAR(32)   NOT NULL,
    plan_name          VARCHAR(100)  NOT NULL,
    plan_type          SMALLINT      NOT NULL DEFAULT 20,  -- 10全盤/20循環/30抽盤/40重点
    warehouse_id       BIGINT        NOT NULL,
    scope_json         JSONB         NOT NULL,             -- {categoryCodes,materialIds,locationIds,stockStatuses}
    freeze_mode        SMALLINT      NOT NULL DEFAULT 10,  -- 10時点スナップショット/20全倉凍結
    planned_start_date DATE          NOT NULL,
    planned_end_date   DATE          NOT NULL,
    plan_status        SMALLINT      NOT NULL DEFAULT 10,  -- 10/20/25/30/40/90
    approval_comment   VARCHAR(500),
    approved_at        TIMESTAMPTZ,
    approved_by        BIGINT,
    version            INT           NOT NULL DEFAULT 0,
    remark             VARCHAR(500),
    ext_data           JSONB,
    created_at         TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by         BIGINT        NOT NULL DEFAULT 0,
    updated_at         TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by         BIGINT        NOT NULL DEFAULT 0,
    CONSTRAINT pk_inv_stocktake_plan PRIMARY KEY (id),
    CONSTRAINT uk_inv_stocktake_plan_tenant_company_id UNIQUE (tenant_id, company_id, id),  -- 同域複合 FK の被参照キー（業務一意キーではない、#43）
    CONSTRAINT ck_inv_stocktake_plan_type CHECK (plan_type IN (10,20,30,40)),
    CONSTRAINT ck_inv_stocktake_plan_freeze CHECK (freeze_mode IN (10,20)),
    CONSTRAINT ck_inv_stocktake_plan_status CHECK (plan_status IN (10,20,25,30,40,90)),
    CONSTRAINT ck_inv_stocktake_plan_date CHECK (planned_start_date <= planned_end_date)
);
ALTER TABLE inv_stocktake_plan ENABLE ROW LEVEL SECURITY;
ALTER TABLE inv_stocktake_plan FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON inv_stocktake_plan
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_inv_stocktake_plan_no ON inv_stocktake_plan (tenant_id, company_id, plan_no);
CREATE INDEX idx_inv_stocktake_plan_wh ON inv_stocktake_plan (tenant_id, company_id, warehouse_id, plan_status);
COMMENT ON TABLE inv_stocktake_plan IS '盘点计划（全盤/循環/抽盤/重点）。scope_json に対象範囲を保持';
COMMENT ON COLUMN inv_stocktake_plan.scope_json IS 'JSON: {"categoryCodes":[],"materialIds":[],"locationIds":[],"stockStatuses":[10,20,30,40,50]}';

-- inv_stocktake（90-db-design.md:791）
CREATE TABLE inv_stocktake (
    id                BIGINT        NOT NULL,
    tenant_id         BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id      BIGINT        NOT NULL,
    stocktake_no      VARCHAR(32)   NOT NULL,
    plan_id           BIGINT        NOT NULL,
    warehouse_id      BIGINT        NOT NULL,
    take_date         DATE          NOT NULL,
    snapshot_at       TIMESTAMPTZ   NOT NULL,
    snapshot_txn_id   BIGINT,                              -- スナップショット時点の最終事務 ID（純変動計算用）
    freeze_mode       SMALLINT      NOT NULL DEFAULT 10,
    take_status       SMALLINT      NOT NULL DEFAULT 10,   -- 10作成中/20実盤入力中/30差異確認中/35承認待ち/40承認済/90取消
    total_lines       INT           NOT NULL DEFAULT 0,
    counted_lines     INT           NOT NULL DEFAULT 0,
    diff_lines        INT           NOT NULL DEFAULT 0,
    diff_amount       NUMERIC(18,2) NOT NULL DEFAULT 0,
    diff_change_reason VARCHAR(500),
    approved_at       TIMESTAMPTZ,
    approved_by       BIGINT,
    adjust_txn_id     BIGINT,
    version           INT           NOT NULL DEFAULT 0,
    remark            VARCHAR(500),
    ext_data          JSONB,
    created_at        TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by        BIGINT        NOT NULL DEFAULT 0,
    updated_at        TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by        BIGINT        NOT NULL DEFAULT 0,
    CONSTRAINT pk_inv_stocktake PRIMARY KEY (id),
    CONSTRAINT uk_inv_stocktake_tenant_company_id UNIQUE (tenant_id, company_id, id),  -- 同域複合 FK の被参照キー（業務一意キーではない、#43）
    CONSTRAINT fk_inv_stocktake_plan FOREIGN KEY (tenant_id, company_id, plan_id) REFERENCES inv_stocktake_plan (tenant_id, company_id, id),
    CONSTRAINT ck_inv_stocktake_freeze CHECK (freeze_mode IN (10,20)),
    CONSTRAINT ck_inv_stocktake_status CHECK (take_status IN (10,20,30,35,40,90)),
    CONSTRAINT ck_inv_stocktake_lines CHECK (total_lines >= 0 AND counted_lines >= 0 AND diff_lines >= 0)
);
ALTER TABLE inv_stocktake ENABLE ROW LEVEL SECURITY;
ALTER TABLE inv_stocktake FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON inv_stocktake
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_inv_stocktake_no ON inv_stocktake (tenant_id, company_id, stocktake_no);
CREATE INDEX idx_inv_stocktake_wh_status ON inv_stocktake (tenant_id, company_id, warehouse_id, take_status);
CREATE INDEX idx_inv_stocktake_open ON inv_stocktake (tenant_id, company_id, warehouse_id)
    WHERE take_status IN (10,20,30,35);
COMMENT ON TABLE inv_stocktake IS '盘点单（账面スナップショット・実盤・差異・承認・調整）';
COMMENT ON COLUMN inv_stocktake.snapshot_txn_id IS 'スナップショット時点の最終在庫事務 ID。差異計算の期間変動還元に使用（03 §6.2）';

-- inv_stocktake_line（90-db-design.md:845）
CREATE TABLE inv_stocktake_line (
    id               BIGINT        NOT NULL,
    tenant_id        BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id      BIGINT        NOT NULL,
    stocktake_id     BIGINT        NOT NULL,
    line_no          INT           NOT NULL,
    material_id      BIGINT        NOT NULL,
    material_code    VARCHAR(10)   NOT NULL,
    material_name    VARCHAR(200)  NOT NULL,
    spec             VARCHAR(200),
    batch_id         BIGINT        NOT NULL DEFAULT 0,
    batch_no         VARCHAR(64)   NOT NULL DEFAULT '',
    stock_status     SMALLINT      NOT NULL,
    location_id      BIGINT        NOT NULL DEFAULT 0,
    uom_code         VARCHAR(16)   NOT NULL,
    book_qty         NUMERIC(18,4) NOT NULL,
    net_movement     NUMERIC(18,4) NOT NULL DEFAULT 0,
    counted_qty      NUMERIC(18,4),
    re_counted_qty   NUMERIC(18,4),
    final_qty        NUMERIC(18,4),
    diff_qty         NUMERIC(18,4),
    unit_cost        NUMERIC(18,6) NOT NULL DEFAULT 0,
    diff_amount      NUMERIC(18,2) NOT NULL DEFAULT 0,
    diff_reason      SMALLINT,                              -- 10管理不善/20自然損耗/30計量誤差/40記録誤差/50災害/60その他
    new_batch_no     VARCHAR(64),
    adjust_txn_line_id BIGINT,
    remark           VARCHAR(200),
    version          INT           NOT NULL DEFAULT 0,
    created_at       TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by       BIGINT        NOT NULL DEFAULT 0,
    updated_at       TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by       BIGINT        NOT NULL DEFAULT 0,
    CONSTRAINT pk_inv_stocktake_line PRIMARY KEY (id),
    CONSTRAINT fk_inv_stocktake_line_head FOREIGN KEY (tenant_id, company_id, stocktake_id) REFERENCES inv_stocktake (tenant_id, company_id, id),
    CONSTRAINT ck_inv_stocktake_line_counted CHECK (counted_qty IS NULL OR counted_qty >= 0),
    CONSTRAINT ck_inv_stocktake_line_recounted CHECK (re_counted_qty IS NULL OR re_counted_qty >= 0),
    CONSTRAINT ck_inv_stocktake_line_reason CHECK (diff_reason IS NULL OR diff_reason IN (10,20,30,40,50,60))
);
ALTER TABLE inv_stocktake_line ENABLE ROW LEVEL SECURITY;
ALTER TABLE inv_stocktake_line FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON inv_stocktake_line
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_inv_stocktake_line_key
    ON inv_stocktake_line (tenant_id, company_id, stocktake_id, material_id, batch_id, stock_status, location_id);
CREATE INDEX idx_inv_stocktake_line_diff
    ON inv_stocktake_line (tenant_id, company_id, stocktake_id) WHERE diff_qty IS NOT NULL AND diff_qty <> 0;
COMMENT ON TABLE inv_stocktake_line IS '盘点单明细。1 行 = 倉庫×物料×批次×状態×庫位';
COMMENT ON COLUMN inv_stocktake_line.net_movement IS 'スナップショット後の純変動（direction×qty 合計）。差異 = final_qty - (book_qty + net_movement)';

-- inv_batch（90-db-design.md:905）
CREATE TABLE inv_batch (
    id               BIGINT        NOT NULL,
    tenant_id        BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id      BIGINT        NOT NULL,
    batch_no         VARCHAR(64)   NOT NULL,
    material_id      BIGINT        NOT NULL,
    batch_type       SMALLINT      NOT NULL DEFAULT 10,   -- 10采购/20制造/30期初/40其他
    supplier_id      BIGINT,
    supplier_batch_no VARCHAR(64),
    receipt_date     DATE,
    production_date  DATE,
    expiry_date      DATE,
    qc_status        SMALLINT      NOT NULL DEFAULT 10,   -- 10待検/20合格/30特採/40不合格
    batch_status     SMALLINT      NOT NULL DEFAULT 10,   -- 10有効/40枯渇/90封存
    first_txn_id     BIGINT,
    last_txn_date    DATE,
    version          INT           NOT NULL DEFAULT 0,
    remark           VARCHAR(500),
    ext_data         JSONB,
    created_at       TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by       BIGINT        NOT NULL DEFAULT 0,
    updated_at       TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by       BIGINT        NOT NULL DEFAULT 0,
    CONSTRAINT pk_inv_batch PRIMARY KEY (id),
    CONSTRAINT ck_inv_batch_type CHECK (batch_type IN (10,20,30,40)),
    CONSTRAINT ck_inv_batch_qc CHECK (qc_status IN (10,20,30,40)),
    CONSTRAINT ck_inv_batch_status CHECK (batch_status IN (10,40,90)),
    CONSTRAINT ck_inv_batch_expiry CHECK (expiry_date IS NULL OR receipt_date IS NULL OR expiry_date >= receipt_date)
);
ALTER TABLE inv_batch ENABLE ROW LEVEL SECURITY;
ALTER TABLE inv_batch FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON inv_batch
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_inv_batch_material_no ON inv_batch (tenant_id, company_id, material_id, batch_no);
CREATE INDEX idx_inv_batch_expiry ON inv_batch (tenant_id, company_id, expiry_date, batch_status)
    WHERE expiry_date IS NOT NULL;
CREATE INDEX idx_inv_batch_supplier_lot ON inv_batch (tenant_id, company_id, supplier_batch_no)
    WHERE supplier_batch_no IS NOT NULL;
COMMENT ON TABLE inv_batch IS '批次主档（批号・種別・有效期・QC 状態）';
COMMENT ON COLUMN inv_batch.supplier_batch_no IS '供給者ロット番号（BN-LOT 形式を推奨。90-data/code-lists/batch-number-rule.csv）';

-- inv_batch_genealogy（90-db-design.md:958）
CREATE TABLE inv_batch_genealogy (
    id                 BIGINT      NOT NULL,
    tenant_id          BIGINT      NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id      BIGINT        NOT NULL,
    parent_batch_id    BIGINT      NOT NULL,      -- 消費された原料/半成品の批次
    child_batch_id     BIGINT      NOT NULL,      -- 生成された製品/半製品の批次
    relation_type      SMALLINT    NOT NULL DEFAULT 10, -- 10生産消費/20委外/30拆分/40返工
    source_txn_id      BIGINT      NOT NULL,      -- FGI/OSR の事務
    source_txn_line_id BIGINT,
    work_order_id      BIGINT,
    outsourcing_order_id BIGINT,
    qty_consumed       NUMERIC(18,4) NOT NULL,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by         BIGINT      NOT NULL DEFAULT 0,
    CONSTRAINT pk_inv_batch_genealogy PRIMARY KEY (id),
    CONSTRAINT ck_inv_batch_genealogy_rel CHECK (relation_type IN (10,20,30,40)),
    CONSTRAINT ck_inv_batch_genealogy_qty CHECK (qty_consumed > 0),
    CONSTRAINT ck_inv_batch_genealogy_self CHECK (parent_batch_id <> child_batch_id)
);
ALTER TABLE inv_batch_genealogy ENABLE ROW LEVEL SECURITY;
ALTER TABLE inv_batch_genealogy FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON inv_batch_genealogy
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
-- NULLS NOT DISTINCT：source_txn_line_id 为 NULL 的系谱也去重（蓝色大肥鱼 2026-10-21 决定，#55）
CREATE UNIQUE INDEX uk_inv_batch_genealogy_key
    ON inv_batch_genealogy (tenant_id, company_id, parent_batch_id, child_batch_id, source_txn_line_id) NULLS NOT DISTINCT;
CREATE INDEX idx_inv_batch_genealogy_child ON inv_batch_genealogy (tenant_id, company_id, child_batch_id);
CREATE INDEX idx_inv_batch_genealogy_parent ON inv_batch_genealogy (tenant_id, company_id, parent_batch_id);
CREATE INDEX idx_inv_batch_genealogy_wo ON inv_batch_genealogy (tenant_id, company_id, work_order_id)
    WHERE work_order_id IS NOT NULL;
COMMENT ON TABLE inv_batch_genealogy IS '批次系譜（父批次→子批次）。前向/後向追溯に使用';

-- inv_serial（90-db-design.md:998）
CREATE TABLE inv_serial (
    id                BIGINT       NOT NULL,
    tenant_id         BIGINT       NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id      BIGINT        NOT NULL,
    serial_no         VARCHAR(64)  NOT NULL,
    external_serial_no VARCHAR(64),
    material_id       BIGINT       NOT NULL,
    batch_id          BIGINT       NOT NULL DEFAULT 0,
    serial_status     SMALLINT     NOT NULL DEFAULT 10,  -- 10在庫/20已出庫/30已退回/40報廃/50凍結
    inbound_txn_id    BIGINT,
    inbound_date      DATE,
    outbound_txn_id   BIGINT,
    outbound_date     DATE,
    customer_id       BIGINT,
    customer_name     VARCHAR(200),
    work_order_id     BIGINT,
    manufacture_date  DATE,
    warranty_end_date DATE,
    version           INT          NOT NULL DEFAULT 0,
    remark            VARCHAR(500),
    ext_data          JSONB,
    created_at        TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_by        BIGINT       NOT NULL DEFAULT 0,
    updated_at        TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_by        BIGINT       NOT NULL DEFAULT 0,
    CONSTRAINT pk_inv_serial PRIMARY KEY (id),
    CONSTRAINT uk_inv_serial_tenant_company_id UNIQUE (tenant_id, company_id, id),  -- 同域複合 FK の被参照キー（業務一意キーではない、#43）
    CONSTRAINT ck_inv_serial_status CHECK (serial_status IN (10,20,30,40,50))
);
ALTER TABLE inv_serial ENABLE ROW LEVEL SECURITY;
ALTER TABLE inv_serial FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON inv_serial
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_inv_serial_no ON inv_serial (tenant_id, company_id, serial_no);
CREATE UNIQUE INDEX uk_inv_serial_external
    ON inv_serial (tenant_id, company_id, external_serial_no)
    WHERE external_serial_no IS NOT NULL;
CREATE INDEX idx_inv_serial_material ON inv_serial (tenant_id, company_id, material_id, serial_status);
CREATE INDEX idx_inv_serial_customer ON inv_serial (tenant_id, company_id, customer_id, outbound_date)
    WHERE customer_id IS NOT NULL;
CREATE INDEX idx_inv_serial_batch ON inv_serial (tenant_id, company_id, batch_id) WHERE batch_id <> 0;
COMMENT ON TABLE inv_serial IS '序列号主档（成品电机の個体識別・顧客・製造指図）';
COMMENT ON COLUMN inv_serial.serial_no IS '成品: {YYMMDD}{機座号3桁}{4位流水}（例 2610201000001）';

-- inv_serial_txn（90-db-design.md:1050）
CREATE TABLE inv_serial_txn (
    id           BIGINT      NOT NULL,
    tenant_id    BIGINT      NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id      BIGINT        NOT NULL,
    serial_id    BIGINT      NOT NULL,
    txn_id       BIGINT      NOT NULL,
    txn_line_id  BIGINT,
    txn_type     VARCHAR(16) NOT NULL,
    direction    SMALLINT    NOT NULL,
    status_before SMALLINT,
    status_after  SMALLINT,
    txn_date     DATE        NOT NULL,
    warehouse_id BIGINT      NOT NULL,
    batch_id     BIGINT      NOT NULL DEFAULT 0,
    customer_id  BIGINT,
    work_order_id BIGINT,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by   BIGINT      NOT NULL DEFAULT 0,
    CONSTRAINT pk_inv_serial_txn PRIMARY KEY (id),
    CONSTRAINT fk_inv_serial_txn_serial FOREIGN KEY (tenant_id, company_id, serial_id) REFERENCES inv_serial (tenant_id, company_id, id),
    CONSTRAINT ck_inv_serial_txn_direction CHECK (direction IN (1,-1)),
    CONSTRAINT ck_inv_serial_txn_status CHECK ((status_before IS NULL OR status_before IN (10,20,30,40,50)) AND (status_after IS NULL OR status_after IN (10,20,30,40,50)))
);
ALTER TABLE inv_serial_txn ENABLE ROW LEVEL SECURITY;
ALTER TABLE inv_serial_txn FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON inv_serial_txn
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE INDEX idx_inv_serial_txn_serial ON inv_serial_txn (tenant_id, company_id, serial_id, txn_date DESC);
CREATE INDEX idx_inv_serial_txn_txn ON inv_serial_txn (tenant_id, company_id, txn_id);
COMMENT ON TABLE inv_serial_txn IS '序列号状態変化履歴。追記専用';

-- inv_reservation（90-db-design.md:1089）
CREATE TABLE inv_reservation (
    id               BIGINT       NOT NULL,
    tenant_id        BIGINT       NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id      BIGINT        NOT NULL,
    reservation_no   VARCHAR(32)  NOT NULL,          -- RSV + YYMMDD + 4桁（08 §2.1）
    source_type      VARCHAR(32)  NOT NULL,          -- SALES_ORDER / WORK_ORDER / MANUAL
    source_id        BIGINT       NOT NULL,
    source_no        VARCHAR(32),
    source_version   INT,                            -- E07 の aggregateVersion 管理
    reservation_status SMALLINT   NOT NULL DEFAULT 10, -- 10有効/20不足/35一部消耗/40完了/90已释放
    expire_date      DATE,
    shortage_qty     NUMERIC(18,4) NOT NULL DEFAULT 0,
    version          INT          NOT NULL DEFAULT 0,
    remark           VARCHAR(500),
    ext_data         JSONB,
    created_at       TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_by       BIGINT       NOT NULL DEFAULT 0,
    updated_at       TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_by       BIGINT       NOT NULL DEFAULT 0,
    CONSTRAINT pk_inv_reservation PRIMARY KEY (id),
    CONSTRAINT uk_inv_reservation_tenant_company_id UNIQUE (tenant_id, company_id, id),  -- 同域複合 FK の被参照キー（業務一意キーではない、#43）
    CONSTRAINT ck_inv_reservation_source CHECK (source_type IN ('SALES_ORDER','WORK_ORDER','MANUAL')),
    CONSTRAINT ck_inv_reservation_status CHECK (reservation_status IN (10,20,35,40,90)),
    CONSTRAINT ck_inv_reservation_shortage CHECK (shortage_qty >= 0)
);
ALTER TABLE inv_reservation ENABLE ROW LEVEL SECURITY;
ALTER TABLE inv_reservation FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON inv_reservation
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_inv_reservation_no ON inv_reservation (tenant_id, company_id, reservation_no);
CREATE UNIQUE INDEX uk_inv_reservation_source
    ON inv_reservation (tenant_id, company_id, source_type, source_id)
    WHERE reservation_status <> 90;
CREATE INDEX idx_inv_reservation_expire
    ON inv_reservation (tenant_id, company_id, expire_date)
    WHERE reservation_status IN (10,20,35);
COMMENT ON TABLE inv_reservation IS '库存预留（引当）ヘッダ。受注/工单単位';
COMMENT ON COLUMN inv_reservation.reservation_status IS '10有効(RESERVED)/20不足(SHORTAGE)/35一部消耗/40完了/90已释放(RELEASED)。E09 の status と対応';

-- inv_reservation_line（90-db-design.md:1137）
CREATE TABLE inv_reservation_line (
    id              BIGINT        NOT NULL,
    tenant_id       BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id      BIGINT        NOT NULL,
    reservation_id  BIGINT        NOT NULL,
    line_no         INT           NOT NULL,
    material_id     BIGINT        NOT NULL,
    warehouse_id    BIGINT        NOT NULL,
    batch_id        BIGINT        NOT NULL DEFAULT 0,
    batch_no        VARCHAR(64)   NOT NULL DEFAULT '',
    reserved_qty    NUMERIC(18,4) NOT NULL,
    consumed_qty    NUMERIC(18,4) NOT NULL DEFAULT 0,
    released_qty    NUMERIC(18,4) NOT NULL DEFAULT 0,
    shortage_qty    NUMERIC(18,4) NOT NULL DEFAULT 0,
    last_consume_txn_id BIGINT,                   -- 消費の二重加算防止
    line_status     SMALLINT      NOT NULL DEFAULT 10, -- 10有効/35一部消耗/40完了/90已释放
    remark          VARCHAR(200),
    version         INT           NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by      BIGINT        NOT NULL DEFAULT 0,
    updated_at      TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by      BIGINT        NOT NULL DEFAULT 0,
    CONSTRAINT pk_inv_reservation_line PRIMARY KEY (id),
    CONSTRAINT fk_inv_reservation_line_head FOREIGN KEY (tenant_id, company_id, reservation_id) REFERENCES inv_reservation (tenant_id, company_id, id),
    CONSTRAINT ck_inv_reservation_line_status CHECK (line_status IN (10,35,40,90)),
    CONSTRAINT ck_inv_reservation_line_qty CHECK (reserved_qty >= 0 AND consumed_qty >= 0
        AND released_qty >= 0 AND shortage_qty >= 0
        AND consumed_qty + released_qty <= reserved_qty)
);
ALTER TABLE inv_reservation_line ENABLE ROW LEVEL SECURITY;
ALTER TABLE inv_reservation_line FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON inv_reservation_line
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_inv_reservation_line_no ON inv_reservation_line (tenant_id, company_id, reservation_id, line_no);
CREATE INDEX idx_inv_reservation_line_mat
    ON inv_reservation_line (tenant_id, company_id, material_id, warehouse_id, batch_id);
CREATE INDEX idx_inv_reservation_line_reserved
    ON inv_reservation_line (tenant_id, company_id, warehouse_id, material_id) WHERE reserved_qty > 0;
COMMENT ON TABLE inv_reservation_line IS '库存预留明细（倉庫×物料×批次）。残予約 = reserved - consumed - released';

-- inv_cost_layer（90-db-design.md:1186）
CREATE TABLE inv_cost_layer (
    id                BIGINT        NOT NULL,
    tenant_id         BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id      BIGINT        NOT NULL,
    layer_type        SMALLINT      NOT NULL DEFAULT 10,  -- 10入庫層/20原価調整層/30期初層
    warehouse_id      BIGINT        NOT NULL,
    material_id       BIGINT        NOT NULL,
    batch_id          BIGINT        NOT NULL DEFAULT 0,
    batch_no          VARCHAR(64)   NOT NULL DEFAULT '',
    source_txn_id     BIGINT,
    source_txn_line_id BIGINT,
    source_adjustment_line_id BIGINT,
    received_date     DATE          NOT NULL,
    inbound_qty       NUMERIC(18,4) NOT NULL,
    purchase_amount   NUMERIC(18,2) NOT NULL DEFAULT 0,
    freight_amount    NUMERIC(18,2) NOT NULL DEFAULT 0,
    duty_amount       NUMERIC(18,2) NOT NULL DEFAULT 0,
    other_amount      NUMERIC(18,2) NOT NULL DEFAULT 0,
    inbound_amount    NUMERIC(18,2) NOT NULL,
    inbound_unit_cost NUMERIC(18,6) NOT NULL,
    remaining_qty     NUMERIC(18,4) NOT NULL,
    remaining_amount  NUMERIC(18,2) NOT NULL,
    layer_status      SMALLINT      NOT NULL DEFAULT 10,  -- 10残存/40枯渇/90沖销
    remark            VARCHAR(200),
    version           INT           NOT NULL DEFAULT 0,
    created_at        TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by        BIGINT        NOT NULL DEFAULT 0,
    updated_at        TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by        BIGINT        NOT NULL DEFAULT 0,
    CONSTRAINT pk_inv_cost_layer PRIMARY KEY (id),
    CONSTRAINT ck_inv_cost_layer_type CHECK (layer_type IN (10,20,30)),
    CONSTRAINT ck_inv_cost_layer_status CHECK (layer_status IN (10,40,90)),
    CONSTRAINT ck_inv_cost_layer_qty CHECK (inbound_qty > 0 AND remaining_qty >= 0
        AND remaining_qty <= inbound_qty),
    CONSTRAINT ck_inv_cost_layer_amount CHECK (inbound_amount >= 0 AND remaining_amount >= 0)
);
ALTER TABLE inv_cost_layer ENABLE ROW LEVEL SECURITY;
ALTER TABLE inv_cost_layer FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON inv_cost_layer
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE INDEX idx_inv_cost_layer_group
    ON inv_cost_layer (tenant_id, company_id, warehouse_id, material_id, batch_id, received_date);
CREATE INDEX idx_inv_cost_layer_remaining
    ON inv_cost_layer (tenant_id, company_id, warehouse_id, material_id, batch_id, received_date)
    WHERE remaining_qty > 0 AND layer_status = 10;
CREATE INDEX idx_inv_cost_layer_txn ON inv_cost_layer (tenant_id, company_id, source_txn_line_id);
COMMENT ON TABLE inv_cost_layer IS '成本层（入庫原価構成・残数量・残金額）。移動平均の主体ではなく、庫齢・原価追跡・調整按分の基礎';
COMMENT ON COLUMN inv_cost_layer.remaining_amount IS 'Σ remaining_amount（cost group）= inv_stock_balance.amount_on_hand（日次対账）';

-- inv_cost_adjustment（90-db-design.md:1245）
CREATE TABLE inv_cost_adjustment (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id      BIGINT        NOT NULL,
    adjustment_no       VARCHAR(32)   NOT NULL,          -- CA + YYMMDD + 4桁（08 §2.1）
    adjustment_type     SMALLINT      NOT NULL DEFAULT 10, -- 10暂估差异/20运费差异/30关税差异/40价格调整/50期間再計算
    adjustment_date     DATE          NOT NULL,
    period_code         VARCHAR(7)    NOT NULL,
    source_type         VARCHAR(32)   NOT NULL,          -- PURCHASE_INVOICE/PURCHASE_RECEIPT/FINISHED_COST/MANUAL/RECALC
    source_id           BIGINT,
    source_no           VARCHAR(32),
    adjustment_status   SMALLINT      NOT NULL DEFAULT 10, -- 10草稿/20承認待ち/25承認済/30已确定/90已冲销
    total_adjust_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
    reason              VARCHAR(500)  NOT NULL,
    approved_at         TIMESTAMPTZ,
    approved_by         BIGINT,
    posted_at           TIMESTAMPTZ,
    posted_by           BIGINT,
    reversal_of_adjustment_id BIGINT,
    version             INT           NOT NULL DEFAULT 0,
    remark              VARCHAR(500),
    ext_data            JSONB,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    CONSTRAINT pk_inv_cost_adjustment PRIMARY KEY (id),
    CONSTRAINT uk_inv_cost_adjustment_tenant_company_id UNIQUE (tenant_id, company_id, id),  -- 同域複合 FK の被参照キー（業務一意キーではない、#43）
    CONSTRAINT ck_inv_cost_adjustment_type CHECK (adjustment_type IN (10,20,30,40,50)),
    CONSTRAINT ck_inv_cost_adjustment_status CHECK (adjustment_status IN (10,20,25,30,90)),
    CONSTRAINT ck_inv_cost_adjustment_source CHECK (source_type IN ('PURCHASE_INVOICE','PURCHASE_RECEIPT','FINISHED_COST','MANUAL','RECALC')),
    CONSTRAINT ck_inv_cost_adjustment_period CHECK (period_code ~ '^[0-9]{4}-[0-9]{2}$')
);
ALTER TABLE inv_cost_adjustment ENABLE ROW LEVEL SECURITY;
ALTER TABLE inv_cost_adjustment FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON inv_cost_adjustment
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_inv_cost_adjustment_no ON inv_cost_adjustment (tenant_id, company_id, adjustment_no);
CREATE INDEX idx_inv_cost_adjustment_period
    ON inv_cost_adjustment (tenant_id, company_id, period_code, adjustment_status);
CREATE INDEX idx_inv_cost_adjustment_source
    ON inv_cost_adjustment (tenant_id, company_id, source_type, source_no);
COMMENT ON TABLE inv_cost_adjustment IS '原価調整単（価格差異・運費差異・期間再計算）。数量は変えず金額のみ更新し E19 を発行';

-- inv_cost_adjustment_line（90-db-design.md:1293）
CREATE TABLE inv_cost_adjustment_line (
    id                    BIGINT        NOT NULL,
    tenant_id             BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id      BIGINT        NOT NULL,
    adjustment_id         BIGINT        NOT NULL,
    line_no               INT           NOT NULL,
    material_id           BIGINT        NOT NULL,
    warehouse_id          BIGINT        NOT NULL,
    batch_id              BIGINT        NOT NULL DEFAULT 0,
    batch_no              VARCHAR(64)   NOT NULL DEFAULT '',
    target_qty            NUMERIC(18,4) NOT NULL,
    old_unit_price        NUMERIC(18,6) NOT NULL DEFAULT 0,
    new_unit_price        NUMERIC(18,6) NOT NULL DEFAULT 0,
    diff_unit_price       NUMERIC(18,6) NOT NULL DEFAULT 0,
    diff_amount           NUMERIC(18,2) NOT NULL DEFAULT 0,
    remaining_qty         NUMERIC(18,4) NOT NULL DEFAULT 0,
    issued_qty            NUMERIC(18,4) NOT NULL DEFAULT 0,
    inventory_adjust_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
    issued_adjust_amount  NUMERIC(18,2) NOT NULL DEFAULT 0,
    old_avg_cost          NUMERIC(18,6) NOT NULL DEFAULT 0,
    new_avg_cost          NUMERIC(18,6) NOT NULL DEFAULT 0,
    remark                VARCHAR(200),
    created_at            TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by            BIGINT        NOT NULL DEFAULT 0,
    CONSTRAINT pk_inv_cost_adjustment_line PRIMARY KEY (id),
    CONSTRAINT fk_inv_cost_adjustment_line_head FOREIGN KEY (tenant_id, company_id, adjustment_id) REFERENCES inv_cost_adjustment (tenant_id, company_id, id),
    CONSTRAINT ck_inv_cost_adjustment_line_qty CHECK (target_qty > 0 AND remaining_qty >= 0 AND issued_qty >= 0)
);
ALTER TABLE inv_cost_adjustment_line ENABLE ROW LEVEL SECURITY;
ALTER TABLE inv_cost_adjustment_line FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON inv_cost_adjustment_line
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_inv_cost_adjustment_line_no ON inv_cost_adjustment_line (tenant_id, company_id, adjustment_id, line_no);
CREATE INDEX idx_inv_cost_adjustment_line_group
    ON inv_cost_adjustment_line (tenant_id, company_id, material_id, warehouse_id, batch_id);
COMMENT ON TABLE inv_cost_adjustment_line IS '原価調整明細。在庫分と既出庫分（当期費用）の配分を保持（05 §2.4）';

-- inv_period（90-db-design.md:1338）
CREATE TABLE inv_period (
    id               BIGINT       NOT NULL,
    tenant_id        BIGINT       NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id      BIGINT        NOT NULL,
    period_code      VARCHAR(7)   NOT NULL,
    period_start_date DATE        NOT NULL,
    period_end_date  DATE         NOT NULL,
    period_status    SMALLINT     NOT NULL DEFAULT 10, -- 10未开始/20开放/40已关账/90已年结
    closed_at        TIMESTAMPTZ,
    closed_by        BIGINT,
    check_result     JSONB,                            -- 月结前置检查結果
    summary_count    INT          NOT NULL DEFAULT 0,  -- 收发存汇总件数
    recalc_result    JSONB,                            -- 期間再計算結果
    recalc_lock      BOOLEAN      NOT NULL DEFAULT FALSE,
    reopened_at      TIMESTAMPTZ,
    reopened_by      BIGINT,
    reopen_reason    VARCHAR(500),
    version          INT          NOT NULL DEFAULT 0,
    remark           VARCHAR(500),
    created_at       TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_by       BIGINT       NOT NULL DEFAULT 0,
    updated_at       TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_by       BIGINT       NOT NULL DEFAULT 0,
    CONSTRAINT pk_inv_period PRIMARY KEY (id),
    CONSTRAINT ck_inv_period_code CHECK (period_code ~ '^[0-9]{4}-[0-9]{2}$'),
    CONSTRAINT ck_inv_period_status CHECK (period_status IN (10,20,40,90)),
    CONSTRAINT ck_inv_period_date CHECK (period_start_date <= period_end_date)
);
ALTER TABLE inv_period ENABLE ROW LEVEL SECURITY;
ALTER TABLE inv_period FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON inv_period
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_inv_period_code ON inv_period (tenant_id, company_id, period_code);
COMMENT ON TABLE inv_period IS '库存期间（月次）。FIN の fin_period と順序制御（在庫月结→原価→FIN 关账）';
COMMENT ON COLUMN inv_period.recalc_lock IS '期間再計算の実行中フラグ。過账時にチェックしてブロック';

-- inv_stock_summary（90-db-design.md:1385）
CREATE TABLE inv_stock_summary (
    id              BIGINT        NOT NULL,
    tenant_id       BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id      BIGINT        NOT NULL,
    period_code     VARCHAR(7)    NOT NULL,
    warehouse_id    BIGINT        NOT NULL,
    material_id     BIGINT        NOT NULL,
    uom_code        VARCHAR(16)   NOT NULL,
    opening_qty     NUMERIC(18,4) NOT NULL DEFAULT 0,
    opening_amount  NUMERIC(18,2) NOT NULL DEFAULT 0,
    in_qty          NUMERIC(18,4) NOT NULL DEFAULT 0,
    in_amount       NUMERIC(18,2) NOT NULL DEFAULT 0,
    out_qty         NUMERIC(18,4) NOT NULL DEFAULT 0,
    out_amount      NUMERIC(18,2) NOT NULL DEFAULT 0,
    closing_qty     NUMERIC(18,4) NOT NULL DEFAULT 0,
    closing_amount  NUMERIC(18,2) NOT NULL DEFAULT 0,
    avg_unit_cost   NUMERIC(18,6) NOT NULL DEFAULT 0,
    turnover_rate   NUMERIC(12,4),
    generated_at    TIMESTAMPTZ   NOT NULL DEFAULT now(),
    generated_by    BIGINT        NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by      BIGINT        NOT NULL DEFAULT 0,
    updated_at      TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by      BIGINT        NOT NULL DEFAULT 0,
    CONSTRAINT ck_inv_stock_summary_amount CHECK (opening_amount >= 0 AND in_amount >= 0 AND out_amount >= 0 AND closing_amount >= 0),
    CONSTRAINT ck_inv_stock_summary_period CHECK (period_code ~ '^[0-9]{4}-[0-9]{2}$'),
    CONSTRAINT pk_inv_stock_summary PRIMARY KEY (id),
    CONSTRAINT ck_inv_stock_summary_balance CHECK (closing_qty = opening_qty + in_qty - out_qty)
);
ALTER TABLE inv_stock_summary ENABLE ROW LEVEL SECURITY;
ALTER TABLE inv_stock_summary FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON inv_stock_summary
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_inv_stock_summary_key
    ON inv_stock_summary (tenant_id, company_id, period_code, warehouse_id, material_id);
CREATE INDEX idx_inv_stock_summary_period ON inv_stock_summary (tenant_id, company_id, period_code);
COMMENT ON TABLE inv_stock_summary IS '月次收发存汇总。期初＋入庫−出庫＝期末（DB CHECK）';

-- inv_age_snapshot（90-db-design.md:1427）
CREATE TABLE inv_age_snapshot (
    id             BIGINT        NOT NULL,
    tenant_id      BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id      BIGINT        NOT NULL,
    snapshot_date  DATE          NOT NULL,
    warehouse_id   BIGINT        NOT NULL,
    material_id    BIGINT        NOT NULL,
    batch_id       BIGINT        NOT NULL DEFAULT 0,
    batch_no       VARCHAR(64)   NOT NULL DEFAULT '',
    received_date  DATE          NOT NULL,
    age_days       INT           NOT NULL,
    age_bucket     VARCHAR(16)   NOT NULL,        -- 0-30/31-60/61-90/91-180/181-365/366-
    qty            NUMERIC(18,4) NOT NULL DEFAULT 0,
    amount         NUMERIC(18,2) NOT NULL DEFAULT 0,
    is_slow_moving BOOLEAN       NOT NULL DEFAULT FALSE,
    generated_at   TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_at     TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by     BIGINT        NOT NULL DEFAULT 0,
    updated_at     TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by     BIGINT        NOT NULL DEFAULT 0,
    CONSTRAINT ck_inv_age_snapshot_bucket CHECK (age_bucket IN ('0-30','31-60','61-90','91-180','181-365','366-')),
    CONSTRAINT pk_inv_age_snapshot PRIMARY KEY (id),
    CONSTRAINT ck_inv_age_snapshot_days CHECK (age_days >= 0),
    CONSTRAINT ck_inv_age_snapshot_qty CHECK (qty >= 0)
);
ALTER TABLE inv_age_snapshot ENABLE ROW LEVEL SECURITY;
ALTER TABLE inv_age_snapshot FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON inv_age_snapshot
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_inv_age_snapshot_key
    ON inv_age_snapshot (tenant_id, company_id, snapshot_date, warehouse_id, material_id, batch_id, received_date, age_bucket);
CREATE INDEX idx_inv_age_snapshot_date ON inv_age_snapshot (tenant_id, company_id, snapshot_date DESC);
CREATE INDEX idx_inv_age_snapshot_slow
    ON inv_age_snapshot (tenant_id, company_id, snapshot_date) WHERE is_slow_moving = TRUE;
COMMENT ON TABLE inv_age_snapshot IS '日次庫齢スナップショット（BAT-INV-003）。過去日の庫齢は本表を正とする';

-- inv_replenishment（90-db-design.md:1465）
CREATE TABLE inv_replenishment (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id      BIGINT        NOT NULL,
    as_of_date          DATE          NOT NULL,
    warehouse_id        BIGINT        NOT NULL,
    material_id         BIGINT        NOT NULL,
    uom_code            VARCHAR(16)   NOT NULL,
    available_qty       NUMERIC(18,4) NOT NULL DEFAULT 0,
    on_order_qty        NUMERIC(18,4) NOT NULL DEFAULT 0,
    safety_stock        NUMERIC(18,4) NOT NULL DEFAULT 0,
    avg_daily_usage     NUMERIC(18,4) NOT NULL DEFAULT 0,
    lead_time_days      INT           NOT NULL DEFAULT 0,
    reorder_point       NUMERIC(18,4) NOT NULL DEFAULT 0,
    suggested_qty       NUMERIC(18,4) NOT NULL DEFAULT 0,
    suggested_order_date DATE,
    is_shortage         BOOLEAN       NOT NULL DEFAULT FALSE,
    replenishment_status SMALLINT     NOT NULL DEFAULT 10, -- 10建議/30已转请购/40已忽略
    purchase_request_no VARCHAR(32),
    ignored_reason      VARCHAR(500),
    generated_at        TIMESTAMPTZ   NOT NULL DEFAULT now(),
    version             INT           NOT NULL DEFAULT 0,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    CONSTRAINT pk_inv_replenishment PRIMARY KEY (id),
    CONSTRAINT ck_inv_replenishment_status CHECK (replenishment_status IN (10,30,40)),
    CONSTRAINT ck_inv_replenishment_qty CHECK (available_qty >= 0 AND on_order_qty >= 0
        AND safety_stock >= 0 AND avg_daily_usage >= 0 AND suggested_qty >= 0)
);
ALTER TABLE inv_replenishment ENABLE ROW LEVEL SECURITY;
ALTER TABLE inv_replenishment FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON inv_replenishment
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_inv_replenishment_key
    ON inv_replenishment (tenant_id, company_id, as_of_date, warehouse_id, material_id);
CREATE INDEX idx_inv_replenishment_status
    ON inv_replenishment (tenant_id, company_id, as_of_date, replenishment_status);
CREATE INDEX idx_inv_replenishment_shortage
    ON inv_replenishment (tenant_id, company_id, as_of_date) WHERE is_shortage = TRUE;
COMMENT ON TABLE inv_replenishment IS '補貨建議（BAT-INV-004）。発注点・推奨発注量。PUR の計画採購が参照';

-- inv_scan_log（90-db-design.md:1517）
CREATE TABLE inv_scan_log (
    id            BIGINT       NOT NULL,
    tenant_id     BIGINT       NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id      BIGINT        NOT NULL,
    device_id     VARCHAR(64)  NOT NULL,
    local_seq     BIGINT,                       -- PDA ローカル連番（冪等キー）
    session_id    VARCHAR(64)  NOT NULL,
    user_id       BIGINT       NOT NULL,
    scan_at       TIMESTAMPTZ  NOT NULL,
    work_type     SMALLINT     NOT NULL,        -- 10入庫/20出庫/30移庫/40棚卸/50状態変換/60照会
    scan_result   SMALLINT     NOT NULL,        -- 1成功/0失敗
    barcode_type  SMALLINT,                     -- 10物料/20批次/30序列号/40库位/50单据
    barcode_value VARCHAR(128) NOT NULL,
    material_id   BIGINT,
    batch_id      BIGINT,
    batch_no      VARCHAR(64),
    serial_no     VARCHAR(64),
    location_id   BIGINT,
    warehouse_id  BIGINT,
    biz_type      VARCHAR(32),
    biz_id        BIGINT,
    error_code    VARCHAR(32),
    error_message VARCHAR(500),
    offline_flag  BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_by    BIGINT       NOT NULL DEFAULT 0,
    CONSTRAINT pk_inv_scan_log PRIMARY KEY (id),
    CONSTRAINT ck_inv_scan_log_result CHECK (scan_result IN (0,1)),
    CONSTRAINT ck_inv_scan_log_work CHECK (work_type IN (10,20,30,40,50,60)),
    CONSTRAINT ck_inv_scan_log_barcode CHECK (barcode_type IS NULL OR barcode_type IN (10,20,30,40,50))
);
ALTER TABLE inv_scan_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE inv_scan_log FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON inv_scan_log
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_inv_scan_log_device_seq
    ON inv_scan_log (tenant_id, company_id, device_id, local_seq) WHERE local_seq IS NOT NULL;
CREATE INDEX idx_inv_scan_log_time ON inv_scan_log (tenant_id, company_id, scan_at DESC);
CREATE INDEX idx_inv_scan_log_barcode ON inv_scan_log (tenant_id, company_id, barcode_value);
CREATE INDEX idx_inv_scan_log_biz ON inv_scan_log (tenant_id, company_id, biz_type, biz_id);
COMMENT ON TABLE inv_scan_log IS 'PDA スキャン記録（成功・失敗の全件）。二重送信排除と異常追跡';

-- inv_event_wait（90-db-design.md:1570）
CREATE TABLE inv_event_wait (
    id              BIGINT        NOT NULL,
    tenant_id       BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id      BIGINT        NOT NULL,
    event_id        UUID          NOT NULL,           -- 受信イベント ID（冪等キー）
    event_type      VARCHAR(100)  NOT NULL,           -- quality.inspection.completed
    source_type     VARCHAR(32)   NOT NULL,           -- PURCHASE_RECEIPT / INSPECTION
    source_id       BIGINT        NOT NULL,           -- inspectionId / receiptId / workOrderId
    source_no       VARCHAR(32),
    warehouse_id    BIGINT        NOT NULL,
    waiting_for     VARCHAR(16)   NOT NULL,           -- PI / FGI / OSR
    payload         JSONB         NOT NULL,           -- E15 全ペイロード
    wait_status     SMALLINT      NOT NULL DEFAULT 0, -- 0待機 / 1適用済 / 9放棄
    retry_count     INT           NOT NULL DEFAULT 0,
    next_retry_at   TIMESTAMPTZ,
    applied_txn_id  BIGINT,
    last_error      VARCHAR(1000),
    version         INT           NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by      BIGINT        NOT NULL DEFAULT 0,
    updated_at      TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by      BIGINT        NOT NULL DEFAULT 0,
    CONSTRAINT pk_inv_event_wait PRIMARY KEY (id),
    CONSTRAINT ck_inv_event_wait_status CHECK (wait_status IN (0,1,9)),
    CONSTRAINT ck_inv_event_wait_for CHECK (waiting_for IN ('PI','FGI','OSR')),
    CONSTRAINT ck_inv_event_wait_source CHECK (source_type IN ('PURCHASE_RECEIPT','PRODUCTION_COMPLETION','OUTSOURCING_ORDER','INSPECTION'))
);
ALTER TABLE inv_event_wait ENABLE ROW LEVEL SECURITY;
ALTER TABLE inv_event_wait FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON inv_event_wait
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_inv_event_wait_event ON inv_event_wait (tenant_id, company_id, event_id);
CREATE INDEX idx_inv_event_wait_pending ON inv_event_wait (tenant_id, company_id, wait_status, next_retry_at) WHERE wait_status = 0;
CREATE INDEX idx_inv_event_wait_source ON inv_event_wait (tenant_id, company_id, source_type, source_id);
CREATE INDEX idx_inv_event_wait_expire ON inv_event_wait (tenant_id, company_id, created_at) WHERE wait_status = 0;
COMMENT ON TABLE inv_event_wait IS '品質イベント保留（E15 先着時の待合せ）。09 §8 の sys_event_wait 相当';
COMMENT ON COLUMN inv_event_wait.waiting_for IS 'PI=入荷待ち、FGI=完工入庫待ち、OSR=委外受入待ち';

-- 跨域 mdm 复合 FK（§6.3 #7〜11）：(tenant_id, x_id) → mdm_x (tenant_id, id)（uk_mdm_x_tenant_id，sys/V202610210707）。ON DELETE 不指定（NO ACTION）。
-- #7 另加 inv_stock_balance.material_id（蓝色大肥鱼 2026-10-21 决定，#55）。
-- #8 warehouse_id：除 §6.3 软引用表所列 inv_stock_txn.warehouse_id、inv_stock_balance.warehouse_id 外，凡含 warehouse_id 的表都加。
ALTER TABLE inv_stock_balance ADD CONSTRAINT fk_inv_stock_balance_material FOREIGN KEY (tenant_id, material_id) REFERENCES mdm_material (tenant_id, id);
ALTER TABLE inv_transfer_line ADD CONSTRAINT fk_inv_transfer_line_material FOREIGN KEY (tenant_id, material_id) REFERENCES mdm_material (tenant_id, id);
ALTER TABLE inv_stocktake_line ADD CONSTRAINT fk_inv_stocktake_line_material FOREIGN KEY (tenant_id, material_id) REFERENCES mdm_material (tenant_id, id);
ALTER TABLE inv_batch ADD CONSTRAINT fk_inv_batch_material FOREIGN KEY (tenant_id, material_id) REFERENCES mdm_material (tenant_id, id);
ALTER TABLE inv_serial ADD CONSTRAINT fk_inv_serial_material FOREIGN KEY (tenant_id, material_id) REFERENCES mdm_material (tenant_id, id);
ALTER TABLE inv_reservation_line ADD CONSTRAINT fk_inv_reservation_line_material FOREIGN KEY (tenant_id, material_id) REFERENCES mdm_material (tenant_id, id);
ALTER TABLE inv_cost_layer ADD CONSTRAINT fk_inv_cost_layer_material FOREIGN KEY (tenant_id, material_id) REFERENCES mdm_material (tenant_id, id);
ALTER TABLE inv_cost_adjustment_line ADD CONSTRAINT fk_inv_cost_adjustment_line_material FOREIGN KEY (tenant_id, material_id) REFERENCES mdm_material (tenant_id, id);
ALTER TABLE inv_stock_summary ADD CONSTRAINT fk_inv_stock_summary_material FOREIGN KEY (tenant_id, material_id) REFERENCES mdm_material (tenant_id, id);
ALTER TABLE inv_age_snapshot ADD CONSTRAINT fk_inv_age_snapshot_material FOREIGN KEY (tenant_id, material_id) REFERENCES mdm_material (tenant_id, id);
ALTER TABLE inv_replenishment ADD CONSTRAINT fk_inv_replenishment_material FOREIGN KEY (tenant_id, material_id) REFERENCES mdm_material (tenant_id, id);
ALTER TABLE inv_transfer ADD CONSTRAINT fk_inv_transfer_from_wh FOREIGN KEY (tenant_id, from_warehouse_id) REFERENCES mdm_warehouse (tenant_id, id);
ALTER TABLE inv_transfer ADD CONSTRAINT fk_inv_transfer_to_wh FOREIGN KEY (tenant_id, to_warehouse_id) REFERENCES mdm_warehouse (tenant_id, id);
ALTER TABLE inv_stocktake_plan ADD CONSTRAINT fk_inv_stocktake_plan_wh FOREIGN KEY (tenant_id, warehouse_id) REFERENCES mdm_warehouse (tenant_id, id);
ALTER TABLE inv_stocktake ADD CONSTRAINT fk_inv_stocktake_wh FOREIGN KEY (tenant_id, warehouse_id) REFERENCES mdm_warehouse (tenant_id, id);
ALTER TABLE inv_serial_txn ADD CONSTRAINT fk_inv_serial_txn_wh FOREIGN KEY (tenant_id, warehouse_id) REFERENCES mdm_warehouse (tenant_id, id);
ALTER TABLE inv_reservation_line ADD CONSTRAINT fk_inv_reservation_line_wh FOREIGN KEY (tenant_id, warehouse_id) REFERENCES mdm_warehouse (tenant_id, id);
ALTER TABLE inv_cost_layer ADD CONSTRAINT fk_inv_cost_layer_wh FOREIGN KEY (tenant_id, warehouse_id) REFERENCES mdm_warehouse (tenant_id, id);
ALTER TABLE inv_cost_adjustment_line ADD CONSTRAINT fk_inv_cost_adjustment_line_wh FOREIGN KEY (tenant_id, warehouse_id) REFERENCES mdm_warehouse (tenant_id, id);
ALTER TABLE inv_stock_summary ADD CONSTRAINT fk_inv_stock_summary_wh FOREIGN KEY (tenant_id, warehouse_id) REFERENCES mdm_warehouse (tenant_id, id);
ALTER TABLE inv_age_snapshot ADD CONSTRAINT fk_inv_age_snapshot_wh FOREIGN KEY (tenant_id, warehouse_id) REFERENCES mdm_warehouse (tenant_id, id);
ALTER TABLE inv_replenishment ADD CONSTRAINT fk_inv_replenishment_wh FOREIGN KEY (tenant_id, warehouse_id) REFERENCES mdm_warehouse (tenant_id, id);
ALTER TABLE inv_scan_log ADD CONSTRAINT fk_inv_scan_log_wh FOREIGN KEY (tenant_id, warehouse_id) REFERENCES mdm_warehouse (tenant_id, id);
ALTER TABLE inv_event_wait ADD CONSTRAINT fk_inv_event_wait_wh FOREIGN KEY (tenant_id, warehouse_id) REFERENCES mdm_warehouse (tenant_id, id);
ALTER TABLE inv_transfer ADD CONSTRAINT fk_inv_transfer_from_factory FOREIGN KEY (tenant_id, from_factory_id) REFERENCES mdm_factory (tenant_id, id);
ALTER TABLE inv_transfer ADD CONSTRAINT fk_inv_transfer_to_factory FOREIGN KEY (tenant_id, to_factory_id) REFERENCES mdm_factory (tenant_id, id);
ALTER TABLE inv_batch ADD CONSTRAINT fk_inv_batch_supplier FOREIGN KEY (tenant_id, supplier_id) REFERENCES mdm_supplier (tenant_id, id);
ALTER TABLE inv_serial ADD CONSTRAINT fk_inv_serial_customer FOREIGN KEY (tenant_id, customer_id) REFERENCES mdm_customer (tenant_id, id);
