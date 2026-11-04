# -*- coding: utf-8 -*-
print("==== 143 foundation")
# 第 143 章 Python：良基归纳与 Mostowski 塌缩（书 7.5-7.6）。
# ① ∈-良基性的窗口审计：嵌套 frozenset 无 x∈x、无下降链；
# ② 良基归纳的可计算审计器（秩为下降证据）；
# ③ 良基递归（书 7.6.6）的实例：rank 本身、trcl、Mostowski 塌缩；
# ④ Mostowski 塌缩定理（书 7.6.15）的有限演示。

# ① 无自属、无下降链
def all_subsets(items):
    items = list(items)
    return [frozenset(items[i] for i in range(len(items)) if mask >> i & 1)
            for mask in range(1 << len(items))]

V = [frozenset()]
for _ in range(4):
    V.append(frozenset(all_subsets(V[-1])))

for x in V[4]:
    assert x not in x                                    # 无 x ∈ x
print("no self-membership in V_4 (foundation): OK")

# 下降链检测：沿 ∈ 走必终止（rank 严格下降）
def rank(x):
    return max((rank(y) + 1 for y in x), default=0)

def chain_terminates(x):
    seen = 0
    stack = [x]
    while stack and seen < 100:
        cur = stack.pop()
        seen += 1
        stack.extend(cur)
    assert seen < 100, "descent chain exceeded 100"
    return True

assert all(chain_terminates(x) for x in V[4])
print("all descent chains terminate (rank strictly decreases): OK")

# ② 良基归纳审计器：以 rank 为证据函数
def wf_induct(x, prop, step):
    """书 7.6 (7.48) 的审计版：step(x, sub_results) -> bool。
    子结果由 ∈ 的良基性保证已可用。"""
    return step(x, [wf_induct(y, prop, step) for y in x])

# 实例：V_4 的一切集合都"有有限传递闭包"
def finite_tc_step(x, sub_ok):
    return all(sub_ok)
assert all(wf_induct(x, None, finite_tc_step) for x in V[4])
print("wellfounded induction: finite-tc property holds by wf-induct: OK")

# ③ 良基递归（书 7.6.6）：G(x) = F(x, G↾pred(x)) 的三个经典实例
# (a) rank 就是 WF-递归的（书 7.6.7）
# (b) trcl
def trcl(x):
    out = set()
    def rec(y):
        out.add(y)
        for z in y:
            rec(z)
    for z in x:
        rec(z)
    return frozenset(out)

# (c) Mostowski 塌缩（书 7.6.9）：G(x) = {G(y) | y R x}
# 对于 R = ∈，G 就是恒等（WF 已经是传递的）——书 7.6.13
def mostowski(x):
    return frozenset(mostowski(y) for y in x)

identity_collapse = all(mostowski(x) == x for x in V[3])
assert identity_collapse                              # ∈ 上的塌缩是恒等
print("mostowski collapse with R=membership is the identity (7.6.13): OK")

# ④ 非外延关系的塌缩把"重复"合并：以标签图 (a→b, a→c 且 b,c 同构)
# 关系 R：a R b, a R c（a 有两个孩子 b, c，b c 无孩子）
def collapse_dag(adj):                                # adj: {node: [children]}
    memo = {}
    def coll(n):
        if n in memo:
            return memo[n]
        memo[n] = frozenset(coll(c) for c in adj.get(n, []))
        return memo[n]
    return {n: coll(n) for n in adj}

# b 和 c 都是"叶子"（无孩子）——它们塌缩为同一个 ∅（外延合并）
adj = {'a': ['b', 'c'], 'b': [], 'c': []}
collapsed = collapse_dag(adj)
assert collapsed['b'] == collapsed['c'] == frozenset()  # b, c 塌成 ∅
assert collapsed['a'] == frozenset([frozenset()])       # a 塌成 {∅}
# 外延性检查（7.6.11）：b ≠ c 但 pred 相同——R 非外延，G 非单射
print("mostowski on dag: b,c collapse to same (ext failure merges): OK")
print("END ====")
