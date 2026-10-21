# -*- coding: utf-8 -*-
print("==== 18 inequalities_lln")
# 第 18 章 Python：不等式与大数定律的精确账。
# ① Markov/Chebyshev/真值三方对照表；② 两点反例（零均值
#    族把概率推到 1）；③ WLLN 的 σ²/(nε²) 界 vs 模拟真值；
# ④ Boole/Bonferroni 夹逼；⑤ 1/√n 律收敛表。
from fractions import Fraction
from math import exp, sqrt


# ① 三方对照
# Unif(0,1)：P(X >= 0.95) —— Markov 0.5/0.95；Chebyshev
# k = 0.45/sqrt(1/12)（注意 σ 不是 σ²！）；真值 0.05
markov_u = Fraction(1, 2) / Fraction(95, 100)
k_u = 0.45 / sqrt(1 / 12)
cheb_u = 1 / k_u ** 2
assert abs(markov_u - Fraction(10, 19)) < 1e-12
assert abs(cheb_u - 100 / 243) < 1e-9            # 原书的修正版账
assert 0.05 < cheb_u < markov_u                   # 界在真值上方
# Exp(1)：P(X >= 4) —— Markov 1/4；Chebyshev k=3 → 1/9；真值 e^{-4}
markov_e, cheb_e, true_e = 0.25, 1 / 9, exp(-4)
assert true_e < cheb_e < markov_e
print("three-way table: bounds above truth, chebyshev tighter: OK")

# ② 两点反例：P(X=2)=p、P(X=-b)=1-p、b=2p/(1-p) 配平零均值
for p in (Fraction(1, 2), Fraction(9, 10), Fraction(99, 100)):
    b = 2 * p / (1 - p)
    mu = 2 * p + (-b) * (1 - p)
    assert mu == 0                                 # 零均值配平
    assert p > Fraction(9, 10) or p <= Fraction(9, 10)  # p 可任意接近 1
print("two-point family: zero mean, P(X>=2)=p arbitrarily close to 1: OK")

# Chebyshev 换算事故的账：σ²=1/12 误当 σ → k=27/5 → 界 25/729 < 真值 0.05
bad_k = 0.45 / (1 / 12)
bad_bound = 1 / bad_k ** 2
assert abs(bad_bound - 25 / 729) < 1e-12
assert bad_bound < 0.05                            # 界低于真值 = 事故信号
print("sigma-vs-sigma^2 trap: bad bound 25/729 < truth 0.05 (caught): OK")

# ③ WLLN：Y = 1−Exp(1)（零均值、方差 1），ε = 0.1；
#    Chebyshev 界 σ²/(nε²) 的递减 vs 模拟真值
import random as _r
_r.seed(18)
for n, trials in ((100, 20_000), (10_000, 5_000), (100_000, 500)):
    bound = 1.0 / (n * 0.1 ** 2)
    hits = 0
    for _ in range(trials):
        s = sum(1.0 - _r.expovariate(1.0) for _ in range(n)) / n
        if abs(s) >= 0.1:
            hits += 1
    emp = hits / trials
    assert emp < bound + 0.002                     # 界成立（模拟精度内）
    if n >= 10_000:
        assert emp < bound                         # 真值远低于界
print("WLLN: empirical P(|Xbar-mu|>=eps) below sigma^2/(n eps^2): OK")

# ④ Boole/Bonferroni：四骰至少一个 6
# S1 = 4·(1/6)；S2 = C(4,2)(1/6)^2；真值 = 1-(5/6)^4
S1 = Fraction(4, 6)
S2 = Fraction(6, 36)                         # C(4,2)·(1/6)^2 = 1/6
true_p = 1 - Fraction(5 ** 4, 6 ** 4)
assert S1 - S2 < true_p < S1                  # Bonferroni 下界 < 真值 < Boole 上界
print("boole/bonferroni: S1-S2 < 1-(5/6)^4 < S1 sandwich: OK")

# ⑤ 1/√n 律：样本均值标准差的表（总体 σ=1）
print("1/sqrt(n) law:", ", ".join(f"n={n}: {1/sqrt(n):.4f}"
      for n in (10, 100, 10_000)))
print("END ====")
