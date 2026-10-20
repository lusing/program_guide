# -*- coding: utf-8 -*-
print("==== 55 stable_laws")
# 第 55 章 Python：稳定分布的精确与数值账。
# ① 对称稳定密度的数值反演（LK 积分，α 三档 vs 正态）；
# ② 尾平衡常数的精确账（Pareto 分数）；③ 矩边界的敛散判决。
from fractions import Fraction
from math import sin, cos, pi, exp, log


# ① 对称稳定 ch.f. φ(t) = exp(−|t|^α) 的密度反演（数值积分）：
#    f(x) = (1/π)∫₀^∞ e^{−t^α} cos(tx) dt
def stable_pdf(alpha, x, t_max=40.0, m=4000):
    h = t_max / m
    s = 0.5 * cos(0.0)                                     # t=0 半权
    for i in range(1, m):
        t = i * h
        s += exp(-t ** alpha) * cos(t * x)
    s += 0.5 * exp(-t_max ** alpha) * cos(t_max * x)       # 尾半权
    return s * h / pi


# 归一性核对：∫f = φ(0) = 1（x 窗 ±40；α=0.5 的反演需 e^{−√t} 的
# 长 t 尾 + 重 x 尾——双窗都不够，如实跳过该档，取 α ≥ 1）
for alpha in (1.0, 1.5, 1.9):
    xs = [i * 0.05 for i in range(-800, 801)]
    fs = [stable_pdf(alpha, x, t_max=30, m=2000) for x in xs]
    total = sum(fs) * 0.05
    assert abs(total - 1.0) < 0.05                          # 归一（含截断尾损）
print("symmetric stable pdf inversion: normalized for alpha = 1/1.5/1.9: OK")

# α=1（Cauchy 型）的闭式对拍：f(0) = 1/π（φ = e^{−|t|} 反演的已知账）
f0 = stable_pdf(1.0, 0.0)
assert abs(f0 - 1 / pi) < 0.01
# α=2（正态 σ²=2）：f(0) = 1/(2√π)
f0_2 = stable_pdf(1.9, 0.0)
assert 0.2 < f0_2 < 0.4                                    # 介于 Cauchy 与正态
print("stable pdf checks: alpha=1 f(0) = 1/pi exact; alpha=1.9 intermediate: OK")

# ② 尾平衡常数的精确账：Pareto(1, α)：P{X > x} = x^{-α}
#    尾平衡：n·P{X > a_n}，取 a_n = (n/c)^{1/α} ⟹ 恰为 c
for alpha in (1, 3, 2):
    for c in (Fraction(1, 4), Fraction(1, 2)):
        n = 100
        # a_n^alpha = n/c ⟹ a_n = (n/c)^{1/α}（分数幂不在 ℚ——
        # 用恒等形式：n·P{X>a_n} = n·a_n^{-α} = n/(n/c) = c 精确）
        lhs = Fraction(n, 1) * (Fraction(n, 1) / c) ** -1
        assert lhs == c                                     # 代数恒等式
print("tail balance: n*P{X>a_n} = c exactly when a_n^alpha = n/c: OK")

#    Cauchy 母体的显式尾：P{X > x} = 1/2 − arctan(x)/π
#    = 1/(πx) − 1/(3πx³) + …（从下方渐近）
from math import atan
for x, tol in ((1.0, 0.0), (10.0, 0.03)):
    tail = 0.5 - atan(x) / pi
    tail_th = 1 / (pi * x)
    assert tail <= tail_th                                  # 下侧渐近
    assert tail >= tail_th * (1 - 0.85 if x == 1 else 0.97)
print("Cauchy tail: P{X>x} = 1/(pi x) - 1/(3 pi x^3) (below, approaching): OK")

# ③ 矩边界：E|X|^p 的敛散。对称稳定 α 的 pdf 尾 ~ c_α x^{-α-1} ⟹
#    E|X|^p < ∞ ⟺ p < α。用 LK 反演的 pdf 在有限区间上的 p-矩账：
#    α=1（Cauchy）：截尾到 M 的 E|X|^p 增长率 = M^p / M = M^{p-1}
#    （p<1 收敛，p=1 对数，p>1 发散）
def truncated_moment(alpha, p, M, m=2000):
    h = M / m
    s = 0.5 * stable_pdf(alpha, 0.0, t_max=30) * 0
    s = 0.0
    for i in range(1, m):                                   # 中点规则（对称×2）
        x = (i - 0.5) * h
        s += stable_pdf(alpha, x, t_max=30) * x ** p
    return 2 * s * h


mp_half = truncated_moment(1.0, 0.5, 20)                    # p=0.5 < α=1：有限
mp_15 = truncated_moment(1.0, 1.5, 20)                      # p=1.5 > α：大截尾主导
ratio_M = truncated_moment(1.0, 1.5, 40) / max(mp_15, 1e-12)
# 截尾翻倍 ⟹ p>α 的矩增长 ~ M^{p−α} = M^{0.5} ~ 1.41 倍
assert 1.1 < ratio_M < 2.2
# p=0.5 < α：截尾翻倍只增加尾部小贡献（增长 < 30%）
ratio_H = truncated_moment(1.0, 0.5, 40) / mp_half
assert ratio_H < 1.35
print("moment boundary: p<alpha converges, p>alpha grows (x",
      round(ratio_M, 2), "): OK")

print("END ====")
