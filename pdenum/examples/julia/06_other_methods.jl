# 06_other_methods.jl —— 第 06 章：Hirt / 矩阵法 / 能量法（Julia 通道）
#
#   (1) Hirt 启示法：迎风格式第一微分近似的耗散系数 ν = (ah/2)(1−λ)，
#       数值衰减率与修正方程预测 exp(−νk²t) 对账；
#   (2) 矩阵法：FTCS/BTCS 热传导的增长矩阵特征值 vs 闭式
#       1 − 4r·sin²(kπh/2) / 1 + 4r·sin²(kπh/2)；
#   (3) 能量法：迎风格式 λ ≤ 1 时 ℓ² 范数单调不增（凸性不等式），
#       违反 (4.19)（λ > 1）时增长；变系数 a(x) 的漂移界。

println("==== 06 other methods")

# ---------- (1) Hirt：修正方程的耗散率 ----------
# 迎风格式 (1.9) 的第一微分近似：u_t + a u_x = (a/2)(h − aτ) u_xx，
# 耗散系数 ν = (ah/2)(1−λ)。单波 e^{ikx} 的幅度按 e^{−νk²t} 衰减。
a, h, lam = 1.0, 0.01, 0.8
kmode = 10 * pi
Tend = 0.1
J = round(Int, 1 / h)
tau = lam * h / a
u = [cos(kmode * (j - 1) * h) for j in 1:J]
nst = round(Int, Tend / tau)
un = similar(u)
for _ in 1:nst
    for j in 1:J
        jm = (j == 1 ? J : j - 1)
        un[j] = u[j] - lam * (u[j] - u[jm])
    end
    u .= un
end
amp = maximum(abs.(u))   # 波幅
nu = (a * h / 2) * (1 - lam)
pred = exp(-nu * kmode^2 * Tend)
rel = abs(amp - pred) / pred
@assert rel < 5.0e-3 "修正方程预测应匹配数值衰减（相对差 $rel）"
println("Hirt: numerical amplitude = ", round(amp, digits=6),
        "  modified-eq prediction exp(-nu k^2 t) = ", round(pred, digits=6),
        "  rel diff = ", round(rel, sigdigits=2))
# 反向验证：FTFS 的第一微分近似扩散系数 (a/2)(h + aτ·(−1))... 即
# (h + aτ)a/2 > 0？——书 §4.1：FTFS(a>0) 修正方程的 u_xx 系数为
# -(a/2)(h + aτ) < 0（负耗散，反扩散）⟹ 不稳定。数值确认：
u = [cos(kmode * (j - 1) * h) for j in 1:J]
for _ in 1:nst
    for j in 1:J
        jp = (j == J ? 1 : j + 1)
        un[j] = u[j] - lam * (u[jp] - u[j])
    end
    u .= un
end
println("Hirt (reversed): FTFS amplitude after same time = ",
        round(maximum(abs.(u)), digits=4), "  (negative diffusion -> growth)")

# ---------- (2) 矩阵法：特征值闭式对账 ----------
using LinearAlgebra
Jm1 = 39                       # 内点数 J-1
hh = 1 / (Jm1 + 1)
for r in (0.25, 0.49, 0.51, 5.0)
    A = SymTridiagonal(fill(1 - 2r, Jm1), fill(r, Jm1 - 1))
    ev = Vector(eigvals(A))
    theory = sort([1 - 4 * r * sin(k * pi * hh / 2)^2 for k in 1:Jm1])
    maxdiff = maximum(abs.(ev .- theory))
    @assert maxdiff < 1.0e-9 "特征值应与闭式吻合（r=$r, maxdiff=$maxdiff）"
end
println("matrix method: eigvals of FTCS growth matrix match 1-4r sin^2(k pi h/2) to 1e-9")
# 稳定判据：ρ(A) ≤ 1 ⟺ r ≤ 1/2（对称矩阵，谱半径=谱范数）
rho(r) = maximum(abs, eigvals(SymTridiagonal(fill(1 - 2r, Jm1), fill(r, Jm1 - 1))))
@assert rho(0.5) < 1.0 "r=1/2 时最危险模式 sin²<1 严格 <1"
@assert rho(0.51) > 1.0 "r>1/2 应出界"
println("rho(A): r=0.5 -> ", round(rho(0.5), digits=4),
        "; r=0.51 -> ", round(rho(0.51), digits=4), " (>1)")
# BTCS：B = (1+2r)I − r S，B^{-1} 对称，特征值 1/(1+4r sin²) < 1
r5 = 5.0
B = SymTridiagonal(fill(1 + 2r5, Jm1), fill(-r5, Jm1 - 1))
rhoB = maximum(abs, eigvals(inv(Matrix(B))))
@assert rhoB < 1.0 "BTCS 增长矩阵逆的谱半径应 < 1"
println("BTCS r=5: rho(B^{-1}) = ", round(rhoB, digits=4), " < 1 (unconditionally stable)")

# ---------- (3) 能量法：凸性与 ℓ² 单调性 ----------
# 迎风更新 u_j^{n+1} = (1−λ_j)u_j + λ_j u_{j−1}；λ 数组逐点给出
function l2_evolve(lams, u0, nst)
    u = copy(u0)
    J = length(u)
    un = similar(u)
    norms = Float64[sqrt(sum(abs2, u))]
    for _ in 1:nst
        for j in 1:J
            jm = (j == 1 ? J : j - 1)
            un[j] = (1 - lams[j]) * u[j] + lams[j] * u[jm]
        end
        u .= un
        push!(norms, sqrt(sum(abs2, u)))
    end
    norms
end

uf = [sin(2 * pi * 5 * j / 64) + 0.3 * sin(2 * pi * 13 * j / 64) for j in 0:63]
norms = l2_evolve(fill(0.9, 64), uf, 50)
monotone = all(norms[i+1] <= norms[i] + 1e-12 for i in 1:length(norms)-1)
@assert monotone "λ=0.9 ≤ 1 时 ℓ² 范数应单调不增（凸性）"
println("energy method: l2 norm monotonically non-increasing for lambda=0.9 (",
        round(norms[1], digits=3), " -> ", round(norms[end], digits=3), ")")

# 违反 (4.19)：λ = 1.05 > 1 → 增长
norms_bad = l2_evolve(fill(1.05, 64), uf, 50)
@assert norms_bad[end] > 2 * norms_bad[1] "λ>1 应增长"
println("lambda=1.05: l2 grows ", round(norms_bad[1], digits=3), " -> ",
        round(norms_bad[end], digits=3), " (violating (4.19))")

# 变系数 a(x) = 1 + 0.5x：λ(x) = a(x)τ/h ≤ 0.9，能量漂移界
hh2 = 1 / 64
axfun(x) = 1 + 0.5 * x
tau2 = 0.9 * hh2 / maximum(axfun.(0:hh2:1))
lams_var = [axfun((j) * hh2) * tau2 / hh2 for j in 0:63]
norms_var = l2_evolve(lams_var, uf, 50)
bound = (1 + 0.9 * 0.5 * hh2)^50   # 每步漂移 ≤ λ_max·max|Δa| = 0.9·0.5h
@assert norms_var[end] <= norms_var[1] * bound + 1e-10
println("a(x)=1+0.5x: growth ", round(norms_var[end] / norms_var[1], digits=4),
        " <= telescoping bound ", round(bound, digits=4))

println("END ====")
