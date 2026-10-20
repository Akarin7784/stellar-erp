# 機能一覧（功能一览）

| 項目 | 内容 |
|---|---|
| 文書名 | 機能一覧（功能一览）（自动生成） |
| 文書番号 | DSN-MTX-001 |
| 版数 | v1.0 |
| 作成日 | 2026-10-20 |
| 作成者 | Lead（生成工具 gen_matrix.py） |
| 状態 | ドラフト（自动生成・最終レビュー前） |
| 備考 | 全 222 件。機能ID/名称/概要/画面/優先度/状態/詳細設計書/域/提取元 |

> 本文件由 `20-matrix/tools/gen_matrix.py` 从各域设计书中自动提取生成。修改设计书后重新运行即可更新。

| 機能 ID | 機能名 | 概要 | 画面 ID | 優先度 | 状態 | 詳細設計書 | 域 | 提取元 |
|---|---|---|---|---|---|---|---|---|
| F-FIN-001 | 会计科目维护 | CAS 科目层级、余额方向、辅助核算维度、启用/停用 | SCR-FIN-001,002 | P0 | 設計済 | 01 | FIN | 07-finance/00-overview.md |
| F-FIN-002 | 辅助核算与期初余额 | 科目辅助核算设置、期初余额导入与试算校验 | SCR-FIN-003,004 | P0 | 設計済 | 01 | FIN | 07-finance/00-overview.md |
| F-FIN-003 | 记账凭证录入 | 手工凭证（记/收/付/转）、借贷平衡、辅助核算、附件 | SCR-FIN-005,006 | P0 | 設計済 | 02 | FIN | 07-finance/00-overview.md |
| F-FIN-004 | 凭证模板管理 | 常用凭证模板（业务事件/手工）与取数规则 | SCR-FIN-007 | P0 | 設計済 | 02 | FIN | 07-finance/00-overview.md |
| F-FIN-005 | 凭证审核 | 审核/取消审核、批量审核、SoD 校验 | SCR-FIN-008,009 | P0 | 設計済 | 02 | FIN | 07-finance/00-overview.md |
| F-FIN-006 | 凭证记账（过账） | 记账/批量记账，更新科目余额与辅助余额 | SCR-FIN-010 | P0 | 設計済 | 02 | FIN | 07-finance/00-overview.md |
| F-FIN-007 | 凭证反记账 | 反记账（限 OPEN 期间）、理由与审计 | SCR-FIN-011 | P0 | 設計済 | 02 | FIN | 07-finance/00-overview.md |
| F-FIN-008 | 红字冲销 | 生成红字冲销凭证、原凭证关联 | SCR-FIN-012 | P0 | 設計済 | 02 | FIN | 07-finance/00-overview.md |
| F-FIN-009 | 凭证查询与附件 | 凭证检索、凭证汇总、附件管理 | SCR-FIN-013 | P0 | 設計済 | 02 | FIN | 07-finance/00-overview.md |
| F-FIN-010 | 总账/明细账查询 | 总账、明细账、序时账、辅助核算明细账 | SCR-FIN-014,015,016 | P0 | 設計済 | 02 | FIN | 07-finance/00-overview.md |
| F-FIN-011 | 试算平衡 | 期初/本期/期末的借贷平衡校验与科目余额表 | SCR-FIN-017 | P0 | 設計済 | 02 | FIN | 07-finance/00-overview.md |
| F-FIN-012 | 应付单管理 | 应付单确认/取消、余额维护、来源追溯 | SCR-FIN-018,019 | P0 | 設計済 | 03 | FIN | 07-finance/00-overview.md |
| F-FIN-013 | 采购发票与三单匹配 | 进项发票登记、PO/GR/发票三单匹配、差异处理 | SCR-FIN-020 | P0 | 設計済 | 03 | FIN | 07-finance/00-overview.md |
| F-FIN-014 | 暂估入账与冲回 | 收货暂估、暂估冲回、暂估余额追溯 | SCR-FIN-021 | P0 | 設計済 | 03 | FIN | 07-finance/00-overview.md |
| F-FIN-015 | 付款申请 | 付款申请、审批、付款排程 | SCR-FIN-022 | P0 | 設計済 | 03 | FIN | 07-finance/00-overview.md |
| F-FIN-016 | 付款执行 | 付款单、银行送金/现金支付、付款凭证 | SCR-FIN-023 | P0 | 設計済 | 03 | FIN | 07-finance/00-overview.md |
| F-FIN-017 | 应付核销 | 付款与应付/预付的核销、部分核销、反核销 | SCR-FIN-024 | P0 | 設計済 | 03 | FIN | 07-finance/00-overview.md |
| F-FIN-018 | 应付账龄 | 应付账款账龄分析（按到期日/业务日期） | SCR-FIN-025 | P0 | 設計済 | 03 | FIN | 07-finance/00-overview.md |
| F-FIN-019 | 应收单管理 | 应收单确认/取消、发票纽付け状态、余额维护 | SCR-FIN-026 | P0 | 設計済 | 04 | FIN | 07-finance/00-overview.md |
| F-FIN-020 | 收款登记 | 收款单（银行/现金/票据）、预收、到账确认 | SCR-FIN-027 | P0 | 設計済 | 04 | FIN | 07-finance/00-overview.md |
| F-FIN-021 | 应收核销 | 收款与应收/预收的核销、部分核销、反核销 | SCR-FIN-028 | P0 | 設計済 | 04 | FIN | 07-finance/00-overview.md |
| F-FIN-022 | 应收账龄与坏账准备 | 应收账龄分析；坏账准备计提（第一版・実装順 P2） | SCR-FIN-029,030 | P0/P2 | 設計済 | 04 | FIN | 07-finance/00-overview.md |
| F-FIN-023 | 现金日记账 | 现金收付登记、日结、现金盘点 | SCR-FIN-031 | P0 | 設計済 | 05 | FIN | 07-finance/00-overview.md |
| F-FIN-024 | 银行日记账与银行对账 | 银行日记账、对账单导入、自动/手工匹配、余额调节表 | SCR-FIN-032～035 | P0 | 設計済 | 05 | FIN | 07-finance/00-overview.md |
| F-FIN-025 | 资金日报 | 现金/银行账户余额、当日收支、资金头寸 | SCR-FIN-036 | P0 | 設計済 | 05 | FIN | 07-finance/00-overview.md |
| F-FIN-026 | 发票台账 | 进项/销项发票台账、发票查验状态、勾选认证 | SCR-FIN-037,038 | P0 | 設計済 | 05 | FIN | 07-finance/00-overview.md |
| F-FIN-027 | 增值税申报辅助 | 销项-进项-留抵计算、申报辅助表、导出 | SCR-FIN-039 | P0 | 設計済 | 05 | FIN | 07-finance/00-overview.md |
| F-FIN-028 | 附加税/所得税计提 | 城建税/教育费附加/地方教育附加/所得税计提凭证 | SCR-FIN-040 | P0 | 設計済 | 05 | FIN | 07-finance/00-overview.md |
| F-FIN-029 | 自动凭证规则管理 | 业务事件→凭证模板的规则维护、模拟测试 | SCR-FIN-041 | P0 | 設計済 | 06 | FIN | 07-finance/00-overview.md |
| F-FIN-030 | 自动凭证生成与监控 | 事件消费、凭证生成、失败重试、补偿 | SCR-FIN-042 | P0 | 設計済 | 06 | FIN | 07-finance/00-overview.md |
| F-FIN-031 | 成本核算 | 品种法/分批法成本计算、成本对象与结果 | SCR-FIN-043,044 | P1 | 設計済 | 06 | FIN | 07-finance/00-overview.md |
| F-FIN-032 | 制造费用归集与分配 | 费用归集、分配标准、分配计算与凭证 | SCR-FIN-045 | P1 | 設計済 | 06 | FIN | 07-finance/00-overview.md |
| F-FIN-033 | 在制品与完工成本 | 在制品成本、完工入库成本、单位成本 | SCR-FIN-046 | P1 | 設計済 | 06 | FIN | 07-finance/00-overview.md |
| F-FIN-034 | 成本差异分析 | 标准/实际、材料/人工/制造费用差异分析 | SCR-FIN-047 | P1 | 設計済 | 06 | FIN | 07-finance/00-overview.md |
| F-FIN-035 | 期间管理与月结 | 期间状态机、月结检查、期间关闭/重开 | SCR-FIN-048,049 | P0 | 設計済 | 07 | FIN | 07-finance/00-overview.md |
| F-FIN-036 | 损益结转 | 收入/费用→本年利润结转凭证与记账 | SCR-FIN-050 | P0 | 設計済 | 07 | FIN | 07-finance/00-overview.md |
| F-FIN-037 | 年度结转 | 本年利润→利润分配、次年期间开启 | SCR-FIN-051 | P0 | 設計済 | 07 | FIN | 07-finance/00-overview.md |
| F-FIN-038 | 财务报表 | 资产负债表、利润表、现金流量表（简表）取数与快照 | SCR-FIN-052 | P0 | 設計済 | 07 | FIN | 07-finance/00-overview.md |
| F-FIN-039 | 科目余额表 | 科目余额表/试算平衡表输出 | SCR-FIN-053 | P0 | 設計済 | 07 | FIN | 07-finance/00-overview.md |
| F-FIN-040 | 费用报销与借款 | 报销单、借款/还款、差旅费（第一版・実装順 P2、概要設計） | SCR-FIN-054,055 | P2 | 設計中 | 07 | FIN | 07-finance/00-overview.md |
| F-FIN-041 | 固定资产卡片与折旧 | 资产卡片、折旧计提、资产台账（第一版・実装順 P2、概要設計） | SCR-FIN-056 | P2 | 設計中 | 07 | FIN | 07-finance/00-overview.md |
| F-FIN-042 | 固定资产处置 | 出售/报废/盘亏处置与凭证（第一版・実装順 P2、概要設計） | SCR-FIN-057 | P2 | 設計中 | 07 | FIN | 07-finance/00-overview.md |
| F-FIN-043 | 预算管理 | 预算编制、控制、执行分析（第一版・実装順 P2、概要設計） | SCR-FIN-058 | P2 | 設計中 | 07 | FIN | 07-finance/00-overview.md |
| F-FIN-044 | 多币种与汇兑损益 | 外币凭证、期末汇兑调整（第一版・実装順 P2、概要設計） | SCR-FIN-059 | P2 | 設計中 | 07 | FIN | 07-finance/00-overview.md |
| F-FIN-045 | 资金计划与付款排程 | 资金计划编制、付款排程、资金缺口预警（第一版・実装順 P2、概要設計） | SCR-FIN-060 | P2 | 設計中 | 07 | FIN | 07-finance/00-overview.md |
| F-FIN-046 | 财务报表分析 | 同比/环比、结构分析、指标计算（第一版・実装順 P2、概要設計） | SCR-FIN-061 | P2 | 設計中 | 07 | FIN | 07-finance/00-overview.md |
| F-FIN-047 | 标准成本维护 | 标准成本版本登记（物料×版本×适用期间、材料/人工/制造费用/委外）、提交、发布（自动截止旧版） | SCR-FIN-062 | P1 | 設計済 | 06 | FIN | 07-finance/00-overview.md |
| F-INT-001 | 接口配置管理 | 相手先・エンドポイント・認証・マッピング・タイムアウト・リトライの登録と有効化 | SCR-INT-001〜003 | P0 | 設計済 | 01-integration-config.md | INT | 09-integration/00-overview.md |
| F-INT-002 | 数电票开具与交付 | 蓝票/红票开具、交付状态取得、票面查询、赤伝 | SCR-INT-008、009 | P1（Phase 2 本格） | 設計済 | 02-tax-bank-interface.md | INT | 09-integration/00-overview.md |
| F-INT-003 | 进项发票查验 | 发票查验、用途确认、异常发票提醒 | SCR-INT-010 | P1 | 設計済 | 02-tax-bank-interface.md | INT | 09-integration/00-overview.md |
| F-INT-004 | 银企直连 | 余额/明细照会、付款指令送信、回单取得 | SCR-INT-011〜013 | P1 | 設計済 | 02-tax-bank-interface.md | INT | 09-integration/00-overview.md |
| F-INT-005 | 银行对账单取込 | 文件取込、形式検証、FIN への引渡、差異通知 | SCR-INT-014、015 | P1 | 設計済 | 02-tax-bank-interface.md | INT | 09-integration/00-overview.md |
| F-INT-006 | MES 集成 | 工单下发、報工回伝、領料・完工連携、状態同期 | SCR-INT-016 | P1 | 設計済 | 03-mes-wms-plm.md | INT | 09-integration/00-overview.md |
| F-INT-007 | WMS 集成 | 入出庫指示・実績・在庫同期（Phase 2） | SCR-INT-016 | P2 | 設計済（概要） | 03-mes-wms-plm.md | INT | 09-integration/00-overview.md |
| F-INT-008 | PLM 同步 | 物料・BOM・工艺・ECN の差分取込 | SCR-INT-017 | P1 | 設計済 | 03-mes-wms-plm.md | INT | 09-integration/00-overview.md |
| F-INT-009 | 开放 API 平台 | クライアント登録、スコープ、レート制限、署名検証、監査 | SCR-INT-018、019 | P1 | 設計済 | 04-openapi-file-notify.md | INT | 09-integration/00-overview.md |
| F-INT-010 | 条码/PDA 接口 | 端末認証、扫码検証、オフライン補伝 | SCR-INT-023 | P1 | 設計済 | 03-mes-wms-plm.md | INT | 09-integration/00-overview.md |
| F-INT-011 | 外部文件取込 | ファイルレイアウト定義、ドライラン、エラー報告、全件/部分成功制御 | SCR-INT-020 | P0 | 設計済 | 04-openapi-file-notify.md | INT | 09-integration/00-overview.md |
| F-INT-012 | 消息渠道 | メール/短信/企业微信/钉钉の送信、テンプレート変数、再送 | SCR-INT-021、022 | P0（SMTP）/P2（他） | 設計済 | 04-openapi-file-notify.md | INT | 09-integration/00-overview.md |
| F-INT-013 | 同步监控与重推 | 失敗/滞留監視、手動再送、死信管理、アラート | SCR-INT-004〜006 | P0 | 設計済 | 05-sync-monitor.md | INT | 09-integration/00-overview.md |
| F-INT-014 | 接口日志与对账 | 呼出日志、原文保存、日次対账、SLA 統計 | SCR-INT-007、024 | P0 | 設計済 | 05-sync-monitor.md | INT | 09-integration/00-overview.md |
| F-INT-015 | 接口凭证与安全 | 凭证ローテーション、IP 許可、mTLS、署名、マスキング | SCR-INT-002 | P0 | 設計済 | 01-integration-config.md | INT | 09-integration/00-overview.md |
| F-INT-016 | 电子税务局申报送信 | 申报数据の送信・受付番号保存（Phase 2） | SCR-INT-020 | P2 | 設計済（概要） | 02-tax-bank-interface.md | INT | 09-integration/00-overview.md |
| F-INT-017 | 物流面单连携 | 送り状番号取得・追跡（Phase 2） | SCR-INT-016 | P2 | 設計済（概要） | 03-mes-wms-plm.md | INT | 09-integration/00-overview.md |
| F-INT-018 | 客户 EDI 订单取込 | 顧客注文ファイルの取込・重複排除 | SCR-INT-020 | P2 | 設計済（概要） | 04-openapi-file-notify.md | INT | 09-integration/00-overview.md |
| F-INT-019 | 供应商门户送信 | PO 送信・納期回答取得（Phase 2） | SCR-INT-020 | P2 | 設計済（概要） | 04-openapi-file-notify.md | INT | 09-integration/00-overview.md |
| F-INT-020 | 设备 IoT 取込 | 設備状態・生産数の収集（Phase 2） | SCR-INT-016 | P2 | 設計済（概要） | 03-mes-wms-plm.md | INT | 09-integration/00-overview.md |
| F-INV-001 | 库存查询 | 现存量/可用量/锁定/待检/冻结/在途，按仓库/物料/批次/库位/状态多条件查询与汇总 | SCR-INV-001 | P0 | 設計済 | 01-stock-query.md | INV | 05-inventory/00-overview.md |
| F-INV-002 | 采购入库 | 来源收货单（E14），生成 GRI，待检入库，成本构成登记 | SCR-INV-004 | P0 | 設計済 | 02-inbound-outbound.md | INV | 05-inventory/00-overview.md |
| F-INV-003 | 销售出库 | 来源发货单（E10），生成 SDO，按移动平均出库、消耗预留 | SCR-INV-005 | P0 | 設計済 | 02-inbound-outbound.md | INV | 05-inventory/00-overview.md |
| F-INV-004 | 生产领料/退料 | 来源工单（MII=E22、MIR=E36），生成 MII/MIR，按 BOM 用量/实发 | SCR-INV-006 | P1 | 設計済 | 02-inbound-outbound.md | INV | 05-inventory/00-overview.md |
| F-INV-005 | 产成品/半成品入库 | 来源工单完工（E24），生成 FGI，完工成本入库 | SCR-INV-007 | P1 | 設計済 | 02-inbound-outbound.md | INV | 05-inventory/00-overview.md |
| F-INV-006 | 委外发料/收货 | 来源委外单（E25/E26），生成 OSI/OSR | SCR-INV-008 | P1 | 設計済 | 02-inbound-outbound.md | INV | 05-inventory/00-overview.md |
| F-INV-007 | 其他入库 | 盘盈以外（赠品/借入/期初/样品），生成 AOI | SCR-INV-009 | P0 | 設計済 | 02-inbound-outbound.md | INV | 05-inventory/00-overview.md |
| F-INV-008 | 其他出库 | 盘亏以外（领用/借出/样品/捐赠），生成 AOO/SC_OUT | SCR-INV-010 | P0 | 設計済 | 02-inbound-outbound.md | INV | 05-inventory/00-overview.md |
| F-INV-009 | 库存调拨 | 同仓移库、跨仓调拨、在途跟踪、部分收货 | SCR-INV-011、012 | P0 | 設計済 | 03-transfer-count.md | INV | 05-inventory/00-overview.md |
| F-INV-010 | 库存盘点 | 盘点计划→盘点单→实盘→差异→审批→调整 | SCR-INV-013〜015 | P0 | 設計済 | 03-transfer-count.md | INV | 05-inventory/00-overview.md |
| F-INV-011 | 批次管理 | 批号规则、批次主档、批次追溯、效期预警 | SCR-INV-016、017 | P0 | 設計済 | 04-batch-serial-status.md | INV | 05-inventory/00-overview.md |
| F-INV-012 | 序列号管理 | 序列号入库/出库/退货/报废全生命周期 | SCR-INV-018 | P1 | 設計済 | 04-batch-serial-status.md | INV | 05-inventory/00-overview.md |
| F-INV-013 | 库存事务流水 | 全部事务查询、来源追溯、反向冲销、导出 | SCR-INV-002、003 | P0 | 設計済 | 01-stock-query.md | INV | 05-inventory/00-overview.md |
| F-INV-014 | 库存状态转换 | 可用/待检/冻结/不合格/报废待处理之间的转换，成对 ST 事务 | SCR-INV-019 | P0 | 設計済 | 04-batch-serial-status.md | INV | 05-inventory/00-overview.md |
| F-INV-015 | 库龄与呆滞分析 | 库龄分段、呆滞判定、库龄快照 | SCR-INV-020 | P1 | 設計済 | 07-reports.md | INV | 05-inventory/00-overview.md |
| F-INV-016 | 安全库存与补货建议 | 安全库存/再订货点计算、补货建议生成、转请购 | SCR-INV-021 | P1 | 設計済 | 07-reports.md | INV | 05-inventory/00-overview.md |
| F-INV-017 | 移动加权平均成本计算与重算 | 入库成本构成、出库成本、成本调整、重新计价 | SCR-INV-022、023 | P0 | 設計済 | 05-costing.md | INV | 05-inventory/00-overview.md |
| F-INV-018 | 条码/PDA 扫码出入库 | 扫码作业、重复扫/错仓/错批次异常处理、离线补传 | SCR-INV-026 | P1 | 設計済 | 06-reservation-barcode-close.md | INV | 05-inventory/00-overview.md |
| F-INV-019 | 库存预留/锁定 | 受注/工单引当、释放、消耗、过期自动释放 | SCR-INV-024 | P0 | 設計済 | 06-reservation-barcode-close.md | INV | 05-inventory/00-overview.md |
| F-INV-020 | 库存期间月结/关账 | 月结检查、收发存汇总、期间关账/重开 | SCR-INV-025 | P0 | 設計済 | 06-reservation-barcode-close.md | INV | 05-inventory/00-overview.md |
| F-INV-021 | 库存报表 | 收发存汇总、明细账、库龄、周转、流水、追溯报告 | SCR-INV-020、003 | P0 | 設計済 | 07-reports.md | INV | 05-inventory/00-overview.md |
| F-INV-022 | 组装拆卸 | 组装/拆卸业务的库存处理（第一版対象。TODO：設計が未作成） | — | P2 | 概要設計 | 07-reports.md | INV | 05-inventory/00-overview.md |
| F-INV-023 | 寄售库存 | 供应商寄售/客户寄售库存（第一版対象。TODO：設計が未作成） | — | P2 | 概要設計 | 07-reports.md | INV | 05-inventory/00-overview.md |
| F-MDM-001 | 物料分类树与分类属性 | 多阶分类树、分类属性模板、分类编码 4 桁 | SCR-MDM-004 | P0 | 設計済 | 01 | MDM | 02-mdm/00-overview.md |
| F-MDM-002 | 物料主数据（多视图） | 基本/采购/销售/库存/生产/财务/质量多视图字段级维护 | SCR-MDM-001/002/003 | P0 | 設計済 | 01 | MDM | 02-mdm/00-overview.md |
| F-MDM-003 | 物料编码规则与自动编码 | 分类 4 + 流水 6 自动采番、手動指定、空番检查 | SCR-MDM-005 | P0 | 設計済 | 01 | MDM | 02-mdm/00-overview.md |
| F-MDM-004 | 客户主数据 | 基本/财务/信用/开票/联系人/收货地址 | SCR-MDM-011/012/013/014/015 | P0 | 設計済 | 02 | MDM | 02-mdm/00-overview.md |
| F-MDM-005 | 供应商主数据 | 基本/财务/付款条件/供货范围/银行账户/资质 | SCR-MDM-021/022/023/024/025 | P0 | 設計済 | 02 | MDM | 02-mdm/00-overview.md |
| F-MDM-006 | 仓库/库区/库位/货架 | 仓库类型、库区、库位编码、库位容量与条码 | SCR-MDM-031/032/033/034 | P0 | 設計済 | 03 | MDM | 02-mdm/00-overview.md |
| F-MDM-007 | 计量单位与单位换算组 | UN/ECE Rec20 + GB/T 3100 单位、换算组、精度 | SCR-MDM-041/042 | P0 | 設計済 | 04 | MDM | 02-mdm/00-overview.md |
| F-MDM-008 | 货币与汇率 | ISO 4217 货币、即期/期间汇率、汇率导入与生效 | SCR-MDM-043/044/045 | P0 | 設計済 | 04 | MDM | 02-mdm/00-overview.md |
| F-MDM-009 | 税码与税率 | 增值税/附加税/关税、含税标志、税收分类编码 | SCR-MDM-046/047 | P0 | 設計済 | 04 | MDM | 02-mdm/00-overview.md |
| F-MDM-010 | 销售价格表与折扣 | 客户/分类/物料/阶梯价/生效期/币种/含税/折扣 | SCR-MDM-051/052/053/056 | P0 | 設計済 | 05 | MDM | 02-mdm/00-overview.md |
| F-MDM-011 | 采购价格与供应商报价 | 供应商+物料采购价、报价单、比价支持 | SCR-MDM-054/055 | P0 | 設計済 | 05 | MDM | 02-mdm/00-overview.md |
| F-MDM-012 | 结算方式与付款条件 | 现金/转账/承兑/信用证；付款条件与分期 | SCR-MDM-061/062 | P0 | 設計済 | 05 | MDM | 02-mdm/00-overview.md |
| F-MDM-013 | 银行账户与联行号 | 银行主数据、CNAPS 联行号、取引先银行账户 | SCR-MDM-063/064 | P0 | 設計済 | 05 | MDM | 02-mdm/00-overview.md |
| F-MDM-014 | 客户信用额度与检查规则 | 信用额度、超限比例、检查时点、冻结/解除申请 | SCR-MDM-071/072 | P0 | 設計済 | 06 | MDM | 02-mdm/00-overview.md |
| F-MDM-015 | 供应商准入/评估/分级 | 准入审查、资质、月度评分、A/B/C/D 分级、AVL | SCR-MDM-026/073/074 | P1 | 設計済 | 06 | MDM | 02-mdm/00-overview.md |
| F-MDM-016 | 物料替代关系 | 单向/双向/一对一/一对多替代、优先级、生效期 | SCR-MDM-081 | P1 | 設計済 | 07 | MDM | 02-mdm/00-overview.md |
| F-MDM-017 | 条码规则与标签 | 物料/批次/库位条码规则、Code128/GS1-128、标签打印 | SCR-MDM-082/083 | P1 | 設計済 | 07 | MDM | 02-mdm/00-overview.md |
| F-MDM-018 | 主数据变更审批与版本历史 | 变更申请、审批、版本历史、前后值对比 | SCR-MDM-091/092/093 | P0 | 設計済 | 07 | MDM | 02-mdm/00-overview.md |
| F-MDM-019 | 数据质量校验与批量维护 | 质量规则、日检、批量导入/更新、错误报告 | SCR-MDM-094/095 | P1 | 設計済 | 07 | MDM | 02-mdm/00-overview.md |
| F-MDM-020 | 主数据数据权限 | 按公司/工厂/部门分配数据范围（委托 SYS 数据权限） | SCR-MDM-096 | P0 | 設計済 | 07 | MDM | 02-mdm/00-overview.md |
| F-MDM-021 | 物料工厂视图参数 | 工厂级默认仓库、安全库存、提前期、批量规则 | SCR-MDM-006 | P1 | 設計済 | 01 | MDM | 02-mdm/00-overview.md |
| F-MDM-022 | 主数据检索与导出 | 跨对象统一检索、主数据门户、导出 | SCR-MDM-097 | P1 | 設計済 | 07 | MDM | 02-mdm/00-overview.md |
| F-MDM-023 | 主数据分发与外部同步 | PLM 物料/BOM 同步、多工厂分发 | — | P2 | 設計済（概要） | 07 | MDM | 02-mdm/00-overview.md |
| F-MDM-024 | 汇率与标准代码导入 | 汇率、单位、货币、联行号等标准数据导入 | SCR-MDM-045 | P1 | 設計済 | 04 | MDM | 02-mdm/00-overview.md |
| F-MDM-025 | 工厂主数据 | 工厂编码・名称・类型・负责人・公司组织参照（Lead 裁定：工厂主数据归 MDM、mdm_factory） | SCR-MDM-098 | P0 | 設計済 | 03 | MDM | 02-mdm/00-overview.md |
| F-PRD-001 | BOM 管理 | 多阶 BOM 的登记/修改/复制/版本/生效期/损耗率/替代料/承认；BOM 比较 | SCR-PRD-001〜003 | P1 | 設計済 | 01-bom-routing-workcenter.md | PRD | 06-production/00-overview.md |
| F-PRD-002 | BOM 展开与成本卷算 | 多阶展开、低层码计算、用量与损耗、标准成本卷算、成本比较 | SCR-PRD-003 | P1 | 設計済 | 同上 | PRD | 06-production/00-overview.md |
| F-PRD-003 | 工艺路线管理 | 工序序列、工作中心、准备/单件工时、替代工序、版本与生效期 | SCR-PRD-004〜005 | P1 | 設計済 | 同上 | PRD | 06-production/00-overview.md |
| F-PRD-004 | 工作中心与产能管理 | 工作中心、设备、班组、工作日历、班次、日能力 | SCR-PRD-006〜007 | P1 | 設計済 | 同上 | PRD | 06-production/00-overview.md |
| F-PRD-005 | 生产订单管理 | 手工/MRP 生成、单阶/多阶、承认、下达、拆分/合并、变更、取消 | SCR-PRD-008〜011 | P1 | 設計済 | 02-work-order.md | PRD | 06-production/00-overview.md |
| F-PRD-006 | 生产领料/补料/退料 | MII/MIR 登记、超领检查、倒冲（後方払出）、引当消込、退料戻入 | SCR-PRD-012〜013 | P1 | 設計済 | 03-material-issue-reporting.md | PRD | 06-production/00-overview.md |
| F-PRD-007 | 工序报工 | 工序报工、良品/不良/报废、工数（人员/设备）、报工审核、返工追加工单 | SCR-PRD-014〜015 | P1 | 設計済 | 同上 | PRD | 06-production/00-overview.md |
| F-PRD-008 | 生产入库 | 成品/半成品完工入库、批次、超量检查、取消 | SCR-PRD-016 | P1 | 設計済 | 同上 | PRD | 06-production/00-overview.md |
| F-PRD-009 | 委外加工管理 | 委外订单、委外发料（OSI）、委外收货（OSR）、加工费结算与对账 | SCR-PRD-017〜020 | P2 | 設計済 | 04-outsourcing.md | PRD | 06-production/00-overview.md |
| F-PRD-010 | MRP 物料需求计划 | 需求收集、毛需求→净需求→计划订单→动作消息、运行履历、计划订单确认 | SCR-PRD-021〜023 | P1 | 設計済 | 05-mrp-planning.md | PRD | 06-production/00-overview.md |
| F-PRD-011 | 生产计划与排产 | 需求预测、MPS、粗能力负荷、日计划（甘特图为 第一版） | SCR-PRD-024 | P1 | 設計済 | 05-mrp-planning.md | PRD | 06-production/00-overview.md |
| F-PRD-012 | 检验标准管理 | 品目×工程×顾客的检验标准、检验项目、规格、抽样与判定基准 | SCR-PRD-025 | P1 | 設計済 | 06-quality-management.md | PRD | 06-production/00-overview.md |
| F-PRD-013 | 检验实施（IQC/IPQC/FQC/OQC） | 检验单起票/登记/判定、E15 発行、結果照会 | SCR-PRD-026〜027 | P1 | 設計済 | 同上 | PRD | 06-production/00-overview.md |
| F-PRD-014 | 不合格品处置（NCR） | NCR 起票、返工/特采/报废/返品处置、再检、处置履历 | SCR-PRD-028 | P1 | 設計済 | 同上 | PRD | 06-production/00-overview.md |
| F-PRD-015 | 质量追溯 | 批次/序列的正向・逆向追溯、受入ロット→完成品ロット→出荷先 | SCR-PRD-029 | P1 | 設計済 | 同上 | PRD | 06-production/00-overview.md |
| F-PRD-016 | 生产进度看板 | 工单进度、日产量、工序滞留、缺料、异常工单 | SCR-PRD-030 | P1 | 設計済 | 07-dashboard-reports.md | PRD | 06-production/00-overview.md |
| F-PRD-017 | 工时与效率统计 | 工时汇总、工数/产量/良率/效率、工作中心负荷与利用率 | SCR-PRD-031 | P1 | 設計済 | 同上 | PRD | 06-production/00-overview.md |
| F-PRD-018 | 设备台账/点检/维修 | 设备台账、点检计划与记录、维修工单（第一版対象。TODO：設計が未作成） | SCR-PRD-032 | P2 | 設計済（概要） | 同上 | PRD | 06-production/00-overview.md |
| F-PRD-019 | 生产报表 | 工单执行、产量、良率、效率、委外回收等报表 | SCR-PRD-033 | P1 | 設計済 | 92-report-batch-design.md | PRD | 06-production/00-overview.md |
| F-PRD-020 | 生产期末处理 | 工单结案、在制品结转、期间关闭检查、数据初始化 | —（バッチ） | P1 | 設計済 | 92-report-batch-design.md | PRD | 06-production/00-overview.md |
| F-PUR-001 | 请购单登记 | 部门需求登记、预算检查、重複チェック、提出・撤回 | SCR-PUR-001、002 | P0 | 設計済 | 01-requisition.md | PUR | 04-purchase/00-overview.md |
| F-PUR-002 | 请购审批 | 金额阶梯审批、差戻・撤回、承認結果反映 | SCR-PUR-002、003 | P0 | 設計済 | 01-requisition.md | PUR | 04-purchase/00-overview.md |
| F-PUR-003 | 请购转订单 | 全量/部分转单、合并转单、转单取消与数量戻し | SCR-PUR-002 | P0 | 設計済 | 01-requisition.md | PUR | 04-purchase/00-overview.md |
| F-PUR-004 | 询价比价单管理 | 询价单作成、供应商邀请、报价截止管理 | SCR-PUR-004、005 | P1 | 設計済 | 02-rfq-comparison.md | PUR | 04-purchase/00-overview.md |
| F-PUR-005 | 供应商报价登录 | 多供应商报价录入（单价/交期/MOQ/运费/条件） | SCR-PUR-006 | P1 | 設計済 | 02-rfq-comparison.md | PUR | 04-purchase/00-overview.md |
| F-PUR-006 | 比价与中选 | 比价表、综合评分、按行中选、生成 PO | SCR-PUR-007 | P1 | 設計済 | 02-rfq-comparison.md | PUR | 04-purchase/00-overview.md |
| F-PUR-007 | 采购订单登记 | 来源请购/询价/手工，取价、MOQ、准入检查 | SCR-PUR-008、009 | P0 | 設計済 | 03-purchase-order.md | PUR | 04-purchase/00-overview.md |
| F-PUR-008 | 采购订单审批 | 金额阶梯审批、承认后発注可 | SCR-PUR-009、010 | P0 | 設計済 | 03-purchase-order.md | PUR | 04-purchase/00-overview.md |
| F-PUR-009 | 采购订单变更 | 数量/单价/交期变更、版数管理、再承認、再送信 | SCR-PUR-011 | P1 | 設計済 | 03-purchase-order.md | PUR | 04-purchase/00-overview.md |
| F-PUR-010 | 采购订单取消与关闭 | 未入荷取消、残数量取消、手動关闭 | SCR-PUR-009 | P0 | 設計済 | 03-purchase-order.md | PUR | 04-purchase/00-overview.md |
| F-PUR-011 | 收货单登记 | 按 PO 收货、超收容差、分纳、批次采集 | SCR-PUR-012、013 | P0 | 設計済 | 04-receipt-iqc.md | PUR | 04-purchase/00-overview.md |
| F-PUR-012 | 收货确认与待检跟踪 | 入荷确定（E14）、待检在庫跟踪、取消 | SCR-PUR-014 | P0 | 設計済 | 04-receipt-iqc.md | PUR | 04-purchase/00-overview.md |
| F-PUR-013 | 来料检验判定与处置 | IQC 判定结果受信（E15）、合格/特采/不合格处置 | SCR-PUR-015 | P0 | 設計済 | 04-receipt-iqc.md | PUR | 04-purchase/00-overview.md |
| F-PUR-014 | 采购入库跟踪 | 入库进度确认（E18）、异常补正 | SCR-PUR-016 | P0 | 設計済 | 04-receipt-iqc.md | PUR | 04-purchase/00-overview.md |
| F-PUR-015 | 采购退货申请 | 质量/数量/错发退货申请、审批 | SCR-PUR-017 | P0 | 設計済 | 05-return.md | PUR | 04-purchase/00-overview.md |
| F-PUR-016 | 采购退货出库确认 | 退货出库（E16）、红字发票关联、换货补货 | SCR-PUR-018 | P0 | 設計済 | 05-return.md | PUR | 04-purchase/00-overview.md |
| F-PUR-017 | 采购发票登记 | 专票/普票/数电票/红字发票登记、发票查验 | SCR-PUR-019 | P0 | 設計済 | 06-purchase-invoice-ap.md | PUR | 04-purchase/00-overview.md |
| F-PUR-018 | 三单匹配与差异处理 | PO/GR/PIV 字段级匹配、容差判定、差异承认 | SCR-PUR-020 | P0 | 設計済 | 06-purchase-invoice-ap.md | PUR | 04-purchase/00-overview.md |
| F-PUR-019 | 采购对账单 | 月次供应商对账、差异确认、开票依据 | SCR-PUR-021 | P1 | 設計済 | 06-purchase-invoice-ap.md | PUR | 04-purchase/00-overview.md |
| F-PUR-020 | 应付/暂估确认与冲回 | E17 发信、暂估台账、入荷済未請求管理 | SCR-PUR-022 | P0 | 設計済 | 06-purchase-invoice-ap.md | PUR | 04-purchase/00-overview.md |
| F-PUR-021 | 付款申请（采购发起） | 依据 AP/PO 发起付款申请（FIN 单据） | SCR-PUR-023 | P1 | 設計済 | 06-purchase-invoice-ap.md | PUR | 04-purchase/00-overview.md |
| F-PUR-022 | 预付款申请 | 预付款比例、预付款申请、冲抵跟踪 | SCR-PUR-024 | P1 | 設計済 | 06-purchase-invoice-ap.md | PUR | 04-purchase/00-overview.md |
| F-PUR-023 | 交期跟踪与催货 | 未入荷一览、延迟判定、催货记录、提醒 | SCR-PUR-025 | P1 | 設計済 | 07-tracking-performance.md | PUR | 04-purchase/00-overview.md |
| F-PUR-024 | 采购价格管理 | 价格表引用、取价规则、成交价历史、价格异常 | SCR-PUR-026 | P1 | 設計済 | 07-tracking-performance.md | PUR | 04-purchase/00-overview.md |
| F-PUR-025 | 计划采购 | MRP 计划订单受信、转请购、安全库存补货 | SCR-PUR-027 | P1 | 設計済 | 07-tracking-performance.md | PUR | 04-purchase/00-overview.md |
| F-PUR-026 | 供应商绩效评价 | 交付/质量/价格/响应指标、评分分级 | SCR-PUR-028 | P1 | 設計済 | 07-tracking-performance.md | PUR | 04-purchase/00-overview.md |
| F-PUR-027 | 采購报表 | 采购额、价格趋势、交付达成、暂估台账 | SCR-PUR-029 | P1 | 設計済 | 07-tracking-performance.md、92 | PUR | 04-purchase/00-overview.md |
| F-RPT-001 | 经营驾驶舱 | 経営 KPI カード、トレンド、構成比、ドリルダウン | SCR-RPT-001、002、016 | P0 | 設計済 | 01-dashboard.md | RPT | 10-analytics/00-overview.md |
| F-RPT-002 | KPI 指标管理 | KPI 定義・算式・次元・目標・出所・権限の管理、版数 | SCR-RPT-008〜010 | P0 | 設計済 | 01-dashboard.md | RPT | 10-analytics/00-overview.md |
| F-RPT-003 | 经营分析报表 | 销售・采购・生产・財務の四域分析（比較・構成・ランキング） | SCR-RPT-003〜006 | P0 | 設計済 | 02-domain-analysis.md | RPT | 10-analytics/00-overview.md |
| F-RPT-004 | 库存分析 | 在庫金額・回転・庫齢・呆滞・欠品の分析 | SCR-RPT-007 | P0 | 設計済 | 02-domain-analysis.md | RPT | 10-analytics/00-overview.md |
| F-RPT-005 | 预警中心 | 規則・閾値・イベント・既読・担当・エスカレーション | SCR-RPT-011〜013 | P1 | 設計済 | 03-warning-subscription.md | RPT | 10-analytics/00-overview.md |
| F-RPT-006 | 报表订阅 | 日次/週次/月次の配信、宛先、形式、停止 | SCR-RPT-014、015 | P1 | 設計済 | 03-warning-subscription.md | RPT | 10-analytics/00-overview.md |
| F-RPT-007 | KPI 校验与数据质量 | 業務域との突合、欠損・遅延・異常値の検出 | SCR-RPT-019 | P1 | 設計済 | 01-dashboard.md | RPT | 10-analytics/00-overview.md |
| F-RPT-008 | 分析数据抽取管理 | 抽出ジョブの実行・再実行・監視、抽出範囲設定 | SCR-RPT-018 | P0 | 設計済 | 02-domain-analysis.md | RPT | 10-analytics/00-overview.md |
| F-RPT-009 | 自助分析与导出 | 条件指定の集計・ピボット・Excel 出力（P2） | SCR-RPT-016、017 | P2 | 設計済（概要） | 02-domain-analysis.md | RPT | 10-analytics/00-overview.md |
| F-RPT-010 | 移动端/大屏展示 | スマホ閲覧・工場大屏（P2） | SCR-RPT-020 | P2 | 設計済（概要） | 01-dashboard.md | RPT | 10-analytics/00-overview.md |
| F-SAL-001 | 客户询价管理 | 引合の登録・照会・回答、报价作成への引継ぎ | SCR-SAL-001〜003 | P0 | 設計済 | 01-quotation.md | SAL | 03-sales/00-overview.md |
| F-SAL-002 | 报价单管理 | 报价作成（版数・有効期限）、承認、PDF 出力、受注転換 | SCR-SAL-004〜007 | P0 | 設計済 | 01-quotation.md | SAL | 03-sales/00-overview.md |
| F-SAL-003 | 销售订单登录 | 受注登録、取価、折扣、納期、可用量チェック、与信チェック、提出・承認、E06 | SCR-SAL-008〜011 | P0 | 設計済 | 02-sales-order.md | SAL | 03-sales/00-overview.md |
| F-SAL-004 | 订单变更 | 承認済受注の数量・納期・価格変更、版数管理、再承認、E07、引当増減 | SCR-SAL-012〜013 | P0 | 設計済 | 02-sales-order.md | SAL | 03-sales/00-overview.md |
| F-SAL-005 | 发货通知与拣货 | DN 作成、批次指定（FIFO/FEFO/手工）、部分出荷、出荷確定（E10）、送り状 | SCR-SAL-014〜018 | P0 | 設計済 | 03-delivery-picking.md | SAL | 03-sales/00-overview.md |
| F-SAL-006 | 销售退货管理 | 返品受付、期限チェック、承認、受入検品、E11、在庫戻入、赤伝売上/AR 戻し、原価戻し | SCR-SAL-019〜022 | P0 | 設計済 | 04-sales-return.md | SAL | 03-sales/00-overview.md |
| F-SAL-007 | 销售发票与开票申请 | 开票申请（集約・税区分）、承認、发票登记（专票/普票/数电票）、赤伝、E12、AR 紐付け、金税 IF 第一版 | SCR-SAL-023〜027 | P0（金税 IF は P2） | 設計済 | 05-invoice-receivable.md | SAL | 03-sales/00-overview.md |
| F-SAL-008 | 客户对账单 | 期間集計、対账单生成・発行・顧客確認 | SCR-SAL-028〜029 | P1 | 設計済 | 05-invoice-receivable.md | SAL | 03-sales/00-overview.md |
| F-SAL-009 | 应收款查询与账龄 | 应收明細・残高・帳齢・回収予定の照会（FIN 契約に基づく投影） | SCR-SAL-030〜031 | P1 | 設計済 | 05-invoice-receivable.md | SAL | 03-sales/00-overview.md |
| F-SAL-010 | 信用管控 | 与信限度照会、FIN 与信台帳照会、与信判定、超限判定・承認連携 | SCR-SAL-032〜034 | P0 | 設計済 | 06-credit-pricing.md | SAL | 03-sales/00-overview.md |
| F-SAL-011 | 价格与促销 | MDM 価格表参照、取価シミュレーション、特価/折扣申請・承認 | SCR-SAL-035〜037 | P0（促销 P2） | 設計済 | 06-credit-pricing.md | SAL | 03-sales/00-overview.md |
| F-SAL-012 | 订单执行跟踪 | 受注残、引当/欠品、出荷予定、納期遅延、齐套状况の可視化 | SCR-SAL-038〜039 | P1 | 設計済 | 07-tracking-reports.md | SAL | 03-sales/00-overview.md |
| F-SAL-013 | 销售预测 | 月度予測入力・確定、MRP 連携（第一版対象。TODO：詳細設計が未作成） | SCR-SAL-040〜041 | P2 | 設計済（概要） | 07-tracking-reports.md | SAL | 03-sales/00-overview.md |
| F-SAL-014 | 换货管理 | 返品＋再出荷の組合せ、差額精算、関連付け | SCR-SAL-042 | P2 | 設計済（概要） | 04-sales-return.md | SAL | 03-sales/00-overview.md |
| F-SAL-015 | 销售报表 | 销售明细、毛利分析、客户排名（域内报表，RPT 連携） | SCR-SAL-043〜045 | P1 | 設計済 | 07-tracking-reports.md | SAL | 03-sales/00-overview.md |
| F-SAL-016 | 出口销售预留 | 外貨・Incoterms・通関情報の項目予約（第一版対象。TODO：概要のみ、詳細設計が未作成） | SCR-SAL-046 | P2 | 設計済（概要） | 07-tracking-reports.md | SAL | 03-sales/00-overview.md |
| F-SAL-017 | 销售订单取消与关闭 | 受注の取消（E08）、残数量クローズ、バックオーダー取消 | SCR-SAL-010（操作） | P0 | 設計済 | 02-sales-order.md | SAL | 03-sales/00-overview.md |
| F-SAL-018 | 出荷实绩照会 | 出荷実績・送り状・未出荷残の照会、再出力 | SCR-SAL-047 | P1 | 設計済 | 03-delivery-picking.md | SAL | 03-sales/00-overview.md |
| F-SYS-001 | 认证与登录 | 登录/登出/验证码/密码策略/账号锁定/首次改密/多端会话 | SCR-SYS-001、002 | P0 | 設計済 | 01-auth-login.md | SYS | 01-system/00-overview.md |
| F-SYS-002 | 用户管理 | 用户开立/变更/停用/查询/角色付与/密码重置/导入 | SCR-SYS-004〜006、009 | P0 | 設計済 | 02-user-role-permission.md | SYS | 01-system/00-overview.md |
| F-SYS-003 | 角色与权限 | 角色维护、权限树、数据范围、项目权限、SoD 检查 | SCR-SYS-007、008 | P0 | 設計済 | 02-user-role-permission.md | SYS | 01-system/00-overview.md |
| F-SYS-004 | 菜单管理 | 菜单/按钮权限树维护、路由生成、权限标识管理 | SCR-SYS-014 | P0 | 設計済 | 04-menu-dict-param.md | SYS | 01-system/00-overview.md |
| F-SYS-005 | 组织部门 | 部门树维护、负责人、层级、使用停止 | SCR-SYS-010 | P0 | 設計済 | 03-org-position.md | SYS | 01-system/00-overview.md |
| F-SYS-006 | 岗位 | 岗位维护、岗位与用户/角色关联 | SCR-SYS-011 | P1 | 設計済 | 03-org-position.md | SYS | 01-system/00-overview.md |
| F-SYS-007 | 数据字典 | 字典类型/字典项目维护、缓存刷新、使用停止 | SCR-SYS-015、016 | P0 | 設計済 | 04-menu-dict-param.md | SYS | 01-system/00-overview.md |
| F-SYS-008 | 系统参数 | 参数分组/值/数据类型/危险级维护、缓存刷新、变更审计 | SCR-SYS-017 | P0 | 設計済 | 04-menu-dict-param.md | SYS | 01-system/00-overview.md |
| F-SYS-009 | 审计日志 | 操作/登录日志记录、照会、前後値、エクスポート、異常検知 | SCR-SYS-018、019 | P0 | 設計済 | 05-audit-attachment-notify.md | SYS | 01-system/00-overview.md |
| F-SYS-010 | 附件管理 | アップロード/ダウンロード/一覧/削除、業務紐付け、検査 | SCR-SYS-020 | P0 | 設計済 | 05-audit-attachment-notify.md | SYS | 01-system/00-overview.md |
| F-SYS-011 | 消息通知与待办中心 | 站内通知、既読管理、待办/已办聚合、通知偏好 | SCR-SYS-021 | P0 | 設計済 | 05-audit-attachment-notify.md | SYS | 01-system/00-overview.md |
| F-SYS-012 | 单据编号规则 | 採番规则维护、日次/月次/年次重置、プレビュー、適用開始日 | SCR-SYS-023 | P0 | 設計済 | 06-import-export-numbering.md | SYS | 01-system/00-overview.md |
| F-SYS-013 | 导入导出中心 | 模板管理、ドライラン、非同期実行、エラー報告、履歴 | SCR-SYS-024、025 | P1 | 設計済 | 06-import-export-numbering.md | SYS | 01-system/00-overview.md |
| F-SYS-014 | 公司/工厂多组织 | 公司主体・会計主体設定、工厂组织設定（有効化・既定割当・責任者）。工厂主データは MDM（mdm_factory）を参照 | SCR-SYS-012 | P1 | 設計済 | 03-org-position.md | SYS | 01-system/00-overview.md |
| F-SYS-015 | 打印模板管理 | 帳票テンプレート登録/版管理/プレビュー/デフォルト指定 | SCR-SYS-026 | P1 | 設計済 | 07-scheduled-job-print-monitor.md | SYS | 01-system/00-overview.md |
| F-SYS-016 | 在线用户与定时任务监控 | セッション一覧・強制ログアウト、ジョブ定義/実行履歴/手動起動 | SCR-SYS-027、028 | P1 | 設計済 | 07-scheduled-job-print-monitor.md | SYS | 01-system/00-overview.md |
| F-SYS-017 | 租户与数据隔离 | 租户マスタ予約、tenant_id 付与方針、RLS 第一版有効 | SCR-SYS-013 | P0 | 設計済 | 03-org-position.md | SYS | 01-system/00-overview.md |
| F-SYS-018 | 个人中心 | プロフィール、パスワード変更、通知設定、画面設定、セッション | SCR-SYS-003 | P0 | 設計済 | 01-auth-login.md | SYS | 01-system/00-overview.md |
| F-SYS-019 | 通知模板 | 站内/邮件/短信テンプレート、変数、版管理、テスト送信 | SCR-SYS-022、030 | P1 | 設計済 | 05-audit-attachment-notify.md | SYS | 01-system/00-overview.md |
| F-SYS-020 | 系统初始化与数据维护 | 初期データ投入、キャッシュ再構築、データ整合性検査、保守 | SCR-SYS-029 | P1 | 設計済 | 07-scheduled-job-print-monitor.md | SYS | 01-system/00-overview.md |
| F-WF-001 | 流程模型管理 | BPMN モデルの登録・デプロイ・版管理・有効化/停止・プレビュー | SCR-WF-001、002 | P0 | 設計済 | 01-process-model.md | WF | 08-workflow/00-overview.md |
| F-WF-002 | 业务类型与流程映射 | 業務類型マスタ、流程マッピング、条件ルール、承認マトリクス | SCR-WF-003、004 | P0 | 設計済 | 01-process-model.md | WF | 08-workflow/00-overview.md |
| F-WF-003 | 发起审批 | 業務单据の提出・変数収集・プロセス開始・申請取消 | SCR-WF-005 | P0 | 設計済 | 02-approval-runtime.md | WF | 08-workflow/00-overview.md |
| F-WF-004 | 待办/已办/发起/抄送 | 4 種のタスク一覧、絞込・ソート・一括処理 | SCR-WF-006、008、009、010 | P0 | 設計済 | 02-approval-runtime.md | WF | 08-workflow/00-overview.md |
| F-WF-005 | 审批操作 | 同意/驳回/差戻し/加签/转办/撤回/催办/委托代理 | SCR-WF-007 | P0 | 設計済 | 02-approval-runtime.md | WF | 08-workflow/00-overview.md |
| F-WF-006 | 审批历史与流程追踪 | 承認経路タイムライン、各タスクの処理者・日時・コメント、経路図 | SCR-WF-011 | P0 | 設計済 | 02-approval-runtime.md | WF | 08-workflow/00-overview.md |
| F-WF-007 | 代理委托设置 | 期間指定の代理承認者設定、委任の取消・履歴 | SCR-WF-012 | P1 | 設計済 | 03-approval-admin.md | WF | 08-workflow/00-overview.md |
| F-WF-008 | 超时提醒与自动审批 | 24h リマインダ、48h エスカレーション、条件付自動承認、設定管理 | SCR-WF-014 | P1 | 設計済 | 03-approval-admin.md | WF | 08-workflow/00-overview.md |
| F-WF-009 | 流程实例管理 | インスタンス検索、掛起/再開、強制終了、承認者跳转（ジャンプ）、変数参照 | SCR-WF-013 | P1 | 設計済 | 03-approval-admin.md | WF | 08-workflow/00-overview.md |
| F-WF-010 | 表单字段级权限 | ノード別フィールド権限（編集可/参照のみ/非表示）の定義と適用 | SCR-WF-015 | P1 | 設計済 | 01-process-model.md、02-approval-runtime.md | WF | 08-workflow/00-overview.md |
| F-WF-011 | 审批与业务单据状态联动 | E31/E32 契約、業務ステータス遷移、冪等コールバック、補償 | （画面なし・API/イベント） | P0 | 設計済 | 02-approval-runtime.md | WF | 08-workflow/00-overview.md |
| F-WF-012 | 审批消息通知 | 承認依頼・結果・超時・催办の通知（站内/メール）、通知設定 | （SYS SCR-SYS-021 と共用） | P0 | 設計済 | 02-approval-runtime.md | WF | 08-workflow/00-overview.md |

## 改訂履歴

| 版数 | 日付 | 変更内容 | 変更者 |
|---|---|---|---|
| v1.0 | 2026-10-20 | 自动生成 | gen_matrix.py |
