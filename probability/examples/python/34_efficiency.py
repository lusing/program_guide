# -*- coding: utf-8 -*-
"""第 34 章：Rao–Blackwell、UMVU 与 Cramér–Rao 下界的精确账。"""
from fractions import Fraction as F
from itertools import product
from math import comb

print("==== 34 efficiency")


def mean_and_variance(values):
    """对 (取值, 概率) 列表计算精确均值与方差。"""
    assert sum(weight for _, weight in values) == 1
    mean = sum(value * weight for value, weight in values)
    second = sum(value ** 2 * weight for value, weight in values)
    return mean, second - mean ** 2


# X1 无偏但浪费数据；对 K=sum(X) 条件化后得到 K/n。
n, p = 4, F(1, 3)
raw, improved = [], []
for bits in product((0, 1), repeat=n):
    weight = p ** sum(bits) * (1 - p) ** (n - sum(bits))
    raw.append((F(bits[0]), weight))
    improved.append((F(sum(bits), n), weight))
raw_mean, raw_variance = mean_and_variance(raw)
rb_mean, rb_variance = mean_and_variance(improved)
assert raw_mean == rb_mean == p
assert raw_variance == p * (1 - p)
assert rb_variance == p * (1 - p) / n
assert rb_variance < raw_variance
print("Rao-Blackwell variances:", raw_variance, "->", rb_variance)


# Bernoulli 均值的方差恰达到 IID Cramer–Rao 下界。
n, p = 8, F(1, 4)
weights = [(k, F(comb(n, k)) * p ** k * (1 - p) ** (n - k))
           for k in range(n + 1)]
phat_values = [(F(k, n), weight) for k, weight in weights]
mean_phat, var_phat = mean_and_variance(phat_values)
information = F(n, 1) / (p * (1 - p))
cr_bound = 1 / information
assert mean_phat == p
assert var_phat == cr_bound == p * (1 - p) / n
print("Bernoulli variance and CR bound:", var_phat, cr_bound)


# 正态方差 v：均值未知时 S^2 是 UMVU，但不达到 CR 下界。
n, v = 10, F(3)
var_s2 = 2 * v ** 2 / (n - 1)
cr_v = 2 * v ** 2 / n
var_known_mean = 2 * v ** 2 / n
assert var_s2 == 2
assert cr_v == var_known_mean == F(9, 5)
assert var_s2 - cr_v == 2 * v ** 2 / (n * (n - 1)) == F(1, 5)
assert cr_v / var_s2 == F(n - 1, n) == F(9, 10)
print("normal variance: Var(S^2), CR, efficiency:",
      var_s2, cr_v, cr_v / var_s2)
print("END ====")
