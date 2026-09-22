#!/usr/bin/env python3
"""SDL2 教程文档机器核查（三项）。

用法：
    python3 tools/check_docs.py            # 先跑 ./run-all.sh 生成 build/ 产物

核查项：
    (a) 指南章节引用的源码文件 <-> examples/ 目录一一对应
    (b) 文档 ```text 块引用的输出行能否在 build 产物里逐字节找到
        （块前一行含 \"非示例运行输出\" / \"非运行输出\" 的显式标注则跳过）
    (c) 坑位编号自洽：CHEATSheet 条目数 == 指南各章坑位清单之和 == README 引用的数字
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BUILD = ROOT / "build"
EXAMPLES = ROOT / "examples"
GUIDE = ROOT / "SDL2编程指南.md"
CHEAT = ROOT / "CHEATSheet.md"
README = ROOT / "README.md"

errors: list[str] = []


def fail(msg: str) -> None:
    errors.append(msg)


# ------------------------------------------------------------
# (a) 章节 <-> 示例文件
# ------------------------------------------------------------
def check_sections() -> None:
    if not GUIDE.exists():
        fail(f"找不到指南文件: {GUIDE}")
        return
    text = GUIDE.read_text(encoding="utf-8")
    referenced = set(re.findall(r"源码：`examples/(\d+)_[A-Za-z0-9_]+\.cpp`", text))
    actual = {p.name.split("_")[0] for p in EXAMPLES.glob("*.cpp")}
    if referenced != actual:
        fail(f"(a) 指南引用的示例 {sorted(referenced)} 与 examples/ {sorted(actual)} 不一致")
    # 示例里印的分节标记编号必须与文件名编号一致
    for p in sorted(EXAMPLES.glob("*.cpp")):
        num = p.name.split("_")[0]
        src = p.read_text(encoding="utf-8")
        if f'==== {num} 开始 ====' not in src or f'==== {num} 结束 ====' not in src:
            fail(f"(a) {p.name} 缺少与文件名一致的分节标记（应为 ==== {num} 开始/结束 ====）")


# ------------------------------------------------------------
# (b) text 块引用 vs build 产物
# ------------------------------------------------------------
def norm(s: str) -> str:
    return re.sub(r"\s+", " ", s).strip()


def load_artifacts() -> str:
    if not BUILD.exists():
        fail("(b) build/ 不存在，请先运行 ./run-all.sh")
        return ""
    parts: list[str] = []
    for p in sorted(BUILD.rglob("*")):
        if p.is_file():
            try:
                parts.append(p.read_text(encoding="utf-8", errors="replace"))
            except OSError:
                continue
    return norm("\n".join(parts))


TEXT_BLOCK = re.compile(r"```text\n(.*?)```", re.S)


def check_artifacts_complete() -> None:
    """产物不全时直接报错，避免把「只跑了单个示例」误判成文档写错。"""
    expected = {p.name.split("_")[0] for p in EXAMPLES.glob("*.cpp")}
    shared = BUILD / "shared"
    have = {p.name.split("_")[0] for p in shared.glob("*.sec1")} if shared.exists() else set()
    if expected - have:
        fail(f"(b) build/shared 产物不全（缺 {sorted(expected - have)}），"
             f"请先跑完整的 ./run-all.sh 再核查")


def check_blocks(artifacts: str) -> None:
    check_artifacts_complete()
    if not artifacts:
        return
    for doc in (GUIDE, CHEAT, README):
        if not doc.exists():
            continue
        lines = doc.read_text(encoding="utf-8").splitlines()
        for i, line in enumerate(lines):
            if not line.startswith("```text"):
                continue
            # 块前一行若显式标注为非运行输出则跳过
            prev = lines[i - 1].strip() if i > 0 else ""
            if "非示例运行输出" in prev or "非运行输出" in prev:
                continue
            body = []
            for l in lines[i + 1:]:
                if l.startswith("```"):
                    break
                body.append(l)
            # 逐行核对：整块拼接会对「跨示例摘录」误报，
            # 也会把 static-libs 这类折行长参数整块匹配掉。
            missing = [l for l in body if l.strip() and norm(l) not in artifacts]
            if missing:
                fail(f"(b) {doc.name}:{i + 1} 的 text 块有 {len(missing)} 行在 build 产物里找不到，"
                     f"首行：{missing[0][:80]}")


# ------------------------------------------------------------
# (c) 坑位编号自洽
# ------------------------------------------------------------
def check_pitfalls() -> None:
    guide_nums: set[int] = set()
    if GUIDE.exists():
        gtext = GUIDE.read_text(encoding="utf-8")
        # 只取「**坑位清单**」标题之后、下一个二级标题之前的编号列表
        for chunk in re.split(r"\n## ", gtext):
            if "**坑位清单**" not in chunk:
                continue
            tail = chunk.split("**坑位清单**", 1)[1]
            for m in re.finditer(r"^(\d+)\. ", tail, re.M):
                guide_nums.add(int(m.group(1)))
    cheat_nums: set[int] = set()
    if CHEAT.exists():
        ctext = CHEAT.read_text(encoding="utf-8")
        for m in re.finditer(r"^\|\s*(\d+)\s*\|", ctext, re.M):
            cheat_nums.add(int(m.group(1)))

    if not guide_nums:
        fail("(c) 指南里没解析到任何坑位清单条目")
    if guide_nums != cheat_nums:
        only_guide = sorted(guide_nums - cheat_nums)
        only_cheat = sorted(cheat_nums - guide_nums)
        fail(f"(c) 指南坑位 {len(guide_nums)} 条 vs CHEATSheet {len(cheat_nums)} 条；"
             f"仅指南有 {only_guide}，仅 CHEATSheet 有 {only_cheat}")

    # README 引用的数字应对齐 CHEATSheet
    if README.exists():
        rtext = README.read_text(encoding="utf-8")
        cited = {int(m.group(1)) for m in re.finditer(r"(\d+)\s*条实测坑位", rtext)}
        if cited and cited != {len(cheat_nums)}:
            fail(f"(c) README 引用 {sorted(cited)} 条，CHEATSheet 实为 {len(cheat_nums)} 条")
    print(f"   指南坑位 {len(guide_nums)} 条 · CHEATSheet {len(cheat_nums)} 条")


def main() -> int:
    print("== (a) 章节 <-> 示例文件 ==")
    check_sections()
    print("== (b) text 块 vs build 产物 ==")
    check_blocks(load_artifacts())
    print("== (c) 坑位编号自洽 ==")
    check_pitfalls()

    if errors:
        print()
        for e in errors:
            print(f"  [FAIL] {e}")
        print(f"\n共 {len(errors)} 项不通过")
        return 1
    print("\n三项核查全部通过")
    return 0


if __name__ == "__main__":
    sys.exit(main())
