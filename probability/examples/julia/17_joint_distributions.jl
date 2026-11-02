# -*- coding: utf-8 -*-
println("==== 17 joint distributions")
# 第 17 章 Julia：联合表的有理数账 + 固定种子模拟审计。
# ① 3×3 联合表：边际、条件、独立判定（Rational 精确）；
# ② 单位圆盘均匀：拒绝采样的 X 边际直方图 vs (2/π)√(1−x²)；条件 Y|X≈x 的区间长度；
# ③ 三角支撑 f=e^{−y}（0<x<y）：用 Y−X ~ Exp(1) 独立于 X 的构造采样，核对条件无记忆；
# ④ 独立指数：P(X<Y)=λ/(λ+μ) 的模拟；
# ⑤ 多项分布：N1 | N2=k2 的条件均值 (n−k2)p1/(1−p2)。
using Random, Statistics

Random.seed!(17)

# ① 联合表（行 X，列 Y）
T = [1//12 1//12 1//6;
     1//12 1//6  1//12;
     1//6  1//12 1//12]
@assert sum(T) == 1
pX = vec(sum(T, dims=2))
pY = vec(sum(T, dims=1))
@assert pX == fill(1//3, 3) && pY == fill(1//3, 3)
for x in 1:3
    @assert sum(T[x, :] ./ pX[x]) == 1
end
@assert T[1, 3] / pX[1] == 1//2
@assert any(T[x, y] != pX[x] * pY[y] for x in 1:3, y in 1:3)
println("① joint table (Rational): uniform marginals, conditional normalised, dependent: OK")

# ② 单位圆盘均匀：拒绝采样
N = 400_000
xs = Float64[]; ys = Float64[]
while length(xs) < N
    a = 2rand() - 1; b = 2rand() - 1
    if a^2 + b^2 <= 1
        push!(xs, a); push!(ys, b)
    end
end
fX(x) = 2 * sqrt(1 - x^2) / pi
# X ∈ [0.4,0.5) 的概率 ≈ ∫ f_X（用 Simpson 对账）
function simpson(f, a, b, n=2000)
    h = (b - a) / n
    s = f(a) + f(b)
    for i in 1:n-1
        s += f(a + i * h) * (iseven(i) ? 2 : 4)
    end
    s * h / 3
end
emp = count(x -> 0.4 <= x < 0.5, xs) / N
@assert abs(emp - simpson(fX, 0.4, 0.5)) < 0.004
# 条件：X≈0.6 时 |Y| ≤ √(1−0.36)=0.8，且 Y 近似均匀
sel = ys[abs.(xs .- 0.6) .< 0.01]
@assert maximum(abs.(sel)) <= 0.8 + 0.02
@assert abs(mean(sel)) < 0.03
@assert abs(var(sel) - 0.8^2 / 3) < 0.03
# 不独立：联合在 (0.9,0.9) 为 0，而 X>0.8 与 Y>0.8 各自概率正
p1 = count(>(0.8), xs) / N
p2 = count(>(0.8), ys) / N
@assert p1 > 0 && p2 > 0 && count(i -> xs[i] > 0.8 && ys[i] > 0.8, 1:N) == 0
println("② unit disk: X-marginal vs (2/π)√(1−x²), conditional uniform, dependent: OK")

# ③ 三角支撑：X~Exp(1)，Y = X + E，E~Exp(1) 独立 ⇒ 联合密度 e^{−y}（0<x<y）
X = -log.(rand(N)); E = -log.(rand(N)); Y = X .+ E
@assert abs(mean(X) - 1) < 0.02 && abs(mean(Y) - 2) < 0.03     # E[Y]=2
# 条件 Y | X≈1：Y−1 应近似 Exp(1)
selY = Y[abs.(X .- 1) .< 0.02] .- 1
@assert minimum(selY) >= -0.021
@assert abs(mean(selY) - 1) < 0.08
# 条件 X | Y≈2 近似均匀(0,2)：均值 1
selX = X[abs.(Y .- 2) .< 0.05]
@assert abs(mean(selX) - 1) < 0.08
println("③ triangular support: E[Y]=2, Y|X memoryless, X|Y uniform: OK")

# ④ 独立指数：P(X<Y)=λ/(λ+μ)
λ, μ = 1.0, 3.0
Xe = -log.(rand(N)) ./ λ; Ye = -log.(rand(N)) ./ μ
@assert abs(mean(Xe .< Ye) - λ / (λ + μ)) < 0.005
println("④ independent exponentials: P(X<Y)=λ/(λ+μ) ≈ 0.25: OK")

# ⑤ 多项分布：n=4，p=(1/2,1/3,1/6)
n = 4; p = (1/2, 1/3, 1/6)
function draw()
    c = [0, 0, 0]
    for _ in 1:n
        u = rand()
        c[u < p[1] ? 1 : (u < p[1] + p[2] ? 2 : 3)] += 1
    end
    c
end
S = [draw() for _ in 1:200_000]
for k2 in 0:2
    sub = [c[1] for c in S if c[2] == k2]
    expect = (n - k2) * p[1] / (1 - p[2])
    @assert abs(mean(sub) - expect) < 0.02
end
println("⑤ multinomial n=4: E[N1 | N2=k] = (n−k)p1/(1−p2): OK")

println("END ====")
