# -*- coding: utf-8 -*-
"""第 00 章：随机游走与确定性混沌的一阶滞后相关。"""
import random


def lag1_corr(x):
    """计算样本一阶滞后 Pearson 相关系数（完全用基础库，避免黑箱）。"""
    n = len(x) - 1
    u = x[:-1]
    v = x[1:]
    mu = sum(u) / n
    mv = sum(v) / n
    cov = sum((a - mu) * (b - mv) for a, b in zip(u, v))
    su = sum((a - mu) ** 2 for a in u)
    sv = sum((b - mv) ** 2 for b in v)
    return cov / (su * sv) ** 0.5


def logistic_series(x0, n=20000):
    x = x0
    out = [x]
    for _ in range(n - 1):
        x = 4.0 * x * (1.0 - x)
        out.append(x)
    return out


print("==== 00 intro")
for x0 in (0.1, 0.2, 0.3, 0.7, 0.123456):
    corr = lag1_corr(logistic_series(x0))
    print(f"logistic x0={x0:<8} lag1 corr = {corr: .12f}")
    assert abs(corr) < 0.02

random.seed(7)
gaussian_steps = [random.gauss(0.0, 1.0) for _ in range(20000)]
gcorr = lag1_corr(gaussian_steps)
print(f"i.i.d. Gaussian steps seed=7 lag1 corr = {gcorr: .12f}")
assert abs(gcorr) < 0.02

# 决定性的一步可由当前值完全确定；这与相关系数接近零并不矛盾。
x = 0.3
for _ in range(3):
    nxt = 4.0 * x * (1.0 - x)
    assert abs(nxt - (4.0 * x * (1.0 - x))) < 1e-15
    x = nxt
print("logistic is deterministic: next value equals 4*x*(1-x) exactly")
print("END ====")
