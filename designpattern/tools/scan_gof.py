# GoF 13 个分卷 PDF：各 OCR 首页标题 → materials/gof_index.txt
# 每行 "001.PDF | <OCR文本前80字符>"，供写作时定位某模式的出处卷。
import pathlib
import warnings

import fitz
from rapidocr_onnxruntime import RapidOCR

warnings.filterwarnings("ignore")

SRC = pathlib.Path(r"G:\book\计算机\设计模式\设计模式可复用面向对象软件的基础")
OUT = pathlib.Path(__file__).resolve().parents[1] / "materials" / "gof_index.txt"

engine = RapidOCR()
lines = []
for pdf in sorted(SRC.glob("*.PDF")):
    doc = fitz.open(pdf)
    pix = doc[0].get_pixmap(dpi=200)
    result, _ = engine(pix.tobytes("png"))
    text = " ".join(item[1] for item in result) if result else "(空)"
    lines.append(f"{pdf.name} | pages={doc.page_count} | {text[:80]}")
    print(f"{pdf.name}: pages={doc.page_count}")
OUT.write_text("\n".join(lines), encoding="utf-8")
print("written:", OUT)
