# DB 共通规格（DB 共通仕様）

| 項目 | 内容 |
|---|---|
| 文書名 | DB 共通规格（DB 共通仕様） |
| 文書番号 | DSN-CMN-004 |
| 版数 | v1.0 |
| 作成日 | 2026-10-20 |
| 作成者 | Lead（设计基盤） |
| 承認者 | 未承認（社内レビュー待ち） |
| 状態 | ドラフト（レビュー中） |
| 関連文書 | [共通项目定义](01-common-item-definitions.md) / [RLS・DB ロール](10-rls-and-db-roles.md)（PR #43） / [ADR-0003](../../adr/0003-database.md) / [テーブル定義書テンプレート](../_template/03-table-definition-template.md) |

---

## 1. 前提

| 項目 | 内容 |
|---|---|
| DBMS | PostgreSQL 18.6（Docker イメージ `postgres:18.6`） |
| 文字コード | UTF-8、照合順序 `zh_CN.utf8` または `C`（環境に合わせる） |
| タイムゾーン | DB は UTC 保存、アプリは Asia/Shanghai で表示（`TIMESTAMPTZ` 使用） |
| データアクセス | MyBatis-Plus 3.5.17（単純 CRUD）+ JdbcClient/XML（複雑検索・レポート） |
| マイグレーション | Flyway（SQL スクリプト）。本設計書の DDL が正 |
| 拡張 | `pg_trgm`（名称曖昧検索）、GIN（JSONB）。RLS は第一版（首批業務テーブルと同時）、パーティション拡張は第一版 |
| 命名 | 小文字 snake_case。予約語との衝突を避ける |

## 2. テーブル命名規則

### 2.1 プレフィックス（モジュール別）

| プレフィックス | モジュール | 例 |
|---|---|---|
| `sys_` | system（用户/角色/菜单/组织/字典/参数/审计/附件/编号/通知/定时任务） | `sys_user`、`sys_role`、`sys_audit_log` |
| `mdm_` | 主数据 | `mdm_material`、`mdm_customer`、`mdm_warehouse` |
| `sal_` | 销售 | `sal_sales_order`、`sal_sales_order_line` |
| `pur_` | 采购 | `pur_purchase_order`、`pur_receipt` |
| `inv_` | 库存 | `inv_stock_balance`、`inv_stock_txn` |
| `prd_` | 生产 | `prd_work_order`、`prd_bom` |
| `fin_` | 财务 | `fin_voucher`、`fin_account_balance` |
| `wf_` | 工作流（业务侧扩展表；Flowable 引擎表 `ACT_`/`FLW_` は schema `flowable` に置き前缀は変更しない） | `wf_business_process` |
| `int_` | 集成 | `int_interface_config`、`int_api_call_log` |
| `rpt_` | 报表 | `rpt_kpi_snapshot` |

### 2.2 テーブル種別の命名

| 種別 | 命名 | 例 |
|---|---|---|
| マスタ | `{prefix}_{entity}`（単数形） | `mdm_customer` |
| 伝票ヘッダ | `{prefix}_{entity}` | `sal_sales_order` |
| 伝票明細 | `{prefix}_{entity}_line` | `sal_sales_order_line` |
| 履歴 | `{prefix}_{entity}_his` | `mdm_material_his` |
| 残高・在庫 | `{prefix}_{entity}_balance` | `inv_stock_balance` |
| 取引・流水 | `{prefix}_{entity}_txn` / `_log` | `inv_stock_txn`、`sys_audit_log` |
| 関連（多対多） | `{prefix}_{entity1}_{entity2}` | `mdm_customer_material` |
| 設定 | `{prefix}_{entity}_config` | `int_interface_config` |

### 2.3 カラム命名

| 種別 | 規則 | 例 |
|---|---|---|
| 主キー | `id` | `id` |
| 親参照 | `{parent}_id` | `sales_order_id` |
| マスタ参照 | `{entity}_id` + スナップショット `{entity}_code`/`{entity}_name` | `customer_id`、`customer_code`、`customer_name` |
| コード | `*_code` | `material_code`、`currency_code` |
| 名称 | `*_name` | `material_name` |
| 状態 | `*_status`（SMALLINT） | `order_status` |
| 区分 | `*_type`（SMALLINT or VARCHAR） | `txn_type`、`settlement_type` |
| 日付 | `*_date`（DATE） | `order_date`、`delivery_date` |
| 日時 | `*_at`（TIMESTAMPTZ） | `approved_at`、`posted_at` |
| 数量 | `*_qty`（NUMERIC） | `ordered_qty`、`received_qty` |
| 金額 | `*_amount`（NUMERIC(18,2)） | `tax_amount`、`total_amount` |
| 単価 | `*_price`（NUMERIC(18,6)） | `unit_price` |
| フラグ | `is_*` / `*_flag`（BOOLEAN） | `is_batch_managed` |
| 備考 | `remark` | — |
| 拡張 | `ext_data`（JSONB） | — |

禁止：意味のない省略（`qty1`、`amt2`、`flag3`）、型を名前に入れない（`name_str` 不可）、複数形（`materials` 不可）、大文字。

## 3. 共通カラム

すべての業務テーブルに [01 共通项目定义](01-common-item-definitions.md) 第 2 章の共通カラムを付与する。省略できるのは以下のみ。

| テーブル種別 | 省略可能カラム |
|---|---|
| 追記専用ログ（`*_log`、`*_txn` の監査系） | `updated_at`、`updated_by`、`version`、`deleted` |
| 集計・スナップショット | `version`（不要）、`deleted`（不要） |
| 明細テーブル | `remark` 以外は付与。`company_id` は省略不可（親と同値を冗長保持。2026-10-21 決定、06 と同じ書き方に全域統一） |
| 基盤テーブル（`sys_sequence`／`sys_outbox_event`／`sys_audit_log` 等） | `deleted`、`version` 等を用途に応じて省略可（**正本は各テーブル定義書**。採番・Outbox は論理削除しない） |

## 4. データ型マッピング

| PostgreSQL | Java | JSON | 用途 |
|---|---|---|---|
| `BIGINT` | `Long` | string | ID、件数 |
| `INT` | `Integer` | number | 版数、行番号、年 |
| `SMALLINT` | `Integer` | number | 状態・区分 |
| `VARCHAR(n)` | `String` | string | コード・名称・短いテキスト |
| `TEXT` | `String` | string | 長文（理由、メッセージ本文） |
| `NUMERIC(p,s)` | `BigDecimal` | string | 金額・数量・単価・率（01 第 6 章） |
| `DATE` | `LocalDate` | string(yyyy-MM-dd) | 業務日付 |
| `TIMESTAMPTZ` | `OffsetDateTime` | string(ISO) | システム日時 |
| `TIME` | `LocalTime` | string(HH:mm:ss) | 時刻 |
| `BOOLEAN` | `Boolean` | boolean | フラグ |
| `JSONB` | `String` / `Map` | object | 拡張項目・スナップショット |
| `BYTEA` | `byte[]` | — | バイナリ（原則使わない。ファイルは StorageService） |

- `VARCHAR` の長さは業務上の最大値 + 余裕（名称 200、コード 64、備考 500、理由 1000）。安易に `VARCHAR(4000)` を使わない。
- 金額・数量に `FLOAT`/`DOUBLE` を**使用禁止**。
- 状態・区分は `SMALLINT` + コメント。名称を DB に保存しない（マスタまたはコードで解決）。

## 5. 主キー・採番

- 主キーは `BIGINT` 雪花 ID（MyBatis-Plus `ASSIGN_ID`）。DB シーケンス・`SERIAL` は使わない。
- 業務番号（伝票番号・コード）は別カラム + 一意インデックス。採番は `sys_sequence` テーブルで管理する。

```sql
CREATE TABLE sys_sequence (
    id          BIGINT       NOT NULL,
    tenant_id   BIGINT       NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,
    company_id  BIGINT       NOT NULL,   -- 既定値なし（DEFAULT 1 禁止）
    sequence_key VARCHAR(64) NOT NULL,   -- 例 'SAL_SALES_ORDER'
    sequence_date DATE       NOT NULL,   -- 日次リセット用（月次は月初日）
    current_value BIGINT     NOT NULL DEFAULT 0,
    step        INT          NOT NULL DEFAULT 1,
    version     INT          NOT NULL DEFAULT 0,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_by  BIGINT       NOT NULL DEFAULT 0,
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_by  BIGINT       NOT NULL DEFAULT 0,
    CONSTRAINT pk_sys_sequence PRIMARY KEY (id),
    CONSTRAINT uk_sys_sequence_key_date UNIQUE (tenant_id, company_id, sequence_key, sequence_date)
);
```

- 採番は `INSERT ... ON CONFLICT (tenant_id, company_id, sequence_key, sequence_date) DO UPDATE SET current_value = sys_sequence.current_value + sys_sequence.step RETURNING current_value` で原子的に取得する（行ロック）。増分は既存行の `sys_sequence.step` を使い、`EXCLUDED.step` は使わない。
- 欠番許容（トランザクションロールバック時）。重複は絶対に許さない。
- 日次採番は `sequence_date` = 当日、月次は月初日を入れる。

## 6. 制約方針

| 制約 | 方針 |
|---|---|
| 主キー | 全テーブル必須。`pk_{table}` 命名 |
| 外部キー | マスタ参照・親子関係は FK を張る（`ON DELETE RESTRICT`、CASCADE 禁止）。参照先が論理削除対象の場合は FK を張らずアプリで検証（削除は使用停止で運用）。**跨域参照は 6.2 に従う**（FK は同一域内と sys/mdm 参照のみ） |
| 一意 | 業務キーは `UNIQUE INDEX WHERE deleted = FALSE`（部分一意）。先頭列は必ず `tenant_id`、`(tenant_id, company_id, ...)` 必須（6.1 項 4 を除く）。詳細は 6.1 |
| CHECK | 列挙値（status/txn_type）、符号（数量 > 0、金額 >= 0）、日付整合（有効期間）に付与。可変の区分値は付けない |
| NOT NULL | 業務上必須の項目は DB でも NOT NULL。NULL 許容は「未設定」に意味がある場合のみ |
| DEFAULT | 共通カラムの既定値のみ DB に置く。業務既定値はアプリで設定（変更可能なため） |
| コメント | 全テーブル・全カラムに `COMMENT ON` を必須とする（日本語/中国語で可、中文推奨） |

```sql
-- 外部キーの例
CONSTRAINT fk_sal_sales_order_line_order
    FOREIGN KEY (sales_order_id) REFERENCES sal_sales_order (id),

-- 部分一意インデックスの例
CREATE UNIQUE INDEX uk_mdm_material_company_code
    ON mdm_material (tenant_id, company_id, material_code) WHERE deleted = FALSE;
```

- **部分一意インデックスに対する `ON CONFLICT`**：衝突対象（arbiter）として推論させるには、インデックスと**同じ列と同じ `WHERE` 述語**を `ON CONFLICT` に書く必要がある。述語を省くと一致するインデックスがなく `there is no unique or exclusion constraint matching the ON CONFLICT specification` で失敗する。部分インデックスは `ON CONFLICT ON CONSTRAINT` では指定できない（制約ではないため）。衝突列は 6.1 に従い `tenant_id` を先頭に含める。

```sql
INSERT INTO mdm_material (id, tenant_id, company_id, material_code, ...)
VALUES (...)
ON CONFLICT (tenant_id, company_id, material_code) WHERE deleted = FALSE
DO UPDATE SET material_name = EXCLUDED.material_name;
```

### 6.1 一意キーの先頭列規則（tenant_id 先頭）

PostgreSQL の一意制約チェックは RLS を経由しないため、`tenant_id` を含まない一意キーは租户間の衝突と、重複エラーによる他租户データの存在探知を許す。以下を必須とする。

1. すべての業務一意キー（`UNIQUE` 制約・一意インデックス・部分一意インデックスを含む。主キーを除く）の**先頭列は `tenant_id`**。`(tenant_id, company_id, 業務キー...)` を必須とする（項 4 の租户共有データを除く。例外登録は認めない）。
2. `company_id` は `NOT NULL`、**既定値なし（`DEFAULT 1` 禁止）**。アプリが明示的に設定する。
3. `ON CONFLICT` の衝突対象列・`WHERE` 条件は対応する一意インデックスと**完全一致**させ、`tenant_id` を含める。
4. **例外（以下に限る。追加は蓝色大肥鱼の決定による）**：
   - (a) `company_id` 列を持たない租户内全公司共有テーブル：一意キーは `(tenant_id, ...)`。
   - (b) **テナント級一意（`(tenant_id, …)` 先頭、`company_id` を含めない）**。`company_id` 列を持つことは会社単位の一意を意味しない。対象は次に限る：

     | 表 | 一意キー | 列 |
     |---|---|---|
     | `sys_company`（会社ルート表） | `uk_sys_company_code` | `(tenant_id, company_code) WHERE deleted=FALSE` |
     | `sys_company` | `uk_sys_company_credit` | `(tenant_id, unified_social_credit_code) WHERE deleted=FALSE AND unified_social_credit_code IS NOT NULL` |
     | `sys_user` | `uk_sys_user_tenant_username` | `(tenant_id, username)`（`V1__baseline.sql`） |
     | `sys_menu` | `uk_sys_menu_code` | `(tenant_id, menu_code) WHERE deleted=FALSE` |
     | `sys_menu` | `uk_sys_menu_permission` | `(tenant_id, permission_code) WHERE deleted=FALSE AND permission_code IS NOT NULL` |
     | `sys_dict_type` | `uk_sys_dict_type_code` | `(tenant_id, dict_code) WHERE deleted=FALSE` |
     | `sys_outbox_event` | `uk_sys_outbox_event_id` | `(tenant_id, event_id)` |
     | `sys_idempotency` | `uk_sys_idempotency_key` | `(tenant_id, idempotency_key)` |
     | `mdm_exchange_rate` | `uk_mdm_exchange_rate` | `(tenant_id, from_currency_code, to_currency_code, rate_type, effective_date) WHERE deleted=FALSE` |

   - 上記以外（例：`uk_sys_role_code`・`uk_sys_number_rule_code`）は `(tenant_id, company_id, …)`。親 id 先頭の一意キーはいかなる場合も認めない。
5. `sys_sequence` の増分は `DO UPDATE SET current_value = sys_sequence.current_value + sys_sequence.step`（`EXCLUDED.step` 禁止）。
6. CI：`RlsCoverageTest.everyUniqueIndexStartsWithTenantId` が業務 schema の全一意インデックス（主キー除く）を検査する。加えて #38 以降、pgTAP `composite_fk.sql` が一意キーの `(tenant_id, company_id)` 先頭（`company_id` なしの表は `tenant_id` 先頭）を検査し、項 4 (b) のテナント級一意は**表名＋索引名の組**で列挙したものだけを許可する（複合 FK 用 `UNIQUE (tenant_id, id)` も許可）。ただし `sys_user.uk_sys_user_tenant_username` は main 上の `sys_user` に `company_id` 列がなく同テストの照合対象外のため、現時点では未検査。親 id 先頭の例外は認めない（2026-10-21 蓝色大肥鱼 決定、例外一覧は廃止）。

### 6.2 跨域外键规则（2026-10-21 決定）

1. **跨域は `*_id BIGINT` のみ保持し、FK は張らない**。参照先の存在性と租户（`tenant_id`・`company_id`）一致は、参照元ドメインのサービス層が**同一トランザクション内**で検証する。
2. **例外**：主データ域 **sys**（`sys_*`）と **mdm**（`mdm_*`）は、他域から硬 FK で参照してよい（6 章「外部キー」の規則に従う）。ただし**必ず複合外键 `FOREIGN KEY (tenant_id, x_id) REFERENCES 被参照表 (tenant_id, id)`** とし、`x_id` 単独の FK は禁止（同一域内の親子・自己参照も同じ）。被参照表には `UNIQUE (tenant_id, id)`（命名 `uk_<table>_tenant_id`）を付与する。適用済：`sys/V202610210707__sys_composite_tenant_fk.sql`（#35。被参照 17 表に `uk_<table>_tenant_id`、sys/mdm 向け単列 FK 76 本〔mdm 32／prd 29／sal 14／fin 1〕を複合 FK に再作成、原制約名・NO ACTION を維持）。
3. **将来硬 FK を追加する場合**：後から建てた域の側で**別の迁移**を起こし、`ALTER TABLE … ADD CONSTRAINT … FOREIGN KEY … NOT VALID` で追加した後、別ステップで `ALTER TABLE … VALIDATE CONSTRAINT …` を実行する。前提として被参照列に一意制約が必要。租户を持つ表は**複合外键 `(tenant_id, x_id)` → 被参照側 `UNIQUE (tenant_id, id)`** とすること（`x_id` 単独の FK は租户隔离を迂回するため禁止）。
4. **目的**：迁移順序が FK に縛られず、各域を単独で rebase／回滚できるようにする。
5. **現状例（软引用）**：`prd_work_order.sales_order_line_id`（→ `sal_sales_order_line`、FK なし）、`05-inventory` の `work_order_id`（→ `prd_work_order`、FK なし）。

## 7. インデックス方針

| 方針 | 内容 |
|---|---|
| 必須 | 主キー、全 FK 列、一意制約列 |
| 検索 | 一覧・帳票の WHERE/ORDER BY に使う列。複合索引は選択性の高い列を先頭に |
| 先頭列（普通索引） | btree 索引は必ず `tenant_id` を先頭とし、`company_id` を持つ表は続けて `company_id`（`(tenant_id, company_id, ...)`）。GIN は除く（下行）。CI：`composite_fk.sql` が sys/mdm/sal/fin/prd の btree 普通索引を検査 |
| 例外：GIN | **GIN 索引は `tenant_id` 先頭を要求しない**（`btree_gin` は導入しない）。理由：GIN は全文検索・jsonb 包含検索に用いるものであり、租户隔離は RLS とクエリ中の `tenant_id` 条件で保証される |
| 部分索引 | `WHERE deleted = FALSE`、`WHERE status IN (10,20)` 等の頻出条件 |
| 曖昧検索 | `pg_trgm` の GIN インデックス（`gin (name gin_trgm_ops)`）。`LIKE '%xx%'` 用 |
| JSONB | `USING gin (ext_data jsonb_path_ops)`（必要なテーブルのみ） |
| 過剰索引の禁止 | 更新系テーブルの索引は 1 テーブル 5 本以内を目安。追加時は設計書に目的・想定 SQL を書く |
| 命名 | `idx_{table}_{cols}`、`uk_{table}_{cols}`、`gin_{table}_{col}` |
| 統計 | 大量テーブルは `ALTER TABLE ... SET (autovacuum_vacuum_scale_factor=0.05)` 等を設定 |

主要な索引例：

```sql
CREATE INDEX idx_sal_sales_order_status_date
    ON sal_sales_order (order_status, order_date DESC);
CREATE INDEX idx_inv_stock_txn_material_date
    ON inv_stock_txn (material_id, txn_date);
CREATE INDEX gin_mdm_material_name
    ON mdm_material USING gin (material_name gin_trgm_ops);
```

## 8. パーティション・アーカイブ

| テーブル | 方針 | 理由 |
|---|---|---|
| `inv_stock_txn`（在庫取引） | 月次レンジパーティション（第一版から。他テーブルから FK 参照しない。§8.1 参照） | 年間 500 万行、期間検索中心 |
| `sys_audit_log` | 月次レンジパーティション（第一版から。FK 参照しない） | 年間数百万行 |
| 仕訳明細（会計伝票明細） | 月次レンジパーティション（第一版から。FK 参照しない。§8.1 参照） | 伝票明細の大量蓄積 |
| `int_api_call_log` | 月次、6 か月保存後に削除/アーカイブ | 外部 API 呼出量 |
| `wf_` 系 | Flowable 標準テーブル。専用スキーマ `flowable`（[10-rls-and-db-roles.md](10-rls-and-db-roles.md)、PR #43）。履歴は定期的にアーカイブ | 完了プロセス増加 |
| その他伝票 | 5 年保存。期間明細はアーカイブ（TODO：アーカイブ先スキーマ・手順の設計が未作成） | 会計保存年限に合わせる |

- パーティション化する場合も、アプリからは 1 テーブルとして見える（PostgreSQL 宣言的パーティショニング）。
- アーカイブは削除ではなく別スキーマ/別 DB へ移管し、参照用ビューを提供する。

### 8.1 パーティション表を FK で参照しない（2026-10-20 決定）

- 対象：`inv_stock_txn`（在庫取引）、仕訳明細（会計伝票明細）、`sys_audit_log`。
- 他テーブルからこれらを FK で参照しない（パーティション表の一意制約はパーティションキーを含む必要があり、複合 FK が成立しないため）。
- 明細と表頭の整合性（例：明細に冗余する `txn_type` が表頭と一致すること）は **トリガー** で書込時に検証し、過帳時の値設定は **ストアドプロシージャ** が担う。
- 冗余列（`txn_type` 等）は `NOT NULL` とする（NULL だと CHECK が素通りするため）。

## 9. JSONB 拡張項目

- 構造・検証・API は [01 共通项目定义](01-common-item-definitions.md) 第 10 章に従う。
- DB は `ext_data JSONB`。NULL = 拡張項目未使用。空オブジェクト `{}` を既定にしない。
- 項目定義テーブル `mdm_ext_field`（対象エンティティ、項目コード、型、必須、選択肢、表示順）。
- 集計・検索の頻度が高い拡張項目は、通常カラムへ昇格（マイグレーションで移行）する。

## 10. Flyway マイグレーション規則

### 10.1 ディレクトリ構成

```
backend/erp-*/src/main/resources/db/migration/
├── common/  # 00 共通（複数ドメイン横断の拡張・関数など）
├── sys/     # 01 sys_
├── mdm/     # 02 mdm_
├── sal/     # 03 sal_
├── pur/     # 04 pur_
├── inv/     # 05 inv_
├── prd/     # 06 prd_
├── fin/     # 07 fin_
├── wf/      # 08 wf_（Flowable 標準テーブルは schema `flowable` に Flyway で事前作成、下記参照）
├── int/     # 09 int_
└── rpt/     # 10 rpt_
```

- サブディレクトリ名・ファイル名の `{module}` は**テーブル接頭辞**（`sys`/`mdm`/`sal`/`pur`/`inv`/`prd`/`fin`/`wf`/`int`/`rpt`、横断は `common`）に統一する。`sales`/`production`/`inventory` 等の長い名称は使わない。
- `spring.flyway.locations: classpath:db/migration` でサブディレクトリを再帰スキャン（Flyway の既定動作）。

### 10.2 ファイル命名とバージョン範囲

```
V{yyyyMMdd}{NNNN}__{module}_{description}.sql     # バージョンは 12 桁
  yyyyMMdd : 作成日
  NNNN     : 同一日の全体通し番号 0001〜9999（ドメイン共通、単調増加）
例: V202610210701__fin_create_extension_btree_gist.sql
    V202610210702__prd_create_tables.sql
```

- ドメインは**配置ディレクトリ**（10.1）で表し、ファイル名の `{module}` はディレクトリ名と一致させる。バージョン番号はドメインを表さない（2026-10-21 改定。改定前にマージ済みのファイル名はそのまま有効）。
- 同一日の番号はドメインを問わず、マージ時点の main 上の最大バージョンの次から取る。
- **新規スクリプトのバージョンは main 上の既存最大バージョンより大きくすること**（Flyway `outOfOrder` は使わない）。後からマージする PR は、マージ前に最新 main の最大バージョンより大きい番号へ採番し直す。CI（`check-migrations.sh`、PR の base sha と比較）で強制する。
- **マイグレーションを含む PR はマージ前に最新 main へ rebase し、CI を再実行して全緑を確認してからマージする**（PR の CI は作成時の base sha で判定され、main 更新後は自動再実行されないため）。
- バージョンは全体で一意。一度適用したスクリプトは編集しない（新規スクリプトで差分適用）。
- 破壊的変更（列削除・型変更）は 2 段階（新列追加 → 移行 → 旧列削除）で行う。
- シードデータ（コード表・初期マスタ）は `V` スクリプト（初期投入）または `R__seed_{module}_{desc}.sql`（冪等な再投入）で管理。**本設計書の 90-data CSV を正**とする。

#### 10.2.1 既存 `V1__baseline.sql` の扱い

- `backend/erp-boot/src/main/resources/db/migration/V1__baseline.sql`（`sys_user`）は**改名・編集しない**。既に適用済みの環境で `flyway_schema_history` のチェックサム・バージョンが一致しなくなるため。
- Flyway はバージョンを数値比較するため、`1` は全ての 12 桁バージョンより先に実行され、順序上の問題はない。
- `V1__baseline.sql` は CI チェックの唯一の例外（許可リスト）とし、以降 `V2__`〜 等の短い連番は**新規作成禁止**。
- `sys_user` への今後の変更は `sys/V{yyyyMMdd}{NNNN}__sys_*.sql` として追加する。

### 10.3 ロールバック

- Flyway の undo は使用しない（PostgreSQL では手動対応）。失敗時は手動で修正スクリプトを作成し、前進のみ。
- DDL はトランザクション内で実行（PostgreSQL は DDL トランザクション可）。重い索引作成は `CREATE INDEX CONCURRENTLY`（トランザクション外）を検討。

## 11. トランザクション・排他

| 処理 | 分離レベル | 排他方式 | 備考 |
|---|---|---|---|
| 一般の伝票登録 | READ COMMITTED（既定） | 楽観排他（version） | — |
| 在庫残高更新 | READ COMMITTED | 行ロック `SELECT ... FOR UPDATE`（残高行） | ロック順序：`warehouse_id, material_id, batch_no` 昇順。デッドロック回避 |
| 採番 | READ COMMITTED | `sys_sequence` 行ロック | — |
| 月結・年結 | REPEATABLE READ または SERIALIZABLE 検討 | Advisory Lock（`pg_advisory_lock`） | 二重実行防止 |
| 一括更新 | READ COMMITTED | 全件ロールバック | 失敗行一覧を返す設定も可 |
| 残高照合バッチ | READ COMMITTED | バッチ内で整合性検証 | 実行中は該当期間の更新をロック（`fin_period` 状態） |

- トランザクション境界は Service の公開メソッド単位。外部 IF 呼出はトランザクション外（イベント/アウトボックス）。
- 長時間トランザクション禁止（目安 5 秒以内）。帳票生成・ファイル出力はトランザクション外。

### 11.1 跨表ロック順序（全域共通、2026-10-20 決定）

- 過帳系パスで複数テーブルをロックする場合、**受注行（`sal_sales_order_line`）→ 工单（`prd_work_order`）** の順にロックする。同一テーブルの複数行は **id 昇順** でロックする。
- 完工超収の上限 `allowed_qty`（基本単位、受注行 `ordered_qty` 基準）と容差チェーンは `sys_param`（[01-system 90 §3.15](../01-system/90-db-design.md)） を参照。超産承認表の DDL は 06-production で定義予定。
- 適用対象：完工報告、冲销（取消・反向伝票）、返工入庫、受注変更、超産承認。いずれのストアドプロシージャもこの順序に従う（詳細は G2-18、Refs #29）。
- 受注変更のように受注行を起点としない処理も、先に受注行を `FOR UPDATE` し、その後関連工单を id 昇順で `FOR UPDATE` してから数量（已完工数・已発貨数）を検証する。
- **過帳パスは行ロックのみ**（数量累加で `version` を検査しない。409 を返さない）。**楽観排他（`version`）は画面編集のみ**とし、競合時は HTTP `409` + `code=4003`（[03 API 規格 §10](03-common-api-spec.md)）。

## 12. 監査・履歴・スナップショット

| 種類 | 実装 |
|---|---|
| 監査ログ | `sys_audit_log`（追記専用、更新・削除禁止）。01 第 12 章の項目 |
| マスタ変更履歴 | `mdm_*_his`（変更前後の JSON + 変更者 + 日時 + 理由）。主データ変更時に記録 |
| 伝票変更履歴 | 重要伝票（受注・発注・工単・支払）は `*_his` にヘッダ変更を記録。明細変更はバージョン管理（`version_no`）で保持 |
| スナップショット | 取引先名・住所・品名・仕様・税率・単位・為替レートは伝票にコピーして保持（マスタ変更の影響を排除）。対象項目は各域 DB 設計書に明記 |
| 削除 | マスタのみ論理削除。伝票はステータス（取消/廃止）で管理し物理削除しない |
| 履歴の保存期間 | 会計帳簿 30 年、契約・伝票 10 年、操作ログ 3 年（[08 共通业务规则](08-common-business-rules.md) 第 12 章） |

## 13. データ量見積・性能目標（初期 5 年）

| テーブル | 初期件数 | 年間増加 | 5 年後 | 保存 |
|---|---|---|---|---|
| `sys_user` | 900 | 50 | 1,150 | 無期限 |
| `sys_audit_log` | — | 1,000 万 | 5,000 万 | 3 年（その後アーカイブ） |
| `mdm_material` | 8,000 | 1,000 | 13,000 | 無期限 |
| `mdm_customer` | 1,200 | 100 | 1,700 | 無期限 |
| `mdm_supplier` | 800 | 50 | 1,050 | 無期限 |
| `sal_sales_order` | 60,000 | 36,000 | 240,000 | 10 年 |
| `sal_sales_order_line` | 300,000 | 180,000 | 1,200,000 | 10 年 |
| `pur_purchase_order` | 20,000 | 12,000 | 80,000 | 10 年 |
| `inv_stock_txn` | 1,000 万 | 500 万 | 3,500 万 | 10 年（月次パーティション） |
| `inv_stock_balance` | 60,000 | — | 80,000 | 現行のみ |
| `prd_work_order` | 30,000 | 18,000 | 120,000 | 10 年 |
| `prd_work_report` | 200,000 | 150,000 | 950,000 | 10 年 |
| `fin_voucher` | 300,000 | 80,000 | 700,000 | 30 年 |
| `fin_voucher_line` | 2,000,000 | 800,000 | 6,000,000 | 30 年 |
| `int_api_call_log` | — | 300 万 | — | 6 か月 |

性能目標（通常負荷）：

| 処理 | 目標 | 前提 |
|---|---|---|
| 一覧検索（100 件表示） | 2 秒以内 | 対象テーブル 1,000 万行以下、索引あり |
| 詳細取得 | 1 秒以内 | — |
| 登録・更新 | 3 秒以内 | 在庫・採番の行ロック待ち含む |
| 在庫照会（単一物料） | 1 秒以内 | 残高テーブル索引 |
| 月次集計バッチ | 30 分以内 | 在庫取引 500 万行/年 |
| 帳票 PDF 生成 | 5 秒以内（1 伝票） | 非同期ジョブは 1 分以内 |

## 14. マルチテナント・多公司

- 全業務テーブルに `tenant_id`（租户＝部署客户、RLS の唯一の隔離キー）と `company_id`（租户内の法人主体、業務キー・索引の先頭列）を保持。1 tenant ⊇ N company。列名は `tenant_id` に統一。
- `tenant_id` の既定値は `current_setting('app.tenant_id')::bigint`（**`DEFAULT 0` 禁止**）。租户上下文なしの INSERT は失敗する。Flyway/owner のシード投入は `tenant_id` を明示する。
- 一意制約は `(tenant_id, company_id, business_key)` を基本とする（6.1）。`company_id` は NOT NULL・既定値なし。
- 多公司（第一版対象）：会社間取引・会社別会計期間・会社別採番を追加（TODO：詳細設計が未作成）。RLS は `tenant_id` のみ（ENABLE + FORCE、`USING` と `WITH CHECK`）。テンプレート・DB ロール（owner / `erp_app`）・租户上下文は [10 RLS・数据库角色](10-rls-and-db-roles.md) を正とする（`sys_user` で実装済み）。同一テナント内の会社間分離はアプリ層（決定：#10）。
- 本設計では `company_id` の付与を全業務テーブルで必須とし、後からの追加を不要にする。

### 14.1 RLS とデータベースロール（第一版、2026-10-20 決定）

詳細・実装は [10-rls-and-db-roles.md](10-rls-and-db-roles.md)（#43 で追加済み）を正とする。本節は決定事項の要約のみ。

| 項目 | 決定 |
|---|---|
| アプリ接続ロール | `erp_app`（`NOBYPASSRLS`、非 owner）。どのスキーマにも `CREATE` 権限を与えない |
| RLS | `tenant_id` を持つ全業務テーブルで `ENABLE` + `FORCE ROW LEVEL SECURITY`。ポリシーは `USING` と `WITH CHECK` の両方を持つ |
| テナント設定 | トランザクション内で `SET LOCAL app.tenant_id`（`set_config(..., true)`）。テナント文脈が無い場合はエラーとし、**tenant 0 へフォールバックしない** |
| `tenant_id` 既定値 | `current_setting('app.tenant_id')::bigint` |
| Flowable | 専用スキーマ `flowable`。表の owner はマイグレーションロール（Flyway で事前作成、`database-schema-update=false`）。`erp_app` には `USAGE` + 表の `SELECT/INSERT/UPDATE/DELETE` + シーケンスの `USAGE` を `ALTER DEFAULT PRIVILEGES` で付与（Refs #7） |

## 15. バックアップ・リカバリ（設計前提）

| 項目 | 内容 |
|---|---|
| フルバックアップ | 日次 `pg_dump` + WAL アーカイブ + PITR（第一版） |
| リストア目標 | RPO 5 分、RTO 4 時間 |
| リストア訓練 | 四半期に 1 回。手順書は運用ドキュメントに分離 |
| 論理削除データ | バックアップから復元可能とする（物理削除しない） |
| 監査ログ | 改ざん防止のため追記専用。保存先の権限制御 |

## 16. 設計書フォーマット

各域の `90-db-design.md` は [テーブル定義書テンプレート](../_template/03-table-definition-template.md) を使用する。必須記載：

1. テーブル一覧（物理名・論理名・種別・更新元機能・件数見積）
2. テーブルごとの定義：概要、DDL、項目定義（型/桁/NULL/PK/FK/既定値/コメント）、インデックス、制約、更新仕様、関連テーブル（ER）
3. スナップショット項目の明示（マスタ変更の影響を受けない項目）
4. データ量見積・保存期間

## 17. レビュー観点（DB）

- [ ] 命名規則に従っているか（プレフィックス・カラム名・索引名）
- [ ] 共通カラムが全テーブルに付与されているか
- [ ] 金額・数量の型・精度が 01 共通项目定义と一致するか
- [ ] 業務キーの一意制約が論理削除を考慮しているか
- [ ] FK・CHECK・NOT NULL が適切か（過不足ないか）
- [ ] 索引が想定 SQL と対応し、過剰でないか
- [ ] 状態・区分が SMALLINT で定義され、名称を保存していないか
- [ ] スナップショット項目が取引データに含まれているか
- [ ] 排他・トランザクション境界が明記されているか
- [ ] 監査・履歴・保存期間が定義されているか
- [ ] データ量見積が現実的か

## 18. 改訂履歴

| 版数 | 日付 | 変更内容 | 変更者 |
|---|---|---|---|
| v1.0 | 2026-10-20 | 初版：命名、型、制約、索引、パーティション、Flyway、排他、履歴、容量、多租戸、レビュー観点 | Lead |
| v1.1 | 2026-10-20 | 第一版全量範囲（分期表記削除）、§8.1 パーティション表 FK 不可、§11.1 ロック順序（RLS・DB ロールは [10](10-rls-and-db-roles.md)、`ON CONFLICT` は #50） | 业务分析 |
| v1.2 | 2026-10-21 | §6.2 跨域外键规则を新設（跨域は `*_id` のみ・FK なし・サービス層で同一 TX 検証、sys/mdm は例外、将来 FK は NOT VALID→VALIDATE・複合 `(tenant_id, x_id)`）、§6 外部キー行に 6.2 参照を追記 | 业务分析 |
| v1.3 | 2026-10-21 | §7 に btree 普通索引の `tenant_id` 先頭規則と GIN 例外（`btree_gin` 不導入、租户隔離は RLS・`tenant_id` 条件で保証）を追記（#35） | 数据库与运维 |
| v1.4 | 2026-10-21 | §3 明細テーブルの `company_id` 省略を廃止（親と同値を冗長保持） | 业务分析 |
| v1.5 | 2026-10-21 | §6/§6.1：一意キー `(tenant_id, company_id, …)` を「原則」→「必須」に変更、§6.1 項 5（親 id 先頭の例外）と例外一覧表を削除（蓝色大肥鱼 決定）。項 4（`company_id` なしの租户共有テーブルは `(tenant_id, …)`）を唯一の例外として明記。§7 に btree 索引の先頭列規則（`tenant_id`→`company_id`、GIN 除く）を 1 行追加 | 业务分析 |
| v1.6 | 2026-10-21 | §6.2 項 2：sys/mdm 参照も複合外键 `(tenant_id, x_id)`→`(tenant_id, id)` 必須、被参照表に `UNIQUE (tenant_id, id)`（`uk_<table>_tenant_id`）を明記（#35 迁移 `sys/V202610210707` に整合）。§6.1 項 4 の例外に `sys_company` 自身（`uk_sys_company_code`／`uk_sys_company_credit`）を追加。§7 先頭列行を「btree は必ず tenant_id 先頭（company_id あれば続けて）、GIN 除く」に統一 | 业务分析 |
| v1.7 | 2026-10-21 | §6.1 項 4：例外を (a) `company_id` なし共有表／(b) テナント級一意 8 本（`sys_company` 2・`sys_menu` 2・`sys_dict_type`・`sys_outbox_event`・`sys_idempotency`・`mdm_exchange_rate`）に限定し表で列挙。`uk_sys_role_code`・`uk_sys_number_rule_code` は `(tenant_id, company_id, …)`（蓝色大肥鱼 2026-10-21 決定） | 业务分析 |
| v1.8 | 2026-10-21 | §6.1 項 6：#38 以降 pgTAP `composite_fk.sql` がテナント級一意を表名＋索引名で照合・許可することを追記 | 业务分析 |
| v1.9 | 2026-10-21 | §6.1 項 4 (b) に `sys_user.uk_sys_user_tenant_username (tenant_id, username)` を追加（計 9 本、蓝色大肥鱼 2026-10-21 決定）。項 6 の pgTAP 記述から本数を除去し、同キーは現時点で pgTAP 未検査と明記 | 业务分析 |

## Flowable 引擎表の schema 分離（issue #7）

- Flowable 引擎表（`ACT_*` / `FLW_*`）は専用 schema **`flowable`** に置く。業務表は `public`。`public` に `ACT_*`/`FLW_*` があってはならない（`FlowableSchemaTest` で検査）。
- 建表は **Flyway（owner 账号）** が `db/migration/wf/V202610200801__wf_create_flowable_schema.sql` で行う。内容は使用中の Flowable バージョン（8.0.0）の jar 同梱 PostgreSQL 建表 SQL（common → engine → history → identity → eventregistry）を無改変で連結したもの。
- アプリ側は `flowable.database-schema-update=false`（起動時は版本チェックのみ、DDL を発行しない）。よって应用账号 `erp_app` は schema `flowable` に対し `USAGE` と DML（`SELECT/INSERT/UPDATE/DELETE`、序列 `USAGE/SELECT`）のみを持ち、`CREATE` 権限は持たない。owner による `ALTER DEFAULT PRIVILEGES IN SCHEMA flowable` で今後の表・序列にも同じ権限を付与する。
- 表の解決は接続ごとの `search_path = public, flowable`（`spring.datasource.hikari.connection-init-sql`）で行う。`flowable.database-schema` は設定しない（Flowable が接続に `setSchema()` を発行し、プール接続の `search_path` が `flowable` のみになるため）。
- Flowable のバージョンアップ時は、新しい jar の `org/flowable/**/db/upgrade/*.postgres.upgradestep.*.sql` を新規 Flyway 迁移として追加する（`database-schema-update=true` に戻さない）。
- RLS は業務 schema（`public`）の業務表のみ対象。Flowable 表は `tenant_id` を持たず RLS 対象外。
