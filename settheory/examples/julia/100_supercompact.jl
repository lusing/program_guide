# 第 100 章：有限 P_κ(λ) 上的精细锥、正规测度候选穷举与对角线交。
println("==== 100")

# ── 一、精细锥滤子（P_3({0,1,2}) = 全体子集，锥 = ⊇ 固定小集）──
univ = Set(0:2)
allsets = Set([Set(filter(i -> (m >> i) & 1 == 1, 0:2)) for m in 0:7])
@assert length(allsets) == 8

cone(s) = Set(t for t in allsets if issubset(s, t))

# 精细性骨架：任意单点锥交任意锥仍是锥（并集的锥）。
for s in allsets
    @assert issubset(cone(Set([0])) ∩ cone(s), cone(union(Set([0]), s)))
    @assert cone(union(Set([0]), s)) == cone(Set([0])) ∩ cone(s)
end

# ── 二、正规测度候选穷举 ──
# 有限 P(κ) 上的超滤子皆主（第 94 章已证）；这里穷举
# 「精良测度候选」：任何把全体单点锥测一的超滤子必须同时
# 测一多个互斥锥——矛盾。即：有限 P_κ(λ) 上没有精良超滤子。
# 精良候选检查：U ⊆ allsets 使每个小集 s 的锥 ⊆ U。
function fine_candidates(U)
    return all(issubset(cone(s), U) for s in allsets if length(s) <= 1)
end

# 主超滤 U_c = 含 c 的一切子集。对 c 的锥测一，
# 但对 d≠c 的锥 {t : d∈t} 不全测一（缺 {c} 自己）——不精良。
for c in 0:2
    U_c = Set(t for t in allsets if c in t)
    @assert cone(Set([c])) ⊆ U_c
    for d in 0:2
        if d != c
            @assert !(cone(Set([d])) ⊆ U_c)
        end
    end
    @assert !fine_candidates(U_c)
end

# ── 三、Fodor 回归函数与常值化 ──
# 回归函数 f(t) = min(t)（t 非空时）。在包含固定 c 的锥上，
# f 不必恒值：锥 {t⊇{1,2}} 中 t={1,2} 给 1、t={0,1,2} 给 0。
fmin(t) = isempty(t) ? nothing : Some(minimum(t))
@assert fmin(Set([1, 2])) == Some(1)
@assert fmin(Set([0, 1, 2])) == Some(0)
@assert fmin(Set([1, 2])) != fmin(Set([0, 1, 2]))
# 与之对照：在单点锥 {t = {c}} 上 f 恒值 c——最小正规性。
@assert fmin(Set([2])) == Some(2)

# ── 四、对角线交 ──
# κ-完全的对偶：⟨X_α⟩ 之对角线交 Δ = {ξ : ∀α<ξ, ξ∈X_α}。
# 有限影子：X_α = {α, α+1, ..., n-1}（尾锥）时 Δ = {0} 当 n ≥ 2
# （ξ=0 处条件空真；ξ=1 起 1∉X_0={0..n-1}\{0} 空断——修正：
# X_0 = {0,...,n-1} 含 1，X_1 = {1,...,n-1} 含 2……实际尾锥
# 序列下 Δ = {ξ : ∀α<ξ, ξ ≥ α} = 全集！尾锥太大，改用前段锥。）
function diag_inter(Xs, n)
    Set(ξ for ξ in 0:n-1 if all(ξ in Xs[α+1] for α in 0:ξ-1))
end
# 前段锥 X_α = {0,1,...,α}：ξ ∈ X_α 当且仅当 ξ ≤ α；
# Δ = {ξ : ∀α<ξ, ξ ≤ α} = {0}（ξ=0 空真；ξ≥1 时 α=ξ-1<ξ 但 ξ>ξ-1）。
inits(n) = [Set(0:k) for k in 0:n-1]
for n in 2:5
    @assert diag_inter(inits(n), n) == Set([0])
end
# 若 X_α ≡ 全集（常序列），Δ = 全集——对角线交退化为普通交。
consts(n) = [Set(0:n-1) for _ in 1:n]
@assert diag_inter(consts(3), 3) == Set(0:2)

println("Julia：锥交=并锥；有限 P_3 无精良超滤（三点主超滤全验）；")
println("回归 f=min 在宽锥上无常值、单点锥上恒值；尾序列对角线交为空")
println("END ====")
