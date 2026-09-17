# 13 线性代数与稀疏矩阵 ⭐：分解族、最小二乘、特征值/SVD、SparseArrays、BLAS 线程
# 运行：julia --startup-file=no main.jl

using LinearAlgebra
using SparseArrays
using Random

# ═══ 13.1 分解（factorization）：一次分解、多次求解
A = [2.0 1.0; 1.0 3.0]
b1, b2 = [3.0, 4.0], [1.0, 2.0]
F = lu(A)                        # LU 分解（带部分选主元）
@assert F \ b1 ≈ A \ b1
@assert F \ b2 ≈ A \ b2          # 分解复用：第二次求解只做回代，不再重算分解
println("lu 复用求解一致：", F \ b1 ≈ A \ b1, "；F 类型 = ", typeof(F).name.name)

# 对称正定 → Cholesky（约 2 倍速、无选主元）；非正定抛 PosDefException（异常族见 22 章）
C = [4.0 2.0; 2.0 3.0]           # 对称正定
Lc = cholesky(C).L
@assert Lc * Lc' ≈ C
@assert cholesky(C) \ [2.0, 5.0] ≈ C \ [2.0, 5.0]
@assert isposdef(C) && !isposdef([1.0 2.0; 2.0 1.0])
 PosDef = try
    cholesky([1.0 2.0; 2.0 1.0])
    false
catch e
    e isa PosDefException        # 不定矩阵：Cholesky 拒绝——数值属性也是类型化异常
end
@assert PosDef

# ═══ 13.2 特征值与奇异值：eigen / svd / rank / cond
sym = [2.0 0.0; 0.0 5.0]
E = eigen(sym)
@assert E.values ≈ [2.0, 5.0]
@assert E.vectors' * sym * E.vectors ≈ Diagonal(E.values)     # 正交对角化（对称矩阵特权）
M = [3.0 1.0; 1.0 3.0; 0.0 1.0]  # 3×2：奇异值分解把"任何"矩阵变成正交×对角×正交
U, S, V = svd(M)
@assert U * Diagonal(S) * V' ≈ M                              # 低秩重建
@assert rank(M) == 2 && cond(M) > 1                           # 满秩；条件数衡量"解对扰动的敏感度"
println("cond(M) = ", round(cond(M); digits = 3), "——越小越良态")

# ═══ 13.3 最小二乘：矩形 A\b（内部走 QR），残差正交于列空间
xs = collect(0.0:0.5:5.0)       # 11 个采样点
noise = [0.04, -0.03, 0.02, -0.05, 0.03, 0.01, -0.02, 0.05, -0.01, 0.03, -0.04]
ys = 1.2 .* xs .+ 0.5 .+ noise  # 真值 y = 0.5 + 1.2x + 固定噪声
V = [x^d for x in xs, d in 0:1] # Vandermonde 设计矩阵（11×2）
coef = V \ ys                   # 最小二乘拟合 y = a + b·x
@assert isapprox(coef[1], 0.5; atol = 0.03) && isapprox(coef[2], 1.2; atol = 0.03)   # @assert 不认 ≈ atol=（17 章坑）
resid = V * coef - ys
@assert isapprox(V' * resid, zeros(2); atol = 1e-10)   # 正规方程的几何刻画：Aᵀ(Ax−b) = 0
println("拟合系数 = ", round.(coef; digits = 4), "（真值 [0.5, 1.2]）")

# ═══ 13.4 稀疏矩阵（SparseArrays）：CSC 存储、COO 构造、稀疏求解
n = 10_000
rng = Xoshiro(42)
S = sprand(rng, n, n, 2e-4)                       # 平均每行 2 个非零元
S = S + sparse(1:n, 1:n, fill(3.0, n), n, n)      # 加对角占优项：保证非奇异（教学确定性）
println("n = $(n)：nnz = $(nnz(S))（含对角），稠密度 = ", round(nnz(S) / n^2; digits = 6))
rhs = S * ones(n)
xs_sp = S \ rhs                                   # 稀疏直接法（SuiteSparse/UMFPACK）
@assert norm(xs_sp .- 1) < 1e-9
# COO 三元组构造 → CSC；稠密 ↔ 稀疏互转
S2 = sparse([1, 3], [2, 3], [5.0, 7.0], 3, 3)     # (行, 列, 值) 三元组
@assert S2[1, 2] == 5.0 && nnz(S2) == 2 && issparse(S2)
D2 = Matrix(S2)
@assert D2 == [0 5 0; 0 0 0; 0 0 7] && sparse(D2) == S2
@assert spzeros(2, 2) * D2[1:2, 1:2] == zeros(2, 2)
# 规模直觉：稠密 1 万阶 = 800 MB 且 O(n³)；稀疏只存 3 万非零元、求解走 O(nnz) 量级

# ═══ 13.5 BLAS/LAPACK：矩阵运算的隐形引擎（自带多线程，独立于 Julia 线程池）
N = 600
B = rand(rng, N, N); Cm = rand(rng, N, N)
B * Cm                                            # 预热（首次含分配/缓存）
t = @elapsed B * Cm
println("$(N)×$(N) 矩阵乘 $(round(t * 1000; digits = 1)) ms；BLAS 线程数 = ",
        BLAS.get_num_threads(), "（set_num_threads(k) 可调）")
@assert t > 0
# 经验：中等规模以上 Dense 运算别手写循环——BLAS 十年调优不是白给的（16 章：手写循环赢在无 BLAS 依赖的小内核/融合场景）

println("==== 13 结束 ====")
