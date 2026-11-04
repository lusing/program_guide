# 第 05 章 · 同余 —— Python 通道
#
# 内建 pow(三参数) 复核费马/例题 + sympy crt 对拍 + 弃九法 + 玛雅历模拟。

from sympy.ntheory.modular import crt
from sympy import isprime, Rational

print("==== 05 同余")

# ---------- 费马小定理：p ≤ 100 全素数全余数 ----------
for p in range(2, 101):
    if isprime(p):
        for a in range(p):
            assert pow(a, p, p) == a % p
            if a:
                assert pow(a, p - 1, p) == 1
print("费马小定理：p ≤ 100 全部素数 × 全部余数（pow 三参数快速幂）✓")

# ---------- 例 1.64：3^12345 mod 7 ----------
v = pow(3, 12345, 7)
assert v == 6
digits7 = []
n = 12345
while n:
    digits7.append(n % 7)
    n //= 7
assert digits7 == [4, 6, 6, 0, 5]           # 低位在前：12345 = (50664)₇
ds = sum(digits7)
assert ds == 21 and ds % 6 == 3 and pow(3, 3, 7) == 6
print(f"3^12345 mod 7 = {v}；数字和路径：Σ(50664)₇ = 21 ≡ 3 (mod 6)，3³ ≡ 6 ✓")

# ---------- 弃九法（中译本编号例 1.66） ----------
def digit_root(m):
    """书的口径：0 ≤ r < 9，9 的倍数 r = 0。"""
    return m % 9 if m % 9 or m == 0 else 0

exact = (12345 + 5261934) * 1776
assert exact == 9367119504                     # 书上等式逐位核对
assert digit_root(12345) == 6 and digit_root(5261934) == 3 and digit_root(1776) == 3
r_formula = digit_root((6 + 3) * 3)            # r([6+3]×3) = r(27) = 0
assert digit_root(exact) == r_formula == 0
print(f"弃九法：r((12345+5261934)×1776) = r([6+3]×3) = {r_formula}，"
      f"与 9367119504 的数字根 {digit_root(exact)} 一致 ✓")

# ---------- 例 1.67：51x ≡ 10 (mod 94) ----------
inv = pow(51, -1, 94)                       # 模逆（贝祖的 pow 版）
assert inv == 59 and (51 * inv) % 94 == 1
x = inv * 10 % 94
assert x == 26 and (51 * 26) % 94 == 10
print(f"51⁻¹ ≡ {inv} (mod 94)，x ≡ {x} ✓")

# ---------- 孙子问题：自实现 CRT vs sympy.crt ----------
def crt_pair(b1, m1, b2, m2):
    """构造性证明直译（同 Julia 通道）。"""
    assert gcd_(m1, m2) == 1
    s = pow(m1, -1, m2)
    x = b1 + (b2 - b1) * s * m1
    return x % (m1 * m2)

def gcd_(a, b):
    while b:
        a, b = b, a % b
    return a

sol = crt_pair(crt_pair(2, 3, 3, 5), 15, 2, 7)
assert sol == 23
r, _ = crt([3, 5, 7], [2, 3, 2])
assert r % 105 == 23
print(f"孙子问题：自实现 CRT 链 = {sol}；sympy.crt 同给 ≡ 23 (mod 105) ✓")

for b1 in range(5):
    for m1 in range(2, 8):
        for b2 in range(5):
            for m2 in range(2, 8):
                if gcd_(m1, m2) != 1:
                    continue
                xx = crt_pair(b1, m1, b2, m2)
                assert xx % m1 == b1 % m1 and xx % m2 == b2 % m2
                rr, _ = crt([m1, m2], [b1, b2])
                assert rr % (m1 * m2) == xx
print("CRT 双实现对拍：互素模全量组合（b ≤ 4, m ≤ 7）一致 ✓")

# ---------- 玛雅卓尔金历模拟 ----------
names = ["Imix", "Ik", "Akbal", "Kan", "Chicchan", "Cimi", "Manik", "Lamat",
         "Muluc", "Oc", "Chuen", "Eb", "Ben", "Ix", "Men", "Kib", "Kaban",
         "Etznab", "Kawak", "Ajaw"]
d = 0
while True:
    name = names[(2 + d) % 20]
    num = (12 + d) % 13 + 1
    if name == "Muluc" and num == 8:
        break
    d += 1
assert d == 86 == crt_pair(6, 20, 8, 13)
print(f"玛雅历：Akbal 13 → {d} 天后 Muluc 8；CRT（d≡6 mod 20, d≡8 mod 13）= 86 ✓")

# ---------- 玩具 RSA ----------
p, q = 2003, 3011
assert isprime(p) and isprime(q) and p % 3 == 2 and q % 3 == 2
N = p * q
phi = (p - 1) * (q - 1)
t = pow(3, -1, phi)
assert 3 * t % phi == 1
msg = [72, 69, 76, 76, 79]                  # "HELLO"
cipher = [pow(m, 3, N) for m in msg]
plain = [pow(c, t, N) for c in cipher]
assert plain == msg
# a³→a^{3t} 往返抽样复核（等距抽样 6000 点 + 消息本身）
for a in list(range(0, N, 997)) + msg:
    assert pow(pow(a, 3, N), t, N) == a
print(f"玩具 RSA：N = {N}，t = {t}，往返还原（消息 + 抽样 6000 点）✓")

print("END ====")
