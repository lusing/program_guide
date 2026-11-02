# -*- coding: utf-8 -*-
print("==== 08 random_variables")
# 离散、连续与混合分布共用 CDF；有理数账与有限枚举互不冒充。
from fractions import Fraction
from itertools import product
from math import comb


def poly_integral(coeffs, a, b):
    """精确计算低次系数在前多项式的定积分。"""
    prim = [Fraction(0)] + [c / (i + 1) for i, c in enumerate(coeffs)]
    ev = lambda cs, x: sum(c * x ** i for i, c in enumerate(cs))
    return ev(prim, b) - ev(prim, a)


# 三枚硬币：从样本点函数到 pmf，再累加成 CDF。
outcomes = list(product("HT", repeat=3))
pmf3 = {}
for outcome in outcomes:
    k = outcome.count("H")
    pmf3[k] = pmf3.get(k, Fraction(0)) + Fraction(1, 8)
assert pmf3 == {0: Fraction(1, 8), 1: Fraction(3, 8),
                2: Fraction(3, 8), 3: Fraction(1, 8)}
assert sum(pmf3.values()) == 1
cdf3, acc = {}, Fraction(0)
for k in range(4):
    acc += pmf3[k]
    cdf3[k] = acc
assert cdf3[2] == Fraction(7, 8)
assert cdf3[3] - cdf3[0] == Fraction(7, 8)  # P(0<X<=3)
print("three-coin pmf and CDF: exact enumeration: OK")

# 两骰和的 36 个等可能有序样本点。
counts = {r: 0 for r in range(2, 13)}
for a, b in product(range(1, 7), repeat=2):
    counts[a + b] += 1
for r, n in counts.items():
    assert n == 6 - abs(r - 7)
assert sum(counts.values()) == 36
print("two-dice triangle pmf: 36-cell enumeration: OK")

# 一般 p 的二项 pmf 与 CDF 区间公式。
def binom_pmf(n, p, k):
    return Fraction(comb(n, k)) * p**k * (1 - p)**(n - k)


n, p = 6, Fraction(1, 3)
pmf6 = {k: binom_pmf(n, p, k) for k in range(n + 1)}
F6, acc = {}, Fraction(0)
for k in range(n + 1):
    acc += pmf6[k]
    F6[k] = acc
assert sum(pmf6.values()) == 1 and F6[n] == 1
assert all(F6[k] <= F6[k + 1] for k in range(n))
assert F6[4] - F6[1] == sum(pmf6[k] for k in (2, 3, 4))
print("binomial CDF monotonicity and interval formula: OK")

# 连续侧：f(x)=2x，F(x)=x^2；端点开闭不改变概率。
twox = [Fraction(0), Fraction(2)]
assert poly_integral(twox, Fraction(0), Fraction(1)) == 1
assert poly_integral(twox, Fraction(0), Fraction(1, 4)) == Fraction(1, 16)
assert poly_integral(twox, Fraction(1, 4), Fraction(3, 4)) == Fraction(1, 2)
print("continuous f=2x: normalization and CDF interval probabilities: OK")

# 多项式密度的归一常数与 CDF。
shape = [Fraction(2), Fraction(3), Fraction(-5)]
area = poly_integral(shape, Fraction(0), Fraction(1))
assert area == Fraction(11, 6)
c = 1 / area
Fpoly = lambda x: c * poly_integral(shape, Fraction(0), x)
assert Fpoly(Fraction(1)) == 1
assert Fpoly(Fraction(1, 2)) == Fraction(7, 11)
assert Fpoly(Fraction(1, 4)) == Fraction(109, 352)
print("polynomial density: c=6/11 and exact CDF values: OK")

# 混合型：0 处有原子 1/2，(0,1) 上有总质量 1/2 的均匀部分。
def Fmix(x):
    if x < 0:
        return Fraction(0)
    if x == 0:
        return Fraction(1, 2)
    if x <= 1:
        return Fraction(1, 2) + x / 2
    return Fraction(1)


assert Fmix(0) == Fraction(1, 2)
assert Fmix(Fraction(1, 2)) == Fraction(3, 4)
assert Fmix(Fraction(1, 2)) - Fmix(0) == Fraction(1, 4)
assert Fmix(1) == 1
print("mixed CDF: atom 1/2 at zero plus continuous mass 1/2: OK")

print("END ====")
