# Stellar ERP 设计文档 画面/API/DDL 一致性审计报告（前端视角）

- 审计对象：`Stellar0502/stellar-erp` main @ `b28c541`（2026-10-20，含 #38/#42/#44），行号以该提交为准。
- 方法：脚本解析 10 个域 `90-db-design.md` 中全部 `CREATE TABLE`（共 322 张表，含一行多列写法）；解析各域 `0x-*.md` 中所有带「DB 項目」列的画面项目定义表，按列名、型/桁与 DDL 比对；解析 POST/PUT/PATCH 请求 JSON 示例的键；比对 `20-matrix/02-screen-list.md`（339 画面）。脚本命中项均已人工复核，下文只列复核确认的问题；误报（如引用子表名、显示用 code/name 联表字段、上下文表识别错误）已剔除。
- 局限：一覧画面「列」为自由文本未逐列比对；`91-api-design.md` 中只有带 JSON 示例的接口能做字段比对；类型检查只覆盖「DB 項目」为单列的行。未覆盖部分不代表无问题。
- 严重度：**S1** 阻塞 SQL 建表或 SQL 层业务跑通；**S2** 名称/类型/长度不一致，建表前需定；**S3** 文档整洁性。

## 处理决定

1. 画面/API 与 DDL 命名冲突时，**以 DDL 为准**，改画面/API 文档的映射。
2. PUR：请购行追溯统一使用 `purchase_requisition_line_id`，修正画面文档与 ER 图中的 `pr_line_id`。
3. INV：DDL 增加列——`inv_stock_txn_line` 增加 `from_status`、`to_status`（状态转换用）和 `inspection_flag`（入库检验要否，默认取自 `mdm_material.inspection_required`）。已决（蓝色大肥鱼，2026-10-20）。
4. `inspection_flag` 规则：以 `05-inventory/02-inbound-outbound.md:157` 为准，ON→明细 `stock_status=10 待检`，OFF→`20 可用`；`:360` 的「ON で状態 20」为笔误。已决（蓝色大肥鱼，2026-10-20）。
5. FIN（SCR-FIN-030、054～061）与 RPT（SCR-RPT-002、019、020）缺失的画面设计，在各域文档 PR 中补齐。

## 0. S1 汇总（优先处理）

1. **[INV] 库存状态转换明细映射到不存在的列**
   - 画面/API 侧：`05-inventory/04-batch-serial-status.md:214-215` 画面 `fromStatus`/`toStatus` → DB `from_status`/`to_status`
   - DDL 侧：`05-inventory/90-db-design.md:439`（`inv_stock_txn_line`）只有单列 `stock_status`（:454）；处理手顺 `04-batch-serial-status.md:326-327` 实际是生成 ST_OUT/ST_IN 两行
   - 建议：已决：加列（见「处理决定」第 3 条）。
2. **[INV] 入库单「检验要否」无对应列且规则自相矛盾**
   - 画面/API 侧：`05-inventory/02-inbound-outbound.md:360` `inspectionFlag` → `inspection_flag`，备注「ON で状態 20」
   - DDL 侧：`inv_stock_txn`（`05-inventory/90-db-design.md:299`）无 `inspection_flag`；同文件 `02-inbound-outbound.md:157` 写的是 `inspection_required=false` 时为 20 可用（即 ON 应为 10 待检）
   - 建议：已决（蓝色大肥鱼，2026-10-20）：`inspection_flag` 加在 `inv_stock_txn_line`；规则按 `:157`（ON→10 待检，OFF→20 可用），`:360` 为笔误需改正（见「处理决定」第 3、4 条）。直接影响 SQL 场景里收货后可用量。
3. **[PUR] 请购行追溯列名不一致**
   - 画面/API 侧：`04-purchase/03-purchase-order.md:242`、`04-purchase/02-rfq-comparison.md:196` 画面 `prLineId` → `pr_line_id`；API 示例 `04-purchase/03-purchase-order.md:497` `prLineId`；ER 图 `04-purchase/90-db-design.md:69` 也写 `pr_line_id`
   - DDL 侧：DDL 实际列名 `purchase_requisition_line_id`（`04-purchase/90-db-design.md:763` PO 行、`:403` RFQ 行）
   - 建议：改画面/ER 文档的 DB 項目为 `purchase_requisition_line_id`（DTO 名 `prLineId` 可保留但须写明映射）。请购→询价→订单是 SQL 场景主链路。
4. **[FIN] 全量 v1 后，9 个原 P2 财务画面无画面设计，DDL 只是「概要」**
   - 画面/API 侧：`02-screen-list.md:46,70-77`（SCR-FIN-030、054～061 标 P2）；`07-finance/07-period-reporting.md:155-160` 只有一行概要，无项目定义；SCR-FIN-055/057 在任何详细设计中都未单独出现
   - DDL 侧：`07-finance/90-db-design.md:1615`「6.11 Phase 2 テーブル（概要 DDL）」：缺 `deleted`/`ext_data` 等公共列、无列注释表；坏账准备只有 `bad_debt_rate`（:586），无计提单据表
   - 建议：两边都要补：业务分析补画面设计书（项目定义、校验、API）；数据库与运维按 `04-common-db-spec.md` 补齐公共列、约束、索引、RLS 后再建迁移。
5. **[RPT] 画面一览中有画面但无任何设计**
   - 画面/API 侧：`02-screen-list.md:261` SCR-RPT-019 数据质量检查、`:262` SCR-RPT-020 移动端/大屏（P2）；10-analytics 各详细设计中均未出现这两个 ID
   - DDL 侧：DDL 有 `rpt_data_quality_check`（`10-analytics/90-db-design.md:674`），但无画面/API 使用说明
   - 建议：补画面设计（10-analytics），或经 Yuri 确认后从画面一览删除。

## 1. 各域明细

### 01-system（SYS）

- 统计：S1 0、S2 1、S3 1；文档内 Phase 2/3/P2 字样 50 处；画面一览中本域 30 个画面，其中无独立「项目定义」小节（标题未出现该画面 ID）的 9 个；DDL 非公共列 421 个，其中在本域画面/API 文档中从未出现（snake 或 camel）的 80 个（d 类，低优先级）。

| 严重度 | 类别 | 问题 | 画面/API 证据 | DDL 证据 | 说明 | 建议修改方 |
|---|---|---|---|---|---|---|
| S2 | b | 通知设置 `notifySms` 仍标 Phase 2 | `01-system/01-auth-login.md:175` | — | 按全量方案去掉 Phase 2 标注（存于 `sys_user_preference.preference_value` JSONB，`01-system/90-db-design.md:1485`，结构未定义） | 改画面文档，并在 DDL 说明里写明 JSON 键（notifyInApp/notifyEmail/notifySms/theme/pageSize） |
| S3 | b | 审计日志检索条件 `dateFrom` 为 DATE，DDL `occurred_at` 为 TIMESTAMPTZ | `01-system/05-audit-attachment-notify.md:122` | `sys_audit_log.occurred_at` | 检索条件按日期，后端需转为时间范围（含时区） | 画面文档注明转换规则即可 |

<details><summary>无项目定义小节的画面（9）</summary>

SCR-SYS-006、SCR-SYS-009、SCR-SYS-011、SCR-SYS-013、SCR-SYS-015、SCR-SYS-019、SCR-SYS-020、SCR-SYS-025、SCR-SYS-030

</details>

<details><summary>d 类：未被画面/API 引用的 DDL 列示例（前 30 / 共 80）</summary>

`sys_company.short_name`、`sys_company.tax_no`、`sys_company.legal_representative`、`sys_company.postal_code`、`sys_company.phone`、`sys_company.invoice_title`、`sys_company.bank_account_name`、`sys_tenant.tenant_code`、`sys_tenant.tenant_name`、`sys_tenant.contact_name`、`sys_tenant.contact_phone`、`sys_tenant.max_user_count`、`sys_tenant.expire_date`、`sys_position.position_category`、`sys_position.is_manager`、`sys_user.gender`、`sys_user.birth_date`、`sys_menu.is_cache`、`sys_menu.is_affix`、`sys_dict_type.dict_name`、`sys_dict_type.is_tree`、`sys_dict_item.dict_type_id`、`sys_param.param_name`、`sys_param.param_group`、`sys_param.default_value`、`sys_param.effective_scope`、`sys_number_rule.separator`、`sys_audit_log.user_agent`、`sys_login_log.login_type`、`sys_login_log.login_result`

</details>

### 02-mdm（MDM）

- 统计：S1 0、S2 5、S3 0；文档内 Phase 2/3/P2 字样 73 处；画面一览中本域 53 个画面，其中无独立「项目定义」小节（标题未出现该画面 ID）的 28 个；DDL 非公共列 620 个，其中在本域画面/API 文档中从未出现（snake 或 camel）的 73 个（d 类，低优先级）。

| 严重度 | 类别 | 问题 | 画面/API 证据 | DDL 证据 | 说明 | 建议修改方 |
|---|---|---|---|---|---|---|
| S2 | b | 物料一覧分类名长度不一致 | `02-mdm/01-material-master.md:360` VARCHAR(64) | `02-mdm/90-db-design.md:168` `category_name VARCHAR(100)` | 以 DDL 为准 | 改画面文档为 100 |
| S2 | b | 银行账号长度不一致 | `02-mdm/05-price-settlement.md:377` `account_no` VARCHAR(32) | `02-mdm/90-db-design.md:795` VARCHAR(64) | 以 DDL 为准（且 DDL 注释建议加密，加密后需更长） | 改画面文档 |
| S2 | b | 信用检查规则 `check_timing`/`exposure_scope` 画面写 SMALLINT[]，DDL 为 JSONB | `02-mdm/06-credit-supplier-eval.md:181-182` | `02-mdm/90-db-design.md:1258-1259` | 两者都能表达，但前端/API 序列化需统一 | 改画面文档写「JSONB（SMALLINT 数组）」 |
| S2 | b | `col_owner`/`assignee` 显示列标 VARCHAR(64)，DB 項目却写 BIGINT 的 id 列 | `02-mdm/02-business-partner.md:229,303`、`02-mdm/07-substitute-barcode-governance.md:227` | `mdm_customer.owner_user_id`、`mdm_data_quality_issue.assignee_id` BIGINT | 显示的是用户名（联表），存的是 id | 画面文档 DB 項目改为「`owner_user_id`→sys_user 名称」 |
| S2 | a | 库位批量生成 API 的区间参数无列（属于操作参数，非存储字段） | `02-mdm/03-warehouse-location.md:382-388`（shelfFrom/To、levelFrom/To、positionFrom/To、mode） | — | 正常：属请求参数 | API 文档注明「仅请求参数，不落库」即可 |

<details><summary>无项目定义小节的画面（28）</summary>

SCR-MDM-003、SCR-MDM-004、SCR-MDM-005、SCR-MDM-006、SCR-MDM-013、SCR-MDM-014、SCR-MDM-015、SCR-MDM-023、SCR-MDM-024、SCR-MDM-025、SCR-MDM-026、SCR-MDM-034、SCR-MDM-043、SCR-MDM-045、SCR-MDM-047、SCR-MDM-051、SCR-MDM-053、SCR-MDM-055、SCR-MDM-056、SCR-MDM-061、SCR-MDM-063、SCR-MDM-074、SCR-MDM-083、SCR-MDM-091、SCR-MDM-093、SCR-MDM-095、SCR-MDM-096、SCR-MDM-097

</details>

<details><summary>d 类：未被画面/API 引用的 DDL 列示例（前 30 / 共 73）</summary>

`mdm_material_category.category_level`、`mdm_material_category.default_uom_code`、`mdm_material_his.operation_type`、`mdm_material_barcode.barcode_rule_code`、`mdm_material_barcode.label_qty`、`mdm_material_barcode.print_count`、`mdm_material_barcode.printed_at`、`mdm_code_rule.code_pattern`、`mdm_code_rule.prefix`、`mdm_code_rule.serial_length`、`mdm_code_rule.sequence_key_template`、`mdm_code_rule.reset_cycle`、`mdm_code_rule.allow_manual`、`mdm_ext_field.field_code`、`mdm_ext_field.data_type`、`mdm_ext_field.is_required`、`mdm_ext_field.enum_options`、`mdm_ext_field.validation_expression`、`mdm_ext_field.display_order`、`mdm_customer_contact.contact_wechat`、`mdm_customer_his.operation_type`、`mdm_supplier_address.address_type`、`mdm_supplier_qualification.attachment_id`、`mdm_supplier_his.operation_type`、`mdm_partner_bank_account_his.account_id`、`mdm_uom.uom_name_en`、`mdm_currency.currency_name`、`mdm_currency.symbol`、`mdm_tax_rate.tax_code_id`、`mdm_tax_rate.effective_to`

</details>

### 03-sales（SAL）

- 统计：S1 0、S2 2、S3 1；文档内 Phase 2/3/P2 字样 156 处；画面一览中本域 47 个画面，其中无独立「项目定义」小节（标题未出现该画面 ID）的 24 个；DDL 非公共列 602 个，其中在本域画面/API 文档中从未出现（snake 或 camel）的 65 个（d 类，低优先级）。

| 严重度 | 类别 | 问题 | 画面/API 证据 | DDL 证据 | 说明 | 建议修改方 |
|---|---|---|---|---|---|---|
| S2 | a | 红冲发票 API 的 `redType`（FULL/…）无对应列 | `03-sales/91-api-design.md:461` | `sal_invoice`（`03-sales/90-db-design.md:966`）只有 `invoice_kind`、`original_invoice_id`、`red_reason`，无红冲类型；`returnId` 在 `sal_invoice` 中也未见（是否经 `sal_invoice_relation` 关联，文档未写） | 部分/全额红冲在 SQL 层无法区分 | DDL 加 `red_type` 或在 API 文档说明由明细推导；`returnId` 落在哪张表需后端/DB 明确 |
| S2 | phase | SCR-SAL-040/041 销售预测、SCR-SAL-046 出口销售仍标 Phase2；换货按钮「Phase2 詳細」 | `03-sales/07-tracking-reports.md:124-125,129,166,208`、`03-sales/04-sales-return.md:329`、`02-screen-list.md:308`；受注 Incoterms 项目 `03-sales/02-sales-order.md:32-33` 标「Phase2/予約項目」，BR-18 `:72` 限定 CNY | DDL 已有 `sal_sales_forecast`（`03-sales/90-db-design.md:1310`） | 全量 v1 需去掉分期并补齐外币/Incoterms 的业务校验 | 改设计文档（业务分析） |
| S3 | a | `includeZeroBalance`/`sendAfterGenerate` 为操作参数 | `03-sales/05-invoice-receivable.md:644-645` | — | 正常 | API 文档注明不落库 |

<details><summary>无项目定义小节的画面（24）</summary>

SCR-SAL-001、SCR-SAL-003、SCR-SAL-004、SCR-SAL-006、SCR-SAL-007、SCR-SAL-010、SCR-SAL-011、SCR-SAL-012、SCR-SAL-013、SCR-SAL-018、SCR-SAL-022、SCR-SAL-023、SCR-SAL-025、SCR-SAL-027、SCR-SAL-028、SCR-SAL-029、SCR-SAL-030、SCR-SAL-031、SCR-SAL-034、SCR-SAL-035、SCR-SAL-036、SCR-SAL-042、SCR-SAL-046、SCR-SAL-047

</details>

<details><summary>d 类：未被画面/API 引用的 DDL 列示例（前 30 / 共 65）</summary>

`sal_quotation.total_qty`、`sal_quotation_version.version_status`、`sal_quotation_version.created_by_name`、`sal_sales_order.credit_check_at`、`sal_sales_order.total_qty`、`sal_sales_order.rejection_reason`、`sal_sales_order_line.invoiced_qty`、`sal_sales_order_version.before_total_amount`、`sal_sales_order_version.after_total_amount`、`sal_sales_order_version.before_grand_total`、`sal_sales_order_version.after_grand_total`、`sal_sales_order_version.requested_at`、`sal_sales_order_version.requested_by`、`sal_sales_order_line_version.before_qty`、`sal_sales_order_line_version.after_qty`、`sal_sales_order_line_version.before_unit_price`、`sal_sales_order_line_version.after_unit_price`、`sal_sales_order_line_version.before_delivery_date`、`sal_sales_order_line_version.after_delivery_date`、`sal_sales_order_line_version.before_amount`、`sal_sales_order_line_version.after_amount`、`sal_delivery_note.total_qty`、`sal_delivery_note.picked_at`、`sal_delivery_note.confirmed_by`、`sal_delivery_note_line.delivery_note_id`、`sal_delivery_note_line.prior_shipped_qty`、`sal_pick_detail.delivery_note_id`、`sal_pick_detail.delivery_note_line_id`、`sal_pick_detail.pick_seq`、`sal_pick_detail.pick_status`

</details>

### 04-purchase（PUR）

- 统计：S1 1、S2 3、S3 0；文档内 Phase 2/3/P2 字样 59 处；画面一览中本域 29 个画面，其中无独立「项目定义」小节（标题未出现该画面 ID）的 7 个；DDL 非公共列 463 个，其中在本域画面/API 文档中从未出现（snake 或 camel）的 36 个（d 类，低优先级）。

| 严重度 | 类别 | 问题 | 画面/API 证据 | DDL 证据 | 说明 | 建议修改方 |
|---|---|---|---|---|---|---|
| S1 | a | 见 S1 #3：`prLineId`/`pr_line_id` ↔ `purchase_requisition_line_id` | `04-purchase/03-purchase-order.md:242,497`、`02-rfq-comparison.md:196` | `04-purchase/90-db-design.md:403,763` |  | 改画面/API 文档 DB 映射 |
| S2 | a | 付款申请 `plannedPaymentDate` ↔ FIN 列名 `planned_pay_date` | `04-purchase/91-api-design.md:417`、`04-purchase/06-purchase-invoice-ap.md:338,648` | `07-finance/90-db-design.md:1039` `fin_payment_request.planned_pay_date` | 跨域命名不一致 | DTO 保持 `plannedPaymentDate`，在 FIN API 文档写明映射；或 DDL 改名 `planned_payment_date`（建议改 DDL，与 DTO 一致） |
| S2 | b | 请购一覧 `departmentName`/`prTypeName`/`applicantName` 型为 VARCHAR，DB 項目写 id/码列 | `04-purchase/01-requisition.md:200-202` | `pur_purchase_requisition.department_id/pr_type/applicant_id` | 显示名为联表或码表翻译 | 画面文档注明来源 |
| S2 | a | 追踪画面 `remainQty` 无列 | `04-purchase/07-tracking-performance.md:226` | — | 应为计算值（订单量−入库量），文档未写算式 | 画面文档补算式 |

<details><summary>无项目定义小节的画面（7）</summary>

SCR-PUR-003、SCR-PUR-010、SCR-PUR-011、SCR-PUR-014、SCR-PUR-015、SCR-PUR-016、SCR-PUR-018

</details>

<details><summary>d 类：未被画面/API 引用的 DDL 列示例（前 30 / 共 36）</summary>

`pur_purchase_requisition_line.purchase_requisition_id`、`pur_rfq.purchase_requisition_id`、`pur_rfq_line.purchase_requisition_line_id`、`pur_rfq_supplier.contact_name`、`pur_rfq_supplier.contact_phone`、`pur_supplier_quotation_line.comparison_unit_price`、`pur_purchase_order_line.purchase_order_id`、`pur_purchase_order_line.purchase_requisition_line_id`、`pur_purchase_order_line.price_source_id`、`pur_purchase_order_his.purchase_order_id`、`pur_purchase_order_his.after_status`、`pur_purchase_order_his.changed_at`、`pur_purchase_order_his.changed_by`、`pur_receipt.purchase_order_id`、`pur_receipt_line.purchase_order_line_id`、`pur_invoice.ap_posted_by`、`pur_invoice_line.purchase_order_id`、`pur_invoice_line.purchase_order_line_id`、`pur_invoice_match.purchase_order_id`、`pur_invoice_match.purchase_order_line_id`、`pur_invoice_match.previously_invoiced_qty`、`pur_invoice_match.po_tax_rate`、`pur_invoice_match.invoice_tax_rate`、`pur_tolerance_rule.rule_name`、`pur_tolerance_rule.scope_level`、`pur_tolerance_rule.scope_id`、`pur_tolerance_rule.threshold_type`、`pur_tolerance_rule.threshold_value`、`pur_tolerance_rule.abs_threshold`、`pur_tolerance_rule.over_receipt_min_qty`

</details>

### 05-inventory（INV）

- 统计：S1 2、S2 2、S3 1；文档内 Phase 2/3/P2 字样 54 处；画面一览中本域 26 个画面，其中无独立「项目定义」小节（标题未出现该画面 ID）的 4 个；DDL 非公共列 361 个，其中在本域画面/API 文档中从未出现（snake 或 camel）的 30 个（d 类，低优先级）。

| 严重度 | 类别 | 问题 | 画面/API 证据 | DDL 证据 | 说明 | 建议修改方 |
|---|---|---|---|---|---|---|
| S1 | a | 见 S1 #1：状态转换 from/to | `05-inventory/04-batch-serial-status.md:214-215` | `05-inventory/90-db-design.md:454` |  |  |
| S1 | a | 见 S1 #2：`inspectionFlag` | `05-inventory/02-inbound-outbound.md:360` | `05-inventory/90-db-design.md:299` |  |  |
| S2 | b | 盘点计划 `scope_json` 的键名：画面写 snake（`scope_json.category_codes` 等），DDL 注释写 camel（`{categoryCodes,...}`） | `05-inventory/03-transfer-count.md:281-284` | `05-inventory/90-db-design.md:662` | JSON 键名不统一会导致 SQL 场景脚本取不到值 | 统一为一种（建议 DDL 注释为准用 camel，或全 snake），两边同步 |
| S2 | b | 库存流水检索 `sourceNo` VARCHAR(64) vs DDL 32 | `05-inventory/01-stock-query.md:219` | `inv_stock_txn.source_no VARCHAR(32)`（`05-inventory/90-db-design.md:310`附近） | 跨域来源单号（如外部单号）可能超过 32 | 确认来源单号最大长度后改一侧 |
| S3 | b | `locationCode`/`materialCode`/`planNo` 显示码列映射到 BIGINT id 列 | `05-inventory/01-stock-query.md:171`、`03-transfer-count.md:298,318`、`04-batch-serial-status.md:211,218` | 对应 `*_id BIGINT` | 显示用联表 | 画面文档注明；另 `materialCode` 写 VARCHAR(10)，与 MDM 物料编码长度需核对 |

<details><summary>无项目定义小节的画面（4）</summary>

SCR-INV-006、SCR-INV-007、SCR-INV-008、SCR-INV-009

</details>

<details><summary>d 类：未被画面/API 引用的 DDL 列示例（前 30 / 共 30）</summary>

`inv_stock_txn.biz_module`、`inv_stock_txn.reference_txn_no`、`inv_stock_txn.reversed_txn_id`、`inv_stock_txn.accounting_period`、`inv_stock_txn_line.cost_layer_id`、`inv_stock_txn_line.source_line_id`、`inv_transfer.from_factory_id`、`inv_transfer.to_factory_id`、`inv_transfer.approval_status`、`inv_transfer_line.returned_qty`、`inv_stocktake_plan.approved_at`、`inv_stocktake.diff_change_reason`、`inv_stocktake.approved_at`、`inv_stocktake.adjust_txn_id`、`inv_serial.outbound_txn_id`、`inv_serial.outbound_date`、`inv_reservation_line.line_status`、`inv_cost_layer.source_adjustment_line_id`、`inv_cost_layer.inbound_qty`、`inv_cost_layer.inbound_amount`、`inv_cost_layer.inbound_unit_cost`、`inv_cost_layer.layer_status`、`inv_cost_adjustment.approved_at`、`inv_cost_adjustment.reversal_of_adjustment_id`、`inv_stock_summary.generated_at`、`inv_stock_summary.generated_by`、`inv_age_snapshot.generated_at`、`inv_replenishment.ignored_reason`、`inv_replenishment.generated_at`、`inv_event_wait.last_error`

</details>

### 06-production（PRD）

- 统计：S1 0、S2 1、S3 1；文档内 Phase 2/3/P2 字样 76 处；画面一览中本域 33 个画面，其中无独立「项目定义」小节（标题未出现该画面 ID）的 11 个；DDL 非公共列 884 个，其中在本域画面/API 文档中从未出现（snake 或 camel）的 171 个（d 类，低优先级）。

| 严重度 | 类别 | 问题 | 画面/API 证据 | DDL 证据 | 说明 | 建议修改方 |
|---|---|---|---|---|---|---|
| S2 | phase | SCR-PRD-032 设备台账仍标 Phase 2 | `02-screen-list.md:212` | DDL 已有 `prd_equipment`（`06-production/90-db-design.md:517`） |  | 去掉分期标注 |
| S3 | b | 多处显示码（`work_order_no`、`supplier_code`、`defect_code`、`standard_no`、`inspection_no` 等）映射到 `*_id BIGINT` | `06-production/01-bom-routing-workcenter.md:614,625,634,639,642`、`02-work-order.md:216-217`、`03-material-issue-reporting.md:189,208,215-216,229,239,249`、`04-outsourcing.md:130,147,159,166`、`06-quality-management.md:196,286,346,349` | 对应 `prd_*.*_id BIGINT` | 显示与存储不同，非缺列；但 `03-material-issue-reporting.md:216` `operation_seq` INT 映射 `work_order_operation_id` BIGINT 需确认报工按工序号还是按工序 id 定位 | 画面文档统一写法「显示 xxx_no，存 xxx_id」 |

<details><summary>无项目定义小节的画面（11）</summary>

SCR-PRD-001、SCR-PRD-003、SCR-PRD-004、SCR-PRD-006、SCR-PRD-007、SCR-PRD-010、SCR-PRD-013、SCR-PRD-015、SCR-PRD-017、SCR-PRD-022、SCR-PRD-024

</details>

<details><summary>d 类：未被画面/API 引用的 DDL 列示例（前 30 / 共 171）</summary>

`prd_bom.material_spec`、`prd_bom.approved_at`、`prd_bom_line.component_spec`、`prd_bom_substitute.bom_line_id`、`prd_bom_substitute.substitute_name`、`prd_bom_substitute.substitute_uom_code`、`prd_bom_substitute.unit_cost_diff`、`prd_bom_substitute.substitute_reason`、`prd_bom_substitute.approval_status`、`prd_routing.total_setup_hours`、`prd_routing.total_run_hours`、`prd_routing.approved_at`、`prd_routing_operation.operation_desc`、`prd_routing_operation_alt.routing_operation_id`、`prd_routing_operation_alt.alt_equipment_id`、`prd_routing_operation_alt.alt_reason`、`prd_work_center.work_center_name`、`prd_work_center.work_center_type`、`prd_work_center.capacity_per_day`、`prd_work_center.shift_pattern`、`prd_work_center.calendar_id`、`prd_work_center.equipment_count`、`prd_work_center.standard_worker_count`、`prd_work_center.machine_rate_per_hour`、`prd_work_center.cost_center_code`、`prd_work_center_calendar.calendar_date`、`prd_work_center_calendar.overtime_hours`、`prd_work_center_calendar.calendar_reason`、`prd_equipment.equipment_type`、`prd_equipment.purchase_date`

</details>

### 07-finance（FIN）

- 统计：S1 1、S2 1、S3 0；文档内 Phase 2/3/P2 字样 184 处；画面一览中本域 61 个画面，其中无独立「项目定义」小节（标题未出现该画面 ID）的 42 个；DDL 非公共列 657 个，其中在本域画面/API 文档中从未出现（snake 或 camel）的 165 个（d 类，低优先级）。

| 严重度 | 类别 | 问题 | 画面/API 证据 | DDL 证据 | 说明 | 建议修改方 |
|---|---|---|---|---|---|---|
| S1 | c | 见 S1 #4：9 个原 P2 画面无设计、P2 DDL 只是概要 | `07-finance/07-period-reporting.md:155-160` | `07-finance/90-db-design.md:1615` 起 |  |  |
| S2 | phase | 分期标注最多的域（184 处），包括收入确认、坏账、跌价、外币、关税等业务规则 | `07-finance/00-overview.md:59,63,66,67,76,246,264-272` | — | 全量 v1 后这些规则需重写为 v1 规则 | 业务分析按域 PR 处理 |

<details><summary>无项目定义小节的画面（42）</summary>

SCR-FIN-001、SCR-FIN-003、SCR-FIN-004、SCR-FIN-007、SCR-FIN-008、SCR-FIN-009、SCR-FIN-010、SCR-FIN-011、SCR-FIN-012、SCR-FIN-013、SCR-FIN-014、SCR-FIN-015、SCR-FIN-016、SCR-FIN-017、SCR-FIN-019、SCR-FIN-021、SCR-FIN-023、SCR-FIN-024、SCR-FIN-025、SCR-FIN-029、SCR-FIN-030、SCR-FIN-031、SCR-FIN-033、SCR-FIN-035、SCR-FIN-036、SCR-FIN-037、SCR-FIN-038、SCR-FIN-040、SCR-FIN-042、SCR-FIN-044、SCR-FIN-045、SCR-FIN-046、SCR-FIN-047、SCR-FIN-048、SCR-FIN-050、SCR-FIN-051、SCR-FIN-054、SCR-FIN-056、SCR-FIN-058、SCR-FIN-059、SCR-FIN-060、SCR-FIN-061

</details>

<details><summary>d 类：未被画面/API 引用的 DDL 列示例（前 30 / 共 165）</summary>

`fin_account_aux.sort_no`、`fin_period.period_no`、`fin_aux_balance.aux_object_id`、`fin_aux_balance.aux_object_code`、`fin_aux_balance.aux_object_name`、`fin_voucher.reviewed_at`、`fin_voucher_template_line.template_id`、`fin_voucher_template_line.sort_no`、`fin_auto_voucher_log.template_id`、`fin_auto_voucher_log.payload_hash`、`fin_auto_voucher_log.processed_at`、`fin_cash_flow_item.section_type`、`fin_aging_config.config_type`、`fin_aging_config.bucket_no`、`fin_aging_config.bucket_name`、`fin_aging_config.from_days`、`fin_aging_config.to_days`、`fin_close_checklist.check_order`、`fin_close_checklist.executed_at`、`fin_close_checklist.executed_by`、`fin_statement_template.item_level`、`fin_statement_template.parent_line_no`、`fin_statement_template.side_type`、`fin_statement_template.is_total`、`fin_statement_template.total_formula`、`fin_statement_template.print_order`、`fin_statement_formula.formula_type`、`fin_statement_formula.formula_expr`、`fin_statement_formula.account_scope`、`fin_statement_formula.round_scale`

</details>

### 08-workflow（WF）

- 统计：S1 0、S2 1、S3 1；文档内 Phase 2/3/P2 字样 15 处；画面一览中本域 16 个画面，其中无独立「项目定义」小节（标题未出现该画面 ID）的 6 个；DDL 非公共列 200 个，其中在本域画面/API 文档中从未出现（snake 或 camel）的 42 个（d 类，低优先级）。

| 严重度 | 类别 | 问题 | 画面/API 证据 | DDL 证据 | 说明 | 建议修改方 |
|---|---|---|---|---|---|---|
| S2 | b | 委托设置 `businessTypes` 画面为 VARCHAR(64)[]，DDL 为逗号分隔 VARCHAR(500) | `08-workflow/03-approval-admin.md:135` | `08-workflow/90-db-design.md:475` | 逗号分隔不利于 SQL 查询/约束 | 建议 DDL 改为 `VARCHAR(64)[]` 或 JSONB，或另建关联表 |
| S3 | b | `dueStatus` SMALLINT 映射 `due_at` TIMESTAMPTZ | `08-workflow/02-approval-runtime.md:170` | `wf_task.due_at` | 派生状态 | 画面文档写派生规则 |

<details><summary>无项目定义小节的画面（6）</summary>

SCR-WF-001、SCR-WF-003、SCR-WF-005、SCR-WF-008、SCR-WF-010、SCR-WF-016

</details>

<details><summary>d 类：未被画面/API 引用的 DDL 列示例（前 30 / 共 42）</summary>

`wf_process_definition_ext.deploy_user_id`、`wf_business_type.module_code`、`wf_business_type.detail_url_template`、`wf_business_type.id_field`、`wf_business_type.sort_no`、`wf_process_mapping.effective_to`、`wf_approval_matrix.effective_to`、`wf_approval_matrix_line.allow_delegate`、`wf_business_process.urgent_flag`、`wf_task.task_def_key`、`wf_task.assignee_name`、`wf_task.create_at`、`wf_task.claim_at`、`wf_task.cc_flag`、`wf_task_operation.operator_name`、`wf_task_operation.target_user_id`、`wf_task_operation.target_task_id`、`wf_task_operation.before_status`、`wf_task_operation.after_status`、`wf_task_operation.deadline_extended`、`wf_task_operation.ip_address`、`wf_task_operation.trace_id`、`wf_cc.cc_user_id`、`wf_cc.cc_type`、`wf_cc.read_at`、`wf_delegation.approved_at`、`wf_timeout_rule.escalate_to_ref`、`wf_timeout_rule.effective_to`、`wf_timeout_record.target_user_id`、`wf_timeout_record.elapsed_hours`

</details>

### 09-integration（INT）

- 统计：S1 0、S2 2、S3 0；文档内 Phase 2/3/P2 字样 62 处；画面一览中本域 24 个画面，其中无独立「项目定义」小节（标题未出现该画面 ID）的 13 个；DDL 非公共列 340 个，其中在本域画面/API 文档中从未出现（snake 或 camel）的 103 个（d 类，低优先级）。

| 严重度 | 类别 | 问题 | 画面/API 证据 | DDL 证据 | 说明 | 建议修改方 |
|---|---|---|---|---|---|---|
| S2 | b | 通知渠道 host/port/from_address/webhook_url 为独立项目，DDL 合并在 `config_json` | `09-integration/04-openapi-file-notify.md:182-184` | `int_notification_channel.config_json JSONB` | 可接受 | 画面文档写明 JSON 键名 |
| S2 | b | `payee_account_no` VARCHAR(64) ↔ `payee_account_enc` VARCHAR(500)（加密存储） | `09-integration/02-tax-bank-interface.md:190` | `int_bank_payment.payee_account_enc` | 明文/密文映射 | 画面文档注明加解密与掩码 |

<details><summary>无项目定义小节的画面（13）</summary>

SCR-INT-001、SCR-INT-003、SCR-INT-007、SCR-INT-008、SCR-INT-010、SCR-INT-011、SCR-INT-012、SCR-INT-014、SCR-INT-015、SCR-INT-019、SCR-INT-022、SCR-INT-023、SCR-INT-024

</details>

<details><summary>d 类：未被画面/API 引用的 DDL 列示例（前 30 / 共 103）</summary>

`int_interface_config.content_type`、`int_interface_config.idempotency_header`、`int_interface_config.request_layout_id`、`int_interface_config.response_layout_id`、`int_interface_config.last_failure_at`、`int_interface_config.owner_user_id`、`int_interface_mapping.interface_id`、`int_interface_mapping.source_field`、`int_interface_mapping.target_field`、`int_interface_mapping.data_type`、`int_interface_mapping.code_set_code`、`int_interface_mapping.required_flag`、`int_interface_mapping.default_value`、`int_interface_mapping.sort_no`、`int_api_client.rate_limit_burst`、`int_api_client.contact_name`、`int_api_call_log.request_path`、`int_api_call_log.result_code`、`int_api_call_log.request_size`、`int_api_call_log.response_size`、`int_api_call_log.client_ip`、`int_external_message.payload_format`、`int_external_message.received_at`、`int_external_message.processed_at`、`int_sync_job.job_no`、`int_sync_job.job_type`、`int_sync_job.trigger_type`、`int_sync_job.skip_count`、`int_sync_job.started_at`、`int_sync_job.finished_at`

</details>

### 10-analytics（RPT）

- 统计：S1 1、S2 2、S3 2；文档内 Phase 2/3/P2 字样 33 处；画面一览中本域 20 个画面，其中无独立「项目定义」小节（标题未出现该画面 ID）的 7 个；DDL 非公共列 270 个，其中在本域画面/API 文档中从未出现（snake 或 camel）的 74 个（d 类，低优先级）。

| 严重度 | 类别 | 问题 | 画面/API 证据 | DDL 证据 | 说明 | 建议修改方 |
|---|---|---|---|---|---|---|
| S1 | c | 见 S1 #5：SCR-RPT-019/020 无设计 | `02-screen-list.md:261-262` | `10-analytics/90-db-design.md:674` |  |  |
| S2 | b | KPI `frequency` 画面 VARCHAR(8)，DDL CHAR(1) 且 CHECK D/M/Q/Y | `10-analytics/01-dashboard.md:229` | `10-analytics/90-db-design.md:106,125` | 值域一致，长度不一致 | 改画面文档为 CHAR(1) |
| S2 | c | SCR-RPT-002 驾驶舱布局设置仅在 `10-analytics/01-dashboard.md:26` 的 ID 列表里出现，无项目定义 | `02-screen-list.md:244` | `rpt_dashboard`/`rpt_dashboard_widget`（`10-analytics/90-db-design.md:248,266`） |  | 补画面项目定义 |
| S3 | b | 驾驶舱 `period_code` VARCHAR(7) vs `rpt_kpi_snapshot.period_code` VARCHAR(10)（含日粒度） | `10-analytics/01-dashboard.md:208` | `10-analytics/90-db-design.md:179` | 日粒度 KPI 无法在画面选 | 画面文档改为 10 或说明仅月/年 |
| S3 | a | `source_tables` 映射到表 `rpt_kpi_lineage`（多行） | `10-analytics/01-dashboard.md:228` | `10-analytics/90-db-design.md:205`（列为 `source_table`） | 一对多编辑 | 画面文档写明为子表编辑 |

<details><summary>无项目定义小节的画面（7）</summary>

SCR-RPT-008、SCR-RPT-010、SCR-RPT-013、SCR-RPT-014、SCR-RPT-016、SCR-RPT-017、SCR-RPT-018

</details>

<details><summary>d 类：未被画面/API 引用的 DDL 列示例（前 30 / 共 74）</summary>

`rpt_kpi_definition.description`、`rpt_kpi_definition.effective_to`、`rpt_kpi_definition.approved_by`、`rpt_kpi_definition.approved_at`、`rpt_kpi_target.target_type`、`rpt_kpi_target.approved_by`、`rpt_kpi_target.approved_at`、`rpt_kpi_snapshot.calc_at`、`rpt_kpi_snapshot.calc_version`、`rpt_kpi_lineage.seq_no`、`rpt_kpi_lineage.source_column`、`rpt_kpi_lineage.join_path`、`rpt_kpi_lineage.formula_part`、`rpt_kpi_comment.root_cause`、`rpt_kpi_comment.action_plan`、`rpt_kpi_comment.author_id`、`rpt_dashboard.dashboard_name`、`rpt_dashboard.layout_json`、`rpt_dashboard.is_default`、`rpt_dashboard_widget.dashboard_id`、`rpt_dashboard_widget.widget_code`、`rpt_dashboard_widget.widget_type`、`rpt_dashboard_widget.position_x`、`rpt_dashboard_widget.position_y`、`rpt_dashboard_widget.width`、`rpt_dashboard_widget.height`、`rpt_dashboard_widget.config_json`、`rpt_dashboard_widget.sort_no`、`rpt_analysis_favorite.favorite_name`、`rpt_analysis_favorite.analysis_type`

</details>

## 2. 画面一览 vs 设计书（c 类）

- 画面一览中有、但所有详细设计书都没有出现该 ID：SCR-FIN-055（`02-screen-list.md:71`）、SCR-FIN-057（`:73`）、SCR-RPT-019（`:261`）、SCR-RPT-020（`:262`）。（FIN-055/057 仅在 `07-finance/07-period-reporting.md:155-156` 以「054/055」「056/057」合并写一行概要。）
- 设计书中有、画面一览中没有：0 个。
- 画面一览中仍带分期字样的画面：SCR-FIN-030、054～061（`02-screen-list.md:46,70-77`）、SCR-PRD-032（`:212`）、SCR-RPT-020（`:262`）、SCR-SAL-046（`:308`），共 12 个；该一览由 `20-matrix/tools/gen_matrix.py` 生成，应改源设计书后重新生成，不要手改。
- 注意：`20-matrix/10-validation-report.md` 显示 missing/id 等检查 0 件，但它不检查「画面项目↔DDL 列」一致性，本报告的问题它都覆盖不到；建议在 gen_matrix.py 中加入本报告的比对逻辑（脚本见 `30-review/tools/screen_ddl_audit.py`）。

## 3. 分期（Phase 2/3/P2）标注分布

| 域 | 处数 |
|---|---|
| 00-common | 82 |
| 01-system | 50 |
| 02-mdm | 73 |
| 03-sales | 156 |
| 04-purchase | 59 |
| 05-inventory | 54 |
| 06-production | 76 |
| 07-finance | 184 |
| 08-workflow | 15 |
| 09-integration | 62 |
| 10-analytics | 33 |

（统计口径：`grep "Phase *[23]|Phase[23]|（P2|P2）"`，不含 30-review；与蓝色大肥鱼所说约 1000 处同量级。）