# 第 80 章：Fraction 递归二分与负平方根区间（独立于 Julia while）。
from fractions import Fraction
import sys
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

ONE = Fraction(1)
TWO = Fraction(2)


def bisect_root(n, negative=False):
    lo, hi = (Fraction(-2), Fraction(-1)) if negative else (ONE, TWO)
    if n == 0:
        return lo, hi
    mid = (lo + hi) / 2
    inside = mid * mid < TWO
    if not negative:
        lo, hi = (mid, hi) if inside else (lo, mid)
    else:
        lo, hi = (lo, mid) if inside else (mid, hi)
    # 把新端点作为下一次递归的起点；用一个局部递归保持精确有理数。
    def continue_from(a, b, k):
        if k == 0:
            return a, b
        m = (a + b) / 2
        less = m * m < TWO
        if not negative:
            return continue_from(m if less else a, b if less else m, k - 1)
        return continue_from(a if less else m, m if less else b, k - 1)
    return continue_from(lo, hi, n - 1)


def main():
    print("==== 80")
    pos = bisect_root(40)
    neg = bisect_root(40, negative=True)
    assert bisect_root(3) == (Fraction(11, 8), Fraction(12, 8))
    assert bisect_root(3, True) == (Fraction(-12, 8), Fraction(-11, 8))
    assert pos[0] ** 2 < TWO <= pos[1] ** 2
    assert neg[0] ** 2 >= TWO > neg[1] ** 2
    assert pos[1] - pos[0] == Fraction(1, 2 ** 40)
    assert neg[1] - neg[0] == Fraction(1, 2 ** 40)
    print("Python Fraction 递归二分：正负 √2 均有 40 层精确包围区间")
    print("三步正区间 [11/8,12/8]，负区间 [-12/8,-11/8]；与 Agda 对账 ✓")
    print("END ====")


if __name__ == "__main__":
    main()
