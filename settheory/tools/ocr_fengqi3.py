#!/usr/bin/env python
"""冯琦《集合论导引 第三卷 高阶无穷》扫描版 OCR 流水线。

用法（settheory 目录运行）：
    G:/scoop/apps/python313/current/python.exe -I tools/ocr_fengqi3.py render 19 22
    G:/scoop/apps/python313/current/python.exe -I tools/ocr_fengqi3.py ocr 19 22

页码参数均为 1 基 PDF 页码；第三卷 PDF 页 = 印刷书页 + 20。
OCR 只作取材索引；公式、量词和上下标必须回读页面图像校订。
"""
import sys
from pathlib import Path

PDF = r"G:\book\计算机\集合论导引 第三卷 高阶无穷 (冯琦) (z-library.sk, 1lib.sk, z-lib.sk).pdf"
HERE = Path(__file__).resolve().parent
BUILD = HERE.parent / "build" / "ocr"
IMG = BUILD / "img_fq3"


def page_range(first: int, last: int) -> range:
    if first < 1 or last < first or last > 515:
        raise ValueError("expected 1 <= FIRST <= LAST <= 515")
    return range(first, last + 1)


def render(first: int, last: int) -> None:
    import pymupdf
    pages = page_range(first, last)
    BUILD.mkdir(parents=True, exist_ok=True)
    IMG.mkdir(parents=True, exist_ok=True)
    with pymupdf.open(PDF) as doc:
        if len(doc) != 515:
            raise ValueError(f"expected 515 PDF pages, got {len(doc)}")
        for page in pages:
            out = IMG / ("p%03d.png" % page)
            if out.exists():
                continue
            doc[page - 1].get_pixmap(dpi=250).save(str(out))
    print("rendered", first, "-", last)


def ocr(first: int, last: int) -> None:
    from rapidocr_onnxruntime import RapidOCR
    pages = page_range(first, last)
    images = [IMG / ("p%03d.png" % page) for page in pages]
    missing = [str(path) for path in images if not path.is_file()]
    if missing:
        raise FileNotFoundError("render missing pages first: " + ", ".join(missing))
    BUILD.mkdir(parents=True, exist_ok=True)
    engine = RapidOCR()
    out = BUILD / ("fq3_%03d-%03d.txt" % (first, last))
    with out.open("w", encoding="utf-8") as f:
        for page, img in zip(pages, images):
            res, _ = engine(str(img))
            f.write(f"\n===== PDF page {page} =====\n")
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
