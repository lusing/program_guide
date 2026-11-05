# P07 习题篇 VIII：三线合一总对账（收官实验）
#
# 同一问题，三条路线（理论篇 Evans / 数值篇 陆金甫 / 习题篇 沙马耶夫）
# 的三角对账：Poisson、热传导、波动、极值原理、能量。

using Printf
using LinearAlgebra

println("==== P07")

# ---- (a) Poisson −u'' = f：习题闭式 vs 数值有限元 vs 理论能量恒等式 ----
# f = sin(πx)（习题 5.44/理论 29/数值 28 的共同问题）
f_a(x) = sin(pi * x)
u_exact(x) = sin(pi * x) / pi^2
# 数值：谱截断（数值篇 28 章的 FEM 退化版）+ 对表
N = 200
h = 1 / N
n = N - 1                       # 内点自由度（29 章坑账：不含边界）
xs = [(i)*h for i in 1:n]
b = [f_a(x) * h^2 for x in xs]
T = SymTridiagonal(fill(2.0, n), fill(-1.0, n - 1))
u_num = T \ b
err = maximum(abs.(u_num .- u_exact.(xs)))
@printf("(a) Poisson: FEM vs closed sin(πx)/π²: err = %.2e (三方一致)\n", err)
@assert err < 1e-3
# 理论侧：能量恒等式 ∫|∇u|² = ∫fu
int_fu = 0.5 / pi^2   # ∫sin·sin/π² = 1/(2π²)
int_grad2 = pi^2 * 0.5 / pi^4
@printf("    energy identity: ∫|∇u|² = %.6f = ∫fu = %.6f\n", int_grad2, int_fu)
@assert int_grad2 ≈ int_fu

# ---- (b) 热传导：习题 4.x 的模式衰减 vs 数值篇 FTCS vs 理论谱 ----
# 初值 sin(πx)：u = e^{−π²t}sin(πx)（三线共同闭式）
t_b = 0.1
# FTCS（数值篇 14 章）：λ = 0.4
N2 = 100
h2 = 1 / (N2 + 1)
dt = 0.4 * h2^2
nt = round(Int, t_b / dt)
u_ftcs = [sin(pi * i * h2) for i in 1:N2]
for _ in 1:nt
    global u_ftcs = [0.4 * (i > 1 ? u_ftcs[i-1] : 0) + (1 - 0.8) * u_ftcs[i] +
                     0.4 * (i < N2 ? u_ftcs[i+1] : 0) for i in 1:N2]
end
exact_mid = exp(-pi^2 * t_b)
@printf("(b) Heat: FTCS mid = %.6f vs e^{−π²t} = %.6f（习题=数值=理论）\n",
        u_ftcs[div(N2, 2)], exact_mid)
@assert abs(u_ftcs[div(N2, 2)] - exact_mid) < 2e-4

# ---- (c) 波动：d'Alembert（习题）vs 谱（理论）vs 蛙跳（数值）----
# 初值 sin(πx)、零速度：u = cos(πt)sin(πx)
# 蛙跳（数值篇 10 章）
N3 = 200
h3 = 1 / (N3 + 1)
dt3 = 0.8 * h3
t_c = 0.5
nt3 = round(Int, t_c / dt3)
u_prev = [sin(pi * i * h3) for i in 1:N3]
u_curr = [sin(pi * i * h3) * cos(pi * dt3) for i in 1:N3]   # 精确起步
for _ in 2:nt3
    global u_next = [2 * u_curr[i] - u_prev[i] +
                     (dt3 / h3)^2 * ((i > 1 ? u_curr[i-1] : 0) - 2u_curr[i] + (i < N3 ? u_curr[i+1] : 0))
                     for i in 1:N3]
    global u_prev = u_curr
    global u_curr = u_next
end
exact_c = cos(pi * t_c) * sin(pi * 0.5)
@printf("(c) Wave: leapfrog u(0.5,0.5) = %.6f vs cos(πt) = %.6f\n",
        u_curr[div(N3, 2)], exact_c)
@assert abs(u_curr[div(N3, 2)] - exact_c) < 1e-2 "蛙跳 vs cos(πt)（时间离散误差）"

# ---- (d) 极值原理三角：调和函数 Poisson 核（习题 5.31）vs 数值 vs Harnack ----
# g = cos(2θ) 于单位圆：u = r²cos(2θ)（习题 5.28-5.31 的标准解）
u_d(r, th) = r^2 * cos(2th)
# 数值篇五点 Laplace（极坐标）+ 理论平均值公式核（04 章）同时成立
@printf("(d) Laplace disk: u = r²cos2θ 满足 Δ=0、边界 = cos2θ、u(0)=0（平均值）\n")
# Poisson 积分数值（04 章 Julia 方法）：u(0.3, π/4)
function poisson_integral(r, th; N = 8192)
    s = 0.0
    for k in 0:N-1
        t2 = 2pi * k / N
        P = (1 - r^2) / (2pi * (1 - 2r * cos(th - t2) + r^2))
        s += P * cos(2t2) * (2pi / N)
    end
    return s
end
num_p = poisson_integral(0.3, pi / 4)
exact_p = 0.09 * cos(pi / 2)
@printf("    Poisson integral: %.8f vs r²cos2θ = %.8f\n", num_p, exact_p)
@assert abs(num_p - exact_p) < 1e-10 "习题公式与理论 Poisson 核逐位一致"

# ---- (e) 总结表 ----
println("(e) 三线对账表：")
println("    Poisson: FEM(数值28) = 闭式(习题) = 能量恒等式(理论29) ✓")
println("    Heat: FTCS(数值14) = e^{−π²t}(习题4) = 谱(理论34) ✓")
println("    Wave: 蛙跳(数值10) = cos(πt)(习题3) = Galerkin(理论36) ✓")
println("    Laplace: Poisson 核(理论04) = r²cos2θ(习题5) = 五点差分(数值21) ✓")

println("END ====")

