#!/usr/bin/env python
"""严加安《测度论讲义》(第二版) 扫描版 OCR 流水线。

用法（在 measuretheory/ 目录运行，python = 3.13 with rapidocr_onnxruntime）：
    G:/scoop/apps/python313/current/python.exe -I tools/ocr_yan.py render 6 12
    G:/scoop/apps/python313/current/python.exe -I tools/ocr_yan.py ocr 6 12

渲染 PDF 第 N-M 页为 PNG（300 dpi）并 OCR，输出 build/ocr/yan_NNN-MMM.txt。
PDF 共 304 页，扫描无文字层。

产出仅作取材骨架：定理编号/结构/习题素材。数学公式由写作时按领域知识
重建——扫描数学 OCR 不可信（项目纪律）。
"""

import subprocess
import sys
from pathlib import Path

PDF = r"G:\book\数学\测度论讲义 (严加安) (z-library.sk, 1lib.sk, z-lib.sk).pdf"
HERE = Path(__file__).resolve().parent
BUILD = HERE.parent / "build" / "ocr"
IMG = BUILD / "img"


def render(first: int, last: int) -> None:
    BUILD.mkdir(parents=True, exist_ok=True)
    IMG.mkdir(parents=True, exist_ok=True)
    code_text = (
        "from pdf2image import convert_from_path\n"
        f"pages = convert_from_path({PDF!r}, dpi=300, first_page={first}, last_page={last})\n"
        f"base = {first}\n"
        f"outdir = {IMG.as_posix()!r}\n"
        "import os\n"
        "kept = 0\n"
        "for i, p in enumerate(pages):\n"
        "    fn = outdir + '/p%03d.png' % (base + i)\n"
        "    if not os.path.exists(fn):\n"
        "        p.save(fn); kept += 1\n"
        "print('rendered', len(pages), 'new', kept)\n"
    )
    code = subprocess.call([sys.executable, "-I", "-c", code_text])
    if code != 0:
        sys.exit("render failed")


def ocr(first: int, last: int, only_odd: bool = False) -> None:
    """逐页 OCR 到 build/ocr/yan_full/pNNN.txt，已存在且非空则跳过（断点续扫）。

    only_odd=True 时只处理奇数 PDF 页（本书对页扫描每摊重复两次，
    奇数页已含全部内容；17-303 的奇数页覆盖书 p.2-287）。
    """
    from rapidocr_onnxruntime import RapidOCR  # noqa: import after PATH set by caller

    engine = RapidOCR()
    full = BUILD / "yan_full"
    full.mkdir(parents=True, exist_ok=True)
    done = skipped = missing = 0
    for n in range(first, last + 1):
        if only_odd and n % 2 == 0:
            continue
        img = IMG / ("p%03d.png" % n)
        if not img.exists():
            missing += 1
            continue
        out = full / ("p%03d.txt" % n)
        if out.exists() and out.stat().st_size > 0:
            skipped += 1
            continue
        result, _ = engine(img.as_posix())
        with out.open("w", encoding="utf-8") as f:
            f.write(f"===== PDF p{n} =====\n")
            if result:
                for box, text, score in result:
                    xs = [p[0] for p in box]
                    f.write(f"[x{int(min(xs)):4d}] {text}\n")
        done += 1
    print(f"ocr done={done} skipped={skipped} missing={missing}")


if __name__ == "__main__":
    if len(sys.argv) < 4 or sys.argv[1] not in ("render", "ocr"):
        sys.exit(__doc__)
    a = int(sys.argv[2])
    b = int(sys.argv[3])
    only_odd = len(sys.argv) > 4 and sys.argv[4] == "odd"
    if sys.argv[1] == "render":
        render(a, b)
    else:
        ocr(a, b, only_odd=only_odd)
