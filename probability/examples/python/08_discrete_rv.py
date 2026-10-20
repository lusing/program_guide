# -*- coding: utf-8 -*-
print("==== 08 discrete_rv")
# 第 08 章 Python：离散随机变量的精确分数账。
# ① 三硬币 pmf 表（8 结果枚举）；② 二项 n=4 的 16 字符串
#    枚举 vs 公式 C(4,k)/16；③ 二项 CDF 阶梯（n=5、p=1/2，
#    P(X≤2) = 1/2）；④ 两骰和 pmf 的 36 格账与矩；
# ⑤ CDF 四性质的程序化核查（n=6、p=1/3）。
from fractions import Fraction
from itertools import product
from math import comb

# ① 三硬币：枚举 8 个结果，按正面数归并
outcomes = list(product("HT", repeat=3))
pmf3 = {}
for o in outcomes:
    k = o.count("H")
    pmf3[k] = pmf3.get(k, Fraction(0)) + Fraction(1, 8)
assert pmf3 == {0: Fraction(1, 8), 1: Fraction(3, 8),
                2: Fraction(3, 8), 3: Fraction(1, 8)}
assert sum(pmf3.values()) == 1
print("three-coin pmf = {1/8, 3/8, 3/8, 1/8}, sums to 1: OK")

# ② 二项 n=4、p=1/2：16 字符串全枚举 vs 公式
pmf4 = {}
for o in product("HT", repeat=4):
    k = o.count("H")
    pmf4[k] = pmf4.get(k, Fraction(0)) + Fraction(1, 16)
for k in range(5):
    assert pmf4[k] == Fraction(comb(4, k), 16)
assert sum(pmf4.values()) == 1
print("binomial(4,1/2): 16-string enumeration = C(4,k)/16: OK")


def binom_pmf(n, p, k):
    return Fraction(comb(n, k)) * p ** k * (1 - p) ** (n - k)


# ③ 二项 CDF 阶梯：n=5、p=1/2
p = Fraction(1, 2)
stair, acc = {}, Fraction(0)
for k in range(6):
    acc += binom_pmf(5, p, k)
    stair[k] = acc
assert stair[2] == Fraction(1, 2)        # (1+5+10)/32：对称中轴
assert stair[5] == 1
vals = [stair[k] for k in range(6)]
assert all(a <= b for a, b in zip(vals, vals[1:]))          # 单调
assert stair[4] - stair[2] == Fraction(15, 32)              # 区间公式
print("binomial(5,1/2) CDF: F(2)=1/2, monotone, F(4)-F(2)=15/32: OK")

# ④ 两骰和：36 格枚举 vs 三角形公式；矩账
counts = {}
for a in range(1, 7):
    for b in range(1, 7):
        r = a + b
        counts[r] = counts.get(r, 0) + 1
assert sum(counts.values()) == 36
for r in range(2, 13):
    assert Fraction(counts[r], 36) == Fraction(6 - abs(r - 7), 36)
mu = sum(Fraction(r * counts[r], 36) for r in range(2, 13))
ex2 = sum(Fraction(r * r * counts[r], 36) for r in range(2, 13))
assert mu == 7
assert ex2 == Fraction(329, 6)                       # 49 + 35/6
assert ex2 - mu * mu == Fraction(35, 6)              # Var（第 10 章）
print("two-dice: triangle pmf, mean=7, E[R2]=329/6, Var=35/6: OK")

# ⑤ CDF 四性质：n=6、p=1/3（一般 p 下的再核查）
n, q = 6, Fraction(1, 3)
pmf6 = {k: binom_pmf(n, q, k) for k in range(n + 1)}
assert sum(pmf6.values()) == 1                       # 归一
F6, acc = {}, Fraction(0)
for k in range(n + 1):
    acc += pmf6[k]
    F6[k] = acc
assert F6[n] == 1                                    # 上极限 1
assert all(F6[k] <= F6[k + 1] for k in range(n))     # 单调
assert F6[4] - F6[1] == sum(pmf6[k] for k in (2, 3, 4))   # 区间公式
print("CDF four properties on binomial(6,1/3): OK")

print("END ====")
