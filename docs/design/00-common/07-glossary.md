# 术语集（用語集）

| 項目 | 内容 |
|---|---|
| 文書名 | 术语集（用語集） |
| 文書番号 | DSN-CMN-007 |
| 版数 | v1.0 |
| 作成日 | 2026-10-20 |
| 作成者 | Lead（设计基盤） |
| 承認者 | 未承認（社内レビュー待ち） |
| 状態 | ドラフト（レビュー中） |
| 関連文書 | [设计方针](00-design-principles.md) / [共通项目定义](01-common-item-definitions.md) |

---

## 1. 使い方

- 設計書・画面・帳票・メッセージの用語は本表の**中文表記**を正とする。1 概念 1 用語。
- 日本語・英語は対日/対外説明用の参考表記であり、中国語正文には使わない。
- 新しい用語が必要な場合は本表に追記してから使用する（Lead 承認）。
- 「所管域」は用語の定義責任を持つ業務域。定義の詳細は各域 `00-overview.md` を参照。

## 2. 共通・システム（SYS）

| 中文 | 日本語 | English | 説明 | 所管域 |
|---|---|---|---|---|
| 企业资源计划 | 企業資源計画 | ERP (Enterprise Resource Planning) | 経営資源を統合管理する業務システム | 全体 |
| 主数据 | マスタ / マスタデータ | Master Data | 各業務で共通利用する基礎データ（物料・取引先等） | MDM |
| 单据 | 伝票 | Document | 業務取引を記録する単位（発注書・受注等） | 全体 |
| 明细 | 明細 | Line / Detail | 伝票の明細行 | 全体 |
| 状态 | ステータス | Status | 伝票・マスタの処理状態。共通体系は 10〜95 | 全体 |
| 审批 | 承認 | Approval | ワークフローによる決裁 | WF |
| 工作流 | ワークフロー | Workflow | 承認フロー・プロセス管理 | WF |
| 用户 | ユーザ | User | システム利用者 | SYS |
| 角色 | ロール | Role | 権限の集合 | SYS |
| 权限 | 権限 | Permission | 画面・操作・項目・データのアクセス権 | SYS |
| 菜单 | メニュー | Menu | 画面ナビゲーション | SYS |
| 部门 | 部門 | Department | 組織単位 | SYS |
| 岗位 | 職位 / ポジション | Position | 職務上の役割 | SYS |
| 数据字典 | データ辞書 | Data Dictionary | 区分値・コードの管理 | SYS |
| 系统参数 | システムパラメータ | System Parameter | システム全体の設定値 | SYS |
| 审计日志 | 監査ログ | Audit Log | 操作履歴（追記専用） | SYS |
| 附件 | 添付ファイル | Attachment | 伝票・マスタに添付するファイル | SYS |
| 消息通知 | 通知 | Notification | 站内・メール・短信による通知 | SYS |
| 编码规则 | 採番ルール | Numbering Rule | 伝票番号・コードの自動採番規則 | SYS |
| 导入 | インポート | Import | 外部ファイルからのデータ取込 | SYS |
| 导出 | エクスポート | Export | データのファイル出力 | SYS |
| 打印模板 | 帳票テンプレート | Print Template | 帳票レイアウトの定義 | SYS |
| 定时任务 | 定期ジョブ | Scheduled Job | 定刻実行のバッチ | SYS |
| 个人中心 | マイページ | Personal Center | 個人設定・パスワード変更 | SYS |
| 租户 | テナント | Tenant | マルチテナントの契約単位（第一版で RLS により分離） | SYS |
| 快照 | スナップショット | Snapshot | 取引時点のマスタ値を伝票に保存したもの | 全体 |
| 逻辑删除 | 論理削除 | Logical Delete | 行を物理削除せず削除フラグを立てる | 全体 |
| 乐观锁 | 楽観ロック | Optimistic Lock | version による更新競合検出 | 全体 |
| 幂等 | 冪等 | Idempotency | 同一操作の再実行結果が変わらない性質 | 全体 |
| 雪花ID | スノーフレークID | Snowflake ID | 分散環境で一意な 64bit ID | 全体 |
| 追溯 | トレーサビリティ | Traceability | データ・処理の追跡可能性 | 全体 |

## 3. 主数据（MDM）

| 中文 | 日本語 | English | 説明 | 所管域 |
|---|---|---|---|---|
| 物料 | 品目 / 部材 | Material / Item | 購入・製造・販売する品目 | MDM |
| 物料分类 | 品目分類 | Material Category | 物料の階層分類 | MDM |
| 物料编码 | 品目コード | Material Code | 物料の一意識別コード | MDM |
| 客户 | 得意先 | Customer | 販売先 | MDM |
| 供应商 | 仕入先 | Supplier | 調達先 | MDM |
| 仓库 | 倉庫 | Warehouse | 在庫保管場所 | MDM |
| 库区 | 倉庫エリア | Warehouse Zone | 倉庫内の区域 | MDM |
| 库位 | ロケーション / 棚番 | Bin Location | 棚・ロケーション単位の保管位置 | MDM |
| 计量单位 | 単位 | Unit of Measure (UoM) | 個・kg・m 等 | MDM |
| 单位换算 | 単位換算 | Unit Conversion | 購入単位と在庫単位の換算 | MDM |
| 币种 | 通貨 | Currency | 通貨コード（ISO 4217） | MDM |
| 汇率 | 為替レート | Exchange Rate | 通貨換算レート | MDM |
| 税码 | 税コード | Tax Code | 税率・税区分の組み合わせ | MDM |
| 税率 | 税率 | Tax Rate | 増値税率等 | MDM |
| 价格表 | 価格表 | Price List | 顧客・品目別の販売価格 | MDM |
| 采购价格 | 仕入価格 | Purchase Price | 仕入先・品目別の調達価格 | MDM |
| 结算方式 | 決済方法 | Settlement Method | 現金・振込・手形等 | MDM |
| 付款条件 | 支払条件 | Payment Terms | 支払期日・締め日 | MDM |
| 信用额度 | 与信限度額 | Credit Limit | 顧客ごとの与信枠 | MDM |
| 银行联行号 | 銀行コード（CNAPS） | CNAPS Code | 中国の銀行間決済コード（12 桁） | MDM |
| 客户等级 | 顧客ランク | Customer Grade | 顧客の優良度分類 | MDM |
| 供应商评估 | 仕入先評価 | Supplier Evaluation | 品質・納期・価格の評価 | MDM |
| 物料替代 | 代替品目 | Alternative Material | 同等用途の代替品目 | MDM |
| 条码 | バーコード | Barcode | 品目・ロット・ロケーションの識別 | MDM |

## 4. 销售（SAL）

| 中文 | 日本語 | English | 説明 | 所管域 |
|---|---|---|---|---|
| 询价 | 引合 | Inquiry | 顧客からの見積依頼 | SAL |
| 报价单 | 見積書 | Quotation | 顧客への提示見積 | SAL |
| 销售订单 | 受注 | Sales Order | 顧客からの注文 | SAL |
| 订单变更 | 受注変更 | Order Change | 受注内容の変更 | SAL |
| 可用量 | 引当可能量 | Available Quantity | 在庫のうち引当可能な数量 | INV |
| 库存锁定 | 引当 / 在庫引当 | Allocation / Reservation | 受注・工単に対する在庫確保 | INV |
| 信用检查 | 与信チェック | Credit Check | 与信限度超過の判定 | SAL |
| 发货通知 | 出荷指示 | Delivery Note | 出荷指示書 | SAL |
| 拣货 | ピッキング | Picking | 出荷品の棚出し | INV |
| 销售出库 | 売上出庫 | Sales Issue | 販売に伴う在庫出庫 | INV |
| 销售退货 | 売上返品 | Sales Return | 顧客からの返品 | SAL |
| 销售发票 | 売上請求書 / 増値税发票 | Sales Invoice | 売上・増値税の請求書 | SAL/FIN |
| 对账单 | 照合書 | Statement of Account | 顧客との取引照合 | SAL |
| 应收账款 | 売掛金 | Accounts Receivable (AR) | 売上代金の未回収債権 | FIN |
| 账龄 | エイジング | Aging | 債権・債務の経過期間分析 | FIN |
| 换货 | 交換 | Exchange | 返品と再出荷の組合せ | SAL |
| 销售预测 | 売上予測 | Sales Forecast | 将来需要の予測 | SAL |
| 出口销售 | 輸出販売 | Export Sales | 海外向け販売 | SAL |

## 5. 采购（PUR）

| 中文 | 日本語 | English | 説明 | 所管域 |
|---|---|---|---|---|
| 采购申请 / 请购 | 購買依頼 | Purchase Requisition | 部門からの購買要求 | PUR |
| 询价比价 | 見積依頼・比較 | RFQ / Comparison | 複数仕入先の見積比較 | PUR |
| 采购订单 | 発注書 | Purchase Order (PO) | 仕入先への発注 | PUR |
| 收货单 | 入荷検収書 | Goods Receipt | 入荷の受領記録 | PUR |
| 来料检验 | 受入検査（IQC） | Incoming Inspection | 受入時の品質検査 | PRD |
| 采购入库 | 仕入入庫 | Purchase Receipt | 受入在庫の計上 | INV |
| 采购退货 | 仕入返品 | Purchase Return | 仕入先への返品 | PUR |
| 对账 | 買掛照合 | AP Reconciliation | 仕入先との取引照合 | PUR |
| 三单匹配 | 三者照合 | 3-way Match | 発注・入荷・請求書の一致確認 | PUR/FIN |
| 应付账款 | 買掛金 | Accounts Payable (AP) | 仕入代金の未払債務 | FIN |
| 预付款 | 前払金 | Prepayment | 発注時の前払 | FIN |
| 暂估 | 暫定計上 | Accrual / Provision | 請求書未着の仕入を暫定計上 | FIN |
| 交期跟踪 | 納期フォロー | Delivery Follow-up | 発注残の納期管理 | PUR |
| 超收 | 過入荷 | Over-receipt | 発注数量を超える入荷 | PUR |
| 最小起订量 | 最小発注量 | MOQ (Minimum Order Quantity) | 発注可能な最小数量 | PUR |

## 6. 库存（INV）

| 中文 | 日本語 | English | 説明 | 所管域 |
|---|---|---|---|---|
| 库存事务 | 在庫取引 | Stock Transaction | 入出庫・移動等の在庫変動記録 | INV |
| 现存量 | 現有在庫量 | On-hand Quantity | 実在庫数量 | INV |
| 可用量 | 引当可能量 | Available Quantity | 現有 − 引当 − 検査中等 | INV |
| 锁定量 / 预留量 | 引当量 | Reserved Quantity | 受注・工単で確保した数量 | INV |
| 在途量 | 輸送中数量 | In-transit Quantity | 移動中・入荷待ちの数量 | INV |
| 待检量 | 検査待ち数量 | Inspection Quantity | 受入検査待ちの数量 | INV |
| 库存状态 | 在庫ステータス | Stock Status | 可用・検査待ち・凍結・不適合 | INV |
| 批次 | ロット / バッチ | Lot / Batch | 製造・入荷単位の管理番号 | INV |
| 序列号 | シリアル番号 | Serial Number | 個体識別番号 | INV |
| 保质期 | 有効期限 | Shelf Life | 使用期限（該当品目のみ） | INV |
| 移动加权平均法 | 移動平均法 | Moving Weighted Average | 入出庫の都度平均単価を更新する原価法 | INV |
| 库龄 | 在庫滞留期間 | Inventory Age | 入庫からの経過期間 | INV |
| 呆滞料 | 滞留在庫 | Slow-moving Inventory | 長期滞留の在庫 | INV |
| 安全库存 | 安全在庫 | Safety Stock | 欠品防止のための基準在庫 | INV |
| 再订货点 | 発注点 | Reorder Point | 補充発注を起動する在庫水準 | INV |
| 盘点 | 棚卸 | Physical Inventory | 実在庫との差異確認 | INV |
| 盘点差异 | 棚卸差異 | Inventory Variance | 帳簿在庫と実在庫の差 | INV |
| 调拨 | 在庫移動 | Transfer | 倉庫・ロケーション間の移動 | INV |
| 移库 | ロケーション移動 | Bin Transfer | 同一倉庫内の移動 | INV |
| 报废 | 廃棄 | Scrap | 使用不可在庫の除却 | INV |
| 成本层 | 原価レイヤ | Cost Layer | 移動平均のコスト記録 | INV |
| 库存周转率 | 在庫回転率 | Inventory Turnover | 売上原価 ÷ 平均在庫 | INV |
| 收发存 | 受払残高 | Receipt-Issue-Balance | 入出庫と残高の集計表 | INV |

## 7. 生产（PRD）

| 中文 | 日本語 | English | 説明 | 所管域 |
|---|---|---|---|---|
| 物料清单 | 部品表（BOM） | Bill of Materials | 製品を構成する部品・数量 | PRD |
| 多阶 BOM | 多段 BOM | Multi-level BOM | 階層構造の部品表 | PRD |
| 工艺路线 | 工順 | Routing | 製造工程の順序・工数 | PRD |
| 工序 | 工程 | Operation | 製造の各工程 | PRD |
| 工作中心 | ワークセンター | Work Center | 工程を実施する設備・職場単位 | PRD |
| 产能 | 生産能力 | Capacity | 単位期間の生産可能量 | PRD |
| 生产订单 / 工单 | 製造指図 / ワークオーダー | Work Order / Production Order | 製造指示単位 | PRD |
| 生产领料 | 材料出庫（払出） | Material Issue | 工単への材料払出 | INV |
| 退料 | 材料返却 | Material Return | 未使用材料の戻し | INV |
| 倒冲 | 後方払出（バックフラッシュ） | Backflush | 完成時に材料を自動払出 | PRD |
| 报工 | 作業実績報告 | Work Report / Confirmation | 工程完了・工数・良否の報告 | PRD |
| 生产入库 | 製品入庫 | Finished Goods Receipt | 完成品の在庫計上 | INV |
| 委外加工 | 外注加工 | Outsourcing / Subcontracting | 外部への加工委託 | PRD |
| 物料需求计划 | 資材所要量計画（MRP） | Material Requirements Planning | 需要から所要量・発注を計算 | PRD |
| 毛需求 | 総所要量 | Gross Requirement | 独立需要＋従属需要 | PRD |
| 净需求 | 正味所要量 | Net Requirement | 現有在庫・入荷予定を考慮した不足量 | PRD |
| 计划订单 | 計画オーダー | Planned Order | MRP が生成する発注・製造提案 | PRD |
| 提前期 | リードタイム | Lead Time | 発注から入荷・製造完了までの期間 | PRD |
| 批量规则 | ロットサイズ規則 | Lot-sizing Rule | 発注・製造のまとめ方 | PRD |
| 排产 | 生産計画 / スケジューリング | Scheduling | 工単の日程計画 | PRD |
| 粗能力计划 | 粗能力計画 | Rough-cut Capacity Planning | 負荷と能力の概算比較 | PRD |
| 完工入库 | 完成入庫 | Completion Receipt | 完成品の入庫 | PRD |
| 在制品 | 仕掛品 | Work in Process (WIP) | 製造途中の品 | FIN |
| 质量控制 | 品質管理 | Quality Control | 検査・不適合品管理 | PRD |
| 来料检验 | 受入検査（IQC） | Incoming Inspection | 受入品の検査 | PRD |
| 过程检验 | 工程内検査（IPQC） | In-process Inspection | 製造工程内の検査 | PRD |
| 成品检验 | 最終検査（FQC） | Final Inspection | 完成品の検査 | PRD |
| 不合格品 | 不適合品 | Nonconforming Product | 規格に適合しない品 | PRD |
| 让步接收 | 特採 | Concession / Use-as-is | 不合格品を条件付きで受け入れ | PRD |
| 返工 | 手直し | Rework | 不合格品の再加工 | PRD |
| 良品率 | 良品率 | Yield Rate | 良品数 ÷ 投入数 | PRD |

## 8. 财务（FIN）

| 中文 | 日本語 | English | 説明 | 所管域 |
|---|---|---|---|---|
| 会计科目 | 勘定科目 | Chart of Accounts | 取引を分類する科目体系 | FIN |
| 总账 | 総勘定元帳 | General Ledger (GL) | 全科目の元帳 | FIN |
| 明细账 | 補助元帳 | Subsidiary Ledger | 補助科目・補助核算別の元帳 | FIN |
| 记账凭证 | 仕訳伝票 | Journal Voucher | 借貸の仕訳 | FIN |
| 借方 / 贷方 | 借方 / 貸方 | Debit / Credit | 仕訳の左右 | FIN |
| 过账 | 記帳 / 転記 | Posting | 仕訳を元帳へ記帳 | FIN |
| 反过账 | 記帳取消 | Unposting | 記帳の取消 | FIN |
| 红字冲销 | 赤伝訂正 | Red-letter Reversal | マイナス仕訳による訂正 | FIN |
| 辅助核算 | 補助核算 | Auxiliary Accounting | 顧客・仕入先・部門等の補助管理 | FIN |
| 记账本位币 | 記帳通貨 | Functional Currency | 会計処理の基準通貨（CNY） | FIN |
| 会计期间 | 会計期間 | Accounting Period | 月次集計単位（YYYY-MM） | FIN |
| 结账 | 月次締め | Period Close | 期間の確定処理 | FIN |
| 年结 | 年次締め | Year-end Close | 年度の確定・繰越 | FIN |
| 结转 | 振替 | Carry-forward / Closing Entry | 損益・残高の振替 | FIN |
| 试算平衡 | 試算表 | Trial Balance | 貸借合計の一致確認 | FIN |
| 资产负债表 | 貸借対照表 | Balance Sheet | 財政状態の報告書 | FIN |
| 利润表 | 損益計算書 | Income Statement | 経営成績の報告書 | FIN |
| 现金流量表 | キャッシュ・フロー計算書 | Cash Flow Statement | 資金の増減報告書 | FIN |
| 应收账款 | 売掛金 | Accounts Receivable | 売上未回収債権 | FIN |
| 应付账款 | 買掛金 | Accounts Payable | 仕入未払債務 | FIN |
| 预收账款 | 前受金 | Advances from Customers | 顧客からの前受 | FIN |
| 收款 | 入金 | Receipt | 売掛金の回収 | FIN |
| 付款 | 支払 | Payment | 買掛金の支払 | FIN |
| 核销 | 消込 | Write-off / Matching | 入出金と債権債務の消込 | FIN |
| 部分核销 | 部分消込 | Partial Matching | 一部金額の消込 | FIN |
| 银行对账 | 銀行勘定照合 | Bank Reconciliation | 銀行残高と帳簿残高の照合 | FIN |
| 余额调节表 | 残高調整表 | Bank Reconciliation Statement | 未達事項の調整表 | FIN |
| 固定资产 | 固定資産 | Fixed Asset | 設備等の資産 | FIN |
| 折旧 | 減価償却 | Depreciation | 固定資産の費用配分 | FIN |
| 成本核算 | 原価計算 | Cost Accounting | 製品原価の計算 | FIN |
| 品种法 | 品種別原価計算 | Process Costing (by product) | 品種別の原価計算 | FIN |
| 分批法 | ロット別原価計算 | Job Order Costing | 製造ロット別の原価計算 | FIN |
| 制造费用 | 製造間接費 | Manufacturing Overhead | 間接的な製造経費 | FIN |
| 直接材料费 | 直接材料費 | Direct Material Cost | 製品に直接賦課できる材料費 | FIN |
| 直接人工费 | 直接労務費 | Direct Labor Cost | 直接作業の労務費 | FIN |
| 成本差异 | 原価差異 | Cost Variance | 標準と実際の差 | FIN |
| 增值税 | 増値税 | Value Added Tax (VAT) | 中国の付加価値税 | FIN |
| 进项税额 | 仕入増値税額 | Input VAT | 仕入時の控除対象税額 | FIN |
| 销项税额 | 売上増値税額 | Output VAT | 売上時の納付対象税額 | FIN |
| 企业所得税 | 法人所得税 | Corporate Income Tax | 法人税 | FIN |
| 附加税费 | 附加税 | Surcharges | 城建税・教育費附加等 | FIN |
| 数电票 | 全数字化電子インボイス | Fully Digitalized E-invoice | 中国の電子インボイス | FIN/INT |
| 增值税专用发票 | 増値税専用発票 | Special VAT Invoice | 仕入税額控除可能な発票 | FIN |

## 9. 集成・报表（INT/RPT）

| 中文 | 日本語 | English | 説明 | 所管域 |
|---|---|---|---|---|
| 接口 | インタフェース | Interface (IF) | システム間のデータ連携 | INT |
| 开放 API | オープン API | Open API | 外部提供用の API | INT |
| 银企直连 | 銀行直結 | Bank-Enterprise Direct Connection | 銀行システムとの直接接続 | INT |
| 制造执行系统 | 製造実行システム（MES） | Manufacturing Execution System | 現場の製造実行管理 | INT |
| 仓库管理系统 | 倉庫管理システム（WMS） | Warehouse Management System | 倉庫の入出庫管理 | INT |
| 产品生命周期管理 | 製品ライフサイクル管理（PLM） | Product Lifecycle Management | 設計・BOM 管理 | INT |
| 驾驶舱 | ダッシュボード | Dashboard | KPI 可視化画面 | RPT |
| 看板 | かんばん / ボード | Kanban / Board | 進捗・状況の可視化 | RPT |
| 指标 | 指標（KPI） | KPI | 経営・業務の測定指標 | RPT |
| 预警 | アラート | Alert | 異常・期限の通知 | RPT |
| 报表订阅 | レポート購読 | Report Subscription | 定期配信の設定 | RPT |
| 钻取 | ドリルダウン | Drill-down | 集計から明細への展開 | RPT |

## 10. 改訂履歴

| 版数 | 日付 | 変更内容 | 変更者 |
|---|---|---|---|
| v1.0 | 2026-10-20 | 初版：共通/システム・主数据・销售・采购・库存・生产・财务・集成报表の用語（約 130 件） | Lead |
