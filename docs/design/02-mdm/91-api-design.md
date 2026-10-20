# 主数据管理 API 设计书（主数据管理 API 設計書）

| 項目 | 内容 |
|---|---|
| 文書名 | 主数据管理 API 设计书（主数据管理 API 設計書） |
| 文書番号 | DSN-MDM-091 |
| 版数 | v1.0 |
| 作成日 | 2026-10-20 |
| 作成者 | mdm-designer |
| 承認者 | 未承認（レビュー待ち） |
| 状態 | ドラフト（レビュー中） |
| 関連文書 | [業務域概要](00-overview.md) / [API 共通規格](../00-common/03-common-api-spec.md) / [DB 設計](90-db-design.md) / [メッセージ](93-messages.md) |

---

## 1. 適用範囲・基本方針

本 API は MDM 域の画面操作と他域からの同期参照に使用する。共通仕様（`Result<T>`、認証、権限、ページング、冪等、楽観排他、エラーコード体系）は [03 API 共通規格](../00-common/03-common-api-spec.md) を正とし、本節では MDM 固有の事項のみ定義する。

| # | 方針 |
|---|---|
| 1 | パス：`/api/mdm/{resource}`（複数形・kebab-case）。状態操作は `/{id}/{action}`、一括は `/batch-{action}` |
| 2 | 全 API に `@SaCheckPermission("mdm:{resource}:{action}")`。データ権限は SQL に強制注入 |
| 3 | ID・金額・数量は文字列で返す。日付 `yyyy-MM-dd`、日時 ISO 8601（+08:00） |
| 4 | 更新系は `version` 必須（新規作成・参照・取込を除く）。競合は `409 code=4003` |
| 5 | 登録・状態操作は `Idempotency-Key` 必須（[03 §9](../00-common/03-common-api-spec.md)）。取込・エクスポートは非同期ジョブ |
| 6 | 他域向けの参照 API は読み取り専用で、内部 REST として公開する（Spring Modulith の公開インタフェース） |
| 7 | マスタ参照 API はキャッシュ TTL ≤ 5 分を許容。取得結果に `version` と `updatedAt` を含める |
| 8 | 削除は論理削除（マスタのみ）。使用中マスタは `MSG-MDM-029`/`MSG-MDM-062` 等で拒否 |

## 2. API 一覧

### 2.1 物料・分類・工厂視図

| # | メソッド | パス | 権限 | 概要 | 主なエラー | 機能 |
|---|---|---|---|---|---|---|
| 1 | GET | `/api/mdm/materials` | `mdm:material:view` | 物料一覧 | 3001/1001 | F-MDM-002 |
| 2 | GET | `/api/mdm/materials/{id}` | `mdm:material:view` | 物料詳細（多視図） | 4001 | F-MDM-002 |
| 3 | GET | `/api/mdm/materials/by-code/{code}` | `mdm:material:view` | コード参照 | 4001 | F-MDM-002 |
| 4 | POST | `/api/mdm/materials` | `mdm:material:create` | 物料登録 | 1005/20010/20012 | F-MDM-002 |
| 5 | PUT | `/api/mdm/materials/{id}` | `mdm:material:update` | 物料更新 | 4003/20011 | F-MDM-002 |
| 6 | POST | `/api/mdm/materials/{id}/submit` | `mdm:material:update` | 承認提出 | 4002 | F-MDM-018 |
| 7 | POST | `/api/mdm/materials/{id}/deactivate` | `mdm:material:delete` | 使用停止申請 | 20018 | F-MDM-002 |
| 8 | POST | `/api/mdm/materials/{id}/reactivate` | `mdm:material:update` | 使用再開申請 | 4002 | F-MDM-002 |
| 9 | GET | `/api/mdm/materials/{id}/factories` | `mdm:material:view` | 工厂視図一覧 | — | F-MDM-021 |
| 10 | PUT | `/api/mdm/materials/{id}/factories/{factoryId}` | `mdm:material-factory:update` | 工厂視図更新 | 4003 | F-MDM-021 |
| 11 | GET | `/api/mdm/materials/{id}/history` | `mdm:change:view` | 変更履歴 | — | F-MDM-018 |
| 12 | POST | `/api/mdm/materials/batch-get` | `mdm:material:view` | 一括参照（≤500） | 1001 | F-MDM-002 |
| 13 | GET | `/api/mdm/material-categories/tree` | `mdm:material:view` | 分類樹 | — | F-MDM-001 |
| 14 | GET | `/api/mdm/material-categories` | `mdm:material:view` | 分類一覧 | — | F-MDM-001 |
| 15 | POST/PUT/DELETE | `/api/mdm/material-categories[/{id}]` | `mdm:material-category:update` | 分類 CRUD | 4001/20012 | F-MDM-001 |
| 16 | GET | `/api/mdm/code-rules` | `mdm:code-rule:update` | 编码規則一覧 | — | F-MDM-003 |
| 17 | PUT | `/api/mdm/code-rules/{id}` | `mdm:code-rule:update` | 编码規則更新 | 4003 | F-MDM-003 |
| 18 | GET | `/api/mdm/materials/{id}/substitutes` | `mdm:substitute:view` | 替代一覧（片方向） | — | F-MDM-016 |

### 2.2 客户・供应商

| # | メソッド | パス | 権限 | 概要 | 主なエラー | 機能 |
|---|---|---|---|---|---|---|
| 19 | GET | `/api/mdm/customers` | `mdm:customer:view` | 客户一覧 | — | F-MDM-004 |
| 20 | GET | `/api/mdm/customers/{id}` | `mdm:customer:view` | 客户詳細 | 4001 | F-MDM-004 |
| 21 | POST | `/api/mdm/customers` | `mdm:customer:create` | 客户登録 | 20020/1005 | F-MDM-004 |
| 22 | PUT | `/api/mdm/customers/{id}` | `mdm:customer:update` | 客户更新 | 4003/20020 | F-MDM-004 |
| 23 | DELETE | `/api/mdm/customers/{id}` | `mdm:customer:delete` | 使用停止申請 | 20018 | F-MDM-004 |
| 24 | POST | `/api/mdm/customers/{id}/submit` | `mdm:customer:update` | 承認提出 | 4002 | F-MDM-004 |
| 25 | GET | `/api/mdm/customers/check-tax-no` | `mdm:customer:view` | 税号重複チェック | — | F-MDM-004 |
| 26 | GET | `/api/mdm/customers/{id}/credit-limit` | `mdm:customer:credit:view` | 与信照会（SAL/FIN 共用） | 20043 | F-MDM-014 |
| 27 | GET | `/api/mdm/customers/{id}/contacts` | `mdm:customer:view` | 連絡先一覧 | — | F-MDM-004 |
| 28 | GET | `/api/mdm/customers/{id}/addresses` | `mdm:customer:view` | 住所一覧 | — | F-MDM-004 |
| 29 | POST/PUT/DELETE | `/api/mdm/customers/{id}/contacts[/{contactId}]` | `mdm:customer:update` | 連絡先 CRUD | 4001 | F-MDM-004 |
| 30 | POST/PUT/DELETE | `/api/mdm/customers/{id}/addresses[/{addressId}]` | `mdm:customer:update` | 住所 CRUD | 4001 | F-MDM-004 |
| 31 | GET | `/api/mdm/suppliers` | `mdm:supplier:view` | 供应商一覧 | — | F-MDM-005 |
| 32 | GET | `/api/mdm/suppliers/{id}` | `mdm:supplier:view` | 供应商詳細 | 4001 | F-MDM-005 |
| 33 | POST | `/api/mdm/suppliers` | `mdm:supplier:create` | 供应商登録 | 20020/1005 | F-MDM-005 |
| 34 | PUT | `/api/mdm/suppliers/{id}` | `mdm:supplier:update` | 供应商更新 | 4003 | F-MDM-005 |
| 35 | DELETE | `/api/mdm/suppliers/{id}` | `mdm:supplier:delete` | 使用停止申請 | 20018 | F-MDM-005 |
| 36 | POST | `/api/mdm/suppliers/{id}/submit` | `mdm:supplier:update` | 承認提出 | 4002 | F-MDM-005 |
| 37 | GET | `/api/mdm/suppliers/{id}/materials` | `mdm:supplier:view` | 供給範囲 | — | F-MDM-005 |
| 38 | POST/PUT/DELETE | `/api/mdm/suppliers/{id}/materials[/{rowId}]` | `mdm:supplier:update` | 供給範囲 CRUD | 20025 | F-MDM-005 |
| 39 | GET | `/api/mdm/suppliers/{id}/qualifications` | `mdm:supplier:view` | 資格一覧 | — | F-MDM-005 |
| 40 | POST/PUT/DELETE | `/api/mdm/suppliers/{id}/qualifications[/{qid}]` | `mdm:supplier:update` | 資格 CRUD | 4001 | F-MDM-005 |
| 41 | POST | `/api/mdm/suppliers/{id}/admission-requests` | `mdm:supplier:update` | 准入申請 | 20024 | F-MDM-015 |
| 42 | POST | `/api/mdm/suppliers/{id}/admission-approve` | `mdm:supplier-admission:approve` | 准入承認 | 20024/4002 | F-MDM-015 |
| 43 | POST | `/api/mdm/suppliers/{id}/suspend` | `mdm:supplier-admission:approve` | 暂停 | 4002 | F-MDM-015 |
| 44 | GET | `/api/mdm/suppliers/{id}/evaluations` | `mdm:supplier-eval:view` | 評価履歴 | — | F-MDM-015 |

### 2.3 倉庫・単位・通貨・税

| # | メソッド | パス | 権限 | 概要 | 主なエラー | 機能 |
|---|---|---|---|---|---|---|
| 45 | GET | `/api/mdm/warehouses` | `mdm:warehouse:view` | 倉庫一覧 | — | F-MDM-006 |
| 46 | GET | `/api/mdm/warehouses/{id}` | `mdm:warehouse:view` | 倉庫詳細 | 4001 | F-MDM-006 |
| 47 | POST/PUT | `/api/mdm/warehouses[/{id}]` | `mdm:warehouse:update` | 倉庫 CRUD | 20026 | F-MDM-006 |
| 48 | POST | `/api/mdm/warehouses/{id}/deactivate` | `mdm:warehouse:update` | 使用停止申請 | 20028 | F-MDM-006 |
| 49 | GET/POST/PUT | `/api/mdm/warehouse-zones[/{id}]` | `mdm:warehouse:update` | 庫区 CRUD | 20026 | F-MDM-006 |
| 50 | GET | `/api/mdm/warehouse-bins` | `mdm:warehouse:view` | 庫位一覧 | — | F-MDM-006 |
| 51 | GET | `/api/mdm/warehouse-bins/{id}` | `mdm:warehouse:view` | 庫位詳細 | 4001 | F-MDM-006 |
| 52 | POST/PUT | `/api/mdm/warehouse-bins[/{id}]` | `mdm:warehouse:update` | 庫位 CRUD | 20027 | F-MDM-006 |
| 53 | POST | `/api/mdm/warehouse-bins/batch-generate` | `mdm:warehouse:update` | 一括生成 | 20027/20055 | F-MDM-006 |
| 54 | POST | `/api/mdm/warehouse-bins/labels` | `mdm:warehouse:print` | 库位ラベル PDF | 20052 | F-MDM-017 |
| 55 | GET | `/api/mdm/warehouses/options` | `mdm:warehouse:view` | 選択用一覧 | — | F-MDM-006 |
| 56 | GET | `/api/mdm/uoms` | `mdm:uom:view` | 単位一覧 | — | F-MDM-007 |
| 57 | GET | `/api/mdm/uoms/{code}` | `mdm:uom:view` | 単位照会 | 4001 | F-MDM-007 |
| 58 | POST/PUT | `/api/mdm/uoms[/{id}]` | `mdm:uom:update` | 単位 CRUD | 20029/20030 | F-MDM-007 |
| 59 | GET | `/api/mdm/uom-conversions` | `mdm:uom:view` | 換算一覧 | — | F-MDM-007 |
| 60 | POST/PUT | `/api/mdm/uom-conversions[/{id}]` | `mdm:uom:update` | 換算 CRUD | 20031 | F-MDM-007 |
| 61 | POST | `/api/mdm/uoms/convert` | `mdm:uom:view` | 数量換算 | 20031 | F-MDM-007 |
| 62 | GET | `/api/mdm/currencies` | `mdm:currency:view` | 通貨一覧 | — | F-MDM-008 |
| 63 | GET | `/api/mdm/currencies/{code}` | `mdm:currency:view` | 通貨照会 | 4001 | F-MDM-008 |
| 64 | POST/PUT | `/api/mdm/currencies[/{id}]` | `mdm:currency:update` | 通貨 CRUD | 20032 | F-MDM-008 |
| 65 | GET | `/api/mdm/exchange-rates` | `mdm:exchange-rate:view` | レート一覧 | — | F-MDM-008 |
| 66 | GET | `/api/mdm/exchange-rates/effective` | `mdm:exchange-rate:view` | 有効レート | 20033 | F-MDM-008 |
| 67 | POST/PUT | `/api/mdm/exchange-rates[/{id}]` | `mdm:exchange-rate:update` | レート CRUD | 20033 | F-MDM-008 |
| 68 | GET | `/api/mdm/tax-codes` | `mdm:tax-code:view` | 税码一覧 | — | F-MDM-009 |
| 69 | GET | `/api/mdm/tax-codes/{code}` | `mdm:tax-code:view` | 税码照会 | 4001 | F-MDM-009 |
| 70 | POST/PUT | `/api/mdm/tax-codes[/{id}]` | `mdm:tax-code:update` | 税码 CRUD | 20034/20035 | F-MDM-009 |
| 71 | GET | `/api/mdm/tax-codes/{id}/rates` | `mdm:tax-code:view` | 税率履歴 | — | F-MDM-009 |
| 72 | GET | `/api/mdm/tax-classifications` | `mdm:tax-code:view` | 税收分類一覧 | — | F-MDM-009 |

### 2.4 価格・結算・銀行

| # | メソッド | パス | 権限 | 概要 | 主なエラー | 機能 |
|---|---|---|---|---|---|---|
| 73 | GET | `/api/mdm/price-lists` | `mdm:price:view` | 価格表一覧 | — | F-MDM-010 |
| 74 | GET | `/api/mdm/price-lists/{id}` | `mdm:price:view` | 価格表詳細 | 4001 | F-MDM-010 |
| 75 | POST | `/api/mdm/price-lists` | `mdm:price:update` | 価格表登録 | 20037/20038 | F-MDM-010 |
| 76 | PUT | `/api/mdm/price-lists/{id}` | `mdm:price:update` | 価格表更新 | 4003/20039 | F-MDM-010 |
| 77 | POST | `/api/mdm/price-lists/{id}/submit` | `mdm:price:update` | 承認提出 | 4002 | F-MDM-010 |
| 78 | POST | `/api/mdm/price-lists/{id}/activate` | `mdm:change:approve` | 有効化（E04） | 4002 | F-MDM-010 |
| 79 | GET | `/api/mdm/prices/sales/effective` | `mdm:price:view` | 销售取价 | 20036 | F-MDM-010 |
| 80 | POST | `/api/mdm/prices/sales/effective-batch` | `mdm:price:view` | 销售取价（一括） | 20036/1001 | F-MDM-010 |
| 81 | POST | `/api/mdm/prices/sales/simulate` | `mdm:price:view` | 取价シミュレーション | 20036 | F-MDM-010 |
| 82 | GET | `/api/mdm/price-discounts` | `mdm:price:view` | 折扣規則一覧 | — | F-MDM-010 |
| 83 | POST/PUT | `/api/mdm/price-discounts[/{id}]` | `mdm:price:update` | 折扣 CRUD | 20040 | F-MDM-010 |
| 84 | GET | `/api/mdm/prices/purchase/effective` | `mdm:purchase-price:view` | 購買取价 | 20036 | F-MDM-011 |
| 85 | GET | `/api/mdm/purchase-prices` | `mdm:purchase-price:view` | 購買価格一覧 | — | F-MDM-011 |
| 86 | POST/PUT | `/api/mdm/purchase-prices[/{id}]` | `mdm:purchase-price:update` | 購買価格 CRUD | 4003 | F-MDM-011 |
| 87 | GET | `/api/mdm/supplier-quotations` | `mdm:supplier-quotation:view` | 報価一覧 | — | F-MDM-011 |
| 88 | POST/PUT | `/api/mdm/supplier-quotations[/{id}]` | `mdm:supplier-quotation:update` | 報価 CRUD | 4003 | F-MDM-011 |
| 89 | POST | `/api/mdm/supplier-quotations/{id}/adopt` | `mdm:purchase-price:update` | 報価採用 | 4002 | F-MDM-011 |
| 90 | GET | `/api/mdm/settlement-methods` | `mdm:settlement:view` | 結算方式一覧 | — | F-MDM-012 |
| 91 | POST/PUT | `/api/mdm/settlement-methods[/{id}]` | `mdm:settlement:update` | 結算方式 CRUD | 4003 | F-MDM-012 |
| 92 | GET | `/api/mdm/payment-terms` | `mdm:payment-term:view` | 付款条件一覧 | — | F-MDM-012 |
| 93 | GET | `/api/mdm/payment-terms/{code}` | `mdm:payment-term:view` | 付款条件照会 | 4001 | F-MDM-012 |
| 94 | POST/PUT | `/api/mdm/payment-terms[/{id}]` | `mdm:payment-term:update` | 付款条件 CRUD | 20041 | F-MDM-012 |
| 95 | POST | `/api/mdm/payment-terms/calc-due-date` | `mdm:payment-term:view` | 支払期日計算 | 4001 | F-MDM-012 |
| 96 | GET | `/api/mdm/banks` | `mdm:bank:view` | 銀行一覧 | — | F-MDM-013 |
| 97 | POST/PUT | `/api/mdm/banks[/{id}]` | `mdm:bank:update` | 銀行 CRUD | 20023 | F-MDM-013 |
| 98 | GET | `/api/mdm/partner-bank-accounts` | `mdm:bank-account:view` | 口座一覧（マスク） | — | F-MDM-013 |
| 99 | POST/PUT | `/api/mdm/partner-bank-accounts[/{id}]` | `mdm:bank-account:update` | 口座 CRUD | 20022/20023/20042 | F-MDM-013 |
| 100 | POST | `/api/mdm/partner-bank-accounts/{id}/change-request` | `mdm:bank-account:update` | 口座変更申請 | 4002 | F-MDM-013 |
| 101 | POST | `/api/mdm/partner-bank-accounts/{id}/verify` | `mdm:bank-account:verify` | 口座検証 | 4002 | F-MDM-013 |

### 2.5 信用・評価・代替・条码・治理

| # | メソッド | パス | 権限 | 概要 | 主なエラー | 機能 |
|---|---|---|---|---|---|---|
| 102 | GET | `/api/mdm/credit-limits` | `mdm:credit:view` | 与信一覧 | — | F-MDM-014 |
| 103 | GET | `/api/mdm/credit-limits/{id}` | `mdm:credit:view` | 与信詳細 | 4001 | F-MDM-014 |
| 104 | POST/PUT | `/api/mdm/credit-limits[/{id}]` | `mdm:credit:update` | 与信 CRUD | 20043 | F-MDM-014 |
| 105 | POST | `/api/mdm/credit-limits/{id}/submit` | `mdm:credit:update` | 承認提出 | 4002 | F-MDM-014 |
| 106 | POST | `/api/mdm/credit-limits/{id}/freeze` | `mdm:credit:update` | 凍結 | 4002 | F-MDM-014 |
| 107 | POST | `/api/mdm/credit-limits/{id}/unfreeze` | `mdm:credit:update` | 凍結解除 | 4002 | F-MDM-014 |
| 108 | GET/POST/PUT | `/api/mdm/credit-check-rules[/{id}]` | `mdm:credit:view/update` | 检查規則 CRUD | 4003 | F-MDM-014 |
| 109 | GET | `/api/mdm/supplier-evaluations` | `mdm:supplier-eval:view` | 評価一覧 | — | F-MDM-015 |
| 110 | GET | `/api/mdm/supplier-evaluations/{id}` | `mdm:supplier-eval:view` | 評価詳細 | 4001 | F-MDM-015 |
| 111 | POST | `/api/mdm/supplier-evaluations/calculate` | `mdm:supplier-eval:update` | 月次計算 | 4005 | F-MDM-015 |
| 112 | PUT | `/api/mdm/supplier-evaluations/{id}` | `mdm:supplier-eval:update` | 評価修正 | 20047 | F-MDM-015 |
| 113 | POST | `/api/mdm/supplier-evaluations/{id}/confirm` | `mdm:supplier-eval:update` | 評価確定 | 20048 | F-MDM-015 |
| 114 | GET | `/api/mdm/supplier-avl` | `mdm:supplier-eval:view` | AVL（合格供应商目录） | — | F-MDM-015 |
| 115 | GET | `/api/mdm/material-substitutes` | `mdm:substitute:view` | 代替一覧 | — | F-MDM-016 |
| 116 | POST/PUT | `/api/mdm/material-substitutes[/{id}]` | `mdm:substitute:update` | 代替 CRUD | 20049/20050/20051 | F-MDM-016 |
| 117 | POST | `/api/mdm/material-substitutes/validate` | `mdm:substitute:update` | 整合チェック | 20049 | F-MDM-016 |
| 118 | DELETE | `/api/mdm/material-substitutes/{id}` | `mdm:substitute:update` | 論理削除 | 4003 | F-MDM-016 |
| 119 | GET/POST/PUT | `/api/mdm/barcode-rules[/{id}]` | `mdm:barcode-rule:view/update` | 条码規則 CRUD | 4003 | F-MDM-017 |
| 120 | POST | `/api/mdm/material-barcodes` | `mdm:barcode:print` | 条码発行 | 20052 | F-MDM-017 |
| 121 | POST | `/api/mdm/material-barcodes/labels` | `mdm:barcode:print` | ラベル PDF | 20052 | F-MDM-017 |
| 122 | GET | `/api/mdm/change-requests` | `mdm:change:view` | 変更申請一覧 | — | F-MDM-018 |
| 123 | POST/PUT | `/api/mdm/change-requests[/{id}]` | 対象 update 権限 | 変更申請 CRUD | 4001 | F-MDM-018 |
| 124 | POST | `/api/mdm/change-requests/{id}/submit` | 対象 update 権限 | 提出 | 20053 | F-MDM-018 |
| 125 | POST | `/api/mdm/change-requests/{id}/approve` | `mdm:change:approve` | 承認・反映 | 20053/20054 | F-MDM-018 |
| 126 | POST | `/api/mdm/change-requests/{id}/reject` | `mdm:change:approve` | 却下/差戻し | 4002 | F-MDM-018 |
| 127 | GET | `/api/mdm/change-histories` | `mdm:change:view` | 変更履歴 | — | F-MDM-018 |
| 128 | GET/POST/PUT | `/api/mdm/data-quality-rules[/{id}]` | `mdm:data-quality:view/update` | 品質規則 CRUD | 4003 | F-MDM-019 |
| 129 | POST | `/api/mdm/data-quality-runs` | `mdm:data-quality:update` | 品質チェック実行 | 4005 | F-MDM-019 |
| 130 | GET | `/api/mdm/data-quality-issues` | `mdm:data-quality:view` | 問題一覧 | — | F-MDM-019 |
| 131 | PUT | `/api/mdm/data-quality-issues/{id}` | `mdm:data-quality:update` | 問題更新・クローズ | 4002 | F-MDM-019 |
| 132 | GET/PUT | `/api/mdm/data-scope-policies[/{id}]` | `mdm:data-scope:update` | データ権限策略 | 4003 | F-MDM-020 |
| 133 | GET | `/api/mdm/search` | `mdm:portal:view` | 主数据横断検索 | 1001 | F-MDM-022 |
| 134 | POST | `/api/mdm/imports` | 各 import 権限 | 一括取込（ドライラン/実行） | 20055/1005 | F-MDM-019 |
| 135 | GET | `/api/mdm/imports/{jobId}/errors` | 各 import 権限 | エラー CSV | 4001 | F-MDM-019 |
| 136 | POST | `/api/mdm/exports` | `mdm:*:export` | エクスポート（202） | 4005 | F-MDM-022 |
| 137 | GET | `/api/mdm/jobs/{jobId}` | `mdm:*:view` | ジョブ状態 | 4001 | F-MDM-019 |

### 2.6 工厂主数据（F-MDM-025。Lead 裁定 2026-10-20：工厂主数据归 MDM）

| # | メソッド | パス | 権限 | 概要 | 主なエラー | 機能 |
|---|---|---|---|---|---|---|
| 138 | GET | `/api/mdm/factories` | `mdm:factory:view` | 工厂一覧（他域共用） | — | F-MDM-025 |
| 139 | POST | `/api/mdm/factories` | `mdm:factory:update` | 工厂登録 | 1005 | F-MDM-025 |
| 140 | PUT | `/api/mdm/factories/{id}` | `mdm:factory:update` | 工厂更新 | 4003 | F-MDM-025 |

> SYS の F-SYS-014（公司/工厂组织设置）は工厂マスタを保有せず、`mdm_factory` を参照する。MDM が工厂マスタの更新責任者（[00-overview](00-overview.md) 未決 #3 は已裁决）。

## 3. API 詳細（代表 7 件）

### 3.1 GET /api/mdm/materials/{id}（物料詳細・他域共用参照）

| 項目 | 内容 |
|---|---|
| 目的 | 物料の全視図を返す。SAL/PUR/INV/PRD/FIN の参照契約 |
| 権限 | `mdm:material:view` |
| リクエスト | パス `id`（文字列）。クエリ `fields`（任意、返却項目の絞込）、`factoryId`（工場視図を含める場合） |
| レスポンス | `data`：`id, materialCode, materialName, shortName, materialType, category{id,code,name}, spec, materialGrade, standardCode, brand, baseUomCode, status, approvalStatus, version, updatedAt` + 視図オブジェクト `purchase/sales/inventory/production/finance/quality` + `factories[]` |
| 正常例 | 下記 |
| エラー | 4001 対象不存在、3001 権限なし、3002 データ範囲外 |
| 処理概要 | PK + 視図結合（1 クエリ）。キャッシュ可（TTL 5 分、`updatedAt` 付き） |
| 関連テーブル | `mdm_material`、`mdm_material_category`、`mdm_material_factory` |

```json
{
  "code": 0, "message": "ok",
  "data": {
    "id": "1845000000000000103", "materialCode": "3001000001",
    "materialName": "YE3-100L1-4 三相异步电动机", "materialType": 10,
    "category": { "id": "1845000000000000101", "categoryCode": "3001", "categoryName": "YE3 系列" },
    "spec": "2.2kW/4极/380V/50Hz/IP55/B3/F级", "standardCode": "GB/T 28575-2020",
    "baseUomCode": "PCE", "status": 1, "approvalStatus": 25,
    "purchase": { "purchaseUomCode": "PCE", "purchaseConversionRate": "1", "purchaseTaxCode": "VAT13-IN", "purchaseLeadTimeDays": 7 },
    "sales": { "salesUomCode": "PCE", "salesTaxCode": "VAT13-OUT", "returnLimitDays": 30 },
    "inventory": { "isBatchManaged": true, "isSerialManaged": true, "shelfLifeDays": 0, "defaultWarehouseId": "1845000000000000301", "safetyStockQty": "20.0000" },
    "production": { "isManufactured": true, "bomRequiredFlag": true, "isBackflush": false, "mrpType": 10 },
    "finance": { "inventoryAccountCode": "1405", "revenueAccountCode": "6001", "cogsAccountCode": "6401", "costMethod": 1, "taxClassificationCode": "1090101" },
    "quality": { "inspectionStage": 40 },
    "version": 2, "updatedAt": "2026-10-20T09:00:00+08:00"
  }
}
```

### 3.2 POST /api/mdm/materials（物料登録）

- 権限 `mdm:material:create`、`Idempotency-Key` 必須。リクエストは [01](01-material-master.md) 4.4.2 の項目定義に従う。
- 処理：権限→入力チェック→分類・既定値確定→採番→INSERT→工場行 INSERT→履歴→監査。トランザクション要。
- 正常：`201` + `MaterialDetailDto`（`approvalStatus=10`、`status=0`、`version=0`）。
- エラー：`1002/1003/1005`（共通入力）、`20010`（コード形式）、`20011`（コード重複）、`20012`（分類不正）、`20013`（換算不正）、`3001`（権限）。レスポンスは `data.fieldErrors[]`。

### 3.3 GET /api/mdm/prices/sales/effective（销售取价）

| 項目 | 内容 |
|---|---|
| 目的 | 顧客・物料・数量・基準日で販売単価を解決する（SAL 受注・見積の取价契約） |
| 権限 | `mdm:price:view` |
| リクエスト | `customerId`（必須）、`materialId`（必須）、`quantity`（必須、文字列）、`priceDate`（yyyy-MM-dd、既定=当日）、`currencyCode`（既定=顧客通貨）、`uomCode`（既定=基本単位） |
| レスポンス | **必須**：`materialId, customerId, currencyCode, unitPriceNet, unitPriceGross, taxCode, isTaxIncluded, discountRate, validFrom, validTo`。参考項目（消費側は無視可）：`taxRate, priceSource(10/20/30/40), priceSourceName, priceListId, priceListLineId, quantityBand{minQty,maxQty}, discountAmount` |
| 正常例 | 3.3.1 |
| エラー | `404`（無価格。`code=20036`「見積価格未設定」）、`4001`、`3001` |
| 処理概要 | 3.1 の優先順位で候補を取得→税抜換算→通貨換算→折扣。候補一覧は `simulate` で返す。`effective-batch` も同一契約（リクエスト順で返却） |
| 性能 | 200ms 以内（索引 `idx_mdm_price_line_lookup`） |

```json
{
  "code": 0, "message": "ok",
  "data": {
    "materialId": "1845000000000000101", "customerId": "1845000000000000001",
    "currencyCode": "CNY",
    "unitPriceNet": "850.000000", "unitPriceGross": "960.500000",
    "taxCode": "VAT13-OUT", "isTaxIncluded": false, "taxRate": "13.0000",
    "discountRate": "0.0000",
    "validFrom": "2026-01-01", "validTo": "2026-12-31",
    "priceSource": 10, "priceSourceName": "客户+物料",
    "priceListId": "1845000000000000501", "priceListLineId": "1845000000000000511",
    "quantityBand": { "minQty": "100.0000", "maxQty": null },
    "discountAmount": "0.00"
  }
}
```

### 3.4 GET /api/mdm/customers/{id}/credit-limit（与信照会）

- 権限 `mdm:customer:credit:view`。SAL 受注・出荷、FIN 与信管理が共用。
- レスポンス：`creditLimitId, customerId, customerCode, currencyCode, creditLimitAmount, singleOrderLimitAmount, overLimitRatio, creditStatus, checkRule{ruleCode, checkTiming[], exposureScope[], includeOpenOrders, overflowAction}, validFrom, validTo, lastReviewDate`。
- **注意**：MDM は与信占用額を返さない。占用額の計算は SAL/FIN が行う（[06](06-credit-supplier-eval.md) 2.5）。
- **与信判定結果コード**：SAL/FIN が行う与信判定の結果コードは [06](06-credit-supplier-eval.md) **BR-CRD-13**（`10 正常`/`20 注意`/`30 超限審査中`/`40 超限承認済`/`90 凍結・閉鎖`）に従う。E06 `creditCheckResult` も同コード。
- エラー：`4001`、`20043`（未設定）、`3001`。

### 3.5 GET /api/mdm/tax-codes/{code}（税码照会）

- 権限 `mdm:tax-code:view`。クエリ `date`（基準日、既定=当日）で有効な税码を返す。
- レスポンス：`taxCode, taxName, taxRateCode, taxType(10/11/20/30/40/50), taxRate, isTaxIncluded, taxClassificationCode, validFrom, validTo, status`。
- エラー：`4001`（不存在/期間外）。
- **業務側は税方向を自行判定しない**（Lead 裁定、[04](04-uom-currency-tax.md) 2.4）。

### 3.6 GET /api/mdm/exchange-rates/effective（有効汇率）

- 権限 `mdm:exchange-rate:view`。`from`、`to`（既定 CNY）、`rateType`（既定 SPOT）、`date`。
- レスポンス：`fromCurrency, toCurrency, rateType, effectiveDate, exchangeRate, source`。
- エラー：`20033`（該当レートなし）。未来日レートは返さない（基準日以前の最新有効レート）。

### 3.7 POST /api/mdm/change-requests/{id}/approve（变更承認・反映）

- 権限 `mdm:change:approve`。リクエスト `{version, comment}`。
- 処理：承認（WF 最終承認後）→ `base_version` と対象 version の一致確認→対象マスタ更新→version+1→履歴確定→E01〜E04 発行→`status=30`。
- 正常：`200` + `ChangeRequestDto`（`status=30`、`appliedAt`）。
- エラー：`4002`（状態不整合）、`20053`（申請後にデータ更新）、`20054`（自己承認）、`4003`（楽観排他）。
- 冪等：WF コールバックは `eventId` + `taskId` で重複排除。

### 3.8 選択用 API の返却項目（工单画面 SCR-PRD-009 等）

| API | 返却項目 | 絞り込み |
|---|---|---|
| `GET /api/mdm/factories`（#138） | `id, factoryCode, factoryName` | 当前会社 |
| `GET /api/mdm/warehouses/options`（#55） | `id, warehouseCode, warehouseName` | 当前会社 |
| `GET /api/mdm/materials`（#1。選択用途） | `id, materialCode, materialName, unitId` | 当前会社 |

（必須項目＝ID・コード・名称（蓝色大肥鱼 2026-10-21 PR #32 決定）。これ以外の項目を返すことは妨げない。物料の `unitId` は画面で単位を表示するため）

## 4. エラーコードとメッセージ対応

### 4.1 MDM 領域コード範囲（20000〜29999）

| コード | HTTP | メッセージ ID | 概要 |
|---|---|---|---|
| 20001 | 400 | MSG-COM-040 | 必須項目未入力 |
| 20002 | 400 | MSG-COM-041/042/043 | 形式・桁不正 |
| 20003 | 400 | MSG-COM-044/045/046 | 範囲・相関不正 |
| 20004 | 400 | MSG-COM-049 | コード不存在・失效 |
| 20005 | 409 | MSG-COM-050 | 一意制約違反 |
| 20006 | 409 | MSG-COM-033 | 楽観排他競合 |
| 20007 | 409 | MSG-COM-034 | 状態不整合 |
| 20008 | 422 | MSG-MDM-029/062 | 参照中のため削除・停止不可 |
| 20009 | 403 | MSG-COM-030 | 権限なし |
| 20010 | 400 | MSG-MDM-013 | 物料コード形式不正 |
| 20011 | 409 | MSG-MDM-014 | 物料コード重複 |
| 20012 | 400 | MSG-MDM-011 | 物料分類不正（末級・有効でない） |
| 20013 | 400 | MSG-MDM-015 | 単位換算率不正 |
| 20014 | 400 | MSG-MDM-016 | 批次/序列号の同時設定 |
| 20015 | 400 | MSG-MDM-017 | 在庫パラメータ相関不正 |
| 20016 | 400 | MSG-MDM-018 | 倒冲条件不正 |
| 20017 | 400 | MSG-MDM-019 | 検査基準未設定 |
| 20018 | 422 | MSG-MDM-029/062 | 使用中のため停止不可 |
| 20019 | 500 | MSG-MDM-030 | 採番枯渇 |
| 20020 | 409 | MSG-MDM-050/051 | 取引先コード/税号の重複・不正 |
| 20021 | 400 | MSG-MDM-052 | 発票 4 要素不足 |
| 20022 | 400 | MSG-MDM-055 | 口座番号形式不正 |
| 20023 | 400 | MSG-MDM-060/122 | CNAPS 形式不正 |
| 20024 | 422 | MSG-MDM-057/150 | 准入資格不足 |
| 20025 | 400 | MSG-MDM-059 | 供給範囲不正 |
| 20026 | 400 | MSG-MDM-071/073 | 倉庫・庫区コード不正 |
| 20027 | 409 | MSG-MDM-074 | 庫位コード重複 |
| 20028 | 422 | MSG-MDM-075 | 在庫あり倉庫の停止不可 |
| 20029 | 400 | MSG-MDM-093 | 単位コード不正 |
| 20030 | 400 | MSG-MDM-094 | 基本単位重複 |
| 20031 | 400 | MSG-MDM-095 | 換算不正（グループ不一致等） |
| 20032 | 400 | MSG-MDM-091 | 通貨/基準通貨不正 |
| 20033 | 400 | MSG-MDM-098/099 | 為替レート不正・未来日 |
| 20034 | 400 | MSG-MDM-096 | 税码/基礎税率コード不正 |
| 20035 | 409 | MSG-MDM-097 | 税码有効期間重複 |
| 20036 | 422 | MSG-MDM-113 | 価格候補なし |
| 20037 | 409 | MSG-MDM-114 | 価格表コード重複 |
| 20038 | 400 | MSG-MDM-115 | 価格スコープ不正 |
| 20039 | 400 | MSG-MDM-116 | 数量帯重複 |
| 20040 | 400 | MSG-MDM-118 | 折扣率不正 |
| 20041 | 400 | MSG-MDM-120 | 分割比率不正 |
| 20042 | 409 | MSG-MDM-124 | 既定口座の重複 |
| 20043 | 422 | MSG-MDM-141 | 与信限度未設定 |
| 20044 | 422 | MSG-MDM-142 | 与信超過（ブロック） |
| 20045 | 422 | MSG-MDM-143 | 与信凍結中 |
| 20046 | 422 | MSG-MDM-145 | 単一受注上限超過（要承認） |
| 20047 | 400 | MSG-MDM-151 | 評価点範囲外 |
| 20048 | 409 | MSG-MDM-152 | 確定済評価の変更 |
| 20049 | 400 | MSG-MDM-171/172 | 代替の自己参照・循環 |
| 20050 | 409 | MSG-MDM-173 | 代替重複 |
| 20051 | 400 | MSG-MDM-174 | 緊急代替の期間超過 |
| 20052 | 409 | MSG-MDM-177 | 条码重複 |
| 20053 | 409 | MSG-MDM-182 | 変更申請の版数競合 |
| 20054 | 403 | MSG-MDM-183 | 自己承認 |
| 20055 | 400 | MSG-MDM-191 | 取込行数超過 |
| 20056 | 400 | MSG-MDM-079/080 | 一括生成・印刷件数超過 |
| 20057 | 400 | MSG-MDM-117 | 価格乖離（警告→承認） |
| 20058 | 400 | MSG-MDM-119 | 税込/税抜の不整合 |
| 20059 | 400 | MSG-MDM-121 | 固定支払日不正 |
| 20060 | 400 | MSG-MDM-123/061 | 口座名義不一致（警告） |

### 4.2 エラーレスポンス形式

```json
{
  "code": 20011,
  "message": "物料编码「3001000001」已被使用。",
  "data": { "fieldErrors": [ { "field": "materialCode", "message": "物料编码已被使用。" } ] }
}
```

- バリデーションは `data.fieldErrors[]`（[03 §5.3](../00-common/03-common-api-spec.md)）。`field` はパス形式（`lines[0].quantity`）。
- 業務エラー（422）は `message` のみ + 必要に応じ `data.detail`。500 系は `trace_id` のみ返す。
- メッセージ本文・対処は [93-messages.md](93-messages.md) を正とする。

## 5. 他域向け参照 API 契約（09 §11）

| 利用域 | API | 主な返却 | 呼出タイミング | キャッシュ |
|---|---|---|---|---|
| SAL | `GET /api/mdm/customers/{id}` | 顧客基本・開票・付款条件・与信状態 | 受注・請求 | 5 分 |
| SAL | `GET /api/mdm/customers/{id}/credit-limit` | 与信限度・規則・状態 | 受注・出荷 | 5 分 |
| SAL | `GET /api/mdm/prices/sales/effective` | 販売単価・税碼・根拠 | 見積・受注 | なし（毎回） |
| SAL/PUR | `GET /api/mdm/materials/{id}` | 物料全視図 | 明細登録 | 5 分 |
| PUR | `GET /api/mdm/suppliers/{id}` | 供給者・付款・准入 | 発注 | 5 分 |
| PUR | `GET /api/mdm/prices/purchase/effective` | 購買単価 | 発注 | なし |
| INV | `GET /api/mdm/warehouses/{id}` / `/warehouse-bins` | 倉庫・庫位 | 入出庫 | 5 分 |
| 全業務域 | `GET /api/mdm/factories` | 工場一覧（会社/工場組織） | 組織参照・データ権限 | 5 分 |
| INV/PRD | `GET /api/mdm/uoms/{code}`、`POST /api/mdm/uoms/convert` | 単位・換算 | 入出庫・払出 | 5 分 |
| FIN/SAL/PUR | `GET /api/mdm/tax-codes/{code}` | 税碼・税率・含税 | 税計算 | 5 分 |
| FIN | `GET /api/mdm/exchange-rates/effective` | 有効レート | 外貨換算 | なし（当日） |
| FIN | `GET /api/mdm/payment-terms/{code}` | 付款条件 | 期日計算 | 5 分 |
| FIN/INT | `GET /api/mdm/partner-bank-accounts` | 口座（マスク） | 支払・振込 | 5 分 |
| 全業務域 | `GET /api/mdm/materials/batch-get` | 物料一括参照 | 一覧・帳票 | 5 分 |

- 参照 API は**読取のみ**。更新は MDM 画面またはイベント購読で行う（[09 §2.2](../00-common/09-cross-domain-flow.md)）。
- マスタ名称は伝票にスナップショット保持すること（[09 §11](../00-common/09-cross-domain-flow.md)）。

## 6. 非機能・セキュリティ

| 項目 | 内容 |
|---|---|
| 性能 | 参照 API 200ms/件、一覧 2 秒/100 件、登録 3 秒（[00-overview](00-overview.md) 第 11 章） |
| 認証 | Sa-Token（`Authorization` ヘッダ）。外部公開は `/api/open/v1` |
| 認可 | 全 API に権限コード。データ権限は SQL 強制注入。API 単体でも再チェック |
| 冪等 | 登録・状態操作に `Idempotency-Key`。24 時間保持（`sys_idempotency`） |
| 排他 | 更新系は `version` 必須。`409` + `code=4003` |
| 監査 | 更新・承認・出力・印刷・取込を `sys_audit_log` に記録（口座・個人情報はマスキング） |
| レート制限 | 内部 API はなし。外部 API は 600 req/分 |
| 入力検証 | Bean Validation + 業務チェック。SQL はパラメータバインドのみ |
| CORS/CSRF | 同一オリジン（Nginx）、Authorization ヘッダ方式 |

## 7. 未決事項

| # | 事項 | 理由 | 暫定仕様 | 担当 | 期限 |
|---|---|---|---|---|---|
| 1 | 他域向け参照 API をモジュール公開 Service と REST のどちらで提供するか | Spring Modulith の内部呼出方式の決定待ち | 設計は REST を正とし、実装は公開 Service 呼出も可（同契約） | lead | 2026-10-24 |
| 2 | 取价 API の一括呼出上限（500 件）と性能 | SAL の明細行数に依存 | 500 件/回。超過は分割 | lead / SAL | 2026-10-30 |
| 3 | 口座番号の暗号化・マスク API の仕様 | セキュリティ要件待ち | 一覧は下 4 桁、詳細は権限者のみ全桁（監査ログ） | lead | 2026-11-06 |
| 4 | 外部公開 API（`/api/open/v1/mdm/**`）の範囲 | 第一版対象 | 第一版で（TODO：設計未作成） `mdm.read` スコープを設計 | lead | 2026-11-13 |

## 8. 改訂履歴

| 版数 | 日付 | 変更内容 | 変更者 |
|---|---|---|---|
| v1.0 | 2026-10-20 | 初版：API 140 件一覧、代表 7 件詳細、エラーコード対応表、他域参照契約。同日追記：Lead 裁定により工厂主数据（F-MDM-025）API 3 件（#138〜140）を追加、物料詳細レスポンスの `finance` に `costMethod` を追加。第 2 次追記（红队第 2 轮 REV-004/REV-003）：销售取价 API のレスポンス契約を `materialId/customerId/currencyCode/unitPriceNet/unitPriceGross/taxCode/isTaxIncluded/discountRate/validFrom/validTo` に統一（無価格は 404＋20036）、与信判定結果コード（BR-CRD-13）を明記 | mdm-designer |
| v1.1 | 2026-10-21 | §3.8 選択用 API（factories／warehouses/options／materials）の返却項目を追加（蓝色大肥鱼 2026-10-21 PR #32 決定） | 业务分析 |
