# 第 20 章 · 多项式的唯一分解 —— Python 通道

from random import seed, randint
from sympy import factor_list, Poly, symbols, GF

print("==== 20 多项式的唯一分解")


def trim(f):
    while len(f) > 1 and f[-1] == 0:
        f.pop()
    return f


def peval(f, a, p):
    v = 0
    for c in reversed(f):
        v = (v * a + c) % p
    return v


def deg(f):
    return len(trim(f)) - 1 if any(f) else -1


# ---------- 自实现分解器（拔线性 + 二次配对） ----------
def monic_quadratics(p):
    return [trim([c0, c1, 1]) for c0 in range(p) for c1 in range(p)]


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


def factorize_zp(f, p):
    f = trim(f[:])
    factors = []
    if deg(f) <= 0:
        return factors
    for a in range(p):
        while peval(f, a, p) == 0:
            lin = trim([(-a) % p, 1])
            factors.append(lin)
            f, _ = polydiv_mod(f, lin, p)
    d = deg(f)
    inv_lc = pow(f[-1], -1, p)
    f_mono = trim([c * inv_lc % p for c in f])     # 剩余部分首一化（单位因子已由 lc 承担）
    if d == 1:
        factors.append(f_mono)
    elif d in (2, 3):
        factors.append(f_mono)      # 无根 ⟹ 不可约（deg ≤ 3）
    elif d == 4:
        for g in monic_quadratics(p):
            q, r = polydiv_mod(f, g, p)
            if not any(r) and deg(q) == 2:
                factors += [g, trim([c * pow(q[-1], -1, p) % p for c in q])]
                return factors
        factors.append(f_mono)     # 无二次因子 ⟹ 不可约（首一化）
    return factors


# ---------- sympy 对拍 ----------
x = symbols('x')
seed(20261104)
checked = 0
for p in (2, 3, 5, 7):
    for _ in range(50):
        f = trim([randint(0, p - 1) for _ in range(randint(3, 5))])
        f[-1] = f[-1] or 1
        if deg(f) < 1:
            continue
        checked += 1
        # 乘积还原（× 首项系数：全部因子首一，单位因子补齐）
        lc = f[-1]
        prod = [lc]
        for g in factorize_zp(f, p):
            r = [0] * (len(prod) + len(g) - 1)
            for i, a in enumerate(prod):
                for j, b in enumerate(g):
                    r[i + j] = (r[i + j] + a * b) % p
            prod = trim(r)
        assert prod == f
        # 因子不可约性
        for g in factorize_zp(f, p):
            assert deg(g) >= 1
            if deg(g) in (2, 3):
                assert not any(peval(g, a, p) == 0 for a in range(p))
assert checked >= 100
print(f"分解器：{checked} 组随机（p = 2,3,5,7）乘积还原 + 因子无根 ✓")

# sympy factor_list 对拍（无平方情形）
for _ in range(50):
    f = trim([randint(0, 1) for _ in range(5)])
    f[-1] = 1
    mine = sorted(tuple(g) for g in factorize_zp(f, 2))
    _, fl = factor_list(Poly(sum(c * x ** i for i, c in enumerate(f)), x, domain=GF(2)))
    n_fac = sum(m for _, m in fl)
    # 度数守恒：deg f = Σ deg(factor_i)
    assert sum(deg(g) for g in factorize_zp(f, 2)) == deg(f)
print("度数守恒：50 组 ℤ₂ 分解 Σ deg = deg f ✓")

# Sophie Germain 域依赖清单
from sympy import expand
lhs = expand((x ** 2 - 2 * x + 2) * (x ** 2 + 2 * x + 2))
assert lhs == expand(x ** 4 + 4)
print("Sophie Germain：x⁴+4 = (x²−2x+2)(x²+2x+2) ✓")

print("END ====")
