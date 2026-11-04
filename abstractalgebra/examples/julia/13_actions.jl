# 第 13 章 · 群作用 —— Julia 通道
#
# 轨道/稳定子/类方程 + 共轭类=中心化子指数 + S₄ 循环结构类 + 项链双验证。

println("==== 13 群作用")

# ---------- 置换件 ----------
function all_perms(n::Int)
    out = Vector{Int}[]; p = collect(1:n)
    while true
        push!(out, copy(p))
        k = 0
        for i in n-1:-1:1
            if p[i] < p[i+1]; k = i; break; end
        end
        k == 0 && break
        l = 0
        for j in n:-1:1
            if p[k] < p[j]; l = j; break; end
        end
        p[k], p[l] = p[l], p[k]
        reverse!(p, k + 1)
    end
    out
end
compose(α, β) = [α[β[i]] for i in eachindex(β)]
perminv(α) = begin r = similar(α); for (i, ai) in enumerate(α); r[ai] = i; end; r end

s3_img = [[1,2,3],[2,3,1],[3,1,2],[2,1,3],[3,2,1],[1,3,2]]
s3_tbl = [findfirst(p -> p == [s3_img[a][s3_img[b][j]] for j in 1:3], s3_img)
          for a in 1:6, b in 1:6]
function dihedral_tbl(n)
    tbl = zeros(Int, 2n, 2n)
    for i in 0:n-1, j in 0:1, k in 0:n-1, l in 0:1
        r, s = j == 0 ? (mod(i + k, n), l) : (mod(i - k, n), 1 - l)
        tbl[(j == 0 ? i + 1 : n + i + 1), (l == 0 ? k + 1 : n + k + 1)] =
            s == 0 ? r + 1 : n + r + 1
    end
    tbl
end

# ---------- 轨道与稳定子（作用 = 表左乘） ----------
function orbit(tbl, x)
    S = Set([x])
    for g in 1:size(tbl, 1), y in collect(S)
        push!(S, tbl[g, y])
    end
    S
end
stabilizer(tbl, x) = [g for g in 1:size(tbl, 1) if tbl[g, x] == x]

# 正则作用（G 作用在自身）：轨道全 G，稳定子 {1}
d4 = dihedral_tbl(4)
@assert orbit(d4, 1) == Set(1:8)
@assert stabilizer(d4, 1) == [1]
println("左正则作用（凯莱定理 2.130 的作用版）：轨道 = 全群，稳定子 = {1} ✓")

# 轨道-稳定子（定理 2.141）：对左乘作用逐点核验
for tbl in (s3_tbl, d4), x in 1:size(tbl, 1)
    @assert length(orbit(tbl, x)) * length(stabilizer(tbl, x)) == size(tbl, 1)
end
println("定理 2.141（|O|·|G_x| = |G|）：S₃ 与 D₄ 的左乘作用逐点成立 ✓")

# ---------- 共轭作用：类方程（D₄） ----------
"""共轭类：{g x g⁻¹ : g ∈ G}（表上实现）。"""
function conjugacy_class(tbl, x)
    S = Set{Int}()
    for g in 1:size(tbl, 1)
        ginv = findfirst(y -> tbl[g, y] == 1, 1:size(tbl, 1))
        push!(S, tbl[tbl[g, x], ginv])
    end
    S
end
center(tbl) = [x for x in 1:size(tbl, 1)
               if all(g -> tbl[tbl[g, x], findfirst(y -> tbl[g, y] == 1, 1:size(tbl,1))] == x,
                      1:size(tbl, 1))]
centerizer(tbl, x) = [g for g in 1:size(tbl, 1)
                      if tbl[tbl[g, x], findfirst(y -> tbl[g, y] == 1, 1:size(tbl,1))] == x]

classes_d4 = unique(Set.(conjugacy_class.(Ref(d4), 1:8)))
@assert sort(length.(classes_d4)) == [1, 1, 2, 2, 2] "D₄ 类方程 8 = 2 + 2+2+2"
@assert length(center(d4)) == 2                      # Z(D₄) = {1, α²}
# 推论 2.143：共轭类大小 = 群阶/中心化子
for x in 1:8
    @assert length(conjugacy_class(d4, x)) * length(centerizer(d4, x)) == 8
end
println("类方程（D₄）：|D₄| = 8 = 2（中心）+ 2+2+2；共轭类 = 群阶/中心化子 ✓")

# ---------- S₄ 循环结构类大小（推论 2.144） ----------
cycles(α) = begin
    n = length(α); seen = falses(n); out = Int[]
    for i in 1:n
        (seen[i] || α[i] == i) && continue
        c = 0; j = i
        while !seen[j]; seen[j] = true; c += 1; j = α[j]; end
        push!(out, c)
    end
    sort(out)
end
struct_sizes = Dict{Vector{Int},Int}()
for α in all_perms(4)
    s = cycles(α)                # 只列长度 ≥ 2 的循环
    struct_sizes[s] = get(struct_sizes, s, 0) + 1
end
@assert struct_sizes[Int[]] == 1          # 恒等（无 ≥2 循环）
@assert struct_sizes[[2]] == 6            # 对换
@assert struct_sizes[[2, 2]] == 3         # 双对换
@assert struct_sizes[[3]] == 8            # 3-循环
@assert struct_sizes[[4]] == 6            # 4-循环
println("S₄ 循环结构类（推论 2.144）：1/6/3/8/6 个，总和 24 ✓")

# ---------- 项链：Burnside 与暴力双跑 ----------
q, n = 2, 6

"""旋转 k 步作用在染色向量上：c'[i] = c[i−k]。"""
rot_action(k, c) = [c[mod1(i - k, n)] for i in 1:n]
"""二面体元素 ρ^k σ 作用：c'[i] = c[n+1+k−i]。"""
dih_action(g, c) = begin
    k = g <= n ? g : g - n                 # g = 1..n 旋转；n+1..2n 反射复合
    g <= n ? rot_action(k, c) : [c[mod1(n + 1 + k - i, n)] for i in 1:n]
end

all_colorings() = ([mod1(d, q) for d in digits(code, base=q, pad=n)]
                   for code in 0:(q^n - 1))

fix_count(action, g) = count(c -> action(g, c) == c, all_colorings())

function brute_orbits(action, Gn)
    seen = Set{Vector{Int}}(); orbits = 0
    for c in all_colorings()
        c in seen && continue
        orbits += 1
        union!(seen, Set([action(g, c) for g in 1:Gn]))
    end
    orbits
end

burn_rot_N = sum(k -> fix_count(rot_action, k), 0:n-1) // n
@assert burn_rot_N == 14
@assert brute_orbits((g, c) -> rot_action(g - 1, c), n) == 14

burn_dih_N = sum(g -> fix_count(dih_action, g), 1:(2n)) // (2n)
@assert burn_dih_N == 13
@assert brute_orbits(dih_action, 2n) == 13
println("2 色 6 珠项链：旋转 Burnside = 14 = 暴力；二面体 13 = 暴力 ✓")

println("END ====")
