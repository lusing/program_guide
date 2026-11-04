"""修补 Gitea/Forgejo 行内数学邻接规则：在违规的定界符旁补空格。

规则（forgejo modules/markup/markdown/math/inline_parser.go）：
- 开 $ 前一个字符是 ASCII 字母数字或 .!?,;: → 不认 → 在开 $ 前补空格
- 闭 $ 后一个字符必须是 空格/换行/)/./!/?/,/;/: 或行尾 → 在闭 $ 后补空格
- 闭 $ 后接 *（强调符）由人工处理，本脚本只报告

扫描按 CommonMark 分块（空行为界），块内 反引号代码段 > $ 按位置争先；
围栏代码块与独占行 $$（含 > 前缀）整体挖空。幂等。
"""
from __future__ import annotations

import argparse
import pathlib
import re

BACKTICK_RUN = re.compile(r"`+")
DISPLAY_LINE = re.compile(r"^\s*(?:>\s*)*\$\$")  # 单行 $$…$$ 或独占行 $$
OPEN_BAD = re.compile(r"[a-zA-Z0-9.!?,;:]")
CLOSE_OK = frozenset(" \n).!?,;:")


def mask(text: str) -> str:
    """围栏块与展示公式行（$$ 开头，含 > 前缀）等长挖空（位置对齐）。"""
    out, in_fence = [], False
    for line in text.split("\n"):
        if line.lstrip().startswith(("```", "~~~")):
            in_fence = not in_fence
            out.append(" " * len(line))
            continue
        if in_fence or DISPLAY_LINE.match(line):
            out.append(" " * len(line))
        else:
            out.append(line)
    return "\n".join(out)


def spans(t: str):
    """分块扫描行内 $…$，产出 (open, close_end, prev, nxt)。"""
    out = []

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
            prev = t[pos - 1] if pos > 0 else "\n"
            nxt = t[c.end()] if c.end() < len(t) else "\n"
            out.append((pos, c.end(), prev, nxt))
            i = c.end()

    for block in re.finditer(r"\S(?:[^\n]|\n(?!\n))*(?=\n\n|\n?$)", t):
        scan(block.start(), block.end())
    return out


def fix_text(text: str) -> tuple[str, dict, list]:
    """返回 (新文本, 统计, 需人工处理的 * 案例行号)。"""
    t = mask(text)
    inserts = []  # (pos, "before"/"after") 补空格位置
    stats = {"close_space": 0, "open_space": 0}
    manual = []
    for pos, end, prev, nxt in spans(t):
        if nxt not in CLOSE_OK:
            if nxt in "*_":
                manual.append(text.count("\n", 0, pos) + 1)
            else:
                inserts.append(end)
                stats["close_space"] += 1
        if OPEN_BAD.match(prev):
            inserts.append(pos)
            stats["open_space"] += 1
    for p in sorted(set(inserts), reverse=True):
        text = text[:p] + " " + text[p:]
    return text, stats, sorted(set(manual))


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", type=pathlib.Path, required=True)
    args = ap.parse_args()
    files = sorted((args.root / "docs").glob("*.md"))
    readme = args.root / "README.md"
    if readme.exists():
        files.append(readme)
    totals = {"close_space": 0, "open_space": 0}
    for path in files:
        raw = path.read_bytes()
        crlf = b"\r\n" in raw
        text = raw.decode("utf-8")
        new, stats, manual = fix_text(text.replace("\r\n", "\n"))
        if any(stats.values()):
            print(f"[fixed] {path.name}: {stats}")
            for k, v in stats.items():
                totals[k] += v
        if manual:
            print(f"[manual] {path.name} 行: {manual}")
        if new != text.replace("\r\n", "\n"):
            path.write_text(new, encoding="utf-8", newline="\r\n" if crlf else "\n")
    print("totals:", totals)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
