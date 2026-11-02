# -*- coding: utf-8 -*-
println("==== 09 expectation")
# 第 09 章 Julia：期望与风险的固定种子模拟。
# ① 线性性：E[3X+2] = 3·3.5+2 = 12.5、Var(3X+2) = 9·35/12；
# ② 方差可加：5 颗骰子之和 均值 17.5、方差 5·35/12；
# ③ 投资组合：独立双股票（μ=3、σ²=2）扫 w，方差抛物线
#    谷底 w = 1/2 处 Var = 1；④ Cauchy vs 正态：样本均值的
#    发散 vs 收敛（均值不存在的频率版）。
using Random, Statistics

Random.seed!(10)

# ① 线性性（骰子）
rolls = rand(1:6, 2_000_000)
Y = 3 .* rolls .+ 2
@assert abs(mean(Y) - 12.5) < 0.01               # 3·7/2 + 2
@assert abs(var(Y) - 9 * 35 / 12) < 0.05         # a²·Var(X)，b 不进方差
println("linearity: E[3X+2]=12.5, Var=9*35/12: OK")

# ② 独立和的方差可加：S5 = 五颗骰子之和
S5 = [sum(rand(1:6, 5)) for _ in 1:1_000_000]
@assert abs(mean(S5) - 17.5) < 0.02              # 5·7/2
@assert abs(var(S5) - 5 * 35 / 12) < 0.08        # 175/12 ≈ 14.583
println("sum of 5 dice: mean≈17.5, var≈5*35/12=14.583: OK")

# ③ 投资组合：S = w·X1 + (1-w)·X2，独立双股票 μ=3、σ²=2
μ, σ2 = 3.0, 2.0
ws = [0.0, 0.25, 0.5, 0.75, 1.0]
vars = Float64[]
for w in ws
    X1 = μ .+ sqrt(σ2) .* randn(400_000)
    X2 = μ .+ sqrt(σ2) .* randn(400_000)
    S = w .* X1 .+ (1 .- w) .* X2
    target = σ2 * (w^2 + (1 - w)^2)
    @assert abs(mean(S) - μ) < 0.02              # 均值与 w 无关
    @assert abs(var(S) - target) < 0.05
    push!(vars, var(S))
end
@assert argmin(vars) == 3                         # w = 0.5 谷底
@assert abs(vars[3] - 1.0) < 0.05                 # 谷底 Var = 1 = 原方差一半
println("portfolio: var parabola [", round.(vars, digits=3),
        "] min at w=1/2 with var=1: OK")

# ④ Cauchy（无均值）vs 正态（均值存在）：running mean 对照
cauchy() = tan(pi * (rand() - 0.5))
samples = [cauchy() for _ in 1:100_000]
cs2 = cumsum(samples)
running = [cs2[i] / i for i in 10_000:10_000:100_000]
normal_run = cumsum(randn(100_000)) ./ collect(1:100_000)
@assert abs(normal_run[end]) < 0.05               # 正态均值 → 0（1/√n 收敛）
@assert maximum(running) - minimum(running) > 1.0 # Cauchy 均值剧烈震荡不收敛
println("Cauchy running mean oscillates (range ",
        round(maximum(running) - minimum(running), digits=2),
        ") vs normal converges to 0: OK")

println("END ====")
