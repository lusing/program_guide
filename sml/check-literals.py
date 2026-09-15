#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""检查 .sml 源文件里「字符串字面量中的非 ASCII 字节」。

为什么需要这个检查
------------------
SML/NJ 接受字符串里的原始 UTF-8，另两套实现都直接拒绝：

  Poly/ML: error: unprintable character \\231 found in string
  MLton  : Extended text constants (using UTF-8 byte sequences) disallowed,
           compile with -default-ann 'allowExtendedTextConsts true'

所以本教程的规矩是：**字符串字面量一律只写 ASCII，中文全部放注释里**，
需要输出中文时用 \\ddd 十进制转义（三套实现都会解成同一串字节）。

注释里的中文完全没问题，所以要先做一遍词法扫描把注释剥掉：
  - 块注释 (* ... *) 可以嵌套，必须配平
  - 字符串 "..." 里可能出现 (* 或 *) 的字面量
  - 字符字面量写作 #"x"

用法
----
    python3 check-literals.py examples/*.sml

退出码 0 表示干净，1 表示有违规（或注释没配平）。
"""

import sys


def scan(path):
    """返回 (违规列表, 结束时的注释深度)。违规项是 (行号, 字面量内容)。"""
    try:
        with open(path, "rb") as fh:
            src = fh.read().decode("utf-8", errors="replace")
    except OSError as exc:
        print("%s: 读不了这个文件 (%s)" % (path, exc), file=sys.stderr)
        sys.exit(1)

    n = len(src)
    i = 0
    depth = 0        # 注释嵌套深度
    line = 1
    bad = []         # [(行号, 字面量)]

    while i < n:
        c = src[i]

        if depth > 0:
            if src.startswith("(*", i):
                depth += 1
                i += 2
                continue
            if src.startswith("*)", i):
                depth -= 1
                i += 2
                continue
            if c == "\n":
                line += 1
            i += 1
            continue

        # 字符串字面量（含 #"x" 这种字符字面量）
        if c == '"':
            i += 1
            start_line = line
            buf = []
            while i < n and src[i] != '"':
                if src[i] == "\\":          # 转义序列整体跳过，\ddd 都是 ASCII
                    buf.append(src[i:i + 2])
                    i += 2
                    continue
                if src[i] == "\n":
                    line += 1
                buf.append(src[i])
                i += 1
            i += 1                          # 跳过收尾的 "
            text = "".join(buf)
            if any(ord(ch) > 127 for ch in text):
                bad.append((start_line, text))
            continue

        if src.startswith("(*", i):
            depth += 1
            i += 2
            continue

        if c == "\n":
            line += 1
        i += 1

    return bad, depth


def main(argv):
    if len(argv) < 2:
        print("用法: python3 check-literals.py <file.sml> [...]", file=sys.stderr)
        return 2

    rc = 0
    for path in argv[1:]:
        bad, depth = scan(path)
        if depth != 0:
            rc = 1
            print("%s: 注释没有配平（读到文件末尾时嵌套深度是 %d）" % (path, depth))
        for ln, text in bad:
            rc = 1
            shown = text if len(text) <= 48 else text[:45] + "..."
            print("%s:%d: 字符串字面量里有非 ASCII 字节 -> %r" % (path, ln, shown))

    if rc == 0:
        print("字面量检查通过：%d 个文件里没有非 ASCII 字符串" % (len(argv) - 1))
    else:
        print("字面量检查未通过：改成 ASCII 字面量，中文放注释里，"
              "需要输出中文请用 \\ddd 转义")
    return rc


if __name__ == "__main__":
    sys.exit(main(sys.argv))
