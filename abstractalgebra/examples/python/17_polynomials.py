# 第 17 章 · 多项式环 —— Python 通道

from random import seed, randint
from sympy import symbols, expand, div, GF, Poly

print("==== 17 多项式环")


def trim(f):
    while len(f) > 1 and f[-1] == 0:
        f.pop()
    return f


def peval(f, a, p):
    v = 0
    for c in reversed(f):
        v = (v * a + c) % p
    return v


def polymul(f, g, p):
    r = [0] * (len(f) + len(g) - 1)
    for i, x in enumerate(f):
        for j, y in enumerate(g):
            r[i + j] = (r[i + j] + x * y) % p
    return trim(r)


def modinv(a, p):
    for b in range(1, p):
        if a * b % p == 1:
            return b
    raise ValueError


def polydiv_mod(f, g, p):
    g = trim(g[:])
    q = [0] * max(0, len(f) - len(g) + 1)
    r = trim(f[:])
    while len(r) >= len(g) and any(r):
        shift = len(r) - len(g)
        c = r[-1] * modinv(g[-1], p) % p
        q[shift] = c
        for j, gv in enumerate(g):
            r[shift + j] = (r[shift + j] - c * gv) % p
        trim(r)
    return trim(q), r


def polyadd(f, g, p):
    n = max(len(f), len(g))
    return trim([((f[i] if i < len(f) else 0) + (g[i] if i < len(g) else 0)) % p
                 for i in range(n)])


# ---------- 除法算式（sympy 对拍） ----------
x = symbols('x')
for _ in range(500):
    f = trim([randint(0, 6) for _ in range(randint(2, 6))])
    g = trim([randint(0, 6) for _ in range(2)])
    g[-1] = g[-1] or 1
    q, r = polydiv_mod(f, g, 7)
    # f = qg + r
    lhs = polyadd(polymul(q, g, 7), r, 7)
    fp = f + [0] * max(0, len(lhs) - len(f))
    assert trim(lhs) == trim(fp)
    assert len(r) < len(g) or not any(r)
print("除法算式：500 组随机（ℤ₇）f = qg + r 且 deg r < deg g ✓")

# sympy div 对拍
fq, fr = div(Poly(x ** 5 - 1, x, domain=GF(7)), Poly(x ** 2 + x + 1, x, domain=GF(7)))
assert fr.degree() < 2
print("sympy div：x⁵−1 ÷ x²+x+1 余式次数 < 2（ℤ₇）✓")

# ---------- 余式定理 ----------
for _ in range(100):
    f = trim([randint(0, 6) for _ in range(5)])
    a = randint(0, 6)
    xa = [(-a) % 7, 1]              # x − a
    _, r = polydiv_mod(f, xa, 7)
    assert r[0] == peval(f, a, 7)
print("余式定理：f mod (x−a) 的余数 = f(a)（100 组）✓")

# ---------- 次数塌缩：ℤ₄ 中 (2x+1)² = 1 ----------
sq = polymul([1, 2], [1, 2], 4)
assert sq == [1]
print("次数塌缩：ℤ₄[x] 中 (2x+1)² = 1 ✓")

# ---------- 形式 ≠ 函数 ----------
xs5 = [0, 4, 0, 0, 0, 1]           # x⁵ − x
assert all(peval(xs5, a, 5) == 0 for a in range(5))
assert any(xs5)
print("形式 ≠ 函数：x⁵ − x 在 ℤ₅ 逐点全 0，形式非零 ✓")

# ---------- 求值同态 ----------
for _ in range(100):
    f = trim([randint(0, 6) for _ in range(4)])
    g = trim([randint(0, 6) for _ in range(4)])
    a = randint(0, 6)
    fg = polyadd(f, g, 7)
    assert (peval(f, a, 7) + peval(g, a, 7)) % 7 == peval(fg, a, 7)
    assert peval(f, a, 7) * peval(g, a, 7) % 7 == peval(polymul(f, g, 7), a, 7)
print("求值同态：φₐ(f+g) 与 φₐ(fg)（100 组）✓")

print("END ====")
