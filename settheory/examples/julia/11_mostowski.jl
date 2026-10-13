# 第 11 章 传递模型：Mostowski 坍缩计算器与反射层数值演示
#
# 1. 有限良基外延图的坍缩 π(x) = {π(z) : z E x}——图读成集合；
# 2. 反射原理（定理 29）的数值侧影：对"有限宇宙" V_n 找
#    反射简单公式的层级。

println("==== 11 传递模型：坍缩与反射")

# ---------- 一、Mostowski 坍缩计算器 ----------

"""坍缩：外延良基图（邻接表 ext）→ 嵌套集合编码。
结果用规范化字符串表示（嵌套 {}）。"""
function mostowski(ext::Dict{Int,Vector{Int}}, x::Int)
    inner = sort(unique(ext[x]))
    return "{" * join((mostowski(ext, z) for z in inner), ",") * "}"
end

# 例 1：von Neumann 链 0∈1∈2（ext: 1↦{0}, 2↦{0,1}）
ext1 = Dict(0 => Int[], 1 => [0], 2 => [0, 1])
for x in 0:2
    println("  π($x) = ", mostowski(ext1, x))
end
@assert mostowski(ext1, 2) == "{{},{{}}}"
println("  ——图 0∈1∈2 坍缩成 von Neumann 数 2 ✓")

# 例 2：非传递的外延结构坍缩成传递的
# 3 ↦ {0}，其中 0 无前驱（∅）
ext2 = Dict(0 => Int[], 3 => [0])
println("\n  π(3) = ", mostowski(ext2, 3), "（{∅}——3 被改名为 1）")
@assert mostowski(ext2, 3) == "{{}}"

# ---------- 二、外延性检查（坍缩的先决条件） ----------

"""外延性：ext(x) 决定 x（不同点的坍缩不同）"""
function is_extensional(ext::Dict{Int,Vector{Int}})
    seen = Dict{String,Int}()
    for x in keys(ext)
        key = mostowski(ext, x)
        if haskey(seen, key)
            seen[key] != x && return false   # 两点同坍缩
        end
        seen[key] = x
    end
    return true
end

@assert is_extensional(ext1)
println("\n  链图外延 ✓（坍缩是单射，Mostowski 的唯一性）")

# 非外延例：两点 ext 都空（坍缩同为 ∅）
ext_bad = Dict(0 => Int[], 1 => Int[])
@assert !is_extensional(ext_bad)
println("  双空点非外延（0 与 1 无法区分——坍缩失败先决条件）")

# ---------- 三、反射原理的数值侧影 ----------

println("\n反射原理（定理 29）的数值侧影：")
println("  对公式 φ，存在 V_α 反射 φ（V_α ⊨ φ[a] ⟺ φ[a]）")
println("  ——有限宇宙里：简单公式（如 '∃y (x ∈ y)'）在足够的")
println("    V_n 上内部/外部求值一致。")
println("  推论：ZF 不可有限公理化（反射给有限定理集以集合模型，")
println("        而'ZF 有模型'不可证——Gödel 第二不完备）。")

println("END ====")
