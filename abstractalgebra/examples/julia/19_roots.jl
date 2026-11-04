# 第 19 章 · 从数到多项式：根与因子 —— Julia 通道
#
# 根穷举 + 多项式欧几里得 + 贝祖回代 + 拉格朗日插值。

println("==== 19 从数到多项式")

peval(f, a, p) = (v = 0; for i in length(f):-1:1; v = (v * a + f[i]) % p; end; v)
trim!(f) = (while length(f) > 1 && f[end] == 0; pop!(f); end; f)
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

# ---------- (1) 根穷举 ----------
roots_of(f, p) = [a for a in 0:p-1 if peval(f, a, p) == 0]
@assert roots_of([0, 6, 0, 1], 7) == [0, 1, 6]   # x³−x 的根 {0,1,6} = {0,1,−1}
@assert length(roots_of([7, 0, 1], 8)) == 4  # x²−1 (mod 8)：{1,3,5,7}
println("x³−x (mod 7) 恰 3 根；x²−1 (mod 8) 恰 4 根（反例：根数 > 次数）✓")

# ---------- (2) 有理根定理机器化：2x³+x−3 ----------
# 候选 = p/q：p | 3、q | 2 → {±1, ±3, ±1/2, ±3/2}
cands = [1, -1, 3, -3, 1//2, -1//2, 3//2, -3//2]
f_eval(x) = 2x^3 + x - 3
hit = [x for x in cands if f_eval(x) == 0]
@assert hit == [1]
println("有理根定理：2x³+x−3 的候选 8 个中恰 x = 1 入选 ✓")

# ---------- (3) 多项式欧几里得 + 贝祖回代 ----------
function poly_extgcd(f, g, p)
    old_r, r = trim!(copy(f)), trim!(copy(g))
    old_s, s = [1], [0]
    old_t, t = [0], [1]
    while any(!=(0), r)
        q, rem = polydiv(old_r, r, p)
        old_r, r = r, rem
        old_s, s = s, trim!([mod(c, p) for c in (length(old_s) >= length(polymul(q, s, p)) ?
            old_s .- vcat(polymul(q, s, p), zeros(Int, length(old_s) - length(polymul(q, s, p)))) :
            vcat(old_s, zeros(Int, length(polymul(q, s, p)) - length(old_s))) .- polymul(q, s, p))])
        old_t, t = t, trim!([mod(c, p) for c in (length(old_t) >= length(polymul(q, t, p)) ?
            old_t .- vcat(polymul(q, t, p), zeros(Int, length(old_t) - length(polymul(q, t, p)))) :
            vcat(old_t, zeros(Int, length(polymul(q, t, p)) - length(old_t))) .- polymul(q, t, p))])
    end
    old_r, old_s, old_t
end

"""多项式加法（长度对齐 + mod p）。"""
function polyadd(f, g, p)
    n_len = max(length(f), length(g))
    trim!([mod(get(f, i, 0) + get(g, i, 0), p) for i in 1:n_len])
end

# 固定案例：ℤ₅ 中 gcd(x²+1, x+2)
f2 = [1, 0, 1]; g2 = [2, 1]      # x²+1, x+2
d2, s2, t2 = poly_extgcd(f2, g2, 5)
@assert polyadd(polymul(s2, f2, 5), polymul(t2, g2, 5), 5) == d2
println("贝祖回代：s(x)(x²+1) + t(x)(x+2) = gcd（ℤ₅ 固定案例核验）✓")

# 随机 50 组贝祖恒等式
for _ in 1:50
    f1 = trim!(rand(0:4, rand(2:4))); g1 = trim!(rand(0:4, 2))
    g1[end] == 0 && continue
    d1, s1, t1 = poly_extgcd(f1, g1, 5)
    @assert polyadd(polymul(s1, f1, 5), polymul(t1, g1, 5), 5) == d1
end
println("贝祖恒等式：50 组随机对全部成立（ℤ₅）✓")

# gcd 递归性质：gcd(f, g) = gcd(g, f mod g)
for _ in 1:50
    f1 = trim!(rand(0:4, rand(2:4))); g1 = trim!(rand(0:4, 2))
    g1[end] == 0 && continue
    _, r1 = polydiv(f1, g1, 5)
    all(iszero, r1) && continue
    d1, _, _ = poly_extgcd(f1, g1, 5)
    d3, _, _ = poly_extgcd(g1, r1, 5)
    # gcd 首一化比较
    inv = modinv(d1[end], 5)
    d1n = [c * inv % 5 for c in d1]
    inv3 = modinv(d3[end], 5)
    d3n = [c * inv3 % 5 for c in d3]
    @assert trim!(d1n) == trim!(d3n)
end
println("gcd 递归性：gcd(f,g) = gcd(g, f mod g)（50 组随机对拍）✓")

# ---------- (4) 拉格朗日插值（CRT 在 F[x] 的实现） ----------
points = [(1, 2), (2, 4), (3, 0)]   # ℤ₇ 上三点
# 解线性方程组求二次多项式系数（克莱姆法则版：范德蒙行列式非零）
A = [mod(a^j, 7) for (a, _) in points, j in 0:2]
bv = [y for (_, y) in points]
det = (A[1,1]*(A[2,2]*A[3,3] - A[2,3]*A[3,2])
     - A[1,2]*(A[2,1]*A[3,3] - A[2,3]*A[3,1])
     + A[1,3]*(A[2,1]*A[3,2] - A[2,2]*A[3,1])) % 7
det_inv = modinv(mod(det, 7), 7)
coef = Int[]
for c in 1:3
    Ac = copy(A)
    Ac[:, c] = bv
    dc = (Ac[1,1]*(Ac[2,2]*Ac[3,3] - Ac[2,3]*Ac[3,2])
        - Ac[1,2]*(Ac[2,1]*Ac[3,3] - Ac[2,3]*Ac[3,1])
        + Ac[1,3]*(Ac[2,1]*Ac[3,2] - Ac[2,2]*Ac[3,1]))
    push!(coef, mod(dc * det_inv, 7))
end
@assert all(peval(coef, a, 7) == v for (a, v) in points)
println("拉格朗日插值：过 (1,2),(2,4),(3,0) 的二次多项式 = $(coef)（ℤ₇ 克莱姆）✓")

# ---------- (6) 高斯整数 ℤ[i]：欧几里得除法与四商例（例 3.77） ----------

gi_norm(a, b) = a^2 + b^2

"""最近整点（±1/2 恰居中时任取一侧都合法——商本就不唯一）。"""
nearest(q::Rational{Int}) = isinteger(q) ? Int(q) :
    (q - floor(q) > 1//2 ? Int(floor(q)) + 1 : Int(floor(q)))

"""高斯除法 α = βq + r（最近整点实现，例 3.77 的证明路线）。"""
function gauss_divide(a1, b1, a2, b2)
    d = gi_norm(a2, b2)
    xr = (a1 * a2 + b1 * b2) // d      # α/β = αβ̄/∂(β) 的实部
    yr = (b1 * a2 - a1 * b2) // d      # 虚部
    m, n = nearest(xr), nearest(yr)
    ra, rb = a1 - (a2 * m - b2 * n), b1 - (a2 * n + b2 * m)
    return (m, n, ra, rb)
end

# 书例：3+5i 除以 2 的四个商，每个余数 ∂ = 2 < 4 = ∂(2)
for (q, r) in [((1, 2), (1, 1)), ((1, 3), (1, -1)), ((2, 2), (-1, 1)), ((2, 3), (-1, -1))]
    @assert 3 + 5im == 2 * (q[1] + q[2] * im) + (r[1] + r[2] * im)
    @assert gi_norm(r...) < gi_norm(2, 0)
end
# 公理 (ii)：随机 40 对 α, β 验证 α = βq + r 且 ∂(r) < ∂(β)
for _ in 1:40
    a1, b1, a2, b2 = rand(-9:9, 4)
    (a2, b2) == (0, 0) && continue
    m, n, ra, rb = gauss_divide(a1, b1, a2, b2)
    @assert a1 + b1 * im == (a2 + b2 * im) * (m + n * im) + (ra + rb * im)
    @assert gi_norm(ra, rb) < gi_norm(a2, b2)
end
# 公理 (i)：范数乘性 ∂(αβ) = ∂(α)∂(β)
for _ in 1:20
    a1, b1, a2, b2 = rand(-6:6, 4)
    @assert gi_norm(a1 * a2 - b1 * b2, a1 * b2 + b1 * a2) == gi_norm(a1, b1) * gi_norm(a2, b2)
end
println("例 3.77：四商恒等式 + 40 对随机高斯除法（∂(r) < ∂(β)）+ 范数乘性 20 对 ✓")

# ---------- (7) 费马二平方和（定理 3.83）：ℤ[i] 的第一份红利 ----------

# 引理 3.82 的见证：p ≡ 1 (mod 4) 时 m² ≡ −1 (mod p)
for (p, m) in [(5, 2), (13, 5), (17, 4), (29, 12), (41, 9), (61, 11)]
    @assert p % 4 == 1 && m^2 % p == p - 1
    a, b = first((a, b) for a in 1:isqrt(p) for b in 0:a if a^2 + b^2 == p)
    @assert a^2 + b^2 == p                   # 定理 3.83 正向：表示存在
end
# 反向：p ≡ 3 (mod 4) 时无表示（平方 mod 4 ∈ {0,1} 的穷举版）
for p in (3, 7, 11, 19)
    @assert p % 4 == 3
    @assert isempty([(a, b) for a in 0:isqrt(p) for b in 0:a if a^2 + b^2 == p])
end
println("定理 3.83：p ≡ 1 (mod 4) 六例有表示（含引理 3.82 见证）；p ≡ 3 (mod 4) 四例穷举无表示 ✓")

println("END ====")
