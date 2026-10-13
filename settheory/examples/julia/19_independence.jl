# 第 19 章 CH 与 AC 独立性：泛型实数族与 ccc
println("==== 19 CH 独立性")

# ---------- 一、Cohen 泛型实数族的生成 ----------

"""Fn(κ×ω, 2) 偏序上的条件：dom 有限 ⊆ κ×ω 的 0/1 函数"""
struct Cond
    dom::Vector{Tuple{Int,Int}}
    val::Vector{Bool}
end

is_stronger(p::Cond, q::Cond) = issubset(Set(q.dom), Set(p.dom))
compatible(p::Cond, q::Cond) = all(
    !((i,j) in Set(p.dom) && (i,j) in Set(q.dom)) ||
    p.val[findfirst(==((i,j)), p.dom)] == q.val[findfirst(==((i,j)), q.dom)]
    for (i,j) in Set(p.dom) ∩ Set(q.dom))

# ---------- 二、ccc 的数值验证（有限域上） ----------

"""有限偏序上最大不相容族的大小"""
function max_antichain(conditions::Vector{Cond})
    max_size = 0
    for n in 1:length(conditions)
        for combo in combinations(conditions, n)
            all(compatible(p,q) == false for p in combo for q in combo if p != q) && (max_size = max(max_size, n))
        end
    end
    return max_size
end

conds = [Cond([(i,j)], [b]) for i in 0:3, j in 0:2, b in [false, true]]
println("  Fn(4×3, 2) 上的条件数 = ", length(conds))
println("  条件 p 和 ¬p 不相容 ✓（同一域点不同值）")
p1 = Cond([(0,0)], [true])
p2 = Cond([(0,0)], [false])
@assert !compatible(p1, p2)
p3 = Cond([(0,1)], [true])
@assert compatible(p1, p3)
println("  不同域点的条件相容 ✓")
println("  ccc：有限域上任何不相容族有界（引理 19.3 的骨架）")

# ---------- 三、泛型实数的两两不同性 ----------

println("\n  泛型实数 a_α = {n : ⋃G(α,n)=1}（α < κ）")
println("  a_α ≠ a_β 当 α≠β：D={p : p(α,n)≠p(β,n) 某处} 稠密 ⟹ G∩D≠∅")
println("  ⟹ 2^ℵ₀ ≥ κ（当 κ=ω₂ 给 ¬CH）")

println("END ====")
