# 03_schemes.jl —— 第 03 章：差分格式的构造（Julia 通道）
#
#   (1) 差商精度表：前差/后差/中心差/二阶中心差对 sin x 的实测阶数；
#   (2) 对流方程三格式：迎风（FTBS）收敛、FTCS 中心与 FTFS 不稳定；
#   (3) 扩散方程显式 FTCS 的二阶收敛；
#   (4) 隐式 BTCS + 追赶法（Thomas 算法），大网格比仍稳定。

println("==== 03 schemes")

# ---------- (1) 差商精度表 ----------
f(x) = sin(x)
df(x) = cos(x)
d2f(x) = -sin(x)

function measured_order(ratio_fn, h1, h2)
    e1, e2 = ratio_fn(h1), ratio_fn(h2)
    log(e1 / e2) / log(h1 / h2)
end

fwd_err(h) = abs((f(1 + h) - f(1)) / h - df(1))
bwd_err(h) = abs((f(1) - f(1 - h)) / h - df(1))
ctr_err(h) = abs((f(1 + h) - f(1 - h)) / (2h) - df(1))
sec_err(h) = abs((f(1 + h) - 2 * f(1) + f(1 - h)) / h^2 - d2f(1))

orders = [measured_order(fn, 1.0e-2, 5.0e-3) for fn in (fwd_err, bwd_err, ctr_err, sec_err)]
for (name, o) in zip(("forward", "backward", "central", "2nd-central"), orders)
    println(name, " difference: measured order = ", round(o, digits=3))
end
@assert all(0.9 .< orders[1:2] .< 1.1) "前差/后差应为一阶"
@assert all(1.9 .< orders[3:4] .< 2.1) "中心差/二阶中心差应为二阶"

# ---------- (2) 对流方程三格式（周期域 [0,1)，精确解 = 平移） ----------
function advect(scheme, g, lambda, h, nsteps)
    J = round(Int, 1 / h)
    u = [g((j - 1) * h) for j in 1:J]          # 周期初值
    un = similar(u)
    jm(j) = (j == 1 ? J : j - 1)               # 周期左邻
    jp(j) = (j == J ? 1 : j + 1)               # 周期右邻
    for _ in 1:nsteps
        for j in 1:J
            if scheme == :ftbs                 # 迎风（a>0 取左差）
                un[j] = u[j] - lambda * (u[j] - u[jm(j)])
            elseif scheme == :ftfs             # 顺风格式（a>0 不稳定）
                un[j] = u[j] - lambda * (u[jp(j)] - u[j])
            elseif scheme == :ftcs             # 时间前差空间中心（无条件不稳定）
                un[j] = u[j] - lambda * 0.5 * (u[jp(j)] - u[jm(j)])
            end
        end
        u .= un
        maximum(abs.(u)) > 1e6 && return u
    end
    return u
end

g0(x) = exp(-100 * (x - 0.5)^2)
h = 0.01
Tend, lam = 0.4, 0.8
nst = round(Int, Tend / (lam * h))
u_ex = [g0(((j - 1) * h - Tend + 1.0) % 1.0) for j in 1:round(Int, 1 / h)]
u_num = advect(:ftbs, g0, lam, h, nst)
err1 = maximum(abs.(u_num .- u_ex))
println("FTBS advection lambda=0.8: max error = ", round(err1, sigdigits=3))

# FTBS 一阶收敛：h 减半误差减半
function ftbs_err(h)
    nst = round(Int, Tend / (lam * h))
    J = round(Int, 1 / h)
    u_num = advect(:ftbs, g0, lam, h, nst)
    u_ex = [g0(((j - 1) * h - Tend + 1.0) % 1.0) for j in 1:J]
    maximum(abs.(u_num .- u_ex))
end
e1, e2 = ftbs_err(2.0e-2), ftbs_err(1.0e-2)
ratio = e1 / e2
@assert 1.7 < ratio < 2.3 "FTBS 应一阶收敛（实测比 $ratio）"
println("FTBS convergence: h->h/2 error ratio = ", round(ratio, digits=3), "  (1st order)")

# FTCS（时间前差空间中心）与 FTFS：不稳定的两个反例
# （增长因子 |G|² = 1+μ²sin²θ 与 5−4cosθ，光滑初值的增长需足够步数积累）
u_ftcs = advect(:ftcs, g0, 1.0, h, 6 * nst)
u_ftfs = advect(:ftfs, g0, 1.0, h, 6 * nst)
@assert maximum(abs.(u_ftcs)) > 10 "FTCS-advection 应不稳定"
@assert maximum(abs.(u_ftfs)) > 10 "FTFS(a>0) 应不稳定"
println("FTCS-advection and FTFS(a>0): max|u| blows past 10 (unstable)")

# ---------- (3) 扩散方程显式 FTCS：二阶收敛 ----------
function heat_ftcs(h, r, Tend)
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
    end
    t = nst * tau
    u_ex = [exp(-pi^2 * t) * sin(pi * j * h) for j in 1:J]
    maximum(abs.(u .- u_ex))
end

e1 = heat_ftcs(2.0e-2, 0.25, 0.1)
e2 = heat_ftcs(1.0e-2, 0.25, 0.1)
ratio = e1 / e2
@assert 3.5 < ratio < 4.5 "FTCS 热传导固定 r 时应 O(h^2)（实测比 $ratio）"
println("FTCS heat r=0.25: h->h/2 error ratio = ", round(ratio, digits=3), "  (2nd order)")

# r = 0.6 > 1/2：显式格式爆掉
function heat_ftcs_max(h, r, nst)
    J = round(Int, 1 / h) - 1
    u = [sin(pi * j * h) for j in 1:J]
    un = similar(u)
    for _ in 1:nst
        for j in 1:J
            ul = (j == 1 ? 0.0 : u[j - 1])
            ur = (j == J ? 0.0 : u[j + 1])
            un[j] = u[j] + r * (ul - 2 * u[j] + ur)
        end
        u .= un
        maximum(abs.(u)) > 1e6 && return 1e6
    end
    maximum(abs.(u))
end
@assert heat_ftcs_max(0.02, 0.6, 200) > 10 "r=0.6 应不稳定"
println("FTCS heat r=0.6: unstable (max|u| exceeds 10)")

# ---------- (4) 隐式 BTCS + 追赶法（Thomas） ----------
"""三对角方程组追赶法：a*u_{j-1} + b*u_j + c*u_{j+1} = d（a、c 为次对角向量）。"""
function thomas(a, b, c, d)
    n = length(b)
    cp = zeros(n)
    dp = zeros(n)
    cp[1] = c[1] / b[1]
    dp[1] = d[1] / b[1]
    for i in 2:n
        m = b[i] - a[i] * cp[i - 1]
        cp[i] = c[i] / m
        dp[i] = (d[i] - a[i] * dp[i - 1]) / m
    end
    x = zeros(n)
    x[n] = dp[n]
    for i in n-1:-1:1
        x[i] = dp[i] - cp[i] * x[i + 1]
    end
    x
end

function heat_btcs(h, r, Tend)
    J = round(Int, 1 / h) - 1
    tau = r * h^2
    u = [sin(pi * j * h) for j in 1:J]
    nst = round(Int, Tend / tau)
    a = fill(-r, J); b = fill(1 + 2r, J); c = fill(-r, J)
    a[1] = 0.0; c[J] = 0.0                       # 边界值 0 并入右端
    for _ in 1:nst
        u = thomas(a, b, c, u)
    end
    t = nst * tau
    u_ex = [exp(-pi^2 * t) * sin(pi * j * h) for j in 1:J]
    maximum(abs.(u .- u_ex))
end

# r = 5（远超 1/2）：隐式依旧稳定且二阶
e1 = heat_btcs(2.0e-2, 5.0, 0.1)
e2 = heat_btcs(1.0e-2, 5.0, 0.1)
ratio = e1 / e2
@assert ratio > 3.5 && ratio < 4.5 "BTCS 固定 r 时应 O(h^2)（实测比 $ratio）"
println("BTCS heat r=5: h->h/2 error ratio = ", round(ratio, digits=3),
        "  (2nd order, unconditionally stable)")

println("END ====")
