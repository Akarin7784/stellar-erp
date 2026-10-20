# 销售域 验收标准（第一版全量・受注行数量/单位・变更・锁定）

| 項目 | 内容 |
|---|---|
| 文書名 | 销售域 验收标准 |
| 版数 | v1.0 |
| 作成日 | 2026-10-20 |
| 作成者 | 业务分析 |
| 状態 | ドラフト（レビュー中） |
| 関連文書 | [90-db-design.md](90-db-design.md) / [02-sales-order.md](02-sales-order.md) / [93-messages.md](93-messages.md) / [04 §11.1](../00-common/04-common-db-spec.md) |

---

形式：G（Given）/ W（When）/ T（Then）。

## AC-SAL-01 分期表記なし

- W：`docs/design/03-sales` で `Phase` / `フェーズ` / `分期` を grep。T：0 件（改訂履歴の原文引用を除く）。

## AC-SAL-02 tenant_id / company_id（Refs #9、#10、#43）

- W：`03-sales/90-db-design.md` を確認。T：禁止写死的默认租户（`tenant_id` 不得使用字面量默认值）；`tenant_id` 既定取 `current_setting('app.tenant_id')::bigint`。`company_id` 为 NOT NULL 且无字面量公司默认值。

## AC-SAL-03 一意索引は tenant_id 先頭（Refs #31 原則）

- W：業務一意索引（親 ID 先頭の例外を除く）を確認。T：`(tenant_id, company_id, …)` で始まる。例外は 90-db-design の「一意索引の先頭列ルール」に登記済み。

## AC-SAL-04 出荷数量の二重単位

- G：受注行の販売単位 PCE、`conversion_rate=1`、`ordered_qty=120`。W：出荷確定で販売単位 80 を計上。T：`shipped_qty=80` かつ `shipped_base_qty=80`。
- G：`conversion_rate=12`（1 BOX = 12 PCE）。W：販売単位 2 BOX を出荷。T：`shipped_qty=2`、`shipped_base_qty=24`。
- W：受注詳細 API / 畫面。T：`shippedQty` と `shippedBaseQty`（および `conversionRate`）の両方を返す・表示する。

## AC-SAL-05 換算率スナップショット

- G：受注確定時 `conversion_rate=12`。W：その後 MDM の換算率を 10 に変更。T：当該受注行の `conversion_rate` は 12 のまま。新規受注のみ新レート。

## AC-SAL-06 受注変更と已完工・已出库（Refs #24、#29）

- G：受注行 `ordered_qty=120`、`conversion_rate=1`、`completed_qty=100`、`shipped_base_qty=80`。W：変更で 90 に減量し承認実行。T：HTTP **422**、業務コード **30022**、`MSG-SAL-056`（変更後基本単位數量が已完工 100 未満）。
- W：変更で 70 に減量（已出库 `shipped_base_qty=80` 未満だが、同时也会触发已完工校验时以更严者为准）。T：HTTP **422**、**30022**、`MSG-SAL-056`（文案同时覆盖已完工与已出库下限；销售单位侧的已出荷チェックは従来どおり `MSG-SAL-054` も可）。
- W：変更で 110 に減量し承認。T：成功。`allowed_qty` が再計算される（承認済変更時）。

## AC-SAL-07 跨表ロック順序（Refs #29）

- G：同一受注行に紐づく工单あり。W：受注変更（數量）と報完工を同時実行。T：デッドロックしない（両パスとも受注行 → 工单、同一表は id 昇順）。`completed_qty ≤ allowed_qty`。

## AC-SAL-08 allowed_qty 計算

- G：基本単位小数 0 桁、`ordered_qty=30`、`conversion_rate=1`、容差率 0.05（会社既定）。W：受注確定。T：`allowed_qty = floor(31.5) = 31`。
- G：物料に `completion_over_rate=0`。W：確定。T：採用率 0（明示 0%。分類・会社へ継承しない）。
- G：受注行が確定済み、`allowed_qty=31`。W：超産承認が通過し承認後の許容数量が基本単位 35 になる。T：`allowed_qty` が 35 に再計算される（確定時スナップショットの再計算経路。90-db-design 数量・単位節）。

## AC-SAL-09 作废已有下游（共通、Refs #25）

- G：受注に出荷実績あり。W：受注取消。T：`MSG-SAL-046` / `MSG-COM-072` 系で拒否（物理削除しない）。
