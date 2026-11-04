# 第 19 章 · 根与因子 —— Python 通道

from random import seed, randint
from sympy import Poly, symbols, div, GF, divisors, Rational, interpolate, factorint

print("==== 19 从数到多项式")


def peval(f, a, p):
    v = 0
    for c in reversed(f):
        v = (v * a + c) % p
    return v


def roots_of(f, p):
    return [a for a in range(p) if peval(f, a, p) == 0]


# 根穷举
assert roots_of([0, 6, 0, 1], 7) == [0, 1, 6]
assert roots_of([7, 0, 1], 8) == [1, 3, 5, 7]
print("x³−x (mod 7) 恰 3 根；x²−1 (mod 8) 恰 4 根（反例）✓")

# 有理根定理
cands = [1, -1, 3, -3, Rational(1, 2), Rational(-1, 2), Rational(3, 2), Rational(-3, 2)]
fev = lambda x: 2 * x ** 3 + x - 3
hit = [x for x in cands if fev(x) == 0]
assert hit == [1]
print("有理根定理：2x³+x−3 的候选 8 个恰 x = 1 ✓")

# sympy roots 对拍
x = symbols('x')
for _ in range(50):
    f = [randint(0, 6) for _ in range(5)]
    f[-1] = f[-1] or 1
    mine = sorted(roots_of(f, 7))
    # 对拍 sympy：因子化后数一次因子
    p7 = Poly(sum(c * x ** i for i, c in enumerate(f)), x, domain=GF(7))
    facs = p7.factor_list()[1]
    # 一次因子 (x − a) 对应根 a
    lib = []
    for fac, mult in facs:
        cs = fac.all_coeffs()          # 高位在前
        if len(cs) == 2:               # 一次
            a = (-cs[1] * pow(cs[0], -1, 7)) % 7
            lib += [a] * mult
    assert sorted(set(lib)) == mine, (f, sorted(lib), mine)
print("根穷举 × sympy factor_list：50 组一致（ℤ₇）✓")


# 欧几里得 + 贝祖
def trim(f):
    while len(f) > 1 and f[-1] == 0:
        f.pop()
    return f


def polymul(f, g, p):
    r = [0] * (len(f) + len(g) - 1)
    for i, a in enumerate(f):
        for j, b in enumerate(g):
            r[i + j] = (r[i + j] + a * b) % p
    return trim(r)


def polydiv_mod(f, g, p):
    g = trim(g[:])
    q = [0] * max(0, len(f) - len(g) + 1)
    r = trim(f[:])
    while len(r) >= len(g) and any(r):
        s = len(r) - len(g)
        c = r[-1] * pow(g[-1], -1, p) % p
        q[s] = c
        for j, gv in enumerate(g):
            r[s + j] = (r[s + j] - c * gv) % p
        trim(r)
    return trim(q), r


def polyadd(f, g, p):
    n = max(len(f), len(g))
    return trim([((f[i] if i < len(f) else 0) + (g[i] if i < len(g) else 0)) % p
                 for i in range(n)])


def poly_extgcd(f, g, p):
    old_r, r = trim(f[:]), trim(g[:])
    old_s, s = [1], [0]
    old_t, t = [0], [1]
    while any(r):
        q, rem = polydiv_mod(old_r, r, p)
        old_r, r = r, rem
        old_s, s = s, polyadd(old_s, [(-c) % p for c in polymul(q, s, p)], p)
        old_t, t = t, polyadd(old_t, [(-c) % p for c in polymul(q, t, p)], p)
    return old_r, old_s, old_t


f2, g2 = [1, 0, 1], [2, 1]
d2, s2, t2 = poly_extgcd(f2, g2, 5)
assert polyadd(polymul(s2, f2, 5), polymul(t2, g2, 5), 5) == d2
print("贝祖回代：s(x)(x²+1)+t(x)(x+2) = gcd（ℤ₅）✓")

seed(20261104)
for _ in range(50):
    f1 = trim([randint(0, 4) for _ in range(randint(2, 4))])
    g1 = trim([randint(0, 4) for _ in range(2)])
    g1[-1] = g1[-1] or 1
    d1, s1, t1 = poly_extgcd(f1, g1, 5)
    assert polyadd(polymul(s1, f1, 5), polymul(t1, g1, 5), 5) == d1
print("贝祖恒等式：50 组随机对成立（ℤ₅）✓")

# 拉格朗日插值（sympy 对拍）
pts = [(1, 2), (2, 4), (3, 0)]
p_poly = interpolate(pts, x)
assert p_poly.subs(x, 1) == 2 and p_poly.subs(x, 2) == 4 and p_poly.subs(x, 3) == 0
print("拉格朗日插值：sympy interpolate 过三点 ✓")

# ---------- 高斯整数 ℤ[i]：欧几里得除法、四商例与二平方和 ----------

def gi_norm(a, b):
    return a * a + b * b

def nearest(q):
    """最近整数（有理数四舍五入；±1/2 居中任取一侧——商本就不唯一）。"""
    fl = q.numerator // q.denominator
    return fl + 1 if (q - fl) * 2 > 1 else fl

def gauss_divide(a1, b1, a2, b2):
    """α = βq + r（例 3.77 的最近整点路线），返回 (m, n, ra, rb)。"""
    from fractions import Fraction as Fr
    d = gi_norm(a2, b2)
    xr = Fr(a1 * a2 + b1 * b2, d)     # α/β = αβ̄/∂(β)
    yr = Fr(b1 * a2 - a1 * b2, d)
    m, n = nearest(xr), nearest(yr)
    ra, rb = a1 - (a2 * m - b2 * n), b1 - (a2 * n + b2 * m)
    return (m, n, ra, rb)

# 书例四商：3+5i = 2q + r 的四种分解（每个 ∂(r) = 2 < 4）
for (m, n, ra, rb) in [(1, 2, 1, 1), (1, 3, 1, -1), (2, 2, -1, 1), (2, 3, -1, -1)]:
    assert complex(3, 5) == complex(2, 0) * complex(m, n) + complex(ra, rb)
    assert gi_norm(ra, rb) < gi_norm(2, 0)
# 欧几里得公理 (ii)：40 对随机 α, β（精确有理最近整点）
from random import randint
for _ in range(40):
    a1, b1, a2, b2 = (randint(-9, 9) for _ in range(4))
    if (a2, b2) == (0, 0):
        continue
    m, n, ra, rb = gauss_divide(a1, b1, a2, b2)
    assert complex(a1, b1) == complex(a2, b2) * complex(m, n) + complex(ra, rb)
    assert gi_norm(ra, rb) < gi_norm(a2, b2)
# 公理 (i)：范数乘性
for _ in range(20):
    a1, b1, a2, b2 = (randint(-6, 6) for _ in range(4))
    assert gi_norm(a1 * a2 - b1 * b2, a1 * b2 + b1 * a2) == gi_norm(a1, b1) * gi_norm(a2, b2)
print("例 3.77：四商恒等式 + 40 对随机高斯除法 + 范数乘性 ✓")

# 费马二平方和（定理 3.83）+ 引理 3.82 见证 + sympy 对拍
for (p, m) in [(5, 2), (13, 5), (17, 4), (29, 12), (41, 9), (61, 11)]:
    assert p % 4 == 1 and (m * m) % p == p - 1
    rep = next((a, b) for a in range(1, p) for b in range(a + 1) if a * a + b * b == p)
    assert sum(t * t for t in rep) == p
    assert factorint(p)[p] == 1 and rep[0] ** 2 + rep[1] ** 2 == p     # sympy 复核素性与表示
for p in (3, 7, 11, 19):
    assert p % 4 == 3
    assert not any(a * a + b * b == p for a in range(p) for b in range(a + 1))
print("定理 3.83：p ≡ 1 (mod 4) 六例有表示（引理 3.82 见证 m）；p ≡ 3 (mod 4) 四例无表示 ✓")

print("END ====")
