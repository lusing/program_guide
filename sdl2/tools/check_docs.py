#!/usr/bin/env python3
"""SDL2 教程文档机器核查（五关，按章 docs/ 布局）。

用法：
    python3 tools/check_docs.py            先跑 ./run-all.sh 生成 build/ 产物
    python3 tools/check_docs.py 02 08      只查指定章（关①仍全量对照）

五关：
  ① 章节对齐：docs/NN-slug.md <-> examples/NN_*.cpp 一一对应
     （NO_EXAMPLE 里声明的章号允许没有示例；示例的分节标记编号须与文件名一致）
  ② 输出对账：每章 ```text 块必须是该章实测产物的【顺序敏感子序列】
     —— 逐行在归一化后的产物大串里按序 find，抄错顺序、抄别的示例都会判失败。
     章号 01–10 只比对自己那份示例的产物；11/12/README/CHEATSheet 比全量产物。
     块前一行含「非示例运行输出 / 非运行输出 / 非 run-all.sh 产物」显式标注则跳过。
  ③ 坑位自洽：每章有「## 坑位清单」且条目 >= 2；编号全局唯一、1..N 连续；
     与 CHEATSheet 表格行号集合一致，且 CHEATSheet 每行的「章」链接指向的
     正是收录该条的章；README 的「N 条实测坑位」== N。
  ④ 导航有效：每章末行含「上一章」与「返回」；章末导航的链接文字 == 目标章 H1
     （正文简称只校验标号对得上）；docs/README/CHEATSheet 里所有相对 .md 与
     ../examples/*.cpp 链接存在；README 分章导航覆盖全部章节。
  ⑤ 正文自足：examples/NN_*.cpp 的每一行代码（注释行除外）都必须出现在该章的
     ```cpp 块里——教程不许把讲解责任推给源码，读者不必打开 examples/。

退出码：任一关失败返回 1；build/ 产物不全直接返回 1（不把「只跑了单个示例」
误判成文档写错）。
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BUILD = ROOT / "build"
DOCS = ROOT / "docs"
EXAMPLES = ROOT / "examples"
README = ROOT / "README.md"
CHEAT = ROOT / "CHEATSheet.md"

# 工程侧两章没有对应示例（内容来自全部示例的 build 产物）
NO_EXAMPLE = {"11", "12"}
# 某章额外可用的证据文件（glob，相对 build/）
CHAPTER_EXTRA_GLOBS = {"02": ["dummy-driver-02.out"]}

SKIP_MARKERS = ("非示例运行输出", "非运行输出", "非 run-all.sh 产物")
# 明显不是运行输出的块：目录树、shell 命令回显、构建工具命令行。
# 链接参数串（-L/opt/local、-Wl,-framework）不算在内——run-all.sh 会把
# sdl2-config 的实际输出留档进 build/toolchain.txt，那是真产物，该验。
NON_OUTPUT_MARKERS = ("├──", "└──", "│ ", "$ ", "clang++ ", "cmake ", "sdl2-config ",
                      "-I/opt/local")

errors: list[str] = []


def fail(msg: str) -> None:
    errors.append(msg)


def norm(s: str) -> str:
    return re.sub(r"\s+", " ", s).strip()


def read(p: Path) -> str:
    return p.read_text(encoding="utf-8", errors="replace")


# ------------------------------------------------------------
# 产物：按「示例各自 shared/static 两通道的 run1+run2+err + 证据文件」拼 blob
# ------------------------------------------------------------
def example_bases() -> dict[str, str]:
    return {p.name.split("_")[0]: p.stem for p in EXAMPLES.glob("[0-9][0-9]_*.cpp")}


def is_texty(p: Path) -> bool:
    """跳过可执行文件本体（无扩展名）与含 NUL 的产物。"""
    try:
        head = p.read_bytes()[:512]
    except OSError:
        return False
    return p.suffix != "" and b"\x00" not in head


def chapter_parts(nn: str, bases: dict[str, str]) -> list[tuple[Path, str]]:
    """章号 NN 的证据文件。01–10 只有自家示例；其余按「示例升序 + build/ 顶层」全量。

    全量时先按章号升序逐个示例拼，再补 build/ 顶层文件——文档里的块是按
    「01、02、02 dummy、04、08、09」这样顺着读的，产物顺序必须跟着这个读法，
    否则顺序敏感子序列会因为 rglob 的字典序（dummy-driver-02.out 排在 shared/
  前面）而假失败。
    """
    if nn in bases:
        base = bases[nn]
        parts = [(f, read(f))
                 for chan in ("shared", "static")
                 for suffix in (".run1", ".run2", ".sec1", ".compile.err", ".run.err")
                 for f in [BUILD / chan / f"{base}{suffix}"]
                 if f.is_file() and is_texty(f)]
        for glob in CHAPTER_EXTRA_GLOBS.get(nn, []):
            parts += [(f, read(f)) for f in sorted(BUILD.glob(glob)) if is_texty(f)]
        return parts
    parts: list[tuple[Path, str]] = []
    for k in sorted(bases):
        parts += chapter_parts(k, bases)
    seen = {f for f, _ in parts}
    for f in sorted(BUILD.glob("*")):
        if f.is_file() and f not in seen and is_texty(f):
            parts.append((f, read(f)))
    return parts


def chapter_blob(nn: str, bases: dict[str, str]) -> str:
    return "\n".join(text for _, text in chapter_parts(nn, bases))


def chapter_files() -> list[Path]:
    return sorted(DOCS.glob("[0-9][0-9]-*.md"))


# ------------------------------------------------------------
# 关①：章节文件 <-> 示例文件
# ------------------------------------------------------------
def check_alignment() -> None:
    if not DOCS.is_dir():
        fail("① docs/ 目录不存在")
        return
    docs = chapter_files()
    if not docs:
        fail("① docs/ 下一个章节文件都没有")
        return
    doc_nums = sorted({p.name[:2] for p in docs})
    bases = example_bases()
    for nn in sorted(bases):
        if nn not in doc_nums:
            fail(f"① 示例 {nn}（{bases[nn]}.cpp）没有对应章节文件")
    for nn in doc_nums:
        if nn not in bases and nn not in NO_EXAMPLE:
            fail(f"① 章节 {nn} 无对应示例（如是工程侧章，请登记进 NO_EXAMPLE）")
    dup = {nn for nn in doc_nums if len([p for p in docs if p.name[:2] == nn]) > 1}
    if dup:
        fail(f"① 章号重复：{sorted(dup)}")
    for p in sorted(EXAMPLES.glob("[0-9][0-9]_*.cpp")):
        num = p.name[:2]
        src = read(p)
        if f"==== {num} 开始 ====" not in src or f"==== {num} 结束 ====" not in src:
            fail(f"① {p.name} 缺少与文件名一致的分节标记（应为 ==== {num} 开始/结束 ====）")
    bad = [e for e in errors if e.startswith("①")]
    print(f"[①] 章节 {len(docs)} 个 / 示例 {len(bases)} 个 —— {'对齐' if not bad else '不齐'}")


# ------------------------------------------------------------
# 关②：text 块 vs 产物（顺序敏感子序列，按行归一化）
# ------------------------------------------------------------
def text_blocks(md: Path) -> list[tuple[int, list[str]]]:
    lines = read(md).splitlines()
    out: list[tuple[int, list[str]]] = []
    i = 0
    while i < len(lines):
        if lines[i].startswith("```text"):
            prev = lines[i - 1].strip() if i > 0 else ""
            body: list[str] = []
            j = i + 1
            while j < len(lines) and not lines[j].startswith("```"):
                body.append(lines[j])
                j += 1
            if not any(mk in prev for mk in SKIP_MARKERS):
                out.append((i + 1, [b for b in body if b.strip()]))
            i = j + 1
        else:
            i += 1
    return out


def match_block(block: list[str], blob: str) -> str | None:
    """返回 None 表示命中；否则返回第一个对不上的行。"""
    pos = 0
    for line in block:
        key = norm(line)
        hit = blob.find(key, pos)
        if hit < 0:
            return line
        pos = hit + len(key)
    return None


def check_outputs(only: list[str]) -> None:
    bases = example_bases()
    if not bases:
        fail("② examples/ 里没有任何示例")
        return
    missing = [nn for nn in sorted(bases)
               if not (BUILD / "shared" / f"{bases[nn]}.run1").is_file()]
    if missing:
        fail(f"② build/shared 产物不全（缺 {missing}），请先跑完整的 ./run-all.sh")
        return

    checked = skipped = 0
    targets = chapter_files() + [p for p in (README, CHEAT) if p.is_file()]
    for md in targets:
        nn = md.name[:2] if md in chapter_files() else ""
        blob = norm(chapter_blob(nn if nn in bases or nn in NO_EXAMPLE else "", bases))
        for lineno, body in text_blocks(md):
            if not body:
                continue
            checked += 1
            if any(b.lstrip().startswith(mk) for b in body for mk in NON_OUTPUT_MARKERS):
                skipped += 1
                continue
            if only and md in chapter_files() and nn not in only:
                continue
            bad = match_block(body, blob)
            if bad is not None:
                name = md.name if md in chapter_files() else md.name
                fail(f"② {name}:{lineno} 有一行按序在产物里找不到：{bad[:70]}")
    print(f"[②] 核对 {checked} 个 ```text 块（跳过非输出块 {skipped} 个）")


# ------------------------------------------------------------
# 关③：坑位自洽
# ------------------------------------------------------------
def pitfalls_of(md: Path) -> list[int]:
    nums: list[int] = []
    inside = False
    for ln in read(md).splitlines():
        if ln.startswith("## "):
            inside = "坑位清单" in ln
        elif inside:
            m = re.match(r"\s*(\d+)\.\s+\*\*", ln)
            if m:
                nums.append(int(m.group(1)))
    return nums


def check_pitfalls() -> None:
    where: dict[int, str] = {}
    for md in chapter_files():
        nums = pitfalls_of(md)
        if not nums:
            fail(f"③ {md.name} 没有「## 坑位清单」或条目为空")
            continue
        if len(nums) < 2:
            fail(f"③ {md.name} 坑位清单只有 {len(nums)} 条（须 >= 2）")
        for n in nums:
            if n in where:
                fail(f"③ 坑位 {n} 重复：{where[n]} 与 {md.name}")
            where[n] = md.name[:2]
    if not where:
        fail("③ 全书一条坑位都没解析到")
        return
    got = sorted(where)
    if got != list(range(1, max(got) + 1)):
        fail(f"③ 坑位编号不连续：实得 {got[0]}..{got[-1]}，缺 "
             f"{sorted(set(range(1, max(got) + 1)) - set(got))}")

    if CHEAT.is_file():
        cheat: dict[int, str] = {}
        for m in re.finditer(r"^\|\s*(\d+)\s*\|.*?\[\s*(\d\d)\s*\]\(docs/",
                             read(CHEAT), re.M):
            cheat[int(m.group(1))] = m.group(2)
        if sorted(cheat) != got:
            fail(f"③ CHEATSheet 收录 {len(cheat)} 条 vs 各章 {len(got)} 条；"
                 f"仅各章有 {sorted(set(got) - set(cheat))}，"
                 f"仅 CHEATSheet 有 {sorted(set(cheat) - set(got))}")
        for n, ch in where.items():
            if n in cheat and cheat[n] != ch:
                fail(f"③ 坑位 {n} 收录在 {ch} 章，CHEATSheet 却指向 {cheat[n]} 章")
    else:
        fail("③ CHEATSheet.md 不存在")

    if README.is_file():
        cited = {int(m.group(1)) for m in re.finditer(r"(\d+)\s*条实测坑位", read(README))}
        if cited and cited != {len(got)}:
            fail(f"③ README 引用 {sorted(cited)} 条，各章实为 {len(got)} 条")
    print(f"[③] 坑位 {len(got)} 条（1..{got[-1]}），分布在 {len(set(where.values()))} 章")


# ------------------------------------------------------------
# 关④：导航与链接
# ------------------------------------------------------------
H1 = re.compile(r"^# (.+?)\s*$", re.M)
MD_LINK = re.compile(r"\[([^\]]*)\]\(([^)#\s]+?\.md)\)")
CPP_LINK = re.compile(r"\]\((examples/[A-Za-z0-9_./-]+\.cpp)\)")


def titles() -> dict[str, str]:
    out = {}
    for md in chapter_files():
        m = H1.search(read(md))
        out[md.name] = m.group(1) if m else ""
    return out


def check_nav(only: list[str]) -> None:
    tt = titles()
    docs = chapter_files()
    if README.is_file():
        rtxt = read(README)
        absent = sorted(p.name for p in docs if p.name not in rtxt)
        if absent:
            fail(f"④ README 分章导航缺：{absent}")
        else:
            print(f"[④] README 导航含全部 {len(docs)} 章")

    for md in docs:
        if only and md.name[:2] not in only:
            continue
        text = read(md)
        lines = [l for l in text.splitlines() if l.strip()]
        last = lines[-1] if lines else ""
        if "上一章" not in last or "返回" not in last:
            fail(f"④ {md.name} 末行不是导航行（应同时含「上一章」与「返回」）")
        if md.name[:2] not in NO_EXAMPLE and "对应示例" not in text:
            fail(f"④ {md.name} 缺少「> 对应示例：」行")

        for ln in text.splitlines():
            is_nav = ln.startswith("上一章：")
            for label, target in MD_LINK.findall(ln):
                if target.startswith("http"):
                    continue
                resolved = (md.parent / target).resolve()
                if not resolved.exists():
                    fail(f"④ {md.name} 死链：{target}")
                    continue
                if resolved.name not in tt:
                    continue
                # 「链接文字必须等于目标章 H1」只约束章末导航行（本仓库惯例见
                # cppgui/tools/reconcile-nav.py）——正文交叉引用按惯例写简称
                # （[12 章](12-verification.md)），全称会把句子撑破。简称也有
                # 下限：标号必须指向同号的章。
                if is_nav:
                    if tt[resolved.name] and label != tt[resolved.name]:
                        fail(f"④ {md.name} 导航链接文字与目标 H1 不符："
                             f"{label!r} != {tt[resolved.name]!r}")
                else:
                    m = re.fullmatch(r"(\d\d)(?: 章)?", label)
                    if m and m.group(1) != resolved.name[:2]:
                        fail(f"④ {md.name} 正文交叉引用标号不符："
                             f"[{label}] 指向 {resolved.name}")
        for target in CPP_LINK.findall(text):
            if not (ROOT / target).exists():
                fail(f"④ {md.name} 示例死链：{target}")

    for doc in (README, CHEAT):
        if not doc.is_file():
            continue
        for _, target in MD_LINK.findall(read(doc)):
            if target.startswith("http"):
                continue
            if not (doc.parent / target).resolve().exists():
                fail(f"④ {doc.name} 死链：{target}")


# ------------------------------------------------------------
# 关⑤：示例代码必须全部引用进正文（不许让读者自己开源码）
# ------------------------------------------------------------
def cpp_lines(md: Path) -> list[str]:
    """该文档里所有 ```cpp 块的行。"""
    lines = read(md).splitlines()
    out: list[str] = []
    i = 0
    while i < len(lines):
        if lines[i].startswith("```cpp"):
            j = i + 1
            while j < len(lines) and not lines[j].startswith("```"):
                out.append(lines[j])
                j += 1
            i = j + 1
        else:
            i += 1
    return out


def check_quotes(only: list[str]) -> None:
    bases = example_bases()
    checked = 0
    for nn, base in sorted(bases.items()):
        if only and nn not in only:
            continue
        docs = [p for p in chapter_files() if p.name[:2] == nn]
        if not docs:
            continue  # 关①已经报过「示例无对应章节」
        src = read(EXAMPLES / f"{base}.cpp").splitlines()
        # 注释行不算「要讲解的代码」；空行不算
        code = [l for l in src if norm(l) and not norm(l).startswith("//")]
        quoted = {norm(l) for l in cpp_lines(docs[0]) if norm(l)}
        miss = [norm(l) for l in code if norm(l) not in quoted]
        checked += 1
        if miss:
            fail(f"⑤ {nn} 章正文没有引用 {base}.cpp 的 {len(miss)} 行代码，"
                 f"读者被迫去看源码：{miss[:3]}")
    print(f"[⑤] {checked} 章逐行核对「示例代码 ⊆ 正文 ```cpp 块」")


# ------------------------------------------------------------
def main() -> int:
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    except AttributeError:
        pass
    only = [a for a in sys.argv[1:] if re.fullmatch(r"\d\d", a)]

    print("== ① 章节 <-> 示例 ==")
    check_alignment()
    print("== ② ```text 块 <-> build 产物 ==")
    check_outputs(only)
    print("== ③ 坑位编号自洽 ==")
    check_pitfalls()
    print("== ④ 导航与链接 ==")
    check_nav(only)
    print("== ⑤ 示例代码全部引用进正文 ==")
    check_quotes(only)

    if errors:
        print()
        for e in errors:
            print(f"  [FAIL] {e}")
        print(f"\n共 {len(errors)} 项不通过")
        return 1
    print("\n五关核查全部通过")
    return 0


if __name__ == "__main__":
    sys.exit(main())
