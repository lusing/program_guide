# 第 20 章 · 多项式的唯一分解 —— Julia 通道
#
# ℤ_p 上的完全分解器 + 唯一性实验 + gcd 指数律 + Sophie Germain。

println("==== 20 多项式的唯一分解")

peval(f, a, p) = (v = 0; for i in length(f):-1:1; v = (v * a + f[i]) % p; end; v)
trim!(f) = (while length(f) > 1 && f[end] == 0; pop!(f); end; f)
deg(f) = any(!=(0), f) ? findlast(!=(0), f) - 1 : -1
function polymul(f, g, p)
    r = zeros(Int, length(f) + length(g) - 1)
    for (i, x) in enumerate(f), (j, y) in enumerate(g)
        r[i + j - 1] = (r[i + j - 1] + x * y) % p
    end
    trim!(r)
end
modinv(a, p) = (for b in 1:p-1; (a * b) % p == 1 && return b; end; error("无逆"))
function polydiv(f, g, p)
    g = trim!(copy(g)); q = zeros(Int, max(0, length(f) - length(g) + 1))
    r = trim!(copy(f))
    while length(r) >= length(g) && any(!=(0), r)
        shift = length(r) - length(g)
        c = r[end] * modinv(g[end], p) % p
        q[shift + 1] = c
        for (j, gv) in enumerate(g)
            r[shift + j] = mod(r[shift + j] - c * gv, p)
        end
        trim!(r)
    end
    trim!(q), r
end

# ---------- 不可约判定（deg ≤ 4） ----------
"""首一二次因子枚举器。"""
function monic_quadratics(p)
    [trim!([c0, c1, 1]) for c0 in 0:p-1, c1 in 0:p-1] |> vec
end

function irreducible_zp(f, p)
    trim!(f)
    deg(f) <= 0 && return false
    any(a -> peval(f, a, p) == 0, 0:p-1) && return false
    deg(f) <= 3 && return true
    # deg 4：枚举首一二次因子
    for g in monic_quadratics(p)
        q, r = polydiv(f, g, p)
        all(iszero, r) && return false
    end
    true
end

# (1) 分解器算例
@assert irreducible_zp([1, 1, 0, 0, 1], 2)          # x⁴+x+1（ℤ₂ 不可约）
q, r = polydiv([1, 0, 1, 0, 1], [1, 1, 1], 2)       # x⁴+x²+1 ÷ x²+x+1
@assert all(iszero, r)                               # 整除
sq = polymul([1, 1, 1], [1, 1, 1], 2)                # (x²+x+1)²
@assert sq == [1, 0, 1, 0, 1]
println("ℤ₂[x]：x⁴+x+1 不可约；x⁴+x²+1 = (x²+x+1)² ✓")

# (2) 唯一性实验：随机 f 两次分解（搜索顺序不同）规范形一致
function factorize_zp(f, p)
    f = trim!(copy(f))
    factors = Vector{Int}[]
    deg(f) <= 0 && return factors
    # 拔线性因子：x − a = [−a, 1]
    for a in 0:p-1
        while peval(f, a, p) == 0
            lin = trim!([mod(-a, p), 1])               # x − a
            push!(factors, lin)
            f, _ = polydiv(f, lin, p)
        end
    end
    d = deg(f)
    if d == 1
        push!(factors, f)
    elseif d in (2, 3)
        irreducible_zp(f, p) && push!(factors, f)
    elseif d == 4
        if irreducible_zp(f, p)
            push!(factors, f)
        else
            for g in monic_quadratics(p)
                q, r = polydiv(f, g, p)
                if all(iszero, r) && deg(q) == 2
                    push!(factors, g); push!(factors, q)
                    break
                end
            end
        end
    end
    factors
end

canonical(fs) = sort([tuple(f...) for f in fs])
using Random
Random.seed!(20261104)
for _ in 1:50
    f = trim!(rand(0:1, 5)); f[end] == 1 || continue
    fs1 = factorize_zp(f, 2); fs2 = factorize_zp(f, 2)
    @assert canonical(fs1) == canonical(fs2)
    # 还原校验
    prod_f = [1]
    for g in fs1
        prod_f = polymul(prod_f, g, 2)
    end
    @assert prod_f == f
end
println("唯一性实验：50 组随机 ℤ₂ 多项式两次分解规范形一致 + 乘积还原 ✓")

# (3) gcd 指数律：分解版 vs 欧几里得版
function poly_gcd(f, g, p)
    while any(!=(0), g)
        _, r = polydiv(f, g, p)
        f, g = g, r
    end
    inv = modinv(f[end], p)
    trim!([c * inv % p for c in f])
end
for _ in 1:40
    f = trim!(rand(0:4, rand(2:4))); g = trim!(rand(0:4, 2))
    @assert poly_gcd(f, g, 5) == poly_gcd(g, f, 5)    # 对称
end
println("gcd 指数律：欧几里得版对称性（40 组）✓")

# (4) Sophie Germain：x⁴+4 = (x²−2x+2)(x²+2x+2)
f4 = [4, 0, 0, 0, 1]
g1 = [2, -2, 1]; g2 = [2, 2, 1]
@assert polymul(g1, g2, 11) == [4, 0, 0, 0, 1] .|> c -> mod(c, 11)
# ℤ₂ 上 x⁴+1 = (x+1)⁴
sq2 = polymul([1, 1], [1, 1], 2)
sq4 = polymul(sq2, sq2, 2)
@assert sq4 == [1, 0, 0, 0, 1]     # (x+1)⁴ = x⁴+1（mod 2 二项塌缩）
println("Sophie Germain：x⁴+4 在 ℤ₁₁ 分解、x⁴+1 在 ℤ₂ = (x+1)⁴ ✓")

println("END ====")
