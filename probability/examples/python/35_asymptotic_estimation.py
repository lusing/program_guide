# -*- coding: utf-8 -*-
"""第 35 章：MLE/GMM sandwich、误设稳健方差与固定种子审计。"""
from fractions import Fraction as F
import numpy as np

print("==== 35 asymptotic estimation")


def scalar_sandwich(a, j):
    """A=E[ell'']，J=Var(score)；sqrt(n) 误差的渐近方差。"""
    assert a != 0
    return j / a ** 2


# 工作模型 N(mu,1)，真实分布只需均值 mu*、方差 v。
assert scalar_sandwich(F(-1), F(4)) == F(4)
assert scalar_sandwich(F(-1), F(1)) == F(1)

# Poisson 伪似然：A=-1/lambda*，J=Var_Q(X)/lambda*^2。
lam, true_variance = F(2), F(5)
a_pois = -1 / lam
j_pois = true_variance / lam ** 2
assert scalar_sandwich(a_pois, j_pois) == true_variance == F(5)
assert lam == F(2)  # 正确 Poisson 模型下，sqrt(n) 渐近方差才会化成 lambda。
print("quasi-normal variance:", scalar_sandwich(F(-1), F(4)),
      "; quasi-Poisson variance:", scalar_sandwich(a_pois, j_pois))


# 两个线性矩条件的一般 sandwich 与最优权重化简。
g = np.ones((2, 1))
s = np.diag([1.0, 4.0])

def gmm_asymptotic_variance(g, w, s):
    gwg = g.T @ w @ g
    return np.linalg.solve(gwg, g.T @ w @ s @ w @ g @ np.linalg.inv(gwg))


omega_i = gmm_asymptotic_variance(g, np.eye(2), s)
omega_star = gmm_asymptotic_variance(g, np.linalg.inv(s), s)
assert np.allclose(omega_i, [[1.25]])
assert np.allclose(omega_star, [[0.8]])
assert np.allclose(omega_star, np.linalg.inv(g.T @ np.linalg.inv(s) @ g))
q, p = 2, 1
assert q - p == 1  # 最优权重下 J 的渐近自由度。
print("GMM sandwich and optimal variance:", omega_i[0, 0], omega_star[0, 0])


# 工作模型 N(mu,1)，真实 X=1+2E，E~Exp(1)。伪真均值 mu*=3。
# 模拟只检查有限样本标准误和覆盖率，不证明渐近定理。
rng = np.random.default_rng(35)
reps, n = 20_000, 200
samples = 1 + 2 * rng.exponential(size=(reps, n))
estimates = samples.mean(axis=1)
robust_ses = samples.std(axis=1, ddof=1) / np.sqrt(n)
naive_ses = np.full(reps, 1 / np.sqrt(n))
pseudo_true = 3.0
naive_coverage = np.mean(np.abs(estimates - pseudo_true) <= 1.96 * naive_ses)
robust_coverage = np.mean(np.abs(estimates - pseudo_true) <= 1.96 * robust_ses)
empirical_se = estimates.std(ddof=1)
assert 1.95 < empirical_se / naive_ses[0] < 2.05
assert 0.62 < naive_coverage < 0.72
assert 0.93 < robust_coverage < 0.96
print("simulation: empirical/naive SE ratio:", round(empirical_se / naive_ses[0], 4))
print("simulation: naive/robust 95% coverage:",
      round(naive_coverage, 4), round(robust_coverage, 4))
print("END ====")
