# 抽取 Sahni 17 个分章 PDF 的文本层 → materials/sahni/NN.txt（UTF-8）
import pathlib
import fitz

SRC = pathlib.Path(r"G:\book\计算机\数据结构\数据结构算法与应用-C++语言描述")
OUT = pathlib.Path(__file__).resolve().parents[1] / "materials" / "sahni"
OUT.mkdir(parents=True, exist_ok=True)

for i in range(1, 18):
    doc = fitz.open(SRC / f"{i:03d}.PDF")
    text = "\n".join(page.get_text() for page in doc)
    (OUT / f"{i:02d}.txt").write_text(text, encoding="utf-8")
    print(f"{i:02d}: {len(text)} chars")
