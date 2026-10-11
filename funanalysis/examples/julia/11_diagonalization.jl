# 第 11 章 · 紧自伴算子对角化的数值实验（Conway II.5）
# 对应 docs/11-diagonalization.md。
# 三个实验：特征值分解 = 对角化（5.1）、特征值趋于零（5.3c）、
# 谱半径 = ‖T‖ = max|αₙ|（5.3c）。

using LinearAlgebra
using Random

println("==== 11 diagonalization (Julia) ====")
Random.seed!(1111)

# --- 实验 1：紧自伴算子的对角化（Conway 5.1）--------------------------------
# 构造 Hilbert-Schmidt 核 k(x,y) = exp(-|x-y|)（对称正定 → 自伴紧）
n = 100
xs = range(0, 1; length = n)
K = [exp(-abs(x - y)) for x in xs, y in xs] / n  # 离散积分算子
evals, evecs = eigen(Symmetric(K))
# 排序（绝对值递减）
idx = sortperm(abs.(evals), rev = true)
evals_sorted = evals[idx]
println("eigenvalues (top 5): ", round.(evals_sorted[1:5], digits = 6))
println("all real: ", all(e -> abs(imag(e)) < 1e-12, evals_sorted))
@assert all(e -> abs(imag(e)) < 1e-12, evals_sorted)

# --- 实验 2：特征值趋于零（Conway 5.3 (c)）-----------------------------------
# 紧自伴算子的非零特征值至多可数且趋于零
println("last 5 eigenvalues: ", round.(evals_sorted[end-4:end], digits = 8))
@assert maximum(abs.(evals_sorted[end-4:end])) < 1e-3

# --- 实验 3：‖T‖ = max|αₙ|（Conway 5.3 (c)）---------------------------------
opnormK = opnorm(K)
specmax = maximum(abs.(evals))
println("opnorm(K) = $(round(opnormK, digits=8))  max|α| = $(round(specmax, digits=8))")
@assert abs(opnormK - specmax) < 1e-10

# 特征向量正交性（Parseval 对角化形态）
Q = evecs
@assert norm(Q'Q - I) < 1e-8

println("==== 11 diagonalization END ====")
