#!/usr/bin/env python
"""边界区编号探针：列出指定 PDF 页内全部编号结果（中英两版）。

用法：python -I -X utf8 tools/probe_num.py en 142 146
      python -I -X utf8 tools/probe_num.py zh 131 135
"""

import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
BUILD = HERE.parent / "build" / "ocr"


def main() -> None:
    which, a, b = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
    if which == "en":
        pat = re.compile(r"(Theorem|Proposition|Lemma|Corollary) (\d+\.\d+)")
        d = BUILD / "rotman_en"
    else:
        pat = re.compile(r"(定理|命题|引理|推论)\s*(\d+\.\d+)")
        d = BUILD / "rotman"
    for n in range(a, b + 1):
        f = d / ("p%03d.txt" % n)
        if not f.exists():
            continue
        flat = re.sub(r"\s+", " ", f.read_text(encoding="utf-8"))
        seen = set()
        for m in pat.finditer(flat):
            if (m.group(2), m.group(1)) in seen:
                continue
            seen.add((m.group(2), m.group(1)))
            tail = flat[m.end(): m.end() + 100]
            print(f"p{n:03d} {m.group(1)} {m.group(2)} :: {tail}")
        print(f"--- p{n:03d} end ---")


if __name__ == "__main__":
    main()
