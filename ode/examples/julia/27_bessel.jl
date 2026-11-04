println("==== 27 bessel")

# 第 27 章：Bessel——级数、零点、递推、Fourier-Bessel（全级数自实现，
# 不依赖外部包：J₀/J₁ 用 24 项级数，零点用二分）。

# --- (a) J_0 / J_1 级数（24 项，|x| ≤ 10 内双精度收敛）---
function j0_series(x; N = 24)
    s = 0.0
    term = 1.0
    for k in 0:N
        k == 0 || (term *= -(x / 2)^2 / (k * k))
        s += term
    end
    s
end
function j1_series(x; N = 24)
    s = 0.0
    term = x / 2
    s += term
    for k in 1:N
        term *= -(x / 2)^2 / (k * (k + 1))
        s += term
    end
    s
end
# 级数与三项递推（J₀/J₁ 生成 J₂）自查：J₂ = (2/x)J₁ − J₀
# 对照书值：J0(1) = 0.7651976865, J1(1) = 0.4400505857（文献常数）
@assert abs(j0_series(1.0) - 0.7651976865579666) < 1e-12 "J₀(1) 文献值"
@assert abs(j1_series(1.0) - 0.4400505857449335) < 1e-12 "J₁(1) 文献值"
@assert abs(j0_series(5.0) - (-0.1775967713143383)) < 1e-10 "J₀(5) 文献值"
println("J₀/J₁ 级数：J₀(1) = 0.76520、J₁(1) = 0.44005、J₀(5) = −0.17760 ✓")

# --- (b) 方程残差：x²y'' + xy' + x²y = 0 对 J₀ 数值核对 ---
for x in [0.5, 2.0, 5.0]
    h = 1e-4
    ypp = (j0_series(x + h) - 2 * j0_series(x) + j0_series(x - h)) / h^2
    yp = (j0_series(x + h) - j0_series(x - h)) / (2h)
    @assert abs(x^2 * ypp + x * yp + x^2 * j0_series(x)) < 1e-5 "J₀ 满足 Bessel 方程（差商 O(h²)）"
end
println("J₀ 数值代入 x²y″ + xy′ + x²y = 0 残差 < 1e-4（差商精度内）")

# --- (c) 零点：首零点 2.4048，相邻差 → π ---
function bisect_root(f, a, b)
    for _ in 1:200
        m = (a + b) / 2
        if f(a) * f(m) <= 0
            b = m
        else
            a = m
        end
    end
    (a + b) / 2
end
zeros0 = Float64[]
x = 1.0
prev = j0_series(1.0)
while length(zeros0) < 6
    global x += 0.02
    now = j0_series(x)
    if prev * now < 0
        push!(zeros0, bisect_root(j0_series, x - 0.02, x))
    end
    global prev = now
end
@assert abs(zeros0[1] - 2.4048255577) < 1e-5 "j_{0,1} = 2.40483"
@assert abs(zeros0[2] - 5.5200781103) < 1e-4 "j_{0,2} = 5.52008"
gaps = [zeros0[i+1] - zeros0[i] for i in 1:5]
@assert gaps[end] > 3.10 && gaps[end] < 3.16 "相邻差 → π"
println("J₀ 零点：", round.(zeros0; digits=4), "（相邻差 → π）")

# --- (d) 递推：J_{ν-1} + J_{ν+1} = (2ν/x)J_ν，取 ν=1：J₀ + J₂ = 2J₁/x ---
j2(x) = 2 * j1_series(x) / x - j0_series(x)   # 定义 J₂
for x in [2.3, 3.7, 6.0]
    lhs = j0_series(x) + j2(x)
    rhs = 2 * 1 / x * j1_series(x)
    @assert abs(lhs - rhs) < 1e-10 "递推（ν=1）恒等——按定义平凡成立"
    # 更实质：J₂ 的级数直接算 vs 递推生成
end
# J₂ 级数独立算
function j2_series(x; N = 24)
    s = 0.0
    term = (x / 2)^2 / 2
    s += term
    for k in 1:N
        term *= -(x / 2)^2 / (k * (k + 2))
        s += term
    end
    s
end
for x in [2.3, 3.7, 6.0]
    @assert abs(j2_series(x) - j2(x)) < 1e-10 "J₂ 级数 vs 递推生成一致"
end
println("递推：J₂（级数独立算）= (2/x)J₁ − J₀ ✓（三组 x）")

# --- (e) Fourier-Bessel：f(x) = 1 - x² 在 J₀(j_n x) 基上（[0,1]） ---
a = Float64[]
for n in 1:3
    jn = zeros0[n]
    xs = range(0, 1; length = 20001)
    h = 1 / 20000
    Ival = sum(xi * (1 - xi^2) * j0_series(jn * xi) for xi in xs[2:end-1]) * h
    push!(a, 2 * Ival / j1_series(jn)^2)
end
recon(x) = sum(a[n] * j0_series(zeros0[n] * x) for n in 1:3)
@assert abs(recon(0.3) - (1 - 0.09)) < 0.15 "三项 Fourier-Bessel 部分和"
println("Fourier-Bessel：前 3 项系数 = ", round.(a; digits=4), "，重构 f(0.3) ≈ 0.91")

println("END ====")
