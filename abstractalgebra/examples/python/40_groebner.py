# 第 40 章 · 格罗布纳基 —— Python 通道
#
# 自实现 S-多项式 + Buchberger，与 sympy.groebner 全面对拍 +
# 三个应用（成员 / 相等 / 消元解方程）。

import itertools
from fractions import Fraction as F

import sympy as sp

x, y = sp.symbols("x y")

print("==== 40 格罗布纳基")

# ---------- 多项式机器（与第 39 章同构） ----------
def P(*terms):
    d = {}
    for c, e in terms:
        if c:
            d[e] = d.get(e, 0) + c
    return {k: v for k, v in d.items() if v}


def lex(a, b):
    return a > b


def padd(f, g):
    h = dict(f)
    for e, c in g.items():
        h[e] = h.get(e, 0) + c
        if h[e] == 0:
            del h[e]
    return h


def pmul(f, g):
    h = {}
    for e1, c1 in f.items():
        for e2, c2 in g.items():
            e = tuple(p + q for p, q in zip(e1, e2))
            h[e] = h.get(e, 0) + c1 * c2
            if h[e] == 0:
                del h[e]
    return h


def leading(f, ordn=lex):
    best = None
    for e in f:
        if best is None or ordn(e, best):
            best = e
    return f[best], best


def rem(f, gs, ordn=lex):
    r = {}
    n = len(next(iter(f))) if f else 0
    while f:
        moved = False
        for g in gs:
            lc, le = leading(g, ordn)
            lfc, lfe = leading(f, ordn)
            if all(lfe[i] >= le[i] for i in range(n)):
                ec = tuple(lfe[i] - le[i] for i in range(n))
                coef = F(lfc, lc)
                f = padd(f, {tuple(p + q for p, q in zip(ec, k)): -coef * v
                             for k, v in g.items()})
                moved = True
                break
        if not moved:
            lfc, lfe = leading(f, ordn)
            r[lfe] = r.get(lfe, 0) + lfc
            f = padd(f, {lfe: -lfc})
    return r


def spoly(f, g, ordn=lex):
    """S(f, g)：首单项式 lcm 上的相消组合。"""
    lf, lg = leading(f, ordn), leading(g, ordn)
    L = tuple(max(p, q) for p, q in zip(lf[1], lg[1]))
    return padd(pmul({tuple(p - q for p, q in zip(L, lf[1])): F(1, lf[0])}, f),
                pmul({tuple(p - q for p, q in zip(L, lg[1])): F(-1, lg[0])}, g))


def buchberger(gs, ordn=lex):
    gs = [dict(g) for g in gs]
    changed = True
    while changed:
        changed = False
        for i, j in itertools.combinations(range(len(gs)), 2):
            s = spoly(gs[i], gs[j], ordn)
            if not s:
                continue
            r = rem(s, gs, ordn)
            if r:
                gs.append(r)
                changed = True
    return gs


# ---------- 非基判定与算法 ----------
h1 = P((1, (2, 0)), (1, (0, 0)))                 # x² + 1
h2 = P((1, (1, 1)), (-1, (0, 0)))                # xy − 1
s = spoly(h1, h2)
assert s == P((1, (1, 0)), (1, (0, 1)))          # S = x + y
assert rem(s, [h1, h2]) == s                     # 余式非零 ⟹ 非 Grobner 基
GB = buchberger([h1, h2])
assert P((1, (1, 0)), (1, (0, 1))) in GB         # x+y 补入
# 判据复核：所有 S-余式为零
for i, j in itertools.combinations(range(len(GB)), 2):
    assert not spoly(GB[i], GB[j]) or not rem(spoly(GB[i], GB[j]), GB)
print("Buchberger：{x²+1, xy−1} → 4 元基；判据（定理 7.67）复核全过 ✓")

# ---------- 与 sympy.groebner 对拍 ----------
for gens_sympy in ([x**2 + 1, x * y - 1],
                   [x * y + 1, y**2 - 1],
                   [x**2 + y**2 - 1, x - y],
                   [y**2, x * y]):
    mine = buchberger([P(*[(int(c), sp.Poly(g, x, y).monoms()[k]) for k, c in enumerate(sp.Poly(g, x, y).coeffs())])
                       for g in gens_sympy])
    # sympy 的（既约）基首项集合 ⊆ 我的基首项集合（同一理想的不同基）
    Gs = sp.groebner(gens_sympy, x, y, order="lex")
    sympy_lts = {g.monoms()[0] for g in Gs.polys}
    mine_lts = {leading(g)[1] for g in mine}
    assert sympy_lts <= mine_lts
    # 成员判定一致：每个 sympy 生成元 mod 我的基余式为零
    for gexpr in gens_sympy:
        gdict = P(*[(int(c), sp.Poly(gexpr, x, y).monoms()[k])
                    for k, c in enumerate(sp.Poly(gexpr, x, y).coeffs())])
        assert not rem(gdict, mine)
print("对拍：4 组理想——sympy 既约基首项 ⊆ 我的基首项、成员判定一致 ✓")

# ---------- 应用一：理想成员（推论 7.63） ----------
GBe = buchberger([P((1, (1, 1)), (1, (0, 0))), P((1, (0, 2)), (-1, (0, 0)))])
t = P((1, (1, 2)), (-1, (1, 0)))                 # xy² − x
assert not rem(t, GBe)                           # ∈ I
assert rem(P((1, (1, 0))), GBe)                  # x ∉ I
print("理想成员：xy²−x ∈ (xy+1, y²−1)（余式 0）；x ∉（余式非零）✓")

# ---------- 应用二：理想相等 ----------
I1 = [P((1, (1, 0)), (1, (0, 1))), P((1, (1, 0)), (-1, (0, 1)))]   # x+y, x−y
I2 = [P((1, (1, 0))), P((1, (0, 1)))]                              # x, y
GB1, GB2 = buchberger(I1), buchberger(I2)
assert all(not rem(g, GB2) for g in I1)
assert all(not rem(g, GB1) for g in I2)
print("理想相等：(x+y, x−y) = (x, y)（½ 系数双向整除）✓")

# ---------- 应用三：消元解方程 ----------
p1 = P((1, (2, 0)), (1, (0, 2)), (-1, (0, 0)))   # x² + y² − 1
p2 = P((1, (1, 0)), (-1, (0, 1)))                # x − y
GBs = buchberger([p1, p2])
only_y = [g for g in GBs if all(e[0] == 0 for e in g)]
assert P((2, (0, 2)), (-1, (0, 0))) in only_y    # 2y² − 1
print("消元：lex 基含 2y²−1（纯 y）⟹ y = ±1/√2、x = y ✓")

print("END ====")
