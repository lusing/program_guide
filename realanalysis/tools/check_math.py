"""回归检查：docs/*.md 与 README.md 不得再出现 \\( \\) \\[ \\] 旧定界符，
$…$/$$…$$ 必须闭合，且行内公式邻接须满足 Forgejo/Gitea 规则
（开 $ 前不得是 ASCII 字母数字或 .!?,;:；闭 $ 后必须是
空格/换行/)/./!/?/,/;/: 或行尾——否则 Codeberg 上公式原样露出）。

结构校验复用迁移器的 validate（围栏、行内代码、数学内 `` 像集记号
均已兼容）。用法：python tools/check_math.py"""
from __future__ import annotations

import pathlib
import re
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from migrate_math_delimiters import validate  # noqa: E402

ROOT = pathlib.Path(__file__).resolve().parents[1]

BACKTICK_RUN = re.compile(r"`+")
DISPLAY_ONE_LINE = re.compile(r"^\s*(?:>\s*)*\$\$.+\$\$\s*$")
DISPLAY_OWN_LINE = re.compile(r"^\s*(?:>\s*)*\$\$\s*$")
OPEN_BAD = re.compile(r"[a-zA-Z0-9.!?,;:]")
CLOSE_OK = frozenset(" \n).!?,;:")


def _mask(text: str) -> str:
    """围栏块与单行展示公式 $$…$$ 等长挖空（位置对齐）。"""
    out, in_fence = [], False
    for line in text.split("\n"):
        if line.lstrip().startswith(("```", "~~~")):
            in_fence = not in_fence
            out.append(" " * len(line))
            continue
        out.append(" " * len(line) if in_fence or DISPLAY_ONE_LINE.match(line) else line)
    return "\n".join(out)


def check_adjacency(text: str) -> list[str]:
    """分块（空行为界）扫描行内 $…$，校验开/闭定界符的邻接字符；
    独占行 $$（多行展示块）判错——Codeberg 只渲染单行 $$…$$。"""
    t = _mask(text)
    errors: list[str] = []
    in_fence = False
    for no, line in enumerate(text.split("\n"), 1):
        if line.lstrip().startswith(("```", "~~~")):
            in_fence = not in_fence
            continue
        if not in_fence and DISPLAY_OWN_LINE.match(line):
            errors.append(f"{no}: display math must be single-line $$...$$")

    def scan(lo: int, hi: int):
        i = lo
        while i < hi:
            bt = BACKTICK_RUN.search(t, i, hi)
            m = re.compile(r"(?<!\\)\$(?!\$)").search(t, i, hi)
            cands = [p for p in ((bt.start(), "bt") if bt else None,
                                 (m.start(), "d") if m else None) if p]
            if not cands:
                break
            pos, kind = min(cands, key=lambda x: x[0])
            if kind == "bt":
                run = bt.group(0)
                close = re.compile(re.escape(run) + r"(?!`)").search(t, pos + len(run), hi)
                i = close.end() if close else pos + len(run)
                continue
            line_end = t.find("\n", pos, hi)
            if line_end == -1:
                line_end = hi
            c = re.compile(r"(?<!\\)\$(?!\$)").search(t, pos + 1, line_end)
            if not c:
                i = line_end
                continue
            line_no = text.count("\n", 0, pos) + 1
            prev = t[pos - 1] if pos > 0 else "\n"
            nxt = t[c.end()] if c.end() < len(t) else "\n"
            if OPEN_BAD.match(prev):
                errors.append(f"{line_no}: char before opening $ breaks Forgejo math")
            if nxt not in CLOSE_OK:
                errors.append(f"{line_no}: char after closing $ breaks Forgejo math")
            i = c.end()

    for block in re.finditer(r"\S(?:[^\n]|\n(?!\n))*(?=\n\n|\n?$)", t):
        scan(block.start(), block.end())
    return errors


def main() -> int:
    files = sorted((ROOT / "docs").glob("*.md"))
    readme = ROOT / "README.md"
    if readme.exists():
        files.append(readme)
    bad = 0
    for path in files:
        text = path.read_text(encoding="utf-8").replace("\r\n", "\n")
        errors = validate(text) + check_adjacency(text)
        if errors:
            bad += 1
            for e in errors[:3]:
                print(f"[FAIL] {path.name}: {e}")
    if bad:
        print(f"{bad} file(s) with math problems")
        return 1
    print(f"math: PASS ({len(files)} files)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
