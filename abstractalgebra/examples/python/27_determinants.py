# 27 行列式：完全展开、公理化与可逆判别（Python + sympy 对拍）
#
# 对应原书 §4.4 前半。自实现 det_perm（置换完全展开）与 det_laplace
#（余子式递推），与 sympy 的 Matrix.det 全面对拍；再用 sympy 的伴随
#（adjugate）、特征多项式（charpoly）核对命题 4.86 / 4.87 / 4.93。

from itertools import permutations
from random import randint

import sympy as sp

print("==== 27")


def sgn_perm(p):
    # (−1)^{逆序数}
    inv = sum(1 for i in range(len(p)) for j in range(i) if p[j] > p[i])
    return -1 if inv % 2 else 1


def det_perm(A):
    """完全展开：Σ sgn(σ) ∏ a[σ(i), i]。"""
    n = len(A)
    s = 0
    for p in permutations(range(n)):
        term = 1
        for col in range(n):
            term *= A[p[col]][col]
        s += sgn_perm(p) * term
    return s


def minor(A, i, j):
    return [row[:j] + row[j + 1:] for k, row in enumerate(A) if k != i]


def det_laplace(A):
    """按第 1 行的 Laplace 展开（公式 (3) 的 i = 1；0 基下符号为 (−1)^j）。"""
    n = len(A)
    if n == 1:
        return A[0][0]
    return sum((-1) ** j * A[0][j] * det_laplace(minor(A, 0, j))
               for j in range(n))


# ---------- 三方对拍（自实现 × 2 + sympy） ----------

for trial in range(30):
    n = 2 + trial % 4
    A = [[randint(-6, 6) for _ in range(n)] for _ in range(n)]
    d_own = det_perm(A)
    assert d_own == det_laplace(A)
    assert d_own == sp.Matrix(A).det()
print("完全展开 = Laplace = sympy.det：30 张随机矩阵（2..5 阶）全同值 ✓")

assert det_perm([[1, 2], [3, 4]]) == det_laplace([[1, 2], [3, 4]]) == -2
print("锚点 det[[1,2;3,4]] = −2（perm 与 laplace 双验）✓")

# ---------- 乘法性与转置不变（式 (1)/(2)） ----------

for trial in range(15):
    n = 2 + trial % 3
    A = [[randint(-5, 5) for _ in range(n)] for _ in range(n)]
    B = [[randint(-5, 5) for _ in range(n)] for _ in range(n)]
    AB = [[sum(A[i][k] * B[k][j] for k in range(n)) for j in range(n)] for i in range(n)]
    assert det_perm(AB) == det_perm(A) * det_perm(B)
    At = [[A[j][i] for j in range(n)] for i in range(n)]
    assert det_perm(At) == det_perm(A)
print("det(AB) = det(A)det(B) 与 det(Aᵀ) = det(A)：15 组随机对 ✓")

# ---------- 命题 4.86：A·adj(A) = det(A)·I（自实现伴随 × sympy 伴随对拍） ----------

def adjugate3(A):
    """c_ji = (−1)^{i+j} det(A_ij)：下标反转是定义的一部分（0 基下符号 (−1)^{i+j}）。"""
    adj = [[0] * 3 for _ in range(3)]
    for i in range(3):
        for j in range(3):
            adj[j][i] = (-1) ** (i + j) * det_laplace(minor(A, i, j))
    return adj

A3 = [[2, 1, 0], [1, 3, 1], [0, 1, 2]]
M3 = sp.Matrix(A3)
assert adjugate3(A3) == M3.adjugate().tolist()               # 与 sympy 伴随对拍
prod = [[sum(A3[i][k] * adjugate3(A3)[k][j] for k in range(3)) for j in range(3)] for i in range(3)]
d3 = det_perm(A3)                                            # = 8
assert prod == [[8 if i == j else 0 for j in range(3)] for i in range(3)]
print("命题 4.86：A·adj(A) = det(A)·I = 8·I（自实现 = sympy.adjugate）✓")

# ---------- 推论 4.87：可逆 ⟺ det 是单位 ----------

U = sp.Matrix([[2, 1], [1, 1]])
assert U.det() == 1 and (U.inv() == sp.Matrix([[1, -1], [-1, 2]]))
S = sp.Matrix([[2, 0], [0, 1]])
assert S.det() == 2 and any(t % 1 != 0 for t in (S.inv()))
# ℤ[x] 侧：多项式矩阵可逆 ⟺ det 为非零常数
x = sp.symbols("x")
P = sp.Matrix([[x, 1], [-1, x]])
assert sp.expand(P.det()) == x**2 + 1        # det 非常数 ⟹ k[x] 上不可逆
Q = sp.Matrix([[x, 1], [0, x - 1]])
assert sp.expand(Q.det() - x * (x - 1)) == 0                # det 非常数 ⟹ ℤ[x] 上同样不可逆
assert sp.expand(Q.inv().det() * Q.det() - 1) == 0          # 但在分式域 ℚ(x) 上可逆
print("推论 4.87：det = ±1 ⟹ 整数逆；det(x²+1) 非常数 ⟹ ℤ[x] 上不可逆 ✓")

# ---------- 命题 4.93：h_A(x) = x³ − tr·x² + e₂·x − det ----------

lam = sp.symbols("lambda")
for A in ([1, 2, 0], [0, 1, 3], [0, 0, 2]), ([0, 1, 0], [-1, 0, 0], [0, 0, 5]), A3:
    cp = sp.Matrix(A).charpoly(lam)          # sympy：λ³ − tr·λ² + e₂·λ − det
    tr = A[0][0] + A[1][1] + A[2][2]
    e2 = (A[0][0] * A[1][1] - A[0][1] * A[1][0]) + (A[0][0] * A[2][2] - A[0][2] * A[2][0]) \
        + (A[1][1] * A[2][2] - A[1][2] * A[2][1])
    expect = lam**3 - tr * lam**2 + e2 * lam - det_perm(A)
    assert sp.expand(cp.as_expr() - expect) == 0
# 自实现符号版 det(λI − A)（3×3，直接展开）也须同值：
def detx3(A, t):
    return (t - A[0][0]) * ((t - A[1][1]) * (t - A[2][2]) - A[1][2] * A[2][1]) \
        - A[0][1] * (A[1][0] * (t - A[2][2]) - A[1][2] * A[2][0]) \
        + A[0][2] * (A[1][0] * A[2][1] - (t - A[1][1]) * A[2][0])
R3 = ([0, 1, 0], [-1, 0, 0], [0, 0, 5])
assert sp.expand(detx3(R3, lam) - (lam**3 - 5 * lam**2 + lam - 5)) == 0
print("命题 4.93：h_A 系数 = (1, −tr, e₂, −det)；旋转块 h = λ³ − 5λ² + λ − 5 ✓")

print("END ====")
