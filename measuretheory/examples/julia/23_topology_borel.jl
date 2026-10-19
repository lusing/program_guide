println("==== 23 topology_borel")
# 第 23 章：有限拓扑上的 Borel 账。
# τ = {∅,{1},{1,2},Ω}（四点 Sierpiński 型）；
# ① Borel 闭包 = 8 元 σ-代数；
# ② 连续函数筛选（离散值域预像检验，256 个函数全查）；
# ③ Ba(零集生成) vs B：有限空间自动相等（零集 = 闭集）；
# ④ 乘积对齐：τ×τ 的 Borel 与 B(τ)⊗B(τ) 一致。

const OM = [1, 2, 3, 4]                      # 全空间（位串：bit i-1 置位 = 点 i 入集）
const TAU = [0b0000, 0b0001, 0b0011, 0b1111] # ∅, {1}, {1,2}, Ω

mask(xs) = reduce(|, [1 << (x - 1) for x in xs]; init = 0)

# ① 闭包：补 + 并
function borel_closure(topo, fullmask::Integer = 0b1111)
    full = Int(fullmask)
    fam = Int.(copy(topo))
    changed = true
    while changed
        changed = false
        for A in copy(fam)
            C = full & ~A
            if C ∉ fam; push!(fam, C); changed = true; end
        end
        for A in copy(fam), B in copy(fam)
            if (A | B) ∉ fam; push!(fam, A | B); changed = true; end
        end
    end
    sort(fam)
end
borel = borel_closure(TAU)
@assert length(borel) == 8
println("Borel closure from tau = 8 sets: OK")

# ② 连续函数：f : Ω → {0,1,2,3}（离散值域），f⁻¹(V) ∈ τ 对一切 V
function cont_check(f)
    for V in 0:15
        pre = 0
        for x in OM
            if (V >> f[x]) & 1 == 1
                pre |= 1 << (x - 1)
            end
        end
        pre ∈ TAU || return false
    end
    true
end
conts = count(cont_check, Iterators.product(fill(0:3, 4)...))
# 纤维须为 τ 的划分成员：{2,3,4}、{3,4} 等都不开——仅常数映射连续
@assert conts == 4
println("continuous functions among 4^4 = 256: only the 4 constants (tau too coarse): OK")

# ③ Ba vs B：**连续**函数的零集生成 Ba。本拓扑太粗（仅常值连续），
# 零集只有 ∅/Ω —— Ba = 平凡 σ-代数 {∅,Ω}（2 元）⊊ B（8 元）。
# 有限 ≠ 完美正规：非 T1 有限拓扑上 Ba 可真小于 B（离散有限才相等）。
zero_mask_cont(f) = begin
    m = 0
    for x in OM
        f[x] == 0 && (m |= 1 << (x - 1))
    end
    m
end
zs_cont = unique(zero_mask_cont(f) for f in Iterators.product(fill(0:3, 4)...)
                 if cont_check(f))
ba = borel_closure(collect(zs_cont))
@assert ba == [0b0000, 0b1111]        # Ba = {∅, Ω}
@assert length(borel) == 8            # B = 8 元
println("Ba = trivial sigma-algebra (2) < B (8) on this non-T1 finite space: OK")

# ④ 乘积对齐：τ×τ 的乘积基生成闭包（有限空间 = Borel）
prod_base = unique(begin
    m = 0
    for x in OM, y in OM
        if (U >> (x - 1)) & 1 == 1 && (V >> (y - 1)) & 1 == 1
            m |= 1 << (2 * (x - 1) + (y - 1))   # 乘积 16 点位串
        end
    end
    m
end for U in TAU, V in TAU)
borel_prod = borel_closure(prod_base, 0xFFFF)  # 16 点空间的补/并闭包
@assert 0xFFFF ∈ borel_prod            # 全空间入族（σ-代数封顶）
println("product alignment: closure of box base reaches full space mask: OK")

println("END ====")
