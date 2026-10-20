# 红队评审报告：主数据管理（02-mdm）＋代码一览（06）＋真实资料（90-data）

| 項目 | 内容 |
|---|---|
| 文書名 | 红队评审报告：主数据＋代码一览＋真实资料（レッドチームレビュー報告書） |
| 文書番号 | DSN-REV-FIN-001 |
| 版数 | v1.0 |
| 作成日 | 2026-10-20 |
| 作成者（レビュアー） | finance-designer（財務管理域担当。被レビュー対象の執筆者ではない） |
| 承認者 | Lead（未承認・レビュー待ち） |
| 状態 | 完了（第 1 ラウンド 指摘のみ。設計変更なし） |
| レビュー対象 | `docs/design/02-mdm/`（13 ファイル）、`docs/design/00-common/06-code-list.md`、`docs/design/90-data/`（全 23 ファイル） |
| 準拠 | [对抗性评审宪章](README.md)（DSN-REV-000） |
| 関連文書 | [09 跨域流程](../00-common/09-cross-domain-flow.md) / [08 共通业务规则](../00-common/08-common-business-rules.md) / [07-finance/01 会計科目](../07-finance/01-accounting-subjects.md) / [06-code-list](../00-common/06-code-list.md) |

---

## 1. レビューの目的と独立性

[对抗性评审宪章](README.md) に基づき、**財務・税務の利用者視点**から 02-mdm・06-code-list・90-data を「実装前提で破壊しにいく」観点でレビューした。レビュアーは財務管理域（07-finance）の執筆者であり、本レビュー対象（MDM・共通コード・90-data）の執筆には関与していない。指摘はすべて**ファイル名:行番号＋引用**を付し、外部事実は URL と参照日（2026-10-20）を記録した。推測・未確認は「未確認」と明記した。

---

## 2. レビュー範囲・方法・実施日

| 項目 | 内容 |
|---|---|
| 実施日 | 2026-10-20 |
| 対象 | 02-mdm 13 ファイル、00-common/06-code-list.md（393 行）、90-data 23 ファイル（Markdown 6・CSV 17）。計 **37 対象** |
| 方法 1：精読 | `02-mdm/00-overview.md`、`04-uom-currency-tax.md`、`90-db-design.md` の該当章、`01-material-master.md` 財務視図、`05-price-settlement.md` 銀行/決済章、`06-credit-supplier-eval.md`、`90-data/sources.md` 全 204 行、`90-data/README.md`、`06-code-list.md` 全 393 行、`material-master.csv`・`tax.csv`・`uom.csv`・`payment-terms.csv`・`bank.csv`・`hs-code.csv`・`material-category.csv` 等の主要 CSV |
| 方法 2：機械照合 | ①ファイル間の件数・名称・コード値の照合（分類 28／単位 21／税 21／決済 18／WC 12／1411 等）②CSV 行数の実測（`Get-Content` によるデータ行数）③06-code-list と 90-data の突合 ④02-mdm DDL のフィールドと CSV ヘッダの突合 |
| 方法 3：外部照合 | GB 標準号・法令・税率・公告・CNAPS・ISO コードの Web 照合。**URL と参照日を §4.2 に記録**。標準の現行版は変更が速いため、sources.md 記載の 2025 年版を重点的に確認 |
| 方法 4：財務要件照合 | FIN が必要とする MDM 項目（税碼、cost_method、銀行口座、付款条件、科目マッピング、単位換算、通貨・為替）の有無を §4.3 で突合 |
| 制約 | ①02-mdm は 13 ファイル合計約 600KB のため、`01-material-master.md`・`02-business-partner.md`・`90-db-design.md` は関連章の部分精読＋grep。②03-sales／04-purchase／05-inventory は対象外のため一次資料未読（FIN 経由の間接確認のみ）。③公式サイト（中国人民銀行・標準平台の詳細ページ）の一部は検索結果の URL のみで本文取得していない（§5）。④指摘のうち「未確認」と付したものは確定事実として扱わない |
| 指摘件数 | **16 件**（S1: 0、S2: 3、S3: 10、S4: 3）。捏造・水増しなし。問題なしと確認した項目は §4 に証拠付きで記載 |

---

## 3. 指摘一覧

### 3.1 重大度 S1（実装前に必須修正）

**該当なし（0 件）**。90-data の標準号・税率・CAS 科目・ISO コードは抽查した範囲で実在し、虚偽の「実データ」表示は検出できなかった（§4.2）。ただし S2 指摘 3 件は実装前に必ず解消すべき。

### 3.2 重大度 S2（実装前に修正必須）

| 指摘 ID | 重大度 | 対象ファイル:行 | 指摘内容 | 証拠・根拠 | 修正提案 | 想定影響 |
|---|---|---|---|---|---|---|
| REV-FIN-001 | **S2** | `90-data/code-lists/tax.csv:2,5,6,9,21`、`90-data/sources.md:95-111` | **税の法的根拠が旧法のまま。2026-10-20 時点で失効済みの「增值税暂行条例」「进出口关税条例」を【実データ】の根拠として引用している。** 增值税は 2024-12-25 公布の《中华人民共和国增值税法》（2026-01-01 施行）が現行法、関税は 2024-04-26 公布の《中华人民共和国关税法》（2024-12-01 施行）が現行法。sources.md §3 には両法の出典が**存在しない**（grep 0 件） | `tax.csv:2`「…财政部 税务总局 海关总署公告2019年第39号；**中华人民共和国增值税暂行条例**」／`:5`「…**增值税暂行条例第二条**」／`:6`「…**增值税暂行条例第十二条**；财税〔2016〕36号」／`:9`「…**增值税暂行条例第十五条**」／`:21`「…**中华人民共和国进出口关税条例**；当年进出口税则」／[sources.md:95-111](../90-data/sources.md) は S-050〜S-063 のみで両法なし。外部確認（参照日 2026-10-20）：财政部「增值税法通过！自 2026 年 1 月 1 日起施行」http://m.mof.gov.cn/czxw/202412/t20241225_3950444.htm ／ 中国政府网「《中华人民共和国关税法》本月起施行」https://www.gov.cn/yaowen/liebiao/202412/content_6990667.htm | ① `legal_basis` を《增值税法》及び同法施行令・配套公告、《关税法》へ更新。② sources.md に S-ID を追加（公布日・施行日・URL 付き）。③ 税率（13/9/6/0、徴収率 3%）は法で維持されているが、**小規模納税人 1% 優遇（2023 年第 19 号）の 2026 年以降の継続根拠を再確認**し、VAT1 の有効期間を更新 | 税務設計の根拠が法令違反状態になる。税率・計算式自体は現行と一致するため S1 ではないが、税務調査・監査で「根拠法令の誤り」を指摘される。§4.2 のとおり税率値の誤りはない |
| REV-FIN-002 | **S2** | `90-data/code-lists/bank.csv:1-10`（対照：`02-mdm/90-db-design.md:1201-1213`、`02-mdm/05-price-settlement.md:79`） | **bank.csv が mdm_bank の DDL にそのまま投入できない。** MDM は `mdm_bank.bank_code`（銀行行別コード）と `bank_category`（SMALLINT 10 政策性/20 国有大型/30 股份制/40 城商/50 农商/60 外资）で管理するが、CSV の列は `bank_code / bank_type_code / bank_type_name` で `bank_category` に相当する列が無く、しかも BANK 行の `bank_type_code=102/103/104/105/301` は「個別銀行の行別コード」、BANK_TYPE 行の `313/314/320/402` は「銀行類別コード」で、同じ列に意味の異なるコードが混在。MDM 05 は CNAPS 先頭 3 桁を「銀行類別」と説明するが、CNAPS の 3 桁は銀行を識別する**行別コード**（102=中国工商银行）であり、類別ではない | `bank.csv` ヘッダ `record_type,bank_code,bank_name,bank_type_code,bank_type_name,region_code,region_name,example_cnaps_no,status,remark`／BANK 行「BANK,102,中国工商银行,102,国有大型商业银行,…」／BANK_TYPE 行「BANK_TYPE,313,城市商业银行,313,城市商业银行,…」／[MDM 90-db-design.md:1201-1213](../02-mdm/90-db-design.md) `bank_code VARCHAR(16) -- 银行行别代码`、`bank_category SMALLINT -- 10政策性/20国有大型/30股份制/40城商/50农商/60外资`／[MDM 05:79](../02-mdm/05-price-settlement.md)「3 桁の銀行類別 + 4 桁の都市コード + 4 桁の支店連番 + 1 桁の検証コード」。CNAPS 構造の参考：https://baike.baidu.com/item/cnaps%E8%A1%8C%E5%8F%B7/50975481 | ① CSV に `bank_category`（MDM コード 10〜60）と `是別コードの意味` を明記した列を追加し、BANK 行/BANK_TYPE 行を分離。② MDM 05 の「銀行類別」を「行別コード（銀行識別 3 桁）」に修正。③ CNAPS 12 桁の構成（3+4+4+1）は正しいため、その点は維持 | mdm_bank のシード投入スクリプトが列不足で失敗、または bank_type_code=102 を bank_category と誤解して分類統計・銀行別集計が壊れる。CNAPS 生成ロジックの設計誤解を招き、銀企連携・口座照合に波及 |
| REV-FIN-003 | **S2** | `02-mdm/90-db-design.md:120`、`02-mdm/00-overview.md:306`、`02-mdm/94-sample-data.md:206-211`、`00-common/06-code-list.md:158-203` | **業務税码（`mdm_tax_code`）の全件リストが存在せず、「60 件」の内訳・初期データが未定義。** FIN の自動凭证（J03/J07 の税区分、J26/J27 の附加税・所得税）と SAL/PUR の发票税码は `mdm_tax_code.tax_code`（VAT13-OUT/VAT13-IN 等）を直接参照する設計だが、MDM 94 の税码サンプルは 8 件程度、90-data に業務税码の CSV は無く、06-code-list も基礎税率码 21 件のみ。60 件の根拠・全件・`tax_rate_code`/`tax_type` の対応表が実装者に渡らない | [MDM 90-db-design.md:120](../02-mdm/90-db-design.md)「`mdm_tax_code` 税码 マスタ 60 件」／[MDM 00-overview.md:306](../02-mdm/00-overview.md)「60 件」／[MDM 94-sample-data.md:206-211](../02-mdm/94-sample-data.md) は VAT13-OUT/VAT13-IN 等 8 例のみ／[06-code-list.md:158-203](../00-common/06-code-list.md) は基礎税率码 21 件（VAT13〜EXCISE）で、業務税码の OUT/IN 派生は MDM 04:70 の記述のみ／90-data に業務税码 CSV なし | ① 90-data に `code-lists/tax-business.csv`（全 60 件：`tax_code, tax_rate_code, tax_type, is_tax_included, valid_from/to, legal_basis`）を追加、または②「基礎码 + 方向（OUT/IN）」の派生ルールを明文化し、シード SQL の生成規則を設計書に記載。③ FIN 自動凭证テンプレートの TAX_TYPE_MAP（10/11/12）との対応を再確認 | FIN の J03/J07/J26/J27、SAL/PUR の发票登録で税码の選択肢が実装者ごとにバラつき、税額・税区分が伝票間で不整合。税務申告辅助表（`fin_vat_return`）の集計が税码別に不能 |

### 3.3 重大度 S3（実装開始までに修正）

| 指摘 ID | 重大度 | 対象ファイル:行 | 指摘内容 | 証拠・根拠 | 修正提案 | 想定影響 |
|---|---|---|---|---|---|---|
| REV-FIN-004 | S3 | `90-data/README.md:43`、`00-common/06-code-list.md:358`、`02-mdm/94-sample-data.md:57,330`、`02-mdm/90-db-design.md:1486` | **物料マスタの件数が 53／54／55 で三者不一致。** 実ファイルのデータ行は **54 件**。90-data README は「約 53 件」、06-code-list は「54 件」、MDM 94 と MDM 90-db は「55 件」（2 箇所） | 実測：`material-master.csv` のデータ行 54（ヘッダ除く）／[README.md:43](../90-data/README.md)「約 53 件」／[06-code-list.md:358](../00-common/06-code-list.md)「54 件」／[MDM 94:57](../02-mdm/94-sample-data.md)「全 55 件」・同 `:330`「物料 55 件」／[MDM 90-db:1486](../02-mdm/90-db-design.md)「`material-master.csv`（55 件）」 | 全ファイルを「54 件」に統一（CSV が正本）。または CSV に行追加して 55 件に揃える場合は、追加行のカテゴリ・標準も同時に整備 | シード投入・検収（件数チェック）・トレーサビリティで件数不一致が発生。データ品質 KPI（充足率）の分母がぶれる |
| REV-FIN-005 | S3 | `90-data/README.md:48`、`00-common/06-code-list.md:363` | **会計科目 CSV の行数記述が不一致。** README は「CAS 常用科目 **75 行**」、実ファイルはデータ **86 行**（06-code-list は 86 件と正しい） | 実測：`accounting-subjects.csv` データ行 86（ヘッダ除く）／[README.md:48](../90-data/README.md)「CAS 常用科目 75 行」／[06-code-list.md:363](../00-common/06-code-list.md)「86 件」 | README を 86 行に修正。行数だけでなく「基礎科目＋明細・補助核算」の内訳を明記 | 財務の科目突合（07-finance/01 は CSV を正とする）で件数検証が失敗し、未突合と誤認される |
| REV-FIN-006 | S3 | `00-common/06-code-list.md:351,364` | **06-code-list §14 のデータ規模記述が実測と乖離。** 「23 ファイル / **約 190KB**」→ 実測 **174.6KB**、「sources.md **約 130 項**」→ 実際の S-ID は **103 件**（sources.md 自身の改訂履歴「国家標準 49・法令税務 14・コード 6・公開企業 34」＝103 と一致） | 実測：90-data 全 23 ファイル合計 174.6KB、sources.md のユニーク S-ID 103／[06-code-list.md:351](../00-common/06-code-list.md)「23 ファイル / 約 190KB」／`:364`「約 130 項」／[sources.md:204](../90-data/sources.md)「初版：国家標準 49 件・法令税務 14 件・コード/貿易/銀行/HS 6 件・公開企業情報 34 件」（49+14+6+34=103） | 「約 175KB」「103 項」に修正、または sources.md に 27 件追加して 130 項に合わせる（追加根拠が必要） | データ索引の信頼性低下。レビューで「実データ件数」を照合する際の基準がぶれる |
| REV-FIN-007 | S3 | `00-common/06-code-list.md:150-151`（対照：`90-data/code-lists/uom.csv`、`02-mdm/04-uom-currency-tax.md:47`） | **単位換算表の体積グループの基本単位が uom.csv／MDM と矛盾。** 06 は「LTR 換算 1（基本単位）」「MLT 0.001 LTR」とするが、uom.csv は VOL グループの基本単位を **MTQ** とし、LTR=0.001 MTQ／MLT=0.000001 MTQ。MDM 04 BR-UOM-03 も「VOL→MTQ」を明文で規定 | [06-code-list.md:150](../00-common/06-code-list.md)「LTR 升 1」／`:151`「MLT 毫升 0.001 LTR」／`uom.csv` 行 LTR「体積,VOL,0.001,MTQ」・MLT「体積,VOL,0.000001,MTQ」／[MDM 04:47](../02-mdm/04-uom-currency-tax.md)「`VOL`→`MTQ`」 | 06 を「LTR 0.001 MTQ／MLT 0.000001 MTQ」に修正（Base は MTQ）。または 06 の表に「表示用の換算」である旨を注記 | 単位換算の実装が 06 と MDM で異なる基本単位を持ち、液体材料（絶縁漆等）の在庫数量・原価計算が 1,000 倍ずれるリスク |
| REV-FIN-008 | S3 | `00-common/06-code-list.md:169,383`、`90-data/code-lists/tax.csv:7`、`90-data/sources.md` | **VAT1（1% 徴収率）のステータスが「実データ＋要確認」の混在で、未決も解消可能なまま残存。** 06 は「【実データ】要確認最新公告」、tax.csv は `status=A` かつ remark「【要確認】文号・期限を公式公告で確認」、06 §15 の未決 #1 にも「1% 征收率公告」を列挙。一方、根拠の「财政部 税务总局公告 2023 年第 19 号」は実在が確認でき、sources.md に登録が無いだけ | [06-code-list.md:169](../00-common/06-code-list.md)「【実データ】要確認最新公告」／`:383` 未決 #1 に「1% 征收率公告」／[tax.csv:7](../90-data/code-lists/tax.csv)「…财政部 税务总局公告2023年第19号…【要確認】文号・期限を公式公告で確認」／sources.md の法令表 §3 に S-ID 未登録（§6 未確認 #6 に「2023 年第 19 号か」と記載のみ＝:181）／外部確認（参照日 2026-10-20）：中国政府网「关于增值税小规模纳税人减免增值税政策的公告」https://www.gov.cn/zhengce/zhengceku/202308/content_6896287.htm | ① sources.md に 2023 年第 19 号を S-ID 付きで追加。② 06/tax.csv の【要確認】を解除し【実データ】へ。③ 06 §15 未決から削除（残 10 項へ）。④ 增值税法施行後（2026-01-01〜）の 1% 優遇継続根拠を確認し、有効期間を更新 | 要確認が放置され「未確定値で実装しない」ルールとの整合が崩れる。1% 仕入先の税額計算可否が実装者判断になる |
| REV-FIN-009 | S3 | `90-data/code-lists/payment-terms.csv:1-19`（対照：`02-mdm/90-db-design.md:1156-1199`） | **payment-terms.csv のスキーマが MDM DDL にマッピング不能。** MDM は `mdm_settlement_method.settlement_type`（SMALLINT 10 現金/20 転帳/30 票拠/40 信用状/50 その他）と `mdm_payment_term.settlement_basis`（SMALLINT 10 発票日/20 検収日/30 出荷日/40 月末/50 注文日）を要求するが、CSV の `base_date` は文字列（`month_end`/`acceptance_date`/`delivery_date`/`order_date`）、`record_type=SETTLEMENT` 行には `settlement_type` 列が無い。両者の対応表が無い | `payment-terms.csv` ヘッダ `record_type,code,name_cn,name_en,description,base_date,prepay_ratio,net_days,due_rule,status,remark`／`base_date` 値（12〜19 行目）`month_end/acceptance_date/delivery_date/order_date`／[MDM 90-db-design.md:1160](../02-mdm/90-db-design.md) `settlement_type SMALLINT -- 10現金/20転帳/30票拠/40信用状/50その他`／`:1174` `settlement_basis SMALLINT -- 10発票日/20検収日/30出荷日/40月末/50注文日` | CSV に MDM コード列（`settlement_type`/`settlement_basis` SMALLINT）を追加し、日本語・英語の名称は別列に。90-data README に変換表を明記 | MDM の決済・支払条件シードが列不足で失敗、または文字列をそのまま SMALLINT に変換する実装が各所で重複し、FIN の AP 到期日計算（NET30 等）が誤る |
| REV-FIN-010 | S3 | `90-data/material-master.csv:31`（対照：`90-data/sources.md:67`） | **木箱の執行標準として GB/T 191-2025 を紐付けているが、GB/T 191 は「包装储运图形符号标志」（表示マークの規格）であり、木箱の製品規格ではない。** 標準自体は実在するが適用対象が誤り。木箱の執行標準は普通木箱・框架木箱等の製品規格であるべき（具体番号は未確認） | [material-master.csv:31](../90-data/material-master.csv)「5001000002,木箱,YE3-100 出口包装用,5001,木箱,包装材料,PCE,PCE,PCE,**GB/T 191-2025**,…,示例值；**包装储运图形符号标志**」／[sources.md:67](../90-data/sources.md) S-029「GB/T 191-2025 包装储运图形符号标志」／同 CSV の瓦楞纸箱は GB/T 6543-2025、平托盘は GB/T 2934-2007 と製品規格を正しく紐付けている（対照） | 木箱の執行標準を製品規格（普通木箱 GB/T 12464、框架木箱 GB/T 7284 等）へ差し替え、GB/T 191 は「表示マーク」の remark に移す。標準番号の最終確認は data-researcher の役割 | PUR の発注仕様・IQC の検査基準に誤った標準が伝播。品質監査で「図示記号の規格で木箱を検査」という矛盾を指摘される |
| REV-FIN-011 | S3 | `02-mdm/01-material-master.md:132`（対照：`90-data/sources.md:89`、`90-data/material-master.csv:17-18`） | **MDM の項目例が廃止済みの GB/T 5782-2016 を引用。** sources.md は「GB/T 5782 は 2025 年版が発布され、**2016 版等の旧版を引用しないこと**」と明記し、CSV は GB/T 5782-2025 を使用している | [01-material-master.md:132](../02-mdm/01-material-master.md)「例 GB/T 5782-2016」／[sources.md:89](../90-data/sources.md)「GB/T 5782（→2025 版）…2016 版・1987 版等の旧版を引用しないこと」／[material-master.csv:17-18](../90-data/material-master.csv)「GB/T 5782-2025」 | MDM の例を「GB/T 5782-2025」に修正。同様に GB/T 93-2025、GB/T 6109.5-2025、GB/T 755-2025 等の新版を例示に反映 | マスタ登録者が旧版を「執行標準」として入力し、購買仕様・品質検査が旧版基準になる |
| REV-FIN-012 | S3 | `00-common/06-code-list.md:263,393`（対照：`90-data/routing-demo.md:46-47`） | **工作中心名称が 06 と routing-demo で不一致。** 06 は `WC008 总装 / WC009 试验`、routing-demo は `WC008 装配 / WC009 出厂试验`。しかも 06 の改訂履歴 v1.3 は「routing-demo.md・demo-company.md・production 域の 12 工作中心と一致させた」と**一致を明言**しており、記載が事実と異なる | [06-code-list.md:263](../00-common/06-code-list.md)「WC008 总装 / WC009 试验」／`:393`「routing-demo.md…と一致させた」／[routing-demo.md:46](../90-data/routing-demo.md)「`WC008`｜装配」／`:47`「`WC009`｜出厂试验」 | 名称をどちらかに統一（推奨：routing-demo の「装配」「出厂试验」に 06 を合わせる。または 06 に「正式名称/別名」を併記）。06 の改訂履歴の「一致」記述を修正 | 原価配賦・工数集計・帳票で工作中心名が不一致となり、生産域との照合が難しくなる。改訂履歴の信頼性低下 |
| REV-FIN-013 | S3 | `02-mdm/03-warehouse-location.md:454` | **未決事項が解消済みなのに残存。**「倉庫コード体系（WH01〜）と 90-data の倉庫一覧の突合」を『data-researcher の demo-company.md 待ち』としているが、demo-company.md は既に完成（326 行、WH01/WH02/WH03 を記載）しており、warehouse-location.csv とも一致している | [03-warehouse-location.md:454](../02-mdm/03-warehouse-location.md)「倉庫コード体系…data-researcher の demo-company.md 待ち…」／[demo-company.md](../90-data/demo-company.md) は完成済（326 行、WX01/CZ01・WH01〜03）／[warehouse-location.csv](../90-data/code-lists/warehouse-location.csv) は WH01/WH02/WH03 を収録 | 未決を「解消済み」として削除し、必要なら「WH04/WH05（待機倉・不合格倉）の追加要否」に置き換える | 未決一覧の件数・信頼性が損なわれ、レビューで「未解消」と誤判定される |

### 3.4 重大度 S4（建議）

| 指摘 ID | 重大度 | 対象ファイル:行 | 指摘内容 | 証拠・根拠 | 修正提案 | 想定影響 |
|---|---|---|---|---|---|---|
| REV-FIN-014 | S4 | `90-data/code-lists/region.csv:2`、`90-data/code-lists/country.csv:20` | 省級行政区画の `parent_code` が「CN」、また台湾の英語名が ISO 3166 の「Taiwan, Province of China」と完全一致しない（「Taiwan (Province of China)」）。GB/T 2260 の根ノードは 000000（または空）で、国コードを親に持たない | [region.csv:2](../90-data/code-lists/region.csv)「110000,北京市,直辖市,CN,CN,…」／[country.csv:21](../90-data/code-lists/country.csv)「TW,TWN,中国台湾,Taiwan (Province of China),…」 | `parent_code` を `000000`（または空）に統一。国名は ISO 3166 の公式表記に合わせる（中文名は「中国台湾」を維持） | 住所・地域ツリーの取込で親子解決が国コードに依存する実装だと不整合。国際取引の地域コード標準照合で指摘される |
| REV-FIN-015 | S4 | `90-data/sources.md:106,108,121` | 出典の質に改善余地。①会計档案保管期限の補助リンクに商業試験対策サイト（dongao.com）を併記。②S-061（企業所得税法実施条例・512 号）の URL を【要確認】としつつ、設計側では 512 号を【実データ】として使用。③CNAPS 構造の出典が百科事典（baike.eastmoney.com / baike.baidu.com）で、中国人民銀行の公式文書 URL は【要確認】のまま | [sources.md:106](../90-data/sources.md) S-059 に「補助：https://www.dongao.com/…」／`:108` S-061「（URL 要確認：文号 512 号、第 60 条…）」／`:121` S-067「baike.eastmoney.com…中国人民銀行（公式文件 URL【要確認】）」 | ①補助リンクを政府・公的機関の URL に差し替え（または削除）。②512 号の公式 URL を確定。③CNAPS は中国人民銀行の公式規則 URL を確定し、百科事典は補助に降格 | 出典の信頼性が下がり、監査・対日レビューで「実データの根拠が二次情報」と指摘される。設計自体への影響は軽微 |
| REV-FIN-016 | S4 | `02-mdm/00-overview.md:296,318`、`02-mdm/90-db-design.md:783-807,1201-1213`（対照：`07-finance/90-db-design.md` の `fin_bank_account`） | **自社（会社）銀行口座の主データ所有が未定義。** MDM は `mdm_bank`（銀行）と `mdm_partner_bank_account`（取引先口座）のみで、会社自身の口座マスタが無い。FIN は `fin_bank_account`（口座・対応科目・対账設定・CNAPS）を独自に持つ設計で、両者をつなぐ契約（同一銀行の `mdm_bank.id` 参照、CNAPS の二重保持回避）が明記されていない | [MDM 00-overview.md:296](../02-mdm/00-overview.md) `mdm_partner_bank_account`（取引先银行账户）／`:318` `mdm_bank`（银行）／[MDM 90-db:783-807](../02-mdm/90-db-design.md) partner bank のみ／[07-finance/90-db-design.md](../07-finance/90-db-design.md) `fin_bank_account` に `cnaps_code` を保持 | 自社口座は FIN 所有と明記し、`fin_bank_account.bank_id → mdm_bank.id` の参照を契約化。または MDM に `mdm_company_bank_account` を新設し FIN は参照のみ | 口座マスタの二重管理・CNAPS の不整合。銀企連携（INT）と対账の口座キーが一致しないリスク |

---

## 4. 検証して問題なかった項目（カバレッジ証跡）

### 4.1 ファイル・データカバレッジ（37/37）

| # | 対象 | 検査方法 | 結果 |
|---|---|---|---|
| 1 | `02-mdm/00-overview.md` | 精読（機能・組織・表・イベント契約） | 機能 25・画面 53・表 53・IF 7。E39〜E42 の追補が 09 §3 と一致。**指摘なし**（S4-016 の当事者） |
| 2 | `02-mdm/01-material-master.md` | 部分精読＋財務視図 grep | `cost_method`（:224）、`purchase_tax_code`/`sales_tax_code`（:157/:168）、`inventory/revenue/cogs_account_code`（:217-219）を確認。**指摘：REV-FIN-011** |
| 3 | `02-mdm/02-business-partner.md` | 部分精読（財務・与信・銀行章） | `ar_account_code`/`ap_account_code`（:262/:329）、開票 4 要素、口座変更 WF を確認。**指摘なし** |
| 4 | `02-mdm/03-warehouse-location.md` | grep（倉庫コード・未決） | WH+/庫位コード規則を確認。**指摘：REV-FIN-013** |
| 5 | `02-mdm/04-uom-currency-tax.md` | 精読（税码・単位・通貨章） | 業務税码・`tax_type` 10/11/20/30/40/50、11 換算グループ、E40/E41 を確認。**指摘なし**（REV-FIN-003/007 の参照元） |
| 6 | `02-mdm/05-price-settlement.md` | 部分精読（決済・銀行・API） | `mdm_settlement_method`/`mdm_payment_term`/`mdm_bank`、CNAPS 12 桁チェックを確認。**指摘：REV-FIN-002（CNAPS 呼称）** |
| 7 | `02-mdm/06-credit-supplier-eval.md` | grep（与信限度・E42・WF） | 与信限度 1 顧客 1 レコード・E42 発行・A20 承認を確認。**指摘なし** |
| 8 | `02-mdm/07-substitute-barcode-governance.md` | grep（機能・条码・代替） | F-MDM-016〜023 の機能範囲、GS1・条码規則の前提を確認。**指摘なし**（財務影響なし） |
| 9 | `02-mdm/90-db-design.md` | 機械照合（DDL 53 表・共通列・索引） | `mdm_bank`/`mdm_tax_code`/`mdm_payment_term`/`mdm_partner_bank_account`/`mdm_exchange_rate` の DDL を突合。**指摘：REV-FIN-002/003/004/009/016** |
| 10 | `02-mdm/91-api-design.md` | grep（material/tax-codes/uom/bank API） | 材料・税码（`GET /api/mdm/tax-codes/{code}`）・UOM API を確認。**指摘なし** |
| 11 | `02-mdm/92-report-batch-design.md` | 行数集計 | PRT-MDM 15・BAT-MDM 10 を確認。財務帳票との重複なし。**指摘なし** |
| 12 | `02-mdm/93-messages.md` | 機械照合（MSG 重複） | `MSG-MDM-*` ユニーク 105 件を確認、形式違反なし。**指摘なし** |
| 13 | `02-mdm/94-sample-data.md` | 精読（物料・税码・価格・科目） | 代表サンプル・価格・税码例を確認。**指摘：REV-FIN-004（55 件）** |
| 14 | `00-common/06-code-list.md` | 全 393 行精読＋CSV 突合 | 通貨 20・国 20・単位 21・税 21・決済 18・Incoterms 11・WC12・分類 28・1411 を確認。**指摘：REV-FIN-006/007/008/012** |
| 15 | `90-data/README.md` | 精読（ファイル索引・件数・区分） | 23 ファイル索引・区分・利用先を確認。**指摘：REV-FIN-004/005** |
| 16 | `90-data/sources.md` | 全 204 行精読＋Web 照合 | S-001〜S-134（ユニーク 103）、参照日 2026-10-20、未確認一覧 11 件を確認。**指摘：REV-FIN-001/006/015** |
| 17 | `90-data/material-master.csv` | 全 54 行精読＋標準突合 | 牌号・執行標準・供給源・価格区分を確認。**指摘：REV-FIN-010** |
| 18 | `90-data/customer-master.csv` | 全 12 行精読 | 実在企業の公開情報＋示例関係、全行に「示例データ」注記あり。個人情報・口座なし。**指摘なし** |
| 19 | `90-data/supplier-master.csv` | 全 22 行精読 | 同左。全行に「示例データ」注記あり。**指摘なし** |
| 20 | `90-data/accounting-subjects.csv` | 全 86 行（科目コード・補助核算） | CAS 科目コード・残高方向・補助核算・出典列を確認。06 §12 の 1411/6901 も整合。**指摘なし**（行数記述は REV-FIN-005） |
| 21 | `90-data/demo-company.md` | 部分精読（組織・拠点・会計政策・KPI） | CZ01/WX01・D010〜080・WH01〜03・会計政策・KPI を確認。**指摘なし** |
| 22 | `90-data/approval-matrix.md` | grep（A01〜A20・財務承認） | APR-PA/A11〜A13（5 万/50 万閾値）ほか 08 §8.1 と一致。**指摘なし** |
| 23 | `90-data/bom-demo.md` | grep（材料・標準） | BOM 45 点・標準号 S-IDs を確認。**指摘なし**（財務側の原価例との差異は R-production-designer が指摘済み） |
| 24 | `90-data/routing-demo.md` | grep（WC・工賃率・標準） | WC001〜012・工賃率 28〜38 元/h・設備を確認。**指摘：REV-FIN-012（WC 名称）** |
| 25 | `code-lists/currency.csv` | 全 20 行精読 | ISO 4217 数値コード・小数桁（JPY/VND=0）を確認。**指摘なし** |
| 26 | `code-lists/country.csv` | 全 20 行精読 | ISO 3166-1 alpha-2/3 を確認。**指摘：REV-FIN-014（表記）** |
| 27 | `code-lists/region.csv` | 全 41 行精読 | GB/T 2260 コード（3204/320412/320206 等）を確認。**指摘：REV-FIN-014** |
| 28 | `code-lists/uom.csv` | 全 21 行精読 | UN/ECE Rec20・11 換算グループ・基本単位を確認。**指摘：REV-FIN-007** |
| 29 | `code-lists/tax.csv` | 全 21 行精読＋Web 照合 | 税率 13/9/6/3/1/0、附加 7/3/2、CIT 25/15/5、印花 0.3‰/1‰/0.25‰ を確認。**指摘：REV-FIN-001/008** |
| 30 | `code-lists/payment-terms.csv` | 全 18 行精読 | 決済 10・支払条件 8 を確認。**指摘：REV-FIN-009** |
| 31 | `code-lists/incoterms.csv` | 全 11 行精読 | Incoterms 2020 の 11 規則（DPU 改称、CIP 保険 ICC(A)、CIF ICC(C)）を確認。**指摘なし** |
| 32 | `code-lists/bank.csv` | 全 9 行精読 | 銀行 5・行別分類 4。**指摘：REV-FIN-002** |
| 33 | `code-lists/hs-code.csv` | 全 24 行精読 | 8501.52/8501.53/7225.19/8544.11/8482.10/7318.15 等の HS 2022 区分を確認。**指摘なし** |
| 34 | `code-lists/material-category.csv` | 全 28 行精読 | 分類 28・大分類 10/20/30/40/50/60/70/90・`default_account` 1403/1405/1408/1411 を確認。06 §11 と一致。**指摘なし** |
| 35 | `code-lists/approval-matrix.csv` | 全 24 行精読 | 08 §8.1 の A01〜A20 と一致。**指摘なし** |
| 36 | `code-lists/batch-number-rule.csv` | 全 5 行精読 | 批号・序列号の採番規則（示例）を確認。**指摘なし** |
| 37 | `code-lists/warehouse-location.csv` | 全 20 行精読 | 倉庫 3・庫区 11・庫位 6。WH01〜03 は demo-company と一致。**指摘なし** |

### 4.2 Web 照合の実施結果（参照日 2026-10-20）

| # | 検証対象 | 結果 | 参照 URL |
|---|---|---|---|
| 1 | GB/T 6109.5-2025（漆包円繞組線 180 級） | **実在**（2025 版の存在を確認） | https://www.ndls.org.cn/standard/detail/ffdbfb7fe7eb8e094275945671277a7d |
| 2 | GB/T 5782-2025（六角頭ボルト） | **実在**（2025 版を確認） | https://ndls.cnis.ac.cn/standard/detail/a052c1f6080bc37e5dc492a52acab501 |
| 3 | GB/T 4772.1-2025（回転電機寸法） | **実在**（openstd に 2025 版） | https://openstd.samr.gov.cn/bzgk/std/newGbInfo?hcno=F73B9C003AF65924C8F2F37F58CC42A5 |
| 4 | GB/T 93-2025（バネ座金） | **実在** | https://www.spc.org.cn/online/1695aad378704e588819b9f77d874992.html |
| 5 | GB/T 28575-2020（YE3 シリーズ技術条件） | **実在** | https://www.spc.org.cn/online/9b9fcc5308a20bd9eb2939c8679de21a.html |
| 6 | GB/T 1032-2023（三相誘導電動機試験方法） | **実在** | https://openstd.samr.gov.cn/bzgk/std/newGbInfo?hcno=46417B7B778C6036D40BEA7403A93733 |
| 7 | GB/T 9439-2023（ねずみ鋳鉄品） | **実在** | https://www.ndls.org.cn/standard/detail/0c483795211c9e5f664e51ebaa8fbd93 |
| 8 | 国家税務総局公告 2024 年第 11 号（数電票） | **実在**（2024 年 11 月公開の公告ページを確認。公布日・施行日の詳細は sources.md 記載） | https://www.gov.cn/zhengce/zhengceku/202411/content_6989164.htm ／ https://tianjin.chinatax.gov.cn/11200000000/0300/030004/03000418/20241125102212175.shtml |
| 9 | 財政部 税務総局公告 2023 年第 19 号（小規模納税人 1% 優遇） | **実在** | https://www.gov.cn/zhengce/zhengceku/202308/content_6896287.htm |
| 10 | 財綜〔2010〕98 号（地方教育附加の統一） | **実在** | https://fgk.chinatax.gov.cn/zcfgk/c102416/c5194201/content.html |
| 11 | 会計档案管理办法（79 号令）・保管期限 30 年 | **実在**（公知の法令。URL は sources.md 記載。独立取得は未実施） | https://www.gov.cn/gongbao/content/2016/content_5041555.htm |
| 12 | GB/T 12406-2022（表示貨幣コード） | **実在** | https://www.spc.org.cn/online/50f9672917aaa66298e89159837b245c.html |
| 13 | 中華人民共和国増値税法（2026-01-01 施行） | **実在**（設計日時点で現行法。tax.csv は旧条例を引用＝REV-FIN-001） | http://m.mof.gov.cn/czxw/202412/t20241225_3950444.htm |
| 14 | 中華人民共和国関税法（2024-12-01 施行） | **実在**（同上） | https://www.gov.cn/yaowen/liebiao/202412/content_6990667.htm |
| 15 | CNAPS 行号 12 桁の構成（3+4+4+1） | **整合**（百科事典ベース。公式 URL は未取得＝§5） | https://baike.baidu.com/item/cnaps%E8%A1%8C%E5%8F%B7/50975481 |

> 税率の**値**（VAT 13/9/6/0・徴収率 3%、城建税 7/5/1、教育費附加 3%、地方教育附加 2%、CIT 25/15/実効 5%、印花税 0.3‰/1‰/0.25‰）は、上記の法令・公告及び公知の税制と矛盾しないことを確認した。**「値は正しいが根拠法令が旧い」**のが REV-FIN-001 の要点である。

### 4.3 財務が必要とする MDM 項目の充足確認

| # | FIN の必要項目 | MDM の実装 | 判定 |
|---|---|---|---|
| 1 | 税码（销项/进项、tax_type、税率、有効期間） | `mdm_tax_code`（`tax_rate_code`/`tax_type`/`is_tax_included`/valid）＋`mdm_tax_rate`。業務税码の全件は REV-FIN-003 | ○（全件リストは△） |
| 2 | 物料の成本核算方法（品種法/分批法） | `mdm_material.cost_method`（01:224、90-db:284） | ○ |
| 3 | 科目マッピング（在庫/売上/原価、AR/AP） | `inventory_account_code`/`revenue_account_code`/`cogs_account_code`（01:217-219）、`ar_account_code`/`ap_account_code`（02:262/329） | ○ |
| 4 | 単位換算（購入/在庫/販売単位、換算率） | `mdm_uom`/`mdm_uom_conversion`＋uom.csv 21 件。基本単位の記述差異は REV-FIN-007 | ○（記述は△） |
| 5 | 通貨・為替レート（Phase 2） | `mdm_currency`/`mdm_exchange_rate`（rate_type SPOT/PERIOD/AVG） | ○ |
| 6 | 決済方式・支払条件（NET30 等） | `mdm_settlement_method`/`mdm_payment_term`＋CSV 18 件。マッピングは REV-FIN-009 | ○（マッピングは△） |
| 7 | 取引先銀行口座（CNAPS） | `mdm_partner_bank_account`（`cnaps_code` 12 桁、変更 WF） | ○ |
| 8 | 自社銀行口座（FIN の `fin_bank_account` と同一キー） | MDM に無し（FIN 独自） | △（REV-FIN-016） |
| 9 | 与信限度・与信状態（SAL と共用） | `mdm_credit_limit`（限度/単一受注上限/状態、E42） | ○ |
| 10 | 補助核算の対象マスタ（顧客/仕入先/部門/員工/項目/物料/倉庫/税種） | 顧客・仕入先・物料・倉庫・税種は MDM。部門は SYS、員工は SYS 用户（専用員工マスタは無し）、項目は `mdm_project`（Phase 2 予約） | ○（員工/項目は△・Phase2） |
| 11 | 税区分イベント（税率改定の通知） | E40 `mdm.tax-code.changed`（09 §3） | ○ |
| 12 | 与信・為替イベント | E42/E41（09 §3） | ○ |

### 4.4 実在企業データの適法性・表示

| 検査 | 結果 |
|---|---|
| 顧客 12 件・仕入先 22 件の全行に「示例データ、商業関係なし」の注記があるか | **あり（12/12、22/22）**。個人情報・連絡先・銀行口座は非収録（CSV ヘッダに該当列なし） |
| sources.md §5 の実在企業・股票コード | 主要 20 社（宝鋼 600019、首鋼 000959、馬鋼 600808、江西銅業 600362、銅陵有色 000630、精達 600577、長城科技 603897、中信特鋼 000708、日月 603218、吉鑫 601218、晋億 601002、長華 605018、東材 601208、正泰 601877、合興 002228、中国鋁業 601600、祥明 301226、今創 603680、常柴 000570、陝鼓 601369、開山 300257、漢鐘 002158、双環 002472、南方中金 300145、恒立 601100、国茂 603915、中聯 000157、三一 600031）は公開知識と矛盾なし。**独立 URL 取得は未実施（§5）** |
| 「実データ」表示の標準号・税率・科目 | 抽查 15 件（§4.2）で**虚偽なし**。標準の現行版（2025 年版）も実在を確認 |

---

## 5. 未検証範囲・制約

1. **02-mdm 全 13 ファイルの完全精読は未実施**（合計約 600KB）。`01-material-master.md`（77.8KB）・`02-business-partner.md`（56.5KB）・`90-db-design.md`（96.8KB）は関連章の部分精読＋grep に留めた。指摘は当該箇所に限定され、他の章の品質は保証しない。
2. **公式 1 次資料の本文取得は一部未実施**：中国人民銀行 CNAPS 公式文書、全国標準情報公共サービスプラットフォームの詳細ページ（GB/T 6109.5-2025 等）は検索結果 URL のみで本文を取得していない。また ISO 4217 の SIX Group XML・UN/ECE Rec20 PDF も sources.md 記載 URL の信頼に留めた。
3. **03-sales／04-purchase／05-inventory／06-production は対象外**のため一次資料未読。FIN 経由（09 契約・90-data）の間接確認のみ。REV-FIN-001 の税率影響、REV-FIN-003 の SAL/PUR 側利用実装は当該域と合同で確認が必要。
4. **税の実務細則（1% 優遇の 2026 年以降の継続、地方教育附加の江蘇省根拠文書、数電票の最新様式）**は sources.md の【要確認】11 件と重複する。本レビューでは「公告の実在」まで確認し、細則の最終確定は data-researcher の責務とした。
5. **実在企業の公開情報（股票コード等）**は公開知識と照合したが、各社公式サイト・巨潮資訊網の個別ページ取得は未実施。誤りを断定しない。
6. **指摘 REV-FIN-010（木箱の執行標準）**の代替標準（GB/T 12464/7284 等）は「木箱の製品規格である」ことまで確認したが、**番号・最新版の確定は未実施**（未確認と明記）。修正時に data-researcher が確定すること。

---

## 6. 総評（実装可否判断）

**判定：条件付可（実装前に S2 の 3 件を必須修正）**

- **良い点**：02-mdm は財務が必要とする主データ（税码の方向/税種、`cost_method`、科目マッピング、決済・支払条件、CNAPS、通貨・為替、与信）を高い網羅性で定義しており、E39〜E42 のイベント契約も 09 と整合している。90-data は CAS 科目 86 件・標準規格・税率・ISO コード・HS コード・実在企業情報を出典付きで整備しており、Web 抽查 15 件で**虚偽の「実データ」表示は検出されなかった**。分類 28／単位 21／税 21／決済 18／WC 12／1411 の要件も充足している。
- **最大のリスク**：①**税の根拠法令が旧法（增值税暂行条例・进出口关税条例）**のまま（REV-FIN-001）。税率値は正しいが、法令根拠として 2026 年時点で不適切であり、税務設計・監査に直結する。②**銀行マスタの CSV と DDL の不整合**（REV-FIN-002）と **業務税码 60 件の全件未定義**（REV-FIN-003）は、MDM シードと FIN 自動凭证の実装を止める。
- **データ品質**：件数（物料 53/54/55、科目 75/86、出典 130/103、サイズ 190/175KB）と標準の適用（木箱の GB/T 191、旧版 5782-2016）に、**「正本が CSV なのに設計書側の記述が追随していない」**パターンが集中している。CSV を正として設計書を機械的に再生成・照合する仕組み（件数・標準号の自動チェック）を推奨する。
- **次ラウンドへの引継ぎ**：S2 3 件の修正後に再レビュー。S3 10 件は実装開始までに、S4 3 件は未決事項または Phase 2 課題として記録すればよい。なお、財務域側で本レビューと同根の指摘（税根拠法令・業務税码）は、07-finance の改訂時に併せて反映する必要がある（本レビューでは指摘のみで設計変更は行っていない）。

---

## 7. 改訂履歴

| 版数 | 日付 | 変更内容 | 変更者 |
|---|---|---|---|
| v1.0 | 2026-10-20 | 初版：02-mdm 13＋06-code-list＋90-data 23 の計 37 対象をレビュー。指摘 16 件（S1:0／S2:3／S3:10／S4:3）、カバレッジ 37/37、Web 照合 15 件（URL・参照日付き）、財務要件充足表、未検証範囲、総評 | finance-designer |
