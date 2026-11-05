# 第 05 章 实数域（下）：Python 通道。
# 精确有理数上的二分法（完备性的算法形态）与有理数稠密性的构造验证。
# 运行：python -I 05_completeness.py
from fractions import Fraction
import math

print("==== 05 completeness ====")

# --- 1. 二分法：区间套逼近 √2 ------------------------------------------
def bisect_sqrt2(k):
    a, b = Fraction(1), Fraction(2)
    for _ in range(k):
        assert a * a < 2 <= b * b
        m = (a + b) / 2
        if m * m < 2:
            a = m
        else:
            b = m
    return a, b

a40, b40 = bisect_sqrt2(40)
assert b40 - a40 == Fraction(1, 2 ** 40)
print("after 40 bisections: gap = 2^-40")
print("  a =", float(a40), " a^2 =", float(a40 * a40))

# --- 2. 步数-精度关系：每步减半（Archimedean 的算法版） ----------------
for k in (10, 20, 40, 60):
    a, b = bisect_sqrt2(k)
    assert b - a == Fraction(1, 2 ** k)
print("gap = 2^-k verified at k = 10,20,40,60")

# --- 3. 有理数稠密的构造证明（计算版） ----------------------------------
def rational_between(x, y):
    """给定浮点 x < y，返回严格夹在中间的有理数（Fraction）。"""
    assert x < y
    n = math.ceil(2 / (y - x))      # 1/n < (y-x)/2
    m = math.floor(x * n) + 1       # m-1 <= nx < m
    r = Fraction(m, n)
    assert x < r < y
    return r

r = rational_between(1.4142135, 1.4142136)
print("rational between 1.4142135 and 1.4142136:", r)

# --- 4. Archimedean：给定正有理 x、任意 y，找 n 使 n*x > y ----------
def arch_witness(x, y):
    assert x > 0
    n = int(y / x) + 1
    assert n * x > y
    return n

assert arch_witness(Fraction(1, 3), Fraction(10)) == 31
print("archimedean witness for x=1/3, y=10: n =", arch_witness(Fraction(1, 3), 10))

# --- 5. 推论 5.7 的影子：q + √2 型无理点夹在两有理数之间 -------------
# 取 q = floor(a) 合适时，a < q + √2 < b（这里用有理逼近核对）。
a, b = Fraction(2), Fraction(3)
# √2 ≈ 1393/985（第 03 章 q-迭代），则 0 + 1393/985 ∈ (0,2) 不够；
# 用 1 + 7/5 = 12/5 = 2.4 ∈ (2,3)，并断言它不是“显然有理的中点”。
p = Fraction(12, 5)
assert a < p < b
print("sample point between 2 and 3:", p)

print("END ====")
