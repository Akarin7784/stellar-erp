# 機能権限一覧（功能权限一览）

| 項目 | 内容 |
|---|---|
| 文書名 | 機能権限一覧（功能权限一览）（自动生成） |
| 文書番号 | DSN-MTX-008 |
| 版数 | v1.0 |
| 作成日 | 2026-10-20 |
| 作成者 | Lead（生成工具 gen_matrix.py） |
| 状態 | ドラフト（自动生成・最終レビュー前） |
| 備考 | 全 451 件。権限コード/域/対象機能/データ範囲/提取元 |

> 本文件由 `20-matrix/tools/gen_matrix.py` 从各域设计书中自动提取生成。修改设计书后重新运行即可更新。

| 権限コード | 域 | 対象機能 | データ範囲 | 提取元 |
|---|---|---|---|---|
| finance:account:create/update | FIN | F-FIN-001 |  | 07-finance/00-overview.md |
| finance:account:update | FIN | F-FIN-002 |  | 07-finance/00-overview.md |
| finance:account:view | FIN | F-FIN-001 |  | 07-finance/00-overview.md |
| finance:aging:view | FIN | F-FIN-018 |  | 07-finance/00-overview.md |
| finance:asset:dispose | FIN | F-FIN-042 |  | 07-finance/00-overview.md |
| finance:asset:view/update | FIN | F-FIN-041 |  | 07-finance/00-overview.md |
| finance:auto-voucher:view | FIN | F-FIN-030 |  | 07-finance/00-overview.md |
| finance:auto-voucher:view/update | FIN | F-FIN-029 |  | 07-finance/00-overview.md |
| finance:bank-journal:view | FIN | F-FIN-024 |  | 07-finance/00-overview.md |
| finance:bank-recon:execute | FIN | F-FIN-024 |  | 07-finance/00-overview.md |
| finance:bank-recon:view | FIN | F-FIN-024 |  | 07-finance/00-overview.md |
| finance:bank-statement:import | FIN | F-FIN-024 |  | 07-finance/00-overview.md |
| finance:budget:update | FIN | F-FIN-043 |  | 07-finance/00-overview.md |
| finance:cash-journal:view | FIN | F-FIN-023 |  | 07-finance/00-overview.md |
| finance:cost:calculate | FIN | F-FIN-031 |  | 07-finance/00-overview.md |
| finance:cost:view | FIN | F-FIN-031 |  | 07-finance/00-overview.md |
| finance:expense:create | FIN | F-FIN-040 |  | 07-finance/00-overview.md |
| finance:fund-report:view | FIN | F-FIN-025 |  | 07-finance/00-overview.md |
| finance:invoice:match | FIN | F-FIN-013 |  | 07-finance/00-overview.md |
| finance:invoice:view | FIN | F-FIN-026 |  | 07-finance/00-overview.md |
| finance:ledger:view | FIN | F-FIN-010 |  | 07-finance/00-overview.md |
| finance:opening-balance:import | FIN | F-FIN-002 |  | 07-finance/00-overview.md |
| finance:payable:update | FIN | F-FIN-012 |  | 07-finance/00-overview.md |
| finance:payable:view | FIN | F-FIN-012 |  | 07-finance/00-overview.md |
| finance:payment-request:create | FIN | F-FIN-015 |  | 07-finance/00-overview.md |
| finance:payment-request:create（数据范围：本部门） | FIN | F-FIN-013/015 |  | 07-finance/00-overview.md |
| finance:payment:execute | FIN | F-FIN-016 |  | 07-finance/00-overview.md |
| finance:period:close | FIN | F-FIN-035/036 |  | 07-finance/00-overview.md |
| finance:period:view/close | FIN | F-FIN-035 |  | 07-finance/00-overview.md |
| finance:receipt:create | FIN | F-FIN-020 |  | 07-finance/00-overview.md |
| finance:receivable:update | FIN | F-FIN-022 |  | 07-finance/00-overview.md |
| finance:receivable:view | FIN | F-FIN-019 |  | 07-finance/00-overview.md |
| finance:receivable:view（数据范围：本部门） | FIN | F-FIN-020 |  | 07-finance/00-overview.md |
| finance:report:view | FIN | F-FIN-039 |  | 07-finance/00-overview.md |
| finance:standard-cost:view/register/publish | FIN | F-FIN-047 |  | 07-finance/00-overview.md |
| finance:statement:view | FIN | F-FIN-038 |  | 07-finance/00-overview.md |
| finance:statement:view/export | FIN |  |  | 07-finance/92-report-batch-design.md |
| finance:tax-accrual:generate | FIN | F-FIN-028 |  | 07-finance/00-overview.md |
| finance:trial-balance:view | FIN | F-FIN-011/039 |  | 07-finance/00-overview.md |
| finance:vat-return:view | FIN | F-FIN-027 |  | 07-finance/00-overview.md |
| finance:vat-return:view/export | FIN |  |  | 07-finance/92-report-batch-design.md |
| finance:voucher-template:view/update | FIN | F-FIN-004 |  | 07-finance/00-overview.md |
| finance:voucher:approve | FIN | F-FIN-005 |  | 07-finance/00-overview.md |
| finance:voucher:create | FIN | F-FIN-003 |  | 07-finance/00-overview.md |
| finance:voucher:post | FIN | F-FIN-006 |  | 07-finance/00-overview.md |
| finance:voucher:print | FIN |  |  | 07-finance/92-report-batch-design.md |
| finance:voucher:reverse | FIN | F-FIN-008 |  | 07-finance/00-overview.md |
| finance:voucher:submit | FIN | F-FIN-003 | 本人制单 | 07-finance/00-overview.md |
| finance:voucher:unpost | FIN | F-FIN-007 |  | 07-finance/00-overview.md |
| finance:voucher:view | FIN | F-FIN-003/009 |  | 07-finance/00-overview.md |
| finance:write-off:create | FIN | F-FIN-017 |  | 07-finance/00-overview.md |
| finance:year-close:execute | FIN | F-FIN-037 |  | 07-finance/00-overview.md |
| integration:api-client:*、integration:notification-channel:* | INT | F-INT-009、012 |  | 09-integration/00-overview.md |
| integration:api-client:view | INT | F-INT-009 |  | 09-integration/00-overview.md |
| integration:api-client:view/create/update | INT | F-INT-009 | 全社 | 09-integration/00-overview.md |
| integration:bank-account:view | INT | F-INT-004 |  | 09-integration/00-overview.md |
| integration:bank-payment:approve | INT | F-INT-004 | 承認経路該当者 | 09-integration/00-overview.md |
| integration:bank-payment:approve、integration:tax-invoice:red | INT | F-INT-002、004 |  | 09-integration/00-overview.md |
| integration:bank-payment:create | INT | F-INT-004 |  | 09-integration/00-overview.md |
| integration:bank-payment:create/submit | INT | F-INT-004 | 全社 | 09-integration/00-overview.md |
| integration:bank-payment:create/submit、integration:bank-statement:import | INT | F-INT-004、005 |  | 09-integration/00-overview.md |
| integration:bank-payment:view | INT | F-INT-004 |  | 09-integration/00-overview.md |
| integration:bank-statement:import | INT | F-INT-005 |  | 09-integration/00-overview.md |
| integration:bank-statement:view | INT | F-INT-005 |  | 09-integration/00-overview.md |
| integration:bank-statement:view/import | INT | F-INT-005 | 全社 | 09-integration/00-overview.md |
| integration:call-log:view | INT | F-INT-014 |  | 09-integration/00-overview.md |
| integration:call-log:view/export | INT | F-INT-014 | 全社 | 09-integration/00-overview.md |
| integration:credential:update | INT | F-INT-015 | 全社 | 09-integration/00-overview.md |
| integration:file-transfer:view | INT | F-INT-011 |  | 09-integration/00-overview.md |
| integration:file-transfer:view/import | INT | F-INT-011 | 全社 | 09-integration/00-overview.md |
| integration:input-invoice:view | INT | F-INT-003 |  | 09-integration/00-overview.md |
| integration:input-invoice:view/verify | INT | F-INT-003 | 全社 | 09-integration/00-overview.md |
| integration:interface-config:*、integration:credential:update | INT | F-INT-001、015 |  | 09-integration/00-overview.md |
| integration:interface-config:create | INT | F-INT-001 |  | 09-integration/00-overview.md |
| integration:interface-config:test | INT | F-INT-001 |  | 09-integration/00-overview.md |
| integration:interface-config:test/enable/disable | INT | F-INT-001 | 全社 | 09-integration/00-overview.md |
| integration:interface-config:view | INT | F-INT-001 |  | 09-integration/00-overview.md |
| integration:interface-config:view/create/update/delete | INT | F-INT-001 | 全社 | 09-integration/00-overview.md |
| integration:mes:receive | INT | F-INT-006 | システム | 09-integration/00-overview.md |
| integration:mes:view | INT | F-INT-006/007 |  | 09-integration/00-overview.md |
| integration:mes:view/retry | INT | F-INT-006 |  | 09-integration/00-overview.md |
| integration:notification-channel:update | INT | F-INT-012 |  | 09-integration/00-overview.md |
| integration:notification-channel:view/update | INT | F-INT-012 | 全社 | 09-integration/00-overview.md |
| integration:notification-log:view | INT | F-INT-012 |  | 09-integration/00-overview.md |
| integration:pda-device:view | INT | F-INT-010 |  | 09-integration/00-overview.md |
| integration:pda-device:view/update | INT | F-INT-010 | 全社 | 09-integration/00-overview.md |
| integration:pda:use | INT | F-INT-010 |  | 09-integration/00-overview.md |
| integration:plm:approve | INT | F-INT-008 | 全社 | 09-integration/00-overview.md |
| integration:plm:view | INT | F-INT-008 |  | 09-integration/00-overview.md |
| integration:plm:view/import | INT | F-INT-008 | 全社 | 09-integration/00-overview.md |
| integration:po-send:submit | INT | F-INT-019 |  | 09-integration/00-overview.md |
| integration:reconcile:view | INT | F-INT-014 |  | 09-integration/00-overview.md |
| integration:sync-task:retry | INT | F-INT-013 |  | 09-integration/00-overview.md |
| integration:sync-task:view | INT | F-INT-013 |  | 09-integration/00-overview.md |
| integration:sync-task:view/retry | INT | F-INT-013 | 全社 | 09-integration/00-overview.md |
| integration:sync-task:view/retry、integration:call-log:view | INT | F-INT-013、014 |  | 09-integration/00-overview.md |
| integration:tax-invoice:create | INT | F-INT-002 |  | 09-integration/00-overview.md |
| integration:tax-invoice:create/request | INT | F-INT-002 | 担当伝票 | 09-integration/00-overview.md |
| integration:tax-invoice:create、integration:input-invoice:verify | INT | F-INT-002、003、016 |  | 09-integration/00-overview.md |
| integration:tax-invoice:red/approve | INT | F-INT-002 | 全社 | 09-integration/00-overview.md |
| integration:tax-invoice:request | INT | F-INT-002 |  | 09-integration/00-overview.md |
| integration:tax-invoice:view | INT | F-INT-002 |  | 09-integration/00-overview.md |
| inventory:*:view | INV | F-INV-011、F-INV-013 |  | 05-inventory/00-overview.md |
| inventory:barcode:print | INV | F-INV-018 | 自仓库 | 05-inventory/00-overview.md |
| inventory:barcode:scan | INV | F-INV-018 |  | 05-inventory/00-overview.md |
| inventory:batch:trace | INV | F-INV-011 |  | 05-inventory/00-overview.md |
| inventory:batch:view | INV | F-INV-011 |  | 05-inventory/00-overview.md |
| inventory:cost:adjust | INV | F-INV-017 |  | 05-inventory/00-overview.md |
| inventory:cost:approve | INV | F-INV-023 | 全社 | 05-inventory/00-overview.md |
| inventory:cost:recalc | INV | F-INV-017、022 | 全社 | 05-inventory/00-overview.md |
| inventory:cost:view | INV | F-INV-017 |  | 05-inventory/00-overview.md |
| inventory:cost:view、inventory:cost:adjust、inventory:period:close | INV | F-INV-017、F-INV-020、F-INV-021 |  | 05-inventory/00-overview.md |
| inventory:period:close | INV | F-INV-020 |  | 05-inventory/00-overview.md |
| inventory:period:reopen | INV | — |  | 05-inventory/00-overview.md |
| inventory:period:view | INV | F-INV-020、025 | 全社 | 05-inventory/00-overview.md |
| inventory:replenishment:generate | INV | F-INV-021 | 全社 | 05-inventory/00-overview.md |
| inventory:replenishment:view | INV | F-INV-016 |  | 05-inventory/00-overview.md |
| inventory:report:export | INV | F-INV-021 | 全社 | 05-inventory/00-overview.md |
| inventory:report:view | INV | F-INV-015、021 |  | 05-inventory/00-overview.md |
| inventory:reservation:create | INV | F-INV-019 | 全社（内部调用） | 05-inventory/00-overview.md |
| inventory:reservation:release | INV | F-INV-019、024 | 全社 | 05-inventory/00-overview.md |
| inventory:reservation:view | INV | F-INV-019 |  | 05-inventory/00-overview.md |
| inventory:serial:view | INV | F-INV-012 |  | 05-inventory/00-overview.md |
| inventory:status:change | INV | F-INV-014 |  | 05-inventory/00-overview.md |
| inventory:status:change（仅待检→可用/不合格） | INV | F-INV-014 |  | 05-inventory/00-overview.md |
| inventory:stock-balance:export | INV | F-INV-001 | 全社 | 05-inventory/00-overview.md |
| inventory:stock-balance:view | INV | F-INV-001 |  | 05-inventory/00-overview.md |
| inventory:stock-balance:view、inventory:replenishment:view | INV | F-INV-001、F-INV-016、F-INV-019 |  | 05-inventory/00-overview.md |
| inventory:stock-balance:view、inventory:reservation:view | INV | F-INV-001、F-INV-019 |  | 05-inventory/00-overview.md |
| inventory:stock-txn:create | INV | F-INV-002 |  | 05-inventory/00-overview.md |
| inventory:stock-txn:create、inventory:stocktake:enter、inventory:barcode:scan | INV | F-INV-002〜010、F-INV-018 |  | 05-inventory/00-overview.md |
| inventory:stock-txn:export | INV | F-INV-013、021 | 全社 | 05-inventory/00-overview.md |
| inventory:stock-txn:post | INV | F-INV-002〜010 | 自仓库 | 05-inventory/00-overview.md |
| inventory:stock-txn:post、inventory:transfer:approve、inventory:stocktake:approve | INV | F-INV-009、F-INV-010、F-INV-014 |  | 05-inventory/00-overview.md |
| inventory:stock-txn:print | INV | F-INV-002〜010 | 自仓库 | 05-inventory/00-overview.md |
| inventory:stock-txn:reverse | INV | F-INV-013 | 自仓库 | 05-inventory/00-overview.md |
| inventory:stock-txn:update | INV | F-INV-002〜010 | 自仓库（草稿のみ） | 05-inventory/00-overview.md |
| inventory:stock-txn:view | INV | F-INV-013 |  | 05-inventory/00-overview.md |
| inventory:stock-txn:view、inventory:replenishment:generate | INV | F-INV-002、F-INV-008 |  | 05-inventory/00-overview.md |
| inventory:stocktake:adjust | INV | F-INV-015 | 全社 | 05-inventory/00-overview.md |
| inventory:stocktake:approve | INV | F-INV-010 |  | 05-inventory/00-overview.md |
| inventory:stocktake:approve、inventory:cost:approve、inventory:period:close | INV | F-INV-010、F-INV-017、F-INV-020 |  | 05-inventory/00-overview.md |
| inventory:stocktake:create | INV | F-INV-010 |  | 05-inventory/00-overview.md |
| inventory:stocktake:enter | INV | F-INV-010 |  | 05-inventory/00-overview.md |
| inventory:stocktake:submit | INV | F-INV-014 | 自仓库 | 05-inventory/00-overview.md |
| inventory:stocktake:view | INV | F-INV-010、013〜015 | 全社 | 05-inventory/00-overview.md |
| inventory:transfer:approve | INV | F-INV-011 | 全社 | 05-inventory/00-overview.md |
| inventory:transfer:cancel | INV | F-INV-011、012 | 自仓库 | 05-inventory/00-overview.md |
| inventory:transfer:create | INV | F-INV-009 |  | 05-inventory/00-overview.md |
| inventory:transfer:receive | INV | F-INV-012 | 目标仓库 | 05-inventory/00-overview.md |
| inventory:transfer:ship | INV | F-INV-011 | 自仓库 | 05-inventory/00-overview.md |
| inventory:transfer:view | INV | F-INV-009 |  | 05-inventory/00-overview.md |
| mdm:bank-account:* | MDM | F-MDM-013 |  | 02-mdm/00-overview.md |
| mdm:bank:* | MDM | F-MDM-013 |  | 02-mdm/00-overview.md |
| mdm:barcode-rule:* | MDM | F-MDM-017 |  | 02-mdm/00-overview.md |
| mdm:barcode:print | MDM | F-MDM-017 |  | 02-mdm/00-overview.md |
| mdm:change:approve | MDM | F-MDM-018 |  | 02-mdm/00-overview.md |
| mdm:change:view | MDM | F-MDM-018 |  | 02-mdm/00-overview.md |
| mdm:code-rule:update | MDM | F-MDM-003 |  | 02-mdm/00-overview.md |
| mdm:credit:* | MDM | F-MDM-014 |  | 02-mdm/00-overview.md |
| mdm:credit:update | MDM | F-MDM-014 |  | 02-mdm/00-overview.md |
| mdm:currency:* | MDM | F-MDM-008 |  | 02-mdm/00-overview.md |
| mdm:currency:update | MDM | F-MDM-008 | 全社 | 02-mdm/00-overview.md |
| mdm:customer:create/update | MDM | F-MDM-004 |  | 02-mdm/00-overview.md |
| mdm:customer:credit:update | MDM | F-MDM-014 | 全社 | 02-mdm/00-overview.md |
| mdm:customer:credit:view | MDM | F-MDM-014 | 全社 | 02-mdm/00-overview.md |
| mdm:customer:update | MDM | F-MDM-004 |  | 02-mdm/00-overview.md |
| mdm:customer:view | MDM | F-MDM-004 |  | 02-mdm/00-overview.md |
| mdm:customer:view/create/update | MDM | F-MDM-004 | 全社/自部门（データ権限） | 02-mdm/00-overview.md |
| mdm:data-quality:* | MDM | F-MDM-019 |  | 02-mdm/00-overview.md |
| mdm:data-quality:view/update | MDM | F-MDM-019 | 全社 | 02-mdm/00-overview.md |
| mdm:data-scope:update | MDM | F-MDM-020 |  | 02-mdm/00-overview.md |
| mdm:exchange-rate:* | MDM | F-MDM-008 |  | 02-mdm/00-overview.md |
| mdm:exchange-rate:import | MDM | F-MDM-024 |  | 02-mdm/00-overview.md |
| mdm:exchange-rate:view/update/import | MDM | F-MDM-008/024 | 全社 | 02-mdm/00-overview.md |
| mdm:factory:view/update | MDM | F-MDM-025 |  | 02-mdm/00-overview.md |
| mdm:material-category:update | MDM | F-MDM-001 |  | 02-mdm/00-overview.md |
| mdm:material-factory:update | MDM | F-MDM-021 |  | 02-mdm/00-overview.md |
| mdm:material:create/update | MDM | F-MDM-002 |  | 02-mdm/00-overview.md |
| mdm:material:delete | MDM | F-MDM-002（使用停止） | 全社 | 02-mdm/00-overview.md |
| mdm:material:import/export | MDM | F-MDM-019/022 | 全社 | 02-mdm/00-overview.md |
| mdm:material:view | MDM | F-MDM-002 |  | 02-mdm/00-overview.md |
| mdm:payment-term:* | MDM | F-MDM-012 |  | 02-mdm/00-overview.md |
| mdm:portal:view | MDM | F-MDM-022 |  | 02-mdm/00-overview.md |
| mdm:price:create/update | MDM | F-MDM-010 |  | 02-mdm/00-overview.md |
| mdm:price:update | MDM | F-MDM-010 |  | 02-mdm/00-overview.md |
| mdm:price:view | MDM | F-MDM-010 |  | 02-mdm/00-overview.md |
| mdm:purchase-price:* | MDM | F-MDM-011 |  | 02-mdm/00-overview.md |
| mdm:purchase-price:view/create/update | MDM | F-MDM-011 | 全社 | 02-mdm/00-overview.md |
| mdm:settlement:* | MDM | F-MDM-012 |  | 02-mdm/00-overview.md |
| mdm:substitute:* | MDM | F-MDM-016 |  | 02-mdm/00-overview.md |
| mdm:supplier-admission:approve | MDM | F-MDM-015 |  | 02-mdm/00-overview.md |
| mdm:supplier-eval:* | MDM | F-MDM-015 |  | 02-mdm/00-overview.md |
| mdm:supplier-eval:view | MDM | F-MDM-015 |  | 02-mdm/00-overview.md |
| mdm:supplier-eval:view/update | MDM | F-MDM-015 | 全社 | 02-mdm/00-overview.md |
| mdm:supplier-quotation:* | MDM | F-MDM-011 |  | 02-mdm/00-overview.md |
| mdm:supplier:bank:update | MDM | F-MDM-013 | 全社 | 02-mdm/00-overview.md |
| mdm:supplier:create/update | MDM | F-MDM-005 |  | 02-mdm/00-overview.md |
| mdm:supplier:update | MDM | F-MDM-005/015 |  | 02-mdm/00-overview.md |
| mdm:supplier:view | MDM | F-MDM-005 |  | 02-mdm/00-overview.md |
| mdm:supplier:view/create/update | MDM | F-MDM-005 | 全社 | 02-mdm/00-overview.md |
| mdm:tax-code:* | MDM | F-MDM-009 |  | 02-mdm/00-overview.md |
| mdm:tax-code:update | MDM | F-MDM-009 |  | 02-mdm/00-overview.md |
| mdm:tax-code:view/update | MDM | F-MDM-009 | 全社 | 02-mdm/00-overview.md |
| mdm:uom:* | MDM | F-MDM-007 |  | 02-mdm/00-overview.md |
| mdm:uom:update | MDM | F-MDM-007 |  | 02-mdm/00-overview.md |
| mdm:uom:view/update | MDM | F-MDM-007 | 全社 | 02-mdm/00-overview.md |
| mdm:warehouse:* | MDM | F-MDM-006 |  | 02-mdm/00-overview.md |
| mdm:warehouse:create/update | MDM | F-MDM-006 | 工場単位 | 02-mdm/00-overview.md |
| mdm:warehouse:update | MDM | F-MDM-006 |  | 02-mdm/00-overview.md |
| mdm:warehouse:view | MDM | F-MDM-006 | 全社/工場 | 02-mdm/00-overview.md |
| production:bom:approve | PRD | F-PRD-001（BOM 变更审批） | 所属工厂 | 06-production/00-overview.md |
| production:bom:update | PRD | F-PRD-001 |  | 06-production/00-overview.md |
| production:bom:view | PRD | F-PRD-001 |  | 06-production/00-overview.md |
| production:completion:create | PRD | F-PRD-008 |  | 06-production/00-overview.md |
| production:dashboard:view | PRD | F-PRD-016 |  | 06-production/00-overview.md |
| production:equipment:view | PRD | F-PRD-018 |  | 06-production/00-overview.md |
| production:inspection-standard:update | PRD | F-PRD-012 |  | 06-production/00-overview.md |
| production:inspection:create | PRD | F-PRD-013 |  | 06-production/00-overview.md |
| production:inspection:judge | PRD | F-PRD-013（合否判定） | 全社 | 06-production/00-overview.md |
| production:inspection:judge（PRD） | PUR | F-PUR-013 |  | 04-purchase/00-overview.md |
| production:inspection:view | PRD | F-PRD-013 |  | 06-production/00-overview.md |
| production:material-issue:approve | PRD | F-PRD-006（超领审批） | 所属工厂 | 06-production/00-overview.md |
| production:material-issue:create | PRD | F-PRD-006 |  | 06-production/00-overview.md |
| production:material-issue:reverse | PRD | F-PRD-006 | 所属工厂 | 06-production/00-overview.md |
| production:material-issue:view | PRD | F-PRD-006 |  | 06-production/00-overview.md |
| production:mrp:confirm | PRD | F-PRD-010 |  | 06-production/00-overview.md |
| production:mrp:run | PRD | F-PRD-010 |  | 06-production/00-overview.md |
| production:mrp:view | PRD | F-PRD-010 |  | 06-production/00-overview.md |
| production:ncr:approve | PRD | F-PRD-014（特采・报废） | 全社 | 06-production/00-overview.md |
| production:ncr:create | PRD | F-PRD-014 |  | 06-production/00-overview.md |
| production:outsourcing:approve | PRD | F-PRD-009 | 全社 | 06-production/00-overview.md |
| production:outsourcing:create | PRD | F-PRD-009 |  | 06-production/00-overview.md |
| production:outsourcing:settle | PRD | F-PRD-009 |  | 06-production/00-overview.md |
| production:outsourcing:view | PRD | F-PRD-009 |  | 06-production/00-overview.md |
| production:param:update | PRD | F-PRD-020 | 全社 | 06-production/00-overview.md |
| production:plan:update | PRD | F-PRD-011 |  | 06-production/00-overview.md |
| production:report:view | PRD | F-PRD-017 |  | 06-production/00-overview.md |
| production:routing:update | PRD | F-PRD-003 |  | 06-production/00-overview.md |
| production:routing:view | PRD | F-PRD-003 |  | 06-production/00-overview.md |
| production:trace:view | PRD | F-PRD-015 |  | 06-production/00-overview.md |
| production:work-center:update | PRD | F-PRD-004 |  | 06-production/00-overview.md |
| production:work-center:view | PRD | F-PRD-004 |  | 06-production/00-overview.md |
| production:work-order:approve | PRD | F-PRD-005 | 所属工厂 | 06-production/00-overview.md |
| production:work-order:close | PRD | F-PRD-005/F-PRD-020 | 所属工厂 | 06-production/00-overview.md |
| production:work-order:create | PRD | F-PRD-005 |  | 06-production/00-overview.md |
| production:work-order:release | PRD | F-PRD-005 |  | 06-production/00-overview.md |
| production:work-order:update | PRD | F-PRD-005 | 所属工厂（10/25 状态のみ） | 06-production/00-overview.md |
| production:work-order:view | PRD | F-PRD-005 |  | 06-production/00-overview.md |
| production:work-report:approve | PRD | F-PRD-007 | 所属车间 | 06-production/00-overview.md |
| production:work-report:create | PRD | F-PRD-007 |  | 06-production/00-overview.md |
| production:work-report:view | PRD | F-PRD-007 |  | 06-production/00-overview.md |
| purchase:ap:view | PUR | F-PUR-020 |  | 04-purchase/00-overview.md |
| purchase:invoice:cancel | PUR | 发票取消 | 全社 | 04-purchase/00-overview.md |
| purchase:invoice:create | PUR | F-PUR-017 |  | 04-purchase/00-overview.md |
| purchase:invoice:view | PUR | F-PUR-018 |  | 04-purchase/00-overview.md |
| purchase:invoice:view/create/cancel、purchase:match:view/run/approve | PUR |  |  | 04-purchase/91-api-design.md |
| purchase:match:approve | PUR | 差异承认 | 全社 | 04-purchase/00-overview.md |
| purchase:match:run | PUR | 三单匹配执行 | 全社 | 04-purchase/00-overview.md |
| purchase:match:view | PUR | 三单匹配照会 | 全社 | 04-purchase/00-overview.md |
| purchase:order:approve | PUR | F-PUR-008 |  | 04-purchase/00-overview.md |
| purchase:order:cancel | PUR | 订单取消・关闭 | 全社 | 04-purchase/00-overview.md |
| purchase:order:change | PUR | F-PUR-009 |  | 04-purchase/00-overview.md |
| purchase:order:create | PUR | F-PUR-007/008/010 |  | 04-purchase/00-overview.md |
| purchase:order:print | PUR | 发注书打印（PRT-PUR-003） | 全社 | 04-purchase/00-overview.md |
| purchase:order:send | PUR | 発注送信 | 全社 | 04-purchase/00-overview.md |
| purchase:order:submit | PUR | 订单提出・撤回 | 本人 | 04-purchase/00-overview.md |
| purchase:order:update | PUR | 订单修正（草稿） | 本人 | 04-purchase/00-overview.md |
| purchase:order:view | PUR | F-PUR-007 |  | 04-purchase/00-overview.md |
| purchase:order:view/create/update/submit/approve/change/send/cancel/print | PUR |  |  | 04-purchase/91-api-design.md |
| purchase:param:manage | PUR | 容差规则・参数维护 | 全社 | 04-purchase/00-overview.md |
| purchase:payment:approve | PUR | 付款申请承认（FIN 側） | 承認経路 | 04-purchase/00-overview.md |
| purchase:payment:create | PUR | F-PUR-021 |  | 04-purchase/00-overview.md |
| purchase:payment:create/approve | PUR |  |  | 04-purchase/91-api-design.md |
| purchase:performance:calculate | PUR | 绩效再計算 | 全社 | 04-purchase/00-overview.md |
| purchase:performance:view | PUR | F-PUR-026 |  | 04-purchase/00-overview.md |
| purchase:plan:convert | PUR | 计划建议转请购 | 全社 | 04-purchase/00-overview.md |
| purchase:plan:view | PUR | F-PUR-025 |  | 04-purchase/00-overview.md |
| purchase:price:view | PUR | F-PUR-024 |  | 04-purchase/00-overview.md |
| purchase:receipt:cancel | PUR | 收货取消（未確認） | 倉庫 | 04-purchase/00-overview.md |
| purchase:receipt:create | PUR | F-PUR-011 |  | 04-purchase/00-overview.md |
| purchase:receipt:override | PUR | 超收例外承认 | 全社 | 04-purchase/00-overview.md |
| purchase:receipt:print | PUR | 入荷検収書打印（PRT-PUR-004） | 倉庫 | 04-purchase/00-overview.md |
| purchase:receipt:view | PUR | F-PUR-011 |  | 04-purchase/00-overview.md |
| purchase:receipt:view/create/cancel/override/print | PUR |  |  | 04-purchase/91-api-design.md |
| purchase:report:export | PUR | 采購报表导出 | 全社/部門 | 04-purchase/00-overview.md |
| purchase:report:view | PUR | F-PUR-027 |  | 04-purchase/00-overview.md |
| purchase:requisition:approve | PUR | F-PUR-002 |  | 04-purchase/00-overview.md |
| purchase:requisition:cancel | PUR | 请购取消 | 自部門 | 04-purchase/00-overview.md |
| purchase:requisition:convert | PUR | 请购转订单 | 全社 | 04-purchase/00-overview.md |
| purchase:requisition:create | PUR | F-PUR-001/002/003 |  | 04-purchase/00-overview.md |
| purchase:requisition:print | PUR | 请购单打印（PRT-PUR-001） | 自部門 | 04-purchase/00-overview.md |
| purchase:requisition:submit | PUR | 请购提出・撤回 | 本人 | 04-purchase/00-overview.md |
| purchase:requisition:update | PUR | 请购修正（草稿/差戻し） | 自部門・本人 | 04-purchase/00-overview.md |
| purchase:requisition:view | PUR | F-PUR-001 |  | 04-purchase/00-overview.md |
| purchase:requisition:view/create/update/submit/approve/cancel/convert/print | PUR |  |  | 04-purchase/91-api-design.md |
| purchase:return:approve | PUR | 退货承认 | 承認経路 | 04-purchase/00-overview.md |
| purchase:return:create | PUR | F-PUR-015 |  | 04-purchase/00-overview.md |
| purchase:return:print | PUR | 退货单打印（PRT-PUR-005） | 全社 | 04-purchase/00-overview.md |
| purchase:return:ship | PUR | F-PUR-016 |  | 04-purchase/00-overview.md |
| purchase:return:view | PUR | 退货照会 | 全社 | 04-purchase/00-overview.md |
| purchase:return:view/create/approve/ship/print | PUR |  |  | 04-purchase/91-api-design.md |
| purchase:rfq:create | PUR | F-PUR-004 |  | 04-purchase/00-overview.md |
| purchase:rfq:print | PUR | 比价表打印（PRT-PUR-002） | 全社 | 04-purchase/00-overview.md |
| purchase:rfq:quote | PUR | F-PUR-005 |  | 04-purchase/00-overview.md |
| purchase:rfq:select | PUR | 比价中选确定 | 全社 | 04-purchase/00-overview.md |
| purchase:rfq:view | PUR | F-PUR-004 |  | 04-purchase/00-overview.md |
| purchase:rfq:view/create/quote/select/print | PUR |  |  | 04-purchase/91-api-design.md |
| purchase:statement:confirm | PUR | 对账单确认 | 全社 | 04-purchase/00-overview.md |
| purchase:statement:export | PUR | 对账单导出 | 全社 | 04-purchase/00-overview.md |
| purchase:statement:view | PUR | F-PUR-019 |  | 04-purchase/00-overview.md |
| purchase:statement:view/confirm | PUR |  |  | 04-purchase/91-api-design.md |
| purchase:tracking:followup | PUR | 催货记录登録 | 全社 | 04-purchase/00-overview.md |
| purchase:tracking:view | PUR | F-PUR-023 |  | 04-purchase/00-overview.md |
| purchase:tracking:view/followup、purchase:price:view、purchase:plan:view/convert、purchase:performance:view/calculate、purchase:report:view/export | PUR |  |  | 04-purchase/91-api-design.md |
| report:analysis:export | RPT | F-RPT-009 |  | 10-analytics/00-overview.md |
| report:analysis:view | RPT | F-RPT-003/004/009 |  | 10-analytics/00-overview.md |
| report:analysis:view（部門範囲） | RPT | F-RPT-003、004、005、006 |  | 10-analytics/00-overview.md |
| report:audit:view | RPT | F-RPT-007 | 全社 | 10-analytics/00-overview.md |
| report:dashboard:update | RPT | F-RPT-001 |  | 10-analytics/00-overview.md |
| report:dashboard:view | RPT | F-RPT-001 |  | 10-analytics/00-overview.md |
| report:dashboard:view、report:analysis:view | RPT | F-RPT-001、003 |  | 10-analytics/00-overview.md |
| report:etl:*、report:kpi:update | RPT | F-RPT-002、008 |  | 10-analytics/00-overview.md |
| report:etl:view | RPT | F-RPT-008 |  | 10-analytics/00-overview.md |
| report:etl:view/run | RPT | F-RPT-008 | 全社 | 10-analytics/00-overview.md |
| report:finance:view | RPT | F-RPT-003、007 |  | 10-analytics/00-overview.md |
| report:inventory:view | RPT | F-RPT-004 |  | 10-analytics/00-overview.md |
| report:kpi:update | RPT | F-RPT-002 |  | 10-analytics/00-overview.md |
| report:kpi:update、report:warning:view | RPT | F-RPT-002、006、005 |  | 10-analytics/00-overview.md |
| report:kpi:view | RPT | F-RPT-002 |  | 10-analytics/00-overview.md |
| report:kpi:view、report:audit:view | RPT | F-RPT-002、007 |  | 10-analytics/00-overview.md |
| report:production:view | RPT | F-RPT-003 |  | 10-analytics/00-overview.md |
| report:production:view、report:inventory:view | RPT | F-RPT-004、005 |  | 10-analytics/00-overview.md |
| report:purchase:view | RPT | F-RPT-003 |  | 10-analytics/00-overview.md |
| report:quality:view | RPT | F-RPT-007 |  | 10-analytics/00-overview.md |
| report:sales:view | RPT | F-RPT-003 |  | 10-analytics/00-overview.md |
| report:subscription:update | RPT | F-RPT-006 |  | 10-analytics/00-overview.md |
| report:subscription:view | RPT | F-RPT-006 |  | 10-analytics/00-overview.md |
| report:subscription:view/update | RPT | F-RPT-006 | 本人/全社 | 10-analytics/00-overview.md |
| report:warning:update | RPT | F-RPT-005 |  | 10-analytics/00-overview.md |
| report:warning:view | RPT | F-RPT-005 |  | 10-analytics/00-overview.md |
| sales:credit:approve | SAL | F-SAL-010 | 承認経路該当者 | 03-sales/00-overview.md |
| sales:credit:approve、sales:invoice:approve | SAL | F-SAL-007/010 |  | 03-sales/00-overview.md |
| sales:credit:submit | SAL | F-SAL-010 |  | 03-sales/00-overview.md |
| sales:credit:view | SAL | F-SAL-010 |  | 03-sales/00-overview.md |
| sales:credit:view、sales:statement:confirm | SAL | F-SAL-008/009/010 |  | 03-sales/00-overview.md |
| sales:delivery:cancel | SAL | F-SAL-005 | 未出荷 DN | 03-sales/00-overview.md |
| sales:delivery:confirm | SAL | F-SAL-005 |  | 03-sales/00-overview.md |
| sales:delivery:create | SAL | F-SAL-005 |  | 03-sales/00-overview.md |
| sales:delivery:pick | SAL | F-SAL-005 |  | 03-sales/00-overview.md |
| sales:delivery:pick/confirm、sales:return:receive | SAL | F-SAL-005/006 |  | 03-sales/00-overview.md |
| sales:delivery:print | SAL | F-SAL-005 |  | 03-sales/00-overview.md |
| sales:delivery:view | SAL | F-SAL-005 |  | 03-sales/00-overview.md |
| sales:exchange:create | SAL | F-SAL-014 |  | 03-sales/00-overview.md |
| sales:export:update | SAL | F-SAL-016 |  | 03-sales/00-overview.md |
| sales:forecast:create | SAL | F-SAL-013 |  | 03-sales/00-overview.md |
| sales:forecast:view | SAL | F-SAL-013 |  | 03-sales/00-overview.md |
| sales:inquiry:*、sales:quotation:*、sales:order:create/update/submit、sales:delivery:create、sales:invoice-application:create | SAL | F-SAL-001〜007 |  | 03-sales/00-overview.md |
| sales:inquiry:create | SAL | F-SAL-001 |  | 03-sales/00-overview.md |
| sales:inquiry:view | SAL | F-SAL-001 |  | 03-sales/00-overview.md |
| sales:invoice-application:create | SAL | F-SAL-007 |  | 03-sales/00-overview.md |
| sales:invoice-application:view | SAL | F-SAL-007 |  | 03-sales/00-overview.md |
| sales:invoice:approve | SAL | F-SAL-007 | 承認経路該当者 | 03-sales/00-overview.md |
| sales:invoice:create | SAL | F-SAL-007 |  | 03-sales/00-overview.md |
| sales:invoice:create、sales:statement:create | SAL | F-SAL-007/008 |  | 03-sales/00-overview.md |
| sales:invoice:red | SAL | F-SAL-007 | 発票済 | 03-sales/00-overview.md |
| sales:invoice:view | SAL | F-SAL-007 |  | 03-sales/00-overview.md |
| sales:order:approve | SAL | F-SAL-003 |  | 03-sales/00-overview.md |
| sales:order:approve、sales:price-override:approve | SAL | F-SAL-003/010/011 |  | 03-sales/00-overview.md |
| sales:order:approve、sales:quotation:approve | SAL | F-SAL-002/003/012 |  | 03-sales/00-overview.md |
| sales:order:approve（高額） | SAL | F-SAL-003/010/011 |  | 03-sales/00-overview.md |
| sales:order:cancel | SAL | F-SAL-017 | 承認済・未出荷 | 03-sales/00-overview.md |
| sales:order:change | SAL | F-SAL-004 | 承認済受注 | 03-sales/00-overview.md |
| sales:order:create | SAL | F-SAL-003 |  | 03-sales/00-overview.md |
| sales:order:export | SAL | F-SAL-003/012/015 | データ範囲内 | 03-sales/00-overview.md |
| sales:order:update | SAL | F-SAL-004 |  | 03-sales/00-overview.md |
| sales:order:view | SAL | F-SAL-003 |  | 03-sales/00-overview.md |
| sales:price-override:approve | SAL | F-SAL-011 | 承認経路該当者 | 03-sales/00-overview.md |
| sales:price-override:create | SAL | F-SAL-011 |  | 03-sales/00-overview.md |
| sales:price-override:view | SAL | F-SAL-011 |  | 03-sales/00-overview.md |
| sales:price:view | SAL | F-SAL-011 |  | 03-sales/00-overview.md |
| sales:quotation:approve | SAL | F-SAL-002 | 承認経路該当者 | 03-sales/00-overview.md |
| sales:quotation:convert | SAL | F-SAL-002 | 有効报价单 | 03-sales/00-overview.md |
| sales:quotation:create | SAL | F-SAL-002 |  | 03-sales/00-overview.md |
| sales:quotation:view | SAL | F-SAL-002 |  | 03-sales/00-overview.md |
| sales:receivable:view | SAL | F-SAL-009 |  | 03-sales/00-overview.md |
| sales:report:view | SAL | F-SAL-015 |  | 03-sales/00-overview.md |
| sales:return:approve | SAL | F-SAL-006 | 承認経路該当者 | 03-sales/00-overview.md |
| sales:return:approve、sales:invoice:approve | SAL | F-SAL-006/007/008/010 |  | 03-sales/00-overview.md |
| sales:return:create | SAL | F-SAL-006 |  | 03-sales/00-overview.md |
| sales:return:inspect | SAL | F-SAL-006 |  | 03-sales/00-overview.md |
| sales:return:receive | SAL | F-SAL-006 | 倉庫担当範囲 | 03-sales/00-overview.md |
| sales:return:view | SAL | F-SAL-006 |  | 03-sales/00-overview.md |
| sales:statement:create | SAL | F-SAL-008 |  | 03-sales/00-overview.md |
| sales:statement:view | SAL | F-SAL-008 |  | 03-sales/00-overview.md |
| sales:tracking:view | SAL | F-SAL-012 |  | 03-sales/00-overview.md |
| system:* | SAL | — |  | 03-sales/00-overview.md |
| system:attachment:view | SYS | F-SYS-010 |  | 01-system/00-overview.md |
| system:audit-log:view | SYS | F-SYS-009 |  | 01-system/00-overview.md |
| system:audit-log:view/export、system:login-log:view | SYS | F-SYS-009 |  | 01-system/00-overview.md |
| system:audit-log:view（モジュール=finance） | SYS | F-SYS-009 |  | 01-system/00-overview.md |
| system:auth:login | SYS | F-SYS-001 | 本人 | 01-system/00-overview.md |
| system:company:view | SYS | F-SYS-014 |  | 01-system/00-overview.md |
| system:department:view | SYS | F-SYS-005 |  | 01-system/00-overview.md |
| system:dict:update | SYS | F-SYS-007 |  | 01-system/00-overview.md |
| system:dict:view | SYS | F-SYS-007 |  | 01-system/00-overview.md |
| system:job-monitor:view | SYS | F-SYS-016 |  | 01-system/00-overview.md |
| system:job:view | SYS | F-SYS-013 |  | 01-system/00-overview.md |
| system:login-log:view | SYS | F-SYS-009 |  | 01-system/00-overview.md |
| system:maintenance:view | SYS | F-SYS-020 |  | 01-system/00-overview.md |
| system:menu:view | SYS | F-SYS-004 |  | 01-system/00-overview.md |
| system:notification-log:view | SYS | F-SYS-019 |  | 01-system/00-overview.md |
| system:notification-template:view | SYS | F-SYS-019 |  | 01-system/00-overview.md |
| system:notification:view | SYS | F-SYS-011 |  | 01-system/00-overview.md |
| system:number-rule:view | SYS | F-SYS-012 |  | 01-system/00-overview.md |
| system:online-user:*、system:job:*、system:maintenance:* | SYS | F-SYS-016、020 |  | 01-system/00-overview.md |
| system:online-user:view | SYS | F-SYS-016 |  | 01-system/00-overview.md |
| system:param:view | SYS | F-SYS-008 |  | 01-system/00-overview.md |
| system:position:view | SYS | F-SYS-006 |  | 01-system/00-overview.md |
| system:print-template:view | SYS | F-SYS-015 |  | 01-system/00-overview.md |
| system:profile:update | SYS | F-SYS-001 |  | 01-system/00-overview.md |
| system:profile:view | SYS | F-SYS-018 |  | 01-system/00-overview.md |
| system:profile:view/update、system:notification:view | SYS | F-SYS-001、010、011、018 |  | 01-system/00-overview.md |
| system:role-grant:approve | SYS | F-SYS-003 | 全社 | 01-system/00-overview.md |
| system:role-grant:approve、system:audit-log:view | SYS | F-SYS-003、009 |  | 01-system/00-overview.md |
| system:role:create/update | SYS | F-SYS-003 |  | 01-system/00-overview.md |
| system:role:view | SYS | F-SYS-003 |  | 01-system/00-overview.md |
| system:tenant:view | SYS | F-SYS-017 |  | 01-system/00-overview.md |
| system:user-role:update | SYS | F-SYS-003 |  | 01-system/00-overview.md |
| system:user:*、system:role:*、system:menu:*、system:param:* | SYS | F-SYS-002〜020 |  | 01-system/00-overview.md |
| system:user:create/update | SYS | F-SYS-002 |  | 01-system/00-overview.md |
| system:user:create/update/disable、system:department:*、system:position:* | SYS | F-SYS-002、005、006 |  | 01-system/00-overview.md |
| system:user:view | SYS | F-SYS-002 |  | 01-system/00-overview.md |
| system:user:view（データ範囲=部門）、system:user-request:submit/approve | SYS | F-SYS-002、009 |  | 01-system/00-overview.md |
| workflow:delegation:admin | WF | F-WF-007 | 全社 | 08-workflow/00-overview.md |
| workflow:delegation:update | WF | F-WF-007 |  | 08-workflow/00-overview.md |
| workflow:field-permission:update | WF | F-WF-010 |  | 08-workflow/00-overview.md |
| workflow:instance:manage | WF | F-WF-009 | 全社 | 08-workflow/00-overview.md |
| workflow:instance:submit | WF | F-WF-003 |  | 08-workflow/00-overview.md |
| workflow:instance:view | WF | F-WF-009 |  | 08-workflow/00-overview.md |
| workflow:mapping:update | WF | F-WF-002 |  | 08-workflow/00-overview.md |
| workflow:mapping:view | WF | F-WF-002 |  | 08-workflow/00-overview.md |
| workflow:monitor:view | WF | F-WF-006/009 |  | 08-workflow/00-overview.md |
| workflow:process:*、workflow:instance:* | WF | F-WF-001/002/009 | 流程定義・マッピング・インスタンス管理 | 08-workflow/00-overview.md |
| workflow:process:deploy | WF | F-WF-001 | 全社 | 08-workflow/00-overview.md |
| workflow:process:update | WF | F-WF-001 |  | 08-workflow/00-overview.md |
| workflow:process:view | WF | F-WF-001 |  | 08-workflow/00-overview.md |
| workflow:task:approve | WF | F-WF-004〜006 | 部門内の申請（金額閾値内） | 08-workflow/00-overview.md |
| workflow:task:urge | WF | F-WF-005 | 本人が申請したプロセス | 08-workflow/00-overview.md |
| workflow:task:view | WF | F-WF-003/004/007 | 申請・待办参照・委任設定 | 08-workflow/00-overview.md |
| workflow:timeout:update | WF | F-WF-008 |  | 08-workflow/00-overview.md |

## 改訂履歴

| 版数 | 日付 | 変更内容 | 変更者 |
|---|---|---|---|
| v1.0 | 2026-10-20 | 自动生成 | gen_matrix.py |
