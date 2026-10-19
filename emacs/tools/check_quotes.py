#!/usr/bin/env python3
"""检查文档里引用的 elisp 代码块是否真的来自对应示例源码。

判定方式（词法单元级，容忍折行与注释差异）：

  1. 把文档代码块和示例源码都切成 token（括号/引号/字符串/符号各自成 token，
     丢掉 ; 注释）；
  2. 先把整个块的 token 序列拿去示例里做「连续子串」匹配，命中即通过；
  3. 否则按「顶层 form」切开（深度归 0 处断开，块里的 `...` 也断开），
     要求每一个顶层 form 都能在示例里连续找到；
  4. 一个 form 都找不到才报 QUOTE-MISS。

这样：
  - 文档把长行重新折行、加注释、空行分段 —— 都不影响判定（只看 token 序列）；
  - 文档从大段代码里截几行 —— 顶层 form 匹配能覆盖；
  - 凭记忆写代码、张冠李戴引用别章的代码 —— 照样抓得出来。

用法：python3 tools/check_quotes.py [--chapter NN]
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DOCS = ROOT / "docs" / "extending-emacs"
EXAMPLES = ROOT / "examples"

TOKEN_RE = re.compile(
    r'"(?:\\.|[^"\\])*"'      # 字符串
    r'|;[^\n]*'               # 行注释（后面丢掉）
    r'|,@|[][()\'`,]'         # 括号 / 引号 / 反引号 / 逗号
    r'|[^\s()\[\]\'",;`]+'    # 符号、数字、字符字面量等
)


def _unescape(s: str) -> str:
    """把字符串字面量里的 \\n \\t \\" \\\\ 还原成真实字符。"""
    out = []
    i = 0
    while i < len(s):
        c = s[i]
        if c == "\\" and i + 1 < len(s):
            nxt = s[i + 1]
            out.append({"n": "\n", "t": " ", '"': '"', "\\": "\\"}.get(nxt, nxt))
            i += 2
            continue
        out.append(c)
        i += 1
    return "".join(out)


def tokenize(text: str, splice: bool = False):
    """切 token，丢弃行注释。

    splice=True 时，字符串字面量**额外**展开：把它的内容也切成 token 附在后面。
    因为示例常常把「另一个文件的源码」当字符串写进去（第 24 章造模块文件、
    第 29 章之后贴 Emacs 源码都是这样），文档引用这些代码时应该算命中。
    主判定走 splice=False（更严格），只有失败时才退到 splice=True。
    """
    out = []
    for m in TOKEN_RE.finditer(text):
        tok = m.group(0)
        if tok.startswith(";"):
            continue
        out.append(tok)
        if splice and tok.startswith('"'):
            out.extend(tokenize(_unescape(tok[1:-1]), splice))
    return out


QUOTE_TOKENS = ("'", "`", ",", ",@")


def split_top_level(tokens):
    """按顶层 form 切开。

    断句规则（在 token 层面判断，与折行无关）：
      - `...` 是显式断点（文档里表示省略）；
      - 深度归 0 且刚闭合一个括号 → 断；
      - 深度归 0 且下一个 token 是关键字 `:xxx` → 断（处理 `:type 'integer`
        这类「关键字 + 值」连写）；
      - 引号 token（' ` , ,@）和关键字 token 后面必须跟值，不在其后断句。
    """
    forms = []
    cur = []
    depth = 0
    expect_value = False
    for i, tok in enumerate(tokens):
        if tok == "...":
            if cur:
                forms.append(cur)
                cur = []
            depth = 0
            expect_value = False
            continue
        if tok == "(":
            depth += 1
        elif tok == ")":
            depth -= 1
        cur.append(tok)
        if tok in QUOTE_TOKENS or tok.startswith(":"):
            expect_value = True
            continue
        expect_value = False
        if depth > 0:
            continue
        if tok == ")":
            forms.append(cur)
            cur = []
            continue
        nxt = tokens[i + 1] if i + 1 < len(tokens) else None
        if nxt is not None and nxt.startswith(":"):
            forms.append(cur)
            cur = []
    if cur:
        forms.append(cur)
    return [f for f in forms if f]


def contains_seq(hay, needle, slack: int = 3) -> bool:
    """needle 是否在 hay 里出现。

    先做**连续**匹配；失败再退到「允许省略」的子序列匹配 —— 文档常常省掉
    docstring、某个可选参数或中间某句，内容仍然逐字来自示例。
    为了避免子序列判据过松，限定匹配窗口不超过 needle 长度的 slack 倍 + 5。
    """
    n = len(needle)
    if n == 0 or n > len(hay):
        return False
    first = needle[0]
    for i in range(len(hay) - n + 1):
        if hay[i] == first and hay[i : i + n] == needle:
            return True
    window = slack * n + 5
    for i in range(len(hay)):
        if hay[i] != first:
            continue
        j = i
        k = 0
        while j < len(hay) and k < n and j - i < window:
            if hay[j] == needle[k]:
                k += 1
            j += 1
        if k == n:
            return True
    return False


def extract_elisp_blocks(md: str):
    """提取 ```elisp 代码块，返回 (起始行号, 块文本) 列表。"""
    blocks = []
    pattern = re.compile(r"```elisp\n(.*?)```", re.DOTALL)
    for m in pattern.finditer(md):
        line_no = md[: m.start()].count("\n") + 1
        blocks.append((line_no, m.group(1)))
    return blocks


ARROW_RE = re.compile(r";\s*(?:→|->)")


def is_api_reference_block(block: str) -> bool:
    """判断一个 elisp 块是不是「API 速查」而不是示例代码引用。

    判定：块里多数非空行带「; → 结果」断言，或所有注释都是 ;; 形式的
    正误对照 Illustration。这类块是自包含的文档（结果就写在旁边），
    不要求出现在示例源码里 —— 其正确性由 check_arrows.py 负责。
    """
    lines = [l for l in block.splitlines() if l.strip()]
    if not lines:
        return False
    arrow_lines = sum(1 for l in lines if ARROW_RE.search(l))
    if arrow_lines * 2 >= len(lines):
        return True
    comment_markers = re.findall(r";+\s", block)
    if comment_markers and all(m.startswith(";;") for m in comment_markers):
        return True
    return False


def chapter_docs(chapter):
    if chapter:
        return sorted(DOCS.glob(f"{chapter}-*.md"))
    return sorted(DOCS.glob("*.md"))


def main() -> int:
    chapter = None
    args = sys.argv[1:]
    if args and args[0] == "--chapter":
        chapter = args[1]
        if not chapter.isdigit():
            print(f"章节号必须是数字: {chapter}")
            return 2
        chapter = chapter.zfill(2)

    total_missing = 0
    for doc_path in chapter_docs(chapter):
        m = re.match(r"(\d+)-", doc_path.name)
        if not m:
            continue
        ex_path = EXAMPLES / f"{m.group(1)}-{doc_path.stem.split('-', 1)[1]}.el"
        if not ex_path.exists():
            print(f"[{doc_path.name}] 找不到示例 {ex_path.name}")
            continue
        ex_src = ex_path.read_text(encoding="utf-8")
        ex_plain = tokenize(ex_src)
        ex_spliced = tokenize(ex_src, splice=True)
        md = doc_path.read_text(encoding="utf-8")
        for line_no, block in extract_elisp_blocks(md):
            if is_api_reference_block(block):
                continue
            blk_plain = tokenize(block)
            if not blk_plain:
                continue
            if contains_seq(ex_plain, blk_plain):
                continue
            blk_spliced = tokenize(block, splice=True)
            if contains_seq(ex_spliced, blk_spliced):
                continue
            for form in split_top_level(blk_plain):
                if contains_seq(ex_plain, form):
                    continue
                if contains_seq(ex_spliced, form):
                    continue
                text = "".join(
                    ((" " + t) if (t not in "()" and not t.startswith("'")
                                   and not t.isspace()) else t)
                    for t in form
                ).strip()
                print(f"[{doc_path.name}:{line_no}] QUOTE-MISS {text[:78]}")
                total_missing += 1
    print(f"\n引用代码缺失 form 数: {total_missing}")
    return 1 if total_missing else 0


if __name__ == "__main__":
    sys.exit(main())
