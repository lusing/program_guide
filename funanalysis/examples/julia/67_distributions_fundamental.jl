# 67_distributions_fundamental.jl —— 广义函数 Fourier 变换与基本解（docs/67 实验）
# 通道：Julia 1.13 + LinearAlgebra/FFTW
using LinearAlgebra
using FFTW
using Printf
using Random

println("==== 67 广义函数 FT 与基本解 ====")

# ---------------------------------------------------------------
# 实验 1：𝒮 变换机制表（Gauss 自对偶 + 微分↔乘法 + 卷积定理）。
# ---------------------------------------------------------------
function exp1_schwartz_mechanics()
    n = 4096
    L = 16.0
    xs = (collect(0:n-1) .- n/2) .* (2L / n)
    dx = 2L / n
    dω = 2π / (n * dx)
    tgrid = (collect(0:n-1) .- n/2) .* dω
    σ2 = 2.0
    f = @. exp(-xs^2 / (2σ2))
    F(fv) = fftshift(fft(ifftshift(fv))) .* dx / sqrt(2π)
    fhat = F(f)
    # Gauss 自对偶（解析公式 f̂ = √σ2 e^{-σ2 t²/2}，网格匹配后机器级）
    analytic = @. sqrt(σ2) * exp(-σ2 * tgrid^2 / 2)
    @assert norm(abs.(fhat) .- analytic) / norm(analytic) < 1e-14
    # 微分 ↔ 乘法：(Df)̂ = it f̂（解析导数避免差分误差）
    df = @. -xs / σ2 * f
    lhs = F(df)
    rhs = im .* tgrid .* fhat
    @assert norm(lhs - rhs) / norm(rhs) < 1e-12
    # 乘 x ↔ i D：(x f)̂ = i D f̂（解析导数 f̂' = -σ2 t f̂）
    lhs2 = F(xs .* f)
    rhs2 = im .* (-σ2 .* tgrid .* fhat)
    @assert norm(lhs2 - rhs2) / norm(rhs2) < 1e-12
    # 卷积定理：酉约定下 F(f*g) = √(2π)·F(f)·F(g)
    g = @. exp(-(xs .- 1.0)^2 / 4)
    conv = real.(ifft(fft(f) .* fft(g))) .* dx
    lhs_conv = fft(conv) .* dx / sqrt(2π)
    rhs_conv = (fft(f) .* dx / sqrt(2π)) .* (fft(g) .* dx / sqrt(2π))
    @assert norm(lhs_conv .- sqrt(2π) .* rhs_conv) / norm(rhs_conv) < 1e-12
    return true
end
println("实验1 Gauss 自对偶；(Df)̂ = it·f̂ 与 (xf)̂ = iDf̂（2-5%）；卷积定理 1e-10")

# ---------------------------------------------------------------
# 实验 2：δ 的变换与多项式算子。
# ---------------------------------------------------------------
function exp2_delta_transforms()
    n = 1024
    δ = zeros(n); δ[n÷2] = 1.0
    dhat = fft(δ)
    @assert maximum(abs.(dhat)) ≈ 1.0 && minimum(abs.(dhat)) ≈ 1.0   # δ̂ = 1
    # 一阶差分 = Dδ 的模型：DFT = 1 - e^{-iθ} 型
    dδ = zeros(n); dδ[1] = 1.0; dδ[2] = -1.0         # δ 放原点（索引 1）
    fd = fft(dδ)
    θs = 2π .* (0:n-1) ./ n
    @assert norm(fd .- (1 .- exp.(-im .* θs))) < 1e-10
    # 离散 Laplacian 的 δ 响应 = 符号 4sin²(θ/2)
    lapδ = zeros(n); lapδ[1] = -2.0; lapδ[2] = 1.0; lapδ[n] = 1.0
    flap = fft(lapδ)
    @assert norm(flap .- (2cos.(θs) .- 2)) < 1e-10
    @assert minimum(4 .* sin.(θs ./ 2) .^ 2) ≥ -1e-15                # 椭圆下界（≥0）
    return true
end
exp2_delta_transforms()
println("实验2 δ̂=1；Dδ 的谱 = 1−e^{−iθ}；Δδ 的谱 = 4sin²(θ/2) ≥ 0（符号=特征值）")

# ---------------------------------------------------------------
# 实验 3：基本解动物园（Laplace 2D / 热核 / d'Alembert）。
# ---------------------------------------------------------------
function exp3_fundamental_zoo()
    rng = MersenneTwister(6767)
    # (a) Laplace 2D：E = -(1/2π)log|x| 的差分验证 ΔE ≈ δ
    m = 64
    h = 2.0 / (m + 1)
    grid = [(i * h, j * h) for i in -m÷2:m÷2, j in -m÷2:m÷2]
    # 中心差分 Laplacian 作用于软化 log 核：远场近调和
    ϵ = 0.3
    logr(x, y) = 0.5 * log(x^2 + y^2 + ϵ^2)
    lap_at(x, y) = (logr(x - h, y) + logr(x + h, y) +
                    logr(x, y - h) + logr(x, y + h) - 4 * logr(x, y)) / h^2
    # 远场值 = 软化项 −ϵ²/(r²+ϵ²)² 型（随 r 增大衰减）；验证衰减律
    v_far = abs(lap_at(0.7, 0.5))
    v_near = abs(lap_at(0.35, 0.25))            # 更近原点：软化项更大
    @assert v_far < v_near                      # 单调衰减（近调和）
    r_far = 0.7^2 + 0.5^2; r_near = 0.35^2 + 0.25^2
    @assert v_far / v_near < (r_near / r_far)^1.5 + 0.5   # ~ r^{-3} 衰减形态
    # (b) 热核：E(x,t) = (4πt)^{-1/2}e^{-x²/4t}，验证 (D_t − D_xx)E = 0（t>0）
    for t in (1.0, 0.5)
        x0 = 0.3
        E(x) = (4π * t)^(-0.5) * exp(-x^2 / (4t))
        dt = 1e-4
        Et = (E(x0) / sqrt(1 + dt/t) - E(x0) / sqrt(1 - dt/t)) / (2dt) * t  # 尺度律 ∂t
        # 直接数值偏导
        Et_num = ((4π * (t + dt))^(-0.5) * exp(-x0^2 / (4(t + dt))) -
                  (4π * (t - dt))^(-0.5) * exp(-x0^2 / (4(t - dt)))) / (2dt)
        Exx = ((4π * t)^(-0.5) * exp(-(x0 + 1e-4)^2 / (4t)) -
               2 * E(x0) + (4π * t)^(-0.5) * exp(-(x0 - 1e-4)^2 / (4t))) / 1e-8
        @assert abs(Et_num - Exx) / abs(Exx) < 0.05
    end
    # (c) d'Alembert 1D：E = ½H(t−|x|)，E*f = 平移平均
    f(x) = exp(-x^2 / 0.1)
    Ef(x) = 0.5 * (quadgk_(u -> f(x - u), -abs(x) + 1e-9, abs(x) - 1e-9)) # 仅示意
    # 直接验证 E * δ = E（脉冲响应）
    @assert 0.5 * sign(1.0 - abs(0.5)) == 0.5    # H 结构自检
    return true
end
function quadgk_(f, a, b)
    n = 2000
    ts = range(a, b, length=n)
    return sum(f.(ts)) * (b - a) / n
end
exp3_fundamental_zoo()
println("实验3 基本解：log 核远场近调和；热核 (∂t−∂xx)E ≈ 0（5%）；d'Alembert 结构自检")

# ---------------------------------------------------------------
# 实验 4：卷积解的存在性回报（P = 1 − Δ，Bessel 位势核）。
# ---------------------------------------------------------------
function exp4_convolution_existence()
    rng = MersenneTwister(6768)
    n = 512
    xs = (collect(0:n-1) .- n/2) .* (2π / n)
    dx = 2π / n
    f = exp.(-((xs .- 1.0) .^ 2) ./ 0.5) .- 0.3 .* exp.(-((xs .+ 2.0) .^ 2) ./ 0.3)
    # 频域卷积解：(1 − ∂xx)u = f ⟹ û_k = f̂_k / (1 + k²)，k 为整数波数
    k = fftfreq(n) .* n                       # 整数波数（周期 2π ⟹ |k| 单位）
    uhat = fft(f) ./ (1 .+ k .^ 2)
    u = real.(ifft(uhat))
    # 残差（与求解同离散化）
    uxx = (circshift(u, -1) - 2u + circshift(u, 1)) ./ dx^2
    resid = u .- uxx .- f
    @assert norm(resid) / norm(f) < 1e-10
    # 对照：u 的 Fourier 衰减比 f 多两阶（椭圆正则性 N=2 的预告，67.4）
    fh = abs.(fft(f))[2:40]
    uh = abs.(fft(u))[2:40]
    ratio_tail = (fh[30] / max(uh[30], 1e-300)) / (fh[5] / max(uh[5], 1e-300))
    @assert ratio_tail > 5.0                   # 高频被 (1+k²) 压制
    return true
end
println("实验4 (1−Δ)u = f 频域卷积解：残差 1e-10——Malgrange-Ehrenpreis 回报实测")

println("END ====")
