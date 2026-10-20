# 财务管理域 验收标准（第一版全量・多租户・标准成本・成本核算）

| 項目 | 内容 |
|---|---|
| 文書名 | 财务管理域 验收标准 |
| 文書番号 | DSN-FIN-095 |
| 版数 | v1.1 |
| 作成日 | 2026-10-21 |
| 作成者 | 业务分析 |
| 状態 | ドラフト（レビュー待ち） |
| 関連文書 | [00-overview.md](00-overview.md) / [02-voucher-ledger.md](02-voucher-ledger.md) / [03-ap-payment.md](03-ap-payment.md) / [04-ar-receipt.md](04-ar-receipt.md) / [05-cashier-tax.md](05-cashier-tax.md) / [06-auto-voucher-costing.md](06-auto-voucher-costing.md) / [07-period-reporting.md](07-period-reporting.md) / [90-db-design.md](90-db-design.md) / [02-mdm 90](../02-mdm/90-db-design.md) / [05-inventory 02](../05-inventory/02-inbound-outbound.md) / [06-production 90](../06-production/90-db-design.md) / [00-common 10](../00-common/10-rls-and-db-roles.md) |

---

形式：G（Given）/ W（When）/ T（Then）。本書は既存設計の規則（BR / BC / CALC / TST）を検証可能な形に書き直したものであり、新しい業務規則は追加しない。未確定事項は末尾「未決」に記す。

## AC-FIN-01 分期表記なし（第一版全量）

- W：`docs/design/07-finance` を `Phase` / `フェーズ` / `分期` で grep。T：0 件（本 AC の検査文言を除く）。
- W：優先度の記述を確認。T：「P0/P1/P2 は全て第一版、実装順のみ」（[00-overview](00-overview.md) 機能一覧注記、[90](90-db-design.md) §1 #13）と矛盾する記述（「次期」「将来版で対応」等）がない。標準原価・RLS・P2 表は第一版に含まれる。

## AC-FIN-02 tenant_id / company_id

- W：[90-db-design.md](90-db-design.md) の全 DDL を確認。T：`tenant_id` は `NOT NULL DEFAULT current_setting('app.tenant_id')::bigint`、字面量默认租户（`DEFAULT 0` 等）なし。`scripts/check-tenant-default.sh` が OK。
- T：`company_id` は全テーブルで `NOT NULL` かつ既定値なし（`DEFAULT 1` が 0 件）。

## AC-FIN-03 一意索引は tenant_id 先頭

- W：業務一意索引（`uk_`）を DDL 本文・§7 索引一覧で確認。T：`(tenant_id, company_id, …)` で始まり、両者の列順が一致する（例：`uk_fin_voucher_no`、`uk_fin_voucher_source`、`uk_fin_receivable_source`、`uk_fin_payable_source`、`uk_fin_cost_collection`）。
- T：`fin_standard_cost` の `uk_fin_standard_cost_version` は `(tenant_id, company_id, material_id, cost_version)`、`uk_fin_standard_cost_period` は `(tenant_id, company_id, material_id, period_from) WHERE status=40`、`ex_fin_standard_cost_period` は `tenant_id, company_id, material_id` 先頭の EXCLUDE（90 §6.12・§7 #21/#22/#22a）。
- T：親 ID／イベント ID 先頭の一意索引は 90 §7.1 の例外一覧に全て列挙され、理由が書かれている。一覧外の非 tenant 先頭 `uk_` は 0 件。
- T（G2-20）：`company_id` 先頭は非一意 `idx_` のみ（例：`idx_fin_standard_cost_lookup`）。

## AC-FIN-04 RLS

- G：テナント A のセッション（`app.tenant_id=A`）。W：`fin_*` を SELECT。T：テナント B の行は返らない。全 `fin_*` が `ENABLE` + `FORCE ROW LEVEL SECURITY`、ポリシーは `tenant_id` のみで判定（`fin_standard_cost` は §6.12 DDL に `ENABLE`/`FORCE`/`rls_fin_standard_cost` を明記）（[90](90-db-design.md) §1、[00-common 10](../00-common/10-rls-and-db-roles.md)）。

## AC-FIN-05 凭证の借貸平衡と記帳

- W：借貸差 0.01 の凭证を保存。T：`MSG-FIN-001`、保存されない（[02](02-voucher-ledger.md) BR-01、CALC-01、TST-F-FIN-003-02）。
- W：1 行のみの凭证。T：`MSG-FIN-018`（BR-02、TST-F-FIN-003-03）。
- W：制单人自身で审核。T：`MSG-FIN-011`（BR-08、TST-F-FIN-005-02）。
- W：CLOSED 期間で反记账。T：`MSG-FIN-020`（BR-11、TST-F-FIN-007-02）。W：同一凭证を再度冲销。T：`MSG-FIN-033`（BR-12、TST-F-FIN-008-02、`uk_fin_voucher_reversal`）。

## AC-FIN-06 自動凭证の冪等性

- G：同一 `eventId` を 2 回処理。T：凭证 1 張のみ（[06](06-auto-voucher-costing.md) BR-03、TST-F-FIN-030-02）。`uk_fin_auto_voucher_log_event` と `uk_fin_voucher_source`（`tenant_id, company_id, source_type, source_id`）で保証。
- G：テンプレート未設定。W：消費。T：`FAILED`、`MSG-FIN-104`（TST-F-FIN-030-03）。リトライで成功時 `status=2`（TST-F-FIN-030-04）。

## AC-FIN-07 暂估 AP（E14）と来源値

- G：E14 受信。T：`fin_payable` に `source_type='PURCHASE_RECEIPT'`、`source_id=receiptId`、`accrual_flag=true` で 1 件、J01 借 1403 26,000.00 / 贷 2202 26,000.00（[03](03-ap-payment.md) BR-01、TST-F-FIN-012-01）。値は INV／PUR の `PURCHASE_RECEIPT` と同一（[05-inventory 02 §2.6.1a](../05-inventory/02-inbound-outbound.md)）。
- G：同一 E14 を 2 回受信。T：AP 1 件のみ（BR-20、TST-F-FIN-012-02）。
- W：E17 で三单一致。T：J02 冲回 + J03 確認（BR-02/BR-07、TST-F-FIN-013-01）。进项税（VAT13-IN）2221.01 借方 3,412.50（TST-F-FIN-013-05）。
- G：价差 260.00（容差 ±1%／±10.00 元の大きい方以内）。T：自動通過（BR-04、TST-F-FIN-013-02）。价差 400.00・理由なし。T：`MSG-FIN-043`（TST-F-FIN-013-03）。

## AC-FIN-08 AR 計上と核销

- G：E10 受信。T：1122 借方 116,141.40、状態 40（[04](04-ar-receipt.md) BR-01、TST-F-FIN-019-01）。同一 E10 2 回で AR 1 件（BR-20、TST-F-FIN-019-02）。
- W：部分核销 60,000.00。T：balance = 116,141.40 − 60,000.00 = 56,141.40、状態 35（BR-09、TST-F-FIN-021-01）。核销>未収。T：`MSG-FIN-065`（TST-F-FIN-021-02）。反核销で残高復元・状態 40（BR-10、TST-F-FIN-021-03）。

## AC-FIN-09 标准成本（fin_standard_cost）

- W：[90](90-db-design.md) §6.12 を確認。T：`fin_standard_cost` が物料×版本×適用期間で定義され、要素は材料／人工／製造費用／委外の 4 区分、単価列は `NUMERIC(18,6)`、数量・工時は `NUMERIC(18,4)`（[01 第 6 章](../00-common/01-common-item-definitions.md)）。`total_unit_cost` = 4 要素合計（CHECK）。
- G：YE3-100L1-4 の発行済み版。T：`total_unit_cost=778.20`（材料 659.95 + 人工 53.75 + 製造費用 64.50 + 委外 0）、標準原価 = 778.20 × 120 = 93,384.00（[06](06-auto-voucher-costing.md) CALC-A7、[bom-demo §6](../90-data/bom-demo.md)）。
- W：当月開始（`period_from` ≤ 当月）の版で `fin_publish_standard_cost` を実行。T：`mdm_material.standard_cost` が発行版の値になる。
- G：当月 2026-10 OPEN、有効版 A（778.20）。W：版 B（`period_from=2026-11`、800.00）を発行。T：`mdm_material.standard_cost` は 778.20 のまま。W：2026-11 を開帳（BAT-FIN-001）。T：`mdm_material.standard_cost`=800.00。
- T：`erp_app` による `mdm_material.standard_cost` の直接 UPDATE は権限エラー（[02-mdm 95](../02-mdm/95-acceptance-criteria.md)）。

## AC-FIN-09a 标准成本なし → 差異分析スキップ

- G：対象製品に発行済み（`status=40`）の `fin_standard_cost` 版が存在しない（工单の `standard_cost` スナップショットも未設定）。W：成本計算（F-FIN-031／034）。T：`MSG-FIN-117`「未设定标准成本，本期不进行成本差异分析。」（W：警告）を返し、実際原価の計算・J16 は通常どおり完了する。
- T：当該成本対象について `fin_cost_variance` は 0 行（差異分析は「標準原価が設定されている場合」のみ、[06](06-auto-voucher-costing.md) PRC 手順 6）。`fin_product_cost.standard_cost_id` / `standard_unit_cost` は NULL。
- 対比：同じ製品に 778.20 の発行版がある場合は AC-FIN-11 の差異 −6.45 が記録される。

## AC-FIN-09b 標準原価の登録・発行権限（SCR-FIN-062）

- G：成本会計（`finance:standard-cost:register`）。W：`POST /api/finance/standard-costs`（YE3、2026A、2026-01、要素 659.95/53.75/64.50/0）。T：201、`status=10`、`totalUnitCost=778.200000`。
- G：成本会計。W：`POST /api/finance/standard-costs/{id}/publish`。T：403、状態は 10 のまま（`finance:cost:*` に publish は含まれない）。
- G：財務総監（`finance:standard-cost:publish`）。W：同 publish。T：`status=40`、`published_by`＝財務総監、`mdm_material.standard_cost=778.20`。財務総監は register 権限を持たず、`POST/PUT` は 403。
- G：`status=40` の版。W：`PUT`。T：`MSG-FIN-135`（70135）。同一物料で版本「2026A」を再登録。T：`MSG-FIN-136`（70136）。

## AC-FIN-09c 発行時の自動打切りと期間重複禁止

- G：版 A（2026-01〜無期限、`status=40`）。W：版 B（`period_from=2026-03`）を発行。T：A の `period_to=2026-02`（DB は 2026-02-01）、B は 2026-03〜無期限で `status=40`。
- G：上記 A・B。W：版 C（`period_from=2026-02`）を発行。T：`MSG-FIN-134`（70134）で拒否（有効版 B の開始 2026-03 以前）。C は `status=10` のまま。
- G：発行関数を経由せず A（2026-01〜無期限）と重なる発行済み行を INSERT。T：`ex_fin_standard_cost_period`（EXCLUDE gist、`btree_gist`）違反で拒否。`period_from` が月初以外（例 2026-05-15）は `ck_fin_standard_cost_period` 違反。
- G：2026-09 が CLOSED。W：`period_from=2026-09` の版を発行。T：`MSG-FIN-134`。
- G：物料 X に発行済み版なし、草稿 D1・D2（ともに `period_from=2026-01`）。W：D1・D2 を 2 セッションから同時に発行。T：`mdm_material` 行ロックで直列化され、一方のみ `status=40`、他方は `MSG-FIN-134`（70134、422）で拒否され `status=10` のまま。500 は返らない（`23P01` 発生時も 70134 に変換）。
- G：版 A（2026-01〜無期限、`status=40`）、草稿 B（2026-03）・C（2026-05）。W：B・C を同時に発行。T：直列化され、先行版が A を打切り、後続版は先行版を有効版として判定（C が後なら B の `period_to=2026-04`、B が後なら `period_from` ≤ C の開始のため 70134）。EXCLUDE 違反の 500 は発生しない。

## AC-FIN-10 成本核算方法（BC-01/02）

- G：`mdm_material.cost_method=1`（MTS）。W：成本計算。T：`fin_cost_collection.cost_method=1`、`cost_object_type=1`、`cost_object_id=material_id`（品种法）。実際 93,377.55 ÷ 120 = 単位 778.146250（表示 778.15）（BC-08、TST-F-FIN-031-01）。
- G：`cost_method=2`（MTO）。T：`cost_method=2`、`cost_object_type=2`、`cost_object_id=work_order_id`（分批法）。完工成本 107,400.00 = 材料 54,000.00 + 人工 29,400.00 + 製造費用 24,000.00、単位 3,580.00（TST-F-FIN-031-02）。`(cost_method, cost_object_type)` の不整合は `ck_fin_cost_collection_object` で拒否。
- T：原価要素（材料・人工・製造費用・委外）と精度（金額 18,2）は `prd_work_order.actual_material_cost` / `actual_labor_cost` / `actual_overhead_cost` / `actual_total_cost` と一致する（BC-15、[06-production 90](../06-production/90-db-design.md)）。
- G：在庫月結（E20）未了。W：成本計算。T：`MSG-FIN-116`（BC-12、TST-F-FIN-031-03）。

## AC-FIN-11 製造費用分配・完工・差異

- W：製造費用分配。T：分配率 40 元/h で 20,800.00 配賦、配賦後 5101=0、端数は最終工单に寄る（BC-05、TST-F-FIN-032-01/02）。
- W：完工入库 J16。T：借 1405 / 贷 5001、単位成本一致（BC-08、TST-F-FIN-033-01）。`fin_product_cost.completion_source_type` は INV 完工入庫の `PRODUCTION_COMPLETION`（委外は `OUTSOURCING_ORDER`）。
- G：5001 残高 ≠ WIP 合計。T：`MSG-FIN-113`（BC-09、TST-F-FIN-033-02）。
- W：差異分析（YE3、120 PCE）。T：標準 93,384.00（778.20 × 120）／実際 93,377.55、総差異 −6.45（有利）。内訳：材料価格差異 79,187.55 − 79,194.00（659.95 × 120）= −6.45、材料数量差異 0.00、人工賃率差異 (25.00 − 25.00) × 258.0 h = 0.00、人工効率差異 (258.0 − 258.0) × 25.00 = 0.00、製造費用差異 7,740.00 − 258.0 h × 30.00 = 0.00（BC-10、CALC-A7/A8/A9、[06](06-auto-voucher-costing.md) §差異表、TST-F-FIN-034-01）。`fin_cost_variance.standard_cost_id` に比較元の版が記録される。

## AC-FIN-12 月結・报表

- G：15 項目 OK。W：月結。T：期間 CLOSED、翌期 OPEN、E30 発行（TST-F-FIN-035-01）。未記帳あり。T：`MSG-FIN-120`（TST-F-FIN-035-02）。
- W：BS 生成。T：資産＝負債＋権益（差 0.00）（TST-F-FIN-038-01）。SCE 期末＝BS 行 69（TST-F-FIN-038-07）。

---

## 未決

全 4 件 **決定済（2026-10-21 蓝色大肥鱼）**。

| # | 事項 | 決定内容 | 決定者 |
|---|---|---|---|
| 1 | 標準原価の版発行（10→40）の承認主体 | **決定済（2026-10-21 蓝色大肥鱼）**：成本会計が卷算・登録、財務総監が発行（`fin_publish_standard_cost` の実行権限を財務総監ロールに限定） | 蓝色大肥鱼 |
| 2 | `prd_work_order.standard_cost` の既定値 | **決定済（2026-10-21 蓝色大肥鱼）**：06-production で `DEFAULT 0` を削除し NULL 許容、下达時に `fin_standard_cost` 発行版をスナップショット。発行版なしは NULL のまま `MSG-FIN-117` で差異分析スキップ（AC-FIN-09a）。06-production DDL・バックエンドは本決定に追従する | 蓝色大肥鱼 |
| 3 | 期中改版時の差異比較元 | **決定済（2026-10-21 蓝色大肥鱼）**：分批法（MTO）は下达時スナップショット、品种法（MTS）は計算期間の発行済み版。`fin_cost_variance.standard_cost_id` に記録 | 蓝色大肥鱼 |
| 4 | 委外加工費暂估の `fin_payable.source_type` | **決定済（2026-10-21 蓝色大肥鱼）**：INV と同じ `OUTSOURCING_ORDER`、`uk_fin_payable_source` で冪等 | 蓝色大肥鱼 |

---

## 改訂履歴

| 版数 | 日付 | 変更内容 | 変更者 |
|---|---|---|---|
| v1.0 | 2026-10-21 | 初版：AC-FIN-01〜12、09a、未決 4 件（決定済） | 业务分析 |
| v1.1 | 2026-10-21 | AC-FIN-09b（登録・発行権限）、AC-FIN-09c（自動打切り・EXCLUDE・MSG-FIN-134）追加 | 业务分析 |
| v1.2 | 2026-10-21 | AC-FIN-09c に同時発行 2 件（初回発行・既存版あり）追加 | 业务分析 |
| v1.3 | 2026-10-21 | AC-FIN-09 に将来月版の開帳時反映を追加 | 业务分析 |
