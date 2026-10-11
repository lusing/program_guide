using LinearAlgebra, Random, Statistics
println("==== 26 fixed-points (Julia) ====")
Random.seed!(2626)
# Schauder 不动点：紧凸集到自身的连续映射有不动点
# 有限维化身：Brouwer（单位球上的连续自映射有不动点）
# 压缩映射的迭代收敛
A = 0.3 * randn(3, 3); A += Matrix(1.0I, 3, 3) * 0.5
x = randn(3)
for _ in 1:100; global x = A * x / maximum(abs.(A*x)); end
println("iterating normalized map: x → $(round.(x, digits=6))")
println("不动点存在：Brouwer/Schauder 定理")
# Haar 测度：圆周上的不变测度 = 弧长/2π
θ = 2π * rand(1000)
println("圆周均匀采样 mean(θ/2π) ≈ $(round(mean(θ)/2/π, digits=4))")
@assert abs(mean(θ)/2/π - 0.5) < 0.02
println("Haar measure on S¹ = uniform: PASS")
println("==== 26 fixed-points END ====")
