#!/usr/bin/env python3
"""验证文档里「代码 ; → 结果」形式断言的正确性。

教程里大量使用这种速查写法：

    (cons 1 2)      ; → (1 . 2)   点对：cdr 不是列表
    (nth 1 '(a b c d))  ; → b

本工具把每条断言的「代码」抽出来，在 emacs -Q --batch 里真求值，
用 %S 格式化，和「→」后面声称的结果逐字比对。

能处理的输入：
  - 单行自含表达式（不引用未定义变量）；
  - 前面几行是同一表达式的一部分（多行表达式取到括号配平为止）。

跳过（报告为 SKIP，不算错）：
  - 引用了文档里别处定义的变量/函数的演示代码（如 my-list、cfg、s1）；
  - 含 ... 省略号、含 ;; 中文注释混排导致无法解析的。

用法：python3 tools/check_arrows.py [--chapter NN] [-v]
"""
import re
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DOCS = ROOT / "docs" / "extending-emacs"

EMACS = "emacs"

# 这些名字在文档示例里出现过、但不是 Emacs 内置符号 —— 跳过
KNOWN_LOCAL = {
    "my-list", "cfg", "s1", "s2", "stack", "x", "some-new-option",
    "some-new-function", "user-value", "default-value", "demo-",
    "child-map", "parent-map", "from", "to", "path", "start", "end",
    "filename", "orig", "args", "result", "n", "s", "key", "value",
    "map", "buf", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k",
    "sym", "val", "expr", "lst", "xs", "ns", "obj", "fn", "pred",
    "beg", "pos", "old", "new", "def", "t0", "count", "log",
}


def strip_comments_outside_strings(line: str) -> str:
    """去掉行内注释，但不动字符串里的分号。"""
    out = []
    in_str = False
    i = 0
    while i < len(line):
        ch = line[i]
        if in_str:
            out.append(ch)
            if ch == "\\" and i + 1 < len(line):
                out.append(line[i + 1])
                i += 2
                continue
            if ch == '"':
                in_str = False
            i += 1
            continue
        if ch == '"':
            in_str = True
            out.append(ch)
            i += 1
            continue
        if ch == ";":
            break
        out.append(ch)
        i += 1
    return "".join(out)


ARROW_RE = re.compile(r"^(?P<code>.*?)\s*;\s*(?:→|->)\s*(?P<claim>.+?)\s*$")


def balanced(code: str) -> bool:
    """括号是否配平（忽略字符串内的括号）。"""
    depth = 0
    in_str = False
    i = 0
    while i < len(code):
        ch = code[i]
        if in_str:
            if ch == "\\":
                i += 2
                continue
            if ch == '"':
                in_str = False
            i += 1
            continue
        if ch == '"':
            in_str = True
        elif ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
            if depth < 0:
                return False
        i += 1
    return depth == 0


def extract_claims(md: str):
    """从 markdown 里抽 (代码, 声称结果, 行号) 三元组。

    策略：扫所有行，找含 → 的行；代码部分向前追溯到括号配平。
    """
    lines = md.splitlines()
    claims = []
    i = 0
    while i < len(lines):
        m = ARROW_RE.match(lines[i])
        if not m:
            i += 1
            continue
        code_part = strip_comments_outside_strings(m.group("code")).strip()
        claim = m.group("claim").strip()
        # 向前追：括号不配平就继续吃上一行
        j = i - 1
        while code_part and not balanced(code_part) and j >= 0:
            prev = strip_comments_outside_strings(lines[j]).strip()
            if not prev:
                break
            code_part = prev + " " + code_part
            j -= 1
        if code_part and balanced(code_part):
            claims.append((code_part, claim, i + 1))
        i += 1
    return claims


def is_prose(claim: str) -> bool:
    """取出的「值」里含中文/全角符号 → 是散文描述，跳过。"""
    return bool(re.search(r"[\u4e00-\u9fff！？，。（）]", claim))


def looks_self_contained(code: str) -> bool:
    """粗判是否自含：不含 ... 省略号，不引用明显的文档局部名。"""
    if "..." in code:
        return False
    for name in KNOWN_LOCAL:
        # 以 - 结尾的是「前缀」，比如 demo- 要匹配 demo-incr / demo-n
        if name.endswith("-"):
            if re.search(rf"(?<![A-Za-z0-9-]){re.escape(name)}", code):
                return False
        elif re.search(rf"(?<![A-Za-z0-9-]){re.escape(name)}(?![A-Za-z0-9-])", code):
            return False
    return True


def evaluate(codes):
    """在 batch 里求值一批代码，返回 %S 结果列表。"""
    prog = []
    for idx, code in enumerate(codes):
        prog.append(
            f'(princ (format "[[{idx}]]%S\\n" (condition-case err '
            f'(let ((r {code})) (if (stringp r) r (format "%S" r))) '
            f'(error (format "ERR:%S" err)))))'
        )
    script = "\n".join(prog)
    with tempfile.NamedTemporaryFile("w", suffix=".el", delete=False) as fh:
        fh.write(script)
        path = fh.name
    try:
        out = subprocess.run(
            [EMACS, "-Q", "--batch", "-l", path],
            capture_output=True, text=True, timeout=120,
        )
    finally:
        Path(path).unlink(missing_ok=True)
    results = {}
    for line in out.stdout.splitlines():
        m = re.match(r"^\[\[(\d+)\]\](.*)$", line)
        if m:
            results[int(m.group(1))] = m.group(2)
    return results, out.stderr


def leading_value(claim: str) -> str:
    """从声称结果里取出开头的 Lisp 值（后面可能跟着解释文字）。"""
    s = claim.strip()
    if not s:
        return ""
    if s.startswith('"'):
        # 字符串字面量
        i = 1
        while i < len(s):
            if s[i] == "\\":
                i += 2
                continue
            if s[i] == '"':
                return s[: i + 1]
            i += 1
        return s
    if s.startswith("(") or s.startswith("["):
        open_ch = s[0]
        close_ch = ")" if open_ch == "(" else "]"
        depth = 0
        i = 0
        while i < len(s):
            if s[i] == open_ch:
                depth += 1
            elif s[i] == close_ch:
                depth -= 1
                if depth == 0:
                    return s[: i + 1]
            i += 1
        return s
    # 裸符号/数字：取到第一个空白
    m = re.match(r"^(\S+)", s)
    return m.group(1) if m else s


def normalize(s: str) -> str:
    return s.strip().strip('"').strip()


def main() -> int:
    verbose = "-v" in sys.argv
    chapter = None
    args = [a for a in sys.argv[1:] if a != "-v"]
    if args and args[0] == "--chapter":
        chapter = args[1].zfill(2)

    docs = sorted(DOCS.glob(f"{chapter}-*.md")) if chapter else sorted(DOCS.glob("*.md"))
    bad = skipped = ok = 0
    for doc in docs:
        md = doc.read_text(encoding="utf-8")
        claims = extract_claims(md)
        runnable = []
        for code, claim, line_no in claims:
            lead = leading_value(claim)
            if is_prose(lead):
                skipped += 1
                if verbose:
                    print(f"[{doc.name}:{line_no}] SKIP-PROSE {code[:50]}")
                continue
            if not looks_self_contained(code):
                skipped += 1
                if verbose:
                    print(f"[{doc.name}:{line_no}] SKIP {code[:60]}")
                continue
            runnable.append((code, claim, line_no))
        if not runnable:
            continue
        results, stderr = evaluate([c for c, _, _ in runnable])
        for idx, (code, claim, line_no) in enumerate(runnable):
            got = results.get(idx)
            if got is None:
                print(f"[{doc.name}:{line_no}] NO-OUTPUT {code[:60]}")
                bad += 1
                continue
            if got.startswith("ERR:"):
                print(f"[{doc.name}:{line_no}] EVAL-ERR {code[:50]} → {got}")
                bad += 1
                continue
            claimed = normalize(leading_value(claim))
            gotn = normalize(got)
            if claimed == gotn or claimed == "...":
                ok += 1
            else:
                print(f"[{doc.name}:{line_no}] ARROW-MISS 代码: {code[:55]} | 声称: {claimed[:40]} | 实际: {gotn[:40]}")
                bad += 1
    print(f"\n断言核对: 通过 {ok}，失败 {bad}，跳过（引用局部变量）{skipped}")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
