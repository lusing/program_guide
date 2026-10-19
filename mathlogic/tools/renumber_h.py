# -*- coding: utf-8 -*-
"""mathlogic 全书重编号（第十五轮·郝兆宽轮，第十三次重编号，2-3 位统一单趟）。
插入新 78（可证性条件与 Löb）与新 91（普莱斯伯格阶梯）：旧 78-89 → 79-90、
旧 90-123 → 92-125。两阶段改名 + 单遍映射替换。
用法：python -I tools/renumber_h.py [--apply]；默认 dry-run。
"""
import os, re, sys, glob

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

MAP = {
    78:79, 79:80, 80:81, 81:82, 82:83, 83:84, 84:85, 85:86, 86:87, 87:88,
    88:89, 89:90, 90:92, 91:93, 92:94, 93:95, 94:96, 95:97, 96:98, 97:99,
    98:100, 99:101, 100:102, 101:103, 102:104, 103:105, 104:106, 105:107,
    106:108, 107:109, 108:110, 109:111, 110:112, 111:113, 112:114, 113:115,
    114:116, 115:117, 116:118, 117:119, 118:120, 119:121, 120:122, 121:123,
    122:124, 123:125,
}
APPLY = '--apply' in sys.argv

def two_phase(kind):
    base = os.path.join(ROOT, 'examples') if kind == 'ex' else os.path.join(ROOT, 'docs')
    pat = re.compile(r'^(\d{2,3})([_-])([a-z]+)(\.md)?$')
    dirs = []
    for name in os.listdir(base):
        m = pat.match(name)
        if m:
            dirs.append((name, int(m.group(1)), m.group(2), m.group(3), m.group(4) or ''))
    moves = [(name, f"{MAP[n]:0{3 if n>=100 else 2}d}{sep}{slug}{ext}")
             for name, n, sep, slug, ext in dirs if n in MAP]
    print(f'[{kind}] rename {len(moves)}')
    if not APPLY:
        for a, b in moves[:6]: print('  ', a, '->', b); 
        if len(moves) > 6: print('   ...')
        return
    for a, b in moves:
        os.rename(os.path.join(base, a), os.path.join(base, a + '.tmp~'))
    for a, b in moves:
        assert not os.path.exists(os.path.join(base, b)), b
        os.rename(os.path.join(base, a + '.tmp~'), os.path.join(base, b))

def sub3(num_str):
    n = int(num_str)
    if n in MAP:
        return f"{MAP[n]:0{3 if n>=100 else 2}d}"
    return num_str

def _enum_ch(m):
    toks = re.split(r'([/-])', m.group(1))
    return ''.join(sub3(t) if t.isdigit() else t for t in toks) + ' 章'

PATTERNS = [
    ('zh章',  re.compile(r'第\s*(\d{1,3})\s*章'),
        lambda m: f"第 {int(m.group(1)) if int(m.group(1)) not in MAP else MAP[int(m.group(1))]} 章"),
    ('enum章', re.compile(r'(?<!第 )(?<!\d)((?:\d{1,3}[/-]){0,4}\d{1,3})\s*章'), _enum_ch),
    ('doc文件', re.compile(r'(?<!\d)(\d{2,3})-([a-z]+)(?![\w-])'),
        lambda m: f"{sub3(m.group(1))}-{m.group(2)}"),
    ('ex文件', re.compile(r'(?<!\w)ex(\d{2,3})_([a-z]+)'),
        lambda m: f"ex{sub3(m.group(1))}_{m.group(2)}"),
    ('目录名', re.compile(r'(?<![\w/])(\d{2,3})_([a-z]+)'),
        lambda m: f"{sub3(m.group(1))}_{m.group(2)}"),
    ('session', re.compile(r'\bML(\d{2,3})\b'),
        lambda m: f"ML{sub3(m.group(1))}"),
    ('hol4',  re.compile(r'\bEx(\d{2,3})'),
        lambda m: f"Ex{sub3(m.group(1))}"),
    ('链接标签', re.compile(r'\[(\d{2,3}) ([^\]]*)\]\(([^)]*)\)'),
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
        nums = sorted(int(f[:3]) for f in os.listdir(os.path.join(ROOT, 'docs'))
                      if re.match(r'^\d', f))
        gaps = [n for n in range(1, 126) if n not in nums]
        print('docs 数', len(nums), '缺口（应为 78/91）:', gaps)
