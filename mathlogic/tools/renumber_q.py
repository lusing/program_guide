# -*- coding: utf-8 -*-
"""mathlogic 第十四轮：全书逻辑重排（非单调映射，两阶段哨兵协议）。
十四年来重排都是单调 MAP（降序改名防链式）；本轮按教学逻辑重排，
映射非单调，故：
  盘上：NN_slug → qz<NN>_slug → 新NN_slug（两阶段，无碰撞）；
  文本：旧号 → ⟦N⟧ 哨兵 → 新号（全部数字模式加 (?<!⟦) 防双包装）；
  页脚：按新序全量重生成。
用法：python -I tools/renumber_q.py [--apply]   # 默认 dry-run
"""
import os, re, sys, glob

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
APPLY = '--apply' in sys.argv

# new ← old（仅移动对；恒等不列）
PAIRS = [
    (22, 23), (23, 24), (24, 25), (25, 30), (27, 28), (28, 29), (29, 31),
    (30, 32), (31, 33), (32, 22), (33, 27),
    (36, 41), (37, 36), (38, 37), (41, 38),
    (43, 44), (44, 45), (45, 46), (46, 47), (47, 48), (48, 49), (49, 50),
    (50, 51), (51, 52), (52, 53), (53, 54), (54, 55), (55, 56), (56, 57),
    (57, 58), (58, 59),
    (59, 60), (60, 61), (61, 62),
    (62, 64), (64, 65), (65, 66), (66, 67),
    (67, 69), (68, 70), (69, 71), (70, 72), (71, 73), (72, 74), (73, 75),
    (74, 76), (75, 77), (76, 78), (77, 79),
    (78, 43),
    (79, 83), (80, 84), (81, 85), (82, 88), (83, 89), (84, 86), (85, 87),
    (86, 80), (87, 81), (88, 82),
    (89, 90), (90, 91),
    (91, 101), (92, 102), (93, 103), (94, 104), (95, 93), (96, 92),
    (97, 95), (98, 96), (99, 97), (100, 98), (101, 99), (102, 100),
    (103, 94),
    (104, 105), (105, 106), (106, 68),
    (113, 119), (114, 113), (115, 114), (116, 120), (117, 121), (118, 122),
    (119, 115), (120, 116), (121, 117), (122, 118),
]
NEW2OLD = dict(PAIRS)
OLD2NEW = {o: n for n, o in PAIRS}

# 完备性校验：移动对 {old} 与恒等 {1..123}\\moved 恰好覆盖 1..123
moved_old = set(OLD2NEW)
moved_new = set(NEW2OLD)
identity = set(range(1, 124)) - moved_old
assert moved_new | identity == set(range(1, 124)), '映射不覆盖 1..123'
assert len(PAIRS) == len(OLD2NEW) == len(NEW2OLD), '映射非单射'

DIR_PAT = re.compile(r'^(\d{2,3})([_-])([a-z][a-z0-9]*)$')
FILE_PAT = re.compile(r'^ex(\d{2,3})_([a-z][a-z0-9]*)\.(\w+)$')
DOC_PAT = re.compile(r'^(\d{2,3})-([a-z][a-z0-9]*)\.md$')
STALE_EXT = {'.agdai', '.vo', '.vok', '.vos', '.glob', '.aux', '.hammer',
             '.ival', '.o', '.hi'}

SENT = '⟦%s⟧'


def tmp_name(n):
    return 'qz%03d' % n


# ---------- 阶段 1：全部目录/文件/docs → 临时名 ----------
def stage1():
    exdir = os.path.join(ROOT, 'examples')
    ddir = os.path.join(ROOT, 'docs')
    nd = nf = 0
    # (a) 先改各目录**内部文件**（目录名此刻还是旧号，路径一致）
    for d in sorted(os.listdir(exdir)):
        dp = os.path.join(exdir, d)
        if not os.path.isdir(dp):
            continue
        for f in sorted(os.listdir(dp)):
            fp = os.path.join(dp, f)
            if os.path.splitext(f)[1] in STALE_EXT:
                if APPLY: os.remove(fp)
                continue
            fm = FILE_PAT.match(f)
            if fm and int(fm.group(1)) in OLD2NEW:
                if APPLY:
                    os.rename(fp, os.path.join(dp, 'ex%s_%s.%s'
                              % (tmp_name(int(fm.group(1))), fm.group(2), fm.group(3))))
                nf += 1
    # (b) 再改目录名（快照迭代，跳过中途消失者）
    for d in sorted(os.listdir(exdir)):
        dp = os.path.join(exdir, d)
        if not os.path.isdir(dp):
            continue
        m = DIR_PAT.match(d)
        if m and int(m.group(1)) in OLD2NEW:
            if APPLY:
                os.rename(dp, os.path.join(exdir, tmp_name(int(m.group(1))) + '_' + m.group(3)))
            nd += 1
    # (c) docs 文件名
    for f in sorted(os.listdir(ddir)):
        m = DOC_PAT.match(f)
        if m and int(m.group(1)) in OLD2NEW:
            if APPLY:
                os.rename(os.path.join(ddir, f),
                          os.path.join(ddir, '%s-%s.md' % (tmp_name(int(m.group(1))), m.group(2))))
            nd += 1
    print(f'[stage1] 目录/文档 {nd}、文件 {nf} → 临时名')


# ---------- 阶段 2：临时名 → 新号 ----------
def stage2():
    exdir = os.path.join(ROOT, 'examples')
    ddir = os.path.join(ROOT, 'docs')
    TMP_PAT = re.compile(r'^qz(\d{3})([_-])([a-z][a-z0-9]*)$')
    TFILE_PAT = re.compile(r'^exqz(\d{3})_([a-z][a-z0-9]*)\.(\w+)$')
    nd = nf = 0
    for d in sorted(os.listdir(exdir)):
        dp = os.path.join(exdir, d)
        if not os.path.isdir(dp):
            continue
        m = TMP_PAT.match(d)
        if m:
            old = int(m.group(1))
            dst = '%02d_%s' % (OLD2NEW[old], m.group(3))
            if APPLY:
                assert not os.path.exists(os.path.join(exdir, dst)), dst
                os.rename(dp, os.path.join(exdir, dst))
            nd += 1
            continue
        for f in sorted(os.listdir(dp)):
            fm = TFILE_PAT.match(f)
            if fm:
                old = int(fm.group(1))
                nf_ = 'ex%02d_%s.%s' % (OLD2NEW[old], fm.group(2), fm.group(3))
                if APPLY:
                    os.rename(os.path.join(dp, f), os.path.join(dp, nf_))
                nf += 1
    for f in sorted(os.listdir(ddir)):
        m = re.match(r'^qz(\d{3})-([a-z][a-z0-9]*)\.md$', f)
        if m:
            old = int(m.group(1))
            dst = '%02d-%s.md' % (OLD2NEW[old], m.group(2))
            if APPLY:
                assert not os.path.exists(os.path.join(ddir, dst)), dst
                os.rename(os.path.join(ddir, f), os.path.join(ddir, dst))
            nd += 1
    print(f'[stage2] 临时名 → 新号：目录/文档 {nd}、文件 {nf}')


# ---------- 文本两阶段 ----------
def sub_old(num_str):
    n = int(num_str)
    return SENT % n if n in OLD2NEW else num_str

def _zh_group(m):
    toks = re.split(r'([/-])', m.group(1))
    return '第 ' + ''.join(sub_old(t) if t.isdigit() else t for t in toks) + ' 章'

def _zh(m):
    n = int(m.group(1))
    return f"第 {SENT % n if n in OLD2NEW else n} 章"

def _enum_ch(m):
    toks = re.split(r'([/-])', m.group(1))
    return ''.join(sub_old(t) if t.isdigit() else t for t in toks) + ' 章'

# 每个数字组前加 (?<!⟦)，防哨兵被后续模式二次包装
PATTERNS = [
    ('zh章组', re.compile(r'第\s*((?<!⟦)(?:\d{1,3}\s*[/-]\s*){1,4}(?<!⟦)\d{1,3})\s*章'), _zh_group),
    ('zh章',   re.compile(r'第\s*((?<!⟦)\d{1,3})\s*章'), _zh),
    ('enum章', re.compile(r'(?<!第 )(?<!\d)((?:(?<!⟦)\d{1,3}[/-]){0,4}(?<!⟦)\d{1,3})\s*章'), _enum_ch),
    ('表行',   re.compile(r'(?m)^\| ((?<!⟦)\d{2,3}) \|'),
        lambda m: '| ' + sub_old(m.group(1)) + ' |'),
    ('ex路径', re.compile(r'(?<!\w)examples/((?<!⟦)\d{2,3})_'),
        lambda m: 'examples/' + sub_old(m.group(1)) + '_'),
    ('doc文件', re.compile(r'(?<!\d)((?<!⟦)\d{2,3})-([a-z][a-z0-9]*)(?![\w-])'),
        lambda m: sub_old(m.group(1)) + '-' + m.group(2)),
    ('ex文件', re.compile(r'(?<!\w)ex((?<!⟦)\d{2,3})_([a-z][a-z0-9]*)'),
        lambda m: 'ex' + sub_old(m.group(1)) + '_' + m.group(2)),
    ('目录名', re.compile(r'(?<![\w/])((?<!⟦)\d{2,3})_([a-z][a-z0-9]*)'),
        lambda m: sub_old(m.group(1)) + '_' + m.group(2)),
    ('session', re.compile(r'\bML((?<!⟦)\d{2,3})\b'),
        lambda m: 'ML' + sub_old(m.group(1))),
    ('hol4',   re.compile(r'\bEx((?<!⟦)\d{2,3})'),
        lambda m: 'Ex' + sub_old(m.group(1))),
    ('链接标签', re.compile(r'\[((?<!⟦)\d{2,3}) ([^\]]*)\]\(([^)]*)\)'),
        lambda m: '[' + sub_old(m.group(1)) + ' ' + m.group(2) + '](' + m.group(3) + ')'),
]

def text_files():
    return (
        glob.glob(os.path.join(ROOT, 'docs', '*.md'))
        + [os.path.join(ROOT, f) for f in ('README.md', 'PLAN.md', 'CHEATSheet.md')]
        + [os.path.join(ROOT, 'examples', 'ROOT')]
        + [p for ext in ('*.v', '*.agda', '*.lean', '*.thy', '*.sml', '*.pl')
            for p in glob.glob(os.path.join(ROOT, 'examples', '**', ext), recursive=True)]
    )

def stageA():
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
    print('阶段A 哨兵化统计:', stats)

SENT_RX = re.compile(r'⟦(\d{2,3})⟧')

def stageB():
    n_tot = 0
    for path in text_files():
        try:
            text = open(path, 'rb').read().decode('utf-8')
        except UnicodeDecodeError:
            continue
        orig = text
        text, n = SENT_RX.subn(lambda m: '%02d' % OLD2NEW[int(m.group(1))], text)
        n_tot += n
        if text != orig and APPLY:
            open(path, 'wb').write(text.encode('utf-8'))
    print(f'阶段B 哨兵→新号：{n_tot} 处')


# ---------- 页脚重生成 ----------
def regen_footers():
    tabs = {}
    for p in glob.glob(os.path.join(ROOT, 'docs', '*.md')):
        m = re.match(r'^(\d{2,3})-([a-z][a-z0-9]*)\.md$', os.path.basename(p))
        if not m: continue
        num, slug = int(m.group(1)), m.group(2)
        head = open(p, 'rb').read().decode('utf-8').split('\n', 1)[0]
        hm = re.match(r'# 第 \d{2,3} 章 (.+)$', head.strip())
        tabs[num] = (slug, hm.group(1).strip() if hm else slug)
    order = sorted(tabs)
    for p in glob.glob(os.path.join(ROOT, 'docs', '*.md')):
        m = re.match(r'^(\d{2,3})-[a-z][a-z0-9]*\.md$', os.path.basename(p))
        if not m: continue
        num = int(m.group(1))
        if num not in tabs: continue
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
    print(f'页脚重生成（{len(order)} 序）')


# ---------- 校验 ----------
def verify():
    ddir = os.path.join(ROOT, 'docs')
    nums = sorted(int(d.split('-')[0]) for d in os.listdir(ddir)
                  if re.match(r'^\d{2,3}-', d))
    assert len(nums) == len(set(nums)), 'docs 章号重复！'
    assert set(nums) == set(range(1, 124)), f'号位差集: 缺 {sorted(set(range(1,124))-set(nums))[:8]}'
    print('docs 01-123 连续无重 ✓')
    bad = []
    for path in text_files():
        t = open(path, 'rb').read().decode('utf-8', errors='ignore')
        if '⟦' in t or '⟧' in t:
            bad.append((path, '哨兵残留'))
        if 'qz' in os.path.basename(path):
            bad.append((path, '临时名残留'))
    print('残留:', bad[:6] if bad else '0')
    assert not bad


if __name__ == '__main__':
    stage1()
    stage2()
    stageA()
    stageB()
    if APPLY:
        regen_footers()
        verify()
        print('APPLY 完成')
    else:
        print('（dry-run：盘上阶段未执行，文本统计基于现状）')
