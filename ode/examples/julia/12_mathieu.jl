println("==== 12 mathieu")
using LinearAlgebra

# 第 12 章：周期系数——Meissner 方程的平移矩阵 + Floquet 稳定性。

# --- (a) Meissner：u'' + (ω² + ε·s(x))u = 0，s = +1 (0..L/2), -1 (L/2..L) ---
# 单周期传播矩阵：两段常系数拼接
function meissner_T(omega, eps, L)
    k1 = sqrt(Complex(omega^2 + eps))      # 前半段
    k2 = sqrt(Complex(omega^2 - eps))      # 后半段（可为虚：ω² < ε 时双曲）
    # 每段的传播矩阵 P(t) = [[cos κt, sin κt/κ], [-κ sin κt, cos κt]]（κ 实）
    # κ 虚时用 cosh/sinh（κ = iμ：cos it = cosh t 等）
    half = L / 2
    P1 = seg_matrix(k1, half)
    P2 = seg_matrix(k2, half)
    P2 * P1      # 状态先过前半段 P₁，再过后半段：T = P₂P₁
end
function seg_matrix(k, t)
    if isreal(k) && real(k) > 0
        [cos(k * t) sin(k * t) / k; -k * sin(k * t) cos(k * t)]
    elseif isreal(k) && real(k) == 0
        [1.0 t; 0.0 1.0]
    else
        mu = sqrt(-k^2)            # k = iμ
        [cosh(mu * t) sinh(mu * t) / mu; mu * sinh(mu * t) cosh(mu * t)]
    end
end

T = meissner_T(1.0, 0.8, 2pi)
@assert abs(det(T) - 1.0) < 1e-12 "det T = 1（Abel）"
trT = T[1, 1] + T[2, 2]
println("Meissner(ω=1, ε=0.8)：tr T = ", round(trT; digits=6), "，|tr| > 2 ⟹ 不稳定（参数共振带内）")
@assert abs(trT) > 2

# --- (b) 数值 T：RK4 双基本解积分一个周期 ---
function rk4_2(f, x, y, yp, h)
    k1y, k1v = yp, f(x, y, yp)
    k2y, k2v = yp + h * k1v / 2, f(x + h / 2, y + h * k1y / 2, yp + h * k1v / 2)
    k3y, k3v = yp + h * k2v / 2, f(x + h / 2, y + h * k2y / 2, yp + h * k2v / 2)
    k4y, k4v = yp + h * k3v, f(x + h, y + h * k3y, yp + h * k3v)
    (y + h * (k1y + 2k2y + 2k3y + k4y) / 6, yp + h * (k1v + 2k2v + 2k3v + k4v) / 6)
end
function numeric_T(f, L; n = 24000)
    # 系数分段常数：按段积分（在跳跃点切分步长，RK4 每段内光滑）
    h = L / n
    y1, v1, y2, v2 = 1.0, 0.0, 0.0, 1.0
    x = 0.0
    for i in 0:(n-1)
        y1, v1 = rk4_2(f, x, y1, v1, h)
        y2, v2 = rk4_2(f, x, y2, v2, h)
        x += h
    end
    [y1 y2; v1 v2]
end
# 数值版也按两段走：前半 f₁、后半 f₂（跳跃点即网格点）
function numeric_T_meissner(omega, eps, L; n = 24000)
    n2 = div(n, 2)
    f1 = (x, y, v) -> -(omega^2 + eps) * y
    f2 = (x, y, v) -> -(omega^2 - eps) * y
    h = L / n
    y1, v1, y2, v2 = 1.0, 0.0, 0.0, 1.0
    x = 0.0
    for _ in 1:n2
        y1, v1 = rk4_2(f1, x, y1, v1, h)
        y2, v2 = rk4_2(f1, x, y2, v2, h)
        x += h
    end
    for _ in 1:n2
        y1, v1 = rk4_2(f2, x, y1, v1, h)
        y2, v2 = rk4_2(f2, x, y2, v2, h)
        x += h
    end
    [y1 y2; v1 v2]
end
Tnum = numeric_T_meissner(1.0, 0.8, 2pi)
maxdev = maximum(abs.(Tnum .- T))
@assert maxdev < 1e-9 "解析 T 与数值 T 应一致"
println("解析 T vs 数值 T 最大偏差 = ", maxdev)

# --- (c) 稳定带扫描：ω=1 固定，ε 扫 0..3，找第一不稳定带边界 ---
ome = 1.0
boundary_eps = Float64[]
prev_unstable = false
for eps in 0.0:0.005:3.0
    Tt = meissner_T(ome, eps, 2pi)
    tr = abs(Tt[1, 1] + Tt[2, 2])
    unstable = tr > 2 + 1e-9
    if prev_unstable != unstable
        push!(boundary_eps, eps)
        global prev_unstable = unstable
    end
end
# 理论（Meissner 微扰）：第一不稳定带宽 ~ ε ∈ (0, ω·4/π)? 边界由
# |cos(κ₁L/2)cosh(...)...| 决定；断言带存在且 ε=0 起始
@assert length(boundary_eps) >= 1 "至少一条带边界"
@assert boundary_eps[1] < 0.05 "第一带从 ε = 0 附近开始"
println("ω=1 第一不稳定带边界（ε）：", round.(boundary_eps[1:min(end,2)]; digits=3))

# --- (d) 指数增长率：λ₊ 的模 vs 数值轨道增长 ---
eps0 = 0.8
T0 = meissner_T(ome, eps0, 2pi)
lam = eigen(T0).values
mu_theory = log(maximum(abs.(lam))) / (2pi)
# 数值：10 个周期的增长（分段常系数）
y, v = 1.0, 0.0
h = 2pi / 2400
n2 = 1200
for _ in 1:10
    for i in 0:(n2-1)
        global (y, v) = rk4_2((x, yy, vv) -> -(ome^2 + eps0) * yy, i * h, y, v, h)
    end
    for i in 0:(n2-1)
        global (y, v) = rk4_2((x, yy, vv) -> -(ome^2 - eps0) * yy, (i + n2) * h, y, v, h)
    end
end
mu_num = log(sqrt(y^2 + v^2)) / (10 * 2pi)
@assert abs(mu_num - mu_theory) < 5e-3 "增长率 λ₊^{1/L} 应与数值一致"
println("增长率：理论 μ = ", round(mu_theory; digits=5), "，数值 μ = ", round(mu_num; digits=5))

println("END ====")
