# 工作流 API 设计书（工作流 API 設計書）

| 項目 | 内容 |
|---|---|
| 文書名 | 工作流 API 设计书（工作流 API 設計書） |
| 文書番号 | DSN-WF-091 |
| 版数 | v1.0 |
| 作成日 | 2026-10-20 |
| 作成者 | system-workflow（域設計担当） |
| 承認者 | 未承認（レビュー待ち） |
| 状態 | ドラフト（レビュー中） |
| 関連文書 | [業務域概要](00-overview.md) / [API 共通規格](../00-common/03-common-api-spec.md) / [跨域流程](../00-common/09-cross-domain-flow.md) / [メッセージ](93-messages.md) |

---

## 1. 適用範囲と共通仕様

本域 API は `/api/workflow/**` に配置する。認証（Sa-Token）、`Result<T>`、`PageResult<T>`、冪等（`Idempotency-Key`）、楽観排他（`version`）は [API 共通規格](../00-common/03-common-api-spec.md) に従う。承認操作は「状態操作 API」として `POST /api/workflow/tasks/{taskId}/{action}` 形式を使用する。

### 1.1 業務エラーコード（WF 領域：80000-89999）

| コード | メッセージ ID | 内容 | HTTP |
|---|---|---|---|
| 80001 | MSG-WF-001 | BPMN パース失敗 | 400 |
| 80002 | MSG-WF-002 | userTask なし | 422 |
| 80003 | MSG-WF-003 | マッピングなし | 422 |
| 80004 | MSG-WF-004 | マトリクス該当なし | 422 |
| 80005 | MSG-WF-005 | 承認者 0 名 | 422 |
| 80006 | MSG-WF-006 | 進行中定義の削除 | 422 |
| 80010 | MSG-WF-010 | 承認ノード 0 行 | 400 |
| 80015 | MSG-WF-015 | 他者タスク/処理済み | 403/422 |
| 80016 | MSG-WF-016 | 驳回・差戻し理由なし | 400 |
| 80017 | MSG-WF-017 | 加签対象不正 | 422 |
| 80018 | MSG-WF-018 | 转办対象不正 | 422 |
| 80019 | MSG-WF-019 | 催办レート超過 | 429 |
| 80021 | MSG-WF-021 | 撤回不可（承認済あり） | 422 |
| 80031 | MSG-WF-031 | 挂起中 | 422 |
| 80041 | MSG-WF-041 | 代理設定不正 | 422 |
| 80046 | MSG-WF-046 | 自動承認設定不備 | 422 |
| 80047 | MSG-WF-047 | 財務フロー自動承認不可 | 422 |
| 80052 | MSG-WF-052 | 条件 JSON 不正 | 400 |
| 80062 | MSG-WF-062 | 財務必須項目の非表示 | 422 |
| 80073 | MSG-WF-073 | 二重提出 | 422 |

## 2. API 一覧

| # | メソッド | パス | 権限 | 概要 | 機能 | 主なエラー |
|---|---|---|---|---|---|---|
| 1 | GET | /api/workflow/process-definitions | `workflow:process:view` | 流程定義一覧 | F-WF-001 | 3001 |
| 2 | GET | /api/workflow/process-definitions/{id} | `workflow:process:view` | 定義詳細 | F-WF-001 | 4001 |
| 3 | POST | /api/workflow/process-definitions/deploy | `workflow:process:deploy` | BPMN デプロイ | F-WF-001 | 80001/80002 |
| 4 | PUT | /api/workflow/process-definitions/{id} | `workflow:process:update` | 定義属性更新 | F-WF-001 | 4003 |
| 5 | PUT | /api/workflow/process-definitions/{id}/active | `workflow:process:update` | 有効/無効 | F-WF-001 | 4001 |
| 6 | PUT | /api/workflow/process-definitions/{id}/default | `workflow:process:update` | 既定版切替 | F-WF-001 | 80006 |
| 7 | GET | /api/workflow/process-definitions/{id}/diagram | `workflow:process:view` | 経路 SVG | F-WF-001 | 4001 |
| 8 | DELETE | /api/workflow/process-definitions/{id} | `workflow:process:update` | 定義廃止 | F-WF-001 | 80006 |
| 9 | GET | /api/workflow/business-types | `workflow:mapping:view` | 業務類型一覧 | F-WF-002 | 3001 |
| 10 | POST | /api/workflow/business-types | `workflow:mapping:update` | 業務類型登録 | F-WF-002 | 1005 |
| 11 | GET | /api/workflow/process-mappings | `workflow:mapping:view` | マッピング一覧 | F-WF-002 | 3001 |
| 12 | POST | /api/workflow/process-mappings | `workflow:mapping:update` | マッピング登録 | F-WF-002 | 80052 |
| 13 | PUT | /api/workflow/process-mappings/{id} | `workflow:mapping:update` | マッピング更新 | F-WF-002 | 4003/80052 |
| 14 | DELETE | /api/workflow/process-mappings/{id} | `workflow:mapping:update` | マッピング削除 | F-WF-002 | 4002 |
| 15 | GET | /api/workflow/approval-matrices | `workflow:mapping:view` | マトリクス一覧 | F-WF-002 | 3001 |
| 16 | GET | /api/workflow/approval-matrices/{id} | `workflow:mapping:view` | マトリクス詳細 | F-WF-002 | 4001 |
| 17 | POST | /api/workflow/approval-matrices | `workflow:mapping:update` | マトリクス登録 | F-WF-002 | 80010 |
| 18 | PUT | /api/workflow/approval-matrices/{id} | `workflow:mapping:update` | マトリクス更新 | F-WF-002 | 4003 |
| 19 | DELETE | /api/workflow/approval-matrices/{id} | `workflow:mapping:update` | マトリクス削除 | F-WF-002 | 4002 |
| 20 | POST | /api/workflow/approval-matrices/validate | `workflow:mapping:update` | 承認者解決チェック | F-WF-002 | 80005 |
| 21 | GET | /api/workflow/field-permissions | `workflow:field-permission:update` | フィールド権限一覧 | F-WF-010 | 3001 |
| 22 | PUT | /api/workflow/field-permissions | `workflow:field-permission:update` | フィールド権限保存 | F-WF-010 | 80062 |
| 23 | POST | /api/workflow/business-processes | `workflow:instance:submit` | 提出（開始） | F-WF-003 | 80003/80004/80005/80073 |
| 24 | POST | /api/workflow/business-processes/preview | `workflow:instance:submit` | 提出プレビュー | F-WF-003 | 80003/80004 |
| 25 | GET | /api/workflow/business-processes/{bizType}/{bizId} | `workflow:task:view` | 承認状態参照 | F-WF-003 | 4001 |
| 26 | GET | /api/workflow/business-processes | `workflow:task:view` | 我发起的 | F-WF-004 | 3001 |
| 27 | POST | /api/workflow/business-processes/{id}/withdraw | `workflow:task:withdraw` | 撤回 | F-WF-003/005 | 80021 |
| 28 | GET | /api/workflow/business-processes/{id}/history | `workflow:task:view` | 承認履歴 | F-WF-006 | 4001 |
| 29 | GET | /api/workflow/business-processes/{id}/diagram | `workflow:task:view` | 経路図 | F-WF-006 | 4001 |
| 30 | GET | /api/workflow/tasks/todo | `workflow:task:view` | 待办一覧 | F-WF-004 | 3001 |
| 31 | GET | /api/workflow/tasks/done | `workflow:task:view` | 已办一覧 | F-WF-004 | 3001 |
| 32 | GET | /api/workflow/tasks/{taskId} | `workflow:task:view` | 承認画面情報 | F-WF-005 | 80015 |
| 33 | POST | /api/workflow/tasks/{taskId}/approve | `workflow:task:approve` | 同意 | F-WF-005 | 80015/80031 |
| 34 | POST | /api/workflow/tasks/{taskId}/reject | `workflow:task:reject` | 驳回 | F-WF-005 | 80016 |
| 35 | POST | /api/workflow/tasks/{taskId}/return | `workflow:task:reject` | 差戻し | F-WF-005 | 80016 |
| 36 | POST | /api/workflow/tasks/{taskId}/add-sign | `workflow:task:add-sign` | 加签 | F-WF-005 | 80017 |
| 37 | POST | /api/workflow/tasks/{taskId}/transfer | `workflow:task:transfer` | 转办 | F-WF-005 | 80018 |
| 38 | POST | /api/workflow/tasks/{taskId}/urge | `workflow:task:urge` | 催办 | F-WF-005 | 80019 |
| 39 | POST | /api/workflow/tasks/batch-approve | `workflow:task:approve` | 一括承認 | F-WF-005 | 1001 |
| 40 | GET | /api/workflow/tasks/{taskId}/field-permissions | `workflow:task:view` | フィールド権限 | F-WF-010 | 4001 |
| 41 | GET | /api/workflow/ccs | `workflow:task:view` | 抄送我的 | F-WF-004 | 3001 |
| 42 | PUT | /api/workflow/ccs/{id}/read | 認証済 | 抄送既読 | F-WF-004 | 4001 |
| 43 | GET | /api/workflow/delegations | `workflow:delegation:update` | 代理設定一覧 | F-WF-007 | 3001 |
| 44 | POST | /api/workflow/delegations | `workflow:delegation:update` | 代理設定登録 | F-WF-007 | 80041 |
| 45 | DELETE | /api/workflow/delegations/{id} | `workflow:delegation:update` | 代理解除 | F-WF-007 | 4001 |
| 46 | GET | /api/workflow/delegations/effective | `workflow:task:view` | 有効代理 | F-WF-007 | — |
| 47 | GET | /api/workflow/timeout-rules | `workflow:timeout:update` | 超時規則一覧 | F-WF-008 | 3001 |
| 48 | POST | /api/workflow/timeout-rules | `workflow:timeout:update` | 超時規則登録 | F-WF-008 | 80046/80047 |
| 49 | PUT | /api/workflow/timeout-rules/{id} | `workflow:timeout:update` | 超時規則更新 | F-WF-008 | 4003 |
| 50 | DELETE | /api/workflow/timeout-rules/{id} | `workflow:timeout:update` | 超時規則削除 | F-WF-008 | 4002 |
| 51 | GET | /api/workflow/instances | `workflow:instance:view` | インスタンス一覧 | F-WF-009 | 3001 |
| 52 | GET | /api/workflow/instances/{id} | `workflow:instance:view` | インスタンス詳細 | F-WF-009 | 4001 |
| 53 | POST | /api/workflow/instances/{id}/suspend | `workflow:instance:manage` | 挂起 | F-WF-009 | 4002 |
| 54 | POST | /api/workflow/instances/{id}/resume | `workflow:instance:manage` | 再開 | F-WF-009 | 4002 |
| 55 | POST | /api/workflow/instances/{id}/terminate | `workflow:instance:manage` | 強制終了 | F-WF-009 | 80016 |
| 56 | POST | /api/workflow/instances/{id}/jump | `workflow:instance:manage` | 跳转 | F-WF-009 | 80048/80050 |
| 57 | GET | /api/workflow/monitor/summary | `workflow:monitor:view` | 監視サマリ | F-WF-006/009 | 3001 |
| 58 | GET | /api/workflow/monitor/pending-top | `workflow:monitor:view` | 滞留上位 | F-WF-009 | 3001 |
| 59 | GET | /api/workflow/dashboard/pending-count | `workflow:task:view` | 未処理件数 | F-WF-004 | — |
| 60 | POST | /api/workflow/approval-routes/resolve | 認証済（業務域内部参照） | 承認要否・経路照会（業務域→WF） | F-WF-002 | 80003/80004 |
| 61 | POST | /api/workflow/tasks/transfer-batch | `workflow:instance:manage` | タスク一括転送（ユーザ停用時の代理転送等） | F-WF-005/009 | 80018 |

> 全 61 API。リクエスト/レスポンスの詳細は各機能文書（01〜03）第 7 章を正とする。

### 2.1 経路照会 API（業務域連携）

`POST /api/workflow/approval-routes/resolve` は、業務域が伝票登録・提出前に「承認要否と経路」を照会するための API。リクエストは `{ "approvalCode": "APR-PR", "amount": "12000.00", "currencyCode": "CNY", "conditions": { "discountRate": 0, "creditExceeded": false }, "departmentId": "..." }`、レスポンスは `{ "required": true, "matchedScenario": "A02", "processKey": "APR-PR-L2", "approvalPath": ["ROLE-DEPT-MGR", "ROLE-PUR-MGR"], "approvalMode": "SEQ" }`。[approval-matrix.md](../90-data/approval-matrix.md) 6 章の業務側インタフェースに対応し、[03-common-api-spec](../00-common/03-common-api-spec.md) の REST 規約（動詞をパスに含めない）に合わせて `:resolve` ではなく `/approval-routes/resolve` を正とする。

## 3. API 詳細（主要 API）

### 3.1 POST /api/workflow/business-processes（提出）

| 項目 | 内容 |
|---|---|
| 目的 | 業務伝票の承認プロセスを開始する |
| 冪等 | `Idempotency-Key` 必須。同一業務の二重提出は 422（80073） |
| 排他 | 業務伝票単位（業務域側の楽観排他に従う） |
| 処理概要 | マッピング解決→プロセス開始→タスク生成→`wf_*` 登録→通知（[02-approval-runtime.md](02-approval-runtime.md) 6.2） |
| 関連テーブル | wf_business_process、wf_task、wf_variable、sys_outbox_event |

リクエスト項目：`businessType`(string,○)、`businessId`(string,○)、`businessNo`(string,○)、`amount`(string)、`currencyCode`(string)、`applicantId`(string,○)、`applicantDeptId`(string)、`factoryId`(string)、`summary`(string)、`variables`(object)、`formSnapshot`(object)。レスポンス：`processInstanceId`、`businessProcessId`、`firstTaskId`、`currentApprovers[]`、`processStatus`、`submitAt`。

### 3.2 POST /api/workflow/tasks/{taskId}/approve（同意）

リクエスト項目：`comment`(string,任意)、`fieldValues`(object,フィールド権限で編集可の項目のみ)、`version`(int)。レスポンス：`taskStatus`、`processStatus`、`nextApprovers[]`。エラー：80015（他者タスク/処理済み）、80031（挂起中）、4003（楽観排他）。

### 3.3 POST /api/workflow/tasks/{taskId}/reject（驳回）/ return（差戻し）

`comment`(string,○)、`returnToNode`(string,差戻しのみ任意)、`version`(int)。驳回は終端（業務 95）、差戻しは業務 10 へ戻す。

### 3.4 POST /api/workflow/tasks/{taskId}/add-sign / transfer

加签：`{ "addSignUserId": "...", "position": "BEFORE|AFTER", "comment": "..." }`。转办：`{ "transferUserId": "...", "reason": "...", "version": 0 }`。

### 3.5 GET /api/workflow/tasks/todo（待办一覧）

クエリ：`keyword`、`businessType`（複数可）、`amountFrom`/`amountTo`、`applicantId`、`dueStatus`（NORMAL/SOON/OVERDUE）、`urgency`、`sort`、`pageNum`、`pageSize`。レスポンス：`PageResult<TaskTodoDto>`。`TaskTodoDto`：`taskId`、`businessType`、`businessTypeName`、`businessNo`、`summary`、`applicantName`、`amount`、`dueAt`、`remainingHours`、`urgency`、`nodeName`。

### 3.6 POST /api/workflow/instances/{id}/terminate（強制終了）

`{ "reason": "...", "version": 3 }`。処理：Flowable 終了→`wf_task` 取消→E32 TERMINATED 発行→通知。業務域が業務ステータスを 90 に更新する。

### 3.7 イベント契約（E31/E32）

WF は業務 API に加え、Outbox 経由で次のイベントを発行する。ペイロード詳細は [02-approval-runtime.md](02-approval-runtime.md) 6.2、定義は [跨域流程](../00-common/09-cross-domain-flow.md) 第 3 章（E31/E32）を正とする。

| イベント | 発行タイミング | 購読者 | 冪等キー |
|---|---|---|---|
| `workflow.task.completed`（E31） | タスク完了（同意/驳回/差戻し/撤回/自動承認） | 各業務域 | `taskId + result`（payload）/ `eventId` |
| `workflow.process.completed`（E32） | プロセス完了（承認/却下/撤回/強制終了） | 各業務域 | `processInstanceId + finalResult` / `eventId` |

## 4. 内部 API（モジュール間公開 Service）

| サービス（概念名） | メソッド | 提供内容 | 利用元 |
|---|---|---|---|
| `WorkflowService` | `submit(request): SubmitResult` | 提出・プロセス開始 | 各業務域（提出時） |
| `WorkflowService` | `getProcessStatus(bizType, bizId): WorkflowStatus` | 現在の承認状態参照 | 各業務域（詳細画面） |
| `WorkflowService` | `cancelByBusiness(bizType, bizId, reason)` | 業務取消時のプロセス終了（管理者相当） | 各業務域（取消時） |
| `ApprovalMatrixService` | `resolve(bizType, amount, variables): List<ApprovalNode>` | 経路解決（提出プレビューでも使用） | 各業務域 |
| `TaskQueryService` | `countPending(userId): int` | 未処理件数（ヘッダバッジ） | フロント共通 |
| `DelegationService` | `resolveEffectiveApprover(userId, bizType): List<Long>` | 代理承認者の解決 | 承認 API |

## 5. 改訂履歴

| 版数 | 日付 | 変更内容 | 変更者 |
|---|---|---|---|
| v1.0 | 2026-10-20 | 初版：WF 領域エラーコード 20、API 一覧 59、主要 API 詳細 7、イベント契約、内部 Service 6 | system-workflow |
| v1.1 | 2026-10-20 | 業務域連携 API（`approval-routes/resolve`、`tasks/transfer-batch`）を追加し 61 API に更新。経路照会 API の契約を追加 | system-workflow |
| v1.2 | 2026-10-21 | HTTP 409 を `version` 競合（4003）専用とし、状態不整合（4002）・二重処理/処理中（4005）・同時実行・確定済変更不可・二重実行等の 409 も 422 に統一し、409 は `version` 競合（4003）のみとする（蓝色大肥鱼 2026-10-21 決定）。対象：:31、:43、:124 | 业务分析 |