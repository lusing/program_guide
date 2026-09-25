#!/usr/bin/env python3
"""check-docs.py —— Boost 教程文档与实测产物的对账（三项机器核查里的第 2 条）

    python3 tools/check-docs.py             扫全部 docs/*.md
    python3 tools/check-docs.py 02 29       只扫指定章号
    python3 tools/check-docs.py --diff      对账失败的块，并排打印"文档块 vs 实测产物"
    python3 tools/check-docs.py --win       把 WIN-ONLY 块也逐条列出来

做法（关键点：**按例子定位产物**，而不是在全部产物里找宽松匹配）：

  1. 扫 docs/*.md 时记住每个 ```text 块前面最近的一处
     "运行输出（`xxx.cpp`）" —— 该块声称的就是 xxx 的输出。
     于是候选产物**只有** build/shared/xxx.out 与 build/static/xxx.out。
     在 296 个产物里做宽松匹配会把"别的例子的输出"也算命中，
     那是假绿；按例子定位才抓得住。
  2. 比对是**顺序敏感的子序列**匹配（不是集合成员）。
     理由（本仓库踩过的"假绿"）：只判集合成员的话，
       (a) 把产物**别处**的一行抄进块里照样绿；
       (b) 块内**两行调换**照样绿。
     子序列要求"块的每一行都按同样的先后顺序出现在产物里，中间允许省略"。
  3. 分类：
       ALL       —— 在某条通道的产物里按序全部命中
       NO-PRODUCT—— 该例程本机没有产物（验证没过，如环境缺口的 parser/compat）
                    或块前面没写"运行输出（`x.cpp`）" ⇒ 单独计数，不算失败
       WIN-ONLY  —— 未命中的行**每一行**都带 Windows 专属特征（F:\\ 路径、
                    .exe/.dll、MSVC、RTX……）⇒ 跳过但计数（列出用 --win）
       NON-OUTPUT—— 目录树/命令行/决策表这类本来就不该在产物里的块 ⇒ 跳过但计数
       PARTIAL   —— 其余部分命中 ⇒ **必须人工看**（退出码 1）
       NONE      —— 一行都没命中且看不出是"非输出块" ⇒ 人工看（退出码 1）

退出码：有 PARTIAL 或 NONE 就返回 1；一个 docs 文件都没扫到也返回 1
（"扫了 0 个文件然后报通过"是最危险的假绿，必须报错）。
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / "docs"
BUILD = ROOT / "build"

# 明确的"非输出"围栏块特征：目录树 / 命令行 / 决策表 / 配置片段
NON_OUTPUT_MARKERS = ("├──", "└──", "│", "$ ", "pwsh ", "cd ", "boost/", "build/",
                      "b2 ", "cmake", "set ", "export ", "cl ", "/W4", "/EHsc",
                      "/std:", "examples/", "run-all.sh", "build.ps1", "？",
                      "要用", "要装", "→")

# 一行里出现这些，就说明它描述的是 Windows 侧的事实
WINDOWS_MARKERS = ("G:\\", "g:\\", "C:\\", "c:\\", "F:\\", "f:\\", ".exe", ".dll",
                   ".lib", ".pdb", "MSVC", "msvc", "cl.exe", "cl /", "win32",
                   "Win32", "WIN32", "_WIN32", "vcpkg", "link.exe", "lib.exe",
                   "dumpbin", "Visual Studio", "vcvars", "Windows", "windows.h",
                   "Microsoft Visual C++", "RTX", "NVIDIA", "CUDA")

FENCE = re.compile(r"^```(\w+)?\s*$")
# “运行输出（`version.cpp`）：” —— 也兼容半角括号；一行里可能有多个例程名
OUT_REF = re.compile(r"运行输出[（(][^）)]*")
OUT_NAME = re.compile(r"`([A-Za-z0-9_.\-]+\.cpp)`")
# 标注行里写了这些，就说明这块记的是 Windows 侧的输出（本机产物里本来就没有）
WIN_ANNOT = ("Windows 侧", "Windows侧", "windows 侧")


def product_paths(stem):
    """某例程在两条通道下的产物路径（可能不存在）。"""
    return [BUILD / ch / f"{stem}.out" for ch in ("shared", "static")]


def read_lines(p):
    try:
        return [ln.rstrip() for ln in p.read_text(encoding="utf-8",
                                                  errors="replace").splitlines()]
    except OSError:
        return None


def blocks_of(md_path):
    """返回 [(起始行号, [例子名...], 标注行原文, [内容行...]), ...]"""
    out = []
    lines = md_path.read_text(encoding="utf-8", errors="replace").splitlines()
    i = 0
    last_ref = None      # 最近一次"运行输出（`x.cpp`）"里的例程名（可能多个）
    last_line = ""       # 那一行原文，用来识别"Windows 侧"这类显式标注
    while i < len(lines):
        m = FENCE.match(lines[i])
        if m and m.group(1) == "text":
            start = i + 1
            j = start
            body = []
            while j < len(lines) and not lines[j].startswith("```"):
                body.append(lines[j])
                j += 1
            out.append((start + 1, last_ref, last_line, body))
            i = j + 1
        else:
            g = OUT_REF.search(lines[i])
            if g:
                last_ref = OUT_NAME.findall(lines[i])
                last_line = lines[i]
            i += 1
    return out


def fit_in_order(block, filelines):
    """块能否作为 filelines 的子序列（顺序敏感、允许省略）。

    返回 (ok, 失败时卡在块的第几行)。
    """
    p = 0
    for idx, b in enumerate(block):
        hit = -1
        while p < len(filelines):
            if filelines[p] == b:
                hit = p
                p += 1
                break
            p += 1
        if hit < 0:
            return False, idx
    return True, -1


def is_non_output(block):
    return any(b.lstrip().startswith(mk) for b in block for mk in NON_OUTPUT_MARKERS)


def all_windows(block):
    return all(any(mk in b for mk in WINDOWS_MARKERS) for b in block) if block else False


def dump_diff(md_name, lineno, ref, block, candidates):
    print(f"    ---- 文档 {md_name}:{lineno}（声称 {ref or '未标注'} 的输出）----")
    for b in block:
        print(f"      doc | {b}")
    for c in candidates:
        lns = read_lines(c)
        if lns is None:
            print(f"      {c.relative_to(BUILD)} | （无此产物）")
            continue
        print(f"      ---- {c.relative_to(BUILD)} ----")
        for l in lns:
            print(f"      out | {l}")
    print()


def main():
    argv = sys.argv[1:]
    show_win = "--win" in argv
    show_diff = "--diff" in argv
    select = [a for a in argv if not a.startswith("-")]

    if not (BUILD / "shared").is_dir() and not (BUILD / "static").is_dir():
        print("build/{shared,static} 都不存在，先跑 ./run-all.sh")
        return 1

    scanned_files = 0
    # 例程名未标注时的兜底：在全部产物里找（比按例子定位宽松，所以单独计数）
    def load_all_products():
        out = []
        for ch in ("shared", "static"):
            d = BUILD / ch
            if d.is_dir():
                for f in sorted(d.glob("*.out")):
                    lns = read_lines(f)
                    if lns:
                        out.append((f, lns))
        return out

    all_products = load_all_products()
    if not all_products:
        print("build/{shared,static}/*.out 一个非空的都没有，先跑 ./run-all.sh")
        return 1

    cnt = {"ALL": 0, "ALL~": 0, "PARTIAL": 0, "NONE": 0, "WIN": 0, "NONOUT": 0,
           "NOPROD": 0}

    for md in sorted(DOCS.glob("*.md")):
        num = md.name.split("-")[0]
        if select and num not in select:
            continue
        scanned_files += 1
        for lineno, refs, annot, raw in blocks_of(md):
            block = [b.rstrip() for b in raw if b.strip()]
            if not block:
                continue
            # 标注行里显式写了"Windows 侧" ⇒ 这块记的就是 Windows 输出，本机没有
            win_annot = any(a in annot for a in WIN_ANNOT)
            label = "/".join(refs) if refs else "未标注例程名"

            refs = refs or []
            # 候选产物：按标注里例程名的顺序拼起来（一个块可能覆盖多个例程）
            candidates = []
            for stem in [Path(r).stem for r in refs]:
                candidates += product_paths(stem)
            # 产物存在但为空 ⇒ 该例程本机没跑起来（环境缺口），等同无产物
            existing = [c for c in candidates if c.is_file() and read_lines(c)]

            if not existing:
                if refs:
                    cnt["NOPROD"] += 1
                    if show_diff:
                        print(f"[NO-PRODUCT] {md.name}:{lineno} 声称 {label} 的输出，"
                              f"但本机无（非空）产物——多半是验证没过的环境缺口例程")
                    continue
                # 显式标了 Windows 侧，就不用再去产物里找了
                if win_annot:
                    cnt["WIN"] += 1
                    if show_win:
                        print(f"[WIN-ONLY] {md.name}:{lineno} 标注写明 Windows 侧")
                    continue
                # 例程名没标注：兜底在全部产物里找（宽松，单独计数）
                hit_any = any(fit_in_order(block, lns)[0] for _, lns in all_products)
                if hit_any:
                    cnt["ALL~"] += 1
                    continue
                miss_all = [b for b in block
                            if not any(b in lns for _, lns in all_products)]
                if len(miss_all) == len(block):
                    if win_annot or all_windows(block):
                        cnt["WIN"] += 1
                        if show_win:
                            print(f"[WIN-ONLY] {md.name}:{lineno} 标注写明 Windows 侧")
                        continue
                    if is_non_output(block):
                        cnt["NONOUT"] += 1
                        continue
                cnt["NONE"] += 1
                print(f"[NONE] {md.name}:{lineno} 未标注例程名，且一行都没匹配上"
                      f"（首行：{block[0][:50]}）")
                if show_diff:
                    dump_diff(md.name, lineno, None, block, [])
                continue

            # 按"标注里的顺序拼起来"的两条通道序列
            seqs = []
            for ch in ("shared", "static"):
                seq = []
                for r in refs:
                    seq += read_lines(BUILD / ch / f"{Path(r).stem}.out") or []
                if seq:
                    seqs.append(seq)

            best = None
            fail_at = 0
            for seq in seqs:
                ok, fail_at = fit_in_order(block, seq)
                if ok:
                    best = seq
                    break
            if best is not None:
                cnt["ALL"] += 1
                continue

            miss = [b for b in block if not any(b in seq for seq in seqs)]
            if win_annot or all_windows(miss):
                cnt["WIN"] += 1
                if show_win:
                    why = "标注写明 Windows 侧" if win_annot else "未命中行均为 Windows 专属"
                    print(f"[WIN-ONLY] {md.name}:{lineno}（{label}）{why}"
                          f"（未命中 {len(miss)}/{len(block)} 行）")
                continue

            if len(miss) == len(block):
                if is_non_output(block):
                    cnt["NONOUT"] += 1
                    continue
                cnt["NONE"] += 1
                print(f"[NONE] {md.name}:{lineno} 一行都没匹配上（{label}）"
                      f"（首行：{block[0][:50]}）")
                if show_diff:
                    dump_diff(md.name, lineno, label, block, existing)
                continue

            cnt["PARTIAL"] += 1
            where = "顺序/位置不符" if not miss else f"{len(miss)} 行根本不在产物里"
            print(f"[PARTIAL] {md.name}:{lineno}（{label}）卡在块内第 {fail_at + 1} 行"
                  f"（{block[fail_at][:50]}）——{where}")
            if show_diff:
                dump_diff(md.name, lineno, label, block, existing)

    print()
    print(f"扫过 {scanned_files} 个 docs 文件")
    print(f"ALL {cnt['ALL']}（其中按例程锚定）   未锚定命中 {cnt['ALL~']}   "
          f"PARTIAL {cnt['PARTIAL']}   NONE {cnt['NONE']}   "
          f"WIN-ONLY 跳过 {cnt['WIN']}   非输出块跳过 {cnt['NONOUT']}   "
          f"无产物跳过 {cnt['NOPROD']}")

    if scanned_files == 0:
        print("一个 docs 文件都没扫到（章号写错了？）—— 这是假绿，直接判失败")
        return 1
    return 1 if (cnt["PARTIAL"] or cnt["NONE"]) else 0


if __name__ == "__main__":
    sys.exit(main())
