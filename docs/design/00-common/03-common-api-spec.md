# API 共通规格（API 共通仕様）

| 項目 | 内容 |
|---|---|
| 文書名 | API 共通规格（API 共通仕様） |
| 文書番号 | DSN-CMN-003 |
| 版数 | v1.0 |
| 作成日 | 2026-10-20 |
| 作成者 | Lead（设计基盤） |
| 承認者 | 未承認（社内レビュー待ち） |
| 状態 | ドラフト（レビュー中） |
| 関連文書 | [共通项目定义](01-common-item-definitions.md) / [DB 共通规格](04-common-db-spec.md) / [跨域流程](09-cross-domain-flow.md) / [API 設計書テンプレート](../_template/04-report-batch-interface-template.md) |

---

## 1. 基本方針

| # | 方針 |
|---|---|
| 1 | REST + JSON。リソース指向。動詞をパスに含めない（業務操作は例外的に `:action` 的なサブリソースで表現） |
| 2 | 全 API は認証必須（ログイン・ヘルスチェック・公開 API を除く）。権限はサーバ側で必ず検証 |
| 3 | レスポンスは常に `Result<T>` でラップ。HTTP ステータスは成功/失敗の大分類、業務コードは `code` |
| 4 | 画面向け API と外部連携向け API を分離する（外部は `/api/open/v1/**`、認証方式・レート制限が異なる） |
| 5 | 破壊的変更は行わない。項目追加は後方互換。削除・意味変更は API バージョンで対応 |
| 6 | 数量・金額・ID は**文字列**で返す（JS 精度問題の回避）。日付は `yyyy-MM-dd`、日時は ISO 8601 |
| 7 | 一覧はサーバサイドページング必須。全件返却 API は作らない（帳票・エクスポートは非同期ジョブ） |
| 8 | 更新系は楽観排他（`version`）を既定とし、非対応の場合は設計書に明記 |

## 2. パス・HTTP メソッド

### 2.1 基本形式

```
/api/{module}/{resource}[/{id}][/{sub-resource}][:action]
```

- `{module}`：`system` / `mdm` / `sales` / `purchase` / `inventory` / `production` / `finance` / `workflow` / `integration` / `report`
- `{resource}`：複数形・kebab-case（例 `sales-orders`、`stock-txns`、`payment-requests`）
- 内部 API は `/api`、外部公開 API は `/api/open/v1`（第 14 章）
- フロントエンドの `baseURL` は `/api`（既存実装 `frontend/src/api/http.ts`）。Nginx/Vite がバックエンドへプロキシする

### 2.2 メソッド対応

| 操作 | メソッド | パス | 成功時 HTTP | 例 |
|---|---|---|---|---|
| 一覧検索 | GET | `/api/{module}/{resource}` | 200 | GET /api/sales/sales-orders?status=30 |
| 詳細取得 | GET | `/api/{module}/{resource}/{id}` | 200 | GET /api/sales/sales-orders/{id} |
| 新規登録 | POST | `/api/{module}/{resource}` | 201 | POST /api/sales/sales-orders |
| 更新 | PUT | `/api/{module}/{resource}/{id}` | 200 | PUT /api/sales/sales-orders/{id} |
| 削除（マスタ） | DELETE | `/api/{module}/{resource}/{id}` | 200 | DELETE /api/mdm/materials/{id} |
| 状態操作（提出/承認/却下/撤回/取消/完了） | POST | `/api/{module}/{resource}/{id}/{action}` | 200 | POST /api/sales/sales-orders/{id}/submit |
| 一括操作 | POST | `/api/{module}/{resource}/batch-{action}` | 200 | POST /api/sales/sales-orders/batch-approve |
| 帳票出力 | POST | `/api/{module}/{resource}/{id}/print` | 200（PDF バイナリ）または 202（非同期） | — |
| エクスポート | POST | `/api/{module}/exports` | 202（ジョブ） | — |

- RFC 的には POST で状態操作、PUT で全項目置換。PATCH は部分更新が必要な場合のみ使用。
- URL に日本語・空白を含めない。検索条件はクエリパラメータ。

## 3. 認証・セッション

| 項目 | 内容 |
|---|---|
| 方式 | Sa-Token。ログイン成功時にトークンを発行 |
| 送信 | HTTP ヘッダ `Authorization: {token}`（接頭辞なし。既存実装 `erp_token` と一致） |
| トークン有効期限 | 8 時間（`sa-token.timeout`）。操作で自動更新（activity-timeout 併用） |
| ログイン API | `POST /api/system/auth/login`（`username`、`password`、`captcha`、`captchaKey`） |
| ログアウト | `POST /api/system/auth/logout` |
| ユーザ情報 | `GET /api/system/auth/me`（ユーザ・ロール・権限コード一覧・データ範囲・メニュー） |
| 失効 | `401` + `code=2001`「ログインの有効期限が切れました」。フロントはログイン画面へ遷移 |
| パスワード | BCrypt ハッシュ。初回ログイン時変更必須・有効期限・履歴 5 世代（SYS 設計書） |
| 多要素認証 | Phase 2（TOTP/短信）。API は項目追加で対応可能な形にしておく |

## 4. 認可（権限）

- サーバ側で `@SaCheckPermission("{module}:{resource}:{action}")` を付与する。
- データ権限（行レベル）はユーザのロールデータ範囲に基づき SQL に強制注入する。
- 権限なし：`403` + `code=3001`「操作権限がありません」。
- 未認証：`401` + `code=2001`。認証済みだがデータ範囲外：`403` + `code=3002`「参照権限がありません」。
- 画面の表示制御は UX 目的であり、API 側のチェックを省略してはならない。

## 5. 共通レスポンス（`Result<T>`）

### 5.1 形式

```json
{
  "code": 0,
  "message": "ok",
  "data": { }
}
```

| フィールド | 型 | 説明 |
|---|---|---|
| `code` | int | 0 = 成功。非 0 = 業務エラーコード（第 6 章） |
| `message` | string | ユーザ表示用メッセージ（中国語）。技術詳細を含めない |
| `data` | object/array/null | 成功時データ。エラー時は `null` または `fieldErrors` |
| `msgId` | string/null | メッセージ ID（`MSG-{COM\|DOM}-{3桁}`、例 `MSG-PRD-040`）。業務エラーで対応 ID がある場合のみ設定、成功時・未定義時は `null`。フロントは `msgId` があれば表示し、なければ `code` を表示する |

### 5.2 成功例（詳細取得）

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "id": "1845678901234567890",
    "salesOrderNo": "SO2610200001",
    "customerId": "1845000000000000001",
    "customerName": "常州泵业有限公司",
    "orderDate": "2026-10-20",
    "status": 30,
    "statusName": "発行済",
    "currencyCode": "CNY",
    "totalAmount": "1234567.89",
    "version": 2,
    "lines": [
      {
        "lineNo": 10,
        "materialId": "1845000000000000101",
        "materialCode": "3001000001",
        "materialName": "YE3-100L1-4 三相异步电动机 2.2kW",
        "quantity": "120.0000",
        "uomCode": "PCE",
        "unitPrice": "856.500000",
        "amount": "102780.00",
        "taxRate": "13.0000",
        "taxAmount": "13361.40"
      }
    ]
  }
}
```

### 5.3 エラー例（バリデーション）

```json
{
  "code": 1001,
  "message": "入力内容に誤りがあります",
  "data": {
    "fieldErrors": [
      { "field": "orderDate", "message": "受注日は必須です" },
      { "field": "lines[0].quantity", "message": "数量は 0 より大きい値を入力してください" }
    ]
  }
}
```

> **実装メモ**：現行の `GlobalExceptionHandler` は `fieldErrors` を返さない。Phase 1 実装時に `Result` の拡張（`data` に `fieldErrors` を格納）または専用 DTO を追加する。設計は本仕様を正とする。

## 6. 業務エラーコード体系

### 6.1 コード範囲

| 範囲 | 用途 | 代表コード |
|---|---|---|
| `0` | 成功 | — |
| `1000-1999` | 共通バリデーション・入力 | 1001 入力エラー、1002 必須漏れ、1003 値域外、1004 コード不存在、1005 一意制約違反 |
| `2000-2999` | 認証・セッション | 2001 未認証/期限切れ、2002 ログイン失敗、2003 アカウントロック、2004 パスワード期限切れ |
| `3000-3999` | 権限 | 3001 操作権限なし、3002 データ参照権限なし、3003 項目参照権限なし |
| `4000-4999` | 共通業務・状態 | 4001 対象データ不存在、4002 状態不整合、4003 楽観排他競合、4004 期間締切済、4005 二重処理 |
| `10000-19999` | SYS 領域 | 10001 ユーザ重複、… |
| `20000-29999` | MDM 領域 | 20001 物料コード重複、… |
| `30000-39999` | SAL 領域 | 30001 与信超過、… |
| `40000-49999` | PUR 領域 | 40001 発注数量超過、… |
| `50000-59999` | INV 領域 | 50001 在庫不足、… |
| `60000-69999` | PRD 領域 | 60001 BOM 循環参照、… |
| `70000-79999` | FIN 領域 | 70001 貸借不一致、… |
| `80000-89999` | WF 領域 | 80001 承認者未設定、… |
| `90000-94999` | INT 領域 | 90001 外部 IF 失敗、… |
| `95000-99999` | RPT 領域 | 95001 集計対象なし、… |

### 6.2 HTTP ステータスとの対応

| HTTP | 用途 | `code` 例 |
|---|---|---|
| 200 | 成功（GET/PUT/DELETE/状態操作） | 0 |
| 201 | 新規登録成功 | 0 |
| 202 | 非同期ジョブ受付 | 0 |
| 400 | 入力・バリデーションエラー | 1001〜1005 |
| 401 | 未認証・期限切れ | 2001 |
| 403 | 権限なし | 3001〜3003 |
| 404 | リソース不存在 | 4001 |
| 409 | 状態競合・楽観排他 | 4002、4003 |
| 422 | 業務ルール違反（入力形式は正しい） | 領域コード（例 50001 在庫不足） |
| 500 | システムエラー | 5000（`code=5000`、詳細はログのみ） |
| 503 | メンテナンス・依存サービス停止 | 5001（保守・依存停止のみ） |
| 429 | レート制限超過（外部 API） | 5002 |

- フロントは `code != 0` でエラー処理。`401` は共通ハンドラでログイン画面へ、`403` は権限エラー表示。
- メッセージ ID との対応：各 API 設計書に「`code` ↔ `MSG-xxx`」の対応表を置く。メッセージ本文は [05 共通消息](05-common-message-list.md) と各域 `93-messages.md` を正とする。

## 7. ページング・ソート・検索

### 7.1 リクエスト

| パラメータ | 型 | 既定 | 制約 | 説明 |
|---|---|---|---|---|
| `pageNum` | int | 1 | 1〜 | 1 始まり |
| `pageSize` | int | 20 | 1〜200 | 上限 200 |
| `sort` | string | 機能既定 | `field,asc` / `field,desc`、カンマ区切りで複数 | ソートキー |
| その他 | — | — | — | 検索条件（`keyword`、`status`、`dateFrom`、`dateTo` 等） |

- 検索条件の命名は各域 API 設計書で定義。共通的なもの：`keyword`（コード・名称の部分一致）、`status`（複数は `status=10,20`）、`dateFrom`/`dateTo`（両端含む）。
- 部分一致検索は `pg_trgm` を利用（名称・コード）。前方一致が既定の項目は明記する。

### 7.2 レスポンス（`PageResult<T>`）

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "list": [ ],
    "total": 1234,
    "pageNum": 1,
    "pageSize": 20,
    "pages": 62
  }
}
```

- `total` は条件一致総件数。取得コストが高い場合は `total` を近似（`totalApprox: true`）としてよい（機能で定義）。

## 8. JSON データ型の表現規則

| データ種別 | JSON 表現 | 例 | 備考 |
|---|---|---|---|
| ID（BIGINT） | 文字列 | `"1845678901234567890"` | 2^53 超のため |
| 金額・数量・単価・率 | 文字列（10 進表記） | `"1234.56"` | 桁数は 01 共通项目定义 第 6 章 |
| 日付 | 文字列 `yyyy-MM-dd` | `"2026-10-20"` | タイムゾーンなし |
| 日時 | 文字列 ISO 8601 | `"2026-10-20T14:30:00+08:00"` | サーバは Asia/Shanghai |
| 真偽値 | boolean | `true` | — |
| 列挙・状態 | 数値（コード） | `30` | 名称は `statusName` で併記可 |
| コード | 文字列（大文字） | `"CNY"`、`"PCE"` | — |
| 配列 | JSON array | `[]` | null と空配列を区別（未設定=null、0 件=[]） |
| ファイル | multipart | — | 第 12 章 |
| 拡張項目 | object | `{"customer_grade":"A"}` | `extData` フィールド |

- リクエストの金額・数量も文字列を許可する（数値も受け付けるが、サーバで `BigDecimal` 変換し精度検証する）。
- `null` は「未設定」、`0` は「値 0」として扱い、混同しない。

## 9. 冪等性

| 対象 | 仕様 |
|---|---|
| 対象 API | 登録系 POST、状態操作（submit/approve/reject/cancel）、ジョブ起動 |
| ヘッダ | `Idempotency-Key: {UUID}`（クライアント生成） |
| 動作 | 同一キーのリクエストが 24 時間以内に再送された場合、初回の処理結果をそのまま返す（再処理しない） |
| 保存 | `sys_idempotency`（key、user_id、path、request_hash、response_code、response_body、expires_at） |
| 競合 | 同一キーで処理中の場合は `409` + `code=4005`「処理中です。しばらくしてから再実行してください」 |
| キーなし | 冪等保証なし。フロントは必ず送信する。外部 API は必須 |

## 10. 楽観排他

- 更新系リクエストに `version`（int）を含める。サーバは `WHERE id=? AND version=?` で更新し、0 件なら `409` + `code=4003`「他のユーザが更新しました。最新情報を再取得してください」。
- 一括更新は全件成功 or 全件失敗（デフォルト）。部分成功を許す場合は設計書に明記し、失敗行一覧を返す。
- 状態操作（承認・取消）も `version` を要求する（画面で保持した version を送信）。

## 11. 伝票操作 API の共通パターン

### 11.1 状態操作

```http
POST /api/sales/sales-orders/{id}/submit
Content-Type: application/json

{ "version": 2, "comment": "10月度分" }
```

| アクション | 意味 | 必要権限 | 事前条件（例） |
|---|---|---|---|
| `submit` | 承認フローへ提出 | `{module}:{resource}:submit` | status=10 草稿 |
| `approve` | 承認 | `{module}:{resource}:approve` | status=20 承認待ち、承認者本人 |
| `reject` | 却下 | `{module}:{resource}:approve` | status=20、却下理由必須 |
| `withdraw` | 撤回 | `{module}:{resource}:submit` | status=20、未処理タスクのみ |
| `cancel` | 取消 | `{module}:{resource}:cancel` | 後続処理なし（在庫・会計の逆処理を伴う場合は専用 API） |
| `close` | 完了/クローズ | `{module}:{resource}:close` | status=30/35 で残数量 0 |

- レスポンスは更新後のリソースを返す（`data` に詳細）。
- 状態操作のエラーは `409`/`422` + メッセージ（例：「承認待ちの伝票ではありません」）。

### 11.2 一括操作

```http
POST /api/sales/sales-orders/batch-approve
{ "ids": ["..."], "comments": "一括承認" }
```

- レスポンス：`{ "successCount": 2, "failureCount": 1, "failures": [{"id":"...","reason":"..."}] }`
- 上限 1,000 件。超過は非同期ジョブ。

## 12. 非同期ジョブ・ファイル API

### 12.1 非同期ジョブ

| 操作 | API | 説明 |
|---|---|---|
| 起動 | `POST /api/{module}/exports` or `/jobs` | 202 + `{jobId}`。対象条件・帳票 ID を指定 |
| 状態 | `GET /api/{module}/jobs/{jobId}` | `{status: QUEUED/RUNNING/SUCCEEDED/FAILED, progress, resultFileId, errorMessage}` |
| 結果取得 | `GET /api/{module}/jobs/{jobId}/files/{fileId}` | ダウンロード（権限チェック、署名付き URL 可） |
| キャンセル | `DELETE /api/{module}/jobs/{jobId}` | QUEUED/RUNNING のみ |

- ジョブ実行結果は 7 日保存。画面にはジョブ一覧（自ユーザ分）を提供。
- 大量エクスポート・MRP・月結・一括登録は非同期ジョブで実行する（各域設計書で定義）。

### 12.2 ファイル

| 操作 | 仕様 |
|---|---|
| アップロード | `POST /api/system/attachments`（multipart、`bizType`、`bizId` 任意）。20MB、形式検証、ウイルス検査 |
| ダウンロード | `GET /api/system/attachments/{id}`。権限 + 業務参照チェック。`Content-Disposition` でファイル名 |
| 一覧/削除 | 業務詳細 API に添付情報を含める。削除はアップロード者または管理者 |
| テンプレート DL | `GET /api/{module}/import-templates/{templateId}` で Excel テンプレート配布 |

## 13. 監査・ログ・トレーシング

| 項目 | 仕様 |
|---|---|
| リクエスト ID | クライアント送信可（`X-Request-Id`）。なければサーバで UUID 生成し、レスポンスヘッダにも返す |
| 監査ログ | 更新・状態操作・出力・認証をサーバ側で記録（01 共通项目定义 第 12 章） |
| アプリログ | SLF4J。リクエスト ID・ユーザ ID・処理時間を MDC で出力。個人情報・パスワードは出力しない |
| エラーログ | 500 系はスタックトレースをサーバログのみに記録。クライアントには `trace_id` を返す |
| マスキング | 銀行口座・電話・メールはログでもマスク（01 共通项目定义 第 15 章） |
| 監視 | Actuator `/actuator/health`、メトリクス（Phase 2 Prometheus） |

## 14. 外部公開 API（`/api/open/v1`）

| 項目 | 仕様 |
|---|---|
| 認証 | OAuth2 Client Credentials（Phase 2）または API Key + HMAC 署名（Phase 1 は API Key） |
| 利用登録 | `sys_api_client`（client_id、secret（ハッシュ）、scope、許可 IP、レート制限） |
| レート制限 | 既定 600 req/分/client（バースト 100）。超過 429 + `code=5002`（5001 は保守停止専用、混用禁止） |
| スコープ | `mdm.read`、`sales.order.write` 等、リソース単位 |
| 監査 | 全リクエストを `int_api_call_log` に記録（リクエスト/レスポンス概要、処理時間） |
| 互換性 | バージョンはパスに含む（`/api/open/v1`）。次版は `/api/open/v2` を併設し、旧版は 12 か月維持 |
| ドキュメント | OpenAPI 3 定義を自動生成・配布（`/v3/api-docs/open`） |

## 15. OpenAPI 記述規約

- `tags`：モジュール単位（例 `Sales - Order`）。
- `operationId`：`{module}{Resource}{Action}`（例 `salesSalesOrderCreate`）。
- Schema 名：`{Domain}{Entity}{Purpose}Request/Response`（例 `SalesOrderCreateRequest`）。
- 全 API に `summary`、`description`、`@Parameter` 説明、成功/エラー例を付与する。
- セキュリティスキーム：`bearerAuth`（Sa-Token）。外部 API は `apiKeyAuth`。
- Swagger UI は開発・テスト環境のみ有効（本番は `springdoc.api-docs.enabled=false`）。

## 16. セキュリティ要求

| 項目 | 仕様 |
|---|---|
| 通信 | 本番は HTTPS 必須（TLS 1.2+）。HTTP は 301 リダイレクト |
| 入力検証 | Bean Validation + 業務チェック。SQL は MyBatis のパラメータバインドのみ（文字列結合禁止） |
| XSS | 出力エスケープ。HTML を返す API は作らない |
| CORS | 同一オリジン（Nginx 配下）を既定。許可オリジンは環境変数で管理 |
| CSRF | Cookie を使わないため不要（Authorization ヘッダ方式） |
| 機密 | パスワード・API secret はハッシュ/暗号化。レスポンスに返さない |
| 権限昇格 | ロール・データ範囲の変更は監査ログ + 管理者権限 |
| 依存 | 脆弱性スキャン（OWASP Dependency-Check）を CI に組み込む（Phase 2） |

## 17. API 一覧の記述形式（各域 `91-api-design.md` で使用）

| # | メソッド | パス | 権限 | 概要 | リクエスト | レスポンス | 主なエラーコード | 関連機能 |
|---|---|---|---|---|---|---|---|---|
| 1 | GET | /api/sales/sales-orders | sales:order:view | 受注一覧 | {検索条件} | PageResult<SalesOrderListDto> | 3001 | F-SAL-003 |

各 API の詳細節には以下を書く：目的 / パス・メソッド / 権限 / リクエスト項目（型・必須・説明）/ レスポンス項目 / 正常例 / エラー例 / 処理概要 / 冪等・排他 / 関連テーブル。

## 18. 現行実装との差分・実装タスク

| # | 事項 | 現状 | 設計（本仕様） | 対応時期 |
|---|---|---|---|---|
| 1 | バリデーションエラーの `fieldErrors` | `GlobalExceptionHandler` は message のみ | `data.fieldErrors[]` を返す | Phase 1 実装時 |
| 2 | API パス接頭辞 `/api` | フロント `baseURL=/api`、バックエンド未実装 | `/api/{module}/...` | Phase 1 |
| 3 | レスポンスの日時形式 | 未定 | ISO 8601（+08:00） | Phase 1 |
| 4 | Idempotency-Key | 未実装 | 登録・状態操作に必須 | Phase 1 |
| 5 | 外部公開 API | 未実装 | `/api/open/v1`（API Key → OAuth2） | Phase 2 |

## 19. 改訂履歴

| 版数 | 日付 | 変更内容 | 変更者 |
|---|---|---|---|
| v1.0 | 2026-10-20 | 初版：パス/認証/権限/Result/エラーコード/ページング/型/冪等/排他/状態操作/非同期/ファイル/監査/外部 API/OpenAPI/セキュリティ | Lead |
