# -*- coding: utf-8 -*-
"""mathlogic 第十三轮（Prawitz 卷轮）全书重编号：114→123。
九章整块插位 34-42（广义消去/Zucker/标号相等/一般逻辑/λ-立方/
线性逻辑/粗糙集与双直觉/归约分解/证明论语义），排在 33 完备性之后。
MAP 单区间 {34..114}→+9（较上轮双区间简单）；ML/Ex 会话/模块模式
升 \d{2,3}（本轮 96_hoare→105 涉及三位号）。用法：
python -I tools/renumber_p.py [--apply]    # 默认 dry-run
"""
import os, re, sys, glob

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

MAP = {  # 旧章号 -> 新章号（01-33 恒等不列；单区间）
}
for _n in range(34, 115):                               # 34-114：+9（114-wrapup 也在内！）
    MAP[_n] = _n + 9
GAPS = {34, 35, 36, 37, 38, 39, 40, 41, 42}       # 本轮新建章（重排后应为空位）
NEW_TITLES = {                     # 空位章的页脚标题
    34: ('ge',        '广义消去规则与高层次规则'),
    35: ('zucker',    'Zucker 对应：截消与正规化'),
    36: ('lndequality','标号演绎与相等：缺失的实体'),
    37: ('generally', '「一般」逻辑与滤子'),
    38: ('lcube',     'λ-立方与定理证明器'),
    39: ('linear',    '线性逻辑的自然演绎与范畴语义'),
    40: ('roughset',  '粗糙集、语用力与双直觉主义'),
    41: ('ars',       '归约分解：抽象归约系统'),
    42: ('ptval',     '证明论语义与完备性猜想'),
}
APPLY = '--apply' in sys.argv


# ---------- 1. 目录内文件改名（先于目录改名！目录此刻还是旧号）----------
DIR_PAT = re.compile(r'^(\d{2,3})([_-])([a-z][a-z0-9]*)$')
FILE_PAT = re.compile(r'^ex(\d{2,3})_([a-z][a-z0-9]*)\.(\w+)$')
STALE_EXT = {'.agdai', '.vo', '.vok', '.vos', '.glob', '.aux', '.hammer',
             '.ival', '.o', '.hi'}

def rename_files():
    exdir = os.path.join(ROOT, 'examples')
    total = 0
    for d in sorted(os.listdir(exdir)):
        dp = os.path.join(exdir, d)
        if not os.path.isdir(dp):
            continue
        dm = DIR_PAT.match(d)
        newnum = MAP.get(int(dm.group(1))) if dm else None
        for f in sorted(os.listdir(dp)):
            fp = os.path.join(dp, f)
            ext = os.path.splitext(f)[1]
            if ext in STALE_EXT:                     # 编译产物：直接删
                if APPLY: os.remove(fp)
                continue
            m = FILE_PAT.match(f)
            if m and newnum:
                nf = f"ex{newnum:02d}_{m.group(2)}.{m.group(3)}"
                if not APPLY:
                    print(f'   {d}/{f} -> {nf}')
                else:
                    assert not os.path.exists(os.path.join(dp, nf))
                    os.rename(fp, os.path.join(dp, nf))
                total += 1
    print(f'[files] 章内文件改名 {total}（含模块名=文件名的 .agda/.thy）')

# ---------- 2. examples 目录改名（按旧号降序防链式）----------
def rename_dirs():
    exdir = os.path.join(ROOT, 'examples')
    entries = []
    for name in os.listdir(exdir):
        m = DIR_PAT.match(name)
        if m and int(m.group(1)) in MAP:
            entries.append((int(m.group(1)), name))
    entries.sort(reverse=True)
    print(f'[dirs] 待改名 {len(entries)}（降序执行）')
    for n, name in entries:
        pre, rest = name.split("_", 1)                   # 3 位号不能按 name[2:] 切片
        new = f"{MAP[n]:02d}_{rest}"
        if not APPLY:
            print('  ', name, '->', new); continue
        assert not os.path.exists(os.path.join(exdir, new)), new
        os.rename(os.path.join(exdir, name), os.path.join(exdir, new))

# ---------- 3. docs 文件改名（NN-slug.md；按旧号降序）----------
DOC_PAT = re.compile(r'^(\d{2,3})-([a-z][a-z0-9]*)\.md$')

def rename_docs():
    ddir = os.path.join(ROOT, 'docs')
    entries = []
    for name in os.listdir(ddir):
        m = DOC_PAT.match(name)
        if m and int(m.group(1)) in MAP:
            entries.append((int(m.group(1)), name))
    entries.sort(reverse=True)
    print(f'[docs] 待改名 {len(entries)}（降序执行）')
    for n, name in entries:
        pre, rest = name.split("-", 1)                   # 3 位号不能按 name[3:] 切片
        new = f"{MAP[n]:02d}-{rest}"
        if not APPLY:
            print('  ', name, '->', new); continue
        assert not os.path.exists(os.path.join(ddir, new)), new
        os.rename(os.path.join(ddir, name), os.path.join(ddir, new))

# ---------- 4. 单遍文本替换（模式有序，输出不被后续重匹配）----------
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
    ('zh章组', re.compile(r'第\s*((?:\d{1,3}\s*[/-]\s*){1,4}\d{1,3})\s*章'), _zh_group),
    ('zh章',   re.compile(r'第\s*(\d{1,3})\s*章'), _zh),
    ('enum章', re.compile(r'(?<!第 )(?<!\d)((?:\d{1,3}[/-]){0,4}\d{1,3})\s*章'), _enum_ch),
    ('表行',   re.compile(r'(?m)^\| (\d{2,3}) \|'),          # PLAN/README 章表行首
        lambda m: f"| {sub_mapped_num(m.group(1))} |"),
    ('ex路径', re.compile(r'(?<!\w)examples/(\d{2,3})_'),     # examples/NN_ 路径形态
        lambda m: f"examples/{sub_mapped_num(m.group(1))}_"),
    ('doc文件', re.compile(r'(?<!\d)(\d{2,3})-([a-z][a-z0-9]*)(?![\w-])'),
        lambda m: f"{sub_mapped_num(m.group(1))}-{m.group(2)}"),
    ('ex文件', re.compile(r'(?<!\w)ex(\d{2,3})_([a-z][a-z0-9]*)'),
        lambda m: f"ex{sub_mapped_num(m.group(1))}_{m.group(2)}"),
    ('目录名', re.compile(r'(?<![\w/])(\d{2,3})_([a-z][a-z0-9]*)'),
        lambda m: f"{sub_mapped_num(m.group(1))}_{m.group(2)}"),
    ('session', re.compile(r'\bML(\d{2,3})\b'),
        lambda m: f"ML{sub_mapped_num(m.group(1))}"),
    ('hol4',   re.compile(r'\bEx(\d{2,3})'),
        lambda m: f"Ex{sub_mapped_num(m.group(1))}"),
    ('链接标签', re.compile(r'\[(\d{2,3}) ([^\]]*)\]\(([^)]*)\)'),
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

# ---------- 5. 页脚导航全量重生成（按 114 章新序，空位章用预留标题）----------
def chapter_table():
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
    return tabs

def regen_footers():
    tabs = chapter_table()
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
        new_text, n = re.subn(r'^(?:上|下)一章：.*$',
                              lambda _: newf, text, flags=re.M)
        if n == 0:   # 无页脚则补（--- 分隔+页脚）
            new_text = text.rstrip('\n') + f"\n\n---\n\n{newf}\n"
        if new_text != text and APPLY:
            open(p, 'wb').write(new_text.encode('utf-8'))
    print(f'页脚重生成完成（{len(order)} 序）')

# ---------- 6. 校验 ----------
def scan_pairs():
    """重命名前收集旧 (号,slug) 对（docs 与 examples 两界）。"""
    pairs = set()
    for d in os.listdir(os.path.join(ROOT, 'docs')):
        m = re.match(r'^(\d{2,3})-([a-z][a-z0-9]*)\.md$', d)
        if m and int(m.group(1)) in MAP:   # 只收号真正变了的（01-33 不动勿伤）
            pairs.add((int(m.group(1)), m.group(2)))
    for d in os.listdir(os.path.join(ROOT, 'examples')):
        m = re.match(r'^(\d{2,3})_([a-z][a-z0-9]*)$', d)
        if m and int(m.group(1)) in MAP:
            pairs.add((int(m.group(1)), m.group(2)))
    return pairs

def verify(oldpairs):
    docs = sorted(d for d in os.listdir(os.path.join(ROOT, 'docs'))
                  if re.match(r'^\d{2,3}-', d))
    nums = [int(d.split('-')[0]) for d in docs]
    assert len(nums) == len(set(nums)), 'docs 章号重复！'
    print(f'docs 数 {len(nums)}，号位 min/max {min(nums)}/{max(nums)}')
    expect = set(range(1, 124)) - GAPS
    assert set(nums) == expect, f'号位差集: 缺 {sorted(expect - set(nums))[:8]} / 多 {sorted(set(nums) - expect)[:8]}'
    print(f'新章号位 {sorted(GAPS)} 预留确认；docs 连续 01-123 除空位')
    bad = []
    for p in text_files():
        t = open(p, 'rb').read().decode('utf-8', errors='ignore')
        for m in re.finditer(r'(?<!\d)(\d{2,3})-([a-z][a-z0-9]*)(?![\w-])', t):
            if (int(m.group(1)), m.group(2)) in oldpairs: bad.append((p, m.group(0)))
        for m in re.finditer(r'(?<![\w/])(\d{2,3})_([a-z][a-z0-9]*)', t):
            if (int(m.group(1)), m.group(2)) in oldpairs: bad.append((p, m.group(0)))
    print('残留旧对:', bad[:10] if bad else '0')
    assert not bad, '残留旧对必须为 0'

OLDPAIRS = scan_pairs()
rename_files()      # 先文件（目录尚为旧号——根治双重改名）
rename_dirs()       # 再目录
rename_docs()       # docs 文件名
replace_texts()
if APPLY:
    regen_footers()
    verify(OLDPAIRS)
