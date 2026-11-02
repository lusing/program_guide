# -*- coding: utf-8 -*-
print("==== 18 multivariate transformations")
# 第 18 章 Python：Jacobian 的符号账与精确验证（sympy / Fraction）。
# ① 线性变换：|det A|；极坐标 r；球坐标 r^2 sin(phi)；
# ② 和 / 积 / 商：辅助变量 + Jacobian，逐个核对；指数商 λμ/(μ+λz)^2；正态商 = Cauchy；
# ③ Gamma-Beta：U=X+Y, V=X/(X+Y) 独立，f = Gamma(a+b) × Beta(a,b)；
# ④ 多对一：U=X^2（X 标准正态）分区求和 → 卡方(1)；
# ⑤ 次序统计量：密度 n!/((k-1)!(n-k)!) F^{k-1}(1-F)^{n-k} f，联合 (min,max)，指数间隔；
# ⑥ Box-Muller：逆映射的 Jacobian 恰好给出二维标准正态密度；
# ⑦ 两骰 (min,max) 的离散分区求和（Fraction）。
from fractions import Fraction as F
from itertools import product
import sympy as sp

# ---------------------------------------------------------------- ① 基本 Jacobian
x, y, z, u, v, r, th, ph = sp.symbols("x y z u v r theta phi", real=True)
A = sp.Matrix([[2, 1], [1, 3]])
assert A.det() == 5                               # 单位正方形 → 面积 5 的平行四边形
J_polar = sp.Matrix([r * sp.cos(th), r * sp.sin(th)]).jacobian([r, th])
assert sp.simplify(J_polar.det() - r) == 0
J_sph = sp.Matrix([r * sp.sin(ph) * sp.cos(th),
                   r * sp.sin(ph) * sp.sin(th),
                   r * sp.cos(ph)]).jacobian([r, ph, th])
assert sp.simplify(J_sph.det() - r**2 * sp.sin(ph)) == 0     # 列序 (r,phi,theta) 时 det = r^2 sin(phi) ≥ 0
# 单位球体积 = ∫ r^2 sin(phi) = 4π/3
vol = sp.integrate(r**2 * sp.sin(ph), (r, 0, 1), (ph, 0, sp.pi), (th, 0, 2 * sp.pi))
assert sp.simplify(vol - 4 * sp.pi / 3) == 0
# 高斯积分：∬ e^{-(x²+y²)/2} dxdy = 2π（极坐标）→ ∫ e^{-x²/2} = √(2π)
gauss2 = sp.integrate(sp.exp(-r**2 / 2) * r, (r, 0, sp.oo)) * 2 * sp.pi
assert sp.simplify(gauss2 - 2 * sp.pi) == 0
print("1 Jacobians: det A=5, polar r, spherical r^2 sin(phi), ball volume 4pi/3, Gaussian 2pi: OK")

# ---------------------------------------------------------------- ② 和 积 商
# 和：(u,v)=(x+y, x) ⇒ x=v, y=u−v，Jacobian ∂(x,y)/∂(u,v)
Jsum = sp.Matrix([v, u - v]).jacobian([u, v])
assert abs(Jsum.det()) == 1
# 积：(u,v)=(xy, x) ⇒ x=v, y=u/v
Jprod = sp.Matrix([v, u / v]).jacobian([u, v])
assert sp.simplify(Jprod.det() + 1 / v) == 0      # det = −1/v，|det| = 1/|v|
# 商：(u,v)=(x/y, y) ⇒ x=uv, y=v
Jquo = sp.Matrix([u * v, v]).jacobian([u, v])
assert sp.simplify(Jquo.det() - v) == 0

lam, mu = sp.symbols("lambda mu", positive=True)
zz = sp.symbols("z", positive=True)
vv = sp.symbols("v", positive=True)
# 指数商 Z = X/Y：f_Z(z) = ∫ v f_X(zv) f_Y(v) dv
fz = sp.integrate(vv * lam * sp.exp(-lam * zz * vv) * mu * sp.exp(-mu * vv), (vv, 0, sp.oo))
assert sp.simplify(fz - lam * mu / (mu + lam * zz) ** 2) == 0
assert sp.simplify(sp.integrate(lam * mu / (mu + lam * zz) ** 2, (zz, 0, sp.oo)) - 1) == 0
# 与 CDF 路径对账：P(X<=zY) = λz/(μ+λz)，求导
assert sp.simplify(sp.diff(lam * zz / (mu + lam * zz), zz) - lam * mu / (mu + lam * zz) ** 2) == 0
# 标准正态商 = Cauchy：f(z) = ∫ |v| φ(zv) φ(v) dv = 2∫_0^∞ v/(2π) e^{-(1+z²)v²/2} dv
zr = sp.symbols("z", real=True)
fc = 2 * sp.integrate(vv / (2 * sp.pi) * sp.exp(-(1 + zr**2) * vv**2 / 2), (vv, 0, sp.oo))
assert sp.simplify(fc - 1 / (sp.pi * (1 + zr**2))) == 0
# 积：Z = XY（独立 U(0,1)）：f(z) = ∫_z^1 (1/v) dv = −ln z
t = sp.symbols("t", positive=True)
fprod = sp.integrate(1 / t, (t, zz, 1))
assert sp.simplify(fprod + sp.log(zz)) == 0
assert sp.integrate(-sp.log(zz), (zz, 0, 1)) == 1
print("2 sum/product/quotient: Jacobians 1, 1/|v|, |v|; Exp quotient and Cauchy and -ln z: OK")

# ---------------------------------------------------------------- ③ Gamma–Beta
a, b = sp.symbols("a b", positive=True)
uu, v01 = sp.symbols("u v", positive=True)
xx = uu * v01
yy = uu * (1 - v01)
Jgb = sp.Matrix([xx, yy]).jacobian([uu, v01])
assert sp.simplify(Jgb.det() + uu) == 0           # |det| = u
fxy = xx ** (a - 1) * sp.exp(-xx) * yy ** (b - 1) * sp.exp(-yy) / (sp.gamma(a) * sp.gamma(b))
fuv = fxy * uu
target = (uu ** (a + b - 1) * sp.exp(-uu) / sp.gamma(a + b)) \
    * (v01 ** (a - 1) * (1 - v01) ** (b - 1) * sp.gamma(a + b) / (sp.gamma(a) * sp.gamma(b)))
ratio = sp.simplify(sp.powsimp(sp.expand_power_base(fuv / target, force=True), force=True))
assert ratio == 1
print("3 Gamma-Beta: f_{U,V} = Gamma(a+b)(u) x Beta(a,b)(v), independent: OK")

# ---------------------------------------------------------------- ④ 多对一：U = X²
uq = sp.symbols("u", positive=True)
phi = lambda s: sp.exp(-s**2 / 2) / sp.sqrt(2 * sp.pi)
# 两个原像 x = ±√u，每个贡献 φ(±√u)/(2√u)
fU = sp.simplify(2 * phi(sp.sqrt(uq)) / (2 * sp.sqrt(uq)))
assert sp.simplify(fU - uq ** sp.Rational(-1, 2) * sp.exp(-uq / 2) / sp.sqrt(2 * sp.pi)) == 0
assert sp.simplify(sp.integrate(fU, (uq, 0, sp.oo)) - 1) == 0
# 对照：只取一个原像会得到总质量 1/2
assert sp.simplify(sp.integrate(fU / 2, (uq, 0, sp.oo)) - sp.Rational(1, 2)) == 0
# (U,V) = (X², Y)，Y 独立：边际仍是 fU
print("4 many-to-one: X^2 two-branch sum = chi-square(1), one branch gives mass 1/2: OK")

# ---------------------------------------------------------------- ⑤ 次序统计量
from math import factorial, comb
n = 5
xs = sp.symbols("x", positive=True)
for k in range(1, n + 1):
    Fk = sum(comb(n, j) * xs**j * (1 - xs) ** (n - j) for j in range(k, n + 1))
    fk = sp.diff(Fk, xs)
    formula = sp.Rational(factorial(n), factorial(k - 1) * factorial(n - k)) \
        * xs ** (k - 1) * (1 - xs) ** (n - k)
    assert sp.simplify(fk - formula) == 0
    # Beta(k, n−k+1) 均值 k/(n+1)
    assert sp.integrate(xs * formula, (xs, 0, 1)) == sp.Rational(k, n + 1)
# 联合 (min,max)：F(a,b) = b^n − (b−a)^n ⇒ f = n(n−1)(b−a)^{n−2}
aa, bb = sp.symbols("aa bb", positive=True)
Fmm = bb**n - (bb - aa) ** n
assert sp.simplify(sp.diff(Fmm, aa, bb) - n * (n - 1) * (bb - aa) ** (n - 2)) == 0
# 指数：min of n Exp(1) ~ Exp(n)，间隔 X_(k+1)−X_(k) ~ Exp(n−k)（用生存函数核对 min）
assert sp.simplify(sp.diff(1 - sp.exp(-n * zz), zz) - n * sp.exp(-n * zz)) == 0
print("5 order statistics: Beta(k,n-k+1) densities, joint (min,max), Exp min ~ Exp(n): OK")

# ---------------------------------------------------------------- ⑥ Box–Muller
xb, yb = sp.symbols("xb yb", real=True)
# 逆映射 u = exp(−(x²+y²)/2)，v = atan2(y,x)/(2π) 的 Jacobian
ub = sp.exp(-(xb**2 + yb**2) / 2)
vb = sp.atan(yb / xb) / (2 * sp.pi)
Jbm = sp.Matrix([ub, vb]).jacobian([xb, yb])
dens = sp.simplify(Jbm.det())      # (U,V) 均匀密度为 1，故 (X,Y) 密度 = |det|
assert sp.simplify(dens ** 2 - (sp.exp(-(xb**2 + yb**2) / 2) / (2 * sp.pi)) ** 2) == 0
# 正向映射：x = sqrt(−2 ln u) cos(2π v) 的 Jacobian 之模 = 2π/u（再取倒数即上式）
ub_, vb_ = sp.symbols("ub vb", positive=True)
Jf = sp.Matrix([sp.sqrt(-2 * sp.log(ub_)) * sp.cos(2 * sp.pi * vb_),
                sp.sqrt(-2 * sp.log(ub_)) * sp.sin(2 * sp.pi * vb_)]).jacobian([ub_, vb_])
assert sp.simplify(Jf.det() ** 2 - (2 * sp.pi / ub_) ** 2) == 0
print("6 Box-Muller: |d(x,y)/d(u,v)| = 2pi/u, density e^{-(x^2+y^2)/2}/(2pi): OK")

# ---------------------------------------------------------------- ⑦ 离散 (min, max)
pmf = {}
for p, q in product(range(1, 7), repeat=2):
    key = (min(p, q), max(p, q))
    pmf[key] = pmf.get(key, F(0)) + F(1, 36)
assert sum(pmf.values()) == 1
for (lo, hi), pr in pmf.items():
    assert pr == (F(1, 36) if lo == hi else F(2, 36))      # 两个原像各贡献 1/36
# 边际：P(min=k) = (13−2k)/36
for k in range(1, 7):
    assert sum(pr for (lo, hi), pr in pmf.items() if lo == k) == F(13 - 2 * k, 36)
# 线性变换 (X+Y, X−Y)：一一对应，质量不变
lin = {}
for p, q in product(range(1, 7), repeat=2):
    lin[(p + q, p - q)] = lin.get((p + q, p - q), F(0)) + F(1, 36)
assert len(lin) == 36 and all(pr == F(1, 36) for pr in lin.values())
print("7 discrete (min,max): off-diagonal 2/36, diagonal 1/36; linear map one-to-one: OK")

print("END ====")
