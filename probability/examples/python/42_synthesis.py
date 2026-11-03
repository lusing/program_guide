# -*- coding: utf-8 -*-
"""第 42 章：合成劳动力市场全程——DGP、OLS、MLE、IV、WLS。"""
from fractions import Fraction as F
import numpy as np

print("==== 42 synthesis")

# —— DGP（全部参数公开）——
# ability A ~ N(0,1)，distance D ~ N(0,1)，U ~ N(0,1)，eps ~ N(0, 0.5^2) 全独立
# educ  E = 10 + 2A + 1.0*D + U          Var(E)=6, Cov(E,A)=2, Cov(D,E)=1
# wage  W = 4.6 + 0.1*E + 0.3*A + eps
B_EDUC, B_ABILITY, SIGMA = 0.1, 0.3, 0.5

# —— 总体账（精确分数）——
var_E = F(4) + F(1) + F(1)
cov_EA = F(2)
bias = F(3, 10) * cov_EA / var_E          # 0.3 * 2/6
assert bias == F(1, 10)
plim_short = F(1, 10) + bias
assert plim_short == F(1, 5)              # 短回归斜率 → 0.2（高估一倍）
iv_estimand = F(1, 10) / F(1)             # Cov(D,W)/Cov(D,E) = 0.1/1
assert iv_estimand == F(1, 10)
print("population: bias = 1/10, plim short = 1/5, IV estimand = 1/10")


def simulate(rng, reps, n):
    A = rng.standard_normal((reps, n))
    D = rng.standard_normal((reps, n))
    U = rng.standard_normal((reps, n))
    E = 10 + 2 * A + D + U
    eps = SIGMA * rng.standard_normal((reps, n))
    W = 4.6 + B_EDUC * E + B_ABILITY * A + eps
    return A, D, E, W


# —— 一次抽样（n=500，固定种子）：描述统计 + 四种估计 ——
rng = np.random.default_rng(42)
A0, D0, E0, W0 = simulate(rng, 1, 500)
A0, D0, E0, W0 = A0[0], D0[0], E0[0], W0[0]
assert abs(E0.mean() - 10) < 0.5 and abs(E0.var() - 6) < 1.2
assert abs(W0.mean() - (4.6 + 0.1 * E0.mean() + 0.3 * A0.mean())) < 0.1


def ols(X, y):
    b, _, _, _ = np.linalg.lstsq(X, y, rcond=None)
    return b


X_short = np.column_stack([np.ones(500), E0])
X_long = np.column_stack([np.ones(500), E0, A0])
b_short = ols(X_short, W0)
b_long = ols(X_long, W0)
assert abs(b_short[1] - 0.2) < 0.05           # 单样本贴住偏误后的 0.2
assert abs(b_long[1] - 0.1) < 0.06
assert abs(b_long[2] - 0.3) < 0.15
# IV（恰好识别）：Cov(D,W)/Cov(D,E)
d_c, w_c, e_c = D0 - D0.mean(), W0 - W0.mean(), E0 - E0.mean()
iv = (d_c * w_c).sum() / (d_c * e_c).sum()
assert abs(iv - 0.1) < 0.09
# 长模型 t 检验：教育与能力都显著
e_hat = W0 - X_long @ b_long
s2 = float(e_hat @ e_hat) / (500 - 3)
XtXi = np.linalg.inv(X_long.T @ X_long)
t_educ = b_long[1] / np.sqrt(s2 * XtXi[1, 1])
t_ability = b_long[2] / np.sqrt(s2 * XtXi[2, 2])
assert t_educ > 4 and t_ability > 4
print("one sample: short %.4f, long (%.4f, %.4f), IV %.4f;"
      % (b_short[1], b_long[1], b_long[2], iv),
      "t_educ %.2f t_ability %.2f" % (t_educ, t_ability))

# —— MLE 与 OLS 一致 + AIC/BIC 模型比较（正态似然）——


def loglik(X, y, b):
    r = y - X @ b
    s2m = float(r @ r) / len(y)
    return -0.5 * len(y) * (np.log(2 * np.pi * s2m) + 1)


ll_hat = loglik(X_long, W0, b_long)
for delta in (0.01, -0.01, 0.02):
    pert = b_long.copy()
    pert[1] += delta
    assert ll_hat > loglik(X_long, W0, pert)  # OLS 点就是似然峰
ll_short = loglik(X_short, W0, b_short)
aic_long, aic_short = -2 * ll_hat + 2 * 3, -2 * ll_short + 2 * 2
bic_long, bic_short = -2 * ll_hat + 3 * np.log(500), -2 * ll_short + 2 * np.log(500)
assert aic_long < aic_short and bic_long < bic_short
print("model choice: AIC long %.1f < short %.1f; BIC long %.1f < short %.1f"
      % (aic_long, aic_short, bic_long, bic_short))

# —— Monte Carlo：三个估计量的概率极限 ——
rng2 = np.random.default_rng(142)
reps = 4000
A, D, E, W = simulate(rng2, reps, 500)
Ec = E - E.mean(axis=1, keepdims=True)
Wc = W - W.mean(axis=1, keepdims=True)
Ac = A - A.mean(axis=1, keepdims=True)
Dc = D - D.mean(axis=1, keepdims=True)
sxx = (Ec * Ec).sum(axis=1)
short_slopes = (Ec * Wc).sum(axis=1) / sxx            # 短回归
# 长模型斜率：E 对 (1, A) 残差化后回归（Frisch–Waugh）
def rcol(M):
    return M.sum(axis=1, keepdims=True)


Ea = Ec - Ac * (rcol(Ac * Ec) / rcol(Ac * Ac))
long_slopes = (Ea * Wc).sum(axis=1) / (Ea * Ea).sum(axis=1)
iv_slopes = (Dc * Wc).sum(axis=1) / (Dc * Ec).sum(axis=1)
assert abs(short_slopes.mean() - 0.2) < 0.01
assert abs(long_slopes.mean() - 0.1) < 0.01
assert abs(iv_slopes.mean() - 0.1) < 0.01
mse_short = ((short_slopes - 0.1) ** 2).mean()        # 围绕真值的 MSE
mse_long = ((long_slopes - 0.1) ** 2).mean()
assert short_slopes.var(ddof=1) < long_slopes.var(ddof=1)   # 偏但更稳
assert mse_long < mse_short / 10                     # 偏误主导一切
print("MC: mean short %.4f -> 0.2, long %.4f -> 0.1, IV %.4f -> 0.1"
      % (short_slopes.mean(), long_slopes.mean(), iv_slopes.mean()))
print("MC: var short %.6f < var long %.6f; MSE long %.6f << short %.6f"
      % (short_slopes.var(ddof=1), long_slopes.var(ddof=1),
         mse_long, mse_short))

# —— WLS 收官：已知异方差下方差对照（理论 + MC）——
n_wls = 100
xw = np.arange(1.0, n_wls + 1)
w = np.concatenate([np.ones(50), 4 * np.ones(50)])    # 后半样本方差 ×4
Xw = np.column_stack([np.ones(n_wls), xw])
Omega = np.diag(w)
XtXi_w = np.linalg.inv(Xw.T @ Xw)
var_ols_th = (XtXi_w @ (Xw.T @ Omega @ Xw) @ XtXi_w)[1, 1]
Winv = np.diag(1 / w)
var_wls_th = np.linalg.inv(Xw.T @ Winv @ Xw)[1, 1]
rng3 = np.random.default_rng(242)
reps3 = 4000
Ew = rng3.standard_normal((reps3, n_wls)) * np.sqrt(w)
Yw = 2 + 0.5 * xw + Ew
B_ols = (Yw @ Xw @ np.linalg.inv(Xw.T @ Xw))[:, 1]
B_wls = (Yw @ (Winv @ Xw) @ np.linalg.inv(Xw.T @ Winv @ Xw))[:, 1]
assert abs(B_ols.var(ddof=1) - var_ols_th) < 0.1 * var_ols_th
assert abs(B_wls.var(ddof=1) - var_wls_th) < 0.1 * var_wls_th
assert B_wls.var(ddof=1) < B_ols.var(ddof=1)
print("WLS: var OLS %.6f vs var WLS %.6f (theory %.6f / %.6f)"
      % (B_ols.var(ddof=1), B_wls.var(ddof=1), var_ols_th, var_wls_th))
print("END ====")
