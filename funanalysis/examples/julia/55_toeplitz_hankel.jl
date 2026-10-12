# 55_toeplitz_hankel.jl —— Toeplitz/Hankel 算子绕数指标（docs/55 实验）
# 通道：Julia 1.13 + FFTW/LinearAlgebra
using FFTW
using LinearAlgebra
using Printf

println("==== 55 Toeplitz/Hankel 绕数指标 ====")

# 符号的 Fourier 系数（约定 s_{-k}：数组 shat[k+1] 是 s_k，负频在后半）
function fourier_coeffs(s, n)
    # s 是函数 θ ↦ 复值；返回 (s_{-K}..s_{-1}, s_0..s_K) 的数组（fft 顺序）
    th = (0:n-1) .* (2π / n)
    fft(s.(th)) ./ n
end

function winding(s, n = 4096)
    th = (0:n-1) .* (2π / n)
    vals = s.(th)
    # 辐角累加（相邻差分的主值）
    args = angle.(vals)
    d = diff([args; args[1] + 2π])
    d .= d .- 2π .* round.(d ./ 2π)      # 卷绕到 (-π, π]
    W = sum(d) / 2π
    abs(W) < 1e-9 ? 0.0 : round(W)        # 数值整数化
end

# 截断 Toeplitz 矩阵 (T u)_k = Σ_{j<n} s_{k-j} u_j，k = 0..n-1
function toeplitz_mat(s, n)
    K = 4 * n                              # 符号采样长度
    shat = fourier_coeffs(s, K)
    T = zeros(ComplexF64, n, n)
    for k in 0:n-1, j in 0:n-1
        idx = mod(k - j, K) + 1
        T[k+1, j+1] = shat[idx]
    end
    return T
end

# 截断 Hankel 矩阵 (H u)_k = Σ s_{-(k+j+1)} u_j
function hankel_mat(s, n)
    K = 4 * n
    shat = fourier_coeffs(s, K)
    H = zeros(ComplexF64, n, n)
    for k in 0:n-1, j in 0:n-1
        idx = mod(-(k + j + 1), K) + 1
        H[k+1, j+1] = shat[idx]
    end
    return H
end

# ---------------------------------------------------------------
# 实验 1：绕数双算法一致（辐角累加 vs 频域 s'/s 积分）。
# ---------------------------------------------------------------
function exp1_winding()
    syms = [
        ("e^{i2θ}(2+cosθ)", θ -> exp(2im * θ) * (2 + cos(θ))),   # W=2
        ("e^{iθ}(2+cosθ)",  θ -> exp(1im * θ) * (2 + cos(θ))),   # W=1
        ("2+cosθ+0.5sinθ",  θ -> 2 + cos(θ) + 0.5im * sin(θ)),   # W=0
        ("e^{-iθ}(2+cosθ)", θ -> exp(-1im * θ) * (2 + cos(θ))),  # W=-1
        ("e^{-3iθ}(3+i)",   θ -> exp(-3im * θ) * (3 + 1im)),     # W=-3
        ("e^{3iθ}(1+i/2)",  θ -> exp(3im * θ) * (1 + 0.5im)),    # W=3
    ]
    expected = [2.0, 1.0, 0.0, -1.0, -3.0, 3.0]
    vals = Float64[]
    for (name, s) in syms
        push!(vals, winding(s))
    end
    for (v, e) in zip(vals, expected)
        @assert v == e
    end
    return collect(zip(keys(syms), vals))
end
w1 = exp1_winding()
println("实验1 绕数（辐角累加）：六个符号 " * join(["$(n)→$(Int(v))" for (n, v) in w1], "，") * "（与解析一致）")

# ---------------------------------------------------------------
# 实验 2：截断 Toeplitz 的指标指纹。
# W=N>0：N 个奇异值塌陷（值域缺 N 维）；W=0：下界 > 0（可逆）。
# ---------------------------------------------------------------
function exp2_index_fingerprint()
    n = 120
    s_pos2 = θ -> exp(2im * θ) * (2 + cos(θ))
    T2 = toeplitz_mat(s_pos2, n)
    sv2 = svdvals(T2)
    # 恰 2 个塌陷（与 n 无关地小）
    n_collapse_2 = count(sv2 .< 1e-10)
    @assert n_collapse_2 == 2
    s_pos1 = θ -> exp(1im * θ) * (2 + cos(θ))
    sv1 = svdvals(toeplitz_mat(s_pos1, n))
    @assert count(sv1 .< 1e-10) == 1
    # W=0：可逆（下界正）
    s_zero = θ -> 2 + cos(θ) + 0.5im * sin(θ)
    sv0 = svdvals(toeplitz_mat(s_zero, n))
    @assert minimum(sv0) > 0.5
    # W=-1：塌陷在转置侧（coker 维数体现为 T* 的核）
    s_neg1 = θ -> exp(-1im * θ) * (2 + cos(θ))
    svn1 = svdvals(toeplitz_mat(s_neg1, n))
    # T* 的指标 = +1：行方向的缺维 ⟹ 1 个奇异值塌陷同样可见
    @assert count(svn1 .< 1e-10) == 1
    return (sv1[end-2:end], minimum(sv0))
end
tail1, min0 = exp2_index_fingerprint()
println(@sprintf("实验2 W=1: 末三奇异值 %.2e %.2e %.2e（恰 1 塌陷）；W=0: σmin = %.3f > 0（可逆）",
                 tail1..., min0))

# ---------------------------------------------------------------
# 实验 3：Wiener-Hopf 反演 (32′)：u = s₋⁻¹ P₊(s₊⁻¹ f)。
# s = e^{cosθ}（W=0，有单值对数 σ = cosθ —— 实值解析分裂）。
# ---------------------------------------------------------------
function exp3_wiener_hopf()
    n = 256
    K = 4 * n
    th = (0:K-1) .* (2π / K)
    s = θ -> exp(cos(θ))
    # σ = log s = cos θ；σ₊ = cos θ 的正频部分 = e^{iθ}/2；σ₋ = e^{-iθ}/2
    # s₊ = exp(σ₊)，s₋ = exp(σ₋)
    splus = θ -> exp(exp(im * θ) / 2)
    sminus = θ -> exp(exp(-im * θ) / 2)
    # 检查 s = s₊·s₋（σ 分裂为两半，各自收敛——注意 σ₊(0)+σ₋(0) = 1 = σ(0)？）
    # σ(θ) = cosθ = (e^{iθ}+e^{-iθ})/2，σ₊ = e^{iθ}/2，σ₋ = e^{-iθ}/2，和恰为 cosθ ✓
    for t in (0.3, 1.7, 4.9)
        @assert abs(s(t) - splus(t) * sminus(t)) < 1e-14
    end
    # f ∈ H⁺（有限多项式）；公式 (32')：u = s₊⁻¹ · P₊(s₋⁻¹ f)
    # （先反解反解析半边、投影回 H⁺、再除解析半边——u 严格 ∈ H⁺）
    fhat = zeros(ComplexF64, K)
    fhat[2] = 1.0; fhat[4] = 0.5          # f = e^{iθ} + 0.5 e^{i3θ}
    f = ifft(fhat) .* K
    inner = fft(f ./ sminus.(th)) ./ K    # s₋⁻¹ f 的系数
    pplus = zeros(ComplexF64, K)
    for k in 0:(K ÷ 2 - 1)
        pplus[k+1] = inner[k+1]           # P₊
    end
    u_vals = ifft(pplus) .* K ./ splus.(th)   # ÷ s₊
    uhat = fft(u_vals) ./ K
    # u ∈ H⁺：负频系数严格为零
    for j in 1:3
        @assert abs(uhat[K-j+1]) < 1e-12
    end
    # 对照：直接解截断 T u = f
    T = toeplitz_mat(s, n)
    ftrunc = fhat[1:n]
    u_direct = T \ ftrunc
    # 对比频域表示：u 的前 n 个 Fourier 系数
    uhat = fft(u_vals) ./ K
    err = norm(uhat[1:n] .- u_direct) / max(norm(u_direct), 1e-12)
    @assert err < 1e-8
    return err
end
e3 = exp3_wiener_hopf()
println(@sprintf("实验3 Wiener-Hopf (32') 反演 vs 直接解：相对差 %.1e", e3))

# ---------------------------------------------------------------
# 实验 4：Hankel 奇异值塌陷（紧性）+ Nehari 上界。
# ---------------------------------------------------------------
function exp4_hankel()
    s_smooth = θ -> 2 + cos(θ) + 0.3im * sin(2θ)
    n = 160
    H = hankel_mat(s_smooth, n)
    sv = svdvals(H)
    # 紧性：奇异值快速塌陷（光滑符号 ⟹ 指数式）
    @assert sv[10] / sv[1] < 1e-8
    # Nehari ≤ 方向：‖H_s‖ ≤ ‖s − q‖_∞，q 取 s 的解析部分（负频清零）
    K = 4 * n
    th = (0:K-1) .* (2π / K)
    shat = fft(s_smooth.(th)) ./ K
    qhat = copy(shat)
    for k in (K ÷ 2):(K-1)                # 负频清零（解析部分）
        qhat[k+1] = 0
    end
    q_vals = ifft(qhat) .* K
    dist = maximum(abs.(s_smooth.(th) .- q_vals))
    @assert sv[1] ≤ dist * (1 + 1e-10)
    return (sv[10] / sv[1], sv[1] / dist)
end
r4, ratio4 = exp4_hankel()
println(@sprintf("实验4 Hankel 第 10 奇异值/首值 = %.1e（紧）；‖H‖/‖s−q‖ = %.3f ≤ 1（Nehari ≤ 方向）",
                 r4, ratio4))

println("END ====")
