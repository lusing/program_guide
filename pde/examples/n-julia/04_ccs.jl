# 04_ccs.jl —— 第 04 章：相容性、收敛性、稳定性与 Lax 等价定理（Julia 通道）
#
#   (1) 相容但不稳定 ⟹ 实际不收敛：FTCS-advection 的误差随 h 减小而增大；
#   (2) FTCS 热传导：r=0.25 收敛 O(h²)，r=0.6 爆炸（书 §2.3 定理的条件不可省）；
#   (3) 复现书图 2.11 的数值实验：Lax-Friedrichs 格式 λ=0.9/1.0/1.1；
#   (4) 收敛阶 = 精度组合：BTCS 取 τ=h 只有一阶，取 τ=5h² 有二阶；
#   (5) FTFS(a>0) 依赖域错配：误差随加密单调增大（不收敛的直接证据）。

println("==== 04 ccs")

# ---------- 底座：对流/扩散求解器（与 03 章同款） ----------
function advect(scheme, g, lam, h, nsteps)
    J = round(Int, 1 / h)
    u = [g((j - 1) * h) for j in 1:J]
    un = similar(u)
    jm(j) = (j == 1 ? J : j - 1)
    jp(j) = (j == J ? 1 : j + 1)
    for _ in 1:nsteps
        for j in 1:J
            if scheme == :ftbs
                un[j] = u[j] - lam * (u[j] - u[jm(j)])
            elseif scheme == :ftfs
                un[j] = u[j] - lam * (u[jp(j)] - u[j])
            elseif scheme == :ftcs
                un[j] = u[j] - lam * 0.5 * (u[jp(j)] - u[jm(j)])
            elseif scheme == :lf    # Lax-Friedrichs
                un[j] = 0.5 * (u[jp(j)] + u[jm(j)]) - lam * 0.5 * (u[jp(j)] - u[jm(j)])
            end
        end
        u .= un
        maximum(abs.(u)) > 1e8 && return u
    end
    return u
end

g0(x) = exp(-100 * (x - 0.5)^2)
function adv_err(scheme, g, lam, h, Tend)
    nst = round(Int, Tend / (lam * h))
    J = round(Int, 1 / h)
    u = advect(scheme, g, lam, h, nst)
    uex = [g(((j - 1) * h - Tend + 1.0) % 1.0) for j in 1:J]
    maximum(abs.(u .- uex))
end

# ---------- (1) 稳定性的本义：初始扰动的传播 ----------
# 稳定性定义（书 (2.15)）：‖εⁿ‖ ≤ K‖ε⁰‖。取 θ=π/2 的网格波型扰动
# δ⁰_j = ε·sin(πj/2)（FTCS 增长因子的峰所在：|G(π/2)|=√(1+λ²)；
# 注意中心差分把 Nyquist 模式 (−1)^j 打到 G=1，峰不在 θ=π），
# 看它随步数的命运：FTBS(λ≤1) 压缩，FTCS 指数放大。
function perturb_growth(scheme, lam, h, nsteps)
    J = round(Int, 1 / h)
    eps0 = 1.0e-6
    u = [eps0 * sin(pi * (j - 1) / 2) for j in 1:J]
    un = similar(u)
    jm(j) = (j == 1 ? J : j - 1)
    jp(j) = (j == J ? 1 : j + 1)
    for _ in 1:nsteps
        for j in 1:J
            if scheme == :ftbs
                un[j] = u[j] - lam * (u[j] - u[jm(j)])
            else
                un[j] = u[j] - lam * 0.5 * (u[jp(j)] - u[jm(j)])
            end
        end
        u .= un
    end
    maximum(abs.(u)) / eps0
end
h, lam = 0.01, 0.8
n = round(Int, 0.4 / (lam * h))
grow_ftbs = perturb_growth(:ftbs, lam, h, n)
grow_ftcs = perturb_growth(:ftcs, lam, h, n)
println("theta=pi/2 mode perturbation after n = ", n, " steps:")
println("  FTBS (lambda=0.8): amplitude ratio = ", round(grow_ftbs, sigdigits=3))
println("  FTCS:             amplitude ratio = ", round(grow_ftcs, sigdigits=3))
@assert grow_ftbs < 1.0e-3 "稳定格式应压缩扰动（|G|=0.825 per step）"
@assert grow_ftcs > 100.0 "不稳定格式应指数放大（|G|=sqrt(1+lam^2)=1.28 per step）"

# 对照：FTBS（λ=0.8 ≤ 1）对光滑数据一阶收敛
e1 = adv_err(:ftbs, g0, 0.8, 2.0e-2, 0.4)
e2 = adv_err(:ftbs, g0, 0.8, 1.0e-2, 0.4)
@assert 1.7 < e1 / e2 < 2.3 "FTBS 应一阶收敛"
println("FTBS (stable): h->h/2 error ratio = ", round(e1 / e2, digits=3), "  (convergent)")

# ---------- (2) FTCS 热传导：条件不可省 ----------
function heat_err(h, r, Tend)
    J = round(Int, 1 / h) - 1
    tau = r * h^2
    u = [sin(pi * j * h) for j in 1:J]
    nst = round(Int, Tend / tau)
    un = similar(u)
    for _ in 1:nst
        for j in 1:J
            ul = (j == 1 ? 0.0 : u[j - 1])
            ur = (j == J ? 0.0 : u[j + 1])
            un[j] = u[j] + r * (ul - 2 * u[j] + ur)
        end
        u .= un
        maximum(abs.(u)) > 1e8 && return 1e8
    end
    t = nst * tau
    uex = [exp(-pi^2 * t) * sin(pi * j * h) for j in 1:J]
    maximum(abs.(u .- uex))
end

e_stable = heat_err(0.01, 0.25, 0.1)
e_unstable = heat_err(0.01, 0.6, 0.1)
@assert e_stable < 1e-4 "r=0.25 时误差应 O(h^2) 级"
@assert e_unstable > 1e3 "r=0.6 时应爆炸"
println("FTCS heat: r=0.25 error = ", round(e_stable, sigdigits=3),
        "; r=0.6 error = ", e_unstable, " (condition 2r<=1 indispensable)")

# ---------- (3) 书图 2.11 的数字版：Lax-Friedrichs ----------
println("--- Lax-Friedrichs (book Fig 2.11): lambda = 0.9 / 1.0 / 1.1 ---")
gsq(x) = (0.25 < x < 0.75) ? 1.0 : 0.0   # 方波脉冲（书的实验形态）
for lam in (0.9, 1.0, 1.1)
    u = advect(:lf, gsq, lam, 0.02, 40)
    println("  lambda = ", lam, "  max|u| after 40 steps = ", round(maximum(abs.(u)), digits=4))
end
u9 = advect(:lf, gsq, 0.9, 0.02, 40)
u10 = advect(:lf, gsq, 1.0, 0.02, 40)
u11 = advect(:lf, gsq, 1.1, 0.02, 40)
@assert maximum(abs.(u9)) <= 1.0 + 1e-10 "λ=0.9 时 |G|<=1，方波幅值不增"
@assert maximum(abs.(u10)) <= 1.0 + 1e-10 "λ=1.0 时 |G|=1 临界"
@assert maximum(abs.(u11)) > 5 "λ=1.1 时应指数增长"
println("LF: lambda<=1 amplitude bounded; lambda=1.1 grows to ",
        round(maximum(abs.(u11)), digits=1))

# ---------- (4) 收敛阶 = 精度组合 ----------
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

function heat_btcs_err_tau(h, tau, Tend)
    J = round(Int, 1 / h) - 1
    r = tau / h^2
    u = [sin(pi * j * h) for j in 1:J]
    nst = round(Int, Tend / tau)
    a = fill(-r, J); b = fill(1 + 2r, J); c = fill(-r, J)
    a[1] = 0.0; c[J] = 0.0
    for _ in 1:nst
        u = thomas(a, b, c, u)
    end
    t = nst * tau
    uex = [exp(-pi^2 * t) * sin(pi * j * h) for j in 1:J]
    maximum(abs.(u .- uex))
end

# τ = h：截断 O(τ) 主导 ⟹ 一阶
ea = heat_btcs_err_tau(2.0e-2, 2.0e-2, 0.1)
eb = heat_btcs_err_tau(1.0e-2, 1.0e-2, 0.1)
ratio1 = ea / eb
@assert 1.7 < ratio1 < 2.3 "τ=h 时应一阶（实测比 $ratio1）"
println("BTCS with tau=h:     h->h/2 error ratio = ", round(ratio1, digits=3), "  (1st order)")

# τ = 5h²：O(h²) 主导 ⟹ 二阶
ea = heat_btcs_err_tau(2.0e-2, 5 * 2.0e-2^2, 0.1)
eb = heat_btcs_err_tau(1.0e-2, 5 * 1.0e-2^2, 0.1)
ratio2 = ea / eb
@assert 3.5 < ratio2 < 4.5 "τ=5h² 时应二阶（实测比 $ratio2）"
println("BTCS with tau=5h^2:  h->h/2 error ratio = ", round(ratio2, digits=3), "  (2nd order)")

# ---------- (5) FTFS(a>0)：依赖域错配 ⟹ 不收敛（书 §2.3 论证的数值版） ----------
# x*=0.6, T*=0.4, a=1：真解依赖 g(0.2)；FTFS 的依赖集是 [0.6, 1.1]（右侧），
# 永远看不到 0.2。取两组初值：g2 = g1 + 0.2 处的单位脉冲。
# FTFS 对两组数据算出**同一个数**，而真解相差 ≈ 1 —— 两组误差之和 ≥ 0.9。
println("--- FTFS (a>0): dependence-domain mismatch ---")
gbump(x) = exp(-((x - 0.2) / 0.01)^2)
g1(x) = exp(-100 * (x - 0.5)^2)
g2(x) = g1(x) + gbump(x)
xstar, tstar = 0.6, 0.4
for h in (4.0e-2, 2.0e-2, 1.0e-2, 5.0e-3)
    nst = round(Int, tstar / (0.8 * h))
    jstar = round(Int, xstar / h) + 1
    u1 = advect(:ftfs, g1, 0.8, h, nst)
    u2 = advect(:ftfs, g2, 0.8, h, nst)
    diff12 = abs(u1[jstar] - u2[jstar])
    ev1 = abs(u1[jstar] - g1(((xstar - tstar) % 1.0 + 1.0) % 1.0))
    ev2 = abs(u2[jstar] - g2(((xstar - tstar) % 1.0 + 1.0) % 1.0))
    println("  h = ", h, "  e(g1) = ", round(ev1, sigdigits=3),
            "  e(g2) = ", round(ev2, sigdigits=3), "  sum = ", round(ev1 + ev2, sigdigits=3),
            "  |u1-u2| = ", round(diff12, sigdigits=3))
    # 论证：真解相差 1，而 FTFS 的依赖集（右侧）不读 x=0.2，|u1−u2| 只能来自
    # 舍入放大（细网格上格式不稳定 (|G(pi)|=1+2λ) 反而把它放大——又一个不稳
    # 定性的实证）。无论如何 e1+e2 ≥ 1 − |u1−u2|−(分离误差)，远离 0：
    @assert ev1 + ev2 > 0.9 "两组真解相差 ≈1 而 FTFS 给出同一个数：不可能同时收敛"
end

println("END ====")
