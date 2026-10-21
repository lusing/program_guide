#!/usr/bin/env python
"""郝兆宽/杨跃《集合论：对无穷概念的探索》(复旦大学出版社) 扫描版 OCR 流水线。

用法（仓库根运行）：
    G:/scoop/apps/python313/current/python.exe -I tools/ocr_haoyang.py render 0 12
    G:/scoop/apps/python313/current/python.exe -I tools/ocr_haoyang.py ocr 0 12
PDF 共 261 页，零文字层（纯扫描）。产出仅作取材骨架；
数学公式由写作时按领域知识重建（扫描数学 OCR 不可信）。
"""
import sys
from pathlib import Path

PDF = r"G:\book\计算机\集合论 对无穷概念的探索 (郝兆宽 杨跃) (z-library.sk, 1lib.sk, z-lib.sk).pdf"
HERE = Path(__file__).resolve().parent
BUILD = HERE.parent / "build" / "ocr"
IMG = BUILD / "img_hy"


def render(first: int, last: int) -> None:
    import pymupdf
    BUILD.mkdir(parents=True, exist_ok=True)
    IMG.mkdir(parents=True, exist_ok=True)
    doc = pymupdf.open(PDF)
    for i in range(first, min(last + 1, len(doc))):
        pix = doc[i].get_pixmap(dpi=250)
        pix.save(str(IMG / ("p%03d.png" % i)))
    print("rendered", first, "-", last)


def ocr(first: int, last: int) -> None:
    from rapidocr_onnxruntime import RapidOCR
    engine = RapidOCR()
    out = BUILD / ("hy_%03d-%03d.txt" % (first, last))
    with out.open("w", encoding="utf-8") as f:
        for n in range(first, last + 1):
            img = IMG / ("p%03d.png" % n)
            if not img.exists():
                continue
            res, _ = engine(str(img))
            f.write(f"\n===== PDF page {n} =====\n")
            for line in res or []:
                f.write(line[1] + "\n")
    print("wrote", out)


if __name__ == "__main__":
    if len(sys.argv) == 4 and sys.argv[1] == "render":
        render(int(sys.argv[2]), int(sys.argv[3]))
    elif len(sys.argv) == 4 and sys.argv[1] == "ocr":
        ocr(int(sys.argv[2]), int(sys.argv[3]))
    else:
        print(__doc__)
