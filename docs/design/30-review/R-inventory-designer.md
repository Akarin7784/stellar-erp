# 红队评审报告：系统管理（01-system）＋生产管理（06-production）

| 項目 | 内容 |
|---|---|
| 文書名 | 对抗性评审报告：系统管理＋生产管理（红队レビュー報告書） |
| 文書番号 | DSN-REV-018 |
| 版数 | v1.0 |
| 実施日 | 2026-10-20 |
| レビュアー | inventory-designer（05-inventory 担当。独立性確保のため自域はレビュー対象外） |
| 対象域 | 01-system（13 ファイル）／06-production（13 ファイル） |
| 参照契約 | 00-common 01/03/04/08/09、90-data、05-inventory（参照側の契約確認のみ） |
| 状態 | 第 1 轮（指摘のみ。設計ファイルは未変更） |

---

## 1. レビュー範囲・方法

### 1.1 範囲

| 分類 | 対象 |
|---|---|
| 主対象 | `docs/design/01-system/` 13 ファイル、`docs/design/06-production/` 13 ファイル |
| 照合先 | 00-common の 01 共通項目／03 API／04 DB／08 業務規則／09 跨域流程、90-data（実データ）、05-inventory（契約の受け手側） |
| 重点 | ①SYS 基盤能力の他域充足性 ②SYS と 03/04 規範の矛盾 ③権限・データ範囲・監査・多端 ④PRD↔SYS 参照断点（ユーザ/工場/工作中心/カレンダ/採番/権限）⑤PRD 内部（BOM/MRP/工单/報工/品質状態・イベント）⑥漏れ |

### 1.2 方法

- **样本抽出＋契約照合**：26 ファイルを対象に、通読 8 ファイル・部分通読 18 ファイル（下記 4 章のカバレッジ表参照）。
- **機械照合**：メッセージ ID の使用/定義突合（SYS：使用 71 = 定義 71、PRD：使用 95 = 定義 95、重複 0）、イベント payload と 09 §3 の項目照合、採番プレフィックスと 08 §2.1 の照合。
- **反例探索**：正常系記述を前提にせず、「別文書の定義と両立しない入力・順序・コード」を探した。
- 指摘はすべて `ファイル:行` の証拠付き。推測に留まるものは明記。設計ファイルの変更・git commit は行っていない。

### 1.3 サンプリング実績（26 ファイル）

- **01-system（13）**：00-overview（通読）、01-auth-login（通読）、02-user-role-permission（部分通読）、03-org-position（部分参照）、04-menu-dict-param（部分参照）、05-audit-attachment-notify（部分通読）、06-import-export-numbering（部分通読）、07-scheduled-job-print-monitor（部分通読）、90-db-design（部分通読：38 表中 10 表の DDL 精査）、91-api-design（部分参照）、92-report-batch-design（部分参照）、93-messages（部分通読＋機械照合）、94-sample-data（部分参照）。
- **06-production（13）**：00-overview（通読）、01-bom-routing-workcenter（部分参照）、02-work-order（部分通読）、03-material-issue-reporting（部分通読）、04-outsourcing（部分参照）、05-mrp-planning（部分通読）、06-quality-management（部分通読）、07-dashboard-reports（部分参照）、90-db-design（部分参照：約 20 表の DDL/制約）、91-api-design（部分参照）、92-report-batch-design（部分参照）、93-messages（機械照合）、94-sample-data（未精査・5 章参照）。

---

## 2. 指摘一覧

> 重大度：S1 致命／S2 重大／S3 一般／S4 建議。**S1・S2 は実装前に必須修正**。

| 指摘 ID | 重大度 | 対象ファイル:行 | 指摘内容 | 証拠・根拠 | 修正提案 | 想定影響 |
|---|---|---|---|---|---|---|
| REV-001 | **S1** | `06-production/03-material-issue-reporting.md:49,187`、`06-production/90-db-design.md:1264,1495,1681,1761` | **在庫側伝票（MII/MIR/FGI/OSI/OSR）を PRD と INV が二重に所有し、同一プレフィックスで二重採番する。** PRD は `prd_material_issue`（`MII{YYMMDD}{4桁}`、`sys_sequence(PRD_MATERIAL_ISSUE)` 採番）、`prd_completion_receipt`（`FGI…`）、`prd_outsourcing_issue/receipt`（`OSI…/OSR…`）を自域の伝票として状態機械・採番・帳票まで定義する。一方 INV は「GRI/SDO/MII/MIR/FGI/OSI/OSR は本域が採番・保持する在庫側伝票（`inv_stock_txn.txn_no`）」と定義（Lead 裁決 2026-10-20 で在庫側所有に統一）。両者が 08 §2.1 の同一プレフィックスを別テーブルで採番するため、**同一伝票番号が 2 レコードに付番され得る** | `06-production/03-…:49`（MII＝`prd_material_issue`、番号 `MII{YYMMDD}{4桁}`）／同 `:187`（`sys_sequence(PRD_MATERIAL_ISSUE)`）／`90-db:1264,1495,1681,1761`（issue_no/receipt_no を MII/FGI/OSI/OSR 形式で保持）／`00-common/08 §2.1`（MII/FGI/OSI の採番定義）／`05-inventory/02-inbound-outbound.md:35`（INV が採番・保持する在庫側伝票）／`05-inventory/92-report-batch-design.md:183`（INV 帳票 PRT-INV-001〜005 が GRI/SDO/MII/FGI/OSI を出力） | ①文書所有権を再確定：**INV が番号・伝票実体の所有者**、PRD は「製造指示／領料・入庫の**要求（指示）データ**」として E22/E24 を発行し、INV が採番した伝票番号を E18 で返すか、PRD の要求 ID（`issue_id`）を業務キーにする。②PRD の `issue_no/receipt_no` から MII/FGI/OSI/OSR プレフィックスを除去（または `REQ-` 系へ改名）。③両域の採番キーを分離し、08 §2.1 のプレフィックスは INV のみが消費 | 同一伝票番号の重複・帳票二重発行、状態機械の二重管理（PRD 側 30→40 と INV 側 30 の不一致）、監査証跡の断絶。実装後にデータ移行困難 |
| REV-002 | **S2** | `06-production/06-quality-management.md:60,62,241-262,267-269` | **E15 の判定値・payload が 09 §3 契約と両立しない。** ①09 は `result(PASS/CONCESSION/REJECT)` の 3 値だが、PRD は「10 合格/20 不合格/30 特采/40 返工/50 报废」の 5 値（数値）と定義し、同節で `result=CONCESSION`（英文）も併記。②payload 例は `lotNo`（INV 側は `batchNo`）、`sourceType` を数値 `10`、`inspectionType` を数値 `10` で送るが、値域の相互定義が 09 に無い。③`warehouseId` が無く、INV は状態変換対象の倉庫別残高行を特定できない。④購読側処理は `sourceType=10/30` の数値分岐のみで、`result=40/50` の在庫状態への写像が未定義 | `06-…:60`（判定結果 10〜50 の 5 値）／`:62`（`result=CONCESSION`）／`:241-262`（payload 例：`lotNo`、`sourceType:10`、`inspectionType:10`、`result:"PASS"`）／`:269`（INV は `sourceType=10/30` で分岐）／`00-common/09 §3 E15`（`result(PASS/CONCESSION/REJECT)`）／`05-inventory/04-batch-serial-status.md`（PASS→可用、REJECT→不合格の写像） | 09 §3 に E15 の**コード値表**（inspectionType/sourceType/result）を追加し、`result` は PASS/CONCESSION/REJECT に固定（返工・报废は NCR 側の処置区分で表現）。payload は `batchNo`・`warehouseId`・`inspectionQty` を明示。改修は 09 と PRD 双方 | INV/PUR の購読ハンドラが判定値を解釈できず、状態変換が実行不能または誤変換。検査と在庫の不整合（受入待検が永久に残る） |
| REV-003 | **S2** | `06-production/06-quality-management.md:33-36,227,237`／`06-production/00-overview.md:111-122,141,222` | **FQC（E15）と完成品入庫（E24）の順序・状態決定が矛盾。** PRD は「FQC は完成品入庫前」「FQC 起票は完工入庫登録（`prd_completion_receipt` 作成）時・入庫確定前」「判定確定で E15 発行」と定義するため、**E15 が E24 より先に到着し得る**。しかし E24 payload には検査結果・入庫状態が無く（09 §3 E24 は `workOrderId, completedQty, lines[...], completedAt`）、INV は FGI 過账時の在庫状態を「FQC 合格→可用／検査必須→待検→E15 で変換」と設計している（`05-inventory/02-…:191`）。E15 先行時は INV に残高行が無く変換不能、E24 先行時は結果不明で状態決定不能 | `06-…:35`（FQC＝完成品入庫前）／`:227`（FQC 起票＝完工入庫登録、同期＝入庫確定前）／`:237`（判定確定で E15 Outbox）／`00-…:141`（FQC→合格 E15→入庫）／`00-…:222`（E24 payload に検査結果なし）／`00-common/09 §8`（FQC は完成品入庫前）／`05-inventory/02-…:191`（FGI 状態ルール） | 方式を 1 つに固定：**(A) E24 が先**＝FGI は必ず `待検` で入庫し、E15 で可用化（PRD の FQC タイミングを「入庫後」に変更）／**(B) E15 が先**＝E24 に `inspectionResult`・`stockStatus` を追加し、INV は受信結果で直接入庫。いずれも 09 §3 の payload と PRD の時系列を同時修正 | 完成品が「待検のまま出荷不能」または「検査前に可用化」の事故。E15/E24 の再送・順序入替で在庫状態が不定 |
| REV-004 | **S2** | `06-production/05-mrp-planning.md:37,63,80,118` | **MRP の利用可能在庫式が INV の唯一算式・実在列と矛盾し、在庫テーブルを直接参照する。** ①`OH = Σ inv_stock_balance(on_hand_qty − inspection_qty − frozen_qty − quality_hold_qty)` と定義するが、INV の `inv_stock_balance` に `inspection_qty/frozen_qty/quality_hold_qty` 列は存在しない（INV は `stock_status` 別行の `qty_on_hand` と `qty_reserved` で保持）。②「引当済は控除しない」と明記するが、INV の可用量は `引当量を控除` する定義（00-overview §2.3）であり、MRP だけが引当を無視すると**净需求を過小/過大に計算**する。③I-04 では「INV 公開照会 API」と書きながら、CALC-MRP-01 は生テーブル集計であり、モジュール境界（09 §2.2/§11）に反する | `05-…:37`（OH＝現有−待検−凍結−品質保留、引当控除せず）／`:80`（`inv_stock_balance` の列名を直接指定）／`:118`（INV 公開 API から `on_hand/inspection/frozen/quality_hold` を取得）／`00-common/09 §2.2/§11`（同期参照は公開 Service）／`05-inventory/00-overview.md:123`（可用量の唯一算式：引当量を控除）／`05-inventory/90-db-design.md`（`inv_stock_balance` の列定義） | INV の `StockAvailabilityService`（`/api/inventory/stock-balances/available`）を唯一の取得経路とし、MRP の OH は「INV 可用量＋品質保留（INV の不合格/報廃待処理として表現）」に統一。引当控除の有無はパラメータ化せず INV 定義に従う | 過剰発注（在庫の二重計上）または欠品（引当済在庫の再発注）。「在庫を見た MRP」と「引当を見た受注」で数字が食い違い、計画の信頼性喪失 |
| REV-005 | **S2** | `01-system/02-user-role-permission.md:50`／`01-system/90-db-design.md:384,485`／`06-production/00-overview.md:408,414,421,427,444,448` | **SYS のデータ範囲モデルに「工場」「倉庫」次元が無く、PRD が前提とする行レベル制御が実現できない。** SYS はデータ範囲を 5 区分（全社/本部门及子部门/本部门/本人/自定义）とし、`custom_rule` の例も `{"departmentIds":[],"userIds":[]}` のみ。一方 PRD の権限一覧は `production:work-order:view`＝「自己所属工厂」、`production:material-issue:view/create`＝「所属工厂・所属仓库」、`production:completion:create`＝「所属仓库」など**工場/倉庫スコープを前提**とする。SYS の DataPermissionInterceptor は部門/本人しか注入できず、PRD/INV のような拠点・倉庫データは「全社参照可」か「独自フィルタ実装」の二択になる | `01-system/02-…:50`（BR-07：5 区分）／`90-db:384`（`data_scope_type` 1〜5）／`90-db:485`（`custom_rule` 例は departmentIds/userIds のみ）／`06-production/00-overview.md:414,421,427,444`（所属工厂/所属仓库）／`01-system/03-org-position.md:118`（`sys_department.factory_id` はあるが範囲次元ではない）／`00-common/01 §4`（データ範囲「全社/事業部/部門/本人/カスタム」） | データ範囲区分に **`factory` / `warehouse`（複数選択）** を追加し、`sys_role_data_scope.custom_rule` に `factoryIds`/`warehouseIds` を定義。各域は「自域のデータ範囲コード」を宣言するのみとし、フィルタ実装は SYS の共通インターセプタに一元化 | 倉管員が他倉庫の在庫・伝票を閲覧/更新できる（越権）、または各域が独自フィルタを実装してポリシーが分散・不統一。SoD と監査の前提が崩れる |
| REV-006 | **S2** | `01-system/05-audit-attachment-notify.md:228` | **監査ログが設計上「欠落し得る」。** 非同期キュー（容量 10,000）満杯時は同期 INSERT にフォールバックするが「タイムアウト 1 秒で諦めてアプリログに退避する」と定義。監査ログは追記専用・全操作記録が前提（`01-system/00-overview.md:43` の監査カバレッジ 100%、`00-common/01 §12` の記録対象＝全マスタ・伝票の登録/更新/削除、承認、過账/取消）であり、**キュー飽和・DB 遅延時に重要操作（POST/REVERSE/APPROVE/CLOSE）の監査証跡が消える**設計は内部統制・監査対応上許容できない | `01-system/05-…:228`（キュー満杯時は同期 INSERT、1 秒タイムアウトでアプリログ退避）／`01-system/00-overview.md:43`（監査覆盖率 100% KPI）／`00-common/01 §12`（監査ログの記録対象・追記専用）／`00-common/08 §12`（操作ログ保存 3 年） | ①重要操作（POST/REVERSE/APPROVE/CLOSE/DELETE 等）は**同一トランザクションで同期 INSERT**（業務と監査の原子性確保）、②参照系のみ非同期、③キュー飽和時は**業務をブロックしてエラー**（監査なしの業務完了を許さない）、④`sys_audit_log` の INSERT 失敗をアラート | 監査証跡の欠落＝内部統制・監査・訴訟対応の根拠喪失。過账・取消の追跡不能は会計監査で致命的 |
| REV-007 | **S2** | `06-production/06-quality-management.md:67`／`06-production/00-overview.md:387`／`06-production/90-db-design.md`（`prd_wo_lot`）／`05-inventory/04-batch-serial-status.md:60` | **批次追溯の主データが PRD と INV で二重管理。** PRD は `prd_wo_lot`（投入批次→製造指図→完成品批次→出荷先）を F-PRD-015 の中核として定義し、5 年保存・正逆追溯を謳う。INV も `inv_batch_genealogy`（父批次→子批次）＋`inv_stock_txn_line` を追溯の中核と定義。09 §8 は「受入ロット→製造指図→完成品ロット→出荷先をリンク」とだけ書き**所有者を定義していない**ため、両域が別データで同じ追溯を提供し、片側だけ欠損（委外・返工・部分入庫等）した場合に追溯結果が一致しない | `06-…:67`（BR-QC-11：`prd_wo_lot` をリンク）／`00-…:387`（`prd_wo_lot`：投入→産出→工序→設備）／`05-inventory/04-…:60`（BR-BT-06：`inv_batch_genealogy`）／`00-common/09 §8`（ロットトレーサビリティのリンク定義のみ） | 09 §8 に「**批次系譜の主データは INV（`inv_batch_genealogy`）**、PRD は製造事実（工単・工序・設備）を保持し、追溯表示時に INV の系譜＋自域の製造実績を結合する」と責任分界を明記。PRD の `prd_wo_lot` は製造側の関連（工単-設備）に限定するか廃止 | 顧客クレーム・リコール時の追溯で「PRD では辿れるが INV では辿れない（逆も）」が発生。回収範囲の判断ミス（法令・品質リスク） |
| REV-008 | **S2** | `06-production/00-overview.md:157-158`／`06-production/90-db-design.md:1027` | **工单状態 `45 結案` が共通ステータス契約に反する。** 01-common §7.1 は `40 完了/クローズ` を「全数量完了。以後の変更は取消・返品処理のみ（終端）」と定義し、08 §3.2 も「生产订单 WO：10→25→30→35→40／90、40 完了・結案」とする。PRD は `40 完工` の後に `45 結案` を追加し、DDL の CHECK にも 45 を許可。共通契約では 40 が終端であり、45 は「40 からの再開」に相当する | `06-production/00-overview.md:157-158`（40 完工／45 結案）／`90-db:1027`（`order_status IN (10,20,25,30,35,40,45,90,95)`）／`00-common/01 §7.1`（40＝終端）／`00-common/08 §3.2`（WO 40 完了・結案） | ①08 §3.2 に WO の `45 結案` を正式追加（共通ステータスの拡張として 01-common §7.1 に「域拡張の許容範囲」を明記）するか、②45 を廃止し「40 完了＋`closed_at/closed_by` フラグ」で結案を表現。いずれも 08/01-common と PRD を同時更新 | 09 §10.3 月結チェック「工单完了・未入庫」や FIN の結案判定が「40 か 45 か」で実装ごとにぶれる。状態遷移の共通制約（40 からの再開禁止）違反 |
| REV-009 | **S3** | `01-system/06-import-export-numbering.md:129,180`／`01-system/94-sample-data.md:116`／`00-common/08-common-business-rules.md:58` | **採番ルールの prefix 検証が「大文字英数 1〜10」であり、凭证番号の中文凭证字（`记-0001` 等）を登録・検証できない。** 08 §2.1 は记账凭证を「凭证字＋4 桁（6 桁、`记-0001/收-0001/付-0001/转-0001`、会計期間×凭证字）」と定義。SYS の初期データには `VOUCHER`：prefix `记-`（94:116）が存在するが、画面/API の入力チェックは「大文字英数」で矛盾し、当該ルールは保存・編集不能 | `06-…:129`（prefix 入力チェック「大文字英数 1〜10」）／`:180`（CHK-SYS-012-02）／`94-…:116`（`VOUCHER` prefix `记-`）／`00-common/08 §2.1`（凭证字＋4 桁） | prefix の許容文字を「英数大文字＋中文（凭证字）＋ハイフン」に拡張（または `prefix_type` を追加し、`date_format`/`separator` を独立項目化）。FIN 凭证採番の要件を F-SYS-012 の受入条件に追加 | FIN が SYS 採番基盤で凭证番号を発行できず、独自採番（単一定義源違反）に追い込まれる。凭证番号の連番欠番・重複リスク |
| REV-010 | **S3** | `01-system/94-sample-data.md:107-116`／`00-common/08-common-business-rules.md:26-60` | **採番ルールの初期データが「代表例 6 件」のみで、08 §2.1 の全プレフィックス（約 30 件）の投入定義が無い。** SYS は「08 §2.1 のプレフィックス・桁数・リセット周期をそのまま初期データとする」と書きながら、表は SO/PO/WO/C/S/VOUCHER の 6 件のみ。`sys_number_rule` の件数見積は 60 件（00-overview:264）。GRI/SDO/MII/MIR/FGI/OSI/OSR/TR/CNT/CPI/AOI/AOO/IQC/NCR/GR/PRT/DN/SRT/RSV/CA/BST 等が未定義で、BAT-SYS-012（初期データ投入）では採番できない | `01-system/94-…:107-116`（代表例 6 件）／`00-common/08 §2.1`（30 行超のプレフィックス定義）／`01-system/00-overview.md:264`（`sys_number_rule` 60 件見積）／`01-system/00-overview.md:243`（BAT-SYS-012 が编号規則を初期登録） | 08 §2.1 の全行を `sys_number_rule` 初期データ（CSV/`R__seed`）として定義し、00-overview に「初期データは 08 §2.1 全件」と明記。各域の採番キー（`PRD_MATERIAL_ISSUE` 等）との対応表も用意 | 初期導入時に伝票番号が発行できず、各域が個別にシードを作る（定義分散・抜け）。実装フェーズで手戻り |
| REV-011 | **S3** | `06-production/02-work-order.md:273`／`06-production/03-material-issue-reporting.md:259,260` | **存在しない INV API を同期参照している。** PRD は `GET /api/inventory/available-quantities`（引当可能量照会）を呼ぶと定義するが、INV の API は `GET /api/inventory/stock-balances/available`（および批次別は `.../available-batches`）。`GET /api/inventory/batches?materialId&warehouseId` は INV に存在するが、FEFO 候補は `available-batches` が正 | `06-production/02-…:273`（`/api/inventory/available-quantities`）／`03-…:259`（同）／`:260`（`/api/inventory/batches`）／`05-inventory/91-api-design.md:43`（実際は `/stock-balances/available`）／`:44`（`available-batches`） | PRD の参照 API を INV の公開 API に修正し、**同期参照のインタフェース契約表**（INV 側 API ID/パス/レスポンス項目）を 09 §11 に追記。実装時は OpenAPI で結合検証 | 引当確認ボタン・FEFO 候補表示が 404 となり、受注/工単画面の在庫確認ができない。結合試験で発覚し手戻り |
| REV-012 | **S3** | `00-common/09-cross-domain-flow.md:96,110`／`06-production/00-overview.md:218-220`／`06-production/03-material-issue-reporting.md:75` | **E22/E36 の payload に `warehouseId` が無く、INV の出庫倉庫が一意に決まらない。** PRD は warehouse を「工单材料行の `warehouse_id`」で保持すると定義するが、E22（領料）/E36（退料）の payload は `workOrderId, issueId/returnId, lines[{materialId, qty, batchNo, unitCost}], issuedAt/returnedAt` のみ。INV は倉庫単位で残高を更新するため（`inv_stock_txn.warehouse_id` NOT NULL）、既定倉庫へ誤記帳するか PRD への逆照会が必要になる | `00-common/09 §3 E22`（payload に warehouseId なし）／`E36`（同）／`06-production/00-overview.md:219-220`（payload 一覧も同様）／`03-…:75`（倉庫は工单材料行に保持）／`05-inventory/02-inbound-outbound.md:174`（E22 受信で MII 生成） | E22/E36 に `lines[].warehouseId`（または `warehouseCode`）を追加（09 §2.3「項目追加は +0」に従い eventVersion 維持）。PRD は工单材料行の倉庫を明示的に送信 | 誤倉庫への在庫計上（棚卸差異・倉庫間在庫の不整合）。引当倉庫と出庫倉庫の不一致 |
| REV-013 | **S3** | `06-production/00-overview.md:37,80-81`／`00-common/08-common-business-rules.md:280-285` | **承認マトリクスの帰属・独自閾値が 08 と不整合。** ①PRD は前提で「SYS ユーザ・ロール・**审批矩阵**」と書くが、承認マトリクスは WF 所有（`wf_approval_matrix`、SYS 00-overview 未決 #1 で已裁决）。②委外订单の承認を「加工費 50,000 元以上：采购经理→生产经理→财务经理」と独自定義するが、08 §8.1 に委外承認の行は無く、金額・経路が未契約。③报废 5,000 元以上の承認経路も 08 §8.1 に無い | `06-production/00-overview.md:37`（SYS に审批矩阵）／`:80-81`（报废 5,000 元・委外 50,000 元）／`00-common/08 §8.1:280-285`（追加 4 類に委外・报废は無い）／`01-system/00-overview.md:87,359`（承認マトリクスは WF 所有・SYS は保存しない） | 承認閾値・経路はすべて 08 §8.1（WF 所有）に集約し、PRD は `wf_approval_matrix` を参照するのみとする。委外・报废の経路を 08 に追加する場合は Lead 承認のうえ全 docs を同期 | 承認経路の二重定義（PRD と WF）、承認なしの高額委外・报废の実行リスク。監査時に「どの規程が正か」不明 |
| REV-014 | **S3** | `06-production/00-overview.md:37`／`06-production/01-bom-routing-workcenter.md:87,727`／`06-production/90-db-design.md:450-451` | **工费率の所有権が未確定で、存在しない `fin_labor_rate` を参照する。** PRD は前提で「工费率（`prd_work_center`（PRD 所有）の费率 または `fin_labor_rate`）」と両論併記し、`prd_work_center` に `labor_rate_per_hour/overhead_rate_per_hour` を保持。しかし 07-finance に `fin_labor_rate` は存在せず（grep 0 件）、PRD 自身も 01 章未決 #3 で「FIN の配賦方針と整合が必要」と留保。J13（直接人工費）・J15（製造費用配賦）の金額根拠の責任分界が未確定 | `06-production/00-overview.md:37`（PRD 费率 or `fin_labor_rate`）／`01-bom:87`（年次見直し・実績時点保持）／`01-bom:727`（未決 #3：FIN と整合必要）／`90-db:450-451`（PRD 側に率を保持）／`07-finance`（`fin_labor_rate` 定義なし） | レートの所有者を 1 つに確定（推奨：**FIN が原価レートの所有者**、PRD は参照。または PRD 所有を FIN が承認）。09 §7.2 J13/J15 の金額根拠に「レートの取得元」を明記 | 人工費・製造費用の二重計算または未計上。工单原価と財務原価の不一致、月結時の差異原因不明 |
| REV-015 | **S3** | `06-production/06-quality-management.md:112,167`／`06-production/90-db-design.md:2072` | **検査状態コードの意味が PRD 内部で矛盾。** 06 §3.3 の検査単は「10 草稿／30 検査中／40 判定確定／90 取消」だが、同文書の遷移表は「20→30 判定確定」とし、90-db の CHECK は `inspection_status IN (10,20,30,90)` で 40 を許可しない。実装時に 30=判定確定 か 30=検査中 か、40 の有無が確定できない | `06-…:167`（10/30/40/90）／`:112`（検査 20→30 判定確定）／`90-db:2072`（CHECK 10/20/30/90） | 状態表・遷移表・DDL CHECK を同一値域に統一（例：10 草稿/20 検査中/30 判定確定/90 取消）し、06 §3.3 と 90-db を同時修正 | 検査記録の状態判定が実装者ごとにぶれ、E15 発行条件・再検査制御が誤動作 |
| REV-016 | **S3** | `06-production/03-material-issue-reporting.md:76,275,295` | **倒冲（後方払出）が PRD 側で在庫不足判定と MII 生成を二重実装する。** PRD は報工確定時に「BOM 標準量×良品数で MII を自動生成（不足時は警告のみ、マイナス在庫禁止）」とし、PRC では「材料行ロック（`material_id` 昇順）」で処理する。しかし在庫不足の最終判定・残高更新は INV（E22 受信時）が行う。PRD 側の「マイナス在庫禁止」は INV の `MSG-INV-001` と二重判定になり、ロック対象も PRD の材料行で INV の残高行ではないため同時実行で在庫が競合し得る | `06-production/03-…:76`（不足時警告のみ、マイナス在庫禁止）／`:275`（報工承認で倒冲実行）／`:295`（PRC：材料行ロック）／`00-common/09 §2.2`（在庫更新は INV の責任）／`05-inventory/02-inbound-outbound.md:411`（CHK-INV-002-12：出庫時 可用量 ≥ 数量、過账時 `MSG-INV-001`） | 倒冲は「PRD が E22 を発行し、INV が在庫検証・出庫」に一本化。PRD 側の在庫可用チェックは INV の照会 API による**事前警告のみ**（最終判定は INV）。ロックは INV の残高行ロックに委ねる | 同时在庫操作で引当/出庫の競合、負在庫（両域の判定タイミング差）、倒冲失敗時の報工確定との整合 |
| REV-017 | **S3** | `01-system/07-scheduled-job-print-monitor.md:103-105` | **SYS のジョブ監視画面サンプルが他域バッチ ID を誤記。** 画面例は `BAT-INV-002 库存月结` とするが、INV の定義は `BAT-INV-001 库存月结`／`BAT-INV-002 库存日次对账`。また Cron 表記が 5 桁（`*/10 * * * *`）と 6 桁（`0 30 2 1 * *`）が混在（Spring は 6 桁前提） | `01-system/07-…:105`（BAT-INV-002＝库存月结）／`:103-104`（5 桁/6 桁 cron 混在）／`05-inventory/92-report-batch-design.md:183-184`（BAT-INV-001 月结／BAT-INV-002 日次対账） | サンプルを正しい ID・名称に修正し、Cron は 6 桁（秒 分 時 日 月 週）に統一。他域バッチの登録は 08/各域 92 の定義を正として連携 | 運用画面で誤ったジョブを手動実行するリスク、スケジュール誤解釈 |
| REV-018 | **S4** | `01-system/00-overview.md:337`／`01-system/02-user-role-permission.md:50` | **SYS 内部でデータ範囲の区分が 3 区分 vs 5 区分で不一致。** 00-overview の権限注記は「データ範囲（全社/部門/本人）は `sys_role_data_scope`」、02 は「全社/本部门及子部门/本部门/本人/自定义」の 5 区分。どちらが正か読者に不明 | `01-system/00-overview.md:337`（3 区分）／`02-…:50`（5 区分）／`90-db:384`（1〜5） | 00-overview の注記を 5 区分に修正（REV-005 の次元追加時はその内容も反映） | 実装・設定時の区分解釈のぶれ。権限設計レビューの手戻り |

---

## 3. 検証して問題なかった項目（カバレッジ証跡）

| # | 検証項目 | 結果 | 証跡 |
|---|---|---|---|
| 1 | Outbox テーブル・配信仕様（状態値・リトライ・デッドレター・10 秒間隔） | 09 §10.1 と整合 | `01-system/90-db-design.md:1355-1381`（status 0/1/2/9、指数バックオフ・最大 10 回）／`00-common/09 §10.1` |
| 2 | 添付の上限（20MB／20 件／100MB／許可形式） | 01-common §9 と一致 | `01-system/05-audit-attachment-notify.md:47,193-196`／`00-common/01 §9` |
| 3 | インポート上限（10,000 行/回）・エクスポート同期上限 | 08 §13.2・03 §12 と一致 | `01-system/06-import-export-numbering.md:51,53,144,186,338` |
| 4 | セッション（8 時間）/無操作 30 分/残 5 分警告 | 02 画面共通規格 §15 と一致 | `01-system/01-auth-login.md:54`／`00-common/02 §15` |
| 5 | 監査ログの項目（trace_id/user/operation_type/module/resource/before/after/IP/UA/result/error/occurred_at） | 01-common §12 と一致（欠落リスクは REV-006） | `01-system/90-db-design.md:765-783`／`00-common/01 §12` |
| 6 | 冪等（`Idempotency-Key`、`sys_idempotency` 項目、処理中 409） | 03 §9 と一致 | `01-system/90-db-design.md:1427-1437`／`01-system/91-api-design.md:18,193` |
| 7 | 工厂主データの所有（MDM `mdm_factory`、SYS は有効化・既定割当のみ） | Lead v1.2 修正済で整合 | `01-system/00-overview.md:56,169,250,376`／`01-system/03-org-position.md:51,139`／`00-common/01 §4` |
| 8 | 権限コード形式（`{module}:{resource}:{action}`）とメニュー登録 | 00-common 00 §6.6 と一致（action 語彙の揺れは残るが重大度低） | `01-system/04-menu-dict-param.md:44,121`／`00-common/00 §6.6` |
| 9 | メッセージ ID の網羅性 | SYS 使用 71 = 定義 71、PRD 使用 95 = 定義 95、重複 0（機械照合） | `01-system/93-messages.md`／`06-production/93-messages.md` |
| 10 | E21/E22/E23/E24/E25/E26 のフィールド名 | 09 §3 と一致（warehouse 欠落は REV-012、E15 は REV-002/003） | `06-production/00-overview.md:218-224`／`00-common/09 §3:95-100,110` |
| 11 | PRD が在庫を直接更新しない方針（更新責任の一元化） | 明記あり（伝票所有の二重は REV-001） | `06-production/04-outsourcing.md:260`／`06-production/00-overview.md:486,492` |
| 12 | BOM 展開・損耗率・低層码・MRP 净需求/批量規則の基本記述 | 08 §6／09 §6 と整合する記述を確認（在庫取得式は REV-004） | `06-production/01-bom-routing-workcenter.md:86-107,376-393`／`05-mrp-planning.md:60-90` |
| 13 | 採番の行ロック・欠番許容・ロールバック・桁溢れ | 08 §2.1／04 §5 と整合 | `01-system/06-import-export-numbering.md:36,45,213-215` |
| 14 | パスワード履歴 5 代・失敗ロック・多端失効・初回改密 | 08 §9／02 と矛盾なし | `01-system/01-auth-login.md:45-54,259-287` |

---

## 4. 未検証範囲・制約

| # | 未検証範囲 | 理由 |
|---|---|---|
| 1 | `01-system/90-db-design.md` の全 38 テーブル DDL | 96KB。10 表（sys_sequence/sys_audit_log/sys_outbox_event/sys_idempotency/sys_role_data_scope/sys_scheduled_job 等）を精査、残りは未精査 |
| 2 | `06-production/90-db-design.md` の全テーブル（約 50 表・191KB） | 約 20 表（work_order/work_center/material_issue/completion/outsourcing/inspection/wo_lot）の DDL・制約のみ精査 |
| 3 | PRD 91 API 全件・92 帳票/バッチ全件 | 部分参照（91:336、92:142-147 等） |
| 4 | PRD 94 サンプルデータの数値検算（BOM 用量・工数・原価） | 未精査（BOM 数量は 90-data/bom-demo.md と一致する範囲のみ確認） |
| 5 | 非機能（性能値・同時実行・可用性）の妥当性 | 設計値の検算は未実施 |
| 6 | 20-matrix／追跡マトリクス | 未生成のため ID 追跡の網羅検証は不可 |
| 7 | 実装技術制約（Spring Modulith の公開境界、Sa-Token のマルチ端末実装） | 実装フェーズで検証が必要 |

> 本レビューは「設計記述間の反例探索」に限定され、実装・実データ検証ではない。指摘の一部（REV-001 の伝票所有権、REV-002/003 の E15/E24 契約）は、**Lead の最終裁定が必要**な跨域契約事項である。

---

## 5. 総評（実装可否判断）

**判定：条件付可（Conditional Go）**

- **SYS 基盤は全体として堅牢**：認証・セッション・採番の原子性、Outbox 配信、冪等、監査項目、添付・インポート上限、工場主データ所有は 00-common/03/04/08/09 と整合し、他域が利用するに足る。メッセージ定義も 71/71 で欠落なし。
- **ただし 2 点は全社基盤の質を左右する**：①データ範囲に工場/倉庫次元が無い（REV-005、PRD/INV の行レベル統制が実現不能）、②監査ログが設計上欠落し得る（REV-006、監査 100% と矛盾）。この 2 件は SYS 側で先行修正すべき。
- **PRD は業務記述・算法記述が充実**している一方、**在庫・伝票境界に致命〜重大の不整合**が集中する：伝票の二重所有・二重採番（REV-001、S1）、E15/E24 の判定・順序契約（REV-002/003）、MRP の在庫取得式（REV-004）、批次追溯の二重管理（REV-007）、工单状態の共通契約違反（REV-008）。いずれも「実装後に直すとデータ移行が必要」な性質のため、**実装着手前（設計レビュー第 2 轮まで）に修正必須**。
- S3 15 件のうち REV-009〜REV-017 は局所的だが、採番・承認・工费率・API パスは実装初日に影響するため、同様に実装前修正を推奨。
- **推奨対応順**：①Lead 裁定（REV-001/002/003/005/007/008 の跨域契約）→ ②09/08/01-common の契約補正 → ③SYS/PRD 本文修正 → ④20-matrix で追跡検証。

---

## 6. 改訂履歴

| 版数 | 日付 | 変更内容 | 変更者 |
|---|---|---|---|
| v1.0 | 2026-10-20 | 初版：01-system（13）＋06-production（13）の红队レビュー。26 ファイル抽出、指摘 18 件（S1×1／S2×7／S3×9／S4×1）、カバレッジ 14 項目、未検証範囲 7 項目、判定「条件付可」 | inventory-designer |
