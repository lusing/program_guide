# -*- coding: utf-8 -*-
print("==== 13 discrete_dists")
# 第 13 章 Python：离散分布族的精确分数账。
# ① 五族 pmf 截断归一与矩；② 赌骰期望 239/1296；③ 饼干
#    3-2-1 与三色边际 = Bin 检查；④ 几何黄紫球尾部；⑤ German
#    Tank 全组合枚举 E[M] vs 公式；⑥ Poisson 邮局与 IKEA。
from fractions import Fraction
from itertools import product
from math import comb, exp, factorial

# ① 五族
p = Fraction(1, 3)
# Bernoulli
assert 1 * p + 0 * (1 - p) == p
assert (1 - p) ** 2 * p + p ** 2 * (1 - p) == p * (1 - p)
# Binomial(6, 1/3)：归一 + 矩（线性性 np / np(1−p)）
n = 6
pmf_bin = {k: Fraction(comb(n, k)) * p ** k * (1 - p) ** (n - k)
           for k in range(n + 1)}
assert sum(pmf_bin.values()) == 1
assert sum(k * pmf_bin[k] for k in range(n + 1)) == n * p == 2
assert sum(k * k * pmf_bin[k] for k in range(n + 1)) - (n * p) ** 2 == n * p * (1 - p)
# Geometric(p)：截断归一 + 均值 1/p（截断逼近）
N = 60
pmf_geo = [p * (1 - p) ** (m - 1) for m in range(1, N + 1)]
assert abs(float(sum(pmf_geo)) - 1.0) < 1e-10   # 截断尾 (2/3)^60 ≈ 2.5e-11
mu_geo = sum(m * pmf_geo[m - 1] for m in range(1, N + 1))
assert abs(float(mu_geo) - 3.0) < 5e-9                  # 1/p = 3
# NegBin(r=2, p=1/3)：截断归一 + 均值 rp/(1−p) = 1
r = 2
pmf_nb = [Fraction(comb(k + r - 1, k)) * p ** k * (1 - p) ** r
          for k in range(N)]
assert abs(float(sum(pmf_nb)) - 1.0) < 5e-9   # 多项式加权尾更肥
mu_nb = sum(k * pmf_nb[k] for k in range(N))
assert abs(float(mu_nb) - 1.0) < 1e-7                   # rp/(1−p) = 1
# Poisson(1/2)：截断归一（e^λ Taylor 的数值对拍）
lam = 0.5
pmf_pois = [lam ** k * exp(-lam) / factorial(k) for k in range(N)]
assert abs(sum(pmf_pois) - 1.0) < 1e-12
print("five families: normalization & moments exact/near-exact: OK")

# ② 赌骰期望：四骰押点，k 次赢 k 元、零次输 1 元
EX = Fraction(0)
for k in range(5):
    EX += Fraction((-1 if k == 0 else k) * comb(4, k) * 5 ** (4 - k), 6 ** 4)
assert EX == Fraction(239, 1296)
print("four-die game: E = 239/1296 =", round(float(EX), 6), ": OK")

# ③ 饼干：有放回抽 6 块恰 3-2-1（Fraction 精确）
P = Fraction(factorial(6), factorial(3) * factorial(2) * factorial(1)) \
    * Fraction(45, 100) ** 3 * Fraction(30, 100) ** 2 * Fraction(25, 100)
assert abs(float(P) - 0.123) < 5e-4
# 全枚举对拍：729 加权序列（每序列概率 = 各次抽取概率之积）
pw = (Fraction(45, 100), Fraction(30, 100), Fraction(25, 100))
enumP = Fraction(0)
for seq in product(range(3), repeat=6):
    if seq.count(0) == 3 and seq.count(1) == 2:
        w = Fraction(1)
        for c in seq:
            w *= pw[c]
        enumP += w
assert enumP == P
# 边际：X1 = 巧克力数 ~ Bin(6, 0.45)（归一检查）
assert abs(float(sum(Fraction(comb(6, k)) * Fraction(45, 100) ** k
                    * Fraction(55, 100) ** (6 - k) for k in range(7)) - 1)) < 1e-12
print("cookie 3-2-1 = 729-enum =", round(float(P), 6), "; marginal = Bin(6,.45): OK")

# ④ 黄紫球：P(D >= m) = (y/(p+y))^(m−1)
pp, yy = Fraction(3), Fraction(5)
for m in (1, 2, 4):
    tail = sum(pp / (pp + yy) * (yy / (pp + yy)) ** (j - 1) for j in range(m, 60))
    assert abs(float(tail) - float((yy / (pp + yy)) ** (m - 1))) < 1e-12
print("purple/yellow balls geometric tail: OK")

# ⑤ German Tank：N=12, k=3 全组合枚举 E[M] vs k/(k+1)·(N+1)
Nt, kt = 12, 3
from itertools import combinations
total = 0
cnt = 0
for S in combinations(range(1, Nt + 1), kt):
    total += max(S)
    cnt += 1
assert cnt == comb(Nt, kt)
assert Fraction(total, cnt) == Fraction(kt, kt + 1) * (Nt + 1)   # = 9
est = Fraction(kt + 1, kt) * 9 - 1                                # m=9 反解
assert est == 11
print("German tank N=12,k=3: E[M]=9 = k/(k+1)(N+1) by 220 combos: OK")

# ⑥ Poisson 例：邮局 1−e^{−1/3}；IKEA P(<=3)
assert abs((1 - exp(-1 / 3)) - 0.28346) < 1e-5
ikea = sum((1 / 2) ** k * exp(-1 / 2) / factorial(k) for k in range(4))
assert abs(ikea - 0.998) < 5e-4
print("Poisson post office 0.2835, IKEA 0.998: OK")

print("END ====")
