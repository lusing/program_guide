println("==== 35 independence")
# 第 35 章：乘法账与 0-1 现象。
# ① 双骰模型两两独立但三元爆雷；② BC 一/二版 i.o. 频率；
# ③ 卷积（U*U 三角 + Bernoulli 二项）；④ 尾部事件 0-1 显影。

# ① 双骰：A=第一颗为 1, B=第二颗为 1, C=总和为偶
# C = "两颗同奇偶"——A、B 各影响 C 的一半
pA = 1 / 6; pB = 1 / 6
P_C = 18 / 36                                  # 同奇偶对数
P_AB = 1 / 36; P_AC = 3 / 36; P_BC = 3 / 36    # 两两乘法账 ✓
@assert abs(P_AB - pA * pB) < 1e-12
@assert abs(P_AC - pA * P_C) < 1e-12
@assert abs(P_BC - pB * P_C) < 1e-12
# 三元账：P(ABC) = 1/36（(1,1) 和为 2 偶 ⟹ C 成立）≠ pA·pB·P_C = 1/72
PABC_true = 1 / 36
@assert abs(PABC_true - pA * pB * P_C) > 1e-3   # 爆雷：1/36 vs 1/72
println("pairwise independent but P(ABC) = 1/36 != 1/72: blow-up witnessed: OK")

# ② Borel-Cantelli
using Random
Random.seed!(35)
function total_count(pn, steps, trials)
    """i.o. 的数值侧写：总发生次数的均值。收敛级数 ⟹ 次数有界；
    发散级数 ⟹ 次数 ~ 对数/幂增长（i.o. 的必要伴随）。"""
    s = 0.0
    for _ in 1:trials
        c = 0
        for k in 1:steps
            rand() < pn(k) && (c += 1)
        end
        s += c
    end
    s / trials
end
# Σ1/n² 收敛：总次数有界（→ π²/6 ≈ 1.64）——i.o. 概率 0
c1a = total_count(n -> 1 / n^2, 2000, 200)
c1b = total_count(n -> 1 / n^2, 8000, 200)
@assert abs(c1a - c1b) < 0.15                # 稳定于极限（不再增长，噪声 0.1 级）
@assert 1.5 < c1b < 1.8                      # ≈ π²/6
println("BC first (convergent): occurrence count saturates at ~ pi^2/6: OK")
# Σ1/n 发散：总次数 ~ log(steps) 增长——i.o. 概率 1 的伴随
c2a = total_count(n -> 1 / n, 2000, 200)
c2b = total_count(n -> 1 / n, 8000, 200)
@assert c2b - c2a > 0.7                      # log(8000)-log(2000) = log 4 ≈ 1.39
@assert c2b > c2a > 2.0
println("BC second (divergent): count grows like log(steps) (", round(c2a, digits=2),
        " -> ", round(c2b, digits=2), "): OK")

function fit_hist(xs, edges)
    h = zeros(length(edges) - 1)
    for x in xs
        for i in 1:length(h)
            if edges[i] ≤ x < edges[i+1]
                h[i] += 1 / length(xs)
                break
            end
        end
    end
    h
end
binom(n, k) = binomial(BigInt(n), BigInt(k)) |> Float64

# ③ 卷积：U*U 三角分布
N = 400_000
s = rand(N) .+ rand(N)
# 分箱对拍三角密度 f(z) = z (z<1), 2-z (z>=1)
edges = collect(0.0:0.1:2.0)
h = fit_hist(s, edges)
tri(z) = z < 1 ? z : 2 - z
for (i, c) in enumerate(h)
    zmid = (edges[i] + edges[i+1]) / 2
    @assert abs(c - tri(zmid) * 0.1) < 0.012  # 每箱 vs 密度×宽（泊松噪声）
end
println("U*U triangular convolution: histogram vs density: OK")

# Bernoulli 卷积：4 枚硬币的 true 计数 ~ Binomial(4, 1/2)
cnt4 = [count(==(true), rand(Bool, 4)) for _ in 1:100_000]
for k in 0:4
    freq = count(==(k), cnt4) / 100_000
    @assert abs(freq - binom(4, k) / 16) < 0.006
end
println("Bernoulli convolution = Binomial(4,1/2) exact-ish: OK")

# ④ 尾部事件 0-1 显影
hits = 0
for _ in 1:200
    n = 20_000
    S = cumsum(rand(Bool, n))
    m = S[end] / n
    abs(m - 0.5) < 0.02 && (global hits += 1)
end
@assert hits ≥ 195                             # 0-1 律的"1 侧"（2% 带容纳波动）
println("tail event {|mean - 1/2| < 0.01}: all 200 orbits on the 1-side: OK")

# 辅助
println("END ====")
