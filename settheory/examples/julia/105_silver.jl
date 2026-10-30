# 第 105 章：Silver 条件（有限部分函数）、Easton 支撑与贪心泛型搜索。
println("==== 105")

# ── 一、条件与偏序律（Add(α,α⁺⁺) 的影子：坐标 (α,ξ)、值 0/1）──
# 条件 = Dict{(Int,Int) => Int}，值域 {0,1}。
is_cond(p) = all(0 ≤ v ≤ 1 for v in values(p))

# 反向包含：q ≤ p ⟺ p ⊆ q（更强的条件信息更多）。
extC(p, q) = all(haskey(q, k) && q[k] == v for (k, v) in p)

agree(p, q) = all(p[k] == q[k] for k in keys(p) if haskey(q, k))

function merge(p, q)
    r = copy(p)
    for (k, v) in q
        if !haskey(r, k); r[k] = v; end
    end
    r
end

# 偏序律样本（Task 20 Step 2 指定件）。
p0 = Dict((0, 0) => 1)
q0 = Dict((0, 0) => 1, (1, 2) => 0)
r0 = Dict((0, 0) => 1, (1, 2) => 0, (3, 5) => 1)
@assert extC(p0, p0)                       # 自反
@assert extC(p0, q0) && extC(q0, r0) && extC(p0, r0)  # 传递
@assert is_cond(q0) && agree(p0, q0)
@assert merge(p0, q0) == q0                # 合并 = 下确界

# 冲突样本：公共键值不同 ⟹ 不相容。
c1 = Dict((0, 0) => 1); c2 = Dict((0, 0) => 0)
@assert !agree(c1, c2)

# ── 二、Easton 支撑（定义 2.9/2.10 影子）──
# spt(p) = 出现的 α-坐标全体；Easton：|spt ∩ μ| < μ（正则 μ）。
support(p) = Set(k[1] for k in keys(p))
easton_ok(p, μ) = count(a -> a < μ, support(p)) < μ

@assert support(q0) == Set([0, 1])
@assert !easton_ok(q0, 2)                  # {0,1} ∩ [0,2) 计 2 ≮ 2 → 假
@assert easton_ok(q0, 3)                   # 2 < 3 ✓
@assert !easton_ok(p0, 1)                  # 1 ≮ 1 → 假
@assert easton_ok(p0, 2)                   # 1 < 2 ✓

# ── 三、贪心泛型搜索（有限稠密族相遇）──
# D(α,ξ,b) = {p | p(α,ξ) = b}——每个坐标-值对都可被击中。
function greedy(targets)
    p = Dict{Tuple{Int,Int},Int}()
    for ((α, ξ), b) in targets
        if !haskey(p, (α, ξ)); p[(α, ξ)] = b; end
    end
    p
end

targets = [((α, ξ), b) for α in 0:2, ξ in 0:1, b in 0:1]
g = greedy(targets)
@assert is_cond(g)
@assert g[(0, 0)] == 0                     # b=0 先到先占
@assert all(g[(α, ξ)] == 0 for α in 0:2, ξ in 0:1)   # 每坐标首个值获胜

# ── 四、定向下界（引理 2.6 大拿/master condition 影子）──
# 定向族：两两有公共延展 ⟹ 并是下界。有限层两两相容即定向。
D = [Dict((0,0)=>1), Dict((1,1)=>0), Dict((0,0)=>1, (1,1)=>0)]
@assert all(agree(D[i], D[j]) for i in 1:3, j in 1:3)
master = merge(merge(D[1], D[2]), D[3])
@assert extC(D[1], master) && extC(D[2], master) && extC(D[3], master)
@assert is_cond(master)

println("Julia：偏序律（自反/传递）、Easton 支撑正反样本、贪心相遇、")
println("定向族的并是下界（大拿影子）——合并=下确界")
println("END ====")
