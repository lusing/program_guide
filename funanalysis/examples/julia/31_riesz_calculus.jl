using LinearAlgebra, Random
println("==== 31 riesz_calculus (Julia) ====")
Random.seed!(3131)
n = 6
A = randn(n, n)

# 全纯泛函演算：f(A) = V f(D) V⁻¹，与幂级数定义一致
S = let acc = Matrix{Float64}(I, n, n), term = Matrix{Float64}(I, n, n)
    for k in 1:40
        term = term * A / k          # term = Aᵏ/k!
        acc += term
    end
    acc
end
F = eigen(A)
exp_eig = F.vectors * Diagonal(exp.(F.values)) / F.vectors
println("‖Σ Aᵏ/k! - V e^D V⁻¹‖ = $(round(norm(S - exp_eig), digits=8))")
@assert norm(S - exp_eig) < 1e-7
println("‖Σ Aᵏ/k! - exp(A)‖ = $(round(norm(S - exp(A)), digits=8))")
@assert norm(S - exp(A)) < 1e-8
println("幂级数 = 谱演算 = 内置 exp(A)：✓")

# Riesz 投影：隔离谱子集的投影。取 Re λ > 0 的特征值
pos = real.(F.values) .> 0
P = F.vectors * Diagonal(float.(pos)) / F.vectors
println("P² - P 的范数 = $(round(norm(P * P - P), digits=8))")
@assert norm(P * P - P) < 1e-8
println("AP - PA 的范数 = $(round(norm(A * P - P * A), digits=8))")
@assert norm(A * P - P * A) < 1e-7
println("rank P = $(rank(P)) = #(Re λ > 0) = $(count(pos))")
@assert rank(P) == count(pos)
println("Riesz 投影幂等、与 A 交换、秩 = 围道内谱点数：✓")
println("==== 31 riesz_calculus END ====")
