# -*- coding: utf-8 -*-
"""第 40 章：正态误差下 OLS 的 t 检验、置信区间与 F 检验。"""
from fractions import Fraction as F
import numpy as np
from scipy.stats import f as f_dist, t as t_dist

print("==== 40 ols inference")

# 延续第 38-39 章的五点固定设计，全部精确分数。
x = [0, 1, 2, 3, 4]
y = [1, 3, 2, 5, 4]
n, k = 5, 2
beta_hat = (F(7, 5), F(4, 5))
XtX_inv = [[F(3, 5), F(-1, 5)], [F(-1, 5), F(1, 10)]]
fitted = [beta_hat[0] + beta_hat[1] * t for t in x]
resid = [F(a) - b for a, b in zip(y, fitted)]
assert fitted == [F(7, 5), F(11, 5), F(3), F(19, 5), F(23, 5)]
assert resid == [F(-2, 5), F(4, 5), F(-1), F(6, 5), F(-3, 5)]
RSS = sum(e * e for e in resid)
assert RSS == F(18, 5)
s2 = RSS / (n - k)
assert s2 == F(6, 5)

# t² 与单约束 F 是同一个分数（两种写法）。
t2_sq = beta_hat[1] ** 2 / (s2 * XtX_inv[1][1])
t1_sq = beta_hat[0] ** 2 / (s2 * XtX_inv[0][0])
assert t2_sq == F(16, 3) and t1_sq == F(49, 18)
assert t2_sq == beta_hat[1] ** 2 / XtX_inv[1][1] / s2

# 临界值：F(1,n-k) 的临界值 = t 的双侧 0.975 分位之平方。
tcrit = float(t_dist.ppf(0.975, n - k))
Fcrit = float(f_dist.ppf(0.95, 1, n - k))
assert abs(tcrit - 3.1824) < 1e-4
assert abs(Fcrit - tcrit ** 2) < 1e-8
assert max(float(t1_sq), float(t2_sq)) < Fcrit    # n=5：都不显著
se2 = float((s2 * XtX_inv[1][1]) ** 0.5)
ci = (float(beta_hat[1]) - tcrit * se2, float(beta_hat[1]) + tcrit * se2)
print("exact t^2: t1^2 = 49/18, t2^2 = 16/3; 5% crit", round(Fcrit, 4))
print("95% CI for beta2:", ci)

# 联合显著性 F 的三种算法一致。
TSS = F(10)
ESS = TSS - RSS
assert TSS == F(10) and ESS == F(32, 5)
F_slopes = (ESS / (k - 1)) / (RSS / (n - k))
assert F_slopes == F(16, 3)                          # k=2 时即单约束 F = t2²
R2 = ESS / TSS
assert F_slopes == (R2 / (k - 1)) / ((1 - R2) / (n - k))
# H0: beta1 = beta2 = 0（含截距）：RSS_R = y'y。
yy = sum(F(a) * F(a) for a in y)
assert yy == F(55)
F_all = ((yy - RSS) / 2) / (RSS / 3)
assert F_all == F(257, 12)
print("joint F (slopes):", F_slopes, "; F (all zero):", F_all)

# 联合显著但单个不显著：相关回归变量的经典现场（固定数据集，
# 两种语言共用同一组数，结论可精确复现）。
x1 = [0.0012, 0.2987, -0.2741, -0.8906, -0.4547, -0.9916, 0.0601,
      1.3402, -0.4922, -0.6205, 0.4898, 0.3569, 0.1054, -0.9305,
      -0.0293, 0.6953, -1.3442, -0.4576, -1.9012, -1.2895, -1.8417,
      -0.2351, -1.2674, 0.2713, 0.1568, -0.1869, -2.5168, -0.5387,
      -0.0485, 0.1133, -1.5301, -0.4778, -0.9785, -0.8088, 1.0609,
      -0.8075, -0.0325, 0.8844, -0.5836, -0.1117, 0.1105, 0.0638,
      -1.2251, 0.0761, 1.3588, -1.5471, 0.8594, 0.1194, -0.6415,
      2.0004, 0.7623, -1.1993, 0.0745, 0.5767, -0.1888, 0.6829,
      -0.0665, 0.6672, 1.4385, -0.6757]
x2 = [0.0646, 0.1391, -0.2207, -1.2168, -0.6129, -1.0033, 0.3377,
      1.6308, -0.8809, -0.8376, 0.6673, -0.2831, -0.0445, -0.9144,
      0.3647, 0.8758, -1.3792, -0.5498, -1.8843, -0.7493, -1.8833,
      -0.3182, -1.0939, 0.22, 0.0874, -0.5254, -2.3946, -0.6503,
      0.318, 0.3116, -1.4611, -0.2452, -1.0357, -0.4398, 1.0062,
      -0.585, -0.434, 0.9484, -1.0816, -0.7416, 0.0099, -0.2204,
      -1.1126, 0.7732, 1.0312, -1.6646, 0.8806, 0.2674, -0.6645,
      1.8361, 0.9435, -0.977, -0.252, 0.5231, -0.1683, 0.3195,
      0.018, 0.3659, 1.6701, -0.5817]
eps = [0.0447, -0.2955, -0.0593, -0.9989, -0.5657, 0.1814, -1.0643,
       0.4233, -0.873, 0.3784, -0.4227, 0.3895, 0.0655, -0.7684,
       0.6246, 0.7209, -0.0329, -0.137, -0.0799, -0.4876, 0.5493,
       -0.2714, -0.0256, -0.3966, -0.313, -0.6389, 0.6285, -0.077,
       0.483, 0.0067, -0.3472, -0.1633, -0.2801, 0.004, -0.1876,
       -0.15, -0.6893, -0.4034, 0.827, -0.3356, -0.527, 0.1687,
       0.7036, -0.727, -0.1043, -0.316, -0.8805, 0.3675, -0.0117,
       0.0357, -0.3762, 0.2274, -0.2696, -0.0715, -0.5541, -0.6081,
       0.6678, -0.2536, 0.1458, -0.0169]
nn = 60
yv = 1.0 + 0.12 * np.array(x1) + 0.12 * np.array(x2) + np.array(eps)
Xd = np.column_stack([np.ones(nn), x1, x2])
b, _, _, _ = np.linalg.lstsq(Xd, yv, rcond=None)
e = yv - Xd @ b
s2v = float(e @ e) / (nn - 3)
XtXi = np.linalg.inv(Xd.T @ Xd)
t1v = b[1] / (s2v * XtXi[1, 1]) ** 0.5
t2v = b[2] / (s2v * XtXi[2, 2]) ** 0.5
Fv = float(b[1:] @ np.linalg.solve(XtXi[1:, 1:], b[1:]) / 2 / s2v)
assert abs(t1v + 0.502) < 0.02 and abs(t2v - 1.356) < 0.02
assert abs(Fv - 4.621) < 0.03
assert abs(t1v) < 1.99 and abs(t2v) < 1.99      # t(57) 临界约 2.00
assert Fv > 3.16                                  # F(2,57) 临界约 3.16
print("joint vs single: t1 =", round(t1v, 3), "t2 =", round(t2v, 3),
      "F =", round(Fv, 3), "> crit 3.16")

# 固定设计下 t 区间的精确覆盖率（正态误差、真斜率为 0）。
rng2 = np.random.default_rng(140)
nn2, reps = 30, 20_000
xd = np.arange(1.0, nn2 + 1)
Xd2 = np.column_stack([np.ones(nn2), xd])
XtXi2 = np.linalg.inv(Xd2.T @ Xd2)
tc = float(t_dist.ppf(0.975, nn2 - 2))
E = rng2.standard_normal((reps, nn2))               # beta = (0,0), sigma = 1
B = E @ Xd2 @ XtXi2
res = E - B @ Xd2.T
s2_all = (res ** 2).sum(axis=1) / (nn2 - 2)
se_slope = (s2_all * XtXi2[1, 1]) ** 0.5
coverage = np.mean(np.abs(B[:, 1]) <= tc * se_slope)
rej_rate = np.mean(np.abs(B[:, 1]) / se_slope > tc)
assert 0.945 < coverage < 0.955
assert abs(rej_rate - 0.05) < 0.005
print("t-interval coverage:", coverage, "; size:", rej_rate)
print("END ====")
