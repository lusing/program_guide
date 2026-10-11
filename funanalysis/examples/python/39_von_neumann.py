import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
import numpy as np
from scipy.linalg import null_space

rng = np.random.default_rng(3939)
print("==== 39 von_neumann (Python) ====")
n = 6
I = np.eye(n)

# 交换子方程 SX = XS 的核：kron(I,S) - kron(Sᵀ,I) 作用于 vec(X)（列主序）
def comm_kernel(S):
    return null_space(np.kron(I, S) - np.kron(S.T, I), rcond=1e-8)

# 1) 对角阵（互异对角元）的交换子 = 对角阵全体
D = np.diag(np.arange(1.0, n + 1))
N1 = comm_kernel(D)
print(f"dim {{D}}' = {N1.shape[1]}（= n：对角阵全体）")
assert N1.shape[1] == n
alldiag = all(
    np.linalg.norm(X - np.diag(np.diag(X))) < 1e-6
    for X in (N1[:, j].reshape(n, n, order="F") for j in range(N1.shape[1]))
)
assert alldiag
print("核中元素全部是对角阵：✓")

# 2) 循环移位的交换子 = 循环阵全体（S 的多项式）
S = np.zeros((n, n))
for i in range(n - 1):
    S[i + 1, i] = 1.0
S[0, n - 1] = 1.0
N2 = comm_kernel(S)
print(f"dim {{S}}' = {N2.shape[1]}（= n：循环阵全体）")
assert N2.shape[1] == n

def is_circulant(X, tol):
    return all(
        np.linalg.norm(X[i, :] - np.roll(X[0, :], i)) < tol
        for i in range(X.shape[0])
    )

allcirc = all(
    is_circulant(N2[:, j].reshape(n, n, order="F"), 1e-6)
    for j in range(N2.shape[1])
)
assert allcirc
print("循环移位的交换子恰为循环阵（= S 的多项式）：✓")

# 3) 双交换子定理（有限维化身）：{S}'' = {S}' = vN(S)
a = rng.standard_normal(n)
C = sum(a[k] * np.linalg.matrix_power(S, k) for k in range(n))
N3 = comm_kernel(C)
print(f"dim {{S}}'' = {N3.shape[1]} = dim {{S}}' = {n}")
assert N3.shape[1] == n
allcirc2 = all(
    is_circulant(N3[:, j].reshape(n, n, order="F"), 1e-6)
    for j in range(N3.shape[1])
)
assert allcirc2
print("双交换子 = 交换子 = 生成的 *-代数（bicommutant 定理）：✓")
print("==== 39 von_neumann END ====")
