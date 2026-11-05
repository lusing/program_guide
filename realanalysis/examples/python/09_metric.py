# 第 09 章 拓扑定义：Python 通道。
# 距离三公理、开球、有界区间、端点作为极限点的数值影子。
# 运行：python -I 09_metric.py
from fractions import Fraction

print("==== 09 metric ====")


def d(p, q):
    return abs(p - q)


pts = [Fraction(x) for x in (-3, -1, 0, 1, 3)]
assert all(d(p, p) == 0 for p in pts)
assert all(d(p, q) == d(q, p) for p in pts for q in pts)
assert all(d(p, q) <= d(p, r) + d(r, q) for p in pts for q in pts for r in pts)
print("distance axioms on a sample")


def in_ball(x, center, radius):
    return d(center, x) < radius


assert in_ball(Fraction(29, 10), 0, 3)
assert not in_ball(3, 0, 3)
assert not in_ball(-3, 0, 3)
print("ball(0,3) contains 2.9, excludes the endpoints")

assert all(d(p, 0) <= 3 for p in pts)
print("[-3,3] is bounded by 0 and M=3")

seq = [3 - Fraction(1, n) for n in range(1, 21)]
assert all(-3 < x < 3 for x in seq)
assert abs(seq[-1] - 3) < Fraction(1, 10)
print("3-1/n in (-3,3) approaches the missing endpoint")

mid = (Fraction(-3) + Fraction(3)) / 2
assert -3 < mid < 3
print("midpoint of an interval lies strictly inside")

print("END ====")
