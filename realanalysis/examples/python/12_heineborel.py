# 第 12 章 海涅-博雷尔定理：Python 通道。
# 闭区间套的公共点、对分后的长度、有界样本落进格子、1/n 靠近 0。
# 运行：python -I 12_heineborel.py
from fractions import Fraction

print("==== 12 heine borel ====")


def in_nested(x, n):
    return 0 <= x <= 1 + Fraction(1, n + 1)


assert all(in_nested(0, n) for n in range(20))
assert all(in_nested(1, n) for n in range(20))
print("0 and 1 lie in every [0, 1+1/(n+1)]")


def bisect_len(n):
    return Fraction(4, 2**n)


assert bisect_len(6) < Fraction(1, 10)
print("after 6 bisections, length 4/64 < 1/10")


def in_cell(x):
    return Fraction(-3) <= x <= 3


sample = [Fraction(k) for k in (-3, -1, 0, 2, 3)]
assert all(in_cell(x) for x in sample)
assert not in_cell(4)
print("bounded sample sits in [-3,3]; 4 does not")


seq = [Fraction(1, n) for n in range(1, 21)]
assert all(0 < x <= 1 for x in seq)
assert seq[-1] < Fraction(1, 10)
print("1/n stays in (0,1] and the 20th term is < 1/10")

print("END ====")
