# -*- coding: utf-8 -*-
"""第 39 章：拟合优度分解、调整 R² 与 Gauss–Markov 定理。"""
from fractions import Fraction as F
import numpy as np

print("==== 39 ols properties")

# 第 38 章三点例的拟合优度账（全程精确分数）。
y = [F(1), F(2), F(4)]
fitted = [F(5, 6), F(7, 3), F(23, 6)]
resid = [F(1, 6), F(-1, 3), F(1, 6)]
ybar = sum(y) / 3
assert ybar == F(7, 3)
TSS = sum((t - ybar) ** 2 for t in y)
ESS = sum((f - ybar) ** 2 for f in fitted)
RSS = sum(e * e for e in resid)
assert (TSS, ESS, RSS) == (F(14, 3), F(9, 2), F(1, 6))
assert TSS == ESS + RSS                           # 含常数项时的正交分解
assert ESS / TSS == F(27, 28)                     # R²
adj = 1 - (RSS / (3 - 2)) / (TSS / (3 - 1))
assert adj == F(13, 14)                           # 调整 R²
assert RSS / (3 - 2) == F(1, 6)                   # s² 无偏估计的分母 n-k
assert F(3, 6) == F(1, 2)                         # (X'X)^-1 的 (2,2) 元
print("fit decomposition: TSS", TSS, "ESS", ESS, "RSS", RSS,
      "; R2 = 27/28; adj = 13/14; s2 = 1/6")

# 嵌套模型：加入无关变量 RSS 必不增、R² 必不降、调整 R² 可以下降。
rng = np.random.default_rng(39)
n = 8
xd = np.arange(1.0, n + 1)
yv = 2.0 + 0.5 * xd + rng.standard_normal(n)
z = rng.standard_normal(n)                        # 与 y 无关的额外列


def ols_rss(X):
    b, _, _, _ = np.linalg.lstsq(X, yv, rcond=None)
    r = yv - X @ b
    return float(r @ r)


X2 = np.column_stack([np.ones(n), xd])
X3 = np.column_stack([np.ones(n), xd, z])
rss2, rss3 = ols_rss(X2), ols_rss(X3)
tss = float(((yv - yv.mean()) ** 2).sum())
r2_2, r2_3 = 1 - rss2 / tss, 1 - rss3 / tss
adj2 = 1 - (rss2 / (n - 2)) / (tss / (n - 1))
adj3 = 1 - (rss3 / (n - 3)) / (tss / (n - 1))
assert rss3 <= rss2 + 1e-12
assert r2_3 >= r2_2 - 1e-12
print("nested fit: RSS", round(rss2, 4), "->", round(rss3, 4),
      "; R2", round(r2_2, 4), "->", round(r2_3, 4),
      "; adj", round(adj2, 4), "->", round(adj3, 4))

# Gauss–Markov 与 s² 无偏的 Monte Carlo（固定三点设计，sigma^2 = 1）。
Xf = np.array([[1.0, 0.0], [1.0, 1.0], [1.0, 2.0]])
XtXi = np.linalg.inv(Xf.T @ Xf)
rng2 = np.random.default_rng(139)
reps = 20_000
Eps = rng2.standard_normal((reps, 3))             # beta = 0
B = Eps @ Xf @ XtXi
slope = B[:, 1]
simple = Eps[:, 1] - Eps[:, 0]                    # 线性无偏竞争者 y2 - y1
assert np.allclose(slope, (Eps[:, 2] - Eps[:, 0]) / 2)
assert abs(slope.var(ddof=1) - 0.5) < 0.02        # sigma^2 (X'X)^-1_22
assert abs(simple.var(ddof=1) - 2.0) < 0.08       # 2 sigma^2
assert slope.var(ddof=1) < simple.var(ddof=1)
resid_mat = Eps - B @ Xf.T
s2_all = (resid_mat ** 2).sum(axis=1) / (3 - 2)
assert abs(s2_all.mean() - 1.0) < 0.05            # E[s^2] = sigma^2
print("Gauss-Markov MC: var(beta2) =", round(slope.var(ddof=1), 4),
      "vs var(y2-y1) =", round(simple.var(ddof=1), 4),
      "; mean s2 =", round(s2_all.mean(), 4))
print("END ====")
