# -*- coding: utf-8 -*-
"""第 27 章：有限方差 CLT 的特征函数路线与格点修正。"""
import cmath
from math import comb, erf, exp, pi, sqrt

print("==== 27 clt")


def normal_cdf(x):
    return (1 + erf(x / sqrt(2))) / 2


def normal_pdf(x):
    return exp(-x * x / 2) / sqrt(2 * pi)


def poisson_standardized_cf(t, lam):
    """Z=(X-lam)/sqrt(lam) 的特征函数，X~Poisson(lam)。"""
    u = t / sqrt(lam)
    return cmath.exp(-1j * t * sqrt(lam)) * cmath.exp(
        lam * (cmath.exp(1j * u) - 1))


# 1. Poisson 特例展示一般证明的同一极限：phi_Z(t)->exp(-t^2/2)。
for t in (0.5, 1.0):
    target = exp(-t * t / 2)
    values = [poisson_standardized_cf(t, lam) for lam in (5, 50, 500)]
    errors = [abs(value - target) for value in values]
    assert errors[0] > errors[1] > errors[2]
    assert errors[-1] < 0.006
print("Poisson standardized CF -> exp(-t^2/2): OK")


# 2. Taylor 二阶项之后，固定 t 的乘积极限只含 -t^2/2。
for t in (0.5, 1.0):
    target = exp(-t * t / 2)
    values = [(1 - t * t / (2 * n)) ** n for n in (10, 100, 10_000)]
    errors = [abs(value - target) for value in values]
    assert errors[0] > errors[1] > errors[2]
    assert errors[-1] < 1e-5
print("(1-t^2/(2n))^n -> exp(-t^2/2): OK")


# 3. Bin(100,1/2) 的区间概率：端点半格修正不是可选装饰。
exact = sum(comb(100, k) for k in range(45, 56)) / 2 ** 100
raw = normal_cdf(1.0) - normal_cdf(-1.0)
corrected = normal_cdf(1.1) - normal_cdf(-1.1)
assert abs(corrected - exact) < abs(raw - exact)
assert abs(corrected - exact) < 0.0001
print("continuity correction:", round(exact, 8), round(raw, 8),
      round(corrected, 8), "OK")


# 4. 单点概率必须乘格距。Bernoulli 和的格距为 1，标准差为 5。
center = comb(100, 50) / 2 ** 100
local = normal_pdf(0) / 5
assert abs(center / local - 1) < 0.003

# 对称 +/-1 随机游走只落在偶数格，格距为 2；少了因子 2 就错一半。
walk_center = comb(200, 100) / 2 ** 200
walk_local = 2 * normal_pdf(0) / sqrt(200)
assert abs(walk_center / walk_local - 1) < 0.0015
assert abs(walk_center - normal_pdf(0) / sqrt(200)) > 0.028
print("lattice bucket width: Bernoulli h=1 and even walk h=2: OK")

print("END ====")
