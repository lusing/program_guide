# P05 习题篇 VI：抛物方程（书第 4 章 §4.1-4.2）
#
# 精选：4.1-4.8 型（边值问题：极值原理、唯一性、相似解）、
# 4.30-4.43 型（Cauchy 问题：Poisson 核、误差函数解、周期初值）。

using Printf
using SpecialFunctions

println("==== P05")

# ---- (a) 4.1 型：相似解 x/√t 组合（半直线热传导的 er f 解）----
# u_t = u_xx 于 x>0，u(0,t)=u₀，u(x,0)=0：u = u₀·erfc(x/(2√t))
u_a(x, t) = erfc(x / (2 * sqrt(t)))
for (x, t) in [(0.5, 0.25), (1.0, 1.0)]
    d = 1e-5
    ut = (u_a(x, t + d) - u_a(x, t - d)) / (2d)
    uxx = (u_a(x + d, t) - 2 * u_a(x, t) + u_a(x - d, t)) / d^2
    @printf("(a) erfc solution: u_t−u_xx = %.1e at (%.1f,%.2f)\n", ut - uxx, x, t)
    @assert abs(ut - uxx) < 5e-6 "半直线解（06 章理论在此应用）"
end
@printf("    boundary: u(0,t) = erfc(0) = %.12f\n", u_a(0.0, 0.5))
@assert u_a(0.0, 0.5) == 1.0

# ---- (b) 4.4 型：Cauchy 问题 + 周期初值（热核卷积 vs Fourier 模式衰减）----
# 初值 g = 1 + 0.5sin(3x)：解 = 1 + 0.5e^{−9t}sin(3x)
u_b(x, t) = 1 + 0.5 * exp(-9t) * sin(3x)
for (x, t) in [(0.7, 0.3), (2.0, 0.8)]
    d = 1e-5
    ut = (u_b(x, t + d) - u_b(x, t - d)) / (2d)
    uxx = (u_b(x + d, t) - 2 * u_b(x, t) + u_b(x - d, t)) / d^2
    @printf("(b) periodic: u_t−u_xx = %.1e at (%.1f,%.1f)\n", ut - uxx, x, t)
    @assert abs(ut - uxx) < 1e-6 "模式衰减（差分精度）"
end

# ---- (c) 4.5 型：逆问题不适定（01 章的抛物版习题）----
# 从 t=T 反推 t=0：模式放大 e^{k²T}
for k in [2.0, 5.0]
    amp = exp(k^2 * 0.1)
    @printf("(c) backward: k=%.0f amplification e^{k²·0.1} = %.1e\n", k, amp)
end
@assert exp(25 * 0.1) > 10 "反向放大爆炸（不适定）"

# ---- (d) 4.30 型：非齐次方程 Cauchy（Duhamel 热核）----
# u_t − u_xx = e^{−t}sin(x)（10 章制造解复现）：u = (1−e^{−t})·?
# 已验（06 章 Duhamel）：这里换新制造解 f = cos(x)·e^{−t}·1：
# 解 u = A(t)cos x：A' + A·1 = e^{−t}·? A'' ... 直接取 u = e^{−t}cos x：
# u_t − u_xx = −e^{−t}cos x + e^{−t}cos x = 0·?
# u = t·e^{−t}cos x 满足 u_t − u_xx = e^{−t}cos x
u_d(x, t) = t * exp(-t) * cos(x)
for (x, t) in [(0.4, 0.6), (1.0, 1.2)]
    d = 1e-5
    ut = (u_d(x, t + d) - u_d(x, t - d)) / (2d)
    uxx = (u_d(x + d, t) - 2 * u_d(x, t) + u_d(x - d, t)) / d^2
    r = ut - uxx - exp(-t) * cos(x)
    @printf("(d) source term: u_t−u_xx−f = %.1e at (%.1f,%.1f)\n", r, x, t)
    @assert abs(r) < 1e-6 "指数衰减源的模式解（差分）"
end

println("END ====")



