# テーブル一覧（表一览）

| 項目 | 内容 |
|---|---|
| 文書名 | テーブル一覧（表一览）（自动生成） |
| 文書番号 | DSN-MTX-003 |
| 版数 | v1.0 |
| 作成日 | 2026-10-20 |
| 作成者 | Lead（生成工具 gen_matrix.py） |
| 状態 | ドラフト（自动生成・最終レビュー前） |
| 備考 | 全 329 件。物理名/論理名/域/提取元 |

> 本文件由 `20-matrix/tools/gen_matrix.py` 从各域设计书中自动提取生成。修改设计书后重新运行即可更新。

| 物理名 | 論理名 | 域 | 提取元 |
|---|---|---|---|
| fin_account | 会计科目 | FIN | 07-finance/90-db-design.md |
| fin_account_aux | 科目辅助核算设置 | FIN | 07-finance/90-db-design.md |
| fin_account_balance | 科目余额（期間） | FIN | 07-finance/90-db-design.md |
| fin_aging_config | 账龄区间配置 | FIN | 07-finance/90-db-design.md |
| fin_asset |  | FIN | 07-finance/90-db-design.md |
| fin_asset_depreciation |  | FIN | 07-finance/90-db-design.md |
| fin_auto_voucher_log | 自动凭证生成日志 | FIN | 07-finance/90-db-design.md |
| fin_aux_balance | 辅助核算余额 | FIN | 07-finance/90-db-design.md |
| fin_bank_account | 银行账户（自有） | FIN | 07-finance/90-db-design.md |
| fin_bank_journal | 银行日记账 | FIN | 07-finance/90-db-design.md |
| fin_bank_recon_item | 银行对账未达账项 | FIN | 07-finance/90-db-design.md |
| fin_bank_reconciliation | 银行余额调节表 | FIN | 07-finance/90-db-design.md |
| fin_bank_statement | 银行对账单（批次） | FIN | 07-finance/90-db-design.md |
| fin_bank_statement_line | 银行对账单明细 | FIN | 07-finance/90-db-design.md |
| fin_budget |  | FIN | 07-finance/90-db-design.md |
| fin_budget_line |  | FIN | 07-finance/90-db-design.md |
| fin_cash_flow_item | 现金流量项目 | FIN | 07-finance/90-db-design.md |
| fin_cash_journal | 现金日记账 | FIN | 07-finance/90-db-design.md |
| fin_cash_plan |  | FIN | 07-finance/90-db-design.md |
| fin_cash_plan_line |  | FIN | 07-finance/90-db-design.md |
| fin_close_checklist | 月结检查清单 | FIN | 07-finance/90-db-design.md |
| fin_cost_allocation | 制造费用分配 | FIN | 07-finance/90-db-design.md |
| fin_cost_collection | 成本归集 | FIN | 07-finance/90-db-design.md |
| fin_cost_variance | 成本差异 | FIN | 07-finance/90-db-design.md |
| fin_exchange_reval |  | FIN | 07-finance/90-db-design.md |
| fin_expense_claim |  | FIN | 07-finance/90-db-design.md |
| fin_expense_claim_line |  | FIN | 07-finance/90-db-design.md |
| fin_invoice | 发票（进项/销项） | FIN | 07-finance/90-db-design.md |
| fin_invoice_line | 发票明细 | FIN | 07-finance/90-db-design.md |
| fin_invoice_match | 三单匹配记录 | FIN | 07-finance/90-db-design.md |
| fin_payable | 应付单 | FIN | 07-finance/90-db-design.md |
| fin_payment | 付款单 | FIN | 07-finance/90-db-design.md |
| fin_payment_request | 付款申请（头） | FIN | 07-finance/90-db-design.md |
| fin_payment_request_line | 付款申请明细 | FIN | 07-finance/90-db-design.md |
| fin_period | 会计期间 | FIN | 07-finance/90-db-design.md |
| fin_product_cost | 完工产品成本 | FIN | 07-finance/90-db-design.md |
| fin_receipt | 收款单 | FIN | 07-finance/90-db-design.md |
| fin_receivable | 应收单 | FIN | 07-finance/90-db-design.md |
| fin_receivable_line | 应收单明细 | FIN | 07-finance/90-db-design.md |
| fin_standard_cost | 标准成本（版管理） | FIN | 07-finance/90-db-design.md |
| fin_statement_formula | 报表取数公式 | FIN | 07-finance/90-db-design.md |
| fin_statement_snapshot | 财务报表快照 | FIN | 07-finance/90-db-design.md |
| fin_statement_template | 报表项目模板 | FIN | 07-finance/90-db-design.md |
| fin_tax_accrual | 税金计提 | FIN | 07-finance/90-db-design.md |
| fin_vat_return | 增值税申报辅助（头） | FIN | 07-finance/90-db-design.md |
| fin_vat_return_line | 增值税申报辅助（行） | FIN | 07-finance/90-db-design.md |
| fin_voucher | 记账凭证（头） | FIN | 07-finance/90-db-design.md |
| fin_voucher_line | 记账凭证（行） | FIN | 07-finance/90-db-design.md |
| fin_voucher_template | 凭证模板（头） | FIN | 07-finance/90-db-design.md |
| fin_voucher_template_line | 凭证模板（行） | FIN | 07-finance/90-db-design.md |
| fin_wip_balance | 在制品余额 | FIN | 07-finance/90-db-design.md |
| fin_write_off | 核销单（头） | FIN | 07-finance/90-db-design.md |
| fin_write_off_line | 核销明细 | FIN | 07-finance/90-db-design.md |
| int_api_call_log | API 呼出日志 | INT | 09-integration/90-db-design.md |
| int_api_client | 開放 API クライアント | INT | 09-integration/90-db-design.md |
| int_bank_account | 銀企口座 | INT | 09-integration/90-db-design.md |
| int_bank_payment | 銀企付款指令 | INT | 09-integration/90-db-design.md |
| int_bank_statement_file | 対账单ファイル | INT | 09-integration/90-db-design.md |
| int_external_message | 外部原文メッセージ | INT | 09-integration/90-db-design.md |
| int_file_layout | 外部ファイルレイアウト | INT | 09-integration/90-db-design.md |
| int_file_transfer | ファイル取込ジョブ | INT | 09-integration/90-db-design.md |
| int_file_transfer_error | 取込エラー行 | INT | 09-integration/90-db-design.md |
| int_input_invoice | 進項発票査験 | INT | 09-integration/90-db-design.md |
| int_interface_config | 接口配置 | INT | 09-integration/90-db-design.md |
| int_interface_mapping | 字段映射 | INT | 09-integration/90-db-design.md |
| int_notification_channel | 通知チャネル | INT | 09-integration/90-db-design.md |
| int_pda_device | PDA 端末 | INT | 09-integration/90-db-design.md |
| int_pda_offline_batch | PDA 補伝批次 | INT | 09-integration/90-db-design.md |
| int_retry_log | 再送履歴 | INT | 09-integration/90-db-design.md |
| int_sync_job | 同期ジョブ | INT | 09-integration/90-db-design.md |
| int_sync_reconcile | 同期対账結果 | INT | 09-integration/90-db-design.md |
| int_sync_task | 同期タスク | INT | 09-integration/90-db-design.md |
| int_tax_invoice | 数电票 | INT | 09-integration/90-db-design.md |
| int_tax_invoice_line | 数电票明细 | INT | 09-integration/90-db-design.md |
| inv_age_snapshot | 库龄快照 | INV | 05-inventory/90-db-design.md |
| inv_batch | 批次主档 | INV | 05-inventory/90-db-design.md |
| inv_batch_genealogy | 批次系谱 | INV | 05-inventory/90-db-design.md |
| inv_cost_adjustment | 成本调整单（头） | INV | 05-inventory/90-db-design.md |
| inv_cost_adjustment_line | 成本调整单明细 | INV | 05-inventory/90-db-design.md |
| inv_cost_layer | 成本层 | INV | 05-inventory/90-db-design.md |
| inv_event_wait | 品質イベント保留 | INV | 05-inventory/90-db-design.md |
| inv_period | 库存期间 | INV | 05-inventory/90-db-design.md |
| inv_replenishment | 补货建议 | INV | 05-inventory/90-db-design.md |
| inv_reservation | 库存预留（头） | INV | 05-inventory/90-db-design.md |
| inv_reservation_line | 库存预留明细 | INV | 05-inventory/90-db-design.md |
| inv_scan_log | 扫码记录 | INV | 05-inventory/90-db-design.md |
| inv_serial | 序列号主档 | INV | 05-inventory/90-db-design.md |
| inv_serial_txn | 序列号事务履历 | INV | 05-inventory/90-db-design.md |
| inv_stock_balance | 库存余额 | INV | 05-inventory/90-db-design.md |
| inv_stock_summary | 收发存汇总 | INV | 05-inventory/90-db-design.md |
| inv_stock_txn | 库存事务（头） | INV | 05-inventory/90-db-design.md |
| inv_stock_txn_key | 在庫事務一意キー台帳 | INV | 05-inventory/90-db-design.md |
| inv_stock_txn_line | 库存事务明细 | INV | 05-inventory/90-db-design.md |
| inv_stocktake | 盘点单 | INV | 05-inventory/90-db-design.md |
| inv_stocktake_line | 盘点单明细 | INV | 05-inventory/90-db-design.md |
| inv_stocktake_plan | 盘点计划 | INV | 05-inventory/90-db-design.md |
| inv_transfer | 调拨单 | INV | 05-inventory/90-db-design.md |
| inv_transfer_line | 调拨单明细 | INV | 05-inventory/90-db-design.md |
| mdm_asset_category | 固定資産分類マスタ | MDM | 02-mdm/00-overview.md |
| mdm_bank | 银行 | MDM | 02-mdm/90-db-design.md |
| mdm_barcode_rule | 条码规则 | MDM | 02-mdm/90-db-design.md |
| mdm_change_request | 主数据变更申请 | MDM | 02-mdm/90-db-design.md |
| mdm_change_request_line | 变更申请明细 | MDM | 02-mdm/90-db-design.md |
| mdm_code_rule | 编码规则 | MDM | 02-mdm/90-db-design.md |
| mdm_contract | 框架合同マスタ（フレーム契約） | MDM | 02-mdm/00-overview.md |
| mdm_credit_check_rule | 信用检查规则 | MDM | 02-mdm/90-db-design.md |
| mdm_credit_limit | 客户信用额度 | MDM | 02-mdm/90-db-design.md |
| mdm_credit_limit_his | 信用额度变更历史 | MDM | 02-mdm/90-db-design.md |
| mdm_currency | 货币 | MDM | 02-mdm/90-db-design.md |
| mdm_customer | 客户 | MDM | 02-mdm/90-db-design.md |
| mdm_customer_address | 客户收货地址 | MDM | 02-mdm/90-db-design.md |
| mdm_customer_contact | 客户联系人 | MDM | 02-mdm/90-db-design.md |
| mdm_customer_his | 客户变更历史 | MDM | 02-mdm/90-db-design.md |
| mdm_data_quality_issue | 数据质量问题 | MDM | 02-mdm/90-db-design.md |
| mdm_data_quality_rule | 数据质量规则 | MDM | 02-mdm/90-db-design.md |
| mdm_data_scope_policy | 数据权限策略 | MDM | 02-mdm/90-db-design.md |
| mdm_exchange_rate | 汇率 | MDM | 02-mdm/90-db-design.md |
| mdm_ext_field | 扩展字段定义 | MDM | 02-mdm/90-db-design.md |
| mdm_factory | 工厂 | MDM | 02-mdm/90-db-design.md |
| mdm_material | 物料主数据 | MDM | 02-mdm/90-db-design.md |
| mdm_material_barcode | 物料条码 | MDM | 02-mdm/90-db-design.md |
| mdm_material_category | 物料分类 | MDM | 02-mdm/90-db-design.md |
| mdm_material_factory | 物料工厂视图 | MDM | 02-mdm/90-db-design.md |
| mdm_material_his | 物料变更历史 | MDM | 02-mdm/90-db-design.md |
| mdm_material_substitute | 物料替代关系 | MDM | 02-mdm/90-db-design.md |
| mdm_material_warehouse | 物料倉庫別パラメータ | MDM | 02-mdm/00-overview.md |
| mdm_partner_bank_account | 取引先银行账户 | MDM | 02-mdm/90-db-design.md |
| mdm_partner_bank_account_his | 银行账户变更历史 | MDM | 02-mdm/90-db-design.md |
| mdm_payment_term | 付款条件 | MDM | 02-mdm/90-db-design.md |
| mdm_payment_term_line | 付款条件分期 | MDM | 02-mdm/90-db-design.md |
| mdm_price_discount | 折扣规则 | MDM | 02-mdm/90-db-design.md |
| mdm_price_list | 价格表 | MDM | 02-mdm/90-db-design.md |
| mdm_price_list_line | 价格表明细 | MDM | 02-mdm/90-db-design.md |
| mdm_project | 項目マスタ（プロジェクト） | MDM | 02-mdm/00-overview.md |
| mdm_purchase_price | 采购价格 | MDM | 02-mdm/90-db-design.md |
| mdm_settlement_method | 结算方式 | MDM | 02-mdm/90-db-design.md |
| mdm_supplier | 供应商 | MDM | 02-mdm/90-db-design.md |
| mdm_supplier_address | 供应商地址 | MDM | 02-mdm/90-db-design.md |
| mdm_supplier_admission | 供应商准入 | MDM | 02-mdm/90-db-design.md |
| mdm_supplier_contact | 供应商联系人 | MDM | 02-mdm/90-db-design.md |
| mdm_supplier_eval_item | 供应商评估明细 | MDM | 02-mdm/90-db-design.md |
| mdm_supplier_evaluation | 供应商评估 | MDM | 02-mdm/90-db-design.md |
| mdm_supplier_his | 供应商变更历史 | MDM | 02-mdm/90-db-design.md |
| mdm_supplier_material | 供应商供货范围 | MDM | 02-mdm/90-db-design.md |
| mdm_supplier_qualification | 供应商资质 | MDM | 02-mdm/90-db-design.md |
| mdm_supplier_quotation | 供应商报价 | MDM | 02-mdm/90-db-design.md |
| mdm_supplier_quotation_line | 供应商报价明细 | MDM | 02-mdm/90-db-design.md |
| mdm_tax_classification | 税收分类编码 | MDM | 02-mdm/90-db-design.md |
| mdm_tax_code | 税码 | MDM | 02-mdm/90-db-design.md |
| mdm_tax_rate | 税率历史 | MDM | 02-mdm/90-db-design.md |
| mdm_uom | 计量单位 | MDM | 02-mdm/90-db-design.md |
| mdm_uom_conversion | 单位换算 | MDM | 02-mdm/90-db-design.md |
| mdm_warehouse | 仓库 | MDM | 02-mdm/90-db-design.md |
| mdm_warehouse_bin | 库位 | MDM | 02-mdm/90-db-design.md |
| mdm_warehouse_zone | 库区 | MDM | 02-mdm/90-db-design.md |
| prd_bom | BOM 头 | PRD | 06-production/90-db-design.md |
| prd_bom_line | BOM 明细 | PRD | 06-production/90-db-design.md |
| prd_bom_substitute | BOM 替代料 | PRD | 06-production/90-db-design.md |
| prd_capacity_load | 产能负荷快照 | PRD | 06-production/90-db-design.md |
| prd_completion_receipt | 完工入库要求（INV FGI の要求データ） | PRD | 06-production/90-db-design.md |
| prd_completion_receipt_line | 完工入库明细 | PRD | 06-production/90-db-design.md |
| prd_defect_code | 缺陷代码 | PRD | 06-production/90-db-design.md |
| prd_demand_forecast | 需求预测 | PRD | 06-production/90-db-design.md |
| prd_equipment | 设备台账 | PRD | 06-production/90-db-design.md |
| prd_equipment_maintenance | 设备点检维修 | PRD | 06-production/90-db-design.md |
| prd_inspection | 检验单头 | PRD | 06-production/90-db-design.md |
| prd_inspection_line | 检验结果明细 | PRD | 06-production/90-db-design.md |
| prd_inspection_standard | 检验标准头 | PRD | 06-production/90-db-design.md |
| prd_inspection_standard_item | 检验标准项目 | PRD | 06-production/90-db-design.md |
| prd_material_issue | 领料/退料要求（INV 伝票の要求データ） | PRD | 06-production/90-db-design.md |
| prd_material_issue_line | 领退料明细 | PRD | 06-production/90-db-design.md |
| prd_material_planning | 物料计划参数 | PRD | 06-production/90-db-design.md |
| prd_mps | 主生产计划头 | PRD | 06-production/90-db-design.md |
| prd_mps_line | 主生产计划明细 | PRD | 06-production/90-db-design.md |
| prd_mrp_action | MRP 动作消息 | PRD | 06-production/90-db-design.md |
| prd_mrp_demand | MRP 需求 | PRD | 06-production/90-db-design.md |
| prd_mrp_plan_order | MRP 计划订单 | PRD | 06-production/90-db-design.md |
| prd_mrp_run | MRP 运行 | PRD | 06-production/90-db-design.md |
| prd_ncr | 不合格品报告 | PRD | 06-production/90-db-design.md |
| prd_ncr_action | NCR 处置措施 | PRD | 06-production/90-db-design.md |
| prd_outsourcing_issue | 委外发料要求（INV OSI の要求データ） | PRD | 06-production/90-db-design.md |
| prd_outsourcing_issue_line | 委外发料明细 | PRD | 06-production/90-db-design.md |
| prd_outsourcing_order | 委外订单头 | PRD | 06-production/90-db-design.md |
| prd_outsourcing_order_line | 委外订单明细 | PRD | 06-production/90-db-design.md |
| prd_outsourcing_receipt | 委外收货要求（INV OSR の要求データ） | PRD | 06-production/90-db-design.md |
| prd_outsourcing_receipt_line | 委外收货明细 | PRD | 06-production/90-db-design.md |
| prd_outsourcing_settlement | 委外结算单头 | PRD | 06-production/90-db-design.md |
| prd_outsourcing_settlement_line | 委外结算明细 | PRD | 06-production/90-db-design.md |
| prd_overproduction_approval |  | PRD | 06-production/90-db-design.md |
| prd_routing | 工艺路线头 | PRD | 06-production/90-db-design.md |
| prd_routing_operation | 工艺工序 | PRD | 06-production/90-db-design.md |
| prd_routing_operation_alt | 替代工序 | PRD | 06-production/90-db-design.md |
| prd_wo_lot | 工单批次追溯 | PRD | 06-production/90-db-design.md |
| prd_work_center | 工作中心 | PRD | 06-production/90-db-design.md |
| prd_work_center_calendar | 工作日历 | PRD | 06-production/90-db-design.md |
| prd_work_order | 工单 | PRD | 06-production/90-db-design.md |
| prd_work_order_change | 工单变更履历 | PRD | 06-production/90-db-design.md |
| prd_work_order_material | 工单用料 | PRD | 06-production/90-db-design.md |
| prd_work_order_operation | 工单工序 | PRD | 06-production/90-db-design.md |
| prd_work_order_relation | 工单拆分/合并关系 | PRD | 06-production/90-db-design.md |
| prd_work_report | 报工单 | PRD | 06-production/90-db-design.md |
| prd_work_report_defect | 报工不良明细 | PRD | 06-production/90-db-design.md |
| prd_work_report_labor | 报工工数明细 | PRD | 06-production/90-db-design.md |
| pur_delivery_followup | 催货记录 | PUR | 04-purchase/90-db-design.md |
| pur_invoice | 采购发票登记 | PUR | 04-purchase/90-db-design.md |
| pur_invoice_line | 采购发票明细 | PUR | 04-purchase/90-db-design.md |
| pur_invoice_match | 三单匹配结果 | PUR | 04-purchase/90-db-design.md |
| pur_purchase_order | 采购订单 | PUR | 04-purchase/90-db-design.md |
| pur_purchase_order_his | 采购订单变更履历 | PUR | 04-purchase/90-db-design.md |
| pur_purchase_order_line | 采购订单明细 | PUR | 04-purchase/90-db-design.md |
| pur_purchase_requisition | 请购单 | PUR | 04-purchase/90-db-design.md |
| pur_purchase_requisition_line | 请购单明细 | PUR | 04-purchase/90-db-design.md |
| pur_receipt | 收货单 | PUR | 04-purchase/90-db-design.md |
| pur_receipt_line | 收货单明细 | PUR | 04-purchase/90-db-design.md |
| pur_return | 采购退货单 | PUR | 04-purchase/90-db-design.md |
| pur_return_line | 采购退货单明细 | PUR | 04-purchase/90-db-design.md |
| pur_rfq | 询价单 | PUR | 04-purchase/90-db-design.md |
| pur_rfq_line | 询价单明细 | PUR | 04-purchase/90-db-design.md |
| pur_rfq_supplier | 询价供应商 | PUR | 04-purchase/90-db-design.md |
| pur_statement | 采购对账单 | PUR | 04-purchase/90-db-design.md |
| pur_statement_line | 采购对账单明细 | PUR | 04-purchase/90-db-design.md |
| pur_supplier_performance | 供应商绩效快照 | PUR | 04-purchase/90-db-design.md |
| pur_supplier_quotation | 供应商报价 | PUR | 04-purchase/90-db-design.md |
| pur_supplier_quotation_line | 供应商报价明细 | PUR | 04-purchase/90-db-design.md |
| pur_tolerance_rule | 容差规则 | PUR | 04-purchase/90-db-design.md |
| rpt_analysis_favorite | 分析お気に入り | RPT | 10-analytics/90-db-design.md |
| rpt_dashboard | 驾驶舱 | RPT | 10-analytics/90-db-design.md |
| rpt_dashboard_widget | 驾驶舱组件 | RPT | 10-analytics/90-db-design.md |
| rpt_data_quality_check | 数据质量检查 | RPT | 10-analytics/90-db-design.md |
| rpt_etl_error | 抽取エラー | RPT | 10-analytics/90-db-design.md |
| rpt_etl_job | 抽取ジョブ | RPT | 10-analytics/90-db-design.md |
| rpt_finance_detail | 财务分析明细 | RPT | 10-analytics/90-db-design.md |
| rpt_inventory_snapshot | 库存分析快照 | RPT | 10-analytics/90-db-design.md |
| rpt_kpi_comment | KPI 评论 | RPT | 10-analytics/90-db-design.md |
| rpt_kpi_definition | KPI 定义 | RPT | 10-analytics/90-db-design.md |
| rpt_kpi_lineage | KPI 血缘 | RPT | 10-analytics/90-db-design.md |
| rpt_kpi_snapshot | KPI 快照 | RPT | 10-analytics/90-db-design.md |
| rpt_kpi_target | KPI 目标 | RPT | 10-analytics/90-db-design.md |
| rpt_production_detail | 生产分析明细 | RPT | 10-analytics/90-db-design.md |
| rpt_purchase_detail | 采购分析明细 | RPT | 10-analytics/90-db-design.md |
| rpt_query_log | 分析查询日志 | RPT | 10-analytics/90-db-design.md |
| rpt_sales_detail | 销售分析明细 | RPT | 10-analytics/90-db-design.md |
| rpt_subscription | 报表订阅 | RPT | 10-analytics/90-db-design.md |
| rpt_subscription_log | 订阅配信履歴 | RPT | 10-analytics/90-db-design.md |
| rpt_warning_event | 预警事件 | RPT | 10-analytics/90-db-design.md |
| rpt_warning_rule | 预警规则 | RPT | 10-analytics/90-db-design.md |
| rpt_warning_subscription | 预警订阅 | RPT | 10-analytics/90-db-design.md |
| sal_credit_check_log | 与信检查日志 | SAL | 03-sales/90-db-design.md |
| sal_credit_ledger_snapshot | 与信台帳投影（FIN 台帳の読取） | SAL | 03-sales/90-db-design.md |
| sal_delivery_note | 发货通知 | SAL | 03-sales/90-db-design.md |
| sal_delivery_note_line | 发货通知明细 | SAL | 03-sales/90-db-design.md |
| sal_delivery_serial | 发货序列号 | SAL | 03-sales/90-db-design.md |
| sal_inquiry | 询价单 | SAL | 03-sales/90-db-design.md |
| sal_inquiry_line | 询价明细 | SAL | 03-sales/90-db-design.md |
| sal_invoice | 销售发票 | SAL | 03-sales/90-db-design.md |
| sal_invoice_application | 开票申请 | SAL | 03-sales/90-db-design.md |
| sal_invoice_application_line | 开票申请明细 | SAL | 03-sales/90-db-design.md |
| sal_invoice_line | 发票明细 | SAL | 03-sales/90-db-design.md |
| sal_invoice_relation | 发票关联 | SAL | 03-sales/90-db-design.md |
| sal_pick_detail | 拣货明细 | SAL | 03-sales/90-db-design.md |
| sal_quotation | 报价单 | SAL | 03-sales/90-db-design.md |
| sal_quotation_line | 报价明细 | SAL | 03-sales/90-db-design.md |
| sal_quotation_version | 报价单版本 | SAL | 03-sales/90-db-design.md |
| sal_receivable_snapshot | 应收投影 | SAL | 03-sales/90-db-design.md |
| sal_return_inspection | 退货检验 | SAL | 03-sales/90-db-design.md |
| sal_sales_forecast | 销售预测 | SAL | 03-sales/90-db-design.md |
| sal_sales_forecast_line | 销售预测明细 | SAL | 03-sales/90-db-design.md |
| sal_sales_order | 销售订单 | SAL | 03-sales/90-db-design.md |
| sal_sales_order_line | 销售订单明细 | SAL | 03-sales/90-db-design.md |
| sal_sales_order_line_version | 销售订单明细版本 | SAL | 03-sales/90-db-design.md |
| sal_sales_order_version | 销售订单版本 | SAL | 03-sales/90-db-design.md |
| sal_sales_return | 销售退货单 | SAL | 03-sales/90-db-design.md |
| sal_sales_return_line | 销售退货明细 | SAL | 03-sales/90-db-design.md |
| sal_special_price | 特价申请 | SAL | 03-sales/90-db-design.md |
| sal_statement | 客户对账单 | SAL | 03-sales/90-db-design.md |
| sal_statement_line | 对账单明细 | SAL | 03-sales/90-db-design.md |
| sys_attachment | 附件 | SYS | 01-system/90-db-design.md |
| sys_attachment_biz | 附件业务关联 | SYS | 01-system/90-db-design.md |
| sys_audit_log | 操作审计日志 | SYS | 01-system/90-db-design.md |
| sys_company | 公司 | SYS | 01-system/90-db-design.md |
| sys_data_maintenance_log | 数据维护历史 | SYS | 01-system/90-db-design.md |
| sys_department | 部门 | SYS | 01-system/90-db-design.md |
| sys_dict_item | 字典项目 | SYS | 01-system/90-db-design.md |
| sys_dict_type | 字典类型 | SYS | 01-system/90-db-design.md |
| sys_event_consume_log | 事件消费日志 | SYS | 01-system/90-db-design.md |
| sys_factory_setting | 工厂组织设置 | SYS | 01-system/90-db-design.md |
| sys_idempotency | 幂等键 | SYS | 01-system/90-db-design.md |
| sys_import_export_error | 任务错误行 | SYS | 01-system/90-db-design.md |
| sys_import_export_job | 导入导出任务 | SYS | 01-system/90-db-design.md |
| sys_import_template | 导入模板 | SYS | 01-system/90-db-design.md |
| sys_login_log | 登录日志 | SYS | 01-system/90-db-design.md |
| sys_menu | 菜单/权限 | SYS | 01-system/90-db-design.md |
| sys_notification | 站内通知 | SYS | 01-system/90-db-design.md |
| sys_notification_receiver | 通知受信者 | SYS | 01-system/90-db-design.md |
| sys_notification_send_log | 通知发送日志 | SYS | 01-system/90-db-design.md |
| sys_notification_template | 通知模板 | SYS | 01-system/90-db-design.md |
| sys_number_rule | 编号规则 | SYS | 01-system/90-db-design.md |
| sys_outbox_event | Outbox 事件 | SYS | 01-system/90-db-design.md |
| sys_param | 系统参数 | SYS | 01-system/90-db-design.md |
| sys_position | 岗位 | SYS | 01-system/90-db-design.md |
| sys_print_log | 打印日志 | SYS | 01-system/90-db-design.md |
| sys_print_template | 打印模板 | SYS | 01-system/90-db-design.md |
| sys_role | 角色 | SYS | 01-system/90-db-design.md |
| sys_role_data_scope | 角色数据范围 | SYS | 01-system/90-db-design.md |
| sys_role_permission | 角色权限 | SYS | 01-system/90-db-design.md |
| sys_scheduled_job | 定时任务定义 | SYS | 01-system/90-db-design.md |
| sys_scheduled_job_log | 定时任务日志 | SYS | 01-system/90-db-design.md |
| sys_sequence | 採番連番 | SYS | 01-system/90-db-design.md |
| sys_tenant | 租户 | SYS | 01-system/90-db-design.md |
| sys_user | 用户 | SYS | 01-system/90-db-design.md |
| sys_user_data_scope | 用户数据范围 | SYS | 01-system/90-db-design.md |
| sys_user_password_history | 密码历史 | SYS | 01-system/90-db-design.md |
| sys_user_preference | 用户画面设置 | SYS | 01-system/90-db-design.md |
| sys_user_role | 用户角色 | SYS | 01-system/90-db-design.md |
| wf_approval_matrix | 承認マトリクス | WF | 08-workflow/90-db-design.md |
| wf_approval_matrix_line | 承認マトリクス明細 | WF | 08-workflow/90-db-design.md |
| wf_business_process | 業務流程関連 | WF | 08-workflow/90-db-design.md |
| wf_business_type | 业务类型 | WF | 08-workflow/90-db-design.md |
| wf_cc | 抄送 | WF | 08-workflow/90-db-design.md |
| wf_delegation | 代理委托 | WF | 08-workflow/90-db-design.md |
| wf_form_field_permission | 表单字段权限 | WF | 08-workflow/90-db-design.md |
| wf_process_definition_ext | 流程定义扩展 | WF | 08-workflow/90-db-design.md |
| wf_process_mapping | 流程映射 | WF | 08-workflow/90-db-design.md |
| wf_process_stat | 流程统计 | WF | 08-workflow/90-db-design.md |
| wf_task | 承認タスク拡張 | WF | 08-workflow/90-db-design.md |
| wf_task_operation | 承認操作履歴 | WF | 08-workflow/90-db-design.md |
| wf_timeout_record | 超时记录 | WF | 08-workflow/90-db-design.md |
| wf_timeout_rule | 超时规则 | WF | 08-workflow/90-db-design.md |
| wf_variable | 流程変数 | WF | 08-workflow/90-db-design.md |

## 改訂履歴

| 版数 | 日付 | 変更内容 | 変更者 |
|---|---|---|---|
| v1.0 | 2026-10-20 | 自动生成 | gen_matrix.py |
