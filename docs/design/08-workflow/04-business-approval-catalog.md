# 业务单据审批横断一览 详细设计书（業務伝票承認・状態遷移 横断一覧）

| 項目 | 内容 |
|---|---|
| 文書名 | 业务单据审批横断一览 详细设计书（業務伝票承認・状態遷移 横断一覧） |
| 文書番号 | DSN-WF-004 |
| 版数 | v1.0 |
| 作成日 | 2026-10-21 |
| 作成者 | 业务分析 |
| 承認者 | 未承認（レビュー待ち） |
| 状態 | ドラフト（レビュー中） |
| 関連文書 | [業務域概要](00-overview.md) / [承認実行設計](02-approval-runtime.md) / [サンプルデータ](94-sample-data.md) / [共通業務規則](../00-common/08-common-business-rules.md) / [跨域流程](../00-common/09-cross-domain-flow.md) / [共通 API 仕様](../00-common/03-common-api-spec.md) / [承認マトリクス](../90-data/approval-matrix.md) |

---

## 1. 目的と位置付け

- 02〜07 各域の 90（DDL）・91（API）・95（受入基準）に分散している**承認対象伝票・状態コード・状態遷移**を 1 か所に集約し、08 工作流（Flowable）接入時の対応表とする。
- 本書は**既存定義の要約・統一のみ**を行い、新しい業務ルールは定義しない。各行の正本は「出典」列の file:line とし、本書と出典が食い違う場合は出典を正とする。
- 出典同士の矛盾・未定義は §5「待確認事項」に列挙し、本書では決定しない。

## 2. 共通規定（要約）

| # | 規定 | 内容（要約） | 出典 |
|---|---|---|---|
| C-1 | 共通ステータス | 10 草稿／20 承認待ち／25 承認済／30 発行済・未実行／35 一部実行／40 完了／90 取消／95 却下 | [00-common/08 §3.1](../00-common/08-common-business-rules.md):100-111 |
| C-2 | 状態遷移の共通制約 | 不許可遷移は `MSG-COM-034`、version 付き楽観排他、25 以降の内容変更禁止、90 は後続処理なしのみ、40 からの再開禁止 | 00-common/08:132-138 |
| C-3 | 状態操作 API | `submit`（10）／`approve`・`reject`（20、却下理由必須）／`withdraw`（20、未処理タスクのみ）／`cancel`／`close`。エラーは 422、409 は `version` 競合 4003 のみ | [00-common/03 §11.1](../00-common/03-common-api-spec.md):271-290 |
| C-4 | 業務域と WF の分担 | 業務域が提出（businessType/businessId/businessNo/variables/formSnapshot）、WF は E31（タスク）・E32（プロセス完了）を発行し、**業務ステータスは業務域が更新**。コールバックは `taskId`+`result` で冪等 | [00-common/09 §9.1](../00-common/09-cross-domain-flow.md):415-438、[00 §12 #6](00-overview.md):289 |
| C-5 | WF 側の状態遷移 | 提出 10→20、最終承認 20→25、驳回 20→95、差戻し・撤回 20→10、強制終了 20→90 | [02 §2.3](02-approval-runtime.md):64-86、[00 §3.1](00-overview.md):88-108 |
| C-6 | 承認経路の正本 | 承認対象 `APR-*`・シナリオ A01〜A20・`ROLE-*` は 90-data/approval-matrix.md を正とする | [00 §2.2](00-overview.md):64-84、[90-data/approval-matrix.md](../90-data/approval-matrix.md):29-72 |
| C-7 | 業務類型（初期） | `wf_business_type` 初期 12 件（PR／PO／PRT／SO／SRT／PA／EXP／MDM 変更／盘点／WORK_ORDER／SYS 2 件） | [94 §2.2](94-sample-data.md):60-75 |

## 3. 承認対象伝票の横断一覧

凡例：`approval_status` の 20 は「待审批（承認待ち）」に統一（蓝色大肥鱼 2026-10-21 決定）。主数据（MDM）の 90 は「废止」のまま（取消ではない。MDM 側は本書で変更しない）。「WF 接続」＝ 08/94 の業務類型・流程定義への登録有無。「承認済コード」＝承認完了時に設定される値。

| 域 | 伝票（テーブル） | 状態列と定義値 | 承認済コード | 却下コード | WF 接続（業務類型／流程キー） | 出典 |
|---|---|---|---|---|---|---|
| MDM | 物料（`mdm_material`） | `approval_status` 10/20/25/95/90 | 25 | 95 | `MASTER_DATA_CHANGE`／`APR-MDM` | 02-mdm/90-db-design.md:302、94:71 |
| MDM | 客户（`mdm_customer`） | `approval_status` 10/20/25/90/95 | 25 | 95 | 同上 | 02-mdm/90-db-design.md:608 |
| MDM | 供应商（`mdm_supplier`） | `approval_status`（値の注記なし） | — | — | 同上 | 02-mdm/90-db-design.md:711 |
| MDM | 信用额度（`mdm_credit_limit`） | `approval_status`（値の注記なし） | — | — | `MASTER_DATA_CHANGE`／`APR-CR` | 02-mdm/90-db-design.md:1284 |
| MDM | 变更申请 | `status` 10/20/25/30 反映/90/95 | 25 | 95 | `MASTER_DATA_CHANGE` | 02-mdm/90-db-design.md:1378 |
| SAL | 报价（`sal_quotation`） | `quotation_status` 10/**25 承認待ち**/30/35/90/95、`approval_status` 10 不要/20/25 | 30（有効） | 95 | 未登録 | 03-sales/90-db-design.md:246-247 |
| SAL | 销售订单（`sal_sales_order`） | `order_status` 10/20/25/30/35/40/90/95 | 25 | 95 | `SALES_ORDER`／`APR-SO-L1..L3` | 03-sales/90-db-design.md:386、94:67、94:88-90 |
| SAL | 销售退货（`sal_sales_return`） | `return_status` 10/20/25/30/40/90/95 | 25 | 95 | `SALES_RETURN`／`APR-SRT` | 03-sales/90-db-design.md:798、94:68 |
| SAL | 开票申请（`sal_invoice_application`） | `application_status` 10/20/25/30/40/90/95 | 25 | 95 | 未登録 | 03-sales/90-db-design.md:935 |
| PUR | 采购申请（`pur_purchase_requisition`） | `pr_status` 10/20/25/30/35/40/90/95、`process_instance_id` | 25 | 95 | `PURCHASE_REQUISITION`／`APR-PR-L1..L4` | 04-purchase/90-db-design.md:164-168、94:64 |
| PUR | 采购订单（`pur_purchase_order`） | `po_status` 10/20/25/30/35/40/90/95、`process_instance_id` | 25 | 95 | `PURCHASE_ORDER`／`APR-PO-L1..L4` | 04-purchase/90-db-design.md:682-689、94:65 |
| PUR | 采购订单变更履歴（`pur_purchase_order_his`） | `approval_status` 10 申請中/25/95 | 25 | 95 | 未登録 | 04-purchase/90-db-design.md:869 |
| PUR | 采购退货（`pur_return`） | `return_status` 10/20/25/30/40/90/95、`process_instance_id` | 25 | 95 | `PURCHASE_RETURN`／`APR-PRT` | 04-purchase/90-db-design.md:1086-1089、94:66 |
| INV | 在庫取引（`inv_stock_txn`） | `txn_status` 10/20/25/30 過账/90 沖销 | 25 | — | 未登録 | 05-inventory/90-db-design.md:345 |
| INV | 移库（`inv_transfer`） | `approval_status` **0 不要/10 待ち/20 承認/30 却下** | 20 | 30 | 未登録 | 05-inventory/90-db-design.md:654、:671、:688 |
| INV | 盘点（`inv_stocktake`） | `take_status` 10/20/30/**35 承認待ち/40 承認済**/90 | 40 | — | `INVENTORY_COUNT`／`APR-STKADJ-L1..L2` | 05-inventory/90-db-design.md:810、94:72 |
| INV | 成本调整（`inv_cost_adjustment`） | `adjustment_status` 10/20/25/30/90 | 25 | — | 未登録 | 05-inventory/90-db-design.md:1265 |
| PRD | 生产工单（`prd_work_order`） | `order_status` 10/20/25/30/35/40/90/95 | 25 | 10（却下は草稿へ戻す（蓝色大肥鱼 2026-10-21 決定）） | `WORK_ORDER`／`prd_work_order_release` | 06-production/90-db-design.md:994、02-work-order.md:111-112、91-api-design.md:72-73、94:73、94:98 |
| PRD | 超产申请（`prd_overproduction_approval`） | `approval_status` 10/20/**30 承認済/40 却下**/90、`process_instance_id` | 30 | 40 | 未登録（「Flowable 接入後は提出を WF 起動に置換」） | 06-production/90-db-design.md:1086-1094、:1108、91-api-design.md:88 |
| PRD | 工单变更（`prd_work_order_change`） | `change_status` 10 申請中/25/95 | 25 | 95 | 未登録 | 06-production/90-db-design.md:1276 |
| PRD | 委外订单（`prd_outsourcing_order`） | `os_status` 10/20/25/30/35/40/90/95 | 25 | 95 | 未登録 | 06-production/90-db-design.md:1686 |
| PRD | NCR（`prd_ncr`） | `ncr_status` 10/20/25/30/40/90/95 | 25 | 95 | 未登録 | 06-production/90-db-design.md:2274 |
| PRD | 需要预测・MPS（`prd_demand_forecast`／`prd_mps`） | 10/20 承認待ち/30 確定/(40)/90 | 30 | — | 未登録 | 06-production/90-db-design.md:676、:710 |
| PRD | 报工（`prd_work_report`） | `report_status` 10/20/40 確定済/90 | 40 | — | 未登録 | 06-production/90-db-design.md:1457 |
| PRD | BOM・工艺路线・检验标准 | 10/25 承認済/30 有効/90（20 なし） | 25 | — | 未登録 | 06-production/90-db-design.md:177、:325、:2045 |
| FIN | 付款申请・费用报销 | 共通 C-1 準拠（10→20→25→40／90） | 25 | — | `PAYMENT_REQUEST`／`APR-PA-L1..L3`、`EXPENSE_CLAIM`／`APR-EXP-L1..L2` | 00-common/08:129、94:69-70 |

## 4. 状態操作の統一（既存定義の再掲）

| 操作 | 業務伝票の遷移（共通） | WF 側 | 権限（形式は 03 §11.1） | エラー | 出典 |
|---|---|---|---|---|---|
| 提出 | 10→20 | プロセス開始 | submit 権限（03 §11.1） | 状態不正 422、version 409／4003 | 00-common/03:282、02:80 |
| 最終承認 | 20→25 | E32（承認） | approve 権限（03 §11.1） | 同上、自己承認不可は域コード（例 PRD 60005） | 00-common/03:283、06-production/91-api-design.md:590 |
| 却下 | 20→95 | E32（却下） | approve 権限（03 §11.1） | 却下理由必須（空 400／1001） | 00-common/03:284、06-production/91-api-design.md:591 |
| 差戻し・撤回 | 20→10 | タスク終了／プロセス削除 | submit 権限（撤回、03 §11.1） | 未処理タスクなしは MSG-WF-020 | 00-common/03:285、02:84-85 |
| 取消 | 10/20→90（25 以降は後続なしのみ） | 強制終了 E32 TERMINATED | cancel 権限（03 §11.1） | MSG-COM-072 | 00-common/03:286、00-common/08:137、03-approval-admin.md:447 |

- 業務域の `approve`/`reject` API は WF の E32 コールバックと**同一サービスメソッド**を呼ぶ（PRD 工单の既存定義。06-production/91-api-design.md:557）。他域での同方針は未定義（§5 #6）。

## 5. 待確認事項（本書では決定しない）

| # | 事項 | 現状（出典） | 選択肢 | 起票者の提案 | 決定者 |
|---|---|---|---|---|---|
| 1 | 超产申请の承認済・却下コードが共通と不一致 | `prd_overproduction_approval` は 30 承認済／40 却下（06-production/90-db-design.md:1086、:1094）。共通は 25／95（00-common/08:106、:111）、WF 状態遷移も 25／95（02:70-71） | A：現行維持し WF 連携時にマッピング／B：25／95 へ移行迁移 | **已定（蓝色大肥鱼 2026-10-21）**：A。30／40 を維持し E32 受信側で承認→30・却下→40・強制終了→90。 A（実装・テスト済のため、E32 受信側でマッピング表を持つ） | 蓝色大肥鱼 |
| 2 | 报价 `quotation_status=25` が「承認待ち」 | 03-sales/90-db-design.md:246。共通では 25＝承認済、20＝承認待ち | A：20 承認待ち・25 承認済へ注記修正／B：現行維持 | A（`approval_status` 側は既に 20/25 で共通準拠：:247） | 蓝色大肥鱼／sales |
| 3 | 移库 `inv_transfer.approval_status` が独自コード | 0 不要／10 待ち／20 承認／30 却下（05-inventory/90-db-design.md:654、CHECK :671） | A：共通 10/20/25/95 へ移行／B：現行維持し対応表を明記 | B（CHECK 制約付きで実装済の可能性が高いため、まず実装状況を確認） | 蓝色大肥鱼／inventory |
| 4 | 盘点の承認待ち 35・承認済 40 | 05-inventory/90-db-design.md:810。共通は 20／25 | A：共通へ統一／B：盘点固有として維持 | B（実盤・差異確認の段階を持つため）＋本書に対応表を明記 | 蓝色大肥鱼／inventory |
| 5 | 工单の共通規定が 20 を飛ばしている | 00-common/08:125 は WO「10→25→30…」。PRD 側は 10→20→25（06-production/02-work-order.md:111-112、90:994） | A：00-common/08:125 を 10→20→25 に修正／B：現行維持 | **已定（蓝色大肥鱼 2026-10-21）**：A。00-common/08:125 を 10→20→25 に修正済。 A（PRD 側が実装済・PR #32 決定） | 蓝色大肥鱼 |
| 6 | WF 未接続の承認伝票 | 超产申请・工单变更・委外・NCR・报价・开票申请・在庫取引・成本调整・移库・BOM 系・MPS 等は 08/94 の業務類型・流程定義に無い（94:60-75） | A：各域で業務類型を追加／B：域内簡易承認（WF 不使用）として明記 | **一部已定（蓝色大肥鱼 2026-10-21）**：工单（`prd_work_order_release`）・超产申请（`prd_overproduction_approval`）を接続。他伝票は待確認。 伝票ごとに要判断。まず超产申请（`process_instance_id` 列あり）と工单（業務類型登録済・流程キー未定）を優先 | 蓝色大肥鱼 |
| 7 | 工单の流程キー未定 | 94:73「PRD 域定義」、94:98 `WO_STANDARD` の proc_def_key も `WORK_ORDER`。approval-matrix に APR-WO なし | A：`APR-WO` を approval-matrix に追加／B：`WORK_ORDER` をキーとして確定 | **已定（蓝色大肥鱼 2026-10-21）**：流程 key `prd_work_order_release`（一級・生产主管）。 決定待ち（新規経路は本書で定義しない） | 蓝色大肥鱼 |
| 8 | 状態不正のエラーコード | 共通は 4002（00-common/03:290、06-production/91-api-design.md:27）。超产申请は域コード 60101（91:588-592） | A：域ごとに許容／B：4002 に統一 | **已定（蓝色大肥鱼 2026-10-21）**：A。超产申请は 60101、他域は 4002。 A（超产申请は大肥鱼 2026-10-21 決定で 60101 確定済。他域は 4002 既定） | 蓝色大肥鱼 |
| 9 | MDM 供应商・信用额度の `approval_status` 値の注記なし | 02-mdm/90-db-design.md:711、:1284 | 物料・客户（10/20/25/90/95）と同一と注記 | 同一値を注記（DDL 本体は変更なし） | mdm |
| 10 | 業務伝票の `process_instance_id` 保持の有無 | PUR 3 表・超产申请のみ列あり。SAL/INV/FIN/他 PRD 表は無い（`wf_business_process` で引ける） | A：`wf_business_process` を正とし業務表に持たない／B：全承認表に追加 | A（08 の正本表は `wf_business_process`：90-db-design.md:290） | 蓝色大肥鱼 |

## 6. 改訂履歴

| 版数 | 日付 | 変更内容 | 変更者 |
|---|---|---|---|
| v1.0 | 2026-10-21 | 初版：共通規定 7 項、承認対象伝票 26 行の横断一覧（状態コード・WF 接続・出典）、状態操作の統一表、待確認 10 件（既存定義の集約のみ、新規業務ルールなし） | 业务分析 |
| v1.1 | 2026-10-21 | §3 工单の却下を 10 へ戻すに変更、流程 key を `prd_work_order_release` に。§5 #8 の出典を 91:588-592 に訂正。§5 #1・#5・#7・#8 を已定、#6 を一部已定に更新。§3 凡例に approval_status 20＝待审批、主数据 90＝废止を追記（蓝色大肥鱼 2026-10-21 決定） | 业务分析 |
