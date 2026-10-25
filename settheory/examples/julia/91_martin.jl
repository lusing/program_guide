# 第 91 章 · 马丁公理之合理性与迭代力迫（冯琦第二卷 §3.4）——Julia 通道
# 与 Python 同一组检查：迭代相容分解、典型嵌入冲突换算、
# 有限支撑与坐标合并、Cantor 记录函数、greedy 相遇引擎。
println("==== 91")

# ---------- 一、一步迭代的相容分解（定理 3.14 的组合核心） ----------

# Julia 1 基索引：ext(p, q) 即 p 是 q 的前缀。
ext(p, q) = length(p) <= length(q) && q[1:length(p)] == p
agree(p, q) = ext(p, q) || ext(q, p)
iter_agree(x, y) = agree(x[1], y[1]) && agree(x[2], y[2])

function iter_common(x, y)
    cmn(p, q) = ext(p, q) ? q : p
    (cmn(x[1], y[1]), cmn(x[2], y[2]))
end

S = [collect(t) for k in 0:2 for t in Iterators.product(fill((0, 1), k)...)]
for x1 in S, x2 in S, y1 in S, y2 in S
    x, y = (x1, x2), (y1, y2)
    if iter_agree(x, y)
        r = iter_common(x, y)
        @assert ext(x[1], r[1]) && ext(y[1], r[1])
        @assert ext(x[2], r[2]) && ext(y[2], r[2])
    end
end
println("迭代相容 iff 分量相容：合并构造双向账 OK")

# ---------- 二、典型嵌入的冲突换算（引理 3.54(6)） ----------

canon(p) = (p, Int[])
for p in S, p2 in S
    @assert iter_agree(canon(p), canon(p2)) == agree(p, p2)
end
println("典型嵌入：i(p) 与 i(p') 相容 <=> p 与 p' 相容（穷举）OK")

# ---------- 三、有限支撑迭代（定义 3.36） ----------

# none 用 nothing 表示。
spt(p) = count(!isnothing, p)

function merge_c(p, q)
    n = max(length(p), length(q))
    [let a = i <= length(p) ? p[i] : nothing,
         b = i <= length(q) ? q[i] : nothing
         a === nothing ? b : a
     end for i in 1:n]
end

@assert spt([nothing, 1, nothing, 0]) == 2
@assert merge_c([nothing, 1], [0, nothing]) == [0, 1]
@assert merge_c([1, nothing], [nothing, 0]) == [1, 0]
C3 = [collect(t) for t in Iterators.product((nothing, 0, 1), (nothing, 0, 1), (nothing, 0, 1))]
@assert all(spt(p) <= length(p) for p in C3)
println("支撑计数 + 坐标合并：[nothing,1,nothing,0] 支撑 2 OK")

# ---------- 四、Cantor 记录函数（定理 3.18 的 (b) 款） ----------

cantor(b, g) = (b + g) * (b + g + 1) ÷ 2 + g
for b in 0:7, g in 0:7
    @assert b <= cantor(b, g)
end
codes = [cantor(b, g) for b in 0:4 for g in 0:4]
@assert length(unique(codes)) == 25
println("Cantor 配对：b <= 编号（64 例）、5x5 编号两两不同 OK")

# greedy 相遇引擎（定理 3.1 的迭代面）
decider(n) = p -> n < length(p) ? copy(p) : vcat(p, fill(0, n + 1 - length(p)))
p = Int[]; chain = [Int[]]
for n in 0:2
    global p = decider(n)(p)
    push!(chain, copy(p))
end
@assert length.(chain) == [0, 1, 2, 3]
println("greedy 相遇链：长度 [0, 1, 2, 3]——一步迭代的演示面 OK")

println("END ====")
