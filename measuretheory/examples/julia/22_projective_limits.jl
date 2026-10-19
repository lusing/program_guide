println("==== 22 projective_limits")
# 第 22 章：投影极限的有限塔显影。
# ① Cantor 塔：均匀位串在每层 n 的分布 = 均匀 2^-n（相容族的极限）；
# ② 高斯塔：布朗式协方差 min(s,t) 的 n 维截段采样（Cholesky），
#    共享坐标边缘在两层塔中同分布（同一条样本轨道，两层账一致）；
# ③ 连续修改预演：网格加密 max|B_{t+Δ}-B_t| ~ sqrt(Δ·log(1/Δ))。

using Random, LinearAlgebra
using Statistics: cov, mean
Random.seed!(7)

# ---- ① Cantor 塔的相容性 ----
function cantor_layer_check(n::Int, samples::Int)
    counts = Dict{Vector{Int},Int}()
    for _ in 1:samples
        bits = rand(0:1, n)
        counts[bits] = get(counts, bits, 0) + 1
    end
    counts
end
for n in (4, 8)
    samples = 1024 * 2^n
    counts = cantor_layer_check(n, samples)
    expected = samples / 2^n
    for (pat, c) in counts
        @assert abs(c - expected) / expected < 0.25    # 每花样期望 1024 命中，4σ 容差
    end
    @assert length(counts) == 2^n                      # 全部花样都被访问
end
println("Cantor tower: layer-n distribution uniform 2^-n (n=4,8): OK")

# ---- ② 高斯塔：共享坐标的边缘一致 ----
# Σₙ = [min(sᵢ,sⱼ)]，t = (1,2,3)：Cholesky 采样三维高斯，
# 检查前两坐标的样本协方差 ≈ Σ₂（三维塔的 (1,2)-边缘 = 二维塔）
Σ3 = [min(i, j) + 0.0 for i in 1:3, j in 1:3]
L = cholesky(Σ3).L
N = 200_000
samples3 = L * randn(3, N)                 # 每列一条样本
C12 = cov(samples3[1:2, :], dims=2)
@assert abs(C12[1, 1] - 1.0) < 0.02
@assert abs(C12[2, 2] - 2.0) < 0.05
@assert abs(C12[1, 2] - 1.0) < 0.02
# 二维塔直接采样对比：
Σ2 = [1.0 1.0; 1.0 2.0]
L2 = cholesky(Σ2).L
samples2 = L2 * randn(2, N)
C2 = cov(samples2, dims=2)
@assert maximum(abs.(C12 .- C2)) < 0.05    # 两层塔的共享边缘同分布
println("Gaussian tower: shared-coordinate marginals coincide across layers: OK")

# ---- ③ 连续修改预演：Lévy 模量的数值影子 ----
# 细化网格 Δ = 2^-k 上的增量最大值 ~ sqrt(2Δ·log(1/Δ))（模量常数）
function max_incr(k::Int)
    m = 2^k                              # [0,1] 上 m 段，步长 Δ = 1/m
    incrs = randn(m) .* sqrt(1.0 / m)    # N(0, Δ) 增量
    maximum(abs.(incrs))
end
for k in (4, 6, 8, 10)
    mi = max_incr(k)
    Δ = 2.0^-k
    levy = sqrt(2 * Δ * log(1 / Δ))
    @assert 0.3 * levy < mi < 2.5 * levy  # 常数容忍：量级对齐（模量的影子）
end
println("continuity preview: max increment ~ sqrt(2*Delta*log(1/Delta)): OK")

println("END ====")
