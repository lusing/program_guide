# 第 38 章 · 广义的除法算式 —— Python 通道
#
# 自实现单项式序 + 多元除法，与 sympy 的 groebner.reduce 对拍。

import itertools
from fractions import Fraction as F

import sympy as sp

x, y = sp.symbols("x y")

print("==== 38 广义的除法算式")

# ---------- 单项式序（指数向量的比较器） ----------
def lex(a, b):
    return a > b                                # 元组字典序（先比首坐标）


def grlex(a, b):
    if sum(a) != sum(b):
        return sum(a) > sum(b)
    return a > b


def grevlex(a, b):
    if sum(a) != sum(b):
        return sum(a) > sum(b)
    # 平局：最后一个非零差（b−a）为正者大
    for i in reversed(range(len(a))):
        if a[i] != b[i]:
            return b[i] - a[i] > 0
    return False


# 序公理：反对称 / 完全 / 乘法相容（小规模全枚举）
for ordn in (lex, grlex, grevlex):
    mons = list(itertools.product(range(3), repeat=2))
    for a in mons:
        for b in mons:
            assert not (ordn(a, b) and ordn(b, a))
            assert ordn(a, b) or ordn(b, a) or a == b
            for c in mons:
                if ordn(a, b):
                    assert ordn(tuple(p + q for p, q in zip(a, c)),
                                tuple(p + q for p, q in zip(b, c)))
print("单项式序：lex/grlex/grevlex 反对称、完全、乘法相容（9 单项式全枚举）✓")

# ---------- 多项式 = dict 指数→系数 ----------
def P(*terms):
    d = {}
    for c, e in terms:
        if c:
            d[e] = d.get(e, 0) + c
    return {k: v for k, v in d.items() if v}


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


def leading(f, ordn):
    """多项式在序 ordn 下的首项 (c, e)。"""
    best = None
    for e in f:
        if best is None or ordn(e, best):
            best = e
    return f[best], best


def divide(f, gs, ordn):
    """多元除法（定理 7.60）：返回 (余式, 商列表)。"""
    r = {}
    qs = [{} for _ in gs]
    n = len(next(iter(f)))
    while f:
        moved = False
        for j, g in enumerate(gs):
            lc, le = leading(g, ordn)
            lfc, lfe = leading(f, ordn)
            if all(lfe[i] >= le[i] for i in range(n)):
                ec = tuple(lfe[i] - le[i] for i in range(n))
                coef = F(lfc, lc)
                f = padd(f, {tuple(p + q for p, q in zip(ec, k)): -coef * v
                             for k, v in g.items()})
                qs[j][ec] = qs[j].get(ec, 0) + coef
                moved = True
                break
        if not moved:
            lfc, lfe = leading(f, ordn)
            r[lfe] = r.get(lfe, 0) + lfc
            f = padd(f, {lfe: -lfc})
    return r, qs


# 原书例：f = x²y + xy² + y² 除以 [xy−1, y²−1]（lex）
f = P((1, (2, 1)), (1, (1, 2)), (1, (0, 2)))
g1 = P((1, (1, 1)), (-1, (0, 0)))
g2 = P((1, (0, 2)), (-1, (0, 0)))
r, q = divide(f, [g1, g2], lex)
assert r == P((1, (1, 0)), (1, (0, 1)), (1, (0, 0)))       # x + y + 1
# 分解恒等式 f = Σqᵢgᵢ + r
lhs = pmul(q[0], g1)
lhs = padd(lhs, pmul(q[1], g2))
lhs = padd(lhs, r)
assert lhs == f
print("多元除法：余式 x+y+1、恒等式 f = Σqᵢgᵢ + r（lex）✓")

# 顺序依赖：f = xy² − x
g = P((1, (1, 2)), (-1, (1, 0)))
h1 = P((1, (1, 1)), (1, (0, 0)))          # xy + 1
h2 = P((1, (0, 2)), (-1, (0, 0)))         # y² − 1
r1, _ = divide(g, [h1, h2], lex)
r2, _ = divide(g, [h2, h1], lex)
assert r1 == P((-1, (1, 0)), (-1, (0, 1)))                 # −x − y
assert r2 == {}                                            # 0
assert r1 != r2
print("顺序依赖：−x−y vs 0（余式不是理想成员判据——Grobner 动机）✓")

# ---------- 与 sympy 对拍 ----------
# sympy 的 Grobner 归约（基为 Grobner 时与手算一致）
G = sp.groebner([x * y + 1, y**2 - 1], x, y, order="lex")
expr = x * y**2 - x
qsy, rsy = G.reduce(expr)
assert sp.expand(rsy) == 0                    # Grobner 基下余式唯一为 0
# 手算 lex 余式 r2 = 0 与 sympy 一致
print("sympy 对拍：xy²−x mod Grobner([xy+1, y²−1]) = 0（与手算换序版一致）✓")

# 首项乘法相容的个案（命题 7.58）：lt(fg) = lt(f)·lt(g)
fa = P((2, (2, 1)), (3, (0, 0)))
fb = P((5, (1, 3)), (-7, (1, 0)))
assert leading(pmul(fa, fb), lex)[1] == (3, 4)
assert leading(fa, lex)[1] == (2, 1) and leading(fb, lex)[1] == (1, 3)
print("首项乘法：lt(fg) = lt(f)·lt(g)（命题 7.58 个案）✓")

print("END ====")
