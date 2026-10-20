# 共通・系统域 验收标准（review-r3 #8–#33 のうち共通/系统に属するもの）

| 項目 | 内容 |
|---|---|
| 文書名 | 共通・系统域 验收标准 |
| 版数 | v1.0 |
| 作成日 | 2026-10-20 |
| 作成者 | 业务分析 |
| 状態 | ドラフト（レビュー中） |
| 関連文書 | [DB 共通規格](04-common-db-spec.md) / [API 共通規格](03-common-api-spec.md) / [共通業務ルール](08-common-business-rules.md) / [RLS・DB ロール](10-rls-and-db-roles.md)（PR #43） |

---

形式：G（Given）/ W（When）/ T（Then）。**待確認** は未決のため断言しない。他ドメイン（在庫・生産・財務）に属する issue はそれぞれのドメイン文書の PR で扱う。

## #9 RLS 启用阶段不一致（Refs #9）

- W：ADR-0003 と DB 共通規格の RLS 適用時期を grep。T：「第一版」の 1 通りのみ（`docs/adr/0003-database.md`、[04 §14](04-common-db-spec.md)、[10-rls-and-db-roles.md](10-rls-and-db-roles.md)（PR #43））。
- G：首批業務テーブルが作成済み。W：`pg_class.relrowsecurity` / `relforcerowsecurity` を照会。T：`tenant_id` を持つ全業務テーブルで共に true。ポリシーは `USING` と `WITH CHECK` を両方持つ（`pg_policy.polqual` / `polwithcheck` が非 NULL）。
- G：tenant 0 と tenant 9 にデータあり。W：`erp_app`（非 owner、NOBYPASSRLS）で `app.tenant_id=0` を設定し SELECT/INSERT/UPDATE/DELETE。T：tenant 9 の行は読めない。tenant 9 の行の書込は WITH CHECK で拒否。
- W：`app.tenant_id` を設定せずに業務テーブルを照会。T：エラー（tenant 0 へフォールバックしない）。
- W：`erp_app` で任意スキーマに `CREATE TABLE`。T：権限エラー。
- W：`erp_app` で `SELECT sys_init_tenant(9)` を実行。T：権限エラー（`EXECUTE` は PUBLIC から REVOKE 済み、`erp_app` に未付与）。テナント払い出し用ロールでは成功し、tenant 9 に `prd.completion_over_rate = 0.05` が投入される。

## #10 tenant_id と company_id の関係（Refs #10）

- G：ADR の定義「tenant = 導入顧客、company = 法人、tenant ⊇ company」（**待確認**）。W：会話のテナントと異なる tenant の `sys_company` を INSERT。T：拒否（RLS WITH CHECK）。
- 決定（#10、[10-rls-and-db-roles.md](10-rls-and-db-roles.md)）：RLS は `tenant_id` のみで分離する。同一テナント内の会社間分離はアプリ層（データ範囲・`company_id` 条件）で行う。G：同一 tenant に company 1・2 のデータ。W：`erp_app` で照会（company 条件なし）。T：RLS では両社の行が見える（company はポリシー条件に含まれない）。W：company 1 のユーザが API で照会。T：アプリ層で company 1 のみ返る。
- 文書：定義は ADR のみを正とし、[04 §14](04-common-db-spec.md) は ADR を参照する。

## #11 迁移文件命名规则（Refs #11）

- 命名規則は PR #40（`V{yyyyMMdd}{NNNN}__{module}_{desc}.sql` と `check-migrations.sh`）で確定予定。本 PR では変更しない。
- W：CI で Flyway を実行。T：全新規スクリプト名が規則に一致、版数は全体で一意、既存スクリプトの改変は Flyway validate で失敗。

## #22 并发控制的分工（共通部分、Refs #22）

- G：在庫・完工数など数量を累加する過帳パス。W：2 セッションが同時に過帳。T：行ロック（`FOR UPDATE`）で直列化され、`version` 検査をせず 409 を返さない。累計は上限を超えない（[04 §11.1](04-common-db-spec.md)）。
- G：画面で編集中の伝票。W：他ユーザが先に更新した後に保存。T：HTTP `409` + `code=4003`（[03 §10](03-common-api-spec.md)）。
- 工程別の報工上限の計算式は生産ドメインで扱う（**待確認**）。

## #25 作废已有下游的单据（共通ルール、Refs #25）

- G：PO に GR が存在。W：PO を取消。T：`MSG-COM-072` で拒否（[08 §3.3](08-common-business-rules.md)）。
- W：任意の取消。T：物理削除しない（状態 90）。過帳済みの仕訳は赤字逆仕訳を生成し、元仕訳は変更しない。
- 領料の 24 時間ルール（BR-MI-15）は生産ドメインで扱う。

## 跨表ロック順序（G2-18 の共通部分、Refs #29）

- G：受注行 L と工单 W。W：報完工と受注変更（数量変更）を同時実行。T：デッドロックしない（両パスとも「受注行 → 工单、同一表は id 昇順」）。`completed_qty` は `allowed_qty` を超えない。
