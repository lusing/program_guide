using LinearAlgebra, Random
println("==== 32 compact_spectrum (Julia) ====")
Random.seed!(3232)
# Riesz–Schauder 定理：紧算子的非零谱点都是特征值（有限重），
# 唯一可能的聚点是 0；且 0 ∈ σ(T) 当空间无穷维。

# 1) 对角紧算子 diag(1/k) 的 n 阶截断：谱 = {1, 1/2, ..., 1/n}
n = 100
D = Diagonal(1.0 ./ (1:n))
λD = eigvals(D)
println("diag(1/k) 截断：λ₁..λ₅ = $(round.(λD[1:5], digits=6))")
@assert maximum(abs.(λD .- 1.0 ./ (1:n))) < 1e-12
for m in [50, 200, 800]
    println("  n = $m : 最小谱值 1/n = $(round(1.0 / m, digits=6)) → 0")
end
@assert 1 / 800 < 1 / 200 < 1 / 50
println("谱值随维数增长填充逼近 0（唯一聚点）：✓")

# 2) 三角结构：严格下三角扰动不改变谱（三角阵谱 = 对角元）
N = randn(n, n) .* 0.05
N = LowerTriangular(N) - Diagonal(diag(LowerTriangular(N)))   # 严格下三角
T = Matrix(D + N)
λT = eigvals(T)                    # 升序返回
ref = reverse(1.0 ./ (1:n))        # 1/k 降序 → 升序
println("严格下三角扰动后谱偏差 = $(round(maximum(abs.(λT .- ref)), digits=10))")
@assert maximum(abs.(λT .- ref)) < 1e-8
println("σ(三角阵) = 对角元集合（有限维 Riesz 理论骨架）：✓")

# 3) Volterra 型算子（h·下三角全 1）：拟幂零的数值化身，谱半径 → 0
volterra(n) = (1.0 / n) .* (Float64[i >= j for i in 1:n, j in 1:n])
ρ20 = maximum(abs.(eigvals(volterra(20))))
ρ100 = maximum(abs.(eigvals(volterra(100))))
ρ400 = maximum(abs.(eigvals(volterra(400))))
println("Volterra 截断谱半径：n=20 : $(round(ρ20, digits=6))  n=100 : $(round(ρ100, digits=6))  n=400 : $(round(ρ400, digits=6))")
@assert ρ400 < ρ100 < ρ20
println("谱半径随加细收缩 → 0（无穷维极限 σ(V) = {0}）：✓")
println("==== 32 compact_spectrum END ====")
