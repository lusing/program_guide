# 第 24 章 · 向量空间 —— Python 通道

from itertools import product, permutations
from fractions import Fraction

print("==== 24 向量空间")


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


from random import seed, randint

seed(20261104)
for _ in range(50):
    A = [[randint(0, 2) for _ in range(4)] for _ in range(4)]
    _, r1 = rref(A, 3)
    _, r2 = rref(A[::-1], 3)
    assert r1 == r2
print("维数不变性：50 组 GF(3) 4×4 rank 与消元顺序无关 ✓")

vectors = [list(v) for v in product([0, 1], repeat=3)]
assert len(vectors) == 8
assert sum(any(v) for v in vectors) == 7

indep = 0
for u in vectors:
    for v in vectors:
        if not any(u) or not any(v) or u == v:
            continue
        dep = any(a * u == b * v for a in (0, 1) for b in (0, 1) if (a, b) != (0, 0))
        if not dep:
            indep += 1
assert indep == 42

bases = 0
for i, j, k in permutations(range(8), 3):
    M = [vectors[i], vectors[j], vectors[k]]
    M_t = [[M[r][c] for r in range(3)] for c in range(3)]
    _, rk = rref(M_t, 2)
    if rk == 3:
        bases += 1
assert bases == 168
print("计数：|V| = 8、非零 7、无关对 42、有序基 168 = |GL(3,2)| ✓")

# GF(2)³ 子空间清单 = Fano
def closed(S):
    return all([(a + b) % 2 for a, b in zip(u, v)] in S for u in S for v in S)


subspaces = set()
for mask in range(256):
    S = [vectors[i] for i in range(8) if (mask >> i) & 1]
    if not S:
        continue
    if closed(S):
        subspaces.add(tuple(sorted(map(tuple, S))))
assert len(subspaces) == 16
lines = sum(1 for S in subspaces if len(S) == 2)
assert lines == 7
planes = sum(1 for S in subspaces if len(S) == 4)
assert planes == 7
print("GF(2)³：16 个子空间（{0} + 7 直线 + 7 平面 + 全空间）；7 直线 = Fano 点 ✓")

# GF(3)³ 平面数 13
def span3(u, v):
    return {tuple((a * x + b * y) % 3 for x, y in zip(u, v))
            for a in range(3) for b in range(3)}


planes3 = {tuple(sorted(span3(u, v)))
           for u in vectors if any(u)
           for v in vectors if any(v)
           if len(span3(u, v)) == 9}
# 注意 vectors 是 GF(2) 的——需要 GF(3) 向量
vecs3 = [list(v) for v in product(range(3), repeat=3)]
planes3 = {tuple(sorted(span3(u, v)))
           for u in vecs3 if any(u)
           for v in vecs3 if any(v)
           if len(span3(u, v)) == 9}
assert len(planes3) == 13
print("GF(3)³ 的 2 维子空间恰 13 个 ✓")

print("END ====")
