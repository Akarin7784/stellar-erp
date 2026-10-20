#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""红队评审指摘の抽出・集計（R-*.md → findings.json / 集計表）。"""
import json
import re
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")
root = Path(__file__).resolve().parents[2]  # docs/design
review_dir = root / "30-review"

DOMAIN_MAP = {
    "R-data-researcher.md": ("DR", "FIN/RPT/90-data"),
    "R-system-workflow.md": ("SW", "00-common/INT"),
    "R-mdm-designer.md": ("MDM", "SAL/PUR"),
    "R-sales-designer.md": ("SAL", "INV/PRD"),
    "R-purchase-designer.md": ("PUR", "MDM/WF"),
    "R-inventory-designer.md": ("INV", "SYS/PRD"),
    "R-production-designer.md": ("PRD", "SAL/FIN"),
    "R-finance-designer.md": ("FIN", "MDM/90-data"),
}


def main() -> int:
    findings = []
    for p in sorted(review_dir.glob("R-*.md")):
        reviewer, targets = DOMAIN_MAP.get(p.name, (p.stem, "?"))
        text = p.read_text(encoding="utf-8")
        for line in text.splitlines():
            s = line.strip()
            if not s.startswith("|"):
                continue
            cells = [c.strip() for c in s.strip("|").split("|")]
            if len(cells) < 3:
                continue
            c0 = cells[0].replace("**", "")
            if not re.match(r"REV-[A-Za-z0-9-]+", c0):
                continue
            # 重大度セル
            sev = ""
            for c in cells[1:4]:
                m = re.search(r"\b(S[1-4])\b", c)
                if m:
                    sev = m.group(1)
                    break
            detail = " / ".join(cells[2:6])[:300]
            findings.append({
                "id": c0,
                "severity": sev or "?",
                "reviewer": reviewer,
                "targets": targets,
                "detail": detail,
                "file": p.name,
            })

    # 集計
    from collections import Counter
    sev = Counter(f["severity"] for f in findings)
    by_rev = Counter(f["reviewer"] for f in findings)
    print("total findings:", len(findings))
    print("severity:", dict(sev))
    print("by reviewer:", dict(by_rev))
    out = review_dir / "tools" / "findings.json"
    out.write_text(json.dumps(findings, ensure_ascii=False, indent=2), encoding="utf-8")
    print("written:", out.relative_to(root))

    # S1/S2 一覧
    print("\n=== S1/S2 findings ===")
    for f in findings:
        if f["severity"] in ("S1", "S2"):
            print(f"{f['severity']} {f['id']:22s} [{f['reviewer']}] {f['detail'][:150]}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
