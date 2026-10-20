# 开放 API・文件・通知 详细设计书（開放 API・ファイル・通知 詳細設計書）

| 項目 | 内容 |
|---|---|
| 文書名 | 开放 API・文件・通知 详细设计书（開放 API・ファイル・通知 詳細設計書） |
| 文書番号 | DSN-INT-004 |
| 版数 | v1.0 |
| 作成日 | 2026-10-20 |
| 作成者 | integration-designer（集成分野担当） |
| 承認者 | 未承認（レビュー待ち） |
| 状態 | ドラフト（レビュー中） |
| 関連文書 | [業務域概要](00-overview.md) / [接口配置](01-integration-config.md) / [製造連携](03-mes-wms-plm.md) / [DB 設計](90-db-design.md) / [API 共通规格](../00-common/03-common-api-spec.md) / [画面共通规格](../00-common/02-common-screen-spec.md) |

---

## 1. 機能概要

| 項目 | 内容 |
|---|---|
| 機能 ID | F-INT-009（开放 API）、F-INT-011（外部文件取込）、F-INT-012（消息渠道）、F-INT-018（EDI 注文・P2）、F-INT-019（供应商门户・P2） |
| 機能名 | 开放 API・文件・通知 |
| 目的 | ① 取引先・3PL・代理店に REST API を開放し、受注・在庫照会・出荷実績を安全に提供する；② 銀行・税局・EDI・PLM 等の固定形式ファイルを検証して取り込む；③ メール・短信・企业微信・钉钉へ通知を確実に送信する |
| 利用者・ロール | 接口管理员、运维担当、情報部長、取引先システム、SYS 通知基盤 |
| 利用シーン | 取引先の受注連携、日次対账单の受信、EDI 注文の取込、承認依頼メール、障害アラート |
| 優先度 | F-INT-009＝P1、F-INT-011＝P0、F-INT-012＝P0（SMTP）/P2（他）、F-INT-018/019＝P2 |
| 画面 ID | SCR-INT-018〜022 |
| 関連 IF | IF-INT-009、011、014、015、006 |

### 1.1 設計方針

1. **開放 API は内部 API と分離**：パス `/api/open/v1`、認証・レート制限・監査を独立させる（[03 §14](../00-common/03-common-api-spec.md)）。内部 API の権限体系（Sa-Token）を流用しない。
2. **署名必須**：Phase 1 から AppKey + HMAC-SHA256。OAuth2 Client Credentials は Phase 2（`auth_type=30`）。
3. **ファイルは「検証→ドライラン→本実行」**：1 行でもエラーがあれば本実行しない。エラー行はダウンロード可能。
4. **通知は業務を止めない**：送信失敗で業務トランザクションをロールバックしない。再送キューで処理する（[08 §13.3](../00-common/08-common-business-rules.md)）。
5. **個人情報の最小化**：通知本文・ログ・原文に電話・メール・口座を残さない（マスキング）。

---

## 2. 業務要件・業務ルール

### 2.1 前提条件

| # | 前提条件 | 成立しない場合 |
|---|---|---|
| 1 | API クライアントが発行済（`status=10`、有効期間内） | 401 |
| 2 | 要求 IP が許可リスト内 | 403 |
| 3 | 署名が正しく、時刻が ±5 分以内、nonce 未使用 | 401 |
| 4 | ファイルレイアウトが有効（`int_file_layout.status=10`） | 取込不可（`MSG-INT-050`） |
| 5 | 通知チャネルが有効 | 送信失敗（`MSG-INT-090`） |

### 2.2 業務ルール（開放 API）

| # | ルール | 根拠 | 関連項目 |
|---|---|---|---|
| BR-API-01 | 認証は `X-Client-Id` + `X-Signature`（HMAC-SHA256）。署名対象は [01 §2.4](01-integration-config.md) の通り | 本設計 | — |
| BR-API-02 | スコープは `mdm.read`、`sales.order.read`、`sales.order.write`、`inventory.stock.read`、`delivery.read`、`purchase.order.read`、`report.read` の 7 種。最小権限を付与する | 本設計 | `scope_json` |
| BR-API-03 | レート制限は既定 600 req/分・バースト 100。超過は 429 + `code=5002`（`5001` は保守停止専用） | [03 §14](../00-common/03-common-api-spec.md) | `rate_limit_per_min` |
| BR-API-04 | 更新系は `Idempotency-Key` 必須。24 時間以内の同一キーは初回結果を返す | [03 §9](../00-common/03-common-api-spec.md) | — |
| BR-API-05 | バージョンはパス（`/api/open/v1`）。破壊的変更は `/v2` を併設し、旧版を 12 か月維持 | [03 §14](../00-common/03-common-api-spec.md) | — |
| BR-API-06 | 全リクエストを `int_api_call_log` に記録（本文は概要のみ、機密はマスキング） | 本設計 | `int_api_call_log` |
| BR-API-07 | 停止・失効したクライアントは即時 401。鍵のローテーションは 24 時間の並行利用を許容 | 本設計 | `secret_ref` |
| BR-API-08 | 外部 API から**業務データを直接更新しない**。受注・出荷は各業務域の公開 API を呼び出す | [09 §2.2](../00-common/09-cross-domain-flow.md) | — |

### 2.3 開放 API スコープとエンドポイント

| スコープ | メソッド | パス | 概要 | 更新系 |
|---|---|---|---|---|
| `mdm.read` | GET | `/api/open/v1/materials` | 物料照会（コード・名称・単位） | × |
| `mdm.read` | GET | `/api/open/v1/customers` | 顧客照会（自社関連のみ） | × |
| `inventory.stock.read` | GET | `/api/open/v1/stock-balances` | 在庫残高照会（倉庫・物料） | × |
| `sales.order.read` | GET | `/api/open/v1/sales-orders` | 受注照会（期間・状態） | × |
| `sales.order.read` | GET | `/api/open/v1/sales-orders/{no}` | 受注詳細 | × |
| `sales.order.write` | POST | `/api/open/v1/sales-orders` | 受注登録（取引先 EDI） | ○ |
| `delivery.read` | GET | `/api/open/v1/deliveries` | 出荷実績照会 | × |
| `purchase.order.read` | GET | `/api/open/v1/purchase-orders` | 発注照会（サプライヤ向け） | × |
| `report.read` | GET | `/api/open/v1/reports/stock-summary` | 在庫サマリ（Phase 2） | × |

**共通仕様**：レスポンスは `Result<T>`。ページングは `pageNum/pageSize`（最大 200）。日付 `yyyy-MM-dd`、金額・数量は文字列。エラーコードは [03 §6](../00-common/03-common-api-spec.md) に従う。

### 2.4 業務ルール（ファイル取込）

| # | ルール | 根拠 | 関連項目 |
|---|---|---|---|
| BR-FILE-01 | 対応形式：CSV（UTF-8/GBK）、Excel（.xlsx）、XML、固定長。ZIP は非対応（Phase 1） | 本設計 | `file_format` |
| BR-FILE-02 | 1 ファイルの上限は 50,000 行または 20MB（`sys_param.int_file_max_rows`）。超過は分割を依頼 | 本設計 | — |
| BR-FILE-03 | 文字コードは原則 UTF-8。国内銀行の GBK はレイアウト定義で指定 | 本設計 | `charset` |
| BR-FILE-04 | ヘッダ行・フッタ行の件数と明細行数が一致しない場合は取込拒否 | 本設計 | `MSG-INT-051` |
| BR-FILE-05 | 同一ファイル（SHA-256）の再取込は拒否。訂正は取消＋新規 | 本設計 | `file_hash` |
| BR-FILE-06 | 取込は全件成功 or 全件失敗。部分成功が必要な場合はジョブを分割する | [08 §13.2](../00-common/08-common-business-rules.md) | — |
| BR-FILE-07 | ドライラン結果（エラー行）は 7 日間ダウンロード可能 | 本設計 | `int_file_transfer_error` |
| BR-FILE-08 | 取込後は必ず業務域の公開 API へ引き渡す。INT は業務テーブルを直接更新しない | 本設計 | — |
| BR-FILE-09 | ファイルは受信後 90 日で削除する（原本が必要な場合は別途アーカイブ） | 本設計 | — |

### 2.5 業務ルール（通知）

| # | ルール | 根拠 | 関連項目 |
|---|---|---|---|
| BR-NOTI-01 | チャネルは EMAIL（SMTP/TLS）、SMS（REST）、WECOM（Webhook）、DINGTALK（Webhook） | [08 §13.3](../00-common/08-common-business-rules.md) | `int_notification_channel` |
| BR-NOTI-02 | 送信は SYS 通知基盤から依頼を受ける（INT は配信のみ）。テンプレートは SYS が管理 | 本設計 | — |
| BR-NOTI-03 | 再送は最大 5 回（1 分、5 分、30 分、2 時間、6 時間）。失敗は `int_api_call_log` に記録 | 本設計 | — |
| BR-NOTI-04 | 同一通知（`notificationId`）の二重送信を禁止する（送信ログで判定） | 本設計 | — |
| BR-NOTI-05 | 宛先はユーザの通知設定に従う。配信停止の希望を尊重する（業務必須通知を除く） | 本設計 | — |
| BR-NOTI-06 | 本文に口座番号・パスワード・個人情報を含めない。URL は短縮しない | 本設計 | — |
| BR-NOTI-07 | 送信元メールは SPF/DKIM を設定し、迷惑メール判定を避ける | 運用要件 | — |

### 2.6 通知テンプレート変数（例）

| 変数 | 説明 | 例 |
|---|---|---|
| `${businessNo}` | 伝票番号 | `SO2610200001` |
| `${businessType}` | 業務種別 | `销售订单` |
| `${applicant}` | 申請者 | `张*` |
| `${amount}` | 金額（通貨付き） | `CNY 116,141.40` |
| `${dueDate}` | 期限 | `2026-10-25` |
| `${url}` | 画面 URL（社内のみ） | `https://erp.example.com/...`（【示例値】） |

> `${url}` のドメインは導入時に設定する。設計書に実在ドメインを固定しない。

---

## 3. 関連機能

| 関係 | 機能 ID | 機能名 | 関係内容 |
|---|---|---|---|
| 参照 | F-INT-001 | 接口配置 | 接続・認証・レート制限 |
| 参照 | F-INT-013/014 | 監視・対账 | 呼出ログ・失敗監視 |
| 上流 | F-SYS-019 | 通知模板 | 文面・変数の受渡し |
| 下流 | F-SYS-011 | 消息通知与待办 | 送信結果の反映 |
| 下流 | F-SAL-003 | 销售订单 | EDI 受注の登録 |
| 下流 | F-PUR-007 | 采购订单 | 供应商ポータル送信（P2） |

---

## 4. 画面設計

### 4.1 画面一覧

| 画面 ID | 画面名 | 類型 | 概要 |
|---|---|---|---|
| SCR-INT-018 | 開放 API クライアント管理 | 一覧検索 | クライアント発行・scope・IP・失効 |
| SCR-INT-019 | API 利用状況・レート制限 | ダッシュボード | 呼出数・失敗率・429 件数・上位クライアント |
| SCR-INT-020 | 外部ファイル取込ジョブ | 一覧検索 | レイアウト選択・ドライラン・本実行・エラー DL |
| SCR-INT-021 | 通知チャネル設定 | 登録編集 | SMTP/SMS/WeCom/DingTalk の設定・テスト送信 |
| SCR-INT-022 | 通知送信履歴 | 一覧検索 | 送信結果・再送・失敗理由 |

### 4.2 画面項目定義（SCR-INT-018）

| No | 項目 ID | 項目名 | 種別 | 型/桁 | 必須 | 初期値 | 入力チェック | データソース | DB 項目 |
|---|---|---|---|---|---|---|---|---|---|
| 1 | client_id | クライアント ID | テキスト | VARCHAR(64) | ○ | 自動 | 一意・英数 | 採番 | `client_id` |
| 2 | client_name | クライアント名 | テキスト | VARCHAR(200) | ○ | 空 | 桁数 | 入力 | `client_name` |
| 3 | scopes | スコープ | 複数選択 | JSONB | ○ | 空 | §2.3 の値のみ | 固定値 | `scope_json` |
| 4 | allowed_ip | 許可 IP | テキスト | VARCHAR(500) | △ | 空 | CIDR 形式 | 入力 | `allowed_ip` |
| 5 | rate_limit_per_min | レート制限 | 数値 | INT | ○ | 600 | 1〜60,000 | 入力 | `rate_limit_per_min` |
| 6 | effective_from | 有効開始日 | 日付 | DATE | ○ | 当日 | 開始 ≤ 終了 | 入力 | `effective_from` |
| 7 | effective_to | 有効終了日 | 日付 | DATE | △ | 空 | 同上 | 入力 | `effective_to` |
| 8 | contact_email | 連絡先 | テキスト | VARCHAR(200) | ○ | 空 | メール形式 | 入力 | `contact_email` |
| 9 | status | 状態 | 表示 | SMALLINT | — | 10 | — | 自動 | `status` |
| 10 | secret | シークレット | 表示 | — | — | 発行時のみ表示 | — | 自動 | `secret_hash` |

### 4.3 画面項目定義（SCR-INT-020 ファイル取込）

| No | 項目 ID | 項目名 | 種別 | 型/桁 | 必須 | 初期値 | 入力チェック | データソース | DB 項目 |
|---|---|---|---|---|---|---|---|---|---|
| 1 | layout_id | レイアウト | 選択 | BIGINT | ○ | 空 | 有効のみ | `int_file_layout` | `layout_id` |
| 2 | file | ファイル | アップロード | — | ○ | 空 | 形式・サイズ・行数 | 入力 | — |
| 3 | biz_date | 業務日 | 日付 | DATE | ○ | 当日 | — | 入力 | `biz_date` |
| 4 | dry_run | ドライラン | チェック | BOOLEAN | ○ | true | — | 入力 | — |
| 5 | charset | 文字コード | 選択 | VARCHAR(20) | ○ | UTF-8 | UTF-8/GBK | レイアウト | — |
| 6 | total_rows | 総行数 | 数値 | INT | — | — | — | 自動 | `total_rows` |
| 7 | success_rows | 成功行数 | 数値 | INT | — | — | — | 自動 | `success_rows` |
| 8 | fail_rows | 失敗行数 | 数値 | INT | — | — | — | 自動 | `fail_rows` |
| 9 | status | 状態 | 表示 | SMALLINT | — | 10 | — | 自動 | `status` |

### 4.4 画面項目定義（SCR-INT-021 通知チャネル）

| No | 項目 ID | 項目名 | 種別 | 型/桁 | 必須 | 初期値 | 入力チェック | データソース | DB 項目 |
|---|---|---|---|---|---|---|---|---|---|
| 1 | channel_code | チャネル | 選択 | VARCHAR(32) | ○ | SMTP | 一意 | 固定値 | `channel_code` |
| 2 | channel_type | 種別 | 選択 | SMALLINT | ○ | 10 | 10〜40 | 固定値 | `channel_type` |
| 3 | provider | 提供者 | テキスト | VARCHAR(100) | △ | 空 | 桁数 | 入力 | `provider` |
| 4 | host / port | ホスト・ポート | テキスト/数値 | VARCHAR(200)/INT | △ | 空 | ホスト形式 | 入力 | `config_json` |
| 5 | from_address | 送信元 | テキスト | VARCHAR(200) | △ | 空 | メール形式 | 入力 | `config_json` |
| 6 | webhook_url | Webhook URL | テキスト | VARCHAR(500) | △ | 空 | https | 入力 | `config_json` |
| 7 | credential_ref | 凭证参照 | テキスト | VARCHAR(200) | △ | 空 | — | Secrets | `credential_ref` |
| 8 | enabled_flag | 有効 | チェック | BOOLEAN | ○ | true | — | 入力 | `enabled_flag` |

### 4.5 イベント処理

| No | イベント | トリガ | 処理内容 | 呼出 API | 画面遷移 |
|---|---|---|---|---|---|
| 1 | クライアント発行 | 発行ボタン | scope 検証→secret 生成（一度だけ表示）→保存 | `POST /api/integration/api-clients` | 同一画面 |
| 2 | 失効 | 失効ボタン | 理由必須→status=90 | `POST /api/integration/api-clients/{id}/revoke` | 同一画面 |
| 3 | ファイル選択 | 選択 | 形式・サイズ検査 | — | 同一画面 |
| 4 | ドライラン | 実行ボタン | 検証のみ→エラー行表示 | `POST /api/integration/file-transfers/dry-run` | 同一画面 |
| 5 | 本実行 | 実行ボタン | 全件検証→取込→業務域引渡 | `POST /api/integration/file-transfers` | SCR-INT-020 |
| 6 | エラー DL | ダウンロード | エラー行 CSV | `GET /api/integration/file-transfers/{id}/errors` | — |
| 7 | テスト送信 | テストボタン | テスト文面を送信 | `POST /api/integration/notification-channels/{id}/test` | 同一画面 |
| 8 | 再送 | 再送ボタン | 失敗通知を再送 | `POST /api/integration/notification-logs/{id}/retry` | SCR-INT-022 |

### 4.6 表示制御

| 条件 | 対象 | 制御 |
|---|---|---|
| `integration:api-client:create` なし | 発行・失効 | 非表示（API 403） |
| secret 発行済 | secret 表示欄 | 初回のみ表示、以後はマスク |
| ドライラン未実施 | 本実行ボタン | 非活性 |
| 権限 `integration:notification-channel:update` なし | 保存・テスト | 非表示 |

---

## 5. 入力チェック仕様

| No | チェック ID | 対象 | 種別 | 条件 | タイミング | メッセージ |
|---|---|---|---|---|---|---|
| 1 | CHK-INT-009-01 | スコープ | 値域 | §2.3 の 7 種のみ | 発行時 | `MSG-INT-080` |
| 2 | CHK-INT-009-02 | 許可 IP | 形式 | CIDR または IP | 保存時 | `MSG-INT-081` |
| 3 | CHK-INT-009-03 | 有効期間 | 相関 | 開始 ≤ 終了 | 保存時 | `MSG-COM-046` |
| 4 | CHK-INT-011-01 | ファイル形式 | 形式 | CSV/XLSX/XML/固定長 | 取込時 | `MSG-INT-050` |
| 5 | CHK-INT-011-02 | 行数 | 上限 | ≤ 50,000 行 | 取込時 | `MSG-INT-054` |
| 6 | CHK-INT-011-03 | ヘッダ件数 | 相関 | ヘッダ件数 = 明細行数 | 取込時 | `MSG-INT-051` |
| 7 | CHK-INT-011-04 | 必須項目 | 必須 | レイアウト定義の必須列 | 取込時 | `MSG-INT-055` |
| 8 | CHK-INT-011-05 | コード存在 | 業務 | 物料・倉庫・取引先が存在 | 取込時 | `MSG-INT-056` |
| 9 | CHK-INT-012-01 | 宛先 | 形式 | メール/電話/Webhook | 送信時 | `MSG-INT-091` |
| 10 | CHK-INT-012-02 | チャネル | 状態 | 有効である | 送信時 | `MSG-INT-090` |

---

## 6. 処理詳細

### 6.1 処理一覧

| 処理 ID | 処理名 | 契機 | トランザクション | 排他 |
|---|---|---|---|---|
| PRC-INT-009-01 | 開放 API 認証 | リクエスト | 不要 | なし（nonce は Redis） |
| PRC-INT-009-02 | API クライアント発行 | 発行 | 要 | `client_id` 一意 |
| PRC-INT-011-01 | ファイル検証（ドライラン） | 実行 | 不要 | ファイルハッシュ |
| PRC-INT-011-02 | ファイル取込 | 実行 | 要（全件） | ファイルハッシュ |
| PRC-INT-012-01 | 通知送信 | SYS 依頼 | 不要（外部） | `notificationId` |
| PRC-INT-012-02 | 通知再送 | 失敗/手動 | 不要 | 同上 |

### 6.2 処理手順（正常系）

**PRC-INT-009-01 開放 API 認証**

1. `X-Client-Id` でクライアントを取得し、状態・有効期間を検証する。
2. 要求 IP を許可リストと照合する。
3. 署名文字列を再計算し、`X-Signature` と比較する（定数時間比較）。
4. 時刻差 ±5 分、nonce 未使用（Redis 10 分）を検証する。
5. スコープとレート制限を検証する。超過は 429。
6. 処理後、`int_api_call_log` に記録する（本文は概要のみ）。

**PRC-INT-011-02 ファイル取込**

1. ファイルを受信し、SHA-256 で重複を検査する。
2. レイアウト定義に従い、文字コード・ヘッダ・件数・型・必須・コード存在を全行検証する。
3. エラーが 1 件でもあれば `int_file_transfer_error` に保存し、`status=50` で終了する（本実行しない）。
4. 全行合格なら `int_file_transfer` を `status=30` とし、業務域の公開 API（SAL/PUR/FIN/MDM 等）へ 1,000 件ずつ引き渡す。
5. 全件成功で `status=40`、部分失敗は `status=45`（失敗分はエラー一覧）。引渡し結果を `int_sync_task` に記録する。

**PRC-INT-012-01 通知送信**

1. SYS から `notificationId`・チャネル・宛先・テンプレート・変数を受領する。
2. 通知設定（受信可否）を確認し、配信停止なら `skipped` とする。
3. チャネル別に送信（SMTP は TLS、SMS/Webhook は REST）。タイムアウト 10 秒。
4. 成功/失敗を `int_api_call_log` に記録し、失敗は再送キューへ。
5. 再送は最大 5 回。最終失敗は SYS に通知し、運用にエスカレーションする。

### 6.3 例外処理

| No | 異常条件 | 検知 | 処理 | ロールバック | メッセージ |
|---|---|---|---|---|---|
| 1 | 署名不一致 | 認証 | 401 | なし | `MSG-INT-082` |
| 2 | 時刻ずれ | 認証 | 401 | なし | `MSG-INT-082` |
| 3 | nonce 再利用 | 認証 | 401 | なし | `MSG-INT-083` |
| 4 | スコープ不足 | 認可 | 403 | なし | `MSG-COM-030` |
| 5 | レート超過 | 認可 | 429 | なし | `MSG-INT-010` |
| 6 | ファイル形式エラー | 検証 | 全件中止 | 全体 | `MSG-INT-050` |
| 7 | 行数超過 | 検証 | 中止 | 全体 | `MSG-INT-054` |
| 8 | 業務域引渡失敗 | 取込 | 部分成功として記録 | 行単位 | `MSG-INT-057` |
| 9 | 通知チャネル無効 | 送信 | 送信しない | なし | `MSG-INT-090` |
| 10 | 通知宛先不正 | 送信 | 送信しない | なし | `MSG-INT-091` |

### 6.4 冪等性・再実行

| 処理 | 冪等キー | 再実行 |
|---|---|---|
| 受注登録 API | `Idempotency-Key` | 24 時間以内は初回結果 |
| ファイル取込 | `file_hash` | 同一ファイルは拒否、訂正は新規 |
| 通知 | `notificationId + channel` | 二重送信しない |
| API クライアント発行 | `client_id` | 再発行は新 ID（旧は失効） |

---

## 7. API 設計

| No | メソッド | パス | 権限 | 概要 |
|---|---|---|---|---|
| 1 | GET | `/api/integration/api-clients` | `integration:api-client:view` | クライアント一覧 |
| 2 | POST | `/api/integration/api-clients` | `integration:api-client:create` | 発行（secret を一度だけ返す） |
| 3 | POST | `/api/integration/api-clients/{id}/revoke` | `integration:api-client:update` | 失効 |
| 4 | GET | `/api/integration/api-call-logs` | `integration:call-log:view` | 呼出ログ |
| 5 | GET | `/api/integration/api-call-logs/stats` | `integration:api-client:view` | 利用統計 |
| 6 | POST | `/api/integration/file-transfers/dry-run` | `integration:file-transfer:import` | ドライラン |
| 7 | POST | `/api/integration/file-transfers` | `integration:file-transfer:import` | 本実行 |
| 8 | GET | `/api/integration/file-transfers` | `integration:file-transfer:view` | 取込一覧 |
| 9 | GET | `/api/integration/file-transfers/{id}/errors` | `integration:file-transfer:view` | エラー行 CSV |
| 10 | GET | `/api/integration/notification-channels` | `integration:notification-channel:view` | チャネル一覧 |
| 11 | POST | `/api/integration/notification-channels/{id}/test` | `integration:notification-channel:update` | テスト送信 |
| 12 | GET | `/api/integration/notification-logs` | `integration:notification-log:view` | 送信履歴 |
| 13 | POST | `/api/integration/notification-logs/{id}/retry` | `integration:notification-channel:update` | 再送 |

### 7.1 開放 API リクエスト例（受注登録・【示例値】）

```http
POST /api/open/v1/sales-orders
X-Client-Id: 3f6c2a1e-...
X-Timestamp: 1792492800
X-Nonce: 5b2f0c1a-...
X-Signature: Base64(HMAC-SHA256(...))
Idempotency-Key: EDI-20261020-0001
Content-Type: application/json

{
  "externalNo": "CUST-PO-20261020-001",
  "customerCode": "C000123",
  "orderDate": "2026-10-20",
  "deliveryDate": "2026-11-05",
  "currencyCode": "CNY",
  "lines": [
    { "materialCode": "3001000001", "quantity": "120.0000", "uomCode": "PCE", "unitPrice": "856.500000" }
  ]
}
```

### 7.2 開放 API エラー例（レート超過）

```json
{ "code": 5002, "message": "请求过于频繁，请稍后重试。", "data": { "retryAfterSeconds": 30 } }
```

---

## 8. データ更新仕様

| テーブル | 操作 | 更新項目 | トリガ |
|---|---|---|---|
| `int_api_client` | INSERT/UPDATE | scope・IP・状態・`last_used_at` | 発行・失効 |
| `int_api_call_log` | INSERT | 呼出結果 | 全 API |
| `int_file_layout` | INSERT/UPDATE | レイアウト定義 | 設定 |
| `int_file_transfer` / `_error` | INSERT/UPDATE | 取込結果・エラー | 取込 |
| `int_notification_channel` | INSERT/UPDATE | 設定・テスト結果 | 設定 |
| `int_external_message` | INSERT | 原文 | 取込・送信 |
| `sys_notification_send_log`（SYS） | — | SYS が管理 | 送信依頼 |

---

## 9. エラー処理・メッセージ

| メッセージ ID | 種別 | 本文 | 発生条件 | 対処 |
|---|---|---|---|---|
| `MSG-INT-080` | E | 指定的权限范围无效。 | scope 不正 | 修正 |
| `MSG-INT-081` | E | IP 地址格式不正确。 | 形式エラー | 修正 |
| `MSG-INT-082` | E | 签名验证失败或请求时间超时，请检查密钥与服务器时间。 | 署名/時刻 | 設定確認 |
| `MSG-INT-083` | E | 请求重复（nonce 已使用），请重新生成。 | nonce 再利用 | 再生成 |
| `MSG-INT-050` | E | 文件格式不正确（第 {0} 行：{1}）。 | 形式エラー | 修正 |
| `MSG-INT-054` | E | 文件行数超过上限（{0} 行）。 | 行数超過 | 分割 |
| `MSG-INT-055` | E | 第 {0} 行缺少必填项「{1}」。 | 必須漏れ | 修正 |
| `MSG-INT-056` | E | 第 {0} 行的代码「{1}」不存在或已失效。 | コード不存在 | マスタ確認 |
| `MSG-INT-057` | W | 导入完成：成功 {0} 行，失败 {1} 行。 | 部分成功 | エラー行修正 |
| `MSG-INT-090` | E | 通知渠道未启用或配置不正确。 | チャネル無効 | 設定確認 |
| `MSG-INT-091` | E | 通知接收地址无效。 | 宛先不正 | 修正 |
| `MSG-INT-092` | W | 通知发送失败，系统将自动重试（第 {0} 次）。 | 送信失敗 | 監視 |

---

## 10. 権限・セキュリティ

| 種別 | 内容 |
|---|---|
| 画面権限 | `integration:api-client:*`、`integration:file-transfer:*`、`integration:notification-channel:*` |
| 操作権限 | 発行・失効は情報部長承認。ファイル本実行は取込権限者のみ |
| データ範囲 | 全社（情報部）。取引先 API は自社関連データのみ |
| 監査 | 発行・失効・取込・通知送信を記録。API は全リクエストを `int_api_call_log` に記録 |
| 機密 | secret は発行時のみ表示、以後はハッシュ。通知本文に個人情報を含めない |
| 通信 | HTTPS 必須。Webhook は TLS 検証を省略しない |
| ファイル | 受信ファイルはウイルススキャン（Phase 2 ClamAV）後、90 日で削除 |

---

## 11. 性能・非機能

| 項目 | 目標 | 前提 |
|---|---|---|
| 開放 API 応答 | 1 秒以内（P95） | 内部 API の性能に依存 |
| レート制限 | 600 req/分/client | Redis カウンタ |
| ファイル検証 | 50,000 行で 60 秒以内 | 非同期ジョブ |
| 通知送信 | 5 秒以内（非同期） | SMTP/GW の SLA |
| 同時接続 | 50 クライアント | — |

---

## 12. テスト観点

| No | 観点 ID | 分類 | 観点 | 期待結果 |
|---|---|---|---|---|
| 1 | TST-F-INT-009-01 | 正常系 | 正しい署名で受注登録 | 201、受注作成 |
| 2 | TST-F-INT-009-02 | 異常系 | 署名不一致 | 401 `MSG-INT-082` |
| 3 | TST-F-INT-009-03 | 異常系 | 時刻ずれ 6 分 | 401 |
| 4 | TST-F-INT-009-04 | 異常系 | nonce 再利用 | 401 `MSG-INT-083` |
| 5 | TST-F-INT-009-05 | 権限 | スコープ外 | 403 |
| 6 | TST-F-INT-009-06 | 境界 | 600 req/分ちょうど | 成功、601 で 429 |
| 7 | TST-F-INT-009-07 | 冪等 | 同一 Idempotency-Key | 初回結果を返す |
| 8 | TST-F-INT-009-08 | 異常系 | 失効クライアント | 401 |
| 9 | TST-F-INT-011-01 | 正常系 | 対账单 CSV 取込 | 全件成功 |
| 10 | TST-F-INT-011-02 | 異常系 | 1 行必須漏れ | 全件中止、エラー行保存 |
| 11 | TST-F-INT-011-03 | 冪等 | 同一ファイル再取込 | 拒否 |
| 12 | TST-F-INT-011-04 | 境界 | 50,000 行 | 成功、50,001 行で拒否 |
| 13 | TST-F-INT-011-05 | 異常系 | GBK ファイルを UTF-8 指定 | 復号エラー、取込中止 |
| 14 | TST-F-INT-012-01 | 正常系 | メール送信 | 送信成功ログ |
| 15 | TST-F-INT-012-02 | 異常系 | SMTP 接続失敗 | 再送キュー、5 回で失敗 |
| 16 | TST-F-INT-012-03 | 冪等 | 同一 notificationId | 二重送信しない |
| 17 | TST-F-INT-012-04 | セキュリティ | 本文に口座番号 | マスキングされる |

---

## 13. 未決事項

| # | 事項 | 理由 | 暫定仕様 | 担当 | 期限 |
|---|---|---|---|---|---|
| 1 | 開放 API の Phase 1 認証（HMAC 必須可否） | 取引先の実装負荷 | HMAC 必須。簡易 API Key は社内のみ | Lead／情報部 | 2026-11-30 |
| 2 | 開放 API の公開範囲（受注登録を許すか） | 取引先との契約次第 | Phase 1 は参照のみ、登録は Phase 2 | SAL／情報部 | 2026-12-15 |
| 3 | ファイル取込上限（50,000 行） | 銀行・EDI の実データ量が未確定 | `sys_param` で変更可 | integration | 2026-12-15 |
| 4 | 短信・WeCom・DingTalk の契約 | 顧客の契約状況 | Phase 1 は SMTP のみ | 情報部 | 2026-12-31 |
| 5 | ウイルススキャンの導入時期 | Phase 2（ClamAV） | Phase 1 は拡張子・サイズ検査のみ | 情報部 | 2027-03-31 |
| 6 | Webhook の再送・署名検証 | 先方仕様が未確定 | 汎用 Webhook（JSON POST）、署名は Phase 2 | integration | 2027-03-31 |
| 7 | EDI 注文の標準（XML スキーマ） | 顧客ごとに異なる | 顧客別レイアウトを `int_file_layout` に定義 | SAL | Phase 2 |

## 14. 改訂履歴

| 版数 | 日付 | 変更内容 | 変更者 |
|---|---|---|---|
| v1.0 | 2026-10-20 | 初版：開放 API（HMAC・scope・レート制限）、ファイル取込（検証/ドライラン/エラー）、通知 4 チャネル、画面 5、API 13、テスト観点 | integration-designer |
| v1.1 | 2026-10-20 | 红队 REV-SW-003 対応：429 レート超過のコードを `5002` に修正（00-common 03 §6.2/§14 と一致） | system-workflow |
