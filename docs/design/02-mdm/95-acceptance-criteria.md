# 主数据域 验收标准（T1 最小集・review-r3 关联 issue）

| 項目 | 内容 |
|---|---|
| 文書名 | 主数据域 验收标准 |
| 版数 | v1.0 |
| 作成日 | 2026-10-20 |
| 作成者 | 业务分析 |
| 状態 | ドラフト（レビュー中） |
| 関連文書 | [90-db-design.md](90-db-design.md) §4.1.2「T1 確定事項」 / [01-system 90 §3.15 sys_param](../01-system/90-db-design.md) / [RLS・DB ロール](../00-common/10-rls-and-db-roles.md)（PR #43） |

---

形式：G（Given）/ W（When）/ T（Then）。対象表：`mdm_uom`、`mdm_material_category`、`mdm_material`、`mdm_factory`、`mdm_warehouse`、`mdm_customer`。**待確認** は断言しない。

## AC1-1 業務キー一意は会社を含む（Refs #31）

- G：company 1 に物料 `3001000001` が存在。W：company 1 に同じコード（`deleted=FALSE`）を INSERT。T：`uk_mdm_material_company_code` 違反。W：company 2 に同じコードを INSERT。T：成功。
- W：`pg_indexes` で T1 表の非主キー索引を確認。T：先頭列はすべて `company_id`（`uk_mdm_uom_base` は `(company_id, conversion_group)`）。

## AC1-2 論理削除後のコード再利用

- G：物料 `deleted=TRUE`。W：同じコードを INSERT。T：成功（部分一意索引 `WHERE deleted = FALSE`）。

## AC1-3 RLS テナント分離（Refs #9、#10）

- G：`mdm_material` に tenant 0 と tenant 9 の行。W：`erp_app` で `app.tenant_id=0` を設定して SELECT。T：tenant 0 の行のみ。W：`tenant_id=9` で INSERT。T：WITH CHECK で拒否。W：`app.tenant_id` 未設定で照会。T：エラー（[10-rls-and-db-roles.md](../00-common/10-rls-and-db-roles.md) に従う）。

## AC1-4 FK RESTRICT

- G：物料が受注行から参照されている。W：`DELETE FROM mdm_material`。T：失敗。

## AC1-5 コメント完備

- W：`pg_description` を照会。T：T1 の全表・全列にコメントがある（欠落 0）。

## AC1-6 種データ投入

- W：seed を実行。T：`mdm_material` 54 行。`3001000001` の `mrp_type`、`cost_method` は `90-data/material-master.csv` と一致。

## AC1-7 計価方法（Refs #8、#32）

- W：`valuation_method` が NULL、または (10,20) 以外で INSERT。T：失敗（`NOT NULL`、`ck_mdm_material_valuation_method`）。
- T：種データで MTS 自制成品は 20、MTO 产品・外购料は 10（R1）。

## AC1-8 容差は比率、優先順位（G2-18 前提、Refs #29）

- W：`completion_over_rate = -0.01` で INSERT。T：CHECK 違反。
- G：受注行・物料が未設定、分類 0.03、会社 `production.completion.over_rate=0.05`。W：受注行確定。T：採用率 0.03。分類も未設定なら 0.05。
- G：基本単位の小数 0 桁、`ordered_qty=30`、率 0.05。W：確定。T：`allowed_qty = floor(31.5) = 31`。
- 購買受入の容差（物料 > 分類 > 仕入先 > 会社）は別系統で、完工の計算に使わない。

## AC1-9 標準原価の唯一の正（Refs #32）

- G：`fin_standard_cost` に YE3 V1（778.20、2026-10-01 発効）。W：`mdm_material.standard_cost` を直接 UPDATE。T：拒否（トリガー）またはビュー列のため更新不可（方式は 07-finance の PR で決める、**待確認**）。
- W：V2 が発効。T：`mdm_material.standard_cost` の参照値は V2。下达済み工单のスナップショットは変わらない。

## AC1-10 検査フラグの導出

- W：`information_schema.columns` を照会。T：`mdm_material.inspection_required` は存在しない。入庫明細の `inspection_flag` 既定値は `inspection_stage` から導出（規則は 05-inventory、**待確認**）。
