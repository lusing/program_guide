# -*- coding: utf-8 -*-
println("==== 14 uniform_exponential")
# 第 14 章 Julia：均匀与指数的频率形态。
# ① 三角形密度模拟 vs 分段公式；② n=8 均匀和 vs 正态
#    N(4, 8/12)（CLT 先声）；③ 指数 μ=λ、σ²=λ² 模拟；
# ④ Erlang n=2/8/30 vs 密度与正态近似（n=30 仍偏）；
# ⑤ 足球 e^{−3/2}；⑥ 逆变换采样直方图 vs 密度。
using Random, Statistics

Random.seed!(14)

# ① 三角形：Z = X+Y（独立 Unif(0,1)）
tri(z) = 0 <= z <= 1 ? z : (1 < z <= 2 ? 2 - z : 0.0)
Z = rand(800_000) .+ rand(800_000)
for (lo, hi) in [(0.0, 0.5), (0.5, 1.0), (1.0, 1.5)]
    emp = count(x -> lo <= x <= hi, Z) / length(Z)
    theo = begin
        q(z) = z <= 1 ? z * z / 2 : 1 - (2 - z)^2 / 2
        q(hi) - q(lo)
    end
    @assert abs(emp - theo) < 0.004
end
println("triangle density: simulated vs piecewise CDF: OK")

# ② n = 8 均匀和 vs N(4, 8/12)：均值方差桶账
S8 = [sum(rand(8)) for _ in 1:300_000]
@assert abs(mean(S8) - 4) < 0.01
@assert abs(var(S8) - 8 / 12) < 0.01
# 中心区 P(3.5 ≤ S ≤ 4.5) 的正态近似质量（Simpson 免 erf）
# 偏差 ~0.007 是 CLT 近似的真实误差（均匀峰度 −1.2/8 的中心
# 效应），非模拟噪声——"极好拟合"仍留 0.7% 的中心差。
c = count(x -> 3.5 <= x <= 4.5, S8) / length(S8)
v = 8 / 12
phi(x) = exp(-(x - 4)^2 / (2 * v)) / sqrt(2 * pi * v)
h = 0.01
theo = (h / 3) * (phi(3.5) + phi(4.5)
    + sum((i % 2 == 0 ? 2 : 4) * phi(3.5 + i * h) for i in 1:99))
@assert abs(c - theo) < 0.012
println("sum of 8 uniforms: mean 4, var 8/12; center mass ", round(c, digits=4),
        " vs normal ", round(theo, digits=4), " (CLT error ~0.7%): OK")

# ③ 指数 λ = 2.5
myexp(λ) = -λ * log(rand())
X = [myexp(2.5) for _ in 1:500_000]
@assert abs(mean(X) - 2.5) < 0.02
@assert abs(var(X) - 6.25) < 0.15
println("exp(2.5): mean 2.5, var 6.25 = lambda^2: OK")

# ④ Erlang(1, n)：和的均值 n、方差 n
for n in (2, 8, 30)
    S = [sum(myexp(1.0) for _ in 1:n) for _ in 1:150_000]
    @assert abs(mean(S) - n) < 0.03 * n
    @assert abs(var(S) - n) < 0.04 * n
end
println("erlang n=2/8/30: mean=n, var=n: OK")

# ⑤ 足球：Exp(30 分钟) 上半场无球 e^{−1.5}
goals = [myexp(30.0) for _ in 1:500_000]
emp = count(>(45), goals) / length(goals)
@assert abs(emp - exp(-1.5)) < 0.004
println("soccer: P(no goal in 45min) ≈ e^{-1.5} = ", round(exp(-1.5), digits=4), ": OK")

# ⑥ 逆变换采样：经验分位数 vs −λ log(1−q)
Y = [myexp(3.0) for _ in 1:200_000]
@assert all(abs(quantile(Y, q) - (-3.0 * log(1 - q))) < 0.05
            for q in (0.25, 0.5, 0.75))
println("inverse transform: quantiles match -lambda*log(1-q): OK")

println("END ====")
