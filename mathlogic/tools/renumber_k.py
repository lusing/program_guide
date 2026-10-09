# -*- coding: utf-8 -*-
"""mathlogic 第九轮（马明辉轮）全书重编号（批次〇，一次性）：86→92。
目录改名 + 目录内文件改名（.agda/.thy 模块名=文件名硬约束）+ docs 文件改名
+ 单遍映射替换 + PLAN 章表表行 + 页脚导航全量重生成。用法：
python -I tools/renumber_k.py [--apply]    # 默认 dry-run

历轮教训全带上（第七轮定稿）：
1) docs 目录改名必须做（rename_docs）；
2) 双重改名 bug——文件改名必须先于目录改名（文件在旧号目录内查旧号 MAP；
   若目录先改，新号本身也在 MAP 里会被二次改）；
3) PLAN 章表 `| NN |` 行格式（表行模式）；
4) verify 残留=未映射章合法页脚互报——过滤 n∈MAP 后真残留必须=0。
"""
import os, re, sys, glob

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

MAP = {  # 旧章号 -> 新章号（01-02 恒等不列；全部单调增）
    3:4, 4:5, 5:6, 6:7, 7:8, 8:9, 9:10, 10:11, 11:12, 12:13, 13:14,
                                                    # 命题证明论块：+1（让位 3 费奇）
    14:16, 15:17, 16:18, 17:19, 18:20, 19:21, 20:22, 21:23, 22:24,
    23:25, 24:26, 25:27, 26:28, 27:29, 28:30, 29:31, 30:32, 31:33,
    32:34, 33:35, 34:36, 35:37, 36:38, 37:39, 38:40, 39:41, 40:42,
    41:43, 42:44, 43:45, 44:46, 45:47, 46:48, 47:49, 48:50, 49:51,
    50:52, 51:53, 52:54, 53:55, 54:56,              # 中段：+2（让位 15 正规化）
    55:59, 56:60, 57:61, 58:62, 59:63, 60:64, 61:65, 62:66, 63:67,
    64:68, 65:69, 66:70, 67:71, 68:72,              # 证明论二块尾：+3（让位 57/58）
    69:74, 70:75, 71:76, 72:77, 73:78, 74:79, 75:80, 76:81, 77:82,
    78:83, 79:84, 80:85, 81:86,                     # 验证+离散块：+4（让位 73 模态证明论）
    82:88, 83:89, 84:90, 85:91, 86:92,              # 同一性/收官：+5（让位 87 代数逻辑）
}
GAPS = {3, 15, 57, 58, 73, 87}   # 本轮新建章（重排后应为空位）
NEW_TITLES = {                     # 空位章的页脚标题
    3:  ('fitch',          '费奇式自然演绎'),
    15: ('normalization',  '正规化定理'),
    57: ('structural',     '矢列演算的结构规则谱系'),
    58: ('interpolation',  'Craig 插值定理'),
    73: ('modalpt',        '模态证明论：矢列与超矢列'),
    87: ('alglogic',       '代数逻辑：后承演算与德摩根代数'),
}
APPLY = '--apply' in sys.argv

# ---------- 1. 目录内文件改名（先于目录改名！目录此刻还是旧号）----------
DIR_PAT = re.compile(r'^(\d{2})([_-])([a-z][a-z0-9]*)$')
FILE_PAT = re.compile(r'^ex(\d{2})_([a-z][a-z0-9]*)\.(\w+)$')
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

# ---------- 2. examples 目录改名（两阶段 .tmp~；按旧号降序防链式）----------
def rename_dirs():
    exdir = os.path.join(ROOT, 'examples')
    entries = []
    for name in os.listdir(exdir):
        m = DIR_PAT.match(name)
        if m and int(m.group(1)) in MAP:
            entries.append((int(m.group(1)), name))
    entries.sort(reverse=True)                       # 降序：73→80 最先
    print(f'[dirs] 待改名 {len(entries)}（降序执行）')
    for n, name in entries:
        new = f"{MAP[n]:02d}{name[2:]}"
        if not APPLY:
            print('  ', name, '->', new); continue
        assert not os.path.exists(os.path.join(exdir, new)), new
        os.rename(os.path.join(exdir, name), os.path.join(exdir, new))

# ---------- 3. docs 文件改名（NN-slug.md；按旧号降序）----------
DOC_PAT = re.compile(r'^(\d{2})-([a-z][a-z0-9]*)\.md$')

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
        new = f"{MAP[n]:02d}-{name[3:]}"
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
    ('zh章组', re.compile(r'第\s*((?:\d{1,2}\s*[/-]\s*){1,4}\d{1,2})\s*章'), _zh_group),
    ('zh章',   re.compile(r'第\s*(\d{1,2})\s*章'), _zh),
    ('enum章', re.compile(r'(?<!第 )(?<!\d)((?:\d{1,2}[/-]){0,4}\d{1,2})\s*章'), _enum_ch),
    ('表行',   re.compile(r'(?m)^\| (\d{2}) \|'),          # PLAN/README 章表行首
        lambda m: f"| {sub_mapped_num(m.group(1))} |"),
    ('ex路径', re.compile(r'(?<!\w)examples/(\d{2})_'),     # examples/NN_ 路径形态
        lambda m: f"examples/{sub_mapped_num(m.group(1))}_"),
    ('doc文件', re.compile(r'(?<!\d)(\d{2})-([a-z][a-z0-9]*)(?![\w-])'),
        lambda m: f"{sub_mapped_num(m.group(1))}-{m.group(2)}"),
    ('ex文件', re.compile(r'(?<!\w)ex(\d{2})_([a-z][a-z0-9]*)'),
        lambda m: f"ex{sub_mapped_num(m.group(1))}_{m.group(2)}"),
    ('目录名', re.compile(r'(?<![\w/])(\d{2})_([a-z][a-z0-9]*)'),
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

# ---------- 5. 页脚导航全量重生成（按 80 章新序，空位章用预留标题）----------
def chapter_table():
    tabs = {}
    for p in glob.glob(os.path.join(ROOT, 'docs', '*.md')):
        m = re.match(r'^(\d{2})-([a-z][a-z0-9]*)\.md$', os.path.basename(p))
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
        m = re.match(r'^(\d{2})-[a-z][a-z0-9]*\.md$', os.path.basename(p))
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
        m = re.match(r'^(\d{2})-([a-z][a-z0-9]*)\.md$', d)
        if m: pairs.add((int(m.group(1)), m.group(2)))
    for d in os.listdir(os.path.join(ROOT, 'examples')):
        m = re.match(r'^(\d{2})_([a-z][a-z0-9]*)$', d)
        if m: pairs.add((int(m.group(1)), m.group(2)))
    return pairs

def verify(oldpairs):
    docs = sorted(d for d in os.listdir(os.path.join(ROOT, 'docs'))
                  if re.match(r'^\d{2}-', d))
    nums = [int(d[:2]) for d in docs]
    assert len(nums) == len(set(nums)), 'docs 章号重复！'
    print(f'docs 数 {len(nums)}，号位 min/max {min(nums)}/{max(nums)}')
    expect = set(range(1, 93)) - GAPS
    assert set(nums) == expect, f'号位差集: 缺 {sorted(expect - set(nums))[:8]} / 多 {sorted(set(nums) - expect)[:8]}'
    print(f'新章号位 {sorted(GAPS)} 预留确认；docs 连续 01-80 除空位')
    bad = []
    for p in text_files():
        t = open(p, 'rb').read().decode('utf-8', errors='ignore')
        for m in re.finditer(r'(?<!\d)(\d{2})-([a-z][a-z0-9]*)(?![\w-])', t):
            if (int(m.group(1)), m.group(2)) in oldpairs: bad.append((p, m.group(0)))
        for m in re.finditer(r'(?<![\w/])(\d{2})_([a-z][a-z0-9]*)', t):
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
