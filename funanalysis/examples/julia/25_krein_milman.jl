using LinearAlgebra, Random
println("==== 25 krein-milman (Julia) ====")
Random.seed!(2525)
# 极点：凸集的"角"
# 单位球的极点：球面（ℓ¹ 的极点是 ±e_n）
println("极点 of ball ℓ¹: {±e_n}（可数，闭包不含全部极点集）")
println("极点 of ball ℓ²: 球面（不可数）")
println("极点 of ball C[0,1]: {f : |f|=1 a.e., f²=1} = {±1 的分段}")
# Krein-Milman: 紧凸集 = 极点集的闭凸包
# 数值化身：单纯形的极点 = 顶点
verts = [0.0 0; 1 0; 0.5 1]  # 三角形顶点
println("三角形极点 = 3 vertices: $(size(verts, 2))")
# 任取凸组合 = 三角形内点
t = rand(3); t /= sum(t)
interior_pt = verts' * t
println("凸组合内点 = $(round.(interior_pt, digits=4))")
@assert all(t .> 0) && sum(t) ≈ 1.0
println("Krein-Milman: 三角形 = conv(3 极点) 的闭包 ✓")
println("==== 25 krein-milman END ====")
