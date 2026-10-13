# 第 13 章 AC 与 GCH 在 L：<_L 典范良序的实现与 GCH 数值叙事
#
# 1. <_L 的构造序比较器：每个 L 的元素携带（层号， Gödel 分解）
#    的出生证——字典序给出全序；
# 2. GCH 在 L 的组合学叙事：|L_γ| = |γ| 的增长控制。

println("==== 13 AC 与 GCH 在 L：<_L 与增长控制")

# ---------- 一、L 的出生证记录（12 章 def 引擎的扩展） ----------

"规范化集合串（与 12 章同构）"
function norm_set(members::Vector{String})
    uniq = sort(unique(members), by = s -> (length(s), s))
    return "{" * join(uniq, ",") * "}"
end

function parse_members(s::String)
    inner = s[2:end-1]
    (isempty(inner)) && return String[]
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

# 出生证：层号 birth[set] = 首次进入的 L_n
# 构造序 <_L：先比层号，同层比（构造分解的）字典序
function build_L_with_birth(maxlayer::Int)
    birth = Dict{String,Int}()
    birth["{}"] = 0
    current = ["{}"]
    for n in 1:maxlayer
        next = String[]
        for x in current, y in current
            c = norm_set([x, y])
            if !haskey(birth, c)
                birth[c] = n
                push!(next, c)
            end
        end
        append!(current, next)
    end
    return birth
end

birth = build_L_with_birth(3)
println("出生证样本：")
for (s, n) in sort(collect(birth), by=kv->(kv[2], length(kv[1]), kv[1]))[1:min(6,end)]
    println("  $(s)：层 $(n)")
end
@assert birth["{}"] == 0
@assert birth["{{}}"] == 1
@assert birth["{{},{{}}}"] == 2

# <_L 比较器：层号字典序
less_L(a, b) = (birth[a], length(a), a) < (birth[b], length(b), b)
println("\n<_L 比较：{} < {{}} < {{},{{}}}}",
        "（层号 0<1<2 ✓）")
@assert less_L("{}", "{{}}")
@assert less_L("{{}}", "{{},{{}}}")

# ---------- 二、GCH 在 L 的组合学（增长控制） ----------

println("\n|L_γ| = |γ| 的增长控制（定理 34 的引擎）：")
println("  |L_{α+1}| = |def(L_α)| ≤ |α|·ℵ₀ = |α|（公式数封顶）")
println("  极限层：|L_λ| = sup = |λ|")
println("  ⟹ 对一切 γ：|L_γ| ≤ |γ|（+α ⊆ L_α 给 ≥）")
println("\n引理 13.1（Condensation）：X ⊆ ω_α ⟹ X ∈ L_γ（γ < ω_{α+1}）")
println("  证明链：反射选可数充分 M ∋ X, ω_α → Mostowski 坍缩 M ≅ N")
println("  → 绝对性（引理 13.2）N = L_γ（γ 可数）→ X ∈ L_γ")
println("\n合流：P(ω_α) ⊆ L_{ω_{α+1}} ⟹ 2^{ℵ_α} ≤ ℵ_{α+1}；")
println("      Cantor ⟹ ≥；于是 2^{ℵ_α} = ℵ_{α+1}（GCH 在 L）∎")
println("\n数值对照（有限层的『每步封顶』）：")
println("  V 增长：1 → 2 → 4 → 16 → 65536 → 2^65536（幂集全取）")
println("  L 增长：1 → 2 → 4 → 16 → …（同 V 到 ω 层）")
println("  ω+1 层：V 取全部子集（2^ℵ₀）而 L 只取可定义子集（ℵ₀）")
println("  ——GCH 的全部秘密：定义性封顶。")

println("END ====")
