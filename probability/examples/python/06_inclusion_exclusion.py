# -*- coding: utf-8 -*-
print("==== 06 inclusion_exclusion")
# 第 06 章 Python：容斥、错排、占位数与组合恒等式的精确账。
from fractions import Fraction
from math import comb, factorial
from itertools import product


def derangement_closed(n):
    """D_n = n! sum_{k=0}^n (-1)^k / k!."""
    return factorial(n) * sum(
        Fraction((-1) ** k, factorial(k)) for k in range(n + 1)
    )


def derangement_rec(n):
    """D_0=1, D_n = n D_{n-1} + (-1)^n."""
    d = 1
    for i in range(1, n + 1):
        d = i * d + (-1) ** i
    return d


# ① 错排：闭式、递推和全枚举小例三方会师。
for n in range(0, 11):
    closed = derangement_closed(n)
    rec = derangement_rec(n)
    assert closed.denominator == 1
    assert closed == rec
assert [derangement_closed(n) for n in range(8)] == [1, 0, 1, 2, 9, 44, 265, 1854]
enum4 = sum(1 for p in product(range(4), repeat=4)
            if len(set(p)) == 4 and all(p[i] != i for i in range(4)))
assert enum4 == derangement_closed(4) == 9
print("derangements D_0..D_7 and n=4 enumeration all give D_4=9: OK")

# D_n/n! 是 e^-1 的交错级数部分和；余项小于下一项 1/(n+1)!。
e = 2.71828182845904523536
for n in (4, 6, 8, 10):
    q = derangement_closed(n) / factorial(n)
    assert abs(float(q) - 1 / e) < 1 / factorial(n + 1)
print("D_n/n! approaches 1/e within alternating-series bound: OK")

# ② 三事件容斥：36 个两骰结果上逐点审计。
omega = list(product(range(1, 7), repeat=2))
def P(event):
    return Fraction(sum(1 for w in omega if event(w)), 36)

A = lambda w: w[0] == 6
B = lambda w: w[1] == 6
C = lambda w: w[0] == w[1]
rhs = P(A) + P(B) + P(C) \
    - P(lambda w: A(w) and B(w)) \
    - P(lambda w: A(w) and C(w)) \
    - P(lambda w: B(w) and C(w)) \
    + P(lambda w: A(w) and B(w) and C(w))
assert P(lambda w: A(w) or B(w) or C(w)) == rhs == Fraction(16, 36)
print("three-event inclusion-exclusion on dice gives 16/36: OK")

# ③ 占位数：4 个可辨球独立进 3 个可辨篮，所有篮均非空。
n_bins, n_balls = 3, 4
assignments = list(product(range(n_bins), repeat=n_balls))
enum_cover = sum(1 for a in assignments if len(set(a)) == n_bins)
ie_count = sum((-1) ** j * comb(n_bins, j) * (n_bins - j) ** n_balls
               for j in range(n_bins + 1))
assert ie_count == enum_cover == 36
assert Fraction(enum_cover, len(assignments)) == Fraction(36, 81)
print("occupancy full-cover: 3^4 - 3*2^4 + 3*1^4 = 36/81: OK")

# ④ Vandermonde：从两个固定组共选 k 人，按从第一组选几个分类。
for m, n, k in ((3, 2, 2), (5, 4, 3), (8, 7, 6)):
    lhs = sum(comb(m, j) * comb(n, k - j) for j in range(k + 1))
    assert lhs == comb(m + n, k)
print("Vandermonde identity checked on three parameter triples: OK")

# ⑤ Hockey-stick：按最大元给 r+1 元子集分类。
for r, n in ((2, 10), (3, 15), (1, 20)):
    assert sum(comb(i, r) for i in range(r, n + 1)) == comb(n + 1, r + 1)
print("hockey-stick sums checked for three parameter pairs: OK")

# ⑥ 全体子集总大小和两阶段选择账。
for n in (4, 10, 15):
    assert sum(k * comb(n, k) for k in range(n + 1)) == n * 2 ** (n - 1)
print("sum k*C(n,k)=n*2^(n-1), including n=4 total size 32: OK")

# ⑦ 交换记账顺序：先选 k 人再选其中 j 人。
for n, k, j in ((8, 5, 3), (10, 6, 2)):
    assert comb(n, k) * comb(k, j) == comb(n, j) * comb(n - j, k - j)
print("order-swap identity C(n,k)C(k,j)=C(n,j)C(n-j,k-j): OK")

print("END ====")
