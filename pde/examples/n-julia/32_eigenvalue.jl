# 32_eigenvalue.jl —— 第 32 章：特征值问题有限元 + 变分不等方程（Julia 通道）
#
#   (1) -u'' = λu 的有限元广义特征值问题 K c = λ M c（书 (4.31)）：
#       最小特征值 λ₁ 的收敛（一致质量 vs 集中质量/差分对照）；
#   (2) Rayleigh 商：λ_h = R(u_h) ≥ λ₁（最小极大原理）；
#   (3) 障碍问题（变分不等方程书 §3.2.2）：u ≥ ψ 约束下的投影 SOR。

println("==== 32 eigenvalue")

using LinearAlgebra

# ---------- (1) 广义特征值 ----------
function fem_eig(N; lump=false)
    h = 1 / N
    n = N - 1
    K = Tridiagonal(fill(-1/h, n - 1), fill(2/h, n), fill(-1/h, n - 1)) |> Matrix
    M = zeros(n, n)
    for k in 1:n
        M[k, k] = 2h / 3
        if k > 1; M[k, k-1] = h / 6; M[k-1, k] = h / 6; end
    end
    if lump
        M = Diagonal(fill(h, n)) |> Matrix
    end
    # 广义特征值 K c = λ M c ⟹ M^{-1/2} K M^{-1/2} 对称化
    evs = eigen(Symmetric(K), Symmetric(M)).values
    evs
end

# 精确：λ_j = (jπ)²，λ₁ = π² ≈ 9.8696
for N in (8, 16, 32)
    evs = fem_eig(N)
    println("N = ", N, ": lam1_h = ", round(evs[1], digits=4),
            "  lam2_h = ", round(evs[2], digits=4), "  (exact ", round(pi^2, digits=4),
            ", ", round(4pi^2, digits=4), ")")
end
evs32 = fem_eig(32)
@assert abs(evs32[1] - pi^2) / pi^2 < 1e-3 "lam1 应二阶收敛到 pi^2（相对差 $(abs(evs32[1]-pi^2)/pi^2)）"
@assert evs32[1] > pi^2 "最小特征值从上方逼近（Rayleigh-Ritz）"

# 集中质量（= 差分）对照：lam1 = (2/h²)(1 - cos(πh)) —— 也从上方？
evs_lump = fem_eig(32; lump=true)
println("lumped (difference scheme): lam1 = ", round(evs_lump[1], digits=4),
        " closed form 2(1-cos(pi h))/h^2 = ", round(2 * (1 - cos(pi / 32)) * 32^2, digits=4))
@assert abs(evs_lump[1] - 2 * (1 - cos(pi / 32)) * 32^2) < 1e-8

# ---------- (2) Rayleigh 商 ----------
N = 32
h = 1 / N
n = N - 1
v = [sin(pi * k * h) for k in 1:n]   # 近似第一特征函数
K = Tridiagonal(fill(-1/h, n-1), fill(2/h, n), fill(-1/h, n-1)) |> Matrix
M = zeros(n, n)
for k in 1:n
    M[k, k] = 2h/3
    if k > 1; M[k, k-1] = h/6; M[k-1, k] = h/6; end
end
R = (v' * K * v) / (v' * M * v)
println("Rayleigh quotient of sin(pi x): R = ", round(R[1], digits=6), " >= lam1_exact = ", round(pi^2, digits=6))
@assert R[1] >= pi^2 - 1e-9

# ---------- (3) 障碍问题 ----------
# -u'' = 1 于 (0,1)，u >= ψ = -0.1，u(0)=u(1)=0，无约束解 x(1-x)/2
# 最大值 0.125 > 0.1... 取 ψ = 0.05·sin(2πx)（负值障碍中段）
psi(k) = 0.05 * sin(2 * pi * k * h)
function obstacle_sor(N; omega=1.8, tol=1e-10)
    h = 1 / N
    n = N - 1
    u = [max(0.0, psi(k)) for k in 1:n]
    for _ in 1:500000
        diff = 0.0
        for k in 1:n
            ul = (k == 1 ? 0.0 : u[k-1]); ur = (k == n ? 0.0 : u[k+1])
            gs = 0.5 * (ul + ur + h^2 * 1.0)
            newv = max(psi(k), u[k] + omega * (gs - u[k]))
            diff = max(diff, abs(newv - u[k]))
            u[k] = newv
        end
        diff < tol && break
    end
    u
end
u_obs = obstacle_sor(64)
active = count(u_obs[k] <= psi(k) + 1e-8 for k in 1:63)
println("obstacle problem (psi = 0.05 sin(2 pi x)): active set size = ", active, "/63")
# 验证互补条件：u > ψ 处残差 ≈ 0；u = ψ 处 -u'' >= 0
function free_viol(u_obs, psi, N)
    mv = 0.0
    h = 1 / N
    for k in 2:N-2
        ul = u_obs[k-1]; ur = u_obs[k+1]
        lap = (ul - 2u_obs[k] + ur) / h^2
        if u_obs[k] > psi(k) + 1e-6
            mv = max(mv, abs(-lap - 1.0))
        end
    end
    mv
end
maxviol_free = free_viol(u_obs, psi, 64)
@assert maxviol_free < 1e-6 "自由区内 -u''=1 应成立（违反 $maxviol_free）"
println("complementarity check: in free region -u'' = 1 to ", round(maxviol_free, sigdigits=3))

println("END ====")

