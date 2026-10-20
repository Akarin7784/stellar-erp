# 预警中心・报表订阅 详细设计书（アラートセンター・レポート購読 詳細設計書）

| 項目 | 内容 |
|---|---|
| 文書名 | 预警中心・报表订阅 详细设计书（アラートセンター・レポート購読 詳細設計書） |
| 文書番号 | DSN-RPT-003 |
| 版数 | v1.0 |
| 作成日 | 2026-10-20 |
| 作成者 | analytics-designer（報表分析分野担当） |
| 承認者 | 未承認（レビュー待ち） |
| 状態 | ドラフト（レビュー中） |
| 関連文書 | [業務域概要](00-overview.md) / [KPI 設計](01-dashboard.md) / [域分析](02-domain-analysis.md) / [DB 設計](90-db-design.md) / [集成管理概要](../09-integration/00-overview.md) / [共通业务规则](../00-common/08-common-business-rules.md) |

---

## 1. 機能概要

| 項目 | 内容 |
|---|---|
| 機能 ID | F-RPT-005（预警中心）、F-RPT-006（报表订阅） |
| 機能名 | 预警中心／报表订阅 |
| 目的 | ① KPI・業務事実の異常をルールで検知し、担当者へ通知・エスカレーションする；② 定例レポート（日次・週次・月次）を指定形式で自動配信する |
| 利用者・ロール | 経営層、部門経理、財務、営業、購買、計画、システム管理者 |
| 利用シーン | 朝会の予警確認、月次会議の資料配信、KPI 悪化の早期対応、監査資料の定期取得 |
| 優先度 | P1 |
| 画面 ID | SCR-RPT-011〜015 |
| 関連 IF | IF-RPT-002（配信）、IF-RPT-005（監査ログ） |

---

## 2. 業務要件

### 2.1 予警の基本方針

1. **KPI と業務事実の両方を監視**：KPI スナップショット（`rpt_kpi_snapshot`）と業務テーブルの事実（在庫不足、納期遅延等）を対象とする。
2. **重複を出さない**：同一ルール・同一日・同一次元の予警は 1 件（`dedup_key`）。再評価しても増やさない。
3. **重要度で通知を変える**：情報（站内のみ）、警告（站内＋メール）、重大（站内＋メール＋Webhook、上司へエスカレーション）。
4. **自動で解決しない**：予警は担当者が「既読 → 対応中 → 解決（理由必須）」と更新する。KPI が回復しても自動クローズしない（履歴を残す）。
5. **配信は止まらない**：通知失敗で予警・業務を止めない。再送キューで処理する（[08 §13.3](../00-common/08-common-business-rules.md)）。

### 2.2 予警ルール一覧（20 件・示例）

| ルール ID | ルール名 | 対象 KPI | 条件 | 重要度 | 頻度 | 通知先 |
|---|---|---|---|---|---|---|
| WARN-RPT-001 | 库存周转率低下 | KPI-RPT-024 | < 目標 × 90%（< 5.4 次） | 警告 | 月次 | 財務・計画・購買 |
| WARN-RPT-002 | 呆滞库存比率超過 | KPI-RPT-026 | > 5% | 警告 | 月次 | 計画・購買・倉庫主管 |
| WARN-RPT-003 | 缺货率超過 | KPI-RPT-028 | > 2% | 重大 | 日次 | 計画・購買 |
| WARN-RPT-004 | 应收账款周转天数超過 | KPI-RPT-006 | > 68 日 | 警告 | 月次 | 財務・営業 |
| WARN-RPT-005 | 毛利率低下 | KPI-RPT-003 | < 20% | 重大 | 月次 | 総経理・財務・営業 |
| WARN-RPT-006 | 交付达成率低下 | KPI-RPT-017 | < 95% | 警告 | 月次 | 営業・生産・計画 |
| WARN-RPT-007 | 计划达成率低下 | KPI-RPT-036 | < 90% | 重大 | 日次 | 生産・計画 |
| WARN-RPT-008 | 良品率低下 | KPI-RPT-037 | < 98% | 重大 | 日次 | 生産・品質 |
| WARN-RPT-009 | 采购降本率未達 | KPI-RPT-030 | < 0% | 警告 | 月次 | 購買・財務 |
| WARN-RPT-010 | 供应商按期交付率低下 | KPI-RPT-031 | < 90% | 警告 | 月次 | 購買 |
| WARN-RPT-011 | 与信超限率超過 | KPI-RPT-022 | > 2% | 警告 | 月次 | 営業・財務 |
| WARN-RPT-012 | 客户集中度過高 | KPI-RPT-020 | > 50% | 警告 | 月次 | 営業・総経理 |
| WARN-RPT-013 | 退货率超過 | KPI-RPT-021 | > 1% | 警告 | 月次 | 営業・品質 |
| WARN-RPT-014 | 库存金额超预算 | KPI-RPT-023 | > 予算 × 110% | 警告 | 月次 | 財務・計画 |
| WARN-RPT-015 | 收入负增长 | KPI-RPT-012 | < 0% | 重大 | 月次 | 総経理・財務・営業 |
| WARN-RPT-016 | 工单成本差异率超過 | KPI-RPT-040 | > 5% | 警告 | 月次 | 生産・財務 |
| WARN-RPT-017 | 来料检验合格率低下 | KPI-RPT-032 | < 97% | 警告 | 月次 | 購買・品質 |
| WARN-RPT-018 | 三单匹配自动通过率低下 | KPI-RPT-034 | < 80% | 警告 | 月次 | 購買・財務 |
| WARN-RPT-019 | 期间费用率超過 | KPI-RPT-005 | > 8% | 警告 | 月次 | 財務 |
| WARN-RPT-020 | 经营活动现金流为负 | KPI-RPT-009 | < 0 | 重大 | 月次 | 総経理・財務 |

> 条件は【示例値】。`rpt_warning_rule.threshold_value` で変更する。KPI の算式・次元は [01-dashboard.md](01-dashboard.md) を正とする。

### 2.3 業務ルール（予警）

| # | ルール | 根拠 | 関連項目 |
|---|---|---|---|
| BR-WARN-01 | ルールは KPI 定義または業務テーブルを参照する。KPI の算式を変更した場合、ルールの閾値も見直す | 本設計 | `kpi_code` |
| BR-WARN-02 | 予警は `dedup_key = rule_code + event_date + dimension_key` で一意。再評価は既存の値を更新する（新規作成しない） | 本設計 | `dedup_key` |
| BR-WARN-03 | 「連続 n 回」ルールは、直近 n 期連続で条件を満たした場合のみ発生する（単発の振れを除外） | 本設計 | `consecutive_count` |
| BR-WARN-04 | 重大予警は 24 時間未読で上司へエスカレーション、48 時間で部門長へ通知する | 本設計 | — |
| BR-WARN-05 | 予警の既読・対応・解決は担当者と管理者のみ。解決には理由を必須とする | 本設計 | `resolution` |
| BR-WARN-06 | 同一 KPI の予警が 3 か月連続で発生した場合、KPI 目標または業務プロセスの見直しを検討する（レポートに表示） | 本設計 | — |
| BR-WARN-07 | 予警の通知はユーザの通知設定に従う。配信停止でも站内には残す（重大は除く） | 本設計 | `rpt_warning_subscription` |
| BR-WARN-08 | 月結前（BAT-RPT-007 前）に予警を再評価し、当月分を確定する | 本設計 | BAT-RPT-008 |

### 2.4 業務ルール（订阅）

| # | ルール | 根拠 | 関連項目 |
|---|---|---|---|
| BR-SUB-01 | 订阅は帳票 ID（PRT-RPT-xxx）とパラメータ（期間・部門等）を保持する | 本設計 | `report_id` |
| BR-SUB-02 | 頻度は日次（毎日）/週次（指定曜日）/月次（指定日）の 3 種。時刻は 07:30 を既定 | 本設計 | `frequency` |
| BR-SUB-03 | 配信形式は PDF/Excel。ファイル名は `{帳票名}_{期間}_{配信日}.pdf` | 本設計 | `output_format` |
| BR-SUB-04 | 宛先はユーザ・ロール・外部メール。ロールは配信時点の有効ユーザに展開する | 本設計 | `recipients` |
| BR-SUB-05 | 同一订阅・同一期間の二重配信を禁止する（`subscription_id + period_code` 一意） | 本設計 | `uk_rpt_subscription_log` |
| BR-SUB-06 | 配信失敗は 3 回再送。失敗が続く場合は管理者へ通知し、订阅を一時停止する | 本設計 | `retry_count` |
| BR-SUB-07 | 月次確定前の配信は「暫定」の透かしを入れる。確定後に再配信できる | 本設計 | `snapshot_status` |
| BR-SUB-08 | 配信ログは 3 年保存する（監査・再発行の根拠） | 本設計 | `rpt_subscription_log` |

### 2.5 通知チャネルと重要度

| 重要度 | 站内 | メール | WeCom/钉钉 | エスカレーション |
|---|---|---|---|---|
| 10 情報 | ○ | — | — | なし |
| 20 警告 | ○ | ○（日次まとめ可） | ○（設定時） | 24h 未読でリマインド |
| 30 重大 | ○ | ○（即時） | ○（即時） | 24h で上司、48h で部門長 |

> 送信は INT の IF-INT-011（SMTP/短信/WeCom/DingTalk）を利用する。RPT は送信を直接行わない。

### 2.6 订阅一覧（示例 10 件）

| 订阅 ID | 名称 | 帳票 | 頻度 | 宛先 | 形式 |
|---|---|---|---|---|---|
| SUB-RPT-001 | 日次経営サマリ | PRT-RPT-001 | 日次 07:30 | 総経理・財務総監 | PDF |
| SUB-RPT-002 | 日次予警レポート | PRT-RPT-009 | 日次 08:00 | 部門経理 | PDF |
| SUB-RPT-003 | 週次販売分析 | PRT-RPT-003 | 週次（月曜） | 営業部 | Excel |
| SUB-RPT-004 | 週次購買・納期 | PRT-RPT-004 | 週次（月曜） | 購買部 | Excel |
| SUB-RPT-005 | 月次経営分析 | PRT-RPT-002 | 月次（5 日） | 経営層 | PDF |
| SUB-RPT-006 | 月次在庫分析 | PRT-RPT-005 | 月次（5 日） | 計画・購買・財務 | Excel |
| SUB-RPT-007 | 月次生産分析 | PRT-RPT-006 | 月次（5 日） | 生産・品質 | Excel |
| SUB-RPT-008 | 月次財務分析 | PRT-RPT-007 | 月次（8 日） | 財務・総経理 | PDF |
| SUB-RPT-009 | 月次 KPI 台帳 | PRT-RPT-010 | 月次（10 日） | 財務・内審 | Excel |
| SUB-RPT-010 | KPI 指標字典 | PRT-RPT-008 | 改訂時 | 全部門 | Excel |

> 订阅 ID は本設計の識別子（DB の `subscription_no` は `SUB-{YYYYMMDD}-{4桁}` で採番）。

---

## 3. 関連機能

| 関係 | 機能 ID | 機能名 | 関係内容 |
|---|---|---|---|
| 上流 | F-RPT-001/002 | 驾驶舱・KPI | 予警対象の KPI 値 |
| 上流 | F-RPT-003/004 | 域分析 | 分析結果の配信 |
| 下流 | F-INT-012 | 消息渠道 | メール/Webhook 送信 |
| 下流 | F-SYS-011 | 站内通知 | 站内通知の登録 |
| 参照 | F-SYS-019 | 通知模板 | 文面 |

---

## 4. 画面設計

### 4.1 画面一覧

| 画面 ID | 画面名 | 類型 | 概要 |
|---|---|---|---|
| SCR-RPT-011 | 预警中心 | 一覧検索 | 重要度・状態・期間・KPI で検索、既読/対応/解決 |
| SCR-RPT-012 | 预警规则编辑 | 登録編集 | ルール・閾値・対象・通知の編集 |
| SCR-RPT-013 | 预警历史 | 一覧検索 | 過去の予警・対応履歴・KPI 推移 |
| SCR-RPT-014 | 报表订阅一覧 | 一覧検索 | 订阅の一覧・実行・停止 |
| SCR-RPT-015 | 订阅設定 | 登録編集 | 帳票・頻度・宛先・形式の設定 |

### 4.2 画面項目定義（SCR-RPT-011）

| No | 項目 ID | 項目名 | 種別 | 型/桁 | 必須 | 初期値 | 入力チェック | データソース | DB 項目 |
|---|---|---|---|---|---|---|---|---|---|
| 1 | date_from | 発生日（開始） | 日付 | DATE | ○ | 当月 1 日 | 開始 ≤ 終了 | 入力 | `event_date` |
| 2 | date_to | 発生日（終了） | 日付 | DATE | ○ | 当日 | 同上 | 入力 | `event_date` |
| 3 | severity | 重要度 | 複数選択 | SMALLINT | △ | 20,30 | 10/20/30 | 固定値 | `severity` |
| 4 | status | 状態 | 複数選択 | SMALLINT | △ | 10,20,30 | 10/20/30/40 | 固定値 | `status` |
| 5 | kpi_code | KPI | 選択 | VARCHAR(32) | △ | 空 | 有効 KPI | `rpt_kpi_definition` | `kpi_code` |
| 6 | owner_role | 担当ロール | 選択 | VARCHAR(64) | △ | 自ロール | 有効ロール | `sys_role` | — |
| 7 | event_no | 予警番号 | テキスト | VARCHAR(64) | △ | 空 | 桁数 | 入力 | `event_no` |
| 8 | actual_value | 実績値 | 表示 | NUMERIC | — | — | — | 自動 | `actual_value` |
| 9 | threshold_value | 閾値 | 表示 | NUMERIC | — | — | — | 自動 | `threshold_value` |
| 10 | assignee_id | 担当者 | 選択 | BIGINT | △ | 空 | 有効ユーザ | `sys_user` | `assignee_id` |

### 4.3 画面項目定義（SCR-RPT-012）

| No | 項目 ID | 項目名 | 種別 | 型/桁 | 必須 | 初期値 | 入力チェック | DB 項目 |
|---|---|---|---|---|---|---|---|---|
| 1 | rule_code | ルールコード | テキスト | VARCHAR(32) | ○ | 空 | `WARN-RPT-\d{3}`、一意 | `rule_code` |
| 2 | rule_name | ルール名 | テキスト | VARCHAR(200) | ○ | 空 | 桁数 | `rule_name` |
| 3 | rule_type | 種別 | 選択 | SMALLINT | ○ | 10 | 10/20/30/40 | `rule_type` |
| 4 | kpi_code | 対象 KPI | 選択 | VARCHAR(32) | ○ | 空 | 有効 KPI | `kpi_code` |
| 5 | operator_code | 比較 | 選択 | VARCHAR(8) | ○ | LT | GT/LT/GE/LE/EQ/NE | `operator_code` |
| 6 | threshold_value | 閾値 | 数値 | NUMERIC(18,4) | ○ | 空 | 単位に整合 | `threshold_value` |
| 7 | dimension_json | 次元 | 複数選択 | JSONB | △ | 全社 | 有効次元 | `dimension_json` |
| 8 | severity | 重要度 | 選択 | SMALLINT | ○ | 20 | 10/20/30 | `severity` |
| 9 | check_frequency | 評価頻度 | 選択 | CHAR(1) | ○ | D | D/W/M | `check_frequency` |
| 10 | consecutive_count | 連続回数 | 数値 | SMALLINT | ○ | 1 | 1〜12 | `consecutive_count` |
| 11 | notify_channels | 通知チャネル | 複数選択 | JSONB | ○ | INAPP | INAPP/EMAIL/WECOM/DINGTALK | `notify_channels` |
| 12 | owner_role_code | 担当ロール | 選択 | VARCHAR(64) | ○ | 空 | 有効ロール | `owner_role_code` |
| 13 | status | 状態 | 選択 | SMALLINT | ○ | 10 | 10/20 | `status` |

### 4.4 画面項目定義（SCR-RPT-015）

| No | 項目 ID | 項目名 | 種別 | 型/桁 | 必須 | 初期値 | 入力チェック | DB 項目 |
|---|---|---|---|---|---|---|---|---|
| 1 | subscription_name | 订阅名 | テキスト | VARCHAR(200) | ○ | 空 | 桁数 | `subscription_name` |
| 2 | report_id | 帳票 | 選択 | VARCHAR(32) | ○ | 空 | 有効帳票 | `report_id` |
| 3 | report_params | パラメータ | テキスト | JSONB | ○ | 空 | 帳票定義に整合 | `report_params` |
| 4 | frequency | 頻度 | 選択 | SMALLINT | ○ | 30 | 10 日次/20 週次/30 月次 | `frequency` |
| 5 | schedule_day | 配信日 | テキスト | VARCHAR(16) | △ | 5 | 1-7/1-28/LAST | `schedule_day` |
| 6 | schedule_time | 配信時刻 | 時刻 | TIME | ○ | 07:30 | 06:00〜20:00 | `schedule_time` |
| 7 | output_format | 形式 | 選択 | SMALLINT | ○ | 10 | 10 PDF/20 Excel | `output_format` |
| 8 | recipients | 宛先 | 複数選択 | JSONB | ○ | 本人 | ユーザ/ロール/メール | `recipients` |
| 9 | status | 状態 | 選択 | SMALLINT | ○ | 10 | 10 有効/20 停止 | `status` |

### 4.5 イベント処理

| No | イベント | トリガ | 処理内容 | 呼出 API | 画面遷移 |
|---|---|---|---|---|---|
| 1 | 検索 | 検索ボタン | 条件検証→一覧 | `GET /api/report/warnings` | 同一画面 |
| 2 | 既読 | 行選択 | `status=20`、`read_at` | `POST /api/report/warnings/{id}/read` | 同一画面 |
| 3 | 対応開始 | ボタン | `status=30`、担当者設定 | `POST /api/report/warnings/{id}/assign` | 同一画面 |
| 4 | 解決 | ボタン | 理由必須→`status=40` | `POST /api/report/warnings/{id}/resolve` | 同一画面 |
| 5 | ルール保存 | 保存 | 入力チェック→保存→次回評価から適用 | `POST/PUT /api/report/warning-rules` | SCR-RPT-011 |
| 6 | 订阅保存 | 保存 | 次回配信日を計算 | `POST/PUT /api/report/subscriptions` | SCR-RPT-014 |
| 7 | 今すぐ配信 | ボタン | 即時配信（テスト） | `POST /api/report/subscriptions/{id}/send` | SCR-RPT-014 |
| 8 | 停止/再開 | ボタン | `status` 更新 | `POST /api/report/subscriptions/{id}/toggle` | SCR-RPT-014 |

### 4.6 表示制御

| 条件 | 対象 | 制御 |
|---|---|---|
| `report:warning:view` なし | 予警一覧 | 403 |
| `report:warning:update` なし | ルール編集・解決 | 非表示（API 403） |
| 他部門の予警 | 一覧 | データ範囲外は非表示 |
| `status=40` | 解決ボタン | 非表示 |
| 订阅の所有者以外 | 編集・停止 | 非表示（管理者除く） |

---

## 5. 入力チェック仕様

| No | チェック ID | 対象 | 種別 | 条件 | タイミング | メッセージ |
|---|---|---|---|---|---|---|
| 1 | CHK-RPT-005-01 | ルールコード | 形式 | `WARN-RPT-\d{3}` | 保存時 | `MSG-RPT-040` |
| 2 | CHK-RPT-005-02 | 対象 KPI | 存在 | 有効 KPI | 保存時 | `MSG-RPT-042` |
| 3 | CHK-RPT-005-03 | 閾値 | 範囲 | KPI の単位・値域に整合 | 保存時 | `MSG-RPT-043` |
| 4 | CHK-RPT-005-04 | 連続回数 | 範囲 | 1〜12 | 保存時 | `MSG-RPT-044` |
| 5 | CHK-RPT-005-05 | 通知チャネル | 必須 | 1 つ以上、有効チャネル | 保存時 | `MSG-RPT-045` |
| 6 | CHK-RPT-006-01 | 帳票 | 存在 | 有効帳票 ID | 保存時 | `MSG-RPT-050` |
| 7 | CHK-RPT-006-02 | 配信日 | 相関 | 頻度と整合（週次 1-7、月次 1-28/LAST） | 保存時 | `MSG-RPT-051` |
| 8 | CHK-RPT-006-03 | 宛先 | 必須 | 1 件以上、有効ユーザ/ロール/メール | 保存時 | `MSG-RPT-052` |
| 9 | CHK-RPT-006-04 | 配信時刻 | 範囲 | 06:00〜20:00 | 保存時 | `MSG-RPT-053` |
| 10 | CHK-RPT-006-05 | 二重配信 | 一意 | 同一订阅×期間なし | 配信時 | `MSG-RPT-054` |

---

## 6. 処理詳細

### 6.1 処理一覧

| 処理 ID | 処理名 | 契機 | トランザクション | 排他 |
|---|---|---|---|---|
| PRC-RPT-005-01 | 予警評価 | BAT-RPT-008 | 要（ルール単位） | `dedup_key` 一意 |
| PRC-RPT-005-02 | 通知送信 | 予警発生 | 不要（外部） | — |
| PRC-RPT-005-03 | エスカレーション | 毎時 | 要（状態） | 状態遷移 |
| PRC-RPT-005-04 | 予警解決 | 画面 | 要 | 楽観排他 |
| PRC-RPT-006-01 | 订阅配信 | BAT-RPT-009 | 要（ログ） | `subscription_id+period` 一意 |
| PRC-RPT-006-02 | 再配信 | 画面/失敗 | 要 | 同上 |

### 6.2 処理手順（正常系）

**PRC-RPT-005-01 予警評価**

1. 有効なルールを取得し、評価頻度（日次/週次/月次）に一致するものを抽出する。
2. 対象期間の KPI スナップショット（`rpt_kpi_snapshot`）または業務事実を取得する。
3. 条件（閾値・前年同期比・連続回数）を評価する。連続ルールは直近 n 期を確認する。
4. 条件成立時、`dedup_key` で既存を確認する。既存があれば `actual_value` のみ更新する。
5. 新規の場合、`rpt_warning_event` を `status=10` で登録し、重要度に応じて通知する。
6. 通知は INT 経由（站内は SYS）。送信失敗は再送キューに積む。
7. 実行結果を `rpt_etl_job`（job_type=予警）に記録する。

**PRC-RPT-006-01 订阅配信**

1. `status=10` かつ `next_send_at ≤ now()` の订阅を取得する。
2. 帳票 ID・パラメータから帳票を生成する（PDF/Excel）。月次未確定の場合は「暫定」を付す。
3. `rpt_subscription_log` に `status=20` で登録する（`subscription_id + period_code` 一意）。
4. 宛先を展開（ロール→ユーザ、外部メール）し、INT 経由で配信する。
5. 成功で `status=40`、`sent_at` 更新。失敗は `status=50`、`retry_count+1`、最大 3 回。
6. 次回配信日を計算して `next_send_at` を更新する。

### 6.3 例外処理

| No | 異常条件 | 検知 | 処理 | ロールバック | メッセージ |
|---|---|---|---|---|---|
| 1 | KPI 未計算 | 評価 | スキップ、翌日再評価 | なし | `MSG-RPT-046` |
| 2 | 閾値不正 | 保存 | 保存拒否 | 全体 | `MSG-RPT-043` |
| 3 | 通知チャネル無効 | 送信 | 站内のみ、警告 | なし | `MSG-RPT-047` |
| 4 | 予警重複 | 評価 | 既存更新（新規作成しない） | なし | — |
| 5 | 帳票生成失敗 | 配信 | `status=50`、再送 | ログのみ | `MSG-RPT-055` |
| 6 | 宛先 0 件 | 配信 | 配信せず警告 | なし | `MSG-RPT-056` |
| 7 | 二重配信 | 配信 | スキップ | なし | `MSG-RPT-054` |
| 8 | エスカレーション先不在 | 毎時 | 管理者へ通知 | なし | `MSG-RPT-048` |

### 6.4 冪等性・再実行

- 予警評価は `dedup_key` で冪等。同日・同ルール・同次元は 1 件。
- 订阅配信は `subscription_id + period_code` の一意制約で二重配信を防ぐ。再配信は明示操作。
- 通知は `notificationId + channel` で冪等（INT 側）。
- エスカレーションは状態（未読→リマインド済）で管理し、二重通知しない。

---

## 7. API 設計

| No | メソッド | パス | 権限 | 概要 |
|---|---|---|---|---|
| 1 | GET | `/api/report/warnings` | `report:warning:view` | 予警一覧 |
| 2 | GET | `/api/report/warnings/{id}` | `report:warning:view` | 予警詳細 |
| 3 | POST | `/api/report/warnings/{id}/read` | `report:warning:view` | 既読 |
| 4 | POST | `/api/report/warnings/{id}/assign` | `report:warning:update` | 担当者設定 |
| 5 | POST | `/api/report/warnings/{id}/resolve` | `report:warning:update` | 解決 |
| 6 | GET | `/api/report/warning-rules` | `report:warning:view` | ルール一覧 |
| 7 | POST | `/api/report/warning-rules` | `report:warning:update` | ルール登録 |
| 8 | PUT | `/api/report/warning-rules/{code}` | `report:warning:update` | ルール更新 |
| 9 | GET | `/api/report/subscriptions` | `report:subscription:view` | 订阅一覧 |
| 10 | POST | `/api/report/subscriptions` | `report:subscription:update` | 订阅登録 |
| 11 | PUT | `/api/report/subscriptions/{id}` | `report:subscription:update` | 订阅更新 |
| 12 | POST | `/api/report/subscriptions/{id}/send` | `report:subscription:update` | 即時配信 |
| 13 | POST | `/api/report/subscriptions/{id}/toggle` | `report:subscription:update` | 停止/再開 |
| 14 | GET | `/api/report/subscriptions/{id}/logs` | `report:subscription:view` | 配信履歴 |

### 7.1 レスポンス例（予警一覧・【示例値】）

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "list": [
      {
        "eventNo": "WARN-20261020-0001",
        "ruleCode": "WARN-RPT-003",
        "kpiCode": "KPI-RPT-028",
        "eventDate": "2026-10-19",
        "severity": 30,
        "message": "缺货率 3.20% 超过阈值 2.00%（仓库 WH01，物料 12 项）",
        "status": 10,
        "actualValue": "3.2000",
        "thresholdValue": "2.0000",
        "assigneeId": null
      }
    ],
    "total": 1
  }
}
```

### 7.2 エラー例

```json
{ "code": 95040, "message": "预警规则代码格式不正确（应为 WARN-RPT-三位数字）。", "data": { "ruleCode": "WARN-001" } }
```

---

## 8. データ更新仕様

| テーブル | 操作 | 更新項目 | トリガ |
|---|---|---|---|
| `rpt_warning_rule` | INSERT/UPDATE | ルール・閾値・状態 | F-RPT-005 |
| `rpt_warning_event` | INSERT/UPDATE | 予警・既読・解決 | BAT-RPT-008／利用者 |
| `rpt_warning_subscription` | INSERT/UPDATE | 受信者・チャネル | F-RPT-005 |
| `rpt_subscription` | INSERT/UPDATE | 订阅・次回配信 | F-RPT-006 |
| `rpt_subscription_log` | INSERT/UPDATE | 配信結果 | BAT-RPT-009 |
| `rpt_query_log` | INSERT | 閲覧 | 画面 |

---

## 9. エラー処理・メッセージ

| メッセージ ID | 種別 | 本文 | 発生条件 | 対処 |
|---|---|---|---|---|
| `MSG-RPT-040` | E | 预警规则代码格式不正确（应为 WARN-RPT-三位数字）。 | 形式違反 | 修正 |
| `MSG-RPT-041` | I | 该预警已存在，已更新为最新值。 | 重複 | — |
| `MSG-RPT-042` | E | 指定的 KPI 不存在或已停用。 | KPI 不正 | 修正 |
| `MSG-RPT-043` | E | 阈值超出该指标的有效范围。 | 閾値不正 | 修正 |
| `MSG-RPT-044` | E | 连续次数必须在 1〜12 之间。 | 値域違反 | 修正 |
| `MSG-RPT-045` | E | 请至少选择一个通知渠道。 | チャネルなし | 選択 |
| `MSG-RPT-046` | W | 该指标的 KPI 尚未计算，本次跳过。 | KPI 未計算 | 翌日再評価 |
| `MSG-RPT-047` | W | 部分通知渠道不可用，已改由站内通知。 | チャネル障害 | 設定確認 |
| `MSG-RPT-048` | W | 升级通知的接收人不存在，已通知系统管理员。 | 宛先不在 | ロール確認 |
| `MSG-RPT-049` | I | 预警已解决。 | 解決 | — |
| `MSG-RPT-050` | E | 指定的报表不存在。 | 帳票不正 | 修正 |
| `MSG-RPT-051` | E | 配信日与频率不匹配。 | 日付不正 | 修正 |
| `MSG-RPT-052` | E | 请至少指定一个接收人。 | 宛先なし | 追加 |
| `MSG-RPT-053` | E | 配信时刻必须在 06:00〜20:00 之间。 | 時刻不正 | 修正 |
| `MSG-RPT-054` | W | 该期间已配信，本次跳过。 | 二重配信 | 再配信を明示 |
| `MSG-RPT-055` | E | 报表生成失败：{0}，系统将重试。 | 生成失敗 | 監視 |
| `MSG-RPT-056` | W | 接收人展开后为 0 件，未执行配信。 | 宛先 0 | 設定確認 |

---

## 10. 権限・セキュリティ

| 種別 | 内容 |
|---|---|
| 画面権限 | `report:warning:view/update`、`report:subscription:view/update` |
| データ範囲 | 予警はロールのデータ範囲に従う。他部門の予警は非表示 |
| 項目権限 | 金額・原価を含む予警は財務権限者のみ |
| 監査 | ルール変更・予警解決・配信を `sys_audit_log` と `rpt_query_log` に記録 |
| 通知 | 個人情報を含めない。宛先はユーザ ID で管理し、メールアドレスはマスク表示 |

---

## 11. 性能・非機能

| 項目 | 目標 | 前提 |
|---|---|---|
| 予警一覧 | 2 秒以内 | 索引（event_date, severity） |
| 予警評価 | 1 回 5 分以内（20 ルール） | スナップショット参照 |
| 订阅配信 | 1 件 30 秒以内 | 帳票生成含む |
| 同時閲覧 | 100 ユーザ | — |
| 通知遅延 | 5 分以内 | INT の SLA |

---

## 12. テスト観点

| No | 観点 ID | 分類 | 観点 | 期待結果 |
|---|---|---|---|---|
| 1 | TST-F-RPT-005-01 | 正常系 | 閾値超過で予警発生 | `status=10`、通知 |
| 2 | TST-F-RPT-005-02 | 冪等 | 同日再評価 | 新規作成されない |
| 3 | TST-F-RPT-005-03 | 正常系 | 連続 3 回ルール | 3 回目のみ発生 |
| 4 | TST-F-RPT-005-04 | 正常系 | 既読→対応→解決 | 状態遷移、監査ログ |
| 5 | TST-F-RPT-005-05 | 異常系 | 解決理由なし | `MSG-COM-040` |
| 6 | TST-F-RPT-005-06 | 異常系 | 通知チャネル障害 | 站内のみ、警告 |
| 7 | TST-F-RPT-005-07 | エスカレーション | 24h 未読 | 上司へ通知 |
| 8 | TST-F-RPT-005-08 | 権限 | 他部門の予警 | 非表示 |
| 9 | TST-F-RPT-006-01 | 正常系 | 月次配信 | PDF 生成・送信・ログ |
| 10 | TST-F-RPT-006-02 | 冪等 | 同一期間の再配信 | `MSG-RPT-054` |
| 11 | TST-F-RPT-006-03 | 異常系 | 帳票生成失敗 | `status=50`、3 回再送 |
| 12 | TST-F-RPT-006-04 | 異常系 | 宛先 0 件 | `MSG-RPT-056` |
| 13 | TST-F-RPT-006-05 | 正常系 | 停止/再開 | `next_send_at` 再計算 |
| 14 | TST-F-RPT-006-06 | 境界 | 2 月 29 日の月次 | 翌営業日またはスキップ（設定） |

---

## 13. 未決事項

| # | 事項 | 理由 | 暫定仕様 | 担当 | 期限 |
|---|---|---|---|---|---|
| 1 | 予警のエスカレーション先 | 運用規程が未確定 | 部門経理→部門長→担当役員（24h/48h） | 経営層 | 2026-12-15 |
| 2 | 日次まとめ通知の時刻 | 朝会の運用に依存 | 08:00 に日次まとめ | 情報部 | 2026-12-15 |
| 3 | 月次配信日（5 日/8 日/10 日） | 月結完了日が変動 | 月結完了後に自動調整する（Phase 2） | 財務 | 2026-12-31 |
| 4 | 予警の自動クローズ可否 | 監査上の要請 | 自動クローズしない（手動解決） | 内審 | 2026-12-15 |
| 5 | 外部メール宛先の許可 | 情報漏洩防止 | 社内ドメインのみ既定。外部は管理者承認 | 情報部 | 2026-12-31 |
| 6 | WeCom/DingTalk の通知テンプレート | INT の Phase 2 | 站内＋メールを先行 | 情報部 | Phase 2 |

## 14. 改訂履歴

| 版数 | 日付 | 変更内容 | 変更者 |
|---|---|---|---|
| v1.0 | 2026-10-20 | 初版：予警ルール 20 件、订阅 10 件、重要度別通知、画面 5、API 14、テスト観点 14 | analytics-designer |
