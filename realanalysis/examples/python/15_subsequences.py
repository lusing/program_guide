# 第 15 章 极限与子序列：Python 通道。
# 和、数乘、积、倒数的误差，以及 (-1)^n 的偶、奇子序列。
# 运行：python -I 15_subsequences.py
from fractions import Fraction

print("==== 15 subsequences ====")

a = Fraction(1, 11)
assert (a + 1) - 1 == a
print("adding 1 moves the term by exactly 1/11 from the limit 1")

assert abs(3 * a) < Fraction(3, 10)
print("three times 1/11 stays under 3/10")

p = (1 + Fraction(1, 10)) * (2 + Fraction(1, 10))
assert abs(p - 2) < Fraction(1, 2)
print("product at n=10 is within 1/2 of 2")

inv = 1 / (1 + Fraction(1, 10))
assert abs(inv - 1) == Fraction(1, 11)
print("reciprocal of 1+1/10 is 10/11, distance 1/11")

def alt(n):
    return 1 if n % 2 == 0 else -1

assert alt(2) == alt(4) == alt(6) == 1
assert alt(1) == alt(3) == alt(5) == -1
assert 2 < 4 < 6
print("even subsequence is constantly 1; odd subsequence is constantly -1")

assert 3 - 3 == 0
print("the second coordinate of (1/n, 3) is already at 3")

print("END ====")
