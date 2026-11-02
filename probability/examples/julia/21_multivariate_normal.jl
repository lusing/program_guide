# -*- coding: utf-8 -*-
println("==== 21 multivariate_normal")
# 第 21 章 Julia：多元正态的模拟审计（Cholesky 生成 + 条件分布 + 反例）。
# ① Cholesky：X = μ + L Z，样本均值/协方差回收 μ,Σ
# ② 二元正态条件：Y|X=x 均值 μ2+ρσ2/σ1(x−μ1)，方差 σ2²(1−ρ²)
# ③ Mahalanobis² ~ χ²_p：均值 p、方差 2p、分位数与 χ² 对账
# ④ 线性变换 AX ~ N(Aμ, AΣAᵀ)；零相关块 ⇒ 独立
# ⑤ 反例：Y=SX 边际正态却非联合正态（X+Y 有原子）
# ⑥ Schur 补：条件协方差 = Σ_AA − Σ_AB Σ_BB⁻¹ Σ_BA
using Random, Statistics, LinearAlgebra

Random.seed!(21)
N = 400_000

# ① Cholesky 生成
μ = [1.0, -2.0, 0.5]
Σ = [4.0 2.0 1.0; 2.0 3.0 0.5; 1.0 0.5 2.0]
L = cholesky(Symmetric(Σ)).L
@assert maximum(abs.(L * L' - Σ)) < 1e-12
Z = randn(N, 3)
X = μ' .+ Z * L'
@assert maximum(abs.(vec(mean(X; dims=1)) - μ)) < 0.03
@assert maximum(abs.(cov(X) - Σ)) < 0.06
println("Cholesky generation recovers mu and Sigma: OK")

# ② 二元正态条件分布（用 σ1=2, σ2=1.5, ρ=0.6）
μ1, μ2, σ1, σ2, ρ = 1.0, -1.0, 2.0, 1.5, 0.6
U1 = randn(N); U2 = randn(N)
X1 = μ1 .+ σ1 .* U1
X2 = μ2 .+ σ2 .* (ρ .* U1 .+ sqrt(1 - ρ^2) .* U2)
@assert abs(cor(X1, X2) - ρ) < 0.005
for (lo, hi) in ((-1.0, 0.0), (0.5, 1.5), (2.0, 4.0))
    sel = (X1 .>= lo) .& (X1 .< hi)
    xm = mean(X1[sel])
    β = ρ * σ2 / σ1
    # 带内回归残差：均值 ≈ μ2+β(xm−μ1)，方差 ≈ σ2²(1−ρ²)（带内再扣掉 X1 变动贡献）
    res = X2[sel] .- β .* X1[sel]
    @assert abs(mean(res) - (μ2 - β * μ1)) < 0.03
    @assert abs(var(res) - σ2^2 * (1 - ρ^2)) < 0.05
end
println("bivariate conditional mean and variance 1-rho^2: OK")

# ③ Mahalanobis
D = X .- μ'
d2 = [dot(D[i, :], Σ \ D[i, :]) for i in 1:N]
@assert abs(mean(d2) - 3) < 0.03 && abs(var(d2) - 6) < 0.15
# χ²_3 的中位数 ≈ 2.366，95% 分位数 ≈ 7.815
@assert abs(median(d2) - 2.3660) < 0.04
@assert abs(mean(d2 .<= 7.8147) - 0.95) < 0.003
println("Mahalanobis squared distance ~ chi2_3: OK")

# ④ 线性变换与独立块
A = [1.0 -1.0 0.0; 0.5 0.5 2.0]
Y = X * A'
@assert maximum(abs.(cov(Y) - A * Σ * A')) < 0.12
Σb = [2.0 0.0; 0.0 3.0]
W = randn(N, 2) * cholesky(Symmetric(Σb)).L'
@assert abs(cor(W[:, 1], W[:, 2])) < 0.01
@assert abs(cor(W[:, 1] .^ 2, W[:, 2] .^ 2)) < 0.01     # 联合正态零相关 ⇒ 平方也不相关
println("linear map and independent blocks: OK")

# ⑤ 反例 Y = S X
Xr = randn(N)
S = rand([-1.0, 1.0], N)
Yr = S .* Xr
@assert abs(cov(Xr, Yr)) < 0.01
@assert abs(var(Yr) - 1) < 0.01
@assert abs(mean(abs.(Xr .+ Yr) .< 1e-12) - 0.5) < 0.005   # X+Y 在 0 处有一半质量
@assert abs(cor(Xr .^ 2, Yr .^ 2) - 1) < 1e-9              # |Y|=|X| ⇒ 平方完全相关
println("sign-flip counterexample: uncorrelated yet dependent: OK")

# ⑥ Schur 补
A_idx, B_idx = [1, 2], [3]
Σaa = Σ[A_idx, A_idx]; Σab = Σ[A_idx, B_idx]; Σbb = Σ[B_idx, B_idx]
βc = Σab / Σbb
schur = Σaa - Σab * (Σbb \ Σab')
Λ = inv(Σ)
@assert maximum(abs.(schur - inv(Λ[A_idx, A_idx]))) < 1e-12
res = X[:, A_idx] .- (X[:, B_idx] .- μ[B_idx]') * βc'
@assert maximum(abs.(cov(res) - schur)) < 0.06
@assert maximum(abs.(cov(res, X[:, 3]))) < 0.02              # 残差与条件变量不相关
println("Schur complement conditional covariance: OK")
println("END ====")
