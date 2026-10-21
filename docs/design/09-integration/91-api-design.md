# 集成管理 API 设计书（集成管理 API 設計書）

| 項目 | 内容 |
|---|---|
| 文書名 | 集成管理 API 设计书（集成管理 API 設計書） |
| 文書番号 | DSN-INT-091 |
| 版数 | v1.0 |
| 作成日 | 2026-10-20 |
| 作成者 | integration-designer（集成分野担当） |
| 承認者 | 未承認（レビュー待ち） |
| 状態 | ドラフト（レビュー中） |
| 関連文書 | [業務域概要](00-overview.md) / [DB 設計](90-db-design.md) / [API 共通规格](../00-common/03-common-api-spec.md) / [税銀 IF](02-tax-bank-interface.md) / [開放 API](04-openapi-file-notify.md) |

---

## 1. 適用範囲

本設計書は INT 域が提供する**内部 API**（`/api/integration/**`）と、外部パートナー向け**開放 API**（`/api/open/v1/**`）の一覧・詳細を定義する。共通の認証（Sa-Token）、`Result<T>`、ページング、エラーコード体系は [API 共通规格](../00-common/03-common-api-spec.md) を正とし、本設計書では再定義しない。

- 内部 API の権限は `integration:{resource}:{action}`（[00 设计方针 6.6](../00-common/00-design-principles.md)）。
- 開放 API の認証は AppKey + HMAC-SHA256（[01 §2.4](01-integration-config.md)）。Sa-Token を使用しない。
- 更新系は `version` による楽観排他、登録系は `Idempotency-Key` を必須とする（[03 §9/§10](../00-common/03-common-api-spec.md)）。
- 日時は ISO 8601（+08:00）、金額・数量・ID は文字列で返す。

---

## 2. API 一覧

### 2.1 接口配置・マッピング

| # | メソッド | パス | 権限 | 概要 | 関連機能 |
|---|---|---|---|---|---|
| 1 | GET | `/api/integration/interface-configs` | `integration:interface-config:view` | 一覧検索 | F-INT-001 |
| 2 | GET | `/api/integration/interface-configs/{id}` | `integration:interface-config:view` | 詳細（secret 非返却） | F-INT-001 |
| 3 | POST | `/api/integration/interface-configs` | `integration:interface-config:create` | 登録 | F-INT-001 |
| 4 | PUT | `/api/integration/interface-configs/{id}` | `integration:interface-config:update` | 更新 | F-INT-001 |
| 5 | POST | `/api/integration/interface-configs/{id}/test` | `integration:interface-config:test` | 接続テスト | F-INT-001 |
| 6 | POST | `/api/integration/interface-configs/{id}/enable` | `integration:interface-config:update` | 有効化 | F-INT-001 |
| 7 | POST | `/api/integration/interface-configs/{id}/disable` | `integration:interface-config:update` | 停止 | F-INT-001 |
| 8 | GET | `/api/integration/interface-configs/{id}/mappings` | `integration:interface-config:view` | マッピング一覧 | F-INT-001 |
| 9 | PUT | `/api/integration/interface-configs/{id}/mappings` | `integration:interface-config:update` | マッピング一括更新 | F-INT-001 |
| 10 | POST | `/api/integration/interface-configs/{id}/credential` | `integration:credential:update` | 凭证更新 | F-INT-015 |

### 2.2 監視・ログ・対账

| # | メソッド | パス | 権限 | 概要 | 関連機能 |
|---|---|---|---|---|---|
| 11 | GET | `/api/integration/sync-dashboard` | `integration:sync-task:view` | 監視サマリ | F-INT-013 |
| 12 | GET | `/api/integration/sync-tasks` | `integration:sync-task:view` | タスク一覧 | F-INT-013 |
| 13 | GET | `/api/integration/sync-tasks/{id}` | `integration:sync-task:view` | タスク詳細・履歴 | F-INT-013 |
| 14 | POST | `/api/integration/sync-tasks/{id}/retry` | `integration:sync-task:retry` | 単件再送 | F-INT-013 |
| 15 | POST | `/api/integration/sync-tasks/batch-retry` | `integration:sync-task:retry` | 一括再送 | F-INT-013 |
| 16 | GET | `/api/integration/sync-jobs` | `integration:sync-task:view` | ジョブ一覧 | F-INT-013 |
| 17 | GET | `/api/integration/call-logs` | `integration:call-log:view` | 呼出ログ | F-INT-014 |
| 18 | GET | `/api/integration/call-logs/{id}` | `integration:call-log:view` | 原文詳細 | F-INT-014 |
| 19 | POST | `/api/integration/call-logs/exports` | `integration:call-log:export` | ログ出力（非同期） | F-INT-014 |
| 20 | GET | `/api/integration/reconciliations` | `integration:reconcile:view` | 対账結果一覧 | F-INT-014 |
| 21 | POST | `/api/integration/reconciliations/run` | `integration:reconcile:view` | 対账再実行 | F-INT-014 |

### 2.3 税務・銀行

| # | メソッド | パス | 権限 | 概要 | 関連機能 |
|---|---|---|---|---|---|
| 22 | GET | `/api/integration/tax-invoices` | `integration:tax-invoice:view` | 数电票一覧 | F-INT-002 |
| 23 | GET | `/api/integration/tax-invoices/{id}` | `integration:tax-invoice:view` | 数电票詳細 | F-INT-002 |
| 24 | POST | `/api/integration/tax-invoices` | `integration:tax-invoice:create` | 数电票开具 | F-INT-002 |
| 25 | POST | `/api/integration/tax-invoices/{id}/retry` | `integration:tax-invoice:create` | 再送 | F-INT-002 |
| 26 | POST | `/api/integration/tax-invoices/{id}/deliver` | `integration:tax-invoice:create` | 交付 | F-INT-002 |
| 27 | POST | `/api/integration/tax-invoices/{id}/red` | `integration:tax-invoice:red` | 赤伝起票 | F-INT-002 |
| 28 | GET | `/api/integration/input-invoices` | `integration:input-invoice:view` | 進項一覧 | F-INT-003 |
| 29 | POST | `/api/integration/input-invoices/verify` | `integration:input-invoice:verify` | 進項査験 | F-INT-003 |
| 30 | POST | `/api/integration/input-invoices/{id}/usage` | `integration:input-invoice:verify` | 用途確認 | F-INT-003 |
| 31 | GET | `/api/integration/bank-accounts` | `integration:bank-account:view` | 口座残高 | F-INT-004 |
| 32 | GET | `/api/integration/bank-payments` | `integration:bank-payment:view` | 付款指令一覧 | F-INT-004 |
| 33 | POST | `/api/integration/bank-payments` | `integration:bank-payment:create` | 指令作成 | F-INT-004 |
| 34 | POST | `/api/integration/bank-payments/{id}/approve` | `integration:bank-payment:approve` | 承認 | F-INT-004 |
| 35 | POST | `/api/integration/bank-payments/{id}/submit` | `integration:bank-payment:submit` | 送信 | F-INT-004 |
| 36 | POST | `/api/integration/bank-payments/{id}/query` | `integration:bank-payment:view` | 状態照会 | F-INT-004 |
| 37 | POST | `/api/integration/bank-statement-files` | `integration:bank-statement:import` | 対账单取込 | F-INT-005 |
| 38 | GET | `/api/integration/bank-statement-files/{id}` | `integration:bank-statement:view` | 取込結果 | F-INT-005 |

### 2.4 製造・ファイル・通知・開放 API

| # | メソッド | パス | 権限 | 概要 | 関連機能 |
|---|---|---|---|---|---|
| 39 | POST | `/api/integration/mes/work-orders` | `integration:mes:retry` | 工单下发 | F-INT-006 |
| 40 | POST | `/api/integration/mes/work-orders/{no}/resend` | `integration:mes:retry` | 再下发 | F-INT-006 |
| 41 | POST | `/api/integration/mes/work-reports` | `integration:mes:receive` | 報工受信 | F-INT-006 |
| 42 | POST | `/api/integration/mes/completions` | `integration:mes:receive` | 完工受信 | F-INT-006 |
| 43 | GET | `/api/integration/mes/status` | `integration:mes:view` | 連携状況 | F-INT-006 |
| 44 | POST | `/api/integration/plm/imports` | `integration:plm:import` | PLM 取込 | F-INT-008 |
| 45 | POST | `/api/integration/plm/imports/{id}/approve` | `integration:plm:approve` | 取込承認 | F-INT-008 |
| 46 | GET | `/api/integration/plm/imports` | `integration:plm:view` | 取込一覧 | F-INT-008 |
| 47 | POST | `/api/integration/pda/scans` | `integration:pda:use` | スキャン受付 | F-INT-010 |
| 48 | POST | `/api/integration/pda/offline-batches` | `integration:pda:use` | 補伝受付 | F-INT-010 |
| 49 | GET | `/api/integration/pda-devices` | `integration:pda-device:view` | 端末一覧 | F-INT-010 |
| 50 | POST | `/api/integration/pda-devices/{id}/disable` | `integration:pda-device:update` | 端末停止 | F-INT-010 |
| 51 | POST | `/api/integration/file-transfers/dry-run` | `integration:file-transfer:import` | ドライラン | F-INT-011 |
| 52 | POST | `/api/integration/file-transfers` | `integration:file-transfer:import` | 本実行 | F-INT-011 |
| 53 | GET | `/api/integration/file-transfers` | `integration:file-transfer:view` | 取込一覧 | F-INT-011 |
| 54 | GET | `/api/integration/file-transfers/{id}/errors` | `integration:file-transfer:view` | エラー行 CSV | F-INT-011 |
| 55 | GET | `/api/integration/notification-channels` | `integration:notification-channel:view` | チャネル一覧 | F-INT-012 |
| 56 | POST | `/api/integration/notification-channels/{id}/test` | `integration:notification-channel:update` | テスト送信 | F-INT-012 |
| 57 | GET | `/api/integration/notification-logs` | `integration:notification-log:view` | 送信履歴 | F-INT-012 |
| 58 | POST | `/api/integration/notification-logs/{id}/retry` | `integration:notification-channel:update` | 再送 | F-INT-012 |
| 59 | GET | `/api/integration/api-clients` | `integration:api-client:view` | クライアント一覧 | F-INT-009 |
| 60 | POST | `/api/integration/api-clients` | `integration:api-client:create` | 発行 | F-INT-009 |
| 61 | POST | `/api/integration/api-clients/{id}/revoke` | `integration:api-client:update` | 失効 | F-INT-009 |

**開放 API（外部向け）**

| # | メソッド | パス | スコープ | 概要 |
|---|---|---|---|---|
| O1 | GET | `/api/open/v1/materials` | `mdm.read` | 物料照会 |
| O2 | GET | `/api/open/v1/customers` | `mdm.read` | 顧客照会 |
| O3 | GET | `/api/open/v1/stock-balances` | `inventory.stock.read` | 在庫残高 |
| O4 | GET | `/api/open/v1/sales-orders` | `sales.order.read` | 受注一覧 |
| O5 | GET | `/api/open/v1/sales-orders/{no}` | `sales.order.read` | 受注詳細 |
| O6 | POST | `/api/open/v1/sales-orders` | `sales.order.write` | 受注登録（P2） |
| O7 | GET | `/api/open/v1/deliveries` | `delivery.read` | 出荷実績 |
| O8 | GET | `/api/open/v1/purchase-orders` | `purchase.order.read` | 発注照会 |
| O9 | GET | `/api/open/v1/reports/stock-summary` | `report.read` | 在庫サマリ（P2） |

> 開放 API は `X-Client-Id`/`X-Timestamp`/`X-Nonce`/`X-Signature` を必須とし、内部 API の権限チェックを通らない（専用フィルタ）。エラーは `Result<T>` の `code` で返し、HTTP は 401/403/429/400/500。

---

## 3. API 詳細

### 3.1 POST /api/integration/interface-configs（接口登録）

| 項目 | 内容 |
|---|---|
| 目的 | 外部 IF の接続定義を登録する |
| 権限 | `integration:interface-config:create` |
| 冪等 | `interface_code` の一意制約。重複は 422 |
| 排他 | なし（新規） |
| 関連テーブル | `int_interface_config`、`sys_audit_log` |

**リクエスト**

| 項目 | 型 | 必須 | 説明 |
|---|---|---|---|
| `interfaceCode` | string | ○ | `IF-INT-xxx` |
| `interfaceName` | string | ○ | 名称 |
| `interfaceType` | int | ○ | 10 REST/20 FILE/30 MQ/40 SMTP/50 SFTP/60 LOCAL |
| `direction` | int | ○ | 10 送信/20 受信/30 双方向 |
| `partnerCode` | string | ○ | 相手先コード |
| `endpointUrl` | string | △ | 接続先（設計書に固定しない） |
| `authType` | int | ○ | [01 §2.3](01-integration-config.md) |
| `credentialRef` | string | △ | Secrets 参照キー |
| `timeoutMs` | int | ○ | 1,000〜120,000 |
| `retryMax` | int | ○ | 0〜10 |
| `retryBackoff` | string | ○ | `1m,5m,30m` |
| `rateLimitPerMin` | int | ○ | 1〜60,000 |
| `charset` | string | ○ | UTF-8/GBK |

**レスポンス**：`201` + `InterfaceConfigDto`（secret なし）。

**エラー**：1001 入力、422 + 90002 重複、403 権限。

### 3.2 POST /api/integration/interface-configs/{id}/test（接続テスト）

| 項目 | 内容 |
|---|---|
| 目的 | 読み取り専用の疎通確認を行い、`health_status` を更新する |
| 権限 | `integration:interface-config:test` |
| 冪等 | あり（読み取りのみ） |
| タイムアウト | 設定値（既定 10 秒） |
| 関連テーブル | `int_interface_config`、`int_api_call_log` |

**レスポンス例**

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "success": true,
    "httpStatus": 200,
    "durationMs": 320,
    "testedAt": "2026-10-20T14:00:00+08:00",
    "message": "connected"
  }
}
```

**エラー**：90003 接続失敗、90004 認証情報取得失敗。失敗時も `200` で `success=false` を返す（設定保存は妨げない）。

### 3.3 POST /api/integration/tax-invoices（数电票开具）

| 項目 | 内容 |
|---|---|
| 目的 | 数电票を开具し、税局の受付結果を保存する |
| 権限 | `integration:tax-invoice:create` |
| 冪等 | `Idempotency-Key` または `sourceType + sourceId` で既存開票を検出 |
| 排他 | `int_tax_invoice` の `invoice_req_no` 一意 |
| 関連テーブル | `int_tax_invoice`、`int_tax_invoice_line`、`int_external_message` |

**リクエスト（主要項目）**

| 項目 | 型 | 必須 | 説明 |
|---|---|---|---|
| `invoiceType` | int | ○ | 10 藍専/20 藍普/30 紅専/40 紅普 |
| `buyerId` | string | △ | 顧客 ID（buyerName/taxNo の補完） |
| `buyerName` | string | ○ | 購買方名 |
| `buyerTaxNo` | string | ○ | 購買方税号（18 桁） |
| `sourceType`/`sourceId`/`sourceNo` | string | ○ | 出荷・AR 等の源泉 |
| `amount`/`taxRate`/`taxAmount`/`totalAmount` | string | ○ | 金額（[08 §4.3](../00-common/08-common-business-rules.md)） |
| `remark` | string | △ | 備考 |
| `lines[]` | array | ○ | 明細（`materialCode`、`itemName`、`quantity`、`unitPrice`、`amount`、`taxRate`、`taxAmount`） |

**レスポンス**：`201` + `TaxInvoiceDto`（`status=30/40`、`invoiceNo`、`rejectCode`）。

**エラー**：90010 税局拒否、90011 項目不備、90012 金額不整合、90013 赤伝不可。

### 3.4 POST /api/integration/tax-invoices/{id}/red（赤伝起票）

| 項目 | 内容 |
|---|---|
| 目的 | 元発票に対する赤伝を起票し、紅字確認単を取得して送信する |
| 権限 | `integration:tax-invoice:red` |
| リクエスト | `{ "reason": "...", "redConfirmNo": "...", "amount": "..." }`（部分赤伝は Phase 2） |
| 前提 | 元発票が `status=30/35`、未赤伝 |
| エラー | 90013 赤伝不可、90011 項目不備 |

### 3.5 POST /api/integration/input-invoices/verify（進項査験）

| 項目 | 内容 |
|---|---|
| 目的 | 進項発票を査験し、結果を保存する |
| 権限 | `integration:input-invoice:verify` |
| リクエスト | `{ "invoiceCode": "...", "invoiceNo": "...", "invoiceDate": "2026-10-20", "amount": "..." }` |
| レスポンス | `InputInvoiceDto`（`verifyStatus` 20/30/40） |
| エラー | 90020 査験不一致（`200` で結果返却、エラーにしない） |

### 3.6 POST /api/integration/bank-payments/{id}/submit（付款送信）

| 項目 | 内容 |
|---|---|
| 目的 | 承認済付款指令を銀行へ送信する |
| 権限 | `integration:bank-payment:submit` |
| 前提 | `status=20`、承認者 ≠ 作成者、金額 = 申請額 |
| 冪等 | `payment_no`（`uk_int_bank_payment_idem`） |
| タイムアウト | 設定値（既定 30 秒）。不明時は `status=35` |
| エラー | 90030 口座相違、90031 残高不足、90032 金額不一致、90033 状態不明 |

**レスポンス例**

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "paymentNo": "PAY2610200001",
    "status": 30,
    "statusName": "受付",
    "bankSerialNo": "ICBC20261020000123",
    "acceptedAt": "2026-10-20T14:20:00+08:00"
  }
}
```

### 3.7 POST /api/integration/bank-payments/{id}/query（状態照会）

| 項目 | 内容 |
|---|---|
| 目的 | 状態不明の付款指令を銀行へ照会し、確定させる |
| 権限 | `integration:bank-payment:view` |
| 前提 | `status=30/35` |
| 冪等 | あり（照会のみ） |
| エラー | 90033 状態不明（照会しても不明な場合） |

### 3.8 POST /api/integration/bank-statement-files（対账单取込）

| 項目 | 内容 |
|---|---|
| 目的 | 対账单ファイルを検証・取込し、FIN へ引き渡す |
| 権限 | `integration:bank-statement:import` |
| 形式 | multipart（`file`、`bankAccountId`、`fileFormat`、`charset`） |
| 前提 | 口座有効、レイアウト有効、ファイル未取込 |
| 処理 | 全件検証→全件取込→FIN 引渡 |
| エラー | 90040 形式エラー、90041 件数不一致、90042 重複、90043 FIN 引渡失敗 |

**レスポンス例**

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "fileNo": "BST-INT-20261020-0001",
    "totalCount": 128,
    "successCount": 128,
    "failCount": 0,
    "status": 50,
    "statusName": "FIN 引渡済",
    "finStatementId": "1845678901234567920"
  }
}
```

### 3.9 POST /api/integration/mes/work-reports（報工受信）

| 項目 | 内容 |
|---|---|
| 目的 | MES の報工実績を受信し、PRD へ反映する |
| 認証 | 内部 API（`integration:mes:receive`、システムトークン） |
| 冪等 | `reportNo` |
| 処理 | 検証→`prd_work_report` 登録→E23 発行→ACK |
| エラー | 90050 重複（ACK のみ）、90061 工单不存在、90052 数量不整合 |

**レスポンス**：`200` + `{ "reportNo": "...", "accepted": true, "acceptedAt": "..." }`。

### 3.10 POST /api/integration/file-transfers（ファイル本実行）

| 項目 | 内容 |
|---|---|
| 目的 | 検証済みファイルを本実行し、業務域へ引き渡す |
| 権限 | `integration:file-transfer:import` |
| 前提 | ドライラン合格（同一 `fileHash`、24 時間以内） |
| 冪等 | `fileHash` |
| エラー | 90040/90041/90042、90043 引渡失敗 |

### 3.11 POST /api/integration/sync-tasks/{id}/retry（手動再送）

| 項目 | 内容 |
|---|---|
| 目的 | 失敗・死信タスクを手動で再送する |
| 権限 | `integration:sync-task:retry` |
| 前提 | `status=40/50/60`、冪等キーあり、死信は 2 名承認 |
| リクエスト | `{ "reason": "...", "version": 2 }` |
| エラー | 90070 再送不可、90072 状態不整合、403 権限 |

### 3.12 POST /api/integration/api-clients（開放 API クライアント発行）

| 項目 | 内容 |
|---|---|
| 目的 | 取引先の API クライアントを発行する（secret は一度だけ返す） |
| 権限 | `integration:api-client:create`（情報部長承認） |
| リクエスト | `{ "clientName": "...", "scopes": ["mdm.read"], "allowedIp": "...", "rateLimitPerMin": 600, "effectiveFrom": "...", "effectiveTo": "..." }` |
| レスポンス | `201` + `{ "clientId": "...", "secret": "...", "clientName": "..." }` |
| 注意 | `secret` は初回のみ。再表示不可。監査ログに secret を残さない |
| エラー | 90080 スコープ不正、90081 IP 形式不正 |

### 3.13 開放 API の共通エラー

| HTTP | `code` | 意味 | 対処 |
|---|---|---|---|
| 400 | 1001 | 入力エラー | `fieldErrors` を確認 |
| 401 | 2001 | 認証失敗（署名・時刻・nonce） | 署名再生成・時刻同期 |
| 403 | 3001 | スコープ不足 | スコープ追加申請 |
| 404 | 4001 | リソース不存在 | 番号確認 |
| 409 | 4003/4005 | 楽観排他・処理中 | 再取得・再試行 |
| 429 | 5002 | レート超過 | `Retry-After` に従う |
| 500 | 5000 | システムエラー | `trace_id` を添えて連絡 |

---

## 4. エラーコード（INT 領域 90000〜90999）

| コード | メッセージ ID | 意味 |
|---|---|---|
| 90001 | `MSG-INT-060` | 外部 IF 失敗（通信・相手先） |
| 90002 | `MSG-INT-002` | 接口設定の重複・不存在 |
| 90003 | `MSG-INT-003` | 接続テスト失敗 |
| 90004 | `MSG-INT-008` | 認証情報取得失敗 |
| 90010 | `MSG-INT-020` | 数电票拒否 |
| 90011 | `MSG-INT-021` | 開票項目不備 |
| 90012 | `MSG-INT-022` | 金額不整合 |
| 90013 | `MSG-INT-026` | 赤伝不可 |
| 90020 | `MSG-INT-030` | 進項査験不一致 |
| 90030 | `MSG-INT-040` | 口座相違 |
| 90031 | `MSG-INT-041` | 残高不足 |
| 90032 | `MSG-INT-045` | 付款金額不一致 |
| 90033 | `MSG-INT-046` | 付款状態不明 |
| 90040 | `MSG-INT-050` | 対账单形式エラー |
| 90041 | `MSG-INT-051` | 件数不一致 |
| 90042 | `MSG-INT-052` | ファイル重複 |
| 90043 | `MSG-INT-053` | FIN 引渡失敗 |
| 90050 | `MSG-INT-062` | 重複報文 |
| 90052 | `MSG-INT-063` | 報工数量不整合 |
| 90061 | `MSG-INT-061` | 工单不存在・状態不正 |
| 90070 | `MSG-INT-072` | 再送不可 |
| 90072 | `MSG-INT-073` | 一括件数超過 |
| 90080 | `MSG-INT-080` | スコープ不正 |
| 90081 | `MSG-INT-081` | IP 形式不正 |
| 90082 | `MSG-INT-082` | 署名失敗 |
| 90083 | `MSG-INT-083` | nonce 再利用 |
| 90090 | `MSG-INT-090` | 通知チャネル無効 |
| 90091 | `MSG-INT-091` | 通知宛先不正 |

---

## 5. 実装上の注意

1. **外部呼出はトランザクション外**：`@Transactional` 内で HTTP 呼出を行わない。状態更新のみトランザクション化する。
2. **タイムアウトの明示**：HTTP クライアントは connect/read を分けて設定する（`connect_timeout_ms`、`timeout_ms`）。
3. **リトライの二重実装禁止**：アプリ層のリトライと HTTP クライアントの自動リトライを併用しない（設定で無効化）。
4. **マスキング**：ログ・原文・`Result` に secret・口座番号・個人情報を出さない。`@JsonIgnore` と DTO 変換で担保する。
5. **日時**：外部との日時は ISO 8601（+08:00）。銀行・税局が `yyyyMMddHHmmss` を要求する場合はマッピングで変換する。
6. **冪等キーの保存**：`int_sync_task` の一意索引で保証。アプリ層の事前チェックのみに依存しない。
7. **監査**：更新系 API は `sys_audit_log` に前後値を記録する（金額・状態は必須）。

---

## 6. 未決事項

| # | 事項 | 理由 | 暫定仕様 | 担当 | 期限 |
|---|---|---|---|---|---|
| 1 | 開放 API の受注登録（O6）の Phase 1 提供可否 | 取引先契約 | Phase 1 は参照のみ | SAL／情報部 | 2026-12-15 |
| 2 | 開放 API のページング上限（200） | 取引先の要望 | 200 固定。バルクは Phase 2 | integration | 2026-12-31 |
| 3 | 内部 API のレート制限要否 | 内部は Sa-Token で制御 | Phase 1 は無制限（監視のみ） | 情報部 | 2026-12-31 |
| 4 | 数电票 API の項目追加（購買方住所等） | 税局仕様の確認 | 拡張項目（`ext_data`）で対応 | 財務 | 2026-11-30 |
| 5 | 対账单取込の非同期化 | 大量ファイル時 | Phase 1 は同期（50,000 行まで） | integration | 2027-01-31 |

## 7. 改訂履歴

| 版数 | 日付 | 変更内容 | 変更者 |
|---|---|---|---|
| v1.0 | 2026-10-20 | 初版：内部 API 61 件・開放 API 9 件の一覧、主要 13 API の詳細、INT エラーコード 29 件 | integration-designer |
| v1.1 | 2026-10-20 | 红队 REV-SW-003 対応：429 レート超過のコードを `5002` に修正 | system-workflow |
| v1.2 | 2026-10-21 | 重複・既存系の業務エラーの HTTP を 409 → 422 に統一（409 は楽観排他競合 4003 のみ。03 §5・01-system 91 v1.10 と整合）。対象：:136、:160（蓝色大肥鱼 2026-10-21 決定） | 业务分析 |
