# -*- coding: utf-8 -*-
"""mathlogic 重编号（第十五轮·补：三位章号 100-123 → 102-125）。
两阶段改名 + 单遍映射替换。用法：python -I tools/renumber_r3.py [--apply]
"""
import os, re, sys, glob

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

MAP = {  # 三位旧章号 -> 新章号
    100:102, 101:103, 102:104, 103:105, 104:106, 105:107, 106:108, 107:109,
    108:110, 109:111, 110:112, 111:113, 112:114, 113:115, 114:116, 115:117,
    116:118, 117:119, 118:120, 119:121, 120:122, 121:123, 122:124, 123:125,
}
APPLY = '--apply' in sys.argv

def two_phase(kind):
    base = os.path.join(ROOT, 'examples') if kind == 'ex' else os.path.join(ROOT, 'docs')
    pat = re.compile(r'^(\d{3})([_-])([a-z]+)(\.md)?$')
    dirs = []
    for name in os.listdir(base):
        m = pat.match(name)
        if m:
            dirs.append((name, int(m.group(1)), m.group(2), m.group(3), m.group(4) or ''))
    moves = [(name, f"{MAP[n]:03d}{sep}{slug}{ext}") for name, n, sep, slug, ext in dirs if n in MAP]
    print(f'[{kind}] rename {len(moves)}')
    if not APPLY:
        for a, b in moves: print('  ', a, '->', b)
        return
    for a, b in moves:
        os.rename(os.path.join(base, a), os.path.join(base, a + '.tmp~'))
    for a, b in moves:
        assert not os.path.exists(os.path.join(base, b)), b
        os.rename(os.path.join(base, a + '.tmp~'), os.path.join(base, b))

def sub3(num_str):
    n = int(num_str)
    return f"{MAP[n]:03d}" if n in MAP else num_str

def _enum_ch(m):
    toks = re.split(r'([/-])', m.group(1))
    return ''.join(sub3(t) if t.isdigit() else t for t in toks) + ' 章'

PATTERNS = [
    ('zh章',  re.compile(r'第\s*(\d{1,3})\s*章'),
        lambda m: f"第 {int(m.group(1)) if int(m.group(1)) not in MAP else MAP[int(m.group(1))]} 章"),
    ('enum章', re.compile(r'(?<!第 )(?<!\d)((?:\d{1,3}[/-]){0,4}\d{1,3})\s*章'), _enum_ch),
    ('doc文件', re.compile(r'(?<!\d)(1\d{2})-([a-z]+)(?![\w-])'),
        lambda m: f"{sub3(m.group(1))}-{m.group(2)}"),
    ('ex文件', re.compile(r'(?<!\w)ex(1\d{2})_([a-z]+)'),
        lambda m: f"ex{sub3(m.group(1))}_{m.group(2)}"),
    ('目录名', re.compile(r'(?<![\w/])(1\d{2})_([a-z]+)'),
        lambda m: f"{sub3(m.group(1))}_{m.group(2)}"),
    ('session', re.compile(r'\bML(1\d{2})\b'),
        lambda m: f"ML{sub3(m.group(1))}"),
    ('hol4',  re.compile(r'\bEx(1\d{2})'),
        lambda m: f"Ex{sub3(m.group(1))}"),
    ('链接标签', re.compile(r'\[(1\d{2}) ([^\]]*)\]\(([^)]*)\)'),
        lambda m: f"[{sub3(m.group(1))} {m.group(2)}]({m.group(3)})"),
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

if __name__ == '__main__':
    two_phase('ex'); two_phase('doc')
    replace_texts()
    if APPLY:
        ds = sorted(int(f[:3]) for f in os.listdir(os.path.join(ROOT, 'docs')) if re.match(r'^\d{3}-', f))
        print('三位 docs:', ds[:3], '...', ds[-3:])
