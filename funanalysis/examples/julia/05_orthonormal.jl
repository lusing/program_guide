# 第 05 章 · 标准正交基的数值实验（Conway I.4）
# 对应 docs/05-orthonormal-bases.md。
# 四个实验：Gram-Schmidt 的子空间链、Bessel 不等式、Parseval 恒等式、
# Fourier 部分和的最佳逼近性（投影到前 N 个基向量张成的子空间）。

using LinearAlgebra
using Random

println("==== 05 orthonormal (Julia) ====")
Random.seed!(512)

# --- 实验 1：Gram-Schmidt 的不减子空间链（Conway 4.6）---------------------
function gram_schmidt(V::Matrix{Float64})
    n = size(V, 2)
    Q = zeros(size(V))
    for j in 1:n
        w = V[:, j]
        for i in 1:j-1
            w -= dot(Q[:, i], V[:, j]) * Q[:, i]
        end
        Q[:, j] = w / norm(w)
    end
    return Q
end
V = randn(6, 4)
Q = gram_schmidt(V)
# 链的性质：span(Q[:,1:j]) = span(V[:,1:j])——同一向量在两条链上投影一致
b = randn(6)
err_chain = 0.0
for j in 1:4
    Vj = V[:, 1:j]
    Qj = Q[:, 1:j]
    global err_chain = max(err_chain, norm(Vj * (Vj \ b) - Qj * (Qj \ b)))
end
println("GS chain-consistency residual = ", err_chain)
@assert err_chain < 1e-8

# --- 实验 2：Bessel 不等式（Conway 4.8）-----------------------------------
# 标准正交系上部分和能量 ≤ 全能量；非标准正交系（未归一）则可能违反
E = randn(10, 4)
E = E ./ norm.(eachcol(E))'   # 归一列
h = randn(10)
bessel_lhs = sum(dot(E[:, k], h)^2 for k in 1:4)
println("Bessel: partial energy = ", round(bessel_lhs, digits=6),
    " ≤ ‖h‖² = ", round(dot(h, h), digits=6))
@assert bessel_lhs ≤ dot(h, h) + 1e-10

# --- 实验 3：Parseval 恒等式（Conway 4.13 有限版）--------------------------
Qf = qr(randn(7, 7)).Q       # 完整标准正交基
x = randn(7)
parseval_lhs = sum(dot(Qf[:, k], x)^2 for k in 1:7)
println("Parseval: Σ|<e_k,x>|² = ", round(parseval_lhs, digits=8),
    "  ‖x‖² = ", round(dot(x, x), digits=8))
@assert abs(parseval_lhs - dot(x, x)) < 1e-10

# --- 实验 4：Fourier 部分和 = 最佳逼近（Conway 4.7 的灵魂）------------------
# 部分和 Σ_{k≤N} <x,e_k> e_k 恰是 x 到 span(e_1..e_N) 的正交投影：
# 部分和残差 ≤ 任意其他线性组合的残差
N = 4
partial = sum(dot(Qf[:, k], x) * Qf[:, k] for k in 1:N)
res_partial = norm(x - partial)
res_other = norm(x - Qf[:, 1:N] * (randn(N) .+ 2))   # 随机非最优系数
println("partial-sum residual = ", round(res_partial, digits=6),
    " ≤ other = ", round(res_other, digits=6))
@assert res_partial ≤ res_other + 1e-12

println("==== 05 orthonormal END ====")
