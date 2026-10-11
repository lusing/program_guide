import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
"""第 19 章 · 一致有界原理（Conway III.14）。"""
import numpy as np
rng = np.random.default_rng(1919)
print("==== 19 uniform-boundedness (Python) ====")
n, m = 20, 100
Ts = [rng.standard_normal((n, n)) / np.sqrt(n) for _ in range(m)]
pts = rng.standard_normal((100, n)); pts /= np.linalg.norm(pts, axis=1, keepdims=True)
pb = max(np.linalg.norm(T @ p) for T in Ts for p in pts)
ub = max(np.linalg.norm(T, 2) for T in Ts)
print(f"pointwise sup = {pb:.4f}")
print(f"uniform sup = {ub:.4f}")
assert pb <= ub + 1e-12
assert ub < 10.0
print("finite dim: both bounded (theorem matters in infinite dim)")
print("==== 19 uniform-boundedness END ====")
