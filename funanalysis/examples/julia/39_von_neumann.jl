using LinearAlgebra, Random
println("==== 39 von_neumann (Julia) ====")
Random.seed!(3939)
n = 6
I_n = Matrix{Float64}(I, n, n)

unvec(v) = reshape(v, n, n)
# 交换子方程 SX = XS 的核：kron(I,S) - kron(Sᵀ,I) 作用于 vec(X)
comm_kernel(S) = nullspace(kron(I_n, S) - kron(transpose(S), I_n), rtol = 1e-8)

# 1) 对角阵（互异对角元）的交换子 = 对角阵全体
D = Diagonal(collect(1.0:n))
N1 = comm_kernel(D)
println("dim {D}' = $(size(N1, 2))（= n：对角阵全体）")
@assert size(N1, 2) == n
alldiag = let ok = true
    for j in 1:size(N1, 2)
        X = unvec(N1[:, j])
        ok = ok && norm(X - Diagonal(diag(X))) < 1e-6
    end
    ok
end
@assert alldiag
println("核中元素全部是对角阵：✓")

# 2) 循环移位的交换子 = 循环阵全体（S 的多项式）
S = zeros(n, n)
for i in 1:n-1
    S[i+1, i] = 1.0
end
S[1, n] = 1.0
N2 = comm_kernel(S)
println("dim {S}' = $(size(N2, 2))（= n：循环阵全体）")
@assert size(N2, 2) == n
function is_circulant(X, tol)
    all(1:size(X, 1)) do i
        norm(X[i, :] - circshift(X[1, :], i - 1)) < tol
    end
end
allcirc = all(is_circulant(unvec(N2[:, j]), 1e-6) for j in 1:size(N2, 2))
@assert allcirc
println("循环移位的交换子恰为循环阵（= S 的多项式）：✓")

# 3) 双交换子定理（有限维化身）：{S}'' = {S}' = vN(S)
a = randn(n)
C = sum(a[k+1] * (S^k) for k in 0:n-1)
N3 = comm_kernel(C)
println("dim {S}'' = $(size(N3, 2)) = dim {S}' = $n")
@assert size(N3, 2) == n
allcirc2 = all(is_circulant(unvec(N3[:, j]), 1e-6) for j in 1:size(N3, 2))
@assert allcirc2
println("双交换子 = 交换子 = 生成的 *-代数（bicommutant 定理）：✓")
println("==== 39 von_neumann END ====")
