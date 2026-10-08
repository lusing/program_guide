# -*- coding: utf-8 -*-
"""mathlogic Mendelson 轮全书重编号（批次〇，一次性）。
两阶段改名 + 单遍映射替换 + 页脚导航全量重生成。用法：
python -I tools/renumber_m.py [--apply]    # 默认 dry-run
"""
import os, re, sys, glob

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

MAP = {  # 旧章号 -> 新章号（01-08 恒等不列）
    9:10, 10:11, 11:12, 12:13, 13:14, 14:15, 15:16, 16:17, 17:18, 18:19,
    19:20, 20:21, 21:22, 22:23, 23:24, 24:25, 25:26, 26:27, 27:28, 28:29,
    29:30, 30:31, 31:32, 32:33, 33:38, 34:37, 35:39, 36:40, 37:41, 38:42,
    39:43, 40:44, 41:45, 42:46, 43:47, 44:48, 45:49, 46:50, 47:51, 48:52,
    49:53, 50:54, 51:55, 52:56, 53:57, 54:58, 55:59, 56:60, 57:61, 58:63,
}
GAPS = {9, 34, 35, 36, 62}            # 本轮新建章（重排后应为空位）
NEW_TITLES = {                        # 空位章的页脚标题（页脚重生成需要）
    9: ('adequate', '完备连接词集与公理独立性'),
    34: ('turing', '图灵机：四元组与纸带'),
    35: ('recfn', '递归函数与部分递归'),
    36: ('goedel', '算术化与哥德尔编码'),
    62: ('nbg', '公理集合论 NBG 与序数'),
}
APPLY = '--apply' in sys.argv

# ---------- 1. 两阶段改名 ----------
def two_phase(kind):
    base = os.path.join(ROOT, 'examples') if kind == 'ex' else os.path.join(ROOT, 'docs')
    pat = re.compile(r'^(\d{2})([_-])([a-z]+)(\.md)?$')
    moves = []
    for name in os.listdir(base):
        m = pat.match(name)
        if m and int(m.group(1)) in MAP:
            n, sep, slug = int(m.group(1)), m.group(2), m.group(3)
            moves.append((name, f"{MAP[n]:02d}{sep}{slug}{m.group(4) or ''}"))
    print(f'[{kind}] rename {len(moves)}')
    if not APPLY:
        for a, b in moves: print('  ', a, '->', b)
        return
    for a, b in moves:
        os.rename(os.path.join(base, a), os.path.join(base, a + '.tmp~'))
    for a, b in moves:
        assert not os.path.exists(os.path.join(base, b)), b
        os.rename(os.path.join(base, a + '.tmp~'), os.path.join(base, b))

# ---------- 2. 单遍文本替换 ----------
def sub_mapped_num(num_str):
    n = int(num_str)
    return f"{MAP[n]:02d}" if n in MAP else num_str

def _zh_group(m):   # 「第 33/34 章」斜杠组（先于 zh章，避免 enum章 的 (?<!第 ) 盲区）
    toks = re.split(r'([/-])', m.group(1))
    return '第 ' + ''.join(sub_mapped_num(t) if t.isdigit() else t for t in toks) + ' 章'

def _zh(m):
    n = int(m.group(1))
    return f"第 {MAP[n] if n in MAP else n} 章"

def _enum_ch(m):
    toks = re.split(r'([/-])', m.group(1))
    return ''.join(sub_mapped_num(t) if t.isdigit() else t for t in toks) + ' 章'

PATTERNS = [
    # 顺序纪律（EFT 轮定稿）：目标改写类在前，链接标签最后；每类输出不被后续类重匹配。
    ('zh章组', re.compile(r'第\s*((?:\d{1,2}\s*[/-]\s*){1,4}\d{1,2})\s*章'), _zh_group),
    ('zh章',   re.compile(r'第\s*(\d{1,2})\s*章'), _zh),
    ('enum章', re.compile(r'(?<!第 )(?<!\d)((?:\d{1,2}[/-]){0,4}\d{1,2})\s*章'), _enum_ch),
    ('doc文件', re.compile(r'(?<!\d)(\d{2})-([a-z]+)(?![\w-])'),
        lambda m: f"{sub_mapped_num(m.group(1))}-{m.group(2)}"),
    ('ex文件', re.compile(r'(?<!\w)ex(\d{2})_([a-z]+)'),
        lambda m: f"ex{sub_mapped_num(m.group(1))}_{m.group(2)}"),
    ('目录名', re.compile(r'(?<![\w/])(\d{2})_([a-z]+)'),
        lambda m: f"{sub_mapped_num(m.group(1))}_{m.group(2)}"),
    ('session', re.compile(r'\bML(\d{2})\b'),
        lambda m: f"ML{sub_mapped_num(m.group(1))}"),
    ('hol4',   re.compile(r'\bEx(\d{2})'),
        lambda m: f"Ex{sub_mapped_num(m.group(1))}"),
    ('链接标签', re.compile(r'\[(\d{2}) ([^\]]*)\]\(([^)]*)\)'),
        lambda m: f"[{sub_mapped_num(m.group(1))} {m.group(2)}]({m.group(3)})"),
]

def text_files():
    return (
        glob.glob(os.path.join(ROOT, 'docs', '*.md'))
        + [os.path.join(ROOT, f) for f in ('README.md', 'PLAN.md', 'CHEATSheet.md')]
        + [os.path.join(ROOT, 'examples', 'ROOT')]
        + [p for ext in ('*.v', '*.agda', '*.lean', '*.thy', '*.sml', '*.pl')
            for p in glob.glob(os.path.join(ROOT, 'examples', '**', ext), recursive=True)]
    )

def replace_texts():
    stats = {}
    for path in text_files():
        try:
            text = open(path, 'rb').read().decode('utf-8')
        except UnicodeDecodeError:
            print('SKIP(编码)', path); continue
        orig = text
        for name, rx, cb in PATTERNS:
            text, n = rx.subn(cb, text)
            if n: stats[name] = stats.get(name, 0) + n
        if text != orig and APPLY:
            open(path, 'wb').write(text.encode('utf-8'))
    print('替换统计:', stats)

# ---------- 3. 页脚导航全量重生成（按 63 章新序，空位章用预留标题）----------
def chapter_table():
    tabs = {}
    for p in glob.glob(os.path.join(ROOT, 'docs', '*.md')):
        m = re.match(r'^(\d{2})-([a-z]+)\.md$', os.path.basename(p))
        if not m: continue
        num, slug = int(m.group(1)), m.group(2)
        head = open(p, 'rb').read().decode('utf-8').split('\n', 1)[0]
        hm = re.match(r'# 第 \d{2} 章 (.+)$', head.strip())
        tabs[num] = (slug, hm.group(1).strip() if hm else slug)
    for num, (slug, title) in NEW_TITLES.items():
        tabs[num] = (slug, title)
    return tabs

def regen_footers():
    tabs = chapter_table()
    order = sorted(tabs)
    for p in glob.glob(os.path.join(ROOT, 'docs', '*.md')):
        m = re.match(r'^(\d{2})-[a-z]+\.md$', os.path.basename(p))
        if not m: continue
        num = int(m.group(1))
        idx = order.index(num)
        link = lambda k: f"[{k:02d} {tabs[k][1]}](docs/{k:02d}-{tabs[k][0]}.md)"
        if idx == 0:
            newf = f"下一章：{link(order[1])}"
        elif idx == len(order) - 1:
            newf = f"上一章：{link(order[-2])}"
        else:
            newf = f"上一章：{link(order[idx-1])} · 下一章：{link(order[idx+1])}"
        text = open(p, 'rb').read().decode('utf-8')
        if not text.endswith('\n'): text += '\n'
        new_text, n = re.subn(r'^(?:上|下)一章：.*$',
                              lambda _: newf, text, flags=re.M)
        if n == 0:   # 无页脚则补（--- 分隔+页脚）
            new_text = text.rstrip('\n') + f"\n\n---\n\n{newf}\n"
        if new_text != text and APPLY:
            open(p, 'wb').write(new_text.encode('utf-8'))
    print('页脚重生成完成（63 序）')

# ---------- 4. 校验 ----------
def scan_pairs():
    """重命名前收集旧 (号,slug) 对（docs 与 examples 两界）。"""
    pairs = set()
    for d in os.listdir(os.path.join(ROOT, 'docs')):
        m = re.match(r'^(\d{2})-([a-z]+)\.md$', d)
        if m: pairs.add((int(m.group(1)), m.group(2)))
    for d in os.listdir(os.path.join(ROOT, 'examples')):
        m = re.match(r'^(\d{2})_([a-z]+)$', d)
        if m: pairs.add((int(m.group(1)), m.group(2)))
    return pairs

def verify(oldpairs):
    docs = sorted(d for d in os.listdir(os.path.join(ROOT, 'docs'))
                  if re.match(r'^\d{2}-', d))
    nums = [int(d[:2]) for d in docs]
    assert len(nums) == len(set(nums)), 'docs 章号重复！'
    print(f'docs 数 {len(nums)}，号位 min/max {min(nums)}/{max(nums)}')
    for n in GAPS:
        assert not any(str(n) == d[:2] for d in docs), f'{n} 号位应预留为空'
    print('新章号位 09/34/35/36/62 预留确认')
    bad = []
    for p in text_files():
        t = open(p, 'rb').read().decode('utf-8', errors='ignore')
        for m in re.finditer(r'(?<!\d)(\d{2})-([a-z]+)(?![\w-])', t):
            if (int(m.group(1)), m.group(2)) in oldpairs: bad.append((p, m.group(0)))
        for m in re.finditer(r'(?<![\w/])(\d{2})_([a-z]+)', t):
            if (int(m.group(1)), m.group(2)) in oldpairs: bad.append((p, m.group(0)))
    print('残留旧对:', bad[:10] if bad else '0')

OLDPAIRS = scan_pairs()
two_phase('ex'); two_phase('docs')
replace_texts()
if APPLY:
    regen_footers()
    verify(OLDPAIRS)
