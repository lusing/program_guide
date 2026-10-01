#!/usr/bin/env python3
"""check_docs.py —— rustgui 教程文档五关机器核查（build.ps1 -All 末尾自动调用）

    python tools/check_docs.py            全部五关
    python tools/check_docs.py 02 23      只查指定章号（关①仍全量对照）

五关：
  ① 章节对齐：docs/NN-slug.md 与 examples/NN_*/ 一一对应（01/31 无示例白名单（37 为 TUI 终章有示例））
  ② 输出对账：每章 ```text 块必须是该章示例实测输出的【顺序敏感子序列】
     —— 产物由本脚本现场重跑 target/debug/<pkg>.exe --selftest 生成
     （写 build/docs-ref/NN_name.out），对的永远是当前二进制，不食陈粮。
  ③ 坑位清单：每章「## 坑位清单」下条目 ≥3
  ④ 链接有效：docs/*.md 里的相对链接全部存在（../README.md 除外）
  ⑤ README 导航：README.md 含全部 37 章的链接

反假绿纪律（沿用 cppgui/tools/check_docs.py）：
  * 子序列而非集合成员——块内两行调换、抄别的示例输出，都判失败；
  * 一个 docs 文件都没扫到 = 最危险的假绿，退出码 1；
  * 明显非输出的块（命令行/目录树）分类 NONOUT 跳过并计数，不冒充命中。

退出码：任一关失败返回 1。
"""
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / "docs"
EXAMPLES = ROOT / "examples"
TARGET_DEBUG = ROOT / "target" / "debug"
REF = ROOT / "build" / "docs-ref"

TIMEOUT = 60  # 秒；与 build.ps1 的 selftest 超时对齐

FENCE = re.compile(r"^```(\w+)?\s*$")

# 明显"非输出"的块特征：命令行 / 目录树 / 决策表
NON_OUTPUT_MARKERS = ("├──", "└──", "│ ", "$ ", "pwsh ", "cd rustgui", "cargo ",
                      "Measure-Command", "Get-Item", "--target", "examples/",
                      "docs/", "build.ps1", "run-all.sh")

EXPECTED_CHAPTERS = 37
# 无独立示例的章（全景观 / 横评）
NO_EXAMPLE_CHAPTERS = {"01", "31"}

# GTK4（24–30 章）：selftest 二进制需要 GTK 的 DLL 在 PATH——与 build.ps1
# 同款自动探测守卫（直接跑本脚本时不经 build.ps1，得自己注入）。
for _g in ("G:\\gtk", "C:\\gtk"):
    if (_g + "\\lib\\pkgconfig\\gtk4.pc") and __import__("os").path.exists(
        _g + "\\lib\\pkgconfig\\gtk4.pc"
    ):
        _p = __import__("os").environ
        _p["PATH"] = _g + "\\bin;" + _p.get("PATH", "")
        _p["PKG_CONFIG_PATH"] = _g + "\\lib\\pkgconfig;" + _p.get("PKG_CONFIG_PATH", "")
        break


def example_dirs():
    """{章号: (示例目录名, package 名)}——package 名 = 目录名去掉 NN_ 前缀。"""
    out = {}
    for d in sorted(EXAMPLES.iterdir()) if EXAMPLES.is_dir() else []:
        m = re.match(r"^(\d{2})_(.+)$", d.name)
        if m and d.is_dir():
            out[m.group(1)] = (d.name, m.group(2))
    return out


def refresh_products(exs):
    """现场重跑全部示例的 --selftest，产出 .out。返回 {NN: [产物行...]}。"""
    if not TARGET_DEBUG.is_dir():
        print("[env] target/debug 不存在，先跑 build.ps1")
        return None
    REF.mkdir(parents=True, exist_ok=True)
    products = {}
    for nn, (dirname, pkg) in sorted(exs.items()):
        exe = TARGET_DEBUG / (pkg + (".exe" if sys.platform == "win32" else ""))
        if not exe.is_file():
            print(f"[env] {nn} 缺二进制：{exe}")
            continue
        out_path = REF / f"{dirname}.out"
        try:
            r = subprocess.run([str(exe), "--selftest"], cwd=str(ROOT),
                               capture_output=True, timeout=TIMEOUT)
            out_path.write_bytes(r.stdout)
        except subprocess.TimeoutExpired:
            print(f"[env] {dirname} --selftest 超时（{TIMEOUT}s），产物缺")
            continue
        lines = [ln.rstrip() for ln in
                 r.stdout.decode("utf-8", errors="replace").splitlines()]
        products[nn] = lines
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
    """「## 坑位清单」小节下的列表条数（下一个 ## 之前）。"""
    lines = md_path.read_text(encoding="utf-8", errors="replace").splitlines()
    n, inside = 0, False
    for ln in lines:
        if ln.startswith("## "):
            inside = "坑位清单" in ln
        elif inside and re.match(r"\s*[-*]\s+\*\*", ln):
            n += 1
    return n


def main():
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    except AttributeError:
        pass
    argv = [a for a in sys.argv[1:] if not a.startswith("-")]
    fail = []

    if not DOCS.is_dir() or not list(DOCS.glob("*.md")):
        print("[①] docs/ 下一个 .md 都没有")
        return 1

    exs = example_dirs()
    products = refresh_products(exs)
    if products is None:
        return 1

    # ---------- 关①：章节文件与示例一一对应 ----------
    doc_nums = sorted({p.name.split("-")[0] for p in DOCS.glob("[0-9][0-9]-*.md")})
    expect = [f"{i:02d}" for i in range(1, EXPECTED_CHAPTERS + 1)]
    missing_docs = [n for n in expect if n not in doc_nums]
    missing_examples = [n for n in expect
                        if n not in exs and n not in NO_EXAMPLE_CHAPTERS]
    extra_examples = [n for n in exs if n not in expect]
    if missing_docs:
        fail.append(f"①缺章节文件：{missing_docs}")
    if missing_examples:
        fail.append(f"①缺示例目录：{missing_examples}")
    if extra_examples:
        fail.append(f"①多出示例目录：{extra_examples}")
    print(f"[①] 示例 {len(exs)} 个 / 文档 {len(doc_nums)} 章"
          f"{' —— 对齐' if not missing_docs and not missing_examples else ' —— 不齐！'}")

    # ---------- 关②③④：逐章 ----------
    cnt = {"ALL": 0, "NONOUT": 0, "PARTIAL": 0, "NONE": 0, "NOPROD": 0}
    link_re = re.compile(r"\]\(([^)#]+?\.md)\)")
    for md in sorted(DOCS.glob("*.md")):
        num = md.name.split("-")[0]
        if argv and num not in argv:
            continue
        seq = products.get(num, [])

        for lineno, block in blocks_of(md):
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

        for target in link_re.findall(md.read_text(encoding="utf-8",
                                                   errors="replace")):
            if target.startswith("../README"):
                continue  # 终验前 README 可能还没写，容忍（关⑤兜底）
            if not (md.parent / target).resolve().exists():
                print(f"[④] {md.name} 死链：{target}")
                fail.append(f"④{md.name} 死链 {target}")

    print(f"[②] ALL {cnt['ALL']}   NONOUT {cnt['NONOUT']}   "
          f"PARTIAL {cnt['PARTIAL']}   NONE {cnt['NONE']}   NOPROD {cnt['NOPROD']}")

    # ---------- 关⑤：README 导航含全部 37 章 ----------
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


