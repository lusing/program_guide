import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
"""第 08 章 · 伴随算子的数值实验（Conway II.2）——scipy 通道。

对应 docs/08-adjoint.md。
- 积分算子的伴随 = 核转置（Conway 2.9）；
- 自伴核 k(x,y)=k(y,x) 的数值验证；
- 谱的实值性：自伴算子特征值全实（2.12 的谱侧影，第 11 章正式化）。
"""

import numpy as np
from scipy import integrate

rng = np.random.default_rng(808)

print("==== 08 adjoint (Python) ====")

xs = np.linspace(0, 1, 81)

# --- 实验 1：K† 的核是 k(y,x)（Conway 2.9）-------------------------------------
k = lambda x, y: np.exp(-np.abs(x - y)) + 0.3 * x * y       # 对称核（自伴）
K = k(xs[:, None], xs[None, :])
f, g = rng.standard_normal(81), rng.standard_normal(81)
lhs = integrate.trapezoid(
    integrate.trapezoid(k(xs[:, None], xs[None, :]) * g[None, :], xs, axis=1) * f, xs)
rhs = integrate.trapezoid(
    integrate.trapezoid(k(xs[:, None], xs[None, :]) * f[:, None], xs, axis=0) * g, xs)
print(f"<Kf,g> = {lhs:.6f}  <f,Kg> = {rhs:.6f}（对称核 ⟹ 自伴）")
assert abs(lhs - rhs) < 1e-8

# --- 实验 2：非对称核的伴随 = 转置核 ---------------------------------------------
k2 = lambda x, y: np.exp(-2 * np.abs(x - y)) + 0.5 * np.sin(x + 2 * y)
K2 = k2(xs[:, None], xs[None, :])
lhs2 = integrate.trapezoid(
    integrate.trapezoid(k2(xs[:, None], xs[None, :]) * g[None, :], xs, axis=1) * f, xs)
rhs2 = integrate.trapezoid(
    integrate.trapezoid(k2(xs[:, None], xs[None, :]) * f[:, None], xs, axis=0) * g, xs)
# <K₂f, g> = <f, K₂†g> 其中 K₂† 的核是 k₂(y,x) —— 即上式 rhs2 用的就是转置
print(f"asymmetric kernel: <Kf,g> = {lhs2:.6f}  <f,K†g>(转置核) = {rhs2:.6f}")
assert abs(lhs2 - rhs2) < 1e-8

# --- 实验 3：自伴矩阵特征值全实（谱定理前奏）------------------------------------
H = rng.standard_normal((6, 6))
H = (H + H.T) / 2
evals = np.linalg.eigvalsh(H)
assert np.abs(evals.imag).max() == 0.0
B = rng.standard_normal((6, 6)) + 1j * rng.standard_normal((6, 6))
Bevals = np.linalg.eigvals(B)
print(f"Hermitian eigenvalues all real: max|Im| = {np.abs(evals.imag).max():.1e}")
print(f"general matrix has complex eigenvalues: max|Im| = {np.abs(Bevals.imag).max():.3f}")
assert np.abs(Bevals.imag).max() > 1e-3

print("==== 08 adjoint END ====")
