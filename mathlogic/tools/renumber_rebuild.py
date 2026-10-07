# -*- coding: utf-8 -*-
"""全树文本重建：每个现行文件取 git 原文（经逆映射解析旧路径），
用修正后的模式组恰跑一遍，覆写。确定性、幂等。"""
import importlib.util, sys, subprocess, os, re

spec = importlib.util.spec_from_file_location('rn', 'tools/renumber.py')
m = importlib.util.module_from_spec(spec)
sys.argv = ['renumber.py']            # APPLY=False → import 期 two_phase 仅 dry
spec.loader.exec_module(m)
MAP, PATTERNS = m.MAP, m.PATTERNS
INV = {v: k for k, v in MAP.items()}

def git_orig(rel):
    r = subprocess.run(['git', 'show', f'HEAD:mathlogic/{rel}'], capture_output=True)
    return r.stdout.decode('utf-8', 'surrogateescape') if r.returncode == 0 else None

def apply_once(text):
    for name, rx, cb in PATTERNS:
        text = rx.sub(cb, text)
    return text

targets, skips = [], []
docs = sorted(f for f in os.listdir('docs') if re.match(r'^\d{2}-', f))
for f in docs:
    n = int(f[:2]); old = f'{INV.get(n, n):02d}-{f[3:]}'
    src = git_orig(f'docs/{old}')
    (targets if src else skips).append((f'docs/{f}', src))

exdirs = sorted(d for d in os.listdir('examples') if re.match(r'^\d{2}_', d))
for d in exdirs:
    n = int(d[:2]); oldd = f'{INV.get(n, n):02d}_{d[3:]}'
    for root, _, files in os.walk(f'examples/{d}'):
        for f in files:
            cur = os.path.join(root, f).replace('\\', '/')
            oldf = re.sub(r'ex\d{2}_', f'ex{INV.get(n, n):02d}_', f)
            src = git_orig(f'examples/{oldd}/{oldf}')
            (targets if src else skips).append((cur, src))

for rel in ('README.md', 'PLAN.md', 'CHEATSheet.md', 'examples/ROOT'):
    src = git_orig(rel)
    (targets if src else skips).append((rel, src))

for rel, src in targets:
    open(rel, 'wb').write(apply_once(src).encode('utf-8', 'surrogateescape'))
print(f'重建 {len(targets)} 个文件，跳过 {len(skips)} 个')
for rel, _ in skips: print('  无原文跳过:', rel)
