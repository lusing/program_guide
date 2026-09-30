#!/usr/bin/env python3
"""一次性统稿：按各章真实 H1 标题重写全部章末导航的链接文字。

用法：python tools/reconcile-nav.py          （幂等；改了哪些行会打印）
      python tools/reconcile-nav.py --dry    只打印不落盘
"""
import re
import sys
from pathlib import Path

DOCS = Path(__file__).resolve().parents[1] / "docs"
DRY = "--dry" in sys.argv

# 1) 收集每章标题：{文件名: "NN · 标题"}
titles = {}
for md in sorted(DOCS.glob("[0-9][0-9]-*.md")):
    for ln in md.read_text(encoding="utf-8").splitlines():
        if ln.startswith("# "):
            titles[md.name] = ln[2:].strip()
            break

changed = []
for md in sorted(DOCS.glob("[0-9][0-9]-*.md")):
    text = md.read_text(encoding="utf-8")
    lines = text.splitlines()

    # 找章末导航行（最后一处以"上一章："开头的行）
    nav_idx = None
    for i, ln in enumerate(lines):
        if ln.startswith("上一章："):
            nav_idx = i
    if nav_idx is None:
        print(f"[跳过] {md.name} 没找到章末导航行")
        continue

    def fix(m):
        label, target = m.group(1), m.group(2)
        want = titles.get(target)
        if want and label != want:
            return f"[{want}]({target})"
        return m.group(0)

    new_nav = re.sub(r"\[([^\]]+)\]\((([0-9]{2}-[^)/]+)\.md)\)", fix, lines[nav_idx])
    if new_nav != lines[nav_idx]:
        lines[nav_idx] = new_nav
        changed.append((md.name, new_nav))

print(f"重写了 {len(changed)} 个导航行：")
for name, nav in changed:
    print(f"  {name}: {nav}")

if not DRY and changed:
    for md in sorted(DOCS.glob("[0-9][0-9]-*.md")):
        for name, nav in changed:
            if name == md.name:
                text = md.read_text(encoding="utf-8")
                lines = text.splitlines()
                for i, ln in enumerate(lines):
                    if ln.startswith("上一章："):
                        lines[i] = nav
                md.write_text("\n".join(lines) + "\n", encoding="utf-8", newline="")
    print("已落盘")
