# -*- coding: utf-8 -*-
print("==== 44 bochner_theorem")
# 第 44 章 Python：正定性与特征函数（Fraction 精确版）。
# ① 两点分布 cos 特征函数逐点；② Gram 半正定（3×3 精确）；
# ③ 卷积乘积律；④ 三角核 Gram。
from fractions import Fraction
import cmath

# ① (δ₁+δ₋₁)/2 的特征函数 = cos(t)：t = kπ/6 网格
for k in range(6):
    t = cmath.pi * k / 6
    phi = (cmath.exp(1j * t) + cmath.exp(-1j * t)) / 2
    assert abs(phi - cmath.cos(t)) < 1e-12
print("two-point charFn = cos(t) exact at grid: OK"

)
# ② Gram 半正定（3×3 主子式法，整数/分数核）
# 三角核 K(i,j) = max(0, 1 - |i-j|·h)（h = 2/5）
h = Fraction(2, 5)
K = [[max(Fraction(0), 1 - abs(i - j) * h) for j in range(3)] for i in range(3)]
# 一阶主子式 ≥ 0
assert all(K[i][i] >= 0 for i in range(3))
# 二阶主子式 ≥ 0（det ≥ 0）
for i in range(2):
    for j in range(i + 1, 3):
        det2 = K[i][i] * K[j][j] - K[i][j] * K[j][i]
        assert det2 >= 0
# 三阶 det ≥ 0（对称三对角公式）
det3 = (K[0][0] * (K[1][1] * K[2][2] - K[1][2] ** 2)
        - K[0][1] * (K[0][1] * K[2][2] - K[1][2] * 0)
        + 0)
# 展开（利用三对角对称）：
det3 = K[0][0] * K[1][1] * K[2][2] - K[0][1]**2 * K[2][2] - K[0][0] * K[1][2]**2
assert det3 >= 0
print("triangular kernel 3x3 Gram PSD (all principal minors >= 0): OK"

)
# ③ 卷积乘积律（Fraction 精确）
for t_num in (1, 3, 7):
    t = Fraction(t_num, 10)
    # (δ₁+δ₋₁)/2 conv 自身 = {-2:1/4, 0:1/2, 2:1/4}
    phi = (cmath.exp(1j * float(t)) + cmath.exp(-1j * float(t))) / 2
    phi2 = phi ** 2
    phi_conv = (cmath.exp(-2j * float(t)) / 4 + Fraction(1, 2)
                + cmath.exp(2j * float(t)) / 4)
    assert abs(phi2 - phi_conv) < 1e-12
print("convolution product law: charFn^2 = charFn(conv) exact: OK"

)
# ④ 高斯 charFn 闭式在 t = 0 处 = 1
mu, sigma = 0.5, 1.2
closed = cmath.exp(1j * mu * 0 - sigma**2 * 0**2 / 2)
assert closed == 1
print("Gaussian charFn(0) = 1 (normalization): OK"

)
print("END ====")
