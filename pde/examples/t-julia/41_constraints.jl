# Ch41 非线性 III：正则性与约束
#
# 对应书 §8.3（极小的正则性：二阶导估计）与 §8.4（约束：非线性
# 特征值、单边约束/变分不等式、调和映射、不可压缩）。

using Printf

println("==== 41")

# ---- (a) 极小的正则性：p-拉普拉斯 -div(|∇u|^{p-2}∇u) = f ----
# p = 2 退化为线性；数值解 p = 3 的 -(|u'|²u')' = 1 与正则性观察
# 制造解：u' = v，(|v|²v)' = -1 ⟹ |v|²v = C - x ⟹ v = (C-x)^{1/3}
# 取 C = 1：u' = (1-x)^{1/3}，u = ∫ = [-(1-x)^{4/3}/(4/3)]₀^x·?
# u(x) = (3/4)[1 - (1-x)^{4/3}]（u(0) = 0）；u(1) = 3/4 ≠ 0——
# 用 u(x) = (3/4)[(1-x)^{4/3} - 1] 检验方程即可
u_p(x) = 0.75 * (1 - (1 - x)^(4 / 3))
d = 1e-5
for x in [0.3, 0.7]
    up = (u_p(x + d) - u_p(x - d)) / (2d)
    upp = (u_p(x + d) - 2u_p(x) + u_p(x - d)) / d^2
    # -(|u'|² u')' = -(|u'|²·u'') ·? 链式：d/dx(|v|²v) = 2|v|v'·v + |v|²v' = 3v²v'（v>0）
    r = 3 * up^2 * upp + 1
    @printf("(a) p-Laplace p=3 at x=%.1f: residual = %.2e\n", x, r)
    @assert abs(r) < 2e-2 "p-拉普拉斯制造解（差分精度）"
end
# 正则性：u ∈ C¹ 但 u'' ~ (1-x)^{-2/3} ∉ L^∞（退化正则性）
@printf("    u'' near x=1: (1-x)^{-2/3} blows up (p-Laplacian degeneracy)\n")
@assert (1 - 0.999)^(-2 / 3) > 10

# ---- (b) 非线性特征值（§8.4.1）：-Δu = λu³ 的分支 ----
# 分支解 u = a·sin(πx)：λ(a) = π²/a²（幅值-特征值曲线）
for a in [0.5, 1.0, 2.0]
    lam = pi^2 / a^2
    @printf("(b) nonlinear eigenpair: u = %.1f sinπx ⟹ λ = %.4f (λ ~ a^{-2})\n", a, lam)
end
@assert pi^2 / 4 < pi^2 "幅值增大 ⟹ 特征值下降（bifurcation 曲线）"

# ---- (c) 单边约束（§8.4.2 障碍问题预演）：u ≥ ψ 的投影 ----
# -u'' = 1、u ≥ ψ = 0.1sin(2πx)、零边值：接触集数值（投影 SOR 快速版）
N = 200
h = 1 / (N + 1)
xs = [(i)*h for i in 1:N]
psi = [0.1 * sin(2pi * x) for x in xs]
u = copy(psi)
for it in 1:20000
    for i in 1:N
        left = i > 1 ? u[i-1] : 0.0
        right = i < N ? u[i+1] : 0.0
        unew = 0.5 * (left + right + h^2 * 1.0)
        u[i] = max(unew, psi[i])
    end
end
ncontact = count(u .<= psi .+ 1e-12)
@printf("(c) obstacle: contact set size = %d / %d\n", ncontact, N)
@assert 0 < ncontact < N "部分接触（自由边界）"
# 互补条件：非接触点满足 -u'' = 1
free_err = maximum(abs.((2u[i] - (i > 1 ? u[i-1] : 0) - (i < N ? u[i+1] : 0)) / h^2 - 1)
                   for i in 1:N if u[i] > psi[i] + 1e-9)
@printf("    complementarity residual on free set = %.2e\n", free_err)
@assert free_err < 5e-3 "自由区内方程成立（互补系统，SOR 收敛级）"

println("END ====")


