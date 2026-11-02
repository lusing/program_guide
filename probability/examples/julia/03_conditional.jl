# -*- coding: utf-8 -*-
println("==== 03 conditional")
# 第 03 章 Julia：条件概率与 Bayes 的模拟对拍。
# ① Monty Hall 十万局（换门 ≈ 2/3）；② 不知情主持人变体
#    （真 1/2——条件结构变则结论变）；③ 医学检验的阳性池
#    分解（真阳/假阳比例显影）。
using Random

Random.seed!(5)

# ① Monty Hall（知情主持人：不开车门、不开你选的门）
function monty_knows(switch; trials = 100_000)
    win = 0
    for _ in 1:trials
        car = rand(1:3)
        pick = rand(1:3)
        # 主持人从"既非车也非 pick"的门中开一扇（知情）
        options = filter(d -> d != car && d != pick, 1:3)
        opened = rand(options)
        if switch
            pick = filter(d -> d != pick && d != opened, 1:3)[1]
        end
        pick == car && (win += 1)
    end
    win / trials
end
stay = monty_knows(false)
swt = monty_knows(true)
@assert abs(stay - 1 / 3) < 0.005
@assert abs(swt - 2 / 3) < 0.005
println("Monty Hall (informed host): stay = ", round(stay, digits=4),
        " switch = ", round(swt, digits=4), " (1/3 vs 2/3): OK")

# ② 不知情主持人：随机开门碰巧是羊（条件在"开到羊"上）
function monty_naive(switch; trials = 200_000)
    win = kept = 0
    for _ in 1:trials
        car = rand(1:3)
        pick = rand(1:3)
        opened = rand(filter(d -> d != pick, 1:3))
        opened == car && continue          # 开到车——重开（条件化）
        kept += 1
        if switch
            pick = filter(d -> d != pick && d != opened, 1:3)[1]
        end
        pick == car && (win += 1)
    end
    win / kept
end
naive_sw = monty_naive(true)
@assert abs(naive_sw - 0.5) < 0.005
println("Monty Hall (naive host opens goat by chance): switch = ",
        round(naive_sw, digits=4), " (1/2 — structure changed): OK")

# ③ 医学检验：病率 1/1000、灵敏度 95%、假阳 5%
function med_screen(n = 1_000_000)
    tp = fp = 0
    for _ in 1:n
        sick = rand() < 0.001
        pos = sick ? rand() < 0.95 : rand() < 0.05
        if pos
            sick ? (tp += 1) : (fp += 1)
        end
    end
    tp / (tp + fp)
end
post = med_screen()
@assert abs(post - 19 / 1018) < 0.002      # ≈ 1.87%
println("medical screening: P(sick|+) = ", round(post, digits=4),
        " (19/1018 = ", round(19 / 1018, digits=4), "): OK")

println("END ====")
