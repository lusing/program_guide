using LinearAlgebra, Random
println("==== 42 symmetric_selfadjoint (Julia) ====")
Random.seed!(4242)

# 对称 ⟹ 自伴？有限维永远成立；分歧在无穷维的"定义域"上。
# 数值化身：-d²/dx² 在 [0,1] 的三个自伴扩张（同一微分表达式，
# 不同边条件），谱各不相同——对称算子的自伴扩张是一个"家族"。

# Cayley 变换：自伴 A ↦ U = (A-i)(A+i)⁻¹ 是酉
n = 6
A = randn(n, n); A = (A + A') / 2
U = (A - im * I) / (A + im * I)
println("Cayley 变换酉性偏差 = $(round(opnorm(U' * U - I), digits=12))")
@assert opnorm(U' * U - I) < 1e-12
@assert maximum(abs.(abs.(eigvals(U)) .- 1)) < 1e-12
println("自伴算子的 Cayley 变换是酉算子（特征值全在单位圆上）：✓")

# 三个自伴扩张的谱（有限差分离散）
N = 400
h = 1.0 / N

# Dirichlet-Dirichlet：λₙ = (nπ)²，n ≥ 1（内点网格）
Ldd = Symmetric(Tridiagonal(-ones(N - 1), 2 * ones(N), -ones(N - 1))) ./ h^2
λdd = eigen(Ldd).values
println("DD 前3特征值比 (nπ)²：$(round.(λdd[1:3] ./ ((1:3) .* π).^2, digits=4))")
@assert abs(λdd[1] / π^2 - 1) < 0.01

# Neumann-Neumann：λₙ = (nπ)²，n ≥ 0（含零特征值：常数函数）
d = 2 * ones(N + 1); d[1] = 1.0; d[end] = 1.0
Lnn = Symmetric(Tridiagonal(-ones(N), d, -ones(N))) ./ h^2
λnn = eigen(Lnn).values
println("NN 最小特征值 = $(round(λnn[1], digits=6))（理论 0：常数函数）")
@assert λnn[1] < 0.01

# Dirichlet-Neumann：λₙ = ((n+1/2)π)²
d2 = 2 * ones(N); d2[1] = 1.0
Ldn = Symmetric(Tridiagonal(-ones(N - 1), d2, -ones(N - 1))) ./ h^2
λdn = eigen(Ldn).values
println("DN 首特征值比 (π/2)²：$(round(λdn[1] / (π / 2)^2, digits=4))")
@assert abs(λdn[1] / (π / 2)^2 - 1) < 0.01

println("同一表达式 -d²/dx²，三种边条件 ⟹ 三套谱：自伴扩张不唯一：✓")
println("==== 42 symmetric_selfadjoint END ====")
