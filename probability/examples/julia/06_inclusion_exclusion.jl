# -*- coding: utf-8 -*-
println("==== 06 inclusion_exclusion")
# 第 06 章 Julia：错排与占位数的模拟，以及组合恒等式的精确审计。
using Random

Random.seed!(6)

# ① 错排频率：n=10 时接近 1/e。闭式答案由 Python/Prolog/Lean 精确核对。
function derangement_rate(n, trials = 200_000)
    hit = 0
    perm = Vector{Int}(undef, n)
    for _ in 1:trials
        perm .= 1:n
        for i in n:-1:2
            j = rand(1:i)
            perm[i], perm[j] = perm[j], perm[i]
        end
        all(i -> perm[i] != i, 1:n) && (hit += 1)
    end
    hit / trials
end

f10 = derangement_rate(10)
@assert abs(f10 - exp(-1)) < 0.004
println("derangement n=10: frequency ", round(f10; digits=4),
        " near 1/e ", round(exp(-1); digits=4), ": OK")
@assert abs(1 - f10 - (1 - exp(-1))) < 0.004
println("at-least-one fixed point frequency is near 1-1/e: OK")

# ② 4 球进 3 篮：模拟频率与容斥计数 36/81 对拍。
function full_cover_rate(n, k, trials = 200_000)
    hit = 0
    for _ in 1:trials
        seen = falses(n)
        for _ in 1:k
            seen[rand(1:n)] = true
        end
        all(seen) && (hit += 1)
    end
    hit / trials
end
sim_cover = full_cover_rate(3, 4)
exact_cover = sum(j -> (-1)^j * binomial(3, j) * (3 - j)^4, 0:3) // 3^4
@assert exact_cover == 36//81
@assert abs(sim_cover - 36/81) < 0.005
println("4 balls into 3 bins full-cover: simulation matches 36/81: OK")

# ③ 错排递推的精确整数审计。
der = Vector{Rational{BigInt}}([1])
for n in 1:10
    d_n = factorial(n) * sum((-1)^k // factorial(k) for k in 0:n)
    @assert denominator(d_n) == 1
    push!(der, d_n)
end
@assert der[1:8] == [1//1, 0//1, 1//1, 2//1, 9//1, 44//1, 265//1, 1854//1]
println("exact derangement sequence D_0..D_7 = [1,0,1,2,9,44,265,1854]: OK")

# ④ Vandermonde 恒等式。
for (m, n, k) in ((3, 2, 2), (5, 4, 3), (8, 7, 6))
    lhs = sum(binomial(m, j) * binomial(n, k - j) for j in 0:k)
    @assert lhs == binomial(m + n, k)
end
println("Vandermonde sums equal C(m+n,k): OK")

# ⑤ Hockey-stick 恒等式和两阶段选择账。
for (r, n) in ((2, 10), (3, 15), (1, 20))
    @assert sum(binomial(i, r) for i in r:n) == binomial(n + 1, r + 1)
end
@assert sum(k * binomial(4, k) for k in 0:4) == 32
for (n, k, j) in ((8, 5, 3), (10, 6, 2))
    @assert binomial(n, k) * binomial(k, j) ==
            binomial(n, j) * binomial(n - j, k - j)
end
println("hockey-stick, subset-size sum, and order-swap identities: OK")

println("END ====")
