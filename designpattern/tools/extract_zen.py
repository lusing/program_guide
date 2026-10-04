# 之禅 epub：EPUB/*.xhtml 按数值序去标签 → materials/zen/NNN.txt
import pathlib
import re
import zipfile

SRC = r"G:\book\计算机\设计模式\设计模式之禅（第2版）.epub"
OUT = pathlib.Path(__file__).resolve().parents[1] / "materials" / "zen"
OUT.mkdir(parents=True, exist_ok=True)

with zipfile.ZipFile(SRC) as z:
    names = [n for n in z.namelist() if n.startswith("EPUB/") and n.endswith(".xhtml")]

    def order(n: str) -> tuple[int, str]:
        stem = pathlib.Path(n).stem
        return (0, "") if not stem.isdigit() else (1, f"{int(stem):0>5}")

    names.sort(key=order)
    for n in names:
        raw = z.read(n).decode("utf-8")
        raw = re.sub(r"<[^>]+>", "\n", raw)
        raw = re.sub(r"\n{2,}", "\n", raw)
        out = OUT / f"{pathlib.Path(n).stem:0>3}.txt"
        out.write_text(raw, encoding="utf-8")
        print(f"{out.name}: {len(raw)} chars")
