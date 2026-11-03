# 第 42 章 Julia：合成劳动力市场全程（独立复算）。
using LinearAlgebra
using Random
using Statistics
println("==== 42 synthesis")

const B_EDUC = 0.1
const B_ABILITY = 0.3
const SIGMA = 0.5

# 总体账（精确分数）
@assert 3 // 10 * 2 // 6 == 1 // 10                # 偏误 = 0.3·Cov/Var
@assert 1 // 10 + 1 // 10 == 1 // 5                # 短回归 plim
@assert (1 // 10) / 1 == 1 // 10                   # IV 识别
println("population: bias = 1/10, plim short = 1/5, IV estimand = 1/10")

function simulate(rng, n)
    A = randn(rng, n)
    D = randn(rng, n)
    U = randn(rng, n)
    E = 10 .+ 2 .* A .+ D .+ U
    eps = SIGMA .* randn(rng, n)
    W = 4.6 .+ B_EDUC .* E .+ B_ABILITY .* A .+ eps
    A, D, E, W
end

# —— 一次抽样：描述统计 + 四种估计 ——
rng = MersenneTwister(42)
A0, D0, E0, W0 = simulate(rng, 500)
@assert abs(mean(E0) - 10) < 0.5 && abs(var(E0) - 6) < 1.2
Xs = [ones(500) E0]
Xl = [ones(500) E0 A0]
b_short = Xs \ W0
b_long = Xl \ W0
@assert abs(b_short[2] - 0.2) < 0.05
@assert abs(b_long[2] - 0.1) < 0.06
@assert abs(b_long[3] - 0.3) < 0.15
dc = D0 .- mean(D0)
wc = W0 .- mean(W0)
ec = E0 .- mean(E0)
iv = dot(dc, wc) / dot(dc, ec)
@assert abs(iv - 0.1) < 0.09
e_hat = W0 .- Xl * b_long
s2 = dot(e_hat, e_hat) / (500 - 3)
XtXi = inv(Xl' * Xl)
t_educ = b_long[2] / sqrt(s2 * XtXi[2, 2])
t_ability = b_long[3] / sqrt(s2 * XtXi[3, 3])
@assert t_educ > 4 && t_ability > 4
println("one sample: short ", round(b_short[2], digits=4),
        ", long (", round(b_long[2], digits=4), ", ", round(b_long[3], digits=4),
        "), IV ", round(iv, digits=4),
        "; t_educ ", round(t_educ, digits=2),
        " t_ability ", round(t_ability, digits=2))

# —— Monte Carlo：三个估计量的概率极限（循环封装为函数）——
function estimator_audit(reps)
    n = 500
    short_s = zeros(reps)
    long_s = zeros(reps)
    iv_s = zeros(reps)
    rng = MersenneTwister(142)
    for r in 1:reps
        A, D, E, W = simulate(rng, n)
        Ac = A .- mean(A); Dc = D .- mean(D)
        Ec = E .- mean(E); Wc = W .- mean(W)
        sxx = dot(Ec, Ec)
        short_s[r] = dot(Ec, Wc) / sxx
        Ea = Ec .- Ac .* dot(Ac, Ec) / dot(Ac, Ac)   # Frisch–Waugh 残差化
        long_s[r] = dot(Ea, Wc) / dot(Ea, Ea)
        iv_s[r] = dot(Dc, Wc) / dot(Dc, Ec)
    end
    short_s, long_s, iv_s
end
short_s, long_s, iv_s = estimator_audit(4000)
@assert abs(mean(short_s) - 0.2) < 0.01
@assert abs(mean(long_s) - 0.1) < 0.01
@assert abs(mean(iv_s) - 0.1) < 0.01
mse_short = mean((short_s .- 0.1) .^ 2)              # 围绕真值的 MSE
mse_long = mean((long_s .- 0.1) .^ 2)
@assert var(short_s, corrected=true) < var(long_s, corrected=true)
@assert mse_long < mse_short / 10
println("MC: mean short ", round(mean(short_s), digits=4),
        " -> 0.2, long ", round(mean(long_s), digits=4),
        " -> 0.1, IV ", round(mean(iv_s), digits=4), " -> 0.1")
println("MC: var short ", round(var(short_s, corrected=true), digits=6),
        " < var long ", round(var(long_s, corrected=true), digits=6),
        "; MSE long ", round(mse_long, digits=6),
        " << short ", round(mse_short, digits=6))

# —— WLS 收官（n=100，后半样本方差 ×4）——
function wls_audit(reps)
    n = 100
    xw = collect(1.0:n)
    w = vcat(ones(50), 4 .* ones(50))
    Xw = [ones(n) xw]
    Winv = Diagonal(1 ./ w)
    var_ols_th = (inv(Xw' * Xw) * (Xw' * Diagonal(w) * Xw) * inv(Xw' * Xw))[2, 2]
    var_wls_th = inv(Xw' * Winv * Xw)[2, 2]
    A_wls = inv(Xw' * Winv * Xw) * (Xw' * Winv)
    rng = MersenneTwister(242)
    ols_s = zeros(reps)
    wls_s = zeros(reps)
    for r in 1:reps
        yv = 2 .+ 0.5 .* xw .+ sqrt.(w) .* randn(rng, n)
        ols_s[r] = (Xw \ yv)[2]
        wls_s[r] = (A_wls * yv)[2]
    end
    ols_s, wls_s, var_ols_th, var_wls_th
end
ols_s, wls_s, var_ols_th, var_wls_th = wls_audit(4000)
@assert abs(var(ols_s, corrected=true) - var_ols_th) < 0.1 * var_ols_th
@assert abs(var(wls_s, corrected=true) - var_wls_th) < 0.1 * var_wls_th
@assert var(wls_s, corrected=true) < var(ols_s, corrected=true)
println("WLS: var OLS ", round(var(ols_s, corrected=true), digits=6),
        " vs var WLS ", round(var(wls_s, corrected=true), digits=6),
        " (theory ", round(var_ols_th, digits=6), " / ",
        round(var_wls_th, digits=6), ")")
println("END ====")
