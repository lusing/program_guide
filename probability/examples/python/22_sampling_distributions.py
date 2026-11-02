# -*- coding: utf-8 -*-
print("==== 22 sampling_distributions")
# 第 22 章 Python：随机样本与抽样分布。
# ① Helmert 正交矩阵与平方和分解（sympy / Fraction 精确）
# ② (n-1)S²/σ² ~ χ²(n-1)、X̄ 与 S² 无相关（正态）与相关（指数）
# ③ t = Z/√(V/ν)、t² = F(1,ν)
# ④ 合并方差权重、方差比 F、顺序统计量
# ⑤ χ² 是 Γ 的特例、密度归一
from fractions import Fraction
from math import comb
import numpy as np
import sympy as sp
from scipy import stats, integrate

rng = np.random.default_rng(22)

# ---------------------------------------------------------------- ① Helmert
n = 4
rows = [
    [1, 1, 1, 1],
    [1, -1, 0, 0],
    [1, 1, -2, 0],
    [1, 1, 1, -3],
]
Hu = sp.Matrix(rows)
Hn = sp.Matrix([[sp.Rational(r) / sp.sqrt(sum(c * c for c in row)) for r in row]
                for row in rows])
assert sp.simplify(Hn * Hn.T - sp.eye(n)) == sp.zeros(n, n)
assert sp.simplify(abs(Hn.det())) == 1
# 第一行恒为 (1/√n,...,1/√n)：y1 = √n * x̄
assert all(sp.simplify(Hn[0, j] - 1 / sp.sqrt(n)) == 0 for j in range(n))
print("Helmert n=4: H H^T = I, |det| = 1, first row = 1/sqrt(n): OK")

# 精确分解：Σ(x-μ)² = Σ(x-x̄)² + n(x̄-μ)²，且 Σ(x-x̄)² = y2²+...+yn²
xs = [Fraction(3), Fraction(-1), Fraction(7, 2), Fraction(5, 3)]
mu = Fraction(2, 5)
xbar = sum(xs) / n
ss = sum((x - xbar) ** 2 for x in xs)
assert sum((x - mu) ** 2 for x in xs) == ss + n * (xbar - mu) ** 2
# y_k² = (行 k 与 x 的内积)² / 行 k 的模方
y2s = [sum(Fraction(r) * x for r, x in zip(row, xs)) ** 2 / sum(r * r for r in row)
       for row in rows[1:]]
assert sum(y2s) == ss
print("sum (x-mu)^2 = sum (x-xbar)^2 + n (xbar-mu)^2; SS = y2^2+..+yn^2: OK")

# ---------------------------------------------------------------- ② χ² 与独立性
m, mu0, sig = 8, 3.0, 2.0
N = 200_000
X = rng.normal(mu0, sig, size=(N, m))
xb = X.mean(axis=1)
s2 = X.var(axis=1, ddof=1)
Q = (m - 1) * s2 / sig ** 2
ks = stats.kstest(Q, stats.chi2(m - 1).cdf)
assert ks.statistic < 0.004, ks.statistic
assert abs(Q.mean() - (m - 1)) < 0.03 and abs(Q.var() - 2 * (m - 1)) < 0.15
r_norm = np.corrcoef(xb, s2)[0, 1]
assert abs(r_norm) < 0.01, r_norm
# 对照：指数总体里 X̄ 与 S² 正相关 → 独立性是正态的特征，不是普遍真理
Xe = rng.exponential(1.0, size=(N, m))
r_exp = np.corrcoef(Xe.mean(axis=1), Xe.var(axis=1, ddof=1))[0, 1]
assert r_exp > 0.3, r_exp
# 对照：除以 n 而非 n-1 的有偏 S² 不是 χ²_{n-1}/(n-1) 的无偏估计
assert abs(np.mean(X.var(axis=1, ddof=0)) - sig ** 2 * (m - 1) / m) < 0.02
print("(n-1)S^2/sigma^2 ~ chi2_%d (KS=%.4f); corr normal=%.4f, exponential=%.3f: OK"
      % (m - 1, ks.statistic, r_norm, r_exp))

# 离散反例：Bernoulli(1/2), n=2 → X̄ 与 S² 不独立（S² 由 X̄ 决定）
from itertools import product
pm = {}
for xs2 in product((0, 1), repeat=2):
    xb2 = Fraction(sum(xs2), 2)
    s22 = sum((Fraction(x) - xb2) ** 2 for x in xs2)  # n-1 = 1
    pm[(xb2, s22)] = pm.get((xb2, s22), 0) + Fraction(1, 4)
pxb = {}
ps2 = {}
for (a, b), pr in pm.items():
    pxb[a] = pxb.get(a, 0) + pr
    ps2[b] = ps2.get(b, 0) + pr
assert pm[(Fraction(1, 2), Fraction(1, 2))] == Fraction(1, 2)
assert pxb[Fraction(1, 2)] * ps2[Fraction(1, 2)] == Fraction(1, 4)
print("Bernoulli(1/2), n=2: P(xbar=1/2,S^2=1/2)=1/2 != 1/4 (dependent): OK")

# ---------------------------------------------------------------- ③ t 与 F
T = np.sqrt(m) * (xb - mu0) / np.sqrt(s2)
kst = stats.kstest(T, stats.t(m - 1).cdf)
assert kst.statistic < 0.004, kst.statistic
Z = np.sqrt(m) * (xb - mu0) / sig
assert np.allclose(T, Z / np.sqrt(Q / (m - 1)))          # 恒等式 T = Z/√(V/ν)
# t² ~ F(1, ν)：分位数对账 F_{1,ν}^{-1}(q) = (t_ν^{-1}((1+q)/2))²
for nu in (1, 2, 5, 12, 40):
    for q in (0.5, 0.9, 0.95, 0.99):
        assert abs(stats.f.ppf(q, 1, nu) - stats.t.ppf((1 + q) / 2, nu) ** 2) < 1e-8
kf = stats.kstest(T ** 2, stats.f(1, m - 1).cdf)
assert kf.statistic < 0.004
# t(1) 是 Cauchy、t(ν) 方差 ν/(ν-2)
assert abs(stats.t.cdf(1.7, 1) - stats.cauchy.cdf(1.7)) < 1e-12
assert abs(stats.t(7).var() - 7 / 5) < 1e-12
print("t=Z/sqrt(V/nu) ~ t_%d (KS=%.4f); t^2 ~ F(1,nu) quantile identity: OK"
      % (m - 1, kst.statistic))

# ---------------------------------------------------------------- ④ 合并方差 / F / 顺序统计量
nx, ny = 5, 11
xa = [Fraction(v) for v in (2, 4, 4, 7, 9)]
ya = [Fraction(v) for v in (1, 3, 3, 4, 5, 5, 6, 8, 8, 9, 12)]


def svar(v):
    mm = sum(v) / len(v)
    return sum((a - mm) ** 2 for a in v) / (len(v) - 1)


sp2 = ((nx - 1) * svar(xa) + (ny - 1) * svar(ya)) / (nx + ny - 2)
ssx = sum((a - sum(xa) / nx) ** 2 for a in xa)
ssy = sum((a - sum(ya) / ny) ** 2 for a in ya)
assert sp2 == (ssx + ssy) / (nx + ny - 2)                 # 自由度加权 = 合并平方和 / 总自由度
w = Fraction(nx - 1, nx + ny - 2)
assert sp2 == w * svar(xa) + (1 - w) * svar(ya)           # 凸组合，权重 = 自由度占比
assert sp2 != (svar(xa) + svar(ya)) / 2                   # 不是算术平均
print("pooled variance = df-weighted average (weight %s on x): OK" % w)

# 模拟：合并 t ~ t(nx+ny-2)，方差比 ~ F(nx-1, ny-1)
M = 120_000
A = rng.normal(1.0, 3.0, size=(M, nx))
B = rng.normal(-2.0, 3.0, size=(M, ny))
va, vb = A.var(axis=1, ddof=1), B.var(axis=1, ddof=1)
sp2n = ((nx - 1) * va + (ny - 1) * vb) / (nx + ny - 2)
tt = ((A.mean(axis=1) - B.mean(axis=1)) - (1.0 - (-2.0))) / np.sqrt(sp2n * (1 / nx + 1 / ny))
assert stats.kstest(tt, stats.t(nx + ny - 2).cdf).statistic < 0.005
assert stats.kstest(va / vb, stats.f(nx - 1, ny - 1).cdf).statistic < 0.005
# 异方差时合并 t 失效：σx=1, σy=6 → 拒绝率远离名义 5%
A2 = rng.normal(0.0, 1.0, size=(M, nx))
B2 = rng.normal(0.0, 6.0, size=(M, ny))
sp2h = ((nx - 1) * A2.var(axis=1, ddof=1) + (ny - 1) * B2.var(axis=1, ddof=1)) / (nx + ny - 2)
th = (A2.mean(axis=1) - B2.mean(axis=1)) / np.sqrt(sp2h * (1 / nx + 1 / ny))
crit = stats.t.ppf(0.975, nx + ny - 2)
rej = np.mean(np.abs(th) > crit)
assert rej < 0.03, rej         # 大方差在大样本一侧→合并方差被抬高→保守
# 反向配置：大方差落在小样本一侧 → 合并 t 反保守（实际拒绝率远超名义 5%）
A3 = rng.normal(0.0, 6.0, size=(M, nx))
B3 = rng.normal(0.0, 1.0, size=(M, ny))
sp2r = ((nx - 1) * A3.var(axis=1, ddof=1) + (ny - 1) * B3.var(axis=1, ddof=1)) / (nx + ny - 2)
tr = (A3.mean(axis=1) - B3.mean(axis=1)) / np.sqrt(sp2r * (1 / nx + 1 / ny))
rej2 = np.mean(np.abs(tr) > crit)
assert rej2 > 0.15, rej2
print("pooled t ~ t_%d, variance ratio ~ F(%d,%d); unequal-variance rejection %.3f / %.3f (nominal 0.05): OK"
      % (nx + ny - 2, nx - 1, ny - 1, rej, rej2))

# 非正态总体：t 检验较稳健，F 方差比检验严重失真（指数总体，κ=6）
K = 80_000
ne = 20
E1 = rng.exponential(1.0, size=(K, ne))
E2 = rng.exponential(1.0, size=(K, ne))
rF = E1.var(axis=1, ddof=1) / E2.var(axis=1, ddof=1)
lo, hi = stats.f.ppf(0.025, ne - 1, ne - 1), stats.f.ppf(0.975, ne - 1, ne - 1)
rej_F = np.mean((rF < lo) | (rF > hi))
t1 = np.sqrt(ne) * (E1.mean(axis=1) - 1.0) / E1.std(axis=1, ddof=1)
rej_t = np.mean(np.abs(t1) > stats.t.ppf(0.975, ne - 1))
assert rej_F > 0.15, rej_F          # 名义 5%，实际约 20%
assert 0.04 < rej_t < 0.12, rej_t   # 偏态使 t 略失真，但远不及 F
# Var(S²) = σ⁴(2/(n-1) + κ/n)；指数 κ=6, n=8 → 2/7 + 6/8
s2e = Xe.var(axis=1, ddof=1)
assert abs(s2e.var() - (2 / (m - 1) + 6 / m)) < 0.08
# Cov(X̄,S²) = μ3/n = 2/n
assert abs(np.cov(Xe.mean(axis=1), s2e)[0, 1] - 2 / m) < 0.01
print("non-normal (exponential): F-test rejection %.3f, t-test rejection %.3f (nominal 0.05); "
      "Var(S^2)=sigma^4(2/(n-1)+kappa/n), Cov(xbar,S^2)=mu3/n: OK" % (rej_F, rej_t))

# Welch 自由度落在 [min(n-1), nx+ny-2]
vx, vy = float(svar(xa)), float(svar(ya))
nu_w = (vx / nx + vy / ny) ** 2 / ((vx / nx) ** 2 / (nx - 1) + (vy / ny) ** 2 / (ny - 1))
assert min(nx - 1, ny - 1) <= nu_w <= nx + ny - 2
print("Welch df = %.3f in [%d, %d]: OK" % (nu_w, min(nx - 1, ny - 1), nx + ny - 2))

# 顺序统计量：U(0,1) 的第 k 小 ~ Beta(k, n-k+1)，CDF = Σ_{j>=k} C(n,j) x^j (1-x)^{n-j}
nn = 9
for k in (1, 3, 5, 9):
    for xv in (Fraction(1, 5), Fraction(1, 2), Fraction(7, 10)):
        exact = sum(comb(nn, j) * xv ** j * (1 - xv) ** (nn - j) for j in range(k, nn + 1))
        assert abs(float(exact) - stats.beta.cdf(float(xv), k, nn - k + 1)) < 1e-12
U = np.sort(rng.random((100_000, nn)), axis=1)
for k in (1, 5, 9):
    assert abs(U[:, k - 1].mean() - k / (nn + 1)) < 0.004
# 一般公式：f_(k)(x) = n!/((k-1)!(n-k)!) F^{k-1}(1-F)^{n-k} f，对 N(0,1) 的 k=n 积分为 1
from math import factorial


def f_order(x, kk, nnn):
    cst = factorial(nnn) / (factorial(kk - 1) * factorial(nnn - kk))
    return cst * stats.norm.cdf(x) ** (kk - 1) * (1 - stats.norm.cdf(x)) ** (nnn - kk) * stats.norm.pdf(x)


for kk in (1, 3, 5):
    tot, _ = integrate.quad(lambda x: f_order(x, kk, 5), -12, 12)
    assert abs(tot - 1) < 1e-8
print("order statistics: Beta(k,n-k+1) CDF, general density integrates to 1: OK")

# ---------------------------------------------------------------- ⑤ χ² 是 Γ 的特例
for nu in (1, 2, 3, 7, 10):
    for y in (0.3, 1.0, 4.5, 12.0):
        assert abs(stats.chi2.pdf(y, nu) - stats.gamma.pdf(y, a=nu / 2, scale=2)) < 1e-12
    tot, _ = integrate.quad(lambda y: stats.chi2.pdf(y, nu), 0, np.inf)
    assert abs(tot - 1) < 1e-7
    assert abs(stats.chi2(nu).mean() - nu) < 1e-12 and abs(stats.chi2(nu).var() - 2 * nu) < 1e-12
# 自由度可加：χ²(3)+χ²(4) 的卷积密度 = χ²(7)
for z in (1.0, 5.0, 9.0):
    conv, _ = integrate.quad(lambda u: stats.chi2.pdf(u, 3) * stats.chi2.pdf(z - u, 4), 0, z)
    assert abs(conv - stats.chi2.pdf(z, 7)) < 1e-9
print("chi2(nu) = Gamma(nu/2, scale 2); mean nu, var 2nu; df additive: OK")

print("END ====")
