# 第 21 章 收官：Python 通道。
# 三个 1/3 加回 1；6 超过 5；两半加回 1；公比 1/2 的闭式是 2。
# 运行：python -I 21_wrapup.py

from fractions import Fraction

print("==== 21 roadmap ====")

assert Fraction(1, 3) + Fraction(1, 3) + Fraction(1, 3) == 1
print("three thirds make 1")

assert 6 > 5
print("6 is past 5")

assert Fraction(1, 2) + Fraction(1, 2) == 1
print("two halves make 1")

assert 1 / (1 - Fraction(1, 2)) == 2
print("geometric closed form is 2")

print("END ====")
