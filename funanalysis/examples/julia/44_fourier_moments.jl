using LinearAlgebra, FFTW, Random
println("==== 44 fourier_moments (Julia) ====")
Random.seed!(4444)

# Fourier 变换的酉性（Parseval）
# 注意：Julia 的 fftfreq(n, d) 第二参数是采样率 fs = 1/Δx（与 NumPy 相反）
n = 1024
L = 32.0
dx = L / n
x = (0:n-1) .* dx .- L / 2            # 排除右端点：真周期网格
f = exp.(-x .^ 2)
f̂ = fft(f) / sqrt(n)
println("Parseval 偏差 ‖f̂‖-‖f‖ = $(round(abs(norm(f̂) - norm(f)), digits=10))")
@assert abs(norm(f̂) - norm(f)) < 1e-10

# 微分 = 无界算子，谱方法：f' = F⁻¹(iξ·Ff)
k = 2π .* fftfreq(n, 1.0 / dx)
fprime = real(ifft(im .* k .* fft(f)))
fprime_exact = -2x .* f
err = norm(fprime - fprime_exact) / norm(fprime_exact)
println("谱方法求导相对误差 = $(round(err, digits=8))（f = e^{-x²}）")
@assert err < 1e-6
println("Fourier 把无界微分算子对角化为乘 iξ：✓")

# Heisenberg 不确定性：σx·σξ ≥ 1/2（ℏ=1 约定），Gaussian 最优
function uncertainty(f)
    fn = f ./ norm(f)
    p = abs2.(fn); p ./= sum(p)          # 归一化概率质量（和为 1）
    mx = sum(x .* p)
    vx = sum((x .- mx) .^ 2 .* p)
    g = fft(fn)
    pg = fftshift(abs2.(g)); pg ./= sum(pg)
    ξ = fftshift(k)
    mξ = sum(ξ .* pg)
    vξ = sum((ξ .- mξ) .^ 2 .* pg)
    return sqrt(vx * vξ)
end
g1 = uncertainty(exp.(-x .^ 2))                         # 单 Gauss（σx = 1/√2）
g2 = uncertainty(exp.(-(x .- 4) .^ 2) .+ exp.(-(x .+ 4) .^ 2))          # 双峰
println("Gaussian 的 σx·σξ = $(round(g1, digits=6))（理论下界 0.5）")
println("双峰的   σx·σξ = $(round(g2, digits=6))")
@assert g1 > 0.49
@assert g2 > 1.2 * g1
println("不确定性乘积 Gaussian 最优、双峰显著变大：✓")

# 矩问题：Hankel 矩阵半正定 ⟺ 序列是测度的矩
mmom(k) = 1.0 / (k + 1)               # [0,1] 均匀分布的矩
for sz in [2, 3, 4]
    H = [mmom(i + j) for i in 0:sz-1, j in 0:sz-1]
    @assert minimum(eigvals(Symmetric(H))) > -1e-12
end
println("均匀分布矩序列的 Hankel 矩阵全半正定：✓")
bad = [1.0, 0.0, 0.0, 1.0, 0.0, 0.0]  # 非矩序列（方差 0 却有高阶矩）
Hb = [bad[i + j + 1] for i in 0:2, j in 0:2]
println("反例序列 Hankel 最小特征值 = $(round(minimum(eigvals(Symmetric(Hb))), digits=4)) < 0")
@assert minimum(eigvals(Symmetric(Hb))) < 0
println("非矩序列 ⟹ Hankel 失去半正定（Hamburger 定理的否命题）：✓")
println("==== 44 fourier_moments END ====")
