# -*- coding: utf-8 -*-
println("==== 51 slln")
# 第 51 章 Julia：强大数定律的四轨道账 + 分界双轨。
# ① 正规数频率（端点带判收敛——LIL 墙纪律）；② Monte Carlo
#    积分的 a.s. 轨道；③ 更新过程 N_t/t → 1/μ；④ Glivenko-
#    Cantelli 的 D_n 衰减；⑤ 分界账：对称重尾（习题 20.18 型）
#    的依概率收敛 vs 几乎必然不收敛。
using Random, Statistics

Random.seed!(51)

# ① 正规数（二进制）：频率端点带 |Sₙ/n − 1/2| ≤ 2/√n（≥95% 覆盖）
function normal_digit_track(n_max)
    cnt = 0
    for k in 1:n_max
        cnt += rand() < 0.5 ? 1 : 0
        if k == n_max
            return cnt / k
        end
    end
end
function band_coverage()
    hits = 0
    for _ in 1:200
        f = normal_digit_track(5000)
        abs(f - 0.5) <= 2 / sqrt(5000) && (hits += 1)
    end
    hits
end
hits = band_coverage()
@assert hits >= 180
println("normal numbers: endpoint band 2/sqrt(n) coverage = ", hits, "/200: OK")

# ② Monte Carlo ∫₀¹ eˣ dx = e − 1：运行均值的 a.s. 轨道
target = exp(1) - 1
function mc_path(n)
    s = 0.0
    for _ in 1:n
        s += exp(rand())
    end
    s / n
end
p1, p2 = mc_path(1_000), mc_path(100_000)
@assert abs(p1 - target) < 0.05          # 粗带
@assert abs(p2 - target) < 2 / sqrt(100_000)  # 端点带
println("Monte Carlo: |mean - (e-1)| shrinks to 2/sqrt(n) band: OK")

# ③ 更新过程：寿命 Exp(1)（逆变换采样），N_t/t → 1/μ = 1
function renewal(t_max)
    n, s = 0, 0.0
    while true
        s += -log(1.0 - rand())          # Exp(1) 逆变换
        s > t_max && break
        n += 1
    end
    n
end
r1 = renewal(2_000) / 2_000
r2 = renewal(20_000) / 20_000
@assert abs(r1 - 1.0) < 0.05
@assert abs(r2 - 1.0) < 0.02
println("renewal: N_t/t -> 1/mu (t=2e3: ", round(r1, digits=4),
        ", t=2e4: ", round(r2, digits=4), "): OK")

# ④ Glivenko-Cantelli：U[0,1] 的 D_n = sup|F̂ₙ−F|
function glivenko_d(n)
    xs = sort(rand(n))
    d = 0.0
    for (k, x) in enumerate(xs)
        d = max(d, abs(k / n - x), abs((k - 1) / n - x))
    end
    d
end
d1, d2, d3 = glivenko_d(10), glivenko_d(100), glivenko_d(10_000)
@assert d3 < d2 < d1                       # 单调收缩（本轨道）
@assert d3 < 0.02                          # DKW：P(D>0.02) ≤ 2e^{-8}
println("Glivenko-Cantelli: D_n = ", round(d1, digits=3), " -> ",
        round(d3, digits=4), " (n=10..1e4): OK")

# ⑤ 分界账：对称重尾 P{|X|>x} = e/(x log x)，x ≥ e（习题 20.18 型）
#    尾函数逆变换：解 e/(x log x) = U ⟺ x log x = e/U（二分，x ≥ e 单调）
function heavy_tail_sample()
    u = rand()
    c = exp(1) / u                          # 目标 x log x = c（≥ e 恒成立）
    lo, hi = exp(1), exp(1)
    while hi * log(hi) < c
        hi *= 2
    end
    for _ in 1:80                           # 二分 80 步足够
        mid = (lo + hi) / 2
        if mid * log(mid) < c
            lo = mid
        else
            hi = mid
        end
    end
    y = (lo + hi) / 2
    return rand() < 0.5 ? y : -y            # 随机符号对称化
end
# (a) 依概率：B 条独立轨道在 n = 4000 的端点 |Sₙ/n| ≤ ε 的比例 → 1
# (a) 依概率收敛的稳健侧写：|S̄ₙ| 的**中位数**随 n 下降——
#     收敛速率 1/log 尺度（真实数学：median|S̄ₙ| 由大跳事件主导，
#     n·P{|X|>εn} = e/(ε log(εn)) —— n 从 1e3 到 8e3 只从 ~0.6
#     降到 ~0.5；小 ε 带在可达的 n 上不可能——如实断言趋势与量级）
function sbar_paths(n, B)
    out = Float64[]
    for _ in 1:B
        s = 0.0
        for _ in 1:n
            s += heavy_tail_sample()
        end
        push!(out, abs(s / n))
    end
    out
end
med1 = median(sbar_paths(1_000, 300))
med2 = median(sbar_paths(8_000, 300))
@assert med2 < med1                          # 中位数单调改善
@assert med1 > 0.5 && med2 < 0.6            # 量级符合 1/log 慢尺度理论
p1 = mean(sbar_paths(1_000, 300) .> 1.5)     # 大 ε 越界率趋势
p2 = mean(sbar_paths(8_000, 300) .> 1.5)
@assert p2 < p1                              # 越界率向下
# (b) 几乎必然死：单条长轨道的端点值不收敛——漂移超过小带
function slln_dead_path()
    snap = Float64[]
    acc = 0.0
    for k in 1:20_000
        acc += heavy_tail_sample()
        if k in (2_000, 5_000, 10_000, 20_000)
            push!(snap, acc / k)
        end
    end
    maximum(snap) - minimum(snap)
end
spread = slln_dead_path()
@assert spread > 0.10                        # 端点值仍在漂移（SLLN 死）
println("boundary law: median|Sbar| ", round(med1, digits=3), " -> ",
        round(med2, digits=3), " (1/log scale, WLLN alive);",
        " single path spread = ", round(spread, digits=3),
        " (SLLN dead): OK")

println("END ====")
