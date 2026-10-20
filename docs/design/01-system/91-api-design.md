# 系统管理 API 设计书（系统管理 API 設計書）

| 項目 | 内容 |
|---|---|
| 文書名 | 系统管理 API 设计书（系统管理 API 設計書） |
| 文書番号 | DSN-SYS-091 |
| 版数 | v1.0 |
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
| 10001 | MSG-SYS-001 | アカウント停用/退職 | 422 |
| 10002 | MSG-SYS-002 | 内置アカウント操作不可 | 422 |
| 10003 | MSG-SYS-003〜007 | パスワード変更エラー | 400/422 |
| 10010 | MSG-SYS-012 | SoD 競合（理由必須） | 422 |
| 10011 | MSG-SYS-011 | 自己付与禁止 | 422 |
| 10020 | MSG-SYS-017 | ロール削除不可（付与中） | 422 |
| 10030 | MSG-SYS-032 | 部門循環参照 | 422 |
| 10031 | MSG-SYS-031 | 部門無効化不可（使用中） | 422 |
| 10040 | MSG-SYS-040 | 内置辞書/パラメータ | 422 |
| 10041 | MSG-SYS-044 | パラメータ型不一致 | 400 |
| 10050 | MSG-SYS-050 | 採番ルールなし | 422 |
| 10052 | MSG-SYS-052 | 採番ロックタイムアウト | 409 |
| 10055 | MSG-SYS-055 | 採番桁数短縮不可 | 422 |
| 10060 | MSG-SYS-070 | ファイル保存/読取失敗 | 500 |
| 10061 | MSG-SYS-071 | 添付上限超過 | 422 |
| 10070 | MSG-SYS-060 | 監査期間超過 | 400 |
| 10080 | MSG-SYS-080 | 帳票生成失敗 | 500 |
| 10090 | MSG-SYS-086 | 初期化二重実行 | 409 |

## 2. API 一覧

| # | メソッド | パス | 権限 | 概要 | 関連機能 | 主なエラー |
|---|---|---|---|---|---|---|
| 1 | GET | /api/system/auth/captchas | 公開 | 検証コード発行 | F-SYS-001 | 503 |
| 2 | POST | /api/system/auth/login | 公開 | ログイン | F-SYS-001 | 2002/2003/10001 |
| 3 | POST | /api/system/auth/logout | 認証済 | ログアウト | F-SYS-001 | 2001 |
| 4 | GET | /api/system/auth/me | 認証済 | ログインユーザ・権限・メニュー | F-SYS-001/003/004 | 2001 |
| 5 | POST | /api/system/auth/password | 認証済 | パスワード変更 | F-SYS-001 | 10003 |
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

> 全 113 API。リクエスト/レスポンスの詳細は各機能文書（01〜07）の第 7 章を正とし、本章は横断一覧と固有エラーコードを定義する。

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
| username | string | ○ | ログインアカウント（工号） |
| password | string | ○ | パスワード（平文、TLS 前提） |
| captchaKey | string | △ | 検証コードキー（失敗 3 回以上で必須） |
| captcha | string | △ | 検証コード（4 桁英数） |
| rememberMe | boolean | — | アカウント記憶 |

レスポンス項目：`token` / `tokenName` / `expiresIn` / `passwordResetRequired` / `userInfo{id,userCode,realName,departmentName,avatarUrl}` / `roles[{roleCode,roleName}]` / `permissions[]` / `menus[]` / `dataScopes`。

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