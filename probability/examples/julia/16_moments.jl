# -*- coding: utf-8 -*-
println("==== 16 moments")
# 第 16 章 Julia：卷积与微分恒等式的频率、数值形态。
# ① 截断和 vs 闭式（Σn/2ⁿ → 2、Σn²/2ⁿ → 6 的收敛演示）；
# ② 二项矩的模拟对拍（均值 np、方差 np(1−p)）；
# ③ 正态偶矩 (2k−1)!! 的样本矩对拍（k 到 4）；
# ④ 指数矩 k!·λᵏ 的样本矩对拍（k 到 4）。
using Random, Statistics

Random.seed!(12)

# ① 几何微分链：闭式 Σnxⁿ = x/(1−x)²、Σn²xⁿ = x(1+x)/(1−x)³
x = 0.5
s1 = sum(n * x^n for n in 1:10_000)
s2 = sum(n^2 * x^n for n in 1:10_000)
@assert abs(s1 - x / (1 - x)^2) < 1e-9          # 2
@assert abs(s2 - x * (1 + x) / (1 - x)^3) < 1e-6  # 6
# 截断速度：N = 10 时 Σn/2ⁿ 距极限 2 仅 3/256（尾项公式 (N+2)/2^N）
trunc10 = sum(n / 2^n for n in 1:10)
@assert abs(trunc10 - (2 - 12 / 2^10)) < 1e-12
println("geometric derivative chain: sums -> 2 and 6, tail at N=10 is 3/256: OK")

# ② 二项矩：n = 10、p = 0.3 模拟 vs np / np(1−p)
n, p = 10, 0.3
function sim_binom_counts(n, p, trials)
    [begin
        c = 0
        for _ in 1:n
            rand() < p && (c += 1)
        end
        c
    end for _ in 1:trials]
end
B = sim_binom_counts(n, p, 1_000_000)
@assert abs(mean(B) - n * p) < 0.01
@assert abs(var(B) - n * p * (1 - p)) < 0.015
println("binomial moments: mean≈3, var≈2.1 = np(1-p): OK")

# ③ 正态偶矩 M(2k) = (2k−1)!!：样本矩对拍（k 到 4）
G = randn(2_000_000)
dfacts = cumprod(2 .* (1:4) .- 1)                  # [3, 15, 105, 945]
for k in 1:4
    m = mean(g -> g^(2k), G)
    @assert abs(m - dfacts[k]) < 0.02 * dfacts[k]  # 2% 相对容差
end
println("normal even moments 3,15,105,945 by sampling: OK")

# ④ 指数矩 E[X^k] = k!·λᵏ：样本矩对拍（λ = 2，k 到 4）
λ = 2.0
Xs = -λ .* log.(rand(1_000_000))
for k in 1:4
    fact = factorial(k)
    m = mean(x -> x^k, Xs)
    @assert abs(m - fact * λ^k) < 0.03 * fact * λ^k
end
println("exponential moments k!*lambda^k by sampling (lambda=2): OK")

println("END ====")
