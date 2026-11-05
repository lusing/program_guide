# 第 59 章 Julia：随机游动与马氏链的三条模拟对账线（固定种子）。
# ① 回返率：p = 0.5 / 0.6 的 Bernoulli 游动，有限窗回返频率对比
#    f* = 1 − |2p−1|（1 与 0.8；对称情形窗内频率向 1 爬升）；
# ② 赌徒破产：N = 10 的破产/满贯频率 vs u_i = i/N；
# ③ 通信链：Cesaro 平均 (1/N)Σ p^(k)₁₁ → 1/2，衰减率 |2p−1|^k 对照。
# 模拟只对账理论值，不冒充证明。
println("==== 59 random_walks")
using Random

# ---------- ① 回返率 ----------
const rng = MersenneTwister(5901)
function return_rate(p, horizon)
    n = 200_000
    hit = 0
    for _ in 1:n
        s = 0
        for _ in 1:horizon
            s += rand(rng) < p ? 1 : -1
            if s == 0
                hit += 1
                break
            end
        end
    end
    return hit / n
end
println("① 回返率（有限窗内的回返频率）：")
println("   p=0.5：窗 10 → ", round(return_rate(0.5, 10), digits=3),
        "，窗 100 → ", round(return_rate(0.5, 100), digits=3),
        "，窗 1000 → ", round(return_rate(0.5, 1000), digits=3), "（→ f* = 1）")
println("   p=0.6：窗 10 → ", round(return_rate(0.6, 10), digits=3),
        "，窗 100 → ", round(return_rate(0.6, 100), digits=3),
        "，窗 1000 → ", round(return_rate(0.6, 1000), digits=3), "（→ f* = 0.8）")
r6 = return_rate(0.6, 1000)
@assert 0.7 < r6 < 0.9  # 有限窗内贴住理论值 0.8

# ---------- ② 赌徒破产 ----------
const rng2 = MersenneTwister(5902)
function win_rate(i, N)
    n = 40_000
    win = 0
    for _ in 1:n
        s = i
        while 0 < s < N
            s += rand(rng2) < 0.5 ? 1 : -1
        end
        win += (s == N)
    end
    return win / n
end
println("② 破产对账（N=10，频率 vs i/N）：")
for i in [2, 5, 8]
    emp = win_rate(i, 10)
    theo = i / 10
    println("   i=", i, "：模拟 ", round(emp, digits=3), " vs 理论 ", theo,
            "（偏差 ", round(abs(emp - theo), digits=3), "）")
    @assert abs(emp - theo) < 0.02
end

# ---------- ③ 通信链的遍历极限 ----------
p = 0.75
q = 2p - 1
p11(k) = (1 + q^k) / 2        # 闭式解：对角元
println("③ 通信链（p=3/4）的 Cesaro 平均 vs 1/2，衰减率 |2p−1|^k = ", q, "：")
for K in [1, 4, 16, 64]
    ces = sum(p11(k) for k in 1:K) / K
    println("   N=", K, "：(1/N)Σ p^(k)₁₁ = ", round(ces, digits=5),
            "，|q|^N = ", round(q^K, digits=6))
end
@assert abs(sum(p11(k) for k in 1:64) / 64 - 0.5) < 1e-2

println("END ====")
