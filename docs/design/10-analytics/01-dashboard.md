# 经营驾驶舱・KPI 指标管理 详细设计书（経営ダッシュボード・KPI 管理 詳細設計書）

| 項目 | 内容 |
|---|---|
| 文書名 | 经营驾驶舱・KPI 指标管理 详细设计书（経営ダッシュボード・KPI 管理 詳細設計書） |
| 文書番号 | DSN-RPT-001 |
| 版数 | v1.0 |
| 作成日 | 2026-10-20 |
| 作成者 | analytics-designer（報表分析分野担当） |
| 承認者 | 未承認（レビュー待ち） |
| 状態 | ドラフト（レビュー中） |
| 関連文書 | [業務域概要](00-overview.md) / [域分析](02-domain-analysis.md) / [予警・订阅](03-warning-subscription.md) / [DB 設計](90-db-design.md) / [共通业务规则](../00-common/08-common-business-rules.md) / [跨域流程](../00-common/09-cross-domain-flow.md) |

---

## 1. 機能概要

| 項目 | 内容 |
|---|---|
| 機能 ID | F-RPT-001（经营驾驶舱）、F-RPT-002（KPI 指标管理）、F-RPT-007（KPI 校验与数据质量）、F-RPT-010（移动端/大屏・P2） |
| 機能名 | 经营驾驶舱／KPI 指标管理 |
| 目的 | 経営 KPI を一画面に集約し、算式・出所・更新頻度・権限を一元管理する。KPI の異常を早期に発見し、現場の分析へ導く |
| 利用者・ロール | 总经理、财务总监、部門経理、経営企画、内審員、システム管理者 |
| 利用シーン | 日次朝会、月次経営会議、四半期レビュー、KPI 定義の改訂、監査対応 |
| 優先度 | F-RPT-001/002/007＝P0、F-RPT-010＝P2 |
| 画面 ID | SCR-RPT-001、002、008〜010、019、020 |
| 関連 IF | IF-RPT-001（抽出）、IF-RPT-005（監査ログ参照） |

---

## 2. 業務要件・業務ルール

### 2.1 KPI 定義の原則（口径の唯一性）

| # | 原則 | 内容 |
|---|---|---|
| P-01 | **単一定義源** | KPI の算式・次元・出所・丸め・更新頻度は `rpt_kpi_definition` のみに定義する。画面・帳票・予警・订阅はすべて同定義を参照する |
| P-02 | **業務域との一致** | KPI の構成要素は業務域の実テーブル・実項目に対応させる（`rpt_kpi_lineage`）。業務域が算式を変えた場合は KPI を同時に改訂する |
| P-03 | **出荷基準** | 売上・粗利は出荷確定（E10）基準で計上する（[09 §7.3](../00-common/09-cross-domain-flow.md)）。発票発行時点では変えない |
| P-04 | **税抜・CNY** | 金額は税抜・CNY を既定とする。税込が必要な KPI は名称に「（含税）」を付ける。外貨は換算後 CNY |
| P-05 | **丸め** | KPI 値は表示時に丸める。率は小数 2 桁（`24.35%`）、金額は 2 桁、日数は小数 1 桁。**計算途中では丸めない** |
| P-06 | **期首・期末の定義** | 月次は月初日の前日終値（＝前月末）を期首、当月末を期末とする。年次は 12 か月の月末平均を用いる（§2.3） |
| P-07 | **改訂の統制** | KPI 定義の変更は版数を +1 し、財務総監の承認を要する。変更前のスナップショットは保持する（遡及再計算しない） |
| P-08 | **欠測の扱い** | 構成要素が欠測の場合、KPI は `NULL`（表示「-」）とし、0 として扱わない。欠測理由を `rpt_data_quality_check` に記録する |

### 2.2 KPI の次元（ディメンション）

| 次元 | 値の例 | 主な用途 |
|---|---|---|
| 期間 | 日 / 週 / 月 / 四半期 / 年 / 任意期間 | すべての KPI |
| 会社・工場 | 1（会社）、CZ01 / WX01 | 拠点比較 |
| 部門 | D010 销售 / D020 采购 / D030 生产 / D050 财务 | 部門評価 |
| 顧客 | `customer_id`、顧客分類（A/B/C） | 销售分析 |
| 供應商 | `supplier_id`、協力等級 | 采购分析 |
| 物料・分類 | `material_id`、分類コード（1001/3001 等） | 库存・生产分析 |
| 倉庫 | WH01 / WH02 / WH03 | 库存分析 |
| 製品系列 | YE3 / YVF / 非標 | 产品分析 |
| 客户行业 | GB/T 4754-2017 大類（C38 等） | 市场分析 |

> 次元の組合せは KPI ごとに `rpt_kpi_definition.dimensions_json` で定義する。定義にない次元での集計は行わない（口径の逸脱を防ぐ）。

### 2.3 期首・期末・平均の定義（唯一）

```
月次 KPI：
  期首在庫金額 = 前月末日の在庫金額合計（rpt_inventory_snapshot の月末値）
  期末在庫金額 = 当月末日の在庫金額合計
  平均在庫金額 = (期首在庫金額 + 期末在庫金額) ÷ 2          … CALC-RPT-01

年次 KPI：
  平均在庫金額 = 12 か月の月末在庫金額の単純平均             … CALC-RPT-02
  （1 月のみ月次と同じ。年度途中は既存月の平均）

売上・費用：
  期間発生額 = 対象期間の fin_voucher_line 借方/貸方発生額（損益科目）
  平均残高（AR/AP/在庫） = (期首残高 + 期末残高) ÷ 2        … CALC-RPT-03
```

> 年次の平均在庫に「(年初+年末)÷2」は**使わない**（季節変動が大きいため）。月次は (期首+期末)÷2 で統一する。

### 2.4 業務ルール

| # | ルール | 根拠 | 関連項目 |
|---|---|---|---|
| BR-KPI-01 | KPI は「定義 → 計算 → 快照 → 表示」の順で確定する。画面表示時に都度集計しない（性能・口径の一貫性） | 本設計 | `rpt_kpi_snapshot` |
| BR-KPI-02 | 日次 KPI は前日分を BAT-RPT-006 で計算し、08:00 までに更新する。月次 KPI は BAT-RPT-007 で確定する | 本設計 | BAT-RPT-006/007 |
| BR-KPI-03 | 月次確定後の KPI は変更しない。修正は翌月の調整として扱い、過去月を書き換えない | 本設計 | `snapshot_status` |
| BR-KPI-04 | 比率 KPI は分子・分母を同時に保持する（例：毛利率の分子=毛利、分母=营业收入）。分母 0 は `NULL` | 本設計 | `numerator_value`、`denominator_value` |
| BR-KPI-05 | 目標値は期間・組織別に `rpt_kpi_target` で管理する。目標未設定の KPI は達成率を表示しない | 本設計 | `target_value` |
| BR-KPI-06 | KPI の色分けは「目標比」で行う（緑 ≥ 100%、黄 90〜100%、赤 < 90%、逆指標は反転） | 本設計 | `direction` |
| BR-KPI-07 | ドリルダウンは KPI の次元に沿って明細へ遷移する。明細は RPT の抽出テーブルのみ参照する（業務域を直接参照しない） | 本設計 | `rpt_*_detail` |
| BR-KPI-08 | 監査・内部統制のため、KPI 閲覧・輸出を `rpt_query_log` に記録する（誰が・いつ・どの KPI・どの条件） | 本設計 | `rpt_query_log` |
| BR-KPI-09 | 従業員数・人均产值の従業員数は SYS の有効ユーザ数を用いる（人事システム連携は Phase 2）。分母の定義を画面に明記する | 本設計 | `sys_user` |
| BR-KPI-10 | 驾驶舱はロール別に表示 KPI を変える（経営層 12、部門経理 8、現場 6）。権限外 KPI は API でも返さない | 本設計 | `rpt_dashboard_widget` |

---

## 3. KPI 定義表（唯一の口径）

> 40 KPI。**算式は本表が唯一**であり、他文書・画面・帳票は本表を参照する。`更新` は日次（D）/月次（M）/四半期（Q）/年次（Y）。`権限` は閲覧に必要な権限コード。目標値は【示例値】。

### 3.1 経営・財務（F01〜F12）

| KPI ID | KPI 名 | 算式（口径） | 単位 | 主な次元 | データ来源（表.項目） | 更新 | 権限 | 目標【示例値】 |
|---|---|---|---|---|---|---|---|---|
| KPI-RPT-001 | 营业收入 | 主营业务收入净额 = Σ`fin_voucher_line`（`account_code` 先頭 6001）貸方 − 借方（赤伝） | CNY | 期間・部門・製品系列 | `fin_voucher_line.account_code/debit_amount/credit_amount`、`fin_voucher.period_code` | M | `report:finance:view` | 8.0 亿元/年 |
| KPI-RPT-002 | 毛利 | 营业收入 − 营业成本（6401 净額） | CNY | 期間・製品・顧客 | `fin_voucher_line`（6001、6401） | M | `report:finance:view` | 1.92 亿元/年 |
| KPI-RPT-003 | 毛利率 | 毛利 ÷ 营业收入 × 100 | % | 期間・製品系列・顧客 | 同上 | M | `report:finance:view` | 24.0% |
| KPI-RPT-004 | 净利率 | 净利润 ÷ 营业收入 × 100。净利润は `fin_statement_snapshot` の利润表「净利润」行 | % | 期間 | `fin_statement_snapshot`、`fin_voucher_line` | M | `report:finance:view` | 3.0% |
| KPI-RPT-005 | 期间费用率 | (销售费用 6601 + 管理费用 6602 + 财务费用 6603) ÷ 营业收入 × 100 | % | 期間・部門 | `fin_voucher_line`（6601/6602/6603） | M | `report:finance:view` | 7.0% |
| KPI-RPT-006 | 应收账款周转天数（DSO） | 平均应收账款 ÷ 营业收入 × 期间日数。平均 = (期初+期末)÷2 | 日 | 期間・顧客 | `fin_receivable.balance_amount`、`fin_account_balance`（1122）、`fin_voucher_line`（6001） | M | `report:finance:view` | ≤ 68 日 |
| KPI-RPT-007 | 应付账款周转天数（DPO） | 平均应付账款 ÷ 营业成本 × 期间日数。平均 = (期初+期末)÷2 | 日 | 期間・供應商 | `fin_payable.balance_amount`、`fin_account_balance`（2202）、`fin_voucher_line`（6401） | M | `report:finance:view` | ≤ 45 日 |
| KPI-RPT-008 | 资产负债率 | 负债合计 ÷ 资产合计 × 100（资产负债表快照） | % | 期末 | `fin_statement_snapshot` | M | `report:finance:view` | ≤ 55% |
| KPI-RPT-009 | 经营活动现金流 | 现金流量表（简表）经营活动产生的现金流量净额 | CNY | 期间 | `fin_statement_snapshot`、`fin_voucher_line.cash_flow_item_code` | M | `report:finance:view` | ≥ 5,000 万元/年 |
| KPI-RPT-010 | 人均产值 | 营业收入 ÷ 平均在籍人数。在籍人数 = `sys_user` 有効ユーザ数の期首期末平均 | CNY/人 | 期間 | `fin_voucher_line`（6001）、`sys_user` | M | `report:finance:view` | ≥ 89 万元/人 |
| KPI-RPT-011 | 预算达成率 | 实际营业收入 ÷ 预算营业收入 × 100（FIN 预算・P2） | % | 期間・部門 | `fin_budget_line`（P2）、`fin_voucher_line` | M | `report:finance:view` | 100%±5% |
| KPI-RPT-012 | 收入增长率 | (本期营业收入 − 上年同期营业收入) ÷ 上年同期营业收入 × 100 | % | 期間・製品系列 | `fin_voucher_line`（6001） | M | `report:finance:view` | ≥ 8% |

### 3.2 销售（F13〜F22）

| KPI ID | KPI 名 | 算式（口径） | 単位 | 主な次元 | データ来源（表.項目） | 更新 | 権限 | 目標【示例値】 |
|---|---|---|---|---|---|---|---|---|
| KPI-RPT-013 | 销售额 | Σ出荷確定の税抜金額（返品は控除）。`rpt_sales_detail.amount`（出荷基準） | CNY | 期間・顧客・製品・部門 | `sal_delivery_note_line.line_amount` → `rpt_sales_detail.amount` | D | `report:sales:view` | 8.0 亿元/年 |
| KPI-RPT-014 | 销量 | Σ出荷数量（基本単位に換算。PCE 換算表を明記） | PCE | 期間・製品系列・顧客 | `sal_delivery_note_line.shipped_qty`、`base_qty` | D | `report:sales:view` | 38 万台/年 |
| KPI-RPT-015 | 受注额 | Σ承認済受注の税抜金額（受注日基準） | CNY | 期間・顧客・営業担当 | `sal_sales_order_line.line_amount`、`sal_sales_order.order_status` | D | `report:sales:view` | 8.4 亿元/年 |
| KPI-RPT-016 | 订单达成率 | 受注額 ÷ 目標受注額 × 100 | % | 期間・部門 | `rpt_sales_detail`、`rpt_kpi_target` | M | `report:sales:view` | ≥ 100% |
| KPI-RPT-017 | 交付达成率（OTD） | 按期出荷数量 ÷ 出荷数量 × 100。按期 = 出荷確定日 ≤ 受注明細納期。部分出荷は数量按分 | % | 期間・顧客・製品 | `sal_sales_order_line.delivery_date`、`sal_delivery_note_line.shipped_qty`、出荷確定日 → `rpt_sales_detail.due_date/ship_date` | D | `report:sales:view` | ≥ 96% |
| KPI-RPT-018 | 受注〜出荷リードタイム | AVG(初回出荷確定日 − 受注日)、営業日ベース | 日 | 期間・製品系列 | `sal_sales_order.order_date`、`sal_delivery_note` 確定日 | M | `report:sales:view` | ≤ 3 営業日 |
| KPI-RPT-019 | 客单价 | 销售额 ÷ 受注件数（受注ヘッダ件数） | CNY/件 | 期間・部門 | `rpt_sales_detail`（出荷額）、`sal_sales_order`（件数） | M | `report:sales:view` | ≥ 2,105 元/件 |
| KPI-RPT-020 | 客户集中度（CR5） | 上位 5 顧客の销售额 ÷ 総销售额 × 100 | % | 期間 | `rpt_sales_detail.customer_id/amount` | M | `report:sales:view` | ≤ 45% |
| KPI-RPT-021 | 退货率 | 退货金额 ÷ 出荷金额 × 100（金額は税抜） | % | 期間・顧客・製品 | `sal_sales_return_line.line_amount`、`rpt_sales_detail.amount` | M | `report:sales:view` | < 1% |
| KPI-RPT-022 | 与信超限发生率 | 与信超限受注件数 ÷ 受注件数 × 100 | % | 期間・部門 | `sal_sales_order.credit_check_result`（30/40） | M | `report:sales:view` | < 2% |

### 3.3 库存（F23〜F28）

| KPI ID | KPI 名 | 算式（口径） | 単位 | 主な次元 | データ来源（表.項目） | 更新 | 権限 | 目標【示例値】 |
|---|---|---|---|---|---|---|---|---|
| KPI-RPT-023 | 库存金额 | Σ`inv_stock_balance.amount_on_hand`（全状態、月末/日次） | CNY | 期間・倉庫・分類 | `inv_stock_balance.amount_on_hand` → `rpt_inventory_snapshot` | D | `report:inventory:view` | 1.3 亿元 |
| KPI-RPT-024 | **库存周转率** | **销售成本 ÷ 平均库存金额（次/年）**。销售成本 = 主营业务成本 6401 借方発生額（月結後）。未月結時は Σ SI 出庫成本（`inv_stock_txn_line` txn_type=`SI`）を暫定使用。平均库存金额 = (期初+期末)÷2（月次）、12 か月月末平均（年次） | 次 | 期間・倉庫・分類 | `fin_voucher_line`（6401）／`inv_stock_txn_line`（SI, amount）、`inv_stock_balance.amount_on_hand`／`rpt_inventory_snapshot` | M | `report:inventory:view` | ≥ 6 次/年 |
| KPI-RPT-025 | 库存周转天数 | 平均库存金额 ÷ 销售成本 × 期間日数（= 期間日数 ÷ 库存周转率） | 日 | 期間・倉庫・分類 | 同 KPI-RPT-024 | M | `report:inventory:view` | ≤ 61 日 |
| KPI-RPT-026 | 呆滞库存占比 | 庫齢 > 365 日の在庫金額 ÷ 総在庫金額 × 100（`inv_age_snapshot` の `age_bucket='366+'`） | % | 期末・倉庫・分類 | `inv_age_snapshot.age_bucket/amount` | M | `report:inventory:view` | ≤ 5% |
| KPI-RPT-027 | 库存准确率 | (1 − Σ\|盘点差异金額\| ÷ Σ帳簿金額) × 100 | % | 期間・倉庫 | `inv_stocktake_line`、`inv_stock_balance` | M | `report:inventory:view` | ≥ 99.5% |
| KPI-RPT-028 | 缺货率 | 可用量 < 安全在庫の品目数 ÷ 在庫管理対象品目数 × 100 | % | 日次・倉庫・分類 | `inv_replenishment.available_qty/safety_stock`、`mdm_material` | D | `report:inventory:view` | ≤ 2% |

> **口径注記（重要）**：[05-inventory/07-reports.md](../05-inventory/07-reports.md) CALC-06 の「库存周转率＝期間出庫成本 ÷ 平均在庫金額」は**明細レベル（倉庫・物料別、全出庫）**の業務指標である。本表 KPI-RPT-024 は**企业级 KPI** として分子を「销售成本」に限定する（生产领料・调拨・其他出库を含めない）。両者は用途が異なるため、画面では「企业库存周转率（销售成本口径）」と「明细周转率（全部出库口径）」を区別して表示し、混在させない。**Lead 裁定（2026-10-20）：両口径を併用**とし、企業 KPI は销售成本口径、明细・运营指标は全出库成本口径とする（[00-overview §12](00-overview.md) #1）。

### 3.4 采购（F29〜F34）

| KPI ID | KPI 名 | 算式（口径） | 単位 | 主な次元 | データ来源（表.項目） | 更新 | 権限 | 目標【示例値】 |
|---|---|---|---|---|---|---|---|---|
| KPI-RPT-029 | 采购额 | Σ入荷確定の税抜金額（`pur_receipt_line` の税抜金額、返品控除） | CNY | 期間・供應商・分類 | `pur_receipt_line.amount` → `rpt_purchase_detail.amount` | D | `report:purchase:view` | 5.2 亿元/年 |
| KPI-RPT-030 | 采购降本率 | (1 − 当期加重平均単価 ÷ 前期加重平均単価) × 100。同一品目群（前後期とも取引あり）に限定 | % | 期間・供應商・分類 | `pur_receipt_line.unit_price/quantity` → `rpt_purchase_detail` | M | `report:purchase:view` | ≥ 2% |
| KPI-RPT-031 | 供应商按期交付率 | 按期入荷行数 ÷ 入荷行数 × 100（`pur_supplier_performance`） | % | 期間・供應商 | `pur_supplier_performance.on_time_line_count/receipt_line_count` | M | `report:purchase:view` | ≥ 95% |
| KPI-RPT-032 | 来料检验合格率 | IQC 合格数量 ÷ 受入数量 × 100 | % | 期間・供應商・分類 | `pur_receipt_line`（検査結果）、`prd_inspection`（IQC） | M | `report:purchase:view` | ≥ 98% |
| KPI-RPT-033 | 供应商集中度（CR5） | 上位 5 供應商の采购额 ÷ 総采购额 × 100 | % | 期間 | `rpt_purchase_detail.supplier_id/amount` | M | `report:purchase:view` | ≤ 60% |
| KPI-RPT-034 | 三单匹配自动通过率 | 自動匹配成功（一致＋容差内）行数 ÷ 匹配対象行数 × 100 | % | 期間・供應商 | `pur_invoice_match.match_status`、`pur_receipt_line` | M | `report:purchase:view` | ≥ 85% |

### 3.5 生产・品質（F35〜F40）

| KPI ID | KPI 名 | 算式（口径） | 単位 | 主な次元 | データ来源（表.項目） | 更新 | 権限 | 目標【示例値】 |
|---|---|---|---|---|---|---|---|---|
| KPI-RPT-035 | 产量 | Σ完工入庫良品数（`prd_work_order.completed_qty`、完工日基準） | PCE | 日次・工場・製品系列 | `prd_work_order.completed_qty/actual_end_date` | D | `report:production:view` | 38 万台/年 |
| KPI-RPT-036 | 计划达成率 | 計画完工日までに完工した工单数 ÷ 当期計画完工工单数 × 100 | % | 期間・工場 | `prd_work_order.planned_end_date/actual_end_date/order_status` | D | `report:production:view` | ≥ 95% |
| KPI-RPT-037 | 良品率 | 良品数 ÷ (良品数 + 不良数 + 报废数) × 100（報工ベース） | % | 期間・工場・工序 | `prd_work_report.reported_good_qty/defect_qty/scrap_qty` | D | `report:production:view` | ≥ 98.5% |
| KPI-RPT-038 | 一次通过率（FPY） | 初回検査合格数 ÷ 初回送检数 × 100（IPQC/FQC） | % | 期間・製品・工序 | `prd_inspection.inspection_result`、`prd_inspection_line` | D | `report:production:view` | ≥ 96% |
| KPI-RPT-039 | 工单生产周期 | AVG(実際完工日 − 下达日)、日 | 日 | 期間・工場・製品 | `prd_work_order.released_at/actual_end_date` | M | `report:production:view` | ≤ 5 日 |
| KPI-RPT-040 | 工单成本差异率 | \|実際完工成本 − 標準成本 × 完工数量\| ÷ (標準成本 × 完工数量) × 100 | % | 期間・製品・工单 | `prd_work_order.actual_total_cost/standard_cost/completed_qty`、`fin_cost_variance` | M | `report:finance:view` | ≤ 5% |

> **KPI 数の内訳**：経営財務 12、销售 10、库存 6、采购 6、生产品質 6 = **40 KPI**。うち P2 は KPI-RPT-011 のみ。更新頻度は日次 11、月次 29（P2 含む）。

---

## 4. 驾驶舱（SCR-RPT-001）

### 4.1 レイアウト

```
┌──────────────────────────────────────────────────────────────┐
│ 华东精密电机股份有限公司  经营驾驶舱   期间[2026-10 ▾]  ↻ 更新  │
├──────────────────────────────────────────────────────────────┤
│ 〔KPI カード 12〕                                             │
│ 营业收入 │ 毛利率 │ 净利率 │ 库存周转率 │ 交付达成率 │ 产量   │
│ 采购额   │ 应收DSO│ 呆滞占比│ 计划达成率│ 与信超限率 │ 现金流 │
├───────────────────────────────┬──────────────────────────────┤
│ 売上・利益トレンド（12 か月）  │ 製品系列別 売上構成（円）     │
├───────────────────────────────┼──────────────────────────────┤
│ 在庫金額・回転トレンド         │ 主要 KPI 目標比（横棒）       │
├───────────────────────────────┴──────────────────────────────┤
│ 〔予警・トピック〕 直近の予警 5 件 / KPI コメント             │
└──────────────────────────────────────────────────────────────┘
```

### 4.2 表示 KPI（ロール別）

| ロール | カード数 | KPI |
|---|---|---|
| 経営層 | 12 | 001、003、004、024、017、035、029、006、026、036、022、009 |
| 財務 | 10 | 001、002、003、004、005、006、007、008、009、040 |
| 销售 | 8 | 013、014、015、016、017、019、020、021 |
| 采购 | 8 | 029、030、031、032、033、034、023、028 |
| 生产・計画 | 8 | 035、036、037、038、039、040、023、028 |
| 全社共通 | 6 | 001、003、017、024、029、035（現場向け） |

### 4.3 画面項目定義（SCR-RPT-001）

| No | 項目 ID | 項目名 | 種別 | 型/桁 | 必須 | 初期値 | 入力チェック | データソース | DB 項目 |
|---|---|---|---|---|---|---|---|---|---|
| 1 | period_code | 期間 | 選択 | VARCHAR(7) | ○ | 当月 | 有効期間 | `fin_period` | `rpt_kpi_snapshot.period_code` |
| 2 | factory_id | 工場 | 選択 | BIGINT | △ | 全社 | 有効工場 | `mdm_factory` | `dimension_json.factoryId` |
| 3 | kpi_code | KPI | 表示 | VARCHAR(32) | — | — | — | 定義 | `rpt_kpi_definition.kpi_code` |
| 4 | value | 実績値 | 表示 | DECIMAL | — | — | — | 快照 | `rpt_kpi_snapshot.value` |
| 5 | target_value | 目標値 | 表示 | DECIMAL | — | — | — | 目標 | `rpt_kpi_target.target_value` |
| 6 | achievement_rate | 達成率 | 表示 | DECIMAL(7,2) | — | — | — | 計算 | — |
| 7 | trend | トレンド | グラフ | — | — | 12 か月 | — | 快照 | — |
| 8 | warning_count | 予警件数 | 表示 | INT | — | — | — | 予警 | `rpt_warning_event` |
| 9 | comment | コメント | テキスト | VARCHAR(1000) | △ | 空 | 500 字以内 | 入力 | `rpt_kpi_comment.comment` |

### 4.4 KPI 定義編集（SCR-RPT-009）

| No | 項目 ID | 項目名 | 種別 | 型/桁 | 必須 | 初期値 | 入力チェック | DB 項目 |
|---|---|---|---|---|---|---|---|---|
| 1 | kpi_code | KPI コード | テキスト | VARCHAR(32) | ○ | 空 | `KPI-RPT-\d{3}`、一意 | `kpi_code` |
| 2 | kpi_name | KPI 名 | テキスト | VARCHAR(200) | ○ | 空 | 桁数 | `kpi_name` |
| 3 | category | 分類 | 選択 | VARCHAR(32) | ○ | 空 | FINANCE/SALES/INVENTORY/PURCHASE/PRODUCTION | `category` |
| 4 | formula | 算式 | テキスト | TEXT | ○ | 空 | 構文チェック | `formula` |
| 5 | unit | 単位 | 選択 | VARCHAR(16) | ○ | 空 | CNY/%/日/次/PCE | `unit` |
| 6 | dimensions | 次元 | 複数選択 | JSONB | ○ | 空 | §2.2 の値のみ | `dimensions_json` |
| 7 | source_tables | 出所 | テキスト | TEXT | ○ | 空 | 実在テーブル | `rpt_kpi_lineage` |
| 8 | frequency | 更新頻度 | 選択 | VARCHAR(8) | ○ | M | D/M/Q/Y | `frequency` |
| 9 | direction | 方向 | 選択 | SMALLINT | ○ | 10 | 10 高いほど良い/20 低いほど良い | `direction` |
| 10 | permission_code | 権限 | テキスト | VARCHAR(64) | ○ | 空 | 実在権限 | `permission_code` |
| 11 | version_no | 版数 | 数値 | INT | ○ | 1 | 変更で +1 | `version_no` |
| 12 | effective_from | 適用開始 | 日付 | DATE | ○ | 当日 | — | `effective_from` |

### 4.5 イベント処理

| No | イベント | トリガ | 処理内容 | 呼出 API | 画面遷移 |
|---|---|---|---|---|---|
| 1 | 期間切替 | 選択 | KPI 快照を取得 | `GET /api/report/dashboard` | 同一画面 |
| 2 | KPI カード選択 | クリック | KPI 詳細・トレンド | `GET /api/report/kpis/{code}` | SCR-RPT-010 |
| 3 | ドリルダウン | 右クリック/リンク | 明細へ | `GET /api/report/analysis/details` | SCR-RPT-016 |
| 4 | コメント保存 | 保存 | コメント登録 | `POST /api/report/kpi-comments` | 同一画面 |
| 5 | レイアウト保存 | 保存 | ウィジェット配置 | `PUT /api/report/dashboards/{id}` | SCR-RPT-001 |
| 6 | KPI 定義保存 | 保存 | 版数 +1、承認へ | `PUT /api/report/kpis/{code}` | SCR-RPT-008 |
| 7 | 再計算 | ボタン | 対象期間の再計算（管理者） | `POST /api/report/etl/recalculate` | SCR-RPT-018 |

### 4.6 表示制御

| 条件 | 対象 | 制御 |
|---|---|---|
| 権限なし KPI | カード | 非表示（API でも返さない） |
| 目標未設定 | 達成率・色 | 「-」表示、色なし |
| 値 `NULL`（欠測） | カード | 「-」＋欠測理由ツールチップ |
| 月次未確定 | カード | 「暫定」バッジ |
| 前月比が計算不能（前月 0） | トレンド | 「-」 |

---

## 5. 入力チェック仕様

| No | チェック ID | 対象 | 種別 | 条件 | タイミング | メッセージ |
|---|---|---|---|---|---|---|
| 1 | CHK-RPT-001-01 | 期間 | 必須 | 有効な会計期間 | 表示時 | `MSG-RPT-002` |
| 2 | CHK-RPT-001-02 | KPI コード | 形式 | `KPI-RPT-\d{3}` | 保存時 | `MSG-RPT-010` |
| 3 | CHK-RPT-001-03 | 算式 | 構文 | 許可関数・実在項目のみ | 保存時 | `MSG-RPT-011` |
| 4 | CHK-RPT-001-04 | 次元 | 値域 | §2.2 の次元のみ | 保存時 | `MSG-RPT-012` |
| 5 | CHK-RPT-001-05 | 出所 | 存在 | 実在テーブル・項目 | 保存時 | `MSG-RPT-013` |
| 6 | CHK-RPT-001-06 | コメント | 桁数 | 500 字以内 | 保存時 | `MSG-COM-041` |
| 7 | CHK-RPT-001-07 | KPI 重複 | 一意 | 同一コードなし | 保存時 | `MSG-RPT-014` |
| 8 | CHK-RPT-001-08 | 分母 0 | 業務 | 率 KPI の分母 ≠ 0 | 計算時 | `MSG-RPT-015`（警告） |

---

## 6. 処理詳細

### 6.1 処理一覧

| 処理 ID | 処理名 | 契機 | トランザクション | 排他 |
|---|---|---|---|---|
| PRC-RPT-001-01 | KPI 日次計算 | BAT-RPT-006 | 要（日付単位） | 日付×KPI 一意 |
| PRC-RPT-001-02 | KPI 月次確定 | BAT-RPT-007 | 要（期間単位） | 期間×KPI 一意 |
| PRC-RPT-001-03 | 驾驶舱表示 | 画面 | 不要（読取） | — |
| PRC-RPT-001-04 | KPI 定義更新 | 保存 | 要 | 楽観排他（`version`） |
| PRC-RPT-001-05 | KPI 整合性校验 | BAT-RPT-010 | 不要（検査） | — |
| PRC-RPT-001-06 | 再計算 | 手動 | 要（期間） | ジョブ多重起動防止 |

### 6.2 処理手順（正常系）

**PRC-RPT-001-01 KPI 日次計算**

1. 対象日・対象 KPI（`frequency=D`）を決定する。
2. `rpt_kpi_definition` から算式・次元・出所を取得する。
3. 出所テーブル（`rpt_sales_detail` 等）から対象日・次元別に分子・分母を集計する。
4. 比率 KPI は分子・分母を保持したまま値を計算し、丸めは表示時のみ行う。
5. `rpt_kpi_snapshot` に UPSERT（日付×KPI×次元）。`snapshot_status=10`（暫定）。
6. 目標値（`rpt_kpi_target`）を付与し、達成率を計算する。
7. 欠測・分母 0 は `NULL` とし、`rpt_data_quality_check` に記録する。

**PRC-RPT-001-02 KPI 月次確定**

1. 前月の日次 KPI と月次 KPI（`frequency=M`）を計算する。
2. 業務域の月次確定値（`fin_statement_snapshot`、`inv_stock_summary`）と突合する。
3. 差異が許容範囲（±0.5% または ±1 単位）内であることを確認する。
4. `snapshot_status=40`（確定）とし、以後の再計算を禁止する（`BAT-RPT-011` でも確定値は上書きしない）。
5. 月報（PRT-RPT-001/002）を生成し、订阅へ引き渡す。

**PRC-RPT-001-05 KPI 整合性校验**

1. KPI ごとに「業務域集計値」と「RPT 快照値」を比較する。
2. 差異率 > 0.5% または絶対値 > 1 の場合は `rpt_data_quality_check` に `status=20`（差異）で記録する。
3. 差異理由（抽出遅延・定義変更・原価未確定）を分類し、アラートする。
4. 月結前に差異 0 件であることを確認する（FIN 月結チェックの前提）。

### 6.3 例外処理

| No | 異常条件 | 検知 | 処理 | ロールバック | メッセージ |
|---|---|---|---|---|---|
| 1 | 抽出データ欠測 | 計算 | KPI を `NULL`、理由記録 | なし | `MSG-RPT-003` |
| 2 | 分母 0 | 計算 | `NULL`、警告 | なし | `MSG-RPT-015` |
| 3 | 業務域と差異 | 校验 | 差異記録・アラート | なし | `MSG-RPT-020` |
| 4 | 確定後の再計算 | 再計算 | 拒否 | なし | `MSG-RPT-021` |
| 5 | KPI 定義の構文エラー | 保存 | 保存拒否 | 全体 | `MSG-RPT-011` |
| 6 | 期間未確定での月報 | 出力 | 暫定表示、確定後に再出力 | なし | `MSG-RPT-022` |
| 7 | 同時再計算 | ジョブ | ロックで拒否 | なし | `MSG-COM-035` |

### 6.4 冪等性・再実行

- KPI 計算は日付×KPI×次元の UPSERT。再実行は暫定値のみ上書き（確定値は不可）。
- 月次確定は期間×KPI の一意制約。確定済みは `MSG-RPT-021`。
- 再計算はジョブ ID で多重起動を防止する。
- コメントは追記（編集・削除は管理者のみ非表示）。

---

## 7. API 設計

| No | メソッド | パス | 権限 | 概要 |
|---|---|---|---|---|
| 1 | GET | `/api/report/dashboard` | `report:dashboard:view` | 驾驶舱データ（期間・工場） |
| 2 | GET | `/api/report/dashboards/{id}` | `report:dashboard:view` | レイアウト |
| 3 | PUT | `/api/report/dashboards/{id}` | `report:dashboard:update` | レイアウト保存 |
| 4 | GET | `/api/report/kpis` | `report:kpi:view` | KPI 一覧 |
| 5 | GET | `/api/report/kpis/{code}` | `report:kpi:view` | KPI 定義・トレンド |
| 6 | POST | `/api/report/kpis` | `report:kpi:update` | KPI 定義登録 |
| 7 | PUT | `/api/report/kpis/{code}` | `report:kpi:update` | KPI 定義更新（版数 +1） |
| 8 | GET | `/api/report/kpi-targets` | `report:kpi:view` | 目標一覧 |
| 9 | PUT | `/api/report/kpi-targets` | `report:kpi:update` | 目標更新 |
| 10 | POST | `/api/report/kpi-comments` | `report:dashboard:view` | コメント登録 |
| 11 | GET | `/api/report/quality-checks` | `report:quality:view` | 整合性検査結果 |
| 12 | POST | `/api/report/etl/recalculate` | `report:etl:run` | 再計算（非同期） |

### 7.1 レスポンス例（驾驶舱・【示例値】）

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "periodCode": "2026-10",
    "snapshotStatus": 10,
    "cards": [
      {
        "kpiCode": "KPI-RPT-001",
        "kpiName": "营业收入",
        "value": "682000000.00",
        "unit": "CNY",
        "targetValue": "800000000.00",
        "achievementRate": "85.25",
        "direction": 10,
        "trend": [{ "period": "2026-09", "value": "71200000.00" }]
      },
      {
        "kpiCode": "KPI-RPT-024",
        "kpiName": "库存周转率",
        "value": "5.12",
        "unit": "次",
        "targetValue": "6.00",
        "achievementRate": "85.33",
        "denominatorValue": "128000000.00",
        "numeratorValue": "655360000.00"
      }
    ]
  }
}
```

### 7.2 エラー例

```json
{ "code": 95001, "message": "该期间尚未生成 KPI 快照，请稍后刷新或联系管理员。", "data": { "periodCode": "2026-10" } }
```

---

## 8. データ更新仕様

| テーブル | 操作 | 更新項目 | トリガ |
|---|---|---|---|
| `rpt_kpi_definition` | INSERT/UPDATE | 定義・版数 | F-RPT-002 |
| `rpt_kpi_target` | INSERT/UPDATE | 目標値 | F-RPT-002 |
| `rpt_kpi_snapshot` | UPSERT | 値・分子分母・状態 | BAT-RPT-006/007 |
| `rpt_kpi_lineage` | INSERT/UPDATE | 出所・算式 | F-RPT-002 |
| `rpt_kpi_comment` | INSERT | コメント | F-RPT-001 |
| `rpt_dashboard` / `_widget` | INSERT/UPDATE | レイアウト | F-RPT-001 |
| `rpt_data_quality_check` | INSERT | 検査結果 | BAT-RPT-010 |
| `rpt_query_log` | INSERT | 閲覧・出力 | 全画面 |

---

## 9. エラー処理・メッセージ

| メッセージ ID | 種別 | 本文 | 発生条件 | 対処 |
|---|---|---|---|---|
| `MSG-RPT-001` | E | 没有查看该报表的权限。 | 権限なし | 管理者へ申请 |
| `MSG-RPT-002` | E | 指定的期间无效或尚未开始。 | 期間不正 | 期間選択 |
| `MSG-RPT-003` | W | 部分指标因数据未就绪显示为「-」。 | 欠測 | 抽出完了後に再表示 |
| `MSG-RPT-010` | E | KPI 代码格式不正确（应为 KPI-RPT-三位数字）。 | 形式違反 | 修正 |
| `MSG-RPT-011` | E | KPI 计算公式不正确，请检查函数与字段引用。 | 構文エラー | 修正 |
| `MSG-RPT-012` | E | 指定的维度不在允许范围内。 | 次元不正 | 修正 |
| `MSG-RPT-013` | E | 数据来源表或字段不存在。 | 出所不正 | 修正 |
| `MSG-RPT-014` | E | KPI 代码已存在。 | 重複 | 既存を編集 |
| `MSG-RPT-015` | W | 分母为 0，该比率指标无法计算。 | 分母 0 | データ確認 |
| `MSG-RPT-020` | W | KPI 与业务域汇总存在差异（{0}%），请确认。 | 差異 | 原因調査 |
| `MSG-RPT-021` | E | 该期间 KPI 已确定，不能重新计算。 | 確定済み | 翌月調整 |
| `MSG-RPT-022` | W | 月次 KPI 尚未确定，当前为暂定值。 | 未確定 | 確定後に再出力 |
| `MSG-RPT-023` | I | 重新计算任务已受理。 | 再計算受付 | ジョブ確認 |

---

## 10. 権限・セキュリティ

| 種別 | 内容 |
|---|---|
| 画面権限 | `report:dashboard:view/update`、`report:kpi:view/update`、`report:quality:view` |
| データ範囲 | ロールに応じて全社/部門/本人。KPI カードは権限外を返さない |
| 項目権限 | 金額・原価・人件費は財務権限者のみ |
| 監査 | KPI 閲覧・定義変更・出力を `rpt_query_log` と `sys_audit_log` に記録 |
| 個人情報 | 個人別売上・人件費は表示しない（部門・役職単位まで） |
| 出力 | Excel/PDF は透かし（ユーザ名・日時）を付与 |

---

## 11. 性能・非機能

| 項目 | 目標 | 前提 |
|---|---|---|
| 驾驶舱初期表示 | 3 秒以内（P95） | 12 カード、スナップショット参照 |
| KPI 詳細 | 2 秒以内 | 12 か月分 |
| ドリルダウン | 5 秒以内（1,000 件） | 抽出テーブル索引 |
| 日次 KPI 計算 | 30 分以内 | 40 KPI×次元 |
| 月次確定 | 60 分以内 | 月次集計含む |
| 同時閲覧 | 100 ユーザ | キャッシュ 60 秒 |

---

## 12. テスト観点

| No | 観点 ID | 分類 | 観点 | 期待結果 |
|---|---|---|---|---|
| 1 | TST-F-RPT-001-01 | 正常系 | 驾驶舱表示 | 12 カード、値・目標・達成率 |
| 2 | TST-F-RPT-001-02 | 権限 | 権限外 KPI | 非表示・API 返却なし |
| 3 | TST-F-RPT-001-03 | 異常系 | 欠測 | 「-」表示、理由記録 |
| 4 | TST-F-RPT-001-04 | 異常系 | 分母 0 | 「-」、`MSG-RPT-015` |
| 5 | TST-F-RPT-002-01 | 正常系 | KPI 定義登録 | 版数 1、承認待ち |
| 6 | TST-F-RPT-002-02 | 異常系 | 算式不正 | `MSG-RPT-011` |
| 7 | TST-F-RPT-002-03 | 排他 | 同時更新 | 409 |
| 8 | TST-F-RPT-002-04 | 監査 | 定義変更 | 前後値が監査ログに残る |
| 9 | TST-F-RPT-007-01 | 正常系 | 業務域と一致 | 差異 0、`status=10` |
| 10 | TST-F-RPT-007-02 | 異常系 | 差異 1% | `status=20`、アラート |
| 11 | TST-F-RPT-001-05 | 冪等 | 同日再計算 | 上書き、重複なし |
| 12 | TST-F-RPT-001-06 | 異常系 | 確定後の再計算 | `MSG-RPT-021` |
| 13 | TST-F-RPT-001-07 | 性能 | 12 か月トレンド | 2 秒以内 |
| 14 | TST-F-RPT-001-08 | 境界 | 期首在庫 0 の平均 | 0 除算しない（`NULL`） |

---

## 13. 未決事項

| # | 事項 | 理由 | 暫定仕様 | 担当 | 期限 |
|---|---|---|---|---|---|
| 1 | 库存周转率の分子（销售成本 vs 全部出库成本）（**已裁决** 2026-10-20） | 05 域 CALC-06（运营口径）と本域 KPI-RPT-024（经营口径）は用途が異なる | 本域は销售成本口径（企业 KPI）、INV は全出库成本口径（明细运营）。画面に口径を明記し、併用する | Lead | 完了（2026-10-20） |
| 2 | 人均产值の従業員数 | 人事システム未連携 | `sys_user` 有効ユーザ数。画面に注記 | 情報部 | 2026-12-15 |
| 3 | 净利润の出所（利润表快照 or 科目計算） | FIN の月結タイミング | `fin_statement_snapshot` を正とし、未確定時は「-」 | 財務 | 2026-12-15 |
| 4 | 目標値の承認フロー | 経営目標の決定プロセスが未確定 | 財務総監が入力、総経理が承認 | 経営層 | 2026-11-30 |
| 5 | 大屏（P2）の解像度・更新間隔 | 現場端末が未確定 | 1920×1080、60 秒更新 | 情報部 | Phase 2 |
| 6 | 标准成本の整備（KPI-RPT-040） | Phase 2（標準原価） | Phase 1 は実際原価のみ。差異率は「-」 | 財務 | Phase 2 |

## 14. 改訂履歴

| 版数 | 日付 | 変更内容 | 変更者 |
|---|---|---|---|
| v1.0 | 2026-10-20 | 初版：KPI 定義 40 件（口径・次元・出所・頻度・権限・目標）、驾驶舱、KPI 管理、整合性検査、API 12、テスト観点 | analytics-designer |
