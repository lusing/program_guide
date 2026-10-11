# 第 10 章 · 紧算子的数值实验（Conway II.4）
# 对应 docs/10-compact-operators.md。
# 四个实验：有限秩逼近（4.4c）、对角算子的紧性 αₙ→0（4.6）、
# 奇异值衰减 = 紧性的数值化身、Volterra 算子的紧性（无特征值）。

using LinearAlgebra
using Random

println("==== 10 compact-operators (Julia) ====")
Random.seed!(1010)

# --- 实验 1：有限秩截断逼近（Conway 4.4 (c) 的核心）--------------------------
# 任何紧算子都是有限秩算子的范数极限——截断 SVD 给出显式逼近序列。
n = 50
A = randn(n, n)
F = svd(A)
for k in [5, 10, 20, 40]
    Ak = F.U[:, 1:k] * Diagonal(F.S[1:k]) * F.Vt[1:k, :]
    err = opnorm(A - Ak)
    println("rank-$k truncation error = ", round(err, digits=6),
        "  σ_$(k+1) = ", round(k < n ? F.S[k+1] : 0, digits=6))
    k < n && @assert abs(err - F.S[k+1]) < 1e-10
end

# --- 实验 2：对角算子的紧性（Conway 4.6）-------------------------------------
# A eₙ = αₙ eₙ，A 紧 ⟺ αₙ → 0。截断余范数 = sup_{j>n}|αⱼ|。
α = [1.0 / k^1.2 for k in 1:100]  # 趋于零：紧
β = [1.0 for k in 1:100]           # 不趋于零：不紧
for (name, seq) in [("αₙ→0", α), ("αₙ→1", β)]
    tail_norm = maximum(abs.(seq[51:end]))
    println("$name: tail sup = ", round(tail_norm, digits=6))
end
@assert maximum(abs.(α[51:end])) < 0.01
@assert maximum(abs.(β[51:end])) ≈ 1.0

# --- 实验 3：紧性 = 奇异值趋于零-----------------------------------------------
# 紧算子的数值化身：奇异值序列趋于零
# （非紧：如单位算子 I 的奇异值全为 1）
function show_sv(name::String, M::Matrix{Float64})
    σ = svdvals(M)
    println("$name: σ₁ = $(round(σ[1], digits=4)),  σ₁₅ = $(round(σ[15], digits=6)),  σ₃₀ = $(round(σ[30], digits=8))")
end
show_sv("Hilbert-Schmidt", randn(30, 30) / 30)
show_sv("identity", Matrix(1.0I, 30, 30))

# --- 实验 4：Volterra 算子紧但无特征值（Conway 4.11）--------------------------
# (Vf)(x) = ∫₀ˣ f(t)dt：‖V‖ = 2/π，紧（Hilbert-Schmidt），但 σ(V) = ∅
n = 200
h = 1.0 / n
xs = range(h / 2, 1 - h / 2; length = n)  # 中点
V = h * [t <= s ? 1.0 : 0.0 for t in xs, s in xs]  # 离散 Volterra
σV = svdvals(V)
println("Volterra: ‖V‖ numeric = $(round(σV[1], digits=4))  2/π = $(round(2/π, digits=4))")
println("Volterra: σ₁₀ = $(round(σV[10], digits=6)) → 0: compact")
@assert abs(σV[1] - 2 / π) < 0.01
@assert σV[10] < 0.1

println("==== 10 compact-operators END ====")
