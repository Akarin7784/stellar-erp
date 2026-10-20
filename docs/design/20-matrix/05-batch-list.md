# バッチ一覧（批处理一览）

| 項目 | 内容 |
|---|---|
| 文書名 | バッチ一覧（批处理一览）（自动生成） |
| 文書番号 | DSN-MTX-005 |
| 版数 | v1.0 |
| 作成日 | 2026-10-20 |
| 作成者 | Lead（生成工具 gen_matrix.py） |
| 状態 | ドラフト（自动生成・最終レビュー前） |
| 備考 | 全 114 件。バッチID/名称/起動方式/域/提取元 |

> 本文件由 `20-matrix/tools/gen_matrix.py` 从各域设计书中自动提取生成。修改设计书后重新运行即可更新。

| バッチ ID | バッチ名 | 起動方式/時間 | 域 | 提取元 |
|---|---|---|---|---|
| BAT-FIN-001 | 会计期间自动开启 | 日次 | FIN | 07-finance/00-overview.md |
| BAT-FIN-002 | 期末暂估入账 | 月次（手动/月结前） | FIN | 07-finance/00-overview.md |
| BAT-FIN-003 | 暂估冲回 | 月次/发票到达 | FIN | 07-finance/00-overview.md |
| BAT-FIN-004 | 自动凭证事件消费 | 分次（10 秒） | FIN | 07-finance/00-overview.md |
| BAT-FIN-005 | 自动凭证失败重试 | 分次（5 分钟） | FIN | 07-finance/00-overview.md |
| BAT-FIN-006 | 应付账龄计算 | 日次 | FIN | 07-finance/00-overview.md |
| BAT-FIN-007 | 应收账龄计算 | 日次 | FIN | 07-finance/00-overview.md |
| BAT-FIN-008 | 银行对账单自动匹配 | 手动/日次 | FIN | 07-finance/00-overview.md |
| BAT-FIN-009 | 月结检查 | 手动（月结向导） | FIN | 07-finance/00-overview.md |
| BAT-FIN-010 | 制造费用分配 | 月次 | FIN | 07-finance/00-overview.md |
| BAT-FIN-011 | 成本计算 | 月次 | FIN | 07-finance/00-overview.md |
| BAT-FIN-012 | 损益结转 | 手动（月结向导） | FIN | 07-finance/00-overview.md |
| BAT-FIN-013 | 年度结转 | 手动（年结） | FIN | 07-finance/00-overview.md |
| BAT-FIN-014 | 财务报表快照生成 | 月次（月结后） | FIN | 07-finance/00-overview.md |
| BAT-FIN-015 | 增值税申报辅助表生成 | 月次 | FIN | 07-finance/00-overview.md |
| BAT-FIN-016 | 附加税/所得税计提 | 月次 | FIN | 07-finance/00-overview.md |
| BAT-FIN-017 | 折旧计提（P2） | 月次 | FIN | 07-finance/00-overview.md |
| BAT-FIN-018 | 坏账准备计提（P2） | 月次 | FIN | 07-finance/00-overview.md |
| BAT-FIN-019 | 试算平衡校验 | 日次 | FIN | 07-finance/00-overview.md |
| BAT-FIN-020 | 资金日报预生成 | 日次 | FIN | 07-finance/00-overview.md |
| BAT-INT-001 | 接口失敗自動再送 | 自動（1 分間隔） | INT | 09-integration/00-overview.md |
| BAT-INT-002 | 数电票交付状態同期 | 日次/イベント | INT | 09-integration/00-overview.md |
| BAT-INT-003 | 銀企残高・回单取得 | 日次 | INT | 09-integration/00-overview.md |
| BAT-INT-004 | 進項発票査験 | 日次 | INT | 09-integration/00-overview.md |
| BAT-INT-005 | MES 未回伝検出 | 自動（10 分間隔） | INT | 09-integration/00-overview.md |
| BAT-INT-006 | PLM 差分取込 | 日次/手動 | INT | 09-integration/00-overview.md |
| BAT-INT-007 | 接口日次対账 | 日次 | INT | 09-integration/00-overview.md |
| BAT-INT-008 | 呼出日志清理 | 日次 | INT | 09-integration/00-overview.md |
| BAT-INT-009 | 凭证・証明書有効期限警告 | 日次 | INT | 09-integration/00-overview.md |
| BAT-INT-010 | 通知送信再送 | 自動（1 分間隔） | INT | 09-integration/00-overview.md |
| BAT-INV-001 | 库存月结 | 月次/手動 | INV | 05-inventory/00-overview.md |
| BAT-INV-002 | 库存日次对账 | 日次 | INV | 05-inventory/00-overview.md |
| BAT-INV-003 | 库龄快照计算 | 日次/月次 | INV | 05-inventory/00-overview.md |
| BAT-INV-004 | 安全库存・补货建议生成 | 日次 | INV | 05-inventory/00-overview.md |
| BAT-INV-005 | 批次效期预警 | 日次 | INV | 05-inventory/00-overview.md |
| BAT-INV-006 | 预留过期自动释放 | 日次/時次 | INV | 05-inventory/00-overview.md |
| BAT-INV-007 | 事件补偿・差异检测 | 日次 | INV | 05-inventory/00-overview.md |
| BAT-INV-008 | 库存周转率统计 | 月次 | INV | 05-inventory/00-overview.md |
| BAT-INV-009 | 历史数据归档 | 月次（Phase 2） | INV | 05-inventory/00-overview.md |
| BAT-MDM-001 | 汇率导入与生效 | 日次（取込）+ イベント | MDM | 02-mdm/00-overview.md |
| BAT-MDM-002 | 价格生效/失效处理 | 日次 | MDM | 02-mdm/00-overview.md |
| BAT-MDM-003 | 信用额度日切快照 | 日次 | MDM | 02-mdm/00-overview.md |
| BAT-MDM-004 | 供应商评估月次计算 | 月次 | MDM | 02-mdm/00-overview.md |
| BAT-MDM-005 | 主数据质量日检 | 日次 | MDM | 02-mdm/00-overview.md |
| BAT-MDM-006 | 主数据质量月报 | 月次 | MDM | 02-mdm/00-overview.md |
| BAT-MDM-007 | 资质・证照到期预警 | 日次 | MDM | 02-mdm/00-overview.md |
| BAT-MDM-008 | 变更审批超时提醒 | 日次 | MDM | 02-mdm/00-overview.md |
| BAT-MDM-009 | 主数据分发导出（Phase2） | 日次 | MDM | 02-mdm/00-overview.md |
| BAT-MDM-010 | 编码空番・使用停止检查 | 月次 | MDM | 02-mdm/00-overview.md |
| BAT-PRD-001 | MRP 自動実行（日次） | 日次/手動 | PRD | 06-production/00-overview.md |
| BAT-PRD-002 | 低层码再計算 | 日次/手動 | PRD | 06-production/00-overview.md |
| BAT-PRD-003 | 安全在庫・発注点チェック | 日次 | PRD | 06-production/00-overview.md |
| BAT-PRD-004 | 納期遅延・滞留アラート | 日次 | PRD | 06-production/00-overview.md |
| BAT-PRD-005 | 工单自動結案 | 日次 | PRD | 06-production/00-overview.md |
| BAT-PRD-006 | 在制品・工单成本结转 | 月次 | PRD | 06-production/00-overview.md |
| BAT-PRD-007 | 工时汇总（日次/月次） | 日次/月次 | PRD | 06-production/00-overview.md |
| BAT-PRD-008 | 产能负荷快照 | 日次 | PRD | 06-production/00-overview.md |
| BAT-PRD-009 | 委外未回收提醒 | 日次 | PRD | 06-production/00-overview.md |
| BAT-PRD-010 | 检验超期提醒 | 日次 | PRD | 06-production/00-overview.md |
| BAT-PRD-011 | MRP 需求・計画データ保持期限処理 | 月次 | PRD | 06-production/00-overview.md |
| BAT-PUR-001 | 交期跟踪・催货提醒 | 日次 | PUR | 04-purchase/00-overview.md |
| BAT-PUR-002 | 超期未入荷 PO 抽出・关闭候補 | 日次 | PUR | 04-purchase/00-overview.md |
| BAT-PUR-003 | 入荷済未請求（暂估）照合 | 日次 + 月结前 | PUR | 04-purchase/00-overview.md |
| BAT-PUR-004 | 三单匹配差异滞留監視 | 日次 | PUR | 04-purchase/00-overview.md |
| BAT-PUR-005 | 请购未转单提醒 | 日次 | PUR | 04-purchase/00-overview.md |
| BAT-PUR-006 | 供应商绩效月次计算 | 月次（毎月 1 日） | PUR | 04-purchase/00-overview.md |
| BAT-PUR-007 | 采购价格异常检查 | 日次 | PUR | 04-purchase/00-overview.md |
| BAT-PUR-008 | 询价报价締切処理 | 毎時 | PUR | 04-purchase/00-overview.md |
| BAT-PUR-009 | 采购报表日次集計 | 日次 | PUR | 04-purchase/00-overview.md |
| BAT-PUR-010 | 长期未照合发票提醒 | 日次 | PUR | 04-purchase/00-overview.md |
| BAT-PUR-011 | 発注未送信・承認滞留チェック | 日次 | PUR | 04-purchase/00-overview.md |
| BAT-RPT-001 | 销售明细抽出 | 日次 | RPT | 10-analytics/00-overview.md |
| BAT-RPT-002 | 采购明细抽出 | 日次 | RPT | 10-analytics/00-overview.md |
| BAT-RPT-003 | 库存快照抽出 | 日次 | RPT | 10-analytics/00-overview.md |
| BAT-RPT-004 | 生产明细抽出 | 日次 | RPT | 10-analytics/00-overview.md |
| BAT-RPT-005 | 财务明细抽出 | 日次 | RPT | 10-analytics/00-overview.md |
| BAT-RPT-006 | 日次 KPI 計算 | 日次 | RPT | 10-analytics/00-overview.md |
| BAT-RPT-007 | 月次 KPI 確定 | 月次 | RPT | 10-analytics/00-overview.md |
| BAT-RPT-008 | 预警規則評価 | 日次/時次 | RPT | 10-analytics/00-overview.md |
| BAT-RPT-009 | 报表订阅配信 | 日次/週次/月次 | RPT | 10-analytics/00-overview.md |
| BAT-RPT-010 | KPI 整合性校验 | 日次 | RPT | 10-analytics/00-overview.md |
| BAT-RPT-011 | 分析数据再計算 | 手動 | RPT | 10-analytics/00-overview.md |
| BAT-RPT-012 | 抽出・スナップショット清理 | 月次 | RPT | 10-analytics/00-overview.md |
| BAT-SAL-001 | 报价单有效期到期处理 | 日次 | SAL | 03-sales/00-overview.md |
| BAT-SAL-002 | 受注引当不足再引当 | 日次 | SAL | 03-sales/00-overview.md |
| BAT-SAL-003 | 交期迟延检出与通知 | 日次 | SAL | 03-sales/00-overview.md |
| BAT-SAL-004 | 与信台帳照合 | 日次 | SAL | 03-sales/00-overview.md |
| BAT-SAL-005 | 销售订单自动关闭 | 日次 | SAL | 03-sales/00-overview.md |
| BAT-SAL-006 | 客户对账单生成与送付 | 月次 | SAL | 03-sales/00-overview.md |
| BAT-SAL-007 | 账龄・回款预测スナップショット | 日次 | SAL | 03-sales/00-overview.md |
| BAT-SAL-008 | 出荷済・未計上照合 | 日次/月結前 | SAL | 03-sales/00-overview.md |
| BAT-SAL-009 | 发票与 AR 紐付け照合 | 日次 | SAL | 03-sales/00-overview.md |
| BAT-SAL-010 | 退货期限超过提醒 | 日次 | SAL | 03-sales/00-overview.md |
| BAT-SAL-011 | 销售数据抽出（RPT 連携） | 日次 | SAL | 03-sales/00-overview.md |
| BAT-SAL-012 | 数电票状态同步（Phase2） | 日次/イベント | SAL | 03-sales/00-overview.md |
| BAT-SAL-013 | 销售预测与实际差异分析 | 月次 | SAL | 03-sales/00-overview.md |
| BAT-SYS-001 | Outbox 事件配信 | 自動（10 秒間隔） | SYS | 01-system/00-overview.md |
| BAT-SYS-002 | セッション・在线用户整合 | 自動（5 分間隔） | SYS | 01-system/00-overview.md |
| BAT-SYS-003 | パスワード有効期限提醒 | 日次 | SYS | 01-system/00-overview.md |
| BAT-SYS-004 | アカウントロック自動解除 | 自動（1 分間隔） | SYS | 01-system/00-overview.md |
| BAT-SYS-005 | 通知送信リトライ | 自動（1 分間隔） | SYS | 01-system/00-overview.md |
| BAT-SYS-006 | 監査日志アーカイブ | 日次 | SYS | 01-system/00-overview.md |
| BAT-SYS-007 | ジョブ結果・一時ファイル清理 | 日次 | SYS | 01-system/00-overview.md |
| BAT-SYS-008 | 添付孤児ファイル検査 | 週次 | SYS | 01-system/00-overview.md |
| BAT-SYS-009 | 定时任务監視・補償 | 自動（1 分間隔） | SYS | 01-system/00-overview.md |
| BAT-SYS-010 | システム整合性検査 | 日次 | SYS | 01-system/00-overview.md |
| BAT-SYS-011 | キャッシュ再構築 | 手動 | SYS | 01-system/00-overview.md |
| BAT-SYS-012 | 初期データ投入（初回） | 手動 | SYS | 01-system/00-overview.md |
| BAT-WF-001 | 超時タスク検出・リマインダ | 自動（5 分間隔） | WF | 08-workflow/00-overview.md |
| BAT-WF-002 | エスカレーション・自動承認 | 自動（5 分間隔） | WF | 08-workflow/00-overview.md |
| BAT-WF-003 | 代理期限切れ処理 | 日次 | WF | 08-workflow/00-overview.md |
| BAT-WF-004 | 流程インスタンス整合検査 | 日次 | WF | 08-workflow/00-overview.md |
| BAT-WF-005 | 承認効率集計 | 日次/月次 | WF | 08-workflow/00-overview.md |
| BAT-WF-006 | 完了プロセスアーカイブ | 月次 | WF | 08-workflow/00-overview.md |

## 改訂履歴

| 版数 | 日付 | 変更内容 | 変更者 |
|---|---|---|---|
| v1.0 | 2026-10-20 | 自动生成 | gen_matrix.py |
