# 第 21 章 · 不可约性判别 —— Julia 通道
#
# Eisenstein 判别 + 模 p 归约工作流 + Φ_p(x+1) 系数核对。

println("==== 21 不可约性判别")

isprime(n) = n >= 2 && (for d in 2:isqrt(n); n % d == 0 && return false; end; true)

peval(f, a, p) = (v = 0; for i in length(f):-1:1; v = (v * a + f[i]) % p; end; v)
trim!(f) = (while length(f) > 1 && f[end] == 0; pop!(f); end; f)
deg(f) = any(!=(0), f) ? findlast(!=(0), f) - 1 : -1

# ---------- (1) Eisenstein ----------
function eisenstein(coeffs)          # 低位到高位
    for p in 2:50
        isprime(p) || continue
        coeffs[end] % p == 0 && continue           # p ∤ 首项
        all(c -> c % p == 0, coeffs[1:end-1]) || continue
        coeffs[1] % (p * p) != 0 || continue       # p² ∤ 常数
        return p
    end
    nothing
end

@assert eisenstein([2, -4, 0, 0, 0, 1]) == 2       # x⁵ − 4x + 2
@assert eisenstein([1, 2, 1]) === nothing           # x²+2x+1 = (x+1)² 不适用
println("Eisenstein：x⁵−4x+2 命中 p = 2；(x+1)² 正确落空 ✓")

# ---------- (2) 模 p 归约工作流 ----------
function modp_reduce(f, p)
    [mod(c, p) for c in f] |> trim!
end
function monic_quadratics(p)
    [trim!([c0, c1, 1]) for c0 in 0:p-1, c1 in 0:p-1] |> vec
end
function polydiv_zp(f, g, p)
    g = trim!(copy(g)); q = zeros(Int, max(0, length(f) - length(g) + 1))
    r = trim!(copy(f))
    while length(r) >= length(g) && any(!=(0), r)
        shift = length(r) - length(g)
        ginv = findfirst(b -> g[end] * b % p == 1, 1:p-1)
        ginv === nothing && error("无逆")
        c = r[end] * ginv % p
        q[shift + 1] = c
        for (j, gv) in enumerate(g)
            r[shift + j] = mod(r[shift + j] - c * gv, p)
        end
        trim!(r)
    end
    trim!(q), r
end
function irreducible_modp(f, p)
    trim!(f)
    deg(f) <= 0 && return false
    any(a -> peval(f, a, p) == 0, 0:p-1) && return false
    deg(f) <= 3 && return true
    for g in monic_quadratics(p)
        _, r = polydiv_zp(f, g, p)
        all(iszero, r) && return false
    end
    true
end

f_x4xp1 = [1, 1, 0, 0, 1]            # x⁴ + x + 1
@assert irreducible_modp(modp_reduce(f_x4xp1, 2), 2)   # mod 2 不可约 → ℚ 上不可约
f_x4p1 = [1, 0, 0, 0, 1]             # x⁴ + 1（Φ₈）
@assert !irreducible_modp(modp_reduce(f_x4p1, 2), 2)   # mod 2 = (x+1)⁴（碰壁）
@assert !irreducible_modp(modp_reduce(f_x4p1, 3), 3)   # mod 3 也裂成两个二次（8 | 3²−1）
println("模 p 归约：x⁴+x+1 mod 2 不可约（⟹ ℚ 上不可约）；x⁴+1 在 p = 2, 3 均碰壁 ✓")

# ---------- (3) Φ_p(x+1) 的二项系数 ----------
for p in (3, 5, 7)
    # Φ_p(x+1) = ((x+1)^p − 1)/x 的系数 = C(p,1),...,C(p,p−1),1
    for k in 1:p-1
        @assert binomial(big(p), k) % p == 0 "C($p,$k) 应被 $p 整除"
    end
    @assert binomial(big(p), p) % p != 0
end
println("Φ_p(x+1) 引擎：C(p,k) 被 p 整除（p = 3,5,7 全档）✓")

# ---------- (4) 工作流闭环：判"不可约"者穷举找不到因子 ----------
using Random
Random.seed!(20261104)
checked = 0
for _ in 1:100
    f = trim!(rand(0:2, rand(4:5)))
    f[end] == 0 && continue
    irreducible_modp(f, 3) || continue
    global checked += 1
    # 穷举一次因子
    has_linear = any(a -> peval(f, a, 3) == 0, 0:2)
    @assert !has_linear
    deg(f) <= 3 && continue
    has_quad = any(g -> all(iszero, polydiv_zp(f, g, 3)[2]), monic_quadratics(3))
    @assert !has_quad
end
@assert checked >= 5
println("工作流闭环：判不可约的 $(checked) 组 ℤ₃ 多项式穷举均无因子 ✓")

println("END ====")
