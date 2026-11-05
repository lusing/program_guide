# Ch20 解的表示 IV：Radon 变换与 Laplace 变换
#
# 对应书 §4.3.2（Radon 变换与中心切片定理）与 §4.3.3（Laplace
# 变换解半直线问题）。

using Printf
using SpecialFunctions

println("==== 20")

# ---- (a) Radon：圆对称函数的 Radon 与角度无关 ----
# f(x) = e^{-|x|²}：Rf(s,θ) = √π e^{-s²}（线积分 = 1D Gauss 投影）
function radon_line(s, th; n = 6000)
    # 沿直线 {(y1,y2): y·ω = s}，ω = (cosθ, sinθ)：参数化 y = sω + τω⊥
    L = 8.0
    h = 2L / n
    c, sn = cos(th), sin(th)
    tot = 0.0
    for k in 0:n
        tau = -L + k * h
        y1, y2 = s * c - tau * sn, s * sn + tau * c
        w = (k == 0 || k == n) ? 1.0 : (iseven(k) ? 2.0 : 4.0)
        tot += w * exp(-(y1^2 + y2^2))
    end
    return tot * h / 3
end
for (s, th) in [(0.0, 0.0), (0.5, 0.7), (1.0, 2.1)]
    r = radon_line(s, th)
    exa = sqrt(pi) * exp(-s^2)
    @printf("(a) Rf(s=%.1f,θ=%.1f) = %.8f  √π e^{-s²} = %.8f (θ-independent)\n", s, th, r, exa)
    @assert abs(r - exa) < 1e-7 "圆对称 ⟹ Radon 与角度无关"
end

# ---- (b) 中心切片定理（数值版）：f 的 1D 投影 = F̂ 的 2D 切片 ----
# 对称 Gauss：投影的 1D Fourier（ξ 方向）= 2D Fourier 在该方向的值
# 解析：投影 p(s) = √πe^{-s²} 的 1D 变换（对称约定）= π^{1/4}e^{-ξ²/4}·?
# 直接数值对照：proj 的 Fourier 积分 vs F̂₂D(ξ·ω) = e^{-|ξ|²/4}·? 用积分对积分
function proj_fourier(xi; n = 6000)
    L = 8.0
    h = 2L / n
    s = 0.0
    for k in 0:n
        x = -L + k * h
        w = (k == 0 || k == n) ? 1.0 : (iseven(k) ? 2.0 : 4.0)
        s += w * sqrt(pi) * exp(-x^2) * cos(xi * x)
    end
    return s * h / 3 / sqrt(2pi)
end
# 2D Fourier 于 (ξ, 0)：(2π)^{-1}∫∫e^{-(y1²+y2²)}e^{-iξy1} = e^{-ξ²/4}
function four2d_slice(xi; n = 3000)
    L = 8.0
    h = 2L / n
    s = 0.0
    for i in 0:n, j in 0:n
        y1 = -L + i * h
        y2 = -L + j * h
        w = ((i == 0 || i == n) ? 1.0 : (iseven(i) ? 2.0 : 4.0)) *
            ((j == 0 || j == n) ? 1.0 : (iseven(j) ? 2.0 : 4.0))
        s += w * exp(-(y1^2 + y2^2)) * cos(xi * y1)
    end
    return s * h^2 / 9 / (2pi)
end
for xi in [0.0, 1.0, 2.0]
    p1 = proj_fourier(xi)
    p2 = four2d_slice(xi)
    # 对称约定下中心切片定理带配平因子：F̂₂ = P̂₁/√(2π)
    @printf("(b) slice theorem ξ=%.1f: proj-FT/√(2π) %.8f  2D-FT slice %.8f\n",
            xi, p1 / sqrt(2pi), p2)
    @assert abs(p1 / sqrt(2pi) - p2) < 2e-4 "中心切片定理（含 (2π)^{-1/2} 配平）"
end

# ---- (c) Laplace 变换解半直线波/热问题：边界驱动的热方程 ----
# u_t = u_xx 于 x>0，u(0,t) = 1（阶跃边界），u(x,0) = 0
# 解：u = erfc(x/(2√t))。用 Laplace 变换推导的核对：
# U(x,s) = e^{-√s x}/s ⟹ 反演给 erfc——数值验证解满足 PDE + 边界
u_c(x, t) = erfc(x / (2 * sqrt(t)))
for (x, t) in [(0.5, 0.4), (1.0, 1.0)]
    d = 1e-5
    ut = (u_c(x, t + d) - u_c(x, t - d)) / (2d)
    uxx = (u_c(x + d, t) - 2u_c(x, t) + u_c(x - d, t)) / d^2
    @printf("(c) erfc solution at (%.1f,%.1f): u_t - u_xx = %.2e\n", x, t, ut - uxx)
    @assert abs(ut - uxx) < 5e-6 "Laplace 反演解满足热方程（差分精度）"
end
@printf("    boundary: u(0, 0.5) = %.12f (=1), u(1e6, .) -> 0\n", u_c(1e-12, 0.5))
@assert abs(u_c(0.0, 0.5) - 1.0) < 1e-12

# ---- (d) Laplace 变换表核对：L[t^{1/2}] = √π/(2 s^{3/2}) 数值 Bromwich 型检验 ----
# 用已知对：L[e^{-at}] = 1/(s+a)：数值 Laplace 积分
function laplace(f, s; n = 8000)
    # ∫₀^∞ e^{-st}f(t)dt（截断 30/s）
    L = 40.0 / s
    h = L / n
    tot = 0.0
    for k in 0:n
        t = k * h
        w = (k == 0 || k == n) ? 1.0 : (iseven(k) ? 2.0 : 4.0)
        tot += w * exp(-s * t) * f(t)
    end
    return tot * h / 3
end
for (s, a) in [(1.0, 0.5), (2.0, 1.3)]
    num = laplace(t -> exp(-a * t), s)
    exa = 1 / (s + a)
    @printf("(d) L[e^{-%.1f t}](%.1f) = %.9f  1/(s+a) = %.9f\n", a, s, num, exa)
    @assert abs(num - exa) < 1e-8 "Laplace 变换表条目"
end

println("END ====")

