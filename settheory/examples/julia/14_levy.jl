# 第 14 章 Lévy 层级：量词前缀的层级判定器
#
# 公式的量词形状 → Σₙ/Πₙ 标签；封闭规则的运算验证。

println("==== 14 Lévy 层级：判定器")

# ---------- 一、层级标签与运算 ----------

abstract type Lev end
struct L0 <: Lev end                       # 受限
struct Sg <: Lev; n::Int; end
struct Pi_ <: Lev; n::Int; end

dual(::L0) = L0()
dual(s::Sg) = Pi_(s.n)
dual(p::Pi_) = Sg(p.n)

ex_over(::L0) = Sg(1)                      # 受限上 ∃ → Σ₁
ex_over(s::Sg) = s                         # Σₙ 上 ∃ 同层吸收
ex_over(p::Pi_) = Sg(p.n + 1)              # Πₙ 上 ∃ 升层

all_over(l) = dual(ex_over(dual(l)))       # 全称 = 对偶

println("dual(dual(Σ₃)) = Σ₃：", dual(dual(Sg(3))) isa Sg && dual(dual(Sg(3))).n == 3)
@assert dual(dual(Sg(3))).n == 3
println("∃ over Π₂ = ", "Σ", ex_over(Pi_(2)).n)
@assert ex_over(Pi_(2)) == Sg(3)
println("∀ over Σ₂ = Π", all_over(Sg(2)).n)
@assert all_over(Sg(2)) == Pi_(3)
println("∀ over Πₙ = Πₙ（同层吸收）")
@assert all_over(Pi_(5)) == Pi_(5)

# ---------- 二、公式的层级计算（量词链解析） ----------

"""公式的量词前缀（如 [:ex,:all,:ex] + :qf）→ 层级标签"""
function level(qs::Vector{Symbol})
    isempty(qs) && return L0()
    # 压缩相邻同型 + 计算交替深度
    n = 1
    for i in 2:length(qs)
        qs[i] != qs[i-1] && (n += 1)
    end
    return qs[1] == :ex ? Sg(n) : Pi_(n)
end

println("\n公式层级示例：")
for (name, qs) in [("受限（无量词）", Symbol[]),
                   ("∃x ψ₀", [:ex]),
                   ("∀x ∃y ψ₀", [:all, :ex]),
                   ("∃x ∀y ∃z ψ₀", [:ex, :all, :ex])]
    l = level(qs)
    tag = l isa L0 ? "Δ₀" : l isa Sg ? "Σ$(l.n)" : "Π$(l.n)"
    println("  $name → $tag")
end
@assert level([:ex, :all, :ex]) == Sg(3)
@assert level([:all, :ex]) == Pi_(2)

println("\n地位表（绝对性）：Δ₁ 双向（∈/序数/良基/Gödel 运算）；")
println("Σ₁ 上（可数/|X|≤|Y|）；Π₁ 下非Σ₁（基数/正则/P(X)）。")

println("END ====")
