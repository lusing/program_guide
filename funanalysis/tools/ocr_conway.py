#!/usr/bin/env python
"""Conway《A Course in Functional Analysis》扫描版 OCR 流水线。

用法（在仓库根或任意目录运行）：
    python -I tools/ocr_conway.py render 17 30   # 渲染 PDF 第 17-30 页为 PNG（300 dpi）
    python -I tools/ocr_conway.py ocr 17 30      # OCR 已渲染页面，输出 build/ocr/pages_17-30.txt

前置：RapidOCR (onnxruntime)；GPU DLL 需把 cudnn 加入 PATH：
    set PATH=G:\\cudnn\\9.24\\bin\\12.9\\x64;%PATH%
（bash: export PATH="/g/cudnn/9.24/bin/12.9/x64:$PATH"）

产出仅作取材骨架：定理编号/结构/习题素材。数学公式由写作时按领域知识
重建——扫描数学 OCR 不可信（项目纪律）。
"""

import subprocess
import sys
from pathlib import Path

PDF = r"G:\book\数学\A Course in Functional Analysis Second Edition (John B. Conway) (z-library.sk, 1lib.sk, z-lib.sk).pdf"
HERE = Path(__file__).resolve().parent
BUILD = HERE.parent / "build" / "ocr"
IMG = BUILD / "img"


def render(first: int, last: int) -> None:
    BUILD.mkdir(parents=True, exist_ok=True)
    IMG.mkdir(parents=True, exist_ok=True)
    code = subprocess.call([
        sys.executable, "-I", "-c",
        "from pdf2image import convert_from_path\n"
        f"pages = convert_from_path({PDF!r}, dpi=300, first_page={first}, last_page={last})\n"
        f"for i, p in enumerate(pages):\n"
        f"    p.save(r'{(IMG / ('p%03d.png' % (first + i))).as_posix()}')\n"
        "print('rendered', len(pages))\n",
    ])
    if code != 0:
        sys.exit("render failed")


def ocr(first: int, last: int) -> None:
    from rapidocr_onnxruntime import RapidOCR  # noqa: import after PATH set by caller

    engine = RapidOCR()
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
