# 第 16 章 · 应用三讲（Conway III.7-9*）
# 对应 docs/16-applications.md。
# 两个实验：Banach 极限（平移不变泛函的有限维逼近）、
# Runge 逼近（多项式逼近全纯函数）。

using LinearAlgebra
using Random

println("==== 16 applications (Julia) ====")
Random.seed!(1616)

# --- 实验 1：Banach 极限的有限维影子（Conway III.7）---------------------------
# Banach 极限 LIM 满足：liminf ≤ LIM ≤ limsup 且平移不变。
# 有限维：取 Cesàro 均值（Banach 极限在收敛序列上的值 = 极限）
x = [(-1.0)^k + 1.0/k for k in 1:1000]  # 振荡 + 缓慢趋势
cesaro(n) = sum(x[1:n]) / n
println("Cesàro mean at n=1000: $(round(cesaro(1000), digits=6))")
println("liminf ≈ -1, limsup ≈ 1, Banach limit should be in [-1, 1]")
@assert -1.1 < cesaro(1000) < 1.1
# 平移不变性的数值验证：前 k 项的丢弃不改变 Cesàro 极限
for k in [10, 50]
    shifted = sum(x[k+1:end]) / (1000 - k)
    println("  shift by $k: $(round(shifted, digits=6))")
    @assert abs(shifted - cesaro(1000)) < 0.1
end

# --- 实验 2：Runge 逼近（Conway III.8 的精神：多项式稠密）------------------
# 在不含 0 的区域上，1/z 可以被多项式一致逼近
# 取圆环 {z : 1/2 ≤ |z| ≤ 2}，在实轴上的采样点
zs = [0.7 + 0.1*im*k for k in -5:5]  # |z| ≈ 0.7-1.1 的点
# 用 Taylor 展开（在 z₀=1 处）：1/z = Σ (-1)^k (z-1)^k
f(z) = 1 / z
pₙ(z, n) = sum(((-1)^k) * (z - 1)^k for k in 0:n)
for n in [5, 10, 20]
    err = maximum(abs.(pₙ.(zs, n) .- f.(zs)))
    println("Runge Taylor n=$n: max|p-f| on |z|≈1: $(round(err, digits=6))")
    n >= 10 && @assert err < 0.1
end

println("==== 16 applications END ====")
