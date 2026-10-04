#!/usr/bin/env python3
"""embed_outputs.py —— 把每章 docs/NN-*.md 的【最后一个】```text 输出块，
用该章示例现场重跑的 stdout 逐字节重灌。

    python tools/embed_outputs.py [NN ...]

围栏纪律：```text 只属于真实运行输出。讲解中途引用输出片段/数据展示/
ASCII 图应当用裸 ``` 围栏——本工具会把每章非末尾的 ```text 围栏降级为
裸围栏（提示但由本工具一并处理），末尾输出块以当前二进制为准重写。
"""
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / "docs"
BUILD = ROOT / "build"
TIMEOUT = 60


def product_lines(nn: str) -> list[str]:
    """现场重跑章号 nn 的 msvc 产物，返回输出行（不 rstrip，保尾随空格差异可见）。"""
    exes = sorted(BUILD.glob(f"{nn}_*.exe"))
    if not exes:
        raise SystemExit(f"[env] build/ 下没有 {nn}_*.exe，先跑 build.ps1")
    r = subprocess.run([str(exes[0])], cwd=str(BUILD), capture_output=True,
                       timeout=TIMEOUT)
    if r.returncode != 0:
        raise SystemExit(f"[env] {exes[0].name} 退出码 {r.returncode}")
    return r.stdout.decode("utf-8", errors="replace").splitlines()


def main():
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    except AttributeError:
        pass
    argv = [a for a in sys.argv[1:] if not a.startswith("-")]

    for md in sorted(DOCS.glob("[0-9][0-9]-*.md")):
        nn = md.name.split("-")[0]
        if argv and nn not in argv:
            continue
        text = md.read_text(encoding="utf-8")
        lines = text.splitlines()
        # 找出所有 ```text 块的起始行号（0 基）
        starts = [i for i, ln in enumerate(lines) if ln.strip() == "```text"]
        if not starts:
            print(f"[skip] {md.name} 没有 ```text 块")
            continue
        # 非末尾的 ```text → 裸 ```（讲解性引用，不参与对账）
        for i in starts[:-1]:
            lines[i] = "```"
        # 末尾块：定位结束围栏
        last = starts[-1]
        end = None
        for j in range(last + 1, len(lines)):
            if lines[j].startswith("```"):
                end = j
                break
        if end is None:
            print(f"[warn] {md.name} 末尾 ```text 块未闭合")
            continue
        prod = product_lines(nn)
        new_lines = lines[:last + 1] + prod + lines[end:]
        md.write_text("\n".join(new_lines) + "\n", encoding="utf-8")
        print(f"[ok] {md.name}：末尾输出块重灌 {len(prod)} 行，"
              f"降级 {len(starts) - 1} 个中途 ```text")
    return 0


if __name__ == "__main__":
    sys.exit(main())
