# -*- coding: utf-8 -*-
print("==== 30 euclidean_convergence")
# 第 30 章：分布函数赛马（Fraction 精确版）。
# ① δ_{1/n} 跳点/连续点精确账；② δₙ 端点亏损；③ 污染逃逸保弱；
# ④ 二项 B(n,1/2) 的 cdf 收敛率（整数账）。
from fractions import Fraction

Fn = lambda n, x: Fraction(1) if Fraction(1, n) <= x else Fraction(0)
F = lambda x: Fraction(1) if 0 <= x else Fraction(0)

# ① 跳点与连续点
for n in (10, 100, 10000):
    assert Fn(n, Fraction(0)) == 0          # 跳点恒 0
assert F(Fraction(0)) == 1                  # 极限 1——失败账
for x in (Fraction(-1), Fraction(-1, 100), Fraction(3, 10), Fraction(2)):
    assert Fn(1000, x) == F(x)              # 连续点全部精确收敛
print("delta_{1/n}: jump fails (0 vs 1), continuity points exact: OK")

# ② δₙ 端点亏损（固定 x < 任意跑动 n）
G = lambda n, x: Fraction(1) if n <= x else Fraction(0)
for x in (Fraction(1, 2), 10, 1000):
    assert G(x + 1 if isinstance(x, int) else 100000, x) == 0
print("delta_n: fixed-x accounts hit 0 (mass escapes): OK")

# ③ 污染逃逸：μₙ = (1-1/n)δ₀ + (1/n)δₙ
g = lambda x: Fraction(1, 2) ** abs(x) if abs(x) < 100 else Fraction(0)  # C_b 型快速衰减检验
for n in (2, 10, 100):
    val = Fraction(n - 1, n) * g(0) + Fraction(1, n) * g(n)
    assert abs(val - g(0)) <= Fraction(1, n)  # 弱收敛账精确
print("contaminated escape: |integral - f(0)| <= 1/n exact: OK")

# ④ B(n, 1/2) 的 cdf 阶梯：跳点集与连续点收敛（整系数精确）
from math import comb
n = 40
probs = [Fraction(comb(n, k), 2 ** n) for k in range(n + 1)]
assert sum(probs) == 1                      # 归一精确
cdf_grid = list(__import__('itertools').accumulate(probs))
# 中位点 k = n/2 的 cdf 与对称正态 1/2 的差（形状收敛影子）
mid = n // 2
assert abs(float(cdf_grid[mid - 1]) - 0.5) < 0.16   # 阶梯中段逼近 1/2
print("B(40,1/2): exact normalization, mid-cdf near 1/2: OK")

print("END ====")
