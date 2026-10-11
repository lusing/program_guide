# 第 09 章 · 投影、幂等与不变子空间的数值实验（Conway II.3）
# 对应 docs/09-projections.md。
# 四个实验：斜投影的幂等性与范数（3.1 + 习题 1）、ran E = ker(I-E)（3.2b）、
# 正交投影的自伴性（3.3d）、不变/约化子空间与交换性（3.7）。

using LinearAlgebra
using Random

println("==== 09 projections (Julia) ====")
Random.seed!(909)

# --- 实验 1：斜投影 E(x,y) = (x+y, 0)：幂等但范数 √2（Conway 习题 1）--------
E = [1.0 1.0; 0.0 0.0]
@assert norm(E * E - E) < 1e-12               # 幂等
println("oblique projection: ‖E‖ = ", round(opnorm(E), digits=6), "（> 1）")
@assert opnorm(E) > 1.3                        # 范数 √2 ≈ 1.414 > 1：非正交投影

# --- 实验 2：ran E = ker(I - E)（Conway 3.2 (b) 的数值化身）-------------------
# E 的列空间 = (I-E) 的零空间：投影迭代收敛到不动点集
for _ in 1:100
    v = randn(2)
    @assert norm((I - E) * (E * v)) < 1e-12    # (I-E) 消灭 ran E
end
println("ran E ⊆ ker(I-E): PASS (100 trials)")

# --- 实验 3：正交投影自伴且幂等（Conway 3.3 (a)↔(d)）--------------------------
A = randn(6, 3)
P = A * (A \ A)                                # A(AᵀA)⁻¹Aᵀ 结构的列投影
P = A * pinv(A)
@assert norm(P * P - P) < 1e-10                # 幂等
@assert norm(P' - P) < 1e-10                   # 自伴
@assert opnorm(P) < 1 + 1e-10                  # 范数 ≤ 1
println("orthogonal projection: idempotent + self-adjoint + ‖P‖ ≤ 1")

# --- 实验 4：不变子空间 ⟺ P A P = A P；约化 ⟺ P A = A P（Conway 3.7）--------
# 构造块上三角 A = [B *; 0 C]：第一个坐标子空间不变
B = randn(2, 2); C = randn(3, 3); X = randn(2, 3)
A = [B X; zeros(3, 2) C]
P = diagm([1.0, 1.0, 0.0, 0.0, 0.0])           # 到前两维的投影
@assert norm(P * A * P - A * P) < 1e-12        # 不变 ⟹ PAP = AP
@assert norm(A * P - P * A) > 0.05             # 不约化：AP ≠ PA
# 把 X 清零后：约化
A2 = [B zeros(2, 3); zeros(3, 2) C]
@assert norm(A2 * P - P * A2) < 1e-12          # 约化 ⟺ 交换
println("invariance: PAP = AP (PASS);  reducing: AP = PA only after block-diag")

println("==== 09 projections END ====")
