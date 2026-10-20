# 库龄・补货・库存报表 详细设计书（在庫滞留・補充発注・在庫帳票 詳細設計書）

| 項目 | 内容 |
|---|---|
| 文書名 | 库龄・补货・库存报表 详细设计书（在庫滞留・補充発注・在庫帳票 詳細設計書） |
| 文書番号 | DSN-INV-007 |
| 版数 | v1.0 |
| 作成日 | 2026-10-20 |
| 作成者 | inventory-designer |
| 承認者 | 未承認（レビュー待ち） |
| 状態 | ドラフト（レビュー中） |
| 関連文書 | [業務域概要](00-overview.md) / [在庫照会](01-stock-query.md) / [原価](05-costing.md) / [月結](06-reservation-barcode-close.md) / [帳票・バッチ](92-report-batch-design.md) / 10-analytics 域（报表分析） |

---

## 1. 機能概要

### 1.1 対象機能

| 機能 ID | 機能名 | 概要 | 画面 ID | 帳票 ID | 優先度 |
|---|---|---|---|---|---|
| F-INV-015 | 库龄与呆滞分析 | 庫齢区分（0-30/31-60/61-90/91-180/181-365/365+）別の数量・金額、呆滞料判定、庫齢スナップショット | SCR-INV-020 | PRT-INV-011 | P1 |
| F-INV-016 | 安全库存与补货建议 | 安全在庫・再訂貨点・推奨発注量の算出、補貨建議一覧、PUR への受渡し | SCR-INV-021 | PRT-INV-015 | P1 |
| F-INV-021 | 库存报表 | 收发存汇总・明細帳・流水表・回転率・追溯報告・残高表（域内操作帳票） | SCR-INV-003、020 | PRT-INV-009〜014、016 | P0 |
| F-INV-022 | 组装拆卸 | 組立・分解の在庫処理（Phase 2 概要） | — | — | P2 |
| F-INV-023 | 寄售库存 | 仕入先寄售・顧客寄售の在庫管理（Phase 2 概要） | — | — | P2 |

### 1.2 帳票とデータソース

| 帳票 ID | 帳票名 | 主データソース | 生成方式 | 詳細 |
|---|---|---|---|---|
| PRT-INV-009 | 库存收发存汇总表 | `inv_stock_summary`（月结）/ `inv_stock_txn_line`（即時） | 同期照会 or 非同期出力 | [92](92-report-batch-design.md) |
| PRT-INV-010 | 库存明细账（台账） | `inv_stock_txn_line` + `inv_stock_balance` | 同期照会 | [01](01-stock-query.md) 4.6、[92](92-report-batch-design.md) |
| PRT-INV-011 | 库龄分析表 | `inv_age_snapshot` / `inv_cost_layer` | 同期照会（スナップショット優先） | 本文 4.2、[92](92-report-batch-design.md) |
| PRT-INV-012 | 库存周转率表 | `inv_stock_summary` | 月次バッチ + 照会 | 本文 2.5、[92](92-report-batch-design.md) |
| PRT-INV-013 | 库存事务流水表 | `inv_stock_txn` / `_line` | 同期照会 | [01](01-stock-query.md) 4.5、[92](92-report-batch-design.md) |
| PRT-INV-014 | 批次追溯报告 | `inv_batch_genealogy` + `inv_stock_txn_line` | 同期照会 | [04](04-batch-serial-status.md) 4.2 |
| PRT-INV-015 | 安全库存・补货建议表 | `inv_replenishment` | 日次バッチ + 照会 | 本文 4.3、[92](92-report-batch-design.md) |
| PRT-INV-016 | 库存余额表（月末） | `inv_stock_balance`（月结時点） | 月结バッチ | [92](92-report-batch-design.md) |

---

## 2. 業務要件・業務ルール

### 2.1 前提条件

| # | 前提条件 | 成立しない場合の挙動 |
|---|---|---|
| 1 | 物料マスタに安全在庫・リードタイム・MOQ が設定済 | 未設定は補貨建議対象外（`MSG-INV-016` 警告） |
| 2 | 庫齢分析は `inv_age_snapshot`（日次）または `inv_cost_layer` が存在する | スナップショット未生成時はコスト層から即時集計（性能劣化） |
| 3 | 月次帳票は対象期間が `40 CLOSED` であること | 未关账期間は「暫定値」表示（`MSG-INV-045`） |
| 4 | ユーザに `inventory:report:view`/`inventory:replenishment:view` がある | `403` |

### 2.2 レポート境界（10-analytics との非衝突）

**本域（05-inventory）は「在庫業務の操作・管理に直接使う帳票（域内操作帳票）」のみを設計する。** 経営分析・横断KPI・ダッシュボードは RPT 域（10-analytics）が担い、RPT は本域のデータを**読み取り専用**で参照する。

| 帳票・指標 | 所管 | 備考 |
|---|---|---|
| 库存查询（現存量・可用量） | **INV**（F-INV-001） | 操作画面 |
| 库存明细账（台账） | **INV**（PRT-INV-010） | 会計帳簿の補助。操作・監査用 |
| 收发存汇总表 | **INV**（PRT-INV-009） | 月结の根拠帳票。RPT の「库存分析」は本帳票のデータを参照 |
| 库龄分析表（明細・区分集計） | **INV**（PRT-INV-011） | 滞留処置の実務用。RPT の「庫齢構成比 KPI」は本データを参照 |
| 库存周转率表（期間・年化） | **INV**（PRT-INV-012） | 計算式を本文 2.5 で唯一化。RPT は同式を再利用 |
| 库存事务流水表 | **INV**（PRT-INV-013） | 監査・照合用 |
| 批次追溯報告 | **INV**（PRT-INV-014） | 品質・回収対応用 |
| 盘点表・差異報告・入出庫伝票 | **INV**（PRT-INV-001〜008、017） | 伝票・ラベル |
| 经营驾驶舱・库存分析ダッシュボード | **RPT**（F-RPT-004） | INV の表を参照。INV は設計しない |
| 呆滞率・在庫回転の KPI トレンド・ベンチマーク | **RPT**（F-RPT-003/004） | 指標定義は RPT。計算式は本域 2.5 と同一にする |
| 需要予測・安全在庫の最適化 | **RPT/SAL**（Phase 2） | INV は「安全在庫パラメータ」を保持し、提案は RPT が行う |

> **重複禁止**：同一の集計値（例：月次在庫金額・回転率）を INV と RPT で二重に定義しない。RPT は `inv_stock_summary` / `inv_age_snapshot` / `inv_replenishment` を**参照するのみ**とする（[09 §11](../00-common/09-cross-domain-flow.md) の RPT は業務データを更新しない）。

### 2.3 庫齢・呆滞の業務ルール

| # | ルール | 根拠 | 関連項目 |
|---|---|---|---|
| BR-AG-01 | **庫齢** = 基準日 − 入庫日（コスト層の `received_date`）。移動平均法では批次内の入庫が複数あるため、**FIFO 仮定**で残存数量を最も古い層から割り当てて庫齢を算出する（会計上の原価計算には影響しない） | 本設計、[05](05-costing.md) PRC-INV-017-05 | `age_days` |
| BR-AG-02 | 庫齢区分：`0〜30` / `31〜60` / `61〜90` / `91〜180` / `181〜365` / `366〜` 日の 6 区分（`sys_param.inv_age_buckets` で変更可） | 本設計 | `age_bucket` |
| BR-AG-03 | **呆滞料**の判定：`庫齢 > inv_slow_moving_days`（既定 365 日【示例値】）かつ、直近 `inv_slow_moving_out_days`（既定 180 日）以内に出庫実績が無い在庫 | 本設計 | `is_slow_moving` |
| BR-AG-04 | 引当済数量も庫齢に含める（出庫予定があっても滞留している事実は変わらない）。ただし「引当済」列を別途表示し、滞留の実質を判断できるようにする | 本設計 | `qty_reserved` |
| BR-AG-05 | 庫齢スナップショット（`inv_age_snapshot`）は日次で生成（`BAT-INV-003`）。過去日の庫齢はスナップショットから参照（再計算しない） | 本設計 | バッチ |
| BR-AG-06 | 庫齢レポートの金額は**現在の在庫金額**（移動平均）ベース。層別の金額は `remaining_amount` を使用 | 本設計 | `amount` |
| BR-AG-07 | 呆滞料の処置（削減・転用・廃棄）は本域で起票せず、状態変換（凍結）・報廃（`SC_OUT`）・他用途への引当で対応する。処置の意思決定は RPT/経営会議 | 本設計 | [04](04-batch-serial-status.md) |

### 2.4 安全在庫・補貨建議の業務ルール

| # | ルール | 根拠 | 関連項目 |
|---|---|---|---|
| BR-RP-01 | 安全在庫は `mdm_material.safety_stock_qty`（MDM 管理）。本域は変更しない（建議のみ） | [00-overview](00-overview.md) 2.3 | `safety_stock` |
| BR-RP-02 | **平均日耗** = 直近 `inv_consumption_days`（既定 90 日）の出庫数量（`SI`+`MII`+`OSI`+`AOO`）÷ 日数。実績が無い場合は直近 365 日で代替 | 本設計 | `avg_daily_usage` |
| BR-RP-03 | **再訂貨点（ROP）** = 安全在庫 + 平均日耗 × 調達リードタイム（`mdm_material.purchase_lead_time_days`） | [00-overview](00-overview.md) 2.3 | `reorder_point` |
| BR-RP-04 | **推奨発注量** = `MAX(0, 平均日耗 × (LT + 発注間隔) + 安全在庫 − 現在可用 − 発注残)`。発注間隔 = `inv_order_cycle_days`（既定 30 日）。MOQ とロット倍数（`mdm_material.min_order_qty`/`lot_size`）で切上げ | 本設計 | CALC-03/04 |
| BR-RP-05 | 発注残（`on_order_qty`）は PUR の未入荷 PO 数量（PUR の参照 API または `pur_purchase_order_line` の参照ビュー）。本域は読取のみ | [09 §11](../00-common/09-cross-domain-flow.md) | — |
| BR-RP-06 | 発注点を下回った時点で「建議」を生成し、在庫が発注点以上の場合は建議を出さない（0 件）。欠品中（可用 0）は「欠品」区分で優先表示 | 本設計 | `replenishment_status` |
| BR-RP-07 | 建議は**日次バッチ（BAT-INV-004）**で生成し、同日の再実行は上書き（冪等）。手動生成も可 | 本設計 | バッチ |
| BR-RP-08 | 建議の**PUR への受渡し**：本域は建議データの生成まで。PUR の「计划采购（F-PUR-011）」が本域の API を参照して請購（PR）を作成する。**本域から PUR の伝票を直接作成しない**（更新責任の一元化） | [09 §2.2](../00-common/09-cross-domain-flow.md) | — |
| BR-RP-09 | 発注不要の物料（`mdm_material.planning_policy = 30`（手動）、受注生産品で都度手配等）は建議対象外。`sys_param.inv_replenish_exclude_category` で分類除外可 | 本設計 | — |
| BR-RP-10 | 建議の状態：`10 建議`（生成済）/`30 已转请购`（PUR が PR を作成）/`40 已忽略`（計画員が理由付きで除外）。日次バッチは `10` の建議のみ更新し、`30/40` は保持 | 本設計 | `replenishment_status` |

### 2.5 レポート口径（唯一の算式）

| # | 帳票・指標 | 算式・口径 | データソース |
|---|---|---|---|
| CALC-01 | 收发存（期初） | 前期間末の `closing_qty/closing_amount`（初回は期首繰越） | `inv_stock_summary` |
| CALC-02 | 收发存（入出庫） | 期間内の `direction=+1` 合計（入庫）、`direction=−1` 合計（出庫）。`txn_status=30/90` を対象、`is_reversal` は方向で自然相殺 | `inv_stock_txn_line` |
| CALC-03 | 收发存（期末） | `期末 = 期初 + 入庫 − 出庫`（数量・金額とも）。検証式は CALC-04（[06](06-reservation-barcode-close.md)） | `inv_stock_summary` |
| CALC-04 | 庫齢 | `age_days = 基準日 − cost_layer.received_date`、`age_bucket` に分類 | `inv_cost_layer` / `inv_age_snapshot` |
| CALC-05 | 呆滞判定 | `age_days > inv_slow_moving_days かつ 直近 inv_slow_moving_out_days の出庫 = 0` | `inv_age_snapshot` + `inv_stock_txn_line` |
| CALC-06 | 库存周转率（回） | `期間出庫成本 ÷ 平均在庫金額`。平均在庫 =（期初金額 + 期末金額）÷ 2 | `inv_stock_summary` |
| CALC-07 | 在庫回転日数 | `平均在庫金額 ÷ 期間出庫成本 × 期間日数` | 同上 |
| CALC-08 | 年化回転率 | `CALC-06 × 365 ÷ 期間日数`（月次の場合 ×12） | 同上 |
| CALC-09 | 在庫金額構成比 | `対象金額 ÷ 総在庫金額`（倉庫別・分類別・庫齢区分別） | `inv_stock_summary` / `inv_age_snapshot` |
| CALC-10 | 発注点（ROP） | `安全在庫 + 平均日耗 × LT` | `inv_replenishment` |
| CALC-11 | 推奨発注量 | `MAX(0, 平均日耗 × (LT + 発注間隔) + 安全在庫 − 可用 − 発注残)` → MOQ/ロット倍数で切上げ | `inv_replenishment` |
| CALC-12 | 欠品率 | `可用量 < 安全在庫` の物料数 ÷ 在庫管理対象物料数 | `inv_replenishment` |
| CALC-13 | 盘点准确率 | `1 − Σ|差異金額| ÷ Σ帳簿金額`（[03](03-transfer-count.md) CALC-05） | `inv_stocktake` |

### 2.6 Phase 2 概要（F-INV-022 组装拆卸・F-INV-023 寄售库存）

**F-INV-022 组装拆卸（Phase 2）**

| 項目 | 方針 |
|---|---|
| 目的 | 部品を組み立てて製品化（組立）、製品を分解して部品を回収（分解）する業務。リサイクル・修理・キット販売で発生 |
| 在庫処理 | 専用の取引種別を**追加しない**（[09 §7.1](../00-common/09-cross-domain-flow.md) の 19 種のみ）。**組立 = 部品の `MII`（消費）+ 製品の `FGI`（入庫）**、**分解 = 製品の `MII`（消費）+ 部品の `AOI`（入庫）** で表現する。原価は `MII` の出庫原価を `FGI`/`AOI` の入庫原価へ按分（FIN が指示） |
| 前提 | PRD に「組立工单」「分解工单」の工单種別を追加（Phase 2）。本域は工单からの E22/E24 を既存どおり処理する |
| 未決 | 組立・分解の専用取引種別の是非、キット販売（親子品目）の在庫表現 → [13 未決](#13-未決事項) |

**F-INV-023 寄售库存（Phase 2）**

| 項目 | 方針 |
|---|---|
| 目的 | ①仕入先寄售（当社倉庫に保管するが所有権は仕入先、使用時に仕入計上）、②顧客寄售（当社製品を顧客先に保管、顧客使用時に売上計上） |
| 在庫表現 | `inv_stock_balance` に **所有区分（`owner_type`：1 自社 / 2 仕入先寄售 / 3 顧客寄售）** と `owner_id` を追加予定。倉庫マスタの倉庫種別（`WAREHOUSE_TYPE=CONSIGNMENT`）で寄售倉を識別する。Phase 1 では列を追加しない（マイグレーションで追加） |
| 取引 | 仕入先寄售：引取り（自社在庫へ振替）・使用（仕入計上）。顧客寄售：出荷（在庫から寄售へ振替）・使用報告（売上計上）。いずれも既存 19 種で表現できないため、Phase 2 で 09 の拡張（新取引種別または `owner_type` 付き既存種別）を Lead と協議する |
| 会計 | 寄售は「所有権移転時」に仕入・売上を計上するため、FIN の仕訳タイミングが通常と異なる。Phase 2 で FIN と共同設計 |
| 未決 | 新取引種別の要否、`owner_type` の追加範囲、寄售在庫の評価方法 → [13 未決](#13-未決事項) |

---

## 3. 関連機能

| 関係 | 機能 ID | 機能名 | 関係内容 |
|---|---|---|---|
| 上流 | F-INV-001/013 | 在庫照会・流水 | データソース |
| 上流 | F-INV-017 | 成本計算 | 金額・層・平均単価 |
| 上流 | F-INV-020 | 月结 | 收发存汇总の生成 |
| 下流 | F-PUR-011 | 计划采购（PUR） | 補貨建議の参照・請購作成 |
| 下流 | F-RPT-004 | 库存分析（RPT） | `inv_stock_summary`/`inv_age_snapshot` の参照 |
| 参照 | F-MDM-001 | 物料 | 安全在庫・LT・MOQ・ロット倍数 |

---

## 4. 画面設計

### 4.1 画面一覧

| 画面 ID | 画面名 | 類型 | 概要 |
|---|---|---|---|
| SCR-INV-020 | 库龄・呆滞分析 | 一覧検索 | 庫齢区分別の数量・金額、呆滞料一覧、明細ドリルダウン |
| SCR-INV-021 | 安全库存・补货建议 | 一覧検索 | 安全在庫・発注点・推奨発注量、建議の生成・PUR 連携 |

### 4.2 画面項目定義（SCR-INV-020 库龄・呆滞分析）

#### 4.2.1 検索条件

| No | 項目 ID | 項目名 | 種別 | 型/桁 | 必須 | 初期値 | 入力チェック | DB 項目 |
|---|---|---|---|---|---|---|---|---|
| 1 | `baseDate` | 基準日 | 日付 | DATE | ○ | 当日 | 実在日付、スナップショット存在日 | `snapshot_date` |
| 2 | `warehouseIds` | 倉庫 | 複数選択 | BIGINT[] | — | 既定 | コード存在 | `warehouse_id` |
| 3 | `categoryCode` | 物料分類 | 選択 | VARCHAR(4) | — | 空 | 存在 | 結合 |
| 4 | `materialKeyword` | 物料 | テキスト | VARCHAR(100) | — | 空 | 部分一致 | 結合 |
| 5 | `ageBuckets` | 庫齢区分 | 複数チェック | VARCHAR(16)[] | — | 全 | `0-30`…`366-` | `age_bucket` |
| 6 | `onlySlowMoving` | 呆滞のみ | チェック | BOOLEAN | — | false | — | `is_slow_moving` |
| 7 | `groupBy` | 集計単位 | 選択 | VARCHAR(16) | ○ | `MATERIAL` | `MATERIAL`/`WAREHOUSE`/`BATCH` | — |

#### 4.2.2 一覧項目

| No | 列 ID | 列名 | 表示形式 | 備考 |
|---|---|---|---|---|
| 1 | `warehouseCode` | 倉庫 | コード | — |
| 2 | `materialCode` | 物料コード | リンク | 照会へ |
| 3 | `materialName/spec` | 品名・仕様 | テキスト | — |
| 4 | `batchNo` | 批次号 | テキスト | 集計単位=BATCH のみ |
| 5 | `ageBucket` | 庫齢区分 | バッジ | 6 区分 |
| 6 | `qtyOnHand` | 在庫数量 | `#,##0.0000 UOM` | — |
| 7 | `qtyReserved` | 引当数量 | 同上 | — |
| 8 | `amount` | 在庫金額 | `CNY #,##0.00` | 権限なし非表示 |
| 9 | `amountRatio` | 金額構成比 | `%` | CALC-09 |
| 10 | `ageDays` | 平均庫齢 | 日 | 加重平均 |
| 11 | `isSlowMoving` | 呆滞 | アイコン | 赤=呆滞 |
| 12 | `lastOutDate` | 最終出庫日 | `yyyy-MM-dd` | — |

**集計表示**：庫齢区分別の合計（数量・金額・構成比）を画面上部に表示。合計が総在庫と一致しない場合は `MSG-INV-046`（集計差異）。

**イベント**

| No | イベント | トリガ | 処理内容 | 呼出 API |
|---|---|---|---|---|
| 1 | 検索 | 検索ボタン | 庫齢スナップショットまたは層から集計 | `GET /api/inventory/reports/age` |
| 2 | 明細ドリルダウン | 行クリック | 批次・コスト層別の明細 | `GET /api/inventory/costs/layers` |
| 3 | 照会へ | 物料リンク | SCR-INV-001 へ遷移 | — |
| 4 | 印刷 | 「印刷」 | PRT-INV-011 | `POST /api/inventory/reports/age/print` |
| 5 | エクスポート | 「エクスポート」 | 非同期 Excel | `POST /api/inventory/exports` |
| 6 | 呆滞処置 | 「処置」 | 状態変換（凍結）・報廃申請へ | [04](04-batch-serial-status.md) 画面 |

### 4.3 画面項目定義（SCR-INV-021 安全库存・补货建议）

| No | 項目 ID | 項目名 | 種別 | 型/桁 | 必須 | 初期値 | 入力チェック | DB 項目 |
|---|---|---|---|---|---|---|---|---|
| 1 | `warehouseIds` | 倉庫 | 複数選択 | BIGINT[] | — | 既定 | 存在 | `warehouse_id` |
| 2 | `categoryCode` | 分類 | 選択 | VARCHAR(4) | — | 空 | 存在 | — |
| 3 | `materialKeyword` | 物料 | テキスト | VARCHAR(100) | — | 空 | 部分一致 | — |
| 4 | `statuses` | 建議状態 | 複数選択 | SMALLINT[] | — | 10 | 10/30/40 | `replenishment_status` |
| 5 | `onlyShortage` | 欠品のみ | チェック | BOOLEAN | — | false | — | `available_qty < safety_stock` |
| 6 | `supplierId` | 既定仕入先 | 表示 | BIGINT | — | — | — | `default_supplier_id` |

**一覧列**：物料 / 仕様 / 倉庫 / 単位 / 現在可用 / 引当 / 発注残 / 安全在庫 / 平均日耗 / LT / 発注点 / 推奨発注量 / 推奨発注日 / 欠品区分 / 既定仕入先 / 状態

**イベント**

| No | イベント | トリガ | 処理内容 | 呼出 API |
|---|---|---|---|---|
| 1 | 検索 | 検索ボタン | 建議一覧取得 | `GET /api/inventory/replenishments` |
| 2 | 再生成 | 「建議生成」 | 日次バッチを手動実行（非同期） | `POST /api/inventory/replenishments/generate` |
| 3 | 請購へ | 「転送」 | PUR の請購登録画面へ遷移（建議 ID を引渡し）、建議を `30 已转请购` に更新 | — / `POST /api/inventory/replenishments/{id}/mark-ordered` |
| 4 | 無視 | 「無視」 | 理由必須で `40 已忽略` | `POST /api/inventory/replenishments/{id}/ignore` |
| 5 | 印刷 | 「印刷」 | PRT-INV-015 | `POST /api/inventory/replenishments/print` |
| 6 | エクスポート | 「エクスポート」 | 非同期 | `POST /api/inventory/exports` |

### 4.4 表示制御

| 条件 | 対象 | 制御 |
|---|---|---|
| `inventory:cost:view` なし | 在庫金額・構成比 | 非表示 |
| 期間が未关账 | 月次帳票の値 | 「暫定値」バッジ + `MSG-INV-045` |
| 建議が `30/40` | 転送・無視ボタン | 非表示（状態保持） |
| データ範囲外 | 行 | 非表示 |

---

## 5. 入力チェック仕様

| No | チェック ID | 対象 | 種別 | 条件 | タイミング | メッセージ ID |
|---|---|---|---|---|---|---|
| 1 | CHK-INV-015-01 | 基準日 | 業務 | スナップショットが存在する日（未来日不可） | 検索時 | `MSG-INV-046` |
| 2 | CHK-INV-015-02 | 庫齢区分 | 値域 | 定義済みの区分のみ | 検索時 | `MSG-COM-042` |
| 3 | CHK-INV-015-03 | 集計整合 | 業務 | 区分合計 = 総在庫（差異 0） | 検索後 | `MSG-INV-046` |
| 4 | CHK-INV-016-01 | 建議生成 | 業務 | 安全在庫・LT 設定済の物料のみ対象 | バッチ時 | `MSG-INV-016`（警告） |
| 5 | CHK-INV-016-02 | 無視理由 | 必須 | 5 文字以上 | 無視時 | `MSG-COM-040` |
| 6 | CHK-INV-016-03 | 月次帳票 | 業務 | 対象期間 `40 CLOSED`（未关账は暫定表示） | 出力時 | `MSG-INV-045` |

---

## 6. 処理詳細

### 6.1 処理一覧

| 処理 ID | 処理名 | 契機 | トランザクション | 排他 |
|---|---|---|---|---|
| PRC-INV-015-01 | 庫齢スナップショット生成 | BAT-INV-003（日次） | 要 | スナップショット単位で洗替（当日重複実行可） |
| PRC-INV-015-02 | 庫齢分析照会 | SCR-INV-020 | 不要（読取） | — |
| PRC-INV-016-01 | 補貨建議生成 | BAT-INV-004（日次）/手動 | 要 | 建議の洗替（`10 建議` のみ） |
| PRC-INV-016-02 | 建議→請購連携 | SCR-INV-021 / PUR | 要 | 建議行の楽観排他 |
| PRC-INV-021-01 | 收发存汇总照会 | SCR/帳票 | 不要 | — |
| PRC-INV-021-02 | 在庫回転率計算 | BAT-INV-008（月次） | 要 | 期間単位 |
| PRC-INV-021-03 | 在庫明細帳・流水表出力 | SCR-INV-003/002 | 不要 | — |
| PRC-INV-021-04 | 帳票 PDF 生成 | 印刷 | 非同期ジョブ | — |

### 6.2 処理手順（正常系）

**PRC-INV-015-01 庫齢スナップショット生成（BAT-INV-003）**

1. 基準日（当日）を決定する。当日分の `inv_age_snapshot` を DELETE する（冪等）。
2. `inv_cost_layer` の残存層（`remaining_qty > 0`、`status ≠ 90`）を、倉庫×物料×批次×`received_date` 単位で集計する。
3. 各層について `age_days = 基準日 − received_date`、`age_bucket` を判定する（BR-AG-02）。
4. `inv_age_snapshot` に INSERT する（`snapshot_date, warehouse_id, material_id, batch_no, received_date, age_days, age_bucket, qty, amount`）。
5. 呆滞判定（BR-AG-03）：`age_days > inv_slow_moving_days` かつ直近 `inv_slow_moving_out_days` の出庫が 0 の組を `is_slow_moving=true` にする。
6. 在庫数量との整合を検証する：`Σ層残数量 = inv_stock_balance.qty_on_hand`（差異があればアラート `MSG-INV-046`）。

**PRC-INV-016-01 補貨建議生成（BAT-INV-004）**

1. 対象物料を抽出する（`is_mrp_planned=true`、安全在庫 > 0、`status=1`、除外分類を除く）。
2. 各物料×倉庫について以下を算出する：
   - `avg_daily_usage`（BR-RP-02、直近 90 日の出庫 ÷ 90）
   - `available_qty`（[00-overview](00-overview.md) 2.3 の算式）
   - `on_order_qty`（PUR の未入荷 PO 数量、参照）
   - `reorder_point = safety_stock + avg_daily_usage × lead_time_days`（CALC-10）
   - `suggested_qty = MAX(0, avg_daily_usage × (LT + 発注間隔) + 安全在庫 − available − on_order)` → MOQ 未満は MOQ、ロット倍数で切上げ（CALC-11）
   - `suggested_order_date` = 当日（または `need_date − LT`）
3. 建議がある物料のみ `inv_replenishment` に INSERT する。既存の `10 建議` は DELETE → INSERT（洗替）。
4. 欠品（`available < safety_stock`）は `is_shortage=true` で優先表示する。
5. 通知（站内、計画/購買）を送る（[08 §13.3](../00-common/08-common-business-rules.md)）。

**PRC-INV-016-02 建議→請購連携**

1. 建議行の状態を検証する（`10 建議` のみ）。
2. PUR の請購登録画面へ遷移し、建議 ID を引き渡す（PUR が PR を作成）。
3. PR 作成後、PUR からコールバック（または画面操作）で `30 已转请购`、`purchase_request_no` を記録する。
4. 建議の再生成時、`30/40` は保持する（BR-RP-07）。

**PRC-INV-021-02 在庫回転率計算（BAT-INV-008）**

1. 対象期間の `inv_stock_summary` を取得する（月结済のみ）。
2. `avg_inventory_amount = (opening_amount + closing_amount) ÷ 2`。
3. `turnover = out_amount ÷ avg_inventory_amount`（CALC-06）、`turnover_days = avg ÷ out_amount × 期間日数`（CALC-07）、`annualized = turnover × 365 ÷ 期間日数`（CALC-08）。
4. 結果を `inv_stock_summary.turnover_rate` 等に保存するか、照会時に都度計算する（Phase 1 は都度計算、帳票で出力）。
5. 平均在庫 0 の場合は「算出不能」と表示（0 除算しない）。

**PRC-INV-021-01 收发存汇总照会**

1. 期間・倉庫・分類・物料で `inv_stock_summary` を検索する（月结済み）。
2. 未关账期間の場合：`inv_stock_txn_line` から即時集計し、「暫定値」フラグを立てる（`MSG-INV-045`）。
3. 期初・入庫・出庫・期末（数量・金額）と平均単価を返す。検証式 CALC-03 で内部チェックする。
4. 帳票（PRT-INV-009）は PDF/Excel で出力する（非同期ジョブ可）。

### 6.3 例外処理

| No | 異常条件 | 検知箇所 | 処理 | ロールバック | メッセージ ID |
|---|---|---|---|---|---|
| 1 | スナップショット未生成 | 照会 | 即時集計にフォールバック + 警告 | — | `MSG-INV-046` |
| 2 | 層残と残高の不一致 | バッチ | アラート、月结を中断候補に | — | `MSG-INV-046` |
| 3 | 安全在庫・LT 未設定 | 建議生成 | 対象外（警告ログ） | — | `MSG-INV-016` |
| 4 | 未关账期間の帳票 | 出力 | 暫定表示 | — | `MSG-INV-045` |
| 5 | 平均在庫 0 の回転率 | 計算 | 算出不能表示 | — | `MSG-INV-046` |
| 6 | 建議の二重生成 | バッチ | 洗替で防止 | — | — |

### 6.4 冪等性・再実行

- 庫齢スナップショット・補貨建議は当日分を洗替するため再実行可（冪等）。
- 建議→請購の状態更新は楽観排他 + `purchase_request_no` の設定で二重連携を防止。
- 帳票出力は読み取りのみ。

---

## 7. API 設計

### 7.1 API 一覧

| # | メソッド | パス | 権限 | 概要 |
|---|---|---|---|---|
| 1 | GET | `/api/inventory/reports/stock-summary` | `inventory:report:view` | 收发存汇总（期間×倉庫×物料） |
| 2 | GET | `/api/inventory/reports/age` | `inventory:report:view` | 庫齢分析（区分別・明細） |
| 3 | GET | `/api/inventory/reports/slow-moving` | `inventory:report:view` | 呆滞料一覧 |
| 4 | GET | `/api/inventory/reports/turnover` | `inventory:report:view` | 在庫回転率（期間・年化） |
| 5 | POST | `/api/inventory/reports/{reportCode}/print` | `inventory:report:export` | 帳票 PDF 出力 |
| 6 | GET | `/api/inventory/replenishments` | `inventory:replenishment:view` | 補貨建議一覧 |
| 7 | POST | `/api/inventory/replenishments/generate` | `inventory:replenishment:generate` | 建議生成（202 ジョブ） |
| 8 | POST | `/api/inventory/replenishments/{id}/mark-ordered` | `inventory:replenishment:generate` | 請購作成済の記録 |
| 9 | POST | `/api/inventory/replenishments/{id}/ignore` | `inventory:replenishment:generate` | 建議の無視（理由必須） |
| 10 | GET | `/api/inventory/replenishments/export` | `inventory:replenishment:view` | 建議 CSV/Excel 出力（PUR 連携用） |

### 7.2 代表 API 詳細

#### 7.2.1 `GET /api/inventory/reports/stock-summary?periodCode=2026-10&warehouseIds=...&groupBy=MATERIAL`

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "periodCode": "2026-10",
    "provisional": false,
    "list": [
      {
        "warehouseCode": "WH01",
        "materialCode": "1001000001",
        "materialName": "冷轧无取向电工钢带",
        "uomCode": "KGM",
        "openingQty": "100.0000",
        "openingAmount": "500.00",
        "inQty": "800.0000",
        "inAmount": "4520.00",
        "outQty": "200.0000",
        "outAmount": "1107.18",
        "closingQty": "700.0000",
        "closingAmount": "3912.82",
        "avgUnitCost": "5.589743",
        "turnoverRate": "0.5100"
      }
    ],
    "total": {
      "openingAmount": "500.00",
      "inAmount": "4520.00",
      "outAmount": "1107.18",
      "closingAmount": "3912.82"
    }
  }
}
```

#### 7.2.2 `GET /api/inventory/reports/age?baseDate=2026-10-20&onlySlowMoving=true`

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "baseDate": "2026-10-20",
    "buckets": [
      { "ageBucket": "0-30", "qty": "0.0000", "amount": "0.00", "ratio": "0.0000" },
      { "ageBucket": "31-60", "qty": "320.0000", "amount": "1789.60", "ratio": "0.4573" },
      { "ageBucket": "61-90", "qty": "380.0000", "amount": "2123.22", "ratio": "0.5427" },
      { "ageBucket": "91-180", "qty": "0.0000", "amount": "0.00", "ratio": "0.0000" },
      { "ageBucket": "181-365", "qty": "0.0000", "amount": "0.00", "ratio": "0.0000" },
      { "ageBucket": "366-", "qty": "0.0000", "amount": "0.00", "ratio": "0.0000" }
    ],
    "slowMovingCount": 0,
    "details": []
  }
}
```

> 上記は构造例（【示例値】）。区分合計と総在庫の整合は CHK-INV-015-03 で検証する。

#### 7.2.3 `GET /api/inventory/replenishments?statuses=10&onlyShortage=false`

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "list": [
      {
        "id": "1845678901234568601",
        "warehouseCode": "WH01",
        "materialCode": "1001000001",
        "materialName": "冷轧无取向电工钢带",
        "uomCode": "KGM",
        "availableQty": "480.0000",
        "onOrderQty": "2000.0000",
        "safetyStock": "2000.0000",
        "avgDailyUsage": "260.0000",
        "leadTimeDays": 45,
        "reorderPoint": "13700.0000",
        "suggestedQty": "1820.0000",
        "suggestedOrderDate": "2026-10-20",
        "isShortage": true,
        "replenishmentStatus": 10,
        "defaultSupplierCode": "S000001"
      }
    ],
    "total": 1
  }
}
```

> 数値は CALC-10/11 の計算例（【示例値】）：平均日耗 260 × 45 + 安全在庫 2,000 = 13,700（ROP）、推奨 = 260 × (45+30) + 2,000 − 480 − 2,000 = 1,820。

#### 7.2.4 `POST /api/inventory/replenishments/generate`

```json
{ "warehouseIds": ["1845000000000000001"], "asOfDate": "2026-10-20" }
```

レスポンス（202）：`{ "jobId": "...", "status": "QUEUED" }`。完了後 `GET /api/inventory/jobs/{jobId}` で `{created: 12, updated: 3, skipped: 40}` を返す。

---

## 8. データ更新仕様

| テーブル | 操作 | 更新項目 | 更新条件 | トリガ |
|---|---|---|---|---|
| `inv_age_snapshot` | DELETE/INSERT | `snapshot_date, warehouse_id, material_id, batch_no, received_date, age_days, age_bucket, qty, amount, is_slow_moving` | `snapshot_date` 単位で洗替 | BAT-INV-003 |
| `inv_replenishment` | DELETE/INSERT/UPDATE | `warehouse_id, material_id, available_qty, on_order_qty, safety_stock, avg_daily_usage, lead_time_days, reorder_point, suggested_qty, suggested_order_date, is_shortage, replenishment_status, purchase_request_no` | `10 建議` のみ洗替、`30/40` は保持 | BAT-INV-004 / 画面 |
| `inv_stock_summary` | 参照のみ | — | — | — |
| `sys_job_execution` | INSERT | バッチ実行履歴（件数・所要時間・エラー） | — | 各バッチ |
| `sys_audit_log` | INSERT | REPORT_EXPORT / REPLENISH_IGNORE | — | 出力・無視 |

---

## 9. エラー処理・メッセージ

| メッセージ ID | 種別 | 本文 | 発生条件 | 利用者への対処 |
|---|---|---|---|---|
| `MSG-INV-016` | W | 物料 {0} 未设置安全库存或提前期，无法生成补货建议。 | マスタ未設定 | MDM で設定 |
| `MSG-INV-045` | W | 该期间尚未关账，显示的是暂定数据。 | 未关账期間の帳票 | 月结後に再出力 |
| `MSG-INV-046` | W/E | 库龄/库存数据不一致：{0}。 | 集計差異・スナップショット未生成 | バッチ再実行・調査 |
| `MSG-COM-052` | E | 查询条件过于宽泛，请增加筛选条件。 | 件数超過 | 条件追加 |
| `MSG-COM-040` | E | 请输入必填项「{0}」。 | 無視理由未入力 | 入力 |
| `MSG-COM-002` | I | 删除しました。 | — | — |

---

## 10. 権限・セキュリティ

| 種別 | 内容 |
|---|---|
| 画面権限 | 庫齢・帐票：`inventory:report:view`、出力：`inventory:report:export`。補貨：`inventory:replenishment:view/generate` |
| 項目権限 | 在庫金額・構成比は `inventory:cost:view` が必要 |
| データ範囲 | 倉庫/工場のデータ範囲を強制 |
| 監査ログ | 帳票出力（種別・条件・出力者）、建議の無視（理由）、転送を記録 |
| 個人情報 | 取引先名は表示可。担当者個人情報は含めない |

---

## 11. 性能・非機能

| 項目 | 目標値 | 前提 |
|---|---|---|
| 庫齢照会（1 万行） | 3 秒以内 | `inv_age_snapshot(snapshot_date, warehouse_id, material_id)` 索引 |
| 庫齢スナップショット生成（日次 10 万層） | 5 分以内 | バッチ INSERT |
| 收发存照会（100 行） | 2 秒以内 | `inv_stock_summary` 索引 |
| 補貨建議生成（8,000 物料） | 10 分以内 | バッチ。出庫実績は 90 日分の索引 |
| 帳票 PDF（1,000 行） | 30 秒以内 | 非同期ジョブ |
| 回転率計算（12 期間×倉庫×物料） | 5 分以内 | 月次バッチ |

---

## 12. テスト観点

| No | 観点 ID | 分類 | 観点 | 期待結果 |
|---|---|---|---|---|
| 1 | TST-F-INV-015-01 | 正常系 | 庫齢区分別集計 | 合計が総在庫と一致（CHK-INV-015-03） |
| 2 | TST-F-INV-015-02 | 正常系 | 呆滞料の抽出 | 365 日超かつ 180 日出庫なしのみ抽出 |
| 3 | TST-F-INV-015-03 | 境界値 | 庫齢 30/31 日 | それぞれ `0-30`/`31-60` に分類 |
| 4 | TST-F-INV-015-04 | 異常系 | スナップショット未生成日 | 即時集計 + `MSG-INV-046` |
| 5 | TST-F-INV-016-01 | 正常系 | 発注点・推奨量の計算 | CALC-10/11 の値と一致 |
| 6 | TST-F-INV-016-02 | 境界値 | 可用量 = 発注点 | 建議 0 件（発注不要） |
| 7 | TST-F-INV-016-03 | 正常系 | MOQ・ロット倍数切上げ | MOQ 未満は MOQ、倍数に切上げ |
| 8 | TST-F-INV-016-04 | 正常系 | 建議→請購連携 | 建議が `30 已转请购` になり、PR 番号が記録 |
| 9 | TST-F-INV-016-05 | 異常系 | 安全在庫未設定 | 対象外 + 警告 |
| 10 | TST-F-INV-021-01 | 正常系 | 收发存汇总（期初＋入−出＝期末） | 数量・金額とも一致 |
| 11 | TST-F-INV-021-02 | 正常系 | 回転率（月次・年化） | CALC-06/08 と一致 |
| 12 | TST-F-INV-021-03 | 異常系 | 未关账期間の帳票 | 「暫定値」表示 + `MSG-INV-045` |
| 13 | TST-F-INV-021-04 | 正常系 | 明細帳・流水表の PDF | レイアウト・ページ番号・合計が正しい |
| 14 | TST-F-INV-021-05 | 権限 | `inventory:cost:view` なし | 金額列が出力されない |
| 15 | TST-F-INV-021-06 | 整合 | RPT 参照データとの一致 | `inv_stock_summary` の値と RPT 集計が一致 |

---

## 13. 未決事項

| # | 事項 | 理由 | 暫定仕様 | 担当 | 期限 |
|---|---|---|---|---|---|
| 1 | 安全在庫の倉庫別上書き | 現在は `mdm_material.safety_stock_qty`（全社 1 値）。倉庫別・工場別の安全在庫が必要になる可能性 | Phase 1 は全社 1 値。Phase 2 で `mdm_material_warehouse.safety_stock` を追加 | MDM 担当 / inventory-designer | 2026-12-31 |
| 2 | 発注残（`on_order_qty`）の参照方法 | PUR の未入荷 PO 残を本域がどう参照するか（同期 API か参照ビューか） | 同期参照（PUR の公開サービス）で取得。09 §11 の「同期参照」に従う | Lead / purchase-designer / inventory-designer | 2026-10-30 |
| 3 | 庫齢の FIFO 仮定 | 移動平均法では層別の原価が実際の払出と一致しないため、庫齢は FIFO 仮定となる | 分析目的のみ FIFO 仮定を明記。会計・原価には影響しない | inventory-designer / finance-designer | 2026-11-15 |
| 4 | 组装拆卸の取引表現 | 専用取引種別を追加できないため、MII/FGI/AOI の組合せで表現する方針 | Phase 2 で Lead と 09 を拡張（工单種別 + 按分ルール）。Phase 1 は設計のみ | Lead / production-designer / inventory-designer | 2027-06-30 |
| 5 | 寄售库存の所有区分と取引 | 新取引種別が必要になる可能性。`owner_type` の追加範囲・会計処理も未確定 | Phase 2 で FIN と共同設計。Phase 1 は設計のみ（テーブル変更なし） | Lead / finance-designer / inventory-designer | 2027-06-30 |
| 6 | 在庫回転率の分母 | 平均在庫金額を（期初＋期末）÷2 とするか、月平均在庫（日次平均）とするか | 月次は（期初＋期末）÷2。日次平均は Phase 2（RPT と統一） | inventory-designer / RPT 担当 | 2026-11-30 |

---

## 14. 改訂履歴

| 版数 | 日付 | 変更内容 | 変更者 |
|---|---|---|---|
| v1.0 | 2026-10-20 | 初版：庫齢・呆滞、安全在庫・補貨建議、域内帳票の口径と RPT 境界、组装拆卸・寄售の Phase 2 概要、画面 2 件、API 10 件、テスト観点 | inventory-designer |
