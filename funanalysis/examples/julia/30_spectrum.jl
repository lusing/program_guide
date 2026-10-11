using LinearAlgebra, Random
println("==== 30 spectrum (Julia) ====")
Random.seed!(3030)
A = randn(5, 5)
λ = eigen(A).values
println("eigenvalues: $(round.(λ, digits=4))")
# 谱半径 = max|λ| vs 范数
ρ = maximum(abs.(λ))
println("spectral radius ρ(A) = $(round(ρ, digits=4))")
println("opnorm(A) = $(round(opnorm(A), digits=4))")
@assert ρ ≤ opnorm(A)
# 谱 Neumann 级数：ρ(A) < 1 ⟹ Σ Aⁿ 收敛
B = 0.3 * randn(5, 5)  # ρ(B) < 1 almost surely
ρB = maximum(abs.(eigen(B).values))
println("ρ(B) = $(round(ρB, digits=4)) < 1 ⟹ I-B invertible")
@assert ρB < 0.8
println("==== 30 spectrum END ====")
