# -*- coding: utf-8 -*-
print("==== 22 projective_limits")
# 第 22 章：投影极限的精确塔账（Fraction 版）。
# ① Cantor 塔：2^-n 精确账 + 截断映射 π_{n,m} 的显式实现；
# ② 协方差子块结构：min(s,t) 的 3×3 子块删行删列 = 2×2（相容性的代数原文）；
# ③ ℤ/2ⁿ 塔的 Haar 账：均匀分布的相容族（模 2^m 约减保持均匀）。
from fractions import Fraction
from itertools import product

# ① Cantor 塔：n 位花样账
for n in (2, 5, 10, 20):
    total = Fraction(0)
    for pattern in product((0, 1), repeat=n):
        total += Fraction(1, 2 ** n)
    assert total == 1
# 截断映射：π_{n,m}（保留前 m 位）把 n 位花样映到 m 位花样，每像原像恰 2^{n-m}
for n, m in ((4, 2), (6, 3), (8, 5)):
    from collections import Counter
    fiber = Counter()
    for pattern in product((0, 1), repeat=n):
        fiber[pattern[:m]] += 1
    assert set(fiber.values()) == {2 ** (n - m)}      # 均匀纤维
    assert len(fiber) == 2 ** m
print("Cantor tower: 2^-n account + uniform fibers of truncation maps: OK")

# ② 协方差子块：min(s,t)，S = {1,2,3} 删去 2 → {1,3} 的 2×2 子块
Sigma3 = [[Fraction(min(i, j)), ] * 1 for i in range(1) for j in range(1)]
Sigma3 = [[Fraction(min(i, j)) for j in (1, 2, 3)] for i in (1, 2, 3)]
keep = (0, 2)                                          # 保留坐标 1 与 3（0 基）
sub = [[Sigma3[i][j] for j in keep] for i in keep]
assert sub == [[Fraction(1), Fraction(1)], [Fraction(1), Fraction(3)]]
# 直接指定 {1,3} 的协方差（min(1,3) = 1, min(3,3) = 3）完全一致
assert sub[0][1] == sub[1][0] == Fraction(min(1, 3))
print("covariance subblock: deleting index 2 gives the {1,3}-window exactly: OK")

# ③ ℤ/2ⁿ 塔：mod 约减把均匀送到均匀（Haar 相容性）
for n, m in ((3, 1), (4, 2), (6, 3)):
    assert n > m
    counts = [0] * (2 ** m)
    for x in range(2 ** n):
        counts[x % (2 ** m)] += 1
    assert counts == [2 ** (n - m)] * (2 ** m)        # 每个像恰 2^{n-m} 个原像
    # 均匀分布的推出：每点 2^{n-m}/2^n = 2^{-m} —— Haar 账精确
    assert all(Fraction(c, 2 ** n) == Fraction(1, 2 ** m) for c in counts)
print("Z/2^n tower: mod reduction pushes uniform to uniform (Haar account): OK")

print("END ====")
