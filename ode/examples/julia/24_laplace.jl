println("==== 24 laplace")

# 第 24 章：Laplace 变换——数值变换、IVP 全流程、卷积定理。

# --- (a) 数值 Laplace：截断积分 vs 表值 ---
function laplace_num(f, s; T = 30.0, n = 200000)
    h = T / n
    s_val = sum(exp.(-s .* (collect(1:n-1) .* h)) .* f.((collect(1:n-1) .* h))) * h
    s_val + h / 2 * (f(0.0) + exp(-s * T) * f(T))
end
for (f, F, s) in [(t -> 1.0, s -> 1 / s, 2.0),
                  (t -> t^2, s -> 2 / s^3, 1.5),
                  (t -> exp(-t), s -> 1 / (s + 1), 2.0),
                  (t -> sin(2t), s -> 2 / (s^2 + 4), 1.2)]
    num = laplace_num(f, s)
    @assert abs(num - F(s)) / F(s) < 1e-6 "数值 Laplace vs 表值"
end
println("数值 Laplace：四个表项（1, t², e⁻ᵗ, sin2t）截断积分对照（< 1e-6）")

# --- (b) 例 A：y'' + 4y = cos 2t 共振 → y = t sin2t / 4 ---
ysol(t) = t * sin(2t) / 4
function rk4_2(f, x, y, yp, h)
    k1y, k1v = yp, f(x, y, yp)
    k2y, k2v = yp + h * k1v / 2, f(x + h / 2, y + h * k1y / 2, yp + h * k1v / 2)
    k3y, k3v = yp + h * k2v / 2, f(x + h / 2, y + h * k2y / 2, yp + h * k2v / 2)
    k4y, k4v = yp + h * k3v, f(x + h, y + h * k3y, yp + h * k3v)
    (y + h * (k1y + 2k2y + 2k3y + k4y) / 6, yp + h * (k1v + 2k2v + 2k3v + k4v) / 6)
end
t, y, yp = 0.0, 0.0, 0.0
h = 10.0 / 100000
for i in 0:99999
    global (y, yp) = rk4_2((t, y, v) -> cos(2t) - 4y, t, y, yp, h)
    global t += h
end
@assert abs(y - ysol(10.0)) < 1e-6 "共振解 t sin2t/4"
println("例 A 共振：y = t sin2t/4 与 RK4 一致（振幅线性增长）")

# --- (c) 例 B：y'' + 3y' + 2y = 1 → y = 1/2 - e^{-t} + e^{-2t}/2 ---
ysolB(t) = 0.5 - exp(-t) + exp(-2t) / 2
# 部分分式账：1/[s(s+1)(s+2)] = 1/2·1/s − 1/(s+1) + 1/2·1/(s+2)
# 反变换即上式。数值验证方程本身 + 端点值
for tt in [0.3, 1.7, 4.0]
    h2 = 1e-5
    ypp = (ysolB(tt + h2) - 2ysolB(tt) + ysolB(tt - h2)) / h2^2
    yp_ = (ysolB(tt + h2) - ysolB(tt - h2)) / 2h2
    @assert abs(ypp + 3 * yp_ + 2 * ysolB(tt) - 1.0) < 1e-4 "例 B 代入残差"
end
@assert ysolB(0.0) == 0.0
println("例 B：y = 1/2 − e⁻ᵗ + e⁻²ᵗ/2 零初值 + 方程残差核对 ✓")

# --- (d) 卷积定理：(f*g)(t) 的变换 = F·G ---
ft(t) = exp(-t)
gt(t) = t
conv(t) = t - exp(-t) * (t + 1) - 0 * t  # (e^-t * t)(t) = ∫₀ᵗ e^{-τ}(t-τ)dτ = t - 1 + e^{-t}
convf(t) = t - 1 + exp(-t)
# F(s) = 1/(s+1), G(s) = 1/s²：F·G = 1/(s²(s+1))
# L^{-1}[1/(s²(s+1))] = t - 1 + e^{-t}
for s in [1.3, 2.0]
    lhs = laplace_num(convf, s)
    rhs = 1.0 / (s^2 * (s + 1))
    @assert abs(lhs - rhs) / rhs < 1e-6 "卷积定理"
end
println("卷积定理：L{e⁻ᵗ∗t} = F·G = 1/(s²(s+1))（两点核对）")

println("END ====")
