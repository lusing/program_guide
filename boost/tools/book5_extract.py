# -*- coding: utf-8 -*-
"""把罗剑锋《Boost 程序库完全开发指南（第5版）》epub 的 xhtml 转成 Markdown。

代码块特征：<div style="background:rgba(204, 201, 194, ...)"> 包着的 <p> 行。
小节标题特征：font-size:17px 且加粗的 span。
"""
import io, os, re, sys
from html import unescape

SRC = r"G:\book\_extract\boost5\EPUB\xhtml"
DST = r"G:\book\_extract\boost5_md"
os.makedirs(DST, exist_ok=True)

def para_text(p):
    t = re.sub(r"<[^>]+>", "", p)
    return unescape(t).strip()

def is_code_div(div):
    return "background:rgba(204, 201, 194" in div[:200]

def is_heading(p):
    if "font-weight: bold" not in p and "<b>" not in p:
        return False
    m = re.search(r"font-size:(\d+)px", p)
    return m and int(m.group(1)) >= 17

def convert(fname):
    raw = io.open(os.path.join(SRC, fname), encoding="utf-8").read()
    # 取 body
    m = re.search(r"<body[^>]*>(.*)</body>", raw, re.S)
    body = m.group(1) if m else raw
    out = []
    # 逐个 div（代码块）与其余 <p> 按出现顺序处理：先按 div 切
    pos = 0
    for dm in re.finditer(r"<div[^>]*>.*?</div>", body, re.S):
        # div 之前的散 p
        for pm in re.finditer(r"<p[^>]*>.*?</p>", body[pos:dm.start()], re.S):
            t = para_text(pm.group(0))
            if not t:
                continue
            out.append(("## " + t) if is_heading(pm.group(0)) else t)
        if is_code_div(dm.group(0)):
            lines = [para_text(p) for p in re.findall(r"<p[^>]*>.*?</p>", dm.group(0), re.S)]
            lines = [l for l in lines if l != ""]
            out.append("```\n" + "\n".join(lines) + "\n```")
        else:
            for p in re.findall(r"<p[^>]*>.*?</p>", dm.group(0), re.S):
                t = para_text(p)
                if t:
                    out.append(t)
        pos = dm.end()
    for pm in re.finditer(r"<p[^>]*>.*?</p>", body[pos:], re.S):
        t = para_text(pm.group(0))
        if not t:
            continue
        out.append(("## " + t) if is_heading(pm.group(0)) else t)
    return "\n\n".join(out)

def main():
    files = sorted(f for f in os.listdir(SRC) if f.startswith("Chapter"))
    for f in files:
        md = convert(f)
        name = f if f.endswith(".xhtml") else f + ".md"
        io.open(os.path.join(DST, name), "w", encoding="utf-8", newline="\n").write(md)
        print(f, len(md))

if __name__ == "__main__":
    main()
