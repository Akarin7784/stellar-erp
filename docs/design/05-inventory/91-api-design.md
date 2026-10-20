# 库存管理 API 设计书（在庫管理 API 設計書）

| 項目 | 内容 |
|---|---|
| 文書名 | 库存管理 API 设计书（在庫管理 API 設計書） |
| 文書番号 | DSN-INV-091 |
| 版数 | v1.0 |
| 作成日 | 2026-10-20 |
| 作成者 | inventory-designer |
| 承認者 | 未承認（レビュー待ち） |
| 状態 | ドラフト（レビュー中） |
| 関連文書 | [API 共通規格](../00-common/03-common-api-spec.md) / [業務域概要](00-overview.md) / [DB 設計](90-db-design.md) / [メッセージ](93-messages.md) / [跨域流程](../00-common/09-cross-domain-flow.md) |

---

## 1. 適用範囲・基本方針

本文件は在庫管理域（INV）の REST API を定義する。共通仕様は [03 API 共通規格](../00-common/03-common-api-spec.md) を正とし、本文件では**本域固有のパス・項目・エラー**のみを定義する（重複定義しない）。

| 項目 | 内容 |
|---|---|
| ベースパス | `/api/inventory/**` |
| 認証 | `Authorization: {token}`（Sa-Token）。全 API 必須 |
| 権限 | `@SaCheckPermission("inventory:{resource}:{action}")`。本文件の各 API に記載 |
| レスポンス | `Result<T>` / 一覧は `PageResult<T>`（[03 §5/§7](../00-common/03-common-api-spec.md)） |
| ID・数量・金額 | **文字列**で返す（`"1845678901234567890"`、`"500.0000"`、`"2800.00"`） |
| 日付・日時 | `yyyy-MM-dd` / ISO 8601（`+08:00`） |
| 楽観排他 | 更新系は `version` 必須。競合は `409` + `code=4003` |
| 冪等 | 登録・過账・沖销・調整・月结・スキャン確定は `Idempotency-Key` 必須 |
| 非同期 | 月结・再計算・帳票・エクスポートは `202 + jobId`（`GET /api/inventory/jobs/{jobId}`） |
| データ権限 | 倉庫/工場の行レベル条件を SQL に強制注入（画面条件のみに依存しない） |
| エラーコード | 本域は `50001〜50099`。`code = 50000 + MSG-INV-NNN` の規則で対応（例 `MSG-INV-001` → `50001`） |

---

## 2. API 一覧

### 2.1 在庫照会・流水

| # | メソッド | パス | 権限 | 概要 | 関連機能 |
|---|---|---|---|---|---|
| 1 | GET | `/api/inventory/stock-balances` | `inventory:stock-balance:view` | 在庫残高照会（ページング） | F-INV-001 |
| 2 | GET | `/api/inventory/stock-balances/available` | `inventory:stock-balance:view`（内部はサービス呼出） | 可用量照会（集約） | F-INV-001/019 |
| 3 | GET | `/api/inventory/stock-balances/available-batches` | `inventory:stock-balance:view` | 批次別可用量（FEFO/FIFO） | F-INV-001/011 |
| 4 | GET | `/api/inventory/stock-balances/summary` | `inventory:stock-balance:view` | 物料別集約 | F-INV-001 |
| 5 | GET | `/api/inventory/stock-balances/in-transit` | `inventory:transfer:view` | 在途量照会 | F-INV-009 |
| 6 | GET | `/api/inventory/stock-txns` | `inventory:stock-txn:view` | 事務流水一覧 | F-INV-013 |
| 7 | GET | `/api/inventory/stock-txns/{id}` | `inventory:stock-txn:view` | 事務詳細（明細含む） | F-INV-013 |
| 8 | POST | `/api/inventory/stock-txns/{id}/reverse` | `inventory:stock-txn:reverse` | 事務沖销 | F-INV-013 |
| 9 | GET | `/api/inventory/stock-txns/ledger` | `inventory:stock-txn:view` | 台帳（結存推移） | F-INV-013/021 |
| 10 | GET | `/api/inventory/sources/{sourceType}/{sourceId}/lines` | `inventory:stock-txn:view` | 来源伝票の未処理明細 | F-INV-002〜008 |

### 2.2 入出庫・状態変換

| # | メソッド | パス | 権限 | 概要 | 関連機能 |
|---|---|---|---|---|---|
| 11 | POST | `/api/inventory/stock-txns` | `inventory:stock-txn:create` | 入出庫伝票の登録（草稿） | F-INV-002〜008 |
| 12 | PUT | `/api/inventory/stock-txns/{id}` | `inventory:stock-txn:update` | 草稿の更新 | 同上 |
| 13 | POST | `/api/inventory/stock-txns/{id}/submit` | `inventory:stock-txn:submit` | 承認提出 | AOI/AOO/SC_OUT |
| 14 | POST | `/api/inventory/stock-txns/{id}/post` | `inventory:stock-txn:post` | 過账（在庫更新） | 全入出庫 |
| 15 | POST | `/api/inventory/stock-txns/{id}/cancel` | `inventory:stock-txn:update` | 草稿取消 | 全入出庫 |
| 16 | POST | `/api/inventory/stock-txns/{id}/print` | `inventory:stock-txn:print` | 伝票 PDF 出力 | 各伝票 |
| 17 | POST | `/api/inventory/stock-txns/scan-load` | `inventory:barcode:scan` | スキャン結果から明細生成 | F-INV-018 |
| 18 | GET | `/api/inventory/stock-txns/recalculate` | `inventory:cost:view` | 原価再計算プレビュー（保存しない） | F-INV-017 |
| 19 | POST | `/api/inventory/status-conversions` | `inventory:status:change` | 在庫状態変換 | F-INV-014 |
| 20 | POST | `/api/inventory/status-conversions/{id}/submit` | `inventory:status:change` | 状態変換の承認提出 | F-INV-014 |
| 21 | GET | `/api/inventory/status-conversions` | `inventory:status:change` | 状態変換履歴 | F-INV-014 |

### 2.3 調撥

| # | メソッド | パス | 権限 | 概要 | 関連機能 |
|---|---|---|---|---|---|
| 22 | GET | `/api/inventory/transfers` | `inventory:transfer:view` | 調撥一覧 | F-INV-009 |
| 23 | GET | `/api/inventory/transfers/{id}` | `inventory:transfer:view` | 調撥詳細 | F-INV-009 |
| 24 | POST | `/api/inventory/transfers` | `inventory:transfer:create` | 調撥登録 | F-INV-009 |
| 25 | PUT | `/api/inventory/transfers/{id}` | `inventory:transfer:create` | 調撥更新（草稿） | F-INV-009 |
| 26 | POST | `/api/inventory/transfers/{id}/submit` | `inventory:transfer:create` | 承認提出 | F-INV-009 |
| 27 | POST | `/api/inventory/transfers/{id}/ship` | `inventory:transfer:ship` | 出庫（TR_OUT） | F-INV-009 |
| 28 | POST | `/api/inventory/transfers/{id}/receive` | `inventory:transfer:receive` | 受入（TR_IN） | F-INV-009 |
| 29 | POST | `/api/inventory/transfers/{id}/return` | `inventory:transfer:receive` | 退回（残量を源倉庫へ） | F-INV-009 |
| 30 | POST | `/api/inventory/transfers/{id}/cancel` | `inventory:transfer:cancel` | 取消 | F-INV-009 |
| 31 | GET | `/api/inventory/transfers/in-transit` | `inventory:transfer:view` | 在途一覧 | F-INV-009 |
| 32 | POST | `/api/inventory/transfers/{id}/print` | `inventory:transfer:print` | 調撥単 PDF | F-INV-009 |

### 2.4 棚卸

| # | メソッド | パス | 権限 | 概要 | 関連機能 |
|---|---|---|---|---|---|
| 33 | GET | `/api/inventory/stocktake-plans` | `inventory:stocktake:view` | 盤点計画一覧 | F-INV-010 |
| 34 | POST | `/api/inventory/stocktake-plans` | `inventory:stocktake:create` | 盤点計画登録 | F-INV-010 |
| 35 | POST | `/api/inventory/stocktake-plans/{id}/submit` | `inventory:stocktake:create` | 計画提出 | F-INV-010 |
| 36 | POST | `/api/inventory/stocktake-plans/{id}/generate` | `inventory:stocktake:create` | 盤点単生成 | F-INV-010 |
| 37 | GET | `/api/inventory/stocktakes` | `inventory:stocktake:view` | 盤点単一覧 | F-INV-010 |
| 38 | GET | `/api/inventory/stocktakes/{id}` | `inventory:stocktake:view` | 盤点単詳細 | F-INV-010 |
| 39 | POST | `/api/inventory/stocktakes/{id}/start` | `inventory:stocktake:enter` | 実盤開始（凍結） | F-INV-010 |
| 40 | PUT | `/api/inventory/stocktakes/{id}/lines` | `inventory:stocktake:enter` | 実盤数量の一括更新 | F-INV-010 |
| 41 | POST | `/api/inventory/stocktakes/{id}/scan` | `inventory:barcode:scan` | PDA スキャン入力 | F-INV-010/018 |
| 42 | POST | `/api/inventory/stocktakes/{id}/import` | `inventory:stocktake:enter` | Excel 取込（2 段階） | F-INV-010 |
| 43 | POST | `/api/inventory/stocktakes/{id}/calc-diff` | `inventory:stocktake:enter` | 差異計算 | F-INV-010 |
| 44 | POST | `/api/inventory/stocktakes/{id}/submit` | `inventory:stocktake:submit` | 差異確定・承認提出 | F-INV-010 |
| 45 | POST | `/api/inventory/stocktakes/{id}/approve` | `inventory:stocktake:approve` | 承認（WF コールバック含む） | F-INV-010 |
| 46 | POST | `/api/inventory/stocktakes/{id}/reject` | `inventory:stocktake:approve` | 却下 | F-INV-010 |
| 47 | POST | `/api/inventory/stocktakes/{id}/adjust` | `inventory:stocktake:adjust` | 調整実行（ADJ_IN/OUT） | F-INV-010 |
| 48 | POST | `/api/inventory/stocktakes/{id}/cancel` | `inventory:stocktake:create` | 取消 | F-INV-010 |
| 49 | POST | `/api/inventory/stocktakes/{id}/print` | `inventory:stocktake:view` | 盤点表 PDF | F-INV-010 |

### 2.5 批次・序列号

| # | メソッド | パス | 権限 | 概要 | 関連機能 |
|---|---|---|---|---|---|
| 50 | GET | `/api/inventory/batches` | `inventory:batch:view` | 批次一覧 | F-INV-011 |
| 51 | GET | `/api/inventory/batches/{id}` | `inventory:batch:view` | 批次詳細 | F-INV-011 |
| 52 | GET | `/api/inventory/batches/{id}/trace` | `inventory:batch:trace` | 批次追溯（前向/後向） | F-INV-011 |
| 53 | GET | `/api/inventory/batches/expiry-warnings` | `inventory:batch:view` | 有效期警告一覧 | F-INV-011 |
| 54 | PATCH | `/api/inventory/batches/{id}` | `inventory:batch:view` | 批次の限定更新（QC 状態等） | F-INV-011 |
| 55 | GET | `/api/inventory/serials` | `inventory:serial:view` | 序列号一覧 | F-INV-012 |
| 56 | GET | `/api/inventory/serials/{serialNo}` | `inventory:serial:view` | 序列号詳細 | F-INV-012 |
| 57 | GET | `/api/inventory/serials/{serialNo}/trace` | `inventory:serial:view` | 序列号履歴 | F-INV-012 |

### 2.6 原価

| # | メソッド | パス | 権限 | 概要 | 関連機能 |
|---|---|---|---|---|---|
| 58 | GET | `/api/inventory/costs/balances` | `inventory:cost:view` | cost group 別 数量・金額・平均単価 | F-INV-017 |
| 59 | GET | `/api/inventory/costs/layers` | `inventory:cost:view` | 成本層一覧 | F-INV-017 |
| 60 | GET | `/api/inventory/costs/movements` | `inventory:cost:view` | 原価流水（平均単価推移） | F-INV-017 |
| 61 | GET | `/api/inventory/costs/adjustment-base` | `inventory:cost:adjust` | 調整基礎情報 | F-INV-017 |
| 62 | GET | `/api/inventory/cost-adjustments` | `inventory:cost:view` | 成本調整単一覧 | F-INV-017 |
| 63 | GET | `/api/inventory/cost-adjustments/{id}` | `inventory:cost:view` | 成本調整単詳細 | F-INV-017 |
| 64 | POST | `/api/inventory/cost-adjustments` | `inventory:cost:adjust` | 成本調整単登録 | F-INV-017 |
| 65 | PUT | `/api/inventory/cost-adjustments/{id}` | `inventory:cost:adjust` | 成本調整単更新（草稿） | F-INV-017 |
| 66 | POST | `/api/inventory/cost-adjustments/{id}/submit` | `inventory:cost:adjust` | 承認提出 | F-INV-017 |
| 67 | POST | `/api/inventory/cost-adjustments/{id}/approve` | `inventory:cost:approve` | 承認 | F-INV-017 |
| 68 | POST | `/api/inventory/cost-adjustments/{id}/post` | `inventory:cost:adjust` | 過账（E19） | F-INV-017 |
| 69 | POST | `/api/inventory/cost-adjustments/{id}/reverse` | `inventory:cost:adjust` | 沖销（期間内） | F-INV-017 |
| 70 | POST | `/api/inventory/costs/recalculate` | `inventory:cost:recalc` | 期間再計算（202） | F-INV-017 |

### 2.7 予約・PDA・月結・補貨・帳票

| # | メソッド | パス | 権限 | 概要 | 関連機能 |
|---|---|---|---|---|---|
| 71 | GET | `/api/inventory/reservations` | `inventory:reservation:view` | 予約一覧 | F-INV-019 |
| 72 | GET | `/api/inventory/reservations/{id}` | `inventory:reservation:view` | 予約詳細 | F-INV-019 |
| 73 | POST | `/api/inventory/reservations` | `inventory:reservation:create` | 手動引当 | F-INV-019 |
| 74 | POST | `/api/inventory/reservations/{id}/release` | `inventory:reservation:release` | 予約解放 | F-INV-019 |
| 75 | POST | `/api/inventory/reservations/allocate` | `inventory:reservation:create` | 來源単位の引当（内部） | F-INV-019 |
| 76 | POST | `/api/inventory/scan-sessions` | `inventory:barcode:scan` | スキャンセッション開始 | F-INV-018 |
| 77 | GET | `/api/inventory/scan-sessions/{id}` | `inventory:barcode:scan` | セッション状態 | F-INV-018 |
| 78 | POST | `/api/inventory/scans` | `inventory:barcode:scan` | スキャン（検証・数量加算） | F-INV-018 |
| 79 | POST | `/api/inventory/scans/sync` | `inventory:barcode:scan` | オフライン実績の一括送信 | F-INV-018 |
| 80 | POST | `/api/inventory/labels/print` | `inventory:barcode:print` | ラベル印刷 | F-INV-018 |
| 81 | GET | `/api/inventory/periods` | `inventory:period:view` | 期間一覧・状態 | F-INV-020 |
| 82 | POST | `/api/inventory/periods/{periodCode}/close-checks` | `inventory:period:close` | 月结前置检查（ドライラン） | F-INV-020 |
| 83 | POST | `/api/inventory/periods/{periodCode}/close` | `inventory:period:close` | 月结実行（202） | F-INV-020 |
| 84 | POST | `/api/inventory/periods/{periodCode}/reopen` | `inventory:period:reopen` | 期間再开 | F-INV-020 |
| 85 | GET | `/api/inventory/jobs/{jobId}` | 各ジョブ起動権限 | 非同期ジョブ結果 | 全般 |
| 86 | GET | `/api/inventory/replenishments` | `inventory:replenishment:view` | 補貨建議一覧 | F-INV-016 |
| 87 | POST | `/api/inventory/replenishments/generate` | `inventory:replenishment:generate` | 建議生成（202） | F-INV-016 |
| 88 | POST | `/api/inventory/replenishments/{id}/mark-ordered` | `inventory:replenishment:generate` | 請購作成済の記録 | F-INV-016 |
| 89 | POST | `/api/inventory/replenishments/{id}/ignore` | `inventory:replenishment:generate` | 建議の無視 | F-INV-016 |
| 90 | GET | `/api/inventory/reports/stock-summary` | `inventory:report:view` | 受発存汇总 | F-INV-021 |
| 91 | GET | `/api/inventory/reports/age` | `inventory:report:view` | 庫齢分析 | F-INV-015 |
| 92 | GET | `/api/inventory/reports/slow-moving` | `inventory:report:view` | 呆滞料一覧 | F-INV-015 |
| 93 | GET | `/api/inventory/reports/turnover` | `inventory:report:view` | 在庫回転率 | F-INV-021 |
| 94 | POST | `/api/inventory/reports/{reportCode}/print` | `inventory:report:export` | 帳票 PDF 出力 | F-INV-021 |
| 95 | POST | `/api/inventory/exports` | `inventory:stock-balance:export` 等 | 非同期エクスポート | 全照会 |

> 入出庫・調撥・棚卸・原価・予約・PDA・月結の**画面向け詳細**（項目定義・JSON 例）は各主題文書（[02](02-inbound-outbound.md) §4/§7、[03](03-transfer-count.md) §4/§7、[05](05-costing.md) §4/§7、[06](06-reservation-barcode-close.md) §4/§7）を正とし、本文件では**API 契約の要約と横断的な規則**を定義する。

---

## 3. API 詳細（契約）

### 3.1 在庫残高照会 `GET /api/inventory/stock-balances`

**目的**：現存量・引当量・可用量を倉庫/物料/批次/庫位/状態で照会する。

| パラメータ | 型 | 必須 | 説明 |
|---|---|---|---|
| `warehouseIds` | string（カンマ区切り） | — | 倉庫 ID |
| `materialId` / `materialKeyword` | string | — | 物料 ID / コード・名称・仕様の部分一致 |
| `categoryCode` | string | — | 物料分類（配下含む） |
| `batchNo` / `locationCode` | string | — | 批次号（前方一致）/ 庫位コード |
| `stockStatuses` | string | — | 10,20,30,40,50 |
| `includeZero` | boolean | — | 既定 false |
| `displayUnit` | string | — | `WAREHOUSE`（既定）/`LOCATION` |
| `sort` / `pageNum` / `pageSize` | — | — | [03 §7](../00-common/03-common-api-spec.md) |

**成功例**（`Result<PageResult<StockBalanceDto>>`）は [01](01-stock-query.md) 7.2.1 を参照。**備考**：照会はロックしない。可用量の最終判定は引当/出庫側で行う。

### 3.2 可用量照会 `GET /api/inventory/stock-balances/available`

**目的**：SAL/PRD からの同期照会用。**予約は行わない**（[01](01-stock-query.md) BR-02）。

| パラメータ | 型 | 必須 | 説明 |
|---|---|---|---|
| `materialId` | string | ○ | 物料 ID |
| `warehouseId` | string | — | 未指定なら全倉庫合算 |

**レスポンス項目**：`materialId, materialCode, uomCode, onHandQty, reservedQty, inspectionQty, frozenQty, rejectedQty, availableQty, queriedAt`。

**利用契約**（SAL/PRD との合意事项）：
- `availableQty = onHandQty − reservedQty − inspectionQty − frozenQty − rejectedQty`（[00-overview](00-overview.md) 2.3 の唯一算式）。
- 照会結果はスナップショットであり、引当の成否は E09 を正とする。
- 内部呼出（モジュール間）は `StockAvailabilityService`（Spring Modulith 公開サービス）を使用し、HTTP を経由しない。パフォーマンス目標 200ms。

### 3.3 入出庫伝票の登録 `POST /api/inventory/stock-txns`

**目的**：入出庫伝票を草稿で登録する。手動登録可能なのは `AOI`/`AOO`/`SC_OUT`，および来源再送・補正時の `PI`/`SI`/`MII`/`MIR`/`FGI`/`OSI`/`OSR`/`RT_IN`/`PR_OUT`（権限分離）。

**リクエスト項目**

| 項目 | 型 | 必須 | 説明 |
|---|---|---|---|
| `txnType` | string | ○ | 19 種のいずれか。手動可能種別は権限で制御 |
| `txnDate` | date | ○ | 対象期間 OPEN、遡及禁止 |
| `warehouseId` | string | ○ | 1 事務 1 倉庫 |
| `reasonType` | int | △ | AOI/AOO/SC_OUT の原因区分（[02](02-inbound-outbound.md) 2.6.6/2.6.7） |
| `partnerType/partnerId/partnerName` | int/string/string | — | 相手先（スナップショット） |
| `sourceType/sourceId/sourceNo` | string/string/string | — | 来源（手動の場合は `MANUAL`） |
| `remark` | string | — | 500 文字以内 |
| `lines[]` | array | ○ | 1〜1,000 行 |
| `lines[].lineNo` | int | — | 省略時は 10 刻みで自動 |
| `lines[].materialId` | string | ○ | — |
| `lines[].uomCode` | string | ○ | 基本単位に換算 |
| `lines[].qty` | string | ○ | > 0、4 桁 |
| `lines[].batchNo` | string | △ | 批次管理時必須 |
| `lines[].serialNos[]` | string[] | △ | 序列号管理時必須（数量と一致） |
| `lines[].locationId` | string | △ | 庫位管理倉庫時必須 |
| `lines[].stockStatus` | int | ○ | 入庫 10（待検）/20（可用。免检品のみ直入）、出庫 20（SC_OUT は 50/40） |
| `lines[].unitPrice` | string | △ | AOI/補正時の原価単価 |
| `lines[].sourceLineNo` | int | — | 来源行番号 |

**成功例**：201 + `Result<StockTxnDto>`（[02](02-inbound-outbound.md) 7.2.1）。
**主なエラー**：`400` 1001/1002（入力）、`404` 4001（対象なし）、`409` 4003/4005（排他・二重）、`422` 50005/50009/50025/50042（業務）、`403` 3001/3002（権限・範囲）。

### 3.4 過账 `POST /api/inventory/stock-txns/{id}/post`

**目的**：在庫を更新し、E18 を発行する。

| リクエスト項目 | 型 | 必須 | 説明 |
|---|---|---|---|
| `version` | int | ○ | 楽観排他 |
| `comment` | string | — | 任意コメント |

**処理概要**：[02](02-inbound-outbound.md) 6.2（PRC-INV-002-01/003-01）と 6.3（残高更新アルゴリズム）。
**成功例**：200 + 更新後の `StockTxnDto`（`txnStatus=30`、明細の `unitCost/amount/before/after`）。
**失敗時**：全体ロールバック。伝票は草稿のまま。
**エラー**：`422` 50001（在庫不足）、50025（遡及）、50026（ロックタイムアウト）、50042（期間関账）、50053（負在庫）。

### 3.5 沖销 `POST /api/inventory/stock-txns/{id}/reverse`

| リクエスト項目 | 型 | 必須 | 説明 |
|---|---|---|---|
| `version` | int | ○ | — |
| `reason` | string | ○ | 1〜500 文字 |

**処理概要**：反向事務を生成し、残高・成本層を戻す。`reversal_of_txn_id` の一意制約で二重沖销を防ぐ（[01](01-stock-query.md) PRC-INV-013-02）。
**成功例**：200 + 反向事務の `StockTxnDto`（`isReversal=true`、`reversalOfTxnId`）。
**エラー**：`422` 50021（沖销済）、50023（未過账）、50024（下流処理あり）、50001（在庫不足）。

### 3.6 調撥出庫/受入 `POST /api/inventory/transfers/{id}/ship` / `receive`

**ship**：リクエスト `{ "version": 1, "comment": "..." }`。TR_OUT を生成し、`transfer_status=30 出庫済（在途）`。
**receive**：

```json
{
  "version": 1,
  "receivedDate": "2026-10-21",
  "lines": [
    { "lineId": "1845678901234568101", "receivedQty": "80.0000", "toLocationId": null }
  ]
}
```

TR_IN を生成し、`30→35/40`。**エラー**：50001/50027/50028/50029/50042。

### 3.7 棚卸単生成・実盤・差異・調整

| API | 主なリクエスト | 主なレスポンス |
|---|---|---|
| `POST /stocktake-plans/{id}/generate` | `{ "version": 1 }` | `{ stocktakeNo, totalLines, snapshotAt }` |
| `PUT /stocktakes/{id}/lines` | `{ version, lines[{lineId, countedQty, reCountedQty, remark}] }` | `{ countedLines, progress }` |
| `POST /stocktakes/{id}/calc-diff` | `{ "version": 2 }` | `{ diffLines, diffAmount, details }` |
| `POST /stocktakes/{id}/adjust` | `{ version, adjustDate, confirmDiffChange }` | `{ adjustTxnNo, adjustLines[], totalDiffAmount }` |

詳細は [03](03-transfer-count.md) 7.2。**エラー**：50032（未完了棚卸）、50033（未承認）、50035（閾値超過）、50036（差異変化）、50039（復盤必須）、50041。

### 3.8 状態変換 `POST /api/inventory/status-conversions`

```json
{
  "conversionDate": "2026-10-20",
  "warehouseId": "1845000000000000001",
  "sourceType": "INSPECTION",
  "sourceNo": "IQC2610200001",
  "reason": "来料检验合格，转可用库存",
  "lines": [
    { "materialId": "1845000000000000101", "batchNo": "261020P001", "fromStatus": 10, "toStatus": 20, "qty": "500.0000" }
  ]
}
```

**成功例**：200 + `{ pairKey, stOutTxnNo, stInTxnNo, convertedAt, lines[] }`（[04](04-batch-serial-status.md) 7.2.2）。
**エラー**：50012（状態不整合）、50038（引当済）、50025/50042。

### 3.9 原価調整 `POST /api/inventory/cost-adjustments` / `.../post`

[05](05-costing.md) 7.2.2 のとおり。**過账**は在庫金額・平均単価・成本層を更新し、E19 を発行する（**在庫事務は生成しない**）。
**エラー**：50037（負金額）、50038（期間）、50039、50040、50041。

### 3.10 予約 `GET /api/inventory/reservations` / `POST .../release`

一覧項目：`reservationNo, sourceType, sourceNo, materialCode, materialName, warehouseCode, batchNo, reservedQty, consumedQty, remainingQty, shortageQty, reservationStatus, expireDate`。
**解放**：`{ version, reason }` → E09（`RELEASED`）。**エラー**：50047/50048。

### 3.11 PDA スキャン `POST /api/inventory/scans`

[06](06-reservation-barcode-close.md) 7.2.2 のとおり。**冪等キー**：`deviceId + localSeq`（`Idempotency-Key` も併用）。
**エラー**：50008（序列号重複）、50050（バーコード不明）、50051（誤倉庫）、50052（数量不一致）、50054（重複スキャン・警告）、50056（誤物料/批次）。

### 3.12 月結 `POST /api/inventory/periods/{periodCode}/close`

| リクエスト項目 | 型 | 必須 | 説明 |
|---|---|---|---|
| `comment` | string | — | 実行コメント |
| `jobMode` | string | — | `ASYNC`（既定）/`SYNC`（テスト用） |

**処理概要**：[06](06-reservation-barcode-close.md) 6.2 PRC-INV-020-01（11 項目前置检查 → 収发存汇总 → 关账 → E20）。
**成功例**：202 + `{ jobId, periodCode, status }`。
**エラー**：50041（前置检查 NG）、50042（既に关账）、50043（前月未关账）。

### 3.13 非同期ジョブ `GET /api/inventory/jobs/{jobId}`

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "jobId": "1845678901234568501",
    "jobType": "INVENTORY_PERIOD_CLOSE",
    "status": "SUCCEEDED",
    "progress": 100,
    "result": { "periodCode": "2026-10", "checkCount": 10, "summaryCount": 1280 },
    "errorMessage": null,
    "startedAt": "2026-11-01T02:00:00+08:00",
    "finishedAt": "2026-11-01T02:15:33+08:00"
  }
}
```

`status`：`QUEUED`/`RUNNING`/`SUCCEEDED`/`FAILED`/`CANCELLED`。結果ファイルは `GET /api/inventory/jobs/{jobId}/files/{fileId}`。

### 3.14 イベント連携（E15/E24/E18）と `stockDocNo` 返却

本域の入出庫・品質変換は**イベント駆動**であり、E15/E24 に対応する公開 API は提供しない（内部ハンドラ `PRC-INV-002-07`）。

| 項目 | 内容 |
|---|---|
| E15 消費 | `resultCode` 20/30→`20 可用`、40/50→`40 不合格`（ヘッダ/行、行優先）。E14/E24 未過账時は `inv_event_wait` に保留 |
| E24 消費 | `lines[].stockStatus` を検証（検査必須は `10 待检`）。`inspectionResult` は E15 適用まで参考値 |
| E18 返却 | `stockDocId`・`stockDocNo`（= `txnNo`）を追加項目として返す。PRD/PUR/SAL は `sourceId` で要求行を特定する |
| 関連 API | 参照系のみ：`GET /api/inventory/stock-txns`、`GET /api/inventory/stock-balances/available`。`inv_event_wait` は内部管理で API 非公開 |

---

## 4. API とメッセージの対応

| code | メッセージ ID | 主な API |
|---|---|---|
| 50001 | `MSG-INV-001` | 過账・沖销・出庫（在庫不足） |
| 50005/50009/50010 | `MSG-INV-005/009/010` | 入出庫・状態変換（批次/序列号） |
| 50012 | `MSG-INV-012` | 過账・状態変換（状態不正） |
| 50021/50023/50024/50025/50026 | `MSG-INV-021/023/024/025/026` | 沖销・過账 |
| 50027/50028/50029/50031 | `MSG-INV-027/028/029/031` | 調撥 |
| 50032/50033/50035/50036/50039 | `MSG-INV-032/033/035/036/039` | 棚卸 |
| 50037/50038/50040/50041 | `MSG-INV-037/038/040/041` | 原価・月結 |
| 50042/50043/50044 | `MSG-INV-042/043/044` | 期間 |
| 50047/50048 | `MSG-INV-047/048` | 予約 |
| 50050/50051/50052/50053/50054/50056 | `MSG-INV-050/051/052/053/054/056` | PDA・在庫不足 |
| 50055/50057/50058 | `MSG-INV-055/057/058` | 来源・庫位 |
| 50063/50064/50065/50066/50067 | `MSG-INV-063〜067` | 品質イベント（E15）・完了入庫（E24）・受入取消（E35）・倉庫変更（E39） |
| 4001/4002/4003/4005 | `MSG-COM-032/034/033/075` | 共通 |
| 1001〜1005 | `MSG-COM-040` 等 | 共通バリデーション |
| 3001/3002 | `MSG-COM-030/031` | 権限 |

> 個別のエラー本文・対処は [93-messages](93-messages.md) を正とする。

---

## 5. セキュリティ・非機能

| 項目 | 内容 |
|---|---|
| 認証・認可 | Sa-Token + `@SaCheckPermission`。データ権限は SQL 強制 |
| 入力検証 | Bean Validation + 業務チェック。数値は `BigDecimal` で精度検証 |
| 冪等 | 登録・過账・沖销・調整・月結・スキャン確定に `Idempotency-Key` 必須 |
| 監査 | 更新系・過账・沖销・調整・月結・出力を `sys_audit_log` に記録 |
| 性能 | 一覧 2 秒以内、可用量照会 200ms 以内、過账 500ms 以内（P95）、月結 30 分以内（[00-overview](00-overview.md) 1.3） |
| レート制限 | 内部 API は既定なし。PDA は端末単位 60 req/分（第一版 で制限） |
| エラー形式 | `Result` の `code/message/data.fieldErrors[]`（[03 §5](../00-common/03-common-api-spec.md)） |

---

## 6. 改訂履歴

| 版数 | 日付 | 変更内容 | 変更者 |
|---|---|---|---|
| v1.0 | 2026-10-20 | 初版：API 95 件の一覧、在庫照会・入出庫・沖销・調撥・棚卸・状態変換・原価・予約・PDA・月結の契約、コード対応表 | inventory-designer |
| v1.1 | 2026-10-20 | 红队第 2 轮：E15/E24 消費ルールと E18 `stockDocId/stockDocNo` 返却を §3.14 に追記。`lines[].stockStatus` の値域を 10=待検/20=可用へ改訂 | inventory-designer |
