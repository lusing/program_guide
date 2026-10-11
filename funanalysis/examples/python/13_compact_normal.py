import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
"""第 13 章 · 紧正规算子谱定理与泛函演算的数值实验（Conway II.7-8）。

- 正规性检验（7.6）；
- 泛函演算 Φ(T) = Q Φ(D) Q*（7.11）；
- 正算子的平方根（7.16）；
- 酉等价保持特征值（8.2）。
"""

import numpy as np
from scipy import linalg

rng = np.random.default_rng(1313)

print("==== 13 compact-normal (Python) ====")

# --- 实验 1：紧正规算子（Conway 7.6）---
n = 50
alpha = np.array([(-1)**k / k**1.5 + 1j * (-1)**(k + 1) / k**2.2
                  for k in range(1, n + 1)])
Q_, _ = np.linalg.qr(rng.standard_normal((n, n)) + 1j * rng.standard_normal((n, n)))
T = Q_ @ np.diag(alpha) @ Q_.conj().T
normality = np.linalg.norm(T @ T.conj().T - T.conj().T @ T)
print(f"normality: ||TT* - T*T|| = {normality:.2e}")
assert normality < 1e-10

# --- 实验 2：泛函演算（Conway 7.11）---
phi = lambda z: z**2 + 1
phiT = Q_ @ np.diag(phi(alpha)) @ Q_.conj().T
direct = T @ T + np.eye(n)
print(f"functional calculus: ||Φ(T) - (T²+I)|| = {np.linalg.norm(phiT - direct):.2e}")
assert np.linalg.norm(phiT - direct) < 1e-8

# --- 实验 3：正算子与平方根（Conway 7.16）---
A = rng.standard_normal((30, 30)) + 1j * rng.standard_normal((30, 30))
T_pos = A.conj().T @ A
evals_pos = linalg.eigh(T_pos, eigvals_only=True)
assert evals_pos.min() >= -1e-10
S = linalg.sqrtm(T_pos)
err = np.linalg.norm(S @ S - T_pos) / np.linalg.norm(T_pos)
print(f"positive: min eig = {evals_pos.min():.8f},  ||S²-T||/||T|| = {err:.2e}")
assert err < 1e-10

# --- 实验 4：酉等价（Conway 8.2）---
n2 = 20
beta = 1.0 / np.arange(1, n2 + 1)
V, _ = np.linalg.qr(rng.standard_normal((n2, n2)) + 1j * rng.standard_normal((n2, n2)))
W, _ = np.linalg.qr(rng.standard_normal((n2, n2)) + 1j * rng.standard_normal((n2, n2)))
T1 = V @ np.diag(beta) @ V.conj().T
T2 = W @ np.diag(beta) @ W.conj().T
U = W @ V.conj().T
err = np.linalg.norm(T2 - U @ T1 @ U.conj().T)
print(f"unitary equivalence: ||T2 - UT1U*|| = {err:.2e}")
assert err < 1e-8

print("==== 13 compact-normal END ====")
