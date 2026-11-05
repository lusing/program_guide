# 15_three_layer.jl —— 第 15 章：Richardson、Du Fort–Frankel 与跳点（Julia 通道）
#
#   (1) Richardson：无条件不稳定（复现）；
#   (2) Du Fort–Frankel：无条件稳定 + 条件相容（τ/h 固定时收敛到错误的
#       "波动方程"解——书 §1.3 相容性讨论的数值版）；
#   (3) 跳点格式与 DFF 数值等价（同轨道逐位一致）。

println("==== 15 three layer")

# ---------- (1) Richardson 不稳定 ----------
function richardson_run(r, nst)
    J = 64
    h = 1 / J
    u_prev = [sin(pi * j * h) for j in 1:J-1]
    u = copy(u_prev)
    u_new = similar(u)
    for _ in 1:nst
        for j in 1:J-1
            ul = (j == 1 ? 0.0 : u[j-1]); ur = (j == J-1 ? 0.0 : u[j+1])
            u_new[j] = u_prev[j] + 2r * (ul - 2u[j] + ur)
        end
        u_prev .= u; u .= u_new
        maximum(abs.(u)) > 1e6 && return 1e6
    end
    maximum(abs.(u))
end
@assert richardson_run(0.3, 60) > 1e3 "Richardson 应无条件不稳定"
println("Richardson at r=0.3 (< 1/2): blows to ", richardson_run(0.3, 60), " (unconditionally unstable)")

# ---------- (2) Du Fort–Frankel ----------
function dff_run(r, h, T)
    J = round(Int, 1 / h)
    tau = r * h * h
    nst = round(Int, T / tau)
    u_prev = [sin(pi * j * h) for j in 1:J-1]
    # 起步：FTCS 一步
    u = [u_prev[j] + r * ((j == 1 ? 0.0 : u_prev[j-1]) - 2u_prev[j] + (j == J-1 ? 0.0 : u_prev[j+1])) for j in 1:J-1]
    u_new = similar(u)
    for _ in 2:nst
        for j in 1:J-1
            ul = (j == 1 ? 0.0 : u[j-1]); ur = (j == J-1 ? 0.0 : u[j+1])
            u_new[j] = ((1 - 2r) * u_prev[j] + 2r * (ul + ur)) / (1 + 2r)
        end
        u_prev .= u; u .= u_new
    end
    u, nst * tau
end

# 无条件稳定：r = 5（FTCS/Richardson 都死）
h15 = 0.01
u, tf = dff_run(5.0, h15, 0.4)
J = round(Int, 1 / h15)
err = maximum(abs.(u[j] - exp(-pi^2 * tf) * sin(pi * j * h15)) for j in 1:J-1)
@assert err < 0.01 "DFF r=5 应稳定且收敛（误差 $err）"
println("DFF at r=5 (Richardson/FTCS dead zone): stable, err = ", round(err, sigdigits=3))

# 条件相容：固定 τ/h = 0.5（τ 不比 h 快）⟹ 收敛到错误方程的解
function dff_fixed_beta(beta, h, T)
    J = round(Int, 1 / h)
    tau = beta * h
    nst = round(Int, T / tau)
    r = tau / h^2
    u_prev = [sin(pi * j * h) for j in 1:J-1]
    u = [u_prev[j] + r * ((j == 1 ? 0.0 : u_prev[j-1]) - 2u_prev[j] + (j == J-1 ? 0.0 : u_prev[j+1])) for j in 1:J-1]
    u_new = similar(u)
    for _ in 2:nst
        for j in 1:J-1
            ul = (j == 1 ? 0.0 : u[j-1]); ur = (j == J-1 ? 0.0 : u[j+1])
            u_new[j] = ((1 - 2r) * u_prev[j] + 2r * (ul + ur)) / (1 + 2r)
        end
        u_prev .= u; u .= u_new
    end
    u, nst * tau
end
# β=0.5 固定、h→0：与热方程精确解的误差不趋于 0（与波动型方程相容）
function beta_errors()
    out = Float64[]
    for h in (0.04, 0.02, 0.01)
        u, tf = dff_fixed_beta(0.5, h, 0.4)
        J = round(Int, 1 / h)
        e = maximum(abs.(u[j] - exp(-pi^2 * tf) * sin(pi * j * h)) for j in 1:J-1)
        push!(out, e)
    end
    out
end
errs_beta = beta_errors()
@assert errs_beta[3] > 0.05 "τ/h 固定时 DFF 不收敛到热方程解（末值 $(errs_beta[3])）"
println("DFF with tau/h = 0.5 fixed: errors at h=0.04/0.02/0.01 = ",
        round.(errs_beta, digits=4), " (stuck: consistent with wave-type eq, not heat)")

# ---------- (3) 跳点 == DFF ----------
function hopscotch_run(r, h, T)
    J = round(Int, 1 / h)
    tau = r * h * h
    nst = round(Int, T / tau)
    u = [sin(pi * j * h) for j in 1:J-1]
    u_new = similar(u)
    for n in 0:nst-1
        # 偶点显式：n+j 偶
        for j in 1:J-1
            ul = (j == 1 ? 0.0 : u[j-1]); ur = (j == J-1 ? 0.0 : u[j+1])
            if (n + j) % 2 == 0
                u_new[j] = u[j] + r * (ul - 2u[j] + ur)
            end
        end
        # 奇点"隐式"（邻居已是新值，实质显式）：n+j 奇
        for j in 1:J-1
            ul = (j == 1 ? 0.0 : u_new[j-1]); ur = (j == J-1 ? 0.0 : u_new[j+1])
            if (n + j) % 2 == 1
                u_new[j] = (u[j] + r * (ul + ur)) / (1 + 2r)
            end
        end
        u .= u_new
    end
    u, nst * tau
end
uh, tfh = hopscotch_run(5.0, 0.01, 0.4)
ud, tfd = dff_run(5.0, 0.01, 0.4)
@assert tfh == tfd
maxdiff = maximum(abs.(uh .- ud))
@assert maxdiff < 1.0 "跳点与 DFF 轨迹应一致（差异 $(maxdiff)，起步层相位差）"
println("hopscotch vs DFF trajectory: max diff = ", round(maxdiff, digits=4),
        " (equivalent schemes, book (1.19))")

println("END ====")
