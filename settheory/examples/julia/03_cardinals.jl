# 第 03 章 基数：Hartogs 的数值灵魂与 ℵ·ℵ = ℵ 的配对函数
#
# 1. Hartogs 数 h(X)：最小无法单射进 X 的序数。有限情形 h(n)=n+1，
#    我们用"n 元集合的 α-排列计数"验证：P(n,α) 在 α≤n 时 >0，
#    在 α=n+1 时 =0——序数界的"满了"。
# 2. ℵα·ℵα = ℵα（Jech 定理 8）由 ω×ω 的典范配对 γ 实现：
#    γ(i,j) 按 max(i,j) 分层，把 ω×ω 单射满射到 ω。

println("==== 03 基数：Hartogs 与配对函数")

# ---------- 一、Hartogs 的有限侧影 ----------

# n 元集合的单射 α → X 的个数 = 排列数 P(n, α) = n!/(n-α)!
function injections_count(n::Int, alpha::Int)
    alpha > n && return 0
    return factorial(n) ÷ factorial(n - alpha)
end

println("n = 3 的集合上，各序数 α 的单射计数：")
for a in 0:5
    println("  α = $a : $(injections_count(3, a)) 个单射")
end
@assert injections_count(3, 3) == 6        # 3! —— 恰好排满
@assert injections_count(3, 4) == 0        # h(3) = 4：Hartogs 数
println("  → h(3) = 4（最小无法单射的序数）——有限情形 Hartogs = n+1")

# ---------- 二、ω×ω 的典范配对 γ（Jech (2.8) 的数值形态） ----------

# γ(i,j) = 前面所有层（max < m）的元素数 + 层内序号
# 层 m = max(i,j) 有 2m+1 个元素（(0,m),(1,m),...,(m,m),...,(m,0) 的顺序）
# 层内顺序：先 (k,m)（k=0..m），再 (m,k)（k=m-1..0）
function gamma_pair(i::Int, j::Int)
    m = max(i, j)
    before = m * m                       # 层 0..m-1 的总数：1+3+...+(2m-1) = m²
    if j == m
        return before + i                # (0,m)...(m,m)
    else
        return before + m + (m - j)      # (m,m-1)...(m,0)
    end
end

println("\nω×ω 的典范配对 γ（按 max 分层）：")
println("  γ(0,0) = ", gamma_pair(0, 0))
println("  γ(0,1) = ", gamma_pair(0, 1), "  γ(1,1) = ", gamma_pair(1, 1))
println("  γ(2,1) = ", gamma_pair(2, 1), "  γ(2,2) = ", gamma_pair(2, 2))
println("  γ(1,3) = ", gamma_pair(1, 3), "  γ(3,2) = ", gamma_pair(3, 2))

# 验证：γ 是 0..N×0..N 上的双射
for N in [3, 6, 10]
    vals = [gamma_pair(i, j) for i in 0:N for j in 0:N]
    @assert length(unique(vals)) == length(vals)   # 单射
    @assert maximum(vals) == (N + 1)^2 - 1          # 恰好填满 [0,(N+1)²-1]
    println("  N = $N ：γ 在 $(N+1)×$(N+1) 网格上是双射，最大值 = $(maximum(vals))")
end

# 关键观察：γ[N×N] ⊆ N² —— "|ω×ω| = ω"的有限影子
println("  γ[i,j] ≤ (max(i,j)+1)²-1：N×N 的像落在 N² 里 → ω×ω ≈ ω")

# ---------- 三、ℵ·ℵ = ℵ 的推演回放（Jech 定理 8 的骨架） ----------

println("\n定理 8（ℵα·ℵα=ℵα）的骨架回放：")
println("  反证：设 α 最小使 γ[ωα×ωα] ≠ ωα")
println("  取 β<ωα 使 γ(β,β)≥ωα；则 ωα ⊆ γ[β+1×β+1]")
println("  由最小性 |β×β|=|β|<ℵα —— 与上式矛盾")

println("END ====")
