import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
"""第 12 章 · Sturm-Liouville 系统的数值实验（Conway II.6*）——scipy 通道。

- Green 函数 g(x,y) = min(x,y)(1-max(x,y)) 的数值验证；
- G 的特征值 = 1/(k²π²)（Conway 6.12）；
- 特征函数 = sin(kπx)（Fourier 正弦基）。
"""

import numpy as np
from scipy import linalg

print("==== 12 sturm-liouville (Python) ====")

n = 200
h = 1.0 / (n + 1)
xs = np.arange(1, n + 1) * h  # 内点

# --- 实验 1：Green 函数矩阵（Conway 6.7-6.9）---
G = np.minimum.outer(xs, xs) * (1 - np.maximum.outer(xs, xs)) * h

# 验证：G sin(πx) = sin(πx)/π²
f = np.sin(np.pi * xs)
Gf = G @ f
expected = f / np.pi**2
err = np.linalg.norm(Gf - expected) / np.linalg.norm(expected)
print(f"Green function check: ||Gf - f/π²||/||f/π²|| = {err:.8f}")
assert err < 1e-4

# --- 实验 2：G 的特征值 = 1/(k²π²)（Conway 6.12）---
evals = linalg.eigh(G, eigvals_only=True)
top_idx = np.argsort(np.abs(evals))[::-1]
for k in range(1, 6):
    α = evals[top_idx[k - 1]]
    expected_α = 1.0 / (k * np.pi) ** 2
    print(f"  λ_{k} = {α:.8f}  1/(k²π²) = {expected_α:.8f}")
    assert abs(α - expected_α) / expected_α < 0.01

# --- 实验 3：特征函数 = sin(kπx)---
_, evecs = linalg.eigh(G)
k = 3
v = evecs[:, top_idx[k - 1]]
if np.dot(v, np.sin(k * np.pi * xs)) < 0:
    v = -v
cos_sim = abs(np.dot(v, np.sin(k * np.pi * xs))) / (
    np.linalg.norm(v) * np.linalg.norm(np.sin(k * np.pi * xs)))
print(f"eigenvector {k} cosine-similarity with sin({k}πx): {cos_sim:.6f}")
assert cos_sim > 0.999

print("==== 12 sturm-liouville END ====")
