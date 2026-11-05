# 第 18 章 特殊序列：Python 通道。
# 1/121 < 1/10，并且 1/121 < 1/11。
# (1/2)^10 = 1/1024 < 1/100。
# (3/2)^2 = 9/4 > 2 = 1 + 2*(1/2)。
# 运行：python -I 18_special.py

from fractions import Fraction

print("==== 18 squeeze ====")

gap = Fraction(1, 121)
bound = Fraction(1, 10)
harmonic = Fraction(1, 11)
assert gap < bound
print("1/121 is below 1/10")

assert 0 < gap < harmonic
print("1/121 sits strictly between 0 and 1/11")

half_ten = Fraction(1, 2) ** 10
assert half_ten == Fraction(1, 1024)
assert half_ten < Fraction(1, 100)
print("(1/2)^10 is 1/1024, below 1/100")

step = Fraction(3, 2) ** 2
assert step == Fraction(9, 4)
assert 1 + 2 * Fraction(1, 2) < step
print("(3/2)^2 is 9/4, above 1 + 2*(1/2)")

print("END ====")
