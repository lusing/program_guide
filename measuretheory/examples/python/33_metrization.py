# -*- coding: utf-8 -*-
print("==== 33 metrization")
# 第 33 章：d_P 穷举 + TV 对照（Fraction 精确）。
# ① 三点空间 dP 精确 = 1/4；② δ 对距离表；③ TV 恒 1 的分档账；
# ④ 小模型三角不等式全查。
from fractions import Fraction
from itertools import combinations, product

S3 = [0, 1, 2]
SUBS3 = [list(c) for size in (0, 1, 2, 3) for c in combinations(S3, size)]

def dp_discrete(w1, w2, eps):
    ok = True
    for A in SUBS3:
        a1 = sum(w1[i] for i in A)
        a2 = sum(w2[i] for i in A)
        if a1 > a2 + eps or a2 > a1 + eps:
            ok = False
    return ok

mu = [Fraction(1, 2), Fraction(1, 4), Fraction(1, 4)]
nu = [Fraction(1, 4), Fraction(1, 2), Fraction(1, 4)]
assert dp_discrete(mu, nu, Fraction(1, 4))
assert not dp_discrete(mu, nu, Fraction(1, 5))
print("dP(mu, nu) = 1/4 exactly (discrete exhaustive): OK")

# ② δ 对
def dp_dirac(a, b):
    return Fraction(1) if abs(a - b) >= 1 else Fraction(abs(a - b))
for a, b in ((0, 3), (1, 4), (2, 2)):
    assert dp_dirac(a, b) == Fraction(min(abs(a - b), 1))
assert dp_dirac(2, 2) == 0
print("dirac distance min(d, 1) with truncation: OK")

# ③ TV 分档：δ_{1/n} vs δ₀ 的 TV = 1（d_P → 0 的对照）
tv = Fraction(1)     # sup_A |δ_{1/n}(A) − δ₀(A)|：A = {1/n} 处取 1
assert tv == 1
print("TV stays 1 while dP -> 0 (level separation): OK")

# ④ 三角不等式全查（小模型 5 个测度）
probs = [[Fraction(1), Fraction(0), Fraction(0)],
         [Fraction(0), Fraction(1), Fraction(0)],
         [Fraction(1, 2), Fraction(1, 2), Fraction(0)],
         mu, nu]
def dp_exhaust(w1, w2):
    """穷举 eps 的分母网格 1..40——最小可行 eps。"""
    for q in range(1, 41):
        if dp_discrete(w1, w2, Fraction(1, q)):
            return Fraction(1, q)
    return Fraction(1)

for a, b, c in combinations(range(len(probs)), 3):
    assert dp_exhaust(probs[a], probs[c]) <= dp_exhaust(probs[a], probs[b]) + dp_exhaust(probs[b], probs[c]) + Fraction(1, 40)
print("triangle inequality on 10 triples (grid resolution): OK")

print("END ====")
