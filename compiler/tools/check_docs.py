#!/usr/bin/env python
# 每篇 docs：≥200 行；src/、TIP.g4、expected 文本全部以标记代码块嵌入且字节一致
import pathlib, re

ROOT = pathlib.Path(__file__).resolve().parents[1]
FENCE = re.compile(r"```([A-Za-z0-9_]*)\n(.*?)\n```", re.S)
MARK = re.compile(r"^(// file: |; expected: )(.+)$")

def check(doc):
    text = doc.read_text(encoding="utf-8")
    assert len(text.splitlines()) >= 200, f"{doc.name}: 不足 200 行"
    # docs/NN-slug → examples/NN_slug（slug 内连字符也转下划线）
    num, slug = doc.stem.split("-", 1)
    ex = ROOT / "examples" / f"{num}_{slug.replace('-', '_')}"
    seen = set()
    for lang, body in FENCE.findall(text):
        first, *rest = body.split("\n")
        m = MARK.match(first)
        if not m:
            continue
        target = ex / m.group(2)
        content = "\n".join(rest)
        assert target.is_file(), f"{doc.name}: 标记文件不存在 {target}"
        assert content == target.read_text(encoding="utf-8").rstrip("\n"), \
               f"{doc.name}: 代码块与 {target} 不一致"
        seen.add(target)
    if ex.is_dir():
        want = set()
        if (ex / "src").is_dir():
            want.update(p for p in (ex / "src").rglob("*") if p.is_file())
        if (ex / "TIP.g4").is_file():
            want.add(ex / "TIP.g4")
        if (ex / "expected").is_dir():
            want.update(p for p in (ex / "expected").rglob("*.txt") if p.is_file())
        missing = want - seen
        assert not missing, f"{doc.name}: 未嵌入 {[str(m.relative_to(ex)) for m in missing]}"
    print(f"[docs {doc.name} OK]")

docs = sorted((ROOT / "docs").glob("*.md"))
for d in docs:
    check(d)
print(f"[check_docs: {len(docs)} chapters]")
