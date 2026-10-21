# -*- coding: utf-8 -*-
println("==== 24 markov_least_squares")
# 第 24 章 Julia：差分方程与最小二乘的频率形态。
# ① 5 连黑模拟 vs 递推；② 加倍赌注法的破产现场；③ 迁移矩阵
#    收敛轨迹；④ 最小二乘的重复实验（a 稳 b 漂的分布现场）；
# ⑤ log 变换的幂律拟合。
using Random, Statistics

Random.seed!(24)

# ① 5 连黑：模拟 vs 递推（81.01%）
function run5_prob(n, trials)
    hits = 0
    for _ in 1:trials
        consec = 0
        for _ in 1:n
            if rand() < 0.5
                consec += 1
                consec >= 5 && break
            else
                consec = 0
            end
        end
        consec >= 5 && (hits += 1)
    end
    hits / trials
end
emp = run5_prob(100, 100_000)
@assert abs(emp - 0.8101) < 0.005
println("5-black in 100 spins: simulated ", round(emp * 100, digits=2),
        "% vs recurrence 81.01%: OK")

# ② 加倍赌注法破产现场：上限 $30、初始 $40
function martingale_bust(bankroll, cap, spins)
    money = bankroll
    for _ in 1:spins
        bet = 1.0
        while true
            if bet > cap || bet > money        # 上限或资金不足：系统崩溃
                return true
            end
            money -= bet
            if rand() < 0.5
                money += 2 * bet               # 赢：净 +bet
                break
            end
            bet *= 2
        end
        money >= bankroll * 2 && return false   # 翻倍离场（未破产）
    end
    return false
end
busts = count(_ -> martingale_bust(40.0, 30.0, 100), 1:20_000)
@assert busts / 20_000 > 0.6                    # 百局内破产过半（81% 的亲戚）
println("martingale with \$30 cap: bust rate ", round(busts / 200, digits=1),
        "% in 100 sessions: OK")

# ③ 迁移矩阵收敛轨迹（10 年 → 平稳）
M = [0.8 0.3; 0.2 0.7]
p = [0.7, 0.3]
for yr in 1:10
    global p = M * p
end
@assert abs(p[1] - 0.6001) < 0.001
for yr in 11:90
    global p = M * p
end
@assert abs(p[1] - 0.6) < 1e-9
println("migration: 10yr at 0.6001, 100yr at 0.6 = stationary: OK")

# ④ 最小二乘重复实验：a 稳 b 漂（100 次实验的分布）
as = Float64[]
bs = Float64[]
for _ in 1:100
    xs = [5 + 0.2 * n for n in 1:100]
    ys = [5 * x + randn() * 4 for x in xs]
    N = 100
    sx, sy = sum(xs), sum(ys)
    sxx = sum(x -> x ^ 2, xs)
    sxy = sum(xy -> xy[1] * xy[2], zip(xs, ys))
    det = N * sxx - sx ^ 2
    push!(as, (N * sxy - sx * sy) / det)
    push!(bs, (sxx * sy - sx * sxy) / det)
end
@assert abs(mean(as) - 5) < 0.1                 # 斜率集中
@assert std(as) < 0.15
@assert std(bs) > 0.5                           # 截距漂移（原书警示的频率版）
@assert std(bs) / abs(mean(bs) - 0) > 0.5
println("least squares repeats: a stable (sd ", round(std(as), digits=3),
        "), b drifts (sd ", round(std(bs), digits=2), "): OK")

# ⑤ log 变换幂律拟合：y = 3x^2 加噪 → log y = 2 log x + log 3
xs5 = [1.0 + 0.2 * n for n in 1:40]
ys5 = [3 * x ^ 2 * exp(0.05 * randn()) for x in xs5]
lx = log.(xs5)
ly = log.(ys5)
N5 = 40
sx5, sy5 = sum(lx), sum(ly)
sxx5 = sum(x -> x ^ 2, lx)
sxy5 = sum(xy -> xy[1] * xy[2], zip(lx, ly))
det5 = N5 * sxx5 - sx5 ^ 2
slope = (N5 * sxy5 - sx5 * sy5) / det5
intercept = (sxx5 * sy5 - sx5 * sxy5) / det5
@assert abs(slope - 2) < 0.01                   # 幂次回收
@assert abs(exp(intercept) - 3) < 0.1           # 系数回收
println("log-transform power law: exponent ", round(slope, digits=3),
        ", coefficient ", round(exp(intercept), digits=3), ": OK")

println("END ====")
