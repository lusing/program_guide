# -*- coding: utf-8 -*-
print("==== 07 combinatorics")
# 第 07 章 Python：枚举法与二项恒等式的精确分数账。
# ① 多项式定理 (x+y+z)^5 的系数表；② Vandermonde 两例；
# ③ hockey-stick；④ 平均子集大小 Σ k·C(n,k) = n·2^{n-1}。
from fractions import Fraction
from math import comb
from itertools import product

# ① 多项式系数：Σ_{a+b+c=5} 5!/(a!b!c!) x^a y^b z^c 与直接展开对拍
def multinomial_expansion(n, x, y, z):
    total = Fraction(0)
    for a in range(n + 1):
        for b in range(n + 1 - a):
            c = n - a - b
            coef = Fraction(factorial5(n), factorial5(a) * factorial5(b) * factorial5(c))
            total += coef * x ** a * y ** b * z ** c
    return total

def factorial5(n):
    r = 1
    for i in range(2, n + 1):
        r *= i
    return r

x, y, z = Fraction(1, 2), Fraction(3), Fraction(-1)
assert multinomial_expansion(5, x, y, z) == (x + y + z) ** 5
# 系数抽样：x^3 y z 的系数 = 5!/(3!1!1!) = 20
assert factorial5(5) // (factorial5(3) * factorial5(1) * factorial5(1)) == 20
print("multinomial (x+y+z)^5 expansion matches direct power: OK")

# ② Vandermonde：Σ C(m,j)C(n,k-j) = C(m+n,k)
for (m, n, k) in ((3, 2, 2), (5, 4, 3), (8, 7, 6)):
    lhs = sum(comb(m, j) * comb(n, k - j) for j in range(k + 1))
    assert lhs == comb(m + n, k), (m, n, k)
print("Vandermonde identity verified for (m,n,k) = (3,2,2),(5,4,3),(8,7,6): OK")

# ③ Hockey-stick：Σ_{i=r}^{n} C(i,r) = C(n+1,r+1)
for (r, n) in ((2, 10), (3, 15), (1, 20)):
    assert sum(comb(i, r) for i in range(r, n + 1)) == comb(n + 1, r + 1)
print("hockey-stick sums verified for (r,n) = (2,10),(3,15),(1,20): OK")

# ④ 平均子集大小：Σ k·C(n,k) = n·2^{n-1}
for n in (4, 10, 15):
    assert sum(k * comb(n, k) for k in range(n + 1)) == n * 2 ** (n - 1)
print("sum k*C(n,k) = n*2^(n-1) for n = 4,10,15: OK")

# ⑤ 记账序交换：C(n,k)C(k,j) = C(n,j)C(n-j,k-j)
for (n, k, j) in ((8, 5, 3), (10, 6, 2)):
    assert comb(n, k) * comb(k, j) == comb(n, j) * comb(n - j, k - j)
print("order-swap identity C(n,k)C(k,j) = C(n,j)C(n-j,k-j): OK")

print("END ====")
