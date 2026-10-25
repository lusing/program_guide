#!/usr/bin/env python3
"""docs/ 与 examples/ + build/ 产物的一致性核查（Isabelle 教程专用）。

三项核查（与 hol4/ 的 check-docs.py 同思路，按 Isabelle 项目定制）:

  1. 坑位条数: 每章"坑位清单"节的编号条目数求和, 必须与 README.md、
     CHEATSheet.md 里声明的总数一致（对不上就是"假绿"）。
  2. ```text 块: docs/NN-*.md 里每个 ```text 块的每一行, 必须能在
     build/first/out/<Theory>.txt 里逐字节找到（正文引用的是实测输出,
     不是想象输出）。产物缺失的章会计入 skipped, 不会静默算通过。
  3. 节号对应: 示例 .thy 里有 section/subsection 标记的章,
     docs 的 `## N.M` 标题必须与之逐条对应（标题文本一致, 顺序一致）。

用法:
    python3 check-docs.py            # 全量核查
    python3 check-docs.py 69 70      # 只核查指定章

退出码 0 = 全部通过; 1 = 有失败项。
"""
import os
import re
import sys
import glob

ROOT = os.path.dirname(os.path.abspath(__file__))
DOCS = os.path.join(ROOT, "docs")
EXAMPLES = os.path.join(ROOT, "examples")
OUTDIR = os.path.join(ROOT, "build", "first", "out")

PIT_HEADINGS = ("坑位清单", "常见坑", "pit list")


def read(path):
    with open(path, encoding="utf-8") as f:
        return f.read()


def theory_of(doc_text):
    """从'对应示例'行取示例理论名（第一个 T 前缀代码片段）。"""
    m = re.search(r"对应示例[：:]\s*`([^`]+)`", doc_text)
    if not m:
        return None
    name = m.group(1)
    name = name.split("/")[-1]
    if name.endswith(".thy"):
        name = name[:-4]
    if not re.match(r"^T\d\d[a-z]?_[A-Za-z0-9_]+$", name):
        return None
    return name


def find_example_file(theory):
    hits = glob.glob(os.path.join(EXAMPLES, "**", theory + ".thy"), recursive=True)
    return hits[0] if hits else None


def pitfall_count(doc_text):
    lines = doc_text.split("\n")
    idx = None
    for i, l in enumerate(lines):
        if l.startswith("## ") and any(h in l for h in PIT_HEADINGS):
            idx = i
            break
    if idx is None:
        return None
    n = 0
    for l in lines[idx + 1:]:
        if l.startswith("## "):
            break
        if re.match(r"^\d+\. ", l):
            n += 1
    return n


def section_titles(thy_text):
    """thy 里的 section/subsection 标题, 按出现顺序返回 [(节号, 标题)]。"""
    out = []
    for m in re.finditer(
            r"^(section|subsection)\s+\\<open>(\d+)\.(\d+)\s+(.+?)\\close>",
            thy_text, re.M):
        out.append((m.group(2) + "." + m.group(3), m.group(4).strip()))
    return out


def norm_title(s):
    for ch in ("**", "`", "「", "」", "「", "」"):
        s = s.replace(ch, "")
    return s.strip()


def is_illustrative(doc_text, block_start):
    """块前 200 字内带 `<!-- 示意块：非构建产物，不参与输出比对 -->` 的
    ```text 块是示意片段（命令、配置、错误目录等），不逐字节比对。"""
    pre = doc_text[max(0, block_start - 200):block_start]
    return "示意块" in pre


def main():
    want = sys.argv[1:]
    docs = sorted(glob.glob(os.path.join(DOCS, "*.md")))
    if want:
        docs = [d for d in docs
                if any(("-" + w + "-") in os.path.basename(d)
                       or os.path.basename(d).startswith(w + "-")
                       for w in want)]
    fails = []
    checked_text = 0
    skipped = []
    total_pits = 0
    pit_chapters = 0

    for d in docs:
        base = os.path.basename(d)
        num = base.split("-")[0]
        text = read(d)
        th = theory_of(text)

        # --- 3) 节号对应（只对带 section 标记的示例生效）----------------
        if th:
            ex = find_example_file(th)
            if ex:
                titles = section_titles(read(ex))
                if titles:
                    heads = re.findall(r"^## (\d+\.\d+) (.+)$", text, re.M)
                    if [h[0] for h in heads] != [t[0] for t in titles]:
                        fails.append("%s: 节号不对应 doc=%s thy=%s"
                                     % (base, [h[0] for h in heads],
                                        [t[0] for t in titles]))
                    else:
                        for h, t in zip(heads, titles):
                            if norm_title(h[1]) != norm_title(t[1]):
                                fails.append("%s: %s 标题不一致 doc=%r thy=%r"
                                             % (base, h[0], h[1], t[1]))

        # --- 2) ```text 块逐字节比对 ------------------------------------
        if th:
            outfile = os.path.join(OUTDIR, th + ".txt")
            if not os.path.exists(outfile):
                skipped.append(base + "（缺 " + os.path.relpath(outfile, ROOT) + "）")
            else:
                outlines = set(read(outfile).split("\n"))
                checked_text += 1
                for m in re.finditer(r"```text\n(.*?)```", text, re.S):
                    if is_illustrative(text, m.start()):
                        continue
                    for line in m.group(1).split("\n"):
                        if line.strip() == "":
                            continue
                        if line not in outlines:
                            fails.append("%s: text 块未在产物中找到: %r"
                                         % (base, line))

        # --- 1) 坑位条数 -------------------------------------------------
        n = pitfall_count(text)
        if n is None:
            fails.append("%s: 找不到坑位清单节" % base)
        else:
            total_pits += n
            pit_chapters += 1

    # 声明数字对账（只在全量核查时做——挑章跑时总数天然不齐）
    if not want:
        readme = read(os.path.join(ROOT, "README.md"))
        cheat = read(os.path.join(ROOT, "CHEATSheet.md"))
        m = re.search(r"共\s*(\d+)\s*条", readme)
        readme_n = int(m.group(1)) if m else None
        m = re.search(r"坑位总数是\s*(\d+)\s*条", cheat)
        cheat_n = int(m.group(1)) if m else None
        if readme_n is None:
            fails.append("README.md 里找不到'共 N 条'的坑位声明")
        elif readme_n != total_pits:
            fails.append("README 声明坑位 %d, 实查 %d" % (readme_n, total_pits))
        if cheat_n is None:
            fails.append("CHEATSheet.md 里找不到'坑位总数是 N 条'的声明")
        elif cheat_n != total_pits:
            fails.append("CHEATSheet 声明坑位 %d, 实查 %d" % (cheat_n, total_pits))

    print("核查章数: %d（其中 %d 章有坑位清单, 合计 %d 条）"
          % (len(docs), pit_chapters, total_pits))
    print("text 块逐字节核查: %d 章" % checked_text)
    if skipped:
        print("跳过 text 核查的章（产物缺失, 未通过也未失败）: %d 章"
              % len(skipped))
        for s in skipped:
            print("   -", s)
    if fails:
        print("\n失败 %d 项:" % len(fails))
        for f in fails:
            print("  !!", f)
        return 1
    print("全部通过")
    return 0


if __name__ == "__main__":
    sys.exit(main())
