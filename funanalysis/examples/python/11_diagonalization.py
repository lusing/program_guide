import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
"""第 11 章 · 紧自伴算子对角化的数值实验（Conway II.5）——scipy 通道。

- Hilbert-Schmidt 核的谱分解（Conway 5.1）；
- 特征值实且趋于零（5.3c）；
- ‖T‖ = max|αₙ|（5.3c）。
"""

import numpy as np

rng = np.random.default_rng(1111)

print("==== 11 diagonalization (Python) ====")

# --- 实验 1：紧自伴算子的对角化（Conway 5.1）---
n = 100
xs = np.linspace(0, 1, n)
K = np.exp(-np.abs(xs[:, None] - xs[None, :])) / n  # 对称正定核
evals, evecs = np.linalg.eigh(K)  # 升序

# --- 实验 2：特征值实且趋于零（Conway 5.3 (c)）---
print(f"all eigenvalues real: max|Im| = {np.abs(evals.imag).max():.2e}")
assert np.abs(evals.imag).max() == 0.0
print(f"last 5 |eigenvalues| max: {np.abs(evals[:5]).max():.6e}")
assert np.abs(evals[:5]).max() < 1e-3

# --- 实验 3：‖T‖ = max|αₙ|（Conway 5.3 (c)）---
opnorm = np.linalg.norm(K, 2)
specmax = np.abs(evals).max()
print(f"opnorm(K) = {opnorm:.8f}  max|α| = {specmax:.8f}")
assert abs(opnorm - specmax) < 1e-10

# 特征向量正交（Parseval 的对角化形态）
Q = evecs
assert np.abs(Q.T @ Q - np.eye(n)).max() < 1e-8
print("eigenvectors orthonormal: PASS")

print("==== 11 diagonalization END ====")
