# 33_bem_mg.jl —— 第 33 章：边界元与多重网格（Julia 通道）
#
#   (1) 边界元（书 §5）：圆域 Laplace 边界积分的常数元离散——
#       单层位势矩阵 + 边界方程求解，与解析解对照；
#   (2) 多重网格（书 §6）：二层网格 V 循环（粗解 + 延拓 + 光滑），
#       与 Jacobi 收敛因子对照。

println("==== 33 bem mg")

# ---------- (1) 边界元：单位圆 Dirichlet 问题 ----------
# Δu = 0 于圆内，u|∂ = cos(2θ)：解析解 u = r²cos(2θ)
# 常数元：边界分 N 段，单层位势 G = -ln|x-x'|/(2π)（二维）
# 边界方程（第一类）：Σ G_ij σ_j = u_i（配置在段中点）
function bem_circle(N)
    dth = 2 * pi / N
    # 段中点
    thm = [(j - 0.5) * dth for j in 1:N]
    G = zeros(N, N)
    for i in 1:N, j in 1:N
        if i == j
            # 常数元的对角自项：∫∫ -ln|r-r'|/(2π) ≈ (dth/(2π))·(1 - ln(dth/2))
            G[i, j] = (dth / (2pi)) * (1 - log(dth / 4))
        else
            # 两段中点距离
            d = 2 * abs(sin((thm[i] - thm[j]) / 2))
            G[i, j] = -(dth / (2pi)) * log(d)
        end
    end
    b = [cos(2 * thm[i]) for i in 1:N]
    sigma = G \ b
    # 内点解：u(x) = Σ σ_j ∫G dS ≈ Σ σ_j G(x, x_j)·dth
    function ueval(r, theta)
        s = 0.0
        for j in 1:N
            d = sqrt(r^2 + 1 - 2 * r * cos(theta - thm[j]))
            s += sigma[j] * (dth / (2pi)) * (-log(d))
        end
        s
    end
    ueval
end
uev = bem_circle(64)
maxerr = maximum(abs(uev(r, th) - r^2 * cos(2 * th))
                 for (r, th) in ((0.3, 0.7), (0.5, 2.1), (0.7, 4.0), (0.5, 0.0)))
println("BEM (constant elements, N=64): max err at 4 interior points = ", round(maxerr, sigdigits=4))
@assert maxerr < 0.05 "边界元应基本收敛（误差 $maxerr）"

# ---------- (2) 多重网格 V 循环 ----------
# 模型：-u'' = f（同 21 章制造解 x²-y²+sin sin 的 1D 版）
# f = 1 + π²sin(πx)，u = x²/2 + sin(πx)... 取 1D：-u''=1，u(0)=u(1)=0 ⟹ u=x(1-x)/2
# 光滑：Jacobi（ω=2/3 加权）
function mg_vcycle(N)
    h = 1 / N
    n = N - 1
    u = zeros(n)
    f = ones(n)     # -u''=1
    # 前光滑（ν1=3 步加权 Jacobi）
    w = 2.0 / 3.0
    for _ in 1:3
        un = copy(u)
        for k in 1:n
            ul = (k == 1 ? 0.0 : u[k-1]); ur = (k == n ? 0.0 : u[k+1])
            un[k] = (1 - w) * u[k] + w * 0.5 * (ul + ur + h^2)
        end
        u .= un
    end
    # 粗网格残差校正：r = f - Au；限制（全权重）
    Nc = div(N, 2)
    nc = Nc - 1
    hc = 1 / Nc
    r = [f[k] - ((k==1 ? 0.0 : u[k-1]) - 2u[k] + (k==n ? 0.0 : u[k+1])) / h^2 for k in 1:n]
    rc = [0.5 * r[2k] + 0.25 * (r[2k-1] + r[2k+1]) for k in 1:nc]
    ec = zeros(nc)
    for _ in 1:20000
        ecn = copy(ec)
        for k in 1:nc
            ul = (k == 1 ? 0.0 : ec[k-1]); ur = (k == nc ? 0.0 : ec[k+1])
            ecn[k] = 0.5 * (ul + ur - hc^2 * rc[k])   # A e = rc 符号：rc 项取负
        end
        ec .= ecn
        maximum(abs.(ec)) < 1e-12 && break
    end
    # 延拓（线性插值）
    e = [ec[1] / 2]
    for k in 1:nc-1
        push!(e, (ec[k] + ec[k+1]) / 2)
        push!(e, ec[k+1])
    end
    push!(e, ec[nc] / 2)
    u .+= e
    # 后光滑（ν2=3 步）
    for _ in 1:3
        un = copy(u)
        for k in 1:n
            ul = (k == 1 ? 0.0 : u[k-1]); ur = (k == n ? 0.0 : u[k+1])
            un[k] = (1 - w) * u[k] + w * 0.5 * (ul + ur + h^2)
        end
        u .= un
    end
    u
end

function solve_mg(N; cycles=8)
    h = 1 / N; n = N - 1
    # mg_vcycle 每圈从零出发求解（线性问题：一圈即含粗网格校正，
    # 多圈作为松弛迭代逼近）；这里改为圈间传递当前解
    u = zeros(n)
    for cyc in 1:cycles
        u = mg_vcycle_from(u, N)
    end
    uex = [k * h * (1 - k * h) / 2 for k in 1:n]
    maximum(abs.(u .- uex))
end

function mg_vcycle_from(u, N)
    h = 1 / N; n = N - 1
    # 光滑步求解的是 δ²u/h² = −1（即 −u″=1），残差须用同一符号约定
    f = fill(-1.0, n)
    w = 2.0 / 3.0
    for _ in 1:3
        un = copy(u)
        for k in 1:n
            ul = (k == 1 ? 0.0 : u[k-1]); ur = (k == n ? 0.0 : u[k+1])
            un[k] = (1 - w) * u[k] + w * 0.5 * (ul + ur + h^2)
        end
        u .= un
    end
    Nc = div(N, 2); nc = Nc - 1; hc = 1 / Nc
    r = [f[k] - ((k==1 ? 0.0 : u[k-1]) - 2u[k] + (k==n ? 0.0 : u[k+1])) / h^2 for k in 1:n]
    rc = [0.5 * r[2k] + 0.25 * (r[2k-1] + r[2k+1]) for k in 1:nc]
    ec = zeros(nc)
    for _ in 1:20000
        ecn = copy(ec)
        for k in 1:nc
            ul = (k == 1 ? 0.0 : ec[k-1]); ur = (k == nc ? 0.0 : ec[k+1])
            ecn[k] = 0.5 * (ul + ur - hc^2 * rc[k])   # A e = rc 符号：rc 项取负
        end
        ec .= ecn
        maximum(abs.(ec)) < 1e-12 && break
    end
    # 延拓：细网格 n = 2nc+1 个内点；偶下标 = 粗值，奇下标 = 平均
    e = zeros(n)
    for k in 1:nc
        e[2k] = ec[k]
    end
    e[1] = ec[1] / 2
    for k in 1:nc-1
        e[2k+1] = (ec[k] + ec[k+1]) / 2
    end
    e[n] = ec[nc] / 2
    u .+= e
    for _ in 1:3
        un = copy(u)
        for k in 1:n
            ul = (k == 1 ? 0.0 : u[k-1]); ur = (k == n ? 0.0 : u[k+1])
            un[k] = (1 - w) * u[k] + w * 0.5 * (ul + ur + h^2)
        end
        u .= un
    end
    u
end

# 单次 V 循环的收敛：误差缩减因子（V 循环 vs Jacobi 同步数）
err_after1 = solve_mg(64; cycles=1)
err_after2 = solve_mg(64; cycles=2)
rho_mg = err_after2 / err_after1
println("multigrid V-cycle: err(1 cyc) = ", round(err_after1, sigdigits=4),
        ", err(2 cyc) = ", round(err_after2, sigdigits=4))
println("  contraction factor ~ ", round(rho_mg, digits=3), " (mesh-independent)")

# Jacobi 对照（同 6 步工作量）
function jacobi_n(N, steps)
    h = 1 / N; n = N - 1
    u = zeros(n)
    for _ in 1:steps
        un = copy(u)
        for k in 1:n
            ul = (k == 1 ? 0.0 : u[k-1]); ur = (k == n ? 0.0 : u[k+1])
            un[k] = 0.5 * (ul + ur + h^2)
        end
        u .= un
    end
    uex = [k * h * (1 - k * h) / 2 for k in 1:n]
    maximum(abs.(u .- uex))
end
e_j1 = jacobi_n(64, 6)
e_j2 = jacobi_n(64, 12)
rho_j = e_j2 / e_j1
println("Jacobi (same work): rho ~ ", round(rho_j, digits=3))
@assert rho_mg < rho_j "V 循环的收缩因子应优于 Jacobi（$(rho_mg) vs $(rho_j)）"
@assert err_after2 < 0.02 "V 循环两圈应基本收敛（$(err_after2)）"

println("END ====")

