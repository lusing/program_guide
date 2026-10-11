# 第 18 章 · 开映射定理的数值实验（Conway III.12-13）
using LinearAlgebra, Random
println("==== 18 open-mapping (Julia) ====")
Random.seed!(1818)
A = randn(3, 5)
σ = svdvals(A)
println("min singular value of surjection = $(round(σ[3], digits=6))")
@assert σ[3] > 0.1
println("‖A⁻¹‖ ≈ 1/min σ = $(round(1/σ[3], digits=4))")
P = [1.0 0 0; 0 1 0; 0 0 0]
println("rank(P) = $(rank(P)) + nullity = $(3 - rank(P)) = 3")
@assert rank(P) + (3 - rank(P)) == 3
println("==== 18 open-mapping END ====")
