# 07_advection.jl —— 第 07 章：迎风、Lax-Friedrichs、Lax-Wendroff（Julia 通道）
#
#   (1) 书 §1.7 数值例子的数字版：四格式推进方波脉冲——
#       LF/迎风抹平（耗散主导），LW/BW 振荡（色散主导）；
#   (2) 耗散-色散账：单波传播的振幅衰减与相位误差对照表；
#   (3) Beam-Warming 二阶迎风：稳定域放宽到 λ ≤ 2 的数值确认。

println("==== 07 advection")

# ---------- 通用推进器（周期域，a > 0） ----------
function step_scheme!(un, u, scheme, lam)
    J = length(u)
    jm(j) = (j == 1 ? J : j - 1)
    jp(j) = (j == J ? 1 : j + 1)
    for j in 1:J
        if scheme == :upwind
            un[j] = u[j] - lam * (u[j] - u[jm(j)])
        elseif scheme == :lf
            un[j] = 0.5 * (u[jp(j)] + u[jm(j)]) - 0.5 * lam * (u[jp(j)] - u[jm(j)])
        elseif scheme == :lw
            un[j] = u[j] - 0.5 * lam * (u[jp(j)] - u[jm(j)]) + 0.5 * lam^2 * (u[jp(j)] - 2 * u[j] + u[jm(j)])
                    0.5 * lam^2 * (u[jp(j)] - 2u[j] + u[jm(j)])
        elseif scheme == :bw   # Beam-Warming 二阶迎风（a>0 用左侧三点）
            un[j] = u[j] - 0.5 * lam * (3u[j] - 4u[jm(j)] + u[jm(jm(j))]) +
                    0.5 * lam^2 * (u[j] - 2u[jm(j)] + u[jm(jm(j))])
        end
    end
end

function run_scheme(scheme, g, lam, h, T)
    J = round(Int, 1 / h)
    u = [g((j - 1) * h) for j in 1:J]
    un = similar(u)
    nst = round(Int, T / (lam * h))
    for _ in 1:nst
        step_scheme!(un, u, scheme, lam)
        u .= un
        maximum(abs.(u)) > 1e6 && return u
    end
    u
end

# ---------- (1) 书 §1.7：四格式推进方波 ----------
gwave(x) = (0.3 < x < 0.6) ? 1.0 : 0.0    # 方波脉冲
h, lam, T = 0.005, 0.8, 0.5
uex = [gwave(((j - 1) * h - T) % 1.0) for j in 1:round(Int, 1 / h)]
println("--- book Fig 3.7 (h=0.005, lambda=0.8, T=0.5): square pulse ---")
for scheme in (:upwind, :lf, :lw, :bw)
    u = run_scheme(scheme, gwave, lam, h, T)
    undershoot = minimum(u)
    over = maximum(u)
    println("  ", rpad(string(scheme), 8), " min = ", round(undershoot, digits=4),
            "  max = ", round(over, digits=4))
end
u_up = run_scheme(:upwind, gwave, lam, h, T)
u_lf = run_scheme(:lf, gwave, lam, h, T)
u_lw = run_scheme(:lw, gwave, lam, h, T)
u_bw = run_scheme(:bw, gwave, lam, h, T)
@assert minimum(u_up) >= -1e-12 "迎风 λ≤1 应保单调（无下冲）"
@assert minimum(u_lf) >= -1e-12 "LF λ≤1 应保单调"
@assert minimum(u_lw) < -0.05 "LW 在间断附近应产生振荡（下冲）"
@assert minimum(u_bw) < -0.05 "BW 在间断附近应产生振荡"
println("one-sided schemes monotone (min >= 0); LW/BW oscillate (min < -0.05)")

# 耗散量对比：LF 抹得比迎风更平（过渡带更宽）
transition_width(u) = count(x -> 0.1 < x < 0.9, u) * h
println("transition widths: upwind = ", round(transition_width(u_up), digits=3),
        ", lf = ", round(transition_width(u_lf), digits=3),
        ", lw = ", round(transition_width(u_lw), digits=3))

# ---------- (2) 耗散-色散账：单波 k = 8 ----------
# 精确传播: u = sin(2πk(x - T))；增长因子决定振幅 |G|^n 与相移 n·arg(G)
kmode = 8
gk(x) = sin(2 * pi * kmode * x)
J = 256
h2 = 1 / J
lam2 = 0.8
T2 = 0.5
nst2 = round(Int, T2 / (lam2 * h2))
theta = 2 * pi * kmode / J
nsteps_total = nst2
println("--- single wave k = 8 (lambda = 0.8, T = 0.5): amplitude & phase ---")
for scheme in (:upwind, :lf, :lw, :bw)
    u = [gk((j - 1) * h2) for j in 1:J]
    un = similar(u)
    for _ in 1:nsteps_total
        step_scheme!(un, u, scheme, lam2)
        u .= un
    end
    # 与精确解的相关分析：振幅与相位
    uexk = [sin(2 * pi * kmode * (((j - 1) * h2 - T2) % 1.0)) for j in 1:J]
    amp = abs(sum(u[j] * exp(-2im * pi * kmode * (j - 1) / J) for j in 1:J)) * 2 / J
    ampex = abs(sum(uexk[j] * exp(-2im * pi * kmode * (j - 1) / J) for j in 1:J)) * 2 / J
    ph = angle(sum(u[j] * exp(-2im * pi * kmode * (j - 1) / J) for j in 1:J))
    phex = angle(sum(uexk[j] * exp(-2im * pi * kmode * (j - 1) / J) for j in 1:J))
    println("  ", rpad(string(scheme), 8), " amplitude = ", round(amp, digits=4),
            " (exact ", round(ampex, digits=4), ")  phase lag = ",
            round((phex - ph) * J / (2 * pi * kmode) * h2, digits=5), " (in x units)")
end
# LW 的振幅衰减应远小于 LF（四阶 vs 二阶耗散）
function amp_of(scheme)
    u = [gk((j - 1) * h2) for j in 1:J]
    un = similar(u)
    for _ in 1:nsteps_total
        step_scheme!(un, u, scheme, lam2)
        u .= un
    end
    abs(sum(u[j] * exp(-2im * pi * kmode * (j - 1) / J) for j in 1:J)) * 2 / J
end
a_lf, a_lw, a_up = amp_of(:lf), amp_of(:lw), amp_of(:upwind)
@assert a_lw > a_lf "LW 的振幅保持应优于 LF"
@assert a_lw > a_up "LW 的振幅保持应优于迎风"
println("amplitude ranking: lw = ", round(a_lw, digits=4), " > lf = ", round(a_lf, digits=4),
        ", upwind = ", round(a_up, digits=4))

# ---------- (3) Beam-Warming：λ ≤ 2 稳定域 ----------
# |G|^2 = 1 - 4λ(1-λ)^2(2-λ) sin^4(θ/2)：λ ∈ [0,2] 非负
for lam3 in (0.8, 1.5, 1.9)
    u = run_scheme(:bw, gk, lam3, h2, T2)
    @assert maximum(abs.(u)) < 1.5 "BW λ=$lam3 应稳定"
end
# λ = 2.2 > 2：用方波（自带网格尺度分量）在充分长的积分时间下验证增长
u_bad = run_scheme(:bw, gwave, 2.2, h2, T2)
@assert maximum(abs.(u_bad)) > 10 "BW λ=2.2 > 2 应不稳定"
println("BW stability: lambda = 0.8/1.5/1.9 bounded; lambda = 2.2 max|u| = ",
        round(maximum(abs.(u_bad)), digits=3))

println("END ====")
