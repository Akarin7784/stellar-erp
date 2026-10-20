# 系统管理 样例数据说明（系统管理 サンプルデータ説明）

| 項目 | 内容 |
|---|---|
| 文書名 | 系统管理 样例数据说明（系统管理 サンプルデータ説明） |
| 文書番号 | DSN-SYS-094 |
| 版数 | v1.1 |
| 作成日 | 2026-10-20 |
| 作成者 | system-workflow（域設計担当） |
| 承認者 | 未承認（レビュー待ち） |
| 状態 | ドラフト（レビュー中） |
| 関連文書 | [業務域概要](00-overview.md) / [DB 設計](90-db-design.md) / [バッチ設計](92-report-batch-design.md) / [示例企業](../90-data/demo-company.md) / [承認マトリクス](../90-data/approval-matrix.md) / [コード一覧](../00-common/06-code-list.md) |

---

## 1. 本域で使用する実データと出典

| 分類 | データ | 内容・出典 | 使用箇所 |
|---|---|---|---|
| 【実データ】 | 統一社会信用代码 | GB 32100-2015《法人和其他组织统一社会信用代码编码规则》の 18 桁形式（例示値は架空） | `sys_company.unified_social_credit_code` |
| 【実データ】 | 行政区划代码 | GB/T 2260 — 江蘇省 `320000`、常州市 `320400`、無錫市 `320200`（[06-code-list.md](../00-common/06-code-list.md) §5 を正とする） | `sys_company`/`sys_factory` |
| 【実データ】 | 通貨コード | ISO 4217 — `CNY`（[06-code-list.md](../00-common/06-code-list.md) §3） | `sys_company.base_currency_code` |
| 【実データ】 | 税コード・税率 | VAT13/VAT9/VAT6/VAT0/VAT3/VAT1（[06-code-list.md](../00-common/06-code-list.md) §7 を正とする） | 辞書 `TAX_CODE`、税関連パラメータ |
| 【実データ】 | 単位コード | UN/ECE Rec20 + 中国国内慣用（KGM/PCE/MTR/MTK/MTQ/HUR 等、[06-code-list.md](../00-common/06-code-list.md) §6 を正とする） | 辞書 `UNIT_TYPE` |
| 【実データ】 | 会計档案保存期間 | 《会计档案管理办法》（财政部 国家档案局令第 79 号）— 会計凭证 30 年等 | 監査ログ・添付の保存期間 |
| 【実データ】 | 個人情報保護 | 《中华人民共和国个人信息保护法》— 個人情報の最小収集・マスキング | 携帯・メールのマスキング |
| 参照先（**正**） | 示例企業の組織・拠点・部門・職位 | [demo-company.md](../90-data/demo-company.md) 2 章 — 部門 `D010`〜`D080`、職位 `P001`〜`P022` | 会社・工場・部門・岗位 |
| 参照先（**正**） | 承認マトリクス | [approval-matrix.md](../90-data/approval-matrix.md) — ロールコード `ROLE-*` | SYS のロールコード・WF 連携 |
| 参照先 | コード全件 | [06-code-list.md](../00-common/06-code-list.md) / [90-data/code-lists/](../90-data/code-lists/) | 辞書・パラメータの初期値 |

> **整合方針**：組織・部門・ロール・職位は [demo-company.md](../90-data/demo-company.md) と [06-code-list.md](../00-common/06-code-list.md) §10 を正とする。本 94 はその要約であり、差分が出た場合は 90-data を優先する。

## 2. 初期データ（BAT-SYS-012 で投入）

### 2.1 会社（sys_company）

| 項目 | 値 | 分類 |
|---|---|---|
| id | `1` | 【示例値】 |
| company_code | `HDJM` | 【示例値】 |
| company_name | 华东精密电机股份有限公司 | 【示例値】実在企業ではない |
| company_name_en | Huadong Precision Motor Co., Ltd. | 【示例値】 |
| unified_social_credit_code | `91320400MA1XXXXXXX`（18 桁の形式のみ実データ、値は架空） | 【示例値】 |
| tax_payer_type | 1（一般纳税人） | 【実データ】区分定義 |
| province_code / city_code | `320000` / `320400` | 【実データ】GB/T 2260 |
| address | 江苏省常州市武进区XX路XX号 | 【示例値】 |
| fiscal_year_start_month | 1 | 【実データ】中国会計年度 |
| base_currency_code | CNY | 【実データ】ISO 4217 |

### 2.2 工厂（MDM 主データ `mdm_factory` ＋ SYS 组织設定 `sys_factory_setting`）

**主データは MDM 域が管理する**（`mdm_factory`、[02-mdm/90-db-design.md](../02-mdm/90-db-design.md) 4.3.1）。SYS は `sys_factory_setting` に「システム利用可否（`is_enabled`）・既定工厂（`is_default`）・工場責任者（`manager_user_id`）・表示順（`sort_no`）」のみを保持する。下表の `factory_code`/`factory_name`/`city_code` は MDM 主データの初期値（【示例値】）であり、SYS は複製しない。

| factory_id（MDM） | factory_code | factory_name | city_code | SYS 設定：is_enabled / is_default | 分類 |
|---|---|---|---|---|---|
| 1 | `CZ01` | 常州总装厂 | `320400` | true / true | 【示例値】 |
| 2 | `WX01` | 无锡零部件厂 | `320200` | true / false | 【示例値】 |

> 倉庫 `WH01`〜`WH03` は MDM 域（`mdm_warehouse`）が管理する。SYS の `sys_factory_setting` は有効化・既定割当のみを持ち、工厂コード・名称・住所等の主データは MDM を参照する（[demo-company.md](../90-data/demo-company.md) §3）。

### 2.3 部门（sys_department、初期 8 件 + ツリールート）

部門コードは [06-code-list.md](../00-common/06-code-list.md) §10 と [demo-company.md](../90-data/demo-company.md) 2.2 を正とする。部門ツリーのルートは会社（`parent_id=0`）とし、以下 8 部門を直下に置く（「公司本部」等の追加ノードは設けない）。

| department_code | department_name | parent | factory | 主要職位（例） | 分類 |
|---|---|---|---|---|---|
| `D010` | 销售部 | 0（公司） | — | P002 销售总监 / P003 销售经理 | 【示例値】 |
| `D020` | 采购部 | 0 | — | P004 采购经理 / P005 采购员 | 【示例値】 |
| `D030` | 生产部 | 0 | CZ01 | P006 生产经理 / P007 计划员 / P008・P009 车间主管 | 【示例値】 |
| `D040` | 技术部 | 0 | — | P010 技术经理 / P011 BOM・工艺工程师 | 【示例値】 |
| `D050` | 财务部 | 0 | — | P012 财务总监 / P013 财务经理 / P014 会计 / P015 出纳 | 【示例値】 |
| `D060` | 质量部 | 0 | CZ01 | P016 质量经理 / P017 质检员 | 【示例値】 |
| `D070` | 综合管理部 | 0 | — | P018 人事・行政 | 【示例値】 |
| `D080` | 信息部 | 0 | — | P019 系统管理员 | 【示例値】 |

> 部門コード規則 `D`+3 桁は [共通業務規則](../00-common/08-common-business-rules.md) 2.2。岗位コード `P001`〜`P022` は [demo-company.md](../90-data/demo-company.md) 2.1 / [06-code-list.md](../00-common/06-code-list.md) §10 に従う。

### 2.4 ロール（sys_role、初期 18 件）

ロールコードは [approval-matrix.md](../90-data/approval-matrix.md) 3 章の `ROLE-*` を正とし、[共通業務規則](../00-common/08-common-business-rules.md) 9.1 のロール名と対応させる。`role_type=1`（内置）は削除・権限変更不可。

| role_code | role_name | role_type | data_scope_type | requires_approval | 対応する 08 §9.1 ロール | 分類 |
|---|---|---|---|---|---|---|
| `ROLE-GM` | 总经理 | 1 内置 | 1 全社 | true | 总经理 | 【示例値】 |
| `ROLE-VP` | 分管副总 | 1 内置 | 1 全社 | true | —（08 には未記載、承認マトリクスで使用） | 【示例値】 |
| `ROLE-FIN-DIR` | 财务总监 | 1 内置 | 1 全社 | true | 财务总监 | 【示例値】 |
| `ROLE-FIN-MGR` | 财务经理 | 2 业务 | 3 本部门 | false | 财务经理 | 【示例値】 |
| `ROLE-FIN-CHK` | 财务复核 | 3 只读 | 3 本部门 | false | 会计（复核） | 【示例値】 |
| `ROLE-SAL-DIR` | 销售总监 | 2 业务 | 3 本部门 | false | —（08 には未記載） | 【示例値】 |
| `ROLE-SAL-MGR` | 销售经理 | 2 业务 | 3 本部门 | false | 销售经理 | 【示例値】 |
| `ROLE-PUR-MGR` | 采购经理 | 2 业务 | 3 本部门 | false | 采购经理 | 【示例値】 |
| `ROLE-DEPT-MGR` | 部门经理 | 2 业务 | 2 本部门及子部门 | false | 部门经理 | 【示例値】 |
| `ROLE-WH-SUP` | 仓库主管 | 2 业务 | 3 本部门 | false | 仓管员（上位） | 【示例値】 |
| `ROLE-SYS-ADMIN` | 系统管理员 | 1 内置 | 1 全社 | true | 系统管理员 | 【示例値】 |
| `ROLE-HR-ADMIN` | 人事管理员 | 2 业务 | 1 全社 | false | —（SYS 追加） | 【示例値】 |
| `ROLE-AUDITOR` | 内审员 | 3 只读 | 1 全社 | false | —（SYS 追加） | 【示例値】 |
| `ROLE-OPS` | 运维担当 | 2 业务 | 1 全社 | false | —（SYS 追加） | 【示例値】 |
| `ROLE-SALES` | 销售员 | 2 业务 | 4 本人 | false | 销售员 | 【示例値】 |
| `ROLE-PURCHASER` | 采购员 | 2 业务 | 4 本人 | false | 采购员 | 【示例値】 |
| `ROLE-PLANNER` | 计划员 | 2 业务 | 3 本部门 | false | 计划员 | 【示例値】 |
| `ROLE-EMPLOYEE` | 普通员工 | 2 业务 | 4 本人 | false | —（SYS 追加） | 【示例値】 |

> SoD 競合ペア（例 `ROLE-PURCHASER`×`ROLE-PUR-MGR`）は `sys_param: sod.conflict-pairs` に初期投入する（[08 §9.2]）。08 §9.1 には「销售总监」「分管副总」等の一部ロールが未記載のため、08 への追記を Lead に提案する（未決 #2）。

### 2.5 採番ルール（sys_number_rule、初期 40 件）

[共通業務規則](../00-common/08-common-business-rules.md) 2.1 のプレフィックス・桁数・リセット周期をそのまま初期データとする。代表例：

| rule_code | prefix | date_format | seq_length | reset_cycle | example | 分類 |
|---|---|---|---|---|---|---|
| `SALES_ORDER` | `SO` | `yyMMdd` | 4 | 1 日次 | `SO2610200001` | 【示例値】伝票番号例 |
| `PURCHASE_ORDER` | `PO` | `yyMMdd` | 4 | 1 日次 | `PO2610200001` | 【示例値】 |
| `WORK_ORDER` | `WO` | `yyMMdd` | 4 | 1 日次 | `WO2610200001` | 【示例値】 |
| `CUSTOMER` | `C` | ``（空） | 6 | 4 無 | `C000123` | 【示例値】 |
| `SUPPLIER` | `S` | ``（空） | 6 | 4 無 | `S000045` | 【示例値】 |
| `VOUCHER` | `记-` | ``（空） | 4 | 2 月次 | `记-0001` | 【実データ】凭证字規則 |

### 2.6 辞書（sys_dict_item 初期値）— [06-code-list.md](../00-common/06-code-list.md) と一致させる

| dict_code | 項目例（item_code: item_name） | 出典 |
|---|---|---|
| `TAX_CODE` | `VAT13`: 增值税 13% / `VAT9`: 9% / `VAT6`: 6% / `VAT0`: 0% / `VAT3`: 征收率 3% / `VAT1`: 征收率 1% | 【実データ】[06-code-list.md](../00-common/06-code-list.md) §7 |
| `UNIT_TYPE` | `KGM`: 千克 / `PCE`: 件 / `MTR`: 米 / `MTK`: 平方米 / `MTQ`: 立方米 / `HUR`: 小时 / `SET`: 套 / `BOX`: 箱 / `ROL`: 卷 | 【実データ】同 §6 |
| `CURRENCY` | `CNY`: 人民币 / `USD`: 美元 / `EUR`: 欧元 | 【実データ】同 §3、ISO 4217 |
| `SETTLEMENT_METHOD` | 10 種（BANK_TRANSFER 等） | 【実データ】同 §8.1 |
| `PAYMENT_TERM` | 8 種（NET30 等） | 【実データ】同 §8.2 |
| `CUSTOMER_GRADE` | A 战略客户 / B 重点客户 / C 一般客户 / D 潜在客户 | 【示例値】 |

### 2.7 システムパラメータ（sys_param 初期値）

| param_key | 初期値 | 分類 | 用途 |
|---|---|---|---|
| `auth.password-expire-days` | 90 | 【示例値】社内規程 | F-SYS-001 |
| `auth.lock-minutes` | 30 | 【示例値】 | F-SYS-001 |
| `auth.max-login-fail` | 5 | 【示例値】 | F-SYS-001 |
| `auth.multi-login` | true | 【示例値】 | F-SYS-001 |
| `file.max-size-mb` | 20 | 【示例値】 | F-SYS-010 |
| `job.max-concurrent` | 10 | 【示例値】 | F-SYS-013 |
| `workflow.task-timeout-hours` | 24 | 【示例値】 | F-WF-008 |
| `workflow.auto-approve-enabled` | false | 【示例値】 | F-WF-008 |
| `sod.conflict-pairs` | JSON（8 ペア） | 【示例値】 | F-SYS-003 |

### 2.8 通知テンプレート（sys_notification_template、初期 10 件）

| template_code | channel | biz_scene | 分類 |
|---|---|---|---|
| `WF_TASK_CREATED` | 1,2 | WORKFLOW_TASK_CREATED | 【示例値】 |
| `WF_TASK_APPROVED` | 1,2 | WORKFLOW_TASK_APPROVED | 【示例値】 |
| `WF_TASK_REJECTED` | 1,2 | WORKFLOW_TASK_REJECTED | 【示例値】 |
| `WF_TASK_TIMEOUT` | 1,2 | WORKFLOW_TASK_TIMEOUT | 【示例値】 |
| `SYS_PASSWORD_EXPIRE` | 1,2 | SYS_PASSWORD_EXPIRE | 【示例値】 |
| `SYS_BATCH_FAILED` | 2 | SYS_BATCH_FAILED | 【示例値】 |
| `SYS_IF_FAILED` | 2 | SYS_IF_FAILED | 【示例値】 |
| `INV_STOCK_SHORTAGE` | 1 | INV_STOCK_SHORTAGE | 【示例値】 |
| `SAL_CREDIT_EXCEEDED` | 1,2 | SAL_CREDIT_EXCEEDED | 【示例値】 |
| `PUR_DELIVERY_DELAY` | 1 | PUR_DELIVERY_DELAY | 【示例値】 |

### 2.9 初期管理者・サンプルユーザ

| user_code | username | real_name | department | position | role | 分類 |
|---|---|---|---|---|---|---|
| `E000001` | `E000001` | 系统管理员（示例） | D080 信息部 | P019 | `ROLE-SYS-ADMIN` | 【示例値】 |
| `E000002` | `E000002` | 总经理（示例） | —（董事会/总经理直轄） | P001 | `ROLE-GM` | 【示例値】 |
| `E000010` | `E000010` | 分管副总（示例） | — | P020 | `ROLE-VP` | 【示例値】 |
| `E000123` | `E000123` | 张建国 | D080 信息部 | P019 | `ROLE-SYS-ADMIN` | 【示例値】設計検証用 |
| `E000124` | `E000124` | 李明 | D020 采购部 | P004 | `ROLE-PUR-MGR` | 【示例値】 |
| `E000125` | `E000125` | 王芳 | D020 采购部 | P005 | `ROLE-PURCHASER` | 【示例値】 |

> 個人情報はすべて架空。実装時は顧客企業の実ユーザで置換する。初期パスワードは初回起動時に生成し、初回ログインで変更を強制する（[01-auth-login.md](01-auth-login.md) BR-06）。

## 3. 仮定値の一覧

| # | 仮定値 | 値 | 根拠・備考 |
|---|---|---|---|
| 1 | 部門数 | 8（初期） | [demo-company.md](../90-data/demo-company.md) §2.2 |
| 2 | ユーザ数 | 900 名 | README 2.1 / demo-company.md §1 |
| 3 | ロール数 | 18 | [approval-matrix.md](../90-data/approval-matrix.md) 3 章 + SYS 追加 |
| 4 | 採番ルール数 | 40 | [共通業務規則](../00-common/08-common-business-rules.md) 2.1 |
| 5 | 監査ログ | 1,000 万件/年 | 想定操作量から試算（1 日約 3 万件） |
| 6 | 添付 | 20 万件/年 | 受注・購買・工単の添付想定 |
| 7 | 通知 | 50 万件/年 | 承認依頼・結果・アラート |
| 8 | ジョブ実行 | 32 ジョブ（初期） | 92 章のバッチ一覧 + 各域バッチ |

## 4. データ整合性ルール（初期投入時）

1. 会社→工厂→部門→岗位→ユーザ→ロール→権限の順に投入する（FK 依存）。
2. 初期管理者は `is_builtin=true` で投入し、削除・停用不可とする。
3. 辞書・パラメータ・採番ルールは `is_system/is_readonly` フラグを設定して投入する（削除不可）。
4. 既存データがある場合はスキップする（BAT-SYS-012 は冪等）。
5. 投入後、BAT-SYS-011（キャッシュ再構築）を実行し、BAT-SYS-010（整合性検査）で確認する。
6. 部門・岗位・ロールは [demo-company.md](../90-data/demo-company.md) / [06-code-list.md](../00-common/06-code-list.md) / [approval-matrix.md](../90-data/approval-matrix.md) と突合済みであること（四半期ごとに再確認）。

## 5. 未決事項

| # | 事項 | 理由 | 暫定仕様 | 担当 | 期限 |
|---|---|---|---|---|---|
| 1 | 08 §9.1 にないロール（销售总监・分管副总・HR/内审/运维）の扱い | 承認マトリクス・SYS 運用で必要だが 08 §9.1 未記載 | SYS の `ROLE-*` として初期投入し、08 §9.1 への追記を Lead に提案 | Lead / system-workflow | 2026-10-27 |
| 2 | ロールコード体系（`ROLE-*` vs `SYSTEM_ADMIN` 形式） | approval-matrix.md は `ROLE-*`、08 §9.1 はロール名のみ | `ROLE-*` を正とし、SYS 初期データに採用。全社規約として Lead 承認待ち | Lead | 2026-10-27 |
| 3 | 初期管理者の初期パスワード配布方式 | セキュリティ要件未確定 | 初回起動時に自動生成し WARN ログへ一度だけ出力、変更強制 | 系统管理员 | 2026-11-10 |
| 4 | 会社コード `HDJM` の採番 | README は公司を `1` と表記（ID）、コード体系は未定義 | `id=1`、`company_code='HDJM'`（示例値）。全社コード規則は第一版で確定（TODO） | Lead | 2026-11-17 |

## 6. 改訂履歴

| 版数 | 日付 | 変更内容 | 変更者 |
|---|---|---|---|
| v1.0 | 2026-10-20 | 初版：実データと出典、初期データ 8 種、仮定値一覧、整合性ルール、未決 3 | system-workflow |
| v1.1 | 2026-10-20 | 90-data と整合：部門を D010〜D080 の 8 件に統一（D000 廃止）、ロールコードを `ROLE-*`、税・単位・通貨を 06-code-list の実データコードに統一、職位・担当者例を追加、未決 4 件 | system-workflow |
| v1.2 | 2026-10-20 | Lead 裁决反映：工厂主データを MDM（`mdm_factory`）へ移管。§2.2 を「MDM 主データ＋SYS 組織設定（`sys_factory_setting`）」に変更 | system-workflow |