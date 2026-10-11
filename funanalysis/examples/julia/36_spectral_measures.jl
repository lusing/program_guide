using LinearAlgebra, Random
println("==== 36 spectral_measures (Julia) ====")
Random.seed!(3636)
n = 8
H0 = randn(n, n)
H = (H0 + H0') / 2
F = eigen(Hermitian(H))
λs, V = F.values, F.vectors

# 谱测度（PVM）：E(Δ) = Σ_{λᵢ∈Δ} vᵢ vᵢ*
E(Δ) = V * Diagonal([Δ(λ) for λ in λs]) * V'
I_n = Matrix{Float64}(I, n, n)

@assert norm(E(x -> false)) < 1e-12
@assert norm(E(x -> true) - I_n) < 1e-12
Δ1 = x -> x < 0
Δ2 = x -> x ≥ 0
E1 = E(Δ1)
E2 = E(Δ2)
@assert norm(E1 * E2) < 1e-12
@assert norm(E1 + E2 - I_n) < 1e-12
@assert norm(E1 * E1 - E1) < 1e-12
println("PVM 公理：E(∅)=0，E(ℝ)=I，不相交⟹正交，可加，幂等：✓")

# 谱积分：H = ∫ λ dE(λ)
@assert norm(V * Diagonal(λs) * V' - H) < 1e-12
println("∫ λ dE(λ) = H：✓")

# 函数演算：f(H) = ∫ f(λ) dE(λ)
@assert norm(V * Diagonal(λs .^ 2) * V' - H * H) < 1e-12
@assert norm(V * Diagonal(exp.(λs)) * V' - exp(H)) < 1e-10
println("f(H) = ∫ f dE（λ²、e^λ 双验证）：✓")
println("==== 36 spectral_measures END ====")
