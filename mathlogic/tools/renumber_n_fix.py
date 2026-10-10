# -*- coding: utf-8 -*-
"""renumber_n.py 首跑修复：MAP 漏 109（range(26,109) 上界开区间）、
rename_docs/rename_dirs 对 3 位章号用 name[3:]/name[2:] 切片产生
'105--paradox.md'/'1050_paradox' 类坏名。正文替换侧当时已全部正确
（100→105 等单横线/单下划线），故本脚本只做四件事：
1) 坏名文件/目录正名（9 docs 双横线 + 9 examples 目录畸形）；
2) 109-wrapup → 114-wrapup（文件名+全部文本引用，MAP={109:114}）；
3) 页脚按 114 章全表重生成（首跑的表缺 9 章记录）；
4) 校验：docs = 1..114 除空位 {18,19,20,21,30}，无残留旧对。
用法：python -I tools/renumber_n_fix.py [--apply]
"""
import os, re, sys, glob

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
APPLY = '--apply' in sys.argv

DIR_FIX = {
    '1050_paradox': '105_paradox', '1061_funequiv': '106_funequiv',
    '1072_posetlattice': '107_posetlattice', '1083_boole': '108_boole',
    '1094_alglogic': '109_alglogic', '1105_graphs': '110_graphs',
    '1116_nbg': '111_nbg', '1127_axioms': '112_axioms',
    '1138_identity': '113_identity',
}
DOC_FIX = {f'{k}--{s}.md': f'{k}-{s}.md' for k, s in
           [('105','paradox'),('106','funequiv'),('107','posetlattice'),
            ('108','boole'),('109','alglogic'),('110','graphs'),
            ('111','nbg'),('112','axioms'),('113','identity')]}
NEW_TITLES = {
    18: ('ljpm',    'LJpm 多后件矢列：饱和与典范模型'),
    19: ('matrix',  '有限矩阵与拓扑完备性'),
    20: ('search',  '证明搜索：LJpm* 表列与判定程序'),
    21: ('iinterp', '直觉主义插值与 Beth 可定义性'),
    30: ('ipred',   '直觉主义谓词逻辑：扩张域与传递规则'),
}
MAP109 = {109: 114}

def sub109(num_str):
    n = int(num_str)
    return f"{MAP109[n]:02d}" if n in MAP109 else num_str

PATTERNS = [
    ('zh章',   re.compile(r'第\s*(109)\s*章'), lambda m: '第 114 章'),
    ('enum章', re.compile(r'(?<!第 )(?<!\d)(109)\s*章'), lambda m: '114 章'),
    ('表行',   re.compile(r'(?m)^\| (109) \|'), lambda m: '| 114 |'),
    ('ex路径', re.compile(r'(?<!\w)examples/(109)_'), lambda m: 'examples/114_'),
    ('doc文件', re.compile(r'(?<!\d)(109)-(wrapup)(?![\w-])'), lambda m: '114-wrapup'),
    ('目录名', re.compile(r'(?<![\w/])(109)_([a-z][a-z0-9]*)'), lambda m: f"114_{m.group(2)}"),
    ('链接标签', re.compile(r'\[(109) ([^\]]*)\]\(([^)]*)\)'),
        lambda m: f"[114 {m.group(2)}]({m.group(3)})"),
]

def text_files():
    return (glob.glob(os.path.join(ROOT, 'docs', '*.md'))
            + [os.path.join(ROOT, f) for f in ('README.md', 'PLAN.md', 'CHEATSheet.md')]
            + [os.path.join(ROOT, 'examples', 'ROOT')]
            + [p for ext in ('*.v', '*.agda', '*.lean', '*.thy', '*.sml', '*.pl')
                for p in glob.glob(os.path.join(ROOT, 'examples', '**', ext), recursive=True)])

# 1-2. 文件名正名
def fix_names():
    exdir, ddir = os.path.join(ROOT, 'examples'), os.path.join(ROOT, 'docs')
    for old, new in DIR_FIX.items():
        op, np = os.path.join(exdir, old), os.path.join(exdir, new)
        print(' dir', old, '->', new)
        if APPLY: assert not os.path.exists(np); os.rename(op, np)
    for old, new in DOC_FIX.items():
        op, np = os.path.join(ddir, old), os.path.join(ddir, new)
        print(' doc', old, '->', new)
        if APPLY: assert not os.path.exists(np); os.rename(op, np)
    op, np = os.path.join(ddir, '109-wrapup.md'), os.path.join(ddir, '114-wrapup.md')
    if os.path.exists(op):
        print(' doc 109-wrapup.md -> 114-wrapup.md')
        if APPLY: assert not os.path.exists(np); os.rename(op, np)

# 3. 文本 109→114
def fix_texts():
    stats = {}
    for path in text_files():
        text = open(path, 'rb').read().decode('utf-8')
        orig = text
        for name, rx, cb in PATTERNS:
            text, n = rx.subn(cb, text)
            if n: stats[name] = stats.get(name, 0) + n
        if text != orig and APPLY:
            open(path, 'wb').write(text.encode('utf-8'))
    print('109→114 替换统计:', stats)

# 4. 页脚重生成（114 全表）
def regen_footers():
    tabs = {}
    for p in glob.glob(os.path.join(ROOT, 'docs', '*.md')):
        m = re.match(r'^(\d{2,3})-([a-z][a-z0-9]*)\.md$', os.path.basename(p))
        if not m: continue
        num, slug = int(m.group(1)), m.group(2)
        head = open(p, 'rb').read().decode('utf-8').split('\n', 1)[0]
        hm = re.match(r'# 第 \d{2,3} 章 (.+)$', head.strip())
        tabs[num] = (slug, hm.group(1).strip() if hm else slug)
    for num, (slug, title) in NEW_TITLES.items():
        tabs[num] = (slug, title)
    order = sorted(tabs)
    assert order == list(range(1, 115)), f'表序异常: {order[:3]}...{order[-3:]} len={len(order)}'
    for p in glob.glob(os.path.join(ROOT, 'docs', '*.md')):
        m = re.match(r'^(\d{2,3})-[a-z][a-z0-9]*\.md$', os.path.basename(p))
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
        new_text, n = re.subn(r'^(?:上|下)一章：.*$', lambda _: newf, text, flags=re.M)
        if n == 0:
            new_text = text.rstrip('\n') + f"\n\n---\n\n{newf}\n"
        if new_text != text and APPLY:
            open(p, 'wb').write(new_text.encode('utf-8'))
    print(f'页脚重生成完成（{len(order)} 序）')

# 5. 校验
def verify():
    docs = sorted(d for d in os.listdir(os.path.join(ROOT, 'docs'))
                  if re.match(r'^\d{2,3}-', d))
    nums = [int(d.split('-')[0]) for d in docs]
    assert len(nums) == len(set(nums)), 'docs 章号重复！'
    gaps = {18, 19, 20, 21, 30}
    expect = set(range(1, 115)) - gaps
    assert set(nums) == expect, f'缺 {sorted(expect - set(nums))[:8]} / 多 {sorted(set(nums) - expect)[:8]}'
    print(f'docs 数 {len(nums)}；01-114 连续除空位 {sorted(gaps)} ✓')
    exs = sorted(d for d in os.listdir(os.path.join(ROOT, 'examples'))
                 if re.match(r'^\d{2,3}_', d))
    enums = [int(d.split('_')[0]) for d in exs]
    assert len(enums) == len(set(enums)), 'examples 章号重复！'
    assert set(enums) == expect, 'examples 号位与 docs 不一致'
    bad = []
    stale = set(DIR_FIX) | set(DOC_FIX) | {'109-wrapup', '114--wrapup'}
    for p in text_files():
        t = open(p, 'rb').read().decode('utf-8', errors='ignore')
        for s in stale:
            if s in t: bad.append((p, s))
    assert not bad, f'残留坏名: {bad[:6]}'
    print('残留坏名: 0')

fix_names()
fix_texts()
if APPLY:
    regen_footers()
    verify()
