# 第 23 章 · 弱拓扑与 Alaoglu 的数值实验（Conway V.1-5）
using LinearAlgebra, Random
println("==== 23 weak-topology (Julia) ====")
Random.seed!(2323)
# 弱收敛 vs 强收敛：e_n → 0 弱但不强
n = 100
e_n = zeros(n); e_n[n] = 1.0
println("‖e_n‖ = $(norm(e_n)) (strong: not → 0)")
println("<e_n, f> = $(dot(e_n, randn(n)/norm(randn(n)))) (weak: depends on f[n])")
# 有限维中弱=强；差异在无穷维
# Alaoglu：对偶单位球弱*紧
# 有限维化身：单位球面紧（Heine-Borel）
pts = [randn(5) for _ in 1:1000]
unit_pts = [p/norm(p) for p in pts]
# 任意序列有收敛子列（有限维紧性）
subseq_indices = sortperm(rand(1000))[1:50]  # 模拟子列选取
println("unit sphere in R^5: compact (finite dim), weak=strong")
# 弱*收敛的数值演示：ℓ¹ 中的单位向量 e_n → 0 弱*
println("e_n → 0 weak* in ℓ¹: <e_n, x> = x[n] → 0 for x ∈ c₀")
x = [1.0/k for k in 1:100]
println("x[n] at n=100: $(x[100]) → 0")
@assert abs(x[100]) < 0.02
println("==== 23 weak-topology END ====")
