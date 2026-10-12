# 65_fixed_points_haar.jl —— 不动点定理群与 Haar 测度（docs/65 实验）
# 通道：Julia 1.13 + LinearAlgebra
using LinearAlgebra
using Printf
using Random

println("==== 65 不动点群与 Haar ====")

# ---------------------------------------------------------------
# 实验 1：Markov-Kakutani 平均迭代的收敛（交换仿射 vs 非交换）。
# ---------------------------------------------------------------
function exp1_markov_kakutani()
    # 交换对：两个对角仿射映射（自动交换）
    # 对角线性映射（自动交换）；不动点 = 原点
    T1(x) = [0.6x[1]; 0.8x[2]]
    T2(x) = [0.7x[1]; 0.5x[2]]
    @assert norm(T1(T2([0.3, 0.4])) - T2(T1([0.3, 0.4]))) < 1e-14   # 交换（对角）
    x = [0.5, 0.5]
    for k in 1:200
        x = k % 2 == 1 ? T1(x) : T2(x)
    end
    @assert norm(x) < 0.2                        # 收敛到公共不动点 (0,0) 附近
    @assert norm(T1(x) - x) < 1e-3 && norm(T2(x) - x) < 1e-3
    # 非交换对照：旋转 + 平移（小收缩）
    θ = 0.7
    R = [cos(θ) -sin(θ); sin(θ) cos(θ)]
    S1(x) = 0.95 .* R * x
    S2(x) = 0.95 .* [cos(-θ/2) -sin(-θ/2); sin(-θ/2) cos(-θ/2)] * x .+ [0.05, 0]
    y = [0.5, -0.3]
    for k in 1:400
        y = k % 2 == 1 ? S1(y) : S2(y)
    end
    @assert norm(y) < 0.5                        # 仍收敛（两个都是收缩）
    # Markov-Kakutani 平均的显式演示：T_n = n⁻¹(I+T+…+T^{n-1})
    T = x -> 0.8 * x .+ [0.1, 0.0]
    avg(x0, n) = begin
        acc = zero(x0); cur = copy(x0)
        for j in 0:n-1
            acc .+= cur
            cur = T(cur)
        end
        acc ./ n
    end
    # Cesàro 平均收敛率 O((1-ρⁿ)/(n(1-ρ)))；不动点 = (0.5, 0)
    @assert norm(avg([1.0, 1.0], 500) - [0.5, 0.0]) < 0.02   # 平均 → 不动点
    return true
end
exp1_markov_kakutani()
println("实验1 交换仿射对收敛到公共不动点；Tₙ 平均序列 → 不动点（n⁻¹ 压缩机制）")

# ---------------------------------------------------------------
# 实验 2：Haar 测度的经验构造（圆周群 + 四元数 SO(3)）。
# ---------------------------------------------------------------
function exp2_haar_empirical()
    rng = MersenneTwister(6565)
    # (a) 圆周群：f(θ) = exp(cosθ)，左移平均 → 弧长平均
    m = 4096
    θs = (0:m-1) .* (2π / m)
    f(θ) = exp(cos(θ))
    # 等距移位平均（凸壳逼近常数的最快形态）：等距的 n 个移位
    for n in (64, 256, 1024)
        shifts = collect(0:n-1) .* (2π / n)
        vals = [f(θ .+ s) for θ in θs, s in shifts]
        avg = vec(sum(vals, dims=2) ./ n)
        spread = maximum(avg) - minimum(avg)
        @assert spread < 1e-6                    # 等距 ⟹ 机器级常数（Mf）
    end
    # 弧长平均 = I₀(1)（修正 Bessel）
    exact = sum(f.(θs)) / m
    # (b) 四元数（SU(2)/SO(3)）：随机旋转的经验 Haar = 球面均匀
    function rand_quat(rng)
        u1, u2, u3 = rand(rng), rand(rng), rand(rng)
        s1, s2 = sqrt(1 - u1), sqrt(u1)
        [s1 * sin(2π * u2), s1 * cos(2π * u2), s2 * sin(2π * u3), s2 * cos(2π * u3)]
    end
    # Haar 经验积分：⟨f⟩ ≈ (1/n)Σf(qᵢ)，f = 旋转把 z 轴带到 v(q) 的 z 分量²
    n2 = 20000
    acc = 0.0
    for _ in 1:n2
        q = rand_quat(rng)
        Rz = 1 - 2 * (q[1]^2 + q[2]^2)           # 旋转矩阵的 (3,3) 元
        acc += Rz^2
    end
    emp = acc / n2
    @assert abs(emp - 1 / 3) < 0.02              # 均匀球面：⟨cos²⟩ = 1/3
    return (exact, emp)
end
exact2, emp2 = exp2_haar_empirical()
println(@sprintf("实验2 圆周群左移平均 → 常数 Mf=I₀(1)≈%.4f；SO(3) 经验 Haar：⟨cos²θ⟩ = %.4f（理论 1/3）",
                 exact2, emp2))

# ---------------------------------------------------------------
# 实验 3：S₃ 上的不变测度均匀化。
# ---------------------------------------------------------------
function exp3_s3_uniformization()
    rng = MersenneTwister(6566)
    # S₃ 的 6 个置换矩阵
    perms = [[1,2,3],[1,3,2],[2,1,3],[2,3,1],[3,1,2],[3,2,1]]
    PM(p) = [Float64(j == p[i]) for i in 1:3, j in 1:3]
    Ps = [PM(p) for p in perms]
    # 随机初始测度（6 维非负、和 1），w[i] = 群上函数在 perms[i] 处的值
    w = rand(rng, 6); w ./= sum(w)
    # 左平移作用在函数上：(τ_g w)(h) = w(g⁻¹h)——用置换表实现
    # perms 的左乘表：L[i][j] = index of perms[i]∘perms[j]（复合）
    lookup(p, q) = begin
        comp = [q[p[k]] for k in 1:3]              # p 后 q：先 p 再 q
        findfirst(x -> x == comp, perms)
    end
    # Markov-Kakutani 平均：w ← (1/6)Σᵢ τᵢw（全群 Cesàro——正是
    # 5.23 的 T_n 平均，把支撑的差异逐层磨平）
    for _ in 1:200
        acc = zeros(6)
        for i in 1:6
            for j in 1:6                          # (τᵢw)(perms[j]) = w(perms[i]∘perms[j])
                acc[j] += w[lookup(perms[i], perms[j])]
            end
        end
        w = acc ./ 6
    end
    @assert maximum(abs.(w .- 1 / 6)) < 1e-10     # 均匀化（几何收敛）
    return true
end
exp3_s3_uniformization()
println("实验3 S₃：随机左平移 + 混合 ⟹ 测度均匀化到 1/6（唯一不变测度）")

# ---------------------------------------------------------------
# 实验 4：Schauder-Brouwer 桥（连续非仿射映射的不动点）。
# ---------------------------------------------------------------
function exp4_schauder_brouwer()
    # K = [0,1]²，f = 旋转 0.4 rad + 向中心平移（连续非仿射扰动）
    θ = 0.4
    R = [cos(θ) -sin(θ); sin(θ) cos(θ)]
    f(x) = R * (x .- [0.5, 0.5]) .* 0.92 .+ [0.5, 0.5]
    # 迭代收敛（0.92 < 1 收缩——Brouwer 的平凡情形；非收缩情形用重心迭代）
    x = [0.2, 0.8]
    for _ in 1:400
        x = f(x)
    end
    @assert norm(f(x) - x) < 1e-8
    @assert all(0 .<= x .<= 1)                    # 不动点在 K 内
    # 非凸对照：K = 环状域，f = 旋转 π/2（无不动点）
    g(x) = [-(x[2] - 0.5) + 0.5; x[1] - 0.5 + 0.5]
    y = [0.5 + 0.3, 0.5]
    for _ in 1:100
        y = g(y)
    end
    @assert norm(y - [0.5, 0.5]) > 0.1            # 绕圈不收敛（无不动点的形态）
    return x
end
x4 = exp4_schauder_brouwer()
println(@sprintf("实验4 旋转压缩映射不动点 (%.3f, %.3f) ∈ K；环域 π/2 旋转无不动点游走", x4...))

println("END ====")
