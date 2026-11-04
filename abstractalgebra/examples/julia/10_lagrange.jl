# 第 10 章 · 子群与拉格朗日定理 —— Julia 通道
#
# 子群枚举 + 陪集分解 + 拉格朗日/元素阶/幂回一全量核验 + 循环群子群唯一性。

println("==== 10 子群与拉格朗日定理")

# ---------- 复用第 09 章的构造器与工具（自包含重写） ----------
function is_group(tbl::Matrix{Int})
    n = size(tbl, 1)
    all(x -> 1 <= x <= n, tbl) || return false
    e = findfirst(i -> tbl[i, :] == collect(1:n) && tbl[:, i] == collect(1:n), 1:n)
    isnothing(e) && return false
    all(i -> any(j -> tbl[i, j] == e, 1:n), 1:n) || return false
    all(tbl[tbl[i, j], k] == tbl[i, tbl[j, k]] for i in 1:n, j in 1:n, k in 1:n)
end

identity_of(tbl) = findfirst(i -> tbl[i, :] == collect(1:size(tbl, 1)) &&
                                   tbl[:, i] == collect(1:size(tbl, 1)), 1:size(tbl, 1))

order_of(tbl, x) = begin
    e = identity_of(tbl); k, cur = 1, x
    while cur != e; cur = tbl[x, cur]; k += 1; end; k
end

itpow(tbl, x, k) = begin
    e = identity_of(tbl)
    r = e
    for _ in 1:k; r = tbl[x, r]; end; r
end

zn_add(n) = [mod(i + j, n) + 1 for i in 0:n-1, j in 0:n-1]
function un_mul(m)
    U = [k for k in 1:m if gcd(k, m) == 1]
    idx = Dict(v => i for (i, v) in enumerate(U))
    [idx[mod(U[i] * U[j], m)] for i in eachindex(U), j in eachindex(U)]
end
function dihedral(n)
    tbl = zeros(Int, 2n, 2n)
    for i in 0:n-1, j in 0:1, k in 0:n-1, l in 0:1
        r, s = j == 0 ? (mod(i + k, n), l) : (mod(i - k, n), 1 - l)
        tbl[(j == 0 ? i + 1 : n + i + 1), (l == 0 ? k + 1 : n + k + 1)] =
            s == 0 ? r + 1 : n + r + 1
    end
    tbl
end

# ---------- 子群与陪集 ----------
"""子群判别（命题 2.69 有限版：非空 + 封闭）。"""
is_subgroup(tbl, H) = !isempty(H) && all(tbl[x, y] in H for x in H, y in H)

"""全部子群（枚举幂集后过滤）。"""
function all_subgroups(tbl)
    n = size(tbl, 1)
    out = Vector{Int}[]
    for mask in 0:(2^n - 1)
        H = [i for i in 1:n if (mask >> (i - 1)) & 1 == 1]
        is_subgroup(tbl, H) && push!(out, H)
    end
    sort!(out; by=length)
    out
end

"""左陪集分解。"""
function cosets(tbl, H)
    left = Set{Int}(); blocks = Vector{Vector{Int}}()
    for a in 1:size(tbl, 1)
        a in left && continue
        C = sort([tbl[a, h] for h in H])
        push!(blocks, C)
        union!(left, C)
    end
    blocks
end

# ---------- 断言组 ----------
# D₄：恰 10 个子群，阶 ∈ {1,2,4,8}（全部因子都出现）
subs_d4 = all_subgroups(dihedral(4))
@assert length(subs_d4) == 10 "D₄ 子群数 $(length(subs_d4)) ≠ 10"
@assert sort!(length.(subs_d4)) == [1, 2, 2, 2, 2, 2, 4, 4, 4, 8]
# S₃（以置换复合表）
s3_img = [[1,2,3],[2,1,3],[3,2,1],[1,3,2],[2,3,1],[3,1,2]]
s3_tbl = [findfirst(p -> p == [s3_img[a][s3_img[b][j]] for j in 1:3], s3_img)
          for a in 1:6, b in 1:6]
@assert is_group(s3_tbl)
subs_s3 = all_subgroups(s3_tbl)
@assert length(subs_s3) == 6
@assert sort!(length.(subs_s3)) == [1, 2, 2, 2, 3, 6]
println("子群枚举：D₄ 恰 10 个（阶 1,2,4,8 全出现）；S₃ 恰 6 个 ✓")

# 陪集分解：块数 × 块大小 = |G|，块两两不交，并回全集
for (tbl, H) in [(s3_tbl, subs_s3[4]), (s3_tbl, subs_s3[5]),
                 (dihedral(4), subs_d4[7]), (zn_add(12), [1, 5, 9])]
    blocks = cosets(tbl, H)
    @assert length(blocks) * length(H) == size(tbl, 1)
    @assert sort(vcat(blocks...)) == collect(1:size(tbl, 1))
end
println("陪集分解：块数 × 块大小 = |G|，两两不交并回全集（多组）✓")

# 拉格朗日三推论
for tbl in (s3_tbl, dihedral(4), un_mul(8), zn_add(12))
    n = size(tbl, 1)
    for H in all_subgroups(tbl)
        @assert n % length(H) == 0
    end
    for x in 1:n
        @assert n % order_of(tbl, x) == 0            # 推论 2.85
        @assert itpow(tbl, x, n) == identity_of(tbl) # 推论 2.86
    end
end
println("推论 2.85/2.86：元素阶 | 群阶，x^|G| = 1（S₃、D₄、U(8)、ℤ₁₂ 全量）✓")

# 命题 2.75：ℤ₁₂ 每个因子恰一个子群，d 阶子群生成元 φ(d) 个
z12 = zn_add(12)
by_order = Dict{Int,Int}()
for H in all_subgroups(z12)
    by_order[length(H)] = get(by_order, length(H), 0) + 1
end
@assert by_order == Dict(1 => 1, 2 => 1, 3 => 1, 4 => 1, 6 => 1, 12 => 1)
# ⟨a^k⟩ = ⟨a^gcd(k,n)⟩：⟨2⟩ = {2,4,6,8,10,12} 生成元恰 φ(6) = 2 个（元素 2 与 10）
H6 = [i for i in 1:12 if order_of(z12, i) == 6]
@assert length(H6) == 2
println("命题 2.75：ℤ₁₂ 因子 1,2,3,4,6,12 各恰一个子群；6 阶子群恰 φ(6) = 2 个生成元 ✓")

# 命题 2.80：ℤ₃₆ 中 ⟨4⟩+⟨6⟩ = ⟨gcd(4,6)⟩ = ⟨2⟩，⟨4⟩∩⟨6⟩ = ⟨lcm(4,6)⟩ = ⟨12⟩
sub_of_cyclic(n, d) = Set([mod1(j * d, n) for j in 0:(n ÷ d - 1)])
gens = Set(mod1(4a + 6b, 36) for a in 0:8, b in 0:5)      # 全部 4a+6b mod 36
@assert gens == sub_of_cyclic(36, 2)                       # 和 = ⟨gcd⟩
@assert intersect(sub_of_cyclic(36, 4), sub_of_cyclic(36, 6)) == sub_of_cyclic(36, 12)
println("命题 2.80：ℤ₃₆ 的 ⟨4⟩+⟨6⟩ = ⟨2⟩ = ⟨gcd⟩；⟨4⟩∩⟨6⟩ = ⟨12⟩ = ⟨lcm⟩ ✓")

println("END ====")
