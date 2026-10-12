import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
import numpy as np
from scipy.linalg import eigh_tridiagonal

rng = np.random.default_rng(4242)
print("==== 42 symmetric_selfadjoint (Python) ====")
n = 6
I = np.eye(n)

# 对称 ⟹ 自伴？有限维永远成立；分歧在无穷维的"定义域"上。
# 数值化身：-d²/dx² 在 [0,1] 的三个自伴扩张（同一微分表达式，
# 不同边条件），谱各不相同——对称算子的自伴扩张是一个"家族"。

# Cayley 变换：自伴 A ↦ U = (A-i)(A+i)⁻¹ 是酉
A0 = rng.standard_normal((n, n)); A = (A0 + A0.T) / 2
U = np.linalg.solve(A + 1j * I, A - 1j * I)
print(f"Cayley 变换酉性偏差 = {np.linalg.norm(U.conj().T @ U - I):.12f}")
assert np.linalg.norm(U.conj().T @ U - I) < 1e-12
assert np.abs(np.abs(np.linalg.eigvals(U)) - 1).max() < 1e-12
print("自伴算子的 Cayley 变换是酉算子（特征值全在单位圆上）：✓")

# 三个自伴扩张的谱（有限差分离散）
N = 400
h = 1.0 / N

# Dirichlet-Dirichlet：λₙ = (nπ)²，n ≥ 1（内点网格）
wdd = eigh_tridiagonal(2 * np.ones(N), -np.ones(N - 1), eigvals_only=True) / h**2
print("DD 前3特征值比 (nπ)²：", np.round(wdd[:3] / (np.arange(1, 4) * np.pi) ** 2, 4))
assert abs(wdd[0] / np.pi**2 - 1) < 0.01

# Neumann-Neumann：λₙ = (nπ)²，n ≥ 0（含零特征值：常数函数）
d = 2 * np.ones(N + 1); d[0] = 1.0; d[-1] = 1.0
wnn = eigh_tridiagonal(d, -np.ones(N), eigvals_only=True) / h**2
print(f"NN 最小特征值 = {wnn[0]:.6f}（理论 0：常数函数）")
assert wnn[0] < 0.01

# Dirichlet-Neumann：λₙ = ((n+1/2)π)²
d2 = 2 * np.ones(N); d2[0] = 1.0
wdn = eigh_tridiagonal(d2, -np.ones(N - 1), eigvals_only=True) / h**2
print(f"DN 首特征值比 (π/2)²：{wdn[0] / (np.pi / 2) ** 2:.4f}")
assert abs(wdn[0] / (np.pi / 2) ** 2 - 1) < 0.01

print("同一表达式 -d²/dx²，三种边条件 ⟹ 三套谱：自伴扩张不唯一：✓")
print("==== 42 symmetric_selfadjoint END ====")
