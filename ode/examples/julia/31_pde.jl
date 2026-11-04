println("==== 31 pde")

function lap(u, dx)
    Nn = length(u)
    du = zeros(Nn)
    for i in 2:Nn-1
        du[i] = (u[i+1] - 2 * u[i] + u[i-1]) / dx^2
    end
    du
end

# 第 31 章：分离变量——热方程模式、波动、Laplace、FTCS。

# --- (a) 热方程模式衰减：u(x,t) = Σ c_n sin(nπx) e^{-n²π²t}，f = x(1-x) ---
c(n) = 2 * quad_x(x -> x * (1 - x) * sin(n * pi * x))   # ×2/[0,1] 归一
function quad_x(f; n = 40000)
    h = 1 / n
    s = 0.0
    for i in 1:n-1
        s += f(i * h)
    end
    (s + 0.5 * (f(0) + f(1))) * h
end
c1 = c(1); c2 = c(2)
t = 0.1
ratio = abs(c1 * exp(-pi^2 * t) / (c2 * exp(-4 * pi^2 * t)))
@assert ratio > 100 "高频先死：t=0.1 时 |模式1/模式2| > 100（实际 $(round(ratio; digits=1))）"
println("热方程：t = 0.1 时第一模式/第二模式 = ", round(ratio; digits=1), "（高频先死）")

# --- (b) 波方程：u = cos(πt) sin(πx) 半离散 RK4 对照 ---
uexact(x, t) = cos(pi * t) * sin(pi * x)
# 半离散：空间二阶差分 N=40 格点，RK4 时间步
N = 40
dx = 1 / N
dt = 0.0005
u = [sin(pi * i * dx) for i in 0:N]
v = zeros(N + 1)
T = 1.0
nstep = round(Int, T / dt)
for _ in 1:nstep
    # u' = v, v' = u_tt = (u_{i+1} - 2u_i + u_{i-1})/dx²
    global u, v
    k1u = copy(v)
    k1v = lap(u, dx)
    u2 = u .+ dt / 2 .* k1u; v2 = v .+ dt / 2 .* k1v
    k2u = copy(v2)
    k2v = lap(u2, dx)
    u3 = u .+ dt / 2 .* k2u; v3 = v .+ dt / 2 .* k2v
    k3u = copy(v3)
    k3v = lap(u3, dx)
    u4 = u .+ dt .* k3u; v4 = v .+ dt .* k3v
    k4u = copy(v4)
    k4v = lap(u4, dx)
    global u = u .+ dt / 6 .* (k1u .+ 2 .* k2u .+ 2 .* k3u .+ k4u)
    global v = v .+ dt / 6 .* (k1v .+ 2 .* k2v .+ 2 .* k3v .+ k4v)
end
@assert abs(u[div(N, 2) + 1] - uexact(0.5, T)) < 1e-3 "波方程半离散 vs cos(πt)sin(πx)"
println("波方程：u(0.5, 1) = ", round(u[div(N, 2) + 1]; digits=6), " vs cos(π)sin(π/2)·…= ", round(uexact(0.5, T); digits=6))

# --- (c) FTCS 热方程：r = 0.4 稳定（vs 级数解） ---
function ftcs(r, nsteps, u0)
    u = copy(u0)
    Nn = length(u) - 1      # 格点 0..Nn（1 基下标 1..Nn+1），内部 2..Nn
    for _ in 1:nsteps
        unew = copy(u)
        for i in 2:Nn
            unew[i] = u[i] + r * (u[i + 1] - 2 * u[i] + u[i - 1])
        end
        u = unew
    end
    u
end
N = 50
dx = 1 / N
r = 0.4
dt = r * dx^2
u0 = [sin(pi * i * dx) for i in 0:N]
nsteps = round(Int, 0.05 / dt)
uftcs = ftcs(r, nsteps, u0)
# 级数解：第一模式 e^{-π²·0.05}
for i in [11, 26, 41]
    x = (i - 1) * dx          # 1 基下标 i 对应格点 (i−1)dx
    @assert abs(uftcs[i] - sin(pi * x) * exp(-pi^2 * 0.05)) < 1e-3 "FTCS vs 级数"
end
println("FTCS（r=0.4）：t=0.05 与级数解 e^{{−π²t}}sin πx 一致（3 点）")

# --- (d) Laplace 方域级数解的极值原理 ---
# u(x,y) = sin(πx)sinh(πy)/sinh(π)（底边 sin πx，其余 0）满足 Δu = 0
lap_check(x, y, h) = begin
    u(xx, yy) = sin(pi * xx) * sinh(pi * yy) / sinh(pi)
    (u(x + h, y) + u(x - h, y) + u(x, y + h) + u(x, y - h) - 4 * u(x, y)) / h^2
end
for (x, y) in [(0.5, 0.5), (0.3, 0.7)]
    @assert abs(lap_check(x, y, 1e-5)) < 1e-5 "调和性 Δu = 0"
end
uval(x, y) = sin(pi * x) * sinh(pi * y) / sinh(pi)
# 极值原理：内部值 < 边界最大值 1
@assert uval(0.5, 0.5) < 1.0 && uval(0.5, 0.5) > 0
println("Laplace：级数解调和（Δu = 0 残差 < 1e-5），内部值 ", round(uval(0.5, 0.5); digits=4), " < 边界最大值 1")

# --- (e) d'Alembert：g = 0，u(x,t) = ½[f(x+t) + f(x−t)] ---
f0(x) = exp(-(x - 0.5)^2 / 0.01)
udalem(x, t) = 0.5 * (f0(x + t) + f0(x - t))
# 波速 1：t = 0.3 时两个半高波包在 x = 0.2 和 0.8
@assert abs(udalem(0.2, 0.3) - 0.5) < 1e-8 && abs(udalem(0.8, 0.3) - 0.5) < 1e-8
@assert udalem(0.5, 0.3) < 0.01
println("d'Alembert：t = 0.3 时两个半高波包在 x = 0.2/0.8 ✓（行波分解）")

println("END ====")

function lap(u, dx)
    Nn = length(u)
    du = zeros(Nn)
    for i in 2:Nn-1
        du[i] = (u[i+1] - 2 * u[i] + u[i-1]) / dx^2
    end
    du
end
