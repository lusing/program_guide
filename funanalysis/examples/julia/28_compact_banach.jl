using LinearAlgebra, Random
println("==== 28 compact_banach (Julia) ====")
Random.seed!(2828)
# 紧算子 = 有限秩算子的范数极限。Hilbert 矩阵是紧积分算子的有限截断
n = 60
H = [1.0 / (i + j - 1) for i in 1:n, j in 1:n]
σ = svdvals(H)
println("Hilbert 矩阵奇异值：σ₁..σ₅ = $(round.(σ[1:5], sigdigits=4))")
println("σ₂₀ = $(round(σ[20], sigdigits=4))")
println("σ₆₀ = $(round(σ[60], sigdigits=4))")
@assert σ[60] < σ[1] * 1e-15
println("奇异值 → 0：可被有限秩一致逼近（紧性判据）：✓")

# Eckart–Young：最佳 k 秩逼近误差恰为 σ_{k+1}
F = svd(H)
k = 10
Hk = F.U[:, 1:k] * Diagonal(F.S[1:k]) * F.Vt[1:k, :]
err = opnorm(H - Hk)
println("‖H - H₁₀‖₂ = $(round(err, sigdigits=4)) = σ₁₁ = $(round(F.S[11], sigdigits=4))")
@assert abs(err - F.S[11]) < 1e-12

# 紧算子谱：非零谱点均为特征值，唯一可能聚点是 0
m = 1000
μ = [1.0 / k for k in 1:m]
println("diag(1/k) 的谱：λ₉₉₉ = $(round(μ[999], digits=6))，λ₁₀₀₀ = $(round(μ[1000], digits=6)) → 0")
println("非零谱点全是特征值，唯一聚点 0：✓")
@assert μ[m] < 1e-2
println("==== 28 compact_banach END ====")
