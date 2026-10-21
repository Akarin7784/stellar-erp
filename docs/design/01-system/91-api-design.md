# 系统管理 API 设计书（系统管理 API 設計書）

| 項目 | 内容 |
|---|---|
| 文書名 | 系统管理 API 设计书（系统管理 API 設計書） |
| 文書番号 | DSN-SYS-091 |
| 版数 | v1.13 |
| 作成日 | 2026-10-20 |
| 作成者 | system-workflow（域設計担当） |
| 承認者 | 未承認（レビュー待ち） |
| 状態 | ドラフト（レビュー中） |
| 関連文書 | [業務域概要](00-overview.md) / [DB 設計](90-db-design.md) / [API 共通規格](../00-common/03-common-api-spec.md) / [メッセージ](93-messages.md) |

---

## 1. 適用範囲と共通仕様

本域 API は `/api/system/**` に配置する。パス・メソッド・`Result<T>`・`PageResult<T>`・認証（Sa-Token）、権限（`@SaCheckPermission`）、冪等（`Idempotency-Key`）、楽観排他（`version`）は [API 共通規格](../00-common/03-common-api-spec.md) に従い、本紙では**本域固有の項目・エラーコード・権限**を定義する。

### 1.1 業務エラーコード（SYS 領域：10000-19999）

| コード | メッセージ ID | 内容 | HTTP |
|---|---|---|---|
| 10001 | MSG-COM-050 | ユーザ重複（03 §6.1） | 422 |
| 10005 | MSG-COM-026 | パスワード強度不足（改密） | 422 |
| 10002 | MSG-SYS-002 | 内置アカウント操作不可 | 422 |
| 10003 | MSG-SYS-003〜007 | パスワード変更エラー | 400/422 |
| 10010 | MSG-SYS-012 | SoD 競合（理由必須） | 422 |
| 10011 | MSG-SYS-011 | 自己付与禁止 | 422 |
| 10020 | MSG-SYS-017 | ロール削除不可（付与中） | 422 |
| 10030 | MSG-SYS-032 | 部門循環参照 | 422 |
| 10031 | MSG-SYS-031 | 部門無効化不可（使用中） | 422 |
| 10035 | MSG-SYS-093 | 公司代码・统一社会信用代码重複（公司登録） | 422 |
| 10040 | MSG-SYS-040 | 内置辞書/パラメータ | 422 |
| 10041 | MSG-SYS-044 | パラメータ型不一致 | 400 |
| 10050 | MSG-SYS-050 | 採番ルールなし | 422 |
| 10052 | MSG-SYS-052 | 採番ロックタイムアウト | 422 |
| 10055 | MSG-SYS-055 | 採番桁数短縮不可 | 422 |
| 10060 | MSG-SYS-070 | ファイル保存/読取失敗 | 500 |
| 10061 | MSG-SYS-071 | 添付上限超過 | 422 |
| 10070 | MSG-SYS-060 | 監査期間超過 | 400 |
| 10080 | MSG-SYS-080 | 帳票生成失敗 | 500 |
| 10090 | MSG-SYS-086 | 初期化二重実行 | 422 |
| 5000 | MSG-SYS-091 | 監査ログ書込み失敗（重要操作。サーバー側障害、業務トランザクション全体をロールバック。例：公司登録）（蓝色大肥鱼 2026-10-21 决定） | 500 |
| 10900 | MSG-SYS-001 | アカウント停用/退職（ログイン API では HTTP 200、他 API では 422） | 200/422 |

### 1.2 選択用（`/options`）API の共通規則（蓝色大肥鱼 2026-10-21 決定）

- **適用範囲**：複数の業務画面で共有するマスタ・基礎データのドロップダウン用 `/options` API に限る。これらは**ログインのみ**を要件とし、権限コード（`@SaCheckPermission`）を付けない。
- 管理画面専用の選択肢 API は対象外とし、当該画面の `view` 権限コードを維持する（反例：#108 `/api/system/maintenance/options` は `system:maintenance:view`）。
- 未ログインは 401（認証インターセプタ導入後に有効）。
- データ範囲は当前会社（ログインセッション `LoginContext`、`companyId` パラメータは無視）と RLS（テナント）で限定する。
- 対象：#36a `/api/system/departments/options`。

## 2. API 一覧

| # | メソッド | パス | 権限 | 概要 | 関連機能 | 主なエラー |
|---|---|---|---|---|---|---|
| 1 | GET | /api/system/auth/captchas | 公開 | 検証コード発行 | F-SYS-001 | 503 |
| 2 | POST | /api/system/auth/login | 公開 | ログイン | F-SYS-001 | 1001/2002/2003/2004/2005/10900/4003（すべて HTTP 200。リクエストボディが不正 JSON 等のプロトコル層エラーは 400、03 §6.1） |
| 3 | POST | /api/system/auth/logout | 公開 | ログアウト（冪等。トークン無効・期限切れでも 200） | F-SYS-001 | — |
| 4 | GET | /api/system/auth/me | 認証済 | ログインユーザ・権限（コードで重複排除）・メニュー | F-SYS-001/003/004 | 2001 |
| 5 | POST | /api/system/auth/password | 認証済 | パスワード変更 | F-SYS-001 | 10003/10005/4003（409） |
| 6 | GET | /api/system/profile | 認証済 | プロフィール取得 | F-SYS-018 | 2001 |
| 7 | PUT | /api/system/profile | `system:profile:update` | プロフィール更新 | F-SYS-018 | 1001/4003 |
| 8 | PUT | /api/system/profile/preferences | `system:profile:update` | 通知・画面設定 | F-SYS-018 | 1001 |
| 9 | GET | /api/system/profile/sessions | `system:profile:view` | 自セッション一覧 | F-SYS-018 | 503 |
| 10 | DELETE | /api/system/profile/sessions/{tokenId} | `system:profile:update` | 他セッション失効 | F-SYS-018 | 4001 |
| 11 | GET | /api/system/users | `system:user:view` | ユーザ一覧 | F-SYS-002 | 3001 |
| 12 | GET | /api/system/users/{id} | `system:user:view` | ユーザ詳細 | F-SYS-002 | 4001/3002 |
| 13 | GET | /api/system/users/next-code | `system:user:create` | 工号採番候補 | F-SYS-002 | — |
| 14 | POST | /api/system/users | `system:user:create` | ユーザ登録 | F-SYS-002 | 10001/10010/4005 |
| 15 | PUT | /api/system/users/{id} | `system:user:update` | ユーザ更新 | F-SYS-002 | 4003/10031 |
| 16 | DELETE | /api/system/users/{id} | `system:user:delete` | ユーザ削除 | F-SYS-002 | 10002/4002 |
| 17 | POST | /api/system/users/{id}/disable | `system:user:disable` | 停用 | F-SYS-002 | 10019 |
| 18 | POST | /api/system/users/{id}/enable | `system:user:reopen` | 再開 | F-SYS-002 | 4002 |
| 19 | POST | /api/system/users/{id}/reset-password | `system:user:reset-password` | パスワードリセット | F-SYS-002 | 10014 |
| 20 | POST | /api/system/users/{id}/unlock | `system:user:unlock` | ロック解除 | F-SYS-002 | 4002 |
| 21 | GET | /api/system/users/{id}/roles | `system:user:view` | 付与ロール | F-SYS-002 | 4001 |
| 22 | POST | /api/system/users/{id}/roles | `system:user-role:update` | ロール付与 | F-SYS-002 | 10010/10011 |
| 23 | POST | /api/system/users/batch-disable | `system:user:disable` | 一括停用 | F-SYS-002 | 4002 |
| 24 | POST | /api/system/users/export | `system:user:export` | ユーザ台帳出力 | F-SYS-002/013 | 10065 |
| 25 | GET | /api/system/roles | `system:role:view` | ロール一覧 | F-SYS-003 | 3001 |
| 26 | GET | /api/system/roles/{id} | `system:role:view` | ロール詳細 | F-SYS-003 | 4001 |
| 27 | POST | /api/system/roles | `system:role:create` | ロール登録 | F-SYS-003 | 10015 |
| 28 | PUT | /api/system/roles/{id} | `system:role:update` | ロール更新 | F-SYS-003 | 10016/4003 |
| 29 | DELETE | /api/system/roles/{id} | `system:role:delete` | ロール削除 | F-SYS-003 | 10020/10018 |
| 30 | GET | /api/system/roles/{id}/users | `system:role:view` | 付与ユーザ一覧 | F-SYS-003 | 4001 |
| 31 | GET | /api/system/menus/tree | `system:menu:view` | 管理用メニューツリー | F-SYS-004 | 3001 |
| 32 | GET | /api/system/menus/routes | 認証済 | ログインユーザのルート | F-SYS-004 | 2001 |
| 33 | POST | /api/system/menus | `system:menu:create` | メニュー登録 | F-SYS-004 | 10022/10024 |
| 34 | PUT | /api/system/menus/{id} | `system:menu:update` | メニュー更新 | F-SYS-004 | 10022/4003 |
| 35 | DELETE | /api/system/menus/{id} | `system:menu:delete` | メニュー無効化 | F-SYS-004 | 10023 |
| 36 | GET | /api/system/departments/tree | `system:department:view` | 部門ツリー | F-SYS-005 | 3001 |
| 36a | GET | /api/system/departments/options | 認証済（§1.2） | 部門選択用一覧（ドロップダウン、§3.7） | F-SYS-005 | 3001 |
| 37 | GET | /api/system/departments/{id} | `system:department:view` | 部門詳細 | F-SYS-005 | 4001 |
| 38 | POST | /api/system/departments | `system:department:create` | 部門登録 | F-SYS-005 | 10030/10033 |
| 39 | PUT | /api/system/departments/{id} | `system:department:update` | 部門更新 | F-SYS-005 | 4003/10030 |
| 40 | PUT | /api/system/departments/{id}/move | `system:department:update` | 部門移動 | F-SYS-005 | 10030/10033 |
| 41 | DELETE | /api/system/departments/{id} | `system:department:delete` | 部門無効化 | F-SYS-005 | 10031 |
| 42 | GET | /api/system/departments/{id}/users | `system:user:view` | 所属ユーザ | F-SYS-005/002 | 4001 |
| 43 | GET | /api/system/positions | `system:position:view` | 岗位一覧 | F-SYS-006 | 3001 |
| 44 | POST | /api/system/positions | `system:position:create` | 岗位登録 | F-SYS-006 | 1001 |
| 45 | PUT | /api/system/positions/{id} | `system:position:update` | 岗位更新 | F-SYS-006 | 4003 |
| 46 | DELETE | /api/system/positions/{id} | `system:position:delete` | 岗位無効化 | F-SYS-006 | 10036 |
| 47 | GET | /api/system/companies | `system:company:view` | 公司一覧 | F-SYS-014 | 3001 |
| 47a | POST | /api/system/companies | `system:company:create` | 公司登録（同一 TX で `sys_init_company` を呼び `sys_param` 既定行と `SYSTEM_ADMIN` ロール＋全権限付与を投入、[90 §3.1](90-db-design.md)・[94 §2.10](94-sample-data.md)） | F-SYS-014 | 1001/10035 |
| 48 | PUT | /api/system/companies/{id} | `system:company:update` | 公司更新 | F-SYS-014 | 4003 |
| 49 | GET | /api/system/factories | `system:company:view` | 工厂组织設合一覧（MDM の `mdm_factory` を参照） | F-SYS-014 | 3001 |
| 50 | POST | /api/system/factories | `system:company:update` | 工厂組織設定登録（有効化・既定割当） | F-SYS-014 | 10034 |
| 51 | PUT | /api/system/factories/{id} | `system:company:update` | 工厂組織設定更新 | F-SYS-014 | 10034/4003 |
| 52 | GET | /api/system/tenants | `system:tenant:view` | 租户一覧 | F-SYS-017 | 3001 |
| 53 | GET | /api/system/dicts | `system:dict:view` | 字典类型一覧 | F-SYS-007 | 3001 |
| 54 | GET | /api/system/dicts/{code}/items | 認証済 | 字典項目（業務参照） | F-SYS-007 | 4001 |
| 55 | POST | /api/system/dicts | `system:dict:create` | 字典类型登録 | F-SYS-007 | 1001 |
| 56 | PUT | /api/system/dicts/{code}/items | `system:dict:update` | 字典項目一括保存 | F-SYS-007 | 10042/10043 |
| 57 | GET | /api/system/params | `system:param:view` | パラメータ一覧 | F-SYS-008 | 3001 |
| 58 | GET | /api/system/params/{key} | 認証済 | パラメータ取得 | F-SYS-008 | 4001 |
| 59 | PUT | /api/system/params/{key} | `system:param:update` | パラメータ更新 | F-SYS-008 | 10041/10045 |
| 60 | POST | /api/system/caches/refresh | `system:cache:refresh` | キャッシュ再構築 | F-SYS-020 | 10088 |
| 61 | GET | /api/system/audit-logs | `system:audit-log:view` | 監査ログ検索 | F-SYS-009 | 10070 |
| 62 | GET | /api/system/audit-logs/{id} | `system:audit-log:view` | 監査詳細 | F-SYS-009 | 4001 |
| 63 | POST | /api/system/audit-logs/export | `system:audit-log:export` | 監査出力 | F-SYS-009 | 10065 |
| 64 | GET | /api/system/login-logs | `system:login-log:view` | ログインログ検索 | F-SYS-009 | 3001 |
| 65 | POST | /api/system/login-logs/export | `system:login-log:export` | ログインログ出力 | F-SYS-009 | 10065 |
| 66 | POST | /api/system/attachments | `system:attachment:upload` | 添付アップロード | F-SYS-010 | 10060/10061 |
| 67 | GET | /api/system/attachments/{id} | `system:attachment:view` | 添付ダウンロード | F-SYS-010 | 3002/10060 |
| 68 | GET | /api/system/attachments | `system:attachment:view` | 添付検索 | F-SYS-010 | 3001 |
| 69 | DELETE | /api/system/attachments/{id} | `system:attachment:delete` | 添付削除 | F-SYS-010 | 3001 |
| 70 | GET | /api/system/attachments/biz/{bizType}/{bizId} | 認証済 | 業務別添付 | F-SYS-010 | 3002 |
| 71 | GET | /api/system/notifications | `system:notification:view` | 通知一覧 | F-SYS-011 | 3001 |
| 72 | GET | /api/system/notifications/unread-count | `system:notification:view` | 未読件数 | F-SYS-011 | — |
| 73 | PUT | /api/system/notifications/{id}/read | `system:notification:read` | 既読 | F-SYS-011 | 10077 |
| 74 | PUT | /api/system/notifications/read-all | `system:notification:read` | 一括既読 | F-SYS-011 | — |
| 75 | GET | /api/system/notifications/todos | 認証済 | 待办一覧（WF 連携） | F-SYS-011 | — |
| 76 | GET | /api/system/notification-templates | `system:notification-template:view` | テンプレート一覧 | F-SYS-019 | 3001 |
| 77 | POST | /api/system/notification-templates | `system:notification-template:update` | テンプレート新版 | F-SYS-019 | 10072/10061 |
| 78 | POST | /api/system/notification-templates/{id}/test-send | `system:notification-template:update` | テスト送信 | F-SYS-019 | 10074 |
| 79 | GET | /api/system/notification-logs | `system:notification-log:view` | 送信履歴 | F-SYS-019 | 3001 |
| 80 | POST | /api/system/notification-logs/{id}/resend | `system:notification-log:view` | 再送 | F-SYS-019 | 4002 |
| 81 | GET | /api/system/number-rules | `system:number-rule:view` | 採番ルール一覧 | F-SYS-012 | 3001 |
| 82 | GET | /api/system/number-rules/{code} | `system:number-rule:view` | 採番ルール詳細 | F-SYS-012 | 4001 |
| 83 | POST | /api/system/number-rules | `system:number-rule:update` | ルール登録 | F-SYS-012 | 10055 |
| 84 | PUT | /api/system/number-rules/{code} | `system:number-rule:update` | ルール更新 | F-SYS-012 | 10054/10055 |
| 85 | POST | /api/system/number-rules/{code}/preview | `system:number-rule:view` | 採番プレビュー | F-SYS-012 | 4001 |
| 86 | GET | /api/system/import-templates | `system:import-template:view` | テンプレート一覧 | F-SYS-013 | 3001 |
| 87 | GET | /api/system/import-templates/{id}/download | `system:import-template:view` | テンプレート DL | F-SYS-013 | 4001 |
| 88 | POST | /api/system/jobs/import | `system:job:create` | インポート起動 | F-SYS-013 | 10056/10057 |
| 89 | POST | /api/system/jobs/export | 各域 `:export` | エクスポート起動 | F-SYS-013 | 10065 |
| 90 | GET | /api/system/jobs | `system:job:view` | ジョブ一覧 | F-SYS-013 | 3001 |
| 91 | GET | /api/system/jobs/{id} | `system:job:view` | ジョブ状態 | F-SYS-013 | 4001 |
| 92 | GET | /api/system/jobs/{id}/files/{fileId} | `system:job:download` | 結果 DL | F-SYS-013 | 10066 |
| 93 | GET | /api/system/jobs/{id}/errors | `system:job:view` | エラー行一覧 | F-SYS-013 | 4001 |
| 94 | POST | /api/system/jobs/{id}/errors/export | `system:job:view` | エラー報告出力 | F-SYS-013 | 10065 |
| 95 | DELETE | /api/system/jobs/{id} | `system:job:cancel` | キャンセル | F-SYS-013 | 4002 |
| 96 | POST | /api/system/jobs/{id}/retry | `system:job:create` | 再実行 | F-SYS-013 | 4002 |
| 97 | GET | /api/system/print-templates | `system:print-template:view` | テンプレート一覧 | F-SYS-015 | 3001 |
| 98 | POST | /api/system/print-templates | `system:print-template:update` | テンプレート新版 | F-SYS-015 | 10080/10081 |
| 99 | GET | /api/system/print-templates/{id} | `system:print-template:view` | 詳細 | F-SYS-015 | 4001 |
| 100 | POST | /api/system/print-templates/{id}/preview | `system:print-template:view` | プレビュー | F-SYS-015 | 10080 |
| 101 | PUT | /api/system/print-templates/{id}/default | `system:print-template:update` | 既定指定 | F-SYS-015 | 10082 |
| 102 | GET | /api/system/online-users | `system:online-user:view` | セッション一覧 | F-SYS-016 | 503 |
| 103 | POST | /api/system/online-users/{tokenId}/kickout | `system:online-user:kickout` | 強制ログアウト | F-SYS-016 | 4001 |
| 104 | GET | /api/system/scheduled-jobs | `system:job-monitor:view` | ジョブ定義一覧 | F-SYS-016 | 3001 |
| 105 | GET | /api/system/scheduled-jobs/{id}/logs | `system:job-monitor:view` | 実行履歴 | F-SYS-016 | 4001 |
| 106 | POST | /api/system/scheduled-jobs/{id}/run | `system:job-monitor:run` | 手動実行 | F-SYS-016 | 10084 |
| 107 | PUT | /api/system/scheduled-jobs/{id}/status | `system:job-monitor:run` | 停止/再開 | F-SYS-016 | 4003 |
| 108 | GET | /api/system/maintenance/options | `system:maintenance:view` | 维护種別 | F-SYS-020 | 3001 |
| 109 | POST | /api/system/maintenance/dry-run | `system:maintenance:execute` | ドライラン | F-SYS-020 | — |
| 110 | POST | /api/system/maintenance/execute | `system:maintenance:execute` | 维护実行 | F-SYS-020 | 10085/10086/10087 |
| 111 | GET | /api/system/maintenance/logs | `system:maintenance:view` | 维护履歴 | F-SYS-020 | 3001 |
| 112 | GET | /api/system/outbox-events | `system:outbox:view` | Outbox 監視 | F-SYS-020 | 3001 |
| 113 | POST | /api/system/outbox-events/{id}/retry | `system:outbox:retry` | イベント再送 | F-SYS-020 | 4002 |

> 全 114 API（47a は 2026-10-21 追加）。リクエスト/レスポンスの詳細は各機能文書（01〜07）の第 7 章を正とし、本章は横断一覧と固有エラーコードを定義する。

## 3. API 詳細（主要 API）

### 3.1 POST /api/system/auth/login

| 項目 | 内容 |
|---|---|
| 目的 | 認証してトークン・権限・メニューを返す |
| 権限 | 公開（レート制限：同一 IP 20 回/分） |
| 冪等 | なし（二重送信は 3 秒以内の同一 username を拒否） |
| 排他 | ユーザ行の楽観排他（`version` で `login_fail_count` 更新） |
| 関連テーブル | sys_user、sys_login_log、sys_audit_log、sys_user_role、sys_role_permission、sys_menu |

リクエスト項目：

| 項目 | 型 | 必須 | 説明 |
|---|---|---|---|
| tenantCode | string | ○ | 企業代码（`sys_tenant.tenant_code`、全体一意）。フロントは localStorage に前回値を保持 |
| username | string | ○ | ログインアカウント（工号、租户内一意） |
| password | string | ○ | パスワード（平文、TLS 前提） |
| captchaKey | string | △ | 検証コードキー（失敗 3 回以上で必須） |
| captcha | string | △ | 検証コード（4 桁英数） |
| rememberMe | boolean | — | アカウント記憶 |

レスポンス項目：`token` / `tokenName` / `expiresIn` / `passwordResetRequired` / `userInfo{id,userCode,realName,departmentName,avatarUrl}` / `roles[{roleCode,roleName}]` / `permissions[]`（付与された権限コードを**コードで重複排除**した集合、[94 §2.10](94-sample-data.md)） / `menus[]`（`id`/`parentId`/`menuType`/`menuCode`/`menuName`/`isVisible`/`routePath`/`sortNo` の 8 項目のフラット配列。当前会社で権限のあるメニュー＋祖先目录、`status=1`・未削除・`menu_type<>3`、`is_visible` では絞り込まず `isVisible=false` も返却。外部リンク（`menu_type=4`）も `menus[]` に含め、`routePath` に外部リンク URL を格納する。フロントはクリック時に新しいタブで開き、ルートは生成せず権限による遮断も行わない（専用 URL 項目は将来必要になった時点で別途追加）（蓝色大肥鱼 2026-10-21 決定））。`dataScopes` は別 PR。企業代码不存在・ユーザ不存在・パスワード誤りは同一の 2002／MSG-COM-021、検証コードは 2005／MSG-COM-022（[01-auth-login](01-auth-login.md) §7.1）（蓝色大肥鱼 2026-10-21 #71 決定）。

### 3.2 POST /api/system/users

| 項目 | 内容 |
|---|---|
| 目的 | ユーザ開立（即時 or WF 承認申請） |
| 権限 | `system:user:create` |
| 冪等 | `Idempotency-Key` 必須 |
| 排他 | 工号・ユーザ名一意制約 |
| 関連テーブル | sys_user、sys_user_role、sys_user_data_scope、sys_audit_log |

リクエスト項目：`userCode`(string,○)、`username`(string,○)、`realName`(string,○)、`employeeType`(int)、`departmentId`(string,○)、`positionId`(string)、`factoryId`(string)、`managerUserId`(string)、`mobile`(string)、`email`(string)、`hireDate`(string)、`roleIds`(string[],○)、`status`(int)、`dataScopeOverride`(array)。

レスポンス：`{id, userCode, initialPassword?}` または `{processInstanceId}`。

### 3.3 PUT /api/system/roles/{id}

リクエスト項目：`version`(int,○)、`roleName`(string)、`dataScopeType`(int,1〜7)、`permissionTree`(string[])、`resourceScope`(array、要素に `scopeType`1〜7・`factoryIds`・`warehouseIds`)、`fieldPermissions`(object)、`requiresApproval`(boolean)、`description`(string)。

エラー例（SoD 競合）：

```json
{ "code": 10010, "message": "所选角色存在职责分离冲突（PURCHASE_CREATE×PURCHASE_APPROVE）。如确需兼任，请填写理由。",
  "data": { "conflicts": ["PURCHASE_CREATE×PURCHASE_APPROVE"] } }
```

### 3.4 POST /api/system/attachments

multipart。項目：`bizType`(string,○)、`bizId`(string,○)、`fileCategory`(string)、`file`(binary,○)。制限：20MB、許可形式、1 業務 20 件/100MB。レスポンス：`{id, attachmentNo, originalName, fileSize, sha256, virusScanStatus}`。

### 3.5 POST /api/system/jobs/import / export

`import` は multipart（`templateId`、`mode`、`overwrite`、`errorPolicy`、`file`）。`export` は JSON（`moduleCode`、`resourceCode`、`queryParams`、`columns`、`format`）。両者 202 + `{jobId, jobNo, jobStatus}`。状態取得は `GET /api/system/jobs/{id}`。

### 3.6 GET /api/system/outbox-events

Outbox 監視（`status`、`eventType`、`from`/`to`、ページング）。Paylaod は概要のみ返し、個人情報を含む可能性がある場合はマスキングする。

### 3.7 GET /api/system/departments/options

部門ドロップダウン用の選択一覧（API #36a、バックエンド PR #61）。

| 項目 | 内容 |
|---|---|
| 権限 | ログインのみ（権限コードなし、§1.2 選択用 API 共通規則）。データ範囲は当前会社 + RLS で限定 |
| リクエスト | パラメータなし。会社はログインセッション（`LoginContext`）の当前会社を使用し、`companyId` パラメータは指定されても無視する |
| 絞り込み | `company_id = 当前会社`、`deleted = FALSE`、`status = 1`。テナントは RLS（`app.tenant_id`）で分離 |
| 返却項目 | `id`（文字列）、`departmentCode`、`departmentName`（[02/91 §3.8](../02-mdm/91-api-design.md) 選択用 API 規則：ID・コード・名称が必須） |
| 並び順 | `sort_no`、`department_code` の昇順 |
| ページング | なし（全件） |

### 3.8 POST /api/system/companies

公司登録（API #47a、PRC-SYS-014-03、バックエンド PR #89）。

| 項目 | 内容 |
|---|---|
| 権限 | `system:company:create` |
| リクエスト | `companyCode`、`companyName`、`unifiedSocialCreditCode` ほか。テナントはログインコンテキストから取得し、リクエスト本文の `companyId`／`tenantId`／`id` は指定されても無視する |
| 処理 | `sys_company` を INSERT（`company_id` = 自行 `id`）し、同一トランザクションで `sys_init_company(p_tenant_id, p_company_id)` を呼ぶ。初期化失敗時は会社登録ごとロールバック |
| 成功 | HTTP 201、`code=0`、`data = {id, companyCode, companyName, version}`（`id` は文字列で返す。`version` は新規行の値 0） |
| 入力エラー | HTTP 400／`1001`、`data.fieldErrors[]`（[00-common/03](../00-common/03-common-api-spec.md) §5.3） |
| 重複 | 一意索引 `uk_sys_company_code`・`uk_sys_company_credit` の違反（23505）**のみ** HTTP 422／`10035`／`MSG-SYS-093`。それ以外の一意違反は `10035` に変換しない |
| 入力値の個別エラー | `unifiedSocialCreditCode` の形式・GB 32100-2015 校验位違反は MSG-COM-088（空は MSG-COM-040、超長は MSG-COM-041）、`taxPayerType` が 1/2 以外・`fiscalYearStartMonth` が 1〜12 以外は MSG-COM-089、`baseCurrencyCode` 形式違反は MSG-COM-088（いずれも 400／`1001`、[03 §5](03-org-position.md) CHK-SYS-014-01・04〜06）（蓝色大肥鱼 2026-10-21 决定） |
| 監査ログ | 同一トランザクションで `sys_audit_log` を INSERT（`company_id`＝操作者セッション会社、新会社は `resource_id`）。失敗時は全体ロールバックし HTTP 500／`5000`／`MSG-SYS-091`（蓝色大肥鱼 2026-10-21 决定） |
| 権限なし | HTTP 403／`3001` |

## 4. 内部 API（モジュール間公開 Service）

| サービス（概念名） | メソッド | 提供内容 | 利用元 |
|---|---|---|---|
| `NumberingService` | `next(ruleCode): String` | 採番 | 全業務域 |
| `PermissionService` | `hasPermission(userId, code): boolean` / `getPermissions(userId): Set<String>` | 認可判定 | 共通インターセプタ |
| `DataScopeService` | `resolve(userId, resourceCode): DataScope`（部門/本人＋**工場 `factoryIds`・倉庫 `warehouseIds`** を返す） | データ範囲解決 | MyBatis インターセプタ |
| `OrganizationService` | `getDepartmentPath(id)` / `getManager(deptId)` / `getPositionLevel(userId)` | 組織参照 | WF、各域 |
| `NotificationService` | `send(scene, receivers, vars)` | 通知送信 | WF、バッチ |
| `AuditService` | `record(AuditEvent)` | 監査ログ記録 | 共通 AOP |
| `AttachmentService` | `getMeta(id)` / `bind(bizType, bizId, attachmentId)` | 添付参照 | 各域 |

> 内部 Service は同一プロセスの公開インタフェース（[跨域流程](../00-common/09-cross-domain-flow.md) 2.1）。REST は提供しない。

## 5. 改訂履歴

| 版数 | 日付 | 変更内容 | 変更者 |
|---|---|---|---|
| v1.0 | 2026-10-20 | 初版：本域固有エラーコード 19、API 一覧 113、主要 API 詳細 6、内部 Service 7 | system-workflow |
| v1.1 | 2026-10-20 | Lead 裁决反映：工厂主データを MDM へ移管したため、`/api/system/factories` 3 API を「工厂組織設定（MDM 参照）」に変更 | system-workflow |
| v1.2 | 2026-10-20 | 红队第 2 轮修复：データ範囲 API に工場/倉庫次元（`factoryIds`/`warehouseIds`、scopeType 1〜7）を追加。ユーザ再開 API の権限を `system:user:reopen` に変更 | system-workflow |
| v1.3 | 2026-10-21 | API 47a `POST /api/system/companies`（公司登録）を追加：`sys_company` INSERT と同一トランザクションで 90 §3.15 業務パラメータの既定行を当該会社（`company_id` = 新 `sys_company.id`）に冪等投入、全 114 API。権限は新設 `system:company:create`（テナント開設級操作、`update` と分離）。1001 は汎用入力検証のみ、公司代码・信用代码重複は新設 `10035`／`MSG-SYS-093`（409）（蓝色大肥鱼 2026-10-21 決定） | 业务分析 |
| v1.4 | 2026-10-21 | API 47a：会社登録と同一トランザクションで `SYSTEM_ADMIN` ロール（会社ごと 1 件）と `permission_code` を持つ全 `sys_menu` 行の付与を冪等投入（94 §2.10）（蓝色大肥鱼 2026-10-21 決定） | 业务分析 |
| v1.5 | 2026-10-21 | API 1 の `permissions[]` はコードで重複排除。API 47a は同一 TX で `sys_init_company` を呼ぶ（蓝色大肥鱼 2026-10-21 決定） | 业务分析 |
| v1.6 | 2026-10-21 | API #36a `GET /api/system/departments/options`（部門選択用一覧、§3.7）を追加：当前会社は LoginContext（`companyId` 無視）、有効・未削除のみ、`id`（文字列）/`departmentCode`/`departmentName`、`sort_no`→`department_code` 順、権限はログインのみ（§1.2 `/options` 共通規則を新設：複数業務画面共有のマスタ・基礎データ選択に限る。管理画面専用の #108 は `system:maintenance:view` を維持）（バックエンド PR #61、蓝色大肥鱼 2026-10-21 決定：パスは `/api/system/**` 配下） | 业务分析 |
| v1.7 | 2026-10-21 | #2 login に必須 `tenantCode` 追加・エラー 2005 追加、#3 logout を公開・冪等に、§3.1 `menus[]` 項目確定・`dataScopes` 別 PR（蓝色大肥鱼 2026-10-21 #71 決定） | 业务分析 |
| v1.8 | 2026-10-21 | §1.1：MSG-SYS-001 を 10001 から新番 10900 に変更（10001 は 03 §6.1 のユーザ重複）、パスワード強度不足に 10005（MSG-COM-026）を新設。#2 login・#5 password のエラーコード列を更新（蓝色大肥鱼 2026-10-21 16:15/16:16 決定） | 业务分析 |
| v1.9 | 2026-10-21 | §1.1：10001（ユーザ重複）のメッセージ ID を MSG-SYS-095 に割当（蓝色大肥鱼 2026-10-21 決定） | 业务分析 |
| v1.10 | 2026-10-21 | §1.1：10001 のメッセージ ID を MSG-COM-050 に（v1.9 の MSG-SYS-095 を撤回）、10035 を 409 → 422。#2 login：プロトコル層エラーは 400 を注記（蓝色大肥鱼 2026-10-21 16:24 決定） | 业务分析 |
| v1.11 | 2026-10-21 | HTTP 409 を `version` 競合（4003）専用とし、状態不整合（4002）・二重処理/処理中（4005）・同時実行・確定済変更不可・二重実行等の 409 も 422 に統一し、409 は `version` 競合（4003）のみとする（蓝色大肥鱼 2026-10-21 決定）。対象：:37、:43 | 业务分析 |
| v1.12 | 2026-10-21 | #2 login・`/auth/me` の `menus[]` に `menuName`（`sys_menu.menu_name`）を追加し 7 項目に（01-auth-login v1.9 と同期、蓝色大肥鱼 2026-10-21 決定）。対象：:199 | 业务分析 |
| v1.13 | 2026-10-21 | #2 login・`/auth/me` の `menus[]` に `isVisible`（`sys_menu.is_visible`）を追加し 8 項目に。`is_visible` では絞り込まない。外部リンク（`menu_type=4`）も `menus[]` に含め、`routePath` に外部リンク URL を格納する。フロントはクリック時に新しいタブで開き、ルートは生成せず権限による遮断も行わない（専用 URL 項目は将来必要になった時点で別途追加）（01-auth-login v1.10 と同期、蓝色大肥鱼 2026-10-21 決定）。対象：:199 | 业务分析 |
| v1.14 | 2026-10-21 | §3.8 を追加：#47a 公司登録の成功レスポンス（HTTP 201、`data = {id, companyCode, companyName, version}`）、`10035` は `uk_sys_company_code`／`uk_sys_company_credit` 違反のみ、重複は 422（v1.3 の 409 は v1.10 で 422 に変更済み）を明記（バックエンド PR #89 に整合） | 业务分析 |
| v1.15 | 2026-10-21 | §1.1 に `5000`／MSG-SYS-091（監査ログ書込み失敗、HTTP 500、全体ロールバック）を追加。§3.8 公司登録に入力値の個別エラー（088／089、`taxPayerType` は 089）と監査ログ（`company_id`＝操作者セッション会社、新会社は `resource_id`、失敗時 500／5000／MSG-SYS-091）を追記（蓝色大肥鱼 2026-10-21 决定） | 业务分析 |
