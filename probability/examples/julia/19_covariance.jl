# -*- coding: utf-8 -*-
println("==== 19 covariance")
# 第 19 章 Julia：协方差、相关、组合风险（固定种子模拟审计 + LinearAlgebra）。
# ① 样本协方差矩阵半正定（特征值 ≥ 0），Var(wᵀX)=wᵀΣw；
# ② 不相关但不独立：X~U(−1,1)，Y=X²：样本相关≈0，但 P(|X|<½, Y>½)=0 ≠ 积；
# ③ 相关系数界：随机生成的数据 |r|≤1；Y=aX+b 时 r=±1；
# ④ 投资组合：σ₁=.2,σ₂=.3,ρ=.5 的 w*=6/7、Var*=27/700 的网格对账；
# ⑤ 方差 σ²/n + (1−1/n)ρσ² 的等相关组合；
# ⑥ 多元 Chebyshev：Mahalanobis D² 的 P(D²≥t) ≤ d/t（经验上成立）。
using Random, Statistics, LinearAlgebra

Random.seed!(19)

# ① 半正定与二次型
N = 200_000
Z = randn(N, 3)
L = [1.0 0 0; 0.6 0.8 0; -0.3 0.5 0.9]
X = Z * L'                       # 协方差 Σ = L Lᵀ
Σhat = cov(X)
Σ = L * L'
@assert maximum(abs.(Σhat .- Σ)) < 0.02
@assert all(eigvals(Symmetric(Σhat)) .>= -1e-12)
w = [0.5, -1.0, 2.0]
@assert abs(var(X * w) - dot(w, Σ * w)) < 0.15
println("① sample covariance PSD, Var(wᵀX) = wᵀΣw: OK")

# ② 不相关但不独立
U = 2 .* rand(N) .- 1; V = U .^ 2
@assert abs(cor(U, V)) < 0.01
pj = mean((abs.(U) .< 0.5) .& (V .> 0.5))
pp = mean(abs.(U) .< 0.5) * mean(V .> 0.5)
@assert pj == 0.0 && pp > 0.1
println("② uncorrelated but dependent: cor≈0, joint 0 vs product ≈ $(round(pp, digits=3)): OK")

# ③ 相关系数界
for _ in 1:200
    a = randn(30); b = randn(30)
    @assert abs(cor(a, b)) <= 1 + 1e-12
end
a = randn(1000)
@assert abs(cor(a, 3 .* a .+ 2) - 1) < 1e-12
@assert abs(cor(a, -0.5 .* a .+ 7) + 1) < 1e-12
println("③ |r| ≤ 1 on 200 random samples; affine ⇒ r=±1: OK")

# ④ 投资组合
σ1, σ2, ρ = 0.2, 0.3, 0.5
var_p(w) = w^2 * σ1^2 + (1 - w)^2 * σ2^2 + 2 * w * (1 - w) * ρ * σ1 * σ2
wstar = (σ2^2 - ρ * σ1 * σ2) / (σ1^2 + σ2^2 - 2ρ * σ1 * σ2)
@assert abs(wstar - 6 / 7) < 1e-12
@assert abs(var_p(wstar) - 27 / 700) < 1e-12
grid = 0:0.0001:1
@assert minimum(var_p.(grid)) >= var_p(wstar) - 1e-12
@assert abs(grid[argmin(var_p.(grid))] - wstar) < 1e-4
# 模拟：两个相关资产的组合样本方差
Z1 = randn(N); Z2 = randn(N)
R1 = σ1 .* Z1; R2 = σ2 .* (ρ .* Z1 .+ sqrt(1 - ρ^2) .* Z2)
port = wstar .* R1 .+ (1 - wstar) .* R2
@assert abs(var(port) - 27 / 700) < 0.002
@assert var(port) < min(var(R1), var(R2))
println("④ minimum-variance weight 6/7, Var 27/700 ≈ $(round(27/700, digits=5)), grid and simulation agree: OK")

# ⑤ 等相关组合
σ = 1.0; ρe = 0.3
for n in (1, 2, 5, 20, 100)
    Σe = fill(ρe * σ^2, n, n) + (1 - ρe) * σ^2 * I(n)
    wv = fill(1 / n, n)
    @assert abs(dot(wv, Σe * wv) - (σ^2 / n + (1 - 1 / n) * ρe * σ^2)) < 1e-12
end
@assert abs(σ^2 / 10_000 + (1 - 1e-4) * ρe * σ^2 - ρe) < 1e-4
println("⑤ equicorrelated portfolio: Var = σ²/n + (1−1/n)ρσ², floor ρσ²: OK")

# ⑥ 多元 Chebyshev
μ = mean(X, dims=1)
Σinv = inv(Σhat)
D2 = [ (X[i, :] .- vec(μ))' * Σinv * (X[i, :] .- vec(μ)) for i in 1:N ]
@assert abs(mean(D2) - 3) < 0.05                 # E[D²]=d=3
for t in (3.0, 6.0, 12.0)
    @assert mean(D2 .>= t) <= 3 / t + 1e-3
end
println("⑥ multivariate Chebyshev: E[D²]=3, P(D²≥t) ≤ 3/t: OK")

println("END ====")
