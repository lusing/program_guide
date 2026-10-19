# -*- coding: utf-8 -*-
print("==== 19 kernels")
# 第 19 章：转移核的精确账（Fraction 版）。
# ① 一步/两步分布（矩阵乘法精确分数）；
# ② Chapman-Kolmogorov 四分量恒等式；
# ③ 平稳分布 π = (4/7, 3/7) 精确解 + 迭代逼近误差的整数账；
# ④ 核版 Fubini：离散 μ、K 上的精确双重和。
from fractions import Fraction

P = [[Fraction(7, 10), Fraction(3, 10)],
     [Fraction(2, 5), Fraction(3, 5)]]
mu0 = [Fraction(1), Fraction(0)]


def mv(v, M):
    return [sum(v[i] * M[i][j] for i in range(2)) for j in range(2)]


def matmul(A, B):
    return [[sum(A[i][k] * B[k][j] for k in range(2)) for j in range(2)]
            for i in range(2)]


# ① 一步 / 两步
mu1 = mv(mu0, P)
assert mu1 == [Fraction(7, 10), Fraction(3, 10)]
mu2 = mv(mu1, P)
assert mu2 == [Fraction(61, 100), Fraction(39, 100)]
print("one-step (7/10,3/10), two-step (61/100,39/100): exact OK")

# ② Chapman-Kolmogorov 逐分量
P2 = matmul(P, P)
for i in range(2):
    for j in range(2):
        ck = sum(P[i][k] * P[k][j] for k in range(2))
        assert P2[i][j] == ck
assert P2 == [[Fraction(61, 100), Fraction(39, 100)],
              [Fraction(13, 25), Fraction(12, 25)]]
print("Chapman-Kolmogorov: (P*P)[i][j] == sum_k P[i][k]P[k][j]: OK")

# ③ 平稳分布：πP = π ⟹ π = (4/7, 3/7)（精确）
# (7/10-1)π1 + (2/5)π2 = 0 ⟹ π2 = (3/4)·(10/4)π1? 手解：3/10 π1 = 2/5 π2? 用方程
# π1 P11 + π2 P21 = π1 ⟹ (7/10)π1 + (2/5)π2 = π1 ⟹ (2/5)π2 = (3/10)π1 ⟹ π2 = (3/4)π1
# 归一：π1(1 + 3/4) = 1 ⟹ π1 = 4/7, π2 = 3/7
pi_stat = [Fraction(4, 7), Fraction(3, 7)]
assert mv(pi_stat, P) == pi_stat
mun = mu0
for n in range(1, 25):
    mun = mv(mun, P)
    # 误差账：μₙ(1) − 4/7 = (3/7)·(3/10)ⁿ（显式公式，整数账精确核对）
    err = mun[0] - Fraction(4, 7)
    exact = Fraction(3, 7) * Fraction(3, 10) ** n
    assert err == exact
print("stationary (4/7,3/7); error = (3/7)(3/10)^n exact for n=1..24: OK")

# ④ 核版 Fubini：μ 在 {0,1}，K(x,·) 在 {0,1,2}——逐 x 报价再平均
mu = [Fraction(1, 3), Fraction(2, 3)]
K = {0: [Fraction(1, 2), Fraction(1, 2), Fraction(0)],
     1: [Fraction(0), Fraction(1, 4), Fraction(3, 4)]}


def f(x, y):
    return Fraction(x + 1, y + 1)


lhs = sum(mu[x] * sum(K[x][y] * f(x, y) for y in range(3)) for x in range(2))
rhs_direct = sum(c * f(x, y) for x in range(2) for y in range(3)
                 for c in [mu[x] * K[x][y]])
# 手账：x=0 侧 (1/3)·(1/2·1 + 1/2·1/2) = 1/4；x=1 侧 (2/3)·(1/4·1 + 3/4·2/3) = 1/2
assert lhs == rhs_direct == Fraction(1, 3) * (
    Fraction(1, 2) * 1 + Fraction(1, 2) * Fraction(1, 2)) + Fraction(2, 3) * (
    Fraction(1, 4) * 1 + Fraction(3, 4) * Fraction(2, 3))
assert lhs == Fraction(3, 4)
print("kernel Fubini: iterated == double sum == 3/4 (exact): OK")

print("END ====")
