# 第 38 章 Julia：OLS 的精确代数、投影矩阵与固定种子 Monte Carlo。
using LinearAlgebra
using Random
using Statistics
println("==== 38 ols")

# 固定三点例：有理数矩阵运算全程精确。
X = [1 0; 1 1; 1 2] .// 1
y = [1, 2, 4] .// 1
XtX = X' * X
Xty = X' * y
@assert XtX == [3 3; 3 5]
@assert Xty == [7, 10]
beta = XtX \ Xty
@assert beta == [5 // 6, 3 // 2]
fitted = X * beta
@assert fitted == [5 // 6, 7 // 3, 23 // 6]
resid = y - fitted
@assert resid == [1 // 6, -1 // 3, 1 // 6]
@assert X' * resid == [0, 0]                     # X'e = 0 纯代数
@assert resid' * resid == 1 // 6
P = X * inv(XtX) * X'
@assert P == (1 // 6) .* [5 2 -1; 2 2 2; -1 2 5]
M = Matrix{Rational{Int}}(I, 3, 3) - P
@assert P * P == P && M * M == M                 # 幂等
@assert P * M == zeros(Rational{Int}, 3, 3)
@assert tr(P) == 2 && tr(M) == 1                 # 秩 = 迹
@assert P * y == fitted && M * y == resid
println("exact OLS: beta = ", beta, "; e = ", resid, "; rank P = 2")

Xf = Float64.(X)
yf = Float64.(y)
@assert isapprox(Xf \ yf, [5 / 6, 1.5])
println("float cross-check: ", Xf \ yf)

# 固定设计下无偏性与协方差（外生性成立）。
Random.seed!(38)
n, sigma, reps = 30, 1.5, 20_000
xd = collect(1.0:n)
Xd = [ones(n) xd]
XtXi = inv(Xd' * Xd)
beta0 = [1.0, 2.0]
B = zeros(reps, 2)
for r in 1:reps
    B[r, :] .= XtXi * (Xd' * (Xd * beta0 .+ sigma .* randn(n)))
end
emp_mean = vec(mean(B, dims=1))
emp_cov = cov(B)
@assert all(abs.(emp_mean .- beta0) .< 0.02)
@assert all(abs.(diag(emp_cov) .- diag(sigma^2 .* XtXi)) .< 0.02)
println("MC unbiased: mean = ", round.(emp_mean, digits=4),
        "; cov diag = ", round.(diag(emp_cov), digits=5))

# 内生性：x = eps + v，斜率 plim = 2 + Cov(x,eps)/Var(x) = 2.5；
# 每个样本里 X'e = 0 仍然成立（循环封装为函数，避免顶层作用域歧义）。
function endogeneity_audit(reps2)
    n2 = 200
    slopes = zeros(reps2)
    for r in 1:reps2
        eps = randn(n2)
        v = randn(n2)
        x = eps .+ v
        yv = 1 .+ 2 .* x .+ eps
        xb, yb = mean(x), mean(yv)
        slopes[r] = sum((x .- xb) .* (yv .- yb)) / sum((x .- xb) .^ 2)
        if r == 1
            Xd2 = [ones(n2) x]
            e2 = yv .- Xd2 * (Xd2 \ yv)
            @assert norm(Xd2' * e2) < 1e-8
        end
    end
    slopes
end
Random.seed!(138)
slopes = endogeneity_audit(5000)
@assert abs(mean(slopes) - 2.5) < 0.05
println("endogeneity: mean slope = ", round(mean(slopes), digits=4),
        " (plim 2.5); X'e = 0 holds anyway")
println("END ====")
