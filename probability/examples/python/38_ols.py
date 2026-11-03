# -*- coding: utf-8 -*-
"""第 38 章：OLS 的代数与几何——投影、正规方程与假设分层。"""
from fractions import Fraction as F
import numpy as np

print("==== 38 ols")


def transpose(A):
    return [[A[i][j] for i in range(len(A))] for j in range(len(A[0]))]


def matmul(A, B):
    return [[sum(A[i][k] * B[k][j] for k in range(len(B)))
             for j in range(len(B[0]))] for i in range(len(A))]


def inv2(S):
    det = S[0][0] * S[1][1] - S[0][1] * S[1][0]
    assert det != 0
    return [[S[1][1] / det, -S[0][1] / det],
            [-S[1][0] / det, S[0][0] / det]]


def solve2(S, b):
    invS = inv2(S)
    v = matmul(invS, [[t] for t in b])
    return [row[0] for row in v]


def trace(A):
    return sum(A[i][i] for i in range(len(A)))


# 固定三点设计：x = 0,1,2 带常数列，y = 1,2,4；全程精确分数。
X = [[F(1), F(0)], [F(1), F(1)], [F(1), F(2)]]
y = [F(1), F(2), F(4)]
XtX = matmul(transpose(X), X)
Xty = [row[0] for row in matmul(transpose(X), [[v] for v in y])]
assert XtX == [[F(3), F(3)], [F(3), F(5)]]
assert Xty == [F(7), F(10)]
beta = solve2(XtX, Xty)
assert beta == [F(5, 6), F(3, 2)]
fitted = [X[i][0] * beta[0] + X[i][1] * beta[1] for i in range(3)]
assert fitted == [F(5, 6), F(7, 3), F(23, 6)]
resid = [y[i] - fitted[i] for i in range(3)]
assert resid == [F(1, 6), F(-1, 3), F(1, 6)]
Xte = [row[0] for row in matmul(transpose(X), [[v] for v in resid])]
assert Xte == [F(0), F(0)]                       # X'e = 0 是代数恒等式
assert sum(e * e for e in resid) == F(1, 6)      # RSS
P = matmul(X, matmul(inv2(XtX), transpose(X)))
assert P == [[F(v, 6) for v in row] for row in
             ([5, 2, -1], [2, 2, 2], [-1, 2, 5])]
M = [[(F(1) if i == j else F(0)) - P[i][j] for j in range(3)]
     for i in range(3)]
assert matmul(P, P) == P                          # 幂等
assert matmul(M, M) == M
assert matmul(P, M) == [[F(0)] * 3 for _ in range(3)]
assert trace(P) == 2 and trace(M) == 1            # 秩 = 迹
assert [sum(P[i][j] * y[j] for j in range(3)) for i in range(3)] == fitted
assert [sum(M[i][j] * y[j] for j in range(3)) for i in range(3)] == resid
print("exact OLS: beta = (5/6, 3/2); e = (1/6, -1/3, 1/6); "
      "X'e = 0; rank P = tr P = 2")

# 浮点库解对拍（同一组数换通道）。
Xf = np.array([[1.0, 0.0], [1.0, 1.0], [1.0, 2.0]])
yf = np.array([1.0, 2.0, 4.0])
coef, _, _, _ = np.linalg.lstsq(Xf, yf, rcond=None)
assert np.allclose(coef, [5 / 6, 1.5])
print("numpy cross-check:", coef)

# 误差度量的选择（承自旧 24 章）：固定斜率 a=1，看截距。
# 残差 r = (0.8, 0.9, 0.95, 3.0) 偏斜：E3 选均值、E2 选中位数区间，
# E1 符号相消且无下界——三个度量给出三个不同的"最佳"。
xs = [0.0, 1.0, 2.0, 3.0]
a_fixed = 1.0
ys = [0.8, 1.9, 2.95, 6.0]
N = len(xs)
r = [t - a_fixed * x for x, t in zip(xs, ys)]


def e1(b):
    return sum(rr - b for rr in r)


def E2(b):
    return sum(abs(rr - b) for rr in r)


def E3(b):
    return sum((rr - b) ** 2 for rr in r)


b3 = sum(r) / N                                    # E3：残差均值
assert abs(b3 - 1.4125) < 1e-12
b2 = min((i * 0.001 for i in range(0, 2001)), key=E2)
assert 0.89 < b2 < 0.96                            # E2：落在中位数区间内
assert abs(e1(b3)) < 1e-12 and e1(10.0) < 0 < e1(-10.0)   # E1 无下界
assert E2(b2) < E2(b3) - 0.9 and E3(b3) < E3(b2) - 1.0
assert abs(b2 - b3) > 0.4
print("metric choice: E1 unbounded; E2 intercept", b2,
      "differs from E3", b3)

# 固定设计下 OLS 无偏、协方差 = sigma^2 (X'X)^-1（外生性成立）。
rng = np.random.default_rng(38)
n, sigma, reps = 30, 1.5, 20_000
xd = np.arange(1.0, n + 1)
Xd = np.column_stack([np.ones(n), xd])
XtXi = np.linalg.inv(Xd.T @ Xd)
beta0 = np.array([1.0, 2.0])
Y = Xd @ beta0 + rng.normal(0.0, sigma, (reps, n))
B = Y @ Xd @ XtXi                                  # 每行一个 beta_hat
assert np.allclose(B.mean(axis=0), beta0, atol=0.02)
assert np.allclose(np.cov(B.T), sigma ** 2 * XtXi, atol=0.02)
print("MC unbiased: mean", B.mean(axis=0),
      "; cov diag", np.round(np.diag(np.cov(B.T)), 5))

# 内生性：x = eps + v 与误差相关，斜率 plim = 2 + 1/2；
# 但每个样本里 X'e = 0 依然成立。
rng2 = np.random.default_rng(138)
n2, reps2 = 200, 5000
eps = rng2.standard_normal((reps2, n2))
v = rng2.standard_normal((reps2, n2))
x2 = eps + v
y2 = 1.0 + 2.0 * x2 + eps
xc = x2 - x2.mean(axis=1, keepdims=True)
yc = y2 - y2.mean(axis=1, keepdims=True)
slopes = (xc * yc).sum(axis=1) / (xc * xc).sum(axis=1)
assert abs(slopes.mean() - 2.5) < 0.05
X_first = np.column_stack([np.ones(n2), x2[0]])
e_first = y2[0] - X_first @ np.linalg.lstsq(X_first, y2[0], rcond=None)[0]
assert np.abs(X_first.T @ e_first).max() < 1e-8
print("endogeneity: mean slope", round(slopes.mean(), 4),
      "(plim 2.5); X'e = 0 holds anyway")
print("END ====")
