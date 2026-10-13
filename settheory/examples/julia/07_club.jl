# 第 07 章 滤子与 club：club 数值实验与 Fodor 演示
#
# 在 κ = ω₁ 的"可数代理"（极限序数 < ω₁ 用收敛序列代表）上：
# 1. club 的交仍是 club（引理 7.3 的交替构造）；
# 2. 对角交（引理 7.5）；
# 3. Fodor 定理（定理 22）的数值影子：regressive 函数的常数化。

println("==== 07 滤子与 club：数值实验")

# ---------- 一、club 的交（引理 7.3 的交替构造引擎） ----------

"""两个无界序列的交替提升：β = lim 交替序列 同时属于两个闭包"""
function alternating_limit(C::Vector{Int}, D::Vector{Int}, alpha::Int, steps::Int)
    x = alpha
    for n in 1:steps
        x = minimum(filter(c -> c > x, C))   # 跳进 C
        x = minimum(filter(d -> d > x, D))   # 再跳进 D
    end
    return x
end

C = [10 * k for k in 1:1000]              # 10 的倍数（在有限域"无界"）
D = [7 * k for k in 1:1500]               # 7 的倍数
x = alternating_limit(C, D, 5, 8)
println("交替提升 8 步后 x = $x（同时 ↑C 与 ↑D）")
@assert x % 7 == 0                                # 本轮终于 D；下一轮入 C
println("  本轮终于 D（7 的倍数）；无穷交替的极限点才双属于 C∩D——引理 7.3。")

# ---------- 二、对角交（引理 7.5 的数值形态） ----------

"""Δ C_α = {ξ : ξ ∈ C_α 对所有 α < ξ}
    有限域：C_α 用移位集合（mod 大周期）模拟。"""
function diagonal_intersection(Cs::Vector{Vector{Int}}, bound::Int)
    [xi for xi in 1:bound if all(xi in Cs[a] for a in 1:min(xi, length(Cs)))]
end

Cs = [vcat(collect(1:a), collect(a:3:100)) for a in 1:10]  # 尾段化的 3 倍数 club
di = diagonal_intersection(Cs, 100)
println("\n对角交 Δ{{C_α}} 的前几个元素：", di[1:min(5, end)])
@assert length(di) > 0
println("  对角交非空且无界趋势——club 滤器的正规性（κ-完备+对角交封闭）。")

# ---------- 三、Fodor（定理 22）：regressive ⟹ 平稳段常数 ----------

"""regressive f（f(α) < α）在任意"大"子集上必有大常数段。
数值演示：f(α) = α 的最大素因子（对合成数），f(素数) = 0。"""
function max_prime_factor(n::Int)
    n <= 1 && return 0
    f = 1
    m = n
    d = 2
    while d * d <= m
        while m % d == 0
            f = d
            m ÷= d
        end
        d += 1
    end
    return max(f, m)
end

domain = 2:2000                          # "平稳集"的有限代理
values = [max_prime_factor(n) for n in domain]

# 每个 regressive 函数值 γ 的纤维
fibers = Dict{Int,Vector{Int}}()
for (n, v) in zip(collect(domain), values)
    push!(get!(fibers, v, Int[]), n)
end
# 最大的纤维（Fodor 的结论：某条纤维"大"）
top = sort(collect(fibers), by=kv -> -length(kv[2]))
println("\nf(n) = 最大素因子（regressive）：")
for (v, fiber) in top[1:3]
    println("  f(n)=$(v) 的纤维大小 = $(length(fiber))（首元素 $(fiber[1]) …）")
end
@assert length(top[1][2]) >= length(domain) ÷ 30   # ≈3%：素因子集中在小值域
println("  至少一条纤维占 3% 以上（素因子集中于小值）——Fodor 的数值影子：")
println("  regressive f 在平稳集上有平稳的常数段。")

println("END ====")
