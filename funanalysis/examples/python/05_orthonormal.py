import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
"""第 05 章 · 标准正交基的数值实验（Conway I.4）——scipy 通道。

对应 docs/05-orthonormal-bases.md。
- Legendre 多项式 = [1,x,x²,...] 在 L²[-1,1] 的 Gram-Schmidt（Conway 习题 6）；
- Bessel 不等式与 Parseval 恒等式的数值确认；
- Fourier 部分和的最佳逼近性。
"""

import numpy as np
from scipy import integrate

rng = np.random.default_rng(512)

print("==== 05 orthonormal (Python) ====")

# --- 实验 1：Legendre 多多项式 = 幂基的 Gram-Schmidt（Conway 习题 6）---------
# P₀=1, P₁=x, P₂=(3x²-1)/2, P₃=(5x³-3x)/2 —— 归一化后互相正交
xs = np.linspace(-1, 1, 2001)
Ps = [np.ones_like(xs), xs, (3 * xs**2 - 1) / 2, (5 * xs**3 - 3 * xs) / 2]
G = np.array([[integrate.trapezoid(p * q, xs) for q in Ps] for p in Ps])
off_diag = G - np.diag(np.diag(G))
print("Legendre Gram matrix off-diagonal max:", f"{np.abs(off_diag).max():.2e}")
assert np.abs(off_diag).max() < 1e-3
# 归一化版本：Gram = I
Pn = [p / np.sqrt(integrate.trapezoid(p * p, xs)) for p in Ps]
Gn = np.array([[integrate.trapezoid(p * q, xs) for q in Pn] for p in Pn])
assert np.abs(Gn - np.eye(4)).max() < 5e-5

# --- 实验 2：Bessel 与 Parseval -------------------------------------------------
f = np.exp(xs)
coeffs = np.array([integrate.trapezoid(f * p, xs) for p in Pn])
partial_energy = np.sum(coeffs**2)
total_energy = integrate.trapezoid(f * f, xs)
print(f"Bessel: partial = {partial_energy:.6f} ≤ total = {total_energy:.6f}")
assert partial_energy <= total_energy + 1e-6

# --- 实验 3：部分和 = 最佳逼近（投影的变分刻画）--------------------------------
approx = sum(c * p for c, p in zip(coeffs, Pn))
res_partial = np.sqrt(integrate.trapezoid((f - approx) ** 2, xs))
for trial in range(50):
    bad = sum(c * p for c, p in zip(coeffs + rng.standard_normal(4) * 0.5, Pn))
    res_bad = np.sqrt(integrate.trapezoid((f - bad) ** 2, xs))
    assert res_partial <= res_bad + 1e-12
print(f"partial-sum residual = {res_partial:.6f} is minimal (50 perturbed trials)")

print("==== 05 orthonormal END ====")
