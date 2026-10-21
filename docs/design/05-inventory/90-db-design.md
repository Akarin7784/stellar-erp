# 库存管理 DB 设计书（在庫管理 DB 設計書）

| 項目 | 内容 |
|---|---|
| 文書名 | 库存管理 DB 设计书（在庫管理 DB 設計書） |
| 文書番号 | DSN-INV-090 |
| 版数 | v1.10 |
| 作成日 | 2026-10-20 |
| 作成者 | inventory-designer |
| 承認者 | 未承認（レビュー待ち） |
| 状態 | ドラフト（レビュー中） |
| 関連文書 | [業務域概要](00-overview.md) / [DB 共通規格](../00-common/04-common-db-spec.md) / [共通項目定義](../00-common/01-common-item-definitions.md) / [入出庫](02-inbound-outbound.md) / [原価](05-costing.md) / [テーブル定義テンプレート](../_template/03-table-definition-template.md) |

---

## 1. 設計方針

### 1.1 データモデルの基本構造

```
[業務イベント]
   ├─ inv_stock_txn（事務ヘッダ：伝票番号・種別・来源・状態）
   │     └─ inv_stock_txn_line（事務明細：倉庫×物料×批次×状態×庫位の変動）
   ├─ inv_transfer（調撥単：在途管理）    └─ inv_transfer_line
   ├─ inv_stocktake_plan → inv_stocktake（棚卸単）└─ inv_stocktake_line
   ├─ inv_cost_adjustment（原価調整単）  └─ inv_cost_adjustment_line
   └─ inv_reservation（引当）             └─ inv_reservation_line

[残高・原価]  inv_stock_balance（倉庫×物料×批次×状態×庫位の残高）
              inv_cost_layer（入庫層：原価構成・庫齢）
[マスタ]      inv_batch / inv_serial / inv_batch_genealogy / inv_serial_txn
[集計]        inv_period / inv_stock_summary / inv_age_snapshot / inv_replenishment
[ログ]        inv_scan_log
```

設計の要点：

1. **更新責任の一元化**：`inv_stock_balance` を更新できるのは本域の `StockPostingManager` のみ（[02](02-inbound-outbound.md) 6.3）。他域は参照のみ。
2. **数量と金額の整合**：残高（`qty_on_hand`/`amount_on_hand`）・事務明細（`inv_stock_txn_line`）・原価層（`inv_cost_layer`）の三者が常に一致する（[BAT-INV-002](92-report-batch-design.md)）。
3. **状態は残高行の一部**：`stock_status` を残高の一意キーに含め、状態間移動は `ST_OUT`+`ST_IN` の対で表現する（[04](04-batch-serial-status.md)）。
4. **原価計算単位**：`(warehouse_id, material_id, batch_id)`（非批次は `batch_id=0`）。同一単位の全状態行が同一 `avg_unit_cost` を共有する（[05](05-costing.md) 1.2）。
5. **追記専用**：`inv_stock_txn` は過账後に数量・金額を変更しない。訂正は沖销（反向事務）。`inv_stock_txn_line` は INSERT のみ。
6. **FK は複合外键のみ**（[04 §6.2](../00-common/04-common-db-spec.md)）：MDM マスタのうち被参照側に `uk_<table>_tenant_id` がある表（`mdm_material`/`mdm_warehouse`/`mdm_factory`/`mdm_supplier`/`mdm_customer`）へは `FOREIGN KEY (tenant_id, x_id) REFERENCES mdm_x (tenant_id, id)` を張る（06/07 の迁移と同じ。一覧は §6.3）。`mdm_warehouse_bin`（`location_id`、0=未管理の番兵）・`batch_id=0` の番兵列・他業務域（prd/sal/pur/fin）への参照は软引用（FK なし、サービス層で同一 TX 検証）。**域内の親子は `(tenant_id, company_id, 親_id)` → 親 `(tenant_id, company_id, id)` の複合 FK**（親側に `uk_<table>_tenant_company_id`、sys/V202610211401・PR #43 の規則）。例外：月次パーティション表 `inv_stock_txn` は FK で参照しない（[04 §8.1](../00-common/04-common-db-spec.md)、明細との整合はトリガー）。
7. **スナップショット**：伝票明細（`inv_stock_txn_line`）は `material_code/name/spec`、`inv_stock_txn` は `partner_name` を保持し、マスタ変更の影響を受けない（[01 §13](../00-common/01-common-item-definitions.md)）。

### 1.2 ER 図（主要テーブル）

```mermaid
erDiagram
    inv_stock_txn ||--o{ inv_stock_txn_line : "1:N (txn_id)"
    inv_stock_txn }o--|| mdm_warehouse : "warehouse_id"
    inv_stock_txn_line }o--|| mdm_material : "material_id"
    inv_stock_txn_line }o--o| inv_batch : "batch_id"
    inv_stock_txn_line }o--o| inv_serial : "serial_id"
    inv_stock_txn_line }o--o| inv_cost_layer : "cost_layer_id"
    inv_stock_balance }o--|| mdm_warehouse : "warehouse_id"
    inv_stock_balance }o--|| mdm_material : "material_id"
    inv_stock_balance }o--o| inv_batch : "batch_id"
    inv_transfer ||--o{ inv_transfer_line : "1:N"
    inv_transfer_line }o--|| mdm_material : "material_id"
    inv_stocktake_plan ||--o{ inv_stocktake : "1:N"
    inv_stocktake ||--o{ inv_stocktake_line : "1:N"
    inv_stocktake_line }o--|| mdm_material : "material_id"
    inv_reservation ||--o{ inv_reservation_line : "1:N"
    inv_cost_adjustment ||--o{ inv_cost_adjustment_line : "1:N"
    inv_batch ||--o{ inv_batch_genealogy : "parent/child"
    inv_serial }o--|| mdm_material : "material_id"
    inv_serial ||--o{ inv_serial_txn : "1:N"
    inv_period ||--o{ inv_stock_summary : "period_code"
    inv_cost_layer }o--|| mdm_material : "material_id"
```

### 1.3 排他・トランザクション方針

| 処理 | 分離レベル | 排他 | 実装 |
|---|---|---|---|
| 在庫過账 | READ COMMITTED | 残高行 `SELECT ... FOR UPDATE`、ロック順 `(warehouse_id, material_id, batch_no, stock_status, location_id)` 昇順 | [02](02-inbound-outbound.md) 6.3 |
| 在庫過账の再試行 | READ COMMITTED | デッドロック `40P01` → 最大 3 回、`lock_timeout=3s` | 同上 |
| 引当 | READ COMMITTED | 残高行 `FOR UPDATE`（引当順にロック） | [06](06-reservation-barcode-close.md) 6.2 |
| 伝票編集（草稿） | READ COMMITTED | 楽観排他（`version`） | 各画面 |
| 棚卸単生成 | READ COMMITTED | `pg_advisory_xact_lock('inv_stocktake:'||warehouse_id)` | [03](03-transfer-count.md) 6.2 |
| 月结・再計算 | REPEATABLE READ 検討 | `pg_advisory_lock('inv_close:'||company_id||':'||period_code)` | [06](06-reservation-barcode-close.md) 6.2 |
| バッチ（対账・庫齢） | READ COMMITTED | Advisory Lock（二重起動防止） | [92](92-report-batch-design.md) |

---

## 2. テーブル一覧

| # | 物理名 | 論理名 | 種別 | 主な更新元 | 件数見積（5 年） | 保存期間 | 章 |
|---|---|---|---|---|---|---|---|
| 1 | `inv_stock_balance` | 库存余额 | 残高 | 入出庫・調整 | 80,000 | 現行のみ | 4.1 |
| 2 | `inv_stock_txn` | 库存事务（头） | 伝票ヘッダ | 入出庫・調整 | 3,500 万 | 10 年 | 4.2 |
| 3 | `inv_stock_txn_line` | 库存事务明细 | 伝票明細 | 同上 | 1 億 | 10 年 | 4.3 |
| 4 | `inv_transfer` | 调拨单 | 伝票ヘッダ | F-INV-009 | 36,000 | 10 年 | 4.4 |
| 5 | `inv_transfer_line` | 调拨单明细 | 伝票明細 | F-INV-009 | 150,000 | 10 年 | 4.5 |
| 6 | `inv_stocktake_plan` | 盘点计划 | 伝票ヘッダ | F-INV-010 | 1,400 | 10 年 | 4.6 |
| 7 | `inv_stocktake` | 盘点单 | 伝票ヘッダ | F-INV-010 | 7,000 | 10 年 | 4.7 |
| 8 | `inv_stocktake_line` | 盘点单明细 | 伝票明細 | F-INV-010 | 70 万 | 10 年 | 4.8 |
| 9 | `inv_batch` | 批次主档 | マスタ | F-INV-011 | 33 万 | 無期限 | 4.9 |
| 10 | `inv_batch_genealogy` | 批次系谱 | 関連 | F-INV-011 | 140 万 | 10 年 | 4.10 |
| 11 | `inv_serial` | 序列号主档 | マスタ | F-INV-012 | 12 万 | 無期限 | 4.11 |
| 12 | `inv_serial_txn` | 序列号事务履历 | 履歴 | F-INV-012 | 60 万 | 10 年 | 4.12 |
| 13 | `inv_reservation` | 库存预留（头） | 伝票ヘッダ | F-INV-019 | 21 万 | 10 年 | 4.13 |
| 14 | `inv_reservation_line` | 库存预留明细 | 伝票明細 | F-INV-019 | 110 万 | 10 年 | 4.14 |
| 15 | `inv_cost_layer` | 成本层 | 残高/履歴 | F-INV-017 | 3,000 万 | 10 年 | 4.15 |
| 16 | `inv_cost_adjustment` | 成本调整单（头） | 伝票ヘッダ | F-INV-017 | 36,000 | 10 年 | 4.16 |
| 17 | `inv_cost_adjustment_line` | 成本调整单明细 | 伝票明細 | F-INV-017 | 140,000 | 10 年 | 4.17 |
| 18 | `inv_period` | 库存期间 | 設定 | F-INV-020 | 60 | 無期限 | 4.18 |
| 19 | `inv_stock_summary` | 收发存汇总 | 集計 | F-INV-020 | 130 万 | 10 年 | 4.19 |
| 20 | `inv_age_snapshot` | 库龄快照 | 集計 | BAT-INV-003 | 300 万 | 3 年 | 4.20 |
| 21 | `inv_replenishment` | 补货建议 | 集計 | BAT-INV-004 | 5 万 | 1 年 | 4.21 |
| 22 | `inv_scan_log` | 扫码记录 | ログ | F-INV-018 | 500 万 | 1 年 | 4.22 |
| 23 | `inv_event_wait` | 品質イベント保留 | 内部キュー | F-INV-014、BAT-INV-007 | 5 万 | 3 か月 | 4.23 |
| 24 | `inv_stock_txn_key` | 在庫事務一意キー台帳 | 内部（一意制約代替） | 過账処理 | 1 億 | 10 年 | 4.2.6 |

> 件数見積は [04 §13](../00-common/04-common-db-spec.md) の `inv_stock_txn` 1,000 万行/初期・+500 万行/年、`inv_stock_balance` 6 万行/初期と整合させた。

---

## 3. 共通カラム・型の適用

### 3.1 共通監査カラム（[01 §2](../00-common/01-common-item-definitions.md)）

```sql
-- 業務テーブル（伝票・残高・マスタ）に展開
id          BIGINT       NOT NULL,              -- 雪花 ID（MyBatis-Plus ASSIGN_ID）
tenant_id   BIGINT       NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
company_id      BIGINT        NOT NULL,
version     INT          NOT NULL DEFAULT 0,    -- 楽観排他
remark      VARCHAR(500),
ext_data    JSONB,
created_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
created_by  BIGINT       NOT NULL DEFAULT 0,
updated_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
updated_by  BIGINT       NOT NULL DEFAULT 0
```

| テーブル種別 | 付与する共通カラム |
|---|---|
| 残高・伝票・マスタ（1〜21 のうちログ/集計以外） | 全項目（`deleted` は**付けない**。伝票は取消ステータスで管理） |
| 履歴・ログ（`inv_serial_txn`、`inv_scan_log`、`inv_batch_genealogy`） | `id, tenant_id, company_id, created_at, created_by` のみ（追記専用） |
| 集計・スナップショット（`inv_stock_summary`、`inv_age_snapshot`、`inv_replenishment`） | `version` 不要。`created_at/created_by/updated_at/updated_by` |

### 3.2 型の適用

| 用途 | 型 | 例 |
|---|---|---|
| 数量 | `NUMERIC(18,4)` | `qty_on_hand`、`qty` |
| 金額 | `NUMERIC(18,2)` | `amount_on_hand`、`amount` |
| 単価・平均単価 | `NUMERIC(18,6)` | `avg_unit_cost`、`unit_cost` |
| 状態・区分 | `SMALLINT` | `stock_status`、`txn_status` |
| 事务種別 | `VARCHAR(16)` | `txn_type`（`PI`〜`ST_OUT` の 19 種） |
| 業務日付 | `DATE` | `txn_date`、`expiry_date` |
| 日時 | `TIMESTAMPTZ` | `posted_at`、`snapshot_at` |
| 期間 | `VARCHAR(7)` | `period_code`（`2026-10`） |
| 拡張・スコープ | `JSONB` | `scope_json`、`check_result` |

> **金額・数量に `FLOAT/DOUBLE` を使用しない**（[04 §4](../00-common/04-common-db-spec.md)）。

### 3.3 命名・索引・制約の方針

- 索引：`idx_{table}_{cols}`（B-Tree）、`uk_{table}_{cols}`（一意）、`ck_{table}_{意味}`（CHECK）。部分索引 `WHERE` を活用する。
- 一意制約：伝票は `(company_id, {伝票番号})`、残高は次元の全列、明細は親 + 行番号・次元。
- **入庫検査**：明細 `inspection_flag BOOLEAN NOT NULL` は入庫点で收窄スナップショット（`PI`/`OSR`：`inspection_stage∈{10,40}`；`FGI`：`∈{30,40}`；他は false）。**true→stock_status=10、false→直入 20**。合格（E15）後は 10→20（ST_OUT+ST_IN）。CHECK `ck_inv_stock_txn_line_insp_inbound`。詳しくは [02 §2.6.1a](02-inbound-outbound.md)。
- **冗余 txn_type**：明細に表頭と同一の `txn_type NOT NULL` を持ち、書込時トリガーで表頭一致を検証（[04](../00-common/04-common-db-spec.md) 8.1）。`direction` は `txn_type` から一意決定しアプリ＋CHECK で二重制約。
- CHECK：状態値（`stock_status`/`txn_status` 等）、`txn_type`、符号（数量 > 0、残高 ≥ 0）、方向（`direction IN (1,-1)`）に付与する。
- コメント：全テーブル・全列に `COMMENT ON` を付与する（本文件では代表例を記載し、実装時に全列へ展開する）。

### 3.4 RLS・複合 FK 用一意キー・迁移共通テンプレート（2026-10-21 追補）

06/07 の迁移（`prd/V202610210702`、`fin/V202610210706`）と同じ形で、**本章の全 24 表**に以下を適用する（表ごとの DDL では省略）。

```sql
ALTER TABLE inv_xxx ENABLE ROW LEVEL SECURITY;
ALTER TABLE inv_xxx FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON inv_xxx
    USING (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
```

- パーティション表 `inv_stock_txn` は親表に ENABLE/FORCE とポリシーを付ける。**子パーティション（初回 25 個：2026-01〜2027-12 + DEFAULT）にも ENABLE/FORCE RLS とポリシーを付け、`REVOKE ALL ON <子> FROM erp_app` で直接アクセスを禁止する**（`erp_app` は親表経由のみ。`RlsCoverageTest` は relkind='r' の子表も対象）。
- 以降の月次パーティションは**月次パーティション作成関数**（`inv_` 接頭辞、`SECURITY INVOKER`、関数名は #55 迁移に従う）でのみ作成し、同関数が作成と同一 TX で ENABLE/FORCE RLS・ポリシー付与・`REVOKE ALL FROM erp_app` を行う。pgTAP で新規作成分区の RLS 有効と `erp_app` 無権限を断言する（蓝色大肥鱼 2026-10-21 決定、PR #55）。
- `erp_app` の DML 権限は `sys/V202610200101` の `ALTER DEFAULT PRIVILEGES` で自動付与されるため、迁移で GRANT を書かない。
- **同域親子 FK の被参照表**には `CONSTRAINT uk_<table>_tenant_company_id UNIQUE (tenant_id, company_id, id)` を付ける（業務一意キーではない。PR #43 `sys/V202610211401` の規則）。本域の対象：`inv_transfer`、`inv_stocktake_plan`、`inv_stocktake`、`inv_serial`、`inv_reservation`、`inv_cost_adjustment`。
- `uk_<table>_tenant_id UNIQUE (tenant_id, id)` は**他域から複合 FK で参照される表にのみ**付ける（[04 §6.2](../00-common/04-common-db-spec.md)）。本域の表を他域が硬 FK で参照する計画はないため、本域では 0 件。
- `tenant_id` 既定値は `current_setting('app.tenant_id')::bigint` のみ（固定値の既定は `scripts/check-tenant-default.sh` が拒否）。`company_id` は既定値なし。

---

## 4. テーブル定義

### 4.1 `inv_stock_balance` 库存余额

| 項目 | 内容 |
|---|---|
| テーブル物理名 | `inv_stock_balance` |
| テーブル論理名 | 库存余额（在庫残高） |
| 種別 | 残高 |
| 更新元機能 | F-INV-002〜010、014、017、019（引当数量） |
| データ量見積 | 初期 6 万 / 5 年後 8 万 |
| 保存期間 | 現行のみ（履歴は `inv_stock_txn`） |
| 備考 | 1 行 = 1「倉庫×物料×批次×状態×庫位」の現在残高。**更新は本域の過账処理のみ** |

#### 4.1.1 概要

倉庫・庫位・物料・批次・在庫状態の組み合わせごとの現在数量・金額・平均単価を持つ。在庫状態を一意キーに含むため、待検・凍結・不合格は別行となる。`avg_unit_cost` は同一 `(warehouse_id, material_id, batch_id)` の全行で同一値（[05](05-costing.md) 1.2）。

#### 4.1.2 DDL

```sql
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
```

#### 4.1.3 項目定義

| No | 物理名 | 論理名 | 型/桁 | NULL | PK | FK/参照先 | 既定値 | 備考 |
|---|---|---|---|---|---|---|---|---|
| 1 | `id` | 主キー | BIGINT | NOT NULL | ○ | — | アプリ採番 | 雪花 ID |
| 2 | `tenant_id` | 租户 ID | BIGINT | NOT NULL | — | — | current_setting(app.tenant_id) | 禁止写死的默认租户 |
| 3 | `company_id` | 公司 ID | BIGINT | NOT NULL | — | — | — | — |
| 4 | `warehouse_id` | 倉庫 ID | BIGINT | NOT NULL | — | `mdm_warehouse.id`（論理参照） | — | — |
| 5 | `location_id` | 庫位 ID | BIGINT | NOT NULL | — | `mdm_warehouse_bin.id`（論理参照） | 0 | 0=库位未管理 |
| 6 | `material_id` | 物料 ID | BIGINT | NOT NULL | — | `mdm_material.id`（論理参照） | — | — |
| 7 | `batch_id` | 批次 ID | BIGINT | NOT NULL | — | `inv_batch.id` | 0 | 0=非批次管理 |
| 8 | `batch_no` | 批次号 | VARCHAR(64) | NOT NULL | — | — | '' | ロック順序・照会用の冗長列 |
| 9 | `stock_status` | 在庫状態 | SMALLINT | NOT NULL | — | — | — | 10/20/30/40/50（[00-overview](00-overview.md) 2.2） |
| 10 | `qty_on_hand` | 現存数量 | NUMERIC(18,4) | NOT NULL | — | — | 0 | ≥ 0（DB CHECK） |
| 11 | `qty_reserved` | 引当数量 | NUMERIC(18,4) | NOT NULL | — | — | 0 | 0 ≤ reserved ≤ on_hand |
| 12 | `amount_on_hand` | 在庫金額 | NUMERIC(18,2) | NOT NULL | — | — | 0 | ≥ 0 |
| 13 | `avg_unit_cost` | 平均単価 | NUMERIC(18,6) | NOT NULL | — | — | 0 | 同一 cost group で同値 |
| 14 | `last_txn_date` | 最終取引日 | DATE | NULL | — | — | NULL | 遡及チェックに使用 |
| 15 | `last_txn_id` | 最終取引 ID | BIGINT | NULL | — | `inv_stock_txn.id` | NULL | — |
| 16 | `version` | 楽観排他版数 | INT | NOT NULL | — | — | 0 | — |
| 17 | `remark` | 備考 | VARCHAR(500) | NULL | — | — | NULL | — |
| 18 | `ext_data` | 拡張項目 | JSONB | NULL | — | — | NULL | — |
| 19-24 | `created_at/created_by/updated_at/updated_by` | 監査カラム | — | NOT NULL | — | — | 既定 | [01 §2](../00-common/01-common-item-definitions.md) |

#### 4.1.4 制約・整合性

| 制約 ID | 内容 | 実現方法 |
|---|---|---|
| UK-01 | 倉庫×物料×批次×状態×庫位で一意 | `uk_inv_stock_balance_key` |
| CK-01 | 状態は 10/20/30/40/50 | `ck_inv_stock_balance_status` |
| CK-02 | 数量・引当・金額・単価は非負、引当 ≤ 現存 | `ck_inv_stock_balance_qty`、`ck_inv_stock_balance_amount`、`ck_inv_stock_balance_avg` |
| IV-01 | 同一 cost group の `avg_unit_cost` は全行同値 | アプリ層（過账時に一括更新）+ [BAT-INV-002](92-report-batch-design.md) |
| IV-02 | `Σ inv_stock_balance.qty_on_hand`（cost group）= `Σ inv_cost_layer.remaining_qty` | バッチ検証（差異でアラート） |
| IV-03 | `Σ amount_on_hand` = `Σ inv_cost_layer.remaining_amount` | 同上 |

#### 4.1.5 更新仕様

| 操作 | 契機 | 更新項目 | 備考 |
|---|---|---|---|
| INSERT | 過账時に残高行が無い場合 | 全項目（0 初期値 + 初回変動） | `INSERT ... ON CONFLICT DO NOTHING` → 再 SELECT FOR UPDATE |
| UPDATE | 入出庫・状態変換・沖销 | `qty_on_hand, qty_reserved, amount_on_hand, avg_unit_cost, last_txn_date, last_txn_id, version` | ロック順序を厳守 |
| DELETE | なし | — | 残高 0 でも行は保持（[01](01-stock-query.md) 未決 #3） |

---

### 4.2 `inv_stock_txn` 库存事务（头）

| 項目 | 内容 |
|---|---|
| テーブル論理名 | 库存事务（在庫取引） |
| 種別 | 伝票ヘッダ |
| 更新元機能 | F-INV-002〜010、014、F-INV-017（沖销） |
| データ量見積 | 初期 1,000 万 / 年間 +500 万 / 5 年後 3,500 万 |
| 保存期間 | 10 年（[08 §12](../00-common/08-common-business-rules.md)） |
| 備考 | 1 行 = 1 業務伝票（GRI/SDO/MII/MIR/FGI/OSI/OSR/TR/CNT/AOI/AOO/ST）。月次パーティションは 第一版 |

#### 4.2.1 概要

在庫の数量・金額・状態を変動させる**すべての事実**を記録する伝票ヘッダ。`txn_type` は [09 §7.1](../00-common/09-cross-domain-flow.md) の 19 種のみ。来源（`source_type + source_id`）と一意制約により二重計上を防ぐ。過账後は数量・金額を変更せず、訂正は沖销（`is_reversal=true` の反向事務）で行う。

#### 4.2.2 DDL

```sql
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
        -- 三値論理対策で IS NOT NULL を明示（NULL 原因の AOI を拒否、蓝色大肥鱼 2026-10-21 決定、PR #55）
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
-- 月次パーティション：inv_stock_txn_yYYYYmMM（例 inv_stock_txn_y2026m10）。初回迁移で 2026-01〜2027-12 と DEFAULT パーティションを作成し、
-- 以降は月次ジョブ（sys_scheduled_job）が月次パーティション作成関数で 3 か月先まで事前作成する（第 10 章 #7）。
-- 同関数は新分区に ENABLE/FORCE RLS・ポリシーを付け、erp_app から REVOKE ALL する（§3.4、蓝色大肥鱼 2026-10-21 決定）。

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
```

#### 4.2.3 項目定義

| No | 物理名 | 論理名 | 型/桁 | NULL | PK | FK/参照先 | 既定値 | 備考 |
|---|---|---|---|---|---|---|---|---|
| 1 | `id` | 主キー | BIGINT | NOT NULL | ○ | — | アプリ採番 | — |
| 2-3 | `tenant_id`/`company_id` | — | BIGINT | NOT NULL | — | — | current_setting / 无 DEFAULT | — |
| 4 | `txn_no` | 事務番号 | VARCHAR(32) | NOT NULL | — | `sys_sequence` | — | 一意（`uk_inv_stock_txn_no`） |
| 5 | `txn_type` | 事務種別 | VARCHAR(16) | NOT NULL | — | — | — | 19 種（CHECK） |
| 6 | `txn_date` | 事務日 | DATE | NOT NULL | — | — | — | 遡及禁止・期間 OPEN |
| 7 | `factory_id` | 工場 ID | BIGINT | NOT NULL | — | `mdm_factory.id`（論理参照） | — | 倉庫の工場 |
| 8 | `warehouse_id` | 倉庫 ID | BIGINT | NOT NULL | — | `mdm_warehouse.id` | — | 1 事務 1 倉庫 |
| 9 | `source_type` | 来源種別 | VARCHAR(32) | NOT NULL | — | — | — | 入庫過账：`PURCHASE_RECEIPT`/`OUTSOURCING_ORDER`/`PRODUCTION_COMPLETION`；状態変換：`INSPECTION`；他：`SALES_DELIVERY`/`WORK_ORDER`/`TRANSFER`/`STOCKTAKE`/`SALES_RETURN`/`PURCHASE_RETURN`/`MANUAL` |
| 10 | `source_id` | 来源 ID | BIGINT | NULL | — | — | NULL | 来源伝票の ID |
| 11 | `source_no` | 来源番号 | VARCHAR(32) | NULL | — | — | NULL | 来源伝票の番号 |
| 12 | `partner_type` | 相手種別 | SMALLINT | NOT NULL | — | — | 0 | 0 なし/1 仕入先/2 顧客/3 部門/4 その他 |
| 13 | `partner_id` | 相手 ID | BIGINT | NULL | — | — | NULL | — |
| 14 | `partner_name` | 相手名称 | VARCHAR(200) | NULL | — | — | NULL | **スナップショット** |
| 15 | `biz_module` | 来源モジュール | VARCHAR(16) | NULL | — | — | NULL | PUR/SAL/PRD/INV |
| 16 | `reference_txn_no` | 関連事務番号 | VARCHAR(32) | NULL | — | — | NULL | TR_OUT⇔TR_IN 等 |
| 17 | `pair_key` | 対グループ | VARCHAR(64) | NULL | — | — | NULL | ST_OUT+ST_IN、同倉移庫の TR 対 |
| 18 | `is_reversal` | 沖销フラグ | BOOLEAN | NOT NULL | — | — | FALSE | 沖销事務で TRUE |
| 19 | `reversal_of_txn_id` | 沖销元 ID | BIGINT | NULL | — | `inv_stock_txn.id` | NULL | 一意（1 事務 1 沖销） |
| 20 | `reversed_txn_id` | 沖销先 ID | BIGINT | NULL | — | `inv_stock_txn.id` | NULL | 元事務に保持 |
| 21 | `reverse_reason` | 沖销理由 | VARCHAR(500) | NULL | — | — | NULL | 沖销時必須 |
| 22-23 | `reversed_at/reversed_by` | 沖销日時/者 | TIMESTAMPTZ/BIGINT | NULL | — | — | NULL | — |
| 24 | `txn_status` | 事務状態 | SMALLINT | NOT NULL | — | — | 10 | 10/20/25/30/90 |
| 25-26 | `posted_at/posted_by` | 過账日時/者 | TIMESTAMPTZ/BIGINT | NULL | — | — | NULL | 過账時に設定 |
| 27 | `currency_code` | 通貨 | VARCHAR(3) | NOT NULL | — | `mdm_currency` | CNY | 当面は CNY |
| 28 | `accounting_period` | 会計期間 | VARCHAR(7) | NOT NULL | — | — | — | `txn_date` から導出 |
| 29 | `total_qty` | 合計数量 | NUMERIC(18,4) | NOT NULL | — | — | 0 | 明細合計 |
| 30 | `total_amount` | 合計金額 | NUMERIC(18,2) | NOT NULL | — | — | 0 | 明細合計 |
| 31-36 | `version`/`remark`/`ext_data`/監査 | — | — | — | — | — | — | — |
| 37 | `source_event_at` | 原本業務日時 | TIMESTAMPTZ | NULL | — | — | NULL | 遅延イベントの業務日付（`txn_date` と分離、BR-16） |
| 38 | `reason_type` | 原因区分 | SMALLINT | NULL | — | — | NULL | AOI：10/20/30/40/50/60（02 §2.6.6）、AOO/SC_OUT：02 §2.6.7 の区分。他種別は NULL（CHECK） |
| 39 | `work_order_id` | 工单 ID | BIGINT | NULL | — | `prd_work_order.id`（软引用） | NULL | MII/MIR/FGI/OSI/OSR。`source_id` は PRD の要求 ID（`issueId`/`returnId`/`receiptId`、02 §2.7）であり工单 ID ではない |
| 40 | `sales_order_line_id` | 受注明細 ID | BIGINT | NULL | — | `sal_sales_order_line.id`（软引用） | NULL | MTO 工单のみ（`prd_work_order.sales_order_line_id` のスナップショット）。分批法の受注別集計用 |

#### 4.2.4 制約・整合性

| 制約 ID | 内容 | 実現方法 |
|---|---|---|
| UK-01 | 事務番号は公司内一意 | `inv_stock_txn_key`（`key_type='TXN_NO'`）。`uk_inv_stock_txn_no` はパーティション内一意のみ |
| UK-02 | 同一来源・同一種別の**過账済**は 1 件のみ（二重計上防止、[09 §10.2](../00-common/09-cross-domain-flow.md)）。**`source_type='TRANSFER'` は対象外**（部分受入で `TR_IN` が複数、[03 §6.4](03-transfer-count.md)） | `inv_stock_txn_key`（`key_type='SOURCE_POSTED'`） |
| UK-03 | 1 事務は 1 回しか沖销できない | `inv_stock_txn_key`（`key_type='REVERSAL'`） |
| UK-04 | 状態変換・同倉移庫の対は `pair_key`×`txn_type` で 1 件 | `inv_stock_txn_key`（`key_type='PAIR'`） |
| CK-04 | 来源種別は 11 種のみ | `ck_inv_stock_txn_source` |
| CK-05 | 原因区分は AOI/AOO/SC_OUT で必須（NULL 不可）：AOI/AOO は 10〜60、SC_OUT は 10〜50（[02 §2.6.6/2.6.7](02-inbound-outbound.md)）。その他 16 種は NULL のみ。AOI で NULL は 23514（pgTAP） | `ck_inv_stock_txn_reason` |
| CK-01 | 種別は 19 種のみ | `ck_inv_stock_txn_type` |
| CK-02 | 状態は 10/20/25/30/90 | `ck_inv_stock_txn_status` |
| CK-03 | 沖销事務は必ず沖销元を持つ | `ck_inv_stock_txn_reversal` |
| IV-01 | `total_qty/total_amount = Σ明細` | アプリ層 + 日次対账 |
| IV-02 | `txn_status=30` の事務のみ残高に反映 | アプリ層（過账TX） |

#### 4.2.5 更新仕様

| 操作 | 契機 | 更新項目 |
|---|---|---|
| INSERT | 入出庫/調整/状態変換の登録・イベント受信 | 全項目（`txn_status=10`、採番済） |
| UPDATE | 承認提出/コールバック | `txn_status=20/25`、`version` |
| UPDATE | 過账 | `txn_status=30, posted_at, posted_by, total_qty, total_amount, version` |
| UPDATE | 沖销（元事務） | `txn_status=90, reversed_at, reversed_by, reverse_reason, reversed_txn_id, version` |
| INSERT | 沖销（反向事務） | 全項目（`is_reversal=true`、`reversal_of_txn_id`） |
| DELETE | **禁止** | — |

#### 4.2.6 `inv_stock_txn_key` 在庫事務一意キー台帳（第 10 章 #7 決定済）

パーティション表では `(tenant_id, company_id, txn_no)` 等の全期間一意を索引で保証できない（一意索引に `txn_date` が必要）。過账 TX 内で本表に先に INSERT し、一意違反（23505）を二重計上・二重沖销として扱う。非パーティション・追記専用。

```sql
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
CREATE UNIQUE INDEX uk_inv_stock_txn_key ON inv_stock_txn_key (tenant_id, company_id, key_type, key_value);
CREATE INDEX idx_inv_stock_txn_key_txn ON inv_stock_txn_key (tenant_id, company_id, txn_id);
COMMENT ON TABLE inv_stock_txn_key IS '在庫事務の全期間一意キー台帳（パーティション表 inv_stock_txn の代替一意制約）';
```

| 操作 | 契機 | 内容 |
|---|---|---|
| INSERT | 採番時 | `TXN_NO` |
| INSERT | 過账時（`txn_status→30`、`is_reversal=false`、`source_id IS NOT NULL` かつ `source_type<>'TRANSFER'`） | `SOURCE_POSTED` |
| INSERT | 沖销事務の登録 | `REVERSAL` |
| INSERT | ST/同倉移庫対の過账 | `PAIR` |
| DELETE | 元事務の沖销時に同じ TX で `SOURCE_POSTED` を削除（再過账を許可）。他は禁止 | — |

---

### 4.3 `inv_stock_txn_line` 库存事务明细

| 項目 | 内容 |
|---|---|
| テーブル論理名 | 库存事务明细 |
| 種別 | 伝票明細 |
| 更新元機能 | 4.2 と同じ |
| データ量見積 | 初期 3,000 万 / 年間 +1,500 万 / 5 年後 1 億 |
| 保存期間 | 10 年 |
| 備考 | 1 行 = 1「倉庫×物料×批次×状態×庫位」の変動。序列号管理品は 1 行 = 1 個 |

#### 4.3.1 DDL

```sql
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
```

#### 4.3.2 項目定義（主要項目）

| No | 物理名 | 論理名 | 型 | NULL | 備考 |
|---|---|---|---|---|---|
| 1 | `id` | 主キー | BIGINT | NOT NULL | — |
| 4 | `txn_id` | 事務 ID | BIGINT | NOT NULL | **FK なし**（`inv_stock_txn` はパーティション表）。トリガー `trg_inv_stock_txn_line_head` で表頭存在を検証 |
| 5 | `line_no` | 行番号 | INT | NOT NULL | 10 刻み |
| 6-9 | `material_id/code/name/spec` | 物料 | — | NOT NULL | **スナップショット** |
| 10 | `uom_code` | 単位 | VARCHAR(16) | NOT NULL | 基本単位（`mdm_uom.uom_code` と同桁） |
| 11 | `qty` | 数量 | NUMERIC(18,4) | NOT NULL | > 0（CHECK）。方向は `direction` |
| 12 | `direction` | 方向 | SMALLINT | NOT NULL | +1/-1（CHECK）。`txn_type` から決定 |
| 13-14 | `batch_id/batch_no` | 批次 | BIGINT/VARCHAR | NOT NULL | 非批次は 0/'' |
| 15 | `stock_status` | 在庫状態 | SMALLINT | NOT NULL | 変動対象の状態。入庫かつ inspection_flag=true なら 10 |
| 15a | `inspection_flag` | 検査要否 | BOOLEAN | NOT NULL | スナップショット。PI/OSR:`stage∈{10,40}`；FGI:`∈{30,40}`。ON→10 / OFF→20 |
| 15b | `txn_type` | 事務種別（冗余） | VARCHAR(16) | NOT NULL | 表頭と一致（トリガー検証） |
| 16 | `location_id` | 庫位 | BIGINT | NOT NULL | 0=未管理 |
| 17 | `unit_cost` | 単価 | NUMERIC(18,6) | NULL | 入庫原価単価/出庫平均単価。草稿時 NULL |
| 18 | `amount` | 金額 | NUMERIC(18,2) | NULL | — |
| 18a | `valuation_method` | 計価方法 | SMALLINT | NOT NULL | `mdm_material.valuation_method` スナップショット（10 移動平均／20 標準原価、[08 §6](../00-common/08-common-business-rules.md) 計価方法） |
| 18b | `std_unit_cost` | 標準単価 | NUMERIC(18,6) | NULL | 20 のみ。過账時に `fin_standard_cost`（`status=40`、`txn_date` が適用期間内）から取得。未発行なら過账拒否 |
| 18c | `variance_amount` | 原価差異 | NUMERIC(18,2) | NOT NULL | 20 の入庫行のみ：`実際原価 − std_unit_cost × qty`。在庫は標準で計上し差異は E18 で FIN へ |
| 19-22 | `purchase/freight/duty/other_amount` | 原価構成 | NUMERIC(18,2) | NOT NULL | 入庫時のみ値、他は 0 |
| 23-27 | `before_*/after_*` | 前後スナップショット | — | NULL | 監査・原価追跡用 |
| 28 | `cost_layer_id` | 原価層 ID | BIGINT | NULL | 入庫時に対応層 |
| 29-30 | `serial_id/serial_no` | 序列号 | BIGINT/VARCHAR | NULL | 序列号管理品のみ |
| 31-32 | `source_line_id/source_line_no` | 来源行 | BIGINT/INT | NULL | 部分入出庫の対応付け |
| 33 | `remark` | 備考 | VARCHAR(500) | NULL | — |

#### 4.3.3 更新仕様

| 操作 | 契機 | 內容 |
|---|---|---|
| INSERT | 伝票登録・過账 | 全項目。**明細は INSERT のみ（insert-only）**：原価・前後スナップショット・`cost_layer_id` は過账 TX 内で確定してから INSERT する |
| UPDATE | — | **禁止**。過账・取消で変わる状態（`txn_status`・`posted_*`）と `version` は表頭 `inv_stock_txn` のみを更新する。そのため明細には `version`・`updated_at`・`updated_by` を持たない（蓝色大肥鱼 2026-10-21 決定、PR #55） |
| — | 沖销 | 反向事務（表頭＋明細）を INSERT |
| DELETE | **禁止** | — |

---

### 4.4 `inv_transfer` 调拨单

| 項目 | 内容 |
|---|---|
| テーブル論理名 | 库存调拨单 |
| 種別 | 伝票ヘッダ |
| 更新元機能 | F-INV-009 |
| データ量見積 | 初期 5,000 / 年間 +6,000 / 5 年後 36,000 |
| 保存期間 | 10 年 |

```sql
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
CREATE UNIQUE INDEX uk_inv_transfer_no ON inv_transfer (tenant_id, company_id, transfer_no);
CREATE INDEX idx_inv_transfer_status ON inv_transfer (tenant_id, company_id, transfer_status, transfer_date DESC);
CREATE INDEX idx_inv_transfer_from_wh ON inv_transfer (tenant_id, company_id, from_warehouse_id, transfer_date DESC);
CREATE INDEX idx_inv_transfer_to_wh ON inv_transfer (tenant_id, company_id, to_warehouse_id, transfer_date DESC);
CREATE INDEX idx_inv_transfer_intransit ON inv_transfer (tenant_id, company_id, transfer_date)
    WHERE transfer_status IN (30, 35);
COMMENT ON TABLE inv_transfer IS '库存调拨单（同倉移庫・跨倉調撥・在途管理）';
COMMENT ON COLUMN inv_transfer.in_transit_qty IS '出庫済・未受入の数量（= Σ line.qty - received_qty）';
```

**主要項目**：`transfer_no`（TR＋YYMMDD＋4、一意）、`transfer_type`（10/20/30）、`transfer_status`（10 草稿/20 承認待ち/25 承認済/30 出庫済（在途）/35 一部受入/40 受入完了/90 取消）、`from/to_warehouse_id`（種別 10 は同一、20/30 は相違の CHECK）、`in_transit_qty`（在途量）、`shipped_at/received_at`。

**更新仕様**：登録（草稿）→ 承認（`approval_status`/`transfer_status=25`）→ 出庫（`30`、`TR_OUT` 生成）→ 受入（`35`/`40`、`TR_IN` 生成）→ 取消（`90`、出庫前のみ）。

---

### 4.5 `inv_transfer_line` 调拨单明细

| 項目 | 内容 |
|---|---|
| 種別 | 伝票明細 |
| データ量見積 | 初期 2 万 / 年間 +2.5 万 / 5 年後 15 万 |

```sql
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
CREATE UNIQUE INDEX uk_inv_transfer_line_no ON inv_transfer_line (tenant_id, company_id, transfer_id, line_no);
CREATE INDEX idx_inv_transfer_line_material ON inv_transfer_line (tenant_id, company_id, material_id);
COMMENT ON TABLE inv_transfer_line IS '库存调拨单明细。金額保存則 ΣTR_OUT.amount = ΣTR_IN.amount（04 §7）';
```

**整合性**：`in_transit_qty = shipped_qty − received_qty − returned_qty`（アプリ層で更新）。`unit_cost` は `TR_OUT` 過账時に確定し、`TR_IN` は引継ぐ。

---

### 4.6 `inv_stocktake_plan` 盘点计划

| 項目 | 内容 |
|---|---|
| 種別 | 伝票ヘッダ |
| 更新元機能 | F-INV-010 |
| データ量見積 | 初期 200 / 年間 +240 / 5 年後 1,400 |

```sql
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
CREATE UNIQUE INDEX uk_inv_stocktake_plan_no ON inv_stocktake_plan (tenant_id, company_id, plan_no);
CREATE INDEX idx_inv_stocktake_plan_wh ON inv_stocktake_plan (tenant_id, company_id, warehouse_id, plan_status);
COMMENT ON TABLE inv_stocktake_plan IS '盘点计划（全盤/循環/抽盤/重点）。scope_json に対象範囲を保持';
COMMENT ON COLUMN inv_stocktake_plan.scope_json IS 'JSON: {"categoryCodes":[],"materialIds":[],"locationIds":[],"stockStatuses":[10,20,30,40,50]}';
```

**更新仕様**：草稿 → 承認（WF）→ 实施中（`30`）→ 完了（`40`）/取消（`90`）。同一倉庫の未完了計画は 1 件のみ（アプリ検査 + `BAT-INV-001` チェック）。

---

### 4.7 `inv_stocktake` 盘点单

| 項目 | 内容 |
|---|---|
| 種別 | 伝票ヘッダ |
| 更新元機能 | F-INV-010 |
| データ量見積 | 初期 1,000 / 年間 +1,200 / 5 年後 7,000 |

```sql
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
CREATE UNIQUE INDEX uk_inv_stocktake_no ON inv_stocktake (tenant_id, company_id, stocktake_no);
CREATE INDEX idx_inv_stocktake_wh_status ON inv_stocktake (tenant_id, company_id, warehouse_id, take_status);
CREATE INDEX idx_inv_stocktake_open ON inv_stocktake (tenant_id, company_id, warehouse_id)
    WHERE take_status IN (10,20,30,35);
COMMENT ON TABLE inv_stocktake IS '盘点单（账面スナップショット・実盤・差異・承認・調整）';
COMMENT ON COLUMN inv_stocktake.snapshot_txn_id IS 'スナップショット時点の最終在庫事務 ID。差異計算の期間変動還元に使用（03 §6.2）';
```

**更新仕様**：生成（`10`）→ 実盤開始（`20`）→ 差異計算（`30`）→ 提出/承認待ち（`35`）→ 承認・調整（`40`）/取消（`90`）。`diff_amount` は差異金額の**絶対値合計**（承認閾値判定用、[08 §8.1](../00-common/08-common-business-rules.md)）。

---

### 4.8 `inv_stocktake_line` 盘点单明细

| 項目 | 内容 |
|---|---|
| 種別 | 伝票明細 |
| データ量見積 | 初期 10 万 / 年間 +12 万 / 5 年後 70 万 |

```sql
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
CREATE UNIQUE INDEX uk_inv_stocktake_line_key
    ON inv_stocktake_line (tenant_id, company_id, stocktake_id, material_id, batch_id, stock_status, location_id);
CREATE INDEX idx_inv_stocktake_line_diff
    ON inv_stocktake_line (tenant_id, company_id, stocktake_id) WHERE diff_qty IS NOT NULL AND diff_qty <> 0;
COMMENT ON TABLE inv_stocktake_line IS '盘点单明细。1 行 = 倉庫×物料×批次×状態×庫位';
COMMENT ON COLUMN inv_stocktake_line.net_movement IS 'スナップショット後の純変動（direction×qty 合計）。差異 = final_qty - (book_qty + net_movement)';
```

**更新仕様**：生成時 INSERT（`book_qty` スナップショット）、実盤入力（`counted_qty`/`re_counted_qty`）、差異計算（`final_qty, diff_qty, diff_amount`）、調整（`adjust_txn_line_id`）。

---

### 4.9 `inv_batch` 批次主档

| 項目 | 内容 |
|---|---|
| 種別 | マスタ |
| 更新元機能 | F-INV-011 |
| データ量見積 | 初期 5 万 / 年間 +6 万 / 5 年後 33 万 |
| 保存期間 | 無期限（参照用） |

```sql
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
CREATE UNIQUE INDEX uk_inv_batch_material_no ON inv_batch (tenant_id, company_id, material_id, batch_no);
CREATE INDEX idx_inv_batch_expiry ON inv_batch (tenant_id, company_id, expiry_date, batch_status)
    WHERE expiry_date IS NOT NULL;
CREATE INDEX idx_inv_batch_supplier_lot ON inv_batch (tenant_id, company_id, supplier_batch_no)
    WHERE supplier_batch_no IS NOT NULL;
COMMENT ON TABLE inv_batch IS '批次主档（批号・種別・有效期・QC 状態）';
COMMENT ON COLUMN inv_batch.supplier_batch_no IS '供給者ロット番号（BN-LOT 形式を推奨。90-data/code-lists/batch-number-rule.csv）';
```

**更新仕様**：入庫時に INSERT（採番・有效期算出）、QC 判定（E15）で `qc_status` 更新、残高 0 で `batch_status=40`（日次バッチ）。

---

### 4.10 `inv_batch_genealogy` 批次系谱

| 項目 | 内容 |
|---|---|
| 種別 | 関連（履歴） |
| 更新元機能 | F-INV-011（FGI/OSR 過账時） |
| データ量見積 | 初期 20 万 / 年間 +25 万 / 5 年後 140 万 |
| 保存期間 | 10 年 |
| 備考 | 追記専用。批次追溯の中核 |

```sql
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
CREATE UNIQUE INDEX uk_inv_batch_genealogy_key
    ON inv_batch_genealogy (tenant_id, company_id, parent_batch_id, child_batch_id, source_txn_line_id)
    NULLS NOT DISTINCT;   -- source_txn_line_id が NULL（期初・手工調整）でも同一キーの二重登録を拒否（PG15+、蓝色大肥鱼 2026-10-21 決定）
CREATE INDEX idx_inv_batch_genealogy_child ON inv_batch_genealogy (tenant_id, company_id, child_batch_id);
CREATE INDEX idx_inv_batch_genealogy_parent ON inv_batch_genealogy (tenant_id, company_id, parent_batch_id);
CREATE INDEX idx_inv_batch_genealogy_wo ON inv_batch_genealogy (tenant_id, company_id, work_order_id)
    WHERE work_order_id IS NOT NULL;
COMMENT ON TABLE inv_batch_genealogy IS '批次系譜（父批次→子批次）。前向/後向追溯に使用';
```

---

### 4.11 `inv_serial` 序列号主档

| 項目 | 内容 |
|---|---|
| 種別 | マスタ |
| 更新元機能 | F-INV-012 |
| データ量見積 | 初期 2 万 / 年間 +2 万 / 5 年後 12 万 |
| 保存期間 | 無期限 |

```sql
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
```

**更新仕様**：入庫時 INSERT（`10 在庫`）、出庫時に `20 已出庫` + 顧客・出荷日、返品で `30 已退回` → 良品 `10`／不良 `40`、報廃 `40`、凍結 `50`。履歴は `inv_serial_txn`。

### 4.12 `inv_serial_txn` 序列号事务履历

| 項目 | 内容 |
|---|---|
| 種別 | 履歴（追記専用） |
| 更新元機能 | F-INV-012 |
| データ量見積 | 初期 10 万 / 年間 +10 万 / 5 年後 60 万 |

```sql
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
CREATE INDEX idx_inv_serial_txn_serial ON inv_serial_txn (tenant_id, company_id, serial_id, txn_date DESC);
CREATE INDEX idx_inv_serial_txn_txn ON inv_serial_txn (tenant_id, company_id, txn_id);
COMMENT ON TABLE inv_serial_txn IS '序列号状態変化履歴。追記専用';
```

---

### 4.13 `inv_reservation` 库存预留（头）

| 項目 | 内容 |
|---|---|
| 種別 | 伝票ヘッダ |
| 更新元機能 | F-INV-019 |
| データ量見積 | 初期 3 万 / 年間 +3.6 万 / 5 年後 21 万 |

```sql
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
CREATE UNIQUE INDEX uk_inv_reservation_no ON inv_reservation (tenant_id, company_id, reservation_no);
CREATE UNIQUE INDEX uk_inv_reservation_source
    ON inv_reservation (tenant_id, company_id, source_type, source_id)
    WHERE reservation_status <> 90;
CREATE INDEX idx_inv_reservation_expire
    ON inv_reservation (tenant_id, company_id, expire_date)
    WHERE reservation_status IN (10,20,35);
COMMENT ON TABLE inv_reservation IS '库存预留（引当）ヘッダ。受注/工单単位';
COMMENT ON COLUMN inv_reservation.reservation_status IS '10有効(RESERVED)/20不足(SHORTAGE)/35一部消耗/40完了/90已释放(RELEASED)。E09 の status と対応';
```

**更新仕様**：E06/E21 で INSERT、E07 で数量調整（`source_version`）、出庫で `35/40`、E08/期限切れ/手動で `90`。

---

### 4.14 `inv_reservation_line` 库存预留明细

| 項目 | 内容 |
|---|---|
| 種別 | 伝票明細 |
| データ量見積 | 初期 15 万 / 年間 +18 万 / 5 年後 110 万 |

```sql
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
CREATE UNIQUE INDEX uk_inv_reservation_line_no ON inv_reservation_line (tenant_id, company_id, reservation_id, line_no);
CREATE INDEX idx_inv_reservation_line_mat
    ON inv_reservation_line (tenant_id, company_id, material_id, warehouse_id, batch_id);
CREATE INDEX idx_inv_reservation_line_reserved
    ON inv_reservation_line (tenant_id, company_id, warehouse_id, material_id) WHERE reserved_qty > 0;
COMMENT ON TABLE inv_reservation_line IS '库存预留明细（倉庫×物料×批次）。残予約 = reserved - consumed - released';
```

---

### 4.15 `inv_cost_layer` 成本层

| 項目 | 内容 |
|---|---|
| 種別 | 残高/履歴 |
| 更新元機能 | F-INV-017（入出庫・調整に伴う） |
| データ量見積 | 初期 500 万 / 年間 +500 万 / 5 年後 3,000 万 |
| 保存期間 | 10 年（庫齢・原価追跡） |

```sql
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
CREATE INDEX idx_inv_cost_layer_group
    ON inv_cost_layer (tenant_id, company_id, warehouse_id, material_id, batch_id, received_date);
CREATE INDEX idx_inv_cost_layer_remaining
    ON inv_cost_layer (tenant_id, company_id, warehouse_id, material_id, batch_id, received_date)
    WHERE remaining_qty > 0 AND layer_status = 10;
CREATE INDEX idx_inv_cost_layer_txn ON inv_cost_layer (tenant_id, company_id, source_txn_line_id);
COMMENT ON TABLE inv_cost_layer IS '成本层（入庫原価構成・残数量・残金額）。移動平均の主体ではなく、庫齢・原価追跡・調整按分の基礎';
COMMENT ON COLUMN inv_cost_layer.remaining_amount IS 'Σ remaining_amount（cost group）= inv_stock_balance.amount_on_hand（日次対账）';
```

**更新仕様**：入庫で INSERT（`remaining_qty=inbound_qty`）、出庫で FIFO 減算（`received_date ASC, id ASC`）、枯渇で `layer_status=40`、原価調整で按分加減、沖销で `90`。

---

### 4.16 `inv_cost_adjustment` 成本调整单（头）

| 項目 | 内容 |
|---|---|
| 種別 | 伝票ヘッダ |
| 更新元機能 | F-INV-017 |
| データ量見積 | 初期 5,000 / 年間 +6,000 / 5 年後 36,000 |

```sql
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
CREATE UNIQUE INDEX uk_inv_cost_adjustment_no ON inv_cost_adjustment (tenant_id, company_id, adjustment_no);
CREATE INDEX idx_inv_cost_adjustment_period
    ON inv_cost_adjustment (tenant_id, company_id, period_code, adjustment_status);
CREATE INDEX idx_inv_cost_adjustment_source
    ON inv_cost_adjustment (tenant_id, company_id, source_type, source_no);
COMMENT ON TABLE inv_cost_adjustment IS '原価調整単（価格差異・運費差異・期間再計算）。数量は変えず金額のみ更新し E19 を発行';
```

**更新仕様**：草稿 → 承認（WF）→ 過账（`30`、残高金額・平均単価・層を更新、E19）→ 冲销（`90`、期間内のみ）。

---

### 4.17 `inv_cost_adjustment_line` 成本调整单明细

```sql
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
CREATE UNIQUE INDEX uk_inv_cost_adjustment_line_no ON inv_cost_adjustment_line (tenant_id, company_id, adjustment_id, line_no);
CREATE INDEX idx_inv_cost_adjustment_line_group
    ON inv_cost_adjustment_line (tenant_id, company_id, material_id, warehouse_id, batch_id);
COMMENT ON TABLE inv_cost_adjustment_line IS '原価調整明細。在庫分と既出庫分（当期費用）の配分を保持（05 §2.4）';
```

---

### 4.18 `inv_period` 库存期间

| 項目 | 内容 |
|---|---|
| 種別 | 設定（期間状態） |
| 更新元機能 | F-INV-020 |
| データ量見積 | 年 12 件 |

```sql
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
CREATE UNIQUE INDEX uk_inv_period_code ON inv_period (tenant_id, company_id, period_code);
COMMENT ON TABLE inv_period IS '库存期间（月次）。FIN の fin_period と順序制御（在庫月结→原価→FIN 关账）';
COMMENT ON COLUMN inv_period.recalc_lock IS '期間再計算の実行中フラグ。過账時にチェックしてブロック';
```

**`fin_period` との対応**（`fin/V202610210706`、`status VARCHAR(16)`）：本表は SMALLINT を維持し、連携時に `10↔FUTURE`／`20↔OPEN`／`40↔CLOSED`／`90↔YEAR_CLOSED` と写像する。在庫过账の期間判定は `inv_period.period_status=20`、かつ同じ `period_code` の `fin_period.status='OPEN'`（FIN 关账後の在庫过账は不可、[06](06-reservation-barcode-close.md) 月結順序）。

---

### 4.19 `inv_stock_summary` 收发存汇总

| 項目 | 内容 |
|---|---|
| 種別 | 集計（月结生成） |
| 更新元機能 | F-INV-020（BAT-INV-001） |
| データ量見積 | 初期 20 万 / 年間 +26 万 / 5 年後 130 万 |
| 保存期間 | 10 年 |

```sql
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
CREATE UNIQUE INDEX uk_inv_stock_summary_key
    ON inv_stock_summary (tenant_id, company_id, period_code, warehouse_id, material_id);
CREATE INDEX idx_inv_stock_summary_period ON inv_stock_summary (tenant_id, company_id, period_code);
COMMENT ON TABLE inv_stock_summary IS '月次收发存汇总。期初＋入庫−出庫＝期末（DB CHECK）';
```

> `closing_amount` の整合は CHECK ではなくバッチで検証する（金額は丸めの影響を受けるため）。数量は CHECK で保証する。

---

### 4.20 `inv_age_snapshot` 库龄快照

```sql
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
CREATE UNIQUE INDEX uk_inv_age_snapshot_key
    ON inv_age_snapshot (tenant_id, company_id, snapshot_date, warehouse_id, material_id, batch_id, received_date, age_bucket);
CREATE INDEX idx_inv_age_snapshot_date ON inv_age_snapshot (tenant_id, company_id, snapshot_date DESC);
CREATE INDEX idx_inv_age_snapshot_slow
    ON inv_age_snapshot (tenant_id, company_id, snapshot_date) WHERE is_slow_moving = TRUE;
COMMENT ON TABLE inv_age_snapshot IS '日次庫齢スナップショット（BAT-INV-003）。過去日の庫齢は本表を正とする';
```

---

### 4.21 `inv_replenishment` 补货建议

```sql
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
CREATE UNIQUE INDEX uk_inv_replenishment_key
    ON inv_replenishment (tenant_id, company_id, as_of_date, warehouse_id, material_id);
CREATE INDEX idx_inv_replenishment_status
    ON inv_replenishment (tenant_id, company_id, as_of_date, replenishment_status);
CREATE INDEX idx_inv_replenishment_shortage
    ON inv_replenishment (tenant_id, company_id, as_of_date) WHERE is_shortage = TRUE;
COMMENT ON TABLE inv_replenishment IS '補貨建議（BAT-INV-004）。発注点・推奨発注量。PUR の計画採購が参照';
```

---

### 4.22 `inv_scan_log` 扫码记录

| 項目 | 内容 |
|---|---|
| 種別 | ログ（追記専用） |
| 更新元機能 | F-INV-018 |
| データ量見積 | 初期 100 万 / 年間 +100 万 / 5 年後 500 万 |
| 保存期間 | 1 年（その後アーカイブ） |

```sql
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
CREATE UNIQUE INDEX uk_inv_scan_log_device_seq
    ON inv_scan_log (tenant_id, company_id, device_id, local_seq) WHERE local_seq IS NOT NULL;
CREATE INDEX idx_inv_scan_log_time ON inv_scan_log (tenant_id, company_id, scan_at DESC);
CREATE INDEX idx_inv_scan_log_barcode ON inv_scan_log (tenant_id, company_id, barcode_value);
CREATE INDEX idx_inv_scan_log_biz ON inv_scan_log (tenant_id, company_id, biz_type, biz_id);
COMMENT ON TABLE inv_scan_log IS 'PDA スキャン記録（成功・失敗の全件）。二重送信排除と異常追跡';
```
### 4.23 `inv_event_wait` 品質イベント保留（イベント順序逆転）

| 項目 | 内容 |
|---|---|
| テーブル物理名 | `inv_event_wait` |
| テーブル論理名 | 品質イベント保留（E15 先着時の待合せ） |
| 種別 | 内部キュー（ログ + 設定） |
| 更新元機能 | F-INV-002/005（E14/E24 過账）・F-INV-014（E15 購読）・BAT-INV-007 |
| データ量見積 | 初期 0 / 年間 +1 万 / 5 年後 5 万 |
| 保存期間 | 3 か月（適用済/放棄後） |
| 備考 | [09 §8](../00-common/09-cross-domain-flow.md) の `sys_event_wait` 相当。INV 実装のため `inv_` プレフィックス（[02](02-inbound-outbound.md) 未決 #6） |

**概要**：E15（品質判定）が E14（入荷）／E24（完工）より先に到着した場合に E15 を一時保留する。対象伝票の過账トランザクション内で同一 TX 適用し、適用不能なら `BAT-INV-007` が再試行する。`event_id` 一意で二重登録を防止する（[02](02-inbound-outbound.md) §2.8）。

```sql
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
CREATE UNIQUE INDEX uk_inv_event_wait_event ON inv_event_wait (tenant_id, company_id, event_id);
CREATE INDEX idx_inv_event_wait_pending ON inv_event_wait (tenant_id, company_id, wait_status, next_retry_at) WHERE wait_status = 0;
CREATE INDEX idx_inv_event_wait_source ON inv_event_wait (tenant_id, company_id, source_type, source_id);
CREATE INDEX idx_inv_event_wait_expire ON inv_event_wait (tenant_id, company_id, created_at) WHERE wait_status = 0;
COMMENT ON TABLE inv_event_wait IS '品質イベント保留（E15 先着時の待合せ）。09 §8 の sys_event_wait 相当';
COMMENT ON COLUMN inv_event_wait.waiting_for IS 'PI=入荷待ち、FGI=完工入庫待ち、OSR=委外受入待ち';
```

**更新仕様**：E15 受信時に `INSERT`（`wait_status=0`）。E14/E24 の過账 TX 内で `SELECT ... FOR UPDATE` → E15 適用 → `wait_status=1`・`applied_txn_id`。適用失敗は `retry_count+1`・`next_retry_at`（指数バックオフ）。24 時間超は `MSG-INV-064` アラート、`BAT-INV-007` で再処理。


---

## 5. 索引一覧（集約）

| # | 索引名 | テーブル | 種別 | 対象列 | 目的 |
|---|---|---|---|---|---|
| 1 | `uk_inv_stock_balance_key` | `inv_stock_balance` | UNIQUE | (tenant_id, company_id, warehouse_id, material_id, batch_id, stock_status, location_id) | 残高の一意キー（ロック対象） |
| 2 | `idx_inv_stock_balance_material_wh` | 同上 | B-Tree | (tenant_id, company_id, material_id, warehouse_id, stock_status) | 物料別在庫照会 |
| 3 | `uk_inv_stock_txn_no` | `inv_stock_txn` | UNIQUE | (tenant_id, company_id, txn_no, txn_date) | パーティション内一意（全期間一意は #4） |
| 4 | `uk_inv_stock_txn_key` | `inv_stock_txn_key` | UNIQUE | (tenant_id, company_id, key_type, key_value) | 全期間の伝票番号・来源二重計上（TRANSFER 除く）・二重沖销・対の一意（旧 `uk_inv_stock_txn_source_posted`/`uk_inv_stock_txn_reversal` を置換） |
| 5 | `idx_inv_stock_txn_wo` | `inv_stock_txn` | B-Tree 部分 | (tenant_id, company_id, work_order_id) WHERE work_order_id IS NOT NULL | 分批法の工单別在庫取引 |
| 6 | `idx_inv_stock_txn_date_type` | 同上 | B-Tree | (tenant_id, company_id, txn_date DESC, txn_type) | 流水照会・月结集計 |
| 7 | `idx_inv_stock_txn_line_material_date` | `inv_stock_txn_line` | B-Tree | (tenant_id, company_id, material_id, batch_id, txn_id) | 台帳・追溯 |
| 8 | `idx_inv_stock_txn_line_serial` | 同上 | B-Tree | (tenant_id, company_id, serial_no) WHERE serial_no IS NOT NULL | 序列号追跡 |
| 9 | `uk_inv_transfer_no` / `idx_inv_transfer_intransit` | `inv_transfer` | UNIQUE / B-Tree 部分 | — / (tenant_id, company_id, transfer_date) WHERE status IN (30,35) | 在途一覧 |
| 10 | `uk_inv_stocktake_no` / `idx_inv_stocktake_open` | `inv_stocktake` | UNIQUE / B-Tree 部分 | — / (tenant_id, company_id, warehouse_id) WHERE status IN (10,20,30,35) | 未完了棚卸チェック |
| 11 | `uk_inv_stocktake_line_key` | `inv_stocktake_line` | UNIQUE | (tenant_id, company_id, stocktake_id, material_id, batch_id, stock_status, location_id) | 明細一意 |
| 12 | `uk_inv_batch_material_no` / `idx_inv_batch_expiry` | `inv_batch` | UNIQUE / B-Tree | — / (tenant_id, company_id, expiry_date) WHERE expiry_date IS NOT NULL | 批次・有效期 |
| 13 | `uk_inv_batch_genealogy_key` | `inv_batch_genealogy` | UNIQUE | (tenant_id, company_id, parent_batch_id, child_batch_id, source_txn_line_id) NULLS NOT DISTINCT | 系譜の二重登録防止（来源行 NULL も一意） |
| 14 | `uk_inv_serial_no` / `uk_inv_serial_external` | `inv_serial` | UNIQUE | — / (tenant_id, company_id, external_serial_no) WHERE NOT NULL | 序列号一意 |
| 15 | `uk_inv_reservation_source` | `inv_reservation` | UNIQUE 部分 | (tenant_id, company_id, source_type, source_id) WHERE status <> 90 | 二重引当防止 |
| 16 | `idx_inv_reservation_expire` | 同上 | B-Tree 部分 | (tenant_id, company_id, expire_date) WHERE status IN (10,20,35) | 期限切れ解放 |
| 17 | `idx_inv_cost_layer_remaining` | `inv_cost_layer` | B-Tree 部分 | (tenant_id, company_id, warehouse_id, material_id, batch_id, received_date) WHERE remaining_qty>0 | 庫齢・FIFO 減算 |
| 18 | `uk_inv_cost_adjustment_no` | `inv_cost_adjustment` | UNIQUE | (tenant_id, company_id, adjustment_no) | 調整番号一意 |
| 19 | `uk_inv_period_code` | `inv_period` | UNIQUE | (tenant_id, company_id, period_code) | 期間一意 |
| 20 | `uk_inv_stock_summary_key` | `inv_stock_summary` | UNIQUE | (tenant_id, company_id, period_code, warehouse_id, material_id) | 汇总一意 |
| 21 | `uk_inv_age_snapshot_key` | `inv_age_snapshot` | UNIQUE | (tenant_id, company_id, snapshot_date, warehouse_id, material_id, batch_id, received_date, age_bucket) | スナップショット一意 |
| 22 | `uk_inv_replenishment_key` | `inv_replenishment` | UNIQUE | (tenant_id, company_id, as_of_date, warehouse_id, material_id) | 建議一意 |
| 23 | `uk_inv_scan_log_device_seq` | `inv_scan_log` | UNIQUE 部分 | (tenant_id, company_id, device_id, local_seq) WHERE local_seq IS NOT NULL | 二重送信排除 |
| 24 | `uk_inv_event_wait_event` / `idx_inv_event_wait_pending` | `inv_event_wait` | UNIQUE / B-Tree 部分 | (tenant_id, company_id, event_id) / (tenant_id, company_id, wait_status, next_retry_at) WHERE wait_status=0 | 二重保留防止・未適用抽出 |

> 1 テーブル 5 本以内を目安（[04 §7](../00-common/04-common-db-spec.md)）。`inv_stock_txn_line` は参照頻度が高いため 5 本まで許容する。**具名例外：`inv_stock_txn` は 6 本**（`uk_inv_stock_txn_no`・`idx_inv_stock_txn_date_type`/`_source`/`_status`/`_pair`/`_wo`、4.2.2）を許容する（蓝色大肥鱼 2026-10-21 決定、PR #55）。

---

## 6. 制約・整合性

### 6.1 テーブル間の不変条件（すべて日次バッチ `BAT-INV-002` で検証）

| # | 不変条件 | 検証 SQL の考え方 | 差異時の対応 |
|---|---|---|---|
| IV-01 | 残高数量 = 事務明細の累計 | `Σ(direction×qty)` by (warehouse, material, batch, status, location) = `qty_on_hand` | アラート・月結中断 |
| IV-02 | 残高金額 = 事務明細の累計 | `Σ(direction×amount)` = `amount_on_hand` | 同上 |
| IV-03 | 残高金額 = 成本層残額 | `Σ remaining_amount` by cost group = `amount_on_hand` | 同上 |
| IV-04 | 予約数量 = 有効予約の残予約 | `Σ(reserved−consumed−released)` = `qty_reserved`（status=10） | 同上 |
| IV-05 | 予約 ≤ 現存 | `qty_reserved ≤ qty_on_hand`（DB CHECK） | データ修正 |
| IV-06 | 平均単価の一貫性 | cost group 内の全行の `avg_unit_cost` が同値 | 再計算 |
| IV-07 | 金額保存則（調撥） | 同一 `transfer_no` の `Σ TR_OUT.amount = Σ TR_IN.amount`（全量受入時） | 調査 |
| IV-08 | 期末 = 期初 + 入 − 出 | `inv_stock_summary`（DB CHECK は数量のみ） | 月結中断 |
| IV-09 | 事務の明細合計 | `total_qty/total_amount = Σ line` | データ修正 |
| IV-10 | 状態変換の対 | `pair_key` 単位で `Σ(direction×qty) = 0`、`Σ amount = 0` | 調査 |
| IV-11 | 品質イベント保留の一意性 | `inv_event_wait` は `event_id` 一意。`wait_status=1`（適用済）の再適用なし | 調査 |

### 6.2 排他・ロック（再掲）

| 対象 | 方式 | 備考 |
|---|---|---|
| 残高行 | `SELECT ... FOR UPDATE` | ロック順 `(warehouse_id, material_id, batch_no, stock_status, location_id)` 昇順。`lock_timeout=3s` |
| 残高行の新規作成 | `INSERT ... ON CONFLICT DO NOTHING` → 再 `SELECT FOR UPDATE` | 同時初回入庫の競合回避 |
| 伝票（草稿） | 楽観排他（`version`） | 更新件数 0 で `MSG-COM-033` |
| 棚卸単生成 | `pg_advisory_xact_lock`（倉庫単位） | 二重生成防止 |
| 月結・再計算 | `pg_advisory_lock`（公司＋期間） | 二重実行防止 |
| バッチ（対账・庫齢） | `pg_advisory_xact_lock`（バッチ単位） | 多重起動防止 |

### 6.3 FK 一覧（2026-10-21 改訂：全て複合 FK）

- **同域親子（#1〜6）**：`FOREIGN KEY (tenant_id, company_id, x_id) REFERENCES 親 (tenant_id, company_id, id)`、被参照は `uk_<親>_tenant_company_id`（PR #43）。
- **跨域 mdm（#7〜11）**：`FOREIGN KEY (tenant_id, x_id) REFERENCES mdm_x (tenant_id, id)`（`uk_mdm_x_tenant_id`、sys/V202610210707）。
- いずれも制約名は本表どおり、`ON DELETE` 指定なし（NO ACTION）、CASCADE 禁止。`x_id` 単独の FK は禁止。

| # | 参照元（列） | 被参照 | 制約名 |
|---|---|---|---|
| 1 | `inv_transfer_line.transfer_id` | `inv_transfer` | `fk_inv_transfer_line_head` |
| 2 | `inv_stocktake.plan_id` | `inv_stocktake_plan` | `fk_inv_stocktake_plan` |
| 3 | `inv_stocktake_line.stocktake_id` | `inv_stocktake` | `fk_inv_stocktake_line_head` |
| 4 | `inv_serial_txn.serial_id` | `inv_serial` | `fk_inv_serial_txn_serial` |
| 5 | `inv_reservation_line.reservation_id` | `inv_reservation` | `fk_inv_reservation_line_head` |
| 6 | `inv_cost_adjustment_line.adjustment_id` | `inv_cost_adjustment` | `fk_inv_cost_adjustment_line_head` |
| 7 | `material_id`（`inv_stock_balance`/`inv_transfer_line`/`inv_stocktake_line`/`inv_batch`/`inv_serial`/`inv_reservation_line`/`inv_cost_layer`/`inv_cost_adjustment_line`/`inv_stock_summary`/`inv_age_snapshot`/`inv_replenishment`） | `mdm_material` | `fk_<table>_material` |
| 8 | `warehouse_id`（下表の软引用を除く全表の `warehouse_id`。履歴・ログ表 `inv_serial_txn`/`inv_scan_log`/`inv_event_wait` を含む（`fk_inv_serial_txn_wh`/`fk_inv_scan_log_wh`/`fk_inv_event_wait_wh`、マスタは論理削除のみのため削除を妨げない）、`inv_transfer.from_/to_warehouse_id`） | `mdm_warehouse` | `fk_<table>_wh`（`_from_wh`/`_to_wh`） |
| 9 | `inv_transfer.from_factory_id` / `to_factory_id` | `mdm_factory` | `fk_inv_transfer_from_factory` / `fk_inv_transfer_to_factory` |
| 10 | `inv_batch.supplier_id` | `mdm_supplier` | `fk_inv_batch_supplier` |
| 11 | `inv_serial.customer_id` | `mdm_customer` | `fk_inv_serial_customer` |

**FK を張らない列（软引用）**

| 列 | 理由 |
|---|---|
| `inv_stock_txn` の全列、`inv_stock_txn_line.txn_id`、`*_txn_id`（`last_txn_id`/`adjust_txn_id`/`source_txn_id`/`applied_txn_id` 等） | `inv_stock_txn` は月次パーティション表で FK 参照不可（[04 §8.1](../00-common/04-common-db-spec.md)）。表頭→明細はトリガー、他はサービス層で検証 |
| `inv_stock_txn.warehouse_id/factory_id/partner_id`、`inv_stock_balance.warehouse_id`、`inv_stock_txn_line.material_id`（`inv_stock_balance.material_id` は硬 FK `fk_inv_stock_balance_material`、#7） | 1 億行級の事務・明細と高頻度更新の残高で FK 検査コストを避ける。過账サービスが同一 TX で存在・租户一致を検証 |
| `location_id`（0=未管理の番兵）、`batch_id`（0=非批次の番兵） | 番兵値 0 は被参照行を持たない。`mdm_warehouse_bin` に `uk_mdm_warehouse_bin_tenant_id` も未作成 |
| `work_order_id`・`sales_order_line_id`・`outsourcing_order_id`・`source_id`・`partner_id`・`customer_id`（`inv_serial_txn`） | 他業務域（prd/sal/pur）または多態参照。[04 §6.2](../00-common/04-common-db-spec.md) 項 1 により FK なし、同一 TX で存在・租户一致を検証 |
| `created_by`/`updated_by`/`posted_by` 等 → `sys_user` | `0`＝システムの番兵（06/07 迁移と同じく FK なし） |

---

## 7. データ量見積・保存期間

| テーブル | 初期 | 年間増加 | 5 年後 | 保存 | アーカイブ方針 |
|---|---|---|---|---|---|
| `inv_stock_txn` | 1,000 万 | 500 万 | 3,500 万 | 10 年 | 第一版 で月次パーティション、10 年超は履歴 DB |
| `inv_stock_txn_line` | 3,000 万 | 1,500 万 | 1 億 | 10 年 | 同上 |
| `inv_cost_layer` | 500 万 | 500 万 | 3,000 万 | 10 年 | 残存層のみ現行、枯渇層は 3 年後にアーカイブ検討 |
| `inv_stock_balance` | 6 万 | — | 8 万 | 現行のみ | — |
| `inv_batch_genealogy` | 20 万 | 25 万 | 140 万 | 10 年 | — |
| `inv_serial` / `inv_serial_txn` | 2 万 / 10 万 | 2 万 / 10 万 | 12 万 / 60 万 | 10 年 | — |
| `inv_reservation` / `_line` | 3 万 / 15 万 | 3.6 万 / 18 万 | 21 万 / 110 万 | 10 年 | 完了・解放済は 2 年後にアーカイブ検討 |
| `inv_scan_log` | 100 万 | 100 万 | 500 万 | 1 年 | 1 年後に削除またはアーカイブ |
| `inv_event_wait` | 0 | 1 万 | 5 万 | 3 か月 | 適用済/放棄は 3 か月後に削除 |
| `inv_age_snapshot` | 50 万 | 60 万 | 300 万 | 3 年 | 3 年超は削除（再生成不能なため注意） |
| `inv_replenishment` | 1 万 | 1 万 | 5 万 | 1 年 | 1 年後に削除 |
| `inv_stock_summary` | 20 万 | 26 万 | 130 万 | 10 年 | — |

**容量見積**：`inv_stock_txn` 1 行 ≈ 400 bytes、3,500 万行 ≈ 14 GB。`inv_stock_txn_line` 1 行 ≈ 350 bytes、1 億行 ≈ 35 GB。索引込みで 5 年後 ≈ 80〜100 GB を想定（[04 §13](../00-common/04-common-db-spec.md) の性能目標を満たす）。

---

## 8. 更新タイミング一覧

| テーブル | INSERT | UPDATE | DELETE |
|---|---|---|---|
| `inv_stock_balance` | 過账時（行が無い場合） | 入出庫・状態変換・沖销・原価調整・引当 | なし |
| `inv_stock_txn` | 伝票登録・イベント受信 | 承認・過账・沖销 | 禁止 |
| `inv_stock_txn_line` | 伝票登録・過账 | 過账時の原価確定のみ | 禁止 |
| `inv_transfer` / `_line` | 調撥登録 | 承認・出庫・受入・退回・取消 | なし |
| `inv_stocktake_plan` | 計画登録 | 承認・状態遷移 | なし |
| `inv_stocktake` / `_line` | 生成・実盤 | 実盤入力・差異・承認・調整 | なし |
| `inv_batch` | 入庫時採番 | QC 判定・枯渇 | なし |
| `inv_batch_genealogy` | FGI/OSR 過账 | なし | 禁止 |
| `inv_serial` | 入庫時採番 | 出庫・返品・報廃・凍結 | なし |
| `inv_serial_txn` | 状態変化時 | なし | 禁止 |
| `inv_reservation` / `_line` | 引当時 | 変更・消費・解放 | なし |
| `inv_cost_layer` | 入庫・原価調整 | 出庫（FIFO 減算）・調整・沖销 | なし |
| `inv_cost_adjustment` / `_line` | 調整登録 | 承認・過账・沖销 | なし |
| `inv_period` | 期間初期化（月初） | 月結・再开・再計算 | なし |
| `inv_stock_summary` | 月結（期間単位で洗替） | 再計算時のみ | 月結再実行時に削除→再作成 |
| `inv_age_snapshot` | 日次バッチ | なし | 当日分を洗替 |
| `inv_replenishment` | 日次バッチ | 転送・無視 | `10 建議` を洗替 |
| `inv_scan_log` | スキャン時 | なし | 1 年後に削除 |
| `inv_event_wait` | E15 先着時 INSERT / 適用・再試行で UPDATE | なし（アーカイブ削除のみ） | BAT-INV-007 |

---

## 9. Flyway マイグレーション計画（2026-10-21 改訂）

旧計画の `V202610210501`〜`0512` は main 上の最大版より小さく、`.github/scripts/check-migrations.sh` の単調増加チェックで不合格になるため廃止する。

| 項目 | 規則 |
|---|---|
| 配置 | `backend/erp-boot/src/main/resources/db/migration/inv/`（新規ディレクトリ。`{module}`=`inv`、[04 §10.1](../00-common/04-common-db-spec.md)） |
| 版数 | `V{yyyyMMdd}{NNNN}__inv_{desc}.sql`。版数は **PR 作成時・マージ時の main 上の最大版より大きく**なければならない。迁移を作成する前に `.github/scripts/check-migrations.sh` で確認する（本書には具体的な版数を記載しない） |
| ファイル構成 | 06 と同じく**1 ファイル**で全 24 表を作成（表の DDL → RLS → 索引 → COMMENT の順、表は本書 §4 の順）。例：`inv/V{yyyyMMdd}{NNNN}__inv_create_tables.sql` |
| 依存 | `mdm/V202610210201`〜`0203`（`mdm_material` 等）、`sys/V202610210707`（`uk_mdm_*_tenant_id`）、PR #43 `sys/V202610211401`（同域複合 FK 規則。マージ後は inv の版数をこれより大きくする）。`fin_standard_cost` は FK なし（软引用） |
| パーティション | 同ファイル内で `inv_stock_txn` の 2026-01〜2027-12 の月次パーティションと `inv_stock_txn_default` を作成 |
| トリガー | `trg_inv_stock_txn_line_head`（表頭存在・`txn_type` 一致・`direction` 符号）を同ファイルで作成（関数は `inv_` 接頭辞、`SECURITY INVOKER`） |
| シード | `inv_period` は会社ごとの初期化（アプリの会社開設処理）で作成し、固定 tenant のシード迁移は作らない。コード表は 90-data CSV を正とし、必要なら `R__seed_inv_{desc}.sql`（名前は `seed_inv_` で始める） |
| 検証 | `scripts/check-tenant-default.sh`、`.github/scripts/check-migrations.sh`、pgTAP `composite_fk.sql`（`uk_` の `(tenant_id, company_id)` 先頭・btree `idx_` の `tenant_id` 先頭・`uk_<table>_tenant_id` 許可）、`RlsCoverageTest` |

- 一度適用したスクリプトは編集しない。破壊的変更は 2 段階。
- 迁移を含む PR はマージ前に最新 main へ rebase し CI 全緑を再確認する（[04 §10.2](../00-common/04-common-db-spec.md)）。

---

## 10. 未決事項

| # | 事項 | 理由 | 暫定仕様 | 担当 | 期限 |
|---|---|---|---|---|---|
| 1 | （**決定済**、[04 §8](../00-common/04-common-db-spec.md)）`inv_stock_txn` の月次パーティション化 | 年 500 万行の増加 | 第一版から `PARTITION BY RANGE (txn_date)`（月次）で作成（4.2.2）。全期間一意の扱いは #7 | inventory-designer | 2026-11-15 |
| 2 | `inv_stock_txn_line.amount` の NOT NULL 化 | 草稿時は原価未確定で NULL を許容 | 草稿時は NULL 許容、過账時に必須（アプリ＋過账トリガーで検証）。列の NOT NULL 化は全伝票が過账前提になった時点で再判断 | inventory-designer | 2027-03-31 |
| 3 | `inv_scan_log` の保存期間 | [08 §12](../00-common/08-common-business-rules.md) に規定なし。監査要件と容量のバランス | 1 年保存後にアーカイブ（第一版で実装）。監査上必要なら延長 | inventory-designer / SYS 担当 | 2026-11-30 |
| 4 | `inv_batch` の削除方針 | 参照実績のない誤登録批次を削除できるか | 在庫・事務参照がある限り削除禁止。参照ゼロかつ当日登録のみ取消可（`batch_status=90`） | inventory-designer | 2026-11-30 |
| 5 | 寄售・组装拆卸用の列追加 | F-INV-022/023で `owner_type` 等の追加が必要 | 第一版で `owner_type` 等の列をマイグレーション追加（F-INV-022/023 設計と同時） | inventory-designer / Lead | 2027-06-30 |
| 6 | `inv_event_wait` と `sys_event_wait` の物理名 | [09 §8](../00-common/09-cross-domain-flow.md) は `sys_event_wait`、[04 DB 規格](../00-common/04-common-db-spec.md) のプレフィックス規約では SYS 所有。INV 実装のため暫定 `inv_event_wait` | 暫定 `inv_event_wait`（INV 所有）。SYS 共通基盤提供時に移管 | Lead / system-workflow / inventory-designer | 2026-10-25 |

| 7 | （**決定済**（蓝色大肥鱼 2026-10-21 決定））`inv_stock_txn` 全期間一意 | パーティション表の一意索引は `txn_date` を含む必要がある | 4.2.6 `inv_stock_txn_key` 台帳で `TXN_NO`/`SOURCE_POSTED`/`REVERSAL`/`PAIR` の一意を保証、PK `(id, txn_date)` | DB | 決定 2026-10-21 |
| 8 | （**決定済**（蓝色大肥鱼 2026-10-21 決定））標準原価計価の差異と版切替 | 08 §6 MTS 自制品＝標準原価 | 在庫は `std_unit_cost` で計上、入庫差異は明細 `variance_amount` を E18 明細 `varianceAmount` で FIN へ（科目は FIN が決定）。`fin_standard_cost` の版切替は月初のみ、切替時は月結（BAT-INV-001）後に在庫残を新標準で再評価する `inv_cost_adjustment`（`adjustment_type=50`、`source_type='RECALC'`）を自動起票 | FIN / INV | 決定 2026-10-21 |
| 9 | （**決定済**（蓝色大肥鱼 2026-10-21 決定））MTO 受注専用在庫（第一版） | 残高キーに受注列なし | **批次で代替**：MTO 工单の FGI 批次は工单単位で採番（1 工单 = 1 批次以上、他工单と共有しない）、`inv_stock_txn.sales_order_line_id` を保持。引当（`inv_reservation`、`source_type='SALES_ORDER'`）は当該受注明細に紐付く批次のみ可（サービス層検証、他受注は MSG 拒否）。残高キーへの列追加なし | INV | 決定 2026-10-21 |
| 10 | （**決定済**（蓝色大肥鱼 2026-10-21 決定））E19 原価調整の仕訳 | — | FIN に TPL-FIN-J31 を追加（[07/06 §4](../07-finance/06-auto-voucher-costing.md)、[09 §7.2](../00-common/09-cross-domain-flow.md) J31）：在庫分 1403/1405、既出庫分 6401/5001.01 | FIN | 決定 2026-10-21 |
| 11 | （**決定済**（蓝色大肥鱼 2026-10-21 決定））OSR 先着 E15 の保留 | — | `inv_event_wait.waiting_for` に `OSR`、`source_type` に `OUTSOURCING_ORDER` を追加（4.23 CHECK 反映済） | INV | 決定 2026-10-21 |
| 12 | （**決定済**（蓝色大肥鱼 2026-10-21 決定））MDM 硬 FK | 04 §6 旧文言「論理削除マスタは FK なし」と矛盾 | mdm 向け跨域 FK は `(tenant_id, x_id)` の硬 FK（§6.3 #7〜11）。マスタは論理削除のみ・物理削除しない。論理削除済みマスタを新規伝票で参照しないことはサービス層で検証（04 §6 改訂済） | INV / DB | 決定 2026-10-21 |

---


### 一意索引の先頭列ルールと例外（2026-10-20 決定）

- 業務一意索引は `(tenant_id, company_id, 業務キー)` で始める（Refs 43/49/54 と同一）。
- `ON CONFLICT` は同じ列を含め、採番は `sys_sequence.step`（`EXCLUDED.step` 禁止）。
- `company_id` は既定値なし・必須。`tenant_id` は `DEFAULT current_setting('app.tenant_id')::bigint`（禁止写死的默认租户）。
- **例外**：例外は [00-common/04](../00-common/04-common-db-spec.md) §6.1 第 4 条（`company_id` を持たないテナント共有表、`(tenant_id, …)` 先頭）のみ：`uk_sys_company_code`、`uk_sys_company_credit`、`uk_sys_menu_code`、`uk_sys_menu_permission`、`uk_sys_dict_type_code`、`uk_sys_outbox_event_id`、`uk_sys_idempotency_key`、`uk_sys_user_username`（ログイン ID はテナント単位（蓝色大肥鱼 2026-10-21 決定））、`uk_mdm_exchange_rate`。親 ID・イベント ID 先頭の例外は廃止（蓝色大肥鱼 2026-10-21 決定、sys/V202610210708 と整合）。明細・自己参照・イベント ID の一意索引（`uk_inv_*_line_no`、`uk_inv_stock_txn_key`、`uk_inv_stocktake_line_key`、`uk_inv_batch_genealogy_key`、`uk_inv_event_wait_event`）も `(tenant_id, company_id, …)` 先頭。
- `uk_inv_age_snapshot_key`・`uk_inv_scan_log_device_seq` は業務キーのため `(tenant_id, company_id, …)` 先頭に改めた。
- **G2-20**：非一意の btree 索引（`idx_`）も `tenant_id` 先頭（`company_id` を持つ表は次に `company_id`）とする（sys/V202610210707）。GIN 索引は対象外（蓝色大肥鱼 2026-10-21 決定）。一意索引（`uk_`）を company_id 先頭と書いてはならない。


## 11. 改訂履歴

| 版数 | 日付 | 変更内容 | 変更者 |
|---|---|---|---|
| v1.0 | 2026-10-20 | 初版：設計方針・ER、テーブル 22 件（残高・事務・調撥・棚卸・批次・序列号・予約・原価層・原価調整・期間・集計・スキャンログ）、索引 23 件、不変条件 10 件、排他、容量、更新タイミング、Flyway 計画 | inventory-designer |

| v1.1 | 2026-10-20 | 整合性修正：`inv_reservation_line` の CHECK（consumed + released ≤ reserved）を修正（E36/E37 によるテーブル変更なし） | inventory-designer |
| v1.2 | 2026-10-20 | 红队第 2 轮修复：`inv_event_wait` 追加（テーブル 23 件・索引 24 件）、`inv_stock_txn.source_event_at` 追加、在庫状態コメントを 10=待検/20=可用へ更新、Flyway V202610210512 追加（旧表記 V2026102112） | inventory-designer |
| v1.3 | 2026-10-21 | inv 明細・自己参照・イベント ID 15 件を 一意索引を `(tenant_id, company_id, …)` 先頭に統一（sys/V202610210707・0708 と整合）、「親 ID 先頭」例外一覧を削除。例外は 00-common/04 §6.1 第 4 条のテナント共有表のみ（蓝色大肥鱼 2026-10-21 決定） | 业务分析 |
| v1.4 | 2026-10-21 | 例外一覧に `uk_sys_user_username`（`(tenant_id, username)`、テナント単位）を追加（蓝色大肥鱼 2026-10-21 決定）。G2-20：非一意 btree `idx_` も `tenant_id` 先頭（次に `company_id`）、GIN 除外に修正 | 业务分析 |
| v1.5 | 2026-10-21 | 非一意 btree 索引（`idx_`）61 箇所を `tenant_id` 先頭（`company_id` がある表は次に `company_id`）に変更（DDL・索引一覧。既存迁移の索引は sys/V202610210707 と同一列。GIN は対象外。蓝色大肥鱼 2026-10-21 決定） | 业务分析 |
| v1.6 | 2026-10-21 | 05 迁移準備の欠落補完：§1.1/§3.4 RLS・`uk_<table>_tenant_id`・域内/MDM 複合 FK（§6.3 一覧）、`inv_stock_txn` 月次パーティション（PK `(id, txn_date)`）と全期間一意台帳 `inv_stock_txn_key`（4.2.6、24 表）、`inv_stock_txn` に `reason_type`/`work_order_id`/`sales_order_line_id` と来源・相手・原因 CHECK、TRANSFER を来源二重計上一意の対象外に、明細に `valuation_method`/`std_unit_cost`/`variance_amount`（08 §6 標準原価計価）と `txn_type` CHECK、明細 FK→トリガー、`uom_code` を VARCHAR(16)、集計 3 表に監査列、CHECK 追加（調撥承認・系譜自己参照・序列号履歴・予約明細状態・調整来源・スキャン区分・保留来源）、`fin_period` 状態写像、§9 迁移計画を main 最大版 `V202610210708` 以降へ改訂、未決 #7〜#11 | 业务分析 |
| v1.7 | 2026-10-21 | PR #43（sys/V202610211401）の規則に合わせ、同域親子 FK 6 本を `(tenant_id, company_id, x_id)` → 親 `(tenant_id, company_id, id)` に、親 6 表の被参照キーを `uk_<table>_tenant_company_id` に変更（`uk_<table>_tenant_id` は跨域被参照のみ＝本域 0 件）。mdm 向け跨域 FK は `(tenant_id, x_id)` のまま。§3.4・§6.3・§9 依存を更新 | 业务分析 |
| v1.8 | 2026-10-21 | 未決 #7〜#12 を決定済に（蓝色大肥鱼 2026-10-21 決定）：`inv_stock_txn_key` 正式化、標準原価差異・月初版切替・月結後再評価、MTO は工单単位批次で受注別引当、E19→J31、`inv_event_wait` に OSR/OUTSOURCING_ORDER、mdm 硬 FK（04 §6 改訂） | 业务分析 |
| v1.9 | 2026-10-21 | §9 版数規則から具体版数を削除（main 最大版より大きいこと、check-migrations で確認）、§6.3 の余分な表区切り行を削除 | 业务分析 |
| v1.10 | 2026-10-21 | PR #55 指摘の決定反映（蓝色大肥鱼 2026-10-21 決定）：`ck_inv_stock_txn_reason` を NULL 不可に（AOI/AOO 10〜60、SC_OUT 10〜50）、`uk_inv_batch_genealogy_key` を NULLS NOT DISTINCT、子パーティション RLS・REVOKE と月次作成関数（§3.4/4.2.2）、明細 insert-only（4.3.3）、`txn_id` FK なし（4.3.2）、`inv_stock_balance.material_id` 硬 FK と履歴・ログ表の倉庫 FK（§6.3）、§6.3 末尾の旧 FK 表を削除、`inv_stock_txn` 索引 6 本を具名例外（§5） | 业务分析 |
