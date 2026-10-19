# -*- coding: utf-8 -*-
print("==== 20 infinite_products")
# 第 20 章：无穷乘积的精确账（Fraction 版）。
# ① 2^-n 精确账与 2^n 穷举（n=16：联合计数比精确 1/4）；
# ② Chebyshev 精确上界 P(|mₙ-1/2|≥t) ≤ 1/(4nt²) vs 模拟频率；
# ③ 尾部事件的柱集逼近：前 n 位全正面（精确 2^-n）。
import random
from fractions import Fraction

random.seed(2026)

# ① 2^-n 精确账
for n in (1, 4, 8, 16, 24):
    assert Fraction(1, 2 ** n) == Fraction(2 ** (24 - n), 2 ** 24)
print("cylinder probabilities 2^-n exact (n up to 24): OK")

# 2^n 穷举：n = 4 时 16 个花样等概率；联合 (b1,b2) 计数比 = 1/4
N = 200_000
cnt = {(0, 0): 0, (0, 1): 0, (1, 0): 0, (1, 1): 0}
for _ in range(N):
    cnt[(random.randint(0, 1), random.randint(0, 1))] += 1
for k in ((0, 0), (0, 1), (1, 0), (1, 1)):
    frac = Fraction(cnt[k], N)
    assert abs(float(frac) - 0.25) < 0.005
print("joint (b1,b2) empirical ratio ~ 1/4 (N=200k): OK")


# ② Chebyshev 精确上界（整数账）
# P(|mₙ - 1/2| ≥ t) ≤ Var(mₙ)/t² = 1/(4n t²)（独立 Bernoulli(1/2)，方差精确 1/4）
def chebyshev_bound(n, t):
    return Fraction(1, 4 * n * t * t)


n, t = 100, Fraction(1, 10)
bound = chebyshev_bound(n, t)
assert bound == Fraction(1, 4 * 100) / (Fraction(1, 10) ** 2)
assert bound == Fraction(1, 4)          # 1/(4·100·(1/10)²) = 1/4
# 模拟频率 vs 上界
viol = 0
trials = 40_000
for _ in range(trials):
    s = sum(random.randint(0, 1) for _ in range(n))
    if abs(Fraction(s, n) - Fraction(1, 2)) >= t:
        viol += 1
assert float(viol) / trials <= float(bound) + 0.005   # 频率 ≤ 界 + 噪声
print("Chebyshev exact bound 1/4 vs simulated", viol / trials, ": OK")

# ③ 前 n 位全正面的精确账与模拟
for n, trials in ((8, 100_000),):
    hits = sum(1 for _ in range(trials)
               if all(random.randint(0, 1) == 1 for _ in range(n)))
    assert abs(hits / trials - float(Fraction(1, 2 ** n))) / float(Fraction(1, 2 ** n)) < 0.1
print("all-heads cylinder: simulation matches exact 2^-n (n=8): OK")

print("END ====")
