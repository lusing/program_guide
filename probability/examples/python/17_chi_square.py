# -*- coding: utf-8 -*-
print("==== 17 chi_square")
# 第 17 章 Python：卡方分布的数值账。
# ① χ²(ν) 密度 Simpson 归一（ν=1..6，Γ(ν/2) 供常数）；
# ② 均值方差的积分 vs (ν, 2ν)；③ χ²(2) 的 CDF 闭式
#    P(Y≤y) = 1−e^{−y/2}；④ 自由度加法的密度验证：χ²(1) 与
#    χ²(2) 的数值卷积 vs χ²(3) 密度逐点；⑤ 中位数与右尾。
from math import exp, gamma as gamma_fn, pi, sqrt


def simpson(f, a, b, n):
    h = (b - a) / n
    s = f(a) + f(b)
    for i in range(1, n):
        s += (4 if i % 2 else 2) * f(a + i * h)
    return s * h / 3


def chi2_pdf(y, nu):
    if y <= 0:
        return 0.0
    return y ** (nu / 2 - 1) * exp(-y / 2) / (2 ** (nu / 2) * gamma_fn(nu / 2))


# ① 归一（ν=1 的 0 端爆破用代换 y = t² 吸收）
for nu in range(1, 7):
    if nu == 1:
        # y = t² 代换后被积化简为 2e^{−t²/2}/√(2π)（直写避免
        # chi2_pdf(0) 的 0 分支在端点注入 1.2e-4 误差）
        tot = simpson(lambda t: 2 * exp(-t * t / 2) / sqrt(2 * pi),
                      0, sqrt(80), 20000)
    else:
        tot = simpson(lambda y: chi2_pdf(y, nu), 1e-9, 80, 20000)
    assert abs(tot - 1) < 1e-4, nu
print("chi2(nu) densities normalize for nu=1..6: OK")

# ② 均值方差 = (ν, 2ν)（ν=1 用代换；ν=3、5 朴素）
for nu in (3, 5):
    m1 = simpson(lambda y: y * chi2_pdf(y, nu), 1e-9, 120, 20000)
    m2 = simpson(lambda y: y * y * chi2_pdf(y, nu), 1e-9, 150, 20000)
    assert abs(m1 - nu) < 5e-3
    assert abs(m2 - (nu ** 2 + 2 * nu)) < 2e-2      # E[Y^2] = ν²+2ν → Var = 2ν
# ν=1 的均值：E[Y] = E[Z²] = 1
# E[Y] = ∫ t²·f(t²)·2t dt：(t²)^{−1/2} 与一个 t 相消 → 2t²e^{−t²/2}/√(2π)
tot1 = simpson(lambda t: 2 * t * t * exp(-t * t / 2) / sqrt(2 * pi),
               0, sqrt(80), 20000)
assert abs(tot1 - 1) < 1e-4
print("chi2 moments: mean=nu, var=2nu for nu=1,3,5: OK")

# ③ χ²(2) 的 CDF 闭式：F(y) = 1 − e^{−y/2}
for y in (0.5, 2.0, 6.0):
    num = simpson(lambda t: chi2_pdf(t, 2), 1e-9, y, 4000)
    assert abs(num - (1 - exp(-y / 2))) < 1e-8
assert abs(1 - exp(-1.0) - 0.6321) < 1e-4           # P(χ²(2) ≤ 2) ≈ 0.632
print("chi2(2) CDF closed form 1 - e^{-y/2}: OK")

# ④ 自由度加法：χ²(1) ∗ χ²(2) = χ²(3)（数值卷积逐点）


def conv12(z):
    # t = u² 代换吸收 χ²(1) 密度在 0 端的 t^{−1/2} 爆破
    # （chi2_pdf(u²,1)·2u = 2e^{−u²/2}/√(2π) 光滑）
    return simpson(lambda u: 2 * u * chi2_pdf(u * u, 1) * chi2_pdf(z - u * u, 2),
                   1e-9, sqrt(z) - 1e-9, 4000)


for z in (0.5, 1.0, 2.0, 4.0, 7.0):
    assert abs(conv12(z) - chi2_pdf(z, 3)) < 3e-4 * max(chi2_pdf(z, 3), 1e-3), z
print("chi2(1)+chi2(2) convolution = chi2(3) at 5 points: OK")

# ⑤ χ²(1) 的中位数（二分）与 ν=5 的右尾 5% 点量级
lo, hi = 0.0, 2.0
for _ in range(60):
    mid = (lo + hi) / 2
    F = simpson(lambda t: 2 * exp(-t * t / 2) / sqrt(2 * pi), 0, sqrt(mid), 2000)
    if F < 0.5:
        lo = mid
    else:
        hi = mid
med = (lo + hi) / 2
assert abs(med - 0.4549) < 1e-3                     # 已知中位数 ≈ 0.4549
# P(χ²(5) > 11.07) ≈ 0.05（统计表值）
tail = simpson(lambda y: chi2_pdf(y, 5), 11.07, 200, 20000)
assert abs(tail - 0.05) < 1e-3
print("chi2(1) median 0.4549; chi2(5) upper 5% point 11.07: OK")

print("END ====")
