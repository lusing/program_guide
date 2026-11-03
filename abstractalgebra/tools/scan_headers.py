#!/usr/bin/env python
"""扫描 Rotman 教材 PDF，找节首标记（→N.N 标题）。

用法：python scan_headers.py FIRST LAST   （PDF 页码，含端点）
渲染 150dpi + OCR，打印每页中疑似节标题的行（→N.N 开头或 N.N 短行）。
"""
import re
import sys
from pathlib import Path

PDF = r"G:\book\数学\代数\抽象代数基础教程(原书第3版)(作者)(美)Rotman(译者)冯明军 机械工业2008年1月第1版.pdf"
HERE = Path(__file__).resolve().parent
IMG = HERE.parent / "build" / "ocr" / "img"


def main(first: int, last: int) -> None:
    import fitz
    from rapidocr_onnxruntime import RapidOCR

    IMG.mkdir(parents=True, exist_ok=True)
    doc = fitz.open(PDF)
    eng = RapidOCR()
    pat = re.compile(r"(→|一>|一>|->|✓|➔|↦)?\s*(\d\.\s?\d(\.\s?\d)?)\s*([\u4e00-\u9fff（].{0,24})")
    for n in range(first, min(last, doc.page_count) + 1):
        fn = IMG / ("p%03d.png" % n)
        if not fn.exists():
            pix = doc[n - 1].get_pixmap(dpi=150)
            pix.save(fn.as_posix())
        r, _ = eng(fn.as_posix())
        if not r:
            continue
        texts = [t for _, t, s in r]
        joined = " / ".join(texts)
        hits = []
        for t in texts:
            m = re.match(r"^(→|一>)?\s*(\d+\s*[.．]\s*\d+)(\s*[.．]\s*\d+)?\s*([\u4e00-\u9fff].{0,20})$", t)
            if m and len(t) < 28:
                hits.append(t)
        if hits:
            print(f"--- PDF p{n} (书 p{n-3}) :", " | ".join(hits), flush=True)


if __name__ == "__main__":
    main(int(sys.argv[1]), int(sys.argv[2]))
