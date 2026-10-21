# -*- coding: utf-8 -*-
println("==== 17 chi_square")
# 第 17 章 Julia：卡方分布的频率形态。
# ① Z² 的样本矩 vs (1, 2)；② Σ_k 个 Z² 的矩 vs (k, 2k)；
# ③ χ²(2) 的经验 CDF vs 1−e^{−y/2}；④ 可加性：χ²(2)+χ²(5)
#    的样本矩 vs χ²(7) 的 (7, 14)；⑤ ν=20 的直方 vs 正态
#    近似 N(20, 40)（CLT 预告）。
using Random, Statistics

Random.seed!(17)

# ① Z² ~ χ²(1)
Y1 = randn(500_000) .^ 2
@assert abs(mean(Y1) - 1) < 0.005
@assert abs(var(Y1) - 2) < 0.02
println("Z^2: mean 1, var 2 = chi2(1) moments: OK")

# ② Σ_k 个 Z² ~ χ²(k)：k = 1, 3, 7
for k in (1, 3, 7)
    S = [sum(randn(k) .^ 2) for _ in 1:300_000]
    @assert abs(mean(S) - k) < 0.015 * k
    @assert abs(var(S) - 2k) < 0.06 * 2k
end
println("sum of k squared normals: mean=k, var=2k for k=1,3,7: OK")

# ③ χ²(2) 的 CDF 闭式：F(y) = 1 − e^{−y/2}
Y2 = [sum(randn(2) .^ 2) for _ in 1:400_000]
for y in (1.0, 2.0, 5.0)
    emp = count(<=(y), Y2) / length(Y2)
    @assert abs(emp - (1 - exp(-y / 2))) < 0.004
end
println("chi2(2): empirical CDF vs 1 - e^{-y/2}: OK")

# ④ 可加性：χ²(2) + χ²(5) 的矩 = χ²(7) 的 (7, 14)
W = [sum(randn(2) .^ 2) + sum(randn(5) .^ 2) for _ in 1:400_000]
@assert abs(mean(W) - 7) < 0.03
@assert abs(var(W) - 14) < 0.15
println("chi2(2)+chi2(5): sample moments match chi2(7) (7, 14): OK")

# ⑤ ν = 20：χ² 自身趋正态（μ=20、σ²=40 的中心区质量对照）
V = [sum(randn(20) .^ 2) for _ in 1:400_000]
@assert abs(mean(V) - 20) < 0.06
@assert abs(var(V) - 40) < 0.3
c = count(x -> 16 <= x <= 24, V) / length(V)      # ±1σ 区间
# N(20,40) 的 P(16≤X≤24)：Simpson 数值（免 erf）
phi20(x) = exp(-(x - 20)^2 / 80) / sqrt(2 * pi * 40)
h = 0.01
theo = (h / 3) * (phi20(16) + phi20(24)
    + sum((i % 2 == 0 ? 2 : 4) * phi20(16 + i * h) for i in 1:799))
@assert abs(c - theo) < 0.012                      # CLT 近似误差现场
println("chi2(20) vs N(20,40): center mass ", round(c, digits=4),
        " vs ", round(theo, digits=4), ": OK")

println("END ====")
