# 真实资料与样例数据 数据地图（データ地図）

| 項目 | 内容 |
|---|---|
| 文書名 | 真实资料与样例数据 数据地图（90-data データ地図） |
| 文書番号 | DSN-DAT-000 |
| 版数 | v1.0 |
| 作成日 | 2026-10-20 |
| 作成者 | data-researcher（真实资料与样例数据担当） |
| 承認者 | Lead（未承認・レビュー待ち） |
| 状態 | ドラフト（レビュー中） |
| 参照日 | 2026-10-20 |
| 関連文書 | [06 代码一览](../00-common/06-code-list.md) / [08 共通业务规则](../00-common/08-common-business-rules.md) / [09 跨域流程](../00-common/09-cross-domain-flow.md) / [sources.md](sources.md) |

> 本ディレクトリ（`docs/design/90-data/`）は、8 業務域の詳細設計が**共通で引用する実データ・サンプルデータ**の正本を置く。設計書本文は数值を再定義せず、本ディレクトリのファイルを参照する。**実データ（標準・法令・科目・コード）と示例値（架空の経営データ）を明確に区別**し、示例値は必ず【示例値】と表示する。

---

## 1. データ区分と表記ルール

| 分類 | 表記 | 定義 | 例 |
|---|---|---|---|
| 実データ | **【実データ】** | 国家標準・法令・税率・会計科目・行政区画・公開情報など、URL で検証できるデータ | GB/T 2521.1-2016、1122 应收账款、VAT13、320400 常州市 |
| 公開情報 | **【公開情報】** | 公開資料に基づく業界量級・企業公開情報（設計の妥当性確認用） | 電機業界の平均単価・上場企業名 |
| 示例値 | **【示例値】** | 企業内部の架空データ。設計検証のみに使用し、実在しない | 採購単価、標準工時、安全在庫、売価、信用限度額 |

ルール：

1. 実データ・公開情報には [sources.md](sources.md) の出典 ID（`S-xxx`）または標準号・文号を付す。
2. 示例値は CSV の `remark` 列または Markdown 本文に【示例値】と明記する。示例値を実データとして引用してはならない。
3. 企業名は公開情報のみ使用し、**「示例数据，仅用于设计验证，不代表任何商业关系」**を必ず併記する。連絡先・担当者名・口座番号・統一社会信用代码は記載しない。
4. 個人情報（氏名・電話・身分証・銀行口座）は一切含めない。銀行口座は脱敏示例のみ。
5. 未確定の標準・URL・税率は**【要確認】**と表示し、確定値として使用しない（[sources.md](sources.md) §6）。

---

## 2. ファイル一覧（データマップ）

> **データ規模（2026-10-20 実測）**：本ディレクトリは **24 ファイル・約 191KB**、CSV データ行 **483 行**、出典 **109 項**（sources.md）。件数は各ファイル末尾の実測値と一致させる（下記 §8 の未決参照）。

| # | ファイル | 文書番号 | 内容 | データ区分 | 主な利用域 |
|---|---|---|---|---|---|
| 1 | [demo-company.md](demo-company.md) | DSN-DAT-001 | 示例企業画像：組織・工場・倉庫・班制・カレンダー・会計政策・製品譜系 | 示例値＋実データ（標準・法令部分） | 全部 |
| 2 | [approval-matrix.md](approval-matrix.md) | DSN-DAT-002 | 承認マトリクス（08 §8.1 のデータシート） | 示例値（社内規程） | WF／全部 |
| 3 | [material-master.csv](material-master.csv) | DSN-DAT-003 | 物料マスタ（原材料・半成品・成品・外購件・包装・工装）54 件 | 実データ（標準・牌号）＋示例値（価格・在庫） | MDM／PUR／INV／PRD／SAL／FIN |
| 4 | [bom-demo.md](bom-demo.md) | DSN-DAT-004 | YE3-100L1-4 多階 BOM（親→子→孫、数量・損耗率・展開算例） | 実データ（材料標準）＋示例値（数量・損耗） | PRD／INV／FIN |
| 5 | [routing-demo.md](routing-demo.md) | DSN-DAT-005 | YE3-100L1-4 工程路線・工作中心・標準工時・検査項目 | 実データ（試験標準）＋示例値（工時・能力） | PRD／FIN |
| 6 | [customer-master.csv](customer-master.csv) | DSN-DAT-006 | 顧客マスタ（実在企業の公開情報・示例関係） | 公開情報＋示例値 | MDM／SAL／FIN |
| 7 | [supplier-master.csv](supplier-master.csv) | DSN-DAT-007 | 仕入先マスタ（実在企業の公開情報・示例関係） | 公開情報＋示例値 | MDM／PUR／FIN |
| 8 | [accounting-subjects.csv](accounting-subjects.csv) | DSN-DAT-008 | 会計科目マスタ（CAS 常用科目 108 行。2221 明細 30 行を含む） | 実データ | FIN／INV／PRD／PUR／SAL |
| 9 | [sources.md](sources.md) | DSN-DAT-009 | 全出典 109 項（標準・法令・コード・公開企業情報）URL＋参照日 | メタデータ | 全部 |
| 10 | [code-lists/currency.csv](code-lists/currency.csv) | DSN-DAT-010 | 通貨（ISO 4217／GB/T 12406-2022） | 実データ | MDM／FIN／SAL／PUR |
| 11 | [code-lists/country.csv](code-lists/country.csv) | DSN-DAT-011 | 国・地域（ISO 3166-1） | 実データ | MDM／SAL／PUR |
| 12 | [code-lists/region.csv](code-lists/region.csv) | DSN-DAT-012 | 行政区画（GB/T 2260-2007） | 実データ | MDM／SAL／PUR／FIN |
| 13 | [code-lists/uom.csv](code-lists/uom.csv) | DSN-DAT-013 | 計量単位（GB 3100-1993／UN-ECE Rec20。体積グループの基本単位は **MTQ**） | 実データ＋設計値 | MDM／INV／PRD |
| 14 | [code-lists/tax.csv](code-lists/tax.csv) | DSN-DAT-014 | 税目・税率（《增值税法》2026-01-01 施行／《关税法》2024-12-01 施行に基づく） | 実データ | MDM／FIN／SAL／PUR |
| 15 | [code-lists/payment-terms.csv](code-lists/payment-terms.csv) | DSN-DAT-015 | 決済方法・支払条件（MDM DDL 互換の `settlement_type`／`settlement_basis`／`payment_day_type` 列付き） | 設計値（示例値） | MDM／FIN／SAL／PUR |
| 16 | [code-lists/incoterms.csv](code-lists/incoterms.csv) | DSN-DAT-016 | Incoterms® 2020（11 規則） | 実データ | SAL（輸出）／PUR（輸入） |
| 17 | [code-lists/bank.csv](code-lists/bank.csv) | DSN-DAT-017 | 銀行行別コード（`bank_category` 付き）。CNAPS 12 桁の構成規則は 06 §11 を正とする | 実データ | MDM／FIN／INT |
| 18 | [code-lists/hs-code.csv](code-lists/hs-code.csv) | DSN-DAT-018 | HS コード（電機及部品・材料） | 実データ | SAL（輸出）／PUR（輸入）／FIN |
| 19 | [code-lists/material-category.csv](code-lists/material-category.csv) | DSN-DAT-019 | 物料分類（大类・中类 4 桁） | 設計値（06 §11 準拠） | MDM／INV／PRD／PUR |
| 20 | [code-lists/approval-matrix.csv](code-lists/approval-matrix.csv) | DSN-DAT-020 | 承認マトリクス（機械可読データ） | 示例値 | WF／全部 |
| 21 | [code-lists/batch-number-rule.csv](code-lists/batch-number-rule.csv) | DSN-DAT-021 | 批号・序列号採番規則（示例） | 示例値 | INV／PRD |
| 22 | [code-lists/warehouse-location.csv](code-lists/warehouse-location.csv) | DSN-DAT-022 | 倉庫・庫区・庫位（示例） | 示例値 | MDM／INV |
| 23 | [code-lists/mdm-tax-code.csv](code-lists/mdm-tax-code.csv) | DSN-DAT-023 | **業務税碼 24 件**（`VAT13-OUT/IN` 等。MDM `mdm_tax_code` の初期データ） | 実データ（税率）＋設計値（方向・税区分） | MDM／FIN／SAL／PUR |

> **正本の関係**：コード値は [06-code-list.md](../00-common/06-code-list.md) が設計上の要約、本ディレクトリの CSV が**全件データの正本**。両者が不一致の場合は CSV を正とし、06 を Lead 承認のうえ更新する。物料・BOM・工程路線は各 CSV/Markdown が正本。

---

## 3. CSV 共通仕様

| 項目 | 仕様 |
|---|---|
| 文字コード | **UTF-8**（BOM なし）。CRLF/LF は問わない |
| 区切り | カンマ（`,`）。値にカンマを含む場合はダブルクォートで囲む |
| ヘッダ | 1 行目は英小文字スネークケースの列名。列の意味は本 README §4・各ファイル先頭の説明による |
| 空欄 | 未設定・該当なしは空欄（`NULL` 文字列は使わない） |
| 真偽値 | `Y`（はい・有効・あり）／`N`（いいえ・無効・なし） |
| 日付 | `YYYY-MM-DD`（例 `2026-10-20`） |
| 数値 | 金額 `decimal(19,4)` 相当、数量は単位ごとの小数桁に従う（[01](../00-common/01-common-item-definitions.md) §6）。CSV では桁区切りなし |
| コードと名称 | コード列（`*_code`）と名称列（`*_name`）を併記。コードは大文字英数字・ハイフン・アンダースコアのみ |
| 出典・備考 | `remark` 列に【実データ】【示例値】【要確認】と出典 ID を付す |
| 更新 | 参照日（2026-10-20）を各ファイル冒頭コメントまたは README で管理。コード変更は Lead 承認＋全設計書 grep 更新 |

---

## 4. 主要データの説明

### 4.1 物料（material-master.csv）

- **物料編碼**：`{分類 4 桁}{流水 6 桁}`＝10 桁（[08](../00-common/08-common-business-rules.md) 2.2、[06](../00-common/06-code-list.md) §11）。分類は [material-category.csv](code-lists/material-category.csv) を正とする。
  - 例：`3001000001` YE3-100L1-4、`1001000001` 50W470 电工钢帯、`1004000001` QZY-2/180 漆包線、`4001000001` 6205-2RS。
- **物料種別**：`原材料`／`半成品`／`成品`／`外購件`／`包装材料`／`低値易耗品`。半成品は自制（BOM を持つ）、外購件は購買品（BOM 末端）。**分類 `4004` は外购绝缘材料、`4005` は其他电机配件**（风扇等は `4005`）。分類コードは [material-category.csv](code-lists/material-category.csv) を唯一の正とし、本 README の記述も同 CSV に一致させる。
- **物料種別コード（MDM 連携用）**：`10` 成品／`20` 半成品／`30` 原材料／`40` 外購件／`50` 包装材料／`60` 低値易耗品／`70` 委外加工件／`80` サービス。`material-master.csv` の `material_type`（中文）と本コードの対応で MDM と連携する（最終口径は 02-mdm で確定）。
- **単位**：`base_uom`（在庫・BOM の基本単位）／`purchase_uom`（購買単位）／`sales_uom`（販売単位）。換算は [08](../00-common/08-common-business-rules.md) §5。
- **批次・序列号**：`batch_managed`／`serial_managed`。材料・半成品は批次、成品は批次＋序列号。規則は [batch-number-rule.csv](code-lists/batch-number-rule.csv)（示例）。
- **執行標準**：材料牌号・製品標準（【実データ】）。**2025 年版が施行済みの標準（GB/T 5782-2025、GB/T 93-2025、GB/T 6109.5-2025）を引用**している。
- **品牌・仕入先**：`brand`（公開情報）／`default_supplier_code`（[supplier-master.csv](supplier-master.csv) 参照）。仕入先未定の材料は空欄＋`remark` に「待寻源」。
- **価格・安全在庫・提前期**：すべて【示例値】。

### 4.2 顧客・仕入先（customer-master.csv／supplier-master.csv）

- 顧客コード `C`＋6 桁、仕入先コード `S`＋6 桁（[08](../00-common/08-common-business-rules.md) 2.2）。
- 企業名・股票コードは**公開情報**（[sources.md](sources.md) §5）。**示例数据，仅用于设计验证，不代表任何商业关系**。
- 住所は行政区画コード＋地区名まで。番地・連絡先・担当者・口座番号は含めない。
- 信用限度額・支払条件・協力等級は【示例値】。

### 4.3 倉庫・庫位（demo-company.md §3、warehouse-location.csv）

- `WH01` 原料倉（WX01 内）／`WH02` 半成品倉（CZ01 内）／`WH03` 成品倉（CZ01 内）。
- 庫位コード：`{倉庫}-{庫区}-{棚 2 桁}-{層 2 桁}-{位 2 桁}`（例 `WH01-A-01-02-03`）。
- 在庫状態：可用／待検／凍結／不合格（[01](../00-common/01-common-item-definitions.md) §7）。

### 4.4 批号・序列号（batch-number-rule.csv、示例）

| 対象 | 規則（示例） | 例 |
|---|---|---|
| 購買材料批号 | `{YYMMDD}P{3 位流水}` | `261020P001` |
| 製造半成品批号 | `{YYMMDD}M{3 位流水}` | `261020M001` |
| その他入庫批号 | `{YYMMDD}O{3 位流水}` | `261020O001` |
| 成品序列号 | `{YYMMDD}{機座号 3 桁}{4 位流水}` | `2610201000001` |

> 上記は【示例値】。実際の採番は在庫域（05-inventory）と MDM 域で確定する。90-data は**参考規則**を提供し、強制しない。

### 4.5 BOM・工程路線（bom-demo.md／routing-demo.md）

- BOM コード `BOM-3001000001-V01`、工程路線 `RT-3001000001-V01`（[08](../00-common/08-common-business-rules.md) 2.2）。
- 階層：L0 成品 → L1 総成／加工品 → L2 部品／材料 → L3 素材。数量は**親 1 単位あたりの純使用量**、`loss_rate` は工程損耗率。MRP は `gross = net / (1 - loss_rate)` で展開する（[bom-demo.md](bom-demo.md) §5 の算例）。
- 工作中心 `WC001〜WC012`（[06](../00-common/06-code-list.md) §10。WC001 下料〜WC010 包装、WC011 转子铸铝、WC012 喷漆。[routing-demo.md](routing-demo.md) と一致）。標準工時は【示例値】。

### 4.6 会計科目（accounting-subjects.csv、108 行）

- 科目コードは 4 桁（CAS 2006 応用指南）。明細科目は `{4 桁}.{2 桁}`、**2221 应交税费のみ 3 級（例 `2221.01.02`）**を 07-finance/01 §3.5 と一致させて収録する（08 §2.2 の「4 桁+補助 2 桁」は 6 桁までの規定であり、3 級を採用する場合は 08 側の追記が必要）。
- 列：`subject_code`／`subject_name`／`parent_code`／`level`／`category`／`balance_direction`／`aux_accounting`／`is_leaf`／`allow_manual_entry`／`valid_from`／`source`／`remark`。
- 補助核算：`CUSTOMER`／`SUPPLIER`／`DEPARTMENT`／`EMPLOYEE`／`PROJECT`／`MATERIAL`／`WAREHOUSE`／`BANK_ACCOUNT`／`TAX`。
- 仕訳で使用する科目は [09](../00-common/09-cross-domain-flow.md) §7.2 を正とする。合同負債・使用権資産等の新準則科目は 2006 年付録に無いため**本 CSV に含めない**（[06](../00-common/06-code-list.md) §12 注記）。
- **行数（2026-10-20 実測）**：データ 108 行（ヘッダ除く。2221 の親 1＋2 級 20＋3 級 9＝30 行、その他 78 行）。

### 4.7 税・通貨・単位・地区・貿易・銀行・HS（code-lists/）

- 各ファイルは 06-code-list.md の要約に対応する**全件データ**。税率・コードは法令・標準に基づく【実データ】。
- 税コードは有効期間（`valid_from`／`valid_to`）管理を前提とし、改正時は旧行を閉じて新行を追加する。**基礎税率コード 21 件は `tax.csv`、業務税碼（方向付き）24 件は `mdm-tax-code.csv`**（MDM `mdm_tax_code` の初期データ）を正とする。
- 法令根拠：增值税は《中华人民共和国增值税法》（2026-01-01 施行）、関税は《中华人民共和国关税法》（2024-12-01 施行）、地方教育附加は財綜〔2010〕98 号（全国統一 2%）、小規模納税人の 1% 減征は 2023 年第 19 号（2027-12-31 まで）＋增值税法施行後の衔接 2026 年第 10 号。
- 単位：体積グループの基本単位は **MTQ**（LTR＝0.001 MTQ、MLT＝0.000001 MTQ）。MDM `mdm_uom` の `is_base_uom` は MTQ を TRUE とする。
- 銀行：`bank.csv` は **CNAPS の行別コード（3 桁）＋`bank_category`（10〜60）**のみを保持し、架空の聯行号・支店コードは保持しない。聯行号の 12 桁構成（3+4+4+1）は [06](../00-common/06-code-list.md) §11 に定義。
- 決済・支払条件：`payment-terms.csv` は MDM `mdm_settlement_method.settlement_type`（10 現金/20 転帳/30 票拠/40 信用状/50 その他）と `mdm_payment_term.settlement_basis`（10 発票日/20 検収日/30 出発日/40 月末/50 注文日）に直接対応する列を持つ。
- 包装：木箱の製品標準は **GB/T 12464-2016（普通木箱）**。GB/T 191-2025 は「包装儲運図形符号標志（表示マーク）」であり製品標準ではない（sources.md S-135／S-029）。
- 関税率・輸出退税率は本ディレクトリに固定値を置かない（毎年の税則で変動）。HS コードのみ保持する。

### 4.8 2026-10 単月シナリオ（正本）

- [demo-company.md](demo-company.md) §8.1 を**唯一の正本**とする（売上 66,666,666.67／原価 50,000,000／粗利 25%／在庫 98,000,000／売掛 149,000,000／買掛 68,000,000／YE3 SO 120 PCE×856.50／WO 120 PCE・標準 778.20・実際 93,377.55）。
- 07-finance・10-analytics の `94-sample-data.md` は本表の値のみを使用する。旧値（売上 61,000,000／在庫 3,240,000／売掛 56,141.40／買掛 75,000,000／単位原価 446.70）は廃止した。

---

## 5. データ間の参照関係

```
material-master.csv ──< bom-demo.md（親子: material_code）
        │                    └──< routing-demo.md（品目→工程路線）
        ├── default_supplier_code ──> supplier-master.csv
        ├── category_code ──────────> code-lists/material-category.csv
        ├── base_uom ───────────────> code-lists/uom.csv
        └── 価格・在庫 ─────────────>（示例値）

customer-master.csv ── region_code ──> code-lists/region.csv
supplier-master.csv ── region_code ──> code-lists/region.csv
        └── payment_term_code ─────> code-lists/payment-terms.csv

accounting-subjects.csv ──（仕訳）──> 09 §7.2
code-lists/tax.csv ──（税計算）────> 08 §4
code-lists/currency.csv ───────────> 06 §3
code-lists/bank.csv ──（聯行号）───> 06 §11
code-lists/approval-matrix.csv ────> 08 §8／approval-matrix.md
```

- 参照整合：`material-master` の `default_supplier_code` は `supplier-master` に存在すること。`bom-demo` の親子コードは `material-master` に存在すること（BOM 内の半成品も含む）。設計時に「コード存在チェック」（[01](../00-common/01-common-item-definitions.md) §8）の対象となる。

---

## 6. ファイル別の列定義（概要）

### 6.1 customer-master.csv

`customer_code`（顧客コード C＋6）／`customer_name`（企業名）／`short_name`／`country_code`／`region_code`／`region_name`／`industry_code`（GB/T 4754-2017 大類）／`industry_name`／`customer_type`（整機メーカー／終端ユーザー／代理店）／`credit_limit_cny`【示例値】／`payment_term_code`／`sales_org`／`status`／`remark`

### 6.2 supplier-master.csv

`supplier_code`（S＋6）／`supplier_name`／`short_name`／`country_code`／`region_code`／`region_name`／`supplier_type`（生産メーカー／商社／サービス）／`material_scope`／`payment_term_code`／`currency_code`／`tax_code`／`bank_name`（公開情報の銀行名のみ）／`cooperation_level`（戦略／合格／潜在）／`status`／`remark`

### 6.3 code-lists/approval-matrix.csv

`approval_code`／`scenario_code`／`target_doc`／`condition_type`／`min_amount`／`max_amount`／`approval_path`／`approval_mode`／`process_key`／`valid_from`／`valid_to`／`remark`

### 6.4 その他 code-lists

各ファイル先頭行のヘッダを参照。列名は `code`＋`name`＋`remark` を基本とし、ドメイン固有列（例：`rate`、`minor_unit`、`valid_from`、`standard_ref`）を追加する。列の意味は本 README と 06-code-list.md の該当章で説明する。

---

## 7. 利用時の注意（設計者向け）

1. **数値を本文へコピーするときは区分を保つ**：実データ（標準・税率）と示例値（価格・工数）を混在させない。
2. **引用はコード＋名称**：`material_code` だけでなく名称も併記する（例 `3001000001 YE3-100L1-4`）。
3. **バージョン**：BOM・工程路線は `V01` 版数を持つ。設計変更時は新バージョンを発行し、旧版は `valid_to` で閉じる。
4. **【要確認】の取扱い**：設計正文で確定値として使用しない。使用する場合は「【要確認】」を残し、未決事項に記載する。
5. **企業情報**：公開情報の企業名は「示例データ」注記なしで顧客・取引先として断定しない。必ず「示例数据，仅用于设计验证，不代表任何商业关系」を併記する。
6. **変更時の連絡**：本ディレクトリの変更は全 8 域に影響する。変更後は Lead へ報告し、影響する設計書・matrix を grep で確認する。

---

## 8. 未決事項

| # | 事項 | 現状 | 対応 |
|---|---|---|---|
| 1 | JB/T 6213.1 現行版／6640 NMN 執行標準／GB/T 894 現行版 | 【要確認】 | [sources.md](sources.md) §6 に従い確認 |
| 2 | 1% 減征の 2026 年以降の適用条件（2026 年第 10 号の対象範囲の詳細） | 【要確認】 | sources.md §6 #5 に従い確認 |
| 3 | 統一社会信用代码の取扱い | 本ディレクトリには含めない | 実施時に国家企業信用信息公示系統で確認（設計対象外） |
| 4 | 批号・序列号規則の最終化 | 示例規則を提示 | 05-inventory／02-mdm で確定 |
| 5 | 2026 年法定节假日の具体日程 | 【要確認】 | 官方通知後に demo-company／routing を更新 |
| 6 | 顧客・仕入先の信用限度額・協力等級 | 【示例値】 | 実施時に与信審査で設定 |
| 7 | 一部企業公式サイト URL | 【要確認】 | sources.md §6 #10 |

> **解消済み（2026-10-20）**：地方教育附加（S-140）、1% 減征文号・期限（S-139）、增值税法・关税法（S-136／S-137）、木箱の製品標準（S-135）、A19/A20 の正本（approval-matrix.md）、UOM 体積基本単位（MTQ）、科目行数（108）、物料件数（54）、出典件数（109）。

---

## 9. 改訂履歴

| 版数 | 日付 | 変更内容 | 変更者 |
|---|---|---|---|
| v1.0 | 2026-10-20 | 初版：データ地図・データ区分・CSV 共通仕様・主要データ説明・参照関係・列定義・利用注意 | data-researcher |
| v1.1 | 2026-10-20 | 紅隊レビュー第 2 輪修正：mdm-tax-code.csv（24 件）追加、material 54 件・科目 108 行・出典 109 項・24 ファイル約 191KB・CSV 483 行に件数修正、UOM 体積基本 MTQ、bank 行別コード＋category、payment-terms の MDM DDL 互換列、木箱 GB/T 12464、月次シナリオ（正本）追加、未決 7 件に整理 | data-researcher |
