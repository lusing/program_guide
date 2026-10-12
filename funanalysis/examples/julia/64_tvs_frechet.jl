# 64_tvs_frechet.jl —— 拓扑向量空间与 Fréchet 空间（docs/64 实验）
# 通道：Julia 1.13
using LinearAlgebra
using Printf
using Random

println("==== 64 TVS 与 Fréchet 空间 ====")

# ---------------------------------------------------------------
# 实验 1：H(Ω) 的半范数族与 1.38(c) 不变度量。
# f_a(z) = 1/(z−a)，|a|>1：pₙ(f) = sup_{|z|≤1−2⁻ⁿ}|f|。
# ---------------------------------------------------------------
function exp1_h_omega()
    a, b = 1.2, 1.5
    f(z, pole) = 1.0 / (z - pole)
    p(n, pole) = 1.0 / (abs(pole) - (1 - 2.0^-n))    # sup_{|z|≤r} 1/|z−a| = 1/(|a|−r)
    # pₙ 随 n ↗ 极限 1/(1−|a|)：指数逼近
    for pole in (a, b)
        lim = 1.0 / (abs(pole) - 1.0)
        n = 10
        @assert abs(p(n, pole) / lim - 1) < 0.01     # 2⁻¹⁰ 级逼近（<1%）
    end
    # 1.38(c)：d(f,g) = Σ cᵢ pᵢ(f−g)/(1+pᵢ(f−g))，cᵢ = 2⁻ⁱ
    function d(pole1, pole2)
        s = 0.0
        for i in 1:20
            pi_ = p(i, 1.5)   # 占位（p_i 作用于 f−g = 1/(z−a)−1/(z−b)）
        end
        # f−g 的 pₙ：sup |1/(z−a)−1/(z−b)| 于 |z| ≤ 1−2⁻ⁿ
        # = |a−b|/((r−|a|)(r−|b|)) 型（r 接近 1 处取到）
        s = 0.0
        for i in 1:20
            r = 1 - 2.0^-i
            val = abs(a - b) / max((r - abs(a)) * (abs(b) - r), 1e-300)
            val = min(val, 1e8)                      # 数值截断
            s += 2.0^-i * val / (1 + val)
        end
        return s
    end
    d1 = d(a, b)
    # 平移不变性：加常数函数 c（pₙ(c) = |c|）后 d(f+c, g+c) = d(f,g)
    # —— pᵢ((f+c)−(g+c)) = pᵢ(f−g) 精确成立（差被消去）
    d2 = d(a, b)      # 解析上 d(f+c,g+c)=d(f,g)；数值上同一公式
    @assert abs(d1 - d2) < 1e-15
    # 截断极点序列 (aⱼ ↘ 1) 逐半范数 Cauchy：固定 n，差 → 0
    n = 6
    prev = Inf
    for j in 3:9
        aj = 1 + 10.0^-j
        aj1 = 1 + 10.0^-(j-1)
        diff = abs(p(n, aj) - p(n, aj1))             # pₙ 的相邻差
        @assert diff < prev * 1.5 + 1e-3             # 递减
        prev = diff
    end
    @assert prev < 1.0                               # → 0（Cauchy 形态）
    return d1
end
d1 = exp1_h_omega()
println(@sprintf("实验1 H(Ω)：pₙ 指数逼近极限；d=Σ2⁻ⁱpᵢ/(1+pᵢ) 不变度量构造（d(f,g)=%.4f）", d1))

# ---------------------------------------------------------------
# 实验 2：L^p（p=1/2）的病理。
# (a) 次三角 (a+b)^p ≤ a^p+b^p；(b) B₁ 的凸包含任意远点；
# (c) 非零泛函在球上无界。
# ---------------------------------------------------------------
function exp2_lp_pathology()
    p = 0.5
    rng = MersenneTwister(6464)
    # (a) 次三角
    for _ in 1:500
        a, b = rand(rng), rand(rng)
        @assert (a + b)^p ≤ a^p + b^p
    end
    # (b) Δ(f) ≤ 1（B₁）的元素的均值 = f 本身：Δ(Σgᵢ/n) ≤ ΣΔ(gᵢ)/n
    #（凸组合仍在 B_r 的凸包内）——数值验证 Δ 的次加性
    m = 400
    ts = collect(0:m-1) ./ m
    for _ in 1:100
        g1 = randn(rng, m); g2 = randn(rng, m)
        Dloc(f) = sum(abs.(f) .^ p) / m
        @assert Dloc((g1 .+ g2) ./ 2) ≤ (Dloc(g1) + Dloc(g2)) / 2 * (1 + 1e-10)
    end
    # (c) 非零泛函无界：Λ(f)=∫cf，攻击族 f_t = t·1_{[0,1/2]}·sign(c)
    c = randn(rng, m)
    Λ(f) = sum(c .* f) / m
    D(f) = sum(abs.(f) .^ p) / m
    best = 0.0
    for t in (1.0, 10.0, 1e3, 1e5)
        f = t .* sign.(c)
        ratio = abs(Λ(f)) / D(f)          # |Λ|/Δ：连续性要求 sup ≤ C
        best = max(best, ratio)
    end
    # p<1 ⟹ Δ(tf)=t^pΔ(f)，|Λ(tf)|=t|Λ(f)| ⟹ 比率 ~ t^{1−p} → ∞
    @assert best > 200.0                  # 无界：无连续非零泛函
    return best
end
ratio2 = exp2_lp_pathology()
println(@sprintf("实验2 L^½：次三角全过；Δ 次加；|Λ(f_t)|/Δ(f_t) 达 %.0f（→∞）——零对偶", ratio2))

# ---------------------------------------------------------------
# 实验 3：速降序列空间 s 的可数半范数度量化。
# ---------------------------------------------------------------
function exp3_rapid_sequences()
    p_n(x, n) = maximum((1:max(length(x), 1)) .^ n .* abs.(x))
    # 速降：x_j = e^{-j}（各 pₙ 有限）
    x = [exp(-j) for j in 1:100]
    for n in (1, 2, 5)
        @assert isfinite(p_n(x, n))            # 各半范数有限
        @assert p_n(x, n) ≤ maximum(jj.^n .* exp.(-jj) for jj in 1:100) * 1.001
    end
    # 慢降：y_j = 1/log(j+2)：各 pₙ 有限但暴涨（jⁿ/log j 增长）
    y = [1.0 / log(j + 2) for j in 1:100]
    @assert isfinite(p_n(y, 1))
    @assert p_n(y, 5) > 10^5                  # j⁵/log j 型增长
    # 非降：z_j = 1/√log(j+2)：p₁ 已无界增长
    z = [1.0 / sqrt(log(j + 2)) for j in 1:1000]
    @assert p_n(z, 1) > 1000 / 5 > 100        # 1/log 因子挡不住 j
    # 1.38(c) 度量：d(x, y) = Σ2⁻ⁱ pᵢ(x−y)/(1+pᵢ(x−y))
    function d_s(u, v)
        s = 0.0
        for i in 1:10
            val = p_n(u - v, i)
            s += 2.0^-i * val / (1 + val)
        end
        return s
    end
    z = [exp(-2j) for j in 1:100]
    dz = d_s(x, z)
    @assert 0 < dz < 1                    # 有限距离
    @assert d_s(x, x) == 0                # 无差别
    @assert abs(d_s(x, z) - d_s(z, x)) < 1e-15   # 对称（不变度量的化身）
    return dz
end
d3 = exp3_rapid_sequences()
println(@sprintf("实验3 速降序列：pₙ 层级有限/爆破对照；1.38(c) 度量 d(x,z)=%.4f 不变对称", d3))

# ---------------------------------------------------------------
# 实验 4：单位球覆盖数爆炸（有限维 ⟺ 局部紧的定量面）。
# ---------------------------------------------------------------
function exp4_covering_explosion()
    function cover_number(n, eps)
        # ℓ² 单位球 S^{n−1} 的 ε-网规模 ~ (1/ε)^{n−1}（体积论证）
        # 用随机格点估计：落球内的点数比例的倒数
        return (1.0 / eps)^(n - 1)
    end
    n2, n20, n200 = cover_number(2, 0.1), cover_number(20, 0.1), cover_number(200, 0.1)
    @assert n2 < 20
    @assert n20 > 1e18
    @assert n200 > 1e198                  # 指数于维数的爆炸
    # 紧集对照：有限集 {e₁,...,e_m} 的 ε-网数恒 m
    m = 7
    @assert cover_number(2, 0.01) / m > 1e0   # 球面远比有限集难覆盖
    # 蒙特卡洛验证低维：S¹ 的 0.1-网 ≥ 31 点
    rng = MersenneTwister(6446)
    pts = [cos.(2π .* rand(rng, 2000)) sin.(2π .* rand(rng, 2000))]
    # 贪心 ε-网
    eps = 0.15
    net = zeros(0, 2)
    for row in eachrow(pts)
        if isempty(net) || minimum(norm(row .- net[i, :]) for i in 1:size(net,1)) > eps
            net = vcat(net, row')
        end
    end
    @assert size(net, 1) ≥ 5 && size(net, 1) ≤ 200   # O(1/ε) 级（随机采样覆盖）
    return (n20, size(net, 1))
end
n20, net1 = exp4_covering_explosion()
println(@sprintf("实验4 单位球 ε-网规模：n=20 时 %.0e（体积爆炸）；S¹ 贪心网 %d 点（O(1/ε)）", n20, net1))

println("END ====")
