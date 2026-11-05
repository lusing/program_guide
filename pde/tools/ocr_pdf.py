#!/usr/bin/env python
"""通用 PDF OCR 工具：按书页渲染 + 识别，输出到 build/ocr_shamaev/。

用法（python313 + cudnn PATH）：
    python -I tools/ocr_pdf.py ocr "<PDF路径>" <first> <last> [offset]
    offset：书页 N = PDF 1-based 页 N+offset（默认 0）
"""
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
BUILD = HERE.parent / "build" / "ocr_shamaev"
IMG = BUILD / "img"


def render(pdf, first, last, offset, dpi=200):
    import pymupdf

    BUILD.mkdir(parents=True, exist_ok=True)
    IMG.mkdir(parents=True, exist_ok=True)
    doc = pymupdf.open(pdf)
    for n in range(first, last + 1):
        pix = doc[n + offset - 1].get_pixmap(dpi=dpi)
        pix.save(IMG / ("b%03d.png" % n))
    print("rendered book pages %d-%d -> %s" % (first, last, IMG))


def ocr(first, last):
    from rapidocr_onnxruntime import RapidOCR

    engine = RapidOCR(det_model_path=None, det_use_cuda=False,
                      cls_model_path=None, cls_use_cuda=False,
                      rec_model_path=None, rec_use_cuda=False)
    missing = [n for n in range(first, last + 1)
               if not (IMG / ("b%03d.png" % n)).exists()]
    if missing:
        return
    out_lines = []
    for n in range(first, last + 1):
        p = IMG / ("b%03d.png" % n)
        r, _ = engine(str(p))
        out_lines.append("===== book page %d =====" % n)
        out_lines.extend(x[1] for x in r) if r else out_lines.append("(empty)")
    BUILD.mkdir(parents=True, exist_ok=True)
    out = BUILD / ("pages_%03d-%03d.txt" % (first, last))
    out.write_text("\n".join(out_lines), encoding="utf-8")
    print("\n".join(out_lines))
    print("saved ->", out)


if __name__ == "__main__":
    cmd = sys.argv[1]
    if cmd == "ocr":
        pdf = sys.argv[2]
        first, last = int(sys.argv[3]), int(sys.argv[4])
        offset = int(sys.argv[5]) if len(sys.argv) > 5 else 0
        render(pdf, first, last, offset)
        ocr(first, last)
