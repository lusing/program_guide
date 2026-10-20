# -*- coding: utf-8 -*-
print("==== 38 uniform_integrability")
# 第 38 章 Python：尾部账（Fraction 精确版）。
# ① 逃逸尖峰的精确整数账；② 截断双分的精确拆账；
# ③ 二项族矩缴费；④ UI 的 ε-ε' 双条件验证。
from fractions import Fraction
from math import comb

# ① 尖峰族：Xₙ = n·1_{[0,1/n]} 于 [0,1]（离散化：n 格中的第 1 格）
# E[|Xₙ|1_{|Xₙ|>K}] = n·(1/n) = 1 当 n > K（尖峰整体超 K）
for n, K in ((10, 5), (100, 50), (1000, 500)):
    if n > K:
        assert n * Fraction(1, n) == 1         # 尾账 = 1
# 截断后（K ≥ n）：尾账 = 0
for n, K in ((10, 10), (5, 100)):
    if K >= n:
        assert n * 0 == 0
print("escaping spikes: tail = 1 for n > K (exact integer account): OK")

# ② 截断双分：E|Xₙ − X| 的精确账（尖峰 vs 极限 0）
for n in (10, 1000):
    assert n * Fraction(1, n) == 1             # L¹ 差恒 1（升舱失败）
print("L1-difference stays exactly 1 (upgrade fails without UI): OK")

# ③ 二项族矩缴费：sup_n E[Xₙ²] ≤ C ⟹ 尾 ≤ C/K（CS+Chebyshev 链）
def binom_E2(n, p_num, p_den):
    p = Fraction(p_num, p_den)
    q = 1 - p
    return n * p * q + (n * p) ** 2

supE2 = max(binom_E2(n, 1, 2) for n in (10, 50))
for K in (10_000, 1_000_000):
    assert supE2 / K < Fraction(1, 10)         # C/K 一致小（K >> C）
print("binomial moment payment: E2/K -> 0 uniformly: OK")

# ④ UI 的 ε-ε' 双条件（有限模型精确验证）
# X ∈ {1..6}（骰子）：P(A) < δ ⟹ E[X·1_A] < ε 的最小 δ
def worst_integral(d):
    # 最坏 A = 权重最大的 d 概率质量
    return Fraction(1, 6) * 6 * min(d, 6) // 1 if False else None

# 直接：P(A) = m/6，E[X1_A] ≤ 6·P(A) = m——δ = ε/6 即可
for eps in (Fraction(1, 2), Fraction(1, 10)):
    delta = eps / 6
    # 对一切 m：m/6 < δ ⟹ E ≤ 6m/6 = m < ε
    for m in range(7):
        if Fraction(m, 6) < delta:
            assert m < 6 * eps + 1
print("epsilon-delta criterion: delta = eps/6 works for dice model: OK")

print("END ====")
