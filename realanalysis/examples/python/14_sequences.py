# 第 14 章 序列与收敛：Python 通道。
# 1/n 的 ε-N、平方越界、交错项到 1 的距离、常数序列的值域。
# 运行：python -I 14_sequences.py
from fractions import Fraction

print("==== 14 sequences ====")

def s(n):
    return Fraction(1, n)

eps = Fraction(1, 10)
assert s(11) < eps
assert s(10) == eps
print("1/11 < 1/10; N = 11 works for epsilon = 1/10")

assert 20 * 20 > 100
print("20^2 = 400 escapes the bound 100")

def alt(n):
    sign = 1 if n % 2 == 0 else -1
    return 1 + Fraction(sign, n)

assert abs(alt(11) - 1) == Fraction(1, 11)
assert abs(alt(11) - 1) < eps
print("alternating distance to 1 equals 1/n")

vals = [1, 1, 1]
assert len(set(vals)) == 1
print("constant sequence has range {1}")

def ends(n):
    sign = 1 if n % 2 == 0 else -1
    return sign + Fraction(sign, n)

assert abs(ends(2) - ends(3)) > 2
print("consecutive terms of the two-endpoint sequence stay more than 2 apart")

print("END ====")
