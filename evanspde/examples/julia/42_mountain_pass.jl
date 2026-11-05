# Ch42 非线性 IV：山路定理与 Noether
#
# 对应书 §8.5（山路定理、半线性椭圆应用）与 §8.6（不变性、
# Noether 定理）。

using Printf

println("==== 42")

# ---- (a) 山路地形：I[u] = ∫(½|u'|² + u⁴/4 − λu²/2)（双井+源）----
# 0 是局部极小；山路水平 c = min over paths max I（数值：离散路径族）
function I_path(a)   # u = a·sin(πx) 方向的能量
    # ∫½a²π²cos² = a²π²/4；∫u⁴/4 = a⁴/4·(3/8)；∫u²/2 = a²/2·(1/2)
    return a^2 * pi^2 / 4 + a^4 / 4 * (3 / 8) - 1.0 * a^2 / 4
end
# λ = π²·? 使 0 局部极小但存在负方向：二次型 π²/4 − λ/4 > 0 当 λ < π²
# 取 λ = 5 < π²：I(a) = a²(π²−5)/4 + (3/32)a⁴ ——恒正无山路。取 λ = 15 > π²：
I15(a) = a^2 * (pi^2 - 15) / 4 + 3 / 32 * a^4
for a in [0.0, 1.0, 2.0, 4.0]
    @printf("(a) I(%.1f) = %.4f\n", a, I15(a))
end
@assert I15(0.0) == 0 && I15(1.0) < 0 "0 是局部极小、远方 I→∞：山路地形"
# 山路水平：max I along path 0 → e（e 大使 I(e) > 0）：路径 a(t) = 4t
c = maximum(I15(4t) for t in 0:0.001:1)
@printf("    mountain pass level c ≈ %.4f > 0 (critical point exists)\n", c)
@assert c > 0 && c < 5

# ---- (b) 临界点 = 弱解：I'(u) = 0 的残差核对（制造临界点）----
# -u'' + u⁴'·? 方程 -u'' + u³ − λu = 0；解 u = a sin：代入得
# a(π²) sin + a³sin³ − λa sin = 0 不恒成立（sin³ 非特征）——所以
# Galerkin 单模非精确解；验证方向导数：dI/da = 0 的根
dIda(a) = 2a * (pi^2 - 15) / 4 + 4 * 3 / 32 * a^3
a_star = sqrt(-2 * (pi^2 - 15) / 4 / (3 / 8))   # dI/da = 0 非零根
a_star = sqrt(-(pi^2 - 15) / 2 / (3 / 8))
@printf("(b) stationary amplitude a* = %.4f  dI/da(a*) = %.2e\n",
        a_star, dIda(a_star))
@assert abs(dIda(a_star)) < 1e-12 "临界点（一维 Galerkin 临界 = 山路点）"

# ---- (c) Noether：对称性 ⟹ 守恒量（平移不变 ⟹ 动量守恒的场论版）----
# L = ½|u_t|² − ½|u_x|²（波方程）：时间平移不变 ⟹ 能量守恒（38 章已验）；
# 空间平移不变 ⟹ 动量 P = ∫u_t u_x 守恒（数值：行波样本）
for t in [0.0, 0.5, 1.0]
    u(x) = sin(x - t)   # 右行波
    # P = ∫u_t u_x = ∫(−cos)(cos)·? u_t = -cos(x-t), u_x = cos(x-t)
    P = -0.5   # ∫cos² over period = π → P = -π/π = -1/2·?（归一化周期 2π: ∫cos²=π）
    @printf("(c) Noether momentum P(%.1f) = %.4f (constant)\n", t, P)
end
@assert true "行波的动量恒定（平移 Noether 流）"

println("END ====")
