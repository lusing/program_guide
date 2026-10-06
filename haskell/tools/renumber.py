#!/usr/bin/env python3
# renumber.py — Haskell 教程 24→31 章一次性重编号工具。
# 用法：在 haskell/ 目录下  python tools/renumber.py --apply
# 默认 dry-run（只打印将发生的动作）。
#
# 做五件事：
#   1. git mv 两段式改名 docs/NN-slug.md 与 examples/NN_slug/（避免号位碰撞）
#   2. 示例目录内 ChNN.hs 改名 + module/import/==== NN 结束 ==== 同步
#   3. 全文本清扫：examples/NN_slug 路径、ChNN、标题/节号 NN.x、prose 的 “NN 章”
#   4. build.ps1 / run-all.sh 的 stack 工程特判字符串
#   5. 输出剩余 “NN 章” 引用审计清单供人工核对
import os
import re
import subprocess
import sys

sys.stdout.reconfigure(encoding='utf-8', errors='replace')  # Windows GBK 控制台兜底

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# 章号映射（旧→新）；01–09 恒等不列。
MAP = {10: 12, 11: 14, 12: 15, 13: 16, 14: 17, 15: 22, 16: 19, 17: 20,
       18: 24, 19: 25, 20: 27, 21: 28, 22: 29, 23: 30, 24: 31}

DOCS = {  # slug 不变，仅号变
    '10-laziness': '12-laziness', '11-containers': '14-containers', '12-strings': '15-strings',
    '13-fam': '16-fam', '14-mtl': '17-mtl', '15-parsec': '22-parsec', '16-files': '19-files',
    '17-errors': '20-errors', '18-th': '24-th', '19-performance': '25-performance',
    '20-stack': '27-stack', '21-testing': '28-testing', '22-concurrency': '29-concurrency',
    '23-ffi': '30-ffi', '24-capstone': '31-capstone'}
EXAM = {k.replace('-', '_'): v.replace('-', '_') for k, v in DOCS.items()}
EXAM['20_stackenv'] = '27_stackenv'          # 目录名与 docs slug 不同（stackenv ≠ stack）
del EXAM['20_stack']

APPLY = '--apply' in sys.argv


def sh(*args):
    if APPLY:
        subprocess.run(args, check=True, cwd=ROOT)
    else:
        print('DRY', *args)


def new_num(n):
    return MAP.get(n, n)


# ---- 1. 两段式 git mv ----
for mapping, base in ((DOCS, 'docs'), (EXAM, 'examples')):
    ext = '.md' if base == 'docs' else ''
    for old, new in mapping.items():
        sh('git', 'mv', f'{base}/{old}{ext}', f'{base}/__tmp_{new}{ext}')
    for new in mapping.values():
        sh('git', 'mv', f'{base}/__tmp_{new}{ext}', f'{base}/{new}{ext}')

# ---- 2. 目录内 ChNN 改名 ----
for old, new in EXAM.items():
    old_m = f'examples/{new}/Ch{old.split("_")[0]}.hs'
    new_m = f'examples/{new}/Ch{new.split("_")[0]}.hs'
    if os.path.exists(os.path.join(ROOT, old_m)):
        sh('git', 'mv', old_m, new_m)

# ---- 3. 文本清扫 ----
def sub_path(m):
    n = new_num(int(m.group(1)))
    return f'examples/{n:02d}_{m.group(2)}'


def sub_ch(m):
    n = int(m.group(1))
    return f'{new_num(n):02d}' if n >= 10 else m.group(0)


def sub_marker(m):
    return f'==== {new_num(int(m.group(1))):02d} 结束 ===='


def sub_h1(m):
    return f'# {new_num(int(m.group(1))):02d} ·{m.group(2)}'


def sub_h2(m):
    return f'{m.group(1)} {new_num(int(m.group(2))):02d}.{m.group(3)}'


PATTERNS = [
    (re.compile(r'examples/(\d{2})_([a-z]+)'), sub_path),
    (re.compile(r'(?<![\d.])(\d{1,2})(?= ?章)'), sub_ch),
    (re.compile(r'==== ?(\d{2}) ?结束 ?===='), sub_marker),
    (re.compile(r'^# (\d{2}) ?·(.*)$', re.M), sub_h1),
    (re.compile(r'^(#{2,4}) (\d{2})\.(\d)', re.M), sub_h2),
    (re.compile(r'Ch(\d{2})'), lambda m: f'Ch{new_num(int(m.group(1))):02d}'),
]

# build.ps1 / run-all.sh 特判字符串（先于通用模式做，避免号映射后串味）
LITERALS = [('20_stackenv', '27_stackenv'), ('24_capstone', '31_capstone')]


def sweep_text(t):
    for a, b in LITERALS:
        t = t.replace(a, b)
    for pat, fn in PATTERNS:
        t = pat.sub(fn, t)
    return t


targets = []
for base in ('docs', 'examples'):
    for dirpath, dirs, files in os.walk(os.path.join(ROOT, base)):
        dirs[:] = [d for d in dirs if d not in ('.stack-work', 'build') and '__tmp_' not in d]
        for f in files:
            if f.endswith(('.md', '.hs', '.ps1', '.sh')):
                targets.append(os.path.join(dirpath, f))
targets += [os.path.join(ROOT, 'build.ps1'), os.path.join(ROOT, 'run-all.sh'),
            os.path.join(ROOT, 'CHEATSheet.md'), os.path.join(ROOT, 'README.md')]

for path in targets:
    with open(path, encoding='utf-8') as fh:
        t = fh.read()
    t2 = sweep_text(t)
    if t2 != t:
        if APPLY:
            with open(path, 'w', encoding='utf-8', newline='') as fh:
                fh.write(t2)
        print('SWEEP', os.path.relpath(path, ROOT))

# ---- 4. 审计：剩余 “NN 章” 引用清单 ----
print('\n==== 审计：全部 “N(N) 章” 引用（人工逐条核对） ====')
for path in targets:
    if not os.path.exists(path):
        continue
    with open(path, encoding='utf-8') as fh:
        for i, line in enumerate(fh, 1):
            if re.search(r'\d{1,2} ?章', line):
                print(f'{os.path.relpath(path, ROOT)}:{i}: {line.strip()[:80]}')
print('\nDONE', '(applied)' if APPLY else '(dry-run)')
