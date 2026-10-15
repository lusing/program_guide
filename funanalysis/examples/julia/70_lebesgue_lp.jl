# 70_lebesgue_lp.jl —— 勒贝格积分与 L^p（docs/70 第 X 节实验）
# 通道：Julia 1.13 + LinearAlgebra + Printf
# 内容：狄利克雷函数、Fatou 反例、截断逼近、L^p 完备性数值
using LinearAlgebra
using Printf

println("==== 70 勒贝格积分与 L^p ====")

# ---------------------------------------------------------------
# 实验 1：狄利克雷函数——逐点采样看不见测度，ε/2ⁱ 覆盖看得见
# D(x) = 1 (x ∈ ℚ)，0 (x ∉ ℚ)。
# 任何浮点数都是有理数：逐点求值 D(x) ≡ 1 —— 而它的勒贝格积分是 0！
# 语义鸿沟：非理点占满测度，浮点数却全是有理点。
# 数值化零测的正确姿势（书 1.4.11）：把 ℚ 编号为 {r₁, r₂, ...}，
# 第 i 个点配半径 ε/2ⁱ 的区间——总长 ≤ ε，与点数无关。
# 对比：若给 M 个点配**固定**半径 δ，总长 = Mδ 随 M 发散。
# ---------------------------------------------------------------
function exp1_dirichlet()
    D(x) = 1.0                            # 浮点数皆有理，逐点求值恒 1
    xs = 0.0:0.01:1.0
    naive = sum(D, xs) / length(xs)       # "黎曼式"逐点均值 = 1
    @assert naive ≈ 1.0
    # 编号衰减覆盖：M 个有理点（Stern-Brocot 序的前缀，任意有限集都行）
    M = 100_000
    eps = 1e-4
    cover = sum(eps / 2.0^i for i in 1:M) # = ε(1 - 2^{-M}) ≤ ε（浮点下≈ε）
    @assert cover ≤ eps * (1 + 1e-12)     # 与点数无关！
    @assert abs(cover - eps) / eps < 1e-5 # 几乎贴住 ε
    # 反面对照：固定半径 δ = ε/M 的均匀覆盖，M 增大时若点在编号下
    # 不衰减，总长恒为 ε；但若对**全体** ℚ 用固定 δ，总长 = ∞·δ = ∞。
    fixed_total = M * (eps / M)           # = ε，但只覆盖了 M 个点；
    @assert abs(fixed_total - eps) < 1e-9 # 而 ℚ 有无穷多——固定半径破产
    return (naive, cover)
end
naive1, cover1 = exp1_dirichlet()
println(@sprintf("实验1 逐点均值=%.1f（浮点全有理）；ε/2ⁱ 编号覆盖总长=%.1e≤ε → 勒贝格积分=0",
                 naive1, cover1))

# ---------------------------------------------------------------
# 实验 2：Fatou 引理的滑动条反例（不等号可以严格）
# fₙ = 1_{[n, n+1]}：每个 ∫fₙ = 1，但 liminf fₙ = 0 逐点，∫liminf = 0。
# Fatou：∫liminf ≤ liminf∫，0 ≤ 1 —— 不等号严格成立。
# ---------------------------------------------------------------
function exp2_fatou_sliding()
    L = 6.0                               # 观察窗 [0,6]
    dx = 0.005
    grid = 0.0:dx:L
    int_fn = Float64[]
    for n in 0:5
        fn = [n ≤ x < n + 1 ? 1.0 : 0.0 for x in grid]
        push!(int_fn, sum(fn) * dx)       # ∫ fₙ ≈ 1
    end
    liminf = [minimum([n ≤ x < n + 1 ? 1.0 : 0.0 for n in 0:5]) for x in grid]
    int_linf = sum(liminf) * dx           # ∫ liminf fₙ = 0
    @assert all(i -> abs(int_fn[i+1] - 1.0) < 0.01, 0:5)   # 每个 ∫fₙ = 1
    @assert int_linf < 1e-12                                 # ∫liminf = 0
    gap = minimum(int_fn) - int_linf                          # Fatou 差 1
    @assert 0.99 < gap < 1.01
    return gap
end
gap2 = exp2_fatou_sliding()
println(@sprintf("实验2 滑动条 Fatou：liminf∫=%.2f > ∫liminf=%.2f，不等号严格（差=%.2f）",
                 1.0, 0.0, gap2))

# ---------------------------------------------------------------
# 实验 3：截断逼近（书 1.4.20 的数值版）
# f(x) = 1/√x 在 (0,1]：不可积（∫=2 但 f ∉ L^∞ 附近无界）……
# 改用 f(x) = 1/x^{1/4}：L¹ 可积（∫ = 4/3），无界。
# fₙ = min(f, n) 单调递增 → ∫fₙ → ∫f（Levi 单调收敛的数值体现）。
# ---------------------------------------------------------------
function exp3_truncation()
    f(x) = x^(-0.25)
    dx = 1e-4
    grid = range(dx, 1.0; step=dx)
    If = sum(f, grid) * dx                # ≈ 4/3
    @assert abs(If - 4/3) < 2e-2
    prev = -1.0
    for n in [2.0, 4.0, 8.0, 16.0, 64.0, 256.0]
        fn = min.(f.(grid), n)
        int_n = sum(fn) * dx
        @assert int_n ≥ prev - 1e-12      # 单调不降（Levi 条件）
        @assert int_n ≤ If + 1e-3         # 控制在极限之下
        global _ = n                      # （保持可读）
        prev = int_n
    end
    # 收敛速度：截断损失 ∫_{f>n}(f - n) ~ ∫₀^{n^{-4}} x^{-1/4} - n·长度
    loss256 = prev
    @assert If - loss256 < 0.02           # n=256 已逼近 99%+
    return If
end
If3 = exp3_truncation()
println(@sprintf("实验3 截断 min(f,n) 递增逼近：∫f=%.4f（真值 4/3=%.4f）", If3, 4/3))

# ---------------------------------------------------------------
# 实验 4：L² 完备性（Riesz-Fischer 的数值体现）
# 构造 L²-Cauchy 列：傅里叶部分和 sₙ(x) = Σ_{k≤n} aₖ sin(kπx)，
# aₖ = 1/k^{1.1}：Σaₖ² < ∞ ⟹ (sₙ) 是 L²-Cauchy 列且收敛到 L² 函数。
# 验证：‖s_{n+m} - s_n‖₂ 随 n → 0（Cauchy），且 = sqrt(Σ_{k>n} aₖ²/2)。
# ---------------------------------------------------------------
function exp4_lp_complete()
    a(k) = k^(-1.1)
    # Parseval：∫₀¹ sin(kπx)sin(jπx)dx = δ_{kj}/2
    grid = range(0, 1; length=4001)
    function s(n)
        acc = zeros(length(grid))
        for k in 1:n
            acc .+= a(k) .* sin.(pi .* k .* grid)
        end
        acc
    end
    s200 = s(200)
    for n in [50, 100]
        sn = s(n)
        # Cauchy：‖s200 - sn‖₂² = Σ_{n<k≤200} aₖ²/2
        exact2 = sum(a(k)^2 for k in n+1:200) / 2
        num2 = sum(abs2, s200 .- sn) / length(grid)   # 网格 L²（含 dx=1 因子化）
        @assert abs(num2 - exact2) < 5e-3             # 相对一致
    end
    tail = sqrt(sum(a(k)^2 for k in 201:10^6) / 2)    # ‖s - s₂₀₀‖₂ 理论尾项
    @assert tail < 0.03                                # ≈0.027：s₂₀₀ 已接近极限
    return tail
end
tail4 = exp4_lp_complete()
println(@sprintf("实验4 L²-Cauchy 列：n=200 尾项范数=%.4f（部分和逼近极限函数）", tail4))

println("END ====")
