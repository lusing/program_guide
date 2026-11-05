# 第 61 章 Julia：离散 GFF 的采样对账与对数相关场的鞅账（固定种子）。
# ① 路径图（n=8）离散 GFF：Cholesky(G) 采样，经验协方差 vs 闭式
#    G(i,j) = min(i,j)(9−max(i,j))/9；
# ② 布朗桥身份：同一 G 的另一采样法（布朗运动减线性钉扎）经验协方差
#    与 ① 对账——一维离散 GFF = 布朗桥；
# ③ 对数相关场的鞅：圆环模型 h_n(θ)，总质量 M_n 的经验均值 vs 理论 1。
println("==== 61 gaussian_free_field")
using Random, Statistics, LinearAlgebra

const rng = MersenneTwister(6101)
n = 8
Gc = [Rational(min(i, j) * (n + 1 - max(i, j)), n + 1) for i in 1:n, j in 1:n]

# ---------- ① Cholesky 采样 ----------
K = cholesky(Matrix{Float64}(Gc)).L
X = K * randn(rng, n, 10_000)
emp = cov(X', dims=1)                     # 样本协方差（10^4 条）
max_dev = maximum(abs.(emp .- Float64.(Gc)))
println("① Cholesky 采样（10^4 条）：max |emp_cov − G| = ", round(max_dev, digits=4))
@assert max_dev < 0.06                    # 噪声地板 ~ 1/√10^4 量级
println("   G(4,4) = ", Gc[4, 4], "（中点最大），G(1,1) = ", Gc[1, 1], "，G(1,8) = ", Gc[1, 8])

# ---------- ② 布朗桥身份 ----------
B = cumsum(randn(rng, n + 1, 30_000), dims=1)      # B_1..B_9（含 B_0=0）
Ymat = Matrix{Float64}(undef, 30_000, n)
for i in 1:n
    @views Ymat[:, i] .= B[i, :] .- (i / (n + 1)) * B[n + 1, :]
end
emp2 = cov(Ymat, dims=1)
bridge = [Rational(min(i, j)) - (i * j) // (n + 1) for i in 1:n, j in 1:n]
@assert bridge == Gc                       # 桥公式 = G 闭式（精确相同）
max_dev2 = maximum(abs.(emp2 .- Float64.(Gc)))
println("② 布朗桥构造的经验协方差：max |dev| = ", round(max_dev2, digits=4))
@assert max_dev2 < 0.08   # 桥构造经由 B_9 耦合，噪声地板略高
println("   桥公式 min(i,j)−ij/9 与 G 闭式逐项相等：一维离散 GFF = 布朗桥")

# ---------- ③ 对数相关场的鞅账 ----------
function chaos_mass(gam, nterm, ndraws)
    Hn = sum(1.0 / k for k in 1:nterm)
    θgrid = range(0, 2π, length=64)[1:63]  # 均匀网格（去端点）
    masses = Float64[]
    for _ in 1:ndraws
        z1 = randn(rng, nterm)
        z2 = randn(rng, nterm)
        tot = 0.0
        for θ in θgrid
            h = sum((z1[k] * cos(k * θ) + z2[k] * sin(k * θ)) / sqrt(k) for k in 1:nterm)
            tot += exp(gam * h - gam^2 * Hn / 2)
        end
        push!(masses, tot / length(θgrid))
    end
    return mean(masses), std(masses)
end
println("③ 对数相关场的总质量（理论 E[M_n] = 1，鞅均值不变）：")
for gam in [0.5, 1.0]
    m, s = chaos_mass(gam, 30, 3000)
    println("   γ=", gam, "：E[M_n] ≈ ", round(m, digits=4), "（std ", round(s, digits=3),
            "，γ 越大方差越大——次临界/超临界的门槛在 √2）")
    @assert abs(m - 1) < 0.1
end

println("END ====")
