# -*- coding: utf-8 -*-
"""第 36 章：Neyman–Pearson、精确二项尾、功效与经典检验。"""
from fractions import Fraction as F
from math import comb, sqrt
import numpy as np
from scipy.stats import chi2, norm, t as student_t

print("==== 36 hypothesis testing")


def binomial_tail(n, k, p):
    """P_p(K>=k)，p 为 Fraction 时全程精确。"""
    return sum(F(comb(n, j)) * p ** j * (1 - p) ** (n - j)
               for j in range(k, n + 1))


# 五点 Bernoulli 样本：H0:p=1/4，H1:p=3/4；LR=3^(2K-5)。
n, p0, p1 = 5, F(1, 4), F(3, 4)
assert 3 ** (2 * 4 - n) == 27
size = binomial_tail(n, 4, p0)
power = binomial_tail(n, 4, p1)
assert size == F(1, 64)
assert power == F(81, 128)
assert 1 - power == F(47, 128)
assert binomial_tail(n, 4, p0) == F(1, 64)    # K=4 的上尾 p 值。
assert binomial_tail(n, 3, p0) == F(53, 512)  # K=3 更温和，p 值反而更大。
# 在 K=3 时以 1/5 概率拒绝，可把 size 精确调到 17/512。
gamma = F(1, 5)
randomized_size = size + gamma * binomial_tail(n, 3, p0) - gamma * size
randomized_power = power + gamma * binomial_tail(n, 3, p1) - gamma * power
assert randomized_size == F(17, 512)
assert randomized_power == F(351, 512)
print("Bernoulli NP: size/power:", size, power,
      "; randomized:", randomized_size, randomized_power)


# 正态均值：n=16、sigma=4，标准误恰为 1；H0:mu<=10，右侧 UMP。
def Phi(x):
    return float(norm.cdf(x))


zcrit = float(norm.ppf(0.95))
noncentrality = (12 - 10) * sqrt(16) / 4
power_at_12 = Phi(noncentrality - zcrit)
assert noncentrality == 2
assert abs(power_at_12 - 0.63876) < 0.0001
zobs = (11.5 - 10) / (4 / sqrt(16))
p_upper = 1 - Phi(zobs)
p_two_sided = 2 * (1 - Phi(abs(zobs)))
assert zobs == 1.5
assert abs(p_upper - 0.0668072) < 1e-6
assert abs(p_two_sided - 2 * p_upper) < 1e-12
z95 = float(norm.ppf(0.975))
ci = (11.5 - z95, 11.5 + z95)
assert ci[0] < 10 < ci[1] and ci[0] < 12 < ci[1]
print("normal UMP: critical/power:", round(zcrit, 6), round(power_at_12, 6))
print("observed z=1.5: upper/two-sided p:", p_upper, p_two_sided,
      "; 95% CI:", ci)
print("one-sided power at mu=10,10.5,11,12,13:",
      [round(Phi(mu - 10 - zcrit), 6) for mu in (10, 10.5, 11, 12, 13)])


# 迁移旧 23 的 z/t 对照：同一右侧统计量，未知方差付出 t 尾代价。
tstat = (48 - 45) / (8 / sqrt(20))
p_z = float(norm.sf(tstat))
p_t = float(student_t.sf(tstat, 19))
assert abs(tstat - 1.67705) < 0.0001
assert p_z < 0.05 < p_t < 0.06
assert abs(float(student_t.ppf(0.95, 19)) - 1.72913) < 0.0001
print("z/t reversal:", round(p_z, 6), round(p_t, 6))


# 迁移拟合优度与 Welch 双样本账。
births = [387, 329, 366, 344, 336, 313, 313, 503, 421, 434, 398, 371]
expected = sum(births) / 12
chi2_stat = sum((observed - expected) ** 2 / expected for observed in births)
assert abs(chi2_stat - 93.07) < 0.02
assert chi2.sf(chi2_stat, 11) < 1e-12
xbar, ybar, sx2, sy2, nx, ny = 83.5, 75.4, 168.6, 73.32, 14, 14
welch_nu = ((sx2 / nx + sy2 / ny) ** 2 /
            (sx2 ** 2 / (nx ** 2 * (nx - 1)) +
             sy2 ** 2 / (ny ** 2 * (ny - 1))))
assert abs(welch_nu - 22.5) < 0.15
assert min(nx - 1, ny - 1) <= welch_nu <= nx + ny - 2
print("migrated chi-square/Welch:", round(chi2_stat, 4), round(welch_nu, 4))


# 固定种子只审计选定设计的频率表现；size 与功效公式已在上面给出。
rng = np.random.default_rng(36)
reps = 20_000
null_means = (10 + 4 * rng.standard_normal((reps, 16))).mean(axis=1)
alt_means = (12 + 4 * rng.standard_normal((reps, 16))).mean(axis=1)
empirical_size = np.mean(null_means - 10 > zcrit)
empirical_power = np.mean(alt_means - 10 > zcrit)
assert 0.045 < empirical_size < 0.055
assert 0.61 < empirical_power < 0.67
print("fixed-seed size/power audit:", empirical_size, empirical_power)
print("END ====")
