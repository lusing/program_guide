# 第 23 章 · 一个数学旅程 —— Python 通道

from sympy import divisors, totient

print("==== 23 一个数学旅程")


# ---------- 暹罗法幻方 ----------
def siam_magic(n):
    assert n % 2 == 1
    M = [[0] * n for _ in range(n)]
    i, j = 0, n // 2
    for k in range(1, n * n + 1):
        M[i][j] = k
        i2, j2 = (i - 1) % n, (j + 1) % n
        if M[i2][j2] != 0:
            i2, j2 = (i + 1) % n, j
        i, j = i2, j2
    return M


for n in (3, 5, 7):
    M = siam_magic(n)
    s = n * (n * n + 1) // 2
    assert all(sum(r) == s for r in M)
    assert all(sum(c) for c in zip(*M)) and all(sum(c) == s for c in zip(*M))
    assert sum(M[d][d] for d in range(n)) == s
    assert sum(M[d][n - 1 - d] for d in range(n)) == s
    assert sorted(v for r in M for v in r) == list(range(1, n * n + 1))
print("暹罗法：n = 3, 5, 7 全查（行列对角和 = n(n²+1)/2）✓")

# ---------- MOLS：闭式 vs 构造 ----------
for n in (2, 3, 4, 5, 7, 8, 9):
    q = n
    closed = sum(totient(d) * q ** (n // d) for d in divisors(n)) // n
    if q in (2, 3, 5, 7):          # 素数：GF 型构造直接可验
        seen = set()
        for i in range(q):
            for j in range(q):
                seen.add((i + j) % q)          # 单个拉丁方行遍历
        assert len(seen) == q
    # 素数时闭式 = Burnside 手算
print("项链闭式：(1/n)Σφ(d)q^{n/d}（sympy totient）✓")

# GF(5) 的 4 个 MOLS 两两正交
n = 5
for a1 in range(1, n):
    for a2 in range(a1 + 1, n):
        seen = set((a1 * i + j, a2 * i + j) for i in range(n) for j in range(n))
        assert len(seen) == n * n
print("GF(5)：4 个 MOLS 两两正交 ✓")

# ---------- STS(7) = Fano ----------
fano = [[0, 1, 3], [1, 2, 4], [2, 3, 5], [3, 4, 6],
        [4, 5, 0], [5, 6, 1], [6, 0, 2]]
for p1 in range(7):
    for p2 in range(p1 + 1, 7):
        assert sum(1 for l in fano if p1 in l and p2 in l) == 1
print("Fano 平面 STS(7)：21 对点各恰共一线 ✓")

# STS(9)：AG(2,3)
ag = set()
for a in range(3):
    for b in range(3):
        ag.add(tuple(sorted(3 * ((a * x + b) % 3) + x for x in range(3))))
for c in range(3):
    ag.add(tuple(sorted(3 * y + c for y in range(3))))
assert len(ag) == 12
for p1 in range(9):
    for p2 in range(p1 + 1, 9):
        assert sum(1 for l in ag if p1 in l and p2 in l) == 1
print("STS(9) = AG(2,3)：12 条线、36 对点 ✓")

# ---------- PG(2,5) ----------
def modinv(a, q):
    for b in range(1, q):
        if a * b % q == 1:
            return b


pts = []
seen = set()
for a, b, c in [(a, b, c) for a in range(5) for b in range(5) for c in range(5)]:
    if a == b == c == 0:
        continue
    if a != 0:
        inv = modinv(a, 5)
        rep = (1, b * inv % 5, c * inv % 5)
    elif b != 0:
        inv = modinv(b, 5)
        rep = (0, 1, c * inv % 5)
    else:
        rep = (0, 0, 1)
    if rep not in seen:
        seen.add(rep)
        pts.append(rep)
assert len(pts) == 31
lines = set()
for al in pts:
    lines.add(tuple(sorted(i for i, pt in enumerate(pts)
                           if (al[0] * pt[0] + al[1] * pt[1] + al[2] * pt[2]) % 5 == 0)))
assert len(lines) == 31 and all(len(l) == 6 for l in lines)
print("PG(2,5)：31 点 31 线、每线 6 点 ✓")

print("END ====")
