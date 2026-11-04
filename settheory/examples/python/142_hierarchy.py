# -*- coding: utf-8 -*-
print("==== 142 hierarchy")
# 第 142 章 Python：层垒谱系 V_α 与传递闭包（书 7.2）。
# ① V_n 的递归构造（第 125 章审计的正式化）与 |V_n| 的增长曲线；
# ② 秩函数 rank(x) = sup{rank(y)+1 | y∈x}——嵌套 frozenset 的显式计算；
# ③ 传递闭包 trcl(x)（书 7.2.12 (7.5) 式）与 7.2.13 的三条恒等式；
# ④ 定理 7.2.15 的三等价在有限窗口的投影。

# ① V_n 构造
def all_subsets(items):
    items = list(items)
    return [frozenset(items[i] for i in range(len(items)) if mask >> i & 1)
            for mask in range(1 << len(items))]

V = [frozenset()]
for _ in range(4):
    V.append(frozenset(all_subsets(V[-1])))
assert [len(v) for v in V] == [0, 1, 2, 4, 16]
# |V_ω| = ℵ₀（V_n 的并）；|V_{ω+1}| = 2^ℵ₀ = c
print("V hierarchy: |V0..V4| = 0,1,2,4,16 -> V_omega = aleph0: OK")

# ② 秩函数（书 7.2.4/7.2.5(4)）
def rank(x, memo=None):
    if memo is None:
        memo = {}
    if x in memo:
        return memo[x]
    r = max((rank(y, memo) + 1 for y in x), default=0)
    memo[x] = r
    return r

assert rank(frozenset()) == 0
assert rank(frozenset([frozenset()])) == 1                # {∅}
assert rank(frozenset([frozenset(), frozenset([frozenset()])])) == 2
# V_1 的秩恰 ≤ 1；V_n 的元素秩 < n
for n in (1, 2, 3):
    assert all(rank(x) < n for x in V[n])                 # 7.2.5(1)
    assert all(rank(x) >= n - 1 for x in V[n] - V[n - 1])  # 新层恰在 n-1
# 7.2.5(3)：x ∈ y ⟹ rank(x) < rank(y)
for y in V[3]:
    for x in y:
        assert rank(x) < rank(y)
print("rank function: 7.2.5(1)(3)(4) audited on V_3: OK")

# ③ 传递闭包（书 7.2.12：(a_0 = a; a_{n+1} = ⋃a_n; trcl = ⋃a_n)）
def trcl(x):
    """传递闭包（书 7.2.12）：trcl(x) = ⋃a_n（a_0 = x）——
    x 的成员、成员的成员……的全体。含 x 自身的最小传递集 = trcl(x)
    本身是传递的且 x ⊆ trcl(x)。"""
    seen = set()
    frontier = list(x)                        # a_1 = ⋃{x} 的成员
    while frontier:
        cur = frontier.pop()
        if cur in seen:
            continue
        seen.add(cur)
        frontier.extend(cur)
    return frozenset(seen)

a = frozenset([frozenset([frozenset([frozenset()])])])    # {{{∅}}}
t = trcl(a)
assert frozenset() in t and frozenset([frozenset()]) in t and a not in t
# 7.2.13(1)：x 传递 ⟹ trcl(x) = x
trans = frozenset([frozenset(), frozenset([frozenset()])])   # {∅,{∅}} = 2 传递
assert trcl(trans) == trans
# 7.2.13(2)：y ∈ x ⟹ trcl(y) ⊆ trcl(x)
for y in a:
    assert trcl(y) <= t
# 7.2.13(3)：trcl(x) = x ∪ ⋃{trcl(y) | y ∈ x}
rhs = a | frozenset().union(*[trcl(y) for y in a])   # ⋃ 求并而非收集
assert t == rhs
print("transitive closure: 7.2.12-7.2.13 all three identities: OK")

# ④ 定理 7.2.15 投影：x ∈ WF ⟺ trcl(x) ∈ WF ⟺ ∈ 良基于 trcl(x)
# 有限窗口内一切集都在 WF 中（= 全部 V_n），良基平凡真——注记边界
for x in V[3]:
    assert trcl(x) in V[4]                                 # trcl 不跳出 WF
print("theorem 7.2.15 shadow: trcl stays in WF: OK")
print("END ====")
