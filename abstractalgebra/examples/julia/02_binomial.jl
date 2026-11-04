# 第 02 章 · 二项式定理与复数 —— 计算通道
#
# 帕斯卡行和 + 分圆多项式的精确计算（Rational{BigInt} 系数一元多项式，
# 递归定义 Φ_n = (xⁿ−1) ÷ Π_{d∣n,d<n} Φ_d，全程精确无浮点）。

println("==== 02 二项式定理与复数")

# ---------- 帕斯卡：二项式系数与行和 ----------
"""乘法公式版二项式系数（精确 BigInt）。"""
function binom(n::Integer, k::Integer)
    (k < 0 || k > n) && return big(0)
    k = min(k, n - k)
    r = big(1)
    for i in 1:k
        r = r * (n - k + i) ÷ i   # 逐步整除：中间值恒为整数
    end
    r
end

for n in 0:20
    s = sum(binom(n, k) for k in 0:n)
    @assert s == 2^n "行和 Σ C($n,k) = $s ≠ 2^n"
end
println("帕斯卡行和 Σ_k C(n,k) = 2ⁿ：n ≤ 20 全部成立 ✓")

for n in 1:15, k in 1:n
    @assert binom(n + 1, k + 1) == binom(n, k) + binom(n, k + 1)
end
println("帕斯卡恒等式 C(n+1,k+1) = C(n,k) + C(n,k+1)：n ≤ 15 全数对成立 ✓")

# ---------- 精确多项式算术（系数向量，低次在前） ----------
const Poly = Vector{Rational{BigInt}}

function trim!(p::Poly)
    while length(p) > 1 && p[end] == 0
        pop!(p)
    end
    p
end

function polymul(p::Poly, q::Poly)::Poly
    r = zeros(Rational{BigInt}, length(p) + length(q) - 1)
    for (i, a) in enumerate(p), (j, b) in enumerate(q)
        r[i + j - 1] += a * b
    end
    trim!(r)
end

Base.:-(p::Poly, q::Poly)::Poly = begin
    r = zeros(Rational{BigInt}, max(length(p), length(q)))
    for (i, c) in enumerate(p); r[i] += c; end
    for (i, c) in enumerate(q); r[i] -= c; end
    trim!(r)
end

"""精确商（本文件只用整除场景；若有余数直接报错）。"""
function polydivexact(a::Poly, b::Poly)::Poly
    a = copy(a)
    q = zeros(Rational{BigInt}, max(1, length(a) - length(b) + 1))
    while length(a) >= length(b) && any(!=(0), a)
        shift = length(a) - length(b)
        c = a[end] // b[end]
        q[shift + 1] = c
        for (j, bv) in enumerate(b)
            a[shift + j] -= c * bv
        end
        trim!(a)
    end
    @assert all(iszero, a) "除法不整除——分圆递归的定义前提被破坏"
    trim!(q)
end

px_pow(n::Integer)::Poly = begin
    p = zeros(Rational{BigInt}, n + 1)
    p[n + 1] = 1
    p
end

divisors(n::Integer) = [d for d in 1:n if n % d == 0]

"""Φ_n = (xⁿ − 1) ÷ Π_{d∣n, d<n} Φ_d（命题 1.27 的构造性读法）。"""
function cyclotomic(n::Integer)::Poly
    n == 1 && return Rational{BigInt}[-1, 1]    # x − 1
    rest = foldl(polymul, (cyclotomic(d) for d in divisors(n) if d < n);
                 init=Rational{BigInt}[1])
    polydivexact(px_pow(n) - Rational{BigInt}[1], rest)
end

"""φ(n)：与 n 互素的数的个数（欧拉函数，定义直译）。"""
totient(n::Integer) = count(k -> gcd(k, n) == 1, 1:n)

for n in 1:12
    Φ = cyclotomic(n)
    @assert all(c -> denominator(c) == 1, Φ) "Φ_$n 出现分式系数"
    ints = map(numerator, Φ)
    @assert length(ints) - 1 == totient(n) "deg Φ_$n ≠ φ($n)"
    prod = foldl(polymul, (cyclotomic(d) for d in divisors(n));
                 init=Rational{BigInt}[1])
    @assert prod == px_pow(n) - Rational{BigInt}[1] "Π_{d∣$n} Φ_d ≠ x^n − 1"
    println("Φ_$n = ", ints)
end

@assert cyclotomic(5) == Rational{BigInt}[1, 1, 1, 1, 1]         # x⁴+x³+x²+x+1
@assert cyclotomic(6) == Rational{BigInt}[1, -1, 1]              # x² − x + 1
@assert cyclotomic(12) == Rational{BigInt}[1, 0, -1, 0, 1]       # x⁴ − x² + 1

# Σ_{d∣n} φ(d) = n（推论 1.28 的整数复核）
for n in 1:60
    @assert sum(totient, divisors(n)) == n
end
println("Σ_{d∣n} φ(d) = n：n ≤ 60 全部成立 ✓")
println("END ====")
