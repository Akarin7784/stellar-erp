# 出纳・银行对账・税务 详细设计书（出納・銀行勘定照合・税務 詳細設計書）

| 項目 | 内容 |
|---|---|
| 文書名 | 出纳・银行对账・税务 详细设计书（出納・銀行勘定照合・税務 詳細設計書） |
| 文書番号 | DSN-FIN-005 |
| 版数 | v1.0 |
| 作成日 | 2026-10-20 |
| 作成者 | finance-designer |
| 承認者 | 未承認（レビュー待ち） |
| 状態 | ドラフト（レビュー中） |
| 関連文書 | [業務域概要](00-overview.md) / [会計科目](01-accounting-subjects.md) / [AP/付款](03-ap-payment.md) / [AR/收款](04-ar-receipt.md) / [コード一覧](../00-common/06-code-list.md) / [自動憑証](06-auto-voucher-costing.md) |

---

## 1. 機能概要

| 項目 | 内容 |
|---|---|
| 機能 ID | F-FIN-023（现金日记账）、F-FIN-024（银行日记账与银行对账）、F-FIN-025（资金日报）、F-FIN-026（发票台账）、F-FIN-027（增值税申报辅助）、F-FIN-028（附加税/所得税计提） |
| 機能名 | 出纳管理・税务管理 |
| 目的 | 管理现金/银行资金流与银行对账，出具资金日报；维护进项/销项发票台账，计算增值税（销项−进项−留抵）并生成申报辅助表；计提附加税费与企业所得税，形成 J26/J27 凭证 |
| 利用者・ロール | 出纳（日记账/对账/资金日报）、税务会计（发票台账/申报辅助/计提）、财务经理（审核/调节表复核）、财务总监（查阅/批准） |
| 利用シーン | 每日收付款登记、日终现金盘点、月末银行对账与余额调节表、月初增值税申报、月末附加税/所得税计提 |
| 優先度 | P0 |
| 画面 ID | SCR-FIN-031～040 |
| 関連 IF | IF-FIN-001（対账单导入）、IF-FIN-002/003（銀企直連）、IF-FIN-004（数电票）、IF-FIN-005（发票查验/勾选）、IF-FIN-006（申报导出） |

---

## 2. 業務要件・業務ルール

### 2.1 前提条件

| # | 前提条件 | 成立しない場合の挙動 |
|---|---|---|
| 1 | 自有银行账户已在 `fin_bank_account` 有効、且关联科目（1002.xx） | 日记账/对账不可 |
| 2 | 收付款单（F-FIN-016/020）已完成或已确认 | 日记账不可手工新增（除现金零星收支） |
| 3 | 税码 `mdm_tax_code` 有効（`tax_rate_code` 引用 06 章基础税率码） | 发票登记不可 |
| 4 | 会计期间 OPEN | 登録/计提拒否（MSG-COM-071） |

### 2.2 業務ルール

| # | ルール | 根拠 | 関連項目 |
|---|---|---|---|
| BR-01 | 现金日记账与银行日记账按「账户 × 日」管理，日终余额＝前日余额＋本日收入−本日支出；日记账与总账 1001/1002 科目余额必须一致 | CAS 现金日记账要求；08 章 9 章 | `fin_cash_journal`、`fin_bank_journal` |
| BR-02 | 现金日记账由出纳登记，每笔须有对应凭证；每日现金实盘金额与账面不符时登记 `cash_count_diff` 并查明原因，不得直接修改余额 | 社内規程【示例値】 | `fin_cash_journal` |
| BR-03 | 银行日记账的收付款必须关联付款单/收款单或手工凭证，保存银行流水号、对方户名、摘要；一条流水只能关联一次 | 银行对账要求 | `bank_ref_no` |
| BR-04 | 银行对账单按「账户 × 期间」导入（CSV/Excel），导入批次号 `BST{YYMMDD}{4}`；导入前必须校验列映射、金额格式、日期格式 | IF-FIN-001 | `fin_bank_statement` |
| BR-05 | 自动匹配规则（按优先级）：①金额+流水号完全一致；②金额+日期（±3 日）+对方户名包含；③金额+日期（±7 日）单侧候选唯一。多条候补时进入人工匹配 | 本域設計 | `fin_bank_statement_line.match_status` |
| BR-06 | 未达账项分两类：企业已记银行未记（企业未达）、银行已记企业未记（银行未达）；调节表公式见 2.3 CALC-05 | 会计实务 | `fin_bank_recon_item` |
| BR-07 | 余额调节表须由**非制表人**复核；复核后锁定，调整需财务经理权限并留痕 | SoD（08 章 9.2） | `fin_bank_reconciliation.reviewed_by` |
| BR-08 | 资金日报按账户列示：前日余额、本日收入、本日支出、本日余额、可用余额（扣除受限资金如保证金）；次日 08:30 前完成 | 社内規程【示例値】 | `fin_cash_journal`/`fin_bank_journal` |
| BR-09 | 进项发票台账登记：发票代码/号码、开票日、销售方名称/税号、金额、税额、发票种类、认证/勾选状态、入账凭证；发票必须与三单匹配/费用报销关联 | 发票管理办法【実データ】 | `fin_invoice`（INPUT） |
| BR-10 | 销项发票台账由 E12 自动登记；发票号码/代码/种类/税额；与 AR 纽付け；作废/红冲须保留原发票关联 | 09 章 7.3；发票管理办法 | `fin_invoice`（OUTPUT） |
| BR-11 | 业务税码由 MDM 管理：`mdm_tax_code` 含 `tax_rate_code`（引用 06 章 VAT13 等基础码）、`tax_type`（10 销项/11 进项/20 附加/30 关税/40 所得税）、`is_tax_included`、`valid_from/valid_to`；发票/凭证按业务税码取税率与税种，**不在程序内写死方向** | Lead 税码口径（2026-10-20） | `tax_code` |
| BR-12 | 增值税一般计税：应纳税额＝销项税额 −（进项税额 − 进项税额转出）− 上期留抵税额；结果为负时形成期末留抵结转下期 | 《中华人民共和国增值税法》【実データ】；申报表逻辑 | `fin_vat_return` |
| BR-13 | 销项税额：当期开具的销项发票（含数电票）税额合计；进项税额：当期已认证/勾选确认的进项发票税额合计；进项转出：退货、非正常损失等 | 增值税会计处理规定（财会〔2016〕22号）【実データ】 | `fin_vat_return_line` |
| BR-14 | 申报辅助表行项目与《增值税及附加税费申报表（一般纳税人适用）》主表口径一致：销售额、销项税额、进项税额、进项税额转出、上期留抵、应抵扣税额合计、实际抵扣、应纳税额、期末留抵、应纳税额合计 | 国家税务总局申报表格式【実データ】 | `fin_vat_return_line` |
| BR-15 | 附加税费以当期**实际应纳增值税**为计税依据：城建税 7%（市区）、教育费附加 3%、地方教育附加 2%；计提 J26（借 6403、贷 2221.03/04/05） | 城建税法、教育费附加规定、财综〔2010〕98号【実データ】 | `fin_tax_accrual` |
| BR-16 | 企业所得税按月度会计利润总额 × 25% 计提 J27（借 6801、贷 2221.06）；季度预缴按累计利润与已预缴差额调整；年度汇算清缴差异通过「以前年度损益调整」或当期调整 | 企业所得税法【実データ】 | `fin_tax_accrual` |
| BR-17 | 税金计提凭证确认后不得直接修改；更正通过赤伝或期间重开（财务总监权限） | 08 章 13.1 | `status` |
| BR-18 | 申报辅助表生成后必须与总账 2221 明细核对（销项/进项/未交增值税），差异必须为 0 | 月结检查项 | `fin_close_checklist` |
| BR-19 | 发票查验/勾选结果由 INT 回写；未勾选的进项发票不得计入当期进项抵扣 | 发票综合服务平台要求 | `verify_status` |
| BR-20 | 现金/银行收付款均须生成凭证（J08/J09/J10）；日记账与凭证必须一一对应（可多对一，如汇总凭证） | 会计基础规范 | `voucher_id` |
| BR-21 | **税会差异（Phase 1 簡便法）**：月次は会計利潤×25%で計上し、年次汇算清缴で以下を調整する：R&D 費用加計扣除 100%（財税〔2023〕7号）、業務招待費（発生額 60% と売上 5‰ の小さい方）、広告宣伝費（売上 15% 上限）、罰金・滞納金（損金不算入）、虧損繰越（5 年）。調整額は 6901 以前年度损益调整 または当期調整で処理する | 企业所得税法・実施条例、財税〔2023〕7号【実データ】 | `fin_tax_accrual`、6901 |
| BR-22 | **留抵退税（Phase 2）**：増量留抵退税は税務局申請→承認→受領（借 1002 / 貸 2221.01）→申報表反映。Phase 1 は留抵を 2221.01 借方残として繰越すのみ | 増量留抵退税政策（Phase 2） | `fin_vat_return` |

### 2.3 計算式・判定式

| # | 対象 | 算式 | 丸め | 例（【示例値】） |
|---|---|---|---|---|
| CALC-01 | 日记账日终余额 | 前日余额 + 本日收入 − 本日支出 | 2 位 | 24,000,000.00 + 116,141.40 − 29,662.50 = 24,086,478.90（10/28 日終、月末とは別日） |
| CALC-02 | 资金日报可用余额 | 日终余额 − 受限资金（保证金/冻结） | 2 位 | 24,086,478.90 − 500,000.00 = 23,586,478.90 |
| CALC-03 | 增值税应纳税额 | 销项税额 − 进项税额 + 进项税额转出 − 上期留抵 | 2 位 | 8,666,666.67 − 6,536,666.67 + 0 − 120,000.00 = 2,010,000.00 |
| CALC-04 | 城建税/教育费附加/地方教育附加 | 实际应纳增值税 × 税率 | 2 位 | 2,010,000 × 7% = 140,700；×3% = 60,300；×2% = 40,200 |
| CALC-05 | 银行余额调节表 | 企业账面余额 + 银行已收企业未收 − 银行已付企业未付 = 银行对账单余额 + 企业已收银行未收 − 企业已付银行未付 | 2 位 | 24,000,000 + 400,000 − 100,000 = 24,250,000 + 200,000 − 150,000 = 24,300,000 |
| CALC-06 | 自动匹配得分 | 流水号一致 +100；金额一致 +50；日期差≤3 日 +20；对方户名包含 +10 | 整数 | 得分 ≥80 自动匹配 |
| CALC-07 | 企业所得税计提（Phase 1 簡便法） | 会计利润总额 × 25% − 已计提（年次汇算清缴で税会差異を調整） | 2 位 | 5,200,000.00 × 25% = 1,300,000.00 |
| CALC-08 | 留抵结转 | min(0, 应纳税额) 的绝对值 | 2 位 | 若销项 5,000,000 − 进项 5,500,000 − 留抵 0 = −500,000 → 留抵 500,000 |

### 2.4 状態遷移

**银行对账单 `fin_bank_statement.status`**：`10 已导入 → 20 匹配中 → 40 已对账 → 90 作废`

**银行余额调节表 `fin_bank_reconciliation.status`**：`10 制表中 → 20 待复核 → 40 已复核（锁定）→ 90 作废`

**税金计提 `fin_tax_accrual.status`**：`10 草稿 → 40 已确认（凭证记账済）→ 90 作废`

**增值税申报辅助 `fin_vat_return.status`**：`10 生成中 → 40 已生成 → 50 已确认（可导出）→ 90 作废`

---

## 3. 関連機能

| 関係 | 機能 ID | 機能名 | 関係内容 |
|---|---|---|---|
| 上流 | F-FIN-016/020 | 付款/收款 | 日记账流水来源 |
| 下流 | F-FIN-030 | 自动凭证 | J08/J09/J10/J26/J27 |
| 下流 | F-FIN-038 | 现金流量表 | 现金流量项目（凭证行）→ CF |
| 参照 | F-FIN-001 | 科目 | 1001/1002/2221/6403/6801 |
| 参照 | INT | 银企/发票/申报 IF | IF-FIN-001～006 |

---

## 4. 画面設計

### 4.1 画面一覧

| 画面 ID | 画面名 | 類型 | 概要 |
|---|---|---|---|
| SCR-FIN-031 | 现金日记账 | LIST | 日次現金収支、日結、現金盤点 |
| SCR-FIN-032 | 银行日记账 | LIST | 銀行口座別収支、残高、対账状態 |
| SCR-FIN-033 | 银行对账单导入 | EDIT | ファイル選択、列マッピング、検証、取込 |
| SCR-FIN-034 | 银行对账 | EDIT | 自動/手動マッチング、未達一覧 |
| SCR-FIN-035 | 余额调节表 | 帳票 | 未達調整、复核、印刷 |
| SCR-FIN-036 | 资金日报 | DASH | 口座別前日/本日/可用残高 |
| SCR-FIN-037 | 进项发票台账 | LIST | 進項发票一覧・認証状態 |
| SCR-FIN-038 | 销项发票台账 | LIST | 销项发票一覧・AR紐付け |
| SCR-FIN-039 | 增值税申报辅助表 | 照会/帳票 | 销项/进项/留抵/应纳税額 |
| SCR-FIN-040 | 附加税/所得税计提 | EDIT | 計提計算、プレビュー、凭证生成 |

### 4.2 画面項目定義（SCR-FIN-034 银行对账）

| No | 項目 ID | 項目名 | 区分 | 種別 | 型/桁 | 必須 | 初期値 | 入力チェック | データソース | DB 項目 | 備考 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | bank_account_id | 银行账户 | 検索 | 選択 | BIGINT | ○ | 空 | 有効 | `fin_bank_account` | — | — |
| 2 | period_code | 会计期间 | 検索 | 選択 | VARCHAR(7) | ○ | 当月 | OPEN/CLOSED 可 | `fin_period` | — | — |
| 3 | statement_id | 对账单批次 | ヘッダ | 選択 | BIGINT | ○ | 空 | 已导入 | `fin_bank_statement` | `statement_id` | — |
| 4 | book_balance | 企业账面余额 | ヘッダ | 数値 | NUMERIC(18,2) | ○ | 自動 | =1002 科目余额 | `fin_account_balance` | `book_balance` | 期末 |
| 5 | statement_balance | 对账单余额 | ヘッダ | 数値 | NUMERIC(18,2) | ○ | 自動 | =対账单最終残高 | `fin_bank_statement` | `statement_balance` | — |
| 6 | unmatched_book | 企业未达 | 明細 | テーブル | — | — | — | 企業已記銀行未記 | `fin_bank_journal` | `fin_bank_recon_item` | — |
| 7 | unmatched_bank | 银行未达 | 明細 | テーブル | — | — | — | 銀行已記企業未記 | `fin_bank_statement_line` | `fin_bank_recon_item` | — |
| 8 | adjusted_book / adjusted_bank | 调节后余额 | フッタ | 数値 | NUMERIC(18,2) | ○ | 自動 | 両者一致で確定可 | CALC-05 | `fin_bank_reconciliation` | — |
| 9 | diff_reason | 差异理由 | フッタ | テキスト | VARCHAR(500) | △ | 空 | 不一致時必須 | 手入力 | — | — |

**イベント処理**

| No | イベント | トリガ | 処理内容 | 呼出 API | 画面遷移 | 備考 |
|---|---|---|---|---|---|---|
| 1 | 対账单選択 | 変更 | 明細・未達候補を取得 | GET /api/finance/bank-statements/{id} | 同一画面 | — |
| 2 | 自動マッチ | ボタン | CALC-06 の規則で判定、自動マッチ | POST /api/finance/bank-reconciliations/auto-match | 同一画面 | 結果件数表示 |
| 3 | 手動マッチ | 行選択 | 対账单行↔銀行日記帳行を関連付け | POST /api/finance/bank-reconciliations/match | 同一画面 | — |
| 4 | 未達登録 | ボタン | 企業未達（収/支）を手動登録 | POST /api/finance/bank-reconciliations/items | 同一画面 | — |
| 5 | 调节表作成 | 作成ボタン | 残高検証→status=20（待复核） | POST /api/finance/bank-reconciliations/{id}/submit | SCR-FIN-035 | 財務経理复核 |
| 6 | 复核 | 复核ボタン | 不一致チェック→status=40、ロック | POST /api/finance/bank-reconciliations/{id}/review | SCR-FIN-035 | 制表人以外 |

### 4.3 画面項目定義（SCR-FIN-039 增值税申报辅助表）

| No | 項目 ID | 項目名 | 種別 | 型/桁 | 必須 | データソース | DB 項目 | 備考 |
|---|---|---|---|---|---|---|---|---|
| 1 | period_code | 所属期间 | 選択 | VARCHAR(7) | ○ | `fin_period` | `fin_vat_return.period_code` | — |
| 2 | output_tax | 销项税额 | 数値 | NUMERIC(18,2) | ○ | 销项发票+调整个 | `output_tax` | 行 1 |
| 3 | input_tax | 进项税额 | 数値 | NUMERIC(18,2) | ○ | 已勾选进项发票 | `input_tax` | 行 2 |
| 4 | input_tax_transfer | 进项税额转出 | 数値 | NUMERIC(18,2) | ○ | 退货/非正常损失 | `input_tax_transfer` | 行 3 |
| 5 | prior_credit | 上期留抵税额 | 数値 | NUMERIC(18,2) | ○ | 前期间 `closing_credit` | `prior_credit` | 行 4 |
| 6 | deductible_total | 应抵扣税额合计 | 数値 | NUMERIC(18,2) | ○ | 2−3+4 | `deductible_total` | 行 5 |
| 7 | actual_deduction | 实际抵扣税额 | 数値 | NUMERIC(18,2) | ○ | min(5, 1) | `actual_deduction` | 行 6 |
| 8 | payable_tax | 应纳税额 | 数値 | NUMERIC(18,2) | ○ | 1−6 | `payable_tax` | 行 7 |
| 9 | closing_credit | 期末留抵税额 | 数値 | NUMERIC(18,2) | ○ | 5−6（≥0） | `closing_credit` | 行 8 |
| 10 | surcharge_total | 附加税费合计 | 数値 | NUMERIC(18,2) | ○ | CALC-04 | — | 附加税费表 |
| 11 | status | 状态 | ラベル | SMALLINT | ○ | 10/40/50/90 | `status` | — |

**イベント処理（SCR-FIN-039）**

| No | イベント | トリガ | 処理内容 | 呼出 API |
|---|---|---|---|---|
| 1 | 生成 | 生成ボタン | 当期发票・凭证から計算、保存（40） | POST /api/finance/vat-returns/generate |
| 2 | 再計算 | 再計算ボタン | 差異があれば再生成（既存 40 のみ） | POST /api/finance/vat-returns/{id}/recalculate |
| 3 | 確認 | 確認ボタン | 総勘定元帳との照合→status=50 | POST /api/finance/vat-returns/{id}/confirm |
| 4 | 導出 | 導出ボタン | IF-FIN-006 形式でファイル出力 | POST /api/finance/vat-returns/{id}/export |

### 4.4 一覧画面仕様（SCR-FIN-032 银行日记账）

| 項目 | 内容 |
|---|---|
| 検索条件 | 银行账户、期間、日付範囲、収支方向、金額範囲、対账状態、相手先、摘要 |
| 既定条件 | 当月初日～当日、口座=基本户、日付降順 |
| ソート | 日付、金額 |
| ページング | 20/50/100/200 |
| 一括操作 | 対账状態の一括更新（手動マッチ）、EXCEL 出力 |
| フッタ | 前日繰越、本日収入合計、本日支出合計、本日残高 |

### 4.5 表示制御

| 条件 | 対象 | 制御 |
|---|---|---|
| 期間 CLOSED | 日記帳登録/対账/计提 | ボタン非表示 |
| 対账状態=已対账 | マッチ取消ボタン | 財務経理のみ表示 |
| 権限なし（会計） | 銀行口座全桁・現金盤点 | マスク表示 |
| 调节表 status=40 | 編集 | 不可（閲覧のみ） |

---

## 5. 入力チェック仕様

| No | チェック ID | 対象項目 | 種別 | 条件 | タイミング | メッセージ ID |
|---|---|---|---|---|---|---|
| 1 | CHK-FIN-023-01 | 現金日記帳 | 業務 | 借方/贷方一方のみ、金額>0 | 保存 | MSG-FIN-080 |
| 2 | CHK-FIN-023-02 | 現金盤点差 | 業務 | 実盤−帳簿の差異は理由必須 | 日結 | MSG-FIN-081 |
| 3 | CHK-FIN-024-01 | 対账单期間 | 業務 | 重複取込なし（同一口座×期間） | 取込 | MSG-FIN-082 |
| 4 | CHK-FIN-024-02 | 対账单金額 | 形式 | 数値・2 位小数 | 取込 | MSG-COM-042 |
| 5 | CHK-FIN-024-03 | 调节表残高 | 業務 | 调节后企業＝调节后銀行 | 作成 | MSG-FIN-084 |
| 6 | CHK-FIN-026-01 | 進項发票 | 一意 | invoice_code+no 重複なし | 登録 | MSG-FIN-042 |
| 7 | CHK-FIN-026-02 | 進項税码 | 業務 | `tax_type=11` | 登録 | MSG-FIN-046 |
| 8 | CHK-FIN-027-01 | 申报期间 | 状態 | 期間 OPEN/CLOSED 可、既確認は再生成不可 | 生成 | MSG-FIN-086 |
| 9 | CHK-FIN-028-01 | 计提基数 | 業務 | 应纳增值税≥0（留抵时为 0） | 计提 | MSG-FIN-087 |
| 10 | CHK-FIN-028-02 | 所得税计提 | 業務 | 利润总额≥0（亏损为 0 计提） | 计提 | MSG-FIN-088 |

---

## 6. 処理詳細

### 6.1 処理一覧

| 処理 ID | 処理名 | 契機 | トランザクション | 排他 |
|---|---|---|---|---|
| PRC-FIN-023-01 | 現金日記帳登録/日結 | 保存/日結 | 要 | 口座行ロック |
| PRC-FIN-024-01 | 対账单取込 | 取込 | 要（全件 or 全件失敗） | バッチロック |
| PRC-FIN-024-02 | 自動マッチ | 実行 | 要 | 対账单/日記帳行ロック |
| PRC-FIN-024-03 | 调节表作成・复核 | 作成/复核 | 要 | 調節表行ロック |
| PRC-FIN-026-01 | 進項发票登録/查验 | 登録/IF | 要 | 发票一意制約 |
| PRC-FIN-026-02 | 销项发票紐付け（E12） | イベント | 要 | AR/发票行ロック |
| PRC-FIN-027-01 | 增值税申报辅助生成 | 生成 | 要（期間スナップショット） | 期間アドバイザリロック |
| PRC-FIN-028-01 | 附加税/所得税计提 | 计提 | 要 | 期間×税種一意 |

### 6.2 処理手順（正常系）

**PRC-FIN-024-02 自動マッチ**

1. 対象口座・期間の対账单明細と銀行日記帳未対账行を取得する。
2. 各対账单行について候補行を抽出し、CALC-06 のスコアを計算する。
3. スコア ≥80 かつ候補一意の行を自動マッチ（`match_status=2`）にする。
4. 候補複数の場合はスコア上位を提示し、自動マッチしない（人工マッチ）。
5. マッチ結果件数と未マッチ件数を返し、`fin_bank_statement.match_status` を更新する。

**PRC-FIN-027-01 增值税申报辅助生成**

1. 対象期間が OPEN/CLOSED かつ未確認であることを確認する。
2. 销项税额：`fin_invoice`（OUTPUT、当期、有効）の `tax_amount` 合計 ＋ 調整仕訳（`fin_voucher_line` 2221.01 の当期発生）。
3. 进项税额：`fin_invoice`（INPUT、当期、`verify_status=已勾选`）の `tax_amount` 合計 ＋ 調整。
4. 进项税额转出：`fin_voucher_line` 2221.01 の当期発生。
5. 上期留抵：前期间 `fin_vat_return.closing_credit`。
6. CALC-03/04 で応納税額・附加税を計算し、`fin_vat_return` + line を保存する。
7. 総勘定元帳 2221 の当期発生と照合し、差異があれば警告する（差異理由必須）。
8. `status=40` で保存し、確認操作で 50 にする。

**PRC-FIN-028-01 附加税/所得税计提**

1. 当期の `fin_vat_return` を取得し、应纳税額を確定する（未生成時は生成を促す）。
2. 附加税 = 应纳税額 × (7% + 3% + 2%) を区間別に計算する。
3. 所得税 = max(0, 当期利润总额) × 25% − 既计提額。利润总额は `fin_account_balance` の損益科目集計から算出。
4. `fin_tax_accrual` を保存し、プレビューを返す。
5. 確定操作で J26/J27 を生成（借 6403/6801、贷 2221.03/04/05/2221.06）し、判断結果を監査ログに記録する。

### 6.3 例外処理

| No | 異常条件 | 検知箇所 | 処理 | ロールバック | メッセージ ID |
|---|---|---|---|---|---|
| 1 | 対账单重複取込 | 取込 | エラー終了 | 全体 | MSG-FIN-082 |
| 2 | 调节表残高不一致 | 作成 | エラー終了（未達一覧表示） | 全体 | MSG-FIN-084 |
| 3 | 发票号码重複 | 登録 | エラー終了 | 全体 | MSG-FIN-042 |
| 4 | 申报表と総勘定元帳の差異 | 生成/確認 | 警告 + 差異理由必須 | —（保存可） | MSG-FIN-085 |
| 5 | 計提重複（同期間・同税種） | 计提 | エラー終了（上書きは再生成 API） | 全体 | MSG-FIN-089 |
| 6 | 銀行口座未設定 | 日記帳 | エラー終了 | 全体 | MSG-FIN-083 |

### 6.4 冪等性・再実行

- 対账单取込は「口座+期間+ファイルハッシュ」で重複判定し、再実行時はスキップ。
- 自動マッチは未マッチ行のみ対象とし、再実行しても既存マッチを壊さない（取消は手動）。
- 申报辅助/计提は期間×税種で一意とし、再生成は既存を上書き（監査ログに版数記録）。

---

## 7. API 設計

| No | メソッド | パス | 権限 | 概要 | リクエスト | レスポンス |
|---|---|---|---|---|---|---|
| 1 | GET | /api/finance/cash-journals | finance:cash-journal:view | 現金日記帳 | `dateFrom,dateTo,direction` | `PageResult<CashJournalDto>` |
| 2 | POST | /api/finance/cash-journals | finance:cash-journal:create | 現金収支登録 | `CashJournalCreate` | `CashJournalDto`（201） |
| 3 | POST | /api/finance/cash-journals/daily-close | finance:cash-journal:create | 現金日結・盤点 | `{journalDate,actualBalance,diffReason?}` | `{bookBalance,actualBalance,diff}` |
| 4 | GET | /api/finance/bank-journals | finance:bank-journal:view | 銀行日記帳 | `bankAccountId,dateFrom,dateTo,reconcileStatus` | `PageResult<BankJournalDto>` |
| 5 | GET | /api/finance/bank-accounts | finance:bank-journal:view | 自有銀行口座一覧 | `—` | `BankAccountDto[]` |
| 6 | POST | /api/finance/bank-statements/import | finance:bank-statement:import | 対账单取込 | multipart + `bankAccountId,periodCode,columnMapping` | `{statementId,lineCount,duplicateCount,errors[]}` |
| 7 | GET | /api/finance/bank-statements | finance:bank-statement:import | 対账单批次一覧 | `bankAccountId,periodCode` | `PageResult<BankStatementDto>` |
| 8 | GET | /api/finance/bank-statements/{id}/lines | finance:bank-recon:execute | 対账单明細 | `matchStatus` | `PageResult<BankStatementLineDto>` |
| 9 | POST | /api/finance/bank-reconciliations/auto-match | finance:bank-recon:execute | 自動マッチ | `{statementId}` | `{matchedCount,unmatchedCount}` |
| 10 | POST | /api/finance/bank-reconciliations/match | finance:bank-recon:execute | 手動マッチ | `{statementLineId,journalId}` | `Result<Void>` |
| 11 | POST | /api/finance/bank-reconciliations/{id}/submit | finance:bank-recon:execute | 调节表作成（待复核） | `{statementId,bookBalance,statementBalance}` | `ReconDto` |
| 12 | POST | /api/finance/bank-reconciliations/{id}/review | finance:bank-recon:view | 调节表复核 | `{version,comment?}` | `ReconDto` |
| 13 | GET | /api/finance/fund-daily | finance:fund-report:view | 資金日報 | `reportDate` | `FundDailyDto` |
| 14 | GET | /api/finance/invoices | finance:invoice:view | 发票台账（進項/销项） | `invoiceType,dateFrom,dateTo,verifyStatus,supplierId,customerId` | `PageResult<InvoiceDto>` |
| 15 | POST | /api/finance/invoices/{id}/verify | finance:invoice:update | 進項发票認証/勾选状態更新 | `{verifyStatus,verifyDate}` | `InvoiceDto` |
| 16 | POST | /api/finance/vat-returns/generate | finance:vat-return:generate | 申报辅助生成 | `{periodCode}` | `VatReturnDto` |
| 17 | GET | /api/finance/vat-returns/{id} | finance:vat-return:view | 申报辅助明細 | — | `VatReturnDto` |
| 18 | POST | /api/finance/vat-returns/{id}/confirm | finance:vat-return:generate | 申报辅助確認 | `{version}` | `VatReturnDto` |
| 19 | POST | /api/finance/vat-returns/{id}/export | finance:vat-return:export | 申報データ出力 | `{format: XML/EXCEL}` | ファイル（202/200） |
| 20 | POST | /api/finance/tax-accruals | finance:tax-accrual:generate | 附加税/所得税计提 | `{periodCode,taxTypes[]}` | `{accruals[],voucherIds[]}` |
| 21 | GET | /api/finance/tax-accruals | finance:tax-accrual:view | 计提一覧 | `periodCode,taxType` | `TaxAccrualDto[]` |

### 7.1 リクエスト/レスポンス詳細

**POST /api/finance/vat-returns/generate**

```json
{ "periodCode": "2026-10" }
```

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "id": "1845678901234590001",
    "periodCode": "2026-10",
    "outputTax": "8666666.67",
    "inputTax": "6536666.67",
    "inputTaxTransfer": "0.00",
    "priorCredit": "120000.00",
    "deductibleTotal": "6656666.67",
    "actualDeduction": "6656666.67",
    "payableTax": "2010000.00",
    "closingCredit": "0.00",
    "surchargeTotal": "241200.00",
    "surchargeDetail": [
      { "taxCode": "SUR7", "base": "2010000.00", "rate": "7.0000", "amount": "140700.00" },
      { "taxCode": "EDU3", "base": "2010000.00", "rate": "3.0000", "amount": "60300.00" },
      { "taxCode": "EDU2", "base": "2010000.00", "rate": "2.0000", "amount": "40200.00" }
    ],
    "status": 40
  }
}
```

**POST /api/finance/bank-reconciliations/auto-match**

```json
{ "statementId": "1845678901234588001" }
```

```json
{
  "code": 0,
  "message": "ok",
  "data": { "matchedCount": 42, "unmatchedCount": 3, "candidates": 5 }
}
```

**エラー例（调节表不一致）**

```json
{
  "code": 70084,
  "message": "余额调节表不平衡（调节后企业余额 24,300,000.00 / 调节后银行余额 24,250,000.00，差额 50,000.00）。",
  "data": { "adjustedBook": "24300000.00", "adjustedBank": "24250000.00", "difference": "50000.00" }
}
```

---

## 8. データ更新仕様

| テーブル | 操作 | 更新項目 | 更新条件 | トリガ |
|---|---|---|---|---|
| `fin_cash_journal` | INSERT/UPDATE | 収支、残高、盤点差 | 登録/日結 | PRC-FIN-023-01 |
| `fin_bank_journal` | INSERT/UPDATE | 収支、残高、対账状態、match_stmt_line_id | 登録/マッチ | PRC-FIN-016/020/024 |
| `fin_bank_statement` / `_line` | INSERT/UPDATE | 取込、マッチ状態 | 取込/マッチ | PRC-FIN-024 |
| `fin_bank_reconciliation` / `_item` | INSERT/UPDATE | 残高、未達、status | 作成/复核 | PRC-FIN-024-03 |
| `fin_invoice` | INSERT/UPDATE | 発票、verify_status、match_status | 登録/E12/認証 | PRC-FIN-026 |
| `fin_vat_return` / `_line` | INSERT/UPDATE | 計算値、status | 生成/確認 | PRC-FIN-027 |
| `fin_tax_accrual` | INSERT | 税種、基数、税率、金額、voucher_id | 计提 | PRC-FIN-028 |
| `fin_voucher` / `fin_voucher_line` | INSERT | J26/J27 | 计提 | PRC-FIN-028 |

---

## 9. エラー処理・メッセージ

| メッセージ ID | 種別 | 本文 | 発生条件 | 利用者への対処 |
|---|---|---|---|---|
| MSG-FIN-080 | E | 现金日记账金额无效（借贷方向与金额不一致）。 | 金額不整合 | 修正 |
| MSG-FIN-081 | E | 现金盘点差异必须填写原因（差异 {0}）。 | 盤点差理由なし | 原因入力 |
| MSG-FIN-082 | E | 该银行账户的 {0} 期间对账单已导入，不能重复导入。 | 重複取込 | 既存批次を削除/確認 |
| MSG-FIN-083 | E | 银行账户未设置或已停用，请联系管理员。 | 口座不備 | 口座設定を確認 |
| MSG-FIN-084 | E | 余额调节表不平衡（调节后企业 {0} / 调节后银行 {1}，差额 {2}）。 | 调节表不一致 | 未達事項を確認 |
| MSG-FIN-085 | W | 申报辅助表与总账应交税费发生额存在差异 {0}，请确认。 | 照合差 | 差異理由を記録 |
| MSG-FIN-086 | E | 该期间的申报辅助表已确认，不能重新生成；如需修正请先取消确认。 | 確認済再生成 | 取消確認（財務経理） |
| MSG-FIN-087 | E | 当期应纳税额小于 0（留抵），附加税费计税依据按 0 计算。 | 留抵 | 情報表示（エラーではない） |
| MSG-FIN-088 | E | 当期利润总额小于 0（亏损），所得税计提金额按 0 处理。 | 亏损 | 情報表示 |
| MSG-FIN-089 | E | 该期间同一税种已计提，不能重复计提。 | 计提重複 | 既存计提を赤伝訂正 |
| MSG-FIN-090 | I | 银行对账完成：自动匹配 {0} 件，未达 {1} 件。 | 対账完了 | — |
| MSG-FIN-091 | I | 增值税申报辅助表已生成（应纳税额 {0}，留抵 {1}）。 | 生成完了 | — |

---

## 10. 権限・セキュリティ

| 種別 | 内容 |
|---|---|
| 画面権限 | `finance:cash-journal:view/create`、`finance:bank-journal:view`、`finance:bank-statement:import`、`finance:bank-recon:execute/view/adjust`、`finance:fund-report:view`、`finance:invoice:view/update`、`finance:vat-return:view/generate/export`、`finance:tax-accrual:view/generate` |
| 操作権限 | 日記帳＝出納、対账单取込/マッチ＝出納、调节表复核＝財務経理（非制表人）、申報辅助/计提＝税務会計、計提確認＝財務経理 |
| 項目権限 | 銀行口座番号は下 4 桁マスク。税額・申報データは税務会計/財務経理のみ |
| データ範囲 | 全社（会計主体）。銀行口座単位の制限は任意設定可 |
| 監査ログ | 取込/マッチ/调节表作成/复核、发票登録/認証、申報生成/確認/輸出、计提/赤伝を記録 |
| 機密 | 銀企直連の認証情報は INT が管理し、FIN は参照しない |

---

## 11. 性能・非機能

| 項目 | 目標値 | 前提 |
|---|---|---|
| 対账单取込（5,000 行） | 60 秒以内 | 一括 INSERT、検証分離 |
| 自動マッチ（5,000 行） | 30 秒以内 | インデックス（口座+日付+金額） |
| 資金日報 | 3 秒以内 | 口座別集計 |
| 申報辅助生成（10 万发票） | 60 秒以内 | 期間索引 + 集計クエリ |
| 计提 | 10 秒以内 | 損益科目集計 |

---

## 12. テスト観点

| No | 観点 ID | 分類 | 観点 | 期待結果 |
|---|---|---|---|---|
| 1 | TST-F-FIN-023-01 | 正常系 | 現金收支登録→日結 | 残高が正しく更新 |
| 2 | TST-F-FIN-023-02 | 異常系 | 現金盤点差・理由なし | MSG-FIN-081 |
| 3 | TST-F-FIN-024-01 | 正常系 | 対账单取込（CSV） | 明細取込、重複なし |
| 4 | TST-F-FIN-024-02 | 異常系 | 同一口座×期間の再取込 | MSG-FIN-082 |
| 5 | TST-F-FIN-024-03 | 正常系 | 自動マッチ | 金額・日付一致行がマッチ |
| 6 | TST-F-FIN-024-04 | 正常系 | 调节表作成→复核 | 调节后一致、复核後ロック |
| 7 | TST-F-FIN-024-05 | 異常系 | 调节表不一致 | MSG-FIN-084 |
| 8 | TST-F-FIN-025-01 | 正常系 | 資金日報 | 前日+収−支=当日 |
| 9 | TST-F-FIN-026-01 | 正常系 | 進項发票登録/認証 | verify_status 更新 |
| 10 | TST-F-FIN-027-01 | 正常系 | 申報辅助生成 | 销项−进项−留抵=应纳税額 |
| 11 | TST-F-FIN-027-02 | 境界値 | 留抵（销项<进项） | 期末留抵が正しく計算 |
| 12 | TST-F-FIN-027-03 | 正常系 | 附加税計算 | 7%/3%/2% が正しい |
| 13 | TST-F-FIN-028-01 | 正常系 | 所得税计提 | 25% 计提、J27 |
| 14 | TST-F-FIN-028-02 | 異常系 | 同期間同税種の再计提 | MSG-FIN-089 |
| 15 | TST-F-FIN-027-04 | 権限 | 一般会計が申報生成 | 403、ボタン非表示 |

---

## 13. 未決事項

| # | 事項 | 理由 | 暫定仕様 | 担当 | 期限 |
|---|---|---|---|---|---|
| 1 | 数电票/纸质票のコード・番号規則 | 数电票は 20 位番号、紙票はコード+番号 | `invoice_code` 可空、`invoice_no` VARCHAR(32)。INT で正規化 | INT | 2026-10-30 |
| 2 | 進項勾选/認証のタイミング | 当月勾选 vs 次月勾选 | 当月勾选分を当期進項。未勾选は 2221.05 待認証へ | 税務会計 | 2026-10-30 |
| 3 | 電子税務局への申報接続 | 楽企/数电票平台の接続方式未定 | Phase 1 はファイル出力（IF-FIN-006）、Phase 2 で直連 | INT | Phase 2 |
| 4 | 附加税の減免・優遇 | 小規模・特定業種の減免有無 | 本企業（一般納税者・製造業）は減免なし前提 | 税務会計 | 2026-10-30 |
| 5 | 銀行対账单のフォーマット | 取引銀行ごとに異なる | 汎用列マッピング + テンプレート（INT 管理） | INT / 出納 | 2026-10-30 |

---

## 14. 改訂履歴

| 版数 | 日付 | 変更内容 | 変更者 |
|---|---|---|---|
| v1.0 | 2026-10-20 | 初版：現金/銀行日記帳、対账单取込・自動マッチ・调节表、資金日報、发票台账（税码口径）、增值税申报辅助、附加税/所得税计提、画面/API/メッセージ/テスト | finance-designer |
| v1.1 | 2026-10-20 | 红队修复：唯一シナリオに合わせ增值税を再計算（销项 8,666,666.67／进项 6,536,666.67／上期留抵 120,000／应纳 2,010,000／附加 241,200）。BR-20（税会差異・匯算清缴）／BR-21（留抵退税 Phase2）追加。引用法令を《增值税法》へ更新 | finance-designer |
