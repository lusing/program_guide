# 第 19 章 级数：Python 通道。
# 1 + 1/2 + 1/4 = 7/4 = (1 - 1/8)/(1/2)。
# (2/3)/(1 - 2/3) = 2。
# 调和前四项大于 2；把 1/3 换成 1/4 之后等于 2。
# 常数 1 并不小于 1/2。
# 运行：python -I 19_series.py

from fractions import Fraction

print("==== 19 series ====")

partial = Fraction(1) + Fraction(1, 2) + Fraction(1, 4)
closed = (Fraction(1) - Fraction(1, 8)) / Fraction(1, 2)
assert partial == Fraction(7, 4)
assert closed == partial
print("1 + 1/2 + 1/4 equals 7/4, and so does the closed form")

assert Fraction(2, 3) / (1 - Fraction(2, 3)) == 2
print("(2/3) / (1 - 2/3) equals 2")

group = Fraction(1) + Fraction(1, 2) + Fraction(1, 4) + Fraction(1, 4)
harmonic = Fraction(1) + Fraction(1, 2) + Fraction(1, 3) + Fraction(1, 4)
assert group == 2
assert harmonic > group
print("replacing 1/3 by 1/4 gives 2; the harmonic head is larger")

assert abs(Fraction(1)) > Fraction(1, 2)
print("the constant term 1 is not below 1/2")

print("END ====")
