# -*- coding: utf-8 -*-
println("==== 01 signature_problems")
# 第 01 章 Julia：三个招牌问题的模拟账。
# ① 生日问题（23 人过半的模拟确认）；② 投篮问题（轮流先中
#    胜的先手优势模拟 vs 公式 p/(p+q−pq)）；③ 几何级数对拍。
using Random, Statistics

Random.seed!(1)

# ① 生日问题：随机 k 人生日，重复与否的百万次频率
function birthday_hit_rate(k; trials = 1_000_000)
    hit = 0
    for _ in 1:trials
        seen = falses(365)
        coll = false
        for _ in 1:k
            d = rand(1:365)
            if seen[d]
                coll = true
                break
            end
            seen[d] = true
        end
        coll && (hit += 1)
    end
    hit / trials
end

function birthday_exact(k)
    p = 1.0
    for j in 0:(k - 1)
        p *= (365 - j) / 365
    end
    1 - p
end

for k in (22, 23, 30, 50)
    rate = birthday_hit_rate(k; trials = 200_000)
    exact = birthday_exact(k)
    @assert abs(rate - exact) < 0.003       # 频率贴理论（3σ 带）
    println("birthday k=", k, ": sim = ", round(rate, digits=4),
            " vs exact = ", round(exact, digits=4))
end
@assert birthday_exact(23) > 0.5 > birthday_exact(22)   # 23 是过半线
println("birthday: 23 is the smallest >50% (0.5073 vs 0.4757): OK")

# ② 投篮问题：A(p) 先手 vs B(q) 轮流，先中者胜
function hoop_win_rate(p, q; games = 500_000)
    w = 0
    for _ in 1:games
        while true
            rand() < p && (w += 1; break)    # A 投中
            rand() < q && break              # B 投中，A 输
        end
    end
    w / games
end

p, q = 0.5, 0.4
theory = p / (p + q - p * q)                 # = p/(1-(1-p)(1-q))
sim = hoop_win_rate(p, q)
@assert abs(sim - theory) < 0.003
println("hoops: sim = ", round(sim, digits=4), " vs theory ",
        round(theory, digits=4), " (first-mover edge): OK")

# ③ 几何级数对拍：部分和 vs 1/(1−r)
for r in (0.3, 0.6, 0.9)
    partial = sum(r^i for i in 0:99)
    limit = 1 / (1 - r)
    @assert abs(partial - limit) < r^99 / (1 - r) + 1e-12  # 理论余项 r^100/(1-r)
end
println("geometric series: partial sums converge to 1/(1-r): OK")

println("END ====")
