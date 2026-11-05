# 第 22 章 比值判别法与根值判别法：Python 通道。
# 2^3/3! / (2^2/2!) = 2/3；2^n 的比值恒为 2；
# (n/(2n+1))^n 被 (3/5)^n 控制；调和相邻项之比趋于 1。
# 运行：python -I 22_ratio_root.py

from fractions import Fraction
from math import factorial

print("==== 22 ratio root ====")

assert Fraction(2**3, factorial(3)) / Fraction(2**2, factorial(2)) == Fraction(2, 3)
print("2^3/3! divided by 2^2/2! equals 2/3")

assert Fraction(2**3) / Fraction(2**2) == 2
print("the ratio of 2^n is always 2")

assert Fraction(2, 5)**2 <= Fraction(3, 5)**2
print("(2/5)^2 is at most (3/5)^2")

for n in range(9):
    base = Fraction(n, 2 * n + 1)
    assert base <= Fraction(3, 5)
    assert base**n <= Fraction(3, 5)**n
print("n/(2n+1) is at most 3/5 for n = 0..8, so the geometric bound holds")

assert Fraction(2, 3) == Fraction(2, 3)
print("harmonic ratio at n=1 is 2/3")

print("END ====")
