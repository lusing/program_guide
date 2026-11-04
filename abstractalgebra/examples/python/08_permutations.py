# 第 08 章 · 置换 —— Python 通道
#
# 循环分解/符号/阶/共轭 + 15-字谜判定器（itertools.permutations 版）。

from itertools import permutations

print("==== 08 置换")

compose = lambda a, b: tuple(a[b[i] - 1] for i in range(len(b)))   # 1 基
def perminv(a):
    r = [0] * len(a)
    for i, ai in enumerate(a, 1):
        r[ai - 1] = i
    return tuple(r)

def cycles(a):
    n, seen, out = len(a), set(), []
    for i in range(1, n + 1):
        if i in seen or a[i - 1] == i:
            continue
        c, j = [], i
        while j not in seen:
            seen.add(j); c.append(j); j = a[j - 1]
        out.append(tuple(c))
    return tuple(out)

def signum(a):
    n = len(a)
    inv = sum(1 for i in range(1, n + 1) for j in range(i + 1, n + 1)
              if a[i - 1] > a[j - 1])
    return 1 if inv % 2 == 0 else -1

def perm_order(a):
    k, cur = 1, a
    while cur != tuple(range(1, len(a) + 1)):
        cur = compose(a, cur)
        k += 1
    return k

from math import lcm, gcd

S4 = list(permutations(range(1, 5)))
assert len(S4) == 24

# 循环分解手算对照
assert cycles((2, 3, 1)) == ((1, 2, 3),)
assert cycles((2, 1, 3)) == ((1, 2),)
assert compose((2, 1, 3), (1, 3, 2)) == (2, 3, 1)   # (12)∘(23) = (123)
print("循环分解与复合从右向左：手算一致 ✓")

# 命题 2.54：阶 = lcm 循环长
for a in S4:
    assert perm_order(a) == (lcm(*map(len, cycles(a))) if cycles(a) else 1)
print("命题 2.54：S₄ 全部 24 个置换 ✓")

# 定理 2.39：符号乘法性
for a in S4:
    for b in S4:
        assert signum(compose(a, b)) == signum(a) * signum(b)
assert sum(1 for a in S4 if signum(a) == 1) == 12
print("定理 2.39：S₄ 全部 576 对 ✓；|A₄| = 12 ✓")

# 命题 2.32：共轭保持循环结构（循环内点序无关，先排序再比）
for a in S4:
    for g in S4:
        d = compose(compose(a, g), perminv(a))
        assert sorted(tuple(sorted(c)) for c in cycles(d)) == \
               sorted(tuple(sorted(a[i - 1] for i in c)) for c in cycles(g))
print("命题 2.32：αγα⁻¹ 与 γ 循环结构同 ✓")

# 循环结构类大小（S₅）
S5 = list(permutations(range(1, 6)))
def struct_key(a):
    return tuple(sorted(len(c) for c in cycles(a)))
sizes = {}
for a in S5:
    sizes[struct_key(a)] = sizes.get(struct_key(a), 0) + 1
assert sizes[(2, 3)] == 20 and sizes[(5,)] == 24 and sizes[(2,)] == 10
print("S₅ 循环结构类：(abc)(de) 20、(abcde) 24、(ab) 10 ✓")


# 15-字谜判定器
def fifteen_solvable(board):
    tiles = [x for x in board if x != 0]
    inv = sum(1 for i in range(len(tiles)) for j in range(i + 1, len(tiles))
              if tiles[i] > tiles[j])
    blank = board.index(0)
    row_from_bottom = 4 - blank // 4
    return (inv + row_from_bottom) % 2 == 1

goal = list(range(1, 16)) + [0]
assert fifteen_solvable(goal)
h = goal[:]; h[14], h[15] = h[15], h[14]          # 水平滑
assert fifteen_solvable(h)
v = goal[:]; v[11], v[15] = v[15], v[11]          # 垂直滑
assert fifteen_solvable(v)
sw = goal[:]; sw[13], sw[14] = sw[14], sw[13]     # 14-15 互换
assert not fifteen_solvable(sw)
print("15-字谜判定器：目标/水平/垂直滑可解；14-15 互换不可解 ✓")

print("END ====")
