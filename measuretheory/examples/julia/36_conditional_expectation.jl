println("==== 36 conditional_expectation")
# 第 36 章：分块平均的全家福（有限划分模型）。
# ① 三块划分的分块平均；② 塔性质（两层划分）；
# ③ 取出性质；④ Jensen 三组；⑤ L² 投影几何。

using Random, LinearAlgebra
Random.seed!(36)

# Ω = {1..12}，X 随机赋值，𝓖₁ = 三块划分，𝓖₀ = 两块粗划分
X = randn(12)
G1 = [[1,2,3], [4,5,6], [7,8,9], [10,11,12]]   # 精化 G0
G0 = [[1,2,3,4,5,6], [7,8,9,10,11,12]]

blockavg(x, blocks) = [sum(x[b]) / length(b) for b in blocks]
scatter_avg(x, blocks) = reduce(vcat, [fill(sum(x[b]) / length(b), length(b)) for b in blocks])

EG1 = scatter_avg(X, G1)
EG0 = scatter_avg(X, G0)

# ① 分块平均账
for b in G1
    @assert abs(EG1[b[1]] - sum(X[b]) / length(b)) < 1e-15
end
println("block averages on 3-block partition: OK")

# ② 塔性质：E[E[X|G1]|G0] = E[X|G0]
tower = scatter_avg(EG1, G0)
@assert maximum(abs.(tower .- EG0)) < 1e-15
println("tower property E[E[X|G1]|G0] = E[X|G0]: exact: OK")

# ③ 取出性质：Z 为 G1-块常数时 E[Z*X|G1] = Z*E[X|G1]
Z = [i <= 3 ? 2.0 : i <= 6 ? -1.5 : i <= 9 ? 0.5 : 3.0 for i in 1:12]
lhs = scatter_avg(Z .* X, G1)
@assert maximum(abs.(lhs .- Z .* EG1)) < 1e-12
println("pull-out property E[ZX|G1] = Z*E[X|G1]: exact: OK")

# ④ Jensen 三组（凸函数在块均值 ≤ 均值的凸函数）
for phi in (t -> t^2, abs, t -> exp(t))
    lhs = scatter_avg(phi.(X), G1)
    @assert all(lhs .>= phi.(EG1) .- 1e-12)
end
println("conditional Jensen for x^2, |x|, exp: blockwise nonneg gaps: OK")

# ⑤ L² 投影：残差与块常数空间正交；Gram 解 = 分块平均
resid = X .- EG1
for b in G1
    c = ones(length(b))
    @assert abs(dot(resid[b], c)) < 1e-12      # 残差与每块常向量正交
end
println("projection geometry: residual orthogonal to block-constant space: OK")

# ⑥ 条件版 MCT：截断列 X_n = min(X, n) 的条件期望单调上升（X ≥ 0 版）
Xp = abs.(X)
prev = scatter_avg(min.(Xp, 0.0), G1)
for n in 1:5
    cur = scatter_avg(min.(Xp, Float64(n)), G1)
    @assert all(cur .>= prev .- 1e-15)
    global prev = cur
end
println("conditional MCT for truncated |X|: monotone block averages: OK")

println("END ====")
