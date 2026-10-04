# 刘伟《设计模式（第2版）》目录页 OCR → materials/liuwei_toc.txt
# 452 页扫描件，目录通常在前 10 页；不足则扩到 14 页。
import pathlib
import warnings

import fitz
from rapidocr_onnxruntime import RapidOCR

warnings.filterwarnings("ignore")

PDF = r"G:\book\计算机\设计模式\设计模式（第2版）.pdf"
OUT = pathlib.Path(__file__).resolve().parents[1] / "materials" / "liuwei_toc.txt"
START, END = 3, 10

engine = RapidOCR()
doc = fitz.open(PDF)
lines = []
for pno in range(START, END + 1):
    pix = doc[pno - 1].get_pixmap(dpi=200)
    result, _ = engine(pix.tobytes("png"))
    lines.append(f"===== PDF page {pno} =====")
    if result:
        lines.extend(item[1] for item in result)
    print(f"page {pno}: {0 if result is None else len(result)} lines")
OUT.write_text("\n".join(lines), encoding="utf-8")
print("written:", OUT)
