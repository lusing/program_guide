# 第 12 章 · 商群 —— Python 通道
#
# 正规性/商表/表同构 + 威尔逊 + φ 乘性 + 小群分类（4/6 阶）。

from itertools import permutations
from math import factorial, gcd

print("==== 12 商群")

# ---------- 群件 ----------
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

identity_of = lambda tbl: next(i for i in range(len(tbl))
                               if tbl[i] == list(range(len(tbl)))
                               and [tbl[k][i] for k in range(len(tbl))] == list(range(len(tbl))))
inv_of = lambda tbl, x: next(y for y in range(len(tbl)) if tbl[x][y] == identity_of(tbl))

def cosets(tbl, H):
    seen, blocks = set(), []
    for a in range(len(tbl)):
        if a in seen:
            continue
        C = sorted(tbl[a][h] for h in H)
        blocks.append(C)
        seen.update(C)
    return blocks

def is_normal(tbl, K):
    return sorted(K) == sorted({tbl[g][tbl[k][inv_of(tbl, g)]] for g in range(len(tbl))
                                for k in K})

def quotient_table(tbl, K):
    blocks = cosets(tbl, K)
    pos = lambda x: next(i for i, b in enumerate(blocks) if x in b)
    return [[pos(tbl[b[0]][blocks[j][0]]) for j in range(len(blocks))]
            for b in blocks], blocks

def table_iso(t1, t2):
    n = len(t1)
    for phi in permutations(range(n)):
        if all(phi[t1[i][j]] == t2[phi[i]][phi[j]] for i in range(n) for j in range(n)):
            return phi
    return None

# ---------- S₃ / A₃ ≅ ℤ₂ ----------
s3 = s3_table()
A3 = [0, 4, 5]                        # id, (123), (132)
assert is_normal(s3, A3)
q, blocks = quotient_table(s3, A3)
assert table_iso(q, zn_add(2)) is not None
print("S₃/A₃ ≅ ℤ₂（正规性 + 商表同构搜索）✓")

# ---------- 反例：⟨(12)⟩ 不正规，良定义性破产 ----------
H12 = [0, 1]
assert not is_normal(s3, H12)
c_of = lambda x: next(i for i, blk in enumerate(cosets(s3, H12)) if x in blk)
witness = None
for blk in cosets(s3, H12)[1:]:
    for a1, a2 in permutations(blk, 2):
        for x in range(6):
            if c_of(s3[a1][x]) != c_of(s3[a2][x]):
                witness = (a1, a2, x)
assert witness is not None
print(f"反例现场：同一陪集的代表元 {witness[0]} 与 {witness[1]} 右乘 "
      f"{witness[2]} 落进不同陪集（良定义性破产）✓")

# ---------- ℤ₁₂/⟨4⟩ ≅ ℤ₄ 与 D₄ 的两个商 ----------
z12 = zn_add(12)
q12, _ = quotient_table(z12, [0, 4, 8])
assert table_iso(q12, zn_add(4)) is not None

d4 = dihedral(4)
assert is_normal(d4, [0, 1, 2, 3])                    # 旋转子群
qr, _ = quotient_table(d4, [0, 1, 2, 3])
assert table_iso(qr, zn_add(2)) is not None           # D₄/⟨旋转⟩ ≅ ℤ₂
assert is_normal(d4, [0, 2])                          # {1, α²}
qc, _ = quotient_table(d4, [0, 2])
V4 = [[(i // 2 + j // 2) % 2 * 2 + (i % 2 + j % 2) % 2 for j in range(4)] for i in range(4)]
assert table_iso(qc, V4) is not None                  # D₄/{1,α²} ≅ V₄
print("ℤ₁₂/⟨4⟩ ≅ ℤ₄；D₄/⟨旋转⟩ ≅ ℤ₂；D₄/{1,α²} ≅ V₄ ✓")

# ---------- 威尔逊定理 ----------
for p in (5, 7, 11, 13):
    assert factorial(p - 1) % p == p - 1
for c in (8, 9, 10, 12):
    assert factorial(c - 1) % c != c - 1
print("威尔逊定理：p = 5,7,11,13 成立；合成数 8,9,10,12 失效 ✓")

# ---------- φ 乘性 + ℤ₂×ℤ₃ ≅ ℤ₆ ----------
totient = lambda n: sum(1 for k in range(1, n + 1) if gcd(k, n) == 1)
for m, n in ((3, 4), (4, 5), (5, 6), (7, 9)):
    assert totient(m * n) == totient(m) * totient(n)
z2z3 = [[(i // 3 + j // 3) % 2 * 3 + (i % 3 + j % 3) % 3 for j in range(6)] for i in range(6)]
assert table_iso(z2z3, zn_add(6)) is not None
print("φ 乘性四例；ℤ₂×ℤ₃ ≅ ℤ₆（定理 2.126）✓")

# ---------- 4 阶群分类（命题 2.132）：枚举凯莱表不可行，改证两实现不同构 ----------
assert table_iso(zn_add(4), V4) is None, "ℤ₄ 与 V 不同构（元素阶谱不同）"
orders = lambda tbl: sorted(order_of(tbl, x) for x in range(len(tbl)))
def order_of(tbl, x):
    e, k, cur = identity_of(tbl), 1, x
    while cur != e:
        cur = tbl[x][cur]
        k += 1
    return k
assert orders(zn_add(4)) == [1, 2, 4, 4] and orders(V4) == [1, 2, 2, 2]
print("命题 2.132：ℤ₄ 与 V 阶谱不同 ⟹ 不同构（4 阶群恰这两个）✓")

print("END ====")
