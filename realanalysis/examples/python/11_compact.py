# 第 11 章 紧集：Python 通道。
# 有限子覆盖、开区间漏点、非紧嵌套区间的无限交。
# 运行：python -I 11_compact.py
from fractions import Fraction

print("==== 11 compact ====")


def in_subcover(x):
    return (-4 < x < 0) or (-1 < x < 3) or (2 < x < 6)


grid = [Fraction(k, 2) for k in range(-6, 7)]
assert all(in_subcover(x) for x in grid)
print("[-3,3] by halves sits in (-4,0) U (-1,3) U (2,6)")


def escapes(n):
    x = Fraction(1, 2 * n)
    return 0 < x < 1 and not (Fraction(1, n) < x)


assert all(escapes(n) for n in range(1, 21))
print("1/(2N) is in (0,1) and left of (1/N, 1-1/N)")


def in_all_open(x):
    return all(0 < x < Fraction(1, n) for n in range(1, 41))


sample = [Fraction(k, 20) for k in range(0, 21)]
assert all(not in_all_open(x) for x in sample)
print("no sample point lies in every (0, 1/n)")


def finite_inter(k):
    return 0 < Fraction(1, 2 * k) < Fraction(1, k)


assert all(finite_inter(k) for k in range(1, 21))
print("each finite intersection (0, 1/k) still holds 1/(2k)")

print("END ====")
