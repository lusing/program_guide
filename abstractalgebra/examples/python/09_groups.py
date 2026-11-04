# 第 09 章 · 群的定义与例子 —— Python 通道
#
# 凯莱表检查器 + 三族构造 + D₃≅S₃ + 元素阶表 + 定理 2.63 关系。

from math import gcd

print("==== 09 群的定义与例子")


def is_group(tbl):
    n = len(tbl)
    flat = [x for row in tbl for x in row]
    if not all(0 <= x < n for x in flat):        # 0 基编号
        return False
    ident = None
    for i in range(n):
        if tbl[i] == list(range(n)) and [tbl[k][i] for k in range(n)] == list(range(n)):
            ident = i
            break
    if ident is None:
        return False
    for i in range(n):
        if not any(tbl[i][j] == ident for j in range(n)):
            return False
    return all(tbl[tbl[i][j]][k] == tbl[i][tbl[j][k]]
               for i in range(n) for j in range(n) for k in range(n))


def identity_of(tbl):
    n = len(tbl)
    for i in range(n):
        if tbl[i] == list(range(n)) and [tbl[k][i] for k in range(n)] == list(range(n)):
            return i
    raise ValueError


def order_of(tbl, x):
    e = identity_of(tbl)
    k, cur = 1, x
    while cur != e:
        cur = tbl[x][cur]
        k += 1
    return k


def itpow(tbl, x, k):
    e = identity_of(tbl)
    r = e
    for _ in range(k):
        r = tbl[x][r]
    return r


zn_add = lambda n: [[(i + j) % n for j in range(n)] for i in range(n)]


def un_mul(m):
    U = [k for k in range(1, m + 1) if gcd(k, m) == 1]
    idx = {v: i for i, v in enumerate(U)}
    return [[idx[(U[i] * U[j]) % m] for j in range(len(U))] for i in range(len(U))]


def dihedral(n):
    tbl = [[0] * (2 * n) for _ in range(2 * n)]
    for i in range(n):
        for j in range(2):
            for k in range(n):
                for l in range(2):
                    if j == 0:
                        r, s = (i + k) % n, l
                    else:
                        r, s = (i - k) % n, 1 - l
                    idx = r if s == 0 else n + r
                    x = i if j == 0 else n + i
                    y = k if l == 0 else n + k
                    tbl[x][y] = idx
    return tbl


for tbl in (zn_add(5), zn_add(12), un_mul(8), un_mul(10), dihedral(3), dihedral(4)):
    assert is_group(tbl)
print("群公理检查器：ℤ₅、ℤ₁₂、U(8)、U(10)、D₃、D₄ 全过（含 O(n³) 结合律）✓")

# D₃ = S₃ 复合表
img = [(1, 2, 3), (2, 3, 1), (3, 1, 2), (2, 1, 3), (3, 2, 1), (1, 3, 2)]
d3 = dihedral(3)
for i in range(6):
    for j in range(6):
        prod = tuple(img[i][img[j][k] - 1] for k in range(3))
        assert img[d3[i][j]] == prod
print("D₃ 的表 = S₃ 的置换复合表 ✓")

# 元素阶
assert sorted(order_of(un_mul(8), i) for i in range(4)) == [1, 2, 2, 2]
assert max(order_of(un_mul(10), i) for i in range(4)) == 4
z12 = zn_add(12)
assert [order_of(z12, i) for i in range(12)] == [1, 12, 6, 4, 3, 12, 2, 12, 3, 4, 6, 12]
print("元素阶：U(8) 全 2 阶；U(10) 有 4 阶元；ℤ₁₂ 阶表 = 12/gcd ✓")

# 定理 2.63 关系（0 基编号：α = 1，b = n）
for n in range(3, 7):
    tbl = dihedral(n)
    e = identity_of(tbl)
    a, b = 1, n
    assert itpow(tbl, a, n) == e
    assert tbl[b][b] == e
    assert tbl[tbl[b][a]][b] == itpow(tbl, a, n - 1)   # bab = α⁻¹
print("定理 2.63 关系 αⁿ = b² = 1，bab = α⁻¹ 在 D₃..D₆ 表上成立 ✓")

# 非阿贝尔现场
a, b = 1, 3
assert itpow(d3, d3[a][b], 2) != d3[itpow(d3, a, 2)][itpow(d3, b, 2)]
print("非阿贝尔现场：D₃ 中 (αb)² ≠ α²b² ✓")

print("END ====")
