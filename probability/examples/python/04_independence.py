# -*- coding: utf-8 -*-
"""第 04 章：独立性、两两独立、条件独立与零相关。

所有有限概率均用 Fraction 精确表示；穷举只验证这些有限模型，
不把频率模拟冒充为一般证明。
"""
from fractions import Fraction
from itertools import product


def empirical(predicate, space, weights=None):
    """在带权有限空间中计算谓词事件的精确概率。"""
    if weights is None:
        weights = {omega: Fraction(1, len(space)) for omega in space}
    return sum(weights[omega] for omega in space if predicate(omega))


def intersection_prob(pred_a, pred_b, space, weights=None):
    return empirical(lambda omega: pred_a(omega) and pred_b(omega),
                     space, weights)


print("==== 04 independence")

# ① 两个公平 Bernoulli 变量：边际独立的四点标准模型
coin_space = list(product([0, 1], repeat=2))
first_heads = lambda xy: xy[0] == 1
second_heads = lambda xy: xy[1] == 1
pa = empirical(first_heads, coin_space)
pb = empirical(second_heads, coin_space)
pab = intersection_prob(first_heads, second_heads, coin_space)
assert (pa, pb, pab) == (Fraction(1, 2), Fraction(1, 2), Fraction(1, 4))
assert pab == pa * pb
both_tails = lambda xy: xy == (0, 0)
assert intersection_prob(first_heads, both_tails, coin_space) == 0
assert 0 != pa * empirical(both_tails, coin_space)
print("two fair coins: P(A and B)=P(A)P(B); positive disjoint events are dependent: OK")

# ② 洪书 9 点反例：两两独立但不相互独立
nine_points = [
    "aaa", "bbb", "ccc",
    "abc", "bca", "cba",
    "acb", "bac", "cab",
]
assert len(nine_points) == 9

def at(position, symbol):
    return lambda word: word[position] == symbol

A1, A2, A3 = (at(i, "a") for i in range(3))
for event in (A1, A2, A3):
    assert empirical(event, nine_points) == Fraction(1, 3)
for left, right in ((A1, A2), (A1, A3), (A2, A3)):
    assert intersection_prob(left, right, nine_points) == Fraction(1, 9)
triple = empirical(lambda w: A1(w) and A2(w) and A3(w), nine_points)
assert triple == Fraction(1, 9)
assert triple != Fraction(1, 3) ** 3
print("nine-point example: pairwise products 1/9 hold, triple is 1/9 not 1/27: OK")

# ③ 条件独立但边际不独立：共同状态 C 使两个信号同涨同落
# 每个 (A,B,C) 给权重；C=0 时 p=1/5，C=1 时 p=4/5，C 自身公平。
mixture = []
for c, p in ((0, Fraction(1, 5)), (1, Fraction(4, 5))):
    for a in (0, 1):
        for b in (0, 1):
            weight = Fraction(1, 2) * (p if a else 1 - p) * (p if b else 1 - p)
            mixture.append(((a, b, c), weight))
mixture_weights = dict(mixture)
mixture_space = list(mixture_weights)

def conditional(predicate, given, space, weights):
    given_weight = empirical(given, space, weights)
    return empirical(lambda w: predicate(w) and given(w), space, weights) / given_weight

for c in (0, 1):
    given_c = lambda w, c=c: w[2] == c
    a_one = lambda w: w[0] == 1
    b_one = lambda w: w[1] == 1
    p_a_c = conditional(a_one, given_c, mixture_space, mixture_weights)
    p_b_c = conditional(b_one, given_c, mixture_space, mixture_weights)
    p_ab_c = conditional(lambda w: a_one(w) and b_one(w),
                         given_c, mixture_space, mixture_weights)
    assert p_ab_c == p_a_c * p_b_c

p_a = empirical(lambda w: w[0] == 1, mixture_space, mixture_weights)
p_b = empirical(lambda w: w[1] == 1, mixture_space, mixture_weights)
p_ab = empirical(lambda w: w[0] == 1 and w[1] == 1,
                 mixture_space, mixture_weights)
assert p_a == p_b == Fraction(1, 2)
assert p_ab == Fraction(17, 50)
assert p_ab != p_a * p_b
print("mixture model: A independent of B given C, but P(A=1,B=1)=17/50 != 1/4: OK")

# ④ 边际独立但给定对撞量 C=A xor B 后不独立
xor_space = list(product([0, 1], repeat=2))
xor_weights = {(a, b, a ^ b): Fraction(1, 4) for a, b in xor_space}
a_event = lambda w: w[0] == 1
b_event = lambda w: w[1] == 1
assert empirical(a_event, xor_weights, xor_weights) == Fraction(1, 2)
assert empirical(b_event, xor_weights, xor_weights) == Fraction(1, 2)
assert empirical(lambda w: a_event(w) and b_event(w), xor_weights,
                 xor_weights) == Fraction(1, 4)
given_xor1 = lambda w: w[2] == 1
p_a_given = conditional(a_event, given_xor1, xor_weights, xor_weights)
p_ab_given = conditional(lambda w: a_event(w) and b_event(w),
                         given_xor1, xor_weights, xor_weights)
assert p_a_given == Fraction(1, 2)
assert p_ab_given == 0
assert p_ab_given != p_a_given ** 2
print("XOR collider: A and B marginally independent, but dependent given C=1: OK")

# ⑤ 四点零相关但完全依赖：Y=X^2，X 等可能取 -2,-1,1,2
xs = (-2, -1, 1, 2)
mean_x = Fraction(sum(xs), len(xs))
mean_y = Fraction(sum(x * x for x in xs), len(xs))
cov = sum((x - mean_x) * (x * x - mean_y) for x in xs) / len(xs)
assert mean_x == 0
assert cov == 0
conditional_y4_given_x2 = Fraction(1)
marginal_y4 = Fraction(sum(1 for x in xs if x * x == 4), len(xs))
assert conditional_y4_given_x2 != marginal_y4
print("four-point X to X^2: covariance is exactly 0 but Y is determined by X: OK")

print("END ====")
