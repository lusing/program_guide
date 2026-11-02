# -*- coding: utf-8 -*-
print("==== 16 convolutions")
# 第 16 章 Python：卷积与变量替换的精确分数账。
# ① 两骰卷积分段公式 vs 36 格枚举；② 四骰 grouping 卷积
#    （Fraction 精确）vs 1296 全枚举；③ 连续均匀自卷积的
#    三角形密度（分段多项式精确 + Simpson 归一）；④ 换元例
#    全账：E[Y] = 4/3 双路会师；⑤ 指数商 1/(1+z)² 的解析账。
from fractions import Fraction
from itertools import product


def convolve_discrete(f, g, z):
    """离散卷积 (f*g)(z) = Σ f(t)g(z−t)（dict 型 pmf）。"""
    return sum(p * g.get(z - t, Fraction(0)) for t, p in f.items())


# ① 两骰：三角形公式 vs 枚举
die = {k: Fraction(1, 6) for k in range(1, 7)}
f2 = {z: convolve_discrete(die, die, z) for z in range(2, 13)}
enum2 = {}
for a, b in product(range(1, 7), repeat=2):
    enum2[a + b] = enum2.get(a + b, Fraction(0)) + Fraction(1, 36)
assert f2 == enum2
assert sum(f2.values()) == 1
assert f2[8] == Fraction(5, 36)
print("two-dice convolution = 36-cell enumeration: OK")

# ② 四骰 grouping：f4 = f2 * f2（Fraction 精确）vs 1296 枚举
f4 = {z: convolve_discrete(f2, f2, z) for z in range(4, 25)}
assert sum(f4.values()) == 1
assert f4[6] == Fraction(10, 1296)
enum4 = {}
for r in product(range(1, 7), repeat=4):
    s = sum(r)
    enum4[s] = enum4.get(s, Fraction(0)) + Fraction(1, 1296)
assert f4 == enum4
# 对称检查：f4(z) = f4(28−z)
assert all(f4[z] == f4[28 - z] for z in range(4, 25))
print("four-dice grouping f2*f2 = 1296-cell enumeration, f4(6)=10/1296: OK")

# ③ 连续：U[−1/2,1/2] 自卷积的三角形密度 (f*f)(z) = 1 − |z|（|z| ≤ 1）
#    精确片段积分验证归一与区间概率


def tri_cdf(z):  # ∫_{−1}^{z} (1−|u|) du
    if z <= -1:
        return Fraction(0)
    if z < 0:
        return Fraction(1, 2) + z + z * z / 2    # (z+1)^2 / 2
    if z <= 1:
        return Fraction(1, 2) + z - z * z / 2
    return Fraction(1)


assert tri_cdf(1) == 1
assert tri_cdf(0) == Fraction(1, 2)
assert tri_cdf(Fraction(1, 2)) - tri_cdf(Fraction(1, 4)) == Fraction(5, 32)
print("triangle density piecewise CDF: normalized, P[1/4,1/2]=5/32: OK")


# Simpson 数值复核三角形归一
def simpson(f, a, b, n):
    h = (b - a) / n
    s = f(a) + f(b)
    for i in range(1, n):
        s += (4 if i % 2 else 2) * f(a + i * h)
    return s * h / 3


tri = lambda z: 1 - abs(z) if abs(z) <= 1 else 0.0
assert abs(simpson(tri, -1, 1, 2000) - 1) < 1e-9
print("triangle density Simpson integral = 1: OK")

# ④ 换元例：X ~ U[0,2]，Y = X²。fY(y) = 1/(4√y)，E[Y] = 4/3 双路
#    （换元空间 ∫ y·(1/4)y^{-1/2} dy vs 原空间 E[X²]）
fY_mean = simpson(lambda y: y * 0.25 * y ** -0.5 if y > 0 else 0.0,
                  1e-9, 4.0, 4000)
assert abs(fY_mean - 4 / 3) < 1e-4
assert Fraction(1, 2) * Fraction(8, 3) == Fraction(4, 3)   # ∫₀² x²/2 dx
print("Y=X^2: E[Y]=4/3 via transformed density AND via E[X^2]: OK")

# ⑤ 指数商：fZ(z) = 1/(1+z)²（z ≥ 0）解析账
#    有限区间 Simpson 对拍闭式 1 − 1/(1+A)；A → ∞ 归一 = 1；
#    P(Z ≤ 1) = 1/2（中位数 = 1）
A = 1000
assert abs(simpson(lambda z: 1 / (1 + z) ** 2, 0, A, 40000)
           - (1 - 1 / (1 + A))) < 1e-6
assert abs(simpson(lambda z: 1 / (1 + z) ** 2, 0, 1, 2000) - 0.5) < 1e-9
print("exponential ratio 1/(1+z)^2: closed form 1-1/(1+A), P(Z<=1)=1/2: OK")

# ---- 以下为微分恒等式与矩账（原 16_moments.py 并入）----
from math import comb, exp, factorial, pi, sqrt

# ⑥ 几何微分链（Σxⁿ → Σnxⁿ → Σn²xⁿ）Fraction 精确验证；
# ⑦ 组合收获的枚举审判（Σk·C(n,k) 与 Σk²·C(n,k)）；
# ⑧ 二项矩账（np / np+n(n−1)p² / np(1−p) vs 直接求和）；
# ⑨ 正态偶矩递推链的数值积分 vs (2k−1)!!；
# ⑩ 指数矩链 E[Xᵏ] = k!·λᵏ 的数值积分验证。
from fractions import Fraction
from math import comb, exp, pi, sqrt


def simpson(f, a, b, n):
    h = (b - a) / n
    s = f(a) + f(b)
    for i in range(1, n):
        s += (4 if i % 2 else 2) * f(a + i * h)
    return s * h / 3


# ⑥ 几何微分链：x = 1/2 与 1/3 双点（截断至 n = 60，误差 < 1e-15）
for x in (Fraction(1, 2), Fraction(1, 3)):
    N = 60
    s0 = sum(x ** n for n in range(N))
    s1 = sum(n * x ** n for n in range(1, N))
    s2 = sum(n * n * x ** n for n in range(1, N))
    xf = float(x)
    assert abs(float(s0) - 1 / (1 - xf)) < 1e-14
    assert abs(float(s1) - xf / (1 - xf) ** 2) < 1e-14
    assert abs(float(s2) - xf * (1 + xf) / (1 - xf) ** 3) < 1e-14
assert sum(Fraction(n, 2 ** n) for n in range(1, 11)) == Fraction(509, 256)
assert Fraction(2) - Fraction(509, 256) == Fraction(3, 256)
print("geometric chain exact at x=1/2,1/3; tail N=10 = 3/256: OK")

# ⑦ 组合收获：Σk·C(n,k) = n·2^{n−1}、Σk²·C(n,k) = n(n+1)·2^{n−2}
n = 8
assert sum(k * comb(n, k) for k in range(n + 1)) == n * 2 ** (n - 1)
assert sum(k * k * comb(n, k) for k in range(n + 1)) == n * (n + 1) * 2 ** (n - 2)
print("binomial harvest sums for n=8: k*C=8*2^7, k^2*C=8*9*2^6: OK")

# ⑧ 二项矩账：n = 5、p = 1/3（Fraction 全程精确）
n, p = 5, Fraction(1, 3)
q = 1 - p
pmf = {k: Fraction(comb(n, k)) * p ** k * q ** (n - k) for k in range(n + 1)}
E1 = sum(k * pmf[k] for k in range(n + 1))
E2 = sum(k * k * pmf[k] for k in range(n + 1))
assert E1 == Fraction(5, 3) == n * p
assert E2 == Fraction(35, 9) == n * p + n * (n - 1) * p * p
assert E2 - E1 * E1 == Fraction(10, 9) == n * p * (1 - p)
print("binomial moments n=5,p=1/3: E=5/3, E2=35/9, Var=10/9: OK")

# ⑨ 正态偶矩：递推 M(2k+2) = (2k+1)·M(2k) 的数值积分链 vs (2k−1)!!
phi = lambda t: exp(-t * t / 2) / sqrt(2 * pi)
M = 1.0                     # M(0) = 1
for k in range(1, 7):       # M(2), M(4), ..., M(12)
    M_num = simpson(lambda t: t ** (2 * k) * phi(t), -12, 12, 4000)
    M *= (2 * k - 1)        # 双阶乘递推
    assert abs(M_num - M) < 1e-5 * M
print("normal even moments up to 11!! via Simpson vs recurrence: OK")

# ⑩ 指数矩链：E[X^k] = k!·λᵏ（λ = 2，k 到 5；∫x^k e^{-x/λ}/λ dx）
from math import factorial
lam = 2.0
for k in range(1, 6):
    m = simpson(lambda t: t ** k * exp(-t / lam) / lam, 0, 80, 4000)
    assert abs(m - factorial(k) * lam ** k) < 1e-4 * factorial(k) * lam ** k
print("exponential moments k!*lambda^k via Simpson (lambda=2): OK")

print("END ====")
