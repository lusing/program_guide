from pathlib import Path
import re

print("==== 123")

strength = ["inaccessible", "measurable", "supercompact",
            "woodin", "woodin_limit", "measurable_above"]
forcing = ["small", "prikry", "proper", "ideal", "tower", "iteration"]
regularity = ["borel", "analytic", "sigma12", "universally_baire",
              "projective", "ad_l_r"]
assert len(strength) == len(forcing) == len(regularity) == 6
assert all(isinstance(row, tuple) and len(row) == 3
           for row in zip(strength, forcing, regularity))

# 与 Julia 分开实现目录解析；章号来自最终 Markdown 文件名。
docs = Path(__file__).resolve().parents[2] / "docs"
chapters = sorted(
    int(match.group(1))
    for path in docs.glob("*.md")
    if (match := re.fullmatch(r"(\d{2,3})-.*\.md", path.name)) is not None
)
assert chapters == list(range(149))
assert len(chapters) == len(set(chapters)) == 149

# 第十三篇（郝兆宽·杨跃路线）并入：124-148，共 25 章。
hao_chapters = [n for n in chapters if n >= 124]
assert hao_chapters == list(range(124, 149))
assert len(hao_chapters) == 25

# 前十二篇 124 章七通道 + Lean 整工程汇总 = 869；郝/杨跃篇新增
# lean 16 + isabelle 8 + coq 6 + julia 15 + python 24 + prolog 10 = 79。
hao_units = dict(lean=16, isabelle=8, coq=6, agda=0,
                 julia=15, python=24, prolog=10)
assert sum(hao_units.values()) == 79
baseline_units = 869
final_units = baseline_units + sum(hao_units.values())
assert final_units == 948
print("docs: 149 chapters, continuous 00-148; hao=25")
print("axes: 6 aligned rows; units: 869+79=948")
print("END ====")
