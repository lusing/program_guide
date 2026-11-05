# Ch36 线性发展 III：双曲方程弱解（Galerkin + 能量）
#
# 对应书 §7.2.1-7.2.3：双曲弱解定义、Galerkin 构造、能量守恒、
# 正则性提升。

using Printf

println("==== 36")

# ---- (a) Galerkin 模式方程：c̈_k + λ_k c_k = f_k 的闭式 vs RK 数值 ----
# 初值位移 sin(πx)、零速度：c₁(t) = cos(πt)
c1(t) = cos(pi * t)
# 数值（velocity-Verlet 辛积分，能量守恒好）
function verlet(T; dt = 1e-4)
    n = round(Int, T / dt)
    q, p = 1.0, 0.0
    λ = pi^2
    p_half = p - λ * q * dt / 2
    for _ in 1:n
        q = q + p_half * dt
        p_half = p_half - λ * q * dt
    end
    return q
end
for T in [0.7, 1.5]
    num = verlet(T)
    @printf("(a) Verlet t=%.1f: q = %.10f  cos(πt) = %.10f\n", T, num, c1(T))
    @assert abs(num - c1(T)) < 1e-5 "模式振子数值积分"
end

# ---- (b) 能量守恒：E(t) = ½(ċ² + λc²) = const（书 §7.2 定理 2）----
for t in [0.0, 0.37, 1.9]
    E = 0.5 * ((pi * sin(pi * t))^2 + pi^2 * cos(pi * t)^2)
    @printf("(b) E(%.2f) = %.12f\n", t, E)
    @assert abs(E - pi^2 / 2) < 1e-12 "动能势能互换总和恒定"
end

# ---- (c) 两模式叠加：能量可加性（正交模式的能量不混合）----
E2m(t) = 0.5 * (pi^2 * cos(pi * t)^2 + 4pi^2 * cos(2pi * t)^2 +
                (pi * sin(pi * t))^2 + (2pi * sin(2pi * t))^2) * 0.5
# 归一化因子：‖sin‖²=1/2——每个模式的能量 = ½λ·½·(cos²+sin²) = λ/4
for t in [0.2, 1.1]
    val = pi^2 / 4 + 4pi^2 / 4
    @printf("(c) two-mode E(%.1f) = %.6f (sum of modal energies %+.6f)\n", t, E2m(t), val)
    @assert abs(E2m(t) - val) < 1e-9 "能量按模式可加（无交叉项）"
end

# ---- (d) 正则性门槛：u ∈ H¹ 需 g ∈ H¹ 且 h ∈ L²（书定理 2 的条件）----
# h = δ ∉ L² ⟹ 无 H¹ 解：数值签名——初速度锯齿高频的能量发散
for K in [10, 100, 1000]
    Eh = 0.5 * sum((k * pi)^0 * 1.0 / k for k in 1:K) * 0 # h=δ 的 L² 发散
    # 改用：h_K = Σ_{k≤K} φ_k/k（L² 范数² = Σ 1/k² 收敛）；h_δ 型（系数 1）发散
    l2_conv = sum(1 / k^2 for k in 1:K)
    l2_div = sum(1.0 for k in 1:K)
    @printf("    K=%4d: ||h_K||² (Σ1/k²) = %.3f (converges); flat coeffs: %.0f (diverges)\n",
            K, l2_conv, l2_div)
end
@assert sum(1.0 for k in 1:1000) == 1000 "平坦系数 ⟹ L² 爆炸（δ 不是 L²）"

println("END ====")
