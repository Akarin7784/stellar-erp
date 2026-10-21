# 采购管理 API 设计书（購買管理 API 設計書）

| 項目 | 内容 |
|---|---|
| 文書名 | 采购管理 API 设计书（購買管理 API 設計書） |
| 文書番号 | DSN-PUR-091 |
| 版数 | v1.0 |
| 作成日 | 2026-10-20 |
| 作成者 | purchase-designer |
| 承認者 | 未承認（レビュー待ち） |
| 状態 | ドラフト（レビュー中） |
| 関連文書 | [業務域概要](00-overview.md) / [API 共通規格](../00-common/03-common-api-spec.md) / [共通項目定義](../00-common/01-common-item-definitions.md) / [跨域流程](../00-common/09-cross-domain-flow.md) / [DB 設計](90-db-design.md) / [メッセージ](93-messages.md) |

---

## 1. 適用範囲と基本方針

本設計書は procurement 域（`/api/purchase/**`）の API と、本域が発行/購読する領域イベントの契約を定義する。共通仕様（パス形式・認証・`Result<T>`・エラーコード体系・ページング・冪等・楽観排他）は [03-common-api-spec.md](../00-common/03-common-api-spec.md) を正とし、本設計書では再定義しない。

| # | 方針 |
|---|---|
| 1 | パスは `/api/purchase/{resource}`（複数形・kebab-case）。状態操作は `POST /{id}/{action}` |
| 2 | 全 API は認証必須。権限は `purchase:{resource}:{action}` をサーバ側で検証（[00-overview](00-overview.md) §10） |
| 3 | 金額・数量・ID は文字列で返す（JS 精度対策、03 §8） |
| 4 | 登録・状態操作は `Idempotency-Key` 必須（03 §9）。更新系は `version` による楽観排他必須 |
| 5 | 一覧はサーバサイドページング必須。全件返却 API は作らない |
| 6 | 非同期処理（帳票・大量エクスポート）は `POST /api/purchase/exports` → `GET /api/purchase/jobs/{jobId}` |
| 7 | 業務エラーコードは 40000～49999 を使用し、`MSG-PUR-xxx` と対応付ける（§6） |
| 8 | 域間イベントは REST ではなく Outbox 経由（09 §10.1）。本設計書 §7 に payload 契約を定義 |

---

## 2. API 一覧

### 2.1 请购（F-PUR-001～003）

| # | メソッド | パス | 権限 | 概要 | リクエスト | レスポンス | 主なエラー | 関連機能 |
|---|---|---|---|---|---|---|---|---|
| 1 | GET | `/api/purchase/purchase-requisitions` | `purchase:requisition:view` | 一覧検索 | 検索条件 + `pageNum/pageSize/sort` | `PageResult<PurchaseRequisitionListDto>` | 3001/3002 | F-PUR-001 |
| 2 | GET | `/api/purchase/purchase-requisitions/{id}` | `purchase:requisition:view` | 詳細 | — | `PurchaseRequisitionDetailDto` | 4001/3002 | F-PUR-001 |
| 3 | POST | `/api/purchase/purchase-requisitions` | `purchase:requisition:create` | 登録 | `PurchaseRequisitionCreateDto` | 詳細（201） | 1001/40002 | F-PUR-001 |
| 4 | PUT | `/api/purchase/purchase-requisitions/{id}` | `purchase:requisition:update` | 更新（草稿） | `PurchaseRequisitionUpdateDto` + `version` | 詳細 | 4002/4003 | F-PUR-001 |
| 5 | POST | `/api/purchase/purchase-requisitions/{id}/submit` | `purchase:requisition:submit` | 提出 | `{version, comment?}` | 詳細 | 4002/80001 | F-PUR-002 |
| 6 | POST | `/api/purchase/purchase-requisitions/{id}/withdraw` | `purchase:requisition:submit` | 撤回 | `{version}` | 詳細 | 4002 | F-PUR-002 |
| 7 | POST | `/api/purchase/purchase-requisitions/{id}/cancel` | `purchase:requisition:cancel` | 取消 | `{version, reason}` | 詳細 | 4002/40072 | F-PUR-001 |
| 8 | POST | `/api/purchase/purchase-requisitions/{id}/close` | `purchase:requisition:convert` | 关闭 | `{version, reason}` | 詳細 | 4002 | F-PUR-003 |
| 9 | POST | `/api/purchase/purchase-requisitions/{id}/convert-to-orders` | `purchase:requisition:convert` | 转订单 | `ConvertToOrdersRequest` | `ConvertToOrdersResponse` | 40010/40011/40012 | F-PUR-003 |
| 10 | POST | `/api/purchase/purchase-requisitions/batch-submit` | `purchase:requisition:submit` | 一括提出 | `{ids[], comment?}` | `BatchResultDto` | 4002 | F-PUR-002 |
| 11 | POST | `/api/purchase/purchase-requisitions/{id}/print` | `purchase:requisition:print` | 請購単出력（PRT-PUR-001） | `{}` | PDF（200） | 4001 | F-PUR-001 |
| 12 | GET | `/api/purchase/purchase-requisitions/{id}/history` | `purchase:requisition:view` | 承認・変更履歴 | — | `HistoryDto[]` | 4001 | F-PUR-002 |
| 13 | POST | `/api/purchase/purchase-requisitions/from-plan` | 内部（`purchase:plan:convert`） | MRP 計画→請購自動作成 | `{planOrderId, lines[]}` | `{prId, prNo}`（201） | 40010/40011 | F-PUR-025 |

### 2.2 询价比价（F-PUR-004～006）

| # | メソッド | パス | 権限 | 概要 | 主なエラー |
|---|---|---|---|---|---|
| 14 | GET | `/api/purchase/rfqs` | `purchase:rfq:view` | 一覧 | 3001 |
| 15 | GET | `/api/purchase/rfqs/{id}` | `purchase:rfq:view` | 詳細 | 4001 |
| 16 | POST | `/api/purchase/rfqs` | `purchase:rfq:create` | 登録（201） | 1001/40020 |
| 17 | PUT | `/api/purchase/rfqs/{id}` | `purchase:rfq:create` | 更新（草稿） | 4002/4003 |
| 18 | POST | `/api/purchase/rfqs/{id}/issue` | `purchase:rfq:create` | 発出（状態 30） | 4002/40020/40021 |
| 19 | POST | `/api/purchase/rfqs/{id}/quotations` | `purchase:rfq:quote` | 供应商報価登録 | 4002/40023/40032/40033 |
| 20 | GET | `/api/purchase/rfqs/{id}/quotations` | `purchase:rfq:view` | 報価一覧 | 4001 |
| 21 | POST | `/api/purchase/rfqs/{id}/evaluate` | `purchase:rfq:view` | 比価計算 | 4002/40033 |
| 22 | GET | `/api/purchase/rfqs/{id}/comparison` | `purchase:rfq:view` | 比価表取得 | 4001 |
| 23 | POST | `/api/purchase/rfqs/{id}/select` | `purchase:rfq:select` | 中選確定 | 40024/40025/40026/40036/40037 |
| 24 | POST | `/api/purchase/rfqs/{id}/create-orders` | `purchase:rfq:select` | PO 生成 | 40030/40003/40039 |
| 25 | POST | `/api/purchase/rfqs/{id}/cancel` | `purchase:rfq:create` | 取消 | 4002/40072 |
| 26 | POST | `/api/purchase/rfqs/{id}/print` | `purchase:rfq:print` | 比価表出力（PRT-PUR-002） | 4001 |

### 2.3 采购订单（F-PUR-007～010）

| # | メソッド | パス | 権限 | 概要 | 主なエラー |
|---|---|---|---|---|---|
| 27 | GET | `/api/purchase/purchase-orders` | `purchase:order:view` | 一覧 | 3001 |
| 28 | GET | `/api/purchase/purchase-orders/{id}` | `purchase:order:view` | 詳細 | 4001 |
| 29 | POST | `/api/purchase/purchase-orders` | `purchase:order:create` | 登録（201） | 1001/40002/40053 |
| 30 | PUT | `/api/purchase/purchase-orders/{id}` | `purchase:order:update` | 更新（草稿） | 4002/4003 |
| 31 | POST | `/api/purchase/purchase-orders/{id}/submit` | `purchase:order:submit` | 提出 | 4002/80001 |
| 32 | POST | `/api/purchase/purchase-orders/{id}/withdraw` | `purchase:order:submit` | 撤回 | 4002 |
| 33 | POST | `/api/purchase/purchase-orders/{id}/send` | `purchase:order:send` | 発注送信（状態 30） | 4002 |
| 34 | POST | `/api/purchase/purchase-orders/{id}/change` | `purchase:order:change` | 変更申請 | 40034/40035/40050 |
| 35 | GET | `/api/purchase/purchase-orders/{id}/changes` | `purchase:order:view` | 変更履歴 | 4001 |
| 36 | POST | `/api/purchase/purchase-orders/{id}/cancel` | `purchase:order:cancel` | 取消（部分取消含む） | 40035/40049 |
| 37 | POST | `/api/purchase/purchase-orders/{id}/close` | `purchase:order:cancel` | 关闭 | 4002 |
| 38 | GET | `/api/purchase/purchase-orders/{id}/progress` | `purchase:order:view` | 入荷・請求進捗 | 4001 |
| 39 | POST | `/api/purchase/purchase-orders/{id}/print` | `purchase:order:print` | 発注書（PRT-PUR-003） | 4001 |
| 40 | POST | `/api/purchase/purchase-orders/batch-submit` | `purchase:order:submit` | 一括提出 | — |
| 41 | POST | `/api/purchase/purchase-orders/batch-send` | `purchase:order:send` | 一括送信 | — |

### 2.4 收货・IQC 跟踪（F-PUR-011～014）

| # | メソッド | パス | 権限 | 概要 | 主なエラー |
|---|---|---|---|---|---|
| 42 | GET | `/api/purchase/receipts` | `purchase:receipt:view` | 一覧 | 3001 |
| 43 | GET | `/api/purchase/receipts/{id}` | `purchase:receipt:view` | 詳細 | 4001 |
| 44 | POST | `/api/purchase/receipts/from-order` | `purchase:receipt:create` | PO→收货単作成（201） | 40060 |
| 45 | PUT | `/api/purchase/receipts/{id}` | `purchase:receipt:create` | 更新（25 のみ） | 4002/4003 |
| 46 | POST | `/api/purchase/receipts/{id}/confirm` | `purchase:receipt:create` | 入荷確定（E14 発行） | 4002/40040/40042 |
| 47 | POST | `/api/purchase/receipts/{id}/over-receipt-approve` | `purchase:receipt:override` | 超収例外承認 | 4002/40040 |
| 48 | POST | `/api/purchase/receipts/{id}/cancel` | `purchase:receipt:cancel` | 取消（E35 発行） | 40047 |
| 49 | GET | `/api/purchase/receipts/pending-inspection` | `purchase:receipt:view` | 待検一覧 | — |
| 50 | GET | `/api/purchase/receipts/{id}/inspections` | `purchase:receipt:view` | IQC 結果参照（PRD 読み取り） | 4001 |
| 51 | GET | `/api/purchase/receipts/{id}/stocking-status` | `purchase:receipt:view` | 入庫進捗（E18） | 4001 |
| 52 | POST | `/api/purchase/receipts/{id}/dispositions` | `purchase:return:create` | 不合格処置（返品/選別/特採/廃棄） | 4002/40060 |
| 53 | POST | `/api/purchase/receipts/{id}/print` | `purchase:receipt:print` | 入荷検収書（PRT-PUR-004） | 4001 |
| 54 | GET | `/api/purchase/receipts/batch-suggestion` | `purchase:receipt:create` | 批次号候補 | — |

### 2.5 采购退货（F-PUR-015～016）

| # | メソッド | パス | 権限 | 概要 | 主なエラー |
|---|---|---|---|---|---|
| 55 | GET | `/api/purchase/returns` | `purchase:return:view` | 一覧 | 3001 |
| 56 | GET | `/api/purchase/returns/{id}` | `purchase:return:view` | 詳細 | 4001 |
| 57 | POST | `/api/purchase/returns/from-receipt` | `purchase:return:create` | 収货単から退货起票（201） | 40060/40070 |
| 58 | POST | `/api/purchase/returns` | `purchase:return:create` | 手工起票（貸項等、201） | 1001/40060 |
| 59 | PUT | `/api/purchase/returns/{id}` | `purchase:return:create` | 更新（10 のみ） | 4002/4003 |
| 60 | POST | `/api/purchase/returns/{id}/submit` | `purchase:return:create` | 提出 | 4002/80001 |
| 61 | POST | `/api/purchase/returns/{id}/withdraw` | `purchase:return:create` | 撤回 | 4002 |
| 62 | POST | `/api/purchase/returns/{id}/ship` | `purchase:return:ship` | 出庫確定（E16 発行） | 4002/40070 |
| 63 | POST | `/api/purchase/returns/{id}/complete` | `purchase:return:ship` | 完了（紅字紐付） | 40078 |
| 64 | POST | `/api/purchase/returns/{id}/cancel` | `purchase:return:create` | 取消（10/25） | 4002/40079 |
| 65 | GET | `/api/purchase/returns/{id}/progress` | `purchase:return:view` | 出庫・紅字進捗 | 4001 |
| 66 | POST | `/api/purchase/returns/{id}/print` | `purchase:return:print` | 退貨単（PRT-PUR-005） | 4001 |

### 2.6 采购发票・三单匹配・対账（F-PUR-017～020）

| # | メソッド | パス | 権限 | 概要 | 主なエラー |
|---|---|---|---|---|---|
| 67 | GET | `/api/purchase/invoices` | `purchase:invoice:view` | 一覧 | 3001 |
| 68 | GET | `/api/purchase/invoices/{id}` | `purchase:invoice:view` | 詳細 | 4001 |
| 69 | POST | `/api/purchase/invoices` | `purchase:invoice:create` | 発票登録（201） | 40070/40071/40082 |
| 70 | PUT | `/api/purchase/invoices/{id}` | `purchase:invoice:create` | 更新（未計上） | 4002/40078 |
| 71 | POST | `/api/purchase/invoices/{id}/match` | `purchase:match:run` | 三单匹配実行 | 4002/40072/40076 |
| 72 | GET | `/api/purchase/invoices/{id}/match-result` | `purchase:invoice:view` | 匹配結果取得 | 4001 |
| 73 | PUT | `/api/purchase/invoices/{id}/match-lines` | `purchase:match:run` | 差異理由・会計処理保存 | 4002/40075 |
| 74 | POST | `/api/purchase/invoices/{id}/submit-diff` | `purchase:match:approve` | 差異承認提出 | 4002/80001 |
| 75 | POST | `/api/purchase/invoices/{id}/post` | `purchase:match:run` | 計上（E17 発行） | 4002/40078 |
| 76 | POST | `/api/purchase/invoices/{id}/cancel` | `purchase:invoice:cancel` | 取消（赤伝） | 4002/40078 |
| 77 | GET | `/api/purchase/invoices/available-lines` | `purchase:invoice:create` | 未請求 GR 明細取得 | — |
| 78 | POST | `/api/purchase/invoices/batch-match` | `purchase:match:run` | 一括匹配 | — |
| 79 | GET | `/api/purchase/invoice-matches` | `purchase:invoice:view` | 匹配結果検索 | 3001 |
| 80 | GET | `/api/purchase/accruals` | `purchase:ap:view` | 入荷済未請求一覧 | — |
| 81 | GET | `/api/purchase/statements` | `purchase:statement:view` | 対账一覧 | 3001 |
| 82 | POST | `/api/purchase/statements/generate` | `purchase:statement:confirm` | 対账生成 | 40090/40091 |
| 83 | POST | `/api/purchase/statements/{id}/send` | `purchase:statement:confirm` | 送付（状態 30） | 4002 |
| 84 | POST | `/api/purchase/statements/{id}/confirm` | `purchase:statement:confirm` | 確認完了（状態 40） | 4002/40090 |
| 85 | POST | `/api/purchase/statements/{id}/print` | `purchase:statement:view` | 対账単（PRT-PUR-006） | 4001 |

### 2.7 付款申請・預付款（F-PUR-021～022）

| # | メソッド | パス | 権限 | 概要 | 主なエラー |
|---|---|---|---|---|---|
| 86 | POST | `/api/purchase/payment-requests` | `purchase:payment:create` | 付款申請（FIN PA 起票） | 40090/40091 |
| 87 | POST | `/api/purchase/prepayment-requests` | `purchase:payment:create` | 預付款申請（FIN PA 起票） | 40095 |
| 88 | GET | `/api/purchase/payment-status` | `purchase:ap:view` | 支払状態（E28 反映） | — |

### 2.8 交期跟踪・価格・計画・績效・報表（F-PUR-023～027）

| # | メソッド | パス | 権限 | 概要 | 主なエラー |
|---|---|---|---|---|---|
| 89 | GET | `/api/purchase/tracking` | `purchase:tracking:view` | 交期跟踪 KPI・一覧 | 3001 |
| 90 | GET | `/api/purchase/tracking/backorders` | `purchase:tracking:view` | 未入荷一覧 | — |
| 91 | POST | `/api/purchase/delivery-followups` | `purchase:tracking:followup` | 催货登録（201） | 1001/4002 |
| 92 | GET | `/api/purchase/delivery-followups` | `purchase:tracking:view` | 催货履歴 | — |
| 93 | GET | `/api/purchase/prices` | `purchase:price:view` | 採購価格照会 | — |
| 94 | GET | `/api/purchase/price-history` | `purchase:price:view` | 成交価履歴・趨勢 | — |
| 95 | GET | `/api/purchase/price-anomalies` | `purchase:price:view` | 価格異常一覧 | — |
| 96 | GET | `/api/purchase/plan-suggestions` | `purchase:plan:view` | MRP 計画オーダー一覧 | 4001 |
| 97 | POST | `/api/purchase/plan-suggestions/convert` | `purchase:plan:convert` | 計画→請購変換 | 40010/40011 |
| 98 | GET | `/api/purchase/supplier-performances` | `purchase:performance:view` | 績效一覧 | — |
| 99 | GET | `/api/purchase/supplier-performances/{id}` | `purchase:performance:view` | 績效詳細 | 4001 |
| 100 | POST | `/api/purchase/supplier-performances/{id}/confirm` | `purchase:performance:calculate` | 績效確定 | 4002/40010 |
| 101 | POST | `/api/purchase/supplier-performances/recalculate` | `purchase:performance:calculate` | 再計算 | — |
| 102 | POST | `/api/purchase/exports` | `purchase:report:export` | 非同期エクスポート（202） | — |
| 103 | GET | `/api/purchase/jobs/{jobId}` | `purchase:report:view` | ジョブ状態 | 4001 |
| 104 | GET | `/api/purchase/jobs/{jobId}/files/{fileId}` | `purchase:report:view` | 結果ファイル取得 | 4001 |

> 合計 104 エンドポイント（同一リソースの GET/POST を含む）。`{id}` は BIGINT の文字列表現。

---

## 3. 共通リクエスト/レスポンス仕様（本域固有）

### 3.1 一覧検索の共通クエリ

| パラメータ | 型 | 既定 | 説明 |
|---|---|---|---|
| `pageNum` | int | 1 | 1 始まり |
| `pageSize` | int | 20 | 最大 200 |
| `sort` | string | 機能既定 | `field,asc` / `field,desc` |
| `keyword` | string | — | コード・名称の部分一致（pg_trgm） |
| `status` | string | — | 状態コード（カンマ区切り複数可） |
| `dateFrom`/`dateTo` | string | — | `yyyy-MM-dd`（両端含む） |
| `supplierId`/`materialId`/`departmentId` | string | — | コード存在チェック |

### 3.2 状態操作の共通ボディ

```json
{ "version": 3, "comment": "任意コメント" }
```

- レスポンスは更新後の詳細 DTO を返す（03 §11.1）。
- `version` 不一致は `409` + `code=4003`、状態不整合は `409` + `code=4002`。

### 3.3 一括操作の共通仕様

```json
{ "ids": ["1845678901234567890", "1845678901234567891"], "comment": "一括処理" }
```

レスポンス：`{ "successCount": 2, "failureCount": 1, "failures": [{"id":"...","code":4002,"reason":"..."}] }`。上限 1,000 件（03 §11.2）。

---

## 4. API 詳細（主要エンドポイント）

### 4.1 POST /api/purchase/purchase-requisitions（请购登録）

| 項目 | 内容 |
|---|---|
| 目的 | 请购単を登録し、予算・重複チェックの警告を返す |
| 権限 | `purchase:requisition:create`（データ範囲：自部門） |
| 冪等 | `Idempotency-Key` 必須（24 時間） |
| 排他 | 新規のため不要（採番は `sys_sequence` 行ロック） |
| 関連テーブル | `pur_purchase_requisition`、`pur_purchase_requisition_line`、`sys_sequence`、`sys_audit_log` |

リクエスト項目：

| 項目 | 型 | 必須 | 説明 |
|---|---|---|---|
| `prType` | number | ○ | 1 通常/2 计划/3 紧急/4 费用性 |
| `departmentId` | string | ○ | 需求部門（データ範囲内） |
| `factoryId`/`warehouseId` | string | ○ | 工厂・収貨倉庫 |
| `requiredDate` | string | ○ | 希望交期（≥ 当日） |
| `reason` | string | ○ | 申請理由（≤500） |
| `externalNo` | string | — | 外部参考号 |
| `lines[]` | array | ○ | 1～1,000 行 |
| `lines[].materialId` | string | ○ | 物料（有効・採購可） |
| `lines[].uomCode` | string | ○ | 採購単位 |
| `lines[].quantity` | string | ○ | > 0、小数 4 桁 |
| `lines[].estimatedUnitPrice` | string | — | 税抜単価（未指定は自動取価） |
| `lines[].taxCode` | string | ○ | 進項税码（例 `VAT13-IN`） |
| `lines[].requiredDate` | string | ○ | 行希望交期 |
| `lines[].supplierSuggestId` | string | — | 推薦供應商 |
| `lines[].purpose` | string | ○ | 用途 |

> リクエスト/レスポンス例は [01-requisition.md](01-requisition.md) §7.1～7.4 を参照。成功時 HTTP 201、`data.warnings[]` に重複请购（`code=40004`）・予算警告（`code=40005`）を返す。

### 4.2 POST /api/purchase/purchase-requisitions/{id}/convert-to-orders（転単）

| 項目 | 内容 |
|---|---|
| 目的 | 承認済請購を PO（草稿）へ転単する。部分転単・多グループ転単可 |
| 権限 | `purchase:requisition:convert` |
| 冪等 | `Idempotency-Key` 必須。同一キー再送は初回結果を返す |
| 排他 | 請購行ロック（`SELECT ... FOR UPDATE`）+ 残量再検証 |
| 関連テーブル | `pur_purchase_requisition(_line)`、`pur_purchase_order(_line)`、`sys_sequence` |

リクエスト（[01](01-requisition.md) §7.3 参照）：

```json
{
  "lines": [
    {
      "purchaseRequisitionLineId": "1845678901234567891",
      "quantity": "8000.0000",
      "supplierId": "1845000000000002001",
      "warehouseId": "1845000000000000101",
      "deliveryDate": "2026-11-03"
    }
  ],
  "autoSubmit": false,
  "comment": "分两批到货"
}
```

レスポンス：`{ orders: [{poId, poNo, lineCount, totalAmountWithTax}], prStatus, convertedRate }`。エラー：`40010`（残量超過）、`40011`（状態不整合）、`40012`（供應商未指定）。

### 4.3 POST /api/purchase/rfqs/{id}/select（中選確定）

| 項目 | 内容 |
|---|---|
| 目的 | 比価結果に基づき行単位で中選を確定し、状態 40 へ遷移 |
| 権限 | `purchase:rfq:select` |
| 排他 | RFQ 行ロック + `version` |
| 関連テーブル | `pur_rfq(_line)`、`pur_supplier_quotation_line` |

リクエスト例・レスポンス例は [02-rfq-comparison.md](02-rfq-comparison.md) §7.2～7.3 を参照。エラー：`40024`（規則不一致）、`40025`（目安差異理由缺失）、`40026`（中選不完全）、`40036`（同一行複数中選）。

### 4.4 POST /api/purchase/purchase-orders/{id}/change（訂单変更申請）

| 項目 | 内容 |
|---|---|
| 目的 | 承認済 PO の数量・単価・交期を変更し、再承認フローへ提出 |
| 権限 | `purchase:order:change` |
| 排他 | PO ロック + `version`・`version_no`、`pending_change=false` |
| 関連テーブル | `pur_purchase_order(_line)`、`pur_purchase_order_his` |

```json
{
  "version": 3,
  "changeReason": "供應商 11 月産能調整，交期 11-03 延至 11-10",
  "lines": [
    { "lineNo": 10, "quantity": "28000.0000", "unitPrice": "5.650000", "deliveryDate": "2026-11-10" }
  ]
}
```

レスポンス：変更後 PO 詳細（`poStatus=20`、`versionNo=2`、`pendingChange=true`）。エラー：`40034`（入荷済数量割れ）、`40035`（入荷済行削除）、`40050`（変更改承認中）。

### 4.5 POST /api/purchase/receipts/{id}/confirm（入荷確定）

| 項目 | 内容 |
|---|---|
| 目的 | 収貨を確定し E14 を発行（待検入庫・IQC 起票・暫估計上のトリガ） |
| 権限 | `purchase:receipt:create` |
| 冪等 | `Idempotency-Key` 必須 |
| 排他 | 収貨単・PO 明細ロック |
| 関連テーブル | `pur_receipt(_line)`、`pur_purchase_order_line`、`sys_outbox_event` |

リクエスト：`{ "version": 2 }`。レスポンス：更新後詳細（`receiptStatus=30`、明細 `inspectionStatus=1`）。E14 payload は §7.2。エラー：`40040`（超収容差超過）、`40042`（超収理由なし）。

### 4.6 POST /api/purchase/receipts/{id}/cancel（収貨取消 E35）

| 項目 | 内容 |
|---|---|
| 目的 | 未検収・未照合の収貨単を取消し、E35 を発行 |
| 権限 | `purchase:receipt:cancel` |
| 事前条件 | `receipt_status=30`、IQC 未完了、三単マッチ未確定 |
| 関連テーブル | `pur_receipt(_line)`、`pur_purchase_order_line`、`sys_outbox_event` |

リクエスト：`{ "version": 3, "reason": "送り状数量の誤入力" }`。エラー：`40047`（条件不成立）。E35 payload は §7.3。

### 4.7 POST /api/purchase/invoices/{id}/match（三単マッチ）

| 項目 | 内容 |
|---|---|
| 目的 | PO/GR/PIV の字段級匹配を実行し、判定・差異を保存（必要時 E17 を発行） |
| 権限 | `purchase:match:run` |
| 排他 | 発票ロック + `version`、GR 明細の可請求残検証 |
| 関連テーブル | `pur_invoice(_line)`、`pur_invoice_match`、`pur_receipt_line` |

リクエスト：`{ "version": 1, "lines": [] }`（`lines` 省略時は全行自動匹配）。

レスポンス例（[06](06-purchase-invoice-ap.md) §7.2）：

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "invoiceId": "1845678901234568300",
    "matchedStatus": 4,
    "diffTotalAmount": "1265.60",
    "summary": { "fullMatch": 0, "withinTolerance": 1, "exceedTolerance": 1, "hold": 0 },
    "matches": [
      {
        "id": "1845678901234568310",
        "invoiceLineNo": 10,
        "poLineNo": 10,
        "receiptLineNo": 10,
        "matchedQty": "16000.0000",
        "invoiceQty": "16000.0000",
        "qtyDiff": "0.0000",
        "poUnitPrice": "5.650000",
        "invoiceUnitPrice": "5.720000",
        "priceDiffRate": "1.2389",
        "priceDiffAmount": "1120.00",
        "taxDiffAmount": "145.60",
        "diffTotalAmount": "1265.60",
        "matchStatus": 3,
        "accountingTreatment": 1
      }
    ]
  }
}
```

判定基準・容差・差異理由・会計処理は [06](06-purchase-invoice-ap.md) §6.2 を正とする。

### 4.8 POST /api/purchase/invoices/{id}/post（計上 E17）

| 項目 | 内容 |
|---|---|
| 目的 | 匹配確定済発票を「已計上」とし、E17 `purchase.invoice.matched` を発行 |
| 権限 | `purchase:match:run` |
| 事前条件 | `matched_status ∈ {3,5}` かつ `ap_status=0` |
| 関連テーブル | `pur_invoice`、`pur_receipt_line.invoiced_qty`、`pur_purchase_order_line.invoiced_qty`、`sys_outbox_event` |

リクエスト：`{ "version": 3 }`。レスポンス：`apStatus=1`、`apPostedAt`。エラー：`40078`（計上済・状態不整合）。

### 4.9 POST /api/purchase/statements/generate（対账生成）

| 項目 | 内容 |
|---|---|
| 目的 | 供應商×月の対账単を生成し、GR/PIV/PRT/支払を明細化して残高を検証 |
| 権限 | `purchase:statement:confirm` |
| 冪等 | 同一 `(supplierId, periodCode)` の再生成は既存を置換（`version` 検証） |
| 関連テーブル | `pur_statement`、`pur_statement_line` |

リクエスト：`{ "supplierId": "1845000000000002001", "periodCode": "2026-10" }`。レスポンス：`{ statementId, statementNo, openingBalance, periodInvoiceAmount, closingBalance, diffCount }`。エラー：`40090`（期間未確定）、`40091`（FIN 残高参照失敗）。

### 4.10 POST /api/purchase/payment-requests（付款申請）

| 項目 | 内容 |
|---|---|
| 目的 | 已計上 AP を対象に FIN へ付款申請（PA）を作成する |
| 権限 | `purchase:payment:create` |
| 冪等 | `Idempotency-Key` 必須（FIN 側 PA 重複防止） |
| 関連 | FIN `POST /api/finance/payment-requests`、`pur_invoice`（参照のみ） |

```json
{
  "invoiceIds": ["1845678901234568300"],
  "amount": "103417.60",
  "plannedPaymentDate": "2026-12-05",
  "remark": "10 月分買挂 1 回目"
}
```

レスポンス：`{ "paId": "1845678901234999999", "paNo": "PA2611200001" }`。エラー：`40090`（金額超過）、`40091`（FIN API 失敗）。

### 4.11 POST /api/purchase/prepayment-requests（預付款申請）

```json
{
  "poId": "1845678901234567900",
  "amount": "147261.60",
  "plannedPaymentDate": "2026-10-25",
  "remark": "合同约定预付 30%"
}
```

レスポンス：`{ "paId": "...", "paNo": "PA2610200001" }`。エラー：`40095`（比例超過）。

---

## 5. 権限と API の対応

| 権限コード | 対象 API | 備考 |
|---|---|---|
| `purchase:requisition:view/create/update/submit/approve/cancel/convert/print` | §2.1 | approve は WF 側 |
| `purchase:rfq:view/create/quote/select/print` | §2.2 | — |
| `purchase:order:view/create/update/submit/approve/change/send/cancel/print` | §2.3 | — |
| `purchase:receipt:view/create/cancel/override/print` | §2.4 | — |
| `purchase:return:view/create/approve/ship/print` | §2.5 | approve は WF 側 |
| `purchase:invoice:view/create/cancel`、`purchase:match:view/run/approve` | §2.6 | — |
| `purchase:statement:view/confirm` | §2.6 | — |
| `purchase:ap:view` | §2.6～2.7 | — |
| `purchase:payment:create/approve` | §2.7 | approve は FIN 側 |
| `purchase:tracking:view/followup`、`purchase:price:view`、`purchase:plan:view/convert`、`purchase:performance:view/calculate`、`purchase:report:view/export` | §2.8 | — |

---

## 6. エラーコードとメッセージの対応（PUR 域）

| code | HTTP | メッセージ ID | 概要 |
|---|---|---|---|
| 4001 | 404 | MSG-COM-032 | 対象データ不存在 |
| 4002 | 409 | MSG-COM-034 | 状態不整合 |
| 4003 | 409 | MSG-COM-033 | 楽観排他競合 |
| 4005 | 409 | MSG-COM-035 | 二重処理・処理中 |
| 40002 | 422 | MSG-PUR-002 | 物料無効・採購不可 |
| 40003 | 422 | MSG-PUR-003 | 供應商未准入・範囲外 |
| 40004 | 200（警告） | MSG-PUR-004 | 重複請購（警告） |
| 40005 | 200（警告） | MSG-PUR-005 | 予算不足（警告） |
| 40010 | 422 | MSG-PUR-021 | 転単数量が残量超過 |
| 40011 | 422 | MSG-PUR-022 | 請購状態が転単不可 |
| 40012 | 422 | MSG-PUR-003 | 転単で供應商未指定 |
| 40020 | 422 | MSG-PUR-030 | 邀請供應商不足 2 家 |
| 40021 | 422 | MSG-PUR-031 | 報価締切日時不正 |
| 40022 | 200（警告） | MSG-PUR-032 | 報価有効期限不足（中選不可） |
| 40023 | 422 | MSG-PUR-033 | 邀請外供應商の報価 |
| 40024 | 422 | MSG-PUR-034 | 中選が比価規則と不一致 |
| 40025 | 422 | MSG-PUR-035 | 目安単価差異理由なし |
| 40026 | 422 | MSG-PUR-036 | 中選不完全 |
| 40030 | 422 | MSG-PUR-038 | 詢価状態不整合 |
| 40032 | 422 | MSG-PUR-040 | 報価締切後の登録 |
| 40033 | 422 | MSG-PUR-041 | 為替レート未設定 |
| 40034 | 422 | MSG-PUR-051 | 変更数量が入荷済数量未満 |
| 40035 | 422 | MSG-PUR-052 | 入荷済数量の取消不可 |
| 40036 | 422 | MSG-PUR-044 | 同一行の複数中選 |
| 40037 | 422 | MSG-PUR-045 | 中選数量不正 |
| 40039 | 200（情報） | MSG-PUR-047 | PO 生成済（重複生成なし） |
| 40040 | 422 | MSG-PUR-068 | 超収容差超過 |
| 40042 | 422 | MSG-PUR-070 | 超収理由なし |
| 40043 | 422 | MSG-PUR-071 | 全量受入済 |
| 40044 | 200（警告） | MSG-PUR-072 | 早入荷（警告） |
| 40045 | 422 | MSG-PUR-073 | 批次号必須 |
| 40046 | 200（警告） | MSG-PUR-074 | 数量整合不一致（警告） |
| 40047 | 422 | MSG-PUR-075 | 取消除外条件不成立 |
| 40049 | 422 | MSG-PUR-052 | 全量入荷済で取消不可 |
| 40050 | 422 | MSG-PUR-063 | 変更改承認中の操作 |
| 40051 | 422 | MSG-PUR-064 | 交期 < 訂単日 |
| 40052 | 422 | MSG-PUR-065 | 訂単日範囲外 |
| 40053 | 422 | MSG-PUR-066 | 手工定価理由なし |
| 40060 | 422 | MSG-PUR-087 | 退貨数量が可退数量超過 |
| 40070 | 422 | MSG-PUR-100 | 発票番号重複 |
| 40071 | 422 | MSG-PUR-101 | 発票合計不一致 |
| 40072 | 200（警告） | MSG-PUR-102 | PO/GR 未発見（保留可） |
| 40074 | 200（情報） | MSG-PUR-104 | 容差内自動通過（警告コード） |
| 40075 | 422 | MSG-PUR-105 | 差異理由なし |
| 40076 | 200（警告） | MSG-PUR-106 | 請求数量超過（保留） |
| 40078 | 422 | MSG-PUR-108 | 計上済の操作不可 |
| 40079 | 422 | MSG-PUR-109 | 紅字発票不備 |
| 40081 | 200（警告） | MSG-PUR-110 | 暫估台帳差異（警告） |
| 40082 | 422 | MSG-PUR-111 | 税号不一致 |
| 40090 | 422 | MSG-PUR-113 | 付款申請金額超過 |
| 40091 | 503 | MSG-PUR-114 | FIN API 呼出失敗 |
| 40095 | 422 | MSG-PUR-115 | 預付款比例超過 |
| 40099 | 422 | MSG-PUR-126 | その他業務エラー（汎用） |
| 5000 | 500 | MSG-COM-080 | システムエラー（trace_id 返却） |
| 5001 | 503 | MSG-COM-082 | レート制限・メンテナンス |

> 警告（200 応答の `data.warnings[]`）に付すコードは 40004/40005/40022/40039/40044/40046/40072/40074/40076/40081。エラーと区別するため HTTP ステータスは 200 とし、`warnings[].code` で識別する。メッセージ本文・対処は [93-messages.md](93-messages.md) を正とする。

---

## 7. 領域イベント契約

### 7.1 発行イベント一覧

| イベント | 発行タイミング | 購読者 | トランザクション境界 | 冪等キー |
|---|---|---|---|---|
| E13 `purchase.order.approved` | PO 最終承認（25 遷移） | INT（第一版（実装順 P2） 供應商送信） | 承認トランザクション内で Outbox INSERT | `aggregateId + aggregateVersion` |
| E14 `purchase.receipt.posted` | 収貨確定（25→30） | INV/PRD/FIN | 同上 | 同上 |
| E16 `purchase.return.confirmed` | 退貨出庫確定（25→30） | INV/FIN | 同上 | 同上 |
| E17 `purchase.invoice.matched` | 三単マッチ計上確定 | FIN | 同上 | 同上 |
| E35 `purchase.receipt.cancelled` | 収貨取消（30→90） | INV/PRD/FIN | 同上 | 同上（`amount` により暫估戻し可） |

### 7.2 E14 `purchase.receipt.posted` payload（契約：09 §3）

```json
{
  "eventId": "0f3b5a8e-9d1c-4a2b-8f0e-1c2d3e4f5a6b",
  "eventType": "purchase.receipt.posted",
  "eventVersion": 1,
  "occurredAt": "2026-11-03T10:25:00+08:00",
  "source": "erp-purchase",
  "tenantId": 0,
  "companyId": 1,
  "aggregateType": "pur_receipt",
  "aggregateId": "1845678901234568100",
  "aggregateNo": "GR2610210001",
  "aggregateVersion": 2,
  "idempotencyKey": "purchase.receipt.posted:1845678901234568100:2",
  "payload": {
    "receiptId": "1845678901234568100",
    "receiptNo": "GR2610210001",
    "orderId": "1845678901234567900",
    "supplierId": "1845000000000002001",
    "lines": [
      {
        "materialId": "1845000000000001001",
        "receivedQty": "16000.0000",
        "uom": "KGM",
        "warehouseId": "1845000000000000101",
        "batchNo": "S000001-20261101-01",
        "unitPrice": "5.650000",
        "inspectionFlag": true
      }
    ],
    "receivedAt": "2026-11-03T10:25:00+08:00"
  }
}
```

> 購読側処理（09 §3）：INV＝待検在庫の入庫、PRD＝`inspectionFlag=true` の明細のみ IQC 起票（`inspectionType=IQC`、`sourceType=PURCHASE_RECEIPT`、`sourceId=receiptId`）。`lines[].inspectionFlag` は PUR の入荷確定時スナップショット（後方互換追加。欠落時の旧メッセージは購読側で true 扱い）で、INV・PRD は再導出しない。FIN＝仕入暫估計上（J01、金額＝`Σ receivedQty × unitPrice`）。

### 7.3 E35 `purchase.receipt.cancelled` payload（契約：09 §3）

```json
{
  "eventId": "7a1b2c3d-4e5f-4a6b-9c8d-0e1f2a3b4c5d",
  "eventType": "purchase.receipt.cancelled",
  "eventVersion": 1,
  "occurredAt": "2026-11-04T09:10:00+08:00",
  "source": "erp-purchase",
  "tenantId": 0,
  "companyId": 1,
  "aggregateType": "pur_receipt",
  "aggregateId": "1845678901234568100",
  "aggregateNo": "GR2610210001",
  "aggregateVersion": 3,
  "idempotencyKey": "purchase.receipt.cancelled:1845678901234568100:3",
  "payload": {
    "receiptId": "1845678901234568100",
    "receiptNo": "GR2610210001",
    "orderId": "1845678901234567900",
    "reason": "送り状数量の誤入力（実数量 15,000 KGM）",
    "amount": "91520.00",
    "reversedLines": [
      { "materialId": "1845000000000001001", "batchNo": "S000001-20261101-01", "qty": "16000.0000", "unitPrice": "5.720000", "amount": "91520.00" }
    ],
    "cancelledAt": "2026-11-04T09:10:00+08:00"
  }
}
```

### 7.4 E16 `purchase.return.confirmed` payload（契約：09 §3）

```json
{
  "payload": {
    "returnId": "1845678901234568200",
    "returnNo": "PRT2611050001",
    "receiptId": "1845678901234568100",
    "lines": [
      { "materialId": "1845000000000001101", "qty": "12.0000", "warehouseId": "1845000000000000101", "batchNo": "S000009-20261101-01",
        "unitPrice": "156.000000", "taxRate": "13.0000", "amount": "1872.00", "taxAmount": "243.36", "reason": "IQC 不合格（尺寸超差）" }
    ],
    "amount": "1872.00",
    "taxAmount": "243.36",
    "returnDate": "2026-11-05"
  }
}
```

> 購読側処理：INV＝`PR_OUT` 出庫、FIN＝J04 赤伝仕入（買挂または暫估の冲減）・進項税額転出。J04 の金額は 09 §3 改訂の `unitPrice`/`taxRate`/`amount`/`taxAmount`（明細）と `amount`/`taxAmount`（ヘッダ）から確定できる。

### 7.5 E17 `purchase.invoice.matched` payload（契約：09 §3）

[06](06-purchase-invoice-ap.md) §7.4 の payload を正とする。09 §3（Lead 2026-10-20 改訂）の契約項目は `invoiceId`、`invoiceNo`、`supplierId`、`amount`、`taxAmount`、`taxRate`、`matchedStatus`、`diffAmount`、`diffTreatment`、`lines[{poLineId, receiptLineId, qty, price, taxAmount, diffType, diffAmount}]`。**送出 payload は 09 と逐字一致**とし、契約外項目は追加しない（追加が必要な場合は 09 追補を Lead に申請する）。

実装内部 DTO とワイヤー項目の対応（内部名は任意。**イベント送信時に 09 名へ変換**する）：

| 09 §3（ワイヤー＝契約） | 実装内部 DTO 例 | 意味 |
|---|---|---|
| `poLineId` | `poLineId` | PO 明細 ID |
| `receiptLineId` | `receiptLineId` | 収貨明細 ID |
| `qty` | `matchedQty` | 匹配（請求）数量 |
| `price` | `invoiceUnitPrice` | 発票税抜単価（PO 単価は照合判定にのみ使用し、payload には含めない） |
| `taxAmount` | `taxAmount` | 発票行税額 |
| `diffType` | `diffType` | 差異類型（1 数量/2 単価/3 金額/4 税額/5 複合） |
| `diffAmount` | `diffAmount` | 当該行の差異額（単価差＋税額差） |

> 項目追加ではないため `eventVersion=1` のまま。E17 の購読側（FIN）は当該 payload のみで J02 暫估冲回・J03 買挂計上・差異処理を実行できる（詳細は [06](06-purchase-invoice-ap.md) §6.2・§7.4）。

> 購読側処理（FIN）：① J02 暫估冲回（受入済・未請求分）② J03 買挂計上（発票税抜・進項税額）③ 差異処理（`diffTreatment` に応じ原価調整/当期損益/応付調整/貸項）④ 買挂残更新。

### 7.6 E13 `purchase.order.approved` payload（契約：09 §3）

```json
{
  "payload": {
    "orderId": "1845678901234567900",
    "orderNo": "PO2610200001",
    "supplierId": "1845000000000002001",
    "lines": [
      { "materialId": "1845000000000001001", "qty": "28000.0000", "price": "5.650000", "deliveryDate": "2026-11-03" },
      { "materialId": "1845000000000001101", "qty": "2000.0000", "price": "78.500000", "deliveryDate": "2026-11-03" },
      { "materialId": "1845000000000002101", "qty": "2000.0000", "price": "12.800000", "deliveryDate": "2026-11-10" },
      { "materialId": "1845000000000003101", "qty": "600.0000", "price": "156.000000", "deliveryDate": "2026-11-12" }
    ],
    "amount": "434400.00"
  }
}
```

> 購読側：INT＝供應商送信（第一版（実装順 P2）、IF-PUR-001）。WF は 09 §3 改訂で購読者から除外済（PO 状態は WF が E31/E32 を発行し業務域が更新する責任分界のため）。本域は承認 TX 内で Outbox INSERT のみ行い、送信結果は待たない。

### 7.7 購読イベントと処理

| イベント | 発行者 | 本域の処理 | 冪等 |
|---|---|---|---|
| E03 `mdm.supplier.changed` | MDM | 供應商参照キャッシュ/スナップショット注意喚起（既存伝票は更新しない） | `eventId` |
| E04 `mdm.price.changed` | MDM | 取価キャッシュの無効化（TTL 最大 5 分） | `eventId` |
| E15 `quality.inspection.completed` | PRD | `pur_receipt_line.inspection_status`・`accepted_qty`/`concession_qty`/`rejected_qty` 更新、処置待ち表示 | `eventId` + `(inspectionId)` |
| E18 `inventory.txn.posted` | INV | `pur_receipt_line.stocked_qty`・`stocked_at` 更新、入庫進捗再計算（`txnType=PI` のみ対象） | `eventId` + `txnId` |
| E28 `finance.payment.completed` | FIN | AP 明細の支払状態表示更新（`ap_status=3`）、PO の支払情報参照 | `eventId` + `paymentId` |
| E31 `workflow.task.completed` / E32 `workflow.process.completed` | WF | PR/PO/PRT/差異承認の状態反映（`businessType` で分岐） | `eventId` + `(processInstanceId, taskId, result)` |
| E20 `inventory.period.closed` | INV | 月結後は取消・再匹配を拒否（期間ロック表示） | `eventId` |

購読実装は [09 §2.2～2.3](../00-common/09-cross-domain-flow.md) の原則（更新責任の一元化・冪等・Outbox）に従う。本域は E15/E18/E28/E31/E32 の購読のみで他域データを更新しない。

### 7.8 イベント共通エンベロープ

09 §2.3 のエンベロープ（`eventId`／`eventType`／`eventVersion`／`occurredAt`／`source`／`tenantId`／`companyId`／`aggregateType`／`aggregateId`／`aggregateNo`／`aggregateVersion`／`idempotencyKey`／`payload`）を全イベントで使用する。`eventVersion` は項目追加で +0、意味変更で +1。

---

## 8. 非同期ジョブ・外部 IF

| IF ID | 名称 | 相手先 | 方向 | 方式 | 頻度 | 状態 |
|---|---|---|---|---|---|---|
| IF-PUR-001 | 採購訂単送信 | INT（門戸/メール/EDI） | 送信 | REST/ファイル | イベント | 第一版（実装順 P2）（P0 実装時点は手動） |
| IF-PUR-002 | 電子発票採集 | INT（税局/数電票） | 受信 | REST/ファイル | 日次/イベント | 第一版（実装順 P2） |
| IF-PUR-003 | MRP 計画オーダー受信 | PRD | 受信 | REST（同期参照） | 日次/イベント | 第一版（実装順 P0） |
| IF-PUR-004 | IQC 起票（E14） | PRD | 送信 | イベント | イベント | 第一版 |
| IF-PUR-005 | IQC 判定受信（E15） | PRD | 受信 | イベント | イベント | 第一版 |
| IF-PUR-006 | 在庫入出庫（E14/E16/E35/E18） | INV | 送受信 | イベント | イベント | 第一版 |
| IF-PUR-007 | 買挂・暫估・支払（E17/E28） | FIN | 送受信 | イベント | イベント | 第一版 |
| IF-PUR-008 | 供應商・価格受信（E03/E04） | MDM | 受信 | イベント | イベント | 第一版 |
| IF-PUR-009 | PDA・条碼収貨 | INT | 受信 | REST | リアルタイム | 第一版（実装順 P1） |
| IF-PUR-010 | 供應商門戸報価 | INT | 受信 | REST/ファイル | 日次 | 第一版（実装順 P2） |
| IF-PUR-011 | 収貨取消逆処理（E35） | INV/PRD/FIN | 送信 | イベント | イベント | 第一版 |

**ジョブ API**：`POST /api/purchase/exports`（202 + `{jobId}`）→ `GET /api/purchase/jobs/{jobId}`（`QUEUED/RUNNING/SUCCEEDED/FAILED`、`progress`、`resultFileId`）→ `GET /api/purchase/jobs/{jobId}/files/{fileId}`（ダウンロード）。結果は 7 日保存（03 §12.1）。

**外部公開 API**：本域は `/api/open/v1` を提供しない（外部連携は INT 域経由、09 §12）。将来、供應商向け PO 照会 API を提供する場合は INT 域設計で定義する。

---

## 9. 非機能・セキュリティ

| 項目 | 仕様 |
|---|---|
| 応答時間 | 一覧 2 秒以内、詳細 1 秒以内、登録 3 秒以内、三単マッチ 3 秒以内（50 行 × 5 GR） |
| 同時実行 | 20 ユーザ（購買 10・倉庫 5・財務 5） |
| レート制限 | 内部 API は既定なし。外部公開時は 600 req/分 |
| 監査 | 全更新・状態操作・出力を `sys_audit_log` に記録（01 §12） |
| マスキング | 銀行口座・電話・メールは応答/ログでマスク（01 §15） |
| 冪等 | 登録・状態操作・ジョブ起動に `Idempotency-Key`（24 時間、`sys_idempotency`） |
| 排他 | 更新系は `version`、在庫・採番・月結は行ロック（04 §11） |
| OpenAPI | `tags: Purchase - Requisition / Rfq / Order / Receipt / Return / Invoice / Match / Tracking`。`operationId: purchase{Resource}{Action}` |

---

## 10. 改訂履歴

| 版数 | 日付 | 変更内容 | 変更者 |
|---|---|---|---|
| v1.0 | 2026-10-20 | 初版：API 104 件（請購 13・詢価 13・訂単 15・収貨 13・退貨 12・発票/対账 19・支払 3・跟踪他 16）、主要 API 詳細、エラーコード対応、発行 5 イベント・購読 7 イベント契約、外部 IF。E17 payload を 09 §3 と逐字一致に調整（Lead 2026-10-20 裁定） | purchase-designer |
| v1.1 | 2026-10-20 | 红队第 2 轮修复：E13 サンプルを 4 明細合計＝amount に整合・購読者 INT のみへ、E16/E35 payload に金額項目を追加（09 改訂）、E17 契約は逐字一致を維持 | purchase-designer |
| v1.2 | 2026-10-21 | 重複・既存系の業務エラーの HTTP を 409 → 422 に統一（409 は楽観排他競合 4003 のみ。03 §5・01-system 91 v1.10 と整合）。対象：:499（蓝色大肥鱼 2026-10-21 決定） | 业务分析 |
