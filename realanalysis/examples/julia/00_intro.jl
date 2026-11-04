# 第 00 章 导言：Julia 通道。
# 主题：数学实数（精确）与机器浮点（近似）的对照，以及 √2 无理性的
# 有限证据。运行：julia --startup-file=no 00_intro.jl

println("==== 00 intro ====")

# --- 1. 浮点不是数学实数 -----------------------------------------
# 0.1 在二进制浮点里无法精确表示，连加三次暴露累积舍入。
println("Float64: 0.1 + 0.2 = ", 0.1 + 0.2)
@assert 0.1 + 0.2 != 0.3          # 反直觉但真实
println("eps(Float64) = ", eps(Float64), "  (相邻浮点数的最小间隔)")

# Julia 的 Rational 是精确分数：1//3 连加三次严格等于 1。
r = 1//3
@assert r + r + r == 1
println("Rational: 1//3 + 1//3 + 1//3 = ", r + r + r)

# BigFloat 可以把精度开得很高，但它仍然是有限精度近似，不是数学实数。
setprecision(256) do
    println("BigFloat(256 bit) sqrt2 = ", sqrt(big(2.0)))
end

# --- 2. √2 无理性的有限证据 --------------------------------------
# 完整证明（无限穷举）在 Lean/Isabelle/Coq 通道；这里用整数算术
# 核验：在 m,n ≤ 5000 的范围内不存在 m^2 = 2n^2 的整数解。
# 注意这只是“有限影子”，不能替代证明——数值实验给直觉，证明给确定性。
function search_pythagoras(limit)
    for n in 1:limit
        m = round(Int, sqrt(2) * n)
        for cand in (m - 1, m, m + 1)
            cand > 0 && cand^2 == 2 * n^2 && return (cand, n)
        end
    end
    return nothing
end
@assert search_pythagoras(5000) === nothing
println("integer scan up to 5000: no m^2 = 2n^2 solution (consistent with irrationality)")

# 另一种数值读数：√2 的连分数逼近始终有误差，且误差不会归零。
approx = 665857 // 470832          # 一个经典的高精度有理数逼近
println("665857//470832 squared vs 2: ", approx^2, " diff = ", approx^2 - 2)
@assert approx^2 != 2

# --- 3. Archimedean 性质的可计算版本 ------------------------------
# 对任意（有限的）浮点 x，总能找到自然数 n > x。
function archimedean(x)
    n = floor(Int, x) + 1
    @assert n > x
    return n
end
println("archimedean(10^6) = ", archimedean(10^6))
println("archimedean(-3.7) = ", archimedean(-3.7))

println("END ====")
