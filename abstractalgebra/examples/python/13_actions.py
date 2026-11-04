# 第 13 章 · 群作用 —— Python 通道
#
# 轨道-稳定子 + 类方程 + 循环结构类 + 项链 Burnside/暴力双跑。

from itertools import permutations, product

print("==== 13 群作用")

def dihedral(n):
    tbl = [[0] * (2 * n) for _ in range(2 * n)]
    for i in range(n):
        for j in range(2):
            for k in range(n):
                for l in range(2):
                    r, s = ((i + k) % n, l) if j == 0 else ((i - k) % n, 1 - l)
                    idx = r if s == 0 else n + r
                    x = i if j == 0 else n + i
                    y = k if l == 0 else n + k
                    tbl[x][y] = idx
    return tbl

def s3_table():
    img = [(1, 2, 3), (2, 1, 3), (3, 2, 1), (1, 3, 2), (2, 3, 1), (3, 1, 2)]
    return [[img.index(tuple(img[a][img[b][j] - 1] for j in range(3)))
             for b in range(6)] for a in range(6)]

identity_of = lambda tbl: next(i for i in range(len(tbl))
                               if tbl[i] == list(range(len(tbl)))
                               and [tbl[k][i] for k in range(len(tbl))] == list(range(len(tbl))))
inv_of = lambda tbl, x: next(y for y in range(len(tbl)) if tbl[x][y] == identity_of(tbl))

def orbit(tbl, x):
    S = {x}
    frontier = [x]
    while frontier:
        new = []
        for g in range(len(tbl)):
            for y in frontier:
                z = tbl[g][y]
                if z not in S:
                    S.add(z); new.append(z)
        frontier = new
    return S

stabilizer = lambda tbl, x: [g for g in range(len(tbl)) if tbl[g][x] == x]

s3, d4 = s3_table(), dihedral(4)
assert orbit(d4, 0) == set(range(8)) and stabilizer(d4, 0) == [0]
print("左正则作用：轨道 = 全群，稳定子 = {1}（凯莱定理的作用版）✓")

for tbl in (s3, d4):
    for x in range(len(tbl)):
        assert len(orbit(tbl, x)) * len(stabilizer(tbl, x)) == len(tbl)
print("定理 2.143（|O|·|G_x| = |G|）：S₃ 与 D₄ 左乘作用逐点成立 ✓")


# 共轭类 / 中心 / 中心化子
def conjugacy_class(tbl, x):
    return {tbl[g][tbl[x][inv_of(tbl, g)]] for g in range(len(tbl))}

centerizer = lambda tbl, x: [g for g in range(len(tbl))
                             if tbl[g][tbl[x][inv_of(tbl, g)]] == x]

classes = []
for x in range(8):
    c = frozenset(conjugacy_class(d4, x))
    if c not in [frozenset(k) for k in classes]:
        classes.append(set(c))
assert sorted(len(c) for c in classes) == [1, 1, 2, 2, 2]
center = [x for x in range(8) if all(tbl_gxg == x for tbl_gxg in
             (d4[g][d4[x][inv_of(d4, g)]] for g in range(8)))]
assert len(center) == 2
for x in range(8):
    assert len(conjugacy_class(d4, x)) * len(centerizer(d4, x)) == 8
print("类方程（D₄）：8 = 2（中心）+ 2+2+2；共轭类 = 群阶/中心化子 ✓")


# S₄ 循环结构类
def cycles(a):
    n, seen, out = len(a), set(), []
    for i in range(1, n + 1):
        if i in seen or a[i - 1] == i:
            continue
        c, j = [], i
        while j not in seen:
            seen.add(j); c.append(j); j = a[j - 1]
        out.append(len(c))
    return tuple(sorted(out))

sizes = {}
for a in permutations(range(1, 5)):
    sizes[cycles(a)] = sizes.get(cycles(a), 0) + 1
assert sizes == {(): 1, (2,): 6, (2, 2): 3, (3,): 8, (4,): 6}
print("S₄ 循环结构类：1/6/3/8/6，总和 24（推论 2.146）✓")


# 项链双跑
n, q = 6, 2
rot_action = lambda k, c: tuple(c[(i - k) % n] for i in range(n))

def dih_action(g, c):                    # g = 0..2n−1：先旋转后反射
    if g < n:
        return rot_action(g, c)
    k = g - n                            # ρ^k σ
    return tuple(c[(n - 1 + k - i) % n] for i in range(n))

all_col = lambda: product(range(q), repeat=n)
fix_count = lambda action, g: sum(1 for c in all_col() if action(g, c) == c)

def brute_orbits(action, Gn):
    seen, orbits = set(), 0
    for c in all_col():
        if c in seen:
            continue
        orbits += 1
        seen.update(action(g, c) for g in range(Gn))
    return orbits

assert sum(fix_count(rot_action, k) for k in range(n)) // n == 14
assert brute_orbits(lambda g, c: rot_action(g, c), n) == 14
assert sum(fix_count(dih_action, g) for g in range(2 * n)) // (2 * n) == 13
assert brute_orbits(dih_action, 2 * n) == 13
print("2 色 6 珠项链：旋转 Burnside = 暴力 = 14；二面体 13 = 暴力 ✓")

print("END ====")
