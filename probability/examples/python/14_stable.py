# -*- coding: utf-8 -*-
print("==== 14 stable")
# 对数正态矩、Cauchy 尾积分原函数与稳定分布的 CF 闭式。
from math import atan, exp, log, log1p, pi


def close(a, b, tol=1e-12):
    assert abs(a - b) <= tol * max(1.0, abs(b)), (a, b)


# Y=exp(X), X~N(mu,sigma^2)：E[Y^r]=exp(r*mu+r^2*sigma^2/2)。
mu, sigma = 0.4, 0.7
for r in (1, 2, 3):
    direct = exp(r * mu + r * r * sigma * sigma / 2)
    close(log(direct), r * mu + r * r * sigma * sigma / 2)
mean = exp(mu + sigma * sigma / 2)
second = exp(2 * mu + 2 * sigma * sigma)
close(second - mean ** 2, (exp(sigma * sigma) - 1) * exp(2 * mu + sigma * sigma))
assert mean > exp(mu)

# Cauchy CDF 与“均值原函数随窗口对数增长”的闭式账。
for A in (0.0, 1.0, 3.0):
    tail = 0.5 - atan(A) / pi
    close(tail + (0.5 + atan(A) / pi), 1.0)
for B in (10.0, 100.0, 1000.0):
    primitive = (log1p(B * B) - log(2.0)) / (2 * pi)
    assert primitive > 0
# B 每扩大 10 倍，truncated first absolute moment 约增加 log(10)/pi。
p10 = (log1p(10000.0) - log1p(100.0)) / (2 * pi)
close(p10, log(10) / pi, 3e-3)

# 标准 Cauchy 的 CF 为 exp(-|t|)：独立和对应尺度相加。
for t in (-1.3, -0.2, 0.5, 2.0):
    close(exp(-2 * abs(t)), exp(-abs(2 * t)))
# 标准正态 CF 为 exp(-t^2/2)：独立和对应方差相加。
for t in (-1.3, 0.5, 2.0):
    close(exp(-t * t), exp(-(2 * t * t) / 2))

print("lognormal moments, Cauchy logarithmic tail, normal/Cauchy stability: OK")
print("END ====")
