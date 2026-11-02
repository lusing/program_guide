# -*- coding: utf-8 -*-
println("==== 20 conditional_expectation")
# 第 20 章 Julia：条件期望与条件方差的模拟审计。
# ① 有限联合表：E[Y|X]、塔性质、全方差（Rational 精确）
# ② 按 X 分层的模拟：分组均值逼近 E[Y|X=x]，残差与 X 正交
# ③ 连续例 f(x,y)=e^{-y}, 0<x<y：Y|X=x = x+Exp(1)，E[Y|X]=1+X，全方差给 Var Y = 2
# ④ Poisson–二项层次：Var(Y)=λp（稀疏化），分层后 Y 仍为 Poisson(λp)
# ⑤ 线性预测 vs 条件期望：Y=X² 的两种 MSE
# ⑥ 硬币序列：E[S_n|F_k]=S_k+(n−k)/2，Var(S_n|F_k)=(n−k)/4
using Random, Statistics

Random.seed!(20)

# ① 有限联合表（与 Python 单元同一张表，行 x∈{0,1,2}，列 y∈{0,1,3}）
P = Dict((0, 0) => 2 // 24, (0, 1) => 3 // 24, (0, 3) => 1 // 24,
         (1, 0) => 1 // 24, (1, 1) => 4 // 24, (1, 3) => 3 // 24,
         (2, 0) => 4 // 24, (2, 1) => 2 // 24, (2, 3) => 4 // 24)
@assert sum(values(P)) == 1
xs = [0, 1, 2]
ys = [0, 1, 3]
pX = Dict(x => sum(P[(x, y)] for y in ys) for x in xs)
condE(h) = Dict(x => sum(h(x, y) * P[(x, y)] for y in ys) // pX[x] for x in xs)
m = condE((x, y) -> y)
v2 = condE((x, y) -> y^2)
v = Dict(x => v2[x] - m[x]^2 for x in xs)
EY = sum(y * p for ((x, y), p) in P)
VarY = sum(y^2 * p for ((x, y), p) in P) - EY^2
@assert sum(pX[x] * m[x] for x in xs) == EY == 11 // 8                       # 塔性质
Ev = sum(pX[x] * v[x] for x in xs)
Ve = sum(pX[x] * m[x]^2 for x in xs) - EY^2
@assert VarY == Ev + Ve == 95 // 64                                          # 全方差
println("finite table: tower and total variance exact: OK")

# ② 模拟：先抽 X，再按条件分布抽 Y；分组均值 ≈ E[Y|X=x]
N = 600_000
Xs = Vector{Int}(undef, N)
Ysim = Vector{Int}(undef, N)
cdfX = cumsum([Float64(pX[x]) for x in xs])
for i in 1:N
    u = rand()
    x = xs[findfirst(>=(u), cdfX)]
    Xs[i] = x
    w = [Float64(P[(x, y)] / pX[x]) for y in ys]
    u2 = rand()
    Ysim[i] = ys[findfirst(>=(u2), cumsum(w))]
end
for x in xs
    sel = Ysim[Xs .== x]
    @assert abs(mean(sel) - Float64(m[x])) < 0.02
    @assert abs(var(sel; corrected=false) - Float64(v[x])) < 0.04
end
g = [Float64(m[x]) for x in 0:2]
resid = Ysim .- g[Xs .+ 1]
@assert abs(mean(resid)) < 0.01
@assert abs(mean(resid .* Xs)) < 0.01                  # ε ⟂ X
@assert abs(mean(resid .* Xs .^ 2)) < 0.02             # ε ⟂ X²
println("stratified simulation: group means, residual orthogonality: OK")

# ③ f(x,y)=e^{-y}, 0<x<y：X~Exp(1)，Y=X+E'
Xc = -log.(rand(N))
Yc = Xc .+ (-log.(rand(N)))
@assert abs(mean(Yc) - 2) < 0.02 && abs(var(Yc) - 2) < 0.06
for (lo, hi) in ((0.0, 0.5), (0.5, 1.5), (1.5, 3.0))
    sel = (Xc .>= lo) .& (Xc .< hi)
    xm = mean(Xc[sel])
    @assert abs(mean(Yc[sel]) - (1 + xm)) < 0.03          # E[Y|X] = 1+X
    @assert abs(var(Yc[sel] .- Xc[sel]) - 1) < 0.05        # 条件方差 = 1
end
println("continuous example E[Y|X]=1+X, Var(Y|X)=1: OK")

# ④ Poisson(λ) 个体各自以 p 保留
λ, p = 4.0, 0.3
function poisson1(λ)
    L, k, t = exp(-λ), 0, 1.0
    while true
        t *= rand()
        t <= L && return k
        k += 1
    end
end
Nn = [poisson1(λ) for _ in 1:200_000]
Yb = [sum(rand(n) .< p) for n in Nn]
@assert abs(mean(Yb) - λ * p) < 0.02
@assert abs(var(Yb) - λ * p) < 0.04                       # Var = E[Var(Y|N)] + Var(E[Y|N]) = λp(1−p)+λp²
println("Poisson-binomial thinning: Var(Y)=λp: OK")

# ⑤ 线性预测 vs 条件期望
Xq = rand(-1:1, N)
Yq = Xq .^ 2
β = cov(Xq, Yq) / var(Xq)
@assert abs(β) < 0.01                                      # 最优线性斜率 ≈ 0
@assert abs(mean((Yq .- mean(Yq)) .^ 2) - 2 / 9) < 0.01   # 线性预测 MSE ≈ Var(Y)=2/9
@assert mean((Yq .- Xq .^ 2) .^ 2) == 0                    # E[Y|X]=X² MSE = 0
println("linear vs conditional expectation: OK")

# ⑥ 硬币序列
n = 10
Xc2 = rand(Bool, 200_000, n)
Sn = sum(Xc2; dims=2)[:]
for k in (0, 3, 7)
    Sk = k == 0 ? zeros(Int, size(Xc2, 1)) : sum(Xc2[:, 1:k]; dims=2)[:]
    for s in 0:k
        sel = Sk .== s
        sum(sel) < 1000 && continue
        @assert abs(mean(Sn[sel]) - (s + (n - k) / 2)) < 0.05
        @assert abs(var(Sn[sel]) - (n - k) / 4) < 0.12
    end
end
println("coin sequence: conditional mean and variance: OK")
println("END ====")
