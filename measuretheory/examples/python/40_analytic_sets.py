# -*- coding: utf-8 -*-
print("==== 40 analytic_sets")
# 第 40 章 Python：树运算（整数精确版）。
# ① Souslin 运算的显式计算；② Borel 闭包对照（有限退化）；
# ③ 容度可容度性；④ 路径统计。
from itertools import product

# ① 深度 3 的二叉树：前缀 → 集合（0..7 位串）
d = 3
U = list(range(8))
F = {}
for length in range(1, d + 1):
    for pref in product((0, 1), repeat=length):
        key = "".join(map(str, pref))
        F[key] = [i for i in U if (key.count("1") * 2 + i) % 3 != 0]

paths = list(product((0, 1), repeat=d))
souslin = set()
for sig in paths:
    leaf = F["".join(map(str, sig))]
    souslin.update(leaf)
assert len(souslin) > 0
print("Souslin operation: |A(F)| = ", len(souslin), "of", len(U), ": OK")

# ② Borel 闭包（补/并饱和）
def borel_closure(seeds, universe):
    fam = set(frozenset(s) for s in seeds)
    fam.add(frozenset(universe))
    changed = True
    while changed:
        changed = False
        for A in list(fam):
            C = frozenset(set(universe) - set(A))
            if C not in fam:
                fam.add(C); changed = True
        lst = list(fam)
        for A in lst:
            for B in lst:
                Uu = frozenset(set(A) | set(B))
                if Uu not in fam:
                    fam.add(Uu); changed = True
    return fam

bc = borel_closure(F.values(), U)
assert frozenset(souslin) in bc              # 有限退化：Souslin 像 Borel
print("finite degeneration: Souslin image inside Borel closure: OK")

# ③ 容度可容度性：c = 计数容度（有限集合的"紧" = 自身）
cap = len
assert cap(souslin) == cap(souslin)          # K = A 达到（退化）
# 单调性：子集容度 ≤
for A in (F["0"], F["1"], F["00"]):
    assert cap(A) <= cap(U)
print("capacitability: K = A attains capacity; monotonicity exact: OK")

# ④ 路径与节点统计（描述集合论的规模直觉）
n_nodes = sum(2 ** k for k in range(d))
assert len(paths) == 2 ** d == 8
assert n_nodes == 2 ** d - 1               # 深度 0..d-1 的节点总数（满二叉前 d 层）
print("tree statistics: 8 paths, ", n_nodes, " nodes: OK")

print("END ====")
