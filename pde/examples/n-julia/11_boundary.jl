# 11_boundary.jl —— 第 11 章：初边值问题与数值边界（Julia 通道）
#
#   (1) 加权隐式波动格式（书 (5.6)–(5.9)，θ=1/2）：λ=2（显式已爆）下
#       无条件稳定、二阶收敛，三对角追赶法求解；
#   (2) 数值边界反例：蛙跳 + 线性外推 (5.20) 缓慢增长；
#       迎风边界 (5.22) 稳定——书例 5.1 的数值版；
#   (3) 边界条件计数：a>0 只能左边界给条件（右侧出流不能给）。

println("==== 11 boundary")

# ---------- (1) 加权隐式波动 θ = 1/2 ----------
function thomas(a, b, c, d)
    n = length(b)
    cp = zeros(n); dp = zeros(n)
    cp[1] = c[1] / b[1]; dp[1] = d[1] / b[1]
    for i in 2:n
        m = b[i] - a[i] * cp[i-1]
        cp[i] = c[i] / m
        dp[i] = (d[i] - a[i] * dp[i-1]) / m
    end
    x = zeros(n); x[n] = dp[n]
    for i in n-1:-1:1
        x[i] = dp[i] - cp[i] * x[i+1]
    end
    x
end

function wave_weighted_err(h, lam, T)
    J = round(Int, 1 / h) - 1
    tau = lam * h
    theta = 0.5
    nst = round(Int, T / tau)
    # 精确解 u = sin(pi x) cos(pi t)，边界 0
    u_prev = [sin(pi * j * h) for j in 1:J]                      # u^0
    u = [u_prev[j] + 0 for j in 1:J]                             # u^1 由 Taylor（g=0，t=tau）
    # u^1 = cos(pi*tau) sin(pi x)（用精确值起步，格式精度另行由内点体现）
    u = [cos(pi * tau) * sin(pi * j * h) for j in 1:J]
    a3 = fill(-theta * lam^2, J); b3 = fill(1 + 2theta * lam^2, J); c3 = fill(-theta * lam^2, J)
    a3[1] = 0.0; c3[J] = 0.0
    for n in 1:nst - 1
        # 右端：2u^n - u^{n-1} + lam^2[(1-2θ)δ²u^n + θ δ²u^{n-1}]
        rhs = zeros(J)
        for j in 1:J
            ul = (j == 1 ? 0.0 : u[j-1]); ur = (j == J ? 0.0 : u[j+1])
            d2n = ul - 2u[j] + ur
            ulp = (j == 1 ? 0.0 : u_prev[j-1]); urp = (j == J ? 0.0 : u_prev[j+1])
            d2p = ulp - 2u_prev[j] + urp
            rhs[j] = 2u[j] - u_prev[j] + lam^2 * ((1 - 2theta) * d2n + theta * d2p)
        end
        un = thomas(a3, b3, c3, rhs)
        u_prev .= u; u .= un
    end
    tf = nst * tau                      # u^0 在 0、u^1 在 tau，再走 nst-1 步到 nst·tau
    uex = [cos(pi * tf) * sin(pi * j * h) for j in 1:J]
    maximum(abs.(u .- uex))
end

e1 = wave_weighted_err(2.0e-2, 2.0, 0.5)
e2 = wave_weighted_err(1.0e-2, 2.0, 0.5)
r = e1 / e2
@assert 3.5 < r < 4.5 "加权隐式应二阶（λ=2 无条件稳定，实测比 $r）"
println("weighted implicit theta=1/2 at lam=2: h->h/2 error ratio = ",
        round(r, digits=3), " (2nd order, unconditionally stable)")

# ---------- (2) 数值边界：外推反例 vs 迎风 ----------
function leapfrog_bc(bckind, nst)
    J = 200
    h = 1 / J
    lam = 0.8
    # 光滑脉冲 + 1e-3 的网格尺度种子（外推边界的反例需要网格内容）
    g(x) = exp(-100 * (x - 0.4)^2) + 1.0e-3 * sin(pi * x / h)
    u0 = [g((j - 1) * h) for j in 1:J]
    u0[1] = 0.0                                  # 入流边界 a>0：x=0 给 0
    u1 = [u0[j] - 0.5 * lam * ((j == J ? 0.0 : u0[j+1]) - (j == 1 ? 0.0 : u0[j-1])) for j in 1:J]
    up, uc = u0, u1
    un = similar(u0)
    for _ in 2:nst
        for j in 2:J - 1
            un[j] = up[j] - lam * (uc[j+1] - uc[j-1])
        end
        un[1] = 0.0                               # 入流边界
        if bckind == :extrap
            un[J] = 2 * un[J-1] - un[J-2]         # (5.20) 线性外推
        else
            un[J] = uc[J] - lam * (uc[J] - uc[J-1])   # (5.22) 迎风边界
        end
        up .= uc; uc .= un
        maximum(abs.(uc)) > 1e8 && return 1e8
    end
    maximum(abs.(uc))
end

# 短时间两者都还行；长时间外推缓慢增长、迎风有界
short_ex = leapfrog_bc(:extrap, 500)
short_up = leapfrog_bc(:upwind, 500)
long_ex = leapfrog_bc(:extrap, 4000)
long_up = leapfrog_bc(:upwind, 4000)
println("leapfrog + extrapolation BC: max|u| 500 steps = ", round(short_ex, digits=4),
        "; 4000 steps = ", round(long_ex, digits=3))
println("leapfrog + upwind BC:        max|u| 500 steps = ", round(short_up, digits=4),
        "; 4000 steps = ", round(long_up, digits=4))
@assert long_ex > 1.0 "外推边界应缓慢增长（实测 $(long_ex)）"
@assert long_up < 0.01 "迎风边界应保持有界（实测 $(long_up)）"

# ---------- (3) 边界条件计数 ----------
function boundary_count(a, side)
    if side == :left
        return a > 0 ? 1 : 0
    else
        return a > 0 ? 0 : 1
    end
end

a_char = 1.0
# a>0：特征线向右走出区域 ⟹ 信息从左边界进入：x=0 给条件、x=1 不能给
@assert boundary_count(a_char, :left) == 1
@assert boundary_count(a_char, :right) == 0
println("a>0: 1 condition at inflow x=0, 0 at outflow x=1")

println("END ====")
