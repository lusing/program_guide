# -*- coding: utf-8 -*-
print("==== 11 convolutions")
# 第 11 章 Python：卷积与变量替换的精确分数账。
# ① 两骰卷积分段公式 vs 36 格枚举；② 四骰 grouping 卷积
#    （Fraction 精确）vs 1296 全枚举；③ 连续均匀自卷积的
#    三角形密度（分段多项式精确 + Simpson 归一）；④ 换元例
#    全账：E[Y] = 4/3 双路会师；⑤ 指数商 1/(1+z)² 的解析账。
from fractions import Fraction
from itertools import product


def convolve_discrete(f, g, z):
    """离散卷积 (f*g)(z) = Σ f(t)g(z−t)（dict 型 pmf）。"""
    return sum(p * g.get(z - t, Fraction(0)) for t, p in f.items())


# ① 两骰：三角形公式 vs 枚举
die = {k: Fraction(1, 6) for k in range(1, 7)}
f2 = {z: convolve_discrete(die, die, z) for z in range(2, 13)}
enum2 = {}
for a, b in product(range(1, 7), repeat=2):
    enum2[a + b] = enum2.get(a + b, Fraction(0)) + Fraction(1, 36)
assert f2 == enum2
assert sum(f2.values()) == 1
assert f2[8] == Fraction(5, 36)
print("two-dice convolution = 36-cell enumeration: OK")

# ② 四骰 grouping：f4 = f2 * f2（Fraction 精确）vs 1296 枚举
f4 = {z: convolve_discrete(f2, f2, z) for z in range(4, 25)}
assert sum(f4.values()) == 1
assert f4[6] == Fraction(10, 1296)
enum4 = {}
for r in product(range(1, 7), repeat=4):
    s = sum(r)
    enum4[s] = enum4.get(s, Fraction(0)) + Fraction(1, 1296)
assert f4 == enum4
# 对称检查：f4(z) = f4(28−z)
assert all(f4[z] == f4[28 - z] for z in range(4, 25))
print("four-dice grouping f2*f2 = 1296-cell enumeration, f4(6)=10/1296: OK")

# ③ 连续：U[−1/2,1/2] 自卷积的三角形密度 (f*f)(z) = 1 − |z|（|z| ≤ 1）
#    精确片段积分验证归一与区间概率


def tri_cdf(z):  # ∫_{−1}^{z} (1−|u|) du
    if z <= -1:
        return Fraction(0)
    if z < 0:
        return Fraction(1, 2) + z + z * z / 2    # (z+1)^2 / 2
    if z <= 1:
        return Fraction(1, 2) + z - z * z / 2
    return Fraction(1)


assert tri_cdf(1) == 1
assert tri_cdf(0) == Fraction(1, 2)
assert tri_cdf(Fraction(1, 2)) - tri_cdf(Fraction(1, 4)) == Fraction(5, 32)
print("triangle density piecewise CDF: normalized, P[1/4,1/2]=5/32: OK")


# Simpson 数值复核三角形归一
def simpson(f, a, b, n):
    h = (b - a) / n
    s = f(a) + f(b)
    for i in range(1, n):
        s += (4 if i % 2 else 2) * f(a + i * h)
    return s * h / 3


tri = lambda z: 1 - abs(z) if abs(z) <= 1 else 0.0
assert abs(simpson(tri, -1, 1, 2000) - 1) < 1e-9
print("triangle density Simpson integral = 1: OK")

# ④ 换元例：X ~ U[0,2]，Y = X²。fY(y) = 1/(4√y)，E[Y] = 4/3 双路
#    （换元空间 ∫ y·(1/4)y^{-1/2} dy vs 原空间 E[X²]）
fY_mean = simpson(lambda y: y * 0.25 * y ** -0.5 if y > 0 else 0.0,
                  1e-9, 4.0, 4000)
assert abs(fY_mean - 4 / 3) < 1e-4
assert Fraction(1, 2) * Fraction(8, 3) == Fraction(4, 3)   # ∫₀² x²/2 dx
print("Y=X^2: E[Y]=4/3 via transformed density AND via E[X^2]: OK")

# ⑤ 指数商：fZ(z) = 1/(1+z)²（z ≥ 0）解析账
#    有限区间 Simpson 对拍闭式 1 − 1/(1+A)；A → ∞ 归一 = 1；
#    P(Z ≤ 1) = 1/2（中位数 = 1）
A = 1000
assert abs(simpson(lambda z: 1 / (1 + z) ** 2, 0, A, 40000)
           - (1 - 1 / (1 + A))) < 1e-6
assert abs(simpson(lambda z: 1 / (1 + z) ** 2, 0, 1, 2000) - 0.5) < 1e-9
print("exponential ratio 1/(1+z)^2: closed form 1-1/(1+A), P(Z<=1)=1/2: OK")

print("END ====")
