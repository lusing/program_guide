# 第 12 章 可构造层级：Gödel 运算引擎与 L_n 的数值生长
#
# 1. 十个 Gödel 运算 F₁-F₁₀（def 闭包的生成元）；
# 2. 有限传递 U 上的 def(U) 计算（受限公式定义的子集枚举）；
# 3. L_n vs V_n 的增长对照（L ⊆ V 且从 ω 层起变瘦）。

println("==== 12 可构造层级：Gödel 运算与 L_n")

using Printf

# ---------- 一、Gödel 运算（集合用规范化字符串表示） ----------

const SetS = String

"规范化集合字符串：成员按 (len, str) 排序去重"
function norm_set(members::Vector{SetS})::SetS
    uniq = sort(unique(members), by = s -> (length(s), s))
    return "{" * join(uniq, ",") * "}"
end

"集合的成员表（解析 '{a,b,...}'）"
function members(s::SetS)::Vector{SetS}
    inner = s[2:end-1]
    (isempty(inner)) && return SetS[]
    # 按顶层逗号切分
    out = String[]; depth = 0; cur = ""
    for c in inner
        c == '{' && (depth += 1)
        c == '}' && (depth -= 1)
        c == ',' && depth == 0 && (push!(out, strip(cur)); cur = ""; continue)
        cur *= c
    end
    push!(out, strip(cur))
    return out
end

# F1-F10 的代表（教学版取最核心的四个 + 讲义）
g_pair(x, y) = norm_set([x, y])
g_union(x) = norm_set(vcat([members(m) for m in members(x)]...))
g_diff(x, y) = norm_set(setdiff(members(x), members(y)))
g_inter(x, y) = norm_set(intersect(members(x), members(y)))

E = "{}"
one = g_pair(E, E)
println("F₁(∅,∅) = ", one, "（{∅}）")
println("⋃{{∅},{{∅}}} = ", g_union("{{},{{}}}"))
println("{∅,{∅}} - {∅} = ", g_diff("{{},{{}}}", "{{}}"))

# ---------- 二、def(U)：受限公式可定义的子集（有限 U 上枚举） ----------

"""对有限传递 U（字符串集合），算 def(U)：
   枚举 U 上的一元受限公式 φ（生成器：原子 x=a、x∈a 的
   布尔组合，a 遍历 U）——每个 φ 给一个子集。"""
function def_finite(U::Vector{SetS})
    # 生成元谓词：u ∈ a（a 固定）与 u = a
    preds = Bool[u == U[1] for u in U] ∨ nothing  # 占位结构见下方实际
    return nothing
end

# 实际版：直接枚举"由原子生成"的子集
function def_finite(U::Vector{SetS})::Vector{SetS}
    n = length(U)
    atoms = Vector{Bool}[]          # 原子谓词的真值向量
    for a in U
        push!(atoms, Bool[(u in members(a)) for u in U])    # u ∈ a
        push!(atoms, Bool[(u == a) for u in U])             # u = a
    end
    # 布尔组合（一层的 and/or/not——教学的有限近似）
    combos = copy(atoms)
    for p in atoms, q in atoms
        push!(combos, p .& q)
        push!(combos, p .| q)
    end
    push!(combos, trues(n))
    allb = unique(combos)
    # 真值向量 → 子集（规范化）
    out = SetS[]
    for v in allb
        sel = norm_set([U[i] for i in 1:n if v[i]])
        isempty(members(sel)) && continue  # ∅ 通常 ∉ def(U) 的非平凡部分
        push!(out, sel)
    end
    return sort(unique(out), by = s -> (length(s), s))
end

# U = V_2 = {∅, {∅}}
V2 = [E, one]
dU = def_finite(V2)
println("\ndef(V₂)：", join(dU, " "))
println("  V₃ = def(V₂) 的成员数 = ", length(dU), "（P(V₂) 有 4 个子集，")
println("  有限层 def = P（习题 12.6），L_n = V_n 直到 ω 层——分歧在无穷处。）")

# ---------- 三、L_n vs V_n 对照表（有限层的数值叙事） ----------

println("\n层级对照（有限层）：")
println("  n : |V_n| : |L_n|")
println("  0 :   0   :   0")
println("  1 :   1   :   1")
println("  2 :   2   :   2")
println("  3 :   4   :   4   （有限层 def=P：L_n = V_n）")
println("  ω :  ℵ₀   :  ℵ₀   （L_ω = V_ω = HF）")
println("  ω+1: 2^ℵ₀ :  ℵ₀   （分歧！def(HF) 只有可数个可定义子集）")
println("  ——L 从 ω+1 层起戏剧性地变瘦：|L_{ω₁}| = ℵ₁ ≤ |V_{ω₁}| = 2^ℵ₀")

println("END ====")
