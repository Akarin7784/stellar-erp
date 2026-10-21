# 生产域 验收标准（第一版全量・G2-18 受注連係・容差・ロック）

| 項目 | 内容 |
|---|---|
| 文書名 | 生产域 验收标准 |
| 版数 | v1.4 |
| 作成日 | 2026-10-20 |
| 作成者 | 业务分析 |
| 状態 | ドラフト（レビュー中） |
| 関連文書 | [90-db-design.md](90-db-design.md) / [02-work-order.md](02-work-order.md) / [03-material-issue-reporting.md](03-material-issue-reporting.md) / [93-messages.md](93-messages.md) / [91-api-design.md](91-api-design.md) / [销售 95](../03-sales/95-acceptance-criteria.md) |
| 関連Issue | Refs #9、#10、#29、#31、#43、#47（backend G2-18）、#54 |

---

形式：G（Given）/ W（When）/ T（Then）。

## AC-PRD-01 分期表記なし

- W：`docs/design/06-production` で `Phase` / `フェーズ` / `分期` を grep。T：0 件（改訂履歴の原文引用を除く）。

## AC-PRD-02 tenant_id / company_id（Refs #9、#10、#43）

- W：`06-production/90-db-design.md` を確認。T：禁止写死的默认租户（`tenant_id` 不得使用字面量默认值；`DEFAULT current_setting('app.tenant_id')::bigint`）。`company_id` は NOT NULL かつ DEFAULT 1 なし。

## AC-PRD-03 一意索引は tenant_id 先頭（Refs #31）

- W：業務一意索引（`uk_`、明細表 16 件を含む）を確認。T：すべて `(tenant_id, company_id, …)` で始まる。`ON CONFLICT` も同じ列を含み、採番は `sys_sequence.step`（`EXCLUDED.step` 禁止）。
- T：親 ID 先頭の例外は存在しない（90-db-design「一意索引の先頭列ルールと例外」、sys/V202610210708 と一致）。

## AC-PRD-04 工单品目＝受注行品目（G2-18 / #47）

- G：受注行 `material_id=A`。W：工单登録／下达で `material_id=B`（≠A）かつ `sales_order_line_id` を当該行に設定。T：HTTP **422**、業務コード **`60056`**、`MSG-PRD-056`。共通 **4002 を返さない**（4002 は 409/状態競合専用）。
- G：受注行物料 A。W：工单物料 A で登録。T：成功。`sales_order_line_id` が保存される。

## AC-PRD-05 数量は物料基本単位

- G：受注行の販売単位 BOX、`conversion_rate=12`、基本単位 PCE。W：工单・報工・完工を登録。T：`order_qty` / `reported_*` / `completed_qty` / `allowed_qty` はすべて **PCE（基本単位）**。販売単位数量を工单に直接持たない。

## AC-PRD-06 allowed_qty と容差チェーン

- G：基本単位小数 0 桁、受注行基本数量 30、容差率 0.05（会社 `sys_param.prd.completion_over_rate`）。W：受注確定→工单作成。T：`allowed_qty = floor(30 × 1.05) = 31`。工单の `allowed_qty`（または参照する受注行値）が 31。
- G：物料に `completion_over_rate=0`（明示 0%）。W：確定。T：採用率 0（分類・会社へ継承しない）。`allowed_qty = floor(base × 1.0)`。
- G：受注行・物料・分類がいずれも NULL。W：確定。T：会社 `prd.completion_over_rate`（NUMERIC(5,4) 比率、既定 0.05）を採用。
- G：会社パラメータ `prd.completion_over_rate` 未シード／テナント未設定。W：確定または完工。T：業務コード **5000**（設定不備）。ドメイン 600xx や 4002 ではない。
- G：MTO 工单の紐づく受注行 `allowed_qty IS NULL`（未スナップショット）。W：工单下达。T：業務コード **5000**。工单ロック前に判定し、工单状態・`version` は不変（0 とみなして処理しない。蓝色大肥鱼 2026-10-21 決定）。

## AC-PRD-07 完工上限と超産承認（コード優先：60100 → 60040）

- G：MTO 工单、`allowed_qty=31`、`completed_qty=30`、超産承認なし／未承認。W：完工入庫 2（累計 32 > 31）。T：**422 / `60100` / `MSG-PRD-100`**（超産未承認が先）。**`60040` は返さない**。入庫されない。
- G：同上。W：超産承認（`prd_overproduction_approval`＋Flowable）が通過し承認後許容が 35。T：受注行および関連工单の `allowed_qty` が 35 に再計算。その後入庫 2 が成功し `completed_qty=32`。
- G：超産承認が却下または取消。W：超過入庫。T：**422 / `60101` / `MSG-PRD-101`**。
- G：MTS 工单（受注行なし）、または MTO で承認後の `allowed_qty` を使い切った状態。W：さらに `completed_qty + 今回 > allowed_qty` となる入庫。T：**422 / `60040` / `MSG-PRD-040`**（ハード上限超過。超産経路が尽きた／MTS）。
- G：完工入庫確定済、`completed_qty=32`。W：冲销（取消・反向）で戻し数量 40（> 32）。T：**422 / `60102` / `MSG-PRD-102`**。`completed_qty` は減らない。

## AC-PRD-08 跨表ロック順序（Refs #29）

- G：同一受注行に紐づく工单あり。W：受注変更（數量）と完工入庫を同時実行。T：デッドロックしない（両パスとも受注行 → 工单、同一表は id 昇順）。`completed_qty ≤ allowed_qty`。
- W：完工確定の実装／設計手順。T：先に `sal_sales_order_line` を `FOR UPDATE`、次に `prd_work_order`。過帳は行ロックのみ（楽観 `version` は画面編集）。

## AC-PRD-09 受注変更後の allowed_qty 再計算

- G：受注行確定済み、工单あり。W：承認済の受注數量変更。T：受注行 `allowed_qty` が再計算され、関連工单のスナップショット／参照が更新される（#54 AC-SAL-06/08 と整合）。減量が `completed_qty` 未満なら販売側拒否（本域は完工済み数量を下回る変更を前提にしない）。

## AC-PRD-10 業務コードと共通コードの使い分け

- W：品目不一致・超産・完工超過・冲销超過など業務拒否。T：HTTP 422 + ドメイン `60056` / `60100` / `60101` / `60040` / `60102`（MTO 未承認超産は **60100 優先**、ハード超過は **60040**）。
- W：楽観排他・状態競合。T：HTTP 409 + 共通 **4002**（または `MSG-COM-033` 系）。業務拒否に 4002 を使わない。
- W：テナント未設定または `prd.completion_over_rate` 欠落。T：**5000**。

## AC-PRD-11 作废・結案（共通）

- G：工单に領料／報工／完工実績あり。W：物理削除。T：拒否（取消・結案フロー）。結案は全数入庫・報工・検査・原価条件を満たすこと（既存 `MSG-PRD-075` 系）。

## AC-PRD-12 有効 BOM の要否と BOM 基準日（蓝色大肥鱼 2026-10-21 #36 決定）

- G：工单の `plannedStartDate=2026-11-12`。W：`GET /api/production/boms/effective` を呼ぶ。T：`date=2026-11-12` で解決される。
- G：`plannedStartDate` 未入力、会社タイムゾーン Asia/Shanghai。W：同上。T：`date` は Asia/Shanghai の当日（例：2026-10-20T23:30Z → 2026-10-21）。
- G：有効 BOM のない製造品。W：工单を登録（草稿保存）。T：成功（201、`order_status=10`）。画面／`data.warnings[]` に `60020`／`MSG-PRD-020` の警告。
- G：上記工单。W：`POST /work-orders/{id}/submit`。T：成功（200、`order_status=20`）。`60020` を返さない。
- G：上記工单が承認済（25）で有効 BOM なし。W：`POST /work-orders/{id}/release`。T：**422 / `60020` / `MSG-PRD-020`**。状態は 25 のまま、E21 は発行されない。

## AC-PRD-13 下达時の BOM 展開（蓝色大肥鱼 2026-10-21 PR #37 決定）

- G：材料明細 0 行の草稿工单。W：`POST /work-orders/{id}/submit`。T：成功（200、`order_status=20`）。`1001` を返さない。
- G：承認済（25）、材料明細 0 行、有効 BOM あり。W：下达。T：成功（`order_status=30`）。同一トランザクションで BOM（基準日＝計画着手日、未入力時は下达処理日の会社タイムゾーン当日）から材料明細が INSERT される。
- G：承認済、材料明細 0 行、有効 BOM なし。W：下达。T：**422 / `60020` / `MSG-PRD-020`**。`order_status=25`・`version` 不変、材料明細 0 行のまま、E21 なし。
- G：承認中（20）、材料明細 0 行、工序明細 1 行以上。W：承認。T：成功（`order_status=25`）。材料明細の不足でエラーにならない。
- G：承認中（20）、工序明細 0 行。W：承認。T：**422 / `60021` / `MSG-PRD-021`**。`order_status=20`・`version` 不変（蓝色大肥鱼 2026-10-21 決定）。
- G：有効工艺なしの品目。W：工单登録（保存）。T：成功（工序 0 件）、`warnings[]` に `60021`／`MSG-PRD-021`。
- G：承認済、材料明細あり（手動修正済）。W：下达。T：成功。既存明細の件数・数量・ID は変わらない（再展開しない）。
- G：承認済、材料明細 0 行、有効 BOM あり。W：同一工单を 2 セッションで同時に下达。T：1 件のみ成功、他方は 409／`4002` または `4003`（後続リクエストは `FOR UPDATE` で待機し、取得後に状態 30 を検知して `4002`、`version` が古ければ `4003`。ロック待ちタイムアウトは既存の `lock_timeout` 処理に従い、新コードは設けない）。材料明細は 1 回分のみ（重複なし）。
- G：承認済、材料明細 0 行、`planned_start_date` NULL、有効 BOM あり。W：下达。T：BOM 基準日は下达処理日の会社タイムゾーン当日（Asia/Shanghai）。`planned_start_date` が入力済ならその日を使う。
- G：承認済、材料明細 0 行、有効 BOM なし。W：下达。T：Outbox に E21 が記録されない。

## AC-PRD-15 超産申請数量の上限と精度（蓝色大肥鱼 2026-10-21 決定）

- G：受注行基本数量 100（基本単位 `PCS`、`decimal_places=0`）、`prd.overproduction_max_rate=1.0000`。W：超産申請 `request_qty=100`。T：保存成功（上限ちょうどは可）。
- G：同上。W：`request_qty=100.5` または `101`。T：**422 / `60103` / `MSG-PRD-103`**、申請は保存されない。
- G：同受注行に承認済超産 `request_qty=100` が既にある。W：新たに `request_qty=100` を申請。T：保存成功（累計上限なし。基準は `allowed_qty` ではなく受注行基本数量）。
- G：当該会社に `prd.overproduction_max_rate` が存在しない。W：超産申請保存。T：業務コード **5000**（既定値で補わない）。

## AC-PRD-16 新規会社の業務パラメータ即時読取り（蓝色大肥鱼 2026-10-21 決定）

- G：テナント開設済み。W：`POST /api/system/companies` で会社を新規登録。T：同一トランザクションで当該会社（`company_id` = 新 `sys_company.id`）に `prd.completion_over_rate = 0.05`、`prd.overproduction_max_rate = 1.0000` の `sys_param` 行が作成される。
- G：上記の新規会社でログイン（`LoginContext.companyId` = 新 `sys_company.id`）。W：完工登録・超産申請を保存。T：パラメータ欠落の `5000` にならない（`company_id = 0` へのフォールバックなし）。
- G：会社登録の再試行等で既定行が既にある（または値が変更済み）。W：投入処理を再実行。T：重複エラーにならず、既存値は上書きされない。
- G：`sys_param` の投入が失敗。W：会社登録。T：`sys_company` も登録されない（全体ロールバック）。

## 改訂履歴

| 版数 | 日付 | 変更内容 | 変更者 |
|---|---|---|---|
| v1.0 | 2026-10-20 | 初版 | 业务分析 |
| v1.1 | 2026-10-21 | AC-PRD-12 を追加：BOM 基準日（計画着手日／未入力時は会社タイムゾーン当日）、登録・提出は BOM なしで成功、下达のみ 60020（蓝色大肥鱼 2026-10-21 #36 決定） | 业务分析 |
| v1.2 | 2026-10-21 | AC-PRD-13 を追加：提出は材料明細 0 行可、下达時の BOM 展開・60020 時の不変・既存明細の非再展開・同時下达（蓝色大肥鱼 2026-10-21 PR #37 決定） | 业务分析 |
| v1.3 | 2026-10-21 | AC-PRD-13：承認は材料明細 0 行でも成功、同時下达の後続を 409／4002 または 4003 に変更（蓝色大肥鱼 2026-10-21 PR #37 決定） | 业务分析 |
| v1.4 | 2026-10-21 | AC-PRD-03 の例外前提を削除、AC-PRD-13 に承認時工序 0 行 60021・保存時警告を追加（蓝色大肥鱼 2026-10-21 決定） | 业务分析 |
| v1.5 | 2026-10-21 | AC-PRD-15 を追加：超産申請 1 件の上限（受注行基本数量 × `prd.overproduction_max_rate`）、累計上限なし、精度違反 60103、パラメータ欠落 5000（蓝色大肥鱼 2026-10-21 決定） | 业务分析 |
| v1.6 | 2026-10-21 | AC-PRD-16 を追加：新規会社は登録直後から両パラメータを読取り可能（5000 にならない）、冪等・全体ロールバック（蓝色大肥鱼 2026-10-21 決定） | 业务分析 |
