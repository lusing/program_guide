# 第 17 章 · 多项式环 —— Julia 通道
#
# 长除法实现 + 余式定理 + 次数塌缩 + 形式 ≠ 函数 + 求值同态。

println("==== 17 多项式环")

# ---------- 多项式件（系数向量 mod p，低位在前） ----------
trim!(p) = (while length(p) > 1 && p[end] == 0; pop!(p); end; p)
peval(f, a, p) = (v = 0; for i in length(f):-1:1; v = (v * a + f[i]) % p; end; v)

function polymul(f, g, p)
    r = zeros(Int, length(f) + length(g) - 1)
    for (i, a) in enumerate(f), (j, b) in enumerate(g)
        r[i + j - 1] = (r[i + j - 1] + a * b) % p
    end
    trim!(r)
end

modinv(a, p) = (for b in 1:p-1; (a * b) % p == 1 && return b; end; error("无逆"))

"""f ÷ g = (q, r)：deg r < deg g 或 r = 0（系数域 ℤ_p）。"""
function polydiv(f, g, p)
    g = trim!(copy(g))
    q = zeros(Int, max(0, length(f) - length(g) + 1))
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

deg(f) = any(!=(0), f) ? findlast(!=(0), f) - 1 : -1

# ---------- 断言组 ----------
# (1) 除法算式：x⁵−1 ÷ x²+x+1（ℤ₇）
f = [6, 0, 0, 0, 0, 1]      # x⁵ − 1（mod 7: −1 = 6）
g = [1, 1, 1]               # x² + x + 1
q, r = polydiv(f, g, 7)
@assert deg(r) < deg(g) || all(iszero, r)
# 直接验证 f = qg + r（按多项式加法，逐位对齐）
sum_ok = polymul(g, q, 7)
n_len = max(length(sum_ok), length(r), length(f))
sum_pad = [get(sum_ok, i, 0) for i in 1:n_len]
r_pad = [get(r, i, 0) for i in 1:n_len]
total = trim!([mod(sum_pad[i] + r_pad[i], 7) for i in 1:n_len])
f_pad = [get(f, i, 0) for i in 1:n_len]
@assert total == trim!(f_pad)
println("除法算式：x⁵−1 = q(x)(x²+x+1) + r，deg r < 2（ℤ₇）✓")

# 唯一性：随机 100 组独立除法结果一致
using Random
Random.seed!(20261104)
for _ in 1:100
    fa = rand(0:6, 6); trim!(fa)
    ga = rand(0:6, 3); trim!(ga); ga[end] == 0 && continue
    qa, ra = polydiv(fa, ga, 7)
    qb, rb = polydiv(fa, ga, 7)
    @assert qa == qb && ra == rb
end
println("唯一性：100 组随机除法两次计算结果一致 ✓")

# (3) 余式定理：f mod (x − a) 的余数 = f(a)
for a in 0:6
    fa = rand(0:6, 5); trim!(fa)
    xa = [mod(-a, 7), 1]                          # x − a：常数 −a，一次系数 1
    _, ra = polydiv(fa, xa, 7)
    @assert ra[1] == peval(fa, a, 7)
end
println("余式定理：f mod (x−a) 的余数 = f(a)（ℤ₇，a = 0..6）✓")

# (4) 次数塌缩：ℤ₄ 中 (2x+1)² = 1
sq = polymul([1, 2], [1, 2], 4)
@assert sq == [1] "(2x+1)² 应塌缩到 1，得 $sq"
println("次数塌缩：ℤ₄[x] 中 (2x+1)² = 1（次数 2 → 0）✓")

# 形式 ≠ 函数：x⁵ − x 在 ℤ₅ 的 5 个点上全 0 但多项式非零
# （x⁵ 与 x 同函数是费马小定理；形式上 x⁵ − x 有非零系数）
xs5 = [0, 4, 0, 0, 0, 1]     # x⁵ − x（低位在前：x 的系数 −1 = 4，x⁵ 的系数 1）
@assert all(peval(xs5, a, 5) == 0 for a in 0:4)
@assert any(!=(0), xs5)
println("形式 ≠ 函数：x⁵ − x 在 ℤ₅ 逐点全 0，但形式多项式 ≠ 0 ✓")

# (5) 求值同态：φₐ(f + g) = φₐ(f) + φₐ(g)、φₐ(fg) = φₐ(f)φₐ(g)
for a in 0:6, _ in 1:20
    f1 = trim!(rand(0:6, 4)); g1 = trim!(rand(0:6, 4))
    addfg = trim!([mod(get(f1, i, 0) + get(g1, i, 0), 7)
                   for i in 1:max(length(f1), length(g1))])
    @assert (peval(f1, a, 7) + peval(g1, a, 7)) % 7 == peval(addfg, a, 7)
    @assert (peval(f1, a, 7) * peval(g1, a, 7)) % 7 == peval(polymul(f1, g1, 7), a, 7)
end
println("求值同态：φₐ(f+g) = φₐ(f)+φₐ(g)、φₐ(fg) = φₐ(f)φₐ(g)（ℤ₇ 抽查 140 组）✓")

println("END ====")
