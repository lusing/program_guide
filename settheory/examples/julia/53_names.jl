# 第 53 章 名字实验室：V^B 的有限化身（B = 钻石代数）

println("==== 53")

# ---------- 钻石代数 ----------
dmeet(a, b) = a == d0 || b == d0 ? d0 :
              a == d1 ? b : b == d1 ? a :
              a == b ? a : d0
djoin(a, b) = a == d1 || b == d1 ? d1 :
              a == d0 ? b : b == d0 ? a :
              a == b ? a : d1
const d0, du, dv, d1 = :d0, :du, :dv, :d1

# ---------- 两层名字宇宙 ----------
# 层 0：空名；层 1：{∅ × b}（单标签）；层 2：挂层 1 名字
# 名字 = [(子名, 标签); ...]
N0 = Vector{Tuple{Any,Symbol}}[]
# 层 1：每个标签 b 挂一个名字
layer1 = []
for b in (d0, du, dv, d1)
    push!(layer1, [((), b)])          # () 表示空子名
end
push!(layer1, [])                     # 空名
# 层 2：单挂层 1 元素 × 标签
layer2 = []
for σ in layer1, b in (d0, du, dv, d1)
    push!(layer2, vcat(σ, [((), b)])) # 拼接
end
push!(layer2, [])
println("名字宇宙：|M^B_1| = $(length(layer1)), |M^B_2| = $(length(layer2))")

# ---------- ⟦τ ∈ σ⟧ 与 ⟦τ = σ⟧（单标签直译） ----------
# 在本 toy 中：名字 τ = [((), b_1);...;((), b_k)]
# ⟦τ = σ⟧ 的简化：标签多重集的逐点 iff（toy 语义）
function eqv(τ, σ)
    # 层 1 单标签比较（取首标签）
    b1 = isempty(τ) ? d0 : τ[1][2]
    b2 = isempty(σ) ? d0 : σ[1][2]
    djoin(dmeet(b1, b2), dmeet(dnot(b1), dnot(b2)))
end
dnot(a) = a == d0 ? d1 : a == d1 ? d0 : a == du ? dv : du

# ⟦τ ∈ σ⟧ = ⋁_{ξ∈dom σ} σ(ξ) ∧ ⟦τ = ξ⟧（单标签版）
function memv(τ, σ)
    isempty(σ) && return d0
    b2 = σ[1][2]
    dmeet(b2, eqv(τ, [((), b2)]))
end

# 检查：tagged du = tagged du 的真值为 1
t_du = [((), du)]
@assert eqv(t_du, t_du) == d1
println("⟦tagged du = tagged du⟧ = 1 ✓")
# tagged du ≠ tagged dv
t_dv = [((), dv)]
@assert eqv(t_du, t_dv) == d0
println("⟦tagged du = tagged dv⟧ = 0（du ⊥ dv）✓")
# ∈ 自反样例
@assert memv(t_du, t_du) == du
println("⟦tagged du ∈ tagged du⟧ = du ∧ 1 = du ✓")

# ---------- 混合拼装（Lemma 7.1.31 的单标签版） ----------
# 反链 {du, dv}；τ(t) := (du ∧ a_u(t)) ∨ (dv ∧ a_v(t))
function mix(a_u, a_v)
    b_u = a_u[1][2]; b_v = a_v[1][2]
    djoin(dmeet(du, b_u), dmeet(dv, b_v))
end
# 验证：mix(tagged du, tagged dv) = du ⊔ dv = d1（在 du 上=du，dv 上=dv）
m = mix(t_du, t_dv)
@assert m == djoin(du, dv) == d1
println("混合拼装：du∧du ∨ dv∧dv = du ⊔ dv = d1 ✓")
println("  （τ 在 du 分量上是 a_u、dv 分量上是 a_v——Lemma 7.1.31 单标签版）")

# ---------- G-读出（两个超滤） ----------
valG(τ, G) = [b for (_, b) in τ if b in G]
G_u = [du, d1]; G_v = [dv, d1]
τ2 = [((), du), ((), dv)]   # 双标签名
println("双标签名 τ 的读出：G_u 读出 $(valG(τ2, G_u))，G_v 读出 $(valG(τ2, G_v))")
@assert valG(τ2, G_u) == [du] && valG(τ2, G_v) == [dv]
println("——同一名字、不同 G、不同集合：泛型多读性的最小剧场 ✓")

println("END ====")
