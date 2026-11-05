# Ch06 热方程 I：基本解、卷积解与 Duhamel
#
# 对应书 §2.3.1：伸缩不变性 u(x,t) -> λ^? u(λx, λ²t) 导出热核
# Φ(x,t) = (4πt)^{-n/2} e^{-|x|²/4t}、归一性引理、初值问题卷积解
# u = Φ(·,t)*g、非齐次 Duhamel 公式。

using Printf

println("==== 06")

# ---- (a) 热核性质：n 维归一性 + 标度律 ----
Phi1(x, t) = (4pi * t)^(-0.5) * exp(-x^2 / (4t))
# 归一性：截断 Simpson + 解析尾段（Gauss 尾 erf 闭式）
using SpecialFunctions
for t in [0.1, 1.0, 5.0]
    L = 10 * sqrt(t)
    n = 4000
    h = 2L / n
    s = 0.0
    for k in 0:n
        global x = -L + k * h
        w = (k == 0 || k == n) ? 1.0 : (iseven(k) ? 2.0 : 4.0)
        global s += w * Phi1(x, t)
    end
    global s *= h / 3
    tail = 1 - erf(L / (2 * sqrt(t)))   # 尾段 2∫_L^∞
    @printf("(a) t=%.1f: integral %.12f + tail %.12f = %.12f\n", t, s, tail, s + tail)
    @assert abs(s + tail - 1) < 1e-10 "热核归一性（书引理）"
end
# 标度律：Φ(λx, λ²t) = λ^{-1}Φ(x,t)（1D；n 维是 λ^{-n}）
lam = 3.0
x0, t0 = 0.7, 2.0
@printf("    scaling: Phi(lx, l^2 t) = %.12e  l^-1 Phi(x,t) = %.12e\n",
        Phi1(lam * x0, lam^2 * t0), Phi1(x0, t0) / lam)
@assert abs(Phi1(lam * x0, lam^2 * t0) - Phi1(x0, t0) / lam) < 1e-15 * Phi1(x0, t0)

# ---- (b) 卷积解：u(x,t) = ∫Φ(x-y,t) g(y) dy ----
# g = 阶梯（间断初值）：解是误差函数形状——磨光瞬时发生。
# 坑账：跳变点正落在核峰中心时 Simpson 在间断处降阶——积分必须
# 以跳点为端点分段（simpson_split 在 0 处断开）。
g_step(y) = y < 0 ? 1.0 : 0.0
# 左段端点 y=0 须取左极限 1（右值 0 会造成 h/3·Φ(0) ≈ 2e-3 的缺口）
g_stepL(y) = y <= 0 ? 1.0 : 0.0
function simpson_seg(f, a, b, n)
    h = (b - a) / n
    s = 0.0
    for k in 0:n
        y = a + k * h
        w = (k == 0 || k == n) ? 1.0 : (iseven(k) ? 2.0 : 4.0)
        s += w * f(y)
    end
    return s * h / 3
end
function heat_solve(x, t, g; L = 8.0, n = 4000)
    half = div(n, 2)
    if g === g_step
        simpson_seg(y -> Phi1(x - y, t) * g_stepL(y), -L, 0, half) +
            simpson_seg(y -> Phi1(x - y, t) * g(y), 0, L, half)
    else
        simpson_seg(y -> Phi1(x - y, t) * g(y), -L, L, n)
    end
end
# 阶梯初值的闭式解：u = ½ erfc(x/(2√t))
for (x, t) in [(0.0, 0.04), (0.3, 0.04), (0.0, 1.0), (-0.5, 0.25)]
    num = heat_solve(x, t, g_step)
    exa = 0.5 * erfc(x / (2 * sqrt(t)))
    @printf("(b) step data x=%+.1f t=%.2f: conv %.10f  ½erfc %.10f  |d|=%.1e\n",
            x, t, num, exa, abs(num - exa))
    @assert abs(num - exa) < 1e-8 "阶梯初值热传导 = ½erfc(x/2√t)"
end

# t→0 极限回到 g（热核逼近恒等）：中心点
for t in [0.1, 0.01, 0.001]
    u = heat_solve(0.0, t, g_step, L = 8 + 10 * sqrt(t))
    @printf("    t=%.3f: u(0,t) = %.9f -> g(0-) = 1（半点值 ½）\n", t, u)
end
@assert abs(heat_solve(0.0, 0.001, g_step) - 0.5) < 1e-3 "间断点半点值"

# ---- (c) 无穷传播速度：紧支初值，远处瞬间变正 ----
g_compact(y) = abs(y) < 1 ? 1.0 : 0.0
xfar, tfar = 5.0, 0.01
ufar = heat_solve(xfar, tfar, g_compact, L = 30)
@printf("(c) compact data: u(5.0, 0.01) = %.3e (positive! infinite speed)\n", ufar)
@assert ufar > 0 "紧支初值的解在支集外立刻为正（与波方程的有限传播对比）"

# ---- (d) Duhamel：u(x,t) = ∫₀ᵗ ∫Φ(x-y, t-s) f(y,s) dy ds ----
# 制造解：f(x,t) = sin(x)：u(x,t) = (1 - e^{-t}) sin x 满足 u_t - u_xx = sin x
# 数值 Duhamel（内层 Gauss 截断 Simpson，外层 Simpson）
function duhamel_heat(x, t; nT = 200, nX = 2000)
    hs = t / nT
    tot = 0.0
    for kT in 0:nT
        s = kT * hs
        wT = (kT == 0 || kT == nT) ? 1.0 : (iseven(kT) ? 2.0 : 4.0)
        tau = t - s
        # τ→0 时内层卷积 → f(x)（核逼近 δ），显式取极限避免 0^{-1/2} 奇异
        inner = kT == nT ? sin(x) :
                begin
                    L = abs(x) + 10 * sqrt(tau)   # 截断以核峰 x 为中心（坑：以 0 为中心
                    hx = 2L / nX                  # 会砍掉右尾，τ 小时差到 1e-2）
                    sx = 0.0
                    for kX in 0:nX
                        y = -L + kX * hx
                        wx = (kX == 0 || kX == nX) ? 1.0 : (iseven(kX) ? 2.0 : 4.0)
                        sx += wx * Phi1(x - y, tau) * sin(y)
                    end
                    sx * hx / 3
                end
        tot += wT * inner
    end
    return tot * hs / 3
end
for (x, t) in [(0.5, 1.0), (1.0, 2.0)]
    num = duhamel_heat(x, t)
    exa = (1 - exp(-t)) * sin(x)
    @printf("(d) Duhamel x=%.1f t=%.1f: num %.9f  exact %.9f  |d|=%.1e\n",
            x, t, num, exa, abs(num - exa))
    @assert abs(num - exa) < 5e-6 "Duhamel 制造解对账（注意 τ→0 处奇异，内层截断随 √τ 收缩）"
end

println("END ====")
