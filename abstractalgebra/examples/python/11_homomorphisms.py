# 第 11 章 · 群同态 —— Python 通道
#
# sgn/det/模映射 + |G| = |ker|·|im| + 共轭自同构 + 同态枚举。

from itertools import product, permutations

print("==== 11 群同态")

compose = lambda a, b: tuple(a[b[i] - 1] for i in range(len(b)))
def signum(a):
    n = len(a)
    inv = sum(1 for i in range(n) for j in range(i + 1, n) if a[i] > a[j])
    return 1 if inv % 2 == 0 else -1

S4 = list(permutations(range(1, 5)))
for a, b in product(S4, repeat=2):
    assert signum(compose(a, b)) == signum(a) * signum(b)
assert sum(1 for a in S4 if signum(a) == 1) == 12
print("sgn : S₄ → {±1}：576 对同态性；|ker| = 12 = |S₄|/|im| ✓")

# ---------- det : GL(2, ℤ₅) → ℤ₅* ----------
def gl2_zp(p):
    return [(a, b, c, d) for a in range(p) for b in range(p)
            for c in range(p) for d in range(p) if (a * d - b * c) % p != 0]

GL = gl2_zp(5)
assert len(GL) == (25 - 1) * (25 - 5) == 480
mul5 = lambda A, B: ((A[0] * B[0] + A[1] * B[2]) % 5,
                     (A[0] * B[1] + A[1] * B[3]) % 5,
                     (A[2] * B[0] + A[3] * B[2]) % 5,
                     (A[2] * B[1] + A[3] * B[3]) % 5)
det5 = lambda A: (A[0] * A[3] - A[1] * A[2]) % 5
for k in range(200):
    A = GL[(97 * k) % len(GL)]
    B = GL[(89 * k + 3) % len(GL)]
    assert det5(mul5(A, B)) == det5(A) * det5(B) % 5
assert sum(1 for A in GL if det5(A) == 1) == 480 // 4
print("det : GL(2,ℤ₅) → ℤ₅*：480 元，200 对抽样；核 = SL₂ 恰 120 ✓")

# ---------- f : ℤ₆ → ℤ₃ ----------
f63 = lambda k: k % 3
for a in range(6):
    for b in range(6):
        assert f63((a + b) % 6) == (f63(a) + f63(b)) % 3
ker = sum(1 for k in range(6) if f63(k) == 0)
im = len({f63(k) for k in range(6)})
assert (ker, im) == (2, 3) and 6 == ker * im
print("ℤ₆ → ℤ₃：核 2 元（{0,3}），像 3 元，6 = 2×3 ✓")

# ---------- 反例 ----------
sq = lambda x: (x * x) % 4
assert not all(sq((a + b) % 4) == (sq(a) + sq(b)) % 4 for a in range(4) for b in range(4))
dbl = lambda x: (2 * x) % 4
assert all(dbl((a + b) % 4) == (dbl(a) + dbl(b)) % 4 for a in range(4) for b in range(4))
print("反例：ℤ₄ 平方映射不保持加法（1+1 处失败）；倍乘 2x 是同态 ✓")


# ---------- 命题 2.92：共轭是自同构（D₄） ----------
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

d4 = dihedral(4)
inv_of = lambda tbl, g: next(y for y in range(len(tbl)) if tbl[g][y] == 0)
for g in range(8):
    phi = [d4[g][d4[inv_of(d4, g)][x]] for x in range(8)]   # g x g⁻¹
    assert sorted(phi) == list(range(8))
    for x in range(8):
        for y in range(8):
            assert phi[d4[x][y]] == d4[phi[x]][phi[y]]
print("命题 2.92：D₄ 的 8 个共轭映射全是表自同构 ✓")

# ---------- 同态枚举 ----------
def s3_table():
    img = [(1, 2, 3), (2, 1, 3), (3, 2, 1), (1, 3, 2), (2, 3, 1), (3, 1, 2)]
    return [[img.index(tuple(img[a][img[b][j] - 1] for j in range(3)))
             for b in range(6)] for a in range(6)]

s3 = s3_table()
def homs_s3_to_z2():
    """枚举全部 2⁶ = 64 个映射，逐对检查乘法保持。"""
    out = []
    for vals in product((0, 1), repeat=6):
        if all(vals[s3[x][y]] == (vals[x] + vals[y]) % 2
               for x in range(6) for y in range(6)):
            out.append(vals)
    return out

homs = homs_s3_to_z2()
assert len(homs) == 2
# sgn 同态：img = [id, (12), (13), (23), (123), (132)]，偶 ↦ 0、奇 ↦ 1
sgn_vals = (0, 1, 1, 1, 0, 0)
assert sgn_vals in homs and (0, 0, 0, 0, 0, 0) in homs
print("同态枚举：S₃ → ℤ₂ 恰 2 个（平凡与 sgn）✓")

print("END ====")
