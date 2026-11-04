# 第 30 章 · 经典公式 —— Python 通道
#
# sympy 精确代数 与 自实现 cardano/ferrari 数值对拍。

import cmath
import random

import sympy as sp

x, t = sp.symbols("x t")

print("==== 30 经典公式")

# ---------- depressed cubic（精确） ----------
# 手工代入 x = t+2：x³−6x²+11x−6 = t³ − t
shifted = sp.expand((t + 2) ** 3 - 6 * (t + 2) ** 2 + 11 * (t + 2) - 6)
assert shifted == t**3 - t
# 与 depress 公式 p = b − a²/3、q = 2a³/27 − ab/3 + c 一致（a=−6, b=11, c=−6）
a0, b0, c0 = sp.Rational(-6), sp.Rational(11), sp.Rational(-6)
assert b0 - a0**2 / 3 == -1
assert 2 * a0**3 / 27 - a0 * b0 / 3 + c0 == 0
print("depressed 化归：x³−6x²+11x−6 --(x=t+2)--> t³ − t（sympy 精确展开）✓")

# ---------- 卡尔达诺（数值实现；与 julia 通道同构） ----------
def cardano_num(p, q):
    """v = −p/(3u) 锁死约束 3uv = −p（⟹ v³ = B = −p³/(27A)）。"""
    Δ = q * q / 4 + p * p * p / 27
    A = complex(-q / 2, 0) + cmath.sqrt(Δ)
    u = A ** (1 / 3)
    v = -p / (3 * u)
    ω = cmath.exp(2j * cmath.pi / 3)
    return [u * ω**k + v * ω**(-k) for k in range(3)]


# t³−7t+6：根 −3, 1, 2（Δ = 9 − 343/27 < 0，复路取实部）
roots = sorted(r.real for r in cardano_num(-7.0, 6.0))
for r in roots:
    assert abs(r**3 - 7 * r + 6) < 1e-9
assert abs(roots[0] + 3) < 1e-6 and abs(roots[1] - 1) < 1e-6 and abs(roots[2] - 2) < 1e-6
# t³−1（Δ > 0）：根 1, ω, ω²
for z in cardano_num(0.0, -1.0):
    assert abs(z**3 - 1) < 1e-12
print("卡尔达诺数值：t³−7t+6 三根 {-3,1,2}（Δ<0）与 t³−1 根 1,ω,ω²（Δ>0）✓")

# sympy nroots 对拍（随机 200 组三次；重根案例上 mpmath 高精度反而不收敛，
# 用默认精度 + 放宽步数）
random.seed(20261104)
for _ in range(200):
    a, b, c = random.randint(-4, 4), random.randint(-6, 6), random.randint(-6, 6)
    poly = sp.Poly(x**3 + a * x**2 + b * x + c, x)
    for s in poly.nroots(maxsteps=200):
        assert abs(complex(poly.eval(s))) < 1e-10
print("sympy nroots 对拍：随机三次 200 组逐根残差 < 1e-10 ✓")

# ---------- 判别式分类：Δ 的符号 ⟺ 实根个数 ----------
def disc3(p, q):
    return sp.Rational(q) ** 2 / 4 + sp.Rational(p) ** 3 / 27


for p_, q_ in [(3, 2), (1, 0), (-3, 0), (-3, 1)]:
    nreal = sum(1 for r in sp.nroots(t**3 + p_ * t + q_)
                if abs(sp.im(r)) < 1e-12)
    d = disc3(p_, q_)
    assert (nreal == 3) == (d < 0)      # Δ<0 ⟺ 三实根；Δ>0 ⟺ 一实根
print("判别式分类：t³+3t+2 / t³+t（Δ>0 一实根）、t³−3t / t³−3t+1"
      "（Δ<0 三实根，末者为不可约情形）✓")

# ---------- 韦达定理 + 牛顿对称函数 ----------
for _ in range(50):
    r1, r2, r3 = random.randint(-5, 5), random.randint(-5, 5), random.randint(-5, 5)
    f = sp.expand((x - r1) * (x - r2) * (x - r3))
    assert sp.expand(f.subs(x, r1)) == 0
    assert f.coeff(x, 2) == -(r1 + r2 + r3)          # e1 = −a2
    assert f.coeff(x, 1) == r1 * r2 + r1 * r3 + r2 * r3   # e2 = a1
    assert f.coeff(x, 0) == -r1 * r2 * r3            # e3 = −a0
    # 牛顿恒等式：p1 = e1、p2 = e1² − 2e2、p3 = e1³ − 3e1e2 + 3e3
    e1 = r1 + r2 + r3
    e2 = r1 * r2 + r1 * r3 + r2 * r3
    e3 = r1 * r2 * r3
    assert r1**2 + r2**2 + r3**2 == e1**2 - 2 * e2
    assert r1**3 + r2**3 + r3**3 == e1**3 - 3 * e1 * e2 + 3 * e3
print("韦达 + 牛顿对称函数：随机 50 组幂和 p1/p2/p3 恒等式 ✓")

# ---------- 费拉里（sympy 精确） ----------
def ferrari_exact(p, q, r):
    """预解三次 s³ − ps² − 4rs + (4rp − q²) = 0；任一实根化两个二次。"""
    s = sp.symbols("s")
    res = s**3 - p * s**2 - 4 * r * s + (4 * r * p - q**2)
    sroot = [z for z in sp.solve(res, s) if z.is_real][-1]
    A, B, C = sroot - p, -q, sroot**2 / 4 - r
    assert sp.expand(B**2 - 4 * A * C) == 0          # 完全平方（精确零）
    m = -B / (2 * A)
    sqA = sp.sqrt(A)
    out = []
    for sgn in (+1, -1):
        bq = -sgn * sqA
        cq = sroot / 2 + sgn * sqA * m
        # sp.roots 带重数（solve 会把 (x−2)²=0 去重成单根）
        for rt, mult in sp.roots(x**2 + bq * x + cq, x).items():
            out += [rt] * mult
    return sp.expand(sp.prod(x - z for z in out))


# x⁴ − 9x² + 4x + 12 = (x+3)(x+1)(x−2)²
assert ferrari_exact(sp.Integer(-9), sp.Integer(4), sp.Integer(12)) \
    == x**4 - 9 * x**2 + 4 * x + 12
# x⁴ − 5x² + 4（q = 0 退化）
assert ferrari_exact(sp.Integer(-5), sp.Integer(0), sp.Integer(4)) \
    == x**4 - 5 * x**2 + 4
print("费拉里精确：预解三次 + 完全平方判别 = 0（符号零），"
      "两案四根回乘还原原多项式 ✓")

# sympy.factor 对拍
assert sp.factor(x**4 - 9 * x**2 + 4 * x + 12) == (x + 3) * (x + 1) * (x - 2) ** 2
assert sp.factor(x**4 - 5 * x**2 + 4) == (x - 1) * (x + 1) * (x - 2) * (x + 2)
print("对拍：sympy.factor 与费拉里四根一致 ✓")

print("END ====")
