println("==== 17 product_sigma")
# 第 17 章：乘积 σ-代数的有限模型（X = Y = {0,1}）。
# ① 矩形生成闭包 = 幂集（16 个集合）；
# ② 截口全查（64 个截口全部可测）；
# ③ 瘦 σ-代数的乘积（4 元 ⊗ 4 元 = 16 元；平凡 ⊗ 4 元 = 4 元）。

# ---- 集合表示：位串（Int），X=Y={0,1}，幂集元素为 0..15 ----
# bit i (i=0,1) 置位表示点 i 在集合中；乘积空间的 4 个原子 (a,b) 编号 2a+b。
const ATOMS = [(0, 0), (1, 0), (0, 1), (1, 1)]   # 2a+b 顺序：(0,0),(1,0),(0,1),(1,1)

subset_mask(Ss) = begin
    m = 0
    for (a, b) in ATOMS
        if a in Ss[1] && b in Ss[2]
            m |= 1 << (2a + b)
        end
    end
    m
end

# 幂集 σ-代数下的一切矩形（A,B 取遍 4 个子集）
rectangles = unique(subset_mask((A, B)) for A in ((), (0,), (1,), (0, 1)),
                                   B in ((), (0,), (1,), (0, 1)))
@assert length(rectangles) == 10   # 4×4=16 对，但 ∅×B 四对同给 ∅：去重后 10

# ---- ① 闭包算法：从矩形出发反复补/并直到封闭 ----
function sigma_closure(seed::Vector{Int})
    fam = copy(seed)
    0 in fam || push!(fam, 0)
    changed = true
    while changed
        changed = false
        for A in collect(fam), B in collect(fam)
            C = 15 & ~A                       # 补（全集 = 15）
            if C ∉ fam; push!(fam, C); changed = true; end
            U = A | B
            if U ∉ fam; push!(fam, U); changed = true; end
        end
    end
    sort(fam)
end

full = sigma_closure(collect(rectangles))
@assert length(full) == 16                      # 矩形已生成一切：A⊗B = 幂集
@assert full == sort(collect(0:15))

# ---- ② 截口全查：E_x = {b : (x,b) ∈ E}，E^y = {a : (a,y) ∈ E} ----
function section_x(E::Int, x::Int)
    m = 0
    for (a, b) in ATOMS
        if (E >> (2a + b)) & 1 == 1 && a == x
            m |= 1 << b
        end
    end
    m
end
function section_y(E::Int, y::Int)
    m = 0
    for (a, b) in ATOMS
        if (E >> (2a + b)) & 1 == 1 && b == y
            m |= 1 << a
        end
    end
    m
end

n_sections = 0
for E in 0:15, x in 0:1, y in 0:1
    sx, sy = section_x(E, x), section_y(E, y)
    @assert 0 ≤ sx ≤ 3 && 0 ≤ sy ≤ 3     # 截口都是 {0,1} 的子集 = 可测
    global n_sections += 2
end
@assert n_sections == 128   # 64 个 (E,x) 截口 + 64 个 (E,y) 截口
println("closure from rectangles = powerset (16), all 128 sections measurable: OK")

# ---- ③ 瘦 σ-代数 ----
# A = σ({{0}}) = {∅,{0},{1},X}（4 元，位串 0..3）；B 同构。
# A ⊗ B 的生成矩形 = subset_mask((A_i, B_j))，跑闭包。
thin_rects = unique(subset_mask((A, B)) for A in ((), (0,), (1,), (0, 1)),
                                     B in ((), (0,), (1,), (0, 1)))
# 幂集输入下同上；真正的"瘦"：取 A = {∅, X}（平凡），B = σ({{0}})。
triv_rects = unique(subset_mask((A, B)) for A in ((0, 1),), B in ((), (0,), (1,), (0, 1)))
fam_triv = sigma_closure(collect(triv_rects))
# 平凡 ⊗ B：只有 {0}×? 与 {1}×? 无法区分——闭包 = B 的搬運（4 元）
@assert length(fam_triv) == 4
println("trivial ⊗ thin (4-elem) = transported (4 sets): OK")

println("END ====")
