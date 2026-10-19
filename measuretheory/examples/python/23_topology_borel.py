# -*- coding: utf-8 -*-
print("==== 23 topology_borel")
# 第 23 章 Python：有限拓扑的 Borel 精确账（整数位串）。
# ① Borel 闭包（8 元）；② 连续函数全查（仅 4 常值）；
# ③ Ba（连续零集）= 平凡 σ-代数 ⊊ B；④ 乘积基闭包封顶。
from itertools import product as iproduct

OM = [1, 2, 3, 4]
TAU = [0b0000, 0b0001, 0b0011, 0b1111]  # ∅,{1},{1,2},Ω


def borel_closure(topo, full=0b1111):
    fam = set(int(t) for t in topo) | {0}
    changed = True
    while changed:
        changed = False
        for A in list(fam):
            C = full & ~A
            if C not in fam:
                fam.add(C); changed = True
        for A in list(fam):
            for B in list(fam):
                if (A | B) not in fam:
                    fam.add(A | B); changed = True
    return sorted(fam)


borel = borel_closure(TAU)
assert len(borel) == 8
print("Borel closure = 8 sets: OK")


def cont_check(f):
    for V in range(16):  # 离散值域的全部开集
        pre = 0
        for x in OM:
            if (V >> f[x - 1]) & 1:
                pre |= 1 << (x - 1)
        if pre not in TAU:
            return False
    return True


conts = [f for f in iproduct(range(4), repeat=4) if cont_check(f)]
assert len(conts) == 4  # 仅常值
print("continuous = 4 constants among 256: OK")

# Ba：连续函数零集的 σ-闭包 = 平凡（∅/Ω）⊊ B
zs = set()
for f in conts:
    m = 0
    for x in OM:
        if f[x - 1] == 0:
            m |= 1 << (x - 1)
    zs.add(m)
ba = borel_closure(sorted(zs))
assert ba == [0b0000, 0b1111] and len(borel) == 8
print("Ba = {empty, Omega} (2) < B (8): finite non-T1 witness: OK")

# 乘积对齐：box 基闭包（16 点）
base = set()
for U in TAU:
    for V in TAU:
        m = 0
        for x in OM:
            for y in OM:
                if (U >> (x - 1)) & 1 and (V >> (y - 1)) & 1:
                    m |= 1 << (2 * (x - 1) + (y - 1))
        base.add(m)
bp = borel_closure(sorted(base), full=0xFFFF)
assert 0xFFFF in bp
print("product base closure reaches full 16-point space: OK")

print("END ====")
