"""把教程 Markdown 的 LaTeX 定界符从 \\(...\\)/\\[...\\] 迁移到 $...$/$$...$$。

背景：Codeberg(Forgejo)/GitHub/VS Code 内置预览的数学渲染只认
$...$ 与 $$...$$，\\(...\\)、\\[...\\] 会原样露出反斜杠。

迁移规则（在围栏代码块与行内代码之外）：
1. 列 0 的 \\[ / \\] 独占行（含误写的 \\\\]）-> $$，并保证上下空行；
2. 列表项内缩进的单行展示块 -> 同缩进的行内 $...$；
3. \\(...\\) -> $...$；跨行对合并为同一行（库中仅 1 处）；
4. 表格单元数学中的裸 | -> \\lvert...\\rvert（绝对值）或 \\mid（条件）；
5. 正文中既有的裸 $（货币）转义为 \\$；
6. 43 章代码段误写的 `\\((1/3)=0\\)` 修为 `(1/3)=0`。

幂等：文件若已无旧定界符，只有"裸 $"需要处理时才改动。
也可用于其他教程：python migrate_math_delimiters.py --root <dir>
"""
from __future__ import annotations

import argparse
import pathlib
import re
import sys

FENCE = ("```", "~~~")
DISPLAY_OPEN = re.compile(r"^\\\[\s*$")
DISPLAY_CLOSE = re.compile(r"^\\+\]\s*$")
INDENTED_OPEN = re.compile(r"^(?P<indent>[ \t]+)\\\[\s*$")
INDENTED_CLOSE = re.compile(r"^(?P<indent>[ \t]+)\\+\]\s*$")
INLINE_PAIR = re.compile(r"\\\((.*?)\\\)", re.S)
CODE_SPAN = re.compile(r"`+[^`\n]*`+")
TABLE_SEP = re.compile(r"\s*\|?[\s:|-]+\|?\s*$")

# 迁移前手工修正：行内代码里误入的 LaTeX 定界符
MANUAL_FIXES = {
    r"`\((1/3)=0\)`": "`(1/3)=0`",
}


def split_segments(text: str):
    """按围栏代码块切成 ['prose'|'fence', chunk]。"""
    segments: list[tuple[str, list[str]]] = []
    kind = "prose"
    current: list[str] = []
    for line in text.splitlines():
        is_fence = line.lstrip().startswith(FENCE)
        if is_fence and kind == "prose":
            segments.append((kind, current))
            kind, current = "fence", [line]
        elif is_fence and kind == "fence":
            current.append(line)
            segments.append((kind, current))
            kind, current = "prose", []
        else:
            current.append(line)
    segments.append((kind, current))
    return segments


def table_row_indices(lines: list[str]) -> set[int]:
    """识别表格行（分隔线上下连续含 | 的行）。"""
    rows = set()
    for i, line in enumerate(lines):
        if TABLE_SEP.match(line) and i > 0 and "|" in lines[i - 1]:
            j = i - 1
            while j >= 0 and "|" in lines[j] and not lines[j].lstrip().startswith(FENCE):
                rows.add(j)
                j -= 1
            j = i + 1
            while j < len(lines) and "|" in lines[j] and not lines[j].lstrip().startswith(FENCE):
                rows.add(j)
                j += 1
    return rows


def fix_table_pipes(span: str) -> str:
    """表格单元数学内：成对待 |x| -> \\lvert x\\rvert，单 | -> \\mid。"""
    protected = []

    def keep(m: re.Match) -> str:
        protected.append(m.group(0))
        return f"\x01{len(protected) - 1}\x01"

    span = re.sub(r"\\\|", keep, span)  # \| 记号（范数等）原样保留
    span = re.sub(r"\|([^|]*)\|", r"\\lvert \1\\rvert", span)
    span = span.replace("|", r"\mid ")  # 尾随空格分开控制词与后继字母（数学模式忽略空格）

    def restore(m: re.Match) -> str:
        return protected[int(m.group(1))]
    return re.sub(r"\x01(\d+)\x01", restore, span)


def transform_prose(lines: list[str], report: dict) -> list[str]:
    table_rows = table_row_indices(lines)
    placeholders: list[str] = []

    def protect(m: re.Match) -> str:
        placeholders.append(m.group(0))
        return f"\x00{len(placeholders) - 1}\x00"

    stage: list[str] = []
    i = 0
    while i < len(lines):
        line = lines[i]

        # 规则 6：手工修正
        for old, new in MANUAL_FIXES.items():
            if old in line:
                line = line.replace(old, new)
                report["manual_fixes"] += 1

        # 保护行内代码
        line = CODE_SPAN.sub(protect, line)

        # 规则 2：列表项内缩进的单行展示块
        m = INDENTED_OPEN.match(line)
        if m:
            indent = m.group("indent")
            if i + 2 >= len(lines):
                raise ValueError(f"indented display block truncated near line {i + 1}")
            body = lines[i + 1]
            close = lines[i + 2]
            cm = INDENTED_CLOSE.match(close)
            if not cm or cm.group("indent") != indent or not body.startswith(indent):
                raise ValueError(f"unexpected indented display block at line {i + 1}")
            inner = body[len(indent):].strip()
            stage.append(f"{indent}${inner}$")
            report["indented_display"] += 1
            i += 3
            continue

        # 规则 1：列 0 展示定界符（含 \\\] 误写）
        if DISPLAY_OPEN.match(line) or DISPLAY_CLOSE.match(line):
            if DISPLAY_CLOSE.match(line) and not line.startswith(r"\]"):
                report["weird_close"] += 1
            stage.append("$$")
            report["display_marker"] += 1
            i += 1
            continue

        # 规则 4：表格行内数学的裸 |
        if i in table_rows and r"\(" in line:
            def per_span(mm: re.Match) -> str:
                fixed = fix_table_pipes(mm.group(0))
                if fixed != mm.group(0):
                    report["table_pipes"] += 1
                return fixed
            line = re.sub(r"\\\((?:(?!\\\)).)*?\\\)", per_span, line)

        # 规则 5：既有裸 $ 转义（此时数学 $ 尚未注入；\$ 不重复转义）
        if "$" in line:
            new_line = re.sub(r"(?<!\\)\$", r"\\$", line)
            report["escaped_dollar"] += new_line.count(r"\$") - line.count(r"\$")
            line = new_line

        stage.append(line)
        i += 1

    text = "\n".join(stage)

    # 规则 3：行内（含跨行）\(...\) -> $...$
    def inline_repl(m: re.Match) -> str:
        body = m.group(1)
        if "\n" in body:
            if "\n\n" in body:
                raise ValueError("inline math spans a blank line: " + m.group(0)[:60])
            body = "".join(part.strip() for part in body.splitlines())
            report["multiline_inline"] += 1
        report["inline"] += 1
        return f"${body}$"

    text = INLINE_PAIR.sub(inline_repl, text)

    # 列 0 $$ 块外补空行：开标记之前、闭标记之后；标记与公式体之间绝不插
    out: list[str] = []
    lines2 = text.split("\n")
    inside_display = False
    for idx, line in enumerate(lines2):
        if line == "$$":
            if not inside_display:
                if out and out[-1] != "":
                    out.append("")
                out.append(line)
                inside_display = True
            else:
                out.append(line)
                inside_display = False
                if idx + 1 < len(lines2) and lines2[idx + 1] != "":
                    out.append("")
        else:
            out.append(line)

    # 还原行内代码
    def restore(m: re.Match) -> str:
        return placeholders[int(m.group(1))]
    text = "\n".join(out)
    text = re.sub(r"\x00(\d+)\x00", restore, text)
    return text


INLINE_MATH_EXISTING = re.compile(r"(?<!\$)\$[^\n$]+\$")


def migrate(text: str, report: dict) -> str:
    has_legacy = bool(re.search(r"\\[()[\]]", text))
    has_math = "$$" in text or bool(INLINE_MATH_EXISTING.search(text))
    pieces: list[str] = []
    for kind, seg_lines in split_segments(text):
        if kind == "fence":
            pieces.append("\n".join(seg_lines))
            continue
        seg = "\n".join(seg_lines)
        if has_legacy:
            # 含旧定界符：全量迁移（行内裸 $ 先于数学 $ 注入被转义）
            pieces.append(transform_prose(seg_lines, report))
        elif "$" in seg and not has_math:
            # 幂等补救：从未迁移、也没有数学 $ 的文件（旧版残留章），
            # 仅转义货币等裸 $（行内代码原样保护）
            stored: list[str] = []

            def protect(m: re.Match) -> str:
                stored.append(m.group(0))
                return f"\x00{len(stored) - 1}\x00"

            def restore(m: re.Match) -> str:
                return stored[int(m.group(1))]

            fixed = "\n".join(
                re.sub(r"(?<!\\)\$", r"\\$", CODE_SPAN.sub(protect, line))
                for line in seg.split("\n")
            )
            fixed = re.sub(r"\x00(\d+)\x00", restore, fixed)
            report["escaped_dollar"] += fixed.count(r"\$") - seg.count(r"\$")
            pieces.append(fixed)
        else:
            pieces.append(seg)
    result = "\n".join(pieces)
    if text.endswith("\n") and not result.endswith("\n"):
        result += "\n"
    return result


def validate(text: str) -> list[str]:
    """迁移后结构校验：代码之外不得残留旧定界符，$ 必须配对。"""
    errors: list[str] = []
    in_fence = False
    dollar_count = 0
    display_count = 0
    for line in text.splitlines():
        if line.lstrip().startswith(FENCE):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        bare = CODE_SPAN.sub("", line)
        if re.search(r"\\[()[\]]", bare):
            errors.append("legacy delimiter: " + line[:60])
        display_count += bare.count("$$")
        dollar_count += len(re.findall(r"(?<!\\)\$(?!\$)", bare))
    if display_count % 2:
        errors.append("unbalanced $$ display fences")
    if dollar_count % 2:
        errors.append("unbalanced $ inline delimiters")
    return errors


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", type=pathlib.Path,
                    default=pathlib.Path(__file__).resolve().parents[1])
    args = ap.parse_args()
    files = sorted((args.root / "docs").glob("*.md"))
    readme = args.root / "README.md"
    if readme.exists():
        files.append(readme)

    totals: dict[str, int] = {}
    for path in files:
        raw = path.read_bytes()
        crlf = b"\r\n" in raw
        text = raw.decode("utf-8")
        report: dict = {
            "inline": 0, "display_marker": 0, "indented_display": 0,
            "multiline_inline": 0, "table_pipes": 0, "escaped_dollar": 0,
            "weird_close": 0, "manual_fixes": 0,
        }
        new = migrate(text, report)
        changed = new != text.replace("\r\n", "\n")
        for key, val in report.items():
            totals[key] = totals.get(key, 0) + val
        if changed:
            errors = validate(new)
            if errors:
                print(f"[FAIL] {path.name}: {errors}")
                return 1
            path.write_text(new, encoding="utf-8", newline="\r\n" if crlf else "\n")
            print(f"[migrated] {path.name}: { {k: v for k, v in report.items() if v} }")
    print("totals:", totals)
    return 0


if __name__ == "__main__":
    sys.exit(main())
