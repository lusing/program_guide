"""把教程 Markdown 的 LaTeX 定界符从 \\(...\\)/\\[...\\] 迁移到 $...$/$$...$$。

settheory 版（比 probability 版多处理的脏形态）：
- 447 个跨行 \\(...\\)，续行常带 `> `（引用）或 3 空格（列表）前缀；
- 161 个独占行 \\[ \\] 显示块（35 个在 `> ` 引用里，正文行带 `> `）；
- 103 个单行 `\\[ ... \\]`；列表缩进的显示块改行内 `$...$`；
- \\] 后紧跟 」/∎/（…） 的三处长尾；
- 数学内的 `` `` ``（j``\\lambda 像集记号）不能被当成代码定界——
  扫描按位置定先后：\\( \\[ 与反引号各自吞掉自己的区间；
- 表格单元数学内的裸 | -> \\lvert...\\rvert / \\mid。

手工修正（迁移前已直接改正文）：102/104 的 \\(\\kappa$、99 的
$V=L[D]\\)$ 与游离 \\)、110/98 的跨行漏闭合。
"""
from __future__ import annotations

import argparse
import pathlib
import re
import sys

FENCE = ("```", "~~~")
BACKTICK_RUN = re.compile(r"`+")
QUOTE_PREFIX = re.compile(r"^(?:[ \t]*>[ \t]?)+")
PREFIX_ONLY = re.compile(r"^[ \t>]*$")
DISPLAY_OWN_LINE = re.compile(r"^\s*(?:>\s*)*\$\$\s*$")


def split_fences(text: str):
    """[(kind, chunk)]，fence 块原样保留。"""
    pieces = []
    kind = "prose"
    buf: list[str] = []
    for line in text.splitlines(keepends=True):
        is_fence = line.lstrip().startswith(FENCE)
        if is_fence and kind == "prose":
            pieces.append(("prose", "".join(buf)))
            kind, buf = "fence", [line]
        elif is_fence and kind == "fence":
            buf.append(line)
            pieces.append(("fence", "".join(buf)))
            kind, buf = "prose", []
        else:
            buf.append(line)
    pieces.append((kind, "".join(buf)))
    return pieces


def scan_regions(text: str):
    """扫描 prose：返回排序的 (start,end,kind)，kind∈code/inline/display。

    反引号代码段按 CommonMark 等长 run 配对；\\( \\)、\\[ \\] 按最近
    定界符配对。谁在前面谁吞区间——数学内的 `` `` 像集记号由此安全。
    """
    regions = []
    i, n = 0, len(text)
    while i < n:
        bt = BACKTICK_RUN.search(text, i)
        pos_inline = text.find(r"\(", i)
        pos_display = text.find(r"\[", i)
        candidates = []
        if bt:
            candidates.append((bt.start(), "backtick", bt.group(0)))
        if pos_inline != -1:
            candidates.append((pos_inline, "inline", None))
        if pos_display != -1:
            candidates.append((pos_display, "display", None))
        if not candidates:
            break
        pos, kind, extra = min(candidates, key=lambda x: x[0])
        i = pos
        if kind == "backtick":
            run = extra
            close = re.compile(run + r"(?!`)").search(text, i + len(run))
            if not close:
                i += len(run)
                continue
            regions.append((i, close.end(), "code"))
            i = close.end()
        else:
            close_delim = r"\)" if kind == "inline" else r"\]"
            j = text.find(close_delim, i + 2)
            if j == -1:
                i += 2
                continue
            regions.append((i, j + 2, kind))
            i = j + 2
    return regions


TABLE_SEPARATOR = re.compile(
    r"^\s*\|?\s*:?-+:?\s*(?:\|\s*:?-+:?\s*)*\|?\s*$"
)


def table_line_set(text: str) -> set[int]:
    """GFM 表格行：分隔线必须含 - 与 |（排除 --- 水平分隔线误伤）。"""
    lines = text.split("\n")
    rows = set()
    for i, line in enumerate(lines):
        if "|" in line and TABLE_SEPARATOR.match(line) and i > 0 and "|" in lines[i - 1]:
            j = i - 1
            while j >= 0 and "|" in lines[j]:
                rows.add(j)
                j -= 1
            j = i + 1
            while j < len(lines) and "|" in lines[j]:
                rows.add(j)
                j += 1
    return rows


def fix_table_pipes(body: str) -> str:
    protected = []

    def keep(m: re.Match) -> str:
        protected.append(m.group(0))
        return f"\x01{len(protected) - 1}\x01"

    body = re.sub(r"\\\|", keep, body)
    body = re.sub(r"\|([^|]*)\|", r"\\lvert \1\\rvert", body)
    body = body.replace("|", r"\mid ")
    return re.sub(r"\x01(\d+)\x01",
                  lambda m: protected[int(m.group(1))], body)


def normalize_body_lines(body: str, quote_mode: bool) -> list[str]:
    out = []
    for line in body.split("\n"):
        if quote_mode:
            line = QUOTE_PREFIX.sub("", line)
        out.append(line.strip())
    while out and not out[0]:
        out.pop(0)
    while out and not out[-1]:
        out.pop()
    if any(not line for line in out):
        raise ValueError("blank line inside display math: " + body[:60])
    return out


def join_inline_body(body: str) -> str:
    """跨行行内公式：首行原样，仅续行剥 `> `/空格前缀（孤立的 `>`
    是大于号，不能当引用标记吞掉）。"""
    raw = body.split("\n")
    parts = [raw[0].strip()]
    for line in raw[1:]:
        parts.append(QUOTE_PREFIX.sub("", line).strip())
    return " ".join(p for p in parts if p)


def render_inline_text(fragment: str, table_rows: set[int], line_no: int,
                       report: dict) -> str:
    """渲染同行片段里的代码段与行内数学（显示块长尾复用）。"""
    out = []
    cursor = 0
    for s, e, kind in scan_regions(fragment):
        out.append(re.sub(r"(?<!\\)\$", r"\\$", fragment[cursor:s]))
        if kind == "code":
            out.append(fragment[s:e])
        elif kind == "inline":
            joined = join_inline_body(fragment[s + 2:e - 2])
            if line_no in table_rows:
                joined = fix_table_pipes(joined)
            out.append(f"${joined}$")
            report["inline"] += 1
        else:
            out.append("$" + " ".join(normalize_body_lines(fragment[s + 2:e - 2], False)) + "$")
            report["display_inline_fallback"] += 1
        cursor = e
    out.append(re.sub(r"(?<!\\)\$", r"\\$", fragment[cursor:]))
    return "".join(out)


def transform_prose(text: str, report: dict) -> str:
    regions = scan_regions(text)
    table_rows = table_line_set(text)
    out: list[str] = []
    cursor = 0

    def esc_dollar(s: str) -> str:
        return re.sub(r"(?<!\\)\$", r"\\$", s)

    for s, e, kind in regions:
        if s < cursor:
            continue  # 已随上一个显示块的长尾一起渲染
        line_start = text.rfind("\n", 0, s) + 1
        line_end = text.find("\n", e)
        if line_end == -1:
            line_end = len(text)
        pre = text[line_start:s]
        tail = text[e:line_end]
        line_no = text.count("\n", 0, s)

        if kind == "code":
            out.append(esc_dollar(text[cursor:s]))
            out.append(text[s:e])
            cursor = e
            continue

        body = text[s + 2:e - 2]

        if kind == "inline":
            joined = join_inline_body(body)
            if "\n" in body:
                report["multiline_inline"] += 1
            if line_no in table_rows:
                fixed = fix_table_pipes(joined)
                if fixed != joined:
                    report["table_pipes"] += 1
                joined = fixed
            out.append(esc_dollar(text[cursor:s]))
            out.append(f"${joined}$")
            report["inline"] += 1
            cursor = e
            continue

        # display：把开标记行的引用/缩进前缀从 plain 尾部摘出自行重建
        head = text[cursor:line_start]
        prefix_only = bool(PREFIX_ONLY.match(pre))
        if not prefix_only:
            # \[ 前有正文（勘察为 0）：安全降级行内
            out.append(esc_dollar(text[cursor:s]))
            out.append("$" + " ".join(normalize_body_lines(body, False)) + "$")
            report["display_inline_fallback"] += 1
            cursor = e
            continue

        out.append(esc_dollar(head))
        quote_mode = ">" in pre
        indented = bool(pre) and not quote_mode
        parts = normalize_body_lines(body, quote_mode)

        # 块前空行
        assembled = "".join(out)
        last_line = assembled[assembled.rfind("\n") + 1:]
        if last_line.strip():
            out.append(">\n" if quote_mode else "\n")

        if indented:
            out.append(pre + "$" + " ".join(parts) + "$")
            report["indented_display"] += 1
        elif quote_mode:
            out.append("> $$\n")
            out.append("\n".join("> " + p for p in parts))
            out.append("\n> $$")
            report["display_quote"] += 1
        else:
            out.append("$$\n")
            out.append("\n".join(parts))
            out.append("\n$$")
            report["display_block"] += 1

        # 长尾：\] 后同行正文（」、∎、（余 \(…\) …）），递归渲染其中数学
        if tail.strip():
            rendered = render_inline_text(tail, table_rows, line_no, report)
            if quote_mode:
                out.append("\n> " + rendered.strip())
                out.append("\n>")
            else:
                out.append("\n" + rendered.lstrip())
            cursor = line_end
            continue

        # 块后空行：按 region 后一行是否仍是引用决定
        after_nl = text.find("\n", e)
        next_line = ""
        if after_nl != -1:
            nle = text.find("\n", after_nl + 1)
            next_line = text[after_nl + 1:nle if nle != -1 else len(text)]
        if next_line.strip():
            if quote_mode and next_line.lstrip().startswith(">"):
                out.append("\n>")
            else:
                out.append("\n")
        cursor = e

    out.append(esc_dollar(text[cursor:]))
    return "".join(out)


def migrate(text: str, report: dict) -> str:
    text = text.replace("\r\n", "\n")
    pieces = []
    for kind, chunk in split_fences(text):
        # 幂等：不含旧定界符的块原样返回（裸 $ 已在迁移前手工清零）
        if kind == "fence" or (r"\(" not in chunk and r"\[" not in chunk):
            pieces.append(chunk)
            continue
        pieces.append(transform_prose(chunk, report))
    result = "".join(pieces)
    if text.endswith("\n") and not result.endswith("\n"):
        result += "\n"
    return result


def validate(text: str) -> list[str]:
    """迁移后结构校验（数学与代码按位置争先，兼容数学内的 `` `` 记号）。"""
    # 围栏代码块整体挖空
    kept = []
    in_fence = False
    for line in text.split("\n"):
        if line.lstrip().startswith(FENCE):
            in_fence = not in_fence
            kept.append("")
            continue
        kept.append("" if in_fence else line)
    t = "\n".join(kept)

    errors = []
    i, n = 0, len(t)

    def check_plain(s: str):
        legacy = re.search(r"\\[()[\]]", s)
        if legacy:
            errors.append("legacy delimiter: " + s[max(0, legacy.start() - 20):legacy.start() + 30].replace("\n", "\\n"))
        stray = re.search(r"(?<!\\)\$", s)
        if stray:
            errors.append("stray $: " + s[max(0, stray.start() - 20):stray.start() + 30].replace("\n", "\\n"))

    while i < n:
        bt = BACKTICK_RUN.search(t, i)
        dd = t.find("$$", i)
        m = re.compile(r"(?<!\\)\$(?!\$)").search(t, i)
        candidates = [p for p in (
            (bt.start(), "bt") if bt else None,
            (dd, "dd") if dd != -1 else None,
            (m.start(), "d") if m else None,
        ) if p]
        if not candidates:
            check_plain(t[i:])
            break
        pos, kind = min(candidates, key=lambda x: x[0])
        check_plain(t[i:pos])  # 区间外普通文本不得有旧定界符或游离 $
        if kind == "bt":
            run = bt.group(0)
            close = re.compile(run + r"(?!`)").search(t, pos + len(run))
            i = close.end() if close else pos + len(run)
        elif kind == "dd":
            j = t.find("$$", pos + 2)
            if j == -1:
                errors.append("unclosed $$ at " + t[pos:pos + 40].replace("\n", "\\n"))
                break
            i = j + 2
        else:
            line_end = t.find("\n", pos)
            if line_end == -1:
                line_end = n
            j = re.compile(r"(?<!\\)\$").search(t, pos + 1, line_end)
            if not j:
                errors.append("unclosed inline $: " + t[pos:line_end][:50])
                i = line_end
            else:
                i = j.end()
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
        report = {"inline": 0, "multiline_inline": 0, "display_block": 0,
                  "display_quote": 0, "indented_display": 0, "table_pipes": 0,
                  "display_inline_fallback": 0}
        new = migrate(text, report)
        for k, v in report.items():
            totals[k] = totals.get(k, 0) + v
        if new != text.replace("\r\n", "\n"):
            errors = validate(new)
            if errors:
                print(f"[FAIL] {path.name}: {errors[:5]}")
                return 1
            path.write_text(new, encoding="utf-8", newline="\r\n" if crlf else "\n")
            print(f"[migrated] {path.name}: { {k: v for k, v in report.items() if v} }")
    print("totals:", totals)
    return 0


if __name__ == "__main__":
    sys.exit(main())
