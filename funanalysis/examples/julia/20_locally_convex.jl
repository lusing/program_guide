# 第 20 章 · 局部凸空间的数值实验（Conway IV.1-2）
using LinearAlgebra, Random
println("==== 20 locally-convex (Julia) ====")
Random.seed!(2020)
# 半范数族生成拓扑：p_i(x) = |x_i| 在 ℝ³ 上
# 局部基 = {x : p_i(x) < ε ∀i} = 立方体
n = 3
ε = 0.1
pts_in_cube = sum(count(abs(p[i]) < ε for i in 1:n) == n for p in eachcol(randn(n, 1000) * 0.1))
println("points in cube of radius $ε: $(pts_in_cube)/1000")
# 半范数是范数 iff 分离点：p_i(x)=0 ∀i ⟹ x=0
# 单个半范数 p(x) = |x₁| 不分离：p(0,1,0)=0 但 (0,1,0)≠0
p₁(x) = abs(x[1])
println("p₁(0,1,0) = $(p₁([0.0,1.0,0.0])) ≠ 0 needed for separation")
@assert p₁([0.0,1.0,0.0]) == 0.0  # 不分离！需要族 {p₁,p₂,p₃}
p₂(x) = abs(x[2]); p₃(x) = abs(x[3])
separates(x) = p₁(x) == 0 && p₂(x) == 0 && p₃(x) == 0
@assert separates([0.0, 0.0, 0.0]) && !separates([0.0, 1.0, 0.0])
println("family separates: yes (need full family)")
println("==== 20 locally-convex END ====")
