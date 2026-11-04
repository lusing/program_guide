# 第 10 章 · 子群与拉格朗日定理 —— Python 通道
#
# 子群枚举 + 陪集分解 + 拉格朗日三推论 + A₄ 无 6 阶子群（命题 2.99）。

from itertools import combinations, permutations
from math import gcd

print("==== 10 子群与拉格朗日定理")

# ---------- 群件（同第 09 章口径，0 基） ----------
def identity_of(tbl):
    n = len(tbl)
    for i in range(n):
        if tbl[i] == list(range(n)) and [tbl[k][i] for k in range(n)] == list(range(n)):
            return i
    raise ValueError

def order_of(tbl, x):
    e, k, cur = identity_of(tbl), 1, x
    while cur != e:
        cur = tbl[x][cur]
        k += 1
    return k

def itpow(tbl, x, k):
    r = identity_of(tbl)
    for _ in range(k):
        r = tbl[x][r]
    return r

zn_add = lambda n: [[(i + j) % n for j in range(n)] for i in range(n)]

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

def is_subgroup(tbl, H):
    return len(H) > 0 and all(tbl[x][y] in H for x in H for y in H)

def all_subgroups(tbl):
    n = len(tbl)
    out = []
    for k in range(1, n + 1):
        for H in combinations(range(n), k):
            if is_subgroup(tbl, set(H)):
                out.append(sorted(H))
    return sorted(out, key=len)

def cosets(tbl, H):
    seen, blocks = set(), []
    for a in range(len(tbl)):
        if a in seen:
            continue
        C = sorted(tbl[a][h] for h in H)
        blocks.append(C)
        seen.update(C)
    return blocks

# ---------- 子群枚举 ----------
s3 = s3_table()
d4 = dihedral(4)
subs_s3 = all_subgroups(s3)
subs_d4 = all_subgroups(d4)
assert len(subs_s3) == 6 and sorted(len(H) for H in subs_s3) == [1, 2, 2, 2, 3, 6]
assert len(subs_d4) == 10
assert sorted(len(H) for H in subs_d4) == [1, 2, 2, 2, 2, 2, 4, 4, 4, 8]
print("子群枚举：S₃ 恰 6 个；D₄ 恰 10 个（因子全出现）✓")

# ---------- 陪集分解 ----------
for tbl, H in ((s3, subs_s3[3]), (s3, subs_s3[4]), (d4, subs_d4[6]), (zn_add(12), [0, 4, 8])):
    blocks = cosets(tbl, H)
    assert len(blocks) * len(H) == len(tbl)
    assert sorted(x for b in blocks for x in b) == list(range(len(tbl)))
print("陪集分解：块数 × 块大小 = |G|，两两不交并回全集 ✓")

# ---------- 拉格朗日三推论 ----------
for tbl in (s3, d4, zn_add(12)):
    n = len(tbl)
    for H in all_subgroups(tbl):
        assert n % len(H) == 0
    for x in range(n):
        assert n % order_of(tbl, x) == 0
        assert itpow(tbl, x, n) == identity_of(tbl)
print("推论 2.85/2.86：元素阶 | 群阶，x^|G| = 1（S₃、D₄、ℤ₁₂ 全量）✓")

# ---------- 命题 2.75：ℤ₁₂ 每因子恰一个子群 ----------
z12 = zn_add(12)
by_order = {}
for H in all_subgroups(z12):
    by_order[len(H)] = by_order.get(len(H), 0) + 1
assert by_order == {1: 1, 2: 1, 3: 1, 4: 1, 6: 1, 12: 1}
assert sum(1 for i in range(12) if order_of(z12, i) == 6) == 2
print("命题 2.75：ℤ₁₂ 六个因子各恰一个子群；6 阶子群恰 φ(6) = 2 个生成元 ✓")

# ---------- 命题 2.80 ----------
sub = lambda n, d: {(j * d) % n for j in range(n // d)}
assert {((4 * a) + (6 * b)) % 36 for a in range(9) for b in range(6)} == sub(36, 2)
assert sub(36, 4) & sub(36, 6) == sub(36, 12)
print("命题 2.80：⟨4⟩+⟨6⟩ = ⟨2⟩ = ⟨gcd⟩；⟨4⟩∩⟨6⟩ = ⟨12⟩ = ⟨lcm⟩ ✓")

# ---------- A₄ 无 6 阶子群（命题 2.99，拉格朗日逆反例） ----------
def a4_table():
    elems = [p for p in permutations(range(1, 5))
             if sum(1 for i in range(4) for j in range(i + 1, 4)
                    if p[i] > p[j]) % 2 == 0]
    idx = {p: i for i, p in enumerate(elems)}
    return [[idx[tuple(a[b[j] - 1] for j in range(4))] for b in elems]
            for a in elems], elems

a4, a4elems = a4_table()
assert len(a4elems) == 12
n6 = 0
for H in combinations(range(12), 6):
    if is_subgroup(a4, set(H)):
        n6 += 1
assert n6 == 0
print("命题 2.99：A₄（12 阶）无 6 阶子群——C(12,6) = 924 个子集全查 ✓")

print("END ====")
