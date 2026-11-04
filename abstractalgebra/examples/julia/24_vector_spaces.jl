# 第 24 章 · 向量空间 —— Julia 通道
#
# GF(p) 上的高斯消元 + 子空间计数 + Fano 平面回环。

println("==== 24 向量空间")

modinv(a, p) = (for b in 1:p-1; a * b % p == 1 && return b; end; error("无逆"))

"""GF(p) 上的 RREF：返回 (rref, rank)。"""
function rref(A, p)
    A = map(x -> mod(x, p), copy(A)); m, n = size(A); rk = 0
    for c in 1:n
        rk >= m && break
        piv = findfirst(!iszero, A[rk+1:m, c]); piv === nothing && continue
        piv += rk
        A[rk+1, :], A[piv, :] = A[piv, :], A[rk+1, :]
        A[rk+1, :] = map(x -> x * modinv(A[rk+1, c], p) % p, A[rk+1, :])
        for r in 1:m; r == rk + 1 && continue
            fac = A[r, c]
            A[r, :] = map((x, y) -> mod(x - fac * y, p), A[r, :], A[rk+1, :])
        end
        rk += 1
    end
    A, rk
end

# ---------- 维数不变性 ----------
using Random
Random.seed!(20261104)
for _ in 1:50
    A = rand(0:2, 4, 4)
    _, r1 = rref(A, 3)
    A2 = A[4:-1:1, 4:-1:1]            # 行列翻转再消元
    _, r2 = rref(A2, 3)
    @assert r1 == r2
end
println("维数不变性：50 组 GF(3) 随机 4×4 的 rank 与消元顺序无关 ✓")

# ---------- 计数公式 ----------
n = 3
@assert 2^n == 8                          # 向量数
@assert 2^n - 1 == 7                      # 非零向量
# 线性无关二元组：(q^n−1)(q^n−q) = 7·6 = 42
vectors = [[a, b, c] for a in 0:1, b in 0:1, c in 0:1] |> vec
indep_pairs = 0
for i in 1:8, j in 1:8
    i == j && continue
    u, v = vectors[i], vectors[j]
    v == [0, 0, 0] && continue
    u == [0, 0, 0] && continue
    dep = false
    for a in 0:1, b in 0:1
        (a, b) == (0, 0) && continue
        a .* u == b .* v && (dep = true)
    end
    dep || (global indep_pairs += 1)
end
@assert indep_pairs == 42
# 有序基 = 7·6·4 = 168 = |GL(3,2)|
bases = 0
for i in 1:8, j in 1:8, k in 1:8
    i == j && continue
    M = hcat(vectors[i], vectors[j], vectors[k])
    _, rk = rref(Int.(M), 2)
    rk == 3 && (global bases += 1)
end
@assert bases == 168
println("计数：|V| = 8、非零 7、无关对 42 = (8−1)(8−2)、有序基 168 = |GL(3,2)| ✓")

# ---------- GF(3)³ 中平面数 = 13 ----------
function span3(u, v)
    s = Set{Vector{Int}}()
    for a in 0:2, b in 0:2
        push!(s, map(x -> mod(x, 3), a .* u .+ b .* v))
    end
    s
end
planes = Set{Vector{Vector{Int}}}()
vecs3 = [[a, b, c] for a in 0:2, b in 0:2, c in 0:2] |> vec
for u in vecs3, v in vecs3
    u == [0, 0, 0] && continue; v == [0, 0, 0] && continue
    span = span3(u, v)
    length(span) == 9 || continue          # 二维张成恰 9 元
    push!(planes, sort(collect(span)))
end
@assert length(planes) == 13
println("GF(3)³ 的 2 维子空间恰 13 个 ✓")

# ---------- GF(2)³ 的 16 个子空间 = Fano 回环 ----------
subspaces = Set{Vector{Vector{Int}}}()
for mask in 0:255
    S = [vectors[i] for i in 1:8 if (mask >> (i - 1)) & 1 == 1]
    isempty(S) && continue
    closed = all(map(x -> mod(x, 2), a .+ b) in S for a in S, b in S)
    closed && push!(subspaces, sort(S))
end
@assert length(subspaces) == 16
lines = count(S -> length(S) == 2, subspaces)   # 二元子空间 = 直线
@assert lines == 7
println("GF(2)³ 恰 16 个子空间：{0} + 7 直线 + 7 平面 + 全空间；7 直线 = Fano 点 ✓")

println("END ====")
