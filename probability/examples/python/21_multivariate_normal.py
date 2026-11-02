# -*- coding: utf-8 -*-
print("==== 21 multivariate_normal")
# 第 21 章 Python：二元 / 多元正态。
# ① sympy 符号：二元正态密度的配方，边际 N(μ1,σ1²)，条件 N(μ2+ρσ2/σ1(x−μ1), σ2²(1−ρ²))
# ② 协方差矩阵、行列式、逆、Schur 补，与二元公式一致
# ③ MGF 的配方恒等式 + 一般 3 维 Schur 补与精度矩阵（Fraction 精确）
# ④ 零相关 ⇔ 独立（联合正态）；两个"边际正态但非联合正态"的反例
# ⑤ Cholesky 生成、Mahalanobis 距离 ~ χ²_p、线性变换
import numpy as np
import sympy as sp
from fractions import Fraction as F
from scipy import integrate, stats

# ---------------------------------------------------------------- ①
x, y = sp.symbols("x y", real=True)
m1, m2 = sp.symbols("mu1 mu2", real=True)
s1, s2 = sp.symbols("sigma1 sigma2", positive=True)
rho = sp.symbols("rho", real=True)
a = (x - m1) / s1
b = (y - m2) / s2
q = (a ** 2 - 2 * rho * a * b + b ** 2) / (1 - rho ** 2)
f_xy = sp.exp(-q / 2) / (2 * sp.pi * s1 * s2 * sp.sqrt(1 - rho ** 2))
f_x = sp.exp(-a ** 2 / 2) / (sp.sqrt(2 * sp.pi) * s1)
mu_c = m2 + rho * s2 / s1 * (x - m1)
var_c = s2 ** 2 * (1 - rho ** 2)
f_cond = sp.exp(-(y - mu_c) ** 2 / (2 * var_c)) / sp.sqrt(2 * sp.pi * var_c)
# 配方：q/2 的指数 = a²/2 + (y−μ_c)²/(2 var_c)
assert sp.simplify(q - (a ** 2 + (y - mu_c) ** 2 / var_c)) == 0
# 乘法法则 f(x,y) = f_X(x) f_{Y|X}(y|x)
ratio = sp.simplify(sp.powsimp(sp.expand_power_exp(f_xy / (f_x * f_cond))))
assert sp.simplify(ratio - 1) == 0
print("1 completing the square: f(x,y)=f_X(x)f_{Y|X}(y|x) (sympy): OK")

# ---------------------------------------------------------------- ②
Sigma = sp.Matrix([[s1 ** 2, rho * s1 * s2], [rho * s1 * s2, s2 ** 2]])
assert sp.simplify(Sigma.det() - s1 ** 2 * s2 ** 2 * (1 - rho ** 2)) == 0
Sinv = Sigma.inv()
z = sp.Matrix([x - m1, y - m2])
assert sp.simplify((z.T * Sinv * z)[0] - q) == 0     # 二次型 = q
S11, S12, S21, S22 = Sigma[0, 0], Sigma[0, 1], Sigma[1, 0], Sigma[1, 1]
assert sp.simplify(S22 - S21 / S11 * S12 - var_c) == 0               # Schur 补 = σ2²(1−ρ²)
assert sp.simplify(S21 / S11 - rho * s2 / s1) == 0                   # 回归系数
# 全方差：Var(Y) = β²σ1² + σ2²(1−ρ²) = σ2²
beta = S21 / S11
assert sp.simplify(beta ** 2 * S11 + var_c - S22) == 0
print("2 det, inverse, Schur complement, Var(Y)=b^2 s1^2+s2^2(1-r^2): OK")

# ---------------------------------------------------------------- ③
# MGF：(x−μ)ᵀΣ⁻¹(x−μ) − 2tᵀx = (x−μ−Σt)ᵀΣ⁻¹(x−μ−Σt) − 2tᵀμ − tᵀΣt
t1, t2 = sp.symbols("t1 t2", real=True)
tt = sp.Matrix([t1, t2])
mu = sp.Matrix([m1, m2])
X = sp.Matrix([x, y])
lhs = ((X - mu).T * Sinv * (X - mu))[0] - 2 * (tt.T * X)[0]
rhs = ((X - mu - Sigma * tt).T * Sinv * (X - mu - Sigma * tt))[0] - 2 * (tt.T * mu)[0] - (tt.T * Sigma * tt)[0]
assert sp.simplify(lhs - rhs) == 0
print("3a MGF square identity => M(t)=exp(t.mu+t.Sigma.t/2): OK")

# 一般 3 维 Fraction 精确：条件协方差 = Schur 补 = (Λ22)⁻¹（Λ=Σ⁻¹）
S3 = sp.Matrix([[4, 2, 1], [2, 3, F(1, 2)], [1, F(1, 2), 2]]).applyfunc(sp.nsimplify)
assert S3[0, 0] > 0 and S3[:2, :2].det() > 0 and S3.det() > 0       # Sylvester 顺序主子式
A = S3[:2, :2]            # 被预测块 (X1,X2)
B = S3[:2, 2:]            # 与条件变量 X3 的协方差
C = S3[2:, 2:]
schur = A - B * C.inv() * B.T
Lam = S3.inv()
assert sp.simplify(schur - Lam[:2, :2].inv()) == sp.zeros(2, 2)           # Schur = (Λ_AA)⁻¹
# 条件均值的回归系数 B C⁻¹ = −(Λ_AA)⁻¹ Λ_AB
assert sp.simplify(B * C.inv() + Lam[:2, :2].inv() * Lam[:2, 2:]) == sp.zeros(2, 1)
# 条件方差不超过无条件方差（对角线）
assert all(schur[i, i] <= A[i, i] for i in range(2))
print("3b Schur complement = inverse of precision block (exact rationals): OK")

# ---------------------------------------------------------------- ④
# 零相关 ⇔ 独立：ρ=0 时联合密度 = 边际乘积
f0 = f_xy.subs(rho, 0)
assert sp.simplify(f0 - f_x * sp.exp(-b ** 2 / 2) / (sp.sqrt(2 * sp.pi) * s2)) == 0

# 反例 A：X~N(0,1)，S=±1 等概率独立，Y=SX。Y~N(0,1)，Cov=0，但 |Y|=|X|，且 P(X+Y=0)=1/2
rng = np.random.default_rng(21)
n = 400_000
Xs = rng.standard_normal(n)
Ss = rng.choice([-1.0, 1.0], size=n)
Ys = Ss * Xs
assert abs(np.mean(Xs * Ys)) < 0.01                       # 样本协方差 ≈ 0
assert stats.kstest(Ys, "norm").pvalue > 1e-3             # Y 的边际是标准正态
assert np.mean(np.abs(Xs + Ys) < 1e-12) > 0.49            # X+Y 有 1/2 概率恰为 0 ⇒ 不是正态
# 独立会推出 E[X²Y²] = 1，而这里 E[X²Y²] = E[X⁴] = 3
assert abs(np.mean(Xs ** 2 * Ys ** 2) - 3) < 0.08
print("4a sign-flip counterexample: uncorrelated, marginals normal, not independent: OK")

# 反例 B：f(x,y) = 2φ(x)φ(y)·1{xy>0}。边际是标准正态，相关系数 2/π
phi = stats.norm.pdf
fx_num = integrate.quad(lambda v: 2 * phi(0.7) * phi(v), 0, np.inf)[0]     # x=0.7>0：只在 y>0 积分
assert abs(fx_num - phi(0.7)) < 1e-10
fx_neg = integrate.quad(lambda v: 2 * phi(-1.3) * phi(v), -np.inf, 0)[0]   # x<0：只在 y<0 积分
assert abs(fx_neg - phi(-1.3)) < 1e-10
cov_num = 2 * 2 * integrate.quad(lambda v: v * phi(v), 0, np.inf)[0] ** 2   # 第一、三象限各 2(∫_0^∞xφ)²
assert abs(cov_num - 2 / np.pi) < 1e-10
print("4b support-restricted density: marginals N(0,1), rho=2/pi, not bivariate normal: OK")

# ---------------------------------------------------------------- ⑤
mu_v = np.array([1.0, -2.0, 0.5])
Sig = np.array([[4.0, 2.0, 1.0], [2.0, 3.0, 0.5], [1.0, 0.5, 2.0]])
L = np.linalg.cholesky(Sig)
assert np.allclose(L @ L.T, Sig) and np.allclose(L, np.tril(L))
Zs = rng.standard_normal((n, 3))
Xv = mu_v + Zs @ L.T                                      # X = μ + L Z
assert np.allclose(Xv.mean(0), mu_v, atol=0.02)
assert np.allclose(np.cov(Xv.T), Sig, atol=0.05)
# Mahalanobis 距离²：d² = (X−μ)ᵀΣ⁻¹(X−μ) ~ χ²_3
D = Xv - mu_v
d2 = np.einsum("ij,jk,ik->i", D, np.linalg.inv(Sig), D)
assert abs(d2.mean() - 3) < 0.03 and abs(d2.var() - 6) < 0.15
assert stats.kstest(d2, stats.chi2(3).cdf).pvalue > 1e-3
# 线性变换：AX ~ N(Aμ, AΣAᵀ)
Amat = np.array([[1.0, -1.0, 0.0], [0.5, 0.5, 2.0]])
Y2 = Xv @ Amat.T
assert np.allclose(np.cov(Y2.T), Amat @ Sig @ Amat.T, atol=0.08)
# 条件分布的 Schur 形式：给定 X3 的条件协方差 vs 回归残差的样本协方差
B = Sig[:2, 2:]
C = Sig[2:, 2:]
beta = (B @ np.linalg.inv(C)).ravel()
resid = Xv[:, :2] - mu_v[:2] - np.outer(Xv[:, 2] - mu_v[2], beta)
schur_np = Sig[:2, :2] - B @ np.linalg.inv(C) @ B.T
assert np.allclose(np.cov(resid.T), schur_np, atol=0.05)
assert abs(np.corrcoef(resid[:, 0], Xv[:, 2])[0, 1]) < 0.01     # 残差与条件变量不相关（⇒独立）
print("5 Cholesky, Mahalanobis~chi2_3, linear map, Schur complement: OK")
print("END ====")
