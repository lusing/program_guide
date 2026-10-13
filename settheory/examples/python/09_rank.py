# 第 09 章 正则公理：V_ω = HF 与秩函数
#
# 1. 嵌套 frozenset 的秩（rank(x) = sup{rank(y)+1}）；
# 2. V_ω 的枚举验证：前几层 V_n 的并恰为深度 < ω 的集合全体。

import sys
import io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

print("==== 09 正则公理：V_ω 与秩")

# ------------------------------------------------------------------
# 一、秩函数（嵌套 frozenset 的深度）
# ------------------------------------------------------------------

def rank(x):
    """rank(x) = sup{rank(y) + 1 : y ∈ x}；空集为 0。"""
    if not x:
        return 0
    return max(rank(y) for y in x) + 1

E = frozenset()
one = frozenset([E])
two = frozenset([E, one])
three = frozenset([E, one, two])

for name, x, expect in [("∅", E, 0), ("1={∅}", one, 1),
                        ("2={∅,{∅}}", two, 2), ("3", three, 3)]:
    r = rank(x)
    assert r == expect, (name, r)
    print(f"  rank({name}) = {r}")

# rank(x) = α 对 von Neumann 序数成立（rank 的性质 (b)）

# ------------------------------------------------------------------
# 二、V_n 的逐层构造（小层全枚举）
# ------------------------------------------------------------------

def powerset_frozen(s):
    els = sorted(s, key=lambda t: (rank(t), sorted(map(str, t)) if False else 0))
    import itertools
    out = []
    n = len(els)
    for k in range(2 ** n):
        out.append(frozenset(els[i] for i in range(n) if (k >> i) & 1))
    return frozenset(out)

V = [frozenset()]                     # V_0 = ∅
for n in range(4):
    V.append(powerset_frozen(V[-1]))  # V_{n+1} = P(V_n)

for n, v in enumerate(V):
    print(f"  |V_{n}| = {len(v)}")
assert [len(v) for v in V] == [1 - 1, 1, 2, 4, 16]  # 0,1,2,4,16

# V_ω = ⋃ V_n：每层集合的秩 < n+1
union_V = set().union(*V)
print(f"\n  |⋃ V_n (n≤4)| = {len(union_V)}——V_ω 的前 5 层并")
print("  V_ω = HF：恰好是全体遗传有限集（每个成员的成员……有限）")

# ------------------------------------------------------------------
# 三、正则公理的三重面貌
# ------------------------------------------------------------------

print("\n  正则公理 ⟺ 无 x∈x ⟺ 无 ∈-下降链 ⟺ V = ⋃V_α")
print("  （Zermelo 的宇宙分层图景——现代集合论的标准世界观）")
print("  BG 类理论（附录）：类=公式的化身；集合=属于其他类的类。")
print("  类的成员都是集合 ⟹ 类理论不产生'类的类'悖论。")

print("END ====")
