# 第 35 章 · 唯一分解整环 —— Python 通道

import math
import random

import sympy as sp
from sympy import factorint

x, y = sp.symbols("x y")

print("==== 35 唯一分解整环")

# ---------- ℤ：UFD 原型 ----------
assert factorint(360) == {2: 3, 3: 2, 5: 1}
for n in range(2, 300):
    m = 1
    for p, e in factorint(n).items():
        m *= p**e
    assert m == n

# gcd = min 指数（命题 7.17）
for a in range(1, 80):
    for b in range(1, 80):
        g = 1
        for p in set(factorint(a)) & set(factorint(b)):
            g *= p ** min(factorint(a)[p], factorint(b)[p])
        assert g == math.gcd(a, b)
print("ℤ 分解与 gcd：2..300 重组还原；gcd = min 指数全对拍 ✓")

# ---------- 高斯引理（引理 7.19/7.20） ----------
def content_poly(f):
    """ℤ 系数多项式的内容（系数 gcd）。"""
    cfs = [int(c) for c in sp.Poly(f, x).all_coeffs()]
    c = 0
    for c0 in cfs:
        c = math.gcd(c, abs(c0))
    return c


random.seed(20261104)
for _ in range(200):
    f = sum(random.randint(-6, 6) * x**i for i in range(3))
    g = sum(random.randint(-6, 6) * x**i for i in range(3))
    if f == 0 or g == 0:
        continue
    assert content_poly(sp.expand(f * g)) == content_poly(f) * content_poly(g)
print("高斯引理：c(fg) = c(f)c(g)（随机 200 组）✓")

# ---------- R UFD ⟹ R[x] UFD（定理 7.21）----------
# ℤ[x] 中：分解 → 内容提出 → 本原部分分解在 ℚ[x] 上收回
#（注意 2*(x−1)*(x+1) 会被自动吸收成 (x+1)*(2x−2)，用差为零判定）
f = 6 * x**2 + 12 * x + 6                        # 6(x+1)²
assert sp.expand(sp.factor(f) - 6 * (x + 1) ** 2) == 0
g = 2 * x**2 - 2                                 # 2(x−1)(x+1)
assert sp.expand(sp.factor(g) - 2 * (x - 1) * (x + 1)) == 0
# 两个分解重组后一致（UFD 唯一性的 sympy 面）
for expr in (f, g, x**4 - 1, 12 * x**3 + 12):
    assert sp.expand(sp.factor(expr)) == sp.expand(expr)
print("ℤ[x] 分解：内容 × 本原部分；expand∘factor = id ✓")

# ---------- ℤ[√−5]：非 UFD ----------
w = sp.sqrt(-5)
# 6 = 2·3 = (1+√−5)(1−√−5)，范数 N(a+b√−5) = a² + 5b²
def norm(a, b):
    return a * a + 5 * b * b


assert sp.expand((2) * (3)) == sp.expand((1 + w) * (1 - w)) == 6
# 范数无 2、3 值：⟹ 四个因子不可约
vals = {norm(a, b) for a in range(4) for b in range(2)}
assert 2 not in vals and 3 not in vals
# 不可约 ↛ 素：2 | 乘积不分因子
def divides(alpha, beta):
    alpha, beta = sp.sympify(alpha), sp.sympify(beta)
    q = sp.expand(beta / alpha)                  # 商写成 a + b·√−5
    a = sp.simplify(q.coeff(w, 0))
    b = sp.simplify(q.coeff(w, 1) / sp.sqrt(5))  # 系数挂在 I·√5 上
    return a == int(a) and b == int(b)


assert not divides(2, 1 + w) and not divides(2, 1 - w)
assert divides(2, 6)
print("ℤ[√−5]：6 的两分解因子皆不可约；2 不整除因子——不可约 ≠ 素 ✓")

# ---------- 多变元 UFD（推论 7.22）----------
expr = (x**2 - 2) * (y**2 + 3) * (x * y + 1)
assert sp.factor(sp.expand(expr)) in (expr, sp.factor(expr))
f2 = sp.expand(expr)
parts = sp.factor_list(f2)
_, factors = parts
prod = 1
for fac, e in factors:
    prod *= fac**e
assert sp.expand(prod * parts[0]) == f2           # 因子重组还原
print("ℚ[x,y] 分解：factor_list 重组还原（k[x,y] 是 UFD）✓")

print("END ====")
