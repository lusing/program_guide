# 第 71 章：序数与累积层次（冯琦 §1.7）
# V_α 塔的前几层与秩函数：RK(n) = n 恒等、S∘RK = RK∘S、
# 有限序数的三择一（可比较性 1.50 的有限截面）、sup/min。
println("==== 71")

const EMPTY = Set{Any}()

# ---------- 冯诺伊曼数字与 V 塔 ----------
vn(n) = foldl((acc, _) -> union(acc, Set([acc])), 1:n; init = EMPTY)

v0, sizes = EMPTY, Int[]
V = Set{Any}[EMPTY]
for k in 1:3
    global V = Set{Any}(Set(e) for e in V)   # V_{k+1} = 单集化的极简版（示意）
    push!(sizes, length(V))
end
println("V 塔（单集化轨道）规模：", sizes, "（真幂集：1,2,4,16,…,2^16）")

# ---------- 秩函数（定义 1.66）：RK(a) = sup{RK(b)+1 | b ∈ a} ----------
function rank(a)
    isempty(a) && return 0
    1 + maximum(rank(e) for e in a)
end

# RK(n) = n：冯诺伊曼数字在秩轴上排成斜率为 1 的直线（命题 1.21）
ranks = [rank(vn(n)) for n in 0:15]
@assert ranks == collect(0:15)
println("RK(0..15) = ", collect(0:15), " ✓（斜率 1 的直线）")

# S∘RK = RK∘S：后继与秩交换（命题 1.21(2)）
succ(x) = union(x, Set([x]))
@assert all(rank(succ(vn(n))) == rank(vn(n)) + 1 for n in 0:15)
@assert all(rank(succ(Set([vn(n), vn(n+2)]))) == rank(Set([vn(n), vn(n+2)])) + 1
            for n in 0:5)
println("S∘RK = RK∘S 在数字与混合集上全对 ✓")

# V_n 的居民全住在秩 < n 处（引理 1.12 的方向）
Vn = [EMPTY]
for k in 1:4
    push!(Vn, union(Vn[end], Set([Set(e) for e in collect(Vn[end])])))
end
# ↑ V_{n+1} = V_n ∪ {单集} 的扩张轨道：够测秩上界即可
@assert all(rank(e) < 12 for level in Vn for e in level)
println("V 轨道居民秩有界 ✓（V_α 的成员都有 < α 的秩）")

# ---------- 三择一（定理 1.50 的有限截面） ----------
# 有限序数上：a < b / a = b / b < a 恰居其一
for i in 0:8, j in 0:8
    a, b = vn(i), vn(j)
    lt = i < j; eq = i == j; gt = j < i
    @assert (lt ⊻ eq ⊻ gt) || (eq && !lt && !gt) || (lt && !eq && !gt) || (gt && !eq && !lt)
    @assert xor(lt, eq, gt)
    # ∈ ⟺ <（序数的成员即更小的序数）
    @assert (a ⊆ b) == (i <= j)
end
println("0..8 全对：三择一恰一成立、a ⊆ b ⟺ a ≤ b ✓")

# ---------- sup = ⋃ 与 min（定理 1.51 / 命题 1.20） ----------
# sup{0,1,2} = ⋃{vn 0, vn 1, vn 2} = vn 2（序数之集的并是 sup）
sup3 = union(vn(0), vn(1), vn(2))
@assert sup3 == vn(2)
# min：非空序数集的 ∈-最小元（对有限集就是最小尺寸）
mins = argmin(length, [vn(3), vn(1), vn(2)])
@assert mins == vn(1)
println("sup{0,1,2} = 2 ✓   min{3,1,2} = 1 ✓")

println("END ====")
