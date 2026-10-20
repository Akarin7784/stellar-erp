#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Lead 红队第 1 轮：共通契约层 S1/S2 修正（00-common/03,04,08,09,00）。"""
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")
root = Path(__file__).resolve().parents[2]  # docs/design


def sub(rel: str, old: str, new: str, expect: int = 1) -> None:
    p = root / rel
    t = p.read_text(encoding="utf-8")
    n = t.count(old)
    if n != expect:
        print(f"[WARN] {rel}: expected {expect} got {n} for: {old[:60]!r}")
        return
    p.write_text(t.replace(old, new), encoding="utf-8")
    print(f"[OK] {rel}: {old[:52]!r} ...")


# ============ 09 跨域流程：事件 payload / 关系修正 ============
# 1) P2P 請購承認で E05（SAL 専用）誤用
sub("00-common/09-cross-domain-flow.md",
    "| 2 | 請購承認 | WF / 承認者 | — | 金額別経路で承認 | E05、PR（25） | 20→25 |",
    "| 2 | 請購承認 | WF / 承認者 | — | 金額別経路で承認 | WF 承認コールバック（E31/E32）、PR（25）※購買提出に専用イベントは設けない（同期コマンド） | 20→25 |")

# 2) E05 / E06 payload 整備（金額口径を明示）
sub("00-common/09-cross-domain-flow.md",
    "| E05 | `sales.order.submitted` | 受注の承認提出 | SAL | WF | businessType, businessId, businessNo, amount, departmentId, applicantId | 承認プロセス開始 |",
    "| E05 | `sales.order.submitted` | 受注の承認提出 | SAL | WF | businessType, businessId, businessNo, amount（税抜）, taxAmount, totalAmount（税込）, currencyCode, isTaxIncluded, departmentId, applicantId | 承認プロセス開始 |")
sub("00-common/09-cross-domain-flow.md",
    "| E06 | `sales.order.approved` | 受注の最終承認 | SAL | INV/FIN | orderId, orderNo, customerId, lines[{materialId, qty, uom, deliveryDate, warehouseId}], amount, creditCheckResult | 在庫引当（倉庫指定）、与信コミット |",
    "| E06 | `sales.order.approved` | 受注の最終承認 | SAL | INV/FIN | orderId, orderNo, customerId, lines[{materialId, qty, uom, deliveryDate, warehouseId}], amount（税抜）, taxAmount, totalAmount（税込）, currencyCode, isTaxIncluded, creditCheckResult | 在庫引当（倉庫指定）、与信コミット |")

# 3) E10: serialNos（契約外拡張を正式化）
sub("00-common/09-cross-domain-flow.md",
    "lines[{materialId, qty, uom, warehouseId, batchNo, unitPrice, taxRate, amount, taxAmount, costAmount?}], amount, taxAmount, deliveryDate",
    "lines[{materialId, qty, uom, warehouseId, batchNo, serialNos[], unitPrice, taxRate, amount, taxAmount, costAmount?}], amount, taxAmount, deliveryDate")

# 4) E11: 返品に金額・原価・元出荷紐付けを追加（J22/J23 用）
sub("00-common/09-cross-domain-flow.md",
    "| E11 | `sales.return.confirmed` | 返品受入・検品完了 | SAL | INV/FIN | returnId, returnNo, orderId, customerId, lines[{materialId, qty, inventoryStatus}], returnDate | 在庫戻入、赤伝売上・売掛 |",
    "| E11 | `sales.return.confirmed` | 返品受入・検品完了 | SAL | INV/FIN | returnId, returnNo, orderId, originalDeliveryId, customerId, lines[{materialId, qty, inventoryStatus, unitPrice, taxRate, amount, taxAmount, costAmount}], amount, taxAmount, returnDate | 在庫戻入、赤伝売上・売掛（J23） |")

# 5) E13: 購読者から WF を除去（最終承認は WF 自身が完了済）
sub("00-common/09-cross-domain-flow.md",
    "| E13 | `purchase.order.approved` | 発注の最終承認 | PUR | WF/INT |",
    "| E13 | `purchase.order.approved` | 発注の最終承認 | PUR | INT（Phase 2  supplier portal） |")

# 6) E14: 暫估金額（J01）
sub("00-common/09-cross-domain-flow.md",
    "lines[{materialId, receivedQty, uom, warehouseId, batchNo, unitPrice}], receivedAt",
    "lines[{materialId, receivedQty, uom, warehouseId, batchNo, unitPrice, amount}], amount, receivedAt")

# 7) E16: 返品金額（J04）
sub("00-common/09-cross-domain-flow.md",
    "| E16 | `purchase.return.confirmed` | 仕入返品の出庫確定 | PUR | INV/FIN | returnId, returnNo, receiptId, lines[{materialId, qty, warehouseId}], returnDate | 在庫出庫、赤伝仕入・買掛 |",
    "| E16 | `purchase.return.confirmed` | 仕入返品の出庫確定 | PUR | INV/FIN | returnId, returnNo, receiptId, lines[{materialId, qty, warehouseId, unitPrice, taxRate, amount, taxAmount, reason}], amount, taxAmount, returnDate | 在庫出庫、赤伝仕入・買掛（J04） |")

# 8) E22/E23/E24/E25/E26: 原価計算に必要な金額・賃率・加工費
sub("00-common/09-cross-domain-flow.md",
    "| E22 | `production.material.issued` | 生産領料確定 | PRD | INV/FIN | workOrderId, issueId, lines[{materialId, qty, batchNo, unitCost}], issuedAt | 在庫出庫、材料費計上 |",
    "| E22 | `production.material.issued` | 生産領料確定 | PRD | INV/FIN | workOrderId, issueId, lines[{materialId, qty, batchNo, unitCost, amount}], amount, issuedAt | 在庫出庫、材料費計上（J11） |")
sub("00-common/09-cross-domain-flow.md",
    "| E23 | `production.report.confirmed` | 報工確定（良品数・工数） | PRD | FIN/PRD | workOrderId, operationId, goodQty, defectQty, workHours, reportedAt | 人工費・製造費用の集計、進捗更新 |",
    "| E23 | `production.report.confirmed` | 報工確定（良品数・工数） | PRD | FIN/PRD | workOrderId, operationId, goodQty, defectQty, workHours, laborRate, laborAmount, overheadRate, overheadAmount, costCenterCode, reportedAt | 人工費・製造費用の集計（J13）、進捗更新 |")
sub("00-common/09-cross-domain-flow.md",
    "| E24 | `production.workorder.completed` | 完工（完成品入庫） | PRD | INV/FIN | workOrderId, completedQty, lines[{materialId, qty, batchNo, unitCost}], completedAt | 完成品入庫、完工原価計上 |",
    "| E24 | `production.workorder.completed` | 完工（完成品入庫） | PRD | INV/FIN | workOrderId, completedQty, lines[{materialId, qty, batchNo, unitCost, amount}], costAmount（完工総原価）, unitCost（完成品単位原価）, completedAt | 完成品入庫、完工原価計上（J16） |")
sub("00-common/09-cross-domain-flow.md",
    "| E25 | `production.outsourcing.issued` | 委外発料確定 | PRD | INV/FIN | outsourcingOrderId, issueId, lines[{materialId, qty, unitCost}], issuedAt | 委託加工物資への振替 |",
    "| E25 | `production.outsourcing.issued` | 委外発料確定 | PRD | INV/FIN | outsourcingOrderId, issueId, lines[{materialId, qty, unitCost, amount}], amount, issuedAt | 委託加工物資への振替（J17） |")
sub("00-common/09-cross-domain-flow.md",
    "| E26 | `production.outsourcing.received` | 委外受入確定 | PRD | INV/FIN | outsourcingOrderId, receiptId, lines[{materialId, qty, unitCost}], processingFee, receivedAt | 在庫入庫、加工費計上 |",
    "| E26 | `production.outsourcing.received` | 委外受入確定 | PRD | INV/FIN | outsourcingOrderId, receiptId, lines[{materialId, qty, unitCost, amount}], processingFee, taxRate, taxAmount, amount, receivedAt | 在庫入庫、加工費計上（J18） |")

# 9) E34: 発行者二重所有 -> FIN 単一所有
sub("00-common/09-cross-domain-flow.md",
    "| E34 | `system.period.status.changed` | 会計・業務期間の状態変更 | FIN/SYS | ALL | periodCode, oldStatus, newStatus | 参照キャッシュ更新 |",
    "| E34 | `system.period.status.changed` | 会計・業務期間の状態変更（発行は FIN 単一所有。SYS は参照のみ） | FIN | ALL | periodCode, oldStatus, newStatus, closedAt | 参照キャッシュ更新 |")

# 10) E35: 取消金額
sub("00-common/09-cross-domain-flow.md",
    "reversedLines[{materialId, batchNo, qty}], cancelledAt",
    "reversedLines[{materialId, batchNo, qty, unitPrice, amount}], amount, cancelledAt")

# 11) E36: 退料金額（J12）
sub("00-common/09-cross-domain-flow.md",
    "| E36 | `production.material.returned` | 生産退料の確定（未使用材料の戻入） | PRD | INV/FIN | workOrderId, returnId, returnNo, lines[{materialId, qty, batchNo, unitCost}], returnReason, returnedAt | 在庫戻入（MIR）、材料費戻し（J12） |",
    "| E36 | `production.material.returned` | 生産退料の確定（未使用材料の戻入） | PRD | INV/FIN | workOrderId, returnId, returnNo, lines[{materialId, qty, batchNo, unitCost, amount}], amount, returnReason, returnedAt | 在庫戻入（MIR）、材料費戻し（J12） |")

# 12) J07 発生元: E12 -> E10（出荷基準）
sub("00-common/09-cross-domain-flow.md",
    "| J07 | 销售发票/应收 | 应收账款 `1122` | 主营业务收入 `6001`、应交税费-销项税额 `2221` | 税抜額・税額 | 「销售 {发票号}」 | E12 |",
    "| J07 | 销售发票/应收 | 应收账款 `1122` | 主营业务收入 `6001`、应交税费-销项税额 `2221` | 税抜額・税額 | 「销售 {发票号}」 | E10（出荷基準で売上計上。E12 は発票の紐付け・台帳のみ） |")

# 13) 与信超過承認経路を A20 に整合
sub("00-common/09-cross-domain-flow.md",
    "| 与信超過 | 受注登録 | 警告 + 承認フロー（財務総監）。未承認は出荷不可 | SAL / FIN |",
    "| 与信超過 | 受注登録 | 警告 + 承認フロー A20（销售总监→财务总监→总经理（設定額以上））。未承認は出荷不可 | SAL / FIN |")

# 14) Outbox DDL を 01-system と整合（共通カラム・event_version 追加）
old_ddl = """CREATE TABLE sys_outbox_event (
    id             BIGINT       NOT NULL,
    event_id       UUID         NOT NULL,
    event_type     VARCHAR(100) NOT NULL,"""
new_ddl = """-- 正本 DDL は 01-system/90-db-design.md。本表は論理定義（共通カラム L + company_id を含む）。
CREATE TABLE sys_outbox_event (
    id             BIGINT       NOT NULL,
    tenant_id      BIGINT       NOT NULL DEFAULT 0,
    company_id     BIGINT       NOT NULL DEFAULT 1,
    event_id       UUID         NOT NULL,
    event_type     VARCHAR(100) NOT NULL,
    event_version  INT          NOT NULL DEFAULT 1,"""
sub("00-common/09-cross-domain-flow.md", old_ddl, new_ddl)

# 15) リトライ層別の明確化（Outbox vs 外部 IF）
sub("00-common/09-cross-domain-flow.md",
    "| リトライ | 指数バックオフ（1 分、5 分、30 分、2 時間、6 時間）。最大 10 回 |",
    "| リトライ | Outbox 配信は指数バックオフ（1 分、5 分、30 分、2 時間、6 時間）で最大 10 回。**外部 IF のリトライは IF 設定（既定 3 回）と層を分けて管理**し、Outbox は業務イベント配信、外部 IF は `int_sync_task` 側で再送する |")

# ============ 03 API: code=5001 二重定義の解消 ============
sub("00-common/03-common-api-spec.md",
    "| 503 | メンテナンス・依存サービス停止 | 5001 |",
    "| 503 | メンテナンス・依存サービス停止 | 5001（保守・依存停止のみ） |\n| 429 | レート制限超過（外部 API） | 5002 |")
sub("00-common/03-common-api-spec.md",
    "| レート制限 | 既定 600 req/分/client（バースト 100）。超過 429 + `code=5001` |",
    "| レート制限 | 既定 600 req/分/client（バースト 100）。超過 429 + `code=5002`（5001 は保守停止専用、混用禁止） |")

# ============ 04 DB: sys_sequence に監査列を追加 ============
sub("00-common/04-common-db-spec.md",
    """    version     INT          NOT NULL DEFAULT 0,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT pk_sys_sequence PRIMARY KEY (id),""",
    """    version     INT          NOT NULL DEFAULT 0,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_by  BIGINT       NOT NULL DEFAULT 0,
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_by  BIGINT       NOT NULL DEFAULT 0,
    CONSTRAINT pk_sys_sequence PRIMARY KEY (id),""")

# ============ 08 業務規則: 発票保存期間の法令リスク修正 ============
sub("00-common/08-common-business-rules.md",
    "| 发票及抵扣凭证 | 按税法规定保存（現行実務 10 年）【要確認】 | 《发票管理办法》及实施细则。詳細は 90-data/sources.md で確認 |",
    "| 发票及抵扣凭证（原始凭证） | **30 年**（会計凭证・原始凭证として）。ただし发票存根联・发票登记簿は 5 年 | 【実データ】《会计档案管理办法》（79 号令・会計凭证 30 年）、《中华人民共和国发票管理办法》（存根联・登记簿 5 年）。詳細は 90-data/sources.md |")

# ============ 00 設計方針: 権限 action に cancel / reopen 追加 ============
sub("00-common/00-design-principles.md",
    "- `action` = view / create / update / delete / submit / approve / reject / withdraw / export / print / close / reverse。",
    "- `action` = view / create / update / delete / submit / approve / reject / withdraw / cancel / reopen / export / print / close / reverse。")

print("done")
