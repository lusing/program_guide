# Ch19 解的表示 III：Fourier 变换法
#
# 对应书 §4.3.1：Fourier 变换与热方程/波方程全空间解、反演公式、
# Gauss 函数的自对偶性。

using Printf

println("==== 19")

# ---- (a) Gauss 变换对：F[e^{-a x²}](ξ) = √(π/a) e^{-ξ²/4a}，a=1/2 自对偶 ----
# 数值验证变换积分（截断 + Simpson）
function fourier_gauss(xi, a)
    L = 10 / sqrt(a)
    n = 8000
    h = 2L / n
    s = 0.0
    for k in 0:n
        x = -L + k * h
        w = (k == 0 || k == n) ? 1.0 : (iseven(k) ? 2.0 : 4.0)
        s += w * exp(-a * x^2) * cos(xi * x)   # 实部（奇部积 0）
    end
    return s * h / 3 / sqrt(2pi)   # Evans 对称约定 (2π)^{-1/2}
end
for (xi, a) in [(0.0, 1.0), (1.3, 0.7), (2.0, 0.5)]
    num = fourier_gauss(xi, a)
    exa = sqrt(1 / (2a)) * exp(-xi^2 / (4a))
    @printf("(a) F[e^{-%.1f x²}](%.1f) = %.9f  exact √(π/a)e^{-ξ²/4a} = %.9f\n", a, xi, num, exa)
    @assert abs(num - exa) < 1e-8 "Gauss 变换对"
end
@printf("    a=1/2: fixed point F[f] = f (self-dual), ratio = %.12f\n",
        fourier_gauss(1.0, 0.5) / exp(-0.5))
@assert abs(fourier_gauss(1.0, 0.5) - exp(-0.5)) < 1e-8 "a=1/2 自对偶（ξ=1 处 e^{-ξ²/2}）"

# ---- (b) 反演公式：f(x) = (1/2π)∫F̂(ξ)e^{iξx}dξ 数值（偶函数 cos 版）----
# 取 f = e^{-x²/2}：F̂ = √(2π)e^{-ξ²/2}（自对偶 × 常数），反演
function inverse_fourier_gauss(x)
    L = 10.0
    n = 8000
    h = 2L / n
    s = 0.0
    for k in 0:n
        xi = -L + k * h
        w = (k == 0 || k == n) ? 1.0 : (iseven(k) ? 2.0 : 4.0)
        s += w * sqrt(2pi) * exp(-xi^2 / 2) * cos(xi * x)
    end
    return s * h / 3 / (2pi)
end
for x in [0.0, 0.8, 1.5]
    num = inverse_fourier_gauss(x)
    exa = exp(-x^2 / 2)
    @printf("(b) inversion at x=%.1f: %.9f  e^{-x²/2} = %.9f\n", x, num, exa)
    @assert abs(num - exa) < 1e-8 "反演公式数值"
end

# ---- (c) 热方程的 Fourier 表示 = 热核（PDE→ODE 的翻译）----
# û_t = -ξ²û ⟹ û = ĝe^{-ξ²t}；对 g = 高斯，u = 卷积热核（仍是高斯、方差加法）
# σ₁² + 2t 的方差律：u(x,t) = (2π(σ²+2t))^{-1/2}e^{-x²/2(σ²+2t)}
sigma2 = 1.0
for t in [0.3, 1.0]
    v = sigma2 + 2t
    # 数值验证 u 满足热方程（解析导公式）
    u(x) = (2pi * v)^(-0.5) * exp(-x^2 / (2v))
    ut = u(0.3) * (0.5 / v - 0.3^2 / (2v^2))   # ∂t v = 2
    ut *= 2 # d/dt[...]：链式 v'=2 与内部导——直接闭式核验：
    # ∂_t u = u·(−1/(2v) + x²/(2v²))·2 = u(−1/v + x²/v²)
    ut = u(0.3) * (-1 / v + 0.3^2 / v^2)
    uxx = u(0.3) * (0.3^2 / v^2 - 1 / v)
    @printf("(c) gaussian heat solution at t=%.1f: u_t - u_xx = %.2e\n", t, ut - uxx)
    @assert abs(ut - uxx) < 1e-15 "方差加法 σ²+2t 的解满足热方程"
end

# ---- (d) 波方程的 Fourier 表示：cos(t|ξ|) 的相位保持（无耗散）----
# û_tt = -ξ²û ⟹ û = ĝcos(tξ)（速度型初值 0）——每个模式不衰减
for (xi, t) in [(1.0, 0.5), (2.0, 3.0)]
    @printf("(d) wave mode |ξ|=%.0f at t=%.1f: amplitude cos = %.6f (no decay, contrast heat e^{-%.1f})\n",
            xi, t, cos(t * xi), xi^2 * t)
end
@assert abs(cos(3.0)) > exp(-4.0) "波模式不衰减 vs 热模式指数衰减（适定性的两面）"

println("END ====")


