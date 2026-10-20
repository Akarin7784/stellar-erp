# 工作流 样例数据说明（工作流 サンプルデータ説明）

| 項目 | 内容 |
|---|---|
| 文書名 | 工作流 样例数据说明（工作流 サンプルデータ説明） |
| 文書番号 | DSN-WF-094 |
| 版数 | v1.1 |
| 作成日 | 2026-10-20 |
| 作成者 | system-workflow（域設計担当） |
| 承認者 | 未承認（レビュー待ち） |
| 状態 | ドラフト（レビュー中） |
| 関連文書 | [業務域概要](00-overview.md) / [DB 設計](90-db-design.md) / [流程模型](01-process-model.md) / [承認マトリクス](../90-data/approval-matrix.md) / [示例企業](../90-data/demo-company.md) / [コード一覧](../00-common/06-code-list.md) |

---

## 1. 本域で使用する実データと出典

| 分類 | データ | 内容・出典 | 使用箇所 |
|---|---|---|---|
| 参照先（**正**） | 承認対象・金額閾値・承認経路・方式・流程 key | [approval-matrix.md](../90-data/approval-matrix.md)（DSN-DAT-002、data-researcher 作成）— A01〜A20、`APR-*`、`ROLE-*` | `wf_approval_matrix` / `wf_process_mapping` の初期値 |
| 参照先（**正**） | 組織・部門・工場・ロール | [demo-company.md](../90-data/demo-company.md)（DSN-DAT-001）§2 | 承認者解決（部門長・ロール） |
| 参照先 | ユーザ・部門・ロールの初期データ | [01-system/94-sample-data.md](../01-system/94-sample-data.md)（SYS 域） | `wf_task.assignee_id` 等の参照 |
| 【実データ】 | BPMN 2.0 仕様 | OMG BPMN 2.0（Business Process Model and Notation, OMG 公式仕様） | BPMN ファイルの構文 |
| 【実データ】 | Flowable 8.0.0 | Flowable 公式ドキュメント（UserTask・ExecutionListener API） | エンジン連携 |
| 【実データ】 | 従業員数・組織規模 | [demo-company.md](../90-data/demo-company.md) の【示例値】（約 900 名） | 承認者負荷の見積 |
| 【実データ】 | 承認時間基準 24h/48h | [共通業務規則](../00-common/08-common-business-rules.md) 8.2（社内規程・設計値） | `wf_timeout_rule` 初期値 |

> **整合方針**：本域の初期データは [approval-matrix.md](../90-data/approval-matrix.md) を**正本**として投入する。同文件と本 94 が不一致の場合は approval-matrix.md を優先し、本文件を修正する（テーブル名は Lead 裁决 2026-10-20 により `wf_approval_matrix`（WF 所有）で統一済み）。

## 2. 初期データ（プロセス定義・業務類型・マッピング）

### 2.1 プロセス定義（wf_process_definition_ext、初期 25 件）

流程定義キーは [approval-matrix.md](../90-data/approval-matrix.md) 2 章の「流程 key（WF 実装）」を正とし、シナリオ（金額・折扣・与信超過）単位で BPMN をデプロイする。BPMN ファイルは `docs/design/90-data/bpmn/{proc_def_key}.bpmn20.xml` に配置予定。

| proc_def_key | process_name | category | approval-matrix 対応 | 分類 |
|---|---|---|---|---|
| `APR-PR-L1` | 采购申请审批（5,000 未満） | purchase | A01 | 【示例値】 |
| `APR-PR-L2` | 采购申请审批（5,000〜50,000） | purchase | A02 | 【示例値】 |
| `APR-PR-L3` | 采购申请审批（50,000〜500,000） | purchase | A03 | 【示例値】 |
| `APR-PR-L4` | 采购申请审批（500,000 以上） | purchase | A04 | 【示例値】 |
| `APR-PO-L1`〜`APR-PO-L4` | 采购订单审批（金額阶梯） | purchase | A05 | 【示例値】 |
| `APR-SO-L1` | 销售订单审批（標準価格 ±5% 以内） | sales | A06 | 【示例値】 |
| `APR-SO-L2` | 销售订单审批（折扣 5〜10%） | sales | A07 | 【示例値】 |
| `APR-SO-L3` | 销售订单审批（折扣 >10%／与信超過） | sales | A08 | 【示例値】 |
| `APR-PRT` | 采购退货审批 | purchase | A09 | 【示例値】 |
| `APR-SRT` | 销售退货审批 | sales | A10 | 【示例値】 |
| `APR-PA-L1`〜`APR-PA-L3` | 付款申请审批（金額阶梯） | finance | A11〜A13 | 【示例値】 |
| `APR-EXP-L1` | 费用报销审批（5,000 未満） | finance | A14 | 【示例値】 |
| `APR-EXP-L2` | 费用报销审批（5,000 以上） | finance | A15 | 【示例値】 |
| `APR-MDM` | 主数据变更审批 | master | A16 | 【示例値】 |
| `APR-STKADJ-L1`〜`APR-STKADJ-L2` | 盘盈盘亏审批 | inventory | A17〜A18 | 【示例値】 |
| `APR-PRC` | 价目表・特别价格变更审批 | master | A19 | 【示例値】 |
| `APR-CR` | 信用额度变更审批 | master | A20 | 【示例値】 |
| `SYS_USER_CHANGE` | ユーザ/権限変更审批 | system | —（[SYS](../01-system/00-overview.md) 追加要件） | 【示例値】 |
| `WF_DELEGATION` | 高権限代理审批 | system | —（F-WF-007） | 【示例値】 |

> 合計 25 プロセス定義（APR-* 23 + SYS 系 2）。`proc_def_key` は BPMN の `process id` と一致させる（[01-process-model.md](01-process-model.md) 4.3 画面項目定義 No.1）。

### 2.2 業務類型（wf_business_type、初期 12 件）

| business_type | business_name | module | business_no_field | owner_domain | 対応 approval_code | 分類 |
|---|---|---|---|---|---|---|
| `PURCHASE_REQUISITION` | 采购申请 | purchase | `requisitionNo` | PUR | `APR-PR` | 【示例値】 |
| `PURCHASE_ORDER` | 采购订单 | purchase | `purchaseOrderNo` | PUR | `APR-PO` | 【示例値】 |
| `PURCHASE_RETURN` | 采购退货 | purchase | `returnNo` | PUR | `APR-PRT` | 【示例値】 |
| `SALES_ORDER` | 销售订单 | sales | `salesOrderNo` | SAL | `APR-SO` | 【示例値】 |
| `SALES_RETURN` | 销售退货 | sales | `returnNo` | SAL | `APR-SRT` | 【示例値】 |
| `PAYMENT_REQUEST` | 付款申请 | finance | `paymentRequestNo` | FIN | `APR-PA` | 【示例値】 |
| `EXPENSE_CLAIM` | 费用报销 | finance | `claimNo` | FIN | `APR-EXP` | 【示例値】 |
| `MASTER_DATA_CHANGE` | 主数据变更 | mdm | `changeNo` | MDM | `APR-MDM`/`APR-PRC`/`APR-CR` | 【示例値】 |
| `INVENTORY_COUNT` | 盘盈盘亏 | inventory | `countNo` | INV | `APR-STKADJ` | 【示例値】 |
| `WORK_ORDER` | 生产工单 | production | `workOrderNo` | PRD | —（[PRD 域](../06-production/00-overview.md) 定義） | 【示例値】 |
| `SYS_USER_CHANGE` | 用户/权限变更 | system | `requestNo` | SYS | — | 【示例値】 |
| `WF_DELEGATION` | 高权限代理 | system | `delegationNo` | WF | — | 【示例値】 |

### 2.3 マッピング（wf_process_mapping、初期 30 件）

`condition_json` は [approval-matrix.md](../90-data/approval-matrix.md) 2 章の条件（金額・折扣率・与信超過フラグ）を式化したもので、`priority` 昇順で最初に成立した行を採用する。条件なし行（フォールバック）は各業務類型に 1 件必須。

| mapping_code | business_type | proc_def_key | 条件（要約） | priority | 分類 |
|---|---|---|---|---|---|
| `PR_A01` | PURCHASE_REQUISITION | `APR-PR-L1` | `amount < 5000` | 10 | 【示例値】 |
| `PR_A02` | PURCHASE_REQUISITION | `APR-PR-L2` | `5000 <= amount < 50000` | 20 | 【示例値】 |
| `PR_A03` | PURCHASE_REQUISITION | `APR-PR-L3` | `50000 <= amount < 500000` | 30 | 【示例値】 |
| `PR_A04` | PURCHASE_REQUISITION | `APR-PR-L4` | `amount >= 500000` | 40 | 【示例値】 |
| `PO_A05` | PURCHASE_ORDER | `APR-PO-L{n}` | PR 承認済は短縮（`prApproved=true`） | 10 | 【示例値】 |
| `SO_A06` | SALES_ORDER | `APR-SO-L1` | `discountRate <= 0.05 && !creditExceeded` | 10 | 【示例値】 |
| `SO_A07` | SALES_ORDER | `APR-SO-L2` | `0.05 < discountRate <= 0.10 && !creditExceeded` | 20 | 【示例値】 |
| `SO_A08` | SALES_ORDER | `APR-SO-L3` | `discountRate > 0.10 || creditExceeded` | 5（最優先） | 【示例値】 |
| `PRT_A09` | PURCHASE_RETURN | `APR-PRT` | なし（フォールバック） | 100 | 【示例値】 |
| `SRT_A10` | SALES_RETURN | `APR-SRT` | なし | 100 | 【示例値】 |
| `PA_A11`〜`PA_A13` | PAYMENT_REQUEST | `APR-PA-L{n}` | 金額阶梯 | 10〜30 | 【示例値】 |
| `EXP_A14`/`EXP_A15` | EXPENSE_CLAIM | `APR-EXP-L{n}` | 金額阶梯 | 10/20 | 【示例値】 |
| `MDM_A16` | MASTER_DATA_CHANGE | `APR-MDM` | 银行口座・価格・与信の重要変更 | 10 | 【示例値】 |
| `MDM_A19`/`MDM_A20` | MASTER_DATA_CHANGE | `APR-PRC`/`APR-CR` | 価格表／与信限度の変更 | 20/30 | 【示例値】 |
| `STKADJ_A17/A18` | INVENTORY_COUNT | `APR-STKADJ-L{n}` | 金額阶梯 | 10/20 | 【示例値】 |
| `WO_STANDARD` | WORK_ORDER | `WORK_ORDER` | なし | 100 | 【示例値】 |
| `SYS_USER_STANDARD` | SYS_USER_CHANGE | `SYS_USER_CHANGE` | なし | 100 | 【示例値】 |
| `WF_DELEGATION_STANDARD` | WF_DELEGATION | `WF_DELEGATION` | 高権限委任のみ | 100 | 【示例値】 |

### 2.4 承認マトリクス（wf_approval_matrix、初期 20 件）

`matrix_code` は [approval-matrix.md](../90-data/approval-matrix.md) 2 章の **シナリオコード A01〜A20** を正とし、金額は同表の閾値（税込・CNY）を投入する。`wf_approval_matrix_line` の承認者は `approver_type`（1 ロール / 2 ユーザ / 3 職位 / 4 直属上長 / 5 部門長 / 6 変数）で参照し、ロールは `ROLE-*` コード（[demo-company.md](../90-data/demo-company.md) 2.1 の職位と対応）を使用する。

| matrix_code | business_type | 金額範囲（税込） | 承認経路（role） | 方式 | approval-matrix 対応 |
|---|---|---|---|---|---|
| `A01` | PURCHASE_REQUISITION | < 5,000 | `ROLE-DEPT-MGR` | OR | A01 |
| `A02` | PURCHASE_REQUISITION | 5,000〜50,000 | `ROLE-DEPT-MGR` → `ROLE-PUR-MGR` | SEQ | A02 |
| `A03` | PURCHASE_REQUISITION | 50,000〜500,000 | `ROLE-DEPT-MGR` → `ROLE-PUR-MGR` → `ROLE-VP` | SEQ | A03 |
| `A04` | PURCHASE_REQUISITION | ≥ 500,000 | 上記 + `ROLE-GM` | SEQ | A04 |
| `A06` | SALES_ORDER | 標準価格 ±5% 以内 | `ROLE-SAL-MGR` | OR | A06 |
| `A07` | SALES_ORDER | 折扣 5〜10% | `ROLE-SAL-DIR` | OR | A07 |
| `A08` | SALES_ORDER | 折扣 >10%／与信超過 | `ROLE-SAL-DIR` → `ROLE-FIN-DIR` → `ROLE-GM` | SEQ | A08 |
| `A09`～`A20` | 各業務類型 | 同 approval-matrix.md 表 | 同表の `approval_path` | OR/SEQ | A09〜A20 |

> `wf_approval_matrix_line` の初期行数は約 50（20 マトリクス × 平均 2.5 ノード）。`sign_type` は approval-matrix.md 4 章の `OR`/`SEQ`/`AND` を 1/3/2 にマップする。

### 2.5 超時規則（wf_timeout_rule、初期 3 件）

| rule_code | 対象 | reminder | escalate | escalate_to | auto_approve | 分類 |
|---|---|---|---|---|---|---|
| `DEFAULT_APPROVAL` | 全業務・全ノード | 24h | 48h | 直属上長 | false | 【示例値】社内規程 |
| `FINANCE_STRICT` | finance モジュール | 12h | 24h | `ROLE-FIN-DIR` | false | 【示例値】 |
| `PURCHASE_NORMAL` | purchase モジュール | 24h | 48h | `ROLE-VP` | false | 【示例値】 |

> 自動承認は初期状態で全件 OFF（approval-matrix.md 5 章「タイムアウト自動承認しない」に一致）。有効化する場合も `sys_param: workflow.auto-approve-enabled=true` と金額上限を設定する（[03-approval-admin.md](03-approval-admin.md) BR-08）。

## 3. サンプルシナリオ（設計検証用）

### 3.1 采购申请 12,000 元（示例値）— approval-matrix.md T02 系

```
1. 王强（采购部 D020）が采购申请 PR2610200001（CNY 12,000.00）を提出
2. mapping PR_A02（5,000〜50,000）→ proc_def_key APR-PR-L2 → matrix A02
3. 承認ノード：ROLE-DEPT-MGR（或签）→ ROLE-PUR-MGR（顺送）
4. 部門经理承認 → 采购经理へ通知・待办
5. 采购经理の最終承認 → プロセス完了、E31/E32 発行
6. PUR 域が PR ステータス 20 → 25 に更新、後続の発注処理へ
```

### 3.2 折扣 12% の受注（示例値）— approval-matrix.md T06

```
1. 销售员が受注 SO2610200001 を提出（discountRate=0.12）
2. mapping SO_A08（最優先）→ proc_def_key APR-SO-L3 → matrix A08
3. 销售总监 → 财务总监 → 总经理 の順送。途中承認ごとに E31、最終で E32
4. 与信超過フラグも同時に成立する場合は A08 を適用（approval-matrix.md 5 章 4 項）
```

### 3.3 タイムアウト・エスカレーション（示例値）

```
1. タスク生成（2026-10-20 14:30、期限 2026-10-21 14:30）
2. 24h 経過 → BAT-WF-001 がリマインダ通知
3. 48h 経過 → BAT-WF-002 が直属上長（ROLE-* / 上長）へエスカレーション + 動的代理権付与
4. 自動承認 OFF のため、承認者・上位者のいずれかが処理
```

## 4. 仮定値の一覧

| # | 仮定値 | 値 | 根拠・備考 |
|---|---|---|---|
| 1 | プロセス定義数 | 25（APR-* 23 + SYS 系 2） | approval-matrix.md A01〜A20 のシナリオ数 |
| 2 | 承認マトリクス数 | 20 | approval-matrix.md A01〜A20 |
| 3 | 承認者数 | 1 ノードあたり 1〜3 名 | demo-company.md の組織規模 |
| 4 | タイムアウト | 24h/48h | 共通業務規則 8.2 |
| 5 | 年間プロセス数 | 30 万件 | 伝票件数（[README](../README.md) の規模）から試算 |
| 6 | 承認リードタイム目標 | 8h（<50 万円）/ 24h（以上） | 社内目標（示例値） |

## 5. 未決事項

| # | 事項 | 理由 | 暫定仕様 | 担当 | 期限 |
|---|---|---|---|---|---|
| 1 | 承認マトリクステーブル名（**已裁决**） | 各域・00-common・90-data で `sys_approval_matrix` / `wf_approval_matrix` の記載が混在していた | **已裁决：`wf_approval_matrix`（WF 所有）に統一**。Lead が 00-common/08・09 と全 docs/90-data を置換済み | Lead | 完了（2026-10-20） |
| 2 | 流程 key の最終命名（**已裁决**） | approval-matrix.md は `APR-*`、本設計の業務類型は `*_ORDER` 等 | **已裁决：`APR-*` を `proc_def_key` の正とし、業務類型→`wf_process_mapping` で解決**（本 94 の通り） | Lead / system-workflow | 完了（2026-10-20） |
| 3 | 承認待ち中の金額変更（閾値跨ぎ）の扱い（**已裁决**） | approval-matrix.md T10 は「経路再評価・再承認」、本設計は「承認中の編集禁止（差戻し→再提出）」 | **已裁决：Phase 1 は承認中編集禁止→差戻し→再提出。Phase 2 で経路再評価を検討**（90-data 側は mdm-designer が修正、WF 側は本設計どおり） | Lead / mdm-designer | 完了（2026-10-20） |
| 4 | BPMN ファイルの配置場所と命名規則 | 90-data のディレクトリ構成未確定 | `docs/design/90-data/bpmn/{proc_def_key}.bpmn20.xml` を提案 | Lead / data-researcher | 2026-10-31 |
| 5 | ロールコードの全件確定 | approval-matrix.md は `ROLE-*` 10 件、08 §9.1 はロール名 16 件。マッピングが必要 | SYS の `sys_role.role_code` を `ROLE-*` に統一し、08 §9.1 と対応表を作成 | system-workflow / data-researcher | 2026-10-31 |

## 6. 改訂履歴

| 版数 | 日付 | 変更内容 | 変更者 |
|---|---|---|---|
| v1.0 | 2026-10-20 | 初版：実データと出典、初期データ（定義 12・業務類型 12・マッピング 20・マトリクス 18・超時 3）、サンプルシナリオ 3、仮定値 6、未決 3 | system-workflow |
| v1.1 | 2026-10-20 | 90-data/approval-matrix.md と整合：流程 key を `APR-*`、マトリクスコードを A01〜A20、ロールコードを `ROLE-*`、業務類型に approval_code 対応を追加。未決を 5 件に更新 | system-workflow |
| v1.2 | 2026-10-20 | Lead 裁决反映：承認マトリクス表名 `wf_approval_matrix`・流程キー `APR-*`・T10（承認中金額変更）を已裁决に更新 | system-workflow |