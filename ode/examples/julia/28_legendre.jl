println("==== 28 legendre")

# 自带 Simpson 数值积分（不依赖 QuadGK 包）
function myquadgk(f, a, b; n = 200000)
    h = (b - a) / n
    s = f(a) + f(b)
    for i in 1:n-1
        s += (i % 2 == 0 ? 2 : 4) * f(a + i * h)
    end
    s * h / 3
end

# 第 28 章：Legendre 递推/正交、Hermite、单摆周期（椭圆积分）。

# --- (a) 三项递推生成 P0..P6（多项式 = 系数表，升幂）---
# P_{n+1} = ((2n+1)x P_n - n P_{n-1})/(n+1)
function legendre_coeffs(n)
    p = Vector{Vector{Float64}}(undef, n + 1)
    p[1] = [1.0]                       # P0
    if n >= 1
        p[2] = [0.0, 1.0]              # P1
    end
    for k in 1:(n-1)
        # P_{k+1}（下标 k+2）= ((2k+1) x P_k - k P_{k-1})/(k+1)
        a = vcat(0.0 .* p[k+1], 0.0)   # x·P_k
        a[1:length(p[k+1])] .+= 0.0
        xpk = vcat(0.0, p[k+1]) .* (2k + 1)
        l = length(p[k]) > length(xpk) ? length(p[k]) : length(xpk)
        xpk2 = vcat(xpk, zeros(l - length(xpk)))
        pk1 = vcat(p[k], zeros(l - length(p[k])))
        res = xpk2 .- k .* pk1
        push!(res, 0.0) # 保长
        res = res[1:l] ./ (k + 1)
        p[k+2] = res
    end
    p
end
P = legendre_coeffs(5)
@assert P[3] ≈ [-0.5, 0.0, 1.5] atol = 1e-14 "P2 = (3x²-1)/2"
@assert P[4] ≈ [0.0, -1.5, 0.0, 2.5] atol = 1e-14 "P3 = (5x³-3x)/2"
@assert P[5] ≈ [0.375, 0.0, -3.75, 0.0, 4.375] atol = 1e-13 "P4"
peval(c, x) = sum(c[i] * x^(i - 1) for i in 1:length(c))
@assert abs(peval(P[5], 0.5) - (35 * 0.5^4 - 30 * 0.5^2 + 3) / 8) < 1e-13 "P4(0.5)"
println("Legendre 递推：P₂/P₃/P₄ 系数与 Rodrigues 公式值一致")

# --- (b) 正交性：∫P_m P_n = 2/(2n+1) δ ---
for (m, n) in [(1, 3), (2, 4), (2, 3)]
    xs = range(-1, 1; length = 100001)
    h = 2 / 100000
    Ival = sum(peval(P[m], x) * peval(P[n], x) for x in xs[2:end-1]) * h
    @assert abs(Ival) < 1e-4 "正交（m≠n）"
end
xs = range(-1, 1; length = 100001)
h = 2 / 100000
I22 = sum(peval(P[3], x)^2 for x in xs[2:end-1]) * h
@assert abs(I22 - 2 / 5) < 1e-4 "∫P₂² = 2/5"
println("正交性：∫PₘPₙ = 0（m≠n），∫P₂² = 2/5 ✓")

# --- (c) Hermite 递推：H_{n+1} = 2xH_n - 2nH_{n-1} ---
function hermite_coeffs(n)
    h = Vector{Vector{Float64}}(undef, n + 1)
    h[1] = [1.0]
    if n >= 1
        h[2] = [0.0, 2.0]
    end
    for k in 1:(n-1)
        xhk = vcat(0.0, h[k+1]) .* 2.0
        l = max(length(h[k]), length(xhk))
        xhk2 = vcat(xhk, zeros(l - length(xhk)))
        hk1 = vcat(h[k], zeros(l - length(h[k])))
        h[k+2] = xhk2 .- (2k) .* hk1
    end
    h
end
H = hermite_coeffs(4)
@assert H[3] ≈ [-2.0, 0.0, 4.0] atol = 1e-14 "H₂ = 4x²-2"
@assert H[4] ≈ [0.0, -12.0, 0.0, 8.0] atol = 1e-14 "H₃ = 8x³-12x"
# 加权正交
xs = range(-6, 6; length = 200001)
h = 12 / 200000
I12 = sum(exp(-x^2) * peval(H[2], x) * peval(H[3], x) for x in xs[2:end-1]) * h
@assert abs(I12) < 1e-4 "Hermite 加权正交"
I22h = sum(exp(-x^2) * peval(H[3], x)^2 for x in xs[2:end-1]) * h
@assert abs(I22h - sqrt(pi) * 2^2 * 2) < 1e-2 "∫e^{-x²}H₂² = √π·2²·2!"
println("Hermite：递推 H₂/H₃ ✓，加权正交 ∫e^{−x²}H₂² = √π·8 ✓")

# --- (d) 单摆周期：T(θ₀) = 4√(L/g)K(sin(θ₀/2))，Simpson 数值 ---
K(k) = myquadgk(t -> 1 / sqrt(1 - k^2 * sin(t)^2), 0, pi / 2)
# 小幅：T/T₀ = 2K(k)/π ≈ 1 + θ₀²/16 + 11θ₀⁴/3072
for (th0, expect) in [(pi / 6, 1.0174), (pi / 2, 1.1803), (5pi / 6, 1.7622)]
    ratio = 2 * K(sin(th0 / 2)) / pi
    @assert abs(ratio - expect) < 5e-4 "单摆周期修正 θ₀ = $(round(th0; digits=3))"
end
println("单摆周期：T/T₀ = 2K(sin θ₀/2)/π：30°→1.017、90°→1.180、150°→1.760 ✓")

# --- (e) k→1 对数发散：K(0.9999) 很大 ---
@assert K(0.9999) > 5.5 "K(k) 对数发散（k→1；K(0.9999) ≈ 5.65 = ln(400/π) 量级）"
println("K(0.9999) = ", round(K(0.9999); digits=3), "（k→1 对数发散）")

println("END ====")

