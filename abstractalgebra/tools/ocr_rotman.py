#!/usr/bin/env python
"""Rotman《抽象代数基础教程》(原书第3版) 扫描版 OCR 流水线。

用法（在 abstractalgebra/ 目录运行）：
    G:/scoop/apps/python313/current/python.exe -I tools/ocr_rotman.py render 4 63
    G:/scoop/apps/python313/current/python.exe -I tools/ocr_rotman.py ocr 4 63

渲染 PDF 第 N-M 页为 PNG（150 dpi）并 OCR，逐页写 build/ocr/rotman/pNNN.txt，
已存在且非空则跳过（断点续扫）。注意：书页 = PDF 页 - 3。

cudnn 依赖：运行前 PATH 前置 G:/cudnn/9.24/bin/12.9/x64。

产出仅作取材骨架：定理编号/结构/习题素材。数学公式由写作时按领域知识
重建——扫描数学 OCR 不可信（项目纪律）。
"""

import sys
from pathlib import Path

PDF = r"G:\book\数学\代数\抽象代数基础教程(原书第3版)(作者)(美)Rotman(译者)冯明军 机械工业2008年1月第1版.pdf"
HERE = Path(__file__).resolve().parent
BUILD = HERE.parent / "build" / "ocr"
IMG = BUILD / "img"
FULL = BUILD / "rotman"


def render(first: int, last: int) -> None:
    """逐页渲染 PDF 为 PNG，已存在则跳过。"""
    import fitz

    IMG.mkdir(parents=True, exist_ok=True)
    doc = fitz.open(PDF)
    kept = 0
    for n in range(first, min(last, doc.page_count) + 1):
        fn = IMG / ("p%03d.png" % n)
        if fn.exists():
            continue
        pix = doc[n - 1].get_pixmap(dpi=150)
        pix.save(fn.as_posix())
        kept += 1
        if kept % 40 == 0:
            print("rendered", kept, flush=True)
    print("render done, new =", kept, "total in dir =", len(list(IMG.glob("p*.png"))))


def ocr(first: int, last: int) -> None:
    """逐页 OCR 到 build/ocr/rotman/pNNN.txt，带 x 坐标行。"""
    from rapidocr_onnxruntime import RapidOCR

    engine = RapidOCR()
    FULL.mkdir(parents=True, exist_ok=True)
    done = skipped = missing = 0
    for n in range(first, last + 1):
        img = IMG / ("p%03d.png" % n)
        if not img.exists():
            missing += 1
            continue
        out = FULL / ("p%03d.txt" % n)
        if out.exists() and out.stat().st_size > 0:
            skipped += 1
            continue
        result, _ = engine(img.as_posix())
        with out.open("w", encoding="utf-8") as f:
            f.write(f"===== PDF p{n} = 书 p{n-3} =====\n")
            if result:
                for box, text, score in result:
                    xs = [p[0] for p in box]
                    f.write(f"[x{int(min(xs)):4d}] {text}\n")
        done += 1
    print(f"ocr done={done} skipped={skipped} missing={missing}")


if __name__ == "__main__":
    if len(sys.argv) < 4 or sys.argv[1] not in ("render", "ocr"):
        sys.exit(__doc__)
    a, b = int(sys.argv[2]), int(sys.argv[3])
    if sys.argv[1] == "render":
        render(a, b)
    else:
        ocr(a, b)
