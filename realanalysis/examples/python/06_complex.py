# 第 06 章 复数与欧几里得空间：Python 通道。
# 复数按定义写成有序对 (a, b)，分量用 Fraction，零舍入；再与内置 complex 对照。
# 欧氏空间：内积、范数平方、Cauchy–Schwarz 与 Lagrange 恒等式。
# 运行：python -I 06_complex.py
from fractions import Fraction
from itertools import combinations
import math

print("==== 06 complex ====")

# --- 1. 复数 = 有序对 ---------------------------------------------------
def C(a, b):
    return (Fraction(a), Fraction(b))

def cmul(z, w):
    (a, b), (c, d) = z, w
    return (a * c - b * d, a * d + b * c)

def cconj(z):
    return (z[0], -z[1])

def cnorm2(z):
    return z[0] ** 2 + z[1] ** 2

def cinv(z):
    d = cnorm2(z)
    assert d != 0
    return (z[0] / d, -z[1] / d)

i = C(0, 1)
assert cmul(i, i) == C(-1, 0)
print("i * i = -1")

z, w = C(1, 2), C(3, 4)
assert cmul(z, w) == C(-5, 10)
print("(1+2i)(3+4i) = -5 + 10i")

assert cmul(z, cconj(z)) == C(cnorm2(z), 0)
print("z * conj(z) = |z|^2 = 5")

assert cmul(z, cinv(z)) == C(1, 0)
print("z * (1/z) = 1, 1/(1+2i) =", cinv(z))

assert cnorm2(C(3, 4)) == 25
print("|3+4i|^2 = 25, |3+4i| = 5")

# 内置 complex（浮点）在这些小整数上是精确的。
assert (1 + 2j) * (3 + 4j) == -5 + 10j
assert abs(3 + 4j) == 5.0
print("builtin complex agrees")

# --- 2. 欧几里得空间 R^n --------------------------------------------------
def dot(x, y):
    return sum(a * b for a, b in zip(x, y))

def n2(x):
    return dot(x, x)

x, y = [1, 2], [3, 4]
assert dot(x, y) == 11 and n2(x) == 5 and n2(y) == 25
assert dot(x, y) ** 2 <= n2(x) * n2(y)
assert n2(x) * n2(y) - dot(x, y) ** 2 == (1 * 4 - 2 * 3) ** 2
print("C-S in R^2: 121 <= 125, gap 4 = (1*4 - 2*3)^2")

def lagrange_gap(x, y):
    return sum((x[i] * y[j] - x[j] * y[i]) ** 2
               for i, j in combinations(range(len(x)), 2))

u = [3, -1, 4, 1, -5]
v = [2, 7, -1, 8, 2]
assert n2(u) * n2(v) - dot(u, v) ** 2 == lagrange_gap(u, v)
assert dot(u, v) ** 2 <= n2(u) * n2(v)
print(f"C-S in R^5: {dot(u, v) ** 2} <= {n2(u) * n2(v)}, gap = sum of squares")

s = [a + b for a, b in zip(u, v)]
assert math.sqrt(n2(s)) <= math.sqrt(n2(u)) + math.sqrt(n2(v))
print("triangle inequality holds in R^5")

print("END ====")
