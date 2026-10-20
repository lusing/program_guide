# -*- coding: utf-8 -*-
print("==== 10 expectation")
# 第 10 章 Python：期望工具的精确分数账。
# ① 多项式密度 r 阶矩闭式（r = 1..5）；② 两班级的均值/方差/
#    标准差（50 vs 1250）；③ 骰子捷径 vs 定义式双账；④ 两骰和
#    的矩；⑤ 三硬币矩账；⑥ 线性性与平移伸缩；⑦ 零协方差不
#    独立（X 与 X²）；⑧ 投资组合方差抛物线；⑨ 粘硬币联合表；
# ⑩ Cauchy 均值的路径依赖账。
from fractions import Fraction
from math import log, pi, sqrt


def poly_integral(coeffs, a, b):
    prim = [Fraction(0)] + [c / (i + 1) for i, c in enumerate(coeffs)]
    ev = lambda cs, x: sum(c * x ** i for i, c in enumerate(cs))
    return ev(prim, b) - ev(prim, a)


# ① 多项式密度 E[X^r] 闭式核对（r = 1..5）
shape = [Fraction(2), Fraction(3), Fraction(-5)]
c = Fraction(6, 11)
for r in range(1, 6):
    integrand = [Fraction(0)] * r + shape          # x^r · 形状
    num = poly_integral(integrand, Fraction(0), Fraction(1))
    closed = Fraction(7 * r + 11) / ((r + 1) * (r + 2) * (r + 3))
    assert c * num == c * closed
    assert num == closed                            # 逐 r 逐项相等
E1 = c * poly_integral([Fraction(0)] + shape, Fraction(0), Fraction(1))
assert E1 == Fraction(9, 22)
print("poly density r-moments match closed form (7r+11)/((r+1)(r+2)(r+3)): OK")


def dist(pairs):
    return pairs


E = lambda pairs: sum(Fraction(x) * p for x, p in pairs)
Var_def = lambda pairs: sum((Fraction(x) - E(pairs)) ** 2 * p for x, p in pairs)
Var_short = lambda pairs: sum(Fraction(x) ** 2 * p for x, p in pairs) - E(pairs) ** 2

# ② 两班级：均值同 50、方差 50 vs 1250、标准差比 5
w = Fraction(1, 5)
A = dist([(40, w), (45, w), (50, w), (55, w), (60, w)])
B = dist([(0, w), (25, w), (50, w), (75, w), (100, w)])
assert E(A) == 50 and E(B) == 50
va, vb = Var_def(A), Var_def(B)
assert va == 50 and vb == 1250
assert vb / va == 25
print("two sections: same mean 50, var 50 vs 1250 (std ratio 5): OK")

# ③ 骰子：捷径 vs 定义式
sixth = Fraction(1, 6)
die = dist([(k, sixth) for k in range(1, 7)])
assert E(die) == Fraction(7, 2)
assert Var_short(die) == Fraction(35, 12)
assert Var_def(die) == Var_short(die)              # 两条路会师
print("die: E=7/2, Var=35/12, shortcut = definition: OK")

# ④ 两骰和：μ = 7、E[R²] = 329/6、Var = 35/6
counts = {r: 6 - abs(r - 7) for r in range(2, 13)}
R = dist([(r, Fraction(n, 36)) for r, n in counts.items()])
assert E(R) == 7
assert Var_short(R) == Fraction(35, 6)
assert Var_def(R) == Fraction(35, 6)
print("two-dice sum: E=7, Var=35/6 both ways: OK")

# ⑤ 三硬币：E[X] = 3/2、E[X²] = 3、Var = 3/4
X3 = dist([(k, Fraction(comb_k, 8)) for k, comb_k in
           zip(range(4), (1, 3, 3, 1))])
assert E(X3) == Fraction(3, 2)
assert sum(Fraction(x) ** 2 * p for x, p in X3) == 3
assert Var_short(X3) == Fraction(3, 4)
print("three coins: E=3/2, E[X2]=3, Var=3/4: OK")

# ⑥ 线性性与平移伸缩：E[3X+2] 与 Var(3X+2)
lin = dist([(3 * k + 2, sixth) for k in range(1, 7)])
assert E(lin) == 3 * Fraction(7, 2) + 2            # a·μ + b
assert Var_short(lin) == 9 * Fraction(35, 12)      # a²·σ²（b 不进方差）
print("linearity: E[3X+2]=3*7/2+2, Var=9*35/12: OK")

# ⑦ 零协方差不独立：X 均匀 {−2,−1,1,2}，Y = X²
q = Fraction(1, 4)
xs = (-2, -1, 1, 2)
X = dist([(x, q) for x in xs])
XY = dist([(x * x * x, q) for x in xs])            # X·Y = X³
Ydist = dist([(x * x, q) for x in xs])
assert E(X) == 0 and E(XY) == 0                    # Cov = 0 − 0·E[Y] = 0
assert E(Ydist) == Fraction(5, 2)
assert Var_short(Ydist) == Fraction(9, 4)
print("zero covariance but dependent (Y = X^2): Cov=0, E[Y]=5/2: OK")

# ⑧ 投资组合：Var = 2(w² + (1−w)²)，谷底 w = 1/2 值 1
vals = {ww: 2 * (ww ** 2 + (1 - ww) ** 2) for ww in
        (Fraction(0), Fraction(1, 4), Fraction(1, 2), Fraction(3, 4), Fraction(1))}
assert vals[Fraction(1, 2)] == 1
assert min(vals.values()) == 1
assert vals[Fraction(0)] == 2 and vals[Fraction(1)] == 2
print("portfolio variance parabola: min 1 at w=1/2, endpoints 2: OK")

# ⑨ 粘硬币：U = 前三枚正面数，V = 后两枚正面数，第 1、4 枚粘连
joint = {}
for c1 in (0, 1):
    for c2 in (0, 1):
        for c3 in (0, 1):
            for c5 in (0, 1):
                c4 = c1                             # 粘连：c4 ≡ c1
                u, v = c1 + c2 + c3, c4 + c5
                joint[(u, v)] = joint.get((u, v), Fraction(0)) + Fraction(1, 16)
assert sum(joint.values()) == 1
margU = {}
margV = {}
for (u, v), pr in joint.items():
    margU[u] = margU.get(u, Fraction(0)) + pr
    margV[v] = margV.get(v, Fraction(0)) + pr
# 边际仍是二项(3,1/2) 与 (2,1/2)
from math import comb
for u in range(4):
    assert margU[u] == Fraction(comb(3, u), 8)
for v in range(3):
    assert margV[v] == Fraction(comb(2, v), 4)
assert joint.get((0, 2), Fraction(0)) == 0          # 破坏格：粘连禁止 U=0 且 V=2
assert margU[0] * margV[2] == Fraction(1, 32)      # 而边际乘积非零
print("glued coins: same marginals, joint(0,2)=0 != 1/32: OK")

# ⑩ Cauchy 均值路径依赖：∫_{−A}^{2A} x/(π(1+x²)) dx → (ln 2)/π
A = 1000
asym = (1 / (2 * pi)) * log((1 + 4 * A * A) / (1 + A * A))
assert abs(asym - log(2) / pi) < 1e-6              # 非零极限：均值不存在
print("Cauchy mean path-dependence: int_-A^2A -> (ln2)/pi != 0: OK")

print("END ====")
