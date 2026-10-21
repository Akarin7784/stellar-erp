# 库存域 验收标准（第一版全量・入庫検査・多租户）

| 項目 | 内容 |
|---|---|
| 文書名 | 库存域 验收标准 |
| 版数 | v1.0 |
| 作成日 | 2026-10-21 |
| 作成者 | 业务分析 |
| 状態 | ドラフト（ローカル準備・未 push） |
| 関連文書 | [90-db-design.md](90-db-design.md) / [02-inbound-outbound.md](02-inbound-outbound.md) / [00-overview.md](00-overview.md) / [02-mdm 90](../02-mdm/90-db-design.md) |
| 関連Issue | Refs #9、#10、#31、#43 |

---

形式：G（Given）/ W（When）/ T（Then）。

## AC-INV-01 分期表記なし

- W：`docs/design/05-inventory` で `Phase` / `フェーズ` / `分期` を grep。T：0 件（本 AC の検査文言を除く）。

## AC-INV-02 tenant_id / company_id

- W：`05-inventory/90-db-design.md` を確認。T：禁止写死的默认租户（`tenant_id` 使用 `DEFAULT current_setting('app.tenant_id')::bigint`、字面量默认租户なし）。`company_id` は NOT NULL かつ DEFAULT 1 なし。

## AC-INV-03 一意索引は tenant_id 先頭

- W：業務一意索引（`uk_`、明細・自己参照・イベント ID を含む）を確認。T：すべて `(tenant_id, company_id, …)` で始まる。親 ID 先頭の例外は存在しない（00-common §6.1 第 4 条のみ、本域は該当なし）。G2-20：非一意 btree `idx_` も `tenant_id` 先頭（次に `company_id`）、GIN は対象外。`uk_` を company_id 先頭にしない（蓝色大肥鱼 2026-10-21 決定）。

## AC-INV-04 inspection_flag 導出とスナップショット（入庫点收窄）

- W：`mdm_material` 列一覧。T：`inspection_required` 列は存在しない。`inspection_stage` ∈ {0,10,20,30,40}。
- G：`inspection_stage=10`（IQC）。W：PI／OSR 過账。T：明細 `inspection_flag=true`、`stock_status=10`。
- G：`inspection_stage=40`（全工程）。W：PI 過账。T：`inspection_flag=true`、`stock_status=10`。W：FGI 過账。T：同様 true→10。
- G：`inspection_stage=20`（純 IPQC）。W：PI または FGI 過账。T：`inspection_flag=false`、`stock_status=20`（入庫待検に乗らない）。
- G：`inspection_stage=30`（FQC）。W：PI 過账。T：false→20。W：FGI 過账。T：true→10。
- G：`inspection_stage=0`（免检）。W：PI 過账。T：`inspection_flag=false`、`stock_status=20`。
- G：入庫済行の `inspection_flag=true`。W：その後マスタの `inspection_stage` を 0 に変更。T：当該明細の `inspection_flag` は true のまま（スナップショット不変）。

## AC-INV-05 ON→10 / OFF→20（:360 と :157 整合）

- W：SCR-INV-004 `inspectionFlag` 備考および §2.6.1 / §2.6.1a。T：**ON（true）→ `stock_status=10` 待检**；**OFF（false）→ `20` 可用**。旧「ON で状態 20」表記なし。

## AC-INV-06 入庫検査種別・来源・合格後 10→20

- W：`inspection_type` 码表。T：`10` IQC / `20` IPQC / `30` FQC / `40` OQC。入庫起票は PI／OSR→10、FGI→30 のみ。
- W：過账 `source_type`。T：PI=`PURCHASE_RECEIPT`、OSR=`OUTSOURCING_ORDER`、FGI=`PRODUCTION_COMPLETION`；状態変換=`INSPECTION`。INV に「入庫検査单」伝票種別なし。
- G：PI／OSR で `inspection_flag=true`。W：IQC 合格（E15 resultCode 20）または特採（30）。T：`ST_OUT(10)`+`ST_IN(20)` で残高が待检→可用。
- G：FGI で `inspection_flag=true`。W：FQC 合格（E15）。T：同様に `10→20`。
- G：FGI で `inspection_flag=true`、E24 `stockStatus=20`。W：過账。T：`MSG-INV-065` で拒否。

## AC-INV-07 冗余 txn_type とトリガー／CHECK

- W：`inv_stock_txn_line` DDL。T：`txn_type VARCHAR(16) NOT NULL` あり。書込時トリガーで表頭 `txn_type` と一致（04 §8.1）。
- W：同一 DDL。T：`ck_inv_stock_txn_line_insp_inbound`：`direction=1` かつ `inspection_flag=true` なら `stock_status=10`。
- W：`direction`。T：`txn_type` から一意決定、CHECK `direction IN (1,-1)`。
- G：入庫行で `inspection_flag=false`。W：過账。T：`stock_status=20`（CHECK は true→10 のみ強制。false→20 は過账サービスで保証し、本 AC のテストで検証）。

## AC-INV-08 状態変換対と可用量

- G：待检残高 100。W：合格変換 100。T：待检 0・可用 +100、現存量不変。`pair_key` で ST_OUT/ST_IN が対。

## AC-INV-09 RLS・複合 FK（迁移）

- W：`inv/` 迁移適用後に `pg_class.relrowsecurity/relforcerowsecurity` を確認。T：90 §2 の 24 表すべて true、ポリシー `tenant_isolation` が `USING`/`WITH CHECK` の両方を持つ（`inv_stock_txn` は親表）。
- G：`app.tenant_id=1` の接続。W：tenant 2 の `inv_stock_balance` を SELECT。T：0 件。W：`tenant_id=2` で INSERT。T：RLS 違反で失敗。
- W：`pg_constraint` の `inv_*` 外部キー。T：同域親子 6 本は `(tenant_id, company_id, x_id)` → 親 `(tenant_id, company_id, id)`（制約名は 90 §6.3 どおり）、被参照の 6 表に `uk_<table>_tenant_company_id UNIQUE (tenant_id, company_id, id)`。mdm 向け跨域 FK は `(tenant_id, x_id)` → `(tenant_id, id)`。単列 FK 0 件。`inv_*` に `uk_<table>_tenant_id` は 0 件（跨域被参照なし）。
- W：`scripts/check-tenant-default.sh`。T：合格（`tenant_id` 既定値は `current_setting('app.tenant_id')::bigint` のみ）。

## AC-INV-10 迁移番号

- W：`.github/scripts/check-migrations.sh`（`MIGRATION_BASE_REF`=PR の base）。T：`inv/V{yyyyMMdd}{NNNN}__inv_*.sql` の版数が base 上の最大版（本書時点 `V202610210708`）より大きく、ファイル名の `inv` がディレクトリと一致。

## AC-INV-11 パーティションと全期間一意

- W：`inv_stock_txn` を確認。T：`PARTITION BY RANGE (txn_date)`、PK `(id, txn_date)`、2026-01〜2027-12 と DEFAULT パーティションが存在。どの表も `inv_stock_txn` を FK 参照しない。
- G：2026-10 に `txn_no=GRI2610200001` が存在。W：2026-11 の日付で同じ `txn_no` を登録。T：`uk_inv_stock_txn_key`（`TXN_NO`）違反で拒否。
- G：PI（`PURCHASE_RECEIPT`, receiptId=1）過账済。W：同じ E14 を再受信。T：`SOURCE_POSTED` 違反で二重計上なし（冪等スキップ）。W：沖销後に再過账。T：成功（元の `SOURCE_POSTED` は沖销 TX で削除）。
- G：調撥 1 件で TR_IN を 2 回（部分受入）。W：2 回目過账。T：成功（`TRANSFER` は `SOURCE_POSTED` 対象外）。
- G：同一工单に E22 が 2 回（issueId=11, 12）。W：2 回目の MII 過账。T：成功（`source_id=issueId`）、両事務の `work_order_id` は同一。

## AC-INV-12 明細の整合トリガー

- W：表頭と異なる `txn_type` の明細を INSERT。T：トリガーで拒否。W：表頭のない `txn_id`。T：拒否。
- W：PI（非沖销）の明細を `direction=-1` で INSERT。T：拒否。W：PI の沖销事務（`is_reversal=true`）の明細を `direction=-1`。T：成功。

## AC-INV-13 計価方法（08 §6 / BC-01）

- G：MTS 自制品（`valuation_method=20`）、`fin_standard_cost` 有効版 `total_unit_cost=778.200000`、E24 実際単価 771.75、数量 1。W：FGI 過账。T：明細 `unit_cost=std_unit_cost=778.200000`、`amount=778.20`、`variance_amount=-6.45`、残高 `avg_unit_cost=778.200000`。
- G：同物料で有効な標準原価版なし。W：FGI 過账。T：拒否（標準原価未発行）。
- G：MTO 产品（`valuation_method=10`、`cost_method=2`）。W：FGI 過账。T：E24 の実際単価で移動平均、`variance_amount=0`、`work_order_id`・`sales_order_line_id` が設定される。
- G：外购料（10）。W：PI 過账。T：移動平均（05 §2）。

## AC-INV-14 区分値 CHECK

- W：`reason_type` なしの AOI／AOO／SC_OUT、または `reason_type` ありの PI を INSERT。T：`ck_inv_stock_txn_reason` で拒否。
- W：90 §2.6 に無い `source_type`（例 `NCR`）。T：`ck_inv_stock_txn_source` で拒否。
- W：`inv_period.period_status=20` だが `fin_period.status='CLOSED'` の期間へ過账。T：拒否。

## AC-INV-15 一意・索引規則（自動検査）

- W：pgTAP `composite_fk.sql` と `RlsCoverageTest`。T：`inv_*` の全 `uk_` が `(tenant_id, company_id, …)` 先頭（`uk_<table>_tenant_company_id` を除く）、全 btree `idx_` が `(tenant_id, company_id, …)` 先頭。

## 改訂履歴

| 版数 | 日付 | 変更内容 | 変更者 |
|---|---|---|---|
| v1.1 | 2026-10-21 | AC の「親 ID 先頭の例外を除く」を削除（蓝色大肥鱼 2026-10-21 決定） | 业务分析 |
| v1.2 | 2026-10-21 | G2-20：非一意 btree `idx_` も `tenant_id` 先頭（次に `company_id`）、GIN 除外に修正（蓝色大肥鱼 2026-10-21 決定） | 业务分析 |
| v1.3 | 2026-10-21 | 05 迁移の受入基準を追加：AC-INV-09 RLS・複合 FK、10 迁移番号、11 パーティション・全期間一意、12 明細トリガー、13 計価方法（08 §6/BC-01）、14 区分値 CHECK・期間、15 一意/索引の自動検査 | 业务分析 |
| v1.4 | 2026-10-21 | AC-INV-09/15：同域親子 FK を `(tenant_id, company_id, x_id)`・被参照キー `uk_<table>_tenant_company_id` に変更（PR #43） | 业务分析 |
