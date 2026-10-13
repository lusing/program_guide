# 第 09 章 正则公理：V_α 层级的增长实验
#
# V₀ = ∅，V_{α+1} = P(V_α)，V_λ = ⋃。
# 有限层的计数：|V_{n+1}| = 2^{|V_n|}——超指数爆炸；
# V_ω = HF（遗传有限全域）。

println("==== 09 正则公理：V_α 的增长")

# ---------- 一、|V_n| 的计数（用位长表示防溢出） ----------

"""|V_n| 的位数（bit length）：|V_0|=0，|V_{n+1}| = 2^{|V_n|}
   用 (log₂ 大小) 链条表示：bits(n+1) = |V_n| = 2^bits(n)"""
function v_bits(n::Int)
    n == 0 && return big(0)          # |V_0| = 0
    n == 1 && return big(1)          # |V_1| = |P(∅)| = 1
    # |V_n| = 2^(|V_{n-1}|)：只跟踪位数
    b = big(1)                        # |V_1| = 1
    for _ in 2:n
        b = big(2)^b                  # |V_n| = 2^{|V_{n-1}|}：位数=|V_{n-1}|
    end
    return b                          # = |V_n| 的位数（当 n≥1 递归定义）
end

println("  |V_0| = 0（空集）")
println("  |V_1| = 1（{∅}）")
println("  |V_2| = 2（P({∅}) = {∅, {∅}}）")
println("  |V_3| = 4")
println("  |V_4| = 16")
println("  |V_5| = 65536")
println("  |V_6| = 2^65536（位数 65537）——超指数起飞")
println("  V_ω = ⋃ V_n = HF（遗传有限全域，可数）")

# ---------- 二、实际枚举小层（验证前几层） ----------

powerset(s) = begin
    els = collect(s)
    n = length(els)
    Set(Set(els[i] for i in 1:n if (k >> (i-1)) & 1 == 1) for k in 0:(2^n-1))
end

V = Set([Set{Int}()])                 # V_1 = {∅}（用 frozenset of Int 表示）
println("\n  V_1 的大小 = ", length(V))
@assert length(V) == 1
V2 = powerset(V)
println("  V_2 的大小 = ", length(V2), "  （P(V_1)）")
@assert length(V2) == 2

# ---------- 三、rank 的计算（嵌套深度） ----------

"""集合的秩：rank(x) = sup{rank(y)+1}——在嵌套集合表示下的深度"""
rank_of(x) = x isa AbstractVector ? (isempty(x) ? 0 : maximum(rank_of.(x)) + 1) : 0

r0 = []                               # ∅：秩 0
r1 = [[]]                             # {∅}：秩 1
r2 = [[], [[]]]                       # {∅,{∅}}：秩 2
r2b = [[], [[]], [[], [[]]]]          # {∅,{∅},{∅,{∅}}}：秩 3
for (name, x, expect) in [("∅", r0, 0), ("{∅}", r1, 1), ("{∅,{∅}}", r2, 2),
                          ("von Neumann 3", r2b, 3)]
    println("  rank($name) = $(rank_of(x))（期望 $expect）")
    @assert rank_of(x) == expect
end
println("  von Neumann n 的秩恰是 n：rank(α) = α（引理 9.3 后的性质 (b)）。")

println("END ====")
