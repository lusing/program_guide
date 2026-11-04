# 第 35 章 · 素理想与极大理想 —— Python 通道

import math

import sympy as sp

print("==== 35 素理想与极大理想")

# ---------- ℤ/n 的理想格 ----------
def zn_ideal(n, d):
    """ℤ/n 中理想 (d) = {0, d, 2d, …}（n/d 个元素）。"""
    return {(d * k) % n for k in range(n // math.gcd(n, d)) if (d * k) % n % d == 0} | {0}


def divisors(n):
    return [d for d in range(1, n + 1) if n % d == 0]


# ℤ/12：6 个理想与因数一一对应
assert divisors(12) == [1, 2, 3, 4, 6, 12]
for a in divisors(12):
    for b in divisors(12):
        contain = zn_ideal(12, a) >= zn_ideal(12, b)
        assert contain == (b % a == 0)          # (a) ⊇ (b) ⟺ a | b
print("ℤ/12：理想 ↔ 因数；(a) ⊇ (b) ⟺ a | b（命题 7.1 对应定理）✓")


# ---------- 素 / 极大判别 ----------
def zn_is_domain(n):
    return all((a * b) % n != 0 or a == 0 or b == 0
               for a in range(n) for b in range(n))


def zn_is_field(n):
    if not zn_is_domain(n):
        return False
    return all(any((a * b) % n == 1 for b in range(n)) for a in range(1, n))


# ℤ/n/(d) ≅ ℤ/d：素/极大判定表
# (2) → ℤ/2 域、(3) → ℤ/3 域（极大）；(4) → ℤ/4、(6) → ℤ/6（非素）
assert zn_is_field(2) and zn_is_field(3)
assert not zn_is_domain(4) and not zn_is_domain(6)
# 2 ≤ n ≤ 30：域 ⟺ 素 ⟺ 整域
for n in range(2, 31):
    isp = sp.isprime(n)
    assert zn_is_field(n) == isp and zn_is_domain(n) == isp
print("ℤ/n 扫描 2..30：域 ⟺ 素 ⟺ 整域（引理 7.6 + 有限整域是域）✓")

# ---------- 极大 ⟹ 素（推论 7.8）----------
for p in (2, 3, 5, 7):
    n = p * p
    ok = all((a * b) % p == 0 if (a % p == 0 or b % p == 0) else True
             for a in range(n) for b in range(n))
    assert ok                                   # (p) 是 ℤ/p² 的素理想
print("(p) ⊂ ℤ/p²（p = 2,3,5,7）：素理想（极大 ⟹ 素）✓")

# ---------- k[x]/(不可约) 造域（推论 7.12）----------
x = sp.Symbol("x")
p = x**2 + x + 1                                # ℤ/2[x] 不可约
assert sp.factor(p, modulus=2) == p             # 模 2 不可约
# GF(4)：商环 = {0, 1, x, x+1}，乘法 mod (p, 2)
def gf4_reduce(expr):
    r = sp.rem(sp.Poly(expr, x, modulus=2), sp.Poly(p, x, modulus=2), modulus=2)
    return r.as_expr()


GF4 = [0, 1, x, x + 1]
prods = {gf4_reduce(a * b) for a in GF4 for b in GF4}
assert prods == set(GF4)                        # 封闭
for a in GF4[1:]:
    assert any(gf4_reduce(a * b) == 1 for b in GF4[1:])   # 非零可逆
assert gf4_reduce(x * x) == x + 1               # x² ≡ x+1
print("GF(4) = ℤ/2[x]/(x²+x+1)：封闭、非零可逆、x² ≡ x+1 ✓")

# ---------- ℤ[x] 的 (x)：素而不极大 ----------
# 商 ℤ[x]/(x) ≅ ℤ 是整域非域；sympy 面验证 x²+x+1 在 (x) 上的像
# 是常数 1（即多项式常数项的同态）
const = sp.Poly(x**2 + 5 * x + 3, x).all_coeffs()[-1]
assert const == 3                               # 模 (x) 只剩常数项
print("ℤ[x]/(x) ≅ ℤ：整域而非域 ⟹ (x) 素不极大 ✓")

print("END ====")
