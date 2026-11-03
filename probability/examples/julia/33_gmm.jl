# 第 33 章 Julia：线性 GMM 的精确有理数账。
using LinearAlgebra
println("==== 33 gmm")

function scalar_linear_gmm(a, g, w)
    numerator = sum(g[i] * w[i, j] * a[j] for i in eachindex(g), j in eachindex(g))
    denominator = sum(g[i] * w[i, j] * g[j] for i in eachindex(g), j in eachindex(g))
    denominator != 0 || error("G'WG is singular")
    numerator / denominator
end

function scalar_sandwich(g, w, s)
    gwg = sum(g[i] * w[i, j] * g[j] for i in eachindex(g), j in eachindex(g))
    gwsgw = sum(g[i] * w[i, j] * s[j, k] * w[k, ell] * g[ell]
                for i in eachindex(g), j in eachindex(g),
                    k in eachindex(g), ell in eachindex(g))
    gwsgw / gwg^2
end

pairs = [(1 // 1, 2 // 1), (3 // 1, 6 // 1), (2 // 1, 1 // 1)]
n = length(pairs)
a = [sum(pair[j] for pair in pairs) / n for j in 1:2]
g = Rational{Int}[1, 1]
identity = Rational{Int}[1 0; 0 1]
known_s = Rational{Int}[1 0; 0 4]
known_precision = Rational{Int}[1 0; 0 1//4]
@assert a == Rational{Int}[2, 3]

theta_one = scalar_linear_gmm(a, g, identity)
theta_star = scalar_linear_gmm(a, g, known_precision)
@assert theta_one == 5 // 2
@assert theta_star == 11 // 5
residual = a - g .* theta_star
@assert residual == Rational{Int}[-1//5, 4//5]
q_star = residual' * known_precision * residual
@assert q_star == 1 // 5
@assert n * q_star == 3 // 5
omega_one = scalar_sandwich(g, identity, known_s)
omega_star = scalar_sandwich(g, known_precision, known_s)
@assert omega_one == 5 // 4
@assert omega_star == 4 // 5
@assert omega_star == 1 / (g' * known_precision * g)[1]
println("one-step theta: ", theta_one, "; optimal theta: ", theta_star)
println("scaled asymptotic variances: ", omega_one, ", ", omega_star,
        "; J at known optimal weight: ", n * q_star)

# 两步法使用一步残差的非中心二阶矩。
moment_vectors = [[pair[j] - theta_one for pair in pairs] for j in 1:2]
s_hat = [sum(moment_vectors[i][t] * moment_vectors[j][t] for t in 1:n) / n
         for i in 1:2, j in 1:2]
@assert s_hat == Rational{Int}[11//12 13//12; 13//12 59//12]
det_s = det(s_hat)
@assert det_s == 10 // 3
w_two = inv(s_hat)
theta_two = scalar_linear_gmm(a, g, w_two)
@assert theta_two == 43 // 22
residual_two = a - g .* theta_two
j_two = n * (residual_two' * w_two * residual_two)
@assert j_two == 9 // 11
println("two-step S_hat: ", s_hat, "; theta: ", theta_two, "; J: ", j_two)

# 一般矩阵接口与秩检查。
linear_gmm(a, g, w) = (g' * w * g) \ (g' * w * a)
@assert isapprox(linear_gmm([2.0, 3.0], ones(2, 1), diagm([1.0, 0.25]))[1], 2.2)
@assert rank(ones(2, 2)) == 1
println("general matrix interface and singular-weight warning: OK")
println("END ====")
