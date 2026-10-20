# 制造・物流连携 详细设计书（製造・物流連携 詳細設計書）

| 項目 | 内容 |
|---|---|
| 文書名 | 制造・物流连携 详细设计书（製造・物流連携 詳細設計書） |
| 文書番号 | DSN-INT-003 |
| 版数 | v1.0 |
| 作成日 | 2026-10-20 |
| 作成者 | integration-designer（集成分野担当） |
| 承認者 | 未承認（レビュー待ち） |
| 状態 | ドラフト（レビュー中） |
| 関連文書 | [業務域概要](00-overview.md) / [接口配置](01-integration-config.md) / [税銀 IF](02-tax-bank-interface.md) / [DB 設計](90-db-design.md) / [跨域流程](../00-common/09-cross-domain-flow.md) / [生产概要](../06-production/00-overview.md) / [库存概要](../05-inventory/00-overview.md) |

---

## 1. 機能概要

| 項目 | 内容 |
|---|---|
| 機能 ID | F-INT-006（MES）、F-INT-007（WMS・P2）、F-INT-008（PLM）、F-INT-010（条码/PDA）、F-INT-017（物流・P2）、F-INT-020（IoT・P2） |
| 機能名 | MES／WMS／PLM／条码連携 |
| 目的 | ① 製造指図を MES へ送信し、報工・領料・完工の実績を受信して PRD/INV へ反映する；② PLM の設計変更（物料・BOM・工艺）を差分取込し、承認を経て主データへ反映する；③ PDA の現場スキャンを在庫・報工の実績として取り込む；④ WMS（Phase 2）と入出庫・在庫を同期する |
| 利用者・ロール | 生産計画員、製造現場（間接）、技術部（BOM/工艺）、倉管員、MDM 管理者、接口管理员、运维担当 |
| 利用シーン | 工单下达、工序完了報告、生产领料、完工入库、PDA 出入庫/移庫/報工、PLM 設計変更 |
| 優先度 | MES＝P1、PLM＝P1、PDA＝P1、WMS＝P2、物流＝P2、IoT＝P2 |
| 画面 ID | SCR-INT-016、SCR-INT-017、SCR-INT-023 |
| 関連 IF | IF-INT-003、004、005、010、013、016 |

### 1.1 連携の基本方針

1. **ERP が正、MES は実行**：工单・BOM・工艺・必要量は ERP（PRD）が正。MES は実行記録（谁が・いつ・どの設備で・何個）の発生源であり、ERP はそれを受信して `prd_work_report` 等へ反映する。
2. **指示と実績を分離**：ERP → MES は「指示」、MES → ERP は「実績」。指示の再送で実績を上書きしない。
3. **冪等キー**：工单下发は `workOrderNo + workOrderVersion`、報工は `reportNo`（MES 採番）、PDA は `deviceCode + batchNo + seqNo`。
4. **部分成功を許さない（1 メッセージ単位）**：1 報工メッセージ内の明細は全件成功 or 全件失敗。ただしバッチ全体では部分成功を許容し、失敗分を再送する。
5. **PLM は自動確定しない**：取込んだ BOM・工艺は「承認待ち」として登録し、MDM/PRD の承認後に有効化する（[08 §11](../00-common/08-common-business-rules.md)）。
6. **オフライン前提**：PDA は電波の届かない場所（倉庫奥・鋳造現場）を想定し、オフライン補伝を必須機能とする。

---

## 2. 業務要件・業務ルール

### 2.1 前提条件

| # | 前提条件 | 成立しない場合 |
|---|---|---|
| 1 | 工单が承認済（`order_status=25`）で、BOM/工艺が有効 | 下发不可（`MSG-INT-060`） |
| 2 | 工单の材料引当が完了（E21 発行済） | 引当不足のまま下发（警告、設定による） |
| 3 | MES 側に該当品目・工程・工作中心が登録済み | マスタ不整合（`MSG-INT-064`） |
| 4 | PLM の BOM/工艺に版数・適用日がある | 取込不可（`MSG-INT-065`） |
| 5 | PDA 端末が有効（`status=10`）で、利用者が認証済み | スキャン不可（`MSG-INT-066`） |

### 2.2 業務ルール

| # | ルール | 根拠 | 関連項目 |
|---|---|---|---|
| BR-MES-01 | 工单下发は `workOrderNo + workOrderVersion` を冪等キーとする。同一版の再送は MES 側で上書き（指示の訂正）とし、ERP は結果のみ記録する | 本設計 | `idempotency_key` |
| BR-MES-02 | 工单の変更（数量・納期・BOM）は版数を +1 して再下发する。旧版の実績は保持する | 本設計 | `version_no` |
| BR-MES-03 | 報工の受理条件：工单が `30/35`、工序が有効、`goodQty + defectQty + scrapQty ≤ inputQty`、累計が `order_qty × (1 + over_report_rate)` 以内 | 本設計、`prd_work_order.over_report_rate` | `reported_*_qty` |
| BR-MES-04 | 報工の重複は `reportNo` で排除する。同一 `reportNo` の再受信は ACK のみ返し、再登録しない | 本設計 | `report_no` |
| BR-MES-05 | 報工確定時に `production.report.confirmed`（E23）を発行する。在庫・会計は E23 を購読して処理する（INT は在庫を更新しない） | [09 §3 E23](../00-common/09-cross-domain-flow.md) | E23 |
| BR-MES-06 | 完工実績（`completedQty`）は `prd_completion_receipt` の登録後に `prd_work_order.completed_qty` へ反映する。二重計上を防ぐため `completionNo` を冪等キーとする | 本設計 | `completed_qty` |
| BR-MES-07 | 設備停止・品質異常は `defectCode` と `defectQty` を必須とし、`prd_ncr` 起票の候補とする | [06 §3](../00-common/09-cross-domain-flow.md) | `defect_qty` |
| BR-PLM-01 | PLM 取込は「品目 → BOM → 工艺」の順。品目が未登録の場合は取込を保留し、エラー一覧に残す | 本設計 | `int_file_transfer_error` |
| BR-PLM-02 | BOM の版数は `BOM-{父物料编码}-V{2桁}`（[08 §2.2](../00-common/08-common-business-rules.md)）。同一版の重複登録は不可 | 本設計 | `bom_no` |
| BR-PLM-03 | ECN（設計変更）は適用日以降の工单に適用する。既存工单は変更申請（F-PRD-005）で対応する | [09 §6.3](../00-common/09-cross-domain-flow.md) | `effective_from` |
| BR-PLM-04 | 取込んだ BOM/工艺は「承認待ち」とし、技術部の承認後に有効化する。自動で本番 BOM を置換しない | [08 §11](../00-common/08-common-business-rules.md) | `approval_status` |
| BR-PDA-01 | スキャンは「端末認証 → 利用者認証 → 業務検証（物料・倉庫・批次・数量）」の順。1 つでも失敗したら処理しない | 本設計 | `inv_scan_log`（INV） |
| BR-PDA-02 | オフライン補伝は `batchNo` 単位で受け付け、`seqNo` の欠番・重複を検査する。重複はスキップ（成功扱い） | 本設計 | `dup_count` |
| BR-PDA-03 | 補伝の有効期限は 7 日（`sys_param.pda_offline_expire_days`）。超過は拒否し、現場で再スキャン | 本設計 | — |
| BR-PDA-04 | バーコードは Code 128（GB/T 18347-2001）を既定、QR コード（GB/T 18284-2000）を併用する。EAN-13 は Phase 2（GB/T 12904 は現行版【要確認】） | 【実データ】S-046、S-048、【要確認】S-047 | `barcode_type` |
| BR-WMS-01 | WMS 連携（P2）は「入出庫指示」と「実績」を分離し、在庫の確定更新は ERP（INV）が行う | 本設計 | E18 |
| BR-WMS-02 | WMS の在庫差異は日次照合で検出し、ERP の在庫を自動調整しない（差異は INV の棚卸で処理） | 本設計 | `int_sync_reconcile` |

### 2.3 MES インタフェース項目定義（IF-INT-003）

**A. 工单下发（ERP → MES）**

| No | 項目 | 型/桁 | 必須 | 説明 | 対応先（MES） | 備考 |
|---|---|---|---|---|---|---|
| 1 | `workOrderNo` | VARCHAR(32) | ○ | 工单号（WO+YYMMDD+4 桁） | work_order_no | 冪等キー |
| 2 | `workOrderVersion` | INT | ○ | 工单版数 | version | 変更で +1 |
| 3 | `materialCode` | VARCHAR(64) | ○ | 製造品コード | product_code | — |
| 4 | `materialName` | VARCHAR(200) | ○ | 品名 | product_name | スナップショット |
| 5 | `spec` | VARCHAR(200) | △ | 仕様 | spec | — |
| 6 | `uomCode` | VARCHAR(16) | ○ | 単位 | uom | PCE 等 |
| 7 | `orderQty` | DECIMAL(18,4) | ○ | 注文数量 | plan_qty | > 0 |
| 8 | `factoryCode` | VARCHAR(16) | ○ | 工厂（CZ01/WX01） | plant_code | — |
| 9 | `plannedStartDate` | DATE | ○ | 计划着手日 | planned_start | `yyyy-MM-dd` |
| 10 | `plannedEndDate` | DATE | ○ | 计划完成日 | planned_end | 着手 ≤ 完成 |
| 11 | `priorityNo` | INT | △ | 优先度 1〜9 | priority | — |
| 12 | `bomNo` | VARCHAR(40) | △ | 適用 BOM 番号 | bom_no | スナップショット |
| 13 | `routingNo` | VARCHAR(40) | △ | 適用工艺番号 | routing_no | — |
| 14 | `materials[]` | ARRAY | △ | 必要材料（`materialCode`、`requiredQty`、`uom`、`warehouseCode`） | materials | BOM 展開結果 |
| 15 | `operations[]` | ARRAY | ○ | 工序（`seq`、`operationCode`、`workCenterCode`、`standardHours`） | operations | 工艺展開 |
| 16 | `salesOrderNo` | VARCHAR(32) | △ | 受注番号（MTO） | sales_order_no | — |
| 17 | `remark` | VARCHAR(500) | △ | 備考 | remark | — |

**B. 報工回伝（MES → ERP）**

| No | 項目 | 型/桁 | 必須 | 説明 | ERP 項目 | 備考 |
|---|---|---|---|---|---|---|
| 1 | `reportNo` | VARCHAR(32) | ○ | 報工番号（MES 採番） | `prd_work_report.report_no` | 冪等キー |
| 2 | `workOrderNo` | VARCHAR(32) | ○ | 工单号 | `work_order_no` | 存在チェック |
| 3 | `operationSeq` | INT | ○ | 工序序号 | `operation_seq` | 工单に存在 |
| 4 | `reportDate` | DATE | ○ | 報工日 | `report_date` | 未来日不可 |
| 5 | `shiftCode` | VARCHAR(16) | △ | 班次 | `shift_code` | A/B/C |
| 6 | `inputQty` | DECIMAL(18,4) | ○ | 投入数量 | `input_qty` | ≥ 良品+不良+廃棄 |
| 7 | `goodQty` | DECIMAL(18,4) | ○ | 良品数 | `reported_good_qty` | ≥ 0 |
| 8 | `defectQty` | DECIMAL(18,4) | ○ | 不良数 | `defect_qty` | ≥ 0 |
| 9 | `scrapQty` | DECIMAL(18,4) | ○ | 廃棄数 | `scrap_qty` | ≥ 0 |
| 10 | `laborHours` | DECIMAL(12,2) | ○ | 工数（h） | `labor_hours` | ≥ 0 |
| 11 | `machineHours` | DECIMAL(12,2) | △ | 設備工数 | `machine_hours` | — |
| 12 | `operatorCode` | VARCHAR(64) | △ | 作業者コード | `report_user_id`（変換） | 個人情報最小化 |
| 13 | `defects[]` | ARRAY | △ | 不良明細（`defectCode`、`qty`、`causeCode`） | `prd_work_report_defect` | 不良時必須 |
| 14 | `reportedAt` | TIMESTAMP | ○ | 実績発生時刻 | `confirmed_at` | ISO 8601 |
| 15 | `traceId` | VARCHAR(64) | △ | 相関 ID | `correlation_id` | ログ追跡 |

**C. ステータス**

| ERP 側 | MES 側 | 同期方向 | 契機 |
|---|---|---|---|
| `30 下达済` | `RELEASED` | ERP→MES | 下发成功 |
| `35 製造中` | `IN_PROGRESS` | MES→ERP | 初回報工 |
| `40 完工` | `COMPLETED` | MES→ERP | 完工実績 |
| `90 取消` | `CANCELLED` | ERP→MES | 工单取消 |

### 2.4 PLM 同期の対象

| 対象 | 取込内容 | 反映先 | 承認 |
|---|---|---|---|
| 物料 | 品目コード、名称、仕様、単位、材質、標準 | `mdm_material`（新規/変更申請） | MDM 承認 |
| BOM | 親子、構成数量、損耗率、代替品、版数、適用日 | `prd_bom` / `prd_bom_line` | 技術部承認 |
| 工艺 | 工序順、工作中心、標準工時、検査項目 | `prd_routing` / `prd_routing_operation` | 技術部承認 |
| ECN | 変更番号、対象品目、変更内容、適用日、理由 | 変更申請（`prd_work_order_change` 等） | 技術部承認 |

---

## 3. 関連機能

| 関係 | 機能 ID | 機能名 | 関係内容 |
|---|---|---|---|
| 上流 | F-PRD-005 | 生产订单 | 工单下发のトリガ（E21） |
| 上流 | F-PRD-007 | 报工 | 報工受信後の確定 |
| 上流 | F-PRD-008 | 完工入库 | 完工実績の受信 |
| 上流 | F-PRD-001/003 | BOM/工艺 | PLM 取込結果の承認・反映 |
| 下流 | F-INV-018 | 条码/PDA | スキャン実績の在庫処理 |
| 下流 | F-INT-013 | 同期監視 | 失敗・滞留の監視 |
| 参照 | F-MDM-001 | 物料主数据 | 品目コードの存在チェック |

---

## 4. 画面設計

### 4.1 画面一覧

| 画面 ID | 画面名 | 類型 | 概要 |
|---|---|---|---|
| SCR-INT-016 | MES/WMS 連携状況 | ダッシュボード | 下发済・未回伝・失敗・滞留の件数、工单別状況 |
| SCR-INT-017 | PLM 同期状況 | 一覧検索 | 取込批次、差分件数、承認待ち、エラー行 |
| SCR-INT-023 | PDA 端末管理 | 一覧検索 | 端末一覧、有効/停止/紛失、最終同期、補伝状況 |

### 4.2 画面項目定義（SCR-INT-016）

| No | 項目 ID | 項目名 | 種別 | 型/桁 | 必須 | 初期値 | 入力チェック | データソース | DB 項目 |
|---|---|---|---|---|---|---|---|---|---|
| 1 | factory_id | 工厂 | 選択 | BIGINT | △ | 全厂 | 有効工厂 | `mdm_factory` | — |
| 2 | date_from | 対象開始日 | 日付 | DATE | ○ | 当月 1 日 | 開始 ≤ 終了 | 入力 | — |
| 3 | date_to | 対象終了日 | 日付 | DATE | ○ | 当日 | 同上 | 入力 | — |
| 4 | sync_status | 同期状態 | 選択 | SMALLINT | △ | 未完了 | 値域 | 固定値 | `int_sync_task.status` |
| 5 | work_order_no | 工单号 | テキスト | VARCHAR(32) | △ | 空 | 桁数 | 入力 | `prd_work_order.work_order_no` |
| 6 | issued_count | 下发件数 | 数値 | INT | — | — | — | 集計 | — |
| 7 | reported_count | 回伝件数 | 数値 | INT | — | — | — | 集計 | — |
| 8 | pending_count | 未回伝件数 | 数値 | INT | — | — | — | 集計 | — |
| 9 | failed_count | 失敗件数 | 数値 | INT | — | — | — | 集計 | — |

### 4.3 画面項目定義（SCR-INT-017）

| No | 項目 ID | 項目名 | 種別 | 型/桁 | 必須 | 初期値 | 入力チェック | データソース | DB 項目 |
|---|---|---|---|---|---|---|---|---|---|
| 1 | transfer_no | 取込批次 | テキスト | VARCHAR(48) | △ | 空 | 桁数 | `int_file_transfer` | `transfer_no` |
| 2 | layout_code | レイアウト | 選択 | VARCHAR(64) | △ | PLM_BOM | 有効レイアウト | `int_file_layout` | `layout_code` |
| 3 | biz_date | 対象日 | 日付 | DATE | ○ | 当日 | — | 入力 | `biz_date` |
| 4 | total_rows | 総行数 | 数値 | INT | — | — | — | 自動 | `total_rows` |
| 5 | success_rows | 成功行数 | 数値 | INT | — | — | — | 自動 | `success_rows` |
| 6 | fail_rows | 失敗行数 | 数値 | INT | — | — | — | 自動 | `fail_rows` |
| 7 | approval_status | 承認状態 | 表示 | SMALLINT | — | — | — | 自動 | `ext_data.approval_status` |
| 8 | error_summary | エラー概要 | テキスト | VARCHAR(1000) | — | — | — | 自動 | `error_summary` |

### 4.4 イベント処理

| No | イベント | トリガ | 処理内容 | 呼出 API | 画面遷移 |
|---|---|---|---|---|---|
| 1 | 工单下发 | E21 購読/手動 | 変換→送信→結果記録 | `POST /api/integration/mes/work-orders` | 同一画面 |
| 2 | 再下发 | 再送ボタン | 同一版数で再送（指示訂正） | `POST /api/integration/mes/work-orders/{no}/resend` | 同一画面 |
| 3 | 報工状況照会 | 行選択 | タスク・原文の確認 | `GET /api/integration/sync-tasks` | SCR-INT-005 |
| 4 | PLM 取込 | 取込ボタン | ファイル選択→検証→取込→承認待ち | `POST /api/integration/plm/imports` | SCR-INT-020 |
| 5 | PLM 承認 | 承認ボタン | 差分確認→承認→有効化 | `POST /api/integration/plm/imports/{id}/approve` | 同一画面 |
| 6 | 端末停止 | 停止ボタン | 理由必須→status=20 | `POST /api/integration/pda-devices/{id}/disable` | SCR-INT-023 |

### 4.5 表示制御

| 条件 | 対象 | 制御 |
|---|---|---|
| `integration:mes:view` なし | 画面全体 | 403 |
| 工单が `40/45` | 再下発ボタン | 非表示 |
| PLM 取込が未承認 | 有効化ボタン | 非表示（承認者のみ） |
| 端末 `status=30`（紛失） | 利用 | 不可、警告表示 |

---

## 5. 入力チェック仕様（受信時）

| No | チェック ID | 対象 | 種別 | 条件 | メッセージ |
|---|---|---|---|---|---|
| 1 | CHK-INT-006-01 | `reportNo` | 一意 | 未処理である | `MSG-INT-062` |
| 2 | CHK-INT-006-02 | `workOrderNo` | 存在 | 工单が存在し `30/35` | `MSG-INT-061` |
| 3 | CHK-INT-006-03 | `operationSeq` | 存在 | 工单工序に存在 | `MSG-INT-064` |
| 4 | CHK-INT-006-04 | 数量 | 相関 | `inputQty ≥ good + defect + scrap` | `MSG-INT-063` |
| 5 | CHK-INT-006-05 | 累計 | 業務 | 累計 ≤ `order_qty × (1 + over_report_rate)` | `MSG-INT-067` |
| 6 | CHK-INT-006-06 | `reportDate` | 範囲 | 未来日でない、期間 OPEN | `MSG-INT-068` |
| 7 | CHK-INT-006-07 | 工单版数 | 相関 | 下发済版数と一致 | `MSG-INT-069` |
| 8 | CHK-INT-010-01 | 端末 | 状態 | `status=10` | `MSG-INT-066` |
| 9 | CHK-INT-010-02 | 補伝 `seqNo` | 連続 | 欠番・重複なし | `MSG-INT-071` |
| 10 | CHK-INT-008-01 | BOM 版数 | 一意 | 同一版が未登録 | `MSG-INT-065` |

---

## 6. 処理詳細

### 6.1 処理一覧

| 処理 ID | 処理名 | 契機 | トランザクション | 排他 |
|---|---|---|---|---|
| PRC-INT-006-01 | 工单下发 | E21/手動 | 要（記録）／外部は外 | 工单版数 |
| PRC-INT-006-02 | 報工受信 | MES | 要 | `report_no` 一意 |
| PRC-INT-006-03 | 完工受信 | MES | 要 | `completionNo` 一意 |
| PRC-INT-008-01 | PLM 取込 | バッチ/手動 | 要 | 版数一意 |
| PRC-INT-010-01 | PDA スキャン | PDA | 要（業務側） | 在庫行ロック（INV） |
| PRC-INT-010-02 | 補伝受信 | PDA | 要 | `device+batch` 一意 |

### 6.2 処理手順（正常系）

**PRC-INT-006-01 工单下发**

1. E21 `production.workorder.released` を購読（または手動指示）し、工单・BOM・工艺を取得する。
2. MES 用 JSON へ変換（`int_interface_mapping`）。マスタ未登録・工程未定義を検査する。
3. `int_sync_task` に `status=10`、`idempotency_key="{workOrderNo}:{workOrderVersion}"` で登録する。
4. MES へ POST（タイムアウト 10 秒、リトライ 3 回、5xx/タイムアウトのみ）。
5. 成功応答（MES 工单 ID）を保存し `status=30`、`external_no` に MES ID を記録する。
6. 失敗は `status=40/50`。恒久失敗は `integration.sync.failed`（E33）を発行する。

**PRC-INT-006-02 報工受信**

1. 受信 JSON を検証（第 5 章）。`payload_hash` で重複を排除する。
2. `int_sync_task` に受信タスクを登録し、`reportNo` の既存を確認する（重複は ACK のみ）。
3. 工单・工序・数量・期間を検証し、`prd_work_report` と `prd_work_report_labor` / `prd_work_report_defect` を登録する。
4. 工单の `reported_good_qty` / `reported_defect_qty` / `reported_scrap_qty` / `progress_rate` を加算更新する（行ロック）。
5. E23 `production.report.confirmed` を発行する（Outbox）。
6. ACK（`reportNo`、`acceptedAt`）を返す。失敗時は理由コード付き NACK。

**PRC-INT-008-01 PLM 取込**

1. PLM の変更一覧（またはファイル）を取得し、`int_file_transfer` に批次を登録する。
2. レイアウト検証（必須・型・コード存在）を行い、エラー行を `int_file_transfer_error` に保存する。
3. 品目 → BOM → 工艺の順に「承認待ち」で登録する（`ext_data.approval_status=20`）。
4. 技術部の承認後、有効版として `mdm_material` / `prd_bom` / `prd_routing` に反映する。
5. 既存版との競合（同一版・適用日重複）は承認者に警告し、上書きしない。

### 6.3 例外処理

| No | 異常条件 | 検知 | 処理 | ロールバック | メッセージ |
|---|---|---|---|---|---|
| 1 | 工单が未承認 | 下发 | 送信しない | なし | `MSG-INT-060` |
| 2 | MES 未応答 | 送信 | リトライ→失敗一覧 | タスクのみ | `MSG-INT-060` |
| 3 | 報工の工单不存在 | 受信 | NACK、原文保存 | 全体 | `MSG-INT-061` |
| 4 | 報工数量不整合 | 受信 | NACK | 全体 | `MSG-INT-063` |
| 5 | 報工重複 | 受信 | ACK のみ（スキップ） | なし | `MSG-INT-062` |
| 6 | 過剰報工 | 受信 | NACK | 全体 | `MSG-INT-067` |
| 7 | 工程マスタ不一致 | 変換 | 送信中止 | タスクのみ | `MSG-INT-064` |
| 8 | BOM 版数重複 | PLM 取込 | 承認待ちに保留 | 行単位 | `MSG-INT-065` |
| 9 | PDA 端末失効 | スキャン | 拒否 | なし | `MSG-INT-066` |
| 10 | 補伝欠番 | 補伝 | 該当バッチを保留 | バッチ全体 | `MSG-INT-071` |

### 6.4 冪等性・再実行

| 処理 | 冪等キー | 再実行時の挙動 |
|---|---|---|
| 工单下发 | `workOrderNo + version` | 同一版は上書き（指示訂正）、結果のみ更新 |
| 報工 | `reportNo` | 重複は ACK のみ、再登録しない |
| 完工 | `completionNo` | 重複はスキップ |
| PLM 取込 | `layout + version + effective_from` | 同一版は再取込しない |
| PDA 補伝 | `deviceCode + batchNo` | 受信済みはスキップ、`dup_count` を加算 |

---

## 7. API 設計

| No | メソッド | パス | 権限 | 概要 |
|---|---|---|---|---|
| 1 | POST | `/api/integration/mes/work-orders` | `integration:mes:retry` | 工单下发（手動） |
| 2 | POST | `/api/integration/mes/work-orders/{no}/resend` | `integration:mes:retry` | 再下发 |
| 3 | POST | `/api/integration/mes/work-reports` | `integration:mes:receive`（システム） | 報工受信 |
| 4 | POST | `/api/integration/mes/completions` | `integration:mes:receive` | 完工受信 |
| 5 | GET | `/api/integration/mes/status` | `integration:mes:view` | 連携状況集計 |
| 6 | POST | `/api/integration/plm/imports` | `integration:plm:import` | PLM 取込 |
| 7 | POST | `/api/integration/plm/imports/{id}/approve` | `integration:plm:approve` | 取込承認 |
| 8 | GET | `/api/integration/plm/imports` | `integration:plm:view` | 取込一覧 |
| 9 | POST | `/api/integration/pda/scans` | `integration:pda:use` | スキャン受付 |
| 10 | POST | `/api/integration/pda/offline-batches` | `integration:pda:use` | 補伝受付 |
| 11 | GET | `/api/integration/pda-devices` | `integration:pda-device:view` | 端末一覧 |
| 12 | POST | `/api/integration/pda-devices/{id}/disable` | `integration:pda-device:update` | 端末停止 |

### 7.1 受信例（報工）

```json
POST /api/integration/mes/work-reports
{
  "reportNo": "MESWR2610200001",
  "workOrderNo": "WO2610200001",
  "operationSeq": 50,
  "reportDate": "2026-10-20",
  "shiftCode": "A",
  "inputQty": "120.0000",
  "goodQty": "118.0000",
  "defectQty": "2.0000",
  "scrapQty": "0.0000",
  "laborHours": "6.50",
  "machineHours": "4.00",
  "operatorCode": "E000123",
  "defects": [
    { "defectCode": "D010", "qty": "2.0000", "causeCode": "WINDING" }
  ],
  "reportedAt": "2026-10-20T17:30:00+08:00"
}
```

> 数量・工数は【示例値】。工单 `WO2610200001` は [90-data/routing-demo.md](../90-data/routing-demo.md) の工程構成に基づく示例。

### 7.2 応答例（ACK）

```json
{ "code": 0, "message": "ok", "data": { "reportNo": "MESWR2610200001", "accepted": true, "acceptedAt": "2026-10-20T17:30:02+08:00" } }
```

### 7.3 エラー例（NACK）

```json
{ "code": 90061, "message": "工单不存在或状态不允许报工。", "data": { "workOrderNo": "WO2610209999", "reportNo": "MESWR2610200001" } }
```

---

## 8. データ更新仕様

| テーブル | 操作 | 更新項目 | トリガ |
|---|---|---|---|
| `int_sync_job` / `int_sync_task` | INSERT/UPDATE | 状態・件数・再送 | 下发・受信 |
| `int_external_message` | INSERT | 原文・ハッシュ | 受信 |
| `prd_work_report` | INSERT | 報工 | 受信（PRD の API 経由） |
| `prd_work_report_labor` / `_defect` | INSERT | 工数・不良 | 受信 |
| `prd_work_order` | UPDATE | 累計・進捗・状態 | 受信（PRD の API 経由） |
| `int_file_transfer` / `_error` | INSERT/UPDATE | 取込結果 | PLM 取込 |
| `int_pda_offline_batch` | INSERT/UPDATE | 補伝結果 | PDA |
| `prd_bom` / `prd_routing` | INSERT（承認待ち） | BOM/工艺 | PLM 承認後 |

> INT は `prd_*` を直接 UPDATE しない。PRD の公開 API（`/api/production/work-reports` 等）を呼び出す（更新責任の一元化）。

---

## 9. エラー処理・メッセージ

| メッセージ ID | 種別 | 本文 | 発生条件 | 対処 |
|---|---|---|---|---|
| `MSG-INT-060` | E | 工单下发失败（{0}），系统将自动重试。 | 通信失敗/未承認 | 監視・再送 |
| `MSG-INT-061` | E | 报工对应的工单不存在或状态不正确。 | 工单不存在 | 工单確認 |
| `MSG-INT-062` | I | 检测到重复报工（{0}），已跳过。 | 重複 | なし |
| `MSG-INT-063` | E | 报工数量不满足投入 ≥ 良品 + 不良 + 报废。 | 数量不整合 | MES 側修正 |
| `MSG-INT-064` | E | 工序或工作中心未在 MES 中登记。 | マスタ不整合 | マスタ登録 |
| `MSG-INT-065` | E | BOM/工艺版本重复或适用日期冲突。 | 版数競合 | 承認者が調整 |
| `MSG-INT-066` | E | PDA 终端未授权或已停用，请联系管理员。 | 端末不正 | 端末再登録 |
| `MSG-INT-067` | E | 报工数量超过工单允许的超出率。 | 過剰報工 | 数量修正 |
| `MSG-INT-068` | E | 报工日期无效或会计期间已关闭。 | 日付/期間 | 日付修正 |
| `MSG-INT-069` | E | 工单版本不一致，请先重新下发。 | 版数不一致 | 再下发 |
| `MSG-INT-071` | E | 离线补传序号缺失或重复，已暂挂该批次。 | 補伝不整合 | 端末再送 |

---

## 10. 権限・セキュリティ

| 種別 | 内容 |
|---|---|
| 画面権限 | `integration:mes:view`、`integration:plm:view`、`integration:pda-device:view` |
| 操作権限 | 再下发 `integration:mes:retry`、PLM 承認 `integration:plm:approve`、端末更新 `integration:pda-device:update` |
| 端末認証 | PDA は端末証明（`device_code` + secret）＋利用者ログインの二段階。端末紛失時は即時停止 |
| データ範囲 | 工場（CZ01/WX01）・倉庫単位。他工場のデータは参照不可 |
| 監査 | 下发・受信・PLM 承認・端末変更を記録 |
| 個人情報 | `operatorCode` は社員コードのみ。氏名は保存しない（必要な場合は SYS 参照） |

---

## 11. 性能・非機能

| 項目 | 目標 | 前提 |
|---|---|---|
| 工单下发 | 10 秒以内 | MES SLA 依存 |
| 報工受信 | 3 秒以内（1 メッセージ 50 行まで） | — |
| 補伝受信 | 10 秒以内（500 行） | — |
| PLM 取込 | 5,000 行で 5 分以内 | 非同期ジョブ |
| 同時接続 | MES 20、PDA 50 | — |

---

## 12. テスト観点

| No | 観点 ID | 分類 | 観点 | 期待結果 |
|---|---|---|---|---|
| 1 | TST-F-INT-006-01 | 正常系 | 工单下发→MES 受理 | `status=30`、MES ID 保存 |
| 2 | TST-F-INT-006-02 | 冪等 | 同一版を再下发 | 上書き、二重作成なし |
| 3 | TST-F-INT-006-03 | 異常系 | 未承認工单の下发 | `MSG-INT-060` |
| 4 | TST-F-INT-006-04 | 正常系 | 報工受信→E23 発行 | `prd_work_report` 登録、累計更新 |
| 5 | TST-F-INT-006-05 | 冪等 | 同一 `reportNo` 再受信 | ACK のみ、二重登録なし |
| 6 | TST-F-INT-006-06 | 異常系 | 数量不整合 | NACK `MSG-INT-063` |
| 7 | TST-F-INT-006-07 | 境界 | 過剰率 5% ちょうど | 受理（設定による） |
| 8 | TST-F-INT-006-08 | 異常系 | 工单版数不一致 | `MSG-INT-069` |
| 9 | TST-F-INT-008-01 | 正常系 | PLM BOM 取込→承認 | 有効 BOM 反映 |
| 10 | TST-F-INT-008-02 | 異常系 | 同一版 BOM | `MSG-INT-065`、上書きしない |
| 11 | TST-F-INT-010-01 | 正常系 | PDA スキャン→在庫反映 | INV に実績 |
| 12 | TST-F-INT-010-02 | 正常系 | オフライン補伝 | 重複排除、`dup_count` 記録 |
| 13 | TST-F-INT-010-03 | 異常系 | 端末失効 | `MSG-INT-066` |
| 14 | TST-F-INT-010-04 | 異常系 | 補伝欠番 | バッチ保留 `MSG-INT-071` |
| 15 | TST-F-INT-007-01 | 正常系（P2） | WMS 入出庫指示 | 指示・実績が一致 |
| 16 | TST-F-INT-007-02 | 異常系（P2） | 在庫差異 | 自動調整しない、対账で検出 |

---

## 13. 未決事項

| # | 事項 | 理由 | 暫定仕様 | 担当 | 期限 |
|---|---|---|---|---|---|
| 1 | MES のベンダー・ペイロード仕様 | 未選定 | 本設計の JSON を契約案とし、`int_interface_mapping` で吸収 | 生産／情報部 | 2026-12-15 |
| 2 | MES 側の工单 ID 体系 | MES 採番が未確定 | `external_no` に保存し、ERP は内部 ID を保持 | integration | 2026-12-31 |
| 3 | PLM 接続方式（REST/ファイル） | PLM 製品未確定 | 両対応。Phase 1 はファイル（XML/CSV）を既定 | 技術部 | 2026-12-31 |
| 4 | PLM 承認フローの主体 | 技術部か MDM か | 技術部承認 → MDM 反映（BOM は PRD が保持） | Lead／技術部 | 2026-12-15 |
| 5 | PDA 端末の機種・OS | 現場調達未定 | REST/JSON、証明書または端末シークレット。OS 非依存 | 情報部 | 2026-12-31 |
| 6 | WMS の要否と範囲 | Phase 2 | 入出庫指示・実績・在庫照会の最小 IF を定義 | Lead | Phase 2 |
| 7 | 物流面单・EDI の対象業者 | Phase 2 | アダプタ方式。項目は追補 | SAL／情報部 | Phase 2 |
| 8 | IoT データの取込粒度 | Phase 2 | MQTT、設備×分次。保存 1 年 | 生産 | Phase 2 |

## 14. 改訂履歴

| 版数 | 日付 | 変更内容 | 変更者 |
|---|---|---|---|
| v1.0 | 2026-10-20 | 初版：MES JSON（工单/報工/完工）、PLM 差分取込、PDA オフライン補伝、WMS 概要、エラー・テスト観点 | integration-designer |
