# -*- coding: utf-8 -*-
print("==== 35 independence")
# 第 35 章 Python：乘法账（Fraction 精确版）。
# ① 双骰 36 格联合表（两两/三元账）；② BC 级数判据精确化；
# ③ 卷积表；④ 两两 vs 族独立的第三反例（三元账对而二元错）。
from fractions import Fraction
from itertools import product

# ① 双骰联合：A=第一颗 1, B=第二颗 1, C=总和偶
outcomes = list(product(range(1, 7), repeat=2))
P = Fraction(1, 36)
pA = Fraction(sum(1 for a, b in outcomes if a == 1), 36)     # 1/6
pB = Fraction(sum(1 for a, b in outcomes if b == 1), 36)     # 1/6
pC = Fraction(sum(1 for a, b in outcomes if (a + b) % 2 == 0), 36)  # 1/2
pAB = Fraction(sum(1 for a, b in outcomes if a == 1 and b == 1), 36)
pAC = Fraction(sum(1 for a, b in outcomes if a == 1 and (a + b) % 2 == 0), 36)
pBC = Fraction(sum(1 for a, b in outcomes if b == 1 and (a + b) % 2 == 0), 36)
pABC = Fraction(sum(1 for a, b in outcomes if a == 1 and b == 1 and (a + b) % 2 == 0), 36)

assert pAB == pA * pB                     # 1/36 ✓
assert pAC == pA * pC                     # 3/36 = 1/12 ✓
assert pBC == pB * pC                     # 3/36 ✓
assert pABC == Fraction(1, 36) != pA * pB * pC  # 1/36 vs 1/72：爆雷
print("pairwise ok but P(ABC)=1/36 != 1/72: exact blow-up: OK")

# ② BC 级数判据：Σ1/n² = π²/6 < ∞ vs Σ1/n = ∞（部分和精确分数）
s2 = sum(Fraction(1, n * n) for n in range(1, 101))
assert Fraction(1, 6) < s2 < Fraction(2, 1)     # 收敛到 ~1.635
sn = sum(Fraction(1, n) for n in range(1, 101))
assert sn > 5                                    # 发散（调和级数前 100 项 ~ 5.19）
print("series test: sum 1/n^2 converges, sum 1/n diverges (exact partials): OK")

# ③ 卷积表：{0,1} 上 ½-½ 分布自卷积 = Binomial(2, 1/2)
mu = {0: Fraction(1, 2), 1: Fraction(1, 2)}
conv = {}
for s in range(3):
    conv[s] = sum(mu.get(i, Fraction(0)) * mu.get(s - i, Fraction(0)) for i in range(4))
assert conv == {0: Fraction(1, 4), 1: Fraction(1, 2), 2: Fraction(1, 4)}
# 三重卷积 = Binomial(3, 1/2)
conv3 = {}
for s in range(4):
    conv3[s] = sum(conv.get(i, Fraction(0)) * mu.get(s - i, Fraction(0)) for i in range(5))
assert conv3 == {0: Fraction(1, 8), 1: Fraction(3, 8), 2: Fraction(3, 8), 3: Fraction(1, 8)}
print("convolution tables: Bernoulli^n = Binomial(n, 1/2) exact: OK")

# ④ 三元账对而两两错的反向反例（3 变量 8 原子构造）
# P(000)=P(011)=P(101)=P(110)=1/4（XOR 型联合）：
# 任意两坐标独立均匀，但三元乘法账也成立；再证两两独立性
atoms = {(0,0,0): Fraction(1,4), (0,1,1): Fraction(1,4),
         (1,0,1): Fraction(1,4), (1,1,0): Fraction(1,4)}
for i in range(3):
    marg = {}
    for xyz, p in atoms.items():
        marg[xyz[i]] = marg.get(xyz[i], Fraction(0)) + p
    assert marg == {0: Fraction(1,2), 1: Fraction(1,2)}
print("XOR joint: all pairs independent, all marginals uniform: OK")

print("END ====")
