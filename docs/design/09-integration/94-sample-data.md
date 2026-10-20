# 集成管理 样例数据说明（集成管理 サンプルデータ説明）

| 項目 | 内容 |
|---|---|
| 文書名 | 集成管理 样例数据说明（集成管理 サンプルデータ説明） |
| 文書番号 | DSN-INT-094 |
| 版数 | v1.0 |
| 作成日 | 2026-10-20 |
| 作成者 | integration-designer（集成分野担当） |
| 承認者 | 未承認（レビュー待ち） |
| 状態 | ドラフト（レビュー中） |
| 参照日 | 2026-10-20 |
| 関連文書 | [業務域概要](00-overview.md) / [税銀 IF](02-tax-bank-interface.md) / [製造連携](03-mes-wms-plm.md) / [開放 API](04-openapi-file-notify.md) / [90-data データ地図](../90-data/README.md) / [出典一覧](../90-data/sources.md) |

---

## 1. 本域で使用する実データと出典

本域のサンプルは、**実データ（法令・標準・コード）**と**示例値（企業内部の架空データ）**を明確に区別する。実データの URL・参照日は [90-data/sources.md](../90-data/sources.md) を正とし、本文では出典 ID のみを示す。

| # | 資料 | 出典 ID | 本域での用途 | 区分 |
|---|---|---|---|---|
| 1 | 国家税务总局公告 2024 年第 11 号（数电票） | S-050 | 数电票の票面要素・交付・赤伝の設計 | 【実データ】 |
| 2 | 财政部 税务总局 海关总署公告 2019 年第 39 号（増値税 13% 等） | S-051 | 税率・税額計算 | 【実データ】 |
| 3 | CNAPS 聯行号（3+4+4+1＝12 桁） | S-067 | 銀行口座・振込先の聯行号検証 | 【実データ】 |
| 4 | ISO 4217 通貨コード | S-064 | 通貨（CNY） | 【実データ】 |
| 5 | 中国海関 HS コード（HS 2022／中国税則 10 桁） | S-068 | 数电票明細の HS コード（輸出・P2） | 【実データ】 |
| 6 | 企業会计准则（CAS）科目 | S-060 | 対账・仕訳連携の科目コード | 【実データ】 |
| 7 | 銀行名・行別コード | [bank.csv](../90-data/code-lists/bank.csv) | 口座・振込先の銀行選択 | 【実データ】（聯行号は虚构示例） |
| 8 | 税目・税率 | [tax.csv](../90-data/code-lists/tax.csv) | 数电票の税率・税目 | 【実データ】（VAT1/EDU2 は【要確認】） |
| 9 | HS コード | [hs-code.csv](../90-data/code-lists/hs-code.csv) | 数电票明細（輸出） | 【実データ】 |
| 10 | 物料マスタ | [material-master.csv](../90-data/material-master.csv) | 数电票・MES・PLM の品目コード | 【実データ】牌号＋【示例値】価格 |
| 11 | 顧客・仕入先マスタ | [customer-master.csv](../90-data/customer-master.csv)、[supplier-master.csv](../90-data/supplier-master.csv) | 購買方・受取人 | 【公開情報】企業名＋【示例値】取引条件 |
| 12 | 示例企業画像 | [demo-company.md](../90-data/demo-company.md) | 口座・組織・取引条件 | 【示例値】 |
| 13 | BOM・工程路線 | [bom-demo.md](../90-data/bom-demo.md)、[routing-demo.md](../90-data/routing-demo.md) | MES 工单下发・報工 | 【実データ】材料標準＋【示例値】数量・工時 |

> **注記**：実在企業名は公開情報としてのみ使用し、**「示例数据，仅用于设计验证，不代表任何商业关系」**を併記する。連絡先・担当者・口座番号・統一社会信用コードは記載しない。

---

## 2. サンプルデータ一覧と利用場面

| # | サンプル | 利用場面 | 主要な値 | 区分 |
|---|---|---|---|---|
| 1 | 数电票（藍字・専票） | IF-INT-002 開票 | YE3-100L1-4 × 120 PCE、税率 13% | 【示例値】（税率は実データ） |
| 2 | 数电票（紅字） | IF-INT-002 赤伝 | 元発票の全額赤伝 | 【示例値】 |
| 3 | 進項発票 | IF-INT-008 査験 | 電工鋼の仕入発票 | 【示例値】 |
| 4 | 銀企付款指令 | IF-INT-001 送信 | 仕入先への電匯 500,000 元 | 【示例値】 |
| 5 | 銀行対账单（CSV） | IF-INT-006 取込 | 2026-10-20 の 128 行 | 【示例値】 |
| 6 | MES 工单下发 | IF-INT-003 送信 | WO2610200001、120 PCE | 【示例値】（品目は実データ） |
| 7 | MES 報工回伝 | IF-INT-003 受信 | 良品 118、不良 2、工数 6.5h | 【示例値】 |
| 8 | PLM BOM 差分 | IF-INT-004 取込 | BOM-3001000001-V01 | 【実データ】構造＋【示例値】数量 |
| 9 | PDA スキャン | IF-INT-010 | 入庫 50 PCE、批次 261020P001 | 【示例値】 |
| 10 | 開放 API 受注 | IF-INT-009 | 顧客 C000123、120 PCE | 【示例値】 |
| 11 | 通知（承認依頼） | IF-INT-011 | 件名・本文・宛先 | 【示例値】 |

---

## 3. サンプル詳細

### 3.1 数电票（藍字・専票）【示例値】

```json
{
  "invoiceReqNo": "INVREQ2610200001",
  "invoiceType": 10,
  "invoiceKind": 30,
  "sellerName": "华东精密电机股份有限公司",
  "sellerTaxNo": "91320400XXXXXXXXXX",
  "buyerName": "常州泵业有限公司",
  "buyerTaxNo": "91320400YYYYYYYYYY",
  "sourceType": "SALES_DELIVERY",
  "sourceNo": "DN2610200001",
  "currencyCode": "CNY",
  "amount": "102780.00",
  "taxRate": "13.0000",
  "taxAmount": "13361.40",
  "totalAmount": "116141.40",
  "lines": [
    {
      "lineNo": 10,
      "materialCode": "3001000001",
      "itemName": "YE3-100L1-4 三相异步电动机",
      "spec": "2.2kW 380V 50Hz IP55 B3",
      "uomCode": "PCE",
      "quantity": "120.0000",
      "unitPrice": "856.500000",
      "amount": "102780.00",
      "taxRate": "13.0000",
      "taxAmount": "13361.40",
      "taxClassificationCode": "1090101010000000000"
    }
  ]
}
```

> 税号・税收分类编码は【示例値】（マスキング）。金額は [08 §4.3](../00-common/08-common-business-rules.md) の計算例と一致。税率 13% は【実データ】S-051。税收分类编码の実際の値は導入時に税局の最新コード表から取得する（本設計では固定しない）。

### 3.2 銀企付款指令【示例値】

```json
{
  "paymentNo": "PAY2610200001",
  "bankAccountId": "1845678901234567801",
  "payeeName": "宝山钢铁股份有限公司",
  "payeeAccountMasked": "**** **** 1234",
  "payeeBankCode": "102304000001",
  "payeeBankName": "中国工商银行常州分行营业部",
  "amount": "500000.00",
  "currencyCode": "CNY",
  "purpose": "2026年10月电工钢货款",
  "paymentMode": 10,
  "idempotencyKey": "PAY2610200001"
}
```

> 振込先は公開情報の企業名（【公開情報】S-101）。口座番号は脱敏示例。聯行号 `102304000001` は 12 桁構造を示す**虚构示例**（[bank.csv](../90-data/code-lists/bank.csv) の注記どおり）。

### 3.3 銀行対账单（CSV・【示例値】）

```csv
bank_account_no,value_date,amount,balance,currency,summary,counterparty_name,bank_serial_no
1105****5678,2026-10-20,-500000.00,3250000.00,CNY,电汇,宝山钢铁股份有限公司,ICBC20261020000123
1105****5678,2026-10-20,116141.40,3366141.40,CNY,货款,常州泵业有限公司,ICBC20261020000124
```

| 列 | 説明 | 検証 |
|---|---|---|
| `bank_account_no` | 口座番号（マスク） | 取込時に復号して照合 |
| `value_date` | 起算日 | `yyyy-MM-dd` |
| `amount` | 入出金（出金は負） | 小数 2 桁 |
| `balance` | 残高 | 小数 2 桁 |
| `currency` | 通貨 | ISO 4217 |
| `summary` | 摘要 | 自由記述（200 字以内） |
| `counterparty_name` | 相手先 | 取引先マスタと照合（任意） |
| `bank_serial_no` | 銀行流水番号 | 一意（重複排除） |

> 文字コードは UTF-8 を既定、国内銀行の GBK はレイアウト定義で指定する。ヘッダ行の列名はレイアウト定義（`columns_json`）と一致すること。

### 3.4 MES 工单下发【示例値】

```json
{
  "workOrderNo": "WO2610200001",
  "workOrderVersion": 1,
  "materialCode": "3001000001",
  "materialName": "YE3-100L1-4 三相异步电动机",
  "spec": "2.2kW 380V 50Hz IP55 B3",
  "uomCode": "PCE",
  "orderQty": "120.0000",
  "factoryCode": "CZ01",
  "plannedStartDate": "2026-10-21",
  "plannedEndDate": "2026-10-25",
  "priorityNo": 3,
  "bomNo": "BOM-3001000001-V01",
  "routingNo": "RT-3001000001-V01",
  "materials": [
    { "materialCode": "1001000001", "requiredQty": "1.8500", "uom": "KGM", "warehouseCode": "WH01" },
    { "materialCode": "1004000001", "requiredQty": "2.1000", "uom": "KGM", "warehouseCode": "WH01" },
    { "materialCode": "4001000001", "requiredQty": "2.0000", "uom": "PCE", "warehouseCode": "WH01" }
  ],
  "operations": [
    { "seq": 10, "operationCode": "WC001", "workCenterCode": "WC001", "standardHours": "0.20" },
    { "seq": 20, "operationCode": "WC002", "workCenterCode": "WC002", "standardHours": "0.15" },
    { "seq": 30, "operationCode": "WC004", "workCenterCode": "WC004", "standardHours": "0.60" }
  ],
  "salesOrderNo": "SO2610200001",
  "remark": "【示例値】10月度 标准机备货"
}
```

> 品目コード・BOM・工程は [material-master.csv](../90-data/material-master.csv)、[bom-demo.md](../90-data/bom-demo.md)、[routing-demo.md](../90-data/routing-demo.md) に基づく。必要量・工時は【示例値】。

### 3.5 MES 報工回伝【示例値】

```json
{
  "reportNo": "MESWR2610200001",
  "workOrderNo": "WO2610200001",
  "operationSeq": 50,
  "reportDate": "2026-10-22",
  "shiftCode": "A",
  "inputQty": "120.0000",
  "goodQty": "118.0000",
  "defectQty": "2.0000",
  "scrapQty": "0.0000",
  "laborHours": "6.50",
  "machineHours": "4.00",
  "operatorCode": "E000123",
  "defects": [
    { "defectCode": "D010", "qty": "2.0000", "causeCode": "WINDING" }
  ],
  "reportedAt": "2026-10-22T17:30:00+08:00"
}
```

### 3.6 開放 API 受注【示例値】

```json
{
  "externalNo": "CUST-PO-20261020-001",
  "customerCode": "C000123",
  "orderDate": "2026-10-20",
  "deliveryDate": "2026-11-05",
  "currencyCode": "CNY",
  "lines": [
    { "materialCode": "3001000001", "quantity": "120.0000", "uomCode": "PCE", "unitPrice": "856.500000" }
  ]
}
```

### 3.7 通知（承認依頼）【示例値】

```text
件名：【Stellar ERP】审批待办：销售订单 SO2610200001
本文：
{z} 您好：
销售订单 SO2610200001（客户：常州泵业有限公司，金额：CNY 116,141.40）已提交审批，请于 2026-10-22 前处理。
审批链接：https://erp.example.com/workflow/tasks/{taskId}（ドメインは【示例値】）
```

### 3.8 PDA スキャン【示例値】

```json
{
  "deviceCode": "PDA-WH01-001",
  "batchNo": "OFFLINE-20261020-0001",
  "seqNo": 1,
  "scanType": 10,
  "barcode": "3001000001|261020P001|WH01-A-01-02-03|50",
  "scannedAt": "2026-10-20T09:15:00+08:00",
  "operatorCode": "E000123"
}
```

> バーコード形式は「物料コード|批次|庫位|数量」の内部規約（【示例値】）。Code 128 を既定とする（【実データ】GB/T 18347-2001、S-046）。

### 3.9 PLM BOM 差分（取込サンプル・【示例値】）

```json
{
  "changeNo": "ECN-2026-0042",
  "changeType": "BOM",
  "effectiveFrom": "2026-11-01",
  "parentMaterialCode": "3001000001",
  "bomNo": "BOM-3001000001-V02",
  "versionNo": 2,
  "lines": [
    { "seq": 10, "childMaterialCode": "1001000001", "requiredQty": "1.8500", "uom": "KGM", "lossRate": "0.0200", "substituteFlag": false },
    { "seq": 20, "childMaterialCode": "1004000001", "requiredQty": "2.1000", "uom": "KGM", "lossRate": "0.0150", "substituteFlag": false },
    { "seq": 30, "childMaterialCode": "4001000001", "requiredQty": "2.0000", "uom": "PCE", "lossRate": "0.0000", "substituteFlag": true }
  ],
  "reason": "【示例値】轴承供应商变更，同步替代料"
}
```

> 親子コードは [material-master.csv](../90-data/material-master.csv)、BOM 構成は [bom-demo.md](../90-data/bom-demo.md) に基づく。数量・損耗率は【示例値】。取込後は「承認待ち」となり、技術部の承認で有効化される（[03 §6](03-mes-wms-plm.md)）。

### 3.10 進項発票（査験サンプル・【示例値】）

```json
{
  "invoiceCode": "032002600111",
  "invoiceNo": "26322000000098765432",
  "invoiceDate": "2026-10-15",
  "invoiceType": 20,
  "sellerName": "宝山钢铁股份有限公司",
  "sellerTaxNo": "91310000XXXXXXXXXX",
  "buyerName": "华东精密电机股份有限公司",
  "buyerTaxNo": "91320400XXXXXXXXXX",
  "amount": "442477.88",
  "taxRate": "13.0000",
  "taxAmount": "57522.12",
  "totalAmount": "500000.00",
  "usageStatus": 10
}
```

> 企業名は【公開情報】（S-101）。税号・発票番号は【示例値】（マスキング）。金額は 500,000 元（税込）に対応する税抜・税額の示例。査験結果は「一致（`verify_status=20`）」を想定するが、実データではない。

### 3.11 サンプルの検証方法

| # | 検証 | 方法 | 合格条件 |
|---|---|---|---|
| 1 | 金額整合 | 税抜 + 税額 = 税込 | 一致（小数 2 桁） |
| 2 | 税率 | [tax.csv](../90-data/code-lists/tax.csv) に存在 | 存在する |
| 3 | 物料コード | [material-master.csv](../90-data/material-master.csv) に存在 | 存在する |
| 4 | 顧客・仕入先 | customer/supplier-master.csv に存在 | 存在する |
| 5 | 聯行号 | 12 桁数字、[bank.csv](../90-data/code-lists/bank.csv) の行別コードと整合 | 形式合格（実在性は問わない） |
| 6 | 税号 | 18 桁（マスク済みは除く） | 形式合格 |
| 7 | 日付 | `yyyy-MM-dd`、業務期間内 | 形式合格 |
| 8 | 区分数 | 数量・単価・金額の桁数 | [01 §6](../00-common/01-common-item-definitions.md) に一致 |

## 4. 仮定値（示例値）の一覧

| # | 項目 | 値 | 利用箇所 | 備考 |
|---|---|---|---|---|
| 1 | 受注数量 | 120 PCE | 数电票・MES・開放 API | YE3-100L1-4 |
| 2 | 税抜単価 | CNY 856.50 | 数电票・開放 API | [08 §4.3](../00-common/08-common-business-rules.md) と同一 |
| 3 | 税率 | 13% | 数电票 | 【実データ】S-051 |
| 4 | 税額 | CNY 13,361.40 | 数电票 | CALC-TAX-02 |
| 5 | 価税合計 | CNY 116,141.40 | 数电票 | CALC-TAX-03 |
| 6 | 付款金額 | CNY 500,000.00 | 銀企 | 仕入先への電匯 |
| 7 | 対账单件数 | 128 行 | 対账单取込 | 1 日分 |
| 8 | 口座残高 | CNY 3,250,000.00 | 銀企 | 残高照会 |
| 9 | 報工工数 | 6.50 h | MES 報工 | 1 工序 |
| 10 | 良品/不良 | 118 / 2 PCE | MES 報工 | 良品率 98.3% |
| 11 | 聯行号 | `102304000001` | 銀企 | 12 桁構造の示例（実在行番号ではない） |
| 12 | 購買方税号 | `91320400YYYYYYYYYY` | 数电票 | マスキング |
| 13 | 通知 URL | `https://erp.example.com/...` | 通知 | 導入時に実ドメインへ置換 |
| 14 | PDA 端末 | `PDA-WH01-001` | PDA | 現物端末 ID は導入時 |

---

## 5. 利用時の注意

1. **実データと示例値を混在させない**：税率・標準号・コードは実データ、金額・数量・工数は示例値。表中でも区分を明記する。
2. **マスタ整合**：物料コードは [material-master.csv](../90-data/material-master.csv)、顧客・仕入先コードは各 CSV に存在すること。存在しないコードをサンプルに使わない。
3. **税務・銀行の値は導入時に置換**：税收分类编码、口座番号、聯行号、銀行エンドポイントは実装時に正式値へ置換する。
4. **個人情報を含めない**：作業者コードは社員コードのみ。氏名・電話・メールはマスキング。
5. **原文の保存**：サンプルを実運用のテストデータに使う場合も、`int_external_message.payload` にはマスキング済みの値を保存する。

---

## 6. 未決事項

| # | 事項 | 理由 | 暫定仕様 | 担当 | 期限 |
|---|---|---|---|---|---|
| 1 | 税收分类编码の実値 | 税局コード表の入手が必要 | 導入時に `mdm_tax_code` へ登録し、サンプルを置換 | 財務 | 2026-11-30 |
| 2 | 数电票の票面サンプル（PDF） | 税局の交付仕様に依存 | 導入時に実発票で確認 | 財務 | 2026-12-15 |
| 3 | 銀行対账单の実レイアウト | 取引行ごとに異なる | レイアウト定義（CSV/Excel/MT940）で吸収 | integration | 2026-12-31 |
| 4 | MES の実ペイロード | ベンダー未選定 | 本サンプルを契約案として提示 | 生産 | 2026-12-15 |
| 5 | 公開企業名の利用範囲 | 商業関係の誤認防止 | 「示例数据」注記を必須とする | Lead | 2026-10-31 |

## 7. 改訂履歴

| 版数 | 日付 | 変更内容 | 変更者 |
|---|---|---|---|
| v1.0 | 2026-10-20 | 初版：実データ出典 13 件、サンプル 11 件、仮定値 14 件、利用注意 | integration-designer |
