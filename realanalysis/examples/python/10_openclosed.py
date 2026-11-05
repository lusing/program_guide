# 第 10 章 闭集和开集：Python 通道。
# 用分数核对无限交、无限并、闭包端点和相对闭集。
# 运行：python -I 10_openclosed.py
from fractions import Fraction

print("==== 10 open closed ====")


def survives(x):
    return all(-Fraction(1, n) < x < Fraction(1, n) for n in range(1, 41))


sample = [Fraction(k, 10) for k in range(-20, 21)]
alive = [x for x in sample if survives(x)]
assert alive == [Fraction(0)]
assert not survives(Fraction(1, 10))
print("nested open intervals keep only 0 from the tenths")


def in_union(x):
    return any(0 <= x <= 2 - Fraction(1, n) for n in range(1, 41))


assert not in_union(2)
assert in_union(0)
assert in_union(Fraction(3, 2))
print("union of [0, 2-1/n] reaches 3/2 and stops short of 2")

seq = [3 - Fraction(1, n) for n in range(1, 21)]
assert all(-3 < x < 3 for x in seq)
assert abs(seq[-1] - 3) < Fraction(1, 10)
print("3-1/n in (-3,3) approaches the closure endpoint 3")


def in_Y(x):
    return 0 <= x < 2


def in_E(x):
    return 1 <= x < 2


assert in_Y(Fraction(3, 2)) and in_E(Fraction(3, 2))
assert not in_Y(2) and not in_E(2)
assert in_Y(Fraction(1, 2)) and not in_E(Fraction(1, 2))
print("[1, 2) sits in [0, 2); the point 2 is outside the subspace")

pts = [Fraction(k, 5) for k in range(-14, 15)]
assert max(pts) < 3
print("a finite sample of (-3,3) stays strictly below the supremum 3")

print("END ====")
