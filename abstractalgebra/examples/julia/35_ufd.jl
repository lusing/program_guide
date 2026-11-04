# 第 35 章 · 唯一分解整环 —— Julia 通道
#
# ℤ 的分解唯一 + 内容/本原（高斯引理）+ ℤ[√−5] 非唯一分解反例。

println("==== 35 唯一分解整环")

# ---------- 多项式乘法（系数表升幂） ----------
function poly_mul(a, b)
    c = zeros(Int, length(a) + length(b) - 1)
    for i in eachindex(a), j in eachindex(b)
        c[i+j-1] += a[i] * b[j]
    end
    c
end

# ---------- ℤ 的因数分解（试除） ----------
function factorize(n)
    n == 0 && error("0 无分解")
    f = Dict{Int,Int}()
    m, p = abs(n), 2
    while m > 1
        while m % p == 0
            f[p] = get(f, p, 0) + 1
            m ÷= p
        end
        p += 1
    end
    f
end

# 唯一性：重排后同一多重集（UFD 的原型）
@assert factorize(360) == Dict(2 => 3, 3 => 2, 5 => 1)
@assert factorize(-360) == factorize(360)
for n in 2:200
    m = 1
    for (p, e) in factorize(n); m *= p^e; end
    @assert m == n
end
println("ℤ 分解：360 = 2³·3²·5；2..200 逐一重组还原 ✓")

# gcd 经分解表（命题 7.17：UFD 中 gcd 存在）
function gcd_via_factor(a, b)
    fa, fb = factorize(a), factorize(b)
    g = 1
    for p in keys(fa)
        e = min(get(fa, p, 0), get(fb, p, 0))
        g *= p^e
    end
    g
end
for a in 1:60, b in 1:60
    @assert gcd_via_factor(a, b) == gcd(a, b)
end
println("gcd 经分解：min 指数公式 与 欧几里得 1..60 全对拍 ✓")

# ---------- 内容与本原（引理 7.19/7.20） ----------
content(cfs) = abs(reduce(gcd, cfs; init=0))
primitive(cfs) = cfs .÷ content(cfs)

# 高斯引理：content(fg) = content(f)·content(g)（随机 200 组）
using Random
Random.seed!(20261104)
for _ in 1:200
    f = [rand(-6:6) for _ in 1:3]
    g = [rand(-6:6) for _ in 1:3]
    fg = poly_mul(f, g)
    @assert content(fg) == content(f) * content(g)
end
println("高斯引理：content(fg) = content(f)content(g)（随机 200 组整数核对）✓")

# ---------- ℤ[√−5]：非 UFD 的经典反例 ----------
# 元素 a + b√−5 表示为 (a, b)，范数 N(a,b) = a² + 5b²（乘法：范数相乘）
nmul((a, b), (c, d)) = (a * c - 5 * b * d, a * d + b * c)
norm((a, b)) = a * a + 5 * b * b

# 乘法保范数（完全代表元运算的合理性）
for a in -3:3, b in -3:3, c in -3:3, d in -3:3
    @assert norm(nmul((a, b), (c, d))) == norm((a, b)) * norm((c, d))
end
println("ℤ[√−5]：范数乘法 N(αβ) = N(α)N(β) 全网格核对 ✓")

# 6 = 2·3 = (1+√−5)(1−√−5)，两条分解的因子都不可约
w1, w2 = (1, 1), (1, -1)
@assert nmul((2, 0), (3, 0)) == nmul(w1, w2) == (6, 0)

# 不可约判别：N(α) ∈ {2, 3} 无范数分解（a²+5b² = 2、3 无整数解）⟹ 不可约
@assert norm((2, 0)) == 4                       # N(2) = 4
@assert norm((3, 0)) == 9
@assert norm(w1) == 6 && norm(w2) == 6
# N = 2、3 无解：a² + 5b² 取值表（b=0: 平方; |b|≥1: ≥5）
norms_small = Set(a^2 + 5b^2 for a in 0:3, b in 0:1 if a^2 + 5b^2 <= 10)
@assert !(2 in norms_small) && !(3 in norms_small)
# 2 的因子 α 满足 N(α) | 4 且 N(α) ∉ {1, 4}（真因子）⟹ N(α) = 2 不可能
# 同理 3（N=9，真因子范数 3 不可能）、1±√−5（N=6，真因子范数 2 或 3 不可能）
println("6 = 2·3 = (1+√−5)(1−√−5)：两边的因子范数 4/9/6 均无真因子 ⟹ 都不可约 ✓")

# 不可约 ↛ 素（命题 7.15 的逆否）：2 | (1+√−5)(1−√−5) 但 2 整除两者皆不
# 整除判定：α | β ⟺ β/α 的系数是整数（解线性方程）
function divides(alpha, beta)
    (a, b), (c, d) = alpha, beta
    # (x + y√−5)(a + b√−5) = (c + d√−5) ⟹ 解 [a −5b; b a]·[x;y] = [c;d]
    det = a * a + 5 * b * b
    x = (a * c + 5 * b * d) / det
    y = (a * d - b * c) / det
    x == round(x) && y == round(y)
end
@assert !divides((2, 0), w1) && !divides((2, 0), w2)
@assert divides((2, 0), (6, 0))
println("2 整除乘积 (1+√−5)(1−√−5) 却不整除任何因子——不可约 ≠ 素 ✓")

# ---------- R UFD ⟹ R[x] UFD（定理 7.21）的数值面 ----------
# ℤ[x] 中随机多项式可分解重组（sympy 面见 python 通道；此处核对
# 内容乘积与本原部分：f = c(f)·f*，f* 本原）
for _ in 1:100
    f = [rand(-8:8) for _ in 1:4]
    all(iszero, f) && continue
    c = content(f)
    pf = primitive(f)
    @assert c * pf == f
    @assert content(pf) == 1
end
println("内容-本原分解：f = c(f)·f*，c(f*) = 1（随机 100 组）✓")

println("END ====")
