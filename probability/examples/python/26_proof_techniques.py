# -*- coding: utf-8 -*-
print("==== 26 proof_techniques")
# 第 26 章 Python：证明十一式的机器审计。
# ① 归纳法机械审计（Σk、Σk²、二项定理逐 n 核对）；② 故事法
#    恒等式（Vandermonde、ΣkC 双路对拍）；③ 抽屉原理的生日账；
# ④ 加零配方核（恒等式数值全等）；⑤ 反例集合（X 与 X²）。
from fractions import Fraction
from math import comb
import random as _r

_r.seed(26)

# ① 归纳审计：对每个 n 验证（归纳步的机械影子）
for n in range(1, 50):
    assert sum(range(1, n + 1)) == n * (n + 1) // 2            # Σk
    assert sum(k * k for k in range(1, n + 1)) == n * (n + 1) * (2 * n + 1) // 6
    # 二项定理：数值代入
    for x, y in ((2, 3), (1, 5)):
        assert sum(comb(n, k) * x ** k * y ** (n - k) for k in range(n + 1)) == (x + y) ** n
print("induction audit: sum identities + binomial theorem for n=1..49: OK")

# ② 故事法：两路对拍
for m, n in ((3, 2), (5, 4), (7, 3)):
    k = 2
    lhs = sum(comb(m, j) * comb(n, k - j) for j in range(k + 1))
    assert lhs == comb(m + n, k)                               # Vandermonde
for n in (6, 8, 10):
    lhs = sum(k * comb(n, k) for k in range(n + 1))
    assert lhs == n * 2 ** (n - 1)                             # 子集总大小
    lhs2 = sum(k * k * comb(n, k) for k in range(n + 1))
    assert lhs2 == n * (n + 1) * 2 ** (n - 2)                  # 平方版
print("story proofs: vandermonde + subset-size identities: OK")

# ③ 抽屉原理的生日账（严格版容斥）
for people in (23, 50, 100):
    p_shared = 1.0
    for i in range(people):
        p_shared *= (365 - i) / 365
    p_collide = 1 - p_shared
    if people == 23:
        assert abs(p_collide - 0.507) < 5e-3
    # 鸽笼版下界（23 人 → 253 对，每对 1/365）
    pairs = people * (people - 1) // 2
    naive = pairs / 365
    assert p_collide <= min(naive, 1.0) + 1e-9                 # 容斥 ≤ 直和（Boole）
print("birthday: exact collision vs pigeonhole (Boole) bound: OK")

# ④ 加零配方：恒等式数值全等（配方 = 加 z²/4 − z²/4）
for z in (0.3, 1.7, -2.5):
    lhs = 2 * z * z - 2 * z * 3 + 9                            # 2(t² − 3t) + 9
    rhs = 2 * (z - 1.5) ** 2 + 9 - 2 * (1.5 ** 2 - 0)          # 配方后的形态
    rhs = 2 * (z - 1.5) ** 2 + 4.5                             # 化简
    assert abs(lhs - rhs) < 1e-10
# 方差捷径的恒等式（加零：X − μ = (X − x̄) + (x̄ − μ)）
xs = [_r.gauss(5, 2) for _ in range(100)]
xb = sum(xs) / len(xs)
lhs = sum((x - 5) ** 2 for x in xs)                            # Σ(x−μ)²
cross = 2 * (xb - 5) * sum(x - xb for x in xs)                 # 交叉项 = 0（加零的果实）
rhs = sum((x - xb) ** 2 for x in xs) + 100 * (xb - 5) ** 2
assert abs(cross) < 1e-8                                       # Σ(x−x̄) = 0
assert abs(lhs - rhs) < 1e-6
print("add-zero: completing square + variance identity numerically exact: OK")

# ⑤ 反例集合：X 均匀 {−2,−1,1,2}、Y = X²
xs5 = [-2, -1, 1, 2]
ys5 = [x * x for x in xs5]
ex = sum(xs5) / 4
exy = sum(x * y for x, y in zip(xs5, ys5)) / 4
assert ex == 0 and exy == 0                                    # Cov = 0 − 0·E[Y] = 0
ey = sum(ys5) / 4
ey2 = sum(y * y for y in ys5) / 4
assert ey == Fraction(5, 2) and ey2 - ey ** 2 == Fraction(9, 4)
# 但 Y 完全由 X 决定：反例成立
print("counterexample: cov(X, X^2) = 0 but Y = X^2 dependent: OK")

# 附：穷举法的验证器角色——验证 Σk³ = (Σk)²（Nicomachus）
for n in (5, 10, 20):
    assert sum(k ** 3 for k in range(1, n + 1)) == (n * (n + 1) // 2) ** 2
print("brute force as verifier: Nicomachus identity: OK")
print("END ====")
