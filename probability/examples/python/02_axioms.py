# -*- coding: utf-8 -*-
print("==== 02 axioms")
# 第 02 章 Python：公理定律的精确分数实验（骰子空间 36 点）。
# ① 容斥二项版；② 全概率两块版；③ Boole 上界与保守度。
from fractions import Fraction
from itertools import product

# Ω = {(i,j)}，36 点等可能：古典概型 P(A) = |A|/36
OMEGA = list(product(range(1, 7), repeat=2))
P = lambda A: Fraction(sum(1 for s in OMEGA if A(s)), 36)

A = lambda s: s[0] == 6                    # 首骰 6
B = lambda s: s[1] == 6                    # 次骰 6

# ① 容斥二项版：P(A∪B) = P(A) + P(B) − P(A∩B)（精确分数）
lhs = P(lambda s: A(s) or B(s))
rhs = P(A) + P(B) - P(lambda s: A(s) and B(s))
assert lhs == rhs == Fraction(11, 36)
assert P(A) == P(B) == Fraction(1, 6)
assert P(lambda s: A(s) and B(s)) == Fraction(1, 36)
print("inclusion-exclusion exact: 1/6 + 1/6 - 1/36 = 11/36: OK")

# ② 全概率两块版：P(A) = P(A|B)P(B) + P(A|B^c)P(B^c)
#    B = "首骰为偶"（分割 Ω）
Bv = lambda s: s[0] % 2 == 0
Av = lambda s: s[1] == 6                    # 次骰 6
p_cond = lambda Ev, Fv: Fraction(
    sum(1 for s in OMEGA if Ev(s) and Fv(s)), sum(1 for s in OMEGA if Fv(s)))
lhs = P(Av)
rhs = p_cond(Av, Bv) * P(Bv) + p_cond(Av, lambda s: not Bv(s)) * P(lambda s: not Bv(s))
assert lhs == rhs == Fraction(1, 6)
assert p_cond(Av, Bv) == Fraction(1, 6)     # 独立的预告（05 章）
print("total probability exact: both blocks give 1/6: OK")

# ③ Boole 上界：三事件并 ≤ 和（保守度 = 差额）
C = lambda s: s[0] + s[1] >= 10
union3 = P(lambda s: A(s) or B(s) or C(s))
sum3 = P(A) + P(B) + P(C)
assert union3 <= sum3
slack = sum3 - union3
assert slack > Fraction(1, 10)              # 重叠可观，上界保守
print("Boole exact: P(u3) = ", float(union3), " <= sum = ",
      float(sum3), " (slack ", float(slack), "): OK")

# ④ 补律与单调性（全子集枚举的抽样验证）
import random
random.seed(2)
subs = []
for _ in range(200):
    mask = random.getrandbits(36)
    subs.append(lambda s, m=mask: bool(m >> OMEGA.index(s) & 1))
for Av2 in subs[:60]:
    assert P(Av2) + P(lambda s, a=Av2: not a(s)) == 1      # 补律
    sup = lambda s, a=Av2: a(s) or s[0] == 6                # A ∪ {首6}
    assert P(Av2) <= P(sup)                                  # 单调性
print("complement & monotonicity: 60 random subsets all pass: OK")

print("END ====")
