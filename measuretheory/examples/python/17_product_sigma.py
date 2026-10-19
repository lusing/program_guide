# -*- coding: utf-8 -*-
print("==== 17 product_sigma")
# 第 17 章：乘积 σ-代数（精确版：整数位串 + 支集记账）。
# ① 矩形闭包 = 幂集（16 集合，整数账零舍入）；
# ② 支集记账：柱集对交封闭且支集取并（袁定理 10.5 的逐条对拍）；
# ③ 截口全查（64 对 (E,x)/(E,y) 全部落在可测族内）。
from itertools import product

# X = Y = {0,1}，乘积空间 4 原子 (a,b) 编号 2a+b
ATOMS = [(0, 0), (1, 0), (0, 1), (1, 1)]


def rect_mask(A, B):
    m = 0
    for a, b in ATOMS:
        if a in A and b in B:
            m |= 1 << (2 * a + b)
    return m


SUBSETS = [(), (0,), (1,), (0, 1)]

# ① 矩形全体（去重）与闭包
rectangles = {rect_mask(A, B) for A, B in product(SUBSETS, SUBSETS)}
assert len(rectangles) == 10  # ∅×B 四对合并

def sigma_closure(seeds):
    fam = set(seeds) | {0}
    changed = True
    while changed:
        changed = False
        for A in list(fam):
            C = 15 & ~A
            if C not in fam:
                fam.add(C); changed = True
        for A in list(fam):
            for B in list(fam):
                if (A | B) not in fam:
                    fam.add(A | B); changed = True
    return fam

full = sigma_closure(rectangles)
assert full == set(range(16))                 # 矩形生成一切：A⊗B = 幂集
print("closure from rectangles = powerset (16):", sorted(full) == list(range(16)))

# ② 支集记账：I = {1..6}，柱集 = (S, assign)：约束支集 S 的坐标取值
def cyl_intersect(c1, c2):
    S1, a1 = c1
    S2, a2 = c2
    for i in S1 & S2:
        if a1[i] != a2[i]:
            return None                       # 冲突 = 空集
    a = dict(a1); a.update(a2)
    return (S1 | S2, a)

# 枚举柱集族：支集取 {1},{2},{1,3},{2,3,4} 等，指派取 0/1
def cylinders():
    out = []
    for S in ({1}, {2}, {1, 2}, {1, 3}, {2, 3, 4}):
        for bits in product((0, 1), repeat=len(S)):
            out.append((frozenset(S), dict(zip(sorted(S), bits))))
    return out

cyls = cylinders()
pairs = conflicts = 0
for c1, c2 in product(cyls, cyls):
    r = cyl_intersect(c1, c2)
    if r is not None:
        assert r[0] == c1[0] | c2[0]          # 交的支集 = 支集之并
        pairs += 1
    else:
        conflicts += 1
assert pairs > 100 and conflicts > 10         # 相容交与冲突都大量出现
print("cylinder intersection: support( C1∩C2 ) = S1 ∪ S2 on", pairs,
      "compatible pairs,", conflicts, "conflicts: OK")

# ③ 截口全查
def section_x(E, x):
    m = 0
    for a, b in ATOMS:
        if (E >> (2 * a + b)) & 1 and a == x:
            m |= 1 << b
    return m

def section_y(E, y):
    m = 0
    for a, b in ATOMS:
        if (E >> (2 * a + b)) & 1 and b == y:
            m |= 1 << a
    return m

n = 0
for E in range(16):
    for x in (0, 1):
        assert section_x(E, x) in (0, 1, 2, 3)
        n += 1
    for y in (0, 1):
        assert section_y(E, y) in (0, 1, 2, 3)
        n += 1
assert n == 64
print("all 64 sections measurable: OK")

print("END ====")
