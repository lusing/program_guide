#!/usr/bin/env python
"""提取中英两版的编号结果索引，供编号映射对账。

英文版：build/ocr/rotman_en/full.txt（文本层）。
中译本：build/ocr/rotman/pNNN.txt（rapidocr，书页 = PDF 页 − 3）。
产出：build/ocr/index_en.txt / build/ocr/index_zh.txt
"""

import re
from pathlib import Path

HERE = Path(__file__).resolve().parent
BUILD = HERE.parent / "build" / "ocr"

KIND_EN = {"Theorem": "Thm", "Proposition": "Prop", "Lemma": "Lem", "Corollary": "Cor", "Example": "Ex"}
KIND_ZH = {"定理": "Thm", "命题": "Prop", "引理": "Lem", "推论": "Cor", "例": "Ex"}


def index_en() -> None:
    txt = (BUILD / "rotman_en" / "full.txt").read_text(encoding="utf-8")
    flat = re.sub(r"===== PDF \d+ =====\n?", "", txt)
    pat = re.compile(
        r"(Theorem|Proposition|Lemma|Corollary) (\d+)\.(\d+)(?:\s*\(([^)]{0,70})\))?[.:]?\s*"
    )
    seen: dict = {}
    for m in pat.finditer(flat):
        key = (m.group(2), m.group(3))
        if key in seen:
            continue
        tail = flat[m.end(): m.end() + 130].replace("\n", " ")
        tail = re.sub(r"\s+", " ", tail)
        seen[key] = (m.group(1), m.group(4) or "", tail)
    lines = []
    for (ch, no), (kind, name, tail) in sorted(seen.items(), key=lambda kv: (int(kv[0][0]), int(kv[0][1]))):
        label = KIND_EN[kind]
        nm = "(%s)" % name if name else ""
        lines.append(f"{label} {ch}.{no} {nm} :: {tail[:110]}")
    (BUILD / "index_en.txt").write_text("\n".join(lines), encoding="utf-8")
    print("english results:", len(lines))


def index_zh() -> None:
    pat = re.compile(r"(定理|命题|引理|推论)\s*(\d+)\.(\d+)")
    seen: dict = {}
    for f in sorted((BUILD / "rotman").glob("p*.txt")):
        txt = f.read_text(encoding="utf-8")
        flat = re.sub(r"\s+", " ", txt)
        for m in pat.finditer(flat):
            key = (m.group(2), m.group(3))
            if key in seen:
                continue
            tail = flat[m.end(): m.end() + 90]
            seen[key] = (m.group(1), tail)
    lines = []
    for (ch, no), (kind, tail) in sorted(seen.items(), key=lambda kv: (int(kv[0][0]), int(kv[0][1]))):
        label = KIND_ZH[kind]
        lines.append(f"{label} {ch}.{no} :: {tail[:100]}")
    (BUILD / "index_zh.txt").write_text("\n".join(lines), encoding="utf-8")
    print("chinese results:", len(lines))


if __name__ == "__main__":
    index_en()
    index_zh()
