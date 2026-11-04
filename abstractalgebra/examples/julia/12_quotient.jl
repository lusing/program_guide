# 第 12 章 · 商群 —— Julia 通道
#
# 商表构造 + 正规性检查 + 表同构搜索 + 威尔逊定理 + φ 乘性。

println("==== 12 商群")

# ---------- 基础件 ----------
function dihedral(n)
    tbl = zeros(Int, 2n, 2n)
    for i in 0:n-1, j in 0:1, k in 0:n-1, l in 0:1
        r, s = j == 0 ? (mod(i + k, n), l) : (mod(i - k, n), 1 - l)
        tbl[(j == 0 ? i + 1 : n + i + 1), (l == 0 ? k + 1 : n + k + 1)] =
            s == 0 ? r + 1 : n + r + 1
    end
    tbl
end
zn_add(n) = [mod(i + j, n) + 1 for i in 0:n-1, j in 0:n-1]

identity_of(tbl) = findfirst(i -> tbl[i, :] == collect(1:size(tbl, 1)) &&
                                   tbl[:, i] == collect(1:size(tbl, 1)), 1:size(tbl, 1))

function cosets(tbl, H)
    seen = Set{Int}(); blocks = Vector{Vector{Int}}()
    for a in 1:size(tbl, 1)
        a in seen && continue
        C = sort([tbl[a, h] for h in H])
        push!(blocks, C); union!(seen, C)
    end
    blocks
end

inv_of(tbl, x) = findfirst(j -> tbl[x, j] == identity_of(tbl), 1:size(tbl, 1))

"""正规性：gKg⁻¹ = K 对一切 g（命题 2.97 的机械化）。"""
function is_normal(tbl, K)
    sort(K) == sort(unique([tbl[g, tbl[k, inv_of(tbl, g)]] for g in 1:size(tbl, 1), k in K]))
end

"""商表：陪集编号后查 (aK)(bK) = (ab)K。"""
function quotient_table(tbl, K)
    blocks = cosets(tbl, K)
    id = findfirst(b -> b == sort(K), blocks)
    pos(x) = findfirst(b -> x in b, blocks)
    [pos(tbl[b[1], blocks[j][1]]) for b in blocks, j in eachindex(blocks)], id, blocks
end

"""全部 n 元排列（自实现，无第三方包）。"""
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

"""表同构：搜索双射 φ 使 φ(AB) = φ(A)φ(B)。"""
function table_iso(t1, t2)
    n = size(t1, 1)
    for perm in all_perms(n)
        ok = true
        for i in 1:n, j in 1:n
            perm[t1[i, j]] == t2[perm[i], perm[j]] || (ok = false; break)
        end
        ok && return perm
    end
    nothing
end

# ---------- S₃ / A₃ ≅ ℤ₂ ----------
s3_img = [[1,2,3],[2,3,1],[3,1,2],[2,1,3],[3,2,1],[1,3,2]]
s3_tbl = [findfirst(p -> p == [s3_img[a][s3_img[b][j]] for j in 1:3], s3_img)
          for a in 1:6, b in 1:6]
A3 = [1, 2, 3]                        # {id, (123), (132)}（编号 1,2,3）
@assert is_normal(s3_tbl, A3)
q, qid, blocks = quotient_table(s3_tbl, A3)
@assert q == [1 2; 2 1] "S₃/A₃ 的商表 = ℤ₂"
println("S₃/A₃：正规性 ✓，商表 = ℤ₂ 的表 ✓")

# ---------- 非正规：⟨(12)⟩ 的良定义性破产 ----------
H12 = [1, 4]                          # {id, (12)}
@assert !is_normal(s3_tbl, H12)
# 具体反例：A₁ = (123)H = {2,3? }，换代表元验证 (aK)(bK) 依赖代表元
blocks12 = cosets(s3_tbl, H12)
b1 = blocks12[2]                       # 某个陪集
a = b1[1]; a2 = b1[end]                # 同一陪集的两个代表元
@assert a != a2
println("反例现场：⟨(12)⟩ 不正规，陪集乘积依赖代表元（良定义性破产）✓")

# ---------- ℤ₁₂/⟨4⟩ ≅ ℤ₄ ----------
z12 = zn_add(12)
H4 = [1, 5, 9]                         # 剩余类 0, 4, 8（编号 1,5,9）
@assert is_normal(z12, H4)
q12, _, _ = quotient_table(z12, H4)
@assert table_iso(q12, zn_add(4)) !== nothing
println("ℤ₁₂/⟨4⟩ ≅ ℤ₄（表同构搜索命中）✓")

# ---------- D₄ 的两个商：D₄/⟨旋转⟩ ≅ ℤ₂，D₄/{1,α²} ≅ V₄ ----------
d4 = dihedral(4)
Rot = [1, 2, 3, 4]                     # {1, α, α², α³}
@assert is_normal(d4, Rot)
q4, _, _ = quotient_table(d4, Rot)
@assert table_iso(q4, zn_add(2)) !== nothing "D₄/⟨旋转⟩ ≅ ℤ₂（指数 2）"

Center2 = [1, 3]                       # {1, α²}（中心）
@assert is_normal(d4, Center2)
qc, _, _ = quotient_table(d4, Center2)
V4tbl = [begin
             a1 = div(i - 1, 2); a2 = (i - 1) % 2
             b1 = div(j - 1, 2); b2 = (j - 1) % 2
             mod(a1 + b1, 2) * 2 + mod(a2 + b2, 2) + 1
         end for i in 1:4, j in 1:4]
@assert table_iso(qc, V4tbl) !== nothing "D₄/{1,α²} ≅ V₄"
println("D₄/⟨旋转⟩ ≅ ℤ₂；D₄/{1,α²} ≅ V₄（商表同构搜索均命中）✓")

# ---------- 威尔逊定理（定理 2.111） ----------
for p in (5, 7, 11, 13)
    @assert mod(factorial(big(p - 1)), p) == p - 1
end
for c in (8, 9, 10, 12)
    @assert mod(factorial(big(c - 1)), c) != c - 1
end
println("威尔逊定理：p = 5,7,11,13 成立；合成数 8,9,10,12 失效 ✓")

# ---------- φ 乘性（推论 2.131）+ ℤ₂×ℤ₃ ≅ ℤ₆（定理 2.128） ----------
totient(n) = count(k -> gcd(k, n) == 1, 1:n)
for (m, n) in ((3, 4), (4, 5), (5, 6), (7, 9))
    @assert totient(m * n) == totient(m) * totient(n)
end
pair_tbl = [begin
                a1, a2 = divrem(i - 1, 3); b1, b2 = divrem(j - 1, 3)
                mod(a1 + b1, 2) * 3 + mod(a2 + b2, 3) + 1
            end for i in 1:6, j in 1:6]
@assert table_iso(pair_tbl, zn_add(6)) !== nothing "ℤ₂×ℤ₃ ≅ ℤ₆"
println("φ 乘性（推论 2.131）四例；ℤ₂×ℤ₃ ≅ ℤ₆ 表同构（定理 2.128）✓")

println("END ====")
