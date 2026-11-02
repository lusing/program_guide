# -*- coding: utf-8 -*-
print("==== 15 cf")
# PGF 的精确系数/阶乘矩与 CF 的独立和闭式。
from fractions import Fraction
from math import comb, exp


def close(a, b, tol=1e-12):
    assert abs(a - b) <= tol * max(1.0, abs(b)), (a, b)


# X~Bin(n,p)，G(s)=E[s^X]=(q+ps)^n：直接 pmf 求和对拍闭式。
n, p = 5, Fraction(1, 3)
q = 1 - p
for s in (Fraction(0), Fraction(1, 2), Fraction(2)):
    direct = sum(Fraction(comb(n, k)) * p ** k * q ** (n - k) * s ** k
                 for k in range(n + 1))
    assert direct == (q + p * s) ** n
# G'(1)=E[X]，G''(1)=E[X(X-1)]。
mean_direct = sum(k * Fraction(comb(n, k)) * p ** k * q ** (n - k)
                  for k in range(n + 1))
fact2_direct = sum(k * (k - 1) * Fraction(comb(n, k)) * p ** k * q ** (n - k)
                   for k in range(n + 1))
assert mean_direct == n * p
assert fact2_direct == n * (n - 1) * p ** 2
assert fact2_direct + mean_direct - mean_direct ** 2 == n * p * q

# Poisson PGF exp(lambda*(s-1))，独立和参数相加。
lam1, lam2, s = 1.5, 2.25, 0.7
close(exp(lam1 * (s - 1)) * exp(lam2 * (s - 1)),
      exp((lam1 + lam2) * (s - 1)))

# 正态/Cauchy CF 均总存在；独立和对应指数相加。
for t in (-1.2, 0.0, 0.8):
    close(exp(-t * t / 2) * exp(-3 * t * t / 2), exp(-2 * t * t))
    close(exp(-abs(t)) * exp(-2 * abs(t)), exp(-3 * abs(t)))
# 所有分布在 t=0 的 CF 都是 1；这一断言不依赖矩是否存在。
close(exp(0.0), 1.0)

print("PGF coefficients/factorial moments and normal/Poisson/Cauchy CF products: OK")
print("END ====")
