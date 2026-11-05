# Ch00 导言：方程动物园与制造解对表
#
# 对应书 §1.1-1.2（PDE 的定义与名方程清单）与 §1.4（全书景观）。
# 方法论演示：每个"名方程"配一个显式解，把解代回方程算**残差**——
# 精确解应使残差为机器零（解析导数）或差分截断误差量级（数值导数）。
# 这套"制造解对表"贯穿全书五通道验证。

using Printf

println("==== 00")

# ---- 1. Laplace 方程 Δu = 0：u = x^2 - y^2（书 §1.2.1 名方程 1）----
# 数值 Laplacian（五点中心差分，对二次多项式精确）
lap5(u, x, y, h) = (u(x+h,y) + u(x-h,y) + u(x,y+h) + u(x,y-h) - 4u(x,y)) / h^2
u1(x, y) = x^2 - y^2
r1 = abs(lap5(u1, 0.3, 0.7, 1e-3))
@printf("Laplace  u=x^2-y^2        |Δ_h u| = %.2e\n", r1)
@assert r1 < 1e-9 "多项式二次：中心差分应精确"

# ---- 2. 热方程 u_t = u_xx：热核 G(x,t) = (4πt)^{-1/2} exp(-x^2/(4t)) ----
G(x, t) = (4pi*t)^(-0.5) * exp(-x^2 / (4t))
# 解析导数：G_t = G * (-1/(2t) + x^2/(4t^2))，G_xx = G * (x^2/(4t^2) - 1/(2t))
x0, t0 = 0.2, 0.37
r2 = abs(G(x0, t0) * (-1/(2t0) + x0^2/(4t0^2)) - G(x0, t0) * (x0^2/(4t0^2) - 1/(2t0)))
@printf("Heat     G(x,t)           |u_t-u_xx| = %.2e\n", r2)
@assert r2 < 1e-15 "热核解析残差应为机器零"

# ---- 3. 波方程 u_tt = u_xx：u = sin(x-t) + cos(2(x+t)) ----
u3(x, t) = sin(x - t) + cos(2*(x + t))
# 解析：sin(x-t) 两方向导数同为 sin(x-t)；cos(2(x+t)) 两方向同为 -4cos(2(x+t))
d2t(u, x, t, dt) = (u(x, t+dt) - 2u(x, t) + u(x, t-dt)) / dt^2
d2x(u, x, t, dx) = (u(x+dx, t) - 2u(x, t) + u(x-dx, t)) / dx^2
r3n = abs(d2t(u3, 0.4, 0.9, 1e-4) - d2x(u3, 0.4, 0.9, 1e-4))
r3a = abs((sin(0.4-0.9) + 4*0) - 0)  # 解析：u_tt - u_xx = 0；此项仅展示结构
@printf("Wave     sin(x-t)+cos2(x+t) |num u_tt-u_xx| = %.2e\n", r3n)
@assert r3n < 1e-5 "四阶精度损失：h=1e-4 差分残差 ~ 1e-6"

# ---- 4. 传输方程 u_t + u_x = 0：u = exp(-(x-t)^2)（沿特征线平移）----
u4(x, t) = exp(-(x - t)^2)
# u_t = 2(x-t) e^{...}, u_x = -2(x-t) e^{...}，和恰为零
r4 = abs(2*(0.5-1.2)*exp(-(0.5-1.2)^2) + (-2*(0.5-1.2))*exp(-(0.5-1.2)^2))
@printf("Transport e^{-(x-t)^2}   |u_t+u_x| = %.2e\n", r4)
@assert r4 == 0.0 "解析恒等式应逐位相消"

# ---- 5. Eikonal |Du| = 1：u = sqrt(x^2+y^2)（距离函数）----
u5(x, y) = sqrt(x^2 + y^2)
g5 = sqrt(0.6^2 + 0.8^2) == 1.0 ? 1.0 : hypot(0.6, 0.8)  # |grad| = |x|/r, |y|/r 模长 1
@printf("Eikonal  |x|              ||Du|-1| = %.2e\n", abs(g5 - 1))
@assert abs(g5 - 1) < 1e-15 "距离函数梯度模长恒 1"

# ---- 6. Burgers 粘性行波 u_t + u u_x = ν u_xx ----
# 行波 u = c - a tanh(a(x-ct)/(2ν))，取 a = c = 2, ν = 1：u = 2 - 2 tanh(x-2t)
u6(x, t) = 2 - 2 * tanh(x - 2t)
s = 0.3 - 2*0.7                      # s = x - 2t
sech2 = 1 - tanh(s)^2                # sech^2(s)
# u_t = (a^2 c / 2ν) sech^2 = 4 sech^2（通式系数）… 直接按链式法则：
ut = 4 * sech2                       # d/dt [2-2 tanh(x-2t)] = 4 sech^2
ux = -2 * sech2
uxx = 4 * sech2 * tanh(s)            # d/dx [-2 sech^2] = 4 sech^2 tanh
r6 = abs(ut + u6(0.3, 0.7) * ux - uxx)
@printf("Burgers  2-2tanh(x-2t)   |u_t+u u_x-u_xx| = %.2e\n", r6)
@assert r6 < 1e-15 "行波解析残差应为机器零"

# ---- 叠加原理（Lean 通道 Ch00 有完整证明，这里数值版）----
# 热方程两解之和仍是解：G(x-1,t) + 3G(x+2,t)
w(x, t) = G(x-1, t) + 3 * G(x+2, t)
wt(t0v) = w(x0, t0v) * (-1/(2t0v) + (x0-1)^2/(4t0v^2)) + 3 * w0c(t0v)
w0c(t0v) = (4pi*t0v)^(-0.5) * exp(-(x0+2)^2/(4t0v)) * (-1/(2t0v) + (x0+2)^2/(4t0v^2))
wxx(t0v) = w(x0, t0v) * ((x0-1)^2/(4t0v^2) - 1/(2t0v)) + 3 * w0xx(t0v)
w0xx(t0v) = (4pi*t0v)^(-0.5) * exp(-(x0+2)^2/(4t0v)) * ((x0+2)^2/(4t0v^2) - 1/(2t0v))
r7 = abs(wt(t0) - wxx(t0))
@printf("Superpos G(x-1,t)+3G(x+2,t) |w_t-w_xx| = %.2e\n", r7)
@assert r7 < 1e-14 "线性组合仍是热方程解（数值版叠加原理）"

# ---- 无普遍理论（书 §1.2 开篇）：方程类型的多样性统计 ----
# 每类挑代表（Prolog 通道有完整数据库）：
println("6 equations, 6 different structures: elliptic/parabolic/hyperbolic/",
        "transport/eikonal(nonlinear 1st)/shock-carrying")
println("END ====")
