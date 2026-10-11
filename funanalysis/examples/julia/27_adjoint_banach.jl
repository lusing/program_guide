using LinearAlgebra, Random
println("==== 27 adjoint_banach (Julia) ====")
Random.seed!(2727)
n = 6
A = randn(n, n)

# Banach 伴随：(ℓ¹ₙ)* = ℓ∞ₙ，A 的伴随由转置实现
# ‖A‖₁ = ‖Aᵀ‖∞（列绝对和 = 转置的行绝对和）
println("‖A‖₁  = $(round(opnorm(A, 1), digits=6))")
println("‖Aᵀ‖∞ = $(round(opnorm(A', Inf), digits=6))")
@assert abs(opnorm(A, 1) - opnorm(A', Inf)) < 1e-12
println("‖A‖∞  = $(round(opnorm(A, Inf), digits=6))")
println("‖Aᵀ‖₁ = $(round(opnorm(A', 1), digits=6))")
@assert abs(opnorm(A, Inf) - opnorm(A', 1)) < 1e-12
println("伴随保范：‖A*‖ = ‖A‖（按 ℓ¹/ℓ∞ 对偶实现）：✓")

# 零化子关系：ker(Aᵀ) = range(A)⊥（有限维化身，用亏秩阵才有非平凡核）
W = randn(n, n)[:, 1:5] * randn(5, n)
K = nullspace(W')
@assert size(K, 2) >= 1
allperp = let ok = true
    for _ in 1:5
        x = randn(n)
        ok = ok && norm(K' * (W * x)) < 1e-10
    end
    ok
end
@assert allperp
println("ker(Aᵀ) ⊥ range(A)：✓")

# Banach-Stone：ℓ¹ₙ 的等距 = 符号置换矩阵
perm = randperm(n)
T = diagm(rand([1.0, -1.0], n)) * Matrix(I, n, n)[perm, :]
isoflag = let ok = true
    for _ in 1:5
        x = randn(n)
        ok = ok && abs(sum(abs.(T * x)) - sum(abs.(x))) < 1e-10
    end
    ok
end
@assert isoflag
println("符号置换保持 ℓ¹ 范数（Banach-Stone 有限维化身）：✓")
B = randn(n, n); x = randn(n)
println("一般矩阵 ℓ¹ 范数比 = $(round(sum(abs.(B * x)) / sum(abs.(x)), digits=4)) ≠ 1")
println("==== 27 adjoint_banach END ====")
