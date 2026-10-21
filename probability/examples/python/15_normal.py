# -*- coding: utf-8 -*-
print("==== 15 normal")
# 第 15 章 Python：正态分布的数值账。
# ① φ 的 Simpson 归一/均值/方差；② 偶矩链 vs (2m−1)!!；
# ③ 68-95-99.7；④ 和稳定性：N(0,1)+N(3,4) 的卷积数值 vs
#    N(3,5) 逐点；⑤ 极坐标技巧的数值重演。
from math import exp, pi, sqrt


def simpson(f, a, b, n):
    h = (b - a) / n
    s = f(a) + f(b)
    for i in range(1, n):
        s += (4 if i % 2 else 2) * f(a + i * h)
    return s * h / 3


phi = lambda x: exp(-x * x / 2) / sqrt(2 * pi)

# ① 归一 / 均值 / 方差
assert abs(simpson(phi, -10, 10, 4000) - 1) < 1e-10
assert abs(simpson(lambda x: x * phi(x), -10, 10, 4000)) < 1e-12   # 奇函数
assert abs(simpson(lambda x: x * x * phi(x), -10, 10, 4000) - 1) < 1e-9
print("phi: normalizes to 1, mean 0 (odd), var 1: OK")

# ② 偶矩链 M(2m) = (2m−1)!!
M = 1.0
for m in range(1, 7):
    val = simpson(lambda t: t ** (2 * m) * phi(t), -12, 12, 6000)
    M *= (2 * m - 1)
    assert abs(val - M) < 1e-5 * M
print("even moments M(2)..M(12) = 1,3,15,105,945,10395: OK")

# ③ 68-95-99.7
for k, target in [(1, 0.6827), (2, 0.9545), (3, 0.9973)]:
    mass = simpson(phi, -k, k, 4000)
    assert abs(mass - target) < 5e-5
print("68-95-99.7 rule: 0.6827 / 0.9545 / 0.9973: OK")

# ④ 和稳定性：X~N(0,1), Y~N(3,4) 独立 → X+Y ~ N(3,5)
#    卷积数值（t 网格上 Simpson）vs N(3,5) 密度


def conv_at(z):
    fx = lambda t: phi(t)
    fy = lambda t: exp(-(t - 3) ** 2 / 8) / sqrt(8 * pi)
    return simpson(lambda t: fx(t) * fy(z - t), -12, 12, 4000)


fsum = lambda z: exp(-(z - 3) ** 2 / 10) / sqrt(10 * pi)
for z in (-2, -1, 0, 1, 2, 3, 4, 5, 8):
    assert abs(conv_at(z) - fsum(z)) < 2e-7
print("stability: N(0,1)*N(3,4) convolution = N(3,5) at 9 points: OK")

# ⑤ 极坐标技巧重演：∬ e^{−(x²+y²)/2}/(2π) dxdy = 1
g = lambda x, y: exp(-(x * x + y * y) / 2) / (2 * pi)
# 极坐标形式 ∫₀^{2π}∫₀^R g·r dr dθ = 1 − e^{−R²/2}
for R in (3.0, 5.0):
    polar = 2 * pi * simpson(lambda r: exp(-r * r / 2) / (2 * pi) * r, 0, R, 4000)
    assert abs(polar - (1 - exp(-R * R / 2))) < 1e-9
assert exp(-25) < 2e-11                   # R = 5 的外溢质量 e^{−12.5}
# 直角坐标复核（网格 Simpson × Simpson；±6 窗口尾部 e^{−18} 可忽略）
grid = simpson(lambda x: simpson(lambda y, x=x: g(x, y), -6, 6, 300), -6, 6, 300)
assert abs(grid - 1) < 1e-7
print("polar trick: radial integral 1-e^{-R^2/2}, Cartesian double check: OK")

print("END ====")
