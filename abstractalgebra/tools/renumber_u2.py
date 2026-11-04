#!/usr/bin/env python
"""U2 重编号：插入新 27（行列式）后，旧 27-40 → 28-41 全库迁移。

改名（降序防覆盖）：docs/NN-slug.md、examples/{julia,python,prolog}/NN_slug.*、
examples/lean/Abstractalgebra/ChNNXxx.lean。
内容：==== NN 标记、Lean namespace、章号引用（第 NN 章 / NN 章 / 区间）、
示例文件名引用、docs 链接（[NN …](NN-slug.md)）、章内节号（## NN.M 与自引）。
单遍回调，无级联。00-intro 表 / 41-finale 地图 / PLAN / README 由人工跟进。
"""

import re
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
DOCS = ROOT / "docs"
EX = ROOT / "examples"

NMAP = {n: n + 1 for n in range(27, 41)}          # 27..40 -> 28..41

# 文件改名映射（旧 → 新），按新号降序执行
DOC_RENAMES = {
    "40-finale.md": "41-finale.md",
    "39-groebner.md": "40-groebner.md",
    "38-division.md": "39-division.md",
    "37-varieties.md": "38-varieties.md",
    "36-noetherian.md": "37-noetherian.md",
    "35-ufd.md": "36-ufd.md",
    "34-ideals.md": "35-ideals.md",
    "33-symmetry.md": "34-symmetry.md",
    "32-sylow.md": "33-sylow.md",
    "31-abelian-groups.md": "32-abelian-groups.md",
    "30-quintic.md": "31-quintic.md",
    "29-classical-formulas.md": "30-classical-formulas.md",
    "28-codes.md": "29-codes.md",
    "27-eigenvalues.md": "28-eigenvalues.md",
}
STEM_RENAMES = {
    "40_finale": "41_finale",  # 若存在
    "39_groebner": "40_groebner",
    "38_division": "39_division",
    "37_varieties": "38_varieties",
    "36_noetherian": "37_noetherian",
    "35_ufd": "36_ufd",
    "34_ideals": "35_ideals",
    "33_symmetry": "34_symmetry",
    "32_sylow": "33_sylow",
    "31_abelian_groups": "32_abelian_groups",
    "30_quintic": "31_quintic",
    "29_formulas": "30_formulas",
    "28_codes": "29_codes",
    "27_eigenvalues": "28_eigenvalues",
}
LEAN_RENAMES = {
    "Ch39Groebner.lean": "Ch40Groebner.lean",
    "Ch38Division.lean": "Ch39Division.lean",
    "Ch37Varieties.lean": "Ch38Varieties.lean",
    "Ch36Noetherian.lean": "Ch37Noetherian.lean",
    "Ch35Ufd.lean": "Ch36Ufd.lean",
    "Ch34Ideals.lean": "Ch35Ideals.lean",
    "Ch33Symmetry.lean": "Ch34Symmetry.lean",
    "Ch32Sylow.lean": "Ch33Sylow.lean",
    "Ch31AbelianGroups.lean": "Ch32AbelianGroups.lean",
    "Ch30Quintic.lean": "Ch31Quintic.lean",
    "Ch29Formulas.lean": "Ch30Formulas.lean",
    "Ch28Codes.lean": "Ch29Codes.lean",
    "Ch27Eigenvalues.lean": "Ch28Eigenvalues.lean",
}

RE_CH = re.compile(r"(第\s*)?(\d{2})\s*(?=\s*章)")
RE_RANGE = re.compile(r"(\d{2})(\s*[-–]\s*)(\d{2})(\s*章)")
RE_LINKFILE = re.compile(r"\((\d{2}-[a-z0-9-]+\.md)\)")
RE_LINKTEXT = re.compile(r"\[(\d{2})\s")
RE_EXREF = re.compile(r"(julia|python|prolog|lean)[/\\](Ch)?(\d{2})(?=[_A-Za-z])")


def bump(n: int) -> str:
    return "%02d" % NMAP.get(int(n), int(n))


def rewrite_text(src: str, own: int | None) -> str:
    out = src

    def ch_sub(m):
        n = int(m.group(2))
        if n in NMAP:
            return (m.group(1) or "") + "%02d" % (n + 1)
        return m.group(0)

    out = RE_CH.sub(ch_sub, out)

    def range_sub(m):
        a, mid, b, tail = int(m.group(1)), m.group(2), int(m.group(3)), m.group(4)
        a2 = a + 1 if a in NMAP else a
        b2 = b + 1 if b in NMAP else b
        return "%02d%s%02d%s" % (a2, mid, b2, tail)

    out = RE_RANGE.sub(range_sub, out)

    def linkfile_sub(m):
        name = m.group(1)
        return "(" + DOC_RENAMES.get(name, name) + ")"

    out = RE_LINKFILE.sub(linkfile_sub, out)

    def linktext_sub(m):
        n = int(m.group(1))
        if n in NMAP:
            return "[%02d " % (n + 1)
        return m.group(0)

    out = RE_LINKTEXT.sub(linktext_sub, out)

    def exref_sub(m):
        n = int(m.group(3))
        if n in NMAP:
            return m.group(1) + "/" + (m.group(2) or "") + "%02d" % (n + 1)
        return m.group(0)

    out = RE_EXREF.sub(exref_sub, out)

    if own is not None and own in NMAP:                     # 章内节号与标题
        new = own + 1
        out = re.sub(r"^(# )%02d( )" % own, r"\g<1>%02d\g<2>" % new, out, flags=re.M)
        out = re.sub(r"^(## )%02d\." % own, r"\g<1>%02d." % new, out, flags=re.M)
        out = re.sub(r"(?<![\d.])%02d\.(\d)" % own, "%02d.\\g<1>" % new, out)
    return out


def main() -> None:
    # 1) 改名（docs）
    for old, new in sorted(DOC_RENAMES.items(), key=lambda kv: -int(kv[0][:2])):
        p = DOCS / old
        if p.exists():
            p.rename(DOCS / new)
    # 2) 改名（三通道 + lean）
    for sub in ("julia", "python", "prolog"):
        d = EX / sub
        items = sorted(STEM_RENAMES.items(), key=lambda kv: -int(kv[0][:2]))
        for old, new in items:
            for ext in (".jl", ".py", ".pl"):
                p = d / (old + ext)
                if p.exists():
                    p.rename(d / (new + ext))
    ld = EX / "lean" / "Abstractalgebra"
    for old, new in sorted(LEAN_RENAMES.items(), key=lambda kv: -int(kv[0][2:4])):
        p = ld / old
        if p.exists():
            p.rename(ld / new)

    # 3) 内容改写：示例文件（标记 + namespace + 章号）
    for sub in ("julia", "python", "prolog"):
        for f in sorted((EX / sub).glob("[0-9][0-9]_*.?*")):
            if f.suffix not in (".jl", ".py", ".pl"):
                continue
            src = f.read_text(encoding="utf-8")
            own = int(f.name[:2])
            out = rewrite_text(src, own)
            if own in NMAP:                                  # ==== NN 标记
                out = out.replace("==== %02d" % own, "==== %02d" % (own + 1))
            if out != src:
                f.write_text(out, encoding="utf-8")
    for f in sorted(ld.glob("Ch*.lean")):
        src = f.read_text(encoding="utf-8")
        own = int(f.name[2:4])
        out = rewrite_text(src, own)
        if own in NMAP:                                      # namespace 与 import 自身
            out = re.sub(r"(namespace Abstractalgebra\.Ch)%02d" % own, r"\g<1>%02d" % (own + 1), out)
        if out != src:
            f.write_text(out, encoding="utf-8")

    # 4) docs 全部改写
    for f in sorted(DOCS.glob("*.md")):
        src = f.read_text(encoding="utf-8")
        own = int(f.name[:2])
        out = rewrite_text(src, own)
        if out != src:
            f.write_text(out, encoding="utf-8")

    # 5) 根模块：替换 import 名并插入 Ch27Determinants
    rootmod = EX / "lean" / "Abstractalgebra.lean"
    src = rootmod.read_text(encoding="utf-8")
    for old, new in sorted(LEAN_RENAMES.items(), key=lambda kv: int(kv[0][2:4])):
        src = src.replace("import Abstractalgebra." + old[2:-5],
                          "import Abstractalgebra." + new[2:-5])
    src = src.replace("import Abstractalgebra.Ch26LinearMaps",
                      "import Abstractalgebra.Ch26LinearMaps\nimport Abstractalgebra.Ch27Determinants")
    rootmod.write_text(src, encoding="utf-8")
    print("renumber done")


if __name__ == "__main__":
    main()
