# 10_wave.jl —— 第 10 章：波动方程的差分格式（Julia 通道）
#
#   (1) 显式格式 (4.10) + 二阶起步 (4.14)：对光滑驻波二阶收敛；
#   (2) 一阶起步 (4.12) vs 二阶起步：阶数不变、常数变小（与 08 章同型结论）；
#   (3) aλ = 1 边界：λ=0.99 稳、λ=1 退化模式线性增长、λ=1.01 指数爆炸；
#   (4) 离散能量有界性（λ<1）。

println("==== 10 wave")

# u_tt = u_xx 的显式格式（周期域），f = sin(2πx)，g = 0：精确解 sin(2π(x−t)) 的叠加
# u(x,t) = sin(2πx)cos(2πt)（驻波）
f0(x) = sin(2 * pi * x)

function wave_solve(h, lam, T, start_order)
    J = round(Int, 1 / h)
    tau = lam * h
    nst = round(Int, T / tau)
    u0 = [f0((j - 1) * h) for j in 1:J]
    # 起步层
    u1 = similar(u0)
    for j in 1:J
        jm = (j == 1 ? J : j - 1); jp = (j == J ? 1 : j + 1)
        if start_order == 1      # (4.12)：u^1 = u^0 + tau*g = u^0（g=0）
            u1[j] = u0[j]
        else                     # (4.14)：u^1 = f + (lam^2/2)δ²f + tau*g
            u1[j] = u0[j] + 0.5 * lam^2 * (u0[jp] - 2u0[j] + u0[jm])
        end
    end
    up, uc = u0, u1
    un = similar(u0)
    for _ in 2:nst
        for j in 1:J
            jm = (j == 1 ? J : j - 1); jp = (j == J ? 1 : j + 1)
            un[j] = 2uc[j] - up[j] + lam^2 * (uc[jp] - 2uc[j] + uc[jm])
        end
        up .= uc; uc .= un
        maximum(abs.(uc)) > 1e8 && return uc, nst
    end
    uc, nst
end

function wave_err(h, start_order)
    lam = 0.8
    T = 0.5
    u, nst = wave_solve(h, lam, T, start_order)
    tf = nst * lam * h
    J = round(Int, 1 / h)
    uex = [sin(2 * pi * (j - 1) * h) * cos(2 * pi * tf) for j in 1:J]
    maximum(abs.(u .- uex))
end

e1, e2 = wave_err(2.0e-2, 2), wave_err(1.0e-2, 2)
r2 = e1 / e2
@assert 3.5 < r2 < 4.5 "二阶起步应二阶收敛（实测 $r2）"
println("wave explicit (2nd-order start): h->h/2 error ratio = ", round(r2, digits=3))

e1a, e2a = wave_err(2.0e-2, 1), wave_err(1.0e-2, 1)
r1 = e1a / e2a
# 数学账：朴素起步 u^1 = f + tau*g 的 O(tau^2) 初始层误差对波方程等效于
# O(tau) 的初速度误差（响应含 1/sin(omega tau) ~ 1/tau 的共振因子），
# 整体拖成一阶——书"截断误差不匹配"的实证。
@assert 1.7 < r1 < 2.4 "一阶起步应拖累为一阶（实测 $r1）"
@assert e2 < e2a "细网格上二阶起步误差更小"
println("wave 1st-order start (4.12): ratio = ", round(r1, digits=3), " (1st order)")
println("wave 2nd-order start (4.14): err(0.01) = ", round(e2, digits=6),
        " vs 1st-order ", round(e2a, digits=6), " (order restored)")

# ---------- (3) aλ 边界 ----------
function wave_growth(lam, nst, degen)
    J = 256
    if degen
        # 退化模式 θ=π：(−1)^j，零速度起步 u^1 = u^0 恰好落在若尔当块的增长方向
        u0 = [((−1.0)^(j - 1)) for j in 1:J]
        u1 = copy(u0)
    else
        u0 = [sin(2 * pi * (j - 1) / J) for j in 1:J]
        u1 = [u0[j] + 0.5 * lam^2 * (u0[mod(j, J) + 1] - 2u0[j] + u0[mod(j - 2, J) + 1]) for j in 1:J]
    end
    up, uc = u0, u1
    un = similar(u0)
    for _ in 2:nst
        for j in 1:J
            un[j] = 2uc[j] - up[j] + lam^2 * (uc[mod(j, J) + 1] - 2uc[j] + uc[mod(j - 2, J) + 1])
        end
        up .= uc; uc .= un
        maximum(abs.(uc)) > 1e8 && return 1e8
    end
    maximum(abs.(uc))
end

@assert wave_growth(0.99, 400, false) < 1.01 "λ=0.99 应稳定"
println("wave lambda=0.99: max|u| = ", round(wave_growth(0.99, 400, false), digits=4), " (stable)")
g100 = wave_growth(1.0, 200, true)
@assert g100 > 100 "λ=1 退化模式应线性增长（实测 $g100）"
@assert g100 < 4 * 200 "增长应线性量级而非指数（实测 $g100）"
println("wave lambda=1.0, degenerate (-1)^j mode: max|u| = ", g100,
        " after 200 steps (linear growth, book's special solution ~ 2n)")
@assert wave_growth(1.01, 400, false) > 1e3 "λ=1.01 应指数爆炸"
println("wave lambda=1.01: blows up (max|u| = ", wave_growth(1.01, 400, false), ")")

# ---------- (4) 离散能量有界 ----------
h = 0.01
lam = 0.5
J = round(Int, 1 / h)
nst = round(Int, 0.5 / (lam * h))
u, nst2 = wave_solve(h, lam, 0.5, 2)
# 能量账：格式等价于蛙跳，|μ|=1 ⟹ 解范数不增（每步范数有界）
@assert maximum(abs.(u)) < 1.01 "λ<1 时波幅不应增长"
println("wave lambda=0.5: amplitude bounded (max|u| = ",
        round(maximum(abs.(u)), digits=4), ") after T=0.5")

println("END ====")
