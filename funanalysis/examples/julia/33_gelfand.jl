using LinearAlgebra, Random
println("==== 33 gelfand (Julia) ====")
Random.seed!(3333)
# Gelfand 变换：交换 Banach 代数 → C(Δ)（极大理想空间上的连续函数）
# 有限维化身：对角矩阵的特征值 = Gelfand 变换的值
D = Diagonal([1.0, 2.0, 3.0])
Δ_values = diag(D)  # "极大理想空间"上的值
println("diagonal entries (= Gelfand transform values): $Δ_values")
println("max |f| = $(maximum(abs.(Δ_values))) = spectral radius")
@assert maximum(abs.(Δ_values)) == 3.0
println("==== 33 gelfand END ====")
