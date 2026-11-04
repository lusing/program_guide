#!/usr/bin/env python
"""陆金甫、关治《偏微分方程数值解法》第3版（2016，清华大学出版社）扫描版 OCR 流水线。

用法（在任意目录运行）：
    python -I tools/ocr_li.py render 5 20    # 渲染 PDF 第 5-20 页为 PNG（300 dpi）
    python -I tools/ocr_li.py ocr 5 20       # OCR 已渲染页面，输出 build/ocr/pages_005-020.txt

前置：PyMuPDF（渲染）+ RapidOCR (onnxruntime)；GPU DLL 需把 cudnn 加入 PATH：
    set PATH=G:\\cudnn\\9.24\\bin\\12.9\\x64;%PATH%

产出仅作取材骨架：章节结构/定理编号/表格素材。数学公式由写作时按领域
知识重建——扫描数学 OCR 不可信（项目纪律）。
"""

import sys
from pathlib import Path

PDF = r"G:\book\数学\偏微分方程\偏微分方程数值解法(第3版)2016.pdf"
HERE = Path(__file__).resolve().parent
BUILD = HERE.parent / "build" / "ocr"
IMG = BUILD / "img"


def render(first: int, last: int) -> None:
    import fitz

    BUILD.mkdir(parents=True, exist_ok=True)
    IMG.mkdir(parents=True, exist_ok=True)
    doc = fitz.open(PDF)
    for n in range(first, last + 1):
        pix = doc[n - 1].get_pixmap(dpi=300)
        pix.save(IMG / ("p%03d.png" % n))
    print("rendered", last - first + 1, "pages ->", IMG)


def ocr(first: int, last: int) -> None:
    from rapidocr_onnxruntime import RapidOCR  # noqa: import after PATH set by caller

    # 本机 onnxruntime(CPU) 与 onnxruntime-gpu 双装冲突：GPU EP 报 bad
    # allocation、CPU EP 找不到 cudnn——三个模块全部强制 CPU provider。
    # 坑：updater 要求 *_model_path 键存在，须显式传 None 才落到默认模型。
    engine = RapidOCR(
        det_model_path=None, det_use_cuda=False,
        cls_model_path=None, cls_use_cuda=False,
        rec_model_path=None, rec_use_cuda=False,
    )
    out = BUILD / f"pages_{first:03d}-{last:03d}.txt"
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


def main() -> None:
    if len(sys.argv) != 4 or sys.argv[1] not in ("render", "ocr"):
        print(__doc__)
        sys.exit(2)
    first, last = int(sys.argv[2]), int(sys.argv[3])
    {"render": render, "ocr": ocr}[sys.argv[1]](first, last)


if __name__ == "__main__":
    main()
