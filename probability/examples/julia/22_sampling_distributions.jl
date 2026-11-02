# -*- coding: utf-8 -*-
println("==== 22 sampling_distributions")
# 第 22 章 Julia：随机样本与抽样分布（仅用标准库）。
# ① Helmert 正交矩阵；② (n-1)S²/σ² 的 χ² 矩与 χ²-CDF 对账，X̄ 与 S² 无相关；
# ③ t = Z/√(V/ν) 的尾概率与 t² 对 F(1,ν)；④ 合并方差权重；⑤ 顺序统计量。
using Random, Statistics, LinearAlgebra

Random.seed!(22)

# ---- 数值积分与 χ²、t、F 的密度（标准库内手写）
lgam(x) = begin   # Lanczos
    g = 7
    c = [0.99999999999980993, 676.5203681218851, -1259.1392167224028,
         771.32342877765313, -176.61502916214059, 12.507343278686905,
         -0.13857109526572012, 9.9843695780195716e-6, 1.5056327351493116e-7]
    x < 0.5 && return log(pi / sin(pi * x)) - lgam(1 - x)
    x -= 1
    a = c[1]
    t = x + g + 0.5
    for i in 1:8
        a += c[i+1] / (x + i)
    end
    0.5 * log(2pi) + (x + 0.5) * log(t) - t + log(a)
end
chi2pdf(y, ν) = y <= 0 ? 0.0 : exp((ν / 2 - 1) * log(y) - y / 2 - (ν / 2) * log(2) - lgam(ν / 2))
tpdf(x, ν) = exp(lgam((ν + 1) / 2) - lgam(ν / 2)) / sqrt(ν * pi) * (1 + x^2 / ν)^(-(ν + 1) / 2)
fpdf(x, p, q) = x <= 0 ? 0.0 :
    exp(lgam((p + q) / 2) - lgam(p / 2) - lgam(q / 2) + (p / 2) * log(p / q) +
        (p / 2 - 1) * log(x) - ((p + q) / 2) * log(1 + p * x / q))
function simpson(f, a, b, n)
    h = (b - a) / n
    s = f(a) + f(b)
    for i in 1:n-1
        s += (iseven(i) ? 2 : 4) * f(a + i * h)
    end
    s * h / 3
end

# ---- ① Helmert
n = 6
H = zeros(n, n)
H[1, :] .= 1 / sqrt(n)
for k in 2:n
    H[k, 1:k-1] .= 1 / sqrt(k * (k - 1))
    H[k, k] = -(k - 1) / sqrt(k * (k - 1))
end
@assert norm(H * H' - I) < 1e-12
@assert abs(abs(det(H)) - 1) < 1e-12
x = randn(n)
y = H * x
@assert abs(y[1] - sqrt(n) * mean(x)) < 1e-12
@assert abs(sum(abs2, y[2:end]) - sum(abs2, x .- mean(x))) < 1e-12
println("Helmert: orthogonal, y1 = sqrt(n)*xbar, sum y_k^2 (k>=2) = SS: OK")

# ---- ② χ² 与独立性
m, μ, σ = 8, 3.0, 2.0
N = 200_000
Xb = zeros(N); S2 = zeros(N)
Xbe = zeros(N); S2e = zeros(N)
for i in 1:N
    v = μ .+ σ .* randn(m)
    Xb[i] = mean(v); S2[i] = var(v)
    w = -log.(rand(m))
    Xbe[i] = mean(w); S2e[i] = var(w)
end
Q = (m - 1) .* S2 ./ σ^2
@assert abs(mean(Q) - (m - 1)) < 0.03
@assert abs(var(Q) - 2 * (m - 1)) < 0.2
for q in (2.0, 6.0, 10.0, 14.0)
    emp = count(<=(q), Q) / N
    theo = simpson(y -> chi2pdf(y, m - 1), 1e-12, q, 4000)
    @assert abs(emp - theo) < 0.004
end
@assert abs(cor(Xb, S2)) < 0.012
@assert cor(Xbe, S2e) > 0.3
println("(n-1)S^2/sigma^2 ~ chi2_7 (moments + CDF); cor normal ≈ 0, exponential > 0.3: OK")

# ---- ③ t = Z/√(V/ν)，t² ~ F(1,ν)
T = sqrt(m) .* (Xb .- μ) ./ sqrt.(S2)
for c in (0.5, 1.0, 2.0, 3.0)
    emp = count(t -> abs(t) <= c, T) / N
    theo = 2 * simpson(t -> tpdf(t, m - 1), 0.0, c, 4000)
    @assert abs(emp - theo) < 0.004
    # t² ≤ c² 等价于 F(1,ν) ≤ c²：换元 f = u² 后 F 的密度应逐点满足 2u·f_F(u²) = 2 f_t(u)
    @assert abs(2 * c * fpdf(c^2, 1, m - 1) - 2 * tpdf(c, m - 1)) < 1e-10
end
@assert abs(simpson(t -> tpdf(t, 5), -60.0, 60.0, 200_000) - 1) < 2e-3
println("t = Z/sqrt(V/nu): central probabilities match t_7; P(|t|<=c) = P(F(1,7)<=c^2): OK")

# ---- ④ 合并方差权重（精确有理）
nx, ny = 5, 11
xa = Rational{Int}[2, 4, 4, 7, 9]
ya = Rational{Int}[1, 3, 3, 4, 5, 5, 6, 8, 8, 9, 12]
sv(v) = sum((v .- sum(v) // length(v)) .^ 2) // (length(v) - 1)
sp2 = ((nx - 1) * sv(xa) + (ny - 1) * sv(ya)) // (nx + ny - 2)
w = (nx - 1) // (nx + ny - 2)
@assert sp2 == w * sv(xa) + (1 - w) * sv(ya)
@assert sp2 != (sv(xa) + sv(ya)) // 2
println("pooled variance = ", sp2, " = df-weighted average, weight on x = ", w, ": OK")

# ---- ⑤ 顺序统计量：U(0,1) 的第 k 小 ~ Beta(k, n-k+1)，均值 k/(n+1)
nn = 9
Us = [sort(rand(nn)) for _ in 1:100_000]
for k in (1, 5, 9)
    @assert abs(mean(u[k] for u in Us) - k / (nn + 1)) < 0.004
    v = k * (nn - k + 1) / ((nn + 1)^2 * (nn + 2))
    @assert abs(var([u[k] for u in Us]) - v) < 0.0007
end
# 极差 R = max - min ~ Beta(n-1, 2)，E[R] = (n-1)/(n+1)
@assert abs(mean(u[end] - u[1] for u in Us) - (nn - 1) / (nn + 1)) < 0.004
println("order statistics: mean k/(n+1), variance, range mean (n-1)/(n+1): OK")

println("END ====")
