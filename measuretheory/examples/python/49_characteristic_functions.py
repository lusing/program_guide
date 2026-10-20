# -*- coding: utf-8 -*-
print("==== 49 characteristic_functions")
# 第 49 章 Python：φ 代数账（Fraction/精确）。
# ① 两点分布的 cos 账；② Bin 的 (q+pe^{it})ⁿ 展开系数；
# ③ Lévy 收敛的闭式对拍；④ Taylor 余项。
from fractions import Fraction
from math import comb
import cmath

# ① (δ₁+δ₋₁)/2 的 φ(t) = cos(t)（Euler）
for k in range(5):
    t = cmath.pi * k / 4
    phi = (cmath.exp(1j * t) + cmath.exp(-1j * t)) / 2
    assert abs(phi - cmath.cos(t)) < 1e-13
print("two-point charFn = cos(t) exact: OK")

# ② Bin(4, 1/2) 的 (q+pe^{it})⁴ 系数 = 概率表
n, p, q = 4, Fraction(1, 2), Fraction(1, 2)
probs = [Fraction(comb(n, k), 2 ** n) for k in range(n + 1)]
assert probs == [Fraction(1,16), Fraction(1,4), Fraction(3,8), Fraction(1,4), Fraction(1,16)]
assert sum(probs) == 1
print("Bin(4,1/2) coefficients = polynomial of (q+pe^{it})^4: OK")

# ③ Lévy 收敛：(cos(t/√n))ⁿ → e^{−t²/2}（数值逼近 + 有理界）
t = 1.0
def levy_approx(n, t):
    return (cmath.cos(t / cmath.sqrt(n))) ** n
closed = cmath.exp(-t**2 / 2)
vals = [abs(levy_approx(n, t) - closed) for n in (10, 100, 1000)]
assert vals[0] > vals[1] > vals[2]                 # 单调收敛
assert vals[2] < 0.001                             # 渐近精度
print("Levy convergence: (cos(t/sqrt n))^n -> e^{-t^2/2} decreasing: OK")

# ④ Taylor 余项：e^{−t²/2} − (1 − t²/2) 的阶
for t in (0.2, 0.5):
    phi = cmath.exp(-t**2 / 2)
    second = 1 - t**2 / 2
    rem = abs(phi - second)
    assert rem < t**4 / 8 + 1e-12                  # 余项 ~ t⁴/8
print("Taylor remainder bounded by t^4/8: OK")

print("END ====")
