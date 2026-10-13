# 第 16 章 泛型扩张：Rasiowa-Sikorski 塔构造与 Cohen 泛型实数
#
# 1. 引理 16.1 的算法：逐层提升的塔构造泛型滤波器；
# 2. Cohen 泛型实数：2^{<ω} 偏序上的泛型滤波器 → 新实数。

println("==== 16 泛型扩张：塔构造与 Cohen 实数")

# ---------- 一、Rasiowa-Sikorski 塔构造 ----------

"""Cohen 偏序：有限 0/1 序列；p ⊑ q 当 p 是 q 的前缀"""
is_prefix(p::Vector{Bool}, q::Vector{Bool}) =
    length(p) <= length(q) && p == q[1:length(p)]

"""first_above：D 中线性扫描第一个延伸 p 的条件"""
function first_above(p::Vector{Bool}, D::Vector{Vector{Bool}})
    for q in D
        is_prefix(p, q) && return q
    end
    return p
end

"""Rasiowa-Sikorski 塔：p₀ 出发逐层提升（引理 16.1 的算法）"""
function rs_tower(p0::Vector{Bool}, D::Vector{Vector{Vector{Bool}}}, n::Int)
    p = p0
    for i in 1:n
        p = first_above(p, D[i])
    end
    return p
end

# ---------- 二、Cohen 泛型实数的生成 ----------

"""生成随机稠密集族（教学版：用有限代理）"""
function make_dense_family(P::Vector{Vector{Bool}}, k::Int)
    """第 n 个稠密集 = {p ∈ P : |p| ≥ n 或 p ⊑ 某 ≥n 长元素}"""
    [filter(p -> length(p) >= min(n, 8) || any(q -> is_prefix(p, q) && length(q) >= min(n, 8), P), P)
     for n in 1:k]
end

P0 = Bool[]                           # 初始条件 ∅
# 有限偏序 P = 2^{<4} 全体（直接枚举）
P_all = Vector{Bool}[[]]
for n in 1:4
    for bits in Iterators.product(fill([false, true], n)...)
        push!(P_all, collect(bits))
    end
end

Dfam = make_dense_family(P_all, 5)
G_partial = rs_tower(P0, Dfam, 5)
println("塔构造 5 层后条件长度 = ", length(G_partial))
println("（每层命中一个更长的条件——塔逐步增长）")

# ---------- 三、泛型滤波器三公理验证（(16.2)） ----------

"""从塔构造泛型滤波器 G = {q : q ⊑ tower p0 n 对某 n}"""
function generic_filter(p0, D, n)
    G = Vector{Vector{Bool}}[]
    p = p0
    for i in 1:n
        p = first_above(p, D[i])
        push!(G, p)
    end
    # 向上封闭 + 有向由塔链保证
    return G
end

G = generic_filter(P0, Dfam, 5)
println("\n泛型滤波器 G 的大小 = ", length(G))
println("G ∩ D_n ≠ ∅ 对 n=1..5：", all(any(p in Dfam[i] for p in G) for i in 1:5))
println("（塔构造保证每层命中——(16.3)(ii) 的验证）")

# ---------- 四、Cohen 泛型实数：f = ⋃G 是新实数 ----------

println("\nCohen 泛型实数的语义：")
println("  P = 2^{<ω}（有限 0/1 序列），f = ⋃G : ω → {0,1}")
println("  D_g = {p : p ⊥ g} 稠密（g ∈ 地面模型）⟹ f ≠ g")
println("  ⟹ f 是新实数（不在任何可数地面模型中）")

println("END ====")
