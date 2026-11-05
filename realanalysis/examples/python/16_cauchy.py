# 第 16 章 柯西序列与单调序列：Python 通道。
# 尾部两项的距离、三点集与区间的跨度、递减的倒数、递增地靠近 1。
# 运行：python -I 16_cauchy.py
from fractions import Fraction

print("==== 16 cauchy ====")

gap = abs(Fraction(1, 11) - Fraction(1, 12))
assert gap < Fraction(1, 10)
print("terms 11 and 12 of 1/n are less than 1/10 apart")

assert abs(3 - 1) == 2
print("the farthest points of {1,2,3} are 2 apart")

assert abs(3 - (-3)) == 6
print("the ends of [-3,3] are 6 apart")

trunc = abs(Fraction(141, 100) - Fraction(1414, 1000))
assert trunc < Fraction(1, 100)
print("two truncations of sqrt(2) differ by less than 1/100")

assert Fraction(1, 12) < Fraction(1, 11)
print("1/n decreases: 1/12 is smaller than 1/11")

left = 1 - Fraction(1, 11)
right = 1 - Fraction(1, 12)
assert left < right
assert abs(left - 1) == Fraction(1, 11)
print("1-1/11 is below 1-1/12, and it is 1/11 short of 1")

print("END ====")
