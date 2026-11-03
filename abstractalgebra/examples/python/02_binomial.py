# 第 02 章 · 二项式定理与复数 —— Python 通道（sympy 符号印证）

from sympy import symbols, expand, binomial, cyclotomic_poly, divisors, chebyshevt, factor

x, y = symbols('x y')

print("==== 02 二项式定理与复数")

# ---------- 二项式定理：逐系数比对 ----------
for n in range(0, 9):
    lhs = expand((x + y) ** n)
    rhs = expand(sum(binomial(n, k) * x**k * y ** (n - k) for k in range(n + 1)))
    assert lhs == rhs, n
print("(x+y)ⁿ 的展开与二项式定理右端：n ≤ 8 逐系数相等 ✓")

# 帕斯卡恒等式
for n in range(1, 20):
    for k in range(1, n + 1):
        assert binomial(n + 1, k + 1) == binomial(n, k) + binomial(n, k + 1)
print("帕斯卡恒等式：n ≤ 19 全数对成立 ✓")

# ---------- 分圆多项式：定义式 vs 库函数 ----------
from sympy import Poly

def cyclotomic_def(n):
    """手算路径：Φ_n = (xⁿ−1) ÷ Π_{d∣n,d<n} Φ_d（与 Julia 通道同一递归）。"""
    if n == 1:
        return Poly(x - 1, x)
    rest = Poly(1, x)
    for d in divisors(n):
        if d < n:
            rest = rest * cyclotomic_def(d)
    q, r = divmod(Poly(x**n - 1, x), rest)
    assert r.is_zero, f"Φ_{n} 除法不整除"
    return q

for n in range(1, 13):
    mine = cyclotomic_def(n)
    lib = Poly(cyclotomic_poly(n, x), x)
    assert mine == lib, n
    # 系数全整数（Poly(x, domain=QQ) → 检查 each coeff 是整数）
    for c in mine.all_coeffs():
        assert c == int(c), (n, c)
print("分圆多项式：定义式除法 == sympy.cyclotomic_poly，n ≤ 12 全一致（整系数）✓")

# Π_{d∣n} Φ_d = xⁿ − 1
for n in range(1, 13):
    prod_all = Poly(1, x)
    for d in divisors(n):
        prod_all = prod_all * Poly(cyclotomic_poly(d, x), x)
    assert expand(prod_all.as_expr() - (x**n - 1)) == 0, n
print("Π_{d∣n} Φ_d(x) = xⁿ − 1：n ≤ 12 符号验证 ✓")

assert expand(cyclotomic_poly(12, x) - (x**4 - x**2 + 1)) == 0
print("Φ₁₂ = x⁴ − x² + 1（负系数实锤）✓")

# ---------- 切比雪夫：首项系数 2^{n−1} 与复合半群性质 ----------
for n in range(1, 8):
    t = chebyshevt(n, x)
    assert t.as_poly().LC() == 2 ** (n - 1), n
for m in range(1, 5):
    for n in range(1, 5):
        assert chebyshevt(m * n, x) == chebyshevt(m, chebyshevt(n, x)).expand()
print("切比雪夫：首项系数 2ⁿ⁻¹；T_m∘T_n = T_{mn}（半群性质）✓")

print("END ====")
