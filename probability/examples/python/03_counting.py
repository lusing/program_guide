# -*- coding: utf-8 -*-
print("==== 03 counting")
# 第 03 章 Python：阶乘与二项系数的精确账（Fraction）。
# ① Pascal 递推表 vs 直接公式逐格对拍；② 二项定理恒等式；
# ③ 顺序/无序的倍数账（陷阱一的数字形态）。
from fractions import Fraction
from math import comb, factorial

# ① Pascal 递推表填充 vs C(n,k) 公式（n ≤ 15 全表）
N = 15
pascal = [[0] * (N + 1) for _ in range(N + 1)]
for n in range(N + 1):
    pascal[n][0] = 1
    for k in range(1, n + 1):
        pascal[n][k] = pascal[n - 1][k - 1] + pascal[n - 1][k]
for n in range(N + 1):
    for k in range(n + 1):
        assert pascal[n][k] == comb(n, k), (n, k)
print("Pascal table matches formula C(n,k) for n<=15: OK")

# 阶乘的自检与 0! = 1
assert factorial(0) == 1
assert [factorial(n) for n in range(7)] == [1, 1, 2, 6, 24, 120, 720]

# ② 二项定理：(x+y)^8 的展开 vs Σ C(8,k) x^k y^(8-k)（x=2,y=3）
x, y = Fraction(2), Fraction(3)
lhs = (x + y) ** 8
rhs = sum(Fraction(comb(8, k)) * x ** k * y ** (8 - k) for k in range(9))
assert lhs == rhs == Fraction(5 ** 8)
print("binomial theorem (x=2,y=3,n=8): both sides = 5^8 = 390625: OK")

# 子集总数：Σ C(n,k) = 2^n（n = 12）
assert sum(comb(12, k) for k in range(13)) == 2 ** 12
# 交错和 = 0（偶 = 奇）
assert sum((-1) ** k * comb(12, k) for k in range(13)) == 0
print("sum C(12,k) = 2^12 and alternating sum = 0: OK")

# ③ 顺序账：3 岗位（有序 10·9·8）vs 3 委员（无序 C(10,3)）
ordered = 10 * 9 * 8
unordered = comb(10, 3)
assert ordered == 6 * unordered          # 3! 倍——先算多再除重
print("order matters: 10*9*8 = 6 * C(10,3) (3! de-duplication): OK")

# 陷阱一的硬币账：3 抛恰 2 正 = C(3,2)/8 = 3/8（精确分数）
p = Fraction(comb(3, 2), 8)
assert p == Fraction(3, 8)
print("3 coins exactly-2-heads = 3/8 exact: OK")

print("END ====")
