# -*- coding: utf-8 -*-
print("==== 05 conditional")
# 第 05 章 Python：条件概率与 Bayes 的精确分数账（Fraction）。
# ① 医学检验（每步中间量）；② Monty Hall 的全条件化；
# ③ 两两独立 ≠ 相互独立（ε₁, ε₂, ε₁ε₂ 系统）；④ 乘法链
#    的抽牌账。
from fractions import Fraction
from itertools import product

# ① 医学检验：病率 1/1000、灵敏度 95%、假阳率 5%
prev = Fraction(1, 1000)
tp = Fraction(95, 100)
fp = Fraction(5, 100)
true_pos = tp * prev
false_pos = fp * (1 - prev)
evidence = true_pos + false_pos              # 全概率分母
post = true_pos / evidence
assert post == Fraction(19, 1018)            # ≈ 1.87%
assert false_pos / evidence == Fraction(999, 1018)
print("medical Bayes exact: P(sick|+) = 19/1018 = ",
      float(post), " (base-rate rescued): OK")

# ② Monty Hall 的三情况条件账（主持人知情、开 3 号门 H）
pC1 = pC2 = pC3 = Fraction(1, 3)
pH_C1 = Fraction(1, 2)                       # 车在 1：随便开 2/3
pH_C2 = Fraction(1)                          # 车在 2：必须开 3
pH_C3 = Fraction(0)                          # 车在 3：不能开 3
pH = pH_C1 * pC1 + pH_C2 * pC2 + pH_C3 * pC3
post2 = (pH_C2 * pC2) / pH
assert pH == Fraction(1, 2)
assert post2 == Fraction(2, 3)
print("Monty Hall exact: P(car-2 | open-3) = 2/3 via 3-case conditioning: OK")

# ③ 两两独立 ≠ 相互独立：ε₁, ε₂ iid 公平硬币位，
#    A = {ε₁=1}、B = {ε₂=1}、C = {ε₁ε₂=1}（异或取反）
#    每个事件概率 1/2，每对独立，但 P(A∩B∩C) = 0 ≠ 1/8
omega = list(product([0, 1], repeat=2))
P = lambda E: Fraction(sum(1 for w in omega if E(w)), 4)
A = lambda w: w[0] == 1
B = lambda w: w[1] == 1
C = lambda w: w[0] == w[1]                   # 两 bit 相同（含 (0,0)）
assert P(A) == P(B) == P(C) == Fraction(1, 2)
for X, Y in ((A, B), (A, C), (B, C)):
    assert P(lambda w, x=X, y=Y: x(w) and y(w)) == Fraction(1, 4)  # 两两独立
assert P(lambda w: A(w) and B(w) and C(w)) == Fraction(1, 4)        # ≠ 1/8
print("pairwise-independent but NOT mutual: P(ABC) = 1/4 != 1/8: OK")

# ④ 乘法链：无放回抽两张牌都是 A
p_two_aces = Fraction(4, 52) * Fraction(3, 51)
assert p_two_aces == Fraction(1, 221)
print("multiplication chain: P(two aces) = 4/52 * 3/51 = 1/221: OK")

print("END ====")
