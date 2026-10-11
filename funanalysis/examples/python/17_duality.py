import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
"""第 17 章 · 对偶理论（Conway III.10-11 + B/C）。"""
import numpy as np
rng = np.random.default_rng(1717)
print("==== 17 duality (Python) ====")
n = 5; x = rng.standard_normal(n)
fs = rng.standard_normal((1000, n)); fs /= np.linalg.norm(fs, axis=1, keepdims=True)
sup_val = np.abs(fs @ x).max()
print(f"sup|<x,f>| over 1000 unit f = {sup_val:.6f}  ||x|| = {np.linalg.norm(x):.6f}")
assert sup_val <= np.linalg.norm(x) + 1e-12
p, q = 1.5, 3.0
f = rng.standard_normal(100); g = rng.standard_normal(100)
lhs = abs(f @ g); rhs = np.linalg.norm(f, p) * np.linalg.norm(g, q)
print(f"Hölder: {lhs:.4f} <= {rhs:.4f}")
assert lhs <= rhs + 1e-10
print("==== 17 duality END ====")
