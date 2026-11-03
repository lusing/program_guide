# 第 39 章 Julia：拟合优度分解、调整 R² 与 Gauss–Markov。
using LinearAlgebra
using Random
using Statistics
println("==== 39 ols properties")

# 第 38 章三点例的拟合优度账（有理数精确）。
y = [1, 2, 4] .// 1
fitted = [5 // 6, 7 // 3, 23 // 6]
resid = [1 // 6, -1 // 3, 1 // 6]
ybar = mean(y)
@assert ybar == 7 // 3
TSS = sum((y .- ybar) .^ 2)
ESS = sum((fitted .- ybar) .^ 2)
RSS = sum(resid .^ 2)
@assert (TSS, ESS, RSS) == (14 // 3, 9 // 2, 1 // 6)
@assert TSS == ESS + RSS
@assert ESS / TSS == 27 // 28
adj = 1 - (RSS / (3 - 2)) / (TSS / (3 - 1))
@assert adj == 13 // 14
@assert RSS / (3 - 2) == 1 // 6
println("fit decomposition: TSS = ", TSS, ", ESS = ", ESS,
        ", RSS = ", RSS, "; R2 = 27/28; adj = 13/14")

# 嵌套模型：加无关变量 RSS 不增、R² 不降、调整 R² 可降。
Random.seed!(39)
n = 8
xd = collect(1.0:n)
yv = 2.0 .+ 0.5 .* xd .+ randn(n)
z = randn(n)
function ols_rss(X)
    b = X \ yv
    r = yv .- X * b
    Float64(r' * r)
end
X2 = [ones(n) xd]
X3 = [ones(n) xd z]
rss2, rss3 = ols_rss(X2), ols_rss(X3)
tss = sum((yv .- mean(yv)) .^ 2)
r2_2, r2_3 = 1 - rss2 / tss, 1 - rss3 / tss
adj2 = 1 - (rss2 / (n - 2)) / (tss / (n - 1))
adj3 = 1 - (rss3 / (n - 3)) / (tss / (n - 1))
@assert rss3 <= rss2 + 1e-12
@assert r2_3 >= r2_2 - 1e-12
println("nested fit: RSS ", round(rss2, digits=4), " -> ", round(rss3, digits=4),
        "; R2 ", round(r2_2, digits=4), " -> ", round(r2_3, digits=4),
        "; adj ", round(adj2, digits=4), " -> ", round(adj3, digits=4))

# Gauss–Markov 与 s² 无偏（固定三点设计，sigma^2 = 1）。
X = [1.0 0.0; 1.0 1.0; 1.0 2.0]
XtXi = inv(X' * X)
Random.seed!(139)
reps = 20_000
slopes = zeros(reps)
simples = zeros(reps)
s2s = zeros(reps)
for r in 1:reps
    eps = randn(3)                                # beta = 0
    b = XtXi * (X' * eps)
    slopes[r] = b[2]
    simples[r] = eps[2] - eps[1]                  # y2 - y1
    e = eps .- X * b
    s2s[r] = (e' * e) / (3 - 2)
end
@assert abs(var(slopes, corrected=true) - 0.5) < 0.02
@assert abs(var(simples, corrected=true) - 2.0) < 0.08
@assert var(slopes, corrected=true) < var(simples, corrected=true)
@assert abs(mean(s2s) - 1.0) < 0.05
println("Gauss-Markov MC: var(beta2) = ", round(var(slopes, corrected=true), digits=4),
        " vs var(y2-y1) = ", round(var(simples, corrected=true), digits=4),
        "; mean s2 = ", round(mean(s2s), digits=4))
println("END ====")
