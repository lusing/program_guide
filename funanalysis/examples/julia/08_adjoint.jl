# 第 08 章 · 伴随算子的数值实验（Conway II.2）
# 对应 docs/08-adjoint.md。
# 四个实验：伴随 = 共轭转置（2.4 的有限维化身）、定义性质的随机验证、
# C* 恒等式 ‖A*A‖ = ‖A‖²（2.7）、自伴算子的实二次型刻画（2.12）。

using LinearAlgebra
using Random

println("==== 08 adjoint (Julia) ====")
Random.seed!(808)

# --- 实验 1：伴随 = 共轭转置（Conway 2.4 + 2.8 后注）------------------------
A = randn(5, 5) + im * randn(5, 5)
x, y = randn(5) + im * randn(5), randn(5) + im * randn(5)
lhs = dot(A * x, y)          # <Ax, y>
rhs = dot(x, A' * y)         # <x, A†y>
println("|<Ax,y> - <x,A†y>| = ", abs(lhs - rhs))
@assert abs(lhs - rhs) < 1e-10

# --- 实验 2：定义性质的随机验证（500 次）-------------------------------------
adjoint_trial() = begin
    A = randn(4, 4) + im * randn(4, 4)
    x = randn(4) + im * randn(4)
    y = randn(4) + im * randn(4)
    abs(dot(A * x, y) - dot(x, A' * y)) < 1e-10
end
ok2 = all(adjoint_trial() for _ in 1:500)
println("adjoint defining property (500 trials): ", ok2 ? "PASS" : "FAIL")
@assert ok2

# --- 实验 3：C* 恒等式 ‖A*A‖ = ‖A‖² 与 ‖A†‖ = ‖A‖（Conway 2.7）-------------
println("‖A†A‖ = ", round(opnorm(A' * A), digits=8),
    "  ‖A‖² = ", round(opnorm(A)^2, digits=8))
println("‖A†‖ = ", round(opnorm(A'), digits=8),
    "  ‖A‖ = ", round(opnorm(A), digits=8))
@assert abs(opnorm(A' * A) - opnorm(A)^2) < 1e-8
@assert abs(opnorm(A') - opnorm(A)) < 1e-10

# --- 实验 4：自伴 ⟺ 二次型取实值（Conway 2.12，复情形）-----------------------
H = (A + A') / 2             # 自伴部分：H† = H
K = A - A'                   # 反自伴部分
quad_H = [dot(H * z, z) for z in (randn(5) + im * randn(5) for _ in 1:100)]
quad_K = [dot(K * z, z) for z in (randn(5) + im * randn(5) for _ in 1:100)]
println("Hermitian part: max |Im <Hz,z>| = ", round(maximum(abs.(imag.(quad_H))), digits=12))
println("anti-Hermitian: max |Im <Kz,z>| = ", round(maximum(abs.(imag.(quad_K))), digits=6))
@assert maximum(abs.(imag.(quad_H))) < 1e-10    # 自伴：二次型全实
@assert maximum(abs.(imag.(quad_K))) > 0.1      # 反自伴：二次型全纯虚

println("==== 08 adjoint END ====")
