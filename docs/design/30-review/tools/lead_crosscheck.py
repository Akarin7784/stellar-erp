#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Lead 红队自动检查 v2：跨文档一致性攻击（事件/J番号/交易类型/分类/税码/消息/数值勾稽）。"""
import re
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")
root = Path(__file__).resolve().parents[2]  # docs/design


def read(rel: str) -> str:
    return (root / rel).read_text(encoding="utf-8")


def main() -> int:
    findings = []

    # --- A. 09 事件定義 ---
    flow = read("00-common/09-cross-domain-flow.md")
    ev_def = {}
    for m in re.finditer(r"\|\s*(E\d{2})\s*\|\s*`([a-z][a-z.]+)`", flow):
        ev_def[m.group(1)] = m.group(2)
    expected = {f"E{i:02d}" for i in range(1, 44)}
    missing = sorted(expected - set(ev_def))
    print(f"A. events defined in 09: {len(ev_def)}/43; missing={missing}")
    if missing:
        findings.append(("A", "09 event table missing", missing))

    # ドメイン文書: 「| E## | `event.name` |」形式（行頭が E##）のみ定義とみなす
    mismatch = []
    pat = re.compile(r"^\s*\|\s*(E\d{2})\s*\|\s*`([a-z][a-z.]+)`")
    for p in root.rglob("*.md"):
        if "20-matrix" in str(p) or "30-review" in str(p):
            continue
        for i, line in enumerate(p.read_text(encoding="utf-8").splitlines(), 1):
            m = pat.match(line)
            if m and m.group(1) in ev_def and ev_def[m.group(1)] != m.group(2):
                mismatch.append((str(p.relative_to(root)), i, m.group(1), ev_def[m.group(1)], m.group(2)))
    print(f"   strict event-table mismatches: {len(mismatch)}")
    for x in mismatch[:20]:
        print("   ", x)
    if mismatch:
        findings.append(("A", "event name mismatch", mismatch))

    # --- B. J 番号 ---
    j09 = set(re.findall(r"\|\s*(J\d{2})\s*\|", flow))
    jfin = set(re.findall(r"(J\d{2})", read("07-finance/06-auto-voucher-costing.md")))
    only09, onlyfin = sorted(j09 - jfin), sorted(jfin - j09)
    print(f"B. journal rules: 09={len(j09)}, FIN={len(jfin)}; only09={only09}, onlyFIN={onlyfin}")
    if only09 or onlyfin:
        findings.append(("B", "journal mismatch", only09 + onlyfin))

    # --- C. 在庫取引 19 型 ---
    expected_types = ["PI", "SI", "MII", "MIR", "FGI", "OSI", "OSR", "TR_OUT", "TR_IN", "ADJ_IN",
                      "ADJ_OUT", "SC_IN", "SC_OUT", "AOI", "AOO", "RT_IN", "PR_OUT", "ST_IN", "ST_OUT"]
    inv_text = read("05-inventory/00-overview.md") + read("05-inventory/02-inbound-outbound.md")
    miss = [c for c in expected_types if c not in inv_text]
    print(f"C. inventory txn types referenced: {len(expected_types) - len(miss)}/19; missing={miss}")
    if miss:
        findings.append(("C", "txn types missing", miss))

    # --- D. 物料分類 06 §11 vs material-category.csv ---
    cl = read("00-common/06-code-list.md")
    sec11 = cl.split("## 11.")[1].split("## 12.")[0]
    codes06 = set(re.findall(r"\b(1[0-9]{3}|2[0-9]{3}|3[0-9]{3}|4[0-9]{3}|5[0-9]{3}|6[0-9]{3}|7[0-9]{3}|9[0-9]{3})\b", sec11))
    csv_lines = read("90-data/code-lists/material-category.csv").splitlines()
    header = csv_lines[0].split(",")
    idx = 0  # category_code が先頭列（README §4.1 で定義）
    codescsv = set()
    for line in csv_lines[1:]:
        cells = line.split(",")
        if len(cells) > idx and re.fullmatch(r"\d{4}", cells[idx].strip()):
            codescsv.add(cells[idx].strip())
    print(f"D. material categories: 06={len(codes06)}, csv={len(codescsv)}; 06-only={sorted(codes06 - codescsv)}, csv-only={sorted(codescsv - codes06)}")
    if codes06 - codescsv:
        findings.append(("D", "06 has categories not in CSV", sorted(codes06 - codescsv)))
    if codescsv - codes06:
        findings.append(("D", "CSV has categories not in 06", sorted(codescsv - codes06)))

    # --- E. 税码 06 §7 vs tax.csv ---
    sec7 = cl.split("## 7.")[1].split("## 8.")[0]
    tax06 = set(re.findall(r"\|\s*`?([A-Z][A-Z0-9-]{1,})`?\s*\|", sec7))
    tax06 = {t for t in tax06 if t not in {"E", "W", "I", "C", "ID"}}
    csv_lines = read("90-data/code-lists/tax.csv").splitlines()
    taxcsv = set()
    for line in csv_lines[1:]:
        cells = line.split(",")
        if cells and re.fullmatch(r"[A-Z][A-Z0-9-]+", cells[0].strip()):
            taxcsv.add(cells[0].strip())
    print(f"E. tax codes: 06={len(tax06)}, csv={len(taxcsv)}; csv-only={sorted(taxcsv - tax06)}, 06-only={sorted(tax06 - taxcsv)}")
    if taxcsv - tax06:
        findings.append(("E", "tax codes in CSV not in 06", sorted(taxcsv - tax06)))

    # --- F. 承認シナリオ ---
    asc = sorted(set(re.findall(r"\b(A\d{2})\b", read("90-data/approval-matrix.md"))))
    print(f"F. approval scenarios: {len(asc)} ({asc[0] if asc else '-'}..{asc[-1] if asc else '-'})")

    # --- G. メッセージ定義重複（ドメイン固有 MSG-{DOM} のみ） ---
    msg_def = {}
    dup = []
    for p in root.rglob("93-messages.md"):
        if "20-matrix" in str(p) or "30-review" in str(p):
            continue
        for m in re.finditer(r"\|\s*(MSG-([A-Z]{3})-\d{3})\s*\|", p.read_text(encoding="utf-8")):
            mid, dom = m.group(1), m.group(2)
            if dom == "COM":
                continue
            if mid in msg_def and msg_def[mid] != str(p):
                dup.append((mid, msg_def[mid], str(p.relative_to(root))))
            msg_def.setdefault(mid, str(p.relative_to(root)))
    domain_msgs = len(msg_def)
    print(f"G. domain message definitions: {domain_msgs}, duplicate MSG-{DOM} across files: {len(dup)}")
    for d in dup[:10]:
        print("   ", d)
    if dup:
        findings.append(("G", "duplicate domain message IDs", dup))

    # --- H. 財務數值勾稽 ---
    fin_all = "\n".join(read(f"07-finance/{f}") for f in
                        ["00-overview.md", "06-auto-voucher-costing.md", "07-period-reporting.md", "94-sample-data.md"])
    bs_ok = "20,988,297.80" in fin_all
    print("H. finance BS: assets found =", bs_ok)
    if not bs_ok:
        findings.append(("H", "BS total missing", []))
    else:
        diff = abs((9_471_200.00 + 11_517_097.80) - 20_988_297.80)
        print(f"   liabilities+equity vs assets diff = {diff:.2f}")
        if diff > 0.005:
            findings.append(("H", "BS not balanced", [diff]))

    # --- I. 材料分類大分類の整合（06 §11 上位2桁） ---
    big06 = {c[:2] for c in codes06}
    print(f"I. big categories in 06: {sorted(big06)}")

    print(f"\n[Lead crosscheck v2] finding groups: {len(findings)}")
    for f in findings:
        print(" -", f[0], f[1], f[2][:5] if isinstance(f[2], list) else f[2])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
