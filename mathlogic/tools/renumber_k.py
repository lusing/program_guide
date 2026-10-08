# -*- coding: utf-8 -*-
"""mathlogic Marker 轮全书重编号（批次〇，一次性）：63→73。
目录改名 + **目录内文件改名**（.agda/.thy 模块名=文件名硬约束）+
单遍映射替换 + 页脚导航全量重生成。用法：
python -I tools/renumber_k.py [--apply]    # 默认 dry-run
"""
import os, re, sys, glob

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

MAP = {  # 旧章号 -> 新章号（01-25 恒等不列；全部单调增）
    26:30, 27:31, 28:32, 29:33, 30:34, 31:35, 32:36,
    33:37, 34:38, 35:39,                      # 旧 26-35：+4 / +7 分段
    36:43, 37:44, 38:48,                      # 算术化/不完备/SMT
    39:49, 40:50, 41:51, 42:52, 43:53, 44:54, 45:55, 46:56,
    47:57, 48:58, 49:59, 50:60, 51:61, 52:62, 53:63, 54:64,
    55:65, 56:66, 57:67, 58:68, 59:69, 60:70, 61:71, 62:72, 63:73,
}
GAPS = {26, 27, 28, 29, 40, 41, 42, 45, 46, 47}   # 本轮新建章（重排后应为空位）
NEW_TITLES = {                                     # 空位章的页脚标题
    26: ('categoricity', '完备理论与范畴性：Vaught 测试与 Ax 定理'),
    27: ('ultraproduct', '超积与 Łoś 定理'),
    28: ('quantelim', '量词消去：从 DLO 到代数闭域'),
    29: ('realclosed', '实闭域与 o-minimality'),
    40: ('undecidable', '通用性与不可判定性：停机、Rice 与递归定理'),
    41: ('hierarchy', '可枚举集与算术层级：Kolmogorov 随机性'),
    42: ('degrees', '图灵度与优先法'),
    45: ('diophantine', 'Hilbert 第十问题：Pell 与 DPRM'),
    46: ('epsilon', 'PA 与 ε₀：Hardy 层谱与 Goodstein'),
    47: ('models', '算术的模型：overspill 与 Paris–Harrington'),
}
APPLY = '--apply' in sys.argv

# ---------- 1. 目录改名（两阶段 .tmp~；按旧号降序防链式）----------
DIR_PAT = re.compile(r'^(\d{2})([_-])([a-z]+)$')

def rename_dirs():
    exdir = os.path.join(ROOT, 'examples')
    entries = []
    for name in os.listdir(exdir):
        m = DIR_PAT.match(name)
        if m and int(m.group(1)) in MAP:
            entries.append((int(m.group(1)), name))
    entries.sort(reverse=True)                       # 降序：63→73 最先
    print(f'[dirs] 待改名 {len(entries)}（降序执行）')
    for n, name in entries:
        new = f"{MAP[n]:02d}{name[2:]}"
        if not APPLY:
            print('  ', name, '->', new); continue
        assert not os.path.exists(os.path.join(exdir, new)), new
        os.rename(os.path.join(exdir, name), os.path.join(exdir, new))

# ---------- 2. 目录内文件改名（exNN_slug.ext → exMM_slug.ext）----------
FILE_PAT = re.compile(r'^ex(\d{2})_([a-z]+)\.(\w+)$')
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

# ---------- 3. 单遍文本替换（模式有序，输出不被后续重匹配）----------
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
    ('ex路径', re.compile(r'(?<!\w)examples/(\d{2})_'),     # examples/NN_ 路径形态
        lambda m: f"examples/{sub_mapped_num(m.group(1))}_"),
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

# ---------- 4. 页脚导航全量重生成（按 73 章新序，空位章用预留标题）----------
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
    print(f'页脚重生成完成（{len(order)} 序）')

# ---------- 5. 校验 ----------
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
    expect = set(range(1, 74)) - GAPS
    assert set(nums) == expect, f'号位差集: 缺 {sorted(expect - set(nums))[:8]} / 多 {sorted(set(nums) - expect)[:8]}'
    print(f'新章号位 {sorted(GAPS)} 预留确认；docs 连续 01-73 除空位')
    bad = []
    for p in text_files():
        t = open(p, 'rb').read().decode('utf-8', errors='ignore')
        for m in re.finditer(r'(?<!\d)(\d{2})-([a-z]+)(?![\w-])', t):
            if (int(m.group(1)), m.group(2)) in oldpairs: bad.append((p, m.group(0)))
        for m in re.finditer(r'(?<![\w/])(\d{2})_([a-z]+)', t):
            if (int(m.group(1)), m.group(2)) in oldpairs: bad.append((p, m.group(0)))
    print('残留旧对:', bad[:10] if bad else '0')
    assert not bad, '残留旧对必须为 0'

OLDPAIRS = scan_pairs()
rename_dirs()
rename_files()
replace_texts()
if APPLY:
    regen_footers()
    verify(OLDPAIRS)
