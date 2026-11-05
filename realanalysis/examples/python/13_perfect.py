# 第 13 章 完备集与连通集：Python 通道。
# 康托尔集前两步、小区间长度，以及带缺口的并集。
# 运行：python -I 13_perfect.py
from fractions import Fraction

print("==== 13 perfect ====")


def in_e1(x):
    return (0 <= x <= Fraction(1, 3)) or (Fraction(2, 3) <= x <= 1)


def in_e2(x):
    pieces = [
        (0, Fraction(1, 9)),
        (Fraction(2, 9), Fraction(3, 9)),
        (Fraction(6, 9), Fraction(7, 9)),
        (Fraction(8, 9), 1),
    ]
    return any(a <= x <= b for a, b in pieces)


assert in_e1(0) and in_e1(Fraction(1, 4)) and in_e1(1)
assert not in_e1(Fraction(1, 2))
assert in_e2(Fraction(1, 4))
assert not in_e2(Fraction(1, 2))
print("0, 1/4, 1 stay in E1; 1/2 is removed; 1/4 still in E2")

assert Fraction(1, 2) > Fraction(1, 9)
assert 2**2 == 4
print("E2 has 4 pieces of length 1/9, shorter than 1/2")


def in_gap(x):
    return (-3 <= x < 0) or (0 < x <= 3)


assert in_gap(-1) and in_gap(1) and not in_gap(0)
print("-1 and 1 are in [-3,0) U (0,3]; 0 is not")

print("END ====")
