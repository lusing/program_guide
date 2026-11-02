# -*- coding: utf-8 -*-
print("==== 19 covariance")
# 第 19 章 Python：协方差、相关与独立的精确账（Fraction / sympy）。
# ① 协方差代数：Cov(X,Y)=E[XY]-E[X]E[Y]，双线性，Var(X+Y) 展开；
# ② 不相关但不独立：X∈{-1,0,1} 均匀，Y=X²；连续版 X~U(-1,1)；
# ③ Bernoulli 对：不相关 ⇔ 独立（二值变量特例）；
# ④ 协方差矩阵半正定：特征值 / 主子式 / 二次型配方；
# ⑤ 相关系数界 |ρ|≤1 与取等：判别式 / Cauchy–Schwarz；
# ⑥ 投资组合：最小方差权重 w*=(σ₂²-ρσ₁σ₂)/(σ₁²+σ₂²-2ρσ₁σ₂)，ρ=-1 零风险；
# ⑦ 多元 Chebyshev（Mahalanobis）：P((X-μ)ᵀΣ⁻¹(X-μ)≥t)≤d/t；用小分布全枚举精确检验。
from fractions import Fraction as F
from itertools import product
import sympy as sp

def E(pmf, g):
    return sum(p * g(*k) for k, p in pmf.items())

def cov(pmf):
    ex = E(pmf, lambda a, b: a); ey = E(pmf, lambda a, b: b)
    return E(pmf, lambda a, b: a * b) - ex * ey

# ---------------------------------------------------------------- ① 代数恒等式
pmf = {(0, 1): F(1, 8), (1, 0): F(3, 8), (1, 2): F(1, 4), (2, 1): F(1, 4)}
assert sum(pmf.values()) == 1
ex = E(pmf, lambda a, b: a); ey = E(pmf, lambda a, b: b)
c_def = E(pmf, lambda a, b: (a - ex) * (b - ey))
c_short = E(pmf, lambda a, b: a * b) - ex * ey
assert c_def == c_short
vx = E(pmf, lambda a, b: (a - ex) ** 2); vy = E(pmf, lambda a, b: (b - ey) ** 2)
vsum = E(pmf, lambda a, b: (a + b - ex - ey) ** 2)
assert vsum == vx + vy + 2 * c_def
# 双线性：Cov(aX+b, cY+d) = ac Cov(X,Y)
a_, b_, c_, d_ = 3, 5, -2, 7
pmf2 = {(a_ * k[0] + b_, c_ * k[1] + d_): p for k, p in pmf.items()}
assert cov(pmf2) == a_ * c_ * c_def
# 符号版本：n 项和的方差
s1, s2, s3 = sp.symbols("s1 s2 s3", positive=True)
r12, r13, r23 = sp.symbols("r12 r13 r23")
Sig = sp.Matrix([[s1**2, r12*s1*s2, r13*s1*s3],
                 [r12*s1*s2, s2**2, r23*s2*s3],
                 [r13*s1*s3, r23*s2*s3, s3**2]])
w = sp.Matrix(sp.symbols("w1 w2 w3"))
quad = sp.expand((w.T * Sig * w)[0])
expected = sum(w[i]**2 * Sig[i, i] for i in range(3)) \
    + 2 * sum(w[i] * w[j] * Sig[i, j] for i in range(3) for j in range(i + 1, 3))
assert sp.expand(quad - expected) == 0
print("1 covariance algebra: shortcut, Var(X+Y), bilinearity, quadratic form w'Sigma w: OK")

# ---------------------------------------------------------------- ② 不相关但不独立
xy = {(x, x * x): F(1, 3) for x in (-1, 0, 1)}
assert cov(xy) == 0
px = {x: F(1, 3) for x in (-1, 0, 1)}
py = {0: F(1, 3), 1: F(2, 3)}
assert xy[(0, 0)] == F(1, 3) and px[0] * py[0] == F(1, 9)       # 乘积失败
# P(Y=0 | X=0) = 1 但 P(Y=0) = 1/3
assert xy[(0, 0)] / px[0] == 1 and py[0] == F(1, 3)
# 连续版：X~U(-1,1), Y=X²
xs = sp.symbols("x", real=True)
fx = sp.Rational(1, 2)
EX = sp.integrate(xs * fx, (xs, -1, 1)); EXY = sp.integrate(xs**3 * fx, (xs, -1, 1))
assert EX == 0 and EXY == 0                                      # Cov = 0
# 但 P(|X|<1/2, Y>1/2) = 0，而 P(|X|<1/2)P(Y>1/2) = (1/2)(1-1/√2)>0
p_joint = 0     # |X|<1/2 ⇒ Y<1/4
p_prod = sp.Rational(1, 2) * (1 - 1 / sp.sqrt(2))
assert p_prod > 0
# 更强：Y 是 X 的函数，R²=1 对 |X|，线性预测 R²=0
print("2 uncorrelated but dependent: Y=X^2 on {-1,0,1} and U(-1,1): OK")

# ---------------------------------------------------------------- ③ Bernoulli 对
p1, p2, c = sp.symbols("p1 p2 c", positive=True)
# 联合 pmf 由 (p1, p2, Cov=c) 完全决定：P(1,1)=p1p2+c
p11 = p1 * p2 + c
p10 = p1 - p11; p01 = p2 - p11; p00 = 1 - p1 - p2 + p11
assert sp.simplify(p10 - (p1 * (1 - p2) - c)) == 0
assert sp.simplify(p01 - ((1 - p1) * p2 - c)) == 0
assert sp.simplify(p00 - ((1 - p1) * (1 - p2) + c)) == 0
# c=0 ⇒ 四个格都是边际积
for cell, prod_ in ((p11, p1 * p2), (p10, p1 * (1 - p2)), (p01, (1 - p1) * p2),
                    (p00, (1 - p1) * (1 - p2))):
    assert sp.simplify(cell.subs(c, 0) - prod_) == 0
print("3 Bernoulli pair: joint table determined by (p1,p2,Cov); Cov=0 <=> independent: OK")

# ---------------------------------------------------------------- ④ 半正定
S = sp.Matrix([[4, 2], [2, 3]])
assert S.is_positive_definite
ev = S.eigenvals()
assert all(e > 0 for e in ev)
# 二次型配方：s²x²+2ρsτxy+τ²y² = (sx+ρτy)² + (1-ρ²)τ²y²
sg, tg, rho, xx, yy = sp.symbols("sigma tau rho x y", real=True)
Q = sg**2 * xx**2 + 2 * rho * sg * tg * xx * yy + tg**2 * yy**2
assert sp.expand(Q - ((sg * xx + rho * tg * yy)**2 + (1 - rho**2) * tg**2 * yy**2)) == 0
# 奇异协方差：Y=2X+1 ⇒ Σ=[[v,2v],[2v,4v]]，det=0，特征向量 (2,-1) 方向方差为零
vsym = sp.symbols("v", positive=True)
Ssing = sp.Matrix([[vsym, 2 * vsym], [2 * vsym, 4 * vsym]])
assert Ssing.det() == 0
vec = sp.Matrix([2, -1])
assert sp.simplify((vec.T * Ssing * vec)[0]) == 0
# 3×3 相关矩阵半正定的范围：det ≥ 0 ⇔ 1+2r12r13r23-r12²-r13²-r23² ≥ 0
R3 = sp.Matrix([[1, r12, r13], [r12, 1, r23], [r13, r23, 1]])
assert sp.expand(R3.det() - (1 + 2*r12*r13*r23 - r12**2 - r13**2 - r23**2)) == 0
# r12=r23=0.9, r13=-0.9 不是合法相关矩阵
bad = (1 + 2 * F(9, 10) * F(-9, 10) * F(9, 10) - 3 * F(81, 100))
assert bad < 0
print("4 PSD: completing the square, singular case det=0, 3x3 correlation det formula, illegal triple: OK")

# ---------------------------------------------------------------- ⑤ |ρ| ≤ 1
tt = sp.symbols("t", real=True)
va, vb, cab = sp.symbols("va vb cab", real=True)
quad_t = sp.expand(va * tt**2 + 2 * cab * tt + vb)         # E[(tA+B)^2]
disc = sp.discriminant(quad_t, tt)
assert sp.simplify(disc - 4 * (cab**2 - va * vb)) == 0
# 取等：Y = aX + b 的 ρ = sign(a)
pm = {(x, 2 * x + 1): F(1, 4) for x in (0, 1, 2, 3)}
vx_ = E(pm, lambda a, b: a * a) - E(pm, lambda a, b: a) ** 2
vy_ = E(pm, lambda a, b: b * b) - E(pm, lambda a, b: b) ** 2
assert cov(pm) ** 2 == vx_ * vy_ and cov(pm) > 0
pm2 = {(x, -3 * x + 1): F(1, 4) for x in (0, 1, 2, 3)}
vy2 = E(pm2, lambda a, b: b * b) - E(pm2, lambda a, b: b) ** 2
assert cov(pm2) ** 2 == vx_ * vy2 and cov(pm2) < 0
# 相关的不是线性不变量：Y=X³ 与 X 的相关 < 1
p3 = {(x, x**3): F(1, 5) for x in (-2, -1, 0, 1, 2)}
r3 = sp.Rational(cov(p3).numerator, cov(p3).denominator) / sp.sqrt(
    sp.Rational(*(lambda v: (v.numerator, v.denominator))(
        E(p3, lambda a, b: a * a) - E(p3, lambda a, b: a) ** 2))
    * sp.Rational(*(lambda v: (v.numerator, v.denominator))(
        E(p3, lambda a, b: b * b) - E(p3, lambda a, b: b) ** 2)))
assert 0 < r3 < 1
print("5 |rho|<=1: discriminant 4(cov^2-var*var), equality iff affine, rho(X,X^3)<1: OK")

# ---------------------------------------------------------------- ⑥ 投资组合
s_1, s_2 = sp.symbols("s_1 s_2", positive=True)
rr = sp.symbols("rho", real=True)
wq = sp.symbols("w", real=True)
varP = wq**2 * s_1**2 + (1 - wq) ** 2 * s_2**2 + 2 * wq * (1 - wq) * rr * s_1 * s_2
wstar = sp.solve(sp.diff(varP, wq), wq)[0]
assert sp.simplify(wstar - (s_2**2 - rr * s_1 * s_2) / (s_1**2 + s_2**2 - 2 * rr * s_1 * s_2)) == 0
vmin = sp.simplify(varP.subs(wq, wstar))
assert sp.simplify(vmin - s_1**2 * s_2**2 * (1 - rr**2) / (s_1**2 + s_2**2 - 2 * rr * s_1 * s_2)) == 0
# 数值：σ1=0.2, σ2=0.3, ρ=0.5
num = {s_1: sp.Rational(1, 5), s_2: sp.Rational(3, 10), rr: sp.Rational(1, 2)}
w_num = wstar.subs(num); v_num = vmin.subs(num)
assert w_num == sp.Rational(6, 7)                   # (0.09-0.03)/(0.04+0.09-0.06)=0.06/0.07
assert v_num == sp.Rational(27, 700)                # 0.04·0.09·0.75/0.07；小于任一单资产方差 0.04
assert v_num < sp.Rational(4, 100)
# ρ=-1：w*=σ2/(σ1+σ2) 时方差为 0
assert sp.simplify(vmin.subs(rr, -1)) == 0
assert sp.simplify(wstar.subs(rr, -1) - s_2 / (s_1 + s_2)) == 0
# ρ=1：Var = (wσ1+(1-w)σ2)²，分散无益
assert sp.simplify(varP.subs(rr, 1) - (wq * s_1 + (1 - wq) * s_2) ** 2) == 0
# 无相关时 w*=σ2²/(σ1²+σ2²)
assert sp.simplify(wstar.subs(rr, 0) - s_2**2 / (s_1**2 + s_2**2)) == 0
# n 个等相关资产：Var = σ²/n + (1-1/n)ρσ² → ρσ²
nn = sp.symbols("n", positive=True)
sg2 = sp.symbols("sg2", positive=True)
v_eq = nn * (1 / nn) ** 2 * sg2 + nn * (nn - 1) * (1 / nn) ** 2 * rr * sg2
assert sp.simplify(v_eq - (sg2 / nn + (1 - 1 / nn) * rr * sg2)) == 0
assert sp.limit(v_eq, nn, sp.oo) == rr * sg2
print("6 portfolio: w*, minimum variance, rho=-1 hedge, rho=1 no gain, equicorrelated limit rho*sigma^2: OK")

# ---------------------------------------------------------------- ⑦ 多元 Chebyshev
# X=(X1,X2) 取 6 点，Σ 可逆；Mahalanobis 平方 D²；Markov 作用于 D²：P(D²≥t) ≤ E[D²]/t = d/t
pts = {(1, 0): F(1, 6), (-1, 0): F(1, 6), (0, 1): F(1, 6), (0, -1): F(1, 6),
       (2, 2): F(1, 6), (-2, -2): F(1, 6)}
assert sum(pts.values()) == 1
m1 = E(pts, lambda a, b: a); m2 = E(pts, lambda a, b: b)
assert m1 == 0 and m2 == 0
s11 = E(pts, lambda a, b: a * a); s22 = E(pts, lambda a, b: b * b)
s12 = E(pts, lambda a, b: a * b)
Sg = sp.Matrix([[sp.Rational(s11.numerator, s11.denominator), sp.Rational(s12.numerator, s12.denominator)],
                [sp.Rational(s12.numerator, s12.denominator), sp.Rational(s22.numerator, s22.denominator)]])
Sinv = Sg.inv()
def D2(a, b):
    v = sp.Matrix([a, b])
    return (v.T * Sinv * v)[0]
ED2 = sum(sp.Rational(p.numerator, p.denominator) * D2(*k) for k, p in pts.items())
assert ED2 == 2                                       # E[D²] = tr(Σ⁻¹Σ) = d
for t in (sp.Rational(1), sp.Rational(2), sp.Rational(4), sp.Rational(6)):
    tail = sum(sp.Rational(p.numerator, p.denominator) for k, p in pts.items() if D2(*k) >= t)
    assert tail <= ED2 / t
print("7 multivariate Chebyshev: E[D^2]=d=2, tails P(D^2>=t) <= d/t on a 6-point law: OK")

# ---------------------------------------------------------------- ⑧ 超几何：指示变量协方差
Nn, Kk, nn_ = sp.symbols("N K n", positive=True)
pp = Kk / Nn
cov_ij = Kk * (Kk - 1) / (Nn * (Nn - 1)) - pp**2
assert sp.simplify(cov_ij + pp * (1 - pp) / (Nn - 1)) == 0
var_h = nn_ * pp * (1 - pp) + nn_ * (nn_ - 1) * cov_ij
assert sp.simplify(var_h - nn_ * pp * (1 - pp) * (Nn - nn_) / (Nn - 1)) == 0
# 全枚举核对：N=7, K=3, n=4
from math import comb
Nv, Kv, nv = 7, 3, 4
pmf_h = {k: F(comb(Kv, k) * comb(Nv - Kv, nv - k), comb(Nv, nv)) for k in range(0, min(Kv, nv) + 1)
         if nv - k <= Nv - Kv}
assert sum(pmf_h.values()) == 1
mean_h = sum(k * p for k, p in pmf_h.items())
var_enum = sum(k * k * p for k, p in pmf_h.items()) - mean_h**2
pv = F(Kv, Nv)
assert var_enum == nv * pv * (1 - pv) * F(Nv - nv, Nv - 1)
print("8 hypergeometric: Cov(I_i,I_j) = -pq/(N-1), Var = npq(N-n)/(N-1), enumerated at N=7: OK")

print("END ====")
