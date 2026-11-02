# -*- coding: utf-8 -*-
print("==== 07 counting_lab")
# 第 07 章 Python：生日、扑克、桥牌与秘书问题的精确计数实验室。
from fractions import Fraction
from itertools import combinations, permutations, product
from math import comb

# ① 生日问题：忽略闰年，365 个生日等可能且相互独立。
def birthday_collision(k):
    no_collision = Fraction(1)
    for j in range(k):
        no_collision *= Fraction(365 - j, 365)
    return 1 - no_collision

p22, p23, p24 = map(birthday_collision, (22, 23, 24))
assert p22 < Fraction(1, 2) < p23 and p24 > p23
assert comb(52, 5) == 2_598_960
print(f"birthday: p22={float(p22):.6f}, p23={float(p23):.6f}; 23 crosses 1/2: OK")
print(f"birthday pair-average C(23,2)/365={comb(23, 2)/365:.6f} is not collision probability: OK")

# ② 52 张牌发 5 张：九类互斥牌型，公式账本必须恰好分成 C(52,5)。
TOTAL = comb(52, 5)
poker_counts = {
    "straight_flush": 10 * 4,
    "four_kind": 13 * 48,
    "full_house": 13 * 4 * 12 * comb(4, 2),
    "flush": 4 * (comb(13, 5) - 10),
    "straight": 10 * (4**5 - 4),
    "three_kind": 13 * 4 * comb(12, 2) * 4**2,
    "two_pair": comb(13, 2) * comb(4, 2) ** 2 * 11 * 4,
    "pair": 13 * comb(4, 2) * comb(12, 3) * 4**3,
    "nothing": (comb(13, 5) - 10) * (4**5 - 4),
}
expected_poker = {
    "straight_flush": 40,
    "four_kind": 624,
    "full_house": 3744,
    "flush": 5108,
    "straight": 10200,
    "three_kind": 54912,
    "two_pair": 123552,
    "pair": 1098240,
    "nothing": 1302540,
}
assert poker_counts == expected_poker
assert sum(poker_counts.values()) == TOTAL
print("nine poker categories partition all C(52,5)=2598960 hands: OK")

# ③ 迷你扑克：5 个点数 × 4 个花色 = 20 张，发 3 张，全枚举 C(20,3)=1140。
def rank_of(card):
    return card % 5

def suit_of(card):
    return card // 5

def classify_mini(hand):
    ranks = sorted(rank_of(c) for c in hand)
    suits = [suit_of(c) for c in hand]
    flush = len(set(suits)) == 1
    straight = ranks[1] == ranks[0] + 1 and ranks[2] == ranks[1] + 1
    if flush and straight:
        return "straight_flush"
    if ranks[0] == ranks[1] == ranks[2]:
        return "three_kind"
    if flush:
        return "flush"
    if straight:
        return "straight"
    if ranks[0] == ranks[1] or ranks[1] == ranks[2]:
        return "pair"
    return "nothing"

mini_counts = {name: 0 for name in
               ("straight_flush", "three_kind", "flush", "straight", "pair", "nothing")}
for hand in combinations(range(20), 3):
    mini_counts[classify_mini(hand)] += 1
assert mini_counts == {
    "straight_flush": 12,
    "three_kind": 20,
    "flush": 28,
    "straight": 180,
    "pair": 480,
    "nothing": 420,
}
assert sum(mini_counts.values()) == comb(20, 3) == 1140
print("mini-poker exhaustive C(20,3)=1140: all six category counts match formulas: OK")

# ④ 桥牌：13 张手牌的花色空缺与 4-4-3-2 分布。
bridge_total = comb(52, 13)
fixed_void = Fraction(comb(39, 13), bridge_total)
any_void = Fraction(
    sum((-1) ** (j + 1) * comb(4, j) * comb(52 - 13 * j, 13)
        for j in range(1, 4)),
    bridge_total,
)
pattern_4432_count = 12 * comb(13, 4) ** 2 * comb(13, 3) * comb(13, 2)
pattern_4432 = Fraction(pattern_4432_count, bridge_total)
assert 0.010 < float(fixed_void) < 0.014
assert fixed_void < float(any_void) < 0.060
assert 0.20 < float(pattern_4432) < 0.23
print("bridge fixed void, inclusion-exclusion any-void, and 4-4-3-2 checked: OK")

# Yarborough：13 张牌全部低于 10 点。
yarborough = Fraction(comb(32, 13), bridge_total)
assert 1820 < 1 / float(yarborough) < 1840
print("Yarborough odds are about 1 to 1828: OK")

# ⑤ 秘书问题 n=4：拒绝前 k 个作为样本，再选择第一个超过样本最大值者。
def secretary_wins(k, perm):
    if k == 0:
        return perm[0] == 4
    threshold = max(perm[:k])
    for value in perm[k:]:
        if value > threshold:
            return value == 4
    return False

secretary_counts = [
    sum(secretary_wins(k, p) for p in permutations(range(1, 5)))
    for k in range(4)
]
assert secretary_counts == [6, 11, 10, 6]
secretary_probs = [Fraction(c, 24) for c in secretary_counts]
assert secretary_probs[1] == Fraction(11, 24)
closed_k1 = Fraction(1, 4) * sum((Fraction(1, m) for m in range(1, 4)), Fraction(0))
assert closed_k1 == Fraction(11, 24)
print("secretary n=4 exhaustive win counts [6,11,10,6]; k=1 gives 11/24: OK")

print("END ====")
