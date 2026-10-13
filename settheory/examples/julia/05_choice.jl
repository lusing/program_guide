# 第 05 章 选择公理：良序构造与 Zorn 爬山的程序形态
#
# 1. Zermelo 良序定理（定理 15）的构造引擎：transfinite 枚举
#    a_α = F(A - {a_ξ : ξ<α})——有限集上的完整模拟；
# 2. Zorn 引理（定理 16）的爬山算法：链的贪心延伸到极大元。

println("==== 05 选择公理：良序与 Zorn 的程序形态")

# ---------- 一、良序定理的构造引擎 ----------

"""选择函数驱动的枚举：不断从未剩集合取元素，直到耗尽。
返回 (枚举序列, 使用步数)。这就是定理 15 证明的算法核心。"""
function zermelo_enum(A::Set{Int}, F::Function)
    rest = collect(A)
    out = Int[]
    while !isempty(rest)
        a = F(Set(rest))             # 选择函数在剩余集上取元素
        push!(out, a)
        setdiff!(rest, [a])
    end
    return out, length(out)
end

# 两种选择函数：最小元（= 良序化的"标准"选择）与任取（伪随机）
A = Set([5, 3, 8, 1, 9, 2])
enum_min, n1 = zermelo_enum(A, minimum)
enum_first, n2 = zermelo_enum(A, s -> first(sort(collect(s))))  # 同序

println("集合 {5,3,8,1,9,2} 经最小元选择函数良序化：")
println("  枚举 = ", enum_min, "（步数 = $n1）")
@assert enum_min == [1, 2, 3, 5, 8, 9]
@assert issorted(enum_min)
println("  选择函数 = minimum 时，transfinite 枚举恰好产生升序——")
println("  这就是『每个集合可良序化』的可计算影子。")

# ---------- 二、Zorn 爬山：贪心链延伸 ----------

"""偏序 (元素, 覆盖关系) 上的极大链贪心构造：
   从起点反复取严格更大的相邻元素直到到顶。
   返回 (极大链, 是否到达极大元)。"""
function zorn_climb(poset::Dict{Int,Vector{Int}}, start::Int)
    chain = [start]
    cur = start
    while true
        ups = filter(x -> x > cur, poset[cur])   # 严格上邻
        if isempty(ups)
            return chain, true                    # cur 极大
        end
        cur = minimum(ups)                        # 选择函数再上场
        push!(chain, cur)
    end
end

# 一个小格：1<2<4, 1<3<4（菱形），4 是唯一极大元
poset = Dict(1 => [2, 3], 2 => [4], 3 => [4], 4 => Int[])
for s in [1, 2, 3]
    chain, maximal = zorn_climb(poset, s)
    println("从 $(s) 爬山：链 = $(chain)，到达极大元 = $(maximal)")
    @assert chain[end] == 4
end

# 换一个有两个极大元的偏序：1<2<5, 1<3<6（双峰）
poset2 = Dict(1 => [2, 3], 2 => [5], 3 => [6], 5 => Int[], 6 => Int[])
c1, _ = zorn_climb(poset2, 1)
println("双峰偏序从 1 出发：链 = $c1（落进 $(c1[end]) —— Zorn 只保证某个极大元）")
@assert c1[end] in (5, 6)

# ---------- 三、可数选择的经典应用：可数并可数 = 可数 ----------

# 引理 5.1 的数值影子：每个 A_n 可数，给枚举后 ℕ×ℕ → ⋃A_n 是投影
A_ns = [Set(k * 100 + n for k in 1:5) for n in 1:4]   # 4 个 5 元集
union_all = union(A_ns...)
println("\n4 个 5 元集的并：|⋃| = $(length(union_all)) ≤ 4×5 = 20")
@assert length(union_all) <= 4 * 5
println("选择函数在此 = 为每个 A_n 选定一张枚举表；")
println("没有它，『可数个可数集』的并可能不可数（ZF 反例）。")

println("END ====")
