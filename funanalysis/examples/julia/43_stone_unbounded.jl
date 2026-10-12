using LinearAlgebra, Random
println("==== 43 stone_unbounded (Julia) ====")
Random.seed!(4343)
I8 = Matrix{Float64}(I, 8, 8)

# Stone 定理：自伴 A 生成强连续酉群 U(t) = e^{itA}
A0 = randn(8, 8); A = (A0 + A0') / 2
F = eigen(Hermitian(A))
U(t) = F.vectors * Diagonal(exp.(im * t .* F.values)) * F.vectors'

# 群律与酉性
println("群律偏差 ‖U(s)U(t)-U(s+t)‖ = $(round(norm(U(0.7) * U(0.3) - U(1.0)), digits=12))")
@assert norm(U(0.7) * U(0.3) - U(1.0)) < 1e-12
println("酉性偏差 ‖U(t)*U(t)-I‖ = $(round(norm(U(0.42)' * U(0.42) - I8), digits=12))")
@assert norm(U(0.42)' * U(0.42) - I8) < 1e-12

# 强连续：‖U(t)x - x‖ ≤ |t|·‖Ax‖（生成元的 Lipschitz 界）
x = randn(8)
Ax = A * x
for t in [0.1, 0.01, 0.001]
    @assert norm(U(t) * x - x) ≤ t * norm(Ax) + 1e-12
end
println("强连续 + 生成元界 ‖U(t)x-x‖ ≤ t‖Ax‖：✓")

# 无界谱定理化身：无界对角算子 N = diag(1², 2², ..., n²)
# 域 Dom(N) = {x : Σ n⁴|xₙ|² < ∞}——谱定理对无界自伴算子照常工作
m = 500
w = collect(1.0:m) .^ 2
xin = w .^ (-1.5)          # n⁻³：Σ n⁴·n⁻⁶ = Σ n⁻² < ∞ ⟹ 在域内
xout = w .^ (-0.75)        # n^{-1.5}：Σ n⁴·n⁻³ = Σ n ⟹ 不在域内
println("Σ n⁴|xₙ|²：域内向量 = $(round(sum(w .^ 2 .* xin .^ 2), sigdigits=4))，域外 = $(round(sum(w .^ 2 .* xout .^ 2), sigdigits=4))")
@assert isfinite(sum(w .^ 2 .* xin .^ 2))
println("‖Nx‖/‖x‖ 随支撑右移无界：无界算子的范数 = ∞（数值上：最大权重 $(round(maximum(w), digits=0))）")

# 无界泛函演算：f(t) = √t 给出 √N = diag(n)，(√N)² = N
sq = Diagonal(sqrt.(w))
@assert norm(sq * sq - Diagonal(w)) < 1e-9
println("无界 f 的函数演算：√N² = N：✓")
println("==== 43 stone_unbounded END ====")
