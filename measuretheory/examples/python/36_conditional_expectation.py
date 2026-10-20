# -*- coding: utf-8 -*-
print("==== 36 conditional_expectation")
# 第 36 章 Python：分块平均（Fraction 精确版）。
# ① 分块平均与塔性质；② 取出性质；③ Jensen 方向判定；
# ④ 投影残差正交（整数内积账）。
from fractions import Fraction

X = [Fraction(3, 2), Fraction(-1), Fraction(5), Fraction(7, 2),
     Fraction(2), Fraction(-3, 4), Fraction(1), Fraction(9)]
G1 = [range(0, 4), range(4, 8)]                    # 两块精化
G0 = [range(0, 8)]                                 # 平凡划分

def blockavg(x, blocks):
    out = [None] * len(x)
    for b in blocks:
        m = sum(x[i] for i in b) / len(b)
        for i in b:
            out[i] = m
    return out

E1 = blockavg(X, G1)
E0 = blockavg(X, G0)

# ① 分块平均
assert E1[0] == (X[0] + X[1] + X[2] + X[3]) / 4
assert E1[7] == (X[4] + X[5] + X[6] + X[7]) / 4
print("block averages exact: OK")

# ② 塔：E[E[X|G1]|G0] = E[X|G0]
tower = blockavg(E1, G0)
assert tower == E0
print("tower property exact: OK")

# ③ 取出：Z 块常数时 E[ZX|G1] = Z·E[X|G1]
Z = [Fraction(3)] * 4 + [Fraction(-2)] * 4
lhs = blockavg([z * x for z, x in zip(Z, X)], G1)
assert lhs == [z * e for z, e in zip(Z, E1)]
print("pull-out property exact: OK")

# ④ Jensen 方向（凸 φ = x²）
phi_X = blockavg([x * x for x in X], G1)
assert all(p >= e * e for p, e in zip(phi_X, E1))
print("Jensen x^2: blockwise E[X^2] >= (E[X])^2 exact: OK")

# ⑤ 残差正交（与块常数向量的内积 = 0，整数比例账）
resid = [x - e for x, e in zip(X, E1)]
for b in G1:
    dot = sum(resid[i] for i in b)                # 与常值 1 的内积
    assert dot == 0
# 与 Z 的内积
assert sum(z * r for z, r in zip(Z, resid)) == 0
print("residual orthogonal to all G1-measurable vectors: exact: OK")

print("END ====")
