println("==== 19 kernels")
# 第 19 章：转移核与 Chapman-Kolmogorov。
# ① 马氏链两步分布（核复合 = 矩阵乘方）；
# ② CK 恒等式 (P²)ᵢⱼ = ΣₖPᵢₖPₖⱼ 四分量逐项核对；
# ③ 平稳分布 π = (4/7,3/7)：πP = π + 收敛速率 |μₙ(1)-4/7| ≈ C·0.3ⁿ；
# ④ 核版 Fubini（连续）：μK 的"逐 x 报价"与卷积闭式双算法对拍。

const P = [0.7 0.3; 0.4 0.6]      # 两态转移矩阵
const μ0 = [1.0 0.0]              # 初始：全在态 1

# ---- ① 一步/两步分布 ----
μ1 = μ0 * P
@assert μ1 ≈ [0.7 0.3]
μ2 = μ1 * P                       # = μ0 * (P*P)：核复合的结合律
@assert μ2[1] ≈ 0.7 * 0.7 + 0.3 * 0.4    # 0.61
@assert μ2[2] ≈ 0.7 * 0.3 + 0.3 * 0.6    # 0.39

# ---- ② Chapman-Kolmogorov 逐项 ----
P2 = P * P
for i in 1:2, j in 1:2
    ck = sum(P[i, k] * P[k, j] for k in 1:2)
    @assert P2[i, j] ≈ ck
end
@assert P2 ≈ [0.61 0.39; 0.52 0.48]

# ---- ③ 平稳分布与次特征值收敛 ----
# πP = π, π1+π2=1  ⟹  π = (4/7, 3/7)（解线性方程）
A = [0.3 -0.4; 1.0 1.0]           # (P₁₁-1)π₁ + P₂₁π₂ = 0 展开式 + 归一
b = [0.0, 1.0]
πstat = A \ b
@assert abs(πstat[1] - 4 / 7) < 1e-12 && abs(πstat[2] - 3 / 7) < 1e-12
@assert maximum(abs.(πstat' * P - πstat')) < 1e-14

μn = copy(μ0)
ratio = 0.0
for n in 1:20                     # n 大到底会被浮点消去污染，20 步内账干净
    global μn = μn * P
    global ratio = abs(μn[1] - 4 / 7) / 0.3^n
end
@assert 0.4 < ratio < 0.5         # 真值 C = 3/7 ≈ 0.4286（次特征值预言的显式常数）
@assert abs(μn[1] - 4 / 7) < 1e-9
println("two-step = 0.61/0.39, CK 4 entries, stationary (4/7,3/7), rate C=3/7: OK")

# ---- ④ 核版 Fubini：μK 逐点报价 vs 闭式卷积 ----
# μ = U[0,1]，K(x,·) = U[x, x+1]（均匀核）。
# μK 的密度 g(y) = ∫₀¹ 1_{[x,x+1]}(y) dx = |{x∈[0,1] : y-1 ≤ x ≤ y}|，
# 闭式 = 三角分布：y∈[0,1] 时 = y；y∈[1,2] 时 = 2-y；否则 0。
g_closed(y) = 0 ≤ y ≤ 1 ? y : (1 ≤ y ≤ 2 ? 2 - y : 0.0)
g_quad(y) = begin
    n = 4000
    h = 1.0 / n
    s = 0.0
    for k in 0:n-1
        s += g_kernel_indicator(y, (k + 0.5) * h)
    end
    s * h
end
g_kernel_indicator(y, x) = (x ≤ y ≤ x + 1) ? 1.0 : 0.0
for y in (0.0, 0.3, 0.5, 0.8, 1.0, 1.2, 1.7, 2.3)
    @assert abs(g_closed(y) - g_quad(y)) < 1e-4   # 中点和 vs 三角闭式
end
@assert abs(g_quad(0.5) - 0.5) < 1e-4             # 峰前斜坡
@assert abs(g_quad(1.5) - 0.5) < 1e-4             # 峰后对称
println("kernel Fubini: per-x quoting vs triangular closed form < 1e-4: OK")

println("END ====")
