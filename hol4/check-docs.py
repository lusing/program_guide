#!/usr/bin/env python3
"""文档机器核查：教程写出来之后，人眼最容易放过的四类错位。

1) **节号对应**：docs/NN-x.md 里的 `## NN.M 标题` 必须与
   examples/NN_x/NN_x.sml 里的 `sec "NN.M 标题"` 一一对应（顺序 + 文字）。
   少了就是文档漏写，多了就是文档写了没验证的东西。
2) **引用输出**：docs 里 ```text 块中的每一行，都必须能在
   build/NN_x/run1.sec 里**逐字节**找到。这是"不写想象中的输出"的硬保证。
   不参与比对的块（示意、输入样本、源码清单）要在紧邻上一行写
   `<!-- 示意 -->` 显式标注。
3) **导航链**：首章只有"下一章"、末章只有"上一章"、其余两章都有，
   且指向的相邻文件必须真实存在。
4) **坑位数**：每章 `## NN.M 坑位清单` 必须恰好 10 条、且是本章最后一节；
   24 章之和必须等于 CHEATSheet.md 与 README.md 里引用的数字。

用法：
  python3 check-docs.py            # 全部检查（有问题返回 1）
  python3 check-docs.py --verbose  # 顺带打印每条引用的比对结果
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent
DOCS = ROOT / 'docs'
EXAMPLES = ROOT / 'examples'
BUILD = ROOT / 'build'
TRAPS_PER_CHAPTER = 10

# 注意调用形式：本教程的 helper 定义为 `fun sec s = print ("\n" ^ s ^ "\n")`，
# 调用是 `sec "11.1 基本转换"` —— **没有括号**。写成 `sec\(` 是一行都匹配不到的
# （实测：24 章全部报"示例 <缺>"，看着像文档全错，其实是正则错了）。
SEC_RE = re.compile(r'\bsec\s+"((?:[^"\\]|\\.)*)"')
HEAD_RE = re.compile(r'^##\s+(\d+)\.(\d+)\s+(.*?)\s*$')
TRAP_HEAD_RE = re.compile(r'^##\s+\d+\.\d+\s+坑位清单\s*$')
ITEM_RE = re.compile(r'^\d+\.\s')
FENCE_RE = re.compile(r'^```')
# 标注用前缀匹配：`<!-- 示意 -->` 和 `<!-- 示意：离线复现的报错文本 -->` 都算。
SKIP_MARK = '<!-- 示意'

problems = []


def err(msg):
    problems.append(msg)


def chapters():
    return sorted(DOCS.glob('[0-9][0-9]-*.md'))


def example_for(num):
    hits = sorted(EXAMPLES.glob(f'{num}_*'))
    for d in hits:
        f = d / f'{d.name}.sml'
        if f.exists():
            return f
    return None


def sec_titles(path):
    """从示例里按 **出现顺序** 取出 sec("...") 的字符串。"""
    out = []
    text = path.read_text(encoding='utf-8')
    for m in SEC_RE.finditer(text):
        out.append(m.group(1))
    return out


def doc_sections(path):
    """从文档里按出现顺序取出 (节号, 标题)；坑位清单那一节单独标记。"""
    secs = []
    trap = None
    for line in path.read_text(encoding='utf-8').split('\n'):
        m = HEAD_RE.match(line)
        if not m:
            continue
        num = f'{m.group(1)}.{m.group(2)}'
        title = m.group(3)
        if TRAP_HEAD_RE.match(line):
            trap = num
        else:
            secs.append((num, title))
    return secs, trap


def check_sections(path, num):
    ex = example_for(num)
    if ex is None:
        err(f'{path.name}: 找不到对应的 examples/{num}_*/{num}_*.sml')
        return
    # 文档标题形如 `## 11.1 基本转换`，示例里是 sec "11.1 基本转换" ——
    # 拼回带节号的完整形式再比，否则每章都会报"全不对应"（实测踩到）。
    # 标题里的反引号（markdown 代码格式）在比对前去掉：
    # `## 20.2 装配：`++`` 和 sec "20.2 装配：++" 说的是同一件事。
    want = sec_titles(ex)
    got, _ = doc_sections(path)
    got_titles = [f'{n} {t}'.replace('`', '') for n, t in got]
    if want == got_titles:
        return
    err(f'{path.name}: 节号与示例 sec() 不对应')
    for i in range(max(len(want), len(got_titles))):
        w = want[i] if i < len(want) else '<缺>'
        g = got_titles[i] if i < len(got_titles) else '<缺>'
        if w != g:
            err(f'    第 {i + 1} 节：示例 sec("{w}") vs 文档 "{g}"')


def fenced_blocks(lines):
    """产出 (起始行号, 语言, 内容行列表, 是否跳过)。"""
    out = []
    i = 0
    while i < len(lines):
        if FENCE_RE.match(lines[i]):
            lang = lines[i][3:].strip()
            j = i + 1
            body = []
            while j < len(lines) and not FENCE_RE.match(lines[j]):
                body.append(lines[j])
                j += 1
            skip = lang != 'text'
            if not skip and i > 0 and lines[i - 1].strip().startswith(SKIP_MARK):
                skip = True
            out.append((i + 1, lang, body, skip))
            i = j + 1
        else:
            i += 1
    return out


def check_output(path, num, verbose=False):
    sec_file = None
    for d in sorted(BUILD.glob(f'{num}_*')):
        f = d / 'run1.sec'
        if f.exists():
            sec_file = f
            break
    if sec_file is None:
        err(f'{path.name}: 找不到 build/{num}_*/run1.sec（先跑 run-all.sh）')
        return
    hay = sec_file.read_text(encoding='utf-8').split('\n')
    hayset = set(hay)
    lines = path.read_text(encoding='utf-8').split('\n')
    for start, lang, body, skip in fenced_blocks(lines):
        if skip:
            continue
        for k, line in enumerate(body):
            if not line.strip():
                continue
            if line in hayset:
                if verbose:
                    print(f'  {path.name}:{start + 1 + k}: ok')
            else:
                err(f'{path.name}:{start + 1 + k}: 输出行在 {sec_file.name} 里逐字节找不到')
                err(f'    {line}')


def check_nav(path, num, all_docs):
    text = path.read_text(encoding='utf-8')
    tail = '\n'.join(text.rstrip().split('\n')[-6:])
    nums = [d.name[:2] for d in all_docs]
    idx = nums.index(num)
    has_prev = '上一章：' in tail
    has_next = '下一章：' in tail
    if idx == 0 and has_prev:
        err(f'{path.name}: 首章不应有「上一章」')
    if idx == len(nums) - 1 and has_next:
        err(f'{path.name}: 末章不应有「下一章」')
    if 0 < idx < len(nums) - 1 and not (has_prev and has_next):
        err(f'{path.name}: 中间章应同时有「上一章」和「下一章」')
    for m in re.finditer(r'(上一章|下一章)：\[[^\]]*\]\(([^)]+)\)', tail):
        target = m.group(2)
        if not (DOCS / target).exists():
            err(f'{path.name}: 导航指向的文件不存在：{target}')
        elif not target.startswith(all_docs[idx + (-1 if m.group(1) == '上一章' else 1)].name[:2]):
            err(f'{path.name}: 导航 {m.group(1)} 指向的不是相邻章：{target}')


def check_traps(path, num, total):
    lines = path.read_text(encoding='utf-8').split('\n')
    idx = None
    for i, line in enumerate(lines):
        if TRAP_HEAD_RE.match(line):
            idx = i
    if idx is None:
        err(f'{path.name}: 缺少「坑位清单」小节')
        return total
    # 必须是本章最后一节：它之后不能再有 `## ` 标题（导航脚注在 `---` 之后）
    for line in lines[idx + 1:]:
        if line.startswith('## '):
            err(f'{path.name}: 坑位清单不是最后一节（后面还有 {line}）')
            break
        if line.strip() == '---':
            break
    n = 0
    for line in lines[idx + 1:]:
        if line.strip() == '---':
            break
        if ITEM_RE.match(line):
            n += 1
    if n != TRAPS_PER_CHAPTER:
        err(f'{path.name}: 坑位清单 {n} 条（应为 {TRAPS_PER_CHAPTER}）')
    return total + n


def check_references(total):
    """CHEATSheet.md 与 README.md 里引用的坑位总数必须等于实际总数。"""
    for name in ('CHEATSheet.md', 'README.md'):
        f = ROOT / name
        if not f.exists():
            err(f'缺少 {name}')
            continue
        found = False
        for m in re.finditer(r'(\d+)\s*条坑位', f.read_text(encoding='utf-8')):
            found = True
            if int(m.group(1)) != total:
                err(f'{name}: 写了 {m.group(1)} 条坑位，实际是 {total} 条')
        if not found:
            err(f'{name}: 没有找到「N 条坑位」的引用')


def main():
    verbose = '--verbose' in sys.argv[1:]
    all_docs = chapters()
    if not all_docs:
        err('docs/ 下没有章节文件')
    total = 0
    for d in all_docs:
        num = d.name[:2]
        check_sections(d, num)
        check_output(d, num, verbose)
        check_nav(d, num, all_docs)
        total = check_traps(d, num, total)
    check_references(total)
    print(f'坑位总数：{total}（{len(all_docs)} 章 × {TRAPS_PER_CHAPTER}）')
    if problems:
        print(f'\n共 {len(problems)} 处问题：')
        for p in problems:
            print(f'  - {p}')
        return 1
    print('文档机器核查通过。')
    return 0


if __name__ == '__main__':
    sys.exit(main())
