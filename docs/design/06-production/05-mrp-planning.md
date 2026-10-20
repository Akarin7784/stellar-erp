# MRP 物料需求计划・生产计划 详细设计书（MRP 所要量計画 詳細設計書）

| 項目 | 内容 |
|---|---|
| 文書名 | MRP 物料需求计划・生产计划 详细设计书（MRP 所要量計画・生産計画 詳細設計書） |
| 文書番号 | DSN-PRD-005 |
| 版数 | v1.0 |
| 作成日 | 2026-10-20 |
| 作成者 | production-designer |
| 承認者 | 未承認（レビュー待ち） |
| 状態 | ドラフト（レビュー中） |
| 関連文書 | [业务域概要](00-overview.md) / [BOM・工艺](01-bom-routing-workcenter.md) / [生产订单](02-work-order.md) / [DB 设计](90-db-design.md) / [API 设计](91-api-design.md) / [跨域流程](../00-common/09-cross-domain-flow.md) / [共通业务规则](../00-common/08-common-business-rules.md) / [YE3 多阶 BOM](../90-data/bom-demo.md) / [YE3 工艺路线](../90-data/routing-demo.md) / [示例企业](../90-data/demo-company.md) |

---

## 1. 機能概要

| 項目 | 内容 |
|---|---|
| 機能 ID | F-PRD-010（MRP 物料需求计划）、F-PRD-011（生产计划与排产） |
| 機能名 | MRP 运行、需求计算、计划订单、动作消息、MPS・粗能力 |
| 目的 | 销售需求・预测・安全库存・既有工单子件需求を需要源として、BOM を多阶展开し、现有库存・入荷预定・引当を考慮した**净需求**を算出。提前期と批量规则を適用して**计划订单**（製造/采购/委外）を生成し、人間の判断を要する**动作消息**（発注/製造/取消/延期等）を提示する。これにより「必要なものを、必要なときに、必要な量だけ」調達・製造できる状態を作る |
| 利用者・ロール | 计划员（主）、生产经理（承認）、采购员（请购受领）、车间主管（能力确认） |
| 利用シーン | ①毎日 20:00 の日次 MRP（BAT-PRD-001）②受注急増・設計変更時の手動 MRP ③週次の MPS 確定後 ④「なぜこの発注が必要か」を計画订单から逆引きする場面 |
| 優先度 | P1（Phase 1.5） |
| 画面 ID | SCR-PRD-021（运行向导）、SCR-PRD-022（运行结果）、SCR-PRD-023（计划订单确认）、SCR-PRD-024（MPS・排产） |
| 関連 IF | なし（域内バッチ＋領域イベント。外部 IF は INT 域の MES 連携で計画結果を参照） |

### 1.1 用語と計算単位

| 用語 | 定義 | 本設計での扱い |
|---|---|---|
| バケット | 需要を集計する時間単位 | Phase 1 は**日次バケット**（0〜90 日）。90 日超は週次バケットに集約（設定 `mrp.bucket.weekly_after_days=90`） |
| 展望期（計画期間） | MRP が需要を展開する期間 | 既定 90 日（`prd_material_planning.planning_horizon_days`、システム既定 `mrp.horizon.days=90`） |
| 毛需求（GR） | 独立需要＋従属需要の合計 | 品目×バケット単位 |
| 入荷预定（SR） | 発注残・工单残・委外残（確定済の入荷予定） | 品目×バケット単位 |
| 现有库存（OH） | MRP が利用可能とみなす在庫 | `現有 − 待検 − 凍結 − 品質保留`（引当済は控除しない。理由は 3.6） |
| 净需求（NR） | 補充が必要な数量 | `max(0, GR + 安全在庫 − (前バケット末在庫 + SR))` |
| 计划订单（PO） | MRP が生成する補充提案 | `order_type`＝製造/采购/委外、`start_date`＝着手/発注日、`due_date`＝必要日 |
| 动作消息 | 計画担当者が判断すべき差異の通知 | 発注/製造/取消/延期/提前/增量/减量/安全库存不足 |
| 低层码（LLC） | 全 BOM 中の最大階層 | 展開順序の決定に使用（[01](01-bom-routing-workcenter.md) 5.2） |

## 2. 業務要件・業務ルール

### 2.1 前提条件

| # | 前提条件 | 成立しない場合の挙動 |
|---|---|---|
| 1 | 対象品目に有効な BOM（`bom_status=30`、`valid_from ≦ 基準日 ≦ valid_to`）が存在する | 製造品はエラー停止（`MSG-PRD-020`）。BOM なし品目は「購入品」として扱わない |
| 2 | 対象品目に `prd_material_planning` が存在し `is_mrp_planned=true` | MRP 対象外としてスキップ（ログに記録） |
| 3 | 低层码が最新（BAT-PRD-002 実行済み） | 実行前に低层码再計算を強制実行（前処理） |
| 4 | 会計期間が締切済でない（当月） | `MSG-COM-071` で実行拒否（計画データは在庫・会計に影響しないため警告のみでも可。設定 `mrp.allow.closed_period=false`） |
| 5 | 同一工厂で MRP が実行中でない | Advisory Lock 取得失敗 → `MSG-PRD-029`「他の MRP が実行中です」 |
| 6 | MDM 物料の基本単位と BOM 単位が整合している | 単位不一致はエラー（`MSG-PRD-022`） |

### 2.2 業務ルール

| # | ルール | 根拠 | 関連項目 |
|---|---|---|---|
| BR-MRP-01 | 需要源は「受注（MTO）」「销售预测（MTS）」「安全库存割れ」「既有工单未領料子件」「既存计划订单子件」「委外订单未発料子件」の 6 種 | [09](../00-common/09-cross-domain-flow.md) 6.2 手順 1 | `prd_mrp_demand.demand_type` |
| BR-MRP-02 | MTO 受注は受注明細の納期を需要日とし、MTS 予測はバケット日を需要日とする。二重計上を避けるため、受注が予測を「食う」設定（`mrp.forecast.consume=true`）では同一品目・同一バケットの予測から受注数量を控除する | 二重発注防止 | `prd_demand_forecast` |
| BR-MRP-03 | 安全库存は「品目×工厂」単位で保持し、净需求計算時に**期末在庫 ≥ 安全在庫**となるよう上乗せする | [08](../00-common/08-common-business-rules.md) 6.1 | `safety_stock_qty` |
| BR-MRP-04 | 可用量は INV が定義する「現有 − 引当 − 待検 − 凍結」を正とし、MRP はそれをそのまま使用する（引当の二重控除をしない）。 | 在庫契約 | `availableQty` |
| BR-MRP-05 | 低层码の昇順に処理する。同一低层码内の品目順序は `material_code` 昇順（再現性のため） | 標準 MRP 手順 | `low_level_code` |
| BR-MRP-06 | 従属需要の必要日は「親品目の計画订单の**着手日（start_date）**」とする（親の製造開始時に子件が必要） | 標準 MRP | `bucket_date` |
| BR-MRP-07 | 提前期は「製造提前期（`production_lead_time_days`）」または「采购提前期（`lead_time_days`）」を用い、**工作日历**（`prd_work_center_calendar`）で逆算する。提前期中に非稼働日を含めない | [00-overview](00-overview.md) 3.2 | `start_date` |
| BR-MRP-08 | 批量规则は `lot_sizing_rule`（L4L/FOQ/最小-最大/周期発注/倍数切上）に従い、`min_order_qty`・`order_multiple`・`max_order_qty` を適用する | 発注効率 | 3.7 |
| BR-MRP-09 | 製造品の计划订单数量は `良品率（yield_rate）` で補正する（必要投入 = 净需求 ÷ 良品率。BOM 损耗率は子件展開時に適用するため二重計上しない） | 歩留り考慮 | `yield_rate` |
| BR-MRP-10 | 計画订单の `order_type` は `material_type` で決まる（10 采购→采购、20 制造→製造、30 委外→委外、40 虚拟件→計画订单を作らず透過展開、50 外注部品→委外） | [06](../00-common/06-code-list.md) 11 章 | `material_type` |
| BR-MRP-11 | 逾期需要（需要日 < 実行日）は実行日バケットに集約し、計画订单の `start_date` が過去になる場合は「即時発注/即時着手」の警告付き动作消息（10/20）を出す | 遅延の可視化 | 3.9 |
| BR-MRP-12 | MRP は計画データのみを生成し、**在庫・会計・既存伝票を直接更新しない**。確認後に工单/請購へ転送する（更新責任の一元化） | [09](../00-common/09-cross-domain-flow.md) 2.2 | `converted_doc_*` |
| BR-MRP-13 | 再実行は同一 `run_date` でも新規 `mrp_run_no` を採番し、旧実行の未確認計画订单は「前回実行」として残す（上書きしない）。確認済・転送済の計画订单は再計算対象外 | 監査性 | `prd_mrp_run` |
| BR-MRP-14 | 計画订单は 1 回のみ転送可能。転送済みは取消・変更できない（変更は転送先伝票で行う） | 二重転送防止 | 5 章 |
| BR-MRP-15 | 安全库存割れが净需求に反映された場合、`prd_mrp_demand.safety_stock_qty > 0` かつ `demand_type=30` の需要行を生成し、根拠を追跡可能にする | 説明可能性 | `prd_mrp_demand` |

### 2.3 計算式・判定式

| # | 対象 | 算式 | 丸め | 例 |
|---|---|---|---|---|
| CALC-MRP-01 | 利用可能在庫 | INV の**公開照会 API**（`GET /api/inventory/stock-balances/available`）が返す `availableQty`（`stock_status=20 可用`,`qty_on_hand − qty_reserved`）を合計する。**PRD は在庫テーブルを直接参照しない** | 4 桁 | 例 850.0000 KGM |
| CALC-MRP-02 | 入荷预定 | `SR[bucket] = Σ(発注残 PO, 工单残 WO, 委外残 OS) の入荷日=bucket の残数量` | 4 桁 | 1,000.0000 KGM |
| CALC-MRP-03 | 期末預計在庫（PAB） | `PAB[t] = PAB[t−1] + SR[t] + plannedReceipt[t] − GR[t]` | 4 桁 | 3.6 参照 |
| CALC-MRP-04 | 净需求 | `NR[t] = max(0, GR[t] + SS − (PAB[t−1] + SR[t]))` | 4 桁切上（`CEILING(...,4)`） | 35 PCE |
| CALC-MRP-05 | 発注数量（L4L） | `Q = NR`（`min_order_qty` 未満なら `min_order_qty`） | 4 桁切上 | 35 |
| CALC-MRP-06 | 発注数量（FOQ） | `Q = CEILING(NR / lot_size) × lot_size` | 整数倍 | 18.18 → 50 |
| CALC-MRP-07 | 発注数量（倍数切上） | `Q = max(min_order_qty, CEILING(NR / order_multiple) × order_multiple)`、`Q > max_order_qty` なら分割 | 整数倍 | 778.2 → 1,000 |
| CALC-MRP-08 | 製造投入量 | `Q_make = CEILING(NR / yield_rate)`（`lot_sizing_rule=L4L` の場合） | 4 桁切上 | 35 ÷ 0.99 = 35.35 |
| CALC-MRP-09 | 子件展开量 | `childQty = Q × prd_bom_line.required_qty ÷ prd_bom.base_qty` | 4 桁切上 | 50 × 1.005 = 50.25 |
| CALC-MRP-10 | 着手日 | `start_date = subtractWorkdays(due_date, lead_time_days, calendar)`（当該日が非稼働なら前の稼働日） | 日単位 | 11-20 − 3 稼働日 = 11-17 |
| CALC-MRP-11 | 安全库存需要行 | `SS需要 = max(0, SS − PAB[最終バケット])` を最終バケットに `demand_type=30` で計上 | 4 桁 | — |

## 3. MRP アルゴリズム（実装仕様）

### 3.1 全体フロー

```mermaid
flowchart TD
    S0[0. 前処理<br/>低层码再計算・ロック取得] --> S1[1. 計画対象品目の抽出<br/>prd_material_planning]
    S1 --> S2[2. バケット生成<br/>日次/週次]
    S2 --> S3[3. 初期在庫・入荷预定・安全在庫の取込]
    S3 --> S4[4. 独立需要の収集<br/>受注/予測/MPS/安全在庫]
    S4 --> S5{5. 低层码昇順ループ}
    S5 --> S6[6. 品目×バケットの净需求計算<br/>GR+SS-(PAB+SR)]
    S6 --> S7[7. 批量规则適用・着手日逆算<br/>计划订单生成]
    S7 --> S8[8. 子件需要の展開<br/>次低层码へ加算]
    S8 --> S5
    S5 -->|全品目完了| S9[9. 既存伝票との差異から动作消息生成<br/>取消/延期/提前/增量/减量]
    S9 --> S10[10. 結果保存・実行サマリ・通知<br/>E イベントなし（計画データのみ）]
```

### 3.2 入力データ（取得元と取得条件）

| # | データ | 取得元 | 取得条件 | 備考 |
|---|---|---|---|---|
| I-01 | 計画対象品目 | `prd_material_planning` | `factory_id = 対象`、`is_mrp_planned=true`、`deleted=false` | `material_type`・`low_level_code`・`yield_rate` 等を含む |
| I-02 | BOM（有效版） | `prd_bom`+`prd_bom_line`+`prd_bom_substitute` | `bom_status=30`、`valid_from ≦ 基準日 ≦ valid_to`、`factory_id = 対象` | 基準日＝`run_date`。BOM キャッシュ（TTL 5 分）使用可 |
| I-03 | 工艺路线（提前期補正用） | `prd_routing`+`prd_routing_operation` | 有效版 | 工序工数から製造提前期を補正（任意、設定時） |
| I-04 | 现有库存（可用量） | INV 公開照会 API `GET /api/inventory/stock-balances/available`（同期参照） | 対象工厂・全倉庫、品目単位 | INV の可用量定義（引当控除後）を使用。INV 停止時は前回スナップショット＋警告 |
| I-05 | 入荷预定 | PUR 発注残照会 / `prd_work_order`（未完工）/ `prd_outsourcing_order`（未受入） | 未完了の確定伝票 | 数量＝注文数量 − 既入荷/既完工数量 |
| I-06 | 独立需要（受注） | SAL 受注残照会（同期参照） | 未出荷の受注明細（承認済 25/30/35）・納期 ≦ 展望期末 | MTO。受注が予測を消費する設定時は I-07 から控除 |
| I-07 | 独立需要（予測） | `prd_demand_forecast` | `forecast_status=30`、`bucket_date` ≦ 展望期末、最新 `version_no` | MTS |
| I-08 | 独立需要（MPS） | `prd_mps`+`prd_mps_line` | `mps_status=30`、対象期間 | MPS が予測に優先（設定） |
| I-09 | 安全库存割れ | `prd_material_planning.safety_stock_qty` + I-04 | — | `demand_type=30` の需要行を生成 |
| I-10 | 既有工单未領料子件 | `prd_work_order`（30/35）＋`prd_work_order_material`（`remaining_qty>0`） | 未完了工单 | 既に計画済の需要（再計上しない）。MRP は**未計画の追加需要のみ**を対象とするため、当該数量は GR に含めず、既存 WO の材料は SR として扱う（二重計上防止） |
| I-11 | 既存計画订单（未転送） | `prd_mrp_plan_order`（`plan_status IN (10,20,25)`） | 前回実行分 | 本次実行では引き継がず、需要が残れば再生成（BR-MRP-13）。確認済は SR とみなす |

> **二重計上防止の原則**：本設計では「確定済の補充（PO/WO/OS）は SR」「未確定の計画订单は再計算」「既存 WO の未領料子件需要は GR に含めない（WO 自体が SR であり、その子件は WO 作成時に展開済み）」とする。I-10 を GR に含めると、WO の材料と MRP の材料が二重になるため。

### 3.3 処理ステップ（正常系）

**PRC-PRD-010-01 MRP 全量実行（BAT-PRD-001 / SCR-PRD-021）**

1. **前処理**：対象工厂の Advisory Lock 取得（`pg_advisory_lock(mrp:{factory_id})`）。低层码の最終計算日時が BOM 変更日より古ければ BAT-PRD-002 のロジックを同期実行。`prd_mrp_run` を `run_status=10`（実行中）で INSERT し `mrp_run_no` を採番する。
2. **計画対象抽出**：I-01 を `low_level_code ASC, material_code ASC` でソート。対象品目数 0 なら `MSG-PRD-023` で終了。
3. **バケット生成**：`run_date` から `planning_horizon_days` 日を日次バケットで生成。`bucket_type` に応じ週次は月曜開始に集約。
4. **初期値取込**：品目ごとに `OH`（CALC-MRP-01）、`SR[t]`（CALC-MRP-02）、`SS` を設定。`PAB[0] = OH`。
5. **独立需要の収集**：受注（MTO）・予測/MPS（MTS）・安全库存割れを `prd_mrp_demand` に `demand_type` 別で INSERT し、`GR[item][bucket]` に加算。受注が予測を消費する設定では予測側を減算する。
6. **低层码ループ（品目×バケット）**：3.4〜3.8 を適用し、`NR>0` なら计划订单を生成して子件へ展開する。計算結果（GR/SR/OH/NR/PAB）を `prd_mrp_demand` に保存する。
7. **既存伝票との差異検査**：PO/WO/OS の現在日付・数量と MRP 必要量を比較し、`prd_mrp_action` を生成（3.9）。
8. **結果確定**：`prd_mrp_run` の件数・`run_status=40` に更新。ロック解放。画面/メール通知（計画員）。

### 3.4 净需求計算（バケット走査）

品目 `i` のバケット `t`（昇順）について：

```
available(t) = PAB(t-1) + SR(t)                        // 利用可能在庫
NR(t)        = max(0, GR(t) + SS(i) - available(t))    // 净需求
if NR(t) > 0:
    Q = lotSizing(NR(t), i)                            // 3.7
    PO(t) = newPlanOrder(qty=Q, due=t, ...)            // 3.8
    plannedReceipt(t) = Q
else:
    plannedReceipt(t) = 0
PAB(t) = available(t) + plannedReceipt(t) - GR(t)
```

- `PAB(0) = OH(i)`。
- `NR(t)` は 4 桁切上（`RoundingMode.CEILING`、scale=4）。端数 0.0001 未満は切り上げて欠品を防ぐ。
- `GR(t)` には独立需要（步骤 5）と従属需要（亲品目の展开で事前に加算済み）の合計が入る。**低层码昇順のため、品目 `i` を処理する時点で `GR` は確定している**（同一低层码の品目間に親子関係はない）。
- `SS(i) = safety_stock_qty`。`safety_stock_days > 0` の場合は `SS(i) = 日平均需要 × safety_stock_days` で動的算出（設定 `mrp.safety_stock.mode=QTY|DAYS`）。

### 3.5 需要源と独立需要の計上規則

| 需要源 | 計上先 | 需要日 | 数量 | 備考 |
|---|---|---|---|---|
| 受注（MTO） | `prd_mrp_demand`（`demand_type=10`、`source_type=10`） | 受注明細の `delivery_date` | 未出荷数量 | 受注変更 E07 で再計算 |
| 销售预测（MTS） | `demand_type=20`、`source_type=20` | `prd_demand_forecast.bucket_date` | `forecast_qty` | 受注消費設定時は受注分を控除 |
| MPS | `demand_type=20`、`source_type=20`（MPS 由来フラグを `source_no=MPS...`） | `prd_mps_line.plan_date` | `planned_qty` | MPS が予測より優先（設定） |
| 安全库存 | `demand_type=30`、`source_type=30` | 展望期末バケット | CALC-MRP-11 | 根拠を `source_no=SAFETY_STOCK` で保持 |
| 工单子件 | `demand_type=40`、`source_type=30` | 親 WO の `planned_start_date` | 未領料数（設定時のみ） | 既定 OFF（二重計上防止のため SR 扱い） |
| 计划订单子件 | `demand_type=50`、`source_type=40` | 親計画订单 `start_date` | `childQty` | MRP 内で生成 |
| 委外子件 | `demand_type=60`、`source_type=50` | 委外订单 `start_date` | 未発料数 | 既定 OFF（同上） |

### 3.6 现有库存・入荷预定・引当の取扱い

| 項目 | 取扱い | 理由 |
|---|---|---|
| 现有库存（OH） | `on_hand − 待検 − 凍結 − 品質保留` を利用可能在庫とする | 待検・凍結・品質保留は製造に使用できないため |
| 引当済（reserved） | 净需求から控除しない | 引当対象の需要は GR に含まれており、控除すると二重計上になる |
| 入荷预定（SR） | 確定済の PO/WO/OS の未入荷数量を入荷予定日に計上 | 発注済の補充を再発注しない |
| 安全库存 | 净需求に上乗せ（`+SS`） | 期末在庫を安全在庫以上に維持 |
| マイナス在庫 | 設定 `allow_negative_stock=false` のため発生しない。データ不整合で OH<0 の場合は 0 とみなし警告（`MSG-PRD-024`） | [08](../00-common/08-common-business-rules.md) 6.1 |

### 3.7 批量规则（Lot Sizing）

| `lot_sizing_rule` | 名称 | 計算式 | 適用場面 |
|---|---|---|---|
| `10` | L4L（Lot for Lot） | `Q = max(NR, min_order_qty)`。製造品は `Q = CEILING(NR ÷ yield_rate)` | 高価品・受注生産 |
| `20` | FOQ（固定批量） | `Q = CEILING(NR ÷ lot_size) × lot_size` | 段取り費が高い加工品 |
| `30` | 最小-最大（Min-Max） | `Q = 補充後在庫が max_order_qty になる量`（`PAB−GR` が `reorder_point_qty` 未満で発注）。`min_order_qty` 以上 | 標準件・汎用品 |
| `40` | 周期発注 | 発注周期 `fixed_lead_time_days` 日ごとにまとめて発注（周期日に NR を集約） | 定期便品 |
| `50` | 倍数切上 | `Q = max(min_order_qty, CEILING(NR ÷ order_multiple) × order_multiple)`。`max_order_qty` 超過時は分割 | 鋼材・電磁線など梱包単位あり |

- `min_order_qty`（最小起订量）、`order_multiple`（発注倍数）、`max_order_qty`（最大订单量）は全規則に共通で適用する（`0` は制約なし）。
- 分割時は `due_date` 昇順に必要分を割り当て、余剰分は最後の计划订单に寄せる。
- 製造品で `lot_sizing_rule` が L4L 以外の場合も `yield_rate` 補正を適用する（`Q = 規則適用後の Q ÷ yield_rate` → 4 桁切上）。

### 3.8 提前期と着手日逆算

```
start_date = subtractWorkdays(due_date, lead_time_days, workCenterCalendar)
```

| 品目区分 | 提前期の決定 | 使用カレンダー |
|---|---|---|
| 采购品（`material_type=10`） | `lead_time_days`（購買提前期） | 購買先の稼働カレンダーがないため**自社の工作日历**（`prd_work_center_calendar` の工場共通パターン）で逆算。非稼働日はスキップ |
| 製造品（`20`） | `production_lead_time_days`（未設定なら工艺路線の工数合計 ÷ 日能力 × 日数） | 製造部門の工作日历（工作中心カレンダー） |
| 委外品（`30`） | `lead_time_days`（往復輸送日数を含む） | 自社工場カレンダー |
| 虚拟件（`40`） | 提前期 0（透过展開） | — |

- 逆算で `start_date < run_date` となる場合は `start_date = run_date`（即時発注/着手）とし、`prd_mrp_action` に「発注遅延」警告を付す（BR-MRP-11）。
- 工序別オフセット（設定 `mrp.lead_time.operation_offset=true`）では、工艺路線の各工序の標準工数から工程別の着手日を算出し、工序ごとの子件必要日を設定する（Phase 2 拡張）。

### 3.9 动作消息の生成規則

| `action_type` | 名称 | 生成条件 | `suggested_*` の内容 | 対象 |
|---|---|---|---|---|
| `10` | 発注 | 采购品の计划订单生成（未転送） | `suggested_date=start_date`、`suggested_qty=Q` | 計画員→購買 |
| `20` | 製造 | 製造品/委外品の计划订单生成（未転送） | 同上 | 計画員→製造/購買 |
| `30` | 取消 | 前回実行の**未確認**计划订单で、今回の需要が消滅（同一品目・必要日の NR=0） | `suggested_qty=0` | 計画員 |
| `40` | 延期 | 既存 PO/WO/OS の現在日付が MRP の必要日より**遅い**（不足する） | `suggested_date=必要日`（前倒し） | 購買/製造 |
| `50` | 提前 | 既存 PO/WO/OS の現在日付が MRP の必要日より**早すぎる**（在庫過剰） | `suggested_date=必要日`（後ろ倒し） | 購買/製造 |
| `60` | 增量 | 既存 PO/WO/OS の数量が不足（同一品目・同一入荷日の不足） | `suggested_qty=必要量` | 購買/製造 |
| `70` | 减量 | 既存 PO/WO/OS の数量が過剰（在庫過剰・需要減） | `suggested_qty=適正量` | 購買/製造 |
| `80` | 安全库存不足 | `PAB` が全バケットで安全在庫を下回る、または補充後も不足が残る | `suggested_qty=不足量` | 計画員 |

- `action_message` は利用者向け文面を組み立てる（例：「発注日を 2026-11-05 に前倒ししてください（現在 2026-11-20）」）。
- 同一品目・同一对象・同一種類の动作消息は 1 件に集約する（重複排除）。
- 动作消息は**提案であり自動実行しない**（BR-MRP-12）。計画員が確認（20）または無視（30）し、実務は PUR/PRD の画面で実行する。

### 3.10 擬似コード（実装レベル）

```java
/**
 * MRP 全量実行。呼出元は BAT-PRD-001 または SCR-PRD-021。
 * トランザクション: 実行単位で 1 トランザクション（大量時は 1,000 品目ごとにコミット）。
 */
public MrpRunResult run(MrpRunCommand cmd) {
    // 0. 前処理
    advisoryLock(cmd.factoryId());                       // 取得できなければ MSG-PRD-029
    if (lowLevelCodeStale(cmd.factoryId())) recalcLowLevelCode(cmd.factoryId());
    MrpRun run = mrpRunRepository.create(cmd);           // run_status=10, 採番 MRP{YYMMDD}{3桁}
    try {
        // 1. 計画対象品目の抽出（低层码昇順）
        List<PlanningItem> items = planningRepo.findMrpTargets(cmd.factoryId())
                .stream().sorted(comparing(PlanningItem::lowLevelCode)
                        .thenComparing(PlanningItem::materialCode)).toList();

        // 2. バケット生成
        List<LocalDate> buckets = bucketBuilder.build(cmd.runDate(), cmd.horizonDays(), cmd.bucketType());

        // 3. 初期値（在庫・入荷预定・安全在庫）
        Map<Long, BigDecimal> onHand = inventoryQuery.fetchMrpOnHand(cmd.factoryId());   // CALC-MRP-01
        Map<ItemBucket, BigDecimal> scheduledReceipt = receiptQuery.fetchScheduledReceipts(cmd); // CALC-MRP-02
        Map<Long, BigDecimal> safetyStock = items.stream()
                .collect(toMap(PlanningItem::materialId, PlanningItem::safetyStockQty));

        // 4. 独立需要の収集
        DemandTable demand = new DemandTable();
        demand.addAll(salesQuery.fetchOpenOrderDemand(cmd, items));       // 受注
        demand.addAll(forecastQuery.fetchConfirmedForecast(cmd, items));  // 予測/MPS
        demand.applyForecastConsumption(cmd.consumeForecast());           // BR-MRP-02
        demand.addSafetyStockDemand(items, onHand, safetyStock, buckets); // CALC-MRP-11

        // 5. 低层码昇順ループ
        for (PlanningItem item : items) {
            BigDecimal pabPrev = onHand.getOrDefault(item.materialId(), ZERO);
            for (LocalDate t : buckets) {
                BigDecimal gr = demand.gross(item.materialId(), t);
                BigDecimal sr = scheduledReceipt.getOrDefault(key(item, t), ZERO);
                BigDecimal available = pabPrev.add(sr);
                BigDecimal nr = gr.add(safetyStock.get(item.materialId()))
                                  .subtract(available).max(ZERO).setScale(4, CEILING);

                BigDecimal planned = ZERO;
                if (nr.signum() > 0) {
                    BigDecimal qty = lotSizing.apply(nr, item);              // 3.7
                    LocalDate start = workdayCalendar.subtractWorkdays(
                            t, leadTimeDays(item), cmd.factoryId());         // CALC-MRP-10
                    MrpPlanOrder po = planOrderRepository.create(run, item, qty, start, t);
                    planned = qty;
                    actionService.generateReleaseAction(run, item, po);      // 10/20
                    explodeToChildren(run, item, po, demand);                // 3.11 子件展開
                }
                pabPrev = available.add(planned).subtract(gr);
                demandRepository.saveDemand(run, item, t, gr, sr, onHand.get(item.materialId()),
                        nr, pabPrev, safetyStock.get(item.materialId()), /*shortage*/ pabPrev.signum() < 0);
            }
        }

        // 6. 既存伝票との差異 → 延期/提前/增量/减量/取消
        actionService.generateRescheduleActions(run, cmd, items, scheduledReceipt);
        actionService.generateCancelActions(run, cmd, items, demand);      // 前回未確認計画订单
        actionService.generateSafetyStockWarnings(run, items);

        // 7. 完了
        mrpRunRepository.complete(run, countersOf(demand));
        return MrpRunResult.of(run);
    } catch (Exception e) {
        mrpRunRepository.fail(run, e);
        throw e;
    } finally {
        advisoryUnlock(cmd.factoryId());
    }
}

/** 子件展開：親の着手日を子件の需要日として GR に加算する */
private void explodeToChildren(MrpRun run, PlanningItem parent, MrpPlanOrder po, DemandTable demand) {
    if (parent.materialType() == VIRTUAL) {                 // 虚拟件は透過展開（自身の計画订单なし）
        for (BomLine child : bomQuery.children(parent.materialId(), parent.bomId())) {
            demand.addDependent(child.materialId(), po.startDate(),
                    po.qty().multiply(child.requiredQty())
                       .divide(child.baseQty(), 4, CEILING), child, parent);
        }
        return;
    }
    for (BomLine child : bomQuery.children(parent.materialId(), parent.bomId())) {
        BigDecimal childQty = po.qty()
                .multiply(child.requiredQty())
                .divide(child.baseQty(), 4, CEILING);        // CALC-MRP-09
        demand.addDependent(child.materialId(), po.startDate(), childQty, child, parent);
    }
}
```

### 3.11 子件展開の詳細

| # | ルール | 内容 |
|---|---|---|
| 1 | 展開量 | `childQty = parentQty × prd_bom_line.required_qty ÷ prd_bom.base_qty`（4 桁切上）。`required_qty` は `component_qty × (1+loss_rate)` を BOM 登録時に計算済み |
| 2 | 需要日 | 親計画订单の `start_date`（製造着手日）。工序別オフセット設定時は「子件の投入工序の着手日」 |
| 3 | 虚拟件 | `material_type=40`（虚拟件）は計画订单を作らず、子件を親の需要日で**透過展開**する（冷媒・接着剤等の中間構成用） |
| 4 | 替代料 | 既定では替代料を自動選択しない（未決 #9）。主料の在庫不足が `shortage_flag` で示され、計画員が手動で手配する |
| 5 | 循環参照 | 展開中に品目の再出現を検出したら中断（`MSG-PRD-010`）。発生時は BOM を修正して再実行 |
| 6 | 展開深さ | 最大 15 階層（`mrp.max.bom_depth=15`）。超過は警告して打ち切り |
| 7 | 多工厂 | 子件の供給工場が異なる場合（无锡→常州）、子件計画订单は**供給工場**の品目計画として生成し、需要日は親の着手日 − 輸送日数（設定 `mrp.transfer.days`）とする。Phase 2 で工場間需給を正式化 |

### 3.12 特殊処理

| ケース | 処理 | 備考 |
|---|---|---|
| 需要日が過去（逾期受注） | `run_date` バケットに集約。计划订单の `start_date=run_date`、动作消息に「即時発注/即時着手」を付す | 遅延可視化 |
| 同一品目が複数需要源 | GR に合算し、`prd_mrp_demand` は需要源別に行を保持（内訳の説明可能性） | — |
| 受注取消・数量減 | E08/E07 購読で需要を再登録し、次回実行で反映。计划订单の取消は动作消息 30 | — |
| 既存 WO の材料不足 | MRP は「不足分の追加発注」を計画订单として生成（WO の材料は SR で既に計上済み） | 材料不足は [02](02-work-order.md) 6.3 |
| 安全在庫の動的算出 | `safety_stock_days` 設定時は「直近 n 日平均需要 × 日数」で算出 | Phase 2 |
| シミュレーション実行 | `run_type=40`（模拟）は計画データを保存するが `plan_status=10` かつ「模拟」フラグを付し、転送不可 | 画面で識別 |

## 4. YE3 数値算例（示例値）

> 本算例は [90-data/bom-demo.md](../90-data/bom-demo.md) の BOM 数量が確定するまでの**設計検証用の示例値**であり、数値はすべて【示例値】。BOM の実数値が確定したら差し替える（未決 #10）。
> 実行条件：`run_date=2026-10-20`、展望期 90 日、日次バケット、工場 `CZ01`（総装）、受注消費＝しない（MTS と MTO を別需要として計上）。

### 4.1 前提データ

**需要（独立需要）**

| 需要源 | 品目 | 数量 | 需要日 |
|---|---|---|---|
| 受注 SO2610200001（MTO） | YE3-100L1-4 `3001000001` | 120 PCE | 2026-11-20 |
| 予測（MTS） | YE3-100L1-4 `3001000001` | 80 PCE | 2026-11-15 |
| 予測（MTS） | YE3-100L1-4 `3001000001` | 100 PCE | 2026-12-15 |

**在庫・入荷预定・計画パラメータ**

| 品目 | 现有库存 OH | 入荷预定 SR | 安全在庫 SS | 批量規則 | 提前期 |
|---|---|---|---|---|---|
| YE3-100L1-4 成品 | 35 PCE | 工单 WO2609280003：30 PCE（入荷 2026-11-05） | 20 PCE | L4L | 3 稼働日 |
| 定子总成（半成品） | 12 PCE | 工单 WO2610050002：20 PCE（入荷 2026-11-10） | 15 PCE | FOQ 50 | 2 稼働日 |
| 电工钢带 50W470 | 850.0000 KGM | PO2610010002：1,000 KGM（入荷 2026-11-08） | 500 KGM | 最小 1,000、倍数 500 | 15 日 |
| 电磁线 QZY-2/180 | 320.0000 KGM | なし | 200 KGM | L4L、最小 50 | 10 日 |

**BOM 抜粋（YE3-100L1-4、1 PCE あたり）**

| 階層 | 親品目 | 子品目 | 純使用量（net） | 损耗率 | 必要量（gross、`required_qty`） | 出典 |
|---|---|---|---|---|---|---|
| L1 | YE3-100L1-4 | `2001000004` 定子总成 | 1.0000 PCE | 0.0050 | 1.0050 | [bom-demo.md](../90-data/bom-demo.md) §3.1 |
| L1 | YE3-100L1-4 | `2002000004` 转子总成 | 1.0000 PCE | 0.0050 | 1.0050 | 同上 |
| L2 | 定子总成 | `2001000002` 定子铁心 | 1.0000 SET | 0.0050 | 1.0050 | §3.2 |
| L2 | 定子总成 | `2001000003` 定子绕组 | 1.0000 SET | 0.0100 | 1.0101 | 同上 |
| L3 | 定子铁心 | `2001000001` 定子冲片 | 1.0000 SET | 0.0100 | 1.0101 | 同上 |
| L3 | 定子绕组 | `1004000001` QZY-2/180 φ1.00 | 2.6000 KGM | 0.0300 | 2.6804 | 同上 |
| L4 | 定子冲片 | `1001000001` 50W470 电工钢 | 10.8000 KGM | 0.3000 | 15.4286 | §3.3 |
| L3 | 转子铁心 | `2002000001` 转子冲片 | 1.0000 SET | 0.0100 | 1.0101 | §3.2 |
| L4 | 转子冲片 | `1001000001` 50W470 电工钢 | 4.2000 KGM | 0.3000 | 6.0000 | §3.3 |

> 損耗率は比率（0.3000 = 30% の冲裁ロス）。[90-data/bom-demo.md](../90-data/bom-demo.md) §4 の定義どおり `gross = net ÷ (1 − loss_rate)`（`required_qty`）。素材段階の 50W470 は 1 台あたり net 15.0 KGM／gross 21.4286 KGM（定子 15.4286＋転子 6.0000）となる。

### 4.2 成品（YE3-100L1-4）の净需求計算

| バケット | GR | SR | 前バケット末 PAB | 利用可能 | NR = max(0, GR+SS−利用可能) | 计划订单（数量） | 期末 PAB |
|---|---|---|---|---|---|---|---|
| 2026-11-05 | 0 | 30 | 35 | 65 | max(0, 0+20−65)=0 | — | 65 |
| 2026-11-15 | 80 | 0 | 65 | 65 | max(0, 80+20−65)=**35** | 35（L4L） | 20 |
| 2026-11-20 | 120 | 0 | 20 | 20 | max(0, 120+20−20)=**120** | 120（L4L） | 20 |
| 2026-12-15 | 100 | 0 | 20 | 20 | max(0, 100+20−20)=**100** | 100（L4L） | 20 |

**计划订单（成品）**

| # | 数量 | 必要日（due） | 着手日（start = due − 3 稼働日） | 対応動作消息 |
|---|---|---|---|---|
| 1 | 35 PCE | 2026-11-15 | 2026-11-12 | 20 製造 |
| 2 | 120 PCE | 2026-11-20 | 2026-11-17 | 20 製造 |
| 3 | 100 PCE | 2026-12-15 | 2026-12-12 | 20 製造 |

> 稼働日逆算は CZ01 の工作日历（週日休、土曜は稼働日の場合あり）を使用。端数は示例。

### 4.3 定子总成（L1）の净需求計算

子件需要：成品計画订单 35/120/100 × `required_qty=1.0050` = 35.18 / 120.60 / 100.50（4 桁切上）。需要日は親の `start_date`（11-12/11-17/12-12）。

| バケット | GR | SR | 前末 PAB | 利用可能 | NR | 計画订单（FOQ 50） | 期末 PAB |
|---|---|---|---|---|---|---|---|
| 2026-11-10 | 0 | 20 | 12 | 32 | max(0, 0+15−32)=0 | — | 32 |
| 2026-11-12 | 35.18 | 0 | 32 | 32 | max(0, 35.18+15−32)=**18.18** | 50（FOQ で切上） | 46.82 |
| 2026-11-17 | 120.60 | 0 | 46.82 | 46.82 | max(0, 120.60+15−46.82)=**88.78** | 100（FOQ 2 個分） | 26.22 |
| 2026-12-12 | 100.50 | 0 | 26.22 | 26.22 | max(0, 100.50+15−26.22)=**89.28** | 100（FOQ 2 個分） | 25.72 |

**計画订单（定子总成）**

| # | 数量 | 必要日 | 着手日（−2 稼働日） | 動作消息 |
|---|---|---|---|---|
| 1 | 50 PCE | 2026-11-12 | 2026-11-10 | 20 製造 |
| 2 | 100 PCE | 2026-11-17 | 2026-11-15 | 20 製造 |
| 3 | 100 PCE | 2026-12-12 | 2026-12-10 | 20 製造 |

> 定子总成の安全在庫 15・FOQ 50 は算例を簡潔にするための【示例値】。実運用では [material-master.csv](../90-data/material-master.csv) の `safety_stock`（定子总成＝100）と [prd_material_planning] のロット規則を使用する。

### 4.4 电工钢带 50W470（L4）の净需求計算

子件需要：定子总成の計画订单 50/100/100 PCE。1 定子总成あたりの 50W470 必要量は、定子側（定子铁心 1.0050 × 定子冲片 1.0101 × 15.4286 ＝ 15.6632 KGM）＋転子側（转子铁心 1.0050 × 转子冲片 1.0101 × 6.0000 ＝ 6.0909 KGM）＝ **21.7541 KGM/定子总成**。需要日は定子总成の `start_date`（11-10 / 11-15 / 12-10）。

| バケット | GR | SR | 前末 PAB | 利用可能 | NR = max(0, GR+SS−利用可能) | 計画订单（最小 1,000・倍数 500） | 期末 PAB |
|---|---|---|---|---|---|---|---|
| 2026-11-08 | 0 | 1,000.00 | 850.00 | 1,850.00 | max(0, 0+500−1,850)=0 | — | 1,850.00 |
| 2026-11-10 | 50 × 21.7541 = 1,087.71 | 0 | 1,850.00 | 1,850.00 | max(0, 1,087.71+500−1,850)=0 | — | 762.29 |
| 2026-11-15 | 100 × 21.7541 = 2,175.41 | 0 | 762.29 | 762.29 | max(0, 2,175.41+500−762.29)=**1,913.12** | **2,000**（500 の倍数切上） | 586.88 |
| 2026-12-10 | 100 × 21.7541 = 2,175.41 | 0 | 586.88 | 586.88 | max(0, 2,175.41+500−586.88)=**2,088.53** | **2,500**（500 の倍数切上） | 911.47 |

**計画订单（电工钢）**

| # | 数量 | 必要日 | 発注日（−15 日） | 動作消息 |
|---|---|---|---|---|
| 1 | 2,000 KGM | 2026-11-15 | 2026-10-31 | 10 発注 |
| 2 | 2,500 KGM | 2026-12-10 | 2026-11-25 | 10 発注 |

> 安全在庫 500・提前期 15 日・ロット（最小 1,000／倍数 500）は説明用の【示例値】。実運用では [material-master.csv](../90-data/material-master.csv)（安全在庫 2,000 KGM、提前期 45 日）を使用する。なお [bom-demo.md](../90-data/bom-demo.md) §5.1 の「120 PCE → 2,571.43 KGM」は 1 台当たり gross を単純積上げした概算であり、厳密な多階展開では中間损耗の累積により 120 × 21.8629 ＝ 2,623.55 KGM となる（差約 2.0%）。

### 4.5 电磁线 QZY-2/180（L3）の净需求計算

1 定子总成あたりの必要量＝定子绕组 1.0101 × 2.6804 ＝ **2.7075 KGM**。

| バケット | GR | SR | 前末 PAB | 利用可能 | NR | 計画订单（L4L・最小 50） | 期末 PAB |
|---|---|---|---|---|---|---|---|
| 2026-11-10 | 50 × 2.7075 = 135.38 | 0 | 320.00 | 320.00 | max(0, 135.38+200−320)=**15.38** | 50（最小 50） | 234.62 |
| 2026-11-15 | 100 × 2.7075 = 270.75 | 0 | 234.62 | 234.62 | max(0, 270.75+200−234.62)=**236.13** | 236.13 | 200.00 |
| 2026-12-10 | 100 × 2.7075 = 270.75 | 0 | 200.00 | 200.00 | max(0, 270.75+200−200)=**270.75** | 270.75 | 200.00 |

### 4.6 动作消息の例（本算例で生成されるもの）

| # | 種別 | 品目 | 対象 | 内容 | 推奨操作 |
|---|---|---|---|---|---|
| 1 | 20 製造 | YE3-100L1-4 | 新規計画订单 35/120/100 | 11-12・11-17・12-12 着手 | 計画員が確認 → 工单転送 |
| 2 | 20 製造 | 定子总成 | 新規計画订单 50/100/100 | 11-10・11-15・12-10 着手 | 同上（无锡/常州の供給工場を確認） |
| 3 | 10 発注 | 电工钢 50W470 | 新規計画订单 2,000/2,500 KGM | 10-31・11-25 発注 | 計画員が確認 → 請購（PUR） |
| 4 | 10 発注 | 电磁线 QZY-2/180 | 新規計画订单 50/236.13/270.75 KGM | 10-31・11-05・11-30 発注 | 同上 |
| 5 | 50 提前（別シナリオ） | 电工钢 50W470 | 既存 PO2610010002（1,000 KGM、入荷予定 2026-11-08）が仕入先都合で **11-20 に遅延**した場合 | 11-10 の需要（1,087.71 KGM）に間に合わないため、`suggested_date=2026-11-08`（前倒し） | 購買が仕入先と納期交渉 |
| 6 | 30 取消 | 电工钢 50W470 | 前回実行の未確認計画订单 500 KGM（2026-11-20 必要、`ref_doc_type=50` 計画订单） | 本次計算で需要が 1,000 KGM に統合され、500 KGM の計画订单は不要 | 計画員が取消（`plan_status=90`） |
| 7 | 80 安全库存不足（別シナリオ） | 电磁线 QZY-2/180 | 受注が 120→150 PCE に増加したシナリオで、11-15 の期末在庫が安全在庫 200 KGM を下回る | `suggested_qty=不足量` | 計画員が `safety_stock_qty`・発注点を見直し |

> 表の数値は【示例値】。動作消息の文面・件数は実データにより変わる。

### 4.7 算例の検算ポイント

| # | 検算内容 | 期待結果 |
|---|---|---|
| 1 | 成品の全バケットで期末 PAB ≥ 安全在庫 20 | ○（各期末 20 以上） |
| 2 | 定子总成の必要量 = 成品計画订单 × 1.005（4 桁切上） | 35 → 35.18、120 → 120.60、100 → 100.50 |
| 3 | 电工钢の発注数量が最小起订量・倍数を満たす | 2,000 / 2,500（いずれも 500 の倍数かつ 1,000 以上） |
| 4 | 着手日が稼働日で、提前期を満たす | 成品 11-15−3=11-12 等 |
| 5 | 子件需要日 = 親の着手日 | 定子总成需要日 11-12/11-17/12-12 |
| 6 | 引当済を二重控除していない | OH は現有ベース（引当 0 のため差異なし） |

## 5. 計画订单の確認と転送（F-PRD-010 後半 / SCR-PRD-023）

### 5.1 画面項目定義（SCR-PRD-023 計画订单确认）

| No | 項目 ID | 項目名 | 区分 | 種別 | 型/桁 | 必須 | 初期値 | 入力チェック | データソース | DB 項目 | 権限 | 備考 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | run_no | 运行编号 | 検索 | 選択 | VARCHAR(32) | △ | 最新実行 | 存在チェック | `prd_mrp_run` | `mrp_run_no` | 参照のみ | — |
| 2 | material_code | 品目编码 | 検索/一覧 | テキスト | VARCHAR(64) | — | 空 | 前方一致 | `prd_mrp_plan_order` | `material_code` | 編集可 | — |
| 3 | order_type | 订单类型 | 検索/一覧 | 選択 | SMALLINT | — | 全 | 10/20/30 | 固定値 | `order_type` | 編集可 | 10 采购/20 制造/30 委外 |
| 4 | start_date | 着手日/発注日 | 一覧 | 日付 | DATE | ○ | MRP 計算値 | 过去日警告 | — | `start_date` | 編集可 | 計画員が調整可 |
| 5 | due_date | 必要日 | 一覧 | 日付 | DATE | ○ | MRP 計算値 | `due_date ≥ start_date` | — | `due_date` | 編集可 | — |
| 6 | order_qty | 数量 | 一覧 | 数値 | NUMERIC(18,4) | ○ | MRP 計算値 | > 0、発注倍数 | — | `order_qty` | 編集可 | 変更時は理由必須 |
| 7 | plan_status | 状態 | 一覧 | バッジ | SMALLINT | — | 10 | — | — | `plan_status` | 参照のみ | 10 提案/20 確認済/30 展開済 |
| 8 | parent_order | 親計画订单 | 一覧 | リンク | VARCHAR(64) | — | — | — | `parent_plan_order_id` | 参照のみ | 多阶展開の系譜 |
| 9 | shortage_flag | 欠品警告 | 一覧 | アイコン | BOOLEAN | — | — | — | `prd_mrp_demand` | 参照のみ | 赤表示 |
| 10 | action_list | 動作消息 | タブ | 一覧 | — | — | — | — | `prd_mrp_action` | — | 参照のみ | 10/20/30/40/50/60/70/80 |
| 11 | convert_btn | 転送ボタン | ボタン | — | — | — | — | 選択行 1 件以上、状態 10/20 | — | — | 編集可 | 権限 `production:mrp:confirm` |
| 12 | verify_btn | 一括確認 | ボタン | — | — | — | — | 同上 | — | — | 編集可 | 転送は別操作 |

### 5.2 イベント処理

| No | イベント | トリガ | 処理内容 | 呼出 API | 画面遷移 | 備考 |
|---|---|---|---|---|---|---|
| 1 | 検索 | 検索ボタン | 条件で `prd_mrp_plan_order` を検索（最新実行既定） | `GET /api/production/mrp-runs/{id}/plan-orders` | 同一画面 | — |
| 2 | 一括確認 | 確認ボタン | 選択行の `plan_status 10→20`、`confirmed_by/at` 更新 | `POST /api/production/mrp-plan-orders/batch-confirm` | 同一画面 | 承認不要（確認のみ） |
| 3 | 転送（製造） | 転送ボタン | `order_type=20` を工单へ転送。工单は `order_status=10` で作成し、BOM/工艺を展開 | `POST /api/production/mrp-plan-orders/{id}/convert-to-work-order` | SCR-PRD-009 | 受注との紐付け（`sales_order_id`）を引継ぎ |
| 4 | 転送（采购） | 転送ボタン | `order_type=10` を PUR の請購へ転送（同期 API） | `POST /api/production/mrp-plan-orders/{id}/convert-to-requisition` | 外部（PUR）画面へ導線 | PUR API 失敗時はロールバックし `MSG-PRD-028` |
| 5 | 転送（委外） | 転送ボタン | `order_type=30` を委外订单（10 草稿）へ転送 | `POST /api/production/mrp-plan-orders/{id}/convert-to-outsourcing` | SCR-PRD-018 | — |
| 6 | 数量修正 | 数量変更 | 理由（必須）を入力させ、`order_qty` を更新 | `PUT /api/production/mrp-plan-orders/{id}` | 同一画面 | 監査ログ必須 |
| 7 | 動作消息確認 | メッセージ行ダブルクリック | 対象伝票（PO/WO/OS）の詳細へ遷移 | — | 各詳細画面 | 権限なし時は遷移不可 |
| 8 | 動作消息を無視 | 無視ボタン | `action_status=30` | `POST /api/production/mrp-actions/{id}/ignore` | 同一画面 | 理由任意 |
| 9 | エクスポート | ボタン | Excel 出力（10,000 件超は非同期） | `POST /api/production/exports` | — | `production:report:export` |

### 5.3 転送時のデータマッピング

| 転送先 | MRP 側項目 | 転送先項目 | 変換 |
|---|---|---|---|
| 工单（F-PRD-005） | `material_id/code/name`、`order_qty`、`due_date`、`start_date` | `prd_work_order` の同名項目 | `order_qty` → `order_qty`。`source_type=10`、`source_id=plan_order_id` |
| 工单 | `parent_plan_order_id` | `parent_work_order_id`（転送順に解決） | 低层码昇順で転送すれば親が先に存在 |
| 请购（PUR） | `material_id`、`order_qty`、`start_date` | `pur_requisition_line` | 希望納期 = `start_date`。`source_type=MRP_PLAN_ORDER` |
| 委外订单（F-PRD-009） | `material_id`、`order_qty`、`due_date` | `prd_outsourcing_order_line` | 加工単価は MDM 購買価格から取得（未設定なら 0 で警告） |
| 全共通 | `mrp_run_id`、`plan_order_no` | `ext_data.mrp_*` または `source_no` | 追溯用に保持 |

### 5.4 転送のトランザクション・冪等性

- 転送は「計画订单の行ロック（`FOR UPDATE NOWAIT`）→ `plan_status` 検証（10/20 のみ）→ 転送先作成（同一 DB 内の別モジュール API）→ `converted_doc_*` 更新 → `plan_status=30`」を**1 トランザクション**で実行する。
- 転送先 API が失敗した場合は全体ロールバックし、`MSG-PRD-028`「転送に失敗しました。再実行してください」。二重転送はロックと `converted_doc_id IS NULL` 条件で防止する。
- 転送の一括処理は全件成功 or 全件失敗（[02 画面共通规格](../00-common/02-common-screen-spec.md) 4.3）。上限 500 件、超過は非同期ジョブ。

## 6. MPS・粗能力計画（F-PRD-011）

### 6.1 MPS（主生产计划）

| 項目 | 内容 |
|---|---|
| 目的 | MTS 製品の計画生産量を期間（月/週）単位で確定し、MRP の上位計画とする |
| 作成単位 | 工厂 × 期间（`period_code=YYYY-MM`）× 版本 |
| 入力 | 销售预测（`prd_demand_forecast`）、受注残（SAL）、安全库存、既存工单残、期首在庫 |
| 計算 | `计划生产量 = 预测 + 受注残 + 期末目标在庫 − 期首在庫 − 既存工单未完工数量`（4 桁切上、0 未満は 0）。期末目标在庫 = 安全库存 + 安全在庫日数分 |
| 確定 | `mps_status=30`（確定）で MRP の需要源となる。承認は WF（生産経理） |
| 画面 | SCR-PRD-024（MPS 一覧・編集・確定、粗能力タブ） |

### 6.2 粗能力計画（Rough-cut Capacity Planning）

```
需要工数[WC][日] = Σ(未完工工单工序の残工数) + Σ(计划订单×工艺標準工数)
  残工数 = planned_run_hours − actual_labor_hours（0 未満は 0）
  计划订单工数 = order_qty × Σ(run_time_per_unit) + setup_time（/ロット）
能力工数[WC][日] = prd_work_center_calendar.available_capacity（H 換算）
負荷率 = 需要工数 ÷ 能力工数
```

| 判定 | 条件 | 表示・対応 |
|---|---|---|
| 正常 | 負荷率 < 0.85 | 青 |
| 注意 | 0.85 ≤ 負荷率 ≤ 1.00 | 黄。残業・応援の検討 |
| 超過 | 負荷率 > 1.00 | 赤。日程調整・外注・能力増強。`MSG-PRD-050` |

粗能力の算例（YE3、11 月、【示例値】）：

| 工作中心 | 工序 | 計画数量 | 標準工数/台 | 必要工数 | 日能力 | 稼働日数 | 能力工数 | 負荷率 |
|---|---|---|---|---|---|---|---|---|
| WC005 嵌线 | 嵌线整形 | 255 台 | 0.35 h | 89.25 h | 16 h/日 | 20 日 | 320 h | 27.9% |
| WC009 试验 | 出厂试验 | 255 台 | 0.25 h | 63.75 h | 16 h/日 | 20 日 | 320 h | 19.9% |
| WC008 总装 | 总装 | 255 台 | 0.40 h | 102.00 h | 16 h/日 | 20 日 | 320 h | 31.9% |

> 上表は YE3 計画订单合計 255 台（35+120+100）を 11〜12 月に均等配分した概算【示例値】。実工数は [90-data/routing-demo.md](../90-data/routing-demo.md) を正とする。

### 6.3 日計画・排产（Phase 1 範囲）

- Phase 1 は**無限能力**で工单工序の `planned_start_date`/`planned_end_date` を算出し、画面で手動調整する（ドラッグ＆ドロップは Phase 2）。
- 工序日程の算出：`planned_start = 前工序完了 + queue_time`、`planned_end = planned_start + setup_time + run_time × 数量 ÷ 標準人数 ÷ 日稼働時間`（稼働日のみ）。
- 山積み（能力無視）で計画後、SCR-PRD-024 の粗能力タブで負荷率を確認し、必要に応じて工单の着手日を変更する。
- Phase 2 で有限能力スケジューリング（APS）とガントチャートを実装する（未決 #8）。

## 7. 入力チェック仕様

| No | チェック ID | 対象 | 種別 | 条件 | タイミング | メッセージ ID |
|---|---|---|---|---|---|---|
| 1 | CHK-PRD-005-01 | 工厂 | 必須 | 未選択不可 | 実行時 | `MSG-COM-040` |
| 2 | CHK-PRD-005-02 | 展望期 | 範囲 | 1〜365 日 | 実行時 | `MSG-COM-044` |
| 3 | CHK-PRD-005-03 | 実行日 | 範囲 | 過去 30 日以内・未来日不可 | 実行時 | `MSG-PRD-025` |
| 4 | CHK-PRD-005-04 | BOM 有无 | 業務 | 対象品目に有効 BOM がある（製造品） | 実行時 | `MSG-PRD-020` |
| 5 | CHK-PRD-005-05 | 低层码 | 業務 | 最新である（否則再計算） | 前処理 | —（自動再計算） |
| 6 | CHK-PRD-005-06 | 二重実行 | 排他 | 同一工厂で実行中でない | 実行時 | `MSG-PRD-029` |
| 7 | CHK-PRD-005-07 | 計画订单数量 | 相関 | 発注倍数・最小起订量を満たす | 確認/転送時 | `MSG-PRD-026` |
| 8 | CHK-PRD-005-08 | 計画订单日付 | 相関 | `start_date ≤ due_date` | 確認/転送時 | `MSG-COM-045` |
| 9 | CHK-PRD-005-09 | 転送対象 | 状態 | `plan_status IN (10,20)` かつ未転送 | 転送時 | `MSG-PRD-027` |
| 10 | CHK-PRD-005-10 | MPS 期間 | 一意 | 同一工厂×期間×版本の重複なし | MPS 保存時 | `MSG-COM-050` |
| 11 | CHK-PRD-005-11 | MPS 数量 | 範囲 | 0 以上 | MPS 保存時 | `MSG-COM-048` |

## 8. 権限・セキュリティ

| 種別 | 内容 |
|---|---|
| 画面権限 | SCR-PRD-021 `production:mrp:run`、SCR-PRD-022 `production:mrp:view`、SCR-PRD-023 `production:mrp:confirm`、SCR-PRD-024 `production:plan:update` |
| 操作権限 | 実行（run）、確認（confirm）、転送（confirm）、数量修正（update）、動作消息無視（confirm） |
| データ範囲 | 计划员は担当工厂のみ（`factory_id`）。生产经理は全社 |
| 項目権限 | 工费率・標準原価は `production:work-order:cost-view` なしでは非表示（[00-overview](00-overview.md) 10 章） |
| 監査ログ | MRP 実行（条件・件数）、計画订单の数量修正・転送・取消、動作消息の無視を記録（`sys_audit_log.operation_type=RUN/CONFIRM/UPDATE`） |
| 非機能 | 実行は非同期ジョブ（`POST /api/production/mrp-runs` → 202 + `jobId`）。進捗は `GET /api/production/jobs/{jobId}`。実行中は同一工厂の再実行を拒否 |

## 9. 性能・非機能

| 項目 | 目標 | 前提 |
|---|---|---|
| MRP 全量実行（品目 8,000、需要 15 万行、展望 90 日） | 10 分以内 | 低层码順・バケット処理・BOM/在庫のバルク取得、1,000 品目ごとにコミット |
| MRP 結果照会（品目 1 件、90 バケット） | 1 秒以内 | `idx_prd_mrp_demand_run_mat` |
| 計画订单一覧（1,000 件） | 2 秒以内 | `idx_prd_mrp_plan_order_run_mat` |
| 一括転送（500 件） | 60 秒以内 | 1 トランザクション（超過は非同期） |
| 粗能力表示（工作中心 80 × 60 日） | 3 秒以内 | `prd_capacity_load` スナップショット利用 |

## 10. テスト観点

| No | 観点 ID | 分類 | 観点 | 期待結果 |
|---|---|---|---|---|
| 1 | TST-F-PRD-010-01 | 正常系 | 受注・予測・安全在庫から净需求と计划订单が生成される | 4.2 の算例どおりの数量・日付 |
| 2 | TST-F-PRD-010-02 | 正常系 | 入荷预定（PO/WO）が净需求から控除される | SR 分だけ発注が減る |
| 3 | TST-F-PRD-010-03 | 境界値 | 净需求がちょうど 0（在庫が需要＋安全在庫と一致） | 计划订单を生成しない |
| 4 | TST-F-PRD-010-04 | 境界値 | 需要が 0 で在庫のみ | 计划订单なし、PAB=OH |
| 5 | TST-F-PRD-010-05 | 異常系 | BOM なし製造品 | エラー停止、`MSG-PRD-020`、部分結果を保存 |
| 6 | TST-F-PRD-010-06 | 異常系 | BOM 循環参照 | エラー停止、`MSG-PRD-010` |
| 7 | TST-F-PRD-010-07 | 正常系 | 低层码昇順で処理され、子件需要が親の着手日に計上される | 4.3/4.4 の日付 |
| 8 | TST-F-PRD-010-08 | 正常系 | 批量规则（L4L/FOQ/最小/倍数）が適用される | 50/100/1,000/1,500 |
| 9 | TST-F-PRD-010-09 | 正常系 | 提前期が工作日历で逆算される（非稼働日をスキップ） | 11-15−3 稼働日 |
| 10 | TST-F-PRD-010-10 | 異常系 | 同一工厂で二重実行 | ロック失敗、`MSG-PRD-029` |
| 11 | TST-F-PRD-010-11 | 正常系 | 再実行で新世代が作成され、旧計画订单は残る | `mrp_run_no` 増加、旧 `plan_status=10` のまま |
| 12 | TST-F-PRD-010-12 | 正常系 | 動作消息（取消/延期/提前/增量/减量/安全库不足）が正しく生成される | 4.6 の例 |
| 13 | TST-F-PRD-010-13 | 正常系 | 計画订单の転送で工单/請購/委外が作成され、二重転送できない | `converted_doc_*` 設定、2 回目は `MSG-PRD-027` |
| 14 | TST-F-PRD-010-14 | 権限 | 権限なしユーザの実行・転送 | 403、`MSG-COM-030` |
| 15 | TST-F-PRD-010-15 | 排他 | 同一計画订单の同時転送 | 後勝ちせずエラー |
| 16 | TST-F-PRD-011-01 | 正常系 | MPS が予測・受注・在庫から計算される | 6.1 の式どおり |
| 17 | TST-F-PRD-011-02 | 正常系 | 粗能力の負荷率が計算され、超過が赤表示される | 6.2 の例 |
| 18 | TST-F-PRD-011-03 | 境界値 | 能力 0（カレンダー未設定） | 警告、負荷率は算出不能表示 |

## 11. 未決事項

| # | 事項 | 理由 | 暫定仕様 | 担当 | 期限 |
|---|---|---|---|---|---|
| 1 | 受注が予測を消費するか（`mrp.forecast.consume`） | MTS/MTO 混在の運用ルールが未確定。二重計上のリスク | 既定 `false`（受注と予測を別需要として計上）。MTS 品目のみ `true` を推奨 | PRD + SAL | 2026-11-15 |
| 2 | 既存工单の未領料子件を MRP 需要に含めるか | 二重計上防止のため既定 OFF。ただし「未計画の追加需要」の検出が弱い | 設定 `mrp.include.wo_remaining=false`。Phase 2 で「計画外需要レポート」として可視化 | PRD | 2026-12-10 |
| 3 | 工序別リードタイムオフセット（子件必要日の工程単位分解） | Phase 1 は開始日一括。現場の投入タイミングと乖離 | 設定 `mrp.lead_time.operation_offset=false`。Phase 2 で工艺路線の工序順に分解 | PRD + 技術部 | 2027-03-31 |
| 4 | 多工厂需給（无锡→常州の半成品供給）の MRP 取扱い | Phase 1 は工場別 MRP ＋ 輸送日数補正。工場間の需給調整は手動 | `mrp.transfer.days=2`（示例）。Phase 2 で集中 MRP | PRD + INV | 2027-03-31 |
| 5 | 安全在庫の動的算出（日数ベース） | 需要変動係数・サービス水準の設計が必要 | `safety_stock_days=0`（固定量モード）を既定。Phase 2 で動的モード | PRD + 営業 | 2027-03-31 |
| 6 | 計画订单の承認要否（確認のみ vs WF 承認） | 少額の自動発注を許すか運用次第 | 確認（20）のみで転送可。金額閾値超過は WF 承認（[00-overview](00-overview.md) 2.1） | PRD | 2026-11-30 |
| 7 | 需給調整（需給会議）用のレポート・画面の範囲 | 経営会議向けサマリは RPT 域と重複 | 本域は MRP 結果一覧と動作消息に限定。サマリは RPT 域へ委譲 | PRD + RPT | 2026-12-20 |

## 12. 改訂履歴

| 版数 | 日付 | 変更内容 | 変更者 |
|---|---|---|---|
| v1.0 | 2026-10-20 | 初版：需要源 6 種、净需求・PAB 算式、低层码順展開、批量規則 5 種、提前期逆算、動作消息 8 種、擬似コード、YE3 算例（成品/定子总成/电工钢/电磁线、動作消息 7 例）、計画订单確認・転送、MPS・粗能力、入力チェック 11、テスト観点 18、未決 7 | production-designer |


| v1.1 | 2026-10-20 | 红队修复第2轮（REV-001/002/003/004/012 等）：INV 単一採番への整合（MII/MIR/FGI/OSI/OSR は INV 所有、PRD は request_no＋stock_doc_id/stock_doc_no 参照）、E15 resultCode/batchNo/warehouseId、E24 stockStatus=10 待検→E15 合格で 20 可用、原価サンプル 120 PCE／材料 79,187.55（標準 79,194.00・価格差異 −6.45）／人工 6,450.00／費用 7,740.00／93,377.55（778.15）、工单結案を 40＋closed_at に統一（45 廃止）、INV API 参照・工费率所有権 | production-designer |
