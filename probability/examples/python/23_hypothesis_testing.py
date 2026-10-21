# -*- coding: utf-8 -*-
print("==== 23 hypothesis_testing")
# 第 23 章 Python：假设检验的数值账。
# ① z 检验三例（麦当劳/灯泡/西雅图）；② t 检验反转现场；
# ③ 两类错误跷跷板；④ 棒球生日 χ² = 93.07；⑤ 双样本三档；
# ⑥ 第一类错误率的模拟审计。
from math import exp, pi, sqrt


def simpson(f, a, b, n):
    h = (b - a) / n
    s = f(a) + f(b)
    for i in range(1, n):
        s += (4 if i % 2 else 2) * f(a + i * h)
    return s * h / 3


phi = lambda x: exp(-x * x / 2) / sqrt(2 * pi)
Phi = lambda x: simpson(phi, -10, x, 4000)          # CDF 数值版

# ① z 三例
z_mcd = (48 - 45) / (8 / sqrt(20))                   # 1.68
p_mcd = 1 - Phi(z_mcd)
assert abs(z_mcd - 1.68) < 0.01 and abs(p_mcd - 0.046) < 0.002
z_bulb = (2050 - 2000) / (100 / sqrt(20))            # 2.24（不是 0.5！）
p_bulb = 2 * (1 - Phi(z_bulb))                       # 双侧
assert abs(z_bulb - 2.236) < 0.01 and abs(p_bulb - 0.025) < 0.002
z_sea = (2300 - 2500) / sqrt(10000 * 0.25 * 0.75)    # -4.62
assert abs(z_sea + 4.619) < 0.005
assert Phi(z_sea) < 3e-6
print("z-tests: mcd 0.046 (reject@.05), bulb 0.025, seattle 2e-6: OK")

# ② t 检验反转：ν=19 的 t 密度数值积分版
def t_pdf(x, nu):
    from math import gamma
    c = gamma((nu + 1) / 2) / (sqrt(nu * pi) * gamma(nu / 2))
    return c * (1 + x * x / nu) ** (-(nu + 1) / 2)


t19_tail = simpson(lambda x: t_pdf(x, 19), 1.68, 12, 4000)
assert abs(t19_tail - 0.055) < 0.002                 # p = 0.055 > 0.05：不拒绝
crit19 = 1.73
tcrit_tail = simpson(lambda x: t_pdf(x, 19), crit19, 12, 4000)
assert abs(tcrit_tail - 0.05) < 0.002                # 临界值 1.73 对 α=0.05
print("t-test reversal: p=0.055 > 0.05, critical 1.73: OK")

# ③ 两类错误跷跷板（WBC 例：健康 N(7000,1000²)、病 N(11000,1500²)）
for thr in (9000, 8540):
    alpha = 1 - Phi((thr - 7000) / 1000)             # 健康被误隔离
    beta = Phi((thr - 11000) / 1500)                 # 病人漏诊
    if thr == 9000:
        assert abs(alpha - 0.023) < 0.002 and abs(beta - 0.091) < 0.002
    else:
        assert abs(beta - 0.05) < 0.003              # β 压到 0.05
        assert abs(alpha - 0.062) < 0.003            # α 升到 0.062
print("type I/II seesaw: thr 9000 (0.023, 0.091) vs 8540 (0.062, 0.05): OK")

# ④ 棒球生日 χ²
births = [387, 329, 366, 344, 336, 313, 313, 503, 421, 434, 398, 371]
n = sum(births)
E = n / 12
chi2 = sum((b - E) ** 2 / E for b in births)
assert abs(chi2 - 93.07) < 0.02
# p 值：χ²(11) 的尾 = 1 - CDF（数值积分，分段避免 0 端奇异）
chi2_pdf = lambda x: x ** (11 / 2 - 1) * exp(-x / 2) / (2 ** (11 / 2) * 144)  # Γ(11/2)=288/5? 用数值
from math import gamma
chi2_pdf = lambda x: x ** 5.5 * exp(-x / 2) / (2 ** 5.5 * gamma(5.5))
p_val = simpson(chi2_pdf, chi2, 400, 4000)
assert p_val < 1e-12                                  # p = 4e-15 量级
print("birthday chi^2 = 93.07 on 11 df, p ~ 1e-15: OK")

# ⑤ 双样本三档（睡眠数据）
xbar, ybar, sx2, sy2, nx, ny = 83.5, 75.4, 168.6, 73.32, 14, 14
# z（把 s² 当 σ²）
z = (xbar - ybar) / sqrt(sx2 / nx + sy2 / ny)
assert abs(z - 1.95) < 0.01
# 合并 t：s²p 同权（nx = ny）
sp2 = ((nx - 1) * sx2 + (ny - 1) * sy2) / (nx + ny - 2)
t = (xbar - ybar) / sqrt(sp2 / nx + sp2 / ny)
assert abs(t - 1.95) < 0.01                          # 同权时与 z 重合
# Welch ν
nu = (sx2 / nx + sy2 / ny) ** 2 / (sx2 ** 2 / (nx ** 2 * (nx - 1))
                                   + sy2 ** 2 / (ny ** 2 * (ny - 1)))
assert abs(nu - 22.5) < 0.15
print("two-sample: z=1.95, pooled t=1.95, welch nu=22.5: OK")

# ⑥ 第一类错误率审计：H0 真（μ=45）时反复检验，拒绝率 ≈ α
import random as _r
_r.seed(23)
alpha = 0.05
zcrit = 1.645                                         # 单侧 0.05
trials, rejections = 20_000, 0
for _ in range(trials):
    sample = [_r.gauss(45, 8) for _ in range(20)]
    m = sum(sample) / 20
    if (m - 45) / (8 / sqrt(20)) > zcrit:
        rejections += 1
assert abs(rejections / trials - alpha) < 0.008
print("type I audit: rejection rate at true H0 = ", rejections / trials,
      " (alpha=0.05): OK", sep="")
print("END ====")
