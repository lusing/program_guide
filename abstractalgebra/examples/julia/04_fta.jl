# 第 04 章 · 算术基本定理 —— 计算通道
#
# 试除分解（命题 1.3 的程序版）+ 指数律 gcd/lcm + gcd·lcm = ab。

println("==== 04 算术基本定理")

# ---------- 试除分解 ----------
"""返回 (素数, 指数) 列表，素数严格递增。除到 √n 为止。"""
function factorize(n::BigInt)
    fs = Tuple{BigInt, Int}[]
    p = BigInt(2)
    while p * p <= n
        e = 0
        while n % p == 0
            n ÷= p
            e += 1
        end
        e > 0 && push!(fs, (p, e))
        p += (p == 2 ? 1 : 2)
    end
    n > 1 && push!(fs, (n, 1))
    fs
end

factorize(n::Integer) = factorize(BigInt(n))

"""由分解式还原数值。"""
reconstruct(fs) = prod(p^e for (p, e) in fs)

for n in 2:999
    fs = factorize(n)
    @assert reconstruct(fs) == n                       # 还原
    @assert all(fs[i][1] < fs[i+1][1] for i in 1:length(fs)-1)  # 素数递增
    @assert all(e ≥ 1 for (_, e) in fs)                # 指数为正
end
println("试除分解：n ≤ 999 还原、素数递增、指数 ≥ 1 全部通过 ✓")

# ---------- 指数律 gcd/lcm（命题 1.55 双实现） ----------
function gcd_from_factors(fs1, fs2)
    d = big(1)
    for (p, e1) in fs1, (q, e2) in fs2
        p == q && (d *= p^min(e1, e2))
    end
    d
end
function lcm_from_factors(fs1, fs2)
    d = big(1)
    for (p, e1) in fs1                       # fs1 的素数取 max 指数
        e2 = 0
        for (q, f2) in fs2
            q == p && (e2 = f2)
        end
        d *= p^max(e1, e2)
    end
    for (q, e2) in fs2                       # fs2 独有的素数照抄
        any(p == q for (p, _) in fs1) || (d *= q^e2)
    end
    d
end

for a in 2:120, b in 2:120
    fa, fb = factorize(a), factorize(b)
    @assert gcd_from_factors(fa, fb) == gcd(a, b)
    @assert lcm_from_factors(fa, fb) == lcm(a, b)
end
println("gcd/lcm 的指数实现（min/max）与欧几里得实现全量一致（a,b ≤ 120）✓")

# ---------- 命题 1.56：gcd·lcm = ab ----------
using Random
Random.seed!(20261104)
for _ in 1:200
    a = big(rand(1:10^12)); b = big(rand(1:10^12))
    @assert gcd(a, b) * lcm(a, b) == a * b
end
println("gcd(a,b)·lcm(a,b) = ab：200 对随机 12 位数全部成立 ✓")

# ---------- 大数抽查：梅森素数 2³¹ − 1 ----------
m = big(2)^31 - 1
@assert factorize(m) == [(m, 1)] "2³¹−1 应是素数"
n2 = big(2)^31 + 1
f2 = factorize(n2)
@assert reconstruct(f2) == n2
println("梅森素数 2³¹−1：分解 = 自身 ✓；2³¹+1 = ", join(("$p^$e" for (p, e) in f2), " × "))

# gcd 快、分解慢的不对称：gcd(2^61−1, 2^31−1) 一步欧几里得
x, y = big(2)^61 - 1, big(2)^31 - 1
@assert gcd(x, y) == 1
println("gcd(2⁶¹−1, 2³¹−1) = 1：欧几里得秒算，而分解它们是另一个世界 ✓")

println("END ====")
