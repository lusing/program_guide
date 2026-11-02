# -*- coding: utf-8 -*-
println("==== 26 lln")
# 第 26 章 Julia：大数定律（Chebyshev 精确界、四阶矩、SLLN 路径、Monte Carlo、Cauchy、Glivenko–Cantelli）。
using Random, Statistics, LinearAlgebra

# ① Chebyshev vs 精确二项尾
function exact_tail(n, eps)
    tot = big(0) // 1
    for k in 0:n
        abs(k // n - 1 // 2) >= eps && (tot += binomial(big(n), k) // big(2)^n)
    end
    return tot
end
eps = 1 // 10
prev = 1 // 1
for n in (10, 50, 100, 400)
    t = exact_tail(n, eps)
    @assert t <= min(1 // 1, (1 // 4) / (n * eps^2))
    @assert t < prev
    global prev = t
end
println("WLLN: exact binomial tails <= Chebyshev, decreasing in n: OK")

# ② 四阶矩：X=±1，E[S_n^4]=3n²−2n ≤ 3n²（枚举）
for n in 1:12
    tot = 0 // 1
    for mask in 0:(2^n - 1)
        s = 2 * count_ones(mask) - n
        tot += s^4 // 2^n
    end
    @assert tot == 3n^2 - 2n
end
@assert sum(3 // BigInt(n)^2 for n in 1:2000) < 6
println("4th-moment bound E[S_n^4] = 3n^2 - 2n (enumerated): OK")

# ③ SLLN 路径
Random.seed!(2026)
paths = -log.(rand(8, 100000))                        # Exp(1)
means = cumsum(paths; dims = 2) ./ reshape(1:100000, 1, :)
@assert all(abs.(means[:, end] .- 1) .< 0.02)
dev = abs.(means .- 1)
suptail = reverse(accumulate(max, reverse(dev; dims = 2); dims = 2); dims = 2)
@assert maximum(suptail[:, 1000]) > maximum(suptail[:, 50000])
println("SLLN paths: all within 0.02 of 1 at n=1e5; tail sup shrinks: OK")

# ④ Monte Carlo π
p = π / 4
σ = 4 * sqrt(p * (1 - p))
rmse = Dict{Int,Float64}()
for n in (100, 10000, 1000000)
    reps = n < 1000000 ? 200 : 40
    est = [4 * mean(rand(n) .^ 2 .+ rand(n) .^ 2 .<= 1) for _ in 1:reps]
    rmse[n] = sqrt(mean((est .- π) .^ 2))
    @assert 0.6 * σ / sqrt(n) < rmse[n] < 1.5 * σ / sqrt(n)
end
@assert rmse[100] / rmse[10000] > 5 && rmse[10000] / rmse[1000000] > 5
println("Monte Carlo pi: RMSE ~ sigma/sqrt(n): OK")

# ⑤ Cauchy：X̄_n 仍为 Cauchy
c = tan.(π .* (rand(2000, 1000) .- 0.5))
p10 = mean(abs.(mean(c[:, 1:10]; dims = 2)) .> 1)
p1000 = mean(abs.(mean(c; dims = 2)) .> 1)
@assert abs(p10 - 0.5) < 0.05 && abs(p1000 - 0.5) < 0.05
println("Cauchy: P(|mean|>1) ~ 1/2 for n=10 and n=1000: OK")

# ⑥ Glivenko–Cantelli
dn = Dict{Int,Float64}()
for n in (50, 500, 5000, 50000)
    ds = Float64[]
    for _ in 1:40
        x = sort(rand(n)); i = 1:n
        push!(ds, max(maximum(i ./ n .- x), maximum(x .- (i .- 1) ./ n)))
    end
    dn[n] = mean(ds)
    @assert dn[n] * sqrt(n) < 2.0
end
@assert dn[50] > dn[500] > dn[5000] > dn[50000]
println("Glivenko-Cantelli: E D_n shrinks, sqrt(n) D_n bounded: OK")

# ⑦ Kolmogorov 不等式（简单对称游走精确枚举）
for (n, lam) in ((10, 5), (12, 6), (14, 5))
    cnt = 0; endp = 0
    for mask in 0:(2^n - 1)
        s = 0; mx = 0
        for b in 0:(n - 1)
            s += (mask >> b) & 1 == 1 ? 1 : -1
            mx = max(mx, abs(s))
        end
        cnt += mx >= lam
        endp += abs(s) >= lam
    end
    @assert cnt // 2^n <= n // lam^2
    @assert cnt >= endp
end
println("Kolmogorov inequality (exact enumeration): OK")

# ⑧ 截断：Σ P(|X|>i) ≤ E|X|（Pareto α=1.5，E X=3）
@assert sum(i^(-1.5) for i in 1:2_000_000) <= 3.0
println("truncation: sum_i P(|X|>i) <= E|X|: OK")
println("END ====")
