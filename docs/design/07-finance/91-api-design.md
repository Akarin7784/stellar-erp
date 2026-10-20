# 财务管理域 API 设计书（財務管理 API 詳細設計書）

| 項目 | 内容 |
|---|---|
| 文書名 | 财务管理域 API 设计书（財務管理 API 詳細設計書） |
| 文書番号 | DSN-FIN-091 |
| 版数 | v1.0 |
| 作成日 | 2026-10-20 |
| 作成者 | finance-designer |
| 承認者 | 未承認（レビュー待ち） |
| 状態 | ドラフト（レビュー中） |
| 関連文書 | [業務域概要](00-overview.md) / [API 共通規格](../00-common/03-common-api-spec.md) / [DB 設計](90-db-design.md) / [メッセージ](93-messages.md) |

---

## 1. 適用範囲・基本方針

| # | 方針 | 内容 |
|---|---|---|
| 1 | パス | `/api/finance/{resource}`（module=`finance`）。全 API は認証必須 |
| 2 | レスポンス | 常に `Result<T>`（`code=0` 成功）。一覧は `PageResult<T>`（`list/total/pageNum/pageSize/pages`） |
| 3 | 数値表現 | ID・金額・数量は**文字列**、日付 `yyyy-MM-dd`、日時 ISO 8601（+08:00）。[03 共通 API 規格](../00-common/03-common-api-spec.md) 第 8 章 |
| 4 | 権限 | `@SaCheckPermission("finance:{resource}:{action}")` + データ権限。権限なしは `403 code=3001` |
| 5 | 楽観排他 | 更新系は `version` 必須。競合は `409 code=4003`（MSG-COM-033） |
| 6 | 冪等 | 登録・状態操作・ジョブ起動は `Idempotency-Key` ヘッダ必須。同一キーは初回結果を返す |
| 7 | 非同期 | 大量処理（月結・成本計算・报表出力・取込）は `202 + jobId`。進捗は `GET /api/finance/jobs/{jobId}` |
| 8 | 内部イベント | E10/E12/E14/E16/E17/E18/E22/E23/E24/E26/E27/E28/E29/E30 は Outbox 経由（API ではない） |
| 9 | エラーコード | FIN 領域は `70000-70999`（[03 共通 API 規格](../00-common/03-common-api-spec.md) 第 6 章）。詳細は第 4 章 |

---

## 2. API 一覧

### 2.1 会计科目・期初（F-FIN-001/002）

| # | メソッド | パス | 権限 | 概要 | 主なエラーコード |
|---|---|---|---|---|---|
| 1 | GET | /api/finance/accounts | finance:account:view | 科目一覧（ツリー/フラット） | 3001 |
| 2 | GET | /api/finance/accounts/{id} | finance:account:view | 科目詳細（補助核算含む） | 4001 |
| 3 | POST | /api/finance/accounts | finance:account:create | 科目登録 | 70004,70007 |
| 4 | PUT | /api/finance/accounts/{id} | finance:account:update | 科目更新（version 必須） | 70005,4003 |
| 5 | DELETE | /api/finance/accounts/{id} | finance:account:update | 科目削除（未使用のみ） | 70006 |
| 6 | PUT | /api/finance/accounts/{id}/aux | finance:account:update | 補助核算設定 | 70005,70007 |
| 7 | GET | /api/finance/opening-balances | finance:opening-balance:import | 期初一覧 | 3001 |
| 8 | POST | /api/finance/opening-balances/import | finance:opening-balance:import | 期初一括取込（dryRun 対応） | 70003,1001 |
| 9 | POST | /api/finance/opening-balances/confirm | finance:opening-balance:import | 期初確定・ロック | 70003,70008 |

### 2.2 記帳凭证・帳簿（F-FIN-003～011）

| # | メソッド | パス | 権限 | 概要 | 主なエラーコード |
|---|---|---|---|---|---|
| 10 | GET | /api/finance/vouchers | finance:voucher:view | 凭证検索（PageResult） | 3001 |
| 11 | GET | /api/finance/vouchers/{id} | finance:voucher:view | 凭证詳細（行・補助核算・附件） | 4001 |
| 12 | POST | /api/finance/vouchers | finance:voucher:create | 凭证登録（手動/テンプレート） | 70001,70009,70012～70019 |
| 13 | PUT | /api/finance/vouchers/{id} | finance:voucher:update | 凭证更新（status=10 のみ） | 70010,4003 |
| 14 | DELETE | /api/finance/vouchers/{id} | finance:voucher:update | 草稿削除（取消） | 70010 |
| 15 | GET | /api/finance/vouchers/next-no | finance:voucher:create | 次の凭证番号プレビュー | 70020 |
| 16 | POST | /api/finance/vouchers/{id}/review | finance:voucher:approve | 审核 | 70010,70011 |
| 17 | POST | /api/finance/vouchers/{id}/unreview | finance:voucher:approve | 取消审核 | 70010 |
| 18 | POST | /api/finance/vouchers/{id}/post | finance:voucher:post | 記帳（过账） | 70010,70011,4002 |
| 19 | POST | /api/finance/vouchers/{id}/unpost | finance:voucher:unpost | 反記帳 | 70016,70017 |
| 20 | POST | /api/finance/vouchers/{id}/reverse | finance:voucher:reverse | 赤伝冲销生成 | 70015,70021 |
| 21 | POST | /api/finance/vouchers/batch-review | finance:voucher:approve | 一括审核 | 70011 |
| 22 | POST | /api/finance/vouchers/batch-post | finance:voucher:post | 一括記帳 | 70010 |
| 23 | POST | /api/finance/vouchers/{id}/print | finance:voucher:print | 凭证 PDF（PRT-FIN-001） | 4001 |
| 24 | GET | /api/finance/voucher-templates | finance:voucher-template:view | 凭证テンプレート一覧 | — |
| 25 | POST | /api/finance/voucher-templates | finance:voucher-template:update | テンプレート登録 | 70100,70105 |
| 26 | PUT | /api/finance/voucher-templates/{id} | finance:voucher-template:update | テンプレート更新 | 70100,70105 |
| 27 | POST | /api/finance/voucher-templates/{id}/preview | finance:voucher-template:view | ドライラン（サンプル payload） | 70105,70106 |
| 28 | GET | /api/finance/ledgers/general | finance:ledger:view | 総勘定元帳 | 3001 |
| 29 | GET | /api/finance/ledgers/detail | finance:ledger:view | 明細帳（補助核算指定可） | 3001 |
| 30 | GET | /api/finance/ledgers/journal | finance:ledger:view | 序時帳 | 3001 |
| 31 | GET | /api/finance/trial-balance | finance:trial-balance:view | 試算平衡表 | 70130 |

### 2.3 应付・三单匹配・付款（F-FIN-012～018）

| # | メソッド | パス | 権限 | 概要 | 主なエラーコード |
|---|---|---|---|---|---|
| 32 | GET | /api/finance/payables | finance:payable:view | 应付一覧 | 3001 |
| 33 | GET | /api/finance/payables/{id} | finance:payable:view | 应付詳細（核销履歴） | 4001 |
| 34 | POST | /api/finance/payables/{id}/confirm | finance:payable:confirm | 应付確認 | 70040,4002 |
| 35 | POST | /api/finance/payables/{id}/cancel | finance:payable:cancel | 应付作废 | 70051 |
| 36 | GET | /api/finance/payables/accruals | finance:payable:view | 暂估残高一覧 | — |
| 37 | POST | /api/finance/payables/accruals/reverse | finance:payable:update | 暂估一括冲回 | 70041 |
| 38 | GET | /api/finance/invoices | finance:invoice:view | 发票一覧（INPUT/OUTPUT） | 3001 |
| 39 | POST | /api/finance/invoices | finance:invoice:create | 進項发票登録 | 70042,70045,70046 |
| 40 | GET | /api/finance/invoices/{id} | finance:invoice:view | 发票詳細 | 4001 |
| 41 | POST | /api/finance/invoices/{id}/match | finance:invoice:match | 三单匹配実行 | 70043,70044 |
| 42 | POST | /api/finance/invoices/{id}/approve | finance:invoice:match | 照合承認→AP 確認・J02/J03 | 70043 |
| 43 | POST | /api/finance/invoices/{id}/reject | finance:invoice:match | 照合拒否 | 4002 |
| 44 | GET | /api/finance/invoices/{id}/match-detail | finance:invoice:view | 三单差異明細 | 4001 |
| 45 | GET | /api/finance/payment-requests | finance:payment-request:view | 付款申請一覧 | 3001 |
| 46 | POST | /api/finance/payment-requests | finance:payment-request:create | 付款申請登録 | 70054 |
| 47 | POST | /api/finance/payment-requests/{id}/submit | finance:payment-request:submit | WF 提出 | 70054,4002 |
| 48 | GET | /api/finance/payments | finance:payment:view | 付款一覧 | 3001 |
| 49 | POST | /api/finance/payments | finance:payment:create | 付款登録（未実行） | 70054 |
| 50 | POST | /api/finance/payments/{id}/execute | finance:payment:execute | 付款実行（J10・核销・E28） | 70055,70058,70059 |
| 51 | POST | /api/finance/payments/{id}/cancel | finance:payment:reverse | 付款作废（銀行退回） | 70051 |
| 52 | POST | /api/finance/write-offs | finance:write-off:create | 核销登録（AR/AP/預収/預払） | 70056,70065,70066 |
| 53 | POST | /api/finance/write-offs/auto | finance:write-off:create | 自動核销（FIFO） | 70056 |
| 54 | POST | /api/finance/write-offs/{id}/reverse | finance:write-off:reverse | 反核销 | 70057,70067 |
| 55 | GET | /api/finance/ap-aging | finance:aging:view | 应付账龄 | — |

### 2.4 应收・收款・账龄（F-FIN-019～022）

| # | メソッド | パス | 権限 | 概要 | 主なエラーコード |
|---|---|---|---|---|---|
| 56 | GET | /api/finance/receivables | finance:receivable:view | 应收一覧 | 3001 |
| 57 | GET | /api/finance/receivables/{id} | finance:receivable:view | 应收詳細 | 4001 |
| 58 | POST | /api/finance/receivables/{id}/confirm | finance:receivable:confirm | 应收確認 | 70060 |
| 59 | POST | /api/finance/receivables/{id}/cancel | finance:receivable:cancel | 应收作废（退货等） | 70069 |
| 60 | POST | /api/finance/receivables/batch-confirm | finance:receivable:confirm | 一括確認 | — |
| 61 | GET | /api/finance/receipts | finance:receipt:view | 收款一覧 | 3001 |
| 62 | POST | /api/finance/receipts | finance:receipt:create | 收款登録 | 70064 |
| 63 | PUT | /api/finance/receipts/{id} | finance:receipt:create | 收款更新（status=10） | 4003 |
| 64 | POST | /api/finance/receipts/{id}/confirm | finance:receipt:confirm | 到账確認（J08/J09・核销・E29） | 70065,70066 |
| 65 | POST | /api/finance/receipts/{id}/cancel | finance:receipt:reverse | 收款作废 | 70069 |
| 66 | GET | /api/finance/ar-aging | finance:aging:view | 应收账龄 | — |
| 67 | GET | /api/finance/customers/{customerId}/credit-usage | finance:receivable:view | 与信使用額（SAL 連携） | — |
| 68 | GET | /api/finance/receivables/customer-statement | finance:receivable:view | 客户对账单データ | — |
| 69 | POST | /api/finance/bad-debts/accrue（P2） | finance:receivable:update | 坏账计提 | 70108 |

### 2.5 出纳・銀行・税務（F-FIN-023～028）

| # | メソッド | パス | 権限 | 概要 | 主なエラーコード |
|---|---|---|---|---|---|
| 70 | GET | /api/finance/cash-journals | finance:cash-journal:view | 現金日記帳 | — |
| 71 | POST | /api/finance/cash-journals | finance:cash-journal:create | 現金収支登録 | 70080 |
| 72 | POST | /api/finance/cash-journals/daily-close | finance:cash-journal:create | 現金日結・盤点 | 70081 |
| 73 | GET | /api/finance/bank-journals | finance:bank-journal:view | 銀行日記帳 | — |
| 74 | GET | /api/finance/bank-accounts | finance:bank-journal:view | 自有銀行口座一覧 | — |
| 75 | POST | /api/finance/bank-statements/import | finance:bank-statement:import | 対账单取込（202 ジョブ可） | 70082 |
| 76 | GET | /api/finance/bank-statements | finance:bank-statement:import | 対账单批次一覧 | — |
| 77 | GET | /api/finance/bank-statements/{id}/lines | finance:bank-recon:execute | 対账单明細 | 4001 |
| 78 | POST | /api/finance/bank-reconciliations/auto-match | finance:bank-recon:execute | 自動マッチ | 70083 |
| 79 | POST | /api/finance/bank-reconciliations/match | finance:bank-recon:execute | 手動マッチ | 4002 |
| 80 | POST | /api/finance/bank-reconciliations/{id}/submit | finance:bank-recon:execute | 调节表作成（待复核） | 70084 |
| 81 | POST | /api/finance/bank-reconciliations/{id}/review | finance:bank-recon:view | 调节表复核 | 70084 |
| 82 | GET | /api/finance/fund-daily | finance:fund-report:view | 資金日報 | — |
| 83 | POST | /api/finance/invoices/{id}/verify | finance:invoice:update | 進項发票認証/勾选 | 70046 |
| 84 | POST | /api/finance/vat-returns/generate | finance:vat-return:generate | 增值税申報補助生成 | 70085 |
| 85 | GET | /api/finance/vat-returns/{id} | finance:vat-return:view | 申報補助明細 | 4001 |
| 86 | POST | /api/finance/vat-returns/{id}/confirm | finance:vat-return:generate | 申報補助確認 | 70085,70086 |
| 87 | POST | /api/finance/vat-returns/{id}/export | finance:vat-return:export | 申報データ出力（202） | 70086 |
| 88 | POST | /api/finance/tax-accruals | finance:tax-accrual:generate | 附加税/所得税計提 | 70089,70108 |
| 89 | GET | /api/finance/tax-accruals | finance:tax-accrual:view | 計提一覧 | — |

### 2.6 自動凭证・成本（F-FIN-029～034）

| # | メソッド | パス | 権限 | 概要 | 主なエラーコード |
|---|---|---|---|---|---|
| 90 | GET | /api/finance/auto-voucher-templates | finance:auto-voucher:view | 自動凭证テンプレート一覧（`voucher-templates?templateType=1` と同義） | — |
| 91 | GET | /api/finance/auto-vouchers | finance:auto-voucher:view | 自動凭证ログ | — |
| 92 | POST | /api/finance/auto-vouchers/{id}/retry | finance:auto-voucher:retry | 手動リトライ | 70102,70104 |
| 93 | POST | /api/finance/auto-vouchers/replay | finance:auto-voucher:retry | イベント再処理 | 70108 |
| 94 | GET | /api/finance/costs/precheck | finance:cost:view | 成本計算前チェック | 70116 |
| 95 | POST | /api/finance/costs/calculate | finance:cost:calculate | 成本計算起動（202） | 70112,70116 |
| 96 | GET | /api/finance/costs/results | finance:cost:view | 成本計算結果 | — |
| 97 | POST | /api/finance/costs/{jobId}/confirm | finance:cost:confirm | 成本確定（J16） | 70113,70114,70115 |
| 98 | GET | /api/finance/costs/allocations | finance:cost:view | 製造費用分配一覧 | — |
| 99 | POST | /api/finance/costs/allocations | finance:cost:calculate | 製造費用分配実行 | 70114 |
| 100 | GET | /api/finance/costs/wip | finance:cost:view | 在制品一覧 | — |
| 101 | GET | /api/finance/costs/variance | finance:cost:view | 成本差異分析 | — |
| 126 | GET | /api/finance/standard-costs | finance:standard-cost:view | 標準原価版一覧（`materialId,status,period`） | — |
| 127 | GET | /api/finance/standard-costs/{id} | finance:standard-cost:view | 標準原価版詳細 | 4001 |
| 128 | POST | /api/finance/standard-costs | finance:standard-cost:register | 草稿登録（`status=10`） | 70136 |
| 129 | PUT | /api/finance/standard-costs/{id} | finance:standard-cost:register | 草稿更新（`version` 楽観ロック） | 70135,70136 |
| 130 | POST | /api/finance/standard-costs/{id}/publish | finance:standard-cost:publish | 発行（`fin_publish_standard_cost` 呼出、`mdm_material` 行ロックで同一物料を直列化、旧版自動打切り。`23P01` も 70134 に変換） | 70134,70135 |

### 2.7 期末・報表（F-FIN-035～039）

| # | メソッド | パス | 権限 | 概要 | 主なエラーコード |
|---|---|---|---|---|---|
| 102 | GET | /api/finance/periods | finance:period:view | 期間一覧 | — |
| 103 | POST | /api/finance/periods/{code}/open | finance:period:close | 期間開帳 | 70121 |
| 104 | POST | /api/finance/periods/{code}/close-checks | finance:period:close | 月結チェック実行 | 70120 |
| 105 | POST | /api/finance/periods/{code}/close-checks/waive | finance:period:close | NG 項目免除 | 70122 |
| 106 | GET | /api/finance/periods/{code}/profit-transfer/preview | finance:period:close | 損益転記プレビュー | 70126 |
| 107 | POST | /api/finance/periods/{code}/profit-transfer | finance:period:close | 損益転記実行（J28/J29） | 70126,70127 |
| 108 | POST | /api/finance/periods/{code}/close | finance:period:close | 期間閉鎖（E30 発行） | 70122 |
| 109 | POST | /api/finance/periods/{code}/reopen | finance:period:reopen | 期間再開（財務総監） | 70124 |
| 110 | POST | /api/finance/year-close | finance:year-close:execute | 年結実行（J30） | 70125 |
| 111 | GET | /api/finance/statements/{type} | finance:statement:view | BS/IS/CF/**SCE（所有者权益变动表）** 取得 | 70128,70132 |
| 112 | POST | /api/finance/statements/{type}/snapshots | finance:statement:view | 报表快照保存 | 70128 |
| 113 | POST | /api/finance/statements/{type}/export | finance:statement:export | 报表出力（PDF/Excel） | 70129 |
| 114 | GET | /api/finance/statement-formulas | finance:statement:view | 取数公式一覧 | — |
| 115 | GET | /api/finance/jobs/{jobId} | （各機能権限） | 非同期ジョブ状態 | 4001 |

### 2.8 実装順 P2 APIs（概要）

| # | メソッド | パス | 権限 | 概要 |
|---|---|---|---|---|
| 116 | GET/POST | /api/finance/expense-claims | finance:expense:view/create | 費用精算 |
| 117 | POST | /api/finance/expense-claims/{id}/approve | finance:expense:approve | 精算承認 |
| 118 | GET/POST | /api/finance/assets | finance:asset:view/update | 固定資産カード |
| 119 | POST | /api/finance/assets/depreciation/run | finance:asset:update | 減価償却実行 |
| 120 | POST | /api/finance/assets/{id}/dispose | finance:asset:dispose | 資産処分 |
| 121 | GET/POST | /api/finance/budgets | finance:budget:view/update | 予算 |
| 122 | GET | /api/finance/budgets/execution | finance:budget:view | 予算執行 |
| 123 | POST | /api/finance/exchange-revaluations | finance:voucher:create | 為替調整 |
| 124 | GET/POST | /api/finance/cash-plans | finance:fund-report:view | 資金計画 |
| 125 | GET | /api/finance/cash-plans/shortage | finance:fund-report:view | 資金不足警告 |

> 合計 **130 API**（P2 含む）。各 API の詳細節は本設計の第 5 章に主要 12 件を記載し、残りは「一覧＋共通仕様」で実装可能な粒度とする（リクエスト項目は DB 項目定義と 1:1 対応）。

---

## 3. 共通 DTO

### 3.1 要求 DTO（抜粋）

| DTO | 主な項目 |
|---|---|
| `VoucherCreateRequest` | `voucherType, periodCode, voucherDate, attachmentCount, remark, lines[{lineNo, summary, accountCode, debitAmount, creditAmount, customerId?, supplierId?, departmentId?, employeeId?, projectId?, materialId?, quantity?, unitPrice?, currencyCode?, cashFlowItemCode?, taxCode?}]`, `idempotencyKey`（ヘッダ） |
| `VoucherUpdateRequest` | 同上 + `version` |
| `ReceivableConfirmRequest` | `version` |
| `ReceiptCreateRequest` | `customerId, receiptDate, method, bankAccountId?, amount, payerName, bankRefNo?, attachmentCount?` |
| `WriteOffCreateRequest` | `writeOffType, sourceType, sourceId, writeOffDate, lines[{targetType,targetId,targetNo?,invoiceId?,matchedAmount}]` |
| `InvoiceCreateRequest` | `invoiceType, invoiceCode?, invoiceNo, invoiceKind, invoiceDate, sellerId?, sellerName?, sellerTaxNo?, buyerId?, buyerName?, buyerTaxNo?, taxCode, taxRate, amount, taxAmount, totalAmount, lines[]` |
| `PaymentRequestCreate` | `supplierId, requestDate, plannedPayDate, reason, lines[{payableId?, prepayFlag, requestedAmount}]` |
| `PaymentExecuteRequest` | `version, bankAccountId, method, bankRemark?, idempotencyKey` |
| `PeriodCloseRequest` | `version, closeDate` |
| `VatReturnGenerateRequest` | `periodCode` |
| `CostCalculateRequest` | `periodCode, costMethod, productIds?, workOrderIds?` |

### 3.2 応答 DTO（抜粋）

| DTO | 主な項目 |
|---|---|
| `VoucherDetailDto` | `id, voucherNo, voucherType, periodCode, voucherDate, status, statusName, totalDebit, totalCredit, attachmentCount, isAuto, isRed, sourceType, sourceNo, version, lines[]` |
| `ReceivableDto` | `id, receivableNo, customerId, customerName, receivableDate, dueDate, amount, taxAmount, totalAmount, receivedAmount, balanceAmount, invoiceStatus, status, version` |
| `PayableDto` | `id, payableNo, supplierId, supplierName, payableDate, dueDate, amount, taxAmount, totalAmount, paidAmount, balanceAmount, accrualFlag, status, version` |
| `InvoiceDto` | `id, invoiceType, invoiceCode, invoiceNo, invoiceKind, invoiceDate, sellerName, buyerName, taxCode, taxRate, amount, taxAmount, totalAmount, verifyStatus, matchStatus, status` |
| `AgingDto` | `asOfDate, customerId/supplierId, buckets[{bucket, amount}], total` |
| `TrialBalanceDto` | `periodCode, rows[{accountCode, accountName, openingDebit, openingCredit, debitAmount, creditAmount, closingDebit, closingCredit}], debitTotal, creditTotal, balanced` |
| `StatementDto` | `statementType, periodCode, status, rows[{lineNo, itemName, closingAmount, openingAmount, compareAmount?}], balanced, difference` |
| `PeriodDto` | `periodCode, fiscalYear, status, startDate, endDate, closeDate, closedAt, closedBy` |

### 3.3 エラーコード ↔ メッセージ対応

| code | HTTP | メッセージ ID | 内容 |
|---|---|---|---|
| 70001 | 422 | MSG-FIN-001 | 借贷不平衡 |
| 70003 | 422 | MSG-FIN-003 | 期初借贷不平衡 |
| 70004 | 409 | MSG-FIN-004 | 科目コード重複 |
| 70005 | 422 | MSG-FIN-005 | 使用中科目の停用/方向変更 |
| 70006 | 422 | MSG-FIN-006 | 使用中科目の削除 |
| 70007 | 422 | MSG-FIN-007 | 科目階層不正 |
| 70008 | 422 | MSG-FIN-008 | 統制科目不一致（警告は 200 + warning） |
| 70009 | 422 | MSG-FIN-009 | 補助核算必須/未綁定 |
| 70010 | 409 | MSG-FIN-013 | 凭证状態不整合 |
| 70011 | 422 | MSG-FIN-011/012 | SoD 違反 |
| 70012 | 422 | MSG-FIN-016 | 摘要不正 |
| 70013 | 422 | MSG-FIN-017 | 行金額不正 |
| 70014 | 422 | MSG-FIN-018 | 行数不足 |
| 70015 | 422 | MSG-FIN-019 | 赤伝対象外 |
| 70016 | 422 | MSG-FIN-020 | 反記帳期間外 |
| 70017 | 422 | MSG-FIN-021 | 反記帳理由なし |
| 70018 | 422 | MSG-FIN-026 | 数量核算不正 |
| 70019 | 422 | MSG-FIN-027 | CF 項目必須 |
| 70020 | 422 | MSG-FIN-029 | 凭证番号枯渇 |
| 70021 | 422 | MSG-FIN-033 | 冲销済 |
| 70022 | 422 | MSG-FIN-034 | 凭证字/期間不一致 |
| 70040 | 422 | MSG-FIN-040 | 应付二重確認 |
| 70041 | 422 | MSG-FIN-041 | 暂估未冲回 |
| 70042 | 409 | MSG-FIN-042 | 发票重複 |
| 70043 | 422 | MSG-FIN-043 | 三単差異容差超 |
| 70044 | 422 | MSG-FIN-044 | 発票数量超過 |
| 70045 | 422 | MSG-FIN-045 | 発票金額不整合 |
| 70046 | 422 | MSG-FIN-046 | 税码不正（税種不一致） |
| 70051 | 422 | MSG-FIN-051 | 核销済作废不可 |
| 70054 | 422 | MSG-FIN-054 | 付款申請超過 |
| 70055 | 422 | MSG-FIN-055 | 付款超過 |
| 70056 | 422 | MSG-FIN-056 | 核销超過 |
| 70057 | 422 | MSG-FIN-057 | 反核销不可 |
| 70058 | 502/503 | MSG-FIN-058 | 銀企送信失敗 |
| 70059 | 200(W) | MSG-FIN-059 | 残高不足警告 |
| 70060 | 422 | MSG-FIN-060 | 应收二重確認 |
| 70062 | 422 | MSG-FIN-062 | E10 金額不整合 |
| 70064 | 409 | MSG-FIN-064 | 銀行流水重複 |
| 70065 | 422 | MSG-FIN-065 | 应收核销超過 |
| 70066 | 422 | MSG-FIN-066 | 收款核销超過 |
| 70067 | 422 | MSG-FIN-067 | 反核销不可 |
| 70068 | 422 | MSG-FIN-068 | 開票超過 |
| 70069 | 422 | MSG-FIN-069 | 收款核销済作废不可 |
| 70080 | 422 | MSG-FIN-080 | 現金日記帳金額不正 |
| 70081 | 422 | MSG-FIN-081 | 現金盤点差異理由なし |
| 70082 | 409 | MSG-FIN-082 | 対账单重複 |
| 70083 | 422 | MSG-FIN-083 | 銀行口座不備 |
| 70084 | 422 | MSG-FIN-084 | 調節表不一致 |
| 70085 | 200(W) | MSG-FIN-085 | 申報表と総帳差異（警告） |
| 70086 | 409 | MSG-FIN-086 | 申報確認済再生成不可 |
| 70089 | 409 | MSG-FIN-089 | 計提重複 |
| 70100 | 409 | MSG-FIN-100 | テンプレート重複 |
| 70102 | 422 | MSG-FIN-102 | 自動凭证生成失敗 |
| 70104 | 422 | MSG-FIN-104 | テンプレート無 |
| 70105 | 422 | MSG-FIN-105 | テンプレート貸借不一致 |
| 70106 | 422 | MSG-FIN-106 | 税種マップ無 |
| 70108 | 4002 | MSG-FIN-108 | 期間 CLOSED（業務保留） |
| 70112 | 200(W) | MSG-FIN-112 | 成本異常対象（警告） |
| 70113 | 422 | MSG-FIN-113 | 生産成本と WIP 不一致 |
| 70114 | 422 | MSG-FIN-114 | 製造費用残高 |
| 70115 | 409 | MSG-FIN-115 | 成本確定済 |
| 70116 | 422 | MSG-FIN-116 | 在庫月結未了 |
| 70120 | 422 | MSG-FIN-120 | 未記帳凭证あり |
| 70121 | 200 | MSG-FIN-121 | 期間開帳成功 |
| 70122 | 422 | MSG-FIN-122 | 月結チェック NG |
| 70123 | 200 | MSG-FIN-123 | 月結成功 |
| 70124 | 422 | MSG-FIN-124 | 期間再開 |
| 70125 | 422 | MSG-FIN-125 | 年結不可 |
| 70126 | 422 | MSG-FIN-126 | 損益転記残高 |
| 70127 | 409 | MSG-FIN-127 | 損益転記二重 |
| 70128 | 422 | MSG-FIN-128 | BS 不一致 |
| 70129 | 422 | MSG-FIN-129 | 未結帳出力不可 |
| 70130 | 422 | MSG-FIN-130 | 科目余額不平衡 |
| 70132 | 200(W) | MSG-FIN-132 | CF 不一致（警告） |
| 70133 | 200 | MSG-FIN-133 | 年結成功 |
| 70134 | 422 | MSG-FIN-134 | 標準原価発行期間不正 |
| 70135 | 409 | MSG-FIN-135 | 標準原価版が草稿でない |
| 70136 | 409 | MSG-FIN-136 | 標準原価版本重複 |

---

## 4. 主要 API 詳細

### 4.1 POST /api/finance/vouchers（凭证登録）

- **目的**：手動/テンプレートによる記帳凭证の登録（10 草稿）
- **権限**：`finance:voucher:create`
- **処理概要**：入力チェック → 期間 OPEN 確認 → 採番 → 貸借平衡 → `fin_voucher`/`fin_voucher_line` INSERT → 監査ログ
- **冪等**：`Idempotency-Key` 必須
- **関連テーブル**：`fin_voucher`, `fin_voucher_line`, `sys_sequence`

リクエスト例（J07 銷售、税率 13%、【示例値】）は [02-voucher-ledger.md](02-voucher-ledger.md) 7.1 を参照。レスポンス：

```json
{ "code": 0, "message": "ok", "data": { "id": "1845678901234567001", "voucherNo": "记-0042", "status": 10, "totalDebit": "116141.40", "totalCredit": "116141.40", "version": 0 } }
```

エラー例：

```json
{ "code": 70001, "message": "借方合计与贷方合计不一致（差额 0.01），无法保存。", "data": { "difference": "0.01" } }
```

### 4.2 POST /api/finance/vouchers/{id}/post（記帳）

- **権限**：`finance:voucher:post`、`finance:voucher:unpost`
- **処理概要**：status=20 確認 → SoD → 余额 UPSERT（行ロック）→ status=40 → 監査ログ
- **エラー**：70011（SoD）、70010（状態）、4002（期間 CLOSED は 70108）

```json
{ "version": 1 }
```

```json
{ "code": 0, "message": "ok", "data": { "id": "1845678901234567001", "voucherNo": "记-0042", "status": 40, "postedAt": "2026-10-20T15:10:00+08:00", "version": 2 } }
```

### 4.3 POST /api/finance/vouchers/{id}/reverse（赤伝冲销）

```json
{ "reason": "销售数量录错，按红字冲销后重新开票" }
```

```json
{ "code": 0, "message": "ok", "data": { "reversalVoucherId": "1845678901234567050", "voucherNo": "记-0152", "reversalOfVoucherNo": "记-0042" } }
```

### 4.4 POST /api/finance/invoices/{id}/approve（三单匹配承認→AP 確認）

```json
{ "version": 1, "diffHandleType": 1, "comment": "单价上调 0.05 元，差异 250 元计入库存成本" }
```

```json
{ "code": 0, "message": "ok", "data": { "payableId": "1845678901234569100", "payableNo": "AP2610200001", "voucherIds": ["1845678901234569201", "1845678901234569202"], "diffAmount": "250.00" } }
```

### 4.5 POST /api/finance/payments/{id}/execute（付款実行）

```json
{ "version": 1, "bankAccountId": "1845000000000000201", "method": "BANK_TRANSFER", "idempotencyKey": "7f1c2f0e-6a3d-4b7e-9a1c-2d4e6f8a0b1c", "bankRemark": "支付 10 月硅钢片货款" }
```

```json
{ "code": 0, "message": "ok", "data": { "paymentId": "1845678901234570011", "paymentNo": "PMT2610200001", "voucherId": "1845678901234567101", "voucherNo": "付-0018", "bankJournalId": "1845678901234570101", "status": 40 } }
```

### 4.6 POST /api/finance/receipts/{id}/confirm（收款確認）

```json
{ "version": 0, "writeOff": { "mode": "AUTO_FIFO", "lines": [] } }
```

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "receiptId": "1845678901234580001", "receiptNo": "RCP2610280001",
    "voucherIds": ["1845678901234580101"], "writeOffId": "1845678901234580201",
    "unappliedAmount": "0.00",
    "matched": [{ "receivableId": "1845678901234578001", "matchedAmount": "116141.40" }]
  }
}
```

### 4.7 POST /api/finance/bank-statements/import（対账单取込）

- multipart/form-data：`file`、`bankAccountId`、`periodCode`、`columnMapping`（JSON）
- 冪等：ファイル SHA256 + 口座 + 期間で重複判定（70082）
- 202 応答（非同期）または 200（同期、5,000 行以下）

```json
{ "code": 0, "message": "ok", "data": { "statementId": "1845678901234588001", "statementNo": "BST2610200001", "lineCount": 45, "duplicateCount": 0, "jobId": null } }
```

### 4.8 POST /api/finance/vat-returns/generate（申報補助生成）

```json
{ "periodCode": "2026-10" }
```

```json
{ "code": 0, "message": "ok", "data": { "id": "1845678901234590001", "periodCode": "2026-10", "outputTax": "8666666.67", "inputTax": "6536666.67", "priorCredit": "120000.00", "payableTax": "2010000.00", "closingCredit": "0.00", "surchargeTotal": "241200.00", "status": 40 } }
```

### 4.9 POST /api/finance/costs/calculate（成本計算）

```json
{ "periodCode": "2026-10", "costMethod": "AUTO", "productIds": [] }
```

```json
{ "code": 0, "message": "ok", "data": { "jobId": "job-20261031-0001", "status": "QUEUED" } }
```

### 4.9a POST /api/finance/standard-costs（標準原価草稿登録）／POST /api/finance/standard-costs/{id}/publish（発行）

期間は API では `YYYY-MM`、DB は月初日 `DATE`（[90 §6.12](90-db-design.md)）。`totalUnitCost` はサーバが 4 要素合計で算出する。

```json
{ "materialId": 30001, "costVersion": "2026A", "periodFrom": "2026-01", "costMethod": 1, "bomId": 50001, "routingId": 60001,
  "baseQty": "1.0000", "stdLaborHours": "2.1500", "stdLaborRate": "25.000000", "stdOverheadRate": "30.000000",
  "materialUnitCost": "659.950000", "laborUnitCost": "53.750000", "overheadUnitCost": "64.500000", "outsourcingUnitCost": "0.000000" }
```

```json
{ "code": 0, "message": "ok", "data": { "id": 91001, "status": 10, "totalUnitCost": "778.200000", "periodFrom": "2026-01", "periodTo": null, "version": 0 } }
```

発行 `POST /api/finance/standard-costs/{id}/publish`（要求 `{ "version": 0 }`）。応答は新版 `status=40`、`publishedAt/By`、および打切りされた旧版 `{ "id", "periodTo" }`。権限は `finance:standard-cost:publish`（財務総監のみ）。成本会計が呼ぶと 403（共通権限エラー）。

### 4.10 GET /api/finance/periods/2026-10/close-checks（月結チェック）

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "periodCode": "2026-10",
    "allPassed": false,
    "checks": [
      { "checkCode": "CLOSE_01", "checkName": "未発行イベント", "result": 1, "ngCount": 0 },
      { "checkCode": "CLOSE_06", "checkName": "在庫取引・未仕訳", "result": 2, "ngCount": 3, "ngAmount": "58200.00" },
      { "checkCode": "CLOSE_14", "checkName": "製造費用期末残高", "result": 1, "ngCount": 0 }
    ]
  }
}
```

### 4.11 POST /api/finance/periods/{code}/close（期間閉鎖）

```json
{ "version": 3, "closeDate": "2026-11-05" }
```

```json
{ "code": 0, "message": "ok", "data": { "periodCode": "2026-10", "status": "CLOSED", "closedAt": "2026-11-05T17:30:00+08:00", "nextPeriod": "2026-11", "checksPassed": 15 } }
```

### 4.12 GET /api/finance/statements/BS（資産負債表）

- **権限**：`finance:statement:view`
- **パラメータ**：`periodCode`（必須）、`compareType`（1 単期/2 前月比/3 前年同期）
- **処理概要**：快照があれば返却、なければ計算（プレビュー）。正式出力は CLOSED のみ

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "statementType": "BS",
    "periodCode": "2026-10",
    "status": "CLOSED",
    "rows": [
      { "lineNo": 1, "itemName": "货币资金", "closingAmount": "24528297.80", "compareAmount": null },
      { "lineNo": 35, "itemName": "资产总计", "closingAmount": "297328297.80", "compareAmount": null },
      { "lineNo": 70, "itemName": "负债和所有者权益总计", "closingAmount": "297328297.80", "compareAmount": null }
    ],
    "balanced": true,
    "difference": "0.00"
  }
}
```

---

## 5. 権限マトリクス（API×ロール）

| リソース | 会計 | 応付会計 | 応収会計 | 成本会計 | 税務会計 | 出納 | 財務経理 | 財務総監 | 監査 |
|---|---|---|---|---|---|---|---|---|---|
| accounts | view | view | view | view | view | — | view/update | view/update | view |
| vouchers | create/view | create/view | create/view | create/view | create/view | — | approve/post/unpost | unpost/reverse | view |
| ledgers/trial-balance | view | view | view | view | view | — | view | view | view |
| payables/invoices | view | create/match | — | — | view | — | approve | view | view |
| payment-requests | — | create/view | — | — | — | view | approve | approve | view |
| payments | — | view | — | — | — | execute | view/cancel | view | view |
| receivables/receipts | view | — | create/confirm | — | — | confirm | approve | view | view |
| cash/bank journals | — | — | — | — | — | create/view | view | view | view |
| bank reconciliation | — | — | — | — | — | execute | review | view | view |
| vat-returns/tax-accruals | — | — | — | — | generate/view | — | confirm | view | view |
| auto-vouchers | view/retry | view | view | view | view | — | update/retry | view | view |
| costs | view | — | — | calculate | — | — | confirm | view | view |
| standard-costs | — | — | — | view/register | — | — | view | view/publish | view |
| periods | — | — | — | — | — | — | close | reopen/year-close | view |
| statements | view | — | — | — | view | — | view/export | view/approve | view |

---

## 6. 非同期ジョブ API

| 操作 | 起動 API | 状態取得 | 結果 |
|---|---|---|---|
| 期初取込（大規模） | POST /api/finance/opening-balances/import | GET /api/finance/jobs/{jobId} | `resultFileId` |
| 対账单取込 | POST /api/finance/bank-statements/import | 同上 | statementId |
| 成本計算 | POST /api/finance/costs/calculate | 同上 | jobId→costs/results |
| 月結（損益転記含む） | POST /api/finance/periods/{code}/profit-transfer | 同上 | voucherIds |
| 年結 | POST /api/finance/year-close | 同上 | nextYearPeriods |
| 报表出力 | POST /api/finance/statements/{type}/export | 同上 | `resultFileId` |
| 申報データ出力 | POST /api/finance/vat-returns/{id}/export | 同上 | `resultFileId` |
| エクスポート（一覧） | POST /api/finance/exports | 同上 | `resultFileId` |

**ジョブ状態レスポンス**

```json
{ "code": 0, "message": "ok", "data": { "jobId": "job-20261031-0001", "status": "RUNNING", "progress": 65, "resultFileId": null, "errorMessage": null, "startedAt": "2026-10-31T20:00:00+08:00" } }
```

- ステータス：`QUEUED / RUNNING / SUCCEEDED / FAILED / CANCELLED`
- 結果ファイルは 7 日保存。権限 + 署名 URL でダウンロード。

---

## 7. セキュリティ・監査

| 項目 | 内容 |
|---|---|
| 認証 | `Authorization: {token}`（Sa-Token、8 時間）。401 は共通ハンドラでログイン画面へ |
| 権限 | 画面表示制御は UX、API 側で必ず再チェック（二重防御）。數據権限は SQL 強制注入 |
| 監査 | 登録/更新/削除/审核/記帳/反記帳/赤伝/出力/取込/月結/年結を `sys_audit_log` に記録（before/after に金額・状態必須） |
| マスキング | 銀行口座は下 4 桁のみ。API レスポンスにも全桁を返さない（`bank_account_no_mask`） |
| 内部 API | 域間は Spring Modulith の公開 Service / イベント。REST を経由しない（同一プロセス） |
| レート制限 | 画面向けは既定なし（認証必須）。エクスポート・ジョブは同時実行数制限（ユーザあたり 3） |
| エラー詳細 | 500 系は `trace_id` のみ返し、スタックトレースはサーバログのみ |

---

## 8. 改訂履歴

| 版数 | 日付 | 変更内容 | 変更者 |
|---|---|---|---|
| v1.0 | 2026-10-20 | 初版：API 125 件（P2 含む）、DTO、エラーコード対応（70001–70133）、主要 12 API の JSON、権限マトリクス、非同期ジョブ | finance-designer |
| v1.1 | 2026-10-20 | 红队修复：唯一シナリオの数値（BS 297,328,297.80、增值税 8,666,666.67/6,536,666.67）へ更新。`statements/{type}` に SCE（所有者权益变动表）を追加 | finance-designer |
| v1.3 | 2026-10-21 | 標準原価 API（#126〜130、§4.9a）、70134〜70136、権限マトリクスに standard-costs | 业务分析 |
| v1.4 | 2026-10-21 | 合計 130 API、#127 の 404 を共通 4001 に修正、#130 の並行発行時 70134 | 业务分析 |
