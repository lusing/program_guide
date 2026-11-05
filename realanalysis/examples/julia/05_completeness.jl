# 第 05 章 实数域（下）：Julia 通道。
# 完备性的算法形态：二分法在精确有理数上逼近 √2——
# 每一步区间长度减半，且左端点平方 < 2 < 右端点平方。
# Archimedean 性质保证步数足够时区间窄于任意给定 ε。
# 运行：julia --startup-file=no 05_completeness.jl

println("==== 05 completeness ====")

# --- 1. 二分法逼近 √2（全程 Rational{BigInt}，零舍入） ----------------
function bisect_sqrt2(k)
    a, b = big(1) // 1, big(2) // 1     # 1^2 < 2 < 2^2；BigInt 防溢出
    for _ in 1:k
        @assert a^2 < 2 && 2 <= b^2
        m = (a + b) // 2
        if m^2 < 2
            a = m
        else
            b = m
        end
    end
    return a, b
end

a40, b40 = bisect_sqrt2(40)
@assert b40 - a40 == 1 // big(2)^40
println("after 40 bisections: gap = 2^-40 ≈ $(Float64(b40 - a40))")
println("  a = $(Float64(a40))  a^2 = $(Float64(a40^2))")

# --- 2. Archimedean 核验：区间长度严格每步减半 -------------------------
for k in (10, 20, 40, 60)
    a, b = bisect_sqrt2(k)
    @assert b - a == 1 // big(2)^k
end
println("archimedean: gap halves every step, beats any eps eventually")

# --- 3. 有理数稠密：任意两实数之间存在有理数 ---------------------------
# 对浮点 x < y，构造性地给出有理数：m/n 夹在中间。
function rational_between(x::Float64, y::Float64)
    @assert x < y
    n = ceil(Int, 2 / (y - x))            # Archimedean：1/n < (y-x)/2
    m = floor(Int, x * n) + 1             # 取整：m-1 <= nx < m
    r = m // n
    @assert x < r < y
    return r
end
r = rational_between(1.4142135, 1.4142136)
println("rational between 1.4142135 and 1.4142136: $r")

# --- 4. Archimedean：找 n 使 n*x > y ---------------------------------
function arch_witness(x::Rational, y)
    @assert x > 0
    n = floor(Int, Float64(y) / Float64(x)) + 1
    @assert n * x > y
    return n
end
@assert arch_witness(1 // 3, 10) == 31
println("archimedean witness for x=1/3, y=10: n = $(arch_witness(1 // 3, 10))")

# --- 5. 两点之间的有理样本（稠密性的有限核验） -----------------------
@assert 2 // 1 < 12 // 5 < 3 // 1
println("sample rational between 2 and 3: 12//5")

println("END ====")
