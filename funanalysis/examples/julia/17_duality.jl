# 第 17 章 · 对偶理论的数值实验（Conway III.10-11 + B/C）
using LinearAlgebra, Random
println("==== 17 duality (Julia) ====")
Random.seed!(1717)
# 对偶范数验证：‖x‖ = sup{|<x,f>| : ‖f‖=1}（Hahn-Banach 推论 2）
n = 5; x = randn(n)
dual_norm = norm(x)  # 欧氏空间自对偶
println("‖x‖ = $(round(dual_norm, digits=6))")
# 随机单位对偶向量上取 sup
fs = begin; vs = [randn(n) for _ in 1:1000]; [v / norm(v) for v in vs]; end
sup_val = maximum(abs.(dot.(Ref(x), fs)))
println("sup|<x,f>| over 1000 random unit f = $(round(sup_val, digits=6))")
@assert sup_val ≤ dual_norm + 1e-12
# L^p 对偶：(L^p)* = L^q
p, q = 1.5, 3.0  # 1/p + 1/q = 1
f = randn(100); g = randn(100)
# Hölder 验证：|<f,g>| ≤ ‖f‖_p · ‖g‖_q
lhs = abs(dot(f, g))
rhs = norm(f, p) * norm(g, q)
println("Hölder: |<f,g>| = $(round(lhs, digits=4)) ≤ ‖f‖_p·‖g‖_q = $(round(rhs, digits=4))")
@assert lhs ≤ rhs + 1e-10
println("==== 17 duality END ====")
