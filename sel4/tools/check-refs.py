#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""校验教程里对真实 seL4/L4V 代码的引用（run-all.sh 第 5 关）。

两类引用：
  路径      l4v/spec/abstract/  ·  seL4/src/object/cnode.c
  带行号    …/CSpace_A.thy:292  ·  …/CSpace_A.thy` 第 292 行  ·  CSpace_A.thy 第 292 行

路径必须在代码根（SE4SRC）下真实存在（目录级引用也算）。带行号的还要求
"被引行上下 WINDOW 行内确实出现离它最近的那个标识名"——
规范重构后行号会漂，名字却往往还记得，所以这一条专抓"名字对、位置错"。
裸文件名（`CSpace_A.thy 第 208 行`）按文件名在 SE4SRC 下解析，多候选任一命中即通过。

官方文档引用走**另一个根**（SE4DOC，seL4 文档站仓库的本地镜像，除 l4v/、seL4/
外还带 docs/、capdl/、microkit/）：形如 `docs/Tutorials/…`、`docs/projects/…`、
`capdl/capDL-tool/doc/capDL.md`、`microkit/docs/manual.md` 的路径在那里核对，
行号规则同上。这里只认 docs/ 下 Tutorials、projects、Hardware、processes、
content_collections 五个子目录，所以 `docs/01-overview.md` 这类教程自己的章节名
不会被当成引用；
代码根下没有这几个目录，两个根不会互相抢解析。
SE4DOC 传 `-` 或目录不存在时，这部分引用整体跳过并报出条数（不静默放行）。

用法: check-refs.py <SE4SRC> <SE4DOC> <窗口行数> <待查文件…>
退出码: 0 全部站得住；1 有失败项。
"""
import os
import re
import sys

src, docsrc = sys.argv[1], sys.argv[2]
window = int(sys.argv[3])
targets = sys.argv[4:]

EXTS = {"thy", "c", "h", "lhs", "ml", "S", "py", "xml", "md", "bf", "ini", "txt"}
QUALIFIED = re.compile(r"(?:l4v|seL4)/[\w./-]*[\w]")
# 官方文档镜像里的路径。docs/ 只放行四个子目录，避开教程自己的 docs/NN-*.md。
DOCPATH = re.compile(r"(?:docs/(?:Tutorials|projects|Hardware|processes|content_collections)"
                     r"|capdl|microkit)/[\w./-]*[\w]")
BARE = re.compile(r"(?<![\w./-])([A-Za-z_]\w*\.(?:thy|c|h|lhs|ml|S))(?![\w-])")
# 行号前最多允许 6 个标点/空白 + 可选的"第"。句子标点（，。；）不在白名单里，
# 于是"CSpace_A.thy 一共 1000 行"这种普通句子不会被误当成行号引用。
NUM = re.compile("^[\\s\"'`（(){}\\\\/:：]{0,6}第?[ 　]{0,2}(\\d{1,5})")
IDENT = re.compile("`([A-Za-z_]\\w*)`|@\\{verbatim \"([A-Za-z_]\\w*)\"\\}")

by_name = {}
for dirpath, dirs, fs in os.walk(src):
    dirs[:] = [d for d in dirs if d not in (".git", "_output")]
    for f in fs:
        if f.rsplit(".", 1)[-1] in EXTS:
            by_name.setdefault(f, []).append(os.path.join(dirpath, f)[len(src) + 1:])

cache = {}


def lines_of(base, rel):
    if (base, rel) not in cache:
        try:
            with open(os.path.join(base, rel), encoding="utf-8", errors="replace") as fh:
                cache[(base, rel)] = fh.read().splitlines()
        except OSError:
            cache[(base, rel)] = None
    return cache[(base, rel)]


def nearest_ident(text, pos):
    """取离引用最近的那个标识名：前面 40 字符内、或后面 60 字符内开始的那对
    `` `name` `` / ``@{verbatim "name"}``（匹配本身可以更长，最多 140 字符）。"""
    best, best_d = "", 999
    off = max(0, pos - 100)
    for m in IDENT.finditer(text[off:pos]):
        d = pos - (off + m.end())
        if d <= 40 and d < best_d:
            best, best_d = m.group(1) or m.group(2), d
    for m in IDENT.finditer(text[pos:pos + 140]):
        if m.start() <= 60 and m.start() + 1 < best_d:
            best = m.group(1) or m.group(2)
        break
    return best


def hits(base, rel, num, ident):
    ls = lines_of(base, rel)
    if ls is None:
        return False, "读不到文件"
    i = int(num)
    if i > len(ls):
        return False, f"{rel} 全文只有 {len(ls)} 行"
    if not ident:
        return True, ""
    pat = re.compile(r"(?<![A-Za-z0-9_])" + re.escape(ident) + r"(?![A-Za-z0-9_])")
    w = "\n".join(ls[max(0, i - 1 - window): i + window])
    if pat.search(w):
        return True, ""
    where = next((str(k + 1) for k, l in enumerate(ls) if pat.search(l)), "别处")
    return False, f"`{ident}` 现在在 {rel}:{where}"


bad = good = line_refs = bare_refs = doc_skipped = 0
seen = set()
doc_ok = os.path.isdir(docsrc)
# `<!-- 源码块：path:起-止 -->` 里的路径整体摘掉：存在性由第 6 关管（它读不到文件
# 就报），行号区间也由第 6 关逐字管（比"±8 行内有这个名字"强得多）。
# 留着只会让检查器把正文里邻近的反引号词当成锚点，制造假失败。
MARKER = re.compile(r"<!--\s*(源码块|示意块)[^>]*-->")
for tf in targets:
    with open(tf, encoding="utf-8", errors="replace") as fh:
        text = fh.read()
    if tf.endswith(".md"):
        text = MARKER.sub("", text)

    if not doc_ok:
        doc_skipped += len({m.group(0) for m in DOCPATH.finditer(text)})
        pats = [(QUALIFIED, src)]
    else:
        pats = [(QUALIFIED, src), (DOCPATH, docsrc)]

    for qual, base in pats:
        for m in qual.finditer(text):
            rel = m.group(0)
            n = NUM.match(text[m.end():m.end() + 12])
            num = n.group(1) if n else ""
            if ("Q", base, tf, rel, num) in seen:
                continue
            seen.add(("Q", base, tf, rel, num))
            if not os.path.exists(os.path.join(base, rel)):
                print(f"!! 引用不存在: {rel}（{tf}）")
                bad += 1
                continue
            good += 1
            if not num:
                continue
            line_refs += 1
            ok, why = hits(base, rel, num, nearest_ident(text, m.start()))
            if not ok:
                print(f"!! 行号站不住: {rel}:{num}（{tf}：{why}）")
                bad += 1

    for m in BARE.finditer(text):
        name = m.group(1)
        cands = by_name.get(name)
        if not cands:                      # 不是真实代码里的文件（教程自己的 .thy 等）
            continue
        n = NUM.match(text[m.end():m.end() + 12])
        if not n:
            continue
        num = n.group(1)
        if ("B", tf, name, num) in seen:
            continue
        seen.add(("B", tf, name, num))
        bare_refs += 1
        ident = nearest_ident(text, m.start())
        results = [hits(src, rel, num, ident) for rel in cands]
        if any(ok for ok, _ in results):
            good += 1
        else:
            print(f"!! 行号站不住: {name} 第 {num} 行（{tf}：{results[0][1] or '多个候选都对不上'}）")
            bad += 1

print(f"   引用检查：{good} 条通过、{bad} 条站不住/不存在"
      f"（带行号 {line_refs} 条，其中裸文件名 {bare_refs} 条）")
if not doc_ok:
    print(f"   （未找到文档镜像 {docsrc}，{doc_skipped} 条官方文档引用没核）")
sys.exit(1 if bad else 0)
