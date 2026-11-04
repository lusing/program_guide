# 第 25 章 · 欧氏作图 —— Python 通道

from sympy import minimal_polynomial, sqrt, Rational, cos, pi, S, nsimplify, factor, Poly

print("==== 25 欧氏作图")

x = S('x')

# 极小多项式与次数
cases = [
    (sqrt(2), 2, "√2"),
    (sqrt(2 + sqrt(3)), 4, "√(2+√3)"),
    ((1 + sqrt(5)) / 2, 2, "黄金比"),
    (2 ** Rational(1, 3), 3, "2^{1/3}"),
]
for val, deg, name in cases:
    p = Poly(minimal_polynomial(val, x), x)
    assert p.degree() == deg, (name, p)
print("极小多项式：√2 → 2、√(2+√3) → 4、黄金比 → 2、2^{1/3} → 3 ✓")

# 三等分角：8x³−6x−1 无有理根
p3 = 8 * x ** 3 - 6 * x - 1
for q in [-1, 1, Rational(1, 2), Rational(-1, 2), Rational(1, 4), Rational(-1, 4),
          Rational(1, 8), Rational(-1, 8)]:
    assert p3.subs(x, q) != 0
mp = Poly(minimal_polynomial(2 * cos(pi / 9), x), x)
assert mp.degree() == 3
print("三等分角：8x³−6x−1 的 8 个有理候选全落空；[ℚ(cos20°)] = 3 ✓")

# cos(2π/7) 的次数 3（正 7 边形不可作）
mp7 = Poly(minimal_polynomial(2 * cos(2 * pi / 7), x), x)
assert mp7.degree() == 3
print("正 7 边形：[ℚ(cos 2π/7)] = 3（有奇因子）⟹ 不可作 ✓")

# cos(2π/17) 的次数 8 = 2³（实子域 φ(17)/2；正 17 边形不排除）
mp17 = Poly(minimal_polynomial(2 * cos(2 * pi / 17), x), x)
assert mp17.degree() == 8
print("正 17 边形：[ℚ(cos 2π/17)] = 8 = φ(17)/2 = 2³ ✓")

# 费马数
F = [2 ** (2 ** k) + 1 for k in range(6)]
from sympy import isprime
for k in range(5):
    assert isprime(F[k])
assert F[5] == 641 * 6700417
assert not isprime(F[5])
print("费马素数 F₀..F₄ 全素；F₅ = 641 × 6700417 ✓")

# Sophie Germain 数值侧写
from sympy import expand
lhs = expand((x ** 2 - 2 * x + 2) * (x ** 2 + 2 * x + 2))
assert lhs == expand(x ** 4 + 4)
print("Sophie Germain：x⁴+4 可分解（次数塌到 2+2，作图视角亦可作）✓")

print("END ====")
