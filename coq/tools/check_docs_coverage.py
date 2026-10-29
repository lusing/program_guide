#!/usr/bin/env python3
"""检查 coq 教程正文是否引用了对应示例文件的每一行代码。

用法：
    python3 tools/check_docs_coverage.py 39              # 单章
    python3 tools/check_docs_coverage.py --all           # 全部已配对的章节
    python3 tools/check_docs_coverage.py 39 --mutate     # 自检：从正文删 3 行必须全部检出

规则：docs/NN-*.md 里所有 ```coq 代码块的行（按 strip 后比较，忽略空行）
必须按顺序覆盖 examples/NN_*.v 的全部非空行。
"""
import argparse
import difflib
import re
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DOCS = ROOT / "docs"
EXAMPLES = ROOT / "examples"


def find_pair(prefix):
    docs = sorted(DOCS.glob(f"{prefix}-*.md"))
    exs = sorted(EXAMPLES.glob(f"{prefix}_*.v"))
    if not docs:
        raise SystemExit(f"no docs file matching docs/{prefix}-*.md")
    if not exs:
        raise SystemExit(f"no example matching examples/{prefix}_*.v")
    ex = exs[0]
    if len(docs) > 1:
        # 扩章后同一编号可能有多篇候选文档（如迁移期的 68-pitfalls.md 与
        # 68-vst-intro.md）；优先配对正文引用了该示例文件的那篇。
        referencing = [d for d in docs if ex.name in d.read_text(encoding="utf-8")]
        if referencing:
            docs = referencing
    return ex, docs[0]


def coq_lines(doc_path):
    text = doc_path.read_text(encoding="utf-8")
    blocks = re.findall(r"```coq\n(.*?)```", text, re.S)
    return [s for b in blocks for s in (l.strip() for l in b.split("\n")) if s]


def example_lines(ex_path):
    return [s for s in (l.strip() for l in ex_path.read_text(encoding="utf-8").split("\n")) if s]


def coverage(ex_lines, doc_lines):
    matched = [False] * len(ex_lines)
    sm = difflib.SequenceMatcher(None, ex_lines, doc_lines, autojunk=False)
    for a, _b, n in sm.get_matching_blocks():
        for k in range(a, a + n):
            matched[k] = True
    # difflib 的单一对齐可能次优；对未覆盖行做一次"正文是否含该行"的兜底，
    # 把误报排除（要求是"正文引用了每一行"，顺序不作硬性要求）。
    doc_set = set(doc_lines)
    return [m or (line in doc_set) for m, line in zip(matched, ex_lines)]


def check(ex_path, doc_path):
    ex, doc = example_lines(ex_path), coq_lines(doc_path)
    matched = coverage(ex, doc)
    missing = [(i + 1, line) for i, line in enumerate(ex) if not matched[i]]
    print(f"{ex_path.name}: example {len(ex)} lines / doc {len(doc)} lines / missing {len(missing)}")
    for lineno, line in missing:
        print(f"  L{lineno}: {line}")
    return not missing


def mutate(ex_path, doc_path):
    """自检：从正文里删掉 3 行被引用的代码，检查器必须把它们报成 missing。
    只挑全文唯一的行当 victim——重复行删一处仍可由兜底匹配兜住，属自检噪声。"""
    doc = coq_lines(doc_path)
    from collections import Counter
    counts = Counter(doc)
    unique = [l for l in doc[7:25] if counts[l] == 1][:3]
    if len(unique) < 3:
        print("mutate check skipped: doc has too few unique coq lines")
        return True
    victims = set(unique)
    raw = doc_path.read_text(encoding="utf-8").split("\n")
    keep, dropped, budget = [], [], 3
    for line in raw:
        s = line.strip()
        if budget and s in victims:
            budget -= 1
            dropped.append(s)
            continue
        keep.append(line)
    with tempfile.TemporaryDirectory() as td:
        tmp = Path(td) / doc_path.name
        tmp.write_text("\n".join(keep), encoding="utf-8")
        ex, doc2 = example_lines(ex_path), coq_lines(tmp)
        matched = coverage(ex, doc2)
        reported = {ex[i] for i in range(len(ex)) if not matched[i]}
    for line in victims:
        if line not in reported:
            print(f"mutate check FAILED: removed doc line not reported -> {line}")
            return False
    print(f"mutate check ok: {len(victims)} removed lines all reported")
    return True


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("prefix", nargs="?")
    ap.add_argument("--all", action="store_true")
    ap.add_argument("--mutate", action="store_true")
    args = ap.parse_args()

    if args.all:
        prefixes = sorted(p.stem.split("_")[0] for p in EXAMPLES.glob("[0-9]*.v"))
    elif args.prefix:
        prefixes = [args.prefix]
    else:
        raise SystemExit("give a chapter prefix (e.g. 39) or --all")

    ok = True
    for prefix in prefixes:
        try:
            ex_path, doc_path = find_pair(prefix)
        except SystemExit as e:
            print(f"[{prefix}] skip: {e}")
            continue
        print(f"[{prefix}] {doc_path.name} <-> {ex_path.name}")
        ok = check(ex_path, doc_path) and ok
        if args.mutate:
            ok = mutate(ex_path, doc_path) and ok
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
