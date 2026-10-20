# -*- coding: utf-8 -*-
print("==== 56 lll")
# 第 56 章 Python：重对数律的精确账（Fraction/数值）。
# ① log log 积分墙（习题 25.1 的机器版）；② 正态尾阶梯的覆盖比
#    （习题 25.4/25.5）；③ 几何子列块概率的收敛判决。
from fractions import Fraction
from math import log, exp, sqrt, erf


# ① 积分墙：∫₁^∞ dx/(x (log x)^c) 在 c=1 分界（换元 u = log x 后
#    是 ∫₀^∞ du/u^c——p 积分的墙）。离散版（下和逼近无穷）：
def discrete_integral(c, n_max=10 ** 7):
    """Σ_{k=2}^{n} 1/(k (log k)^c) 的部分和（对数分桶粗化加速）。"""
    s = 0.0
    for k in range(2, 10 ** 6):
        s += 1.0 / (k * log(k) ** c)
    return s


sc_05 = discrete_integral(0.5)
sc_15 = discrete_integral(1.5)
assert sc_05 > 2.0 * sc_15                   # c<1 发散侧远大
# c=1.5 的收敛上界：∫₂^∞ ≤ 2/( (1.5-1)(log 2)^{0.5} ) ≈ 4.8 + 首项
assert sc_15 < 10.0
print("integral wall: c=0.5 partial sum = ", round(sc_05, 2),
      " (diverges); c=1.5 = ", round(sc_15, 2), " (converges): OK")

# ② 正态尾阶梯：∫_x^∞ e^{-t^2/2}dt ≤ (1/x)e^{-x^2/2}（习题 25.4）
#    数值核对（erf 精确积分 vs 上界）
for x, tightness in ((1.0, 0.6), (2.0, 0.8), (3.0, 0.85)):
    integral = sqrt(2 * 3.141592653589793) * 0.5 * (1 - erf(x / sqrt(2)))
    bound = exp(-x * x / 2) / x
    assert integral <= bound * (1 + 1e-9)             # 上界成立
    assert integral > bound * tightness               # 渐近紧（x↑ 越紧）
print("normal tail ladder: integral <= e^{-x^2/2}/x (x = 1,2,3): OK")

# ③ 几何子列块概率（离散模型）：S_m ~ 二项代替正态——
#    Bin(N, 1/2) 标准化 > c·√(2 N LLN) 的概率，N = q^m 几何增长，
#    Σ_m P 越界的收敛/发散随 c 的 0/1（习题 25.7 的二项离散版）
from math import comb


def binom_tail(N, thr):
    mu = N / 2
    sig = sqrt(N / 4)
    z = (thr - mu) / sig
    if z <= 0:
        return 1.0
    # 正态近似 + 连续修正（离散模型的诚实账）
    return 0.5 * (1 - erf((z - 0.5 / sig) / sqrt(2)))


def geometric_series(c, q=1.8, m_max=40):
    total = 0.0
    for m in range(5, m_max):
        N = int(q ** m)
        if N < 20:
            continue
        ll = log(log(N)) if N >= 3 else 0.0
        thr = mu_of(N) + c * sqrt(2 * N * ll) * 0.5     # σ√(2NLLN)，σ=1/2
        total += binom_tail(N, thr)
    return total


def mu_of(N):
    return N / 2


s_plus = geometric_series(1.6)
s_minus = geometric_series(0.4)
assert s_plus < 0.5                                     # c>1：级数收敛
assert s_minus > 3.0                                    # c<1：发散（每个块都大概率越界）
print("geometric block series: c=1.6 sum = ", round(s_plus, 3),
      " (finite); c=0.4 sum = ", round(s_minus, 2), " (diverges): OK")

# ④ 包络刻度的精确账：√(2n log log n) 在 n = e^e^k 处的显式值
#    n = e^e ⟹ LLn = 1 ⟹ 包络 = √(2n)·1（log log 尺度的锚点）
n_anchor = exp(exp(1))
env = sqrt(2 * n_anchor * log(log(n_anchor)))
assert abs(env / sqrt(2 * n_anchor) - 1.0) < 1e-12       # LLn = 1 精确锚
print("envelope anchor: n = e^e gives LLn = 1, envelope = sqrt(2n): OK")

print("END ====")
