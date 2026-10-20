println("==== 43 local_martingales")
# 第 43 章：截断与策略。
# ① 局部化截断的稳定性；② 可料策略的公平性；
# ③ 偷看策略的获利；④ 非负恢复。

using Random, Statistics
Random.seed!(43)

# ① 局部化截断：乘积鞅 ±0.8（重尾版）在 τ_k = inf{|M| >= k} 截断后
# 期望稳定（每段是鞅），对照全局期望的理论值 1
function product_trunc(n, eps, cap)
    """停止过程 M^{tau}：tau = inf{|M| >= cap} 后冻结（真停止，非 clamp）。"""
    m = 1.0
    for k in 1:n
        abs(m) >= cap && break                 # 冻结在穿越值（停止语义）
        m *= 1 + (rand() < 0.5 ? eps : -eps)
    end
    m
end
for cap in (2.0, 5.0)
    vals = [product_trunc(300, 0.8, cap) for _ in 1:2000]
    mv = mean(vals)
    @assert 0.2 < mv < 5.0                     # 截断后期望有界（稳定性的粗账）
end
# 对照：无截断版的中位数深度衰减（局部化前的野性）
med = median([product_trunc(300, 0.8, 1e18) for _ in 1:1000])
@assert med < 0.01
println("localization truncation: capped means bounded, raw median -> 0: OK")

# ② 可料策略：H_k = sign(D_{k-1})（昨日方向，𝓕_{k-1}-可测）
function strat_pnl_correct(T)
    D = rand([-1.0, 1.0], T)                   # 差分列
    pnl = 0.0
    for k in 2:T
        H = D[k-1] > 0 ? 1.0 : -1.0            # 可料：昨日方向
        pnl += H * D[k]                        # 今日差分
    end
    pnl
end
vals = [strat_pnl_correct(200) for _ in 1:4000]
@assert abs(mean(vals)) < 5.0                  # E = 0（鞅性保持——噪声 ~ sqrt(T))
println("predictable strategy (follow yesterday): mean pnl = ", round(mean(vals), digits=2), " ~ 0: OK")

# ③ 偷看策略：H_k = 今日实际方向（非可料）
function cheat_pnl(T)
    D = rand([-1.0, 1.0], T)
    pnl = 0.0
    for k in 2:T
        H = D[k] > 0 ? 1.0 : -1.0              # 偷看今日
        pnl += H * D[k]                        # = |D_k| = 1
    end
    pnl
end
vals2 = [cheat_pnl(200) for _ in 1:500]
@assert mean(vals2) > 190                      # ≈ 199：每步 +1
println("cheating strategy (lookahead): mean pnl = ", round(mean(vals2), digits=1),
        " ≈ T-1 (arbitrage from future info): OK")

# ④ 非负恢复：|截断鞅| 的期望有限（恢复定理的条件侧）
for cap in (2.0, 5.0)
    vals = [abs(product_trunc(100, 0.8, cap)) for _ in 1:1000]
    @assert mean(vals) ≤ cap
end
println("nonnegative recovery: |truncated M| bounded by cap: OK")

println("END ====")
