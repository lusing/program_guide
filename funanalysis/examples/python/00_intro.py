"""第 00 章 · Python/scipy 通道总览。

对应 docs/00-intro.md。与 Julia 通道互为镜像：同一组数学实验，
另一套浮点实现。本章热身：CBS 与三角不等式的随机验证。
运行：python -I 00_intro.py
"""

import numpy as np

rng = np.random.default_rng(42)

print("==== 00 intro (Python) ====")
print("numpy", np.__version__)

# --- CBS：|<x,y>| <= ||x|| * ||y|| ---
ok = True
for _ in range(1000):
    n = rng.integers(1, 50)
    x, y = rng.standard_normal(n), rng.standard_normal(n)
    ok &= abs(x @ y) <= np.linalg.norm(x) * np.linalg.norm(y) + 1e-12
print("CBS random check (1000 trials):", "PASS" if ok else "FAIL")
assert ok

# --- 三角不等式 ---
ok = True
for _ in range(1000):
    n = rng.integers(1, 50)
    x, y = rng.standard_normal(n), rng.standard_normal(n)
    ok &= np.linalg.norm(x + y) <= np.linalg.norm(x) + np.linalg.norm(y) + 1e-12
print("triangle random check (1000 trials):", "PASS" if ok else "FAIL")
assert ok

print("==== 00 intro END ====")
