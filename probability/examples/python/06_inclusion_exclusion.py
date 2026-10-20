# -*- coding: utf-8 -*-
print("==== 06 inclusion_exclusion")
# 第 06 章 Python：容斥与错排的精确分数账（Fraction）。
# ① 错排闭式 vs 递推双向对拍；② D_n/n! → 1/e 的收敛界；
# ③ 三事件容斥（骰子空间 36 点）；④ 篮子问题 n=3、k=4 的
#    容斥值 vs 3^4 = 81 全枚举（终审法庭）。
from fractions import Fraction
from math import comb, factorial
from itertools import product


def der_closed(n):
    """错排闭式：D_n = n! * sum (-1)^k / k!（精确分数）。"""
    return factorial(n) * sum(Fraction((-1) ** k, factorial(k))
                              for k in range(n + 1))


def der_rec(n):
    """错排递推：D_n = n D_{n-1} + (-1)^n。"""
    d = 0                                    # D_0 = 1? 用 D_1 = 0 起步
    d = 1 if n == 0 else 0
    for i in range(2, n + 1):
        d = i * d + (-1) ** i
    return d if n != 0 else 1


# ① 双向对拍（n = 2..10）+ 整数性
for n in range(2, 11):
    c, r = der_closed(n), der_rec(n)
    assert c == r and c.denominator == 1, n
assert [der_closed(n) for n in range(0, 8)] == [1, 0, 1, 2, 9, 44, 265, 1854]
print("derangements D_0..D_7 = [1,0,1,2,9,44,265,1854] (closed = recurrence): OK")

# ② 收敛：|D_n/n! - 1/e| < 1/(n+1)!（交错级数余项的数值形态）
E = 2.71828182845904523536
for n in (4, 6, 8, 10):
    q = der_closed(n) / factorial(n)
    assert abs(float(q) - 1 / E) < 1 / factorial(n + 1)
print("D_n/n! -> 1/e with alternating-series remainder < 1/(n+1)!: OK")

# ③ 三事件容斥：骰子空间 A=首6、B=次6、C=两骰同点
OMEGA = list(product(range(1, 7), repeat=2))
P = lambda E: Fraction(sum(1 for w in OMEGA if E(w)), 36)
A = lambda w: w[0] == 6
B = lambda w: w[1] == 6
C = lambda w: w[0] == w[1]
union = P(lambda w: A(w) or B(w) or C(w))
in_ex = (P(A) + P(B) + P(C)
         - P(lambda w: A(w) and B(w)) - P(lambda w: A(w) and C(w))
         - P(lambda w: B(w) and C(w)) + P(lambda w: A(w) and B(w) and C(w)))
assert union == in_ex == Fraction(16, 36)
print("3-event inclusion-exclusion on dice: both sides = 16/36: OK")

# ④ 篮子问题：n=3 篮、k=4 球，全非空 = 容斥 vs 81 全枚举
n, k = 3, 4
ie = sum((-1) ** j * comb(n, j) * Fraction(n - j, n) ** k
         for j in range(n + 1))
enum = sum(1 for tup in product(range(n), repeat=k) if len(set(tup)) == n)
assert ie == Fraction(enum, n ** k) == Fraction(36, 81)
print("balls-to-bins n=3,k=4: IE = 36/81 = full enumeration: OK")

print("END ====")
