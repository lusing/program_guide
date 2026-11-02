# -*- coding: utf-8 -*-
print("==== 17 joint distributions")
# 第 17 章 Python：联合、边际与条件分布的精确账。
# ① 3×3 联合表：边际、条件、归一化、独立判定（Fraction）；
# ② 单位圆盘上的二维均匀：边际 (2/π)√(1−x²) 归一，且 f ≠ f_X f_Y；
# ③ 三角支撑 f = e^{−y}（0<x<y）：边际、条件、无记忆性、因子分解为何失败；
# ④ 独立指数：P(X<Y) = λ/(λ+μ)，联合 CDF 的矩形公式；
# ⑤ 混合型：Z∈{0,1}，Y|Z 指数 → 后验概率与全概率密度；
# ⑥ 多项分布 n=4：边际二项、条件二项（全枚举，Fraction）。
from fractions import Fraction as F
from itertools import product
from math import comb, factorial
import sympy as sp

# ---------------------------------------------------------------- ① 联合表
# 行 X∈{0,1,2}，列 Y∈{0,1,2}；总和 1。
table = {
    (0, 0): F(1, 12), (0, 1): F(1, 12), (0, 2): F(1, 6),
    (1, 0): F(1, 12), (1, 1): F(1, 6), (1, 2): F(1, 12),
    (2, 0): F(1, 6), (2, 1): F(1, 12), (2, 2): F(1, 12),
}
assert sum(table.values()) == 1
pX = {x: sum(table[x, y] for y in range(3)) for x in range(3)}
pY = {y: sum(table[x, y] for x in range(3)) for y in range(3)}
assert pX == {0: F(1, 3), 1: F(1, 3), 2: F(1, 3)}
assert pY == {0: F(1, 3), 1: F(1, 3), 2: F(1, 3)}
# 条件 pmf 必须归一
for x in range(3):
    cond = {y: table[x, y] / pX[x] for y in range(3)}
    assert sum(cond.values()) == 1
assert table[0, 2] / pX[0] == F(1, 2)       # P(Y=2 | X=0)
# 边际均匀但不独立
assert any(table[x, y] != pX[x] * pY[y] for x, y in table)
# 乘积表一定独立
prod_table = {(x, y): pX[x] * pY[y] for x, y in table}
assert sum(prod_table.values()) == 1
# 矩形公式：P(0<X≤1, 0<Y≤2) = F(1,2) − F(0,2) − F(1,0) + F(0,0)
def cdf(a, b):
    return sum(p for (x, y), p in table.items() if x <= a and y <= b)
rect = cdf(1, 2) - cdf(0, 2) - cdf(1, 0) + cdf(0, 0)
assert rect == sum(table[1, y] for y in (1, 2))
print("[1] joint table: marginals uniform, conditionals normalise, not independent: OK")

# ---------------------------------------------------------------- ② 圆盘均匀
x, y, t = sp.symbols("x y t", real=True)
r = sp.symbols("r", positive=True)
fXY = 1 / sp.pi                                  # 单位圆盘密度
fX = sp.integrate(fXY, (y, -sp.sqrt(1 - x**2), sp.sqrt(1 - x**2)))
assert sp.simplify(fX - 2 * sp.sqrt(1 - x**2) / sp.pi) == 0
assert sp.simplify(sp.integrate(fX, (x, -1, 1)) - 1) == 0
# 在 (0.9, 0.9) 处联合密度为 0（圆盘外），而 f_X f_Y > 0 ⇒ 不独立
assert sp.simplify(fX.subs(x, F(1, 2)) ** 2) != 0
# 条件分布：Y | X=x 均匀于 (−√(1−x²), √(1−x²))，长度 2√(1−x²)
fcond = fXY / fX
assert sp.simplify(fcond - 1 / (2 * sp.sqrt(1 - x**2))) == 0
# 对比：单位正方形上的均匀是独立的 f=1·1
print("[2] unit disk: f_X = (2/pi)sqrt(1-x^2) normalised, conditional uniform, not product: OK")

# ---------------------------------------------------------------- ③ 三角支撑
a, b = sp.symbols("a b", positive=True)
fxy = sp.exp(-y)                                  # 0 < x < y
fXm = sp.integrate(fxy, (y, x, sp.oo))            # = e^{-x}
fYm = sp.integrate(fxy, (x, 0, y))                # = y e^{-y}
assert sp.simplify(fXm - sp.exp(-x)) == 0
assert sp.simplify(fYm - y * sp.exp(-y)) == 0
# 条件密度
fY_given_X = sp.simplify(fxy / fXm)               # e^{-(y-x)}, y>x
fX_given_Y = sp.simplify(fxy / fYm)               # 1/y, 0<x<y
assert sp.simplify(fY_given_X - sp.exp(-(y - x))) == 0
assert sp.simplify(fX_given_Y - 1 / y) == 0
# 归一化
assert sp.simplify(sp.integrate(fY_given_X, (y, x, sp.oo)) - 1) == 0
assert sp.simplify(sp.integrate(fX_given_Y, (x, 0, y)) - 1) == 0
# 无记忆：P(Y−x > s | X=x) = e^{-s}
s = sp.symbols("s", positive=True)
tail = sp.integrate(fY_given_X.subs(y, x + t), (t, s, sp.oo))
assert sp.simplify(tail - sp.exp(-s)) == 0
# 乘积 f_X f_Y 在 (x,y)=(2,1) 处不为零，而联合为零 ⇒ 不是乘积形式
assert (fXm * fYm).subs({x: 2, y: 1}) != 0
# E[Y] 两条路：边际 ∫ y·y e^{-y} = 2；全期望 E[X]+E[Y−X] = 1+1
assert sp.integrate(y * fYm, (y, 0, sp.oo)) == 2
print("[3] triangular support: marginals e^{-x}, y e^{-y}; conditional memoryless: OK")

# ---------------------------------------------------------------- ④ 独立指数
lam, mu = sp.symbols("lambda mu", positive=True)
f_ind = lam * mu * sp.exp(-lam * x - mu * y)
p_less = sp.integrate(sp.integrate(f_ind, (y, x, sp.oo)), (x, 0, sp.oo))
assert sp.simplify(p_less - lam / (lam + mu)) == 0
# 联合 CDF F(x,y) = (1−e^{-λx})(1−e^{-μy})：矩形公式
Fxy = (1 - sp.exp(-lam * x)) * (1 - sp.exp(-mu * y))
a1, b1, c1, d1 = sp.symbols("a1 b1 c1 d1", positive=True)
rect_formula = (Fxy.subs({x: b1, y: d1}) - Fxy.subs({x: a1, y: d1})
                - Fxy.subs({x: b1, y: c1}) + Fxy.subs({x: a1, y: c1}))
rect_int = sp.integrate(sp.integrate(f_ind, (x, a1, b1)), (y, c1, d1))
assert sp.simplify(rect_formula - rect_int) == 0
print("[4] independent exponentials: P(X<Y)=lam/(lam+mu), rectangle formula: OK")

# ---------------------------------------------------------------- ⑤ 混合型
# Z~Bernoulli(1/3)；Z=0: Y~Exp(1)，Z=1: Y~Exp(3)（速率）
pz1 = sp.Rational(1, 3)
f0 = sp.exp(-y)
f1 = 3 * sp.exp(-3 * y)
fY = (1 - pz1) * f0 + pz1 * f1
assert sp.simplify(sp.integrate(fY, (y, 0, sp.oo)) - 1) == 0
post1 = sp.simplify(pz1 * f1 / fY)                # P(Z=1 | Y=y)
assert sp.simplify(post1 - sp.exp(-3 * y) / (2 * sp.exp(-y) / 3 + sp.exp(-3 * y))) == 0
# 后验概率在 y→0 为 1/3·3/(2/3+1)=3/5，在 y→∞ 趋于 0
assert sp.limit(post1, y, 0) == sp.Rational(3, 5)
assert sp.limit(post1, y, sp.oo) == 0
# 混合边际：P(Z=1) = ∫ P(Z=1|y) f_Y(y) dy = 1/3
assert sp.simplify(sp.integrate(post1 * fY, (y, 0, sp.oo)) - pz1) == 0
print("[5] mixed (Z discrete, Y|Z continuous): posterior 3/5 at y=0, law of total prob: OK")

# ---------------------------------------------------------------- ⑥ 多项分布
n = 4
probs = (F(1, 2), F(1, 3), F(1, 6))               # p1, p2, p3
def multinom(k):
    k1, k2, k3 = k
    return F(factorial(n), factorial(k1) * factorial(k2) * factorial(k3)) \
        * probs[0]**k1 * probs[1]**k2 * probs[2]**k3
cells = [(k1, k2, n - k1 - k2) for k1 in range(n + 1) for k2 in range(n + 1 - k1)]
assert sum(multinom(k) for k in cells) == 1
# 边际：N1 ~ Bin(4, 1/2)
for k1 in range(n + 1):
    marg = sum(multinom(k) for k in cells if k[0] == k1)
    assert marg == comb(n, k1) * probs[0]**k1 * (1 - probs[0])**(n - k1)
# 条件：N1 | N2=k2 ~ Bin(n−k2, p1/(1−p2))
for k2 in range(n + 1):
    pk2 = sum(multinom(k) for k in cells if k[1] == k2)
    q = probs[0] / (1 - probs[1])
    for k1 in range(n - k2 + 1):
        cond = multinom((k1, k2, n - k1 - k2)) / pk2
        assert cond == comb(n - k2, k1) * q**k1 * (1 - q)**(n - k2 - k1)
# 非独立：P(N1=4,N2=4) = 0 但边际积 > 0
assert multinom((4, 0, 0)) != 0
assert sum(multinom(k) for k in cells if k[0] == 4) \
    * sum(multinom(k) for k in cells if k[1] == 4) > 0
assert not any(k[0] == 4 and k[1] == 4 for k in cells)
print("[6] multinomial n=4: binomial marginals, binomial conditionals, dependent: OK")

# ---------------------------------------------------------------- ⑦ 零测集条件化依赖刻画
# X,Y 独立 Exp(1)。以 V=Y-X=0 与 W=Y/X=1 两种方式“条件化在 {Y=X}”，得到不同的 X 条件分布。
xp = sp.symbols("x", positive=True)
wv = sp.symbols("w", positive=True)
f_xv = sp.exp(-2 * xp - 0)                      # (X,V) 联合密度在 v=0 处：e^{-2x-v}
cond_v = sp.simplify(f_xv / sp.integrate(f_xv, (xp, 0, sp.oo)))
assert sp.simplify(cond_v - 2 * sp.exp(-2 * xp)) == 0         # Exp(2)
f_xw = xp * sp.exp(-xp * (1 + wv))              # (X,W) 联合密度，Jacobian = x
f_at1 = f_xw.subs(wv, 1)
cond_w = sp.simplify(f_at1 / sp.integrate(f_at1, (xp, 0, sp.oo)))
assert sp.simplify(cond_w - 4 * xp * sp.exp(-2 * xp)) == 0    # Gamma(2, 速率 2)
assert sp.simplify(cond_v - cond_w) != 0
print("7 conditioning on a null event depends on the limiting family: Exp(2) vs Gamma(2,2): OK")

print("END ====")
