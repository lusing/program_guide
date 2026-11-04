# 第 22 章 · 商环与有限域 —— Julia 通道
#
# GF(4)/GF(8)/GF(9) 完整实现 + 域公理 + 原根 + 双实现同构 + ℂ 模型。

println("==== 22 商环与有限域")

# ---------- GF(p^d) 引擎（ℤ_p[x]/(modpoly)） ----------
trim!(f) = (while length(f) > 1 && f[end] == 0; pop!(f); end; f)
deg(f) = any(!=(0), f) ? findlast(!=(0), f) - 1 : -1
peval(f, a) = (v = 0; for i in length(f):-1:1; v = v * 2 + f[i]; end; v)

function polymul_mod(f, g, modpoly, p)
    r = zeros(Int, length(f) + length(g) - 1)
    for (i, x) in enumerate(f), (j, y) in enumerate(g)
        r[i + j - 1] = (r[i + j - 1] + x * y) % p
    end
    # 模 modpoly 归约（反复消最高次）
    while deg(r) >= deg(modpoly)
        shift = deg(r) - deg(modpoly) + 1
        c = r[end]
        for (j, mv) in enumerate(modpoly)
            r[shift + j - 1] = mod(r[shift + j - 1] - c * mv, p)
        end
        trim!(r)
    end
    trim!(r)
end

struct GF
    p::Int
    coeff::Vector{Int}    # 次数 < d 的系数（mod p）
    modpoly::Vector{Int}
end
Base.:(==)(u::GF, v::GF) = u.p == v.p && u.coeff == v.coeff && u.modpoly == v.modpoly
gf_add(u::GF, v::GF) = GF(u.p, trim!([mod(a + b, u.p) for (a, b) in zip(vcat(u.coeff, zeros(Int, max(0, length(v.coeff) - length(u.coeff)))),
                                                                                vcat(v.coeff, zeros(Int, max(0, length(u.coeff) - length(v.coeff)))))]) , u.modpoly)
gf_neg(u::GF) = GF(u.p, trim!([mod(-c, u.p) for c in u.coeff]), u.modpoly)
gf_mul(u::GF, v::GF) = GF(u.p, polymul_mod(u.coeff, v.coeff, u.modpoly, u.p), u.modpoly)

gf_zero(p, mp) = GF(p, [0], mp)
gf_one(p, mp) = GF(p, [1], mp)

function gf_inv(u::GF)
    u == gf_zero(u.p, u.modpoly) && error("零元无逆")
    # 穷举非零元找乘积 = 1
    d = length(u.modpoly) - 1
    for code in 1:(u.p^d - 1)
        cs = digits(code, base=u.p, pad=d) .+ 1 .- 1
        cs = [c for c in cs]
        v = GF(u.p, trim!(cs .+ 0), u.modpoly)
        gf_mul(u, v) == gf_one(u.p, u.modpoly) && return v
    end
    error("无逆")
end

# ---------- (1) GF(4) = ℤ₂[x]/(x²+x+1) ----------
p4, mp4 = 2, [1, 1, 1]                # x² + x + 1
g1 = gf_one(p4, mp4)
ga = GF(2, [0, 1], mp4)               # α = x
g3 = gf_mul(ga, ga)                    # α² = α+1（mod x²+x+1: x² ≡ x+1）
@assert g3.coeff == [1, 1]
g4 = gf_mul(g3, ga)                    # α³ = 1
@assert g4 == g1
println("GF(4)：α² = α+1、α³ = 1（非零乘法群 = ⟨α⟩ 循环 3 阶）✓")

# ---------- (2) GF(8) = ℤ₂[x]/(x³+x+1) ----------
mp8 = [1, 1, 0, 1]                     # x³ + x + 1
a8 = GF(2, [0, 1], mp8)
cur = gf_one(2, mp8)
order8 = 0
for k in 1:7
    global cur = gf_mul(cur, a8)
    if cur == gf_one(2, mp8)
        global order8 = k
        break
    end
end
@assert order8 == 7                    # α 是原根
# 双实现同构：ℤ₂[x]/(x³+x²+1) 造出同一个 GF(8)
mp8b = [1, 0, 1, 1]                    # x³ + x² + 1
b8 = GF(2, [0, 1], mp8b)
# 两个实现都是 8 元域：非零元乘法群都循环（都找到原根）
cur = gf_one(2, mp8b); order8b = 0
for k in 1:7
    global cur = gf_mul(cur, b8)
    if cur == gf_one(2, mp8b)
        global order8b = k
        break
    end
end
@assert order8b == 7
println("GF(8)：ℤ₂[x]/(x³+x+1) 与 (x³+x²+1) 双实现均有 7 阶原根（同构的实验侧写）✓")

# ---------- (3) GF(9) = ℤ₃[x]/(x²+1) ----------
mp9 = [1, 0, 1]                        # x² + 1（x² ≡ −1 = 2）
a9 = GF(3, [0, 1], mp9)
a9sq = gf_mul(a9, a9)
@assert a9sq.coeff == [2]              # α² = −1 (mod 3)
# 原根计数：φ(8) = 4
primitives = 0
for code in 1:8
    cs = digits(code, base=3, pad=2)
    u = GF(3, trim!(cs), mp9)
    cur = gf_one(3, mp9); ord = 0
    for k in 1:8
        global cur2 = gf_mul(cur, u)
        cur = cur2
        if cur == gf_one(3, mp9)
            ord = k; break
        end
    end
    ord == 8 && (global primitives += 1)
end
@assert primitives == 4
println("GF(9)：ℤ₃[x]/(x²+1)，α² = −1；原根恰 φ(8) = 4 个 ✓")

# ---------- (4) ℂ 模型：ℝ[x]/(x²+1) 的序对实现 = 复数算术 ----------
cmul(z, w) = (z[1]*w[1] - z[2]*w[2], z[1]*w[2] + z[2]*w[1])
z, w = (0, 1), (3, 4)
@assert cmul(z, w) == (-4, 3)          # i(3+4i) = −4+3i
@assert cmul(z, z) == (-1, 0)          # i² = −1
println("ℂ 模型：ℝ[x]/(x²+1) 的序对乘法 = 复数乘法（i² = −1）✓")

# ---------- (5) ℤ₁₂ vs GF(16) ----------
z12_mul(a, b) = (a * b) % 12
has_zd = any(a > 0 && b > 0 && z12_mul(a, b) == 0 for a in 1:11, b in 1:11)
@assert has_zd                          # ℤ₁₂ 有零因子
mp16 = [1, 1, 0, 0, 1]                  # x⁴ + x + 1（ℤ₂ 不可约）
# GF(16) 无零因子：抽 50 对非零元乘积非零
using Random
Random.seed!(20261104)
function rand_gf(p, mp)
    d = length(mp) - 1
    GF(p, trim!(rand(0:p-1, d) .+ (0)), mp)
end
for _ in 1:50
    u = rand_gf(2, mp16); u.coeff == [0] && continue
    v = rand_gf(2, mp16); v.coeff == [0] && continue
    prod16 = gf_mul(u, v)
    @assert prod16.coeff != [0]
end
println("素数幂阶两个命运：ℤ₁₂ 有零因子；GF(16) = ℤ₂[x]/(x⁴+x+1) 无零因子 ✓")

println("END ====")
