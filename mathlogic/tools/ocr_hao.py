#!/usr/bin/env python
"""郝兆宽/杨睿之/杨跃《数理逻辑：证明及其限度》(复旦大学出版社 2014) 扫描版 OCR 流水线。

用法（仓库根运行）：
    G:/scoop/apps/python313/current/python.exe -I tools/ocr_hao.py render 16 80
    G:/scoop/apps/python313/current/python.exe -I tools/ocr_hao.py ocr 16 80
PDF 共 265 页：0 封面，1 版权，4 引言，13-15 目录，16 起正文（书页 1）。
产出仅作取材骨架；数学公式由写作时按领域知识重建（扫描数学 OCR 不可信）。
"""
import sys
from pathlib import Path

PDF = r"G:\book\计算机\数理逻辑 证明及其限度.pdf"
HERE = Path(__file__).resolve().parent
BUILD = HERE.parent / "build" / "ocr"
IMG = BUILD / "img_hao"


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
    out = BUILD / ("hao_%03d-%03d.txt" % (first, last))
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
