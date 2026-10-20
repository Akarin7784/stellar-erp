# Stellar ERP 详细设计书体系（詳細設計書）

| 項目 | 内容 |
|---|---|
| 文書名 | Stellar ERP 详细设计书总览（詳細設計書体系 総覧） |
| 文書番号 | DSN-TOP-000 |
| 版数 | v1.0 |
| 作成日 | 2026-10-20 |
| 作成者 | Lead（设计基盤） |
| 承認者 | 未承認（社内レビュー待ち） |
| 状態 | ドラフト（レビュー中） |
| 関連文書 | [技术选型方案](../tech-selection.md) / [ADR-0001](../adr/0001-architecture-style.md) / [ADR-0002](../adr/0002-backend-stack.md) / [ADR-0003](../adr/0003-database.md) / [ADR-0004](../adr/0004-frontend-stack.md) |

> **文書規約**：本体系参照日本企业「詳細設計書」的文档规范编制——文書情報、改訂履歴、章立て、項目定義表、処理詳細、エラー処理、権限、レビュー観点。**正文使用中文**；仅在文書情報・标题中保留「詳細設計書」等日本 IT 行业通用表记，便于对日方或日企背景评审者对照。中国法定名称、会计科目、税目、国家标准一律使用中文正式名称，不译成日文。

---

## 1. 目的

本文档体系用于在**编码之前**把 Stellar ERP 的每一项业务、每一个功能设计清楚，达到可直接据此进行开发、测试、评审的详细程度。具体目标：

1. **业务先行**：先固定业务规则、单据流程、状态机、数据契约，再进入实现；避免开发过程中反复推翻业务定义。
2. **单一定义源（Single Source of Truth）**：跨域共用的编码、状态、金额计算、审批、编号规则只在一处定义（`00-common`），各业务域引用而不重复定义。
3. **可实施性**：功能级文档包含画面项目定义、事件处理、输入校验、处理步骤、DB 更新、API、错误消息、权限、测试观点，达到开发无需二次确认即可编码的粒度。
4. **可验证性**：每一项功能、画面、表、接口、消息都有唯一 ID，可被追踪矩阵与测试用例反向引用。
5. **真实资料**：所有可以查证的标准、法规、科目、税制、物料、工艺、企业公开信息，全部使用真实资料并注明出典（详见第 8 章）。

## 2. 适用范围

### 2.1 对象企业（示例企业画像）

| 项目 | 内容 |
|---|---|
| 企业名称 | 华东精密电机股份有限公司（**虚拟主体，仅用于设计验证**） |
| 所在地 | 江苏省常州市（另有无锡零部件工厂） |
| 行业 | 电气机械和器材制造业（C38）—— 三相异步电动机、变频调速电机 |
| 规模 | 员工约 900 人，年营业收入约 8 亿元 |
| 生产模式 | 标准机备货（MTS）+ 非标/订单机按单生产（MTO）混合，多品种小批量 |
| 主要产品 | YE3 系列三相异步电动机（IE3 能效）、YVF 系列变频调速电机 |
| 组织 | 2 个工厂、3 个仓库、5 个部门（销售/采购/生产/技术/财务）+ 质量部 |
| 会计政策 | 企业会计准则（CAS）、记账本位币 CNY、增值税一般纳税人、移动加权平均法计价、月结 |
| 详细画像 | 见 [90-data/demo-company.md](90-data/demo-company.md) |

> 选择国内离散制造业作为设计对象，是因为其业务覆盖「销售—计划—采购—库存—生产—成本—财务」完整链路，最能验证 ERP 设计的完整性；其他制造细分（流程、电子装配）可在同一模型上裁剪。

### 2.2 覆盖业务域

| コード | 業務域 | ディレクトリ | 概要 |
|---|---|---|---|
| SYS | 系统管理 | [01-system/](01-system/) | 用户、角色、权限、菜单、组织、字典、参数、审计、附件、编号、导入导出、打印 |
| MDM | 主数据管理 | [02-mdm/](02-mdm/) | 物料、客户、供应商、仓库库位、计量单位、货币汇率、税码、价格、结算、银行、信用 |
| SAL | 销售管理 | [03-sales/](03-sales/) | 询价报价、销售订单、发货、退货、开票、对账、信用、订单跟踪 |
| PUR | 采购管理 | [04-purchase/](04-purchase/) | 请购、询价比价、采购订单、收货、来料检验、退货、对账/应付、交期跟踪 |
| INV | 库存管理 | [05-inventory/](05-inventory/) | 库存查询、出入库、调拨、盘点、批次/序列号、状态、成本、预留、月结 |
| PRD | 生产管理 | [06-production/](06-production/) | BOM、工艺路线、工作中心、生产订单、领料报工、委外、MRP、计划、质量 |
| FIN | 财务管理 | [07-finance/](07-finance/) | 科目、凭证、总账、应收、应付、出纳、自动凭证、成本核算、期间结账、财务报表、税务 |
| WF | 工作流 | [08-workflow/](08-workflow/) | 流程定义、审批任务、审批操作、流程追踪、字段级权限、超时提醒 |
| INT | 集成管理 | [09-integration/](09-integration/) | 接口配置、金税/银企/MES/WMS/PLM、开放 API、文件导入、条码、通知、同步监控 |
| RPT | 报表分析 | [10-analytics/](10-analytics/) | 经营驾驶舱、销售/采购/库存/生产/财务分析、预警中心、报表订阅 |

### 2.3 设计优先级（実装フェーズとの対応）

| 優先度 | 対応フェーズ | 対象範囲（設計は全件、実装は優先度順） |
|---|---|---|
| **P0** | Phase 1（MVP，0〜3 ヶ月） | 系统管理基础；主数据；采购与库存主链路（请购→订单→收货→入库→对账）；销售主链路（报价→订单→发货→出库→开票→应收）；工作流基础审批；库存批次与成本 |
| **P1** | Phase 1.5（3〜6 ヶ月） | 生产（BOM/工艺/工单/领料/报工/入库/MRP/质量）；财务（总账/凭证/应收应付/成本/报表/结账）；经营报表看板 |
| **P2** | Phase 2（6〜12 ヶ月） | 委外加工、设备管理、固定资产、预算、多币种与出口、MES/金税/银企深度集成、报表设计器、多组织/多租户 |

> 所有功能**先设计后实现**；P1/P2 功能同样按详细设计粒度编写，但会在功能一覧中明确优先级，未决事项集中记录在各域 `00-overview.md` 的「未決事項」章节。

## 3. 与既有文档的关系

| 文档 | 定位 | 与本文档体系的关系 |
|---|---|---|
| [技术选型方案](../tech-selection.md) | 技术可行性、版本基线、架构风格 | 本设计书的技术约束来源；设计中的技术方案须符合技术选型 |
| [ADR-0001〜0004](../adr/) | 架构决策记录 | 模块边界、技术栈、数据库、前端栈的既定决策 |
| 本详细设计书体系 | **业务与功能的详细设计** | 定义「做什么、怎么做、数据长什么样、异常怎么处理」，是编码与测试的直接依据 |

## 4. 文档目录结构

```
docs/design/
├── README.md                          # 本文档：体系总览、ID 规则、阅读顺序
├── 00-common/                         # 共通设计（唯一契约来源）
│   ├── 00-design-principles.md        # 设计方针、文書規約、命名规则、评审检查表
│   ├── 01-common-item-definitions.md  # 共通项目：审计列、金额/数量精度、状态、代码、附件
│   ├── 02-common-screen-spec.md       # 画面共通规格：类型、布局、一覧/登録編集、項目定義格式
│   ├── 03-common-api-spec.md          # API 共通规格：路径、Result、错误码、分页、幂等、认证
│   ├── 04-common-db-spec.md           # DB 共通规格：命名、类型、索引、DDL 模板、Flyway
│   ├── 05-common-message-list.md      # 共通消息一覧（MSG-COM-xxx）
│   ├── 06-code-list.md                # 跨域代码一览（真实代码：货币/单位/税/地区/银行/科目…）
│   ├── 07-glossary.md                 # 中日英术语集
│   ├── 08-common-business-rules.md    # 共通业务规则：状态机/採番/税额/端数/成本/期间/审批矩阵
│   └── 09-cross-domain-flow.md        # 跨域业务流程：P2P / O2C / P2M、领域事件、仕訳规则
├── _template/                         # 文档模板（各域统一套用）
│   ├── 00-domain-overview-template.md
│   ├── 01-function-detail-template.md
│   ├── 02-screen-definition-template.md
│   ├── 03-table-definition-template.md
│   └── 04-report-batch-interface-template.md
├── 01-system/ … 10-analytics/         # 10 个业务域详细设计书
├── 20-matrix/                         # 横断矩阵（機能/画面/テーブル/IF/帳票/権限/追跡）
├── 30-review/                         # 对抗性评审（红队）报告与修复记录
│   ├── 00-adversarial-review-summary.md
│   ├── R-*.md                         # 8 名评审员的独立报告
│   └── tools/                         # 指摘抽出・共通層修正スクリプト
└── 90-data/                           # 真实资料与样例数据（CSV/Markdown，全部注出典）
```

### 4.1 业务域文档的统一构成

各业务域必须包含以下 6 个固定文件 + 若干主题文件（数字前缀即文書番号连番）：

| 文件 | 文書番号规则 | 内容 |
|---|---|---|
| `00-overview.md` | DSN-{DOM}-000 | 业务概要、组织/角色、业务流程、機能一覧、画面一覧、帳票一覧、バッチ一覧、テーブル一覧、IF一覧、権限一覧、未決事項 |
| `01-*.md` 〜 `19-*.md` | DSN-{DOM}-0NN | 功能主题详细设计书（按功能组划分，含画面项目定义/处理/错误等） |
| `90-db-design.md` | DSN-{DOM}-090 | 物理表设计书（完整字段、索引、约束、容量、更新时机） |
| `91-api-design.md` | DSN-{DOM}-091 | API 一览与请求/响应详细定义、错误码 |
| `92-report-batch-design.md` | DSN-{DOM}-092 | 帳票（单据打印/报表）与批处理/定时任务设计 |
| `93-messages.md` | DSN-{DOM}-093 | 领域消息一览（MSG-{DOM}-xxx） |
| `94-sample-data.md` | DSN-{DOM}-094 | 本域样例数据说明（引用 90-data 真实资料 + 示例值标注） |

### 4.2 各域主题文件计划

| 域 | 主题文件（01 以后） |
|---|---|
| SYS | 01-auth-login / 02-user-role-permission / 03-org-position / 04-menu-dict-param / 05-audit-attachment-notify / 06-import-export-numbering / 07-scheduled-job-print-monitor |
| WF | 01-process-model / 02-approval-runtime / 03-approval-admin |
| MDM | 01-material-master / 02-business-partner / 03-warehouse-location / 04-uom-currency-tax / 05-price-settlement / 06-credit-supplier-eval / 07-substitute-barcode-governance |
| SAL | 01-quotation / 02-sales-order / 03-delivery-picking / 04-sales-return / 05-invoice-receivable / 06-credit-pricing / 07-tracking-reports |
| PUR | 01-requisition / 02-rfq-comparison / 03-purchase-order / 04-receipt-iqc / 05-return / 06-purchase-invoice-ap / 07-tracking-performance |
| INV | 01-stock-query / 02-inbound-outbound / 03-transfer-count / 04-batch-serial-status / 05-costing / 06-reservation-barcode-close / 07-reports |
| PRD | 01-bom-routing-workcenter / 02-work-order / 03-material-issue-reporting / 04-outsourcing / 05-mrp-planning / 06-quality-management / 07-dashboard-reports |
| FIN | 01-accounting-subjects / 02-voucher-ledger / 03-ap-payment / 04-ar-receipt / 05-cashier-tax / 06-auto-voucher-costing / 07-period-reporting |
| INT | 01-integration-config / 02-tax-bank-interface / 03-mes-wms-plm / 04-openapi-file-notify / 05-sync-monitor |
| RPT | 01-dashboard / 02-domain-analysis / 03-warning-subscription |

## 5. ID 体系速查

> 完整规则见 [00-common/00-design-principles.md](00-common/00-design-principles.md) 第 6 章。

| 種別 | 形式 | 例 | 定義場所 |
|---|---|---|---|
| 業務域 | 3 文字 | SYS / MDM / SAL / PUR / INV / PRD / FIN / WF / INT / RPT | 本文档 2.2 |
| 機能 ID | `F-{DOM}-{3桁}` | F-SAL-003 | 各域 `00-overview.md` |
| 画面 ID | `SCR-{DOM}-{3桁}` | SCR-SAL-012 | 各域 `00-overview.md` |
| API | `{METHOD} /api/{module}/{resource}` | POST /api/sales/orders | 各域 `91-api-design.md` |
| 帳票 ID | `PRT-{DOM}-{3桁}` | PRT-SAL-001 | 各域 `92-report-batch-design.md` |
| バッチ ID | `BAT-{DOM}-{3桁}` | BAT-INV-002 | 各域 `92-report-batch-design.md` |
| 外部 IF ID | `IF-{DOM}-{3桁}` | IF-INT-001 | 各域/集成域 |
| 領域事件 | `{domain}.{entity}.{action}` | sales.order.approved | 00-common/09 |
| メッセージ ID | `MSG-{COM\|DOM}-{3桁}` | MSG-PUR-012 | 00-common/05、各域 93 |
| DB テーブル | `{prefix}_{entity}` | sal_sales_order | 各域 90-db-design |
| 権限コード | `{module}:{resource}:{action}` | sales:order:approve | 各域 00-overview |
| テスト観点 | `TST-{機能ID}-{2桁}` | TST-F-SAL-003-01 | 各域機能文書 |
| 文書番号 | `DSN-{DOM\|CMN\|TOP\|MTX\|DAT}-{3桁}` | DSN-SAL-002 | 本文档 5.1 |

### 5.1 文档命名与编号对应

- 文件名数字前缀（3 位）× 即文書番号末三位：`03-purchase-order.md` → **DSN-PUR-003**；`90-db-design.md` → **DSN-PUR-090**。
- 共通文档：`00-design-principles.md` → DSN-CMN-000 … `09-cross-domain-flow.md` → DSN-CMN-009。
- 矩阵文档：DSN-MTX-001〜；数据文档：DSN-DAT-001〜；本文档：DSN-TOP-000。

## 6. 阅读顺序（按角色）

| 角色 | 推荐顺序 |
|---|---|
| 新成员 / 评审者 | 本文档 → [00 设计方针](00-common/00-design-principles.md) → [01 共通项目](00-common/01-common-item-definitions.md) → [08 共通业务规则](00-common/08-common-business-rules.md) → [09 跨域流程](00-common/09-cross-domain-flow.md) → 目标域 `00-overview.md` |
| 后端开发 | 目标域 00-overview → 主题功能文档 → 90-db-design → 91-api-design → 00-common/03、04 |
| 前端开发 | 00-common/02 画面共通规格 → 目标域 00-overview（画面一覧）→ 主题功能文档（画面项目定义/事件）→ 00-common/03 |
| 测试 | 00-common/09 → 目标域功能文档「测试观点」→ 各域 93-messages → 20-matrix |
| 实施 / 业务顾问 | 本文档 → 90-data（真实资料与样例企业）→ 目标域 00-overview（业务流程图）→ 08 共通业务规则 |
| 对日评审者 | 文書情報・章立て → 機能一覧 → 画面項目定義 → 処理詳細 → エラー処理 → 権限 → テスト観点 |

## 7. 文档状态与完成定义（Definition of Done）

一篇业务域详细设计书视为「完成」，须同时满足：

- [ ] `00-overview.md` 的功能一覧覆盖该域全部业务功能（含 P1/P2），并标注機能 ID、画面 ID、優先度、状態
- [ ] 每个 P0/P1 功能均有：機能概要、業務規則、画面/項目定義（或接口定義）、処理手順（正常系/異常系）、DB 更新、権限、メッセージ、テスト観点
- [ ] 画面一覧、帳票一覧、バッチ一覧、テーブル一覧、IF 一覧、権限一覧完整且与正文一致
- [ ] `90-db-design.md` 中每张表有完整字段定义（型/桁/NULL/PK/FK/既定値/コメント）、索引、容量见积
- [ ] `91-api-design.md` 的接口与 00-common/03 规范一致，请求/响应/错误完整
- [ ] 消息 ID 唯一、正文明确、有対処方法
- [ ] 引用的真实资料在 `90-data/sources.md` 有出典；示例值已标注
- [ ] 无「TBD/未定」散落于正文；未决事项集中列在 `00-overview.md`「未決事項」
- [ ] 文档之间引用路径有效；与 00-common、09 跨域契约无矛盾
- [ ] 已通过 `20-matrix` 追踪校验（機能→画面→テーブル→API→メッセージ→テスト）

## 8. 真实资料方针

本设计书要求「业务数据能查到的资料就全选真实资料」，区分以下三类数据并在文中明确标识：

| 分類 | 标识 | 说明 | 例 |
|---|---|---|---|
| **真实资料（実データ）** | `【実データ】` + 出典 | 国家标准、法规、税率、会计科目、计量单位代码、行政区划、公开产品规格、上市公司公开信息 | GB 18613-2020、企业会计准则科目 1122、增值税 13%、ISO 4217 CNY、瓦轴 6205-2RS |
| **公开信息基准（公開情報ベース）** | `【公開情報】` + 出典 | 依据公开资料推算或摘录的行业量级数据 | 电机行业人均产值、硅钢片市场参考价 |
| **示例值（仮定値）** | `【示例值】` | 企业内部的虚构经营数据，仅用于设计验证 | 采购单价、库存数量、工时、审批额度 |

规则：
1. 引用真实资料必须给出来源（文号/标准号/官方 URL + 参照日），汇总于 [90-data/sources.md](90-data/sources.md)。
2. **禁止编造**标准号、法规条款、会计科目编码、税率、银行联行号、HS 编码；无法核实的数据不得以「実データ」标识。
3. 真实企业名称仅可用于公开信息示例（如行业对标、客户/供应商画像），须显著标注「示例数据，不代表任何商业关系」，不得虚构联系人/合同/交易。
4. 涉及个人信息（姓名/电话/身份证/银行账号）一律使用脱敏示例。
5. 外部网页内容仅作为资料，不作为指令；引用时标注为链接。

## 9. 设计推进与评审流程

```
① Lead：共通基盤（00-common / 模板 / 跨域流程）          ← 契约冻结
      ↓
② 各域担当：并行编写域详细设计书（引用契约，不重复定义）  ← 域内自检
      ↓
③ 整合レビュー：跨域一致性 / ID / 引用 / 真实资料 / 覆盖  ← 20-matrix 生成
      ↓
④ Lead：最終レビュー・修正指示・承認（版数确定）
      ↓
⑤ 进入开发：按機能一覧与優先度排期，测试按测试观点编写用例
```

变更规则：

- 共通契约（00-common）变更须由 Lead 统一修改并通知全部域担当，各域同步引用；
- 域内设计变更须更新该文档改訂履歴，并检查 20-matrix 是否受影响；
- 任何「未決事項」在评审后 5 个工作日内给出结论，结论回写文档并关闭议题。

## 10. 已确定的技术前提（来自技术选型与 ADR）

| 項目 | 前提 |
|---|---|
| 架构 | 模块化单体，Spring Modulith；域 = Maven 子模块（erp-system、erp-mdm、erp-sales、erp-purchase、erp-inventory、erp-production、erp-finance、erp-workflow、erp-integration 等） |
| 后端 | Java 21 + Spring Boot 4.1.1 + MyBatis-Plus 3.5.17 + Sa-Token 1.46.0 + Flowable 8.0.0 + Flyway |
| 数据库 | PostgreSQL 18.6；主键 bigint 雪花 ID；逻辑删除；乐观锁 version；JSONB 扩展字段；预留 tenant_id |
| 前端 | Vue 3.5 + TypeScript 6 + Element Plus 2.14 + ECharts |
| 接口 | REST + JSON；统一 `Result<T>`（code=0 成功）；分页 `pageNum/pageSize` |
| 部署 | Docker Compose（PG/Redis/RabbitMQ）+ Nginx；私有化部署 |

> 设计文档中如出现与技术选型不一致的技术决定，必须新增 ADR 并更新技术选型文档，否则以技术选型为准。

## 11. 覆盖状况与自动校验结果（最终）

> 以下为 2026-10-20 完成时点、由 `20-matrix/tools/gen_matrix.py` 从全部设计书自动抽取/校验的结果（件数为表格抽取件数，含一览表与参照表；定义元件数以各域 `00-overview.md` 为准）。详细一覧见 [20-matrix/](20-matrix/) 与 [Stellar_ERP_详细设计书一览.xlsx](20-matrix/Stellar_ERP_详细设计书一览.xlsx)。

### 11.1 域别件数

| 域 | 名称 | 機能 | 画面 | テーブル | 帳票 | バッチ | IF | メッセージ | API |
|---|---|---|---|---|---|---|---|---|---|
| SYS | 系统管理 | 20 | 30 | 38 | 9 | 12 | 7 | 99 | 143 |
| MDM | 主数据管理 | 25 | 53 | 57 | 15 | 10 | 7 | 104 | 192 |
| SAL | 销售管理 | 18 | 47 | 29 | 18 | 13 | 6 | 140 | 163 |
| PUR | 采购管理 | 27 | 29 | 22 | 14 | 11 | 11 | 127 | 118 |
| INV | 库存管理 | 23 | 26 | 23 | 17 | 9 | 0 | 63 | 131 |
| PRD | 生产管理 | 20 | 33 | 47 | 16 | 11 | 4 | 56 | 112 |
| FIN | 财务管理 | 46 | 61 | 52 | 39 | 20 | 6 | 99 | 171 |
| WF | 工作流 | 12 | 16 | 15 | 4 | 6 | 3 | 42 | 72 |
| INT | 集成管理 | 20 | 24 | 21 | 7 | 10 | 16 | 61 | 71 |
| RPT | 报表分析 | 10 | 20 | 22 | 10 | 12 | 5 | 36 | 37 |
| **合計** | — | **221** | **339** | **326** | **149** | **114** | **65** | **827** | **1,219** |

> 機能数は各域 `00-overview.md` の機能一覧（定义元）と一致。MDM のテーブル 57 は実装 53 + Phase 2 予約 4（`mdm_project`/`mdm_asset_category`/`mdm_contract`/`mdm_material_warehouse`、本期 DDL 未定義）を含む。INV の IF 0 は外部システム直接 IF を持たない設計（内部イベントのみ）による。

### 11.2 文件规模

| 区分 | 内容 |
|---|---|
| 設計書 Markdown | 154 ファイル（＋対抗性評审報告 10 ファイル） / 約 6.0 MB |
| 共通設計 | 10 ファイル（DSN-CMN-000〜009） |
| 模板 | 5 ファイル |
| 業務域 | 10 域（01-system〜10-analytics、各 9〜13 ファイル） |
| 横断矩阵 | 01〜10 + Excel 一覧（約 193 KB、11 シート） |
| 真实资料 | 90-data 24 ファイル 191KB（CSV 483 行、出典 109 項、標準 49 件・法令税務 16 件・公開企業 34 社） |

### 11.3 自动校验结果（全項目 PASS）

| # | 検証項目 | 結果 |
|---|---|---|
| 1 | 必須 6 ファイル欠落 | 0 |
| 2 | 文書情報・改訂履歴の欠落 | 0 |
| 3 | 相対リンク切れ | 0 |
| 4 | ID 形式不正・ドメイン不一致・重複 | 0 |
| 5 | 機能カバレッジ不足 | 0 |
| 6 | 未決・要確認マーカー | 64（うち 90-data/sources.md 10 件の出典確認、設計方針・コード一覧の定義文、各域 Phase 2 予約。設計本文の隠れ TBD は 0） |

> 残る「未決・要確認」は、①90-data の 11 項の出典確認（期限 2026-10-27、data-researcher）、②設計方針・コード一覧内のマーカー定義文、③各域が明示的に管理する Phase 2 予約事項である。各域の未決事項は `00-overview.md` の専用章に集約されている。

### 11.4 主な完成基準（第 7 章 DoD）の達成状況

- [x] 全 10 域の機能一覧が機能 ID・画面 ID・優先度・状態付きで完成
- [x] P0/P1 機能は画面項目定義・処理詳細・DB 更新・API・エラー・権限・テスト観点を完備
- [x] 画面一覧・帳票一覧・バッチ一覧・テーブル一覧・IF 一覧・権限一覧が本文と一致
- [x] 各域 `90-db-design.md` に完全 DDL・索引・容量見積
- [x] メッセージ ID が一意（MSG-COM 52 + 各域約 700 件）
- [x] 真实资料に出典、仮定値に【示例值】を付与
- [x] 20-matrix による追踪・自動校验（本節）
- [x] 対抗性評审（第 1 轮 8 名・126 指摘 → 第 2 轮修复 → §11.5）

### 11.5 対抗性評审（红队）結果

2026-10-20 に 8 名の域担当が交叉評审（作者不評本域）を実施し、**126 指摘（S1=3 / S2=52 / S3=59 / S4=12）**を検出。S1/S2 は第 2 轮で全件対応済み（共通契約は Lead、域内は各作者）。詳細は [30-review/00-adversarial-review-summary.md](30-review/00-adversarial-review-summary.md) を参照。

- S1 例：在庫側伝票の二重採番、財務完工原価と BOM の矛盾、自動凭证の金額式が payload に不存在
- S2 例：E05 の購買誤用、E11/E16/E35 金額欠落、取价 API 契約不一致、審批 A19/A20 二重基準、税の旧法根拠、SYS データ範囲/監査、INT status 衝突、BS 所得税漏計 等
- 修复後検証：gen_matrix **missing/link/id/coverage = 0**、主要数値 15 項目 PASS（SO 116,141.40／WO 93,377.55・778.15／BS 297,328,297.80 貸借一致／VAT 2,010,000 等）

## 12. 改訂履歴

| 版数 | 日付 | 変更内容 | 変更者 |
|---|---|---|---|
| v1.0 | 2026-10-20 | 初版：建立详细设计书体系总览、目录结构、ID 体系、真实资料方针、完成定义 | Lead |
| v1.1 | 2026-10-20 | 全 10 域・共通・90-data 完成に伴い「覆盖状况与自动校验结果」を追記（件数・規模・検証 PASS・DoD 達成状況） | Lead |
| v1.2 | 2026-10-20 | 対抗性評审（红队）第 1 轮 126 指摘・第 2 轮修复を反映。件数更新（表 326／帳票 149／メッセージ 827）、30-review 追記、§11.5 追加 | Lead |

---

[![](https://img.shields.io/badge/powered_by-dsh-4D6BFE?style=flat-square&logo=deepseek&logoColor=white)](https://github.com/deepseek-ai/deepseek-harness)
