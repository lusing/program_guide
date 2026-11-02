# -*- coding: utf-8 -*-
println("==== 18 multivariate transformations")
# 第 18 章 Julia：Jacobian 的数值差分审计 + 固定种子模拟。
# ① 中心差分 Jacobian 行列式 vs 解析式（极坐标 r、球坐标 r² sinφ、积/商）；
# ② Box–Muller：U₁,U₂ → (X,Y)，均值/方差/相关/径向尾 P(R²>t)=e^{−t/2}；
# ③ 极坐标：(X,Y) 标准正态 ⇒ R²~Exp(1/2)，Θ 均匀，且 R、Θ 近似独立；
# ④ 指数商 Z=X/Y 的 CDF λz/(μ+λz) 与模拟；λ 同比缩放不改变分布；
# ⑤ Gamma–Beta：U=X+Y 与 V=X/(X+Y) 近似不相关，E[V]=a/(a+b)；
# ⑥ 次序统计量：n=5 个 U(0,1) 的第 k 个均值 k/(n+1)；(min,max) 联合：E[max−min]=(n−1)/(n+1)。
using Random, Statistics, LinearAlgebra

Random.seed!(18)

# ① 数值 Jacobian
function numjac(f, p; h=1e-6)
    k = length(p); m = length(f(p))
    J = zeros(m, k)
    for j in 1:k
        e = zeros(k); e[j] = h
        J[:, j] = (f(p .+ e) .- f(p .- e)) ./ (2h)
    end
    J
end
polar(p) = [p[1] * cos(p[2]), p[1] * sin(p[2])]
@assert abs(det(numjac(polar, [1.7, 0.6])) - 1.7) < 1e-6
sph(p) = [p[1] * sin(p[2]) * cos(p[3]), p[1] * sin(p[2]) * sin(p[3]), p[1] * cos(p[2])]
@assert abs(det(numjac(sph, [1.3, 0.8, 1.1])) - 1.3^2 * sin(0.8)) < 1e-5
prodinv(p) = [p[2], p[1] / p[2]]           # (u,v) ↦ (x,y)=(v, u/v)
@assert abs(abs(det(numjac(prodinv, [0.7, 1.9]))) - 1 / 1.9) < 1e-7
quoinv(p) = [p[1] * p[2], p[2]]            # (u,v) ↦ (uv, v)
@assert abs(det(numjac(quoinv, [0.7, 1.9])) - 1.9) < 1e-7
println("① numerical Jacobians match r, r² sinφ, 1/v, v: OK")

# ② Box–Muller
N = 400_000
U1 = rand(N); U2 = rand(N)
R = sqrt.(-2 .* log.(U1)); Θ = 2π .* U2
X = R .* cos.(Θ); Y = R .* sin.(Θ)
@assert abs(mean(X)) < 0.01 && abs(mean(Y)) < 0.01
@assert abs(var(X) - 1) < 0.02 && abs(var(Y) - 1) < 0.02
@assert abs(cor(X, Y)) < 0.01
# 偶数阶矩：E[X⁴]=3
@assert abs(mean(X .^ 4) - 3) < 0.1
# 径向尾：P(X²+Y² > t) = e^{−t/2}
for t in (1.0, 2.0, 4.0)
    @assert abs(mean(X .^ 2 .+ Y .^ 2 .> t) - exp(-t / 2)) < 0.005
end
println("② Box–Muller: moments, correlation, radial tail e^{−t/2}: OK")

# ③ 极坐标反向：由 (X,Y) 重新算 R²、Θ
R2 = X .^ 2 .+ Y .^ 2
@assert abs(mean(R2) - 2) < 0.03                      # Exp(速率 1/2)，均值 2
Θ2 = mod.(atan.(Y, X), 2π)
@assert abs(mean(Θ2) - π) < 0.02
@assert abs(cor(R2, Θ2)) < 0.01
println("③ polar decomposition: R²~Exp(mean 2), Θ uniform, uncorrelated: OK")

# ④ 指数商
function expquot(λ, μ, n)
    -log.(rand(n)) ./ λ ./ (-log.(rand(n)) ./ μ)
end
for (λ, μ) in ((1.0, 1.0), (2.0, 3.0))
    Z = expquot(λ, μ, N)
    for z in (0.5, 1.0, 3.0)
        @assert abs(mean(Z .<= z) - λ * z / (μ + λ * z)) < 0.005
    end
end
Z1 = expquot(1.0, 1.0, N); Z5 = expquot(5.0, 5.0, N)
for z in (0.5, 1.0, 3.0)
    @assert abs(mean(Z1 .<= z) - mean(Z5 .<= z)) < 0.007    # λ=μ 时与尺度无关
end
println("④ exponential quotient: F(z)=λz/(μ+λz), scale-free when λ=μ: OK")

# ⑤ Gamma–Beta（a=2, b=3：用整数形状 = 指数和）
gam(k, n) = [sum(-log.(rand(k))) for _ in 1:n]
Ga = gam(2, 100_000); Gb = gam(3, 100_000)
S = Ga .+ Gb; V = Ga ./ S
@assert abs(mean(V) - 2 / 5) < 0.005
@assert abs(cor(S, V)) < 0.01
@assert abs(var(V) - (2 * 3) / (5^2 * 6)) < 0.003          # Beta(2,3) 方差 ab/((a+b)²(a+b+1))
println("⑤ Gamma–Beta: E[V]=2/5, Var[V]=1/25, cor(S,V)≈0: OK")

# ⑥ 次序统计量
n = 5; M = 200_000
A = rand(M, n)
sorted = sort(A, dims=2)
for k in 1:n
    @assert abs(mean(sorted[:, k]) - k / (n + 1)) < 0.004
end
@assert abs(mean(sorted[:, n] .- sorted[:, 1]) - (n - 1) / (n + 1)) < 0.004
println("⑥ order statistics: E[U₍ₖ₎]=k/(n+1), E[range]=(n−1)/(n+1): OK")

println("END ====")
