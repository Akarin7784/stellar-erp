# 横断マトリクス（横断矩阵）

| 項目 | 内容 |
|---|---|
| 文書名 | 横断マトリクス索引（横斷矩阵索引） |
| 文書番号 | DSN-MTX-000 |
| 版数 | v1.0 |
| 作成日 | 2026-10-20 |
| 作成者 | Lead（设计基盤） |
| 状態 | ドラフト（レビュー中） |
| 関連文書 | [详细设计书体系总览](../README.md) / [设计方针](../00-common/00-design-principles.md) |

---

## 1. 目的

各業務域の詳細設計書から **ID を抽出・集約** し、次の目的で利用する。

1. **重複・欠番・形式不正の検出**：機能 ID・画面 ID・テーブル名・メッセージ ID の一意性検証。
2. **カバレッジ確認**：機能一覧に載る機能が詳細設計文書で実装可能な粒度まで設計されているか。
3. **トレーサビリティ**：機能 → 画面 → テーブル → API → メッセージ → テスト観点の追跡。
4. **レビュー・テスト設計の材料**：一覧を起点にレビュー表・テストケースを派生させる。

## 2. 生成方法

本ディレクトリの一覧・検証レポートは **自動生成** である。設計書を更新したら次を実行する。

```powershell
# リポジトリルートで実行
$env:PYTHONIOENCODING='utf-8'
& "C:\Users\Administrator\.dsh\dsh-runtimes\dsh-primary-runtime\dependencies\python\python.exe" `
    docs\design\20-matrix\tools\gen_matrix.py
```

- `--no-xlsx` を付けると Excel 出力をスキップ（Markdown/JSON のみ）。
- 生成物：
  - `00-domain-summary.md`：域別件数サマリ
  - `01-feature-list.md`：機能一覧（全機能）
  - `02-screen-list.md`：画面一覧
  - `03-table-list.md`：テーブル一覧
  - `04-report-list.md`：帳票一覧
  - `05-batch-list.md`：バッチ一覧
  - `06-interface-list.md`：インタフェース一覧
  - `07-message-list.md`：メッセージ一覧
  - `08-permission-list.md`：機能権限一覧
  - `09-api-list.md`：API 一覧
  - `10-validation-report.md`：検証レポート（ID/リンク/必須ファイル/未決マーカー）
  - `data/matrix.json`：機械可読の抽出データ
  - `Stellar_ERP_详细设计书一览.xlsx`：Excel 版一覧（レビュー配布用）

## 3. 検証観点（スクリプトが自動判定）

| # | 検証 | 内容 |
|---|---|---|
| 1 | 必須ファイル | 各域に `00-overview / 90-db-design / 91-api-design / 92-report-batch-design / 93-messages / 94-sample-data` が存在するか |
| 2 | 文書情報 | 冒頭 25 行以内に「文書番号」があるか |
| 3 | 改訂履歴 | 「改訂履歴」章があるか |
| 4 | リンク切れ | 相対リンクの参照先が実在するか |
| 5 | ID 形式 | `F-/SCR-/PRT-/BAT-/IF-/MSG-{DOM}-{3桁}` に適合するか |
| 6 | ID ドメイン整合 | ID のドメインコードが配置ディレクトリと一致するか |
| 7 | ID 重複 | 同一 ID が複数文件・複数行に現れないか |
| 8 | 機能カバレッジ | 機能一覧の各機能が概要書以外の詳細設計文書に登場するか |
| 9 | 未決マーカー | `【未決】` `【要確認】` の残存件数（完成時 0 が目標） |

## 4. 現在の状態

> 一覧・検証レポートは設計書の完成に合わせて再生成する。最新の結果は [10-validation-report.md](10-validation-report.md) を参照。

## 5. 改訂履歴

| 版数 | 日付 | 変更内容 | 変更者 |
|---|---|---|---|
| v1.0 | 2026-10-20 | 初版：目的、生成方法、検証観点 | Lead |
