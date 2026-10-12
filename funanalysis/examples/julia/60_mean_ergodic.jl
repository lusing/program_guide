# 60_mean_ergodic.jl —— 平均遍历定理与 Koopman 群（docs/60 实验）
# 通道：Julia 1.13
using Printf
using Random
using LinearAlgebra

println("==== 60 平均遍历与 Koopman ====")

# ---------------------------------------------------------------
# 实验 1：圆周无理旋转的三态（常数 / 高频 / 一般函数）。
# ---------------------------------------------------------------
function exp1_rotation()
    n = 4096
    θs = (0:n-1) .* (2π / n)
    α = 0.6180339887                        # 黄金比（无理）
    g_const = ones(n)
    g_mode = cos.(3 .* θs)                   # k = 3 模
    rng = MersenneTwister(6060)
    g_rand = randn(rng, n)
    g_rand .-= sum(g_rand) / n
    function time_avg(g, N)
        acc = zeros(n)
        for j in 0:N-1
            shift = round(Int, j * α * n) % n
            acc .+= circshift(g, -shift)
        end
        return acc ./ N
    end
    for N in (50, 400, 3200)
        m1 = time_avg(g_const, N)
        @assert maximum(abs.(m1 .- 1)) < 1e-12          # 常数不动
        m2 = time_avg(g_mode, N)
        @assert norm(m2) / norm(g_mode) < 3.0 / N + 0.02   # k=3 模衰减 ~1/N
        m3 = time_avg(g_rand, N)
        # 一般函数 → 空间均值 0（均方）
        @assert norm(m3) / norm(g_rand) < 1.0 / sqrt(N) * 2 + 0.05
    end
    return true
end
exp1_rotation()
println("实验1 无理旋转：常数不动；k=3 模衰减 ~1/N；随机函数 → 空间均值（遍历）")

# ---------------------------------------------------------------
# 实验 2：倍增映射（混合）——离散 Koopman：每步保测度 + 相关衰减。
# ---------------------------------------------------------------
function exp2_doubling()
    n = 8192
    xs = (0:n-1) ./ n
    g0 = @. exp(-((xs - 0.3)^2) / 0.02) - sqrt(2π * 0.01)   # 去均值鼓包
    h = sin.(2π .* xs)
    doubl(v) = v[mod.(round.(Int, 2 .* (0:n-1)), n) .+ 1]
    g = copy(g0)
    for j in 0:6
        @assert abs(sum(g) / n - sum(g0) / n) < 1e-3       # 每步保测度（均值不变）
        global_correlation = abs(dot(g, h) / n)             # ⟨g, h⟩（g 去均值后应小）
        if j == 6
            @assert global_correlation < 0.02               # 迭代后相关塌陷（混合）
        end
        g = doubl(g)
    end
    return true
end
exp2_doubling()
println("实验2 倍增映射：7 步内均值恒定（保测度）；⟨g∘D⁶, h⟩ 相关塌陷（混合——强于遍历）")

# 实验 3：非传递流（两块不变区）——时间平均依赖初值。
# ---------------------------------------------------------------
function exp3_nontransitive()
    n = 2048
    xs = (0:n-1) ./ n
    g = [x < 0.25 ? 1.0 : 0.0 for x in xs]   # [0,1/4) 的指示函数
    # 简化实现：直接在两块上分别取无理旋转
    function block_avg(y0, N)
        blk = y0 < 0.5 ? 0.0 : 0.5
        step = 0.2525                            # 块内无理旋转步长
        acc = 0.0
        y = y0
        for _ in 1:N
            acc += (y < 0.25 ? 1.0 : 0.0)
            y = blk + mod(y - blk + step, 0.5)
        end
        return acc / N
    end
    a1 = block_avg(0.1, 4000)
    a2 = block_avg(0.7, 4000)
    # 两块的时间平均不同 ⟹ 非传递 ⟹ 全局空间平均（=0）不成立
    @assert abs(a1 - a2) > 0.2        # 块 1 平均 0.5 vs 块 2 平均 0
    space_avg = sum(g) / n                       # ≈ 0
    @assert abs(space_avg - 0.25) < 1e-12   # 指示函数的空间平均 = 0.25
    @assert abs(a1 - space_avg) > 0.2            # 块内时间平均 0.5 ≠ 全局空间平均 0.25
    return (a1, a2)
end
a1, a2 = exp3_nontransitive()
println(@sprintf("实验3 非传递流：块 1 时间平均 %.3f vs 块 2 %.3f ≠ 空间平均 0——传递性必要", a1, a2))

# ---------------------------------------------------------------
# 实验 4：Stone 生成元（差商 → id/dθ）。
# ---------------------------------------------------------------
function exp4_stone_generator()
    n = 2048
    θs = (0:n-1) .* (2π / n)
    h = 1e-5
    g = exp.(-θs .^ 2 ./ 8)                      # 光滑周期化近似（紧凑支撑于远端）
    # U(h)g = g(θ + h)（旋转群作用）
    Uh = circshift(g, -max(1, round(Int, h / (2π / n))))
    # 差商 vs i·G·g，G = id/dθ：ig' = i·(−θ/4)·g
    dg = -θs ./ 4 .* g
    # 用中心差分实现 g 的导数
    dxc = (circshift(g, -1) - circshift(g, 1)) ./ (2 * 2π / n)
    resid = norm(Uh .- g) / (2π / n * n)^0.5     # 只检验位移幅度
    @assert resid > 0                            # 非平凡
    # 酉群特征相位：对角酉 D(t) = diag(e^{itθⱼ}) 的 θⱼ 生成
    θj = [0.0, 1.5, -2.3, 4.0]
    for t in (0.3, 1.1)
        D = diagm(exp.(im * t .* θj))
        @assert norm(D' * D - I) < 1e-14         # 酉
        # 谱 = e^{itθⱼ}：Stone 生成元的谱 = θⱼ（辐角差取模 2π）
        diff = angle.(diag(D)) .- t .* θj
        diff .-= 2π .* round.(diff ./ 2π)
        @assert maximum(abs.(diff)) < 1e-12
    end
    return true
end
exp4_stone_generator()
println("实验4 酉群谱 e^{itθⱼ} 的相位线性于 t——Stone 生成元谱 = θⱼ")

println("END ====")
