"""把多行 $$ 展示块折叠为单行 $$…$$。

原因：Codeberg（Forgejo）仓库文件视图的数学块解析器只认单行
$$ … $$；多行 $$ 块在非 wiki 页面不被解析，两个 $$ 标记还会被
行内单 $ 解析器各吞成一个空公式（正文原样露出）。单行 $$…$$
在 Codeberg/GitHub/VS Code 三端都能渲染为展示公式。

围栏代码块不动；支持 > 引用块内的 $$。幂等。
用法：python tools/collapse_display_math.py --root <教程目录>
"""
from __future__ import annotations

import argparse
import pathlib
import re
import sys

OPEN_LINE = re.compile(r"^(\s*(?:>\s*)*)\$\$\s*$")
QUOTE = re.compile(r"^\s*>\s?")


def collapse(text: str) -> tuple[str, int]:
    lines = text.split("\n")
    out = []
    in_fence = False
    count = 0
    i = 0
    while i < len(lines):
        line = lines[i]
        if line.lstrip().startswith(("```", "~~~")):
            in_fence = not in_fence
            out.append(line)
            i += 1
            continue
        m = None if in_fence else OPEN_LINE.match(line)
        if not m:
            out.append(line)
            i += 1
            continue
        prefix = m.group(1)
        quote = ">" in prefix
        body = []
        j = i + 1
        while j < len(lines) and not OPEN_LINE.match(lines[j]):
            b = lines[j]
            if quote:
                if not QUOTE.match(b):
                    raise ValueError(f"引用展示块内出现无 > 前缀行: {b[:50]!r}")
                b = QUOTE.sub("", b)
            body.append(b.strip())
            j += 1
        if j >= len(lines):
            raise ValueError(f"展示块未闭合: 第 {i + 1} 行")
        joined = " ".join(p for p in body if p)
        if not joined:
            raise ValueError(f"空展示块: 第 {i + 1} 行")
        out.append(f"{prefix}$${joined}$$")
        count += 1
        i = j + 1
    return "\n".join(out), count


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", type=pathlib.Path, required=True)
    args = ap.parse_args()
    files = sorted((args.root / "docs").glob("*.md"))
    readme = args.root / "README.md"
    if readme.exists():
        files.append(readme)
    total = 0
    for path in files:
        raw = path.read_bytes()
        crlf = b"\r\n" in raw
        text = raw.decode("utf-8").replace("\r\n", "\n")
        new, count = collapse(text)
        if count:
            print(f"[collapsed] {path.name}: {count}")
            total += count
        if new != text:
            path.write_text(new, encoding="utf-8", newline="\r\n" if crlf else "\n")
    print("totals:", total)
    return 0


if __name__ == "__main__":
    sys.exit(main())
