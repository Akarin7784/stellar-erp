# 接口配置管理 详细设计书（インタフェース設定管理 詳細設計書）

| 項目 | 内容 |
|---|---|
| 文書名 | 接口配置管理 详细设计书（インタフェース設定管理 詳細設計書） |
| 文書番号 | DSN-INT-001 |
| 版数 | v1.0 |
| 作成日 | 2026-10-20 |
| 作成者 | integration-designer（集成分野担当） |
| 承認者 | 未承認（レビュー待ち） |
| 状態 | ドラフト（レビュー中） |
| 関連文書 | [業務域概要](00-overview.md) / [税銀 IF](02-tax-bank-interface.md) / [DB 設計](90-db-design.md) / [API 共通规格](../00-common/03-common-api-spec.md) / [共通项目定义](../00-common/01-common-item-definitions.md) |

---

## 1. 機能概要

| 項目 | 内容 |
|---|---|
| 機能 ID | F-INT-001（接口配置管理）、F-INT-015（接口凭证与安全） |
| 機能名 | 接口配置管理／接口凭证与安全 |
| 目的 | 外部 IF の接続情報（エンドポイント・認証・タイムアウト・リトライ・レート制限・項目マッピング）を**コード変更なしで**管理し、安全な認証情報の保管・更新・失効を行う |
| 利用者・ロール | 接口管理员（情報部）、运维担当、情報部長（承認） |
| 利用シーン | 新規外部システム接続、接続先変更、認証期限更新、障害時の一時停止、接続テスト |
| 優先度 | P0 |
| 画面 ID | SCR-INT-001、SCR-INT-002、SCR-INT-003 |
| 関連 IF | 全 IF-INT-001〜016 の接続定義 |

### 1.1 設計方針

1. **設定と実装の分離**：エンドポイント・認証・リトライ・レート制限は `int_interface_config` に保持し、アダプタ実装は IF 種別ごとに固定する。設定変更でアダプタを再デプロイしない。
2. **認証情報の非保存**：secret・証明書・秘密鍵は Secrets Manager / 環境変数に置き、DB には `credential_ref`（参照キー）のみ保存する。画面・API は値を返さない。
3. **接続テストは読み取りのみ**：テスト接続で業務データを作成・更新しない（残高照会・ヘルスチェック・認証トークン取得まで）。
4. **変更の統制**：本番有効化・認証情報更新・無効化は承認フロー（[00-overview §2.1](00-overview.md)）を経る。全変更を監査ログに記録する。
5. **安全側の既定値**：タイムアウト 10 秒、リトライ 3 回、指数バックオフ 1 分/5 分/30 分、レート制限 600 回/分。無効状態で登録し、テスト合格後に有効化する。
6. **層別リトライ**：再送回数は層ごとに異なる。混同しないよう下表を正とする。

| 層 | 対象 | 最大再送回数 | 間隔 | 根拠・関連 |
|---|---|---|---|---|
| IF 直呼出（同期） | `int_interface_config.retry_max`（既定 3、上限 10） | 3 回（非冪等 0〜2） | 指数バックオフ 1 分/5 分/30 分 | §2.1 BR-CFG-03/04、[02](02-tax-bank-interface.md) 照会先行 |
| 同期タスク自動再送 | `int_sync_task`（BAT-INT-010 等） | 10 回 | バックオフ（5 分〜） | [05](05-sync-monitor.md) BR-MON-02 |
| 通知送信再送 | メール/短信/Webhook（BAT-INT-010） | 5 回 | 1 分〜（指数） | 00-overview §7 BAT-INT-010 |
| Outbox 配信 | SYS `sys_outbox_event`（BAT-SYS-001） | 10 回 | 1 分/5 分/30 分/2 時間/6 時間 | [09 §10.1](../00-common/09-cross-domain-flow.md) |

> 429 レート超過の共通コードは `code=5002`（`5001` は保守停止専用）。[03 §14](../00-common/03-common-api-spec.md) に従う。

---

## 2. 業務要件・業務ルール

### 2.1 前提条件

| # | 前提条件 | 成立しない場合 |
|---|---|---|
| 1 | 相手先との接続契約・IP 許可・証明書が準備済み | 接続テスト不可（`MSG-INT-003`） |
| 2 | 相手先のインタフェース仕様書（項目・コード・エラー）が入手済み | マッピング未定義として登録不可 |
| 3 | 本番環境の Secrets Manager が利用可能 | 認証情報を登録できない（平文保存禁止） |
| 4 | 承認者が設定されている（情報部長） | 有効化不可 |

### 2.2 業務ルール

| # | ルール | 根拠 | 関連項目 |
|---|---|---|---|
| BR-CFG-01 | `interface_code` は `IF-INT-xxx` 形式で一意。既存コードの再利用・変更は禁止（廃止は `enabled_flag=false`） | [00 设计方针 6.4](../00-common/00-design-principles.md) | `interface_code` |
| BR-CFG-02 | 認証情報の実値を DB・ログ・API レスポンスに含めない。`credential_ref` のみ保持する | セキュリティ規程 | `credential_ref` |
| BR-CFG-03 | タイムアウトは 1,000〜120,000 ms、リトライは 0〜10 回。上限超過は登録不可 | 本設計 | `timeout_ms`、`retry_max` |
| BR-CFG-04 | リトライ対象は**冪等な操作**に限る。開票・付款などの非冪等操作は「照会先行」とし、設定で `retry_max` を 0〜2 に制限する | [02](02-tax-bank-interface.md) BR-TAX-05、BR-BANK-01 | `retry_max` |
| BR-CFG-05 | レート制限を超えた呼出は待機または 429 を返す。外部への 429 はそのまま返さず、内部キューで再試行する | [03 API 共通规格 §14](../00-common/03-common-api-spec.md) | `rate_limit_per_min` |
| BR-CFG-06 | 有効化には接続テスト合格と承認を要する。テスト結果は 24 時間有効 | 本設計 | `health_status` |
| BR-CFG-07 | 認証情報のローテーションは「新規登録→テスト→切替→旧失効」の順で行い、切替中の二重登録を許容する（`secret_ref` と `secret_ref_old`） | 本設計 | `credential_ref` |
| BR-CFG-08 | 証明書・secret の有効期限 30 日前・7 日前・期限切れで通知する（BAT-INT-009） | 本設計 | `expires_at`（`ext_data`） |
| BR-CFG-09 | 項目マッピングは許可関数のみ（四則演算・日付変換・コード変換・部分文字列）。スクリプト実行は禁止 | セキュリティ | `transform_expr` |
| BR-CFG-10 | 設定変更は版数を増やし、変更前後を監査ログに保存する。進行中のタスクは旧設定で完了させる（途中で設定を混在させない） | 本設計 | `version` |

### 2.3 認証方式の定義

| コード | 方式 | 用途 | 主な設定項目 | 備考 |
|---|---|---|---|---|
| 0 | なし | 社内システム（MES/WMS/PLM）でネットワーク分離済み | — | 本番は非推奨 |
| 10 | API Key | 开放 API（Phase 1）、簡易な外部連携 | `client_id`、`credential_ref`（secret） | ヘッダ `X-Api-Key` |
| 20 | HMAC-SHA256 | 开放 API（推奨）、署名必須の外部連携 | `client_id`、`credential_ref`、署名対象 | 後述 §2.4 |
| 30 | OAuth2 Client Credentials | 税局/サービス事業者、クラウド型外部 | `client_id`、`credential_ref`、token URL | Phase 2 |
| 40 | mTLS | 銀企直連、税局 | クライアント証明書（`credential_ref`） | 証明書期限監視 |
| 50 | Basic | レガシー社内システム | `client_id`（ユーザ）、`credential_ref` | TLS 必須 |
| 60 | SFTP 鍵 | 対账单・EDI ファイル | SSH 鍵（`credential_ref`）、known_hosts | ホスト鍵検証必須 |

### 2.4 HMAC 署名仕様（IF-INT-009 开放 API）

| 項目 | 仕様 |
|---|---|
| 署名対象 | `{method}\n{path}\n{query}\n{timestamp}\n{nonce}\n{body_sha256}` |
| ヘッダ | `X-Client-Id`、`X-Timestamp`（Unix 秒）、`X-Nonce`（UUID）、`X-Signature`（Base64(HMAC-SHA256)） |
| 時刻許容 | ±5 分（サーバ時刻 Asia/Shanghai）。超過は 401 |
| Nonce | 10 分間の再利用禁止（Redis）。再利用は 401 |
| Body | `body_sha256` は空ボディ時も `e3b0c442...`（SHA-256 空文字）を用いる |
| 失敗時 | 401 `code=2001`、監査ログに記録（secret は記録しない） |

> HMAC の詳細実装は [04-openapi-file-notify.md](04-openapi-file-notify.md) 第 3 章を正とする。

### 2.5 リトライ・サーキットブレーカ

| 項目 | 既定 | 説明 |
|---|---|---|
| 最大再送回数 | 3 回 | 0〜10。非冪等操作は 0〜2 |
| バックオフ | 1 分、5 分、30 分 | 指数バックオフ。設定文字列で変更可 |
| リトライ判定 | 通信エラー・タイムアウト・5xx・429 のみ | 4xx（400/401/403/404/422）は再送しない |
| サーキットブレーカ | 連続 5 回失敗で 5 分間 OPEN | OPEN 中は送信せず `status=40`（再送待ち） |
| ヘルスチェック | 5 分間隔（読取のみ） | 3 回連続失敗で `health_status=30` |

---

## 3. 関連機能

| 関係 | 機能 ID | 機能名 | 関係内容 |
|---|---|---|---|
| 下流 | F-INT-002〜012、016〜020 | 各外部 IF | 本設定を参照して送受信 |
| 下流 | F-INT-013 | 同期監視 | `health_status`・失敗回数の参照 |
| 参照 | F-INT-015 | 凭证管理 | 認証情報の更新・失効 |
| 参照 | F-SYS-009 | 审计日志 | 設定変更の記録 |
| 参照 | F-SYS-019 | 通知模板 | 期限警告の文面 |

---

## 4. 画面設計

### 4.1 画面一覧

| 画面 ID | 画面名 | 類型 | 概要 |
|---|---|---|---|
| SCR-INT-001 | 接口配置一覧 | 一覧検索 | IF コード・相手先・種別・有効状態・最終成功で検索 |
| SCR-INT-002 | 接口配置登録編集 | 登録編集 | 接続・認証・リトライ・マッピングの編集、接続テスト |
| SCR-INT-003 | 接続テスト/実行結果 | 参照詳細 | テスト結果、レスポンスタイム、エラー詳細 |

### 4.2 画面項目定義（SCR-INT-002）

| No | 項目 ID | 項目名 | 種別 | 型/桁 | 必須 | 初期値 | 入力チェック | データソース | DB 項目 | 備考 |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | interface_code | IF コード | テキスト | VARCHAR(32) | ○ | 空 | `IF-INT-\d{3}`、一意 | 入力 | `interface_code` | 登録後変更不可 |
| 2 | interface_name | IF 名称 | テキスト | VARCHAR(200) | ○ | 空 | 桁数 | 入力 | `interface_name` | — |
| 3 | interface_type | 種別 | 選択 | SMALLINT | ○ | 10 | 値域 | 固定値 | `interface_type` | 10 REST/20 FILE/30 MQ/40 SMTP/50 SFTP/60 LOCAL |
| 4 | direction | 方向 | 選択 | SMALLINT | ○ | 20 | 値域 | 固定値 | `direction` | 10 送信/20 受信/30 双方向 |
| 5 | partner_code | 相手先コード | テキスト | VARCHAR(32) | ○ | 空 | 大文字英数・_ | 入力 | `partner_code` | 例 `BANK_ICBC` |
| 6 | partner_name | 相手先名 | テキスト | VARCHAR(200) | ○ | 空 | 桁数 | 入力 | `partner_name` | — |
| 7 | endpoint_url | 接続先 | テキスト | VARCHAR(500) | △ | 空 | URL 形式（https 推奨） | 入力 | `endpoint_url` | FILE/SFTP はディレクトリ |
| 8 | http_method | HTTP メソッド | 選択 | VARCHAR(10) | △ | POST | GET/POST/PUT | 入力 | `http_method` | REST のみ |
| 9 | auth_type | 認証方式 | 選択 | SMALLINT | ○ | 20 | 値域 | 固定値 | `auth_type` | §2.3 |
| 10 | credential_ref | 凭证参照 | テキスト | VARCHAR(200) | △ | 空 | 参照キー形式 | Secrets Manager | `credential_ref` | 実値は入力しない |
| 11 | timeout_ms | タイムアウト | 数値 | INT | ○ | 10000 | 1,000〜120,000 | 入力 | `timeout_ms` | ms |
| 12 | retry_max | 最大再送回数 | 数値 | SMALLINT | ○ | 3 | 0〜10 | 入力 | `retry_max` | 非冪等は 0〜2 |
| 13 | retry_backoff | バックオフ | テキスト | VARCHAR(100) | ○ | 1m,5m,30m | 形式 `\d+[mh](,\d+[mh])*` | 入力 | `retry_backoff` | — |
| 14 | rate_limit_per_min | レート制限 | 数値 | INT | ○ | 600 | 1〜60,000 | 入力 | `rate_limit_per_min` | 回/分 |
| 15 | charset | 文字コード | 選択 | VARCHAR(20) | ○ | UTF-8 | UTF-8/GBK | 入力 | `charset` | 国内銀行は GBK あり |
| 16 | enabled_flag | 有効 | チェック | BOOLEAN | ○ | false | — | 入力 | `enabled_flag` | 承認後に有効化 |
| 17 | effective_from | 有効開始日 | 日付 | DATE | ○ | 当日 | 開始 ≤ 終了 | 入力 | `effective_from` | — |
| 18 | effective_to | 有効終了日 | 日付 | DATE | △ | 空 | 開始 ≤ 終了 | 入力 | `effective_to` | — |

### 4.3 イベント処理

| No | イベント | トリガ | 処理内容 | 呼出 API | 画面遷移 |
|---|---|---|---|---|---|
| 1 | 検索 | 検索ボタン | 条件検証→一覧取得 | `GET /api/integration/interface-configs` | 同一画面 |
| 2 | 新規/編集 | ボタン | 設定編集 | — | SCR-INT-002 |
| 3 | 保存 | 保存ボタン | 入力チェック→楽観排他→保存→監査 | `POST/PUT /api/integration/interface-configs` | SCR-INT-001 |
| 4 | 接続テスト | テストボタン | 読み取りのみ実行→結果表示 | `POST /api/integration/interface-configs/{id}/test` | SCR-INT-003 |
| 5 | 有効化 | 有効化ボタン | テスト結果・承認確認→有効化 | `POST /api/integration/interface-configs/{id}/enable` | SCR-INT-001 |
| 6 | 停止 | 停止ボタン | 理由必須→無効化→実行中タスクは完了させる | `POST /api/integration/interface-configs/{id}/disable` | SCR-INT-001 |
| 7 | マッピング編集 | タブ切替 | 項目追加・削除・並替 | `PUT /api/integration/interface-configs/{id}/mappings` | 同一画面 |
| 8 | 凭证更新 | 更新ボタン | 新 secret 登録→テスト→切替 | `POST /api/integration/interface-configs/{id}/credential` | 同一画面 |

### 4.4 一覧画面仕様

| 項目 | 内容 |
|---|---|
| 検索条件 | IF コード（部分一致）、名称（部分一致）、相手先、種別、有効状態、ヘルス状態 |
| 既定検索 | 有効のみ |
| ソート | 更新日時降順 |
| ページング | 20 件/ページ |
| 一括操作 | 有効化/停止（承認済のみ） |
| エクスポート | 設定一覧（secret は含めない）、最大 1,000 件 |

### 4.5 表示制御

| 条件 | 対象 | 制御 |
|---|---|---|
| 権限 `integration:interface-config:update` なし | 保存・有効化・停止 | 非表示（API 403） |
| `enabled_flag=true` | IF コード・種別 | 編集不可（参照のみ） |
| 認証方式 = 0 | 凭证参照 | 非表示 |
| 全画面 | secret・証明書 | 表示しない（マスクもせず非表示） |

---

## 5. 入力チェック仕様

| No | チェック ID | 対象 | 種別 | 条件 | タイミング | メッセージ |
|---|---|---|---|---|---|---|
| 1 | CHK-INT-001-01 | IF コード | 形式 | `IF-INT-` + 3 桁 | 保存時 | `MSG-INT-001` |
| 2 | CHK-INT-001-02 | IF コード | 一意 | 既存と重複しない | 保存時 | `MSG-INT-002` |
| 3 | CHK-INT-001-03 | 接続先 | 形式 | `http(s)://` またはディレクトリ | 保存時 | `MSG-INT-003` |
| 4 | CHK-INT-001-04 | タイムアウト | 範囲 | 1,000〜120,000 | 保存時 | `MSG-INT-004` |
| 5 | CHK-INT-001-05 | リトライ | 範囲 | 0〜10（非冪等は 0〜2） | 保存時 | `MSG-INT-004` |
| 6 | CHK-INT-001-06 | バックオフ | 形式 | `\d+[mh](,\d+[mh])*` | 保存時 | `MSG-INT-004` |
| 7 | CHK-INT-001-07 | 有効化 | 業務 | 接続テスト合格（24 時間以内） | 有効化時 | `MSG-INT-006` |
| 8 | CHK-INT-001-08 | 有効化 | 権限 | 承認済（情報部長） | 有効化時 | `MSG-COM-030` |
| 9 | CHK-INT-001-09 | マッピング | 必須 | 送信 IF は最低 1 件のマッピング | 保存時 | `MSG-INT-007` |
| 10 | CHK-INT-001-10 | 有効期間 | 相関 | 開始 ≤ 終了 | 保存時 | `MSG-COM-046` |

---

## 6. 処理詳細

### 6.1 処理一覧

| 処理 ID | 処理名 | 契機 | トランザクション | 排他 |
|---|---|---|---|---|
| PRC-INT-001-01 | 接口登録 | 保存 | 要 | 業務キー一意 |
| PRC-INT-001-02 | 接口更新 | 保存 | 要 | 楽観排他（`version`） |
| PRC-INT-001-03 | 接続テスト | テスト | 不要（外部呼出） | — |
| PRC-INT-001-04 | 有効化/停止 | ボタン | 要 | 楽観排他 |
| PRC-INT-001-05 | 認証情報更新 | 更新 | 要（参照のみ） | 排他不要（Secrets Manager） |
| PRC-INT-001-06 | 設定キャッシュ更新 | 保存後 | 不要 | — |

### 6.2 処理手順（正常系）

**PRC-INT-001-03 接続テスト**

1. 権限・IF 有効性を確認する（無効でもテスト可、ただし本番送信は不可）。
2. 認証トークン/署名を生成する（secret は Secrets Manager から取得し、メモリのみ保持）。
3. **読み取り専用**のテスト API（ヘルスチェック・残高照会・token 取得）を呼び出す。
4. 応答時間・HTTP ステータス・エラーコードを `int_api_call_log` に記録する（`request_summary` はマスキング）。
5. 成功なら `health_status=10`、失敗なら `health_status=30`・`last_error` を更新する。
6. テスト結果を 24 時間保持し、有効化の前提条件とする。

**PRC-INT-001-04 有効化**

1. 承認状態・テスト結果（24 時間以内）・マッピング定義を確認する。
2. `enabled_flag=true`、`effective_from` を設定し、`version` を +1 する。
3. 設定キャッシュを無効化し、監視対象に登録する。
4. 監査ログ（変更前後・実行者）を記録する。

**PRC-INT-001-05 認証情報更新（ローテーション）**

1. 新 secret を Secrets Manager に登録し、`secret_ref_new` を取得する（DB には参照のみ）。
2. 新 secret で接続テストを実行する。
3. 成功後、`credential_ref` を新キーへ切替え、旧キーは 24 時間後に失効する（並行運用）。
4. 切替結果を監査ログに記録する。失敗時は旧キーを継続し、`MSG-INT-008` を返す。

### 6.3 例外処理

| No | 異常条件 | 検知箇所 | 処理 | ロールバック | メッセージ |
|---|---|---|---|---|---|
| 1 | IF コード重複 | 保存 | エラー | 全体 | `MSG-INT-002` |
| 2 | 接続テスト失敗 | テスト | 保存は可、有効化不可 | なし | `MSG-INT-003` |
| 3 | 承認なしの有効化 | 有効化 | 拒否 | なし | `MSG-COM-030` |
| 4 | 楽観排他競合 | 更新 | 409 | 全体 | `MSG-COM-033` |
| 5 | Secrets Manager 参照失敗 | テスト/送信 | 送信中止、アラート | なし | `MSG-INT-008` |
| 6 | マッピング不備 | 送信 | 送信中止 | タスクのみ失敗 | `MSG-INT-007` |
| 7 | レート制限超過 | 送信 | 内部キューで待機 | なし | `MSG-INT-010` |

### 6.4 冪等性・再実行

- 登録は `interface_code` の一意制約で二重登録を防ぐ。
- 更新は `version` による楽観排他。再送された更新は 409 を返す。
- 接続テストは冪等（読み取りのみ）。
- 有効化/停止は同一状態への操作を `MSG-COM-034` で拒否する。

---

## 7. API 設計

| No | メソッド | パス | 権限 | 概要 |
|---|---|---|---|---|
| 1 | GET | `/api/integration/interface-configs` | `integration:interface-config:view` | 一覧 |
| 2 | GET | `/api/integration/interface-configs/{id}` | `integration:interface-config:view` | 詳細（secret 非返却） |
| 3 | POST | `/api/integration/interface-configs` | `integration:interface-config:create` | 登録 |
| 4 | PUT | `/api/integration/interface-configs/{id}` | `integration:interface-config:update` | 更新（`version` 必須） |
| 5 | POST | `/api/integration/interface-configs/{id}/test` | `integration:interface-config:test` | 接続テスト |
| 6 | POST | `/api/integration/interface-configs/{id}/enable` | `integration:interface-config:update` | 有効化 |
| 7 | POST | `/api/integration/interface-configs/{id}/disable` | `integration:interface-config:update` | 停止 |
| 8 | GET | `/api/integration/interface-configs/{id}/mappings` | `integration:interface-config:view` | マッピング一覧 |
| 9 | PUT | `/api/integration/interface-configs/{id}/mappings` | `integration:interface-config:update` | マッピング一括更新 |
| 10 | POST | `/api/integration/interface-configs/{id}/credential` | `integration:credential:update` | 凭证更新 |

### 7.1 レスポンス例

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "id": "1845678901234567801",
    "interfaceCode": "IF-INT-002",
    "interfaceName": "数电票开具与交付",
    "interfaceType": 10,
    "direction": 30,
    "partnerCode": "TAX",
    "partnerName": "电子发票服务平台",
    "authType": 40,
    "credentialRef": "secret/tax/if-int-002",
    "timeoutMs": 30000,
    "retryMax": 2,
    "retryBackoff": "1m,5m",
    "enabledFlag": true,
    "healthStatus": 10,
    "lastSuccessAt": "2026-10-20T15:10:00+08:00",
    "version": 3
  }
}
```

> `credentialRef` は参照キーのみ。secret の実値は返さない。

### 7.2 エラー例

```json
{
  "code": 1001,
  "message": "输入内容有误",
  "data": {
    "fieldErrors": [
      { "field": "timeoutMs", "message": "超时时间必须在 1000〜120000 毫秒之间" },
      { "field": "retryMax", "message": "非幂等接口的最大重试次数不能超过 2" }
    ]
  }
}
```

---

## 8. データ更新仕様

| テーブル | 操作 | 更新項目 | 条件 | トリガ |
|---|---|---|---|---|
| `int_interface_config` | INSERT | 全項目 | 新規 | PRC-INT-001-01 |
| `int_interface_config` | UPDATE | 設定・`version`・`health_status` | 更新/テスト | PRC-INT-001-02/03/04 |
| `int_interface_mapping` | INSERT/UPDATE/DELETE | マッピング | 一括更新 | PRC-INT-001-02 |
| `int_api_call_log` | INSERT | 呼出結果 | テスト・送受信 | 全 IF |
| `sys_audit_log` | INSERT | 変更前後 | 登録・更新・有効化 | — |

---

## 9. エラー処理・メッセージ

| メッセージ ID | 種別 | 本文 | 発生条件 | 対処 |
|---|---|---|---|---|
| `MSG-INT-001` | E | 接口代码格式不正确（应为 IF-INT-三位数字）。 | 形式違反 | 修正 |
| `MSG-INT-002` | E | 接口代码已存在，请勿重复登记。 | 一意違反 | 既存を編集 |
| `MSG-INT-003` | E | 连接测试失败：{0}。请检查地址、证书与网络。 | テスト失敗 | 設定・NW 確認 |
| `MSG-INT-004` | E | 超时、重试或退避参数超出允许范围。 | 値域違反 | 修正 |
| `MSG-INT-005` | E | 该接口当前状态不允许此操作。 | 状態不整合 | 状態確認 |
| `MSG-INT-006` | E | 连接测试未通过或已超过 24 小时，不能启用。 | 有効化条件不足 | 再テスト |
| `MSG-INT-007` | E | 字段映射未定义或不完整。 | マッピング不備 | 定義追加 |
| `MSG-INT-008` | E | 认证信息读取失败，请联系系统管理员。 | Secrets 参照失敗 | 情報部へ連絡 |
| `MSG-INT-009` | W | 认证信息将在 {0} 天后到期，请及时更新。 | 期限警告 | ローテーション |
| `MSG-INT-010` | W | 调用频率超过限制，已进入等待队列。 | レート超過 | 待機 |

---

## 10. 権限・セキュリティ

| 種別 | 内容 |
|---|---|
| 画面権限 | `integration:interface-config:view`（一覧・詳細）、`:create/update`（登録・編集）、`:test`（テスト） |
| 操作権限 | 有効化・停止・凭证更新は情報部長の承認を要する |
| 項目権限 | `credential_ref` は参照のみ、実値は全ロール非表示 |
| データ範囲 | 全社（情報部のみ） |
| 監査ログ | 登録・更新・有効化・停止・テスト・凭证更新を記録（secret は記録しない） |
| 通信 | HTTPS 必須（TLS 1.2+）。mTLS は証明書検証を省略しない |
| 保存 | secret は DB に保存しない。ログ・原文にも出力しない |

---

## 11. 性能・非機能

| 項目 | 目標 | 前提 |
|---|---|---|
| 一覧表示 | 2 秒以内 | 100 件程度 |
| 設定保存 | 3 秒以内 | — |
| 接続テスト | 30 秒以内（タイムアウト含む） | 相手先 SLA 依存 |
| 設定キャッシュ | 変更後 60 秒以内に全ノード反映 | Redis Pub/Sub |
| 同時編集 | 10 ユーザ | 楽観排他 |

---

## 12. テスト観点

| No | 観点 ID | 分類 | 観点 | 期待結果 |
|---|---|---|---|---|
| 1 | TST-F-INT-001-01 | 正常系 | 接口を登録 | 保存され、無効状態で登録 |
| 2 | TST-F-INT-001-02 | 異常系 | IF コード重複 | `MSG-INT-002` |
| 3 | TST-F-INT-001-03 | 異常系 | タイムアウト範囲外 | `MSG-INT-004` |
| 4 | TST-F-INT-001-04 | 正常系 | 接続テスト成功→有効化 | 有効化され監視対象に登録 |
| 5 | TST-F-INT-001-05 | 異常系 | テスト未実施で有効化 | `MSG-INT-006` |
| 6 | TST-F-INT-001-06 | 排他 | 同時更新 | 後勝ちせず 409 |
| 7 | TST-F-INT-001-07 | 権限 | 権限なしで保存 | 403 |
| 8 | TST-F-INT-001-08 | セキュリティ | レスポンス・ログに secret が出ない | 出力されない |
| 9 | TST-F-INT-001-09 | 冪等 | 同一状態への有効化 | `MSG-COM-034` |
| 10 | TST-F-INT-001-10 | 異常系 | マッピング未定義で送信 | `MSG-INT-007` |
| 11 | TST-F-INT-015-01 | 正常系 | 凭证ローテーション | 新 secret で疎通、旧は失効 |
| 12 | TST-F-INT-015-02 | 異常系 | 新 secret でテスト失敗 | 旧 secret 継続、`MSG-INT-008` |

---

## 13. 未決事項

| # | 事項 | 理由 | 暫定仕様 | 担当 | 期限 |
|---|---|---|---|---|---|
| 1 | Secrets Manager の製品選定 | 顧客のクラウド/オンプレ構成が未確定 | 環境変数 + Vault 互換を想定。`credential_ref` の解決は抽象化 | 情報部 | 2026-11-30 |
| 2 | 設定の多環境（開発/検証/本番）管理 | 現設計は 1 環境 1 レコード | `company_id` + `ext_data.env` で分離可能とする | 情報部 | 2026-12-15 |
| 3 | サーキットブレーカの実装方式 | Resilience4j 等の選定 | アプリ層で実装（Phase 1）。設定値は `int_interface_config` | 情報部 | 2026-12-15 |
| 4 | 項目マッピングの UI 編集範囲 | 複雑な変換は UI で表現困難 | Phase 1 は単純変換のみ UI、複雑変換はアダプタ実装 | integration | 2027-01-31 |

## 14. 改訂履歴

| 版数 | 日付 | 変更内容 | 変更者 |
|---|---|---|---|
| v1.0 | 2026-10-20 | 初版：接口設定、認証 7 方式、HMAC 仕様、リトライ/サーキットブレーカ、凭证管理、画面 3、API 10、テスト観点 | integration-designer |
| v1.1 | 2026-10-20 | 红队 REV-SW-012/003 対応：層別リトライ表（IF 直呼出 3 回／同期タスク 10 回／通知 5 回／Outbox 10 回）を追加し、429 のコードを `5002` に統一 | system-workflow |
