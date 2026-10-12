# 51_weak_applications.jl —— 弱收敛的应用（docs/51 第七章实验）
# 通道：Julia 1.13 + LinearAlgebra
using LinearAlgebra
using Printf
using Random
using Statistics
using FFTW

println("==== 51 弱收敛的应用 ====")

# ---------------------------------------------------------------
# 实验 1：Dirichlet 核的 log 增长与 Fejér 核的治愈。
# ‖D_N‖₁/(2π) ~ (4/π²)log N；‖K_N‖₁/(2π) = 1 恒定（非负性）。
# 受害者构造：f = Σ εⱼ·光滑化 sign(D_{Nⱼ})，S_{Nⱼ}(f)(0) 增长。
# ---------------------------------------------------------------
function dirichlet_l1(N::Int, m::Int = 20 * N)
    θs = (0:m-1) .* (2π / m)
    d = abs.(sin.((N + 0.5) .* θs)) ./ max.(abs.(sin.(θs ./ 2)), 1e-300)
    # θ=0 处取极限值 2N+1；梯形积分
    d[1] = 2N + 1
    return sum(d) * (2π / m) / (2π)
end
function fejer_l1(N::Int, m::Int = 20 * N)
    # K_N 非负：‖K_N‖₁ = ∫K_N = 2π（归一性）——数值验证非负闭式
    θs = (0:m-1) .* (2π / m)
    K = [(1 / (N + 1)) * (sin((N + 1) * t / 2) / max(sin(t / 2), 1e-300))^2 for t in θs]
    K[1] = N + 1
    return sum(K) * (2π / m) / (2π)
end
function exp1()
    Ns = [2^k for k in 2:12]
    l1 = [dirichlet_l1(N) for N in Ns]
    for N in Ns[2:end]
        @assert fejer_l1(N) ≈ 1.0 atol = 1e-9        # Fejér 归一
    end
    # 斜率拟合：‖D_N‖₁/(2π) ≈ (4/π²)·log N + c
    x = log.(Float64.(Ns)); y = l1
    slope = sum((x .- mean(x)) .* (y .- mean(y))) / sum((x .- mean(x)) .^ 2)
    @assert 0.30 < slope < 0.50                      # ≈ 4/π² = 0.405
    # 受害者构造：光滑化 sign(D_N) 逐层叠加
    m = 2^16
    θs = (0:m-1) .* (2π / m)
    f = zeros(m)
    grow = Float64[]
    for (j, N) in enumerate([64, 256, 1024, 4096])
        d = sin.((N + 0.5) .* θs) ./ sin.(θs ./ 2 .+ 1e-300)
        d[1] = 2N + 1
        sg = sign.(d)
        # 光滑化：与宽 σ 的 Gauss 卷积（FFT 圆卷积）
        σ = (2π / (N + 0.5)) / 10     # 光滑宽度 << 振荡周期：保住 sign 结构
        θc = min.(θs, 2π .- θs)
        k = exp.(-(θc .^ 2) / (2σ^2)); k ./= sum(k)
        sg_smooth = real.(ifft(fft(sg) .* fft(k)))
        w = 1 / j
        f .+= w .* sg_smooth
        # S_N(f)(0)：∫f·D_N/(2π)（f 是实值周期）
        dN = sin.((N + 0.5) .* θs) ./ sin.(θs ./ 2 .+ 1e-300); dN[1] = 2N + 1
        push!(grow, sum(f .* dN) * (2π / m) / (2π))
    end
    @assert grow[end] > 2.0 && grow[end] > grow[1]   # 部分和沿子列增长
    return (slope, grow)
end
slope1, grow1 = exp1()
println(@sprintf("实验1 ‖D_N‖₁/(2π) 拟合斜率 %.3f（理论 4/π²=0.405）；Fejér 恒 1", slope1))
println(@sprintf("      受害者 f 的 S_N(f)(0) 沿子列：%.2f → %.2f（增长）", grow1[1], grow1[end]))

# ---------------------------------------------------------------
# 实验 2：Fourier-Galerkin 谱收敛（u′ + u = f，周期）。
# f = exp(cos t) 解析 ⟹ 系数指数衰减 ⟹ 机器精度。
# 能量估计形态：min|in+1| = √2（n=0 与 n=−1 处 |i·0+1|=1，
# |−i+1|=√2——实际 min=1），‖u‖ ≤ ‖f‖/1。
# ---------------------------------------------------------------
function exp2()
    n = 256
    θs = (0:n-1) .* (2π / n)
    f = exp.(cos.(θs))
    f̂ = fft(f) / n
    û = zeros(ComplexF64, n)
    for k in 0:(n-1)
        mode = k ≤ n ÷ 2 ? k : k - n            # 频率 ∈ (-n/2, n/2]
        û[k+1] = f̂[k+1] / (im * mode + 1)
    end
    u = real.(ifft(û))
    # 余量：谱域逐点 |(in+1)û − f̂|
    res = maximum([abs((im * (k ≤ n ÷ 2 ? k : k - n) + 1) * û[k+1] - f̂[k+1])
                   for k in 0:(n-1)])
    @assert res < 1e-14
    @assert norm(u) ≤ norm(f) * (1 + 1e-12)     # 能量估计（k=1）
    return res
end
r2 = exp2()
println(@sprintf("实验2 Fourier-Galerkin 谱余量 %.1e（机器级），能量估计 ‖u‖≤‖f‖", r2))

# ---------------------------------------------------------------
# 实验 3：求积公式的分水岭（Gauss vs Newton-Cotes）。
# Gauss-Legendre 权恒正：对 e^t 与 |t−1/2|^{1/2} 都收敛；
# 高阶 Newton-Cotes 权出负、Σ|w| 爆炸：对后者发散。
# ---------------------------------------------------------------
function newton_cotes_weights(N::Int)
    # 在 [0,1] 等距节点上积分 Lagrange 基（闭式：用权重表或积分多项式）
    ts = (0:N) ./ N
    w = zeros(N + 1)
    for j in 0:N
        # 数值积分基函数（梯形加密的精确多项式积分）
        m = 4N + 16
        s = (1:N*m) ./ (N * m)
        Lj = ones(length(s))
        for k in 0:N
            if k != j
                Lj .*= (s .- ts[k+1]) ./ (ts[j+1] - ts[k+1])
            end
        end
        w[j+1] = sum(Lj) ./ (N * m)
    end
    return w
end
function exp3()
    # Gauss-Legendre：scipy 不可用——Julia 用 Golub-Welsch（对称三对角）
    function gauss_legendre(N)
        β = [i / sqrt(4i^2 - 1) for i in 1:N-1]
        T = SymTridiagonal(zeros(N), β)
        vals, vecs = eigen(T)
        return (vals .+ 1) ./ 2, (vecs[1, :] .^ 2)          # 映到 [0,1]：x=(λ+1)/2，w=2v₁²/2
    end
    e2s = Float64[]
    for N in (10, 30, 50)
        xs, ws = gauss_legendre(N)
        @assert all(ws .> 0)                            # 权恒正
        e1 = abs(sum(ws .* exp.(xs)) - (exp(1) - 1))
        e2 = abs(sum(ws .* abs.(xs .- 0.5) .^ 0.5) - (2 / 3) * (0.5^1.5 + 0.5^1.5))
        @assert e1 < 1e-12                              # 解析被积函数：机器精度
        push!(e2s, e2)
    end
    @assert e2s[3] < e2s[1] / 5                         # 病态函数：代数式收敛（仍在收敛）
    # Newton-Cotes：绝对和爆炸 + 病态函数发散
    w20 = newton_cotes_weights(20)
    w30 = newton_cotes_weights(30)
    @assert sum(abs, w20) < sum(abs, w30)               # 绝对和增长
    @assert minimum(w30) < 0                            # 出现负权
    return (sum(abs, w20), sum(abs, w30), minimum(w30))
end
s20, s30, wmin = exp3()
println(@sprintf("实验3 Gauss（权恒正）全收敛；N-C Σ|w|：%.1f(N=20) → %.1f(N=30)，min w = %.1f",
                 s20, s30, wmin))

# ---------------------------------------------------------------
# 实验 4：Dunford 定理的数值影子（F(ζ) = e^{ζA}）。
# (a) 随机场泛函 l_v(F) 的 CR 残差 O(h²)；
# (b) 差商范数收敛：‖(F(h)−F(0))/h − A‖ → 0。
# ---------------------------------------------------------------
function expm(A::Matrix{ComplexF64})
    # 缩放-平方法（教学实现）
    n = size(A, 1)
    s = opnorm(A, 1) > 1.0 ? ceil(Int, log2(opnorm(A, 1))) : 0
    As = A / 2.0^s
    E = Matrix{ComplexF64}(I, n, n); X = Matrix{ComplexF64}(I, n, n)
    for k in 1:25
        X *= As / k
        E += X
    end
    for _ in 1:s
        E = E * E
    end
    return E
end
function exp4()
    rng = MersenneTwister(5151)
    n = 6
    A = randn(rng, n, n) + im * randn(rng, n, n)
    F(z) = expm(A * z)
    z0 = 0.3 + 0.2im
    # (a) 随机场 v（单位化）的 CR 残差：l_v(X) = v′Xv
    cr(h) = begin
        du = (F(z0 + h) - F(z0 - h)) / 2h
        dv = (F(z0 + im * h) - F(z0 - im * h)) / (2h)
        worst = 0.0
        for _ in 1:50
            v = randn(rng, n) + im * randn(rng, n)
            v = v / norm(v)                        # 单位化：|v′Xv| ≤ ‖X‖
            worst = max(worst, abs(v' * (du + im * dv) * v))
        end
        worst
    end
    c1, c2 = cr(0.1), cr(0.05)
    @assert c2 < 0.05                              # CR 成立（小残差）
    @assert c1 / c2 > 2.0                          # O(h²)：减半 → ~×1/4
    # (b) 差商范数收敛（强解析）
    e1 = opnorm((F(0.2) - F(0.0)) / 0.2 - A)
    e2 = opnorm((F(0.1) - F(0.0)) / 0.1 - A)
    @assert e2 < e1 / 1.5
    return (c2, e1, e2)
end
w4, e41, e42 = exp4()
println(@sprintf("实验4 随机场 CR 残差 %.1e；差商收敛 %.2e → %.2e（弱=强解析）", w4, e41, e42))

println("END ====")
