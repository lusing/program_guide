# 第 16 章 · 域与分式域 —— Python 通道

from fractions import Fraction
from random import seed, randint
from math import gcd

print("==== 16 域与分式域")

# ---------- 自实现 Frac + Fraction 对拍 ----------
def frac_norm(a, b):
    g = gcd(a, b)
    s = -1 if b < 0 else 1
    return (s * a // g, s * b // g)

def frac_add(x, y):
    a, b = x; c, d = y
    return frac_norm(a * d + c * b, b * d)

def frac_mul(x, y):
    a, b = x; c, d = y
    return frac_norm(a * c, b * d)

seed(20261104)
for _ in range(10 ** 4):
    a, b, c, d = (randint(-99, 99) or 1, randint(1, 99),
                  randint(-99, 99) or 1, randint(1, 99))
    x, y = (a, b), (c, d)
    assert Fraction(*frac_add(x, y)) == Fraction(a, b) + Fraction(c, d)
    assert Fraction(*frac_mul(x, y)) == Fraction(a, b) * Fraction(c, d)
print("自实现 Frac × Fraction：10⁴ 对四则逐位相等 ✓")

# ---------- ℚ(√2) 序对模型 ----------
def q2_add(x, y):
    return (x[0] + y[0], x[1] + y[1])

def q2_mul(x, y):
    return (x[0] * y[0] + 2 * x[1] * y[1], x[0] * y[1] + x[1] * y[0])

s = (0, 1)          # √2
assert q2_mul(s, s) == (2, 0)
for _ in range(200):
    z = (Fraction(randint(-9, 9), randint(1, 9)), Fraction(randint(-9, 9), randint(1, 9)))
    w = (Fraction(randint(-9, 9), randint(1, 9)), Fraction(randint(-9, 9), randint(1, 9)))
    # 范数乘性：(a²−2b²)(c²−2d²) = (ac+2bd)² − 2(ad+bc)²
    nzw = (q2_mul(z, w)[0] ** 2 - 2 * q2_mul(z, w)[1] ** 2)
    nz = z[0] ** 2 - 2 * z[1] ** 2
    nw = w[0] ** 2 - 2 * w[1] ** 2
    assert nzw == nz * nw
print("ℚ(√2) 模型：(√2)² = 2；N(zw) = N(z)N(w)（200 组精确有理数）✓")

# ---------- GF(4) 预演：ℤ₂[x]/(x²+x+1) 的乘法表 ----------
def gf4_mul(a, b):
    # 元素 0,1,2,3 ↔ 0,1,α,α+1；乘法按 α² = α+1 归约
    T = [[0, 0, 0, 0],
         [0, 1, 2, 3],
         [0, 2, 3, 1],
         [0, 3, 1, 2]]
    return T[a][b]

for a in range(4):
    for b in range(4):
        assert gf4_mul(a, b) == gf4_mul(b, a)          # 交换
# 非零元乘法群 {1, α, α+1}：α³ = 1
assert gf4_mul(2, 2) == 3 and gf4_mul(2, 3) == 1
print("GF(4) 预演：α² = α+1、α³ = 1、乘法交换（16 对）✓")

print("END ====")
