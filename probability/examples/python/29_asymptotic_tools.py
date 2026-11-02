# -*- coding: utf-8 -*-
"""第 29 章：Op/op、Slutsky 与 Delta 方法的精确和数值账。"""
import random
import statistics
from math import erf, log, sqrt
import sympy as sp

print("==== 29 asymptotic_tools")


def delta_variance(g, theta, base_variance):
    """一阶 Delta：sqrt(n)(g(Tn)-g(theta)) 的渐近方差。"""
    return sp.simplify(sp.diff(g, theta) ** 2 * base_variance)


p = sp.symbols("p", positive=True)
mu, variance = sp.symbols("mu variance", positive=True)

# 三个闭式例子：样本均值函数、Poisson 方差稳定化、Bernoulli logit。
assert delta_variance(mu ** 2, mu, variance) == 4 * mu ** 2 * variance
assert delta_variance(sp.sqrt(p), p, p) == sp.Rational(1, 4)
logit_variance = delta_variance(sp.log(p / (1 - p)), p, p * (1 - p))
assert sp.simplify(logit_variance - 1 / (p * (1 - p))) == 0
print("Delta variances: mu^2, sqrt(Poisson mean), Bernoulli logit: OK")


# 导数为零时一阶项消失；g(x)=x^2 必须改用 n 倍尺度和二阶项。
x = sp.symbols("x")
assert sp.diff(x ** 2, x).subs(x, 0) == 0
assert sp.diff(x ** 2, x, 2).subs(x, 0) == 2
print("zero derivative: second-order Delta uses n, not sqrt(n): OK")


def normal_cdf(z):
    return (1 + erf(z / sqrt(2))) / 2


random.seed(29)
true_p = 0.25
n = 400
reps = 50_000
logits = []
for _ in range(reps):
    phat = sum(random.random() < true_p for _ in range(n)) / n
    logits.append(log(phat / (1 - phat)))

# Delta 预测的 logit 渐近方差：1/(n p(1-p))。
predicted = 1 / (n * true_p * (1 - true_p))
observed = statistics.variance(logits)
assert abs(observed / predicted - 1) < 0.08

# 插入一致估计的标准误后仍渐近 N(0,1)：用正态样本的 t 统计量
# 隔离检查 Slutsky，避免把 Bernoulli 偏态与插入误差混在同一个阈值里。
studentized = []
for _ in range(30_000):
    xs = [random.gauss(0, 1) for _ in range(100)]
    xbar = statistics.mean(xs)
    studentized.append(sqrt(100) * xbar / statistics.stdev(xs))
for lo, hi in ((-1.0, 0.0), (0.0, 1.0)):
    empirical = sum(lo <= z < hi for z in studentized) / len(studentized)
    target = normal_cdf(hi) - normal_cdf(lo)
    assert abs(empirical - target) < 0.01
print("Slutsky plug-in SE and simulated Delta variance: OK")


# 二阶反例：若样本来自 N(0,1)，n*(样本均值)^2 恰好是 chi^2_1，
# 因而均值为 1、方差为 2；它不收敛到均值为 0 的正态极限。
for size in (1, 10, 100):
    q = []
    for _ in range(20_000):
        xbar = sum(random.gauss(0, 1) for _ in range(size)) / size
        q.append(size * xbar * xbar)
    assert abs(statistics.mean(q) - 1) < 0.05
    assert abs(statistics.variance(q) - 2) < 0.12
print("second-order limit: n*xbar^2 has chi-square_1 moments: OK")

# 确定序列对应 Op/op 的尺度：1/sqrt(n)->0，而 mu+sigma/sqrt(n) 有界。
scales = [1 / sqrt(k) for k in (1, 10, 100, 1000)]
assert scales[0] > scales[1] > scales[2] > scales[3]
assert all(abs(2 + 3 * scale) <= 5 for scale in scales)
print("op(1) shrinkage and Op(1) bound: OK")

print("END ====")
