# 59_semigroups.jl —— 半群与 Hille-Yosida（docs/59 实验）
# 通道：Julia 1.13 + LinearAlgebra/FFTW
using LinearAlgebra
using FFTW
using Printf
using Random

println("==== 59 半群与 Hille-Yosida ====")

# ---------------------------------------------------------------
# 实验 1：热半群（Fourier 对角化）的生成元与预解式。
# ---------------------------------------------------------------
function exp1_heat_semigroup()
    n = 256
    k = fftfreq(n) .* n                       # 整数频率
    # 压缩性：|e^{-k²t}| ≤ 1
    for t in (0.01, 0.5, 2.0)
        @assert maximum(abs.(exp.(-k .^ 2 .* t))) ≤ 1.0
    end
    # 生成元：差商收敛到 -k²（对低频向量）
    h = 1e-6
    for kk in (0, 1, 3, 5)
        comp = exp(-kk^2 * h)                 # eₖ 分量在 Z(h) 下
        dq = (comp - 1) / h                   # 差商
        @assert abs(dq + kk^2) < 1e-4 * max(kk^2, 1) * h^0
        @assert abs(dq + kk^2) / max(kk^2, 1) < 15h  # 一阶精度（常数 k²h/2）
    end
    # 预解式 = Laplace 变换：1/(ζ+k²) = ∫e^{-ζt}e^{-k²t}dt = 1/(ζ+k²)（解析）
    # 数值验证积分
    for (ζ, kk) in ((1.0, 0.0), (2.0, 1.0), (0.5, 3.0))
        # 区间自适应：宽度 ~ 若干倍衰减尺度（分辨率须高于尖峰宽度）
        up = min(50.0, 40 / (ζ + kk^2))
        lap = quadgl(t -> exp(-ζ * t) * exp(-kk^2 * t), 0.0, up)
        tail = exp(-(ζ + kk^2) * up) / (ζ + kk^2)   # 截断尾补偿
        @assert abs(lap + tail - 1 / (ζ + kk^2)) < 1e-10
    end
    return true
end
# 小工具：Gauss-Legendre 数值积分（Golub-Welsch，30 点）
function quadgl(f, a, b)
    n = 30
    β = [i / sqrt(4i^2 - 1) for i in 1:n-1]    # Golub-Welsch（分子有 i）
    vals, vecs = eigen(SymTridiagonal(zeros(n), β))
    xs = (b - a) / 2 .* vals .+ (a + b) / 2
    ws = (vecs[1, :] .^ 2) .* (b - a)          # 权重 = 首分量平方（×区间长）
    return sum(ws .* f.(xs))
end
exp1_heat_semigroup()
println("实验1 热半群：压缩；生成元差商 → −k²；预解式 = Laplace 变换（1e-10）")

# ---------------------------------------------------------------
# 实验 2：Lax 等价定理的双面（对流方程 u_t = u_x，周期）。
# u(x,t) = f(x+t)（左行）。精确解 = 整周期循环移位。
# 格式 A：前向 Euler + 中心差分——相容但恒不稳（放大 |1−iC·sinθ|>1）；
# 格式 B：隐式迎风 (1+C)u_i − C·u_{i−1} = uⁿ——稳定（|amp|⁻¹=|1+C(1−e^{iθ})|≥1−C>0）。
# ---------------------------------------------------------------
function exp2_lax_equivalence()
    # 收敛性以加密序列表达（一阶格式绝对误差天然 O(dx)）
    results = Tuple{Float64,Float64}[]
    for n in (128, 256)
        dx = 1.0 / n
        xs = (collect(0:n-1) .+ 0.5) ./ n
        f0 = @. exp(-((xs - 0.3)^2) / 0.01)
        # 播 1e-4 高频纹波：给不稳定模式食物（Lax 等价定理说的是
        # 一切初值的行为；光滑初值只是推迟爆发的可见性）
        ripple = 1e-4 .* [(-1.0)^i for i in 0:n-1]
        f0s = f0 .+ ripple
        T = 1.0                                 # 整周期：exact = f0s
        exact = f0s
        dxc(v) = (circshift(v, -1) - circshift(v, 1)) / (2dx)
        dtA = 0.4 * dx
        nA = round(Int, T / dtA)
        uA = copy(f0s)
        for _ in 1:nA
            uA .+= dtA .* dxc(uA)
        end
        C = 0.9
        dtB = C * dx
        nB = round(Int, T / dtB)
        B = Matrix(1.0I, n, n) * (1 + C)
        for i in 1:n
            B[i, mod1(i + 1, n)] -= C
        end
        uB = copy(f0s)
        for _ in 1:nB
            uB = B \ uB
        end
        push!(results, (norm(uA - exact) / norm(exact), norm(uB - exact) / norm(exact)))
    end
    errA1, errB1 = results[1]
    errA2, errB2 = results[2]
    @assert errA1 > 10.0                       # 不稳定：有纹波种子即爆
    @assert errB2 < errB1 * 0.8                # 稳定：加密收敛（一阶）
    return (errA1, errB1, errB2)
end
errA, errB, errB2 = exp2_lax_equivalence()
println(@sprintf("实验2 对流方程 T=1：前向中心差分误差 %.0f（发散）；隐式迎风 %.3f→%.3f（加密收敛）——稳定 ⟺ 收敛", errA, errB, errB2))

# ---------------------------------------------------------------
# 实验 3：Trotter 乘积公式与 Strang 分裂。
# ---------------------------------------------------------------
function exp3_trotter()
    rng = MersenneTwister(5959)
    m = 8
    A = randn(rng, m, m)
    B = randn(rng, m, m)
    t = 0.5
    # 参考：expm 由缩放-平方
    E(t) = begin
        s = max(0, ceil(Int, log2(opnorm(t * A, 2)))) # A 换 t*A
        s2 = max(0, ceil(Int, log2(opnorm(t * B, 2))))
        scale = max(s, s2)
        # 逐个算（简化：直接矩阵指数级数于 tA+tB）
        series_exp(t * (A + B))
    end
    series_exp(M) = begin
        s = max(0, ceil(Int, log2(opnorm(M, 1))))
        Ms = M / 2.0^s
        E = Matrix{Float64}(I, size(M)); X = Matrix{Float64}(I, size(M))
        for k in 1:20; X *= Ms / k; E += X; end
        for _ in 1:s; E = E * E; end
        return E
    end
    ref = series_exp(t * (A + B))
    # 简化：分别写 helper
    expm1(M) = series_exp(M)
    eA(dt) = series_exp(dt * A)
    eB(dt) = series_exp(dt * B)
    errL(n) = opnorm(series_exp(t * (A + B)) - (eA(t/n) * eB(t/n))^n)
    errS(n) = opnorm(series_exp(t * (A + B)) - (eA(t/2n) * eB(t/n) * eA(t/2n))^n)
    e1, e2 = errL(16), errL(64)
    s1, s2 = errS(16), errS(64)
    @assert e2 < e1 / 2.5                     # Lie: O(1/n)（n×4 → err×~1/4）
    @assert s2 < s1 / 8                       # Strang: O(1/n²)
    return (e1, e2, s1, s2)
end
eL1, eL2, eS1, eS2 = exp3_trotter()
println(@sprintf("实验3 Trotter：Lie 误差 %.1e→%.1e（~×1/4）；Strang %.1e→%.1e（~×1/16，二阶）",
                 eL1, eL2, eS1, eS2))

# ---------------------------------------------------------------
# 实验 4：Yosida 逼近的逐步还原。
# ---------------------------------------------------------------
function exp4_yosida()
    n = 80
    h = 1.0 / (n + 1)
    G = SymTridiagonal(-2.0 ./ h^2 .* ones(n), 1.0 ./ h^2 .* ones(n - 1))  # Δ（负定）
    ev = eigen(G).values                     # 升序（最负在前）
    worst = 0.0
    for N in (5, 20, 100)
        RN = inv(N * Matrix(1.0I, n, n) - Matrix(G))
        Gn = N^2 .* RN .- N .* Matrix(1.0I, n, n)   # Yosida 逼近 (21)
        evn = eigen(Symmetric((Gn + Gn') / 2)).values
        # 比较靠近零端的特征值（Yosida 把 |λ|>N 的端削平到 −N——
        # 收敛是逐特征值的：固定的 λ 在 N ≫ |λ| 时 nλ/(N−λ) → λ）
        for j in (n, n - 1, n - 2)
            worst = max(worst, abs(evn[j] - ev[j]) / abs(ev[j]))
        end
        worstN = abs(evn[n] - ev[n]) / abs(ev[n])
        @assert worstN < abs(ev[n]) / N * 1.5 # 相对误差 ≈ |λ|/N（一阶）
    end
    # nR(n) → I（范数单调下降）
    d10 = opnorm(10 .* inv(10 * Matrix(1.0I, n, n) - Matrix(G)) - Matrix(1.0I, n, n))
    d50 = opnorm(50 .* inv(50 * Matrix(1.0I, n, n) - Matrix(G)) - Matrix(1.0I, n, n))
    @assert d50 < d10
    return true
end
exp4_yosida()
println("实验4 Yosida 逼近 Gₙ = n²R(n) − nI：特征值以 O(1/N) 还原 G；nR(n) → I")

println("END ====")
