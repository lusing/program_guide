# -*- coding: utf-8 -*-
println("==== 06 inclusion_exclusion")
# 第 06 章 Julia：容斥的模拟渐近。
# ① n=10 随机排列的零固定点频率 vs 1/e；② 篮子问题
#    （n=5 篮 k=20 球）全非空的模拟 vs 容斥公式；③ 至少
#    一固定点 → 1 − 1/e。
using Random

Random.seed!(6)

# ① 零固定点（错排）频率：n = 10 的随机排列
function zero_fixed(n, trials = 200_000)
    hit = 0
    perm = Vector{Int}(undef, n)
    for _ in 1:trials
        for i in 1:n
            perm[i] = i
        end
        for i in n:-1:2                    # Fisher-Yates
            j = rand(1:i)
            perm[i], perm[j] = perm[j], perm[i]
        end
        all(i -> perm[i] != i, 1:n) && (hit += 1)
    end
    hit / trials
end
f10 = zero_fixed(10)
@assert abs(f10 - exp(-1)) < 0.004
println("derangement n=10: freq = ", round(f10, digits=4),
        " vs 1/e = ", round(exp(-1), digits=4), ": OK")

# ③ 至少一固定点（1 − 1/e 的显影）
one_plus = 1 - f10
@assert abs(one_plus - (1 - exp(-1))) < 0.004
println("at-least-one fixed point: ", round(one_plus, digits=4),
        " -> 1 - 1/e = ", round(1 - exp(-1), digits=4), ": OK")

# ② 篮子问题：k 球独立进 n 篮，全非空的概率（容斥公式 vs 模拟）
function balls_all_covered(n, k, trials = 200_000)
    hit = 0
    for _ in 1:trials
        seen = falses(n)
        ok = true
        for _ in 1:k
            b = rand(1:n)
            seen[b] = true
            count(seen) == n && break
        end
        count(seen) == n && (hit += 1)
    end
    hit / trials
end
# 容斥公式：Σ_j (-1)^j C(n,j) ((n-j)/n)^k
ie_prob(n, k) = sum(j -> (-1)^j * binomial(n, j) * ((n - j) / n)^k, 0:n)
sim = balls_all_covered(5, 20)
th = ie_prob(5, 20)
@assert abs(sim - th) < 0.004
println("balls-to-bins n=5,k=20: sim = ", round(sim, digits=4),
        " vs inclusion-exclusion = ", round(th, digits=4), ": OK")

println("END ====")
