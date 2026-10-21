# -*- coding: utf-8 -*-
print("==== 12 differentiating")
# 第 12 章 Python：微分恒等式的精确分数账。
# ① 几何微分链（Σxⁿ → Σnxⁿ → Σn²xⁿ）Fraction 精确验证；
# ② 组合收获的枚举审判（Σk·C(n,k) 与 Σk²·C(n,k)）；
# ③ 二项矩账（np / np+n(n−1)p² / np(1−p) vs 直接求和）；
# ④ 正态偶矩递推链的数值积分 vs (2k−1)!!；
# ⑤ 指数矩链 E[Xᵏ] = k!·λᵏ 的数值积分验证。
from fractions import Fraction
from math import comb, exp, pi, sqrt


def simpson(f, a, b, n):
    h = (b - a) / n
    s = f(a) + f(b)
    for i in range(1, n):
        s += (4 if i % 2 else 2) * f(a + i * h)
    return s * h / 3


# ① 几何微分链：x = 1/2 与 1/3 双点（截断至 n = 60，误差 < 1e-15）
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

# ② 组合收获：Σk·C(n,k) = n·2^{n−1}、Σk²·C(n,k) = n(n+1)·2^{n−2}
n = 8
assert sum(k * comb(n, k) for k in range(n + 1)) == n * 2 ** (n - 1)
assert sum(k * k * comb(n, k) for k in range(n + 1)) == n * (n + 1) * 2 ** (n - 2)
print("binomial harvest sums for n=8: k*C=8*2^7, k^2*C=8*9*2^6: OK")

# ③ 二项矩账：n = 5、p = 1/3（Fraction 全程精确）
n, p = 5, Fraction(1, 3)
q = 1 - p
pmf = {k: Fraction(comb(n, k)) * p ** k * q ** (n - k) for k in range(n + 1)}
E1 = sum(k * pmf[k] for k in range(n + 1))
E2 = sum(k * k * pmf[k] for k in range(n + 1))
assert E1 == Fraction(5, 3) == n * p
assert E2 == Fraction(35, 9) == n * p + n * (n - 1) * p * p
assert E2 - E1 * E1 == Fraction(10, 9) == n * p * (1 - p)
print("binomial moments n=5,p=1/3: E=5/3, E2=35/9, Var=10/9: OK")

# ④ 正态偶矩：递推 M(2k+2) = (2k+1)·M(2k) 的数值积分链 vs (2k−1)!!
phi = lambda t: exp(-t * t / 2) / sqrt(2 * pi)
M = 1.0                     # M(0) = 1
for k in range(1, 7):       # M(2), M(4), ..., M(12)
    M_num = simpson(lambda t: t ** (2 * k) * phi(t), -12, 12, 4000)
    M *= (2 * k - 1)        # 双阶乘递推
    assert abs(M_num - M) < 1e-5 * M
print("normal even moments up to 11!! via Simpson vs recurrence: OK")

# ⑤ 指数矩链：E[X^k] = k!·λᵏ（λ = 2，k 到 5；∫x^k e^{-x/λ}/λ dx）
from math import factorial
lam = 2.0
for k in range(1, 6):
    m = simpson(lambda t: t ** k * exp(-t / lam) / lam, 0, 80, 4000)
    assert abs(m - factorial(k) * lam ** k) < 1e-4 * factorial(k) * lam ** k
print("exponential moments k!*lambda^k via Simpson (lambda=2): OK")

print("END ====")
