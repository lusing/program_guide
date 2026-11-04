# 05_vonneumann.jl —— 第 05 章：von Neumann 稳定性分析（Julia 通道）
#
#   (1) 四个格式的增长因子 |G(θ)| 全 θ 扫描，与解析判据对账：
#       FTCS-advection |G|>1（恒不稳）；迎风 |G|²=1−4μ(1−μ)s²（0≤μ≤1）；
#       FTCS 热传导 G=1−4r s²（r≤1/2）；BTCS G=1/(1+4r s²)（无条件）；
#   (2) Richardson 增长矩阵：特征值模恒超 1（书例 3.4 的数值版）；
#   (3) Parseval 闭环：整个 ℓ² 误差增长 = 各波型 |G|ⁿ 的加权和，
#       与直接迭代实测吻合——Fourier 方法完整链路的端到端验证。

println("==== 05 vonneumann")

# ---------- (1) 增长因子扫描 ----------
thetas = range(1.0e-3, pi - 1.0e-3, length = 500)
s2(th) = sin(th / 2)^2   # sin^2(theta/2)

maxG(mu) = maximum(abs(1 - 1im * mu * sin(th)) for th in thetas)                     # FTCS-adv
maxG_upwind(mu) = maximum(sqrt(1 - 4 * mu * (1 - mu) * s2(th)) for th in thetas)     # 迎风
maxG_ftcs_heat(r) = maximum(abs(1 - 4 * r * s2(th)) for th in thetas)                # FTCS heat
maxG_btcs_heat(r) = maximum(1 / (1 + 4 * r * s2(th)) for th in thetas)               # BTCS heat

for mu in (0.3, 0.8, 1.0)
    g = maxG(mu)
    @assert g > 1.0 + 1.0e-6 "FTCS-advection 应恒不稳定（mu=$mu, maxG=$g）"
end
println("FTCS-advection: max|G| = sqrt(1+mu^2) > 1 for every mu (unconditionally unstable)")

# 迎风：μ∈[0,1] 时 maxG=1（在 θ→0 处），μ>1 时超 1
for mu in (0.5, 0.9, 1.0)
    @assert maxG_upwind(mu) < 1.0 + 1.0e-9 "迎风 mu<=1 应稳定"
end
g15 = maxG_upwind(1.5)
@assert g15 > 1.0 + 0.5 "迎风 mu>1 应不稳定（实测 $(g15)）"
println("upwind: max|G| <= 1 iff mu in [0,1]; at mu=1.5 max|G| = ", round(g15, digits=4))

# FTCS 热传导：r ≤ 1/2 稳定；r > 1/2 时 maxG = 4r−1
for r in (0.25, 0.5)
    @assert maxG_ftcs_heat(r) <= 1.0 + 1.0e-9 "FTCS heat r<=$r 应稳定"
end
gr = maxG_ftcs_heat(0.6)
# θ 网格端点留了 1e-3 的余量，|G| 偏差 ~ 2r·(1e-3) 量级，容差取 1e-5
@assert abs(gr - (4 * 0.6 - 1)) < 1.0e-5 "FTCS heat r>1/2 应有 maxG=4r-1（实测 $gr）"
println("FTCS heat: max|G| = 1-4r s^2; at r=0.6, max|G| = 4r-1 = ", round(gr, digits=4))

# BTCS：任意 r 无条件稳定
for r in (0.25, 2.0, 50.0)
    @assert maxG_btcs_heat(r) < 1.0 "BTCS 应无条件稳定"
end
println("BTCS heat: |G| = 1/(1+4r s^2) < 1 for every r (unconditionally stable)")

# ---------- (2) Richardson 增长矩阵（书例 3.4） ----------
# 三层格式化二层方程组：G = [[-8 r s, 1], [1, 0]]，特征值 -4rs ± sqrt(16 r² s² + 1)
println("--- Richardson growth matrix (book Example 3.4) ---")
worst = maximum(abs(-4 * r * s2(th) - sqrt(16 * r^2 * s2(th)^2 + 1))
                for r in 0.1:0.1:1.0 for th in thetas)
@assert worst > 4.9 "Richardson 特征值模应远超 1（实测 $worst）"
println("max over r in [0.1,1], theta of |mu_-| = ", round(worst, digits=3), " > 1: always unstable")

# 数值迭代版：Richardson 格式在 r=0.5 下爆掉，增长率与 |mu2| 吻合
function richardson_run(h, r, nst)
    J = round(Int, 1 / h) - 1
    tau = r * h^2
    u_prev = [sin(pi * j * h) for j in 1:J]                 # u^0
    # 用两层 FTCS 起步得 u^1（工程惯例；理论分析看渐近增长率）
    u = [u_prev[j] + r * ((j == 1 ? 0.0 : u_prev[j-1]) - 2u_prev[j] + (j == J ? 0.0 : u_prev[j+1])) for j in 1:J]
    u_new = similar(u)
    for _ in 2:nst
        for j in 1:J
            ul = (j == 1 ? 0.0 : u[j-1]); ur = (j == J ? 0.0 : u[j+1])
            u_new[j] = u_prev[j] + 2r * (ul - 2u[j] + ur)
        end
        u_prev .= u; u .= u_new
        maximum(abs.(u)) > 1e8 && break
    end
    maximum(abs.(u))
end
run200 = richardson_run(0.01, 0.5, 60)
@assert run200 > 1e3 "Richardson 迭代应爆炸（实测 $(run200)）"
println("Richardson iterations at r=0.5: max|u| after ~60 steps = ", round(run200, sigdigits=3))

# ---------- (3) Parseval 闭环：|G|^n 预测 vs 实测 ℓ² 增长 ----------
# 初值 = 混合波型（低波数的和），周期域；对照"逐波型增长因子加权和"
function l2_growth(scheme, lam, h, nst)
    J = round(Int, 1 / h)
    u = [sin(2 * pi * 3 * (j - 1) * h) + 0.5 * sin(2 * pi * 7 * (j - 1) * h) for j in 1:J]
    n0 = sqrt(sum(abs2, u))
    un = similar(u)
    jm(j) = (j == 1 ? J : j - 1); jp(j) = (j == J ? 1 : j + 1)
    for _ in 1:nst
        for j in 1:J
            if scheme == :ftbs
                un[j] = u[j] - lam * (u[j] - u[jm(j)])
            else
                un[j] = 0.5 * (u[jp(j)] + u[jm(j)]) - lam * 0.5 * (u[jp(j)] - u[jm(j)])
            end
        end
        u .= un
    end
    sqrt(sum(abs2, u)) / n0
end

function predicted_growth(scheme, lam, h, nst)
    J = round(Int, 1 / h)
    # 周期波型 θ_k = 2πk/J；初值的谱：k=3 幅 1、k=7 幅 0.5
    total = 0.0
    for (k, amp) in ((3, 1.0), (7, 0.5))
        th = 2 * pi * k / J
        if scheme == :ftbs
            G2 = 1 - 4 * lam * (1 - lam) * s2(th)
        else  # LF: G = cosθ − i λ sinθ
            G2 = cos(th)^2 + lam^2 * sin(th)^2
        end
        total += amp^2 * G2^nst
    end
    sqrt(total / (1.0^2 + 0.5^2))
end

h, nst = 0.01, 60
for (scheme, lam) in ((:ftbs, 0.8), (:lf, 0.9), (:ftbs, 1.1))
    meas = l2_growth(scheme, lam, h, nst)
    pred = predicted_growth(scheme, lam, h, nst)
    rel = abs(meas - pred) / pred
    @assert rel < 1.0e-8 "Parseval 闭环应吻合（$(scheme) λ=$(lam)：实测 $(meas) 预测 $(pred)）"
    println("l2 growth (", scheme, ", lambda=", lam, ", n=", nst, "): measured = ",
            round(meas, digits=6), "  predicted = ", round(pred, digits=6))
end

println("END ====")
