# 第 03 章 · 正交投影的数值实验（Conway I.2）
# 对应 docs/03-orthogonality.md。
# 三个实验：最近点迭代的收敛（交替投影）、Gram-Schmidt 正交化、
# 投影的"降范数"性质与勾股分解。

using LinearAlgebra
using Random

println("==== 03 projection (Julia) ====")
Random.seed!(314)

# --- 实验 1：闭凸集上的最近点——交替投影（von Neumann 式演示）------------
# 对两个闭凸子空间（线性子空间）M1, M2，交替投影收敛到 M1∩M2 上的投影。
# 这是 Conway I.2 投影定理最经典的应用形态之一（第 28 章弱紧算子处再遇）。
# 子空间：M1 = {x : x1 + x2 + x3 = 0}（超平面），M2 = span{(1,0,-1)} 的正交补？
# 取 M2 = {x : x3 = 0}。则 M1 ∩ M2 = {x : x1+x2 = 0, x3 = 0} = span{(1,-1,0)}。
proj_hyperplane(x, a, b) = x - (dot(a, x) - b) / dot(a, a) * a   # 投影到 {y: a·y = b}
proj_M1(x) = proj_hyperplane(x, [1.0, 1.0, 1.0], 0.0)
proj_M2(x) = [x[1], x[2], 0.0]                                     # 投影到 {x3=0}

x0 = randn(3)
z = x0
for _ in 1:200
    global z = proj_M2(proj_M1(z))
end
# 期望极限：x0 到 M1∩M2 = span{(1,-1,0)} 的投影
udir = [1.0, -1.0, 0.0]
expected = dot(x0, udir) / dot(udir, udir) * udir
println("alternating projection : ", round.(z, digits=10))
println("direct onto M1∩M2       : ", round.(expected, digits=10))
@assert norm(z - expected) < 1e-8

# --- 实验 2：Gram-Schmidt 正交化（Conway I.4.6 预演，投影的构造化身）----
# 线性无关组 -> 标准正交组，生成相同的不减子空间链。
function gram_schmidt(V::Matrix{Float64})
    n = size(V, 2)
    Q = zeros(size(V))
    for j in 1:n
        w = V[:, j]
        for i in 1:j-1
            w -= dot(Q[:, i], V[:, j]) * Q[:, i]   # 减去到已生成子空间的投影
        end
        Q[:, j] = w / norm(w)
    end
    return Q
end
V = randn(6, 4)
Q = gram_schmidt(V)
b = ones(6)
err_id = norm(Q' * Q - I)                     # 正交性：Q'Q = I
err_span = norm(V * (V \ b) - Q * (Q \ b))    # 同一列空间：外部向量投影一致
println("Gram-Schmidt: ||Q'Q - I|| = ", err_id)
@assert err_id < 1e-10
@assert err_span < 1e-8

# --- 实验 3：投影的勾股分解与范数压缩（Conway I.2.7）--------------------
# v = Pv + (v - Pv)，误差正交，范数平方相加；且 ||Pv|| <= ||v||。
M = randn(8, 3)                    # 列生成子空间
A = qr(M).Q                         # 正交基（前 3 列）
Pv = A[:, 1:3] * (A[:, 1:3]' * [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0])
v = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0]
err = v - Pv
println("orthogonality <Pv, v-Pv> = ", round(dot(Pv, err), digits=12))
println("||v||^2 = ", round(dot(v, v), digits=6), "  vs ||Pv||^2+||err||^2 = ",
    round(dot(Pv, Pv) + dot(err, err), digits=6))
@assert abs(dot(Pv, err)) < 1e-10
@assert abs(dot(v, v) - dot(Pv, Pv) - dot(err, err)) < 1e-8
@assert norm(Pv) <= norm(v)

println("==== 03 projection END ====")
