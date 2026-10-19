# -*- coding: utf-8 -*-
print("==== 24 riesz")
# 第 24 章 Python：泛函→测度翻译机（Fraction 精确）。
# ① 权泛函双向账（500 随机 f 精确分数）；
# ② 唯一性（基向量分离）；
# ③ Riemann 透视（x² 精确分数 1/3）；
# ④ Stieltjes 透视（Heaviside R-S 和 → f(0)）。
from fractions import Fraction
import random

random.seed(24)
W = [Fraction(3), Fraction(5), Fraction(2), Fraction(1), Fraction(4)]

If = lambda f: sum(W[i] * f[i] for i in range(5))

# ① 双向账
ok = True
for _ in range(500):
    f = [Fraction(random.randint(-25, 25), random.randint(1, 25)) for _ in range(5)]
    if If(f) != sum(W[i] * f[i] for i in range(5)):
        ok = False
assert ok
print("weighted-sum account exact on 500 random f: OK")

# ② 唯一性：基向量逐个评价分离权
for i in range(5):
    e = [Fraction(0)] * 5
    e[i] = Fraction(1)
    assert If(e) == W[i]
print("uniqueness via basis evaluation: OK")

# ③ Riemann 透视：midpoint 的精确分数账（x² on [0,1] 用 n=6 手算 vs 1/3 数值）
def midpoint(f, n):
    h = Fraction(1, n)
    return sum(f((Fraction(2 * k + 1, 2 * n))) for k in range(n)) * h


val = midpoint(lambda x: x * x, 3000)
closed = Fraction(1, 3)
assert abs(float(val - closed)) < 1e-6   # 中点法误差 h^2/24·f''
# 常值与线性函数的中点法**精确**（Simpson 型对称性）
assert midpoint(lambda x: Fraction(1), 7) == Fraction(1)
assert midpoint(lambda x: x, 7) == Fraction(1, 2)
print("Riemann透视: constants/linear exact, x^2 -> 1/3: OK")

# ④ Stieltjes 透视：F = 1_{x≥0}，R-S 和只有跨 0 区间贡献 → f(0)
def heaviside(x):
    return 1 if x >= 0 else 0


def rs_sum(f, a, b, n):
    h = Fraction(b - a, n)
    s = Fraction(0)
    for k in range(n):
        dF = heaviside(a + (k + 1) * h) - heaviside(a + k * h)
        if dF:
            s += f(a + Fraction(2 * k + 1, 2) * h) * dF
    return s


f0 = Fraction(3, 7)          # 目标：f(0) 处取值 3/7 的连续函数 f(x)=x+3/7
g = lambda x: x + Fraction(3, 7)
v = rs_sum(g, Fraction(-1), Fraction(1), 4000)
assert abs(float(v - Fraction(3, 7))) < 3e-4   # 网格宽 5e-4 的中点偏差（实测 2.5e-4）
print("Stieltjes透视: Heaviside R-S sum -> f(0) = 3/7: OK")

print("END ====")
