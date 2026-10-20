# 采购域 验收标准（第一版全量・多租户・收货 IQC・三单匹配）

| 項目 | 内容 |
|---|---|
| 文書名 | 采购域 验收标准 |
| 版数 | v1.0 |
| 作成日 | 2026-10-21 |
| 作成者 | 业务分析 |
| 状態 | ドラフト（レビュー待ち） |
| 関連文書 | [00-overview.md](00-overview.md) / [04-receipt-iqc.md](04-receipt-iqc.md) / [06-purchase-invoice-ap.md](06-purchase-invoice-ap.md) / [90-db-design.md](90-db-design.md) / [05-inventory 02 §2.6.1a](../05-inventory/02-inbound-outbound.md) / [05-inventory 95](../05-inventory/95-acceptance-criteria.md) / [00-common 09](../00-common/09-cross-domain-flow.md) / [00-common 10](../00-common/10-rls-and-db-roles.md) |

---

形式：G（Given）/ W（When）/ T（Then）。本書は既存設計の規則を検証可能な形に書き直したものであり、新しい業務規則は追加しない。未確定事項は末尾「未決」に記す。

## AC-PUR-01 分期表記なし（第一版全量）

- W：`docs/design/04-purchase` を `Phase` / `フェーズ` / `分期` で grep。T：0 件（本 AC の検査文言を除く）。
- W：優先度の記述を確認。T：「P0/P1/P2 は全て第一版、実装順のみ」と矛盾する記述（「次期」「将来版で対応」等）がない（[00-overview](00-overview.md) §1）。

## AC-PUR-02 tenant_id / company_id

- W：[90-db-design.md](90-db-design.md) の全 DDL を確認。T：`tenant_id` は `NOT NULL DEFAULT current_setting('app.tenant_id')::bigint`、字面量默认租户（`DEFAULT 0` 等）なし。`scripts/check-tenant-default.sh` が OK。
- T：`company_id` を持つテーブル（ヘッダ・設定・集計）では `NOT NULL` かつ既定値なし（`DEFAULT 1` なし）。明細・関連テーブルは `company_id` を持たず親行で保証する（90 §3 監査カラム）。

## AC-PUR-03 一意索引は tenant_id 先頭

- W：業務一意索引（`uk_`）を DDL 本文・§4 テーブル一覧・§6 索引一覧・§7 制約一覧で確認。T：`(tenant_id, company_id, …)` で始まり、4 箇所の列順が一致する（`uk_pur_*_no`、`uk_pur_invoice_number`、`uk_pur_statement_period`、`uk_pur_tolerance_rule`、`uk_pur_supplier_performance`）。
- T：親 ID 先頭の一意索引は 90 §6.1 の例外一覧に全て列挙され、理由（親行が tenant/company を保証）が書かれている。一覧外の非 tenant 先頭 `uk_` は 0 件。
- T（G2-20）：`company_id` 先頭は非一意 `idx_` のみ（例：`idx_pur_tolerance_rule_lookup`）。

## AC-PUR-04 RLS

- G：テナント A のセッション（`app.tenant_id=A`）。W：`pur_*` を SELECT。T：テナント B の行は返らない（[00-common 10](../00-common/10-rls-and-db-roles.md) の RLS 方針に従う）。

## AC-PUR-05 入荷確定と E14

- G：`receipt_status=25` の收货单。W：`POST /api/purchase/receipts/{id}/confirm`。T：`receipt_status=30`、`confirmed_at` 記録、E14 `purchase.receipt.posted` が同一トランザクションで Outbox に登録される（[04](04-receipt-iqc.md) BR-08、§6）。
- T：E14 購読者は INV（待検在庫）・PRD（IQC 起票）・FIN（暂估 J01）（[04](04-receipt-iqc.md) BR-08、[06](06-purchase-invoice-ap.md) BR-21）。

## AC-PUR-06 E14 冪等性

- G：E14 が Outbox 再送で 2 回配信。W：PUR・INV が処理。T：PO 明細累計（`received_qty` 等）が二重加算されない（[04](04-receipt-iqc.md) §6.4、TST-F-PUR-012-02）。
- T：INV は `source_type='PURCHASE_RECEIPT'` + `source_id=receiptId` + `txn_type='PI'` の過账済を検知してスキップし、`PI` は 1 件のみ（[05-inventory 02](../05-inventory/02-inbound-outbound.md) §2.6.1）。
- T：E15・E18・E35 の受信も `eventId` で重複排除される。

## AC-PUR-07 inspection_flag と IQC

- W：`mdm_material` 列一覧。T：`inspection_required` 列は存在せず、`inspection_stage` ∈ {0,10,20,30,40}。PUR 文書にも `inspection_required` の記述がない。
- G：`inspection_stage=10` または `40`。W：入荷確定。T：明細 `inspection_flag=true`、`inspection_status=1` 待检、INV は `PI` を `stock_status=10` 待检で計上、PRD は IQC（`inspection_type=10`）を起票。
- G：`inspection_stage ∈ {0,20,30}`。W：入荷確定。T：`inspection_flag=false`、`inspection_status=0` 検査不要、INV は `20` 可用で直入、IQC は起票されない。
- G：入荷確定済明細 `inspection_flag=true`。W：マスタの `inspection_stage` を 0 に変更。T：当該明細の `inspection_flag` は true のまま（スナップショット）。
- G：IQC 判定 E15。W：`resultCode` 20 合格 / 30 特采。T：`inspection_status` 3 / 4、INV で `10→20`。W：不合格（40/50）。T：`inspection_status=5`、INV で `10→40`、返品・選別・廃棄の対象（[04](04-receipt-iqc.md) BR-09/BR-18）。
- T：在庫側伝票は INV が採番（GRI）、IQC は PRD、收货单は PUR（GR）。INV は入庫検査单を別建てしない。

## AC-PUR-08 收货取消（E35）

- G：IQC 未完了かつ三単マッチ未実行。W：取消。T：`receipt_status=90`、E35 発行（INV 待検在庫取消・FIN 暂估冲回・PRD IQC 取消）。
- G：可用化済または匹配済。W：取消。T：`MSG-PUR-075` で拒否、返品（E16）で処理（[04](04-receipt-iqc.md) BR-12）。

## AC-PUR-09 超收容差

- G：PO 明細数量 100、`receiving_tolerance_rate=0.05`（比率、5%）、既入荷 0。W：入荷 105 を登録。T：上限 `100×(1+0.05)=105` 以内のため `MSG-PUR-069` 警告で受入可。
- 同 G。W：入荷 106 を登録。T：上限超過で受入拒否（例外承認 `MSG-PUR-068`）。
- 判定順は PO 明細 > PUR 上書き規則 > MDM 既定（[04](04-receipt-iqc.md) BR-02/BR-03）。

## AC-PUR-10 三单匹配（基本）

- T：匹配粒度は「发票明细 × 收货明细」、`pur_invoice_match` で `(invoice_line_id, receipt_line_id)` 重複不可（[06](06-purchase-invoice-ap.md) BR-10、90 §7 #11）。
- G：可请求数量 `accepted_qty + concession_qty − returned_qty − 已请求数量` = 588、发票数量 600。W：匹配。T：匹配数量 588、数量差异 12 は HOLD、应付不确认（CALC-01～03、BR-11）。
- G：差异が全て容差内。T：自动通过・差异記録。G：超容差。T：差异理由（BR-15 コード）＋財務经理承認が必要（BR-13/BR-14）。容差既定値は BR-13 の記載どおり。
- G：容差内かつ `pur.match.auto.post=true`。W：匹配確定。T：E17 発行（BR-17）。否则「待计上」。
- G：红字发票（`invoice_type=50`）。T：原发票必須、負数匹配で冲减（BR-05/BR-19）。
- G：同一 `(supplier_id, invoice_code, invoice_number)` が既存。W：登録。T：拒否（BR-08、`uk_pur_invoice_number`）。

## AC-PUR-11 暂估と月结

- T：E14 で FIN が J01 暂估、E17 で J02 冲回 → J03 确认（[06](06-purchase-invoice-ap.md) BR-21/BR-22）。月结時に未匹配 GR は暂估のまま（BR-23）。

---

## 未決

| # | 事項 | 現状 | 推奨 | 決定者 |
|---|---|---|---|---|
| 1 | E14 に `inspectionFlag` を載せるか | **決定済（蓝色大肥鱼 2026-10-21）**：E14 明細ごとに後方互換追加 | — | 蓝色大肥鱼 |
| 2 | PRD IQC 起票の `sourceType` | **決定済（同上）**：`PURCHASE_RECEIPT` に統一 | — | 蓝色大肥鱼 |
| 3 | `pur_receipt.inspection_flag`（ヘッダ）の要否 | **決定済（同上）**：ヘッダ列を削除、明細のみ。一覧表示は `bool_or(line.inspection_flag)` で導出 | — | 蓝色大肥鱼 |
