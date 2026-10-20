# -*- coding: utf-8 -*-
println("==== 56 lll")
# 第 56 章 Julia：重对数律的包络轨道。
# ① 正态游走 vs ±√(2n log log n) 包络（多轨道触界不穿越）；
# ② 几何子列的 0/1 转换（包络系数 c>1 vs c<1）；③ 单边 LIL；
# ④ 重尾对照（无二阶矩则 LIL 破产）。
using Random, Statistics

Random.seed!(56)

# LIL 包络：φ(n) = sqrt(2n log log n)（n ≥ 3）
envelope(n) = sqrt(2.0 * n * log(log(n)))

# ① 多轨道包络显影：n = 3..40000 的正态游走。**有限 n 诚实账**：
#    log log(4e4) = 2.36 远未入渐近域（二阶修正 ~1/√LLn 量级），
#    实测 max|S|/包络 的中位 ~1.3-1.5——包络给出正确**量级**与
#    √n·√loglog 结构，常数 1 是渐近陈述（数值断言按量级定）
function walk_stats(n_max)
    s = 0.0
    touch = false                          # 曾达 0.9·包络
    cross = false                          # 曾超 2.0·包络
    maxratio = 0.0
    for n in 3:n_max
        s += randn()
        r = abs(s) / envelope(n)
        maxratio = max(maxratio, r)
        r > 0.9 && (touch = true)
        r > 2.0 && (cross = true)
    end
    (touch, cross, maxratio)
end
function lll_paths(paths = 40)
    touch = cross = 0
    ratios = Float64[]
    for _ in 1:paths
        t, c, m = walk_stats(40_000)
        t && (touch += 1)
        c && (cross += 1)
        push!(ratios, m)
    end
    (touch, cross, median(ratios), maximum(ratios), paths)
end
touch, cross, med, mr, paths = lll_paths()
@assert touch >= paths - 4                 # 几乎每条轨道触 0.9 带
@assert cross <= paths ÷ 3                 # 2 倍包络的穿越罕见
@assert 1.0 < med < 2.0                    # 中位比在正确量级（渐近 1）
@assert mr < 5.0                           # 上界受控
println("LIL envelope: touched ", touch, "/", paths, "; crossed(2x) ", cross,
        "; median ratio = ", round(med, digits=3), " (asymptote 1): OK")

# ② 几何子列的 0/1 转换：q = 1.5 的检查点，包络系数 c 的两侧
function geom_hits(c; q = 1.5, n_max = 40_000)
    # 检查点 n_m = q^m（几何子列——56.3 步骤 1）
    s = 0.0
    hits = 0
    m = 0
    n_m = 1.0
    for n in 1:n_max
        s += randn()
        if n + 0.5 >= n_m                  # 到达检查点
            m += 1
            n_m = q^m
            n >= 3 && abs(s) > c * envelope(n) && (hits += 1)
        end
    end
    hits, m
end
h_plus, m_plus = geom_hits(1.6)
@assert h_plus < m_plus ÷ 8                # c > 1：几何子列上几乎不越界
h_minus, _ = geom_hits(0.8)
@assert h_minus > 0                        # c < 1：确有越界（发散侧）
println("geometric subsequence 0/1: c=1.6 hits ", h_plus, "/", m_plus,
        " checkpoints; c=0.8 hits ", h_minus, " (crossing the wall): OK")

# ③ 单边 LIL：max_{k≤n}Sₖ 与 Sₙ 的比（习题 25.6——首穿不改变包络）
function one_sided_ratio(n_max = 30_000)
    s = 0.0
    mx = 0.0
    r_max = 0.0
    for n in 3:n_max
        s += randn()
        mx = max(mx, s)
        n > 1000 && (r_max = max(r_max, mx / envelope(n)))
    end
    r_max
end
r1 = median([one_sided_ratio() for _ in 1:15])
@assert 0.5 < r1 < 1.6                     # 单边包络同刻度（渐近同 1，
#   有限 n 下单边 max 只用一半触界机会，中位偏低——如实）
println("one-sided LIL: median max-ratio = ", round(r1, digits=3),
        " (same envelope): OK")

# ④ 重尾对照：Cauchy 步长的 |Sₙ|/包络 → ∞（无二阶矩 ⟹ LIL 破产）
cauchy_step() = tan(pi * (rand() - 0.5))
function heavy_ratio(n_max = 20_000)
    s = 0.0
    mr = 0.0
    for n in 3:n_max
        s += cauchy_step()
        mr = max(mr, abs(s) / envelope(n))
    end
    mr
end
hr = maximum([heavy_ratio() for _ in 1:8])
@assert hr > 20                            # 包络被碾压（正态情形 < 1.6）
println("heavy-tail violation: Cauchy max |S|/envelope = ", round(hr, digits=1),
        " (envelope crushed): OK")

println("END ====")
