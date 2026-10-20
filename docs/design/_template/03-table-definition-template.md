# テーブル定義書テンプレート（テーブル定義書）

> 使用単位：1 テーブル 1 節。業務域の `90-db-design.md` は本フォーマットを表ごとに展開する。

| 項目 | 内容 |
|---|---|
| テーブル物理名 | {prefix}_{entity} |
| テーブル論理名 | {中文名} |
| 種別 | マスタ / 伝票ヘッダ / 伝票明細 / 履歴 / 残高 / ログ / 設定 |
| 更新元機能 | {F-...} |
| データ量見積 | {初期: x 件 / 年間増加: y 件 / 5 年後: z 件} |
| 保存期間 | {無期限/10 年/…} |
| 備考 | {パーティション、アーカイブ等} |

## 1. 概要

{このテーブルが何を表すか、業務上の位置づけ、1 行の意味}

## 2. DDL

```sql
CREATE TABLE {prefix}_{entity} (
    id              BIGINT       NOT NULL,
    tenant_id       BIGINT       NOT NULL DEFAULT 0,
    company_id      BIGINT       NOT NULL DEFAULT 1,
    {column}        {type}       {NULL/NOT NULL} {DEFAULT ...},
    ...
    version         INT          NOT NULL DEFAULT 0,
    deleted         BOOLEAN      NOT NULL DEFAULT FALSE,
    remark          VARCHAR(500),
    ext_data        JSONB,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_by      BIGINT       NOT NULL DEFAULT 0,
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_by      BIGINT       NOT NULL DEFAULT 0,
    CONSTRAINT pk_{table} PRIMARY KEY (id)
);

COMMENT ON TABLE {prefix}_{entity} IS '{中文名}';
COMMENT ON COLUMN {prefix}_{entity}.{column} IS '{中文説明}';
```

## 3. 項目定義

| No | 物理名 | 論理名 | 型/桁 | NULL | PK | FK/参照先 | 既定値 | 備考 |
|---|---|---|---|---|---|---|---|---|
| 1 | id | 主キー | BIGINT | NOT NULL | ○ | — | アプリ採番 | 雪花 ID |
| 2 | {column} | {論理名} | {VARCHAR(64)} | {NULL} | — | {mdm_material.id} | {NULL} | {制約・算出方法} |

## 4. インデックス

| No | 索引名 | 種別 | 対象列 | 条件 | 目的 |
|---|---|---|---|---|---|
| 1 | idx_{table}_{cols} | B-Tree | ({col1}, {col2}) | — | {検索条件} |
| 2 | uk_{table}_{cols} | UNIQUE | ({col1}, {col2}) | WHERE deleted = FALSE | {業務キー一意} |
| 3 | idx_{table}_ext | GIN | (ext_data jsonb_path_ops) | — | {拡張項目検索} |

## 5. 制約・整合性

| 制約 ID | 内容 | 実現方法 | エラーメッセージ |
|---|---|---|---|
| CK-01 | {数量 > 0} | CHECK | {MSG-...} |
| FK-01 | {material_id → mdm_material.id} | FK | {参照エラー} |

## 6. 更新仕様

| 操作 | 契機（機能 ID / バッチ ID） | 更新項目 | 削除/取消の扱い |
|---|---|---|---|
| INSERT | {F-...} | 全項目 | — |
| UPDATE | {F-...} | {項目} | {取消時は status=90} |

## 7. 関連テーブル

```mermaid
erDiagram
    {prefix}_{entity} ||--o{ {prefix}_{entity}_line : "1:N"
    {prefix}_{entity} }o--|| mdm_material : "material_id"
```

## 8. データ例（任意）

| {column1} | {column2} | 説明 |
|---|---|---|
| {値} | {値} | {実データ/示例値の別} |

## 9. 備考・注意事項

{パフォーマンス上の注意、アーカイブ方針、既知の制約}
