# 第 08 章 可数性：Python 通道。
# 交错枚举、对角线逃逸、约分有理数列举。
# 运行：python -I 08_countability.py
from fractions import Fraction
from math import gcd

print("==== 08 countability ====")


def zig(n):
    return n // 2 if n % 2 == 0 else -((n + 1) // 2)


def unzig(z):
    return 2 * z if z >= 0 else -2 * z - 1


assert [zig(n) for n in range(6)] == [0, -1, 1, -2, 2, -3]
assert all(zig(unzig(z)) == z for z in range(-20, 21))
assert all(unzig(zig(n)) == n for n in range(41))
print("zigzag bijection on sample: 0,-1,1,-2,2,-3,...")


def diagonal(rows):
    return [1 if rows[i][i] == 0 else 0 for i in range(len(rows))]


rows = [
    [0, 1, 0, 1],
    [1, 1, 0, 0],
    [0, 0, 0, 1],
    [1, 0, 1, 1],
]
s = diagonal(rows)
assert all(s[i] != rows[i][i] for i in range(4))
print("diagonal escape differs on the diagonal")


def rationals(limit):
    out = []
    s = 1
    while len(out) < limit:
        for b in range(1, s + 1):
            a = s - b
            if gcd(a, b) == 1:
                out.append(Fraction(a, b))
                if a != 0:
                    out.append(Fraction(-a, b))
        s += 1
    return out[:limit]


qs = rationals(12)
assert len(set(qs)) == len(qs)
assert Fraction(0, 1) in qs and Fraction(1, 2) in qs and Fraction(-1, 1) in qs
print("first reduced rationals are unique, include 0, -1, 1/2")

print("END ====")
