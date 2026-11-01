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
assert chapters == list(range(124))
assert len(chapters) == len(set(chapters)) == 124

expected_new = list(range(79, 84)) + list(range(93, 123))
actual_new = [n for n in chapters if n in set(expected_new)]
assert actual_new == expected_new
assert len(actual_new) == 35

baseline_units = 624
channels = 7
final_units = baseline_units + len(actual_new) * channels
assert final_units == 869
assert final_units == len(chapters) * channels + 1
print("docs: 124 chapters, continuous 00-123; new=35")
print("axes: 6 aligned rows; units: 624+35*7=869")
print("END ====")
