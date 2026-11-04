# -*- coding: utf-8 -*-
print("==== 129 equipollence")
# 第 129 章 Python：等势的精确计算面。
# ① 配对函数 f(k,n)=2^k(2n+1)−1 的往返与分解（书 3.3.9）；
# ② 鸽笼原理的穷举（书 3.3.5）：n 到任何更小集合的映射必撞车；
# ③ 交错序列的并可数（书 3.3.7）与 zigzag 名单（ℚ 可数的影子）；
# ④ 戴德金有穷的有限侧审计：有限集到真子集的双射不存在。
from fractions import Fraction
from itertools import product
from math import gcd


# ① 配对函数：N×N → N 的显式双射
def pairkn(k, n):
    return 2 ** k * (2 * n + 1) - 1


def unpair(m):
    """m+1 分解为 2^k · 奇数——第 124 章的素数分解在这里复用。"""
    q, k = m + 1, 0
    while q % 2 == 0:
        q //= 2
        k += 1
    return k, (q - 1) // 2


grid = [(k, n) for k in range(7) for n in range(50)]
codes = [pairkn(k, n) for k, n in grid]
assert len(set(codes)) == len(codes)                  # 单射
for m in range(300):
    k, n = unpair(m)
    assert pairkn(k, n) == m and 2 * n + 1 >= 1       # 满射 + 往返复原
print("pairing: 2^k(2n+1)-1 bijective on grid, roundtrip 0..299: OK")

# ② 鸽笼原理（书 3.3.5）：n 到真子集的双射不存在——穷举一切映射
for n in (2, 3, 4):
    for size in range(n):                             # 目标集 {0..size-1}，size<n
        for f in product(range(size), repeat=n):      # 全部 n 元组映射
            assert len(set(f)) < n                    # 必有撞车：不单
print("pigeonhole: every map from n-set to smaller set collides, n<=4: OK")

# ③ 交错序列（书 3.3.7）：c_{2k}=a_k, c_{2k+1}=b_k
a = list(range(0, 40, 2))
b = list(range(1, 41, 2))
c = [x for pair in zip(a, b) for x in pair]
assert sorted(set(c)) == list(range(40))              # 不重不漏
# zigzag 名单回访（第 123 章）：互素对的枚举就是 ℚ⁺ → N 的单射
def rationals(count):
    out, d = [], 1
    while len(out) < count:
        for p in range(d + 1):
            q = d - p
            if q >= 1 and gcd(p, q) == 1:
                out.append(Fraction(p, q))
        d += 1
    return out

qs = rationals(300)
assert len(set(qs)) == len(qs) >= 300                 # 不重（末条对角线可超额）
print("countable unions: interleave exact; Q+ enumeration injective: OK")

# ④ 戴德金有穷（书 3.3.11(4)）的有限侧：有限集的真子集严格更小——
#    "到真子集的双射"只在无穷出现（第 123 章的希尔伯特旅馆）。
from itertools import chain, combinations


def subsets(X):
    X = list(X)
    return chain.from_iterable(combinations(X, r) for r in range(len(X) + 1))


for n in (2, 3, 4):
    full = frozenset(range(n))
    for S in subsets(range(n)):
        S = frozenset(S)
        if S != full:
            assert len(S) < n                         # 真子集必更小：有限性
print("dedekind-finite shadow: every proper subset of a finite set is smaller: OK")
print("END ====")
