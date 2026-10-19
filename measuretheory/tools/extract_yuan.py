#!/usr/bin/env python
"""袁德美-王学军《测度论基础与高等概率论》文字层提取（免 OCR）。

用法（在 measuretheory/ 目录运行）：
    G:/scoop/apps/python313/current/python.exe -I tools/extract_yuan.py v1 247 272
    G:/scoop/apps/python313/current/python.exe -I tools/extract_yuan.py v2 11 66

两册均有文字层与内嵌书签（PyMuPDF get_text 直出；数学公式为 Unicode
文本，分式/根号可能失真——取材仍按项目纪律：骨架定位定理编号/结构，
公式由写作时按领域知识重建）。输出 build/ocr/yuan_v{1,2}_pNNN.txt。

页码速查：上册 v1 = pdf247 起 第10章 乘积 / pdf272 第11章 局部紧 /
pdf296 第12章 弱收敛；下册 v2 = pdf11 第13章 独立 / pdf34 第14章
不等式 / pdf64 第15章 条件期望 / pdf96 第16章 多维正态 / pdf111
第17章 特征函数 / pdf145 第18章 应用 / pdf159 第19章 大数律 /
pdf184 第20章 强大数律 / pdf216 第21章 CLT / pdf247 第22章 无穷
可分 / pdf269 第23章 普遍极限 / pdf308 第24章 稳定 / pdf344 第25章
重对数律。全目录见 build/ocr/yuan_toc.txt。
"""

import sys
from pathlib import Path

PDFS = {
    "v1": r"G:\book\数学\测度论基础与高等概率论 上册 (袁德美, 王学军) (z-library.sk, 1lib.sk, z-lib.sk).pdf",
    "v2": r"G:\book\数学\测度论基础与高等概率论 下册 (袁德美 王学军) (z-library.sk, 1lib.sk, z-lib.sk).pdf",
}

HERE = Path(__file__).resolve().parent
BUILD = HERE.parent / "build" / "ocr"


def extract(vol: str, first: int, last: int) -> None:
    import fitz

    BUILD.mkdir(parents=True, exist_ok=True)
    doc = fitz.open(PDFS[vol])
    done = skipped = 0
    for n in range(first, min(last, doc.page_count) + 1):
        out = BUILD / ("yuan_%s_p%03d.txt" % (vol, n))
        if out.exists() and out.stat().st_size > 0:
            skipped += 1
            continue
        text = doc[n - 1].get_text()
        with out.open("w", encoding="utf-8") as f:
            f.write("===== 袁%s PDF p%d =====\n" % (vol, n))
            f.write(text)
        done += 1
    print("extract %s %d-%d: done=%d skipped=%d" % (vol, first, last, done, skipped))


if __name__ == "__main__":
    if len(sys.argv) != 4 or sys.argv[1] not in PDFS:
        sys.exit(__doc__)
    extract(sys.argv[1], int(sys.argv[2]), int(sys.argv[3]))
