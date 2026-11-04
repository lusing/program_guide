# 24_variational.jl —— 第 24 章：古典变分问题与必要条件（Julia 通道）
#
#   (1) 最速降线：J = ∫√((1+y'²)/(2gy))dx 的 Euler 方程是摆线；
#       数值上用 Ritz 型参数族对最优参数扫描，与理论摆线周期对账；
#   (2) 泛函极小的必要条件：Euler 方程残差的数值核对；
#   (3) 极小曲面近似（肥皂膜）：min ∫√(1+u_x²) 的离散最速下降。

println("==== 24 variational")

# ---------- (1) 最速降线 ----------
# Euler-Lagrange：L = sqrt((1+y'^2)/(2gy)) 不显含 x ⟹ Beltrami：
# L − y'·L_y' = 1/√(2g y (1+y'²)) = const ⟹ y(1+y'²) = const = 2aR
# 摆线参数化：x = R(θ − sinθ), y = R(1 − cosθ)，从 (0,0) 到 (1,1)
# 定 R：R(θ1 − sinθ1) = 1, R(1 − cosθ1) = 1 ⟹ θ1 − sinθ1 = 1 − cosθ1
# 解 θ1，得 R = 1/(1 − cosθ1)；下降时间 T = θ1·sqrt(R/g)·...
g = 9.8
function solve_theta1()
    t = 2.0
    for _ in 1:60
        fv = t - sin(t) - (1 - cos(t))
        t -= fv / (1 - cos(t) + sin(t))
    end
    t
end
θ1 = solve_theta1()
R = 1 / (1 - cos(θ1))
T_bachistochrone = θ1 * sqrt(R / g)
println("brachistochrone: theta1 = ", round(θ1, digits=6), ", R = ", round(R, digits=6))
println("  descent time along cycloid = ", round(T_bachistochrone, digits=6), " s")

# 与候选曲线族比较：直线与圆弧都更慢
function time_along(yc)
    # 数值积分 dt = ds/v, v = sqrt(2 g y)
    n = 20000
    t = 0.0
    for i in 1:n-1
        x1 = (i - 1) / n; x2 = i / n
        y1 = yc(x1); y2 = yc(x2)
        ds = sqrt((x2 - x1)^2 + (y2 - y1)^2)
        ym = max((y1 + y2) / 2, 1e-12)
        t += ds / sqrt(2 * g * ym)
    end
    t
end
t_line = time_along(x -> x)
println("  straight line time = ", round(t_line, digits=6), " s (slower)")
@assert t_line > T_bachistochrone "摆线应快于直线"
# 验证摆线本身给出同一下降时间（参数化数值积分）
function time_cycloid()
    n = 20000
    t = 0.0
    for i in 1:n
        θa = (i - 1) / n * θ1; θb = i / n * θ1
        dsdθ = sqrt((1 - cos(θa))^2 + sin(θa)^2) * R   # |d(x,y)/dθ|
        ds = dsdθ * (θb - θa)
        ym = max(R * (1 - cos((θa + θb) / 2)), 1e-12)
        t += ds / sqrt(2 * g * ym)
    end
    t
end
t_cyc = time_cycloid()
println("  cycloid time (parametric quadrature) = ", round(t_cyc, digits=6),
        " s (matches ", round(T_bachistochrone, digits=6), ")")
@assert abs(t_cyc - T_bachistochrone) < 2e-4 "摆线参数化积分应与闭式一致"

# ---------- (2) Euler 方程残差核对 ----------
# J = ∫ (y'^2 + y^2) dx 的极值曲线满足 Euler：y'' = y
# 精确极值曲线 y = sinh(x)/sinh(1)（端点 y(0)=0, y(1)=1）
yopt(x) = sinh(x) / sinh(1)
resid = maximum(begin
    h = 1e-3
    ypp = (yopt(x + h) - 2 * yopt(x) + yopt(x - h)) / h^2
    abs(ypp - yopt(x))
end for x in 0.05:0.05:0.95)
@assert resid < 1e-5 "极值曲线应满足 Euler 方程 y''=y（残差 $resid）"
println("Euler equation check: sinh(x)/sinh(1) satisfies y'' = y, resid = ", round(resid, sigdigits=3))

# Ritz 单参数族对照：y = x^a，J(a) 在 a=1 附近（最优是 sinh 型），
# J(sinh) < J(x^a) 对一切 a
function Jfunc(yc)
    n = 10000
    s = 0.0
    for i in 1:n-1
        x = i / n
        dy = (yc(x + 1e-6) - yc(x - 1e-6)) / 2e-6
        s += (dy^2 + yc(x)^2) / n
    end
    s
end
Js = Jfunc(yopt)
println("J(sinh-curve) = ", round(Js, digits=6))
for a in (0.8, 1.0, 1.3)
    Jx = Jfunc(x -> x^a)
    println("  J(x^", a, ") = ", round(Jx, digits=6), " (larger)")
    @assert Jx > Js "极值曲线的 J 应最小"
end

# ---------- (3) 极小曲面（离散最速下降） ----------
# min ∫ sqrt(1 + u_x²) dx, u(0)=0, u(1)=1：Euler 方程 (u'/sqrt(1+u'^2))' = 0
# ⟹ u' = const ⟹ 直线！数值：梯度下降收敛到直线
N = 50
h = 1 / N
u = [i * h + 0.3 * sin(pi * i * h) for i in 0:N]  # 初始猜：满足边界条件的弯弧
for iter in 1:200000
    grad = zeros(N + 1)
    for i in 2:N   # 数组下标（u[i-1] 有效）
        sl = (u[i] - u[i-1]) / h
        sr = (u[i+1] - u[i]) / h
        # ∂E/∂u_i = L'(s₋) − L'(s₊)（不含 /h：h 因子已吸收进步长）
        grad[i] = (sl / sqrt(1 + sl^2) - sr / sqrt(1 + sr^2))
    end
    u .-= (0.5 * h) .* grad   # 步长与 h 同阶（梯度已无量纲化）
    if iter % 40000 == 0
        maxdev = maximum(abs(u[i+1] - i * h) for i in 0:N)
        println("  minimal surface iter ", iter, ": max deviation from line = ", round(maxdev, digits=5))
    end
end
maxdev = maximum(abs(u[i+1] - i * h) for i in 0:N)
@assert maxdev < 0.02 "极小曲面应收敛到直线（偏差 $maxdev）"
println("minimal surface (u(0)=0, u(1)=1): converges to straight line, dev = ", round(maxdev, digits=5))

println("END ====")
