# 红队评审报告：库存管理（05-inventory）＋生产管理（06-production）

| 項目 | 内容 |
|---|---|
| 文書名 | 红队评审报告：库存管理＋生产管理（レッドチームレビュー報告書） |
| 文書番号 | DSN-REV-SAL-001 |
| 版数 | v1.0 |
| 作成日 | 2026-10-20 |
| 作成者（レビュアー） | sales-designer（03-sales 担当。被レビュー対象の執筆者ではない） |
| 承認者 | Lead（未承認・レビュー待ち） |
| 状態 | 完了（第 1 ラウンド 指摘のみ。設計変更なし） |
| レビュー対象 | `docs/design/05-inventory/`（13 ファイル）、`docs/design/06-production/`（13 ファイル） |
| 準拠 | [对抗性评审宪章](README.md)（DSN-REV-000） |
| 関連文書 | [09 跨域流程](../00-common/09-cross-domain-flow.md) / [08 共通业务规则](../00-common/08-common-business-rules.md) / [04-purchase/00](../04-purchase/00-overview.md) / [07-finance/06](../07-finance/06-auto-voucher-costing.md) / [02-mdm/01](../02-mdm/01-material-master.md) / [90-data/bom-demo.md](../90-data/bom-demo.md) |

---

## 1. レビューの目的と独立性

[对抗性评审宪章](README.md) に基づき、**O2C 起点（受注・出荷・売上）と在庫・原価・購買の接続利用者**の視点から、05-inventory と 06-production を「実装前提で破壊しにいく」観点でレビューした。レビュアーは 03-sales の執筆者であり、本レビュー対象（在庫・生産）の執筆には関与していない。指摘はすべて**ファイル名:行番号＋引用**を付し、数値は再計算して確認した。推測は「推測」と明記した。

> **重要な前提**：レビュー実施中に `00-common/08`・`09` が **v1.1（2026-10-20 21:53、E35〜E43 追加・E11/E16/E22/E23/E24/E25/E26/E35 の payload 拡張）** に更新された。本報告は**更新後の 09/08 を正**として評価している。したがって「09 v1.1 で追加された項目を 05/06 側が未反映」という指摘は、更新日時の前後関係（05/06 の主要ファイルは 21:16 更新）に基づく**現時点の差分**である。

---

## 2. レビュー範囲・方法・実施日

| 項目 | 内容 |
|---|---|
| 実施日 | 2026-10-20 |
| 対象 | 05-inventory 13 ファイル（計 8,419 行）、06-production 13 ファイル（計 8,364 行）、合計 **26 ファイル・約 16,800 行** |
| 方法 1：精読 | `05-inventory/00-overview.md`、`02-inbound-outbound.md`（§2・§6.2/6.3）、`03-transfer-count.md`（§2）、`04-batch-serial-status.md`（§2）、`05-costing.md`（§2・§6）、`06-reservation-barcode-close.md`（§2・§6）、`06-production/00-overview.md`、`01-bom-routing-workcenter.md`（§4.2〜4.5）、`02-work-order.md`（§2・§6.2〜6.9）、`03-material-issue-reporting.md`（§2・§4）、`05-mrp-planning.md`（§3・§4）、`06-quality-management.md`（§2・§4） |
| 方法 2：機械照合 | ①在庫取引 19 種のコード照合（09 §7.1 対 05/00・02）②イベント payload の項目照合（E14/E15/E18/E19/E20/E21/E22/E23/E24/E25/E26/E35/E36/E37）③状態コードの全ファイル横断照合（WO・検査・在庫・予約・期間）④テーブル/帳票/バッチ/メッセージ件数の実測（同ディレクトリ 90〜94 と 00-overview）⑤`grep` による E35/E43/`costAmount`/`inspection_required` 等の出現漏れ検査 |
| 方法 3：数値再計算 | 移動平均の数値例（05-costing §2.4）、YE3 完工原価（03 §2.3・§4.7）、MRP バケット計算（05-mrp §4.2〜4.5）、BOM 120 PCE 展開（01 §4.3）、J11〜J16 金額整合 |
| 方法 4：跨域照合 | 09 §3/§7、08 §3.2/§8.1、04-purchase/00、07-finance/06、02-mdm/01、90-data/bom-demo.md・sources.md と突合 |
| 制約 | ①16,800 行の全行精読ではなく、上記キー文書の精読＋残ファイルは grep/部分読。②DB/プログラム実行・並行実行試験は未実施（設計記述のみで評価）。③Phase 2 機能（設備・exports 等）は概要レベルのみ。④INT/FIN/WF の全文レビューは範囲外（必要箇所のみ参照）。⑤2026-10-20 21:53 の 08/09 更新以降に 05/06 が更に更新された場合は差分が変わり得る |
| 指摘件数 | **19 件（S1: 0、S2: 8、S3: 9、S4: 2）**。捏造・水増しなし。問題なしと確認した項目は §4 に証拠付きで記載 |

---

## 3. 指摘一覧

### 3.1 重大度 S1（実装前に必須修正）

**該当なし（0 件）**。標準号・税率・企業情報の創作は検出されなかった（§4.3）。ただし S2 の 8 件は実装前に必ず解消すべき。

### 3.2 重大度 S2（実装前に修正必須）

| 指摘 ID | 重大度 | 対象ファイル:行 | 指摘内容 | 証拠・根拠 | 修正提案 | 想定影響 |
|---|---|---|---|---|---|---|
| REV-SAL-001 | **S2** | `06-production/03-material-issue-reporting.md:399-410`（対照 `00-common/09-cross-domain-flow.md:98`、`07-finance/06-auto-voucher-costing.md:158,417`） | **E24 `production.workorder.completed` の payload が 09 v1.1 の必須項目 `costAmount`（完工総原価）・`unitCost`（完成品単位原価）を送出しておらず、FIN の J16 自動仕訳テンプレートが参照する `payload.costAmount` が存在しない。** さらに J16 金額の責任は「PRD の完工原価（E24）が正」としているが、E24 でその総額を渡していない | 09 v1.1:98 は E24 の payload を `workOrderId, completedQty, lines[{materialId, qty, batchNo, unitCost, amount}], costAmount（完工総原価）, unitCost（完成品単位原価）, completedAt` と定義／PRD 03:401-409 の E24 JSON は `workOrderId, completedQty, lines[{materialId, qty, batchNo, unitCost}], completedAt` のみ／PRD 03:467「J16 は PRD の完工原価（E24）が正」／FIN 06:158「TPL-FIN-J16 … `payload.costAmount`（完工原価）」、FIN 06:417 も同様 | E24 の payload 例と仕様に `costAmount`（= CALC-MI-09 の `actual_total_cost`）とヘッダ `unitCost`（= CALC-MI-10）を追加し、INV/FIN の購読項目表と一致させる。J16 の金額解決順（`costAmount` 必須、欠落時はエラー）も明記 | J16 が金額 0/null で起票され、完成品在庫金額（1405）と生产成本（5001）が不整合。月結の E22/E23/E24 照合が失敗し、財務諸表の在庫・売上原価が誤る |
| REV-SAL-002 | **S2** | `06-production/06-quality-management.md:60,236,241-262`（対照 `05-inventory/00-overview.md:324`、`05-inventory/04-batch-serial-status.md:65`、`06-production/90-db-design.md:2037,2058,2072-2073`） | **E15 `quality.inspection.completed` の `result` と `lines` の意味が、PRD の DB・09 契約・INV の状態変換で三者不一致。** (a) DB は `result SMALLINT`（0/10/20/30/40/50 = 合格/不合格/特采/返工/报废）なのに E15 例は文字列 `PASS` を送出。(b) 09 は `result(PASS/CONCESSION/REJECT)` の 3 値のみで、PRD の 40 返工・50 报废 の変換規則がない。(c) E15 の `lines[]` は検査項目（`itemCode/judge`）であり、INV が必要とする「対象在庫行（倉庫・批次・状態・数量）」が含まれない。FQC は `source_id=workOrderId` のみで、複数回入庫・複数批次のどの在庫行を変換するか特定不能 | 06-quality:60「判定結果は 10 合格/20 不合格/30 特采/40 返工/50 报废」／:236「判定結果を `result` に設定（10/20/30/40/50）」／:253 実例 `"result": "PASS"`／:257-260 `lines` は `{itemCode, itemName, judge}`／06-production/90-db:2058 `result SMALLINT … 0:未判定 10:合格 20:不合格 30:特采 40:返工 50:报废`、:2072-2073 CHECK 制約／09:89 `result(PASS/CONCESSION/REJECT)`／06-quality:227 FQC `source_type=30、source_id=workOrderId`／INV 00:324「E15 → 状態変換（待検→可用/不合格）」、INV 04:65「E15 で qc_status/在庫状態を更新」 | E15 の `result` を文字列 enum（PASS/CONCESSION/REJECT/REWORK/SCRAP）に統一し、DB `result` との双方向マッピング表を PRD 06 に追加。E15 に `receiptId`/`stockTxnLineId`/`batchNo`/`inventoryStatus`（変換先 10/40/50）または `lines[{materialId, batchNo, qty, fromStatus, toStatus}]` を追加して INV が対象残高行を一意に特定できるようにする。返工/报废は「INV の状態変換 20→40/50」との対応を明記 | IQC/FQC の「待検→可用/不合格/報廃」変換が実装不能または誤変換となり、出荷・生産投入・原価に波及。在庫状態 40/50 の残高が永久に滞留し、月結の在庫金額と実態が乖離 |
| REV-SAL-003 | **S2** | `05-inventory/00-overview.md:313-335`（購読イベント表）、`06-production/00-overview.md:226-234`（同）（対照 `00-common/09-cross-domain-flow.md:109`、`04-purchase/00-overview.md:126,159,170,396`） | **E35 `purchase.receipt.cancelled` の購読者として 09 が INV/PRD を指定しているが、INV・PRD の両方に E35 の購読・在庫逆処理・IQC タスク取消の設計が存在しない。** PUR 側は「未検収・未照合なら E35 発行」で設計済みのため、受入取消後に待検在庫・IQC 検査依頼・仕入暫估が残留する | 09 v1.1:109 E35（発行者 PUR、購読者 INV/PRD/FIN、`reversedLines[{materialId, batchNo, qty, unitPrice, amount}], amount`）／PUR 00:126「入荷取消…E35 発行」、:159、:170「INV … 收货取消逆処理（E35）」／INV 00:313-335 の購読一覧に E35 なし／INV `02-inbound-outbound.md`・`04-batch-serial-status.md` にも E35・受入取消・GR 取消の記述なし（grep 0 件）／PRD 00:226-234 に E35 なし、06-quality にも E35 による IQC 取消なし | INV：E35 購読で `PI` の逆仕訳（残高・原価層・E18 逆、待検在庫の減算、`txn_status=90`）を PRC として定義（`reversedLines` の batchNo で対象残高行を特定）。PRD：E35 購読で該当 `prd_inspection`（IQC）を 90 取消し、NCR 起票済なら連動取消。月結チェックに「E35 未処理 0 件」を追加 | GR 取消後も「待検在庫」が帳簿に残り、可用量・在庫金額・IQC 品質記録が実態と一致しない。取消→再入荷で二重在庫、棚卸差異の原因になる |
| REV-SAL-004 | **S2** | `05-inventory/05-costing.md:66,304,348`（対照 `05-inventory/90-db-design.md:267,1476-1477`、`05-inventory/05-costing.md:358-362`） | **原価層（`inv_cost_layer`）を FIFO で減算しながら、原価計算は移動平均であり、両者の金額を「一致させる」と定義しているため、金額保存則が両立しない。** 例：層1=100@5.00、層2=500@5.50（平均 5.4167）で 120 出庫すると、移動平均出庫額=650.00 に対し FIFO 層減額=100×5.00+20×5.50=610.00。層残額は 2,690.00、残高金額は 2,650.00 となり 40.00 の恒常的差異が発生し、日次対账（BAT-INV-002）・月結チェックが必ず不一致になる | 05-costing:66「金額保存則：…Σ成本層残額 = 残高金額…」／:304「inv_cost_layer を FIFO で減算する（received_date ASC, id ASC）」／:348「移動平均法では成本層は原価計算の主体ではない…層は①庫齢分析、②成本調整の按分根拠、③取引別原価の追跡」／90-db:267 IV-03「Σ amount_on_hand = Σ inv_cost_layer.remaining_amount」、:1476-1477 IV-02/IV-03／:358-360 月結時の 3 者一致条件 | ①層を「年齢・分析専用」とするなら、金額保存則の対象から層を外し、`remaining_amount` は「移動平均で按分した評価額」として出庫の都度 `amount = 層残数量 × 出庫時平均` で再評価する（層単価は別途保持）。②または FIFO 層単価による原価計算へ変更（移動平均をやめる）。どちらかに統一し、BAT-INV-002 の判定式を修正 | 日次・月結の在庫金額照合が常に失敗し、原価計算の信頼性が失われる。在庫金額（貸借対照表）と売上原価（損益）の差異原因が層と残高の差として毎月発生 |
| REV-SAL-005 | **S2** | `06-production/05-mrp-planning.md:37,80,118,179-180`（対照 `05-inventory/00-overview.md:105,120-123`、`05-inventory/01-stock-query.md:79`） | **MRP の「利用可能在庫（OH）」算式が、在庫域が定める「可用量の P0 唯一算式」と異なる。** INV は「現存量 − 引当量 − 待検 − 凍結 − 不合格 − 報廃待処理」を唯一算式とし他文書での再定義を禁止しているが、MRP は「現有 − 待検 − 凍結 − 品質保留」で、**不合格（40）・報廃待処理（50）・引当済（reserved）を控除しない**。また INV 公開 API の返却項目は `rejectedQty` 等であり、MRP が取得を前提とする `quality_hold` は INV API の項目名と一致しない | PRD 05:37「現有 − 待検 − 凍結 − 品質保留（引当済は控除しない）」／:80 CALC-MRP-01 も同式／:118 I-04 で `on_hand`・`inspection`・`frozen`・`quality_hold` を取得と定義／:179-180 に同旨／INV 00:120「可用量公式（P0 唯一算式、禁止在其他文書出现不同写法）」、:123「現存量 − 引当量 − 待検量 − 凍結量 − 不合格量 − 報廃待処理量」／INV 01:79 CALC-01「Σ(qty_on_hand WHERE status=10) − Σ(qty_reserved WHERE status=10)」 | MRP は INV の可用量照会 API の `availableQty`（status10 残高 − 引当）を使用し、独自算式を削除する。少なくとも不合格 40・報廃待処理 50 を控除対象に追加し、「引当済を控除しない理由」を GR との関係で再定義（MTO 受注分と引当が二重計上にならない条件を明記）。API 項目名は INV の 91-api（`rejectedQty` 等）に合わせる | MRP が使用不能在庫（不合格・報廃待処理・引当済）を「使える在庫」と誤認し、発注・製造の計画量が過少になる。欠品・突発発注が増え、KPI（欠品率）と在庫金額が悪化 |
| REV-SAL-006 | **S2** | `06-production/00-overview.md:153,158`、`06-production/02-work-order.md:87-105`、`06-production/90-db-design.md:982,1027`（対照 `00-common/08-common-business-rules.md:124`） | **生産订单（WO）の状態機が 08 の共通状態定義と異なる。** 08 は WO を `10→25→30→35→40 / 90`（25=承認/計画確定、40=完了・結案）と定義するが、PRD は `20 承認待ち` を追加して `10→20→25→30→35→40→45` とし、`45 結案` を新設している。状態コードは伝票横断の共通契約であり、WF・在庫・財務・テストが 08 基準で実装されると承認待ちの判定・引当実施のタイミングがずれる | 08:124「生产订单 WO \| 10→25→30→35→40 / 90 \| 25 承認/計画確定、30 下达・引当…40 完了・結案」／PRD 00:153「`20` 承認待ち（本域拡張）」、:158「`45` 結案（`40` の終端拡張）」／PRD 02:87-105 の stateDiagram・遷移表 T-01〜T-08／PRD 90-db:982「10:草稿 20:承認待ち 25:承認済 30:下达済 35:製造中 40:完工 45:結案」、:1027 CHECK 制約 | ①08 §3.2 を「WO 10→20→25→30→35→40→45/90」へ正式改訂する（Lead 承認のうえ 08 に追記）か、②PRD を 08 どおりに戻し 40=完了・結案、承認待ちは WF タスク側で表現する。いずれの場合も PRD 内の 00/02/90 の 3 箇所を同時修正し、E2E テストの状態期待値を統一 | 承認・引当・完了の状態判定が文書間で不一致となり、WF 連携や在庫引当（E21/E09）の実行時点がぶれる。テストで「25 承認済」の意味が実装者ごとに異なり、受入試験が不能 |
| REV-SAL-007 | **S2** | `06-production/03-material-issue-reporting.md:470-479`、`06-production/04-outsourcing.md:277-278`（対照 `00-common/09-cross-domain-flow.md:96,98,110`、09 §3 事件一覧） | **生産伝票の取消（逆処理）が、09 に存在しないイベント（E22 取消・E23 取消・E24 取消・E25 逆・E26 逆・E36 取消）に依存している。** 09 §2.2 はイベントを「事実の通知」と定め、正の事実（E22/E23/E24/E25/E26/E36）のみ定義し、生産系の取消・赤伝イベントは未定義（E35 は購買受入取消のみ）。このままでは MII/MIR/WR/FGI/OSI/OSR の取消時に、在庫逆出庫・原価戻し・仕訳赤伝を起動できない | PRD 03:474「INV へ逆出庫依頼（E22 逆）、原価戻し \| E22（取消）→ E18（逆）」、:475「E36（取消）」、:476「E23（取消）」、:477「E24（取消）」／PRD 04:277「E25 逆（E18 逆）」、:278「E26 逆（E18 逆）」／09 v1.1:96/98/110 に取消 payload なし、§3 全 43 イベントにも該当なし／08 §13.1「取消時は関連在庫・会計を逆処理」 | 09 に `production.issue.cancelled`/`production.report.cancelled`/`production.completion.cancelled`/`production.outsourcing.issue.cancelled`/`production.outsourcing.receipt.cancelled`（または共通 `production.document.reversed`）を追加し、payload に元 txnId・逆数量・理由・`reversalOfEventId` を持たせる。INV/FIN の逆処理（在庫戻し・E18 逆・J11/J12/J16 赤伝）の起動条件を明記。追加しない場合は「取消は当日・INV 過账前のみ、以降は赤伝伝票を新規作成」と業務制約を明文化 | 確定後の取消・訂正ができない、または実装者が独自解釈で在庫・仕訳を直接逆処理し、E18/E19 と GL の不整合・二重計上が発生。品質 NCR の返工/廃棄取消にも波及 |
| REV-SAL-008 | **S2** | `05-inventory/05-costing.md:292-294,536`、`05-inventory/02-inbound-outbound.md:514-527`（対照 `05-inventory/90-db-design.md:214`、`05-inventory/00-overview.md:181`） | **入庫時の平均単価更新は「全状態行の avg_unit_cost を同一値に更新」と定義するが、他状態行の `amount_on_hand` の再評価式が無く、出庫時は対象行の金額から「cost group 平均×出庫数量」を減算する。** 例：状態10 行が 100@5.00（金額500）、状態20 に 500@8.00 を入庫して平均=(500+4,000)/600=7.50 に更新後、状態10 から 100 出庫すると出庫額=750.00 > 行金額 500.00 となり、DB の `ck_inv_stock_balance_amount CHECK (amount_on_hand >= 0)` 違反で出荷が失敗する（または金額を負にする）。処理手順・DB 更新仕様・制約が三者で矛盾 | 05-costing:292「全状態行の `avg_unit_cost` を同一値に更新する」／:293「対象状態行の `qty_on_hand`・`amount_on_hand` を加算」／:536 更新仕様「`amount_on_hand, avg_unit_cost` … cost group の全状態行」／02-inbound:514-515 出庫 `row.amountOnHand = row.amountOnHand.subtract(amount)`、:523-524 入庫加算のみ／90-db:214 `CHECK (amount_on_hand >= 0)`／INV 00:181「任何余额行 amount_on_hand ≥ 0」 | 入庫時の平均更新の一部として、cost group 全行の `amount_on_hand = qty_on_hand × 新平均` を再評価し、端数差は最終行（または最大金額行）で調整する手順を明記。出庫計算前に「対象行金額 ≥ 出庫金額」を 검証し、不足時は再評価 or エラー（`MSG-INV-037`）とする。DB 更新仕様の「全状態行」と処理手順を一致させる | 混在状態（待検・凍結・不合格と可用）で入出庫が発生する通常運用で、出荷・領料が DB 制約違反で失敗。または行単位の在庫金額が破綻し、棚卸・原価調整の根拠が失われる |

### 3.3 重大度 S3（実装開始までに修正）

| 指摘 ID | 重大度 | 対象ファイル:行 | 指摘内容 | 証拠・根拠 | 修正提案 | 想定影響 |
|---|---|---|---|---|---|---|
| REV-SAL-009 | S3 | `05-inventory/02-inbound-outbound.md:18,133-134,142-228`（対照 `00-common/09-cross-domain-flow.md:85,90`） | **RT_IN（销售退货入库）・PR_OUT（采购退货出库）の「発生源別業務ルール」節が存在しない。** §2.6 は PI/SI/MII/MIR/FGI/OSI/OSR/AOI/AOO/SC_OUT の 9 節のみで、冒頭 :18 は「RT_IN/PR_OUT を含む 19 種の発生源・処理・原価・仕訳を定義する」と宣言している。また原価は「元 SI/PI 明細の unit_cost」としているが、09 v1.1 の E11/E16 は `unitPrice/amount/taxAmount/costAmount`（E11）、`unitPrice/taxRate/amount`（E16）を直接持つため、どちらを正とするか未定義 | INV 02:18「…PI/SI/…/RT_IN/PR_OUT の発生源・処理・原価・仕訳を定義する」／:133 `RT_IN` 原価「原销售出库原价（SI 明細の unit_cost）」／:134 `PR_OUT` 原価「原入库价（PI 明細の unit_cost）」／§2.6 は :144〜:226 の 2.6.1〜2.6.7 のみ／09 v1.1:85 E11 に `originalDeliveryId, costAmount, unitPrice, amount`、:90 E16 に `unitPrice, taxRate, amount` | §2.6.8 RT_IN、§2.6.9 PR_OUT を追加し、①E11/E16 の新項目（原価・元伝票・批次）と残高/原価層の更新、②状態（RT_IN: 10/40/20、PR_OUT: 10/20）、③引当対象外・シリアル号復元、④E18/J23/J04 の金額根拠（E11.costAmount を正とする等）を明記 | 返品・仕入返品の原価・批次・状態戻入が実装者判断となり、J23（売上原価戻し）と在庫金額が伝票間で不一致 |
| REV-SAL-010 | S3 | `05-inventory/05-costing.md:69,93,120,312` | **価格差異の按分分母が、算式定義と数値例・処理手順で異なる。** BR-CS-07/CALC-08 は「既出庫分 = 差異総額 × 既出庫数量 ÷ **対象入庫数量**」とするが、数値例は分母 600（対象入庫 500 ＋ 期初 100）で 15.00 を算出し、処理手順も「target_qty + 対象以前の残数量」としており、算式どおり 500 で計算すると 18.00 となる | 05-costing:69 BR-CS-07「配分比 = 既出庫数量 ÷ 対象入庫数量」／:93 CALC-08「既出庫分 = 差異総額 × 既出庫数量 ÷ 対象入庫数量」／:120「75.00 × 120 ÷ 600（対象入庫 500 ＋ 期初 100 = 600 のうち出庫 120）」／:312 処理手順4「÷ (target_qty + 対象以前の残数量)」 | 算式定義を「対象入庫時点の cost group 数量（対象入庫数量＋対象以前残数量）」に統一し、CALC-08 の表記と数値例を修正（または「対象入庫数量」の定義を明確化）。E19 `issuedAdjustmentAmount` の計算も同一式に統一 | 在庫分/売上原価分の配分額が実装者により 15.00 と 18.00 に分かれ、在庫金額・当期費用・E19 が不一致 |
| REV-SAL-011 | S3 | `06-production/01-bom-routing-workcenter.md:257,299,304,706`、`06-production/05-mrp-planning.md:448`、`06-production/94-sample-data.md:96`、`90-data/bom-demo.md:177` | **YE3-100L1-4 120 PCE の 50W470 厳密展開量が文書間で不一致。** PRD 01 は 2,623.42 KGM（内訳 1,888.85＋734.57）とするが、PRD 05・PRD 94 は 2,623.55 KGM、90-data は 2,571.43 KGM（概算）とする。再計算では 1.0050×1.0050×1.0101×21.4286×120 = 約 2,623.55 であり、PRD 01 の内訳にも計算誤差（122.4271×15.4286=1,888.88、×6.0000=734.56）がある | PRD 01:257「2,623.42 KGM」、:299「1,888.85 KGM」、:304「合計 2,623.42 KGM」、:706 テスト期待値「2,623.42」／PRD 05:448「120 × 21.8629 = 2,623.55 KGM」／PRD 94:96「厳密展開 2,623.55 KGM」／90-data bom-demo:177「2,571.43」（概算） | 展開の丸め規則（各階 4 桁切上）を再適用して正値を確定し、PRD 01 の算例・テスト期待値・PRD 05/94 の注記を同一値に統一。90-data の概算式との差（中間損耗累積）は「概算 vs 厳密」の注記に留める | MRP・工单展開の受入テスト期待値が文書で異なり、どちらを正とするか実装者判断になる。BOM 数量の信頼性低下 |
| REV-SAL-012 | S3 | `06-production/02-work-order.md:383,399`、`06-production/90-db-design.md:1089,1092`（対照 `00-common/09-cross-domain-flow.md:95`） | **E21 の `requiredQty` の意味（純必要量 net か総必要量 gross か）が、DB・イベント・画面で揺れている。** DB の `prd_work_order_material.required_qty` は「純必要量（net）」、`total_required_qty` は「総必要量（gross）」だが、E21 は `requiredQty = total_required_qty − 既引当`（gross 相当）を同名 `requiredQty` で送信している。09 も同フィールド名のまま | PRD 90:1089「required_qty … 純必要量（BOM.component_qty × order_qty ÷ base_qty）」、:1092「total_required_qty … 総必要量（gross）= required_qty + loss_qty」／PRD 02:383「requiredQty（total_required_qty − 既引当）」、:399 実例 `120.6030`／09 v1.1:95 E21 `lines[{materialId, requiredQty, uom, warehouseId}]` | E21 に `requiredQty`（gross）と `netRequiredQty` を分けて定義するか、`grossRequiredQty` に改名。09 §3 E21 の説明に「gross（ロス込み）」を明記し、INV の引当数量が gross であることを保証 | INV が net と解釈すると損失率分（本例 0.5〜30%）引当不足となり、材料欠品・追加引当が頻発 |
| REV-SAL-013 | S3 | `06-production/03-material-issue-reporting.md:84,309-321,333-346`、`05-inventory/02-inbound-outbound.md:62,174,178`、`05-inventory/05-costing.md:78`（対照 `00-common/09-cross-domain-flow.md:96,110`） | **E22/E36 の `unitCost` の権威（正）が未定義。** PRD は「参考単価」を E22/E36 に設定し、INV は「自域の移動平均（E18）が権威」とし、INV の MIR 原価は「元 MII 明細の unit_cost」とする。E22 送信時点では INV の移動平均は未確定であり、E36 の unitCost も PRD の参考値。J11/J12 の金額根拠（PRD 参考値か INV E18 か）が一意でない | PRD 03:84 BR-MI-14「PRD は参考単価で計上し、E18 受信で actual_unit_cost を更新」／:317 E22 `unitCost: 252.000000`／:341 E36 `unitCost: 252.000000`／INV 02:62/BR-03「出庫原価は出庫直前の移動平均」、:174/178 MII/MIR 原価の定義／INV 05:78 BR-CS-16「出庫原価の単価はロック取得後の最新平均を用いる。E10 の costAmount が参考値でも本域の計算結果を正とする」／09:96/110 に `unitCost` | 09/各文書に「E22/E36 の unitCost は参考値（スナップショット）であり、J11/J12 の金額は INV の E18 amount を正とする」と明記。E22/E36 の payload 例に `costSource: REFERENCE` 等の識別子を追加するか、INV 側で E18 受信後に PRD へ補正通知する手順を定義 | J11/J12 の材料費が参考値で起票され、E18 の権威原価と差額が生じる。工程別原価・工单原価差異の原因が不明になる |
| REV-SAL-014 | S3 | `06-production/00-overview.md:167`、`06-production/02-work-order.md:127`、`06-production/06-quality-management.md:85-93`、`06-production/90-db-design.md:2037,2072`（対照 `00-common/08-common-business-rules.md:119`） | **検査单の状態コードが 08・PRD 00・PRD 06/90 で三者不一致。** 08 は IQC を `10→30→40 / 95 / 90`、PRD 00 は検査单を `10/30/40/90` とするが、PRD 06 の状態図と DB は `10 待検→20 検査中→30 判定確定→90 取消`、WO のサブステータス `inspection_status` は `00/10/20/30`（意味も異なる）。同名 `inspection_status` が 3 種類のコード体系で使われている | 08:119「来料检验 IQC \| 10→30→40 / 95 / 90」／PRD 00:167「检验单 \| 10/30/40/90 \| 草稿/検査中/判定確定/取消」／PRD 06:85-93 stateDiagram S10→S20→S30／:2037「inspection_status … 10待検 20検査中 30判定確定 90取消」／:2072 CHECK (10,20,30,90)／PRD 02:127 WO サブステータス「00 未/10 検査中/20 合格/30 不合格・特采」 | 08 を正として全コードを `10 待検/30 検査開始/40 判定確定/95 却下/90 取消` に統一するか、08 §3.2 を PRD 06 の `10/20/30/90` に改訂。WO のサブステータスは名称を `inspection_progress_status` 等に変更し、検査单の状態と混同しないようにする | 検査单の状態遷移・帳票・E15 発行タイミングが実装者ごとにずれ、WF 承認・品質 KPI・検査進捗が正しく集計できない |
| REV-SAL-015 | S3 | `05-inventory/02-inbound-outbound.md:152,191,202,313`（対照 `05-inventory/02-inbound-outbound.md:63`、`05-inventory/00-overview.md:100`、`02-mdm/01-material-master.md:230`） | **検査要否の参照フィールド名が、INV 内で `inspection_required` と `inspection_stage` に分裂し、MDM の実フィールド（`inspection_stage`）と一致しない。** 同じファイル内でも :63 は `inspection_stage=0`、:152/191/202/313 は `inspection_required` を使用。PI/FGI/OSR の初期在庫状態（10 直入 vs 20 待検）の判定が実装不能 | INV 02:63「`mdm_material.inspection_stage = 0（免检）`」／:152「`inspection_required=false` は 10 可用」／:191/:202 同旨／:313 画面項目「物料 `inspection_required`」／INV 00:100「検査段階」／MDM 01:230「`inspection_stage` … 00 免検/10 IQC/20 IPQC/30 FQC/40 全工程」 | 全箇所を `mdm_material.inspection_stage`（00 免検）に統一し、判定式を「inspection_stage=00 → 10 可用、それ以外 → 20 待検」と明記。画面項目 ID・API DTO も `inspectionStage` に修正 | 検査不要品が待検のまま滞留、または検査必要品が可用で出庫され、品質・在庫状態が不正 |
| REV-SAL-016 | S3 | `05-inventory/02-inbound-outbound.md:80-81,153`、`05-inventory/05-costing.md:63`（対照 `00-common/09-cross-domain-flow.md:88`） | **采购入库の運費・関税の入力/計上タイミングが矛盾。** 02 は E14 に運費・関税が含まれないため「暫定 0 で過账し、後日 `inv_cost_adjustment` で調整」とするが、同ファイルの CALC-01・画面例（運費按分 800.00、入庫金額 11,200.00）は受入時に運費を入力・按分する前提。E14 の payload にも運費項目がなく、調整区分 `20 運費差異` の起票契機も未定義 | 02:153「運費・関税は E14 に含まれないため、暫定 0 で過账し、後日 inv_cost_adjustment で調整」／:80 CALC-01「数量×税抜単価 + 運費分摊 + 関税分摊」、:81 CALC-02、:277 以降の画面例に運費 800.00／05-costing:63 BR-CS-01「入庫原価 = … + 運費分摊 + 関税分摊」／INV 90-db `adjustment_type … 20運費差異`／09:88 E14 payload に運費なし | 受入時に「運費を入力するのか（誰が・どの伝票で）」を明確化。E14 に運費・関税を追加するか、PUR の運費入力伝票→INV のコスト調整連携（API/イベント）を定義。画面例と処理手順を一致させる | 実際の運費が在庫原価に反映されず、原価が過少/過大に。後日調整の起票漏れで月結差異が残る |
| REV-SAL-017 | S3 | `06-production/03-material-issue-reporting.md:397,412,419-425`（対照 `00-common/09-cross-domain-flow.md:367-369`） | **J16 の計上タイミングと J15（製造費用结转）の月結タイミングが不整合。** 完工入库時に J16 が「材料費＋人工費＋製造費用（暫定配賦）」を 5001 の貸方に計上するが、製造費用の 5001 への振替（J15）は月結時、人工費（J13）は報工時、製造費用の実際発生（J14）は費用計上時であり、完工が月結前だと 5001 が貸方超過（一時的な負残高）となり得る。暫定配賦の起票ルールが 09 にない | PRD 03:397「暫定単位原価（CALC-MI-10）を計算」、:412「FIN が J16 を計上」、:419-425 で J11〜J16 対応／09:364-369 J13（報工時）/J14（費用発生時）/J15（月結）/J16（E24）／PRD 03 CALC-MI-09 は製造費用を含む完工原価 | ①FIN が J16 時に製造費用の暫定配賦を同時に起票する（J15 前倒し）②または完工原価を材料費＋人工費のみとし、製造費用は月結後に原価調整する③月結前に FGI を行わない運用制約を設ける、のいずれかを明記 | 完工直後の生産成本 5001 が借方不足となり、財務諸表（仕掛品・在庫）が一時的に不正確。月結時の成本差異分析が複雑化 |
| REV-SAL-018 | S4 | `05-inventory/02-inbound-outbound.md:138-140`、`05-inventory/04-batch-serial-status.md:96`（対照 `00-common/09-cross-domain-flow.md:341`、09 §7.1「19 種のみ・追加禁止」） | **09 の 19 取引種に含まれる `SC_IN`（报废转入）を、INV は「予約コード」として実際には使用せず、状態移動を `ST_OUT`＋`ST_IN` の対で処理するとしている。** 09 は SC_IN を独立取引として定義し、INV 00 の取引一覧にも掲載しているため、取引種別・帳票・監査の単位が実装により異なる | 09:341「SC_IN \| 报废转入 \| IN \| +（不良品仓） \| 移動平均 \| 内部状态移动」／INV 02:138-140「SC_IN は予約し、状態移動は ST_OUT+ST_IN の対で行う」／INV 04:96 同旨／INV 00:157 付近の 19 種一覧に SC_IN あり／Lead 2026-10-20 裁決「19 種のみ・新類型禁止」（INV 02:60 BR-01） | SC_IN を使用する（40→50 の状態移動を SC_IN 1 件で表現）か、使用しないなら 09 §7.1 から SC_IN を削除し 18 種に改訂する（Lead 承認）。INV の取引一覧・帳票の取引種別フィルタ・監査集計を同時修正 | 取引種別別の在庫異動報告・監査で SC_IN が 0 件のままとなり、設計と実装の取引分類が不一致。外部監査で「定義された取引が使われていない」と指摘 |
| REV-SAL-019 | S4 | `05-inventory/00-overview.md:120-123`、`05-inventory/06-reservation-barcode-close.md:63`、`05-inventory/01-stock-query.md:690` | **可用量の算式表記が文書内で揺れている。** 00-overview は 6 項目（現存−引当−待検−凍結−不合格−報廃待処理）、06-reservation BR-RS-04 と 01-stock-query のテスト期待値は 5 項目（報廃待処理を省略）。計算結果自体は `status=10` 残高−引当で等価だが、「唯一算式」と宣言しながら表記が 3 種類あるため照合時に誤判定しやすい | INV 00:123（6 項目）／INV 06:63「可用量 = 在庫 − 引当 − 待検 − 凍結 − 不合格」／INV 01:690 テスト期待値「現存 − 引当 − 待検 − 凍結 − 不合格」 | 表記を 00-overview の 6 項目に統一し、参考として「= Σ(status10) − Σ(reserved status10)」の実装式を併記。テスト期待値も同表記に修正 | 実装者・テスタが「報廃待処理」を控除し忘れ、わずかに可用量が過大になるリスク（計算式実装が status=10 ベースなら影響なし） |

---

## 4. 検証して問題なかった項目（カバレッジ証跡）

### 4.1 内部整合（在庫・原価・MRP・工单）

| # | 検査項目 | 結果 | 根拠 |
|---|---|---|---|
| P-01 | 在庫取引 19 種のコードが 09 §7.1 と完全一致（追加・欠落なし） | ○ | `05-inventory/00-overview.md:140-160`（PI/SI/MII/MIR/FGI/OSI/OSR/TR_OUT/TR_IN/ADJ_IN/ADJ_OUT/SC_IN/SC_OUT/AOI/AOO/RT_IN/PR_OUT/ST_IN/ST_OUT）と 09 §7.1:320-341 を突合 |
| P-02 | E18/E19/E20/E37 payload の項目が 09 v1.1 と一致 | ○ | `05-inventory/00-overview.md:307-311`、`05-costing.md:354-356`、`06-reservation-barcode-close.md:391` と 09:92-94/111 |
| P-03 | 予約（引当）の状態・E06/E07/E08/E09 の状態値 `RESERVED/PARTIAL/SHORTAGE/RELEASED` が 09 と一致 | ○ | `06-reservation-barcode-close.md:60-71,321-347`、`00-overview.md:307`、09:80-83 |
| P-04 | 移動平均の数値例（期初 100→PI 500→SI 120→PI 300→SI 80）を再計算 | ○ | `05-costing.md:103-111`：600/3,300→5.500000、480/2,640→5.500000、780/4,360→5.589744、700/3,912.82→5.589743。残高金額・金額保存則の計算は一致 |
| P-05 | YE3 完工原価の算例（材料費 89,458.80＋人工 1,781.25＋製造費用 2,137.50＝93,377.55、÷120＝778.146250、標準原価 93,384.00、差異 −6.45）を再計算 | ○ | `03-material-issue-reporting.md:92-101`：全項目一致 |
| P-06 | MRP バケット計算（成品 35/120/100、定子总成 50/100/100、50W470 2,000/2,500、QZY 50/236.13/270.75）を再計算 | ○ | `05-mrp-planning.md:394-458`：NR・PAB・ロット切上・端数は一致（数値例自体の整合性。BOM 厳密展開の値のみ REV-SAL-011） |
| P-07 | 工单状態のフルセット（10/20/25/30/35/40/45/90/95）が DB・画面・遷移表で一致、拆分・合并・取消・結案・保留の条件と権限を定義 | ○ | `02-work-order.md:52-130,414-460`、`90-db-design.md:982,1027`（ただし 20/45 の 08 整合は REV-SAL-006） |
| P-08 | 批次/序列号の状態変換マトリクス・FEFO/FIFO・有効期限・QC 状態の定義が自己完結 | ○ | `04-batch-serial-status.md:51-136`、`02-inbound-outbound.md:132-140` |
| P-09 | 棚卸差異の計算（スナップショット＋事後純変動で還元）・調撥在途・金額保存則・同倉移庫の一括処理 | ○ | `03-transfer-count.md:52-148`：CALC-01〜08 の計算例を再計算し一致 |
| P-10 | 月结前置检查 10 項目、期間再開（E37）の承認・FIN 連携、E35/E36/E37 の取り込み | △ | E36/E37 は INV 00:311/331、02:178、06:391 に反映済み（○）。E35 は REV-SAL-003 |
| P-11 | ロック順序・lock_timeout・デッドロック再試行・負在庫 CHECK・楽観排他の設計 | ○ | `02-inbound-outbound.md:456-527`、`90-db-design.md:77,213-214` |
| P-12 | テーブル件数（INV 22／PRD 47）と 00-overview のテーブル一覧、帳票（17/16）・バッチ（9/11）・メッセージ（120/96）の件数一致 | ○ | 各 00-overview §8、92、93 の実測と一致 |

### 4.2 跨域契約（一致したもの）

| # | 検査項目 | 結果 | 根拠 |
|---|---|---|---|
| C-01 | E21（工单下达→INV 引当）の payload 項目（workOrderId/workOrderNo/lines[]/plannedStartDate） | ○ | 09:95 と PRD 02:390-404 |
| C-02 | E25/E26（委外発料/受入）の payload に加工費・税額を含む項目が 09 v1.1 と整合（委外文書の項目定義は 09 を参照） | ○ | 09:99-100 と PRD 04:186-247（詳細は REV-SAL-007 の取消イベントのみ課題） |
| C-03 | E36（退料）の発生源が MIR として INV に購読され、09 の payload と一致 | ○ | 09:110、INV 00:331、02:178 |
| C-04 | 品質検査の所管（IQC 検査単は PRD の `prd_inspection`、PUR は起票依頼）が 09 §8・PUR 00 と一致 | ○ | PRD 00:30-31、PUR 00:30「IQC 本体は PRD `prd_inspection`」、09 §8 |
| C-05 | 承認マトリクス（盤盈盤亏 10,000 元・調撥 10,000 元・成本調整 1,000 元・状態変換・AOI/AOO 10,000 元）が 08 §8.1 追補に存在 | ○ | 08:279-286、INV 00:216-229 |
| C-06 | 品質標準の出典（GB/T 2828.1-2012、GB/T 5782-2025、GB/T 9439-2023、GB/T 1196-2023、GB/T 6109.5-2025、JB/T 9558-1999）が 90-data/sources.md に実在 | ○ | 06-quality:58、01-bom:221-251、sources.md S-006/007/008/013/026/034/042 |

### 4.3 データ真正性（スポットチェック）

90-data/sources.md と照合した範囲で、**実在しない標準号・法規・企業情報の創作は検出されなかった**。GB/T 5782-2025（S-013）、GB/T 9439-2023（S-008）、GB/T 1196-2023（S-026）、GB/T 6109.5-2025（S-007）、GB/T 2828.1-2012（S-034）、JB/T 9558-1999（S-042）はいずれも sources.md に登録があり、本文の引用と一致。YE3-100L1-4 = `3001000001`、顧客 C000001 等も 06-code-list/90-data と一致。

### 4.4 YE3-100L1-4 120 PCE の在庫→原価チェーン追跡（指示対応）

| 段階 | データ・金額 | 判定 | 関連指摘 |
|---|---|---|---|
| 1. 受注 120 PCE → E21 引当 | `requiredQty=120.6030`（gross） | 意味の混在（net/gross） | REV-SAL-012 |
| 2. MRP 展開（50W470） | 2,623.42（PRD 01）／2,623.55（PRD 05・94）／2,571.43（90-data 概算） | 文書間不一致 | REV-SAL-011 |
| 3. 領料 MII → E18 → J11 | 例：30,240.00（120×252）／CALC-MI-02 は 120.6030×252 | 参考値と INV 権威原価の混在 | REV-SAL-013 |
| 4. 報工 E23 → J13（人工 1,781.25）／製造費用 2,137.50 | 計算は一致 | 完工時 J16 とのタイミング課題 | REV-SAL-017 |
| 5. 完工 E24（unitCost 778.146250、総額 93,377.55） | 算術は一致。ただし E24 payload に `costAmount`/header `unitCost` なし | FIN J16 の金額が解決不能 | REV-SAL-001 |
| 6. FGI → 在庫金額（E24 unitCost）→ J16 | INV 94 は「FIN 提供 845.00/PCE」と記載し、PRD の 778.146250 と別値・別責任 | 完工原価の提供元が不明確 | REV-SAL-001 |
| 7. SI（出荷）→ J06 | 移動平均出庫額 vs FIFO 層減額の金額保存則が不成立 | 在庫金額・売上原価の照合が失敗 | REV-SAL-004、REV-SAL-008 |
| 8. 取消・返品時の逆処理 | MII/FGI の取消イベントが 09 に未定義 | 逆仕訳の起動不能 | REV-SAL-007 |

> チェーン全体として「数量→材料費→人工費→製造費用→完工原価→在庫→売上原価」の**算術自体は追跡可能**だが、①E24 の総額フィールド欠落、②完工原価の提供元（PRD/FIN）の不一致、③層と残高の金額乖離、④取消イベント欠落の 4 点で実装時に断絶する。

### 4.5 ファイル別カバレッジ（26 ファイル）

| ファイル | 読了範囲 | 主な確認点 | 指摘 |
|---|---|---|---|
| 05-inventory/00-overview.md | 精読（全 605 行） | 定義・状態・19 取引・機能/画面/帳票/表/IF/権限 | 003/005/008/019 |
| 05-inventory/01-stock-query.md | 部分（§2・§6・テスト） | 可用量算式・在庫金額・照会 | 005/019 |
| 05-inventory/02-inbound-outbound.md | 精読（§2・§6.2/6.3・画面・チェック） | 19 取引ルール・過账算法・ロック | 004/008/009/015/016/018 |
| 05-inventory/03-transfer-count.md | 精読（§2） | 調撥在途・棚卸差異・承認 | なし |
| 05-inventory/04-batch-serial-status.md | 精読（§2） | 批次/序列号・状態変換マトリクス | 002/018 |
| 05-inventory/05-costing.md | 精読（§2・§6） | 移動平均・原価層・差異配分・再計算 | 004/008/010/013/016 |
| 05-inventory/06-reservation-barcode-close.md | 精読（§2・§6） | 引当/解放/消費・PDA・月結/再開 | 019 |
| 05-inventory/07-reports.md | 部分（grep 中心） | 域内帳票と RPT の境界 | なし |
| 05-inventory/90-db-design.md | 部分（全 CREATE TABLE 一覧＋残高/予約/原価 DDL） | 22 表・索引・CHECK・金額保存則 | 004/008 |
| 05-inventory/91-api-design.md | 部分（予約/月結/照会 API） | API 一覧・予約解放 API | なし |
| 05-inventory/92-report-batch-design.md | 件数・grep | 帳票 17・バッチ 9・月結チェック | なし |
| 05-inventory/93-messages.md | 件数・grep | メッセージ 120・ID 形式 | なし |
| 05-inventory/94-sample-data.md | 部分（FGI/SI 例・仮定値） | 845.00/PCE の出典・数値 | 001 |
| 06-production/00-overview.md | 精読（全 519 行） | 状態体系・イベント・機能/画面/帳票/表 | 006/007/014 |
| 06-production/01-bom-routing-workcenter.md | 精読（§4.2〜4.5） | BOM 展開・低層コード・成本巻上・120 PCE 算例 | 011 |
| 06-production/02-work-order.md | 精読（§2・§6.2〜6.9） | 状態遷移・引当・拆分/合并/変更/結案 | 006/012/014 |
| 06-production/03-material-issue-reporting.md | 精読（§2・§4） | MII/MIR/E22/E36/E23/E24・原価帰集・J11〜J16 | 001/007/013/017 |
| 06-production/04-outsourcing.md | 部分（§1・§2・§4 抜粋） | 委外発料/受入/加工費・E25/E26 | 007 |
| 06-production/05-mrp-planning.md | 精読（§3・§4） | MRP 算式・バケット・批量・YE3 算例 | 005/011 |
| 06-production/06-quality-management.md | 精読（§2・§4） | IQC/IPQC/FQC・E15・NCR・追溯 | 002/014 |
| 06-production/07-dashboard-reports.md | 部分（KPI・帳票） | 工数/効率 KPI・帳票範囲 | なし |
| 06-production/90-db-design.md | 部分（全 CREATE TABLE 一覧＋WO/BOM/検査 DDL） | 47 表・状態 CHECK・required/gross の定義 | 006/012/014 |
| 06-production/91-api-design.md | 件数・grep | API 102 件の一覧性 | なし |
| 06-production/92-report-batch-design.md | 件数・grep | 帳票 16・バッチ 11 | なし |
| 06-production/93-messages.md | 部分（ID・主要メッセージ） | メッセージ 96・ID 形式 | なし |
| 06-production/94-sample-data.md | 部分（YE3 工单・原価・MRP 算例） | 778.146250・2,623.55・120 PCE | 011 |

---

## 5. 未検証範囲・制約

1. **実行検証なし**：並行トランザクション・ロック待ち・デッドロック・DB 制約違反の実挙動は未実行（設計記述の整合性評価のみ）。REV-SAL-008 の負金額チェックは、実装時の SQL/アプリ挙動によっては「エラーで止まる」か「金額調整で回避」かの分岐があるため、**実行試験で確認が必要**。
2. **全行精読ではない**：26 ファイル約 16,800 行のうち、キー文書 12 本を精読、残りは grep・部分読。90-db は全 CREATE TABLE と主要 DDL を確認したが、全テーブルの全索引・容量見積までは精査していない。
3. **09 v1.1 との差分**：本レビュー中に 08/09 が v1.1 に更新されたため、05/06 の「09 未反映」指摘（REV-SAL-001/003/009/013）は**更新日時 21:16 対 21:53 の差分**に基づく。レビュー後に 05/06 が同期改訂された場合は再確認が必要。
4. **Phase 2 範囲**：設備管理（`prd_equipment`）・輸出・MES/PLM 連携・プロモーション等は概要レベルのみで、詳細設計の妥当性は評価していない。
5. **他域全文**：04-purchase／07-finance／08-workflow／02-mdm は参照箇所のみ確認。特に FIN の J11〜J16 の全テンプレート・INV の月結チェック SQL は全文未読。
6. **データ真正性**：90-data との照合はスポットチェック（標準 6 件・企業 4 件・顧客コード）。全 CSV の全行検証は data-researcher／finance-designer のレビュー範囲に委ねる。

---

## 6. 総評（実装可否判断）

**条件付可（Conditional Pass）**。

- **良い点**：在庫取引 19 種のコード体系・状態定義（10〜50）・移動平均の数値例・予約の状態/イベント対応・ロック順序/負在庫防止・BOM 多階展開/低層コード・MRP のバケット計算・工单分割/合并/結案・品質の所管（IQC は PRD）・承認マトリクスの 08 追補整合は、いずれも設計として成立しており、計算例も再現できた。実データ標準の引用も出典と一致し、創作は検出されなかった。
- **致命的（S1）**：なし。ただし **S2 の 8 件**（E24/J16 金額欠落、E15 検査→在庫状態変換、E35 未購読、原価層 vs 移動平均の金額保存則、MRP 可用量算式、WO 状態機 08 不整合、取消イベント未定義、行金額再評価の欠落）は、そのまま実装すると **在庫金額・売上原価・財務諸表・引当/出荷** に直接影響するため、**実装着手前に設計修正が必須**。
- **最重要 3 件**：
  1. **REV-SAL-001（E24/J16）**：完工原価の総額フィールドが送出されず、J16 の金額が解決できない。E24 payload への `costAmount`/`unitCost` 追加と、INV/FIN の購読項目の同時修正が必要。
  2. **REV-SAL-002（E15）**：検査結果の enum・数値コード・在庫状態変換の対応が三者不一致。E15 に在庫行特定情報と変換先状態を追加しないと、IQC/FQC の在庫状態変換が実装不能。
  3. **REV-SAL-003（E35）**：受入取消が INV/PRD に未購読。取消後も待検在庫・IQC タスク・仕入暫估が残り、在庫・品質・財務が不整合。
- **推奨**：S2 を修正した第 2 ラウンドで、REV-SAL-004/005（原価層・MRP 可用量）と REV-SAL-006/007（状態機・取消イベント）の 4 件を重点再確認する。S3/S4 は実装開始までに順次解消可能。

---

## 7. 改訂履歴

| 版数 | 日付 | 変更内容 | 変更者 |
|---|---|---|---|
| v1.0 | 2026-10-20 | 初版：26 ファイル・約 16,800 行を対象に紅隊評審。指摘 19 件（S1 0／S2 8／S3 9／S4 2）、YE3-100L1-4 120 PCE の在庫→原価チェーン追跡、ファイル別カバレッジ、未検証範囲、総評（条件付可） | sales-designer |
