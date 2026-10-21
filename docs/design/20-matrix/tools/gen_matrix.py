#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Stellar ERP 详细设计书 校验与横断矩阵生成工具。

用途：
  1. 扫描 docs/design 下全部设计书，提取機能/画面/テーブル/帳票/バッチ/IF/メッセージ/権限/API 的 ID 一览。
  2. 校验：ID 重复、缺失固定文件、文書情報缺失、改訂履歴缺失、リンク切れ、机能详细化漏れ、未決マーカー件数。
  3. 生成：20-matrix/*.md（矩阵一览）、10-validation-report.md（校验报告）、data/matrix.json、
           Stellar_ERP_详细设计书一览.xlsx（Excel 一览，openpyxl）。

使用：
  python gen_matrix.py            # 生成 md + json + xlsx
  python gen_matrix.py --no-xlsx  # 只生成 md + json

注意：本脚本只读设计书，不修改设计正文。生成物位于 docs/design/20-matrix/。
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

# Windows のコンソール既定コードページによる文字化け・例外を防ぐ
for _stream in (sys.stdout, sys.stderr):
    try:
        _stream.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
    except Exception:  # noqa: BLE001
        pass

BASE = Path(__file__).resolve().parents[2]  # docs/design
MATRIX = BASE / "20-matrix"
DOMAINS = [
    ("SYS", "01-system", "系统管理"),
    ("MDM", "02-mdm", "主数据管理"),
    ("SAL", "03-sales", "销售管理"),
    ("PUR", "04-purchase", "采购管理"),
    ("INV", "05-inventory", "库存管理"),
    ("PRD", "06-production", "生产管理"),
    ("FIN", "07-finance", "财务管理"),
    ("WF", "08-workflow", "工作流"),
    ("INT", "09-integration", "集成管理"),
    ("RPT", "10-analytics", "报表分析"),
]
PREFIX_BY_DOMAIN = {
    "SYS": "sys", "MDM": "mdm", "SAL": "sal", "PUR": "pur", "INV": "inv",
    "PRD": "prd", "FIN": "fin", "WF": "wf", "INT": "int", "RPT": "rpt",
}
REQUIRED_DOMAIN_FILES = [
    "00-overview.md", "90-db-design.md", "91-api-design.md",
    "92-report-batch-design.md", "93-messages.md", "94-sample-data.md",
]
ID_PATTERNS = {
    "function": re.compile(r"^F-([A-Z]{2,4})-(\d{3})$"),
    "screen": re.compile(r"^SCR-([A-Z]{2,4})-(\d{3})$"),
    "report": re.compile(r"^PRT-([A-Z]{2,4})-(\d{3})$"),
    "batch": re.compile(r"^BAT-([A-Z]{2,4})-(\d{3})$"),
    "interface": re.compile(r"^IF-([A-Z]{2,4})-(\d{3})$"),
    "message": re.compile(r"^MSG-([A-Z]{2,4})-(\d{3})$"),
    "test": re.compile(r"^TST-F-([A-Z]{2,4})-(\d{3})-\d{2}$"),
}


def norm(s: str) -> str:
    """表头正規化：除去 markdown/空白/全角括弧等。"""
    s = s.replace("**", "").replace("`", "").strip()
    s = re.sub(r"[\s　]+", "", s)
    return s


def md_files() -> list[Path]:
    return sorted(BASE.rglob("*.md"))


def extract_tables(text: str) -> list[tuple[list[str], list[list[str]]]]:
    """Markdown テーブル抽出（第 2 行が区切り行）。"""
    lines = text.splitlines()
    tables: list[tuple[list[str], list[list[str]]]] = []
    i = 0
    while i < len(lines):
        if lines[i].lstrip().startswith("|"):
            block = []
            while i < len(lines) and lines[i].lstrip().startswith("|"):
                block.append(lines[i])
                i += 1
            if len(block) >= 2 and re.match(r"^\|[\s:\-|]+\|\s*$", block[1].strip()):
                header = [c.strip() for c in block[0].strip().strip("|").split("|")]
                rows = []
                for ln in block[2:]:
                    cells = [c.strip() for c in ln.strip().strip("|").split("|")]
                    if any(c for c in cells):
                        rows.append(cells)
                tables.append((header, rows))
            continue
        i += 1
    return tables


def find_col(header: list[str], *keywords: str) -> int | None:
    for idx, h in enumerate(header):
        hn = norm(h)
        for kw in keywords:
            if norm(kw) and norm(kw) in hn:
                return idx
    return None


def cell(row: list[str], idx: int | None) -> str:
    if idx is None or idx >= len(row):
        return ""
    return re.sub(r"\*\*|`", "", row[idx]).strip()


def clean_id(v: str) -> str:
    v = v.replace("**", "").replace("`", "").strip()
    m = re.match(r"^(F-[A-Z]{2,4}-\d{3})", v)
    if m:
        return m.group(1)
    m = re.match(r"^(SCR-[A-Z]{2,4}-\d{3})", v)
    if m:
        return m.group(1)
    for pat in ("PRT", "BAT", "IF", "MSG"):
        m = re.match(rf"^({pat}-[A-Z]{{2,4}}-\d{{3}})", v)
        if m:
            return m.group(1)
    return v.split()[0].strip("*`") if v else ""


@dataclass
class DocInfo:
    path: Path
    rel: str
    domain: str
    kind: str


@dataclass
class Collected:
    functions: list[dict] = field(default_factory=list)
    screens: list[dict] = field(default_factory=list)
    reports: list[dict] = field(default_factory=list)
    batches: list[dict] = field(default_factory=list)
    interfaces: list[dict] = field(default_factory=list)
    messages: list[dict] = field(default_factory=list)
    permissions: list[dict] = field(default_factory=list)
    apis: list[dict] = field(default_factory=list)
    tables: list[dict] = field(default_factory=list)
    docs: list[DocInfo] = field(default_factory=list)


def domain_of(path: Path) -> str:
    parts = path.relative_to(BASE).parts
    if not parts:
        return ""
    top = parts[0]
    for dom, folder, _cn in DOMAINS:
        if top == folder:
            return dom
    return "CMN" if top == "00-common" else ("MTX" if top == "20-matrix" else ("DAT" if top == "90-data" else "TOP"))


def kind_of(path: Path) -> str:
    name = path.name
    if name == "00-overview.md":
        return "overview"
    if name == "90-db-design.md":
        return "db"
    if name == "91-api-design.md":
        return "api"
    if name == "92-report-batch-design.md":
        return "report-batch"
    if name == "93-messages.md":
        return "messages"
    if name == "94-sample-data.md":
        return "sample"
    if name.startswith("00-"):
        return "index"
    return "topic"


def scan_docs() -> Collected:
    c = Collected()
    for p in md_files():
        rel = p.relative_to(BASE).as_posix()
        c.docs.append(DocInfo(path=p, rel=rel, domain=domain_of(p), kind=kind_of(p)))
    return c


def collect(c: Collected) -> None:
    for doc in c.docs:
        # 20-matrix（生成物）と 90-data（データ）は抽出対象外。含めると重複・誤検出になる。
        if doc.domain in ("MTX", "DAT", "TOP"):
            continue
        text = doc.path.read_text(encoding="utf-8", errors="ignore")
        tables = extract_tables(text)
        for header, rows in tables:
            hn = [norm(h) for h in header]

            # 機能一覧
            if find_col(header, "機能ID", "功能ID") is not None and find_col(header, "機能名", "功能名") is not None:
                i_id = find_col(header, "機能ID", "功能ID")
                i_nm = find_col(header, "機能名", "功能名")
                i_sum = find_col(header, "概要", "說明", "说明")
                i_scr = find_col(header, "画面ID", "画面")
                i_pri = find_col(header, "優先度", "优先级")
                i_sta = find_col(header, "状態", "状态")
                i_det = find_col(header, "詳細設計書", "详细设计书", "詳細")
                for row in rows:
                    fid = clean_id(cell(row, i_id))
                    if not ID_PATTERNS["function"].match(fid):
                        continue
                    c.functions.append({
                        "id": fid, "name": cell(row, i_nm), "summary": cell(row, i_sum),
                        "screens": cell(row, i_scr), "priority": cell(row, i_pri),
                        "status": cell(row, i_sta), "detail": cell(row, i_det),
                        "domain": doc.domain, "source": doc.rel,
                    })

            # 画面一覧
            if find_col(header, "画面ID") is not None and find_col(header, "画面名") is not None:
                i_id = find_col(header, "画面ID")
                i_nm = find_col(header, "画面名")
                i_type = find_col(header, "類型", "类型")
                i_fn = find_col(header, "機能ID", "功能ID")
                i_perm = find_col(header, "権限コード", "权限代码")
                for row in rows:
                    sid = clean_id(cell(row, i_id))
                    if not ID_PATTERNS["screen"].match(sid):
                        continue
                    c.screens.append({
                        "id": sid, "name": cell(row, i_nm), "type": cell(row, i_type),
                        "function": cell(row, i_fn), "permission": cell(row, i_perm),
                        "domain": doc.domain, "source": doc.rel,
                    })

            # 帳票一覧
            if find_col(header, "帳票ID", "票据ID", "帐票ID") is not None:
                i_id = find_col(header, "帳票ID", "票据ID", "帐票ID")
                i_nm = find_col(header, "帳票名", "票据名", "帐票名")
                i_tm = find_col(header, "出力", "输出", "出力タイミング")
                for row in rows:
                    rid = clean_id(cell(row, i_id))
                    if not ID_PATTERNS["report"].match(rid):
                        continue
                    c.reports.append({"id": rid, "name": cell(row, i_nm), "timing": cell(row, i_tm),
                                      "domain": doc.domain, "source": doc.rel})

            # バッチ一覧
            if find_col(header, "バッチID", "批处理ID", "作业ID") is not None:
                i_id = find_col(header, "バッチID", "批处理ID", "作业ID")
                i_nm = find_col(header, "バッチ名", "批处理名", "作业名")
                i_tm = find_col(header, "起動方式", "启动方式", "実行時間帯", "运行时间")
                for row in rows:
                    bid = clean_id(cell(row, i_id))
                    if not ID_PATTERNS["batch"].match(bid):
                        continue
                    c.batches.append({"id": bid, "name": cell(row, i_nm), "schedule": cell(row, i_tm),
                                      "domain": doc.domain, "source": doc.rel})

            # IF 一覧
            if find_col(header, "IFID") is not None or find_col(header, "IF ID") is not None:
                i_id = find_col(header, "IFID", "IF ID")
                i_nm = find_col(header, "名称", "IF名")
                i_to = find_col(header, "相手先", "对方", "外部系统")
                i_dir = find_col(header, "方向")
                i_mode = find_col(header, "方式")
                i_freq = find_col(header, "頻度", "频率")
                for row in rows:
                    iid = clean_id(cell(row, i_id))
                    if not ID_PATTERNS["interface"].match(iid):
                        continue
                    c.interfaces.append({"id": iid, "name": cell(row, i_nm), "target": cell(row, i_to),
                                         "direction": cell(row, i_dir), "mode": cell(row, i_mode),
                                         "frequency": cell(row, i_freq), "domain": doc.domain, "source": doc.rel})

            # メッセージ一覧
            # 定義表のみ対象：先頭列がメッセージ ID かつ本文列を持つ表。
            # 入力チェック表・異常表・業務コード表（91 §1.1）など ID を参照するだけの表は
            # 本文等が空のまま定義として拾われ、93 の定義を上書きしてしまうため除外する。
            # 93-messages.md の定義表は先頭列見出しが「ID」。
            # 00-common/05-common-message-list.md の定義表も先頭列見出しが「ID」（MSG-COM の唯一の定義元）。
            is_com_src = doc.rel == "00-common/05-common-message-list.md"
            is_93_def = ((doc.rel.endswith("/93-messages.md") or is_com_src)
                         and bool(header) and norm(header[0]) == norm("ID"))
            if ((find_col(header, "メッセージID", "消息ID") == 0 or is_93_def)
                    and find_col(header, "本文", "消息正文", "メッセージ本文") is not None):
                i_id = 0
                i_type = find_col(header, "種別", "类型")
                i_body = find_col(header, "本文", "消息正文", "メッセージ本文")
                i_cond = find_col(header, "発生条件", "发生条件")
                i_act = find_col(header, "対処", "处理", "处理方式")
                for row in rows:
                    mid = clean_id(cell(row, i_id))
                    if not ID_PATTERNS["message"].match(mid):
                        continue
                    # MSG-COM は 05-common-message-list.md のみを定義元とし COM 域に帰属。
                    # 各域文書の MSG-COM 行（摘要表を含む）は定義として収録しない。
                    is_com = mid.startswith("MSG-COM-")
                    if is_com != is_com_src:
                        continue
                    c.messages.append({"id": mid, "type": cell(row, i_type), "body": cell(row, i_body),
                                       "condition": cell(row, i_cond), "action": cell(row, i_act),
                                       "domain": "COM" if is_com else doc.domain, "source": doc.rel})

            # 権限一覧
            if find_col(header, "権限コード", "权限代码") is not None:
                i_p = find_col(header, "権限コード", "权限代码")
                i_fn = find_col(header, "対象機能", "对象功能", "機能")
                i_scope = find_col(header, "データ範囲", "数据范围", "範囲")
                for row in rows:
                    pc = cell(row, i_p)
                    if ":" in pc and " " not in pc:
                        c.permissions.append({"code": pc, "function": cell(row, i_fn),
                                              "scope": cell(row, i_scope), "domain": doc.domain,
                                              "source": doc.rel})

            # API 一覧
            i_m = find_col(header, "メソッド", "方法", "HTTPメソッド", "HTTP方法")
            i_path = find_col(header, "パス", "路径", "API")
            if i_m is not None and i_path is not None:
                i_name = find_col(header, "概要", "名称", "機能")
                i_perm = find_col(header, "権限", "权限", "権限コード")
                for row in rows:
                    path = cell(row, i_path)
                    if not path.startswith("/"):
                        continue
                    c.apis.append({"method": cell(row, i_m).upper(), "path": path,
                                   "name": cell(row, i_name), "permission": cell(row, i_perm),
                                   "domain": doc.domain, "source": doc.rel})

            # テーブル一覧（overview の物理名テーブル / db 設計書のテーブル物理名表）
            i_tbl = find_col(header, "物理名", "テーブル物理名")
            if i_tbl is not None:
                i_logical = find_col(header, "論理名", "逻辑名", "テーブル論理名")
                for row in rows:
                    tn = cell(row, i_tbl)
                    if re.match(r"^[a-z][a-z0-9_]{2,}$", tn) and tn.split("_")[0] in PREFIX_BY_DOMAIN.values():
                        c.tables.append({"name": tn, "logical": cell(row, i_logical),
                                         "domain": doc.domain, "source": doc.rel})

        # CREATE TABLE から物理名を補完
        for m in re.finditer(r"CREATE TABLE\s+(?:IF NOT EXISTS\s+)?([a-z][a-z0-9_]{2,})", text, re.I):
            tn = m.group(1).lower()
            if tn.split("_")[0] in PREFIX_BY_DOMAIN.values():
                c.tables.append({"name": tn, "logical": "", "domain": doc.domain, "source": doc.rel})


def dedupe(collected: Collected) -> None:
    """ID 重複を排除する。

    他域の 00-overview や関連機能表で「参照」として記載された ID が先に出現すると、
    定義元（自域の 00-overview / 93 / 90 / 91 / 92）の行が消えてしまうため、
    「ID のドメイン接頭辞が配置域と一致するか」「定義元ファイルか」で優先度を付ける。
    """
    folder_code = {folder: code for code, folder, _cn in DOMAINS}
    prefix_of = {
        "SYS": "sys_", "MDM": "mdm_", "SAL": "sal_", "PUR": "pur_", "INV": "inv_",
        "PRD": "prd_", "FIN": "fin_", "WF": "wf_", "INT": "int_", "RPT": "rpt_",
    }

    def dedup(items: list[dict], prefer_names: tuple[str, ...]) -> list[dict]:
        best: dict[str, tuple[int, dict]] = {}
        for it in items:
            key = it.get("id") or it.get("name") or it.get("code") or (it.get("method", "") + it.get("path", ""))
            src = it.get("source", "")
            name = src.rsplit("/", 1)[-1]
            folder = src.split("/", 1)[0] if "/" in src else ""
            code = folder_code.get(folder, "")
            idv = str(it.get("id") or it.get("code") or it.get("name") or "")
            score = 0
            if code and (f"-{code}-" in idv or any(idv.startswith(p) for p in [f"-{code}-"])):
                score += 3
            if code and idv.startswith(prefix_of.get(code, "@@")):
                score += 3
            if name in prefer_names:
                score += 2
            if key not in best or score > best[key][0]:
                best[key] = (score, it)
        return [v[1] for v in best.values()]

    collected.functions = dedup(collected.functions, ("00-overview.md",))
    collected.screens = dedup(collected.screens, ("00-overview.md",))
    collected.reports = dedup(collected.reports, ("00-overview.md", "92-report-batch-design.md"))
    collected.batches = dedup(collected.batches, ("00-overview.md", "92-report-batch-design.md"))
    collected.interfaces = dedup(collected.interfaces, ("00-overview.md", "92-report-batch-design.md"))
    collected.messages = dedup(collected.messages, ("93-messages.md",))
    collected.permissions = dedup(collected.permissions, ("00-overview.md",))
    collected.apis = dedup(collected.apis, ("91-api-design.md",))
    collected.tables = dedup(collected.tables, ("90-db-design.md",))


def check_links(collected: Collected) -> list[dict]:
    issues = []
    for doc in collected.docs:
        # 生成物（20-matrix）とテンプレート（_template）は設計書ではないためリンク検査対象外
        # （前者は本ツールが生成し、後者はプレースホルダ例を含む）
        if doc.rel.startswith(("20-matrix/", "_template/")):
            continue
        text = doc.path.read_text(encoding="utf-8", errors="ignore")
        # インラインコード（例示用の `[文書名](相対パス)` 等）を除外してからリンク検査
        text = re.sub(r"`[^`]*`", "", text)
        for m in re.finditer(r"\]\(([^)\s]+)\)", text):
            target = m.group(1)
            if target.startswith(("http://", "https://", "mailto:", "#")):
                continue
            if "相対パス" in target or "http" in target:
                continue
            target = target.split("#")[0]
            if not target:
                continue
            resolved = (doc.path.parent / target).resolve()
            if not resolved.exists():
                issues.append({"type": "link", "file": doc.rel, "detail": f"リンク切れ: {target}"})
    return issues


def check_docs(collected: Collected) -> list[dict]:
    issues = []
    for dom, folder, cn in DOMAINS:
        ddir = BASE / folder
        if not ddir.exists():
            issues.append({"type": "missing_domain", "file": folder, "detail": f"{cn} のディレクトリがありません"})
            continue
        for name in REQUIRED_DOMAIN_FILES:
            f = ddir / name
            if not f.exists():
                issues.append({"type": "missing_file", "file": f.relative_to(BASE).as_posix(),
                               "detail": f"{cn} の必須ファイル {name} がありません"})
    for doc in collected.docs:
        if doc.domain in ("CMN", "MTX", "DAT", "TOP"):
            continue
        head = "\n".join(doc.path.read_text(encoding="utf-8", errors="ignore").splitlines()[:25])
        if "文書番号" not in head:
            issues.append({"type": "doc_info", "file": doc.rel, "detail": "冒頭に文書情報（文書番号）がありません"})
        body = doc.path.read_text(encoding="utf-8", errors="ignore")
        if "改訂履歴" not in body:
            issues.append({"type": "revision", "file": doc.rel, "detail": "改訂履歴がありません"})
        if doc.path.stat().st_size < 400:
            issues.append({"type": "thin", "file": doc.rel, "detail": "内容が極端に少ない（400 byte 未満）"})
    return issues


def check_ids(collected: Collected) -> list[dict]:
    """ID 検証。

    他域の ID を参照（関連機能表など）することは正しい設計なので、
    ドメインコード不一致は「定義元の一覧表（00-overview.md）」だけを検査する。
    重複も定義元（00-overview / 93-messages）に限定し、参照・転記は許容する。
    """
    issues = []

    def srcname(it: dict) -> str:
        return Path(it.get("source", "")).name

    groups = [
        ("function", collected.functions, ID_PATTERNS["function"]),
        ("screen", collected.screens, ID_PATTERNS["screen"]),
        ("report", collected.reports, ID_PATTERNS["report"]),
        ("batch", collected.batches, ID_PATTERNS["batch"]),
        ("interface", collected.interfaces, ID_PATTERNS["interface"]),
        ("message", collected.messages, ID_PATTERNS["message"]),
    ]

    # 1) 形式チェック（全件）
    for kind, items, pat in groups:
        for it in items:
            key = it.get("id", "")
            if not pat.match(key):
                issues.append({"type": "id_format", "file": it.get("source", ""),
                               "detail": f"{kind} ID 形式不正: {key}"})

    # 2) ドメイン整合（定義元一覧のみ。MSG-COM はどの域でも参照可）
    for kind, items, pat in groups[:4]:  # function/screen/report/batch
        for it in items:
            m = pat.match(it.get("id", ""))
            if m and srcname(it) == "00-overview.md" and m.group(1) != it.get("domain"):
                issues.append({"type": "id_domain", "file": it.get("source", ""),
                               "detail": f"{it['id']} のドメインコード {m.group(1)} が配置域 {it.get('domain')} と不一致"})

    # 3) 重複（定義元が複数ある場合のみ）
    def dup_check(kind: str, items: list[dict], def_files: tuple[str, ...]) -> None:
        by_id: dict[str, list[dict]] = {}
        for it in items:
            if srcname(it) in def_files:
                by_id.setdefault(it.get("id", ""), []).append(it)
        for key, lst in by_id.items():
            if len(lst) > 1:
                issues.append({"type": "id_duplicate", "file": lst[0].get("source", ""),
                               "detail": f"{kind} {key} が複数ファイルで定義（{', '.join(i.get('source', '') for i in lst)}）"})

    dup_check("機能", collected.functions, ("00-overview.md",))
    dup_check("画面", collected.screens, ("00-overview.md",))
    dup_check("帳票", collected.reports, ("00-overview.md", "92-report-batch-design.md"))
    dup_check("バッチ", collected.batches, ("00-overview.md", "92-report-batch-design.md"))
    dup_check("メッセージ", collected.messages, ("93-messages.md", "05-common-message-list.md"))
    return issues


def check_functions(collected: Collected) -> list[dict]:
    """機能が概要書だけでなく詳細設計に登場するか。"""
    issues = []
    all_text = {doc.rel: doc.path.read_text(encoding="utf-8", errors="ignore") for doc in collected.docs}
    for fn in collected.functions:
        fid = fn["id"]
        if fid.startswith("F-") is False:
            continue
        refs = [rel for rel, text in all_text.items() if fid in text and rel != fn["source"]]
        if not refs:
            issues.append({"type": "not_detailed", "file": fn["source"],
                           "detail": f"{fid} {fn.get('name','')} が詳細設計文書に記載されていません"})
    return issues


def check_undecided(collected: Collected) -> tuple[list[dict], int]:
    hits = []
    total = 0
    for doc in collected.docs:
        if doc.domain in ("MTX",):
            continue
        text = doc.path.read_text(encoding="utf-8", errors="ignore")
        for lineno, line in enumerate(text.splitlines(), start=1):
            if "【未決】" in line or "【要確認】" in line:
                total += 1
                if len(hits) < 200:
                    hits.append({"file": doc.rel, "line": lineno, "text": line.strip()[:180]})
    return hits, total


def per_domain_counts(collected: Collected) -> dict:
    counts = {}
    for dom, folder, cn in DOMAINS:
        counts[dom] = {
            "name": cn, "folder": folder,
            "functions": sum(1 for x in collected.functions if x["domain"] == dom),
            "screens": sum(1 for x in collected.screens if x["domain"] == dom),
            "tables": len({t["name"] for t in collected.tables if t["domain"] == dom}),
            "reports": sum(1 for x in collected.reports if x["domain"] == dom),
            "batches": sum(1 for x in collected.batches if x["domain"] == dom),
            "interfaces": sum(1 for x in collected.interfaces if x["domain"] == dom),
            "messages": sum(1 for x in collected.messages if x["domain"] == dom),
            "apis": sum(1 for x in collected.apis if x["domain"] == dom),
        }
    return counts


def esc(v: str) -> str:
    v = str(v).replace("|", "／").replace("\n", " ")
    # 生成一覧のセル内相対リンクは 20-matrix からの相対パスとして壊れるため、表示名のみ残す
    v = re.sub(r"\[([^\]]*)\]\(([^)\s]+)\)", r"\1", v)
    return v


def write_md(path: Path, title: str, doc_no: str, intro: str, header: list[str], rows: list[list[str]]) -> None:
    lines = [
        f"# {title}",
        "",
        "| 項目 | 内容 |",
        "|---|---|",
        f"| 文書名 | {title}（自动生成） |",
        f"| 文書番号 | {doc_no} |",
        "| 版数 | v1.0 |",
        "| 作成日 | 2026-10-20 |",
        "| 作成者 | Lead（生成工具 gen_matrix.py） |",
        "| 状態 | ドラフト（自动生成・最終レビュー前） |",
        f"| 備考 | {intro} |",
        "",
        "> 本文件由 `20-matrix/tools/gen_matrix.py` 从各域设计书中自动提取生成。修改设计书后重新运行即可更新。",
        "",
        "| " + " | ".join(header) + " |",
        "|" + "|".join(["---"] * len(header)) + "|",
    ]
    for row in rows:
        lines.append("| " + " | ".join(esc(c) for c in row) + " |")
    lines += ["", "## 改訂履歴", "", "| 版数 | 日付 | 変更内容 | 変更者 |", "|---|---|---|---|",
              "| v1.0 | 2026-10-20 | 自动生成 | gen_matrix.py |", ""]
    path.write_text("\n".join(lines), encoding="utf-8")


def generate_matrices(collected: Collected, counts: dict) -> list[str]:
    MATRIX.mkdir(parents=True, exist_ok=True)
    written = []

    rows = [[f["id"], f["name"], f["summary"], f["screens"], f["priority"], f["status"], f["detail"], f["domain"], f["source"]]
            for f in sorted(collected.functions, key=lambda x: (x["domain"], x["id"]))]
    write_md(MATRIX / "01-feature-list.md", "機能一覧（功能一览）", "DSN-MTX-001",
             f"全 {len(rows)} 件。機能ID/名称/概要/画面/優先度/状態/詳細設計書/域/提取元", 
             ["機能 ID", "機能名", "概要", "画面 ID", "優先度", "状態", "詳細設計書", "域", "提取元"], rows)
    written.append("01-feature-list.md")

    rows = [[s["id"], s["name"], s["type"], s["function"], s["permission"], s["domain"], s["source"]]
            for s in sorted(collected.screens, key=lambda x: (x["domain"], x["id"]))]
    write_md(MATRIX / "02-screen-list.md", "画面一覧（画面一览）", "DSN-MTX-002",
             f"全 {len(rows)} 件。画面ID/名称/類型/機能/権限/域/提取元",
             ["画面 ID", "画面名", "類型", "機能 ID", "権限コード", "域", "提取元"], rows)
    written.append("02-screen-list.md")

    rows = [[t["name"], t["logical"], t["domain"], t["source"]] for t in
            sorted(collected.tables, key=lambda x: (x["domain"], x["name"]))]
    write_md(MATRIX / "03-table-list.md", "テーブル一覧（表一览）", "DSN-MTX-003",
             f"全 {len(rows)} 件。物理名/論理名/域/提取元",
             ["物理名", "論理名", "域", "提取元"], rows)
    written.append("03-table-list.md")

    rows = [[r["id"], r["name"], r["timing"], r["domain"], r["source"]]
            for r in sorted(collected.reports, key=lambda x: (x["domain"], x["id"]))]
    write_md(MATRIX / "04-report-list.md", "帳票一覧（票据一览）", "DSN-MTX-004",
             f"全 {len(rows)} 件。帳票ID/名称/出力契機/域/提取元",
             ["帳票 ID", "帳票名", "出力契機", "域", "提取元"], rows)
    written.append("04-report-list.md")

    rows = [[b["id"], b["name"], b["schedule"], b["domain"], b["source"]]
            for b in sorted(collected.batches, key=lambda x: (x["domain"], x["id"]))]
    write_md(MATRIX / "05-batch-list.md", "バッチ一覧（批处理一览）", "DSN-MTX-005",
             f"全 {len(rows)} 件。バッチID/名称/起動方式/域/提取元",
             ["バッチ ID", "バッチ名", "起動方式/時間", "域", "提取元"], rows)
    written.append("05-batch-list.md")

    rows = [[i["id"], i["name"], i["target"], i["direction"], i["mode"], i["frequency"], i["domain"], i["source"]]
            for i in sorted(collected.interfaces, key=lambda x: (x["domain"], x["id"]))]
    write_md(MATRIX / "06-interface-list.md", "インタフェース一覧（接口一览）", "DSN-MTX-006",
             f"全 {len(rows)} 件。IFID/名称/相手先/方向/方式/頻度/域/提取元",
             ["IF ID", "名称", "相手先", "方向", "方式", "頻度", "域", "提取元"], rows)
    written.append("06-interface-list.md")

    rows = [[m["id"], m["type"], m["body"], m["condition"], m["action"], m["domain"], m["source"]]
            for m in sorted(collected.messages, key=lambda x: (x["domain"], x["id"]))]
    write_md(MATRIX / "07-message-list.md", "メッセージ一覧（消息一览）", "DSN-MTX-007",
             f"全 {len(rows)} 件。メッセージID/種別/本文/発生条件/対処/域/提取元",
             ["メッセージ ID", "種別", "本文", "発生条件", "対処", "域", "提取元"], rows)
    written.append("07-message-list.md")

    # 権限マトリクス
    perm_map: dict[str, dict] = {}
    for p in collected.permissions:
        perm_map.setdefault(p["code"], p)
    rows = [[p["code"], p["domain"], p["function"], p["scope"], p["source"]]
            for p in sorted(perm_map.values(), key=lambda x: x["code"])]
    write_md(MATRIX / "08-permission-list.md", "機能権限一覧（功能权限一览）", "DSN-MTX-008",
             f"全 {len(rows)} 件。権限コード/域/対象機能/データ範囲/提取元",
             ["権限コード", "域", "対象機能", "データ範囲", "提取元"], rows)
    written.append("08-permission-list.md")

    # API 一覧
    rows = [[a["method"], a["path"], a["name"], a["permission"], a["domain"], a["source"]]
            for a in sorted(collected.apis, key=lambda x: (x["domain"], x["path"], x["method"]))]
    write_md(MATRIX / "09-api-list.md", "API 一覧（接口一览）", "DSN-MTX-009",
             f"全 {len(rows)} 件。メソッド/パス/概要/権限/域/提取元",
             ["メソッド", "パス", "概要", "権限コード", "域", "提取元"], rows)
    written.append("09-api-list.md")

    # 域別集計
    rows = [[d, counts[d]["name"], counts[d]["functions"], counts[d]["screens"], counts[d]["tables"],
             counts[d]["reports"], counts[d]["batches"], counts[d]["messages"], counts[d]["apis"]]
            for d in counts]
    write_md(MATRIX / "00-domain-summary.md", "域別集計（域别汇总）", "DSN-MTX-000",
             "域ごとの設計件数。00 はサマリ、01-09 が詳細一覧",
             ["域", "名称", "機能数", "画面数", "テーブル数", "帳票数", "バッチ数", "メッセージ数", "API 数"], rows)
    written.insert(0, "00-domain-summary.md")

    return written


def generate_report(collected: Collected, counts: dict, issues_by_type: dict[str, list[dict]],
                    undecided: list[dict], undecided_total: int, matrices: list[str]) -> None:
    lines = [
        "# 设计书校验报告（設計書検証レポート）",
        "",
        "| 項目 | 内容 |",
        "|---|---|",
        "| 文書名 | 设计书校验报告（自动生成） |",
        "| 文書番号 | DSN-MTX-010 |",
        "| 版数 | v1.0 |",
        "| 作成日 | 2026-10-20 |",
        "| 作成者 | Lead（生成工具 gen_matrix.py） |",
        "| 状態 | ドラフト |",
        "",
        "> 本报告由 `20-matrix/tools/gen_matrix.py` 自动生成，用于最终一致性审查。",
        "",
        "## 1. 集計サマリ",
        "",
        "| 指標 | 値 |",
        "|---|---|",
        f"| 設計書ファイル数 | {len(collected.docs)} |",
        f"| 機能数 | {len(collected.functions)} |",
        f"| 画面数 | {len(collected.screens)} |",
        f"| テーブル数 | {len(collected.tables)} |",
        f"| 帳票数 | {len(collected.reports)} |",
        f"| バッチ数 | {len(collected.batches)} |",
        f"| IF 数 | {len(collected.interfaces)} |",
        f"| メッセージ数 | {len(collected.messages)} |",
        f"| 権限コード数 | {len(collected.permissions)} |",
        f"| API 数 | {len(collected.apis)} |",
        f"| 未決・要確認マーカー | {undecided_total} |",
        "",
        "## 2. 域別件数",
        "",
        "| 域 | 名称 | 機能 | 画面 | テーブル | 帳票 | バッチ | メッセージ | API |",
        "|---|---|---|---|---|---|---|---|---|",
    ]
    for d, v in counts.items():
        lines.append(f"| {d} | {v['name']} | {v['functions']} | {v['screens']} | {v['tables']} | {v['reports']} | {v['batches']} | {v['messages']} | {v['apis']} |")
    lines += ["", "## 3. 検証結果一覧", ""]
    all_issues = []
    for kind, items in issues_by_type.items():
        all_issues.extend(items)
        lines.append(f"### 3.{len(issues_by_type)} {kind}（{len(items)} 件）")
        lines.append("")
        if not items:
            lines.append("問題なし。")
        else:
            lines += ["| ファイル | 内容 |", "|---|---|"]
            for it in items[:80]:
                lines.append(f"| {esc(it.get('file', ''))} | {esc(it.get('detail', ''))} |")
            if len(items) > 80:
                lines.append(f"| ... | 他 {len(items) - 80} 件（data/matrix.json 参照） |")
        lines.append("")

    lines += ["## 4. 未決・要確認マーカー（先頭 50 件）", ""]
    if undecided:
        lines += ["| ファイル | 行 | 内容 |", "|---|---|---|"]
        for u in undecided[:50]:
            lines.append(f"| {esc(u['file'])} | {u['line']} | {esc(u['text'])} |")
    else:
        lines.append("なし。")
    lines += ["", "## 5. 生成マトリクス", ""]
    for m in matrices:
        lines.append(f"- [{m}]({m})")
    lines += ["", "## 改訂履歴", "", "| 版数 | 日付 | 変更内容 | 変更者 |", "|---|---|---|---|",
              "| v1.0 | 2026-10-20 | 自动生成 | gen_matrix.py |", ""]
    (MATRIX / "10-validation-report.md").write_text("\n".join(lines), encoding="utf-8")


def generate_xlsx(collected: Collected, counts: dict, issues: list[dict]) -> None:
    try:
        from openpyxl import Workbook
        from openpyxl.styles import Font, PatternFill, Alignment
    except Exception as e:  # noqa: BLE001
        print(f"[WARN] openpyxl が使用できないため Excel 出力をスキップ: {e}")
        return
    wb = Workbook()
    wb.remove(wb.active)
    head_font = Font(bold=True, color="FFFFFF")
    head_fill = PatternFill("solid", fgColor="305496")
    alt_fill = PatternFill("solid", fgColor="F2F2F2")

    def sheet(name: str, header: list[str], rows: list[list], widths: list[int]) -> None:
        ws = wb.create_sheet(name[:31])
        ws.append(header)
        for c in ws[1]:
            c.font = head_font
            c.fill = head_fill
            c.alignment = Alignment(horizontal="center")
        for row in rows:
            ws.append(row)
        for i, w in enumerate(widths, start=1):
            ws.column_dimensions[ws.cell(row=1, column=i).column_letter].width = w
        ws.freeze_panes = "A2"
        for r in range(2, ws.max_row + 1):
            if r % 2 == 0:
                for c in ws[r]:
                    c.fill = alt_fill
                    c.alignment = Alignment(vertical="top", wrap_text=True)

    sheet("域别汇总", ["域", "名称", "功能数", "画面数", "テーブル数", "帳票数", "バッチ数", "メッセージ数", "API数"],
          [[d, v["name"], v["functions"], v["screens"], v["tables"], v["reports"], v["batches"], v["messages"], v["apis"]] for d, v in counts.items()],
          [8, 14, 8, 8, 10, 8, 8, 10, 8])
    sheet("機能一覧", ["機能ID", "機能名", "概要", "画面ID", "優先度", "状態", "詳細設計書", "域", "提取元"],
          [[f["id"], f["name"], f["summary"], f["screens"], f["priority"], f["status"], f["detail"], f["domain"], f["source"]] for f in sorted(collected.functions, key=lambda x: x["id"])],
          [14, 28, 40, 16, 8, 10, 24, 8, 34])
    sheet("画面一覧", ["画面ID", "画面名", "類型", "機能ID", "権限", "域", "提取元"],
          [[s["id"], s["name"], s["type"], s["function"], s["permission"], s["domain"], s["source"]] for s in sorted(collected.screens, key=lambda x: x["id"])],
          [14, 28, 14, 14, 28, 8, 34])
    sheet("テーブル一覧", ["物理名", "論理名", "域", "提取元"],
          [[t["name"], t["logical"], t["domain"], t["source"]] for t in sorted(collected.tables, key=lambda x: (x["domain"], x["name"]))],
          [28, 28, 8, 34])
    sheet("帳票一覧", ["帳票ID", "帳票名", "出力契機", "域", "提取元"],
          [[r["id"], r["name"], r["timing"], r["domain"], r["source"]] for r in sorted(collected.reports, key=lambda x: x["id"])],
          [14, 32, 20, 8, 34])
    sheet("バッチ一覧", ["バッチID", "バッチ名", "起動方式", "域", "提取元"],
          [[b["id"], b["name"], b["schedule"], b["domain"], b["source"]] for b in sorted(collected.batches, key=lambda x: x["id"])],
          [14, 32, 20, 8, 34])
    sheet("IF一覧", ["IFID", "名称", "相手先", "方向", "方式", "頻度", "域", "提取元"],
          [[i["id"], i["name"], i["target"], i["direction"], i["mode"], i["frequency"], i["domain"], i["source"]] for i in sorted(collected.interfaces, key=lambda x: x["id"])],
          [12, 28, 20, 10, 12, 12, 8, 34])
    sheet("メッセージ一覧", ["メッセージID", "種別", "本文", "発生条件", "対処", "域", "提取元"],
          [[m["id"], m["type"], m["body"], m["condition"], m["action"], m["domain"], m["source"]] for m in sorted(collected.messages, key=lambda x: x["id"])],
          [16, 6, 50, 30, 30, 8, 34])
    sheet("権限一覧", ["権限コード", "域", "対象機能", "データ範囲", "提取元"],
          [[p["code"], p["domain"], p["function"], p["scope"], p["source"]] for p in sorted(collected.permissions, key=lambda x: x["code"])],
          [30, 8, 30, 16, 34])
    sheet("API一覧", ["メソッド", "パス", "概要", "権限", "域", "提取元"],
          [[a["method"], a["path"], a["name"], a["permission"], a["domain"], a["source"]] for a in sorted(collected.apis, key=lambda x: (x["domain"], x["path"]))],
          [10, 44, 30, 26, 8, 34])
    sheet("检查结果", ["类型", "文件", "内容"],
          [[i.get("type", ""), i.get("file", ""), i.get("detail", "")] for i in issues],
          [18, 40, 80])
    out = MATRIX / "Stellar_ERP_详细设计书一览.xlsx"
    wb.save(out)
    print(f"[OK] Excel 出力: {out.relative_to(BASE)}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--no-xlsx", action="store_true", help="Excel 出力をスキップ")
    args = parser.parse_args()

    collected = scan_docs()
    collect(collected)
    dedupe(collected)
    counts = per_domain_counts(collected)

    issues_by_type: dict[str, list[dict]] = {
        "missing": [],
        "doc_format": [],
    }
    doc_issues = check_docs(collected)
    for it in doc_issues:
        key = "missing" if it["type"].startswith("missing") else "doc_format"
        issues_by_type[key].append(it)
    issues_by_type["link"] = check_links(collected)
    issues_by_type["id"] = check_ids(collected)
    issues_by_type["coverage"] = check_functions(collected)
    undecided, undecided_total = check_undecided(collected)

    all_issues = [i for items in issues_by_type.values() for i in items]
    matrices = generate_matrices(collected, counts)
    generate_report(collected, counts, issues_by_type, undecided, undecided_total, matrices)

    data_dir = MATRIX / "data"
    data_dir.mkdir(parents=True, exist_ok=True)
    (data_dir / "matrix.json").write_text(json.dumps({
        "counts": counts,
        "functions": collected.functions,
        "screens": collected.screens,
        "tables": collected.tables,
        "reports": collected.reports,
        "batches": collected.batches,
        "interfaces": collected.interfaces,
        "messages": collected.messages,
        "permissions": collected.permissions,
        "apis": collected.apis,
        "issues": all_issues,
        "undecided": undecided,
        "undecidedTotal": undecided_total,
    }, ensure_ascii=False, indent=2), encoding="utf-8")

    if not args.no_xlsx:
        generate_xlsx(collected, counts, all_issues)

    print("=== 集計 ===")
    print(f"設計書: {len(collected.docs)} ファイル / 機能: {len(collected.functions)} / 画面: {len(collected.screens)} / "
          f"テーブル: {len(collected.tables)} / 帳票: {len(collected.reports)} / バッチ: {len(collected.batches)} / "
          f"IF: {len(collected.interfaces)} / メッセージ: {len(collected.messages)} / API: {len(collected.apis)}")
    print(f"未決・要確認: {undecided_total} 件 / 検証指摘: {len(all_issues)} 件")
    for kind, items in issues_by_type.items():
        print(f"  - {kind}: {len(items)}")
    print(f"出力: {(MATRIX / '10-validation-report.md').relative_to(BASE)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
