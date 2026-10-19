#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""audit_docs.py — 核对 extending-emacs 文档与 examples/ 真实产物的一致性。

判据（两条，都按「章节的示例」为基准）：
  1. 文档里每个输出块（无 info string 的围栏）的每一行，必须能在该章示例的
     真实 stdout 里按顺序找到（子序列判定）。防止「想象输出」。
  2. 每个 ```elisp 代码块必须能被 Emacs read 成完整 form（防止把输出 dump
     或半截代码当代码贴；含 "..." 的教学片段跳过）。

附带报告：示例未收录的代码块（正文引用了示例里没有的代码）——这类要么是
「示例该补」，要么是「正文该改成示例里的写法」，需人工过一遍。

用法：python3 tools/audit_docs.py [--chapter NN ...]
"""
import re
import subprocess
import sys
from pathlib import Path

EMACS_DIR = Path(__file__).parent.parent
DOCS_DIR = EMACS_DIR / "docs" / "extending-emacs"
EXAMPLES_DIR = EMACS_DIR / "examples"
EMACS = "/opt/local/bin/emacs"
FENCE_RE = re.compile(r"^```(\w*)\s*$")

READ_PROBE = r"""
(with-temp-buffer
  (insert %s)
  (goto-char (point-min))
  (condition-case err
      (progn
        (while (not (eobp))
          (skip-chars-forward " \t\n")
          (unless (eobp) (read (current-buffer))))
        (princ "READABLE"))
    (error (princ "UNREADABLE"))))
"""


def split_blocks(text):
    blocks = []
    lines = text.split("\n")
    i = 0
    while i < len(lines):
        m = FENCE_RE.match(lines[i])
        if m:
            info = m.group(1)
            j = i + 1
            body = []
            while j < len(lines) and not FENCE_RE.match(lines[j]):
                body.append(lines[j])
                j += 1
            blocks.append((info, "\n".join(body), i + 2))
            i = j + 1
        else:
            i += 1
    return blocks


def readable(code):
    if "..." in code:
        return None  # 教学片段，跳过
    lit = '"' + code.replace("\\", "\\\\").replace('"', '\\"') + '"'
    r = subprocess.run(
        [EMACS, "-Q", "--batch", "--eval", READ_PROBE % lit],
        capture_output=True, text=True, timeout=30,
    )
    return "READABLE" in r.stdout


def run_example(num):
    cands = sorted(EXAMPLES_DIR.glob(f"{num}-*.el"))
    if not cands:
        return None
    r = subprocess.run([EMACS, "-Q", "--batch", "-l", str(cands[0])],
                       capture_output=True, text=True, timeout=60)
    return r.stdout


def is_subseq(claimed, real):
    missing = []
    pos = 0
    for c in claimed:
        found = False
        while pos < len(real):
            if real[pos] == c:
                found = True
                pos += 1
                break
            pos += 1
        if not found:
            missing.append(c)
    return missing


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("-")]
    chapters = sorted(DOCS_DIR.glob("[0-9][0-9]-*.md"))
    if args:
        chapters = [c for c in chapters if c.name[:2] in args]

    problems = 0
    for doc in chapters:
        num = doc.name[:2]
        real_out = run_example(num)
        if real_out is None:
            print(f"[{doc.name}] 没有对应示例，跳过")
            continue
        real_lines = [l.rstrip() for l in real_out.split("\n")]

        text = doc.read_text(encoding="utf-8")
        blocks = split_blocks(text)
        for info, body, line_no in blocks:
            if info in ("elisp", "lisp"):
                ok = readable(body)
                if ok is False:
                    print(f"[{doc.name}:{line_no}] ELISP-UNREADABLE "
                          f"（输出 dump 或半截代码？）")
                    problems += 1
            elif info == "":
                claimed = [l.rstrip() for l in body.split("\n")
                           if l.strip() and not l.startswith("$")]
                if not claimed:
                    continue
                missing = is_subseq(claimed, real_lines)
                if missing:
                    print(f"[{doc.name}:{line_no}] OUT-MISS "
                          f"{len(missing)}/{len(claimed)} 行")
                    for m in missing[:4]:
                        print(f"    声称: {m!r}")
                    problems += 1
    print(f"\n问题总数: {problems}")
    sys.exit(1 if problems else 0)


if __name__ == "__main__":
    main()
