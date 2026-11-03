# -*- coding: utf-8 -*-
"""第 41 章：受约束 OLS、遗漏变量偏误与广义最小二乘。"""
from fractions import Fraction as F
import numpy as np

print("==== 41 gls")


def solve_exact(A, b):
    """高斯消元，Fraction 全程精确。"""
    m = len(A)
    aug = [row[:] + [b[i]] for i, row in enumerate(A)]
    for col in range(m):
        piv = next(r for r in range(col, m) if aug[r][col] != 0)
        aug[col], aug[piv] = aug[piv], aug[col]
        pv = aug[col][col]
        aug[col] = [v / pv for v in aug[col]]
        for r2 in range(m):
            if r2 != col and aug[r2][col] != 0:
                fac = aug[r2][col]
                aug[r2] = [a - fac * c for a, c in zip(aug[r2], aug[col])]
    return [aug[i][m] for i in range(m)]


def normal_solve(Xcols, yv):
    """Xcols: k 个长度 n 的列（含常数列）；返回精确 beta。"""
    kk = len(Xcols)
    XtX = [[sum(c1 * c2 for c1, c2 in zip(Xcols[i], Xcols[j]))
            for j in range(kk)] for i in range(kk)]
    Xty = [sum(c * t for c, t in zip(Xcols[i], yv)) for i in range(kk)]
    return solve_exact(XtX, Xty)


x = [0, 1, 2, 3, 4]
y = [F(1), F(3), F(2), F(5), F(4)]
ones = [F(1)] * 5

# —— 受约束 OLS：beta2 = 1 ——
beta_hat = (F(7, 5), F(4, 5))
XtX_inv = [[F(3, 5), F(-1, 5)], [F(-1, 5), F(1, 10)]]
col = [XtX_inv[0][1], XtX_inv[1][1]]                # (X'X)^-1 R'
assert col == [F(-1, 5), F(1, 10)]
scalar = beta_hat[1] - F(1)                          # R beta_hat - r
assert scalar == F(-1, 5)
adjust = [c * scalar / XtX_inv[1][1] for c in col]
beta_tilde = [beta_hat[i] - adjust[i] for i in range(2)]
assert beta_tilde == [F(1), F(1)]                    # 闭式公式
resid_r = [t - F(1 + v) for t, v in zip(y, x)]       # 受约束拟合 x + 1
assert resid_r == [F(0), F(1), F(-1), F(1), F(-1)]
RSS_R = sum(e * e for e in resid_r)
RSS_U = F(18, 5)
assert RSS_R == F(4)
assert RSS_R - RSS_U == scalar ** 2 / XtX_inv[1][1] == F(2, 5)   # 二次型
F_stat = ((RSS_R - RSS_U) / 1) / (RSS_U / 3)
assert F_stat == F(1, 3)
print("restricted beta2=1: beta_tilde = (1,1); RSS_R = 4; F = 1/3")

# —— 长模型精确解（三参数，z2 = (0,0,1,1,2)）——
z2 = [F(0), F(0), F(1), F(1), F(2)]
beta_long = normal_solve([ones, [F(v) for v in x], z2], y)
assert beta_long == [F(11, 15), F(37, 15), F(-10, 3)]
Xf = np.array([[1.0, v, w] for v, w in zip(x, [0, 0, 1, 1, 2])])
yf = np.array([1.0, 3.0, 2.0, 5.0, 4.0])
bf, _, _, _ = np.linalg.lstsq(Xf, yf, rcond=None)
assert np.allclose(bf, [11 / 15, 37 / 15, -10 / 3])

# —— 正交回归变量不碰已有系数 ——
z_orth = [F(0), F(1), F(-2), F(1), F(0)]
assert sum(z_orth) == 0 and sum(a * b for a, b in zip(x, z_orth)) == 0
beta_orth = normal_solve([ones, [F(v) for v in x], z_orth], y)
assert beta_orth[:2] == [F(7, 5), F(4, 5)]
assert beta_orth[2] == F(2, 3)                        # sum(zy)/(z'z) = 4/6
print("orthogonal regressor: slopes unchanged; extra coef 2/3")

# —— 遗漏变量偏误：真实 beta3 = 2 时短模型偏差 = (-2/5, 1) ——
bias_unit = solve_exact([[F(5), F(10)], [F(10), F(30)]],
                        [F(4), F(13)])                # (X1'X1)^-1 X1'z2
assert bias_unit == [F(-1, 5), F(1, 2)]
bias = [F(2) * v for v in bias_unit]
assert bias == [F(-2, 5), F(1)]
rng = np.random.default_rng(41)
reps_omit = 50_000
E = rng.standard_normal((reps_omit, 5))               # sigma = 1
Y = 1.0 + np.array(x, float) + 2.0 * np.array([0, 0, 1, 1, 2], float) + E
short = np.column_stack([np.ones(5), np.array(x, float)])
B_short = Y @ short @ np.linalg.inv(short.T @ short)
B_long = Y @ Xf @ np.linalg.inv(Xf.T @ Xf)
assert np.allclose(B_short.mean(axis=0), [0.6, 2.0], atol=0.02)
assert np.allclose(B_long.mean(axis=0), [1.0, 1.0, 2.0], atol=0.03)
print("omitted variable: short mean", B_short.mean(axis=0).round(4),
      "(theory 0.6, 2); long mean", B_long.mean(axis=0).round(4))

# —— 无关但相关的变量：方差膨胀 14/15 vs 1/10 ——
XtX3 = [[F(5), F(10), F(4)], [F(10), F(30), F(13)], [F(4), F(13), F(6)]]
assert solve_exact(XtX3, [F(1), F(0), F(0)]) == [F(11, 15), F(-8, 15), F(2, 3)]
assert solve_exact(XtX3, [F(0), F(1), F(0)]) == [F(-8, 15), F(14, 15), F(-5, 3)]
assert F(14, 15) / F(1, 10) == F(28, 3)
print("irrelevant regressor: Var ratio (14/15)/(1/10) = 28/3")

# —— GLS/Aitken：Omega = diag(1,1,1,4,4) ——
w = [F(1), F(1), F(1), F(4), F(4)]
w_inv = [F(1) / t for t in w]
Sw = sum(w_inv)
Swx = sum(a * b for a, b in zip(w_inv, x))
Swxx = sum(a * F(b * b) for a, b in zip(w_inv, x))
Swy = sum(a * b for a, b in zip(w_inv, y))
Swxy = sum(a * b * c for a, b, c in zip(w_inv, x, y))
assert (Sw, Swx, Swxx) == (F(7, 2), F(19, 4), F(45, 4))
assert (Swy, Swxy) == (F(33, 4), F(59, 4))
det = Sw * Swxx - Swx ** 2
assert det == F(269, 16)
beta_gls = [(Swxx * Swy - Swx * Swxy) / det, (Sw * Swxy - Swx * Swy) / det]
assert beta_gls == [F(364, 269), F(199, 269)]
# 变换后 OLS 与 GLS 公式一致：常数列也要除以 sqrt(w)。
sq = [F(1), F(1), F(1), F(2), F(2)]
c1 = [F(1) / s for s in sq]
c2 = [F(v) / s for v, s in zip(x, sq)]
y_star = [t / s for t, s in zip(y, sq)]
beta_trans = normal_solve([c1, c2], y_star)
assert beta_trans == beta_gls
# OLS 在真实协方差下的斜率方差 vs GLS 方差。
XtOmegaX = [[F(11), F(31)], [F(31), F(105)]]
row2 = [F(-1, 5), F(1, 10)]
v_vec = [sum(XtOmegaX[i][j] * row2[j] for j in range(2)) for i in range(2)]
assert v_vec == [F(9, 10), F(43, 10)]
var_ols = sum(row2[i] * v_vec[i] for i in range(2))
assert var_ols == F(1, 4)
var_gls = Sw / det
assert var_gls == F(56, 269)
assert var_gls < var_ols
print("GLS: beta =", beta_gls, "; Var OLS = 1/4 > Var GLS = 56/269")

# Aitken 的 Monte Carlo 审计（sigma^2 = 1，真值为 0）。
rng2 = np.random.default_rng(141)
sd = np.array([1.0, 1.0, 1.0, 2.0, 2.0])
Xf2 = np.column_stack([np.ones(5), np.array(x, float)])
Wm = np.diag(1.0 / np.array([1, 1, 1, 4, 4], float))
A_gls = np.linalg.inv(Xf2.T @ Wm @ Xf2) @ Xf2.T @ Wm
Y2 = sd * rng2.standard_normal((20_000, 5))
ols_slopes = (Y2 @ Xf2 @ np.linalg.inv(Xf2.T @ Xf2))[:, 1]
gls_slopes = (Y2 @ A_gls.T)[:, 1]
assert abs(ols_slopes.var(ddof=1) - 0.25) < 0.01
assert abs(gls_slopes.var(ddof=1) - 56 / 269) < 0.01
assert gls_slopes.var(ddof=1) < ols_slopes.var(ddof=1)
print("Aitken MC: var OLS =", round(ols_slopes.var(ddof=1), 4),
      "var GLS =", round(gls_slopes.var(ddof=1), 4))
print("END ====")
