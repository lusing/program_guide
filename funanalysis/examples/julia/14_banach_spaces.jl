# 第 14 章 · Banach 空间的数值实验（Conway III.1-4）
# 对应 docs/14-banach-spaces.md。
# 三个实验：完备化（C[a,b] 中 Cauchy 列收敛）、商空间范数、
# 有限维 vs 无穷维（Riesz 引理的数值化身）。

using LinearAlgebra
using Random

println("==== 14 banach-spaces (Julia) ====")
Random.seed!(1414)

# --- 实验 1：C[0,1] 的完备性（Cauchy 列收敛）---------------------------------
# Weierstrass 逼近：多项式 Cauchy 列收敛到连续函数
f = x -> exp(x)
# Bernstein 多项式逼近（在每个 n 级数上是多项式，n→∞ 时一致收敛）
n = 200
xs = range(0, 1; length = n)
# 验证：多项式序列（截断 Taylor 级数）在 C[0,1] 中 Cauchy 且收敛
for k in [5, 10, 15]
    pₖ(x) = sum(x^j / factorial(big(j)) for j in 0:k)
    err = maximum(abs.(Float64.(pₖ.(xs)) .- f.(xs)))
    println("Taylor degree $k: sup error = $(round(err, digits=6))")
    @assert err < 0.01  # Taylor 收敛
end

# --- 实验 2：商空间范数 ‖x+M‖ = inf{‖x+m‖ : m ∈ M}----------------------------
# M = span{e₁} ⊂ ℝ³，商空间 ℝ³/M 的范数
M_basis = [1.0, 0.0, 0.0]
x = [1.0, 2.0, 3.0]
# ‖x+M‖ = inf{‖x+t·e₁‖ : t ∈ ℝ} = sqrt(2²+3²) = sqrt(13)
proj_coeff = dot(x, M_basis)
x_parallel = proj_coeff * M_basis
x_perp = x - x_parallel
quotient_norm = norm(x_perp)
println("quotient ‖x+M‖ = $(round(quotient_norm, digits=6))  √13 = $(round(sqrt(13), digits=6))")
@assert abs(quotient_norm - sqrt(13)) < 1e-12

# --- 实验 3：有限维单位球紧 vs 无穷维不紧（Riesz 引理）------------------------
# 有限维：单位球上的任意序列有收敛子列（Heine-Borel）
n = 50
A = randn(n, n)
σ = svdvals(A)
# 无穷维的化身：随机高维单位球上的两个"随机"点几乎正交
d = 1000
v1 = randn(d); v1 /= norm(v1)
v2 = randn(d); v2 /= norm(v2)
cos_angle = abs(dot(v1, v2))
println("random unit vectors in ℝ^$d: |cos| = $(round(cos_angle, digits=6))")
@assert cos_angle < 0.1  # 高维随机向量近似正交
# 这意味着无穷维空间中可以构造无穷多两两近正交的单位向量
# ⟹ 单位球不是完全有界的 ⟹ 不紧（Riesz 引理的精神）

println("==== 14 banach-spaces END ====")
