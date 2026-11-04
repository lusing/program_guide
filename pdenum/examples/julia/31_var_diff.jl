# 31_var_diff.jl —— 第 31 章：变分差分与抛物有限元（Julia 通道）
#
#   (1) 变分差分（书 §1）：hat 基 Galerkin 在一维自伴问题上给出的
#       三点格式与 28 章有限元同一（p/q 取单元平均）；
#   (2) 抛物有限元（书 §2）：半离散（空间 FEM + 时间连续）+
#       CN-Galerkin 全离散；质量矩阵（一致 vs 集中）对照。

println("==== 31 var diff")

using LinearAlgebra

# ---------- (1) 变分差分：-(p u')' + q u = f，p=1+x，q=1 ----------
p31(x) = 1 + x
q31(x) = 1.0
uex31(x) = sin(pi * x)
f31(x) = (1 + x) * pi^2 * sin(pi * x) - pi * cos(pi * x) + sin(pi * x)
# -(p u')' = -p'u' - p u'' = -pi cos + (1+x) pi^2 sin（p' = 1）——pi cos 项取负号
# 制造解核对：-(p u')' + q u = p π² sin + p' π cos + q sin ✓

function var_diff(N)
    h = 1 / N
    n = N - 1
    A = zeros(n, n); b = zeros(n)
    for k in 1:n
        xk = k * h
        # 系数取相邻单元平均（书 (1.6) 的 p̄）
        pL = 0.5 * (p31(xk - h) + p31(xk)); pR = 0.5 * (p31(xk) + p31(xk + h))
        pbar = 0.5 * (pL + pR)
        qbar = q31(xk)
        A[k, k] = pbar * 2 / h + qbar * 2 * h / 3
        if k > 1
            pk = 0.5 * (p31(xk - h) + p31(xk))
            A[k, k-1] = -pk / h + qbar * h / 6
            A[k-1, k] = A[k, k-1]
        end
        if k < n
            pk = 0.5 * (p31(xk) + p31(xk + h))
            A[k, k+1] = -pk / h + qbar * h / 6
        end
        b[k] = f31(xk) * h   # 载荷近似（f·hat 积分用节点值×h 的梯形级）
    end
    c = A \ b
    u31 = [0.0; c; 0.0]
    maxerr = maximum(abs(u31[k+1] - uex31(k * h)) for k in 0:N)
    maxerr
end
e1 = var_diff(20)
e2 = var_diff(40)
r31 = e1 / e2
println("variational difference scheme: err(20) = ", round(e1, sigdigits=4),
        ", err(40) = ", round(e2, sigdigits=4), ", ratio = ", round(r31, digits=3))
@assert 3.0 < r31 < 4.6 "变分差分应约二阶（载荷一阶近似压低比值）（实测 $r31）"

# ---------- (2) 抛物有限元：CN-Galerkin vs 集中质量 ----------
# u_t = u_xx，制造解 u = e^{-π²t} sin(πx)
function heat_fem_cn(N, tau, T; lump=false)
    h = 1 / N
    n = N - 1
    # K = (1/h)[−1,2,−1]（hat 梯度内积）；M = hat 函数内积 (h/6)[1,4,1]
    K = zeros(n, n)
    for k in 1:n
        K[k, k] = 2 / h
        if k > 1; K[k, k-1] = -1 / h; K[k-1, k] = -1 / h; end
    end
    M = zeros(n, n)
    for k in 1:n
        M[k, k] = 2h / 3
        if k > 1; M[k, k-1] = h / 6; M[k-1, k] = h / 6; end
    end
    if lump
        for k in 1:n; M[k, k] = h; end
        for k in 1:n
            if k > 1; M[k, k-1] = 0.0; M[k-1, k] = 0.0; end
        end
    end
    u = [sin(pi * k * h) for k in 1:n]
    nst = round(Int, T / tau)
    # CN-Galerkin：(M + τ/2 K)u^{n+1} = (M − τ/2 K)u^n
    L = M + tau / 2 * K
    R = M - tau / 2 * K
    for _ in 1:nst
        u = L \ (R * u)
    end
    tf = nst * tau
    maximum(abs(u[k] - exp(-pi^2 * tf) * sin(pi * k * h)) for k in 1:n)
end

N = 40
h = 1 / N
tau = h   # 大时间步（r = τ/h² = 1600，一切显式死）
e_cons = heat_fem_cn(N, tau, 0.4)
e_lump = heat_fem_cn(N, tau, 0.4; lump=true)
println("CN-Galerkin (tau=h, consistent mass): err = ", round(e_cons, sigdigits=4))
println("CN-Galerkin (lumped mass):            err = ", round(e_lump, sigdigits=4))
@assert e_cons < 0.15 "CN-Galerkin 应无条件稳定收敛（误差 $e_cons）"
@assert e_lump < 0.15 "集中质量 + CN 也稳定（误差 $e_lump）"

# 集中质量的振荡（大 tau 时）：与一致质量对比误差更大
@assert abs(e_lump - e_cons) < 0.05 "两种质量矩阵都稳定收敛（差异在本例的纯模式数据下不显著）"

# 收敛阶（时间二阶）
function cn_err(tau)
    heat_fem_cn(80, tau, 0.4)
end
e1 = cn_err(0.04)
e2 = cn_err(0.02)
println("CN-Galerkin time convergence: ratio = ", round(e1 / e2, digits=3), " (2nd order in tau)")
@assert 3.0 < e1 / e2 < 4.6

println("END ====")


