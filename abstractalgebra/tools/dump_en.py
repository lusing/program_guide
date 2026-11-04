#!/usr/bin/env python
"""英文原书（Rotman, A First Course in Abstract Algebra, 3rd ed.）文本层抽取。

扫描件自带 Acrobat OCR 文本层，直接 get_text 即可（无需 rapidocr）。
逐页写 build/ocr/rotman_en/pNNN.txt（PDF 页号），并合成 full.txt（带页标记）。

用法：G:/scoop/apps/python313/current/python.exe -I -X utf8 tools/dump_en.py
"""

from pathlib import Path

import fitz

PDF = r"G:\book\数学\代数\J.Rotman.-.A.first.course.in.abstract.algebra.pdf"
HERE = Path(__file__).resolve().parent
OUT = HERE.parent / "build" / "ocr" / "rotman_en"


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    doc = fitz.open(PDF)
    parts = []
    for n in range(1, doc.page_count + 1):
        t = doc[n - 1].get_text().strip()
        (OUT / ("p%03d.txt" % n)).write_text(t, encoding="utf-8")
        parts.append("===== PDF %d =====\n%s" % (n, t))
    (OUT / "full.txt").write_text("\n".join(parts), encoding="utf-8")
    print("dumped", doc.page_count, "pages to", OUT)


if __name__ == "__main__":
    main()
