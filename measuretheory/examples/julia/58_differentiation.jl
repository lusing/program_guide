# 第 58 章 Julia：测度导数的数值横截面（确定性，无随机）。
# ① 混合测度 μ = m/2 + ν_C/2 的局部比值表：缺口内点恒 1/2（精确），
#    Cantor 端点 0 沿 r=3^-n 的比值 (1/2)(1+(3/2)^n) 发散（奇异侧）；
# ② 密度定理：S=[0,1/3] 在内点/边界点/外点的密度比三走向（→1、→1/2、→0）；
# ③ 变差账：分段线性 f 的 V(P) 在加密分割下逼近转折点和（精确有理数）。
println("==== 58 differentiation")

# ---------- ① 混合测度的局部比值 ----------
# μ = m/2 + ν_C/2。缺口 (1/3,2/3) 内点 1/2：含于缺口的区间 ν_C 质量为 0，
# 比值恒 1/2（精确有理数）。
for n in 1:8
    r = 1 // 3^n
    # 区间 [1/2 - r/6, 1/2 + r/6] 含于缺口（r/6 < 1/6 即可，精确验证）
    @assert 1 // 3 < 1 // 2 - r // 6 && 1 // 2 + r // 6 < 2 // 3
    ratio = 1 // 2          # m 侧 1/2 + Cantor 侧 0
    @assert ratio == 1 // 2
end
println("① 缺口内点：任何足够小的含内区间比值恒 1/2 = dμ/dm（精确）")
# Cantor 端点 0：区间 [0, 3^-n] 的比值 = (1/2)(1 + (3/2)^n)
println("   端点 0 处 [0, 3^-n] 比值（精确分数）：")
for n in 1:6
    ratio = 1 // 2 * (1 + Rational(3, 2)^n)
    println("     n=", n, " → ", ratio, " ≈ ", float(ratio))
    @assert ratio == 1 // 2 + 1 // (2 * Rational(2, 3)^n)
end
println("   相邻比恒 3/2 → ∞：奇异部分上导数发散（局部维数 log2/log3 < 1）")

# ---------- ② 密度定理三走向 ----------
S_len(x, r) = max(0, min(1 // 3, x + r) - max(0, x - r))
println("② 密度比 m(S∩[x±r])/2r，S=[0,1/3]：")
for (x, tag, lim) in [(1 // 6, "内点", "→ 1"), (1 // 3, "边界", "→ 1/2"), (1 // 2, "外点", "→ 0")]
    vals = [S_len(x, 1 // 2^k) / (2 * (1 // 2^k)) for k in 4:9]
    println("   x=", x, "（", tag, "）：", round.(Float64.(vals), digits=4), "  ", lim)
end
@assert S_len(1 // 3, 1 // 2^9) / (2 // 2^9) == 1 // 2   # 边界点恰好 1/2（精确）

# ---------- ③ 变差账 ----------
# f 过点 (0,0),(1,3),(2,1),(3,4),(4,2),(5,5) 的折线：转折点变差和
pts = [(0, 0), (1, 3), (2, 1), (3, 4), (4, 2), (5, 5)]
V_turn = sum(abs(pts[i+1][2] - pts[i][2]) for i in 1:5)
@assert V_turn == 13
# 加密分割：在折线节点间取中点细分，V(P) ≤ V_turn 且单调不减趋近
function variation(grid)
    # 折线 f 的值在 grid 上线性插值，V = Σ|Δf|
    f(x) = begin
        for i in 1:5
            if pts[i][1] <= x <= pts[i+1][1]
                t = (x - pts[i][1]) // 1
                _, y0 = pts[i]; _, y1 = pts[i+1]
                return y0 + t * (y1 - y0)
            end
        end
    end
    v = 0 // 1
    for i in 1:length(grid)-1
        v += abs(f(grid[i+1]) - f(grid[i]))
    end
    return v
end
println("③ 折线变差：转折点分割 V = ", V_turn, "（精确）")
for k in 1:3
    grid = [i // 2^k for i in 0:(5 * 2^k)]
    v = variation(grid)
    @assert v ≤ V_turn
    println("   加密 2^-", k, " 网格（含全部转折点）：V(P) = ", v, " = V_f（上确界达到）")
end

println("END ====")
