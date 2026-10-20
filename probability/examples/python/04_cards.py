# -*- coding: utf-8 -*-
print("==== 04 cards")
# 第 04 章 Python：扑克牌型账本的精确全表（Fraction）。
# ① 九型手数与概率；② 分母守恒（和 = C(52,5)）；
# ③ Yarborough 与单花色 void 的账。
from fractions import Fraction
from math import comb

C = lambda n, k: comb(n, k)

TOTAL = C(52, 5)

counts = {
    "straight_flush": 10 * 4,
    "four_kind": 13 * 48,
    "full_house": 13 * 4 * 12 * 6,
    "flush": 4 * (C(13, 5) - 10),
    "straight": 10 * (4 ** 5 - 4),
    "three_kind": 13 * 4 * C(12, 2) * 4 ** 2,
    "two_pair": C(13, 2) * 6 * 6 * 11 * 4,
    "pair": 13 * 6 * C(12, 3) * 4 ** 3,
    "nothing": (C(13, 5) - 10) * (4 ** 5 - 4),
}

# 教材数值对账（Miller 表 3.1）
expected = {
    "straight_flush": 40, "four_kind": 624, "full_house": 3744,
    "flush": 5108, "straight": 10200, "three_kind": 54912,
    "two_pair": 123552, "pair": 1098240, "nothing": 1302540,
}
for k in counts:
    assert counts[k] == expected[k], k
assert sum(counts.values()) == TOTAL == 2598960
print("nine hand counts match textbook, sum = C(52,5) = 2598960: OK")

# 概率表（精确分数）
probs = {k: Fraction(v, TOTAL) for k, v in counts.items()}
assert probs["pair"] == Fraction(1098240, 2598960)
assert float(probs["nothing"]) > 0.50            # 一半的手无型
assert float(probs["pair"] + probs["nothing"]) > 0.92
print("probabilities: nothing 50.1%, pair 42.3%, together > 92%: OK")

# ③ Yarborough：13 张全 < 10 点
yar = Fraction(C(32, 13), C(52, 13))
assert 1820 < 1 / yar < 1840                     # ≈ 1/1828
print("Yarborough: C(32,13)/C(52,13) ~ 1/", round(1 / yar), "(th 1/1828): OK")

# 单花色 void（指定玩家、指定花色）
void1 = Fraction(C(39, 13), C(52, 13))
assert 0.010 < float(void1) < 0.014              # ≈ 1.28%
print("single-suit void: C(39,13)/C(52,13) = ",
      round(float(void1), 4), "(th 0.0128): OK")

# 三条结构的细账：13·C(4,3)·C(12,2)·4^2 逐步核对
assert 13 * C(4, 3) * C(12, 2) * 4 ** 2 == 54912
print("three-kind decomposition 13*C(4,3)*C(12,2)*4^2 = 54912: OK")

print("END ====")
