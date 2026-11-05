#!/usr/bin/env python
"""Evans《Partial Differential Equations》2nd ed（AMS 影印）扫描版 OCR 流水线。

用法（在 evanspde 目录运行，python313 + cudnn PATH）：
    python -I tools/ocr_ev.py toc            # 渲染并 OCR 目录页
    python -I tools/ocr_ev.py ocr 17 45      # OCR 书第 17-45 页（书页码！）
    python -I tools/ocr_ev.py where          # 打印页码映射

页码映射：书页 N = PDF 1-based 页 N+19（书页 1 = PDF 页 20）。
前置：PyMuPDF + RapidOCR(onnxruntime)；PATH 须含
    G:\\cudnn\\9.24\\bin\\12.9\\x64

产出仅作取材骨架：定理编号/例子数据/结构。数学公式按领域知识重建
——扫描数学 OCR 不可信（项目纪律）。
"""

import sys
from pathlib import Path

PDF = r"G:\book\数学\偏微分方程\偏微分方程（第2版） (Lawrence C. Evans) (Z-Library).pdf"
OFFSET = 19  # 书页 N -> PDF 1-based 页 N+OFFSET
HERE = Path(__file__).resolve().parent
BUILD = HERE.parent / "build" / "ocr"
IMG = BUILD / "img"


def render(first: int, last: int, dpi: int = 200) -> None:
    import fitz

    BUILD.mkdir(parents=True, exist_ok=True)
    IMG.mkdir(parents=True, exist_ok=True)
    doc = fitz.open(PDF)
    for n in range(first, last + 1):
        pix = doc[n + OFFSET - 1].get_pixmap(dpi=dpi)
        pix.save(IMG / ("b%03d.png" % n))
    print("rendered book pages %d-%d -> %s" % (first, last, IMG))


def ocr(first: int, last: int) -> None:
    # 本机 onnxruntime(CPU) 与 onnxruntime-gpu 双装冲突：三个模块全部强制
    # CPU provider 且显式 *_model_path=None（updater KeyError 坑）。
    from rapidocr_onnxruntime import RapidOCR

    engine = RapidOCR(det_model_path=None, det_use_cuda=False,
                      cls_model_path=None, cls_use_cuda=False,
                      rec_model_path=None, rec_use_cuda=False)
    missing = [n for n in range(first, last + 1)
               if not (IMG / ("b%03d.png" % n)).exists()]
    if missing:
        render(min(missing), max(missing))
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
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    if cmd == "toc":
        render(733, 745)  # 附录起步处附近样页可换
    elif cmd == "ocr":
        ocr(int(sys.argv[2]), int(sys.argv[3]))
    elif cmd == "where":
        print("book page N = PDF 1-based page N+%d" % OFFSET)
    else:
        print(__doc__)
