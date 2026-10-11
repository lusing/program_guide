using LinearAlgebra, Random
println("==== 35 positive_elements (Julia) ====")
Random.seed!(3535)
n = 5

# 正元：A = B*B ⟺ A 自伴且 σ(A) ⊆ [0, ∞)
B = randn(n, n) + im * randn(n, n)
A = B' * B
λA = eigen(Hermitian(A)).values
println("B*B 的特征值：$(round.(λA, digits=4))  全部 > 0")
@assert all(λA .> 0)

# 平方根：S = V√ΛV*，S² = A 且 S 仍正
F = eigen(Hermitian(A))
S = F.vectors * Diagonal(sqrt.(F.values)) * F.vectors'
println("‖S² - A‖/‖A‖ = $(round(norm(S * S - A) / norm(A), digits=12))")
@assert norm(S * S - A) / norm(A) < 1e-12
λS = eigen(Hermitian(S)).values
@assert all(λS .> 0)
println("正元的正平方根存在（数值验证）：✓")

# 反例：含负特征值的自伴元不是 B*B
C = randn(n, n); C = (C + C') / 2
λC = eigen(Hermitian(C)).values
println("随机自伴阵最小特征值 $(round(minimum(λC), digits=4)) < 0 ⟹ 非正")
@assert minimum(λC) < 0

# 正元构成闭凸锥
B2 = randn(n, n) + im * randn(n, n); A2 = B2' * B2
@assert all(eigen(Hermitian(A + A2)).values .> 0)
@assert all(eigen(Hermitian(2.7 * A)).values .> 0)
println("A,B 正 ⟹ A+B 正；t>0 ⟹ tA 正（闭凸锥）：✓")
println("==== 35 positive_elements END ====")
