# -*- coding: utf-8 -*-
println("==== 08 random_variables")
using Random, Statistics
Random.seed!(8)

binom(n, k) = k < 0 || k > n ? 0 :
    (k == 0 ? 1 : binom(n, k - 1) * (n - k + 1) ÷ k)

# 离散侧：概率树逐路径连乘，再按正面数折层。
function tree_fold_pmf(n, p)
    pmf = zeros(n + 1)
    for m in 0:(2^n - 1)
        k = count_ones(m)
        prob = 1.0
        for i in 0:(n - 1)
            prob *= ((m >> i) & 1 == 1 ? p : 1 - p)
        end
        pmf[k + 1] += prob
    end
    pmf
end
pmf = tree_fold_pmf(6, 0.3)
for k in 0:6
    @assert abs(pmf[k + 1] - binom(6, k) * 0.3^k * 0.7^(6-k)) < 1e-12
end
@assert sum(pmf) ≈ 1
println("discrete probability tree folds to binomial pmf: OK")

# CDF 阶梯与区间公式。
cdf = cumsum(pmf)
@assert cdf[5] - cdf[2] ≈ sum(pmf[3:5])
@assert all(diff(cdf) .>= 0)
println("discrete CDF is monotone and recovers interval mass: OK")

# 连续侧：F(x)=x^2 的逆变换采样，目标概率来自精确 CDF。
X = sqrt.(rand(500_000))
@assert abs(count(<=(0.25), X) / length(X) - 1/16) < 0.003
@assert abs(mean(X) - 2/3) < 0.004
println("continuous density 2x: inverse-CDF simulation near exact anchors: OK")

# 多项式密度用拒绝采样审计 F(1/2)=7/11。
fpoly(x) = (6/11) * (2 + 3x - 5x^2)
function sample_poly(n)
    out = Float64[]
    while length(out) < n
        x, u = rand(), rand()
        u * 1.5 <= fpoly(x) && push!(out, x)
    end
    out
end
Y = sample_poly(100_000)
@assert abs(count(<=(0.5), Y) / length(Y) - 7/11) < 0.006
println("polynomial density: rejection sample near exact CDF: OK")

# 混合型广义逆：0 处原子 1/2，其余质量均匀铺在 (0,1)。
U = rand(500_000)
M = [u <= 0.5 ? 0.0 : 2 * (u - 0.5) for u in U]
@assert abs(count(==(0.0), M) / length(M) - 0.5) < 0.003
@assert abs(count(x -> 0 < x <= 0.5, M) / length(M) - 0.25) < 0.003
println("mixed distribution: atom and continuous interval kept separate: OK")

println("END ====")
