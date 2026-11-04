# 第 07 章 · 集合、函数与等价关系 —— Julia 通道
#
# 小集合上穷举：单/满/双三性格重合（鸽笼）、双射 = n!、贝尔数 B(4) = 15。

println("==== 07 集合、函数与等价关系")

# ---------- 全部函数 [dom] → [cod] 的枚举（f 编码为像的向量） ----------
function all_functions(dom::Int, cod::Int)
    fs = Vector{Int}[]
    for code in 0:(cod^dom - 1)
        d = digits(code, base=cod, pad=dom)     # 低位在前
        push!(fs, [d[dom - i + 1] + 1 for i in 1:dom])
    end
    fs
end

is_injective(f) = length(unique(f)) == length(f)
is_surjective(f, cod) = length(unique(f)) == cod

# ---------- 鸽笼：|X| = |Y| = 3 时 单 ⟺ 满 ⟺ 双 ----------
fs33 = all_functions(3, 3)
@assert length(fs33) == 27
for f in fs33
    @assert (is_injective(f) && is_surjective(f, 3)) ||
            (!is_injective(f) && !is_surjective(f, 3))
end
n_inj = count(is_injective, fs33)
@assert n_inj == 6 "3 元集双射应为 3! = 6，得 $n_inj"
println("3 元集间 27 个函数：单 ⟺ 满（鸽笼）；双射恰 3! = 6 ✓")

# ---------- 不等势方向：|X| = 3 → |Y| = 4 有单无满 ----------
fs34 = all_functions(3, 4)
@assert count(is_injective, fs34) == 24 "3 → 4 单射 4·3·2 = 24"
@assert count(f -> is_surjective(f, 4), fs34) == 0 "3 → 4 无满射"
println("3 → 4：单射 24 个、满射 0 个（值域至多 3 点）✓")

# ---------- 4 元集：双射 24 个 ----------
fs44 = all_functions(4, 4)
@assert count(f -> is_injective(f) && is_surjective(f, 4), fs44) == 24
println("4 元集：双射恰 4! = 24 ✓")

# ---------- 复合结合律（2 元集间全部函数对） ----------
fs22 = all_functions(2, 2)
for f in fs22, g in fs22, h in fs22
    fg = [f[g[i]] for i in 1:2]
    gh = [g[h[i]] for i in 1:2]
    @assert [f[gh[i]] for i in 1:2] == [fg[h[i]] for i in 1:2]
end
println("复合结合律：2 元集间全部 2⁶ 函数三元组逐点成立 ✓")

# ---------- 贝尔数：划分枚举（贝尔数 B(4) = 15） ----------
"""整数划分数列（集合划分按最小元素递归）。"""
function set_partitions(xs::Vector{Int})
    isempty(xs) && return [Vector{Int}[]]
    x = xs[1]
    rest = set_partitions(xs[2:end])
    out = Vector{Vector{Int}}[]
    for p in rest
        # x 单独成块
        push!(out, vcat([[x]], p))
        # x 并入既有某块
        for i in eachindex(p)
            q = deepcopy(p)
            push!(q[i], x)
            push!(out, q)
        end
    end
    out
end

parts4 = set_partitions(collect(1:4))
@assert length(parts4) == 15 "B(4) = 15，得 $(length(parts4))"
# 每个划分诱导的等价关系满足三公理
for p in parts4
    rel = Set{Tuple{Int,Int}}()
    for blk in p, a in blk, b in blk
        push!(rel, (a, b))
    end
    @assert all(a -> (a, a) in rel, 1:4)                       # 自反
    @assert all(ab -> (ab[2], ab[1]) in rel, rel)              # 对称
    @assert all(ab -> all(cd -> !(ab[2] == cd[1]) || (ab[1], cd[2]) in rel, rel), rel)  # 传递
end
println("4 元集划分 15 个（贝尔数 B(4)），每个诱导的等价关系三公理全过 ✓")

println("END ====")
