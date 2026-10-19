println("==== 21 kolmogorov")
# 第 21 章：相容性的双向账。
# ① 正例：布朗式协方差 min(s,t) 的有限维族——三维窗口的二维边缘
#    = 二维窗口分布（Simpson 网格积分对拍）；
# ② 反例：边缘失配族——检查器当场报出不一致；
# ③ 核装配：马氏链 P₃ 的 {2}-边缘 = P₂ 的 {2}-边缘（Tulcea 相容性）。

using LinearAlgebra

# ---- ① 正例：高斯二维密度与三维窗口的边缘 ----
# 布朗式协方差在 t=(1,2)：Σ = [min(i,j)] = [1 1; 1 2]，行列式 1，
# 密度 f₂(x,y) = (2π√det)^{-1} exp(-½ [x y]Σ⁻¹[x y]ᵀ)
Σ2 = [1.0 1.0; 1.0 2.0]
Σ2inv = inv(Σ2)
det2 = det(Σ2)                       # = 1
f2(x, y) = exp(-0.5 * dot([x, y], Σ2inv * [x, y])) / (2π * sqrt(det2))

# 三维窗口 t=(1,2,3)：Σ₃ = [min(i,j)]₃，其 (1,2)-边缘 = f₂
Σ3 = [1.0 1.0 1.0; 1.0 2.0 2.0; 1.0 2.0 3.0]
Σ3inv = inv(Σ3)
det3 = det(Σ3)
f3(x, y, z) = exp(-0.5 * dot([x, y, z], Σ3inv * [x, y, z])) / ((2π)^1.5 * sqrt(det3))

# (1,2)-边缘：∫f3 dz 数值（Simpson，z ∈ [-8,8]）
function marginal12_f3(x::Float64, y::Float64)
    n = 2000
    h = 16.0 / n
    s = f3(x, y, -8.0) + f3(x, y, 8.0)
    for k in 1:n-1
        s += (isodd(k) ? 4 : 2) * f3(x, y, -8.0 + k * h)
    end
    s * h / 3
end

for (x, y) in ((0.5, -0.3), (-1.0, 0.8), (0.0, 1.5), (1.2, 1.2))
    @assert abs(marginal12_f3(x, y) - f2(x, y)) < 1e-6
end
println("Brownian family: 3d-window (1,2)-marginal == 2d-window density < 1e-6: OK")

# ---- ② 反例：边缘失配 ----
# P_{1,2}：完美相关（(0,0),(1,1) 各半）；P_{2,3}：独立均匀。
# P_{1,2} 的 2-边缘 = 均匀{0,1}，P_{2,3} 的 2-边缘 = 均匀{0,1}（表面相容），
# 但二维层面 P_{1,2} ≠ 独立——三维装配必败。
function consistent2(P12::Dict{Tuple{Int,Int},Float64}, P23::Dict{Tuple{Int,Int},Float64})
    m2_of_12 = Dict{Int,Float64}()
    for ((x, y), p) in P12
        m2_of_12[y] = get(m2_of_12, y, 0.0) + p
    end
    m2_of_23 = Dict{Int,Float64}()
    for ((y, z), p) in P23
        m2_of_23[y] = get(m2_of_23, y, 0.0) + p
    end
    for y in keys(m2_of_12)
        abs(m2_of_12[y] - get(m2_of_23, y, 0.0)) > 1e-12 && return false
    end
    length(m2_of_12) == length(m2_of_23)
end
P12 = Dict((0, 0) => 0.5, (1, 1) => 0.5)            # X1 = X2 完美相关
P23_perf = Dict((y, z) => (y == z ? 0.5 : 0.0) for y in 0:1, z in 0:1)  # X2 = X3
@assert consistent2(P12, P23_perf)                # 共享的 2-边缘（均匀）相容——表面通过
# 装配：X1=X2、X2=X3 联合迫使 X1=X3 完全相关——
# 若另宣称 P_{1,3} 独立，则三维装配必败（传递性断链）：
P13_indep = Dict((x, z) => 0.25 for x in 0:1, z in 0:1)
joint_required = Dict{Tuple{Int,Int,Int},Float64}()
for ((x, y), p12) in P12
    for z in 0:1
        pz = (z == y) ? 1.0 : 0.0                 # X3 = X2（完全相关装配）
        joint_required[(x, y, z)] = get(joint_required, (x, y, z), 0.0) + p12 * pz
    end
end
# 装配出的 (1,3)-边缘：
m13 = Dict{Tuple{Int,Int},Float64}()
for ((x, y, z), p) in joint_required
    m13[(x, z)] = get(m13, (x, z), 0.0) + p
end
mismatch = 0.0
for ((x, z), p) in P13_indep
    global mismatch = max(mismatch, abs(p - get(m13, (x, z), 0.0)))
end
@assert mismatch > 0.1                            # 0.25 vs 0.5：当场爆雷
println("inconsistent family: checker exposes mismatch at (1,3)-marginal: OK")

# ---- ③ 核装配：马氏链的窗口相容性 ----
const P = [0.7 0.3; 0.4 0.6]
# 三步联合 (X1,X2,X3) = μ₁ ⊗ P ⊗ P（μ₁ = 一步分布），其 (X2,X3)-边缘
# 应恰为 μ₂ ⊗ P（两步装配）——Tulcea 相容性的数值版。
function joint123()
    d = Dict{Tuple{Int,Int,Int},Float64}()
    μ1 = [0.7, 0.3]                                # X1 分布（μ₀=[1,0] 一步后）
    for x1 in 1:2, x2 in 1:2, x3 in 1:2
        d[(x1, x2, x3)] = μ1[x1] * P[x1, x2] * P[x2, x3]
    end
    d
end
d3 = joint123()
m23_from3 = Dict{Tuple{Int,Int},Float64}()
for ((x1, x2, x3), p) in d3
    m23_from3[(x2, x3)] = get(m23_from3, (x2, x3), 0.0) + p
end
μ2 = [0.7 0.3] * P                                  # X2 分布（两步后）= [0.61, 0.39]
m23_assembled = Dict{Tuple{Int,Int},Float64}(
    (x2, x3) => μ2[x2] * P[x2, x3] for x2 in 1:2, x3 in 1:2)
for k in keys(m23_from3)
    @assert abs(m23_from3[k] - m23_assembled[k]) < 1e-15
end
@assert abs(sum(values(m23_from3)) - 1.0) < 1e-15
println("kernel assembly: (2,3)-marginal of 3-window == 2-step assembly: OK")

println("END ====")
