#!/usr/bin/env python3
"""check_docs.py —— algorithm 教程文档五关机器核查（build.ps1 -All 末尾自动调用）

    python tools/check_docs.py            全部五关（一致性口径：已交付的章节须成对齐整）
    python tools/check_docs.py 02 04      只查指定章号（关①仍全量对照）
    python tools/check_docs.py --expect 37 终验口径：要求 37 章全部交付

五关：
  ① 章节对齐：docs/NN-slug.md 与 examples/NN_slug/（目录）一一对应、
     编号从 01 起连续无洞；--expect N 时还要求 N 章全部在场
  ② 输出对账：每章 ```text 块必须是该章示例实测输出的【顺序敏感子序列】
     —— 产物由本脚本现场重跑 build/NN_slug.exe（msvc 通道产物）生成，
     对的永远是当前二进制，不食陈粮；且每章至少要有一个 ```text 输出块
  ③ 坑位清单：每章「## 坑位清单」下加粗标题条目 ≥3
  ④ 链接有效：docs/*.md 里的相对链接全部存在（../README.md 除外——
     分步写作容忍），且每章正文标注了 CLRS 出处（含 "CLRS" 字样）
  ⑤ README 导航：README.md 含全部已交付章节的链接

围栏纪律（docs 写作约定，本脚本只认 ```text 为输出块）：
  * ```clrs  CLRS 伪代码改写块 —— 不采集
  * ```cpp   C++23 讲解片段 —— 不采集
  * 裸 ```   ASCII 图/复杂度表等 —— 不采集
  * ```text  仅用于真实运行输出 —— 全量采集对账

反假绿纪律（沿用 boost/tools/check-docs.py 的教训）：
  * 子序列而非集合成员——块内两行调换、把别的示例输出抄进来，都判失败；
  * 一个 docs 文件都没扫到 = 最危险的假绿，直接退出码 1；
  * 明显非输出的块分类 NONOUT 跳过并计数，不冒充命中。

退出码：任一关失败返回 1。骨架阶段（docs 与 examples 均为空）返回 0。
"""
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / "docs"
EXAMPLES = ROOT / "examples"
BUILD = ROOT / "build"
REF = BUILD / "docs-ref"

TIMEOUT = 60  # 秒；与 build.ps1 的运行超时对齐

FENCE = re.compile(r"^```(\w+)?\s*$")

# 明显"非输出"的块特征：目录树 / 命令行（误用 ```text 时兜底，不算命中）
NON_OUTPUT_MARKERS = ("├──", "└──", "│ ", "$ ", "pwsh ", "python ", "cmake ",
                      "build.ps1", "run-all.sh", "cl ")


def refresh_products():
    """现场重跑全部示例（msvc 产物 build/NN_slug.exe），产出 docs-ref/NN.out。
    返回 {NN: [产物行...]}。"""
    REF.mkdir(parents=True, exist_ok=True)
    products = {}
    if not BUILD.is_dir():
        return products
    for exe in sorted(BUILD.glob("*.exe")):
        stem = exe.stem  # NN_slug
        out_path = REF / f"{stem}.out"
        try:
            r = subprocess.run([str(exe)], cwd=str(BUILD),
                               capture_output=True, timeout=TIMEOUT)
            out_path.write_bytes(r.stdout)
        except subprocess.TimeoutExpired:
            print(f"[env] {stem} 运行超时（{TIMEOUT}s），产物缺")
            continue
        lines = [ln.rstrip() for ln in
                 r.stdout.decode("utf-8", errors="replace").splitlines()]
        products[stem.split("_")[0]] = lines
    return products


def blocks_of(md_path):
    """[(起始行号, [非空内容行...]), ...] —— 只收 ```text 块。"""
    out = []
    lines = md_path.read_text(encoding="utf-8", errors="replace").splitlines()
    i = 0
    while i < len(lines):
        m = FENCE.match(lines[i])
        if m and m.group(1) == "text":
            j = i + 1
            body = []
            while j < len(lines) and not lines[j].startswith("```"):
                body.append(lines[j])
                j += 1
            out.append((i + 1, [b.rstrip() for b in body if b.strip()]))
            i = j + 1
        else:
            i += 1
    return out


def fit_in_order(block, seq):
    """顺序敏感子序列匹配：块每行按序出现在 seq 里，中间允许省略。"""
    p = 0
    for b in block:
        while p < len(seq):
            if seq[p] == b:
                break
            p += 1
        if p >= len(seq):
            return False
        p += 1
    return True


def is_non_output(block):
    return any(b.lstrip().startswith(mk) for b in block for mk in NON_OUTPUT_MARKERS)


def pitfalls_of(md_path):
    """「## 坑位清单」小节下的加粗标题条数（下一个 ## 之前）。"""
    lines = md_path.read_text(encoding="utf-8", errors="replace").splitlines()
    n, inside = 0, False
    for ln in lines:
        if ln.startswith("## "):
            inside = "坑位清单" in ln
        elif inside and re.match(r"\s*[-*]\s+\*\*", ln):
            n += 1
    return n


def main():
    # GBK 控制台下 Python 默认按控制台编码打印中文——钉死 UTF-8 防乱码
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    except AttributeError:
        pass
    argv = []
    expect = None
    args = sys.argv[1:]
    i = 0
    while i < len(args):
        if args[i] == "--expect" and i + 1 < len(args):
            expect = int(args[i + 1])
            i += 2
        elif not args[i].startswith("-"):
            argv.append(args[i])
            i += 1
        else:
            i += 1
    fail = []

    doc_nums = sorted({p.name.split("-")[0] for p in DOCS.glob("[0-9][0-9]-*.md")}) \
        if DOCS.is_dir() else []
    ex_nums = sorted({p.name.split("_")[0] for p in EXAMPLES.glob("[0-9][0-9]_*")}) \
        if EXAMPLES.is_dir() else []

    if not doc_nums and not ex_nums:
        print("[骨架] docs/ 与 examples/ 均为空 —— 五关空转通过（分批交付阶段）")
        return 0

    # ---------- 关①：章节文件与示例一一对应、编号连续 ----------
    only_docs = [n for n in doc_nums if n not in ex_nums]
    only_examples = [n for n in ex_nums if n not in doc_nums]
    if only_docs:
        fail.append(f"①有文档无示例：{only_docs}")
    if only_examples:
        fail.append(f"①有示例无文档：{only_examples}")
    contiguous = doc_nums == [f"{i:02d}" for i in range(1, len(doc_nums) + 1)]
    if not contiguous:
        fail.append(f"①章号不连续：{doc_nums}")
    if expect is not None:
        want = [f"{i:02d}" for i in range(1, expect + 1)]
        missing = [n for n in want if n not in doc_nums]
        if missing:
            fail.append(f"①终验缺章：{missing}")
    print(f"[①] 文档 {len(doc_nums)} 章 / 示例 {len(ex_nums)} 章"
          f"{' —— 对齐' if not only_docs and not only_examples and contiguous else ' —— 不齐！'}")

    products = refresh_products()

    # ---------- 关②③④：逐章 ----------
    cnt = {"ALL": 0, "NONOUT": 0, "PARTIAL": 0, "NONE": 0, "NOPROD": 0}
    link_re = re.compile(r"\]\(([^)#]+?\.md)\)")
    for md in sorted(DOCS.glob("[0-9][0-9]-*.md")):
        num = md.name.split("-")[0]
        if argv and num not in argv:
            continue
        text = md.read_text(encoding="utf-8", errors="replace")

        text_blocks = blocks_of(md)
        if not text_blocks:
            print(f"[②] {md.name} 一个 ```text 输出块都没有")
            fail.append(f"②{md.name} 无输出块")
        seq = products.get(num, [])
        for lineno, block in text_blocks:
            if not block:
                continue
            if not seq:
                cnt["NOPROD"] += 1
                print(f"[②] {md.name}:{lineno} 章号 {num} 无实测产物")
                fail.append(f"②{md.name}:{lineno} 无产物")
                continue
            if fit_in_order(block, seq):
                cnt["ALL"] += 1
            elif is_non_output(block):
                cnt["NONOUT"] += 1
            else:
                kind = "PARTIAL" if any(b in seq for b in block) else "NONE"
                cnt[kind] += 1
                print(f"[②] {kind} {md.name}:{lineno} 首行：{block[0][:44]}")
                fail.append(f"②{md.name}:{lineno} 输出块对不上（{kind}）")

        n = pitfalls_of(md)
        if n < 3:
            print(f"[③] {md.name} 坑位清单只有 {n} 条（须 ≥3）")
            fail.append(f"③{md.name} 坑位 {n} 条")

        if "CLRS" not in text:
            print(f"[④] {md.name} 未标注 CLRS 出处")
            fail.append(f"④{md.name} 缺 CLRS 出处")

        for target in link_re.findall(text):
            if target.startswith("../README"):
                continue  # 终验前根 README 可能还没收录，容忍（终验另查）
            if not (md.parent / target).resolve().exists():
                print(f"[④] {md.name} 死链：{target}")
                fail.append(f"④{md.name} 死链 {target}")

    print(f"[②] ALL {cnt['ALL']}   NONOUT {cnt['NONOUT']}   "
          f"PARTIAL {cnt['PARTIAL']}   NONE {cnt['NONE']}   NOPROD {cnt['NOPROD']}")

    # ---------- 关⑤：README 导航含全部已交付章节 ----------
    readme = ROOT / "README.md"
    if readme.is_file():
        txt = readme.read_text(encoding="utf-8", errors="replace")
        docs_names = {p.name for p in DOCS.glob("[0-9][0-9]-*.md")}
        absent = sorted(n for n in docs_names if n not in txt)
        if absent:
            print(f"[⑤] README 缺导航：{absent}")
            fail.append(f"⑤README 缺 {len(absent)} 章导航")
        else:
            print(f"[⑤] README 导航含全部 {len(docs_names)} 章")
    else:
        print("[⑤] README.md 尚不存在（分步写作容忍；终验必须补上）")

    if fail:
        print(f"\n==== 五关核查：{len(fail)} 处不合格 ====")
        for f in fail[:20]:
            print("  -", f)
        return 1
    print("\n==== 五关核查：全部通过 ====")
    return 0


if __name__ == "__main__":
    sys.exit(main())
