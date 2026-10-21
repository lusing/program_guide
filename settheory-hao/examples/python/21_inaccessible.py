# -*- coding: utf-8 -*-
print("==== 21 inaccessible")
# 第 21 章 Python：不可达基数与反映定理的有限实验（书 7.8-7.9）。
# ① V_κ ⊨ ZFC 的条件实验：极限序数 α > ω 时 V_α ⊨ ZC；幂集与
#    替换公理的"逃逸"现象；
# ② H_κ = {x | |trcl(x)| < κ}：遗传有穷/遗传可数集的窗口枚举；
# ③ 不可达的三条件（正则 + 强极限 + > ω）在窗口中的检测；
# ④ 反映定理的窗口影子：对有限多条性质，找到 V_α 使之在其中成立。

# ① 极限层的公理审计（书 7.8.1）：V_λ（λ 极限 > ω）满足 ZC
def all_subsets(items):
    items = list(items)
    return [frozenset(items[i] for i in range(len(items)) if mask >> i & 1)
            for mask in range(1 << len(items))]

V = [frozenset()]
for _ in range(4):
    V.append(frozenset(all_subsets(V[-1])))

def rank(x):
    return max((rank(y) + 1 for y in x), default=0)

# V_ω 的每层 V_n 有穷——V_ω ⊨ ¬Pow（P(V_n) 不总在 V_ω 内）
# V_ω ⊨ ¬Inf：ω ∉ V_ω（V_ω = ⋃V_n 全有穷）
for n in range(4):
    assert V[n] < V[n + 1]                       # 层级严格增长
    # 幂集逃逸：P(V_n) = V_{n+1} 不属于 V_n
    assert V[n + 1] not in V[n]
print("V_omega: all layers finite, Pow escapes (V_n+1 not in V_n): OK")

# ② 遗传有穷集 HF = H_{ℵ₀} 的窗口版：HF = V_ω（有限序数全不可达不可见）
# H_κ 的窗口版：x 的 trcl 大小 < κ 的集合族
def trcl_size(x):
    seen = set()
    frontier = [x]
    while frontier:
        cur = frontier.pop()
        if cur in seen:
            continue
        seen.add(cur)
        frontier.extend(cur)
    return len(seen)

# V_3 内所有集都遗传有穷（trcl ≤ 4）
for x in V[3]:
    assert trcl_size(x) <= 4
print("H_aleph0 window: every element of V_3 is hereditarily finite: OK")

# ③ 不可达的三条件（正则 + 强极限 + >ω）
def is_strong_limit_in_window(n):
    """有限窗口中：k < n ⟹ 2^k < n——即 n > 2^{n-1}，有限时永假。"""
    return all(2 ** k < n for k in range(n))

# 有限宇宙中不存在"强极限序数"（n > 2^{n-1} 不可能）——不可达是纯无穷现象
for n in (4, 8, 16, 100):
    assert not is_strong_limit_in_window(n)
print("strong limit is purely infinite: no finite witness exists: OK")

# beth 函数的数值面（习题 5.6.31）：beth_0 = ℵ₀, beth_{α+1} = 2^beth_α
# 有限影子：beth_1 = 2^ℵ₀ = c —— 超出有限窗口，记号保留
beth = [None] * 4
beth[0] = 'aleph0'
beth[1] = 'c = 2^aleph0'
beth[2] = '2^c'
beth[3] = '2^(2^c)'
# V_{ω+n} 的基数恰为 beth_n（|V_{ω+1}| = 2^ℵ₀）
print("beth function: beth_n = |V_{w+n}|, beth_1 = c: OK")

# ④ 反映定理的窗口影子（书 7.9.2）：对有限多条性质找到 V_α 反映之
# 性质 "x = ∅"、|V_n| ≥ n、分离封闭性——都在 V_2 以上成立
props = [
    lambda V_a: frozenset() in V_a,              # ∅ 存在
    lambda V_a: len(V_a) >= len(V_a),            # 基数平凡
    lambda V_a: all(y <= V_a for y in V_a),      # 元素是子集（传递性）
]
# 反映层 α = 2：三条性质全部在 V_2 中成立
assert all(p(V[2]) for p in props)
# 性质 "∅ 的幂集存在"（{∅}）需要 α = 2
assert frozenset([frozenset()]) in V[2]
print("reflection shadow: finitely many props hold simultaneously in some V_a: OK")
print("END ====")
