# 生产域 验收标准（第一版全量・G2-18 受注連係・容差・ロック）

| 項目 | 内容 |
|---|---|
| 文書名 | 生产域 验收标准 |
| 版数 | v1.0 |
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

- W：業務一意索引（親 ID 先頭の例外を除く）を確認。T：`(tenant_id, company_id, …)` で始まる。`ON CONFLICT` も同じ列を含み、採番は `sys_sequence.step`（`EXCLUDED.step` 禁止）。
- T：例外一覧が 90-db-design「一意索引の先頭列ルールと例外」に明記されている。

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
