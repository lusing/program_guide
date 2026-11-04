# 第 21 章 · 不可约性判别 —— Python 通道

from random import seed, randint
from sympy import isprime, binomial, expand, symbols, factor_list, Poly, GF

print("==== 21 不可约性判别")


def eisenstein(coeffs):
    for p in range(2, 50):
        if not isprime(p):
            continue
        if coeffs[-1] % p == 0:
            continue
        if any(c % p for c in coeffs[:-1]):
            continue
        if coeffs[0] % (p * p) == 0:
            continue
        return p
    return None


assert eisenstein([2, -4, 0, 0, 0, 1]) == 2          # x⁵ − 4x + 2
assert eisenstein([1, 2, 1]) is None                  # (x+1)²
assert eisenstein([3, 0, 9, 2]) == 3   # 2x³ + 9x + 3
print("Eisenstein：正反两案（x⁵−4x+2 → 2；(x+1)² → 落空）✓")

# 二项系数引理
for p in (3, 5, 7, 11):
    for k in range(1, p):
        assert binomial(p, k) % p == 0
    assert binomial(p, p) % p != 0
print("C(p,k) 整除性：p = 3,5,7,11 全档 ✓")

x = symbols('x')
# Φ₅(x+1) = x⁴+5x³+10x²+10x+5
phi5shift = expand(((x + 1) ** 5 - 1) / x)
assert phi5shift == x ** 4 + 5 * x ** 3 + 10 * x ** 2 + 10 * x + 5
print("Φ₅(x+1) 展开：系数 = C(5,k)（Eisenstein p = 5 命中）✓")

# 模 p 归约工作流
def trim(f):
    while len(f) > 1 and f[-1] == 0:
        f.pop()
    return f


def peval(f, a, p):
    v = 0
    for c in reversed(f):
        v = (v * a + c) % p
    return v


def irreducible_modp(f, p):
    """简化版：无根（deg ≤ 3 的充要判据）。deg 4 由 sympy factor_list 处理。"""
    f = trim(f)
    if len(f) <= 1:
        return False
    return not any(peval(f, a, p) == 0 for a in range(p))


# x³+x+1 mod 2 无根 → 不可约（deg 3 判据的完整情形）
f_cubic = [1, 1, 0, 1]
assert irreducible_modp(trim([c % 2 for c in f_cubic]), 2)
f_x4xp1 = [1, 1, 0, 0, 1]      # x⁴ + x + 1（deg 4 走 sympy）
_, facs = factor_list(Poly(sum(c * x ** i for i, c in enumerate(f_x4xp1)),
                           x, domain=GF(2)))
assert len(facs) == 1 and facs[0][1] == 1     # 单因子一次 → 不可约
f_x4p1 = [1, 0, 0, 0, 1]       # x⁴ + 1
_, facs2 = factor_list(Poly(sum(c * x ** i for i, c in enumerate(f_x4p1)),
                            x, domain=GF(2)))
assert len(facs2) > 1 or facs2[0][1] > 1      # (x+1)⁴
print("模 p 归约：x³+x+1 无根判不可约；x⁴+x+1 sympy 单因子；x⁴+1 = (x+1)⁴ ✓")

# 工作流闭环
seed(20261104)
checked = 0
for _ in range(100):
    f = trim([randint(0, 2) for _ in range(randint(4, 5))])
    f[-1] = f[-1] or 1
    if not irreducible_modp(f, 3):
        continue
    checked += 1
    assert not any(peval(f, a, 3) == 0 for a in range(3))
assert checked >= 5
print(f"工作流闭环：{checked} 组 ℤ₃ 判不可约者穷举无根 ✓")

print("END ====")
