# 第 01 章 · 数学归纳法与良序 —— Python 通道
#
# 精确有理数（fractions.Fraction）上的 AM-GM + 最小反例搜索 + 卡西尼。

from fractions import Fraction
from math import isqrt, prod


def first_counterexample(bad, N):
    """最小反例搜索：良序原则的可执行版。"""
    for n in range(1, N + 1):
        if bad(n):
            return n
    return None


def am_gm_gap(xs):
    """(算术平均)ⁿ − Πxᵢ：精确有理数，≥ 0，等号 ⟺ 全相等。"""
    n = len(xs)
    lhs = Fraction(sum(xs), n) ** n
    rhs = prod(xs)
    return lhs - rhs


def isprime(n: int) -> bool:
    if n < 2:
        return False
    p = 2
    while p * p <= n:
        if n % p == 0:
            return False
        p += 1 if p == 2 else 2
    return True


print("==== 01 数学归纳法与良序")

# 欧拉多项式：n = 0..40 全素，41 处爆炸
hit = first_counterexample(lambda n: not isprime(n * n - n + 41), 100)
assert hit == 41, hit
print(f"欧拉多项式 n²−n+41：第一个反例 n = {hit}（f(41) = 41² = {41*41}）")

# 谢尔宾斯基：991n²+1 非平方——前 10⁶ 无反例（isqrt 精确判别）
hit2 = first_counterexample(
    lambda n: isqrt(991 * n * n + 1) ** 2 == 991 * n * n + 1, 10**6)
assert hit2 is None
print("谢尔宾斯基 991n²+1：前 10⁶ 个 n 内无平方数（真反例 ~1.2×10²⁸）")

# AM-GM（定理 1.11）：严格不等与取等两个分支
gap = am_gm_gap([Fraction(1), Fraction(2), Fraction(4), Fraction(8)])
assert gap > 0
assert am_gm_gap([Fraction(3, 7)] * 5) == 0
print(f"AM-GM：(1,2,4,8) 严格（gap = {gap} > 0）；全相等组取等 ✓")

# 2ⁿ > n² 恰从 5 开始
assert 2**1 > 1 and 2**2 == 4 and 2**3 < 9 and 2**4 == 16
for n in range(5, 30):
    assert 2**n > n * n
print("2ⁿ 与 n²：n = 2, 4 相等；n = 3 反向；n ≥ 5 严格大于 ✓")

# n = 2^k · m（m 奇）的存在唯一性抽查
def split_pow2(n):
    k = 0
    while n % 2 == 0:
        n //= 2
        k += 1
    return k, n

for n in range(1, 2000):
    k, m = split_pow2(n)
    assert n == 2**k * m and m % 2 == 1
print("n = 2^k · m（m 奇）：n < 2000 全部可分且 m 为奇 ✓")

# 卡西尼恒等式（BigInt 无压力）
def fib(n):
    a, b = 0, 1
    for _ in range(n):
        a, b = b, a + b
    return a

for n in range(1, 400):
    lhs = fib(n - 1) * fib(n + 1) - fib(n) ** 2
    assert lhs == (1 if n % 2 == 0 else -1)
print("卡西尼恒等式：n ≤ 400 全部成立 ✓")

print("END ====")
