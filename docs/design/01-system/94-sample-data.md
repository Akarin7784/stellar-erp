# 系统管理 样例数据说明（系统管理 サンプルデータ説明）

| 項目 | 内容 |
|---|---|
| 文書名 | 系统管理 样例数据说明（系统管理 サンプルデータ説明） |
| 文書番号 | DSN-SYS-094 |
| 版数 | v1.6 |
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

系统管理员のロールコードは `SYSTEM_ADMIN` に確定する（[01-auth-login.md](01-auth-login.md):339、[90 §3.7](90-db-design.md):389 と一致。蓝色大肥鱼 2026-10-21 決定）。その他のロールコードは [approval-matrix.md](../90-data/approval-matrix.md) 3 章の `ROLE-*` を示例値とし、[共通業務規則](../00-common/08-common-business-rules.md) 9.1 のロール名と対応させる。`role_type=1`（内置）は削除・権限変更不可。

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
| `SYSTEM_ADMIN` | 系统管理员 | 1 内置 | 1 全社 | true | 系统管理员 | **確定値**（会社ごとに 1 件自動投入、全権限。§2.10） |
| `ROLE-HR-ADMIN` | 人事管理员 | 2 业务 | 1 全社 | false | —（SYS 追加） | 【示例値】 |
| `ROLE-AUDITOR` | 内审员 | 3 只读 | 1 全社 | false | —（SYS 追加） | 【示例値】 |
| `ROLE-OPS` | 运维担当 | 2 业务 | 1 全社 | false | —（SYS 追加） | 【示例値】 |
| `ROLE-SALES` | 销售员 | 2 业务 | 4 本人 | false | 销售员 | 【示例値】 |
| `ROLE-PURCHASER` | 采购员 | 2 业务 | 4 本人 | false | 采购员 | 【示例値】 |
| `ROLE-PLANNER` | 计划员 | 2 业务 | 3 本部门 | false | 计划员 | 【示例値】 |
| `ROLE-EMPLOYEE` | 普通员工 | 2 业务 | 4 本人 | false | —（SYS 追加） | 【示例値】 |

> SoD 競合ペア（例 `ROLE-PURCHASER`×`ROLE-PUR-MGR`）は `sys_param: sod.conflict-pairs` に初期投入する（[08 §9.2]）。08 §9.1 には「销售总监」「分管副总」等の一部ロールが未記載のため、08 への追記を Lead に提案する（未決 #1）。

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
| `E000001` | `E000001` | 系统管理员（示例） | D080 信息部 | P019 | `SYSTEM_ADMIN` | 【示例値】 |
| `E000002` | `E000002` | 总经理（示例） | —（董事会/总经理直轄） | P001 | `ROLE-GM` | 【示例値】 |
| `E000010` | `E000010` | 分管副总（示例） | — | P020 | `ROLE-VP` | 【示例値】 |
| `E000123` | `E000123` | 张建国 | D080 信息部 | P019 | `SYSTEM_ADMIN` | 【示例値】設計検証用 |
| `E000124` | `E000124` | 李明 | D020 采购部 | P004 | `ROLE-PUR-MGR` | 【示例値】 |
| `E000125` | `E000125` | 王芳 | D020 采购部 | P005 | `ROLE-PURCHASER` | 【示例値】 |

> 個人情報はすべて架空。実装時は顧客企業の実ユーザで置換する。初期パスワードは初回起動時に生成し、初回ログインで変更を強制する（[01-auth-login.md](01-auth-login.md) BR-06）。

### 2.10 メニュー・権限・系统管理员ロール（sys_menu / sys_role / sys_role_permission）

蓝色大肥鱼 2026-10-21 決定。種データは DBA の種マイグレーションで投入する（本書は仕様のみ。全件は §6 付録 A）。

**(1) データの単位**

| テーブル | 単位 | `company_id` | 一意キー・索引（迁移） |
|---|---|---|---|
| `sys_menu` | テナント単位（会社共通） | `0`（`sys_param` のテナント単位行と同じ扱い） | `uk_sys_menu_code (tenant_id, menu_code) WHERE deleted = FALSE` は一意のまま。`permission_code` は**一意にしない**：`uk_sys_menu_permission` を普通索引 `idx_sys_menu_permission (tenant_id, permission_code)` に変更（DBA が種マイグレーションで実施） |
| `sys_role` | 会社単位 | `sys_company.id` | `uk_sys_role_code (tenant_id, company_id, role_code) WHERE deleted = FALSE`（sys/V202610210708:93） |
| `sys_role_permission` | 会社単位 | `sys_company.id` | `uk_sys_role_permission (tenant_id, company_id, role_id, menu_id)`。**`deleted` 列なし・部分条件なし**（sys/V202610210708:81） |

**(2) メニューツリーの導出ルール**（画面・権限を新たに作らない）

1. 第 1 階層：業務域ごとに `menu_type=1`（目录）を 1 行。`menu_code` = `DIR-<域略号>`、`module_code` = 権限コードの第 1 セグメント（`system`/`mdm`/`sales`/`purchase`/`inventory`/`production`/`finance`/`workflow`/`integration`/`report`）。
2. 第 2 階層：[画面一覧](../20-matrix/02-screen-list.md) の全 `SCR-*`（`SCR-SYS-001` 登录は公開画面のため除外）を `menu_type=2`（菜单）で 1 行ずつ。`menu_code` = 画面 ID（一意）、`menu_name` = 画面名、親 = 当該域の目录。例：`SCR-SYS-012` 公司/工厂设置の親は `DIR-SYS`（系统管理）。
3. 各域 00-overview 画面一覧の「遷移元」に「メニュー」と書かれた画面は `is_visible=TRUE`（174 行。G-11 の `SCR-PRD-034` を加えると 175 行）、それ以外は `is_visible=FALSE` の非表示ルート。
4. 菜单行の `permission_code` は**全行必須**：画面一覧の権限コード（`a/b` 併記は分解し先頭、`:*` は同一リソースの具体コードで代替）。同じコードを複数の菜单行が持ってよい。
5. 第 3 階層：設計書（docs/design 全域、20-matrix を除く）に出現する権限コードのうち、どの菜单行も持たないものを `menu_type=3`（按钮）で 1 行ずつ。`menu_code` = `BTN-` + コードの `:` を `-` に置換し大文字化。親 = 同一リソース（第 1・2 セグメント）を最初に使う画面。該当画面がなければ当該域の目录直下。
6. `sort_no`：目录は 10 刻み（域順）、菜单は域内で画面 ID 順に 10 刻み、按钮は親内でコード昇順に 1 刻み。
7. 件数：目录 10、菜单 340、按钮 244、計 594 行。`permission_code` を持つ行 584（菜单 340 + 按钮 244）、異なるコード 518。うち V202610211405 が投入するのは G-11 の 5 行を除く 589 行（菜单 339、按钮 240、付与 579、異なるコード 513）。G-11 の 5 行は後続の増分迁移で投入し、V202610211405 は変更しない。

**(3) 認可の判定**

- 権限判定は**コードのみ**で行う（`@SaCheckPermission` / `v-permission`）。ユーザの権限集合 = 付与された `sys_role_permission.permission_code` をコードで重複排除した集合（`GET /api/system/auth/me` の `permissions[]` も同じ、[91](91-api-design.md)）。あるコードを持つ菜单・按钮のどれか 1 行が付与されていれば、そのコードを持つ全画面・操作が許可される。
- 目录行（`menu_type=1`）は `permission_code` を持たず、付与対象外（`sys_role_permission.permission_code NOT NULL`）。目录の表示は配下に許可された行があるかでフロントが判定する。目录単位の付与が必要になった時点で別途決定する。

**(4) `route_path`（フロント要件、2026-10-21）**

- 目录・菜单行は必ず `route_path` を持つ。**先頭スラッシュなし**（例 `system/users`）。按钮行は `route_path` なし（`permission_code` のみ）。
- 既存フロントルート（frontend/src/router/index.ts:17,23,29）と一致させる：`SCR-SYS-004` = `system/users`、`SCR-PRD-009` = `production/work-orders/new`、`SCR-PRD-010` = `production/work-orders/:id`。
- 命名規則：
  - 一覧・メニュー入口：`<module_code>/<リソースの複数形>`。
  - `<res>/new` は**真の新規登録画面のみ**。
  - 詳細は `<res>/:id`、既存データの編集は `<res>/:id/edit`。
  - 子画面（マスタの子表）と既存伝票への操作は `<res>/:id/<子または操作>`（例 `mdm/customers/:id/contacts`、`purchase/orders/:id/change`、`finance/vouchers/:id/reverse`）。
  - 伝票種別ごとに分かれた新規登録画面は `<res>/<種別>/new`（例 `inventory/stock-txns/sdo/new`）。
  - 1 画面で複数の伝票種別を扱う場合、`<種別>` は種別コード（小文字）を[09 §7.1](../00-common/09-cross-domain-flow.md) 取引種別一覧の順にハイフンで連結する（例 `inventory/stock-txns/mii-mir/new`（MII→MIR）、`inventory/stock-txns/osi-osr/new`（OSI→OSR））。
  - 設定・管理・実行画面はリソース名（`<module>/<res>`）または `<res>/<操作>`（例 `finance/periods/closing`、`system/profile/password`）。
  - 全 `route_path` は一意。衝突時のみ末尾に `/<画面 ID 小文字>` を付ける。
- 導出値はフロント実装時に確定し、変更時は本表を更新する。

**(5) 投入関数と投入範囲**

| 関数 | 処理 | 呼出し元 | EXECUTE |
|---|---|---|---|
| `sys_init_tenant(p_tenant_id BIGINT)` | 付録 A の `sys_menu` 全行（V202610211405 時点 589 行、G-11 の増分迁移後 594 行）を `company_id = 0` で冪等投入（`parent_id` は `menu_code` で解決、既存行は上書きしない）。続けて当該テナントの全会社について `sys_init_company` を呼ぶ | テナント開設（初期会社登録の後）、既存テナントの回填 | `erp_tenant_provisioner` のみ（既存どおり、sys/V202610211403:117） |
| `sys_init_company(p_tenant_id BIGINT, p_company_id BIGINT)` | ① 当該会社の `sys_param` 既定行（[90 §3.15](90-db-design.md)、既存行スキップ）。② 当該会社に `SYSTEM_ADMIN` が**存在しない場合のみ** `sys_role` 1 行（`role_code='SYSTEM_ADMIN'`、`role_name='系统管理员'`、`role_type=1` 内置、`data_scope_type=1` 全社、`requires_approval=TRUE`）を作成し、`permission_code IS NOT NULL` の全 `sys_menu` 行（V202610211405 時点 579 行、G-11 の増分迁移後 584 行、`system:company:create` を含む）を `sys_role_permission` に付与（`permission_code` は `sys_menu.permission_code` を写す）。既に `SYSTEM_ADMIN` があれば付与しない | 会社登録（`POST /api/system/companies`、[91 API 47a](91-api-design.md)。バックエンドが会社 INSERT と同一トランザクションで呼ぶ）、`sys_init_tenant`、既存会社の回填 | `erp_tenant_provisioner` と `erp_app` |

- 両関数とも `SECURITY DEFINER`、`SET search_path = pg_catalog, public`、`REVOKE EXECUTE … FROM PUBLIC`。
- `sys_init_company` は処理の最初に次を検査し、満たさなければ例外を送出する（`erp_app` から呼べるため）：
  1. `p_tenant_id = current_setting('app.tenant_id')::bigint`。
  2. `sys_company` に `id = p_company_id` の行が存在し、`tenant_id = p_tenant_id`、`deleted = FALSE`。
- 既存テナント・既存会社は種マイグレーションで全テナントに対して `sys_init_tenant` を実行して回填する。
- 失敗時は呼出し元トランザクション全体をロールバックする。

**(6) 冪等性・上書き禁止**（#52 と同じ要件）

- `sys_menu`：`ON CONFLICT (tenant_id, menu_code) WHERE deleted = FALSE DO NOTHING`。既存行の名称・並び・`route_path`・表示設定は上書きしない。
- `SYSTEM_ADMIN` と付与：作成・付与は「会社登録時」と「初回回填」の 2 回のみ。条件は「当該会社に `SYSTEM_ADMIN`（`deleted = FALSE`）がまだない」こと。再実行では付与しないため、管理者が外した付与は戻らない（`sys_role_permission` に `deleted` 列がなくても区別不要）。
- pgTAP で断言する：
  - 再実行で行数が変わらない／既存値が変わらない。
  - 全会社に `SYSTEM_ADMIN` が 1 件、付与数 = `permission_code` を持つ `sys_menu` 行数（V202610211405 時点 579、G-11 の増分迁移後 584）、`system:company:create` が付与済み。
  - 付与を 1 件削除 → 種（`sys_init_tenant` / `sys_init_company`）を再実行 → 削除した付与は戻らない。
  - `erp_app` として：他テナントの `p_tenant_id` を渡すとエラー／自テナントの `p_tenant_id` で他テナントの会社 ID を渡すとエラー／自社なら成功し、2 回目の呼出しで行数が変わらない。

**(7) ギャップと解決**

| # | 内容 | 解決 |
|---|---|---|
| G-1 | 次の 16 コードは設計書に出現するが対応画面がない：`integration:credential:update`、`integration:pda:use`、`integration:po-send:submit`、`production:param:update`、`purchase:match:approve`、`purchase:match:run`、`purchase:match:view`、`purchase:param:manage`、`report:audit:view`、`system:cache:refresh`、`system:import-template:view`、`system:outbox:retry`、`system:outbox:view`、`system:role-grant:approve`、`system:user-request:approve`、`system:user-request:submit` | 解決：当該域の目录直下の按钮として投入 |
| G-2 | `mdm:config:*`、`mdm:finance-master:*` はワイルドカードのみで具体コードが未定義 | 解決：投入対象外。MDM で具体コードを定義後に追加 |
| G-3 | `system:auth:login`（公開 API）・`SCR-SYS-001`（登录、認証不要） | 解決：投入対象外 |
| G-4 | 複数画面が同じ権限コードを使う（66 画面） | 解決（蓝色大肥鱼 2026-10-21）：`permission_code` の重複を許可し全菜单行に設定。`menu_code` は一意のまま。一意索引は普通索引に変更（DBA が種マイグレーションで実施） |
| G-5 | 目录行は `permission_code` を持たない | 解決：目录は付与対象外。判定はコードのみ（§2.10 (3)） |
| G-6 | `sys_role_permission` に `deleted` 列がない | 解決：付与は会社登録時と初回回填（`SYSTEM_ADMIN` 未作成時）のみ。再実行で戻らない（§2.10 (6)） |
| G-7 | 同域複合 FK の規則（`(tenant_id, company_id, x_id)`）は `sys_menu`（`company_id=0`）に適用できない | 解決：`sys_menu` を参照する FK は `sys_role_permission.menu_id` の 1 本のみ（`fk_sys_role_permission_menu`、`(tenant_id, menu_id)` 2 列の命名例外、[04 §6.2](../00-common/04-common-db-spec.md) 項 2a）。`sys_menu.parent_id` には FK を付けない（`parent_id` は 0＝ルート（V202610210104、01/90 §3.12）、ルート行は `parent_id=0` だが `id=0` の行は存在しないため、自己参照 FK を付けるとルート行の投入が 23503 で失敗する）。親子関係はアプリで検査（`MSG-SYS-021`）、種データは pgTAP で検査（`parent_id<>0` の行は同一テナントに `id=parent_id` の菜单が存在、`parent_id=0` は目录 10 行のみ）（蓝色大肥鱼 2026-10-21 決定、案 A） |
| G-8 | `route_path` の DDL 列コメント例が `/system/users`（sys/V202610210104:428） | 解決：先頭スラッシュなしを正とし、迁移コメントは DBA が種マイグレーションで修正 |
| G-9 | 系统管理员以外のロール（`ROLE-*` 17 件）は示例値 | 解決：本種マイグレーションの対象外 |
| G-10 | `component_path`・`icon` の値は設計書に定義がない | 解決：`NULL` で投入、フロント実装時に設定 |
| G-11 | 超産承認 API（[06/91](../06-production/91-api-design.md)、#66・#68）の権限コード `production:overproduction-approval:{view,create,submit,approve,cancel}`（reject は approve と共用）が V202610211405 の種にない | 解決（蓝色大肥鱼 2026-10-21 決定）：06 画面一覧に `SCR-PRD-034` 超产申请一覧を登録し（[06/00 §5](../06-production/00-overview.md)）、付録 A #397〜#401 に菜单 1 行（`production/overproduction-approvals`、`is_visible=TRUE`、view）と按钮 4 行（新規 create／提出 submit／承認・却下 approve／取消 cancel）を追加。DBA が**後続の増分迁移**（新バージョン。V202610211405 は変更しない）で投入する。増分迁移の要件：① `sys_menu` 5 行を全テナントに冪等投入（§2.10 (6) と同じ `ON CONFLICT DO NOTHING`）。② 既存会社の `SYSTEM_ADMIN`（`deleted = FALSE`）に**新しい 5 行（permission_code 付き）だけ**を一度だけ付与する（`ON CONFLICT DO NOTHING`）。既存の付与は変更せず、過去に撤销された付与も戻さない（既存 579 行分を再付与しない）。③ 以後に登録される会社は `sys_init_company` で 584 行全件（5 コードを含む）が付与される。pgTAP で次を断言する：既存会社の `SYSTEM_ADMIN` が 5 コードを得る／増分迁移前に撤销した既存付与が戻らない／増分迁移後の新規会社の `SYSTEM_ADMIN` が 5 コードを含む 584 行を持つ／再実行で行数が変わらない |

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
| 3 | 初期管理者の初期パスワード配布方式 | セキュリティ要件未確定 | 初回起動時に自動生成し WARN ログへ一度だけ出力、変更強制 | 系统管理员 | 2026-11-10 |
| 4 | 会社コード `HDJM` の採番 | README は公司を `1` と表記（ID）、コード体系は未定義 | `id=1`、`company_code='HDJM'`（示例値）。全社コード規則は第一版で確定（TODO） | Lead | 2026-11-17 |

## 6. 付録 A：`sys_menu` 種データ全件（594 行。うち #397〜#401 の 5 行は G-11 の後続増分迁移で投入）

§2.10 の規則で [画面一覧](../20-matrix/02-screen-list.md)・各域設計書の権限コードから導出した。`company_id = 0`、`status = 1`、`is_external = FALSE`。`parent_id` は「親 menu_code」で解決する。`permission_code` は複数行で重複しうる。

| # | menu_code | menu_name | menu_type | module_code | 親 menu_code | route_path | permission_code | sort_no | 備考 |
|---|---|---|---|---|---|---|---|---|---|
| 1 | `DIR-SYS` | 系统管理 | 1 目录 | `system` | —（ルート） | `system` | — | 10 | 目录 |
| 2 | `BTN-SYSTEM-CACHE-REFRESH` | refresh | 3 按钮 | `system` | `DIR-SYS` | — | `system:cache:refresh` | 1 | 対応画面なし（ディレクトリ直下） |
| 3 | `BTN-SYSTEM-IMPORT-TEMPLATE-VIEW` | view | 3 按钮 | `system` | `DIR-SYS` | — | `system:import-template:view` | 2 | 対応画面なし（ディレクトリ直下） |
| 4 | `BTN-SYSTEM-OUTBOX-RETRY` | retry | 3 按钮 | `system` | `DIR-SYS` | — | `system:outbox:retry` | 3 | 対応画面なし（ディレクトリ直下） |
| 5 | `BTN-SYSTEM-OUTBOX-VIEW` | view | 3 按钮 | `system` | `DIR-SYS` | — | `system:outbox:view` | 4 | 対応画面なし（ディレクトリ直下） |
| 6 | `BTN-SYSTEM-ROLE-GRANT-APPROVE` | approve | 3 按钮 | `system` | `DIR-SYS` | — | `system:role-grant:approve` | 5 | 対応画面なし（ディレクトリ直下） |
| 7 | `BTN-SYSTEM-USER-REQUEST-APPROVE` | approve | 3 按钮 | `system` | `DIR-SYS` | — | `system:user-request:approve` | 6 | 対応画面なし（ディレクトリ直下） |
| 8 | `BTN-SYSTEM-USER-REQUEST-SUBMIT` | submit | 3 按钮 | `system` | `DIR-SYS` | — | `system:user-request:submit` | 7 | 対応画面なし（ディレクトリ直下） |
| 9 | `SCR-SYS-002` | 密码修改（强制/任意） | 2 菜单 | `system` | `DIR-SYS` | `system/profile/password` | `system:profile:update` | 10 | 非表示ルート（is_visible=FALSE） |
| 10 | `SCR-SYS-003` | 个人中心 | 2 菜单 | `system` | `DIR-SYS` | `system/profiles` | `system:profile:view` | 20 |  |
| 11 | `SCR-SYS-004` | 用户一覧 | 2 菜单 | `system` | `DIR-SYS` | `system/users` | `system:user:view` | 30 |  |
| 12 | `BTN-SYSTEM-USER-DELETE` | delete | 3 按钮 | `system` | `SCR-SYS-004` | — | `system:user:delete` | 1 |  |
| 13 | `BTN-SYSTEM-USER-DISABLE` | disable | 3 按钮 | `system` | `SCR-SYS-004` | — | `system:user:disable` | 2 |  |
| 14 | `BTN-SYSTEM-USER-EXPORT` | export | 3 按钮 | `system` | `SCR-SYS-004` | — | `system:user:export` | 3 |  |
| 15 | `BTN-SYSTEM-USER-IMPORT` | import | 3 按钮 | `system` | `SCR-SYS-004` | — | `system:user:import` | 4 |  |
| 16 | `BTN-SYSTEM-USER-REOPEN` | reopen | 3 按钮 | `system` | `SCR-SYS-004` | — | `system:user:reopen` | 5 |  |
| 17 | `BTN-SYSTEM-USER-RESET-PASSWORD` | reset-password | 3 按钮 | `system` | `SCR-SYS-004` | — | `system:user:reset-password` | 6 |  |
| 18 | `BTN-SYSTEM-USER-UNLOCK` | unlock | 3 按钮 | `system` | `SCR-SYS-004` | — | `system:user:unlock` | 7 |  |
| 19 | `BTN-SYSTEM-USER-UPDATE` | update | 3 按钮 | `system` | `SCR-SYS-004` | — | `system:user:update` | 8 |  |
| 20 | `SCR-SYS-005` | 用户登録編集 | 2 菜单 | `system` | `DIR-SYS` | `system/users/new` | `system:user:create` | 40 | 非表示ルート（is_visible=FALSE） |
| 21 | `SCR-SYS-006` | 用户詳細 | 2 菜单 | `system` | `DIR-SYS` | `system/users/:id` | `system:user:view` | 50 | 非表示ルート（is_visible=FALSE） |
| 22 | `SCR-SYS-007` | 角色一覧 | 2 菜单 | `system` | `DIR-SYS` | `system/roles` | `system:role:view` | 60 |  |
| 23 | `BTN-SYSTEM-ROLE-DELETE` | delete | 3 按钮 | `system` | `SCR-SYS-007` | — | `system:role:delete` | 1 |  |
| 24 | `BTN-SYSTEM-ROLE-EXPORT` | export | 3 按钮 | `system` | `SCR-SYS-007` | — | `system:role:export` | 2 |  |
| 25 | `BTN-SYSTEM-ROLE-UPDATE` | update | 3 按钮 | `system` | `SCR-SYS-007` | — | `system:role:update` | 3 |  |
| 26 | `SCR-SYS-008` | 角色登録編集（権限/データ範囲/项目権限） | 2 菜单 | `system` | `DIR-SYS` | `system/roles/new` | `system:role:create` | 70 | 非表示ルート（is_visible=FALSE） |
| 27 | `SCR-SYS-009` | 用户角色割当 | 2 菜单 | `system` | `DIR-SYS` | `system/users/:id/roles` | `system:user-role:update` | 80 | 非表示ルート（is_visible=FALSE） |
| 28 | `SCR-SYS-010` | 组织部门管理 | 2 菜单 | `system` | `DIR-SYS` | `system/departments` | `system:department:view` | 90 |  |
| 29 | `BTN-SYSTEM-DEPARTMENT-CREATE` | create | 3 按钮 | `system` | `SCR-SYS-010` | — | `system:department:create` | 1 |  |
| 30 | `BTN-SYSTEM-DEPARTMENT-DELETE` | delete | 3 按钮 | `system` | `SCR-SYS-010` | — | `system:department:delete` | 2 |  |
| 31 | `BTN-SYSTEM-DEPARTMENT-UPDATE` | update | 3 按钮 | `system` | `SCR-SYS-010` | — | `system:department:update` | 3 |  |
| 32 | `SCR-SYS-011` | 岗位管理 | 2 菜单 | `system` | `DIR-SYS` | `system/positions` | `system:position:view` | 100 |  |
| 33 | `BTN-SYSTEM-POSITION-CREATE` | create | 3 按钮 | `system` | `SCR-SYS-011` | — | `system:position:create` | 1 |  |
| 34 | `BTN-SYSTEM-POSITION-DELETE` | delete | 3 按钮 | `system` | `SCR-SYS-011` | — | `system:position:delete` | 2 |  |
| 35 | `BTN-SYSTEM-POSITION-UPDATE` | update | 3 按钮 | `system` | `SCR-SYS-011` | — | `system:position:update` | 3 |  |
| 36 | `SCR-SYS-012` | 公司/工厂设置 | 2 菜单 | `system` | `DIR-SYS` | `system/companies` | `system:company:view` | 110 |  |
| 37 | `BTN-SYSTEM-COMPANY-CREATE` | create | 3 按钮 | `system` | `SCR-SYS-012` | — | `system:company:create` | 1 |  |
| 38 | `BTN-SYSTEM-COMPANY-UPDATE` | update | 3 按钮 | `system` | `SCR-SYS-012` | — | `system:company:update` | 2 |  |
| 39 | `SCR-SYS-013` | 租户设置（予約） | 2 菜单 | `system` | `DIR-SYS` | `system/tenants` | `system:tenant:view` | 120 |  |
| 40 | `BTN-SYSTEM-TENANT-UPDATE` | update | 3 按钮 | `system` | `SCR-SYS-013` | — | `system:tenant:update` | 1 |  |
| 41 | `SCR-SYS-014` | 菜单管理 | 2 菜单 | `system` | `DIR-SYS` | `system/menus` | `system:menu:view` | 130 |  |
| 42 | `BTN-SYSTEM-MENU-CREATE` | create | 3 按钮 | `system` | `SCR-SYS-014` | — | `system:menu:create` | 1 |  |
| 43 | `BTN-SYSTEM-MENU-DELETE` | delete | 3 按钮 | `system` | `SCR-SYS-014` | — | `system:menu:delete` | 2 |  |
| 44 | `BTN-SYSTEM-MENU-UPDATE` | update | 3 按钮 | `system` | `SCR-SYS-014` | — | `system:menu:update` | 3 |  |
| 45 | `SCR-SYS-015` | 数据字典一覧 | 2 菜单 | `system` | `DIR-SYS` | `system/dicts` | `system:dict:view` | 140 |  |
| 46 | `BTN-SYSTEM-DICT-CREATE` | create | 3 按钮 | `system` | `SCR-SYS-015` | — | `system:dict:create` | 1 |  |
| 47 | `SCR-SYS-016` | 字典項目編集 | 2 菜单 | `system` | `DIR-SYS` | `system/dicts/:id/items` | `system:dict:update` | 150 | 非表示ルート（is_visible=FALSE） |
| 48 | `SCR-SYS-017` | 系统参数 | 2 菜单 | `system` | `DIR-SYS` | `system/params` | `system:param:view` | 160 |  |
| 49 | `BTN-SYSTEM-PARAM-UPDATE` | update | 3 按钮 | `system` | `SCR-SYS-017` | — | `system:param:update` | 1 |  |
| 50 | `SCR-SYS-018` | 操作审计日志 | 2 菜单 | `system` | `DIR-SYS` | `system/audit-logs` | `system:audit-log:view` | 170 |  |
| 51 | `BTN-SYSTEM-AUDIT-LOG-EXPORT` | export | 3 按钮 | `system` | `SCR-SYS-018` | — | `system:audit-log:export` | 1 |  |
| 52 | `SCR-SYS-019` | 登录日志 | 2 菜单 | `system` | `DIR-SYS` | `system/login-logs` | `system:login-log:view` | 180 |  |
| 53 | `BTN-SYSTEM-LOGIN-LOG-EXPORT` | export | 3 按钮 | `system` | `SCR-SYS-019` | — | `system:login-log:export` | 1 |  |
| 54 | `SCR-SYS-020` | 附件管理 | 2 菜单 | `system` | `DIR-SYS` | `system/attachments` | `system:attachment:view` | 190 |  |
| 55 | `BTN-SYSTEM-ATTACHMENT-DELETE` | delete | 3 按钮 | `system` | `SCR-SYS-020` | — | `system:attachment:delete` | 1 |  |
| 56 | `BTN-SYSTEM-ATTACHMENT-UPLOAD` | upload | 3 按钮 | `system` | `SCR-SYS-020` | — | `system:attachment:upload` | 2 |  |
| 57 | `SCR-SYS-021` | 消息通知中心/待办中心 | 2 菜单 | `system` | `DIR-SYS` | `system/notifications` | `system:notification:view` | 200 | 非表示ルート（is_visible=FALSE） |
| 58 | `BTN-SYSTEM-NOTIFICATION-READ` | read | 3 按钮 | `system` | `SCR-SYS-021` | — | `system:notification:read` | 1 |  |
| 59 | `SCR-SYS-022` | 通知模板管理 | 2 菜单 | `system` | `DIR-SYS` | `system/notification-templates` | `system:notification-template:view` | 210 |  |
| 60 | `BTN-SYSTEM-NOTIFICATION-TEMPLATE-UPDATE` | update | 3 按钮 | `system` | `SCR-SYS-022` | — | `system:notification-template:update` | 1 |  |
| 61 | `SCR-SYS-023` | 单据编号规则 | 2 菜单 | `system` | `DIR-SYS` | `system/number-rules` | `system:number-rule:view` | 220 |  |
| 62 | `BTN-SYSTEM-NUMBER-RULE-UPDATE` | update | 3 按钮 | `system` | `SCR-SYS-023` | — | `system:number-rule:update` | 1 |  |
| 63 | `SCR-SYS-024` | 导入导出中心 | 2 菜单 | `system` | `DIR-SYS` | `system/jobs` | `system:job:view` | 230 |  |
| 64 | `BTN-SYSTEM-JOB-CANCEL` | cancel | 3 按钮 | `system` | `SCR-SYS-024` | — | `system:job:cancel` | 1 |  |
| 65 | `BTN-SYSTEM-JOB-CREATE` | create | 3 按钮 | `system` | `SCR-SYS-024` | — | `system:job:create` | 2 |  |
| 66 | `BTN-SYSTEM-JOB-DOWNLOAD` | download | 3 按钮 | `system` | `SCR-SYS-024` | — | `system:job:download` | 3 |  |
| 67 | `SCR-SYS-025` | 异步任务詳細/進捗 | 2 菜单 | `system` | `DIR-SYS` | `system/jobs/:id` | `system:job:view` | 240 | 非表示ルート（is_visible=FALSE） |
| 68 | `SCR-SYS-026` | 打印模板管理 | 2 菜单 | `system` | `DIR-SYS` | `system/print-templates` | `system:print-template:view` | 250 |  |
| 69 | `BTN-SYSTEM-PRINT-TEMPLATE-UPDATE` | update | 3 按钮 | `system` | `SCR-SYS-026` | — | `system:print-template:update` | 1 |  |
| 70 | `SCR-SYS-027` | 在线用户 | 2 菜单 | `system` | `DIR-SYS` | `system/online-users` | `system:online-user:view` | 260 |  |
| 71 | `BTN-SYSTEM-ONLINE-USER-KICKOUT` | kickout | 3 按钮 | `system` | `SCR-SYS-027` | — | `system:online-user:kickout` | 1 |  |
| 72 | `SCR-SYS-028` | 定时任务监控 | 2 菜单 | `system` | `DIR-SYS` | `system/job-monitors` | `system:job-monitor:view` | 270 |  |
| 73 | `BTN-SYSTEM-JOB-MONITOR-RUN` | run | 3 按钮 | `system` | `SCR-SYS-028` | — | `system:job-monitor:run` | 1 |  |
| 74 | `SCR-SYS-029` | 系统初始化与数据维护 | 2 菜单 | `system` | `DIR-SYS` | `system/maintenances` | `system:maintenance:view` | 280 |  |
| 75 | `BTN-SYSTEM-MAINTENANCE-APPROVE` | approve | 3 按钮 | `system` | `SCR-SYS-029` | — | `system:maintenance:approve` | 1 |  |
| 76 | `BTN-SYSTEM-MAINTENANCE-EXECUTE` | execute | 3 按钮 | `system` | `SCR-SYS-029` | — | `system:maintenance:execute` | 2 |  |
| 77 | `SCR-SYS-030` | 通知发送履歴 | 2 菜单 | `system` | `DIR-SYS` | `system/notification-logs` | `system:notification-log:view` | 290 | 非表示ルート（is_visible=FALSE） |
| 78 | `DIR-MDM` | 主数据管理 | 1 目录 | `mdm` | —（ルート） | `mdm` | — | 20 | 目录 |
| 79 | `SCR-MDM-001` | 物料一覧 | 2 菜单 | `mdm` | `DIR-MDM` | `mdm/materials` | `mdm:material:view` | 10 |  |
| 80 | `BTN-MDM-MATERIAL-DELETE` | delete | 3 按钮 | `mdm` | `SCR-MDM-001` | — | `mdm:material:delete` | 1 |  |
| 81 | `BTN-MDM-MATERIAL-EXPORT` | export | 3 按钮 | `mdm` | `SCR-MDM-001` | — | `mdm:material:export` | 2 |  |
| 82 | `BTN-MDM-MATERIAL-FORCE-DEACTIVATE` | force-deactivate | 3 按钮 | `mdm` | `SCR-MDM-001` | — | `mdm:material:force-deactivate` | 3 |  |
| 83 | `BTN-MDM-MATERIAL-PRINT` | print | 3 按钮 | `mdm` | `SCR-MDM-001` | — | `mdm:material:print` | 4 |  |
| 84 | `BTN-MDM-MATERIAL-UPDATE` | update | 3 按钮 | `mdm` | `SCR-MDM-001` | — | `mdm:material:update` | 5 |  |
| 85 | `SCR-MDM-002` | 物料登録編集 | 2 菜单 | `mdm` | `DIR-MDM` | `mdm/materials/new` | `mdm:material:create` | 20 | 非表示ルート（is_visible=FALSE） |
| 86 | `SCR-MDM-003` | 物料参照詳細 | 2 菜单 | `mdm` | `DIR-MDM` | `mdm/materials/:id` | `mdm:material:view` | 30 | 非表示ルート（is_visible=FALSE） |
| 87 | `SCR-MDM-004` | 物料分类树管理 | 2 菜单 | `mdm` | `DIR-MDM` | `mdm/material-categories` | `mdm:material-category:update` | 40 |  |
| 88 | `SCR-MDM-005` | 物料编码规则 | 2 菜单 | `mdm` | `DIR-MDM` | `mdm/code-rules` | `mdm:code-rule:update` | 50 |  |
| 89 | `SCR-MDM-006` | 物料工厂视图設定 | 2 菜单 | `mdm` | `DIR-MDM` | `mdm/material-factories` | `mdm:material-factory:update` | 60 |  |
| 90 | `SCR-MDM-011` | 客户一覧 | 2 菜单 | `mdm` | `DIR-MDM` | `mdm/customers` | `mdm:customer:view` | 70 |  |
| 91 | `BTN-MDM-CUSTOMER-DELETE` | delete | 3 按钮 | `mdm` | `SCR-MDM-011` | — | `mdm:customer:delete` | 1 |  |
| 92 | `BTN-MDM-CUSTOMER-EXPORT` | export | 3 按钮 | `mdm` | `SCR-MDM-011` | — | `mdm:customer:export` | 2 |  |
| 93 | `BTN-MDM-CUSTOMER-IMPORT` | import | 3 按钮 | `mdm` | `SCR-MDM-011` | — | `mdm:customer:import` | 3 |  |
| 94 | `SCR-MDM-012` | 客户登録編集 | 2 菜单 | `mdm` | `DIR-MDM` | `mdm/customers/new` | `mdm:customer:create` | 80 | 非表示ルート（is_visible=FALSE） |
| 95 | `SCR-MDM-013` | 客户参照詳細 | 2 菜单 | `mdm` | `DIR-MDM` | `mdm/customers/:id` | `mdm:customer:view` | 90 | 非表示ルート（is_visible=FALSE） |
| 96 | `SCR-MDM-014` | 客户联系人管理 | 2 菜单 | `mdm` | `DIR-MDM` | `mdm/customers/:id/contacts` | `mdm:customer:update` | 100 | 非表示ルート（is_visible=FALSE） |
| 97 | `SCR-MDM-015` | 客户收货地址管理 | 2 菜单 | `mdm` | `DIR-MDM` | `mdm/customers/:id/addresses` | `mdm:customer:update` | 110 | 非表示ルート（is_visible=FALSE） |
| 98 | `SCR-MDM-021` | 供应商一覧 | 2 菜单 | `mdm` | `DIR-MDM` | `mdm/suppliers` | `mdm:supplier:view` | 120 |  |
| 99 | `BTN-MDM-SUPPLIER-DELETE` | delete | 3 按钮 | `mdm` | `SCR-MDM-021` | — | `mdm:supplier:delete` | 1 |  |
| 100 | `BTN-MDM-SUPPLIER-EXPORT` | export | 3 按钮 | `mdm` | `SCR-MDM-021` | — | `mdm:supplier:export` | 2 |  |
| 101 | `BTN-MDM-SUPPLIER-IMPORT` | import | 3 按钮 | `mdm` | `SCR-MDM-021` | — | `mdm:supplier:import` | 3 |  |
| 102 | `SCR-MDM-022` | 供应商登録編集 | 2 菜单 | `mdm` | `DIR-MDM` | `mdm/suppliers/new` | `mdm:supplier:create` | 130 | 非表示ルート（is_visible=FALSE） |
| 103 | `SCR-MDM-023` | 供应商参照詳細 | 2 菜单 | `mdm` | `DIR-MDM` | `mdm/suppliers/:id` | `mdm:supplier:view` | 140 | 非表示ルート（is_visible=FALSE） |
| 104 | `SCR-MDM-024` | 供应商资质管理 | 2 菜单 | `mdm` | `DIR-MDM` | `mdm/suppliers/:id/qualifications` | `mdm:supplier:update` | 150 | 非表示ルート（is_visible=FALSE） |
| 105 | `SCR-MDM-025` | 供应商供货范围管理 | 2 菜单 | `mdm` | `DIR-MDM` | `mdm/suppliers/:id/supply-scopes` | `mdm:supplier:update` | 160 | 非表示ルート（is_visible=FALSE） |
| 106 | `SCR-MDM-026` | 供应商准入审查 | 2 菜单 | `mdm` | `DIR-MDM` | `mdm/supplier-admissions` | `mdm:supplier-admission:approve` | 170 |  |
| 107 | `SCR-MDM-031` | 仓库一覧/登録編集 | 2 菜单 | `mdm` | `DIR-MDM` | `mdm/warehouses` | `mdm:warehouse:view` | 180 |  |
| 108 | `BTN-MDM-WAREHOUSE-CREATE` | create | 3 按钮 | `mdm` | `SCR-MDM-031` | — | `mdm:warehouse:create` | 1 |  |
| 109 | `BTN-MDM-WAREHOUSE-PRINT` | print | 3 按钮 | `mdm` | `SCR-MDM-031` | — | `mdm:warehouse:print` | 2 |  |
| 110 | `SCR-MDM-032` | 库区登録編集 | 2 菜单 | `mdm` | `DIR-MDM` | `mdm/warehouses/new` | `mdm:warehouse:update` | 190 | 非表示ルート（is_visible=FALSE） |
| 111 | `SCR-MDM-033` | 库位一覧/登録編集 | 2 菜单 | `mdm` | `DIR-MDM` | `mdm/warehouses/update` | `mdm:warehouse:update` | 200 | 非表示ルート（is_visible=FALSE） |
| 112 | `SCR-MDM-034` | 库位一括生成ウィザード | 2 菜单 | `mdm` | `DIR-MDM` | `mdm/warehouses/update/scr-mdm-034` | `mdm:warehouse:update` | 210 | 非表示ルート（is_visible=FALSE） |
| 113 | `SCR-MDM-041` | 计量单位一覧/登録編集 | 2 菜单 | `mdm` | `DIR-MDM` | `mdm/uoms` | `mdm:uom:view` | 220 |  |
| 114 | `SCR-MDM-042` | 单位换算组管理 | 2 菜单 | `mdm` | `DIR-MDM` | `mdm/uom-groups` | `mdm:uom:update` | 230 | 非表示ルート（is_visible=FALSE） |
| 115 | `SCR-MDM-043` | 货币一覧/登録編集 | 2 菜单 | `mdm` | `DIR-MDM` | `mdm/currencies` | `mdm:currency:view` | 240 |  |
| 116 | `BTN-MDM-CURRENCY-UPDATE` | update | 3 按钮 | `mdm` | `SCR-MDM-043` | — | `mdm:currency:update` | 1 |  |
| 117 | `SCR-MDM-044` | 汇率一覧/登録編集 | 2 菜单 | `mdm` | `DIR-MDM` | `mdm/exchange-rates` | `mdm:exchange-rate:view` | 250 |  |
| 118 | `BTN-MDM-EXCHANGE-RATE-UPDATE` | update | 3 按钮 | `mdm` | `SCR-MDM-044` | — | `mdm:exchange-rate:update` | 1 |  |
| 119 | `SCR-MDM-045` | 标准代码・汇率导入 | 2 菜单 | `mdm` | `DIR-MDM` | `mdm/exchange-rates/import` | `mdm:exchange-rate:import` | 260 | 非表示ルート（is_visible=FALSE） |
| 120 | `SCR-MDM-046` | 税码一覧/登録編集 | 2 菜单 | `mdm` | `DIR-MDM` | `mdm/tax-codes` | `mdm:tax-code:view` | 270 |  |
| 121 | `SCR-MDM-047` | 税率与税收分类编码 | 2 菜单 | `mdm` | `DIR-MDM` | `mdm/tax-codes/classifications` | `mdm:tax-code:update` | 280 | 非表示ルート（is_visible=FALSE） |
| 122 | `SCR-MDM-051` | 销售价格表一覧 | 2 菜单 | `mdm` | `DIR-MDM` | `mdm/prices` | `mdm:price:view` | 290 |  |
| 123 | `SCR-MDM-052` | 销售价格表登録編集 | 2 菜单 | `mdm` | `DIR-MDM` | `mdm/prices/new` | `mdm:price:create` | 300 | 非表示ルート（is_visible=FALSE） |
| 124 | `SCR-MDM-053` | 折扣规则管理 | 2 菜单 | `mdm` | `DIR-MDM` | `mdm/prices/update` | `mdm:price:update` | 310 |  |
| 125 | `SCR-MDM-054` | 采购价格一覧/登録編集 | 2 菜单 | `mdm` | `DIR-MDM` | `mdm/purchase-prices` | `mdm:purchase-price:view` | 320 |  |
| 126 | `BTN-MDM-PURCHASE-PRICE-CREATE` | create | 3 按钮 | `mdm` | `SCR-MDM-054` | — | `mdm:purchase-price:create` | 1 |  |
| 127 | `BTN-MDM-PURCHASE-PRICE-UPDATE` | update | 3 按钮 | `mdm` | `SCR-MDM-054` | — | `mdm:purchase-price:update` | 2 |  |
| 128 | `SCR-MDM-055` | 供应商报价管理 | 2 菜单 | `mdm` | `DIR-MDM` | `mdm/supplier-quotations` | `mdm:supplier-quotation:view` | 330 |  |
| 129 | `BTN-MDM-SUPPLIER-QUOTATION-UPDATE` | update | 3 按钮 | `mdm` | `SCR-MDM-055` | — | `mdm:supplier-quotation:update` | 1 |  |
| 130 | `SCR-MDM-056` | 取价模拟与照会 | 2 菜单 | `mdm` | `DIR-MDM` | `mdm/prices/view` | `mdm:price:view` | 340 |  |
| 131 | `SCR-MDM-061` | 结算方式一覧/登録編集 | 2 菜单 | `mdm` | `DIR-MDM` | `mdm/settlements` | `mdm:settlement:view` | 350 |  |
| 132 | `BTN-MDM-SETTLEMENT-UPDATE` | update | 3 按钮 | `mdm` | `SCR-MDM-061` | — | `mdm:settlement:update` | 1 |  |
| 133 | `SCR-MDM-062` | 付款条件一覧/登録編集 | 2 菜单 | `mdm` | `DIR-MDM` | `mdm/payment-terms` | `mdm:payment-term:view` | 360 |  |
| 134 | `BTN-MDM-PAYMENT-TERM-UPDATE` | update | 3 按钮 | `mdm` | `SCR-MDM-062` | — | `mdm:payment-term:update` | 1 |  |
| 135 | `SCR-MDM-063` | 银行一覧/登録編集 | 2 菜单 | `mdm` | `DIR-MDM` | `mdm/banks` | `mdm:bank:view` | 370 |  |
| 136 | `BTN-MDM-BANK-UPDATE` | update | 3 按钮 | `mdm` | `SCR-MDM-063` | — | `mdm:bank:update` | 1 |  |
| 137 | `SCR-MDM-064` | 取引先银行账户管理 | 2 菜单 | `mdm` | `DIR-MDM` | `mdm/bank-accounts` | `mdm:bank-account:view` | 380 | 非表示ルート（is_visible=FALSE） |
| 138 | `BTN-MDM-BANK-ACCOUNT-UPDATE` | update | 3 按钮 | `mdm` | `SCR-MDM-064` | — | `mdm:bank-account:update` | 1 |  |
| 139 | `BTN-MDM-BANK-ACCOUNT-VERIFY` | verify | 3 按钮 | `mdm` | `SCR-MDM-064` | — | `mdm:bank-account:verify` | 2 |  |
| 140 | `SCR-MDM-071` | 客户信用额度一覧/登録編集 | 2 菜单 | `mdm` | `DIR-MDM` | `mdm/credits` | `mdm:credit:view` | 390 |  |
| 141 | `SCR-MDM-072` | 信用检查规则管理 | 2 菜单 | `mdm` | `DIR-MDM` | `mdm/credit-rules` | `mdm:credit:update` | 400 | 非表示ルート（is_visible=FALSE） |
| 142 | `SCR-MDM-073` | 供应商评估 | 2 菜单 | `mdm` | `DIR-MDM` | `mdm/supplier-evals` | `mdm:supplier-eval:view` | 410 |  |
| 143 | `BTN-MDM-SUPPLIER-EVAL-UPDATE` | update | 3 按钮 | `mdm` | `SCR-MDM-073` | — | `mdm:supplier-eval:update` | 1 |  |
| 144 | `SCR-MDM-074` | 供应商分级/AVL | 2 菜单 | `mdm` | `DIR-MDM` | `mdm/supplier-evals/view` | `mdm:supplier-eval:view` | 420 | 非表示ルート（is_visible=FALSE） |
| 145 | `SCR-MDM-081` | 物料替代关系管理 | 2 菜单 | `mdm` | `DIR-MDM` | `mdm/substitutes` | `mdm:substitute:view` | 430 |  |
| 146 | `BTN-MDM-SUBSTITUTE-UPDATE` | update | 3 按钮 | `mdm` | `SCR-MDM-081` | — | `mdm:substitute:update` | 1 |  |
| 147 | `SCR-MDM-082` | 条码规则管理 | 2 菜单 | `mdm` | `DIR-MDM` | `mdm/barcode-rules` | `mdm:barcode-rule:view` | 440 |  |
| 148 | `BTN-MDM-BARCODE-RULE-UPDATE` | update | 3 按钮 | `mdm` | `SCR-MDM-082` | — | `mdm:barcode-rule:update` | 1 |  |
| 149 | `SCR-MDM-083` | 条码标签打印 | 2 菜单 | `mdm` | `DIR-MDM` | `mdm/barcodes/print` | `mdm:barcode:print` | 450 | 非表示ルート（is_visible=FALSE） |
| 150 | `SCR-MDM-091` | 主数据变更申请一覧 | 2 菜单 | `mdm` | `DIR-MDM` | `mdm/changes` | `mdm:change:view` | 460 |  |
| 151 | `SCR-MDM-092` | 主数据变更审批/详细 | 2 菜单 | `mdm` | `DIR-MDM` | `mdm/changes/approve` | `mdm:change:approve` | 470 | 非表示ルート（is_visible=FALSE） |
| 152 | `SCR-MDM-093` | 主数据变更历史照会 | 2 菜单 | `mdm` | `DIR-MDM` | `mdm/changes/view` | `mdm:change:view` | 480 | 非表示ルート（is_visible=FALSE） |
| 153 | `SCR-MDM-094` | 数据质量校验 | 2 菜单 | `mdm` | `DIR-MDM` | `mdm/data-qualities` | `mdm:data-quality:view` | 490 |  |
| 154 | `BTN-MDM-DATA-QUALITY-MANAGE` | manage | 3 按钮 | `mdm` | `SCR-MDM-094` | — | `mdm:data-quality:manage` | 1 |  |
| 155 | `BTN-MDM-DATA-QUALITY-UPDATE` | update | 3 按钮 | `mdm` | `SCR-MDM-094` | — | `mdm:data-quality:update` | 2 |  |
| 156 | `SCR-MDM-095` | 主数据批量维护导入 | 2 菜单 | `mdm` | `DIR-MDM` | `mdm/materials/import` | `mdm:material:import` | 500 |  |
| 157 | `SCR-MDM-096` | 主数据数据权限設定 | 2 菜单 | `mdm` | `DIR-MDM` | `mdm/data-scopes` | `mdm:data-scope:update` | 510 |  |
| 158 | `SCR-MDM-097` | 主数据检索（主数据门户） | 2 菜单 | `mdm` | `DIR-MDM` | `mdm/portals` | `mdm:portal:view` | 520 |  |
| 159 | `SCR-MDM-098` | 工厂一覧/登録編集 | 2 菜单 | `mdm` | `DIR-MDM` | `mdm/factories` | `mdm:factory:view` | 530 |  |
| 160 | `BTN-MDM-FACTORY-UPDATE` | update | 3 按钮 | `mdm` | `SCR-MDM-098` | — | `mdm:factory:update` | 1 |  |
| 161 | `DIR-SAL` | 销售管理 | 1 目录 | `sales` | —（ルート） | `sales` | — | 30 | 目录 |
| 162 | `SCR-SAL-001` | 询价一覧 | 2 菜单 | `sales` | `DIR-SAL` | `sales/inquiries` | `sales:inquiry:view` | 10 |  |
| 163 | `BTN-SALES-INQUIRY-UPDATE` | update | 3 按钮 | `sales` | `SCR-SAL-001` | — | `sales:inquiry:update` | 1 |  |
| 164 | `SCR-SAL-002` | 询价登録編集 | 2 菜单 | `sales` | `DIR-SAL` | `sales/inquiries/new` | `sales:inquiry:create` | 20 | 非表示ルート（is_visible=FALSE） |
| 165 | `SCR-SAL-003` | 询价参照詳細 | 2 菜单 | `sales` | `DIR-SAL` | `sales/inquiries/:id` | `sales:inquiry:view` | 30 | 非表示ルート（is_visible=FALSE） |
| 166 | `SCR-SAL-004` | 报价单一覧 | 2 菜单 | `sales` | `DIR-SAL` | `sales/quotations` | `sales:quotation:view` | 40 |  |
| 167 | `BTN-SALES-QUOTATION-APPROVE` | approve | 3 按钮 | `sales` | `SCR-SAL-004` | — | `sales:quotation:approve` | 1 |  |
| 168 | `BTN-SALES-QUOTATION-CONVERT` | convert | 3 按钮 | `sales` | `SCR-SAL-004` | — | `sales:quotation:convert` | 2 |  |
| 169 | `BTN-SALES-QUOTATION-PRINT` | print | 3 按钮 | `sales` | `SCR-SAL-004` | — | `sales:quotation:print` | 3 |  |
| 170 | `SCR-SAL-005` | 报价单登録編集 | 2 菜单 | `sales` | `DIR-SAL` | `sales/quotations/new` | `sales:quotation:create` | 50 | 非表示ルート（is_visible=FALSE） |
| 171 | `SCR-SAL-006` | 报价单参照詳細 | 2 菜单 | `sales` | `DIR-SAL` | `sales/quotations/:id` | `sales:quotation:view` | 60 | 非表示ルート（is_visible=FALSE） |
| 172 | `SCR-SAL-007` | 报价单版本比較 | 2 菜单 | `sales` | `DIR-SAL` | `sales/quotations/:id/scr-sal-007` | `sales:quotation:view` | 70 | 非表示ルート（is_visible=FALSE） |
| 173 | `SCR-SAL-008` | 销售订单一覧 | 2 菜单 | `sales` | `DIR-SAL` | `sales/orders` | `sales:order:view` | 80 |  |
| 174 | `BTN-SALES-ORDER-CANCEL` | cancel | 3 按钮 | `sales` | `SCR-SAL-008` | — | `sales:order:cancel` | 1 |  |
| 175 | `BTN-SALES-ORDER-CHANGE` | change | 3 按钮 | `sales` | `SCR-SAL-008` | — | `sales:order:change` | 2 |  |
| 176 | `BTN-SALES-ORDER-CLOSE` | close | 3 按钮 | `sales` | `SCR-SAL-008` | — | `sales:order:close` | 3 |  |
| 177 | `BTN-SALES-ORDER-EXPORT` | export | 3 按钮 | `sales` | `SCR-SAL-008` | — | `sales:order:export` | 4 |  |
| 178 | `BTN-SALES-ORDER-PRINT` | print | 3 按钮 | `sales` | `SCR-SAL-008` | — | `sales:order:print` | 5 |  |
| 179 | `BTN-SALES-ORDER-SUBMIT` | submit | 3 按钮 | `sales` | `SCR-SAL-008` | — | `sales:order:submit` | 6 |  |
| 180 | `SCR-SAL-009` | 销售订单登録編集 | 2 菜单 | `sales` | `DIR-SAL` | `sales/orders/new` | `sales:order:create` | 90 | 非表示ルート（is_visible=FALSE） |
| 181 | `SCR-SAL-010` | 销售订单参照詳細 | 2 菜单 | `sales` | `DIR-SAL` | `sales/orders/:id` | `sales:order:view` | 100 | 非表示ルート（is_visible=FALSE） |
| 182 | `SCR-SAL-011` | 订单承认画面（WF） | 2 菜单 | `sales` | `DIR-SAL` | `sales/orders/approve` | `sales:order:approve` | 110 | 非表示ルート（is_visible=FALSE） |
| 183 | `SCR-SAL-012` | 订单变更ウィザード | 2 菜单 | `sales` | `DIR-SAL` | `sales/orders/update` | `sales:order:update` | 120 | 非表示ルート（is_visible=FALSE） |
| 184 | `SCR-SAL-013` | 订单变更履歴 | 2 菜单 | `sales` | `DIR-SAL` | `sales/orders/:id/scr-sal-013` | `sales:order:view` | 130 | 非表示ルート（is_visible=FALSE） |
| 185 | `SCR-SAL-014` | 发货通知一覧 | 2 菜单 | `sales` | `DIR-SAL` | `sales/deliveries` | `sales:delivery:view` | 140 |  |
| 186 | `BTN-SALES-DELIVERY-CANCEL` | cancel | 3 按钮 | `sales` | `SCR-SAL-014` | — | `sales:delivery:cancel` | 1 |  |
| 187 | `BTN-SALES-DELIVERY-UPDATE` | update | 3 按钮 | `sales` | `SCR-SAL-014` | — | `sales:delivery:update` | 2 |  |
| 188 | `SCR-SAL-015` | 发货通知登録編集 | 2 菜单 | `sales` | `DIR-SAL` | `sales/deliveries/new` | `sales:delivery:create` | 150 | 非表示ルート（is_visible=FALSE） |
| 189 | `SCR-SAL-016` | 拣货作业 | 2 菜单 | `sales` | `DIR-SAL` | `sales/deliveries/:id/pick` | `sales:delivery:pick` | 160 | 非表示ルート（is_visible=FALSE） |
| 190 | `SCR-SAL-017` | 出荷確定 | 2 菜单 | `sales` | `DIR-SAL` | `sales/deliveries/:id/confirm` | `sales:delivery:confirm` | 170 | 非表示ルート（is_visible=FALSE） |
| 191 | `SCR-SAL-018` | 送货单预览 | 2 菜单 | `sales` | `DIR-SAL` | `sales/deliveries/print` | `sales:delivery:print` | 180 | 非表示ルート（is_visible=FALSE） |
| 192 | `SCR-SAL-019` | 退货单一覧 | 2 菜单 | `sales` | `DIR-SAL` | `sales/returns` | `sales:return:view` | 190 |  |
| 193 | `BTN-SALES-RETURN-APPROVE` | approve | 3 按钮 | `sales` | `SCR-SAL-019` | — | `sales:return:approve` | 1 |  |
| 194 | `BTN-SALES-RETURN-CANCEL` | cancel | 3 按钮 | `sales` | `SCR-SAL-019` | — | `sales:return:cancel` | 2 |  |
| 195 | `BTN-SALES-RETURN-RECEIVE` | receive | 3 按钮 | `sales` | `SCR-SAL-019` | — | `sales:return:receive` | 3 |  |
| 196 | `SCR-SAL-020` | 退货单登録編集 | 2 菜单 | `sales` | `DIR-SAL` | `sales/returns/new` | `sales:return:create` | 200 | 非表示ルート（is_visible=FALSE） |
| 197 | `SCR-SAL-021` | 退货检验 | 2 菜单 | `sales` | `DIR-SAL` | `sales/returns/:id/inspect` | `sales:return:inspect` | 210 | 非表示ルート（is_visible=FALSE） |
| 198 | `SCR-SAL-022` | 退货单参照詳細 | 2 菜单 | `sales` | `DIR-SAL` | `sales/returns/:id` | `sales:return:view` | 220 | 非表示ルート（is_visible=FALSE） |
| 199 | `SCR-SAL-023` | 开票申请一覧 | 2 菜单 | `sales` | `DIR-SAL` | `sales/invoice-applications` | `sales:invoice-application:view` | 230 |  |
| 200 | `SCR-SAL-024` | 开票申请登録編集 | 2 菜单 | `sales` | `DIR-SAL` | `sales/invoice-applications/new` | `sales:invoice-application:create` | 240 | 非表示ルート（is_visible=FALSE） |
| 201 | `SCR-SAL-025` | 发票登记一覧 | 2 菜单 | `sales` | `DIR-SAL` | `sales/invoices` | `sales:invoice:view` | 250 |  |
| 202 | `BTN-SALES-INVOICE-APPROVE` | approve | 3 按钮 | `sales` | `SCR-SAL-025` | — | `sales:invoice:approve` | 1 |  |
| 203 | `BTN-SALES-INVOICE-RED` | red | 3 按钮 | `sales` | `SCR-SAL-025` | — | `sales:invoice:red` | 2 |  |
| 204 | `SCR-SAL-026` | 发票登记編集 | 2 菜单 | `sales` | `DIR-SAL` | `sales/invoices/:id/edit` | `sales:invoice:create` | 260 | 非表示ルート（is_visible=FALSE） |
| 205 | `SCR-SAL-027` | 发票参照詳細（赤伝） | 2 菜单 | `sales` | `DIR-SAL` | `sales/invoices/:id` | `sales:invoice:view` | 270 | 非表示ルート（is_visible=FALSE） |
| 206 | `SCR-SAL-028` | 对账单生成 | 2 菜单 | `sales` | `DIR-SAL` | `sales/statements` | `sales:statement:create` | 280 |  |
| 207 | `BTN-SALES-STATEMENT-CONFIRM` | confirm | 3 按钮 | `sales` | `SCR-SAL-028` | — | `sales:statement:confirm` | 1 |  |
| 208 | `SCR-SAL-029` | 对账单照会 | 2 菜单 | `sales` | `DIR-SAL` | `sales/statements/:id` | `sales:statement:view` | 290 | 非表示ルート（is_visible=FALSE） |
| 209 | `SCR-SAL-030` | 应收款查询 | 2 菜单 | `sales` | `DIR-SAL` | `sales/receivables` | `sales:receivable:view` | 300 |  |
| 210 | `SCR-SAL-031` | 账龄分析 | 2 菜单 | `sales` | `DIR-SAL` | `sales/receivables/view` | `sales:receivable:view` | 310 | 非表示ルート（is_visible=FALSE） |
| 211 | `SCR-SAL-032` | 信用额度照会 | 2 菜单 | `sales` | `DIR-SAL` | `sales/credits` | `sales:credit:view` | 320 |  |
| 212 | `BTN-SALES-CREDIT-APPROVE` | approve | 3 按钮 | `sales` | `SCR-SAL-032` | — | `sales:credit:approve` | 1 |  |
| 213 | `SCR-SAL-033` | 与信台帳明細（FIN 投影） | 2 菜单 | `sales` | `DIR-SAL` | `sales/credits/view` | `sales:credit:view` | 330 | 非表示ルート（is_visible=FALSE） |
| 214 | `SCR-SAL-034` | 信用超限审批申请 | 2 菜单 | `sales` | `DIR-SAL` | `sales/credits/approval-requests` | `sales:credit:submit` | 340 | 非表示ルート（is_visible=FALSE） |
| 215 | `SCR-SAL-035` | 价格表照会 | 2 菜单 | `sales` | `DIR-SAL` | `sales/prices` | `sales:price:view` | 350 |  |
| 216 | `SCR-SAL-036` | 特价申请一覧 | 2 菜单 | `sales` | `DIR-SAL` | `sales/price-overrides` | `sales:price-override:view` | 360 |  |
| 217 | `BTN-SALES-PRICE-OVERRIDE-APPROVE` | approve | 3 按钮 | `sales` | `SCR-SAL-036` | — | `sales:price-override:approve` | 1 |  |
| 218 | `SCR-SAL-037` | 特价申请登録編集 | 2 菜单 | `sales` | `DIR-SAL` | `sales/price-overrides/new` | `sales:price-override:create` | 370 | 非表示ルート（is_visible=FALSE） |
| 219 | `SCR-SAL-038` | 订单执行跟踪 | 2 菜单 | `sales` | `DIR-SAL` | `sales/trackings` | `sales:tracking:view` | 380 |  |
| 220 | `SCR-SAL-039` | 欠货・交期迟延一覧 | 2 菜单 | `sales` | `DIR-SAL` | `sales/trackings/view` | `sales:tracking:view` | 390 | 非表示ルート（is_visible=FALSE） |
| 221 | `SCR-SAL-040` | 销售预测一覧 | 2 菜单 | `sales` | `DIR-SAL` | `sales/forecasts` | `sales:forecast:view` | 400 |  |
| 222 | `SCR-SAL-041` | 销售预测登録編集 | 2 菜单 | `sales` | `DIR-SAL` | `sales/forecasts/new` | `sales:forecast:create` | 410 | 非表示ルート（is_visible=FALSE） |
| 223 | `SCR-SAL-042` | 换货申请登録 | 2 菜单 | `sales` | `DIR-SAL` | `sales/exchanges/new` | `sales:exchange:create` | 420 | 非表示ルート（is_visible=FALSE） |
| 224 | `SCR-SAL-043` | 销售明细报表 | 2 菜单 | `sales` | `DIR-SAL` | `sales/reports` | `sales:report:view` | 430 |  |
| 225 | `BTN-SALES-REPORT-EXPORT` | export | 3 按钮 | `sales` | `SCR-SAL-043` | — | `sales:report:export` | 1 |  |
| 226 | `SCR-SAL-044` | 毛利分析 | 2 菜单 | `sales` | `DIR-SAL` | `sales/reports/view` | `sales:report:view` | 440 | 非表示ルート（is_visible=FALSE） |
| 227 | `SCR-SAL-045` | 客户排名 | 2 菜单 | `sales` | `DIR-SAL` | `sales/reports/:id` | `sales:report:view` | 450 | 非表示ルート（is_visible=FALSE） |
| 228 | `SCR-SAL-046` | 出口销售信息 | 2 菜单 | `sales` | `DIR-SAL` | `sales/exports` | `sales:export:update` | 460 | 非表示ルート（is_visible=FALSE） |
| 229 | `SCR-SAL-047` | 出荷实绩照会 | 2 菜单 | `sales` | `DIR-SAL` | `sales/deliveries/view` | `sales:delivery:view` | 470 |  |
| 230 | `DIR-PUR` | 采购管理 | 1 目录 | `purchase` | —（ルート） | `purchase` | — | 40 | 目录 |
| 231 | `BTN-PURCHASE-MATCH-APPROVE` | approve | 3 按钮 | `purchase` | `DIR-PUR` | — | `purchase:match:approve` | 1 | 対応画面なし（ディレクトリ直下） |
| 232 | `BTN-PURCHASE-MATCH-RUN` | run | 3 按钮 | `purchase` | `DIR-PUR` | — | `purchase:match:run` | 2 | 対応画面なし（ディレクトリ直下） |
| 233 | `BTN-PURCHASE-MATCH-VIEW` | view | 3 按钮 | `purchase` | `DIR-PUR` | — | `purchase:match:view` | 3 | 対応画面なし（ディレクトリ直下） |
| 234 | `BTN-PURCHASE-PARAM-MANAGE` | manage | 3 按钮 | `purchase` | `DIR-PUR` | — | `purchase:param:manage` | 4 | 対応画面なし（ディレクトリ直下） |
| 235 | `SCR-PUR-001` | 请购单一覧 | 2 菜单 | `purchase` | `DIR-PUR` | `purchase/requisitions` | `purchase:requisition:view` | 10 |  |
| 236 | `BTN-PURCHASE-REQUISITION-CANCEL` | cancel | 3 按钮 | `purchase` | `SCR-PUR-001` | — | `purchase:requisition:cancel` | 1 |  |
| 237 | `BTN-PURCHASE-REQUISITION-CONVERT` | convert | 3 按钮 | `purchase` | `SCR-PUR-001` | — | `purchase:requisition:convert` | 2 |  |
| 238 | `BTN-PURCHASE-REQUISITION-PRINT` | print | 3 按钮 | `purchase` | `SCR-PUR-001` | — | `purchase:requisition:print` | 3 |  |
| 239 | `BTN-PURCHASE-REQUISITION-SUBMIT` | submit | 3 按钮 | `purchase` | `SCR-PUR-001` | — | `purchase:requisition:submit` | 4 |  |
| 240 | `BTN-PURCHASE-REQUISITION-UPDATE` | update | 3 按钮 | `purchase` | `SCR-PUR-001` | — | `purchase:requisition:update` | 5 |  |
| 241 | `SCR-PUR-002` | 请购单登録編集 | 2 菜单 | `purchase` | `DIR-PUR` | `purchase/requisitions/new` | `purchase:requisition:create` | 20 | 非表示ルート（is_visible=FALSE） |
| 242 | `SCR-PUR-003` | 请购审批 | 2 菜单 | `purchase` | `DIR-PUR` | `purchase/requisitions/approve` | `purchase:requisition:approve` | 30 | 非表示ルート（is_visible=FALSE） |
| 243 | `SCR-PUR-004` | 询价比价单一覧 | 2 菜单 | `purchase` | `DIR-PUR` | `purchase/rfqs` | `purchase:rfq:view` | 40 |  |
| 244 | `BTN-PURCHASE-RFQ-PRINT` | print | 3 按钮 | `purchase` | `SCR-PUR-004` | — | `purchase:rfq:print` | 1 |  |
| 245 | `BTN-PURCHASE-RFQ-SELECT` | select | 3 按钮 | `purchase` | `SCR-PUR-004` | — | `purchase:rfq:select` | 2 |  |
| 246 | `SCR-PUR-005` | 询价比价单登録編集 | 2 菜单 | `purchase` | `DIR-PUR` | `purchase/rfqs/new` | `purchase:rfq:create` | 50 | 非表示ルート（is_visible=FALSE） |
| 247 | `SCR-PUR-006` | 供应商报价登録 | 2 菜单 | `purchase` | `DIR-PUR` | `purchase/rfqs/:id/quote` | `purchase:rfq:quote` | 60 | 非表示ルート（is_visible=FALSE） |
| 248 | `SCR-PUR-007` | 比价表 | 2 菜单 | `purchase` | `DIR-PUR` | `purchase/rfqs/:id` | `purchase:rfq:view` | 70 | 非表示ルート（is_visible=FALSE） |
| 249 | `SCR-PUR-008` | 采购订单一覧 | 2 菜单 | `purchase` | `DIR-PUR` | `purchase/orders` | `purchase:order:view` | 80 |  |
| 250 | `BTN-PURCHASE-ORDER-CANCEL` | cancel | 3 按钮 | `purchase` | `SCR-PUR-008` | — | `purchase:order:cancel` | 1 |  |
| 251 | `BTN-PURCHASE-ORDER-PRINT` | print | 3 按钮 | `purchase` | `SCR-PUR-008` | — | `purchase:order:print` | 2 |  |
| 252 | `BTN-PURCHASE-ORDER-SEND` | send | 3 按钮 | `purchase` | `SCR-PUR-008` | — | `purchase:order:send` | 3 |  |
| 253 | `BTN-PURCHASE-ORDER-SUBMIT` | submit | 3 按钮 | `purchase` | `SCR-PUR-008` | — | `purchase:order:submit` | 4 |  |
| 254 | `BTN-PURCHASE-ORDER-UPDATE` | update | 3 按钮 | `purchase` | `SCR-PUR-008` | — | `purchase:order:update` | 5 |  |
| 255 | `SCR-PUR-009` | 采购订单登録編集 | 2 菜单 | `purchase` | `DIR-PUR` | `purchase/orders/new` | `purchase:order:create` | 90 | 非表示ルート（is_visible=FALSE） |
| 256 | `SCR-PUR-010` | 采购订单审批 | 2 菜单 | `purchase` | `DIR-PUR` | `purchase/orders/approve` | `purchase:order:approve` | 100 | 非表示ルート（is_visible=FALSE） |
| 257 | `SCR-PUR-011` | 采购订单变更 | 2 菜单 | `purchase` | `DIR-PUR` | `purchase/orders/:id/change` | `purchase:order:change` | 110 | 非表示ルート（is_visible=FALSE） |
| 258 | `SCR-PUR-012` | 收货单一覧 | 2 菜单 | `purchase` | `DIR-PUR` | `purchase/receipts` | `purchase:receipt:view` | 120 |  |
| 259 | `BTN-PURCHASE-RECEIPT-CANCEL` | cancel | 3 按钮 | `purchase` | `SCR-PUR-012` | — | `purchase:receipt:cancel` | 1 |  |
| 260 | `BTN-PURCHASE-RECEIPT-OVERRIDE` | override | 3 按钮 | `purchase` | `SCR-PUR-012` | — | `purchase:receipt:override` | 2 |  |
| 261 | `BTN-PURCHASE-RECEIPT-PRINT` | print | 3 按钮 | `purchase` | `SCR-PUR-012` | — | `purchase:receipt:print` | 3 |  |
| 262 | `SCR-PUR-013` | 收货单登録編集 | 2 菜单 | `purchase` | `DIR-PUR` | `purchase/receipts/new` | `purchase:receipt:create` | 130 | 非表示ルート（is_visible=FALSE） |
| 263 | `SCR-PUR-014` | 收货确认与待检跟踪 | 2 菜单 | `purchase` | `DIR-PUR` | `purchase/receipts/:id` | `purchase:receipt:view` | 140 | 非表示ルート（is_visible=FALSE） |
| 264 | `SCR-PUR-015` | 来料检验判定（IQC） | 2 菜单 | `purchase` | `DIR-PUR` | `purchase/inspections/judge` | `production:inspection:judge` | 150 | 非表示ルート（is_visible=FALSE） |
| 265 | `SCR-PUR-016` | 采购入库跟踪 | 2 菜单 | `purchase` | `DIR-PUR` | `purchase/receipts/:id/scr-pur-016` | `purchase:receipt:view` | 160 | 非表示ルート（is_visible=FALSE） |
| 266 | `SCR-PUR-017` | 采购退货单登録編集 | 2 菜单 | `purchase` | `DIR-PUR` | `purchase/returns/new` | `purchase:return:create` | 170 | 非表示ルート（is_visible=FALSE） |
| 267 | `BTN-PURCHASE-RETURN-APPROVE` | approve | 3 按钮 | `purchase` | `SCR-PUR-017` | — | `purchase:return:approve` | 1 |  |
| 268 | `BTN-PURCHASE-RETURN-PRINT` | print | 3 按钮 | `purchase` | `SCR-PUR-017` | — | `purchase:return:print` | 2 |  |
| 269 | `BTN-PURCHASE-RETURN-VIEW` | view | 3 按钮 | `purchase` | `SCR-PUR-017` | — | `purchase:return:view` | 3 |  |
| 270 | `SCR-PUR-018` | 采购退货出库确认 | 2 菜单 | `purchase` | `DIR-PUR` | `purchase/returns/:id/ship` | `purchase:return:ship` | 180 | 非表示ルート（is_visible=FALSE） |
| 271 | `SCR-PUR-019` | 采购发票登记 | 2 菜单 | `purchase` | `DIR-PUR` | `purchase/invoices` | `purchase:invoice:create` | 190 |  |
| 272 | `BTN-PURCHASE-INVOICE-CANCEL` | cancel | 3 按钮 | `purchase` | `SCR-PUR-019` | — | `purchase:invoice:cancel` | 1 |  |
| 273 | `SCR-PUR-020` | 三单匹配与差异处理 | 2 菜单 | `purchase` | `DIR-PUR` | `purchase/invoices/:id` | `purchase:invoice:view` | 200 | 非表示ルート（is_visible=FALSE） |
| 274 | `SCR-PUR-021` | 采购对账单 | 2 菜单 | `purchase` | `DIR-PUR` | `purchase/statements` | `purchase:statement:view` | 210 |  |
| 275 | `BTN-PURCHASE-STATEMENT-CONFIRM` | confirm | 3 按钮 | `purchase` | `SCR-PUR-021` | — | `purchase:statement:confirm` | 1 |  |
| 276 | `BTN-PURCHASE-STATEMENT-EXPORT` | export | 3 按钮 | `purchase` | `SCR-PUR-021` | — | `purchase:statement:export` | 2 |  |
| 277 | `SCR-PUR-022` | 应付/暂估台账 | 2 菜单 | `purchase` | `DIR-PUR` | `purchase/aps` | `purchase:ap:view` | 220 |  |
| 278 | `SCR-PUR-023` | 付款申请（采购发起） | 2 菜单 | `purchase` | `DIR-PUR` | `purchase/payment-requests` | `purchase:payment:create` | 230 | 非表示ルート（is_visible=FALSE） |
| 279 | `BTN-PURCHASE-PAYMENT-APPROVE` | approve | 3 按钮 | `purchase` | `SCR-PUR-023` | — | `purchase:payment:approve` | 1 |  |
| 280 | `SCR-PUR-024` | 预付款申请 | 2 菜单 | `purchase` | `DIR-PUR` | `purchase/payments/new` | `purchase:payment:create` | 240 | 非表示ルート（is_visible=FALSE） |
| 281 | `SCR-PUR-025` | 交期跟踪看板 | 2 菜单 | `purchase` | `DIR-PUR` | `purchase/trackings` | `purchase:tracking:view` | 250 |  |
| 282 | `BTN-PURCHASE-TRACKING-FOLLOWUP` | followup | 3 按钮 | `purchase` | `SCR-PUR-025` | — | `purchase:tracking:followup` | 1 |  |
| 283 | `SCR-PUR-026` | 采购价格查询 | 2 菜单 | `purchase` | `DIR-PUR` | `purchase/prices` | `purchase:price:view` | 260 |  |
| 284 | `SCR-PUR-027` | 计划采购建议 | 2 菜单 | `purchase` | `DIR-PUR` | `purchase/plans` | `purchase:plan:view` | 270 |  |
| 285 | `BTN-PURCHASE-PLAN-CONVERT` | convert | 3 按钮 | `purchase` | `SCR-PUR-027` | — | `purchase:plan:convert` | 1 |  |
| 286 | `SCR-PUR-028` | 供应商绩效评价 | 2 菜单 | `purchase` | `DIR-PUR` | `purchase/performances` | `purchase:performance:view` | 280 |  |
| 287 | `BTN-PURCHASE-PERFORMANCE-CALCULATE` | calculate | 3 按钮 | `purchase` | `SCR-PUR-028` | — | `purchase:performance:calculate` | 1 |  |
| 288 | `SCR-PUR-029` | 采购报表 | 2 菜单 | `purchase` | `DIR-PUR` | `purchase/reports` | `purchase:report:view` | 290 |  |
| 289 | `BTN-PURCHASE-REPORT-EXPORT` | export | 3 按钮 | `purchase` | `SCR-PUR-029` | — | `purchase:report:export` | 1 |  |
| 290 | `DIR-INV` | 库存管理 | 1 目录 | `inventory` | —（ルート） | `inventory` | — | 50 | 目录 |
| 291 | `SCR-INV-001` | 库存查询（现存量照会） | 2 菜单 | `inventory` | `DIR-INV` | `inventory/stock-balances` | `inventory:stock-balance:view` | 10 |  |
| 292 | `BTN-INVENTORY-STOCK-BALANCE-EXPORT` | export | 3 按钮 | `inventory` | `SCR-INV-001` | — | `inventory:stock-balance:export` | 1 |  |
| 293 | `SCR-INV-002` | 库存事务流水照会 | 2 菜单 | `inventory` | `DIR-INV` | `inventory/stock-txns` | `inventory:stock-txn:view` | 20 |  |
| 294 | `BTN-INVENTORY-STOCK-TXN-EXPORT` | export | 3 按钮 | `inventory` | `SCR-INV-002` | — | `inventory:stock-txn:export` | 1 |  |
| 295 | `BTN-INVENTORY-STOCK-TXN-POST` | post | 3 按钮 | `inventory` | `SCR-INV-002` | — | `inventory:stock-txn:post` | 2 |  |
| 296 | `BTN-INVENTORY-STOCK-TXN-PRINT` | print | 3 按钮 | `inventory` | `SCR-INV-002` | — | `inventory:stock-txn:print` | 3 |  |
| 297 | `BTN-INVENTORY-STOCK-TXN-REVERSE` | reverse | 3 按钮 | `inventory` | `SCR-INV-002` | — | `inventory:stock-txn:reverse` | 4 |  |
| 298 | `BTN-INVENTORY-STOCK-TXN-SUBMIT` | submit | 3 按钮 | `inventory` | `SCR-INV-002` | — | `inventory:stock-txn:submit` | 5 |  |
| 299 | `BTN-INVENTORY-STOCK-TXN-UPDATE` | update | 3 按钮 | `inventory` | `SCR-INV-002` | — | `inventory:stock-txn:update` | 6 |  |
| 300 | `SCR-INV-003` | 库存明细账（台帳） | 2 菜单 | `inventory` | `DIR-INV` | `inventory/stock-txns/view` | `inventory:stock-txn:view` | 30 | 非表示ルート（is_visible=FALSE） |
| 301 | `SCR-INV-004` | 采购入库单（GRI）登録 | 2 菜单 | `inventory` | `DIR-INV` | `inventory/stock-txns/gri/new` | `inventory:stock-txn:create` | 40 | 非表示ルート（is_visible=FALSE） |
| 302 | `SCR-INV-005` | 销售出库单（SDO）登録 | 2 菜单 | `inventory` | `DIR-INV` | `inventory/stock-txns/sdo/new` | `inventory:stock-txn:create` | 50 | 非表示ルート（is_visible=FALSE） |
| 303 | `SCR-INV-006` | 生产领料/退料单（MII/MIR）登録 | 2 菜单 | `inventory` | `DIR-INV` | `inventory/stock-txns/mii-mir/new` | `inventory:stock-txn:create` | 60 | 非表示ルート（is_visible=FALSE） |
| 304 | `SCR-INV-007` | 生产入库单（FGI）登録 | 2 菜单 | `inventory` | `DIR-INV` | `inventory/stock-txns/fgi/new` | `inventory:stock-txn:create` | 70 | 非表示ルート（is_visible=FALSE） |
| 305 | `SCR-INV-008` | 委外发料/收货单（OSI/OSR）登録 | 2 菜单 | `inventory` | `DIR-INV` | `inventory/stock-txns/osi-osr/new` | `inventory:stock-txn:create` | 80 | 非表示ルート（is_visible=FALSE） |
| 306 | `SCR-INV-009` | 其他入库单（AOI）登録 | 2 菜单 | `inventory` | `DIR-INV` | `inventory/stock-txns/create` | `inventory:stock-txn:create` | 90 |  |
| 307 | `SCR-INV-010` | 其他出库单（AOO）登録 | 2 菜单 | `inventory` | `DIR-INV` | `inventory/stock-txns/create/scr-inv-010` | `inventory:stock-txn:create` | 100 |  |
| 308 | `SCR-INV-011` | 库存调拨单（TR）登録 | 2 菜单 | `inventory` | `DIR-INV` | `inventory/transfers` | `inventory:transfer:create` | 110 |  |
| 309 | `BTN-INVENTORY-TRANSFER-APPROVE` | approve | 3 按钮 | `inventory` | `SCR-INV-011` | — | `inventory:transfer:approve` | 1 |  |
| 310 | `BTN-INVENTORY-TRANSFER-CANCEL` | cancel | 3 按钮 | `inventory` | `SCR-INV-011` | — | `inventory:transfer:cancel` | 2 |  |
| 311 | `BTN-INVENTORY-TRANSFER-PRINT` | print | 3 按钮 | `inventory` | `SCR-INV-011` | — | `inventory:transfer:print` | 3 |  |
| 312 | `BTN-INVENTORY-TRANSFER-RECEIVE` | receive | 3 按钮 | `inventory` | `SCR-INV-011` | — | `inventory:transfer:receive` | 4 |  |
| 313 | `BTN-INVENTORY-TRANSFER-SHIP` | ship | 3 按钮 | `inventory` | `SCR-INV-011` | — | `inventory:transfer:ship` | 5 |  |
| 314 | `SCR-INV-012` | 调拨在途跟踪 | 2 菜单 | `inventory` | `DIR-INV` | `inventory/transfers/view` | `inventory:transfer:view` | 120 | 非表示ルート（is_visible=FALSE） |
| 315 | `SCR-INV-013` | 盘点计划登録 | 2 菜单 | `inventory` | `DIR-INV` | `inventory/stocktakes` | `inventory:stocktake:create` | 130 |  |
| 316 | `BTN-INVENTORY-STOCKTAKE-ADJUST` | adjust | 3 按钮 | `inventory` | `SCR-INV-013` | — | `inventory:stocktake:adjust` | 1 |  |
| 317 | `BTN-INVENTORY-STOCKTAKE-SUBMIT` | submit | 3 按钮 | `inventory` | `SCR-INV-013` | — | `inventory:stocktake:submit` | 2 |  |
| 318 | `BTN-INVENTORY-STOCKTAKE-VIEW` | view | 3 按钮 | `inventory` | `SCR-INV-013` | — | `inventory:stocktake:view` | 3 |  |
| 319 | `SCR-INV-014` | 盘点单（实盘入力） | 2 菜单 | `inventory` | `DIR-INV` | `inventory/stocktakes/:id/count` | `inventory:stocktake:enter` | 140 | 非表示ルート（is_visible=FALSE） |
| 320 | `SCR-INV-015` | 盘点差异承认・调整 | 2 菜单 | `inventory` | `DIR-INV` | `inventory/stocktakes/:id/adjust` | `inventory:stocktake:approve` | 150 | 非表示ルート（is_visible=FALSE） |
| 321 | `SCR-INV-016` | 批次追溯照会 | 2 菜单 | `inventory` | `DIR-INV` | `inventory/batches` | `inventory:batch:trace` | 160 |  |
| 322 | `SCR-INV-017` | 批次效期预警 | 2 菜单 | `inventory` | `DIR-INV` | `inventory/batches/view` | `inventory:batch:view` | 170 |  |
| 323 | `SCR-INV-018` | 序列号照会 | 2 菜单 | `inventory` | `DIR-INV` | `inventory/serials` | `inventory:serial:view` | 180 |  |
| 324 | `SCR-INV-019` | 库存状态转换 | 2 菜单 | `inventory` | `DIR-INV` | `inventory/statuses/change` | `inventory:status:change` | 190 | 非表示ルート（is_visible=FALSE） |
| 325 | `SCR-INV-020` | 库龄・呆滞分析 | 2 菜单 | `inventory` | `DIR-INV` | `inventory/reports` | `inventory:report:view` | 200 |  |
| 326 | `BTN-INVENTORY-REPORT-EXPORT` | export | 3 按钮 | `inventory` | `SCR-INV-020` | — | `inventory:report:export` | 1 |  |
| 327 | `SCR-INV-021` | 安全库存・补货建议 | 2 菜单 | `inventory` | `DIR-INV` | `inventory/replenishments` | `inventory:replenishment:view` | 210 |  |
| 328 | `BTN-INVENTORY-REPLENISHMENT-GENERATE` | generate | 3 按钮 | `inventory` | `SCR-INV-021` | — | `inventory:replenishment:generate` | 1 |  |
| 329 | `SCR-INV-022` | 成本查询（移动平均） | 2 菜单 | `inventory` | `DIR-INV` | `inventory/costs` | `inventory:cost:view` | 220 |  |
| 330 | `BTN-INVENTORY-COST-APPROVE` | approve | 3 按钮 | `inventory` | `SCR-INV-022` | — | `inventory:cost:approve` | 1 |  |
| 331 | `BTN-INVENTORY-COST-RECALC` | recalc | 3 按钮 | `inventory` | `SCR-INV-022` | — | `inventory:cost:recalc` | 2 |  |
| 332 | `SCR-INV-023` | 成本调整单登録 | 2 菜单 | `inventory` | `DIR-INV` | `inventory/costs/new` | `inventory:cost:adjust` | 230 | 非表示ルート（is_visible=FALSE） |
| 333 | `SCR-INV-024` | 库存预留照会・释放 | 2 菜单 | `inventory` | `DIR-INV` | `inventory/reservations` | `inventory:reservation:view` | 240 |  |
| 334 | `BTN-INVENTORY-RESERVATION-CREATE` | create | 3 按钮 | `inventory` | `SCR-INV-024` | — | `inventory:reservation:create` | 1 |  |
| 335 | `BTN-INVENTORY-RESERVATION-RELEASE` | release | 3 按钮 | `inventory` | `SCR-INV-024` | — | `inventory:reservation:release` | 2 |  |
| 336 | `SCR-INV-025` | 库存月结执行 | 2 菜单 | `inventory` | `DIR-INV` | `inventory/periods` | `inventory:period:close` | 250 |  |
| 337 | `BTN-INVENTORY-PERIOD-REOPEN` | reopen | 3 按钮 | `inventory` | `SCR-INV-025` | — | `inventory:period:reopen` | 1 |  |
| 338 | `BTN-INVENTORY-PERIOD-VIEW` | view | 3 按钮 | `inventory` | `SCR-INV-025` | — | `inventory:period:view` | 2 |  |
| 339 | `SCR-INV-026` | PDA 扫码作業 | 2 菜单 | `inventory` | `DIR-INV` | `inventory/barcodes/scan` | `inventory:barcode:scan` | 260 | 非表示ルート（is_visible=FALSE） |
| 340 | `BTN-INVENTORY-BARCODE-PRINT` | print | 3 按钮 | `inventory` | `SCR-INV-026` | — | `inventory:barcode:print` | 1 |  |
| 341 | `DIR-PRD` | 生产管理 | 1 目录 | `production` | —（ルート） | `production` | — | 60 | 目录 |
| 342 | `BTN-PRODUCTION-PARAM-UPDATE` | update | 3 按钮 | `production` | `DIR-PRD` | — | `production:param:update` | 1 | 対応画面なし（ディレクトリ直下） |
| 343 | `SCR-PRD-001` | BOM 一覧 | 2 菜单 | `production` | `DIR-PRD` | `production/boms` | `production:bom:view` | 10 |  |
| 344 | `BTN-PRODUCTION-BOM-APPROVE` | approve | 3 按钮 | `production` | `SCR-PRD-001` | — | `production:bom:approve` | 1 |  |
| 345 | `BTN-PRODUCTION-BOM-CREATE` | create | 3 按钮 | `production` | `SCR-PRD-001` | — | `production:bom:create` | 2 |  |
| 346 | `SCR-PRD-002` | BOM 登録編集 | 2 菜单 | `production` | `DIR-PRD` | `production/boms/new` | `production:bom:update` | 20 | 非表示ルート（is_visible=FALSE） |
| 347 | `SCR-PRD-003` | BOM 多阶展开・成本卷算 | 2 菜单 | `production` | `DIR-PRD` | `production/boms/:id` | `production:bom:view` | 30 | 非表示ルート（is_visible=FALSE） |
| 348 | `SCR-PRD-004` | 工艺路线一覧 | 2 菜单 | `production` | `DIR-PRD` | `production/routings` | `production:routing:view` | 40 |  |
| 349 | `BTN-PRODUCTION-ROUTING-CREATE` | create | 3 按钮 | `production` | `SCR-PRD-004` | — | `production:routing:create` | 1 |  |
| 350 | `SCR-PRD-005` | 工艺路线登録編集 | 2 菜单 | `production` | `DIR-PRD` | `production/routings/new` | `production:routing:update` | 50 | 非表示ルート（is_visible=FALSE） |
| 351 | `SCR-PRD-006` | 工作中心一覧・編集 | 2 菜单 | `production` | `DIR-PRD` | `production/work-centers` | `production:work-center:view` | 60 |  |
| 352 | `SCR-PRD-007` | 工作日历・产能设定 | 2 菜单 | `production` | `DIR-PRD` | `production/work-calendars` | `production:work-center:update` | 70 | 非表示ルート（is_visible=FALSE） |
| 353 | `SCR-PRD-008` | 生产订单一覧 | 2 菜单 | `production` | `DIR-PRD` | `production/work-orders` | `production:work-order:view` | 80 |  |
| 354 | `BTN-PRODUCTION-WORK-ORDER-APPROVE` | approve | 3 按钮 | `production` | `SCR-PRD-008` | — | `production:work-order:approve` | 1 |  |
| 355 | `BTN-PRODUCTION-WORK-ORDER-CANCEL` | cancel | 3 按钮 | `production` | `SCR-PRD-008` | — | `production:work-order:cancel` | 2 |  |
| 356 | `BTN-PRODUCTION-WORK-ORDER-CLOSE` | close | 3 按钮 | `production` | `SCR-PRD-008` | — | `production:work-order:close` | 3 |  |
| 357 | `BTN-PRODUCTION-WORK-ORDER-COST-VIEW` | cost-view | 3 按钮 | `production` | `SCR-PRD-008` | — | `production:work-order:cost-view` | 4 |  |
| 358 | `BTN-PRODUCTION-WORK-ORDER-SUBMIT` | submit | 3 按钮 | `production` | `SCR-PRD-008` | — | `production:work-order:submit` | 5 |  |
| 359 | `BTN-PRODUCTION-WORK-ORDER-UPDATE` | update | 3 按钮 | `production` | `SCR-PRD-008` | — | `production:work-order:update` | 6 |  |
| 360 | `SCR-PRD-009` | 生产订单登録編集 | 2 菜单 | `production` | `DIR-PRD` | `production/work-orders/new` | `production:work-order:create` | 90 | 非表示ルート（is_visible=FALSE） |
| 361 | `SCR-PRD-010` | 生产订单詳細（工序/用料/报工/入库标签） | 2 菜单 | `production` | `DIR-PRD` | `production/work-orders/:id` | `production:work-order:view` | 100 | 非表示ルート（is_visible=FALSE） |
| 362 | `SCR-PRD-011` | 生产订单下达・拆分・合并 | 2 菜单 | `production` | `DIR-PRD` | `production/work-orders/release` | `production:work-order:release` | 110 | 非表示ルート（is_visible=FALSE） |
| 363 | `SCR-PRD-012` | 生产领料单登録編集 | 2 菜单 | `production` | `DIR-PRD` | `production/material-issues/new` | `production:material-issue:create` | 120 | 非表示ルート（is_visible=FALSE） |
| 364 | `BTN-PRODUCTION-MATERIAL-ISSUE-APPROVE` | approve | 3 按钮 | `production` | `SCR-PRD-012` | — | `production:material-issue:approve` | 1 |  |
| 365 | `BTN-PRODUCTION-MATERIAL-ISSUE-REVERSE` | reverse | 3 按钮 | `production` | `SCR-PRD-012` | — | `production:material-issue:reverse` | 2 |  |
| 366 | `SCR-PRD-013` | 领退料一覧 | 2 菜单 | `production` | `DIR-PRD` | `production/material-issues` | `production:material-issue:view` | 130 |  |
| 367 | `SCR-PRD-014` | 工序报工登録（现场/扫码） | 2 菜单 | `production` | `DIR-PRD` | `production/work-reports/new` | `production:work-report:create` | 140 | 非表示ルート（is_visible=FALSE） |
| 368 | `BTN-PRODUCTION-WORK-REPORT-APPROVE` | approve | 3 按钮 | `production` | `SCR-PRD-014` | — | `production:work-report:approve` | 1 |  |
| 369 | `SCR-PRD-015` | 报工一覧・审核 | 2 菜单 | `production` | `DIR-PRD` | `production/work-reports` | `production:work-report:view` | 150 |  |
| 370 | `SCR-PRD-016` | 生产入库登録 | 2 菜单 | `production` | `DIR-PRD` | `production/completions/new` | `production:completion:create` | 160 | 非表示ルート（is_visible=FALSE） |
| 371 | `BTN-PRODUCTION-COMPLETION-VIEW` | view | 3 按钮 | `production` | `SCR-PRD-016` | — | `production:completion:view` | 1 |  |
| 372 | `SCR-PRD-017` | 委外订单一覧 | 2 菜单 | `production` | `DIR-PRD` | `production/outsourcings` | `production:outsourcing:view` | 170 |  |
| 373 | `BTN-PRODUCTION-OUTSOURCING-APPROVE` | approve | 3 按钮 | `production` | `SCR-PRD-017` | — | `production:outsourcing:approve` | 1 |  |
| 374 | `SCR-PRD-018` | 委外订单登録編集 | 2 菜单 | `production` | `DIR-PRD` | `production/outsourcings/new` | `production:outsourcing:create` | 180 | 非表示ルート（is_visible=FALSE） |
| 375 | `SCR-PRD-019` | 委外发料・收货登録 | 2 菜单 | `production` | `DIR-PRD` | `production/outsourcings/osi-osr/new` | `production:outsourcing:create` | 190 | 非表示ルート（is_visible=FALSE） |
| 376 | `SCR-PRD-020` | 委外加工费结算 | 2 菜单 | `production` | `DIR-PRD` | `production/outsourcings/:id/settle` | `production:outsourcing:settle` | 200 | 非表示ルート（is_visible=FALSE） |
| 377 | `SCR-PRD-021` | MRP 运行向导 | 2 菜单 | `production` | `DIR-PRD` | `production/mrps` | `production:mrp:run` | 210 |  |
| 378 | `SCR-PRD-022` | MRP 结果（需求/净需求/计划订单/动作消息） | 2 菜单 | `production` | `DIR-PRD` | `production/mrps/view` | `production:mrp:view` | 220 | 非表示ルート（is_visible=FALSE） |
| 379 | `SCR-PRD-023` | 计划订单确认・转工单/请购 | 2 菜单 | `production` | `DIR-PRD` | `production/mrps/confirm` | `production:mrp:confirm` | 230 | 非表示ルート（is_visible=FALSE） |
| 380 | `SCR-PRD-024` | MPS・排产（粗能力） | 2 菜单 | `production` | `DIR-PRD` | `production/plans` | `production:plan:update` | 240 |  |
| 381 | `BTN-PRODUCTION-PLAN-APPROVE` | approve | 3 按钮 | `production` | `SCR-PRD-024` | — | `production:plan:approve` | 1 |  |
| 382 | `BTN-PRODUCTION-PLAN-VIEW` | view | 3 按钮 | `production` | `SCR-PRD-024` | — | `production:plan:view` | 2 |  |
| 383 | `SCR-PRD-025` | 检验标准一覧・編集 | 2 菜单 | `production` | `DIR-PRD` | `production/inspection-standards` | `production:inspection-standard:update` | 250 |  |
| 384 | `BTN-PRODUCTION-INSPECTION-STANDARD-VIEW` | view | 3 按钮 | `production` | `SCR-PRD-025` | — | `production:inspection-standard:view` | 1 |  |
| 385 | `SCR-PRD-026` | 检验单登録（IQC/IPQC/FQC/OQC） | 2 菜单 | `production` | `DIR-PRD` | `production/inspections` | `production:inspection:create` | 260 |  |
| 386 | `SCR-PRD-027` | 检验一覧・判定 | 2 菜单 | `production` | `DIR-PRD` | `production/inspections/view` | `production:inspection:view` | 270 |  |
| 387 | `SCR-PRD-028` | NCR 登録・处置 | 2 菜单 | `production` | `DIR-PRD` | `production/ncrs/new` | `production:ncr:create` | 280 | 非表示ルート（is_visible=FALSE） |
| 388 | `BTN-PRODUCTION-NCR-APPROVE` | approve | 3 按钮 | `production` | `SCR-PRD-028` | — | `production:ncr:approve` | 1 |  |
| 389 | `BTN-PRODUCTION-NCR-VIEW` | view | 3 按钮 | `production` | `SCR-PRD-028` | — | `production:ncr:view` | 2 |  |
| 390 | `SCR-PRD-029` | 质量追溯查询 | 2 菜单 | `production` | `DIR-PRD` | `production/traces` | `production:trace:view` | 290 |  |
| 391 | `SCR-PRD-030` | 生产进度看板 | 2 菜单 | `production` | `DIR-PRD` | `production/dashboards` | `production:dashboard:view` | 300 |  |
| 392 | `SCR-PRD-031` | 工时・效率统计 | 2 菜单 | `production` | `DIR-PRD` | `production/reports` | `production:report:view` | 310 |  |
| 393 | `BTN-PRODUCTION-REPORT-EXPORT` | export | 3 按钮 | `production` | `SCR-PRD-031` | — | `production:report:export` | 1 |  |
| 394 | `SCR-PRD-032` | 设备台账 | 2 菜单 | `production` | `DIR-PRD` | `production/equipments` | `production:equipment:view` | 320 |  |
| 395 | `BTN-PRODUCTION-EQUIPMENT-UPDATE` | update | 3 按钮 | `production` | `SCR-PRD-032` | — | `production:equipment:update` | 1 |  |
| 396 | `SCR-PRD-033` | 生产报表 | 2 菜单 | `production` | `DIR-PRD` | `production/reports/view` | `production:report:view` | 330 |  |
| 397 | `SCR-PRD-034` | 超产申请一覧 | 2 菜单 | `production` | `DIR-PRD` | `production/overproduction-approvals` | `production:overproduction-approval:view` | 340 | G-11。後続増分迁移で投入 |
| 398 | `BTN-PRODUCTION-OVERPRODUCTION-APPROVAL-APPROVE` | approve | 3 按钮 | `production` | `SCR-PRD-034` | — | `production:overproduction-approval:approve` | 1 | approve・reject 共用（G-11）。後続増分迁移で投入 |
| 399 | `BTN-PRODUCTION-OVERPRODUCTION-APPROVAL-CANCEL` | cancel | 3 按钮 | `production` | `SCR-PRD-034` | — | `production:overproduction-approval:cancel` | 2 | 後続増分迁移で投入 |
| 400 | `BTN-PRODUCTION-OVERPRODUCTION-APPROVAL-CREATE` | create | 3 按钮 | `production` | `SCR-PRD-034` | — | `production:overproduction-approval:create` | 3 | 後続増分迁移で投入 |
| 401 | `BTN-PRODUCTION-OVERPRODUCTION-APPROVAL-SUBMIT` | submit | 3 按钮 | `production` | `SCR-PRD-034` | — | `production:overproduction-approval:submit` | 4 | 後続増分迁移で投入 |
| 402 | `DIR-FIN` | 财务管理 | 1 目录 | `finance` | —（ルート） | `finance` | — | 70 | 目录 |
| 403 | `SCR-FIN-001` | 会计科目一覧 | 2 菜单 | `finance` | `DIR-FIN` | `finance/accounts` | `finance:account:view` | 10 | 非表示ルート（is_visible=FALSE） |
| 404 | `SCR-FIN-002` | 会计科目登録編集 | 2 菜单 | `finance` | `DIR-FIN` | `finance/accounts/new` | `finance:account:create` | 20 | 非表示ルート（is_visible=FALSE） |
| 405 | `SCR-FIN-003` | 期初余额录入 | 2 菜单 | `finance` | `DIR-FIN` | `finance/opening-balances` | `finance:opening-balance:import` | 30 | 非表示ルート（is_visible=FALSE） |
| 406 | `SCR-FIN-004` | 科目辅助核算设置 | 2 菜单 | `finance` | `DIR-FIN` | `finance/accounts/:id/aux` | `finance:account:update` | 40 | 非表示ルート（is_visible=FALSE） |
| 407 | `SCR-FIN-005` | 记账凭证录入 | 2 菜单 | `finance` | `DIR-FIN` | `finance/vouchers/new` | `finance:voucher:create` | 50 | 非表示ルート（is_visible=FALSE） |
| 408 | `BTN-FINANCE-VOUCHER-EXPORT` | export | 3 按钮 | `finance` | `SCR-FIN-005` | — | `finance:voucher:export` | 1 |  |
| 409 | `BTN-FINANCE-VOUCHER-PRINT` | print | 3 按钮 | `finance` | `SCR-FIN-005` | — | `finance:voucher:print` | 2 |  |
| 410 | `BTN-FINANCE-VOUCHER-SUBMIT` | submit | 3 按钮 | `finance` | `SCR-FIN-005` | — | `finance:voucher:submit` | 3 |  |
| 411 | `BTN-FINANCE-VOUCHER-UPDATE` | update | 3 按钮 | `finance` | `SCR-FIN-005` | — | `finance:voucher:update` | 4 |  |
| 412 | `SCR-FIN-006` | 凭证一覧 | 2 菜单 | `finance` | `DIR-FIN` | `finance/vouchers` | `finance:voucher:view` | 60 |  |
| 413 | `SCR-FIN-007` | 凭证模板管理 | 2 菜单 | `finance` | `DIR-FIN` | `finance/voucher-templates` | `finance:voucher-template:view` | 70 | 非表示ルート（is_visible=FALSE） |
| 414 | `BTN-FINANCE-VOUCHER-TEMPLATE-UPDATE` | update | 3 按钮 | `finance` | `SCR-FIN-007` | — | `finance:voucher-template:update` | 1 |  |
| 415 | `SCR-FIN-008` | 凭证待审核一覧 | 2 菜单 | `finance` | `DIR-FIN` | `finance/vouchers/approve` | `finance:voucher:approve` | 80 |  |
| 416 | `SCR-FIN-009` | 凭证审核详细 | 2 菜单 | `finance` | `DIR-FIN` | `finance/vouchers/:id` | `finance:voucher:approve` | 90 | 非表示ルート（is_visible=FALSE） |
| 417 | `SCR-FIN-010` | 凭证记账处理 | 2 菜单 | `finance` | `DIR-FIN` | `finance/vouchers/post` | `finance:voucher:post` | 100 |  |
| 418 | `SCR-FIN-011` | 凭证反记账 | 2 菜单 | `finance` | `DIR-FIN` | `finance/vouchers/unpost` | `finance:voucher:unpost` | 110 |  |
| 419 | `SCR-FIN-012` | 红字冲销凭证 | 2 菜单 | `finance` | `DIR-FIN` | `finance/vouchers/:id/reverse` | `finance:voucher:reverse` | 120 | 非表示ルート（is_visible=FALSE） |
| 420 | `SCR-FIN-013` | 凭证查询与附件 | 2 菜单 | `finance` | `DIR-FIN` | `finance/vouchers/view` | `finance:voucher:view` | 130 |  |
| 421 | `SCR-FIN-014` | 总账查询 | 2 菜单 | `finance` | `DIR-FIN` | `finance/ledgers` | `finance:ledger:view` | 140 |  |
| 422 | `SCR-FIN-015` | 明细账查询 | 2 菜单 | `finance` | `DIR-FIN` | `finance/ledgers/view` | `finance:ledger:view` | 150 | 非表示ルート（is_visible=FALSE） |
| 423 | `SCR-FIN-016` | 序时账（日记账） | 2 菜单 | `finance` | `DIR-FIN` | `finance/ledgers/view/scr-fin-016` | `finance:ledger:view` | 160 |  |
| 424 | `SCR-FIN-017` | 试算平衡表 | 2 菜单 | `finance` | `DIR-FIN` | `finance/trial-balances` | `finance:trial-balance:view` | 170 |  |
| 425 | `SCR-FIN-018` | 应付单一覧 | 2 菜单 | `finance` | `DIR-FIN` | `finance/payables` | `finance:payable:view` | 180 |  |
| 426 | `SCR-FIN-019` | 应付单确认/详细 | 2 菜单 | `finance` | `DIR-FIN` | `finance/payables/:id` | `finance:payable:update` | 190 | 非表示ルート（is_visible=FALSE） |
| 427 | `SCR-FIN-020` | 采购发票三单匹配 | 2 菜单 | `finance` | `DIR-FIN` | `finance/invoices` | `finance:invoice:match` | 200 |  |
| 428 | `BTN-FINANCE-INVOICE-UPDATE` | update | 3 按钮 | `finance` | `SCR-FIN-020` | — | `finance:invoice:update` | 1 |  |
| 429 | `SCR-FIN-021` | 暂估余额与冲回 | 2 菜单 | `finance` | `DIR-FIN` | `finance/payables/view` | `finance:payable:view` | 210 |  |
| 430 | `SCR-FIN-022` | 付款申请 | 2 菜单 | `finance` | `DIR-FIN` | `finance/payment-requests` | `finance:payment-request:create` | 220 |  |
| 431 | `BTN-FINANCE-PAYMENT-REQUEST-APPROVE` | approve | 3 按钮 | `finance` | `SCR-FIN-022` | — | `finance:payment-request:approve` | 1 |  |
| 432 | `BTN-FINANCE-PAYMENT-REQUEST-VIEW` | view | 3 按钮 | `finance` | `SCR-FIN-022` | — | `finance:payment-request:view` | 2 |  |
| 433 | `SCR-FIN-023` | 付款执行 | 2 菜单 | `finance` | `DIR-FIN` | `finance/payments/execute` | `finance:payment:execute` | 230 | 非表示ルート（is_visible=FALSE） |
| 434 | `BTN-FINANCE-PAYMENT-VIEW` | view | 3 按钮 | `finance` | `SCR-FIN-023` | — | `finance:payment:view` | 1 |  |
| 435 | `SCR-FIN-024` | 应付核销 | 2 菜单 | `finance` | `DIR-FIN` | `finance/write-offs` | `finance:write-off:create` | 240 |  |
| 436 | `BTN-FINANCE-WRITE-OFF-REVERSE` | reverse | 3 按钮 | `finance` | `SCR-FIN-024` | — | `finance:write-off:reverse` | 1 |  |
| 437 | `SCR-FIN-025` | 应付账龄分析 | 2 菜单 | `finance` | `DIR-FIN` | `finance/agings` | `finance:aging:view` | 250 |  |
| 438 | `SCR-FIN-026` | 应收单一覧 | 2 菜单 | `finance` | `DIR-FIN` | `finance/receivables` | `finance:receivable:view` | 260 |  |
| 439 | `BTN-FINANCE-RECEIVABLE-CANCEL` | cancel | 3 按钮 | `finance` | `SCR-FIN-026` | — | `finance:receivable:cancel` | 1 |  |
| 440 | `BTN-FINANCE-RECEIVABLE-CONFIRM` | confirm | 3 按钮 | `finance` | `SCR-FIN-026` | — | `finance:receivable:confirm` | 2 |  |
| 441 | `BTN-FINANCE-RECEIVABLE-CREATE` | create | 3 按钮 | `finance` | `SCR-FIN-026` | — | `finance:receivable:create` | 3 |  |
| 442 | `SCR-FIN-027` | 收款登记 | 2 菜单 | `finance` | `DIR-FIN` | `finance/receipts` | `finance:receipt:create` | 270 |  |
| 443 | `BTN-FINANCE-RECEIPT-CONFIRM` | confirm | 3 按钮 | `finance` | `SCR-FIN-027` | — | `finance:receipt:confirm` | 1 |  |
| 444 | `BTN-FINANCE-RECEIPT-REVERSE` | reverse | 3 按钮 | `finance` | `SCR-FIN-027` | — | `finance:receipt:reverse` | 2 |  |
| 445 | `BTN-FINANCE-RECEIPT-VIEW` | view | 3 按钮 | `finance` | `SCR-FIN-027` | — | `finance:receipt:view` | 3 |  |
| 446 | `SCR-FIN-028` | 应收核销 | 2 菜单 | `finance` | `DIR-FIN` | `finance/write-offs/receivables` | `finance:write-off:create` | 280 | 非表示ルート（is_visible=FALSE） |
| 447 | `SCR-FIN-029` | 应收账龄分析 | 2 菜单 | `finance` | `DIR-FIN` | `finance/agings/view` | `finance:aging:view` | 290 |  |
| 448 | `SCR-FIN-030` | 坏账准备计提（P2） | 2 菜单 | `finance` | `DIR-FIN` | `finance/receivables/update` | `finance:receivable:update` | 300 | 非表示ルート（is_visible=FALSE） |
| 449 | `SCR-FIN-031` | 现金日记账 | 2 菜单 | `finance` | `DIR-FIN` | `finance/cash-journals` | `finance:cash-journal:view` | 310 |  |
| 450 | `BTN-FINANCE-CASH-JOURNAL-CREATE` | create | 3 按钮 | `finance` | `SCR-FIN-031` | — | `finance:cash-journal:create` | 1 |  |
| 451 | `SCR-FIN-032` | 银行日记账 | 2 菜单 | `finance` | `DIR-FIN` | `finance/bank-journals` | `finance:bank-journal:view` | 320 |  |
| 452 | `SCR-FIN-033` | 银行对账单导入 | 2 菜单 | `finance` | `DIR-FIN` | `finance/bank-statements/import` | `finance:bank-statement:import` | 330 | 非表示ルート（is_visible=FALSE） |
| 453 | `SCR-FIN-034` | 银行对账 | 2 菜单 | `finance` | `DIR-FIN` | `finance/bank-recons` | `finance:bank-recon:execute` | 340 | 非表示ルート（is_visible=FALSE） |
| 454 | `BTN-FINANCE-BANK-RECON-ADJUST` | adjust | 3 按钮 | `finance` | `SCR-FIN-034` | — | `finance:bank-recon:adjust` | 1 |  |
| 455 | `SCR-FIN-035` | 余额调节表 | 2 菜单 | `finance` | `DIR-FIN` | `finance/bank-recons/view` | `finance:bank-recon:view` | 350 | 非表示ルート（is_visible=FALSE） |
| 456 | `SCR-FIN-036` | 资金日报 | 2 菜单 | `finance` | `DIR-FIN` | `finance/fund-reports` | `finance:fund-report:view` | 360 |  |
| 457 | `SCR-FIN-037` | 进项发票台账 | 2 菜单 | `finance` | `DIR-FIN` | `finance/invoices/view` | `finance:invoice:view` | 370 |  |
| 458 | `SCR-FIN-038` | 销项发票台账 | 2 菜单 | `finance` | `DIR-FIN` | `finance/invoices/view/scr-fin-038` | `finance:invoice:view` | 380 |  |
| 459 | `SCR-FIN-039` | 增值税申报辅助表 | 2 菜单 | `finance` | `DIR-FIN` | `finance/vat-returns` | `finance:vat-return:view` | 390 |  |
| 460 | `BTN-FINANCE-VAT-RETURN-EXPORT` | export | 3 按钮 | `finance` | `SCR-FIN-039` | — | `finance:vat-return:export` | 1 |  |
| 461 | `BTN-FINANCE-VAT-RETURN-GENERATE` | generate | 3 按钮 | `finance` | `SCR-FIN-039` | — | `finance:vat-return:generate` | 2 |  |
| 462 | `SCR-FIN-040` | 附加税/所得税计提 | 2 菜单 | `finance` | `DIR-FIN` | `finance/tax-accruals` | `finance:tax-accrual:generate` | 400 |  |
| 463 | `BTN-FINANCE-TAX-ACCRUAL-VIEW` | view | 3 按钮 | `finance` | `SCR-FIN-040` | — | `finance:tax-accrual:view` | 1 |  |
| 464 | `SCR-FIN-041` | 自动凭证规则管理 | 2 菜单 | `finance` | `DIR-FIN` | `finance/auto-vouchers` | `finance:auto-voucher:view` | 410 | 非表示ルート（is_visible=FALSE） |
| 465 | `BTN-FINANCE-AUTO-VOUCHER-RETRY` | retry | 3 按钮 | `finance` | `SCR-FIN-041` | — | `finance:auto-voucher:retry` | 1 |  |
| 466 | `BTN-FINANCE-AUTO-VOUCHER-UPDATE` | update | 3 按钮 | `finance` | `SCR-FIN-041` | — | `finance:auto-voucher:update` | 2 |  |
| 467 | `SCR-FIN-042` | 自动凭证监控 | 2 菜单 | `finance` | `DIR-FIN` | `finance/auto-vouchers/view` | `finance:auto-voucher:view` | 420 |  |
| 468 | `SCR-FIN-043` | 成本计算 | 2 菜单 | `finance` | `DIR-FIN` | `finance/costs` | `finance:cost:calculate` | 430 |  |
| 469 | `BTN-FINANCE-COST-CONFIRM` | confirm | 3 按钮 | `finance` | `SCR-FIN-043` | — | `finance:cost:confirm` | 1 |  |
| 470 | `SCR-FIN-044` | 成本计算结果 | 2 菜单 | `finance` | `DIR-FIN` | `finance/costs/:id` | `finance:cost:view` | 440 | 非表示ルート（is_visible=FALSE） |
| 471 | `SCR-FIN-045` | 制造费用归集与分配 | 2 菜单 | `finance` | `DIR-FIN` | `finance/costs/calculate` | `finance:cost:calculate` | 450 |  |
| 472 | `SCR-FIN-046` | 在制品与完工成本 | 2 菜单 | `finance` | `DIR-FIN` | `finance/costs/view` | `finance:cost:view` | 460 |  |
| 473 | `SCR-FIN-047` | 成本差异分析 | 2 菜单 | `finance` | `DIR-FIN` | `finance/costs/view/scr-fin-047` | `finance:cost:view` | 470 |  |
| 474 | `SCR-FIN-048` | 会计期间管理 | 2 菜单 | `finance` | `DIR-FIN` | `finance/periods` | `finance:period:view` | 480 | 非表示ルート（is_visible=FALSE） |
| 475 | `BTN-FINANCE-PERIOD-REOPEN` | reopen | 3 按钮 | `finance` | `SCR-FIN-048` | — | `finance:period:reopen` | 1 |  |
| 476 | `SCR-FIN-049` | 月结向导 | 2 菜单 | `finance` | `DIR-FIN` | `finance/periods/close` | `finance:period:close` | 490 | 非表示ルート（is_visible=FALSE） |
| 477 | `SCR-FIN-050` | 损益结转 | 2 菜单 | `finance` | `DIR-FIN` | `finance/periods/closing` | `finance:period:close` | 500 | 非表示ルート（is_visible=FALSE） |
| 478 | `SCR-FIN-051` | 年度结转 | 2 菜单 | `finance` | `DIR-FIN` | `finance/year-closes/execute` | `finance:year-close:execute` | 510 | 非表示ルート（is_visible=FALSE） |
| 479 | `SCR-FIN-052` | 财务报表（三表） | 2 菜单 | `finance` | `DIR-FIN` | `finance/statements` | `finance:statement:view` | 520 |  |
| 480 | `BTN-FINANCE-STATEMENT-EXPORT` | export | 3 按钮 | `finance` | `SCR-FIN-052` | — | `finance:statement:export` | 1 |  |
| 481 | `BTN-FINANCE-STATEMENT-PRINT` | print | 3 按钮 | `finance` | `SCR-FIN-052` | — | `finance:statement:print` | 2 |  |
| 482 | `SCR-FIN-053` | 科目余额表 | 2 菜单 | `finance` | `DIR-FIN` | `finance/reports` | `finance:report:view` | 530 |  |
| 483 | `BTN-FINANCE-REPORT-EXPORT` | export | 3 按钮 | `finance` | `SCR-FIN-053` | — | `finance:report:export` | 1 |  |
| 484 | `BTN-FINANCE-REPORT-PRINT` | print | 3 按钮 | `finance` | `SCR-FIN-053` | — | `finance:report:print` | 2 |  |
| 485 | `SCR-FIN-054` | 费用报销（P2） | 2 菜单 | `finance` | `DIR-FIN` | `finance/expenses` | `finance:expense:create` | 540 |  |
| 486 | `BTN-FINANCE-EXPENSE-VIEW` | view | 3 按钮 | `finance` | `SCR-FIN-054` | — | `finance:expense:view` | 1 |  |
| 487 | `SCR-FIN-055` | 借款/还款（P2） | 2 菜单 | `finance` | `DIR-FIN` | `finance/expenses/create` | `finance:expense:create` | 550 |  |
| 488 | `SCR-FIN-056` | 固定资产卡片（P2） | 2 菜单 | `finance` | `DIR-FIN` | `finance/assets` | `finance:asset:view` | 560 |  |
| 489 | `BTN-FINANCE-ASSET-UPDATE` | update | 3 按钮 | `finance` | `SCR-FIN-056` | — | `finance:asset:update` | 1 |  |
| 490 | `SCR-FIN-057` | 固定资产处置（P2） | 2 菜单 | `finance` | `DIR-FIN` | `finance/assets/disposal` | `finance:asset:dispose` | 570 | 非表示ルート（is_visible=FALSE） |
| 491 | `SCR-FIN-058` | 预算管理（P2） | 2 菜单 | `finance` | `DIR-FIN` | `finance/budgets` | `finance:budget:update` | 580 |  |
| 492 | `BTN-FINANCE-BUDGET-VIEW` | view | 3 按钮 | `finance` | `SCR-FIN-058` | — | `finance:budget:view` | 1 |  |
| 493 | `SCR-FIN-059` | 汇兑损益调整（P2） | 2 菜单 | `finance` | `DIR-FIN` | `finance/vouchers/create` | `finance:voucher:create` | 590 |  |
| 494 | `SCR-FIN-060` | 资金计划与付款排程（P2） | 2 菜单 | `finance` | `DIR-FIN` | `finance/fund-reports/view` | `finance:fund-report:view` | 600 |  |
| 495 | `SCR-FIN-061` | 财务报表分析（P2） | 2 菜单 | `finance` | `DIR-FIN` | `finance/statements/view` | `finance:statement:view` | 610 | 非表示ルート（is_visible=FALSE） |
| 496 | `SCR-FIN-062` | 標準原価メンテナンス | 2 菜单 | `finance` | `DIR-FIN` | `finance/standard-costs` | `finance:standard-cost:view` | 620 | 非表示ルート（is_visible=FALSE） |
| 497 | `BTN-FINANCE-STANDARD-COST-PUBLISH` | publish | 3 按钮 | `finance` | `SCR-FIN-062` | — | `finance:standard-cost:publish` | 1 |  |
| 498 | `BTN-FINANCE-STANDARD-COST-REGISTER` | register | 3 按钮 | `finance` | `SCR-FIN-062` | — | `finance:standard-cost:register` | 2 |  |
| 499 | `DIR-WF` | 工作流 | 1 目录 | `workflow` | —（ルート） | `workflow` | — | 80 | 目录 |
| 500 | `SCR-WF-001` | 流程模型一覧 | 2 菜单 | `workflow` | `DIR-WF` | `workflow/processes` | `workflow:process:view` | 10 |  |
| 501 | `BTN-WORKFLOW-PROCESS-DEPLOY` | deploy | 3 按钮 | `workflow` | `SCR-WF-001` | — | `workflow:process:deploy` | 1 |  |
| 502 | `SCR-WF-002` | 流程模型登録編集/デプロイ | 2 菜单 | `workflow` | `DIR-WF` | `workflow/processes/new` | `workflow:process:update` | 20 | 非表示ルート（is_visible=FALSE） |
| 503 | `SCR-WF-003` | 业务类型映射設定 | 2 菜单 | `workflow` | `DIR-WF` | `workflow/mappings` | `workflow:mapping:view` | 30 |  |
| 504 | `SCR-WF-004` | 承認マトリクス設定 | 2 菜单 | `workflow` | `DIR-WF` | `workflow/approval-matrices` | `workflow:mapping:update` | 40 | 非表示ルート（is_visible=FALSE） |
| 505 | `SCR-WF-005` | 审批发起（提出ダイアログ） | 2 菜单 | `workflow` | `DIR-WF` | `workflow/instances/submit` | `workflow:instance:submit` | 50 | 非表示ルート（is_visible=FALSE） |
| 506 | `BTN-WORKFLOW-INSTANCE-MANAGE` | manage | 3 按钮 | `workflow` | `SCR-WF-005` | — | `workflow:instance:manage` | 1 |  |
| 507 | `SCR-WF-006` | 待办一覧 | 2 菜单 | `workflow` | `DIR-WF` | `workflow/tasks` | `workflow:task:view` | 60 |  |
| 508 | `BTN-WORKFLOW-TASK-ADD-SIGN` | add-sign | 3 按钮 | `workflow` | `SCR-WF-006` | — | `workflow:task:add-sign` | 1 |  |
| 509 | `BTN-WORKFLOW-TASK-REJECT` | reject | 3 按钮 | `workflow` | `SCR-WF-006` | — | `workflow:task:reject` | 2 |  |
| 510 | `BTN-WORKFLOW-TASK-TRANSFER` | transfer | 3 按钮 | `workflow` | `SCR-WF-006` | — | `workflow:task:transfer` | 3 |  |
| 511 | `BTN-WORKFLOW-TASK-URGE` | urge | 3 按钮 | `workflow` | `SCR-WF-006` | — | `workflow:task:urge` | 4 |  |
| 512 | `BTN-WORKFLOW-TASK-WITHDRAW` | withdraw | 3 按钮 | `workflow` | `SCR-WF-006` | — | `workflow:task:withdraw` | 5 |  |
| 513 | `SCR-WF-007` | 承認画面 | 2 菜单 | `workflow` | `DIR-WF` | `workflow/tasks/approve` | `workflow:task:approve` | 70 | 非表示ルート（is_visible=FALSE） |
| 514 | `SCR-WF-008` | 已办一覧 | 2 菜单 | `workflow` | `DIR-WF` | `workflow/tasks/view` | `workflow:task:view` | 80 |  |
| 515 | `SCR-WF-009` | 我发起的 | 2 菜单 | `workflow` | `DIR-WF` | `workflow/tasks/view/scr-wf-009` | `workflow:task:view` | 90 |  |
| 516 | `SCR-WF-010` | 抄送我的 | 2 菜单 | `workflow` | `DIR-WF` | `workflow/tasks/view/scr-wf-010` | `workflow:task:view` | 100 |  |
| 517 | `SCR-WF-011` | 审批历史/流程追踪 | 2 菜单 | `workflow` | `DIR-WF` | `workflow/tasks/:id` | `workflow:task:view` | 110 | 非表示ルート（is_visible=FALSE） |
| 518 | `SCR-WF-012` | 代理委托设置 | 2 菜单 | `workflow` | `DIR-WF` | `workflow/delegations` | `workflow:delegation:update` | 120 |  |
| 519 | `BTN-WORKFLOW-DELEGATION-ADMIN` | admin | 3 按钮 | `workflow` | `SCR-WF-012` | — | `workflow:delegation:admin` | 1 |  |
| 520 | `SCR-WF-013` | 流程实例管理 | 2 菜单 | `workflow` | `DIR-WF` | `workflow/instances` | `workflow:instance:view` | 130 |  |
| 521 | `SCR-WF-014` | 超时规则与自动审批设置 | 2 菜单 | `workflow` | `DIR-WF` | `workflow/timeouts` | `workflow:timeout:update` | 140 |  |
| 522 | `SCR-WF-015` | 表单字段权限设置 | 2 菜单 | `workflow` | `DIR-WF` | `workflow/field-permissions` | `workflow:field-permission:update` | 150 | 非表示ルート（is_visible=FALSE） |
| 523 | `SCR-WF-016` | 流程监控看板 | 2 菜单 | `workflow` | `DIR-WF` | `workflow/monitors` | `workflow:monitor:view` | 160 |  |
| 524 | `DIR-INT` | 集成管理 | 1 目录 | `integration` | —（ルート） | `integration` | — | 90 | 目录 |
| 525 | `BTN-INTEGRATION-CREDENTIAL-UPDATE` | update | 3 按钮 | `integration` | `DIR-INT` | — | `integration:credential:update` | 1 | 対応画面なし（ディレクトリ直下） |
| 526 | `BTN-INTEGRATION-PDA-USE` | use | 3 按钮 | `integration` | `DIR-INT` | — | `integration:pda:use` | 2 | 対応画面なし（ディレクトリ直下） |
| 527 | `BTN-INTEGRATION-PO-SEND-SUBMIT` | submit | 3 按钮 | `integration` | `DIR-INT` | — | `integration:po-send:submit` | 3 | 対応画面なし（ディレクトリ直下） |
| 528 | `SCR-INT-001` | 接口配置一覧 | 2 菜单 | `integration` | `DIR-INT` | `integration/interface-configs` | `integration:interface-config:view` | 10 |  |
| 529 | `BTN-INTEGRATION-INTERFACE-CONFIG-DELETE` | delete | 3 按钮 | `integration` | `SCR-INT-001` | — | `integration:interface-config:delete` | 1 |  |
| 530 | `BTN-INTEGRATION-INTERFACE-CONFIG-DISABLE` | disable | 3 按钮 | `integration` | `SCR-INT-001` | — | `integration:interface-config:disable` | 2 |  |
| 531 | `BTN-INTEGRATION-INTERFACE-CONFIG-ENABLE` | enable | 3 按钮 | `integration` | `SCR-INT-001` | — | `integration:interface-config:enable` | 3 |  |
| 532 | `BTN-INTEGRATION-INTERFACE-CONFIG-UPDATE` | update | 3 按钮 | `integration` | `SCR-INT-001` | — | `integration:interface-config:update` | 4 |  |
| 533 | `SCR-INT-002` | 接口配置登録編集 | 2 菜单 | `integration` | `DIR-INT` | `integration/interface-configs/new` | `integration:interface-config:create` | 20 | 非表示ルート（is_visible=FALSE） |
| 534 | `SCR-INT-003` | 接続テスト/実行結果 | 2 菜单 | `integration` | `DIR-INT` | `integration/interface-configs/:id` | `integration:interface-config:test` | 30 | 非表示ルート（is_visible=FALSE） |
| 535 | `SCR-INT-004` | 同步監視ダッシュボード | 2 菜单 | `integration` | `DIR-INT` | `integration/sync-tasks` | `integration:sync-task:view` | 40 |  |
| 536 | `SCR-INT-005` | 同期タスク一覧（失敗・滞留） | 2 菜单 | `integration` | `DIR-INT` | `integration/sync-tasks/view` | `integration:sync-task:view` | 50 | 非表示ルート（is_visible=FALSE） |
| 537 | `SCR-INT-006` | 手動再送/再処理 | 2 菜单 | `integration` | `DIR-INT` | `integration/sync-tasks/retry` | `integration:sync-task:retry` | 60 | 非表示ルート（is_visible=FALSE） |
| 538 | `SCR-INT-007` | 接口呼出日志 | 2 菜单 | `integration` | `DIR-INT` | `integration/call-logs` | `integration:call-log:view` | 70 | 非表示ルート（is_visible=FALSE） |
| 539 | `BTN-INTEGRATION-CALL-LOG-EXPORT` | export | 3 按钮 | `integration` | `SCR-INT-007` | — | `integration:call-log:export` | 1 |  |
| 540 | `SCR-INT-008` | 数电票発行一覧 | 2 菜单 | `integration` | `DIR-INT` | `integration/tax-invoices` | `integration:tax-invoice:view` | 80 |  |
| 541 | `BTN-INTEGRATION-TAX-INVOICE-APPROVE` | approve | 3 按钮 | `integration` | `SCR-INT-008` | — | `integration:tax-invoice:approve` | 1 |  |
| 542 | `BTN-INTEGRATION-TAX-INVOICE-RED` | red | 3 按钮 | `integration` | `SCR-INT-008` | — | `integration:tax-invoice:red` | 2 |  |
| 543 | `BTN-INTEGRATION-TAX-INVOICE-REQUEST` | request | 3 按钮 | `integration` | `SCR-INT-008` | — | `integration:tax-invoice:request` | 3 |  |
| 544 | `SCR-INT-009` | 数电票詳細・赤伝 | 2 菜单 | `integration` | `DIR-INT` | `integration/tax-invoices/:id` | `integration:tax-invoice:create` | 90 | 非表示ルート（is_visible=FALSE） |
| 545 | `SCR-INT-010` | 進項発票査験一覧 | 2 菜单 | `integration` | `DIR-INT` | `integration/input-invoices` | `integration:input-invoice:view` | 100 |  |
| 546 | `BTN-INTEGRATION-INPUT-INVOICE-VERIFY` | verify | 3 按钮 | `integration` | `SCR-INT-010` | — | `integration:input-invoice:verify` | 1 |  |
| 547 | `SCR-INT-011` | 銀企口座残高一覧 | 2 菜单 | `integration` | `DIR-INT` | `integration/bank-accounts` | `integration:bank-account:view` | 110 |  |
| 548 | `SCR-INT-012` | 付款指令一覧 | 2 菜单 | `integration` | `DIR-INT` | `integration/bank-payments` | `integration:bank-payment:view` | 120 | 非表示ルート（is_visible=FALSE） |
| 549 | `BTN-INTEGRATION-BANK-PAYMENT-APPROVE` | approve | 3 按钮 | `integration` | `SCR-INT-012` | — | `integration:bank-payment:approve` | 1 |  |
| 550 | `BTN-INTEGRATION-BANK-PAYMENT-SUBMIT` | submit | 3 按钮 | `integration` | `SCR-INT-012` | — | `integration:bank-payment:submit` | 2 |  |
| 551 | `SCR-INT-013` | 付款指令詳細・回单 | 2 菜单 | `integration` | `DIR-INT` | `integration/bank-payments/:id` | `integration:bank-payment:create` | 130 | 非表示ルート（is_visible=FALSE） |
| 552 | `SCR-INT-014` | 銀行対账单取込 | 2 菜单 | `integration` | `DIR-INT` | `integration/bank-statements` | `integration:bank-statement:import` | 140 |  |
| 553 | `SCR-INT-015` | 対账单取込結果・FIN 引渡 | 2 菜单 | `integration` | `DIR-INT` | `integration/bank-statements/:id` | `integration:bank-statement:view` | 150 | 非表示ルート（is_visible=FALSE） |
| 554 | `SCR-INT-016` | MES/WMS 連携状況 | 2 菜单 | `integration` | `DIR-INT` | `integration/meses` | `integration:mes:view` | 160 |  |
| 555 | `BTN-INTEGRATION-MES-RECEIVE` | receive | 3 按钮 | `integration` | `SCR-INT-016` | — | `integration:mes:receive` | 1 |  |
| 556 | `BTN-INTEGRATION-MES-RETRY` | retry | 3 按钮 | `integration` | `SCR-INT-016` | — | `integration:mes:retry` | 2 |  |
| 557 | `SCR-INT-017` | PLM 同期状況 | 2 菜单 | `integration` | `DIR-INT` | `integration/plms` | `integration:plm:view` | 170 |  |
| 558 | `BTN-INTEGRATION-PLM-APPROVE` | approve | 3 按钮 | `integration` | `SCR-INT-017` | — | `integration:plm:approve` | 1 |  |
| 559 | `BTN-INTEGRATION-PLM-IMPORT` | import | 3 按钮 | `integration` | `SCR-INT-017` | — | `integration:plm:import` | 2 |  |
| 560 | `SCR-INT-018` | 開放 API クライアント管理 | 2 菜单 | `integration` | `DIR-INT` | `integration/api-clients` | `integration:api-client:view` | 180 |  |
| 561 | `BTN-INTEGRATION-API-CLIENT-CREATE` | create | 3 按钮 | `integration` | `SCR-INT-018` | — | `integration:api-client:create` | 1 |  |
| 562 | `BTN-INTEGRATION-API-CLIENT-UPDATE` | update | 3 按钮 | `integration` | `SCR-INT-018` | — | `integration:api-client:update` | 2 |  |
| 563 | `SCR-INT-019` | API 利用状況・レート制限 | 2 菜单 | `integration` | `DIR-INT` | `integration/api-clients/view` | `integration:api-client:view` | 190 | 非表示ルート（is_visible=FALSE） |
| 564 | `SCR-INT-020` | 外部ファイル取込ジョブ | 2 菜单 | `integration` | `DIR-INT` | `integration/file-transfers` | `integration:file-transfer:view` | 200 |  |
| 565 | `BTN-INTEGRATION-FILE-TRANSFER-IMPORT` | import | 3 按钮 | `integration` | `SCR-INT-020` | — | `integration:file-transfer:import` | 1 |  |
| 566 | `SCR-INT-021` | 通知チャネル設定 | 2 菜单 | `integration` | `DIR-INT` | `integration/notification-channels` | `integration:notification-channel:update` | 210 |  |
| 567 | `BTN-INTEGRATION-NOTIFICATION-CHANNEL-VIEW` | view | 3 按钮 | `integration` | `SCR-INT-021` | — | `integration:notification-channel:view` | 1 |  |
| 568 | `SCR-INT-022` | 通知送信履歴 | 2 菜单 | `integration` | `DIR-INT` | `integration/notification-logs` | `integration:notification-log:view` | 220 | 非表示ルート（is_visible=FALSE） |
| 569 | `SCR-INT-023` | PDA 端末管理 | 2 菜单 | `integration` | `DIR-INT` | `integration/pda-devices` | `integration:pda-device:view` | 230 |  |
| 570 | `BTN-INTEGRATION-PDA-DEVICE-UPDATE` | update | 3 按钮 | `integration` | `SCR-INT-023` | — | `integration:pda-device:update` | 1 |  |
| 571 | `SCR-INT-024` | 日次対账結果 | 2 菜单 | `integration` | `DIR-INT` | `integration/reconciles` | `integration:reconcile:view` | 240 | 非表示ルート（is_visible=FALSE） |
| 572 | `DIR-RPT` | 报表分析 | 1 目录 | `report` | —（ルート） | `report` | — | 100 | 目录 |
| 573 | `BTN-REPORT-AUDIT-VIEW` | view | 3 按钮 | `report` | `DIR-RPT` | — | `report:audit:view` | 1 | 対応画面なし（ディレクトリ直下） |
| 574 | `SCR-RPT-001` | 经营驾驶舱 | 2 菜单 | `report` | `DIR-RPT` | `report/dashboards` | `report:dashboard:view` | 10 |  |
| 575 | `SCR-RPT-002` | 驾驶舱布局设置 | 2 菜单 | `report` | `DIR-RPT` | `report/dashboards/layout` | `report:dashboard:update` | 20 | 非表示ルート（is_visible=FALSE） |
| 576 | `SCR-RPT-003` | 销售分析 | 2 菜单 | `report` | `DIR-RPT` | `report/saleses` | `report:sales:view` | 30 | 非表示ルート（is_visible=FALSE） |
| 577 | `SCR-RPT-004` | 采购分析 | 2 菜单 | `report` | `DIR-RPT` | `report/purchases` | `report:purchase:view` | 40 | 非表示ルート（is_visible=FALSE） |
| 578 | `SCR-RPT-005` | 生产分析 | 2 菜单 | `report` | `DIR-RPT` | `report/productions` | `report:production:view` | 50 | 非表示ルート（is_visible=FALSE） |
| 579 | `SCR-RPT-006` | 财务分析 | 2 菜单 | `report` | `DIR-RPT` | `report/finances` | `report:finance:view` | 60 | 非表示ルート（is_visible=FALSE） |
| 580 | `SCR-RPT-007` | 库存分析 | 2 菜单 | `report` | `DIR-RPT` | `report/inventories` | `report:inventory:view` | 70 | 非表示ルート（is_visible=FALSE） |
| 581 | `SCR-RPT-008` | KPI 一覧 | 2 菜单 | `report` | `DIR-RPT` | `report/kpis` | `report:kpi:view` | 80 |  |
| 582 | `SCR-RPT-009` | KPI 定义编辑 | 2 菜单 | `report` | `DIR-RPT` | `report/kpis/:id/edit` | `report:kpi:update` | 90 | 非表示ルート（is_visible=FALSE） |
| 583 | `SCR-RPT-010` | KPI 详情/趋势 | 2 菜单 | `report` | `DIR-RPT` | `report/kpis/:id` | `report:kpi:view` | 100 | 非表示ルート（is_visible=FALSE） |
| 584 | `SCR-RPT-011` | 预警中心 | 2 菜单 | `report` | `DIR-RPT` | `report/warnings` | `report:warning:view` | 110 |  |
| 585 | `SCR-RPT-012` | 预警规则编辑 | 2 菜单 | `report` | `DIR-RPT` | `report/warnings/:id/edit` | `report:warning:update` | 120 | 非表示ルート（is_visible=FALSE） |
| 586 | `SCR-RPT-013` | 预警历史 | 2 菜单 | `report` | `DIR-RPT` | `report/warnings/view` | `report:warning:view` | 130 | 非表示ルート（is_visible=FALSE） |
| 587 | `SCR-RPT-014` | 报表订阅一覧 | 2 菜单 | `report` | `DIR-RPT` | `report/subscriptions` | `report:subscription:view` | 140 |  |
| 588 | `SCR-RPT-015` | 订阅設定 | 2 菜单 | `report` | `DIR-RPT` | `report/subscriptions/settings` | `report:subscription:update` | 150 | 非表示ルート（is_visible=FALSE） |
| 589 | `SCR-RPT-016` | 分析明细/钻取 | 2 菜单 | `report` | `DIR-RPT` | `report/analysises` | `report:analysis:view` | 160 | 非表示ルート（is_visible=FALSE） |
| 590 | `SCR-RPT-017` | 分析导出/非同期ジョブ | 2 菜单 | `report` | `DIR-RPT` | `report/analysises/:id` | `report:analysis:export` | 170 | 非表示ルート（is_visible=FALSE） |
| 591 | `SCR-RPT-018` | 分析数据抽取监视 | 2 菜单 | `report` | `DIR-RPT` | `report/etls` | `report:etl:view` | 180 |  |
| 592 | `BTN-REPORT-ETL-RUN` | run | 3 按钮 | `report` | `SCR-RPT-018` | — | `report:etl:run` | 1 |  |
| 593 | `SCR-RPT-019` | 数据质量检查 | 2 菜单 | `report` | `DIR-RPT` | `report/qualities` | `report:quality:view` | 190 |  |
| 594 | `SCR-RPT-020` | 移动端/大屏（P2） | 2 菜单 | `report` | `DIR-RPT` | `report/dashboards/view` | `report:dashboard:view` | 200 | 非表示ルート（is_visible=FALSE） |

## 7. 改訂履歴

| 版数 | 日付 | 変更内容 | 変更者 |
|---|---|---|---|
| v1.0 | 2026-10-20 | 初版：実データと出典、初期データ 8 種、仮定値一覧、整合性ルール、未決 3 | system-workflow |
| v1.1 | 2026-10-20 | 90-data と整合：部門を D010〜D080 の 8 件に統一（D000 廃止）、ロールコードを `ROLE-*`、税・単位・通貨を 06-code-list の実データコードに統一、職位・担当者例を追加、未決 4 件 | system-workflow |
| v1.2 | 2026-10-20 | Lead 裁决反映：工厂主データを MDM（`mdm_factory`）へ移管。§2.2 を「MDM 主データ＋SYS 組織設定（`sys_factory_setting`）」に変更 | system-workflow |
| v1.3 | 2026-10-21 | 系统管理员のロールコードを `SYSTEM_ADMIN` に確定し未決 #2 を削除。§2.10 メニュー・権限・`SYSTEM_ADMIN` の種データ仕様（`sys_menu` は `company_id=0` のテナント単位、会社ごとに `SYSTEM_ADMIN` と全権限付与、テナント開設・会社登録・既存回填、冪等・上書き禁止、ギャップ G-1〜G-10）と付録 A（589 行、`route_path` は先頭スラッシュなし）を追加（蓝色大肥鱼 2026-10-21 決定） | 业务分析 |
| v1.4 | 2026-10-21 | #58 決定反映：`permission_code` の重複を許可し全菜单行に設定（付与 579 行）、判定はコードのみ・目录は付与対象外。`sys_init_tenant`（メニュー投入＋各社 `sys_init_company`）／`sys_init_company(p_tenant_id, p_company_id)`（`sys_param`＋`SYSTEM_ADMIN` 未作成時のみ作成・全付与、`erp_app` にも EXECUTE、テナント・会社の検査）の分担と pgTAP。`route_path` 規則（`/new` は新規登録のみ）と 32 画面の訂正。ギャップ G-1〜G-10 を解決済みに更新（蓝色大肥鱼 2026-10-21 決定） | 业务分析 |
| v1.5 | 2026-10-21 | 付録 A の `route_path` 20 件を訂正（子表・既存伝票操作は `<res>/:id/<子または操作>`、種別別新規は `<res>/<種別>/new`）、§2.10 (4) に規則を追記（蓝色大肥鱼 2026-10-21 承認） | 业务分析 |
| v1.6 | 2026-10-21 | §2.10 (4)：複数伝票種別を扱う画面の `route_path` は種別コードを 09 §7.1 の順にハイフン連結（`mii-mir`、`osi-osr`）と明記 | 业务分析 |
| v1.7 | 2026-10-21 | §2.10 (7) G-7 を改訂：`sys_menu.parent_id` に自己参照 FK を付けないことを明記（0＝ルート、親子はアプリ `MSG-SYS-021` と pgTAP で検査。#65、蓝色大肥鱼 2026-10-21 決定、案 A） | 业务分析 |
| v1.8 | 2026-10-21 | G-11 を追加：超産承認の菜单 `SCR-PRD-034` と按钮 4 行（`production:overproduction-approval:*`、reject は approve と共用）を付録 A #397〜#401 に追加し後続行を繰下げ（画面は 06 §5 SCR-PRD-034）。増分迁移の要件（既存 SYSTEM_ADMIN へ新 5 コードのみ一度付与・撤销済み付与は戻さない・新規会社は sys_init_company で取得、pgTAP で両方を断言）を明記。件数を 594 行／付与 584／異なるコード 518 に更新（V202610211405 は 589／579／513 のまま、5 行は後続の増分迁移で投入。蓝色大肥鱼 2026-10-21 決定） | 业务分析 |
