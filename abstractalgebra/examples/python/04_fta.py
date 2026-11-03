# 第 04 章 · 算术基本定理 —— Python 通道
#
# sympy.factorint 对照自实现试除 + Ω/ω 可加性 + 指数律 gcd/lcm。

from math import gcd, lcm, prod
from sympy import factorint, divisors, totient

print("==== 04 算术基本定理")


def factorize(n):
    """试除分解：返回 [(素数, 指数), ...]，素数递增。"""
    fs = []
    p = 2
    while p * p <= n:
        e = 0
        while n % p == 0:
            n //= p
            e += 1
        if e:
            fs.append((p, e))
        p += 1 if p == 2 else 2
    if n > 1:
        fs.append((n, 1))
    return fs


# n ≤ 2000 全量：与 sympy.factorint 完全一致
for n in range(2, 2001):
    mine = dict(factorize(n))
    lib = factorint(n)
    assert mine == lib, n
    assert prod(p**e for p, e in mine.items()) == n
print("试除分解 == sympy.factorint：n ≤ 2000 全量一致（规范形：素数递增）✓")

# Ω 与 ω 的可加性
def Omega(n):
    return sum(e for _, e in factorize(n))

def omega(n):
    return len(factorize(n))

for a in range(1, 300):
    for b in range(1, 300):
        assert Omega(a * b) == Omega(a) + Omega(b)
assert omega(2 * 3 * 5 * 7 * 11) == 5
print("Ω(ab) = Ω(a)+Ω(b)：a,b < 300 全量；ω(2·3·5·7·11) = 5 ✓")

# 指数律：min/max 合成 == math.gcd/lcm
for a in range(2, 150):
    for b in range(2, 150):
        fa, fb = dict(factorize(a)), dict(factorize(b))
        g = prod(p ** min(fa.get(p, 0), fb.get(p, 0)) for p in fa)
        m = prod(p ** max(fa.get(p, 0), fb.get(p, 0)) for p in set(fa) | set(fb))
        assert g == gcd(a, b) and m == lcm(a, b)
        assert gcd(a, b) * lcm(a, b) == a * b
print("指数律 gcd/lcm（min/max）：a,b < 150 与欧几里得实现一致；gcd·lcm = ab ✓")

# 大数抽查
big1 = 2**61 - 1      # 梅森素数
assert factorint(big1) == {big1: 1}
print("梅森素数 2⁶¹−1：分解 = 自身 ✓（sympy 秒判——它用了更强的素性检验）")

# Σ φ(d) = n（与推论 1.31 呼应）
for n in range(1, 200):
    assert sum(totient(d) for d in divisors(n)) == n
print("Σ_{d∣n} φ(d) = n：n < 200 全部成立 ✓")

print("END ====")
