#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Lead 红队第 2 轮收尾：J21 分割・E18 追加項目・イベント待機テーブルの正本化。"""
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")
root = Path(__file__).resolve().parents[2]


def sub(old, new, expect=1):
    p = root / "00-common/09-cross-domain-flow.md"
    t = p.read_text(encoding="utf-8")
    n = t.count(old)
    if n != expect:
        print(f"[WARN] expected {expect} got {n}: {old[:70]!r}")
        return
    p.write_text(t.replace(old, new), encoding="utf-8")
    print(f"[OK] {old[:56]!r}")


# J21 分割（FIN の J21A/J21B と整合）
sub("| J21 | 盘盈盘亏批准 | 待处理财产损溢 `1901` | 管理费用 `6602` / 营业外收入 `6301` / 营业外支出 `6711` | 承認額 | 「盘盈亏处理 {单号}」 | 承認 |",
    "| J21A | 盘盈批准（盘盈） | 待处理财产损溢 `1901` | 管理费用 `6602`（または営業外収入 `6301`） | 承認額 | 「盘盈处理 {单号}」 | 承認 |\n"
    "| J21B | 盘亏批准（盘亏） | 管理费用 `6602` / 营业外支出 `6711` | 待处理财产损溢 `1901` | 承認額 | 「盘亏处理 {单号}」 | 承認 |")

# E18: INV が追加した返却項目を契約に追記
sub("| E18 | `inventory.txn.posted` | 在庫取引の確定（全取引種別） | INV | FIN/SAL/PUR/PRD | txnId, txnNo, txnType, warehouseId, lines[{materialId, batchNo, qty, unitCost, amount}], bizDate, sourceType, sourceId | 原価計算・（必要時）仕訳起票 |",
    "| E18 | `inventory.txn.posted` | 在庫取引の確定（全取引種別） | INV | FIN/SAL/PUR/PRD | txnId, txnNo, txnType, warehouseId, lines[{materialId, batchNo, qty, unitCost, amount}], totalQty, totalAmount, bizDate, sourceType, sourceId, sourceEventAt, stockDocId, stockDocNo | 原価計算・（必要時）仕訳起票。`stockDocId/stockDocNo` は INV 採番の在庫側伝票番号（MII/MIR/FGI/OSI/OSR 等）を PRD へ返却する |")

# イベント待機テーブルの正本化（SYS 提供）
sub("- **受入・完工の在庫状態**：受入は E14 で待検計上 → E15（IQC 合格）で可用化。完工は E24 で**必ず `stockStatus=10 待検` で計上** → E15（FQC 合格）で `20 可用` へ変換する。E24 が E15 より先に到着する前提とし、順序逆転時は INV がイベントを保留（`sys_event_wait`）して E24 到着後に E15 を適用する。",
    "- **受入・完工の在庫状態**：受入は E14 で待検計上 → E15（IQC 合格）で可用化。完工は E24 で**必ず `stockStatus=10 待検` で計上** → E15（FQC 合格）で `20 可用` へ変換する。E24 が E15 より先に到着する前提とし、順序逆転時はイベントを保留して E24 到着後に E15 を適用する。保留テーブルの正本は **`sys_event_wait`（SYS 提供の共通基盤）** とし、INV が暫定実装する `inv_event_wait` は Phase 1 内で `sys_event_wait` へ移管する（物理名の最終正本は SYS）。")

print("done")
