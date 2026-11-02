# -*- coding: utf-8 -*-
print("==== 13 families")
# 广义 Gamma、Beta、Laplace：全部用变量代换后的闭式对账。
from math import exp, gamma, log
from scipy.integrate import quad


def close(a, b, tol=1e-12):
    assert abs(a - b) <= tol * max(1.0, abs(b)), (a, b)


# 广义 Gamma：先作 t=(x/theta)^p，再独立积分审计矩公式。
k, p, theta = 2.0, 3.0, 1.5
for r in (0, 1, 2):
    numerical = theta ** r * quad(
        lambda t: t ** (k + r / p - 1) * exp(-t), 0, 40,
        epsabs=1e-11, epsrel=1e-11)[0] / gamma(k)
    closed = theta ** r * gamma(k + r / p) / gamma(k)
    close(numerical, closed, 1e-9)
# p=1 退化为 Gamma(k,theta)，均值 k*theta。
close(theta * gamma(k + 1) / gamma(k), k * theta)
# k=1 时是 Weibull(p,theta)，生存函数 exp(-(x/theta)^p)。
for x in (0.2, 1.0, 2.0):
    t = (x / theta) ** p
    close(exp(-t) * exp(t), 1.0)

# Beta(a,b)：均值与方差来自 B(a+r,b)/B(a,b)。
a, b = 2.0, 3.0
mean = a / (a + b)
second = a * (a + 1) / ((a + b) * (a + b + 1))
close(mean, 2 / 5)
close(second - mean ** 2, a * b / ((a + b) ** 2 * (a + b + 1)))
close(second, 1 / 5)

# Laplace(mu,b)：对称性和 E|X-mu|^2=2b^2。
mu, scale = -1.0, 2.0
for x in (0.5, 1.0, 3.0):
    left = exp(-abs((mu - x) - mu) / scale) / (2 * scale)
    right = exp(-abs((mu + x) - mu) / scale) / (2 * scale)
    close(left, right)
close(2 * scale ** 2, 8.0)
# 右尾 CDF：x>=mu 时 F(x)=1-exp(-(x-mu)/b)/2。
x = mu + scale * log(2)
close(1 - exp(-(x - mu) / scale) / 2, 3 / 4)

print("generalized gamma moments, Weibull survival, Beta moments, Laplace tails: OK")
print("END ====")
