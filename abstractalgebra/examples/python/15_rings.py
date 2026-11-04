# 第 15 章 · 交换环的基本性质 —— Python 通道

from math import gcd

print("==== 15 交换环的基本性质")

zn_add = lambda n: [[(i + j) % n for j in range(n)] for i in range(n)]
zn_mul = lambda n: [[(i * j) % n for j in range(n)] for i in range(n)]

def is_domain(mul, n):
    return all(mul[a][b] != 0 for a in range(1, n) for b in range(1, n))

def is_field(mul, n):
    return all(any(mul[a][b] == 1 for b in range(1, n)) for a in range(1, n))

for m in (5, 7, 11):
    assert is_domain(zn_mul(m), m) and is_field(zn_mul(m), m)
print("ℤ₅、ℤ₇、ℤ₁₁：整环 + 域 ✓")

def zero_divisors(mul, n):
    return [a for a in range(1, n) if any(mul[a][b] == 0 for b in range(1, n))]

assert zero_divisors(zn_mul(6), 6) == [2, 3, 4]
assert zero_divisors(zn_mul(8), 8) == [2, 4, 6]
print("零因子谱：ℤ₆ = {2,3,4}；ℤ₈ = {2,4,6} ✓")

for m in range(2, 21):
    fld = is_field(zn_mul(m), m)
    prm = all(m % d for d in range(2, int(m ** 0.5) + 1))
    assert fld == prm, m
print("命题 3.15：m = 2..20，ℤ_m 域 ⟺ 素数 ✓")

# 单位群表：U(ℤ_m) 大小 = φ(m)；零因子 ∪ 单位 = 非零元
for m in range(5, 13):
    units = [a for a in range(1, m) if gcd(a, m) == 1]
    zd = set(zero_divisors(zn_mul(m), m))
    us = set(units)
    assert zd | us == set(range(1, m)) and not (zd & us)
print("单位 ∪ 零因子 = 非零元（m = 5..12）✓")

print("END ====")
