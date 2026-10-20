# 红队评审报告：03-sales / 04-purchase（第 1 轮）

| 項目 | 内容 |
|---|---|
| 文書名 | 红队评审报告（03-sales / 04-purchase） |
| 文書番号 | DSN-REV-005 |
| 版数 | v1.0 |
| 作成日 | 2026-10-20 |
| レビュアー | mdm-designer（担当：02-mdm） |
| 対象域 | 03-sales（13 ファイル）/ 04-purchase（13 ファイル） |
| 状態 | 第 1 轮 指摘のみ（設計変更・修正は行っていない） |
| 関連文書 | [评审宪章](README.md) / [09 跨域流程](../00-common/09-cross-domain-flow.md) / [02-mdm API 設計](../02-mdm/91-api-design.md) / [02-mdm データ設計](../02-mdm/90-db-design.md) |

> **独立性**：レビュアーは 02-mdm の筆者であり、対象域（03-sales / 04-purchase）の筆者ではない。MDM 側の契約は「参照規約」としてのみ使用し、本報告で MDM 自身の妥当性は評価対象にしていない。

---

## 1. レビュー範囲・方法

- **対象**：`docs/design/03-sales/`（13 ファイル）と `docs/design/04-purchase/`（13 ファイル）＝**26/26 ファイル抽査**（うち約 15 ファイルは主要章を精読、全 26 ファイルは grep でイベント名・項目名・数値を横断確認）。
- **方法**：
  1. 09 §3 のイベント契約（E05〜E17、E35）と 09 §4.2/§4.3 の P2P/O2C 步骤を基準に、SAL/PUR が発行・購読する payload を**項目名・型・金額口径**まで逐字比較。
  2. 02-mdm 91 API / 01・06 項目定義 / 90-db を基準に、SAL/PUR が参照する MDM 項目・API の実在性を確認。
  3. 追跡シナリオ①：YE3 受注 `SO2610200001`（120+60 PCE、折扣 2%、分納 80+100、返品 20、開票）を 03-sales の全工程で追跡。
  4. 追跡シナリオ②：鋼材 PO `PO2610200001`（4 明細、超収容差、三単マッチ、差異、返品、取消、対账）を 04-purchase の全工程で追跡。
  5. 金額・税額・与信・帳齡・粗利のサンプル値を再計算し、設計式（CALC-*）との一致を確認。
- **攻撃次元**：A（業務漏れ）/B（跨域契約）/C（データ真正性）/D（実装可能性）/E（法令・税務）/F（文書品質）/G（権限）/H（数値整合）を全次元適用。本報告の指摘は主に **B・D・H**。

---

## 2. 指摘一覧

| 指摘 ID | 重大度 | 対象ファイル:行 | 指摘内容 | 証拠・根拠 | 修正提案 | 想定影響 |
|---|---|---|---|---|---|---|
| REV-mdm-001 | **S2** | `03-sales/02-sales-order.md:732` | E06 `sales.order.approved` の明細項目が 09 契約の `qty` ではなく **`quantity`** で送出され、項目名が一致しない（09 は `lines[{materialId, qty, uom, deliveryDate, warehouseId}]`） | 09:80（契約）／02-sales-order.md:727-740（payload `"quantity": "120.0000"`） | E06 の明細を `qty` に改名（互換のため `quantity` 併記は 09 追補後）。実装側で 09 名→内部名の変換表を 91 と同様に明記 | INV が 09 契約通りに実装すると受注数量を取得できず引当不能。O2C 中核イベントの致命的不整合 |
| REV-mdm-002 | **S2** | `03-sales/02-sales-order.md:694,722` | 同一受注で E05 の `amount`＝**199,856.77（税込）**、E06 の `amount`＝**176,864.40（税抜）** と口径が異なる。09 は両イベントとも `amount` とだけ定義し「税込/税抜」を規定していない | 09:79-80／02-sales-order.md:694（E05 amount 199856.77）、722（E06 amount 176864.40）、724（totalAmount 199856.77）／94:196（与信コミット 199,856.77） | 09 に `amount` の口径（税抜）と `totalAmount`/`taxAmount` を明記、またはイベントごとに `amountTaxType` を追加。E05 も税抜に統一 | WF 金額判定・FIN 与信コミット・SAL 与信占用の金額基礎が三者三様になり、与信・承認閾値が狂う |
| REV-mdm-003 | **S2** | `03-sales/06-credit-pricing.md:51,54,385,396,689` | 与信判定結果コード `credit_check_result` の意味が文書内で自己矛盾。BR-CR-06 は **40＝阻斷**、BR-CR-09/PRC/未決 #2 は **40＝超限承認済**。また更新値は 10/20/40 のみで 30（超限承認待ち）が欠落 | 06-credit-pricing.md:51（10 OK/20 警告/30 超限/40 阻斷）、54（承認済フラグ＝40）、385（更新 10/20/40）、396（最終承認済 credit_check_result=40）、689（同） | コード体系を再定義（例：10 OK／20 警告／30 超限承認待ち／40 阻斷／50 超限承認済）。BR-CR-06・BR-CR-09・PRC・未決を一括改訂 | 出荷可否・超限承認判定が実装不能。誤実装時は「阻斷」と「承認済」を取り違え、与信統制が無効化 |
| REV-mdm-004 | **S2** | `03-sales/06-credit-pricing.md:401,405` | MDM 销售取价 API の戻り項目が契約不一致。SAL は `unitPrice`・`isTaxIncluded`・`discountRate` を取得前提だが、MDM 91 §3.3 は `unitPriceNet`/`unitPriceGross`・`discount{discountRate,discountAmount}` で **`isTaxIncluded` 自体が存在しない**。また取价不能を **404** 前提とするが MDM は **422/20036** | 06-credit-pricing.md:401（取得項目列挙）、405（404 前提）／02-mdm/91-api-design.md:247-254（response 項目）、130（errorCode 20036） | MDM response に `isTaxIncluded`（または `priceTaxType`）を追加し、`unitPrice`/`discountRate` の別名を提供するか SAL 側を MDM 形式へ変更。404→422 の分岐を SAL に明記 | 受注・見積の取価が「常に 404 取价不能」または項目未取得で手動単価に落ち、価格統制・与信・粗利が機能しない。报价/受注両方に波及 |
| REV-mdm-005 | **S2** | `03-sales/06-credit-pricing.md:403`／`03-sales/02-sales-order.md:58` | 標準価格・標準原価を MDM から取得する前提だが、MDM 物料詳細 API のレスポンスに `standardPrice`/`standardCost` が含まれない（DB には列あり） | 06-credit-pricing.md:403（標準価 MDM `standard_price` 取得）、02-sales-order.md:58（標準価比 ±5% 承認）、07-tracking-reports.md:72（原価 61,600 使用）／02-mdm/91-api-design.md:214,233（material response に該当項目なし）、02-mdm/90-db-design.md:286-287（列は存在） | MDM 物料 API の `finance`/`sales` ビューに `standardCost`/`standardPrice` を追加（項目権限制御付き）。または SAL 側の算出基礎を FIN API へ変更 | 価格承認（標準価比 ±5%）・粗利チェック（CALC-CR-07/TR-08）が実装不能または別契約の暗黙前提に依存 |
| REV-mdm-006 | **S2** | `00-common/09-cross-domain-flow.md:85`／`03-sales/04-sales-return.md:637-641` | E11 `sales.return.confirmed` の 09 契約は `lines[{materialId, qty, inventoryStatus}]` のみで**金額・税額・原価を持たない**が、購読処理は「赤伝売上・売掛（J22/J23）」である。SAL 実装は `unitPrice/taxRate/amount/taxAmount/costAmount` を追加送出しており、09 と不一致（実装が SAL 拡張に暗黙依存） | 09:85／04-sales-return.md:637-641（payload に金額あり）、652（FIN が J22/J23） | 09 E11 に `unitPrice/taxRate/amount/taxAmount`（必要なら `costAmount`）を追加。SAL は既に送出済のため 09 追補のみで整合可 | FIN が 09 契約だけでは赤伝売上・AR 戻しを計上できない。実装が SAL 独自拡張に依存し、仕様書間で齟齬 |
| REV-mdm-007 | **S2** | `00-common/09-cross-domain-flow.md:90,109`／`04-purchase/91-api-design.md:601-612,615` | E16 `purchase.return.confirmed` は `lines[{materialId, qty, warehouseId}]`、E35 `purchase.receipt.cancelled` は `reversedLines[{materialId, batchNo, qty}]` のみで**金額・単価・税額がない**。一方 PUR は返品金額・税額を内部計算し（BR-15/CALC-02/03）、FIN は E16 で「赤伝仕入（買掛または暫估の冲減）・進項税額転出」（J04）、E35 で「仕入暫估の戻し」を行う契約 | 09:90,109／04-purchase/05-return.md:59,69,75-78（金額計算式あり）、91-api-design.md:601-612（E16 payload 金額なし）、91:615（FIN J04） | E16/E35 に `unitPrice/amount/taxAmount`（または FIN が原 GR 明細を保持する前提の明示）を追加。E35 は `reversedLines` に `unitPrice` を追加 | FIN が返品・取消の金額を契約のみから確定できず、買掛/暫估の冲減額が実装者判断に。会計・税務の正確性に直結 |
| REV-mdm-008 | **S2** | `00-common/09-cross-domain-flow.md:84`／`03-sales/03-delivery-picking.md:616` | E10 `sales.delivery.confirmed` の 09 契約に **`serialNos` がなく**、シリアル管理品（YE3 成品は `serial_managed=Y`）の出荷で INV が個体を特定できない。SAL は `serialNos[]` を追加送出しており契約外 | 09:84（lines に batchNo はあるが serialNos なし）／03-delivery-picking.md:609-623（`serialNos` 送出）、94:164（成品はシリアル管理） | 09 E10 lines に `serialNos[]` を追加（E11/E16 も同様に個体・批次項目の契約整備） | INV のシリアル在庫消込・トレーサビリティが実装不能。品質トレース（IATF/顧客要求）に影響 |
| REV-mdm-009 | **S2** | `00-common/09-cross-domain-flow.md:80`／`03-sales/06-credit-pricing.md:360,380-385` | 与信コミットの更新責任が二重。09 E06 は購読者 FIN の処理を「与信コミット」とし、SAL も PRC-SAL-006-02 で `sal_credit_occupation` にコミットを INSERT する。C-7 の使用額式は「FIN AR ＋ SAL 受注コミット − 前受金」であり、FIN 側でも注残コミットを持つと二重計上。さらに SAL コミット額は税込 `grand_total`（06:384）で E06 `amount`（税抜）と基礎が異なる | 09:80／06-credit-pricing.md:360（PRC 一覧）、380-385（INSERT amount=grand_total、更新 10/20/40）／00-overview.md:461（C-7 式）／02-sales-order.md:722（E06 amount 税抜） | 09 で責任を一抹化（例：与信占用の保持は SAL、FIN は AR と前受金のみ／またはその逆）。E06 の購読処理の文言を「与信再判定トリガ」へ修正 | 与信使用額が二重計上され、与信超過の見逃し・過剰ブロックが発生。与信統制（S1 相当の財務リスク） |
| REV-mdm-010 | **S2** | `04-purchase/04-receipt-iqc.md:58,340`／`03-purchase-order.md:258` | 過入荷容差が**二重定義**。MDM は `mdm_material.over_receipt_tolerance_pct`（物料別）を持ち、PUR は `pur_tolerance_rule`＋PO 明細 `receiving_tolerance_rate` で判定し MDM を参照しない。09 §4.3 は「5% または 1 個」とのみ記載し、優先順位・正本を定めない | 02-mdm/01-material-master.md:158,403／02-mdm/90-db-design.md:237（MDM 物料容差）／04-receipt-iqc.md:58（5% デフォルト）、340（`poLine.receivingToleranceRate ?? rule(...) ?? 0.05`）／03-purchase-order.md:258／09:187 | 09/08 に優先順位を明記（PO 明細 > PUR 容差規則 > MDM 物料容差 > 既定 5%）。MDM の物料容差を採用するか廃止するか裁定 | 同じ受入で判定結果が変わる可能性。マスタと業務ルールの二重管理で監査時に説明不能 |
| REV-mdm-011 | **S2** | `03-sales/94-sample-data.md:137,145,147,149,158,186` | サンプル金額が**受注→出荷→請求で不整合**。(a) 受注明細 10 は折扣 2% 後 100,724.40（120×856.50×0.98）、受注合計 176,864.40 だが、出荷 1+2 合計は 178,724.40、請求は 102,780.00（=120×856.50、**折扣未反映**）。(b) 出荷 2 は 40×856.50＋60×1,269.00＝110,400.00 だが記載は 110,204.40（差 195.60） | 94:137（受注合計 176,864.40）、145（明細 100,724.40）、149（計算式）、158（出荷 68,520.00＋110,204.40）、186（請求 102,780.00）／02-sales-order.md:88（CALC-04 折扣後金額）、07-tracking-reports.md:72（毛利が 102,780.00 基準） | 折扣の適用範囲（受注のみ/出荷・請求まで）を CALC で明確化し、受注→引当→出荷→請求→AR の金額が一致するようサンプルを再計算。出荷 2 の金額も再計算 | 売上・AR・与信・粗利・税額がすべて連鎖的に不一致。E10/E12/FIN AR の金額が受注と一致せず、会計・税務の正確性に影響 |
| REV-mdm-012 | **S2** | `03-sales/00-overview.md:317`／`03-sales/05-invoice-receivable.md:73,341` | 帳齡の権威・算出方式が文書内で矛盾。00-overview の BAT-SAL-007 は「AR 投影から帳齢区分・DSO を算出」とするが、05-invoice の BR-ST-06 は「FIN ar-aging が正、SAL は独自口徑を持たない」、92-report の BAT-SAL-007 も「FIN 帳齡の取込」と記載 | 00-overview.md:317／05-invoice-receivable.md:73,341／92-report-batch-design.md:183,271,408 | 00-overview の BAT-SAL-007 を「FIN ar-aging 取込・DSO スナップショット」に統一し、独自計算記述を削除 | 帳齡の二重実装・口径不一致。与信・回収管理・経営 KPI の信頼性低下 |
| REV-mdm-013 | **S3** | `04-purchase/91-api-design.md:645-648` | E13 `purchase.order.approved` のサンプル payload が明細 1 行のみ（28,000×5.65＝158,200）なのに `amount` は 434,400.00（PO 4 明細合計）で、明細合計と金額が一致しない | 91-api-design.md:645-648（lines 1 件、amount 434,400.00）／94-sample-data.md:117-130（4 明細、合計 434,400.00） | サンプルに全 4 明細を記載するか、`amount` を当該 1 行分（158,200.00）に修正 | 購読側が明細合計で金額検証すると不整合。実装時の検収基準が曖昧 |
| REV-mdm-014 | **S3** | `04-purchase/00-overview.md:513` | PUR 未決 #6 は「RFQ 中選価→MDM 価格更新の跨域インタフェース未定、P1 手工待办」とするが、MDM は既に `POST /api/mdm/supplier-quotations/{id}/adopt`（報価採用 API）を定義済みで契約が不整合（既存 API の利用が未決として放置） | 00-overview.md:513／02-mdm/91-api-design.md:140（adopt API #89） | 未決 #6 を「MDM adopt API を利用（中選価→MDM 購買価格）」に更新し、呼出条件・承認要否を明記 | 実装時に未決が不必要に残り、中選価→価格表反映が手作業のまま。手戻り・データ二重管理 |
| REV-mdm-015 | **S3** | `04-purchase/07-tracking-performance.md:249-251`／`04-purchase/00-overview.md:469` | 跨模块の MDM マスタを**テーブル直接参照**する前提の記載（`mdm_purchase_price` を画面データソースに指定）。09 §2.1 は同期参照を「モジュール公開インタフェース（根包の Service）＋内部 REST」と定義し、直接 SELECT はモジュール境界違反。MDM 側には購買価格 API（#84〜86）が存在するが PUR は参照していない | 04-purchase/07-tracking-performance.md:249-251（`mdm_purchase_price` をデータソース）、00-overview.md:469（同期参照）／02-mdm/91-api-design.md:135-137（購買価格 API #84〜86）／09:26,498-506（同期参照規約） | 画面・照会のデータソースを「MDM 公開 API 経由」に統一。例外を認める場合は 09/04 DB 規格に境界例外を明記 | Spring Modulith のモジュール境界違反。将来の MDM 変更が PUR に波及し、デプロイ結合・測試範囲拡大 |
| REV-mdm-016 | **S3** | `00-common/09-cross-domain-flow.md:88`／`02-mdm/01-material-master.md:230` | E14 の購読処理は PRD の「IQC 起票」だが、payload に検査要否・検査段階（`inspection_stage`）が含まれない。PRD が IQC 起票要否を判定するには MDM 照会が必要だが、その連携が契約に明記されていない（免検品の扱いが実装者判断に） | 09:88／02-mdm/01-material-master.md:230（`inspection_stage` 00 免検〜40 全工程）／04-purchase/04-receipt-iqc.md:22（E14 で IQC 起票） | E14 payload に `inspectionStage`（または `inspectionRequired`）を追加するか、「PRD が MDM 物料を同期参照して判定」と 09 に明記 | 免検品に IQC が起票される/必要品が起票されない。検査工数・品質統制の不整合 |
| REV-mdm-017 | **S4** | `03-sales/02-sales-order.md:704-742` | E05/E06 等の SAL/PUR 発行 payload は 09 契約に対する**追加項目**（`customerCode`/`currencyCode`/`taxAmount`/`totalAmount`/`materialCode`/`unitPrice`/`taxRate` 等）を多数含む。09 §2.3 の `eventVersion` 運用（項目追加は +0）に沿うが、09 の契約表に追記されていない | 02-sales-order.md:716-740／09:79-80／04-purchase/91-api-design.md:671（項目追加 +0 の運用） | 09 §3 の該当イベントの payload 表へ追加項目（意味・必須・口径）を追補。追補までは消費側で無視する旨を明記 | 契約の暗黙拡張。消費側が項目を無視して実装し、後続の機能追加時に「使えると思った項目がない」手戻り |

> 重大度内訳：**S1=0、S2=12、S3=4、S4=1（計 17 件）**。ID は連番だが重大度順に並べた（REV-011 は重要度が高いため S2 群に含める）。

---

## 3. 検証して問題なかった項目

### 3.1 抽査カバレッジ（26/26 ファイル）

| # | ファイル | 抽査方法 | 主な確認点 | 判定 |
|---|---|---|---|---|
| 1 | 03-sales/00-overview.md | 精読 | 機能/画面/状態/イベント連携/未決、与信式 C-7、帳齡 C-8 | 矛盾 1 件（REV-012） |
| 2 | 03-sales/01-quotation.md | 抽読 | 見積→受注変換、取価・特価の引継、価格承認 | 主要契約は妥当（REV-004 の影響範囲に含む） |
| 3 | 03-sales/02-sales-order.md | 精読 | 状態機械、CALC、E05〜E08 payload、与信・取価 | 矛盾 3 件（REV-001/002/017） |
| 4 | 03-sales/03-delivery-picking.md | 精読 | 出荷確定、E10 payload、部分出荷、シリアル | 1 件（REV-008） |
| 5 | 03-sales/04-sales-return.md | 精読 | 返品受入、E11 payload、赤伝、原価戻し | 1 件（REV-006） |
| 6 | 03-sales/05-invoice-receivable.md | 精読 | 発票種別/コード、E12 payload、対账单、帳齡 | 1 件（REV-012） |
| 7 | 03-sales/06-credit-pricing.md | 精読 | 与信判定/コミット/解放、取価、特価承認 | 4 件（REV-003/004/005/009） |
| 8 | 03-sales/07-tracking-reports.md | 抽読 | 毛利・受注残 KPI、分析 | 数式は概ね妥当、REV-011 の影響を確認 |
| 9 | 03-sales/90-db-design.md | grep | 与信・AR 投影・請求テーブル、FK/索引 | 重大問題なし（DDL 全量は未検証） |
| 10 | 03-sales/91-api-design.md | 抽読 | API 一覧、状態連携、イベント記述 | 重大問題なし |
| 11 | 03-sales/92-report-batch-design.md | grep | 対账单・帳齡・BAT-SAL-006/007 | 1 件（REV-012） |
| 12 | 03-sales/93-messages.md | grep | 与信・発票・返品メッセージ | 重大問題なし（全件照合は未実施） |
| 13 | 03-sales/94-sample-data.md | 精読 | SO/DN/SRT/E10〜E12/与信/請求のサンプル値 | 1 件（REV-011） |
| 14 | 04-purchase/00-overview.md | 精読 | P2P 全链路、状態表、容差、未決 | 1 件（REV-014） |
| 15 | 04-purchase/01-requisition.md | 抽読 | 請購→転単、MOQ、見積単価 | 重大問題なし |
| 16 | 04-purchase/02-rfq-comparison.md | 抽読 | 比価・中選、目安単価（MDM 購買価格） | 重大問題なし |
| 17 | 04-purchase/03-purchase-order.md | 抽読 | PO 登録/承認、取価、容差率 | 1 件（REV-010 の一部） |
| 18 | 04-purchase/04-receipt-iqc.md | 精読 | 受入確定、超収容差、IQC、E14/E35 | 2 件（REV-010/016） |
| 19 | 04-purchase/05-return.md | 精読 | 返品出庫、赤伝、E16、金額計算 | 1 件（REV-007） |
| 20 | 04-purchase/06-purchase-invoice-ap.md | 精読 | 三単マッチ、容差、差異承認、E17、対账、前払 | 主要契約は妥当（E17 は 09 一致） |
| 21 | 04-purchase/07-tracking-performance.md | 抽読 | 交期跟踪、価格趨勢、供應商績效、MDM 参照 | 1 件（REV-015） |
| 22 | 04-purchase/90-db-design.md | grep | P2P テーブル、状態項目、FK | 重大問題なし（DDL 全量は未検証） |
| 23 | 04-purchase/91-api-design.md | 精読 | API 契約、E13/E14/E16/E17/E35 payload | 1 件（REV-013） |
| 24 | 04-purchase/92-report-batch-design.md | grep | 対账单・差異滞留・暫估照合 | 重大問題なし |
| 25 | 04-purchase/93-messages.md | grep | 容差・三単マッチ・付款メッセージ | 重大問題なし（全件照合は未実施） |
| 26 | 04-purchase/94-sample-data.md | 精読 | PO/GR/PIV/返品/三単マッチのサンプル値 | 数値は概ね整合（REV-013 の対比に使用） |

### 3.2 問題なしと確認した主要契約・数値

- **E12 `sales.invoice.issued`**：payload は 09 契約の全項目（`invoiceId/invoiceNo/invoiceCode/invoiceKind/customerId/orderId/deliveryIds[]/amount/taxAmount/taxRate/totalAmount/invoiceType/issuedAt`）を充足（`03-sales/05-invoice-receivable.md:620-634` 対 09:86）。
- **E13 `purchase.order.approved`**：payload 項目（orderId/orderNo/supplierId/lines/amount）は 09 と一致（明細サンプルの件数不整合のみ REV-013）。
- **E14 `purchase.receipt.posted`**：payload は 09 契約と逐字一致（`04-purchase/91-api-design.md:532-568` 対 09:88）。
- **E17 `purchase.invoice.matched`**：09 の契約項目と逐字一致し、内部 DTO→09 名の変換表も明記（`04-purchase/91-api-design.md:617-633` 対 09:91）。三単マッチの容差（単価 ±1%/±10 元、数量 0、税額 ±0.02、金額 ±10）と三態+HOLD の判定も定義済み（`06-purchase-invoice-ap.md:78-79`）。
- **E35 `purchase.receipt.cancelled`**：payload は 09 契約（`reversedLines[{materialId,batchNo,qty}]` 等）と一致（`04-purchase/91-api-design.md:570-597` 対 09:109）。
- **発票種別コード**：SAL の 10/20/30/40（専票/普票/数電専票/数電普票）は MDM 顧客 `invoice_type` のコードと一致（`03-sales/05-invoice-receivable.md:48,268` 対 `02-mdm/02-business-partner.md:265`）。
- **税額計算（サンプル）**：`102,780.00 × 13% = 13,361.40`（HALF_UP 2 桁）、`68,520.00 × 13% = 8,907.60`、`91,520.00 × 13% = 11,897.60` は計算一致（`03-sales/94-sample-data.md:149,186`、`04-purchase/94-sample-data.md:191`）。
- **状態機械**：SO 25→30→35→40/90/95、GR 25→30→90（E35）、PIV `matched_status` 0〜9＋`ap_status` の定義は網羅的で、部分出荷（35）・残数量クローズ（F-SAL-017）・超収例外承認・三単マッチ差異承認の経路も存在（`02-sales-order.md:125-146`、`04-purchase/00-overview.md:219-230`）。業務漏れ次元（A）で重大な欠落は検出せず。
- **業務漏れ（対账/前払/績效/出口）**：SAL 対账单 F-SAL-008、PUR 対账单 F-PUR-019、PUR 前払 F-PUR-022、供應商績效 F-PUR-026、SAL 出口 Phase 2 予約 F-SAL-016 が定義済み（`03-sales/00-overview.md:214,222`、`04-purchase/00-overview.md:255-256,296-297,301`）。「漏れ」との指摘は成立しない。
- **MDM 参照の実在性**：26 ファイル中の `mdm_*` テーブル・項目・API 参照は、02-mdm 90-db/91 の定義と一致（Lead 承認済み Phase2 予約 `mdm_contract`/`mdm_material_warehouse` を除き、存在しない MDM 参照は 0）。旧表名・旧項目名の残存も 0（第 1 轮の機械修正後に再確認済み）。

---

## 4. 未検証範囲・制約

- **90-db-design（両域）の DDL 全量**：CREATE TABLE/索引/制約はスポット確認のみ。列型・NULL・一意制約の完全照合は未実施。
- **91-api の全 API 項目（約 100 件超）**：代表 API とイベント関連 API のみ確認。エラーコード体系・権限コードの網羅照合は未実施。
- **92-report / 93-messages の全件**：主要帳票・メッセージのみ。帳票レイアウト項目やメッセージ ID 参照の完全性は未検証。
- **04-purchase/06 の三単マッチ算法**：差異種別判定（数量/単価/金額/税額/複合）と差異処理コードの全文精読は未実施。E17 payload との対応のみ確認。
- **他域発行イベント（E09/E15/E16 の INV/PRD 側 payload、E18/E20/E27/E28/E29）**：本レビューの対象外。E27/E29 の項目充足性は別途 FIN/INV レビューで要確認。
- **性能・同時実行・冪等性の実装詳細**：設計記述の確認のみで、負荷時の挙動・デッドロック・再送は未検証。
- **20-matrix / 90-data の出典実在性**：本レビューの観点外（data-researcher の担当範囲）。

---

## 5. 総評

**実装可否：条件付可（Conditional Go）**

- **S1（致命）= 0 件**。根拠のない実データ・法令違反・重大な会計破綻は検出しなかった。業務機能の網羅性（P2P/O2C、対账、前払、績效、出口予約）は高く、状態機械・三単マッチ・容差・差異承認の設計は実装可能な水準にある。
- **S2（重大）= 12 件**。主因は **跨域イベント契約の不整合（E06 項目名・金額口径、E10 serialNos、E11/E16/E35 の金額欠落）** と **MDM との契約不一致（価格 API 項目、標準価格/原価の非公開）**、**与信判定コードの自己矛盾**、**サンプル金額の不整合**。いずれも実装着手前に修正すべきで、そのまま実装すると引当・与信・売上/買掛・税務のいずれかが破綻する。
- **S3（一般）= 4 件、S4（建議）= 1 件**。サンプル・未決・モジュール境界・契約追補に関するもので、実装開始までに解消可能。
- **推奨対応順**：①E06/E10/E11/E16/E35 の 09 契約追補（SAL/PUR の実装が既に追加送出している項目を正本化）→ ②与信判定コード体系の再定義 → ③MDM 価格 API・標準価格/原価の公開契約 → ④受注→出荷→請求の金額一貫性（折扣）再計算 → ⑤容差の正本・優先順位の明文化。
- 第 2 轮で上記 S2 の修正後、再レビューを推奨する（特に REV-002/003/004/009/011 は実装影響が大きい）。
