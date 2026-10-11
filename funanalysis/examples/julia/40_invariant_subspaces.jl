using LinearAlgebra, Random
println("==== 40 invariant_subspaces (Julia) ====")
Random.seed!(4040)
n = 6
I_n = Matrix{Float64}(I, n, n)

# 不变子空间：AV ⊆ V。上三角阵天然有不变旗 span(e₁..eₖ)
A = Matrix(UpperTriangular(randn(n, n)))
for k in 1:n-1
    V = I_n[:, 1:k]
    @assert norm((I_n - V * V') * A * V) < 1e-10
end
println("上三角阵：span(e₁..eₖ) 对每个 k 不变：✓")

# 约化子空间 = 对 A 与 A* 都不变。正规算子的特征空间自动约化
H0 = randn(n, n) + im * randn(n, n)
H = H0 + H0'
F = eigen(Hermitian(H))
v, λ = F.vectors[:, 1], F.values[1]
@assert norm(H * v - λ * v) < 1e-10
@assert norm(H' * v - λ' * v) < 1e-10
println("正规算子：一维特征空间同时约化 A 与 A*：✓")

# 非正规反例：后移 S 的 span(e₁) 不变但不约化
S = zeros(n, n)
for i in 2:n
    S[i-1, i] = 1.0      # S eₖ = eₖ₋₁，S e₁ = 0
end
e1 = zeros(n); e1[1] = 1.0
e2 = zeros(n); e2[2] = 1.0
@assert norm(S * e1) < 1e-12            # S(span e₁) ⊆ span e₁
@assert norm(S' * e1 - e2) < 1e-12      # S* e₁ = e₂ ∉ span e₁
println("span(e₁) 对后移不变，但 S*e₁ = e₂ 越出（不约化）：✓")

# 重数：代数重数 vs 几何重数（特征空间维数）
J = Array(Bidiagonal(ones(4), ones(3), :U))    # Jordan 块 λ = 1
g = size(nullspace(J - Matrix(I, 4, 4)), 2)
println("4 阶 Jordan 块：代数重数 4，几何重数 $g")
@assert g == 1
println("==== 40 invariant_subspaces END ====")
