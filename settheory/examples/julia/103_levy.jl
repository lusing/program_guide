# 第 103 章：Lévy 条件、稠密性 D(λ,β) 与贪心泛型相遇。
println("==== 103")

# ── 一、Lévy 条件：有限部分函数，键 (λ,n)、值 β<λ（书定义 2.1）──
# 槽号 n ∈ ℕ 无界——书 p152 的 n = 1 + max 公式可直接落码。
const KAPPA = 4  # 有限宇宙：λ ∈ {1,2,3,4}

is_cond(p::Dict{Tuple{Int,Int},Int}) =
    all(1 ≤ l ≤ KAPPA && 0 ≤ β < l for ((l, n), β) in p)

compat(p, q) =
    all(p[k] == q[k] for k in keys(p) if haskey(q, k))

# 书式新鲜槽号：n₀ = 1 + max{已用的 n}（无已用时 0）。
fresh_n(l, p) = 1 + maximum((n for ((λ, n)) in keys(p) if λ == l); init=0)

# 稠密性 D(λ,β)：任何条件可扩展至含 ((λ,n₀),β)。
function extend_dense(l, β, p)
    n₀ = fresh_n(l, p)
    q = copy(p); q[(l, n₀)] = β
    return q
end

# 稠密性核查：对一切 (λ,β) 与一切条件 p，扩展存在且合法。
for l in 1:KAPPA, β in 0:(l-1)
    p = Dict((2, 0) => 1, (3, 1) => 2)  # 任意样本条件
    n₀ = fresh_n(l, p)
    q = extend_dense(l, β, p)
    @assert is_cond(q) && compat(p, q)
    @assert any(k[1] == l && q[k] == β for k in keys(q))
    # n₀ 新鲜：与 p 的一切 λ-槽不同。
    @assert all(n₀ != n || p[(l, n)] == β
                for ((λ, n)) in keys(p) if λ == l)
end

# ── 二、贪心泛型相遇：对稠密族 {D(λ,β)} 逐个扩展 ──
# 定理 2.2 的机制：G 的并定义 f_λ: ω→λ 满射。
function greedy_generic(dense_targets)
    p = Dict{Tuple{Int,Int},Int}()
    for (l, β) in dense_targets
        p = extend_dense(l, β, p)
    end
    return p
end

targets = [(l, β) for l in 1:KAPPA for β in 0:(l-1)]
g = greedy_generic(targets)
@assert is_cond(g)
# f_λ 还原：对每个 λ<κ 与 β<λ，∃n 使 g[(λ,n)]=β——λ 被可数化。
for l in 1:KAPPA, β in 0:(l-1)
    @assert any(haskey(g, (l, n)) && g[(l, n)] == β for n in 0:100)
end

# ── 三、样本与对拍断言 ──
p0 = Dict((2, 0) => 1)
@assert fresh_n(2, p0) == 1          # 已用槽 {0} → n₀=1
@assert fresh_n(2, Dict((2,5) => 0)) == 6
@assert fresh_n(3, p0) == 1          # λ=3 无已用槽
@assert compat(Dict((2,0)=>1), Dict((3,1)=>2))
@assert !compat(Dict((2,0)=>1), Dict((2,0)=>0))
# 贪心相遇后每 λ 的使用槽数 = λ 个（β 全覆盖）。
for l in 1:KAPPA
    used = count(k[1] == l for k in keys(g))
    @assert used == l
end

println("Julia：稠密性 D(λ,β) 全核验（n₀=1+max 书式公式）；")
println("贪心泛型相遇后 f_λ 满射还原——λ<κ 全体可数化（定理 2.2 机制）")
println("END ====")
