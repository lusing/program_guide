import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
"""第 10 章 · 紧算子的数值实验（Conway II.4）——scipy 通道。

- 有限秩逼近：截断 SVD 的误差恰为第 k+1 个奇异值；
- 对角算子的紧性：αₙ → 0；
- Volterra 算子：紧（奇异值衰减）但无特征值。
"""

import numpy as np

rng = np.random.default_rng(1010)

print("==== 10 compact-operators (Python) ====")

# --- 实验 1：有限秩截断逼近（Conway 4.4 (c)）---
A = rng.standard_normal((50, 50))
U, S, Vt = np.linalg.svd(A)
for k in [5, 10, 20, 40]:
    Ak = U[:, :k] @ np.diag(S[:k]) @ Vt[:k, :]
    err = np.linalg.norm(A - Ak, 2)
    print(f"rank-{k} truncation error = {err:.6f}  σ_{k+1} = {S[k]:.6f}")
    assert abs(err - S[k]) < 1e-10

# --- 实验 2：对角算子的紧性（Conway 4.6）---
alpha = 1.0 / np.arange(1, 101) ** 1.2  # → 0：紧
beta = np.ones(100)                       # 不趋于零：不紧
print(f"alpha tail sup = {np.abs(alpha[50:]).max():.6f} (< 0.01: compact)")
print(f"beta  tail sup = {np.abs(beta[50:]).max():.6f} (= 1: not compact)")
assert np.abs(alpha[50:]).max() < 0.01
assert np.abs(beta[50:]).max() == 1.0

# --- 实验 3：Volterra 算子紧但无特征值（Conway 4.11）---
n = 200
h = 1.0 / n
xs = (np.arange(n) + 0.5) * h
V = h * (xs[:, None] >= xs[None, :]).astype(float)  # 下三角：离散积分
σV = np.linalg.svd(V, compute_uv=False)
print(f"Volterra: σ₁ = {σV[0]:.4f} (2/π = {2/np.pi:.4f})")
print(f"Volterra: σ₁₀ = {σV[9]:.6f} → 0 (compact)")
assert abs(σV[0] - 2 / np.pi) < 0.01
assert σV[9] < 0.1

# Volterra 无特征值：特征值全为零
evals_V = np.linalg.eigvals(V)
print(f"Volterra: max|eig| = {np.abs(evals_V).max():.6f}")
assert np.abs(evals_V).max() < 0.01  # 连续算子无特征值，离散近似全为零

print("==== 10 compact-operators END ====")
