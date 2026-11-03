# 第 05 章 · 同余 —— 计算通道
#
# 快速幂取模 + 中国剩余定理 + 费马小定理全量复核 + 玩具 RSA + 玛雅历。

println("==== 05 同余")

# ---------- 基础件（自包含，不依赖其他章节文件） ----------
"""扩展欧几里得（同第 03 章）。"""
function extgcd(a::T, b::T) where T <: Integer
    old_r, r = a, b
    old_s, s = T(1), T(0)
    old_t, t = T(0), T(1)
    while r != 0
        q = div(old_r, r)
        old_r, r = r, old_r - q * r
        old_s, s = s, old_s - q * s
        old_t, t = t, old_t - q * t
    end
    old_r, old_s, old_t
end

"""快速幂取模：指数折半，O(log e) 次乘法。"""
function powmod(a::BigInt, e::Integer, m::BigInt)
    r = big(1); a = a % m
    while e > 0
        e & 1 == 1 && (r = r * a % m)
        a = a * a % m
        e >>= 1
    end
    r
end
powmod(a::Integer, e::Integer, m::Integer) = powmod(BigInt(a), e, BigInt(m))

isprime(n::Integer) = n ≥ 2 && (p = big(2); while p * p ≤ n; n % p == 0 && return false; p += (p == 2 ? 1 : 2); end; true)

"""中国剩余定理（定理 1.73 的构造性证明直译）。"""
function crt(b1, m1, b2, m2)
    d, s, _ = extgcd(BigInt(m1), BigInt(m2))
    @assert d == 1 "模不互素：($m1, $m2)"
    x = b1 + (b2 - b1) * s * m1
    mod(x, BigInt(m1 * m2))
end

# ---------- 费马小定理全量复核 ----------
for p in 2:100
    isprime(p) || continue
    for a in 0:p-1
        @assert powmod(a, p, p) == a % p "a^p ≡ a (mod p) 在 p=$p, a=$a 失效"
        a == 0 ? @assert(true) : @assert(powmod(a, p - 1, p) == 1)
    end
end
println("费马小定理：p ≤ 100 全部素数 × 全部余数（含 a ≡ 0 情形）✓")

# ---------- 例 1.68：3^12345 mod 7 ----------
v = powmod(3, 12345, 7)
@assert v == 6
# 数字和折叠路径：12345 = (50664)₇，数字和 21 ≡ 3 (mod 6)，3³ = 27 ≡ 6
ds = sum(digits(12345, base=7))
@assert (ds == 21 && mod(ds, 6) == 3 && mod(3^3, 7) == 6)
println("3^12345 mod 7 = $v（直接快速幂）；数字和路径：Σ数字 = 21 ≡ 3 (mod 6)，3³ ≡ 6 ✓")

# ---------- 例 1.72：51x ≡ 10 (mod 94) ----------
_, s0, _ = extgcd(51, 94)
inv = mod(s0, 94)
@assert inv == 59 "51⁻¹ mod 94 = $inv ≠ 59"
x = mod(inv * 10, 94)
@assert (x == 26 && mod(51 * 26, 94) == 10)
println("51x ≡ 10 (mod 94)：51⁻¹ ≡ $(inv)，x ≡ $x ✓")

# ---------- 孙子问题 + 一般核验 ----------
sun = crt(crt(2, 3, 3, 5), 15, 2, 7)   # 链式：三模 → 两模
@assert sun == 23
println("孙子问题 x ≡ 2,3,2 (mod 3,5,7)：x ≡ $sun (mod 105) ✓")

for b1 in 0:4, m1 in 2:7, b2 in 0:4, m2 in 2:7
    gcd(m1, m2) == 1 || continue
    xx = crt(b1, m1, b2, m2)
    @assert (mod(xx, m1) == mod(b1, m1) && mod(xx, m2) == mod(b2, m2))
end
println("CRT 构造解：互素模全量组合（b ≤ 4, m ≤ 7）回代核验 ✓")

# ---------- 玛雅卓尔金历（例 1.78） ----------
names = ["Imix", "Ik", "Akbal", "Kan", "Chicchan", "Cimi", "Manik", "Lamat",
         "Muluc", "Oc", "Chuen", "Eb", "Ben", "Ix", "Men", "Kib", "Kaban",
         "Etznab", "Kawak", "Ajaw"]
# 第 0 天 = Akbal 13（名序 3、数 13）；求第一个出现 Muluc 8 的日子
function maya_gap()
    d = 0
    while true
        name = names[mod(2 + d, 20) + 1]      # 从 Akbal（下标 2，0 基）起推进
        num = mod(12 + d, 13) + 1             # 从 13 起推进
        (name == "Muluc" && num == 8) && return d
        d += 1
    end
end
d = maya_gap()
@assert d == 86
d_crt = crt(6, 20, 8, 13)
@assert d_crt == 86
println("玛雅历：Akbal 13 之后第 $(d) 天是 Muluc 8；CRT（d≡6 mod 20, d≡8 mod 13）同给 86 ✓")

# ---------- 玩具 RSA（例 1.79） ----------
p, q = 2003, 3011                     # 都 ≡ 2 (mod 3)，素数
@assert isprime(p) && isprime(q) && mod(p, 3) == 2 && mod(q, 3) == 2
N = p * q                             # N = 6031033
phi = BigInt((p - 1) * (q - 1))
d_, t_, _ = extgcd(BigInt(3), phi)
@assert d_ == 1 "3 与 (p−1)(q−1) 应互素"
t = mod(t_, phi)                      # 3t ≡ 1 (mod φ)
@assert mod(3 * t, phi) == 1
msg = [72, 69, 76, 76, 79]            # ASCII "HELLO"
cipher = [powmod(m, 3, BigInt(N)) for m in msg]
plain = [powmod(c, t, BigInt(N)) for c in cipher]
@assert plain == msg
println("玩具 RSA：p×q = $(N)，加密 a³ mod N，解密指数 t = $(t)，往返还原 ✓")

println("END ====")
