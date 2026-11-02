# -*- coding: utf-8 -*-
"""第 32 章：似然、得分、信息、MLE 与固定数据 Newton 迭代。"""
from fractions import Fraction
from math import comb, log
import sympy as sp

print("==== 32 mle")


def bernoulli_score(x, p):
    return x / p - (1 - x) / (1 - p)


def bernoulli_information(p):
    return 1 / (p * (1 - p))


# 一个 Bernoulli 观测：得分零均值、得分方差等于 Fisher 信息。
p = Fraction(1, 3)
scores = {0: bernoulli_score(0, p), 1: bernoulli_score(1, p)}
assert (1 - p) * scores[0] + p * scores[1] == 0
score_variance = (1 - p) * scores[0] ** 2 + p * scores[1] ** 2
expected_negative_curvature = (
    (1 - p) / (1 - p) ** 2 + p / p ** 2)
assert score_variance == expected_negative_curvature == bernoulli_information(p)
print("Bernoulli score mean and information equality: OK")


# 固定数据 7/10：牛顿法求得分方程的零点，再与闭式 MLE 对账。
data = [1, 0, 1, 1, 0, 1, 0, 1, 1, 1]


def bernoulli_loglik(p, observations):
    k, n = sum(observations), len(observations)
    value = 0.0
    if k:
        value += k * log(p)
    if n - k:
        value += (n - k) * log(1 - p)
    return value


def bernoulli_newton(observations, start=0.2, tolerance=1e-12):
    p = start
    history = [p]
    for _ in range(30):
        k, n = sum(observations), len(observations)
        score = k / p - (n - k) / (1 - p)
        curvature = -k / p ** 2 - (n - k) / (1 - p) ** 2
        candidate = p - score / curvature
        if not 0 < candidate < 1:
            raise ValueError("unconstrained Newton left (0,1)")
        history.append(candidate)
        if abs(candidate - p) < tolerance:
            return candidate, history
        p = candidate
    raise RuntimeError("Newton did not converge")


phat, history = bernoulli_newton(data)
assert abs(phat - sum(data) / len(data)) < 1e-12
assert bernoulli_loglik(phat, data) >= bernoulli_loglik(0.2, data)
odds_hat = phat / (1 - phat)
assert abs(odds_hat / (1 + odds_hat) - phat) < 1e-12
print("Newton history:", [round(x, 8) for x in history])


# 正态固定数据 [1,2,4,5]：mu_hat=3，v_hat=10/4=5/2。
xs = [Fraction(x) for x in (1, 2, 4, 5)]
n = len(xs)
mu_hat = sum(xs) / n
q = sum((x - mu_hat) ** 2 for x in xs)
v_hat = q / n
assert (mu_hat, q, v_hat) == (3, 10, Fraction(5, 2))
normal_score_mu = sum(x - mu_hat for x in xs) / v_hat
normal_score_v = -n / (2 * v_hat) + q / (2 * v_hat ** 2)
assert normal_score_mu == normal_score_v == 0


# Poisson 的符号账：E[X]=lambda，故 E[score]=0、E[-score']=1/lambda。
x, lam = sp.symbols("x lambda", positive=True)
poisson_loglik = x * sp.log(lam) - lam - sp.log(sp.factorial(x))
poisson_score = sp.diff(poisson_loglik, lam)
assert sp.simplify(poisson_score.subs(x, lam)) == 0
assert sp.simplify(-sp.diff(poisson_score, lam).subs(x, lam) - 1 / lam) == 0


# k/n 的抽样性质用二项分布精确求和，不用模拟冒充证明。
n, p = 8, Fraction(1, 4)
weights = [(k, Fraction(comb(n, k)) * p ** k * (1 - p) ** (n - k))
           for k in range(n + 1)]
assert sum(weight for _, weight in weights) == 1
mean_phat = sum(Fraction(k, n) * weight for k, weight in weights)
second_moment = sum(Fraction(k, n) ** 2 * weight for k, weight in weights)
assert mean_phat == p
assert second_moment - mean_phat ** 2 == p * (1 - p) / n
print("normal and Poisson MLE; exact Binomial sampling moments: OK")
print("END ====")
