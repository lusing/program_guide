# 第 15 章 · Hahn-Banach 定理的数值实验（Conway III.5-6）
# 对应 docs/15-hahn-banach.md。
# 两个实验：子空间上泛函的保范延拓、分离超平面的构造。

using LinearAlgebra
using Random

println("==== 15 hahn-banach (Julia) ====")
Random.seed!(1515)

# --- 实验 1：保范延拓（Conway III.6 的数值化身）-------------------------------
# M = span{e₁,e₂} ⊂ ℝ⁵，在 M 上定义 f(e₁)=3, f(e₂)=4
# 延拓到 ℝ⁵ 使 ‖f‖ = ‖f|_M‖ = 5
n = 5
M = zeros(n, 2)
M[1, 1] = 1.0; M[2, 2] = 1.0
f_on_M = [3.0, 4.0]
norm_on_M = norm(f_on_M)  # = 5
# Hahn-Banach：延拓向量在 M 上的投影等于 f_on_M，正交补分量取零
ext = M * f_on_M  # [3, 4, 0, 0, 0]
println("extension: ‖ext‖ = $(round(norm(ext), digits=6))  ‖f|_M‖ = $(round(norm_on_M, digits=6))")
@assert norm(ext) ≈ norm_on_M
# 验证延拓与限制一致
@assert dot(ext, M[:, 1]) ≈ f_on_M[1]
@assert dot(ext, M[:, 2]) ≈ f_on_M[2]

# --- 实验 2：分离超平面（几何 Hahn-Banach）------------------------------------
# 两个不相交凸集：单位球和球外一点
x0 = [3.0, 0.0]  # 球外点
# 分离超平面：f(x) = <x, x0/‖x0‖> 在球上 < 1，在 x0 处 = ‖x0‖ = 3
sep_direction = x0 / norm(x0)
# 验证分离
ball_points = [randn(2) for _ in 1:1000]
for p in ball_points
    p /= norm(p)  # 归一化到单位球
    @assert dot(p, sep_direction) < dot(x0, sep_direction) - 0.5
end
println("separation: max|<ball,dir>| = 1 < <x0,dir> = $(round(dot(x0, sep_direction), digits=4))")

println("==== 15 hahn-banach END ====")
