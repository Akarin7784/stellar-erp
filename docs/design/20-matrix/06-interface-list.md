# インタフェース一覧（接口一览）

| 項目 | 内容 |
|---|---|
| 文書名 | インタフェース一覧（接口一览）（自动生成） |
| 文書番号 | DSN-MTX-006 |
| 版数 | v1.0 |
| 作成日 | 2026-10-20 |
| 作成者 | Lead（生成工具 gen_matrix.py） |
| 状態 | ドラフト（自动生成・最終レビュー前） |
| 備考 | 全 65 件。IFID/名称/相手先/方向/方式/頻度/域/提取元 |

> 本文件由 `20-matrix/tools/gen_matrix.py` 从各域设计书中自动提取生成。修改设计书后重新运行即可更新。

| IF ID | 名称 | 相手先 | 方向 | 方式 | 頻度 | 域 | 提取元 |
|---|---|---|---|---|---|---|---|
| IF-FIN-001 | 银行对账单导入 | 开户银行/银企直连（INT） | 受信 | ファイル（CSV/Excel） | 日次 | FIN | 07-finance/00-overview.md |
| IF-FIN-002 | 银企直连付款指令 | 开户银行（INT） | 送信 | REST | リアルタイム | FIN | 07-finance/00-overview.md |
| IF-FIN-003 | 银企直连回单/余额 | 开户银行（INT） | 受信 | REST | 日次/リアルタイム | FIN | 07-finance/00-overview.md |
| IF-FIN-004 | 数电票开票（销项） | 电子发票服务平台（INT） | 送信 | REST | リアルタイム | FIN | 07-finance/00-overview.md |
| IF-FIN-005 | 进项发票查验/勾选 | 增值税发票综合服务平台（INT） | 双方向 | REST/ファイル | 日次 | FIN | 07-finance/00-overview.md |
| IF-FIN-006 | 增值税申报数据导出 | 电子税务局（INT） | 送信 | ファイル（XML/Excel） | 月次 | FIN | 07-finance/00-overview.md |
| IF-INT-001 | 银企直连（残高・明細・付款指令・回单） | 开户银行（企业网银/银企直连网关） | 双方向 | REST/JSON（银行提供 SDK・署名） | リアルタイム＋日次 | INT | 09-integration/00-overview.md |
| IF-INT-002 | 数电票开具・交付 | 电子发票服务平台（税局开放接口，経由：税務サービス事業者） | 送信/受信 | REST/JSON | リアルタイム | INT | 09-integration/00-overview.md |
| IF-INT-003 | MES 工单・报工 | MES | 双方向 | REST/JSON | リアルタイム/イベント | INT | 09-integration/00-overview.md |
| IF-INT-004 | PLM 物料/BOM/工艺 | PLM | 受信 | REST/JSON またはファイル（XML/CSV） | 日次＋手動 | INT | 09-integration/00-overview.md |
| IF-INT-005 | WMS（Phase 2） | 外部 WMS | 双方向 | REST/JSON | リアルタイム | INT | 09-integration/00-overview.md |
| IF-INT-006 | 銀行対账单/回单取込 | 銀行（CSV/Excel/MT940） | 受信 | ファイル（SFTP/手動） | 日次 | INT | 09-integration/00-overview.md |
| IF-INT-007 | 電子税務局 申報データ（Phase 2） | 電子税務局 | 送信 | ファイル（XML/Excel） | 月次 | INT | 09-integration/00-overview.md |
| IF-INT-008 | 進項発票 査験・用途確認 | 增值税发票综合服务平台 | 双方向 | REST/ファイル | 日次 | INT | 09-integration/00-overview.md |
| IF-INT-009 | 開放 API | 取引先・代理店・3PL | 受信 | REST/JSON（/api/open/v1） | リアルタイム | INT | 09-integration/00-overview.md |
| IF-INT-010 | 条码/PDA | PDA・ハンディ端末 | 受信 | REST/JSON＋オフライン補伝 | リアルタイム | INT | 09-integration/00-overview.md |
| IF-INT-011 | 消息送信 | SMTP・短信GW・企业微信・钉钉 | 送信 | SMTP / REST(Webhook) | リアルタイム | INT | 09-integration/00-overview.md |
| IF-INT-012 | 数据同步监控 | INT 内部（外部相手なし） | — | 内部処理 | 常時 | INT | 09-integration/00-overview.md |
| IF-INT-013 | 物流・送り状（Phase 2） | 物流会社 | 送信/受信 | REST | 出荷時 | INT | 09-integration/00-overview.md |
| IF-INT-014 | 顧客 EDI 注文（Phase 2） | 顧客 EDI/メール | 受信 | ファイル（CSV/XML） | 随時 | INT | 09-integration/00-overview.md |
| IF-INT-015 | 供給者ポータル/PO 送信（Phase 2） | 供給者ポータル/メール | 送信 | REST/ファイル | イベント | INT | 09-integration/00-overview.md |
| IF-INT-016 | 設備 IoT データ（Phase 2） | IoT ゲートウェイ | 受信 | MQTT/REST | 分次 | INT | 09-integration/00-overview.md |
| IF-MDM-001 | 汇率导入 | 中国外汇交易中心 / 银行公开牌价（CSV） | 受信 | ファイル（CSV） | 日次 | MDM | 02-mdm/00-overview.md |
| IF-MDM-002 | 银行联行号（CNAPS）取込 | 人民银行支付系统公开行号表 | 受信 | ファイル（CSV） | 月次/随時 | MDM | 02-mdm/00-overview.md |
| IF-MDM-003 | 标准代码取込（货币/单位） | ISO 4217 / UN/ECE Rec20 公开代码表 | 受信 | ファイル（CSV） | 随時 | MDM | 02-mdm/00-overview.md |
| IF-MDM-004 | PLM 物料/设计 BOM 同步（Phase2） | PLM（如 Siemens Teamcenter） | 双方向 | REST | 随時 | MDM | 02-mdm/00-overview.md |
| IF-MDM-005 | 供应商工商信息核验（Phase2） | 国家企业信用信息公示系统 / 第三方（如企查查） | 受信 | REST | 随時 | MDM | 02-mdm/00-overview.md |
| IF-MDM-006 | 税码/税收分类编码取込（Phase2） | 国家税务总局公开代码表 | 受信 | ファイル（CSV） | 随時 | MDM | 02-mdm/00-overview.md |
| IF-MDM-007 | 庫位マスタ配信（PDA/WMS） | WMS/PDA（Phase 2） | 送信 | REST / ファイル | 日次/随時 | MDM | 02-mdm/00-overview.md |
| IF-PRD-001 | MES 工单下发・报工回传 | 制造执行系统（MES） | 双方向 | REST/JSON | リアルタイム | PRD | 06-production/00-overview.md |
| IF-PRD-002 | PLM BOM/工艺同步 | 产品生命周期管理（PLM） | 受信 | REST/JSON/ファイル | 日次 | PRD | 06-production/00-overview.md |
| IF-PRD-003 | PDA/条码 报工・领料扫描 | 手持终端/PDA | 双方向 | REST/JSON | リアルタイム | PRD | 06-production/00-overview.md |
| IF-PRD-004 | 设备数据采集（Phase 2） | 设备 IoT 网关 | 受信 | MQTT/REST | 定期（分） | PRD | 06-production/00-overview.md |
| IF-PUR-001 | 采购订单送信 | INT（供应商门户/邮件/EDI） | 送信 | REST/ファイル | イベント | PUR | 04-purchase/00-overview.md |
| IF-PUR-002 | 电子发票采集 | INT（金税/数电票平台） | 受信 | REST/ファイル | 日次/イベント | PUR | 04-purchase/00-overview.md |
| IF-PUR-003 | MRP 计划订单受信 | PRD | 受信 | REST（同期参照） | 日次/イベント | PUR | 04-purchase/00-overview.md |
| IF-PUR-004 | IQC 检验起票 | PRD | 送信 | イベント | イベント | PUR | 04-purchase/00-overview.md |
| IF-PUR-005 | IQC 判定受信 | PRD | 受信 | イベント | イベント | PUR | 04-purchase/00-overview.md |
| IF-PUR-006 | 在庫入出庫 | INV | 送信/受信 | イベント | イベント | PUR | 04-purchase/00-overview.md |
| IF-PUR-007 | 应付・暂估・付款 | FIN | 送信/受信 | イベント | イベント | PUR | 04-purchase/00-overview.md |
| IF-PUR-008 | 供应商・采购价格受信 | MDM | 受信 | イベント/同期参照 | イベント | PUR | 04-purchase/00-overview.md |
| IF-PUR-009 | PDA・条码收货 | INT | 受信 | REST | リアルタイム | PUR | 04-purchase/00-overview.md |
| IF-PUR-010 | 供应商门户报价 | INT | 受信 | REST/ファイル | 日次 | PUR | 04-purchase/00-overview.md |
| IF-PUR-011 | 收货取消逆処理 | INV/PRD/FIN | 送信 | イベント | イベント | PUR | 04-purchase/00-overview.md |
| IF-RPT-001 | 業務域データ抽出 | SAL/PUR/INV/PRD/FIN（内部） | 受信 | DB 参照（SELECT）/内部 API | 日次 | RPT | 10-analytics/00-overview.md |
| IF-RPT-002 | レポート配信 | INT（メール/WeCom） | 送信 | SMTP/REST | 日次/週次/月次 | RPT | 10-analytics/00-overview.md |
| IF-RPT-003 | 外部 BI ツール接続（P2） | BI ツール（Tableau/Power BI 等） | 送信 | JDBC/ODBC（読取専用ビュー） | 随時 | RPT | 10-analytics/00-overview.md |
| IF-RPT-004 | 大屏表示（P2） | 工場大屏端末 | 送信 | REST/WebSocket | 常時 | RPT | 10-analytics/00-overview.md |
| IF-RPT-005 | 監査ログ参照 | SYS | 受信 | 内部 API | 随時 | RPT | 10-analytics/00-overview.md |
| IF-SAL-001 | 数电票/金税发票开具接口 | 国家税务总局电子发票服务平台（経由：INT 域） | 送信/受信 | REST（Phase2。INT 域が実装） | リアルタイム | SAL | 03-sales/00-overview.md |
| IF-SAL-002 | 发票交付状态同步 | 电子发票服务平台（経由：INT） | 受信 | REST/ファイル | 日次 | SAL | 03-sales/00-overview.md |
| IF-SAL-003 | 客户 EDI 订单接入 | 顧客（EDI/邮件） | 受信 | CSV/XML（INT 域） | 随時 | SAL | 03-sales/00-overview.md |
| IF-SAL-004 | 物流/快递面单接口 | 物流会社（経由：INT） | 送信/受信 | REST | 出荷確定時 | SAL | 03-sales/00-overview.md |
| IF-SAL-005 | 出口报关数据接口 | 报关行/单一窗口（経由：INT） | 送信 | ファイル/EDI | 出荷時 | SAL | 03-sales/00-overview.md |
| IF-SAL-006 | 客户对账单电子送付 | メール/客户ポータル | 送信 | SMTP/ファイル | 月次 | SAL | 03-sales/00-overview.md |
| IF-SYS-001 | メール送信 | SMTP サーバ（企业邮箱） | 送信 | SMTP/TLS | リアルタイム/再送 | SYS | 01-system/00-overview.md |
| IF-SYS-002 | 短信送信 | 短信网关（Phase 2） | 送信 | REST | リアルタイム | SYS | 01-system/00-overview.md |
| IF-SYS-003 | 企业微信/钉钉通知 | 企业微信/钉钉開放平台（Phase 2） | 送信 | REST（Webhook） | リアルタイム | SYS | 01-system/00-overview.md |
| IF-SYS-004 | 统一身份认证 | LDAP/AD（Phase 2） | 双方向 | LDAP | ログイン時 | SYS | 01-system/00-overview.md |
| IF-SYS-005 | 对象存储 | MinIO/S3（Phase 2） | 双方向 | S3 API | リアルタイム | SYS | 01-system/00-overview.md |
| IF-SYS-006 | ウイルススキャン | ClamAV（Phase 2） | 送信 | clamd/ICAP | リアルタイム | SYS | 01-system/00-overview.md |
| IF-SYS-007 | PDF 変換 | LibreOffice/Puppeteer ローカルプロセス | 送信 | ローカル実行 | リアルタイム | SYS | 01-system/00-overview.md |
| IF-WF-001 | BPMN モデルインポート | 設計ツール（bpmn-js / Camunda Modeler エクスポート） | 受信 | ファイル（.bpmn20.xml） | 手動 | WF | 08-workflow/00-overview.md |
| IF-WF-002 | 承認結果通知 | 各業務域 | 送信 | イベント（E31/E32） | リアルタイム | WF | 08-workflow/00-overview.md |
| IF-WF-003 | 通知送信 | SYS 通知基盤（→メール IF-SYS-001） | 送信 | 同期（公開 Service） | リアルタイム | WF | 08-workflow/00-overview.md |

## 改訂履歴

| 版数 | 日付 | 変更内容 | 変更者 |
|---|---|---|---|
| v1.0 | 2026-10-20 | 自动生成 | gen_matrix.py |
