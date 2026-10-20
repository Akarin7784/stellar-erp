-- 03-sales 全量建表（docs/design/03-sales/90-db-design.md §3，29 表）
-- 由设计书 DDL 机械转换：仅展开「共通カラム（§1.3）」并追加 RLS，不新增设计书之外的业务列。
-- 规则：tenant_id DEFAULT current_setting('app.tenant_id')::bigint（禁 DEFAULT 0）；company_id NOT NULL 无 DEFAULT；
--       明细表也冗余持有 company_id NOT NULL 无 DEFAULT（与 prd 一致；设计书 §1.3「明细省略」已由蓝色大肥鱼改定）；
--       全部业务 uk 以 (tenant_id, company_id, …) 打头（设计书 §9 的 12 个父 ID 打头例外已取消）；
--       ENABLE + FORCE RLS；erp_app 的 DML 权限由 V202610200101 的 ALTER DEFAULT PRIVILEGES 自动授予（设计书无列级授权）。
-- 设计书 §8 的 9 个文件（0301〜0309）按 #12 规则（当天全局 4 位序号）合并为本迁移。
-- 跨域引用（inv_/fin_/prd_ 等）设计书只在注释中给出，未声明 FK，本迁移不追加。


-- sal_inquiry（傳票ヘッダ）
CREATE TABLE sal_inquiry (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    remark              VARCHAR(500),
    ext_data            JSONB,
    inquiry_no          VARCHAR(32)  NOT NULL,                 -- 引合番号（INQ+YYMMDD+4桁）
    customer_id         BIGINT       NOT NULL,                 -- 顧客ID（mdm_customer.id）
    customer_code       VARCHAR(20)  NOT NULL,                 -- 顧客コード（スナップショット）
    customer_name       VARCHAR(200) NOT NULL,                 -- 顧客名（スナップショット）
    contact_name        VARCHAR(50),                           -- 連絡先氏名（マスキング対象）
    contact_phone       VARCHAR(30),                           -- 連絡先電話（マスキング対象）
    inquiry_date        DATE         NOT NULL,                 -- 引合日
    inquiry_source      SMALLINT     NOT NULL DEFAULT 10,      -- 引合区分（10電話/20メール/30訪問/40既存取引/50その他）
    required_date       DATE,                                  -- 希望納期
    owner_user_id       BIGINT       NOT NULL,                 -- 営業担当（sys_user.id）
    sales_department_id BIGINT       NOT NULL,                 -- 販売部門（sys_department.id）
    inquiry_status      SMALLINT     NOT NULL DEFAULT 10,      -- 状態（10起票中/30回答済/40見積作成済/90取消）
    answered_at         DATE,                                  -- 回答日
    answer_note         VARCHAR(1000),                         -- 回答内容
    quotation_id        BIGINT,                                -- 見積ID（論理参照）
    CONSTRAINT pk_sal_inquiry PRIMARY KEY (id),
    CONSTRAINT fk_sal_inquiry_customer FOREIGN KEY (customer_id) REFERENCES mdm_customer (id)
);
ALTER TABLE sal_inquiry ENABLE ROW LEVEL SECURITY;
ALTER TABLE sal_inquiry FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sal_inquiry
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_sal_inquiry_no ON sal_inquiry (tenant_id, company_id, inquiry_no);
CREATE INDEX idx_sal_inquiry_customer ON sal_inquiry (customer_id, inquiry_date DESC);
CREATE INDEX idx_sal_inquiry_owner_status ON sal_inquiry (owner_user_id, inquiry_status);
CREATE INDEX idx_sal_inquiry_date ON sal_inquiry (inquiry_date DESC);

-- sal_inquiry_line（傳票明細）
CREATE TABLE sal_inquiry_line (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    remark              VARCHAR(500),
    ext_data            JSONB,
    inquiry_id          BIGINT       NOT NULL,                 -- 親（sal_inquiry.id）
    line_no             INT          NOT NULL,                 -- 行番号（10刻み）
    material_id         BIGINT       NOT NULL,                 -- 物料ID（mdm_material.id）
    material_code       VARCHAR(20)  NOT NULL,                 -- 物料コード（スナップショット）
    material_name       VARCHAR(200) NOT NULL,                 -- 品名（スナップショット）
    spec                VARCHAR(500),                          -- 仕様・要求
    qty            NUMERIC(18,4) NOT NULL,                -- 希望数量
    uom_code            VARCHAR(10)  NOT NULL,                 -- 単位（mdm_uom.uom_code）
    required_date       DATE,                                  -- 希望納期
    customer_material_no VARCHAR(100),                         -- 顧客品番
    line_remark         VARCHAR(500),                          -- 明細備考
    CONSTRAINT pk_sal_inquiry_line PRIMARY KEY (id),
    CONSTRAINT fk_sal_inquiry_line_inquiry FOREIGN KEY (inquiry_id) REFERENCES sal_inquiry (id),
    CONSTRAINT fk_sal_inquiry_line_material FOREIGN KEY (material_id) REFERENCES mdm_material (id),
    CONSTRAINT ck_sal_inquiry_line_qty CHECK (qty > 0)
);
ALTER TABLE sal_inquiry_line ENABLE ROW LEVEL SECURITY;
ALTER TABLE sal_inquiry_line FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sal_inquiry_line
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_sal_inquiry_line_no ON sal_inquiry_line (tenant_id, company_id, inquiry_id, line_no);
CREATE INDEX idx_sal_inquiry_line_material ON sal_inquiry_line (material_id);

-- sal_quotation（傳票ヘッダ）
CREATE TABLE sal_quotation (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    remark              VARCHAR(500),
    ext_data            JSONB,
    quotation_no        VARCHAR(32)  NOT NULL,                 -- 見積番号（QT+YYMMDD+4桁）
    revision_no         INT          NOT NULL DEFAULT 1,       -- 版数（改訂で+1）
    inquiry_id          BIGINT,                                -- 引合ID（sal_inquiry.id）
    customer_id         BIGINT       NOT NULL,                 -- 顧客ID
    customer_code       VARCHAR(20)  NOT NULL,                 -- 顧客コード
    customer_name       VARCHAR(200) NOT NULL,                 -- 顧客名
    customer_tax_no     VARCHAR(30),                           -- 顧客税号（スナップショット）
    delivery_address    VARCHAR(500) NOT NULL,                 -- 納品先住所
    owner_user_id       BIGINT       NOT NULL,                 -- 営業担当
    sales_department_id BIGINT       NOT NULL,                 -- 販売部門
    issue_date          DATE         NOT NULL,                 -- 発行日
    valid_from          DATE         NOT NULL,                 -- 有効期限開始日
    valid_to            DATE         NOT NULL,                 -- 有効期限終了日
    currency_code       VARCHAR(3)   NOT NULL DEFAULT 'CNY',   -- 通貨（ISO 4217）
    exchange_rate       NUMERIC(18,8) NOT NULL DEFAULT 1,      -- 為替レート
    price_list_id       BIGINT,                                -- 価格表（mdm_price_list.id）
    payment_term_code   VARCHAR(20)  NOT NULL,                 -- 付款条件（mdm_payment_term.payment_term_code）
    settlement_method_code VARCHAR(20),                        -- 決済方法
    quotation_status    SMALLINT     NOT NULL DEFAULT 10,      -- 状態（10作成中/25承認待ち/30有効/35已转订单/90失效/95却下）
    approval_status     SMALLINT     NOT NULL DEFAULT 10,      -- 承認状態（10不要/20承認待ち/25承認済）
    approval_required   BOOLEAN      NOT NULL DEFAULT FALSE,   -- 承認要否
    approved_at         TIMESTAMPTZ,                            -- 承認日時
    approved_by         BIGINT,                                 -- 承認者
    sent_at             TIMESTAMPTZ,                            -- 顧客送付日時
    converted_at        TIMESTAMPTZ,                            -- 受注転換日時
    invalidated_at      TIMESTAMPTZ,                            -- 失効日時
    total_qty           NUMERIC(18,4) NOT NULL DEFAULT 0,      -- 数量合計
    total_amount        NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 税抜合計
    tax_amount          NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 税額合計
    grand_total         NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 税込合計
    CONSTRAINT pk_sal_quotation PRIMARY KEY (id),
    CONSTRAINT fk_sal_quotation_customer FOREIGN KEY (customer_id) REFERENCES mdm_customer (id),
    CONSTRAINT fk_sal_quotation_inquiry FOREIGN KEY (inquiry_id) REFERENCES sal_inquiry (id)
);
ALTER TABLE sal_quotation ENABLE ROW LEVEL SECURITY;
ALTER TABLE sal_quotation FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sal_quotation
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_sal_quotation_no ON sal_quotation (tenant_id, company_id, quotation_no);
CREATE INDEX idx_sal_quotation_status_valid ON sal_quotation (quotation_status, valid_to);
CREATE INDEX idx_sal_quotation_customer ON sal_quotation (customer_id, issue_date DESC);
CREATE INDEX idx_sal_quotation_owner ON sal_quotation (owner_user_id, quotation_status);
CREATE INDEX idx_sal_quotation_inquiry ON sal_quotation (inquiry_id);

-- sal_quotation_line（傳票明細）
CREATE TABLE sal_quotation_line (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    remark              VARCHAR(500),
    ext_data            JSONB,
    quotation_id        BIGINT       NOT NULL,                 -- 親
    line_no             INT          NOT NULL,                 -- 行番号
    material_id         BIGINT       NOT NULL,                 -- 物料ID
    material_code       VARCHAR(20)  NOT NULL,                 -- 物料コード
    material_name       VARCHAR(200) NOT NULL,                 -- 品名
    spec                VARCHAR(200),                          -- 仕様
    qty            NUMERIC(18,4) NOT NULL,                -- 見積数量
    uom_code            VARCHAR(10)  NOT NULL,                 -- 単位
    base_uom_code       VARCHAR(10)  NOT NULL,                 -- 基本単位
    conversion_rate     NUMERIC(18,8) NOT NULL DEFAULT 1,      -- 単位換算率
    list_price          NUMERIC(18,6),                         -- 標準価格（税抜）
    unit_price          NUMERIC(18,6) NOT NULL,                -- 見積単価（税抜）
    price_source        SMALLINT     NOT NULL DEFAULT 50,      -- 取価区分（10特価/20顧客物料/30顧客分類/40物料/50標準/90手動）
    price_list_line_id  BIGINT,                                -- 価格表行ID
    special_price_id    BIGINT,                                -- 特価ID
    discount_rate       NUMERIC(7,4) NOT NULL DEFAULT 0,       -- 折扣率（%）
    tax_code            VARCHAR(20)  NOT NULL,                 -- 税コード（VAT13-OUT 等）
    tax_rate            NUMERIC(7,4) NOT NULL DEFAULT 13,      -- 税率（%）
    line_amount         NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 税抜金額
    tax_amount          NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 税額
    total_amount        NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 税込金額
    delivery_date       DATE,                                  -- 回答納期
    converted_qty       NUMERIC(18,4) NOT NULL DEFAULT 0,      -- 受注転換済数量
    line_remark         VARCHAR(500),                          -- 明細備考
    CONSTRAINT pk_sal_quotation_line PRIMARY KEY (id),
    CONSTRAINT fk_sal_quotation_line_q FOREIGN KEY (quotation_id) REFERENCES sal_quotation (id),
    CONSTRAINT ck_sal_quotation_line_qty CHECK (qty > 0 AND converted_qty >= 0),
    CONSTRAINT ck_sal_quotation_line_price CHECK (unit_price >= 0)
);
ALTER TABLE sal_quotation_line ENABLE ROW LEVEL SECURITY;
ALTER TABLE sal_quotation_line FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sal_quotation_line
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_sal_quotation_line_no ON sal_quotation_line (tenant_id, company_id, quotation_id, line_no);
CREATE INDEX idx_sal_quotation_line_material ON sal_quotation_line (material_id);

-- sal_quotation_version（履歴）
CREATE TABLE sal_quotation_version (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    remark              VARCHAR(500),
    ext_data            JSONB,
    quotation_id        BIGINT       NOT NULL,                 -- 親
    revision_no         INT          NOT NULL,                 -- 版数
    version_status      SMALLINT     NOT NULL DEFAULT 10,      -- 版状態（10作成中/30発行済/90無効）
    valid_from          DATE,                                  -- 版の有効開始日
    valid_to            DATE,                                  -- 版の有効終了日
    total_amount        NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 税抜合計
    tax_amount          NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 税額合計
    grand_total         NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 税込合計
    snapshot            JSONB        NOT NULL,                 -- ヘッダ+明細スナップショット
    change_reason       VARCHAR(500),                          -- 改訂理由
    created_by_name     VARCHAR(64),                           -- 作成者名（スナップショット）
    approved_at         TIMESTAMPTZ,                            -- 承認日時
    CONSTRAINT pk_sal_quotation_version PRIMARY KEY (id),
    CONSTRAINT fk_sal_quotation_version_q FOREIGN KEY (quotation_id) REFERENCES sal_quotation (id)
);
ALTER TABLE sal_quotation_version ENABLE ROW LEVEL SECURITY;
ALTER TABLE sal_quotation_version FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sal_quotation_version
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_sal_quotation_version_rev ON sal_quotation_version (tenant_id, company_id, quotation_id, revision_no);

-- sal_sales_order（傳票ヘッダ）
CREATE TABLE sal_sales_order (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    remark              VARCHAR(500),
    ext_data            JSONB,
    sales_order_no      VARCHAR(32)  NOT NULL,                 -- 受注番号（SO+YYMMDD+4桁）
    order_type          SMALLINT     NOT NULL DEFAULT 10,      -- 受注区分（10標準/20備貨/30出口/40換貨/50サンプル）
    order_date          DATE         NOT NULL,                 -- 受注日
    customer_id         BIGINT       NOT NULL,                 -- 顧客ID
    customer_code       VARCHAR(20)  NOT NULL,                 -- 顧客コード
    customer_name       VARCHAR(200) NOT NULL,                 -- 顧客名
    customer_tax_no     VARCHAR(30),                           -- 顧客税号
    contact_name        VARCHAR(50),                           -- 連絡先
    contact_phone       VARCHAR(30),                           -- 連絡先電話
    delivery_address    VARCHAR(500) NOT NULL,                 -- 納品先住所
    sales_department_id BIGINT       NOT NULL,                 -- 販売部門
    owner_user_id       BIGINT       NOT NULL,                 -- 営業担当
    currency_code       VARCHAR(3)   NOT NULL DEFAULT 'CNY',   -- 通貨
    exchange_rate       NUMERIC(18,8) NOT NULL DEFAULT 1,      -- 為替レート
    price_list_id       BIGINT,                                -- 価格表
    payment_term_code   VARCHAR(20)  NOT NULL,                 -- 付款条件
    settlement_method_code VARCHAR(20),                        -- 決済方法
    delivery_date       DATE         NOT NULL,                 -- 最終納期
    warehouse_id        BIGINT       NOT NULL,                 -- 出荷倉庫（既定）
    invoice_type        SMALLINT,                              -- 発票種別（10専票/20普票/30数電専票/40数電普票）
    invoice_title       VARCHAR(200),                          -- 発票抬頭
    order_status        SMALLINT     NOT NULL DEFAULT 10,      -- 状態（10草稿/20承認待ち/25承認済/30引当済/35一部出荷/40完了/90取消/95却下）
    version_no          INT          NOT NULL DEFAULT 1,       -- 業務版数（変更で+1）
    credit_check_result SMALLINT,                              -- 与信判定（10正常/20注意/30超限審査中/40超限承認済/90凍結・閉鎖）
    credit_used_amount  NUMERIC(18,2),                         -- 与信使用額（判定時スナップショット）
    credit_over_amount  NUMERIC(18,2),                         -- 超限金額
    credit_check_at     TIMESTAMPTZ,                           -- 与信判定日時
    list_amount         NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 標準価格合計
    discount_amount     NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 値引合計
    total_amount        NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 税抜合計
    tax_amount          NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 税額合計
    grand_total         NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 税込合計
    total_qty           NUMERIC(18,4) NOT NULL DEFAULT 0,      -- 数量合計
    external_no         VARCHAR(100),                          -- 顧客注文番号
    quotation_id        BIGINT,                                -- 見積ID（受注転換元）
    source_type         VARCHAR(30),                           -- 來源区分（QUOTATION/EXCHANGE/MANUAL）
    source_id           BIGINT,                                -- 來源ID
    source_no           VARCHAR(32),                           -- 來源番号
    submitted_at        TIMESTAMPTZ,                           -- 提出日時
    submitted_by        BIGINT,                                -- 提出者
    approved_at         TIMESTAMPTZ,                           -- 承認日時
    approved_by         BIGINT,                                -- 承認者
    cancelled_at        TIMESTAMPTZ,                           -- 取消日時
    cancelled_by        BIGINT,                                -- 取消者
    cancel_reason       VARCHAR(500),                          -- 取消理由
    rejection_reason    VARCHAR(500),                          -- 却下・差戻し理由
    closed_at           TIMESTAMPTZ,                           -- クローズ日時
    closed_by           BIGINT,                                -- クローズ者
    incoterms_code      VARCHAR(10),                           -- Incoterms 2020
    incoterms_place     VARCHAR(100),                          -- 引渡場所
    export_flag         BOOLEAN      NOT NULL DEFAULT FALSE,   -- 輸出フラグ
    destination_country_code VARCHAR(3),                       -- 仕向国
    port_of_loading     VARCHAR(10),                           -- 積出港
    port_of_destination VARCHAR(10),                           -- 仕向港
    export_declaration_no VARCHAR(50),                         -- 通関申告番号
    export_license_no   VARCHAR(50),                           -- 輸出許可番号
    packing_list_no     VARCHAR(50),                           -- 梱包明細番号
    foreign_currency_code VARCHAR(3),                          -- 外貨通貨
    CONSTRAINT pk_sal_sales_order PRIMARY KEY (id),
    CONSTRAINT fk_sal_sales_order_customer FOREIGN KEY (customer_id) REFERENCES mdm_customer (id),
    CONSTRAINT fk_sal_sales_order_quotation FOREIGN KEY (quotation_id) REFERENCES sal_quotation (id),
    CONSTRAINT ck_sal_sales_order_status CHECK (order_status IN (10,20,25,30,35,40,90,95)),
    CONSTRAINT ck_sal_sales_order_amt CHECK (grand_total >= 0)
);
ALTER TABLE sal_sales_order ENABLE ROW LEVEL SECURITY;
ALTER TABLE sal_sales_order FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sal_sales_order
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_sal_sales_order_no ON sal_sales_order (tenant_id, company_id, sales_order_no);
CREATE INDEX idx_sal_sales_order_status_date ON sal_sales_order (order_status, order_date DESC);
CREATE INDEX idx_sal_sales_order_customer ON sal_sales_order (customer_id, order_date DESC);
CREATE INDEX idx_sal_sales_order_owner ON sal_sales_order (owner_user_id, order_status);
CREATE INDEX idx_sal_sales_order_delivery ON sal_sales_order (delivery_date, order_status);
CREATE UNIQUE INDEX uk_sal_sales_order_source ON sal_sales_order (tenant_id, company_id, source_type, source_id) WHERE source_id IS NOT NULL;

-- sal_sales_order_line（傳票明細）
CREATE TABLE sal_sales_order_line (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    remark              VARCHAR(500),
    ext_data            JSONB,
    sales_order_id      BIGINT       NOT NULL,                 -- 親（sal_sales_order.id）
    line_no             INT          NOT NULL,                 -- 行番号（10刻み・安定キー）
    material_id         BIGINT       NOT NULL,                 -- 物料ID
    material_code       VARCHAR(20)  NOT NULL,                 -- 物料コード
    material_name       VARCHAR(200) NOT NULL,                 -- 品名
    spec                VARCHAR(200),                          -- 仕様
    customer_material_no VARCHAR(100),                         -- 顧客品番
    ordered_qty         NUMERIC(18,4) NOT NULL,                -- 受注数量
    uom_code            VARCHAR(10)  NOT NULL,                 -- 販売単位
    base_uom_code       VARCHAR(10)  NOT NULL,                 -- 基本単位
    conversion_rate     NUMERIC(18,8) NOT NULL DEFAULT 1,      -- 換算率スナップショット（1 販売単位 = n 基本単位。受注確定時に固定、以降変更しない）
    base_qty            NUMERIC(18,4) NOT NULL,                -- 基本単位数量（= ordered_qty × conversion_rate）
    list_price          NUMERIC(18,6),                         -- 標準価格（税抜）
    unit_price          NUMERIC(18,6) NOT NULL,                -- 受注単価（税抜）
    is_tax_included_input BOOLEAN     NOT NULL DEFAULT FALSE,  -- 税込入力フラグ
    price_source        SMALLINT     NOT NULL DEFAULT 50,      -- 取価区分
    price_list_line_id  BIGINT,                                -- 価格表行ID
    special_price_id    BIGINT,                                -- 特価ID
    discount_rate       NUMERIC(7,4) NOT NULL DEFAULT 0,       -- 折扣率（%）
    discount_amount     NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 折扣額
    tax_code            VARCHAR(20)  NOT NULL,                 -- 税コード（VAT13-OUT）
    tax_rate            NUMERIC(7,4) NOT NULL,                 -- 税率（%）
    line_amount         NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 税抜金額
    tax_amount          NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 税額
    total_amount        NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 税込金額
    delivery_date       DATE         NOT NULL,                 -- 納期
    warehouse_id        BIGINT       NOT NULL,                 -- 出荷倉庫
    reserved_qty        NUMERIC(18,4) NOT NULL DEFAULT 0,      -- 引当済数量（E09）
    shipped_qty         NUMERIC(18,4) NOT NULL DEFAULT 0,      -- 出荷済数量（販売単位。E10）
    shipped_base_qty    NUMERIC(18,4) NOT NULL DEFAULT 0,      -- 出荷済数量（基本単位。= shipped_qty × conversion_rate の累計）
    cancelled_qty       NUMERIC(18,4) NOT NULL DEFAULT 0,      -- 取消数量
    completed_qty       NUMERIC(18,4) NOT NULL DEFAULT 0,      -- 完工累計（基本単位。G2-18、生産過帳が更新）
    allowed_qty         NUMERIC(18,4),                         -- 許容完工上限（基本単位。確定時にスナップショット。NULL=未快照，G2-18 审批时报 5000）
    completion_over_rate NUMERIC(5,4),                         -- 完工超収容差スナップショット（比率。NULL=チェーン継承結果を確定時に展開）
    shortage_qty        NUMERIC(18,4) NOT NULL DEFAULT 0,      -- 引当不足数量
    return_qty          NUMERIC(18,4) NOT NULL DEFAULT 0,      -- 返品済数量（E11）
    invoiced_qty        NUMERIC(18,4) NOT NULL DEFAULT 0,      -- 開票済数量（E12）
    expected_available_date DATE,                              -- 入荷/完成予定日
    reservation_id      BIGINT,                                -- 引当ID（inv_reservation.id）
    reservation_line_id BIGINT,                                -- 引当明細ID（inv_reservation_line.id）
    line_status         SMALLINT     NOT NULL DEFAULT 10,      -- 明細状態（10未引当/30引当済/35一部出荷/40完了/90取消）
    line_version        INT          NOT NULL DEFAULT 1,       -- 明細版数
    tracking_memo       VARCHAR(500),                          -- 追跡メモ（追記）
    line_remark         VARCHAR(500),                          -- 明細備考
    CONSTRAINT pk_sal_sales_order_line PRIMARY KEY (id),
    CONSTRAINT fk_sal_sales_order_line_o FOREIGN KEY (sales_order_id) REFERENCES sal_sales_order (id),
    CONSTRAINT fk_sal_sales_order_line_m FOREIGN KEY (material_id) REFERENCES mdm_material (id),
    CONSTRAINT ck_sal_sales_order_line_qty CHECK (ordered_qty > 0 AND reserved_qty >= 0 AND shipped_qty >= 0 AND shipped_base_qty >= 0 AND cancelled_qty >= 0 AND completed_qty >= 0 AND allowed_qty >= 0),
    CONSTRAINT ck_sal_sales_order_line_price CHECK (unit_price >= 0),
    CONSTRAINT ck_sal_sol_completed_qty CHECK (completed_qty >= 0 AND completed_qty <= allowed_qty)  -- G2-18 完工上限（2026-10-21 决定，设计书未载）
);
ALTER TABLE sal_sales_order_line ENABLE ROW LEVEL SECURITY;
ALTER TABLE sal_sales_order_line FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sal_sales_order_line
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_sal_sales_order_line_no ON sal_sales_order_line (tenant_id, company_id, sales_order_id, line_no);
CREATE INDEX idx_sal_sales_order_line_status ON sal_sales_order_line (line_status, delivery_date);
CREATE INDEX idx_sal_sales_order_line_material ON sal_sales_order_line (material_id, delivery_date);
CREATE INDEX idx_sal_sales_order_line_open ON sal_sales_order_line (sales_order_id) WHERE line_status IN (10,30,35);

-- sal_sales_order_version（履歴）
CREATE TABLE sal_sales_order_version (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    remark              VARCHAR(500),
    ext_data            JSONB,
    sales_order_id      BIGINT       NOT NULL,                 -- 親受注
    version_no          INT          NOT NULL,                 -- 業務版数（2 以降）
    change_status       SMALLINT     NOT NULL DEFAULT 10,      -- 変更状態
    change_type         SMALLINT     NOT NULL DEFAULT 10,      -- 変更種別（10数量/20納期/30価格/40明細追加削除/50混在）
    change_reason       VARCHAR(500),                          -- 変更理由
    before_total_amount NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 変更前税抜合計
    after_total_amount  NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 変更後税抜合計
    before_grand_total  NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 変更前税込合計
    after_grand_total   NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 変更後税込合計
    credit_check_result SMALLINT,                              -- 変更時の与信判定（10/20/30/40/90）
    requested_at        TIMESTAMPTZ,                           -- 変更開始日時
    requested_by        BIGINT,                                -- 変更申請者
    approved_at         TIMESTAMPTZ,                           -- 変更承認日時
    approved_by         BIGINT,                                -- 変更承認者
    applied_at          TIMESTAMPTZ,                           -- 引当増減適用日時（E09）
    snapshot            JSONB,                                 -- 変更前後スナップショット
    CONSTRAINT pk_sal_sales_order_version PRIMARY KEY (id),
    CONSTRAINT fk_sal_sales_order_version_o FOREIGN KEY (sales_order_id) REFERENCES sal_sales_order (id)
);
ALTER TABLE sal_sales_order_version ENABLE ROW LEVEL SECURITY;
ALTER TABLE sal_sales_order_version FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sal_sales_order_version
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_sal_sales_order_version_no ON sal_sales_order_version (tenant_id, company_id, sales_order_id, version_no);
CREATE INDEX idx_sal_sales_order_version_status ON sal_sales_order_version (change_status, requested_at DESC);

-- sal_sales_order_line_version（履歴）
CREATE TABLE sal_sales_order_line_version (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    remark              VARCHAR(500),
    ext_data            JSONB,
    sales_order_id      BIGINT       NOT NULL,                 -- 親受注
    version_no          INT          NOT NULL,                 -- 業務版数
    line_no             INT          NOT NULL,                 -- 行番号
    change_type         SMALLINT     NOT NULL,                 -- 変更種別（10追加/20変更/30削除）
    material_id         BIGINT,                                -- 物料ID
    material_code       VARCHAR(20),                           -- 物料コード
    material_name       VARCHAR(200),                          -- 品名
    before_qty          NUMERIC(18,4),                         -- 変更前数量
    after_qty           NUMERIC(18,4),                         -- 変更後数量
    before_unit_price   NUMERIC(18,6),                         -- 変更前単価
    after_unit_price    NUMERIC(18,6),                         -- 変更後単価
    before_delivery_date DATE,                                 -- 変更前納期
    after_delivery_date DATE,                                  -- 変更後納期
    before_amount       NUMERIC(18,2),                         -- 変更前税抜金額
    after_amount        NUMERIC(18,2),                         -- 変更後税抜金額
    change_reason       VARCHAR(500),                          -- 変更理由（明細）
    CONSTRAINT pk_sal_sales_order_line_version PRIMARY KEY (id),
    CONSTRAINT fk_sal_sales_order_line_version_v FOREIGN KEY (sales_order_id) REFERENCES sal_sales_order (id)
);
ALTER TABLE sal_sales_order_line_version ENABLE ROW LEVEL SECURITY;
ALTER TABLE sal_sales_order_line_version FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sal_sales_order_line_version
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE INDEX idx_sal_so_line_version ON sal_sales_order_line_version (sales_order_id, version_no, line_no);

-- sal_delivery_note（傳票ヘッダ）
CREATE TABLE sal_delivery_note (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    remark              VARCHAR(500),
    ext_data            JSONB,
    delivery_no         VARCHAR(32)  NOT NULL,                 -- 出荷指示番号（DN+YYMMDD+4桁）
    sales_order_id      BIGINT       NOT NULL,                 -- 受注ID
    sales_order_no      VARCHAR(32)  NOT NULL,                 -- 受注番号（スナップショット）
    customer_id         BIGINT       NOT NULL,                 -- 顧客ID
    customer_code       VARCHAR(20)  NOT NULL,                 -- 顧客コード
    customer_name       VARCHAR(200) NOT NULL,                 -- 顧客名
    delivery_date       DATE         NOT NULL,                 -- 出荷日
    warehouse_id        BIGINT       NOT NULL,                 -- 出荷倉庫
    delivery_status     SMALLINT     NOT NULL DEFAULT 25,      -- 状態（25承認済/30ピッキング中/35一部出庫/40全数出庫/90取消）
    picking_rule        VARCHAR(10)  NOT NULL DEFAULT 'FEFO',  -- ピッキングルール（FEFO/FIFO/MANUAL）
    credit_check_result SMALLINT,                              -- 出荷時与信判定（10/20/30/40/90）
    is_exception        BOOLEAN      NOT NULL DEFAULT FALSE,   -- 例外出荷フラグ
    exception_approval_id VARCHAR(32),                         -- 例外承認ID（WF）
    carrier_code        VARCHAR(20),                           -- 運送会社
    carrier_no          VARCHAR(50),                           -- 送り状番号
    total_qty           NUMERIC(18,4) NOT NULL DEFAULT 0,      -- 出荷数量合計
    total_amount        NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 税抜合計
    tax_amount          NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 税額合計
    grand_total         NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 税込合計
    picked_at           TIMESTAMPTZ,                           -- ピッキング開始日時
    confirmed_at        TIMESTAMPTZ,                           -- 出荷確定日時
    confirmed_by        BIGINT,                                -- 出荷確定者
    cancelled_at        TIMESTAMPTZ,                           -- 取消日時
    cancel_reason       VARCHAR(500),                          -- 取消理由
    CONSTRAINT pk_sal_delivery_note PRIMARY KEY (id),
    CONSTRAINT fk_sal_delivery_note_order FOREIGN KEY (sales_order_id) REFERENCES sal_sales_order (id),
    CONSTRAINT fk_sal_delivery_note_wh FOREIGN KEY (warehouse_id) REFERENCES mdm_warehouse (id),
    CONSTRAINT ck_sal_delivery_note_status CHECK (delivery_status IN (25,30,35,40,90))
);
ALTER TABLE sal_delivery_note ENABLE ROW LEVEL SECURITY;
ALTER TABLE sal_delivery_note FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sal_delivery_note
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_sal_delivery_note_no ON sal_delivery_note (tenant_id, company_id, delivery_no);
CREATE INDEX idx_sal_delivery_note_status_date ON sal_delivery_note (delivery_status, delivery_date DESC);
CREATE INDEX idx_sal_delivery_note_order ON sal_delivery_note (sales_order_id);
CREATE INDEX idx_sal_delivery_note_customer ON sal_delivery_note (customer_id, delivery_date DESC);

-- sal_delivery_note_line（傳票明細）
CREATE TABLE sal_delivery_note_line (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    remark              VARCHAR(500),
    ext_data            JSONB,
    delivery_note_id    BIGINT       NOT NULL,                 -- 親
    line_no             INT          NOT NULL,                 -- 行番号
    sales_order_line_id BIGINT       NOT NULL,                 -- 受注明細ID
    material_id         BIGINT       NOT NULL,                 -- 物料ID
    material_code       VARCHAR(20)  NOT NULL,                 -- 物料コード
    material_name       VARCHAR(200) NOT NULL,                 -- 品名
    spec                VARCHAR(200),                          -- 仕様
    uom_code            VARCHAR(10)  NOT NULL,                 -- 単位
    ordered_qty         NUMERIC(18,4) NOT NULL,                -- 受注数量（スナップショット）
    reserved_qty        NUMERIC(18,4) NOT NULL,                -- DN 作成時の引当残
    prior_shipped_qty   NUMERIC(18,4) NOT NULL DEFAULT 0,      -- 作成時の既出荷数量
    planned_qty         NUMERIC(18,4) NOT NULL,                -- 今回出荷指示数量
    picked_qty          NUMERIC(18,4) NOT NULL DEFAULT 0,      -- ピッキング数量
    shipped_qty         NUMERIC(18,4) NOT NULL DEFAULT 0,      -- 今回出荷確定数量
    unit_price          NUMERIC(18,6) NOT NULL,                -- 税抜単価（受注スナップショット）
    tax_code            VARCHAR(20)  NOT NULL,                 -- 税コード
    tax_rate            NUMERIC(7,4) NOT NULL,                 -- 税率（%）
    line_amount         NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 税抜金額
    tax_amount          NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 税額
    total_amount        NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 税込金額
    cost_amount         NUMERIC(18,2),                         -- 出庫原価（E18 より）
    inv_txn_no          VARCHAR(32),                           -- 在庫取引番号（SDO…）
    batch_no            VARCHAR(50),                           -- 批次番号
    serial_nos          JSONB,                                 -- 序列号リスト
    stock_status        SMALLINT,                              -- 在庫状態（10可用/20待検/30凍結/40不合格/50報廃待）
    line_status         SMALLINT     NOT NULL DEFAULT 25,      -- 明細状態（25/30/35/40）
    pick_remark         VARCHAR(200),                          -- ピッキング備考
    CONSTRAINT pk_sal_delivery_note_line PRIMARY KEY (id),
    CONSTRAINT fk_sal_dn_line_note FOREIGN KEY (delivery_note_id) REFERENCES sal_delivery_note (id),
    CONSTRAINT fk_sal_dn_line_so_line FOREIGN KEY (sales_order_line_id) REFERENCES sal_sales_order_line (id),
    CONSTRAINT ck_sal_dn_line_qty CHECK (planned_qty > 0 AND picked_qty >= 0 AND shipped_qty >= 0 AND shipped_qty <= planned_qty)
);
ALTER TABLE sal_delivery_note_line ENABLE ROW LEVEL SECURITY;
ALTER TABLE sal_delivery_note_line FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sal_delivery_note_line
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_sal_dn_line_no ON sal_delivery_note_line (tenant_id, company_id, delivery_note_id, line_no);
CREATE INDEX idx_sal_dn_line_order_line ON sal_delivery_note_line (sales_order_line_id);
CREATE INDEX idx_sal_dn_line_material ON sal_delivery_note_line (material_id);

-- sal_pick_detail（明細）
CREATE TABLE sal_pick_detail (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    remark              VARCHAR(500),
    ext_data            JSONB,
    delivery_note_id    BIGINT       NOT NULL,                 -- 親 DN
    delivery_note_line_id BIGINT     NOT NULL,                 -- 親 DN 明細
    pick_seq            INT          NOT NULL,                 -- ピッキング連番
    material_id         BIGINT       NOT NULL,                 -- 物料ID
    warehouse_id        BIGINT       NOT NULL,                 -- 倉庫
    location_code       VARCHAR(50),                           -- 庫位コード
    batch_no            VARCHAR(50),                           -- 批次番号
    serial_nos          JSONB,                                 -- 序列号リスト
    pick_qty            NUMERIC(18,4) NOT NULL,                -- ピッキング数量
    stock_status        SMALLINT     NOT NULL DEFAULT 10,      -- 在庫状態
    pick_status         SMALLINT     NOT NULL DEFAULT 10,      -- ピッキング状態（10指示/30完了/90取消）
    source_reservation_line_id BIGINT,                         -- 引当明細ID（inv_reservation_line.id）
    picked_by           BIGINT,                                -- ピッキング担当
    picked_at           TIMESTAMPTZ,                           -- ピッキング日時
    CONSTRAINT pk_sal_pick_detail PRIMARY KEY (id),
    CONSTRAINT fk_sal_pick_detail_dn FOREIGN KEY (delivery_note_id) REFERENCES sal_delivery_note (id),
    CONSTRAINT fk_sal_pick_detail_dn_line FOREIGN KEY (delivery_note_line_id) REFERENCES sal_delivery_note_line (id),
    CONSTRAINT ck_sal_pick_detail_qty CHECK (pick_qty > 0)
);
ALTER TABLE sal_pick_detail ENABLE ROW LEVEL SECURITY;
ALTER TABLE sal_pick_detail FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sal_pick_detail
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE INDEX idx_sal_pick_detail_line ON sal_pick_detail (delivery_note_line_id, pick_seq);
CREATE INDEX idx_sal_pick_detail_batch ON sal_pick_detail (material_id, batch_no);

-- sal_delivery_serial（明細）
CREATE TABLE sal_delivery_serial (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    remark              VARCHAR(500),
    ext_data            JSONB,
    delivery_note_id    BIGINT       NOT NULL,                 -- 親 DN
    delivery_note_line_id BIGINT     NOT NULL,                 -- 親 DN 明細
    material_id         BIGINT       NOT NULL,                 -- 物料ID
    material_code       VARCHAR(20)  NOT NULL,                 -- 物料コード
    serial_no           VARCHAR(50)  NOT NULL,                 -- 序列号
    serial_status       SMALLINT     NOT NULL DEFAULT 10,      -- 状態（10出荷済/90返品済）
    shipped_at          DATE         NOT NULL,                 -- 出荷日
    returned_at         DATE,                                  -- 返品日
    return_id           BIGINT,                                -- 返品ID
    CONSTRAINT pk_sal_delivery_serial PRIMARY KEY (id),
    CONSTRAINT fk_sal_delivery_serial_dn FOREIGN KEY (delivery_note_id) REFERENCES sal_delivery_note (id),
    CONSTRAINT fk_sal_delivery_serial_line FOREIGN KEY (delivery_note_line_id) REFERENCES sal_delivery_note_line (id)
);
ALTER TABLE sal_delivery_serial ENABLE ROW LEVEL SECURITY;
ALTER TABLE sal_delivery_serial FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sal_delivery_serial
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_sal_delivery_serial_line ON sal_delivery_serial (tenant_id, company_id, delivery_note_line_id, serial_no);
CREATE INDEX idx_sal_delivery_serial_no ON sal_delivery_serial (material_id, serial_no);

-- sal_sales_return（傳票ヘッダ）
CREATE TABLE sal_sales_return (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    remark              VARCHAR(500),
    ext_data            JSONB,
    return_no           VARCHAR(32)  NOT NULL,                 -- 返品番号（SRT+YYMMDD+4桁）
    return_type         SMALLINT     NOT NULL DEFAULT 10,      -- 返品区分（10通常/20交換）
    original_delivery_id BIGINT      NOT NULL,                 -- 元出荷ID
    original_delivery_no VARCHAR(32) NOT NULL,                 -- 元出荷番号
    sales_order_id      BIGINT       NOT NULL,                 -- 元受注ID
    sales_order_no      VARCHAR(32)  NOT NULL,                 -- 元受注番号
    customer_id         BIGINT       NOT NULL,                 -- 顧客ID
    customer_code       VARCHAR(20)  NOT NULL,                 -- 顧客コード
    customer_name       VARCHAR(200) NOT NULL,                 -- 顧客名
    return_date         DATE         NOT NULL,                 -- 返品日
    return_deadline_date DATE        NOT NULL,                 -- 返品期限日
    is_overdue          BOOLEAN      NOT NULL DEFAULT FALSE,   -- 期限超過フラグ
    return_reason_code  VARCHAR(20)  NOT NULL,                 -- 返品理由（QUALITY/QTY_DIFF/LATE/WRONG_ORDER/SPEC_DIFF/OTHER）
    return_reason       VARCHAR(500),                          -- 理由詳細
    freight_bearer      SMALLINT     NOT NULL DEFAULT 10,      -- 運賃負担（10自社/20顧客/30折半）
    red_invoice_required BOOLEAN     NOT NULL DEFAULT FALSE,   -- 赤伝要否
    red_invoice_id      BIGINT,                                -- 赤伝発票ID
    exchange_order_id   BIGINT,                                -- 交換先受注ID（F-SAL-014）
    return_status       SMALLINT     NOT NULL DEFAULT 10,      -- 状態（10受付/20承認待ち/25承認済/30検品完了/40完了/90取消/95却下）
    total_qty           NUMERIC(18,4) NOT NULL DEFAULT 0,      -- 返品数量合計
    total_amount        NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 税抜合計
    tax_amount          NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 税額合計
    grand_total         NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 税込合計
    submitted_at        TIMESTAMPTZ,                           -- 提出日時
    submitted_by        BIGINT,                                -- 提出者
    approved_at         TIMESTAMPTZ,                           -- 承認日時
    approved_by         BIGINT,                                -- 承認者
    confirmed_at        TIMESTAMPTZ,                           -- 検品確定日時
    completed_at        TIMESTAMPTZ,                           -- 完了日時
    cancelled_at        TIMESTAMPTZ,                           -- 取消日時
    cancel_reason       VARCHAR(500),                          -- 取消理由
    CONSTRAINT pk_sal_sales_return PRIMARY KEY (id),
    CONSTRAINT fk_sal_sales_return_dn FOREIGN KEY (original_delivery_id) REFERENCES sal_delivery_note (id),
    CONSTRAINT fk_sal_sales_return_so FOREIGN KEY (sales_order_id) REFERENCES sal_sales_order (id),
    CONSTRAINT ck_sal_sales_return_status CHECK (return_status IN (10,20,25,30,40,90,95))
);
ALTER TABLE sal_sales_return ENABLE ROW LEVEL SECURITY;
ALTER TABLE sal_sales_return FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sal_sales_return
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_sal_sales_return_no ON sal_sales_return (tenant_id, company_id, return_no);
CREATE INDEX idx_sal_sales_return_deadline ON sal_sales_return (return_status, return_deadline_date);
CREATE INDEX idx_sal_sales_return_customer ON sal_sales_return (customer_id, return_date DESC);
CREATE INDEX idx_sal_sales_return_delivery ON sal_sales_return (original_delivery_id);

-- sal_sales_return_line（傳票明細）
CREATE TABLE sal_sales_return_line (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    remark              VARCHAR(500),
    ext_data            JSONB,
    return_id           BIGINT       NOT NULL,                 -- 親返品
    line_no             INT          NOT NULL,                 -- 行番号
    original_delivery_line_id BIGINT NOT NULL,                 -- 元出荷明細ID
    material_id         BIGINT       NOT NULL,                 -- 物料ID
    material_code       VARCHAR(20)  NOT NULL,                 -- 物料コード
    material_name       VARCHAR(200) NOT NULL,                 -- 品名
    uom_code            VARCHAR(10)  NOT NULL,                 -- 単位
    original_qty        NUMERIC(18,4) NOT NULL,                -- 元出荷数量
    returned_qty        NUMERIC(18,4) NOT NULL DEFAULT 0,      -- 既返品数量
    returnable_qty      NUMERIC(18,4) NOT NULL,                -- 返品可能数量（作成時点）
    return_qty          NUMERIC(18,4) NOT NULL,                -- 今回返品数量
    inspected_qty       NUMERIC(18,4) NOT NULL DEFAULT 0,      -- 受入数量
    unit_price          NUMERIC(18,6) NOT NULL,                -- 元出荷税抜単価
    tax_code            VARCHAR(20)  NOT NULL,                 -- 税コード
    tax_rate            NUMERIC(7,4) NOT NULL,                 -- 税率（%）
    line_amount         NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 税抜金額
    tax_amount          NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 税額
    total_amount        NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 税込金額
    cost_amount         NUMERIC(18,2),                         -- 元出荷原価（按分前）
    cost_return_amount  NUMERIC(18,2),                         -- 原価戻し額（E18）
    batch_no            VARCHAR(50),                           -- 元批次
    serial_nos          JSONB,                                 -- 元序列号
    inspection_result   VARCHAR(20),                           -- 検品結果（PASS/REWORK/REJECT/CONCESSION）
    inventory_status    SMALLINT,                              -- 戻入先在庫状態（10可用/20待検/40不合格）
    defect_reason       VARCHAR(500),                          -- 不良内容
    line_status         SMALLINT     NOT NULL DEFAULT 10,      -- 明細状態
    inv_txn_no          VARCHAR(32),                           -- 在庫取引番号（RT_IN）
    line_remark         VARCHAR(500),                          -- 明細備考
    CONSTRAINT pk_sal_sales_return_line PRIMARY KEY (id),
    CONSTRAINT fk_sal_return_line_return FOREIGN KEY (return_id) REFERENCES sal_sales_return (id),
    CONSTRAINT fk_sal_return_line_dn_line FOREIGN KEY (original_delivery_line_id) REFERENCES sal_delivery_note_line (id),
    CONSTRAINT ck_sal_return_line_qty CHECK (return_qty > 0 AND return_qty <= returnable_qty)
);
ALTER TABLE sal_sales_return_line ENABLE ROW LEVEL SECURITY;
ALTER TABLE sal_sales_return_line FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sal_sales_return_line
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_sal_return_line_no ON sal_sales_return_line (tenant_id, company_id, return_id, line_no);
CREATE INDEX idx_sal_return_line_dn_line ON sal_sales_return_line (original_delivery_line_id);

-- sal_return_inspection（明細）
CREATE TABLE sal_return_inspection (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    remark              VARCHAR(500),
    ext_data            JSONB,
    return_id           BIGINT       NOT NULL,                 -- 親返品
    return_line_id      BIGINT       NOT NULL,                 -- 返品明細
    inspection_seq      INT          NOT NULL,                 -- 検品連番
    inspection_status   SMALLINT     NOT NULL DEFAULT 10,      -- 検品状態（10未検品/20検品中/40完了）
    inspection_result   VARCHAR(20),                           -- 検品結果
    inventory_status    SMALLINT,                              -- 在庫状態
    inspected_qty       NUMERIC(18,4),                         -- 受入数量
    defect_reason       VARCHAR(500),                          -- 不良内容
    inspection_remark   VARCHAR(500),                          -- 検品備考
    inspected_by        BIGINT,                                -- 検品者
    inspected_at        TIMESTAMPTZ,                           -- 検品日時
    CONSTRAINT pk_sal_return_inspection PRIMARY KEY (id),
    CONSTRAINT fk_sal_return_inspection_r FOREIGN KEY (return_id) REFERENCES sal_sales_return (id),
    CONSTRAINT fk_sal_return_inspection_l FOREIGN KEY (return_line_id) REFERENCES sal_sales_return_line (id)
);
ALTER TABLE sal_return_inspection ENABLE ROW LEVEL SECURITY;
ALTER TABLE sal_return_inspection FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sal_return_inspection
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE INDEX idx_sal_return_inspection_line ON sal_return_inspection (return_line_id, inspection_seq DESC);

-- sal_invoice_application（傳票ヘッダ）
CREATE TABLE sal_invoice_application (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    remark              VARCHAR(500),
    ext_data            JSONB,
    application_no      VARCHAR(32)  NOT NULL,                 -- 申請番号（IVA+YYMMDD+4桁）
    customer_id         BIGINT       NOT NULL,                 -- 顧客ID
    customer_code       VARCHAR(20)  NOT NULL,                 -- 顧客コード
    customer_name       VARCHAR(200) NOT NULL,                 -- 顧客名
    period_from         DATE         NOT NULL,                 -- 請求期間From
    period_to           DATE         NOT NULL,                 -- 請求期間To
    invoice_type        SMALLINT     NOT NULL,                 -- 発票種別（10専票/20普票/30数電専票/40数電普票）
    invoice_kind        VARCHAR(20),                           -- 発票区分（SPECIAL/NORMAL/E_INVOICE）
    invoice_title       VARCHAR(200),                          -- 発票抬頭
    invoice_tax_no      VARCHAR(30),                           -- 購入方納税者番号
    invoice_address_phone VARCHAR(300),                        -- 購入方住所・電話
    invoice_bank_name   VARCHAR(200),                          -- 購入方銀行名
    invoice_bank_account VARCHAR(50),                          -- 購入方口座（暗号化対象）
    delivery_method     SMALLINT     NOT NULL DEFAULT 10,      -- 交付方法（10PDFメール/20郵送/30ポータル/40数電交付）
    total_amount        NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 税抜合計
    tax_amount          NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 税額合計
    grand_total         NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 税込合計
    amount_diff         NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 応収との差額
    diff_reason         VARCHAR(500),                          -- 差額理由
    application_status  SMALLINT     NOT NULL DEFAULT 10,      -- 状態（10草稿/20承認待ち/25承認済/30発票発行済/40完了/90取消/95却下）
    invoice_id          BIGINT,                                -- 発票ID
    submitted_at        TIMESTAMPTZ,                           -- 提出日時
    submitted_by        BIGINT,                                -- 提出者
    approved_at         TIMESTAMPTZ,                           -- 承認日時
    approved_by         BIGINT,                                -- 承認者
    completed_at        TIMESTAMPTZ,                           -- 完了日時
    cancelled_at        TIMESTAMPTZ,                           -- 取消日時
    cancel_reason       VARCHAR(500),                          -- 取消理由
    CONSTRAINT pk_sal_invoice_application PRIMARY KEY (id),
    CONSTRAINT fk_sal_iva_customer FOREIGN KEY (customer_id) REFERENCES mdm_customer (id),
    CONSTRAINT ck_sal_iva_period CHECK (period_from <= period_to)
);
ALTER TABLE sal_invoice_application ENABLE ROW LEVEL SECURITY;
ALTER TABLE sal_invoice_application FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sal_invoice_application
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_sal_iva_no ON sal_invoice_application (tenant_id, company_id, application_no);
CREATE INDEX idx_sal_iva_customer_period ON sal_invoice_application (customer_id, period_from DESC);
CREATE INDEX idx_sal_iva_status ON sal_invoice_application (application_status, period_from DESC);

-- sal_invoice_application_line（傳票明細）
CREATE TABLE sal_invoice_application_line (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    remark              VARCHAR(500),
    ext_data            JSONB,
    application_id      BIGINT       NOT NULL,                 -- 親申請
    line_no             INT          NOT NULL,                 -- 行番号
    delivery_id         BIGINT       NOT NULL,                 -- 出荷ID（sal_delivery_note.id）
    delivery_no         VARCHAR(32)  NOT NULL,                 -- 出荷番号
    receivable_id       BIGINT,                                -- 応収ID（fin_receivable.id）
    receivable_no       VARCHAR(32),                           -- 応収番号
    material_id         BIGINT       NOT NULL,                 -- 物料ID
    material_code       VARCHAR(20)  NOT NULL,                 -- 物料コード
    material_name       VARCHAR(200) NOT NULL,                 -- 品名
    qty                 NUMERIC(18,4) NOT NULL,                -- 数量
    uom_code            VARCHAR(10)  NOT NULL,                 -- 単位
    unit_price          NUMERIC(18,6) NOT NULL,                -- 税抜単価
    tax_code            VARCHAR(20)  NOT NULL,                 -- 税コード
    tax_rate            NUMERIC(7,4) NOT NULL,                 -- 税率（%）
    line_amount         NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 税抜金額
    tax_amount          NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 税額
    total_amount        NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 税込金額
    invoice_status      SMALLINT     NOT NULL DEFAULT 10,      -- 開票状態（10未開票/30開票済/40紐付け済）
    line_remark         VARCHAR(200),                          -- 明細備考
    CONSTRAINT pk_sal_iva_line PRIMARY KEY (id),
    CONSTRAINT fk_sal_iva_line_app FOREIGN KEY (application_id) REFERENCES sal_invoice_application (id),
    CONSTRAINT fk_sal_iva_line_dn FOREIGN KEY (delivery_id) REFERENCES sal_delivery_note (id)
);
ALTER TABLE sal_invoice_application_line ENABLE ROW LEVEL SECURITY;
ALTER TABLE sal_invoice_application_line FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sal_invoice_application_line
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_sal_iva_line_no ON sal_invoice_application_line (tenant_id, company_id, application_id, line_no);
CREATE INDEX idx_sal_iva_line_dn ON sal_invoice_application_line (delivery_id);

-- sal_invoice（傳票ヘッダ）
CREATE TABLE sal_invoice (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    remark              VARCHAR(500),
    ext_data            JSONB,
    invoice_no          VARCHAR(50)  NOT NULL,                 -- 発票番号（数電票20桁/紙票8桁）
    invoice_code        VARCHAR(20),                           -- 発票コード（紙票のみ）
    invoice_kind        VARCHAR(20)  NOT NULL,                 -- 発票区分（SPECIAL/NORMAL/E_INVOICE/RED）
    invoice_type        SMALLINT     NOT NULL,                 -- 発票種別（10/20/30/40）
    application_id      BIGINT,                                -- 開票申請ID
    customer_id         BIGINT       NOT NULL,                 -- 顧客ID
    customer_code       VARCHAR(20)  NOT NULL,                 -- 顧客コード
    customer_name       VARCHAR(200) NOT NULL,                 -- 顧客名
    buyer_name          VARCHAR(200) NOT NULL,                 -- 購入方名称
    buyer_tax_no        VARCHAR(30),                           -- 購入方納税者番号
    buyer_address_phone VARCHAR(300),                          -- 購入方住所・電話
    buyer_bank_name     VARCHAR(200),                          -- 購入方銀行名
    buyer_bank_account  VARCHAR(50),                           -- 購入方口座（暗号化）
    issued_at           DATE         NOT NULL,                 -- 開票日
    delivered_at        DATE,                                  -- 交付日
    delivery_status     SMALLINT     NOT NULL DEFAULT 10,      -- 交付状態（10未交付/30交付済）
    delivery_method     SMALLINT,                              -- 交付方法
    amount              NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 税抜金額
    tax_amount          NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 税額
    total_amount        NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 税込金額
    currency_code       VARCHAR(3)   NOT NULL DEFAULT 'CNY',   -- 通貨
    invoice_status      SMALLINT     NOT NULL DEFAULT 10,      -- 状態（10登録済/30交付済/40完了/90赤伝済）
    ar_link_status      SMALLINT     NOT NULL DEFAULT 10,      -- AR紐付け（10未/40済）
    original_invoice_id BIGINT,                                -- 元発票ID（赤伝時）
    red_reason          VARCHAR(500),                          -- 赤伝理由
    reissue_count       INT          NOT NULL DEFAULT 0,       -- 再発行回数
    attachment_id       BIGINT,                                -- 発票 PDF/OFD（sys_attachment.id）
    CONSTRAINT pk_sal_invoice PRIMARY KEY (id),
    CONSTRAINT fk_sal_invoice_customer FOREIGN KEY (customer_id) REFERENCES mdm_customer (id),
    CONSTRAINT fk_sal_invoice_application FOREIGN KEY (application_id) REFERENCES sal_invoice_application (id)
);
ALTER TABLE sal_invoice ENABLE ROW LEVEL SECURITY;
ALTER TABLE sal_invoice FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sal_invoice
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_sal_invoice_no ON sal_invoice (tenant_id, company_id, COALESCE(invoice_code, ''), invoice_no);
CREATE INDEX idx_sal_invoice_issued ON sal_invoice (issued_at DESC, invoice_status);
CREATE INDEX idx_sal_invoice_customer ON sal_invoice (customer_id, issued_at DESC);
CREATE INDEX idx_sal_invoice_original ON sal_invoice (original_invoice_id);

-- sal_invoice_line（傳票明細）
CREATE TABLE sal_invoice_line (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    remark              VARCHAR(500),
    ext_data            JSONB,
    invoice_id          BIGINT       NOT NULL,                 -- 親発票
    line_no             INT          NOT NULL,                 -- 行番号
    delivery_id         BIGINT,                                -- 出荷ID
    delivery_no         VARCHAR(32),                           -- 出荷番号
    material_id         BIGINT       NOT NULL,                 -- 物料ID
    material_code       VARCHAR(20)  NOT NULL,                 -- 物料コード
    material_name       VARCHAR(200) NOT NULL,                 -- 品名（貨物或应税劳务、服务名称）
    spec                VARCHAR(200),                          -- 規格型番
    qty                 NUMERIC(18,4) NOT NULL,                -- 数量
    uom_code            VARCHAR(10)  NOT NULL,                 -- 単位
    unit_price          NUMERIC(18,6) NOT NULL,                -- 単価（税抜）
    amount              NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 金額（税抜）
    tax_code            VARCHAR(20)  NOT NULL,                 -- 税コード
    tax_rate            NUMERIC(7,4) NOT NULL,                 -- 税率・徴収率（%）
    tax_amount          NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 税額
    total_amount        NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 税込金額
    tax_classification_code VARCHAR(20),                       -- 税収分類編碼
    CONSTRAINT pk_sal_invoice_line PRIMARY KEY (id),
    CONSTRAINT fk_sal_invoice_line_inv FOREIGN KEY (invoice_id) REFERENCES sal_invoice (id),
    CONSTRAINT ck_sal_invoice_line_qty CHECK (qty > 0)
);
ALTER TABLE sal_invoice_line ENABLE ROW LEVEL SECURITY;
ALTER TABLE sal_invoice_line FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sal_invoice_line
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_sal_invoice_line_no ON sal_invoice_line (tenant_id, company_id, invoice_id, line_no);
CREATE INDEX idx_sal_invoice_line_material ON sal_invoice_line (material_id);

-- sal_invoice_relation（関連）
CREATE TABLE sal_invoice_relation (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    remark              VARCHAR(500),
    ext_data            JSONB,
    invoice_id          BIGINT       NOT NULL,                 -- 発票ID
    relate_type         VARCHAR(30)  NOT NULL,                 -- 関連種別（ORIGINAL_INVOICE/DELIVERY/ORDER/RECEIVABLE/RETURN）
    relate_id           BIGINT       NOT NULL,                 -- 関連ID
    relate_no           VARCHAR(50),                           -- 関連番号
    relate_amount       NUMERIC(18,2),                         -- 関連金額（按分額）
    CONSTRAINT pk_sal_invoice_relation PRIMARY KEY (id),
    CONSTRAINT fk_sal_invoice_relation_inv FOREIGN KEY (invoice_id) REFERENCES sal_invoice (id)
);
ALTER TABLE sal_invoice_relation ENABLE ROW LEVEL SECURITY;
ALTER TABLE sal_invoice_relation FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sal_invoice_relation
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE INDEX idx_sal_invoice_relation_inv ON sal_invoice_relation (invoice_id, relate_type);
CREATE INDEX idx_sal_invoice_relation_target ON sal_invoice_relation (relate_type, relate_id);

-- sal_statement（傳票ヘッダ）
CREATE TABLE sal_statement (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    remark              VARCHAR(500),
    ext_data            JSONB,
    statement_no        VARCHAR(32)  NOT NULL,                 -- 対账单番号（STM+YYMMDD+4桁）
    statement_version   INT          NOT NULL DEFAULT 1,       -- 版数
    customer_id         BIGINT       NOT NULL,                 -- 顧客ID
    customer_code       VARCHAR(20)  NOT NULL,                 -- 顧客コード
    customer_name       VARCHAR(200) NOT NULL,                 -- 顧客名
    period_code         VARCHAR(7)   NOT NULL,                 -- 対象期間（YYYY-MM）
    opening_balance     NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 前月末残高
    period_sales_amount NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 当期売上（税込）
    period_return_amount NUMERIC(18,2) NOT NULL DEFAULT 0,     -- 当期赤伝
    period_receipt_amount NUMERIC(18,2) NOT NULL DEFAULT 0,    -- 当期入金
    period_adjust_amount NUMERIC(18,2) NOT NULL DEFAULT 0,     -- 当期調整
    closing_balance     NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 月末残高
    overdue_amount      NUMERIC(18,2) NOT NULL DEFAULT 0,      -- うち逾期
    fin_balance         NUMERIC(18,2),                         -- FIN 応収残高
    balance_diff        NUMERIC(18,2),                         -- 差異
    balance_diff_reason VARCHAR(500),                          -- 差異理由
    statement_status    SMALLINT     NOT NULL DEFAULT 10,      -- 状態（10作成中/30発行済/40顧客確認済）
    sent_at             TIMESTAMPTZ,                           -- 送付日時
    send_method         SMALLINT,                              -- 送付方法（10PDFメール/20郵送/30ポータル）
    sent_by             BIGINT,                                -- 送付者
    confirmed_at        TIMESTAMPTZ,                           -- 顧客確認日時
    confirmed_by        BIGINT,                                -- 確認記録者
    CONSTRAINT pk_sal_statement PRIMARY KEY (id),
    CONSTRAINT fk_sal_statement_customer FOREIGN KEY (customer_id) REFERENCES mdm_customer (id)
);
ALTER TABLE sal_statement ENABLE ROW LEVEL SECURITY;
ALTER TABLE sal_statement FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sal_statement
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_sal_statement_version ON sal_statement (tenant_id, company_id, customer_id, period_code, statement_version);
CREATE INDEX idx_sal_statement_status ON sal_statement (statement_status, period_code DESC);

-- sal_statement_line（傳票明細）
CREATE TABLE sal_statement_line (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    remark              VARCHAR(500),
    ext_data            JSONB,
    statement_id        BIGINT       NOT NULL,                 -- 親対账单
    line_no             INT          NOT NULL,                 -- 行番号
    transaction_type    SMALLINT     NOT NULL,                 -- 区分（10前期繰越/20売上/30赤伝/40入金/50前受金/90その他）
    transaction_date    DATE         NOT NULL,                 -- 取引日
    document_no         VARCHAR(32),                           -- 伝票番号（応収/出荷/入金）
    receivable_id       BIGINT,                                -- 応収ID
    delivery_id         BIGINT,                                -- 出荷ID
    invoice_id          BIGINT,                                -- 発票ID
    description         VARCHAR(200),                          -- 摘要
    debit_amount        NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 借方金額（売上）
    credit_amount       NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 貸方金額（入金）
    balance_amount      NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 残高
    due_date            DATE,                                  -- 支払期日
    CONSTRAINT pk_sal_statement_line PRIMARY KEY (id),
    CONSTRAINT fk_sal_statement_line_s FOREIGN KEY (statement_id) REFERENCES sal_statement (id)
);
ALTER TABLE sal_statement_line ENABLE ROW LEVEL SECURITY;
ALTER TABLE sal_statement_line FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sal_statement_line
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_sal_statement_line_no ON sal_statement_line (tenant_id, company_id, statement_id, line_no);
CREATE INDEX idx_sal_statement_line_date ON sal_statement_line (statement_id, transaction_date);

-- sal_credit_ledger_snapshot（**投影（読取専用）**。権威は FIN）
CREATE TABLE sal_credit_ledger_snapshot (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    remark              VARCHAR(500),
    ext_data            JSONB,
    customer_id         BIGINT       NOT NULL,                 -- 顧客ID
    source_type         VARCHAR(30)  NOT NULL,                 -- 来源（SALES_ORDER）
    source_id           BIGINT       NOT NULL,                 -- 来源ID（受注ID）
    source_no           VARCHAR(32)  NOT NULL,                 -- 来源番号
    currency_code       VARCHAR(3)   NOT NULL DEFAULT 'CNY',   -- 通貨
    amount              NUMERIC(18,2) NOT NULL,                -- FIN 台帳コミット額（税込）の投影
    released_amount     NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 解放済額
    status              SMALLINT     NOT NULL DEFAULT 10,      -- 状態（10有効/35一部解放/40全解放/90取消）
    release_seq         INT          NOT NULL DEFAULT 0,       -- 解放連番（冪等キー）
    committed_at        TIMESTAMPTZ  NOT NULL,                 -- FIN 台帳コミット日時の投影
    released_at         TIMESTAMPTZ,                           -- 最終解放日時
    release_reason      VARCHAR(30),                           -- 解放理由（SHIP/RECEIPT/CANCEL/WRITE_OFF）
    release_event_id    VARCHAR(64),                           -- 解放イベントID（冪等）
    CONSTRAINT pk_sal_credit_ledger_snapshot PRIMARY KEY (id),
    CONSTRAINT fk_sal_credit_occ_customer FOREIGN KEY (customer_id) REFERENCES mdm_customer (id),
    CONSTRAINT ck_sal_credit_occ_amt CHECK (amount >= 0 AND released_amount >= 0 AND released_amount <= amount)
);
ALTER TABLE sal_credit_ledger_snapshot ENABLE ROW LEVEL SECURITY;
ALTER TABLE sal_credit_ledger_snapshot FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sal_credit_ledger_snapshot
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_sal_credit_occ_source ON sal_credit_ledger_snapshot (tenant_id, source_type, source_id, release_seq);
CREATE INDEX idx_sal_credit_occ_customer ON sal_credit_ledger_snapshot (customer_id, status);
CREATE INDEX idx_sal_credit_occ_source_lookup ON sal_credit_ledger_snapshot (source_type, source_id);

-- sal_credit_check_log（ログ（追記専用））
CREATE TABLE sal_credit_check_log (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    remark              VARCHAR(500),
    ext_data            JSONB,
    customer_id         BIGINT       NOT NULL,                 -- 顧客ID
    check_type          SMALLINT     NOT NULL,                 -- 判定種別（10登録/20提出/30承認/40出荷/50日次照合）
    sales_order_id      BIGINT,                                -- 受注ID
    receivable_balance  NUMERIC(18,2) NOT NULL DEFAULT 0,      -- FIN 応収残高
    order_commitment    NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 受注コミット残
    advance_receipt     NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 前受金未核销
    credit_limit_amount NUMERIC(18,2),                         -- 与信限度額
    single_order_limit_amount NUMERIC(18,2),                   -- 単筆上限
    order_amount        NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 今回受注額
    used_amount         NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 与信使用額
    available_amount    NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 与信余力
    over_amount         NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 超限金額
    over_ratio          NUMERIC(7,4) NOT NULL DEFAULT 0,       -- 超限比率（%）
    check_result        SMALLINT     NOT NULL,                 -- 判定結果（10正常/20注意/30超限審査中/40超限承認済/90凍結・閉鎖）
    check_action        VARCHAR(30),                           -- 処置（CONTINUE/APPROVAL_REQUIRED/BLOCKED）
    rule_id             BIGINT,                                -- 与信チェックルールID
    snapshot            JSONB,                                 -- 判定根拠スナップショット
    checked_by          BIGINT,                                -- 判定者
    checked_at          TIMESTAMPTZ  NOT NULL DEFAULT now(),   -- 判定日時
    CONSTRAINT pk_sal_credit_check_log PRIMARY KEY (id),
    CONSTRAINT fk_sal_credit_log_customer FOREIGN KEY (customer_id) REFERENCES mdm_customer (id)
);
ALTER TABLE sal_credit_check_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE sal_credit_check_log FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sal_credit_check_log
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE INDEX idx_sal_credit_log_customer ON sal_credit_check_log (customer_id, checked_at DESC);
CREATE INDEX idx_sal_credit_log_order ON sal_credit_check_log (sales_order_id, check_type);

-- sal_receivable_snapshot（投影（読取専用））
CREATE TABLE sal_receivable_snapshot (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    remark              VARCHAR(500),
    ext_data            JSONB,
    receivable_id       BIGINT       NOT NULL,                 -- FIN 応収ID（fin_receivable.id）
    receivable_no       VARCHAR(32)  NOT NULL,                 -- 応収番号
    customer_id         BIGINT       NOT NULL,                 -- 顧客ID
    customer_code       VARCHAR(20)  NOT NULL,                 -- 顧客コード
    customer_name       VARCHAR(200) NOT NULL,                 -- 顧客名
    source_type         VARCHAR(30),                           -- 来源区分（SALES_DELIVERY/SALES_RETURN/OPENING）
    source_id           BIGINT,                                -- 来源ID
    source_no           VARCHAR(32),                           -- 来源番号
    delivery_id         BIGINT,                                -- 出荷ID
    sales_order_id      BIGINT,                                -- 受注ID
    receivable_date     DATE         NOT NULL,                 -- 計上日
    due_date            DATE         NOT NULL,                 -- 支払期日
    currency_code       VARCHAR(3)   NOT NULL DEFAULT 'CNY',   -- 通貨
    amount              NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 税抜金額
    tax_amount          NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 税額
    total_amount        NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 税込金額
    received_amount     NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 入金済額
    balance_amount      NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 残高
    invoice_status      SMALLINT     NOT NULL DEFAULT 0,       -- 開票状態（FIN 契約: 0未開票/1部分開票/2已開票）
    receivable_status   SMALLINT     NOT NULL DEFAULT 10,      -- 状態（10未回収/35一部回収/40回収済/90取消）
    overdue_days        INT          NOT NULL DEFAULT 0,       -- 逾期日数（FIN 提供値）
    last_event_id       VARCHAR(64),                           -- 最終反映イベントID（冪等）
    synced_at           TIMESTAMPTZ  NOT NULL DEFAULT now(),   -- 同期日時
    CONSTRAINT pk_sal_receivable_snapshot PRIMARY KEY (id)
);
ALTER TABLE sal_receivable_snapshot ENABLE ROW LEVEL SECURITY;
ALTER TABLE sal_receivable_snapshot FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sal_receivable_snapshot
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_sal_receivable_snapshot_fin ON sal_receivable_snapshot (tenant_id, receivable_id);
CREATE INDEX idx_sal_receivable_snapshot_cust ON sal_receivable_snapshot (customer_id, due_date);
CREATE INDEX idx_sal_receivable_snapshot_open ON sal_receivable_snapshot (customer_id, receivable_status);

-- sal_special_price（傳票ヘッダ）
CREATE TABLE sal_special_price (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    remark              VARCHAR(500),
    ext_data            JSONB,
    special_price_no    VARCHAR(32)  NOT NULL,                 -- 特価番号（SP+YYMMDD+4桁）
    customer_id         BIGINT       NOT NULL,                 -- 顧客ID
    customer_code       VARCHAR(20)  NOT NULL,                 -- 顧客コード
    customer_name       VARCHAR(200) NOT NULL,                 -- 顧客名
    material_id         BIGINT       NOT NULL,                 -- 物料ID
    material_code       VARCHAR(20)  NOT NULL,                 -- 物料コード
    material_name       VARCHAR(200) NOT NULL,                 -- 品名
    standard_price      NUMERIC(18,6),                         -- 標準価格（税抜）
    special_unit_price  NUMERIC(18,6) NOT NULL,                -- 特価（税抜）
    min_qty             NUMERIC(18,4) NOT NULL DEFAULT 0,      -- 最低数量
    currency_code       VARCHAR(3)   NOT NULL DEFAULT 'CNY',   -- 通貨
    tax_code            VARCHAR(20)  NOT NULL,                 -- 税コード（VAT13-OUT）
    valid_from          DATE         NOT NULL,                 -- 有効開始日
    valid_to            DATE         NOT NULL,                 -- 有効終了日
    reason_type         VARCHAR(20)  NOT NULL,                 -- 理由区分（COMPETITION/VOLUME/NEW_CUSTOMER/STOCK_CLEAR/OTHER）
    reason              VARCHAR(500) NOT NULL,                 -- 理由
    standard_cost       NUMERIC(18,6),                         -- 標準原価（参考）
    gross_margin_rate   NUMERIC(7,4),                          -- 粗利率（%）
    status              SMALLINT     NOT NULL DEFAULT 10,      -- 状態（10草稿/20承認待ち/25承認済有効/40適用終了/90取消/95却下）
    approval_route      VARCHAR(200),                          -- 承認経路
    source_type         VARCHAR(30),                           -- 来源（QUOTATION/ORDER/MANUAL）
    source_id           BIGINT,                                -- 来源ID
    approved_at         TIMESTAMPTZ,                           -- 承認日時
    approved_by         BIGINT,                                -- 承認者
    closed_at           TIMESTAMPTZ,                           -- 終了日時
    cancel_reason       VARCHAR(500),                          -- 取消理由
    CONSTRAINT pk_sal_special_price PRIMARY KEY (id),
    CONSTRAINT fk_sal_special_price_cust FOREIGN KEY (customer_id) REFERENCES mdm_customer (id),
    CONSTRAINT fk_sal_special_price_mat FOREIGN KEY (material_id) REFERENCES mdm_material (id),
    CONSTRAINT ck_sal_special_price_price CHECK (special_unit_price > 0),
    CONSTRAINT ck_sal_special_price_valid CHECK (valid_from <= valid_to)
);
ALTER TABLE sal_special_price ENABLE ROW LEVEL SECURITY;
ALTER TABLE sal_special_price FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sal_special_price
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_sal_special_price_no ON sal_special_price (tenant_id, company_id, special_price_no);
CREATE UNIQUE INDEX uk_sal_special_price_active ON sal_special_price (tenant_id, company_id, customer_id, material_id, valid_from) WHERE status = 25;
CREATE INDEX idx_sal_special_price_lookup ON sal_special_price (customer_id, material_id, status, valid_to);

-- sal_sales_forecast（傳票ヘッダ）
CREATE TABLE sal_sales_forecast (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    remark              VARCHAR(500),
    ext_data            JSONB,
    forecast_no         VARCHAR(32)  NOT NULL,                 -- 予測番号（FCST+YYMMDD+4桁）
    forecast_version    INT          NOT NULL DEFAULT 1,       -- 版数
    period_code         VARCHAR(7)   NOT NULL,                 -- 対象月（YYYY-MM）
    department_id       BIGINT       NOT NULL,                 -- 部門ID
    customer_id         BIGINT,                                -- 顧客ID（任意）
    currency_code       VARCHAR(3)   NOT NULL DEFAULT 'CNY',   -- 通貨
    input_deadline      DATE,                                  -- 入力締切
    forecast_status     SMALLINT     NOT NULL DEFAULT 10,      -- 状態（10入力中/25確定/40実績照合済/90取消）
    total_qty           NUMERIC(18,4) NOT NULL DEFAULT 0,      -- 数量合計
    total_amount        NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 金額合計
    confirmed_at        TIMESTAMPTZ,                           -- 確定日時
    confirmed_by        BIGINT,                                -- 確定者
    CONSTRAINT pk_sal_sales_forecast PRIMARY KEY (id),
    CONSTRAINT fk_sal_forecast_dept FOREIGN KEY (department_id) REFERENCES sys_department (id),
    CONSTRAINT ck_sal_forecast_period CHECK (period_code ~ '^[0-9]{4}-[0-9]{2}$')
);
ALTER TABLE sal_sales_forecast ENABLE ROW LEVEL SECURITY;
ALTER TABLE sal_sales_forecast FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sal_sales_forecast
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_sal_forecast_ver ON sal_sales_forecast (tenant_id, company_id, forecast_no, forecast_version);
CREATE INDEX idx_sal_forecast_period ON sal_sales_forecast (period_code, department_id, forecast_status);

-- sal_sales_forecast_line（傳票明細）
CREATE TABLE sal_sales_forecast_line (
    id                  BIGINT        NOT NULL,
    tenant_id           BIGINT        NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id          BIGINT        NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by          BIGINT        NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_by          BIGINT        NOT NULL DEFAULT 0,
    version             INT           NOT NULL DEFAULT 0,
    remark              VARCHAR(500),
    ext_data            JSONB,
    forecast_id         BIGINT       NOT NULL,                 -- 親予測
    line_no             INT          NOT NULL,                 -- 行番号
    material_id         BIGINT       NOT NULL,                 -- 物料ID
    material_code       VARCHAR(20)  NOT NULL,                 -- 物料コード
    material_name       VARCHAR(200) NOT NULL,                 -- 品名
    uom_code            VARCHAR(10)  NOT NULL,                 -- 単位
    last_month_actual_qty NUMERIC(18,4) NOT NULL DEFAULT 0,    -- 前月実績
    last_year_same_month_qty NUMERIC(18,4) NOT NULL DEFAULT 0, -- 前年同月実績
    forecast_qty        NUMERIC(18,4) NOT NULL DEFAULT 0,      -- 予測数量
    forecast_amount     NUMERIC(18,2) NOT NULL DEFAULT 0,      -- 予測金額
    confidence          VARCHAR(1),                            -- 確度（A/B/C）
    line_remark         VARCHAR(500),                          -- 明細備考
    CONSTRAINT pk_sal_sales_forecast_line PRIMARY KEY (id),
    CONSTRAINT fk_sal_forecast_line_f FOREIGN KEY (forecast_id) REFERENCES sal_sales_forecast (id),
    CONSTRAINT ck_sal_forecast_line_qty CHECK (forecast_qty >= 0)
);
ALTER TABLE sal_sales_forecast_line ENABLE ROW LEVEL SECURITY;
ALTER TABLE sal_sales_forecast_line FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON sal_sales_forecast_line
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
CREATE UNIQUE INDEX uk_sal_forecast_line_no ON sal_sales_forecast_line (tenant_id, company_id, forecast_id, line_no);
CREATE INDEX idx_sal_forecast_line_material ON sal_sales_forecast_line (material_id);
