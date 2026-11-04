# 第 00 章 导言：Python 通道。
# 数学实数（fractions.Fraction 精确分数）与机器浮点（float 近似）对照，
# 以及 √2 无理性的有限证据。运行：python -I 00_intro.py
from fractions import Fraction
import math

print("==== 00 intro ====")

# --- 1. 浮点不是数学实数 -----------------------------------------
print("float: 0.1 + 0.2 =", 0.1 + 0.2)
assert 0.1 + 0.2 != 0.3
print("float epsilon =", math.ulp(1.0), " (gap between adjacent floats)")

# Fraction 是精确有理数：1/3 连加三次严格等于 1。
r = Fraction(1, 3)
assert r + r + r == 1
print("Fraction: 1/3 + 1/3 + 1/3 =", r + r + r)

# decimal 可以提高十进制精度，但仍然是有限精度，不是数学实数。
from decimal import Decimal, getcontext
getcontext().prec = 50
print("Decimal(50) sqrt2 approx =", Decimal(2).sqrt())

# --- 2. √2 无理性的有限证据 --------------------------------------
# 完整证明在 Lean/Isabelle/Coq 通道；这里用整数算术扫描
# m,n ≤ 5000，核验不存在 m^2 = 2 n^2 的整数解。
def search_pythagoras(limit):
    for n in range(1, limit + 1):
        m = round(math.sqrt(2) * n)
        for cand in (m - 1, m, m + 1):
            if cand > 0 and cand * cand == 2 * n * n:
                return cand, n
    return None

assert search_pythagoras(5000) is None
print("integer scan up to 5000: no m^2 = 2n^2 (consistent with irrationality)")

# 高精度有理逼近仍然严格不等于 √2。
approx = Fraction(665857, 470832)
assert approx * approx != 2
print("665857/470832 squared minus 2 =", approx * approx - 2)

# --- 3. Archimedean 性质的可计算版本 ------------------------------
def archimedean(x):
    n = math.floor(x) + 1
    assert n > x
    return n

print("archimedean(10^6) =", archimedean(10 ** 6))
print("archimedean(-3.7) =", archimedean(-3.7))

print("END ====")
