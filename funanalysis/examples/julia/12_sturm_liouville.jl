# 第 12 章 · Sturm-Liouville 系统的数值实验（Conway II.6*）
# 对应 docs/12-sturm-liouville.md。
# 三个实验：Green 函数数值构造（6.7-6.9）、特征值与特征函数（6.12）、
# Fourier 正弦基 = L = -d²/dx² 的特征基（习题 1a）。

using LinearAlgebra
using Printf

println("==== 12 sturm-liouville (Julia) ====")

# --- 实验 1：L = -d²/dx²，h(0)=h(1)=0 的 Green 函数（Conway 习题 1a）--------
# Green 函数 g(x,y) = min(x,y)·(1-max(x,y))（显式公式）
# 验证：(G f)(x) = ∫ g(x,y) f(y) dy 满足 -G f'' = f 且边界条件成立
n = 200
h = 1.0 / (n + 1)
xs = [i * h for i in 1:n]  # 内点

# Green 函数矩阵
G = zeros(n, n)
for (i, x) in enumerate(xs), (j, y) in enumerate(xs)
    G[i, j] = min(x, y) * (1 - max(x, y)) * h
end

# 验证：对 f = sin(πx)，G f = sin(πx) / π²
f = sin.(π .* xs)
Gf = G * f
expected = f ./ π^2
err = norm(Gf - expected) / norm(expected)
println("Green function check: ||Gf - f/π²||/||f/π²|| = $(round(err, digits=8))")
@assert err < 1e-4

# --- 实验 2：G 的特征值分解（Conway 6.12）-------------------------------------
# G 的特征值 = 1/(n²π²)（Conway 5.4 + 6.10）
evals, evecs = eigen(Symmetric(G))
# 对称矩阵特征值升序；取最大的（对应最小的 n²π²）
top = sortperm(abs.(evals), rev = true)
for k in 1:5
    α = evals[top[k]]
    expected_α = 1 / (k * π)^2
    @printf("  λ_%d = %.8f  1/(%d²π²) = %.8f\n", k, α, k, expected_α)
    @assert abs(α - expected_α) / expected_α < 0.01
end

# --- 实验 3：特征函数 = sin(kπx)（Fourier 正弦基）----------------------------
k = 3
v = evecs[:, top[k]]
# 符号对齐（特征向量可能差一个符号）
if dot(v, sin.(k .* π .* xs)) < 0
    v = -v
end
cos_sim = abs(dot(v, sin.(k .* π .* xs))) / (norm(v) * norm(sin.(k .* π .* xs)))
println("eigenvector $k cosine-similarity with sin($(k)πx): $(round(cos_sim, digits=6))")
@assert cos_sim > 0.999

println("==== 12 sturm-liouville END ====")
