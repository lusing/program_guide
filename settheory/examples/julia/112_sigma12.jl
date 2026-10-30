# 第 112 章：两层树投影、双模型真值对比与 Sierpiński 分层——Σ¹₂ 的影子。
println("==== 112")

# ── 一、两层树（ω×ω₁ 的替身：路径层 × 序数层，深度 2） ──
# 节点对 (s, h)：s 是实数前段（0/1 位串）、h 是序数值前段（0/1 串）。
const MAXD = 2
take2(v::Vector{Int}, k) = v[1:min(k, end)]
paths2() = [[a, b] for a in 0:1 for b in 0:1]

# 截面：T(α) = {h | (α↾|h|, h) ∈ T}。
sec2(T, α) = begin
    out = Vector{Vector{Int}}()
    for (s, h) in T
        if s == take2(α, length(h))
            push!(out, h)
        end
    end
    out
end

# 截面有全长树枝 ⟺ α ∈ p[T]（Σ¹₂ 经树表示的分支语义）。
sec_has_branch(T, α) = begin
    S = sec2(T, α)
    for g1 in 0:1, g2 in 0:1
        [g1] in S && [g1, g2] in S && return true
    end
    false
end

projection(T) = Set(α for α in paths2() if sec_has_branch(T, α))

# 样本两层树：α=00 有树枝、其余良基。
Tb = Set([
    (Int[], Int[]),
    ([0], [0]), ([0], [1]),
    ([0,0], [0,0]), ([0,0], [1,0]),
])
@assert projection(Tb) == Set([[0,0]])
@assert Set(sec2(Tb, [0,0])) == Set([[], [0], [1], [0,0], [1,0]])
@assert Set(sec2(Tb, [0,1])) == Set([[], [0], [1]])
@assert !sec_has_branch(Tb, [0,1])

# ── 二、双模型真值对比（Shoenfield 绝对性的量词面） ──
# V = 全体路径；M = 首位为 0 的路径（子模型——沿 3.1.2 的传递模型影子）。
const V_all = paths2()
const M_sub = [[0,0], [0,1]]

# Σ₁ 语句：∃y∈universe φ(y)（φ 判定）——上行绝对。
sig1(phi, univ) = any(phi, univ)
# Π₁ 语句：∀y∈universe φ(y)——下行绝对。
pi1(phi, univ) = all(phi, univ)

# 上行：M 真 ⟹ V 真（见证上移）。
for phi in (y -> y[1] == 0, y -> y == [0,0], y -> y[2] == 1)
    if sig1(phi, M_sub)
        @assert sig1(phi, V_all)
    end
end
# 下行反例核查：V 真 ↛ M 真（存在语句不下行）。
phi_out = y -> y[1] == 1
@assert sig1(phi_out, V_all) && !sig1(phi_out, M_sub)

# Π 下行：V 真 ⟹ M 真。
for phi in (y -> y[1] >= 0, y -> length(y) == 2)
    if pi1(phi, V_all)
        @assert pi1(phi, M_sub)
    end
end
# Π 上行反例：M 真 ↛ V 真。
phi_m = y -> y[1] == 0
@assert pi1(phi_m, M_sub) && !pi1(phi_m, V_all)

# ── 三、Sierpiński 分层（定理 3.8：Σ¹₂ = ℵ₁ 个博雷尔集之并） ──
# 有限影子：p[T] = ∪_{ξ<Ω} {α | T(α) 有坐标全 ≤ ξ 的树枝}，
# 每层「坐标有界」=「秩有界」（引理 3.5 的机制件）。
bounded_branch(T, α, ξ) = begin
    S = sec2(T, α)
    for g1 in 0:min(ξ,1), g2 in 0:min(ξ,1)
        [g1] in S && [g1, g2] in S && return true
    end
    false
end

layer(T, ξ) = Set(α for α in paths2() if bounded_branch(T, α, ξ))
Ω = 1   # 序数供给上界（0/1 两层——「ℵ₁」的有限影子）
acc = Set{Vector{Int}}()
for ξ in 0:Ω
    union!(acc, layer(Tb, ξ))
end
@assert acc == projection(Tb)   # 分层并 = 全投影（Sierpiński 账）
@assert layer(Tb, 0) != Set()  # 零层已含 00（坐标全 0 的树枝）

println("Julia：两层树投影（p[Tb]={00}）；Σ 上行/Π 下行 + 双反例；")
println("Sierpiński 分层并 = 全投影（Ω=1 两层账）")
println("END ====")
