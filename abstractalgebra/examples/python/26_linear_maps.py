# 第 26 章 · 线性变换 —— Python 通道

from itertools import product, permutations
from random import seed, randint

print("==== 26 线性变换")


def det_gf2(M):
    return (M[0][0] * M[1][1] - M[0][1] * M[1][0]) % 2


def matmul2(A, B, p):
    return [[sum(A[i][k] * B[k][j] for k in range(2)) % p for j in range(2)] for i in range(2)]


# GL(2,2) 枚举
gl = [M for M in product([0, 1], repeat=4)]
gl = [[list(M[:2]), list(M[2:])] for M in gl]
gl = [M for M in gl if det_gf2(M) == 1]
assert len(gl) == 6

# 乘法封闭性
for M in gl:
    for N in gl:
        P = matmul2(M, N, 2)
        assert P in gl
print("GL(2,2)：6 个矩阵、乘法封闭 ✓")

# 与 S₃ 同构：矩阵作用在非零向量 {e1, e2, e1+e2} 上
nonzero = [[1, 0], [0, 1], [1, 1]]


def label(v):
    w = [t % 2 for t in v]
    return nonzero.index(w) + 1


def phi(M):
    return [label([M[i][0] * w[0] + M[i][1] * w[1] for i in range(2)]) for w in nonzero]

s3 = list(permutations([1, 2, 3]))
phis = [tuple(phi(M)) for M in gl]
assert len(set(phis)) == 6 and set(phis) == set(s3)

def compose(p, q):
    return tuple(p[q[j] - 1] for j in range(3))

for M in gl:
    for N in gl:
        P = matmul2(M, N, 2)
        assert tuple(phi(P)) == compose(phi(M), phi(N))
print("GL(2,2) ≅ S₃：矩阵幂 ↦ 置换复合（36 对）✓")

# GL(2,3) = 48
def det3(M):
    return (M[0][0] * M[1][1] - M[0][1] * M[1][0]) % 3


cnt = sum(1 for M in product(range(3), repeat=4)
          if det3([list(M[:2]), list(M[2:])]) != 0)
assert cnt == (9 - 1) * (9 - 3)
print("|GL(2,3)| = (9−1)(9−3) = 48 ✓")


# 秩-零化度 + 相似不变量（GF(7)）
def rref(A, p):
    A = [row[:] for row in A]
    m, n = len(A), len(A[0])
    rk = 0
    for c in range(n):
        if rk >= m:
            break
        piv = next((r for r in range(rk, m) if A[r][c] % p), None)
        if piv is None:
            continue
        A[rk], A[piv] = A[piv], A[rk]
        inv = pow(A[rk][c], -1, p)
        A[rk] = [(x * inv) % p for x in A[rk]]
        for r in range(m):
            if r != rk:
                fac = A[r][c]
                A[r] = [(x - fac * y) % p for x, y in zip(A[r], A[rk])]
        rk += 1
    return A, rk


def inv_gf(P, p):
    m = len(P)
    aug = [row[:] + [1 if i == j else 0 for j in range(m)] for i, row in enumerate(P)]
    aug, _ = rref(aug, p)
    return [row[m:] for row in aug]


def det_gf7(A):
    d = (A[0][0] * (A[1][1] * A[2][2] - A[1][2] * A[2][1])
         - A[0][1] * (A[1][0] * A[2][2] - A[1][2] * A[2][0])
         + A[0][2] * (A[1][0] * A[2][1] - A[1][1] * A[2][0]))
    return d % 7


seed(20261104)
checked = 0
for _ in range(200):
    A = [[randint(0, 6) for _ in range(3)] for _ in range(3)]
    P = [[randint(0, 6) for _ in range(3)] for _ in range(3)]
    if det_gf7(A) == 0 or det_gf7(P) == 0:
        continue
    Pinv = inv_gf(P, 7)
    A1 = [[sum(Pinv[i][k] * A[k][j] for k in range(3)) % 7 for j in range(3)] for i in range(3)]
    A1 = [[sum(A1[i][k] * P[k][j] for k in range(3)) % 7 for j in range(3)] for i in range(3)]
    assert sum(A1[i][i] for i in range(3)) % 7 == sum(A[i][i] for i in range(3)) % 7
    checked += 1
assert checked >= 50
print(f"相似不变量：{checked} 组 GF(7) trace(P⁻¹AP) = trace(A) ✓")

print("END ====")
