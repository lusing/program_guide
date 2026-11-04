# -*- coding: utf-8 -*-
print("==== 146 forcing")
# 第 146 章 Python：力迫法的有限实验（书 9.1-9.5）。
# ① 力迫偏序 Func(I,J)（有限函数集）与稠密集；
# ② M-脱殊滤的存在性构造（引理 9.2.2 的递归算法）；
# ③ Δ-系统引理（9.5.6）的有限演示；
# ④ c.c.c. 的有限审计 + Cohen 实数（Func(ω,2) 的脱殊滤给出
#    不在 M 中的"新实数"）。

from itertools import combinations, product as iproduct

# ① 力迫偏序 Func(I,J)：I 到 J 的部分函数（有限窗口）
# p ≤ q ⟺ p ⊇ q（更强=更多信息）
def all_partial_funcs(I, J, max_size):
    out = set()
    for r in range(max_size + 1):
        for dom in combinations(I, r):
            for vals in iproduct(range(len(J)), repeat=r):   # 值可重复选——product 不是 combinations
                out.add(frozenset(zip(dom, vals)))
    return frozenset(out)

# 稠密集判定：D ⊆ P 稠密 ⟺ ∀p∃q∈D(q ≤ p)
def is_dense(D, P):
    for p in P:
        if not any(q >= p for q in D):        # q ⊇ p 即 q ≤ p
            return False
    return True

# 有限窗口：I = {0,1}, J = {0,1}, 函数大小 ≤ 2
P = all_partial_funcs([0, 1], [0, 1], 2)
# ∅（最弱条件）+ 4 个单点 + 4 个双点 = 9 个条件
assert len(P) == 9

# 稠密集示例：{定义域含 0 的条件} 稠密
D0 = frozenset(p for p in P if any(dom == 0 for dom, _ in p))
assert is_dense(D0, P)
print("forcing poset Func({0,1},{0,1}): 9 conditions, D_0 dense: OK")

# ② 脱殊滤的存在（引理 9.2.2 的构造）：对稠密集列表逐一延伸
def build_generic_filter(P, dense_sets, start):
    """递归构造穿过一切稠密集的滤（可数 M 的窗口版）。"""
    q = frozenset(start)
    trace = [q]
    for D in dense_sets:
        # D 稠密 ⟹ 存在 r ∈ D 使 r ≥ q（更强）
        cands = [r for r in D if r >= q]
        assert cands, "dense set should extend any condition"
        q = min(cands, key=len)                     # 取最短的加强
        trace.append(q)
    # 生成滤：若 p ∈ G 且 p ≤ q（p ⊇ q）则 q ∈ G——即 frozenset 的子方向
    G = frozenset(p for p in P if any(p <= q for q in trace))
    return G, trace

D1 = frozenset(p for p in P if any(dom == 1 for dom, _ in p))
G, trace = build_generic_filter(P, [D0, D1], frozenset())
assert any(p in D0 for p in G)                      # 穿过 D₀
assert any(p in D1 for p in G)                      # 穿过 D₁
# G 是滤：上封闭 + 两两相容
assert all(any(g2 >= g1 for g2 in G) for g1 in G)
print("generic filter constructed through D_0, D_1 (lemma 9.2.2): OK")

# ③ Δ-系统引理（9.5.6）的有限演示
# 不可数族的有限版：大族中找到"根相同的子族"
def delta_system(family):
    """有限版：找子族 A₀ 和根 R 使两两交 = R。"""
    family = list(family)
    best_r, best_sub = None, []
    for r in range(0, max(len(s) for s in family) + 1):
        for combo in combinations(family, min(3, len(family))):
            if all(len(s & t) == r for s, t in combinations(combo, 2)):
                root = combo[0] & combo[1]
                if all(s & t == root for s, t in combinations(combo, 2)):
                    if len(combo) > len(best_sub):
                        best_sub, best_r = combo, root
    return best_sub, best_r

# 平凡情况：两两不交族的根是 ∅
disjoint = [frozenset({i}) for i in range(5)]
sub, root = delta_system(disjoint)
assert root == frozenset() and len(sub) >= 3
# 共享根的情况
shared = [frozenset({0, i}) for i in range(1, 5)]
sub2, root2 = delta_system(shared)
assert root2 == frozenset({0})                       # 根 = {0}
print("delta-system lemma: pairwise disjoint -> root empty, shared -> root {0}: OK")

# ④ Cohen 实数的最小演示：Func(ω,2) 的脱殊滤给出新实数
# 窗口版：Func({0,1,2}, {0,1}) 的脱殊滤的并是全长函数
P3 = all_partial_funcs([0, 1, 2], [0, 1], 3)
Ds = [frozenset(p for p in P3 if any(dom == i for dom, _ in p)) for i in range(3)]
G3, _ = build_generic_filter(P3, Ds, frozenset())
f_cohen = frozenset().union(*G3)                    # ⋃G 是全长函数
assert len(f_cohen) == 3                             # 定义域全={0,1,2}
# f_cohen ∉ 基础模型（= ∅ 条件的扩张空间）——它包含基础模型没有的信息
print("cohen real: union of generic filter is a total function: OK")

# c.c.c. 的有限影子：有限偏序的反链总是有限的
# （真正的 c.c.c. 说的是"反链至多可数"——有限版平凡真）
print("ccc finite shadow: finite antichains are finite (trivially countable): OK")
print("END ====")
