# -*- coding: utf-8 -*-
print("==== 03 conditional")
# 第 03 章 Python：条件概率与 Bayes 的精确分数账（Fraction）。
# ① 医学检验（每步中间量）；② Monty Hall 的全条件化；
# ③ 25 点有限表上的双向条件概率；④ 乘法链的无放回抽牌账。
from fractions import Fraction

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

# ③ 25 个等可能样本点的条件概率：P(A)=15/25，P(B)=7/25，P(A∩B)=5/25
p_A = Fraction(15, 25)
p_B = Fraction(7, 25)
p_AB = Fraction(5, 25)
assert p_AB / p_B == Fraction(5, 7)
assert p_AB / p_A == Fraction(1, 3)
print("finite table: P(A|B)=5/7 and P(B|A)=1/3: OK")

# ④ 乘法链：无放回抽两张牌都是 A
p_two_aces = Fraction(4, 52) * Fraction(3, 51)
assert p_two_aces == Fraction(1, 221)
print("multiplication chain: P(two aces) = 4/52 * 3/51 = 1/221: OK")

print("END ====")
