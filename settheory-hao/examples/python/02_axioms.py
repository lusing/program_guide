# -*- coding: utf-8 -*-
print("==== 02 axioms")
# 第 02 章 Python：层垒谱系前几层作为有限宇宙，审计每条构造公理
# "住在哪一层"。V_0 = ∅，V_{k+1} = P(V_k)。
#   分离/并集/基础：在 V_4 内封闭；
#   对集/幂集：结果总逃到下一层 V_5——构造公理需要"更高一层"
#   才能兑现。这正是第 19 章层垒谱系与反映定理的预演。
from itertools import chain


def all_subsets(items):
    items = list(items)
    n = len(items)
    return [frozenset(items[i] for i in range(n) if mask >> i & 1)
            for mask in range(1 << n)]


V = [frozenset()]
for _ in range(1, 5):
    V.append(frozenset(all_subsets(V[-1])))
V5 = frozenset(all_subsets(V[4]))                    # V_5：65536 元素

assert [len(v) for v in V] == [0, 1, 2, 4, 16]
assert len(V5) == 65536
print("sizes: |V0..V5| = 0,1,2,4,16,65536: OK")

# ① 分离：V_4 的任何成员的任何子集仍在 V_4 内（穷举审计）
for X in V[4]:
    for Y in all_subsets(X):
        assert Y in V[4]
print("separation: every subset of every member of V4 stays in V4: OK")

# ② 对集：a,b ∈ V_4 则 {a,b} ∈ V_5；但未必在 V_4——见证 a = V_3, b = ∅
a, b = V[3], frozenset()
pair = frozenset([a, b])
assert a in V[4] and b in V[4]
assert pair in V5 and pair not in V[4]
print("pairing: {V3, 0} lands in V5, not V4: OK")

# ③ 幂集：X ∈ V_3 则 P(X) ∈ V_4；但 X ∈ V_4 时 P(X) 逃出本层
for X in V[3]:
    assert frozenset(all_subsets(X)) in V[4]
assert V[4] not in V[4]                              # P(V3) = V4 本身不在 V4 内
print("powerset: closed for V3-members, P(V3) = V4 escapes V4: OK")

# ④ 并集：X ∈ V_4 则 ⋃X ⊆ V_2，故 ⋃X ∈ V_4（封闭）
for X in V[4]:
    u = frozenset(chain.from_iterable(X))
    assert u in V[4]
print("union: closed in V4: OK")

# ⑤ 基础：V_4 的每个非空成员都有 ∈-最小元（z ∩ Y = ∅）
for Y in V[4]:
    if Y:
        assert any(z & Y == frozenset() for z in Y)
print("foundation: every nonempty set in V4 has a minimal member: OK")

# ⑥ 全集不存在（有限影子）：V_k ∉ V_k
for k in range(1, 5):
    assert V[k] not in V[k]
assert V5 not in V5
print("no universal set: Vk is not a member of itself: OK")

# ⑦ Cantor 有限影子：|P(X)| = 2^|X| > |X|
for X in V[4]:
    assert 2 ** len(X) > len(X)
print("cantor shadow: 2^|X| > |X| for every X in V4: OK")
print("END ====")
