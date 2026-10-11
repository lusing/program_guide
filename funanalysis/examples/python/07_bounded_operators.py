import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
"""第 07 章 · 有界算子的数值实验（Conway II.1）——scipy 通道。

对应 docs/07-bounded-operators.md。
- 算子范数的数值逼近（随机方向搜索 vs 奇异值精确值）；
- Hilbert-Schmidt 型积分算子的范数界（Conway 1.6 的 ‖K‖ <= √(c₁c₂)）；
- 乘法算子范数 = ess-sup（1.5 离散化身）。
"""

import numpy as np
from scipy import integrate

rng = np.random.default_rng(707)

print("==== 07 bounded-operators (Python) ====")

# --- 实验 1：随机方向逼近算子范数（从下方逼近 sup）-----------------------------
A = rng.standard_normal((5, 4))
dirs = rng.standard_normal((20000, 4))
dirs /= np.linalg.norm(dirs, axis=1, keepdims=True)
vals = np.linalg.norm(dirs @ A.T, axis=1)
sigma_max = np.linalg.svd(A, compute_uv=False)[0]
print(f"random-dir sup = {vals.max():.6f} <= σ_max = {sigma_max:.6f}")
assert vals.max() <= sigma_max + 1e-12
assert vals.max() > sigma_max * 0.97                        # 覆盖良好

# --- 实验 2：Hilbert-Schmidt 积分算子的范数控制（Conway 1.6）--------------------
# Kf(x) = ∫₀¹ k(x,y) f(y) dy，Schur 界：‖K‖ <= √(c₁c₂)
# c₁ = sup_x ∫|k(x,y)|dy，c₂ = sup_y ∫|k(x,y)|dx
# 取对称核 k(x,y) = 1/(1.1 - x*y)（正定核）
xs = np.linspace(0, 1, 201)
K = 1.0 / (1.1 - np.outer(xs, xs))
c1 = integrate.trapezoid(np.abs(K), xs, axis=1).max()
c2 = integrate.trapezoid(np.abs(K), xs, axis=0).max()
bound = np.sqrt(c1 * c2)
# 数值算子范数：迭代幂法（对称核，最大特征值）
v = np.ones_like(xs)
for _ in range(300):
    v = integrate.trapezoid(K * v[None, :], xs, axis=1)
    v /= np.linalg.norm(v)
op_norm = np.linalg.norm(integrate.trapezoid(K * v[None, :], xs, axis=1))
print(f"Schur bound √(c₁c₂) = {bound:.4f} >= numeric ‖K‖ = {op_norm:.4f}")
assert op_norm <= bound + 1e-6

# --- 实验 3：乘法算子范数 = max|φ|（Conway 1.5 离散化身）------------------------
phi = np.array([2.0, -0.5, 1.5])
for trial in range(100):
    f = rng.standard_normal(3)
    assert np.linalg.norm(phi * f) <= np.abs(phi).max() * np.linalg.norm(f) + 1e-12
print(f"multiplication opnorm = {np.abs(phi).max():.4f} = max|φ|（上界紧）")

print("==== 07 bounded-operators END ====")
