# API 一覧（接口一览）

| 項目 | 内容 |
|---|---|
| 文書名 | API 一覧（接口一览）（自动生成） |
| 文書番号 | DSN-MTX-009 |
| 版数 | v1.0 |
| 作成日 | 2026-10-20 |
| 作成者 | Lead（生成工具 gen_matrix.py） |
| 状態 | ドラフト（自动生成・最終レビュー前） |
| 備考 | 全 1239 件。メソッド/パス/概要/権限/域/提取元 |

> 本文件由 `20-matrix/tools/gen_matrix.py` 从各域设计书中自动提取生成。修改设计书后重新运行即可更新。

| メソッド | パス | 概要 | 権限コード | 域 | 提取元 |
|---|---|---|---|---|---|
| POST | /api/{module}/exports |  |  | CMN | 00-common/03-common-api-spec.md |
| GET | /api/{module}/{resource} |  |  | CMN | 00-common/03-common-api-spec.md |
| POST | /api/{module}/{resource} |  |  | CMN | 00-common/03-common-api-spec.md |
| POST | /api/{module}/{resource}/batch-{action} |  |  | CMN | 00-common/03-common-api-spec.md |
| DELETE | /api/{module}/{resource}/{id} |  |  | CMN | 00-common/03-common-api-spec.md |
| GET | /api/{module}/{resource}/{id} |  |  | CMN | 00-common/03-common-api-spec.md |
| PUT | /api/{module}/{resource}/{id} |  |  | CMN | 00-common/03-common-api-spec.md |
| POST | /api/{module}/{resource}/{id}/print |  |  | CMN | 00-common/03-common-api-spec.md |
| POST | /api/{module}/{resource}/{id}/{action} |  |  | CMN | 00-common/03-common-api-spec.md |
| GET | /api/finance/accounts | 科目一覧（ツリー/フラット） | finance:account:view | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/accounts | 科目登録 | finance:account:create | FIN | 07-finance/91-api-design.md |
| DELETE | /api/finance/accounts/{id} | 科目削除（未使用のみ） | finance:account:update | FIN | 07-finance/91-api-design.md |
| GET | /api/finance/accounts/{id} | 科目詳細 | finance:account:view | FIN | 07-finance/01-accounting-subjects.md |
| GET | /api/finance/accounts/{id} | 科目詳細（補助核算含む） | finance:account:view | FIN | 07-finance/91-api-design.md |
| PUT | /api/finance/accounts/{id} | 科目更新 | finance:account:update | FIN | 07-finance/01-accounting-subjects.md |
| PUT | /api/finance/accounts/{id} | 科目更新（version 必須） | finance:account:update | FIN | 07-finance/91-api-design.md |
| PUT | /api/finance/accounts/{id}/aux | 補助核算設定 | finance:account:update | FIN | 07-finance/91-api-design.md |
| GET | /api/finance/ap-aging | 应付账龄 | finance:aging:view | FIN | 07-finance/91-api-design.md |
| GET | /api/finance/ar-aging | 应收账龄 | finance:aging:view | FIN | 07-finance/91-api-design.md |
| GET/POST | /api/finance/assets | 固定資産カード | finance:asset:view/update | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/assets/depreciation/run | 減価償却実行 | finance:asset:update | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/assets/{id}/dispose | 資産処分 | finance:asset:dispose | FIN | 07-finance/91-api-design.md |
| GET/POST | /api/finance/assets（P2） | 固定資産 | finance:asset:* | FIN | 07-finance/07-period-reporting.md |
| GET | /api/finance/auto-voucher-templates | 自動凭证テンプレート一覧（voucher-templates?templateType=1 と同義） | finance:auto-voucher:view | FIN | 07-finance/91-api-design.md |
| GET | /api/finance/auto-vouchers | 自動凭证ログ | finance:auto-voucher:view | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/auto-vouchers/replay | イベント再処理（指定 eventId） | finance:auto-voucher:retry | FIN | 07-finance/06-auto-voucher-costing.md |
| POST | /api/finance/auto-vouchers/replay | イベント再処理 | finance:auto-voucher:retry | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/auto-vouchers/{id}/retry | 手動リトライ | finance:auto-voucher:retry | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/bad-debts/accrue（P2） | 坏账计提 | finance:receivable:update | FIN | 07-finance/91-api-design.md |
| GET | /api/finance/bank-accounts | 自有銀行口座一覧 | finance:bank-journal:view | FIN | 07-finance/91-api-design.md |
| GET | /api/finance/bank-journals | 銀行日記帳 | finance:bank-journal:view | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/bank-reconciliations/auto-match | 自動マッチ | finance:bank-recon:execute | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/bank-reconciliations/match | 手動マッチ | finance:bank-recon:execute | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/bank-reconciliations/{id}/review | 调节表复核 | finance:bank-recon:view | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/bank-reconciliations/{id}/submit | 调节表作成（待复核） | finance:bank-recon:execute | FIN | 07-finance/91-api-design.md |
| GET | /api/finance/bank-statements | 対账单批次一覧 | finance:bank-statement:import | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/bank-statements/import | 対账单取込（202 ジョブ可） | finance:bank-statement:import | FIN | 07-finance/91-api-design.md |
| GET | /api/finance/bank-statements/{id}/lines | 対账单明細 | finance:bank-recon:execute | FIN | 07-finance/91-api-design.md |
| GET/POST | /api/finance/budgets | 予算 | finance:budget:view/update | FIN | 07-finance/91-api-design.md |
| GET | /api/finance/budgets/execution | 予算執行 | finance:budget:view | FIN | 07-finance/91-api-design.md |
| GET | /api/finance/cash-journals | 現金日記帳 | finance:cash-journal:view | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/cash-journals | 現金収支登録 | finance:cash-journal:create | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/cash-journals/daily-close | 現金日結・盤点 | finance:cash-journal:create | FIN | 07-finance/91-api-design.md |
| GET/POST | /api/finance/cash-plans | 資金計画 | finance:fund-report:view | FIN | 07-finance/91-api-design.md |
| GET | /api/finance/cash-plans/shortage | 資金不足警告 | finance:fund-report:view | FIN | 07-finance/91-api-design.md |
| GET | /api/finance/costs/allocations | 製造費用分配一覧 | finance:cost:view | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/costs/allocations | 製造費用分配実行 | finance:cost:calculate | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/costs/calculate | 成本計算起動 | finance:cost:calculate | FIN | 07-finance/06-auto-voucher-costing.md |
| POST | /api/finance/costs/calculate | 成本計算起動（202） | finance:cost:calculate | FIN | 07-finance/91-api-design.md |
| GET | /api/finance/costs/precheck | 成本計算前チェック | finance:cost:view | FIN | 07-finance/91-api-design.md |
| GET | /api/finance/costs/results | 成本計算結果 | finance:cost:view | FIN | 07-finance/91-api-design.md |
| GET | /api/finance/costs/variance | 成本差異分析 | finance:cost:view | FIN | 07-finance/91-api-design.md |
| GET | /api/finance/costs/wip | 在制品一覧 | finance:cost:view | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/costs/{jobId}/confirm | 成本確定（J16 生成） | finance:cost:confirm | FIN | 07-finance/06-auto-voucher-costing.md |
| POST | /api/finance/costs/{jobId}/confirm | 成本確定（J16） | finance:cost:confirm | FIN | 07-finance/91-api-design.md |
| GET | /api/finance/customers/{customerId}/credit-usage | 与信使用額（SAL 連携） | finance:receivable:view | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/exchange-revaluations | 為替調整 | finance:voucher:create | FIN | 07-finance/91-api-design.md |
| GET/POST | /api/finance/expense-claims | 費用精算 | finance:expense:view/create | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/expense-claims/{id}/approve | 精算承認 | finance:expense:approve | FIN | 07-finance/91-api-design.md |
| GET | /api/finance/fund-daily | 資金日報 | finance:fund-report:view | FIN | 07-finance/91-api-design.md |
| GET | /api/finance/invoices | 发票一覧（進項/销项） | finance:invoice:view | FIN | 07-finance/03-ap-payment.md |
| GET | /api/finance/invoices | 发票台账（進項/销项） | finance:invoice:view | FIN | 07-finance/05-cashier-tax.md |
| GET | /api/finance/invoices | 发票一覧（INPUT/OUTPUT） | finance:invoice:view | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/invoices | 進項发票登记 | finance:invoice:create | FIN | 07-finance/03-ap-payment.md |
| POST | /api/finance/invoices | 進項发票登録 | finance:invoice:create | FIN | 07-finance/91-api-design.md |
| GET | /api/finance/invoices/{id} | 发票詳細 | finance:invoice:view | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/invoices/{id}/approve | 照合承認/AP 確認 | finance:invoice:match | FIN | 07-finance/03-ap-payment.md |
| POST | /api/finance/invoices/{id}/approve | 照合承認→AP 確認・J02/J03 | finance:invoice:match | FIN | 07-finance/91-api-design.md |
| GET | /api/finance/invoices/{id}/match-detail | 三单差異明細 | finance:invoice:view | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/invoices/{id}/reject | 照合拒否 | finance:invoice:match | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/invoices/{id}/verify | 進項发票認証/勾选状態更新 | finance:invoice:update | FIN | 07-finance/05-cashier-tax.md |
| POST | /api/finance/invoices/{id}/verify | 進項发票認証/勾选 | finance:invoice:update | FIN | 07-finance/91-api-design.md |
| GET | /api/finance/jobs/{jobId} | 非同期ジョブ状態 | （各機能権限） | FIN | 07-finance/91-api-design.md |
| GET | /api/finance/ledgers/detail | 明細帳 | finance:ledger:view | FIN | 07-finance/02-voucher-ledger.md |
| GET | /api/finance/ledgers/detail | 明細帳（補助核算指定可） | finance:ledger:view | FIN | 07-finance/91-api-design.md |
| GET | /api/finance/ledgers/general | 総勘定元帳 | finance:ledger:view | FIN | 07-finance/91-api-design.md |
| GET | /api/finance/ledgers/journal | 序時帳 | finance:ledger:view | FIN | 07-finance/91-api-design.md |
| GET | /api/finance/opening-balances | 期初一覧 | finance:opening-balance:import | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/opening-balances/confirm | 期初確定（ロック） | finance:opening-balance:import | FIN | 07-finance/01-accounting-subjects.md |
| POST | /api/finance/opening-balances/confirm | 期初確定・ロック | finance:opening-balance:import | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/opening-balances/import | 期初一括取込 | finance:opening-balance:import | FIN | 07-finance/01-accounting-subjects.md |
| POST | /api/finance/opening-balances/import | 期初一括取込（dryRun 対応） | finance:opening-balance:import | FIN | 07-finance/91-api-design.md |
| GET | /api/finance/payables | 应付一覧 | finance:payable:view | FIN | 07-finance/91-api-design.md |
| GET | /api/finance/payables/accruals | 暂估残高一覧 | finance:payable:view | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/payables/accruals/reverse | 暂估冲回（一括） | finance:payable:update | FIN | 07-finance/03-ap-payment.md |
| POST | /api/finance/payables/accruals/reverse | 暂估一括冲回 | finance:payable:update | FIN | 07-finance/91-api-design.md |
| GET | /api/finance/payables/supplier-statement | 供应商对账单データ | finance:payable:view | FIN | 07-finance/03-ap-payment.md |
| GET | /api/finance/payables/{id} | 应付詳細（核销履歴含む） | finance:payable:view | FIN | 07-finance/03-ap-payment.md |
| GET | /api/finance/payables/{id} | 应付詳細（核销履歴） | finance:payable:view | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/payables/{id}/cancel | 应付作废 | finance:payable:cancel | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/payables/{id}/confirm | 应付確認 | finance:payable:confirm | FIN | 07-finance/91-api-design.md |
| GET | /api/finance/payment-requests | 付款申請一覧 | finance:payment-request:view | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/payment-requests | 付款申請登録 | finance:payment-request:create | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/payment-requests/{id}/submit | 申請提出（WF） | finance:payment-request:submit | FIN | 07-finance/03-ap-payment.md |
| POST | /api/finance/payment-requests/{id}/submit | WF 提出 | finance:payment-request:submit | FIN | 07-finance/91-api-design.md |
| GET | /api/finance/payments | 付款一覧 | finance:payment:view | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/payments | 付款登録（未実行） | finance:payment:create | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/payments/{id}/cancel | 付款作废（銀行退回） | finance:payment:reverse | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/payments/{id}/execute | 付款実行 | finance:payment:execute | FIN | 07-finance/03-ap-payment.md |
| POST | /api/finance/payments/{id}/execute | 付款実行（J10・核销・E28） | finance:payment:execute | FIN | 07-finance/91-api-design.md |
| GET | /api/finance/periods | 期間一覧 | finance:period:view | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/periods/{code}/close | 期間閉鎖 | finance:period:close | FIN | 07-finance/07-period-reporting.md |
| POST | /api/finance/periods/{code}/close | 期間閉鎖（E30 発行） | finance:period:close | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/periods/{code}/close-checks | 月結チェック実行 | finance:period:close | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/periods/{code}/close-checks/waive | NG 項目の免除 | finance:period:close | FIN | 07-finance/07-period-reporting.md |
| POST | /api/finance/periods/{code}/close-checks/waive | NG 項目免除 | finance:period:close | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/periods/{code}/open | 期間開帳 | finance:period:close | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/periods/{code}/profit-transfer | 損益転記実行 | finance:period:close | FIN | 07-finance/07-period-reporting.md |
| POST | /api/finance/periods/{code}/profit-transfer | 損益転記実行（J28/J29） | finance:period:close | FIN | 07-finance/91-api-design.md |
| GET | /api/finance/periods/{code}/profit-transfer/preview | 損益転記プレビュー | finance:period:close | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/periods/{code}/reopen | 期間再開（財務総監） | finance:period:reopen | FIN | 07-finance/91-api-design.md |
| GET | /api/finance/receipts | 收款一覧 | finance:receipt:view | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/receipts | 收款登録 | finance:receipt:create | FIN | 07-finance/91-api-design.md |
| PUT | /api/finance/receipts/{id} | 收款更新（status=10） | finance:receipt:create | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/receipts/{id}/cancel | 收款作废 | finance:receipt:reverse | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/receipts/{id}/confirm | 到账確認（J08/J09/E29） | finance:receipt:confirm | FIN | 07-finance/04-ar-receipt.md |
| POST | /api/finance/receipts/{id}/confirm | 到账確認（J08/J09・核销・E29） | finance:receipt:confirm | FIN | 07-finance/91-api-design.md |
| GET | /api/finance/receivables | 应收一覧 | finance:receivable:view | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/receivables/batch-confirm | 一括確認 | finance:receivable:confirm | FIN | 07-finance/91-api-design.md |
| GET | /api/finance/receivables/customer-statement | 客户对账单データ | finance:receivable:view | FIN | 07-finance/91-api-design.md |
| GET | /api/finance/receivables/{id} | 应收詳細 | finance:receivable:view | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/receivables/{id}/cancel | 应收作废（退货等） | finance:receivable:cancel | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/receivables/{id}/confirm | 应收確認 | finance:receivable:confirm | FIN | 07-finance/91-api-design.md |
| GET | /api/finance/standard-costs | 標準原価版一覧 | finance:standard-cost:view | FIN | 07-finance/06-auto-voucher-costing.md |
| GET | /api/finance/standard-costs | 標準原価版一覧（materialId,status,period） | finance:standard-cost:view | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/standard-costs | 草稿登録（status=10） | finance:standard-cost:register | FIN | 07-finance/91-api-design.md |
| GET | /api/finance/standard-costs/{id} | 標準原価版詳細 | finance:standard-cost:view | FIN | 07-finance/91-api-design.md |
| PUT | /api/finance/standard-costs/{id} | 草稿更新（version 楽観ロック） | finance:standard-cost:register | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/standard-costs/{id}/publish | 発行（旧版自動打切り） | finance:standard-cost:publish | FIN | 07-finance/06-auto-voucher-costing.md |
| POST | /api/finance/standard-costs/{id}/publish | 発行（fin_publish_standard_cost 呼出、mdm_material 行ロックで同一物料を直列化、旧版自動打切り。23P01 も 70134 に変換） | finance:standard-cost:publish | FIN | 07-finance/91-api-design.md |
| POST/PUT | /api/finance/standard-costs[/{id}] | 草稿登録・更新 | finance:standard-cost:register | FIN | 07-finance/06-auto-voucher-costing.md |
| GET | /api/finance/statement-formulas | 取数公式一覧（保守） | finance:statement:view | FIN | 07-finance/07-period-reporting.md |
| GET | /api/finance/statement-formulas | 取数公式一覧 | finance:statement:view | FIN | 07-finance/91-api-design.md |
| GET | /api/finance/statements/{type} | 报表取得（プレビュー/快照） | finance:statement:view | FIN | 07-finance/07-period-reporting.md |
| GET | /api/finance/statements/{type} | BS/IS/CF/SCE（所有者权益变动表） 取得 | finance:statement:view | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/statements/{type}/export | 报表出力（PDF/Excel） | finance:statement:export | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/statements/{type}/snapshots | 报表快照保存 | finance:statement:view | FIN | 07-finance/91-api-design.md |
| GET | /api/finance/tax-accruals | 计提一覧 | finance:tax-accrual:view | FIN | 07-finance/05-cashier-tax.md |
| GET | /api/finance/tax-accruals | 計提一覧 | finance:tax-accrual:view | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/tax-accruals | 附加税/所得税计提 | finance:tax-accrual:generate | FIN | 07-finance/05-cashier-tax.md |
| POST | /api/finance/tax-accruals | 附加税/所得税計提 | finance:tax-accrual:generate | FIN | 07-finance/91-api-design.md |
| GET | /api/finance/trial-balance | 試算平衡表 | finance:trial-balance:view | FIN | 07-finance/91-api-design.md |
| GET | /api/finance/trial-balance | 科目余額表データ | finance:trial-balance:view | FIN | 07-finance/07-period-reporting.md |
| POST | /api/finance/trial-balance/export | 科目余額表出力 | finance:report:export | FIN | 07-finance/07-period-reporting.md |
| POST | /api/finance/vat-returns/generate | 申报辅助生成 | finance:vat-return:generate | FIN | 07-finance/05-cashier-tax.md |
| POST | /api/finance/vat-returns/generate | 增值税申報補助生成 | finance:vat-return:generate | FIN | 07-finance/91-api-design.md |
| GET | /api/finance/vat-returns/{id} | 申报辅助明細 | finance:vat-return:view | FIN | 07-finance/05-cashier-tax.md |
| GET | /api/finance/vat-returns/{id} | 申報補助明細 | finance:vat-return:view | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/vat-returns/{id}/confirm | 申报辅助確認 | finance:vat-return:generate | FIN | 07-finance/05-cashier-tax.md |
| POST | /api/finance/vat-returns/{id}/confirm | 申報補助確認 | finance:vat-return:generate | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/vat-returns/{id}/export | 申報データ出力 | finance:vat-return:export | FIN | 07-finance/05-cashier-tax.md |
| POST | /api/finance/vat-returns/{id}/export | 申報データ出力（202） | finance:vat-return:export | FIN | 07-finance/91-api-design.md |
| GET | /api/finance/voucher-templates | 凭证テンプレート一覧 | finance:voucher-template:view | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/voucher-templates | テンプレート登録 | finance:voucher-template:update | FIN | 07-finance/91-api-design.md |
| GET | /api/finance/voucher-templates/{id} | テンプレート詳細（行含む） | finance:auto-voucher:view | FIN | 07-finance/06-auto-voucher-costing.md |
| PUT | /api/finance/voucher-templates/{id} | テンプレート更新 | finance:voucher-template:update | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/voucher-templates/{id}/preview | ドライラン（サンプル payload） | finance:voucher-template:view | FIN | 07-finance/91-api-design.md |
| GET | /api/finance/vouchers | 凭证検索 | finance:voucher:view | FIN | 07-finance/02-voucher-ledger.md |
| GET | /api/finance/vouchers | 凭证検索（PageResult） | finance:voucher:view | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/vouchers | 凭证登録 | finance:voucher:create | FIN | 07-finance/02-voucher-ledger.md |
| POST | /api/finance/vouchers | 凭证登録（手動/テンプレート） | finance:voucher:create | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/vouchers/batch-post | 一括记账 | finance:voucher:post | FIN | 07-finance/02-voucher-ledger.md |
| POST | /api/finance/vouchers/batch-post | 一括記帳 | finance:voucher:post | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/vouchers/batch-review | 一括审核 | finance:voucher:approve | FIN | 07-finance/91-api-design.md |
| GET | /api/finance/vouchers/next-no | 次の凭证号プレビュー | finance:voucher:create | FIN | 07-finance/02-voucher-ledger.md |
| GET | /api/finance/vouchers/next-no | 次の凭证番号プレビュー | finance:voucher:create | FIN | 07-finance/91-api-design.md |
| DELETE | /api/finance/vouchers/{id} | 草稿削除（論理取消） | finance:voucher:update | FIN | 07-finance/02-voucher-ledger.md |
| DELETE | /api/finance/vouchers/{id} | 草稿削除（取消） | finance:voucher:update | FIN | 07-finance/91-api-design.md |
| GET | /api/finance/vouchers/{id} | 凭证詳細 | finance:voucher:view | FIN | 07-finance/02-voucher-ledger.md |
| GET | /api/finance/vouchers/{id} | 凭证詳細（行・補助核算・附件） | finance:voucher:view | FIN | 07-finance/91-api-design.md |
| PUT | /api/finance/vouchers/{id} | 凭证更新（status=10） | finance:voucher:update | FIN | 07-finance/02-voucher-ledger.md |
| PUT | /api/finance/vouchers/{id} | 凭证更新（status=10 のみ） | finance:voucher:update | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/vouchers/{id}/post | 记账 | finance:voucher:post | FIN | 07-finance/02-voucher-ledger.md |
| POST | /api/finance/vouchers/{id}/post | 記帳（过账） | finance:voucher:post | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/vouchers/{id}/print | 凭证 PDF | finance:voucher:print | FIN | 07-finance/02-voucher-ledger.md |
| POST | /api/finance/vouchers/{id}/print | 凭证 PDF（PRT-FIN-001） | finance:voucher:print | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/vouchers/{id}/reverse | 红字冲销生成 | finance:voucher:reverse | FIN | 07-finance/02-voucher-ledger.md |
| POST | /api/finance/vouchers/{id}/reverse | 赤伝冲销生成 | finance:voucher:reverse | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/vouchers/{id}/review | 审核 | finance:voucher:approve | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/vouchers/{id}/unpost | 反记账 | finance:voucher:unpost | FIN | 07-finance/02-voucher-ledger.md |
| POST | /api/finance/vouchers/{id}/unpost | 反記帳 | finance:voucher:unpost | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/vouchers/{id}/unreview | 取消审核 | finance:voucher:approve | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/write-offs | 核销登録 | finance:write-off:create | FIN | 07-finance/03-ap-payment.md |
| POST | /api/finance/write-offs | 核销登録（AR/AP/預収/預払） | finance:write-off:create | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/write-offs/auto | 自動核销（FIFO） | finance:write-off:create | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/write-offs/{id}/reverse | 反核销 | finance:write-off:reverse | FIN | 07-finance/91-api-design.md |
| POST | /api/finance/year-close | 年結実行 | finance:year-close:execute | FIN | 07-finance/07-period-reporting.md |
| POST | /api/finance/year-close | 年結実行（J30） | finance:year-close:execute | FIN | 07-finance/91-api-design.md |
| GET | /api/integration/api-call-logs/stats | 利用統計 | integration:api-client:view | INT | 09-integration/04-openapi-file-notify.md |
| GET | /api/integration/api-clients | クライアント一覧 | integration:api-client:view | INT | 09-integration/91-api-design.md |
| POST | /api/integration/api-clients | 発行（secret を一度だけ返す） | integration:api-client:create | INT | 09-integration/04-openapi-file-notify.md |
| POST | /api/integration/api-clients | 発行 | integration:api-client:create | INT | 09-integration/91-api-design.md |
| POST | /api/integration/api-clients/{id}/revoke | 失効 | integration:api-client:update | INT | 09-integration/91-api-design.md |
| GET | /api/integration/bank-accounts | 口座残高 | integration:bank-account:view | INT | 09-integration/91-api-design.md |
| GET | /api/integration/bank-payments | 付款指令一覧 | integration:bank-payment:view | INT | 09-integration/91-api-design.md |
| POST | /api/integration/bank-payments | 指令作成 | integration:bank-payment:create | INT | 09-integration/91-api-design.md |
| POST | /api/integration/bank-payments/{id}/query | 状態照会 | integration:bank-payment:view | INT | 09-integration/91-api-design.md |
| POST | /api/integration/bank-payments/{id}/submit | 送信 | integration:bank-payment:submit | INT | 09-integration/91-api-design.md |
| POST | /api/integration/bank-statement-files | 対账单取込 | integration:bank-statement:import | INT | 09-integration/91-api-design.md |
| GET | /api/integration/bank-statement-files/{id} | 取込結果 | integration:bank-statement:view | INT | 09-integration/91-api-design.md |
| GET | /api/integration/call-logs | 呼出ログ | integration:call-log:view | INT | 09-integration/91-api-design.md |
| POST | /api/integration/call-logs/exports | ログ出力（非同期） | integration:call-log:export | INT | 09-integration/91-api-design.md |
| GET | /api/integration/call-logs/{id} | 原文詳細（マスキング） | integration:call-log:view | INT | 09-integration/05-sync-monitor.md |
| GET | /api/integration/call-logs/{id} | 原文詳細 | integration:call-log:view | INT | 09-integration/91-api-design.md |
| POST | /api/integration/file-transfers | 本実行 | integration:file-transfer:import | INT | 09-integration/91-api-design.md |
| GET | /api/integration/file-transfers/{id}/errors | エラー行 CSV | integration:file-transfer:view | INT | 09-integration/91-api-design.md |
| GET | /api/integration/input-invoices | 進項一覧 | integration:input-invoice:view | INT | 09-integration/91-api-design.md |
| POST | /api/integration/input-invoices/verify | 査験 | integration:input-invoice:verify | INT | 09-integration/02-tax-bank-interface.md |
| POST | /api/integration/input-invoices/verify | 進項査験 | integration:input-invoice:verify | INT | 09-integration/91-api-design.md |
| POST | /api/integration/input-invoices/{id}/usage | 用途確認 | integration:input-invoice:verify | INT | 09-integration/91-api-design.md |
| GET | /api/integration/interface-configs/{id} | 詳細（secret 非返却） | integration:interface-config:view | INT | 09-integration/91-api-design.md |
| PUT | /api/integration/interface-configs/{id} | 更新 | integration:interface-config:update | INT | 09-integration/91-api-design.md |
| PUT | /api/integration/interface-configs/{id} | 更新（version 必須） | integration:interface-config:update | INT | 09-integration/01-integration-config.md |
| POST | /api/integration/interface-configs/{id}/credential | 凭证更新 | integration:credential:update | INT | 09-integration/91-api-design.md |
| POST | /api/integration/interface-configs/{id}/disable | 停止 | integration:interface-config:update | INT | 09-integration/91-api-design.md |
| POST | /api/integration/interface-configs/{id}/enable | 有効化 | integration:interface-config:update | INT | 09-integration/91-api-design.md |
| PUT | /api/integration/interface-configs/{id}/mappings | マッピング一括更新 | integration:interface-config:update | INT | 09-integration/91-api-design.md |
| POST | /api/integration/interface-configs/{id}/test | 接続テスト | integration:interface-config:test | INT | 09-integration/91-api-design.md |
| POST | /api/integration/mes/completions | 完工受信 | integration:mes:receive | INT | 09-integration/91-api-design.md |
| GET | /api/integration/mes/status | 連携状況集計 | integration:mes:view | INT | 09-integration/03-mes-wms-plm.md |
| GET | /api/integration/mes/status | 連携状況 | integration:mes:view | INT | 09-integration/91-api-design.md |
| POST | /api/integration/mes/work-orders | 工单下发（手動） | integration:mes:retry | INT | 09-integration/03-mes-wms-plm.md |
| POST | /api/integration/mes/work-orders | 工单下发 | integration:mes:retry | INT | 09-integration/91-api-design.md |
| POST | /api/integration/mes/work-orders/{no}/resend | 再下发 | integration:mes:retry | INT | 09-integration/91-api-design.md |
| POST | /api/integration/mes/work-reports | 報工受信 | integration:mes:receive | INT | 09-integration/91-api-design.md |
| GET | /api/integration/notification-channels | チャネル一覧 | integration:notification-channel:view | INT | 09-integration/91-api-design.md |
| GET | /api/integration/pda-devices | 端末一覧 | integration:pda-device:view | INT | 09-integration/91-api-design.md |
| POST | /api/integration/pda-devices/{id}/disable | 端末停止 | integration:pda-device:update | INT | 09-integration/91-api-design.md |
| POST | /api/integration/pda/offline-batches | 補伝受付 | integration:pda:use | INT | 09-integration/91-api-design.md |
| POST | /api/integration/pda/scans | スキャン受付 | integration:pda:use | INT | 09-integration/91-api-design.md |
| GET | /api/integration/plm/imports | 取込一覧 | integration:plm:view | INT | 09-integration/91-api-design.md |
| POST | /api/integration/plm/imports | PLM 取込 | integration:plm:import | INT | 09-integration/91-api-design.md |
| POST | /api/integration/plm/imports/{id}/approve | 取込承認 | integration:plm:approve | INT | 09-integration/91-api-design.md |
| GET | /api/integration/reconciliations | 対账結果一覧 | integration:reconcile:view | INT | 09-integration/91-api-design.md |
| POST | /api/integration/reconciliations/run | 対账再実行（管理者） | integration:reconcile:view | INT | 09-integration/05-sync-monitor.md |
| POST | /api/integration/reconciliations/run | 対账再実行 | integration:reconcile:view | INT | 09-integration/91-api-design.md |
| GET | /api/integration/sync-tasks | タスク一覧 | integration:sync-task:view | INT | 09-integration/91-api-design.md |
| POST | /api/integration/sync-tasks/batch-retry | 一括再送 | integration:sync-task:retry | INT | 09-integration/91-api-design.md |
| GET | /api/integration/sync-tasks/{id} | タスク詳細・履歴 | integration:sync-task:view | INT | 09-integration/91-api-design.md |
| POST | /api/integration/sync-tasks/{id}/retry | 単件再送 | integration:sync-task:retry | INT | 09-integration/91-api-design.md |
| GET | /api/integration/tax-invoices | 数电票一覧 | integration:tax-invoice:view | INT | 09-integration/91-api-design.md |
| POST | /api/integration/tax-invoices | 数电票开具 | integration:tax-invoice:create | INT | 09-integration/91-api-design.md |
| GET | /api/integration/tax-invoices/{id} | 数电票詳細 | integration:tax-invoice:view | INT | 09-integration/91-api-design.md |
| POST | /api/integration/tax-invoices/{id}/red | 赤伝起票 | integration:tax-invoice:red | INT | 09-integration/91-api-design.md |
| GET | /api/open/v1/customers | 顧客照会（自社関連のみ） |  | INT | 09-integration/04-openapi-file-notify.md |
| GET | /api/open/v1/customers | 顧客照会 |  | INT | 09-integration/91-api-design.md |
| GET | /api/open/v1/deliveries | 出荷実績 |  | INT | 09-integration/91-api-design.md |
| GET | /api/open/v1/materials | 物料照会（コード・名称・単位） |  | INT | 09-integration/04-openapi-file-notify.md |
| GET | /api/open/v1/materials | 物料照会 |  | INT | 09-integration/91-api-design.md |
| GET | /api/open/v1/purchase-orders | 発注照会（サプライヤ向け） |  | INT | 09-integration/04-openapi-file-notify.md |
| GET | /api/open/v1/purchase-orders | 発注照会 |  | INT | 09-integration/91-api-design.md |
| GET | /api/open/v1/reports/stock-summary | 在庫サマリ（Phase 2） |  | INT | 09-integration/04-openapi-file-notify.md |
| GET | /api/open/v1/reports/stock-summary | 在庫サマリ（P2） |  | INT | 09-integration/91-api-design.md |
| GET | /api/open/v1/sales-orders | 受注照会（期間・状態） |  | INT | 09-integration/04-openapi-file-notify.md |
| POST | /api/open/v1/sales-orders | 受注登録（取引先 EDI） |  | INT | 09-integration/04-openapi-file-notify.md |
| POST | /api/open/v1/sales-orders | 受注登録（P2） |  | INT | 09-integration/91-api-design.md |
| GET | /api/open/v1/sales-orders/{no} | 受注詳細 |  | INT | 09-integration/91-api-design.md |
| GET | /api/open/v1/stock-balances | 在庫残高照会（倉庫・物料） |  | INT | 09-integration/04-openapi-file-notify.md |
| GET | /api/open/v1/stock-balances | 在庫残高 |  | INT | 09-integration/91-api-design.md |
| GET | /api/inventory/batches | 批次一覧 | inventory:batch:view | INV | 05-inventory/91-api-design.md |
| GET | /api/inventory/batches/expiry-warnings | 效期预警一覧 | inventory:batch:view | INV | 05-inventory/04-batch-serial-status.md |
| GET | /api/inventory/batches/expiry-warnings | 有效期警告一覧 | inventory:batch:view | INV | 05-inventory/91-api-design.md |
| GET | /api/inventory/batches/{id} | 批次詳細 | inventory:batch:view | INV | 05-inventory/91-api-design.md |
| PATCH | /api/inventory/batches/{id} | 批次の任意項目更新（QC 状態・原産国・remark のみ） | inventory:batch:view（限定） | INV | 05-inventory/04-batch-serial-status.md |
| PATCH | /api/inventory/batches/{id} | 批次の限定更新（QC 状態等） | inventory:batch:view | INV | 05-inventory/91-api-design.md |
| GET | /api/inventory/batches/{id}/trace | 批次追溯（前向/後向） | inventory:batch:trace | INV | 05-inventory/91-api-design.md |
| GET | /api/inventory/cost-adjustments | 成本調整単一覧 | inventory:cost:view | INV | 05-inventory/91-api-design.md |
| POST | /api/inventory/cost-adjustments | 成本調整単登録（CA 採番） | inventory:cost:adjust | INV | 05-inventory/05-costing.md |
| POST | /api/inventory/cost-adjustments | 成本調整単登録 | inventory:cost:adjust | INV | 05-inventory/91-api-design.md |
| GET | /api/inventory/cost-adjustments/{id} | 成本調整単詳細 | inventory:cost:view | INV | 05-inventory/91-api-design.md |
| PUT | /api/inventory/cost-adjustments/{id} | 成本調整単更新（草稿） | inventory:cost:adjust | INV | 05-inventory/91-api-design.md |
| POST | /api/inventory/cost-adjustments/{id}/post | 過账（在庫金額更新・E19） | inventory:cost:adjust | INV | 05-inventory/05-costing.md |
| POST | /api/inventory/cost-adjustments/{id}/post | 過账（E19） | inventory:cost:adjust | INV | 05-inventory/91-api-design.md |
| POST | /api/inventory/cost-adjustments/{id}/reverse | 冲销（期間内） | inventory:cost:adjust | INV | 05-inventory/05-costing.md |
| POST | /api/inventory/cost-adjustments/{id}/reverse | 沖销（期間内） | inventory:cost:adjust | INV | 05-inventory/91-api-design.md |
| GET | /api/inventory/costs/adjustment-base | 調整基礎情報（対象入庫・既出庫数量） | inventory:cost:adjust | INV | 05-inventory/05-costing.md |
| GET | /api/inventory/costs/adjustment-base | 調整基礎情報 | inventory:cost:adjust | INV | 05-inventory/91-api-design.md |
| GET | /api/inventory/costs/balances | cost group 別の数量・金額・平均単価 | inventory:cost:view | INV | 05-inventory/05-costing.md |
| GET | /api/inventory/costs/balances | cost group 別 数量・金額・平均単価 | inventory:cost:view | INV | 05-inventory/91-api-design.md |
| GET | /api/inventory/costs/layers | 成本層一覧（庫齢・残数量） | inventory:cost:view | INV | 05-inventory/05-costing.md |
| GET | /api/inventory/costs/layers | 成本層一覧 | inventory:cost:view | INV | 05-inventory/91-api-design.md |
| GET | /api/inventory/costs/movements | 原価流水（平均単価の推移） | inventory:cost:view | INV | 05-inventory/05-costing.md |
| GET | /api/inventory/costs/movements | 原価流水（平均単価推移） | inventory:cost:view | INV | 05-inventory/91-api-design.md |
| POST | /api/inventory/costs/recalculate | 期間再計算（202 ジョブ） | inventory:cost:recalc | INV | 05-inventory/05-costing.md |
| POST | /api/inventory/costs/recalculate | 期間再計算（202） | inventory:cost:recalc | INV | 05-inventory/91-api-design.md |
| GET | /api/inventory/jobs/{jobId} | ジョブ結果（差異一覧） | inventory:cost:recalc | INV | 05-inventory/05-costing.md |
| GET | /api/inventory/jobs/{jobId} | 月结ジョブ結果 | inventory:period:close | INV | 05-inventory/06-reservation-barcode-close.md |
| GET | /api/inventory/jobs/{jobId} | 非同期ジョブ結果 | 各ジョブ起動権限 | INV | 05-inventory/91-api-design.md |
| POST | /api/inventory/labels/print | ラベル印刷（PRT-INV-017） | inventory:barcode:print | INV | 05-inventory/06-reservation-barcode-close.md |
| POST | /api/inventory/labels/print | ラベル印刷 | inventory:barcode:print | INV | 05-inventory/91-api-design.md |
| GET | /api/inventory/periods | 期間一覧・状態 | inventory:period:view | INV | 05-inventory/91-api-design.md |
| POST | /api/inventory/periods/{periodCode}/close | 月结実行（202 ジョブ） | inventory:period:close | INV | 05-inventory/06-reservation-barcode-close.md |
| POST | /api/inventory/periods/{periodCode}/close | 月结実行（202） | inventory:period:close | INV | 05-inventory/91-api-design.md |
| POST | /api/inventory/periods/{periodCode}/close-checks | 前置检查（ドライラン） | inventory:period:close | INV | 05-inventory/06-reservation-barcode-close.md |
| POST | /api/inventory/periods/{periodCode}/close-checks | 月结前置检查（ドライラン） | inventory:period:close | INV | 05-inventory/91-api-design.md |
| POST | /api/inventory/periods/{periodCode}/reopen | 再开 | inventory:period:reopen | INV | 05-inventory/06-reservation-barcode-close.md |
| POST | /api/inventory/periods/{periodCode}/reopen | 期間再开 | inventory:period:reopen | INV | 05-inventory/91-api-design.md |
| GET | /api/inventory/replenishments | 補貨建議一覧 | inventory:replenishment:view | INV | 05-inventory/91-api-design.md |
| GET | /api/inventory/replenishments/export | 建議 CSV/Excel 出力（PUR 連携用） | inventory:replenishment:view | INV | 05-inventory/07-reports.md |
| POST | /api/inventory/replenishments/generate | 建議生成（202 ジョブ） | inventory:replenishment:generate | INV | 05-inventory/07-reports.md |
| POST | /api/inventory/replenishments/generate | 建議生成（202） | inventory:replenishment:generate | INV | 05-inventory/91-api-design.md |
| POST | /api/inventory/replenishments/{id}/ignore | 建議の無視（理由必須） | inventory:replenishment:generate | INV | 05-inventory/07-reports.md |
| POST | /api/inventory/replenishments/{id}/ignore | 建議の無視 | inventory:replenishment:generate | INV | 05-inventory/91-api-design.md |
| POST | /api/inventory/replenishments/{id}/mark-ordered | 請購作成済の記録 | inventory:replenishment:generate | INV | 05-inventory/91-api-design.md |
| GET | /api/inventory/reports/age | 庫齢分析（区分別・明細） | inventory:report:view | INV | 05-inventory/07-reports.md |
| GET | /api/inventory/reports/age | 庫齢分析 | inventory:report:view | INV | 05-inventory/91-api-design.md |
| GET | /api/inventory/reports/slow-moving | 呆滞料一覧 | inventory:report:view | INV | 05-inventory/91-api-design.md |
| GET | /api/inventory/reports/stock-summary | 收发存汇总（期間×倉庫×物料） | inventory:report:view | INV | 05-inventory/07-reports.md |
| GET | /api/inventory/reports/stock-summary | 受発存汇总 | inventory:report:view | INV | 05-inventory/91-api-design.md |
| GET | /api/inventory/reports/turnover | 在庫回転率（期間・年化） | inventory:report:view | INV | 05-inventory/07-reports.md |
| GET | /api/inventory/reports/turnover | 在庫回転率 | inventory:report:view | INV | 05-inventory/91-api-design.md |
| POST | /api/inventory/reports/{reportCode}/print | 帳票 PDF 出力 | inventory:report:export | INV | 05-inventory/91-api-design.md |
| GET | /api/inventory/reservations | 予約一覧 | inventory:reservation:view | INV | 05-inventory/91-api-design.md |
| POST | /api/inventory/reservations | 手動引当（計画員） | inventory:reservation:create | INV | 05-inventory/06-reservation-barcode-close.md |
| POST | /api/inventory/reservations | 手動引当 | inventory:reservation:create | INV | 05-inventory/91-api-design.md |
| POST | /api/inventory/reservations/allocate | 來源単位の引当（内部/API） | inventory:reservation:create | INV | 05-inventory/06-reservation-barcode-close.md |
| POST | /api/inventory/reservations/allocate | 來源単位の引当（内部） | inventory:reservation:create | INV | 05-inventory/91-api-design.md |
| GET | /api/inventory/reservations/{id} | 予約詳細 | inventory:reservation:view | INV | 05-inventory/91-api-design.md |
| POST | /api/inventory/reservations/{id}/release | 予約解放 | inventory:reservation:release | INV | 05-inventory/91-api-design.md |
| POST | /api/inventory/scan-sessions | スキャンセッション開始 | inventory:barcode:scan | INV | 05-inventory/91-api-design.md |
| GET | /api/inventory/scan-sessions/{id} | セッション状態・明細 | inventory:barcode:scan | INV | 05-inventory/06-reservation-barcode-close.md |
| GET | /api/inventory/scan-sessions/{id} | セッション状態 | inventory:barcode:scan | INV | 05-inventory/91-api-design.md |
| POST | /api/inventory/scans | スキャン（検証・数量加算） | inventory:barcode:scan | INV | 05-inventory/91-api-design.md |
| POST | /api/inventory/scans/sync | オフライン実績の一括送信 | inventory:barcode:scan | INV | 05-inventory/91-api-design.md |
| GET | /api/inventory/serials | 序列号一覧 | inventory:serial:view | INV | 05-inventory/91-api-design.md |
| GET | /api/inventory/serials/{serialNo} | 序列号詳細 | inventory:serial:view | INV | 05-inventory/91-api-design.md |
| GET | /api/inventory/serials/{serialNo}/trace | 序列号履歴・追溯 | inventory:serial:view | INV | 05-inventory/04-batch-serial-status.md |
| GET | /api/inventory/serials/{serialNo}/trace | 序列号履歴 | inventory:serial:view | INV | 05-inventory/91-api-design.md |
| GET | /api/inventory/sources/{sourceType}/{sourceId}/lines | 來源伝票の未処理明細取得 | inventory:stock-txn:view | INV | 05-inventory/02-inbound-outbound.md |
| GET | /api/inventory/sources/{sourceType}/{sourceId}/lines | 来源伝票の未処理明細 | inventory:stock-txn:view | INV | 05-inventory/91-api-design.md |
| GET | /api/inventory/status-conversions | 変換履歴 | inventory:status:change | INV | 05-inventory/04-batch-serial-status.md |
| GET | /api/inventory/status-conversions | 状態変換履歴 | inventory:status:change | INV | 05-inventory/91-api-design.md |
| POST | /api/inventory/status-conversions | 状態変換（即時/承認提出） | inventory:status:change | INV | 05-inventory/04-batch-serial-status.md |
| POST | /api/inventory/status-conversions | 在庫状態変換 | inventory:status:change | INV | 05-inventory/91-api-design.md |
| POST | /api/inventory/status-conversions/{id}/submit | 状態変換の承認提出 | inventory:status:change | INV | 05-inventory/91-api-design.md |
| GET | /api/inventory/stock-balances | 在庫残高照会（ページング） | inventory:stock-balance:view | INV | 05-inventory/91-api-design.md |
| GET | /api/inventory/stock-balances/available | 可用量照会（集約） | inventory:stock-balance:view（内部はサービス呼出） | INV | 05-inventory/91-api-design.md |
| GET | /api/inventory/stock-balances/available-batches | 批次別可用量（FEFO/FIFO） | inventory:stock-balance:view | INV | 05-inventory/91-api-design.md |
| GET | /api/inventory/stock-balances/in-transit | 在途量照会 | inventory:transfer:view | INV | 05-inventory/91-api-design.md |
| GET | /api/inventory/stock-balances/summary | 物料別集約（横持ち表示） | inventory:stock-balance:view | INV | 05-inventory/01-stock-query.md |
| GET | /api/inventory/stock-balances/summary | 物料別集約 | inventory:stock-balance:view | INV | 05-inventory/91-api-design.md |
| GET | /api/inventory/stock-txns | 事務流水一覧 | inventory:stock-txn:view | INV | 05-inventory/91-api-design.md |
| POST | /api/inventory/stock-txns | 入出庫伝票の登録（草稿。手動は AOI/AOO/SC_OUT のみ、他は補正用） | inventory:stock-txn:create | INV | 05-inventory/02-inbound-outbound.md |
| POST | /api/inventory/stock-txns | 入出庫伝票の登録（草稿） | inventory:stock-txn:create | INV | 05-inventory/91-api-design.md |
| GET | /api/inventory/stock-txns/ledger | 台帳（結存推移） | inventory:stock-txn:view | INV | 05-inventory/91-api-design.md |
| GET | /api/inventory/stock-txns/recalculate | 原価再計算プレビュー（保存しない） | inventory:cost:view | INV | 05-inventory/91-api-design.md |
| POST | /api/inventory/stock-txns/scan-load | スキャン結果から明細生成 | inventory:barcode:scan | INV | 05-inventory/91-api-design.md |
| GET | /api/inventory/stock-txns/{id} | 事務詳細（明細含む） | inventory:stock-txn:view | INV | 05-inventory/91-api-design.md |
| PUT | /api/inventory/stock-txns/{id} | 草稿の更新（楽観排他） | inventory:stock-txn:update | INV | 05-inventory/02-inbound-outbound.md |
| PUT | /api/inventory/stock-txns/{id} | 草稿の更新 | inventory:stock-txn:update | INV | 05-inventory/91-api-design.md |
| POST | /api/inventory/stock-txns/{id}/cancel | 草稿取消 | inventory:stock-txn:update | INV | 05-inventory/91-api-design.md |
| POST | /api/inventory/stock-txns/{id}/post | 過账（在庫更新） | inventory:stock-txn:post | INV | 05-inventory/91-api-design.md |
| POST | /api/inventory/stock-txns/{id}/print | 伝票 PDF 出力 | inventory:stock-txn:print | INV | 05-inventory/91-api-design.md |
| POST | /api/inventory/stock-txns/{id}/reverse | 事務沖销 | inventory:stock-txn:reverse | INV | 05-inventory/91-api-design.md |
| POST | /api/inventory/stock-txns/{id}/reverse | 沖销 | inventory:stock-txn:reverse | INV | 05-inventory/02-inbound-outbound.md |
| POST | /api/inventory/stock-txns/{id}/submit | 承認提出（承認対象のみ） | inventory:stock-txn:submit | INV | 05-inventory/02-inbound-outbound.md |
| GET | /api/inventory/stocktake-plans | 盘点計画一覧 | inventory:stocktake:view | INV | 05-inventory/03-transfer-count.md |
| GET | /api/inventory/stocktake-plans | 盤点計画一覧 | inventory:stocktake:view | INV | 05-inventory/91-api-design.md |
| POST | /api/inventory/stocktake-plans | 盘点計画登録 | inventory:stocktake:create | INV | 05-inventory/03-transfer-count.md |
| POST | /api/inventory/stocktake-plans | 盤点計画登録 | inventory:stocktake:create | INV | 05-inventory/91-api-design.md |
| POST | /api/inventory/stocktake-plans/{id}/generate | 盘点単生成 | inventory:stocktake:create | INV | 05-inventory/03-transfer-count.md |
| POST | /api/inventory/stocktake-plans/{id}/generate | 盤点単生成 | inventory:stocktake:create | INV | 05-inventory/91-api-design.md |
| POST | /api/inventory/stocktake-plans/{id}/submit | 計画提出 | inventory:stocktake:create | INV | 05-inventory/91-api-design.md |
| GET | /api/inventory/stocktakes | 盘点単一覧 | inventory:stocktake:view | INV | 05-inventory/03-transfer-count.md |
| GET | /api/inventory/stocktakes | 盤点単一覧 | inventory:stocktake:view | INV | 05-inventory/91-api-design.md |
| GET | /api/inventory/stocktakes/{id} | 盘点単詳細（明細含む） | inventory:stocktake:view | INV | 05-inventory/03-transfer-count.md |
| GET | /api/inventory/stocktakes/{id} | 盤点単詳細 | inventory:stocktake:view | INV | 05-inventory/91-api-design.md |
| POST | /api/inventory/stocktakes/{id}/adjust | 調整実行（ADJ_IN/ADJ_OUT） | inventory:stocktake:adjust | INV | 05-inventory/03-transfer-count.md |
| POST | /api/inventory/stocktakes/{id}/adjust | 調整実行（ADJ_IN/OUT） | inventory:stocktake:adjust | INV | 05-inventory/91-api-design.md |
| POST | /api/inventory/stocktakes/{id}/approve | 承認（WF 連携時はコールバック） | inventory:stocktake:approve | INV | 05-inventory/03-transfer-count.md |
| POST | /api/inventory/stocktakes/{id}/approve | 承認（WF コールバック含む） | inventory:stocktake:approve | INV | 05-inventory/91-api-design.md |
| POST | /api/inventory/stocktakes/{id}/calc-diff | 差異計算 | inventory:stocktake:enter | INV | 05-inventory/91-api-design.md |
| POST | /api/inventory/stocktakes/{id}/import | Excel 取込（2 段階） | inventory:stocktake:enter | INV | 05-inventory/91-api-design.md |
| PUT | /api/inventory/stocktakes/{id}/lines | 実盤数量の一括更新 | inventory:stocktake:enter | INV | 05-inventory/91-api-design.md |
| POST | /api/inventory/stocktakes/{id}/print | 盘点表 PDF | inventory:stocktake:view | INV | 05-inventory/03-transfer-count.md |
| POST | /api/inventory/stocktakes/{id}/print | 盤点表 PDF | inventory:stocktake:view | INV | 05-inventory/91-api-design.md |
| POST | /api/inventory/stocktakes/{id}/scan | PDA スキャン入力 | inventory:barcode:scan | INV | 05-inventory/91-api-design.md |
| POST | /api/inventory/stocktakes/{id}/start | 実盤開始（凍結開始） | inventory:stocktake:enter | INV | 05-inventory/03-transfer-count.md |
| POST | /api/inventory/stocktakes/{id}/start | 実盤開始（凍結） | inventory:stocktake:enter | INV | 05-inventory/91-api-design.md |
| POST | /api/inventory/stocktakes/{id}/submit | 差異確定・承認提出 | inventory:stocktake:submit | INV | 05-inventory/91-api-design.md |
| GET | /api/inventory/transfers | 調撥一覧 | inventory:transfer:view | INV | 05-inventory/91-api-design.md |
| POST | /api/inventory/transfers | 調撥登録（草稿） | inventory:transfer:create | INV | 05-inventory/03-transfer-count.md |
| POST | /api/inventory/transfers | 調撥登録 | inventory:transfer:create | INV | 05-inventory/91-api-design.md |
| GET | /api/inventory/transfers/in-transit | 在途一覧 | inventory:transfer:view | INV | 05-inventory/91-api-design.md |
| GET | /api/inventory/transfers/{id} | 調撥詳細 | inventory:transfer:view | INV | 05-inventory/91-api-design.md |
| PUT | /api/inventory/transfers/{id} | 調撥更新（草稿） | inventory:transfer:create | INV | 05-inventory/91-api-design.md |
| POST | /api/inventory/transfers/{id}/print | 調撥単 PDF | inventory:transfer:print | INV | 05-inventory/91-api-design.md |
| POST | /api/inventory/transfers/{id}/receive | 受入（TR_IN） | inventory:transfer:receive | INV | 05-inventory/91-api-design.md |
| POST | /api/inventory/transfers/{id}/return | 退回（残量を源倉庫へ） | inventory:transfer:receive | INV | 05-inventory/91-api-design.md |
| POST | /api/inventory/transfers/{id}/ship | 出庫（TR_OUT） | inventory:transfer:ship | INV | 05-inventory/91-api-design.md |
| GET | /api/mdm/banks | 銀行一覧 | mdm:bank:view | MDM | 02-mdm/91-api-design.md |
| POST/PUT | /api/mdm/banks[/{id}] | 銀行 CRUD | mdm:bank:update | MDM | 02-mdm/91-api-design.md |
| GET | /api/mdm/barcode-rules | 条码規則一覧 | mdm:barcode-rule:view | MDM | 02-mdm/07-substitute-barcode-governance.md |
| GET/POST/PUT | /api/mdm/barcode-rules[/{id}] | 条码規則 CRUD | mdm:barcode-rule:view/update | MDM | 02-mdm/91-api-design.md |
| GET | /api/mdm/change-requests | 変更申請一覧 | mdm:change:view | MDM | 02-mdm/91-api-design.md |
| POST | /api/mdm/change-requests/{id}/approve | 承認・反映 | mdm:change:approve | MDM | 02-mdm/91-api-design.md |
| POST | /api/mdm/change-requests/{id}/reject | 却下/差戻し | mdm:change:approve | MDM | 02-mdm/91-api-design.md |
| POST | /api/mdm/change-requests/{id}/submit | 提出 | 対象 update 権限 | MDM | 02-mdm/91-api-design.md |
| POST/PUT | /api/mdm/change-requests[/{id}] | 変更申請 CRUD | 対象 update 権限 | MDM | 02-mdm/91-api-design.md |
| GET | /api/mdm/code-rules | 編碼規則一覧 | mdm:code-rule:update | MDM | 02-mdm/01-material-master.md |
| GET | /api/mdm/code-rules | 编码規則一覧 | mdm:code-rule:update | MDM | 02-mdm/91-api-design.md |
| PUT | /api/mdm/code-rules/{id} | 編碼規則更新 | mdm:code-rule:update | MDM | 02-mdm/01-material-master.md |
| PUT | /api/mdm/code-rules/{id} | 编码規則更新 | mdm:code-rule:update | MDM | 02-mdm/91-api-design.md |
| GET | /api/mdm/credit-check-rules | 規則一覧 | mdm:credit:view | MDM | 02-mdm/06-credit-supplier-eval.md |
| GET/POST/PUT | /api/mdm/credit-check-rules[/{id}] | 检查規則 CRUD | mdm:credit:view/update | MDM | 02-mdm/91-api-design.md |
| POST/PUT | /api/mdm/credit-check-rules[/{id}] | 規則 CRUD | mdm:credit:update | MDM | 02-mdm/06-credit-supplier-eval.md |
| GET | /api/mdm/credit-limits | 与信一覧 | mdm:credit:view | MDM | 02-mdm/91-api-design.md |
| GET | /api/mdm/credit-limits/{id} | 与信詳細 | mdm:credit:view | MDM | 02-mdm/91-api-design.md |
| POST | /api/mdm/credit-limits/{id}/freeze | 凍結 | mdm:credit:update | MDM | 02-mdm/91-api-design.md |
| POST | /api/mdm/credit-limits/{id}/unfreeze | 凍結解除 | mdm:credit:update | MDM | 02-mdm/91-api-design.md |
| POST/PUT | /api/mdm/credit-limits[/{id}] | 与信登録・変更 | mdm:credit:update | MDM | 02-mdm/06-credit-supplier-eval.md |
| POST/PUT | /api/mdm/credit-limits[/{id}] | 与信 CRUD | mdm:credit:update | MDM | 02-mdm/91-api-design.md |
| GET | /api/mdm/currencies | 通貨一覧 | mdm:currency:view | MDM | 02-mdm/91-api-design.md |
| GET | /api/mdm/currencies/{code} | 通貨照会 | mdm:currency:view | MDM | 02-mdm/91-api-design.md |
| POST/PUT | /api/mdm/currencies[/{id}] | 通貨 CRUD | mdm:currency:update | MDM | 02-mdm/91-api-design.md |
| GET | /api/mdm/customers | 客户一覧 | mdm:customer:view | MDM | 02-mdm/91-api-design.md |
| POST | /api/mdm/customers | 客户登録 | mdm:customer:create | MDM | 02-mdm/91-api-design.md |
| GET | /api/mdm/customers/check-tax-no | 税号重複チェック | mdm:customer:view | MDM | 02-mdm/91-api-design.md |
| POST | /api/mdm/customers/import / /suppliers/import | 一括取込 | mdm:customer:import 等 | MDM | 02-mdm/02-business-partner.md |
| GET | /api/mdm/customers/{customerId}/credit-limit | 顧客与信照会（SAL/FIN 共用） | mdm:customer:credit:view | MDM | 02-mdm/06-credit-supplier-eval.md |
| GET | /api/mdm/customers/{id} | 客户詳細 | mdm:customer:view | MDM | 02-mdm/91-api-design.md |
| PUT | /api/mdm/customers/{id} | 客户更新 | mdm:customer:update | MDM | 02-mdm/91-api-design.md |
| GET | /api/mdm/customers/{id}/addresses | 住所一覧 | mdm:customer:view | MDM | 02-mdm/91-api-design.md |
| POST/PUT/DELETE | /api/mdm/customers/{id}/addresses[/{addressId}] | 住所 CRUD | mdm:customer:update | MDM | 02-mdm/91-api-design.md |
| GET | /api/mdm/customers/{id}/contacts | 連絡先一覧 | mdm:customer:view | MDM | 02-mdm/91-api-design.md |
| POST/PUT/DELETE | /api/mdm/customers/{id}/contacts[/{contactId}] | 連絡先 CRUD | mdm:customer:update | MDM | 02-mdm/91-api-design.md |
| GET | /api/mdm/customers/{id}/credit-limit | 与信情報 | mdm:customer:credit:view | MDM | 02-mdm/02-business-partner.md |
| GET | /api/mdm/customers/{id}/credit-limit | 与信照会（SAL/FIN 共用） | mdm:customer:credit:view | MDM | 02-mdm/91-api-design.md |
| GET | /api/mdm/data-quality-issues | 問題一覧 | mdm:data-quality:view | MDM | 02-mdm/91-api-design.md |
| PUT | /api/mdm/data-quality-issues/{id} | 担当割当・状態更新 | mdm:data-quality:update | MDM | 02-mdm/07-substitute-barcode-governance.md |
| PUT | /api/mdm/data-quality-issues/{id} | 問題更新・クローズ | mdm:data-quality:update | MDM | 02-mdm/91-api-design.md |
| GET | /api/mdm/data-quality-rules | 品質規則一覧 | mdm:data-quality:view | MDM | 02-mdm/07-substitute-barcode-governance.md |
| GET/POST/PUT | /api/mdm/data-quality-rules[/{id}] | 品質規則 CRUD | mdm:data-quality:view/update | MDM | 02-mdm/91-api-design.md |
| POST | /api/mdm/data-quality-runs | 品質チェック実行 | mdm:data-quality:update | MDM | 02-mdm/91-api-design.md |
| GET/PUT | /api/mdm/data-scope-policies[/{id}] | データ権限ポリシー | mdm:data-scope:update | MDM | 02-mdm/07-substitute-barcode-governance.md |
| GET/PUT | /api/mdm/data-scope-policies[/{id}] | データ権限策略 | mdm:data-scope:update | MDM | 02-mdm/91-api-design.md |
| GET | /api/mdm/exchange-rates | レート一覧 | mdm:exchange-rate:view | MDM | 02-mdm/91-api-design.md |
| GET | /api/mdm/exchange-rates/effective | 有効レート取得（他域共用） | mdm:exchange-rate:view | MDM | 02-mdm/04-uom-currency-tax.md |
| GET | /api/mdm/exchange-rates/effective | 有効レート | mdm:exchange-rate:view | MDM | 02-mdm/91-api-design.md |
| POST/PUT | /api/mdm/exchange-rates[/{id}] | レート CRUD | mdm:exchange-rate:update | MDM | 02-mdm/91-api-design.md |
| POST | /api/mdm/exports | エクスポートジョブ | mdm:material:export | MDM | 02-mdm/01-material-master.md |
| POST | /api/mdm/exports | エクスポート（202） | mdm:*:export | MDM | 02-mdm/91-api-design.md |
| GET | /api/mdm/factories | 工場一覧（他域参照） | mdm:factory:view | MDM | 02-mdm/03-warehouse-location.md |
| GET | /api/mdm/factories | 工厂一覧（他域共用） | mdm:factory:view | MDM | 02-mdm/91-api-design.md |
| POST | /api/mdm/factories | 工場登録 | mdm:factory:update | MDM | 02-mdm/03-warehouse-location.md |
| POST | /api/mdm/factories | 工厂登録 | mdm:factory:update | MDM | 02-mdm/91-api-design.md |
| PUT | /api/mdm/factories/{id} | 工場更新 | mdm:factory:update | MDM | 02-mdm/03-warehouse-location.md |
| PUT | /api/mdm/factories/{id} | 工厂更新 | mdm:factory:update | MDM | 02-mdm/91-api-design.md |
| GET | /api/mdm/import-templates/{type} | 取込テンプレート DL | 各 import 権限 | MDM | 02-mdm/04-uom-currency-tax.md |
| POST | /api/mdm/imports | 標準コード取込（ドライラン/実行） | mdm:exchange-rate:import 等 | MDM | 02-mdm/04-uom-currency-tax.md |
| POST | /api/mdm/imports | 一括维护（ドライラン/実行） | 各 import 権限 | MDM | 02-mdm/07-substitute-barcode-governance.md |
| POST | /api/mdm/imports | 一括取込（ドライラン/実行） | 各 import 権限 | MDM | 02-mdm/91-api-design.md |
| GET | /api/mdm/imports/{jobId}/errors | エラー CSV DL | 各 import 権限 | MDM | 02-mdm/07-substitute-barcode-governance.md |
| GET | /api/mdm/imports/{jobId}/errors | エラー CSV | 各 import 権限 | MDM | 02-mdm/91-api-design.md |
| POST | /api/mdm/material-barcodes | 条码発行 | mdm:barcode:print | MDM | 02-mdm/91-api-design.md |
| POST | /api/mdm/material-barcodes/labels | ラベル PDF | mdm:barcode:print | MDM | 02-mdm/91-api-design.md |
| GET | /api/mdm/material-categories |  |  | MDM | 02-mdm/01-material-master.md |
| GET | /api/mdm/material-categories | 分類一覧 | mdm:material:view | MDM | 02-mdm/91-api-design.md |
| GET | /api/mdm/material-categories/tree | 分類樹取得 | mdm:material:view | MDM | 02-mdm/01-material-master.md |
| GET | /api/mdm/material-categories/tree | 分類樹 | mdm:material:view | MDM | 02-mdm/91-api-design.md |
| POST/PUT/DELETE | /api/mdm/material-categories[/{id}] | 分類 CRUD | mdm:material-category:update | MDM | 02-mdm/91-api-design.md |
| GET | /api/mdm/material-substitutes | 代替一覧 | mdm:substitute:view | MDM | 02-mdm/91-api-design.md |
| POST | /api/mdm/material-substitutes/validate | 整合チェック | mdm:substitute:update | MDM | 02-mdm/91-api-design.md |
| DELETE | /api/mdm/material-substitutes/{id} | 論理削除 | mdm:substitute:update | MDM | 02-mdm/91-api-design.md |
| POST/PUT | /api/mdm/material-substitutes[/{id}] | 代替 CRUD | mdm:substitute:update | MDM | 02-mdm/91-api-design.md |
| GET | /api/mdm/materials | 物料一覧検索 | mdm:material:view | MDM | 02-mdm/01-material-master.md |
| GET | /api/mdm/materials | 物料一覧 | mdm:material:view | MDM | 02-mdm/91-api-design.md |
| POST | /api/mdm/materials | 新規登録 | mdm:material:create | MDM | 02-mdm/01-material-master.md |
| POST | /api/mdm/materials | 物料登録 | mdm:material:create | MDM | 02-mdm/91-api-design.md |
| POST | /api/mdm/materials/batch-get |  |  | MDM | 02-mdm/01-material-master.md |
| POST | /api/mdm/materials/batch-get | 一括参照（≤500） | mdm:material:view | MDM | 02-mdm/91-api-design.md |
| GET | /api/mdm/materials/by-code/{code} | コード照会（他域参照用） | mdm:material:view | MDM | 02-mdm/01-material-master.md |
| GET | /api/mdm/materials/by-code/{code} | コード参照 | mdm:material:view | MDM | 02-mdm/91-api-design.md |
| POST | /api/mdm/materials/import | 一括取込（検証→実行） | mdm:material:import | MDM | 02-mdm/01-material-master.md |
| GET | /api/mdm/materials/{id} | 物料詳細（全視図） | mdm:material:view | MDM | 02-mdm/01-material-master.md |
| GET | /api/mdm/materials/{id} | 物料詳細（多視図） | mdm:material:view | MDM | 02-mdm/91-api-design.md |
| PUT | /api/mdm/materials/{id} | 物料更新 | mdm:material:update | MDM | 02-mdm/91-api-design.md |
| POST | /api/mdm/materials/{id}/deactivate | 使用停止申請 | mdm:material:delete | MDM | 02-mdm/91-api-design.md |
| GET | /api/mdm/materials/{id}/factories | 工廠視図一覧 | mdm:material:view | MDM | 02-mdm/01-material-master.md |
| GET | /api/mdm/materials/{id}/factories | 工厂視図一覧 | mdm:material:view | MDM | 02-mdm/91-api-design.md |
| PUT | /api/mdm/materials/{id}/factories/{factoryId} | 工廠視図更新 | mdm:material-factory:update | MDM | 02-mdm/01-material-master.md |
| PUT | /api/mdm/materials/{id}/factories/{factoryId} | 工厂視図更新 | mdm:material-factory:update | MDM | 02-mdm/91-api-design.md |
| GET | /api/mdm/materials/{id}/history | 変更履歴 | mdm:change:view | MDM | 02-mdm/91-api-design.md |
| POST | /api/mdm/materials/{id}/reactivate | 再開申請 | mdm:material:update | MDM | 02-mdm/01-material-master.md |
| POST | /api/mdm/materials/{id}/reactivate | 使用再開申請 | mdm:material:update | MDM | 02-mdm/91-api-design.md |
| POST | /api/mdm/materials/{id}/submit | 承認提出 | mdm:material:update | MDM | 02-mdm/91-api-design.md |
| GET | /api/mdm/materials/{id}/substitutes | 替代一覧（片方向） | mdm:substitute:view | MDM | 02-mdm/91-api-design.md |
| GET | /api/mdm/partner-bank-accounts | 口座一覧 | mdm:supplier:view/mdm:customer:view | MDM | 02-mdm/02-business-partner.md |
| GET | /api/mdm/partner-bank-accounts | 取引先口座一覧 | mdm:bank-account:view | MDM | 02-mdm/05-price-settlement.md |
| GET | /api/mdm/partner-bank-accounts | 口座一覧（マスク） | mdm:bank-account:view | MDM | 02-mdm/91-api-design.md |
| POST | /api/mdm/partner-bank-accounts/{id}/change-request | 口座変更申請 | mdm:bank-account:update | MDM | 02-mdm/91-api-design.md |
| POST | /api/mdm/partner-bank-accounts/{id}/verify | 口座検証済み登録 | mdm:bank-account:verify | MDM | 02-mdm/05-price-settlement.md |
| POST | /api/mdm/partner-bank-accounts/{id}/verify | 口座検証 | mdm:bank-account:verify | MDM | 02-mdm/91-api-design.md |
| POST/PUT | /api/mdm/partner-bank-accounts[/{id}] | 口座 CRUD | mdm:bank-account:update | MDM | 02-mdm/91-api-design.md |
| GET | /api/mdm/payment-terms | 付款条件一覧 | mdm:payment-term:view | MDM | 02-mdm/91-api-design.md |
| POST | /api/mdm/payment-terms/calc-due-date | 支払期日計算 | mdm:payment-term:view | MDM | 02-mdm/91-api-design.md |
| GET | /api/mdm/payment-terms/{code} | 付款条件照会（他域共用） | mdm:payment-term:view | MDM | 02-mdm/05-price-settlement.md |
| GET | /api/mdm/payment-terms/{code} | 付款条件照会 | mdm:payment-term:view | MDM | 02-mdm/91-api-design.md |
| POST/PUT | /api/mdm/payment-terms[/{id}] | 付款条件 CRUD | mdm:payment-term:update | MDM | 02-mdm/91-api-design.md |
| GET | /api/mdm/price-discounts | 折扣規則一覧 | mdm:price:view | MDM | 02-mdm/91-api-design.md |
| POST/PUT | /api/mdm/price-discounts[/{id}] | 折扣 CRUD | mdm:price:update | MDM | 02-mdm/91-api-design.md |
| GET | /api/mdm/price-lists | 価格表一覧 | mdm:price:view | MDM | 02-mdm/91-api-design.md |
| POST | /api/mdm/price-lists | 価格表登録 | mdm:price:update | MDM | 02-mdm/91-api-design.md |
| GET | /api/mdm/price-lists/{id} | 価格表詳細（明細含む） | mdm:price:view | MDM | 02-mdm/05-price-settlement.md |
| GET | /api/mdm/price-lists/{id} | 価格表詳細 | mdm:price:view | MDM | 02-mdm/91-api-design.md |
| PUT | /api/mdm/price-lists/{id} | 価格表更新（草稿のみ） | mdm:price:update | MDM | 02-mdm/05-price-settlement.md |
| PUT | /api/mdm/price-lists/{id} | 価格表更新 | mdm:price:update | MDM | 02-mdm/91-api-design.md |
| POST | /api/mdm/price-lists/{id}/activate | 有効化（E04） | mdm:change:approve | MDM | 02-mdm/91-api-design.md |
| GET | /api/mdm/prices/purchase/effective | 採購取价 | mdm:purchase-price:view | MDM | 02-mdm/05-price-settlement.md |
| GET | /api/mdm/prices/purchase/effective | 購買取价 | mdm:purchase-price:view | MDM | 02-mdm/91-api-design.md |
| GET | /api/mdm/prices/sales/effective | 销售取价（単品） | mdm:price:view | MDM | 02-mdm/05-price-settlement.md |
| GET | /api/mdm/prices/sales/effective | 销售取价 | mdm:price:view | MDM | 02-mdm/91-api-design.md |
| POST | /api/mdm/prices/sales/effective-batch | 销售取价（一括、≤500） | mdm:price:view | MDM | 02-mdm/05-price-settlement.md |
| POST | /api/mdm/prices/sales/effective-batch | 销售取价（一括） | mdm:price:view | MDM | 02-mdm/91-api-design.md |
| POST | /api/mdm/prices/sales/simulate | 取价シミュレーション | mdm:price:view | MDM | 02-mdm/91-api-design.md |
| GET | /api/mdm/purchase-prices | 採購価格一覧 | mdm:purchase-price:view | MDM | 02-mdm/05-price-settlement.md |
| GET | /api/mdm/purchase-prices | 購買価格一覧 | mdm:purchase-price:view | MDM | 02-mdm/91-api-design.md |
| POST/PUT | /api/mdm/purchase-prices[/{id}] | 採購価格 CRUD | mdm:purchase-price:update | MDM | 02-mdm/05-price-settlement.md |
| POST/PUT | /api/mdm/purchase-prices[/{id}] | 購買価格 CRUD | mdm:purchase-price:update | MDM | 02-mdm/91-api-design.md |
| GET | /api/mdm/search | 主数据横断検索 | mdm:portal:view | MDM | 02-mdm/91-api-design.md |
| GET | /api/mdm/settlement-methods | 結算方式一覧 | mdm:settlement:view | MDM | 02-mdm/91-api-design.md |
| POST/PUT | /api/mdm/settlement-methods[/{id}] | 結算方式 CRUD | mdm:settlement:update | MDM | 02-mdm/91-api-design.md |
| GET | /api/mdm/supplier-avl | 合格供应商目录（AVL） | mdm:supplier-eval:view | MDM | 02-mdm/06-credit-supplier-eval.md |
| GET | /api/mdm/supplier-avl | AVL（合格供应商目录） | mdm:supplier-eval:view | MDM | 02-mdm/91-api-design.md |
| GET | /api/mdm/supplier-evaluations | 評価一覧 | mdm:supplier-eval:view | MDM | 02-mdm/91-api-design.md |
| POST | /api/mdm/supplier-evaluations/calculate | 月次計算 | mdm:supplier-eval:update | MDM | 02-mdm/91-api-design.md |
| GET | /api/mdm/supplier-evaluations/{id} | 評価詳細 | mdm:supplier-eval:view | MDM | 02-mdm/91-api-design.md |
| PUT | /api/mdm/supplier-evaluations/{id} | 評価修正（確定前） | mdm:supplier-eval:update | MDM | 02-mdm/06-credit-supplier-eval.md |
| PUT | /api/mdm/supplier-evaluations/{id} | 評価修正 | mdm:supplier-eval:update | MDM | 02-mdm/91-api-design.md |
| POST | /api/mdm/supplier-evaluations/{id}/confirm | 評価確定・分级 | mdm:supplier-eval:update | MDM | 02-mdm/06-credit-supplier-eval.md |
| POST | /api/mdm/supplier-evaluations/{id}/confirm | 評価確定 | mdm:supplier-eval:update | MDM | 02-mdm/91-api-design.md |
| GET | /api/mdm/supplier-quotations | 報価一覧 | mdm:supplier-quotation:view | MDM | 02-mdm/91-api-design.md |
| POST | /api/mdm/supplier-quotations/{id}/adopt | 報価採用→購買価格反映 | mdm:purchase-price:update | MDM | 02-mdm/05-price-settlement.md |
| POST | /api/mdm/supplier-quotations/{id}/adopt | 報価採用 | mdm:purchase-price:update | MDM | 02-mdm/91-api-design.md |
| POST/PUT | /api/mdm/supplier-quotations[/{id}] | 報価 CRUD | mdm:supplier-quotation:update | MDM | 02-mdm/91-api-design.md |
| GET | /api/mdm/suppliers | 供应商一覧 | mdm:supplier:view | MDM | 02-mdm/91-api-design.md |
| POST | /api/mdm/suppliers | 供应商登録 | mdm:supplier:create | MDM | 02-mdm/91-api-design.md |
| GET | /api/mdm/suppliers/{id} | 供应商詳細 | mdm:supplier:view | MDM | 02-mdm/91-api-design.md |
| PUT | /api/mdm/suppliers/{id} | 供应商更新 | mdm:supplier:update | MDM | 02-mdm/91-api-design.md |
| POST | /api/mdm/suppliers/{id}/admission-approve | 准入承認 | mdm:supplier-admission:approve | MDM | 02-mdm/91-api-design.md |
| POST | /api/mdm/suppliers/{id}/admission-requests | 准入申請 | mdm:supplier:update | MDM | 02-mdm/91-api-design.md |
| GET | /api/mdm/suppliers/{id}/evaluations | 供應商評価履歴 | mdm:supplier-eval:view | MDM | 02-mdm/06-credit-supplier-eval.md |
| GET | /api/mdm/suppliers/{id}/evaluations | 評価履歴 | mdm:supplier-eval:view | MDM | 02-mdm/91-api-design.md |
| GET | /api/mdm/suppliers/{id}/materials | 供給範囲 | mdm:supplier:view | MDM | 02-mdm/91-api-design.md |
| POST/PUT/DELETE | /api/mdm/suppliers/{id}/materials[/{rowId}] | 供給範囲 CRUD | mdm:supplier:update | MDM | 02-mdm/91-api-design.md |
| GET | /api/mdm/suppliers/{id}/qualifications | 資格一覧 | mdm:supplier:view | MDM | 02-mdm/91-api-design.md |
| POST/PUT/DELETE | /api/mdm/suppliers/{id}/qualifications[/{qid}] | 資格 CRUD | mdm:supplier:update | MDM | 02-mdm/91-api-design.md |
| POST | /api/mdm/suppliers/{id}/suspend | 暂停（品質問題等） | mdm:supplier-admission:approve | MDM | 02-mdm/06-credit-supplier-eval.md |
| POST | /api/mdm/suppliers/{id}/suspend | 暂停 | mdm:supplier-admission:approve | MDM | 02-mdm/91-api-design.md |
| GET | /api/mdm/tax-classifications | 税收分類编码一覧 | mdm:tax-code:view | MDM | 02-mdm/04-uom-currency-tax.md |
| GET | /api/mdm/tax-classifications | 税收分類一覧 | mdm:tax-code:view | MDM | 02-mdm/91-api-design.md |
| GET | /api/mdm/tax-codes | 税碼一覧 | mdm:tax-code:view | MDM | 02-mdm/04-uom-currency-tax.md |
| GET | /api/mdm/tax-codes | 税码一覧 | mdm:tax-code:view | MDM | 02-mdm/91-api-design.md |
| GET | /api/mdm/tax-codes/{code} | 税碼照会（他域共用） | mdm:tax-code:view | MDM | 02-mdm/04-uom-currency-tax.md |
| GET | /api/mdm/tax-codes/{code} | 税码照会 | mdm:tax-code:view | MDM | 02-mdm/91-api-design.md |
| GET | /api/mdm/tax-codes/{id}/rates | 税率履歴 | mdm:tax-code:view | MDM | 02-mdm/91-api-design.md |
| POST/PUT | /api/mdm/tax-codes[/{id}] | 税碼 CRUD | mdm:tax-code:update | MDM | 02-mdm/04-uom-currency-tax.md |
| POST/PUT | /api/mdm/tax-codes[/{id}] | 税码 CRUD | mdm:tax-code:update | MDM | 02-mdm/91-api-design.md |
| GET | /api/mdm/uom-conversions | 換算一覧 | mdm:uom:view | MDM | 02-mdm/91-api-design.md |
| POST | /api/mdm/uom-conversions | 換算登録 | mdm:uom:update | MDM | 02-mdm/04-uom-currency-tax.md |
| POST/PUT | /api/mdm/uom-conversions[/{id}] | 換算 CRUD（20077 は SQLSTATE 23P01 のうち制約名が ex_mdm_uom_conversion_period の場合のみ 20077 に変換（23P01 を一律 20077 にしない。標準原価公開の排他制約の 23P01 は 70134／MSG-FIN-134）） | mdm:uom:update | MDM | 02-mdm/91-api-design.md |
| GET | /api/mdm/uoms | 単位一覧 | mdm:uom:view | MDM | 02-mdm/91-api-design.md |
| POST | /api/mdm/uoms/convert | 数量換算（他域共用） | mdm:uom:view | MDM | 02-mdm/04-uom-currency-tax.md |
| POST | /api/mdm/uoms/convert | 数量換算 | mdm:uom:view | MDM | 02-mdm/91-api-design.md |
| GET | /api/mdm/uoms/{code} | 単位照会 | mdm:uom:view | MDM | 02-mdm/91-api-design.md |
| POST/PUT | /api/mdm/uoms[/{id}] | 単位 CRUD | mdm:uom:update | MDM | 02-mdm/91-api-design.md |
| GET | /api/mdm/warehouse-bins | 庫位一覧 | mdm:warehouse:view | MDM | 02-mdm/91-api-design.md |
| POST | /api/mdm/warehouse-bins/batch-generate | 一括生成（プレビュー/実行） | mdm:warehouse:update | MDM | 02-mdm/03-warehouse-location.md |
| POST | /api/mdm/warehouse-bins/batch-generate | 一括生成 | mdm:warehouse:update | MDM | 02-mdm/91-api-design.md |
| POST | /api/mdm/warehouse-bins/labels | ラベル PDF 生成 | mdm:warehouse:view + print | MDM | 02-mdm/03-warehouse-location.md |
| POST | /api/mdm/warehouse-bins/labels | 库位ラベル PDF | mdm:warehouse:print | MDM | 02-mdm/91-api-design.md |
| GET | /api/mdm/warehouse-bins/{id} | 庫位詳細 | mdm:warehouse:view | MDM | 02-mdm/91-api-design.md |
| POST/PUT | /api/mdm/warehouse-bins[/{id}] | 庫位 CRUD | mdm:warehouse:update | MDM | 02-mdm/91-api-design.md |
| GET/POST/PUT | /api/mdm/warehouse-zones[/{id}] | 庫区 CRUD | mdm:warehouse:update | MDM | 02-mdm/91-api-design.md |
| GET | /api/mdm/warehouses | 倉庫一覧 | mdm:warehouse:view | MDM | 02-mdm/91-api-design.md |
| POST | /api/mdm/warehouses | 倉庫登録 | mdm:warehouse:update | MDM | 02-mdm/03-warehouse-location.md |
| GET | /api/mdm/warehouses/options | 選択用一覧（他域参照） | mdm:warehouse:view | MDM | 02-mdm/03-warehouse-location.md |
| GET | /api/mdm/warehouses/options | 選択用一覧 | mdm:warehouse:view | MDM | 02-mdm/91-api-design.md |
| GET | /api/mdm/warehouses/{id} | 倉庫詳細 | mdm:warehouse:view | MDM | 02-mdm/91-api-design.md |
| PUT | /api/mdm/warehouses/{id} | 倉庫更新 | mdm:warehouse:update | MDM | 02-mdm/03-warehouse-location.md |
| GET | /api/mdm/warehouses/{id}/zones | 庫区一覧 | mdm:warehouse:view | MDM | 02-mdm/03-warehouse-location.md |
| POST/PUT | /api/mdm/warehouses[/{id}] | 倉庫 CRUD | mdm:warehouse:update | MDM | 02-mdm/91-api-design.md |
| GET | /api/production/boms | BOM 一覧 | production:bom:view | PRD | 06-production/91-api-design.md |
| POST | /api/production/boms | BOM 登録 | production:bom:update | PRD | 06-production/91-api-design.md |
| GET | /api/production/boms/compare | BOM 比較 | production:bom:view | PRD | 06-production/91-api-design.md |
| GET | /api/production/boms/effective | 有効 BOM の解決（パラメータ materialId・factoryId・date（すべて必須）。詳細 §3.12） | production:bom:view | PRD | 06-production/91-api-design.md |
| GET | /api/production/boms/{id} | BOM 詳細（明細・替代料） | 同上 | PRD | 06-production/91-api-design.md |
| PUT | /api/production/boms/{id} | BOM 変更 | 同上 | PRD | 06-production/91-api-design.md |
| POST | /api/production/boms/{id}/copy | 新版本コピー | 同上 | PRD | 06-production/91-api-design.md |
| GET | /api/production/boms/{id}/cost-rollup | 成本卷算 | production:bom:view（原価権限推奨） | PRD | 06-production/91-api-design.md |
| GET | /api/production/boms/{id}/explode | 多階展開 | 同上 | PRD | 06-production/91-api-design.md |
| POST | /api/production/boms/{id}/obsolete | 廃止 | 同上 | PRD | 06-production/91-api-design.md |
| GET | /api/production/capacity-load | 粗能力（負荷率） | production:plan:update | PRD | 06-production/91-api-design.md |
| GET | /api/production/completion-receipts | 完工入库一覧 | production:completion:view | PRD | 06-production/91-api-design.md |
| POST | /api/production/completion-receipts | 完工入库要求確定（E24、INV FGI 採番） | production:completion:create | PRD | 06-production/91-api-design.md |
| POST | /api/production/completion-receipts/{id}/cancel | 入庫取消 | production:completion:create | PRD | 06-production/91-api-design.md |
| GET | /api/production/dashboard/lists | 遅延・欠品・NCR・保留リスト | 同上 | PRD | 06-production/91-api-design.md |
| GET | /api/production/dashboard/summary | 看板 KPI・チャート | production:dashboard:view | PRD | 06-production/91-api-design.md |
| GET | /api/production/defect-codes | 缺陷コード一覧 | production:inspection:view | PRD | 06-production/91-api-design.md |
| GET | /api/production/equipments | 設備一覧 | production:equipment:view | PRD | 06-production/91-api-design.md |
| POST | /api/production/equipments | 設備登録 | production:equipment:update | PRD | 06-production/91-api-design.md |
| GET | /api/production/forecasts / POST | 需求予測 | production:plan:update | PRD | 06-production/91-api-design.md |
| GET | /api/production/inspection-standards | 標準一覧 | production:inspection-standard:view | PRD | 06-production/06-quality-management.md |
| GET | /api/production/inspection-standards | 検査標準一覧 | production:inspection-standard:view | PRD | 06-production/91-api-design.md |
| POST | /api/production/inspection-standards | 標準登録 | production:inspection-standard:update | PRD | 06-production/06-quality-management.md |
| POST | /api/production/inspection-standards | 検査標準登録 | production:inspection-standard:update | PRD | 06-production/91-api-design.md |
| GET | /api/production/inspection-standards/effective | 適用標準の解決 | production:inspection:view | PRD | 06-production/91-api-design.md |
| GET | /api/production/inspection-standards/{id} | 標準詳細（項目含む） | 同上 | PRD | 06-production/06-quality-management.md |
| PUT | /api/production/inspection-standards/{id} | 標準変更 | 同上 | PRD | 06-production/06-quality-management.md |
| PUT | /api/production/inspection-standards/{id} | 検査標準変更 | 同上 | PRD | 06-production/91-api-design.md |
| GET | /api/production/inspections | 検査一覧 | production:inspection:view | PRD | 06-production/91-api-design.md |
| POST | /api/production/inspections | 検査起票（手動） | production:inspection:create | PRD | 06-production/06-quality-management.md |
| POST | /api/production/inspections | 検査起票 | production:inspection:create | PRD | 06-production/91-api-design.md |
| POST | /api/production/inspections/batch-judge | 一括判定 | 同上 | PRD | 06-production/91-api-design.md |
| GET | /api/production/inspections/{id} | 検査詳細 | 同上 | PRD | 06-production/06-quality-management.md |
| PUT | /api/production/inspections/{id} | 検査結果登録 | 同上 | PRD | 06-production/91-api-design.md |
| POST | /api/production/inspections/{id}/cancel | 検査取消 | production:inspection:judge | PRD | 06-production/91-api-design.md |
| POST | /api/production/inspections/{id}/judge | 判定確定（E15） | production:inspection:judge | PRD | 06-production/91-api-design.md |
| DELETE | /api/production/jobs/{jobId} | ジョブ取消 | 同上 | PRD | 06-production/91-api-design.md |
| GET | /api/production/material-issues | 領料/退料一覧 | production:material-issue:view | PRD | 06-production/91-api-design.md |
| POST | /api/production/material-issues | 領料/退料要求の登録・確定（E22/E36）。MII/MIR 伝票は INV 採番 | production:material-issue:create | PRD | 06-production/91-api-design.md |
| POST | /api/production/material-issues/{id}/cancel | 領料取消 | production:material-issue:reverse | PRD | 06-production/91-api-design.md |
| GET | /api/production/mps / POST | MPS 一覧・登録 | production:plan:update | PRD | 06-production/91-api-design.md |
| POST | /api/production/mrp-actions/{id}/ignore | 動作消息を無視 | production:mrp:confirm | PRD | 06-production/91-api-design.md |
| POST | /api/production/mrp-plan-orders/batch-confirm | 計画订单一括確認 | production:mrp:confirm | PRD | 06-production/91-api-design.md |
| POST | /api/production/mrp-plan-orders/{id}/convert-to-outsourcing | 委外訂单へ転送 | production:mrp:confirm | PRD | 06-production/91-api-design.md |
| POST | /api/production/mrp-plan-orders/{id}/convert-to-requisition | 請購へ転送（PUR） | production:mrp:confirm | PRD | 06-production/91-api-design.md |
| POST | /api/production/mrp-plan-orders/{id}/convert-to-work-order | 工单へ転送 | production:mrp:confirm | PRD | 06-production/91-api-design.md |
| GET | /api/production/mrp-runs | MRP 実行履歴 | production:mrp:view | PRD | 06-production/91-api-design.md |
| POST | /api/production/mrp-runs | MRP 実行（202 非同期） | production:mrp:run | PRD | 06-production/91-api-design.md |
| GET | /api/production/mrp-runs/{id} | 実行結果サマリ | 同上 | PRD | 06-production/91-api-design.md |
| GET | /api/production/mrp-runs/{id}/actions | 動作消息一覧 | 同上 | PRD | 06-production/91-api-design.md |
| GET | /api/production/mrp-runs/{id}/demands | 需求・净需求一覧 | 同上 | PRD | 06-production/91-api-design.md |
| GET | /api/production/mrp-runs/{id}/plan-orders | 計画订单一覧 | 同上 | PRD | 06-production/91-api-design.md |
| GET | /api/production/ncrs | NCR 一覧 | production:ncr:view | PRD | 06-production/06-quality-management.md |
| POST | /api/production/ncrs | NCR 起票 | production:ncr:create | PRD | 06-production/06-quality-management.md |
| GET | /api/production/ncrs / POST | NCR 一覧・起票 | production:ncr:create | PRD | 06-production/91-api-design.md |
| GET | /api/production/ncrs/{id} | NCR 詳細 | 同上 | PRD | 06-production/06-quality-management.md |
| POST | /api/production/ncrs/{id}/close | NCR 完了 | production:ncr:create | PRD | 06-production/91-api-design.md |
| POST | /api/production/ncrs/{id}/execute | 処置実行（返工/特采/报废/返品） | production:ncr:create | PRD | 06-production/06-quality-management.md |
| POST | /api/production/ncrs/{id}/execute | 処置実行 | production:ncr:create | PRD | 06-production/91-api-design.md |
| POST | /api/production/ncrs/{id}/submit | NCR 承認提出 | production:ncr:create | PRD | 06-production/06-quality-management.md |
| POST | /api/production/ncrs/{id}/submit | NCR 提出 | production:ncr:create | PRD | 06-production/91-api-design.md |
| POST | /api/production/outsourcing-issues | 発料登録/確定 | production:outsourcing:create | PRD | 06-production/04-outsourcing.md |
| POST | /api/production/outsourcing-issues | 委外発料（E25） | production:outsourcing:create | PRD | 06-production/91-api-design.md |
| GET | /api/production/outsourcing-orders | 委外訂单一覧 | production:outsourcing:view | PRD | 06-production/91-api-design.md |
| POST | /api/production/outsourcing-orders | 委外訂单登録 | production:outsourcing:create | PRD | 06-production/91-api-design.md |
| GET | /api/production/outsourcing-orders/supplier-stock | 委外先別支給材料残 | production:outsourcing:view | PRD | 06-production/04-outsourcing.md |
| GET | /api/production/outsourcing-orders/supplier-stock | 委外先支給材料残 | production:outsourcing:view | PRD | 06-production/91-api-design.md |
| GET | /api/production/outsourcing-orders/{id} | 委外訂单詳細 | 同上 | PRD | 06-production/91-api-design.md |
| POST | /api/production/outsourcing-orders/{id}/order | 発注 | 同上 | PRD | 06-production/91-api-design.md |
| GET | /api/production/outsourcing-orders/{id}/progress | 進捗（発料/受入/残） | production:outsourcing:view | PRD | 06-production/04-outsourcing.md |
| GET | /api/production/outsourcing-orders/{id}/supply-materials | 支給材料展開 | production:outsourcing:view | PRD | 06-production/91-api-design.md |
| POST | /api/production/outsourcing-receipts | 受入登録/確定 | production:outsourcing:create | PRD | 06-production/04-outsourcing.md |
| POST | /api/production/outsourcing-receipts | 委外受入（E26） | 同上 | PRD | 06-production/91-api-design.md |
| POST | /api/production/outsourcing-receipts/{id}/cancel | 受入取消 | 同上 | PRD | 06-production/91-api-design.md |
| POST | /api/production/outsourcing-settlements | 結算作成 | production:outsourcing:settle | PRD | 06-production/04-outsourcing.md |
| POST | /api/production/outsourcing-settlements | 加工費結算 | production:outsourcing:settle | PRD | 06-production/91-api-design.md |
| POST | /api/production/outsourcing-settlements/{id}/approve | 結算承認 | production:outsourcing:approve | PRD | 06-production/91-api-design.md |
| GET | /api/production/overproduction-approvals | 超産申請一覧（詳細 §3.14） | production:overproduction-approval:view | PRD | 06-production/91-api-design.md |
| POST | /api/production/overproduction-approvals | 超産申請登録（→10、201。§3.14） | production:overproduction-approval:create | PRD | 06-production/91-api-design.md |
| GET | /api/production/overproduction-approvals/{id} | 超産申請詳細（§3.14） | 同上 | PRD | 06-production/91-api-design.md |
| POST | /api/production/overproduction-approvals/{id}/approve | 承認（20→30、allowed_qty +request_qty。§3.14）。TODO：権限チェック未実装、Flowable 接入後に閉鎖 | production:overproduction-approval:approve | PRD | 06-production/91-api-design.md |
| POST | /api/production/overproduction-approvals/{id}/cancel | 取消（10/20→90。§3.14） | production:overproduction-approval:cancel | PRD | 06-production/91-api-design.md |
| POST | /api/production/overproduction-approvals/{id}/reject | 却下（20→40。§3.14） | production:overproduction-approval:approve | PRD | 06-production/91-api-design.md |
| POST | /api/production/overproduction-approvals/{id}/submit | 申請提出（10→20。Flowable 接入後は WF 起動に置換。§3.14） | production:overproduction-approval:submit | PRD | 06-production/91-api-design.md |
| GET | /api/production/reports/work-hours | 工数・能率集計 | production:report:view | PRD | 06-production/91-api-design.md |
| GET | /api/production/routings | 工艺路線一覧 | production:routing:view | PRD | 06-production/91-api-design.md |
| POST | /api/production/routings | 工艺路線登録 | production:routing:update | PRD | 06-production/91-api-design.md |
| GET | /api/production/routings/{id} | 工艺路線詳細 | 同上 | PRD | 06-production/91-api-design.md |
| PUT | /api/production/routings/{id} | 工艺路線変更 | 同上 | PRD | 06-production/91-api-design.md |
| GET | /api/production/traceability/forward | 順追溯 | 同上 | PRD | 06-production/91-api-design.md |
| GET | /api/production/traceability/reverse | 逆追溯 | production:trace:view | PRD | 06-production/91-api-design.md |
| GET | /api/production/traceability/work-order/{id} | 工单追溯 | 同上 | PRD | 06-production/91-api-design.md |
| GET | /api/production/work-centers | 工作中心一覧 | production:work-center:view | PRD | 06-production/91-api-design.md |
| POST | /api/production/work-centers | 工作中心登録 | production:work-center:update | PRD | 06-production/91-api-design.md |
| PUT | /api/production/work-centers/{id} | 工作中心変更 | 同上 | PRD | 06-production/91-api-design.md |
| GET | /api/production/work-centers/{id}/calendar | 工作日历取得 | production:work-center:view | PRD | 06-production/91-api-design.md |
| POST | /api/production/work-centers/{id}/calendar | 工作日历一括登録 | production:work-center:update | PRD | 06-production/91-api-design.md |
| GET | /api/production/work-orders | 工单一覧 | production:work-order:view | PRD | 06-production/91-api-design.md |
| POST | /api/production/work-orders | 工单登録 | production:work-order:create | PRD | 06-production/91-api-design.md |
| POST | /api/production/work-orders/batch-release | 一括下达 | 同上 | PRD | 06-production/91-api-design.md |
| GET | /api/production/work-orders/by-no/{no} | 工单番号検索（PDA） | 同上 | PRD | 06-production/91-api-design.md |
| POST | /api/production/work-orders/merge | 合并 | 同上 | PRD | 06-production/91-api-design.md |
| GET | /api/production/work-orders/{id} | 工单詳細 | 同上 | PRD | 06-production/91-api-design.md |
| PUT | /api/production/work-orders/{id} | 変更 | production:work-order:update | PRD | 06-production/02-work-order.md |
| PUT | /api/production/work-orders/{id} | 工单変更 | production:work-order:update | PRD | 06-production/91-api-design.md |
| POST | /api/production/work-orders/{id}/approve | 承認（20→25。08 WF E32 コールバックと同一サービス。詳細 §3.11）。TODO：権限チェック未実装、Flowable 接入後に閉鎖 | production:work-order:approve | PRD | 06-production/91-api-design.md |
| POST | /api/production/work-orders/{id}/close | 結案 | production:work-order:close | PRD | 06-production/91-api-design.md |
| GET | /api/production/work-orders/{id}/completion-preview | 入庫プレビュー（残数・単価） | production:completion:view | PRD | 06-production/91-api-design.md |
| POST | /api/production/work-orders/{id}/explode-bom | BOM 再展開 | production:work-order:update | PRD | 06-production/91-api-design.md |
| POST | /api/production/work-orders/{id}/hold | 保留/解除 | 同上 | PRD | 06-production/91-api-design.md |
| GET | /api/production/work-orders/{id}/materials | 材料明細 | production:work-order:view | PRD | 06-production/91-api-design.md |
| GET | /api/production/work-orders/{id}/operations | 工序明細 | 同上 | PRD | 06-production/91-api-design.md |
| GET | /api/production/work-orders/{id}/progress | 進捗（報工/入庫/検査） | 同上 | PRD | 06-production/91-api-design.md |
| POST | /api/production/work-orders/{id}/release | 下达 | production:work-order:release | PRD | 06-production/02-work-order.md |
| POST | /api/production/work-orders/{id}/release | 下达（E21） | production:work-order:release | PRD | 06-production/91-api-design.md |
| POST | /api/production/work-orders/{id}/split | 拆分 | 同上 | PRD | 06-production/91-api-design.md |
| POST | /api/production/work-orders/{id}/submit | 承認提出（10→20。詳細 §3.10） | production:work-order:submit | PRD | 06-production/91-api-design.md |
| GET | /api/production/work-reports | 報工一覧 | production:work-report:view | PRD | 06-production/91-api-design.md |
| POST | /api/production/work-reports | 報工登録（草稿/提出） | production:work-report:create | PRD | 06-production/91-api-design.md |
| POST | /api/production/work-reports/{id}/approve | 報工審核確定（E23、倒冲） | production:work-report:approve | PRD | 06-production/91-api-design.md |
| POST | /api/production/work-reports/{id}/cancel | 報工取消 | production:work-report:approve | PRD | 06-production/91-api-design.md |
| GET | /api/purchase/accruals | 入荷済未請求一覧 | purchase:ap:view | PUR | 04-purchase/91-api-design.md |
| GET | /api/purchase/delivery-followups | 催货履歴 | purchase:tracking:view | PUR | 04-purchase/91-api-design.md |
| POST | /api/purchase/delivery-followups | 催货登録 | purchase:tracking:followup | PUR | 04-purchase/07-tracking-performance.md |
| POST | /api/purchase/delivery-followups | 催货登録（201） | purchase:tracking:followup | PUR | 04-purchase/91-api-design.md |
| POST | /api/purchase/exports | 报表非同期出力 | purchase:report:export | PUR | 04-purchase/07-tracking-performance.md |
| POST | /api/purchase/exports | 非同期エクスポート（202） | purchase:report:export | PUR | 04-purchase/91-api-design.md |
| GET | /api/purchase/invoice-matches | 匹配結果検索 | purchase:invoice:view | PUR | 04-purchase/91-api-design.md |
| POST | /api/purchase/invoices | 発票登録（201） | purchase:invoice:create | PUR | 04-purchase/91-api-design.md |
| GET | /api/purchase/invoices/available-lines | 未請求 GR 明細取得 | purchase:invoice:create | PUR | 04-purchase/91-api-design.md |
| POST | /api/purchase/invoices/batch-match | 一括匹配 | purchase:match:run | PUR | 04-purchase/91-api-design.md |
| PUT | /api/purchase/invoices/{id} | 更新（未計上） | purchase:invoice:create | PUR | 04-purchase/91-api-design.md |
| POST | /api/purchase/invoices/{id}/cancel | 取消（赤伝） | purchase:invoice:cancel | PUR | 04-purchase/91-api-design.md |
| POST | /api/purchase/invoices/{id}/match | 三单匹配 | purchase:match:run | PUR | 04-purchase/06-purchase-invoice-ap.md |
| POST | /api/purchase/invoices/{id}/match | 三单匹配実行 | purchase:match:run | PUR | 04-purchase/91-api-design.md |
| PUT | /api/purchase/invoices/{id}/match-lines | 差異理由・会計処理保存 | purchase:match:run | PUR | 04-purchase/91-api-design.md |
| GET | /api/purchase/invoices/{id}/match-result | 匹配結果取得 | purchase:invoice:view | PUR | 04-purchase/91-api-design.md |
| POST | /api/purchase/invoices/{id}/post | 計上（E17 発行） | purchase:match:run | PUR | 04-purchase/91-api-design.md |
| POST | /api/purchase/invoices/{id}/submit-diff | 差異承認提出 | purchase:match:approve | PUR | 04-purchase/91-api-design.md |
| GET | /api/purchase/jobs/{jobId}/files/{fileId} | 結果ファイル取得 | purchase:report:view | PUR | 04-purchase/91-api-design.md |
| POST | /api/purchase/payment-requests | 付款申請（FIN PA 起票） | purchase:payment:create | PUR | 04-purchase/91-api-design.md |
| GET | /api/purchase/payment-status | 支払状況（E28 反映） | purchase:ap:view | PUR | 04-purchase/06-purchase-invoice-ap.md |
| GET | /api/purchase/payment-status | 支払状態（E28 反映） | purchase:ap:view | PUR | 04-purchase/91-api-design.md |
| GET | /api/purchase/plan-suggestions | MRP 計画オーダー一覧 | purchase:plan:view | PUR | 04-purchase/91-api-design.md |
| POST | /api/purchase/plan-suggestions/convert | 計画→請購変換 | purchase:plan:convert | PUR | 04-purchase/91-api-design.md |
| POST | /api/purchase/prepayment-requests | 预付款申請（FIN PA 起票） | purchase:payment:create | PUR | 04-purchase/06-purchase-invoice-ap.md |
| POST | /api/purchase/prepayment-requests | 預付款申請（FIN PA 起票） | purchase:payment:create | PUR | 04-purchase/91-api-design.md |
| GET | /api/purchase/price-anomalies | 価格異常一覧 | purchase:price:view | PUR | 04-purchase/91-api-design.md |
| GET | /api/purchase/price-history | 成交价历史・趨勢 | purchase:price:view | PUR | 04-purchase/07-tracking-performance.md |
| GET | /api/purchase/price-history | 成交価履歴・趨勢 | purchase:price:view | PUR | 04-purchase/91-api-design.md |
| GET | /api/purchase/prices | 採購価格照会 | purchase:price:view | PUR | 04-purchase/91-api-design.md |
| POST | /api/purchase/purchase-orders/batch-send | 一括送信 | purchase:order:send | PUR | 04-purchase/91-api-design.md |
| POST | /api/purchase/purchase-orders/{id}/cancel | 取消（部分取消含む） | purchase:order:cancel | PUR | 04-purchase/91-api-design.md |
| POST | /api/purchase/purchase-orders/{id}/change | 变更申請 | purchase:order:change | PUR | 04-purchase/03-purchase-order.md |
| POST | /api/purchase/purchase-orders/{id}/change | 変更申請 | purchase:order:change | PUR | 04-purchase/91-api-design.md |
| GET | /api/purchase/purchase-orders/{id}/changes | 变更履历 | purchase:order:view | PUR | 04-purchase/03-purchase-order.md |
| POST | /api/purchase/purchase-orders/{id}/print | 発注書出力 | purchase:order:print | PUR | 04-purchase/03-purchase-order.md |
| POST | /api/purchase/purchase-orders/{id}/print | 発注書（PRT-PUR-003） | purchase:order:print | PUR | 04-purchase/91-api-design.md |
| GET | /api/purchase/purchase-orders/{id}/progress | 入荷・請求進捗 | purchase:order:view | PUR | 04-purchase/91-api-design.md |
| POST | /api/purchase/purchase-orders/{id}/send | 発注送信 | purchase:order:send | PUR | 04-purchase/03-purchase-order.md |
| POST | /api/purchase/purchase-orders/{id}/send | 発注送信（状態 30） | purchase:order:send | PUR | 04-purchase/91-api-design.md |
| GET | /api/purchase/purchase-requisitions | 一覧検索 | purchase:requisition:view | PUR | 04-purchase/91-api-design.md |
| POST | /api/purchase/purchase-requisitions | 登録 | purchase:requisition:create | PUR | 04-purchase/91-api-design.md |
| POST | /api/purchase/purchase-requisitions/from-plan | PRD からの計画請購自動作成 | purchase:plan:convert（内部呼出） | PUR | 04-purchase/07-tracking-performance.md |
| POST | /api/purchase/purchase-requisitions/from-plan | MRP 計画→請購自動作成 | 内部（purchase:plan:convert） | PUR | 04-purchase/91-api-design.md |
| GET | /api/purchase/purchase-requisitions/{id} | 詳細取得 | purchase:requisition:view | PUR | 04-purchase/01-requisition.md |
| PUT | /api/purchase/purchase-requisitions/{id} | 更新（草稿のみ） | purchase:requisition:update | PUR | 04-purchase/01-requisition.md |
| PUT | /api/purchase/purchase-requisitions/{id} | 更新（草稿） | purchase:requisition:update | PUR | 04-purchase/91-api-design.md |
| POST | /api/purchase/purchase-requisitions/{id}/cancel | 取消 | purchase:requisition:cancel | PUR | 04-purchase/91-api-design.md |
| POST | /api/purchase/purchase-requisitions/{id}/close | 关闭（残量不再转单） | purchase:requisition:convert | PUR | 04-purchase/01-requisition.md |
| POST | /api/purchase/purchase-requisitions/{id}/close | 关闭 | purchase:requisition:convert | PUR | 04-purchase/91-api-design.md |
| POST | /api/purchase/purchase-requisitions/{id}/convert-to-orders | 转订单 | purchase:requisition:convert | PUR | 04-purchase/91-api-design.md |
| GET | /api/purchase/purchase-requisitions/{id}/history | 审批・变更履历 | purchase:requisition:view | PUR | 04-purchase/01-requisition.md |
| GET | /api/purchase/purchase-requisitions/{id}/history | 承認・変更履歴 | purchase:requisition:view | PUR | 04-purchase/91-api-design.md |
| POST | /api/purchase/purchase-requisitions/{id}/print | 帳票出力 | purchase:requisition:print | PUR | 04-purchase/01-requisition.md |
| POST | /api/purchase/purchase-requisitions/{id}/print | 請購単出력（PRT-PUR-001） | purchase:requisition:print | PUR | 04-purchase/91-api-design.md |
| GET | /api/purchase/receipts/batch-suggestion | 批次号候補 | purchase:receipt:create | PUR | 04-purchase/91-api-design.md |
| POST | /api/purchase/receipts/from-order | PO から收货单作成 | purchase:receipt:create | PUR | 04-purchase/04-receipt-iqc.md |
| POST | /api/purchase/receipts/from-order | PO→收货単作成（201） | purchase:receipt:create | PUR | 04-purchase/91-api-design.md |
| GET | /api/purchase/receipts/pending-inspection | 待検一覧 | purchase:receipt:view | PUR | 04-purchase/91-api-design.md |
| PUT | /api/purchase/receipts/{id} | 更新（25 のみ） | purchase:receipt:create | PUR | 04-purchase/91-api-design.md |
| POST | /api/purchase/receipts/{id}/cancel | 取消（E35） | purchase:receipt:cancel | PUR | 04-purchase/04-receipt-iqc.md |
| POST | /api/purchase/receipts/{id}/cancel | 取消（E35 発行） | purchase:receipt:cancel | PUR | 04-purchase/91-api-design.md |
| POST | /api/purchase/receipts/{id}/confirm | 入荷確定（E14） | purchase:receipt:create | PUR | 04-purchase/04-receipt-iqc.md |
| POST | /api/purchase/receipts/{id}/confirm | 入荷確定（E14 発行） | purchase:receipt:create | PUR | 04-purchase/91-api-design.md |
| POST | /api/purchase/receipts/{id}/dispositions | 不合格処置 | purchase:return:create | PUR | 04-purchase/04-receipt-iqc.md |
| POST | /api/purchase/receipts/{id}/dispositions | 不合格処置（返品/選別/特採/廃棄） | purchase:return:create | PUR | 04-purchase/91-api-design.md |
| GET | /api/purchase/receipts/{id}/inspections | IQC 結果参照 | purchase:receipt:view | PUR | 04-purchase/04-receipt-iqc.md |
| GET | /api/purchase/receipts/{id}/inspections | IQC 結果参照（PRD 読み取り） | purchase:receipt:view | PUR | 04-purchase/91-api-design.md |
| POST | /api/purchase/receipts/{id}/over-receipt-approve | 超收例外承認 | purchase:receipt:override | PUR | 04-purchase/04-receipt-iqc.md |
| POST | /api/purchase/receipts/{id}/over-receipt-approve | 超収例外承認 | purchase:receipt:override | PUR | 04-purchase/91-api-design.md |
| POST | /api/purchase/receipts/{id}/print | 入荷検収書出力 | purchase:receipt:print | PUR | 04-purchase/04-receipt-iqc.md |
| POST | /api/purchase/receipts/{id}/print | 入荷検収書（PRT-PUR-004） | purchase:receipt:print | PUR | 04-purchase/91-api-design.md |
| GET | /api/purchase/receipts/{id}/stocking-status | 入库進捗 | purchase:receipt:view | PUR | 04-purchase/04-receipt-iqc.md |
| GET | /api/purchase/receipts/{id}/stocking-status | 入庫進捗（E18） | purchase:receipt:view | PUR | 04-purchase/91-api-design.md |
| POST | /api/purchase/returns | 手工起票（貸項等） | purchase:return:create | PUR | 04-purchase/05-return.md |
| POST | /api/purchase/returns | 手工起票（貸項等、201） | purchase:return:create | PUR | 04-purchase/91-api-design.md |
| POST | /api/purchase/returns/from-receipt | 收货単から退货単起票 | purchase:return:create | PUR | 04-purchase/05-return.md |
| POST | /api/purchase/returns/from-receipt | 収货単から退货起票（201） | purchase:return:create | PUR | 04-purchase/91-api-design.md |
| PUT | /api/purchase/returns/{id} | 更新（10 のみ） | purchase:return:create | PUR | 04-purchase/91-api-design.md |
| POST | /api/purchase/returns/{id}/cancel | 取消（10/25） | purchase:return:create | PUR | 04-purchase/91-api-design.md |
| POST | /api/purchase/returns/{id}/complete | 完了（红字关联） | purchase:return:ship | PUR | 04-purchase/05-return.md |
| POST | /api/purchase/returns/{id}/complete | 完了（紅字紐付） | purchase:return:ship | PUR | 04-purchase/91-api-design.md |
| POST | /api/purchase/returns/{id}/print | 退货単出力（PRT-PUR-005） | purchase:return:print | PUR | 04-purchase/05-return.md |
| POST | /api/purchase/returns/{id}/print | 退貨単（PRT-PUR-005） | purchase:return:print | PUR | 04-purchase/91-api-design.md |
| GET | /api/purchase/returns/{id}/progress | 出庫・红字進捗 | purchase:return:view | PUR | 04-purchase/05-return.md |
| GET | /api/purchase/returns/{id}/progress | 出庫・紅字進捗 | purchase:return:view | PUR | 04-purchase/91-api-design.md |
| POST | /api/purchase/returns/{id}/ship | 出庫確定（E16） | purchase:return:ship | PUR | 04-purchase/05-return.md |
| POST | /api/purchase/returns/{id}/ship | 出庫確定（E16 発行） | purchase:return:ship | PUR | 04-purchase/91-api-design.md |
| GET | /api/purchase/rfqs | 一覧 | purchase:rfq:view | PUR | 04-purchase/91-api-design.md |
| POST | /api/purchase/rfqs | 登録（201） | purchase:rfq:create | PUR | 04-purchase/91-api-design.md |
| GET | /api/purchase/rfqs/{id}/comparison | 比价表取得 | purchase:rfq:view | PUR | 04-purchase/02-rfq-comparison.md |
| GET | /api/purchase/rfqs/{id}/comparison | 比価表取得 | purchase:rfq:view | PUR | 04-purchase/91-api-design.md |
| POST | /api/purchase/rfqs/{id}/create-orders | PO 生成 | purchase:rfq:select | PUR | 04-purchase/91-api-design.md |
| POST | /api/purchase/rfqs/{id}/evaluate | 比价計算 | purchase:rfq:view | PUR | 04-purchase/02-rfq-comparison.md |
| POST | /api/purchase/rfqs/{id}/evaluate | 比価計算 | purchase:rfq:view | PUR | 04-purchase/91-api-design.md |
| POST | /api/purchase/rfqs/{id}/issue | 发出询价 | purchase:rfq:create | PUR | 04-purchase/02-rfq-comparison.md |
| POST | /api/purchase/rfqs/{id}/issue | 発出（状態 30） | purchase:rfq:create | PUR | 04-purchase/91-api-design.md |
| POST | /api/purchase/rfqs/{id}/print | 比价表出力（PRT-PUR-002） | purchase:rfq:print | PUR | 04-purchase/02-rfq-comparison.md |
| POST | /api/purchase/rfqs/{id}/print | 比価表出力（PRT-PUR-002） | purchase:rfq:print | PUR | 04-purchase/91-api-design.md |
| GET | /api/purchase/rfqs/{id}/quotations | 报价一覧 | purchase:rfq:view | PUR | 04-purchase/02-rfq-comparison.md |
| POST | /api/purchase/rfqs/{id}/quotations | 供应商报价登録 | purchase:rfq:quote | PUR | 04-purchase/02-rfq-comparison.md |
| POST | /api/purchase/rfqs/{id}/quotations | 供应商報価登録 | purchase:rfq:quote | PUR | 04-purchase/91-api-design.md |
| POST | /api/purchase/rfqs/{id}/select | 中选確定 | purchase:rfq:select | PUR | 04-purchase/02-rfq-comparison.md |
| POST | /api/purchase/rfqs/{id}/select | 中選確定 | purchase:rfq:select | PUR | 04-purchase/91-api-design.md |
| GET | /api/purchase/statements | 対账一覧 | purchase:statement:view | PUR | 04-purchase/91-api-design.md |
| POST | /api/purchase/statements/generate | 対账生成 | purchase:statement:confirm | PUR | 04-purchase/91-api-design.md |
| POST | /api/purchase/statements/{id}/confirm | 確認完了 | purchase:statement:confirm | PUR | 04-purchase/06-purchase-invoice-ap.md |
| POST | /api/purchase/statements/{id}/confirm | 確認完了（状態 40） | purchase:statement:confirm | PUR | 04-purchase/91-api-design.md |
| POST | /api/purchase/statements/{id}/print | 対账単（PRT-PUR-006） | purchase:statement:view | PUR | 04-purchase/91-api-design.md |
| POST | /api/purchase/statements/{id}/send | 送付 | purchase:statement:confirm | PUR | 04-purchase/06-purchase-invoice-ap.md |
| POST | /api/purchase/statements/{id}/send | 送付（状態 30） | purchase:statement:confirm | PUR | 04-purchase/91-api-design.md |
| GET | /api/purchase/supplier-performances | 績效一覧 | purchase:performance:view | PUR | 04-purchase/91-api-design.md |
| POST | /api/purchase/supplier-performances/recalculate | 再計算 | purchase:performance:calculate | PUR | 04-purchase/91-api-design.md |
| GET | /api/purchase/supplier-performances/{id} | 績效詳細・推移 | purchase:performance:view | PUR | 04-purchase/07-tracking-performance.md |
| GET | /api/purchase/supplier-performances/{id} | 績效詳細 | purchase:performance:view | PUR | 04-purchase/91-api-design.md |
| POST | /api/purchase/supplier-performances/{id}/confirm | 績效確定 | purchase:performance:calculate | PUR | 04-purchase/91-api-design.md |
| GET | /api/purchase/tracking | 交期跟踪 KPI・一覧 | purchase:tracking:view | PUR | 04-purchase/91-api-design.md |
| GET | /api/purchase/tracking/backorders | 未入荷一覧 | purchase:tracking:view | PUR | 04-purchase/91-api-design.md |
| GET | /api/report/analysis/details | ドリルダウン明細 | report:analysis:view | RPT | 10-analytics/91-api-design.md |
| POST | /api/report/analysis/exports | 分析出力（非同期） | report:analysis:export | RPT | 10-analytics/91-api-design.md |
| GET | /api/report/analysis/exports/{jobId} | 出力ジョブ状態 | report:analysis:export | RPT | 10-analytics/91-api-design.md |
| GET | /api/report/analysis/exports/{jobId}/files/{fileId} | 出力ファイル DL | report:analysis:export | RPT | 10-analytics/91-api-design.md |
| GET | /api/report/analysis/finance | 财务分析 | report:finance:view | RPT | 10-analytics/91-api-design.md |
| GET | /api/report/analysis/inventory | 库存分析 | report:inventory:view | RPT | 10-analytics/91-api-design.md |
| GET | /api/report/analysis/production | 生产分析 | report:production:view | RPT | 10-analytics/91-api-design.md |
| GET | /api/report/analysis/purchase | 采购分析 | report:purchase:view | RPT | 10-analytics/91-api-design.md |
| GET | /api/report/analysis/sales | 销售分析 | report:sales:view | RPT | 10-analytics/91-api-design.md |
| GET | /api/report/dashboard | 驾驶舱データ（期間・工場） | report:dashboard:view | RPT | 10-analytics/01-dashboard.md |
| GET | /api/report/dashboard | 驾驶舱データ | report:dashboard:view | RPT | 10-analytics/91-api-design.md |
| GET | /api/report/dashboards/{id} | レイアウト | report:dashboard:view | RPT | 10-analytics/91-api-design.md |
| PUT | /api/report/dashboards/{id} | レイアウト保存 | report:dashboard:update | RPT | 10-analytics/91-api-design.md |
| GET | /api/report/etl/jobs | 抽取ジョブ一覧 | report:etl:view | RPT | 10-analytics/91-api-design.md |
| POST | /api/report/etl/recalculate | 再計算（非同期） | report:etl:run | RPT | 10-analytics/91-api-design.md |
| GET | /api/report/favorites | お気に入り一覧 | report:analysis:view | RPT | 10-analytics/91-api-design.md |
| POST | /api/report/favorites | お気に入り登録 | report:analysis:view | RPT | 10-analytics/91-api-design.md |
| POST | /api/report/kpi-comments | コメント登録 | report:dashboard:view | RPT | 10-analytics/91-api-design.md |
| GET | /api/report/kpi-targets | 目標一覧 | report:kpi:view | RPT | 10-analytics/91-api-design.md |
| PUT | /api/report/kpi-targets | 目標更新 | report:kpi:update | RPT | 10-analytics/91-api-design.md |
| GET | /api/report/kpis | KPI 一覧 | report:kpi:view | RPT | 10-analytics/91-api-design.md |
| POST | /api/report/kpis | KPI 定義登録 | report:kpi:update | RPT | 10-analytics/91-api-design.md |
| GET | /api/report/kpis/{code} | KPI 定義・トレンド | report:kpi:view | RPT | 10-analytics/01-dashboard.md |
| GET | /api/report/kpis/{code} | KPI 定義 | report:kpi:view | RPT | 10-analytics/91-api-design.md |
| PUT | /api/report/kpis/{code} | KPI 定義更新（版数 +1） | report:kpi:update | RPT | 10-analytics/91-api-design.md |
| GET | /api/report/kpis/{code}/trend | KPI トレンド | report:kpi:view | RPT | 10-analytics/91-api-design.md |
| GET | /api/report/quality-checks | 整合性検査結果 | report:quality:view | RPT | 10-analytics/91-api-design.md |
| GET | /api/report/subscriptions | 订阅一覧 | report:subscription:view | RPT | 10-analytics/91-api-design.md |
| POST | /api/report/subscriptions | 订阅登録 | report:subscription:update | RPT | 10-analytics/91-api-design.md |
| PUT | /api/report/subscriptions/{id} | 订阅更新 | report:subscription:update | RPT | 10-analytics/91-api-design.md |
| GET | /api/report/subscriptions/{id}/logs | 配信履歴 | report:subscription:view | RPT | 10-analytics/91-api-design.md |
| POST | /api/report/subscriptions/{id}/send | 即時配信 | report:subscription:update | RPT | 10-analytics/91-api-design.md |
| GET | /api/report/warning-rules | ルール一覧 | report:warning:view | RPT | 10-analytics/91-api-design.md |
| GET | /api/report/warnings | 予警一覧 | report:warning:view | RPT | 10-analytics/91-api-design.md |
| GET | /api/report/warnings/{id} | 予警詳細 | report:warning:view | RPT | 10-analytics/91-api-design.md |
| POST | /api/report/warnings/{id}/assign | 担当者設定 | report:warning:update | RPT | 10-analytics/91-api-design.md |
| POST | /api/report/warnings/{id}/resolve | 解決 | report:warning:update | RPT | 10-analytics/91-api-design.md |
| GET | /api/finance/ar-aging |  |  | SAL | 03-sales/91-api-design.md |
| GET | /api/finance/customers/{customerId}/credit-usage | FIN 與信使用額照会（FIN） | sales:credit:view | SAL | 03-sales/06-credit-pricing.md |
| GET | /api/finance/customers/{customerId}/credit-usage |  |  | SAL | 03-sales/91-api-design.md |
| GET | /api/finance/receivables |  |  | SAL | 03-sales/91-api-design.md |
| GET | /api/inventory/stock-balances/available | 可用量照会（INV） | sales:delivery:view | SAL | 03-sales/03-delivery-picking.md |
| GET | /api/inventory/stock-balances/available |  |  | SAL | 03-sales/91-api-design.md |
| GET | /api/inventory/stock-balances/available-batches | 批次可用明細（INV、FEFO/FIFO） | sales:delivery:pick | SAL | 03-sales/03-delivery-picking.md |
| GET | /api/inventory/stock-balances/available-batches |  |  | SAL | 03-sales/91-api-design.md |
| GET | /api/inventory/stock-txns |  |  | SAL | 03-sales/91-api-design.md |
| GET | /api/inventory/stock-txns?sourceType=SALES_DELIVERY&sourceId= | 出庫過帳狀況（INV） | sales:delivery:view | SAL | 03-sales/03-delivery-picking.md |
| GET | /api/mdm/customers/{id} |  |  | SAL | 03-sales/91-api-design.md |
| GET | /api/mdm/customers/{id}/credit-limit |  |  | SAL | 03-sales/91-api-design.md |
| GET | /api/mdm/materials/by-code/{code} |  |  | SAL | 03-sales/91-api-design.md |
| GET | /api/mdm/materials/{id} |  |  | SAL | 03-sales/91-api-design.md |
| GET | /api/mdm/payment-terms/{code} |  |  | SAL | 03-sales/91-api-design.md |
| GET | /api/mdm/prices/sales/effective | 有效價格照会（MDM。unitPriceNet/unitPriceGross/discount） | sales:price:view | SAL | 03-sales/06-credit-pricing.md |
| GET | /api/mdm/prices/sales/effective |  |  | SAL | 03-sales/91-api-design.md |
| POST | /api/mdm/prices/sales/effective-batch | 有効價格一括照会（MDM） | sales:price:view | SAL | 03-sales/06-credit-pricing.md |
| POST | /api/mdm/prices/sales/effective-batch |  |  | SAL | 03-sales/91-api-design.md |
| GET | /api/mdm/tax-codes/{code} |  |  | SAL | 03-sales/91-api-design.md |
| GET | /api/mdm/warehouses/{id} |  |  | SAL | 03-sales/91-api-design.md |
| POST | /api/sales/credit-overrides | 與信超限承認申請（SO の WF 提出） | sales:credit:submit | SAL | 03-sales/06-credit-pricing.md |
| POST | /api/sales/credit-overrides | 與信超限承認申請 | sales:credit:submit | SAL | 03-sales/91-api-design.md |
| GET | /api/sales/credits | 與信一覧（顧客別使用額） | sales:credit:view | SAL | 03-sales/06-credit-pricing.md |
| GET | /api/sales/credits | 與信一覧 | sales:credit:view | SAL | 03-sales/91-api-design.md |
| GET | /api/sales/credits/{customerId} | 顧客與信詳細（FIN 殘高等） | sales:credit:view | SAL | 03-sales/06-credit-pricing.md |
| GET | /api/sales/credits/{customerId} | 與信詳細 | sales:credit:view | SAL | 03-sales/91-api-design.md |
| GET | /api/sales/credits/{customerId}/check | 與信再判定（キャッシュ不使用） | sales:credit:view | SAL | 03-sales/06-credit-pricing.md |
| GET | /api/sales/credits/{customerId}/ledger | 與信台帳投影明細（FIN 台帳の読取） | sales:credit:view | SAL | 03-sales/91-api-design.md |
| GET | /api/sales/delivery-notes | DN 一覧 | sales:delivery:view | SAL | 03-sales/91-api-design.md |
| POST | /api/sales/delivery-notes | DN 作成 | sales:delivery:create | SAL | 03-sales/91-api-design.md |
| POST | /api/sales/delivery-notes/batch-confirm | 一括出荷確定（上限 200） | sales:delivery:confirm | SAL | 03-sales/91-api-design.md |
| GET | /api/sales/delivery-notes/{id} | DN 詳細（明細・ピッキング含む） | sales:delivery:view | SAL | 03-sales/03-delivery-picking.md |
| GET | /api/sales/delivery-notes/{id} | DN 詳細 | sales:delivery:view | SAL | 03-sales/91-api-design.md |
| PUT | /api/sales/delivery-notes/{id} | DN 更新（25 のみ） | sales:delivery:update | SAL | 03-sales/91-api-design.md |
| POST | /api/sales/delivery-notes/{id}/cancel | DN 取消 | sales:delivery:cancel | SAL | 03-sales/91-api-design.md |
| POST | /api/sales/delivery-notes/{id}/confirm | 出荷確定（E10 発行） | sales:delivery:confirm | SAL | 03-sales/03-delivery-picking.md |
| POST | /api/sales/delivery-notes/{id}/confirm | 出荷確定（E10） | sales:delivery:confirm | SAL | 03-sales/91-api-design.md |
| PUT | /api/sales/delivery-notes/{id}/lines/{lineId}/pick | ピッキング明細確定（批次/序列號/庫位） | sales:delivery:pick | SAL | 03-sales/03-delivery-picking.md |
| PUT | /api/sales/delivery-notes/{id}/lines/{lineId}/pick | ピッキング確定 | sales:delivery:pick | SAL | 03-sales/91-api-design.md |
| POST | /api/sales/delivery-notes/{id}/print | 送り状 PDF（PRT-SAL-004） | sales:delivery:print | SAL | 03-sales/03-delivery-picking.md |
| POST | /api/sales/delivery-notes/{id}/print | 送り状（PRT-SAL-004） | sales:delivery:print | SAL | 03-sales/91-api-design.md |
| GET | /api/sales/delivery-notes/{id}/serials | 元出荷序列號照会 | sales:return:view | SAL | 03-sales/91-api-design.md |
| POST | /api/sales/delivery-notes/{id}/start-picking | ピッキング開始（25→30） | sales:delivery:pick | SAL | 03-sales/03-delivery-picking.md |
| POST | /api/sales/delivery-notes/{id}/start-picking | ピッキング開始 | sales:delivery:pick | SAL | 03-sales/91-api-design.md |
| POST | /api/sales/exchanges | 換貨作成（返品＋新規受注） | sales:exchange:create | SAL | 03-sales/91-api-design.md |
| POST | /api/sales/exports | 非同期エクスポート | sales:report:export | SAL | 03-sales/91-api-design.md |
| GET | /api/sales/forecasts | 予測一覧 | sales:forecast:view | SAL | 03-sales/07-tracking-reports.md |
| GET | /api/sales/forecasts | 予測一覧（P2） | sales:forecast:view | SAL | 03-sales/91-api-design.md |
| POST | /api/sales/forecasts | 予測保存 | sales:forecast:create | SAL | 03-sales/07-tracking-reports.md |
| POST | /api/sales/forecasts | 予測保存（P2） | sales:forecast:create | SAL | 03-sales/91-api-design.md |
| POST | /api/sales/forecasts/{id}/confirm | 予測確定 | sales:forecast:create | SAL | 03-sales/07-tracking-reports.md |
| POST | /api/sales/forecasts/{id}/confirm | 予測確定（P2） | sales:forecast:create | SAL | 03-sales/91-api-design.md |
| GET | /api/sales/inquiries | 引合一覧 | sales:inquiry:view | SAL | 03-sales/91-api-design.md |
| POST | /api/sales/inquiries | 引合登録 | sales:inquiry:create | SAL | 03-sales/91-api-design.md |
| GET | /api/sales/inquiries/{id} | 引合詳細 | sales:inquiry:view | SAL | 03-sales/91-api-design.md |
| PUT | /api/sales/inquiries/{id} | 引合更新（回答含む） | sales:inquiry:update | SAL | 03-sales/91-api-design.md |
| POST | /api/sales/inquiries/{id}/cancel | 引合取消 | sales:inquiry:update | SAL | 03-sales/91-api-design.md |
| GET | /api/sales/invoice-applications | 開票申請一覧 | sales:invoice-application:view | SAL | 03-sales/91-api-design.md |
| POST | /api/sales/invoice-applications | 開票申請作成 | sales:invoice-application:create | SAL | 03-sales/91-api-design.md |
| GET | /api/sales/invoice-applications/invoiceable | 未開票明細照会 | sales:invoice-application:view | SAL | 03-sales/91-api-design.md |
| PUT | /api/sales/invoice-applications/{id} | 申請更新（10 のみ） | sales:invoice-application:create | SAL | 03-sales/91-api-design.md |
| GET | /api/sales/invoices | 発票一覧 | sales:invoice:view | SAL | 03-sales/91-api-design.md |
| POST | /api/sales/invoices | 発票登録（E12） | sales:invoice:create | SAL | 03-sales/91-api-design.md |
| GET | /api/sales/invoices/{id} | 発票詳細 | sales:invoice:view | SAL | 03-sales/91-api-design.md |
| POST | /api/sales/invoices/{id}/deliver | 交付 | sales:invoice:create | SAL | 03-sales/91-api-design.md |
| POST | /api/sales/invoices/{id}/print | 発票 PDF（PRT-SAL-008） | sales:invoice:view | SAL | 03-sales/91-api-design.md |
| POST | /api/sales/invoices/{id}/red | 赤伝登録（E12 RED） | sales:invoice:red | SAL | 03-sales/91-api-design.md |
| POST | /api/sales/invoices/{id}/reissue | 再発行（寫し） | sales:invoice:create | SAL | 03-sales/91-api-design.md |
| GET | /api/sales/jobs/{jobId} | ジョブ狀態 | sales:report:export | SAL | 03-sales/91-api-design.md |
| GET | /api/sales/jobs/{jobId}/files/{fileId} | ジョブ結果 DL | sales:report:export | SAL | 03-sales/91-api-design.md |
| GET | /api/sales/order-tracking | 執行跟蹤一覧 | sales:tracking:view | SAL | 03-sales/07-tracking-reports.md |
| GET | /api/sales/order-tracking | 訂單執行跟蹤 | sales:tracking:view | SAL | 03-sales/91-api-design.md |
| GET | /api/sales/order-tracking/delays | 納期遅延一覧 | sales:tracking:view | SAL | 03-sales/91-api-design.md |
| GET | /api/sales/order-tracking/shortages | 欠品一覧 | sales:tracking:view | SAL | 03-sales/91-api-design.md |
| GET | /api/sales/order-tracking/summary | KPI サマリ | sales:tracking:view | SAL | 03-sales/91-api-design.md |
| PUT | /api/sales/order-tracking/{orderId}/memo | 追跡メモ追記 | sales:tracking:view | SAL | 03-sales/91-api-design.md |
| GET | /api/sales/quotations | 見積一覧 | sales:quotation:view | SAL | 03-sales/91-api-design.md |
| POST | /api/sales/quotations | 見積作成 | sales:quotation:create | SAL | 03-sales/91-api-design.md |
| GET | /api/sales/quotations/{id} | 見積詳細 | sales:quotation:view | SAL | 03-sales/91-api-design.md |
| PUT | /api/sales/quotations/{id} | 見積更新（10 のみ） | sales:quotation:create | SAL | 03-sales/91-api-design.md |
| POST | /api/sales/quotations/{id}/approve | 承認 | sales:quotation:approve | SAL | 03-sales/91-api-design.md |
| POST | /api/sales/quotations/{id}/cancel | 見積取消・失効 | sales:quotation:create | SAL | 03-sales/01-quotation.md |
| POST | /api/sales/quotations/{id}/cancel | 見積取消 | sales:quotation:create | SAL | 03-sales/91-api-design.md |
| POST | /api/sales/quotations/{id}/convert | 受注轉換 | sales:quotation:convert | SAL | 03-sales/91-api-design.md |
| POST | /api/sales/quotations/{id}/issue | 發行（有効化） | sales:quotation:create | SAL | 03-sales/01-quotation.md |
| POST | /api/sales/quotations/{id}/issue | 發行 | sales:quotation:create | SAL | 03-sales/91-api-design.md |
| POST | /api/sales/quotations/{id}/print | 見積書 PDF（PRT-SAL-001） | sales:quotation:view | SAL | 03-sales/91-api-design.md |
| POST | /api/sales/quotations/{id}/reject | 却下 | sales:quotation:approve | SAL | 03-sales/91-api-design.md |
| POST | /api/sales/quotations/{id}/revise | 改訂（新版） | sales:quotation:create | SAL | 03-sales/91-api-design.md |
| GET | /api/sales/quotations/{id}/versions | 版數一覧・比較 | sales:quotation:view | SAL | 03-sales/91-api-design.md |
| GET | /api/sales/receivables | 應收一覧（投影 + FIN API） | sales:receivable:view | SAL | 03-sales/05-invoice-receivable.md |
| GET | /api/sales/receivables | 應收一覧 | sales:receivable:view | SAL | 03-sales/91-api-design.md |
| GET | /api/sales/receivables/aging | 帳齡分析（FIN API） | sales:receivable:view | SAL | 03-sales/91-api-design.md |
| GET | /api/sales/reports/customer-ranking | 顧客排名 | sales:report:view | SAL | 03-sales/91-api-design.md |
| GET | /api/sales/reports/gross-profit | 粗利分析 | sales:report:view | SAL | 03-sales/91-api-design.md |
| GET | /api/sales/reports/sales-detail | 売上明細 | sales:report:view | SAL | 03-sales/91-api-design.md |
| GET | /api/sales/reports/sales-summary | 売上サマリ（部門/擔當/月） | sales:report:view | SAL | 03-sales/07-tracking-reports.md |
| GET | /api/sales/reports/sales-summary | 売上サマリ | sales:report:view | SAL | 03-sales/91-api-design.md |
| GET | /api/sales/returns | 返品一覧 | sales:return:view | SAL | 03-sales/91-api-design.md |
| POST | /api/sales/returns | 返品登録 | sales:return:create | SAL | 03-sales/91-api-design.md |
| GET | /api/sales/returns/returnable-lines | 返品可能明細照会（元出荷指定） | sales:return:view | SAL | 03-sales/04-sales-return.md |
| GET | /api/sales/returns/returnable-lines | 返品可能明細照会 | sales:return:view | SAL | 03-sales/91-api-design.md |
| GET | /api/sales/returns/{id} | 返品詳細（検品・関連含む） | sales:return:view | SAL | 03-sales/04-sales-return.md |
| GET | /api/sales/returns/{id} | 返品詳細 | sales:return:view | SAL | 03-sales/91-api-design.md |
| PUT | /api/sales/returns/{id} | 返品更新（10 のみ） | sales:return:create | SAL | 03-sales/91-api-design.md |
| POST | /api/sales/returns/{id}/approve | 返品承認 | sales:return:approve | SAL | 03-sales/91-api-design.md |
| POST | /api/sales/returns/{id}/cancel | 返品取消 | sales:return:cancel | SAL | 03-sales/91-api-design.md |
| POST | /api/sales/returns/{id}/inspection/confirm | 検品確定（E11 発行） | sales:return:inspect | SAL | 03-sales/04-sales-return.md |
| POST | /api/sales/returns/{id}/inspection/confirm | 検品確定（E11） | sales:return:inspect | SAL | 03-sales/91-api-design.md |
| POST | /api/sales/returns/{id}/inspection/start | 検品開始 | sales:return:inspect | SAL | 03-sales/91-api-design.md |
| POST | /api/sales/returns/{id}/print | 返品受付票（PRT-SAL-006） | sales:return:view | SAL | 03-sales/91-api-design.md |
| POST | /api/sales/returns/{id}/submit | 返品提出 | sales:return:create | SAL | 03-sales/91-api-design.md |
| GET | /api/sales/sales-orders | 受注一覧 | sales:order:view | SAL | 03-sales/91-api-design.md |
| GET | /api/sales/sales-orders | 受注一覧（ページング） | sales:order:view | SAL | 03-sales/02-sales-order.md |
| POST | /api/sales/sales-orders | 受注登録 | sales:order:create | SAL | 03-sales/91-api-design.md |
| POST | /api/sales/sales-orders/batch-approve | 一括承認 | sales:order:approve | SAL | 03-sales/91-api-design.md |
| POST | /api/sales/sales-orders/batch-submit | 一括提出（上限 1,000） | sales:order:submit | SAL | 03-sales/02-sales-order.md |
| POST | /api/sales/sales-orders/batch-submit | 一括提出 | sales:order:submit | SAL | 03-sales/91-api-design.md |
| GET | /api/sales/sales-orders/{id} | 受注詳細（明細・履歴含む） | sales:order:view | SAL | 03-sales/02-sales-order.md |
| GET | /api/sales/sales-orders/{id} | 受注詳細（明細・履歴） | sales:order:view | SAL | 03-sales/91-api-design.md |
| PUT | /api/sales/sales-orders/{id} | 受注更新（10 のみ） | sales:order:update | SAL | 03-sales/91-api-design.md |
| POST | /api/sales/sales-orders/{id}/approve | 承認（最終承認で E06） | sales:order:approve | SAL | 03-sales/02-sales-order.md |
| POST | /api/sales/sales-orders/{id}/approve | 承認（E06） | sales:order:approve | SAL | 03-sales/91-api-design.md |
| POST | /api/sales/sales-orders/{id}/cancel | 取消（E08） | sales:order:cancel | SAL | 03-sales/91-api-design.md |
| POST | /api/sales/sales-orders/{id}/changes | 変更開始（版作成） | sales:order:change | SAL | 03-sales/91-api-design.md |
| PUT | /api/sales/sales-orders/{id}/changes/{versionNo} | 変更內容保存 | sales:order:change | SAL | 03-sales/91-api-design.md |
| POST | /api/sales/sales-orders/{id}/changes/{versionNo}/approve | 変更承認（E07） | sales:order:approve | SAL | 03-sales/91-api-design.md |
| POST | /api/sales/sales-orders/{id}/changes/{versionNo}/submit | 変更提出 | sales:order:submit | SAL | 03-sales/91-api-design.md |
| POST | /api/sales/sales-orders/{id}/close | クローズ | sales:order:close | SAL | 03-sales/91-api-design.md |
| GET | /api/sales/sales-orders/{id}/credit-check | 與信再判定 | sales:credit:view | SAL | 03-sales/91-api-design.md |
| PUT | /api/sales/sales-orders/{id}/export-info | 輸出販売情報 | sales:export:update | SAL | 03-sales/07-tracking-reports.md |
| PUT | /api/sales/sales-orders/{id}/export-info | 輸出販売情報（P2） | sales:export:update | SAL | 03-sales/91-api-design.md |
| POST | /api/sales/sales-orders/{id}/print | 注文請書 PDF（PRT-SAL-002） | sales:order:print | SAL | 03-sales/02-sales-order.md |
| POST | /api/sales/sales-orders/{id}/print | 注文請書（PRT-SAL-002） | sales:order:print | SAL | 03-sales/91-api-design.md |
| POST | /api/sales/sales-orders/{id}/return | 差戻し | sales:order:approve | SAL | 03-sales/91-api-design.md |
| POST | /api/sales/sales-orders/{id}/submit | 提出（E05） | sales:order:submit | SAL | 03-sales/91-api-design.md |
| POST | /api/sales/sales-orders/{id}/withdraw | 撤回 | sales:order:submit | SAL | 03-sales/91-api-design.md |
| GET | /api/sales/shipments | 出荷実績照会 | sales:delivery:view | SAL | 03-sales/91-api-design.md |
| GET | /api/sales/shipments/trace | 序列號トレース（serialNo） | sales:delivery:view | SAL | 03-sales/03-delivery-picking.md |
| GET | /api/sales/shipments/trace | 序列號トレース | sales:delivery:view | SAL | 03-sales/91-api-design.md |
| GET | /api/sales/special-prices | 特價申請一覧 | sales:price-override:view | SAL | 03-sales/06-credit-pricing.md |
| GET | /api/sales/special-prices | 特價一覧 | sales:price-override:view | SAL | 03-sales/91-api-design.md |
| POST | /api/sales/special-prices | 特價申請登録 | sales:price-override:create | SAL | 03-sales/06-credit-pricing.md |
| POST | /api/sales/special-prices | 特價登録 | sales:price-override:create | SAL | 03-sales/91-api-design.md |
| GET | /api/sales/special-prices/{id} | 特價申請詳細 | sales:price-override:view | SAL | 03-sales/06-credit-pricing.md |
| GET | /api/sales/special-prices/{id} | 特價詳細 | sales:price-override:view | SAL | 03-sales/91-api-design.md |
| PUT | /api/sales/special-prices/{id} | 特價申請更新（10 のみ） | sales:price-override:create | SAL | 03-sales/06-credit-pricing.md |
| PUT | /api/sales/special-prices/{id} | 特價更新（10 のみ） | sales:price-override:create | SAL | 03-sales/91-api-design.md |
| POST | /api/sales/special-prices/{id}/approve | 特價承認 | sales:price-override:approve | SAL | 03-sales/91-api-design.md |
| POST | /api/sales/special-prices/{id}/cancel | 特價取消 | sales:price-override:approve | SAL | 03-sales/91-api-design.md |
| POST | /api/sales/special-prices/{id}/print | 特價審批單（PRT-SAL-016） | sales:price-override:view | SAL | 03-sales/91-api-design.md |
| POST | /api/sales/special-prices/{id}/submit | 特價申請提出 | sales:price-override:create | SAL | 03-sales/06-credit-pricing.md |
| POST | /api/sales/special-prices/{id}/submit | 特價提出 | sales:price-override:create | SAL | 03-sales/91-api-design.md |
| GET | /api/sales/statements | 対账单一覧 | sales:statement:view | SAL | 03-sales/91-api-design.md |
| POST | /api/sales/statements/generate | 対账单生成 | sales:statement:create | SAL | 03-sales/91-api-design.md |
| GET | /api/sales/statements/{id} | 対账单詳細（明細含む） | sales:statement:view | SAL | 03-sales/05-invoice-receivable.md |
| GET | /api/sales/statements/{id} | 対账单詳細 | sales:statement:view | SAL | 03-sales/91-api-design.md |
| POST | /api/sales/statements/{id}/confirm | 顧客確認 | sales:statement:confirm | SAL | 03-sales/91-api-design.md |
| POST | /api/sales/statements/{id}/print | 対账单 PDF（PRT-SAL-009） | sales:statement:view | SAL | 03-sales/91-api-design.md |
| POST | /api/sales/statements/{id}/send | 対账单送付 | sales:statement:create | SAL | 03-sales/91-api-design.md |
| GET | /api/system/sequences/{key} |  |  | SAL | 03-sales/91-api-design.md |
| POST | /api/workflow/processes |  |  | SAL | 03-sales/91-api-design.md |
| GET | /api/system/attachments | 添付検索（管理用） | system:attachment:view | SYS | 01-system/05-audit-attachment-notify.md |
| GET | /api/system/attachments | 添付検索 | system:attachment:view | SYS | 01-system/91-api-design.md |
| POST | /api/system/attachments | アップロード（multipart） | system:attachment:upload | SYS | 01-system/05-audit-attachment-notify.md |
| POST | /api/system/attachments | 添付アップロード | system:attachment:upload | SYS | 01-system/91-api-design.md |
| GET | /api/system/attachments/biz/{bizType}/{bizId} | 業務別添付一覧 | 認証済 | SYS | 01-system/05-audit-attachment-notify.md |
| GET | /api/system/attachments/biz/{bizType}/{bizId} | 業務別添付 | 認証済 | SYS | 01-system/91-api-design.md |
| DELETE | /api/system/attachments/{id} | 添付削除 | system:attachment:delete | SYS | 01-system/91-api-design.md |
| GET | /api/system/attachments/{id} | ダウンロード | system:attachment:view | SYS | 01-system/05-audit-attachment-notify.md |
| GET | /api/system/attachments/{id} | 添付ダウンロード | system:attachment:view | SYS | 01-system/91-api-design.md |
| GET | /api/system/audit-logs | 監査ログ検索 | system:audit-log:view | SYS | 01-system/91-api-design.md |
| POST | /api/system/audit-logs/export | 監査エクスポート（非同期） | system:audit-log:export | SYS | 01-system/05-audit-attachment-notify.md |
| POST | /api/system/audit-logs/export | 監査出力 | system:audit-log:export | SYS | 01-system/91-api-design.md |
| GET | /api/system/audit-logs/{id} | 監査詳細 | system:audit-log:view | SYS | 01-system/91-api-design.md |
| GET | /api/system/auth/captchas | 検証コード発行 | 公開 | SYS | 01-system/91-api-design.md |
| POST | /api/system/auth/login | ログイン | 公開 | SYS | 01-system/91-api-design.md |
| POST | /api/system/auth/logout | ログアウト | 認証済 | SYS | 01-system/91-api-design.md |
| GET | /api/system/auth/me | ログインユーザ・権限・メニュー取得 | 認証済 | SYS | 01-system/01-auth-login.md |
| GET | /api/system/auth/me | ログインユーザ・権限（コードで重複排除）・メニュー | 認証済 | SYS | 01-system/91-api-design.md |
| POST | /api/system/auth/password | パスワード変更 | 認証済 | SYS | 01-system/91-api-design.md |
| POST | /api/system/caches/refresh | キャッシュ再構築 | system:cache:refresh | SYS | 01-system/91-api-design.md |
| GET | /api/system/companies | 公司一覧 | system:company:view | SYS | 01-system/91-api-design.md |
| POST | /api/system/companies | 公司登録（PRC-SYS-014-03） | system:company:create | SYS | 01-system/03-org-position.md |
| POST | /api/system/companies | 公司登録（同一 TX で sys_init_company を呼び sys_param 既定行と SYSTEM_ADMIN ロール＋全権限付与を投入、90 §3.1・94 §2.10） | system:company:create | SYS | 01-system/91-api-design.md |
| PUT | /api/system/companies/{id} | 公司更新 | system:company:update | SYS | 01-system/91-api-design.md |
| POST | /api/system/departments | 部門登録 | system:department:create | SYS | 01-system/91-api-design.md |
| GET | /api/system/departments/options | 部門選択用一覧（ドロップダウン、§3.7） | 認証済（§1.2） | SYS | 01-system/91-api-design.md |
| GET | /api/system/departments/tree | 部門ツリー（有効のみ/全部） | system:department:view | SYS | 01-system/03-org-position.md |
| GET | /api/system/departments/tree | 部門ツリー | system:department:view | SYS | 01-system/91-api-design.md |
| DELETE | /api/system/departments/{id} | 部門無効化 | system:department:delete | SYS | 01-system/91-api-design.md |
| GET | /api/system/departments/{id} | 部門詳細 | system:department:view | SYS | 01-system/91-api-design.md |
| PUT | /api/system/departments/{id} | 部門更新 | system:department:update | SYS | 01-system/91-api-design.md |
| PUT | /api/system/departments/{id}/move | 部門移動（適用日付き） | system:department:update | SYS | 01-system/03-org-position.md |
| PUT | /api/system/departments/{id}/move | 部門移動 | system:department:update | SYS | 01-system/91-api-design.md |
| GET | /api/system/departments/{id}/users | 所属ユーザ一覧 | system:user:view | SYS | 01-system/03-org-position.md |
| GET | /api/system/departments/{id}/users | 所属ユーザ | system:user:view | SYS | 01-system/91-api-design.md |
| GET | /api/system/dicts | 字典类型一覧 | system:dict:view | SYS | 01-system/91-api-design.md |
| POST | /api/system/dicts | 字典类型登録 | system:dict:create | SYS | 01-system/91-api-design.md |
| GET | /api/system/dicts/{code}/items | 字典項目一覧（有効のみ） | 認証済（業務参照） | SYS | 01-system/04-menu-dict-param.md |
| GET | /api/system/dicts/{code}/items | 字典項目（業務参照） | 認証済 | SYS | 01-system/91-api-design.md |
| PUT | /api/system/dicts/{code}/items | 字典項目一括保存 | system:dict:update | SYS | 01-system/91-api-design.md |
| GET | /api/system/factories | 工厂组织設合一覧（MDM の mdm_factory を参照） | system:company:view | SYS | 01-system/91-api-design.md |
| POST | /api/system/factories | 工厂组织設定登録（有効化・既定割当） | system:company:update | SYS | 01-system/03-org-position.md |
| POST | /api/system/factories | 工厂組織設定登録（有効化・既定割当） | system:company:update | SYS | 01-system/91-api-design.md |
| PUT | /api/system/factories/{id} | 工厂组织設定更新 | system:company:update | SYS | 01-system/03-org-position.md |
| PUT | /api/system/factories/{id} | 工厂組織設定更新 | system:company:update | SYS | 01-system/91-api-design.md |
| GET | /api/system/import-templates/{id}/download | テンプレート DL | system:import-template:view | SYS | 01-system/91-api-design.md |
| GET | /api/system/jobs | ジョブ一覧 | system:job:view | SYS | 01-system/91-api-design.md |
| POST | /api/system/jobs/export | エクスポート起動 | 各域 :export | SYS | 01-system/91-api-design.md |
| POST | /api/system/jobs/import | インポート起動（multipart） | system:job:create | SYS | 01-system/06-import-export-numbering.md |
| POST | /api/system/jobs/import | インポート起動 | system:job:create | SYS | 01-system/91-api-design.md |
| DELETE | /api/system/jobs/{id} | キャンセル | system:job:cancel | SYS | 01-system/91-api-design.md |
| GET | /api/system/jobs/{id} | ジョブ状態・進捗 | system:job:view | SYS | 01-system/06-import-export-numbering.md |
| GET | /api/system/jobs/{id} | ジョブ状態 | system:job:view | SYS | 01-system/91-api-design.md |
| GET | /api/system/jobs/{id}/download | （互換）結果 DL | system:job:download | SYS | 01-system/06-import-export-numbering.md |
| GET | /api/system/jobs/{id}/errors | エラー行一覧 | system:job:view | SYS | 01-system/91-api-design.md |
| POST | /api/system/jobs/{id}/errors/export | エラー報告出力（PRT-SYS-005） | system:job:view | SYS | 01-system/06-import-export-numbering.md |
| POST | /api/system/jobs/{id}/errors/export | エラー報告出力 | system:job:view | SYS | 01-system/91-api-design.md |
| GET | /api/system/jobs/{id}/files/{fileId} | 結果 DL | system:job:download | SYS | 01-system/91-api-design.md |
| POST | /api/system/jobs/{id}/retry | 再実行 | system:job:create | SYS | 01-system/91-api-design.md |
| GET | /api/system/login-logs | ログインログ検索 | system:login-log:view | SYS | 01-system/91-api-design.md |
| POST | /api/system/login-logs/export | ログインログ出力 | system:login-log:export | SYS | 01-system/91-api-design.md |
| POST | /api/system/maintenance/dry-run | ドライラン | system:maintenance:execute | SYS | 01-system/91-api-design.md |
| POST | /api/system/maintenance/execute | 実行 | system:maintenance:execute | SYS | 01-system/07-scheduled-job-print-monitor.md |
| POST | /api/system/maintenance/execute | 维护実行 | system:maintenance:execute | SYS | 01-system/91-api-design.md |
| GET | /api/system/maintenance/logs | 维护履歴 | system:maintenance:view | SYS | 01-system/91-api-design.md |
| GET | /api/system/maintenance/options | 维护種別一覧 | system:maintenance:view | SYS | 01-system/07-scheduled-job-print-monitor.md |
| GET | /api/system/maintenance/options | 维护種別 | system:maintenance:view | SYS | 01-system/91-api-design.md |
| POST | /api/system/menus | メニュー登録 | system:menu:create | SYS | 01-system/91-api-design.md |
| GET | /api/system/menus/routes | ログインユーザのルート（フロント生成用） | 認証済 | SYS | 01-system/04-menu-dict-param.md |
| GET | /api/system/menus/routes | ログインユーザのルート | 認証済 | SYS | 01-system/91-api-design.md |
| GET | /api/system/menus/tree | 管理用メニューツリー | system:menu:view | SYS | 01-system/91-api-design.md |
| DELETE | /api/system/menus/{id} | メニュー無効化 | system:menu:delete | SYS | 01-system/91-api-design.md |
| PUT | /api/system/menus/{id} | メニュー更新 | system:menu:update | SYS | 01-system/91-api-design.md |
| GET | /api/system/notification-logs | 送信履歴 | system:notification-log:view | SYS | 01-system/91-api-design.md |
| POST | /api/system/notification-logs/{id}/resend | 再送 | system:notification-log:view | SYS | 01-system/91-api-design.md |
| GET | /api/system/notification-templates | テンプレート一覧 | system:notification-template:view | SYS | 01-system/91-api-design.md |
| POST | /api/system/notification-templates | テンプレート新版登録 | system:notification-template:update | SYS | 01-system/05-audit-attachment-notify.md |
| POST | /api/system/notification-templates | テンプレート新版 | system:notification-template:update | SYS | 01-system/91-api-design.md |
| POST | /api/system/notification-templates/{id}/test-send | テスト送信 | system:notification-template:update | SYS | 01-system/91-api-design.md |
| GET | /api/system/notifications | 通知一覧（受信箱） | system:notification:view | SYS | 01-system/05-audit-attachment-notify.md |
| GET | /api/system/notifications | 通知一覧 | system:notification:view | SYS | 01-system/91-api-design.md |
| PUT | /api/system/notifications/read-all | 一括既読 | system:notification:read | SYS | 01-system/91-api-design.md |
| GET | /api/system/notifications/todos | 待办一覧（WF 連携） | 認証済 | SYS | 01-system/91-api-design.md |
| GET | /api/system/notifications/unread-count | 未読件数 | system:notification:view | SYS | 01-system/91-api-design.md |
| PUT | /api/system/notifications/{id}/read | 既読 | system:notification:read | SYS | 01-system/91-api-design.md |
| GET | /api/system/number-rules | 採番ルール一覧 | system:number-rule:view | SYS | 01-system/91-api-design.md |
| POST | /api/system/number-rules | ルール登録 | system:number-rule:update | SYS | 01-system/91-api-design.md |
| GET | /api/system/number-rules/{code} | 採番ルール詳細 | system:number-rule:view | SYS | 01-system/91-api-design.md |
| PUT | /api/system/number-rules/{code} | ルール更新 | system:number-rule:update | SYS | 01-system/91-api-design.md |
| POST | /api/system/number-rules/{code}/preview | 採番プレビュー（消費なし） | system:number-rule:view | SYS | 01-system/06-import-export-numbering.md |
| POST | /api/system/number-rules/{code}/preview | 採番プレビュー | system:number-rule:view | SYS | 01-system/91-api-design.md |
| POST | /api/system/numbers | 採番実行（他域から Service 呼出。API は公開しない） | 内部（サービス間） | SYS | 01-system/06-import-export-numbering.md |
| GET | /api/system/online-users | セッション一覧 | system:online-user:view | SYS | 01-system/91-api-design.md |
| POST | /api/system/online-users/{tokenId}/kickout | 強制ログアウト | system:online-user:kickout | SYS | 01-system/91-api-design.md |
| GET | /api/system/outbox-events | Outbox 監視 | system:outbox:view | SYS | 01-system/91-api-design.md |
| POST | /api/system/outbox-events/{id}/retry | イベント再送 | system:outbox:retry | SYS | 01-system/91-api-design.md |
| GET | /api/system/params | パラメータ一覧 | system:param:view | SYS | 01-system/91-api-design.md |
| GET | /api/system/params/{key} | パラメータ取得 | 認証済 | SYS | 01-system/91-api-design.md |
| PUT | /api/system/params/{key} | パラメータ更新 | system:param:update | SYS | 01-system/91-api-design.md |
| GET | /api/system/positions | 岗位一覧 | system:position:view | SYS | 01-system/91-api-design.md |
| POST | /api/system/positions | 岗位登録 | system:position:create | SYS | 01-system/91-api-design.md |
| DELETE | /api/system/positions/{id} | 岗位無効化 | system:position:delete | SYS | 01-system/91-api-design.md |
| PUT | /api/system/positions/{id} | 岗位更新 | system:position:update | SYS | 01-system/91-api-design.md |
| GET | /api/system/print-templates/{id} | テンプレート詳細 | system:print-template:view | SYS | 01-system/07-scheduled-job-print-monitor.md |
| GET | /api/system/print-templates/{id} | 詳細 | system:print-template:view | SYS | 01-system/91-api-design.md |
| PUT | /api/system/print-templates/{id}/default | 既定指定 | system:print-template:update | SYS | 01-system/91-api-design.md |
| POST | /api/system/print-templates/{id}/preview | プレビュー PDF | system:print-template:view | SYS | 01-system/07-scheduled-job-print-monitor.md |
| POST | /api/system/print-templates/{id}/preview | プレビュー | system:print-template:view | SYS | 01-system/91-api-design.md |
| GET | /api/system/profile | 個人プロフィール取得 | 認証済 | SYS | 01-system/01-auth-login.md |
| GET | /api/system/profile | プロフィール取得 | 認証済 | SYS | 01-system/91-api-design.md |
| PUT | /api/system/profile | プロフィール更新 | system:profile:update | SYS | 01-system/91-api-design.md |
| PUT | /api/system/profile/preferences | 通知・画面設定更新 | system:profile:update | SYS | 01-system/01-auth-login.md |
| PUT | /api/system/profile/preferences | 通知・画面設定 | system:profile:update | SYS | 01-system/91-api-design.md |
| GET | /api/system/profile/sessions | 自セッション一覧 | system:profile:view | SYS | 01-system/91-api-design.md |
| DELETE | /api/system/profile/sessions/{tokenId} | 他セッション失効 | system:profile:update | SYS | 01-system/91-api-design.md |
| GET | /api/system/roles | ロール一覧 | system:role:view | SYS | 01-system/91-api-design.md |
| POST | /api/system/roles | ロール登録 | system:role:create | SYS | 01-system/91-api-design.md |
| DELETE | /api/system/roles/{id} | ロール削除 | system:role:delete | SYS | 01-system/91-api-design.md |
| GET | /api/system/roles/{id} | ロール詳細（権限ツリー含む） | system:role:view | SYS | 01-system/02-user-role-permission.md |
| GET | /api/system/roles/{id} | ロール詳細 | system:role:view | SYS | 01-system/91-api-design.md |
| PUT | /api/system/roles/{id} | ロール更新 | system:role:update | SYS | 01-system/91-api-design.md |
| POST | /api/system/roles/{id}/export | 権限マトリクス出力 | system:role:export | SYS | 01-system/02-user-role-permission.md |
| GET | /api/system/roles/{id}/users | 付与ユーザ一覧 | system:role:view | SYS | 01-system/91-api-design.md |
| GET | /api/system/scheduled-jobs | ジョブ定義一覧 | system:job-monitor:view | SYS | 01-system/91-api-design.md |
| GET | /api/system/scheduled-jobs/{id}/logs | 実行履歴 | system:job-monitor:view | SYS | 01-system/91-api-design.md |
| POST | /api/system/scheduled-jobs/{id}/run | 手動実行 | system:job-monitor:run | SYS | 01-system/91-api-design.md |
| PUT | /api/system/scheduled-jobs/{id}/status | 停止/再開 | system:job-monitor:run | SYS | 01-system/91-api-design.md |
| GET | /api/system/tenants | 租户一覧 | system:tenant:view | SYS | 01-system/91-api-design.md |
| GET | /api/system/users | ユーザ一覧（ページング） | system:user:view | SYS | 01-system/02-user-role-permission.md |
| GET | /api/system/users | ユーザ一覧 | system:user:view | SYS | 01-system/91-api-design.md |
| POST | /api/system/users | ユーザ登録 | system:user:create | SYS | 01-system/91-api-design.md |
| POST | /api/system/users/batch-disable | 一括停用 | system:user:disable | SYS | 01-system/91-api-design.md |
| POST | /api/system/users/export | エクスポート（非同期） | system:user:export | SYS | 01-system/02-user-role-permission.md |
| POST | /api/system/users/export | ユーザ台帳出力 | system:user:export | SYS | 01-system/91-api-design.md |
| GET | /api/system/users/next-code | 工号採番候補 | system:user:create | SYS | 01-system/91-api-design.md |
| DELETE | /api/system/users/{id} | ユーザ削除（論理削除。原則停用） | system:user:delete | SYS | 01-system/02-user-role-permission.md |
| DELETE | /api/system/users/{id} | ユーザ削除 | system:user:delete | SYS | 01-system/91-api-design.md |
| GET | /api/system/users/{id} | ユーザ詳細 | system:user:view | SYS | 01-system/91-api-design.md |
| PUT | /api/system/users/{id} | ユーザ更新 | system:user:update | SYS | 01-system/91-api-design.md |
| POST | /api/system/users/{id}/disable | 停用 | system:user:disable | SYS | 01-system/91-api-design.md |
| POST | /api/system/users/{id}/enable | 再開 | system:user:reopen | SYS | 01-system/91-api-design.md |
| POST | /api/system/users/{id}/reset-password | パスワードリセット | system:user:reset-password | SYS | 01-system/91-api-design.md |
| GET | /api/system/users/{id}/roles | 付与ロール取得 | system:user:view | SYS | 01-system/02-user-role-permission.md |
| GET | /api/system/users/{id}/roles | 付与ロール | system:user:view | SYS | 01-system/91-api-design.md |
| POST | /api/system/users/{id}/roles | ロール付与 | system:user-role:update | SYS | 01-system/91-api-design.md |
| POST | /api/system/users/{id}/unlock | ロック解除 | system:user:unlock | SYS | 01-system/91-api-design.md |
| GET | /api/workflow/approval-matrices | マトリクス一覧 | workflow:mapping:view | WF | 08-workflow/91-api-design.md |
| POST | /api/workflow/approval-matrices | マトリクス登録 | workflow:mapping:update | WF | 08-workflow/91-api-design.md |
| POST | /api/workflow/approval-matrices/validate | 承認者解決チェック | workflow:mapping:update | WF | 08-workflow/91-api-design.md |
| DELETE | /api/workflow/approval-matrices/{id} | マトリクス削除 | workflow:mapping:update | WF | 08-workflow/91-api-design.md |
| GET | /api/workflow/approval-matrices/{id} | マトリクス詳細（明細含む） | workflow:mapping:view | WF | 08-workflow/01-process-model.md |
| GET | /api/workflow/approval-matrices/{id} | マトリクス詳細 | workflow:mapping:view | WF | 08-workflow/91-api-design.md |
| PUT | /api/workflow/approval-matrices/{id} | マトリクス更新 | workflow:mapping:update | WF | 08-workflow/91-api-design.md |
| POST | /api/workflow/approval-routes/resolve | 承認要否・経路照会（業務域→WF） | 認証済（業務域内部参照） | WF | 08-workflow/91-api-design.md |
| GET | /api/workflow/business-processes | 我发起的（一覧） | workflow:task:view | WF | 08-workflow/02-approval-runtime.md |
| GET | /api/workflow/business-processes | 我发起的 | workflow:task:view | WF | 08-workflow/91-api-design.md |
| POST | /api/workflow/business-processes | 提出（プロセス開始） | workflow:instance:submit | WF | 08-workflow/02-approval-runtime.md |
| POST | /api/workflow/business-processes | 提出（開始） | workflow:instance:submit | WF | 08-workflow/91-api-design.md |
| POST | /api/workflow/business-processes/preview | 提出プレビュー（経路・承認者） | workflow:instance:submit | WF | 08-workflow/02-approval-runtime.md |
| POST | /api/workflow/business-processes/preview | 提出プレビュー | workflow:instance:submit | WF | 08-workflow/91-api-design.md |
| GET | /api/workflow/business-processes/{bizType}/{bizId} | 業務の承認状態参照 | workflow:task:view | WF | 08-workflow/02-approval-runtime.md |
| GET | /api/workflow/business-processes/{bizType}/{bizId} | 承認状態参照 | workflow:task:view | WF | 08-workflow/91-api-design.md |
| GET | /api/workflow/business-processes/{id}/diagram | 経路図 | workflow:task:view | WF | 08-workflow/91-api-design.md |
| GET | /api/workflow/business-processes/{id}/history | 承認履歴（タイムライン） | workflow:task:view | WF | 08-workflow/02-approval-runtime.md |
| GET | /api/workflow/business-processes/{id}/history | 承認履歴 | workflow:task:view | WF | 08-workflow/91-api-design.md |
| GET | /api/workflow/business-types | 業務類型一覧 | workflow:mapping:view | WF | 08-workflow/91-api-design.md |
| POST | /api/workflow/business-types | 業務類型登録 | workflow:mapping:update | WF | 08-workflow/91-api-design.md |
| PUT | /api/workflow/business-types/{code} | 業務類型更新 | workflow:mapping:update | WF | 08-workflow/01-process-model.md |
| GET | /api/workflow/ccs | 抄送我的 | workflow:task:view | WF | 08-workflow/91-api-design.md |
| PUT | /api/workflow/ccs/{id}/read | 抄送既読 | 認証済 | WF | 08-workflow/91-api-design.md |
| GET | /api/workflow/dashboard/pending-count | 未処理件数（ヘッダバッジ） | workflow:task:view | WF | 08-workflow/02-approval-runtime.md |
| GET | /api/workflow/dashboard/pending-count | 未処理件数 | workflow:task:view | WF | 08-workflow/91-api-design.md |
| GET | /api/workflow/delegations | 代理設定一覧（自分/代理人/管理者） | workflow:delegation:update | WF | 08-workflow/03-approval-admin.md |
| GET | /api/workflow/delegations | 代理設定一覧 | workflow:delegation:update | WF | 08-workflow/91-api-design.md |
| POST | /api/workflow/delegations | 代理設定登録 | workflow:delegation:update | WF | 08-workflow/91-api-design.md |
| GET | /api/workflow/delegations/effective | 有効な代理（代理人向け） | workflow:task:view | WF | 08-workflow/03-approval-admin.md |
| GET | /api/workflow/delegations/effective | 有効代理 | workflow:task:view | WF | 08-workflow/91-api-design.md |
| DELETE | /api/workflow/delegations/{id} | 代理解除 | workflow:delegation:update | WF | 08-workflow/91-api-design.md |
| GET | /api/workflow/field-permissions | フィールド権限一覧 | workflow:field-permission:update | WF | 08-workflow/91-api-design.md |
| PUT | /api/workflow/field-permissions | フィールド権限保存 | workflow:field-permission:update | WF | 08-workflow/91-api-design.md |
| GET | /api/workflow/instances | インスタンス一覧 | workflow:instance:view | WF | 08-workflow/91-api-design.md |
| GET | /api/workflow/instances/{id} | インスタンス詳細（変数・履歴） | workflow:instance:view | WF | 08-workflow/03-approval-admin.md |
| GET | /api/workflow/instances/{id} | インスタンス詳細 | workflow:instance:view | WF | 08-workflow/91-api-design.md |
| POST | /api/workflow/instances/{id}/jump | 跳转 | workflow:instance:manage | WF | 08-workflow/91-api-design.md |
| POST | /api/workflow/instances/{id}/suspend | 挂起 | workflow:instance:manage | WF | 08-workflow/91-api-design.md |
| POST | /api/workflow/instances/{id}/terminate | 強制終了 | workflow:instance:manage | WF | 08-workflow/91-api-design.md |
| GET | /api/workflow/monitor/pending-top | 滞留上位一覧 | workflow:monitor:view | WF | 08-workflow/03-approval-admin.md |
| GET | /api/workflow/monitor/pending-top | 滞留上位 | workflow:monitor:view | WF | 08-workflow/91-api-design.md |
| GET | /api/workflow/monitor/summary | 監視サマリ | workflow:monitor:view | WF | 08-workflow/91-api-design.md |
| GET | /api/workflow/process-definitions | 定義一覧 | workflow:process:view | WF | 08-workflow/01-process-model.md |
| GET | /api/workflow/process-definitions | 流程定義一覧 | workflow:process:view | WF | 08-workflow/91-api-design.md |
| POST | /api/workflow/process-definitions/deploy | BPMN デプロイ | workflow:process:deploy | WF | 08-workflow/91-api-design.md |
| DELETE | /api/workflow/process-definitions/{id} | 定義廃止 | workflow:process:update | WF | 08-workflow/91-api-design.md |
| GET | /api/workflow/process-definitions/{id} | 定義詳細 | workflow:process:view | WF | 08-workflow/91-api-design.md |
| PUT | /api/workflow/process-definitions/{id} | 定義属性更新 | workflow:process:update | WF | 08-workflow/91-api-design.md |
| PUT | /api/workflow/process-definitions/{id}/active | 有効/無効 | workflow:process:update | WF | 08-workflow/91-api-design.md |
| PUT | /api/workflow/process-definitions/{id}/default | 既定版切替 | workflow:process:update | WF | 08-workflow/91-api-design.md |
| GET | /api/workflow/process-definitions/{id}/diagram | 経路 SVG | workflow:process:view | WF | 08-workflow/91-api-design.md |
| GET | /api/workflow/process-mappings | マッピング一覧 | workflow:mapping:view | WF | 08-workflow/91-api-design.md |
| POST | /api/workflow/process-mappings | マッピング登録 | workflow:mapping:update | WF | 08-workflow/91-api-design.md |
| DELETE | /api/workflow/process-mappings/{id} | マッピング削除 | workflow:mapping:update | WF | 08-workflow/91-api-design.md |
| PUT | /api/workflow/process-mappings/{id} | マッピング更新 | workflow:mapping:update | WF | 08-workflow/91-api-design.md |
| GET | /api/workflow/tasks/done | 已办一覧 | workflow:task:view | WF | 08-workflow/91-api-design.md |
| GET | /api/workflow/tasks/todo | 待办一覧 | workflow:task:view | WF | 08-workflow/91-api-design.md |
| POST | /api/workflow/tasks/transfer-batch | タスク一括転送（ユーザ停用時の代理転送等） | workflow:instance:manage | WF | 08-workflow/91-api-design.md |
| GET | /api/workflow/tasks/{taskId} | 承認画面情報（スナップショット・権限・履歴） | workflow:task:view | WF | 08-workflow/02-approval-runtime.md |
| GET | /api/workflow/tasks/{taskId} | 承認画面情報 | workflow:task:view | WF | 08-workflow/91-api-design.md |
| POST | /api/workflow/tasks/{taskId}/add-sign | 加签 | workflow:task:add-sign | WF | 08-workflow/91-api-design.md |
| POST | /api/workflow/tasks/{taskId}/approve | 同意 | workflow:task:approve | WF | 08-workflow/91-api-design.md |
| GET | /api/workflow/tasks/{taskId}/field-permissions | フィールド権限取得 | workflow:task:view | WF | 08-workflow/02-approval-runtime.md |
| GET | /api/workflow/tasks/{taskId}/field-permissions | フィールド権限 | workflow:task:view | WF | 08-workflow/91-api-design.md |
| POST | /api/workflow/tasks/{taskId}/reject | 驳回 | workflow:task:reject | WF | 08-workflow/91-api-design.md |
| POST | /api/workflow/tasks/{taskId}/transfer | 转办 | workflow:task:transfer | WF | 08-workflow/91-api-design.md |
| POST | /api/workflow/tasks/{taskId}/urge | 催办 | workflow:task:urge | WF | 08-workflow/91-api-design.md |
| GET | /api/workflow/timeout-rules | 超時規則一覧 | workflow:timeout:update | WF | 08-workflow/91-api-design.md |
| POST | /api/workflow/timeout-rules | 超時規則登録 | workflow:timeout:update | WF | 08-workflow/91-api-design.md |
| DELETE | /api/workflow/timeout-rules/{id} | 超時規則削除 | workflow:timeout:update | WF | 08-workflow/91-api-design.md |
| PUT | /api/workflow/timeout-rules/{id} | 超時規則更新 | workflow:timeout:update | WF | 08-workflow/91-api-design.md |

## 改訂履歴

| 版数 | 日付 | 変更内容 | 変更者 |
|---|---|---|---|
| v1.0 | 2026-10-20 | 自动生成 | gen_matrix.py |
