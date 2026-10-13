# 第 04 章 实数：康托集的构造现场与 Baire 纲定理的数值体验
#
# 1. 康托集：逐步挖中段的构造、测度递减、完美性（无孤立点）检查；
# 2. Baire 纲（Jech 定理 13）：可数个稠密开集的交仍稠密——
#    在有限网格上体验"交不空"。

println("==== 04 实数：康托集与 Baire 纲")

# ---------- 一、康托集构造 ----------

"""返回第 depth 步保留的闭区间列表（精确分数算术）"""
function cantor_ivs(depth::Int)
    ivs = [(0 // 1, 1 // 1)]
    for _ in 1:depth
        nxt = Tuple{Rational{Int},Rational{Int}}[]
        for (a, b) in ivs
            third = (b - a) // 3
            push!(nxt, (a, a + third))
            push!(nxt, (b - third, b))
        end
        ivs = nxt
    end
    return ivs
end

for d in 0:5
    ivs = cantor_ivs(d)
    total = sum(b - a for (a, b) in ivs)
    println("  depth=$(d)：区间数=$(lpad(length(ivs),3))，总测度=$(total)")
    @assert total == (2 // 3)^d
end
println("  测度 (2/3)^n → 0，但每点有三进制地址：|C| = 2^ℵ₀")

# 完美性检查：保留区间的端点永远不是孤立的（每个端点 x 的任意
# 邻域内有同层的另一个端点）
d = 6
ivs = cantor_ivs(d)
pts = [a for (a, b) in ivs]  # 左端点集
min_gap = minimum(abs(pts[i] - pts[j]) for i in 1:length(pts), j in 1:length(pts) if i ≠ j)
println("  depth=$(d) 的左端点最小间距 = $min_gap（有限步骤内无孤立）")

# ---------- 二、Baire 纲（定理 13）：稠密开集的交非空 ----------
# 数值体验：在 [0,1] 网格上取一列"挖掉小洞"的开稠密集，
# 有限个的交永远不空且仍稠密。

grid = [k // 1000 for k in 1:999]

# D_n = [0,1] 去掉以 q_n 为中心、半径 r_n 的小闭洞（q_n 遍历有理网格）
function baire_intersection(depth::Int)
    holes = [(k // (depth + 1), 1 // (4 * (depth + 1)^2)) for k in 1:depth]
    survivors = [x for x in grid
                 if all(abs(x - c) >= r for (c, r) in holes)]
    return survivors
end

for d in [3, 10, 50, 200]
    surv = baire_intersection(d)
    println("  挖 $d 个洞后剩 $(length(surv)) 个网格点（仍稠密非空）")
    @assert length(surv) > 0
end
println("  Baire 纲：可数个稠密开集的交在完备空间中仍稠密；")
println("  推论（Jech）：ℚ 不是可数个开集的交——ℚ ≠ G_δ。")

println("END ====")
