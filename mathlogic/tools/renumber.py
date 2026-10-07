# -*- coding: utf-8 -*-
"""mathlogic 全书重编号（批次〇，一次性）。
两阶段改名 + 单遍映射替换。用法：python -I tools/renumber.py [--apply]
默认 dry-run（只打印将发生的改动计数）；--apply 真正执行。
"""
import os, re, sys, shutil, glob

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

MAP = {  # 旧章号 -> 新章号（01-18 恒等不列）
    19:26, 20:27, 21:33, 22:34, 23:22, 24:35, 25:46, 26:58, 27:36, 28:37,
    29:38, 30:47, 31:43, 32:44, 33:45, 34:42, 35:19, 36:39, 37:40, 38:41,
    39:48, 40:30, 41:28, 42:31, 43:49, 44:50, 45:51, 46:52, 47:53, 48:54,
    49:55, 50:56, 51:57,
}
APPLY = '--apply' in sys.argv

# ---------- 1. 两阶段改名：examples/NN_slug 与 docs/NN-slug ----------
def two_phase(kind):
    dirs = []
    base = os.path.join(ROOT, 'examples') if kind == 'ex' else os.path.join(ROOT, 'docs')
    pat = re.compile(r'^(\d{2})([_-])([a-z]+)(\.md)?$')
    for name in os.listdir(base):
        m = pat.match(name)
        if m:
            n = int(m.group(1))
            dirs.append((name, n, m.group(2), m.group(3), m.group(4) or ''))
    moves = [(name, f"{MAP[n]:02d}{sep}{slug}{ext}") for name, n, sep, slug, ext in dirs if n in MAP]
    print(f'[{kind}] rename {len(moves)}')
    if not APPLY:
        for a, b in moves: print('  ', a, '->', b)
        return
    # phase 1: -> tmp~
    for a, b in moves:
        os.rename(os.path.join(base, a), os.path.join(base, a + '.tmp~'))
    # phase 2: tmp~ -> new
    for a, b in moves:
        assert not os.path.exists(os.path.join(base, b)), b
        os.rename(os.path.join(base, a + '.tmp~'), os.path.join(base, b))

# ---------- 2. 单遍文本替换 ----------
def sub_mapped_num(num_str, slug=None):
    n = int(num_str)
    return f"{MAP[n]:02d}" if n in MAP else num_str

def _enum_ch(m):
    toks = re.split(r'([/-])', m.group(1))
    return ''.join(sub_mapped_num(t) if t.isdigit() else t for t in toks) + ' 章'

PATTERNS = [
    # (名称, 正则, 回调)——顺序纪律：目标改写类（doc/ex/目录/session/hol4）在前，
    # 链接标签（只改标签号、保 target 原样）在最后，杜绝同区间二次改写。
    ('zh章',  re.compile(r'第\s*(\d{1,2})\s*章'),
        lambda m: f"第 {int(m.group(1)) if int(m.group(1)) not in MAP else MAP[int(m.group(1))]} 章"),
    ('enum章', re.compile(r'(?<!第 )(?<!\d)((?:\d{1,2}[/-]){0,4}\d{1,2})\s*章'), _enum_ch),
    ('doc文件', re.compile(r'(?<!\d)(\d{2})-([a-z]+)(?![\w-])'),
        lambda m: f"{sub_mapped_num(m.group(1), m.group(2))}-{m.group(2)}"),
    ('ex文件', re.compile(r'(?<!\w)ex(\d{2})_([a-z]+)'),
        lambda m: f"ex{sub_mapped_num(m.group(1))}_{m.group(2)}"),
    ('目录名', re.compile(r'(?<![\w/])(\d{2})_([a-z]+)'),
        lambda m: f"{sub_mapped_num(m.group(1))}_{m.group(2)}"),
    ('session', re.compile(r'\bML(\d{2})\b'),
        lambda m: f"ML{sub_mapped_num(m.group(1))}"),
    ('hol4',  re.compile(r'\bEx(\d{2})'),
        lambda m: f"Ex{sub_mapped_num(m.group(1))}"),
    ('链接标签', re.compile(r'\[(\d{2}) ([^\]]*)\]\(([^)]*)\)'),
        lambda m: f"[{sub_mapped_num(m.group(1))} {m.group(2)}]({m.group(3)})"),
]

def text_files():
    return (
        glob.glob(os.path.join(ROOT, 'docs', '*.md'))
        + [os.path.join(ROOT, f) for f in ('README.md', 'PLAN.md', 'CHEATSheet.md')]
        + glob.glob(os.path.join(ROOT, 'examples', 'ROOT'))
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

# ---------- 3. 校验 ----------
def verify():
    docs = sorted(os.listdir(os.path.join(ROOT, 'docs')))
    docs = [d for d in docs if re.match(r'^\d{2}-', d)]
    nums = [int(d[:2]) for d in docs]
    assert len(nums) == len(set(nums)), 'docs 章号重复！'
    print(f'docs 数 {len(nums)}，号位 min/max {min(nums)}/{max(nums)}')
    for n in (20, 21, 23, 24, 25, 29, 32):
        assert not any(str(n) == f'{d[:2]}' for d in docs), f'{n} 号位应预留为空'
    print('新章号位 20/21/23/24/25/29/32 预留确认')

two_phase('ex'); two_phase('docs')
replace_texts()
if APPLY: verify()
