# 第 35 章 Julia：sandwich 方差、误设与固定种子覆盖率审计。
using LinearAlgebra
using Random
using Statistics
println("==== 35 asymptotic estimation")

scalar_sandwich(a, j) = (@assert a != 0; j / a^2)
@assert scalar_sandwich(-1 // 1, 4 // 1) == 4
@assert scalar_sandwich(-1 // 1, 1 // 1) == 1

# Poisson 伪似然的均值估计：V=Var_Q(X)/lambda*^2。
lam, true_variance = 2 // 1, 5 // 1
a_pois = -1 / lam
j_pois = true_variance / lam^2
@assert scalar_sandwich(a_pois, j_pois) == true_variance == 5
@assert lam == 2  # 正确 Poisson 模型下，sqrt(n) 渐近方差才会化成 lambda。
println("quasi-normal variance: ", scalar_sandwich(-1 // 1, 4 // 1),
        "; quasi-Poisson variance: ", scalar_sandwich(a_pois, j_pois))

# GMM 一般 sandwich 与 W=S^{-1} 的化简。
g = ones(2, 1)
s = diagm([1.0, 4.0])
function gmm_asymptotic_variance(g, w, s)
    gwg = g' * w * g
    inv(gwg) * (g' * w * s * w * g) * inv(gwg)
end
omega_i = gmm_asymptotic_variance(g, Matrix{Float64}(I, 2, 2), s)
omega_star = gmm_asymptotic_variance(g, inv(s), s)
@assert isapprox(omega_i[1], 1.25)
@assert isapprox(omega_star[1], 0.8)
@assert isapprox(omega_star, inv(g' * inv(s) * g))
q, p = 2, 1
@assert q - p == 1
println("GMM sandwich and optimal variance: ", omega_i[1], ", ", omega_star[1])

# X=1+2E，E~Exp(1)，工作模型 N(mu,1)，伪真均值 mu*=3。
# 固定种子模拟仅审计有限样本表现，不能替代上面的渐近推导。
Random.seed!(35)
reps, n = 20_000, 200
samples = 1 .+ 2 .* randexp(reps, n)
estimates = vec(mean(samples, dims=2))
robust_ses = vec(std(samples, dims=2, corrected=true)) ./ sqrt(n)
naive_se = 1 / sqrt(n)
pseudo_true = 3.0
naive_coverage = mean(abs.(estimates .- pseudo_true) .<= 1.96 .* naive_se)
robust_coverage = mean(abs.(estimates .- pseudo_true) .<= 1.96 .* robust_ses)
empirical_se = std(estimates, corrected=true)
@assert 1.95 < empirical_se / naive_se < 2.05
@assert 0.62 < naive_coverage < 0.72
@assert 0.93 < robust_coverage < 0.96
println("simulation: empirical/naive SE ratio: ", empirical_se / naive_se)
println("simulation: naive/robust 95% coverage: ", naive_coverage, ", ", robust_coverage)
println("END ====")
