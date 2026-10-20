# 画面一覧（画面一览）

| 項目 | 内容 |
|---|---|
| 文書名 | 画面一覧（画面一览）（自动生成） |
| 文書番号 | DSN-MTX-002 |
| 版数 | v1.0 |
| 作成日 | 2026-10-20 |
| 作成者 | Lead（生成工具 gen_matrix.py） |
| 状態 | ドラフト（自动生成・最終レビュー前） |
| 備考 | 全 339 件。画面ID/名称/類型/機能/権限/域/提取元 |

> 本文件由 `20-matrix/tools/gen_matrix.py` 从各域设计书中自动提取生成。修改设计书后重新运行即可更新。

| 画面 ID | 画面名 | 類型 | 機能 ID | 権限コード | 域 | 提取元 |
|---|---|---|---|---|---|---|
| SCR-FIN-001 | 会计科目一覧 | LIST | F-FIN-001 | finance:account:view | FIN | 07-finance/00-overview.md |
| SCR-FIN-002 | 会计科目登録編集 | EDIT | F-FIN-001 | finance:account:create/update | FIN | 07-finance/00-overview.md |
| SCR-FIN-003 | 期初余额录入 | EDIT | F-FIN-002 | finance:opening-balance:import | FIN | 07-finance/00-overview.md |
| SCR-FIN-004 | 科目辅助核算设置 | EDIT | F-FIN-002 | finance:account:update | FIN | 07-finance/00-overview.md |
| SCR-FIN-005 | 记账凭证录入 | EDIT | F-FIN-003 | finance:voucher:create | FIN | 07-finance/00-overview.md |
| SCR-FIN-006 | 凭证一覧 | LIST | F-FIN-003/009 | finance:voucher:view | FIN | 07-finance/00-overview.md |
| SCR-FIN-007 | 凭证模板管理 | LIST/EDIT | F-FIN-004 | finance:voucher-template:view/update | FIN | 07-finance/00-overview.md |
| SCR-FIN-008 | 凭证待审核一覧 | LIST | F-FIN-005 | finance:voucher:approve | FIN | 07-finance/00-overview.md |
| SCR-FIN-009 | 凭证审核详细 | VIEW | F-FIN-005 | finance:voucher:approve | FIN | 07-finance/00-overview.md |
| SCR-FIN-010 | 凭证记账处理 | LIST | F-FIN-006 | finance:voucher:post | FIN | 07-finance/00-overview.md |
| SCR-FIN-011 | 凭证反记账 | LIST/EDIT | F-FIN-007 | finance:voucher:unpost | FIN | 07-finance/00-overview.md |
| SCR-FIN-012 | 红字冲销凭证 | EDIT | F-FIN-008 | finance:voucher:reverse | FIN | 07-finance/00-overview.md |
| SCR-FIN-013 | 凭证查询与附件 | VIEW | F-FIN-009 | finance:voucher:view | FIN | 07-finance/00-overview.md |
| SCR-FIN-014 | 总账查询 | LIST | F-FIN-010 | finance:ledger:view | FIN | 07-finance/00-overview.md |
| SCR-FIN-015 | 明细账查询 | LIST | F-FIN-010 | finance:ledger:view | FIN | 07-finance/00-overview.md |
| SCR-FIN-016 | 序时账（日记账） | LIST | F-FIN-010 | finance:ledger:view | FIN | 07-finance/00-overview.md |
| SCR-FIN-017 | 试算平衡表 | LIST | F-FIN-011/039 | finance:trial-balance:view | FIN | 07-finance/00-overview.md |
| SCR-FIN-018 | 应付单一覧 | LIST | F-FIN-012 | finance:payable:view | FIN | 07-finance/00-overview.md |
| SCR-FIN-019 | 应付单确认/详细 | EDIT/VIEW | F-FIN-012 | finance:payable:update | FIN | 07-finance/00-overview.md |
| SCR-FIN-020 | 采购发票三单匹配 | EDIT | F-FIN-013 | finance:invoice:match | FIN | 07-finance/00-overview.md |
| SCR-FIN-021 | 暂估余额与冲回 | LIST | F-FIN-014 | finance:payable:view | FIN | 07-finance/00-overview.md |
| SCR-FIN-022 | 付款申请 | EDIT | F-FIN-015 | finance:payment-request:create | FIN | 07-finance/00-overview.md |
| SCR-FIN-023 | 付款执行 | EDIT | F-FIN-016 | finance:payment:execute | FIN | 07-finance/00-overview.md |
| SCR-FIN-024 | 应付核销 | EDIT | F-FIN-017 | finance:write-off:create | FIN | 07-finance/00-overview.md |
| SCR-FIN-025 | 应付账龄分析 | 照会 | F-FIN-018 | finance:aging:view | FIN | 07-finance/00-overview.md |
| SCR-FIN-026 | 应收单一覧 | LIST | F-FIN-019 | finance:receivable:view | FIN | 07-finance/00-overview.md |
| SCR-FIN-027 | 收款登记 | EDIT | F-FIN-020 | finance:receipt:create | FIN | 07-finance/00-overview.md |
| SCR-FIN-028 | 应收核销 | EDIT | F-FIN-021 | finance:write-off:create | FIN | 07-finance/00-overview.md |
| SCR-FIN-029 | 应收账龄分析 | 照会 | F-FIN-022 | finance:aging:view | FIN | 07-finance/00-overview.md |
| SCR-FIN-030 | 坏账准备计提（P2） | LIST | F-FIN-022 | finance:receivable:update | FIN | 07-finance/00-overview.md |
| SCR-FIN-031 | 现金日记账 | LIST | F-FIN-023 | finance:cash-journal:view | FIN | 07-finance/00-overview.md |
| SCR-FIN-032 | 银行日记账 | LIST | F-FIN-024 | finance:bank-journal:view | FIN | 07-finance/00-overview.md |
| SCR-FIN-033 | 银行对账单导入 | EDIT | F-FIN-024 | finance:bank-statement:import | FIN | 07-finance/00-overview.md |
| SCR-FIN-034 | 银行对账 | EDIT | F-FIN-024 | finance:bank-recon:execute | FIN | 07-finance/00-overview.md |
| SCR-FIN-035 | 余额调节表 | 帳票 | F-FIN-024 | finance:bank-recon:view | FIN | 07-finance/00-overview.md |
| SCR-FIN-036 | 资金日报 | DASH | F-FIN-025 | finance:fund-report:view | FIN | 07-finance/00-overview.md |
| SCR-FIN-037 | 进项发票台账 | LIST | F-FIN-026 | finance:invoice:view | FIN | 07-finance/00-overview.md |
| SCR-FIN-038 | 销项发票台账 | LIST | F-FIN-026 | finance:invoice:view | FIN | 07-finance/00-overview.md |
| SCR-FIN-039 | 增值税申报辅助表 | 照会/帳票 | F-FIN-027 | finance:vat-return:view | FIN | 07-finance/00-overview.md |
| SCR-FIN-040 | 附加税/所得税计提 | EDIT | F-FIN-028 | finance:tax-accrual:generate | FIN | 07-finance/00-overview.md |
| SCR-FIN-041 | 自动凭证规则管理 | LIST/EDIT | F-FIN-029 | finance:auto-voucher:view/update | FIN | 07-finance/00-overview.md |
| SCR-FIN-042 | 自动凭证监控 | LIST | F-FIN-030 | finance:auto-voucher:view | FIN | 07-finance/00-overview.md |
| SCR-FIN-043 | 成本计算 | WIZ | F-FIN-031 | finance:cost:calculate | FIN | 07-finance/00-overview.md |
| SCR-FIN-044 | 成本计算结果 | VIEW | F-FIN-031 | finance:cost:view | FIN | 07-finance/00-overview.md |
| SCR-FIN-045 | 制造费用归集与分配 | EDIT | F-FIN-032 | finance:cost:calculate | FIN | 07-finance/00-overview.md |
| SCR-FIN-046 | 在制品与完工成本 | LIST | F-FIN-033 | finance:cost:view | FIN | 07-finance/00-overview.md |
| SCR-FIN-047 | 成本差异分析 | 照会 | F-FIN-034 | finance:cost:view | FIN | 07-finance/00-overview.md |
| SCR-FIN-048 | 会计期间管理 | LIST | F-FIN-035 | finance:period:view/close | FIN | 07-finance/00-overview.md |
| SCR-FIN-049 | 月结向导 | WIZ | F-FIN-035/036 | finance:period:close | FIN | 07-finance/00-overview.md |
| SCR-FIN-050 | 损益结转 | EDIT | F-FIN-036 | finance:period:close | FIN | 07-finance/00-overview.md |
| SCR-FIN-051 | 年度结转 | WIZ | F-FIN-037 | finance:year-close:execute | FIN | 07-finance/00-overview.md |
| SCR-FIN-052 | 财务报表（三表） | 照会/帳票 | F-FIN-038 | finance:statement:view | FIN | 07-finance/00-overview.md |
| SCR-FIN-053 | 科目余额表 | 照会/帳票 | F-FIN-039 | finance:report:view | FIN | 07-finance/00-overview.md |
| SCR-FIN-054 | 费用报销（P2） | EDIT | F-FIN-040 | finance:expense:create | FIN | 07-finance/00-overview.md |
| SCR-FIN-055 | 借款/还款（P2） | EDIT | F-FIN-040 | finance:expense:create | FIN | 07-finance/00-overview.md |
| SCR-FIN-056 | 固定资产卡片（P2） | LIST/EDIT | F-FIN-041 | finance:asset:view/update | FIN | 07-finance/00-overview.md |
| SCR-FIN-057 | 固定资产处置（P2） | EDIT | F-FIN-042 | finance:asset:dispose | FIN | 07-finance/00-overview.md |
| SCR-FIN-058 | 预算管理（P2） | EDIT | F-FIN-043 | finance:budget:update | FIN | 07-finance/00-overview.md |
| SCR-FIN-059 | 汇兑损益调整（P2） | EDIT | F-FIN-044 | finance:voucher:create | FIN | 07-finance/00-overview.md |
| SCR-FIN-060 | 资金计划与付款排程（P2） | LIST | F-FIN-045 | finance:fund-report:view | FIN | 07-finance/00-overview.md |
| SCR-FIN-061 | 财务报表分析（P2） | DASH | F-FIN-046 | finance:statement:view | FIN | 07-finance/00-overview.md |
| SCR-INT-001 | 接口配置一覧 | LIST | F-INT-001 | integration:interface-config:view | INT | 09-integration/00-overview.md |
| SCR-INT-002 | 接口配置登録編集 | EDIT | F-INT-001 | integration:interface-config:create | INT | 09-integration/00-overview.md |
| SCR-INT-003 | 接続テスト/実行結果 | VIEW | F-INT-001 | integration:interface-config:test | INT | 09-integration/00-overview.md |
| SCR-INT-004 | 同步監視ダッシュボード | DASH | F-INT-013 | integration:sync-task:view | INT | 09-integration/00-overview.md |
| SCR-INT-005 | 同期タスク一覧（失敗・滞留） | LIST | F-INT-013 | integration:sync-task:view | INT | 09-integration/00-overview.md |
| SCR-INT-006 | 手動再送/再処理 | EDIT | F-INT-013 | integration:sync-task:retry | INT | 09-integration/00-overview.md |
| SCR-INT-007 | 接口呼出日志 | LIST | F-INT-014 | integration:call-log:view | INT | 09-integration/00-overview.md |
| SCR-INT-008 | 数电票発行一覧 | LIST | F-INT-002 | integration:tax-invoice:view | INT | 09-integration/00-overview.md |
| SCR-INT-009 | 数电票詳細・赤伝 | EDIT | F-INT-002 | integration:tax-invoice:create | INT | 09-integration/00-overview.md |
| SCR-INT-010 | 進項発票査験一覧 | LIST | F-INT-003 | integration:input-invoice:view | INT | 09-integration/00-overview.md |
| SCR-INT-011 | 銀企口座残高一覧 | DASH | F-INT-004 | integration:bank-account:view | INT | 09-integration/00-overview.md |
| SCR-INT-012 | 付款指令一覧 | LIST | F-INT-004 | integration:bank-payment:view | INT | 09-integration/00-overview.md |
| SCR-INT-013 | 付款指令詳細・回单 | EDIT | F-INT-004 | integration:bank-payment:create | INT | 09-integration/00-overview.md |
| SCR-INT-014 | 銀行対账单取込 | WIZ | F-INT-005 | integration:bank-statement:import | INT | 09-integration/00-overview.md |
| SCR-INT-015 | 対账单取込結果・FIN 引渡 | VIEW | F-INT-005 | integration:bank-statement:view | INT | 09-integration/00-overview.md |
| SCR-INT-016 | MES/WMS 連携状況 | DASH | F-INT-006/007 | integration:mes:view | INT | 09-integration/00-overview.md |
| SCR-INT-017 | PLM 同期状況 | LIST | F-INT-008 | integration:plm:view | INT | 09-integration/00-overview.md |
| SCR-INT-018 | 開放 API クライアント管理 | LIST | F-INT-009 | integration:api-client:view | INT | 09-integration/00-overview.md |
| SCR-INT-019 | API 利用状況・レート制限 | DASH | F-INT-009 | integration:api-client:view | INT | 09-integration/00-overview.md |
| SCR-INT-020 | 外部ファイル取込ジョブ | LIST | F-INT-011 | integration:file-transfer:view | INT | 09-integration/00-overview.md |
| SCR-INT-021 | 通知チャネル設定 | EDIT | F-INT-012 | integration:notification-channel:update | INT | 09-integration/00-overview.md |
| SCR-INT-022 | 通知送信履歴 | LIST | F-INT-012 | integration:notification-log:view | INT | 09-integration/00-overview.md |
| SCR-INT-023 | PDA 端末管理 | LIST | F-INT-010 | integration:pda-device:view | INT | 09-integration/00-overview.md |
| SCR-INT-024 | 日次対账結果 | LIST | F-INT-014 | integration:reconcile:view | INT | 09-integration/00-overview.md |
| SCR-INV-001 | 库存查询（现存量照会） | 一覧検索 | F-INV-001 | inventory:stock-balance:view | INV | 05-inventory/00-overview.md |
| SCR-INV-002 | 库存事务流水照会 | 一覧検索 | F-INV-013 | inventory:stock-txn:view | INV | 05-inventory/00-overview.md |
| SCR-INV-003 | 库存明细账（台帳） | 一覧検索 | F-INV-013 | inventory:stock-txn:view | INV | 05-inventory/00-overview.md |
| SCR-INV-004 | 采购入库单（GRI）登録 | 登録編集 | F-INV-002 | inventory:stock-txn:create | INV | 05-inventory/00-overview.md |
| SCR-INV-005 | 销售出库单（SDO）登録 | 登録編集 | F-INV-003 | inventory:stock-txn:create | INV | 05-inventory/00-overview.md |
| SCR-INV-006 | 生产领料/退料单（MII/MIR）登録 | 登録編集 | F-INV-004 | inventory:stock-txn:create | INV | 05-inventory/00-overview.md |
| SCR-INV-007 | 生产入库单（FGI）登録 | 登録編集 | F-INV-005 | inventory:stock-txn:create | INV | 05-inventory/00-overview.md |
| SCR-INV-008 | 委外发料/收货单（OSI/OSR）登録 | 登録編集 | F-INV-006 | inventory:stock-txn:create | INV | 05-inventory/00-overview.md |
| SCR-INV-009 | 其他入库单（AOI）登録 | 登録編集 | F-INV-007 | inventory:stock-txn:create | INV | 05-inventory/00-overview.md |
| SCR-INV-010 | 其他出库单（AOO）登録 | 登録編集 | F-INV-008 | inventory:stock-txn:create | INV | 05-inventory/00-overview.md |
| SCR-INV-011 | 库存调拨单（TR）登録 | 登録編集 | F-INV-009 | inventory:transfer:create | INV | 05-inventory/00-overview.md |
| SCR-INV-012 | 调拨在途跟踪 | 一覧検索 | F-INV-009 | inventory:transfer:view | INV | 05-inventory/00-overview.md |
| SCR-INV-013 | 盘点计划登録 | 登録編集 | F-INV-010 | inventory:stocktake:create | INV | 05-inventory/00-overview.md |
| SCR-INV-014 | 盘点单（实盘入力） | 登録編集 | F-INV-010 | inventory:stocktake:enter | INV | 05-inventory/00-overview.md |
| SCR-INV-015 | 盘点差异承认・调整 | 登録編集 | F-INV-010 | inventory:stocktake:approve | INV | 05-inventory/00-overview.md |
| SCR-INV-016 | 批次追溯照会 | 一覧検索 | F-INV-011 | inventory:batch:trace | INV | 05-inventory/00-overview.md |
| SCR-INV-017 | 批次效期预警 | 一覧検索 | F-INV-011 | inventory:batch:view | INV | 05-inventory/00-overview.md |
| SCR-INV-018 | 序列号照会 | 一覧検索 | F-INV-012 | inventory:serial:view | INV | 05-inventory/00-overview.md |
| SCR-INV-019 | 库存状态转换 | 登録編集 | F-INV-014 | inventory:status:change | INV | 05-inventory/00-overview.md |
| SCR-INV-020 | 库龄・呆滞分析 | 一覧検索 | F-INV-015、021 | inventory:report:view | INV | 05-inventory/00-overview.md |
| SCR-INV-021 | 安全库存・补货建议 | 一覧検索 | F-INV-016 | inventory:replenishment:view | INV | 05-inventory/00-overview.md |
| SCR-INV-022 | 成本查询（移动平均） | 一覧検索 | F-INV-017 | inventory:cost:view | INV | 05-inventory/00-overview.md |
| SCR-INV-023 | 成本调整单登録 | 登録編集 | F-INV-017 | inventory:cost:adjust | INV | 05-inventory/00-overview.md |
| SCR-INV-024 | 库存预留照会・释放 | 一覧検索 | F-INV-019 | inventory:reservation:view | INV | 05-inventory/00-overview.md |
| SCR-INV-025 | 库存月结执行 | ウィザード | F-INV-020 | inventory:period:close | INV | 05-inventory/00-overview.md |
| SCR-INV-026 | PDA 扫码作業 | ウィザード | F-INV-018 | inventory:barcode:scan | INV | 05-inventory/00-overview.md |
| SCR-MDM-001 | 物料一覧 | 一覧検索 | F-MDM-002 | mdm:material:view | MDM | 02-mdm/00-overview.md |
| SCR-MDM-002 | 物料登録編集 | 登録編集 | F-MDM-002 | mdm:material:create/update | MDM | 02-mdm/00-overview.md |
| SCR-MDM-003 | 物料参照詳細 | 参照詳細 | F-MDM-002 | mdm:material:view | MDM | 02-mdm/00-overview.md |
| SCR-MDM-004 | 物料分类树管理 | 登録編集 | F-MDM-001 | mdm:material-category:update | MDM | 02-mdm/00-overview.md |
| SCR-MDM-005 | 物料编码规则 | 登録編集 | F-MDM-003 | mdm:code-rule:update | MDM | 02-mdm/00-overview.md |
| SCR-MDM-006 | 物料工厂视图設定 | 登録編集 | F-MDM-021 | mdm:material-factory:update | MDM | 02-mdm/00-overview.md |
| SCR-MDM-011 | 客户一覧 | 一覧検索 | F-MDM-004 | mdm:customer:view | MDM | 02-mdm/00-overview.md |
| SCR-MDM-012 | 客户登録編集 | 登録編集 | F-MDM-004 | mdm:customer:create/update | MDM | 02-mdm/00-overview.md |
| SCR-MDM-013 | 客户参照詳細 | 参照詳細 | F-MDM-004 | mdm:customer:view | MDM | 02-mdm/00-overview.md |
| SCR-MDM-014 | 客户联系人管理 | 登録編集 | F-MDM-004 | mdm:customer:update | MDM | 02-mdm/00-overview.md |
| SCR-MDM-015 | 客户收货地址管理 | 登録編集 | F-MDM-004 | mdm:customer:update | MDM | 02-mdm/00-overview.md |
| SCR-MDM-021 | 供应商一覧 | 一覧検索 | F-MDM-005 | mdm:supplier:view | MDM | 02-mdm/00-overview.md |
| SCR-MDM-022 | 供应商登録編集 | 登録編集 | F-MDM-005 | mdm:supplier:create/update | MDM | 02-mdm/00-overview.md |
| SCR-MDM-023 | 供应商参照詳細 | 参照詳細 | F-MDM-005 | mdm:supplier:view | MDM | 02-mdm/00-overview.md |
| SCR-MDM-024 | 供应商资质管理 | 登録編集 | F-MDM-005/015 | mdm:supplier:update | MDM | 02-mdm/00-overview.md |
| SCR-MDM-025 | 供应商供货范围管理 | 登録編集 | F-MDM-005 | mdm:supplier:update | MDM | 02-mdm/00-overview.md |
| SCR-MDM-026 | 供应商准入审查 | ワークフロー | F-MDM-015 | mdm:supplier-admission:approve | MDM | 02-mdm/00-overview.md |
| SCR-MDM-031 | 仓库一覧/登録編集 | 一覧検索/登録編集 | F-MDM-006 | mdm:warehouse:* | MDM | 02-mdm/00-overview.md |
| SCR-MDM-032 | 库区登録編集 | 登録編集 | F-MDM-006 | mdm:warehouse:update | MDM | 02-mdm/00-overview.md |
| SCR-MDM-033 | 库位一覧/登録編集 | 一覧検索/登録編集 | F-MDM-006 | mdm:warehouse:update | MDM | 02-mdm/00-overview.md |
| SCR-MDM-034 | 库位一括生成ウィザード | ウィザード | F-MDM-006 | mdm:warehouse:update | MDM | 02-mdm/00-overview.md |
| SCR-MDM-041 | 计量单位一覧/登録編集 | 一覧検索/登録編集 | F-MDM-007 | mdm:uom:* | MDM | 02-mdm/00-overview.md |
| SCR-MDM-042 | 单位换算组管理 | 登録編集 | F-MDM-007 | mdm:uom:update | MDM | 02-mdm/00-overview.md |
| SCR-MDM-043 | 货币一覧/登録編集 | 一覧検索/登録編集 | F-MDM-008 | mdm:currency:* | MDM | 02-mdm/00-overview.md |
| SCR-MDM-044 | 汇率一覧/登録編集 | 一覧検索/登録編集 | F-MDM-008 | mdm:exchange-rate:* | MDM | 02-mdm/00-overview.md |
| SCR-MDM-045 | 标准代码・汇率导入 | 取込 | F-MDM-024 | mdm:exchange-rate:import | MDM | 02-mdm/00-overview.md |
| SCR-MDM-046 | 税码一覧/登録編集 | 一覧検索/登録編集 | F-MDM-009 | mdm:tax-code:* | MDM | 02-mdm/00-overview.md |
| SCR-MDM-047 | 税率与税收分类编码 | 登録編集 | F-MDM-009 | mdm:tax-code:update | MDM | 02-mdm/00-overview.md |
| SCR-MDM-051 | 销售价格表一覧 | 一覧検索 | F-MDM-010 | mdm:price:view | MDM | 02-mdm/00-overview.md |
| SCR-MDM-052 | 销售价格表登録編集 | 登録編集 | F-MDM-010 | mdm:price:create/update | MDM | 02-mdm/00-overview.md |
| SCR-MDM-053 | 折扣规则管理 | 登録編集 | F-MDM-010 | mdm:price:update | MDM | 02-mdm/00-overview.md |
| SCR-MDM-054 | 采购价格一覧/登録編集 | 一覧検索/登録編集 | F-MDM-011 | mdm:purchase-price:* | MDM | 02-mdm/00-overview.md |
| SCR-MDM-055 | 供应商报价管理 | 登録編集 | F-MDM-011 | mdm:supplier-quotation:* | MDM | 02-mdm/00-overview.md |
| SCR-MDM-056 | 取价模拟与照会 | 照会 | F-MDM-010/011 | mdm:price:view | MDM | 02-mdm/00-overview.md |
| SCR-MDM-061 | 结算方式一覧/登録編集 | 一覧検索/登録編集 | F-MDM-012 | mdm:settlement:* | MDM | 02-mdm/00-overview.md |
| SCR-MDM-062 | 付款条件一覧/登録編集 | 一覧検索/登録編集 | F-MDM-012 | mdm:payment-term:* | MDM | 02-mdm/00-overview.md |
| SCR-MDM-063 | 银行一覧/登録編集 | 一覧検索/登録編集 | F-MDM-013 | mdm:bank:* | MDM | 02-mdm/00-overview.md |
| SCR-MDM-064 | 取引先银行账户管理 | 登録編集 | F-MDM-013 | mdm:bank-account:* | MDM | 02-mdm/00-overview.md |
| SCR-MDM-071 | 客户信用额度一覧/登録編集 | 一覧検索/登録編集 | F-MDM-014 | mdm:credit:* | MDM | 02-mdm/00-overview.md |
| SCR-MDM-072 | 信用检查规则管理 | 登録編集 | F-MDM-014 | mdm:credit:update | MDM | 02-mdm/00-overview.md |
| SCR-MDM-073 | 供应商评估 | 一覧検索/登録編集 | F-MDM-015 | mdm:supplier-eval:* | MDM | 02-mdm/00-overview.md |
| SCR-MDM-074 | 供应商分级/AVL | 照会 | F-MDM-015 | mdm:supplier-eval:view | MDM | 02-mdm/00-overview.md |
| SCR-MDM-081 | 物料替代关系管理 | 登録編集 | F-MDM-016 | mdm:substitute:* | MDM | 02-mdm/00-overview.md |
| SCR-MDM-082 | 条码规则管理 | 登録編集 | F-MDM-017 | mdm:barcode-rule:* | MDM | 02-mdm/00-overview.md |
| SCR-MDM-083 | 条码标签打印 | 帳票プレビュー | F-MDM-017 | mdm:barcode:print | MDM | 02-mdm/00-overview.md |
| SCR-MDM-091 | 主数据变更申请一覧 | 一覧検索 | F-MDM-018 | mdm:change:view | MDM | 02-mdm/00-overview.md |
| SCR-MDM-092 | 主数据变更审批/详细 | ワークフロー | F-MDM-018 | mdm:change:approve | MDM | 02-mdm/00-overview.md |
| SCR-MDM-093 | 主数据变更历史照会 | 一覧検索 | F-MDM-018 | mdm:change:view | MDM | 02-mdm/00-overview.md |
| SCR-MDM-094 | 数据质量校验 | 一覧検索 | F-MDM-019 | mdm:data-quality:* | MDM | 02-mdm/00-overview.md |
| SCR-MDM-095 | 主数据批量维护导入 | ウィザード | F-MDM-019 | mdm:material:import 等 | MDM | 02-mdm/00-overview.md |
| SCR-MDM-096 | 主数据数据权限設定 | 登録編集 | F-MDM-020 | mdm:data-scope:update | MDM | 02-mdm/00-overview.md |
| SCR-MDM-097 | 主数据检索（主数据门户） | 一覧検索 | F-MDM-022 | mdm:portal:view | MDM | 02-mdm/00-overview.md |
| SCR-MDM-098 | 工厂一覧/登録編集 | 一覧検索/登録編集 | F-MDM-025 | mdm:factory:view/update | MDM | 02-mdm/00-overview.md |
| SCR-PRD-001 | BOM 一覧 | 一覧検索 | F-PRD-001 | production:bom:view | PRD | 06-production/00-overview.md |
| SCR-PRD-002 | BOM 登録編集 | 登録編集 | F-PRD-001 | production:bom:update | PRD | 06-production/00-overview.md |
| SCR-PRD-003 | BOM 多阶展开・成本卷算 | 参照詳細 | F-PRD-002 | production:bom:view | PRD | 06-production/00-overview.md |
| SCR-PRD-004 | 工艺路线一覧 | 一覧検索 | F-PRD-003 | production:routing:view | PRD | 06-production/00-overview.md |
| SCR-PRD-005 | 工艺路线登録編集 | 登録編集 | F-PRD-003 | production:routing:update | PRD | 06-production/00-overview.md |
| SCR-PRD-006 | 工作中心一覧・編集 | 一覧検索 | F-PRD-004 | production:work-center:view | PRD | 06-production/00-overview.md |
| SCR-PRD-007 | 工作日历・产能设定 | 登録編集 | F-PRD-004 | production:work-center:update | PRD | 06-production/00-overview.md |
| SCR-PRD-008 | 生产订单一覧 | 一覧検索 | F-PRD-005 | production:work-order:view | PRD | 06-production/00-overview.md |
| SCR-PRD-009 | 生产订单登録編集 | 登録編集 | F-PRD-005 | production:work-order:create | PRD | 06-production/00-overview.md |
| SCR-PRD-010 | 生产订单詳細（工序/用料/报工/入库标签） | 参照詳細 | F-PRD-005 | production:work-order:view | PRD | 06-production/00-overview.md |
| SCR-PRD-011 | 生产订单下达・拆分・合并 | ウィザード | F-PRD-005 | production:work-order:release | PRD | 06-production/00-overview.md |
| SCR-PRD-012 | 生产领料单登録編集 | 登録編集 | F-PRD-006 | production:material-issue:create | PRD | 06-production/00-overview.md |
| SCR-PRD-013 | 领退料一覧 | 一覧検索 | F-PRD-006 | production:material-issue:view | PRD | 06-production/00-overview.md |
| SCR-PRD-014 | 工序报工登録（现场/扫码） | 登録編集 | F-PRD-007 | production:work-report:create | PRD | 06-production/00-overview.md |
| SCR-PRD-015 | 报工一覧・审核 | 一覧検索 | F-PRD-007 | production:work-report:view | PRD | 06-production/00-overview.md |
| SCR-PRD-016 | 生产入库登録 | 登録編集 | F-PRD-008 | production:completion:create | PRD | 06-production/00-overview.md |
| SCR-PRD-017 | 委外订单一覧 | 一覧検索 | F-PRD-009 | production:outsourcing:view | PRD | 06-production/00-overview.md |
| SCR-PRD-018 | 委外订单登録編集 | 登録編集 | F-PRD-009 | production:outsourcing:create | PRD | 06-production/00-overview.md |
| SCR-PRD-019 | 委外发料・收货登録 | 登録編集 | F-PRD-009 | production:outsourcing:create | PRD | 06-production/00-overview.md |
| SCR-PRD-020 | 委外加工费结算 | 登録編集 | F-PRD-009 | production:outsourcing:settle | PRD | 06-production/00-overview.md |
| SCR-PRD-021 | MRP 运行向导 | ウィザード | F-PRD-010 | production:mrp:run | PRD | 06-production/00-overview.md |
| SCR-PRD-022 | MRP 结果（需求/净需求/计划订单/动作消息） | 一覧検索 | F-PRD-010 | production:mrp:view | PRD | 06-production/00-overview.md |
| SCR-PRD-023 | 计划订单确认・转工单/请购 | 一覧検索 | F-PRD-010 | production:mrp:confirm | PRD | 06-production/00-overview.md |
| SCR-PRD-024 | MPS・排产（粗能力） | 登録編集 | F-PRD-011 | production:plan:update | PRD | 06-production/00-overview.md |
| SCR-PRD-025 | 检验标准一覧・編集 | 登録編集 | F-PRD-012 | production:inspection-standard:update | PRD | 06-production/00-overview.md |
| SCR-PRD-026 | 检验单登録（IQC/IPQC/FQC/OQC） | 登録編集 | F-PRD-013 | production:inspection:create | PRD | 06-production/00-overview.md |
| SCR-PRD-027 | 检验一覧・判定 | 一覧検索 | F-PRD-013 | production:inspection:view | PRD | 06-production/00-overview.md |
| SCR-PRD-028 | NCR 登録・处置 | 登録編集 | F-PRD-014 | production:ncr:create | PRD | 06-production/00-overview.md |
| SCR-PRD-029 | 质量追溯查询 | 照会 | F-PRD-015 | production:trace:view | PRD | 06-production/00-overview.md |
| SCR-PRD-030 | 生产进度看板 | ダッシュボード | F-PRD-016 | production:dashboard:view | PRD | 06-production/00-overview.md |
| SCR-PRD-031 | 工时・效率统计 | 一覧検索 | F-PRD-017 | production:report:view | PRD | 06-production/00-overview.md |
| SCR-PRD-032 | 设备台账（Phase 2） | 一覧検索 | F-PRD-018 | production:equipment:view | PRD | 06-production/00-overview.md |
| SCR-PRD-033 | 生产报表 | 帳票プレビュー | F-PRD-019 | production:report:view | PRD | 06-production/00-overview.md |
| SCR-PUR-001 | 请购单一覧 | LIST | F-PUR-001 | purchase:requisition:view | PUR | 04-purchase/00-overview.md |
| SCR-PUR-002 | 请购单登録編集 | EDIT | F-PUR-001/002/003 | purchase:requisition:create | PUR | 04-purchase/00-overview.md |
| SCR-PUR-003 | 请购审批 | WF | F-PUR-002 | purchase:requisition:approve | PUR | 04-purchase/00-overview.md |
| SCR-PUR-004 | 询价比价单一覧 | LIST | F-PUR-004 | purchase:rfq:view | PUR | 04-purchase/00-overview.md |
| SCR-PUR-005 | 询价比价单登録編集 | EDIT | F-PUR-004 | purchase:rfq:create | PUR | 04-purchase/00-overview.md |
| SCR-PUR-006 | 供应商报价登録 | EDIT | F-PUR-005 | purchase:rfq:quote | PUR | 04-purchase/00-overview.md |
| SCR-PUR-007 | 比价表 | VIEW | F-PUR-006 | purchase:rfq:view | PUR | 04-purchase/00-overview.md |
| SCR-PUR-008 | 采购订单一覧 | LIST | F-PUR-007 | purchase:order:view | PUR | 04-purchase/00-overview.md |
| SCR-PUR-009 | 采购订单登録編集 | EDIT | F-PUR-007/008/010 | purchase:order:create | PUR | 04-purchase/00-overview.md |
| SCR-PUR-010 | 采购订单审批 | WF | F-PUR-008 | purchase:order:approve | PUR | 04-purchase/00-overview.md |
| SCR-PUR-011 | 采购订单变更 | EDIT | F-PUR-009 | purchase:order:change | PUR | 04-purchase/00-overview.md |
| SCR-PUR-012 | 收货单一覧 | LIST | F-PUR-011 | purchase:receipt:view | PUR | 04-purchase/00-overview.md |
| SCR-PUR-013 | 收货单登録編集 | EDIT | F-PUR-011 | purchase:receipt:create | PUR | 04-purchase/00-overview.md |
| SCR-PUR-014 | 收货确认与待检跟踪 | VIEW | F-PUR-012 | purchase:receipt:view | PUR | 04-purchase/00-overview.md |
| SCR-PUR-015 | 来料检验判定（IQC） | WF | F-PUR-013 | production:inspection:judge（PRD） | PUR | 04-purchase/00-overview.md |
| SCR-PUR-016 | 采购入库跟踪 | VIEW | F-PUR-014 | purchase:receipt:view | PUR | 04-purchase/00-overview.md |
| SCR-PUR-017 | 采购退货单登録編集 | EDIT | F-PUR-015 | purchase:return:create | PUR | 04-purchase/00-overview.md |
| SCR-PUR-018 | 采购退货出库确认 | EDIT | F-PUR-016 | purchase:return:ship | PUR | 04-purchase/00-overview.md |
| SCR-PUR-019 | 采购发票登记 | EDIT | F-PUR-017 | purchase:invoice:create | PUR | 04-purchase/00-overview.md |
| SCR-PUR-020 | 三单匹配与差异处理 | VIEW | F-PUR-018 | purchase:invoice:view | PUR | 04-purchase/00-overview.md |
| SCR-PUR-021 | 采购对账单 | VIEW | F-PUR-019 | purchase:statement:view | PUR | 04-purchase/00-overview.md |
| SCR-PUR-022 | 应付/暂估台账 | VIEW | F-PUR-020 | purchase:ap:view | PUR | 04-purchase/00-overview.md |
| SCR-PUR-023 | 付款申请（采购发起） | EDIT | F-PUR-021 | purchase:payment:create | PUR | 04-purchase/00-overview.md |
| SCR-PUR-024 | 预付款申请 | EDIT | F-PUR-022 | purchase:payment:create | PUR | 04-purchase/00-overview.md |
| SCR-PUR-025 | 交期跟踪看板 | DASH | F-PUR-023 | purchase:tracking:view | PUR | 04-purchase/00-overview.md |
| SCR-PUR-026 | 采购价格查询 | LIST | F-PUR-024 | purchase:price:view | PUR | 04-purchase/00-overview.md |
| SCR-PUR-027 | 计划采购建议 | LIST | F-PUR-025 | purchase:plan:view | PUR | 04-purchase/00-overview.md |
| SCR-PUR-028 | 供应商绩效评价 | VIEW | F-PUR-026 | purchase:performance:view | PUR | 04-purchase/00-overview.md |
| SCR-PUR-029 | 采购报表 | LIST | F-PUR-027 | purchase:report:view | PUR | 04-purchase/00-overview.md |
| SCR-RPT-001 | 经营驾驶舱 | DASH | F-RPT-001 | report:dashboard:view | RPT | 10-analytics/00-overview.md |
| SCR-RPT-002 | 驾驶舱布局设置 | EDIT | F-RPT-001 | report:dashboard:update | RPT | 10-analytics/00-overview.md |
| SCR-RPT-003 | 销售分析 | DASH | F-RPT-003 | report:sales:view | RPT | 10-analytics/00-overview.md |
| SCR-RPT-004 | 采购分析 | DASH | F-RPT-003 | report:purchase:view | RPT | 10-analytics/00-overview.md |
| SCR-RPT-005 | 生产分析 | DASH | F-RPT-003 | report:production:view | RPT | 10-analytics/00-overview.md |
| SCR-RPT-006 | 财务分析 | DASH | F-RPT-003 | report:finance:view | RPT | 10-analytics/00-overview.md |
| SCR-RPT-007 | 库存分析 | DASH | F-RPT-004 | report:inventory:view | RPT | 10-analytics/00-overview.md |
| SCR-RPT-008 | KPI 一覧 | LIST | F-RPT-002 | report:kpi:view | RPT | 10-analytics/00-overview.md |
| SCR-RPT-009 | KPI 定义编辑 | EDIT | F-RPT-002 | report:kpi:update | RPT | 10-analytics/00-overview.md |
| SCR-RPT-010 | KPI 详情/趋势 | VIEW | F-RPT-002 | report:kpi:view | RPT | 10-analytics/00-overview.md |
| SCR-RPT-011 | 预警中心 | LIST | F-RPT-005 | report:warning:view | RPT | 10-analytics/00-overview.md |
| SCR-RPT-012 | 预警规则编辑 | EDIT | F-RPT-005 | report:warning:update | RPT | 10-analytics/00-overview.md |
| SCR-RPT-013 | 预警历史 | LIST | F-RPT-005 | report:warning:view | RPT | 10-analytics/00-overview.md |
| SCR-RPT-014 | 报表订阅一覧 | LIST | F-RPT-006 | report:subscription:view | RPT | 10-analytics/00-overview.md |
| SCR-RPT-015 | 订阅設定 | EDIT | F-RPT-006 | report:subscription:update | RPT | 10-analytics/00-overview.md |
| SCR-RPT-016 | 分析明细/钻取 | LIST | F-RPT-003/004/009 | report:analysis:view | RPT | 10-analytics/00-overview.md |
| SCR-RPT-017 | 分析导出/非同期ジョブ | VIEW | F-RPT-009 | report:analysis:export | RPT | 10-analytics/00-overview.md |
| SCR-RPT-018 | 分析数据抽取监视 | LIST | F-RPT-008 | report:etl:view | RPT | 10-analytics/00-overview.md |
| SCR-RPT-019 | 数据质量检查 | LIST | F-RPT-007 | report:quality:view | RPT | 10-analytics/00-overview.md |
| SCR-RPT-020 | 移动端/大屏（P2） | DASH | F-RPT-010 | report:dashboard:view | RPT | 10-analytics/00-overview.md |
| SCR-SAL-001 | 询价一覧 | LIST | F-SAL-001 | sales:inquiry:view | SAL | 03-sales/00-overview.md |
| SCR-SAL-002 | 询价登録編集 | EDIT | F-SAL-001 | sales:inquiry:create | SAL | 03-sales/00-overview.md |
| SCR-SAL-003 | 询价参照詳細 | VIEW | F-SAL-001 | sales:inquiry:view | SAL | 03-sales/00-overview.md |
| SCR-SAL-004 | 报价单一覧 | LIST | F-SAL-002 | sales:quotation:view | SAL | 03-sales/00-overview.md |
| SCR-SAL-005 | 报价单登録編集 | EDIT | F-SAL-002 | sales:quotation:create | SAL | 03-sales/00-overview.md |
| SCR-SAL-006 | 报价单参照詳細 | VIEW | F-SAL-002 | sales:quotation:view | SAL | 03-sales/00-overview.md |
| SCR-SAL-007 | 报价单版本比較 | VIEW | F-SAL-002 | sales:quotation:view | SAL | 03-sales/00-overview.md |
| SCR-SAL-008 | 销售订单一覧 | LIST | F-SAL-003 | sales:order:view | SAL | 03-sales/00-overview.md |
| SCR-SAL-009 | 销售订单登録編集 | EDIT | F-SAL-003 | sales:order:create | SAL | 03-sales/00-overview.md |
| SCR-SAL-010 | 销售订单参照詳細 | VIEW | F-SAL-003 | sales:order:view | SAL | 03-sales/00-overview.md |
| SCR-SAL-011 | 订单承认画面（WF） | WF | F-SAL-003 | sales:order:approve | SAL | 03-sales/00-overview.md |
| SCR-SAL-012 | 订单变更ウィザード | WIZ | F-SAL-004 | sales:order:update | SAL | 03-sales/00-overview.md |
| SCR-SAL-013 | 订单变更履歴 | VIEW | F-SAL-004 | sales:order:view | SAL | 03-sales/00-overview.md |
| SCR-SAL-014 | 发货通知一覧 | LIST | F-SAL-005 | sales:delivery:view | SAL | 03-sales/00-overview.md |
| SCR-SAL-015 | 发货通知登録編集 | EDIT | F-SAL-005 | sales:delivery:create | SAL | 03-sales/00-overview.md |
| SCR-SAL-016 | 拣货作业 | EDIT | F-SAL-005 | sales:delivery:pick | SAL | 03-sales/00-overview.md |
| SCR-SAL-017 | 出荷確定 | EDIT | F-SAL-005 | sales:delivery:confirm | SAL | 03-sales/00-overview.md |
| SCR-SAL-018 | 送货单预览 | PRINT | F-SAL-005 | sales:delivery:print | SAL | 03-sales/00-overview.md |
| SCR-SAL-019 | 退货单一覧 | LIST | F-SAL-006 | sales:return:view | SAL | 03-sales/00-overview.md |
| SCR-SAL-020 | 退货单登録編集 | EDIT | F-SAL-006 | sales:return:create | SAL | 03-sales/00-overview.md |
| SCR-SAL-021 | 退货检验 | EDIT | F-SAL-006 | sales:return:inspect | SAL | 03-sales/00-overview.md |
| SCR-SAL-022 | 退货单参照詳細 | VIEW | F-SAL-006 | sales:return:view | SAL | 03-sales/00-overview.md |
| SCR-SAL-023 | 开票申请一覧 | LIST | F-SAL-007 | sales:invoice-application:view | SAL | 03-sales/00-overview.md |
| SCR-SAL-024 | 开票申请登録編集 | EDIT | F-SAL-007 | sales:invoice-application:create | SAL | 03-sales/00-overview.md |
| SCR-SAL-025 | 发票登记一覧 | LIST | F-SAL-007 | sales:invoice:view | SAL | 03-sales/00-overview.md |
| SCR-SAL-026 | 发票登记編集 | EDIT | F-SAL-007 | sales:invoice:create | SAL | 03-sales/00-overview.md |
| SCR-SAL-027 | 发票参照詳細（赤伝） | VIEW | F-SAL-007 | sales:invoice:view | SAL | 03-sales/00-overview.md |
| SCR-SAL-028 | 对账单生成 | WIZ | F-SAL-008 | sales:statement:create | SAL | 03-sales/00-overview.md |
| SCR-SAL-029 | 对账单照会 | VIEW | F-SAL-008 | sales:statement:view | SAL | 03-sales/00-overview.md |
| SCR-SAL-030 | 应收款查询 | LIST | F-SAL-009 | sales:receivable:view | SAL | 03-sales/00-overview.md |
| SCR-SAL-031 | 账龄分析 | DASH | F-SAL-009 | sales:receivable:view | SAL | 03-sales/00-overview.md |
| SCR-SAL-032 | 信用额度照会 | DASH | F-SAL-010 | sales:credit:view | SAL | 03-sales/00-overview.md |
| SCR-SAL-033 | 与信台帳明細（FIN 投影） | LIST | F-SAL-010 | sales:credit:view | SAL | 03-sales/00-overview.md |
| SCR-SAL-034 | 信用超限审批申请 | EDIT | F-SAL-010 | sales:credit:submit | SAL | 03-sales/00-overview.md |
| SCR-SAL-035 | 价格表照会 | LIST | F-SAL-011 | sales:price:view | SAL | 03-sales/00-overview.md |
| SCR-SAL-036 | 特价申请一覧 | LIST | F-SAL-011 | sales:price-override:view | SAL | 03-sales/00-overview.md |
| SCR-SAL-037 | 特价申请登録編集 | EDIT | F-SAL-011 | sales:price-override:create | SAL | 03-sales/00-overview.md |
| SCR-SAL-038 | 订单执行跟踪 | DASH | F-SAL-012 | sales:tracking:view | SAL | 03-sales/00-overview.md |
| SCR-SAL-039 | 欠货・交期迟延一覧 | LIST | F-SAL-012 | sales:tracking:view | SAL | 03-sales/00-overview.md |
| SCR-SAL-040 | 销售预测一覧 | LIST | F-SAL-013 | sales:forecast:view | SAL | 03-sales/00-overview.md |
| SCR-SAL-041 | 销售预测登録編集 | EDIT | F-SAL-013 | sales:forecast:create | SAL | 03-sales/00-overview.md |
| SCR-SAL-042 | 换货申请登録 | EDIT | F-SAL-014 | sales:exchange:create | SAL | 03-sales/00-overview.md |
| SCR-SAL-043 | 销售明细报表 | VIEW | F-SAL-015 | sales:report:view | SAL | 03-sales/00-overview.md |
| SCR-SAL-044 | 毛利分析 | DASH | F-SAL-015 | sales:report:view | SAL | 03-sales/00-overview.md |
| SCR-SAL-045 | 客户排名 | VIEW | F-SAL-015 | sales:report:view | SAL | 03-sales/00-overview.md |
| SCR-SAL-046 | 出口销售信息（Phase2） | EDIT | F-SAL-016 | sales:export:update | SAL | 03-sales/00-overview.md |
| SCR-SAL-047 | 出荷实绩照会 | LIST | F-SAL-018 | sales:delivery:view | SAL | 03-sales/00-overview.md |
| SCR-SYS-001 | 登录 | LOGIN | F-SYS-001 | 認証不要（公開） | SYS | 01-system/00-overview.md |
| SCR-SYS-002 | 密码修改（强制/任意） | EDIT | F-SYS-001 | system:profile:update | SYS | 01-system/00-overview.md |
| SCR-SYS-003 | 个人中心 | EDIT | F-SYS-018 | system:profile:view | SYS | 01-system/00-overview.md |
| SCR-SYS-004 | 用户一覧 | LIST | F-SYS-002 | system:user:view | SYS | 01-system/00-overview.md |
| SCR-SYS-005 | 用户登録編集 | EDIT | F-SYS-002 | system:user:create/update | SYS | 01-system/00-overview.md |
| SCR-SYS-006 | 用户詳細 | VIEW | F-SYS-002 | system:user:view | SYS | 01-system/00-overview.md |
| SCR-SYS-007 | 角色一覧 | LIST | F-SYS-003 | system:role:view | SYS | 01-system/00-overview.md |
| SCR-SYS-008 | 角色登録編集（権限/データ範囲/项目権限） | EDIT | F-SYS-003 | system:role:create/update | SYS | 01-system/00-overview.md |
| SCR-SYS-009 | 用户角色割当 | EDIT | F-SYS-003 | system:user-role:update | SYS | 01-system/00-overview.md |
| SCR-SYS-010 | 组织部门管理 | EDIT | F-SYS-005 | system:department:view | SYS | 01-system/00-overview.md |
| SCR-SYS-011 | 岗位管理 | LIST | F-SYS-006 | system:position:view | SYS | 01-system/00-overview.md |
| SCR-SYS-012 | 公司/工厂设置 | EDIT | F-SYS-014 | system:company:view | SYS | 01-system/00-overview.md |
| SCR-SYS-013 | 租户设置（予約） | LIST | F-SYS-017 | system:tenant:view | SYS | 01-system/00-overview.md |
| SCR-SYS-014 | 菜单管理 | EDIT | F-SYS-004 | system:menu:view | SYS | 01-system/00-overview.md |
| SCR-SYS-015 | 数据字典一覧 | LIST | F-SYS-007 | system:dict:view | SYS | 01-system/00-overview.md |
| SCR-SYS-016 | 字典項目編集 | EDIT | F-SYS-007 | system:dict:update | SYS | 01-system/00-overview.md |
| SCR-SYS-017 | 系统参数 | LIST | F-SYS-008 | system:param:view | SYS | 01-system/00-overview.md |
| SCR-SYS-018 | 操作审计日志 | LIST | F-SYS-009 | system:audit-log:view | SYS | 01-system/00-overview.md |
| SCR-SYS-019 | 登录日志 | LIST | F-SYS-009 | system:login-log:view | SYS | 01-system/00-overview.md |
| SCR-SYS-020 | 附件管理 | LIST | F-SYS-010 | system:attachment:view | SYS | 01-system/00-overview.md |
| SCR-SYS-021 | 消息通知中心/待办中心 | LIST | F-SYS-011 | system:notification:view | SYS | 01-system/00-overview.md |
| SCR-SYS-022 | 通知模板管理 | LIST | F-SYS-019 | system:notification-template:view | SYS | 01-system/00-overview.md |
| SCR-SYS-023 | 单据编号规则 | LIST | F-SYS-012 | system:number-rule:view | SYS | 01-system/00-overview.md |
| SCR-SYS-024 | 导入导出中心 | LIST | F-SYS-013 | system:job:view | SYS | 01-system/00-overview.md |
| SCR-SYS-025 | 异步任务詳細/進捗 | VIEW | F-SYS-013 | system:job:view | SYS | 01-system/00-overview.md |
| SCR-SYS-026 | 打印模板管理 | LIST | F-SYS-015 | system:print-template:view | SYS | 01-system/00-overview.md |
| SCR-SYS-027 | 在线用户 | LIST | F-SYS-016 | system:online-user:view | SYS | 01-system/00-overview.md |
| SCR-SYS-028 | 定时任务监控 | LIST | F-SYS-016 | system:job-monitor:view | SYS | 01-system/00-overview.md |
| SCR-SYS-029 | 系统初始化与数据维护 | WIZ | F-SYS-020 | system:maintenance:view | SYS | 01-system/00-overview.md |
| SCR-SYS-030 | 通知发送履歴 | LIST | F-SYS-019 | system:notification-log:view | SYS | 01-system/00-overview.md |
| SCR-WF-001 | 流程模型一覧 | LIST | F-WF-001 | workflow:process:view | WF | 08-workflow/00-overview.md |
| SCR-WF-002 | 流程模型登録編集/デプロイ | EDIT | F-WF-001 | workflow:process:update | WF | 08-workflow/00-overview.md |
| SCR-WF-003 | 业务类型映射設定 | LIST | F-WF-002 | workflow:mapping:view | WF | 08-workflow/00-overview.md |
| SCR-WF-004 | 承認マトリクス設定 | EDIT | F-WF-002 | workflow:mapping:update | WF | 08-workflow/00-overview.md |
| SCR-WF-005 | 审批发起（提出ダイアログ） | WF | F-WF-003 | workflow:instance:submit | WF | 08-workflow/00-overview.md |
| SCR-WF-006 | 待办一覧 | WF | F-WF-004 | workflow:task:view | WF | 08-workflow/00-overview.md |
| SCR-WF-007 | 承認画面 | WF | F-WF-005 | workflow:task:approve | WF | 08-workflow/00-overview.md |
| SCR-WF-008 | 已办一覧 | WF | F-WF-004 | workflow:task:view | WF | 08-workflow/00-overview.md |
| SCR-WF-009 | 我发起的 | WF | F-WF-004 | workflow:task:view | WF | 08-workflow/00-overview.md |
| SCR-WF-010 | 抄送我的 | WF | F-WF-004 | workflow:task:view | WF | 08-workflow/00-overview.md |
| SCR-WF-011 | 审批历史/流程追踪 | VIEW | F-WF-006 | workflow:task:view | WF | 08-workflow/00-overview.md |
| SCR-WF-012 | 代理委托设置 | EDIT | F-WF-007 | workflow:delegation:update | WF | 08-workflow/00-overview.md |
| SCR-WF-013 | 流程实例管理 | LIST | F-WF-009 | workflow:instance:view | WF | 08-workflow/00-overview.md |
| SCR-WF-014 | 超时规则与自动审批设置 | EDIT | F-WF-008 | workflow:timeout:update | WF | 08-workflow/00-overview.md |
| SCR-WF-015 | 表单字段权限设置 | EDIT | F-WF-010 | workflow:field-permission:update | WF | 08-workflow/00-overview.md |
| SCR-WF-016 | 流程监控看板 | DASH | F-WF-006/009 | workflow:monitor:view | WF | 08-workflow/00-overview.md |

## 改訂履歴

| 版数 | 日付 | 変更内容 | 変更者 |
|---|---|---|---|
| v1.0 | 2026-10-20 | 自动生成 | gen_matrix.py |
