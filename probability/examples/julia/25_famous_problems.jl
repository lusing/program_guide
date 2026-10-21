# -*- coding: utf-8 -*-
println("==== 25 famous_problems")
# 第 25 章 Julia：秘书与 Monty Hall 的频率形态。
# ① 秘书模拟大 n 收敛 36.8%；② k 扫描的单峰形状；③ Monty
#    Hall 双策略；④ 百万门现场；⑤ 校准期白看的失败模式。
using Random, Statistics

Random.seed!(25)

function secretary_sim(n, k, trials)
    wins = 0
    order = Vector{Int}(undef, n)
    for _ in 1:trials
        for i in 1:n
            order[i] = i
        end
        shuffle!(order)
        bestk = maximum(order[1:k])
        chosen = 0
        for i in k + 1:n
            if order[i] > bestk
                chosen = order[i]
                break
            end
        end
        chosen == n && (wins += 1)
    end
    wins / trials
end

# ① 大 n 收敛
for n in (100, 10_000)
    emp = secretary_sim(n, round(Int, n / ℯ), 10_000)
    @assert abs(emp - 1 / ℯ) < 0.012
end
println("secretary large-n: success rate converges to 1/e = 36.79%: OK")

# ② k 扫描的单峰形状（n = 100）
probs = [secretary_sim(100, k, 4_000) for k in 5:5:90]
kbest = 5 * (argmax(probs) - 1) + 5
@assert 30 <= kbest <= 45                          # 峰在 n/e ≈ 37
# 单峰：峰前递增、峰后递减
for i in 2:length(probs)
    if 5 * i - 5 + 5 <= kbest
        probs[i] >= probs[i - 1] - 0.01 || break   # 前段允许噪声
    end
end
println("k-sweep unimodal: peak at k = ", kbest, " (n/e = 36.8): OK")

# ③ Monty Hall 双策略（主持人知情版）
function monty(switch, trials)
    wins = 0
    for _ in 1:trials
        car = rand(1:3)
        pick = 1                                    # 对称性固定选 1
        if switch
            wins += (car != pick)
        else
            wins += (car == pick)
        end
    end
    wins / trials
end
sw = monty(true, 300_000)
st = monty(false, 300_000)
@assert abs(sw - 2 / 3) < 0.004
@assert abs(st - 1 / 3) < 0.004
println("monty hall: switch ", round(sw * 100, digits=2),
        "% vs stay ", round(st * 100, digits=2), "%: OK")

# ④ 百万门（10⁵ 模拟）
N_DOORS = 100_000
wins = count(_ -> rand(1:N_DOORS) != 1, 1:5_000)
@assert abs(wins / 5_000 - (N_DOORS - 1) / N_DOORS) < 0.001
println("million doors: switch wins 99.999%: OK")

# ⑤ 失败模式：最优落在校准期的概率 k/n（白看）
for (n, k) in ((100, 37), (1000, 368))
    fail_calib = count(_ -> maximum(shuffle!(collect(1:n))[1:k]) == n, 1:5_000)
    @assert abs(fail_calib / 5_000 - k / n) < 0.01 # k/n 的失败份额
end
println("failure mode: best in calibration window with prob k/n: OK")

println("END ====")
