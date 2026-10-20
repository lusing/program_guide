println("==== 44 bochner_theorem")
# 第 44 章：正定性与特征函数。
# ① Gram 矩阵半正定检查；② 高斯/Cauchy 特征函数闭式对拍；
# ③ 卷积乘积律；④ Pólya 构造。

using Random, LinearAlgebra
Random.seed!(44)

# ① Gram 半正定：高斯 e^{-t²/2}
pts = collect(-2.0:0.7:2.0)
n = length(pts)
phi_gauss(t) = exp(-t^2 / 2)
G = [phi_gauss(pts[i] - pts[j]) for i in 1:n, j in 1:n]
eigs = eigvals(Symmetric(G))
@assert minimum(eigs) > -1e-10                  # 半正定
println("Gaussian kernel Gram matrix PSD (min eig = ", round(minimum(eigs), digits=6), "): OK")

# Cauchy e^{-|t|}
phi_cauchy(t) = exp(-abs(t))
G2 = [phi_cauchy(pts[i] - pts[j]) for i in 1:n, j in 1:n]
@assert minimum(eigvals(Symmetric(G2))) > -1e-10
println("Cauchy kernel Gram PSD: OK"

)
# cos（两点分布 (δ₁+δ₋₁)/2）
phi_cos(t) = cos(t)
G3 = [phi_cos(pts[i] - pts[j]) for i in 1:n, j in 1:n]
@assert minimum(eigvals(Symmetric(G3))) > -1e-10
println("cos (two-point) Gram PSD: OK")

# ② 高斯特征函数数值积分 vs 闭式
function charfn_numeric(mu, sigma, t; N = 20000)
    # N(μ,σ) 密度 × cos/sin 的中点积分
    h = 8 * sigma / N
    s_cos = 0.0; s_sin = 0.0
    for k in 0:N-1
        x = mu - 4 * sigma + (k + 0.5) * h
        dens = exp(-(x - mu)^2 / (2 * sigma^2)) / (sigma * sqrt(2pi))
        s_cos += dens * cos(t * x) * h
        s_sin += dens * sin(t * x) * h
    end
    s_cos + s_sin * im
end
for t in (0.5, 1.0, 2.0)
    val = charfn_numeric(0.0, 1.0, t)
    closed = exp(-t^2 / 2)
    @assert abs(val.re - closed) < 1e-4 && abs(val.im) < 1e-4
end
println("Gaussian charFn: numeric integration vs closed form < 1e-4: OK")

# ③ 卷积乘积律：(δ_a + δ_b)/2 * 自身 = 三点分布
# charFn(conv) = charFn² 逐 t 验证（离散直接计算）
for t in (0.3, 1.2, 2.5)
    phi(t) = (exp(im * t * 1.0) + exp(im * t * (-1.0))) / 2   # (δ₁+δ₋₁)/2
    # 卷积分布：P(-2)=1/4, P(0)=1/2, P(2)=1/4
    phi_conv(t) = exp(im*t*(-2.0))/4 + exp(im*t*0.0)/2 + exp(im*t*2.0)/4
    @assert abs(phi(t)^2 - phi_conv(t)) < 1e-12
end
println("convolution product law: charFn(mu*nu) = charFn(mu)*charFn(nu) exact: OK")

# ④ Pólya 构造：凸偶降函数 (1-|t|)_+ 的 Gram
phi_polya(t) = max(0.0, 1 - abs(t))
G4 = [phi_polya(pts[i] - pts[j]) for i in 1:n, j in 1:n]
@assert minimum(eigvals(Symmetric(G4))) > -1e-10
println("Polya triangular kernel Gram PSD: OK")

println("END ====")
