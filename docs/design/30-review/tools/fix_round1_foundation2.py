#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Lead 红队第 1 轮：E15/E24 质量契约与库存传票所有权修正。"""
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")
root = Path(__file__).resolve().parents[2]


def sub(rel, old, new, expect=1):
    p = root / rel
    t = p.read_text(encoding="utf-8")
    n = t.count(old)
    if n != expect:
        print(f"[WARN] {rel}: expected {expect} got {n}: {old[:70]!r}")
        return
    p.write_text(t.replace(old, new), encoding="utf-8")
    print(f"[OK] {rel}: {old[:56]!r}")


# E15: 判定コード・inspection type・倉庫/ロットを明確化
sub("00-common/09-cross-domain-flow.md",
    "| E15 | `quality.inspection.completed` | 来料・工程・最終検査の判定確定 | PRD | PUR/INV | inspectionId, inspectionNo, inspectionType, sourceType, sourceId, result(PASS/CONCESSION/REJECT), lines, inspectedAt | 在庫ステータス変換、返品/再検査の起動 |",
    "| E15 | `quality.inspection.completed` | 来料・工程・最終検査の判定確定 | PRD | PUR/INV | inspectionId, inspectionNo, inspectionType(IQC/IPQC/FQC/OQC), sourceType, sourceId, sourceNo, warehouseId, result(PASS/CONCESSION/REJECT), resultCode(10未検査/20合格/30特採/40不合格/50廃棄), lines[{materialId, batchNo, sampleQty, defectQty, resultCode}], inspectedAt | 在庫ステータス変換、返品/再検査の起動 |")

# E24: 入庫時状態・検査情報を追加
sub("00-common/09-cross-domain-flow.md",
    "| E24 | `production.workorder.completed` | 完工（完成品入庫） | PRD | INV/FIN | workOrderId, completedQty, lines[{materialId, qty, batchNo, unitCost, amount}], costAmount（完工総原価）, unitCost（完成品単位原価）, completedAt | 完成品入庫、完工原価計上（J16） |",
    "| E24 | `production.workorder.completed` | 完工（完成品入庫） | PRD | INV/FIN | workOrderId, completedQty, lines[{materialId, qty, batchNo, unitCost, amount, stockStatus(10待検/20可用)}], costAmount（完工総原価）, unitCost（完成品単位原価）, inspectionId, inspectionResult, completedAt | 完成品入庫（既定は待検計上）、完工原価計上（J16） |")

# 09 §8 品質連携: 判定コード対応と FGI 状態確定ルール
sub("00-common/09-cross-domain-flow.md",
    "| 生产完工 | FQC 成品检验 | 完成品入庫前 | E15 → 入庫 | 返工/特採/廃棄 |",
    "| 生产完工 | FQC 成品检验 | 完成品入庫前 | E15（result=PASS/resultCode=20）→ 入庫ステータス可用化 | 返工/特採/廃棄 |")

sub("00-common/09-cross-domain-flow.md",
    "- 検査基準（`prd_inspection_standard`）は品目・工程・顧客別に定義。検査項目・規格・サンプリング（全数/抜取）・判定基準を持つ。",
    "- 検査基準（`prd_inspection_standard`）は品目・工程・顧客別に定義。検査項目・規格・サンプリング（全数/抜取）・判定基準を持つ。\n- **判定コード対応**：PRD 内部コード `resultCode` 10=未検査 / 20=合格 / 30=特採 / 40=不合格 / 50=廃棄。イベント E15 では `resultCode` と 3 値 `result`（20→PASS、30→CONCESSION、40/50→REJECT、10 はイベント発行しない）を併記する。\n- **受入・完工の在庫状態**：受入は E14 で待検計上 → E15（IQC 合格）で可用化。完工は E24 で**必ず `stockStatus=10 待検` で計上** → E15（FQC 合格）で `20 可用` へ変換する。E24 が E15 より先に到着する前提とし、順序逆転時は INV がイベントを保留（`sys_event_wait`）して E24 到着後に E15 を適用する。")

# 在庫取引伝票の採番所有権を明記（MII/MIR/FGI/OSI/OSR）
sub("00-common/08-common-business-rules.md",
    "- 状態変換（ST_IN/ST_OUT）は独立した伝票番号を持たない。来源单据（IQC/盘点/手工）を source とし、`pair_key` で対になる 2 取引を関連付ける。ただし在庫域内の管理用に内部番号 `ST{YYMMDD}{4}` を付してよい（**業務伝票番号ではなく、帳票・対外文書には使用しない**）。",
    "- 状態変換（ST_IN/ST_OUT）は独立した伝票番号を持たない。来源单据（IQC/盘点/手工）を source とし、`pair_key` で対になる 2 取引を関連付ける。ただし在庫域内の管理用に内部番号 `ST{YYMMDD}{4}` を付してよい（**業務伝票番号ではなく、帳票・対外文書には使用しない**）。\n- **在庫側伝票の採番所有権**：`MII`（生産領料）`MIR`（生産退料）`FGI`（完成品入庫）`OSI`（委外発料）`OSR`（委外受入）の伝票番号は **INV が単一所有・採番**する（`inv_stock_txn.txn_no` と 1:1）。PRD は要求/実績データ（数量・工単・理由）のみを保持し、伝票番号は INV が返す `stock_doc_id/stock_doc_no` を参照する（PRD 側で同一プレフィックスを再採番しない）。")

print("done")
