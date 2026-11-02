# -*- coding: utf-8 -*-
print("==== 05 counting")
# 第 05 章 Python：阶乘与二项系数的精确账（Fraction）。
# ① Pascal 递推表 vs 直接公式逐格对拍；② 二项定理恒等式；
# ③ 顺序/无序的倍数账（陷阱一的数字形态）。
from fractions import Fraction
from math import comb, factorial

# ① Pascal 递推表填充 vs C(n,k) 公式（n ≤ 15 全表）
N = 15
pascal = [[0] * (N + 1) for _ in range(N + 1)]
for n in range(N + 1):
    pascal[n][0] = 1
    for k in range(1, n + 1):
        pascal[n][k] = pascal[n - 1][k - 1] + pascal[n - 1][k]
for n in range(N + 1):
    for k in range(n + 1):
        assert pascal[n][k] == comb(n, k), (n, k)
print("Pascal table matches formula C(n,k) for n<=15: OK")

# 阶乘的自检与 0! = 1
assert factorial(0) == 1
assert [factorial(n) for n in range(7)] == [1, 1, 2, 6, 24, 120, 720]

# ② 二项定理：(x+y)^8 的展开 vs Σ C(8,k) x^k y^(8-k)（x=2,y=3）
x, y = Fraction(2), Fraction(3)
lhs = (x + y) ** 8
rhs = sum(Fraction(comb(8, k)) * x ** k * y ** (8 - k) for k in range(9))
assert lhs == rhs == Fraction(5 ** 8)
print("binomial theorem (x=2,y=3,n=8): both sides = 5^8 = 390625: OK")

# 子集总数：Σ C(n,k) = 2^n（n = 12）
assert sum(comb(12, k) for k in range(13)) == 2 ** 12
# 交错和 = 0（偶 = 奇）
assert sum((-1) ** k * comb(12, k) for k in range(13)) == 0
print("sum C(12,k) = 2^12 and alternating sum = 0: OK")

# ③ 顺序账：3 岗位（有序 10·9·8）vs 3 委员（无序 C(10,3)）
ordered = 10 * 9 * 8
unordered = comb(10, 3)
assert ordered == 6 * unordered          # 3! 倍——先算多再除重
print("order matters: 10*9*8 = 6 * C(10,3) (3! de-duplication): OK")

# ④ 多项系数：把 5 个带标签位置分成大小 (3,1,1) 的三组。
def multinomial(n, groups):
    assert sum(groups) == n
    den = 1
    for g in groups:
        den *= factorial(g)
    return factorial(n) // den

assert multinomial(5, (3, 1, 1)) == 20
assert multinomial(11, (5, 3, 3)) == factorial(11) // (factorial(5) * factorial(3) ** 2)
print("multinomial coefficients 5!/(3!1!1!)=20 and 11!/(5!3!3!) checked: OK")

# 多项式定理：(x+y+z)^5 的系数表与直接幂相等。
def multinomial_power(n, values):
    total = Fraction(0)
    m = len(values)
    def recurse(pos, left, coef_den, power):
        nonlocal total
        if pos == m - 1:
            groups = tuple(power + [left])
            coef = Fraction(factorial(n), coef_den * factorial(left))
            term = coef
            for value, exponent in zip(values, groups):
                term *= Fraction(value) ** exponent
            total += term
            return
        for take in range(left + 1):
            recurse(pos + 1, left - take, coef_den * factorial(take),
                    power + [take])
    recurse(0, n, 1, [])
    return total

values = (Fraction(1, 2), Fraction(3), Fraction(-1))
assert multinomial_power(5, values) == (sum(values)) ** 5
print("multinomial theorem (x+y+z)^5 matches direct power: OK")

# 所有多项系数之和是类型数的 n 次幂：3^5 = 243。
assert sum(multinomial(5, (a, b, 5 - a - b))
           for a in range(6) for b in range(6 - a)) == 3 ** 5
print("sum of multinomial coefficients over a+b+c=5 is 3^5=243: OK")

# 星与条：x1+x2+x3=4 的非负整数解数为 C(6,4)=15。
stars = [(a, b, 4 - a - b) for a in range(5) for b in range(5 - a)]
assert len(stars) == comb(4 + 3 - 1, 4) == 15
print("stars-and-bars nonnegative solutions count C(6,4)=15: OK")

# 陷阱一的硬币账：3 抛恰 2 正 = C(3,2)/8 = 3/8（精确分数）
p = Fraction(comb(3, 2), 8)
assert p == Fraction(3, 8)
print("3 coins exactly-2-heads = 3/8 exact: OK")

print("END ====")
