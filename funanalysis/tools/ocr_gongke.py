#!/usr/bin/env python
"""《工科泛函分析基础》(2019) 扫描版 OCR 流水线。

用法（仓库根运行，python = 3.13 with rapidocr_onnxruntime）：
    G:/scoop/apps/python313/current/python.exe -I tools/ocr_gongke.py 10 60
渲染 PDF 第 10-60 页为 PNG（300 dpi）并 OCR，输出 build/ocr/gongke_010-060.txt

PDF 共 142 页：10-127 正文，128-141 习题答案，142 参考文献。
产出仅作取材骨架；数学公式由写作时按领域知识重建（扫描数学 OCR 不可信）。
"""

import subprocess
import sys
from pathlib import Path

PDF = r"G:\book\数学\工科泛函分析基础-2019.pdf"
HERE = Path(__file__).resolve().parent
BUILD = HERE.parent / "build" / "ocr"
IMG = BUILD / "img_gongke"


def main(first: int, last: int) -> None:
    BUILD.mkdir(parents=True, exist_ok=True)
    IMG.mkdir(parents=True, exist_ok=True)
    # render
    code = subprocess.call([
        sys.executable, "-I", "-c",
        "import pymupdf\n"
        f"doc = pymupdf.open({PDF!r})\n"
        f"imgdir = r'{IMG.as_posix()}'\n"
        f"for n in range({first}, {last + 1}):\n"
        "    pix = doc[n-1].get_pixmap(dpi=300)\n"
        "    pix.save(imgdir + '/p%03d.png' % n)\n"
        "print('rendered')\n",
    ])
    if code != 0:
        sys.exit("render failed")
    # ocr（断点续扫：输出里已有的页跳过）
    from rapidocr_onnxruntime import RapidOCR

    # config.yaml 默认 use_cuda: true（GPU EP）。显存只够一个进程：
    # 严禁并行运行本脚本（双进程 cudnn FE "out of memory" 崩）。
    engine = RapidOCR()
    out = BUILD / f"gongke_{first:03d}-{last:03d}.txt"
    done = set()
    if out.exists():
        for line in out.read_text(encoding="utf-8").splitlines():
            if line.startswith("===== PDF p"):
                done.add(int(line.split("p")[1].split(" ")[0]))
    todo = [n for n in range(first, last + 1)
            if (IMG / ("p%03d.png" % n)).exists() and n not in done]
    if not todo:
        print("all pages already OCR'd:", out)
        return
    with out.open("a", encoding="utf-8") as f:
        for n in todo:
            result, _ = engine(str(IMG / ("p%03d.png" % n)))
            f.write(f"\n===== PDF p{n} =====\n")
            if result:
                for box, text, score in result:
                    f.write(text + "\n")
            f.flush()
    print("wrote", out)


if __name__ == "__main__":
    main(int(sys.argv[1]), int(sys.argv[2]))
