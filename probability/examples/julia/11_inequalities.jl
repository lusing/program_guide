# -*- coding: utf-8 -*-
println("==== 11 inequalities")
using Random, Statistics
Random.seed!(11)

# Markov 等号分布与指数分布对照；模拟只审计数值实现。
mu = 2.0
for a in (4.0, 10.0)
    p = mu / a
    X = [rand() < p ? a : 0.0 for _ in 1:300_000]
    @assert abs(mean(X) - mu) < 0.03
    @assert abs(count(>=(a), X) / length(X) - p) < 0.004
end
println("Markov tight two-point examples near equality: OK")

# Chebyshev：正态真尾概率远低于通用界。
Z = randn(1_000_000)
for (k, bound) in ((2, 0.25), (5, 0.04), (10, 0.01))
    empirical = count(z -> abs(z) >= k, Z) / length(Z)
    @assert empirical < bound
end
# 方差误当标准差会给出 25/729<0.05 的假界。
@assert 25/729 < 0.05 < 100/243
println("Chebyshev bounds and sigma/variance trap: OK")

# Jensen 间隙恰为方差；这里用精确分布公式而非样本均值。
EX, EX2 = 1//1, 2//1
@assert EX2 - EX^2 == 1
@assert EX2 > EX^2
println("Jensen quadratic gap equals variance: OK")

# WLLN 入口：固定种子模拟频率低于确定性 Chebyshev 界。
for (n, reps) in ((100, 20_000), (1_000, 10_000))
    hits = 0
    for _ in 1:reps
        xbar = sum(randexp() for _ in 1:n) / n
        abs(xbar - 1.0) >= 0.1 && (hits += 1)
    end
    empirical = hits / reps
    bound = 1 / (n * 0.1^2)
    @assert empirical < bound
end
println("WLLN simulation stays below sigma^2/(n eps^2): OK")

println("END ====")
