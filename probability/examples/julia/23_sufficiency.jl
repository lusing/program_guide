# -*- coding: utf-8 -*-
println("==== 23 sufficiency")
# 第 23 章 Julia：充分统计量与数据简化。
# ① Bernoulli 条件分布的有理数枚举；② 因子分解 g(T,θ)h(x) 的逐点核对；
# ③ 指数族：Poisson/正态的 (T) 与似然比；④ U(0,θ) 的最大值；⑤ Rao–Blackwell 模拟。
using Random, Statistics

Random.seed!(23)

# ---- ① Bernoulli：给定 T=Σx 的条件分布不依赖 p
n = 5
points = [Tuple(digits(i, base=2, pad=n)) for i in 0:2^n-1]
lik(x, p) = p^sum(x) * (1 - p)^(n - sum(x))
function cond(p)
    d = Dict{Tuple{Int,NTuple{n,Int}},Rational{BigInt}}()
    tot = Dict{Int,Rational{BigInt}}()
    for x in points
        tot[sum(x)] = get(tot, sum(x), 0 // 1) + lik(x, p)
    end
    for x in points
        d[(sum(x), x)] = lik(x, p) / tot[sum(x)]
    end
    d
end
c1 = cond(Rational{BigInt}(1, 3))
c2 = cond(Rational{BigInt}(9, 10))
@assert c1 == c2
for ((t, x), v) in c1
    @assert v == 1 // binomial(n, t)
end
println("Bernoulli n=5: P(x | T=t) = 1/C(5,t), identical for p=1/3 and p=9/10: OK")

# ---- ② 因子分解逐点：f(x;p) = g(T(x),p) h(x)，其中 g(t,p)=p^t(1-p)^(n-t)，h≡1
for p in (1 // 7, 1 // 2, 5 // 6), x in points
    g(t) = p^t * (1 - p)^(n - t)
    @assert lik(x, p) == g(sum(x)) * 1
end
# 非因子分解：f(x;p) 对 T'=x1 只在 h 依赖 p 时才能写出——用条件概率验证不充分
p = 1 // 3
num = sum(lik(x, p) for x in points if x[1] == 1 && x[2] == 1)
den = sum(lik(x, p) for x in points if x[1] == 1)
@assert num / den == p                      # P(x2=1 | x1=1) = p 依赖 p → x1 不充分
println("factorization g(T,p)h(x) verified pointwise; x1 alone is not sufficient: OK")

# ---- ③ Poisson / 正态的充分统计量：似然比只经 T 依赖数据
lpois(x, λ) = sum(xi * log(λ) - λ - log(factorial(big(xi))) for xi in x)
xa, xb = [0, 3, 3, 4], [1, 1, 2, 6]        # 和同为 10
for λ in (0.4, 2.5, 9.0)
    d = Float64(lpois(xa, λ) - lpois(xb, λ))
    @assert abs(d - Float64(sum(log(factorial(big(v))) for v in xb) - sum(log(factorial(big(v))) for v in xa))) < 1e-9
end
lnorm(x, μ, s2) = sum(-(xi - μ)^2 / (2s2) - 0.5 * log(2pi * s2) for xi in x)
ya, yb = [1.0, 5.0, 6.0], [2.0, 3.0, 7.0]  # 和与平方和都相等
for μ in (-1.0, 0.3, 4.0), s2 in (0.5, 2.0)
    @assert abs(lnorm(ya, μ, s2) - lnorm(yb, μ, s2)) < 1e-12
end
println("Poisson: ratio depends on x only via sum; Normal: equal (sum, sum of squares) => equal likelihood: OK")

# ---- ④ U(0,θ)：max 的分布与 X_i/max 的 θ-无关
nn, N = 5, 100_000
function run(θ)
    mx = zeros(N); ratios = Float64[]
    for i in 1:N
        x = θ .* rand(nn)
        m = maximum(x)
        mx[i] = m
        push!(ratios, minimum(x) / m)
    end
    mx, ratios
end
m1, r1 = run(1.0)
m5, r5 = run(5.0)
@assert abs(mean(m1 .<= 0.8) - 0.8^nn) < 0.005
@assert abs(mean(m5 .<= 4.0) - 0.8^nn) < 0.005
@assert abs(mean(r1) - mean(r5)) < 0.005 && abs(var(r1) - var(r5)) < 0.003
@assert abs(mean(m5) - 5 * nn / (nn + 1)) < 0.02
println("U(0,theta): max has CDF (m/theta)^n; min/max has the same law for theta=1 and 5: OK")

# ---- ⑤ Rao–Blackwell：Bernoulli 估 p
pp, nb = 0.3, 5
δ1 = Float64[]; δrb = Float64[]
for _ in 1:200_000
    x = rand(nb) .< pp
    push!(δ1, x[1]); push!(δrb, mean(x))
end
@assert abs(mean(δ1) - pp) < 0.004 && abs(mean(δrb) - pp) < 0.004
@assert abs(var(δ1) - pp * (1 - pp)) < 0.004
@assert abs(var(δrb) - pp * (1 - pp) / nb) < 0.002
@assert var(δrb) < var(δ1)
println("Rao-Blackwell: var(X1) = p(1-p) = 0.21 -> var(Xbar) = 0.042: OK")

println("END ====")
