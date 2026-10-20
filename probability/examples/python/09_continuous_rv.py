# -*- coding: utf-8 -*-
print("==== 09 continuous_rv")
# 第 09 章 Python：连续随机变量的精确分数账。
# ① 多项式密度的归一（∫ 形状 = 11/6 → c = 6/11）与 CDF
#    逐点值；② 密度 2x 的全套账（归一/CDF/矩）；③ 均匀的
#    区间账（长度比）；④ Cauchy 形状 1/(1+x²) 的配平
#    （Simpson 数值积分 ∫₀¹ = π/4 → c = 1/π）；⑤ 混合型
#    CDF 的分段账。
from fractions import Fraction
from math import pi


def poly_integral(coeffs, a, b):
    """∫_a^b Σ c_i x^i dx（Fraction 精确；coeffs 低次在前）。"""
    prim = [Fraction(0)] + [c / (i + 1) for i, c in enumerate(coeffs)]

    def ev(cs, x):
        return sum(c * x ** i for i, c in enumerate(cs))

    return ev(prim, b) - ev(prim, a)


# ① 多项式密度：形状 2+3x-5x² 的配平与 CDF 表
shape = [Fraction(2), Fraction(3), Fraction(-5)]
A = poly_integral(shape, Fraction(0), Fraction(1))
assert A == Fraction(11, 6)
c = 1 / A
assert c == Fraction(6, 11)


def Fpoly(x):
    return c * poly_integral(shape, Fraction(0), x)


assert Fpoly(Fraction(1)) == 1
assert Fpoly(Fraction(1, 2)) == Fraction(7, 11)
assert Fpoly(Fraction(1, 4)) == Fraction(109, 352)
grid = {x: Fpoly(Fraction(x)) for x in (0, "1/4", "1/2", "3/4", 1)}
print("poly density: c=6/11, F(1/2)=7/11, F(1/4)=109/352: OK")

# ② 密度 f(x) = 2x 的全套账
twox = [Fraction(0), Fraction(2)]
assert poly_integral(twox, Fraction(0), Fraction(1)) == 1            # 天然归一
assert poly_integral(twox, Fraction(0), Fraction(1, 4)) == Fraction(1, 16)
mean2x = poly_integral([Fraction(0), Fraction(0), Fraction(2)],      # x·f = 2x²
                       Fraction(0), Fraction(1))
ex2_2x = poly_integral([Fraction(0), Fraction(0), Fraction(0), Fraction(2)],
                       Fraction(0), Fraction(1))                      # x²·f = 2x³
assert mean2x == Fraction(2, 3)
assert ex2_2x == Fraction(1, 2)
assert ex2_2x - mean2x ** 2 == Fraction(1, 18)
print("f=2x: normalized, P(X<=1/4)=1/16, mean=2/3, Var=1/18: OK")

# ③ 均匀 U[a,b]：区间概率 = 长度比


def unif_prob(a, b, lo, hi):
    return Fraction(hi - lo) / (b - a)


assert unif_prob(0, 1, Fraction(1, 4), Fraction(3, 4)) == Fraction(1, 2)
assert unif_prob(2, 6, 3, 5) == Fraction(1, 2)
assert unif_prob(2, 6, 2, 6) == 1
print("uniform interval probabilities as length ratios: OK")


# ④ Cauchy 形状：Simpson 数值积分 ∫₀¹ 1/(1+x²) = π/4 → c = 1/π
def simpson(f, a, b, n):
    h = (b - a) / n
    s = f(a) + f(b)
    for i in range(1, n):
        s += (4 if i % 2 else 2) * f(a + i * h)
    return s * h / 3


val = simpson(lambda x: 1 / (1 + x * x), 0.0, 1.0, 1000)
assert abs(val - pi / 4) < 1e-9
print("Cauchy shape: Simpson int_0^1 1/(1+x^2) = pi/4 -> c=1/pi: OK")

# ⑤ 混合型：1/2 质量在 0，1/2 均匀铺在 (0,1)——分段 CDF 账


def Fmix(x):
    if x < 0:
        return Fraction(0)
    if x == 0:
        return Fraction(1, 2)                       # 跳点：F(0) 含质量 1/2
    return Fraction(1, 2) + Fraction(1, 2) * Fraction(1) * x if x <= 1 else Fraction(1)


assert Fmix(-1) == 0 and Fmix(1) == 1
assert Fmix(0) == Fraction(1, 2)                    # 阶跃
assert Fmix(Fraction(1, 2)) == Fraction(3, 4)       # 斜坡段
print("mixed CDF: jump 1/2 at 0, ramp to 1: OK")

print("END ====")
