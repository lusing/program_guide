# -*- coding: utf-8 -*-
"""第 37 章：Wald/LM/LR、检验—区间对偶与覆盖率审计。"""
from fractions import Fraction as F
from math import log, sqrt
import numpy as np
from scipy.stats import chi2, norm, t as student_t

print("==== 37 asymptotic tests")


def bernoulli_wald(n, k, p0):
    phat = F(k, n)
    return n * (phat - p0) ** 2 / (phat * (1 - phat))


def bernoulli_score(n, k, p0):
    phat = F(k, n)
    return n * (phat - p0) ** 2 / (p0 * (1 - p0))


def bernoulli_lr(n, k, p0):
    phat = k / n
    return 2 * (k * log(phat / p0) + (n - k) * log((1 - phat) / (1 - p0)))


# n=20、K=12、p0=1/2：三者不同，但都不超过 chi^2_1 的 5% 临界值。
n, k, p0 = 20, 12, F(1, 2)
wald = bernoulli_wald(n, k, p0)
score = bernoulli_score(n, k, p0)
lr = bernoulli_lr(n, k, float(p0))
assert wald == F(5, 6)
assert score == F(4, 5)
assert abs(lr - 2 * (12 * log(F(6, 5)) + 8 * log(F(4, 5)))) < 1e-15
critical = float(chi2.ppf(0.95, 1))
assert max(float(wald), float(score), lr) < critical
p_wald = float(chi2.sf(float(wald), 1))
p_score = float(chi2.sf(float(score), 1))
p_lr = float(chi2.sf(lr, 1))
assert 0.35 < p_wald < 0.38 and 0.35 < p_score < 0.38 and 0.35 < p_lr < 0.38
print("Bernoulli W/LM/LR:", wald, score, lr)
print("chi-square p-values:", p_wald, p_score, p_lr,
      "; 5% critical:", critical)
# 更远的数据 K=16 显示有限样本差异可以很大。
w16, s16, lr16 = (bernoulli_wald(20, 16, p0), bernoulli_score(20, 16, p0),
                  bernoulli_lr(20, 16, float(p0)))
assert w16 == F(45, 4) and s16 == F(36, 5)
assert w16 > lr16 > s16 > critical
print("K=16 W/LM/LR:", w16, s16, lr16)


# 正态均值的检验—区间对偶：n=16、sigma=4，故标准误为 1。
def normal_mean_interval(xbar, sigma, n, level=0.95):
    half_width = float(norm.ppf((1 + level) / 2)) * sigma / sqrt(n)
    return xbar - half_width, xbar + half_width


def not_rejected(xbar, sigma, n, mu0, level=0.95):
    lower, upper = normal_mean_interval(xbar, sigma, n, level)
    return lower <= mu0 <= upper


xbar, sigma, n = 11.5, 4.0, 16
interval = normal_mean_interval(xbar, sigma, n)
z95 = float(norm.ppf(0.975))
assert abs(interval[0] - (xbar - z95)) < 1e-12
assert abs(interval[1] - (xbar + z95)) < 1e-12
assert not_rejected(xbar, sigma, n, 10)
assert not_rejected(xbar, sigma, n, 12)
assert not not_rejected(xbar, sigma, n, 14)
# 未知方差时同一对偶给出 t 区间。
t_half_width = float(student_t.ppf(0.975, 19)) * 8 / sqrt(20)
t_interval = (48 - t_half_width, 48 + t_half_width)
assert t_interval[0] < 45 < t_interval[1]
print("normal 95% interval:", interval, "; t interval:", t_interval)


# 20 个独立真原假设各用 0.05，至少一个假拒绝的概率约 64.15%。
familywise = 1 - 0.95 ** 20
assert abs(familywise - 0.641514) < 0.00001
assert 0.05 / 20 == 0.0025  # Bonferroni 的单检验水平。
print("20-test familywise error / Bonferroni level:", familywise, 0.05 / 20)


# 固定种子覆盖率：已知方差 z 区间与未知方差 t 区间。
rng = np.random.default_rng(37)
reps, n = 20_000, 16
samples = 10 + 4 * rng.standard_normal((reps, n))
means = samples.mean(axis=1)
standard_deviations = samples.std(axis=1, ddof=1)
z_coverage = np.mean(np.abs(means - 10) <= z95 * 4 / sqrt(n))
tcrit15 = float(student_t.ppf(0.975, 15))
t_coverage = np.mean(np.abs(means - 10) <= tcrit15 * standard_deviations / sqrt(n))
assert 0.94 < z_coverage < 0.96
assert 0.94 < t_coverage < 0.96
print("fixed-seed z/t interval coverage:", z_coverage, t_coverage)
print("END ====")
