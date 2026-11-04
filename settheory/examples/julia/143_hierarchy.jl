# 第 143 章 Julia：层垒谱系的数值面（书 7.2）。
# ① |V_n| 的增长曲线（0,1,2,4,16,65536——每层幂集）；
# ② 秩分布：V_4 内各集合的秩直方图；
# ③ HF 宇宙的密度：V_ω 中秩 < n 的比例。
println("==== 143 hierarchy")

# ① V_n 构造（与 Python/Coq 通道互证）
all_subsets(items) = begin
    n = length(items)
    [Set(items[i] for i in 1:n if (mask >> (i-1)) & 1 == 1) for mask in 0:(1<<n)-1]
end

V = Vector{Set{Any}}([Set{Any}()])
for _ in 1:4
    push!(V, Set{Any}(all_subsets(collect(V[end]))))
end
@assert length.(V) == [0, 1, 2, 4, 16]
println("V hierarchy: |V0..V4| = 0,1,2,4,16: OK")

# ② 秩函数与直方图
rank(x::Set) = isempty(x) ? 0 : maximum(rank.(collect(x)) .+ 1)

rank1 = Set()
rank2 = Set([rank1])
rank3 = Set([rank2])
@assert rank(rank1) == 0
@assert rank(rank2) == 1
@assert rank(rank3) == 2

# V_4 = P(V_3)，V_3 有 4 元素——秩分布
hist = Dict{Int,Int}()
for x in V[4]
    r = rank(x)
    hist[r] = get(hist, r, 0) + 1
end
# V_4 的元素秩 ≤ 3；恰有 C(4,k) 个秩为 k... 不是这个——V_4=P(V_3) 的元素
# 是 V_3 的子集，秩 = max(元素秩)+1 或 0
@assert get(hist, 0, 0) == 1                                 # ∅
@assert get(hist, 1, 0) == 1                                 # {∅} 是唯一秩1子集
println("rank histogram on V_4: rank 0 -> 1 (empty), rank 1 -> 1 ({empty}): OK")

# ③ x ∈ y ⟹ rank(x) < rank(y) 的全量审计（V_3 内）
for y in V[3]
    for x in y
        @assert rank(x) < rank(y)
    end
end
println("rank monotone: x in y implies rank x < rank y: OK")

# ④ 传递闭包（书 7.2.12）的尺寸曲线：嵌套深度 d 的链的 trcl 大小 = d
chain(d) = begin
    c = Set{Any}()
    for _ in 1:d
        c = Set{Any}([c])
    end
    c
end

function trcl_size(x)
    seen = Set{Any}()
    frontier = collect(x)
    while !isempty(frontier)
        cur = pop!(frontier)
        cur in seen && continue
        push!(seen, cur)
        append!(frontier, collect(cur))
    end
    length(seen)
end

for d in (1, 2, 3, 4)
    @assert trcl_size(chain(d)) == d
end
println("trcl sizes: chain of depth d has trcl of size d: OK")
println("END ====")
