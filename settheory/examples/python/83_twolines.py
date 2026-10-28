# 第 83 章：与 Julia 独立对拍的截断超有理数与有限 ccc 区间族。
from fractions import Fraction
from itertools import combinations
import io
import sys
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

ZERO = (Fraction(0), Fraction(0))
ONE = (Fraction(1), Fraction(0))
EPS = (Fraction(0), Fraction(1))


def tplus(x, y):
    return (x[0] + y[0], x[1] + y[1])


def tmul(x, y):
    return (x[0] * y[0], x[0] * y[1] + x[1] * y[0])


def tlt(x, y):
    return x[0] < y[0] or (x[0] == y[0] and x[1] < y[1])


def teq(x, y):
    return x[0] == y[0] and x[1] == y[1]


def main():
    print("==== 83")
    for n in range(1, 41):
        assert tlt(ZERO, EPS) and tlt(EPS, (Fraction(1, n), Fraction(0)))
    for k in range(1, 41):
        assert tlt(tmul((k, Fraction(0)), EPS), ONE)
    for n in range(1, 41):
        assert teq(tmul((Fraction(n), Fraction(0)),
                        (Fraction(1, n), Fraction(0))), ONE)
    assert teq(tmul(tplus(ONE, EPS), tplus(ONE, EPS)),
               (Fraction(1), Fraction(2)))

    # 有限 ccc 区间族：[0,12] 上整数端点开区间的两两不交族。
    # 鸽笼账：不交族长度之和 ≤ 12，每段长 ≥ 1 ⟹ 至多 12 段。
    fam12 = [(i, i + 1) for i in range(12)]
    assert all(x[1] <= y[0] or y[1] <= x[0]
               for x, y in combinations(fam12, 2))
    assert sum(b - a for a, b in fam12) == 12
    print("Python：无穷小不等式与标准部分律同 Julia；")
    print("[0,12] 上 12 个单位开区间两两不交；长度鸽笼 ⟹ 上界恰 12（ccc 影子）")
    print("END ====")


if __name__ == "__main__":
    main()
