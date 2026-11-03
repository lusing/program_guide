# 第 41 章 Julia：受约束 OLS、遗漏变量偏误与 GLS 的精确账。
using LinearAlgebra
using Random
using Statistics
println("==== 41 gls")

# —— 受约束 OLS：beta2 = 1 ——
beta_hat = [7 // 5, 4 // 5]
XtX_inv = [3//5 -1//5; -1//5 1//10]
col = XtX_inv[:, 2]                                   # (X'X)^-1 R'
@assert col == [-1 // 5, 1 // 10]
scalar = beta_hat[2] - 1                              # R beta_hat - r
adjust = col .* scalar ./ XtX_inv[2, 2]
beta_tilde = beta_hat .- adjust
@assert beta_tilde == [1, 1]
x = [0, 1, 2, 3, 4]
y = [1, 3, 2, 5, 4] .// 1
resid_r = y .- (1 .+ x)
@assert resid_r == [0, 1, -1, 1, -1]
RSS_R = sum(resid_r .^ 2)
RSS_U = 18 // 5
@assert RSS_R == 4
@assert RSS_R - RSS_U == scalar^2 / XtX_inv[2, 2] == 2 // 5
F_stat = ((RSS_R - RSS_U) / 1) / (RSS_U / 3)
@assert F_stat == 1 // 3
println("restricted beta2=1: beta_tilde = (1,1); RSS_R = 4; F = 1/3")

# —— 长模型（三参数）与正交回归变量 ——
ones5 = ones(Rational{Int}, 5)
z2 = [0, 0, 1, 1, 2] .// 1
X3 = reshape([ones5; x .// 1; z2], 5, 3)
beta_long = (X3' * X3) \ (X3' * y)
@assert beta_long == [11 // 15, 37 // 15, -10 // 3]
z_orth = [0, 1, -2, 1, 0] .// 1
@assert sum(z_orth) == 0 && dot(x .- 2, z_orth) == 0
Xo = reshape([ones5; x .// 1; z_orth], 5, 3)
beta_orth = (Xo' * Xo) \ (Xo' * y)
@assert beta_orth[1:2] == [7 // 5, 4 // 5]
@assert beta_orth[3] == 2 // 3
println("long model exact; orthogonal regressor keeps slopes")

# —— 遗漏变量偏误：真实 beta3 = 2 时短模型偏差 = (-2/5, 1) ——
X1 = reshape([ones5; x .// 1], 5, 2)
bias_unit = (X1' * X1) \ (X1' * z2)
@assert bias_unit == [-1 // 5, 1 // 2]
bias = 2 .* bias_unit
@assert bias == [-2 // 5, 1]
function omission_audit(reps)
    B_short = zeros(reps, 2)
    B_long = zeros(reps, 3)
    Xf = Float64.(X3)
    Xs = Float64.(X1)
    for r in 1:reps
        yv = 1 .+ Float64.(x) .+ 2 .* [0.0, 0, 1, 1, 2] .+ randn(5)
        B_short[r, :] .= Xs \ yv
        B_long[r, :] .= Xf \ yv
    end
    B_short, B_long
end
Random.seed!(41)
B_short, B_long = omission_audit(50_000)
@assert all(abs.(vec(mean(B_short, dims=1)) .- [0.6, 2.0]) .< 0.02)
@assert all(abs.(vec(mean(B_long, dims=1)) .- [1.0, 1.0, 2.0]) .< 0.03)
println("omitted variable: short mean = ", round.(vec(mean(B_short, dims=1)), digits=4),
        " (theory 0.6, 2)")

# —— 无关但相关的变量：方差膨胀 28/3 ——
inv3 = inv(X3' * X3)
@assert inv3[2, 2] == 14 // 15
@assert inv3[2, 2] / (1 // 10) == 28 // 3
println("irrelevant regressor: Var ratio = 28/3")

# —— GLS/Aitken：Omega = diag(1,1,1,4,4) ——
w_inv = [1, 1, 1, 1 // 4, 1 // 4]
Sw = sum(w_inv)
Swx = dot(w_inv, x)
Swxx = dot(w_inv, x .^ 2)
Swy = dot(w_inv, y)
Swxy = dot(w_inv, x .* y)
@assert (Sw, Swx, Swxx) == (7 // 2, 19 // 4, 45 // 4)
det = Sw * Swxx - Swx^2
@assert det == 269 // 16
beta_gls = [(Swxx * Swy - Swx * Swxy) / det, (Sw * Swxy - Swx * Swy) / det]
@assert (Swy, Swxy) == (33 // 4, 59 // 4)
@assert beta_gls == [364 // 269, 199 // 269]
sq = [1, 1, 1, 2, 2] .// 1
Xstar = reshape([1 .// 1 ./ sq; x .// 1 ./ sq], 5, 2)   # 常数列也除以 sqrt(w)
ystar = y ./ sq
beta_trans = (Xstar' * Xstar) \ (Xstar' * ystar)
@assert beta_trans == beta_gls
XtOmegaX = [11 31; 31 105] .// 1
row2 = [-1 // 5, 1 // 10]
var_ols = dot(row2, XtOmegaX * row2)
@assert var_ols == 1 // 4
var_gls = Sw / det
@assert var_gls == 56 // 269
@assert var_gls < var_ols
println("GLS: beta = ", beta_gls, "; Var OLS = 1/4 > Var GLS = 56/269")

# Aitken 的 Monte Carlo 审计（sigma^2 = 1，真值为 0）。
function aitken_audit(reps)
    sd = [1.0, 1.0, 1.0, 2.0, 2.0]
    Xf2 = Float64.(X1)
    Wm = Diagonal([1.0, 1.0, 1.0, 0.25, 0.25])
    A_gls = inv(Xf2' * Wm * Xf2) * Xf2' * Wm
    ols_s = zeros(reps)
    gls_s = zeros(reps)
    for r in 1:reps
        yv = sd .* randn(5)
        ols_s[r] = (Xf2 \ yv)[2]
        gls_s[r] = (A_gls * yv)[2]
    end
    ols_s, gls_s
end
Random.seed!(141)
ols_s, gls_s = aitken_audit(20_000)
@assert abs(var(ols_s, corrected=true) - 0.25) < 0.01
@assert abs(var(gls_s, corrected=true) - 56 / 269) < 0.01
@assert var(gls_s, corrected=true) < var(ols_s, corrected=true)
println("Aitken MC: var OLS = ", round(var(ols_s, corrected=true), digits=4),
        ", var GLS = ", round(var(gls_s, corrected=true), digits=4))
println("END ====")
