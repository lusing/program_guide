# 第 13 章 · 紧正规算子谱定理与泛函演算的数值实验（Conway II.7-8）
# 对应 docs/13-compact-normal.md。
# 四个实验：正规性检验（7.6）、泛函演算（7.11）、
# 正算子与平方根（7.16）、酉等价与重数（8.2）。

using LinearAlgebra
using Random

println("==== 13 compact-normal (Julia) ====")
Random.seed!(1313)

# --- 实验 1：紧正规算子的对角化（Conway 7.6）--------------------------------
# 构造正规紧算子：T = U D U* 其中 D 对角（αₙ → 0）
n = 50
α = [(-1)^k / k^1.5 + im * (-1)^(k+1) / k^2.2 for k in 1:n]  # 复特征值趋于零
Q = qr(randn(n, n) + im * randn(n, n)).Q  # 随机酉矩阵
D = Diagonal(α)
T = Q * D * Q'
# 验证正规性
normTT = norm(T * T' - T' * T)
println("normality: ‖TT* - T*T‖ = $(normTT)")
@assert normTT < 1e-10

# --- 实验 2：泛函演算（Conway 7.11）-------------------------------------------
# Φ(T) = Q Φ(D) Q*：对特征值逐点应用 Φ
Φ = z -> z^2 + 1
ΦT = Q * Diagonal(Φ.(α)) * Q'
direct = T * T + I
println("functional calculus: ‖Φ(T) - (T² + I)‖ = $(round(norm(ΦT - direct), digits=10))")
@assert norm(ΦT - direct) < 1e-8

# --- 实验 3：正算子与平方根（Conway 7.16）--------------------------------------
# 构造正算子 T = A*A（自动正）
A = randn(30, 30) + im * randn(30, 30)
T_pos = A' * A
# 特征值全非负
evals_pos = eigen(Hermitian(T_pos)).values
@assert all(≥(0), evals_pos)  # 全部非负
# 平方根：S = √T 满足 S² = T
S = sqrt(Hermitian(T_pos))
@assert norm(S * S - T_pos) / norm(T_pos) < 1e-10
println("positive: min eig = $(round(minimum(evals_pos), digits=8)),  √T² = T: PASS")

# --- 实验 4：酉等价与重数（Conway 8.2）------------------------------------------
# 两个酉等价的紧正规算子有相同的特征值（含重数）
n2 = 20
β = [1.0/k for k in 1:n2]  # 实特征值（自伴）
V = qr(randn(n2, n2) + im * randn(n2, n2)).Q
T1 = V * Diagonal(β) * V'     # T1 = V D V*
W = qr(randn(n2, n2) + im * randn(n2, n2)).Q
T2 = W * Diagonal(β) * W'     # T2 = W D W*（不同的基）
# T1 与 T2 酉等价（通过 W' V）
U = W * V'
println("unitary equivalence: ‖T2 - U T1 U*‖ = $(round(norm(T2 - U * T1 * U'), digits=10))")
@assert norm(T2 - U * T1 * U') < 1e-10

println("==== 13 compact-normal END ====")
