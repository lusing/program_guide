# 第 07 章 · 有界算子的数值实验（Conway II.1）
# 对应 docs/07-bounded-operators.md。
# 四个实验：次乘性的随机验证（1.2c）、算子范数 = 最大奇异值（1.1）、
# 乘法算子范数 = ess-sup（1.5 有限维化身）、有限维线性 ⟹ 有界。

using LinearAlgebra
using Random

println("==== 07 bounded-operators (Julia) ====")
Random.seed!(707)

# --- 实验 1：‖BA‖ ≤ ‖B‖·‖A‖ 的随机验证（Conway 1.2 (c)）--------------------
function submult_trial()
    A = randn(6, 5)
    B = randn(4, 6)
    opnorm(B * A) ≤ opnorm(B) * opnorm(A) + 1e-10
end
ok1 = all(submult_trial() for _ in 1:500)
println("submultiplicativity (500 trials): ", ok1 ? "PASS" : "FAIL")
@assert ok1

# --- 实验 2：算子范数 = 最大奇异值（谱定理的前奏）----------------------------
A = randn(8, 5)
println("opnorm(A) = ", round(opnorm(A), digits=8),
    "  σ_max(A) = ", round(maximum(svdvals(A)), digits=8))
@assert abs(opnorm(A) - maximum(svdvals(A))) < 1e-10

# --- 实验 3：乘法算子范数 = max|φ|（Conway 1.5 有限维化身）-------------------
d = [3.0, -1.5, 2.0]
M = diagm(d)
println("opnorm(diag d) = ", round(opnorm(M), digits=8),
    "  max|d| = ", round(maximum(abs.(d)), digits=8))
@assert abs(opnorm(M) - maximum(abs.(d))) < 1e-12
# 对一般矩阵 max|entry| 只是下界（1.4：无穷维矩阵表示的困难预告）
G = randn(3, 3)
@assert opnorm(G) ≥ maximum(abs.(G)) - 1e-12

# --- 实验 4：有限维线性 ⟹ 有界（Conway 1.3/习题 3）--------------------------
# 随机线性映射（随机矩阵）总有有限范数；条件数随维数增长的现象
for n in [5, 20, 50]
    R = randn(n, n)
    @assert isfinite(opnorm(R))
end
println("finite-dim boundedness: PASS (n=5,20,50)")

println("==== 07 bounded-operators END ====")
