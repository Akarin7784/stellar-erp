# 域分析・取数设计书（ドメイン分析・データ抽出 詳細設計書）

| 項目 | 内容 |
|---|---|
| 文書名 | 域分析・取数设计书（ドメイン分析・データ抽出 詳細設計書） |
| 文書番号 | DSN-RPT-002 |
| 版数 | v1.0 |
| 作成日 | 2026-10-20 |
| 作成者 | analytics-designer（報表分析分野担当） |
| 承認者 | 未承認（レビュー待ち） |
| 状態 | ドラフト（レビュー中） |
| 関連文書 | [業務域概要](00-overview.md) / [驾驶舱・KPI](01-dashboard.md) / [DB 設計](90-db-design.md) / [销售 DB](../03-sales/90-db-design.md) / [采购 DB](../04-purchase/90-db-design.md) / [生产 DB](../06-production/90-db-design.md) / [财务 DB](../07-finance/90-db-design.md) / [库存概要](../05-inventory/00-overview.md) |

---

## 1. 機能概要

| 項目 | 内容 |
|---|---|
| 機能 ID | F-RPT-003（经营分析报表・四域）、F-RPT-004（库存分析）、F-RPT-008（分析数据抽取）、F-RPT-009（自助分析・P2） |
| 機能名 | 域分析・取数 |
| 目的 | 销售・采购・库存・生产・財務の五つの分析画面を、**業務域の実テーブルから日次で抽出した分析用テーブル**（`rpt_*_detail`）の上に構築する。集計の都度業務テーブルを全走査せず、口径を KPI 定義と一致させる |
| 利用者・ロール | 経営層、部門経理、営業、購買、計画、会計、内審員 |
| 利用シーン | 月次会議の事前分析、日次の受注・出荷・在庫確認、価格交渉、納期改善、原価改善 |
| 優先度 | F-RPT-003/004/008＝P0、F-RPT-009＝P2 |
| 画面 ID | SCR-RPT-003〜007、016、017、018 |
| 関連 IF | IF-RPT-001（抽出） |

---

## 2. 設計方針

### 2.1 抽出テーブル方式

| # | 方針 | 内容 |
|---|---|---|
| 1 | **RPT は業務テーブルを更新しない** | 抽出は `INSERT ... SELECT` のみ。業務域のテーブルへの書込は一切行わない |
| 2 | **日付単位で全削除→再作成** | 抽出バッチは対象日（または対象月）の行を削除してから再作成する。部分更新をしない（再実行の冪等性） |
| 3 | **スナップショット列を保持** | 顧客名・品名・部門名・分類は抽出時点の名称を保持する（マスタ変更で過去分析が変わらない） |
| 4 | **金額は税抜・CNY** | 外貨は抽出時に換算し、`currency_code` と `exchange_rate` を保持する（Phase 2） |
| 5 | **明細粒度を保持** | 集計は画面・KPI 計算時に行う。抽出テーブルは可能な限り明細粒度（受注明細・出荷明細・入荷明細）で保持する |
| 6 | **インデックス** | 期間・次元・キーに索引を張る（[90-db-design §4](90-db-design.md)）。月次パーティションは Phase 2 |
| 7 | **保存期間** | 明細 3 年、月次確定 KPI は 10 年。3 年超はアーカイブ（BAT-RPT-012） |
| 8 | **監査** | 抽出の実行・再実行を `rpt_etl_job` に記録する |

### 2.2 抽出元マッピング（RPT ← 業務域）

#### `rpt_sales_detail`（销售分析明细）

| RPT 列 | 型 | 抽出元（テーブル.項目） | 備考 |
|---|---|---|---|
| `line_id` | BIGINT | `sal_delivery_note_line.id` | 出荷明細単位 |
| `order_no` | VARCHAR | `sal_sales_order.sales_order_no` | — |
| `order_date` | DATE | `sal_sales_order.order_date` | 受注日 |
| `due_date` | DATE | `sal_sales_order_line.delivery_date` | 受注納期（OTD 判定） |
| `ship_date` | DATE | `sal_delivery_note.confirmed_at::date` | 出荷確定日 |
| `delivery_no` | VARCHAR | `sal_delivery_note.delivery_no` | — |
| `customer_id/code/name` | BIGINT/VARCHAR | `sal_sales_order.customer_*` | スナップショット |
| `sales_dept_id` | BIGINT | `sal_sales_order.sales_department_id` | 部門分析 |
| `owner_user_id` | BIGINT | `sal_sales_order.owner_user_id` | 担当者 |
| `material_id/code/name` | BIGINT/VARCHAR | `sal_delivery_note_line.material_*` | — |
| `category_code` | VARCHAR | `mdm_material_category.category_code` | 抽出時点 |
| `product_series` | VARCHAR | `mdm_material.product_series`（YE3/YVF/非標） | 無い場合は分類で代替 |
| `uom_code` | VARCHAR | `sal_delivery_note_line.uom_code` | — |
| `ordered_qty` | NUMERIC(18,4) | `sal_delivery_note_line.ordered_qty` | — |
| `shipped_qty` | NUMERIC(18,4) | `sal_delivery_note_line.shipped_qty` | — |
| `return_qty` | NUMERIC(18,4) | `sal_sales_return_line.return_qty`（別途集計） | 返品はマイナス行で保持 |
| `unit_price` | NUMERIC(18,6) | `sal_delivery_note_line.unit_price` | — |
| `amount` | NUMERIC(18,2) | `sal_delivery_note_line.line_amount` | 税抜金額 |
| `tax_amount` | NUMERIC(18,2) | `sal_delivery_note_line.tax_amount` | — |
| `cost_amount` | NUMERIC(18,2) | `sal_delivery_note_line.cost_amount`（E18） | 未確定は NULL |
| `credit_check_result` | SMALLINT | `sal_sales_order.credit_check_result` | 与信分析 |
| `line_status` | SMALLINT | `sal_delivery_note_line.line_status` | 取消除外 |

> `product_series` は MDM に列が無い場合、`material_category`（3001=YE3、3002=YVF、3003=非標）から導出する。実装時に 02-mdm と確定する（未決 #2）。

#### `rpt_purchase_detail`（采购分析明细）

| RPT 列 | 型 | 抽出元 | 備考 |
|---|---|---|---|
| `line_id` | BIGINT | `pur_receipt_line.id` | 入荷明細単位 |
| `po_no` | VARCHAR | `pur_purchase_order.po_no` | — |
| `po_date` | DATE | `pur_purchase_order.order_date` | — |
| `due_date` | DATE | `pur_purchase_order_line.delivery_date` | 納期 |
| `receipt_date` | DATE | `pur_receipt.receipt_date` | 入荷日 |
| `supplier_id/code/name` | BIGINT/VARCHAR | `pur_purchase_order.supplier_*` | — |
| `material_id/code/name` | BIGINT/VARCHAR | `pur_receipt_line.material_*` | — |
| `category_code` | VARCHAR | `mdm_material_category.category_code` | — |
| `received_qty` | NUMERIC(18,4) | `pur_receipt_line.received_qty` | — |
| `accepted_qty` | NUMERIC(18,4) | `pur_receipt_line.accepted_qty` | IQC 合格 |
| `rejected_qty` | NUMERIC(18,4) | `pur_receipt_line.rejected_qty` | — |
| `unit_price` | NUMERIC(18,6) | `pur_receipt_line.unit_price` | — |
| `amount` | NUMERIC(18,2) | `pur_receipt_line.amount` | 税抜 |
| `tax_amount` | NUMERIC(18,2) | `pur_receipt_line.amount × tax_rate`（または請求額） | — |
| `inspection_status` | SMALLINT | `pur_receipt_line.inspection_status` | 0〜5 |
| `late_days` | INT | `pur_receipt_line.late_days` | 納期遅延 |
| `warehouse_id` | BIGINT | `pur_receipt_line.warehouse_id` | — |

#### `rpt_inventory_snapshot`（库存分析快照）

| RPT 列 | 型 | 抽出元 | 備考 |
|---|---|---|---|
| `snapshot_date` | DATE | バッチ実行日 | 日次 |
| `warehouse_id` | BIGINT | `inv_stock_balance.warehouse_id` | — |
| `material_id/code/name` | BIGINT/VARCHAR | `inv_stock_balance.material_id`／`mdm_material` | — |
| `category_code` | VARCHAR | `mdm_material_category.category_code` | — |
| `batch_no` | VARCHAR | `inv_batch.batch_no` | 批次管理のみ |
| `stock_status` | SMALLINT | `inv_stock_balance.stock_status` | 10/20/30/40/50 |
| `qty_on_hand` | NUMERIC(18,4) | `inv_stock_balance.qty_on_hand` | — |
| `qty_reserved` | NUMERIC(18,4) | `inv_stock_balance.qty_reserved` | — |
| `amount_on_hand` | NUMERIC(18,2) | `inv_stock_balance.amount_on_hand` | — |
| `avg_unit_cost` | NUMERIC(18,6) | `inv_stock_balance.avg_unit_cost` | — |
| `age_bucket` | VARCHAR(8) | `inv_age_snapshot.age_bucket` | 0-30〜366+ |
| `age_amount` | NUMERIC(18,2) | `inv_age_snapshot.amount` | 庫齢別金額 |
| `safety_stock` | NUMERIC(18,4) | `mdm_material.safety_stock_qty`／`mdm_material_warehouse` | 欠品判定 |

> 05-inventory の 90-db-design.md は 2026-10-20 に刊行済み。本域が参照する項目名は実 DDL（inv_stock_balance/inv_stock_txn/inv_stock_txn_line/inv_stock_summary/inv_period 等）と突合済みである（未決 #3 は解消）。

#### `rpt_production_detail`（生产分析明细）

| RPT 列 | 型 | 抽出元 | 備考 |
|---|---|---|---|
| `work_order_no` | VARCHAR | `prd_work_order.work_order_no` | — |
| `material_id/code/name` | BIGINT/VARCHAR | `prd_work_order.material_*` | — |
| `factory_id` | BIGINT | `prd_work_order.factory_id` | — |
| `planned_start/end_date` | DATE | `prd_work_order.planned_start_date/planned_end_date` | — |
| `actual_start/end_date` | DATE | `prd_work_order.actual_start_date/actual_end_date` | — |
| `released_at` | TIMESTAMPTZ | `prd_work_order.released_at` | — |
| `order_qty` | NUMERIC(18,4) | `prd_work_order.order_qty` | — |
| `completed_qty` | NUMERIC(18,4) | `prd_work_order.completed_qty` | — |
| `reported_good_qty` | NUMERIC(18,4) | `prd_work_order.reported_good_qty` | — |
| `reported_defect_qty` | NUMERIC(18,4) | `prd_work_order.reported_defect_qty` | — |
| `scrapped_qty` | NUMERIC(18,4) | `prd_work_order.scrapped_qty` | — |
| `work_hours` | NUMERIC(12,2) | `prd_work_report.total_work_hours`（合計） | 工数 |
| `first_pass_flag` | BOOLEAN | `prd_inspection`／`prd_inspection_line` の判定（初回） | FPY 用。抽出時に導出 |
| `inspection_result` | SMALLINT | `prd_inspection.inspection_result` | 20 合格/30 不合格/40 特采 |
| `standard_cost` | NUMERIC(18,6) | `prd_work_order.standard_cost` | — |
| `actual_total_cost` | NUMERIC(18,2) | `prd_work_order.actual_total_cost` | 月結後 |
| `cost_variance` | NUMERIC(18,2) | `prd_work_order.cost_variance` | — |

#### `rpt_finance_detail`（财务分析明细）

| RPT 列 | 型 | 抽出元 | 備考 |
|---|---|---|---|
| `period_code` | VARCHAR(7) | `fin_voucher.period_code` | — |
| `voucher_no` | VARCHAR | `fin_voucher.voucher_no` | — |
| `account_code` | VARCHAR(32) | `fin_voucher_line.account_code` | スナップショット |
| `account_name` | VARCHAR(200) | `fin_voucher_line.account_name` | — |
| `debit_amount` | NUMERIC(18,2) | `fin_voucher_line.debit_amount` | — |
| `credit_amount` | NUMERIC(18,2) | `fin_voucher_line.credit_amount` | — |
| `customer_id` | BIGINT | `fin_voucher_line.customer_id` | 補助核算 |
| `supplier_id` | BIGINT | `fin_voucher_line.supplier_id` | — |
| `department_id` | BIGINT | `fin_voucher_line.department_id` | — |
| `cash_flow_item_code` | VARCHAR | `fin_voucher_line.cash_flow_item_code` |  CF |
| `period_debit/credit` | NUMERIC(18,2) | `fin_account_balance` 発生額 | 月次集計用 |

> 財務 KPI は原則 `fin_voucher_line` から直接集計できる。`rpt_finance_detail` は分析画面のドリルダウン用（勘定式・補助核算）に用いる。

### 2.3 SQL 記述ルール

| # | ルール |
|---|---|
| 1 | 集計は `rpt_*_detail` に対して行う。業務テーブルを直接 JOIN しない（抽出時に解決済み） |
| 2 | 期間条件は `>= :from AND < :to + 1`（日付型）または `period_code BETWEEN`（月次） |
| 3 | 比率は `NULLIF(分母, 0)` で 0 除算を防ぐ |
| 4 | 金額は `SUM(...)::NUMERIC(18,2)`、率は `ROUND(..., 2)` で表示時に丸める |
| 5 | 前年同期比は `LAG(..., 12)`（月次）または自己 JOIN（期間指定）で求める |
| 6 | ランキングは `RANK() OVER (ORDER BY ... DESC)`、上位 N 件は `FETCH FIRST N ROWS` |
| 7 | 抽出テーブルの削除は `DELETE FROM rpt_* WHERE 日付 = :d`（バッチ内トランザクション） |

---

## 3. 销售分析（SCR-RPT-003）

### 3.1 画面項目定義

| No | 項目 ID | 項目名 | 種別 | 型/桁 | 必須 | 初期値 | 入力チェック | データソース |
|---|---|---|---|---|---|---|---|---|
| 1 | date_from | 開始日 | 日付 | DATE | ○ | 当月 1 日 | 開始 ≤ 終了 | 入力 |
| 2 | date_to | 終了日 | 日付 | DATE | ○ | 当日 | 同上 | 入力 |
| 3 | customer_id | 顧客 | 選択 | BIGINT | △ | 全顧客 | 有効顧客 | `mdm_customer` |
| 4 | product_series | 製品系列 | 複数選択 | VARCHAR | △ | 全系列 | YE3/YVF/非標 | `mdm_material` |
| 5 | sales_dept_id | 部門 | 選択 | BIGINT | △ | 全部門 | 有効部門 | `sys_department` |
| 6 | compare_mode | 比較 | 選択 | SMALLINT | ○ | 10 | 10 前月/20 前年同期/30 無 | 入力 |
| 7 | group_by | 集計軸 | 選択 | SMALLINT | ○ | 10 | 10 顧客/20 製品/30 部門/40 担当 | 入力 |
| 8 | chart_type | グラフ | 選択 | SMALLINT | ○ | 10 | 10 棒/20 折線/30 円/40 表 | 入力 |

### 3.2 取数 SQL 思路

**S-01 月次売上・粗利**

```sql
SELECT date_trunc('month', d.ship_date)::date AS period_code,
       SUM(d.amount)                          AS sales_amount,
       SUM(d.shipped_qty)                     AS sales_qty,
       SUM(d.amount - COALESCE(d.cost_amount, 0)) AS gross_profit,
       ROUND(SUM(d.amount - COALESCE(d.cost_amount, 0)) / NULLIF(SUM(d.amount), 0) * 100, 2) AS gross_margin
FROM rpt_sales_detail d
WHERE d.ship_date >= :from AND d.ship_date < :to + 1
  AND d.line_status <> 90
GROUP BY 1
ORDER BY 1;
```

**S-02 顧客別売上・構成比（CR5）**

```sql
WITH c AS (
  SELECT d.customer_id, d.customer_name, SUM(d.amount) AS amount
  FROM rpt_sales_detail d
  WHERE d.ship_date BETWEEN :from AND :to AND d.line_status <> 90
  GROUP BY d.customer_id, d.customer_name
), t AS (SELECT SUM(amount) AS total FROM c)
SELECT c.customer_name, c.amount,
       ROUND(c.amount / NULLIF(t.total, 0) * 100, 2) AS share_pct,
       RANK() OVER (ORDER BY c.amount DESC) AS rnk
FROM c CROSS JOIN t
ORDER BY c.amount DESC
FETCH FIRST 20 ROWS ONLY;
```

**S-03 交付達成率（OTD）**

```sql
SELECT SUM(CASE WHEN d.ship_date <= d.due_date THEN d.shipped_qty ELSE 0 END) AS on_time_qty,
       SUM(d.shipped_qty) AS shipped_qty,
       ROUND(SUM(CASE WHEN d.ship_date <= d.due_date THEN d.shipped_qty ELSE 0 END)
             / NULLIF(SUM(d.shipped_qty), 0) * 100, 2) AS otd_rate
FROM rpt_sales_detail d
WHERE d.ship_date BETWEEN :from AND :to
  AND d.line_status <> 90;
```

**S-04 製品別毛利**

```sql
SELECT d.material_code, d.material_name,
       SUM(d.amount) AS sales_amount,
       SUM(d.amount - COALESCE(d.cost_amount, 0)) AS gross_profit,
       ROUND(SUM(d.amount - COALESCE(d.cost_amount, 0)) / NULLIF(SUM(d.amount), 0) * 100, 2) AS gross_margin
FROM rpt_sales_detail d
WHERE d.ship_date BETWEEN :from AND :to AND d.line_status <> 90
GROUP BY d.material_code, d.material_name
HAVING SUM(d.amount) > 0
ORDER BY gross_profit DESC;
```

**S-05 受注残・バックオーダー（業務域参照）**

```sql
SELECT l.sales_order_id, o.sales_order_no, o.customer_name,
       l.material_code, l.ordered_qty, l.shipped_qty,
       (l.ordered_qty - l.shipped_qty - l.cancelled_qty) AS open_qty,
       l.delivery_date, l.shortage_qty
FROM sal_sales_order_line l
JOIN sal_sales_order o ON o.id = l.sales_order_id
WHERE o.order_status IN (25,30,35)
  AND l.line_status IN (10,30,35)
  AND (l.ordered_qty - l.shipped_qty - l.cancelled_qty) > 0
ORDER BY l.delivery_date;
```

> 受注残は「現在の業務状態」を返す必要があるため、例外的に業務テーブルを参照する（読取のみ）。日次スナップショットは `rpt_sales_detail` に保持しない。

**S-06 退货率**

```sql
SELECT ROUND(SUM(r.line_amount) / NULLIF((SELECT SUM(d.amount) FROM rpt_sales_detail d
       WHERE d.ship_date BETWEEN :from AND :to AND d.line_status <> 90), 0) * 100, 2) AS return_rate
FROM sal_sales_return_line r
JOIN sal_sales_return s ON s.id = r.return_id
WHERE s.return_date BETWEEN :from AND :to AND s.return_status = 40;
```

> `sal_sales_return` の状態コードは [08 §3.2](../00-common/08-common-business-rules.md)（40 完了）。項目名は 03-sales/90-db-design §3.14/3.15 を正とする。

**S-07 与信超限率**

```sql
SELECT COUNT(*) FILTER (WHERE o.credit_check_result IN (30,40)) AS over_count,
       COUNT(*) AS total_count,
       ROUND(COUNT(*) FILTER (WHERE o.credit_check_result IN (30,40))::numeric
             / NULLIF(COUNT(*), 0) * 100, 2) AS over_rate
FROM sal_sales_order o
WHERE o.order_date BETWEEN :from AND :to
  AND o.order_status NOT IN (90,95);
```

**S-08 前年同期比**

```sql
WITH m AS (
  SELECT period_code, sales_amount,
         LAG(sales_amount, 12) OVER (ORDER BY period_code) AS last_year
  FROM rpt_kpi_snapshot
  WHERE kpi_code = 'KPI-RPT-013'
)
SELECT period_code, sales_amount, last_year,
       ROUND((sales_amount - last_year) / NULLIF(last_year, 0) * 100, 2) AS yoy_pct
FROM m ORDER BY period_code;
```

---

## 4. 采购分析（SCR-RPT-004）

**P-01 月次・供應商別採購額**

```sql
SELECT date_trunc('month', p.receipt_date)::date AS period_code,
       p.supplier_id, p.supplier_name,
       SUM(p.amount) AS purchase_amount,
       SUM(p.received_qty) AS received_qty
FROM rpt_purchase_detail p
WHERE p.receipt_date BETWEEN :from AND :to
GROUP BY 1, 2, 3
ORDER BY 1, 4 DESC;
```

**P-02 供應商按期交付率**

```sql
SELECT s.period_code, s.supplier_code, s.supplier_name,
       s.receipt_line_count, s.on_time_line_count,
       ROUND(s.on_time_line_count::numeric / NULLIF(s.receipt_line_count, 0) * 100, 2) AS on_time_rate,
       s.delivery_score, s.grade
FROM pur_supplier_performance s
WHERE s.period_code BETWEEN :from_period AND :to_period
ORDER BY s.period_code DESC, on_time_rate ASC;
```

**P-03 入荷ベース納期遅延**

```sql
SELECT COUNT(*) AS late_lines,
       ROUND(AVG(p.late_days)::numeric, 1) AS avg_late_days,
       ROUND(COUNT(*) FILTER (WHERE p.late_days > 0)::numeric / NULLIF(COUNT(*), 0) * 100, 2) AS late_rate
FROM rpt_purchase_detail p
WHERE p.receipt_date BETWEEN :from AND :to;
```

**P-04 採購単価トレンド（加重平均）**

```sql
SELECT date_trunc('month', p.receipt_date)::date AS period_code,
       p.material_code, p.material_name,
       ROUND(SUM(p.amount) / NULLIF(SUM(p.received_qty), 0), 6) AS avg_unit_price
FROM rpt_purchase_detail p
WHERE p.material_code = :material_code
  AND p.receipt_date BETWEEN :from AND :to
GROUP BY 1, 2, 3
ORDER BY 1;
```

**P-05 採購降本率（同一品目群）**

```sql
WITH cur AS (
  SELECT material_code, SUM(amount) / NULLIF(SUM(received_qty), 0) AS price
  FROM rpt_purchase_detail
  WHERE receipt_date BETWEEN :cur_from AND :cur_to GROUP BY material_code
), prev AS (
  SELECT material_code, SUM(amount) / NULLIF(SUM(received_qty), 0) AS price
  FROM rpt_purchase_detail
  WHERE receipt_date BETWEEN :prev_from AND :prev_to GROUP BY material_code
)
SELECT COUNT(*) AS comparable_items,
       ROUND((1 - SUM(cur.price) / NULLIF(SUM(prev.price), 0)) * 100, 2) AS saving_rate
FROM cur JOIN prev USING (material_code)
WHERE prev.price > 0;
```

> 上記は同一品目群の単価を単純合計した簡易式である。厳密には数量加重（`SUM(cur.price × cur.qty) ÷ SUM(prev.price × cur.qty)`）を用いる。数量列を CTE に追加して実装する（未決 #4）。

**P-06 三单匹配自动通过率**

```sql
SELECT COUNT(*) FILTER (WHERE m.match_status IN (10,20)) AS auto_matched,
       COUNT(*) AS total,
       ROUND(COUNT(*) FILTER (WHERE m.match_status IN (10,20))::numeric / NULLIF(COUNT(*), 0) * 100, 2) AS pass_rate
FROM pur_invoice_match m
WHERE m.created_at::date BETWEEN :from AND :to;
```

> `match_status` の値（10 一致/20 容差内/30 差異/40 保留）は 04-purchase/06-purchase-invoice-ap.md を正とする。実装時に確認する。

---

## 5. 库存分析（SCR-RPT-007）

**I-01 月末在庫金額・構成比**

```sql
SELECT s.warehouse_id, SUM(s.amount_on_hand) AS stock_amount,
       ROUND(SUM(s.amount_on_hand) / NULLIF(SUM(SUM(s.amount_on_hand)) OVER (), 0) * 100, 2) AS share_pct
FROM rpt_inventory_snapshot s
WHERE s.snapshot_date = :month_end
GROUP BY s.warehouse_id;
```

**I-02 库存周转率（销售成本口径・KPI-RPT-024）**

```sql
WITH p AS (SELECT :from::date AS d1, :to::date AS d2),
open_bal AS (
  SELECT SUM(s.amount_on_hand) AS amt
  FROM rpt_inventory_snapshot s, p
  WHERE s.snapshot_date = (SELECT MAX(snapshot_date) FROM rpt_inventory_snapshot WHERE snapshot_date < p.d1)
),
close_bal AS (
  SELECT SUM(s.amount_on_hand) AS amt
  FROM rpt_inventory_snapshot s, p
  WHERE s.snapshot_date = (SELECT MAX(snapshot_date) FROM rpt_inventory_snapshot WHERE snapshot_date <= p.d2)
),
cogs AS (
  SELECT SUM(d.cost_amount) AS amt
  FROM rpt_sales_detail d, p
  WHERE d.ship_date BETWEEN p.d1 AND p.d2 AND d.line_status <> 90
)
SELECT ROUND(cogs.amt / NULLIF((open_bal.amt + close_bal.amt) / 2, 0), 2) AS turnover_times,
       ROUND((open_bal.amt + close_bal.amt) / 2, 2) AS avg_inventory_amount,
       ROUND((p.d2 - p.d1 + 1)::numeric / NULLIF(cogs.amt / NULLIF((open_bal.amt + close_bal.amt) / 2, 0), 0), 1) AS turnover_days
FROM cogs, open_bal, close_bal, p;
```

> 上記の `cogs.amt` は `rpt_sales_detail.cost_amount`（SI 出庫原価）の合計。月結後は `fin_voucher_line`（6401 借方発生額）と一致することを BAT-RPT-010 で検証する。期首は「対象開始日より前の直近スナップショット」、期末は「対象終了日以前の直近スナップショット」を用いる（休日で欠測の場合に備える）。

**I-03 庫齢構成・呆滞**

```sql
SELECT s.age_bucket, SUM(s.amount_on_hand) AS amount,
       ROUND(SUM(s.amount_on_hand) / NULLIF(SUM(SUM(s.amount_on_hand)) OVER (), 0) * 100, 2) AS share_pct
FROM rpt_inventory_snapshot s
WHERE s.snapshot_date = :month_end
GROUP BY s.age_bucket
ORDER BY s.age_bucket;
```

**I-04 欠品率**

```sql
SELECT COUNT(*) FILTER (WHERE r.available_qty < r.safety_stock) AS shortage_items,
       COUNT(*) AS managed_items,
       ROUND(COUNT(*) FILTER (WHERE r.available_qty < r.safety_stock)::numeric / NULLIF(COUNT(*), 0) * 100, 2) AS shortage_rate
FROM inv_replenishment r
WHERE r.calc_date = :date;
```

**I-05 收发存（期間）**

```sql
SELECT s.warehouse_id, s.material_id,
       s.opening_qty, s.in_qty, s.out_qty, s.closing_qty,
       s.opening_amount, s.in_amount, s.out_amount, s.closing_amount
FROM inv_stock_summary s
WHERE s.period_code = :period_code
ORDER BY s.warehouse_id, s.material_id;
```

> `inv_stock_summary` の列名は 05-inventory/07-reports CALC-01〜03（`closing_qty`、`closing_amount`）に基づく。実装時に 05 域の物理名と突合する。

**I-06 库存准确率**

```sql
SELECT ROUND((1 - SUM(ABS(t.diff_amount)) / NULLIF(SUM(t.book_amount), 0)) * 100, 2) AS accuracy
FROM inv_stocktake_line t
JOIN inv_stocktake k ON k.id = t.stocktake_id
WHERE k.stocktake_date BETWEEN :from AND :to AND k.stocktake_status = 40;
```

---

## 6. 生产分析（SCR-RPT-005）

**M-01 日次・製品別産量**

```sql
SELECT d.actual_end_date AS prod_date, d.material_code, d.material_name,
       SUM(d.completed_qty) AS completed_qty
FROM rpt_production_detail d
WHERE d.actual_end_date BETWEEN :from AND :to
GROUP BY 1, 2, 3
ORDER BY 1, 4 DESC;
```

**M-02 計画達成率**

```sql
SELECT COUNT(*) FILTER (WHERE d.actual_end_date <= d.planned_end_date) AS on_time_orders,
       COUNT(*) AS planned_orders,
       ROUND(COUNT(*) FILTER (WHERE d.actual_end_date <= d.planned_end_date)::numeric
             / NULLIF(COUNT(*), 0) * 100, 2) AS achievement_rate
FROM rpt_production_detail d
WHERE d.planned_end_date BETWEEN :from AND :to
  AND d.actual_end_date IS NOT NULL;
```

**M-03 良品率（報工ベース）**

```sql
SELECT r.work_order_no, r.operation_seq, r.operation_name,
       SUM(r.reported_good_qty) AS good_qty,
       SUM(r.defect_qty) AS defect_qty,
       SUM(r.scrap_qty) AS scrap_qty,
       ROUND(SUM(r.reported_good_qty)::numeric
             / NULLIF(SUM(r.reported_good_qty + r.defect_qty + r.scrap_qty), 0) * 100, 2) AS yield_rate
FROM prd_work_report r
WHERE r.report_date BETWEEN :from AND :to AND r.report_status = 40
GROUP BY 1, 2, 3;
```

**M-04 一次通過率（FPY）**

```sql
SELECT COUNT(*) FILTER (WHERE p.first_pass_flag) AS first_pass,
       COUNT(*) AS inspected,
       ROUND(COUNT(*) FILTER (WHERE p.first_pass_flag)::numeric / NULLIF(COUNT(*), 0) * 100, 2) AS fpy
FROM rpt_production_detail p
WHERE p.actual_end_date BETWEEN :from AND :to
  AND p.inspection_result IS NOT NULL;
```

**M-05 工单周期・遅延**

```sql
SELECT ROUND(AVG((d.actual_end_date - d.released_at::date))::numeric, 1) AS avg_cycle_days,
       COUNT(*) FILTER (WHERE d.actual_end_date > d.planned_end_date) AS late_orders,
       COUNT(*) AS completed_orders
FROM rpt_production_detail d
WHERE d.actual_end_date BETWEEN :from AND :to;
```

**M-06 成本差异率**

```sql
SELECT d.work_order_no, d.material_code,
       d.actual_total_cost,
       ROUND(d.standard_cost * d.completed_qty, 2) AS standard_total,
       ROUND(ABS(d.actual_total_cost - d.standard_cost * d.completed_qty)
             / NULLIF(d.standard_cost * d.completed_qty, 0) * 100, 2) AS variance_rate
FROM rpt_production_detail d
WHERE d.actual_end_date BETWEEN :from AND :to
  AND d.actual_total_cost > 0 AND d.standard_cost > 0;
```

---

## 7. 财务分析（SCR-RPT-006）

**F-01 月次損益・毛利率**

```sql
SELECT v.period_code,
       SUM(CASE WHEN l.account_code LIKE '6001%' THEN l.credit_amount - l.debit_amount ELSE 0 END) AS revenue,
       SUM(CASE WHEN l.account_code LIKE '6401%' THEN l.debit_amount - l.credit_amount ELSE 0 END) AS cogs,
       SUM(CASE WHEN l.account_code LIKE '6601%' OR l.account_code LIKE '6602%' OR l.account_code LIKE '6603%'
                THEN l.debit_amount - l.credit_amount ELSE 0 END) AS period_expense
FROM fin_voucher_line l
JOIN fin_voucher v ON v.id = l.voucher_id
WHERE v.period_code BETWEEN :from_period AND :to_period
  AND v.status = 40
GROUP BY v.period_code
ORDER BY v.period_code;
```

> `fin_voucher.status=40`（記帳済）のみを対象とする。赤伝は負数で自然相殺される。

**F-02 DSO（应收周转天数）**

```sql
WITH ar AS (
  SELECT period_code, SUM(balance_amount) AS ar_balance
  FROM fin_receivable
  WHERE status NOT IN (90) AND balance_amount > 0
  GROUP BY period_code
), rev AS (
  SELECT v.period_code,
         SUM(CASE WHEN l.account_code LIKE '6001%' THEN l.credit_amount - l.debit_amount ELSE 0 END) AS revenue
  FROM fin_voucher_line l JOIN fin_voucher v ON v.id = l.voucher_id
  WHERE v.status = 40 AND v.period_code BETWEEN :from_period AND :to_period
  GROUP BY v.period_code
)
SELECT r.period_code,
       ROUND((LAG(a.ar_balance) OVER (ORDER BY r.period_code) + a.ar_balance) / 2
             / NULLIF(r.revenue, 0) * 30, 1) AS dso_days
FROM rev r JOIN ar a USING (period_code)
ORDER BY r.period_code;
```

**F-03 DPO（应付周转天数）**

```sql
WITH ap AS (
  SELECT period_code, SUM(balance_amount) AS ap_balance
  FROM fin_payable
  WHERE status NOT IN (90) AND balance_amount > 0
  GROUP BY period_code
), cogs AS (
  SELECT v.period_code,
         SUM(CASE WHEN l.account_code LIKE '6401%' THEN l.debit_amount - l.credit_amount ELSE 0 END) AS cogs
  FROM fin_voucher_line l JOIN fin_voucher v ON v.id = l.voucher_id
  WHERE v.status = 40 AND v.period_code BETWEEN :from_period AND :to_period
  GROUP BY v.period_code
)
SELECT c.period_code,
       ROUND((LAG(a.ap_balance) OVER (ORDER BY c.period_code) + a.ap_balance) / 2
             / NULLIF(c.cogs, 0) * 30, 1) AS dpo_days
FROM cogs c JOIN ap a USING (period_code)
ORDER BY c.period_code;
```

**F-04 資産負債率（BS スナップショット）**

```sql
WITH bs AS (
  SELECT s.period_code, r
  FROM fin_statement_snapshot s
  CROSS JOIN LATERAL jsonb_array_elements(s.rows_data) AS r
  WHERE s.statement_type = 'BS'
    AND s.period_code = :period_code
    AND s.compare_type = 1
)
SELECT period_code,
       MAX(CASE WHEN r->>'itemName' = '负债合计' THEN (r->>'closingAmount')::numeric END) AS liability,
       MAX(CASE WHEN r->>'itemName' = '资产总计' THEN (r->>'closingAmount')::numeric END) AS asset,
       ROUND(MAX(CASE WHEN r->>'itemName' = '负债合计' THEN (r->>'closingAmount')::numeric END)
             / NULLIF(MAX(CASE WHEN r->>'itemName' = '资产总计' THEN (r->>'closingAmount')::numeric END), 0) * 100, 2) AS debt_ratio
FROM bs
GROUP BY period_code;
```

> `fin_statement_snapshot.rows_data` は JSONB 配列（`lineNo`・`itemName`・`closingAmount`・`openingAmount`）。項目名は `fin_statement_template` を正とする。`statement_type` は `BS`/`IS`/`CF`、`compare_type=1` は単期。

**F-05 期間費用率・経常利益率**

```sql
SELECT v.period_code,
       ROUND(SUM(CASE WHEN l.account_code LIKE '6601%' OR l.account_code LIKE '6602%' OR l.account_code LIKE '6603%'
                      THEN l.debit_amount - l.credit_amount ELSE 0 END)
             / NULLIF(SUM(CASE WHEN l.account_code LIKE '6001%' THEN l.credit_amount - l.debit_amount ELSE 0 END), 0) * 100, 2) AS expense_ratio
FROM fin_voucher_line l JOIN fin_voucher v ON v.id = l.voucher_id
WHERE v.status = 40 AND v.period_code BETWEEN :from_period AND :to_period
GROUP BY v.period_code;
```

**F-06 人均産値**

```sql
WITH rev AS (
  SELECT SUM(credit_amount - debit_amount) AS revenue
  FROM fin_voucher_line l JOIN fin_voucher v ON v.id = l.voucher_id
  WHERE v.status = 40 AND v.period_code BETWEEN :from_period AND :to_period
    AND l.account_code LIKE '6001%'
), headcount AS (
  SELECT COUNT(*) AS hc FROM sys_user WHERE status = 1 AND deleted = FALSE
)
SELECT ROUND(rev.revenue / NULLIF(headcount.hc, 0), 2) AS revenue_per_capita
FROM rev CROSS JOIN headcount;
```

---

## 8. 分析画面の共通仕様

### 8.1 分析画面一覧

| 画面 ID | 画面名 | 主なグラフ | ドリルダウン先 |
|---|---|---|---|
| SCR-RPT-003 | 销售分析 | 月次推移、顧客別構成、製品別粗利、OTD | SCR-RPT-016（受注・出荷明細） |
| SCR-RPT-004 | 采购分析 | 月次推移、供應商別、価格トレンド、納期遅延 | SCR-RPT-016（入荷明細） |
| SCR-RPT-005 | 生产分析 | 日次産量、良率、計画達成、工单周期 | SCR-RPT-016（工单・報工明細） |
| SCR-RPT-006 | 财务分析 | 損益推移、費用構成、DSO/DPO、BS 比率 | SCR-RPT-016（仕訳明細） |
| SCR-RPT-007 | 库存分析 | 在庫金額、回転、庫齢、欠品 | SCR-RPT-016（在庫明細） |
| SCR-RPT-016 | 分析明細/钻取 | 表 | SCR-RPT-017（出力） |

### 8.2 ドリルダウン仕様

| 項目 | 内容 |
|---|---|
| 遷移条件 | グラフ要素クリックまたは表の行クリック |
| 引継条件 | 期間・次元（顧客/製品/倉庫等）・KPI コード |
| 明細件数 | 最大 10,000 件（超過は出力ジョブ） |
| 列 | 業務キー・日付・相手先・品目・数量・金額・原価・状態 |
| 並び順 | 金額降順（既定）、日付降順に変更可 |
| 出力 | Excel（.xlsx）、非同期（SCR-RPT-017） |
| 権限 | 元画面と同じ。明細で権限外の項目は非表示 |

### 8.3 分析画面の表示制御

| 条件 | 対象 | 制御 |
|---|---|---|
| データ範囲外 | 全画面 | 403 `MSG-RPT-001` |
| 原価項目の権限なし | 粗利・原価 | 非表示（API 返却なし） |
| 期間が未抽出 | グラフ | 「データ未準備」表示 |
| 比較期間なし | 前年同期比 | 「-」 |
| 明細 > 10,000 件 | ドリルダウン | 出力ジョブへ誘導 |

---

## 9. 処理詳細（抽出）

### 9.1 処理一覧

| 処理 ID | 処理名 | 契機 | トランザクション | 冪等 |
|---|---|---|---|---|
| PRC-RPT-002-01 | 销售明细抽出 | BAT-RPT-001 | 要（日付単位） | 日付削除→再作成 |
| PRC-RPT-002-02 | 采购明细抽出 | BAT-RPT-002 | 要 | 同上 |
| PRC-RPT-002-03 | 库存快照抽出 | BAT-RPT-003 | 要 | 日付 UPSERT |
| PRC-RPT-002-04 | 生产明细抽出 | BAT-RPT-004 | 要 | 日付削除→再作成 |
| PRC-RPT-002-05 | 财务明细抽出 | BAT-RPT-005 | 要 | 期間削除→再作成 |
| PRC-RPT-002-06 | 分析クエリ | 画面 | 不要（読取） | — |

### 9.2 処理手順（正常系）

**PRC-RPT-002-01 销售明细抽出**

1. 対象日（前日）を決定し、`rpt_etl_job` に `status=10` で登録する。
2. トランザクション開始。`rpt_sales_detail WHERE ship_date = :d` を削除する。
3. `sal_delivery_note`（`confirmed_at::date = :d`、`delivery_status=40`）× `sal_delivery_note_line` × `sal_sales_order` × `sal_sales_order_line` × `mdm_material` を SELECT し、INSERT する。
4. 返品（`sal_sales_return` 完了）はマイナス行として同日に INSERT する。
5. 件数・金額を検証し、コミットする。`rpt_etl_job` を `status=40`、件数を更新する。
6. エラー時はロールバックし、`rpt_etl_error` に記録、`status=90`。

**PRC-RPT-002-03 库存快照抽出**

1. 対象日を決定し、`rpt_inventory_snapshot WHERE snapshot_date=:d` を削除する。
2. `inv_stock_balance` を倉庫×物料×状態で集計し、`inv_age_snapshot` の庫齢区分を LEFT JOIN して INSERT する。
3. `mdm_material` の安全在庫を結合し、欠品判定用の列を保持する。
4. 件数・金額を `inv_stock_summary`（該当月末）と突合し、差異があればアラートする。

### 9.3 例外処理

| No | 異常条件 | 検知 | 処理 | ロールバック | メッセージ |
|---|---|---|---|---|---|
| 1 | 抽出元にデータなし | 件数 0 | 正常終了（0 件） | なし | — |
| 2 | 金額不整合 | 検証 | エラー、ジョブ失敗 | 全体 | `MSG-RPT-030` |
| 3 | 業務域の期間未確定 | 抽出 | 暫定フラグ付きで抽出 | なし | `MSG-RPT-031` |
| 4 | 重複実行 | ジョブ | ロックで拒否 | なし | `MSG-COM-035` |
| 5 | 明細件数が想定超過 | 検証 | 警告、継続 | なし | `MSG-RPT-032` |

### 9.4 冪等性・再実行

- 抽出は「日付（期間）単位の全削除→再作成」。再実行しても重複しない。
- 再計算（BAT-RPT-011）は指定期間の抽出と KPI を再作成する。確定済み月次 KPI は上書きしない。
- 抽出ジョブは `rpt_etl_job` の実行中フラグで多重起動を防ぐ。

---

## 10. 帳票・出力

| 帳票 ID | 帳票名 | 出力元画面 | 形式 | 備考 |
|---|---|---|---|---|
| PRT-RPT-003 | 销售分析表 | SCR-RPT-003 | Excel/PDF | 月次・顧客/製品別 |
| PRT-RPT-004 | 采购分析表 | SCR-RPT-004 | Excel/PDF | 月次・供應商別 |
| PRT-RPT-005 | 库存分析表 | SCR-RPT-007 | Excel/PDF | 月末・倉庫/分類別 |
| PRT-RPT-006 | 生产分析表 | SCR-RPT-005 | Excel/PDF | 月次・工場/製品別 |
| PRT-RPT-007 | 财务分析表 | SCR-RPT-006 | Excel/PDF | 月次・科目/部門別 |

> 帳票の詳細（レイアウト・印字項目）は [92-report-batch-design.md](92-report-batch-design.md) を正とする。

---

## 11. エラー処理・メッセージ

| メッセージ ID | 種別 | 本文 | 発生条件 | 対処 |
|---|---|---|---|---|
| `MSG-RPT-001` | E | 没有查看该报表的权限。 | 権限なし | 管理者へ申請 |
| `MSG-RPT-030` | E | 分析数据抽取失败：{0}，请联系管理员。 | 抽出失敗 | ログ確認・再実行 |
| `MSG-RPT-031` | W | 部分业务数据尚未确定，当前分析结果为暂定值。 | 期間未確定 | 確定後に再表示 |
| `MSG-RPT-032` | W | 抽取数据量超过预期（{0} 行），请确认是否存在异常。 | 件数超過 | データ確認 |
| `MSG-RPT-033` | E | 指定的分析条件无效。 | 条件不正 | 修正 |
| `MSG-RPT-034` | W | 明细超过 10,000 件，请使用导出功能。 | 件数超過 | 出力 |
| `MSG-RPT-035` | I | 分析数据已更新。 | 抽出完了 | — |

## 12. 権限・セキュリティ

| 種別 | 内容 |
|---|---|
| 画面権限 | `report:sales:view`、`report:purchase:view`、`report:production:view`、`report:finance:view`、`report:inventory:view`、`report:analysis:export` |
| データ範囲 | 部門・担当顧客・倉庫単位。全社権限は経営層・財務のみ |
| 項目権限 | 原価・粗利・人件費は財務権限者のみ |
| 監査 | 分析閲覧・出力を `rpt_query_log` に記録 |
| 出力 | Excel にユーザ名・日時を透かし表示 |

## 13. 性能・非機能

| 項目 | 目標 | 前提 |
|---|---|---|
| 月次分析表示 | 3 秒以内 | 抽出テーブル + 索引 |
| 日次分析表示 | 3 秒以内 | 直近 90 日 |
| ドリルダウン | 5 秒以内（10,000 件） | 索引（日付・次元） |
| 抽出（1 日分） | 5 分以内/IF | 50 万行以下 |
| 抽出（月次再計算） | 60 分以内 | 非同期 |

## 14. テスト観点

| No | 観点 ID | 分類 | 観点 | 期待結果 |
|---|---|---|---|---|
| 1 | TST-F-RPT-003-01 | 正常系 | 月次売上と業務域の一致 | 差異 0 |
| 2 | TST-F-RPT-003-02 | 正常系 | 顧客別構成比の合計 | 100% |
| 3 | TST-F-RPT-003-03 | 異常系 | 分母 0 | `NULL`、0 除算なし |
| 4 | TST-F-RPT-003-04 | 正常系 | OTD の数量按分 | 業務域と一致 |
| 5 | TST-F-RPT-003-05 | 冪等 | 同日抽出の再実行 | 重複しない |
| 6 | TST-F-RPT-003-06 | 権限 | 範囲外顧客 | 表示されない |
| 7 | TST-F-RPT-004-01 | 正常系 | 入荷額と PUR の一致 | 差異 0 |
| 8 | TST-F-RPT-004-02 | 正常系 | 供應商交付率 | `pur_supplier_performance` と一致 |
| 9 | TST-F-RPT-004-03 | 正常系 | 三单匹配率 | 一致 |
| 10 | TST-F-RPT-004-04 | 正常系 | 库存周转率（KPI-RPT-024） | 手計算と一致 |
| 11 | TST-F-RPT-004-05 | 境界 | 期首在庫 0 | `NULL`、エラーなし |
| 12 | TST-F-RPT-004-06 | 正常系 | 庫齢区分の合計 | 総在庫金額と一致 |
| 13 | TST-F-RPT-005-01 | 正常系 | 良品率 | 報工データと一致 |
| 14 | TST-F-RPT-005-02 | 正常系 | 計画達成率 | 工单データと一致 |
| 15 | TST-F-RPT-006-01 | 正常系 | 毛利率 | 財務諸表と一致 |
| 16 | TST-F-RPT-006-02 | 正常系 | DSO | 手計算と一致 |
| 17 | TST-F-RPT-006-03 | 異常系 | 期間未確定 | 暫定表示 |
| 18 | TST-F-RPT-008-01 | 正常系 | 抽出ジョブ | 件数・金額が一致 |
| 19 | TST-F-RPT-008-02 | 異常系 | 抽出失敗 | ロールバック、`MSG-RPT-030` |
| 20 | TST-F-RPT-008-03 | 性能 | 1 日分抽出 | 5 分以内 |

## 15. 未決事項

| # | 事項 | 理由 | 暫定仕様 | 担当 | 期限 |
|---|---|---|---|---|---|
| 1 | 库存周转率の分子（销售成本 vs 全部出库成本）（**已裁决** 2026-10-20） | 05 域 CALC-06（运营口径）と本域 KPI-RPT-024（经营口径） | 本域は销售成本口径、INV は全出库成本口径で併用（混在させない） | Lead | 完了（2026-10-20） |
| 2 | `product_series` の持ち方 | MDM に列が未定義 | `mdm_material_category.category_code` から導出（3001/3002/3003） | MDM／analytics | 2026-12-15 |
| 3 | 05-inventory の物理項目名（**已解消** 2026-10-20） | 90-db-design は 2026-10-20 に刊行済み | 実テーブル名・項目名と突合済み（inv_stock_balance/inv_stock_txn/inv_stock_txn_line 等） | analytics | 完了（2026-10-20） |
| 4 | 採購降本率の加重方法 | 品目構成の変化をどう除くか | 同一品目群の数量加重。実装時に確定 | 購買／analytics | 2026-12-15 |
| 5 | 粗利の原価（暫定/確定） | FIN 月結前は未確定 | 月結前は SI 出庫原価、月結後に再計算 | 財務 | 2026-12-15 |
| 6 | `pur_invoice_match.match_status` の値 | 04 域の詳細確認が必要 | 10/20 を一致・容差内として集計 | PUR／analytics | 2026-12-15 |
| 7 | 分析用の月次パーティション | 容量 | Phase 1 は単一テーブル、Phase 2 で月次 | 情報部 | 2027-03-31 |

## 16. 改訂履歴

| 版数 | 日付 | 変更内容 | 変更者 |
|---|---|---|---|
| v1.0 | 2026-10-20 | 初版：抽出マッピング 5 表、销售 8・采购 6・库存 6・生产 6・财务 6 の SQL 思路、画面 5、処理詳細、テスト観点 20 | analytics-designer |
