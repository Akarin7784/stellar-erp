# 报表分析 API 设计书（报表分析 API 設計書）

| 項目 | 内容 |
|---|---|
| 文書名 | 报表分析 API 设计书（报表分析 API 設計書） |
| 文書番号 | DSN-RPT-091 |
| 版数 | v1.1 |
| 作成日 | 2026-10-20 |
| 作成者 | analytics-designer（報表分析分野担当） |
| 承認者 | 未承認（レビュー待ち） |
| 状態 | ドラフト（レビュー中） |
| 関連文書 | [業務域概要](00-overview.md) / [KPI 設計](01-dashboard.md) / [域分析](02-domain-analysis.md) / [DB 設計](90-db-design.md) / [API 共通规格](../00-common/03-common-api-spec.md) |

---

## 1. 適用範囲

本設計書は RPT 域が提供する分析 API（`/api/report/**`）を定義する。共通の認証（Sa-Token）、`Result<T>`、ページング、エラーコード体系は [API 共通规格](../00-common/03-common-api-spec.md) を正とする。

- **すべて読み取り専用**（例外：KPI 定義・目標・ルール・订阅・コメント・出力ジョブの登録/更新）。業務データを更新する API は提供しない。
- 権限は `report:{resource}:{action}`。行レベルはロールのデータ範囲を SQL に強制注入する。
- 一覧はサーバサイドページング（`pageNum`/`pageSize`、最大 200）。分析の集計 API はページングせず、明細 API のみページングする。
- 金額・数量・ID は文字列、日付は `yyyy-MM-dd`、日時は ISO 8601（+08:00）。
- 出力（Excel/PDF）は非同期ジョブ（202 + `jobId`）。

---

## 2. API 一覧

### 2.1 驾驶舱・KPI

| # | メソッド | パス | 権限 | 概要 | 関連機能 |
|---|---|---|---|---|---|
| 1 | GET | `/api/report/dashboard` | `report:dashboard:view` | 驾驶舱データ | F-RPT-001 |
| 2 | GET | `/api/report/dashboards/{id}` | `report:dashboard:view` | レイアウト | F-RPT-001 |
| 3 | PUT | `/api/report/dashboards/{id}` | `report:dashboard:update` | レイアウト保存 | F-RPT-001 |
| 4 | GET | `/api/report/kpis` | `report:kpi:view` | KPI 一覧 | F-RPT-002 |
| 5 | GET | `/api/report/kpis/{code}` | `report:kpi:view` | KPI 定義 | F-RPT-002 |
| 6 | POST | `/api/report/kpis` | `report:kpi:update` | KPI 定義登録 | F-RPT-002 |
| 7 | PUT | `/api/report/kpis/{code}` | `report:kpi:update` | KPI 定義更新（版数 +1） | F-RPT-002 |
| 8 | GET | `/api/report/kpis/{code}/trend` | `report:kpi:view` | KPI トレンド | F-RPT-001 |
| 9 | GET | `/api/report/kpi-targets` | `report:kpi:view` | 目標一覧 | F-RPT-002 |
| 10 | PUT | `/api/report/kpi-targets` | `report:kpi:update` | 目標更新 | F-RPT-002 |
| 11 | POST | `/api/report/kpi-comments` | `report:dashboard:view` | コメント登録 | F-RPT-001 |
| 12 | GET | `/api/report/quality-checks` | `report:quality:view` | 整合性検査結果 | F-RPT-007 |

### 2.2 域分析

| # | メソッド | パス | 権限 | 概要 | 関連機能 |
|---|---|---|---|---|---|
| 13 | GET | `/api/report/analysis/sales` | `report:sales:view` | 销售分析 | F-RPT-003 |
| 14 | GET | `/api/report/analysis/purchase` | `report:purchase:view` | 采购分析 | F-RPT-003 |
| 15 | GET | `/api/report/analysis/inventory` | `report:inventory:view` | 库存分析 | F-RPT-004 |
| 16 | GET | `/api/report/analysis/production` | `report:production:view` | 生产分析 | F-RPT-003 |
| 17 | GET | `/api/report/analysis/finance` | `report:finance:view` | 财务分析 | F-RPT-003 |
| 18 | GET | `/api/report/analysis/details` | `report:analysis:view` | ドリルダウン明細 | F-RPT-003/004 |
| 19 | POST | `/api/report/analysis/exports` | `report:analysis:export` | 分析出力（非同期） | F-RPT-009 |
| 20 | GET | `/api/report/analysis/exports/{jobId}` | `report:analysis:export` | 出力ジョブ状態 | F-RPT-009 |
| 21 | GET | `/api/report/analysis/exports/{jobId}/files/{fileId}` | `report:analysis:export` | 出力ファイル DL | F-RPT-009 |
| 22 | GET | `/api/report/favorites` | `report:analysis:view` | お気に入り一覧 | F-RPT-009 |
| 23 | POST | `/api/report/favorites` | `report:analysis:view` | お気に入り登録 | F-RPT-009 |

### 2.3 予警・订阅・抽出

| # | メソッド | パス | 権限 | 概要 | 関連機能 |
|---|---|---|---|---|---|
| 24 | GET | `/api/report/warnings` | `report:warning:view` | 予警一覧 | F-RPT-005 |
| 25 | GET | `/api/report/warnings/{id}` | `report:warning:view` | 予警詳細 | F-RPT-005 |
| 26 | POST | `/api/report/warnings/{id}/read` | `report:warning:view` | 既読 | F-RPT-005 |
| 27 | POST | `/api/report/warnings/{id}/assign` | `report:warning:update` | 担当者設定 | F-RPT-005 |
| 28 | POST | `/api/report/warnings/{id}/resolve` | `report:warning:update` | 解決 | F-RPT-005 |
| 29 | GET | `/api/report/warning-rules` | `report:warning:view` | ルール一覧 | F-RPT-005 |
| 30 | POST | `/api/report/warning-rules` | `report:warning:update` | ルール登録 | F-RPT-005 |
| 31 | PUT | `/api/report/warning-rules/{code}` | `report:warning:update` | ルール更新 | F-RPT-005 |
| 32 | GET | `/api/report/subscriptions` | `report:subscription:view` | 订阅一覧 | F-RPT-006 |
| 33 | POST | `/api/report/subscriptions` | `report:subscription:update` | 订阅登録 | F-RPT-006 |
| 34 | PUT | `/api/report/subscriptions/{id}` | `report:subscription:update` | 订阅更新 | F-RPT-006 |
| 35 | POST | `/api/report/subscriptions/{id}/send` | `report:subscription:update` | 即時配信 | F-RPT-006 |
| 36 | POST | `/api/report/subscriptions/{id}/toggle` | `report:subscription:update` | 停止/再開 | F-RPT-006 |
| 37 | GET | `/api/report/subscriptions/{id}/logs` | `report:subscription:view` | 配信履歴 | F-RPT-006 |
| 38 | GET | `/api/report/etl/jobs` | `report:etl:view` | 抽取ジョブ一覧 | F-RPT-008 |
| 39 | POST | `/api/report/etl/recalculate` | `report:etl:run` | 再計算（非同期） | F-RPT-008 |

---

## 3. API 詳細

### 3.1 GET /api/report/dashboard（驾驶舱）

| 項目 | 内容 |
|---|---|
| 目的 | 期間・工場・ロールに応じた KPI カードとチャートを返す |
| 権限 | `report:dashboard:view` |
| パラメータ | `periodCode`（必須、`YYYY-MM`）、`factoryId`（任意）、`dashboardCode`（任意） |
| キャッシュ | 60 秒（同一ユーザ・同一条件）。KPI 更新時に無効化 |
| 関連テーブル | `rpt_kpi_snapshot`、`rpt_kpi_target`、`rpt_kpi_definition`、`rpt_warning_event` |

**レスポンス項目**

| 項目 | 型 | 説明 |
|---|---|---|
| `periodCode` | string | 期間 |
| `snapshotStatus` | int | 10 暫定 / 40 確定 |
| `cards[]` | array | `kpiCode`、`kpiName`、`value`、`unit`、`targetValue`、`achievementRate`、`direction`、`denominatorValue`、`numeratorValue` |
| `charts[]` | array | `chartCode`、`type`、`series[]` |
| `warnings` | array | 直近 5 件の予警（`eventNo`、`severity`、`message`） |

**エラー**：95001（期間の KPI 未生成）、400（期間不正）。

### 3.2 GET /api/report/kpis/{code}/trend（KPI トレンド）

| 項目 | 内容 |
|---|---|
| 目的 | 指定 KPI の期間別推移・目標・前年同期を返す |
| 権限 | `report:kpi:view` |
| パラメータ | `from`、`to`（最大 36 か月）、`dimension`（任意） |
| レスポンス | `points[]`（`period`、`value`、`target`、`lastYearValue`、`achievementRate`） |
| エラー | 95001、95010（KPI 不存在） |

### 3.3 POST /api/report/kpis（KPI 定義登録）

| 項目 | 内容 |
|---|---|
| 目的 | KPI 定義を登録する（版数 1、状態=草稿） |
| 権限 | `report:kpi:update` |
| リクエスト | `kpiCode`、`kpiName`、`category`、`formula`、`formulaSql`、`unit`、`dimensions[]`、`frequency`、`direction`、`sourceDomain`、`permissionCode`、`effectiveFrom` |
| チェック | コード形式・一意、算式構文、次元値域、出所の実在、権限コードの実在 |
| 承認 | 登録後は「承認待ち」。財務総監の承認で状態=20 |
| エラー | 95010、95011（算式不正）、95012（次元不正）、95013（出所不正）、422 + 95014 重複 |

### 3.4 PUT /api/report/kpis/{code}（KPI 定義更新）

| 項目 | 内容 |
|---|---|
| 目的 | KPI 定義を更新し、版数を +1 する（過去版は保持） |
| 権限 | `report:kpi:update` |
| 排他 | `version` 必須。競合は 409 + `MSG-COM-033` |
| 注意 | 算式変更はスナップショットの再計算を伴わない（遡及しない）。変更後の期間から新定義を適用 |
| エラー | 95011、409 |

### 3.5 GET /api/report/analysis/sales（销售分析）

| 項目 | 内容 |
|---|---|
| 目的 | 期間・次元別の売上・粗利・数量・OTD・前年同期を返す |
| 権限 | `report:sales:view`（データ範囲を強制） |
| パラメータ | `dateFrom`、`dateTo`、`groupBy`（CUSTOMER/PRODUCT/DEPT/OWNER/MONTH）、`customerId`、`productSeries`、`compareMode` |
| レスポンス | `summary`（売上・粗利・粗利率・数量・OTD）、`rows[]`（次元値・売上・粗利・構成比・前年同期比） |
| データソース | `rpt_sales_detail`（[02 §3](02-domain-analysis.md)） |
| エラー | 95020（抽出未完了）、95021（条件不正） |

### 3.6 GET /api/report/analysis/inventory（库存分析）

| 項目 | 内容 |
|---|---|
| 目的 | 在庫金額・回転・庫齢・呆滞・欠品を返す |
| 権限 | `report:inventory:view` |
| パラメータ | `periodCode`、`warehouseId`、`categoryCode`、`includeSlowMoving` |
| レスポンス | `summary`（在庫金額・平均在庫・回転率・回転日数・呆滞比率）、`ageBuckets[]`、`warehouseRows[]`、`topSlowMoving[]` |
| データソース | `rpt_inventory_snapshot`、`rpt_sales_detail`、`inv_age_snapshot` |
| 口径 | 回転率は KPI-RPT-024（销售成本 ÷ 平均库存金额）。画面に口径注記を表示する |
| エラー | 95020、95021 |

### 3.7 GET /api/report/analysis/details（ドリルダウン）

| 項目 | 内容 |
|---|---|
| 目的 | 集計値の内訳（明細）を返す |
| 権限 | 元画面と同じ（`report:analysis:view`） |
| パラメータ | `type`（SALES/PURCHASE/INVENTORY/PRODUCTION/FINANCE）、`dateFrom`、`dateTo`、`dimensionKey`、`dimensionValue`、`pageNum`、`pageSize` |
| レスポンス | `PageResult<AnalysisDetailDto>`（業務キー・日付・相手先・品目・数量・金額・原価・状態） |
| 上限 | 10,000 件。超過は出力ジョブへ誘導（`MSG-RPT-034`） |
| エラー | 95020、95021、95022（件数超過） |

### 3.8 POST /api/report/analysis/exports（分析出力）

| 項目 | 内容 |
|---|---|
| 目的 | 分析結果を Excel/PDF で非同期出力する |
| 権限 | `report:analysis:export` |
| リクエスト | `type`、`params`（画面条件）、`format`（XLSX/PDF）、`title` |
| レスポンス | `202` + `{jobId}` |
| ジョブ | `rpt_etl_job`（job_type=90）または SYS のジョブ基盤。結果は 7 日保存 |
| 透かし | ユーザ名・出力日時を付与 |
| エラー | 95022、95023（出力失敗） |

### 3.9 GET /api/report/warnings（予警一覧）

| 項目 | 内容 |
|---|---|
| 目的 | 予警を検索し、既読・対応状況を返す |
| 権限 | `report:warning:view`（データ範囲） |
| パラメータ | `dateFrom`、`dateTo`、`severity`、`status`、`kpiCode`、`assigneeId`、`pageNum`、`pageSize` |
| レスポンス | `PageResult<WarningDto>`（`eventNo`、`ruleCode`、`kpiCode`、`eventDate`、`severity`、`message`、`status`、`actualValue`、`thresholdValue`、`assigneeId`） |
| エラー | 95040（条件不正） |

### 3.10 POST /api/report/warnings/{id}/resolve（予警解決）

| 項目 | 内容 |
|---|---|
| 目的 | 予警を解決済みにする |
| 権限 | `report:warning:update`（担当者または管理者） |
| リクエスト | `{ "resolution": "原因と対策", "version": 1 }` |
| チェック | 理由必須（10 文字以上）、状態が 10/20/30 |
| 監査 | `sys_audit_log` に記録 |
| エラー | 95041（理由不足）、95042（状態不整合）、403 |

### 3.11 POST /api/report/warning-rules（予警ルール登録）

| 項目 | 内容 |
|---|---|
| 目的 | 予警ルールを登録する |
| 権限 | `report:warning:update` |
| リクエスト | `ruleCode`、`ruleName`、`ruleType`、`kpiCode`、`operatorCode`、`thresholdValue`、`dimension`、`severity`、`checkFrequency`、`consecutiveCount`、`notifyChannels`、`ownerRoleCode` |
| チェック | コード形式・一意、KPI 存在、閾値が KPI 単位に整合、チャネル 1 件以上 |
| エラー | 95040、95043（KPI 不正）、95044（閾値不正）、95045（チャネルなし） |

### 3.12 POST /api/report/subscriptions（订阅登録）

| 項目 | 内容 |
|---|---|
| 目的 | 帳票の定期配信を登録する |
| 権限 | `report:subscription:update` |
| リクエスト | `subscriptionName`、`reportId`、`reportParams`、`frequency`、`scheduleDay`、`scheduleTime`、`outputFormat`、`recipients[]` |
| チェック | 帳票存在、頻度と配信日の整合、宛先 1 件以上、時刻 06:00〜20:00 |
| 初期値 | `status=10`、`nextSendAt` を計算 |
| エラー | 95050（帳票不正）、95051（配信日不正）、95052（宛先なし）、95053（時刻不正） |

### 3.13 POST /api/report/subscriptions/{id}/send（即時配信）

| 項目 | 内容 |
|---|---|
| 目的 | 订阅を即時配信する（テスト・再送） |
| 権限 | `report:subscription:update` |
| リクエスト | `{ "periodCode": "2026-10" }` |
| 冪等 | 同一订阅×期間は 1 回。再配信は `force=true` を明示 |
| エラー | 95054（二重配信）、95055（帳票生成失敗） |

### 3.14 POST /api/report/etl/recalculate（再計算）

| 項目 | 内容 |
|---|---|
| 目的 | 指定期間の抽出・KPI を再計算する（管理者） |
| 権限 | `report:etl:run` |
| リクエスト | `{ "dateFrom": "2026-10-01", "dateTo": "2026-10-31", "targets": ["SALES","KPI"] }` |
| 前提 | 対象期間が確定済みでない（確定済みは拒否） |
| レスポンス | `202` + `{jobId}` |
| 排他 | 同一期間のジョブ多重起動禁止 |
| エラー | 95060（確定済み）、95061（実行中） |

---

## 4. エラーコード（RPT 領域 95000〜95999）

| コード | メッセージ ID | 意味 |
|---|---|---|
| 95001 | `MSG-RPT-001` | KPI 未生成・期間不正 |
| 95010 | `MSG-RPT-010` | KPI コード不正 |
| 95011 | `MSG-RPT-011` | 算式不正 |
| 95012 | `MSG-RPT-012` | 次元不正 |
| 95013 | `MSG-RPT-013` | 出所不正 |
| 95014 | `MSG-RPT-014` | KPI 重複 |
| 95015 | `MSG-RPT-015` | 分母 0（警告） |
| 95020 | `MSG-RPT-030` | 抽出未完了・抽出失敗 |
| 95021 | `MSG-RPT-033` | 分析条件不正 |
| 95022 | `MSG-RPT-034` | 明細件数超過 |
| 95023 | `MSG-RPT-035` | 出力失敗 |
| 95040 | `MSG-RPT-040` | 予警ルール不正 |
| 95041 | `MSG-RPT-041` | 予警重複（情報） |
| 95042 | `MSG-RPT-042` | KPI 不正（予警） |
| 95043 | `MSG-RPT-043` | 閾値不正 |
| 95044 | `MSG-RPT-044` | 連続回数不正 |
| 95045 | `MSG-RPT-045` | 通知チャネルなし |
| 95050 | `MSG-RPT-050` | 帳票不正 |
| 95051 | `MSG-RPT-051` | 配信日不正 |
| 95052 | `MSG-RPT-052` | 宛先なし |
| 95053 | `MSG-RPT-053` | 配信時刻不正 |
| 95054 | `MSG-RPT-054` | 二重配信 |
| 95055 | `MSG-RPT-055` | 帳票生成失敗 |
| 95060 | `MSG-RPT-021` | 確定済みの再計算 |
| 95061 | `MSG-COM-035` | 実行中 |

---

## 5. 実装上の注意

1. **データ範囲の強制**：`rpt_*_detail` の検索に `sales_dept_id`・`warehouse_id`・`customer_id` の条件を MyBatis の DataPermissionInterceptor で注入する。画面の絞り込みのみに依存しない。
2. **KPI の NULL**：`value` が NULL の場合は `"value": null` を返し、フロントは「-」を表示する。0 と混同しない。
3. **キャッシュ**：驾驶舱・KPI トレンドは 60 秒キャッシュ。KPI スナップショット更新時にキーを無効化する。
4. **集計 API の性能**：`rpt_*_detail` の索引（日付・次元）を必須とする。月次は `period_code`、日次は `ship_date`/`receipt_date`/`snapshot_date` を用いる。
5. **出力の非同期**：10,000 件超は必ずジョブ。同期出力は 10,000 件以下かつ 30 秒以内。
6. **監査**：閲覧・出力を `rpt_query_log` に記録する（個人情報は記録しない）。
7. **口径の明示**：库存回転率など口径が分かれる KPI は、レスポンスに `caliberNote`（口径注記）を含める。

---

## 6. 未決事項

| # | 事項 | 理由 | 暫定仕様 | 担当 | 期限 |
|---|---|---|---|---|---|
| 1 | 分析 API のキャッシュ方式（Redis/Caffeine） | インフラ構成が未確定 | Phase 1 は Caffeine（ローカル 60 秒） | 情報部 | 2026-12-15 |
| 2 | 出力ジョブ基盤を SYS と共通化するか | SYS F-SYS-013 と類似 | RPT 専用の `rpt_etl_job` を先行。Phase 2 で共通化検討 | Lead／SYS | 2026-12-31 |
| 3 | 外部 BI 向けの読取専用ビュー | Phase 2 | 主要抽出テーブルのビューを提供 | 情報部 | Phase 2 |
| 4 | モバイル向け API の項目削減 | Phase 2 | 同一 API を利用し、フロントで調整 | 情報部 | Phase 2 |
| 5 | 口径注記の多言語化 | Phase 2 | 中国語のみ | Lead | Phase 2 |

## 7. 改訂履歴

| 版数 | 日付 | 変更内容 | 変更者 |
|---|---|---|---|
| v1.0 | 2026-10-20 | 初版：API 39 件の一覧、主要 14 API の詳細、RPT エラーコード 26 件 | analytics-designer |
| v1.1 | 2026-10-21 | 重複・既存系の業務エラーの HTTP を 409 → 422 に統一（409 は楽観排他競合 4003 のみ。03 §5・01-system 91 v1.10 と整合）。対象：:129（蓝色大肥鱼 2026-10-21 決定） | 业务分析 |
