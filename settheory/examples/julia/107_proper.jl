# 第 107 章：主条件证书、(M,P)-泛型条件搜索与准稠密核查。
println("==== 107")

# ── 一、样本宇宙：根 0 分叉到终端 1、2（extT 表）──
const EXT = Dict{Int,Set{Int}}(
    0 => Set([0, 1, 2]),
    1 => Set([1]),
    2 => Set([2]),
)

compat(r, p) = !isempty(EXT[r] ∩ EXT[p])
ext_of(q) = get(EXT, q, Set{Int}())

# ── 二、反链与准稠密（定义 2.21 内核）──
is_antichain(A) = all(!compat(p, q) for p in A, q in A if p != q)

# A 在 q 之下准稠密：一切 r ≤ q 与 A 中某元素相容。
predense_below(A, q) = all(any(compat(r, p) for p in A) for r in ext_of(q))

# (M,P)-泛型条件证书。
generic_cond(As, q) = all(predense_below(A, q) for A in As)

# ── 三、正反样本 ──
A12 = Set([1, 2])
@assert is_antichain(A12)                    # 终端 1、2 不相容
@assert !is_antichain(Set([0, 1]))           # 0 与 1 相容
@assert predense_below(A12, 0)               # 根下准稠密
@assert predense_below(A12, 1)               # 终端下也准稠密
@assert !predense_below(Set([2]), 1)         # 单点 {2} 在 1 下不稠（2∉ext 1 且不相容）
@assert generic_cond([A12], 0)
@assert generic_cond([A12], 1)
@assert generic_cond([A12], 2)
@assert !generic_cond([Set([2])], 1)

# ── 四、泛型条件搜索（Task 22 Step 2：Julia/Python 独立搜索）──
function search_generic(As, universe)
    return sort(collect(q for q in universe if generic_cond(As, q)))
end

@assert search_generic([A12], 0:2) == [0, 1, 2]
@assert search_generic([A12], 0:5) == [0, 1, 2, 3, 4, 5]  # 空 extT 下平凡泛型
@assert search_generic([Set([1])], 0:2) == [1]        # 单点反链 {1} 下仅 1 泛型
@assert search_generic([Set([1]), A12], 0:2) == [1]   # 合取收紧到 1

# 更强条件保持证书（数值核查：q 强于 p ⟹ extT q ⊆ extT p）。
stronger(q, p) = ext_of(q) ⊆ ext_of(p)
@assert stronger(1, 0) && stronger(2, 0)
@assert !stronger(0, 1)
# 证书下放核查：p 泛型 ∧ q 强于 p ⟹ q 泛型。
for p in 0:2, q in 0:2
    if generic_cond([A12], p) && stronger(q, p)
        @assert generic_cond([A12], q)
    end
end

# ── 五、cc 与闭包的样本对照（命题 2.1 的影子）──
# cc 力迫保荟萃（链宇宙）；闭合力迫保荟萃（有下界）。
# 有限影子：cc ⟺ 无 3-反链（本宇宙反链至多 2 元）；闭包 ⟺ 每 2-链有下界。
function max_antichain_size(universe)
    us = collect(universe)
    best = 0
    for mask in 0:(2^length(us) - 1)
        A = Set(us[i] for i in 1:length(us) if (mask >> (i - 1)) & 1 == 1)
        if is_antichain(A)
            best = max(best, length(A))
        end
    end
    return best
end
@assert max_antichain_size(0:2) == 2
# 闭包：{1,1} 型 2-链有下界 1。
@assert 1 ∈ ext_of(1)   # 自反

println("Julia：主条件证书 4+2 正反；泛型搜索三例；更强条件保持证书全核查；")
println("极大反链规模 2（cc 影子）")
println("END ====")
