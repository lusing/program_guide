# -*- coding: utf-8 -*-
print("==== 39 esssup")
# 第 39 章 Python：尖刺账（Fraction 精确版）。
# ① 零测/正测尖刺的 ess sup 跳变表；② 格运算四条；
# ③ L∞ 范数的有限模型；④ 分块 ess sup。
from fractions import Fraction

def esssup(vals, weights, eps):
    """忽略权重 ≤ eps 的位置后的最大值（ess sup 的数值代理）。"""
    cands = [v for v, w in zip(vals, weights) if w > eps]
    return max(cands) if cands else None

# ① 尖刺跳变表
vals = [Fraction(1)] * 10 + [Fraction(2)]      # 第 11 位尖刺
w_zero = [Fraction(1, 10)] * 10 + [Fraction(0)]        # 尖刺零测
w_pos = [Fraction(1, 10)] * 10 + [Fraction(1, 10)]     # 尖刺正测
assert esssup(vals, w_zero, Fraction(0)) == 1          # 零测被无视
assert esssup(vals, w_pos, Fraction(0)) == 2           # 正测入账
assert max(vals) == 2                                 # sup 恒见
print("spike jump: esssup 1 (zero mass) vs 2 (positive mass), sup always 2: OK")

# ② 格运算四条
f = [Fraction(0)] * 5 + [Fraction(1)] * 5     # 1_A
g = [Fraction(1)] * 5 + [Fraction(0)] * 5     # 1_A^c
w = [Fraction(1, 10)] * 10
assert esssup(f, w, Fraction(0)) == 1
assert esssup(g, w, Fraction(0)) == 1
assert esssup([a + b for a, b in zip(f, g)], w, Fraction(0)) == 1   # 子可加严格
# 数乘与平移
h = [Fraction(3, 2) * x for x in f]
assert esssup(h, w, Fraction(0)) == Fraction(3, 2)
h2 = [x + Fraction(5) for x in f]
assert esssup(h2, w, Fraction(0)) == Fraction(6)
print("lattice ops: strict subadditivity, scaling, translation exact: OK")

# ③ L∞ 范数（有限模型）：‖X‖∞ = ess sup |X|
X = [Fraction(-2), Fraction(1), Fraction(3), Fraction(-1)]
wX = [Fraction(1, 4)] * 4
assert esssup([abs(x) for x in X], wX, Fraction(0)) == 3
# 改最大值位置的权重为 0：范数降
wX2 = [Fraction(1, 4), Fraction(1, 4), Fraction(0), Fraction(1, 4)]
assert esssup([abs(x) for x in X], wX2, Fraction(0)) == 2
print("L-infinity norm: ignores zero-mass maximum, finite model exact: OK")

# ④ 分块 ess sup（条件 ess sup 有限版）
blocks = [range(0, 2), range(2, 4)]
Y = [Fraction(5), Fraction(1), Fraction(2), Fraction(3)]
bmax = [max(Y[i] for i in b) for b in blocks]
assert max(bmax) == esssup(Y, [Fraction(1, 4)] * 4, Fraction(0)) == 5
print("blockwise ess sup: max of block maxima = global: OK")

print("END ====")
