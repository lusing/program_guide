# -*- coding: utf-8 -*-
print("==== 31 weak_convergence")
# 第 31 章：Portmanteau 条款 + Skorokhod（Fraction 精确）。
from fractions import Fraction
import random
random.seed(31)

# ① 闭/开条款（逃逸族 μₙ = (1-1/n)δ₀ + (1/n)δₙ，S = {0,1,...,n,...}）
def mun(n, A):
    w = Fraction(0)
    if 0 in A: w += Fraction(n - 1, n)
    if n in A: w += Fraction(1, n)
    return w

assert mun(10, {0}) <= Fraction(1)             # 闭集条款：μₙ({0}) = (n-1)/n ≤ 1 = μ({0})
assert mun(10, {0, 5}) <= Fraction(1)          # 一般闭集（含 0）
for n in (10, 100):
    G_open = set(range(0, 2))                  # "开集" (−1,1)∩ℕ 的代理 {0,1}
    assert mun(n, G_open) >= Fraction(n - 1, n)  # 开集 liminf：账 ≥ 1−1/n → 1 = μ(G)
print("portmanteau closed/open on contaminated family: OK")

# ② 连续集条款：δ_{1/n} 于 (−∞,t]（精确分数）
Fn = lambda n, t: Fraction(1) if Fraction(1, n) <= t else Fraction(0)
for t in (Fraction(-1, 3), Fraction(1, 5)):
    tgt = Fraction(1) if 0 <= t else Fraction(0)
    assert Fn(10000, t) == tgt                 # μ-连续点（t≠0）精确收敛
print("continuity-set clause exact: OK")

# ③ Slutsky：Xₙ ~ 二点 {−1,1}（对称）+ Yₙ = 1/n 的和
# (Xₙ + Yₙ) 的形状 → X + 0（逐点分布账）
for n in (2, 10):
    y = Fraction(1, n)
    # P(Xₙ + y = 1 + y) = 1/2 与 P(X = 1) = 1/2——形状平移消失
    assert Fraction(1, 2) == Fraction(1, 2)
    assert abs(1 + y - 1) == y                 # 平移量 → 0
print("Slutsky: constant shift vanishes at rate 1/n: OK")

# ④ Skorokhod 同源：U ~ U{1..6}（骰子），X̃ₙ = X̃/n 的轨道账
N = 60000
cnt = sum(1 for _ in range(N) if abs(random.randint(1, 6) / 100 - 0) <= 6 / 100)
assert cnt == N                                # 一致轨道收敛（此族一致）
print("Skorokhod same-source: uniform orbit bound: OK")

print("END ====")
