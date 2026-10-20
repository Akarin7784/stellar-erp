# 销售管理 API 详细设计书（販売管理 API 詳細設計書）

| 項目 | 内容 |
|---|---|
| 文書名 | 销售管理 API 详细设计书（販売管理 API 詳細設計書） |
| 文書番号 | DSN-SAL-091 |
| 版数 | v1.1 |
| 作成日 | 2026-10-20 |
| 作成者 | sales-designer（销售域担当） |
| 承認者 | 未承認（レビュー待ち） |
| 状態 | ドラフト（レビュー中） |
| 関連文書 | [業務域概要](00-overview.md) / [API 共通規格](../00-common/03-common-api-spec.md) / [共通項目定義](../00-common/01-common-item-definitions.md) / [跨域流程](../00-common/09-cross-domain-flow.md) / 各機能詳細設計書 |

---

## 1. 基本方針

| # | 方針 |
|---|---|
| 1 | REST + JSON、ベースパス `/api/sales/**`。階層は `/api/sales/{resource}[/{id}][/{sub-resource}][/{action}]`（[API 共通規格 §2](../00-common/03-common-api-spec.md)） |
| 2 | 全 API は Sa-Token 認証 + `@SaCheckPermission`。権限コードは `sales:{resource}:{action}` |
| 3 | レスポンスは `Result<T>` でラップ。`code=0` 成功。一覧は `PageResult<T>` |
| 4 | ID・金額・數量は**文字列**（JS 精度対策）、日付は `yyyy-MM-dd`、日時は ISO 8601 |
| 5 | 登録・状態操作は `Idempotency-Key` 必須、更新は `version` による楽観排他 |
| 6 | 画面向けと外部連携向けを分離。本域に外部公開 API はない（外部連携は INT 域経由） |
| 7 | 一覧はサーバサイドページング必須（`pageNum`/`pageSize`）。全件返却 API は作らない |
| 8 | 削除は傳票では行わない（取消は `/cancel` の状態操作） |

## 2. API 一覧

### 2.1 询价・报价（F-SAL-001/002）

| # | メソッド | パス | 権限 | 概要 |
|---|---|---|---|---|
| 1 | GET | `/api/sales/inquiries` | `sales:inquiry:view` | 引合一覧 |
| 2 | GET | `/api/sales/inquiries/{id}` | `sales:inquiry:view` | 引合詳細 |
| 3 | POST | `/api/sales/inquiries` | `sales:inquiry:create` | 引合登録 |
| 4 | PUT | `/api/sales/inquiries/{id}` | `sales:inquiry:update` | 引合更新（回答含む） |
| 5 | POST | `/api/sales/inquiries/{id}/cancel` | `sales:inquiry:update` | 引合取消 |
| 6 | GET | `/api/sales/quotations` | `sales:quotation:view` | 見積一覧 |
| 7 | GET | `/api/sales/quotations/{id}` | `sales:quotation:view` | 見積詳細 |
| 8 | POST | `/api/sales/quotations` | `sales:quotation:create` | 見積作成 |
| 9 | PUT | `/api/sales/quotations/{id}` | `sales:quotation:create` | 見積更新（10 のみ） |
| 10 | POST | `/api/sales/quotations/{id}/submit` | `sales:quotation:create` | 承認提出 |
| 11 | POST | `/api/sales/quotations/{id}/approve` | `sales:quotation:approve` | 承認 |
| 12 | POST | `/api/sales/quotations/{id}/reject` | `sales:quotation:approve` | 却下 |
| 13 | POST | `/api/sales/quotations/{id}/issue` | `sales:quotation:create` | 發行 |
| 14 | POST | `/api/sales/quotations/{id}/revise` | `sales:quotation:create` | 改訂（新版） |
| 15 | GET | `/api/sales/quotations/{id}/versions` | `sales:quotation:view` | 版數一覧・比較 |
| 16 | POST | `/api/sales/quotations/{id}/convert` | `sales:quotation:convert` | 受注轉換 |
| 17 | POST | `/api/sales/quotations/{id}/print` | `sales:quotation:view` | 見積書 PDF（PRT-SAL-001） |
| 18 | POST | `/api/sales/quotations/{id}/cancel` | `sales:quotation:create` | 見積取消 |

### 2.2 受注（F-SAL-003/004/017）

| # | メソッド | パス | 権限 | 概要 |
|---|---|---|---|---|
| 19 | GET | `/api/sales/sales-orders` | `sales:order:view` | 受注一覧 |
| 20 | GET | `/api/sales/sales-orders/{id}` | `sales:order:view` | 受注詳細（明細・履歴） |
| 21 | POST | `/api/sales/sales-orders` | `sales:order:create` | 受注登録 |
| 22 | PUT | `/api/sales/sales-orders/{id}` | `sales:order:update` | 受注更新（10 のみ） |
| 23 | POST | `/api/sales/sales-orders/{id}/submit` | `sales:order:submit` | 提出（E05） |
| 24 | POST | `/api/sales/sales-orders/{id}/approve` | `sales:order:approve` | 承認（E06） |
| 25 | POST | `/api/sales/sales-orders/{id}/return` | `sales:order:approve` | 差戻し |
| 26 | POST | `/api/sales/sales-orders/{id}/reject` | `sales:order:approve` | 却下 |
| 27 | POST | `/api/sales/sales-orders/{id}/withdraw` | `sales:order:submit` | 撤回 |
| 28 | POST | `/api/sales/sales-orders/{id}/cancel` | `sales:order:cancel` | 取消（E08） |
| 29 | POST | `/api/sales/sales-orders/{id}/close` | `sales:order:close` | クローズ |
| 30 | POST | `/api/sales/sales-orders/{id}/changes` | `sales:order:change` | 変更開始（版作成） |
| 31 | PUT | `/api/sales/sales-orders/{id}/changes/{versionNo}` | `sales:order:change` | 変更內容保存 |
| 32 | POST | `/api/sales/sales-orders/{id}/changes/{versionNo}/submit` | `sales:order:submit` | 変更提出 |
| 33 | POST | `/api/sales/sales-orders/{id}/changes/{versionNo}/approve` | `sales:order:approve` | 変更承認（E07） |
| 34 | GET | `/api/sales/sales-orders/{id}/changes` | `sales:order:view` | 変更履歴 |
| 35 | GET | `/api/sales/sales-orders/{id}/credit-check` | `sales:credit:view` | 與信再判定 |
| 36 | POST | `/api/sales/sales-orders/{id}/print` | `sales:order:print` | 注文請書（PRT-SAL-002） |
| 37 | POST | `/api/sales/sales-orders/batch-submit` | `sales:order:submit` | 一括提出 |
| 38 | POST | `/api/sales/sales-orders/batch-approve` | `sales:order:approve` | 一括承認 |

### 2.3 出荷（F-SAL-005/018）

| # | メソッド | パス | 権限 | 概要 |
|---|---|---|---|---|
| 39 | GET | `/api/sales/delivery-notes` | `sales:delivery:view` | DN 一覧 |
| 40 | GET | `/api/sales/delivery-notes/{id}` | `sales:delivery:view` | DN 詳細 |
| 41 | POST | `/api/sales/delivery-notes` | `sales:delivery:create` | DN 作成 |
| 42 | PUT | `/api/sales/delivery-notes/{id}` | `sales:delivery:update` | DN 更新（25 のみ） |
| 43 | POST | `/api/sales/delivery-notes/{id}/start-picking` | `sales:delivery:pick` | ピッキング開始 |
| 44 | PUT | `/api/sales/delivery-notes/{id}/lines/{lineId}/pick` | `sales:delivery:pick` | ピッキング確定 |
| 45 | POST | `/api/sales/delivery-notes/{id}/confirm` | `sales:delivery:confirm` | 出荷確定（E10） |
| 46 | POST | `/api/sales/delivery-notes/{id}/cancel` | `sales:delivery:cancel` | DN 取消 |
| 47 | POST | `/api/sales/delivery-notes/{id}/print` | `sales:delivery:print` | 送り状（PRT-SAL-004） |
| 48 | POST | `/api/sales/delivery-notes/batch-confirm` | `sales:delivery:confirm` | 一括出荷確定（上限 200） |
| 49 | GET | `/api/sales/shipments` | `sales:delivery:view` | 出荷実績照会 |
| 50 | GET | `/api/sales/shipments/trace` | `sales:delivery:view` | 序列號トレース |

### 2.4 返品（F-SAL-006/014）

| # | メソッド | パス | 権限 | 概要 |
|---|---|---|---|---|
| 51 | GET | `/api/sales/returns` | `sales:return:view` | 返品一覧 |
| 52 | GET | `/api/sales/returns/{id}` | `sales:return:view` | 返品詳細 |
| 53 | POST | `/api/sales/returns` | `sales:return:create` | 返品登録 |
| 54 | PUT | `/api/sales/returns/{id}` | `sales:return:create` | 返品更新（10 のみ） |
| 55 | POST | `/api/sales/returns/{id}/submit` | `sales:return:create` | 返品提出 |
| 56 | POST | `/api/sales/returns/{id}/approve` | `sales:return:approve` | 返品承認 |
| 57 | POST | `/api/sales/returns/{id}/inspection/start` | `sales:return:inspect` | 検品開始 |
| 58 | POST | `/api/sales/returns/{id}/inspection/confirm` | `sales:return:inspect` | 検品確定（E11） |
| 59 | POST | `/api/sales/returns/{id}/cancel` | `sales:return:cancel` | 返品取消 |
| 60 | POST | `/api/sales/returns/{id}/print` | `sales:return:view` | 返品受付票（PRT-SAL-006） |
| 61 | GET | `/api/sales/returns/returnable-lines` | `sales:return:view` | 返品可能明細照会 |
| 62 | POST | `/api/sales/exchanges` | `sales:exchange:create` | 換貨作成（返品＋新規受注） |
| 63 | GET | `/api/sales/delivery-notes/{id}/serials` | `sales:return:view` | 元出荷序列號照会 |

### 2.5 開票・対账・應收（F-SAL-007/008/009）

| # | メソッド | パス | 権限 | 概要 |
|---|---|---|---|---|
| 64 | GET | `/api/sales/invoice-applications` | `sales:invoice-application:view` | 開票申請一覧 |
| 65 | GET | `/api/sales/invoice-applications/invoiceable` | `sales:invoice-application:view` | 未開票明細照会 |
| 66 | POST | `/api/sales/invoice-applications` | `sales:invoice-application:create` | 開票申請作成 |
| 67 | PUT | `/api/sales/invoice-applications/{id}` | `sales:invoice-application:create` | 申請更新（10 のみ） |
| 68 | POST | `/api/sales/invoice-applications/{id}/submit` | `sales:invoice-application:create` | 提出 |
| 69 | POST | `/api/sales/invoice-applications/{id}/approve` | `sales:invoice:approve` | 承認 |
| 70 | GET | `/api/sales/invoices` | `sales:invoice:view` | 発票一覧 |
| 71 | GET | `/api/sales/invoices/{id}` | `sales:invoice:view` | 発票詳細 |
| 72 | POST | `/api/sales/invoices` | `sales:invoice:create` | 発票登録（E12） |
| 73 | POST | `/api/sales/invoices/{id}/deliver` | `sales:invoice:create` | 交付 |
| 74 | POST | `/api/sales/invoices/{id}/red` | `sales:invoice:red` | 赤伝登録（E12 RED） |
| 75 | POST | `/api/sales/invoices/{id}/reissue` | `sales:invoice:create` | 再発行（寫し） |
| 76 | POST | `/api/sales/invoices/{id}/print` | `sales:invoice:view` | 発票 PDF（PRT-SAL-008） |
| 77 | POST | `/api/sales/statements/generate` | `sales:statement:create` | 対账单生成 |
| 78 | GET | `/api/sales/statements` | `sales:statement:view` | 対账单一覧 |
| 79 | GET | `/api/sales/statements/{id}` | `sales:statement:view` | 対账单詳細 |
| 80 | POST | `/api/sales/statements/{id}/send` | `sales:statement:create` | 対账单送付 |
| 81 | POST | `/api/sales/statements/{id}/confirm` | `sales:statement:confirm` | 顧客確認 |
| 82 | POST | `/api/sales/statements/{id}/print` | `sales:statement:view` | 対账单 PDF（PRT-SAL-009） |
| 83 | GET | `/api/sales/receivables` | `sales:receivable:view` | 應收一覧 |
| 84 | GET | `/api/sales/receivables/aging` | `sales:receivable:view` | 帳齡分析（FIN API） |

### 2.6 與信・価格（F-SAL-010/011）

| # | メソッド | パス | 権限 | 概要 |
|---|---|---|---|---|
| 85 | GET | `/api/sales/credits` | `sales:credit:view` | 與信一覧 |
| 86 | GET | `/api/sales/credits/{customerId}` | `sales:credit:view` | 與信詳細 |
| 87 | GET | `/api/sales/credits/{customerId}/check` | `sales:credit:view` | 與信再判定 |
| 88 | GET | `/api/sales/credits/{customerId}/ledger` | `sales:credit:view` | 與信台帳投影明細（FIN 台帳の読取） |
| 89 | POST | `/api/sales/credit-overrides` | `sales:credit:submit` | 與信超限承認申請 |
| 90 | GET | `/api/sales/special-prices` | `sales:price-override:view` | 特價一覧 |
| 91 | GET | `/api/sales/special-prices/{id}` | `sales:price-override:view` | 特價詳細 |
| 92 | POST | `/api/sales/special-prices` | `sales:price-override:create` | 特價登録 |
| 93 | PUT | `/api/sales/special-prices/{id}` | `sales:price-override:create` | 特價更新（10 のみ） |
| 94 | POST | `/api/sales/special-prices/{id}/submit` | `sales:price-override:create` | 特價提出 |
| 95 | POST | `/api/sales/special-prices/{id}/approve` | `sales:price-override:approve` | 特價承認 |
| 96 | POST | `/api/sales/special-prices/{id}/cancel` | `sales:price-override:approve` | 特價取消 |
| 97 | POST | `/api/sales/special-prices/{id}/print` | `sales:price-override:view` | 特價審批單（PRT-SAL-016） |

### 2.7 追蹤・予測・レポート（F-SAL-012/013/015/016）

| # | メソッド | パス | 権限 | 概要 |
|---|---|---|---|---|
| 98 | GET | `/api/sales/order-tracking` | `sales:tracking:view` | 訂單執行跟蹤 |
| 99 | GET | `/api/sales/order-tracking/summary` | `sales:tracking:view` | KPI サマリ |
| 100 | GET | `/api/sales/order-tracking/shortages` | `sales:tracking:view` | 欠品一覧 |
| 101 | GET | `/api/sales/order-tracking/delays` | `sales:tracking:view` | 納期遅延一覧 |
| 102 | PUT | `/api/sales/order-tracking/{orderId}/memo` | `sales:tracking:view` | 追跡メモ追記 |
| 103 | GET | `/api/sales/forecasts` | `sales:forecast:view` | 予測一覧（P2） |
| 104 | POST | `/api/sales/forecasts` | `sales:forecast:create` | 予測保存（P2） |
| 105 | POST | `/api/sales/forecasts/{id}/confirm` | `sales:forecast:create` | 予測確定（P2） |
| 106 | GET | `/api/sales/reports/sales-detail` | `sales:report:view` | 売上明細 |
| 107 | GET | `/api/sales/reports/gross-profit` | `sales:report:view` | 粗利分析 |
| 108 | GET | `/api/sales/reports/customer-ranking` | `sales:report:view` | 顧客排名 |
| 109 | GET | `/api/sales/reports/sales-summary` | `sales:report:view` | 売上サマリ |
| 110 | PUT | `/api/sales/sales-orders/{id}/export-info` | `sales:export:update` | 輸出販売情報（P2） |
| 111 | POST | `/api/sales/exports` | `sales:report:export` | 非同期エクスポート |
| 112 | GET | `/api/sales/jobs/{jobId}` | `sales:report:export` | ジョブ狀態 |
| 113 | GET | `/api/sales/jobs/{jobId}/files/{fileId}` | `sales:report:export` | ジョブ結果 DL |

### 2.8 他域呼出契約（本域が呼び出す API）

| # | メソッド | パス | 提供域 | 用途 |
|---|---|---|---|---|
| C1 | GET | `/api/mdm/materials/{id}` | MDM | 物料取得 |
| C2 | GET | `/api/mdm/materials/by-code/{code}` | MDM | 物料コード照会 |
| C3 | GET | `/api/mdm/customers/{id}` | MDM | 顧客取得 |
| C4 | GET | `/api/mdm/customers/{id}/credit-limit` | MDM | 與信限度取得 |
| C5 | GET | `/api/mdm/prices/sales/effective` | MDM | 有效價格照会（必須：`unitPriceNet`/`unitPriceGross`/`isTaxIncluded`/`discountRate`/`validFrom`/`validTo`、無価格 404+20036） |
| C6 | POST | `/api/mdm/prices/sales/effective-batch` | MDM | 有效價格一括照会 |
| C7 | GET | `/api/mdm/tax-codes/{code}` | MDM | 税碼取得 |
| C8 | GET | `/api/mdm/payment-terms/{code}` | MDM | 付款條件取得 |
| C9 | GET | `/api/mdm/warehouses/{id}` | MDM | 倉庫取得 |
| C10 | GET | `/api/inventory/stock-balances/available` | INV | 可用量照会 |
| C11 | GET | `/api/inventory/stock-balances/available-batches` | INV | 批次可用明細（FEFO/FIFO） |
| C12 | GET | `/api/inventory/stock-txns` | INV | 在庫取引照会（SDO 状況） |
| C13 | GET | `/api/finance/customers/{customerId}/credit-usage` | FIN | 與信台帳使用額（FIN 権威。應收殘・受注コミット・前受金） |
| C14 | GET | `/api/finance/ar-aging` | FIN | 帳齡分析 |
| C15 | GET | `/api/finance/receivables` | FIN | 應收照会 |
| C16 | POST | `/api/workflow/processes` | WF | 承認プロセス開始 |
| C17 | GET | `/api/system/sequences/{key}` | SYS | 採番（サーバ內部） |

> C1〜C17 は他域が提供する公開 API。本域は呼出條件・タイムアウト・失敗時の扱いのみ規定し、項目定義は提供域の設計書を正とする（[02-mdm/91](../02-mdm/91-api-design.md)、[05-inventory/91](../05-inventory/91-api-design.md)、[07-finance/91](../07-finance/91-api-design.md)）。

## 3. 共通仕様参照

- 認証・認可：`Authorization: {token}`（Sa-Token）。`401`/`403` の扱いは [API 共通規格 §3/§4](../00-common/03-common-api-spec.md)。
- レスポンス：`Result<T>`（`code`/`message`/`data`）。一覧は `PageResult<T>`（`list`/`total`/`pageNum`/`pageSize`/`pages`）。
- エラー：HTTP ステータス + 業務コード。SAL 領域は `30000-39999`。
- ページング：`pageNum`（1 始まり、既定 1）、`pageSize`（既定 20、最大 200）、`sort`（`field,asc`）。
- 検索條件：`keyword`、`status`、`dateFrom`/`dateTo`、`customerId` など。両端含む。
- 冪等：登録・状態操作は `Idempotency-Key: {UUID}` 必須。24 時間保持。
- 楽観排他：更新・状態操作は `version` 必須。競合は `409` + `code=4003`。
- 非同期：エクスポート・大量出力は `202` + `jobId`。`GET /api/sales/jobs/{jobId}` で狀態確認。

## 4. API 詳細

### 4.1 詢価・報価 API

#### 4.1.1 `POST /api/sales/quotations`（見積作成）

- 目的：引合または直接入力から見積を作成する。取價・承認要否判定・採番を行う。
- 権限：`sales:quotation:create`
- 冪等：`Idempotency-Key` 必須
- リクエスト項目：

| 項目 | 型 | 必須 | 説明 |
|---|---|---|---|
| `inquiryId` | string | △ | 引合 ID（あれば引合を 40 に更新） |
| `customerId` | string | ○ | 顧客 ID |
| `ownerUserId` | string | ○ | 営業擔當 |
| `issueDate` | date | ○ | 発行日（既定 當日） |
| `validFrom` / `validTo` | date | ○ | 有効期限（最大 180 日） |
| `currencyCode` | string | ○ | 通貨（当面 CNY（多币种第一版対象）） |
| `priceListId` | string | △ | 価格表 ID |
| `paymentTermCode` | string | ○ | 付款條件コード |
| `lines[]` | array | ○ | 明細（`materialId`、`qty`/`orderedQty`、`uomCode`、`baseUomCode`、`conversionRate`、`baseQty`、`shippedQty`、`shippedBaseQty`、`unitPrice`、`taxCode`、`discountRate`、`deliveryDate`）。數量は販売単位と基本単位の両方を返す |

- 正常例（201）：

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "id": "1845222000000000001",
    "quotationNo": "QT2610200001",
    "revisionNo": 1,
    "quotationStatus": 10,
    "approvalRequired": false,
    "validFrom": "2026-10-20",
    "validTo": "2026-11-19",
    "totalAmount": "102780.00",
    "taxAmount": "23259.60",
    "grandTotal": "202179.60",
    "version": 0
  }
}
```

- エラー：`1001` 入力エラー（`MSG-COM-040`）、`30013` 見積發行不可（`MSG-SAL-171`）、`20001` 物料無効（`MSG-SAL-006`）、`20002` 取價不能（`MSG-SAL-012`、警告扱い）。

#### 4.1.2 `POST /api/sales/quotations/{id}/convert`（受注轉換）

- 目的：有効見積から受注を作成する（部分轉換可）。
- 権限：`sales:quotation:convert`
- リクエスト：

```json
{
  "version": 2,
  "lines": [
    { "lineId": "1845222000000000101", "convertQty": "120.0000" },
    { "lineId": "1845222000000000102", "convertQty": "60.0000" }
  ],
  "salesOrderDraft": { "orderDate": "2026-10-20", "deliveryDate": "2026-10-30", "warehouseId": "1847000000000000011" }
}
```

- 正常例：`data.quotationStatus=35`、`data.salesOrders[]` に受注番號を返す。
- エラー：`30014` 轉換不可（期限切れ／數量超過／狀態不正、`MSG-SAL-183/184`）。

### 4.2 受注 API

#### 4.2.1 `POST /api/sales/sales-orders`（受注登録）

- 目的：受注を登録し、取價・可用量・與信を判定して下書きを作成する。
- 権限：`sales:order:create` / 冪等キー必須
- リクエスト／レスポンス：詳細は [02-sales-order.md §7.2](02-sales-order.md) を正とする。
- 主な処理：入力チェック→會計期間確認→MDM 取得→取價→金額計算→可用量照会→與信判定→採番→INSERT→監査ログ。
- エラー：`30001` 與信超過（`MSG-SAL-020/021/022`）、`30002` 引當不可、`50001` 在庫不足（`MSG-SAL-030`、警告）、`4003` 楽観排他。

#### 4.2.2 `POST /api/sales/sales-orders/{id}/submit`（提出）

```json
{ "version": 0, "comment": "10月度分、納期10/30" }
```

- 処理：狀態 10 確認→與信再判定→WF 送信→狀態 20→E05 Outbox。
- 正常例：`data.orderStatus=20`、`data.processInstanceId`。
- エラー：`4002` 状態不整合（`MSG-COM-034`）、`30001` 與信超過（`MSG-SAL-022`）、`4004` 期間締切（`MSG-COM-071`）。

#### 4.2.3 `POST /api/sales/sales-orders/{id}/approve`（承認）

- 目的：WF 承認コールバック。最終承認で E06 発行・與信コミット。
- 権限：`sales:order:approve`（承認者本人のみ）
- リクエスト：`{ "version": 1, "taskId": "…", "comment": "承認" }`
- 正常例：`data.orderStatus=25`、`data.eventType="sales.order.approved"`、`data.creditCheckResult=10`（10 正常/20 注意/30 超限審査中/40 超限承認済/90 凍結・閉鎖）。
- エラー：`30003` 自己承認（`MSG-SAL-018`）、`30001` 與信悪化（`MSG-SAL-022`、承認保留）。

#### 4.2.4 `POST /api/sales/sales-orders/{id}/changes`（変更開始）

- 目的：承認済受注の変更版を作成する。
- 権限：`sales:order:change`
- リクエスト：`{ "version": 2, "changeType": 10, "changeReason": "顧客納期前倒し" }`
- 正常例：`data.versionNo=2`、`data.changeStatus=10`、変更前スナップショット作成。
- エラー：`30002` 変更不能狀態（`MSG-SAL-048`）、`30001` 與信超過。

#### 4.2.5 `POST /api/sales/sales-orders/{id}/cancel`（取消）

```json
{ "version": 3, "reason": "顧客都合キャンセル", "cancelRemainingOnly": false }
```

- 処理：状態確認→出荷有無確認→與信解放→狀態 90→E08 Outbox。
- エラー：`30005` 出荷済で取消不可（`MSG-SAL-046`）、`30002` 状態不整合。

#### 4.2.6 一括操作

`POST /api/sales/sales-orders/batch-submit` / `batch-approve`

```json
{ "ids": ["1845678901234567890", "1845678901234567891"], "comment": "一括提出" }
```

- レスポンス：

```json
{
  "code": 0,
  "message": "ok",
  "data": { "successCount": 1, "failureCount": 1, "failures": [ { "id": "1845678901234567891", "reason": "与信限度額を超過しています（MSG-SAL-021）" } ] }
}
```

- 上限 1,000 件。全件成功 or 全件失敗が既定（部分成功を返す場合は失敗一覧必須）。

### 4.3 出荷 API

#### 4.3.1 `POST /api/sales/delivery-notes`（DN 作成）

- 権限：`sales:delivery:create` / 冪等キー必須
- リクエスト：受注 ID・出荷日・倉庫・明細（`salesOrderLineId`、`plannedQty`）。詳細は [03-delivery-picking.md §7.2](03-delivery-picking.md)。
- 正常例：`deliveryNo=DN2610200001`、`deliveryStatus=25`。

#### 4.3.2 `POST /api/sales/delivery-notes/{id}/confirm`（出荷確定・E10 発行）

- 権限：`sales:delivery:confirm` / 冪等キー必須
- リクエスト：

```json
{
  "version": 2,
  "deliveryDate": "2026-10-24",
  "lines": [ { "lineId": "1845777000000000101", "shippedQty": "80.0000" } ],
  "comment": "第1回出荷確定"
}
```

- 処理：状態確認→ピッキング数量一致→引當/在庫可用量檢証→與信再判定→DN/SO 更新→與信解放→E10 Outbox→監査ログ。
- 正常例：`deliveryStatus=40`、`salesOrderStatus=35`、`eventType=sales.delivery.confirmed`。
- エラー：`30002` 引當なし（`MSG-SAL-101`）、`30004` ピッキング不足（`MSG-SAL-111`）、`30005` 與信超過で出荷保留（`MSG-SAL-085`）、`50001` 在庫不足、`4004` 締切。

#### 4.3.3 `GET /api/sales/shipments/trace?serialNo=SN-YE3-2610-0001`

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "serialNo": "SN-YE3-2610-0001",
    "materialCode": "3001000001",
    "materialName": "YE3-100L1-4 三相异步电动机 2.2kW 4极",
    "deliveryNo": "DN2610200001",
    "deliveryDate": "2026-10-24",
    "salesOrderNo": "SO2610200001",
    "customerCode": "C000001",
    "customerName": "江苏恒立液压股份有限公司",
    "returnStatus": "NOT_RETURNED",
    "deliveryStatus": 40
  }
}
```

### 4.4 返品 API

#### 4.4.1 `GET /api/sales/returns/returnable-lines?deliveryId={id}`

- 権限：`sales:return:view`
- レスポンス：元出荷明細ごとに `originalQty`/`returnedQty`/`returnableQty`/`unitPrice`/`taxRate`/`batchNo`/`serialNos`/`returnDeadlineDate`/`isOverdue` を返す。

#### 4.4.2 `POST /api/sales/returns`（返品登録）

- 権限：`sales:return:create` / 冪等キー必須
- リクエスト：`originalDeliveryId`、`returnDate`、`returnReasonCode`、`freightBearer`、`redInvoiceRequired`、`lines[]`（`originalDeliveryLineId`、`returnQty`、`serialNos`）。
- 正常例：`returnNo=SRT2610280001`、`returnStatus=10`、`returnDeadlineDate`。詳細例は [04-sales-return.md §7.2](04-sales-return.md)。

#### 4.4.3 `POST /api/sales/returns/{id}/inspection/confirm`（検品確定・E11 発行）

- 権限：`sales:return:inspect` / 冪等キー必須
- リクエスト：

```json
{
  "version": 2,
  "lines": [
    {
      "lineId": "1845888000000000101",
      "inspectedQty": "20.0000",
      "inspectionResult": "REWORK",
      "inventoryStatus": 20,
      "defectReason": "轴承异音，需更换轴承后复检",
      "serialNos": ["SN-YE3-2610-0001", "SN-YE3-2610-0002"]
    }
  ]
}
```

- 処理：状態 25 確認→検品檢証→元出荷明細ロック→状態 30→E11 Outbox。
- 正常例：`returnStatus=30`、`eventType=sales.return.confirmed`、`inventoryStatusSummary`。
- エラー：`30006` 返品不可（`MSG-SAL-120`）、`30007` 検品確定不可（`MSG-SAL-122/133`）、`4004` 締切。

### 4.5 開票・対账・應收 API

#### 4.5.1 `POST /api/sales/invoices`（発票登録・E12 発行）

- 権限：`sales:invoice:create` / 冪等キー必須
- リクエスト：

```json
{
  "applicationId": "1846111000000000001",
  "invoiceNo": "26322000000012345678",
  "invoiceCode": null,
  "invoiceType": 30,
  "issuedAt": "2026-10-31",
  "deliveryMethod": 10,
  "buyerName": "江苏恒立液压股份有限公司",
  "buyerTaxNo": "9132**************",
  "attachmentId": "1846222000000000001"
}
```

- 処理：申請狀態 25 確認→発票番號一意・形式檢証→金額一致檢証→INSERT→申請 30→E12 Outbox。
- 正常例：`invoiceKind=E_INVOICE`、`eventType=sales.invoice.issued`、`arLinkStatus=10`。E12 payload は [05-invoice-receivable.md §7.2](05-invoice-receivable.md)。
- エラー：`30010` 発票登録不可（`MSG-SAL-141/142/156/157/158/159`）。

#### 4.5.2 `POST /api/sales/invoices/{id}/red`（赤伝・E12 RED）

```json
{
  "version": 1,
  "redType": "FULL",
  "redReason": "返品による赤伝（SRT2610280001）",
  "returnId": "1845888000000000001"
}
```

- 権限：`sales:invoice:red`（財務經理以上）／冪等キー必須
- 正常例：`invoiceKind=RED`、`originalInvoiceId`、`eventType=sales.invoice.issued`。
- エラー：`30011` 赤伝不可（`MSG-SAL-124/161`）。

#### 4.5.3 `POST /api/sales/statements/generate`

```json
{ "customerId": "1845000000000000001", "periodCode": "2026-09", "sendAfterGenerate": false }
```

- 権限：`sales:statement:create` / 冪等キー必須
- 処理：FIN 應收・入金照会→殘高計算→差異チェック→採番→INSERT。
- 正常例：`statementNo=STM2610050001`、`closingBalance`、`finBalance`、`balanceDiff`。
- エラー：`30012` 対账单生成不可（`MSG-SAL-143/160`）、`MICROFIN` 障害（`MSG-SAL-081`）。

#### 4.5.4 `GET /api/sales/receivables/aging?asOf=2026-10-20&customerId=C000001`

- 権限：`sales:receivable:view`
- 処理：FIN `GET /api/finance/ar-aging` を呼び出し、結果をそのまま返す（SAL 独自集計は禁止、BR-ST-06）。
- レスポンス例：`buckets[]`（未到期/1-30/31-60/61-90/91-180/181-360/360 超）、`dso`、`totalBalance`、`overdueAmount`。詳細は [05-invoice-receivable.md §7.2](05-invoice-receivable.md)。

### 4.6 與信・価格 API

#### 4.6.1 `GET /api/sales/credits/{customerId}/check`（與信再判定）

- 権限：`sales:credit:view`
- クエリ：`orderAmount`（判定する受注額）、`checkType`（10 登録/20 提出/30 承認/40 出荷）。
- 処理：MDM 限度額・ルール取得→FIN 與信使用額取得→SAL コミット殘集計→CALC-CR-01〜06→判定ログ INSERT。
- 正常例：

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "creditLimitAmount": "5000000.00",
    "creditUsedAmount": "3900000.00",
    "orderAmount": "116141.40",
    "usedAfterOrder": "4016141.40",
    "creditOverAmount": "0.00",
    "creditCheckResult": 10,
    "creditAction": "CONTINUE",
    "ruleId": "1845000000000000901",
    "checkedAt": "2026-10-20T14:30:00+08:00"
  }
}
```

- エラー：`30017` 與信判定不可（限度未設定／FIN 障害、`MSG-SAL-080/081`）、`30001` 與信超過（`MSG-SAL-020/021/022`）。

#### 4.6.2 `POST /api/sales/special-prices`（特價登録）

- 権限：`sales:price-override:create` / 冪等キー必須
- リクエスト例：

```json
{
  "customerId": "1845000000000000001",
  "materialId": "1845000000000000101",
  "specialUnitPrice": "856.500000",
  "minQty": "100.0000",
  "currencyCode": "CNY",
  "taxCode": "VAT13-OUT",
  "validFrom": "2026-10-20",
  "validTo": "2027-10-19",
  "reasonType": "COMPETITION",
  "reason": "竞品报价 850 元，为保住年度框架合同申请特价"
}
```

- 正常例：`specialPriceNo=SP2610200001`、`grossMarginRate`、`approvalRoute`。
- エラー：`30015` 特價不可（`MSG-SAL-091/092/093`）、`20001` 物料無効。

#### 4.6.3 `GET /api/sales/credits`（與信一覧）

- 権限：`sales:credit:view`
- クエリ：`customerId`、`creditStatus`、`overOnly`、`keyword`、`pageNum`、`pageSize`。
- レスポンス：顧客ごとに `creditLimitAmount`・`receivableBalance`・`overdueAmount`・`orderCommitment`・`unappliedAmount`・`creditUsedAmount`・`creditAvailableAmount`・`usageRate`・`creditStatus`。金額は FIN 照会値をそのまま使用（キャッシュ 5 分）。

### 4.7 追蹤・レポート・予測 API

#### 4.7.1 `GET /api/sales/order-tracking`

- 権限：`sales:tracking:view`
- クエリ：`status`（複數可）、`customerId`、`ownerUserId`、`deliveryDateFrom/To`、`shortageOnly`、`delayOnly`、`pageNum`、`pageSize`。
- レスポンス：`list[].openQty`/`reservedQty`/`shortageQty`/`delayDays`/`isReady`/`executionStatus`、`summary`（KPI）。詳細は [07-tracking-reports.md §7.2](07-tracking-reports.md)。

#### 4.7.2 `GET /api/sales/reports/sales-detail`

- 権限：`sales:report:view`
- クエリ：`dateFrom`、`dateTo`、`customerId`、`materialId`、`groupBy`（10 顧客/20 物料/30 月/40 擔當）、`amountBasis`（10 稅抜/20 稅込）、`pageNum`、`pageSize`。
- レスポンス：`salesAmount`、`taxAmount`、`totalAmount`、`costAmount`（権限時）、`grossProfit`、`grossMarginRate`、`costEstimated`。
- エラー：`95001` 集計対象なし（RPT 域と共通コードを使用）、`3001` 権限なし。

#### 4.7.3 `POST /api/sales/exports`（非同期エクスポート）

```json
{
  "exportType": "SALES_ORDER_LIST",
  "query": { "orderDateFrom": "2026-10-01", "orderDateTo": "2026-10-31", "status": [25,30,35] },
  "columns": ["salesOrderNo", "customerName", "orderDate", "grandTotal", "orderStatus"]
}
```

- レスポンス（202）：

```json
{ "code": 0, "message": "ok", "data": { "jobId": "1846555000000000001", "status": "QUEUED" } }
```

- `GET /api/sales/jobs/{jobId}` → `status: QUEUED/RUNNING/SUCCEEDED/FAILED`、`progress`、`resultFileId`。
- ジョブ結果は 7 日保存。1 回 10,000 件超は非同期必須。

### 4.8 イベント連動 API（內部）

| 処理 | 契機 | 呼出/購読 | 処理 |
|---|---|---|---|
| E05 提出 | 受注・見積・返品・開票申請・特價の提出 | Outbox 発行 | WF プロセス開始 |
| E06 承認 | 受注最終承認 | Outbox 発行 | INV 引當、FIN 與信コミット |
| E07 変更 | 受注変更確定 | Outbox 発行 | INV 引當増減 |
| E08 取消 | 受注取消 | Outbox 発行 | INV 引當解除、FIN 與信解放 |
| E09 引當 | INV から購読 | `@ApplicationModuleListener` | 受注明細 `reserved_qty`・狀態 30 |
| E10 出荷確定 | 出荷確定 | Outbox 発行 | INV 出庫、FIN 売上・應收 |
| E11 返品確定 | 検品確定 | Outbox 発行 | INV 在庫戻入、FIN 赤伝 |
| E12 発票 | 発票登録・赤伝 | Outbox 発行 | FIN 銷項台帳・AR 紐付け |
| E18 原價 | INV から購読 | 購読 | DN 明細・返品明細の原價更新 |
| E27/E29 | FIN から購読 | 購読 | 應收投影・與信解放 |
| E31/E32 | WF から購読 | 購読 | 状態更新・E06 発行 |

## 5. エラーコード対応表（SAL 領域 30000-39999）

| code | HTTP | メッセージ ID | 概要 |
|---|---|---|---|
| 30001 | 422 | MSG-SAL-020/021/022 | 與信超過・単筆上限超過・超限承認要 |
| 30002 | 409 | MSG-SAL-100/101/048 | 受注・引當の状態不整合 |
| 30003 | 403 | MSG-SAL-018 | 自己承認・承認権限なし |
| 30004 | 422 | MSG-SAL-103/104/111 | ピッキング不可（批次・序列號・數量不整合） |
| 30005 | 422 | MSG-SAL-085/036 | 出荷確定不可（與信・數量・引當） |
| 30006 | 422 | MSG-SAL-120/121/122 | 返品受付不可（元出荷・期限・數量） |
| 30007 | 422 | MSG-SAL-123/124/133 | 返品検品不可・赤伝不可 |
| 30008 | 422 | MSG-SAL-002/006 | 主データ無効（顧客・物料） |
| 30009 | 422 | MSG-SAL-140/141/155 | 開票申請不可 |
| 30010 | 422 | MSG-SAL-142/156/157/158/159 | 発票登録不可 |
| 30011 | 422 | MSG-SAL-124/161 | 赤伝不可 |
| 30012 | 422 | MSG-SAL-143/160 | 対账单生成不可 |
| 30013 | 422 | MSG-SAL-170/171 | 見積発行不可 |
| 30014 | 422 | MSG-SAL-183/184/185 | 見積轉換不可 |
| 30015 | 422 | MSG-SAL-091/092/093/094 | 特價登録不可 |
| 30016 | 409 | MSG-COM-035 | 與信ロック・同時処理競合 |
| 30017 | 422 | MSG-SAL-080/081 | 與信判定不可（限度未設定・FIN 障害） |
| 30018 | 422 | MSG-SAL-036/047 | 數量超過（受注殘・引當殘） |
| 30019 | 422 | MSG-SAL-121 | 期限超過（返品・見積） |
| 30020 | 409 | MSG-COM-050 / MSG-SAL-093/156 | 業務キー重複 |
| 30021 | 422 | MSG-SAL-102/110 | 出荷日・倉庫不正 |
| 30022 | 422 | MSG-SAL-056 | 受注変更：変更後數量 < 已完工數量（基本単位） |
| 30050 | 400 | MSG-COM-084 | 処理中・二重起動 |
| 30090 | 500 | MSG-COM-080 | その他サーバエラー（trace_id） |

- 共通コード（`1001〜1005`、`2001〜2004`、`3001〜3003`、`4001〜4005`、`5000`）は [API 共通規格 §6](../00-common/03-common-api-spec.md) を使用する。
- メッセージ本文は [93-messages.md](93-messages.md) と [05-common-message-list.md](../00-common/05-common-message-list.md) を正とする。

## 6. 非機能要件（API）

| 項目 | 目標 | 前提 |
|---|---|---|
| 応答時間（参照） | 2 秒以内（一覧 100 件） | インデックス・ページング |
| 応答時間（更新） | 3 秒以内 | 採番・與信照会・在庫照会含む |
| 同時リクエスト | 100 req/秒（ピーク） | 営業 50・倉庫 20 |
| 冪等キー保持 | 24 時間 | `sys_idempotency` |
| 監査ログ | 更新・狀態操作は 100% 記錄 | `sys_audit_log` |
| 外部 IF | INT 域経由、10 秒タイムアウト・3 回リトライ |  |
| エクスポート | 同期 10,000 件 / 非同期は 1 分以内 | ジョブ基盤 |

## 7. 未決事項

| # | 事項 | 理由 | 暫定仕様 | 担当 | 期限 |
|---|---|---|---|---|---|
| 1 | 他域 API（MDM/INV/FIN）の最終パス・DTO 項目名 | 各域設計が並行中のため | 本域の呼出は §2.8 のパスを想定。相違時は提供域を正とし本域を修正 | mdm/inventory/finance-designer | 2026-10-24 |
| 2 | E09/E18 購読のリトライ・DLQ 運用 | 共通基盤の実装待ち | Outbox 再送 + 日次照合（BAT-SAL-008） | Lead / system-workflow | 2026-11-01 |
| 3 | 外部 IF（數電票）のレート制限・再送仕様 | INT 域  | INT 域の設計に従う | integration-designer | 2026-11-15 |
| 4 | エラーコードの域內連番確定 | 本表は暫定採番（30001〜30090） | 実装時に `error_code` 定数クラスで一元管理 | sales-designer | 2026-10-28 |
| 5 | 一括操作の部分成功可否 | 機能ごとに要件が異なる | 既定は全件成功 or 全件失敗。失敗一覧を返す | Lead | 2026-10-28 |

## 8. 改訂履歴

| 版数 | 日付 | 変更內容 | 変更者 |
|---|---|---|---|
| v1.0 | 2026-10-20 | 初版作成：API 113 件の一覧、他域呼出契約 17 件、主要 API のリクエスト/レスポンス、SAL エラーコード対応表、非機能要件 | sales-designer |
| v1.1 | 2026-10-20 | 紅隊修復第 2 輪：與信台帳 API を `/ledger`（FIN 投影・読取）へ変更、與信判定コードを 10/20/30/40/90 に統一、FIN credit-usage の権威を明記、取價 API の MDM 新契約（`unitPriceNet`/`unitPriceGross`/`discount`/20036）を反映 | sales-designer |










