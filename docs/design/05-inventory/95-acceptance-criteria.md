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

## 改訂履歴

| 版数 | 日付 | 変更内容 | 変更者 |
|---|---|---|---|
| v1.1 | 2026-10-21 | AC の「親 ID 先頭の例外を除く」を削除（蓝色大肥鱼 2026-10-21 決定） | 业务分析 |
| v1.2 | 2026-10-21 | G2-20：非一意 btree `idx_` も `tenant_id` 先頭（次に `company_id`）、GIN 除外に修正（蓝色大肥鱼 2026-10-21 決定） | 业务分析 |
