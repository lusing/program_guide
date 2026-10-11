import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
import numpy as np
from scipy.linalg import null_space

rng = np.random.default_rng(4040)
print("==== 40 invariant_subspaces (Python) ====")
n = 6
I = np.eye(n)

# 不变子空间：AV ⊆ V。上三角阵天然有不变旗 span(e₁..eₖ)
A = np.triu(rng.standard_normal((n, n)))
for k in range(1, n):
    V = I[:, :k]
    assert np.linalg.norm((I - V @ V.T) @ A @ V) < 1e-10
print("上三角阵：span(e₁..eₖ) 对每个 k 不变：✓")

# 约化子空间 = 对 A 与 A* 都不变。正规算子的特征空间自动约化
H0 = rng.standard_normal((n, n)) + 1j * rng.standard_normal((n, n))
H = H0 + H0.conj().T
vals, vecs = np.linalg.eigh(H)
v, lam = vecs[:, 0], vals[0]
assert np.linalg.norm(H @ v - lam * v) < 1e-10
assert np.linalg.norm(H.conj().T @ v - np.conj(lam) * v) < 1e-10
print("正规算子：一维特征空间同时约化 A 与 A*：✓")

# 非正规反例：后移 S 的 span(e₁) 不变但不约化
S = np.zeros((n, n))
for i in range(1, n):
    S[i - 1, i] = 1.0      # S eₖ = eₖ₋₁，S e₁ = 0
e1 = np.zeros(n); e1[0] = 1.0
e2 = np.zeros(n); e2[1] = 1.0
assert np.linalg.norm(S @ e1) < 1e-12            # S(span e₁) ⊆ span e₁
assert np.linalg.norm(S.T @ e1 - e2) < 1e-12     # S* e₁ = e₂ ∉ span e₁
print("span(e₁) 对后移不变，但 S*e₁ = e₂ 越出（不约化）：✓")

# 重数：代数重数 vs 几何重数（特征空间维数）
J = np.eye(4) + np.diag(np.ones(3), 1)           # Jordan 块 λ = 1
g = null_space(J - np.eye(4)).shape[1]
print(f"4 阶 Jordan 块：代数重数 4，几何重数 {g}")
assert g == 1
print("==== 40 invariant_subspaces END ====")
