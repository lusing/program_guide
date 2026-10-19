# -*- coding: utf-8 -*-
print("==== 21 kolmogorov")
# 第 21 章：相容性检查器（Fraction 精确版）。
# ① 边缘投影 marg(P_S, keep) 的精确实现；
# ② 相容性谓词 consistent(family)：全窗口两两核对——正例（独立乘积、
#    核装配）通过、反例（传递断链）爆雷；
# ③ 马氏链三步装配的精确账。
from fractions import Fraction
from itertools import product

HALF = Fraction(1, 2)
QUARTER = Fraction(1, 4)


# 分布表：dict{assignment(tuple) -> Fraction}
def marginal(dist, keep):
    """把 dist 关于 keep 之外的坐标求和（精确分数）。"""
    out = {}
    for assign, p in dist.items():
        key = tuple(assign[k] for k in keep)
        out[key] = out.get(key, Fraction(0)) + p
    return out


# ① 独立乘积族：P_{12} = 均匀×均匀（两两独立）
P12_indep = {t: QUARTER for t in product((0, 1), repeat=2)}
m1 = marginal(P12_indep, (0,))
assert m1 == {(0,): HALF, (1,): HALF}
m2 = marginal(P12_indep, (1,))
assert m2 == {(0,): HALF, (1,): HALF}
print("marginal projection exact (indep family): OK")


# ② 相容性谓词
def consistent(family):
    """family: dict{frozenset(indices) -> dist}；dist 的 assignment 按
    sorted(window) 的变量顺序排列。枚举窗口对，核对共享边缘。"""
    windows = list(family.keys())
    for W1 in windows:
        for W2 in windows:
            shared_labels = tuple(sorted(W1 & W2))
            if not shared_labels:
                continue
            o1 = sorted(W1)
            o2 = sorted(W2)
            pos1 = tuple(o1.index(ℓ) for ℓ in shared_labels)
            pos2 = tuple(o2.index(ℓ) for ℓ in shared_labels)

            def marg(dist, pos):
                out = {}
                for assign, p in dist.items():
                    key = tuple(assign[i] for i in pos)
                    out[key] = out.get(key, Fraction(0)) + p
                return out

            if marg(family[W1], pos1) != marg(family[W2], pos2):
                return False, (o1, o2, shared_labels)
    return True, None


# 正例一：独立乘积族 {1,2} 与 {2,3}（边缘一致）
fam_ok = {frozenset({1, 2}): P12_indep, frozenset({2, 3}): P12_indep}
ok, _ = consistent(fam_ok)
assert ok
print("consistent family (independent products): passes: OK")

# 反例：{1,2} 完美相关 vs {1,3} 独立（共享 1-边缘一致，但配 {2,3} 后断链）
P_perfect = {(0, 0): HALF, (1, 1): HALF}
fam_bad = {frozenset({1, 2}): P_perfect,
           frozenset({2, 3}): P_perfect,
           frozenset({1, 3}): P12_indep}
ok2, witness = consistent(fam_bad)
# 共享单边缘：完美相关与独立在单坐标上同为均匀——pairwise 边缘全部一致！
# 但传递性断链：X1=X2=X3 ⟹ X1,X3 完全相关 ≠ 独立。
assert ok2  # 边缘层面检查器确实通过（说明 pairwise 边缘不充分）
# 全窗口装配检查：三个二元窗无法拼出三元联合——显式枚举 8 个原子
def assemble3(fam):
    cand = {}
    for a in product((0, 1), repeat=3):
        p = Fraction(1)  # 上确界装配（min of constraints = Fréchet）
        for W, dist in fam.items():
            idx = sorted(W)
            key = tuple(a[i - 1] for i in idx)
            p = min(p, dist.get(key, Fraction(0)))
        cand[a] = p
    return cand


cand = assemble3(fam_bad)
total = sum(cand.values())
# Fréchet 上界装配的总质量 < 1 ⟹ 不存在真正的联合分布
assert total < Fraction(1)
print("pairwise-consistent but NOT jointly realizable: Frechet total =", total, ": OK")

# ③ 马氏链装配（Fraction）：μ₁ ⊗ P ⊗ P 的 (2,3)-边缘 = μ₂ ⊗ P
P = [[Fraction(7, 10), Fraction(3, 10)], [Fraction(2, 5), Fraction(3, 5)]]
mu1 = [Fraction(7, 10), Fraction(3, 10)]
joint123 = {}
for x1 in (0, 1):
    for x2 in (0, 1):
        for x3 in (0, 1):
            joint123[(x1, x2, x3)] = mu1[x1] * P[x1][x2] * P[x2][x3]
m23 = marginal(joint123, (1, 2))            # (X2, X3) 边缘
mu2 = [sum(mu1[i] * P[i][j] for i in (0, 1)) for j in (0, 1)]
assert mu2 == [Fraction(61, 100), Fraction(39, 100)]
for x2 in (0, 1):
    for x3 in (0, 1):
        assert m23[(x2, x3)] == mu2[x2] * P[x2][x3]
assert sum(m23.values()) == 1
print("kernel assembly: (2,3)-marginal == mu2 (*) P (exact): OK")

print("END ====")
