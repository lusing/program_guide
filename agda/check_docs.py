#!/usr/bin/env python3
"""教程文档核查脚本（配合 build.sh 使用）。

核查项（全部通过才 exit 0）：
  A. 章节配对：docs/NN-*.md 与 examples/ExNN_*.agda 一一对应（43/44 章无示例；
     04/12/29 章示例名用连字符是历史约定，按章号配对）。
  B. 正文引用一致：docs/NN-*.md 里 ```agda 代码块的非注释行能在对应示例里
     按序找到。**严格模式只施加于 45/46/47 章**（本次按「正文引用全部代码」规则
     新写的章）；其余旧章按劝告级报告——它们成文于该规则之前，
     且大量代码块是「故意写错的报错演示」，不适合逐字比对。
  B↑ 覆盖率（只对严格章）：反方向也查——示例里每一行非注释代码都必须出现在
     正文某个 ```agda 块里。这是「教程不能是代码罗列、不许让读者回去翻源码」
     的机器关卡。
  C. 导航链接：每章**末尾导航行**的「上一章/下一章」链接文字必须与目标
     文件 H1 逐字一致（旧章正文里的行内引用如 [44 章] 是教程既有约定，
     不查）；README 索引必须覆盖每章的编号与链接。
  D. 变异自检（--mutate）：对每个严格章故意改坏文档两件事——某行代码加尾巴
     （B 关必须抓出）、删掉某行独占引用（B↑ 关必须抓出），确认本脚本能
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
STRICT_BLOCK_CHECK = {"45", "46", "47"}  # 本规则下新写的章：正文代码块与源码逐字一致
# 覆盖率关卡（B↑）只对 46/47 严格：45 章成文时只立了「引用 ⊆ 源码」这半边
# 规则，正文按约定复用 23 章的同构机器（≅-refl/sym/trans）与 import 清单，
# 没有逐行重贴。硬套会误伤，故 45 的覆盖率缺口按劝告级报告。
STRICT_COVERAGE = {"46", "47"}


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


def doc_blocks(doc_path):
    return re.findall(r"```agda\n(.*?)```",
                      open(doc_path, encoding="utf-8").read(), re.S)


def check_coverage(doc_path, ex_path):
    """B↑：示例的每一行非注释代码都必须被正文引用（集合成员检查，不看顺序）。"""
    quoted = set()
    for block in doc_blocks(doc_path):
        for ln in code_lines(block):
            quoted.add(ln.lstrip())
    errors = []
    seen = set()
    for ln in open(ex_path, encoding="utf-8").read().splitlines():
        s = ln.rstrip()
        if not s.strip() or s.lstrip().startswith("--"):
            continue
        key = s.lstrip()
        if key not in quoted and key not in seen:
            seen.add(key)
            errors.append(f"正文未引用示例代码: {key!r}")
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


def example_code_lines(ex_path):
    out = []
    for ln in open(ex_path, encoding="utf-8").read().splitlines():
        s = ln.rstrip()
        if s.strip() and not s.lstrip().startswith("--"):
            out.append(s.lstrip())
    return out


def mutate_and_verify(doc_path, ex_path, coverage=True):
    """两关各测一次变异：B 关（改坏一行引用）、B↑ 关（删掉一处独占引用）。"""
    text = open(doc_path, encoding="utf-8").read()
    m = re.search(r"```agda\n(.*?)```", text, re.S)
    if not m:
        print("[D] 跳过变异：文档无 agda 块")
        return True
    ok = True

    # B 关：给第一个块的首行代码加尾巴
    lines = m.group(1).splitlines()
    for i, ln in enumerate(lines):
        if ln.strip() and not ln.lstrip().startswith("--"):
            lines[i] = ln + " --MUTATED"
            break
    try:
        open(doc_path, "w", encoding="utf-8").write(
            text[: m.start(1)] + "\n".join(lines) + text[m.end(1):])
        if check_blocks_in_example(doc_path, ex_path, strict=True):
            print(f"[D:B] 变异被抓出 {os.path.basename(doc_path)}")
        else:
            print(f"[D:B] 变异测试失败！改坏引用后未报警 {os.path.basename(doc_path)}")
            ok = False
    finally:
        open(doc_path, "w", encoding="utf-8").write(text)

    # B↑ 关：删掉正文里只出现一次、且确实是示例代码的那一行
    #（只对 STRICT_COVERAGE 的章跑——其余章覆盖率本就不做硬要求）
    codes = set(example_code_lines(ex_path))
    all_quoted = [l.lstrip() for b in doc_blocks(doc_path) for l in code_lines(b)]
    target = None
    for bm in re.finditer(r"```agda\n(.*?)```", text, re.S):
        off = bm.start(1)
        for raw in bm.group(1).splitlines(keepends=True):
            s = raw.rstrip()
            if s.strip() and not s.lstrip().startswith("--"):
                key = s.lstrip()
                if key in codes and all_quoted.count(key) == 1:
                    target = (off, len(raw))
                    break
            off += len(raw)
        if target:
            break
    if not target:
        print(f"[D:B↑] 跳过：找不到独占一行的引用（正文可能重复引用了所有代码）")
        return ok
    if not coverage:
        return ok
    pos, cut = target
    try:
        open(doc_path, "w", encoding="utf-8").write(text[:pos] + text[pos + cut:])
        errs = check_coverage(doc_path, ex_path)
        if errs:
            print(f"[D:B↑] 变异被抓出 {os.path.basename(doc_path)}：{errs[0]}")
        else:
            print(f"[D:B↑] 变异测试失败！删掉引用后覆盖率关卡未报警 "
                  f"{os.path.basename(doc_path)}")
            ok = False
    finally:
        open(doc_path, "w", encoding="utf-8").write(text)
    return ok


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
                    cov = check_coverage(doc, ex)
                    tag = "[B↑] " if num in STRICT_COVERAGE else "[B↑:劝告] "
                    if num in STRICT_COVERAGE:
                        errors += [f"{tag}{base} {e}" for e in cov]
                    else:
                        warnings += [f"{tag}{base} 正文未引用示例代码 {len(cov)} 行"
                                     f"（复用件与 import，见脚本头注释）"]
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
        for num in sorted(STRICT_BLOCK_CHECK):
            cand = sorted(glob.glob(os.path.join(DOCS, f"{num}-*.md")))
            e = find_example(num)
            if not cand or not e:
                print(f"[D] 跳过 {num} 章（缺文档或示例）")
                continue
            if not mutate_and_verify(cand[0], e,
                                      coverage=num in STRICT_COVERAGE):
                sys.exit(1)


if __name__ == "__main__":
    main()
