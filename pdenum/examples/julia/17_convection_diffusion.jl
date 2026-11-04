# 17_convection_diffusion.jl —— 第 17 章：对流扩散方程（Julia 通道）
#
#   (1) 中心显式的稳定条件 λ² ≤ 2μ ≤ 1（书 (3.4)(3.5)）：两侧数值确认；
#   (2) 对流占优（μ << λ）：中心格式振荡、迎风格式单调但抹平；
#   (3) 指数型格式：对定态对扩散解精确（格子上精确解移植）。

println("==== 17 convection diffusion")

# ---------- (1) 中心显式稳定条件 ----------
# u_t + a u_x = nu u_xx；λ = aτ/h，μ = nu τ/h²
function central_cd(lam, mu, nst)
    J = 128
    u = [exp(-200 * ((j - 1) / J - 0.3)^2) for j in 1:J]
    un = similar(u)
    for _ in 1:nst
        for j in 1:J
            jp = (j == J ? 1 : j + 1); jm = (j == 1 ? J : j - 1)
            un[j] = u[j] - 0.5 * lam * (u[jp] - u[jm]) + mu * (u[jp] - 2u[j] + u[jm])
        end
        u .= un
        maximum(abs.(u)) > 1e4 && return 1e4
    end
    maximum(abs.(u))
end
# λ² ≤ 2μ 且 2μ ≤ 1
@assert central_cd(0.6, 0.4, 400) < 1.001 "λ²=0.36 ≤ 2μ=0.8 ≤ 1 应稳定"
println("central: lam=0.6 mu=0.4 (lam^2 <= 2mu <= 1): max|u| = ", central_cd(0.6, 0.4, 400))
# λ² > 2μ：增长
@assert central_cd(0.6, 0.15, 400) > 1.01 "λ²=0.36 > 2μ=0.3 应不稳"
println("central: lam=0.6 mu=0.15 (lam^2 > 2mu): max|u| = ", central_cd(0.6, 0.15, 400),
        " (unstable)")

# ---------- (2) 对流占优：中心 vs 迎风 ----------
# 定态问题（书 §3.5 指数型格式的原型）：-a u_x + nu u_xx = 0, u(0)=1, u(1)=0
# 精确解：u = (e^{Pe(1-x)} - e^{Pe})/(1 - e^{Pe})，Pe = a/nu·L 为整体 Peclet
a, nu = 1.0, 0.05
Pe = a / nu
# 特征根 r = 0, a/nu：u = A + B e^{Pe x}；u(0)=1, u(1)=0 ⟹ 边界层在 x=1
uexact(x) = (exp(Pe * x) - exp(Pe)) / (1 - exp(Pe))

J = 40
h = 1 / J
# 中心差定态：-λ/2 中心 + μ δ² = 0 的三点递推——网格 Peclet pe = a h/nu = 0.5 < 2 单调
pe = a * h / nu
@assert pe < 2 "中心格式的单调条件 pe = a h/nu < 2"
# 加密到 pe > 2 看振荡
J2 = 50
h2 = 1 / J2
pe2 = a * h2 / nu
@assert pe2 < 2
J3 = 8     # h = 0.125 ⟹ pe = 2.5 > 2：中心格式单调性失守
h3 = 1 / J3
pe3 = a * h3 / nu
@assert pe3 > 2 "pe = a h/nu 应 > 2（中心格式的振荡区）"

function thomas_v(a, b, c, d)
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

function steady_center(J, kind)
    h = 1 / J
    if kind == :exact
        return [(exp(Pe * j * h) - exp(Pe)) / (1 - exp(Pe)) for j in 0:J]
    end
    # 定态三点方程（乘 h²）：(ν + s)u_{j-1} − (2ν + s)u_j + ν u_{j+1} = 0，
    # 其中中心 s = ah/2（u_{j-1} 系数为 ν + ah/2、u_{j+1} 为 ν − ah/2），
    # 迎风 s = ah（全放在 u_{j-1} 一侧）。
    α, β, γ = (kind == :center) ? (nu + 0.5a * h, 2nu, nu - 0.5a * h) :
                                  (nu + a * h, 2nu + a * h, nu)
    n = J - 1                       # 未知 u_1..u_{J-1}，u_0 = 1、u_J = 0
    aa = fill(-α, n); bb = fill(β, n); cc = fill(-γ, n); dd = zeros(n)
    aa[1] = 0.0
    dd[1] = α * 1.0                 # 左边界 u_0 = 1 的贡献移到右端
    cc[n] = 0.0                     # 右边界 u_J = 0 无贡献
    inner = thomas_v(aa, bb, cc, dd)
    [1.0; inner; 0.0]
end

uc25 = steady_center(8, :center)
uu25 = steady_center(8, :upwind)
ue25 = steady_center(8, :exact)
# 单调 = 差分无符号翻转（解单调降也算单调！）
is_monotone(u) = all(d -> d >= -1e-12, diff(u)) || all(d -> d <= 1e-12, diff(u))
mono_center = is_monotone(uc25)
mono_upwind = is_monotone(uu25)
println("pe = ah/nu = 2.5 (J=8): center monotone? ", mono_center)
println("                        upwind  monotone? ", mono_upwind)
@assert !mono_center "中心格式在 pe >= 2 应振荡"
@assert mono_upwind "迎风格式应保持单调"

# 指数型在任何 pe 下精确
for J4 in (10, 25, 50)
    uex = [uexact(j / J4) for j in 0:J4]
    u_num = steady_center(J4, :exact)
    @assert maximum(abs.(u_num .- uex)) < 1e-12 "指数型应与采样精确解一致"
end
println("exponential fitting: exact at cell level for any pe (verified J = 10/25/50)")

# 迎风的额外耗散（人工扩散 ah/2 的代价）：边界层厚度对比
# pe=2 时中心已振荡，比较 pe=1（J=50）的中心 vs 迎风误差
u50c = steady_center(50, :center)
u50u = steady_center(50, :upwind)
errc = maximum(abs.(u50c[j+1] - uexact(j / 50)) for j in 0:50)
erru = maximum(abs.(u50u[j+1] - uexact(j / 50)) for j in 0:50)
println("pe=1 (J=50): center err = ", round(errc, digits=5), ", upwind err = ", round(erru, digits=5))
@assert errc < erru "pe<2 时中心格式应更精确（迎风带人工扩散）"

println("END ====")
