# 第 33 章 · 西罗定理 —— Python 通道
#
# 共轭枚举数西罗（命题 6.17 机器化）+ 30/40/56 非单性 + UT(3,F_p) 案。

from sympy.combinatorics import (
    AlternatingGroup,
    DihedralGroup,
    Permutation,
    SymmetricGroup,
)

print("==== 33 西罗定理")


def sylow_count(G, p):
    """西罗 p-子群的个数 = 一个西罗子群的共轭个数（定理 6.19 + 命题 6.17）。"""
    P = G.sylow_subgroup(p)
    pelems = list(P.elements)
    conj = set()
    for g in G.elements:
        conj.add(frozenset(~g * x * g for x in pelems))
    return len(conj)


def pm_split(n, p):
    e, m = 0, n
    while m % p == 0:
        m //= p
        e += 1
    return e, m


def check_sylow(G, name):
    n = G.order()
    for p in sorted({q for q in range(2, n + 1) if n % q == 0 and
                     all(q % r for r in range(2, q))}):   # 素因子
        np_ = sylow_count(G, p)
        e, m = pm_split(n, p)
        assert G.sylow_subgroup(p).order() == p ** e      # 定理 6.21：阶 p^e
        assert np_ % p == 1                                # 定理 6.19：n_p ≡ 1 mod p
        assert m % np_ == 0                                # 定理 6.19：n_p | m
        print(f"  {name}: n_{p} = {np_} ≡ 1 (mod {p}) 且 | {m}")
    return True


check_sylow(SymmetricGroup(3), "S₃")
assert sylow_count(SymmetricGroup(3), 2) == 3
assert sylow_count(SymmetricGroup(3), 3) == 1

check_sylow(AlternatingGroup(4), "A₄")
assert sylow_count(AlternatingGroup(4), 2) == 1
assert sylow_count(AlternatingGroup(4), 3) == 4

check_sylow(SymmetricGroup(4), "S₄")
assert sylow_count(SymmetricGroup(4), 2) == 3
assert sylow_count(SymmetricGroup(4), 3) == 4

check_sylow(DihedralGroup(6), "D₆(六边形)")
assert sylow_count(DihedralGroup(6), 2) == 3
assert sylow_count(DihedralGroup(6), 3) == 1
print("共轭枚举：S₃/A₄/S₄/D₆ 的全部西罗数满足两条件（阶 = p^e 全核）✓")

# 推论 6.20：唯一西罗 ⟺ 正规（按定义验证：共轭后元素集不变）
A4 = AlternatingGroup(4)
V4 = frozenset(A4.sylow_subgroup(2).elements)
assert len(V4) == 4
assert all(frozenset(~g * x * g for x in V4) == V4 for g in A4.elements)
# 对照：S₃ 的西罗 2-子群不正规（n₂ = 3，共轭会搬家）
S3 = SymmetricGroup(3)
P2 = frozenset(S3.sylow_subgroup(2).elements)
assert any(frozenset(~g * x * g for x in P2) != P2 for g in S3.elements)
print("推论 6.20：A₄ 的 V₄ 共轭封闭（正规）；S₃ 的 2-子群共轭搬家（不正规）✓")

# ---------- 30/40/56 非单性 ----------
def sylow_candidates(m, p):
    return [d for d in range(1, m + 1) if m % d == 0 and d % p == 1]


assert sylow_candidates(6, 5) == [1, 6]                   # 30 的 n₅
assert sylow_candidates(10, 3) == [1, 10]                 # 30 的 n₃
assert sylow_candidates(8, 5) == [1]                      # 40 的 n₅ → 正规
assert sylow_candidates(8, 7) == [1, 8]                   # 56 的 n₇
# 30：n₅ = 6 与 n₃ = 10 时非单位元 24 + 20 = 44 > 29 超预算
assert 6 * 4 + 10 * 2 == 44 and 44 > 29
# 56：n₇ = 8 时 48 + 1 + 7 = 56 封顶，第二个西罗 2-子群必超
assert 8 * 6 + 1 + 7 == 56 and 8 * 6 + 1 + 7 + 1 > 56
print("非单性算术：30（44 > 29 超限）、40（n₅ = 1 正规）、56（56 封顶）✓")

# ---------- UT(3, F_p)：海森伯群的元组乘法 ----------
def ut_mul(x, y, p):
    a, b, c = x
    d, e, f = y
    return ((a + d) % p, (b + e) % p, (c + f + a * e) % p)


def ut_order(x, p):
    n, y = 1, x
    ident = (0, 0, 0)
    while y != ident:
        y = ut_mul(y, x, p)
        n += 1
    return n


for p in (2, 3):
    elems = [(a, b, c) for a in range(p) for b in range(p) for c in range(p)]
    assert len(elems) == p ** 3
    # 乘法封闭
    assert {ut_mul(x, y, p) for x in elems for y in elems} == set(elems)
    # 非交换：E₁₂ 与 E₂₃ 不对易（交换子 = E₁₃）
    x, y = (1, 0, 0), (0, 1, 0)
    assert ut_mul(x, y, p) != ut_mul(y, x, p)
    orders = sorted(ut_order(e, p) for e in elems)
    if p == 2:
        # (I+N)² = I + N²：恰两个 4 阶元——阶谱与 D₄ 相同（习题 2.123：≅ D₄）
        assert orders == [1, 2, 2, 2, 2, 2, 4, 4]
    else:
        # 奇素数：(I+N)^p = I ⟹ 阶谱与 (ℤ/p)³ 全同，但群非阿贝尔
        #（命题 6.29 + 其后注记：阶档案不是一般群的完全不变量）
        assert orders == [1] + [3] * 26
print("UT(3,F_p)：p=2 阶谱同 D₄（≅ D₄）；p=3 阶谱同 (ℤ/3)³ 但非阿贝尔 ✓")

# ---------- |GL(n, F_q)|（定理 6.30） ----------
def gl_order(n, q):
    prod = 1
    for i in range(n):
        prod *= q ** n - q ** i
    return prod


assert gl_order(2, 2) == 6 and gl_order(3, 2) == 168
assert gl_order(2, 3) == (9 - 1) * (9 - 3) == 48
# UT(3, F_q) 阶 q³ 是 GL(3, F_q) 的西罗 p-子群（q = 2：8 | 168）
assert gl_order(3, 2) == 21 * 8
print("|GL(2,F₂)| = 6、|GL(3,F₂)| = 168 = 21·8、|GL(2,F₃)| = 48 ✓")

print("END ====")
