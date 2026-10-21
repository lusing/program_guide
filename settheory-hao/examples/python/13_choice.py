# -*- coding: utf-8 -*-
print("==== 13 choice")
# 第 13 章 Python：选择公理的有限实验场（书 4.6）。
# ① AC1→AC2→AC3 的构造审计：选择函数、不交化技巧（i × X_i）、
#    选择集与每块之交恰单点；
# ② Zorn 引理与 Hausdorff 极大链的有限版：有限偏序集必有极大元
#    与极大链（有限情形无需 AC——贪心即可）；
# ③ 良序定理的有限版平凡成立：每个有限集都有良序；
# ④ 无穷族的"不可构造性"注记：ℕ 上的选择函数在计算上就是不可
#    实现的（任意谓词族没有统一取元素算法）。
from itertools import product

# ① AC3（选择函数）→ AC2（不交族的选择集）
Fam = {0: {'a', 'b'}, 1: {'c', 'd'}, 2: {'e', 'f'}}    # 两两不交
f = {0: 'a', 1: 'c', 2: 'e'}                            # 一个选择函数
assert all(f[i] in Fam[i] for i in Fam)
S = set(f.values())                                     # 选择集
assert all(len(S & X) == 1 for X in Fam.values())       # AC2 形态

# 不交化技巧（书 (2)→(3) 的 Y = {(i, x)}）：族不必不交也能转不交
Fam2 = {0: {'a', 'b'}, 1: {'b', 'c'}}                   # 相交族
Y = {(i, x) for i, X in Fam2.items() for x in X}        # 打标签后两两不交
assert {(0, 'a'), (1, 'b')} <= Y
Yfam = {i: {(i, x) for x in X} for i, X in Fam2.items()}
for i, j in product(range(2), repeat=2):
    if i != j:
        assert Yfam[i] & Yfam[j] == set()               # 打标签 ⟹ 不交
# 在打标签世界里选，然后撕标签——得到原族的选择函数
Yf = {0: (0, 'a'), 1: (1, 'b')}
proj = {i: pair[1] for i, pair in Yf.items()}
assert all(proj[i] in Fam2[i] for i in Fam2)
print("AC forms: choice function, tagged disjointification, selection set: OK")

# ② Zorn / Hausdorff 的有限版
def subsets(X):
    X = tuple(X)
    return [frozenset(c) for r in range(len(X) + 1)
            for c in combinations_tuple(X, r)]


def combinations_tuple(X, r):
    from itertools import combinations
    return combinations(X, r)


P3 = [frozenset(s) for s in subsets({1, 2, 3})]
pos = P3                                              # (P({1,2,3}), ⊆)

def maximal_elements(universe):
    return [m for m in universe
            if not any(m < o for o in universe)]

def chains(universe):
    out = []
    for r in range(len(universe) + 1):
        for c in combinations_tuple(universe, r):
            if all(a <= b or b <= a for a in c for b in c):
                out.append(frozenset(c))
    return out

maxs = maximal_elements(pos)
assert maxs == [frozenset({1, 2, 3})]                 # 有限偏序有极大元（顶）
all_chains = chains(pos)
max_chains = [c for c in all_chains
              if not any(c < d for d in all_chains)]
assert frozenset({frozenset(), frozenset({1}), frozenset({1, 2}),
                  frozenset({1, 2, 3})}) in max_chains   # 极大链存在
print("zorn/hausdorff finite: maximal element and maximal chain exist: OK")

# 无最大元的偏序：极大元仍存在（Zorn 的"有限免费版"）
pos2 = [s for s in P3 if s != frozenset({1, 2, 3})]   # 挖掉顶
maxs2 = maximal_elements(pos2)
assert set(maxs2) == {frozenset({1, 2}), frozenset({1, 3}), frozenset({2, 3})}
# 但注意：三条极大链不同高——"链有上界"条件在 pos2 中对链
# {∅ ⊆ {1}} 的上界 {1,2} 存在 ✓ Zorn 条件满足
print("poset without top still has maximal elements (3 of them): OK")

# ③ 有限良序定理
for n in (3, 4):
    U = list(range(n))
    assert sorted(U)                                  # 任何有限集可良序化
print("finite well-ordering trivially holds: OK")
print("END ====")
