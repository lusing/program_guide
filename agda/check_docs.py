#!/usr/bin/env python3
"""教程文档核查脚本（配合 build.sh 使用）。

核查项（全部通过才 exit 0）：
  A. 章节配对：docs/NN-*.md 与 examples/ExNN_*.agda 一一对应（43/44 章无示例；
     04/12/29 章示例名用连字符是历史约定，按章号配对）。
  B. 正文引用一致：docs/NN-*.md 里 ```agda 代码块的非注释行能在对应示例里
     按序找到。**严格模式只施加于 45 章**（本次按「正文引用全部代码」规则
     新写的收官章）；43 章之前的旧章按劝告级报告——它们成文于该规则之前，
     且大量代码块是「故意写错的报错演示」，不适合逐字比对。
  C. 导航链接：每章**末尾导航行**的「上一章/下一章」链接文字必须与目标
     文件 H1 逐字一致（旧章正文里的行内引用如 [44 章] 是教程既有约定，
     不查）；README 索引必须覆盖每章的编号与链接。
  D. 变异自检（--mutate）：故意把 45 章某个文档代码块改坏，确认本脚本能
     抓出（防止核查器本身失效）。

用法：
  python3 check_docs.py            # 全量核查
  python3 check_docs.py --mutate   # 全量核查 + 变异测试（跑完自动恢复）
"""

import glob
import os
import re
import sys

ROOT = os.path.dirname(os.path.abspath(__file__))
DOCS = os.path.join(ROOT, "docs")
EXAMPLES = os.path.join(ROOT, "examples")
README = os.path.join(ROOT, "README.md")

NO_EXAMPLE = {"43", "44"}
STRICT_BLOCK_CHECK = {"45"}  # 本规则下新写的章：正文代码块与源码逐字一致


def code_lines(block: str):
    out = []
    for ln in block.splitlines():
        s = ln.rstrip()
        if not s.strip():
            continue
        if s.lstrip().startswith("--"):
            continue
        out.append(s)
    return out


def find_example(num: str):
    cands = sorted(glob.glob(os.path.join(EXAMPLES, f"Ex{num}_*.agda"))
                   + glob.glob(os.path.join(EXAMPLES, f"Ex{num}-*.agda")))
    return cands[0] if cands else None


def check_blocks_in_example(doc_path, ex_path, strict=True):
    text = open(doc_path, encoding="utf-8").read()
    src_stripped = [l.rstrip() for l in open(ex_path, encoding="utf-8").read().splitlines()]
    blocks = re.findall(r"```agda\n(.*?)```", text, re.S)
    errors = []
    for bi, block in enumerate(blocks):
        want = code_lines(block)
        if not want:
            continue
        pos = 0
        for w in want:
            w_stripped = w.lstrip()
            found = False
            while pos < len(src_stripped):
                if src_stripped[pos].lstrip() == w_stripped:
                    found = True
                    pos += 1
                    break
                pos += 1
            if not found:
                errors.append(f"块#{bi} 行不存在于示例（或顺序不一致）: {w!r}")
                break
    return errors


def check_navigation(doc_path):
    """只查末尾导航行（上一章/下一章），链接文字须与目标 H1 逐字一致。"""
    text = open(doc_path, encoding="utf-8").read()
    errors = []
    h1 = re.search(r"^# (.+)$", text, re.M)
    if not h1:
        return ["缺 H1 标题"], None
    nav_lines = [l for l in text.splitlines() if re.search(r"上一章|下一章", l)]
    for line in nav_lines:
        for label, target in re.findall(r"\[([^\]]+)\]\((\d{2}-[^)]+)\)", line):
            tgt_path = os.path.join(DOCS, target)
            if not os.path.exists(tgt_path):
                errors.append(f"导航死链: {target}")
                continue
            tgt_h1 = re.search(r"^# (.+)$", open(tgt_path, encoding="utf-8").read(), re.M)
            if tgt_h1 and tgt_h1.group(1) != label:
                errors.append(
                    f"导航链接文字 {label!r} ≠ 目标 H1 {tgt_h1.group(1)!r} ({target})"
                )
    return errors, h1.group(1)


def check_readme(h1s):
    errors = []
    readme = open(README, encoding="utf-8").read()
    for num, h1 in sorted(h1s.items()):
        if not re.search(rf"docs/{num}-[^\)]+\.md", readme):
            errors.append(f"README 索引缺章节链接：{num} · {h1}")
    return errors


def mutate_and_verify(doc_path, ex_path):
    text = open(doc_path, encoding="utf-8").read()
    m = re.search(r"```agda\n(.*?)```", text, re.S)
    if not m:
        print("[D] 跳过变异：文档无 agda 块")
        return True
    block = m.group(1)
    lines = block.splitlines()
    for i, ln in enumerate(lines):
        if ln.strip() and not ln.lstrip().startswith("--"):
            lines[i] = ln + " --MUTATED"
            break
    mutated = text[: m.start(1)] + "\n".join(lines) + text[m.end(1):]
    try:
        open(doc_path, "w", encoding="utf-8").write(mutated)
        errs = check_blocks_in_example(doc_path, ex_path, strict=True)
        if errs:
            print(f"[D] 变异测试通过（核查器抓出了被改坏的块）：{os.path.basename(doc_path)}")
            return True
        print(f"[D] 变异测试失败！改坏文档后核查器未报警：{os.path.basename(doc_path)}")
        return False
    finally:
        open(doc_path, "w", encoding="utf-8").write(text)


def main():
    mutate = "--mutate" in sys.argv
    errors = []
    warnings = []
    h1s = {}
    docs = sorted(glob.glob(os.path.join(DOCS, "*.md")))
    used_examples = set()

    for doc in docs:
        base = os.path.basename(doc)
        num = base.split("-")[0]
        ex = None if num in NO_EXAMPLE else find_example(num)
        if num not in NO_EXAMPLE:
            if not ex:
                errors.append(f"[A] {base} 找不到配套示例 examples/Ex{num}_*.agda")
            else:
                used_examples.add(os.path.basename(ex))
                errs = check_blocks_in_example(doc, ex, strict=num in STRICT_BLOCK_CHECK)
                if num in STRICT_BLOCK_CHECK:
                    errors += [f"[B] {base} {e}" for e in errs]
                else:
                    warnings += [f"[B:劝告] {base} {e}" for e in errs]
        nav_errs, h1 = check_navigation(doc)
        errors += [f"[C] {base} {e}" for e in nav_errs]
        if h1:
            h1s[num] = h1

    for f in sorted(glob.glob(os.path.join(EXAMPLES, "Ex*.agda"))):
        if os.path.basename(f) not in used_examples:
            errors.append(f"[A] 示例无对应文档：{os.path.basename(f)}")

    errors += [f"[C] README {e}" for e in check_readme(h1s)]

    for w in warnings:
        print(w)
    for e in errors:
        print(e)
    print(f"\n{len(docs)} 章：{len(errors)} 项未过，{len(warnings)} 项劝告（旧章正文引用，非失败）")
    if errors:
        sys.exit(1)

    if mutate:
        t = os.path.join(DOCS, "45-memoize.md")
        e = find_example("45")
        if os.path.exists(t) and e and not mutate_and_verify(t, e):
            sys.exit(1)


if __name__ == "__main__":
    main()
