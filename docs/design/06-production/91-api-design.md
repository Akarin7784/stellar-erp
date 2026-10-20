# 生产管理域 API 设计书（生産管理 API 設計書）

| 項目 | 内容 |
|---|---|
| 文書名 | 生产管理域 API 设计书（生産管理 API 設計書） |
| 文書番号 | DSN-PRD-091 |
| 版数 | v1.0 |
| 作成日 | 2026-10-20 |
| 作成者 | production-designer |
| 承認者 | 未承認（レビュー待ち） |
| 状態 | ドラフト（レビュー中） |
| 関連文書 | [业务域概要](00-overview.md) / [API 共通规格](../00-common/03-common-api-spec.md) / [消息一览](93-messages.md) / [DB 设计](90-db-design.md) / [BOM・工艺](01-bom-routing-workcenter.md) / [生产订单](02-work-order.md) / [領料・報工](03-material-issue-reporting.md) / [委外](04-outsourcing.md) / [MRP](05-mrp-planning.md) / [质量](06-quality-management.md) |

---

## 1. 基本仕様

[API 共通规格](../00-common/03-common-api-spec.md)（DSN-CMN-003）を全面的に適用する。本域固有の事項のみ以下に定める。

| 項目 | 内容 |
|---|---|
| パス接頭辞 | `/api/production`（内部）。外部公開は `/api/open/v1/production` |
| 認証 | `Authorization: {Sa-Token}`（[03](../00-common/03-common-api-spec.md) 3 章） |
| レスポンス | `Result<T>`（`code=0` 成功）。一覧は `PageResult<T>` |
| ID・数量・金額 | 文字列で返す（`"1845678901234567890"`、`"120.0000"`、`"778.200000"`） |
| 日付 | `yyyy-MM-dd`。日時は ISO 8601（`+08:00`） |
| エラーコード | `60000 + MSG-PRD-NNN`（例：`MSG-PRD-030` → `60030`、`MSG-PRD-056` → `60056`）。**業務拒否はドメインコード**（422）。共通 **4002 は 409/状態競合のみ**。テナント／会社パラメータ欠落は **5000**。入力・権限の共通コードは [03](../00-common/03-common-api-spec.md) 6 章 |
| HTTP ステータス | 400 入力、403 権限、404 不存在、409 状態競合・楽観排他、422 業務ルール違反、202 非同期受付 |
| 冪等 | 登録系 POST・状態操作に `Idempotency-Key` ヘッダ必須（[03](../00-common/03-common-api-spec.md) 9 章） |
| 楽観排他 | 更新系は `version` 必須。競合は 409 + `code=4003` |
| 非同期ジョブ | MRP 実行・一括転送・エクスポートは 202 + `jobId`。`GET /api/production/jobs/{jobId}` で進捗、`DELETE` で取消（[03](../00-common/03-common-api-spec.md) 12 章） |
| OpenAPI | `tags`: `Production - BOM` / `Production - Work Order` / `Production - MRP` / `Production - Quality` 等。`operationId`: `productionWorkOrderCreate` 形式 |

## 2. API 一覧

### 2.1 BOM・工艺路线・工作中心（F-PRD-001〜004）

| # | メソッド | パス | 権限 | 概要 | 関連機能 |
|---|---|---|---|---|---|
| 1 | GET | `/api/production/boms` | `production:bom:view` | BOM 一覧 | F-PRD-001 |
| 2 | GET | `/api/production/boms/{id}` | 同上 | BOM 詳細（明細・替代料） | F-PRD-001 |
| 3 | POST | `/api/production/boms` | `production:bom:update` | BOM 登録 | F-PRD-001 |
| 4 | PUT | `/api/production/boms/{id}` | 同上 | BOM 変更 | F-PRD-001 |
| 5 | POST | `/api/production/boms/{id}/submit` | 同上 | 承認提出 | F-PRD-001 |
| 6 | POST | `/api/production/boms/{id}/copy` | 同上 | 新版本コピー | F-PRD-001 |
| 7 | POST | `/api/production/boms/{id}/obsolete` | 同上 | 廃止 | F-PRD-001 |
| 8 | GET | `/api/production/boms/compare` | `production:bom:view` | BOM 比較 | F-PRD-001 |
| 9 | GET | `/api/production/boms/effective` | `production:bom:view` | 有効 BOM の解決（パラメータ `materialId`・`factoryId`・`date`（すべて必須）。詳細 §3.12） | F-PRD-002 |
| 10 | GET | `/api/production/boms/{id}/explode` | 同上 | 多階展開 | F-PRD-002 |
| 11 | GET | `/api/production/boms/{id}/cost-rollup` | `production:bom:view`（原価権限推奨） | 成本卷算 | F-PRD-002 |
| 12 | GET | `/api/production/routings` | `production:routing:view` | 工艺路線一覧 | F-PRD-003 |
| 13 | GET | `/api/production/routings/{id}` | 同上 | 工艺路線詳細 | F-PRD-003 |
| 14 | POST | `/api/production/routings` | `production:routing:update` | 工艺路線登録 | F-PRD-003 |
| 15 | PUT | `/api/production/routings/{id}` | 同上 | 工艺路線変更 | F-PRD-003 |
| 16 | GET | `/api/production/work-centers` | `production:work-center:view` | 工作中心一覧 | F-PRD-004 |
| 17 | POST | `/api/production/work-centers` | `production:work-center:update` | 工作中心登録 | F-PRD-004 |
| 18 | PUT | `/api/production/work-centers/{id}` | 同上 | 工作中心変更 | F-PRD-004 |
| 19 | GET | `/api/production/work-centers/{id}/calendar` | `production:work-center:view` | 工作日历取得 | F-PRD-004 |
| 20 | POST | `/api/production/work-centers/{id}/calendar` | `production:work-center:update` | 工作日历一括登録 | F-PRD-004 |
| 21 | GET | `/api/production/equipments` | `production:equipment:view` | 設備一覧 | F-PRD-018 |
| 22 | POST | `/api/production/equipments` | `production:equipment:update` | 設備登録 | F-PRD-018 |

### 2.2 生产订单（F-PRD-005）

| # | メソッド | パス | 権限 | 概要 | 関連機能 |
|---|---|---|---|---|---|
| 23 | GET | `/api/production/work-orders` | `production:work-order:view` | 工单一覧 | F-PRD-005 |
| 24 | GET | `/api/production/work-orders/{id}` | 同上 | 工单詳細 | F-PRD-005 |
| 25 | GET | `/api/production/work-orders/by-no/{no}` | 同上 | 工单番号検索（PDA） | F-PRD-005 |
| 26 | POST | `/api/production/work-orders` | `production:work-order:create` | 工单登録 | F-PRD-005 |
| 27 | PUT | `/api/production/work-orders/{id}` | `production:work-order:update` | 工单変更 | F-PRD-005 |
| 28 | POST | `/api/production/work-orders/{id}/submit` | `production:work-order:submit` | 承認提出（10→20。詳細 §3.10） | F-PRD-005 |
| 28a | POST | `/api/production/work-orders/{id}/approve` | `production:work-order:approve`（TODO：権限チェック未実装） | 承認（20→25。08 WF E32 コールバックと同一サービス。詳細 §3.11） | F-PRD-005 |
| 29 | POST | `/api/production/work-orders/{id}/release` | `production:work-order:release` | 下达（E21） | F-PRD-005 |
| 30 | POST | `/api/production/work-orders/batch-release` | 同上 | 一括下达 | F-PRD-005 |
| 31 | POST | `/api/production/work-orders/{id}/split` | 同上 | 拆分 | F-PRD-005 |
| 32 | POST | `/api/production/work-orders/merge` | 同上 | 合并 | F-PRD-005 |
| 33 | POST | `/api/production/work-orders/{id}/explode-bom` | `production:work-order:update` | BOM 再展開 | F-PRD-005 |
| 34 | POST | `/api/production/work-orders/{id}/hold` | 同上 | 保留/解除 | F-PRD-005 |
| 35 | POST | `/api/production/work-orders/{id}/cancel` | `production:work-order:cancel` | 取消 | F-PRD-005 |
| 36 | POST | `/api/production/work-orders/{id}/close` | `production:work-order:close` | 結案 | F-PRD-005/020 |
| 37 | GET | `/api/production/work-orders/{id}/materials` | `production:work-order:view` | 材料明細 | F-PRD-005 |
| 38 | GET | `/api/production/work-orders/{id}/operations` | 同上 | 工序明細 | F-PRD-005 |
| 39 | GET | `/api/production/work-orders/{id}/progress` | 同上 | 進捗（報工/入庫/検査） | F-PRD-005/016 |

### 2.3 領料・報工・完工入库（F-PRD-006〜008）

| # | メソッド | パス | 権限 | 概要 | 関連機能 |
|---|---|---|---|---|---|
| 40 | GET | `/api/production/material-issues` | `production:material-issue:view` | 領料/退料一覧 | F-PRD-006 |
| 41 | POST | `/api/production/material-issues` | `production:material-issue:create` | 領料/退料**要求**の登録・確定（E22/E36）。MII/MIR 伝票は INV 採番 | F-PRD-006 |
| 42 | POST | `/api/production/material-issues/{id}/cancel` | `production:material-issue:reverse` | 領料取消 | F-PRD-006 |
| 43 | GET | `/api/production/work-reports` | `production:work-report:view` | 報工一覧 | F-PRD-007 |
| 44 | POST | `/api/production/work-reports` | `production:work-report:create` | 報工登録（草稿/提出） | F-PRD-007 |
| 45 | POST | `/api/production/work-reports/{id}/approve` | `production:work-report:approve` | 報工審核確定（E23、倒冲） | F-PRD-007 |
| 46 | POST | `/api/production/work-reports/{id}/cancel` | `production:work-report:approve` | 報工取消 | F-PRD-007 |
| 47 | GET | `/api/production/completion-receipts` | `production:completion:view` | 完工入库一覧 | F-PRD-008 |
| 48 | POST | `/api/production/completion-receipts` | `production:completion:create` | 完工入库**要求**確定（E24、INV FGI 採番） | F-PRD-008 |
| 49 | POST | `/api/production/completion-receipts/{id}/cancel` | `production:completion:create` | 入庫取消 | F-PRD-008 |
| 50 | GET | `/api/production/work-orders/{id}/completion-preview` | `production:completion:view` | 入庫プレビュー（残数・単価） | F-PRD-008 |

### 2.4 委外（F-PRD-009）

| # | メソッド | パス | 権限 | 概要 |
|---|---|---|---|---|
| 51 | GET | `/api/production/outsourcing-orders` | `production:outsourcing:view` | 委外訂单一覧 |
| 52 | GET | `/api/production/outsourcing-orders/{id}` | 同上 | 委外訂单詳細 |
| 53 | POST | `/api/production/outsourcing-orders` | `production:outsourcing:create` | 委外訂单登録 |
| 54 | POST | `/api/production/outsourcing-orders/{id}/submit` | 同上 | 承認提出 |
| 55 | POST | `/api/production/outsourcing-orders/{id}/order` | 同上 | 発注 |
| 56 | POST | `/api/production/outsourcing-orders/{id}/cancel` | 同上 | 取消 |
| 57 | GET | `/api/production/outsourcing-orders/{id}/supply-materials` | `production:outsourcing:view` | 支給材料展開 |
| 58 | POST | `/api/production/outsourcing-issues` | `production:outsourcing:create` | 委外発料（E25） |
| 59 | POST | `/api/production/outsourcing-receipts` | 同上 | 委外受入（E26） |
| 60 | POST | `/api/production/outsourcing-receipts/{id}/cancel` | 同上 | 受入取消 |
| 61 | POST | `/api/production/outsourcing-settlements` | `production:outsourcing:settle` | 加工費結算 |
| 62 | POST | `/api/production/outsourcing-settlements/{id}/approve` | `production:outsourcing:approve` | 結算承認 |
| 63 | GET | `/api/production/outsourcing-orders/supplier-stock` | `production:outsourcing:view` | 委外先支給材料残 |

### 2.5 MRP・計画（F-PRD-010/011）

| # | メソッド | パス | 権限 | 概要 |
|---|---|---|---|---|
| 64 | POST | `/api/production/mrp-runs` | `production:mrp:run` | MRP 実行（202 非同期） |
| 65 | GET | `/api/production/mrp-runs` | `production:mrp:view` | MRP 実行履歴 |
| 66 | GET | `/api/production/mrp-runs/{id}` | 同上 | 実行結果サマリ |
| 67 | GET | `/api/production/mrp-runs/{id}/demands` | 同上 | 需求・净需求一覧 |
| 68 | GET | `/api/production/mrp-runs/{id}/plan-orders` | 同上 | 計画订单一覧 |
| 69 | GET | `/api/production/mrp-runs/{id}/actions` | 同上 | 動作消息一覧 |
| 70 | POST | `/api/production/mrp-plan-orders/batch-confirm` | `production:mrp:confirm` | 計画订单一括確認 |
| 71 | POST | `/api/production/mrp-plan-orders/{id}/convert-to-work-order` | `production:mrp:confirm` | 工单へ転送 |
| 72 | POST | `/api/production/mrp-plan-orders/{id}/convert-to-requisition` | `production:mrp:confirm` | 請購へ転送（PUR） |
| 73 | POST | `/api/production/mrp-plan-orders/{id}/convert-to-outsourcing` | `production:mrp:confirm` | 委外訂单へ転送 |
| 74 | POST | `/api/production/mrp-actions/{id}/ignore` | `production:mrp:confirm` | 動作消息を無視 |
| 75 | GET | `/api/production/mps` / `POST` | `production:plan:update` | MPS 一覧・登録 |
| 76 | GET | `/api/production/capacity-load` | `production:plan:update` | 粗能力（負荷率） |
| 77 | GET | `/api/production/forecasts` / `POST` | `production:plan:update` | 需求予測 |

### 2.6 品質（F-PRD-012〜015）

| # | メソッド | パス | 権限 | 概要 |
|---|---|---|---|---|
| 78 | GET | `/api/production/inspection-standards` | `production:inspection-standard:view` | 検査標準一覧 |
| 79 | POST | `/api/production/inspection-standards` | `production:inspection-standard:update` | 検査標準登録 |
| 80 | PUT | `/api/production/inspection-standards/{id}` | 同上 | 検査標準変更 |
| 81 | GET | `/api/production/inspection-standards/effective` | `production:inspection:view` | 適用標準の解決 |
| 82 | GET | `/api/production/inspections` | `production:inspection:view` | 検査一覧 |
| 83 | POST | `/api/production/inspections` | `production:inspection:create` | 検査起票 |
| 84 | PUT | `/api/production/inspections/{id}` | 同上 | 検査結果登録 |
| 85 | POST | `/api/production/inspections/{id}/judge` | `production:inspection:judge` | 判定確定（E15） |
| 86 | POST | `/api/production/inspections/batch-judge` | 同上 | 一括判定 |
| 87 | POST | `/api/production/inspections/{id}/cancel` | `production:inspection:judge` | 検査取消 |
| 88 | GET | `/api/production/ncrs` / `POST` | `production:ncr:create` | NCR 一覧・起票 |
| 89 | POST | `/api/production/ncrs/{id}/submit` | `production:ncr:create` | NCR 提出 |
| 90 | POST | `/api/production/ncrs/{id}/execute` | `production:ncr:create` | 処置実行 |
| 91 | POST | `/api/production/ncrs/{id}/close` | `production:ncr:create` | NCR 完了 |
| 92 | GET | `/api/production/defect-codes` | `production:inspection:view` | 缺陷コード一覧 |
| 93 | GET | `/api/production/traceability/reverse` | `production:trace:view` | 逆追溯 |
| 94 | GET | `/api/production/traceability/forward` | 同上 | 順追溯 |
| 95 | GET | `/api/production/traceability/work-order/{id}` | 同上 | 工单追溯 |

### 2.7 看板・レポート・ジョブ

| # | メソッド | パス | 権限 | 概要 |
|---|---|---|---|---|
| 96 | GET | `/api/production/dashboard/summary` | `production:dashboard:view` | 看板 KPI・チャート |
| 97 | GET | `/api/production/dashboard/lists` | 同上 | 遅延・欠品・NCR・保留リスト |
| 98 | GET | `/api/production/reports/work-hours` | `production:report:view` | 工数・能率集計 |
| 99 | POST | `/api/production/exports` | `production:report:export` | 非同期エクスポート |
| 100 | GET | `/api/production/jobs/{jobId}` | 認証済 | ジョブ状態 |
| 101 | GET | `/api/production/jobs/{jobId}/files/{fileId}` | 同上 | 結果ファイル取得 |
| 102 | DELETE | `/api/production/jobs/{jobId}` | 同上 | ジョブ取消 |

## 3. API 詳細（主要エンドポイント）

### 3.1 POST `/api/production/work-orders`（工单登録）

| 項目 | 内容 |
|---|---|
| 目的 | 手動または計画订单から工单を作成し、BOM・工艺を展開する |
| 権限 | `production:work-order:create` |
| 冪等 | `Idempotency-Key` 必須 |
| トランザクション | 工单・材料・工序・変更履歴・監査ログを 1 トランザクション |
| 関連テーブル | `prd_work_order`・`prd_work_order_material`・`prd_work_order_operation`・`sys_sequence`・`sys_audit_log` |

**リクエスト**

```json
{
  "workOrderType": 10,
  "factoryId": "1845000000000000100",
  "materialId": "1845000000000000301",
  "orderQty": "120.0000",
  "uomCode": "PCE",
  "plannedStartDate": "2026-11-12",
  "plannedEndDate": "2026-11-17",
  "priorityNo": 5,
  "warehouseId": "1845000000000000203",
  "salesOrderId": "1845678901234567000",
  "isBackflush": true,
  "createChildWo": false,
  "remark": "YE3-100L1-4 受注分（SO2610200001）"
}
```

**レスポンス（201）**

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "id": "1845678901234567890",
    "workOrderNo": "WO2610200001",
    "orderStatus": 10,
    "statusName": "草稿",
    "materialCode": "3001000001",
    "materialName": "YE3-100L1-4 三相异步电动机",
    "orderQty": "120.0000",
    "plannedStartDate": "2026-11-12",
    "plannedEndDate": "2026-11-17",
    "standardCost": "778.200000",
    "materials": [
      { "lineNo": 10, "materialCode": "2001000004", "materialName": "定子总成", "totalRequiredQty": "120.6030", "uomCode": "PCE" },
      { "lineNo": 20, "materialCode": "2002000004", "materialName": "转子总成", "totalRequiredQty": "120.6030", "uomCode": "PCE" }
    ],
    "operations": [
      { "operationSeq": 110, "operationName": "总装", "workCenterCode": "WC008", "plannedStartDate": "2026-11-12", "plannedEndDate": "2026-11-13" },
      { "operationSeq": 120, "operationName": "出厂试验", "workCenterCode": "WC009", "plannedStartDate": "2026-11-14", "plannedEndDate": "2026-11-14" }
    ],
    "version": 0
  }
}
```

**有効 BOM なし**：登録は成功（201、材料明細 0 件）し、`data.warnings[]` に `{ "code": 60020, "message": "有効な BOM がありません。BOM を登録・承認してください。" }`（MSG-PRD-020）を含める。下达時のみエラー（§3.2）（蓝色大肥鱼 2026-10-21 #36 決定）。BOM 基準日は `plannedStartDate`、未指定時は会社のタイムゾーンの当日（現時点では Asia/Shanghai）。

**エラー例（下达時 BOM なし。§3.2）**

```json
{
  "code": 60020,
  "message": "有効な BOM がありません。BOM を登録・承認してください。",
  "data": null
}
```

### 3.2 POST `/api/production/work-orders/{id}/release`（下达）

| 項目 | 内容 |
|---|---|
| 目的 | 工单を 25→30 に遷移し、材料引当 E21 を発行する |
| 権限 | `production:work-order:release` |
| 事前条件 | `order_status=25`、`is_hold=false`、有効 BOM あり（基準日＝計画着手日、未入力時は会社タイムゾーン当日。なしは 422／`60020`／`MSG-PRD-020`（蓝色大肥鱼 2026-10-21 #36 決定）） |
| イベント | `production.workorder.released`（E21）を Outbox に記録 |
| 排他 | 工单行ロック（`FOR UPDATE`、3 秒待ち） |

**リクエスト**

```json
{ "version": 1, "releaseDate": "2026-11-12", "reservationMode": 20, "shortageAction": 10 }
```

**レスポンス（200・引当不足の警告付き）**

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "workOrderNo": "WO2610200001",
    "orderStatus": 30,
    "statusName": "下达済",
    "releasedAt": "2026-11-12T09:00:00+08:00",
    "warnings": [
      { "code": 60045, "message": "一部材料の引当が不足しています。不足分は補充手配が必要です。",
        "shortages": [{ "materialCode": "2001000004", "requiredQty": "120.6030", "reservedQty": "90.0000", "shortageQty": "30.6030" }] }
    ]
  }
}
```

警告：標準原価の発行版がない場合は `data.warnings[]` に `{ "code": 70117, "message": "未设定标准成本，本期不进行成本差异分析。" }`（MSG-FIN-117）を含め、下达は成功（200）。

**エラー例（状態不整合）**：HTTP 409、`{"code":4002,"message":"該当データは現在の状態ではこの操作を実行できません。"}`

**エラー例（下达日が過去日）**：HTTP 422、`{"code":60104,"message":"下达日不能早于今天。"}`（MSG-PRD-104。`releaseDate` < Asia/Shanghai 当日）

### 3.3 POST `/api/production/material-issues`（領料確定・E22）

| 項目 | 内容 |
|---|---|
| 目的 | 工单材料の払出要求（倒冲含む）は E22、退料要求は E36 を発行する。MII/MIR 伝票の採番・在庫処理は INV が単一所有（PRD は `request_no` のみ、`stock_doc_no` は E18 で受領） |
| 権限 | `production:material-issue:create` |
| 事前条件 | 工单 30/35、保留でない、未領数量 ≥ 領料数量（超領は承認） |
| 冪等 | `Idempotency-Key` 必須（E22 の二重発行防止） |

**リクエスト**

```json
{
  "issueType": 10,
  "workOrderId": "1845678901234567890",
  "issueDate": "2026-11-12",
  "warehouseId": "1845000000000000202",
  "sourceType": 10,
  "lines": [
    { "workOrderMaterialId": "1845678901234567901", "issueQty": "120.0000", "batchNo": "261105M001" },
    { "workOrderMaterialId": "1845678901234567902", "issueQty": "120.0000", "batchNo": "261105M002" }
  ]
}
```

**レスポンス（201）**

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "id": "1845678901234568801",
    "requestNo": "REQ2611120001", "stockDocNo": null,
    "issueType": 10,
    "issueStatus": 30,
    "statusName": "確定済",
    "totalQty": "240.0000",
    "totalAmount": "53,520.00",
    "lines": [
      { "lineNo": 10, "materialCode": "2001000004", "issueQty": "120.0000", "unitCost": "252.000000", "amount": "30240.00" }
    ],
    "e22PublishedAt": "2026-11-12T09:30:01+08:00"
  }
}
```

### 3.4 POST `/api/production/work-reports/{id}/approve`（報工確定・E23）

| 項目 | 内容 |
|---|---|
| 目的 | 報工を確定し、良品・不良・报废・工数を工单へ反映、E23 を発行、倒冲を実行する |
| 権限 | `production:work-report:approve` |
| 事前条件 | `report_status=20`、数量整合、検査点の前工程合格 |
| 副作用 | 工单累計・進捗率・人工費・製造費用の更新、IPQC 起票、倒冲 MII 生成 |

**リクエスト**

```json
{ "version": 0, "comment": "11/15 総装完了分" }
```

**レスポンス（200）**

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "reportNo": "WR2611150001",
    "reportStatus": 40,
    "statusName": "確定済",
    "workOrderNo": "WO2610200001",
    "operationSeq": 110,
    "goodQty": "120.0000",
    "defectQty": "2.0000",
    "laborHours": "71.25",
    "laborAmount": "1781.25",
    "overheadAmount": "2137.50",
    "backflushIssueNo": "MII2611150002",
    "e23PublishedAt": "2026-11-15T17:25:00+08:00"
  }
}
```

### 3.5 POST `/api/production/completion-receipts`（完工入库・E24）

**リクエスト**

```json
{
  "workOrderId": "1845678901234567890",
  "receiptType": 10,
  "receiptDate": "2026-11-18",
  "warehouseId": "1845000000000000203",
  "lines": [{ "receiptQty": "120.0000", "batchNo": "261118M001" }]
}
```

**レスポンス（201）**

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "requestNo": "REQ2611180001", "stockDocNo": null,
    "receiptStatus": 30,
    "totalQty": "120.0000",
    "totalAmount": "93377.55",
    "isLastReceipt": true,
    "unitCost": "778.146250",
    "e24PublishedAt": "2026-11-18T10:00:01+08:00",
    "warning": null
  }
}
```

### 3.6 POST `/api/production/mrp-runs`（MRP 実行）

**リクエスト**

```json
{
  "factoryId": "1845000000000000100",
  "runDate": "2026-10-20",
  "horizonDays": 90,
  "bucketType": 10,
  "runType": 10,
  "includeForecast": true,
  "includeSafetyStock": true,
  "includeSalesOrder": true
}
```

**レスポンス（202・非同期）**

```json
{ "code": 0, "message": "ok", "data": { "jobId": "job-20261020-0001", "mrpRunNo": "MRP261020001", "status": "QUEUED" } }
```

**ジョブ状態（GET `/api/production/jobs/{jobId}`）**

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "jobId": "job-20261020-0001",
    "status": "SUCCEEDED",
    "progress": 100,
    "result": { "mrpRunNo": "MRP261020001", "demandCount": 1820, "planOrderCount": 143, "actionCount": 57, "errorCount": 0 }
  }
}
```

### 3.7 POST `/api/production/inspections/{id}/judge`（判定・E15）

**リクエスト**

```json
{
  "version": 1,
  "result": 20,
  "comment": "耐電圧試験で絶縁破壊。NCR を起票します。",
  "lines": [
    { "itemSeq": 10, "measuredValue": "1520", "judge": 20 },
    { "itemSeq": 20, "measuredText": "絶縁破壊（1,200V で発生）", "judge": 20 }
  ]
}
```

**レスポンス（200）**

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "inspectionNo": "FQC2611150001",
    "inspectionStatus": 30,
    "result": 20,
    "judgedAt": "2026-11-15T16:40:00+08:00",
    "ncrNo": "NCR2611150001",
    "e15PublishedAt": "2026-11-15T16:40:01+08:00"
  }
}
```

### 3.8 GET `/api/production/traceability/reverse`（逆追溯）

**リクエスト**：`?lotNo=261118M001`（または `serialNo=2611181000001`）

**レスポンス（200・抜粋）**

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "root": { "type": "PRODUCT_LOT", "lotNo": "261118M001", "materialCode": "3001000001", "materialName": "YE3-100L1-4" },
    "nodes": [
      { "depth": 1, "workOrderNo": "WO2610200001", "operationSeq": 110, "inputMaterialCode": "2001000004", "inputMaterialName": "定子总成", "inputLotNo": "261105M001", "qty": "120.0000" },
      { "depth": 2, "workOrderNo": "WO2611020003", "operationSeq": 70, "inputMaterialCode": "1004000001", "inputMaterialName": "QZY-2/180 φ1.00", "inputLotNo": "261020P001", "qty": "326.5400" }
    ],
    "totalLinks": 2,
    "truncated": false
  }
}
```

### 3.9 GET `/api/production/dashboard/summary`（看板）

**リクエスト**：`?factoryId=...&period=2026-11`

**レスポンス（200・抜粋）**

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "factoryCode": "CZ01",
    "period": "2026-11",
    "lastUpdated": "2026-11-15T17:35:00+08:00",
    "kpis": [
      { "code": "KPI-PRD-01", "name": "计划达成率", "value": "96.20", "unit": "%", "target": "95.00" },
      { "code": "KPI-PRD-03", "name": "良品率", "value": "99.10", "unit": "%", "target": "98.50" },
      { "code": "KPI-PRD-09", "name": "能力負荷率", "value": "92.00", "unit": "%", "target": "100.00" }
    ],
    "charts": { "dailyOutput": [{ "date": "2026-11-14", "actual": "1180", "plan": "1200" }] }
  }
}
```

### 3.10 POST `/api/production/work-orders/{id}/submit`（承認提出）

| 項目 | 内容 |
|---|---|
| 目的 | 工单を 10（起票）→20（承認中）に遷移する |
| 権限 | `production:work-order:submit`（02-work-order.md T-01 と統一） |
| リクエスト | `{ "version": 3 }` |
| 正常 | 200 + 工单 DTO（`orderStatus=20`、`version`+1） |
| エラー | `4003`（409、`version` 不一致）／`4002`（409、状態が 10 以外）／`1001`（400、材料明細なし）。有効 BOM は要求しない（`60020` を返さない（蓝色大肥鱼 2026-10-21 #36 決定）） |

### 3.11 POST `/api/production/work-orders/{id}/approve`（承認）

| 項目 | 内容 |
|---|---|
| 目的 | 工单を 20（承認中）→25（承認済）に遷移する |
| 権限 | `production:work-order:approve`（02-work-order.md T-02。TODO：権限チェックは未実装） |
| 呼出元 | 08 工作流の E32 承認完了コールバックと**同一のサービスメソッド**を呼ぶ。08（Flowable）接入後は本 API を閉じ、E32 コールバックからのみ遷移可能とする（蓝色大肥鱼 2026-10-21 決定、PR #32）。**Flowable 接入前の暫定入口**であり、統一入口は [08/91 #33](../08-workflow/91-api-design.md) `POST /api/workflow/tasks/{taskId}/approve`。接入後は廃止またはコールバック専用とする |
| リクエスト | `{ "version": 4 }` |
| 正常 | 200 + 工单 DTO（`orderStatus=25`、`version`+1） |
| エラー | `60005`（422、`MSG-PRD-005`：起案者＝承認者）／`4003`（409、`version` 不一致）／`4002`（409、状態が 20 以外） |

### 3.12 GET `/api/production/boms/effective`（有効 BOM の解決）

| パラメータ | 必須 | 内容 |
|---|---|---|
| `materialId` | ○ | 親品目 ID |
| `factoryId` | ○ | 工厂 ID（BOM は工厂別。`prd_bom.factory_id` NOT NULL）。工单画面からは工单の工厂を渡す。欠落は 400／`1001` |
| `date` | ○ | 基準日。工单から呼ぶ場合は `plannedStartDate`、未入力なら会社のタイムゾーンの当日（現時点では Asia/Shanghai）（蓝色大肥鱼 2026-10-21 #36 決定） |

- 命中規則：`bom_status=30` かつ基準日が有効期間内の BOM。複数命中時は `is_default=TRUE` を優先し、次に版本号の最大、最後に `id DESC` で 1 件に確定。該当なしは `60020`（422、`MSG-PRD-020`）。
- 会社は当前会社で絞り込む。

## 4. エラーコード対応表（本域の主要コード）

| code | HTTP | 対応 MSG | 意味 |
|---|---|---|---|
| 1001 | 400 | `MSG-COM-040`〜`052` | 入力・バリデーションエラー（共通） |
| 2001 | 401 | `MSG-COM-020` | 未認証・期限切れ |
| 3001 | 403 | `MSG-COM-030` | 操作権限なし |
| 3002 | 403 | `MSG-COM-031` | データ参照権限なし |
| 4002 | 409 | `MSG-COM-034` | 状態不整合 |
| 4003 | 409 | `MSG-COM-033` | 楽観排他競合 |
| 4005 | 409 | `MSG-COM-035`/`075` | 二重処理・処理中 |
| 5000 | 500 | `MSG-COM` / 設定不備 | テナント未設定・`sys_param.prd.completion_over_rate` 欠落、または予期せぬシステムエラー（trace_id） |
| 60005 | 422 | `MSG-PRD-005` | 起案者と承認者が同一（工单承認） |
| 60010 | 422 | `MSG-PRD-010` | BOM 循環参照 |
| 60011 | 422 | `MSG-PRD-011` | BOM 有効期間重複 |
| 60020 | 422 | `MSG-PRD-020` | 有効 BOM なし（エラーは下达のみ。登録・提出は警告） |
| 60001 | 422 | `MSG-PRD-001` | 製造品ではありません（品目が制造/委外の計画行を持たない場合も含む。判定は `prd_material_planning.material_type ∈ {20,30}`） |
| 60021 | 422 | `MSG-PRD-021` | 有効工艺路線なし |
| 60027 | 409 | `MSG-PRD-027` | 計画订单の二重転送 |
| 60029 | 409 | `MSG-PRD-029` | MRP 実行中 |
| 60030 | 422 | `MSG-PRD-030` | 領料上限超過／材料不一致 |
| 60032 | 422 | `MSG-PRD-032` | 報工数量不整合 |
| 60040 | 422 | `MSG-PRD-040` | `allowed_qty` ハード超過（MTS／承認後も超過）。MTO 未承認は 60100 優先 |
| 60045 | 422（警告） | `MSG-PRD-045` | 引当不足（続行可） |
| 60046 | 422 | `MSG-PRD-046` | 実績あり取消不可 |
| 60047 | 422 | `MSG-PRD-047` | 保留中の操作 |
| 60048 | 422 | `MSG-PRD-048` | 拆分合計不一致 |
| 60056 | 422 | `MSG-PRD-056` | 工单品目 ≠ 受注行品目（G2-18） |
| 60100 | 422 | `MSG-PRD-100` | 超産承認が必要 |
| 60101 | 422 | `MSG-PRD-101` | 超産承認無効 |
| 60102 | 422 | `MSG-PRD-102` | 冲销数量 > completed_qty |
| 60103 | 422 | `MSG-PRD-103` | 超産申請数量不正（`request_qty` ≤ 0 または NULL） |
| 60104 | 422 | `MSG-PRD-104` | 下达日不能早于今天（上海时间）（`releaseDate` が Asia/Shanghai 当日より前） |
| 60060 | 422 | `MSG-PRD-060` | 検査未合格で次工程不可 |
| 60062 | 422 | `MSG-PRD-062` | FQC 未合格で入庫不可 |
| 60064 | 422 | `MSG-PRD-064` | 特采・报废の承認必要 |
| 60065 | 422 | `MSG-PRD-065` | NCR 処置数量不一致 |
| 60075 | 422 | `MSG-PRD-075` | 結案条件未達 |
| 60080 | 422 | `MSG-PRD-080` | 委外超過受入 |
| 60083 | 422 | `MSG-PRD-083` | IQC 未合格で入庫不可 |
| 60086 | 422 | `MSG-PRD-086` | 支給材料在庫不足 |

## 5. 冪等性・排他・再実行

| 対象 API | 冪等キー | 競合時 | 備考 |
|---|---|---|---|
| 工单登録・領料・報工・入庫・委外発料/受入・MRP 実行 | `Idempotency-Key`＋業務キー（例：工单番号＋材料行） | 同一キー 24 時間は初回結果を返す | E22/E23/E24/E25/E26 の二重発行防止 |
| 状態操作（release/submit/judge/cancel） | `Idempotency-Key`＋`version` | 409 + `code=4003` | 同時承認・同時取消の防止 |
| 一括処理（batch-release/batch-judge/batch-confirm） | `Idempotency-Key` | 全件成功 or 全件失敗 | 上限 1,000 件、超過は非同期 |
| 計画订单の転送 | 行ロック＋`converted_doc_id IS NULL` 条件 | 409 + `code=60027` | 二重転送防止 |
| MRP 実行 | `pg_advisory_lock(mrp:{factoryId})` | 409 + `code=60029` | 同一工場の同時実行防止 |

## 6. セキュリティ・監査

| 項目 | 内容 |
|---|---|
| 権限 | 全 API に `@SaCheckPermission`。データ範囲は SQL 強制適用 |
| 監査ログ | 登録・変更・状態操作・出力を `sys_audit_log` に記録（`operation_type`、before/after、trace_id） |
| マスキング | 原価・工賃率は権限なしで非返却。個人情報（作業者名）は必要最小限 |
| レート制限 | 外部公開 API は [03](../00-common/03-common-api-spec.md) 14 章 |
| CSRF/XSS | Authorization ヘッダ方式・JSON のみ（HTML 返却なし） |

## 7. 改訂履歴

| 版数 | 日付 | 変更内容 | 変更者 |
|---|---|---|---|
| v1.0 | 2026-10-20 | 初版：基本仕様、API 102 件の一覧、主要 9 API のリクエスト/レスポンス例、エラーコード対応表、冪等・排他・セキュリティ | production-designer |
| v1.1 | 2026-10-21 | §4 に `60001`／`MSG-PRD-001` を追加（#18 決定 6） | 业务分析 |
| v1.2 | 2026-10-21 | §3.2 下达の警告に 70117／MSG-FIN-117 を追記 | 业务分析 |
| v1.3 | 2026-10-21 | §3.2・§4 に 60104／MSG-PRD-104（422、下达日過去日）を追加（蓝色大肥鱼 2026-10-21 承認） | 业务分析 |
| v1.4 | 2026-10-21 | §2.2 に #28a 工单承認 API を追加、§3.10 承認提出・§3.11 承認・§3.12 有効 BOM 解決（`factoryId` 必須・欠落 1001、命中規則 is_default→版本号→id DESC）を追加、§4 に 60005 を追加、#28 submit の権限を `production:work-order:submit` に統一（蓝色大肥鱼 2026-10-21 PR #32 決定） | 业务分析 |
| v1.5 | 2026-10-21 | §3.1 BOM なしを警告（登録成功）に変更・BOM 基準日を明記、§3.2 下达の事前条件に有効 BOM（なし 60020）を追加、§3.10 提出は BOM 不要と明記、§3.12 `date` の工单既定値、§4 60020 の意味を更新（蓝色大肥鱼 2026-10-21 #36 決定） | 业务分析 |
