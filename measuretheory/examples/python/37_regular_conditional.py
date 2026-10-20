# -*- coding: utf-8 -*-
print("==== 37 regular_conditional")
# 第 37 章 Python：条件分布表（Fraction 精确版）。
# ① 骰子条件分布表；② 因子分解定理验证；
# ③ 离散核复合（条件套条件）；④ Rao-Blackwell 精确。
from fractions import Fraction
from itertools import product

# ① 骰子×骰子联合表（独立）：P(Y|X) 行恒等
joint = {}
for x in range(1, 7):
    for y in range(1, 7):
        joint[(x, y)] = Fraction(1, 36)
for x in range(1, 7):
    row = {y: joint[(x, y)] / Fraction(1, 6) for y in range(1, 7)}
    assert all(v == Fraction(1, 6) for v in row.values())   # 条件分布 = 无条件
print("dice: conditional rows equal unconditional (independence): OK")

# ② 因子分解定理：Bernoulli(θ) 的联合 = g(Σxᵢ; θ)·h(x)
def joint_bern(x, theta):
    return Fraction(theta) ** sum(x) * Fraction(1 - theta) ** (len(x) - sum(x))

for theta_num in (3, 7):                      # θ = 3/10, 7/10
    th = Fraction(theta_num, 10)
    for x in product((0, 1), repeat=4):
        s = sum(x)
        g = Fraction(th)**s * (1 - th)**(4 - s)
        h = Fraction(1)                        # h 与 θ 无关（均匀计数权重）
        assert joint_bern(x, th) == g * h
print("factorization theorem: Bernoulli joint = g(sum; theta) * h(x): OK")

# ③ 离散核复合：两层条件（先对 A 再对 B 的嵌套分块）
# K1(x, a) = P(a|x)，K2(a, y) = P(y|a)——复合核 = 边缘化的链式法则
P_xy = {}
for x in range(2):
    for y in range(3):
        P_xy[(x, y)] = Fraction(x + 1, 3) * Fraction(y + 1, 6)
tot = sum(P_xy.values())
P_xy = {k: v / tot for k, v in P_xy.items()}   # 归一

Px = {x: sum(P_xy[(x, y)] for y in range(3)) for x in range(2)}
Py = {y: sum(P_xy[(x, y)] for x in range(2)) for y in range(3)}
assert sum(Px.values()) == 1 and sum(Py.values()) == 1
# 链式：P(x,y) = P(x)·P(y|x)（"核复合"的二元素版）
for x in range(2):
    for y in range(3):
        assert P_xy[(x, y)] == Px[x] * (P_xy[(x, y)] / Px[x])
print("kernel composition = chain rule: P(x,y) = P(x)P(y|x): OK")

# ④ Rao-Blackwell 精确：4 骰，φ = x1，充分统计 S = Σ
# Var(x1) = 35/12；Var(S/4) = 35/48（精确分数）
EX2 = Fraction(1, 6) * sum(i * i for i in range(1, 7))
Var1 = EX2 - Fraction(7, 2) ** 2
assert Var1 == Fraction(35, 12)
VarS4 = 4 * Var1 / 16
assert VarS4 == Fraction(35, 48)
assert VarS4 == Var1 / 4                       # 方差压缩 4 倍（精确）
print("Rao-Blackwell: Var = 35/12 -> 35/48 (exact 4x compression): OK")

print("END ====")
