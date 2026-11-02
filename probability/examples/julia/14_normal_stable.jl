# -*- coding: utf-8 -*-
println("==== 14 normal_stable")
# 第 14 章 Julia：正态分布与稳定性的频率形态。
# ① 标准正态样本均值 0、方差 1；② 偶矩 vs (2m−1)!!；
# ③ 和稳定性模拟（X+Y 的矩 vs N(μX+μY, σX²+σY²)）；
# ④ 68-95-99.7 经验频率；⑤ μ+a 对称性频率对照。
using Random, Statistics

Random.seed!(15)

# ① 标准正态
Z = randn(2_000_000)
@assert abs(mean(Z)) < 0.005
@assert abs(var(Z) - 1) < 0.005
println("standard normal: mean 0, var 1: OK")

# ② 偶矩：样本矩 vs (2m−1)!!（cumprod 免软作用域）
dfs = cumprod(2 .* (1:4) .- 1)          # [3, 15, 105, 945]
for m in 1:4
    sm = mean(z -> z ^ (2m), Z)
    @assert abs(sm - dfs[m]) < 0.02 * dfs[m]
end
println("even moments 3,15,105,945 by sampling: OK")

# ③ 和稳定性：X~N(1,4), Y~N(3,9) → X+Y ~ N(4,13)
X = 1 .+ 2 .* randn(1_000_000)
Y = 3 .+ 3 .* randn(1_000_000)
S = X .+ Y
@assert abs(mean(S) - 4) < 0.02
@assert abs(var(S) - 13) < 0.06
# 形状检查：偏度应接近 0（正态峰度 3、偏度 0）
sk = mean(((S .- 4) ./ sqrt(13)) .^ 3)
@assert abs(sk) < 0.02
println("stability: N(1,4)+N(3,9) has moments of N(4,13), skewness~0: OK")

# ④ 68-95-99.7
for (k, tgt) in [(1, 0.6827), (2, 0.9545), (3, 0.9973)]
    emp = count(z -> abs(z) <= k, Z) / length(Z)
    @assert abs(emp - tgt) < 0.003
end
println("68-95-99.7 empirical: OK")

# ⑤ 对称性：P(X ≤ μ−a) = P(X ≥ μ+a)（μ = 2、a = 1）
W = 2 .+ randn(1_000_000)
lo = count(<=(1.0), W) / length(W)
hi = count(>=(3.0), W) / length(W)
@assert abs(lo - hi) < 0.003
println("symmetry about mu: P(X<=mu-a) = P(X>=mu+a): OK")

# ⑥ 对数正态：E[Y]=exp(μ+σ²/2) 大于中位数 exp(μ)；Cauchy 样本均值不稳
LN = exp.(0.4 .+ 0.7 .* randn(2_000_000))
@assert abs(mean(LN) - exp(0.4 + 0.7^2 / 2)) < 0.02
@assert abs(median(LN) - exp(0.4)) < 0.01
@assert mean(LN) > median(LN)
cauchy() = tan(pi * (rand() - 0.5))
Cs = cumsum([cauchy() for _ in 1:200_000])
m1, m2 = Cs[50_000] / 50_000, Cs[200_000] / 200_000
println("lognormal mean>median: OK; cauchy running means ", round(m1, digits=3),
        " vs ", round(m2, digits=3), " (no LLN)")

println("END ====")
