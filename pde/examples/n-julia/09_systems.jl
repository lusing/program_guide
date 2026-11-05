# 09_systems.jl —— 第 09 章：一阶方程组与变系数双曲（Julia 通道）
#
#   (1) 声学方程组 p_t + u_x = 0, u_t + p_x = 0（A = [[0,1],[1,0]]，特征 ±1）：
#       Riemann 不变量 w± = p ± u 各自平移——精确解；
#       系统迎风（特征形式）、系统 LF (2.3)、系统 LW (2.5) 三格式对账；
#   (2) 变系数对流 a(x) = 1 + 0.5·sin(2πx)：迎风格式 (3.8) + 冻结系数
#       稳定条件 max|a|·λ ≤ 1；沿特征线（RK4 反向积分）核对精确解；
#   (3) 违反冻结系数条件 ⟹ 增长。

println("==== 09 systems")

# ---------- (1) 声学方程组 ----------
g(x) = exp(-100 * (x - 0.5)^2)          # 主实验：窄脉冲
gc(x) = exp(-25 * (x - 0.5)^2)         # 收敛实验：宽脉冲（h=0.02 也充分分辨）
# 精确解（Riemann 不变量）：p = (g(x-t)+g(x+t))/2, u = (g(x-t)-g(x+t))/2
function exact_acoustics(x, t, gfun=g)
    gm = gfun(((x - t) % 1.0 + 1.0) % 1.0)
    gp = gfun(((x + t) % 1.0 + 1.0) % 1.0)
    (0.5 * (gm + gp), 0.5 * (gm - gp))
end

function acoustics_scheme(kind, lam, h, T; gfun=g)
    J = round(Int, 1 / h)
    nst = round(Int, T / (lam * h))
    p = [gfun((j - 1) * h) for j in 1:J]
    u = zeros(J)
    pn = similar(p); un = similar(u)
    for _ in 1:nst
        for j in 1:J
            jm = (j == 1 ? J : j - 1); jp = (j == J ? 1 : j + 1)
            if kind == :upwind
                # 特征形式：w+ = p+u 用左差，w- = p-u 用右差，变换回 (p,u)
                wp = p[j] + u[j]; wm = p[j] - u[j]
                wpm = p[jm] + u[jm]; wmm = p[jp] - u[jp]
                wp_new = wp - lam * (wp - wpm)
                wm_new = wm + lam * (wmm - wm)
                pn[j] = 0.5 * (wp_new + wm_new)
                un[j] = 0.5 * (wp_new - wm_new)
            elseif kind == :lf
                pn[j] = 0.5 * (p[jp] + p[jm]) - 0.5 * lam * (u[jp] - u[jm])
                un[j] = 0.5 * (u[jp] + u[jm]) - 0.5 * lam * (p[jp] - p[jm])
            else  # lw: A² = I
                pn[j] = p[j] - 0.5 * lam * (u[jp] - u[jm]) +
                        0.5 * lam^2 * (p[jp] - 2p[j] + p[jm])
                un[j] = u[j] - 0.5 * lam * (p[jp] - p[jm]) +
                        0.5 * lam^2 * (u[jp] - 2u[j] + u[jm])
            end
        end
        p .= pn; u .= un
    end
    (p, u)
end

h, lam, T = 0.01, 0.8, 0.5
J = round(Int, 1 / h)
tf = round(Int, T / (lam * h)) * lam * h     # 实际推进时间（步数取整对账）
errs = Dict{Symbol,Float64}()
for kind in (:upwind, :lf, :lw)
    p, u = acoustics_scheme(kind, lam, h, T)
    err = 0.0
    for j in 1:J
        pe, ue = exact_acoustics((j - 1) * h, tf)
        err = max(err, abs(p[j] - pe), abs(u[j] - ue))
    end
    errs[kind] = err
    println("acoustics ", rpad(string(kind), 8), " max error = ", round(err, sigdigits=4))
end
@assert errs[:lf] > errs[:lw] "系统 LW（二阶）应优于系统 LF（一阶）"
@assert errs[:upwind] < errs[:lf] "特征迎风应比 LF 少耗散"

# 系统迎风一阶收敛、系统 LW 二阶收敛
function acoustics_err(kind, h)
    gg = gc
    lam2, T2 = 0.8, 0.5
    nst = round(Int, T2 / (lam2 * h))
    tf2 = nst * lam2 * h
    p, u = acoustics_scheme(kind, lam2, h, T2; gfun=gg)
    J = round(Int, 1 / h)
    err = 0.0
    for j in 1:J
        pe, ue = exact_acoustics((j - 1) * h, tf2, gg)
        err = max(err, abs(p[j] - pe), abs(u[j] - ue))
    end
    err
end
r_up = acoustics_err(:upwind, 2.0e-2) / acoustics_err(:upwind, 1.0e-2)
r_lw = acoustics_err(:lw, 2.0e-2) / acoustics_err(:lw, 1.0e-2)
@assert 1.5 < r_up < 2.5 "系统迎风应一阶（实测 $r_up）"
@assert 3.0 < r_lw < 4.7 "系统 LW 应二阶（实测 $r_lw）"
println("convergence: system upwind ratio = ", round(r_up, digits=3),
        " (1st), system lw ratio = ", round(r_lw, digits=3), " (2nd)")

# ---------- (2) 变系数对流 + 特征线核对 ----------
avec(x) = 1 + 0.5 * sin(2 * pi * x)
function char_back(x_target, t_target, nstep)
    # RK4 反向积分 dx/dt = -a(x)：从 (x_target, t_target) 回到 t=0
    x = x_target
    dt = -t_target / nstep
    for _ in 1:nstep
        k1 = -avec(x); k2 = -avec(x + 0.5 * dt * k1)
        k3 = -avec(x + 0.5 * dt * k2); k4 = -avec(x + dt * k3)
        x += dt * (k1 + 2k2 + 2k3 + k4) / 6
        x = ((x % 1.0) + 1.0) % 1.0
    end
    x
end

function varcoef_upwind(h, tau, T)
    J = round(Int, 1 / h)
    nst = round(Int, T / tau)
    u = [g((j - 1) * h) for j in 1:J]
    un = similar(u)
    for _ in 1:nst
        for j in 1:J
            xj = (j - 1) * h
            aj = avec(xj)
            lam_j = aj * tau / h
            if aj >= 0
                jm = (j == 1 ? J : j - 1)
                un[j] = u[j] - lam_j * (u[j] - u[jm])
            else
                jp = (j == J ? 1 : j + 1)
                un[j] = u[j] - lam_j * (u[jp] - u[j])
            end
        end
        u .= un
        maximum(abs.(u)) > 1e6 && return u
    end
    u
end

h = 0.002
tau = 0.6 * h / maximum(avec.((0:h:1) |> collect))    # 冻结系数条件：max(a)·λ ≤ 0.6
u = varcoef_upwind(h, tau, 0.5)
# 特征线核对：u(x*, 0.5) = g(x0)，x0 由 RK4 反向积分
maxerr = maximum(begin
    x0 = char_back((jstar - 1) * h, 0.5, 2000)
    abs(u[jstar] - g(x0))
end for jstar in [round(Int, 0.3 / h) + 1, round(Int, 0.7 / h) + 1, round(Int, 0.52 / h) + 1])
@assert maxerr < 0.05 "变系数迎风应沿特征线核对（实测误差 $(maxerr)）"
println("variable-coefficient upwind vs characteristic (RK4): max error at 3 probes = ",
        round(maxerr, sigdigits=3))

# ---------- (3) 违反冻结系数条件 ----------
h = 0.002
tau = 1.3 * h / 1.5        # max(a)·τ/h = 1.3 > 1（局部超界只在 a≈1.5 的窄区，须长积分）
u = varcoef_upwind(h, tau, 2.0)
@assert maximum(abs.(u)) > 10 "违反 max|a|·λ ≤ 1 应增长（实测 $(maximum(abs.(u)))）"
println("frozen-coeff violated (max a * lam = 1.3): max|u| = ",
        round(maximum(abs.(u)), sigdigits=4), " (growth)")

println("END ====")
